/*
 * CBMC --mm pso verification harness for Phase C42 `(gambit fiber)` hardening:
 *   1. Cross-scheduler `tx-fast`/`rx-fast` exchange-cancel routing via `%wake-fk!`
 *      (preserving exact quiescence `completed == spawned` on BOTH schedulers).
 *   2. Sequentially consistent Dekker recv-park (`STLR rxw` + `LDAR head/seq`) vs
 *      sender-push (`STLR seq` + `LDAR rxw`) under PSO store buffers (0 lost wakeups).
 *   3. Lock-synchronized unbuffered (`cap == 0`) `fiber-try-recv!` visibility.
 *   4. Closed-nursery (`state == 2`) spawn rejection guard.
 *
 * Negative mutants (all 4 must FAIL with VERIFICATION FAILED):
 *   -DINJECT_BUG_FOREIGN_EXCHANGE_CANCEL_LOCAL_LIFO : routes foreign fk to local sched
 *   -DINJECT_BUG_RECV_DEKKER_RELAXED_HEAD           : omits seq_cst fence before head/seq load
 *   -DINJECT_BUG_UNBUF_TRY_RECV_STALE_MISS          : unbuffered try-recv misses parked sender
 *   -DINJECT_BUG_NURSERY_ALLOW_SPAWN_AFTER_CLOSE    : allows spawn into closed nursery
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

/* 1. Dekker buffered channel state (under PSO store buffers!) */
static int ch_seq;          /* 0 = empty, 1 = item published */
static int ch_rxw;          /* 0 = no waiter, 1 = receiver parked */
static int sender_saw_rxw;
static int recv_saw_seq;
static int t1_done;

/* 2. Cross-scheduler quiescence state */
static int spawnedA, completedA;
static int spawnedB, completedB;

/* 3. Unbuffered channel state */
static int unbuf_lock;
static int unbuf_swq_head;  /* 0 = empty, 42 = parked sender payload */
static int unbuf_got;

/* 4. Nursery lifecycle state: 0=live, 1=cancelled, 2=closed */
static int nursery_state;
static int nursery_active;

static void dekker_sender_thread(void) {
  /* Publish seq[idx] = 1 with seq_cst, then load rxw with seq_cst */
  ch_seq = 1;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  sender_saw_rxw = ch_rxw;

  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  __CPROVER_atomic_begin();
  t1_done = 1;
  __CPROVER_atomic_end();
}

static void wake_fk(int caller_sched, int fk_owner_sched) {
#ifdef INJECT_BUG_FOREIGN_EXCHANGE_CANCEL_LOCAL_LIFO
  /* Buggy: pushes foreign fk onto caller's own scheduler LIFO! */
  (void)fk_owner_sched;
  if (caller_sched == 0) completedA++;
  else completedB++;
#else
  /* Fixed: %wake-fk! always routes fk to its owning %fk-sched */
  (void)caller_sched;
  if (fk_owner_sched == 0) completedA++;
  else completedB++;
#endif
}

static bool nursery_try_spawn(void) {
#ifdef INJECT_BUG_NURSERY_ALLOW_SPAWN_AFTER_CLOSE
  nursery_active++;
  return true;
#else
  if (nursery_state == 2) {
    return false;
  }
  nursery_active++;
  return true;
#endif
}

int main(void) {
  /* --- Test 1: Dekker seq_cst under PSO store buffers --- */
  ch_seq = 0;
  ch_rxw = 0;
  sender_saw_rxw = 0;
  recv_saw_seq = 0;
  t1_done = 0;

  __CPROVER_ASYNC_1: dekker_sender_thread();

  /* Receiver publishes rxw = 1, then re-checks head & seq */
  ch_rxw = 1;
#ifndef INJECT_BUG_RECV_DEKKER_RELAXED_HEAD
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#endif
  recv_saw_seq = ch_seq;

  int done = 0;
  __CPROVER_atomic_begin();
  done = t1_done;
  __CPROVER_atomic_end();
  if (done) {
    /* Zero lost wakeups: at least one side MUST observe the other! */
    assert(sender_saw_rxw == 1 || recv_saw_seq == 1);
  }

  /* --- Test 2: Cross-scheduler exchange-cancel routing --- */
  spawnedA = 1; completedA = 0;
  spawnedB = 1; completedB = 0;
  /* Sender already woke fkA on sched A */
  wake_fk(0, 0);
  /* Worker on sched A cancels rx-fast and extracts foreign fkB (owner=1) */
  wake_fk(0, 1);
  assert(completedA == spawnedA);
  assert(completedB == spawnedB);

  /* --- Test 3: Unbuffered try-recv linearizability --- */
  unbuf_lock = 0;
  unbuf_swq_head = 42;
  unbuf_got = 0;
#ifdef INJECT_BUG_UNBUF_TRY_RECV_STALE_MISS
  /* Buggy: unsynchronized relaxed pre-check misses parked sender */
  unbuf_got = 0;
#else
  /* Fixed: lock-synchronized check observes parked sender 42 */
  __CPROVER_atomic_begin();
  if (unbuf_swq_head != 0) {
    unbuf_got = unbuf_swq_head;
    unbuf_swq_head = 0;
  }
  __CPROVER_atomic_end();
#endif
  assert(unbuf_got == 42);

  /* --- Test 4: Closed nursery rejects spawn & stays active == 0 --- */
  nursery_state = 2; /* closed */
  nursery_active = 0;
  bool spawned = nursery_try_spawn();
  assert(!spawned);
  assert(nursery_active == 0);

  return 0;
}
