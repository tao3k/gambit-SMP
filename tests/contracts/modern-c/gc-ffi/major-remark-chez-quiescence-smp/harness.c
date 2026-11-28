/* Adversarial CBMC PSO Harness for Parallel STW Remark Phase R-A
 * Chez Creator-Owned Remote-Inbox Single-Word Atomic Quiescence Counter.
 *
 * Models 2 concurrent workers (w1, w2) under --mm pso:
 *   - Initial state: w1 is IDLE, w2 is IDLE, inboxes[1] = 1 (take = 1),
 *     working = 0, remote_pending = 1, inflight = 1 (working + inboxes + stack).
 *   - w1 wakes from IDLE by draining inboxes[1] (`take = 1`), then scans the
 *     object and routes a child to inboxes[2] (`major_remote_flush_one`).
 *   - w2 concurrently checks the quiescence termination condition and exits to
 *     BARRIER() permanently if it observes quiescence.
 *
 * Safety Assertion (No Orphaned-Inbox Livelock):
 *   If w2 permanently exited to BARRIER(), then inboxes[2] MUST be 0!
 *
 * Negative Mutants (each MUST trigger VERIFICATION FAILED):
 *   -DINJECT_BUG_SPLIT_WORKING_REMOTE_READ
 *   -DINJECT_BUG_NONATOMIC_IDLE_INBOX_DRAIN
 *   -DINJECT_BUG_OMIT_MARK_STACK_FROM_INFLIGHT
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern void __CPROVER_assume(int);

static inline void fence_acq_rel(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

static inline int fetch_add_acq_rel(volatile int *p, int delta) {
  int prev;
  __CPROVER_atomic_begin();
  prev = *p;
  *p = prev + delta;
  __CPROVER_atomic_end();
  fence_acq_rel();
  return prev;
}

static inline int load_acq(volatile int *p) {
  int v = *p;
  fence_acq_rel();
  return v;
}

/* Scenario 0: Remote inbox handoff race (reproduces PID 67298 livelock) */
static volatile int g_working;
static volatile int g_remote_pending;
static volatile int g_inflight;
static volatile int g_inbox1;
static volatile int g_inbox2;
static volatile int g_w2_exited;
static volatile int g_w1_done;

static void worker1_drain_and_route(void) {
  if (load_acq(&g_inbox1) > 0) {
    int take = 1;
    g_inbox1 = 0;
#ifdef INJECT_BUG_SPLIT_WORKING_REMOTE_READ
    /* Original buggy two-counter update */
    fetch_add_acq_rel(&g_working, 1);
    fetch_add_acq_rel(&g_remote_pending, -take);
#elif defined(INJECT_BUG_NONATOMIC_IDLE_INBOX_DRAIN)
    /* Buggy non-atomic two-step inflight update: decrements BEFORE incrementing! */
    fetch_add_acq_rel(&g_inflight, -take);
    fetch_add_acq_rel(&g_inflight, 1);
#else
    /* Safe single-word atomic 1 - take handoff (never visits 0!) */
    fetch_add_acq_rel(&g_inflight, 1 - take);
#endif
    /* Worker 1 scans popped mature object and routes a child to w2's inbox */
    g_inbox2 = 1;
#ifdef INJECT_BUG_SPLIT_WORKING_REMOTE_READ
    fetch_add_acq_rel(&g_remote_pending, 1);
    fetch_add_acq_rel(&g_working, -1);
#else
    fetch_add_acq_rel(&g_inflight, 1);
    /* Worker 1 finishes and goes idle */
    fetch_add_acq_rel(&g_inflight, -1);
#endif
  }
  fence_acq_rel();
  g_w1_done = 1;
}

static void worker2_check_exit(void) {
#ifdef INJECT_BUG_SPLIT_WORKING_REMOTE_READ
  /* Original buggy non-atomic split read of working == 0 && remote_pending == 0 */
  int w = load_acq(&g_working);
  int r = load_acq(&g_remote_pending);
  if (w == 0 && r == 0) {
    g_w2_exited = 1;
  }
#else
  /* Safe single-word atomic quiescence check */
  if (load_acq(&g_inflight) == 0) {
    g_w2_exited = 1;
  }
#endif
}

/* Scenario 1: Global mark stack inclusion in single-word inflight counter */
static volatile int g_mark_stack;
static volatile int g_s_inflight;
static volatile int g_s_w2_exited;

static void stack_worker1(void) {
  /* Worker 1 starts with 1 item on global mark_stack (inflight includes stack!) */
  if (load_acq(&g_mark_stack) > 0) {
    int take = 1;
    g_mark_stack = 0;
#ifdef INJECT_BUG_OMIT_MARK_STACK_FROM_INFLIGHT
    /* Bug: inflight did NOT count mark_stack (so inflight started at 0!) */
    fetch_add_acq_rel(&g_s_inflight, 1);
#else
    /* Safe: inflight included mark_stack (+1), atomic 1 - take keeps inflight >= 1 */
    fetch_add_acq_rel(&g_s_inflight, 1 - take);
#endif
    /* Routes child to w2 */
    g_inbox2 = 1;
    fetch_add_acq_rel(&g_s_inflight, 1);
    fetch_add_acq_rel(&g_s_inflight, -1);
  }
}

static void stack_worker2(void) {
  if (load_acq(&g_s_inflight) == 0) {
    g_s_w2_exited = 1;
  }
}

int main(void) {
  int scenario;
  __CPROVER_assume(scenario == 0 || scenario == 1);

  if (scenario == 0) {
    g_working = 0;
    g_remote_pending = 1;
    g_inflight = 1; /* 0 working + 1 inbox1 + 0 stack */
    g_inbox1 = 1;
    g_inbox2 = 0;
    g_w2_exited = 0;
    g_w1_done = 0;

    __CPROVER_ASYNC_1: worker1_drain_and_route();
    worker2_check_exit();

    fence_acq_rel();
    /* Once w1 finishes routing to inbox2, if w2 already exited to BARRIER(),
     * inbox2 is permanently orphaned (12-core livelock)! */
    if (g_w1_done && g_w2_exited) {
      assert(g_inbox2 == 0);
    }
    /* Even before w1 finishes, w2 MUST NOT have exited while inbox1 was live! */
    assert(g_w2_exited == 0);
  } else {
    g_mark_stack = 1;
    g_inbox2 = 0;
#ifdef INJECT_BUG_OMIT_MARK_STACK_FROM_INFLIGHT
    g_s_inflight = 0;
#else
    g_s_inflight = 1; /* 0 working + 0 inboxes + 1 mark_stack */
#endif
    g_s_w2_exited = 0;

    __CPROVER_ASYNC_2: stack_worker1();
    stack_worker2();

    fence_acq_rel();
    assert(g_s_w2_exited == 0);
  }

  return 0;
}
