/*
 * CBMC Weak-Memory (--mm pso) Contract Verification Harness:
 * Phase C27 (gambit parallel) Zero-Mutex-Poll Work-Stealing Pool,
 * Dekker-Fenced Sleeper Parking, Steal Cascade, Single-Run Future CAS &
 * Structured Fork-Join Exception Quiescence.
 *
 * Negative Mutants (each MUST FAIL CBMC):
 *   -DINJECT_BUG_SKIP_DEKKER_FENCE
 *   -DINJECT_BUG_DROP_STEAL_CASCADE
 *   -DINJECT_BUG_ORPHAN_RIGHT_ON_LEFT_THROW
 *   -DINJECT_BUG_DOUBLE_FUTURE_RUN
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern int nondet_int(void);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

/* Scenario 0: Dekker sleeper parking vs local push under PSO */
static volatile int g_work;
static volatile int g_sleepers;
static volatile int g_w0_sleeping;
static volatile int g_w0_done;
static volatile int g_w1_done;

static void s0_worker_park(void) {
  __CPROVER_atomic_begin();
  g_sleepers = g_sleepers + 1;
  __CPROVER_atomic_end();
#ifndef INJECT_BUG_SKIP_DEKKER_FENCE
  fence_seq_cst();
#endif
  if (g_work == 0) {
    __CPROVER_atomic_begin();
    if (g_work == 0)
      g_w0_sleeping = 1;
    else
      g_sleepers = g_sleepers - 1;
    __CPROVER_atomic_end();
  } else {
    __CPROVER_atomic_begin();
    g_sleepers = g_sleepers - 1;
    __CPROVER_atomic_end();
  }
  fence_seq_cst();
  g_w0_done = 1;
}

static void s0_submitter(void) {
  g_work = 1;
#ifndef INJECT_BUG_SKIP_DEKKER_FENCE
  fence_seq_cst();
#endif
  if (g_sleepers > 0) {
    __CPROVER_atomic_begin();
    g_w0_sleeping = 0;
    __CPROVER_atomic_end();
  }
  fence_seq_cst();
  g_w1_done = 1;
}

/* Scenario 1: Steal-cascade wakeup */
static volatile int g_dq0;
static volatile int g_w2_sleeping;
static volatile int g_w2_woken;

static void s1_steal_cascade(void) {
  if (g_dq0 > 0) {
    g_dq0 = g_dq0 - 1;
#ifndef INJECT_BUG_DROP_STEAL_CASCADE
    if (g_sleepers > 0) {
      g_w2_sleeping = 0;
      g_w2_woken = 1;
    }
#endif
  }
}

/* Scenario 2: Single-run future CAS race (2 threads) */
static volatile int g_fstate;
static volatile int g_fruns;
static volatile int g_f0_done;
static volatile int g_f1_done;

static void future_run_once(void) {
#ifdef INJECT_BUG_DOUBLE_FUTURE_RUN
  if (g_fstate == 0) {
    g_fstate = 1;
    __CPROVER_atomic_begin();
    g_fruns = g_fruns + 1;
    __CPROVER_atomic_end();
    g_fstate = 2;
  }
#else
  int won = 0;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  if (g_fstate == 0) {
    g_fstate = 1;
    won = 1;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();
  if (won) {
    __CPROVER_atomic_begin();
    g_fruns = g_fruns + 1;
    __CPROVER_atomic_end();
    g_fstate = 2;
  }
#endif
}

static void s2_t0(void) { future_run_once(); fence_seq_cst(); g_f0_done = 1; }
static void s2_t1(void) { future_run_once(); fence_seq_cst(); g_f1_done = 1; }

/* Scenario 3: Structured fork-join exception quiescence */
static volatile int g_right_running;
static volatile int g_parent_unwound;

static void s3_fork_join_left_throws(void) {
  g_right_running = 1;
  /* Left branch throws! */
#ifdef INJECT_BUG_ORPHAN_RIGHT_ON_LEFT_THROW
  /* BUG: unwinds immediately without joining right */
  g_parent_unwound = 1;
#else
  /* Catch left exception, join right first, then re-raise */
  g_right_running = 0;
  g_parent_unwound = 1;
#endif
}

int main(void) {
  int scen = nondet_int() & 3;
  g_work = 0;
  g_sleepers = 0;
  g_w0_sleeping = 0;
  g_w0_done = 0;
  g_w1_done = 0;
  g_dq0 = 0;
  g_w2_sleeping = 1;
  g_w2_woken = 0;
  g_fstate = 0;
  g_fruns = 0;
  g_f0_done = 0;
  g_f1_done = 0;
  g_right_running = 0;
  g_parent_unwound = 0;

  if (scen == 0) {
  __CPROVER_ASYNC_0:
    s0_worker_park();
    s0_submitter();
    if (g_w0_done && g_w1_done) {
      fence_seq_cst();
      assert(g_w0_sleeping == 0);
    }
  } else if (scen == 1) {
    g_dq0 = 3;
    g_sleepers = 1;
    s1_steal_cascade();
    assert(g_w2_sleeping == 0 && g_w2_woken == 1);
  } else if (scen == 2) {
  __CPROVER_ASYNC_1:
    s2_t0();
    s2_t1();
    if (g_f0_done && g_f1_done) {
      fence_seq_cst();
      assert(g_fruns == 1);
    }
  } else {
    s3_fork_join_left_throws();
    assert(g_parent_unwound == 1 && g_right_running == 0);
  }
  return 0;
}
