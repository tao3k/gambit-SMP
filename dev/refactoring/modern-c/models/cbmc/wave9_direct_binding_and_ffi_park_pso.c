/*
 * Wave 9 CBMC Weak-Memory (PSO) Formal Verification Harness:
 *   1. Direct-Indexed Global Slot Directory Growth & In-Place Page Publication:
 *      Proves release/acquire ordering for both geometric directory replacement
 *      (direct_cap + entries[key]) and in-place entry insertion into an active
 *      direct directory prevent torn/uninitialized reads under PSO.
 *   2. Monotonic 256-bit Per-ID Primitive Override Bloom Bitset (prim_override_bits[4]):
 *      Proves release ordering cell -> primitive_set -> prim_override_bits bit
 *      guarantees linearizable visibility on both fast (bit=0) and override (bit=1) paths.
 *   3. Blocking-FFI Unpark Conditional Broadcast (___leave_blocking_ffi):
 *      Proves guarding ___CONDVAR_BROADCAST with (sync_block_new_parks > 0)
 *      preserves zero lost wakeups for requires_full on_all_processors.
 *
 * Safe verification:
 *   cbmc --mm pso --bounds-check --signed-overflow-check --unwind 4 \
 *     dev/refactoring/modern-c/models/cbmc/wave9_direct_binding_and_ffi_park_pso.c
 *
 * Mutation-killing checks (each MUST fail with exit code 10):
 *   -DMUTANT_DIR_DROP_PUBLISH_RELEASE
 *   -DMUTANT_PAGE_DROP_ENTRY_RELEASE
 *   -DMUTANT_PRIM_SET_OVERRIDE_BEFORE_CELL
 *   -DMUTANT_FFI_SKIP_BROADCAST_WHEN_BLOCKING
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
 * Model 1: Directory Growth Publication (dir0 -> dir1, direct_cap 1 -> 2)
 * ============================================================================ */

static int g_page1_key = 0;
static int g_page1_ord = 0;
static int g_dir1_direct_cap = 0;
static int g_dir1_entry1 = 0;
static int g_store_dir = 0; /* 0 = dir0 (cap 1), 1 = dir1 (cap 2) */

static void dir_grow_writer(void) {
  g_page1_key = 1;
  g_page1_ord = 222;
  g_dir1_direct_cap = 2;
  g_dir1_entry1 = 1;
#ifndef MUTANT_DIR_DROP_PUBLISH_RELEASE
  fence_release();
#endif
  g_store_dir = 1;
}

static void dir_grow_reader(void) {
  int d = g_store_dir;
  fence_acquire();
  if (d == 1) {
    int cap = g_dir1_direct_cap;
    assert(cap == 2);
    int e1 = g_dir1_entry1;
    fence_acquire();
    assert(e1 == 1);
    assert(g_page1_key == 1);
    assert(g_page1_ord == 222);
  }
}

/* ============================================================================
 * Model 2: In-Place Page Insertion into Active Direct Directory
 * ============================================================================ */

static int g_ip_page_key = 0;
static int g_ip_page_ord = 0;
static int g_ip_entry1 = 0; /* slot in already-published dir (direct_cap == 2) */

static void inplace_page_writer(void) {
  g_ip_page_key = 1;
  g_ip_page_ord = 333;
#ifndef MUTANT_PAGE_DROP_ENTRY_RELEASE
  fence_release();
#endif
  g_ip_entry1 = 1;
}

static void inplace_page_reader(void) {
  int e1 = g_ip_entry1;
  fence_acquire();
  if (e1 == 1) {
    assert(g_ip_page_key == 1);
    assert(g_ip_page_ord == 333);
  }
}

/* ============================================================================
 * Model 3: Monotonic Primitive Override Fast-Path (has_primitive_override)
 * ============================================================================ */

static int g_image_prm = 777;
static int g_prim_cell = 0;
static int g_prim_set = 0;
static int g_has_prim_override = 0;

static void prim_override_writer(void) {
#ifdef MUTANT_PRIM_SET_OVERRIDE_BEFORE_CELL
  g_has_prim_override = 1;
  fence_release();
  g_prim_cell = 999;
  fence_release();
  g_prim_set = 1;
#else
  g_prim_cell = 999;
  fence_release();
  g_prim_set = 1;
  fence_release();
  g_has_prim_override = 1;
#endif
}

static void prim_override_reader(void) {
  int has_ov = g_has_prim_override;
  fence_acquire();
  if (has_ov == 0) {
    assert(g_image_prm == 777);
  } else {
    int bits = g_prim_set;
    fence_acquire();
    assert((bits & 1) != 0);
    int val = g_prim_cell;
    fence_acquire();
    assert(val == 999);
  }
}

/* ============================================================================
 * Model 4: Blocking-FFI Unpark Conditional Broadcast (sync_block_new_parks)
 * ============================================================================ */

static int g_parked_count = 1;
static int g_block_new_parks = 0;
static int g_waiter_sleeping = 0;
static int g_woken_count = 0;
static int g_req_done = 0;
static int g_unpark_done = 0;

static void full_sync_requester(void) {
  __CPROVER_atomic_begin();
  if (g_parked_count > 0) {
    g_block_new_parks++;
    g_waiter_sleeping = 1;
  }
  g_req_done = 1;
  __CPROVER_atomic_end();
}

static void ffi_unparker(void) {
  __CPROVER_atomic_begin();
  if (g_parked_count > 0) {
    g_parked_count--;
  }
#ifndef MUTANT_FFI_SKIP_BROADCAST_WHEN_BLOCKING
  if (g_block_new_parks > 0) {
    g_woken_count++;
    g_waiter_sleeping = 0;
  }
#endif
  g_unpark_done = 1;
  __CPROVER_atomic_end();
}

int main(void) {
  /* Check 1: Directory growth publication */
__CPROVER_ASYNC_1:
  dir_grow_writer();
  dir_grow_reader();

  /* Check 2: In-place direct page insertion */
__CPROVER_ASYNC_2:
  inplace_page_writer();
  inplace_page_reader();

  /* Check 3: Monotonic primitive override fast-path */
__CPROVER_ASYNC_3:
  prim_override_writer();
  prim_override_reader();

  /* Check 4: Blocking-FFI conditional broadcast */
__CPROVER_ASYNC_4:
  full_sync_requester();
  ffi_unparker();

  __CPROVER_atomic_begin();
  if (g_req_done && g_unpark_done) {
    assert(g_parked_count == 0);
    if (g_block_new_parks > 0) {
      assert(g_waiter_sleeping == 0);
      assert(g_woken_count >= 1);
    }
  }
  __CPROVER_atomic_end();

  return 0;
}
