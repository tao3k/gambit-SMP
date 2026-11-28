/*
 * CBMC PSO harness for (srfi 226) composable continuation replay and
 * (gambit effect) resume / resume-multishot transactional post-dynamic-wind
 * commit and continuation-barrier enforcement.
 *
 * Verifies:
 *   1. Fast path (same_dynwind): direct commit preserves barriers & target state.
 *   2. Winding path: caller dynamic-wind after-thunk observes pure caller
 *      mc/marks/handlers (never target's prompts/marks/effect handlers).
 *   3. Post-unwind landing thunk restores caller_barriers after barrier's own
 *      dynamic-wind after-thunk popped st_barriers -> zero barrier bypass.
 *   4. Throwing inside after-thunk skips landing thunk -> zero zombie uframe/handlers.
 *   5. One-shot vs promoted multi-shot atomic CAS slot preservation.
 *
 * Negative mutants (all 4 MUST fail CBMC):
 *   -DINJECT_BUG_EAGER_COMMIT_BEFORE_AFTER
 *   -DINJECT_BUG_BARRIER_WIPED_BY_AFTER_THUNK
 *   -DINJECT_BUG_STALE_UFRAME_ON_AFTER_THROW
 *   -DINJECT_BUG_CLEAR_MULTISHOT_SLOTS
 */

#include <assert.h>
#include <stdbool.h>

#define STATE_LIVE      0
#define STATE_CONSUMED  1
#define STATE_MULTISHOT 2

typedef struct {
  int mc;
  int marks;
  int barriers;
  int handlers;
} ctrl_state_t;

typedef struct {
  volatile int state;
  int sub_k;
  int prefix;
  int marks;
  int handlers;
} cont_cell_t;

extern bool nondet_bool(void);

static int atomic_cas_int(volatile int *p, int expected, int desired) {
  int prev;
  __CPROVER_atomic_begin();
  prev = *p;
  if (prev == expected) {
    *p = desired;
  }
  __CPROVER_atomic_end();
  return prev;
}

static void clear_consumed_cell(cont_cell_t *c) {
  c->sub_k = 0;
  c->prefix = 0;
  c->marks = 0;
  c->handlers = 0;
}

static bool invoke_composable_or_resume(
    ctrl_state_t *st,
    cont_cell_t *cell,
    bool same_dynwind,
    bool after_throws,
    bool *after_observed_pure,
    bool *entered_target) {

  int prev = atomic_cas_int(&cell->state, STATE_LIVE, STATE_CONSUMED);

  if (prev != STATE_LIVE && prev != STATE_MULTISHOT) {
    return false;
  }

  /* Extract locals before clearing one-shot slots */
  int sub_k = cell->sub_k;
  int prefix = cell->prefix;
  int cap_marks = cell->marks;
  int cap_handlers = cell->handlers;
  assert(sub_k != 0);

  if (prev == STATE_LIVE) {
    clear_consumed_cell(cell);
  }
#ifdef INJECT_BUG_CLEAR_MULTISHOT_SLOTS
  else if (prev == STATE_MULTISHOT) {
    clear_consumed_cell(cell);
  }
#endif

  int caller_mc = st->mc;
  int caller_marks = st->marks;
  int caller_barriers = st->barriers;
  int caller_handlers = st->handlers;

  int composed_mc = caller_mc + prefix + 1;
  int composed_marks = caller_marks + cap_marks;
  int composed_handlers = caller_handlers + cap_handlers;

  if (same_dynwind) {
    st->mc = composed_mc;
    st->marks = composed_marks;
    st->barriers = caller_barriers;
    st->handlers = composed_handlers;
    *after_observed_pure = true;
    *entered_target = true;
    return true;
  }

#ifdef INJECT_BUG_EAGER_COMMIT_BEFORE_AFTER
  /* Pre-C36 bug: mutate st BEFORE unwinding dynamic-wind */
  st->mc = composed_mc;
  st->marks = composed_marks;
  st->barriers = caller_barriers;
  st->handlers = composed_handlers;
#endif

  /* Simulate unwinding caller dynamic-wind (including barrier's after-thunk). */
  *after_observed_pure = (st->mc == caller_mc &&
                          st->marks == caller_marks &&
                          st->handlers == caller_handlers);
  /* Barrier's dynamic-wind after-thunk temporarily pops the barrier token. */
  if (caller_barriers > 0) {
    st->barriers = caller_barriers - 1;
  }

  if (after_throws) {
#ifdef INJECT_BUG_STALE_UFRAME_ON_AFTER_THROW
    /* Bug: leak composed uframe / handlers on rollback */
    st->mc = composed_mc;
    st->handlers = composed_handlers;
#endif
    /* Unwinding aborts back into caller scope (re-entering barrier if caught inside) */
    st->barriers = caller_barriers;
    *entered_target = false;
    return true;
  }

  /* Post-unwind landing thunk via ##continuation-graft:
   * commits composed state AND restores caller_barriers! */
  st->mc = composed_mc;
  st->marks = composed_marks;
#ifndef INJECT_BUG_BARRIER_WIPED_BY_AFTER_THUNK
  st->barriers = caller_barriers;
#endif
  st->handlers = composed_handlers;
  *entered_target = true;
  return true;
}

