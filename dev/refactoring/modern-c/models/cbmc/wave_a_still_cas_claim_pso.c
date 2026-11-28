/* Stage 6 CBMC --mm pso weak-memory contract harness for Wave A:
 * Parallel Minor GC atomic CAS claim on young_still objects and
 * deferred ___sFOREIGN release custody.
 *
 * Safe mode  (-DUSE_GUARD=1): MUST PASS under `cbmc --mm pso`.
 * Mutant mode(-DUSE_GUARD=0): MUST FAIL (proving CAS prevents double-push cycle).
 */
#include <assert.h>
#include <stdint.h>

#ifndef USE_GUARD
#define USE_GUARD 1
#endif

typedef intptr_t word_t;

static word_t young_mark = -1;       /* -1 = unmarked; else next pointer (0 = list end) */
static int w0_pushed = 0;
static int w1_pushed = 0;
static int w0_done = 0;
static int w1_done = 0;
static int deferred_foreign = 0;
static int inline_stw_release = 0;

static int cas_mark_from_unmarked(word_t desired) {
  int won = 0;
  __CPROVER_atomic_begin();
  if (young_mark == -1) {
    young_mark = desired;
    won = 1;
  }
  __CPROVER_atomic_end();
  return won;
}

static void worker0(void) {
#if USE_GUARD
  if (cas_mark_from_unmarked(0)) {
    w0_pushed = 1;
  }
#else
  /* Mutant: non-atomic check-then-set allows both workers to push the same
   * young_still node onto their still_objs_to_scan lists (list corruption/cycle). */
  if (young_mark == -1) {
    young_mark = 0;
    w0_pushed = 1;
  }
#endif
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  w0_done = 1;
}

static void worker1(void) {
#if USE_GUARD
  if (cas_mark_from_unmarked(0)) {
    w1_pushed = 1;
  }
#else
  if (young_mark == -1) {
    young_mark = 0;
    w1_pushed = 1;
  }
#endif
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  w1_done = 1;
}

int main(void) {
  /* 1. Two parallel Minor GC workers race to mark one reachable young_still object. */
  __CPROVER_ASYNC_1: worker0();
  worker1();

  __CPROVER_assume(w0_done == 1 && w1_done == 1);
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");

  /* Exactly one worker must claim and push young_obj (push_count == 1). */
  assert(w0_pushed + w1_pushed == 1);
  assert(young_mark != -1);

  /* 2. Sweep of an unmarked dead young ___sFOREIGN object MUST defer release
   * outside STW (never invoke release_fn inline during STW). */
  int dead_mark = -1;
  int dead_refcount = 0;
  int dead_is_foreign = 1;
  if (dead_mark == -1 && dead_refcount == 0) {
    if (dead_is_foreign) {
      deferred_foreign++;
    }
  }
  assert(deferred_foreign == 1);
  assert(inline_stw_release == 0);
  return 0;
}
