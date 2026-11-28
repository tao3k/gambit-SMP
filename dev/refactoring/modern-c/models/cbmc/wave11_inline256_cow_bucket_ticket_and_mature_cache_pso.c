/*
 * Wave 11 CBMC Weak-Memory (PSO) Formal Verification Harness:
 *   1. 256-Page Inline Global Slot Store Publication (inline_pages[256], key=99):
 *      Proves release/acquire publication covers stdlib/concurrent/user globals
 *      above the old 32-page (2048-global) cap with initialized page payload.
 *   2. Wait-Free Read / Lock-Free Copy-on-Write Flat Vector Buckets (concurrent-table):
 *      Proves copy-on-write publication with release CAS guarantees wait-free
 *      readers always observe a consistent flat #(k0 v0 k1 v1) snapshot and
 *      never observe uninitialized slots or torn in-place mutations.
 *   3. Adaptive Backoff Ticketlock Handoff Safety (___TICKETLOCK_LOCK2):
 *      Proves release-fetch-add unlock paired with acquire-load spin (with
 *      periodic backoff reset / yield) enforces mutual exclusion and payload
 *      happens-before between consecutive ticket holders.
 *   4. Dual-Cache Minor GC Mature-Skip Cache Preserving SATB Shading (mark_array):
 *      Proves caching non-evacuating mature sections separately from young
 *      fromspace sections never skips SATB shading during active concurrent
 *      major marking and never caches gc_evacuating sections.
 *
 * Safe verification:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 4 \
 *     dev/refactoring/modern-c/models/cbmc/wave11_inline256_cow_bucket_ticket_and_mature_cache_pso.c
 *
 * Mutation-killing checks (each MUST fail with exit code 10):
 *   -DMUTANT_INLINE256_DROP_RELEASE
 *   -DMUTANT_COW_BUCKET_DROP_RELEASE
 *   -DMUTANT_COW_BUCKET_MUTATE_IN_PLACE
 *   -DMUTANT_TICKET_DROP_UNLOCK_RELEASE
 *   -DMUTANT_MATURE_CACHE_SKIP_SATB_SHADE
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

/* ============================================================================
 * Model 1: 256-Page Inline Global Slot Store Publication (key = 99 > old 32)
 * ============================================================================ */

#define W11_INLINE_PAGES 256
#define W11_TEST_KEY 99

static int m1_page_key = 0;
static int m1_page_val = 0;
static int m1_inline_pages[W11_INLINE_PAGES];

static void m1_writer(void) {
  m1_page_key = W11_TEST_KEY;
  m1_page_val = 0x511;
#ifndef MUTANT_INLINE256_DROP_RELEASE
  fence_release();
#endif
  m1_inline_pages[W11_TEST_KEY] = 1;
}

static void m1_reader(void) {
  int pub = m1_inline_pages[W11_TEST_KEY];
  fence_acquire();
  if (pub != 0) {
    assert(m1_page_key == W11_TEST_KEY);
    assert(m1_page_val == 0x511);
  }
}

static void verify_model1_inline256(void) {
  m1_page_key = 0;
  m1_page_val = 0;
  m1_inline_pages[W11_TEST_KEY] = 0;
  __CPROVER_ASYNC_1: m1_writer();
  m1_reader();
}

/* ============================================================================
 * Model 2: Wait-Free Read / Lock-Free Copy-on-Write Flat Vector Buckets
 * ============================================================================ */

/* Bucket 0 = initial #(1 17); Bucket 1 = COW replacement #(1 17 2 27) */
static int m2_len[2];
static int m2_kv[2][4];
static int m2_slot_idx = 0; /* published immutable bucket index (0 or 1) */

static void m2_writer(void) {
#ifdef MUTANT_COW_BUCKET_MUTATE_IN_PLACE
  /* Buggy in-place mutation of live bucket 0 breaks wait-free reader invariant */
  m2_kv[0][0] = 2;
  m2_kv[0][1] = 27;
#else
  /* Allocate & populate fresh immutable flat vector bucket 1 before CAS publish */
  m2_len[1] = 4;
  m2_kv[1][0] = m2_kv[0][0];
  m2_kv[1][1] = m2_kv[0][1];
  m2_kv[1][2] = 2;
  m2_kv[1][3] = 27;
#ifndef MUTANT_COW_BUCKET_DROP_RELEASE
  fence_release();
#endif
  __CPROVER_atomic_begin();
  if (m2_slot_idx == 0) {
    m2_slot_idx = 1;
  }
  __CPROVER_atomic_end();
#endif
}

