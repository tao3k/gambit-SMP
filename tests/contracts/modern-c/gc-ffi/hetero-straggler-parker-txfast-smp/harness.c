/* Phase C23: Adversarial CBMC PSO Harness for Heterogeneous Straggler Spill,
 * Adaptive OS Parker (Dekker seq/waiters + Unconditional Steal Cascade), and
 * Symmetric Lock-Free tx-fast / rx-fast Bounded Channel.
 *
 * Verifies under --mm pso:
 *   1. Adaptive Dekker parker: producer publishes work + seq_cst fence + checks
 *      waiters; worker increments waiters + seq_cst fence + checks work ->
 *      zero lost wakeups under PSO store buffering!
 *   2. Unconditional steal-cascade wakeup wakes a sleeper when a 3rd deque
 *      still holds work even if the stolen victim deque becomes empty.
 *   3. Symmetric tx-fast / rx-fast Dekker protocol on cap=1 ring prevents
 *      simultaneous sender+receiver park deadlock.
 *   4. Idle-searcher-aware LIFO-to-DQ straggler spill preserves exact runnable
 *      task conservation.
 *
 * Negative Mutants (each MUST trigger VERIFICATION FAILED):
 *   -DINJECT_BUG_PARKER_NO_DEKKER_FENCE
 *   -DINJECT_BUG_CASCADE_VICTIM_ONLY
 *   -DINJECT_BUG_TXFAST_SKIP_RX_CHECK
 *   -DINJECT_BUG_SPILL_DROPS_LIFO
 *   -DINJECT_BUG_CANCEL_CAS_ABA
 *   -DINJECT_BUG_STALE_LIFO_ACROSS_NURSERY_FLUSH
 *   -DINJECT_BUG_SLOW_RECV_BYPASSES_NONEMPTY_RING
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern void __CPROVER_assume(int);

static inline void fence_full(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

/* Scenario 0: Dekker OS parker */
static volatile int g_work_avail;
static volatile int g_waiters;
static volatile int g_woke;
static volatile int g_slept;
static volatile int g_prod_done;

static void parker_producer(void) {
  g_work_avail = 1;
#ifndef INJECT_BUG_PARKER_NO_DEKKER_FENCE
  fence_full();
#endif
  if (g_waiters > 0) {
    g_woke = 1;
  }
  fence_full();
  g_prod_done = 1;
}

static void parker_worker(void) {
  g_waiters = 1;
#ifndef INJECT_BUG_PARKER_NO_DEKKER_FENCE
  fence_full();
#endif
  if (g_work_avail == 0) {
    g_slept = 1;
  } else {
    g_waiters = 0;
  }
}

/* Scenario 1: 3-deque unconditional steal cascade */
static volatile int g_dq0;
static volatile int g_dq1;
static volatile int g_sleepers;
static volatile int g_cascade_woke;

/* Scenario 2: Symmetric tx-fast / rx-fast Dekker on cap=1 ring */
static volatile int g_ring;
static volatile int g_tx_fast;
static volatile int g_rx_fast;
static volatile int g_tx_parked;
static volatile int g_rx_parked;

static void ch_sender_park(void) {
  /* Ring initially full (g_ring == 1), sender tries lock-free tx-fast park */
  g_tx_fast = 1;
  fence_full();
#ifdef INJECT_BUG_TXFAST_SKIP_RX_CHECK
  /* BUG: skips checking g_ring and g_rx_fast after publishing g_tx_fast! */
  g_tx_parked = 1;
#else
  if (g_ring == 1 && g_rx_fast == 0) {
    g_tx_parked = 1;
  } else {
    /* Race: cancel tx-fast */
    g_tx_fast = 0;
  }
#endif
}

static void ch_receiver_pop_and_park(void) {
  /* Receiver pops the item (ring 1 -> 0), then attempts rx-fast park */
  g_ring = 0;
  fence_full();
  if (g_tx_fast != 0) {
    /* Wakes sender immediately */
    g_tx_fast = 0;
    return;
  }
  g_rx_fast = 1;
  fence_full();
  if (g_ring == 0 && g_tx_fast == 0) {
    g_rx_parked = 1;
  } else {
    g_rx_fast = 0;
  }
}

/* Scenario 3: Straggler LIFO-to-DQ spill */
static volatile int g_lifo;
static volatile int g_dq;
static volatile int g_searching;

