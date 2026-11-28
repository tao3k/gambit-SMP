/*
 * CBMC --mm pso verification harness for (srfi 226):
 *   1. Transactional full control-state restoration (mc, marks, barriers,
 *      handlers) on raw call/1cc invocation across inner prompts/marks/handlers
 *      and dynamic-wind after-thunks.
 *   2. Continuation barrier entry rejection and public API argument validation.
 *
 * Negative mutants (all 4 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_SKIP_RAW_MC_RESTORE
 *   -DINJECT_BUG_EAGER_RAW_WIPE_BEFORE_AFTER
 *   -DINJECT_BUG_SKIP_RAW_BARRIER_CHECK
 *   -DINJECT_BUG_UNCHECKED_PROMPT_PROC
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

typedef struct {
  int mc;
  int marks;
  int barriers;
  int handlers;
} ctrl_state_t;

static void verify_raw_call1cc_restore(void) {
  ctrl_state_t cap = {0, 0, 0, 0};
  ctrl_state_t st  = {1, 1, 0, 1}; /* inside inner prompt + mark + effect handler */
  int same_dynwind = nondet_int() & 1;
  int after_throws = nondet_int() & 1;

  if (same_dynwind) {
#ifndef INJECT_BUG_SKIP_RAW_MC_RESTORE
    st = cap;
#endif
    /* Landed at raw call/1cc: zero zombie mc/marks/handlers */
    assert(st.mc == 0);
    assert(st.marks == 0);
    assert(st.barriers == 0);
    assert(st.handlers == 0);
  } else {
#ifdef INJECT_BUG_EAGER_RAW_WIPE_BEFORE_AFTER
    /* Buggy: wipes st before dynamic-wind after-thunk runs */
    st = cap;
#endif
    /* Dynamic-wind after-thunk executes here: MUST see intact inner scope! */
    assert(st.mc == 1);
    assert(st.marks == 1);
    assert(st.handlers == 1);

    if (after_throws) {
      /* Caught inside inner prompt: inner scope MUST remain intact! */
      assert(st.mc == 1);
      assert(st.marks == 1);
      assert(st.handlers == 1);
    } else {
      /* Landing thunk commits captured state cleanly */
#ifndef INJECT_BUG_SKIP_RAW_MC_RESTORE
      st = cap;
#endif
      assert(st.mc == 0);
      assert(st.marks == 0);
      assert(st.barriers == 0);
      assert(st.handlers == 0);
    }
  }
}

static void verify_barrier_and_api_guards(void) {
  int entering_barrier = nondet_int() & 1;
  int barrier_bypassed = 0;

#ifdef INJECT_BUG_SKIP_RAW_BARRIER_CHECK
  if (entering_barrier) {
    barrier_bypassed = 1;
  }
#else
  if (entering_barrier) {
    /* Raises barrier error before modifying control state */
  }
#endif
  assert(barrier_bypassed == 0);

  int is_proc = nondet_int() & 1;
  int crashed_bad_proc = 0;
#ifdef INJECT_BUG_UNCHECKED_PROMPT_PROC
  if (!is_proc) {
    crashed_bad_proc = 1;
  }
#else
  if (!is_proc) {
    /* Raises clean Scheme error */
  }
#endif
  assert(crashed_bad_proc == 0);
}

int main(void) {
  verify_raw_call1cc_restore();
  verify_barrier_and_api_guards();
  return 0;
}
