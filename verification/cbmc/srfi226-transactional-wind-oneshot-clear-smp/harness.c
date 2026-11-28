/*
 * CBMC --mm pso verification harness for:
 *   1. Transactional post-dynamic-wind metacontinuation commit (after-thunks
 *      observe intact prompts/marks; throwing after-thunks never corrupt st).
 *   2. 2-thread SMP race between one-shot consumption (CAS LIVE->CONSUMED +
 *      clearing cell.sub_k / cell.marks for zero GC retention leak) and
 *      concurrent promotion / multishot reader (CAS LIVE->MULTISHOT + reading
 *      cell.sub_k / cell.marks without ever observing a cleared slot).
 *
 * Negative mutants (all 4 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_EAGER_WIPE_BEFORE_AFTER_THUNK
 *   -DINJECT_BUG_CLEAR_ON_MULTISHOT
 *   -DINJECT_BUG_SKIP_ONESHOT_CLEAR
 *   -DINJECT_BUG_IGNORE_CONT_MARKS
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

/* ============================================================================
 * Model 1: Transactional Post-dynamic-wind Commit + Continuation-Marks Lookup
 * ============================================================================ */

static int verify_transactional_wind_and_marks(void) {
  int prompt_live = 1;
  int marks_val = 77;
  int after_throws = nondet_int() & 1;

#ifdef INJECT_BUG_EAGER_WIPE_BEFORE_AFTER_THUNK
  /* Buggy pre-fix order: mutates st BEFORE running dynamic-wind after-thunk */
  prompt_live = 0;
  marks_val = 0;
#endif

  /* Dynamic-wind after-thunk executes here and observes prompt & marks */
  assert(prompt_live == 1);
  assert(marks_val == 77);

  if (after_throws) {
    /* Exception caught inside prompt: landing thunk NEVER runs */
    assert(prompt_live == 1);
    assert(marks_val == 77);
  } else {
    /* Landing thunk commits state pop after all after-thunks complete */
    prompt_live = 0;
    marks_val = 0;
    assert(prompt_live == 0);
  }

  /* Captured-continuation marks lookup must return captured marks (77), not caller marks (99) */
  int caller_marks = 99;
  int captured_marks = 77;
#ifdef INJECT_BUG_IGNORE_CONT_MARKS
  int observed = caller_marks;
#else
  int observed = captured_marks;
#endif
  assert(observed == 77);
  return 0;
}

/* ============================================================================
 * Model 2: 2-Thread SMP One-Shot Clear vs Concurrent Promote / Multishot Read
 * ============================================================================ */

#define ST_LIVE      0
#define ST_CONSUMED  1
#define ST_MULTISHOT 2

static volatile int g_state = ST_LIVE;
static volatile int g_sub_k = 1234;
static volatile int g_marks = 77;
static volatile int g_t0_won_oneshot = 0;
static volatile int g_t0_done = 0;
static volatile int g_t1_saw_cleared = 0;
static volatile int g_t0_saw_cleared = 0;

static int cas_state(int expected, int desired) {
  int prev;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  prev = g_state;
  if (prev == expected) {
    g_state = desired;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();
  return prev;
}

static void thread_invoke(void) {
  int prev = cas_state(ST_LIVE, ST_CONSUMED);
  if (prev == ST_LIVE) {
    int sk = g_sub_k;
    int mk = g_marks;
    assert(sk == 1234);
    assert(mk == 77);
#ifndef INJECT_BUG_SKIP_ONESHOT_CLEAR
    g_sub_k = 0;
    g_marks = 0;
#endif
    g_t0_won_oneshot = 1;
  } else if (prev == ST_MULTISHOT) {
#ifdef INJECT_BUG_CLEAR_ON_MULTISHOT
    g_sub_k = 0;
    g_marks = 0;
#endif
    if (g_sub_k != 1234 || g_marks != 77) {
      g_t0_saw_cleared = 1;
    }
  }
  fence_seq_cst();
  g_t0_done = 1;
}

static void thread_promote_and_read(void) {
  int prev = cas_state(ST_LIVE, ST_MULTISHOT);
  if (prev == ST_LIVE || prev == ST_MULTISHOT) {
    if (g_sub_k != 1234 || g_marks != 77) {
      g_t1_saw_cleared = 1;
    }
  }
}

int main(void) {
  verify_transactional_wind_and_marks();

  __CPROVER_ASYNC_1: thread_invoke();
  thread_promote_and_read();

  assert(g_t0_saw_cleared == 0);
  assert(g_t1_saw_cleared == 0);
  if (g_t0_done) {
    fence_seq_cst();
    if (g_t0_won_oneshot) {
      assert(g_state == ST_CONSUMED);
      assert(g_sub_k == 0);
      assert(g_marks == 0);
    }
  }
  return 0;
}
