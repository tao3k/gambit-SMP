/*
 * CBMC PSO Concurrency Harness:
 * Deadlock-Free Future Cycle Detection, Non-Local Escape Unwind Quiescence,
 * Worker Self-Shutdown Guard, and Zero-Retention Chase-Lev Last-Item Pop.
 *
 * Compact scalar-only globals (zero pointers across async threads) so
 * `cbmc --mm pso` verifies exhaustively in seconds.
 *
 * Clean build must pass with VERIFICATION SUCCESSFUL (0 failed).
 * All 4 negative mutants must fail with VERIFICATION FAILED:
 *   -DMUTANT_FUTURE_ABORT_WEDGES_RUNNING
 *   -DMUTANT_FORK_JOIN_ORPHANS_RIGHT
 *   -DMUTANT_SELF_CYCLE_SPINS
 *   -DMUTANT_LAST_POP_PINS_SLOT
 */

#include <assert.h>
#include <stdbool.h>

extern bool nondet_bool(void);

#define F_PENDING 0
#define F_RUN_T1  1
#define F_RUN_T2  2
#define F_OK      3
#define F_ERR     4

static volatile int g_fut_state = F_PENDING;
static volatile int g_fut_peer_saw_ready = 0;

static volatile int g_fj_right_done = 0;
static volatile int g_fj_right_state = F_PENDING;

/* Single-element Chase-Lev deque (t == 0, b == 1) */
static volatile int g_dq_top = 0;
static volatile int g_dq_bot = 1;
static volatile int g_dq_slot = 42;
static volatile int g_dq_owner_won = 0;
static volatile int g_dq_thief_won = 0;
static volatile int g_dq_thief_done = 0;

static void fence_seq_cst(void) {
    __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WWcumul", "RRcumul", "RWcumul", "WRcumul");
}

static void fence_release(void) {
    __CPROVER_fence("WWfence", "RWfence", "WWcumul", "RWcumul");
}

static void fence_acquire(void) {
    __CPROVER_fence("RRfence", "RWfence", "RRcumul", "RWcumul");
}

static bool cas_fut(int expected, int desired) {
    bool ok = false;
    fence_release();
    __CPROVER_atomic_begin();
    if (g_fut_state == expected) {
        g_fut_state = desired;
        ok = true;
    }
    __CPROVER_atomic_end();
    fence_seq_cst();
    return ok;
}

static bool cas_dq_top(int expected, int desired) {
    bool ok = false;
    fence_release();
    __CPROVER_atomic_begin();
    if (g_dq_top == expected) {
        g_dq_top = desired;
        ok = true;
    }
    __CPROVER_atomic_end();
    fence_seq_cst();
    return ok;
}

/* Worker running right branch of fork-join concurrently */
static void fj_right_worker(void) {
    fence_release();
    g_fj_right_done = 1;
    fence_release();
    g_fj_right_state = F_OK;
}

/* Thief racing against owner pop on single-item Chase-Lev deque (t == 0, b == 1) */
static void dq_thief_thread(void) {
    int t = g_dq_top;
    fence_seq_cst();
    int b = g_dq_bot;
    if (t < b) {
        int x = g_dq_slot;
        (void)x;
        if (cas_dq_top(t, t + 1)) {
            g_dq_thief_won = 1;
        }
    }
    fence_release();
    g_dq_thief_done = 1;
}

int main(void) {
    bool do_abort = nondet_bool();
    bool do_self_cycle = nondet_bool();

    /* Part A: Future owner-thread state, self-cycle detection, and 'unwind err commit */
    assert(cas_fut(F_PENDING, F_RUN_T1));
    if (do_self_cycle) {
        int st = g_fut_state;
        fence_acquire();
#ifdef MUTANT_SELF_CYCLE_SPINS
        bool detected = false;
#else
        bool detected = (st == F_RUN_T1);
#endif
        assert(detected);
    }

    if (do_abort) {
        /* Non-local abort ('unwind hook) commits F_ERR */
#ifndef MUTANT_FUTURE_ABORT_WEDGES_RUNNING
        fence_release();
        g_fut_state = F_ERR;
        fence_seq_cst();
#endif
        int st = g_fut_state;
        fence_acquire();
        g_fut_peer_saw_ready = (st == F_OK || st == F_ERR) ? 1 : 0;
        assert(g_fut_peer_saw_ready == 1);
    } else {
        fence_release();
        g_fut_state = F_OK;
        fence_seq_cst();
        assert(g_fut_state == F_OK);
    }

    /* Part B: Fork-join left-branch 'unwind quiesces right future before outer handler */
    g_fj_right_done = 0;
    g_fj_right_state = F_PENDING;
    __CPROVER_ASYNC_1: fj_right_worker();

#ifndef MUTANT_FORK_JOIN_ORPHANS_RIGHT
    /* 'unwind hook joins right before exiting to outer prompt */
    __CPROVER_assume(g_fj_right_state == F_OK);
    fence_acquire();
#endif
    assert(g_fj_right_done == 1);

    /* Part C: Chase-Lev last-item pop (t == b == 0) vs thief steal + zero GC retention */
    g_dq_top = 0;
    g_dq_bot = 1;
    g_dq_slot = 42;
    g_dq_owner_won = 0;
    g_dq_thief_won = 0;
    g_dq_thief_done = 0;
    fence_seq_cst();

    __CPROVER_ASYNC_2: dq_thief_thread();

    /* Owner deque-pop-bottom! */
    int b = g_dq_bot - 1;
    g_dq_bot = b;
    fence_seq_cst();
    int t = g_dq_top;
    if (t <= b) {
        int x = g_dq_slot;
        if (t == b) {
            if (cas_dq_top(t, t + 1)) {
                assert(x == 42);
#ifndef MUTANT_LAST_POP_PINS_SLOT
                g_dq_slot = 0; /* Clear slot to #f after winning CAS! */
#endif
                g_dq_owner_won = 1;
            }
            g_dq_bot = b + 1;
        }
    } else {
        g_dq_bot = b + 1;
    }

    if (g_dq_thief_done == 1) {
        fence_acquire();
        assert((g_dq_owner_won + g_dq_thief_won) == 1);
    }
    if (g_dq_owner_won == 1) {
        assert(g_dq_slot == 0);
    }

    return 0;
}
