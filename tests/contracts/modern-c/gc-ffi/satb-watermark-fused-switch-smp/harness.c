/* Phase C22: Adversarial CBMC PSO Harness for SATB Stack-Watermark One-Shot
 * Rewind + Fused Send-to-LIFO + Zero-Hop Park-Recv Direct Switch.
 *
 * Verifies under --mm pso:
 *   1. When satb_active != 0, reclaiming a one-shot fiber continuation shades
 *      both ordinary frame roots and cont_denv BEFORE resuming so zero mature
 *      objects are lost at STW Remark.
 *   2. Draining satb_buf_ containing stale young stack continuation addresses
 *      uses address-only mature classification (never dereferences reclaimed
 *      young stack memory).
 *   3. Fused park-recv-and-direct-switch clears fk.raw_k and recycles fk into
 *      fk_pool strictly BEFORE reclaiming raw_k's stack span (and rolls back
 *      intact if reclaim returns 0).
 *   4. Fused send-to-LIFO never clobbers an occupied ctx.lifo slot (zero lost
 *      fiber wakeups).
 *
 * Negative Mutants (each MUST trigger VERIFICATION FAILED):
 *   -DINJECT_BUG_SKIP_WATERMARK_SHADE
 *   -DINJECT_BUG_RECYCLE_FK_AFTER_RECLAIM
 *   -DINJECT_BUG_CLOBBER_OCCUPIED_LIFO
 *   -DINJECT_BUG_DEREF_YOUNG_IN_SATB
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

/* Continuation & mature root state */
static volatile int g_satb_active;
static volatile int g_cont_alive;      /* 1 = valid stack span, 0 = reclaimed/overwritten */
static volatile int g_cont_is_young;   /* 1 = young stack_msection */
static volatile int g_mature_frame_m;  /* 1 = white mature obj reachable via frame */
static volatile int g_mature_denv_m;   /* 1 = white mature obj reachable via cont_denv */
static volatile int g_shaded_frame_m;
static volatile int g_shaded_denv_m;
static volatile int g_satb_buf_cont;   /* stale young cont id logged by write barrier */
static volatile int g_satb_buf_valid;

/* Carrier %fiber-k & LIFO/deque state */
static volatile int g_fk_in_pool;
static volatile int g_fk_raw_k;        /* 1 = points to cont, 0 = cleared */
static volatile int g_ctx_lifo;        /* 0 = empty, >0 = task id */
static volatile int g_dq_count;
static volatile int g_total_runnable;

/* Concurrent GC marker / STW observer */
static void concurrent_satb_drain(void) {
  int active, has_entry, is_young;
  __CPROVER_atomic_begin();
  active = g_satb_active;
  has_entry = g_satb_buf_valid;
  is_young = g_cont_is_young;
  __CPROVER_atomic_end();

  if (active && has_entry) {
#ifdef INJECT_BUG_DEREF_YOUNG_IN_SATB
    /* BUG: dereferences young stack continuation after reclaim! */
    assert(g_cont_alive == 1);
#else
    /* Address-only mature lookup: young stack addresses are ignored without deref */
    if (!is_young) {
      assert(g_cont_alive == 1);
    }
#endif
  }
}

static void gc_audit_fk_invariant(void) {
  int in_pool, raw_k, alive;
  __CPROVER_atomic_begin();
  in_pool = g_fk_in_pool;
  raw_k = g_fk_raw_k;
  alive = g_cont_alive;
  __CPROVER_atomic_end();
  if (in_pool) {
    assert(raw_k == 0);
  }
  if (raw_k != 0) {
    assert(alive == 1);
  }
}

