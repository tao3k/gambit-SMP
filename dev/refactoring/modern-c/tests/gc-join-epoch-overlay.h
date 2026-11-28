/* DEV-only R3 tree receipts. No Scheme allocation or collection-path I/O. */
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

extern void dev_join_epoch_snapshot(unsigned long long counts[3][3]);

enum { join_epoch_limit = 8192 };
struct join_epoch_sample {
  unsigned long long counts[3][3];
  uint64_t cut;
  uint64_t publish[2];
  _Atomic uint64_t consume[2];
  _Atomic unsigned route[2];
  _Atomic uint64_t wait_enter[2];
  _Atomic uint64_t wait_return[2];
};

static struct join_epoch_sample join_epochs[join_epoch_limit];
static _Atomic unsigned join_ticket[2];
static _Atomic unsigned join_epoch_invalid;
static unsigned join_epoch_count;

static uint64_t join_epoch_now(void)
{
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
    atomic_store_explicit(&join_epoch_invalid, 1, memory_order_relaxed);
    return 0;
  }
  return (uint64_t)ts.tv_sec * 1000000000 + ts.tv_nsec;
}

#ifdef DEV_GC_JOIN_KERNEL_CLOCK
#include <pthread.h>
extern int dev_gc_kernel_clock(unsigned id, uint64_t tid, uint64_t ns);
static _Atomic uint64_t join_kernel_tid[3];

static uint64_t join_epoch_wait_clock(unsigned carrier)
{
  uint64_t tid = atomic_load_explicit(&join_kernel_tid[carrier], memory_order_relaxed);
  if (!tid) {
    if (pthread_threadid_np(NULL, &tid) != 0) {
      atomic_store_explicit(&join_epoch_invalid, 1, memory_order_relaxed);
      return 0;
    }
    atomic_store_explicit(&join_kernel_tid[carrier], tid, memory_order_relaxed);
  }
  uint64_t stamp = join_epoch_now();
  dev_gc_kernel_clock(carrier, tid, stamp);
  return stamp;
}
#else
#define join_epoch_wait_clock(carrier) join_epoch_now()
#endif

static void join_epoch_begin(void)
{
  if (join_epoch_count == join_epoch_limit) {
    atomic_store_explicit(&join_epoch_invalid, 1, memory_order_relaxed);
    return;
  }
  struct join_epoch_sample *row = &join_epochs[join_epoch_count++];
  dev_join_epoch_snapshot(row->counts);
  row->cut = join_epoch_now();
}

static void join_epoch_publish(unsigned recipient)
{
  if (atomic_load_explicit(&join_epoch_invalid, memory_order_relaxed)) return;
  unsigned index = recipient - 1;
  join_epochs[join_epoch_count - 1].publish[index] = join_epoch_now();
  atomic_store_explicit(&join_ticket[index], join_epoch_count, memory_order_relaxed);
}

#ifdef DEV_GC_JOIN_PUBLICATION_CLOCK
extern void dev_gc_kernel_release(unsigned ticket, unsigned recipient, unsigned after);

static void join_epoch_release(unsigned recipient, unsigned after)
{
  if (!atomic_load_explicit(&join_epoch_invalid, memory_order_relaxed))
    dev_gc_kernel_release(join_epoch_count, recipient, after);
}
#else
#define join_epoch_release(recipient, after) ((void)0)
#endif

static void join_epoch_consume(unsigned recipient, unsigned route,
                               uint64_t wait_enter, uint64_t wait_return)
{
  unsigned index = recipient - 1;
  unsigned ticket = atomic_load_explicit(&join_ticket[index], memory_order_relaxed);
  if (!ticket) {
    atomic_store_explicit(&join_epoch_invalid, 1, memory_order_relaxed);
    return;
  }
  atomic_store_explicit(&join_epochs[ticket - 1].route[index], route, memory_order_relaxed);
  atomic_store_explicit(&join_epochs[ticket - 1].wait_enter[index], wait_enter, memory_order_relaxed);
  atomic_store_explicit(&join_epochs[ticket - 1].wait_return[index], wait_return, memory_order_relaxed);
  uint64_t prior = atomic_exchange_explicit(&join_epochs[ticket - 1].consume[index],
                                             join_epoch_now(), memory_order_relaxed);
  if (prior) atomic_store_explicit(&join_epoch_invalid, 1, memory_order_relaxed);
}

__attribute__((destructor))
static void join_epoch_dump(void)
{
  FILE *out = fopen("gc-join-epoch.trace", "w");
  if (!out) return;
  for (unsigned i = 0; i < join_epoch_count; ++i) {
    struct join_epoch_sample *row = &join_epochs[i];
    fprintf(out, "%u %llu", i + 1, (unsigned long long)row->cut);
    for (unsigned j = 0; j < 2; ++j) {
      uint64_t seen = atomic_load_explicit(&row->consume[j], memory_order_relaxed);
      fprintf(out, " %llu %llu", (unsigned long long)row->publish[j], (unsigned long long)seen);
    }
    for (unsigned j = 0; j < 2; ++j)
      fprintf(out, " %u", atomic_load_explicit(&row->route[j], memory_order_relaxed));
    for (unsigned j = 0; j < 2; ++j)
      fprintf(out, " %llu %llu",
              (unsigned long long)atomic_load_explicit(&row->wait_enter[j], memory_order_relaxed),
              (unsigned long long)atomic_load_explicit(&row->wait_return[j], memory_order_relaxed));
    for (unsigned c = 0; c < 3; ++c)
      for (unsigned event = 0; event < 3; ++event)
        fprintf(out, " %llu", row->counts[c][event]);
    fputc('\n', out);
  }
#ifdef DEV_GC_JOIN_KERNEL_CLOCK
  for (unsigned c = 1; c < 3; ++c)
    fprintf(out, "tid %u %llu\n", c,
            (unsigned long long)atomic_load_explicit(&join_kernel_tid[c], memory_order_relaxed));
#endif
  fprintf(out, "trace-invalid=%u\n", atomic_load_explicit(&join_epoch_invalid, memory_order_relaxed));
  fclose(out);
}
