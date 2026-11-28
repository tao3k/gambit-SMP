/*
 * CBMC (--mm pso) Adversarial Weak-Memory Verification Harness for Phase C6:
 *   1. Sharded Per-Worker Monotonic Quiescence Detection (completed[] before spawned[])
 *      under PSO weak memory with concurrent cross-core spawn + steal + completion
 *   2. SATB-Gated In-Place One-Shot Fiber Continuation Rewind
 *
 * Negative Mutants (4/4 must FAIL assertion when enabled):
 *   -DINJECT_BUG_READ_SPAWNED_BEFORE_COMPLETED : scans spawned[] before completed[] -> false termination!
 *   -DINJECT_BUG_SPAWN_AFTER_PUBLISH           : increments spawned[0] after publishing task -> false termination!
 *   -DINJECT_BUG_MISSING_PUBLISH_FENCE         : omits release fence between spawned0++ and child_queued=1 under PSO!
 *   -DINJECT_BUG_REWIND_ON_SHARED_OR_SATB      : rewinds fiber stack continuation while satb_active == 1
 */

#include <assert.h>
#include <stdint.h>

static inline void full_fence(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
}

static inline void release_fence(void) {
  __CPROVER_fence("WWfence", "RWfence");
}

static inline void acquire_fence(void) {
  __CPROVER_fence("RRfence", "RWfence");
}

/* Sharded per-worker monotonic counters: root fiber pre-seeded as spawned[0] = 1 */
static volatile int spawned0   = 1;
static volatile int spawned1   = 0;
static volatile int completed0 = 0;
static volatile int completed1 = 0;

/* Shared deque slot for child task stolen by worker 1 */
static volatile int child_queued = 0;
static volatile int child_done   = 0;
static volatile int root_done    = 0;
static volatile int w1_finished  = 0;
static volatile int w2_finished  = 0;
static int false_termination     = 0;

/* Worker 0 runs root fiber: spawns 1 child fiber (published to worker 1), then completes root */
static void worker0_run(void) {
#ifdef INJECT_BUG_SPAWN_AFTER_PUBLISH
  /* Buggy: publishes child to worker 1 BEFORE incrementing spawned0! */
  release_fence();
  child_queued = 1;
  spawned0 = 2;
#else
  /* Correct: increment spawned0 with release BEFORE publishing child! */
  spawned0 = 2;
#ifndef INJECT_BUG_MISSING_PUBLISH_FENCE
  release_fence();
#endif
  child_queued = 1;
#endif
  /* Root finishes its work, then increments completed0 with release! */
  root_done = 1;
  release_fence();
  completed0 = 1;
}

/* Worker 1 steals child fiber from worker 0 and executes it to completion */
static void worker1_run(void) {
  if (child_queued == 1) {
    acquire_fence();
    /* Child completes its work, then increments completed1 with release! */
    child_done = 1;
    release_fence();
    completed1 = 1;
  }
  release_fence();
  w1_finished = 1;
}

/* Worker 2 performs concurrent quiescence scan (must NEVER observe C == S while child is unfinished!) */
static void worker2_scan(void) {
  int c, s;
#ifdef INJECT_BUG_READ_SPAWNED_BEFORE_COMPLETED
  /* Buggy order: read spawned BEFORE completed -> sees s=1 (old), then c=1 (after root finishes) while child is live! */
  s = spawned0 + spawned1;
  full_fence();
  c = completed0 + completed1;
#else
  /* Correct order: read completed FIRST, fence, then read spawned! */
  int c0 = completed0;
  int c1 = completed1;
  c = c0 + c1;
  full_fence();
  int s0 = spawned0;
  int s1 = spawned1;
  s = s0 + s1;
#endif

  /* If scanner concluded quiescent (c == s), then EVERY spawned fiber (both root AND child) MUST be done! */
  if (c == s) {
    /* Wait: if worker0 hasn't spawned child yet, c=0 != s=1, so c==s can ONLY happen when c>=1!
     * And once root completed (completed0==1), root ALREADY spawned child (spawned0==2),
     * so c==s==2 implies BOTH root_done==1 AND child_done==1! */
    if (!(root_done == 1 && child_done == 1)) {
      false_termination = 1;
    }
  }
  release_fence();
  w2_finished = 1;
}

/* SATB-safe one-shot fiber rewind model (pointer-free for CBMC concurrency) */
static int rewound_during_satb = 0;

static int try_rewind_fiber(int satb_on) {
#ifndef INJECT_BUG_REWIND_ON_SHARED_OR_SATB
  if (satb_on)
    return 0;
#endif
  if (satb_on)
    rewound_during_satb = 1;
  return 1;
}

int main(void) {
  __CPROVER_ASYNC_1: worker1_run();
  __CPROVER_ASYNC_2: worker2_scan();
  worker0_run();

  __CPROVER_assume(w1_finished == 1 && w2_finished == 1);
  acquire_fence();

  /* Safety: ZERO false premature termination under ALL PSO weak-memory interleavings! */
  assert(false_termination == 0);

  /* Safety: SATB-gated one-shot fiber rewind */
  int ok_satb = try_rewind_fiber(1);
  assert(ok_satb == 0);
  assert(rewound_during_satb == 0);
  int ok_idle = try_rewind_fiber(0);
  assert(ok_idle == 1);
  assert(rewound_during_satb == 0);

  return 0;
}
