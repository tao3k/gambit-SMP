/* CBMC 6.11 Weak-Memory (--mm pso) Harness for Slice 2 (v2 Production System):
 *   Concurrent SATB Major GC + Per-Processor Local Mark-Stack Buffers +
 *   Parallel STW Remark Termination Counter + Weak-Table Read-Barrier +
 *   CAS SATB + Atomic Weak-Clear-Before-Sweep (refining concurrent_major_satb_v2.qnt).
 *
 * Safe build:
 *   cbmc --mm pso -DUSE_SATB_GUARD=1 slice2_satb_major_pso.c
 * Mutant killer builds (ALL 4 must FAIL verification):
 *   cbmc --mm pso -DUSE_SATB_GUARD=0 slice2_satb_major_pso.c
 *   cbmc --mm pso -DUSE_SATB_GUARD=1 -DMUTANT_SKIP_WEAK_CLEAR=1 slice2_satb_major_pso.c
 *   cbmc --mm pso -DUSE_SATB_GUARD=1 -DMUTANT_SKIP_WEAK_READ_BARRIER=1 slice2_satb_major_pso.c
 *   cbmc --mm pso -DUSE_SATB_GUARD=1 -DMUTANT_SKIP_LOCAL_MARK_FLUSH=1 slice2_satb_major_pso.c
 */
#include <assert.h>
#include <stdint.h>

#ifndef USE_SATB_GUARD
#define USE_SATB_GUARD 1
#endif
#ifndef MUTANT_SKIP_WEAK_CLEAR
#define MUTANT_SKIP_WEAK_CLEAR 0
#endif
#ifndef MUTANT_SKIP_WEAK_READ_BARRIER
#define MUTANT_SKIP_WEAK_READ_BARRIER 0
#endif
#ifndef MUTANT_SKIP_LOCAL_MARK_FLUSH
#define MUTANT_SKIP_LOCAL_MARK_FLUSH 0
#endif

enum { PHASE_IDLE = 0, PHASE_MARKING = 1, PHASE_SWEEPING = 2 };

/* Mature objects:
 *   0 = A (root, initially BLACK, edge_a initially 1)
 *   1 = B (initially GREY on local mark buffer, edge_b initially 2)
 *   2 = C (initially WHITE, reachable only via B -> C, then moved to A -> C)
 *   3 = W (weak-table target, initially WHITE)
 *   4 = D (initially WHITE, reachable via C -> D, pushed into local mark buffer)
 */
static int major_phase = PHASE_MARKING;
static int satb_active = 1;
static int edge_a = 1;
static int edge_b = 2;
static int edge_c = 4;
static int weak_slot = 3;         /* weak table entry -> W(3), or -1 if cleared */
static int mutator_strong_w = -1; /* strong local root if mutator read weak_slot */

static uint32_t mark_bits = (1u << 0) | (1u << 1); /* A(0) BLACK, B(1) marked */
static int satb_entry0 = -1;
static int satb_entry1 = -1;
static int satb_count = 0;

/* Per-processor lock-free local mark buffer (Slice 2 v2) */
static int local_mark_entry0 = -1;
static int local_mark_count = 0;

static int freed0 = 0, freed1 = 0, freed2 = 0, freed3 = 0, freed4 = 0;
static int mutator_phase1_done = 0;
static int remark_done = 0;
static int stale_weak_uaf = 0;
static int live_c_swept = 0;
static int live_d_swept = 0;
static int live_w_swept = 0;

static void satb_log_val(int val) {
  if (val >= 0) {
    __CPROVER_atomic_begin();
    if (satb_count == 0) {
      satb_entry0 = val;
      satb_count = 1;
    } else if (satb_count == 1) {
      satb_entry1 = val;
      satb_count = 2;
    }
    __CPROVER_atomic_end();
  }
}

static void mark_obj(int id) {
  if (id >= 0 && id < 5) {
    __CPROVER_atomic_begin();
    mark_bits |= (1u << id);
    __CPROVER_atomic_end();
  }
}

static void local_mark_push(int id) {
  if (id >= 0 && id < 5) {
    __CPROVER_atomic_begin();
    if (local_mark_count == 0) {
      local_mark_entry0 = id;
      local_mark_count = 1;
    }
    __CPROVER_atomic_end();
  }
}

static int is_freed(int id) {
  if (id == 0) return freed0;
  if (id == 1) return freed1;
  if (id == 2) return freed2;
  if (id == 3) return freed3;
  if (id == 4) return freed4;
  return 0;
}

