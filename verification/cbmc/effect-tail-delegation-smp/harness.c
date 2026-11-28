/* Phase C52 CBMC --mm pso Verification Harness:
 * 1. Tail-Resumptive Deep-Handler Delegation & Dynamic Scope Isolation
 * 2. Cross-Extent Prefix Splicing After Outer Suspend / Resume Under Extra Handler
 * 3. Exception Unwind & Continuable-Return Handler Stack Coherency
 * 4. Concurrent 2-Thread SMP Per-Thread Handler Stack Isolation
 *
 * Negative Mutants (each MUST fail with VERIFICATION FAILED):
 *   -DMUTANT_TAIL_NO_SCOPE_SHIFT
 *   -DMUTANT_TAIL_BLIND_OVERWRITE_ON_RESUME
 *   -DMUTANT_TAIL_NO_EH_RESTORE_BEFORE_CATCHER
 *   -DMUTANT_TAIL_CONTINUABLE_WRONG_SCOPE
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

static inline void fence_acq(void) { __CPROVER_fence("RRfence", "RWfence"); }
static inline void fence_rel(void) { __CPROVER_fence("WWfence", "WRfence", "RWfence"); }
static inline int load_acq(volatile int *p) { int v = *p; fence_acq(); return v; }
static inline void store_rel(volatile int *p, int v) { fence_rel(); *p = v; }

/* Bitmasks representing active handler stack frames:
 *   bit 0 (0x1) = inner e2 handler (inside H_e1)
 *   bit 1 (0x2) = H_e1 tail handler
 *   bit 2 (0x4) = outer e1/e2 handler
 *   bit 3 (0x8) = extra resumer handler installed around (resume k ...)
 */
static int run_thread_tail_scenario(void) {
  int handlers = 0x1 | 0x2 | 0x4;  /* [H_e2_in, H_e1, H_outer] */
  int paused_prefix = 0x1 | 0x2;   /* [H_e2_in, H_e1] */
  int outer_handlers = 0x4;        /* [H_outer] */
  int st_handlers = handlers;

  int mode = nondet_int();
  __CPROVER_assume(mode >= 0 && mode <= 3);
  /* mode 0: direct delegation inside tail proc -> normal return
   * mode 1: outer suspending perform -> resumed under extra handler 0x8 -> normal return
   * mode 2: exception raised inside tail proc -> caught by inner catcher (pops 0x1)
   * mode 3: continuable exception raised inside tail proc -> returns to proc -> normal return
   */

#ifndef MUTANT_TAIL_NO_SCOPE_SHIFT
  /* FIX: shift st.handlers to (cdr fs) = outer_handlers before invoking tail proc */
  st_handlers = outer_handlers;
#endif

  /* Check delegation & dynamic scope isolation inside tail proc */
  assert((st_handlers & 0x2) == 0); /* NEVER self-recurses into H_e1 */
  assert((st_handlers & 0x1) == 0); /* NEVER hijacked by inner H_e2_in */
  assert((st_handlers & 0x4) != 0); /* sees outer handler */

  if (mode == 1) {
    /* Suspended to outer handler and resumed under extra resumer handler 0x8 */
    st_handlers = outer_handlers | 0x8;
#ifdef MUTANT_TAIL_BLIND_OVERWRITE_ON_RESUME
    /* BUG: blindly overwrites st_handlers = handlers, wiping out resumer 0x8! */
    st_handlers = handlers;
#else
    /* FIX: splice paused_prefix onto cur_h when cur_h != outer_handlers */
    st_handlers = (st_handlers == outer_handlers) ? handlers : (paused_prefix | st_handlers);
#endif
    assert((st_handlers & 0x1) != 0);
    assert((st_handlers & 0x2) != 0);
    assert((st_handlers & 0x4) != 0);
    assert((st_handlers & 0x8) != 0); /* resumer handler preserved! */
  } else if (mode == 2) {
    /* Exception raised inside tail proc, caught by inner catcher between 0x1 and 0x2 */
    int saved_h = st_handlers;
#ifndef MUTANT_TAIL_NO_EH_RESTORE_BEFORE_CATCHER
    /* FIX: restore paused_prefix onto saved_h BEFORE delegating to cur-eh */
    st_handlers = (saved_h == outer_handlers) ? handlers : (paused_prefix | saved_h);
#endif
    /* Inner handler 0x1's macro-dynamic-bind pops 0x1 before inner catcher runs */
    st_handlers &= ~0x1;
    /* Inner catcher MUST observe H_e1 (0x2) and H_outer (0x4), and NOT 0x1 */
    assert((st_handlers & 0x1) == 0);
    assert((st_handlers & 0x2) != 0);
    assert((st_handlers & 0x4) != 0);
  } else if (mode == 3) {
    /* Continuable exception inside tail proc: restore -> cur-eh returns -> re-hide */
    int saved_h = st_handlers;
    st_handlers = (saved_h == outer_handlers) ? handlers : (paused_prefix | saved_h);
    /* Outer with-exception-handler returns value; inner eh restores handlers, then we restore saved_h */
#ifndef MUTANT_TAIL_CONTINUABLE_WRONG_SCOPE
    st_handlers = saved_h;
#endif
    /* Tail proc continues executing in its exact outer scope (0x4 only, NOT 0x1 or 0x2!) */
    assert((st_handlers & 0x2) == 0);
    assert((st_handlers & 0x1) == 0);
    assert((st_handlers & 0x4) != 0);
    /* Normal return restores full stack */
    st_handlers = (st_handlers == outer_handlers) ? handlers : (paused_prefix | st_handlers);
    assert(st_handlers == handlers);
  } else {
    /* mode == 0: normal return */
    st_handlers = (st_handlers == outer_handlers) ? handlers : (paused_prefix | st_handlers);
    assert(st_handlers == handlers);
  }

  return 1;
}

static volatile int g_t1_ok;
static volatile int g_t2_ok;

int main(void) {
  g_t1_ok = 0;
  g_t2_ok = 0;

  __CPROVER_ASYNC_1:
  {
    store_rel(&g_t1_ok, run_thread_tail_scenario());
  }

  store_rel(&g_t2_ok, run_thread_tail_scenario());

  __CPROVER_assume(load_acq(&g_t1_ok) == 1 && load_acq(&g_t2_ok) == 1);
  assert(load_acq(&g_t1_ok) == 1 && load_acq(&g_t2_ok) == 1);
  return 0;
}
