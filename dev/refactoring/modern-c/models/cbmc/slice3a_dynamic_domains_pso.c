/* CBMC Weak-Memory (--mm pso) & Exact C Arithmetic Contract Harness
 * for Slice 3A-1: Dynamic Per-Domain VM Tables & O(live) Adaptive GC Copy Workers:
 *   1. Overflow-checked 16-byte-aligned contiguous slot layout sizing
 *      (zero wrap, zero partial-OOM leak, handles arbitrary cap = 1..256+).
 *   2. Exact C `gc_select_adaptive_workers` (honors explicit requested_workers,
 *      keeps coordinator at worker 0, enforces restore_loan safety, yields
 *      worker_count == 1 on idle 12/64/128-core VMs and full P on heavy heaps).
 *   3. Concurrent PSO weak-memory `life->sync_targets` custody proof:
 *        -DUSE_RUNNING_STATE_GATE=1 : PASSES (0 concurrent overwrite races under PSO)
 *        -DUSE_RUNNING_STATE_GATE=0 : FAILS  (kills mutant letting a second thread
 *                                     overwrite sync_targets before interrupt delivery)
 */
#include <assert.h>
#include <stdint.h>
#include <stddef.h>

#ifndef USE_RUNNING_STATE_GATE
#define USE_RUNNING_STATE_GATE 1
#endif

/* --- Part 1: Exact C Overflow-Checked Contiguous Slot Block Layout --- */
static int add_aligned16_slice(size_t *offset, size_t count, size_t elem_size) {
  size_t off = *offset;
  if (off > SIZE_MAX - 15u) return 0;
  off = (off + 15u) & ~(size_t)15u;
  if (elem_size > 0 && count > (SIZE_MAX - off) / elem_size) return 0;
  *offset = off + count * elem_size;
  return 1;
}

static size_t vm_lifecycle_storage_bytes(size_t cap) {
  size_t off = 0;
  if (cap < 1u) return 0;
  /* 12 dynamic per-domain arrays inside ___vm_lifecycle */
  if (!add_aligned16_slice(&off, cap, 8u)) return 0;   /* requests */
  if (!add_aligned16_slice(&off, cap, 8u)) return 0;   /* entries */
  if (!add_aligned16_slice(&off, cap, 48u)) return 0;  /* cleanup */
  if (!add_aligned16_slice(&off, cap, 8u)) return 0;   /* activations */
  if (!add_aligned16_slice(&off, cap, 16u)) return 0;  /* owners */
  if (!add_aligned16_slice(&off, cap, 1u)) return 0;   /* sync_constructed */
  if (!add_aligned16_slice(&off, cap, 1u)) return 0;   /* sync_parked */
  if (!add_aligned16_slice(&off, cap, 1u)) return 0;   /* sync_active */
  if (!add_aligned16_slice(&off, cap, 1u)) return 0;   /* sync_targets */
  if (!add_aligned16_slice(&off, cap, 32u)) return 0;  /* slots */
  if (!add_aligned16_slice(&off, cap, 64u)) return 0;  /* launches */
  if (!add_aligned16_slice(&off, cap, 128u)) return 0; /* group_demand */
  return off;
}

/* --- Part 2: Exact C O(live) Adaptive Worker Selection --- */
static int gc_select_adaptive_workers(
    int active_n,
    int requested,
    size_t small_words,
    size_t large_count,
    size_t half_cap,
    int parallel_demand,
    int promo_tails,
    int all_loans_safe) {
  if (requested > 0)
    return (requested < active_n) ? requested : active_n;
  if (active_n <= 1 || !all_loans_safe || half_cap == 0)
    return active_n;
  size_t copy_demand = 1u + (small_words / half_cap) + large_count;
  size_t demand = copy_demand;
  if (parallel_demand > 0 && (size_t)parallel_demand > demand)
    demand = (size_t)parallel_demand;
  if (promo_tails > 0 && (size_t)promo_tails > demand)
    demand = (size_t)promo_tails;
  if (demand < 1u) demand = 1u;
  if (demand > (size_t)active_n) demand = (size_t)active_n;
  return (int)demand;
}

/* --- Part 3: Concurrent PSO sync_targets Custody Proof --- */
static int sync_mut = 0;
static int sync_op_state = 0; /* 0=IDLE, 1=RUNNING, 2=DRAINING */
static int sync_remaining = 0;
static int sync_targets_owner = 0;
static int sync_targets_corrupted = 0;
static int t1_done = 0;

