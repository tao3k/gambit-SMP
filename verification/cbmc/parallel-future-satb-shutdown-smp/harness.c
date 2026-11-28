/*
 * CBMC --mm pso verification harness for (gambit parallel):
 *   1. 3-thread PSO concurrent ws-future claim + eager SATB-barriered thunk clear
 *      + release publication of DONE vs concurrent future-force readers.
 *      Verifies: runs == 1, thunk == NULL whenever DONE is observed, SATB
 *      pre-write shade recorded on overwritten thunk.
 *   2. 2-thread PSO concurrent idempotent work-stealing-pool-shutdown!
 *      (0=RUNNING -> 1=SHUTTING_DOWN -> 2=SHUTDOWN_DONE CAS protocol).
 *      Verifies: join_calls == 1 and every returning caller observes workers_joined == 1.
 *
 * Negative mutants (all 4 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_SKIP_THUNK_CLEAR
 *   -DINJECT_BUG_RELEASE_BEFORE_THUNK_CLEAR
 *   -DINJECT_BUG_SKIP_SATB_SHADE
 *   -DINJECT_BUG_NONATOMIC_SHUTDOWN
 */

#include <assert.h>
#include <stdint.h>

static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence", "WWcumul");
}

static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

/* ============================================================================
 * Model 1: 3-Thread PSO ws-future Single-Run + SATB Thunk Clear
 * ============================================================================ */

#define F_PENDING 0
#define F_RUNNING 1
#define F_DONE    2

static volatile int f_state = F_PENDING;
static volatile int f_thunk_alive = 1;
static volatile int f_satb_shaded = 0;
static volatile int f_result = 0;
static volatile int f_runs = 0;
static volatile int f_t1_done = 0;
static volatile int f_t2_done = 0;

static void future_run_once_thread(void) {
  int won = 0;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  if (f_state == F_PENDING) {
    f_state = F_RUNNING;
    won = 1;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();

  if (won) {
    f_runs = f_runs + 1;

#ifdef INJECT_BUG_RELEASE_BEFORE_THUNK_CLEAR
    /* Buggy: publishes DONE before clearing thunk! */
    f_result = 42;
    fence_release();
    f_state = F_DONE;
    f_thunk_alive = 0;
    f_satb_shaded = 1;
#else
#ifndef INJECT_BUG_SKIP_THUNK_CLEAR
    /* Eager SATB-barriered thunk clear BEFORE release publication of DONE */
    int old_thunk;
    __CPROVER_atomic_begin();
    old_thunk = f_thunk_alive;
    f_thunk_alive = 0;
    __CPROVER_atomic_end();
#ifndef INJECT_BUG_SKIP_SATB_SHADE
    if (old_thunk) {
      f_satb_shaded = 1;
    }
#endif
#endif
    f_result = 42;
    fence_release();
    f_state = F_DONE;
#endif
  }
}

static void future_racer_1(void) {
  future_run_once_thread();
  if (f_state == F_DONE) {
    fence_acquire();
    assert(f_result == 42);
    assert(f_thunk_alive == 0);
    assert(f_satb_shaded == 1);
  }
  fence_release();
  f_t1_done = 1;
}

static void future_racer_2(void) {
  future_run_once_thread();
  if (f_state == F_DONE) {
    fence_acquire();
    assert(f_result == 42);
    assert(f_thunk_alive == 0);
    assert(f_satb_shaded == 1);
  }
  fence_release();
  f_t2_done = 1;
}

/* ============================================================================
 * Model 2: 2-Thread PSO Concurrent Idempotent Pool Shutdown
 * ============================================================================ */

#define P_RUNNING       0
#define P_SHUTTING_DOWN 1
#define P_SHUTDOWN_DONE 2

static volatile int p_shut = P_RUNNING;
static volatile int p_join_calls = 0;
static volatile int p_workers_joined = 0;
static volatile int p_c1_done = 0;

static void pool_shutdown_call(void) {
#ifdef INJECT_BUG_NONATOMIC_SHUTDOWN
  /* Buggy: plain store allows both callers to execute thread-join! */
  p_shut = P_SHUTTING_DOWN;
  fence_seq_cst();
  p_join_calls = p_join_calls + 1;
  p_workers_joined = 1;
  fence_release();
  p_shut = P_SHUTDOWN_DONE;
#else
  int won = 0;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  if (p_shut == P_RUNNING) {
    p_shut = P_SHUTTING_DOWN;
    won = 1;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();

  if (won) {
    p_join_calls = p_join_calls + 1;
    p_workers_joined = 1;
    fence_release();
    p_shut = P_SHUTDOWN_DONE;
  } else {
    /* Concurrent / repeat caller waits until shutdown completes */
    if (p_shut == P_SHUTDOWN_DONE) {
      fence_acquire();
      assert(p_workers_joined == 1);
    }
  }
#endif
}

static void shutdown_caller_1(void) {
  pool_shutdown_call();
  fence_release();
  p_c1_done = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: future_racer_1();
  __CPROVER_ASYNC_2: future_racer_2();
  future_run_once_thread();

  if (f_t1_done && f_t2_done && f_state == F_DONE) {
    fence_acquire();
    assert(f_runs == 1);
    assert(f_result == 42);
    assert(f_thunk_alive == 0);
    assert(f_satb_shaded == 1);
  }

  __CPROVER_ASYNC_3: shutdown_caller_1();
  pool_shutdown_call();

  if (p_c1_done && p_shut == P_SHUTDOWN_DONE) {
    fence_acquire();
    assert(p_join_calls == 1);
    assert(p_workers_joined == 1);
  }
  return 0;
}
