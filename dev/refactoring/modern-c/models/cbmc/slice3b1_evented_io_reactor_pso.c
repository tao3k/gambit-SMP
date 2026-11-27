/* CBMC weak-memory PSO & arithmetic contract harness for Slice 3B-1:
 *   kqueue / epoll Evented SMP I/O Reactor + Persistent FD-Generation Custody
 *   + Tier 3.3 Blocking-FFI Park vs requires_full (OP_VM_RESIZE) Dekker Wakeup
 *   + Dynamic Unlimited Reactor Capacity (zero FD_SETSIZE / MAX_CONDVARS cap).
 *
 * Run (safe - must PASS with 0 failures):
 *   cbmc --mm pso -DUSE_FD_GEN_CHECK=1 -DUSE_FULL_SYNC_ABORT=1 \
 *     --bounds-check --signed-overflow-check --unsigned-overflow-check --unwind 20 \
 *     dev/refactoring/modern-c/models/cbmc/slice3b1_evented_io_reactor_pso.c
 *
 * Run (Mutant 1 - FD reuse without generation check -> MUST FAIL):
 *   cbmc --mm pso -DUSE_FD_GEN_CHECK=0 -DUSE_FULL_SYNC_ABORT=1 --unwind 20 \
 *     dev/refactoring/modern-c/models/cbmc/slice3b1_evented_io_reactor_pso.c
 *
 * Run (Mutant 2 - OP_VM_RESIZE waits on parked reactor without abort -> MUST FAIL):
 *   cbmc --mm pso -DUSE_FD_GEN_CHECK=1 -DUSE_FULL_SYNC_ABORT=0 --unwind 20 \
 *     dev/refactoring/modern-c/models/cbmc/slice3b1_evented_io_reactor_pso.c
 */

#include <assert.h>
#include <stdint.h>
#include <stddef.h>
#include <limits.h>

#ifndef USE_FD_GEN_CHECK
#define USE_FD_GEN_CHECK 1
#endif

#ifndef USE_FULL_SYNC_ABORT
#define USE_FULL_SYNC_ABORT 1
#endif

#define FULL_FENCE() __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence")

/* 1. Dynamic overflow-safe reactor capacity (zero 1024 / 8192 compile-time cap). */
static size_t reactor_grow_capacity(size_t cur, size_t need)
{
  size_t cap = (cur < 64u) ? 64u : cur;
  if (need <= cap)
    return cap;
  if (need > (SIZE_MAX >> 1))
    return 0u; /* overflow guard */
  while (cap < need)
    {
      if (cap > (SIZE_MAX >> 1))
        return need;
      cap <<= 1;
    }
  return cap;
}

/* 2. Persistent kernel interest-set sync decision (kqueue / epoll).
 *    Returns: 0=noop, 1=reuse_persistent, 2=reregister_fresh, 3=delete_idle. */
static int reactor_slot_sync_action(unsigned char reg_mask,
                                    unsigned char want_mask,
                                    uint64_t reg_gen,
                                    uint64_t want_gen)
{
  if (want_mask == 0u)
    return (reg_mask == 0u) ? 0 : 3;
#if USE_FD_GEN_CHECK
  if (reg_mask == want_mask && reg_gen != 0u && reg_gen == want_gen)
    return 1;
#else
  /* MUTANT: ignore reg_gen vs want_gen -> reuses dead kernel entry after close+reuse! */
  if (reg_mask == want_mask)
    return 1;
#endif
  return 2;
}

/* 3. Two-thread PSO model of Tier 3.3 parked reactor vs requires_full (OP_VM_RESIZE):
 *    - sync_part_mut serializes publication of sync_parked and sync_block_new_parks.
 *    - Thread 1 (reactor): under sync_part_mut, if sync_block_new_parks==0 sets
 *      sync_parked=1; then enters kernel wait (which blocks iff abort_latched==0).
 *    - Thread 2 (OP_VM_RESIZE): under sync_part_mut, sets sync_block_new_parks=1;
 *      if sync_parked!=0, triggers select_abort (abort_latched=1) and waits for unpark.
 *    Under PSO, both threads MUST NOT simultaneously stall (reactor parked with
 *    abort_latched==0 AND resize waiting for sync_parked==0). */

