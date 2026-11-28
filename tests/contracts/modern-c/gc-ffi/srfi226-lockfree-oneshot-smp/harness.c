/*
 * CBMC Weak-Memory (--mm pso) Contract Verification Harness:
 * Phase C25 (srfi 226) Lock-Free Closure-Code One-Shot Continuations,
 * Prompt Freeze-on-Capture, and SATB-Safe `%mc-return1` Reclaim.
 *
 * Negative Mutants (each MUST FAIL CBMC):
 *   -DINJECT_BUG_NONATOMIC_ONESHOT_STATE
 *   -DINJECT_BUG_PROMOTE_AFTER_CONSUMED
 *   -DINJECT_BUG_SKIP_PFRAME_FREEZE_ON_CAPTURE
 *   -DINJECT_BUG_SKIP_DENV_GUARD_MC_RETURN1
 *   -DINJECT_BUG_CLEAR_ESCAPEK_ON_RECLAIM_FAIL
 *   -DINJECT_BUG_UNFROZEN_REPLAY_UFRAME
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern int nondet_int(void);

#define STATE_LIVE      0
#define STATE_CONSUMED  1
#define STATE_MULTISHOT 2

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

static inline int cas_seq_cst(volatile int *p, int expected, int desired) {
  int prev;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  prev = *p;
  if (prev == expected)
    *p = desired;
  __CPROVER_atomic_end();
  fence_seq_cst();
  return prev;
}

static inline void atomic_inc(volatile int *p) {
  __CPROVER_atomic_begin();
  *p = *p + 1;
  __CPROVER_atomic_end();
}

static volatile int g_cell_state;
static volatile int g_invoke_wins;
static volatile int g_promoted_flag;
static volatile int g_resurrect_fault;
static volatile int g_t0_done;
static volatile int g_t1_done;

static volatile int g_pframe_frozen;
static volatile int g_pframe_escape_k;
static volatile int g_captured_cont_ref;
static volatile int g_aliased_reclaim_fault;
static volatile int g_denv_skip_fault;
static volatile int g_null_fallback_fault;

static void invoke_oneshot(void) {
#ifdef INJECT_BUG_NONATOMIC_ONESHOT_STATE
  int prev = g_cell_state;
  if (prev == STATE_LIVE) {
    g_cell_state = STATE_CONSUMED;
    atomic_inc(&g_invoke_wins);
  } else if (prev == STATE_MULTISHOT) {
    atomic_inc(&g_invoke_wins);
  }
#else
  int prev = cas_seq_cst(&g_cell_state, STATE_LIVE, STATE_CONSUMED);
  if (prev == STATE_LIVE || prev == STATE_MULTISHOT)
    atomic_inc(&g_invoke_wins);
#endif
}

static void promote_oneshot(void) {
#ifdef INJECT_BUG_PROMOTE_AFTER_CONSUMED
  /* BUG: unconditional store resurrects already-consumed continuation */
  __CPROVER_atomic_begin();
  int old = g_cell_state;
  g_cell_state = STATE_MULTISHOT;
  g_promoted_flag = 1;
  if (old == STATE_CONSUMED)
    g_resurrect_fault = 1;
  __CPROVER_atomic_end();
#else
  int prev = cas_seq_cst(&g_cell_state, STATE_LIVE, STATE_MULTISHOT);
  if (prev == STATE_LIVE) {
    g_promoted_flag = 1;
    g_pframe_frozen = 1;
    fence_seq_cst();
  }
#endif
}

static void s0_t0(void) { invoke_oneshot(); fence_seq_cst(); g_t0_done = 1; }
static void s0_t1(void) { invoke_oneshot(); fence_seq_cst(); g_t1_done = 1; }
static void s1_t0(void) { promote_oneshot(); fence_seq_cst(); g_t0_done = 1; }
static void s1_t1(void) { invoke_oneshot(); fence_seq_cst(); g_t1_done = 1; }

