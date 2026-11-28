/*
 * Phase C15 CBMC PSO Adversarial Verification Harness:
 *   1. root-done guarded quiescence with detached fiber (no premature shutdown)
 *   2. Fused park-recv + LIFO pop under PSO (no lost wakeup, no fk aliasing)
 *   3. global-pending guarded 32-tick fairness check (no missed external task)
 *
 * Negative Mutants (each MUST FAIL under `cbmc --mm pso --unwind 4`):
 *   -DINJECT_BUG_QUIESCE_ONLY_CHECKS_ROOT_DONE
 *   -DINJECT_BUG_FUSED_PARK_SWITCH_NO_DEKKER
 *   -DINJECT_BUG_FUSED_PARK_ALIAS_FK
 *   -DINJECT_BUG_GLOBAL_PENDING_SKIP_IGNORES_NONZERO
 */

#include <assert.h>

extern void __CPROVER_fence(const char *kind, ...);
extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_assume(_Bool);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}
static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence");
}
static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

/* ============================================================================
 * Scenario 1: root-done guarded quiescence with detached fiber
 * ============================================================================ */
static int s1_root_done = 0;
static int s1_spawned0 = 1;  /* root starts spawned = 1 */
static int s1_completed0 = 0;
static int s1_completed1 = 0;
static int s1_detached_running = 0;
static int s1_premature_quiesce = 0;
static int s1_done_root = 0;
static int s1_done_det = 0;

static int check_quiescent_s1(void) {
  int rd = s1_root_done;
  fence_acquire();
  if (rd == 0) return 0;
#ifdef INJECT_BUG_QUIESCE_ONLY_CHECKS_ROOT_DONE
  return 1; /* BUG: ignores detached fiber still running! */
#else
  int c0 = s1_completed0;
  int c1 = s1_completed1;
  fence_acquire();
  fence_seq_cst();
  int sp0 = s1_spawned0;
  fence_acquire();
  return ((c0 + c1) == sp0) ? 1 : 0;
#endif
}

static void s1_thread_root_and_detached(void) {
  /* Root spawns detached fiber BEFORE setting root_done */
  s1_detached_running = 1;
  fence_release();
  s1_spawned0 = 2;
  fence_release();

  /* Root finishes body & marks root_done = 1, completed0 = 1 */
  fence_release();
  s1_root_done = 1;
  fence_release();
  s1_completed0 = 1;
  fence_release();
  s1_done_root = 1;

  /* Observer check while detached fiber is STILL running */
  if (s1_detached_running == 1 && check_quiescent_s1() == 1) {
    s1_premature_quiesce = 1;
  }

  /* Now detached fiber finishes */
  s1_detached_running = 0;
  fence_release();
  s1_completed1 = 1;
  fence_release();
  s1_done_det = 1;
}

/* ============================================================================
 * Scenario 2: Fused park-recv + LIFO pop racing with concurrent send (PSO)
 * ============================================================================ */
static int s2_seq0 = 0;     /* 0 = empty, 1 = ready */
static int s2_buf0 = -1;
static int s2_rxw = 0;
static int s2_lock = 0;
static int s2_rwq_head = 0; /* 0 = empty, 1/2 = fk id */
static int s2_woke_rx = 0;
static int s2_cons_got = -1;
static int s2_prod_done = 0;
static int s2_cons_done = 0;

/* Local worker pool & LIFO state for Scenario 2 */
static int s2_pool_head = 1; /* fk1 in pool */
static int s2_lifo_fk = 2;   /* fk2 in LIFO */
static int s2_switched_fk = 0;
static int s2_pool_aliased = 0;

static void s2_lock_acq(void) {
  int got = 0;
  __CPROVER_atomic_begin();
  if (s2_lock == 0) { s2_lock = 1; got = 1; }
  __CPROVER_atomic_end();
  __CPROVER_assume(got == 1);
  fence_acquire();
}

