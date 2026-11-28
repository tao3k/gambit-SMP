/*
 * Wave 13 Weak-Memory (PSO) Formal Verification Model:
 *   Model 1: Per-Segment LCRQ-style 2-Sentinel FAA (fetch_add) Cache-Line-Permuted
 *            256-Slot MPMC Queue (___UNB2 = EMPTY, ___DELETED = CANCELLED).
 *            Each segment owns independent 128B-padded (head_ctr, tail_ctr) so
 *            t >= CAP / h >= CAP closes a segment permanently with zero ticket
 *            loss and zero consumer-side segment allocation.
 *   Model 2: Owner-Private cached_top + Relaxed-Slot Chase-Lev Work-Stealing
 *            Deque (Le et al., PPoPP '13) verifying bounded ring safety and
 *            payload visibility under PSO.
 *   Model 3: Sound fast_minor_admitted upper bound for young sections carrying
 *            captured continuations (raw_marks != 0) or parked stacks.
 *
 * Verified with:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 5 \
 *     dev/refactoring/modern-c/models/cbmc/wave13_faa_mpmc_cached_chase_lev_and_fast_minor_pso.c
 *
 * Negative Mutants (all 5 MUST fail with rc=10):
 *   -DMUTANT_LCRQ_DROP_ENQ_RELEASE
 *   -DMUTANT_LCRQ_SKIP_CANCEL_RETRY
 *   -DMUTANT_LCRQ_DEQ_IGNORE_CLOSED_SEG
 *   -DMUTANT_CL_STALE_CACHED_TOP_OVERWRITE
 *   -DMUTANT_FAST_MINOR_OMIT_RAW_SPAN_BOUND
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *kind, ...);
extern int nondet_int(void);
extern unsigned int nondet_uint(void);

static inline void fence_acq(void) { __CPROVER_fence("RRfence", "RWfence"); }
static inline void fence_rel(void) { __CPROVER_fence("WWfence", "RWfence"); }
static inline void fence_sc(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

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
#define FAA_ACQREL(v, d, old_out) do { \
  fence_rel(); \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  (v) = (old_out) + (d); \
  __CPROVER_atomic_end(); \
  fence_acq(); \
} while (0)
#define CAS_ACQREL(v, exp, des, old_out) do { \
  fence_rel(); \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  if ((old_out) == (exp)) (v) = (des); \
  __CPROVER_atomic_end(); \
  fence_acq(); \
} while (0)
#define CAS_RLX(v, exp, des, old_out) do { \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  if ((old_out) == (exp)) (v) = (des); \
  __CPROVER_atomic_end(); \
} while (0)
#define CAS_SC(v, exp, des, old_out) do { \
  fence_sc(); \
  __CPROVER_atomic_begin(); \
  (old_out) = (v); \
  if ((old_out) == (exp)) (v) = (des); \
  __CPROVER_atomic_end(); \
  fence_sc(); \
} while (0)

/* ============================================================================
 * Model 1: Per-Segment LCRQ 2-Sentinel FAA Cache-Line-Permuted MPMC Queue
 * ============================================================================ */

#define M1_EMPTY     (-8)   /* models ___UNB2 */
#define M1_CANCELLED (-15)  /* models ___DELETED */
#define M1_CAP       2

/* Sub-model 1A: 256-slot cache-line permutation bijection + 16-way disjointness */
static void verify_m1_permutation(void) {
  unsigned int off = nondet_uint();
  __CPROVER_assume(off < 256u);
  unsigned int phys = ((off & 15u) << 4) | (off >> 4);
  assert(phys < 256u);
  unsigned int inv = ((phys & 15u) << 4) | (phys >> 4);
  assert(inv == off);

  unsigned int base = nondet_uint();
  unsigned int d1 = nondet_uint();
  unsigned int d2 = nondet_uint();
  __CPROVER_assume(base <= 240u && d1 < 16u && d2 < 16u && d1 != d2);
  unsigned int p1 = (((base + d1) & 15u) << 4) | ((base + d1) >> 4);
  unsigned int p2 = (((base + d2) & 15u) << 4) | ((base + d2) >> 4);
  assert((p1 >> 4) != (p2 >> 4));
}

