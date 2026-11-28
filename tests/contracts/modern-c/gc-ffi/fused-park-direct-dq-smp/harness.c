/*
 * Phase C12 CBMC (--mm pso) Concurrency Verification Harness:
 *   1. Fused C23 %ch-park-send-c! vs %vyukov-try-pop-c! on FULL CAP=1 ring (PSO Dekker)
 *   2. Fused C23 %ch-park-recv-c! lock-release ordering under PSO
 *   3. Empty-deque LIFO-streak bypass anti-starvation check
 *   4. SATB write barrier completeness on rk.val inside %ch-try-direct-handoff-c!
 *
 * Negative mutants (all 4 MUST be caught by CBMC --mm pso):
 *   -DINJECT_BUG_PARK_SEND_NO_DEKKER_FENCE    : omit seq_cst ordering in fused park-send
 *   -DINJECT_BUG_LIFO_BYPASS_IGNORES_NONEMPTY_DQ: allow LIFO at streak==8 when dq_len > 0
 *   -DINJECT_BUG_HANDOFF_VAL_NO_SATB          : omit SATB barrier on rk.val store
 *   -DINJECT_BUG_PARK_RECV_NO_UNLOCK_RELEASE  : omit release fence on wait-lock unlock
 */

#include <assert.h>

/* 1. Fused park-send vs pop on FULL CAP=1 ring (tail=1, head=0, seq0=1, buf0=10) */
static volatile int g_seq0 = 1; /* 2*0 + 1 => FULL with item 10 */
static volatile int g_buf0 = 10;
static volatile int g_lock = 0;
static volatile int g_txw = 0;
static volatile int g_parked_tx = 0;
static volatile int g_woke_tx = 0;
static volatile int g_tx_pushed = 0;
static volatile int g_cons_done = 0;
static volatile int g_prod_done = 0;

static void spin_lock(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (g_lock == 0) { g_lock = 1; ok = 1; }
  __CPROVER_atomic_end();
  __CPROVER_assume(ok == 1);
  __CPROVER_fence("RRfence", "RWfence");
}

static void spin_unlock(void) {
#ifndef INJECT_BUG_PARK_RECV_NO_UNLOCK_RELEASE
  __CPROVER_fence("WWfence", "RWfence");
#endif
  g_lock = 0;
}

static void consumer_pop_cap1(void) {
  /* Pop item 10 from slot 0, advance seq0 = 2*(0+1) = 2 (FREE for pos=1!) */
  int item = g_buf0;
  assert(item == 10);
  g_buf0 = 0;
  __CPROVER_fence("WWfence", "RWfence");
  g_seq0 = 2;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  if (g_txw > 0) {
    spin_lock();
    if (g_parked_tx) {
      g_parked_tx = 0;
      g_txw = 0;
      g_woke_tx = 1;
    }
    spin_unlock();
  }
  __CPROVER_fence("WWfence", "RWfence");
  g_cons_done = 1;
}

static void producer_fused_park_send_cap1(void) {
  /* Fast check sees g_seq0 == 1 != 2*1 -> FULL, enters fused park-send */
  spin_lock();
  g_txw = 1;
#ifndef INJECT_BUG_PARK_SEND_NO_DEKKER_FENCE
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#endif
  int s = g_seq0;
  __CPROVER_fence("RRfence", "RWfence");
  if (s == 2) {
    /* Slot became free! Push item 20 immediately & do not park */
    g_buf0 = 20;
    __CPROVER_fence("WWfence", "RWfence");
    g_seq0 = 3;
    g_txw = 0;
    g_tx_pushed = 1;
  } else {
    g_parked_tx = 1;
  }
  spin_unlock();
  __CPROVER_fence("WWfence", "RWfence");
  g_prod_done = 1;
}

/* 2. Park-recv unlock release visibility check under PSO */
static volatile int g_rwq_head = 0;
static volatile int g_rx_lock = 0;
static volatile int g_rx_park_done = 0;
static volatile int g_rx_wake_done = 0;
static volatile int g_rx_seen = -1;

static void park_recv_thread(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (g_rx_lock == 0) { g_rx_lock = 1; ok = 1; }
  __CPROVER_atomic_end();
  __CPROVER_assume(ok == 1);
  g_rwq_head = 42;
#ifndef INJECT_BUG_PARK_RECV_NO_UNLOCK_RELEASE
  __CPROVER_fence("WWfence", "RWfence");
#endif
  g_rx_lock = 0;
  __CPROVER_fence("WWfence", "RWfence");
  g_rx_park_done = 1;
}

static void wake_recv_thread(void) {
  /* Acquire lock ONLY AFTER park_recv_thread released it */
  __CPROVER_assume(g_rx_park_done == 1);
  int ok = 0;
  __CPROVER_atomic_begin();
  if (g_rx_lock == 0) { g_rx_lock = 1; ok = 1; }
  __CPROVER_atomic_end();
  __CPROVER_assume(ok == 1);
  __CPROVER_fence("RRfence", "RWfence");
  g_rx_seen = g_rwq_head;
  g_rx_lock = 0;
  __CPROVER_fence("WWfence", "RWfence");
  g_rx_wake_done = 1;
}

/* 3. Empty-deque LIFO-streak bypass anti-starvation check */
static void check_lifo_bypass(void) {
  int streak = 8;
  int dq_len = 1; /* sibling waiting in local deque! */
#ifdef INJECT_BUG_LIFO_BYPASS_IGNORES_NONEMPTY_DQ
  int allow_lifo = 1; /* BUG: starves waiting sibling! */
#else
  int allow_lifo = (streak < 8) || (dq_len == 0);
#endif
  assert(allow_lifo == 0);
}

/* 4. SATB write barrier on rk.val inside fused %ch-try-direct-handoff-c! */
static void check_handoff_val_satb(void) {
  int satb_active = 1;
  int rk_old_val = 999;
  int shaded = 0;
#ifndef INJECT_BUG_HANDOFF_VAL_NO_SATB
  if (satb_active && rk_old_val != 0) shaded = rk_old_val;
#endif
  rk_old_val = 1000;
  assert(shaded == 999);
  (void)rk_old_val;
}

int main(void) {
  check_lifo_bypass();
  check_handoff_val_satb();

__CPROVER_ASYNC_1:
  consumer_pop_cap1();
  producer_fused_park_send_cap1();
  __CPROVER_assume(g_cons_done == 1 && g_prod_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* Either producer pushed item 20 directly OR consumer woke parked producer! */
  assert(g_tx_pushed == 1 || g_woke_tx == 1);

__CPROVER_ASYNC_2:
  park_recv_thread();
  wake_recv_thread();
  __CPROVER_assume(g_rx_park_done == 1 && g_rx_wake_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* Waker acquiring lock after parker unlocked MUST see g_rwq_head == 42! */
  assert(g_rx_seen == 42);
  return 0;
}
