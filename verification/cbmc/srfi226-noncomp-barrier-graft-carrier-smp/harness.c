/*
 * CBMC --mm pso verification harness for Phase C43:
 *   1. Non-composable / prompted call/1cc barrier prefix capture & restore
 *      (preserves outer barriers at invocation site; avoids false-positive
 *       rejection when outer barrier was outside delimiting prompt; still
 *       blocks illegal entry into an inner barrier captured inside prompt).
 *   2. Post-unwind ##continuation-graft landing thunk re-fetching (%tc-current)
 *      after carrier migration during dynamic-wind after-thunk (zero cross-
 *      carrier corruption under PSO).
 *
 * Negative mutants (all 4 must FAIL with VERIFICATION FAILED):
 *   -DINJECT_BUG_NONCOMP_WIPES_OUTER_BARRIER             : overwrites st.barriers with cap_barriers
 *   -DINJECT_BUG_NONCOMP_CAPTURES_OUTER_BARRIER_FALSE_POS: captures full st.barriers instead of prefix
 *   -DINJECT_BUG_NONCOMP_ALLOWS_INNER_BARRIER_ENTRY      : skips entering-barrier check
 *   -DINJECT_BUG_LANDING_THUNK_STALE_CARRIER_ST          : landing thunk writes stale carrier 0 st
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

#define B_OUTER1 1
#define B_OUTER2 2
#define B_INNER  3

/* Two SMP carrier threads' control states (mc depth) */
static int carrier0_mc;
static int carrier1_mc;
static int carrier1_done;

static void carrier1_run_landing_thunk(void) {
  /* Fiber migrated from carrier 0 to carrier 1 during dynamic-wind after-thunk.
     Landing thunk must commit mc=0 to carrier 1, NOT stale carrier 0! */
#ifdef INJECT_BUG_LANDING_THUNK_STALE_CARRIER_ST
  __CPROVER_atomic_begin();
  carrier0_mc = 999; /* corrupts carrier 0's active mc! */
  __CPROVER_atomic_end();
#else
  __CPROVER_atomic_begin();
  carrier1_mc = 0;
  __CPROVER_atomic_end();
#endif
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  __CPROVER_atomic_begin();
  carrier1_done = 1;
  __CPROVER_atomic_end();
}

int main(void) {
  /* --- Case A: non-composable k (cap_barriers = empty) invoked inside B_OUTER2 --- */
  int cap_a = 0; /* no barrier between capture and t-in */
  int cur_pf_b = B_OUTER2;
#ifdef INJECT_BUG_NONCOMP_WIPES_OUTER_BARRIER
  int restored_a = cap_a; /* BUG: wipes B_OUTER2! */
#else
  int restored_a = (cap_a == 0) ? cur_pf_b : cap_a;
#endif
  assert(restored_a == B_OUTER2);

  /* --- Case B: non-composable k captured inside B_OUTER1 -> prompt t-in -> capture --- */
  /* B_OUTER1 is outside t-in, so prefix(st.barriers={B_OUTER1}, pf.barriers={B_OUTER1}) = 0 */
#ifdef INJECT_BUG_NONCOMP_CAPTURES_OUTER_BARRIER_FALSE_POS
  int cap_b = B_OUTER1; /* BUG: captures outer barrier outside t-in! */
#else
  int cap_b = 0;
#endif
  /* Invoking outside B_OUTER1 (cur_barriers = 0): must NOT be blocked! */
  bool blocked_b = (cap_b != 0);
  assert(!blocked_b);

  /* --- Case C: non-composable k captured inside prompt t-in -> B_INNER -> capture --- */
  int cap_c = B_INNER;
  int cur_c_outside = B_OUTER1;
#ifdef INJECT_BUG_NONCOMP_ALLOWS_INNER_BARRIER_ENTRY
  bool blocked_c = false;
#else
  bool blocked_c = (cap_c != 0 && cap_c != cur_c_outside);
#endif
  assert(blocked_c);

  /* --- Case D: SMP carrier migration during dynamic-wind after-thunk --- */
  carrier0_mc = 2; /* Carrier 0 is now running an unrelated fiber with mc depth 2 */
  carrier1_mc = 1; /* Carrier 1 holds the migrated fiber's prompt frame before commit */
  carrier1_done = 0;

  __CPROVER_ASYNC_1: carrier1_run_landing_thunk();

  /* Carrier 0 concurrently reads its own mc depth: must remain 2 */
  __CPROVER_atomic_begin();
  int c0_mid = carrier0_mc;
  __CPROVER_atomic_end();
  assert(c0_mid == 2);

  int done = 0;
  __CPROVER_atomic_begin();
  done = carrier1_done;
  __CPROVER_atomic_end();
  if (done) {
    __CPROVER_atomic_begin();
    int c0_end = carrier0_mc;
    int c1_end = carrier1_mc;
    __CPROVER_atomic_end();
    assert(c0_end == 2);
    assert(c1_end == 0);
  }
  return 0;
}
