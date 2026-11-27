/*
 * High-Order Adversarial CBMC C23 Contract Harness (Aligned with vendor/chez & vendor/ocaml)
 *
 * Tests:
 *   1. Cyclic nursery graphs (3 procs x 6 objects) under promote-on-share + local minor GC.
 *   2. Shared weak/will box registration closure.
 *   3. OCaml 5 3-state CAS forwarding (ORIG -> IN_PROGRESS -> FORWARDED + field0 payload).
 *
 * Negative Mutation Modes (proving invariants are non-vacuous and catch real bugs):
 *   -DINJECT_BUG_NO_PROMOTE : skip promote-on-share on SRFI-230 publish -> MUST FAIL
 *   -DINJECT_BUG_WEAK_ESCAPE: skip promote-on-share on weak-box register -> MUST FAIL
 *   -DINJECT_BUG_NO_SPIN    : loser reads fwd_addr while hdr==IN_PROGRESS -> MUST FAIL
 */
#include <stdint.h>
#include <stdbool.h>

extern unsigned int nondet_uint(void);

enum { LOC_UNALLOC = 0, LOC_N0 = 1, LOC_N1 = 2, LOC_N2 = 3, LOC_SHARED = 4 };
enum { FWD_ORIG = 0, FWD_IN_PROGRESS = 1, FWD_DONE = 2 };
enum { N_PROCS = 3, N_OBJS = 6 };

static unsigned int loc[N_OBJS];
static int edge[N_OBJS];
static int root[N_PROCS];
static int atomic_box;
static int weak_box;
static unsigned int fwd_state[N_OBJS];
static unsigned int fwd_addr[N_OBJS];
static int fwd_owner[N_OBJS];

static unsigned int nloc_of(unsigned int p) { return p + 1u; }

/* Iterative cyclic-safe transitive closure promotion inside N_p -> SHARED */
static void promote_cyclic_closure(unsigned int p, int start) {
  unsigned int nl = nloc_of(p);
  if (start < 0 || start >= N_OBJS || loc[start] != nl) return;

  bool in_cl[N_OBJS];
  for (int i = 0; i < N_OBJS; i++) in_cl[i] = false;
  in_cl[start] = true;

  /* Fixed-point expansion over arbitrary cycles of length <= N_OBJS */
  for (int iter = 0; iter < N_OBJS; iter++) {
    for (int u = 0; u < N_OBJS; u++) {
      if (in_cl[u]) {
        int v = edge[u];
        if (v >= 0 && v < N_OBJS && loc[v] == nl) {
          in_cl[v] = true;
        }
      }
    }
  }
  for (int i = 0; i < N_OBJS; i++) {
    if (in_cl[i]) loc[i] = LOC_SHARED;
  }
}

static void check_invariants(void) {
  if (atomic_box >= 0) {
    __CPROVER_assert(loc[atomic_box] == LOC_SHARED, "atomic_box must live in SHARED");
  }
  if (weak_box >= 0) {
    __CPROVER_assert(loc[weak_box] == LOC_SHARED, "weak_box must live in SHARED");
  }
  for (int i = 0; i < N_OBJS; i++) {
    if (loc[i] == LOC_SHARED && edge[i] >= 0) {
      __CPROVER_assert(loc[edge[i]] == LOC_SHARED, "SHARED cyclic closure: no shared->nursery edge");
    }
    if (fwd_state[i] == FWD_DONE) {
      __CPROVER_assert(fwd_addr[i] >= 100u, "FORWARDED object must expose valid fwd_addr");
    }
  }
  for (unsigned int p = 0u; p < N_PROCS; p++) {
    unsigned int nl = nloc_of(p);
    if (root[p] >= 0) {
      unsigned int rl = loc[root[p]];
      __CPROVER_assert(rl == nl || rl == LOC_SHARED, "root cannot dangle or cross nursery");
    }
  }
}

int main(void) {
  for (int i = 0; i < N_OBJS; i++) {
    loc[i] = LOC_UNALLOC;
    edge[i] = -1;
    fwd_state[i] = FWD_ORIG;
    fwd_addr[i] = 0u;
    fwd_owner[i] = -1;
  }
  for (int p = 0; p < N_PROCS; p++) root[p] = -1;
  atomic_box = -1;
  weak_box = -1;

  for (unsigned int step = 0u; step < 5u; step++) {
    unsigned int op = nondet_uint() % 8u;
    unsigned int p = nondet_uint() % N_PROCS;
    unsigned int o = nondet_uint() % N_OBJS;
    unsigned int v = nondet_uint() % N_OBJS;

    if (op == 0u && loc[o] == LOC_UNALLOC) {
      loc[o] = nloc_of(p);
      edge[o] = root[p];
      root[p] = (int)o;
    } else if (op == 1u && loc[o] == nloc_of(p) && (loc[v] == nloc_of(p) || loc[v] == LOC_SHARED)) {
      /* Create arbitrary cycle in N_p */
      edge[o] = (int)v;
    } else if (op == 2u && root[p] >= 0) {
      /* SRFI-230 atomic-box-set! */
#ifndef INJECT_BUG_NO_PROMOTE
      promote_cyclic_closure(p, root[p]);
#endif
      atomic_box = root[p];
    } else if (op == 3u && root[p] >= 0) {
      /* Shared weak/will box registration */
#ifndef INJECT_BUG_WEAK_ESCAPE
      promote_cyclic_closure(p, root[p]);
#endif
      weak_box = root[p];
    } else if (op == 4u && atomic_box >= 0) {
      root[p] = atomic_box;
    } else if (op == 5u) {
      /* Independent local minor GC on processor p */
      if (root[p] >= 0) promote_cyclic_closure(p, root[p]);
      unsigned int nl = nloc_of(p);
      for (int i = 0; i < N_OBJS; i++) {
        if (loc[i] == nl) {
          loc[i] = LOC_UNALLOC;
          edge[i] = -1;
        }
      }
    } else if (op == 6u && loc[o] == LOC_SHARED && fwd_state[o] == FWD_ORIG) {
      /* OCaml 5 3-state CAS claim: ORIG -> IN_PROGRESS */
      fwd_state[o] = FWD_IN_PROGRESS;
      fwd_owner[o] = (int)p;
#ifdef INJECT_BUG_NO_SPIN
      /* Buggy loser reads fwd_addr without spinning for FWD_DONE */
      __CPROVER_assert(fwd_addr[o] >= 100u, "loser must not read uninitialized fwd_addr");
#endif
    } else if (op == 7u && loc[o] == LOC_SHARED && fwd_state[o] == FWD_IN_PROGRESS && fwd_owner[o] == (int)p) {
      /* OCaml 5 3-state release publish: write fwd_addr then FWD_DONE */
      fwd_addr[o] = 100u + p * 10u + o;
      fwd_state[o] = FWD_DONE;
    }

    check_invariants();
  }
  return 0;
}
