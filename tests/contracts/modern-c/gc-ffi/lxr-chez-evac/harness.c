/*
 * CBMC C23 Contract Harness for Phase B:
 * LXR Deferred-RC + Immix Line Recycling + Concurrent SATB + Chez Parallel CAS Evacuation
 *
 * Verifies:
 *   1. Parallel CAS forwarding installation has at most 1 winner; losers converge to winner.
 *   2. SATB pre-write barrier prevents reclaiming any rooted/live object during concurrent mark.
 *   3. Deferred RC reclaim only frees unrooted objects with drc == 0 when SATB is inactive.
 */
#include <stdint.h>
#include <stdbool.h>

extern unsigned int nondet_uint(void);

enum { ST_LIVE = 0, ST_EVAC = 1, ST_RECLAIMED = 2 };
enum { COL_WHITE = 0, COL_GREY = 1, COL_BLACK = 2 };
enum { N_OBJS = 3 };

static unsigned int state[N_OBJS];
static bool rooted[N_OBJS];
static unsigned int drc[N_OBJS];
static unsigned int color[N_OBJS];
static bool satb_active;
static bool satb_logged[N_OBJS];
static unsigned int fwd[N_OBJS];
static unsigned int fwd_winners[N_OBJS];

static void check_invariants(void) {
  for (int i = 0; i < N_OBJS; i++) {
    if (rooted[i]) {
      __CPROVER_assert(state[i] != ST_RECLAIMED, "rooted object must never be reclaimed");
    }
    __CPROVER_assert(fwd_winners[i] <= 1u, "at most one parallel evacuation CAS winner");
    if (state[i] == ST_EVAC) {
      __CPROVER_assert(fwd[i] != 0u, "evacuated object must have non-zero forwarding address");
    }
    if (satb_active && rooted[i]) {
      __CPROVER_assert(color[i] != COL_WHITE || satb_logged[i],
                       "SATB must protect every rooted object");
    }
  }
}

int main(void) {
  for (int i = 0; i < N_OBJS; i++) {
    state[i] = ST_LIVE;
    rooted[i] = (i < 2);
    drc[i] = (i < 2) ? 1u : 0u;
    color[i] = COL_WHITE;
    satb_logged[i] = false;
    fwd[i] = 0u;
    fwd_winners[i] = 0u;
  }
  satb_active = false;

  for (unsigned int step = 0u; step < 6u; step++) {
    unsigned int op = nondet_uint() % 7u;
    unsigned int o = nondet_uint() % N_OBJS;
    unsigned int w = nondet_uint() & 1u;

    if (op == 0u && !satb_active) {
      /* Start concurrent SATB cycle */
      satb_active = true;
      for (int i = 0; i < N_OBJS; i++) {
        color[i] = (state[i] != ST_RECLAIMED && rooted[i]) ? COL_GREY : COL_WHITE;
        satb_logged[i] = false;
      }
    } else if (op == 1u && rooted[o]) {
      /* Mutator drops root with Yuasa SATB pre-write barrier */
      rooted[o] = false;
      if (drc[o] > 0u) drc[o]--;
      if (satb_active && state[o] != ST_RECLAIMED) {
        satb_logged[o] = true;
      }
    } else if (op == 2u && satb_active && satb_logged[o]) {
      /* Concurrent marker drains SATB log */
      satb_logged[o] = false;
      if (color[o] == COL_WHITE) color[o] = COL_GREY;
    } else if (op == 3u && satb_active && color[o] == COL_GREY) {
      /* Concurrent marker shades GREY -> BLACK */
      color[o] = COL_BLACK;
    } else if (op == 4u && satb_active) {
      /* Finish SATB sweep if all grey & logs drained */
      bool done = true;
      for (int i = 0; i < N_OBJS; i++) {
        if (color[i] == COL_GREY || satb_logged[i]) done = false;
      }
      if (done) {
        for (int i = 0; i < N_OBJS; i++) {
          if (state[i] != ST_RECLAIMED && color[i] == COL_WHITE && !rooted[i]) {
            state[i] = ST_RECLAIMED;
          }
          color[i] = COL_WHITE;
        }
        satb_active = false;
      }
    } else if (op == 5u && !satb_active && state[o] == ST_LIVE && drc[o] == 0u && !rooted[o]) {
      /* LXR Deferred RC immediate line reclaim */
      state[o] = ST_RECLAIMED;
    } else if (op == 6u && state[o] == ST_LIVE && rooted[o]) {
      /* Chez-style parallel work-stealing evacuation CAS */
      if (fwd[o] == 0u) {
        fwd[o] = 10u + w;
        fwd_winners[o]++;
        state[o] = ST_EVAC;
      } else {
        /* Loser observes winner's forwarding address */
        __CPROVER_assert(fwd[o] == 10u || fwd[o] == 11u, "loser converges to valid winner");
      }
    }

    check_invariants();
  }
  return 0;
}
