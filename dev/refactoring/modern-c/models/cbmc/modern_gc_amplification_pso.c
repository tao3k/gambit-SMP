/*
 * modern_gc_amplification_pso.c
 *
 * CBMC --mm pso weak-memory verification harness for Post-Phase A/B/C Structural Amplification:
 *   Contract A (OCaml-5 Opportunistic STW-Spin Major Slice):
 *     Fast core executes bounded major slice during STW_ENTERING, clears spin_active with
 *     release fence before signaling arrived; coordinator observes arrived && !spin_active
 *     with acquire fence before flipping major color epoch.
 *     Mutant: -DMUTANT_MISSING_SPIN_FENCE=1 drops spin_active check/fence -> ASSERT FAIL!
 *
 *   Contract B (LXR Line Reuse Epoch Counter under PSO):
 *     Recycler bumps line_epoch (odd = recycling, even = new epoch) with release fences
 *     around payload overwrite; remset scanner validates epoch before & after payload read.
 *     Mutant: -DMUTANT_NO_LINE_EPOCH_CHECK=1 skips post-read epoch check -> stale remset
 *     observes torn/new-epoch payload -> ASSERT FAIL!
 *
 *   Contract C (Lock-Free Per-Processor Still-Word Delta Flush):
 *     Two processors flush local still_words_delta to global_still_words atomically instead
 *     of taking global ALLOC_MEM_LOCK().
 *     Mutant: -DMUTANT_NONATOMIC_STILL_DELTA=1 uses non-atomic RMW -> lost update -> ASSERT FAIL!
 */

#include <assert.h>

#ifndef MUTANT_MISSING_SPIN_FENCE
#define MUTANT_MISSING_SPIN_FENCE 0
#endif

#ifndef MUTANT_NO_LINE_EPOCH_CHECK
#define MUTANT_NO_LINE_EPOCH_CHECK 0
#endif

#ifndef MUTANT_NONATOMIC_STILL_DELTA
#define MUTANT_NONATOMIC_STILL_DELTA 0
#endif

static void full_fence(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

/* ========================================================================= */
/* Contract A: Opportunistic STW-Spin Major Slice vs STW Phase Flip          */
/* ========================================================================= */
static int stw_phase = 1;       /* 1 = ENTERING, 2 = FLIPPED */
static int spin_active = 1;     /* Worker 1 starts in opportunistic major slice */
static int fast_ready = 0;
static int mark_color_epoch = 1;
static int a_w1_done = 0;
static int a_w2_done = 0;

static void contract_a_fast_core(void) {
  /* Fast core executes bounded slice reading mark_color_epoch */
  int seen_epoch = mark_color_epoch;
  assert(seen_epoch == 1);
#if !MUTANT_MISSING_SPIN_FENCE
  full_fence();
  spin_active = 0;
  full_fence();
  fast_ready = 1;
#else
  /* Buggy: signals ready before exiting spin slice and without fence! */
  fast_ready = 1;
  int seen_again = mark_color_epoch;
  assert(seen_again == 1);
  spin_active = 0;
#endif
  full_fence();
  a_w1_done = 1;
}

static void contract_a_coordinator(void) {
#if !MUTANT_MISSING_SPIN_FENCE
  __CPROVER_assume(fast_ready == 1 && spin_active == 0);
  full_fence();
#else
  __CPROVER_assume(fast_ready == 1);
#endif
  /* Coordinator flips STW phase & rotates VCGC mark color epoch */
  stw_phase = 2;
  mark_color_epoch = 2;
  full_fence();
  a_w2_done = 1;
}

/* ========================================================================= */
/* Contract B: LXR Line-Reuse Epoch Counter vs Concurrent Remset Scan        */
/* ========================================================================= */
static int line_epoch = 2;     /* even = stable, odd = recycling */
static int line_payload = 10;  /* epoch 2 payload = 10, epoch 4 payload = 20 */
static int b_w1_done = 0;
static int b_w2_done = 0;

static void contract_b_recycler(void) {
  /* Transition line from epoch 2 -> 3 (recycling) -> overwrite -> 4 (reused) */
  line_epoch = 3;
  full_fence();
  line_payload = 20;
  full_fence();
  line_epoch = 4;
  full_fence();
  b_w1_done = 1;
}

static void contract_b_remset_scanner(void) {
  /* Stale remset entry recorded for epoch 2 */
  int recorded_epoch = 2;
  int e1 = line_epoch;
  if (e1 == recorded_epoch) {
    full_fence();
    int val = line_payload;
#if !MUTANT_NO_LINE_EPOCH_CHECK
    full_fence();
    int e2 = line_epoch;
    if (e2 == recorded_epoch) {
      /* Validated epoch 2 payload MUST be 10, never new-epoch 20! */
      assert(val == 10);
    }
#else
    /* Buggy: skips post-read epoch validation -> observes recycled payload 20! */
    assert(val == 10);
#endif
  }
  full_fence();
  b_w2_done = 1;
}

/* ========================================================================= */
/* Contract C: Lock-Free Per-Processor Still-Word Delta Flush                */
/* ========================================================================= */
static int global_still_words = 100;
static int c_w1_done = 0;
static int c_w2_done = 0;

static void atomic_add_still(int delta) {
  full_fence();
  __CPROVER_atomic_begin();
  global_still_words += delta;
  __CPROVER_atomic_end();
  full_fence();
}

static void contract_c_proc1(void) {
#if !MUTANT_NONATOMIC_STILL_DELTA
  atomic_add_still(-30);
#else
  int tmp = global_still_words;
  global_still_words = tmp - 30;
#endif
  full_fence();
  c_w1_done = 1;
}

static void contract_c_proc2(void) {
#if !MUTANT_NONATOMIC_STILL_DELTA
  atomic_add_still(-20);
#else
  int tmp = global_still_words;
  global_still_words = tmp - 20;
#endif
  full_fence();
  c_w2_done = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: contract_a_fast_core();
  __CPROVER_ASYNC_2: contract_a_coordinator();
  __CPROVER_ASYNC_3: contract_b_recycler();
  __CPROVER_ASYNC_4: contract_b_remset_scanner();
  __CPROVER_ASYNC_5: contract_c_proc1();
  __CPROVER_ASYNC_6: contract_c_proc2();

  __CPROVER_assume(a_w1_done && a_w2_done && b_w1_done && b_w2_done && c_w1_done && c_w2_done);
  full_fence();

  assert(stw_phase == 2 && mark_color_epoch == 2 && spin_active == 0);
  assert(line_epoch == 4 && line_payload == 20);
  assert(global_still_words == 50);
  return 0;
}
