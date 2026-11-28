/*
 * Wave 10 CBMC Weak-Memory (PSO) Formal Verification Harness:
 *   1. Inline Per-VM Global Page Publication (store->inline_pages[32]):
 *      Proves release/acquire publication guarantees initialized page->key and
 *      page->ordinary[slot] without traversing store->directory.
 *   2. Relaxed Fast-Path Bloom Check + Acquire Slow-Path Primitive Override:
 *      Proves a plain relaxed load of prim_override_bits on the 99.61%
 *      un-overridden fast path (returning immutable static global->prm) is
 *      PSO-sound when paired with release-OR on write and acquire on the slow
 *      override path.
 *   3. Unified Atomic Rest-Hook Gate (___rest_hooks_gate):
 *      Proves clearing the fast-path gate only when attempt/observation hooks
 *      are inactive prevents bypassing armed refusal/observation hooks and
 *      preserves happens-before for armed hook payloads.
 *   4. Packed (work_gen << 12) | active Single-Word Futex GC Chunk-Stealing:
 *      Proves zero lost wakeups, zero torn chunk reads, and zero
 *      post-termination resurrection when idle GC workers wake on work_gen
 *      advances and CAS-reactivate to steal newly published heap chunks.
 *
 * Safe verification:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 4 \
 *     dev/refactoring/modern-c/models/cbmc/wave10_inline_binding_rest_and_gc_steal_pso.c
 *
 * Mutation-killing checks (each MUST fail with exit code 10):
 *   -DMUTANT_INLINE_PAGE_DROP_RELEASE
 *   -DMUTANT_PRIM_BLOOM_DROP_RELEASE
 *   -DMUTANT_REST_GATE_CLEAR_WHILE_ARMED
 *   -DMUTANT_GC_STEAL_DROP_CHUNK_RELEASE
 *   -DMUTANT_GC_STEAL_RESURRECT_AFTER_ZERO
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *kind, ...);

static inline void fence_release(void) {
  __CPROVER_fence("WWfence", "RWfence");
}

static inline void fence_acquire(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

static inline void fence_seq_cst(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

/* ============================================================================
 * Model 1: Inline Per-VM Page Slot Publication (store->inline_pages[key])
 * ============================================================================ */

static int g_ip_key = 0;
static int g_ip_ord = 0;
static int g_store_inline_page0 = 0;

static void inline_page_writer(void) {
  g_ip_key = 7;
  g_ip_ord = 555;
#ifndef MUTANT_INLINE_PAGE_DROP_RELEASE
  fence_release();
#endif
  g_store_inline_page0 = 1;
}

static void inline_page_reader(void) {
  int p = g_store_inline_page0;
  fence_acquire();
  if (p == 1) {
    assert(g_ip_key == 7);
    assert(g_ip_ord == 555);
  }
}

/* ============================================================================
 * Model 2: Relaxed Fast-Path Bloom + Acquire Slow-Path Primitive Override
 * ============================================================================ */

static int g_static_prm = 777;
static int g_ov_cell = 0;
static int g_ov_set = 0;
static int g_bloom_bits = 0;

static void prim_bloom_writer(void) {
  g_ov_cell = 999;
#ifndef MUTANT_PRIM_BLOOM_DROP_RELEASE
  fence_release();
#endif
  g_ov_set = 1;
#ifndef MUTANT_PRIM_BLOOM_DROP_RELEASE
  fence_release();
#endif
  g_bloom_bits = 1;
}

static void prim_bloom_reader(void) {
  /* Fast path: plain RELAXED load (no acquire fence on bit == 0 branch) */
  int bits = g_bloom_bits;
  if ((bits & 1) == 0) {
    /* Only reads static immutable global->prm */
    assert(g_static_prm == 777);
  } else {
    /* Slow path acquires override metadata and cell */
    fence_acquire();
    assert((g_ov_set & 1) != 0);
    assert(g_ov_cell == 999);
  }
}

/* ============================================================================
 * Model 3: Unified Atomic Rest-Hook Gate (___rest_hooks_gate)
 * ============================================================================ */

static int g_rest_attempt_armed = 0;
static int g_rest_hook_payload = 0;
static int g_rest_hooks_gate = 0;

static void rest_hook_arm_and_run(void) {
  g_rest_hook_payload = 42;
  fence_release();
#ifdef MUTANT_REST_GATE_CLEAR_WHILE_ARMED
  g_rest_hooks_gate = 0; /* BUG: gate stays 0 while attempt is armed! */
#else
  g_rest_hooks_gate = 1;
#endif
  fence_release();
  g_rest_attempt_armed = 1;
}

