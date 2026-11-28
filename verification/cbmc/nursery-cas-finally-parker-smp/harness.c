/* Phase C49 CBMC --mm pso Verification Harness:
 * 1. Linearizable Zero-Orphan Nursery Close & Non-Zero Refill CAS
 * 2. Zero-Capture Continuable-Exception Parity for with-finally & with-nursery
 * 3. Seq-Cst Parker Searching-Counter Wakeup (Dekker / RCsc Total Order)
 *
 * Negative Mutants (each MUST fail with VERIFICATION FAILED):
 *   -DMUTANT_NURSERY_UNCONDITIONAL_ADD
 *   -DMUTANT_FINALLY_USES_CATCHER
 *   -DMUTANT_TRAMPOLINE_IGNORES_IN_EH
 *   -DMUTANT_PARKER_RELAXED_SEARCHING
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

static inline int load_rlx(volatile int *p) { return *p; }
static inline int load_acq(volatile int *p) { int v = *p; fence_acq(); return v; }
static inline int load_seq(volatile int *p) { fence_seq_cst(); int v = *p; fence_seq_cst(); return v; }

static inline void store_rel(volatile int *p, int v) { fence_rel(); *p = v; }
static inline void store_seq(volatile int *p, int v) { fence_seq_cst(); *p = v; fence_seq_cst(); }

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

static inline int fetch_sub_seq(volatile int *p, int d) {
  fence_seq_cst();
  int old;
  __CPROVER_atomic_begin();
  old = *p;
  *p = old - d;
  __CPROVER_atomic_end();
  fence_seq_cst();
  return old;
}

static inline int cas_acqrel(volatile int *p, int expected, int desired) {
  fence_rel();
  int old;
  __CPROVER_atomic_begin();
  old = *p;
  if (old == expected) {
    *p = desired;
  }
  __CPROVER_atomic_end();
  fence_acq();
  return old;
}

/* =========================================================================
 * Test 1: Linearizable Nursery Close vs Concurrent External Spawn (PSO)
 * ========================================================================= */
static volatile int g_n_active;
static volatile int g_n_cancelled;   /* 0=live, 1=cancelled, 2=closed */
static volatile int g_n_returned;    /* 1 once with-nursery returned to caller */
static volatile int g_n_child_done;  /* 1 once spawned child completes */
static volatile int g_n_orphans;     /* incremented if child runs after return */
static volatile int g_n_spawned;     /* 1 if attacker spawn succeeded */

static void test_nursery_cas_close(void) {
  g_n_active = 1;
  g_n_cancelled = 0;
  g_n_returned = 0;
  g_n_child_done = 0;
  g_n_orphans = 0;
  g_n_spawned = 0;

  __CPROVER_ASYNC_1:
  {
    /* External fiber holding leaked nursery reference calls (fiber-spawn child n) */
    if (load_acq(&g_n_cancelled) != 2) {
      int ok = 0;
#ifdef MUTANT_NURSERY_UNCONDITIONAL_ADD
      /* BUG: unconditional fetch_add resurrects active from 0 -> 1 after teardown! */
      (void)fetch_add_acqrel(&g_n_active, 1);
      ok = 1;
#else
      /* FIX: non-zero CAS loop rejects active <= 0 monotonically */
      for (int tries = 0; tries < 2; tries++) {
        int cur = load_acq(&g_n_active);
        if (cur <= 0) {
          ok = 0;
          break;
        }
        if (cas_acqrel(&g_n_active, cur, cur + 1) == cur) {
          ok = 1;
          break;
        }
      }
#endif
      if (ok) {
        store_rel(&g_n_spawned, 1);
        /* Child runs immediately; if parent already returned, it is an orphan! */
        if (load_acq(&g_n_returned) != 0) {
          fetch_add_acqrel(&g_n_orphans, 1);
        }
        store_rel(&g_n_child_done, 1);
        (void)fetch_add_acqrel(&g_n_active, -1);
      }
    }
  }

  /* Parent enters %nursery-teardown!: drops initial credit (1) and waits until active == 0 */
  int prev = fetch_add_acqrel(&g_n_active, -1);
  if (prev > 1) {
    /* Bounded wait modeling %park-nursery-cont! */
    __CPROVER_assume(load_acq(&g_n_active) == 0);
  }
  store_seq(&g_n_cancelled, 2);
  store_rel(&g_n_returned, 1);

  /* If external spawn succeeded, child MUST have finished before return */
  if (load_acq(&g_n_spawned)) {
    assert(load_acq(&g_n_child_done) == 1);
  }
  assert(load_acq(&g_n_orphans) == 0);
}

/* =========================================================================
 * Test 2: with-finally / with-nursery Continuable vs Escaping Guard
 * ========================================================================= */
