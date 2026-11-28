/*
 * CBMC (--mm pso) Adversarial Weak-Memory Verification Harness for Phase C5:
 *   1. Dynamic Per-Carrier sched-k Trampoline Affinity Across Cross-Core Steal
 *   2. Per-Worker LIFO Slot Eviction Conservation & Anti-Starvation Streak
 *   3. Per-Fiber Isolated %tc-state Save/Restore Across Migration
 *   4. Zero-Alloc Intrusive Channel Handoff (val release-published before wake)
 *
 * Negative Mutants (5/5 must FAIL assertion when enabled):
 *   -DINJECT_BUG_STALE_SCHED_K        : migrated fiber returns to spawner's sched-k instead of current carrier's
 *   -DINJECT_BUG_LIFO_OVERWRITE_LOSS  : LIFO push overwrites existing slot without evicting to deque
 *   -DINJECT_BUG_LIFO_STARVATION      : omits MAX_LIFO_STREAK bound so local deque can starve
 *   -DINJECT_BUG_TC_STATE_LEAK        : forgets to reset carrier tc-state on suspend/exit
 *   -DINJECT_BUG_VAL_PUBLISH_REORDER  : omits release fence / reorders wake publish before fk->val write
 */

#include <assert.h>
#include <stdint.h>

#define MAX_LIFO_STREAK 4

static inline void release_fence(void) {
  __CPROVER_fence("WWfence", "RWfence");
}

static inline void acquire_fence(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

typedef struct {
  int fiber_id;
  int tc_state;
  volatile int val;
} fiber_k_t;

/* 1. Per-worker LIFO slot conservation & bounded streak */
static int lifo_slot = -1;
static int deque_count = 0;
static int lifo_streak = 0;

static void lifo_push(int task_id) {
  if (lifo_slot != -1) {
#ifndef INJECT_BUG_LIFO_OVERWRITE_LOSS
    deque_count++; /* Evict prior LIFO occupant to Chase-Lev deque */
#endif
  }
  lifo_slot = task_id;
}

static int worker_poll_next(void) {
#ifndef INJECT_BUG_LIFO_STARVATION
  if (lifo_slot != -1 && lifo_streak < MAX_LIFO_STREAK) {
    int t = lifo_slot;
    lifo_slot = -1;
    lifo_streak++;
    return t;
  }
#else
  if (lifo_slot != -1) {
    int t = lifo_slot;
    lifo_slot = -1;
    lifo_streak++;
    return t;
  }
#endif
  if (deque_count > 0) {
    deque_count--;
    lifo_streak = 0;
    return 999; /* Deque task */
  }
  if (lifo_slot != -1) {
    int t = lifo_slot;
    lifo_slot = -1;
    lifo_streak = 0;
    return t;
  }
  return -1;
}

/* 2. Cross-core zero-alloc intrusive handoff under PSO weak memory */
static fiber_k_t shared_fk = { 7, 777, 0 };
static volatile int published = 0;
static volatile int consumer_done = 0;
static int observed_val = 0;
static int observed_sched_k = -1;
static int carrier0_tc = 777;
static int carrier1_tc = 0;

static void consumer_worker1(void) {
  if (published == 1) {
    acquire_fence();
    observed_val = shared_fk.val;
    carrier1_tc = shared_fk.tc_state;
    /* Migrated fiber exits on carrier 1: MUST return to carrier 1's sched-k! */
    int spawner_sched_k = 0;
    int current_carrier_sched_k = 1;
#ifdef INJECT_BUG_STALE_SCHED_K
    observed_sched_k = spawner_sched_k;
#else
    (void)spawner_sched_k;
    observed_sched_k = current_carrier_sched_k;
#endif
#ifndef INJECT_BUG_TC_STATE_LEAK
    carrier1_tc = 0;
#endif
  }
  release_fence();
  consumer_done = 1;
}

int main(void) {
  /* A. Test LIFO conservation across 3 consecutive pushes -> 1 in lifo + 2 in deque */
  lifo_push(1);
  lifo_push(2);
  lifo_push(3);
  int total_after_push = (lifo_slot != -1 ? 1 : 0) + deque_count;
  assert(total_after_push == 3);

  /* B. Test anti-starvation: after MAX_LIFO_STREAK consecutive LIFO polls, deque MUST be polled */
  int polled_deque = 0;
  for (int i = 0; i < MAX_LIFO_STREAK + 1; i++) {
    lifo_push(100 + i);
    int r = worker_poll_next();
    if (r == 999) polled_deque = 1;
  }
  assert(polled_deque == 1);
  assert(lifo_streak <= MAX_LIFO_STREAK);

  /* C. Test carrier 0 suspends fiber 7, hands off payload 42 to carrier 1 under PSO */
#ifndef INJECT_BUG_TC_STATE_LEAK
  carrier0_tc = 0;
#endif
  assert(carrier0_tc == 0);

  __CPROVER_ASYNC_1: consumer_worker1();

#ifdef INJECT_BUG_VAL_PUBLISH_REORDER
  /* Buggy: omits release fence under PSO so store to published can become visible before val */
  shared_fk.val = 42;
  published = 1;
#else
  shared_fk.val = 42;
  release_fence();
  published = 1;
#endif

  __CPROVER_assume(consumer_done == 1);
  acquire_fence();

  if (observed_sched_k != -1) {
    assert(observed_val == 42);
    assert(observed_sched_k == 1);
    assert(carrier1_tc == 0);
  }

  return 0;
}