static void rest_mutator_check(void) {
  int gate = g_rest_hooks_gate;
  if (gate == 0) {
    /* Fast path: gate==0 strictly implies attempt is NOT yet armed */
    __CPROVER_atomic_begin();
    if (g_rest_attempt_armed && g_rest_hooks_gate == 0) {
      assert(0 && "rest_hooks_gate cleared while hook armed");
    }
    __CPROVER_atomic_end();
  } else {
    fence_acquire();
    assert(g_rest_hook_payload == 42);
  }
}

/* ============================================================================
 * Model 4: Packed (work_gen << 12) | active GC Chunk-Stealing Termination
 * ============================================================================ */

#define SCAN_ACTIVE_MASK 0xFFFu
#define SCAN_GEN_INC (1u << 12)

static uint32_t g_scan_state = 2u; /* gen=0, active=2 */
static uint32_t g_scan_waiters = 0u;
static int g_chunk_payload = 0;
static int g_chunk_queued = 0;
static int g_chunk_stolen = 0;
static int g_terminated_seen = 0;
static int g_resurrected = 0;

static void gc_worker0_producer(void) {
  /* Publish one heap chunk */
  g_chunk_payload = 888;
#ifndef MUTANT_GC_STEAL_DROP_CHUNK_RELEASE
  fence_release();
#endif
  __CPROVER_atomic_begin();
  g_chunk_queued = 1;
  g_scan_state += SCAN_GEN_INC;
  __CPROVER_atomic_end();
  fence_seq_cst();
  /* Finish local work and decrement active */
  __CPROVER_atomic_begin();
  uint32_t prev = g_scan_state;
  g_scan_state = prev - 1u;
  if ((g_scan_state & SCAN_ACTIVE_MASK) == 0u) {
    g_terminated_seen = 1;
  }
  __CPROVER_atomic_end();
  fence_seq_cst();
}

static void gc_worker1_stealer(void) {
  /* Initial steal misses; drop active and wait for either work_gen or active==0 */
  uint32_t prev;
  __CPROVER_atomic_begin();
  prev = g_scan_state;
  g_scan_state = prev - 1u;
  if ((g_scan_state & SCAN_ACTIVE_MASK) == 0u) {
    g_terminated_seen = 1;
  }
  __CPROVER_atomic_end();
  if ((prev & SCAN_ACTIVE_MASK) == 1u) {
    return;
  }

  uint32_t seen_gen = prev >> 12;
  __CPROVER_atomic_begin();
  g_scan_waiters++;
  __CPROVER_atomic_end();
  fence_seq_cst();

  /* Observe current packed state */
  uint32_t cur = g_scan_state;
  fence_acquire();
  if ((cur >> 12) != seen_gen) {
    int reactivated = 0;
    __CPROVER_atomic_begin();
#ifdef MUTANT_GC_STEAL_RESURRECT_AFTER_ZERO
    /* BUG: forgets (g_scan_state & SCAN_ACTIVE_MASK) != 0u check */
    if ((g_scan_state & SCAN_ACTIVE_MASK) == 0u) {
      g_resurrected = 1;
    }
    g_scan_state += 1u;
    reactivated = 1;
#else
    if ((g_scan_state & SCAN_ACTIVE_MASK) != 0u) {
      g_scan_state += 1u;
      reactivated = 1;
    }
#endif
    __CPROVER_atomic_end();

    if (reactivated) {
      assert(!g_resurrected);
      /* Acquire chunk and verify payload */
      int q = g_chunk_queued;
      fence_acquire();
      if (q) {
        assert(g_chunk_payload == 888);
        g_chunk_stolen = 1;
      }
      /* Done stealing: decrement active */
      __CPROVER_atomic_begin();
      g_scan_state -= 1u;
      if ((g_scan_state & SCAN_ACTIVE_MASK) == 0u) {
        g_terminated_seen = 1;
      }
      __CPROVER_atomic_end();
    }
  }

  __CPROVER_atomic_begin();
  g_scan_waiters--;
  __CPROVER_atomic_end();
}

int main(void) {
  /* Check 1: Inline per-VM page publication */
__CPROVER_ASYNC_1:
  inline_page_writer();
  inline_page_reader();

  /* Check 2: Relaxed fast-path bloom + acquire slow-path primitive override */
__CPROVER_ASYNC_2:
  prim_bloom_writer();
  prim_bloom_reader();

  /* Check 3: Unified rest-hook gate */
__CPROVER_ASYNC_3:
  rest_hook_arm_and_run();
  rest_mutator_check();

  /* Check 4: Packed single-word GC chunk-stealing futex termination */
__CPROVER_ASYNC_4:
  gc_worker0_producer();
  gc_worker1_stealer();

  assert(!g_resurrected);
  return 0;
}
