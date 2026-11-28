#if defined(DEV_GC_NO_PROBES) || !defined(DEV_GC_PARK_METRICS)
#define GC_PARK_START() UINT64_C(0)
#define gc_park_record(kind, start) ((void)(start))
#endif
#ifdef DEV_GC_NO_PROBES
/* Keep only the experimental protocol in the timing comparison. */
#define gc_enter(...) ((void)0)
#define gc_leave() ((void)0)
#define gc_record(bucket, start) ((void)(start))
#define GC_START() UINT64_C(0)
#define GC_TIMED(bucket, statement) do { statement; } while (0)
#define GC_VALUE(bucket, expression) (expression)
#define GC_BARRIER(statement) do { statement; } while (0)
#define GC_BARRIER_PUBLISH(statement) GC_BARRIER(statement)
#define GC_BARRIER_SITE(site, statement) GC_BARRIER(statement)
#define GC_BARRIER_SITE_PUBLISH(site, statement) GC_BARRIER_PUBLISH(statement)
#define GC_ALLOCATOR_GATE(statement) GC_BARRIER(statement)
#else
/* DEV only. Inclusive per-carrier timings; nested buckets may overlap. */
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

enum gc_bucket {
  gc_total, gc_cpu, gc_plan, gc_scan, gc_steal, gc_idle, gc_barrier,
  gc_alloc_gate, gc_alloc_call, gc_resize, gc_take, gc_barrier_cpu, gc_barrier_cond, gc_bucket_count
};
static const char *const gc_bucket_names[] = {
  "total", "thread-cpu", "plan", "copy-scan", "steal-loop", "idle-cond",
  "barrier", "allocator-gate", "allocator-call", "resize", "local-take", "barrier-thread-cpu", "barrier-cond"
};
static _Thread_local uint64_t gc_times[gc_bucket_count];
static _Thread_local uint64_t gc_calls[gc_bucket_count];
static _Thread_local uint64_t gc_start, gc_cpu_start;
static _Thread_local unsigned gc_carrier;
static _Thread_local int gc_active;
static _Thread_local unsigned gc_barrier_site;
static _Thread_local int gc_barrier_publication;
#ifndef DEV_GC_SAMPLE_EVERY
#define DEV_GC_SAMPLE_EVERY 1
#endif
static _Thread_local unsigned gc_sequence;
static _Atomic uint64_t gc_sum[8][gc_bucket_count], gc_count[8][gc_bucket_count];
static _Atomic unsigned gc_invalid;

static uint64_t gc_clock(clockid_t clock)
{
  struct timespec ts;
  if (clock_gettime(clock, &ts) != 0) {
    atomic_store_explicit(&gc_invalid, 1, memory_order_relaxed);
    return 0;
  }
  return (uint64_t)ts.tv_sec * 1000000000 + (uint64_t)ts.tv_nsec;
}

#if defined(DEV_GC_ENTRY_TRACE) && !defined(DEV_GC_TAIL_TRACE)
#error "entry phase tracing requires the existing interval recorder"
#endif
#ifdef DEV_GC_ENTRY_TRACE
extern void dev_gc_phase_entry(unsigned id, const void *vm);
#endif
#ifdef DEV_GC_ROUND_TOTALS
#if !defined(DEV_GC_ENTRY_TRACE) || defined(DEV_GC_ENTRY_PREFIX_ROUNDS)
#error "round totals require entry identity and no ordinal window"
#endif
extern void dev_gc_phase_total(unsigned bucket, uint64_t elapsed);
#endif
#ifdef DEV_GC_TAIL_TRACE
static _Thread_local int gc_trace_tail;
extern void dev_gc_tail_interval(unsigned bucket, uint64_t start, uint64_t end);

void dev_gc_tail_enable(void)
{
  gc_trace_tail = gc_active;
}
#endif

#if defined(DEV_GC_TAIL_TRACE) || defined(DEV_GC_LONG_WAIT_NS)
#define GC_WALL_CLOCK CLOCK_UPTIME_RAW
#else
#define GC_WALL_CLOCK CLOCK_MONOTONIC
#endif

