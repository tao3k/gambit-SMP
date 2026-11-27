/*
 * CBMC C23 Contract Harness for Stage-2 Big Old-Gen Architecture:
 *   1. Chez Creator-Owned Segment Routing & Remote Mark Queues (cross-owner cycles)
 *   2. Zero-Contention Marking (any_marked flag + deferred Phase R-C live_words)
 *   3. Multi-Hole Immix Line Recycling (consume hole 1, advance to hole 2, never overlap live)
 *
 * Negative mutation checks:
 *   -DINJECT_BUG_SKIP_REMOTE_DRAIN -> breaks quiescence completeness
 *   -DINJECT_BUG_RECYCLE_LIVE_LINE -> breaks Immix live-object disjointness
 */
#include <stdint.h>
#include <stdbool.h>

extern unsigned int nondet_uint(void);

enum { N_WORKERS = 2, N_SECS = 4, N_LINES = 4, N_OBJS = 6 };

static const unsigned int obj_sec[N_OBJS]  = { 0, 0, 1, 1, 2, 3 };
static const unsigned int obj_line[N_OBJS] = { 0, 2, 0, 1, 1, 0 };
/* Cross-owner cyclic graph: 0(w0)->2(w1)->4(w0)->1(w0)->0(w0), 2->3(w1), 5 unreachable */
static const uint8_t adj_mask[N_OBJS] = {
  (1u << 2),
  (1u << 0),
  (1u << 3) | (1u << 4),
  0u,
  (1u << 1),
  0u,
};

static inline unsigned int sec_owner(unsigned int s) { return s & 1u; }

static uint8_t marked_mask;
static uint8_t any_marked_mask;
static uint8_t local_mask[N_WORKERS];
static uint8_t remote_mask[N_WORKERS];

static void mark_owned(unsigned int w, unsigned int o) {
  unsigned int s = obj_sec[o];
  __CPROVER_assert(sec_owner(s) == w, "worker only writes mark bitmaps of owned sections");
  uint8_t bit = (uint8_t)(1u << o);
  if ((marked_mask & bit) == 0u) {
    marked_mask |= bit;
    any_marked_mask |= (uint8_t)(1u << s);
    local_mask[w] |= bit;
  }
}

static void scan_one(unsigned int w, unsigned int o) {
  uint8_t outs = adj_mask[o];
  for (unsigned int t = 0; t < N_OBJS; t++) {
    if ((outs & (1u << t)) != 0u) {
      unsigned int owner = sec_owner(obj_sec[t]);
      if (owner == w) {
        mark_owned(w, t);
      } else {
        remote_mask[owner] |= (uint8_t)(1u << t);
      }
    }
  }
}

static void worker_step(unsigned int w) {
  if (remote_mask[w] != 0u) {
#ifdef INJECT_BUG_SKIP_REMOTE_DRAIN
    remote_mask[w] = 0u;
#else
    for (unsigned int o = 0; o < N_OBJS; o++) {
      if ((remote_mask[w] & (1u << o)) != 0u) {
        remote_mask[w] &= (uint8_t)~(1u << o);
        mark_owned(w, o);
        return;
      }
    }
#endif
  } else if (local_mask[w] != 0u) {
    for (unsigned int o = 0; o < N_OBJS; o++) {
      if ((local_mask[w] & (1u << o)) != 0u) {
        local_mask[w] &= (uint8_t)~(1u << o);
        scan_one(w, o);
        return;
      }
    }
  }
}

