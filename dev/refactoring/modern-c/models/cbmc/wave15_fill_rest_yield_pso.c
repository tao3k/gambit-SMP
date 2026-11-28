/*
 * Bounded CBMC (--mm pso) formal verification model for Wave 15 native
 * runtime optimizations:
 *
 *   1. Vectorized / 8-wide homogeneous vector initialization
 *      (___INIT_SCMOBJ_INLINE_FLOAT & ___INIT_SCMOBJ_INLINE):
 *      exact bit-pattern preservation (including IEEE-754 -0.0 vs +0.0),
 *      exact coverage of [0, n) across empty/sub-block/multi-block/tail sizes,
 *      zero guard-slot overrun, and overflow-free loop bounds.
 *   2. Single-load ___rest_hooks_gate + slow-path re-arm + register-cached
 *      fp_cur pair-pop loop in handler_get_rest / handler_get_key_rest:
 *      exact stack-pointer displacement, exact element order, and guaranteed
 *      disarm/observation execution whenever armed or slow-path entered.
 *   3. 4-thread (2 publishers + 1 stealer + 1 yielder) lock-free acquire peek
 *      in SMP ##thread-yield! paired with locked release store in
 *      macro-btq-leftmost-set! under PSO weak memory:
 *      DRF-0 publication visibility (happens-before payload init), safe
 *      locked re-check under concurrent work stealing and multi-producer
 *      btq_leftmost transitions, and zero lost yield for already-published
 *      runnable threads.
 *
 * Baseline verification:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 13 \
 *     dev/refactoring/modern-c/models/cbmc/wave15_fill_rest_yield_pso.c
 *
 * Mutant falsification (5/5 must FAIL with exit code 10):
 *   -DMUTANT_1  (drops -0.0 sign check -> clobbers -0.0 to +0.0)
 *   -DMUTANT_2  (off-by-one fill tail -> leaves final element uninitialized)
 *   -DMUTANT_3  (omits rest_fast=0 on slow path -> skips disarm/note_body)
 *   -DMUTANT_4  (publishes btq_leftmost without release ordering under PSO)
 *   -DMUTANT_5  (skips locked re-check in ##thread-yield! after concurrent steal)
 */

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <assert.h>

extern unsigned int nondet_uint(void);
extern int nondet_int(void);
extern bool nondet_bool(void);
extern void __CPROVER_assume(bool);
extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, ...);

/* =========================================================================
 * Protocol A: 8-wide homogeneous f64vector fill with exact -0.0 handling
 * ========================================================================= */

#define POS_ZERO_BITS UINT64_C(0x0000000000000000)
#define NEG_ZERO_BITS UINT64_C(0x8000000000000000)
#define SENTINEL_BITS UINT64_C(0xDEADBEEFCAFEBABE)

static bool is_positive_zero_bits(uint64_t bits) {
#ifdef MUTANT_1
  /* Bug: treats both +0.0 and -0.0 as zero for memset(0). */
  return (bits & UINT64_C(0x7FFFFFFFFFFFFFFF)) == 0;
#else
  /* Exact equivalent of (f == 0.0 && 1.0/f > 0.0): sign bit must be 0. */
  return bits == POS_ZERO_BITS;
#endif
}

static void init_f64_fill_bits(uint64_t *body, size_t limit, uint64_t f_bits) {
  if (is_positive_zero_bits(f_bits)) {
    for (size_t i = 0; i < limit; i++) {
      body[i] = POS_ZERO_BITS;
    }
  } else {
    size_t i = 0;
    for (; limit - i >= 8; i += 8) {
      body[i]     = f_bits;
      body[i + 1] = f_bits;
      body[i + 2] = f_bits;
      body[i + 3] = f_bits;
      body[i + 4] = f_bits;
      body[i + 5] = f_bits;
      body[i + 6] = f_bits;
      body[i + 7] = f_bits;
    }
#ifdef MUTANT_2
    /* Bug: off-by-one tail leaves final element uninitialized when tail > 0. */
    for (; i + 1 < limit; i++) {
      body[i] = f_bits;
    }
#else
    for (; i < limit; i++) {
      body[i] = f_bits;
    }
#endif
  }
}

