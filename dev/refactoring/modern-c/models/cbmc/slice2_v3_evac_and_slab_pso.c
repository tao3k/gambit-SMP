/* CBMC 6.11 Weak-Memory (--mm pso) & Exact C Arithmetic Contract Harness
 * for Slice 2 v3 Memory Endgame (P1-2 + P2-2 + P2-3):
 *   1. Hardware-adaptive Major GC triggers (zero overflow, >= mcnt+8, 2.0x->1.25x)
 *   2. Sub-linear generational nursery headroom cap (zero overflow, < mcnt for mcnt>=64)
 *   3. Medium ___STILL page-backed slab 2-bit container tag round-trip & bitmask math
 *   4. Concurrent PSO slab alloc/free & empty-chunk munmap protocol:
 *        -DUSE_SLAB_LOCK=1 : PASSES (0 double-alloc, 0 double-free, 0 live-chunk munmap)
 *        -DUSE_SLAB_LOCK=0 : FAILS  (kills unlocked slab race mutant under PSO!)
 */
#include <assert.h>
#include <stdint.h>
#include <stddef.h>

#ifndef USE_SLAB_LOCK
#define USE_SLAB_LOCK 1
#endif

static uint32_t isqrt_u32(uint32_t n) {
  uint32_t x = 0;
  uint32_t bit = 1u << 16;
  int step;
  for (step = 0; step < 9; step++) {
    if (bit <= n) {
      if (n >= x + bit) {
        n -= x + bit;
        x = (x >> 1) + bit;
      } else {
        x >>= 1;
      }
    } else if (x != 0) {
      x >>= 1;
    }
    bit >>= 2;
  }
  return x;
}

static int adaptive_major_trigger_sections(int mcnt, int eff_pct) {
  if (eff_pct < 10) eff_pct = 10;
  if (eff_pct > 90) eff_pct = 90;
  if (mcnt <= 0) return 8;
  uint32_t t = ((uint32_t)mcnt * 100u + (uint32_t)(eff_pct - 1)) / (uint32_t)eff_pct;
  if (t < (uint32_t)mcnt + 8u) t = (uint32_t)mcnt + 8u;
  return (int)t;
}

static int gen_nursery_cap_sections(int mcnt) {
  if (mcnt <= 0) return 32;
  uint32_t clamped = (mcnt > 65536) ? 65536u : (uint32_t)mcnt;
  int cap = 16 + 4 * (int)isqrt_u32(clamped);
  return (cap < 32) ? 32 : cap;
}

/* --- Concurrent PSO Slab Bucket Protocol --- */
static int slab_lock = 0;
static uint64_t chunk_free_mask = 0x3u; /* 2 usable slots: bits 0 and 1 */
static int chunk_mapped = 1;
static int slot0_owner = 0;
static int slot1_owner = 0;
static int t1_done = 0;
static int t2_done = 0;
static int live_munmap_violation = 0;
static int double_alloc_violation = 0;

static void lock_slab(void) {
#if USE_SLAB_LOCK
  __CPROVER_atomic_begin();
  __CPROVER_assume(slab_lock == 0);
  slab_lock = 1;
  __CPROVER_atomic_end();
  __CPROVER_fence("RRfence", "RWfence");
#endif
}

static void unlock_slab(void) {
#if USE_SLAB_LOCK
  __CPROVER_fence("WWfence", "RWfence");
  __CPROVER_atomic_begin();
  slab_lock = 0;
  __CPROVER_atomic_end();
#endif
}

static int slab_try_alloc(int tid) {
  int idx = -1;
  lock_slab();
  if (chunk_mapped && chunk_free_mask != 0u) {
    if (chunk_free_mask & 1u) idx = 0;
    else if (chunk_free_mask & 2u) idx = 1;
    if (idx >= 0) {
      uint64_t bit = (uint64_t)1u << idx;
      if ((chunk_free_mask & bit) == 0u)
        double_alloc_violation = 1;
      chunk_free_mask &= ~bit;
      if (idx == 0) {
        if (slot0_owner != 0) double_alloc_violation = 1;
        slot0_owner = tid;
      } else {
        if (slot1_owner != 0) double_alloc_violation = 1;
        slot1_owner = tid;
      }
    }
  }
  unlock_slab();
  return idx;
}

static void slab_free_and_maybe_munmap(int tid, int idx) {
  int do_munmap = 0;
  if (idx < 0) return;
  lock_slab();
  if (!chunk_mapped) {
    live_munmap_violation = 1;
  } else {
    if (idx == 0) {
      if (slot0_owner != tid) double_alloc_violation = 1;
      slot0_owner = 0;
    } else {
      if (slot1_owner != tid) double_alloc_violation = 1;
      slot1_owner = 0;
    }
    chunk_free_mask |= ((uint64_t)1u << idx);
    if (chunk_free_mask == 0x3u) {
      chunk_mapped = 0;
      do_munmap = 1;
    }
  }
  unlock_slab();
  if (do_munmap) {
    /* Verify no live owner remained when munmap fired outside the lock. */
    if (slot0_owner != 0 || slot1_owner != 0)
      live_munmap_violation = 1;
  }
}

static void worker_1(void) {
  int s = slab_try_alloc(1);
  slab_free_and_maybe_munmap(1, s);
  __CPROVER_fence("WWfence", "RWfence");
  t1_done = 1;
}

static void worker_2(void) {
  int s = slab_try_alloc(2);
  slab_free_and_maybe_munmap(2, s);
  __CPROVER_fence("WWfence", "RWfence");
  t2_done = 1;
}

int main(void) {
  /* 1. Adaptive Major GC trigger arithmetic */
  static const int m_table[5] = { 0, 8, 40, 200, 1000 };
  static const int p_table[4] = { 10, 50, 65, 80 };
  int mi, pi;
  __CPROVER_assume(mi >= 0 && mi < 5);
  __CPROVER_assume(pi >= 0 && pi < 4);
  int mcnt = m_table[mi];
  int pct = p_table[pi];
  int trig = adaptive_major_trigger_sections(mcnt, pct);
  assert(trig >= mcnt + 8);
  if (mcnt >= 8 && pct == 50) assert(trig == 2 * mcnt);
  if (mcnt >= 16 && pct == 80) assert(trig < 2 * mcnt);

  /* 2. Generational nursery sub-linear cap */
  int cap = gen_nursery_cap_sections(mcnt);
  assert(cap >= 32);
  if (mcnt >= 64) assert(cap < mcnt);
  if (mcnt == 200) assert(cap == 72);

  /* 3. 2-bit container tag separation (0=malloc, 1=direct_mmap, 2=slab) */
  uintptr_t fake_aligned = (uintptr_t)0x100000u;
  assert((fake_aligned & 3u) == 0u);
  uintptr_t tagged_mmap = fake_aligned | 1u;
  uintptr_t tagged_slab = fake_aligned | 2u;
  assert((tagged_mmap & 3u) == 1u && (tagged_mmap & ~(uintptr_t)3u) == fake_aligned);
  assert((tagged_slab & 3u) == 2u && (tagged_slab & ~(uintptr_t)3u) == fake_aligned);

  /* 4. Concurrent PSO slab alloc/free/munmap safety */
  __CPROVER_ASYNC_1: worker_1();
  worker_2();
  __CPROVER_assume(t1_done == 1 && t2_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  assert(double_alloc_violation == 0);
  assert(live_munmap_violation == 0);
  assert(slot0_owner == 0 && slot1_owner == 0);
  assert(chunk_mapped == 0);
  return 0;
}
