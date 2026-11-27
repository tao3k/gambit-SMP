/*
 * Phase C8 CBMC (--mm pso) Concurrency Verification Harness:
 *   Lock-Free Vyukov Bounded MPMC Ring + Dekker Waiter Protocol +
 *   Linearizable Direct Handoff + Per-Carrier %fiber-k Freelist Recycling
 *
 * Uses scalar ring slots (g_seq0/g_seq1, g_buf0/g_buf1) so CBMC --mm pso
 * explores full store-buffer (WW & WR) reorderings across all slots and
 * waiter counters!
 *
 * Negative mutants (all 4 MUST be caught by CBMC --mm pso):
 *   -DINJECT_BUG_DEKKER_NO_FENCE           : omit seq_cst fence before waiter check
 *   -DINJECT_BUG_SKIP_PARK_RECHECK         : omit ring re-check after waiter inc
 *   -DINJECT_BUG_DIRECT_HANDOFF_BYPASS_RING: handoff without verifying tail == head
 *   -DINJECT_BUG_FK_RECYCLE_WITHOUT_CLEAR  : push fk to pool without clearing raw_k
 */

#include <assert.h>

#define CAP 2

/* Vyukov ring state (scalar slots for full PSO partial-order modeling) */
static volatile int g_tail = 0;
static volatile int g_head = 0;
static volatile int g_seq0 = 0;
static volatile int g_seq1 = 1;
static volatile int g_buf0 = 0;
static volatile int g_buf1 = 0;

/* Waiter protocol state */
static volatile int g_wait_lock = 0;
static volatile int g_recv_waiters = 0;
static volatile int g_parked_rx = 0;
static volatile int g_handoff_val = 0;
static volatile int g_woke_rx = 0;

/* Observed delivery log */
static volatile int g_prod_done = 0;
static volatile int g_cons_done = 0;
static volatile int g_cons_got = 0;

/* %fiber-k freelist node state */
static volatile int g_fk_in_pool = 0;
static volatile int g_fk_raw_k = 1;

static void spin_lock(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (g_wait_lock == 0) {
    g_wait_lock = 1;
    ok = 1;
  }
  __CPROVER_atomic_end();
  __CPROVER_assume(ok == 1);
  __CPROVER_fence("RRfence", "RWfence");
}

static void spin_unlock(void) {
  __CPROVER_fence("WWfence", "RWfence");
  g_wait_lock = 0;
}

static int vyukov_try_push(int val) {
  int pos = g_tail;
  int idx = pos & (CAP - 1);
  int s = (idx == 0) ? g_seq0 : g_seq1;
  __CPROVER_fence("RRfence", "RWfence");
  if (s != pos) {
    return 0;
  }
  int cas_ok = 0;
  __CPROVER_atomic_begin();
  if (g_tail == pos) {
    g_tail = pos + 1;
    cas_ok = 1;
  }
  __CPROVER_atomic_end();
  if (!cas_ok) {
    return 0;
  }
  if (idx == 0) {
    g_buf0 = val;
  } else {
    g_buf1 = val;
  }
#ifndef INJECT_BUG_DEKKER_NO_FENCE
  __CPROVER_fence("WWfence", "RWfence");
#endif
  if (idx == 0) {
    g_seq0 = pos + 1;
  } else {
    g_seq1 = pos + 1;
  }
#ifndef INJECT_BUG_DEKKER_NO_FENCE
  /* seq_cst fence orders seq[idx] publish before reading g_recv_waiters */
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#endif
  return 1;
}

static int vyukov_try_pop(void) {
  int pos = g_head;
  int idx = pos & (CAP - 1);
  int s = (idx == 0) ? g_seq0 : g_seq1;
  __CPROVER_fence("RRfence", "RWfence");
  if (s != pos + 1) {
    return 0;
  }
  int cas_ok = 0;
  __CPROVER_atomic_begin();
  if (g_head == pos) {
    g_head = pos + 1;
    cas_ok = 1;
  }
  __CPROVER_atomic_end();
  if (!cas_ok) {
    return 0;
  }
  int item;
  if (idx == 0) {
    item = g_buf0;
    g_buf0 = 0;
  } else {
    item = g_buf1;
    g_buf1 = 0;
  }
  __CPROVER_fence("WWfence", "RWfence");
  if (idx == 0) {
    g_seq0 = pos + CAP;
  } else {
    g_seq1 = pos + CAP;
  }
  return item;
}

/* Scenario 1: Concurrent Producer & Consumer Dekker zero-lost-wakeup test */
static void producer_thread(void) {
  int pushed = vyukov_try_push(42);
  assert(pushed == 1);
  if (g_recv_waiters > 0) {
    spin_lock();
    if (g_parked_rx) {
      int item = vyukov_try_pop();
      g_parked_rx = 0;
      g_recv_waiters = 0;
      g_handoff_val = item;
      g_woke_rx = 1;
    }
    spin_unlock();
  }
  g_prod_done = 1;
}

static void consumer_thread(void) {
  int item = vyukov_try_pop();
  if (item != 0) {
    g_cons_got = item;
    g_cons_done = 1;
    return;
  }
  /* Slow path: park with Dekker seq_cst increment + authoritative ring re-check */
  spin_lock();
  g_recv_waiters = 1;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#ifndef INJECT_BUG_SKIP_PARK_RECHECK
  item = vyukov_try_pop();
  if (item != 0) {
    g_recv_waiters = 0;
    spin_unlock();
    g_cons_got = item;
    g_cons_done = 1;
    return;
  }
#endif
  g_parked_rx = 1;
  spin_unlock();
  g_cons_done = 1;
}

/* Scenario 2: Linearizable direct handoff FIFO check (item 1 buffered, item 2 arrives) */
static void check_direct_handoff_fifo(void) {
  int r_head = 0;
  int r_tail = 1; /* item 1 already buffered at slot 0! */
  int r_buf0 = 100;
  int r_buf1 = 0;
  int first_delivered = 0;

  int can_direct_handoff = (r_tail == r_head);
#ifdef INJECT_BUG_DIRECT_HANDOFF_BYPASS_RING
  can_direct_handoff = 1; /* BUG: bypasses buffered item 100! */
#endif
  if (can_direct_handoff) {
    first_delivered = 200;
  } else {
    r_buf1 = 200;
    r_tail = 2;
    first_delivered = r_buf0;
    r_head = 1;
  }
  assert(first_delivered == 100);
  (void)r_buf1;
  (void)r_head;
}

/* Scenario 3: Per-carrier %fiber-k freelist recycling zero-retention check */
static void check_fk_pool_recycle(void) {
  g_fk_raw_k = 12345;
  g_fk_in_pool = 0;
#ifndef INJECT_BUG_FK_RECYCLE_WITHOUT_CLEAR
  g_fk_raw_k = 0;
#endif
  g_fk_in_pool = 1;
  assert(!(g_fk_in_pool && g_fk_raw_k != 0));
}

int main(void) {
  check_direct_handoff_fifo();
  check_fk_pool_recycle();

__CPROVER_ASYNC_1:
  producer_thread();
  consumer_thread();

  __CPROVER_assume(g_prod_done == 1 && g_cons_done == 1);
  assert(g_cons_got == 42 || (g_woke_rx == 1 && g_handoff_val == 42));
  return 0;
}
