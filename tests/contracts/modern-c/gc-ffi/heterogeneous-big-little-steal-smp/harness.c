/*
 * Phase C19 CBMC PSO Adversarial Verification Harness:
 *   1. Go/Tokio-style bounded `num_searching <= max(1, W/2)` CAS permit under PSO
 *   2. Exact permit release on both steal-success and steal-miss (zero permit leak!)
 *   3. Uniform carrier QoS prevents XNU STW-GC barrier priority inversion
 *
 * Negative Mutants (each MUST FAIL under `cbmc --mm pso --unwind 4`):
 *   -DINJECT_BUG_SEARCH_NO_CAS_CAP
 *   -DINJECT_BUG_SEARCH_LEAK_PERMIT_ON_STEAL
 *   -DINJECT_BUG_QOS_PRIORITY_INVERSION_ON_STW_BARRIER
 *   -DINJECT_BUG_SEARCH_CAP_ZERO_DEADLOCK
 */

#include <assert.h>

extern void __CPROVER_fence(const char *kind, ...);
extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_assume(_Bool);

static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence");
}
static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}
static inline void fence_acqrel(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

/* ============================================================================
 * Scenario 1 & 2: Two idle thieves compete for max_searching = 1 permit (PSO)
 * ============================================================================ */
static int g_num_searching = 0;
static int g_peak_searching = 0;
static int g_victim_tasks = 1;
static int g_stolen_count = 0;
static int g_t1_done = 0;
static int g_t2_done = 0;

static int try_acquire_search(int max_s) {
  int cur = g_num_searching;
  fence_acquire();
  if (cur >= max_s) return 0;
#ifdef INJECT_BUG_SEARCH_NO_CAS_CAP
  /* BUG: non-atomic check-then-increment allows 2 thieves past cap = 1! */
  g_num_searching = cur + 1;
  if (g_num_searching > g_peak_searching) g_peak_searching = g_num_searching;
  return 1;
#else
  int won = 0;
  __CPROVER_atomic_begin();
  if (g_num_searching == cur) {
    g_num_searching = cur + 1;
    if (g_num_searching > g_peak_searching) g_peak_searching = g_num_searching;
    won = 1;
  }
  __CPROVER_atomic_end();
  if (won) fence_acqrel();
  return won;
#endif
}

static void release_search(void) {
  fence_acqrel();
  __CPROVER_atomic_begin();
  g_num_searching -= 1;
  __CPROVER_atomic_end();
}

static void thief_run(int *done_flag) {
#ifdef INJECT_BUG_SEARCH_CAP_ZERO_DEADLOCK
  int max_s = 0; /* BUG: cap = 0 prevents ANY thief from stealing -> deadlock! */
#else
  int max_s = 1; /* max(1, W / 2) for W = 3 */
#endif
  if (try_acquire_search(max_s)) {
    int got = 0;
    __CPROVER_atomic_begin();
    if (g_victim_tasks > 0) {
      g_victim_tasks -= 1;
      g_stolen_count += 1;
      got = 1;
    }
    __CPROVER_atomic_end();
#ifdef INJECT_BUG_SEARCH_LEAK_PERMIT_ON_STEAL
    if (!got) release_search(); /* BUG: leaks permit when steal succeeds! */
#else
    (void)got;
    release_search();
#endif
  }
  fence_release();
  *done_flag = 1;
}

/* ============================================================================
 * Scenario 3: Uniform carrier QoS prevents STW-GC barrier priority inversion
 * ============================================================================ */
static void check_qos_non_inversion(void) {
  int W = 3;
  int pcores = 2;
  int min_qos = 1;
  int wid;
  for (wid = 0; wid < W; wid++) {
    int q;
#ifdef INJECT_BUG_QOS_PRIORITY_INVERSION_ON_STW_BARRIER
    q = (wid < pcores) ? 1 : 0; /* BUG: demotes worker to UTILITY -> STW GC stall! */
#else
    (void)pcores;
    q = 1;
#endif
    if (q < min_qos) min_qos = q;
  }
  assert(min_qos == 1);
}

int main(void) {
  __CPROVER_ASYNC_1: thief_run(&g_t1_done);
  thief_run(&g_t2_done);
  __CPROVER_assume(g_t1_done == 1 && g_t2_done == 1);
  fence_acquire();

  /* Bounded concurrency: never exceeded max_searching = 1 */
  assert(g_peak_searching <= 1);
  /* Liveness: at least one thief acquired permit and stole the available task */
  assert(g_stolen_count == 1);
  assert(g_victim_tasks == 0);
  /* Zero permit leak */
  assert(g_num_searching == 0);

  /* Uniform QoS non-inversion */
  check_qos_non_inversion();

  return 0;
}