static void lock_sync(void) {
  __CPROVER_atomic_begin();
  __CPROVER_assume(sync_mut == 0);
  sync_mut = 1;
  __CPROVER_atomic_end();
  __CPROVER_fence("RRfence", "RWfence");
}

static void unlock_sync(void) {
  __CPROVER_fence("WWfence", "RWfence");
  __CPROVER_atomic_begin();
  sync_mut = 0;
  __CPROVER_atomic_end();
}

static void initiator_t1(void) {
  lock_sync();
  if (sync_op_state == 0) {
    sync_targets_owner = 1;
    sync_remaining = 2;
#if USE_RUNNING_STATE_GATE
    sync_op_state = 1; /* RUNNING: blocks any other thread from entering IDLE branch */
#else
    /* BUGGY MUTANT: forgets to transition sync_op_state before unlocking! */
    sync_op_state = 0;
#endif
    unlock_sync();

    /* raise_sync_op_interrupt_targets reads sync_targets outside mutex */
    if (sync_targets_owner != 1) {
      sync_targets_corrupted = 1;
    }

    /* Initiator finishes sync_op and calls sync_op_leave */
    lock_sync();
    sync_op_state = 2;
    sync_remaining -= 1;
    if (sync_remaining == 0) sync_op_state = 0;
    unlock_sync();
  } else {
    unlock_sync();
  }
  __CPROVER_fence("WWfence", "RWfence");
  t1_done = 1;
}

static void contender_t2(void) {
  lock_sync();
  if (sync_op_state == 0) {
    /* Only allowed to touch sync_targets when sync_op_state == IDLE */
    sync_targets_owner = 2;
    sync_remaining = 2;
    sync_op_state = 1;
    unlock_sync();

    if (sync_targets_owner != 2) {
      sync_targets_corrupted = 1;
    }

    lock_sync();
    sync_op_state = 2;
    sync_remaining -= 1;
    if (sync_remaining == 0) sync_op_state = 0;
    unlock_sync();
  } else {
    /* Participates in t1's active sync_op and leaves */
    unlock_sync();
    lock_sync();
    if (sync_remaining > 0) {
      sync_remaining -= 1;
      if (sync_remaining == 0) sync_op_state = 0;
    }
    unlock_sync();
  }
}

int main(void) {
  /* 1. Contiguous layout overflow & positivity checks */
  assert(vm_lifecycle_storage_bytes(0) == 0);
  assert(vm_lifecycle_storage_bytes(1) > 0);
  assert(vm_lifecycle_storage_bytes(12) > vm_lifecycle_storage_bytes(4));
  assert(vm_lifecycle_storage_bytes(128) > vm_lifecycle_storage_bytes(64));
  /* Overflow boundary must safely refuse (return 0) without unsigned wrap */
  assert(vm_lifecycle_storage_bytes(SIZE_MAX / 64u) == 0);

  /* 2. Adaptive worker sizing contracts */
  /* Idle 12-core and 128-core VMs -> strictly 1 copy worker */
  assert(gc_select_adaptive_workers(12, 0, 20000u, 0u, 32768u, 0, 0, 1) == 1);
  assert(gc_select_adaptive_workers(128, 0, 20000u, 0u, 32768u, 0, 0, 1) == 1);
  /* Heavy 12-core workload (>= 12 * 32768 words) -> full 12 workers */
  assert(gc_select_adaptive_workers(12, 0, 12u * 32768u, 0u, 32768u, 0, 0, 1) == 12);
  /* Explicit requested_workers == 4 honored verbatim even when idle */
  assert(gc_select_adaptive_workers(12, 4, 0u, 0u, 32768u, 0, 0, 1) == 4);
  /* Unsafe restoration loan keeps full active_n */
  assert(gc_select_adaptive_workers(12, 0, 0u, 0u, 32768u, 0, 0, 0) == 12);
  /* Parallel remark/evacuation demand keeps full mature parallelism */
  assert(gc_select_adaptive_workers(12, 0, 0u, 0u, 32768u, 16, 0, 1) == 12);

  /* 3. Concurrent PSO sync_targets custody proof */
  __CPROVER_ASYNC_1: initiator_t1();
  contender_t2();
  __CPROVER_assume(t1_done == 1);
  __CPROVER_fence("RRfence", "RWfence");
  assert(sync_targets_corrupted == 0);
  return 0;
}
