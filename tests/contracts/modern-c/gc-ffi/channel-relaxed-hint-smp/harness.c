/*
 * CBMC (--mm pso) Adversarial Weak-Memory Verification Harness for Phase C7:
 *   1. Relaxed Empty/Full Channel Hint + Authoritative Spinlock Re-Check
 *   2. Spinlock Acquire/Release Payload Visibility Under PSO
 *   3. Owner-Only Single-Writer Release Store on Sharded Quiescence Counters
 *
 * Negative Mutants (4/4 must FAIL assertion when enabled):
 *   -DINJECT_BUG_SKIP_LOCKED_RECHECK    : trusts relaxed empty hint without locked re-check -> lost wakeup!
 *   -DINJECT_BUG_UNLOCK_RELAXED         : omits release fence on spinlock unlock -> consumer sees stale payload!
 *   -DINJECT_BUG_OWNER_STORE_NO_RELEASE : omits release fence on owner-only spawned0 = cur + 1 -> PSO false quiescence!
 *   -DINJECT_BUG_DOUBLE_CONSUME_SLOT    : fails to decrement count on buffered recv -> duplicate consumption!
 */

#include <assert.h>
#include <stdint.h>

static inline void release_fence(void) {
  __CPROVER_fence("WWfence", "RWfence");
}

static inline void acquire_fence(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

static inline void full_fence(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

/* Channel state (cap = 1) */
static volatile int ch_lock = 0;
static volatile int ch_count = 0;
static volatile int ch_slot = 0;
static volatile int recv_parked = 0;
static volatile int recv_woken = 0;
static volatile int recv_val = 0;
static volatile int prod_done = 0;
static volatile int cons_done = 0;

static void spin_lock(void) {
  __CPROVER_atomic_begin();
  __CPROVER_assume(ch_lock == 0);
  ch_lock = 1;
  __CPROVER_atomic_end();
  acquire_fence();
}

static void spin_unlock(void) {
#ifndef INJECT_BUG_UNLOCK_RELAXED
  release_fence();
#endif
  ch_lock = 0;
}

static void producer_send_42(void) {
  spin_lock();
  if (recv_parked == 1) {
    recv_parked = 0;
    spin_unlock();
    recv_val = 42;
    release_fence();
    recv_woken = 1;
  } else {
    ch_slot = 42;
    ch_count = 1;
    spin_unlock();
  }
  release_fence();
  prod_done = 1;
}

static void consumer_recv_hinted(void) {
  /* Relaxed empty hint (0 atomics!) */
  int hint_empty = (ch_count == 0);
  if (hint_empty) {
    spin_lock();
#ifdef INJECT_BUG_SKIP_LOCKED_RECHECK
    /* Buggy: skips authoritative count > 0 re-check under lock! */
    recv_parked = 1;
    spin_unlock();
#else
    if (ch_count > 0) {
      int item = ch_slot;
#ifndef INJECT_BUG_DOUBLE_CONSUME_SLOT
      ch_count = 0;
#endif
      spin_unlock();
      recv_val = item;
      recv_woken = 1;
    } else {
      recv_parked = 1;
      spin_unlock();
    }
#endif
  } else {
    spin_lock();
    if (ch_count > 0) {
      int item = ch_slot;
#ifndef INJECT_BUG_DOUBLE_CONSUME_SLOT
      ch_count = 0;
#endif
      spin_unlock();
      recv_val = item;
      recv_woken = 1;
    } else {
      recv_parked = 1;
      spin_unlock();
    }
  }
  release_fence();
  cons_done = 1;
}

/* Part B: Owner-only single-writer release store vs concurrent quiescence scanner */
static volatile int spawned0 = 1;
static volatile int completed0 = 0;
static volatile int completed1 = 0;
static volatile int child_pub = 0;
static volatile int root_ok = 0;
static volatile int child_ok = 0;
static volatile int w1_ok = 0;
static volatile int w2_ok = 0;
static int false_quiescent = 0;

static void w0_owner_spawn(void) {
  /* Owner-only single-writer increment: plain load + add + release store! */
  int cur = spawned0;
  spawned0 = cur + 1;
#ifndef INJECT_BUG_OWNER_STORE_NO_RELEASE
  release_fence();
#endif
  child_pub = 1;
  root_ok = 1;
  release_fence();
  completed0 = 1;
}

static void w1_steal(void) {
  if (child_pub == 1) {
    acquire_fence();
    child_ok = 1;
    release_fence();
    completed1 = 1;
  }
  release_fence();
  w1_ok = 1;
}

static void w2_scan(void) {
  int c = completed0 + completed1;
  full_fence();
  int s = spawned0;
  if (c == s && !(root_ok == 1 && child_ok == 1)) {
    false_quiescent = 1;
  }
  release_fence();
  w2_ok = 1;
}

int main(void) {
  /* Test A: Relaxed hint + spinlock payload visibility under PSO */
  __CPROVER_ASYNC_1: consumer_recv_hinted();
  producer_send_42();
  __CPROVER_assume(cons_done == 1);
  acquire_fence();

  /* Zero lost wakeup: either consumer got item immediately or producer woke it! */
  assert(recv_woken == 1 || ch_count == 1);
  if (recv_woken == 1) {
    assert(recv_val == 42);
    assert(ch_count == 0);
  }
  assert(!(recv_parked == 1 && prod_done == 1 && recv_woken == 0));

  /* Test B: Owner-only release store quiescence under PSO */
  __CPROVER_ASYNC_2: w1_steal();
  __CPROVER_ASYNC_3: w2_scan();
  w0_owner_spawn();
  __CPROVER_assume(w1_ok == 1 && w2_ok == 1);
  acquire_fence();
  assert(false_quiescent == 0);

  return 0;
}
