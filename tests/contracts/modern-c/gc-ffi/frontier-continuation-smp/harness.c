/*
 * CBMC (--mm pso) Bounded Verification Harness:
 * T0 Frontier Multicore Continuation Ownership & Stack Watermark x SATB Contract
 *
 * Verifies:
 *   1. Atomic 3-state continuation claim (ONE_SHOT_LIVE -> ONE_SHOT_CONSUMED | MULTISHOT_COW)
 *   2. Mutual exclusion of one-shot claims across 2 concurrent threads under PSO
 *   3. Consumed continuation cannot be promoted to multi-shot
 *   4. Return watermark barrier cooperatively shades frame roots during SATB
 *
 * Negative mutants:
 *   -DINJECT_BUG_NONATOMIC_CLAIM
 *   -DINJECT_BUG_PROMOTE_AFTER_CONSUME
 *   -DINJECT_BUG_SKIP_WATERMARK_SHADE
 */
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *kind, ...);
extern int nondet_int(void);

enum {
  CONT_ONE_SHOT_LIVE = 0,
  CONT_ONE_SHOT_CONSUMED = 1,
  CONT_MULTISHOT_COW = 2
};

static int g_satb_active;
static int g_cont_state;
static int g_watermark_armed;
static int g_frame_shaded;
static int g_claim_count;
static int g_cow_resumes;

static int atomic_cas_state(int expected, int desired) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (g_cont_state == expected) {
    g_cont_state = desired;
    ok = 1;
  }
  __CPROVER_atomic_end();
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  return ok;
}

static int atomic_xchg_watermark(int val) {
  int prev;
  __CPROVER_atomic_begin();
  prev = g_watermark_armed;
  g_watermark_armed = val;
  __CPROVER_atomic_end();
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  return prev;
}

static void atomic_inc(int *p) {
  __CPROVER_atomic_begin();
  *p = *p + 1;
  __CPROVER_atomic_end();
}

static bool claim_one_shot(void) {
#ifdef INJECT_BUG_NONATOMIC_CLAIM
  if (g_cont_state == CONT_ONE_SHOT_LIVE) {
    g_cont_state = CONT_ONE_SHOT_CONSUMED;
    return true;
  }
  return false;
#else
  if (atomic_cas_state(CONT_ONE_SHOT_LIVE, CONT_ONE_SHOT_CONSUMED)) {
    if (g_satb_active && atomic_xchg_watermark(0)) {
#ifndef INJECT_BUG_SKIP_WATERMARK_SHADE
      g_frame_shaded = 1;
      __CPROVER_fence("WWfence", "RWfence");
#endif
    }
    return true;
  }
  return false;
#endif
}

static bool promote_to_multishot(void) {
#ifdef INJECT_BUG_PROMOTE_AFTER_CONSUME
  g_cont_state = CONT_MULTISHOT_COW;
  return true;
#else
  return atomic_cas_state(CONT_ONE_SHOT_LIVE, CONT_MULTISHOT_COW) != 0;
#endif
}

static void worker_step(int action) {
  if (action == 0) {
    if (claim_one_shot()) {
      atomic_inc(&g_claim_count);
      if (g_satb_active) {
        assert(g_frame_shaded == 1);
      }
    }
  } else {
    if (promote_to_multishot()) {
      atomic_inc(&g_cow_resumes);
    }
  }
}

int main(void) {
  int satb_on = nondet_int();
  int a0 = nondet_int();
  int a1 = nondet_int();
  __CPROVER_assume(satb_on == 0 || satb_on == 1);
  __CPROVER_assume(a0 == 0 || a0 == 1);
  __CPROVER_assume(a1 == 0 || a1 == 1);

  g_satb_active = satb_on;
  g_cont_state = CONT_ONE_SHOT_LIVE;
  g_watermark_armed = satb_on;
  g_frame_shaded = 0;
  g_claim_count = 0;
  g_cow_resumes = 0;

__CPROVER_ASYNC_1:
  worker_step(a0);
  worker_step(a1);

  /* Join point */
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");

  /* Law 1: At most one thread can claim a one-shot continuation. */
  assert(g_claim_count <= 1);
  /* Law 2: One-shot claim and multi-shot promotion are mutually exclusive. */
  assert(!(g_claim_count > 0 && g_cow_resumes > 0));
  /* Law 3: Claimed continuation stays in CONSUMED state. */
  if (g_claim_count == 1) {
    assert(g_cont_state == CONT_ONE_SHOT_CONSUMED);
  }
  return 0;
}
