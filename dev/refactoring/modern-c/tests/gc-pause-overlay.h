/* DEV probe. Per-processor bounded buffers; no collection-path I/O. */
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

enum {
  pause_trace_processors = 8,
#ifdef DEV_GC_FIRST_OP
  /* Exact transfers add start, target, arrival and completion records. */
  pause_trace_capacity = 131072
#else
  pause_trace_capacity = 65536
#endif
};
struct pause_sample {
  uint64_t ns;
  uintptr_t vm;
  char kind;
  _Atomic unsigned ready;
};
static struct pause_sample pause_samples[pause_trace_processors][pause_trace_capacity];
static _Atomic unsigned pause_counts[pause_trace_processors];
static _Atomic unsigned pause_invalid;

static uint64_t pause_now(void)
{
  struct timespec ts;
#ifdef DEV_GC_RAW_UPTIME
  const clockid_t clock = CLOCK_UPTIME_RAW;
#else
  const clockid_t clock = CLOCK_MONOTONIC;
#endif
  if (clock_gettime(clock, &ts) != 0) {
    atomic_store_explicit(&pause_invalid, 1, memory_order_relaxed);
    return 0;
  }
  return (uint64_t)ts.tv_sec * 1000000000 + (uint64_t)ts.tv_nsec;
}

static void pause_record(unsigned id, const void *vm, char kind, uint64_t ns)
{
  if (id >= pause_trace_processors) {
    atomic_store_explicit(&pause_invalid, 1, memory_order_relaxed);
    return;
  }
  unsigned n = atomic_fetch_add_explicit(&pause_counts[id], 1, memory_order_relaxed);
  if (n >= pause_trace_capacity) {
    atomic_store_explicit(&pause_invalid, 1, memory_order_relaxed);
    return;
  }
  struct pause_sample *s = &pause_samples[id][n];
  s->ns = ns;
  s->vm = (uintptr_t)vm;
  s->kind = kind;
  atomic_store_explicit(&s->ready, 1, memory_order_release);
}

#ifdef DEV_GC_RESUME_LABELS
#ifdef DEV_GC_HOST_ORIGIN
#include <dlfcn.h>
#endif
#ifdef __APPLE__
#include <pthread.h>
extern void dev_gc_signpost(unsigned id, uint64_t ns);
static _Thread_local int dev_gc_clock_announced;
#ifdef DEV_GC_KERNEL_CLOCK
extern int dev_gc_kernel_clock(unsigned id, uint64_t tid, uint64_t ns);
static _Thread_local unsigned dev_gc_clock_round;
static _Thread_local uint64_t dev_gc_clock_tid;
#endif
#endif
_Thread_local int dev_gc_resume_pending;
#ifdef DEV_GC_HANDOFF_LABELS
static _Thread_local int dev_gc_handoff_observed;
#endif
#ifdef DEV_GC_FIRST_OP
static _Thread_local ___SCMOBJ dev_gc_first_target;
static _Thread_local unsigned dev_gc_first_handoffs;
static _Thread_local int dev_gc_first_ready;
static _Thread_local ___SCMOBJ dev_gc_transfer_expected;

#endif
static _Thread_local unsigned dev_gc_resume_id;
static _Thread_local const void *dev_gc_resume_vm;

#ifdef DEV_GC_FIRST_OP
int dev_gc_first_op_begin(___SCMOBJ target)
{
  int ready = dev_gc_first_ready && target == dev_gc_first_target;
  dev_gc_first_ready = 0;
#ifdef DEV_GC_CLASSIFY_ONLY
  return 0;
#endif
  if (ready) {
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'F', pause_now());
    atomic_signal_fence(memory_order_seq_cst);
  }
  return ready;
}

/* Carry the evaluated target without changing the original jump. */
___SCMOBJ dev_gc_transfer_target(___SCMOBJ target)
{
  dev_gc_transfer_expected = target;
  dev_gc_resume_pending = 2;
  pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'V', (uint64_t)target);
  return target;
}

void dev_gc_direct_start(___SCMOBJ source)
{
  if (dev_gc_first_op_begin(source)) {
    dev_gc_transfer_target(1);
    dev_gc_resume_pending = 3;
  }
}

void dev_gc_first_op_end(void)
{
  atomic_signal_fence(memory_order_seq_cst);
  pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'G', pause_now());
}

void dev_gc_direct_arrive(void)
{
  if (dev_gc_resume_pending == 3) {
    dev_gc_resume_pending = 0;
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'X', 1);
    dev_gc_first_op_end();
  }
}
#endif

