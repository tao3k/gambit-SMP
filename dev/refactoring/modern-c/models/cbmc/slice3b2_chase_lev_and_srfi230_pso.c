/*
 * CBMC Weak-Memory (PSO / ARM64) Verification Harness for Slice 3B-2:
 *   1. Chase-Lev Work-Stealing Deque (Le et al., PPoPP 2013):
 *      Verifies Dekker seq_cst fence between owner pop_bottom() and thief steal()
 *      on a 1-element deque (exact-once execution: zero duplicate, zero lost task).
 *      Mutant 1 (-DUSE_CHASE_LEV_SEQ_CST=0) omits the seq_cst fence and MUST FAIL!
 *   2. SRFI-230 GC-Barriered Pointer Atomic Exchange & Card Barrier:
 *      Verifies that concurrent atomic-box-set! using atomic_exchange never drops
 *      an overwritten mature pointer from Yuasa SATB, and always dirties the
 *      generational card before publishing a young pointer.
 *      Mutant 2 (-DUSE_ATOMIC_EXCHANGE_SATB=0) uses racy load+shade+store -> MUST FAIL!
 *      Mutant 3 (-DUSE_CARD_BARRIER=0) omits generational card mark -> MUST FAIL!
 *
 * Safe check:
 *   cbmc --mm pso -DUSE_CHASE_LEV_SEQ_CST=1 -DUSE_ATOMIC_EXCHANGE_SATB=1 -DUSE_CARD_BARRIER=1 \
 *     --bounds-check --signed-overflow-check --unsigned-overflow-check \
 *     dev/refactoring/modern-c/models/cbmc/slice3b2_chase_lev_and_srfi230_pso.c
 *
 * Mutant killers (each MUST fail verification!):
 *   ! cbmc --mm pso -DUSE_CHASE_LEV_SEQ_CST=0 -DUSE_ATOMIC_EXCHANGE_SATB=1 -DUSE_CARD_BARRIER=1 ...
 *   ! cbmc --mm pso -DUSE_CHASE_LEV_SEQ_CST=1 -DUSE_ATOMIC_EXCHANGE_SATB=0 -DUSE_CARD_BARRIER=1 ...
 *   ! cbmc --mm pso -DUSE_CHASE_LEV_SEQ_CST=1 -DUSE_ATOMIC_EXCHANGE_SATB=1 -DUSE_CARD_BARRIER=0 ...
 */

#include <assert.h>
#include <stdint.h>

extern uint64_t __VERIFIER_nondet_uint64(void);

#ifndef USE_CHASE_LEV_SEQ_CST
#define USE_CHASE_LEV_SEQ_CST 1
#endif

#ifndef USE_ATOMIC_EXCHANGE_SATB
#define USE_ATOMIC_EXCHANGE_SATB 1
#endif

#ifndef USE_CARD_BARRIER
#define USE_CARD_BARRIER 1
#endif

/* ========================================================================= */
/* Part 1: Chase-Lev Work-Stealing Deque Last-Item Dekker Race under PSO     */
/* ========================================================================= */

static int cl_top;
static int cl_bottom;
static int cl_buf[2];
static int owner_got;
static int thief1_got;
static int thief2_got;

static int atomic_cas_int(int *addr, int expected, int desired)
{
  int ok = 0;
  __CPROVER_atomic_begin();
  if (*addr == expected) {
    *addr = desired;
    ok = 1;
  }
  __CPROVER_atomic_end();
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  return ok;
}

static void cl_owner_pop(void)
{
  int b = cl_bottom - 1;
  cl_bottom = b;
#if USE_CHASE_LEV_SEQ_CST
  /* Le et al. PPoPP 2013 critical Store-Load seq_cst fence */
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#endif
  int t = cl_top;
  if (t <= b) {
    int x = cl_buf[b & 1];
    if (t == b) {
      if (!atomic_cas_int(&cl_top, t, t + 1)) {
        x = 0; /* lost to thief */
      }
      cl_bottom = b + 1;
    }
    owner_got = x;
  } else {
    cl_bottom = b + 1;
    owner_got = 0;
  }
}

static void cl_thief_steal(int *out)
{
  int t = cl_top;
#if USE_CHASE_LEV_SEQ_CST
  /* Le et al. PPoPP 2013 critical seq_cst fence */
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#endif
  int b = cl_bottom;
  if (t < b) {
    int x = cl_buf[t & 1];
    if (atomic_cas_int(&cl_top, t, t + 1)) {
      *out = x;
    } else {
      *out = 0;
    }
  } else {
    *out = 0;
  }
}

/* ========================================================================= */
/* Part 2: SRFI-230 Atomic Box Concurrent Exchange SATB + Card Barrier       */
/* ========================================================================= */

/* Mature object IDs: 1, 2; Young object ID: 100; Immediate: 0 */
static int box_slot;
static int card_dirty;
static int satb_shaded[3]; /* tracks whether mature object 1 or 2 was SATB-shaded */
static int w1_done;
static int w2_done;

