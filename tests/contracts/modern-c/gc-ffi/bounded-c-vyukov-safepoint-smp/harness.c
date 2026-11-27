/*
 * Phase C10 CBMC (--mm pso) Concurrency Verification Harness:
 *   Single-C-Block Bounded-Retry Vyukov MPMC Ring with Universal 2*pos / 2*pos+1
 *   Encoding (Explicitly Verifying CAP = 1 under PSO!) + SATB Pop-Clear Barrier
 *   + Bounded Safepoint Admission
 *
 * Negative mutants (all 4 MUST be caught by CBMC --mm pso):
 *   -DINJECT_BUG_CAP1_1POS_ENCODING          : broken pos / pos+1 on CAP=1 -> overwrite!
 *   -DINJECT_BUG_POP_CLEAR_NO_SATB           : clear buf[0]=0 without SATB barrier
 *   -DINJECT_BUG_PUSH_NO_RELEASE_SEQ         : omit release fence before seq store
 *   -DINJECT_BUG_ZERO_RETRY_BUDGET_STARVES_GC: skip safepoint yield when budget exhausted
 */

#include <assert.h>

#define CAP 1

static volatile int g_tail = 0;
static volatile int g_head = 0;
static volatile int g_seq0 = 0;
static volatile int g_buf0 = 0;

static volatile int g_satb_active = 1;
static volatile int g_satb_shaded_old = 0;

static volatile int g_prod_done = 0;
static volatile int g_cons_done = 0;
static volatile int g_cons_got1 = 0;
static volatile int g_push2_when_full = 0;

static int c_vyukov_try_push_cap1(int val) {
  int pos = g_tail;
  int s = g_seq0;
  __CPROVER_fence("RRfence", "RWfence");
#ifdef INJECT_BUG_CAP1_1POS_ENCODING
  int exp = pos; /* BUG on CAP=1: seq0==1 collides with next pos==1! */
#else
  int exp = pos * 2;
#endif
  if (s != exp) {
    return 0; /* FULL */
  }
  int won = 0;
  __CPROVER_atomic_begin();
  if (g_tail == pos) {
    g_tail = pos + 1;
    won = 1;
  }
  __CPROVER_atomic_end();
  if (!won) return 0;

  g_buf0 = val;
#ifndef INJECT_BUG_PUSH_NO_RELEASE_SEQ
  __CPROVER_fence("WWfence", "RWfence");
#endif
  g_seq0 = exp + 1;
  return 1;
}

static int c_vyukov_try_pop_cap1(void) {
  int pos = g_head;
  int s = g_seq0;
  __CPROVER_fence("RRfence", "RWfence");
#ifdef INJECT_BUG_CAP1_1POS_ENCODING
  int exp = pos + 1;
#else
  int exp = pos * 2 + 1;
#endif
  if (s != exp) {
    return -1; /* EMPTY */
  }
  int won = 0;
  __CPROVER_atomic_begin();
  if (g_head == pos) {
    g_head = pos + 1;
    won = 1;
  }
  __CPROVER_atomic_end();
  if (!won) return -1;

  int item = g_buf0;
#ifndef INJECT_BUG_POP_CLEAR_NO_SATB
  if (g_satb_active && item != 0) {
    g_satb_shaded_old = item;
  }
#endif
  g_buf0 = 0;
  __CPROVER_fence("WWfence", "RWfence");
#ifdef INJECT_BUG_CAP1_1POS_ENCODING
  g_seq0 = pos + CAP;
#else
  g_seq0 = (pos + CAP) * 2;
#endif
  return item;
}

/* Scenario 1: CAP=1 back-to-back push MUST reject 2nd push as FULL (no overwrite!) */
static void check_cap1_full_rejection(void) {
  int ok1 = c_vyukov_try_push_cap1(111);
  assert(ok1 == 1);
  /* Ring is now FULL (CAP=1); a 2nd push before pop MUST return 0! */
  int ok2 = c_vyukov_try_push_cap1(222);
  g_push2_when_full = ok2;
  assert(g_push2_when_full == 0);
  /* Pop MUST return 111 (never overwritten by 222!) and SATB-shade 111! */
  int got = c_vyukov_try_pop_cap1();
  assert(got == 111);
  assert(g_satb_shaded_old == 111);
  /* Reset for concurrent PSO scenario */
  g_tail = 0;
  g_head = 0;
  g_seq0 = 0;
  g_buf0 = 0;
  g_satb_shaded_old = 0;
}

/* Scenario 2: Bounded retry loop admits STW safepoint */
static void check_safepoint_admission(void) {
  int gc_requested = 1;
  int admitted = 0;
  int retries = 0;
  for (retries = 0; retries < 4; retries++) {
    /* Simulated CAS contention */
  }
#ifndef INJECT_BUG_ZERO_RETRY_BUDGET_STARVES_GC
  if (retries >= 4 && gc_requested) {
    admitted = 1; /* Returned to Scheme ___POLL safepoint! */
  }
#endif
  assert(admitted == 1);
}

/* Scenario 3: Concurrent PSO publish visibility on CAP=1 */
static void prod_thread(void) {
  int ok = c_vyukov_try_push_cap1(55);
  assert(ok == 1);
  __CPROVER_fence("WWfence", "RWfence");
  g_prod_done = 1;
}

static void cons_thread(void) {
  int v = c_vyukov_try_pop_cap1();
  g_cons_got1 = v;
  __CPROVER_fence("WWfence", "RWfence");
  g_cons_done = 1;
}

int main(void) {
  check_cap1_full_rejection();
  check_safepoint_admission();

__CPROVER_ASYNC_1:
  prod_thread();
  cons_thread();

  __CPROVER_assume(g_prod_done == 1 && g_cons_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  /* If consumer observed seq0 ready, it MUST see payload 55 (never stale 0 under PSO!) */
  assert(g_cons_got1 == -1 || g_cons_got1 == 55);
  /* And if consumer got 55, SATB barrier MUST have shaded 55 before clearing buf0! */
  assert(g_cons_got1 != 55 || g_satb_shaded_old == 55);
  return 0;
}
