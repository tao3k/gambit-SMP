/*
 * Phase C11 CBMC (--mm pso) Concurrency Verification Harness:
 *   1. Same-denv fast-path write-barrier skip in ___JUMP_CONTINUATION_RETURN_NO_WINDING2
 *   2. Single-copy_gate merged dest_room + chunk restore (fudge headroom & no nested locks)
 *   3. Fused C23 Dekker seq_cst park-recv vs Vyukov push (zero lost wakeup under PSO!)
 *
 * Negative mutants (all 4 MUST be caught by CBMC --mm pso):
 *   -DINJECT_BUG_SKIP_DENV_UPDATE_WHEN_DIFF : skip cache reset even when cur_denv != dst_denv
 *   -DINJECT_BUG_NO_FUDGE_RESERVE           : omit ___MSECTION_FUDGE reserve in merged dest_room
 *   -DINJECT_BUG_NESTED_COPY_GATE           : acquire dest gate while holding source gate
 *   -DINJECT_BUG_FUSED_PARK_NO_DEKKER_FENCE : omit seq_cst ordering in fused park-recv
 */

#include <assert.h>

/* 1. Same-denv cache skip check */
static void check_denv_fast_path(void) {
  int thread_denv = 1;
  int cache1_tag = 1;
  int cont_denv = 2;

#ifndef INJECT_BUG_SKIP_DENV_UPDATE_WHEN_DIFF
  if (thread_denv != cont_denv) {
    thread_denv = cont_denv;
    cache1_tag = cont_denv;
  }
#else
  /* BUG: updates thread_denv without resetting stale cache1_tag! */
  thread_denv = cont_denv;
#endif
  assert(thread_denv == cont_denv && cache1_tag == cont_denv);
}

/* 2. Merged single-copy_gate fudge headroom & single-gate invariant */
static void check_single_gate_restore(void) {
  int dest_lo = 100;
  int fudge = 16;
  int dest = 124; /* only 8 words above safe_lo = 116 */
  int safe_lo = dest_lo + fudge;
#ifdef INJECT_BUG_NO_FUDGE_RESERVE
  int dest_room = dest - dest_lo; /* BUG: 24 words, overruns fudge zone! */
#else
  int dest_room = (dest > safe_lo) ? (dest - safe_lo) : 0;
#endif
  int chunk_words = 12;
  int copied = (chunk_words <= dest_room) ? chunk_words : 0;
  int new_fp = dest - copied;
  assert(new_fp >= safe_lo);

  int gates_held = 0;
  /* Cross-section restore must release own gate before acquiring source gate */
  gates_held++; /* acquire own gate */
#ifndef INJECT_BUG_NESTED_COPY_GATE
  gates_held--; /* release own gate BEFORE acquiring source gate */
#endif
  gates_held++; /* acquire source gate */
  assert(gates_held <= 1);
}

/* 3. Fused C23 Dekker seq_cst park-recv vs Vyukov push (PSO concurrent check) */
static volatile int g_tail = 0;
static volatile int g_head = 0;
static volatile int g_seq0 = 0;
static volatile int g_buf0 = 0;
static volatile int g_lock = 0;
static volatile int g_rxw = 0;
static volatile int g_parked = 0;
static volatile int g_woke = 0;
static volatile int g_got = -1;
static volatile int g_p_done = 0;
static volatile int g_c_done = 0;

static void lock_wait(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (g_lock == 0) { g_lock = 1; ok = 1; }
  __CPROVER_atomic_end();
  __CPROVER_assume(ok == 1);
  __CPROVER_fence("RRfence", "RWfence");
}

static void unlock_wait(void) {
  __CPROVER_fence("WWfence", "RWfence");
  g_lock = 0;
}

static void fused_producer(void) {
  /* Vyukov push */
  g_tail = 1;
  g_buf0 = 77;
  __CPROVER_fence("WWfence", "RWfence");
  g_seq0 = 1;
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  if (g_rxw > 0) {
    lock_wait();
    if (g_parked) {
      g_parked = 0;
      g_rxw = 0;
      g_woke = 1;
    }
    unlock_wait();
  }
  __CPROVER_fence("WWfence", "RWfence");
  g_p_done = 1;
}

static void fused_consumer(void) {
  /* Fast check empty -> enter fused park-or-pop */
  int s0 = g_seq0;
  __CPROVER_fence("RRfence", "RWfence");
  if (s0 == 1) {
    g_got = g_buf0;
    __CPROVER_fence("WWfence", "RWfence");
    g_c_done = 1;
    return;
  }
  lock_wait();
  g_rxw = 1;
#ifndef INJECT_BUG_FUSED_PARK_NO_DEKKER_FENCE
  /* Models C23 store(seq_cst) on g_rxw ordered before load(seq_cst) on g_seq0 */
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
#endif
  int s1 = g_seq0;
  __CPROVER_fence("RRfence", "RWfence");
  if (s1 == 1) {
    g_rxw = 0;
    g_got = g_buf0;
  } else {
    g_parked = 1;
  }
  unlock_wait();
  __CPROVER_fence("WWfence", "RWfence");
  g_c_done = 1;
}

int main(void) {
  check_denv_fast_path();
  check_single_gate_restore();

__CPROVER_ASYNC_1:
  fused_producer();
  fused_consumer();

  __CPROVER_assume(g_p_done == 1 && g_c_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  assert(g_got == 77 || g_woke == 1);
  return 0;
}