static void satb_shade(int obj)
{
  if (obj == 1 || obj == 2) {
    __CPROVER_atomic_begin();
    satb_shaded[obj] = 1;
    __CPROVER_atomic_end();
  }
}

static int atomic_exchange_int(int *addr, int desired)
{
  int prev;
  __CPROVER_atomic_begin();
  prev = *addr;
  *addr = desired;
  __CPROVER_atomic_end();
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  return prev;
}

static void srfi230_box_set(int new_val)
{
#if USE_CARD_BARRIER
  if (new_val >= 100) {
    __CPROVER_atomic_begin();
    card_dirty = 1;
    __CPROVER_atomic_end();
    __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  }
#endif
#if USE_ATOMIC_EXCHANGE_SATB
  /* OCaml-5 / SRFI-230 sound pattern: atomic_exchange returns exact overwritten
   * value to the exact overwriting thread -> zero SATB edge loss under races. */
  int old = atomic_exchange_int(&box_slot, new_val);
  satb_shade(old);
#else
  /* BUGGY shortcut: separate load + shade + store races with concurrent writers! */
  int old = box_slot;
  satb_shade(old);
  box_slot = new_val;
#endif
}

int main(void)
{
  /* ----------------------------------------------------------------------- */
  /* Test 1: Chase-Lev 2-item pop_bottom vs 2 concurrent thieves under PSO   */
  /* (Le et al. PPoPP 2013 canonical Store-Load duplicate-execution bug!)    */
  /* ----------------------------------------------------------------------- */
  cl_top = 0;
  cl_bottom = 2;
  cl_buf[0] = 10;
  cl_buf[1] = 20;
  owner_got = -1;
  thief1_got = -1;
  thief2_got = -1;

  __CPROVER_ASYNC_1: cl_owner_pop();
  __CPROVER_ASYNC_2: cl_thief_steal(&thief1_got);
  __CPROVER_ASYNC_3: cl_thief_steal(&thief2_got);

  __CPROVER_assume(owner_got != -1 && thief1_got != -1 && thief2_got != -1);

  /* No task (10 or 20) may EVER be taken more than once! */
  int c10 = (owner_got == 10) + (thief1_got == 10) + (thief2_got == 10);
  int c20 = (owner_got == 20) + (thief1_got == 20) + (thief2_got == 20);
  assert(c10 <= 1);
  assert(c20 <= 1);
  /* Whenever deque drained to empty (cl_top >= cl_bottom), both tasks were taken! */
  if (cl_top >= cl_bottom) {
    assert(c10 == 1 && c20 == 1);
  }

  /* ----------------------------------------------------------------------- */
  /* Test 2: SRFI-230 concurrent atomic-box-set! SATB + Card completeness    */
  /* ----------------------------------------------------------------------- */
  box_slot = 1; /* initially holds mature object 1 */
  card_dirty = 0;
  satb_shaded[0] = 0;
  satb_shaded[1] = 0;
  satb_shaded[2] = 0;

  w1_done = 0;
  w2_done = 0;

  /* Thread 1 writes mature object 2; Thread 2 writes young object 100.
   * Whichever writer overwrites 1 or 2 MUST have SATB-shaded it, AND if
   * box_slot ends up holding young 100, card_dirty MUST be 1! */
  __CPROVER_ASYNC_4: { srfi230_box_set(2); __CPROVER_atomic_begin(); w1_done = 1; __CPROVER_atomic_end(); }
  __CPROVER_ASYNC_5: { srfi230_box_set(100); __CPROVER_atomic_begin(); w2_done = 1; __CPROVER_atomic_end(); }

  __CPROVER_assume(w1_done == 1 && w2_done == 1);

  /* Every mature object (1 and 2) that is no longer in box_slot MUST be SATB-shaded! */
  if (box_slot != 1)
    assert(satb_shaded[1] == 1);
  if (box_slot != 2)
    assert(satb_shaded[2] == 1);
  /* If box_slot holds young object 100, generational card MUST be dirty! */
  if (box_slot >= 100)
    assert(card_dirty == 1);

  /* ----------------------------------------------------------------------- */
  /* Test 3: SRFI-230 fixnum tagged-word arithmetic preserves 00 tag bits    */
  /* ----------------------------------------------------------------------- */
  uint64_t a = __VERIFIER_nondet_uint64() & ~3ULL;
  uint64_t b = __VERIFIER_nondet_uint64() & ~3ULL;
  assert(((a + b) & 3ULL) == 0ULL);
  assert(((a - b) & 3ULL) == 0ULL);
  assert(((a & b) & 3ULL) == 0ULL);
  assert(((a | b) & 3ULL) == 0ULL);
  assert(((a ^ b) & 3ULL) == 0ULL);

  return 0;
}
