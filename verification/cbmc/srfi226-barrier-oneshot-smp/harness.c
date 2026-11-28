/* Phase C51 CBMC --mm pso Verification Harness:
 * 1. Exact LCA Diff (%mc-diff-list) in %commit-noncomp-and-return!
 * 2. Non-Destructive Pre-CAS Validation for One-Shot Continuations
 * 3. Linearizable At-Most-Once SMP Consumption with Immutable Barrier Slot
 *
 * Negative Mutants (each MUST fail with VERIFICATION FAILED):
 *   -DMUTANT_NAIVE_NONCOMP_FULL_UNWIND
 *   -DMUTANT_CAS_BEFORE_BARRIER_CHECK
 *   -DMUTANT_CAS_BEFORE_PROMPT_CHECK
 *   -DMUTANT_NONATOMIC_ONESHOT_CONSUME
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

static inline void fence_acq(void) {
  __CPROVER_fence("RRfence", "RWfence");
}
static inline void fence_rel(void) {
  __CPROVER_fence("WWfence", "WRfence", "RWfence");
}
static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "WRfence", "RWfence", "RRfence");
}

static inline int load_acq(volatile int *p) { int v = *p; fence_acq(); return v; }
static inline void store_rel(volatile int *p, int v) { fence_rel(); *p = v; }

static inline int cas_seq(volatile int *p, int expected, int desired) {
  fence_seq_cst();
  int old;
  __CPROVER_atomic_begin();
  old = *p;
  if (old == expected) {
    *p = desired;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();
  return old;
}

static inline int fetch_add_acqrel(volatile int *p, int d) {
  fence_rel();
  int old;
  __CPROVER_atomic_begin();
  old = *p;
  *p = old + d;
  __CPROVER_atomic_end();
  fence_acq();
  return old;
}

/* =========================================================================
 * Test 1: Exact LCA Diff in %commit-noncomp-and-return!
 * ========================================================================= */
static void test_noncomp_lca_diff(void) {
  /* Bitmasks: bit 0 = shared outer guard (with-finally/nursery/future),
   *           bit 1 = inner guard A, bit 2 = inner guard B */
  int cur_prefix = 0x3;    /* {shared, A} */
  int target_prefix = nondet_int();
  __CPROVER_assume(target_prefix == 0x1 || target_prefix == 0x5 || target_prefix == 0x3);
  /* 0x1: {shared} (exiting A), 0x5: {shared, B} (divergent), 0x3: {shared, A} (same scope) */

  int shared_unwound = 0;
  int a_unwound = 0;
  int b_restored = 0;

#ifdef MUTANT_NAIVE_NONCOMP_FULL_UNWIND
  /* BUG: old %commit-noncomp-and-return! blindly unwinds ALL of cur_prefix! */
  int dropped = cur_prefix;
  int reentered = target_prefix;
#else
  /* FIX: exact LCA diff (%mc-diff-list) */
  int dropped = cur_prefix & ~target_prefix;
  int reentered = target_prefix & ~cur_prefix;
#endif

  if (dropped & 0x1) shared_unwound = 1;
  if (dropped & 0x2) a_unwound = 1;
  if (reentered & 0x4) b_restored = 1;

  /* Shared outer guard (bit 0) is present in BOTH cur & target -> MUST NEVER unwind! */
  assert(shared_unwound == 0);
  if (target_prefix == 0x1) {
    assert(a_unwound == 1 && b_restored == 0);
  } else if (target_prefix == 0x5) {
    assert(a_unwound == 1 && b_restored == 1);
  } else {
    assert(a_unwound == 0 && b_restored == 0);
  }
}

/* =========================================================================
 * Test 2 & 3: Non-Destructive Pre-CAS One-Shot Validation + SMP Race (PSO)
 * ========================================================================= */
static volatile int g_state;
static int g_cap_barriers;        /* immutable inner barrier bitmask */
static volatile int g_sub_k;      /* 1=live, 0=cleared */
static volatile int g_jumps;
static volatile int g_t1_done;
static volatile int g_t2_done;