/* Sub-model 1B: 2-thread PSO Producer-vs-Consumer on per-segment FAA slots */
static int m1b_slots[M1_CAP];
static int m1b_head;
static int m1b_tail;
static int m1b_payload[3];

static void verify_m1b_pso_prod_cons(void) {
  m1b_slots[0] = M1_EMPTY;
  m1b_slots[1] = M1_EMPTY;
  m1b_head = 0;
  m1b_tail = 0;
  m1b_payload[1] = 0;

  __CPROVER_ASYNC_m1b_prod:
  {
    int t, prev;
    STORE_RLX(m1b_payload[1], 101);
    FAA_RLX(m1b_tail, 1, t);
    if (t < M1_CAP) {
#ifdef MUTANT_LCRQ_DROP_ENQ_RELEASE
      CAS_RLX(m1b_slots[t], M1_EMPTY, 1, prev);
#else
      CAS_ACQREL(m1b_slots[t], M1_EMPTY, 1, prev);
#endif
      (void)prev;
    }
  }
  __CPROVER_ASYNC_m1b_cons:
  {
    int h0, t0;
    LOAD_ACQ(m1b_head, h0);
    LOAD_ACQ(m1b_tail, t0);
    if (h0 < M1_CAP && h0 < t0) {
      int h, v, prev;
      FAA_ACQREL(m1b_head, 1, h);
      if (h < M1_CAP) {
        LOAD_ACQ(m1b_slots[h], v);
        if (v != M1_EMPTY && v != M1_CANCELLED) {
          assert(v == 1);
          assert(LOAD_RLX(m1b_payload[1]) == 101);
          STORE_RLX(m1b_slots[h], M1_CANCELLED);
        } else {
          CAS_ACQREL(m1b_slots[h], M1_EMPTY, M1_CANCELLED, prev);
          if (prev != M1_EMPTY && prev != M1_CANCELLED) {
            assert(prev == 1);
            assert(LOAD_RLX(m1b_payload[1]) == 101);
            STORE_RLX(m1b_slots[h], M1_CANCELLED);
          }
        }
      }
    }
  }
}

/* Sub-model 1C: 2-thread PSO concurrent consumers crossing closed segment boundary */
static int m1c_slots[2][M1_CAP];
static int m1c_head[2];
static int m1c_tail[2];
static int m1c_delivered[3];

static int m1c_deq_once(void) {
  int h, v, prev;
  FAA_ACQREL(m1c_head[0], 1, h);
#ifdef MUTANT_LCRQ_DEQ_IGNORE_CLOSED_SEG
  /* BUG: masks h instead of checking h >= M1_CAP on closed segment! */
  int idx = h & (M1_CAP - 1);
  LOAD_ACQ(m1c_slots[0][idx], v);
  if (v != M1_EMPTY && v != M1_CANCELLED) {
    STORE_RLX(m1c_slots[0][idx], M1_CANCELLED);
    return v;
  }
  return -1;
#else
  if (h < M1_CAP) {
    LOAD_ACQ(m1c_slots[0][h], v);
    if (v != M1_EMPTY && v != M1_CANCELLED) {
      STORE_RLX(m1c_slots[0][h], M1_CANCELLED);
      return v;
    }
    CAS_ACQREL(m1c_slots[0][h], M1_EMPTY, M1_CANCELLED, prev);
    if (prev != M1_EMPTY && prev != M1_CANCELLED) {
      STORE_RLX(m1c_slots[0][h], M1_CANCELLED);
      return prev;
    }
    return -1;
  }
  /* Segment 0 closed (h >= M1_CAP): advance seamlessly to segment 1 */
  FAA_ACQREL(m1c_head[1], 1, h);
  if (h < M1_CAP) {
    LOAD_ACQ(m1c_slots[1][h], v);
    if (v != M1_EMPTY && v != M1_CANCELLED) {
      STORE_RLX(m1c_slots[1][h], M1_CANCELLED);
      return v;
    }
  }
  return -1;
#endif
}