static int sync_part_lock = 0;
static int sync_parked = 0;
static int sync_block_new_parks = 0;
static int abort_latched = 0;
static int reactor_blocked = 0;
static int resize_waiting = 0;
static int t1_done = 0;
static int t2_done = 0;

static void lock_sync_part(void)
{
  __CPROVER_atomic_begin();
  __CPROVER_assume(sync_part_lock == 0);
  sync_part_lock = 1;
  __CPROVER_atomic_end();
  FULL_FENCE();
}

static void unlock_sync_part(void)
{
  FULL_FENCE();
  __CPROVER_atomic_begin();
  sync_part_lock = 0;
  __CPROVER_atomic_end();
}

static void reactor_thread(void)
{
  int parked_now = 0;

  /* Models ___enter_blocking_ffi under sync_part_mut. */
  lock_sync_part();
  if (sync_block_new_parks == 0)
    {
      sync_parked = 1;
      parked_now = 1;
    }
  unlock_sync_part();

  if (parked_now)
    {
      /* Enter kevent/epoll_wait: kernel wake latch is serialized by kernel syscall. */
      FULL_FENCE();
      if (abort_latched == 0)
        reactor_blocked = 1;
    }
  FULL_FENCE();
  t1_done = 1;
}

static void resize_thread(void)
{
  /* Models on_all_processors(requires_full=1) under sync_part_mut. */
  lock_sync_part();
  sync_block_new_parks = 1;
  if (sync_parked != 0)
    {
#if USE_FULL_SYNC_ABORT
      /* Kernel EVFILT_USER / eventfd / self-pipe write latches wakeup! */
      abort_latched = 1;
      FULL_FENCE();
#endif
      resize_waiting = 1;
    }
  unlock_sync_part();
  FULL_FENCE();
  t2_done = 1;
}

int main(void)
{
  /* A. Unlimited dynamic capacity checks (> FD_SETSIZE=1024 and > MAX_CONDVARS=8192). */
  assert(reactor_grow_capacity(0u, 1u) == 64u);
  assert(reactor_grow_capacity(64u, 1025u) >= 1025u);
  assert(reactor_grow_capacity(64u, 12000u) >= 12000u);
  assert(reactor_grow_capacity(64u, SIZE_MAX) == 0u);

  /* B. Persistent FD-generation custody check across close + OS FD reuse. */
  {
    unsigned char reg_mask = 1u; /* RD registered for device gen 1 */
    uint64_t reg_gen = 1u;
    int kernel_has_new_fd = 0;

    /* Same device (gen 1), same mask -> O(1) persistent reuse. */
    assert(reactor_slot_sync_action(reg_mask, 1u, reg_gen, 1u) == 1);

    /* Device gen 1 closed (kernel dropped it), OS reused same fd for device gen 2! */
    int action = reactor_slot_sync_action(reg_mask, 1u, reg_gen, 2u);
    if (action == 2)
      kernel_has_new_fd = 1;
    assert(kernel_has_new_fd == 1);

    /* Idle fd leaves waitset -> deleted from kernel. */
    assert(reactor_slot_sync_action(reg_mask, 0u, reg_gen, 0u) == 3);
  }

  /* C. PSO concurrency check: OP_VM_RESIZE + parked reactor deadlock freedom. */
  __CPROVER_ASYNC_1: reactor_thread();
  resize_thread();

  __CPROVER_assume(t1_done == 1 && t2_done == 1);
  FULL_FENCE();

  /* Deadlock freedom: if OP_VM_RESIZE is waiting for a parked reactor AND the
   * reactor entered kernel wait, abort_latched MUST be 1 (waking the reactor!). */
  if (resize_waiting && reactor_blocked)
    assert(abort_latched == 1);

  return 0;
}
