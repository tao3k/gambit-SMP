/*
 * CBMC PSO Concurrency Harness:
 * Generator Slow-Path Unwind-Hook Coherency, Multi-Value Yield (0/1/N),
 * and Winding-Transition Guard Soundness under SMP.
 *
 * Compact scalar-only globals (zero pointers across async threads) using
 * CBMC-native atomic blocks and PSO memory fences so `cbmc --mm pso` verifies
 * exhaustively in seconds.
 *
 * Clean build must pass with VERIFICATION SUCCESSFUL (0 failed).
 * All 4 negative mutants must fail with VERIFICATION FAILED:
 *   -DMUTANT_DROP_SLOWPATH_UNWIND_HOOK
 *   -DMUTANT_MULTIVAL_ARITY_WEDGE
 *   -DMUTANT_STALE_GUARD_ON_UNTRAMPED_THROW
 *   -DMUTANT_NO_GUARD_ON_BEFORE_THROW
 */

#include <assert.h>
#include <stdbool.h>

extern int nondet_int(void);
extern bool nondet_bool(void);

#define GEN_INIT      0
#define GEN_RUNNING   1
#define GEN_SUSPENDED 2
#define GEN_DONE      3

#define SK_NONE 0
#define SK_RAW  1
#define SK_EC   2

static volatile int g_state = GEN_INIT;
static volatile int g_sub_k = SK_NONE;
static volatile int g_yield_arity = -1;
static volatile int g_active_runners = 0;

static volatile int g_pframe_hook = 0;
static volatile int g_mc_guard_present = 0;
static volatile int g_fault_eh_routed = 1;
static volatile int g_t1_entered = 0;
static volatile int g_t2_entered = 0;
static volatile int g_t2_done = 0;

static void fence_seq_cst(void) {
    __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WWcumul", "RRcumul", "RWcumul", "WRcumul");
}

static void fence_release(void) {
    __CPROVER_fence("WWfence", "RWfence", "WWcumul", "RWcumul");
}

static void fence_acquire(void) {
    __CPROVER_fence("RRfence", "RWfence", "RRcumul", "RWcumul");
}

static bool cas_state_seq(int expected, int desired) {
    bool ok = false;
    __CPROVER_atomic_begin();
    if (g_state == expected) {
        g_state = desired;
        ok = true;
    }
    __CPROVER_atomic_end();
    fence_seq_cst();
    return ok;
}

static void store_state_rel(int v) {
    fence_release();
    g_state = v;
}

static int load_state_acq(void) {
    int v = g_state;
    fence_acquire();
    return v;
}

static int fetch_add_runners(int delta) {
    int prev;
    __CPROVER_atomic_begin();
    prev = g_active_runners;
    g_active_runners = prev + delta;
    __CPROVER_atomic_end();
    return prev;
}

/* Thread 2 races concurrently against Thread 1 on the same generator */
static void racer_thread(void) {
    if (cas_state_seq(GEN_SUSPENDED, GEN_RUNNING)) {
        int r = fetch_add_runners(1);
        assert(r == 0);
        int sk = g_sub_k;
        assert(sk == SK_RAW || sk == SK_EC);
        g_sub_k = SK_NONE;
        g_t2_entered = 1;

        /* Slow-path resume installs unwind hook on replayed prompt frame */
#ifdef MUTANT_DROP_SLOWPATH_UNWIND_HOOK
        int hook = (sk == SK_EC) ? 0 : 1;
#else
        int hook = 1;
#endif
        g_pframe_hook = hook;

        /* Simulate body exception / outer prompt abort */
        fetch_add_runners(-1);
        if (g_pframe_hook == 1) {
            g_pframe_hook = 0;
            store_state_rel(GEN_DONE);
        }
        /* Post-fault invariant: generator MUST be DONE, never wedged RUNNING */
        assert(load_state_acq() == GEN_DONE);
    }
    fence_release();
    g_t2_done = 1;
}

