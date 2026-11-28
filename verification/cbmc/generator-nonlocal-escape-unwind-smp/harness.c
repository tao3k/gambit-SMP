/*
 * CBMC PSO harness for generator lifecycle coherency across non-local escapes:
 *   - abort-current-continuation
 *   - raw / non-composable call/1cc
 *   - outer suspending effect perform & resume
 *   - transactional dynamic-wind after-thunk rollback
 *
 * Negative mutants (all 4 MUST fail CBMC):
 *   -DINJECT_BUG_ABORT_SKIPS_UNWIND_HOOK
 *   -DINJECT_BUG_RAW_1CC_SKIPS_UNWIND_HOOK
 *   -DINJECT_BUG_PERFORM_SKIPS_UNWIND_HOOK
 *   -DINJECT_BUG_EAGER_UNWIND_BEFORE_AFTER_THROW
 */

#include <assert.h>
#include <stdbool.h>

#define GEN_INIT      0
#define GEN_RUNNING   1
#define GEN_SUSPENDED 2
#define GEN_DONE      3

typedef struct {
  int state;
  bool on_mc_stack;
  bool mc_cell_detached;
  bool frozen;
} gen_t;

extern bool nondet_bool(void);

static void gen_unwind_hook(gen_t *g, bool is_unwind) {
  if (is_unwind) {
    if (!g->frozen) {
      g->mc_cell_detached = true;
    }
    g->state = GEN_DONE;
  } else {
    /* restore */
    if (g->state == GEN_DONE) {
      g->state = GEN_RUNNING;
    }
  }
}

static void check_coherent(const gen_t *g) {
  assert((g->state == GEN_RUNNING) == g->on_mc_stack);
}

static void abort_escape(gen_t *g, bool after_throws) {
  assert(g->state == GEN_RUNNING && g->on_mc_stack);
#ifdef INJECT_BUG_EAGER_UNWIND_BEFORE_AFTER_THROW
  /* Bug: run unwind hook BEFORE after-thunk potentially throws */
  gen_unwind_hook(g, true);
#endif
  if (after_throws) {
    /* Transactional rollback: generator frame remains active on st.mc */
    return;
  }
  g->on_mc_stack = false;
#ifndef INJECT_BUG_ABORT_SKIPS_UNWIND_HOOK
  gen_unwind_hook(g, true);
#endif
}

static void raw_1cc_escape(gen_t *g, bool after_throws) {
  assert(g->state == GEN_RUNNING && g->on_mc_stack);
  if (after_throws) {
    return;
  }
  g->on_mc_stack = false;
#ifndef INJECT_BUG_RAW_1CC_SKIPS_UNWIND_HOOK
  gen_unwind_hook(g, true);
#endif
}

static void outer_effect_perform_and_maybe_resume(gen_t *g, bool will_resume) {
  assert(g->state == GEN_RUNNING && g->on_mc_stack);
  g->frozen = true;
  g->on_mc_stack = false;
#ifndef INJECT_BUG_PERFORM_SKIPS_UNWIND_HOOK
  gen_unwind_hook(g, true);
#endif
  check_coherent(g);
  assert(g->state == GEN_DONE);

  if (will_resume) {
    g->on_mc_stack = true;
    gen_unwind_hook(g, false);
    check_coherent(g);
    assert(g->state == GEN_RUNNING);
  }
}

int main(void) {
  /* 1. abort-current-continuation escape (with or without throwing after-thunk) */
  gen_t g1 = {GEN_RUNNING, true, false, false};
  bool after_throws_1 = nondet_bool();
  abort_escape(&g1, after_throws_1);
  check_coherent(&g1);
  if (!after_throws_1) {
    assert(g1.state == GEN_DONE && g1.mc_cell_detached);
  } else {
    assert(g1.state == GEN_RUNNING && g1.on_mc_stack);
  }

  /* 2. raw call/1cc escape */
  gen_t g2 = {GEN_RUNNING, true, false, false};
  bool after_throws_2 = nondet_bool();
  raw_1cc_escape(&g2, after_throws_2);
  check_coherent(&g2);
  if (!after_throws_2) {
    assert(g2.state == GEN_DONE && g2.mc_cell_detached);
  }

  /* 3. outer suspending effect perform (both abandoned and resumed) */
  gen_t g3 = {GEN_RUNNING, true, false, false};
  bool will_resume = nondet_bool();
  outer_effect_perform_and_maybe_resume(&g3, will_resume);
  check_coherent(&g3);

  return 0;
}
