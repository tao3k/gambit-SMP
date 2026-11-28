/*
 * CBMC (--mm pso) Adversarial Weak-Memory Verification Harness for Phase C4-B:
 *   1. Chez PLDI '90 Bounded Multi-Frame Chunk Restore (underflow_limit)
 *      with contiguous link rewiring & ZGC Stack Watermark SATB shading
 *   2. Racket CS ICFP '20 Tail-Call-Preserving Continuation Marks
 *
 * Negative Mutants (6/6 must FAIL assertion when enabled):
 *   -DINJECT_BUG_SHADE_ONLY_TOP_FRAME   : only shades frame 0 of a k-frame chunk during SATB
 *   -DINJECT_BUG_CHUNK_OVERRUN          : copies past known_break / dest room limit
 *   -DINJECT_BUG_TAIL_MARK_STACK_GROWTH : pushes a new mark frame even when R0 == mark_pop_ra
 *   -DINJECT_BUG_IGNORE_FUDGE_ZONE      : ignores MSECTION_FUDGE headroom above dest_lo
 *   -DINJECT_BUG_REWIND_DURING_SATB     : reclaims stack cont in-place while satb_active == 1
 *   -DINJECT_BUG_UNSCRUBBED_GVM_REG     : leaves reclaimed stack cont live in GVM R2 across poll
 */

#include <assert.h>
#include <stdint.h>

#define MAX_FRAMES 4
#define UNDERFLOW_LIMIT_WORDS 16
#define FRAME_WORDS 4
#define DEST_LO 0
#define MSECTION_FUDGE 8

/* Simulated source stack frames (0 = top, 3 = bottom at known_break) */
static int src_frame_payload[MAX_FRAMES] = {101, 202, 303, 404};
static int src_frame_shaded[MAX_FRAMES]  = {0, 0, 0, 0};

/* Simulated destination stack buffer */
static int dest_frames[MAX_FRAMES];
static int dest_link_is_break[MAX_FRAMES];

static volatile int satb_active = 1;

static int restore_chunk(int start_idx, int avail_frames, int dest_fp, int *out_count) {
  int words_used = 0;
  int count = 0;
  int idx = start_idx;
#ifdef INJECT_BUG_IGNORE_FUDGE_ZONE
  int dest_room = (dest_fp > DEST_LO) ? (dest_fp - DEST_LO) : 0;
#else
  int safe_lo = DEST_LO + MSECTION_FUDGE;
  int dest_room = (dest_fp > safe_lo) ? (dest_fp - safe_lo) : 0;
#endif

  while (idx < MAX_FRAMES && count < avail_frames) {
#ifndef INJECT_BUG_CHUNK_OVERRUN
    if (count > 0 && words_used + FRAME_WORDS > UNDERFLOW_LIMIT_WORDS)
      break;
    if (count > 0 && words_used + FRAME_WORDS > dest_room)
      break;
    if (count == 0 && words_used + FRAME_WORDS > (dest_fp - DEST_LO))
      break;
#else
    /* Buggy: ignores dest_room limit */
    (void)dest_room;
#endif
    dest_frames[count] = src_frame_payload[idx];
    dest_link_is_break[count] = 0;
    words_used += FRAME_WORDS;
    count++;
    idx++;
  }

  /* Boundary invariants: hard limit never crossed; multi-frame chunks preserve MSECTION_FUDGE! */
  assert(dest_fp - words_used >= DEST_LO);
  if (count >= 2) {
    assert(dest_fp - words_used >= DEST_LO + MSECTION_FUDGE);
  }

  /* Only the LAST frame of the chunk connects to handler_break if more frames remain */
  if (count > 0) {
    if (idx < MAX_FRAMES) {
      dest_link_is_break[count - 1] = 1;
    }
    /* ZGC Stack Watermark x SATB: shade ALL frames in the restored chunk! */
    if (satb_active) {
#ifdef INJECT_BUG_SHADE_ONLY_TOP_FRAME
      src_frame_shaded[start_idx] = 1;
#else
      for (int i = 0; i < count; i++) {
        src_frame_shaded[start_idx + i] = 1;
      }
#endif
    }
  }

  *out_count = count;
  return idx;
}

/* Racket CS Tail-Call-Preserving Continuation Marks model */
static int mark_depth = 0;
static int top_mark_val = 0;
static int r0_is_mark_pop = 0;

static void with_mark_step(int val) {
  if (r0_is_mark_pop) {
#ifdef INJECT_BUG_TAIL_MARK_STACK_GROWTH
    mark_depth++;
#endif
    top_mark_val = val;
  } else {
    mark_depth++;
    r0_is_mark_pop = 1;
    top_mark_val = val;
  }
}

/* SATB-gated in-place stack continuation rewind + GVM register scrub model */
static int try_rewind_in_place(int satb_on, int *cont_overwritten, int *gvm_r2_cont) {
#ifndef INJECT_BUG_REWIND_DURING_SATB
  if (satb_on)
    return 0; /* Must refuse while concurrent SATB major GC is active! */
#endif
  *cont_overwritten = 1;
#ifndef INJECT_BUG_UNSCRUBBED_GVM_REG
  *gvm_r2_cont = 0; /* Scrub dead GVM R2 so next ___POLL -> ___PUSH_REGS never spills it! */
#endif
  return 1;
}

int main(void) {
  /* 1. Multi-frame chunk restore with dest_fp = 16 (safe_lo = 8 => 8 words = 2 frames max) */
  int c1 = 0;
  int next = restore_chunk(0, 4, 16, &c1);
  assert(c1 == 2);
  assert(next == 2);
  /* Frame 0 must NOT bounce to handler_break; frame 1 MUST link to handler_break */
  assert(dest_link_is_break[0] == 0);
  assert(dest_link_is_break[1] == 1);
  /* BOTH restored frames 0 and 1 must be SATB-shaded! */
  assert(src_frame_shaded[0] == 1);
  assert(src_frame_shaded[1] == 1);

  /* Second chunk restores remaining 2 frames [2..3] down to known_break */
  int c2 = 0;
  next = restore_chunk(next, 2, 24, &c2);
  assert(c2 == 2);
  assert(next == 4);
  assert(dest_link_is_break[0] == 0);
  assert(dest_link_is_break[1] == 0); /* reached known_break */
  assert(src_frame_shaded[2] == 1);
  assert(src_frame_shaded[3] == 1);

  /* 2. SATB-gated in-place rewind + dead GVM R2 register scrub before ___POLL */
  int cont_overwritten = 0;
  int gvm_r2_cont = 1; /* R2 initially holds stack-allocated escape_k/sub_k */
  int rewound_satb = try_rewind_in_place(1, &cont_overwritten, &gvm_r2_cont);
  assert(rewound_satb == 0);
  assert(cont_overwritten == 0);
  int rewound_idle = try_rewind_in_place(0, &cont_overwritten, &gvm_r2_cont);
  assert(rewound_idle == 1);
  assert(cont_overwritten == 1);
  /* On next ___POLL -> ___PUSH_REGS, R2 MUST NOT hold reclaimed stack cont! */
  assert(gvm_r2_cont == 0);

  /* 3. Tail-call-preserving continuation marks: 5 tail iterations => depth stays 1 */
  with_mark_step(10);
  with_mark_step(20);
  with_mark_step(30);
  with_mark_step(40);
  with_mark_step(50);
  assert(mark_depth == 1);
  assert(top_mark_val == 50);

  return 0;
}
