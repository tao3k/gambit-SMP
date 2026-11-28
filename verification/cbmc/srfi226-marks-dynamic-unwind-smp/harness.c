/*
 * CBMC --mm pso verification harness for SRFI-226 continuation-mark dynamic
 * unwind, cross-thread SMP replay isolation, tail-checked immediate marks,
 * and prompt-scoped `continuation-marks` slicing.
 *
 * Uses compact scalar globals (no pointer parameters or large struct copies
 * under __CPROVER_ASYNC_1) so PSO partial-order encoding completes in < 1s.
 *
 * Negative mutants (all 4 must FAIL with VERIFICATION FAILED):
 *   -DINJECT_BUG_STALE_CAPTURE_ST_AND_MS  : exception restores capture-time st & ms
 *   -DINJECT_BUG_TAIL_REPLACE_CHANGES_FID : tail replace alters frame fid
 *   -DINJECT_BUG_IMMEDIATE_IGNORES_R0     : immediate mark skips r0 == MARK_POP_RA
 *   -DINJECT_BUG_CONT_MARKS_IGNORES_TAG   : continuation-marks ignores inner prompt tag
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

#define MARK_POP_RA 1
#define NONTAIL_RA  2
#define PROMPT_RA   3

#define KEY_OUTER   1
#define KEY_INNER   2
#define KEY_RESUMER 3

#define VAL_DEAD    100
#define VAL_IN1     201
#define VAL_IN2     202
#define VAL_RESUMER 300
#define VAL_DEFAULT -1

/* Thread 0 mark stack (2-slot scalar representation: index 0 = top) */
static int t0_len;
static int t0_fid0, t0_key0, t0_val0;
static int t0_fid1, t0_key1, t0_val1;

/* Thread 1 mark stack (2-slot scalar representation: index 0 = top) */
static int t1_len;
static int t1_fid0, t1_key0, t1_val0;
static int t1_fid1, t1_key1, t1_val1;

static int t1_done_flag;

/* Immutable captured continuation payload */
static int cap_fid;
static int cap_frame_fid, cap_frame_key, cap_frame_val;
/* Stale capture-time outer mark snapshot (for mutant only) */
static int stale_t0_len, stale_t0_fid0, stale_t0_key0, stale_t0_val0;

static int immediate_mark_t0(int r0, int key) {
#ifdef INJECT_BUG_IMMEDIATE_IGNORES_R0
  (void)r0;
  if (t0_len > 0 && t0_key0 == key) return t0_val0;
  return VAL_DEFAULT;
#else
  if (r0 == MARK_POP_RA && t0_len > 0 && t0_key0 == key) {
    return t0_val0;
  }
  return VAL_DEFAULT;
#endif
}

/* Pure self-replay prompt-tag slicing on 4-frame marks vs 3-frame stop */
static int slice_self_replay_4_3(int m0, int m1, int m2, int m3,
                                 int s0, int s1, int s2) {
#ifdef INJECT_BUG_CONT_MARKS_IGNORES_TAG
  (void)m0; (void)m1; (void)m2; (void)m3;
  (void)s0; (void)s1; (void)s2;
  return 4;
#else
  /* Check i=0 (rem=4 > slen=3 -> no) */
  /* Check i=1 (rem=3): (m1,m2,m3) == (s0,s1,s2)? */
  if (m1 == s0 && m2 == s1 && m3 == s2) return 1;
  /* Check i=2 (rem=2): (m2,m3) == (s0,s1)? */
  if (m2 == s0 && m3 == s1) return 2;
  /* Check i=3 (rem=1): m3 == s0? */
  if (m3 == s0) return 3;
  return 4;
#endif
}