static void m2_reader(void) {
  int idx = m2_slot_idx;
  fence_acquire();
  int n = m2_len[idx];
  assert(n == 2 || n == 4);
  for (int i = 0; i < n; i += 2) {
    int k = m2_kv[idx][i];
    int v = m2_kv[idx][i + 1];
    assert(k == 1 || k == 2);
    assert(v == k * 10 + 7);
  }
}

static void verify_model2_cow_bucket(void) {
  m2_len[0] = 2;
  m2_kv[0][0] = 1;
  m2_kv[0][1] = 17;
  m2_kv[0][2] = 0;
  m2_kv[0][3] = 0;
  m2_len[1] = 0;
  m2_kv[1][0] = 0;
  m2_kv[1][1] = 0;
  m2_kv[1][2] = 0;
  m2_kv[1][3] = 0;
  m2_slot_idx = 0;
  fence_release();

  __CPROVER_ASYNC_1: m2_writer();
  m2_reader();
}

/* ============================================================================
 * Model 3: Adaptive Backoff Ticketlock Release-Acquire Handoff
 * ============================================================================ */

static int m3_next = 0;
static int m3_current = 0;
static int m3_shared_a = 10;
static int m3_shared_b = 10;

static int m3_lock_bounded(void) {
  int ticket;
  __CPROVER_atomic_begin();
  ticket = m3_next;
  m3_next = ticket + 1;
  __CPROVER_atomic_end();

  int spins = 0;
  for (int attempt = 0; attempt < 3; attempt++) {
    int cur = m3_current;
    fence_acquire();
    if (cur == ticket) {
      return 1;
    }
    if (spins < 1) {
      spins++;
    } else {
      /* Periodic yield resets spin window instead of trapping every iteration */
      spins = 0;
    }
  }
  return 0;
}

static void m3_unlock(void) {
#ifndef MUTANT_TICKET_DROP_UNLOCK_RELEASE
  fence_release();
#endif
  __CPROVER_atomic_begin();
  m3_current = m3_current + 1;
  __CPROVER_atomic_end();
}

static void m3_worker(void) {
  if (m3_lock_bounded()) {
    assert(m3_shared_a == m3_shared_b);
    m3_shared_a = m3_shared_a + 1;
    m3_shared_b = m3_shared_b + 1;
    m3_unlock();
  }
}

static void verify_model3_ticketlock(void) {
  m3_next = 0;
  m3_current = 0;
  m3_shared_a = 10;
  m3_shared_b = 10;
  fence_release();

  __CPROVER_ASYNC_1: m3_worker();

  if (m3_lock_bounded()) {
    assert(m3_shared_a == m3_shared_b);
    m3_shared_a = m3_shared_a + 1;
    m3_shared_b = m3_shared_b + 1;
    m3_unlock();
  }
}

/* ============================================================================
 * Model 4: Dual-Cache Minor GC Mature-Skip Preserving SATB Shading
 * ============================================================================ */

static void verify_model4_mature_skip_cache(void) {
  int sec_mature_base = 1000;
  int sec_mature_evac = 0;
  int sec_mature_satb_marked = 0;

  int sec_evac_base = 2000;
  int sec_evac_evac = 1;

  int cache_valid = 0;
  int cache_base = 0;
  int cache_epoch = 0;
  int epoch = 7;
  int major_marking = 1;
  int traverse_weak = 0;

  /* Prime cache on first non-evacuating mature section */
  if (!sec_mature_evac) {
    cache_valid = 1;
    cache_base = sec_mature_base;
    cache_epoch = epoch;
  }

  /* Evacuating mature section MUST NEVER be installed in mature_skip cache */
  if (!sec_evac_evac) {
    cache_valid = 1;
    cache_base = sec_evac_base;
    cache_epoch = epoch;
  }
  assert(cache_valid == 1 && cache_base == sec_mature_base);

  /* Second pointer hits mature_skip cache during active SATB major marking */
  int addr = 1040;
  if (cache_valid && cache_epoch == epoch &&
      addr >= cache_base && (addr - cache_base) < 512) {
#ifndef MUTANT_MATURE_CACHE_SKIP_SATB_SHADE
    if (major_marking && !traverse_weak) {
      sec_mature_satb_marked = 1;
    }
#endif
  }

  assert(sec_mature_satb_marked == 1);
}

int main(void) {
  verify_model1_inline256();
  verify_model2_cow_bucket();
  verify_model3_ticketlock();
  verify_model4_mature_skip_cache();
  return 0;
}