static void dev_gc_arm_resume(unsigned id, const void *vm)
{
  dev_gc_resume_id = id;
  dev_gc_resume_vm = vm;
  dev_gc_resume_pending = 1;
#ifdef DEV_GC_FIRST_OP
  dev_gc_first_handoffs = 0;
  dev_gc_first_ready = 0;
#endif
#ifdef DEV_GC_HANDOFF_LABELS
  dev_gc_handoff_observed = 0;
#endif
#ifdef __APPLE__
  if (!dev_gc_clock_announced) {
    uint64_t tid = 0;
    if (pthread_threadid_np(NULL, &tid) == 0) {
      pause_record(id, vm, 'T', tid);
#ifdef DEV_GC_KERNEL_CLOCK
      dev_gc_clock_tid = tid;
#endif
      dev_gc_signpost(id, pause_now());
    }
    dev_gc_clock_announced = 1;
  }
#ifdef DEV_GC_KERNEL_CLOCK
  if (dev_gc_clock_tid && (dev_gc_clock_round++ & 127u) == 0) {
    uint64_t now = pause_now();
    int status = dev_gc_kernel_clock(id, dev_gc_clock_tid, now);
    pause_record(id, vm, status == 0 ? 'K' : 'E', now);
    uint64_t signpost_start = pause_now();
    dev_gc_signpost(id, signpost_start);
    uint64_t signpost_end = pause_now();
    pause_record(id, vm, 'S', signpost_start);
    pause_record(id, vm, 'Z', signpost_end);
  }
#endif
#endif
}

/* This observes the transfer request at the internal return, before dispatch. */
void dev_gc_return_target(___SCMOBJ target)
{
  if (dev_gc_resume_pending == 1) {
#ifdef DEV_GC_HANDOFF_LABELS
    dev_gc_handoff_observed = 1;
#endif
#ifdef DEV_GC_HANDOFF_TIMING
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'J', pause_now());
#endif
#ifdef DEV_GC_FIRST_OP
    dev_gc_first_target = target;
    ++dev_gc_first_handoffs;
#endif
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'H', (uint64_t)target);
#ifdef DEV_GC_HOST_ORIGIN
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'P',
                 (uint64_t)(uintptr_t)___LABEL_HOST_GET(target));
#endif
  }
}

void dev_gc_workload_label(___SCMOBJ target)
{
#ifdef DEV_GC_HANDOFF_LABELS
  if (!dev_gc_handoff_observed)
    return;
#endif
#ifdef DEV_GC_FIRST_OP
  dev_gc_first_ready = target && target == dev_gc_first_target && dev_gc_first_handoffs == 1;
#endif
  dev_gc_resume_pending = 0;
  uint64_t now = pause_now();
  pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'D', (uint64_t)target);
  pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'L', now);
}
#ifdef DEV_GC_FIRST_OP
void dev_gc_workload_label_kind(___SCMOBJ target, unsigned kind)
{
  if (dev_gc_resume_pending == 3) {
    dev_gc_resume_pending = 0;
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'X', 0);
    return;
  }
  if (dev_gc_resume_pending == 2) {
    dev_gc_resume_pending = 0;
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'X', (uint64_t)target);
    if (target && target == dev_gc_transfer_expected)
      dev_gc_first_op_end();
    return;
  }
  dev_gc_workload_label(target);
  if (dev_gc_first_ready)
    pause_record(dev_gc_resume_id, dev_gc_resume_vm, 'Y', kind);
}
#endif
#endif

__attribute__((destructor))
static void pause_dump(void)
{
  FILE *out = fopen("gc-pause.trace", "w");
  if (!out)
    return;
  for (unsigned id = 0; id < pause_trace_processors; ++id) {
    unsigned n = atomic_load_explicit(&pause_counts[id], memory_order_relaxed);
    for (unsigned i = 0; i < n && i < pause_trace_capacity; ++i) {
      struct pause_sample *s = &pause_samples[id][i];
      if (atomic_load_explicit(&s->ready, memory_order_acquire))
        fprintf(out, "%u %jx %c %ju\n", id, (uintmax_t)s->vm, s->kind, (uintmax_t)s->ns);
      else
        atomic_store_explicit(&pause_invalid, 1, memory_order_relaxed);
    }
  }
#if defined(DEV_GC_RESUME_LABELS) && defined(DEV_GC_HOST_ORIGIN)
  Dl_info image;
  if (dladdr((void *)(uintptr_t)dev_gc_return_target, &image))
    fprintf(out, "image-base=%ju\n", (uintmax_t)(uintptr_t)image.dli_fbase);
  else
    atomic_store_explicit(&pause_invalid, 1, memory_order_relaxed);
#endif
  fprintf(out, "trace-invalid=%u\n", atomic_load_explicit(&pause_invalid, memory_order_relaxed));
  fclose(out);
}
