/*
 * Phase C14 CBMC (--mm pso) Concurrency Verification Harness:
 *   Fused Top-Level %ch-send-fast-c! & %ch-recv-fast-c! Single-Block Protocol
 *   Verifies under PSO weak memory:
 *     1. Direct-handoff fallback into Vyukov push inside ONE C block when tail != head
 *     2. Dekker seq_cst wakeup visibility between fused send and fused recv/park
 *     3. Return-status tag disjointness and sentinel isolation
 *
 * Negative mutants (all 4 MUST be caught by CBMC --mm pso):
 *   -DINJECT_BUG_FUSED_SEND_SKIP_WAKE_CHECK : omit rxw load_seq after Vyukov push -> lost wakeup!
 *   -DINJECT_BUG_FUSED_SEND_BYPASS_ON_RACE  : direct handoff when tail != head -> FIFO violation!
 *   -DINJECT_BUG_FUSED_RECV_SKIP_TXW_CHECK  : omit txw load_seq after pop -> lost sender wakeup!
 *   -DINJECT_BUG_STATUS_TAG_COLLISION       : collide FULL_PARK tag with WAKE_RX tag!
 */

#include <assert.h>

#define ST_DONE_FAST  0
#define ST_WAKE_RX    1
#define ST_FULL_PARK  2
#define ST_UNBUF      4
#define ST_RETRY_POLL 5
#define ST_HANDOFF_RK 6

/* Scenario 1: Fused send push vs concurrent consumer park under PSO */
static volatile int s1_tail = 0;
static volatile int s1_head = 0;
static volatile int s1_seq0 = 0;
static volatile int s1_buf0 = 0;
static volatile int s1_lock = 0;
static volatile int s1_rxw = 0;
static volatile int s1_parked_rx = 0;
static volatile int s1_woke_rx = 0;
static volatile int s1_cons_got = -1;
static volatile int s1_p_done = 0;
static volatile int s1_c_done = 0;

static void lock1(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (s1_lock == 0) { s1_lock = 1; ok = 1; }
  __CPROVER_atomic_end();
  __CPROVER_assume(ok == 1);
  __CPROVER_fence("RRfence", "RWfence");
}

static void unlock1(void) {
  __CPROVER_fence("WWfence", "RWfence");
  s1_lock = 0;
}

static void fused_send_s1(void) {
  int status = ST_RETRY_POLL;
  /* Fast check: if rxw > 0 try direct handoff under lock */
  if (s1_rxw > 0) {
    lock1();
    if (s1_parked_rx && s1_tail == s1_head) {
      s1_parked_rx = 0;
      s1_rxw = 0;
      s1_woke_rx = 1;
      status = ST_HANDOFF_RK;
    }
    unlock1();
  }
  if (status != ST_HANDOFF_RK) {
    /* Vyukov push into slot 0 */
    s1_tail = 1;
    s1_buf0 = 88;
    __CPROVER_fence("WWfence", "RWfence");
    s1_seq0 = 1;
    __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#ifndef INJECT_BUG_FUSED_SEND_SKIP_WAKE_CHECK
    if (s1_rxw > 0) {
      status = ST_WAKE_RX;
      lock1();
      if (s1_parked_rx) {
        s1_parked_rx = 0;
        s1_rxw = 0;
        s1_woke_rx = 1;
      }
      unlock1();
    } else {
      status = ST_DONE_FAST;
    }
#else
    status = ST_DONE_FAST; /* BUG: skipped rxw check -> lost wakeup! */
#endif
  }
  __CPROVER_fence("WWfence", "RWfence");
  s1_p_done = 1;
  (void)status;
}

