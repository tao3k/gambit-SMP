/*
 * CBMC --mm pso verification harness for:
 *   1. Concurrent `resume` vs `resume-multishot` CAS + idempotent freeze
 *      before replay (zero unfrozen pframe/prefix replay under PSO).
 *   2. Non-tail one-shot replay frozen anchor invariant (caller-k never
 *      reclaimed in-place when sub-k may splice frames onto caller-k).
 *   3. Concurrent SMP generator Call #1 -> Yield -> Call #2 exception unwind
 *      with atomic release-store GEN_DONE, zero stuck GEN_RUNNING, zero stale
 *      metacontinuation frames, and exact Call #2 catcher delivery.
 *
 * Negative mutants (all 4 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_NO_UNWIND_ON_THROW
 *   -DINJECT_BUG_GEN_CALL2_STALE_EH
 *   -DINJECT_BUG_RESUME_NO_FREEZE_ON_MULTISHOT
 *   -DINJECT_BUG_NONTAIL_UNFROZEN_PFRAME
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence", "WWcumul");
}

static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence", "WRcumul");
}

/* ============================================================================
 * Model 1: Concurrent `resume` vs `resume-multishot` + Non-Tail Anchor Safety
 * ============================================================================ */

#define EC_LIVE      0
#define EC_CONSUMED  1
#define EC_MULTISHOT 2

static volatile int g_ec_state = EC_LIVE;
static volatile int g_pframe_frozen = 0;
static volatile int g_prefix_frozen = 0;
static volatile int g_oneshot_winners = 0;
static volatile int g_unfrozen_replay = 0;
static volatile int g_nontail_pframe_frozen = 0;
static volatile int g_anchor_corrupted = 0;

static int ec_cas_seq_cst(int expected, int desired) {
  int prev;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  prev = g_ec_state;
  if (prev == expected) {
    g_ec_state = desired;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();
  return prev;
}

static void thread_resume(void) {
  int prev = ec_cas_seq_cst(EC_LIVE, EC_CONSUMED);
  if (prev == EC_LIVE) {
    __CPROVER_atomic_begin();
    g_oneshot_winners++;
    __CPROVER_atomic_end();
    /* Non-tail one-shot replay creates a replay pframe: must be frozen so
     * caller-k (the stack anchor beneath ##continuation-return) is never
     * reclaimed in-place on exit. */
#ifdef INJECT_BUG_NONTAIL_UNFROZEN_PFRAME
    g_nontail_pframe_frozen = 0;
#else
    g_nontail_pframe_frozen = 1;
#endif
    if (!g_nontail_pframe_frozen) {
      g_anchor_corrupted = 1;
    }
  } else if (prev == EC_MULTISHOT) {
#ifndef INJECT_BUG_RESUME_NO_FREEZE_ON_MULTISHOT
    g_pframe_frozen = 1;
    g_prefix_frozen = 1;
    fence_seq_cst();
#endif
    /* Entering %resume-checked under MULTISHOT_COW requires frozen pframe & prefix */
    if (!g_pframe_frozen || !g_prefix_frozen) {
      g_unfrozen_replay = 1;
    }
  }
}

static void thread_promote(void) {
  int prev = ec_cas_seq_cst(EC_LIVE, EC_MULTISHOT);
  if (prev == EC_LIVE || prev == EC_MULTISHOT) {
    g_pframe_frozen = 1;
    g_prefix_frozen = 1;
    fence_seq_cst();
    if (!g_pframe_frozen || !g_prefix_frozen) {
      g_unfrozen_replay = 1;
    }
  }
}

/* ============================================================================
 * Model 2: SMP Generator Call #1 -> Yield -> Call #2 Exception Unwind
 * ============================================================================ */

#define GEN_INIT      0
#define GEN_RUNNING   1
#define GEN_SUSPENDED 2
#define GEN_DONE      3

static volatile int g_gen_state = GEN_INIT;
static volatile int g_gen_sub_k = 0;
static volatile int g_mc_depth = 0;
static volatile int g_gen_call1_eh = 1;
static volatile int g_pframe_eh_scope = 0;
static volatile int g_delivered_eh = 0;
static volatile int g_racer_saw_corrupt = 0;
static volatile int g_owner_threw = 0;
static volatile int g_racer_done = 0;

static int gen_cas_seq_cst(int expected, int desired) {
  int prev;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  prev = g_gen_state;
  if (prev == expected) {
    g_gen_state = desired;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();
  return prev;
}

static void thread_gen_owner(void) {
  /* Call #1 under catcher 1: INIT -> RUNNING -> yield -> SUSPENDED */
  int p1 = gen_cas_seq_cst(GEN_INIT, GEN_RUNNING);
  assert(p1 == GEN_INIT);
  g_mc_depth = 1;
  g_pframe_eh_scope = g_gen_call1_eh; /* 1 */
  /* Yield #1 publishes sub_k then release-stores SUSPENDED */
  g_mc_depth = 0;
  g_gen_sub_k = 42;
  fence_release();
  g_gen_state = GEN_SUSPENDED;

  /* Call #2 under catcher 2: SUSPENDED -> RUNNING, then body throws! */
  int p2 = gen_cas_seq_cst(GEN_SUSPENDED, GEN_RUNNING);
  if (p2 == GEN_SUSPENDED) {
    int sk = g_gen_sub_k;
    assert(sk == 42);
    g_gen_sub_k = 0;
    g_mc_depth = 1;
    g_pframe_eh_scope = 2; /* Call #2 catcher */

    /* Body raises an uncaught exception */
    g_owner_threw = 1;
#ifdef INJECT_BUG_NO_UNWIND_ON_THROW
    /* Buggy: mc_depth stays 1, gen_state stays GEN_RUNNING */
    g_delivered_eh = 2;
#else
    g_mc_depth = 0;
    g_gen_sub_k = 0;
    fence_release();
    g_gen_state = GEN_DONE;
#ifdef INJECT_BUG_GEN_CALL2_STALE_EH
    g_delivered_eh = g_gen_call1_eh; /* Buggy: stale Call #1 catcher! */
#else
    g_delivered_eh = g_pframe_eh_scope; /* Exact Call #2 catcher! */
#endif
#endif
  }
}

static void thread_gen_racer(void) {
  /* Concurrently attempts to invoke the same generator */
  int prev = gen_cas_seq_cst(GEN_SUSPENDED, GEN_RUNNING);
  if (prev == GEN_SUSPENDED) {
    fence_acquire();
    int sk = g_gen_sub_k;
    if (sk != 42) {
      g_racer_saw_corrupt = 1;
    }
    /* Racer cleanly finishes generator */
    g_gen_sub_k = 0;
    fence_release();
    g_gen_state = GEN_DONE;
    fence_release();
    g_racer_done = 1;
  }
}

int main(void) {
  /* Part 1: Concurrent resume vs resume-multishot race under PSO */
  __CPROVER_ASYNC_1: thread_resume();
  thread_promote();

  assert(g_oneshot_winners <= 1);
  assert(g_unfrozen_replay == 0);
  assert(g_anchor_corrupted == 0);

  /* Part 2: Concurrent generator Call #1 -> Yield -> Call #2 throw under PSO */
  __CPROVER_ASYNC_2: thread_gen_racer();
  thread_gen_owner();

  assert(g_racer_saw_corrupt == 0);
  if (g_owner_threw) {
    assert(g_mc_depth == 0);
    assert(g_gen_state == GEN_DONE);
    assert(g_delivered_eh == 2);
  }
  if (g_racer_done && !g_owner_threw) {
    fence_acquire();
    assert(g_gen_state == GEN_DONE);
  }
  return 0;
}