int main(void) {
  /* 1. Parallel Initial-Mark clear (disjoint partition by sec_owner) */
  uint8_t cleared = 0u;
  for (unsigned int w = 0; w < N_WORKERS; w++) {
    for (unsigned int s = w; s < N_SECS; s += N_WORKERS) {
      __CPROVER_assert((cleared & (1u << s)) == 0u, "each section cleared exactly once");
      cleared |= (uint8_t)(1u << s);
    }
  }
  __CPROVER_assert(cleared == ((1u << N_SECS) - 1u), "all sections cleared by parallel init-mark");

  marked_mask = 0u;
  any_marked_mask = 0u;
  local_mask[0] = local_mask[1] = 0u;
  remote_mask[0] = remote_mask[1] = 0u;

  /* 2. Seed root (obj 0 -> owner 0) */
  remote_mask[sec_owner(obj_sec[0])] |= (uint8_t)(1u << 0);

  /* 3. Nondeterministic interleaved parallel Remark with Chez remote queues */
  for (unsigned int step = 0; step < 8; step++) {
    unsigned int w = nondet_uint() & 1u;
    worker_step(w);
  }

  /* Drain to quiescence deterministically */
  for (unsigned int round = 0; round < 6; round++) {
    worker_step(0);
    worker_step(1);
  }

  __CPROVER_assert(local_mask[0] == 0u && local_mask[1] == 0u &&
                   remote_mask[0] == 0u && remote_mask[1] == 0u,
                   "quiescence reached: all local and remote queues empty");

  /* Verify quiescence completeness & any_marked soundness */
  for (unsigned int o = 0; o < 5; o++) {
    __CPROVER_assert((marked_mask & (1u << o)) != 0u,
                     "every reachable object across owners/cycles is marked");
  }
  __CPROVER_assert((marked_mask & (1u << 5)) == 0u, "unreachable object remains white");
  __CPROVER_assert((any_marked_mask & (1u << 3)) == 0u,
                   "100%-dead section has any_marked == false");

  /* 4. Parallel Phase R-C deferred live_words & multi-hole Immix free_line_mask */
  unsigned int live_words[N_SECS];
  uint8_t free_line_mask[N_SECS];
  uint8_t promoted_line_mask[N_SECS];

  for (unsigned int s = 0; s < N_SECS; s++) {
    promoted_line_mask[s] = 0u;
    if ((any_marked_mask & (1u << s)) == 0u) {
      for (unsigned int o = 0; o < N_OBJS; o++) {
        if (obj_sec[o] == s) {
          __CPROVER_assert((marked_mask & (1u << o)) == 0u,
                           "any_marked == false implies zero live objects");
        }
      }
      live_words[s] = 0;
      free_line_mask[s] = 0u;
    } else {
      uint8_t live_lines = 0u;
      unsigned int lw = 0;
      for (unsigned int o = 0; o < N_OBJS; o++) {
        if (obj_sec[o] == s && ((marked_mask & (1u << o)) != 0u)) {
          lw++;
          live_lines |= (uint8_t)(1u << obj_line[o]);
        }
      }
      live_words[s] = lw;
#ifdef INJECT_BUG_RECYCLE_LIVE_LINE
      free_line_mask[s] = (uint8_t)((1u << N_LINES) - 1u);
#else
      free_line_mask[s] = (uint8_t)(((1u << N_LINES) - 1u) & ~live_lines);
#endif
    }
  }

  __CPROVER_assert(live_words[0] == 2 && live_words[1] == 2 &&
                   live_words[2] == 1 && live_words[3] == 0,
                   "deferred Phase R-C live_words matches exact live count");

  /* 5. Multi-Hole Immix Recycling: consume ALL free lines in sec 0 (lines 1 and 3) */
  unsigned int holes_recycled_sec0 = 0;
  for (unsigned int l = 0; l < N_LINES; l++) {
    if ((free_line_mask[0] & (1u << l)) != 0u) {
      free_line_mask[0] &= (uint8_t)~(1u << l);
      promoted_line_mask[0] |= (uint8_t)(1u << l);
      holes_recycled_sec0++;
    }
  }
  __CPROVER_assert(holes_recycled_sec0 == 2,
                   "multi-hole Immix recycles BOTH disjoint dead holes in section 0");

  for (unsigned int o = 0; o < N_OBJS; o++) {
    if ((marked_mask & (1u << o)) != 0u) {
      unsigned int s = obj_sec[o];
      unsigned int l = obj_line[o];
      __CPROVER_assert((promoted_line_mask[s] & (1u << l)) == 0u,
                       "multi-hole Immix promotion never overlaps live object");
    }
  }
  return 0;
}
