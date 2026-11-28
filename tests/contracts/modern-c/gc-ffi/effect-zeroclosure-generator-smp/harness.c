/* Phase C24: Adversarial CBMC PSO Harness for Zero-Closure Inline-CAS
 * Algebraic Effects and Symmetric 4-State Atomic Direct-Style Generators.
 *
 * Verifies under --mm pso:
 *   0. Inline atomic CAS(0 -> 1) on effect-continuation guarantees strictly 1
 *      winner under concurrent 2-thread resume race.
 *   1. Escaped consumed effect-continuation handle is NEVER recycled to LIVE,
 *      so later resume attempts are always rejected.
 *   2. 4-state atomic generator CAS(SUSPENDED -> RUNNING) prevents concurrent
 *      double-resume of the generator's one-shot continuation.
 *   3. Frozen pframe (marked by multi-shot promotion) is NEVER mutated in-place
 *      by a subsequent generator resume.
 *   4. denv equality guard declines direct no-winding one-shot return whenever
 *      cur_denv != target_denv, preserving dynamic-wind semantics.
 *
 * Negative Mutants (each MUST trigger VERIFICATION FAILED):
 *   -DINJECT_BUG_NONATOMIC_EC_STATE
 *   -DINJECT_BUG_RECYCLE_ESCAPED_EK
 *   -DINJECT_BUG_GEN_NO_RUNNING_CAS
 *   -DINJECT_BUG_MUTATE_FROZEN_PFRAME
 *   -DINJECT_BUG_SKIP_DENV_CHECK
 *   -DINJECT_BUG_GEN_PUBLISH_BEFORE_PFRAME_POP
 *   -DINJECT_BUG_GEN_RECLAIM_INIT_ANCHOR
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern void __CPROVER_assume(int);

static inline int cas_seq(volatile int *p, int expected, int desired) {
  int prev;
  __CPROVER_atomic_begin();
  prev = *p;
  if (prev == expected) *p = desired;
  __CPROVER_atomic_end();
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
  return prev;
}

/* Scenario 0: 2 threads racing to consume inline-CAS effect-continuation */
static volatile int g_ec_state;
static volatile int g_ec_winners;

static void ec_racer_t1(void) {
#ifdef INJECT_BUG_NONATOMIC_EC_STATE
  if (g_ec_state == 0) {
    g_ec_state = 1;
    __CPROVER_atomic_begin(); g_ec_winners++; __CPROVER_atomic_end();
  }
#else
  if (cas_seq(&g_ec_state, 0, 1) == 0) {
    __CPROVER_atomic_begin(); g_ec_winners++; __CPROVER_atomic_end();
  }
#endif
}

/* Scenario 2: 2 threads racing to invoke the same suspended generator */
static volatile int g_gen_state; /* 2 = SUSPENDED, 1 = RUNNING */
static volatile int g_gen_winners;

static void gen_racer_t1(void) {
#ifdef INJECT_BUG_GEN_NO_RUNNING_CAS
  if (g_gen_state == 2) {
    g_gen_state = 1;
    __CPROVER_atomic_begin(); g_gen_winners++; __CPROVER_atomic_end();
  }
#else
  if (cas_seq(&g_gen_state, 2, 1) == 2) {
    __CPROVER_atomic_begin(); g_gen_winners++; __CPROVER_atomic_end();
  }
#endif
}

/* Scenario 5: Generator SUSPENDED publish ordering vs pframe clear */
static volatile int g_pub_state;   /* 1 = RUNNING, 2 = SUSPENDED */
static volatile int g_pf_escape_k; /* caller-k stored in reusable pframe */
static volatile int g_t2_clobbered;

static void gen_yield_publisher(void) {
#ifdef INJECT_BUG_GEN_PUBLISH_BEFORE_PFRAME_POP
  /* BUG: publishes SUSPENDED before clearing pframe.escape_k! */
  g_pub_state = 2;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
  g_pf_escape_k = 0;
#else
  /* Safe: finishes all pframe reads/writes strictly BEFORE release-storing SUSPENDED */
  g_pf_escape_k = 0;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
  g_pub_state = 2;
#endif
}

