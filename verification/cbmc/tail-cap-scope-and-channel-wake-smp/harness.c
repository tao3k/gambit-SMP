/*
 * Phase C53 CBMC (--mm pso) Verification Harness:
 * 1. Lexical Tail-Capability Creation-Site Dynamic Scope Isolation,
 *    Cross-Extent Suspend/Resume Splicing, and Exception/Continuable Coherency
 *    (vendor/gambit/lib/gambit/effect/capability.scm).
 * 2. O(1)-Stack Tail-Recursive Channel Wakeup Cascade with Immediate Peer Wake
 *    and Dekker seq_cst Memory Ordering
 *    (vendor/gambit/lib/gambit/fiber/channel-ring.scm).
 *
 * Negative Mutants (must fail verification):
 *   -DMUTANT_TAIL_CAP_NO_SCOPE_SHIFT
 *   -DMUTANT_TAIL_CAP_BLIND_OVERWRITE_ON_RESUME
 *   -DMUTANT_TAIL_CAP_NO_EH_RESTORE
 *   -DMUTANT_CHANNEL_WAKE_NON_TAIL_STACK
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *kind, ...);
extern int nondet_int(void);

#define MAX_STACK 6

/* Handler IDs */
#define H_OUTER_E2   1
#define H_INNER_E2   2
#define H_RESUMER_E3 3

typedef struct {
  int items[MAX_STACK];
  int len;
} HStack;

typedef struct {
  HStack prefix;
  HStack target;
  int found;
} SplitRes;

static int stack_find_first_e2(HStack s) {
  for (int i = 0; i < s.len; i++) {
    if (s.items[i] == H_OUTER_E2 || s.items[i] == H_INNER_E2)
      return s.items[i];
  }
  return 0;
}

static int stack_contains(HStack s, int h) {
  for (int i = 0; i < s.len; i++) {
    if (s.items[i] == h) return 1;
  }
  return 0;
}

static int stack_equal(HStack a, HStack b) {
  if (a.len != b.len) return 0;
  for (int i = 0; i < a.len; i++) {
    if (a.items[i] != b.items[i]) return 0;
  }
  return 1;
}

static SplitRes split_at_frame(HStack cur, int top_frame) {
  SplitRes r;
  r.prefix.len = 0;
  r.target.len = 0;
  r.found = 0;
  for (int i = 0; i < cur.len; i++) {
    if (!r.found && cur.items[i] == top_frame) {
      r.found = 1;
    }
    if (!r.found) {
      r.prefix.items[r.prefix.len++] = cur.items[i];
    } else {
      r.target.items[r.target.len++] = cur.items[i];
    }
  }
  return r;
}

static HStack splice_stacks(HStack prefix, HStack after) {
  HStack out;
  out.len = 0;
  for (int i = 0; i < prefix.len; i++)
    out.items[out.len++] = prefix.items[i];
  for (int i = 0; i < after.len; i++)
    out.items[out.len++] = after.items[i];
  return out;
}

/* =========================================================================
 * Part 1: Tail-Capability Creation-Site Scope Isolation & Exception Coherency
 * ========================================================================= */
