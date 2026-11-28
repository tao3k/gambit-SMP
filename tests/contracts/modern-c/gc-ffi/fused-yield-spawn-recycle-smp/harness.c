/*
 * Phase C16 CBMC PSO Adversarial Verification Harness:
 *   1. Fused fiber-spawn (active++ & spawned++ before release-publish) vs thief
 *   2. Fused yield-push-and-pop (`dq_push` + `CAS(dq.head)`) vs concurrent thief
 *   3. Inline %free-fk-c! extract-before-clear self-yield preservation
 *
 * Negative Mutants (each MUST FAIL under `cbmc --mm pso --unwind 4`):
 *   -DINJECT_BUG_SPAWN_PUBLISH_BEFORE_ACTIVE_INC
 *   -DINJECT_BUG_YIELD_PUSH_NO_RELEASE_TAIL
 *   -DINJECT_BUG_YIELD_POP_WITHOUT_CAS
 *   -DINJECT_BUG_FREE_FK_BEFORE_READ_RAWK
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
 * Scenario 1: Fused fiber-spawn vs concurrent thief stealing & completing
 * ============================================================================ */
static int s1_n_active = 1; /* parent = 1 */
static int s1_spawned = 1;
static int s1_completed = 0;
static int s1_dq_slot0 = 0;
static int s1_dq_tail = 0;
static int s1_dq_head = 0;
static int s1_active_underflow = 0;
static int s1_done_owner = 0;
static int s1_done_thief = 0;

static void s1_owner_fused_spawn(void) {
#ifdef INJECT_BUG_SPAWN_PUBLISH_BEFORE_ACTIVE_INC
  /* BUG: publishes task to deque BEFORE incrementing n_active! */
  s1_dq_slot0 = 42;
  fence_release();
  s1_dq_tail = 1;
  __CPROVER_atomic_begin();
  s1_n_active += 1;
  __CPROVER_atomic_end();
  s1_spawned = 2;
#else
  __CPROVER_atomic_begin();
  s1_n_active += 1;
  __CPROVER_atomic_end();
  fence_release();
  s1_spawned = 2;
  fence_release();
  s1_dq_slot0 = 42;
  fence_release();
  s1_dq_tail = 1;
#endif
  fence_release();
  s1_done_owner = 1;
}

static void s1_thief_steal_and_finish(void) {
  int t = s1_dq_tail;
  fence_acquire();
  int h = s1_dq_head;
  if (h < t) {
    int item = s1_dq_slot0;
    int won = 0;
    __CPROVER_atomic_begin();
    if (s1_dq_head == h) { s1_dq_head = h + 1; won = 1; }
    __CPROVER_atomic_end();
    if (won) {
      assert(item == 42);
      /* Child finishes: decrement n_active (must NEVER drop below 1 while parent alive!) */
      int after;
      __CPROVER_atomic_begin();
      s1_n_active -= 1;
      after = s1_n_active;
      s1_completed += 1;
      __CPROVER_atomic_end();
      if (after < 1) {
        s1_active_underflow = 1;
      }
    }
  }
  fence_release();
  s1_done_thief = 1;
}

/* ============================================================================
 * Scenario 2: Fused yield (push fk + CAS pop) vs concurrent thief (PSO)
 * ============================================================================ */
static int s2_slot0 = 0; /* pre-existing sibling task 10 */
static int s2_slot1 = 0; /* yielded fk task 20 */
static int s2_head = 0;
static int s2_tail = 1;
static int s2_run_10 = 0;
static int s2_run_20 = 0;
static int s2_bad_item = 0;
static int s2_done_owner = 0;
static int s2_done_thief = 0;

static void record_run(int item) {
  if (item == 10) {
    __CPROVER_atomic_begin(); s2_run_10++; __CPROVER_atomic_end();
  } else if (item == 20) {
    __CPROVER_atomic_begin(); s2_run_20++; __CPROVER_atomic_end();
  } else {
    s2_bad_item = 1;
  }
}

static void s2_owner_fused_yield(void) {
  /* Step A: Push yielded fk (20) at slot 1 */
  s2_slot1 = 20;
#ifndef INJECT_BUG_YIELD_PUSH_NO_RELEASE_TAIL
  fence_release();
#endif
  s2_tail = 2;

  /* Step B: Immediately pop next task from dq.head */
  int h = s2_head;
  fence_acquire();
  if (h < 2) {
    int item = (h == 0) ? s2_slot0 : s2_slot1;
#ifdef INJECT_BUG_YIELD_POP_WITHOUT_CAS
    /* BUG: owner increments head without CAS against thief! */
    s2_head = h + 1;
    record_run(item);
#else
    int won = 0;
    __CPROVER_atomic_begin();
    if (s2_head == h) { s2_head = h + 1; won = 1; }
    __CPROVER_atomic_end();
    if (won) {
      fence_acqrel();
      record_run(item);
    }
#endif
  }
  fence_release();
  s2_done_owner = 1;
}

static void s2_thief(void) {
  int t = s2_tail;
  fence_acquire();
  int h = s2_head;
  fence_acquire();
  if (h < t) {
    int item = (h == 0) ? s2_slot0 : s2_slot1;
    int won = 0;
    __CPROVER_atomic_begin();
    if (s2_head == h) { s2_head = h + 1; won = 1; }
    __CPROVER_atomic_end();
    if (won) {
      fence_acqrel();
      record_run(item);
    }
  }
  fence_release();
  s2_done_thief = 1;
}

/* ============================================================================
 * Scenario 3: Inline %free-fk-c! extract-before-clear on self-yield
 * ============================================================================ */
static void check_inline_fk_self_yield(void) {
  int fk_raw_k = 999;
  int fk_val = 123;
  int pool_len = 0;

  int nk, nval;
#ifdef INJECT_BUG_FREE_FK_BEFORE_READ_RAWK
  /* BUG: clears fk fields BEFORE reading nk/nval! */
  fk_raw_k = 0;
  fk_val = 0;
  pool_len++;
  nk = fk_raw_k;
  nval = fk_val;
#else
  nk = fk_raw_k;
  nval = fk_val;
  /* Inline %free-fk-c! clears fields and recycles to pool */
  fk_raw_k = 0;
  fk_val = 0;
  if (pool_len < 64) pool_len++;
#endif
  assert(nk == 999);
  assert(nval == 123);
  assert(fk_raw_k == 0);
  assert(pool_len == 1);
}

int main(void) {
  /* Scenario 1: Fused spawn vs thief */
  __CPROVER_ASYNC_1: s1_thief_steal_and_finish();
  s1_owner_fused_spawn();
  __CPROVER_assume(s1_done_owner == 1 && s1_done_thief == 1);
  fence_acquire();
  assert(s1_active_underflow == 0);
  assert(s1_completed <= s1_spawned);

  /* Scenario 2: Fused yield push+pop vs thief under PSO */
  s2_slot0 = 10;
  fence_release();
  __CPROVER_ASYNC_2: s2_thief();
  s2_owner_fused_yield();
  __CPROVER_assume(s2_done_owner == 1 && s2_done_thief == 1);
  fence_acquire();
  assert(s2_bad_item == 0);
  assert(s2_run_10 <= 1);
  assert(s2_run_20 <= 1);
  /* Remaining unclaimed tasks in [s2_head, s2_tail) + executed == 2 */
  assert((2 - s2_head) + s2_run_10 + s2_run_20 == 2);

  /* Scenario 3: Inline %free-fk-c! self-yield ordering */
  check_inline_fk_self_yield();

  return 0;
}