static void gen_next_resumer(void) {
  if (cas_seq(&g_pub_state, 2, 1) == 2) {
    /* Installs Thread 2's fresh caller-k (200) into reusable pframe */
    g_pf_escape_k = 200;
    __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
    if (g_pf_escape_k != 200) {
      g_t2_clobbered = 1;
    }
  }
}

int main(void) {
  int scenario;
  __CPROVER_assume(scenario >= 0 && scenario <= 6);

  if (scenario == 0) {
    g_ec_state = 0;
    g_ec_winners = 0;
    __CPROVER_ASYNC_1: ec_racer_t1();
    ec_racer_t1();
    assert(g_ec_winners <= 1);
  } else if (scenario == 1) {
    /* Escaped handle retained after linear consumption */
    int ek_state = 0;
    int prev = (ek_state == 0) ? (ek_state = 1, 0) : ek_state;
    assert(prev == 0);
#ifdef INJECT_BUG_RECYCLE_ESCAPED_EK
    /* BUG: recycling ek back into a freelist resets ek_state = 0! */
    ek_state = 0;
#endif
    /* Retained escaped handle MUST still read CONSUMED (1), never LIVE (0) */
    assert(ek_state == 1);
  } else if (scenario == 2) {
    g_gen_state = 2; /* SUSPENDED */
    g_gen_winners = 0;
    __CPROVER_ASYNC_2: gen_racer_t1();
    gen_racer_t1();
    assert(g_gen_winners <= 1);
  } else if (scenario == 3) {
    /* Multi-shot continuation freezes gen-pframe (handler = #t / frozen = 1) */
    int pframe_frozen = 1;
    int pframe_escape_k = 100; /* captured by multi-shot */
    int mutated_frozen = 0;
#ifdef INJECT_BUG_MUTATE_FROZEN_PFRAME
    /* BUG: overwrites escape_k in-place without checking pframe_frozen! */
    pframe_escape_k = 200;
    if (pframe_frozen) mutated_frozen = 1;
#else
    if (!pframe_frozen) {
      pframe_escape_k = 200;
    } else {
      /* Allocates fresh pframe, leaving captured frozen pframe untouched */
      int fresh_escape_k = 200;
      (void)fresh_escape_k;
    }
#endif
    assert(mutated_frozen == 0);
    assert(pframe_escape_k == 100);
  } else if (scenario == 4) {
    /* denv mismatch due to dynamic-wind / parameterize */
    int cur_denv = 1;
    int target_denv = 2;
    int used_direct_no_winding = 0;
    int ran_dynamic_wind = 0;
#ifdef INJECT_BUG_SKIP_DENV_CHECK
    used_direct_no_winding = 1;
#else
    if (cur_denv == target_denv) {
      used_direct_no_winding = 1;
    } else {
      ran_dynamic_wind = 1;
    }
#endif
    assert(!(cur_denv != target_denv && used_direct_no_winding == 1));
    assert(ran_dynamic_wind == 1);
  } else if (scenario == 5) {
    /* Scenario 5: Generator yield MUST pop/clear pframe BEFORE releasing SUSPENDED */
    g_pub_state = 1;
    g_pf_escape_k = 100;
    g_t2_clobbered = 0;
    __CPROVER_ASYNC_3: gen_yield_publisher();
    gen_next_resumer();
    __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
    assert(g_t2_clobbered == 0);
  } else {
    /* Scenario 6: Yield #1 base-anchor preservation (sub_k.next_break_link -> caller_k_0) */
    int init_anchor_live = 1;
    int sub_k_break_target_valid = 1;
    int is_init_yield = 1;
#ifdef INJECT_BUG_GEN_RECLAIM_INIT_ANCHOR
    /* BUG: Yield #1 reclaims caller_k_0 in-place while sub_k still links to it! */
    init_anchor_live = 0;
#else
    /* Safe: Yield #1 (handler == 'init) returns via ##continuation-return, keeping anchor live */
    if (!is_init_yield) {
      init_anchor_live = 0;
    }
#endif
    if (!init_anchor_live) sub_k_break_target_valid = 0;
    assert(sub_k_break_target_valid == 1);
  }

  return 0;
}
