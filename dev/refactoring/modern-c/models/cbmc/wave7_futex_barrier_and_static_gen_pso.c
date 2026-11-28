/*
 * wave7_futex_barrier_and_static_gen_pso.c
 *
 * CBMC --mm pso weak-memory verification harness for:
 *   1. Lock-free adaptive-spin + OS futex sense-reversing barrier
 *      (os_sync_wait_on_address / FUTEX_WAIT_PRIVATE zero-lost-wakeup proof).
 *      Mutants:
 *        -DMUTANT_FUTEX_DROP_WAKE_FENCE=1     : waker omits WR full fence -> lost wakeup under PSO!
 *        -DMUTANT_FUTEX_DROP_WAITER_SEQ_CST=1 : waiter omits WR full fence -> lost wakeup under PSO!
 *   2. Inductive-closure GEN_STATIC dirty-barrier & concurrent sweep soundness:
 *      Mutants:
 *        -DMUTANT_STATIC_CLEAR_DIRTY_WITH_NONSTATIC_REF=1 : clears static_major_dirty while holding non-static ref -> live child lost!
 *        -DMUTANT_STATIC_SKIP_MATURE_WRITE_BARRIER=1      : value-aware WB skips dirtying static section on non-static mature store -> live child lost!
 */

#include <assert.h>

#ifndef MUTANT_FUTEX_DROP_WAKE_FENCE
#define MUTANT_FUTEX_DROP_WAKE_FENCE 0
#endif

#ifndef MUTANT_FUTEX_DROP_WAITER_SEQ_CST
#define MUTANT_FUTEX_DROP_WAITER_SEQ_CST 0
#endif

#ifndef MUTANT_STATIC_CLEAR_DIRTY_WITH_NONSTATIC_REF
#define MUTANT_STATIC_CLEAR_DIRTY_WITH_NONSTATIC_REF 0
#endif

#ifndef MUTANT_STATIC_SKIP_MATURE_WRITE_BARRIER
#define MUTANT_STATIC_SKIP_MATURE_WRITE_BARRIER 0
#endif

static void full_fence(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

static void release_fence(void) {
  __CPROVER_fence("WWfence", "RWfence");
}

static void acquire_fence(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

/* ========================================================================= */
/* Contract 1: Lock-Free Futex Barrier Zero-Lost-Wakeup under PSO (Dekker)   */
/* ========================================================================= */
static int bar_gen = 0;
static int bar_waiters = 0;
static int payload_data = 0;
static int waiter_parked = 0;
static int waiter_observed_payload = 0;
static int waker_skipped_wake = 0;
static int waiter_done = 0;
static int waker_done = 0;

static void futex_waiter_thread(void) {
  bar_waiters = 1;
#if !MUTANT_FUTEX_DROP_WAITER_SEQ_CST
  full_fence(); /* models atomic_fetch_add(&fast_bar_waiters, 1, seq_cst) */
#endif
  if (bar_gen == 0) {
    waiter_parked = 1;
  } else {
    acquire_fence();
    waiter_observed_payload = payload_data;
  }
  full_fence();
  waiter_done = 1;
}

static void futex_waker_thread(void) {
  payload_data = 42;
  release_fence();
  bar_gen = 1;
#if !MUTANT_FUTEX_DROP_WAKE_FENCE
  full_fence(); /* models atomic_thread_fence(seq_cst) before checking fast_bar_waiters */
#endif
  if (bar_waiters == 0) {
    waker_skipped_wake = 1;
  }
  full_fence();
  waker_done = 1;
}

static void verify_futex_barrier_pso(void) {
__CPROVER_ASYNC_1:
  futex_waiter_thread();
  futex_waker_thread();

  if (waiter_done && waker_done) {
    acquire_fence();
    /* Zero lost wakeups: waiter cannot park while waker skips os_sync_wake */
    assert(!(waiter_parked && waker_skipped_wake));
    /* Release-Acquire data visibility if waiter saw gen == 1 */
    if (!waiter_parked) {
      assert(waiter_observed_payload == 42);
    }
  }
}

/* ========================================================================= */
/* Contract 2: Inductive-Closure GEN_STATIC Dirty Barrier & Sweep Soundness  */
/* ========================================================================= */
#define OBJ_NONE             0
#define OBJ_PERM             1
#define OBJ_STATIC           2
#define OBJ_NONSTATIC_MATURE 3

static int st_major_static_gen = 1;
static int st_static_major_dirty = 1;
static int st_slot_kind = OBJ_PERM;
static int st_marked = 0;

static void wb_store_into_static(int val_kind) {
  st_slot_kind = val_kind;
#if MUTANT_STATIC_SKIP_MATURE_WRITE_BARRIER
  if (val_kind != OBJ_NONSTATIC_MATURE && val_kind != OBJ_PERM && val_kind != OBJ_STATIC) {
    release_fence();
    st_static_major_dirty = 1;
  }
#else
  if (st_major_static_gen && val_kind != OBJ_PERM && val_kind != OBJ_STATIC && val_kind != OBJ_NONE) {
    release_fence();
    st_static_major_dirty = 1;
  }
#endif
}

static void run_major_cycle(void) {
  st_marked = 0;
  if (st_static_major_dirty != 0) {
    int has_nonstatic = 0;
    acquire_fence();
    if (st_slot_kind == OBJ_NONSTATIC_MATURE) {
      st_marked = 1;
      has_nonstatic = 1;
    }
#if MUTANT_STATIC_CLEAR_DIRTY_WITH_NONSTATIC_REF
    st_static_major_dirty = 0;
#else
    if (!has_nonstatic) {
      st_static_major_dirty = 0;
    }
#endif
  }
}

static void verify_static_gen_closure(void) {
  /* Cycle 1: S only references OBJ_PERM -> STW proves closure and clears dirty to 0 */
  run_major_cycle();
  assert(st_static_major_dirty == 0);

  /* Mutator stores a non-static mature child M1 into clean static section S */
  wb_store_into_static(OBJ_NONSTATIC_MATURE);

  /* Cycle 2: M1 MUST be shaded live */
  run_major_cycle();
  assert(st_marked == 1);

  /* Cycle 3: S was NOT mutated again, still holds M1 -> M1 MUST STILL be shaded live! */
  run_major_cycle();
  assert(st_marked == 1);

  /* Overwrite with OBJ_STATIC -> Cycle 4 proves closure again and clears dirty to 0 */
  wb_store_into_static(OBJ_STATIC);
  run_major_cycle();
  assert(st_static_major_dirty == 0);
}

int main(void) {
  verify_futex_barrier_pso();
  verify_static_gen_closure();
  return 0;
}
