/*
 * Phase C13 CBMC (--mm pso) Concurrency Verification Harness:
 *   1. Tokio-style SPSC-push + MPMC-FIFO CAS(head) owner-pop vs thief steal_batch(2)
 *   2. PSO store-store visibility on owner SPSC push -> thief steal_batch
 *   3. Per-worker batched nursery completion flush (zero deadlock, zero overflush)
 *
 * Negative mutants (all 4 MUST be caught by CBMC --mm pso):
 *   -DINJECT_BUG_OWNER_POP_WITHOUT_CAS   : owner pops without CASing head -> double-consume!
 *   -DINJECT_BUG_PUSH_NO_RELEASE_TAIL    : owner stores buf[idx] & tail without release fence
 *   -DINJECT_BUG_NURSERY_FORGET_IDLE_FLUSH: worker goes idle without flushing private batch
 *   -DINJECT_BUG_NURSERY_OVERFLUSH       : flushes batch+1 instead of batch -> premature zero!
 */

#include <assert.h>

/* Scenario 1: Owner-pop vs Thief steal_batch(2) on 3 pre-filled slots */
static volatile int q_head = 0;
static volatile int q_tail = 3;
static volatile int q_buf0 = 10;
static volatile int q_buf1 = 20;
static volatile int q_buf2 = 30;
static volatile int owner_item = 0;
static volatile int thief_item0 = 0;
static volatile int thief_item1 = 0;
static volatile int s1_owner_done = 0;
static volatile int s1_thief_done = 0;

static int read_q_slot(int idx) {
  if (idx == 0) return q_buf0;
  if (idx == 1) return q_buf1;
  return q_buf2;
}

static void owner_pop_fifo(void) {
  int h = q_head;
  __CPROVER_fence("RRfence", "RWfence");
  if (h < q_tail) {
    int item = read_q_slot(h);
#ifdef INJECT_BUG_OWNER_POP_WITHOUT_CAS
    /* BUG: claims slot h without CASing q_head -> races with thief steal_batch! */
    owner_item = item;
#else
    int won = 0;
    __CPROVER_atomic_begin();
    if (q_head == h) {
      q_head = h + 1;
      won = 1;
    }
    __CPROVER_atomic_end();
    if (won) owner_item = item;
#endif
  }
  __CPROVER_fence("WWfence", "RWfence");
  s1_owner_done = 1;
}

static void thief_steal_batch2(void) {
  int h = q_head;
  __CPROVER_fence("RRfence", "RWfence");
  int t = q_tail;
  int avail = t - h;
  if (avail >= 2) {
    int i0 = read_q_slot(h);
    int i1 = read_q_slot(h + 1);
    int won = 0;
    __CPROVER_atomic_begin();
    if (q_head == h) {
      q_head = h + 2;
      won = 1;
    }
    __CPROVER_atomic_end();
    if (won) {
      thief_item0 = i0;
      thief_item1 = i1;
    }
  }
  __CPROVER_fence("WWfence", "RWfence");
  s1_thief_done = 1;
}

/* Scenario 2: Owner SPSC push -> Thief steal PSO release/acquire visibility */
static volatile int p_head = 0;
static volatile int p_tail = 0;
static volatile int p_buf0 = 0;
static volatile int p_push_done = 0;
static volatile int p_steal_done = 0;
static volatile int p_stolen_val = -1;

static void spsc_pusher(void) {
  p_buf0 = 55;
#ifndef INJECT_BUG_PUSH_NO_RELEASE_TAIL
  __CPROVER_fence("WWfence", "RWfence");
#endif
  p_tail = 1;
  __CPROVER_fence("WWfence", "RWfence");
  p_push_done = 1;
}

static void spsc_stealer(void) {
  int h = p_head;
  int t = p_tail;
#ifndef INJECT_BUG_PUSH_NO_RELEASE_TAIL
  __CPROVER_fence("RRfence", "RWfence");
#endif
  if (h < t) {
    int v = p_buf0;
    int won = 0;
    __CPROVER_atomic_begin();
    if (p_head == h) {
      p_head = h + 1;
      won = 1;
    }
    __CPROVER_atomic_end();
    if (won) p_stolen_val = v;
  }
  __CPROVER_fence("WWfence", "RWfence");
  p_steal_done = 1;
}

/* Scenario 3: Batched nursery completion flush (zero deadlock & zero overflush) */
static void check_batched_nursery(void) {
  int nursery_active = 2; /* 2 children (parent already exited) */
  int live_children = 2;
  int w0_batch = 0;

  /* Child 1 completes on W0 -> accumulated privately */
  live_children--;
  w0_batch++;

#ifdef INJECT_BUG_NURSERY_OVERFLUSH
  /* BUG: overflushes batch+1 while child 2 is still live -> premature active == 0! */
  nursery_active -= (w0_batch + 1);
  w0_batch = 0;
  assert(!(nursery_active == 0 && live_children > 0));
#endif

  /* Child 2 completes on W0 -> accumulated privately (batch=2) */
  live_children--;
  w0_batch++;

  /* W0 reaches idle boundary -> MUST flush w0_batch to wake parked parent! */
#ifndef INJECT_BUG_NURSERY_FORGET_IDLE_FLUSH
  if (w0_batch > 0) {
    nursery_active -= w0_batch;
    w0_batch = 0;
  }
#endif
  /* Once all children completed and worker is idle, nursery_active MUST be 0! */
  assert(live_children == 0 && nursery_active == 0);
}

int main(void) {
  check_batched_nursery();

__CPROVER_ASYNC_1:
  owner_pop_fifo();
  thief_steal_batch2();
  __CPROVER_assume(s1_owner_done == 1 && s1_thief_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* Zero double-consume between owner_pop and thief_steal_batch2! */
  assert(owner_item == 0 || (owner_item != thief_item0 && owner_item != thief_item1));

__CPROVER_ASYNC_2:
  spsc_pusher();
  spsc_stealer();
  __CPROVER_assume(p_push_done == 1 && p_steal_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* If stealer claimed slot 0, it MUST observe payload 55 (never stale 0 under PSO!) */
  assert(p_stolen_val == -1 || p_stolen_val == 55);
  return 0;
}
