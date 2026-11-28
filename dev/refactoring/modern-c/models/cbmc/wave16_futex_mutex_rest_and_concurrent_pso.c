/*
 * Bounded 8-Thread CBMC (--mm pso) formal verification model for Wave 16
 * native runtime optimizations:
 *
 *   1. Protocol A (8 concurrent threads T0..T7 racing on ONE shared futex mutex under PSO):
 *      128-byte isolated 3-state adaptive-spin + OS-futex alloc_mem_lock
 *      (state 0=UNLOCKED, 1=LOCKED_NO_WAITERS, 2=LOCKED_CONTENDED):
 *        - T0: initial holder writing PSO-protected CS payload and releasing
 *        - T1, T2: contended slow-path waiters (1->2 escalation, futex park,
 *          futex wake handoff, contended re-acquire, CS update + release)
 *        - T3, T4: concurrent fast-path thieves (0->1 acquire, CS verify + release)
 *        - T5, T6: concurrent contention escalators (1->2 escalation racing unlock)
 *        - T7: concurrent fast-path thief / observer (0->1 acquire, CS verify + release)
 *      Hardware futex state (bits 0..1) and ghost kernel waitqueue counters
 *      (parked/wakes/awake) are co-located in one coherent 8-bit word
 *      (mirroring single-address futex coherence), while protected CS payload
 *      variables (m_seq/m_data) remain separate non-atomic globals under
 *      full PSO weak memory.
 *   2. Protocol B (8 concurrent threads: 4 producers T0..T3 + 4 consumers T4..T7 under PSO):
 *      Per-segment FAA MPMC queue with release-CAS (casl) enqueue and
 *      relaxed-peek + acquire-load dequeue across 4 disjoint slots.
 *      Verifies PSO payload happens-before visibility and zero duplicate
 *      consumption across 8 concurrent threads.
 *   3. Protocol C (exact arithmetic & bounds):
 *      Overflow-free fast rest grant (pending <= 1024, np <= 1024, byte-shift
 *      room checks) bit-identical to exact overflow-checked grant, plus
 *      small-key (<= 32) vs processor-scratch (> 32) keyword buffer dispatch.
 *
 * Baseline verification:
 *   cbmc --sat-solver cadical --mm pso --bounds-check --signed-overflow-check --unwind 2 \
 *     dev/refactoring/modern-c/models/cbmc/wave16_futex_mutex_rest_and_concurrent_pso.c
 *
 * Mutant falsification (5/5 must FAIL with exit code 10):
 *   -DMUTANT_1  (futex mutex contended re-acquire installs 1 instead of 2 -> stranded waiter)
 *   -DMUTANT_2  (futex mutex unlock drops PSO release fence -> stale CS visibility)
 *   -DMUTANT_3  (MPMC enqueue drops release ordering on slot CAS -> uninit payload read)
 *   -DMUTANT_4  (MPMC dequeue skips MPMC_DELETED cancel sentinel on spin timeout -> lost enqueued item)
 *   -DMUTANT_5  (fast rest grant drops MAX_NB_PARMS overflow guard -> overflow mis-grant)
 */

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <assert.h>

extern unsigned int nondet_uint(void);
extern int64_t nondet_i64(void);
extern uint64_t nondet_u64(void);
extern bool nondet_bool(void);
extern void __CPROVER_assume(bool);
extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, ...);

/* =========================================================================
 * Protocol A: 8-Thread Single-Lock 3-State Futex Mutex under PSO
 *   Bit layout of m_word (8-bit coherent futex + ghost waitqueue word):
 *     [1:0] hardware futex state (0=unlocked, 1=locked, 2=contended)
 *     [3:2] ghost parked waiter count (0..3)
 *     [5:4] ghost committed kernel wake_one tokens (0..3)
 *     [7:6] ghost awake looping contenders (0..3)
 * ========================================================================= */

#define ST_MASK     0x3u
#define PARK_SHIFT  2u
#define WAKE_SHIFT  4u
#define AWAKE_SHIFT 6u
#define FIELD_MASK  0x3u

#define GET_ST(w)    ((w) & ST_MASK)
#define GET_PARK(w)  (((w) >> PARK_SHIFT) & FIELD_MASK)
#define GET_WAKE(w)  (((w) >> WAKE_SHIFT) & FIELD_MASK)
#define GET_AWAKE(w) (((w) >> AWAKE_SHIFT) & FIELD_MASK)
#define SET_ST(w, s) ((uint8_t)(((w) & ~ST_MASK) | ((s) & ST_MASK)))

