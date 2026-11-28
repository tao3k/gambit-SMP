/*
 * Phase C17 CBMC PSO Adversarial Verification Harness:
 *   1. Lock-free rx-fast slot Dekker park + cancel-vs-claim CAS race under PSO
 *   2. Linearizable empty-ring guard (`tail == head`) prevents FIFO bypass
 *   3. Symmetric Dekker guard between full-ring sender park (`txw`) and `rx-fast`
 *
 * Negative Mutants (each MUST FAIL under `cbmc --mm pso --unwind 4`):
 *   -DINJECT_BUG_RXFAST_NO_DEKKER_FENCE
 *   -DINJECT_BUG_RXFAST_CANCEL_RECYCLES_ON_CAS_FAIL
 *   -DINJECT_BUG_RXFAST_DIRECT_HANDOFF_IGNORES_NONEMPTY_RING
 *   -DINJECT_BUG_PARK_SEND_IGNORES_RXFAST
 */

#include <assert.h>

extern void __CPROVER_fence(const char *kind, ...);
extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_assume(_Bool);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}
static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence");
}
static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

/* ============================================================================
 * Scenario 1: Lock-free rx-fast park + cancel-vs-claim CAS race vs Vyukov push
 * ============================================================================ */
static int s1_seq0 = 0;       /* 0 = empty, 1 = ready */
static int s1_buf0 = -1;
static int s1_rx_fast = 0;    /* 0 = empty, 1 = fk1 */
static int s1_fk1_val = -1;
static int s1_fk1_resumes = 0; /* MUST be == 1 (never 0 lost, never 2 double!) */
static int s1_prod_done = 0;
static int s1_cons_done = 0;

static int cas_s1_rx_fast(int expected, int desired, int sc) {
  int prev;
  if (sc) fence_seq_cst();
  __CPROVER_atomic_begin();
  prev = s1_rx_fast;
  if (prev == expected) s1_rx_fast = desired;
  __CPROVER_atomic_end();
  if (sc) fence_seq_cst();
  return prev;
}

static void s1_sender_vyukov_and_wake(void) {
  /* Vyukov push slot 0 */
  s1_buf0 = 88;
#ifdef INJECT_BUG_RXFAST_NO_DEKKER_FENCE
  s1_seq0 = 1; /* BUG: relaxed store without seq_cst Dekker ordering */
  int rk = s1_rx_fast;
#else
  fence_seq_cst();
  s1_seq0 = 1;
  fence_seq_cst();
  int rk = s1_rx_fast;
  fence_seq_cst();
#endif
  if (rk == 1) {
    if (cas_s1_rx_fast(1, 0, 1) == 1) {
      /* Exclusive ownership of fk1: pop item and resume fk1 */
      int item = s1_buf0;
      s1_fk1_val = item;
      __CPROVER_atomic_begin();
      s1_fk1_resumes += 1;
      __CPROVER_atomic_end();
    }
  }
  fence_release();
  s1_prod_done = 1;
}

static void s1_receiver_lockfree_park(void) {
  /* Fast recv saw empty -> publish fk1 into rx_fast */
#ifdef INJECT_BUG_RXFAST_NO_DEKKER_FENCE
  s1_rx_fast = 1; /* BUG: relaxed publish without seq_cst Dekker ordering */
  int s = s1_seq0;
#else
  int prev = cas_s1_rx_fast(0, 1, 1);
  assert(prev == 0);
  int s = s1_seq0;
  fence_seq_cst();
#endif
  if (s == 1) {
    /* Race: item arrived! Attempt lock-free cancel CAS(rx_fast, 1 -> 0) */
    int cprev = cas_s1_rx_fast(1, 0, 1);
#ifdef INJECT_BUG_RXFAST_CANCEL_RECYCLES_ON_CAS_FAIL
    /* BUG: ignores CAS failure and consumes/resumes fk1 anyway -> double resume! */
    (void)cprev;
    fence_acquire();
    s1_fk1_val = s1_buf0;
    __CPROVER_atomic_begin();
    s1_fk1_resumes += 1;
    __CPROVER_atomic_end();
#else
    if (cprev == 1) {
      /* Cancel succeeded: consume item directly (fk1 resumed once) */
      fence_acquire();
      s1_fk1_val = s1_buf0;
      __CPROVER_atomic_begin();
      s1_fk1_resumes += 1;
      __CPROVER_atomic_end();
    }
    /* Else: sender already claimed fk1 and will resume it exactly once */
#endif
  }
  fence_release();
  s1_cons_done = 1;
}