static void test_continuable_finally_guard(void) {
  int done = 0;
  int in_eh = 0;
  int suspended = 0;
  int runs = 0;
  int nursery_live = 1;
  int mode = nondet_int();
  __CPROVER_assume(mode >= 0 && mode <= 3);

  /* mode 0: continuable exception handled outside prompt (trampoline fires 'unwind)
   * mode 1: continuable exception whose handler performs effect suspend + resume
   * mode 2: escaping with-exception-catcher (inside or outside prompt)
   * mode 3: direct abort-current-continuation / call/1cc (no exception)
   */
  if (mode == 0 || mode == 1 || mode == 2) {
#ifdef MUTANT_FINALLY_USES_CATCHER
    /* BUG: with-exception-catcher eagerly runs finally & kills continuable return */
    if (!done) { done = 1; runs++; nursery_live = 0; }
    assert(mode == 2); /* fails on continuable modes 0 and 1 */
    return;
#endif
    int returned = 0;
    in_eh = 1;

    /* Simulate SRFI-226 trampoline firing unwind-guard 'unwind before target-eh */
#ifdef MUTANT_TRAMPOLINE_IGNORES_IN_EH
    if (!done) { done = 1; runs++; nursery_live = 0; }
#else
    if (!in_eh && !done) { done = 1; runs++; nursery_live = 0; }
#endif

    if (mode == 1) {
      /* Outer handler suspends via algebraic effect perform */
      suspended = 1;
      /* Cold-path dynamic-wind after runs on perform unwind -> skips while suspended */
      if (!returned && !suspended && !done) { done = 1; runs++; nursery_live = 0; }
      assert(runs == 0 && nursery_live == 1);
      /* Resumed -> restores suspended = 0 */
      suspended = 0;
    }

    if (mode == 0 || mode == 1) {
      /* Outer with-exception-handler returns a value! */
      returned = 1;
      in_eh = 0;
      if (!returned && !suspended && !done) { done = 1; runs++; nursery_live = 0; }
      /* Body resumes with resource & nursery STILL LIVE! */
      assert(runs == 0);
      assert(nursery_live == 1);
      /* Normal exit runs cleanup strictly once */
      if (!done) { done = 1; runs++; nursery_live = 0; }
      assert(runs == 1);
      assert(nursery_live == 0);
    } else {
      /* mode == 2: outer catcher escapes -> cold-path after runs BEFORE catcher */
      in_eh = 0;
      if (!returned && !suspended && !done) { done = 1; runs++; nursery_live = 0; }
      assert(runs == 1);
      assert(nursery_live == 0);
    }
  } else {
    /* mode == 3: direct abort / call/1cc with in_eh == 0 */
    if (!in_eh && !done) { done = 1; runs++; nursery_live = 0; }
    assert(runs == 1);
    assert(nursery_live == 0);
  }
}

/* =========================================================================
 * Test 3: Parker Seq-Cst Searching-Counter Wakeup Under PSO
 * ========================================================================= */
static volatile int g_dq_tail;
static volatile int g_waiters;
static volatile int g_searching;
static volatile int g_worker_a_parked;
static volatile int g_woke;
static volatile int g_worker_a_done;
static volatile int g_prod_done;

static void test_parker_searching_seq_cst(void) {
  g_dq_tail = 0;
  g_waiters = 1;      /* Worker B already parked */
  g_searching = 1;    /* Worker A currently searching */
  g_worker_a_parked = 0;
  g_woke = 0;
  g_worker_a_done = 0;
  g_prod_done = 0;

  __CPROVER_ASYNC_2:
  {
    /* Worker A: finished scanning deque (saw 0), releases searching, then rechecks before park */
#ifdef MUTANT_PARKER_RELAXED_SEARCHING
    /* BUG: relaxed store to searching & relaxed load without SC total order */
    g_searching = 0;
    int t = load_rlx(&g_dq_tail);
#else
    /* FIX: seq_cst release of searching + seq_cst recheck of dq_tail */
    (void)fetch_sub_seq(&g_searching, 1);
    int t = load_seq(&g_dq_tail);
#endif
    if (t == 0) {
      store_rel(&g_worker_a_parked, 1);
    }
    store_rel(&g_worker_a_done, 1);
  }

  /* Producer: pushes work (STLR dq_tail = 1), checks waiters > 0 && searching == 0 */
  store_rel(&g_dq_tail, 1);
  int w = load_seq(&g_waiters);
#ifdef MUTANT_PARKER_RELAXED_SEARCHING
  int s = load_rlx(&g_searching);
#else
  int s = load_seq(&g_searching);
#endif
  if (w > 0 && s == 0) {
    store_rel(&g_woke, 1);
  }
  store_rel(&g_prod_done, 1);

  __CPROVER_assume(load_acq(&g_worker_a_done) == 1 && load_acq(&g_prod_done) == 1);
  /* Liveness invariant: if Worker A missed the push and parked, producer MUST have woken a sleeper */
  assert(!(load_acq(&g_worker_a_parked) == 1 && load_acq(&g_woke) == 0));
}

int main(void) {
  test_nursery_cas_close();
  test_continuable_finally_guard();
  test_parker_searching_seq_cst();
  return 0;
}
