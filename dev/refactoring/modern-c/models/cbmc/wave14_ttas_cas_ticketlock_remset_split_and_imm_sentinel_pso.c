/*
 * Wave 14 CBMC --mm pso Formal Verification Model
 *
 * Verifies four concurrent protocols introduced/refined in Wave 14:
 *   1. Linearizable TTAS fast-fail + write-barriered vector/structure CAS
 *      (___gc_vector_cas_barrier / ___gc_structure_cas_barrier).
 *   2. Progress-aware adaptive ticketlock (___TICKETLOCK_LOCK2) with
 *      minimal-hold msection claiming (bump_heap_section_for_demand).
 *   3. Zero-global-lookup immediate-sentinel (___UNB2 / ___DELETED) MPMC
 *      relaxed-peek dequeue and sentinel disjointness from user #f / 0 / heap.
 *   4. Object-disjoint intra-section movable remembered-set card-run splitting
 *      (remset_cards_split_safe) guaranteeing zero overlapping worker writes.
 *
 * Verify SAFE baseline:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 5 \
 *        dev/refactoring/modern-c/models/cbmc/wave14_ttas_cas_ticketlock_remset_split_and_imm_sentinel_pso.c
 *
 * Kill all 5 mutants (each MUST exit rc=10 / VERIFICATION FAILED):
 *   -DMUTANT_TTAS_CAS_DROP_BARRIER_ORDER
 *   -DMUTANT_TTAS_CAS_SKIP_WB_ON_HIT
 *   -DMUTANT_TICKETLOCK_DROP_UNLOCK_RELEASE
 *   -DMUTANT_MPMC_ALIAS_FALSE_SENTINEL
 *   -DMUTANT_REMSET_SPLIT_UNSAFE_NONVECTOR
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *kind, ...);
extern int nondet_int(void);
extern void __CPROVER_assume(_Bool);

static inline void fence_acq(void) { __CPROVER_fence("RRfence", "RWfence"); }
static inline void fence_rel(void) { __CPROVER_fence("WWfence", "RWfence"); }

#define LOAD_RLX(v) (v)
#define LOAD_ACQ(v, out) do { (out) = (v); fence_acq(); } while (0)
#define STORE_RLX(v, x) do { (v) = (x); } while (0)
#define STORE_REL(v, x) do { fence_rel(); (v) = (x); } while (0)
#define FAA_RLX(v, d, old_out) do { \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  (v) = (old_out) + (d); \
  __CPROVER_atomic_end(); \
} while (0)
#define FAA_REL(v, d, old_out) do { \
  fence_rel(); \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  (v) = (old_out) + (d); \
  __CPROVER_atomic_end(); \
} while (0)
#define CAS_RLX(v, exp, des, old_out) do { \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  if ((old_out) == (exp)) (v) = (des); \
  __CPROVER_atomic_end(); \
} while (0)
#define CAS_ACQREL(v, exp, des, old_out) do { \
  fence_rel(); \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  if ((old_out) == (exp)) (v) = (des); \
  __CPROVER_atomic_end(); \
  fence_acq(); \
} while (0)

/* =========================================================================
 * Model 1: Linearizable TTAS Fast-Fail Vector CAS + Write Barrier
 * ========================================================================= */
#define M1_INIT_VAL  10
#define M1_YOUNG_PTR 20
#define M1_OTHER_VAL 30

static int m1_young_payload = 0;
static int m1_slot = M1_INIT_VAL;
static int m1_card_dirty = 0;
static int m1_t1_won = 0;
static int m1_t2_won = 0;

static void m1_thread1(void)
{
  /* Allocate and initialize young object before publishing into mature vector */
  STORE_RLX(m1_young_payload, 0x42);

  /* TTAS fast-fail acquire peek */
  int cur;
  LOAD_ACQ(m1_slot, cur);
  if (cur != M1_INIT_VAL) {
    STORE_REL(m1_t1_won, 0);
    return;
  }

  /* Generational write barrier before publishing young pointer into mature slot */
#ifndef MUTANT_TTAS_CAS_SKIP_WB_ON_HIT
  STORE_REL(m1_card_dirty, 1);
#endif

  int prev;
#ifdef MUTANT_TTAS_CAS_DROP_BARRIER_ORDER
  CAS_RLX(m1_slot, M1_INIT_VAL, M1_YOUNG_PTR, prev);
#else
  CAS_ACQREL(m1_slot, M1_INIT_VAL, M1_YOUNG_PTR, prev);
#endif
  STORE_REL(m1_t1_won, (prev == M1_INIT_VAL) ? 1 : 0);
}

