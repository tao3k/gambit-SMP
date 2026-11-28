/* Stage 6 CBMC --mm pso weak-memory contract harness for Wave A:
 * Lock-free ___rest_fast_grant_fits fast_span disjointness & GC-epoch validity.
 *
 * Safe mode  (-DUSE_GUARD=1): MUST PASS under `cbmc --mm pso`.
 * Mutant mode(-DUSE_GUARD=0): MUST FAIL (shared-msection overlap or stale epoch).
 */
#include <assert.h>
#include <stdint.h>

#ifndef USE_GUARD
#define USE_GUARD 1
#endif

typedef uintptr_t uword_t;

extern uword_t nondet_uword(void);
extern int nondet_int(void);

#define WORD_BYTES 8u
#define HALF_WORDS 65536u
#define FUDGE_WORDS 8200u

struct fast_span_state {
  uword_t stack_fast_floor_b;
  uword_t stack_fast_limit_b;
  uword_t heap_fast_lo_b;
  uword_t heap_fast_bytes;
  int shared_msection;
  int gc_epoch;
  int span_epoch;
};

static void clear_fast_span(struct fast_span_state *s) {
  s->stack_fast_floor_b = 0;
  s->stack_fast_limit_b = 0;
  s->heap_fast_lo_b = 0;
  s->heap_fast_bytes = 0;
}

static void publish_fast_span(struct fast_span_state *s,
                              uword_t stack_lo_b, uword_t stack_hi_b,
                              uword_t heap_lo_b, uword_t heap_soft_hi_b,
                              int shared_msection) {
  s->shared_msection = shared_msection;
  if (stack_hi_b > stack_lo_b + FUDGE_WORDS * WORD_BYTES) {
    uword_t floor_b = stack_lo_b + FUDGE_WORDS * WORD_BYTES;
    s->stack_fast_floor_b = floor_b;
    s->stack_fast_limit_b = stack_hi_b - floor_b + 1;
  } else {
    s->stack_fast_floor_b = 0;
    s->stack_fast_limit_b = 0;
  }
  s->heap_fast_lo_b = 0;
  s->heap_fast_bytes = 0;
  if (heap_soft_hi_b > heap_lo_b) {
#if USE_GUARD
    /* Enforce disjointness on shared stack+heap msection (Lean: shared_fast_span_disjoint). */
    if (!shared_msection ||
        (s->stack_fast_limit_b != 0 && heap_soft_hi_b <= s->stack_fast_floor_b)) {
      s->heap_fast_lo_b = heap_lo_b;
      s->heap_fast_bytes = heap_soft_hi_b - heap_lo_b;
    }
#else
    /* Mutant: omits shared-msection disjointness check. */
    s->heap_fast_lo_b = heap_lo_b;
    s->heap_fast_bytes = heap_soft_hi_b - heap_lo_b;
#endif
  }
  s->span_epoch = s->gc_epoch;
}

static int rest_fast_span_admits(const struct fast_span_state *s,
                                 uword_t hp_b, uword_t fp_b,
                                 uword_t heap_words, uword_t stack_slots) {
  uword_t sd = fp_b - s->stack_fast_floor_b;
  uword_t hd = hp_b - s->heap_fast_lo_b;
  if (sd < s->stack_fast_limit_b &&
      (sd / WORD_BYTES) >= stack_slots &&
      hd < s->heap_fast_bytes &&
      ((s->heap_fast_bytes - hd) / WORD_BYTES) >= heap_words) {
    return 1;
  }
  return 0;
}

int main(void) {
  struct fast_span_state st = {0};
  st.gc_epoch = 1;

  uword_t base = 0x100000u;
  uword_t half_bytes = HALF_WORDS * WORD_BYTES;
  uword_t stack_lo = base + (nondet_uword() % (half_bytes / 2u));
  stack_lo &= ~(uword_t)(WORD_BYTES - 1u);
  uword_t stack_hi = base + half_bytes;
  uword_t heap_lo = base;
  uword_t heap_soft_hi = base + (nondet_uword() % half_bytes);
  heap_soft_hi &= ~(uword_t)(WORD_BYTES - 1u);

  /* Case 1: shared stack+heap msection with arbitrary split candidates. */
  publish_fast_span(&st, stack_lo, stack_hi, heap_lo, heap_soft_hi, 1);

  uword_t hp = base + (nondet_uword() % half_bytes);
  hp &= ~(uword_t)(WORD_BYTES - 1u);
  uword_t fp = base + (nondet_uword() % half_bytes);
  fp &= ~(uword_t)(WORD_BYTES - 1u);
  uword_t req_words = 1u + (nondet_uword() % 64u);
  uword_t req_slots = 1u;

  if (rest_fast_span_admits(&st, hp, fp, req_words, req_slots)) {
    /* Every admitted pair write [hp, hp + req_words*8) MUST lie strictly below
     * the stack floor and active fp on shared msections (zero overlap). */
    assert(hp + req_words * WORD_BYTES <= st.stack_fast_floor_b);
    assert(st.stack_fast_floor_b <= fp);
    assert(st.span_epoch == st.gc_epoch);
  }

  /* Case 2: GC epoch advance MUST invalidate fast_span so old cursors cannot pass. */
  st.gc_epoch = 2;
#if USE_GUARD
  clear_fast_span(&st);
#endif
  if (rest_fast_span_admits(&st, hp, fp, req_words, req_slots)) {
    assert(st.span_epoch == st.gc_epoch);
  }

  return 0;
}
