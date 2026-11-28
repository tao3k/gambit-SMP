/* DEV counters for actual generated join control paths. */
#include <stdatomic.h>
#include <stdio.h>

enum {
  join_wait, join_fast, join_timeout, join_capture, join_capture_return,
  join_register, join_enqueued, join_race, join_register_timeout,
  join_event_count
};

static struct {
  alignas(128) _Atomic unsigned long long events[join_event_count];
} join_counts[3];
static _Atomic unsigned join_outside_r3;

static inline void dev_join_count(___processor_state ps, unsigned event)
{
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(ps);
  ___WORD carrier = ___PROCESSOR_ID(ps, vm);
  if (carrier < 0 || carrier >= 3) {
    atomic_store_explicit(&join_outside_r3, 1, memory_order_relaxed);
    return;
  }
  atomic_fetch_add_explicit(&join_counts[carrier].events[event], 1, memory_order_relaxed);
}

/* The root takes this snapshot after both children have offered a sync op
 * and before either can receive the reply. */
void dev_join_epoch_snapshot(unsigned long long counts[3][3])
{
  for (unsigned i = 0; i < 3; ++i) {
    counts[i][0] = atomic_load_explicit(&join_counts[i].events[join_wait], memory_order_relaxed);
    counts[i][1] = atomic_load_explicit(&join_counts[i].events[join_capture], memory_order_relaxed);
    counts[i][2] = atomic_load_explicit(&join_counts[i].events[join_enqueued], memory_order_relaxed);
  }
}

__attribute__((destructor))
static void dev_join_dump(void)
{
  FILE *out = fopen("gc-join-path.trace", "w");
  if (!out) return;
  for (unsigned i = 0; i < 3; ++i) {
    fprintf(out, "%u", i);
    for (unsigned event = 0; event < join_event_count; ++event)
      fprintf(out, " %llu", atomic_load_explicit(&join_counts[i].events[event], memory_order_relaxed));
    fputc('\n', out);
  }
  fprintf(out, "trace-invalid=%u\n", atomic_load_explicit(&join_outside_r3, memory_order_relaxed));
  fclose(out);
}
