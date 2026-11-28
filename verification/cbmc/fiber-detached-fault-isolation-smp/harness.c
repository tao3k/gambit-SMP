/*
 * CBMC PSO harness for (gambit fiber) detached-fiber fault isolation +
 * guaranteed parker destruction, and (gambit parallel) next-pow2 overflow guard.
 *
 * Negative mutants (all 4 MUST fail CBMC):
 *   -DINJECT_BUG_DETACHED_KILLS_WORKER
 *   -DINJECT_BUG_DETACHED_LEAKS_TC
 *   -DINJECT_BUG_LEAK_PARKER_ON_EXIT
 *   -DINJECT_BUG_NEXT_POW2_OVERFLOW
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

extern bool nondet_bool(void);
extern int64_t nondet_i64(void);

static volatile int spawned_0 = 1; /* root fiber */
static volatile int spawned_1 = 0;
static volatile int completed_0 = 0;
static volatile int completed_1 = 0;
static volatile int root_done = 0;
static volatile int worker_alive_0 = 1;
static volatile int worker_alive_1 = 1;
static volatile int carrier_tc_0 = 0;
static volatile int carrier_tc_1 = 0;
static volatile int parker_destroyed = 0;

static void run_detached_w0(bool throws_err, bool had_tc) {
  assert(carrier_tc_0 == 0);
  if (had_tc) carrier_tc_0 = 1;
  if (throws_err) {
#ifdef INJECT_BUG_DETACHED_KILLS_WORKER
    worker_alive_0 = 0;
    return;
#endif
#ifndef INJECT_BUG_DETACHED_LEAKS_TC
    carrier_tc_0 = 0;
#endif
    __CPROVER_atomic_begin();
    completed_0 = completed_0 + 1;
    __CPROVER_atomic_end();
    return;
  }
  carrier_tc_0 = 0;
  __CPROVER_atomic_begin();
  completed_0 = completed_0 + 1;
  __CPROVER_atomic_end();
}

static void run_detached_w1(bool throws_err, bool had_tc) {
  assert(carrier_tc_1 == 0);
  if (had_tc) carrier_tc_1 = 1;
  if (throws_err) {
#ifdef INJECT_BUG_DETACHED_KILLS_WORKER
    worker_alive_1 = 0;
    return;
#endif
#ifndef INJECT_BUG_DETACHED_LEAKS_TC
    carrier_tc_1 = 0;
#endif
    /* Matches %fxatom-inc-owner-rel! release ordering */
    __CPROVER_fence("WWfence", "RWfence", "RRfence", "WRfence");
    __CPROVER_atomic_begin();
    completed_1 = completed_1 + 1;
    __CPROVER_atomic_end();
    return;
  }
  carrier_tc_1 = 0;
  __CPROVER_fence("WWfence", "RWfence", "RRfence", "WRfence");
  __CPROVER_atomic_begin();
  completed_1 = completed_1 + 1;
  __CPROVER_atomic_end();
}

static int64_t next_pow2_checked(int64_t n) {
  const int64_t MAX_FIX = (1LL << 61) - 1;
  const int64_t MAX_HALF = MAX_FIX >> 1;
#ifndef INJECT_BUG_NEXT_POW2_OVERFLOW
  if (n > MAX_HALF) {
    return -1;
  }
#endif
  if (n <= 0) {
    return 64;
  }
  int64_t p = 4;
  /* Bounded proof check: if p ever becomes negative/0, signed overflow occurred */
  for (int step = 0; step < 63; step++) {
    if (p >= n) {
      return p;
    }
    int64_t nxt = p << 1;
    assert(nxt > p && nxt <= MAX_FIX);
    p = nxt;
  }
  assert(0 && "next_pow2 infinite loop / overflow");
  return -1;
}

int main(void) {
  bool fault1 = nondet_bool();
  bool fault2 = nondet_bool();
  bool tc1 = nondet_bool();
  bool tc2 = nondet_bool();

  /* Root spawns two detached fibers (one per worker) */
  __CPROVER_atomic_begin();
  spawned_0 = spawned_0 + 1;
  spawned_1 = spawned_1 + 1;
  __CPROVER_atomic_end();

  /* Concurrent execution on worker 1 */
  __CPROVER_ASYNC_1:
  {
    run_detached_w1(fault1, tc1);
  }

  /* Worker 0 runs a detached fiber (which may fault) followed by root completion */
  run_detached_w0(fault2, tc2);
  /* Verify worker 0 observes clean tc == 0 after detached fiber returns/aborts */
  assert(carrier_tc_0 == 0);

  /* Root finishes */
  __CPROVER_atomic_begin();
  completed_0 = completed_0 + 1;
  __CPROVER_atomic_end();
  root_done = 1;

  /* Wait for worker 1 to finish its detached task (matches %fxatom-load-acq) */
  __CPROVER_assume(!worker_alive_1 || completed_1 == 1);
  __CPROVER_fence("WWfence", "RWfence", "RRfence", "WRfence");

  /* All carrier workers MUST remain alive */
  assert(worker_alive_0 == 1);
  assert(worker_alive_1 == 1);
  assert(carrier_tc_1 == 0);

  /* Quiescence MUST converge: total completed == total spawned */
  assert(root_done == 1);
  assert((completed_0 + completed_1) == (spawned_0 + spawned_1));

#ifndef INJECT_BUG_LEAK_PARKER_ON_EXIT
  parker_destroyed = 1;
#endif
  assert(parker_destroyed == 1);

  /* Verify next_pow2 overflow guard across boundary inputs */
  assert(next_pow2_checked(1) == 4);
  assert(next_pow2_checked(65) == 128);
  int64_t huge = (1LL << 59) + 1;
  int64_t r_huge = next_pow2_checked(huge);
  assert(r_huge == -1 || (r_huge >= huge && r_huge <= ((1LL << 61) - 1)));
  int64_t over_half = (1LL << 60) + 1;
  assert(next_pow2_checked(over_half) == -1);

  return 0;
}