static void s2_lock_rel(void) {
  fence_release();
  __CPROVER_atomic_begin();
  s2_lock = 0;
  __CPROVER_atomic_end();
}

static void s2_producer(void) {
  /* Vyukov push slot 0 */
  s2_buf0 = 77;
  fence_seq_cst();
  s2_seq0 = 1;
  fence_seq_cst();
  if (s2_rxw > 0) {
    s2_woke_rx = 1;
  }
  fence_release();
  s2_prod_done = 1;
}

static void s2_consumer_fused_park_switch(void) {
  /* Fast recv sees empty (seq0 == 0) -> enters fused park-recv + LIFO pop */
  int fk = s2_pool_head;
#ifndef INJECT_BUG_FUSED_PARK_ALIAS_FK
  s2_pool_head = 0; /* Pop fk1 out of pool before parking it */
#endif

  s2_lock_acq();
#ifdef INJECT_BUG_FUSED_PARK_SWITCH_NO_DEKKER
  s2_rxw = 1; /* BUG: relaxed store without seq_cst Dekker ordering */
  int s = s2_seq0;
#else
  fence_seq_cst();
  s2_rxw = 1;
  fence_seq_cst();
  int s = s2_seq0;
  fence_seq_cst();
#endif
  if (s == 0) {
    s2_rwq_head = fk;
    if (s2_pool_head == fk) {
      s2_pool_aliased = 1;
    }
    s2_lock_rel();
    /* Fused LIFO pop in same C block */
    int next_fk = s2_lifo_fk;
    s2_lifo_fk = 0;
    s2_switched_fk = next_fk;
    /* Recycle next_fk onto pool */
    s2_pool_head = next_fk;
  } else {
    /* Race: item arrived! Abort park and consume item */
    s2_rxw = 0;
    s2_lock_rel();
    fence_acquire();
    s2_cons_got = s2_buf0;
  }
  fence_release();
  s2_cons_done = 1;
}

/* ============================================================================
 * Scenario 3: 32-tick global-pending bypass fairness check
 * ============================================================================ */
static int s3_global_q_len = 0;
static int s3_global_pending = 0;
static int s3_polled_global = 0;

static void check_global_tick31(void) {
  /* External wakeup enqueues 1 task (always increments global_pending first) */
  s3_global_pending = 1;
  fence_release();
  s3_global_q_len = 1;

  int ticks = 31;
#ifdef INJECT_BUG_GLOBAL_PENDING_SKIP_IGNORES_NONZERO
  int must_poll = 0; /* BUG: ignores global_pending > 0 on tick 31! */
#else
  int must_poll = ((ticks & 31) == 31) && (s3_global_pending > 0);
#endif
  if (must_poll) {
    s3_polled_global = 1;
    s3_global_q_len = 0;
    s3_global_pending = 0;
  }
  assert(s3_polled_global == 1);
  assert(s3_global_q_len == 0);
}

int main(void) {
  /* Scenario 1: Quiescence guard with detached fiber */
  s1_thread_root_and_detached();
  assert(s1_premature_quiesce == 0);
  assert(check_quiescent_s1() == 1);

  /* Scenario 2: Concurrent PSO fused park-recv + LIFO pop vs send */
  __CPROVER_ASYNC_1: s2_producer();
  s2_consumer_fused_park_switch();
  __CPROVER_assume(s2_prod_done == 1 && s2_cons_done == 1);
  fence_acquire();

  /* Dekker no-lost-wakeup assertion */
  assert(s2_cons_got == 77 || s2_woke_rx == 1);
  /* Fused LIFO switch fk disjointness assertion */
  if (s2_rwq_head != 0) {
    assert(s2_rwq_head != s2_switched_fk);
    assert(s2_pool_head != s2_rwq_head);
    assert(s2_pool_aliased == 0);
  }

  /* Scenario 3: 32-tick global-pending check */
  check_global_tick31();

  return 0;
}