int main(void) {
    int arity = nondet_int();
    if (arity < 0 || arity > 2) {
        return 0;
    }
    bool slow_yield = nondet_bool();
    bool winding = nondet_bool();
    bool caller_trampolined = nondet_bool();
    bool fault_during_winding = nondet_bool();

    /* Step 1: Thread 1 starts generator INIT -> RUNNING */
    bool started = cas_state_seq(GEN_INIT, GEN_RUNNING);
    assert(started);
    fetch_add_runners(1);

    /* Step 2: Yield (either fast 1-arg or slow/multi-value 0/1/2-arg) */
    fetch_add_runners(-1);
    if (slow_yield || arity != 1) {
#ifdef MUTANT_MULTIVAL_ARITY_WEDGE
        if (arity != 1) {
            /* Bug: post-pop arity error leaves generator wedged in RUNNING */
            assert(load_state_acq() == GEN_SUSPENDED);
            return 0;
        }
#endif
        g_yield_arity = arity;
        g_sub_k = SK_EC;
        store_state_rel(GEN_SUSPENDED);
    } else {
        g_yield_arity = 1;
        g_sub_k = SK_RAW;
        store_state_rel(GEN_SUSPENDED);
    }

    /* Step 3: Spawn Thread 2 to race on resuming the suspended generator */
    __CPROVER_ASYNC_1: racer_thread();

    /* Thread 1 also tries to resume the generator */
    if (cas_state_seq(GEN_SUSPENDED, GEN_RUNNING)) {
        int r = fetch_add_runners(1);
        assert(r == 0);
        int sk = g_sub_k;
        assert(sk == SK_RAW || sk == SK_EC);
        g_sub_k = SK_NONE;
        g_t1_entered = 1;

        if (winding) {
#ifdef MUTANT_STALE_GUARD_ON_UNTRAMPED_THROW
            int push_guard = 1; /* Bug: pushes guard even when caller after-thunk is untramped */
#elif defined(MUTANT_NO_GUARD_ON_BEFORE_THROW)
            int push_guard = 0; /* Bug: skips guard even when caller_trampolined == true */
#else
            int push_guard = caller_trampolined ? 1 : 0;
#endif
            g_mc_guard_present = push_guard;

            if (fault_during_winding) {
                fetch_add_runners(-1);
                if (caller_trampolined) {
                    /* Generator before-thunk or trampolined caller after-thunk faults */
                    if (g_mc_guard_present == 1) {
                        g_mc_guard_present = 0;
                        store_state_rel(GEN_DONE);
                        g_fault_eh_routed = 1;
                    } else {
                        g_fault_eh_routed = 0;
                    }
                    assert(load_state_acq() == GEN_DONE);
                    assert(g_fault_eh_routed == 1);
                    assert(g_mc_guard_present == 0);
                } else {
                    /* Untramped caller after-thunk throws directly to bare catcher:
                       MUST NOT leave any stale guard frame on st.mc! */
                    assert(g_mc_guard_present == 0);
                }
            } else {
                /* Landing thunk strips guard and installs prompt frame with unwind hook */
                g_mc_guard_present = 0;
#ifdef MUTANT_DROP_SLOWPATH_UNWIND_HOOK
                int hook = (sk == SK_EC) ? 0 : 1;
#else
                int hook = 1;
#endif
                g_pframe_hook = hook;
                fetch_add_runners(-1);
                if (g_pframe_hook == 1) {
                    g_pframe_hook = 0;
                    store_state_rel(GEN_DONE);
                }
                assert(load_state_acq() == GEN_DONE);
                assert(g_mc_guard_present == 0);
            }
        } else {
#ifdef MUTANT_DROP_SLOWPATH_UNWIND_HOOK
            int hook = (sk == SK_EC) ? 0 : 1;
#else
            int hook = 1;
#endif
            g_pframe_hook = hook;
            fetch_add_runners(-1);
            if (g_pframe_hook == 1) {
                g_pframe_hook = 0;
                store_state_rel(GEN_DONE);
            }
            assert(load_state_acq() == GEN_DONE);
        }
    }

    /* Mutual exclusion: at most one thread ever won the SUSPENDED -> RUNNING CAS */
    if (g_t2_done == 1) {
        fence_acquire();
        int c1 = g_t1_entered;
        int c2 = g_t2_entered;
        assert((c1 + c2) == 1);
    }

    return 0;
}
