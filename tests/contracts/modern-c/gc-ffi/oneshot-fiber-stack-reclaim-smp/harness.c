/* Phase C20: Adversarial CBMC PSO Harness for One-Shot Fiber Continuation
 * Stack Rewind & Parked-Section Recycling.
 *
 * Verifies under --mm pso:
 *   1. Non-aliasing proof (cont_hdr + cont_alloc == top) protects multi-shot call/cc spans
 *   2. Concurrent SATB major GC guard prevents reclaiming/recycling SATB-observed spans
 *   3. Parked-section recycling refuses sections with parked_top != 0, raw_live_spans > 0,
 *      heap_used != 0, or source_pins > 0
 *   4. Cross-carrier concurrent steal consumption + owner recycle under copy_gate is PSO-safe
 *
 * Negative Mutants (each MUST trigger VERIFICATION FAILED):
 *   -DINJECT_BUG_CLEAR_ALIASED_CONT
 *   -DINJECT_BUG_RECLAIM_UNDER_SATB
 *   -DINJECT_BUG_RECYCLE_WITH_PARKED_TOP
 *   -DINJECT_BUG_RECYCLE_WITHOUT_COPY_GATE_OR_PINS
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern void __CPROVER_assume(int);

static inline void fence_full(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

enum StackState {
  STACK_UNCLAIMED = 0,
  STACK_ACTIVE    = 1,
  STACK_PARKED    = 2,
  STACK_REUSABLE  = 3
};

static volatile int g_copy_gate;
static int g_owner;
static volatile int g_state;
static volatile int g_gen;
static volatile int g_raw_live_spans;
static int g_has_parked_top;
static int g_heap_used;
static volatile int g_source_pins;
static volatile int g_satb_active;

/* Span slot 0..1 (no pointers in concurrent paths for clean CBMC PSO modeling) */
static int sp_gen[2];
static int sp_is_oneshot[2];
static int sp_cont_hdr[2];
static int sp_cont_alloc[2];
static int sp_top[2];
static int sp_full_copy[2];
static volatile int sp_alive[2];
static int sp_satb_pinned[2];
static volatile int g_uaf;

static int try_acquire_gate(void) {
  int got = 0;
  __CPROVER_atomic_begin();
  if (g_copy_gate == 0) {
    g_copy_gate = 1;
    got = 1;
  }
  __CPROVER_atomic_end();
  if (got) fence_full();
  return got;
}

static void release_gate(void) {
  fence_full();
  __CPROVER_atomic_begin();
  g_copy_gate = 0;
  __CPROVER_atomic_end();
}

static int try_consume_oneshot(int idx) {
  int satb;
  __CPROVER_atomic_begin();
  satb = g_satb_active;
  __CPROVER_atomic_end();
#ifndef INJECT_BUG_RECLAIM_UNDER_SATB
  if (satb != 0) return 0;
#endif
  if (!sp_is_oneshot[idx] || !sp_full_copy[idx]) return 0;

#ifndef INJECT_BUG_CLEAR_ALIASED_CONT
  /* Pointer-adjacency proof: excludes r0 == handler_break aliased capture */
  if (sp_cont_hdr[idx] + sp_cont_alloc[idx] != sp_top[idx]) return 0;
#endif

  if (!try_acquire_gate()) return 0;
  if (g_gen != sp_gen[idx] || (g_state != STACK_ACTIVE && g_state != STACK_PARKED)) {
    g_uaf = 1;
    release_gate();
    return 0;
  }
  if (g_raw_live_spans > 0) {
    g_raw_live_spans = g_raw_live_spans - 1;
  }
  sp_alive[idx] = 0;
  release_gate();
  return 1;
}

static int try_recycle_parked(int ps) {
  int satb;
  __CPROVER_atomic_begin();
  satb = g_satb_active;
  __CPROVER_atomic_end();
#ifndef INJECT_BUG_RECLAIM_UNDER_SATB
  if (satb != 0) return 0;
#endif

#ifndef INJECT_BUG_RECYCLE_WITHOUT_COPY_GATE_OR_PINS
  if (!try_acquire_gate()) return 0;
#endif
  int ok = 1;
  if (g_owner != ps) ok = 0;
  if (g_state != STACK_PARKED) ok = 0;
  if (g_heap_used != 0) ok = 0;
#ifndef INJECT_BUG_RECYCLE_WITH_PARKED_TOP
  if (g_has_parked_top != 0) ok = 0;
#endif
  if (g_raw_live_spans != 0) ok = 0;
#ifndef INJECT_BUG_RECYCLE_WITHOUT_COPY_GATE_OR_PINS
  if (g_source_pins != 0) ok = 0;
#endif

  if (ok) {
    g_state = STACK_REUSABLE;
    g_gen = g_gen + 1;
  }
#ifndef INJECT_BUG_RECYCLE_WITHOUT_COPY_GATE_OR_PINS
  release_gate();
#endif
  return ok;
}

