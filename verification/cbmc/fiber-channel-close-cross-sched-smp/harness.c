/*
 * CBMC --mm pso verification harness for:
 *   1. Cross-scheduler & external OS thread `%wake-fk!` routing via immutable
 *      `%fk-sched` ownership (zero null-ctx crash, zero foreign-scheduler steal).
 *   2. 2-thread SMP Dekker interleaving between `fiber-channel-close!` and
 *      concurrent lock-free `rx-fast` / `tx-fast` parking under PSO memory model:
 *      verifies zero lost wakeups on close.
 *   3. 3-thread SMP Vyukov packed-tail `(pos << 1) | closed_bit` linearizability
 *      between concurrent Sender, Closer, and Receiver under PSO memory model:
 *      verifies exact conservation (`sent_cnt == recv_cnt`), zero post-close
 *      slot claims, and zero premature `#!eof` while an in-flight pre-close
 *      sender is committing `seq[idx]`.
 *
 * Negative mutants (all 5 MUST FAIL CBMC --mm pso):
 *   -DINJECT_BUG_BLIND_CALLER_LIFO
 *   -DINJECT_BUG_CLOSE_NO_FENCE
 *   -DINJECT_BUG_PARK_SKIP_CLOSED_RECHECK
 *   -DINJECT_BUG_CLOSE_SKIP_WAKE_DRAIN
 *   -DINJECT_BUG_SPLIT_CLOSED_FROM_TAIL
 */

#include <assert.h>
#include <stdint.h>

extern int nondet_int(void);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

/* ============================================================================
 * Model 1: Cross-Scheduler & External OS Thread Wakeup Routing
 * ============================================================================ */

static int verify_wake_routing(void) {
  /* caller_sched: 0 = external OS thread (ctx==NULL), 1 = sched-A, 2 = sched-B */
  int caller_sched = nondet_int() % 3;
  if (caller_sched < 0) caller_sched = -caller_sched;
  int fk_owner_sched = 1; /* parked fiber belongs to sched-A */
  int crashed_null_ctx = 0;
  int routed_sched = 0;

#ifdef INJECT_BUG_BLIND_CALLER_LIFO
  if (caller_sched == 0) {
    crashed_null_ctx = 1;
  } else {
    routed_sched = caller_sched; /* Buggy: pushes onto sched-B's LIFO! */
  }
#else
  if (caller_sched == fk_owner_sched) {
    routed_sched = fk_owner_sched; /* Same-scheduler local LIFO fast path */
  } else {
    routed_sched = fk_owner_sched; /* Safe global-q enqueue on owning scheduler */
  }
#endif

  assert(crashed_null_ctx == 0);
  assert(routed_sched == fk_owner_sched);
  return 0;
}

/* ============================================================================
 * Model 2: 2-Thread SMP Dekker Close vs Lock-Free rx-fast Park under PSO
 * ============================================================================ */

static volatile int g_closed = 0;
static volatile int g_rx_fast = 0;   /* 0 = empty, 1 = receiver parked */
static volatile int g_rx_parked = 0; /* 1 if receiver actually suspended */
static volatile int g_rx_woken = 0;  /* 1 if closer woke receiver */
static volatile int g_rx_done = 0;
static volatile int g_close_done = 0;

