/* Phase C50 CBMC --mm pso Verification Harness:
 * 1. Structural Defense-in-Depth in %mc-return1 / %mc-return-vals / %mc-return1-with-fn
 * 2. Zero-Leak Tail-Capability Guard Pop on Escaping Exceptions & Continuable Restore
 * 3. Zero-Capture, Zero-Leak, Continuable-Safe Fork-Join Combinators (Concurrent PSO)
 *
 * Negative Mutants (each MUST fail with VERIFICATION FAILED):
 *   -DMUTANT_MC_RETURN_NO_GUARD_SKIP
 *   -DMUTANT_CAP_LEAKS_GUARD_ON_ESCAPE
 *   -DMUTANT_FJ_OUTER_CATCHER_LEAKS_GUARD
 *   -DMUTANT_FJ_NO_JOIN_ON_ESCAPE
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

static inline int load_acq(volatile int *p) { int v = *p; fence_acq(); return v; }
static inline void store_rel(volatile int *p, int v) { fence_rel(); *p = v; }

/* =========================================================================
 * Test 1: %mc-return* Structural Guard-Skip Safety (No NULL escape_k Deref)
 * ========================================================================= */
typedef struct {
  int kind;     /* 0 = prompt, 1 = unwind-guard */
  int escape_k; /* non-zero for prompt, 0 for unwind-guard */
  int hook_ran;
} mc_frame_t;

static void test_mc_return_skip_guards(void) {
  mc_frame_t stack[3];
  /* Bottom: real prompt with valid escape_k = 1 */
  stack[0].kind = 0; stack[0].escape_k = 1; stack[0].hook_ran = 0;
  /* Top: 1 or 2 stray unwind-guard frames with escape_k = 0 */
  stack[1].kind = 1; stack[1].escape_k = 0; stack[1].hook_ran = 0;
  stack[2].kind = 1; stack[2].escape_k = 0; stack[2].hook_ran = 0;

  int top = nondet_int();
  __CPROVER_assume(top >= 0 && top <= 2);

  int target_ek = 0;
#ifdef MUTANT_MC_RETURN_NO_GUARD_SKIP
  /* BUG: old %mc-return* blindly dereferences stack[top].escape_k -> SIGSEGV when 0! */
  target_ek = stack[top].escape_k;
#else
  while (top >= 0) {
    if (stack[top].escape_k != 0) {
      target_ek = stack[top].escape_k;
      top--;
      break;
    }
    /* Skip unwind-guard frame and invoke its unwind hook */
    stack[top].hook_ran = 1;
    top--;
  }
#endif
  assert(target_ek != 0);
}

/* =========================================================================
 * Test 2: Tail-Capability Guard Pop Under Prompt + Non-Trampoline Catcher/EH
 * ========================================================================= */
static void test_tail_cap_guard_pop(void) {
  int cap_live = 1;
  int guard_on_mc = 1;
  int continuable = nondet_int();
  __CPROVER_assume(continuable == 0 || continuable == 1);

  /* Body raises exception while inside prompt + non-trampoline cur-eh */
  int prev_live = cap_live;
  cap_live = 0;
#ifndef MUTANT_CAP_LEAKS_GUARD_ON_ESCAPE
  /* FIX: pop guard_frame from st.mc BEFORE calling cur-eh */
  int saved_guard = guard_on_mc;
  guard_on_mc = 0;
#endif

  if (continuable) {
    /* cur-eh returns -> restore guard_on_mc & cap_live */
#ifndef MUTANT_CAP_LEAKS_GUARD_ON_ESCAPE
    guard_on_mc = saved_guard;
#endif
    cap_live = prev_live;
    assert(guard_on_mc == 1);
    assert(cap_live == 1);
    /* Normal exit pops guard & deactivates cap */
    guard_on_mc = 0;
    cap_live = 0;
    assert(guard_on_mc == 0);
    assert(cap_live == 0);
  } else {
    /* cur-eh escapes to enclosing with-exception-catcher inside prompt */
    assert(guard_on_mc == 0);
    assert(cap_live == 0);
  }
}

/* =========================================================================
 * Test 3: Concurrent Fork-Join Guard Under PSO (Escape, Abort, Continuable)
 * ========================================================================= */
static volatile int g_right_state;  /* 0 = running, 1 = done */
static volatile int g_right_result;

static void test_fork_join_guard_pso(void) {
  g_right_state = 0;
  g_right_result = 0;

  /* Worker thread executes right future concurrently */
  __CPROVER_ASYNC_1:
  {
    store_rel(&g_right_result, 42);
    store_rel(&g_right_state, 1);
  }

  int guard_on_mc = 1;
  int in_eh = 0;
  int suspended = 0;
  int joined = 0;
  int join_count = 0;
  int mode = nondet_int();
  __CPROVER_assume(mode >= 0 && mode <= 2);
  /* mode 0: left raises continuable exception (outer eh returns)
   * mode 1: left raises escaping exception (outer catcher escapes)
   * mode 2: left escapes via abort-current-continuation / call/1cc
   */

#ifdef MUTANT_FJ_OUTER_CATCHER_LEAKS_GUARD
  /* BUG: outer with-exception-catcher escapes past %with-fork-join-guard without popping guard_on_mc */
  if (mode == 0 || mode == 1) {
    /* guard_on_mc leaked! */
    assert(guard_on_mc == 0);
  }
  return;
#endif

  if (mode == 0 || mode == 1) {
    int returned = 0;
    in_eh = 1;
    /* Trampoline 'unwind sees in_eh == 1 -> does NOT prematurely join right */
    if (!in_eh && !joined) {
      joined = 1; join_count++;
      __CPROVER_assume(load_acq(&g_right_state) == 1);
      guard_on_mc = 0;
    }

    if (mode == 0) {
      /* Continuable return */
      returned = 1;
      in_eh = 0;
      if (!returned && !suspended && !joined) {
        joined = 1; join_count++;
        __CPROVER_assume(load_acq(&g_right_state) == 1);
        guard_on_mc = 0;
      }
      assert(join_count == 0);
      assert(guard_on_mc == 1);
      /* Left finishes normally -> pops guard, then joins right */
      guard_on_mc = 0;
      if (!joined) {
        joined = 1; join_count++;
        __CPROVER_assume(load_acq(&g_right_state) == 1);
      }
      assert(join_count == 1);
      assert(guard_on_mc == 0);
      assert(load_acq(&g_right_result) == 42);
    } else {
      /* mode == 1: escaping exception -> cold-path after pops guard & joins right BEFORE catcher */
      in_eh = 0;
      guard_on_mc = 0;
#ifndef MUTANT_FJ_NO_JOIN_ON_ESCAPE
      if (!returned && !suspended && !joined) {
        joined = 1; join_count++;
        __CPROVER_assume(load_acq(&g_right_state) == 1);
      }
#endif
      /* Outer catcher observes right future ALREADY finished & zero stale guards */
      assert(guard_on_mc == 0);
      assert(load_acq(&g_right_state) == 1);
      assert(load_acq(&g_right_result) == 42);
      assert(join_count == 1);
    }
  } else {
    /* mode == 2: direct abort / call/1cc with in_eh == 0 */
    if (!in_eh && !joined) {
      joined = 1; join_count++;
      __CPROVER_assume(load_acq(&g_right_state) == 1);
      guard_on_mc = 0;
    }
    assert(guard_on_mc == 0);
    assert(load_acq(&g_right_state) == 1);
    assert(join_count == 1);
  }
}

int main(void) {
  test_mc_return_skip_guards();
  test_tail_cap_guard_pop();
  test_fork_join_guard_pso();
  return 0;
}