static void verify_vector_fill_protocol(void) {
  /* Guarded buffer: [0] is leading guard, [1..10] is body, [11] is tail guard.
   * Covers empty (0), sub-block (1..7), exact 8-wide block (8), and block+tail (9..10). */
  uint64_t buf[12];
  for (size_t k = 0; k < 12; k++) {
    buf[k] = SENTINEL_BITS;
  }

  unsigned int n = nondet_uint();
  __CPROVER_assume(n <= 10);

  unsigned int kind = nondet_uint();
  __CPROVER_assume(kind <= 2);
  uint64_t fill_bits = (kind == 0) ? POS_ZERO_BITS
                     : (kind == 1) ? NEG_ZERO_BITS
                                   : UINT64_C(0x3FF8000000000001);

  uint64_t *body = &buf[1];
  init_f64_fill_bits(body, (size_t)n, fill_bits);

  /* Leading and trailing guard words must never be touched. */
  assert(buf[0] == SENTINEL_BITS);
  for (size_t k = (size_t)n; k < 10; k++) {
    assert(body[k] == SENTINEL_BITS);
  }
  assert(buf[11] == SENTINEL_BITS);

  /* Every element in [0, n) must preserve the exact IEEE-754 bit pattern. */
  for (size_t k = 0; k < (size_t)n; k++) {
    assert(body[k] == fill_bits);
  }
}

/* =========================================================================
 * Protocol B: Single-load ___rest_hooks_gate + fp_cur register-cached pop
 * ========================================================================= */

static void verify_rest_gate_and_fp_cache(void) {
  bool attempt_armed = nondet_bool();
  bool observation_open = nondet_bool();
  bool admission_captured = nondet_bool();
  bool heap_fits_fast = nondet_bool();

  /* Invariant of rest_hooks_gate_refresh(): gate is 0 iff no attempt armed,
   * no observation open, and initial admission has been captured. */
  int rest_hooks_gate = (attempt_armed || observation_open || !admission_captured) ? 1 : 0;
  int rest_attempt_words = attempt_armed ? 8 : 0;

  bool entry_called = false;
  bool disarm_called = false;
  bool note_body_called = false;
  bool fallback_counted = false;

  bool rest_fast = (rest_hooks_gate == 0);
  if (!rest_fast) {
    entry_called = true;
  }

  bool held = false;
  if (!(rest_fast && heap_fits_fast)) {
    /* Slow path entered: must clear rest_fast so attempt/observation hooks run. */
#ifndef MUTANT_3
    rest_fast = false;
#endif
    if (!heap_fits_fast) {
      held = true;
    }
  }

  /* Fallback diagnostic counter check. */
  unsigned int n_rest = nondet_uint();
  __CPROVER_assume(n_rest <= 6);
  if (!rest_fast && (held || rest_attempt_words != 0)) {
    fallback_counted = true;
  }

  /* Register-cached fp_cur pop loop vs direct fp pop equivalence. */
  int stack[8] = {10, 20, 30, 40, 50, 60, 70, 80};
  int *fp_ref = &stack[1];
  int *fp_opt = &stack[1];
  int out_ref[6] = {0};
  int out_opt[6] = {0};

  for (unsigned int k = 0; k < n_rest; k++) {
    out_ref[k] = *fp_ref++;
  }
  {
    int *fp_cur = fp_opt;
    for (unsigned int k = 0; k < n_rest; k++) {
      out_opt[k] = *fp_cur++;
    }
    fp_opt = fp_cur;
  }

  assert(fp_opt == fp_ref);
  for (unsigned int k = 0; k < n_rest; k++) {
    assert(out_opt[k] == out_ref[k]);
  }

  if (!rest_fast) {
    disarm_called = true;
    note_body_called = true;
  }

  /* Safety contracts: */
  if (attempt_armed || observation_open || !admission_captured) {
    assert(entry_called);
    assert(disarm_called);
    assert(note_body_called);
  }
  if (attempt_armed || held) {
    assert(fallback_counted);
    assert(disarm_called);
    assert(note_body_called);
  }
  if (!attempt_armed && !observation_open && admission_captured && heap_fits_fast) {
    /* Fast path executes with zero hook calls and zero fallback counter traffic. */
    assert(!entry_called);
    assert(!disarm_called);
    assert(!note_body_called);
    assert(!fallback_counted);
  }
}

/* =========================================================================
 * Protocol C: 4-thread (2 publishers + 1 stealer + 1 yielder) lock-free
 * acquire peek in SMP ##thread-yield! under PSO weak memory
 * ========================================================================= */

#define PROC_SELF 0
#define THREAD_2  1
#define THREAD_3  2

static int proc_lock = 0;
static int btq_leftmost = PROC_SELF;
static int q2 = 0;
static int q3 = 0;
static int ready2 = 0;
static int ready3 = 0;
static int yield_switched_to = PROC_SELF;