static void stealer_thread(void) {
  (void)try_consume_oneshot(0);
}

int main(void) {
  int scenario;
  __CPROVER_assume(scenario >= 0 && scenario <= 3);

  g_copy_gate = 0;
  g_owner = 0;
  g_state = STACK_PARKED;
  g_gen = 1;
  g_heap_used = 0;
  g_source_pins = 0;
  g_satb_active = 0;
  g_uaf = 0;

  if (scenario == 0) {
    /* Scenario 0: Aliased one-shot capture sharing a multi-shot call/cc frame. */
    g_raw_live_spans = 1;
    g_has_parked_top = 0;

    /* Slot 0: multi-shot call/cc span */
    sp_gen[0] = 1; sp_is_oneshot[0] = 0; sp_cont_hdr[0] = 100; sp_cont_alloc[0] = 8;
    sp_top[0] = 108; sp_full_copy[0] = 1; sp_alive[0] = 1; sp_satb_pinned[0] = 0;

    /* Slot 1: aliased one-shot capture (cont_hdr + cont_alloc = 88 != 108) */
    sp_gen[1] = 1; sp_is_oneshot[1] = 1; sp_cont_hdr[1] = 80; sp_cont_alloc[1] = 8;
    sp_top[1] = 108; sp_full_copy[1] = 1; sp_alive[1] = 1; sp_satb_pinned[1] = 0;

    (void)try_consume_oneshot(1);
    (void)try_recycle_parked(0);

    assert(g_uaf == 0);
    assert(sp_alive[0] == 1);
    assert(g_gen == sp_gen[0]);
    assert(g_state == STACK_PARKED);
    assert(g_raw_live_spans == 1);
  } else if (scenario == 1) {
    /* Scenario 1: Concurrent SATB major GC active when one-shot is consumed. */
    g_raw_live_spans = 1;
    g_has_parked_top = 0;
    g_satb_active = 1;

    sp_gen[0] = 1; sp_is_oneshot[0] = 1; sp_cont_hdr[0] = 100; sp_cont_alloc[0] = 8;
    sp_top[0] = 108; sp_full_copy[0] = 1; sp_alive[0] = 1; sp_satb_pinned[0] = 1;

    (void)try_consume_oneshot(0);
    (void)try_recycle_parked(0);

    assert(g_uaf == 0);
    assert(sp_satb_pinned[0] == 1);
    assert(g_gen == sp_gen[0]);
    assert(g_state == STACK_PARKED);
    assert(g_raw_live_spans == 1);
  } else if (scenario == 2) {
    /* Scenario 2: Parked section with non-empty active caller suffix MUST NOT recycle. */
    g_raw_live_spans = 0;
    g_has_parked_top = 1;

    int recycled = try_recycle_parked(0);
    assert(recycled == 0);
    assert(g_state == STACK_PARKED);
    assert(g_gen == 1);
  } else {
    /* Scenario 3: True concurrent PSO race between sibling stealer consuming the
     * last span and owner attempting recycle, plus source_pins exclusion. */
    g_raw_live_spans = 1;
    g_has_parked_top = 0;

    sp_gen[0] = 1; sp_is_oneshot[0] = 1; sp_cont_hdr[0] = 100; sp_cont_alloc[0] = 8;
    sp_top[0] = 108; sp_full_copy[0] = 1; sp_alive[0] = 1; sp_satb_pinned[0] = 0;

    g_source_pins = 1;
    __CPROVER_ASYNC_1: stealer_thread();

    int r_pinned = try_recycle_parked(0);
    assert(r_pinned == 0);
    assert(g_gen == 1);
    assert(g_uaf == 0);

    __CPROVER_atomic_begin();
    g_source_pins = 0;
    __CPROVER_atomic_end();
    fence_full();

    (void)try_recycle_parked(0);
    assert(g_uaf == 0);
  }

  return 0;
}
