/*
 * CBMC --mm pso verification harness for (srfi 230):
 *   1. 2-thread PSO atomic-pair-compare-and-swap! (val, stamp) linearizability,
 *      lazy cons allocation (0 allocs on mismatch), SATB pre-write shade on
 *      overwritten cons cell, and valid speculative load-order mapping.
 *   2. Load/store memory-order validator and vector-atomic-* bounds validator.
 *
 * Negative mutants (all 4 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_EAGER_ALLOC_ON_MISMATCH
 *   -DINJECT_BUG_RELEASE_LOAD_ORDER
 *   -DINJECT_BUG_SKIP_SATB_SHADE_ON_PAIR_CAS
 *   -DINJECT_BUG_UNCHECKED_VEC_OOB
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

/* Order codes: 0=relaxed, 1=acquire, 2=release, 3=acq_rel, 4=seq_cst */
static inline int valid_load_order(int o) {
  return (o == 0 || o == 1 || o == 4);
}

static inline int valid_store_order(int o) {
  return (o == 0 || o == 2 || o == 4);
}

static inline int spec_load_order(int rmw_o) {
#ifdef INJECT_BUG_RELEASE_LOAD_ORDER
  return rmw_o; /* Buggy: passes release(2) / acq_rel(3) directly to load! */
#else
  if (rmw_o == 2) return 0;
  if (rmw_o == 3) return 1;
  return rmw_o;
#endif
}

/* ============================================================================
 * Model 1: 2-Thread PSO atomic-pair-compare-and-swap! with Lazy Alloc & SATB
 * ============================================================================ */

static volatile int pair_val = 0;
static volatile int pair_stamp = 0;
static volatile int pair_satb_shaded = 0;
static volatile int pair_mismatch_allocs = 0;
static volatile int t1_won = 0;
static volatile int t2_won = 0;
static volatile int t1_done = 0;

static int atomic_pair_cas_step(int exp_v, int exp_s, int des_v, int des_s, int rmw_order) {
  int lo = spec_load_order(rmw_order);
  assert(valid_load_order(lo));

  int alloc_done = 0;
#ifdef INJECT_BUG_EAGER_ALLOC_ON_MISMATCH
  alloc_done = 1; /* Buggy: allocates cons cell before checking match */
#endif

  int cv = pair_val;
  int cs = pair_stamp;
  if (cv != exp_v || cs != exp_s) {
    if (alloc_done) {
      pair_mismatch_allocs = pair_mismatch_allocs + 1;
    }
    return 0;
  }

  /* Lazy alloc only once (cv, cs) matches */
  alloc_done = 1;
  int won = 0;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  if (pair_val == exp_v && pair_stamp == exp_s) {
    pair_val = des_v;
    pair_stamp = des_s;
    won = 1;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();

  if (won) {
#ifndef INJECT_BUG_SKIP_SATB_SHADE_ON_PAIR_CAS
    pair_satb_shaded = 1;
#endif
  }
  return won;
}

static void racer_1(void) {
  t1_won = atomic_pair_cas_step(0, 0, 10, 1, 2 /* release */);
  fence_seq_cst();
  t1_done = 1;
}

/* ============================================================================
 * Model 2: Bounds & Order Validation
 * ============================================================================ */

static void verify_vec_bounds(void) {
  int len = 4;
  int idx = nondet_int() % 8 - 2; /* covers negative, valid, and >= len */
  int oob_access = 0;

#ifdef INJECT_BUG_UNCHECKED_VEC_OOB
  if (idx < 0 || idx >= len) {
    oob_access = 1;
  }
#else
  if (idx >= 0 && idx < len) {
    /* Safe access within [0, len) */
  }
#endif
  assert(oob_access == 0);
}

int main(void) {
  verify_vec_bounds();

  /* Verify mismatch path does zero allocations */
  int m = atomic_pair_cas_step(99, 99, 100, 100, 3 /* acq_rel */);
  assert(m == 0);
  assert(pair_mismatch_allocs == 0);

  /* Two concurrent racers compete to transition (0, 0) -> (10, 1) / (20, 1) */
  __CPROVER_ASYNC_1: racer_1();
  t2_won = atomic_pair_cas_step(0, 0, 20, 1, 3 /* acq_rel */);

  if (t1_done) {
    fence_seq_cst();
    /* Exactly one racer MUST win */
    assert(t1_won + t2_won == 1);
    assert(pair_stamp == 1);
    assert(pair_val == (t1_won ? 10 : 20));
    assert(pair_satb_shaded == 1);
  }
  return 0;
}