static uint8_t m_word = 1u; /* T0 starts holding the uncontended lock */
static uint8_t m_seq = 0u, m_data = 0u;

#ifdef MUTANT_1
#define MUTANT_1_INSTALL_ST 1u
#else
#define MUTANT_1_INSTALL_ST 2u
#endif

#ifdef MUTANT_2
#define MUTANT_2_REL_FLAG false
#else
#define MUTANT_2_REL_FLAG true
#endif

static inline void futex_unlock(void) {
  if (MUTANT_2_REL_FLAG) __CPROVER_fence("WWfence", "RWfence");
  __CPROVER_atomic_begin();
  uint8_t w = m_word;
  unsigned int prev_st = GET_ST(w);
  assert(prev_st != 0u);
  uint8_t nw = SET_ST(w, 0u);
  if (prev_st == 2u) {
    if (GET_WAKE(nw) < 3u) nw = (uint8_t)(nw + (1u << WAKE_SHIFT));
    m_word = nw;
  } else {
    m_word = nw;
    /* Releasing from state 1 (no futex wake) is legal iff no waiter is stranded. */
    assert(GET_PARK(nw) == 0u || GET_WAKE(nw) > 0u || GET_AWAKE(nw) > 0u);
  }
  __CPROVER_atomic_end();
}

static void futex_t0_initial_holder(void) {
  /* T0 holds lock initially, publishes PSO CS payload (m_data before m_seq), then releases. */
  m_data = 101u;
  m_seq = 1u;
  futex_unlock();
}

static void futex_sleeper_worker(uint8_t tid) {
  /* Single-path slow waiter: either acquires fast (0->1) or escalates 1->2, parks, wakes, re-acquires. */
  bool acquired = false;
  bool parked = false;
  __CPROVER_atomic_begin();
  uint8_t w = m_word;
  if (GET_ST(w) == 0u) {
    m_word = SET_ST(w, 1u);
    acquired = true;
  } else {
    m_word = (uint8_t)(SET_ST(w, 2u) + (1u << PARK_SHIFT));
    parked = true;
  }
  __CPROVER_atomic_end();

  if (parked) {
    __CPROVER_assume(GET_WAKE(m_word) > 0u);
    /* Atomic wake-handoff + contended re-acquire attempt (single word op). */
    __CPROVER_atomic_begin();
    uint8_t w2 = m_word;
    if (GET_WAKE(w2) > 0u && GET_PARK(w2) > 0u) {
      w2 = (uint8_t)(w2 - (1u << WAKE_SHIFT) - (1u << PARK_SHIFT));
      if (GET_ST(w2) == 0u) {
        m_word = SET_ST(w2, MUTANT_1_INSTALL_ST);
        acquired = true;
      } else {
        m_word = (uint8_t)(w2 + (1u << AWAKE_SHIFT));
      }
    }
    __CPROVER_atomic_end();
  }

  if (acquired) {
    __CPROVER_fence("RRfence", "RWfence");
    uint8_t prev = m_seq;
    if (prev != 0u) assert(m_data == (uint8_t)(prev + 100u));
    m_data = (uint8_t)(tid + 101u);
    m_seq = (uint8_t)(tid + 1u);
    futex_unlock();
  }
}

static void futex_fast_thief(uint8_t tid, bool write_payload) {
  bool won = false;
  __CPROVER_atomic_begin();
  uint8_t w = m_word;
  if (GET_ST(w) == 0u) {
    m_word = SET_ST(w, 1u);
    won = true;
  }
  __CPROVER_atomic_end();
  if (won) {
    __CPROVER_fence("RRfence", "RWfence");
    uint8_t prev = m_seq;
    if (prev != 0u) assert(m_data == (uint8_t)(prev + 100u));
    if (write_payload) {
      m_data = (uint8_t)(tid + 101u);
      m_seq = (uint8_t)(tid + 1u);
    }
    futex_unlock();
  }
}

static void futex_escalator(void) {
  __CPROVER_atomic_begin();
  uint8_t w = m_word;
  if (GET_ST(w) == 1u) {
    m_word = SET_ST(w, 2u);
  }
  __CPROVER_atomic_end();
}

/* =========================================================================
 * Protocol B: 8-Thread (4 Producers T0..T3 + 4 Consumers T4..T7) MPMC Queue
 * ========================================================================= */

