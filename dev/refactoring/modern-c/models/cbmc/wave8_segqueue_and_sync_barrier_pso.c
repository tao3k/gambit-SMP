/*
 * Wave 8 CBMC Weak-Memory (PSO) Formal Verification Harness:
 *   1. Segmented Lock-Free MPMC FIFO Queue (Crossbeam/Vyukov single-use segments):
 *      Proves producer slot-publication release/acquire ordering and lazy
 *      segment-next link publication prevent torn/uninitialized reads under PSO.
 *   2. Active-Subset OS Futex Synchronization Barrier (barrier_sync_op_ex):
 *      Proves Dekker seq_cst waiter publication prevents lost wakeups AND
 *      double-buffered payload release/acquire prevents stale sop visibility.
 *
 * Safe verification:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 4 \
 *     dev/refactoring/modern-c/models/cbmc/wave8_segqueue_and_sync_barrier_pso.c
 *
 * Mutation-killing checks (each MUST fail with exit code 10):
 *   -DMUTANT_SEGQ_DROP_SLOT_RELEASE
 *   -DMUTANT_SEGQ_DROP_NEXT_RELEASE
 *   -DMUTANT_SYNCBAR_DROP_WAKE_FENCE
 *   -DMUTANT_SYNCBAR_DROP_PAYLOAD_RELEASE
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *kind, ...);

static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence");
}

static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

/* ============================================================================
 * Model 1: Segmented Lock-Free MPMC Queue (2 segments x 1 slot, PSO handoff)
 * ============================================================================ */

static int seg0_slot = 0;
static int seg0_state = 0;   /* 0=EMPTY, 1=READY */
static int seg0_next_ready = 0; /* 0=NULL, 1=linked seg1 */
static int seg1_base = 0;
static int seg1_slot = 0;
static int seg1_state = 0;

static int q_tail_ticket = 0;
static int q_head_ticket = 0;

static int c_obs_slot0 = -1;
static int c_obs_base1 = -1;
static int c_obs_slot1 = -1;

static void segq_producer(void) {
  /* Enqueue item 0 into seg0 (ticket 0 -> 1) */
  __CPROVER_atomic_begin();
  int t0 = q_tail_ticket;
  q_tail_ticket = t0 + 1;
  __CPROVER_atomic_end();

  seg0_slot = 42;
#ifndef MUTANT_SEGQ_DROP_SLOT_RELEASE
  fence_release();
#endif
  seg0_state = 1;

  /* Link seg1 lazily for ticket 1 -> 2 */
  seg1_base = 1;
#ifndef MUTANT_SEGQ_DROP_NEXT_RELEASE
  fence_release();
#endif
  seg0_next_ready = 1;

  __CPROVER_atomic_begin();
  int t1 = q_tail_ticket;
  q_tail_ticket = t1 + 1;
  __CPROVER_atomic_end();

  seg1_slot = 99;
#ifndef MUTANT_SEGQ_DROP_SLOT_RELEASE
  fence_release();
#endif
  seg1_state = 1;
}

static void segq_consumer(void) {
  /* Consume item 0 once seg0_state == 1 */
  int st0 = seg0_state;
  if (st0 == 1) {
    fence_acquire();
    c_obs_slot0 = seg0_slot;
    __CPROVER_atomic_begin();
    q_head_ticket = 1;
    __CPROVER_atomic_end();
  }

  /* Follow seg0 -> seg1 once seg0_next_ready == 1 */
  int nxt = seg0_next_ready;
  if (nxt == 1) {
    fence_acquire();
    c_obs_base1 = seg1_base;
    int st1 = seg1_state;
    if (st1 == 1) {
      fence_acquire();
      c_obs_slot1 = seg1_slot;
      __CPROVER_atomic_begin();
      q_head_ticket = 2;
      __CPROVER_atomic_end();
    }
  }
}

/* ============================================================================
 * Model 2: Active-Subset OS Futex Sync Barrier (Dekker seq_cst + Double Buffer)
 * ============================================================================ */

static int bar_gen = 0;
static int bar_waiters = 0;
static int bar_out_sop[2] = {0, 0};
static int bar_slept = 0;
static int bar_woken = 0;
static int waiter_obs_sop = -1;

static void syncbar_waiter(void) {
  int my_gen = 0;
  /* Fast spin misses -> publish waiter flag with seq_cst */
  bar_waiters = 1;
  fence_seq_cst();

  int g = bar_gen;
  if (g == my_gen) {
    bar_slept = 1;
  } else {
    fence_acquire();
    waiter_obs_sop = bar_out_sop[my_gen & 1];
  }
}

static void syncbar_leader(void) {
  int my_gen = 0;
  /* Last arriver publishes double-buffered out_sop, advances gen, checks waiters */
  bar_out_sop[my_gen & 1] = 777;
#ifndef MUTANT_SYNCBAR_DROP_PAYLOAD_RELEASE
  fence_release();
#endif
  bar_gen = my_gen + 1;
#ifndef MUTANT_SYNCBAR_DROP_WAKE_FENCE
  fence_seq_cst();
#endif
  if (bar_waiters != 0) {
    bar_woken = 1;
  }
}

int main(void) {
  /* Check 1: Segmented MPMC queue PSO visibility */
  __CPROVER_ASYNC_1: segq_producer();
  segq_consumer();
  if (c_obs_slot0 != -1) {
    assert(c_obs_slot0 == 42);
  }
  if (c_obs_base1 != -1) {
    assert(c_obs_base1 == 1);
  }
  if (c_obs_slot1 != -1) {
    assert(c_obs_slot1 == 99);
  }

  /* Check 2: Active-subset OS futex sync barrier Dekker + payload visibility */
  __CPROVER_ASYNC_2: syncbar_waiter();
  syncbar_leader();
  if (bar_slept) {
    assert(bar_woken == 1);
  }
  if (waiter_obs_sop != -1) {
    assert(waiter_obs_sop == 777);
  }
  return 0;
}