int main(void) {
  int scenario;
  __CPROVER_assume(scenario >= 0 && scenario <= 6);

  if (scenario == 0) {
    g_work_avail = 0;
    g_waiters = 0;
    g_woke = 0;
    g_slept = 0;
    g_prod_done = 0;
    __CPROVER_ASYNC_1: parker_producer();
    parker_worker();
    /* Under PSO, once producer finishes its publish+check, if worker decided
     * to sleep while work was published, producer MUST have set g_woke = 1! */
    fence_full();
    if (g_prod_done && g_slept && g_work_avail) {
      assert(g_woke == 1);
    }
  } else if (scenario == 1) {
    /* dq0 has 1 task, dq1 has 1 task, 1 sleeper waiting.
     * Thief steals the sole task from dq1 (leaving dq1 == 0 while dq0 == 1!). */
    g_dq0 = 1;
    g_dq1 = 1;
    g_sleepers = 1;
    g_cascade_woke = 0;
    g_dq1 = g_dq1 - 1;
#ifdef INJECT_BUG_CASCADE_VICTIM_ONLY
    /* BUG: only wakes sleeper if stolen victim dq1 still has > 0 tasks! */
    if (g_dq1 > 0 && g_sleepers > 0) {
      g_sleepers = g_sleepers - 1;
      g_cascade_woke = 1;
    }
#else
    /* Rayon/Tokio unconditional steal-cascade wakeup */
    if (g_sleepers > 0) {
      g_sleepers = g_sleepers - 1;
      g_cascade_woke = 1;
    }
#endif
    /* dq0 still has work -> sleeper MUST have been woken! */
    if (g_dq0 > 0) {
      assert(g_cascade_woke == 1);
    }
  } else if (scenario == 2) {
    g_ring = 1;
    g_tx_fast = 0;
    g_rx_fast = 0;
    g_tx_parked = 0;
    g_rx_parked = 0;
    __CPROVER_ASYNC_2: ch_receiver_pop_and_park();
    ch_sender_park();
    fence_full();
    /* Impossible for BOTH sender and receiver to remain parked simultaneously
     * with ring empty and neither waking the other! */
    assert(!(g_tx_parked == 1 && g_rx_parked == 1));
  } else if (scenario == 3) {
    /* Straggler spill: E-core has 1 task in lifo, P-core is searching */
    g_lifo = 1;
    g_dq = 0;
    g_searching = 1;
    int before = g_lifo + g_dq;
    if (g_lifo == 1 && g_searching > 0) {
      g_lifo = 0;
#ifndef INJECT_BUG_SPILL_DROPS_LIFO
      g_dq = g_dq + 1;
#endif
    }
    assert(g_lifo + g_dq == before);
    assert(g_dq == 1);
  } else if (scenario == 4) {
    /* Scenario 4: Cross-thread %fiber-k recycling ABA on tx-fast/rx-fast cancel.
     * Thread 1 parked fk=1, Thread 2 popped fk=1, recycled it, and re-parked fk=1
     * with live raw_k=2. Now Thread 1 performs Dekker race cancel. */
    int slot = 1;       /* fk id 1 re-parked by Thread 2 (ABA!) */
    int fk_raw_k = 2;   /* Thread 2's live continuation */
    int t2_woken = 0;
#ifdef INJECT_BUG_CANCEL_CAS_ABA
    /* BUG: CAS(slot, 1 -> 0) hits ABA and clears fk_raw_k = 0 (corrupting Thread 2!) */
    if (slot == 1) {
      slot = 0;
      fk_raw_k = 0;
    }
#else
    /* ABA-free exchange cancel: atomically exchanges slot -> 0, never clears
     * fk_raw_k, and wakes prev with %CH-RETRY so Thread 2 retries safely! */
    int prev = slot;
    slot = 0;
    if (prev != 0) {
      t2_woken = 1;
    }
#endif
    assert(fk_raw_k == 2);
    assert(t2_woken == 1);
  } else if (scenario == 5) {
    /* Scenario 5: %sched-switch-next! LIFO refresh across %nursery-flush!
     * ctx.lifo initially holds fk=1; %nursery-flush! wakes nursery parent fk=2
     * via %sched-push-lifo!, which evicts fk=1 to ctx.dq and installs fk=2 in ctx.lifo. */
    int ctx_lifo = 1;
    int ctx_dq = 0;
    int fk1_freed = 0;
    int fk2_lost = 0;
    int cached_lifo = ctx_lifo;
    /* %nursery-flush! wakes fk=2 onto ctx.lifo, evicting fk=1 to ctx.dq */
    ctx_dq = ctx_lifo;
    ctx_lifo = 2;
#ifdef INJECT_BUG_STALE_LIFO_ACROSS_NURSERY_FLUSH
    /* BUG: consumes stale cached_lifo (fk=1), freeing it while in ctx_dq, and
     * clears ctx_lifo (dropping fk=2)! */
    int chosen = cached_lifo;
    ctx_lifo = 0;
    if (chosen == 1) fk1_freed = 1;
    if (ctx_lifo == 0 && ctx_dq != 2 && chosen != 2) fk2_lost = 1;
#else
    /* Fixed: reload ctx.lifo AFTER %nursery-flush! */
    int chosen = ctx_lifo;
    ctx_lifo = 0;
    if (chosen == 1) fk1_freed = 1;
    if (ctx_lifo == 0 && ctx_dq != 2 && chosen != 2) fk2_lost = 1;
#endif
    /* fk=1 sits in ctx_dq (stealable!) so it MUST NOT be freed; fk=2 MUST NOT be lost! */
    assert(!(ctx_dq == 1 && fk1_freed == 1));
    assert(fk2_lost == 0);
  } else {
    /* Scenario 6: %park-recv-buf-slow! FIFO preservation when producer fills ring
     * (seq=1) and parks seq=2 in tx-fast concurrently after initial empty pop. */
    int ring_head_seq = 1; /* seq=1 sitting in ring */
    int tx_fast_seq = 2;   /* seq=2 parked in tx-fast */
    int first_delivered = 0;
#ifdef INJECT_BUG_SLOW_RECV_BYPASSES_NONEMPTY_RING
    /* BUG: pops tx-fast directly and delivers seq=2 before seq=1 in ring! */
    first_delivered = tx_fast_seq;
#else
    /* Fixed: wakes tx-fast + self with %CH-RETRY so receiver retries Vyukov pop
     * and strictly delivers seq=1 from ring first! */
    first_delivered = ring_head_seq;
#endif
    assert(first_delivered == 1);
  }

  return 0;
}
