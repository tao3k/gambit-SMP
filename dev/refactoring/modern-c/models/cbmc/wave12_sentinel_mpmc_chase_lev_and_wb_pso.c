/*
 * Wave 12 CBMC --mm pso Formal Weak-Memory Model:
 *   Model 1: Single-vector sentinel MPMC queue (release-acquire payload publish,
 *            tail-cacheline-elided dequeue, clear-to-sentinel prevents ABA/false-item)
 *   Model 2: Chase-Lev work-stealing deque relaxed empty peek + seq_cst pop/steal
 *            single-item arbitration + bounded peer-thief CAS retry
 *   Model 3: Target-first / local-nursery generational write barrier card publication
 *
 * Verify SAFE baseline:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 5 \
 *     dev/refactoring/modern-c/models/cbmc/wave12_sentinel_mpmc_chase_lev_and_wb_pso.c
 *
 * Verify all 5 PSO mutants killed (rc=10):
 *   -DMUTANT_LFQ_SENTINEL_DROP_RELEASE
 *   -DMUTANT_LFQ_CLEAR_TO_FALSE_NOT_SENTINEL
 *   -DMUTANT_CHASE_LEV_DROP_SEQ_CST_FENCE
 *   -DMUTANT_CHASE_LEV_DROP_PUSH_RELEASE
 *   -DMUTANT_WB_SKIP_LOCAL_NURSERY_CARD
 */

#include <assert.h>

