/*
 * Phase C54 CBMC (--mm pso) Verification Harness:
 * Metacontinuation Prefix Relativization & Pointer-Shared Tail Re-Basing
 * for Composable, Non-Composable & Algebraic-Effect Continuation Replays.
 *
 * Verifies concurrent multi-shot replay of a shared relativized inner-prompt
 * prefix across two distinct dynamic extents under PSO memory ordering:
 *   - PA: current-continuation-marks on replayed inner prompt never leaks outer/resumer marks
 *   - PB: returning from replayed inner prompt preserves resumer marks
 *   - PC/PD: returning or aborting replayed inner prompt preserves resumer effect handlers
 *   - PE: returning or aborting replayed inner prompt NEVER bypasses resumer barrier
 *   - Multi-shot immutability: concurrent replays never corrupt each other's extents
 *
 * Negative Mutants (must ALL fail verification):
 *   -DMUTANT_NO_REBASE_MARKS
 *   -DMUTANT_NO_REBASE_HANDLERS
 *   -DMUTANT_NO_REBASE_BARRIERS
 *   -DMUTANT_MUTATE_SHARED_PREFIX_IN_PLACE
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *kind, ...);
extern int nondet_int(void);

#define MAX_LEN 6

/* Symbolic tokens */
#define M_OUTER    10
#define M_INNER    11
#define M_RES1     12
#define M_RES2     13

#define H_OUTER    20
#define H_INNER    21
#define H_RES1     22
#define H_RES2     23

#define B_RES1     30
#define B_RES2     31

typedef struct {
  int items[MAX_LEN];
  int len;
} TokList;

typedef struct {
  TokList marks;
  TokList barriers;
  TokList handlers;
} FrameSnap;

static int list_contains(TokList l, int v) {
  for (int i = 0; i < l.len; i++) {
    if (l.items[i] == v) return 1;
  }
  return 0;
}

static TokList list_append(TokList a, TokList b) {
  TokList out;
  out.len = 0;
  for (int i = 0; i < a.len; i++) out.items[out.len++] = a.items[i];
  for (int i = 0; i < b.len; i++) out.items[out.len++] = b.items[i];
  return out;
}

static TokList list_drop(TokList a, int k) {
  TokList out;
  out.len = 0;
  for (int i = k; i < a.len; i++) out.items[out.len++] = a.items[i];
  return out;
}

static TokList list_take(TokList a, int k) {
  TokList out;
  out.len = 0;
  for (int i = 0; i < k && i < a.len; i++) out.items[out.len++] = a.items[i];
  return out;
}

static TokList tail_for_rel(TokList rel, int cap_len, TokList new_list, TokList base_list) {
  if (rel.len == 0) return base_list;
  if (rel.len <= cap_len) return list_drop(new_list, cap_len - rel.len);
  return list_append(rel, base_list);
}

/* Shared captured multi-shot template (initialized before concurrent replay) */
static TokList g_cap_marks;
static TokList g_cap_handlers;
static FrameSnap g_orig_pf_in;   /* creation-site stale snapshot */
static FrameSnap g_rel_pf_in;    /* relativized template */
static FrameSnap g_shared_mut;   /* used only by MUTANT_MUTATE_SHARED_PREFIX_IN_PLACE */

static int t1_done = 0;
static int t1_ok = 0;

static void seq_fence(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence",
                  "WWcumul", "RRcumul", "RWcumul", "WRcumul");
}