int main(void) {
  ctrl_state_t st;
  st.mc = 1;
  st.marks = 10;
  st.barriers = nondet_bool() ? 1 : 0;
  st.handlers = 1;

  int orig_mc = st.mc;
  int orig_marks = st.marks;
  int orig_barriers = st.barriers;
  int orig_handlers = st.handlers;

  cont_cell_t cell;
  bool is_multi = nondet_bool();
  cell.state = is_multi ? STATE_MULTISHOT : STATE_LIVE;
  cell.sub_k = 42;
  cell.prefix = 2;
  cell.marks = 5;
  cell.handlers = 3;

  bool same_dw = (st.barriers == 0) ? nondet_bool() : false;
  bool after_throws = same_dw ? false : nondet_bool();

  bool after_pure = false;
  bool entered = false;

  bool ok = invoke_composable_or_resume(
      &st, &cell, same_dw, after_throws, &after_pure, &entered);
  assert(ok);

  /* Property 1: caller after-thunk NEVER sees target mc/marks/handlers */
  assert(after_pure);

  if (entered) {
    /* Property 2: target enters with exact composed state */
    assert(st.mc == orig_mc + 2 + 1);
    assert(st.marks == orig_marks + 5);
    assert(st.handlers == orig_handlers + 3);
    /* Property 3: continuation barrier MUST remain enforced inside target */
    assert(st.barriers == orig_barriers);
    if (orig_barriers > 0) {
      assert(st.barriers > 0);
    }
  } else {
    /* Property 4: throwing after-thunk rolls back with zero zombie state */
    assert(after_throws);
    assert(st.mc == orig_mc);
    assert(st.marks == orig_marks);
    assert(st.handlers == orig_handlers);
    assert(st.barriers == orig_barriers);
  }

  /* Property 5: one-shot cleared & second call rejected; multi-shot preserved */
  if (!is_multi) {
    assert(cell.sub_k == 0 && cell.prefix == 0 && cell.marks == 0 && cell.handlers == 0);
    bool ok2 = invoke_composable_or_resume(&st, &cell, true, false, &after_pure, &entered);
    assert(!ok2);
  } else {
    assert(cell.sub_k == 42 && cell.prefix == 2 && cell.marks == 5 && cell.handlers == 3);
    /* Reset caller state and replay second time */
    st.mc = orig_mc;
    st.marks = orig_marks;
    st.barriers = orig_barriers;
    st.handlers = orig_handlers;
    bool ok2 = invoke_composable_or_resume(&st, &cell, same_dw, false, &after_pure, &entered);
    assert(ok2 && after_pure && entered && st.barriers == orig_barriers);
  }

  return 0;
}
