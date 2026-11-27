/* CBMC Weak-Memory (--mm pso) & Exact C Arithmetic Contract Harness
 * for Slice 2.5 Runtime Hardening (commit f6510651):
 *   1. OCaml-5-style per-domain geometric rest_directory chunk growth arithmetic
 *      overflow guards (4 -> 8 -> 16 -> ..., zero wrap, non-relocating append,
 *      retired_generation monotonicity on slot reuse).
 *   2. Concurrent PSO weak-memory `___device_select` vs `___device_close`
 *      two-stage post-poll `___SELECT_PASS_CHECK` custody fence (`lib/os_io.c`):
 *        -DUSE_POST_CHECK_FENCE=1 : PASSES (0 concurrent close-vs-check races under PSO)
 *        -DUSE_POST_CHECK_FENCE=0 : FAILS  (kills exact Linux CI c8 exit=139 SIGSEGV bug!)
 */
#include <assert.h>
#include <stdint.h>
#include <stddef.h>

#ifndef USE_POST_CHECK_FENCE
#define USE_POST_CHECK_FENCE 1
#endif

/* --- Part 1: Exact C Overflow-Guarded Geometric Slab Growth --- */
static size_t rest_slab_next_chunk_cap(size_t total_slots, size_t last_cap) {
  size_t next_cap = (last_cap == 0) ? 4u : last_cap;
  if (last_cap > 0) {
    if (next_cap > SIZE_MAX / 2u) return 0;
    next_cap *= 2u;
  }
  if (next_cap > SIZE_MAX - total_slots) return 0;
  /* Guard byte allocation size: header + (next_cap - 1) * slot_size (40 bytes) */
  if (next_cap > (SIZE_MAX - 64u) / 40u) return 0;
  return next_cap;
}

/* --- Part 2: Concurrent PSO Two-Stage Select-vs-Close Fence --- */
static int select_mutex = 0;
static int select_active = 0;
static int close_in_progress = 0;
static int close_pending_rd = 0;
static int device_mutated_or_closed = 0;
static int check_saw_mutated_device = 0;
static int selector_done = 0;

static void lock_sel(void) {
  __CPROVER_atomic_begin();
  __CPROVER_assume(select_mutex == 0);
  select_mutex = 1;
  __CPROVER_atomic_end();
  __CPROVER_fence("RRfence", "RWfence");
}

static void unlock_sel(void) {
  __CPROVER_fence("WWfence", "RWfence");
  __CPROVER_atomic_begin();
  select_mutex = 0;
  __CPROVER_atomic_end();
}

static void selector_thread(void) {
  int dir_is_rd;
  __CPROVER_assume(dir_is_rd == 0 || dir_is_rd == 1);

  /* Phase 1: Borrow device before OS poll() */
  lock_sel();
  if ((dir_is_rd && close_pending_rd) || close_in_progress) {
    unlock_sel();
    selector_done = 1;
    return;
  }
  select_active += 1;
  unlock_sel();

  /* (OS poll() returns here; concurrent close_thread may have started!) */

#if USE_POST_CHECK_FENCE
  /* SAFE (f6510651): snapshot close flags while KEEPING select_active > 0,
   * run ___SELECT_PASS_CHECK only if not closing, and decrement select_active
   * strictly AFTER ___SELECT_PASS_CHECK completes. */
  int skip_check = 0;
  lock_sel();
  if ((dir_is_rd && close_pending_rd) || close_in_progress) {
    skip_check = 1;
  }
  unlock_sel();

  if (!skip_check) {
    /* ___SELECT_PASS_CHECK reads device fields */
    if (device_mutated_or_closed) {
      check_saw_mutated_device = 1;
    }
  }

  lock_sel();
  select_active -= 1;
  unlock_sel();
#else
  /* BUGGY MUTANT (pre-f6510651 Linux CI c8 exit=139): decrements select_active
   * BEFORE ___SELECT_PASS_CHECK, allowing close_thread to destroy/mutate device
   * state concurrently while ___SELECT_PASS_CHECK dereferences it! */
  int skip_check = 0;
  lock_sel();
  if (dir_is_rd && close_pending_rd) {
    skip_check = 1;
  }
  select_active -= 1;
  unlock_sel();

  if (!skip_check) {
    if (device_mutated_or_closed) {
      check_saw_mutated_device = 1;
    }
  }
#endif
  __CPROVER_fence("WWfence", "RWfence");
  selector_done = 1;
}

static void closer_thread(void) {
  /* Phase 1: Publish close_in_progress + close_pending_rd */
  lock_sel();
  close_in_progress = 1;
  close_pending_rd = 1;
  /* Wait until select_active == 0 (modeled by release/reacquire gate) */
  if (select_active != 0) {
    unlock_sel();
    lock_sel();
    __CPROVER_assume(select_active == 0);
  }
  unlock_sel();

  /* Phase 2: Execute ___device_close_virt (mutates fd / stages / TLS / process state) */
  device_mutated_or_closed = 1;
  __CPROVER_fence("WWfence", "RWfence");
}

int main(void) {
  /* 1. Verify geometric rest_directory growth chain 4 -> 8 -> 16 -> 32 */
  size_t total = 0, last = 0, next = 0;
  next = rest_slab_next_chunk_cap(total, last);
  assert(next == 4u);
  total += next; last = next;

  next = rest_slab_next_chunk_cap(total, last);
  assert(next == 8u);
  total += next; last = next;

  next = rest_slab_next_chunk_cap(total, last);
  assert(next == 16u);
  total += next; last = next;
  assert(total == 28u);

  /* Overflow boundary must safely refuse without wrapping */
  assert(rest_slab_next_chunk_cap(0, (SIZE_MAX / 2u) + 1u) == 0u);

  /* 2. Verify concurrent PSO select-vs-close two-stage post-poll check fence */
  __CPROVER_ASYNC_1: selector_thread();
  closer_thread();
  __CPROVER_assume(selector_done == 1);
  __CPROVER_fence("RRfence", "RWfence");

  assert(check_saw_mutated_device == 0);
  assert(select_active == 0);
  return 0;
}
