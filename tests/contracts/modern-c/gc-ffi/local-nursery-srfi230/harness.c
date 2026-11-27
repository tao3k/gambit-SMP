/*
 * CBMC C23 Contract Harness for Phase A:
 * Processor-Local Independent Minor GC + SRFI-230 Promote-on-Share Protocol
 *
 * Verifies under bounded nondeterministic interleaving:
 *   1. No pointer in shared old generation S or atomicBox ever points into any nursery N_p.
 *   2. SRFI-230 acquire load always observes a fully promoted live object in S.
 *   3. Independent local minor GC on processor p reclaims dead N_p objects without
 *      touching sibling nursery N_q or invalidating any root or atomicBox reference.
 */
#include <stdint.h>
#include <stdbool.h>

extern unsigned int nondet_uint(void);

enum { LOC_UNALLOC = 0, LOC_N0 = 1, LOC_N1 = 2, LOC_SHARED = 3 };
enum { N_OBJS = 4 };

static unsigned int loc[N_OBJS];
static int edge[N_OBJS];   /* -1 = null, 0..N_OBJS-1 = target obj */
static int root[2];        /* per-processor root */
static int atomic_box;     /* SRFI-230 shared atomic box */
static int acquired[2];    /* last acquired object */
static bool major_req_start; /* vm->mem.major_request_start_ != 0 */
static bool local_escaped[2]; /* per-processor local_young_escaped_ */

static unsigned int nursery_of(unsigned int p) {
  return (p == 0u) ? LOC_N0 : LOC_N1;
}

static void promote_closure_from(unsigned int p, int start) {
  unsigned int nloc = nursery_of(p);
  int cur = start;
  for (unsigned int hop = 0u; hop < N_OBJS; hop++) {
    if (cur < 0 || cur >= N_OBJS) break;
    if (loc[cur] == nloc) {
      loc[cur] = LOC_SHARED;
      cur = edge[cur];
    } else {
      break;
    }
  }
}

static void check_invariants(void) {
  /* Invariant 1: atomic_box is either empty or strictly in SHARED */
  if (atomic_box >= 0) {
    __CPROVER_assert(loc[atomic_box] == LOC_SHARED, "atomic_box must be in SHARED");
  }
  /* Invariant 2: SHARED is closed (no shared -> nursery pointers) */
  for (int i = 0; i < N_OBJS; i++) {
    if (loc[i] == LOC_SHARED && edge[i] >= 0) {
      __CPROVER_assert(loc[edge[i]] == LOC_SHARED, "shared object cannot point into nursery");
    }
  }
  /* Invariant 3: No cross-nursery pointers and no dangling roots */
  for (unsigned int p = 0u; p < 2u; p++) {
    unsigned int other = nursery_of(1u - p);
    if (root[p] >= 0) {
      __CPROVER_assert(loc[root[p]] != LOC_UNALLOC, "root must not be dangling");
      __CPROVER_assert(loc[root[p]] != other, "root must not point to sibling nursery");
    }
    if (acquired[p] >= 0) {
      __CPROVER_assert(loc[acquired[p]] == LOC_SHARED, "SRFI-230 acquired object must live in SHARED");
    }
  }
  for (int i = 0; i < N_OBJS; i++) {
    if ((loc[i] == LOC_N0 || loc[i] == LOC_N1) && edge[i] >= 0) {
      unsigned int other = (loc[i] == LOC_N0) ? LOC_N1 : LOC_N0;
      __CPROVER_assert(loc[edge[i]] != other, "no cross-nursery object edge");
      __CPROVER_assert(loc[edge[i]] != LOC_UNALLOC, "no dangling nursery edge");
    }
  }
}

int main(void) {
  for (int i = 0; i < N_OBJS; i++) {
    loc[i] = LOC_UNALLOC;
    edge[i] = -1;
  }
  root[0] = -1;
  root[1] = -1;
  atomic_box = -1;
  acquired[0] = -1;
  acquired[1] = -1;
  major_req_start = false;
  local_escaped[0] = false;
  local_escaped[1] = false;

  for (unsigned int step = 0u; step < 6u; step++) {
    unsigned int op = nondet_uint() % 7u;
    unsigned int p = nondet_uint() & 1u;
    unsigned int idx = nondet_uint() % N_OBJS;

    if (op == 0u) {
      /* Local nursery allocation on processor p */
      if (loc[idx] == LOC_UNALLOC) {
        loc[idx] = nursery_of(p);
        edge[idx] = root[p];
        root[p] = (int)idx;
      }
    } else if (op == 1u) {
      /* SRFI-230 atomic-box-set! with promote-on-share barrier */
      if (root[p] >= 0) {
        promote_closure_from(p, root[p]);
        atomic_box = root[p];
        local_escaped[p] = true;
      }
    } else if (op == 2u) {
      /* SRFI-230 atomic-box-ref acquire load */
      if (atomic_box >= 0) {
        acquired[p] = atomic_box;
        root[p] = atomic_box;
      }
    } else if (op == 3u) {
      /* Independent local minor GC on processor p:
       * MUST yield if major_req_start is active or local_escaped[p] is set! */
      if (!major_req_start && !local_escaped[p]) {
        unsigned int nloc = nursery_of(p);
        if (root[p] >= 0) {
          promote_closure_from(p, root[p]);
        }
        for (int i = 0; i < N_OBJS; i++) {
          if (loc[i] == nloc) {
            loc[i] = LOC_UNALLOC;
            edge[i] = -1;
          }
        }
      }
    } else if (op == 4u) {
      /* Request concurrent major cycle start */
      major_req_start = true;
    } else if (op == 5u) {
      /* Global GC round unconditionally resets local_escaped[] and services major_req_start */
      major_req_start = false;
      local_escaped[0] = false;
      local_escaped[1] = false;
    } else {
      /* Drop local root to generate nursery garbage */
      root[p] = -1;
    }

    check_invariants();
  }
  return 0;
}
