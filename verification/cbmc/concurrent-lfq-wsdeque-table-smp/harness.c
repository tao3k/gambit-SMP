/*
 * CBMC PSO harness for (gambit concurrent) hardening:
 *   1. lf-queue-try-dequeue! lock-free return on closed segment with unlinked next.
 *   2. Chase-Lev ws-deque-try-pop! Dekker-safe GC slot clearing when t < b racing
 *      with concurrent thief ws-deque-try-steal! under PSO.
 *   3. Non-negative clamped concurrent-table-size under insert/delete race.
 *   4. Overflow-safe %next-pow2 wrap detection.
 *
 * Negative mutants (all 4 MUST fail CBMC):
 *   -DINJECT_BUG_LFQ_SPIN_ON_UNLINKED_NEXT
 *   -DINJECT_BUG_WS_CLEAR_SLOT_WHEN_T_EQ_B
 *   -DINJECT_BUG_TABLE_SIZE_NEGATIVE
 *   -DINJECT_BUG_CONCURRENT_POW2_OVERFLOW
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

extern bool nondet_bool(void);

/* Chase-Lev 2-slot ring (t=0, b=2 initially, items 10 and 20) */
static volatile int ws_top = 0;
static volatile int ws_bot = 2;
static volatile int ws_slot0 = 10;
static volatile int ws_slot1 = 20;
static volatile int thief_result = -1; /* -1 = empty/abort, 0 = BUG cleared, >0 = valid item */
static volatile int owner_result = -1;

static void ws_owner_pop(void) {
  int b = ws_bot - 1;
  ws_bot = b;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  int t = ws_top;
  if (t <= b) {
    int val = (b == 0) ? ws_slot0 : ws_slot1;
    if (t < b) {
      /* Dekker exclusive ownership of slot b: safe to clear for GC! */
      if (b == 0) ws_slot0 = 0; else ws_slot1 = 0;
      owner_result = val;
    } else {
      /* t == b: must race with thief on CAS(ws_top, t -> t+1) */
#ifdef INJECT_BUG_WS_CLEAR_SLOT_WHEN_T_EQ_B
      /* Bug: clearing slot when t == b lets racing thief read 0! */
      if (b == 0) ws_slot0 = 0; else ws_slot1 = 0;
#endif
      int won = 0;
      __CPROVER_atomic_begin();
      if (ws_top == t) {
        ws_top = t + 1;
        won = 1;
      }
      __CPROVER_atomic_end();
      ws_bot = b + 1;
      owner_result = won ? val : -1;
    }
  } else {
    ws_bot = b + 1;
    owner_result = -1;
  }
}

static void ws_thief_steal(void) {
  int t = ws_top;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  int b = ws_bot;
  if (t < b) {
    int val = (t == 0) ? ws_slot0 : ws_slot1;
    int won = 0;
    __CPROVER_atomic_begin();
    if (ws_top == t) {
      ws_top = t + 1;
      won = 1;
    }
    __CPROVER_atomic_end();
    if (won) {
      thief_result = val;
    }
  }
}

static int lfq_try_deq_closed_segment(bool next_linked, int tail_ctr) {
  /* Returns 0 = EMPTY, 1 = RETRY (advance to next), -1 = LIVELOCK */
  if (!next_linked) {
#ifdef INJECT_BUG_LFQ_SPIN_ON_UNLINKED_NEXT
    if (tail_ctr > 256) {
      return -1; /* Pre-C38 livelock spinning on stalled producer */
    }
#endif
    (void)tail_ctr;
    return 0; /* Lock-free EMPTY return */
  }
  return 1;
}

static int ct_read_size(int raw_count) {
#ifdef INJECT_BUG_TABLE_SIZE_NEGATIVE
  return raw_count;
#else
  return (raw_count > 0) ? raw_count : 0;
#endif
}

static int64_t next_pow2_checked(int64_t n) {
  const int64_t MAX_FIX = (1LL << 61) - 1;
  int64_t p = 16;
  for (int step = 0; step < 63; step++) {
    if (p >= n) return p;
    int64_t nxt = p * 2;
#ifndef INJECT_BUG_CONCURRENT_POW2_OVERFLOW
    if (nxt <= p || nxt > MAX_FIX) return -1;
#else
    assert(nxt > p && nxt <= MAX_FIX);
#endif
    p = nxt;
  }
  assert(0 && "next_pow2 infinite loop");
  return -1;
}

int main(void) {
  /* 1. Concurrent Chase-Lev owner pop + thief steal under PSO */
  bool one_item = nondet_bool();
  if (one_item) {
    ws_bot = 1;
  }

  __CPROVER_ASYNC_1:
  {
    ws_thief_steal();
  }
  ws_owner_pop();

  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  /* Thief MUST NEVER observe cleared slot (0) on a successful steal! */
  assert(thief_result != 0);
  /* Owner MUST NEVER observe cleared slot (0) on a successful pop! */
  assert(owner_result != 0);
  /* If both popped/stole, items MUST be distinct (no duplication) */
  if (owner_result > 0 && thief_result > 0) {
    assert(owner_result != thief_result);
  }

  /* 2. lf-queue closed segment with stalled producer (tail_ctr = 257, next = false) */
  int lfq_r = lfq_try_deq_closed_segment(false, 257);
  assert(lfq_r == 0);

  /* 3. concurrent-table-size non-negativity when raw_count transiently dips to -1 */
  assert(ct_read_size(-1) >= 0);
  assert(ct_read_size(0) == 0);
  assert(ct_read_size(5) == 5);

  /* 4. %next-pow2 overflow guard */
  assert(next_pow2_checked(16) == 16);
  assert(next_pow2_checked(17) == 32);
  int64_t over_max_pow2 = (1LL << 60) + 1;
  assert(next_pow2_checked(over_max_pow2) == -1);

  return 0;
}