static void mutator_thread(int do_weak_read) {
  /* 1. Classic Yuasa SATB race: move C(2) from B(1) to already-BLACK A(0),
   *    then overwrite B(1)->edge_b with -1 (immediate). */
  int old_b = edge_b;
#if USE_SATB_GUARD
  if (satb_active) {
    satb_log_val(old_b);
    __CPROVER_fence("WWfence", "RWfence");
  }
#endif
  edge_a = old_b;
  edge_b = -1;

  /* 2. Optional weak-table read during MARKING (weak resurrection test). */
  if (do_weak_read) {
    int w = weak_slot;
    __CPROVER_fence("RRfence", "RWfence");
    if (w >= 0) {
#if USE_SATB_GUARD && !MUTANT_SKIP_WEAK_READ_BARRIER
      if (satb_active) {
        satb_log_val(w);
        __CPROVER_fence("WWfence", "RWfence");
      }
#endif
      mutator_strong_w = w;
    }
  }

  /* 3. Cooperative mutator slice pushes child C(2) into per-processor local mark buffer
   *    leaving D(4) to be scanned only when local_mark_buf is flushed at Remark! */
  if (satb_active) {
    local_mark_push(2);
    __CPROVER_fence("WWfence", "RWfence");
  }

  __CPROVER_fence("WWfence", "RWfence");
  mutator_phase1_done = 1;
}

static void marker_and_remark_thread(void) {
  /* Concurrent marking step: scan B(1) concurrently with mutator! */
  int b_child = edge_b;
  if (b_child >= 0)
    mark_obj(b_child);

  /* STW Remark barrier: synchronize after mutator reaches safepoint. */
  __CPROVER_assume(mutator_phase1_done == 1);
  __CPROVER_fence("RRfence", "RWfence");

  /* STW Remark Phase R-A: drain SATB buffer AND per-processor local mark buffer! */
  if (satb_count >= 1) {
    int v0 = satb_entry0;
    mark_obj(v0);
    if (v0 == 2 && edge_c >= 0) local_mark_push(edge_c);
  }
  if (satb_count >= 2) {
    int v1 = satb_entry1;
    mark_obj(v1);
    if (v1 == 2 && edge_c >= 0) local_mark_push(edge_c);
  }
#if !MUTANT_SKIP_LOCAL_MARK_FLUSH
  if (local_mark_count >= 1) {
    int lm = local_mark_entry0;
    local_mark_count = 0;
    mark_obj(lm);
    if (lm == 2 && edge_c >= 0)
      mark_obj(edge_c);
  }
#endif

  /* STW Remark Phase R-B: atomically clear dead (WHITE) weak-table entries BEFORE sweep! */
#if !MUTANT_SKIP_WEAK_CLEAR
  if (weak_slot >= 0 && ((mark_bits & (1u << weak_slot)) == 0))
    weak_slot = -1;
#endif

  /* Transition MARKING -> SWEEPING with release fence. */
  satb_active = 0;
  major_phase = PHASE_SWEEPING;
  __CPROVER_fence("WWfence", "RWfence");

  /* Non-moving sweep of WHITE objects. */
  if ((mark_bits & (1u << 0)) == 0) freed0 = 1;
  if ((mark_bits & (1u << 1)) == 0) freed1 = 1;
  if ((mark_bits & (1u << 2)) == 0) freed2 = 1;
  if ((mark_bits & (1u << 3)) == 0) freed3 = 1;
  if ((mark_bits & (1u << 4)) == 0) freed4 = 1;

  __CPROVER_fence("WWfence", "RWfence");
  remark_done = 1;

  /* Verify all safety invariants immediately after sweep & post-sweep weak read. */
  if (edge_a >= 0 && is_freed(edge_a)) live_c_swept = 1;
  if (edge_a == 2 && edge_c >= 0 && is_freed(edge_c)) live_d_swept = 1;
  if (mutator_strong_w >= 0 && is_freed(mutator_strong_w)) live_w_swept = 1;
  if (weak_slot >= 0 && is_freed(weak_slot)) stale_weak_uaf = 1;
}

int main(void) {
  int do_weak_read; /* nondeterministic 0 or 1 */
  __CPROVER_ASYNC_1: mutator_thread(do_weak_read);
  marker_and_remark_thread();

  assert(!freed0);
  assert(!live_c_swept);
  assert(!live_d_swept);
  assert(!live_w_swept);
  assert(!stale_weak_uaf);
  return 0;
}