static int fused_direct_switch(int reclaim_ok) {
  int nk;
  __CPROVER_atomic_begin();
  nk = g_fk_raw_k;
  __CPROVER_atomic_end();

#ifndef INJECT_BUG_RECYCLE_FK_AFTER_RECLAIM
  /* Step 1: Recycle fk (clear raw_k -> 0, log to SATB if active) BEFORE reclaim */
  __CPROVER_atomic_begin();
  if (g_satb_active && nk != 0) {
    g_satb_buf_cont = nk;
    g_satb_buf_valid = 1;
  }
  g_fk_raw_k = 0;
  g_fk_in_pool = 1;
  __CPROVER_atomic_end();
  fence_full();
#endif

  if (reclaim_ok) {
    /* Step 2: Reclaim stack span */
    __CPROVER_atomic_begin();
    g_cont_alive = 0;
    __CPROVER_atomic_end();
    fence_full();

#ifdef INJECT_BUG_RECYCLE_FK_AFTER_RECLAIM
    /* BUG: fk still held raw_k when g_cont_alive became 0! */
    gc_audit_fk_invariant();
    __CPROVER_atomic_begin();
    g_fk_raw_k = 0;
    g_fk_in_pool = 1;
    __CPROVER_atomic_end();
#endif

#ifndef INJECT_BUG_SKIP_WATERMARK_SHADE
    /* Step 3: ZGC Stack Watermark shading of frame ordinary roots + cont_denv */
    if (g_satb_active) {
      __CPROVER_atomic_begin();
      if (g_mature_frame_m) g_shaded_frame_m = 1;
      if (g_mature_denv_m)  g_shaded_denv_m = 1;
      __CPROVER_atomic_end();
    }
#endif
    return 1;
  } else {
    /* Fallback: span untouched, roll back fk intact */
    __CPROVER_atomic_begin();
    g_fk_in_pool = 0;
    g_fk_raw_k = nk;
    __CPROVER_atomic_end();
    return 0;
  }
}

static void fused_send_push_lifo(int rk_id) {
#ifdef INJECT_BUG_CLOBBER_OCCUPIED_LIFO
  /* BUG: blindly overwrites ctx.lifo without evicting previous occupant! */
  g_ctx_lifo = rk_id;
#else
  if (g_ctx_lifo == 0) {
    g_ctx_lifo = rk_id;
  } else {
    g_dq_count = g_dq_count + 1;
    g_ctx_lifo = rk_id;
  }
#endif
  g_total_runnable = (g_ctx_lifo != 0 ? 1 : 0) + g_dq_count;
}

int main(void) {
  int scenario;
  __CPROVER_assume(scenario >= 0 && scenario <= 2);

  g_satb_active = 1;
  g_cont_alive = 1;
  g_cont_is_young = 1;
  g_mature_frame_m = 1;
  g_mature_denv_m = 1;
  g_shaded_frame_m = 0;
  g_shaded_denv_m = 0;
  g_satb_buf_cont = 0;
  g_satb_buf_valid = 0;
  g_fk_in_pool = 0;
  g_fk_raw_k = 1;
  g_ctx_lifo = 0;
  g_dq_count = 0;
  g_total_runnable = 0;

  if (scenario == 0) {
    /* Scenario 0: SATB active + concurrent SATB drain + concurrent GC fk audit */
    __CPROVER_ASYNC_1: concurrent_satb_drain();
    __CPROVER_ASYNC_2: gc_audit_fk_invariant();
    int switched = fused_direct_switch(1);
    assert(switched == 1);
    /* STW Remark completeness: both mature roots MUST be shaded! */
    assert(g_shaded_frame_m == 1);
    assert(g_shaded_denv_m == 1);
    assert(g_fk_in_pool == 1 && g_fk_raw_k == 0);
  } else if (scenario == 1) {
    /* Scenario 1: Reclaim fallback (returns 0) rolls back fk cleanly */
    int switched = fused_direct_switch(0);
    assert(switched == 0);
    assert(g_cont_alive == 1);
    assert(g_fk_in_pool == 0 && g_fk_raw_k == 1);
    gc_audit_fk_invariant();
  } else {
    /* Scenario 2: Fused send-to-LIFO preserves exact runnable task count */
    fused_send_push_lifo(10);
    assert(g_total_runnable == 1);
    fused_send_push_lifo(20);
    assert(g_total_runnable == 2);
    assert(g_ctx_lifo == 20 && g_dq_count == 1);
  }

  return 0;
}
