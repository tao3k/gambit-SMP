/*
 * CBMC PSO harness for (gambit effect) dynamic tail-resumptive handler frame
 * popping (%pop-handler-frame!) and (srfi 226) dynamic barrier push/pop.
 *
 * Negative mutants (all 4 MUST fail CBMC):
 *   -DINJECT_BUG_RESTORE_STALE_OLD_HANDLERS_NORMAL
 *   -DINJECT_BUG_RESTORE_STALE_OLD_HANDLERS_EXC
 *   -DINJECT_BUG_SKIP_POP_INNER_ON_EXC
 *   -DINJECT_BUG_STALE_BARRIER_RESTORE
 */

#include <assert.h>
#include <stdbool.h>

#define H_ZOMBIE 1
#define H_TAIL   2
#define H_RES_A  3
#define H_RES_B  4
#define H_INNER  5

#define B_OUTER  10
#define B_INNER  20

#define MAX_STK  8

typedef struct {
  int items[MAX_STK];
  int len; /* top is items[len - 1] */
} stk_t;

extern bool nondet_bool(void);

static void stk_push(stk_t *s, int v) {
  assert(s->len < MAX_STK);
  s->items[s->len++] = v;
}

static bool stk_contains(const stk_t *s, int v) {
  for (int i = 0; i < MAX_STK; i++) {
    if (i < s->len && s->items[i] == v) return true;
  }
  return false;
}

static void pop_frame(stk_t *s, int target) {
  if (s->len > 0 && s->items[s->len - 1] == target) {
    s->len--;
    return;
  }
#ifndef INJECT_BUG_SKIP_POP_INNER_ON_EXC
  for (int i = MAX_STK - 1; i >= 0; i--) {
    if (i < s->len && s->items[i] == target) {
      s->len = i;
      return;
    }
  }
#endif
}

static void run_replayed_tail_handler(
    stk_t *handlers,
    stk_t *barriers,
    const stk_t *capture_old_handlers,
    const stk_t *capture_old_barriers,
    int resumer_h,
    bool has_inner_frame,
    bool throws_exc) {

  /* Resumer installs resumer_h and B_OUTER, then replays captured segment with H_TAIL */
  handlers->len = 0;
  stk_push(handlers, resumer_h);
  stk_push(handlers, H_TAIL);

  barriers->len = 0;
  stk_push(barriers, B_OUTER);

  /* Enter and exit an inner barrier dynamically inside resumed body */
  stk_push(barriers, B_INNER);
#ifdef INJECT_BUG_STALE_BARRIER_RESTORE
  *barriers = *capture_old_barriers;
#else
  pop_frame(barriers, B_INNER);
#endif
  assert(stk_contains(barriers, B_OUTER));
  assert(!stk_contains(barriers, B_INNER));

  if (has_inner_frame) {
    stk_push(handlers, H_INNER);
  }

  if (throws_exc) {
#ifdef INJECT_BUG_RESTORE_STALE_OLD_HANDLERS_EXC
    *handlers = *capture_old_handlers;
#else
    pop_frame(handlers, H_TAIL);
#endif
  } else {
    if (has_inner_frame) {
      pop_frame(handlers, H_INNER);
    }
#ifdef INJECT_BUG_RESTORE_STALE_OLD_HANDLERS_NORMAL
    *handlers = *capture_old_handlers;
#else
    pop_frame(handlers, H_TAIL);
#endif
  }

  /* Post-conditions: resumer handler preserved, zombie never resurrected, H_TAIL gone */
  assert(stk_contains(handlers, resumer_h));
  assert(!stk_contains(handlers, H_ZOMBIE));
  assert(!stk_contains(handlers, H_TAIL));
}

int main(void) {
  stk_t capture_old_handlers = {{H_ZOMBIE}, 1};
  stk_t capture_old_barriers = {{0}, 0};

  stk_t handlers = {{0}, 0};
  stk_t barriers = {{0}, 0};

  bool inner1 = nondet_bool();
  bool exc1 = nondet_bool();
  run_replayed_tail_handler(
      &handlers, &barriers, &capture_old_handlers, &capture_old_barriers,
      H_RES_A, inner1, exc1);

  /* Second multi-shot replay under a different resumer handler H_RES_B */
  bool inner2 = nondet_bool();
  bool exc2 = nondet_bool();
  run_replayed_tail_handler(
      &handlers, &barriers, &capture_old_handlers, &capture_old_barriers,
      H_RES_B, inner2, exc2);

  return 0;
}