static int entering_barrier(int cap_mask, int cur_mask) {
  return (cap_mask & ~cur_mask) != 0;
}

static int invoke_cell(int cur_barriers, int prompt_active) {
  int st = load_acq(&g_state);
  if (st == 1) return 0;
  if (st == 2) {
    if (entering_barrier(g_cap_barriers, cur_barriers) || !prompt_active) return 0;
    fetch_add_acqrel(&g_jumps, 1);
    return 1;
  }

#if defined(MUTANT_CAS_BEFORE_BARRIER_CHECK)
  int prev = cas_seq(&g_state, 0, 1);
  if (prev != 0) return 0;
  store_rel(&g_sub_k, 0);
  if (entering_barrier(g_cap_barriers, cur_barriers) || !prompt_active) return 0;
#elif defined(MUTANT_CAS_BEFORE_PROMPT_CHECK)
  if (entering_barrier(g_cap_barriers, cur_barriers)) return 0;
  int prev = cas_seq(&g_state, 0, 1);
  if (prev != 0) return 0;
  store_rel(&g_sub_k, 0);
  if (!prompt_active) return 0;
#elif defined(MUTANT_NONATOMIC_ONESHOT_CONSUME)
  if (entering_barrier(g_cap_barriers, cur_barriers) || !prompt_active) return 0;
  if (load_acq(&g_state) != 0) return 0;
  store_rel(&g_state, 1);
  store_rel(&g_sub_k, 0);
#else
  /* FIX: pre-validate barrier & prompt BEFORE atomic CAS(LIVE -> CONSUMED) */
  if (entering_barrier(g_cap_barriers, cur_barriers)) return 0;
  if (!prompt_active) return 0;
  int prev = cas_seq(&g_state, 0, 1);
  if (prev != 0) return 0;
  store_rel(&g_sub_k, 0);
#endif

  fetch_add_acqrel(&g_jumps, 1);
  return 1;
}

static void test_precheck_preserves_live(void) {
  g_cap_barriers = 1;
  g_state = 0;
  g_sub_k = 1;
  g_jumps = 0;

  int bad_mode = nondet_int();
  __CPROVER_assume(bad_mode == 0 || bad_mode == 1);
  if (bad_mode == 0) {
    assert(invoke_cell(0, 1) == 0);
    assert(load_acq(&g_state) == 0);
    assert(load_acq(&g_sub_k) == 1);
  } else {
    assert(invoke_cell(1, 0) == 0);
    assert(load_acq(&g_state) == 0);
    assert(load_acq(&g_sub_k) == 1);
  }

  assert(invoke_cell(3, 1) == 1);
  assert(load_acq(&g_state) == 1);
  assert(load_acq(&g_sub_k) == 0);
  assert(load_acq(&g_jumps) == 1);
}

static void test_smp_concurrent_oneshot_race(void) {
  g_cap_barriers = 1;
  g_state = 0;
  g_sub_k = 1;
  g_jumps = 0;
  g_t1_done = 0;
  g_t2_done = 0;

  int t1_bar = nondet_int();
  int t1_prompt = nondet_int();
  __CPROVER_assume(t1_bar == 0 || t1_bar == 1);
  __CPROVER_assume(t1_prompt == 0 || t1_prompt == 1);

  __CPROVER_ASYNC_1:
  {
    (void)invoke_cell(t1_bar, t1_prompt);
    store_rel(&g_t1_done, 1);
  }

  (void)invoke_cell(1, 1);
  store_rel(&g_t2_done, 1);

  __CPROVER_assume(load_acq(&g_t1_done) == 1 && load_acq(&g_t2_done) == 1);

  assert(load_acq(&g_jumps) == 1);
  assert(load_acq(&g_state) == 1);
}

int main(void) {
  test_noncomp_lca_diff();
  test_precheck_preserves_live();
  test_smp_concurrent_oneshot_race();
  return 0;
}
