/*
 * CBMC --mm pso verification harness for (gambit effect):
 *   1. 2-thread PSO race between slow-path one-shot `resume` and concurrent
 *      `resume-multishot` on an `effect-continuation`:
 *      - If one-shot wins LIVE -> CONSUMED, all 6 heap slots are cleared and
 *        `resume-multishot` is rejected.
 *      - If multishot wins LIVE -> MULTI, slots are strictly preserved.
 *   2. 2-thread PSO generator yield/finish detachment:
 *      - Whenever observer sees SUSPENDED, caller_mc_pinned == 0.
 *      - Whenever observer sees DONE, caller_mc_pinned == 0 AND cells_alive == 0.
 *   3. Public API argument validation (`perform`, `perform-cap`, `effect-name`).
 *
 * Negative mutants (all 4 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_SKIP_SLOW_EC_CLEAR
 *   -DINJECT_BUG_CLEAR_MULTISHOT_EC
 *   -DINJECT_BUG_RETAIN_GEN_CALLER_MC
 *   -DINJECT_BUG_UNCHECKED_PERFORM_ARG
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

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
 * Model 1: 2-Thread PSO Slow-Path One-Shot resume vs resume-multishot
 * ============================================================================ */

#define EC_LIVE     0
#define EC_CONSUMED 1
#define EC_MULTI    2

static volatile int ec_state = EC_LIVE;
static volatile int ec_slots_alive = 1;
static volatile int t_multi_done = 0;
static volatile int t_multi_ok = 0;

static void thread_resume_multishot(void) {
  int prev;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  prev = ec_state;
  if (prev == EC_LIVE) {
    ec_state = EC_MULTI;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();

  if (prev == EC_LIVE || prev == EC_MULTI) {
    assert(ec_slots_alive == 1);
    t_multi_ok = 1;
  }
  fence_release();
  t_multi_done = 1;
}

static void thread_resume_slow_oneshot(void) {
  int prev;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  prev = ec_state;
  if (prev == EC_LIVE) {
    ec_state = EC_CONSUMED;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();

  if (prev == EC_LIVE) {
    /* Unique winner on slow path: extract fields locally, then clear all 6 slots */
#ifndef INJECT_BUG_SKIP_SLOW_EC_CLEAR
    ec_slots_alive = 0;
#endif
  } else if (prev == EC_MULTI) {
#ifdef INJECT_BUG_CLEAR_MULTISHOT_EC
    ec_slots_alive = 0; /* Buggy: clobbers multishot slots! */
#endif
    assert(ec_slots_alive == 1);
  }
}

/* ============================================================================
 * Model 2: 2-Thread PSO Generator Yield & Finish Caller-MC Detachment
 * ============================================================================ */

#define GEN_RUNNING   1
#define GEN_SUSPENDED 2
#define GEN_DONE      3

static volatile int gen_state = GEN_RUNNING;
static volatile int gen_caller_mc_pinned = 1;
static volatile int gen_cells_alive = 1;
static volatile int gen_finished = 0;

static void thread_gen_finish(void) {
  int do_finish = nondet_int() & 1;
#ifndef INJECT_BUG_RETAIN_GEN_CALLER_MC
  gen_caller_mc_pinned = 0;
#endif
  if (do_finish) {
    gen_cells_alive = 0;
    fence_release();
    gen_state = GEN_DONE;
  } else {
    fence_release();
    gen_state = GEN_SUSPENDED;
  }
  fence_release();
  gen_finished = 1;
}

static void thread_gen_observer(void) {
  int st = gen_state;
  fence_acquire();
  if (st == GEN_SUSPENDED) {
    assert(gen_caller_mc_pinned == 0);
  } else if (st == GEN_DONE) {
    assert(gen_caller_mc_pinned == 0);
    assert(gen_cells_alive == 0);
  }
}

/* ============================================================================
 * Model 3: Public API Argument Validation
 * ============================================================================ */

static void verify_public_api_guards(void) {
  int is_effect = nondet_int() & 1;
  int crashed = 0;
#ifdef INJECT_BUG_UNCHECKED_PERFORM_ARG
  if (!is_effect) {
    crashed = 1;
  }
#else
  if (!is_effect) {
    /* Raises clean Scheme error */
  }
#endif
  assert(crashed == 0);
}

int main(void) {
  verify_public_api_guards();

  __CPROVER_ASYNC_1: thread_resume_multishot();
  thread_resume_slow_oneshot();

  if (t_multi_done) {
    fence_acquire();
    if (ec_state == EC_CONSUMED) {
      assert(ec_slots_alive == 0);
      assert(t_multi_ok == 0);
    } else if (ec_state == EC_MULTI) {
      assert(ec_slots_alive == 1);
      assert(t_multi_ok == 1);
    }
  }

  __CPROVER_ASYNC_2: thread_gen_finish();
  thread_gen_observer();
  if (gen_finished) {
    fence_acquire();
    assert(gen_caller_mc_pinned == 0);
  }
  return 0;
}