#ifdef DEV_GC_GATE_CENSUS
static _Thread_local int gc_inside;
static _Atomic uint64_t gc_native_ns[8], gc_native_calls[8];
#define GC_BUCKET_ACTIVE(bucket) (gc_active || (gc_inside && (bucket) == gc_alloc_call))
#else
#define GC_BUCKET_ACTIVE(bucket) gc_active
#endif

#ifdef DEV_GC_ALLOCATOR_CPU
#ifndef DEV_GC_GATE_CENSUS
#error "allocator CPU measurements require the allocator census"
#endif
static _Thread_local uint64_t gc_native_cpu_start;
static _Atomic uint64_t gc_native_cpu_ns[8];
#endif

#ifdef DEV_GC_ALLOCATOR_OS
#if !defined(DEV_GC_GATE_CENSUS) || !defined(DEV_GC_ENTRY_TRACE) || \
    !defined(DEV_GC_KERNEL_CLOCK) || defined(DEV_GC_ENTRY_PREFIX_ROUNDS) || DEV_GC_SAMPLE_EVERY != 1
#error "allocator OS probes require census, kernel clock and every entry identity"
#endif
extern void dev_gc_allocator_anchor(void);
extern void dev_gc_allocator_interval(uint64_t start, uint64_t end);
#endif

static uint64_t gc_measure_start(enum gc_bucket bucket)
{
  if (!GC_BUCKET_ACTIVE(bucket))
    return 0;
#ifdef DEV_GC_ALLOCATOR_OS
  if (bucket == gc_alloc_call)
    dev_gc_allocator_anchor();
#endif
  uint64_t start = gc_clock(GC_WALL_CLOCK);
#ifdef DEV_GC_ALLOCATOR_CPU
  if (bucket == gc_alloc_call)
    gc_native_cpu_start = gc_clock(CLOCK_THREAD_CPUTIME_ID);
#endif
  return start;
}

static void gc_record(enum gc_bucket bucket, uint64_t start)
{
#ifdef DEV_GC_GATE_CENSUS
  if (gc_inside && bucket == gc_alloc_call && start) {
#ifdef DEV_GC_ALLOCATOR_CPU
    uint64_t cpu_end = gc_clock(CLOCK_THREAD_CPUTIME_ID);
#endif
    uint64_t end = gc_clock(GC_WALL_CLOCK);
#ifdef DEV_GC_ALLOCATOR_CPU
    if (cpu_end < gc_native_cpu_start)
      atomic_store_explicit(&gc_invalid, 1, memory_order_relaxed);
    else
      atomic_fetch_add_explicit(&gc_native_cpu_ns[gc_carrier],
                                cpu_end - gc_native_cpu_start, memory_order_relaxed);
#endif
#ifdef DEV_GC_ALLOCATOR_OS
    dev_gc_allocator_interval(start, end);
    dev_gc_allocator_anchor();
#endif
    atomic_fetch_add_explicit(&gc_native_ns[gc_carrier], end - start, memory_order_relaxed);
    atomic_fetch_add_explicit(&gc_native_calls[gc_carrier], 1, memory_order_relaxed);
    if (gc_active) {
      gc_times[bucket] += end - start;
#if defined(DEV_GC_ENTRY_TRACE) && !defined(DEV_GC_ROUND_TOTALS)
      dev_gc_tail_interval(bucket, start, end);
#endif
      ++gc_calls[bucket];
    }
    return;
  }
#endif
  if (gc_active) {
    uint64_t end = gc_clock(GC_WALL_CLOCK);
    gc_times[bucket] += end - start;
#if defined(DEV_GC_TAIL_TRACE) && !defined(DEV_GC_ROUND_TOTALS)
    if (gc_trace_tail && bucket >= gc_plan && bucket != gc_barrier_cpu)
      dev_gc_tail_interval(bucket, start, end);
#endif
    ++gc_calls[bucket];
  }
}

#define GC_START() (gc_active ? gc_clock(GC_WALL_CLOCK) : 0)

