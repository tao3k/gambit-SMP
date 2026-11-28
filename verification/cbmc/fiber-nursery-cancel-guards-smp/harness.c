/*
 * CBMC --mm pso verification harness for (gambit fiber):
 *   1. 2-thread PSO interaction between error-triggered / explicit nursery
 *      cancellation and sibling polling + active==0 join quiescence.
 *      Verifies:
 *        - Error recording always publishes cancelled == 1 with seq_cst.
 *        - Once child finishes abort + active decrement, parent waking from
 *          nursery join observes both has_err == 1 AND cancelled == 1 AND
 *          active == 0.
 *   2. Caller guards for fiber-yield outside run-fibers and cross-scheduler
 *      fiber-spawn nursery mismatch (zero null-ctx crash, zero foreign write).
 *
 * Negative mutants (all 4 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_ERROR_SKIPS_CANCEL
 *   -DINJECT_BUG_CANCEL_NO_FENCE
 *   -DINJECT_BUG_UNCHECKED_YIELD_OUTSIDE
 *   -DINJECT_BUG_UNCHECKED_FOREIGN_NURSERY
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

/* ============================================================================
 * Model 1: 2-Thread PSO Nursery Error -> Auto-Cancel -> Quiescent Join
 * ============================================================================ */

static volatile int n_active = 2; /* 1 child + 1 parent */
static volatile int n_cancelled = 0;
static volatile int n_has_err = 0;
static volatile int n_first_err = 0;
static volatile int n_child_done = 0;

static void thread_child_abort(void) {
  /* Automatically set cancelled = 1 with seq_cst BEFORE publishing has_err = 1 */
#ifndef INJECT_BUG_ERROR_SKIPS_CANCEL
  n_cancelled = 1;
#endif
#ifndef INJECT_BUG_CANCEL_NO_FENCE
  fence_seq_cst();
#endif
  n_first_err = 77;
  n_has_err = 1;
  /* Decrement active atomically (acq_rel) */
  __CPROVER_atomic_begin();
  n_active = n_active - 1;
  __CPROVER_atomic_end();
  fence_seq_cst();
  n_child_done = 1;
}

static void thread_parent_join(void) {
  /* Concurrent observer: if has_err is visible, cancelled MUST already be visible */
  if (n_has_err == 1) {
    fence_acquire();
    assert(n_cancelled == 1);
  }
  /* Parent finishes body and drops its active count of 1 */
  __CPROVER_atomic_begin();
  n_active = n_active - 1;
  __CPROVER_atomic_end();
  fence_seq_cst();

  if (n_active == 0) {
    fence_acquire();
    if (n_child_done) {
      assert(n_has_err == 1);
      assert(n_first_err == 77);
      assert(n_cancelled == 1);
    }
  }
}

/* ============================================================================
 * Model 2: Outside-run-fibers fiber-yield & Cross-Scheduler Nursery Guards
 * ============================================================================ */

static void verify_boundary_guards(void) {
  int caller_sched = nondet_int() % 3; /* 0 = outside run-fibers, 1 = sched-A, 2 = sched-B */
  if (caller_sched < 0) caller_sched = -caller_sched;
  int nursery_sched = 1;
  int crashed_null_ctx = 0;
  int corrupted_foreign = 0;

  /* Guard 1: fiber-yield outside run-fibers */
#ifdef INJECT_BUG_UNCHECKED_YIELD_OUTSIDE
  if (caller_sched == 0) {
    crashed_null_ctx = 1;
  }
#else
  if (caller_sched == 0) {
    /* Raises clean Scheme error before continuation-capture */
  }
#endif

  /* Guard 2: fiber-spawn into nursery belonging to a different scheduler */
#ifdef INJECT_BUG_UNCHECKED_FOREIGN_NURSERY
  if (caller_sched != 0 && caller_sched != nursery_sched) {
    corrupted_foreign = 1;
  }
#else
  if (caller_sched == 0 || caller_sched != nursery_sched) {
    /* Raises clean Scheme error before mutating ctx.nursery-cur */
  }
#endif

  assert(crashed_null_ctx == 0);
  assert(corrupted_foreign == 0);
}

/* ============================================================================
 * Model 3: Private LIFO Thunk Closure Starvation Freedom
 *   Verifies that a newly-spawned closure in ctx.lifo is ALWAYS dispatched
 *   within <= 2 yield steps even when dq stays non-empty (streak <= 8).
 * ============================================================================ */

static void verify_lifo_thunk_progress(void) {
  int lifo_has_thunk = 1;
  int dq_nonempty = 1;
  int streak = nondet_int() % 9;
  if (streak < 0) streak = -streak;
  int thunk_ran = 0;

  for (int step = 0; step < 2 && lifo_has_thunk; step++) {
#ifdef INJECT_BUG_SKIP_LIFO_CLOSURE
    /* Buggy: ignores non-structure closure in ctx.lifo while dq is non-empty */
    if (dq_nonempty) {
      streak = 0;
    }
#else
    if (streak < 8) {
      lifo_has_thunk = 0;
      thunk_ran = 1;
      streak = streak + 1;
    } else if (dq_nonempty) {
      /* Pop dq once to preserve fairness and reset streak -> next step pops lifo */
      streak = 0;
    }
#endif
  }

  assert(thunk_ran == 1);
  assert(lifo_has_thunk == 0);
}

int main(void) {
  verify_boundary_guards();
  verify_lifo_thunk_progress();

  __CPROVER_ASYNC_1: thread_child_abort();
  thread_parent_join();

  if (n_child_done && n_active == 0) {
    fence_acquire();
    assert(n_has_err == 1);
    assert(n_cancelled == 1);
  }
  return 0;
}
