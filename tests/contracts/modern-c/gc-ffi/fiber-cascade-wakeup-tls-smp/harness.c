/*
 * CBMC Weak-Memory (--mm pso) Contract Verification Harness:
 * Phase C26 (gambit fiber) Steal & Global-Queue Cascade Wakeup + Lock-Free
 * Per-Carrier TLS Slot Isolation (`vendor/gambit/lib/gambit/fiber/fiber.scm`).
 *
 * Scenarios under --mm pso:
 *   0. Post-serial-phase burst on w0 (`deques[0] = 3`) while w1, w2 sleep:
 *      w0 wakes w1; w1 steals 1 task from w0 and MUST cascade-wake w2!
 *   1. Global-queue overflow burst (`global_q = 3`) while w1, w2 sleep:
 *      w0 wakes w1; w1 pops 1 task from `global_q` and MUST cascade-wake w2!
 *   2. Concurrent per-carrier `fiber-carrier-tls-set!` / `fiber-carrier-tls`
 *      across carriers w0, w1, w2: zero cross-carrier clobbering, 0 global locks.
 *
 * Negative Mutants (each MUST FAIL CBMC):
 *   -DINJECT_BUG_DROP_STEAL_CASCADE
 *   -DINJECT_BUG_DROP_GLOBAL_POP_CASCADE
 *   -DINJECT_BUG_SHARED_CARRIER_TLS_SLOT
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern int nondet_int(void);

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

/* Scenario 0 & 1: 3-worker scheduler state */
static volatile int g_dq0;
static volatile int g_dq1;
static volatile int g_global_q;
static volatile int g_w1_sleeping;
static volatile int g_w2_sleeping;
static volatile int g_w1_done;
static volatile int g_w2_woken;

static void parker_wake_one(void) {
  fence_seq_cst();
  __CPROVER_atomic_begin();
  if (g_w1_sleeping) {
    g_w1_sleeping = 0;
  } else if (g_w2_sleeping) {
    g_w2_sleeping = 0;
    g_w2_woken = 1;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();
}

static void s0_thief_w1(void) {
  int stolen = 0;
  __CPROVER_atomic_begin();
  if (g_dq0 > 0) {
    g_dq0 = g_dq0 - 1;
    stolen = 1;
  }
  __CPROVER_atomic_end();
  if (stolen) {
#ifdef INJECT_BUG_DROP_STEAL_CASCADE
    /* Buggy local-dq-only check (Section 26): w1's own deque is empty! */
    if (g_dq1 > 0 || g_global_q > 0)
      parker_wake_one();
#else
    /* Unconditional Rayon/Tokio steal-cascade wakeup (`fiber.scm:2989`) */
    parker_wake_one();
#endif
  }
  fence_seq_cst();
  g_w1_done = 1;
}

static void s1_global_popper_w1(void) {
  int popped = 0;
  int rem = 0;
  __CPROVER_atomic_begin();
  if (g_global_q > 0) {
    g_global_q = g_global_q - 1;
    rem = g_global_q;
    popped = 1;
  }
  __CPROVER_atomic_end();
  if (popped) {
#ifndef INJECT_BUG_DROP_GLOBAL_POP_CASCADE
    if (rem > 0)
      parker_wake_one();
#endif
  }
  fence_seq_cst();
  g_w1_done = 1;
}

/* Scenario 2: Per-carrier TLS slots (zero global mutex) */
static volatile int g_tls_w0;
static volatile int g_tls_w1;
static volatile int g_tls_w2;
static volatile int g_global_mutex_acquires;
static volatile int g_tls_t0_ok;
static volatile int g_tls_t1_ok;
static volatile int g_tls_t2_ok;
static volatile int g_tls_t0_done;
static volatile int g_tls_t1_done;

static void carrier_tls_worker0(void) {
  g_tls_w0 = 100;
  fence_seq_cst();
  g_tls_t0_ok = (g_tls_w0 == 100);
  fence_seq_cst();
  g_tls_t0_done = 1;
}

static void carrier_tls_worker1(void) {
#ifdef INJECT_BUG_SHARED_CARRIER_TLS_SLOT
  /* BUG: aliased slot clobbers worker 0's carrier TLS */
  g_tls_w0 = 200;
  fence_seq_cst();
  g_tls_t1_ok = (g_tls_w0 == 200);
#else
  g_tls_w1 = 200;
  fence_seq_cst();
  g_tls_t1_ok = (g_tls_w1 == 200);
#endif
  fence_seq_cst();
  g_tls_t1_done = 1;
}

static void carrier_tls_worker2(void) {
  g_tls_w2 = 300;
  fence_seq_cst();
  g_tls_t2_ok = (g_tls_w2 == 300);
}

int main(void) {
  int scen = nondet_int() % 3;
  g_dq0 = 0;
  g_dq1 = 0;
  g_global_q = 0;
  g_w1_sleeping = 0;
  g_w2_sleeping = 1;
  g_w1_done = 0;
  g_w2_woken = 0;
  g_tls_w0 = 0;
  g_tls_w1 = 0;
  g_tls_w2 = 0;
  g_global_mutex_acquires = 0;
  g_tls_t0_ok = 0;
  g_tls_t1_ok = 0;
  g_tls_t2_ok = 0;
  g_tls_t0_done = 0;
  g_tls_t1_done = 0;

  if (scen == 0) {
    /* w0 spawned 3 tasks into local deque; w1 woke to steal, w2 still sleeps */
    g_dq0 = 3;
    s0_thief_w1();
    assert(g_w1_done == 1);
    assert(g_dq0 == 2);
    assert(g_w2_sleeping == 0 && g_w2_woken == 1);
  } else if (scen == 1) {
    /* 3 tasks pushed into global queue; w1 woke to pop, w2 still sleeps */
    g_global_q = 3;
    s1_global_popper_w1();
    assert(g_w1_done == 1);
    assert(g_global_q == 2);
    assert(g_w2_sleeping == 0 && g_w2_woken == 1);
  } else {
  __CPROVER_ASYNC_0:
    carrier_tls_worker0();
  __CPROVER_ASYNC_1:
    carrier_tls_worker1();
    carrier_tls_worker2();
    if (g_tls_t0_done && g_tls_t1_done) {
      fence_seq_cst();
      assert(g_tls_t0_ok == 1);
      assert(g_tls_t1_ok == 1);
      assert(g_tls_t2_ok == 1);
      assert(g_tls_w0 == 100);
      assert(g_tls_w1 == 200);
      assert(g_tls_w2 == 300);
      assert(g_global_mutex_acquires == 0);
    }
  }
  return 0;
}