static int run_replay_in_extent(int res_m, int res_b, int res_h, int do_abort) {
  /* Resumer's base control state */
  TokList base_m; base_m.len = 1; base_m.items[0] = res_m;
  TokList base_b; base_b.len = 1; base_b.items[0] = res_b;
  TokList base_h; base_h.len = 2; base_h.items[0] = H_OUTER; base_h.items[1] = res_h;

  /* Replayed thread's live state = cap ++ base */
  TokList new_m = list_append(g_cap_marks, base_m);
  TokList new_b = base_b;
  TokList new_h = list_append(g_cap_handlers, base_h);

  /* Re-base inner prompt frame */
  FrameSnap rebased;
#ifdef MUTANT_NO_REBASE_MARKS
  rebased.marks = g_orig_pf_in.marks; /* BUG: stale capture-site marks! */
#else
  rebased.marks = tail_for_rel(g_rel_pf_in.marks, g_cap_marks.len, new_m, base_m);
#endif

#ifdef MUTANT_NO_REBASE_BARRIERS
  rebased.barriers = g_orig_pf_in.barriers; /* BUG: stale empty barriers -> bypasses resumer barrier! */
#else
  rebased.barriers = tail_for_rel(g_rel_pf_in.barriers, 0, new_b, base_b);
#endif

#ifdef MUTANT_NO_REBASE_HANDLERS
  rebased.handlers = g_orig_pf_in.handlers; /* BUG: stale capture-site handlers! */
#else
  rebased.handlers = tail_for_rel(g_rel_pf_in.handlers, g_cap_handlers.len, new_h, base_h);
#endif

#ifdef MUTANT_MUTATE_SHARED_PREFIX_IN_PLACE
  /* BUG: mutating shared multi-shot frame in-place races across concurrent replays! */
  g_shared_mut = rebased;
  seq_fence();
  rebased = g_shared_mut;
#endif

  /* PA: Query current-continuation-marks up to replayed inner prompt pt-in */
  /* Matches exact tail in new_m iff trailing elements match rebased.marks */
  int match_idx = -1;
  for (int i = 0; i <= new_m.len; i++) {
    int rem = new_m.len - i;
    if (rem == rebased.marks.len) {
      int eq = 1;
      for (int j = 0; j < rem; j++) {
        if (new_m.items[i + j] != rebased.marks.items[j]) { eq = 0; break; }
      }
      if (eq) { match_idx = i; break; }
    }
  }
  /* If match_idx < 0 (stale pointer never matched!), %list-prefix-until leaks ALL of new_m! */
  TokList queried = (match_idx >= 0) ? list_take(new_m, match_idx) : new_m;
  assert(queried.len == 1 && queried.items[0] == M_INNER);
  assert(!list_contains(queried, M_OUTER));
  assert(!list_contains(queried, res_m));

  /* PB/PC/PD/PE: Inner prompt returns normally or aborts -> restores rebased frame snapshot */
  (void)do_abort;
  TokList post_m = rebased.marks;
  TokList post_b = rebased.barriers;
  TokList post_h = rebased.handlers;

  /* Must preserve outer_m AND this extent's exact resumer mark */
  assert(list_contains(post_m, M_OUTER));
  assert(list_contains(post_m, res_m));
  /* Must preserve outer_h AND this extent's exact resumer handler */
  assert(list_contains(post_h, H_OUTER));
  assert(list_contains(post_h, res_h));
  /* Must preserve this extent's exact resumer barrier (ZERO barrier bypass!) */
  assert(list_contains(post_b, res_b));

  return 1;
}

static void async_replay_thread(void) {
  int ok = run_replay_in_extent(M_RES2, B_RES2, H_RES2, 1);
  seq_fence();
  __CPROVER_atomic_begin();
  t1_ok = ok;
  t1_done = 1;
  __CPROVER_atomic_end();
}

int main(void) {
  /* Capture-site setup:
   *   st.marks    = [M_INNER, M_OUTER]
   *   pf_in.marks = [M_OUTER]  (orig base_marks = [])
   *   st.handlers = [H_INNER, H_OUTER]
   *   pf_in.handlers = [H_OUTER] (orig base_handlers = [H_OUTER])
   *   pf_in.barriers = [] (orig base_barriers = [])
   */
  g_cap_marks.len = 2;
  g_cap_marks.items[0] = M_INNER;
  g_cap_marks.items[1] = M_OUTER;

  g_cap_handlers.len = 1;
  g_cap_handlers.items[0] = H_INNER;

  g_orig_pf_in.marks.len = 1;    g_orig_pf_in.marks.items[0] = M_OUTER;
  g_orig_pf_in.barriers.len = 0;
  g_orig_pf_in.handlers.len = 1; g_orig_pf_in.handlers.items[0] = H_OUTER;

  /* Relativized prefix (at capture time) */
  g_rel_pf_in.marks.len = 1;     g_rel_pf_in.marks.items[0] = M_OUTER;
  g_rel_pf_in.barriers.len = 0;
  g_rel_pf_in.handlers.len = 0;

  t1_done = 0;
  t1_ok = 0;
  seq_fence();

__CPROVER_ASYNC_1:
  async_replay_thread();

  int do_abort = nondet_int() ? 1 : 0;
  int ok0 = run_replay_in_extent(M_RES1, B_RES1, H_RES1, do_abort);
  assert(ok0 == 1);

  int d1;
  __CPROVER_atomic_begin();
  d1 = t1_done;
  __CPROVER_atomic_end();
  __CPROVER_assume(d1 == 1);
  seq_fence();

  assert(t1_ok == 1);
  return 0;
}