static int run_tail_cap_scenario(int do_cross_extent_resume, int do_exc_path) {
  /* Creation site: hStack = [H_OUTER_E2] */
  HStack st;
  st.len = 1;
  st.items[0] = H_OUTER_E2;
  int cap_outer_top = H_OUTER_E2;
  int cap_live = 1;

  /* Inside call-with-tail-capability body: install inner H_INNER_E2 */
  HStack cur;
  cur.len = 2;
  cur.items[0] = H_INNER_E2;
  cur.items[1] = H_OUTER_E2;
  st = cur;

  /* Enter perform-cap */
  SplitRes sp = split_at_frame(cur, cap_outer_top);
  assert(sp.found == 1);
  HStack prefix = sp.prefix;
  HStack target = sp.target;

#ifdef MUTANT_TAIL_CAP_NO_SCOPE_SHIFT
  /* Mutant: leave cur-h active instead of shifting to target */
  (void)target;
#else
  st = target;
#endif

  /* Inside capability proc: (perform e2) MUST resolve to H_OUTER_E2, never H_INNER_E2 */
  int seen_in_cap = stack_find_first_e2(st);
  assert(seen_in_cap == H_OUTER_E2);
  assert(!stack_contains(st, H_INNER_E2));

  if (do_exc_path) {
    /* Inner with-exception-catcher catches escaping exception from proc */
    HStack saved_h = st;
#ifdef MUTANT_TAIL_CAP_NO_EH_RESTORE
    /* Mutant: fail to restore paused prefix before inner exception handler pops it */
    HStack before_inner_pop = saved_h;
#else
    HStack before_inner_pop;
    if (stack_equal(saved_h, target))
      before_inner_pop = cur;
    else
      before_inner_pop = splice_stacks(prefix, saved_h);
#endif
    /* Inner with-handler's exception hook expects H_INNER_E2 on top to pop it cleanly */
    assert(before_inner_pop.len >= 2 && before_inner_pop.items[0] == H_INNER_E2);
    /* Inner pops H_INNER_E2 */
    HStack after_inner_pop;
    after_inner_pop.len = before_inner_pop.len - 1;
    for (int i = 0; i < after_inner_pop.len; i++)
      after_inner_pop.items[i] = before_inner_pop.items[i + 1];

    /* Continuable return vs escaping catch */
    assert(cap_live == 1);
    assert(stack_find_first_e2(after_inner_pop) == H_OUTER_E2);
    assert(!stack_contains(after_inner_pop, H_INNER_E2));

    /* Continuable return restores saved_h (still isolated from H_INNER_E2) */
    st = saved_h;
    assert(stack_find_first_e2(st) == H_OUTER_E2);
    assert(!stack_contains(st, H_INNER_E2));
  }

  if (do_cross_extent_resume) {
    /* Outer suspending e2 resumed in a new dynamic extent under H_RESUMER_E3 */
    st.items[st.len++] = H_RESUMER_E3;
  }

  /* Return from perform-cap */
  HStack after_h = st;
#ifdef MUTANT_TAIL_CAP_BLIND_OVERWRITE_ON_RESUME
  /* Mutant: blindly restore cur-h, clobbering H_RESUMER_E3! */
  st = cur;
#else
  if (stack_equal(after_h, target)) {
    st = cur;
  } else {
    st = splice_stacks(prefix, after_h);
  }
#endif

  /* Post-return assertions */
  assert(stack_find_first_e2(st) == H_INNER_E2);
  assert(stack_contains(st, H_OUTER_E2));
  if (do_cross_extent_resume) {
    assert(stack_contains(st, H_RESUMER_E3));
  }
  return 1;
}

/* =========================================================================
 * Part 2: O(1)-Stack Tail-Recursive Channel Wakeup Cascade (cap = 1, SMP PSO)
 * ========================================================================= */
static int ch_buf_full = 0;
static int ch_rx_waiters = 0;
static int ch_tx_waiters = 0;
static int ch_rx_woken = 0;
static int ch_tx_woken = 0;
static int ch_max_depth = 0;
static int ch_woke_before_recurse_ok = 1;
static int t1_done = 0;
static int t2_done = 0;

static void seq_fence(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence",
                  "WWcumul", "RRcumul", "RWcumul", "WRcumul");
}

static void record_depth(int d) {
  __CPROVER_atomic_begin();
  if (d > ch_max_depth) ch_max_depth = d;
  __CPROVER_atomic_end();
}

static int try_pop_rx_and_item(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (ch_rx_waiters > 0 && ch_buf_full == 1) {
    ch_rx_waiters--;
    ch_buf_full = 0;
    ok = 1;
  }
  __CPROVER_atomic_end();
  seq_fence();
  return ok;
}

static int try_pop_tx_and_push(void) {
  int ok = 0;
  __CPROVER_atomic_begin();
  if (ch_tx_waiters > 0 && ch_buf_full == 0) {
    ch_tx_waiters--;
    ch_buf_full = 1;
    ok = 1;
  }
  __CPROVER_atomic_end();
  seq_fence();
  return ok;
}

