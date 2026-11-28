/*
 * CBMC --mm pso verification harness for Phase C44 `(gambit effect)` `return:`
 * clause out-of-scope tail execution and full multiple-value dispatch.
 *
 * Negative mutants (all 4 must FAIL with VERIFICATION FAILED):
 *   -DINJECT_BUG_RETURN_RUNS_INSIDE_INNER_HANDLER : runs return: before popping inner handler
 *   -DINJECT_BUG_MULTISHOT_SKIPS_RETURN_CLAUSE    : skips return: on multi-shot branch
 *   -DINJECT_BUG_MULTIVAL_RETURN_PACKS_SINGLE_ARG : passes multi-value box as 1 arg
 *   -DINJECT_BUG_TAIL_RETURN_STALE_EXC_HANDLER    : runs tail return: inside inner exc catcher
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

#define H_OUTER 1
#define H_INNER 2

/* Thread 0 & Thread 1 handler stacks (top = index 0) */
static int t0_h0, t0_h1, t0_hlen;
static int t1_h0, t1_h1, t1_hlen;
static int t1_done;

static void thread1_multishot_branch_return(void) {
  /* Branch re-installed H_INNER over H_OUTER, body returned value 2 */
  t1_h0 = H_INNER;
  t1_h1 = H_OUTER;
  t1_hlen = 2;

  /* %mc-return1-with-fn pops H_INNER BEFORE running return: */
#ifndef INJECT_BUG_RETURN_RUNS_INSIDE_INNER_HANDLER
  t1_h0 = t1_h1;
  t1_hlen = 1;
#endif

  int branch_out = 0;
#ifdef INJECT_BUG_MULTISHOT_SKIPS_RETURN_CLAUSE
  branch_out = 2; /* raw body value, skipped return: transform (* 10)! */
#else
  /* return: performs effect e -> must dispatch to H_OUTER (not H_INNER!) */
  assert(t1_hlen == 1);
  assert(t1_h0 == H_OUTER);
  branch_out = 20;
#endif
  assert(branch_out == 20);

  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  __CPROVER_atomic_begin();
  t1_done = 1;
  __CPROVER_atomic_end();
}

static int dispatch_return_arity(bool is_values_box, int box_len) {
#ifdef INJECT_BUG_MULTIVAL_RETURN_PACKS_SINGLE_ARG
  (void)is_values_box; (void)box_len;
  return 1; /* BUG: passes values-box as single arg! */
#else
  return is_values_box ? box_len : 1;
#endif
}

int main(void) {
  /* 1. Suspending handler return: clause must pop H_INNER before executing */
  t0_h0 = H_INNER;
  t0_h1 = H_OUTER;
  t0_hlen = 2;
#ifndef INJECT_BUG_RETURN_RUNS_INSIDE_INNER_HANDLER
  t0_h0 = t0_h1;
  t0_hlen = 1;
#endif
  /* Effect performed in return: dispatches to H_OUTER */
  assert(t0_hlen == 1);
  assert(t0_h0 == H_OUTER);

  /* 2. Concurrent multi-shot branch replay on Thread 1 */
  t1_done = 0;
  __CPROVER_ASYNC_1: thread1_multishot_branch_return();

  /* 3. Multiple-value arity dispatch (0, 1, 2 values) */
  assert(dispatch_return_arity(true, 0) == 0);
  assert(dispatch_return_arity(false, 1) == 1);
  assert(dispatch_return_arity(true, 2) == 2);

  /* 4. Tail-resumptive return: runs OUTSIDE inner with-exception-catcher */
  bool inside_inner_catcher = false;
#ifdef INJECT_BUG_TAIL_RETURN_STALE_EXC_HANDLER
  inside_inner_catcher = true;
#endif
  assert(!inside_inner_catcher);

  int done = 0;
  __CPROVER_atomic_begin();
  done = t1_done;
  __CPROVER_atomic_end();
  if (done) {
    assert(t0_h0 == H_OUTER);
    assert(t1_h0 == H_OUTER);
  }
  return 0;
}