#define MPMC_UNB2    0u
#define MPMC_DELETED 99u

static uint8_t q_slot0 = MPMC_UNB2, q_slot1 = MPMC_UNB2, q_slot2 = MPMC_UNB2, q_slot3 = MPMC_UNB2;
static uint8_t q_data0 = 0u, q_data1 = 0u, q_data2 = 0u, q_data3 = 0u;
static uint8_t q_seen0 = 0u, q_seen1 = 0u, q_seen2 = 0u, q_seen3 = 0u;
static uint8_t q_abandoned0 = 0u, q_abandoned1 = 0u, q_abandoned2 = 0u, q_abandoned3 = 0u;
static uint8_t q_tail_ctr = 0u;

#define DEFINE_MPMC_SLOT(IDX, VAL, PAYLOAD) \
static void mpmc_prod_##IDX(void) { \
  __CPROVER_atomic_begin(); \
  q_tail_ctr++; \
  __CPROVER_atomic_end(); \
  q_data##IDX = (PAYLOAD); \
  if (MPMC_REL_ENQ) __CPROVER_fence("WWfence", "RWfence"); \
  bool won = false; \
  __CPROVER_atomic_begin(); \
  if (q_slot##IDX == MPMC_UNB2) { \
    q_slot##IDX = (VAL); \
    won = true; \
  } \
  __CPROVER_atomic_end(); \
  if (won) { \
    /* Producer CAS must never succeed on a slot already abandoned by its consumer. */ \
    assert(q_abandoned##IDX == 0u); \
  } \
} \
static void mpmc_cons_##IDX(void) { \
  uint8_t v0 = q_slot##IDX; \
  if (v0 == MPMC_UNB2 && (IDX) >= q_tail_ctr) return; \
  uint8_t val = q_slot##IDX; \
  __CPROVER_fence("RRfence", "RWfence"); \
  if (val == MPMC_UNB2) { \
    /* Spin budget exhausted on claimed slot: must atomically cancel to MPMC_DELETED. */ \
    if (MPMC_CANCEL_SENTINEL) { \
      __CPROVER_atomic_begin(); \
      if (q_slot##IDX == MPMC_UNB2) { \
        q_slot##IDX = MPMC_DELETED; \
        q_abandoned##IDX = 1u; \
      } else { \
        val = q_slot##IDX; \
      } \
      __CPROVER_atomic_end(); \
    } else { \
      q_abandoned##IDX = 1u; \
      return; \
    } \
  } \
  if (val != MPMC_UNB2 && val != MPMC_DELETED) { \
    assert(val == (VAL)); \
    assert(q_data##IDX == (PAYLOAD)); \
    q_slot##IDX = MPMC_DELETED; \
    q_seen##IDX++; \
    assert(q_seen##IDX == 1u); \
  } \
}

#ifdef MUTANT_3
#define MPMC_REL_ENQ false
#else
#define MPMC_REL_ENQ true
#endif

#ifdef MUTANT_4
#define MPMC_CANCEL_SENTINEL false
#else
#define MPMC_CANCEL_SENTINEL true
#endif

DEFINE_MPMC_SLOT(0, 1u, 100u)
DEFINE_MPMC_SLOT(1, 2u, 101u)
DEFINE_MPMC_SLOT(2, 3u, 102u)
DEFINE_MPMC_SLOT(3, 4u, 103u)

/* =========================================================================
 * Protocol C: Overflow-Free Fast Rest Grant & Small-Key Scratch Contract
 * ========================================================================= */

#define MAX_NB_PARMS_MODEL 1024u
#define KEY_SMALL_CAP      32u

static bool exact_ref_rest_grant(int64_t pending, int64_t np, int64_t stack_slots,
                                 uint64_t sd, uint64_t stack_limit_b,
                                 uint64_t hd, uint64_t heap_bytes) {
  if (pending < 0 || np < 0 || stack_slots < 0) return false;
  if (pending > (INT64_MAX / 3)) return false;
  int64_t pairs = (pending << 1) + pending;
  if (pairs > INT64_MAX - np) return false;
  int64_t payload = pairs + np;
  if (payload > INT64_MAX - 1) return false;
  uint64_t words = (uint64_t)(payload + 1);
  if (sd >= stack_limit_b) return false;
  if ((sd >> 3) < (uint64_t)stack_slots) return false;
  if (hd >= heap_bytes) return false;
  if (((heap_bytes - hd) >> 3) < words) return false;
  return true;
}

static bool wave16_fast_rest_grant(int64_t pending, int64_t np, int64_t stack_slots,
                                   uint64_t sd, uint64_t stack_limit_b,
                                   uint64_t hd, uint64_t heap_bytes) {
#ifdef MUTANT_5
  if (pending >= 0 && np >= 0 && stack_slots >= 0) {
    uint64_t p_u = (uint64_t)pending;
    uint64_t words = (p_u << 1) + p_u + (uint64_t)np + 1u;
    if (sd < stack_limit_b && sd >= ((uint64_t)stack_slots << 3) &&
        hd < heap_bytes && (heap_bytes - hd) >= (words << 3)) {
      return true;
    }
  }
  return false;
#else
  if ((uint64_t)pending <= MAX_NB_PARMS_MODEL &&
      (uint64_t)np <= MAX_NB_PARMS_MODEL &&
      (uint64_t)stack_slots <= (2u * MAX_NB_PARMS_MODEL + 2u)) {
    uint64_t p_u = (uint64_t)pending;
    uint64_t words = (p_u << 1) + p_u + (uint64_t)np + 1u;
    if (sd < stack_limit_b && sd >= ((uint64_t)stack_slots << 3) &&
        hd < heap_bytes && (heap_bytes - hd) >= (words << 3)) {
      return true;
    }
    return false;
  }
  return exact_ref_rest_grant(pending, np, stack_slots, sd, stack_limit_b, hd, heap_bytes);
#endif
}

static void verify_rest_grant_and_key_scratch(void) {
  int64_t pending = nondet_i64();
  int64_t np = nondet_i64();
  int64_t stack_slots = nondet_i64();
  uint64_t sd = nondet_u64();
  uint64_t stack_limit_b = nondet_u64();
  uint64_t hd = nondet_u64();
  uint64_t heap_bytes = nondet_u64();

  bool ref = exact_ref_rest_grant(pending, np, stack_slots, sd, stack_limit_b, hd, heap_bytes);
  bool fast = wave16_fast_rest_grant(pending, np, stack_slots, sd, stack_limit_b, hd, heap_bytes);
  assert(fast == ref);

  unsigned int nb_key = nondet_uint();
  __CPROVER_assume(nb_key <= MAX_NB_PARMS_MODEL);
  bool uses_small = (nb_key <= KEY_SMALL_CAP);
  unsigned int cap = uses_small ? KEY_SMALL_CAP : nb_key;
  assert(cap >= nb_key);
}

static void thread_entry(unsigned int tid, unsigned int mode) {
  if (mode == 0u) {
    if (tid == 0u) futex_t0_initial_holder();
    else if (tid == 1u) futex_sleeper_worker(1u);
    else if (tid == 2u) futex_sleeper_worker(2u);
    else if (tid == 3u) futex_fast_thief(3u, true);
    else if (tid == 4u) futex_fast_thief(4u, false);
    else if (tid == 5u) futex_escalator();
    else if (tid == 6u) futex_escalator();
    else futex_fast_thief(7u, false);
  } else if (mode == 1u) {
    if (tid == 0u) mpmc_prod_0();
    else if (tid == 1u) mpmc_prod_1();
    else if (tid == 2u) mpmc_prod_2();
    else if (tid == 3u) mpmc_prod_3();
    else if (tid == 4u) mpmc_cons_0();
    else if (tid == 5u) mpmc_cons_1();
    else if (tid == 6u) mpmc_cons_2();
    else mpmc_cons_3();
  } else if (tid == 7u) {
    verify_rest_grant_and_key_scratch();
  }
}

int main(void) {
  unsigned int mode = nondet_uint();
  __CPROVER_assume(mode < 3u);
  __CPROVER_ASYNC_0: thread_entry(0u, mode);
  __CPROVER_ASYNC_1: thread_entry(1u, mode);
  __CPROVER_ASYNC_2: thread_entry(2u, mode);
  __CPROVER_ASYNC_3: thread_entry(3u, mode);
  __CPROVER_ASYNC_4: thread_entry(4u, mode);
  __CPROVER_ASYNC_5: thread_entry(5u, mode);
  __CPROVER_ASYNC_6: thread_entry(6u, mode);
  thread_entry(7u, mode);
  return 0;
}
