/*
 * slice4_gerbil_inline_lock_pso.c
 *
 * CBMC --mm pso weak-memory verification harness for Slice 4:
 *   Gerbil SMP single-slot atomic owner CAS inline lock (__lock-inline! / __unlock-inline!).
 *
 * Verifies under Partial Store Order (PSO / ARM64 weak memory):
 *   1. Single-slot atomic CAS (USE_SINGLE_SLOT_CAS=1):
 *      - Strict mutual exclusion between threads 1 and 2,
 *      - Contending thread NEVER observes owner == 0 (no #f dereference in macro-thread-end-condvar!),
 *      - Release-ordered owner-checked CAS unlock publishes critical-section writes cleanly.
 *   2. Upstream 2-slot mutant (USE_SINGLE_SLOT_CAS=0):
 *      - Thread 1 acquires flag (slot 0) via CAS and writes owner (slot 1) separately;
 *        Thread 2 observes flag == 1 with owner == 0 -> ASSERTION FAILURE (mutant killed!).
 */

#include <assert.h>

#ifndef USE_SINGLE_SLOT_CAS
#define USE_SINGLE_SLOT_CAS 1
#endif

static int lock_slot = 0;   /* 0 = unlocked, 1/2 = owning thread id */
static int owner_slot = 0;  /* legacy 2nd slot (used when USE_SINGLE_SLOT_CAS=0) */
static int shared_cs_data = 0;
static int in_cs = 0;
static int t1_entered = 0;
static int t1_done = 0;
static int t2_done = 0;

static int cas_lock_val(int expected, int desired) {
  int prev;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  __CPROVER_atomic_begin();
  prev = lock_slot;
  if (prev == expected) {
    lock_slot = desired;
  }
  __CPROVER_atomic_end();
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  return prev;
}

static void worker1(void) {
#if USE_SINGLE_SLOT_CAS
  int prev = cas_lock_val(0, 1);
  if (prev == 0) {
    in_cs++;
    assert(in_cs == 1);
    shared_cs_data = 42;
    t1_entered = 1;
    in_cs--;
    int u_prev = cas_lock_val(1, 0);
    assert(u_prev == 1);
  }
#else
  int prev = cas_lock_val(0, 1);
  if (prev == 0) {
    /* Upstream 2-slot window: lock_slot is 1 while owner_slot is still 0 (#f)! */
    owner_slot = 1;
    shared_cs_data = 42;
    owner_slot = 0;
    (void)cas_lock_val(1, 0);
  }
#endif
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  t1_done = 1;
}

static void worker2(void) {
#if USE_SINGLE_SLOT_CAS
  int prev = cas_lock_val(0, 2);
  if (prev == 0) {
    in_cs++;
    assert(in_cs == 1);
    if (t1_entered) {
      assert(shared_cs_data == 42);
    }
    in_cs--;
    int u_prev = cas_lock_val(2, 0);
    assert(u_prev == 2);
  } else {
    /* Contended CAS returns exact non-zero owner atomically: never #f! */
    assert(prev == 1);
  }
#else
  int prev = cas_lock_val(0, 1);
  if (prev != 0) {
    /* Contended thread reads separate slot 1 -> observes 0 (#f) -> crashes macro-thread-end-condvar! */
    int seen_owner = owner_slot;
    assert(seen_owner != 0);
  }
#endif
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  t2_done = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: worker1();
  __CPROVER_ASYNC_2: worker2();
  __CPROVER_assume(t1_done == 1 && t2_done == 1);
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  assert(lock_slot == 0);
  return 0;
}