static void verify_m1c_closed_seg_transition(void) {
  /* Segment 0 has 1 remaining item (item 1 at slot 1; slot 0 already consumed);
   * Segment 1 has item 2 at slot 0. Two concurrent consumers race across boundary! */
  m1c_slots[0][0] = 1; /* stale non-cancelled if someone wraps modulo? Wait: mark slot 0 item 99 to catch wrap! */
  m1c_slots[0][0] = 99; /* already logically retired; valid consumer starts at head=1 */
  m1c_slots[0][1] = 1;
  m1c_head[0] = 1;
  m1c_tail[0] = 2;

  m1c_slots[1][0] = 2;
  m1c_slots[1][1] = M1_EMPTY;
  m1c_head[1] = 0;
  m1c_tail[1] = 1;

  m1c_delivered[1] = 0;
  m1c_delivered[2] = 0;

  __CPROVER_ASYNC_m1c_c1:
  {
    int g = m1c_deq_once();
    if (g >= 0) {
      int d;
      assert(g == 1 || g == 2);
      FAA_ACQREL(m1c_delivered[g], 1, d);
      assert(d == 0);
    }
  }
  __CPROVER_ASYNC_m1c_c2:
  {
    int g = m1c_deq_once();
    if (g >= 0) {
      int d;
      assert(g == 1 || g == 2);
      FAA_ACQREL(m1c_delivered[g], 1, d);
      assert(d == 0);
    }
  }
}

/* Sub-model 1D: Stalled-producer cancellation + retry exactness */
static void verify_m1d_cancel_and_retry(void) {
  int slots[M1_CAP] = { M1_EMPTY, M1_EMPTY };
  int head = 0, tail = 0;
  int payload = 111;
  int t0, h0, prev, t1;

  /* Producer claims slot 0 via FAA and stalls before writing slots[0] */
  FAA_ACQREL(tail, 1, t0);
  assert(t0 == 0);

  /* Consumer claims slot 0 via FAA, sees EMPTY, cancels slot 0 -> CANCELLED */
  FAA_ACQREL(head, 1, h0);
  assert(h0 == 0);
  CAS_ACQREL(slots[h0], M1_EMPTY, M1_CANCELLED, prev);
  assert(prev == M1_EMPTY && slots[0] == M1_CANCELLED);

  /* Producer wakes up, tries CAS(slots[0], EMPTY, 1) -> fails with CANCELLED */
  CAS_ACQREL(slots[t0], M1_EMPTY, 1, prev);
  assert(prev == M1_CANCELLED);

#ifndef MUTANT_LCRQ_SKIP_CANCEL_RETRY
  /* Producer retries with fresh FAA ticket t1=1 and succeeds! */
  FAA_ACQREL(tail, 1, t1);
  assert(t1 == 1);
  CAS_ACQREL(slots[t1], M1_EMPTY, 1, prev);
  assert(prev == M1_EMPTY);
#endif

  /* Subsequent consumer MUST receive item 1 with intact payload! */
  assert(head < tail);
  int h1, v;
  FAA_ACQREL(head, 1, h1);
  LOAD_ACQ(slots[h1], v);
  assert(v == 1 && payload == 111);
}

/* ============================================================================
 * Model 2: Owner-Private cached_top + Relaxed-Slot Chase-Lev Deque
 * ============================================================================ */

#define M2_CAP  2
#define M2_MASK 1

static int m2_top;
static int m2_bot;
static int m2_cached_top;
static int m2_slots[M2_CAP];
static int m2_payload[4];

static int m2_push(int item, int secret) {
  STORE_RLX(m2_payload[item], secret);
  int b = LOAD_RLX(m2_bot);
  if (b - m2_cached_top >= M2_CAP) {
#ifdef MUTANT_CL_STALE_CACHED_TOP_OVERWRITE
    m2_cached_top = b - M2_CAP + 1; /* BUG: assumes space without loading top! */
#else
    LOAD_ACQ(m2_top, m2_cached_top);
#endif
    if (b - m2_cached_top >= M2_CAP) return 0;
  }
  STORE_RLX(m2_slots[b & M2_MASK], item);
  STORE_REL(m2_bot, b + 1);
  return 1;
}

