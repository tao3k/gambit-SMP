/*
 * amp_chase_lev_and_radix_pso.c
 *
 * CBMC --mm pso weak-memory verification harness for Deep Amp-1/Amp-2 Contracts:
 *   Contract 1A (Lê et al. PPoPP 2013 Chase-Lev Push->Steal Publication under PSO):
 *     Owner writes cl1_buf[0] = 42, issues release fence, increments cl1_bottom = 1;
 *     Thief observes cl1_bottom == 1, reads cl1_buf[0] -> MUST observe 42, never 0!
 *     Mutant: -DMUTANT_CHASE_LEV_DROP_PUSH_RELEASE=1 drops release fence -> PSO WW reorder -> FAIL!
 *
 *   Contract 1B (Lê et al. PPoPP 2013 Chase-Lev 2-Element Take vs Steal×2 Race under PSO):
 *     Deque initialized with 2 tasks {11, 22} (top=0, bottom=2).
 *     Owner runs take() (bottom=1, fast-path takes 22 if top<1, CAS if top==1);
 *     Thief runs steal() (takes 11, top=0->1) then steal() again (races owner for 22!).
 *     Proves: task 22 is NEVER taken by BOTH owner and thief (strict uniqueness!).
 *     Mutants:
 *       -DMUTANT_CHASE_LEV_DROP_TAKE_FENCE=1  : drops seq_cst fence after bottom-- in take -> FAIL!
 *       -DMUTANT_CHASE_LEV_DROP_STEAL_FENCE=1 : drops seq_cst fence between load(top) & load(bottom) in steal -> FAIL!
 *
 *   Contract 2 (Amp-1 Two-Level Radix Directory L1->L2 Lock-Free Publication under PSO):
 *     Writer initializes L2[0] = 777, release fence, publishes L1 = 1;
 *     Concurrent reader observes L1 == 1, acquire fence, asserts L2[0] == 777.
 *     Mutant: -DMUTANT_RADIX_DROP_PUBLISH_FENCE=1 -> FAIL!
 *
 *   Contract 3 (Amp-1 Local->Mature SATB Black-Allocation Publication under PSO):
 *     During active SATB, local nursery writes payload=99 + satb_black=1, release fence,
 *     publishes global_pub=1; concurrent SATB observer asserts black==1 && payload==99.
 *     Mutant: -DMUTANT_LOCAL_PROMOTE_UNMARKED_SATB=1 -> FAIL!
 */

#include <assert.h>

#ifndef MUTANT_CHASE_LEV_DROP_PUSH_RELEASE
#define MUTANT_CHASE_LEV_DROP_PUSH_RELEASE 0
#endif

#ifndef MUTANT_CHASE_LEV_DROP_TAKE_FENCE
#define MUTANT_CHASE_LEV_DROP_TAKE_FENCE 0
#endif

#ifndef MUTANT_CHASE_LEV_DROP_STEAL_FENCE
#define MUTANT_CHASE_LEV_DROP_STEAL_FENCE 0
#endif

#ifndef MUTANT_RADIX_DROP_PUBLISH_FENCE
#define MUTANT_RADIX_DROP_PUBLISH_FENCE 0
#endif

#ifndef MUTANT_LOCAL_PROMOTE_UNMARKED_SATB
#define MUTANT_LOCAL_PROMOTE_UNMARKED_SATB 0
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
/* Contract 1A: Chase-Lev push() -> steal() Store-Release Publication        */
/* ========================================================================= */
static int cl1_buf = 0;
static int cl1_bottom = 0;
static int cl1_w_done = 0;
static int cl1_r_done = 0;

static void cl1_push_owner(void) {
  cl1_buf = 42;
#if !MUTANT_CHASE_LEV_DROP_PUSH_RELEASE
  release_fence();
#endif
  cl1_bottom = 1;
  full_fence();
  cl1_w_done = 1;
}

static void cl1_steal_thief(void) {
  if (cl1_bottom > 0) {
    acquire_fence();
    int v = cl1_buf;
    assert(v == 42);
  }
  full_fence();
  cl1_r_done = 1;
}

/* ========================================================================= */
/* Contract 1B: Chase-Lev 2-Element Take vs 2 Concurrent Thieves (3-Thread)  */
/* ========================================================================= */
static int cl2_top = 0;
static int cl2_bottom = 2;
static int cl2_buf[2] = {11, 22};
static int owner_val = 0;
static int thief_val1 = 0;
static int thief_val2 = 0;
static int cl2_owner_done = 0;
static int cl2_thief_a_done = 0;
static int cl2_thief_b_done = 0;

/* Relaxed CAS modeling LL/SC without full barrier (per Lê et al. §3) */
static int cas_cl2_top_relaxed(int expected, int desired) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (cl2_top == expected) {
    cl2_top = desired;
    ok = 1;
  }
  __CPROVER_atomic_end();
  return ok;
}