#ifdef DEV_GC_PARK_METRICS
enum gc_park_kind { park_recheck_hit, park_recheck_empty, park_notify, park_kind_count };
static const char *const gc_park_names[] = {
  "park-recheck-hit", "park-recheck-empty", "park-notify"
};
static _Atomic uint64_t gc_park_calls[8][park_kind_count];
static _Atomic uint64_t gc_park_ns[8][park_kind_count];

#define GC_PARK_START() GC_START()
static void gc_park_record(enum gc_park_kind kind, uint64_t start)
{
  if (start) {
    uint64_t end = gc_clock(GC_WALL_CLOCK);
    atomic_fetch_add_explicit(&gc_park_calls[gc_carrier][kind], 1, memory_order_relaxed);
    atomic_fetch_add_explicit(&gc_park_ns[gc_carrier][kind], end - start, memory_order_relaxed);
  }
}
#endif

#define GC_TIMED(bucket, statement) do { \
  uint64_t gc_before = gc_measure_start(bucket); \
  statement; \
  gc_record(bucket, gc_before); \
} while (0)
#ifdef DEV_GC_LONG_WAIT_NS
#define GC_OBSERVE_BARRIER(measuring) 1
#else
#define GC_OBSERVE_BARRIER(measuring) (measuring)
#endif
/* Bound the CPU-clock reads inside the matching inclusive wall span. */
#define GC_BARRIER(statement) GC_BARRIER_AT(statement, 0)
#define GC_BARRIER_PUBLISH(statement) GC_BARRIER_AT(statement, 1)
#ifdef DEV_GC_BARRIER_SITES
/* Explicit source ordinals stay stable when an arm inserts ordinary lines. */
#define GC_BARRIER_SITE_LIMIT 32
static _Atomic uint64_t gc_site_calls[8][GC_BARRIER_SITE_LIMIT];
static _Atomic uint64_t gc_site_ns[8][GC_BARRIER_SITE_LIMIT];
#define GC_BARRIER_SITE(site, statement) GC_BARRIER_SITE_AT(site, statement, 0)
#define GC_BARRIER_SITE_PUBLISH(site, statement) GC_BARRIER_SITE_AT(site, statement, 1)
#define GC_BARRIER_SITE_AT(site, statement, publication) do { \
  _Static_assert((site) < GC_BARRIER_SITE_LIMIT, "GC barrier site overflow"); \
  uint64_t gc_site_before = gc_times[gc_barrier]; \
  GC_BARRIER_AT(statement, publication); \
  if (gc_active) { \
    atomic_fetch_add_explicit(&gc_site_calls[gc_carrier][site], 1, memory_order_relaxed); \
    atomic_fetch_add_explicit(&gc_site_ns[gc_carrier][site], \
      gc_times[gc_barrier] - gc_site_before, memory_order_relaxed); \
  } \
} while (0)
#else
#define GC_BARRIER_SITE(site, statement) GC_BARRIER(statement)
#define GC_BARRIER_SITE_PUBLISH(site, statement) GC_BARRIER_PUBLISH(statement)
#endif
#define GC_BARRIER_AT(statement, publication) do { \
  int gc_measuring = gc_active; \
  uint64_t gc_wall_before = GC_START(); \
  uint64_t gc_cpu_before = gc_measuring ? gc_clock(CLOCK_THREAD_CPUTIME_ID) : 0; \
  gc_barrier_site = GC_OBSERVE_BARRIER(gc_measuring) ? __LINE__ : 0; \
  gc_barrier_publication = (publication); \
  statement; \
  gc_barrier_publication = 0; \
  gc_barrier_site = 0; \
  if (gc_measuring) { \
    gc_times[gc_barrier_cpu] += gc_clock(CLOCK_THREAD_CPUTIME_ID) - gc_cpu_before; \
    ++gc_calls[gc_barrier_cpu]; \
    gc_record(gc_barrier, gc_wall_before); \
  } \
} while (0)
uint64_t dev_gc_barrier_wait_begin(void)
{
  return gc_barrier_site ? gc_clock(GC_WALL_CLOCK) : 0;
}

