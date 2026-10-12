# Retained-Tree Convergence And Resource Retirement

## Pre-Implementation Review

1. The path follows candidate027's actual two tree rounds, rather than adding
   a new barrier. The prior GC/resize model left the implementation of retained
   next-round admission open.
2. Existing models already reject cleanup at receiver exit and joins alone.
   This refinement checks how the next outer upward tree can establish that
   admission; it does not repeat a native failure or replace the GC model.
3. The benefit is a concrete candidate reclamation boundary for the lifetime
   repair. It does not demonstrate a runtime speedup.
4. Cost and risk remain: a pending-retirement representation, initialization
   ownership, failed joins, round identity and C publication must be handled.
   None is licensed by paper conformance or finite-state success alone.

## Source Refinement

Source is candidate027 `lib/setup.c`, bound by the manifest's SHA-256.

| Source | Model Transition / Obligation |
| --- | --- |
| `SYNC_SEND_MSG:526-535` | Separate old publish, mutex unlock and condition signal. A receiver may observe publication before the latter two return. |
| `barrier_sync_op:568-570,696-708` | Snapshot old population; send to the first old child completely before the second. |
| `___vm_resize_pstate:930-940` | Retired worker leaves its inner barrier, performs cleanup and exits; that does not imply its incoming sender returned. |
| `___vm_resize_pstate:976-988` | Root joins retired workers after its own inner barrier; a retained non-root sender can still be finishing its downward send. Successful join is a premise, not the ignored-error implementation's guarantee. |
| `execute_sync_op_loop:1075-1119` | Retained processors return from the resize operation before entering the next outer barrier. Root does so after the joins. |
| `barrier_sync_op:582-650,666-679` | Each retained node receives its retained children's upward aggregates before publishing its own aggregate. Root convergence thus covers descendants, not just direct children. |

The proposed boundary is the root's **next outer upward convergence**, after
its child receives and before the downward broadcast. It is not the root's
return from the inner count-setting barrier, and not any GC work-closure event.
The model derives `closure` from this tree: convergence implies every retained
processor returned from its old downward sends. Together with successful joins,
all old sends targeting retired synchronization resources have finished.

This is a source-audited sufficient boundary for a single successful shrink,
not an implemented hook. The runtime needs an explicit pending-retirement
identity tied to the shrink and initialized resources. A generic call on every
barrier is not justified. Root must distinguish the next outer round from the
inner count-setting round, including intervening operations and nested GC.

## Model And Evidence Boundary

`sync_retirement_round_closure.qnt` explores populations 2..5 and every legal
retained prefix. Node numbers and parent/child order are the source algorithm,
not a symmetry claim. Its negative control reclaims after joins alone; the
positive policy uses the concrete aggregated upward events. `safe` checks both
the derived closure and completed accesses to retired resources. Progress uses
weak fairness in a finite, one-shrink transition system.

It omits repeated shrink/grow, failed joins, failed setup, C weak memory,
signals, VM callbacks and full GC. Those are required composition/engineering
gates, not reasons to silently treat a failed operation as joined or retired.
No runtime cleanup implementation, native GC result, bootstrap completion or
Gerbil full-suite acceptance is provided by this model.

Campaign001 was rejected due to an invalid map lookup: a disjunction evaluated
the preceding-sibling lookup for the first child. This was a model expression
error, not a protocol counterexample. Campaign002 uses an explicit conditional
and additionally checks the closure implication inside `safe`; the failed log
is retained. Campaign002 passed with stable context: the negative control has
a 16-state counterexample (20.759 seconds); positive safety and weak-fair
progress cover 4,695 distinct states, 14,872 generated, zero queued in 24.830
seconds. Ten initial configurations cover the stated population/prefix bounds.
The portable source-bound bundle is
`evidence/model-results/sync-retirement-round-closure/`. This local evidence
publication does not mean a GitHub push or native execution admission.

## Paper Connection

GHC section 3.5 and HotSpot section 3.3 require closing the participating
work-producing population before declaring termination. Neither proves that a
later notification call has returned. Here, that participant-completion concept
guides the audit, but Gambit's exact tree and call-return order determine the
candidate boundary. No paper-specific queue, bit-width or thread count is copied
into the runtime.

## Native Admission Still Required

Exercise shrink with a retained non-root sender and a fast retired receiver,
delaying the sender between publication/unlock/signal. Verify resource ownership
through repeated shrink/grow and teardown, preserve join failures, and bind the
revised source and newly built binary. Only then proceed to all-three-flags GC,
bootstrap and complete Gerbil tests under GNU GCC. Do not rerun an unchanged
denied candidate or use this model receipt as execution permission.