static void capture_delimited(void) {
  g_captured_cont_ref = 1;
#ifndef INJECT_BUG_SKIP_PFRAME_FREEZE_ON_CAPTURE
  g_pframe_frozen = 1;
  fence_seq_cst();
#endif
}

static void mc_return1(int cur_denv, int target_denv, int satb_blocks_reclaim) {
  int ek = g_pframe_escape_k;
  fence_seq_cst();
  int frozen = g_pframe_frozen;

  if (!frozen) {
#ifdef INJECT_BUG_SKIP_DENV_GUARD_MC_RETURN1
    int denv_ok = 1;
#else
    int denv_ok = (cur_denv == target_denv);
#endif
    if (denv_ok) {
#ifdef INJECT_BUG_CLEAR_ESCAPEK_ON_RECLAIM_FAIL
      /* BUG: clears pframe->escape-k before confirming reclaim succeeded */
      g_pframe_escape_k = 0;
      if (!satb_blocks_reclaim) {
        if (g_captured_cont_ref) g_aliased_reclaim_fault = 1;
        if (cur_denv != target_denv) g_denv_skip_fault = 1;
        return;
      }
      if (g_pframe_escape_k == 0)
        g_null_fallback_fault = 1;
      return;
#else
      if (!satb_blocks_reclaim) {
        g_pframe_escape_k = 0;
        if (g_captured_cont_ref) g_aliased_reclaim_fault = 1;
        if (cur_denv != target_denv) g_denv_skip_fault = 1;
        return;
      }
#endif
    }
  }

  /* Safe fallback to ##continuation-return ek val */
  if (ek == 0 || g_pframe_escape_k == 0)
    g_null_fallback_fault = 1;
}

int main(void) {
  int scen = nondet_int() % 5;
  g_cell_state = STATE_LIVE;
  g_invoke_wins = 0;
  g_promoted_flag = 0;
  g_resurrect_fault = 0;
  g_t0_done = 0;
  g_t1_done = 0;
  g_pframe_frozen = 0;
  g_pframe_escape_k = 1;
  g_captured_cont_ref = 0;
  g_aliased_reclaim_fault = 0;
  g_denv_skip_fault = 0;
  g_null_fallback_fault = 0;

  if (scen == 0) {
  __CPROVER_ASYNC_0:
    s0_t0();
    s0_t1();
    if (g_t0_done && g_t1_done) {
      fence_seq_cst();
      assert(g_invoke_wins == 1);
      assert(g_cell_state == STATE_CONSUMED);
    }
  } else if (scen == 1) {
  __CPROVER_ASYNC_1:
    s1_t0();
    s1_t1();
    if (g_t0_done && g_t1_done) {
      fence_seq_cst();
      if (g_cell_state == STATE_CONSUMED) {
        assert(g_invoke_wins == 1);
        assert(g_promoted_flag == 0);
      }
      assert(g_resurrect_fault == 0);
    }
  } else if (scen == 2) {
    int satb = nondet_int() & 1;
    capture_delimited();
    mc_return1(7, 7, satb);
    assert(g_aliased_reclaim_fault == 0);
    assert(g_null_fallback_fault == 0);
  } else if (scen == 3) {
    int cur_d = nondet_int() & 1;
    int satb = nondet_int() & 1;
    mc_return1(cur_d, 0, satb);
    assert(g_denv_skip_fault == 0);
    assert(g_null_fallback_fault == 0);
  } else {
    /* Composable / multi-shot replay installs uframe right before
     * `##continuation-return sub-k` whose underlying prompt frame sits on the
     * same stack section: replay uframe MUST be created frozen (`handler=#t`)
     * so `%mc-return-vals`/`%mc-return1` never reclaims it in-place and
     * overwrites the enclosing prompt's stack continuation (`denv`). */
    g_captured_cont_ref = 1;
#ifdef INJECT_BUG_UNFROZEN_REPLAY_UFRAME
    g_pframe_frozen = 0;
#else
    g_pframe_frozen = 1;
#endif
    mc_return1(7, 7, 0);
    assert(g_aliased_reclaim_fault == 0);
  }

  return 0;
}