unsigned dev_gc_barrier_publication_site(void)
{
  return gc_barrier_publication ? gc_barrier_site : 0;
}

unsigned dev_gc_barrier_wait_site(void)
{
  return gc_barrier_site;
}

void dev_gc_barrier_wait_end(uint64_t start)
{
  if (start)
    gc_record(gc_barrier_cond, start);
}

#define GC_VALUE(bucket, expression) __extension__ ({ \
  uint64_t gc_before = gc_measure_start(bucket); \
  __auto_type gc_value = (expression); \
  gc_record(bucket, gc_before); \
  gc_value; \
})

#ifdef DEV_GC_GATE_CENSUS
#if defined(DEV_GC_ENTRY_TRACE) && !defined(DEV_GC_ROUND_TOTALS)
#define GC_TRACE_GATE(start, end) do { \
  if (gc_trace_tail) dev_gc_tail_interval(gc_alloc_gate, (start), (end)); \
} while (0)
#else
#define GC_TRACE_GATE(start, end) ((void)0)
#endif
#ifdef DEV_GC_ROUND_TOTALS
#define GC_TOTAL_GATE(start, end) do { \
  if (gc_active) { \
    gc_times[gc_alloc_gate] += (end) - (start); \
    ++gc_calls[gc_alloc_gate]; \
  } \
} while (0)
#else
#define GC_TOTAL_GATE(start, end) ((void)0)
#endif
static _Atomic uint64_t gc_gate_ns[8], gc_gate_calls[8];
/* Count gate acquisitions even in collector rounds skipped by other probes. */
#define GC_ALLOCATOR_GATE(statement) do { \
  uint64_t gate_start = gc_inside ? gc_clock(GC_WALL_CLOCK) : 0; \
  statement; \
  if (gate_start) { \
    uint64_t gate_end = gc_clock(GC_WALL_CLOCK); \
    atomic_fetch_add_explicit(&gc_gate_ns[gc_carrier], gate_end - gate_start, memory_order_relaxed); \
    atomic_fetch_add_explicit(&gc_gate_calls[gc_carrier], 1, memory_order_relaxed); \
    GC_TRACE_GATE(gate_start, gate_end); \
    GC_TOTAL_GATE(gate_start, gate_end); \
  } \
} while (0)
#else
#define GC_ALLOCATOR_GATE(statement) GC_TIMED(gc_alloc_gate, statement)
#endif

static void gc_enter(unsigned id, const void *vm)
{
  if (gc_active || id >= 8) {
    atomic_store_explicit(&gc_invalid, 1, memory_order_relaxed);
    return;
  }
#ifdef DEV_GC_GATE_CENSUS
  gc_inside = 1;
  gc_carrier = id;
#endif
#ifdef DEV_GC_ENTRY_PREFIX_ROUNDS
#ifndef DEV_GC_ENTRY_SKIP_ROUNDS
#define DEV_GC_ENTRY_SKIP_ROUNDS 0
#endif
  /* Keep the sample contiguous; the reducer matches actual VM rounds. */
  if (gc_sequence >= DEV_GC_ENTRY_SKIP_ROUNDS + DEV_GC_ENTRY_PREFIX_ROUNDS)
    return;
  unsigned sequence = gc_sequence++;
  if (sequence < DEV_GC_ENTRY_SKIP_ROUNDS)
    return;
#else
  if (gc_sequence++ % DEV_GC_SAMPLE_EVERY != 0)
    return;
#endif
  gc_carrier = id;
  gc_active = 1;
#ifdef DEV_GC_ENTRY_TRACE
  dev_gc_phase_entry(id, vm);
  gc_trace_tail = 1;
#else
  (void)vm;
#endif
  gc_cpu_start = gc_clock(CLOCK_THREAD_CPUTIME_ID);
  gc_start = gc_clock(GC_WALL_CLOCK);
}