static void publish_thread2(void) {
  __CPROVER_atomic_begin();
  __CPROVER_assume(proc_lock == 0);
  proc_lock = 1;
  __CPROVER_atomic_end();
  __CPROVER_fence("RRfence", "RWfence");

  ready2 = 1;
  q2 = 1;
#ifndef MUTANT_4
  /* Release fence before publishing btq_leftmost (models atomic store_release). */
  __CPROVER_fence("WWfence", "RWfence");
#endif
  btq_leftmost = THREAD_2;

  __CPROVER_fence("WWfence", "RWfence");
  __CPROVER_atomic_begin();
  proc_lock = 0;
  __CPROVER_atomic_end();
}

static void publish_thread3(void) {
  __CPROVER_atomic_begin();
  __CPROVER_assume(proc_lock == 0);
  proc_lock = 1;
  __CPROVER_atomic_end();
  __CPROVER_fence("RRfence", "RWfence");

  ready3 = 1;
  q3 = 1;
  int new_left = q2 ? THREAD_2 : THREAD_3;
#ifndef MUTANT_4
  __CPROVER_fence("WWfence", "RWfence");
#endif
  btq_leftmost = new_left;

  __CPROVER_fence("WWfence", "RWfence");
  __CPROVER_atomic_begin();
  proc_lock = 0;
  __CPROVER_atomic_end();
}

static void stealer_remove_leftmost(void) {
  __CPROVER_atomic_begin();
  __CPROVER_assume(proc_lock == 0);
  proc_lock = 1;
  int cur = btq_leftmost;
  if (cur == THREAD_2) {
    q2 = 0;
    btq_leftmost = q3 ? THREAD_3 : PROC_SELF;
  } else if (cur == THREAD_3) {
    q3 = 0;
    btq_leftmost = q2 ? THREAD_2 : PROC_SELF;
  }
  proc_lock = 0;
  __CPROVER_atomic_end();
}

static void thread_yield_fast(void) {
  /* Lock-free acquire peek of processor->btq_leftmost. */
  int peek = btq_leftmost;
  __CPROVER_fence("RRfence", "RWfence");

  if (peek == PROC_SELF) {
    yield_switched_to = PROC_SELF;
    return;
  }

  /* Release-acquire synchronization must guarantee published thread payload
   * visibility even before acquiring the processor lock under PSO. */
  assert(peek == THREAD_2 || peek == THREAD_3);
  if (peek == THREAD_2) {
    assert(ready2 == 1);
  } else {
    assert(ready3 == 1);
  }

  /* Slow path: acquire processor lock and re-check under lock. */
  __CPROVER_atomic_begin();
  __CPROVER_assume(proc_lock == 0);
  proc_lock = 1;
#ifdef MUTANT_5
  /* Bug: trusts stale lock-free peek without re-checking under lock. */
  int next = peek;
#else
  int next = btq_leftmost;
#endif
  if (next != PROC_SELF) {
    /* Must never schedule an uninitialized or already-stolen thread. */
    assert(next == THREAD_2 || next == THREAD_3);
    assert(btq_leftmost == next);
    if (next == THREAD_2) {
      assert(q2 == 1);
      assert(ready2 == 1);
    } else {
      assert(q3 == 1);
      assert(ready3 == 1);
    }
    yield_switched_to = next;
  } else {
    yield_switched_to = PROC_SELF;
  }
  proc_lock = 0;
  __CPROVER_atomic_end();
}

static void verify_yield_pso_4threads(void) {
  /* 4 distinct concurrent threads under PSO:
   *   Thread 1: Producer A publishes THREAD_2
   *   Thread 2: Producer B publishes THREAD_3
   *   Thread 3: Concurrent work-stealer drains current leftmost
   *   Thread 4 (main): Current processor runs lock-free ##thread-yield! */
  __CPROVER_ASYNC_1: publish_thread2();
  __CPROVER_ASYNC_2: publish_thread3();
  __CPROVER_ASYNC_3: stealer_remove_leftmost();

  thread_yield_fast();
}

static void verify_yield_no_lost_wakeup(void) {
  /* If a runnable thread is already published before ##thread-yield! starts,
   * ##thread-yield! must observe non-empty and switch to it. */
  publish_thread2();
  thread_yield_fast();
  assert(yield_switched_to == THREAD_2);
}

int main(void) {
  /* Partition independent proofs nondeterministically so CBMC checks all 4
   * scenarios exhaustively without cross-coupling sequential writes into the
   * 4-thread PSO partial-order graph. */
  unsigned int mode = nondet_uint();
  __CPROVER_assume(mode <= 3);
  if (mode == 0) {
    verify_vector_fill_protocol();
  } else if (mode == 1) {
    verify_rest_gate_and_fp_cache();
  } else if (mode == 2) {
    verify_yield_no_lost_wakeup();
  } else {
    verify_yield_pso_4threads();
  }
  return 0;
}