/* ============================================================================
 * Scenario 2: Lock-free direct handoff respects tail == head (zero FIFO bypass)
 * ============================================================================ */
static void check_rxfast_fifo_linearizability(void) {
  int head = 0;
  int tail = 1;       /* item 100 already committed in ring */
  int ring0 = 100;
  int rx_fast = 1;    /* receiver parked concurrently */
  int delivered_first = -1;

#ifdef INJECT_BUG_RXFAST_DIRECT_HANDOFF_IGNORES_NONEMPTY_RING
  /* BUG: bypasses non-empty ring and hands 200 directly to rx_fast! */
  if (rx_fast == 1) {
    rx_fast = 0;
    delivered_first = 200;
  }
#else
  if (rx_fast == 1 && tail == head) {
    rx_fast = 0;
    delivered_first = 200;
  } else {
    /* Push 200 after 100, then wake rx_fast with oldest item ring[head] */
    rx_fast = 0;
    delivered_first = ring0;
    head = 1;
  }
#endif
  assert(delivered_first == 100);
}

/* ============================================================================
 * Scenario 3: Symmetric Dekker between full-ring sender park & rx-fast park
 * ============================================================================ */
static int s3_txw = 0;
static int s3_rx_fast = 0;
static int s3_tx_parked = 0;
static int s3_rx_parked = 0;
static int s3_t_done = 0;
static int s3_r_done = 0;

static void s3_sender_park_check(void) {
  fence_seq_cst();
  s3_txw = 1;
  fence_seq_cst();
#ifdef INJECT_BUG_PARK_SEND_IGNORES_RXFAST
  int rxf = 0; /* BUG: forgets to check rx_fast before parking sender! */
#else
  int rxf = s3_rx_fast;
  fence_seq_cst();
#endif
  if (rxf == 0) {
    s3_tx_parked = 1;
  } else {
    s3_txw = 0;
  }
  fence_release();
  s3_t_done = 1;
}

static void s3_receiver_park_check(void) {
  fence_seq_cst();
  s3_rx_fast = 1;
  fence_seq_cst();
  int txw = s3_txw;
  fence_seq_cst();
  if (txw == 0) {
    s3_rx_parked = 1;
  } else {
    s3_rx_fast = 0;
  }
  fence_release();
  s3_r_done = 1;
}

int main(void) {
  /* Scenario 1: Lock-free rx-fast Dekker + cancel-vs-claim race under PSO */
  __CPROVER_ASYNC_1: s1_sender_vyukov_and_wake();
  s1_receiver_lockfree_park();
  __CPROVER_assume(s1_prod_done == 1 && s1_cons_done == 1);
  fence_acquire();
  /* Must resume fk1 EXACTLY ONCE (no lost wakeup, no double wakeup) with val 88 */
  assert(s1_fk1_resumes == 1);
  assert(s1_fk1_val == 88);

  /* Scenario 2: Linearizable empty-ring guard */
  check_rxfast_fifo_linearizability();

  /* Scenario 3: Symmetric Dekker no mutual park deadlock */
  __CPROVER_ASYNC_2: s3_sender_park_check();
  s3_receiver_park_check();
  __CPROVER_assume(s3_t_done == 1 && s3_r_done == 1);
  fence_acquire();
  assert(!(s3_tx_parked == 1 && s3_rx_parked == 1));

  return 0;
}
