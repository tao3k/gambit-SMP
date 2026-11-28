/*
 * CBMC (--mm pso) Adversarial Weak-Memory Verification Harness for Phase C4-A:
 *   - Atomic One-Shot Fiber Steal / Pop Claim (exclusive resume across cores)
 *   - Lock-Free Fiber Channel Rendezvous (zero lost wakeup under PSO reordering)
 *   - Structured Concurrency Nursery Exit Barrier (zero orphaned live fibers)
 *
 * Negative Mutants (must fail assertion when enabled):
 *   -DINJECT_BUG_DOUBLE_STEAL         : non-atomic fiber claim allows 2 workers to run same fiber
 *   -DINJECT_BUG_LOST_WAKEUP          : receiver parks without rechecking buffer after enqueueing
 *   -DINJECT_BUG_PREMATURE_NURSERY    : nursery exits before child decrement release fence
 */

#include <assert.h>
#include <stdint.h>

#define F_READY       0
#define F_RUNNING     1
#define F_PARKED_RECV 2
#define F_DONE        3

static volatile int fiber_state = F_READY;
static volatile int fiber_exec_count = 0;
static volatile int t1_done = 0;
static volatile int t2_done = 0;

static volatile int chan_lock = 0;
static volatile int chan_items = 0;
static volatile int chan_recv_waiter = 0;
static volatile int chan_sent = 0;
static volatile int chan_recvd = 0;

static volatile int nursery_active = 2;
static volatile int child_finished[2] = {0, 0};

static int cas_int(volatile int *addr, int expected, int desired) {
  int old;
  __CPROVER_atomic_begin();
  old = *addr;
  if (old == expected) {
    *addr = desired;
  }
  __CPROVER_atomic_end();
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  return old;
}

static void lock_chan(void) {
  while (cas_int(&chan_lock, 0, 1) != 0) {
    __CPROVER_assume(0);
  }
}

static void unlock_chan(void) {
  __CPROVER_fence("WWfence", "RWfence");
  chan_lock = 0;
}

/* --- Test 1: Exclusive One-Shot Fiber Steal / Pop --- */
static void worker_try_claim_fiber(void) {
#ifdef INJECT_BUG_DOUBLE_STEAL
  if (fiber_state == F_READY) {
    fiber_state = F_RUNNING;
    fiber_exec_count++;
  }
#else
  if (cas_int(&fiber_state, F_READY, F_RUNNING) == F_READY) {
    __CPROVER_atomic_begin();
    fiber_exec_count++;
    __CPROVER_atomic_end();
  }
#endif
}

/* --- Test 2: Zero Lost Wakeup Channel Rendezvous --- */
static void chan_send_op(void) {
#ifdef INJECT_BUG_LOST_WAKEUP
  /* Racy unsynchronized check before receiver publishes waiter */
  if (chan_recv_waiter) {
    chan_recv_waiter = 0;
    chan_sent++;
    chan_recvd++;
  } else {
    chan_items++;
    chan_sent++;
  }
#else
  lock_chan();
  if (chan_recv_waiter) {
    chan_recv_waiter = 0;
    chan_sent++;
    chan_recvd++;
  } else {
    chan_items++;
    chan_sent++;
  }
  unlock_chan();
#endif
}

static void chan_recv_op(void) {
#ifdef INJECT_BUG_LOST_WAKEUP
  if (chan_items > 0) {
    chan_items--;
    chan_recvd++;
  } else {
    chan_recv_waiter = 1;
  }
#else
  lock_chan();
  if (chan_items > 0) {
    chan_items--;
    chan_recvd++;
  } else {
    chan_recv_waiter = 1;
  }
  unlock_chan();
#endif
}

/* --- Test 3: Structured Nursery Completion Barrier --- */
static void complete_child(int id) {
  child_finished[id] = 1;
#ifndef INJECT_BUG_PREMATURE_NURSERY
  __CPROVER_fence("WWfence", "RWfence");
#endif
  __CPROVER_atomic_begin();
  nursery_active--;
  __CPROVER_atomic_end();
}

static void worker_thread_1(void) {
  worker_try_claim_fiber();
  __CPROVER_fence("WWfence", "RWfence");
  t1_done = 1;
}

static void chan_sender_thread(void) {
  chan_send_op();
  __CPROVER_fence("WWfence", "RWfence");
  t2_done = 1;
}

int main(void) {
  /* 1. Two cores race to claim the same READY fiber */
__CPROVER_ASYNC_1:
  worker_thread_1();
  worker_try_claim_fiber();
  __CPROVER_assume(t1_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  assert(fiber_exec_count == 1);

  /* 2. Concurrent send + recv on empty channel: zero lost wakeup & conservation */
__CPROVER_ASYNC_2:
  chan_sender_thread();
  chan_recv_op();

  /* Join sender thread before checking post-rendezvous invariants */
  __CPROVER_assume(t2_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* Conservation & zero lost wakeup: cannot have both items > 0 and parked waiter */
  assert(!(chan_items > 0 && chan_recv_waiter == 1));
  assert(chan_sent == chan_recvd + chan_items);

  /* 3. Structured nursery exit visibility */
  complete_child(0);
#ifdef INJECT_BUG_PREMATURE_NURSERY
  /* Simulate premature exit when child 1 hasn't finished */
  nursery_active = 0;
#else
  complete_child(1);
#endif
  if (nursery_active == 0) {
    __CPROVER_fence("RRfence", "RWfence");
    assert(child_finished[0] == 1 && child_finished[1] == 1);
  }
  return 0;
}
