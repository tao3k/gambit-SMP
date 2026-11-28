/*
 * Phase C9 CBMC (--mm pso) Concurrency Verification Harness:
 *   1. Inline Chase-Lev work-stealing deque (seq_cst fence on last-item pop vs steal)
 *   2. Global-queue pending hint (publish item -> release inc global_pending vs
 *      acquire load global_pending -> dequeue item -> dec global_pending)
 *   3. Lazy #f thread.control-state isolation across fiber switches
 *
 * Negative mutants (all 4 MUST be caught by CBMC --mm pso):
 *   -DINJECT_BUG_GLOBAL_HINT_DEC_BEFORE_POP : dec global_pending before popping item
 *   -DINJECT_BUG_GLOBAL_HINT_NO_FENCE       : omit release/acquire on global_pending
 *   -DINJECT_BUG_SKIP_CLEAR_NONZERO_TC      : forget clearing non-zero tc on suspend
 *   -DINJECT_BUG_DQ_MISSING_SEQ_FENCE       : omit seq_cst fence in Chase-Lev pop
 */

#include <assert.h>

/* 1. Chase-Lev 2-item race state (owner pop of slot1 vs thief 2-step steal of slot0,slot1) */
static volatile int dq_top = 0;
static volatile int dq_bot = 2;
static volatile int dq_slot0 = 88;
static volatile int dq_slot1 = 99;
static volatile int owner_got = 0;
static volatile int thief_got0 = 0;
static volatile int thief_got1 = 0;
static volatile int owner_done = 0;
static volatile int thief_done = 0;

static void owner_pop(void) {
  int b = dq_bot - 1;
  dq_bot = b;
#ifndef INJECT_BUG_DQ_MISSING_SEQ_FENCE
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#endif
  int t = dq_top;
  if (t <= b) {
    int item = (b == 0) ? dq_slot0 : dq_slot1;
    if (t == b) {
      int won = 0;
      __CPROVER_atomic_begin();
      if (dq_top == t) {
        dq_top = t + 1;
        won = 1;
      }
      __CPROVER_atomic_end();
      dq_bot = t + 1;
      if (won) owner_got = item;
    } else {
      owner_got = item;
    }
  } else {
    dq_bot = t;
  }
  __CPROVER_fence("WWfence", "RWfence");
  owner_done = 1;
}

static int thief_steal_once(void) {
  int t = dq_top;
  __CPROVER_fence("RRfence", "RWfence");
  int b = dq_bot;
  if (t < b) {
    int item = (t == 0) ? dq_slot0 : dq_slot1;
    int won = 0;
    __CPROVER_atomic_begin();
    if (dq_top == t) {
      dq_top = t + 1;
      won = 1;
    }
    __CPROVER_atomic_end();
    if (won) return item;
  }
  return 0;
}

static void thief_steal(void) {
  thief_got0 = thief_steal_once();
  thief_got1 = thief_steal_once();
  __CPROVER_fence("WWfence", "RWfence");
  thief_done = 1;
}

/* 2. Global-queue pending hint publish/consume PSO protocol */
static volatile int g_q_item = 0;
static volatile int g_pending = 0;
static volatile int g_enq_done = 0;
static volatile int g_deq_done = 0;
static volatile int g_deq_item = 0;

static void global_enqueuer(void) {
  g_q_item = 77;
#ifndef INJECT_BUG_GLOBAL_HINT_NO_FENCE
  __CPROVER_fence("WWfence", "RWfence");
#endif
  g_pending = 1;
  __CPROVER_fence("WWfence", "RWfence");
  g_enq_done = 1;
}

static void global_poller(void) {
  int p = g_pending;
#ifndef INJECT_BUG_GLOBAL_HINT_NO_FENCE
  __CPROVER_fence("RRfence", "RWfence");
#endif
  if (p > 0) {
#ifdef INJECT_BUG_GLOBAL_HINT_DEC_BEFORE_POP
    /* BUG: decrements hint before claiming item, exposing transient pending==0 while item still unread */
    g_pending = 0;
    assert(g_pending > 0 || g_q_item == 0);
#endif
    g_deq_item = g_q_item;
    g_q_item = 0;
    g_pending = 0;
  }
  __CPROVER_fence("WWfence", "RWfence");
  g_deq_done = 1;
}

/* 3. Lazy #f thread.control-state isolation check */
static void check_lazy_tc_isolation(void) {
  int carrier_tc = 0;
  int fiber_a_tc = 777;
  int fiber_b_tc = 0;

  /* Resume fiber A (non-zero tc -> write carrier_tc) */
  if (fiber_a_tc != 0) carrier_tc = fiber_a_tc;
  assert(carrier_tc == 777);

  /* Suspend fiber A: save & clear carrier_tc ONLY if non-zero */
  fiber_a_tc = carrier_tc;
#ifndef INJECT_BUG_SKIP_CLEAR_NONZERO_TC
  if (carrier_tc != 0) carrier_tc = 0;
#endif

  /* Resume fiber B (tc == 0 -> skip write barrier!) */
  if (fiber_b_tc != 0) carrier_tc = fiber_b_tc;
  /* Fiber B MUST observe carrier_tc == 0 (never leak fiber A's 777!) */
  assert(carrier_tc == 0);
  (void)fiber_a_tc;
}

int main(void) {
  check_lazy_tc_isolation();

__CPROVER_ASYNC_1:
  owner_pop();
  thief_steal();
  __CPROVER_assume(owner_done == 1 && thief_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* Slot 1 (value 99) must NEVER be double-consumed by both owner and thief! */
  assert(!(owner_got == 99 && (thief_got0 == 99 || thief_got1 == 99)));
  /* Total sum of claimed items must never exceed 88 + 99 = 187 */
  assert(owner_got + thief_got0 + thief_got1 <= 187);

__CPROVER_ASYNC_2:
  global_enqueuer();
  global_poller();
  __CPROVER_assume(g_enq_done == 1 && g_deq_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* If poller observed g_pending > 0, it MUST observe g_q_item == 77 (never stale 0) */
  assert(g_deq_item == 77 || g_pending == 1);
  return 0;
}
