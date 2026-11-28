/*
 * CBMC PSO Concurrency Harness:
 * Structured-Concurrency Nursery & with-finally 3-Phase Unwind-Hook Coherency
 * Across Non-Local Escapes, Plus Post-Close rx-fast ABA Guard.
 *
 * Compact scalar-only globals (zero pointers across async threads) so
 * `cbmc --mm pso` verifies exhaustively in seconds.
 *
 * Clean build must pass with VERIFICATION SUCCESSFUL (0 failed).
 * All 4 negative mutants must fail with VERIFICATION FAILED:
 *   -DMUTANT_NURSERY_ESCAPE_NO_JOIN
 *   -DMUTANT_FINALLY_SKIP_ABORT
 *   -DMUTANT_FINALLY_FIRE_ON_SUSPEND
 *   -DMUTANT_RXFAST_POST_CLOSE_ABA
 */

#include <assert.h>
#include <stdbool.h>

extern bool nondet_bool(void);

#define N_LIVE      0
#define N_CANCELLED 1
#define N_CLOSED    2

static volatile int g_n_state = N_LIVE;
static volatile int g_n_active = 0;
static volatile int g_child_done = 0;
static volatile int g_child_saw_cancel = 0;

static volatile int g_finally_done = 0;
static volatile int g_finally_runs = 0;

/* Channel tail (bit 0 = closed) and rx-fast slot (0 = empty, 1 = parked) */
static volatile int g_ch_closed = 0;
static volatile int g_ch_rxf = 0;
static volatile int g_post_close_delivery = 0;

static void fence_seq_cst(void) {
    __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WWcumul", "RRcumul", "RWcumul", "WRcumul");
}

static void fence_release(void) {
    __CPROVER_fence("WWfence", "RWfence", "WWcumul", "RWcumul");
}

static void fence_acquire(void) {
    __CPROVER_fence("RRfence", "RWfence", "RRcumul", "RWcumul");
}

static int atomic_sub_active(int delta) {
    int prev;
    fence_release();
    __CPROVER_atomic_begin();
    prev = g_n_active;
    g_n_active = prev - delta;
    __CPROVER_atomic_end();
    fence_seq_cst();
    return prev;
}

static bool cas_n_state(int expected, int desired) {
    bool ok = false;
    __CPROVER_atomic_begin();
    if (g_n_state == expected) {
        g_n_state = desired;
        ok = true;
    }
    __CPROVER_atomic_end();
    fence_seq_cst();
    return ok;
}

static void finally_run_once(void) {
    if (!g_finally_done) {
        g_finally_done = 1;
        g_finally_runs++;
    }
}

/* Peer worker runs nursery child fiber concurrently */
static void child_worker_thread(void) {
    int st = g_n_state;
    fence_acquire();
    g_child_saw_cancel = (st != N_LIVE) ? 1 : 0;
    fence_release();
    g_child_done = 1;
    atomic_sub_active(1);
}

/* Concurrent channel receiver attempting rx-fast park after close */
static void post_close_receiver_thread(void) {
#ifdef MUTANT_RXFAST_POST_CLOSE_ABA
    /* Bug: speculatively CAS rx-fast without pre-checking closed bit */
    __CPROVER_atomic_begin();
    if (g_ch_rxf == 0) {
        g_ch_rxf = 1;
    }
    __CPROVER_atomic_end();
#else
    int c = g_ch_closed;
    fence_acquire();
    if (c == 0) {
        __CPROVER_atomic_begin();
        if (g_ch_closed == 0 && g_ch_rxf == 0) {
            g_ch_rxf = 1;
        }
        __CPROVER_atomic_end();
    }
#endif
}

int main(void) {
    bool do_effect_suspend = nondet_bool();
    bool do_nonlocal_abort = nondet_bool();

    /* Part A: with-nursery + with-finally 3-phase unwind verification */
    g_n_state = N_LIVE;
    g_n_active = 2; /* parent (1) + child (1) */
    g_child_done = 0;
    g_finally_done = 0;
    g_finally_runs = 0;

    __CPROVER_ASYNC_1: child_worker_thread();

    if (do_effect_suspend) {
        /* Outer algebraic effect perform ('suspend phase):
           MUST NOT run finally-thunk or close nursery */
#ifdef MUTANT_FINALLY_FIRE_ON_SUSPEND
        finally_run_once();
#endif
        assert(g_finally_runs == 0);
        assert(g_n_state == N_LIVE);
        /* Outer handler resumes ('restore phase) */
    }

    if (do_nonlocal_abort) {
        /* abort-current-continuation / call/1cc ('unwind phase) */
#ifndef MUTANT_FINALLY_SKIP_ABORT
        finally_run_once();
#endif
#ifndef MUTANT_NURSERY_ESCAPE_NO_JOIN
        cas_n_state(N_LIVE, N_CANCELLED);
        atomic_sub_active(1);
        /* Park until active == 0 (join child before returning to outer prompt!) */
        __CPROVER_assume(g_n_active == 0);
        fence_acquire();
        g_n_state = N_CLOSED;
        fence_seq_cst();
#endif
        /* Structured concurrency post-conditions before outer prompt handler runs: */
        assert(g_finally_runs == 1);
        assert(g_n_state == N_CLOSED);
        assert(g_n_active == 0);
        assert(g_child_done == 1);
    } else {
        /* Normal exit */
        finally_run_once();
        atomic_sub_active(1);
        __CPROVER_assume(g_n_active == 0);
        fence_acquire();
        g_n_state = N_CLOSED;
        assert(g_finally_runs == 1);
        assert(g_n_state == N_CLOSED);
        assert(g_child_done == 1);
    }

    /* Part B: Post-close rx-fast ABA guard verification */
    g_ch_closed = 1;
    g_ch_rxf = 0;
    fence_seq_cst();

    __CPROVER_ASYNC_2: post_close_receiver_thread();

    /* Stalled sender tries fast-path A1 direct handoff on rx-fast after close returned */
    bool handed_off = false;
    __CPROVER_atomic_begin();
    if (g_ch_rxf == 1) {
        g_ch_rxf = 0;
        handed_off = true;
    }
    __CPROVER_atomic_end();
    if (handed_off) {
        g_post_close_delivery = 1;
    }
    assert(g_post_close_delivery == 0);

    return 0;
}