static void cl2_owner_take(void) {
  int nb = cl2_bottom - 1; /* nb = 1 */
  cl2_bottom = nb;         /* Store bottom = 1 */
#if !MUTANT_CHASE_LEV_DROP_TAKE_FENCE
  full_fence();            /* Required seq_cst fence (Lê et al. Fig. 1) */
#endif
  int t = cl2_top;         /* Load top */
  int x = 0;
  if (t <= nb) {
    x = cl2_buf[nb];       /* cl2_buf[1] == 22 */
    if (t == nb) {
      /* Single element left: must arbitrate via CAS */
      full_fence();
      if (!cas_cl2_top_relaxed(t, t + 1)) {
        x = 0;
      }
      full_fence();
      cl2_bottom = nb + 1;
    }
    /* Fast path when t < nb (t == 0 < 1): NO CAS! Safe ONLY because owner's
     * seq_cst fence + thief's seq_cst fence guarantee any thief observing
     * top == 1 also observes bottom == 1! */
  } else {
    cl2_bottom = nb + 1;
  }
  owner_val = x;
  full_fence();
  cl2_owner_done = 1;
}

static int cl2_steal_once(void) {
#if !MUTANT_CHASE_LEV_DROP_STEAL_FENCE
  int t = cl2_top;
  full_fence();            /* Required seq_cst fence (Lê et al. Fig. 1) */
  int b = cl2_bottom;
#else
  /* Without seq_cst fence between load(top) and load(bottom), relaxed CPU/compiler
   * may hoist load(bottom) ahead of load(top) (ARM64/POWER RR reordering)!
   * With 2 concurrent thieves (Lê et al. §2.1): Thief B hoists b=2 before owner
   * sets bottom=1 and fast-path takes 22, Thief A steals 11 (top: 0->1), then
   * Thief B reads t=1 < b=2 and steals 22 again -> DUPLICATE TASK 22! */
  int b = cl2_bottom;
  int t = cl2_top;
#endif
  if (t < b) {
    int cand = cl2_buf[t];
    if (cas_cl2_top_relaxed(t, t + 1)) {
      return cand;
    }
  }
  return 0;
}

static void cl2_thief_a(void) {
  thief_val1 = cl2_steal_once();
  full_fence();
  cl2_thief_a_done = 1;
}

static void cl2_thief_b(void) {
  thief_val2 = cl2_steal_once();
  full_fence();
  cl2_thief_b_done = 1;
}

/* ========================================================================= */
/* Contract 2: Amp-1 Two-Level Radix Directory L1->L2 Publication under PSO  */
/* ========================================================================= */
static int radix_l2_slot = 0;
static int radix_l1_ptr = 0;
static int r_w_done = 0;
static int r_r_done = 0;

static void radix_writer(void) {
  radix_l2_slot = 777;
#if !MUTANT_RADIX_DROP_PUBLISH_FENCE
  release_fence();
#endif
  radix_l1_ptr = 1;
  full_fence();
  r_w_done = 1;
}

static void radix_reader(void) {
  if (radix_l1_ptr == 1) {
    acquire_fence();
    assert(radix_l2_slot == 777);
  }
  full_fence();
  r_r_done = 1;
}

/* ========================================================================= */
/* Contract 3: Amp-1 Local->Mature SATB Black-Allocation Publication         */
/* ========================================================================= */
static int satb_mature_payload = 0;
static int satb_mature_black = 0;
static int satb_global_pub = 0;
static int s_w_done = 0;
static int s_r_done = 0;

static void local_promoter(void) {
  satb_mature_payload = 99;
#if !MUTANT_LOCAL_PROMOTE_UNMARKED_SATB
  satb_mature_black = 1;
  release_fence();
#endif
  satb_global_pub = 1;
  full_fence();
  s_w_done = 1;
}

static void satb_observer(void) {
  if (satb_global_pub == 1) {
    acquire_fence();
    assert(satb_mature_black == 1);
    assert(satb_mature_payload == 99);
  }
  full_fence();
  s_r_done = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: cl1_push_owner();
  __CPROVER_ASYNC_2: cl1_steal_thief();
  __CPROVER_ASYNC_3: cl2_owner_take();
  __CPROVER_ASYNC_4: cl2_thief_a();
  __CPROVER_ASYNC_5: cl2_thief_b();
  __CPROVER_ASYNC_6: radix_writer();
  __CPROVER_ASYNC_7: radix_reader();
  __CPROVER_ASYNC_8: local_promoter();
  __CPROVER_ASYNC_9: satb_observer();

  __CPROVER_assume(cl1_w_done && cl1_r_done &&
                   cl2_owner_done && cl2_thief_a_done && cl2_thief_b_done &&
                   r_w_done && r_r_done &&
                   s_w_done && s_r_done);
  full_fence();

  /* Strict Uniqueness of task 22 across owner take() and 2 concurrent thieves: */
  int got22 = (owner_val == 22 ? 1 : 0) +
              (thief_val1 == 22 ? 1 : 0) +
              (thief_val2 == 22 ? 1 : 0);
  assert(got22 == 1);
  /* Strict Uniqueness of task 11: */
  int got11 = (owner_val == 11 ? 1 : 0) +
              (thief_val1 == 11 ? 1 : 0) +
              (thief_val2 == 11 ? 1 : 0);
  assert(got11 <= 1);
  return 0;
}
