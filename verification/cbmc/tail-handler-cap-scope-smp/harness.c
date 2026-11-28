/*
 * CBMC PSO Concurrency Harness:
 * Zero-Capture Tail-Resumptive with-handler Continuable-Exception Parity,
 * Lexical Tail-Capability Scope Safety, and Raw call/1cc LCA Restore Coherency.
 *
 * Compact scalar-only globals (zero pointers across async threads) so
 * `cbmc --mm pso` verifies exhaustively in seconds.
 *
 * Clean build must pass with VERIFICATION SUCCESSFUL (0 failed).
 * All 4 negative mutants must fail with VERIFICATION FAILED:
 *   -DMUTANT_TAIL_HANDLER_USES_CATCHER
 *   -DMUTANT_ESCAPED_TAIL_CAP_ALLOWED
 *   -DMUTANT_TAIL_CAP_STUCK_DEAD_ON_RESTORE
 *   -DMUTANT_RAW_1CC_MISSING_RESTORE
 */

#include <assert.h>
#include <stdbool.h>

extern bool nondet_bool(void);

/* Per-thread simulated tail-handler stack depth (isolated across T1 and T2) */
static volatile int g_t1_handlers = 0;
static volatile int g_t2_handlers = 0;

/* Shared atomic flag for concurrent T2 thread check */
static volatile int g_t2_done = 0;
static volatile int g_t2_ok = 0;

static void fence_release(void) {
    __CPROVER_fence("WWfence", "RWfence", "WWcumul", "RWcumul");
}

static void fence_acquire(void) {
    __CPROVER_fence("RRfence", "RWfence", "RRcumul", "RWcumul");
}

/* Thread 2 independently runs a tail-resumptive with-handler with continuable exception */
static void peer_thread(void) {
    g_t2_handlers = 1;
    /* Continuable raise: pop frame during outer eh, restore on return */
    int saved = g_t2_handlers;
    g_t2_handlers = 0;
    /* Outer eh returns 100 -> restore saved */
    g_t2_handlers = saved;
    assert(g_t2_handlers == 1);
    /* Normal exit pops frame */
    g_t2_handlers = 0;
    g_t2_ok = 1;
    fence_release();
    g_t2_done = 1;
}

int main(void) {
    bool continuable = nondet_bool();
    bool do_multishot_restore = nondet_bool();

    __CPROVER_ASYNC_1: peer_thread();

    /* Part A: Tail-resumptive with-handler continuable vs escaping exception */
    g_t1_handlers = 1;
    int body_result = 0;
    if (continuable) {
#ifdef MUTANT_TAIL_HANDLER_USES_CATCHER
        /* Bug: with-exception-catcher unwinds stack and destroys continuation! */
        g_t1_handlers = 0;
        body_result = 142; /* lost (+ 1 ...) and handler */
#else
        /* macro-dynamic-bind: pop frame during outer eh, restore on return */
        int saved = g_t1_handlers;
        g_t1_handlers = 0;
        assert(g_t1_handlers == 0);
        g_t1_handlers = saved;
        assert(g_t1_handlers == 1);
        /* Remaining body runs with handler still active! */
        body_result = 143;
        g_t1_handlers = 0;
#endif
        assert(body_result == 143);
        assert(g_t1_handlers == 0);
    } else {
        /* Escaping exception pops frame cleanly */
        g_t1_handlers = 0;
        assert(g_t1_handlers == 0);
    }

    /* Part B: Lexical tail-capability live-box across exit, 'suspend, 'restore */
    int cap_live = 1;
    /* Outer perform ('suspend) deactivates cap outside lexical scope */
#ifdef MUTANT_ESCAPED_TAIL_CAP_ALLOWED
    /* Bug: cap remains live after suspend / exit! */
#else
    cap_live = 0;
#endif
    assert(cap_live == 0);

    if (do_multishot_restore) {
        /* Multi-shot resume ('restore) re-activates cap! */
#ifndef MUTANT_TAIL_CAP_STUCK_DEAD_ON_RESTORE
        cap_live = 1;
#endif
        assert(cap_live == 1);
        /* Exit deactivates cap again */
#ifndef MUTANT_ESCAPED_TAIL_CAP_ALLOWED
        cap_live = 0;
#endif
        assert(cap_live == 0);
    }

    /* Part C: Raw call/1cc divergent jump (branch A [f1, f0] -> branch B [f2, f0]) */
    int f0_active = 1; /* shared LCA */
    int f1_active = 1; /* dropped */
    int f2_active = 0; /* reentered */

    /* Unwind dropped [f1] */
    f1_active = 0;
    /* Restore reentered [f2] */
#ifndef MUTANT_RAW_1CC_MISSING_RESTORE
    f2_active = 1;
#endif
    assert(f0_active == 1);
    assert(f1_active == 0);
    assert(f2_active == 1);

    if (g_t2_done == 1) {
        fence_acquire();
        assert(g_t2_ok == 1);
        assert(g_t2_handlers == 0);
    }

    return 0;
}
