# Scheduler Lock Moving Roots

## Source Facts

Authority is the pinned submodule plus
`evidence/fixtures/scheduler-retry-sync-participation/source.lock.json`, not a
runtime cache. The current candidate has no new runtime edit in this campaign.

`lib/_thread.scm:##lock-scheduler-object-with-sync-participation!` polls only
the sync flag after a failed trylock. Its generated return frame stores the
object argument and return address before calling `##sync-op-interrupt!`,
then reloads them from the stack before the next trylock. The generated
return descriptor is `___IFD(___RETN,5,0,0x3L)` for the inspected producer.
This observation is not a complete derivation of the frame scanner semantics.

`lib/_kernel.scm:##sync-op-interrupt!` saves the return address, publishes
cached state with `___W_ALL`, calls `service_sync_op`, reloads with `___R_ALL`
and restores the return address. Existing `ffi_gc_frame_protocol.qnt` covers
that abstract frame-publication envelope; it is context, not an imported proof
in the new model.

`lib/setup.c:execute_sync_op_loop` can accumulate a processor error and call
`___throw_error` on P0 when setup is not complete. Therefore normal return from
every serviced collective is not established. `___throw_error` invokes
`___THROW`; it is not a local scheduler-lock rollback. Correct VM termination,
remaining cohort participation and held-lock cleanup require separate evidence.
No speculative runtime exception repair is made here.

## Model Boundary

`scheduler_lock_moving_root.qnt` distinguishes publishing the lock argument,
GC relocation of owner and waiter roots, reloading the argument, unlocking the
relocated lock, and retrying against its current identity. Two synthetic
negative controls omit publication or retain the pre-GC address; they fail
after 4 and 9 distinct states. The fixed abstraction passes safety and fair
completion over 10 distinct states.

These controls characterize omitted obligations, not observed candidate bugs.
Collector updates, lock-counter preservation and complete root/frame scanning
are assumptions. The model is not composed with the shared-cohort model yet.
The first construction attempt used the wrong `weakFair` signature and is
retained separately; the accepted check uses the repository-standard state set.
The exact older FFI context model was copied for publication, not executed as
an imported transition system.

## Native Observations

The independently built candidate executes three simultaneous scheduler wait
paths through two forced-GC epochs. The separately named
`gc_wait_cohort_moving_roots_unlocked_observer.scm` observes addresses before
acquiring and after releasing the controlled locks. All three executions pass:
0.739 / 0.010 / 0.010 seconds; compilation takes 0.997 seconds. Every epoch
observes all five thread objects changing address. Result symbols, GC calls
and joins remain unchanged. The processor population is host-selected; five
controlled role placements are not a global CPU limit.

The observation interval includes setup and post-unlock work, so address
differences do not isolate which particular collection moved each object.
They establish actual relocation across the tested interval, not exact
forwarding traces or complete frame-map correctness. Native process caps
remain 30 seconds, compilation 60 seconds; identity checks pass before/after.

The original `gc_wait_cohort_moving_roots.scm` runs generic `map`/FFI observers
while scheduler locks are held. It compiles, then times out at 30.011 seconds;
remaining repetitions are not run. Its original bytes, receipt and same-live
process sample are preserved. Generated calls into ordinary generic procedures
do not inherit the caller's interrupt-disabled declaration. The sample shows
the owner waiting on the processor-lock path and peers in sync/scheduler paths.
It does not identify exact lock ownership or prove a candidate root defect.
Moving only observation work outside the locked region yields the passing
separate fixture; the timeout is not overwritten or relabeled.

Portable evidence is in the `moving-root-observer-lock-denial` and
`moving-root-unlocked-observer` subdirectories of
`evidence/source-results/fixtures/scheduler-retry-sync-participation/`.
These are diagnostics, not sealed full-suite, bootstrap, Gerbil or release
admission. Physical tracing/copying refinement, collective error handling and
root/phase/retirement composition remain open.

## Shared-Cohort Extension

The subsequent `scheduler_gc_root_cohort_composition.qnt` executes the four
canonical transition systems through resolved-IR projections, without changing
their original bytes or receipts. Six controlled roles share two collective
commits. The additional lock waiter publishes its argument before participation,
remains parked across both commits, and reloads/acquires/unlocks afterward.
Both root relocations occur in the same actions as the three wait-path GC
completions; there is no separate independent GC event.

The fixed composition passes safety and fair completion over 351 distinct
states (969 generated). The five negative controls produce expected violations
over 4 / 3 / 16 / 51 / 248 distinct states. All four projection contracts
verify the canonical source, template and generated bytes. This closes the
finite shared-cohort composition gap above, not the physical collector,
memory-order, error-unwind, arbitrary-cardinality or retirement obligations.

The new `gc_root_cohort_composition.scm` parks an additional production lock
helper across both forced-GC epochs, then checks its exact return symbol and
actual target-address relocation. Three runs on the unchanged verified producer
pass in 0.729 / 0.011 / 0.012 seconds; compilation takes 0.977 seconds.
The six role placements require six available processors but do not cap the
total population, which is selected from available host CPUs. The original
30/60-second process/compile budgets and all prior cohort assertions remain.

The new manifest and model receipt are
`evidence/fixtures/scheduler-retry-sync-participation/shared-root-cohort-contract.json`
and `evidence/model-results/fixtures/scheduler-retry-sync-participation/shared-root-cohort/receipt.json`.
Native observations are separately bound under the source-results
`shared-root-cohort` directory. These remain diagnostics, not full-suite
admission; earlier models and failures are preserved rather than upgraded.