static void gc_leave(void)
{
#ifdef DEV_GC_GATE_CENSUS
  gc_inside = 0;
#endif
  if (!gc_active)
    return;
  gc_record(gc_total, gc_start);
#ifdef DEV_GC_ROUND_TOTALS
  /* Sparse inclusive totals. Zero-duration hits still emit a receipt. */
  for (unsigned i = gc_plan; i < gc_bucket_count; ++i)
    if (i != gc_barrier_cpu && gc_calls[i])
      dev_gc_phase_total(i, gc_times[i]);
#endif
  gc_times[gc_cpu] = gc_clock(CLOCK_THREAD_CPUTIME_ID) - gc_cpu_start;
  gc_calls[gc_cpu] = 1;
  for (unsigned i = 0; i < gc_bucket_count; ++i) {
    atomic_fetch_add_explicit(&gc_sum[gc_carrier][i], gc_times[i], memory_order_relaxed);
    atomic_fetch_add_explicit(&gc_count[gc_carrier][i], gc_calls[i], memory_order_relaxed);
    gc_times[i] = gc_calls[i] = 0;
  }
#ifdef DEV_GC_TAIL_TRACE
  gc_trace_tail = 0;
#endif
  gc_active = 0;
}

__attribute__((destructor))
static void gc_dump(void)
{
  FILE *out = fopen("gc-collector.trace", "w");
  if (!out)
    return;
  for (unsigned id = 0; id < 8; ++id)
    for (unsigned i = 0; i < gc_bucket_count; ++i) {
      uint64_t n = atomic_load_explicit(&gc_count[id][i], memory_order_relaxed);
      if (n)
        fprintf(out, "%u %s %llu %llu\n", id, gc_bucket_names[i],
                (unsigned long long)n,
                (unsigned long long)atomic_load_explicit(&gc_sum[id][i], memory_order_relaxed));
    }
#ifdef DEV_GC_GATE_CENSUS
  for (unsigned id = 0; id < 8; ++id)
    fprintf(out, "%u allocator-gate-census %llu %llu\n", id,
            (unsigned long long)atomic_load_explicit(&gc_gate_calls[id], memory_order_relaxed),
            (unsigned long long)atomic_load_explicit(&gc_gate_ns[id], memory_order_relaxed));
  for (unsigned id = 0; id < 8; ++id)
    fprintf(out, "%u allocator-call-census %llu %llu\n", id,
            (unsigned long long)atomic_load_explicit(&gc_native_calls[id], memory_order_relaxed),
            (unsigned long long)atomic_load_explicit(&gc_native_ns[id], memory_order_relaxed));
#endif
#ifdef DEV_GC_ALLOCATOR_CPU
  for (unsigned id = 0; id < 8; ++id)
    fprintf(out, "%u allocator-call-thread-cpu %llu %llu\n", id,
            (unsigned long long)atomic_load_explicit(&gc_native_calls[id], memory_order_relaxed),
            (unsigned long long)atomic_load_explicit(&gc_native_cpu_ns[id], memory_order_relaxed));
#endif
#ifdef DEV_GC_PARK_METRICS
  for (unsigned id = 0; id < 8; ++id)
    for (unsigned i = 0; i < park_kind_count; ++i)
      fprintf(out, "%u %s %llu %llu\n", id, gc_park_names[i],
              (unsigned long long)atomic_load_explicit(&gc_park_calls[id][i], memory_order_relaxed),
              (unsigned long long)atomic_load_explicit(&gc_park_ns[id][i], memory_order_relaxed));
#endif
#ifdef DEV_GC_BARRIER_SITES
  for (unsigned id = 0; id < 8; ++id)
    for (unsigned site = 0; site < GC_BARRIER_SITE_LIMIT; ++site) {
      uint64_t calls = atomic_load_explicit(&gc_site_calls[id][site], memory_order_relaxed);
      if (calls)
        fprintf(out, "%u barrier-site-%u %ju %ju\n", id, site,
                (uintmax_t)calls,
                (uintmax_t)atomic_load_explicit(&gc_site_ns[id][site], memory_order_relaxed));
    }
#endif
  fprintf(out, "trace-invalid=%u\n", atomic_load_explicit(&gc_invalid, memory_order_relaxed));
  fclose(out);
}

#endif