static void thread1_replay_and_raise(void) {
  /* Thread 1 runs under its own resumer mark and replays captured continuation */
  t1_fid0 = cap_frame_fid; t1_key0 = cap_frame_key; t1_val0 = cap_frame_val;
  t1_fid1 = 30;            t1_key1 = KEY_RESUMER;   t1_val1 = VAL_RESUMER;
  t1_len = 2;

  /* Exception raised inside replayed continuation */
#ifdef INJECT_BUG_STALE_CAPTURE_ST_AND_MS
  /* Buggy: overwrites capture-time thread t0 marks with stale outer snapshot */
  __CPROVER_atomic_begin();
  t0_len  = stale_t0_len;
  t0_fid0 = stale_t0_fid0;
  t0_key0 = stale_t0_key0;
  t0_val0 = stale_t0_val0;
  __CPROVER_atomic_end();
#else
  /* Fixed: unwinds dynamically on current thread t1 marks by cap_fid */
  if (t1_len >= 1 && t1_fid0 == cap_fid) {
    t1_fid0 = t1_fid1; t1_key0 = t1_key1; t1_val0 = t1_val1;
    t1_len = t1_len - 1;
  } else if (t1_len >= 2 && t1_fid1 == cap_fid) {
    t1_len = t1_len - 2;
  }
#endif

  /* Inside catcher on Thread 1: resumer mark survives, inner mark is popped */
  assert(t1_len == 1);
  assert(t1_key0 == KEY_RESUMER);
  assert(t1_val0 == VAL_RESUMER);

  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence");
  __CPROVER_atomic_begin();
  t1_done_flag = 1;
  __CPROVER_atomic_end();
}

int main(void) {
  t0_len = 0;
  t1_len = 0;
  t1_done_flag = 0;

  /* 1. Thread 0 enters outer(DEAD), captures inner(IN1 -> tail-replaced IN2) */
  t0_fid0 = 10; t0_key0 = KEY_OUTER; t0_val0 = VAL_DEAD;
  t0_len = 1;
  stale_t0_len = 1; stale_t0_fid0 = 10; stale_t0_key0 = KEY_OUTER; stale_t0_val0 = VAL_DEAD;

  /* Push inner frame (fid=20) on top of outer */
  t0_fid1 = t0_fid0; t0_key1 = t0_key0; t0_val1 = t0_val0;
  t0_fid0 = 20; t0_key0 = KEY_INNER; t0_val0 = VAL_IN1;
  t0_len = 2;
  cap_fid = 20;

  /* Tail-position with-continuation-mark replaces top entry while preserving fid */
#ifdef INJECT_BUG_TAIL_REPLACE_CHANGES_FID
  t0_fid0 = 999;
#endif
  t0_key0 = KEY_INNER;
  t0_val0 = VAL_IN2;

  /* Immediate mark check: tail sees VAL_IN2, non-tail & cross-prompt see VAL_DEFAULT */
  assert(immediate_mark_t0(MARK_POP_RA, KEY_INNER) == VAL_IN2);
  assert(immediate_mark_t0(NONTAIL_RA, KEY_INNER) == VAL_DEFAULT);
  assert(immediate_mark_t0(PROMPT_RA, KEY_INNER) == VAL_DEFAULT);

  /* Capture inner frame and unwind Thread 0 completely */
  cap_frame_fid = t0_fid0;
  cap_frame_key = t0_key0;
  cap_frame_val = t0_val0;
  t0_len = 0;

  /* 2. Spawn concurrent Thread 1 replaying & raising while Thread 0 checks isolation */
  __CPROVER_ASYNC_1: thread1_replay_and_raise();

  /* Thread 0 concurrently reads its own mark stack and must NEVER observe VAL_DEAD */
  __CPROVER_atomic_begin();
  int len0_a = t0_len;
  __CPROVER_atomic_end();
  assert(len0_a == 0);

  /* 3. Prompt-scoped `continuation-marks` slicing under nested self-replay */
  int fA = 1, fB = 2, fE = 3;
  assert(slice_self_replay_4_3(fA, fB, fA, fB, fA, fB, fE) == 2);

  /* Re-verify Thread 0 mark stack clean after Thread 1 completes */
  int done1 = 0;
  __CPROVER_atomic_begin();
  done1 = t1_done_flag;
  __CPROVER_atomic_end();
  if (done1) {
    __CPROVER_atomic_begin();
    int len0_b = t0_len;
    __CPROVER_atomic_end();
    assert(len0_b == 0);
  }
  return 0;
}