static void m1_thread2(void)
{
  /* Contend with TTAS CAS or read published value */
  int cur;
  LOAD_ACQ(m1_slot, cur);
  if (cur != M1_INIT_VAL) {
    /* TTAS fast-fail: returned value must be validly published with dirty card */
    if (cur == M1_YOUNG_PTR) {
      int p = LOAD_RLX(m1_young_payload);
      int d;
      LOAD_ACQ(m1_card_dirty, d);
      assert(p == 0x42);
      assert(d == 1);
    }
    STORE_REL(m1_t2_won, 0);
    return;
  }
  int prev;
  CAS_ACQREL(m1_slot, M1_INIT_VAL, M1_OTHER_VAL, prev);
  if (prev != M1_INIT_VAL && prev == M1_YOUNG_PTR) {
    int p = LOAD_RLX(m1_young_payload);
    int d;
    LOAD_ACQ(m1_card_dirty, d);
    assert(p == 0x42);
    assert(d == 1);
  }
  STORE_REL(m1_t2_won, (prev == M1_INIT_VAL) ? 1 : 0);
}

static void run_model1_ttas_cas(void)
{
__CPROVER_ASYNC_1:
  m1_thread1();
  m1_thread2();

  /* Direct post-state check when T1 published */
  int cur;
  LOAD_ACQ(m1_slot, cur);
  if (cur == M1_YOUNG_PTR) {
    int p = LOAD_RLX(m1_young_payload);
    int d;
    LOAD_ACQ(m1_card_dirty, d);
    assert(p == 0x42);
    assert(d == 1);
  }
  int w1, w2;
  LOAD_ACQ(m1_t1_won, w1);
  LOAD_ACQ(m1_t2_won, w2);
  assert(w1 + w2 <= 1);
}

/* =========================================================================
 * Model 2: Progress-Aware Ticketlock + Minimal-Hold Msection Claim
 * ========================================================================= */
static int m2_next = 0;
static int m2_curr = 0;
static int m2_alloc_idx = 0;
static int m2_sec_payload = 0;
static int m2_in_cs = 0;

static void m2_lock_and_claim_t0(void)
{
  int ticket;
  FAA_RLX(m2_next, 1, ticket);
  int cur;
  LOAD_ACQ(m2_curr, cur);
  __CPROVER_assume(cur == ticket);

  /* Minimal critical section: write shared allocator state + claim msection */
  int prev_cs;
  FAA_RLX(m2_in_cs, 1, prev_cs);
  assert(prev_cs == 0);
  int my_ms = LOAD_RLX(m2_alloc_idx);
  STORE_RLX(m2_alloc_idx, my_ms + 1);
  STORE_RLX(m2_sec_payload, 77);
  int tmp;
  FAA_RLX(m2_in_cs, -1, tmp);

  int u_old;
#ifdef MUTANT_TICKETLOCK_DROP_UNLOCK_RELEASE
  FAA_RLX(m2_curr, 1, u_old);
#else
  FAA_REL(m2_curr, 1, u_old);
#endif
}

static void m2_lock_and_claim_t1(void)
{
  int ticket;
  FAA_RLX(m2_next, 1, ticket);
  int cur;
  LOAD_ACQ(m2_curr, cur);
  __CPROVER_assume(cur == ticket);

  int prev_cs;
  FAA_RLX(m2_in_cs, 1, prev_cs);
  assert(prev_cs == 0);
  int my_ms = LOAD_RLX(m2_alloc_idx);
  /* If T1 acquired after T0 (ticket == 1), it MUST observe T0's msection advance and payload */
  if (ticket == 1) {
    assert(my_ms == 1);
    assert(LOAD_RLX(m2_sec_payload) == 77);
  }
  STORE_RLX(m2_alloc_idx, my_ms + 1);
  int tmp;
  FAA_RLX(m2_in_cs, -1, tmp);

  int u_old;
#ifdef MUTANT_TICKETLOCK_DROP_UNLOCK_RELEASE
  FAA_RLX(m2_curr, 1, u_old);
#else
  FAA_REL(m2_curr, 1, u_old);
#endif
}

static void run_model2_ticketlock_msection(void)
{
__CPROVER_ASYNC_2:
  m2_lock_and_claim_t0();
  m2_lock_and_claim_t1();
}

/* =========================================================================
 * Model 3: Zero-Global-Lookup Immediate-Sentinel MPMC Relaxed Peek
 * ========================================================================= */
