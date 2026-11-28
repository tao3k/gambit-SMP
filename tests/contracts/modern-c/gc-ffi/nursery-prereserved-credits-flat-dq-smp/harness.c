/*
 * Phase C18 CBMC PSO Adversarial Verification Harness:
 *   1. Pre-reserved nursery spawn credit (+32 / local cancel / flush) under concurrent stealing
 *   2. Zero-cons flat dual-array (buf[idx], nbuf[idx]) visibility under PSO release-tail / acquire-tail
 *
 * Negative Mutants (each MUST FAIL under `cbmc --mm pso --unwind 4`):
 *   -DINJECT_BUG_SPAWN_CREDIT_UNDER_RESERVE
 *   -DINJECT_BUG_FORGET_FLUSH_UNUSED_CREDIT
 *   -DINJECT_BUG_FLAT_DQ_NBUF_AFTER_TAIL_STORE
 *   -DINJECT_BUG_FLAT_DQ_NO_RELEASE_TAIL
 */

#include <assert.h>

extern void __CPROVER_fence(const char *kind, ...);
extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_assume(_Bool);

static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence");
}
static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}
static inline void fence_acqrel(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

/* ============================================================================
 * Scenario 1 & 2 Combined under PSO:
 *   Owner spawns 2 nursery children into flat dual-array (buf, nbuf) using
 *   pre-reserved credit (+4 chunk), publishes with release tail, then joins
 *   nursery (flushing unused credit + parent's 1).
 *   Thief concurrently steals from flat dual-array, verifies (buf, nbuf) pair
 *   integrity, and flushes completion credit.
 * ============================================================================ */
static int g_active = 1;    /* parent = 1 */
static int g_buf0 = 0;
static int g_buf1 = 0;
static int g_nbuf0 = 0;     /* nursery ID = 77 */
static int g_nbuf1 = 0;
static int g_head = 0;
static int g_tail = 0;
static int g_premature_zero = 0;
static int g_pair_corrupt = 0;
static int g_owner_done = 0;
static int g_thief_done = 0;
static int g_children_completed = 0;

static void owner_spawn_and_join(void) {
  int credit = 0;

  /* Spawn child 1 (tid=11, nid=77) with pre-reserved credit chunk = 4 */
#ifdef INJECT_BUG_SPAWN_CREDIT_UNDER_RESERVE
  /* BUG: reserves only +1 for 2 children -> thief drives active to 0 early! */
  __CPROVER_atomic_begin(); g_active += 1; __CPROVER_atomic_end();
  credit = 1; /* erroneously thinks it has 1 spare credit */
#else
  __CPROVER_atomic_begin(); g_active += 4; __CPROVER_atomic_end();
  credit = 3; /* consumed 1 of 4 for child 1 */
#endif
  fence_release();

  /* Push child 1 into flat dual-array slot 0 */
  g_buf0 = 11;
#ifdef INJECT_BUG_FLAT_DQ_NBUF_AFTER_TAIL_STORE
  /* BUG: writes nbuf0 AFTER publishing tail -> thief observes nbuf0 == 0! */
  fence_release();
  g_tail = 1;
  g_nbuf0 = 77;
#else
  g_nbuf0 = 77;
#ifndef INJECT_BUG_FLAT_DQ_NO_RELEASE_TAIL
  fence_release();
#endif
  g_tail = 1;
#endif

  /* Spawn child 2 (tid=22, nid=77) using pre-reserved credit (0 atomics!) */
  credit -= 1; /* now credit == 2 (or 0 in buggy mutant) */
  g_buf1 = 22;
  g_nbuf1 = 77;
#ifndef INJECT_BUG_FLAT_DQ_NO_RELEASE_TAIL
  fence_release();
#endif
  g_tail = 2;

  /* Owner tries to pop remaining children locally */
  int tries;
  for (tries = 0; tries < 2; tries++) {
    int h = g_head;
    fence_acquire();
    if (h < 2) {
      int t_val = (h == 0) ? g_buf0 : g_buf1;
      int n_val = (h == 0) ? g_nbuf0 : g_nbuf1;
      int won = 0;
      __CPROVER_atomic_begin();
      if (g_head == h) { g_head = h + 1; won = 1; }
      __CPROVER_atomic_end();
      if (won) {
        fence_acqrel();
        if (t_val == 0 || n_val != 77) g_pair_corrupt = 1;
        __CPROVER_atomic_begin(); g_children_completed += 1; __CPROVER_atomic_end();
        /* Local completion increments credit (0 atomics!) */
        credit += 1;
      }
    }
  }

  /* Parent exits with-nursery body: flush unused credit + parent's 1 */
#ifdef INJECT_BUG_FORGET_FLUSH_UNUSED_CREDIT
  /* BUG: only subtracts parent's 1, leaking unused credit so active never reaches 0! */
  __CPROVER_atomic_begin(); g_active -= 1; __CPROVER_atomic_end();
#else
  int drop = credit + 1;
  credit = 0;
  __CPROVER_atomic_begin(); g_active -= drop; __CPROVER_atomic_end();
#endif

  fence_release();
  g_owner_done = 1;
}

static void thief_steal_and_complete(void) {
  int t = g_tail;
  fence_acquire();
  int h = g_head;
  fence_acquire();
  int thief_credit = 0;

  if (h < t) {
    int t_val = (h == 0) ? g_buf0 : g_buf1;
    int n_val = (h == 0) ? g_nbuf0 : g_nbuf1;
    int won = 0;
    __CPROVER_atomic_begin();
    if (g_head == h) { g_head = h + 1; won = 1; }
    __CPROVER_atomic_end();
    if (won) {
      fence_acqrel();
      if (t_val == 0 || n_val != 77) g_pair_corrupt = 1;
      __CPROVER_atomic_begin(); g_children_completed += 1; __CPROVER_atomic_end();
      thief_credit += 1;
    }
  }

  /* Thief flushes completion credit on idle */
  if (thief_credit > 0) {
    int after;
    int done_cnt;
    __CPROVER_atomic_begin();
    g_active -= thief_credit;
    after = g_active;
    done_cnt = g_children_completed;
    __CPROVER_atomic_end();
    if (after <= 0 && done_cnt < 2) {
      g_premature_zero = 1;
    }
  }

  fence_release();
  g_thief_done = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: thief_steal_and_complete();
  owner_spawn_and_join();
  __CPROVER_assume(g_owner_done == 1 && g_thief_done == 1);
  fence_acquire();

  /* Drain any remaining child not yet popped (modeling continued worker dispatch) */
  while (g_head < 2) {
    int h = g_head;
    int t_val = (h == 0) ? g_buf0 : g_buf1;
    int n_val = (h == 0) ? g_nbuf0 : g_nbuf1;
    if (t_val == 0 || n_val != 77) g_pair_corrupt = 1;
    g_head = h + 1;
    g_children_completed += 1;
    g_active -= 1;
  }

  assert(g_pair_corrupt == 0);
  assert(g_premature_zero == 0);
  assert(g_children_completed == 2);
  assert(g_active == 0);
  return 0;
}