static int m2_steal(void) {
  int t_peek = LOAD_RLX(m2_top);
  int b_peek = LOAD_RLX(m2_bot);
  if (t_peek >= b_peek) return -1;
  int t, b, prev;
  LOAD_ACQ(m2_top, t);
  fence_sc();
  LOAD_ACQ(m2_bot, b);
  if (t >= b) return -1;
  int val = LOAD_RLX(m2_slots[t & M2_MASK]);
  CAS_SC(m2_top, t, t + 1, prev);
  if (prev == t) return val;
  return -1;
}

static void verify_m2_cached_top_chase_lev(void) {
  m2_top = 0;
  m2_bot = 0;
  m2_cached_top = 0;
  m2_slots[0] = 0;
  m2_slots[1] = 0;
  m2_payload[1] = 0;
  m2_payload[2] = 0;
  m2_payload[3] = 0;

  assert(m2_push(1, 11) == 1);
  assert(m2_push(2, 22) == 1);

  __CPROVER_ASYNC_m2_thief:
  {
    int thief_got = m2_steal();
    if (thief_got >= 0) {
      assert(thief_got == 1);
      assert(LOAD_RLX(m2_payload[1]) == 11);
    }
  }
  __CPROVER_ASYNC_m2_owner:
  {
    int p3_ok = m2_push(3, 33);
    if (p3_ok) {
      int t_now;
      LOAD_ACQ(m2_top, t_now);
      assert(t_now >= 1);
    }
  }
}

/* ============================================================================
 * Model 3: fast_minor_admitted Bound Soundness with raw_marks / STACK_PARKED
 * ============================================================================ */

#define M3_FRAME_RESERVE     3
#define M3_FRAME_EXTRA_SLOTS 1
#define M3_FRAME_ALIGN       4
#define M3_HALF_WORDS        65536
#define M3_CAPACITY          60000

static int round_up_4(int x) { return (x + 3) & ~3; }

static void verify_m3_fast_minor_bounds(void) {
  int fs = nondet_int();
  __CPROVER_assume(fs >= 0 && fs <= 16384);
  int src_words = round_up_4(fs + M3_FRAME_RESERVE);
  int dst_words = fs + M3_FRAME_EXTRA_SLOTS + 1;
  assert(dst_words < src_words);

  int heap_used = nondet_int();
  int has_raw = nondet_int();
  int raw_span = nondet_int();
  int heap_words = nondet_int();
  __CPROVER_assume(heap_used == 0 || heap_used == 1);
  __CPROVER_assume(has_raw == 0 || has_raw == 1);
  __CPROVER_assume(raw_span >= 0 && raw_span <= M3_HALF_WORDS);
  __CPROVER_assume(heap_words >= 0 && heap_words <= M3_HALF_WORDS);
  if (!heap_used) __CPROVER_assume(heap_words == 0);
  if (!has_raw) __CPROVER_assume(raw_span == 0);
  __CPROVER_assume(heap_words + raw_span <= M3_HALF_WORDS);

  int true_copied = heap_words + raw_span;
  int true_max_req = (raw_span > 516) ? raw_span : 516;

  int est_words = 0;
  int est_max = 516;
  int fast_ok = 1;

  if (heap_used) {
    est_words += M3_HALF_WORDS;
  }
#ifndef MUTANT_FAST_MINOR_OMIT_RAW_SPAN_BOUND
  if (has_raw) {
    if (!heap_used) est_words += raw_span;
    if (raw_span + M3_FRAME_EXTRA_SLOTS + 2 > est_max) {
      est_max = raw_span + M3_FRAME_EXTRA_SLOTS + 2;
    }
  }
#endif
  if (est_max >= M3_CAPACITY) fast_ok = 0;

  if (fast_ok) {
    assert(est_words >= true_copied);
    assert(est_max >= true_max_req);
    assert(true_max_req < M3_CAPACITY);
  }
}

int main(void) {
  verify_m1_permutation();
  verify_m1d_cancel_and_retry();
  verify_m1b_pso_prod_cons();
  verify_m1c_closed_seg_transition();
  verify_m2_cached_top_chase_lev();
  verify_m3_fast_minor_bounds();
  return 0;
}