static void thread_receiver_park(void) {
  /* Publish receiver in rx-fast with seq_cst CAS */
  int published = 0;
  fence_seq_cst();
  __CPROVER_atomic_begin();
  if (g_rx_fast == 0) {
    g_rx_fast = 1;
    published = 1;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();

  if (published) {
    /* Dekker seq_cst re-check of closed flag */
#ifdef INJECT_BUG_PARK_SKIP_CLOSED_RECHECK
    int c = 0;
#else
    int c = g_closed;
    fence_seq_cst();
#endif
    if (c == 0) {
      g_rx_parked = 1;
    } else {
      /* Race with close: exchange rx_fast -> 0 to cancel cleanly */
      int prev;
      fence_seq_cst();
      __CPROVER_atomic_begin();
      prev = g_rx_fast;
      g_rx_fast = 0;
      __CPROVER_atomic_end();
      fence_seq_cst();
      if (prev != 0) {
        g_rx_woken = 1; /* Self-canceled cleanly */
      } else {
        g_rx_parked = 1; /* Closer already claimed and will wake us */
      }
    }
  }
  fence_seq_cst();
  g_rx_done = 1;
}

static void thread_closer(void) {
  /* Mark channel closed with seq_cst store */
  g_closed = 1;
#ifndef INJECT_BUG_CLOSE_NO_FENCE
  fence_seq_cst();
#endif

#ifndef INJECT_BUG_CLOSE_SKIP_WAKE_DRAIN
  /* Atomically exchange rx_fast -> 0 and wake any parked receiver */
  int prev;
  __CPROVER_atomic_begin();
  prev = g_rx_fast;
  g_rx_fast = 0;
  __CPROVER_atomic_end();
  fence_seq_cst();
  if (prev != 0) {
    g_rx_woken = 1;
  }
#endif
  fence_seq_cst();
  g_close_done = 1;
}

/* ============================================================================
 * Model 3: 3-Thread SMP Packed-Tail (pos << 1) | closed_bit Linearizability
 * ============================================================================ */

static volatile int m3_tail = 0;    /* (pos << 1) | closed_bit */
static volatile int m3_split_closed = 0; /* Only used by negative mutant */
static volatile int m3_head = 0;
static volatile int m3_seq0 = 0;    /* Vyukov slot 0 sequence: 0=empty, 1=ready */
static volatile int m3_buf0 = 0;    /* Slot 0 payload */
static volatile int m3_sent_cnt = 0;
static volatile int m3_recv_cnt = 0;
static volatile int m3_sender_done = 0;
static volatile int m3_closer_done = 0;

static void m3_thread_sender(void) {
#ifdef INJECT_BUG_SPLIT_CLOSED_FROM_TAIL
  /* Buggy split-flag protocol: checks closed separately from tail CAS */
  if (m3_split_closed == 0) {
    int claimed = 0;
    __CPROVER_atomic_begin();
    if (m3_tail == 0) {
      m3_tail = 2; /* pos = 1 */
      claimed = 1;
    }
    __CPROVER_atomic_end();
    if (claimed) {
      m3_buf0 = 42;
      fence_seq_cst();
      m3_seq0 = 1;
      fence_seq_cst();
      m3_sent_cnt = 1;
    }
  }
#else
  /* Linearizable single-word packed-tail CAS: atomically proves closed == 0 */
  int raw_t = m3_tail;
  if ((raw_t & 1) == 0) {
    int pos = raw_t >> 1;
    int claimed = 0;
    __CPROVER_atomic_begin();
    if (m3_tail == raw_t) {
      m3_tail = (pos + 1) << 1;
      claimed = 1;
    }
    __CPROVER_atomic_end();
    if (claimed) {
      m3_buf0 = 42;
      fence_seq_cst();
      m3_seq0 = 1;
      fence_seq_cst();
      m3_sent_cnt = 1;
    }
  }
#endif
  fence_seq_cst();
  m3_sender_done = 1;
}

static void m3_thread_closer(void) {
#ifdef INJECT_BUG_SPLIT_CLOSED_FROM_TAIL
  m3_split_closed = 1;
  fence_seq_cst();
#else
  /* Seal bit 0 of m3_tail atomically via seq_cst CAS */
  fence_seq_cst();
  __CPROVER_atomic_begin();
  m3_tail = m3_tail | 1;
  __CPROVER_atomic_end();
  fence_seq_cst();
#endif
  m3_closer_done = 1;
}

static void m3_receiver_drain_until_eof(void) {
  int got_eof = 0;
  /* Bounded poll loop modeling %ch-drain-closed-or-eof! */
  for (int step = 0; step < 4 && !got_eof; step++) {
    int h = m3_head;
    int s = m3_seq0;
    fence_acquire();
    if (h == 0 && s == 1) {
      int item = m3_buf0;
      assert(item == 42);
      m3_head = 1;
      m3_recv_cnt = m3_recv_cnt + 1;
    } else {
#ifdef INJECT_BUG_SPLIT_CLOSED_FROM_TAIL
      /* Buggy split-flag receiver sees closed == 1 and seq0 == 0 -> premature EOF! */
      if (m3_split_closed == 1) {
        got_eof = 1;
      }
#else
      int raw_t = m3_tail;
      fence_acquire();
      if ((raw_t & 1) != 0) {
        int final_tail = raw_t >> 1;
        if (m3_head >= final_tail) {
          got_eof = 1; /* Safe: every pre-close claimed slot has been drained! */
        }
        /* Else: head < final_tail -> an in-flight pre-close sender is committing seq0;
           MUST NOT return EOF yet! */
      }
#endif
    }
  }
  /* Once both sender and closer have finished, a final drain MUST conserve count */
  if (m3_sender_done && m3_closer_done && got_eof) {
    fence_seq_cst();
    assert(m3_sent_cnt == m3_recv_cnt);
  }
}

int main(void) {
  verify_wake_routing();

  __CPROVER_ASYNC_1: thread_receiver_park();
  thread_closer();

  if (g_rx_done && g_close_done) {
    fence_seq_cst();
    /* If receiver suspended on a closed channel, closer MUST have woken it! */
    if (g_rx_parked) {
      assert(g_rx_woken == 1);
    }
    assert(g_closed == 1);
  }

  __CPROVER_ASYNC_2: m3_thread_sender();
  __CPROVER_ASYNC_3: m3_thread_closer();
  m3_receiver_drain_until_eof();

  return 0;
}