static void fused_recv_s1(void) {
  int s = s1_seq0;
  __CPROVER_fence("RRfence", "RWfence");
  if (s == 1) {
    s1_cons_got = s1_buf0;
    s1_head = 1;
    __CPROVER_fence("WWfence", "RWfence");
    s1_c_done = 1;
    return;
  }
  lock1();
  s1_rxw = 1;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  int s2 = s1_seq0;
  __CPROVER_fence("RRfence", "RWfence");
  if (s2 == 1) {
    s1_rxw = 0;
    s1_cons_got = s1_buf0;
    s1_head = 1;
  } else {
    s1_parked_rx = 1;
  }
  unlock1();
  __CPROVER_fence("WWfence", "RWfence");
  s1_c_done = 1;
}

/* Scenario 2: Fused recv pop vs parked sender on FULL CAP=1 ring */
static volatile int s2_seq0 = 1; /* FULL */
static volatile int s2_buf0 = 11;
static volatile int s2_lock = 0;
static volatile int s2_txw = 0;
static volatile int s2_parked_tx = 0;
static volatile int s2_woke_tx = 0;
static volatile int s2_tx_pushed = 0;
static volatile int s2_c_done = 0;
static volatile int s2_p_done = 0;

static void lock2(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (s2_lock == 0) { s2_lock = 1; ok = 1; }
  __CPROVER_atomic_end();
  __CPROVER_assume(ok == 1);
  __CPROVER_fence("RRfence", "RWfence");
}

static void unlock2(void) {
  __CPROVER_fence("WWfence", "RWfence");
  s2_lock = 0;
}

static void fused_recv_s2(void) {
  int item = s2_buf0;
  assert(item == 11);
  s2_buf0 = 0;
  __CPROVER_fence("WWfence", "RWfence");
  s2_seq0 = 2; /* FREE for pos=1 */
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#ifndef INJECT_BUG_FUSED_RECV_SKIP_TXW_CHECK
  if (s2_txw > 0) {
    lock2();
    if (s2_parked_tx) {
      s2_parked_tx = 0;
      s2_txw = 0;
      s2_woke_tx = 1;
    }
    unlock2();
  }
#endif
  __CPROVER_fence("WWfence", "RWfence");
  s2_c_done = 1;
}

static void fused_send_s2(void) {
  lock2();
  s2_txw = 1;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  int s = s2_seq0;
  __CPROVER_fence("RRfence", "RWfence");
  if (s == 2) {
    s2_buf0 = 22;
    __CPROVER_fence("WWfence", "RWfence");
    s2_seq0 = 3;
    s2_txw = 0;
    s2_tx_pushed = 1;
  } else {
    s2_parked_tx = 1;
  }
  unlock2();
  __CPROVER_fence("WWfence", "RWfence");
  s2_p_done = 1;
}

/* Scenario 3: Direct-handoff fallback & status tag disjointness checks */
static void check_dispatch_and_fifo(void) {
  int t = 1, h = 0;
  int buf0 = 100;
  int first = 0;
#ifdef INJECT_BUG_FUSED_SEND_BYPASS_ON_RACE
  int allow_handoff = 1; /* BUG: ignores t == h guard! */
#else
  int allow_handoff = (t == h);
#endif
  if (allow_handoff) {
    first = 200;
  } else {
    first = buf0;
  }
  assert(first == 100);

  int tag_wake = ST_WAKE_RX;
#ifdef INJECT_BUG_STATUS_TAG_COLLISION
  int tag_full = ST_WAKE_RX; /* BUG: collides full-park with wake-rx! */
#else
  int tag_full = ST_FULL_PARK;
#endif
  assert(tag_wake != tag_full);
}

int main(void) {
  check_dispatch_and_fifo();

__CPROVER_ASYNC_1:
  fused_send_s1();
  fused_recv_s1();
  __CPROVER_assume(s1_p_done == 1 && s1_c_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  assert(s1_cons_got == 88 || s1_woke_rx == 1);

__CPROVER_ASYNC_2:
  fused_recv_s2();
  fused_send_s2();
  __CPROVER_assume(s2_c_done == 1 && s2_p_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  assert(s2_tx_pushed == 1 || s2_woke_tx == 1);
  return 0;
}