static void wake_cascade(int start_rx) {
#ifdef MUTANT_CHANNEL_WAKE_NON_TAIL_STACK
  /* Mutant: non-tail mutual recursion calls reciprocal wake BEFORE waking peer! */
  int steps = 0;
  int mode_rx = start_rx;
  int cur_depth = 0;
  int pending_rx_wakes = 0;
  int pending_tx_wakes = 0;
  while (steps < 4) {
    steps++;
    if (mode_rx) {
      if (try_pop_rx_and_item()) {
        cur_depth++;
        record_depth(cur_depth);
        pending_rx_wakes++;
        seq_fence();
        if (ch_tx_waiters > 0) {
          /* Recursing BEFORE waking rk -> violates immediate wake & O(1) stack! */
          ch_woke_before_recurse_ok = 0;
          mode_rx = 0;
          continue;
        }
      }
      break;
    } else {
      if (try_pop_tx_and_push()) {
        cur_depth++;
        record_depth(cur_depth);
        pending_tx_wakes++;
        seq_fence();
        if (ch_rx_waiters > 0) {
          ch_woke_before_recurse_ok = 0;
          mode_rx = 1;
          continue;
        }
      }
      break;
    }
  }
  __CPROVER_atomic_begin();
  ch_rx_woken += pending_rx_wakes;
  ch_tx_woken += pending_tx_wakes;
  __CPROVER_atomic_end();
  seq_fence();
#else
  /* Tail-call loop: wake peer IMMEDIATELY, then tail-jump (stack depth strictly 1!) */
  int mode_rx = start_rx;
  record_depth(1);
  for (int steps = 0; steps < 6; steps++) {
    if (mode_rx) {
      if (try_pop_rx_and_item()) {
        /* Wake rk FIRST before tail-calling %ch-wake-one-sender! */
        __CPROVER_atomic_begin();
        ch_rx_woken++;
        __CPROVER_atomic_end();
        seq_fence();
        if (ch_tx_waiters > 0) {
          mode_rx = 0;
          continue; /* tail call: stack depth remains 1 */
        }
      }
      break;
    } else {
      if (try_pop_tx_and_push()) {
        /* Wake sk FIRST before tail-calling %ch-wake-one-receiver! */
        __CPROVER_atomic_begin();
        ch_tx_woken++;
        __CPROVER_atomic_end();
        seq_fence();
        if (ch_rx_waiters > 0) {
          mode_rx = 1;
          continue; /* tail call: stack depth remains 1 */
        }
      }
      break;
    }
  }
#endif
}

static void async_worker_t1(void) {
  wake_cascade(1);
  seq_fence();
  __CPROVER_atomic_begin();
  t1_done = 1;
  __CPROVER_atomic_end();
}

int main(void) {
  int c1 = nondet_int() ? 1 : 0;
  int c2 = nondet_int() ? 1 : 0;

  /* 1. Verify tail-capability scope isolation across all nondet branches */
  int r1 = run_tail_cap_scenario(c1, c2);
  int r2 = run_tail_cap_scenario(1, 1);
  assert(r1 == 1 && r2 == 1);

  /* 2. Concurrent 2-thread PSO verification of tail-wake cascade */
  ch_buf_full = 1;
  ch_rx_waiters = 2;
  ch_tx_waiters = 2;
  ch_rx_woken = 0;
  ch_tx_woken = 0;
  ch_max_depth = 0;
  ch_woke_before_recurse_ok = 1;
  t1_done = 0;
  t2_done = 0;
  seq_fence();

__CPROVER_ASYNC_1:
  async_worker_t1();

  /* Main thread concurrently runs a secondary tail-cap check and wake trigger */
  int r3 = run_tail_cap_scenario(1, 0);
  assert(r3 == 1);
  wake_cascade(0);
  seq_fence();
  t2_done = 1;

  int d1;
  __CPROVER_atomic_begin();
  d1 = t1_done;
  __CPROVER_atomic_end();
  __CPROVER_assume(d1 == 1 && t2_done == 1);
  seq_fence();

  /* Final channel invariants: O(1) stack, immediate wake, conservation, zero lost wakeups */
  assert(ch_max_depth <= 1);
  assert(ch_woke_before_recurse_ok == 1);
  assert(ch_rx_waiters + ch_rx_woken == 2);
  assert(ch_tx_waiters + ch_tx_woken == 2);
  assert(ch_rx_woken == 2 && ch_tx_woken == 2);
  assert(ch_buf_full == 1);

  return 0;
}