#define M3_USER_FALSE   0
#ifdef MUTANT_MPMC_ALIAS_FALSE_SENTINEL
#define M3_SENT_EMPTY   M3_USER_FALSE
#else
#define M3_SENT_EMPTY   (-8)   /* ___UNB2 internal sentinel */
#endif
#define M3_SENT_DELETED (-15)  /* ___DELETED internal sentinel */

static int m3_slot0 = M3_SENT_EMPTY;
static int m3_head = 0;
static int m3_tail = 0;
static int m3_prod_done = 0;

static void m3_producer(void)
{
  /* Enqueue Scheme #f (M3_USER_FALSE) — must NEVER alias with ___UNB2 */
  int t;
  FAA_RLX(m3_tail, 1, t);
  assert(t == 0);
  int prev;
  CAS_ACQREL(m3_slot0, M3_SENT_EMPTY, M3_USER_FALSE, prev);
  assert(prev == M3_SENT_EMPTY);
  STORE_REL(m3_prod_done, 1);
}

static void m3_consumer(void)
{
  int done;
  LOAD_ACQ(m3_prod_done, done);
  if (!done) return;

  int h0;
  LOAD_ACQ(m3_head, h0);
  int v0 = LOAD_RLX(m3_slot0);
  if (v0 == M3_SENT_EMPTY) {
    int t0;
    LOAD_ACQ(m3_tail, t0);
    if (h0 >= t0) {
      /* Must NOT falsely report empty after producer finished! */
      assert(0);
    }
  }
  int h;
  FAA_RLX(m3_head, 1, h);
  assert(h == 0);
  int v;
  LOAD_ACQ(m3_slot0, v);
  /* Immediate sentinel check: ___UNB2 and ___DELETED are disjoint from #f (0) */
  assert(v != M3_SENT_EMPTY && v != M3_SENT_DELETED);
  assert(v == M3_USER_FALSE);
  STORE_RLX(m3_slot0, M3_SENT_DELETED);
}

static void run_model3_imm_sentinel_mpmc(void)
{
__CPROVER_ASYNC_3:
  m3_producer();
  m3_consumer();
}

/* =========================================================================
 * Model 4: Disjoint Intra-Section Movable Card-Run Splitting
 * ========================================================================= */
static void run_model4_remset_disjoint_split(void)
{
  int obj_kind = nondet_int();
  __CPROVER_assume(obj_kind >= 0 && obj_kind <= 2);

  /* Card boundaries: card 0 = [0,4), card 1 = [4,8), card 2 = [8,12) */
  int obj0_start = (obj_kind == 2) ? 0 : 2;
  int obj0_end   = (obj_kind == 2) ? 4 : 6; /* crosses card 0->1 when kind != 2 */
  int obj0_is_vec = (obj_kind == 0) ? 1 : 0;
  int starts_c1_zero = (obj_kind == 2) ? 1 : 0;

  int can_split_0_1;
#ifdef MUTANT_REMSET_SPLIT_UNSAFE_NONVECTOR
  can_split_0_1 = 1; /* BUG: splits across crossing non-vector object */
#else
  can_split_0_1 = starts_c1_zero || (obj0_start >= 4) || obj0_is_vec;
#endif

  int w0_hits[12] = {0};
  int w1_hits[12] = {0};

  if (can_split_0_1) {
    if (obj0_is_vec) {
      for (int w = obj0_start; w < obj0_end; w++) {
        if (w >= 0 && w < 4) w0_hits[w]++;
        if (w >= 4 && w < 8) w1_hits[w]++;
      }
    } else {
      if (obj0_start < 4 && obj0_end > 0) {
        for (int w = obj0_start; w < obj0_end; w++) w0_hits[w]++;
      }
      if (obj0_start < 8 && obj0_end > 4) {
        for (int w = obj0_start; w < obj0_end; w++) w1_hits[w]++;
      }
    }
  } else {
    int last_end = 0;
    if (obj0_start >= last_end) {
      for (int w = obj0_start; w < obj0_end; w++) w0_hits[w]++;
      last_end = obj0_end;
    }
    if (obj0_start >= last_end) {
      for (int w = obj0_start; w < obj0_end; w++) w0_hits[w]++;
      last_end = obj0_end;
    }
  }

  for (int w = obj0_start; w < obj0_end; w++) {
    assert(!(w0_hits[w] > 0 && w1_hits[w] > 0));
    assert(w0_hits[w] + w1_hits[w] == 1);
  }
}

int main(void)
{
  run_model1_ttas_cas();
  run_model2_ticketlock_msection();
  run_model3_imm_sentinel_mpmc();
  run_model4_remset_disjoint_split();
  return 0;
}
