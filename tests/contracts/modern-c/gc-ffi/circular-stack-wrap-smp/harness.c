/* Phase C21: Adversarial CBMC PSO Harness for Single-Section Circular
 * Stack-Wrap Protocol (Zero-Overflow Ping-Pong).
 *
 * Verifies under --mm pso:
 *   1. Wrapping to top raises alloc_stack_limit (floor) above raw_high so
 *      subsequent active frames never collide with live lower spans
 *   2. Concurrent SATB major GC blocks wrap-around
 *   3. Cross-carrier source_pins blocks wrap-around under copy_gate
 *   4. Restoring floor -> 0 is admitted ONLY when raw_low >= floor (zero live
 *      spans remain below floor)
 *
 * Negative Mutants (each MUST trigger VERIFICATION FAILED):
 *   -DINJECT_BUG_WRAP_WITHOUT_RAISING_FLOOR
 *   -DINJECT_BUG_WRAP_UNDER_SATB
 *   -DINJECT_BUG_WRAP_WITHOUT_PINS_CHECK
 *   -DINJECT_BUG_RESTORE_FLOOR_WITH_LIVE_LOWER_SPAN
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

#define CAP   64
#define FUDGE 8
#define ALIGN 1

static volatile int g_copy_gate;
static volatile int g_floor;
static volatile int g_stack_break;
static volatile int g_raw_low;
static volatile int g_raw_high;
static volatile int g_raw_wrap_low;
static volatile int g_raw_live_spans;
static volatile int g_source_pins;
static volatile int g_satb_active;

/* Track one lower parked span [lo_top .. lo_brk) */
static volatile int g_lo_top;
static volatile int g_lo_brk;
static volatile int g_lo_alive;
static volatile int g_fault;

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

static int try_wrap_single_section(void) {
  int satb;
  __CPROVER_atomic_begin();
  satb = g_satb_active;
  __CPROVER_atomic_end();
#ifndef INJECT_BUG_WRAP_UNDER_SATB
  if (satb != 0) return 0;
#endif

  if (!try_acquire_gate()) return 0;
#ifndef INJECT_BUG_WRAP_WITHOUT_PINS_CHECK
  if (g_source_pins != 0) {
    release_gate();
    return 0;
  }
#endif

  int new_floor = (g_raw_live_spans == 0) ? 0 : (g_raw_high + ALIGN);
  if (CAP <= new_floor + FUDGE + 4) {
    release_gate();
    return 0;
  }

#ifndef INJECT_BUG_WRAP_WITHOUT_RAISING_FLOOR
  g_floor = new_floor;
#endif
  g_stack_break = CAP;
  g_raw_wrap_low = CAP;
  release_gate();
  return 1;
}

static void try_restore_floor_after_consume(int consumed_lower) {
  if (!try_acquire_gate()) return;
  if (consumed_lower && g_lo_alive) {
    g_lo_alive = 0;
    g_raw_live_spans = g_raw_live_spans - 1;
    g_raw_low = (g_raw_live_spans == 0) ? CAP : g_raw_wrap_low;
  }
#ifdef INJECT_BUG_RESTORE_FLOOR_WITH_LIVE_LOWER_SPAN
  /* BUG: blindly resets floor to 0 even if g_lo_alive == 1! */
  g_floor = 0;
#else
  if (g_raw_live_spans == 0 || g_raw_low >= g_floor) {
    g_floor = 0;
  }
#endif
  release_gate();
}

static void sibling_stealer_consume_lower(void) {
  try_restore_floor_after_consume(1);
}

int main(void) {
  int scenario;
  __CPROVER_assume(scenario >= 0 && scenario <= 3);

  g_copy_gate = 0;
  g_floor = 0;
  g_lo_top = 8;
  g_lo_brk = 12;
  g_lo_alive = 1;
  g_raw_low = 8;
  g_raw_high = 12;
  g_raw_wrap_low = 8;
  g_raw_live_spans = 1;
  g_stack_break = 7;
  g_source_pins = 0;
  g_satb_active = 0;
  g_fault = 0;

  if (scenario == 0) {
    /* Scenario 0: Wrap raises floor above lower span [8..12) so post-wrap
     * stack growth cannot enter [0..13). */
    int wrapped = try_wrap_single_section();
    assert(wrapped == 1);
    assert(g_floor >= g_lo_brk);
    assert(g_stack_break == CAP);
  } else if (scenario == 1) {
    /* Scenario 1: Concurrent SATB major GC active -> MUST refuse wrap! */
    g_satb_active = 1;
    int wrapped = try_wrap_single_section();
    assert(wrapped == 0);
    assert(g_stack_break == 7);
  } else if (scenario == 2) {
    /* Scenario 2: Active cross-section source_pins > 0 -> MUST refuse wrap! */
    g_source_pins = 1;
    int wrapped = try_wrap_single_section();
    assert(wrapped == 0);
    assert(g_stack_break == 7);
  } else {
    /* Scenario 3: Wrap succeeds, upper span published, then check floor
     * restoration with live lower span vs concurrent stealer consuming lower span. */
    int wrapped = try_wrap_single_section();
    assert(wrapped == 1);
    /* Publish an upper span at [60..64) above floor=13 */
    g_raw_wrap_low = 60;
    g_raw_high = 64;
    g_raw_live_spans = 2;

    /* Consuming something else (NOT the lower span) MUST NOT lower floor below lo_brk! */
    try_restore_floor_after_consume(0);
    if (g_lo_alive) {
      assert(g_floor >= g_lo_brk);
    }

    /* Sibling stealer consumes the lower span concurrently */
    __CPROVER_ASYNC_1: sibling_stealer_consume_lower();
    try_restore_floor_after_consume(0);
    if (try_acquire_gate()) {
      if (g_lo_alive) {
        assert(g_floor >= g_lo_brk);
      }
      release_gate();
    }
  }

  return 0;
}