static void fence_release(void) { __CPROVER_fence("WWfence", "RWfence"); }
static void fence_acquire(void) { __CPROVER_fence("RRfence", "RWfence"); }
static void fence_seq_cst(void) { __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence"); }

/* ============================================================================
 * Model 1: Single-Vector Sentinel MPMC Queue (no separate states vector,
 *          tail-cacheline-elided dequeue, clear-to-sentinel on win)
 * ============================================================================ */

#define SENTINEL_EMPTY (-1)
#define USER_FALSE_PAYLOAD 0
#define PAYLOAD_OBJ_1 1

static int m1_payload_val = 0;
static int m1_slot[2] = { SENTINEL_EMPTY, SENTINEL_EMPTY };
static int m1_head = 0;
static int m1_tail = 0;
static int m1_c1_got = SENTINEL_EMPTY;
static int m1_c2_got = SENTINEL_EMPTY;

static void m1_producer(void) {
  int t;
  __CPROVER_atomic_begin();
  t = m1_tail;
  m1_tail = t + 1;
  __CPROVER_atomic_end();
  if (t == 0) {
    m1_payload_val = 42;
#ifndef MUTANT_LFQ_SENTINEL_DROP_RELEASE
    fence_release();
#endif
    m1_slot[0] = PAYLOAD_OBJ_1;
  }
}

static void m1_consumer(int *out) {
  for (int attempt = 0; attempt < 2; attempt++) {
    int h = m1_head;
    fence_acquire();
    if (h >= 1) {
      return;
    }
    int v = m1_slot[h];
    fence_acquire();
    if (v != SENTINEL_EMPTY) {
      int won = 0;
      __CPROVER_atomic_begin();
      if (m1_head == h) {
        m1_head = h + 1;
        won = 1;
      }
      __CPROVER_atomic_end();
      if (won) {
        if (v == PAYLOAD_OBJ_1) {
          assert(m1_payload_val == 42);
        }
#ifdef MUTANT_LFQ_CLEAR_TO_FALSE_NOT_SENTINEL
        /* Buggy clear to user-valid #f (0) instead of private SENTINEL_EMPTY */
        m1_slot[h] = USER_FALSE_PAYLOAD;
#else
        m1_slot[h] = SENTINEL_EMPTY;
#endif
        *out = v;
        return;
      }
    }
  }
}

static void verify_model1_sentinel_mpmc(void) {
  m1_payload_val = 0;
  m1_slot[0] = SENTINEL_EMPTY;
  m1_slot[1] = SENTINEL_EMPTY;
  m1_head = 0;
  m1_tail = 0;
  m1_c1_got = SENTINEL_EMPTY;
  m1_c2_got = SENTINEL_EMPTY;
  fence_release();

  __CPROVER_ASYNC_1: m1_producer();
  __CPROVER_ASYNC_2: m1_consumer(&m1_c1_got);
  m1_consumer(&m1_c2_got);

  /* At most one consumer may claim ticket 0, and if either claims it, it must
   * be PAYLOAD_OBJ_1 (never USER_FALSE_PAYLOAD from a cleared slot). */
  assert(!(m1_c1_got != SENTINEL_EMPTY && m1_c2_got != SENTINEL_EMPTY));
  if (m1_c1_got != SENTINEL_EMPTY) {
    assert(m1_c1_got == PAYLOAD_OBJ_1);
  }
  if (m1_c2_got != SENTINEL_EMPTY) {
    assert(m1_c2_got == PAYLOAD_OBJ_1);
  }
#ifdef MUTANT_LFQ_CLEAR_TO_FALSE_NOT_SENTINEL
  /* Post-consume slow probe must observe SENTINEL_EMPTY, never a fake user #f */
  if (m1_head == 1) {
    assert(m1_slot[0] == SENTINEL_EMPTY);
  }
#endif
}

/* ============================================================================
 * Model 2: Chase-Lev Relaxed Empty Peek + 2-Item Seq-Cst StoreLoad Arbitration
 * ============================================================================ */

static int m2_data = 0;
static int m2_slot[2] = { 0, 0 };
static int m2_top = 0;
static int m2_bottom = 0;
static int m2_owner_got = 0;
static int m2_thief_got = 0;

static void m2_owner_push(void) {
  m2_data = 77;
  m2_slot[0] = 1;
#ifndef MUTANT_CHASE_LEV_DROP_PUSH_RELEASE
  fence_release();
#endif
  m2_bottom = 1;
}

static void m2_thief_steal_relaxed_peek(int target_slot_check) {
  /* Zero-barrier relaxed empty peek */
  int t_peek = m2_top;
  int b_peek = m2_bottom;
  if (t_peek >= b_peek) {
    return;
  }
  /* Non-empty path: full Chase-Lev acquire + seq_cst + CAS */
  int t = m2_top;
  fence_acquire();
#ifndef MUTANT_CHASE_LEV_DROP_SEQ_CST_FENCE
  fence_seq_cst();
#endif
  int b = m2_bottom;
  fence_acquire();
  if (t < b) {
    int val = m2_slot[t];
    fence_acquire();
    int won = 0;
    __CPROVER_atomic_begin();
    if (m2_top == t) {
      m2_top = t + 1;
      won = 1;
    }
    __CPROVER_atomic_end();
    if (won) {
      if (target_slot_check == 0) {
        assert(val == 1);
        assert(m2_data == 77);
      }
      m2_thief_got = val;
    }
  }
}

static void m2_owner_pop_from_2(void) {
  /* Owner LIFO pop of slot[1] when bottom starts at 2 */
  int b = m2_bottom - 1; /* b = 1 */
  m2_bottom = b;
#ifndef MUTANT_CHASE_LEV_DROP_SEQ_CST_FENCE
  fence_seq_cst();
#endif
  int t = m2_top;
  if (t <= b) {
    int val = m2_slot[b];
    if (t == b) {
      int won = 0;
      __CPROVER_atomic_begin();
      if (m2_top == t) {
        m2_top = t + 1;
        won = 1;
      }
      __CPROVER_atomic_end();
      m2_bottom = b + 1;
      if (won) {
        m2_owner_got = val;
      }
    } else {
      /* t < b (e.g. stale t == 0 < b == 1): owner claims slot[1] without CAS */
      m2_owner_got = val;
    }
  } else {
    m2_bottom = b + 1;
  }
}

static void m2_thief_pair_from_2(void) {
  /* Thief 1 claims slot[0] (top 0 -> 1), then Thief 2 tries to steal slot[1] */
  __CPROVER_atomic_begin();
  if (m2_top == 0) {
    m2_top = 1;
  }
  __CPROVER_atomic_end();
  m2_thief_steal_relaxed_peek(1);
}

static void verify_model2_chase_lev_relaxed_peek(void) {
  /* Sub-model 2A: Push release ordering against relaxed empty peek + steal */
  m2_data = 0;
  m2_slot[0] = 0;
  m2_slot[1] = 0;
  m2_top = 0;
  m2_bottom = 0;
  m2_thief_got = 0;
  fence_release();

  __CPROVER_ASYNC_1: m2_owner_push();
  m2_thief_steal_relaxed_peek(0);

  /* Sub-model 2B: Classic Le et al. PPoPP '13 2-item StoreLoad race:
   * With 2 items (top=0, bottom=2), Thief 1 advances top 0->1 while Owner
   * pops slot[1] (bottom=1) and Thief 2 races for slot[1]. Without seq_cst,
   * Owner reads stale top=0 (< b=1, skipping CAS) while Thief 2 reads stale
   * bottom=2 (> t=1) and wins CAS(top, 1, 2) -> double claim of slot[1]! */
  m2_slot[0] = 10;
  m2_slot[1] = 20;
  m2_top = 0;
  m2_bottom = 2;
  m2_owner_got = 0;
  m2_thief_got = 0;
  fence_seq_cst();

  __CPROVER_ASYNC_2: m2_owner_pop_from_2();
  m2_thief_pair_from_2();

  /* Owner and Thief 2 must NEVER both claim item 20 (slot[1])! */
  assert(!(m2_owner_got == 20 && m2_thief_got == 20));
}

/* ============================================================================
 * Model 3: Target-First / Local-Nursery Generational Write Barrier Publication
 * ============================================================================ */

static int m3_mature_slot = 0;      /* 0 = none, 1 = young child in local nursery */
static int m3_card_dirty = 0;
static int m3_local_escaped = 0;
static int m3_young_child_init = 0;

static void m3_mutator_store(int target_is_mature, int val_in_local_nursery) {
  if (val_in_local_nursery) {
    m3_young_child_init = 99;
  }
  if (!target_is_mature) {
    /* Cross-core young target: elide mature card lookup, set local_young_escaped_ */
    if (val_in_local_nursery) {
      m3_local_escaped = 1;
    }
    return;
  }
  /* Target is mature: local-nursery short-circuit skips val radix lookup */
  if (val_in_local_nursery) {
    m3_local_escaped = 1;
#ifndef MUTANT_WB_SKIP_LOCAL_NURSERY_CARD
    fence_release();
    m3_card_dirty = 1;
#endif
    m3_mature_slot = 1;
  }
}

static void verify_model3_target_first_wb(void) {
  /* Case A: Mature target <- local-nursery young child */
  m3_mature_slot = 0;
  m3_card_dirty = 0;
  m3_local_escaped = 0;
  m3_young_child_init = 0;
  m3_mutator_store(1, 1);
  if (m3_mature_slot == 1) {
    assert(m3_card_dirty == 1);
    assert(m3_local_escaped == 1);
    assert(m3_young_child_init == 99);
  }

  /* Case B: Cross-core young target <- local-nursery young child */
  m3_mature_slot = 0;
  m3_card_dirty = 0;
  m3_local_escaped = 0;
  m3_young_child_init = 0;
  m3_mutator_store(0, 1);
  assert(m3_card_dirty == 0);
  assert(m3_local_escaped == 1);
}

int main(void) {
  verify_model1_sentinel_mpmc();
  verify_model2_chase_lev_relaxed_peek();
  verify_model3_target_first_wb();
  return 0;
}
