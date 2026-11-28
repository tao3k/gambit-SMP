/*
 * amp4_refc_and_pacing_pso.c
 *
 * CBMC --mm pso weak-memory verification harness closing Amp-4 (H12-H13):
 *   Contract 1 (H12: Off-Heap Immutable RefC Binary Arc/ProcBin Drop Barrier):
 *     Two threads share an immutable off-heap binary (`bin_immutable = 1`, `bin_payload = 99`).
 *     Thread A reads payload, records `reader_done = 1`, issues release fence, decrements refcount.
 *     Thread B decrements refcount; observing final count == 0, issues acquire fence,
 *     verifies `reader_done == 1`, and frees (`bin_freed = 1; bin_payload = 0`).
 *     Mutants:
 *       -DMUTANT_REFC_DROP_WITHOUT_RELEASE=1 : drops release fence in Thread A -> PSO WW reorder -> FAIL!
 *       -DMUTANT_REFC_FREE_WITHOUT_ACQUIRE=1 : drops acquire fence in Thread B -> RR hoist -> FAIL!
 *       -DMUTANT_REFC_MUTATE_SHARED_BINARY=1 : bypasses IMMUTABLE_TAG check and mutates shared buffer -> FAIL!
 *
 *   Contract 2 (H13: OCaml-5 Global alloc_counter / work_counter Atomic Pacing):
 *     Two domains execute mark slices (`mark_node_1 = 1`, `mark_node_2 = 1`), issue release
 *     fences, and atomically increment `global_work_counter`. Coordinator observing
 *     `global_work_counter == 2` issues acquire fence and asserts BOTH mark nodes are visible.
 *     Mutant:
 *       -DMUTANT_PACING_NONATOMIC_WORK_PUBLISH=1 : drops release fence & uses non-atomic RMW -> FAIL!
 */

#include <assert.h>

#ifndef MUTANT_REFC_DROP_WITHOUT_RELEASE
#define MUTANT_REFC_DROP_WITHOUT_RELEASE 0
#endif

#ifndef MUTANT_REFC_FREE_WITHOUT_ACQUIRE
#define MUTANT_REFC_FREE_WITHOUT_ACQUIRE 0
#endif

#ifndef MUTANT_REFC_MUTATE_SHARED_BINARY
#define MUTANT_REFC_MUTATE_SHARED_BINARY 0
#endif

#ifndef MUTANT_PACING_NONATOMIC_WORK_PUBLISH
#define MUTANT_PACING_NONATOMIC_WORK_PUBLISH 0
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
/* Contract 1: Off-Heap Immutable RefC Binary (Arc / ProcBin Drop Barrier)   */
/* ========================================================================= */
static int bin_immutable = 1;
static int bin_payload = 99;
static int bin_freed = 0;
static int bin_reader_done = 0;
static int bin_a_dropped = 0;
static int bin_b_done = 0;
static int bin_a_done = 0;
static int bin_m_done = 0;

static void refc_reader_drop_a(void) {
  /* Read immutable off-heap payload while holding refcount */
  int v = bin_payload;
  int f = bin_freed;
  assert(f == 0);
  assert(v == 99);
  bin_reader_done = 1;
#if !MUTANT_REFC_DROP_WITHOUT_RELEASE
  release_fence();
#endif
  /* Signal Thread A's refcount decrement (2 -> 1 or 1 -> 0) */
  bin_a_dropped = 1;
  full_fence();
  bin_a_done = 1;
}

static void refc_final_drop_b(void) {
#if !MUTANT_REFC_FREE_WITHOUT_ACQUIRE
  if (bin_a_dropped == 1) {
    acquire_fence();
    /* Final dropper MUST see Thread A's payload read finished before freeing! */
    assert(bin_reader_done == 1);
    bin_freed = 1;
    bin_payload = 0;
  }
#else
  /* Without acquire fence before free(), weak memory (ARM64/POWER) may hoist
   * read of bin_reader_done / deallocation ahead of observing bin_a_dropped == 1! */
  int rd = bin_reader_done;
  if (bin_a_dropped == 1) {
    assert(rd == 1);
    bin_freed = 1;
    bin_payload = 0;
  }
#endif
  full_fence();
  bin_b_done = 1;
}

static void refc_mutator_guard_c(void) {
#if !MUTANT_REFC_MUTATE_SHARED_BINARY
  /* Chez IMMUTABLE_TAG check blocks in-place mutation of off-heap shared binary */
  if (!bin_immutable) {
    bin_payload = 0xDEAD;
  }
#else
  /* Mutant bypasses immutability check and mutates shared off-heap buffer! */
  bin_payload = 0xDEAD;
#endif
  full_fence();
  bin_m_done = 1;
}

/* ========================================================================= */
/* Contract 2: OCaml-5 Global alloc_counter / work_counter Atomic Pacing     */
/* ========================================================================= */
static int mark_node_1 = 0;
static int mark_node_2 = 0;
static int global_work_counter = 0;
static int p1_done = 0;
static int p2_done = 0;
static int coord_done = 0;

static void pacing_atomic_inc_work(void) {
#if !MUTANT_PACING_NONATOMIC_WORK_PUBLISH
  release_fence();
  __CPROVER_atomic_begin();
  global_work_counter = global_work_counter + 1;
  __CPROVER_atomic_end();
#else
  /* Mutant omits release fence AND uses racy non-atomic load+store RMW! */
  int tmp = global_work_counter;
  global_work_counter = tmp + 1;
#endif
}

static void pacing_domain_1(void) {
  mark_node_1 = 1;
  pacing_atomic_inc_work();
  full_fence();
  p1_done = 1;
}

static void pacing_domain_2(void) {
  mark_node_2 = 1;
  pacing_atomic_inc_work();
  full_fence();
  p2_done = 1;
}

static void pacing_coordinator(void) {
  if (global_work_counter == 2) {
    acquire_fence();
    assert(mark_node_1 == 1);
    assert(mark_node_2 == 1);
  }
  full_fence();
  coord_done = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: refc_reader_drop_a();
  __CPROVER_ASYNC_2: refc_final_drop_b();
  __CPROVER_ASYNC_3: refc_mutator_guard_c();
  __CPROVER_ASYNC_4: pacing_domain_1();
  __CPROVER_ASYNC_5: pacing_domain_2();
  __CPROVER_ASYNC_6: pacing_coordinator();

  __CPROVER_assume(bin_a_done && bin_b_done && bin_m_done &&
                   p1_done && p2_done && coord_done);
  full_fence();

  /* Both pacing slices must be conserved (no lost increment under concurrency) */
  assert(global_work_counter == 2);
  return 0;
}
