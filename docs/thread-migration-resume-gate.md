# Independent migration resume gate

## Admission review

- The destination mismatch is a real compiled observation, separate from the
  unpinned shrink timeout; see `docs/thread-migration-destination.md`.
- A temporary user pin would close stealing but restoration can overwrite a
  concurrent user pin update. The new candidate never changes that field.
- The independent gate model reproduces the old destination-stealing control
  in ten distinct states and passes fixed safety/completion in 28 distinct /
  42 generated states. One user pin update can occur at every pre-return stage.
- This targets correctness of an existing internal C-return hook. Removing a
  fixed busy loop may reduce migration cost, but no performance gain is claimed
  before matched real measurements.

The published source-context model receipt is
`evidence/model-results/fixtures/startup-sync-flag-handoff/migration-resume-gate-contract/receipt.json`.
The model has five unresolved obligations and is not native or source admission.

## Source candidate

The cumulative overlay and lock are
`patches/fixtures/thread-migration-resume-gate.patch` and
`evidence/fixtures/thread-migration-resume-gate/source.lock.json`.
They retain all 16 authority files from `startup-sync-flag-handoff`; only the
thread implementation differs from that parent. The overlay was reapplied to
immutable pinned source blobs and all 16 candidate hashes matched.

An internal resume action marks the migration as awaiting destination ownership.
Migration saves the thread, sets that action and clears donor current-thread
before publication under the destination processor lock. The remote stealing
path skips this action, independently of user pin state. The local destination
can restore the thread and eventually invoke the action, which returns its resume
thunk to the ordinary void action. The fixed busy loop is removed.

This reuses the internal resume-thunk protocol rather than allocating a side
table, changing thread layout or overloading user-visible thread-specific data.
No package-specific code is introduced. The parent remains untouched, and the
runtime candidate uses a copy-on-write isolated execution tree.

## Source refinement boundaries

The model's gate consumption maps to the migration completion resume action,
not merely queue insertion or a elapsed delay. Processor queue locking orders
the marker write before remote consumers obtain that queue. Existing scheduler
thread locks still govern extraction and restoration.

`##thread-resume-execution!` snapshots the action, processes pending interrupts,
then calls it. Interrupt handlers may yield, cancel, terminate or change state;
this interval is not modeled by the 28-state contract. Resume-thunk replacement,
user cancellation/exception, destination retirement and rollback therefore
remain explicit open requirements. The candidate must not be promoted merely
because the ordinary no-interrupt regression passes.

Saved-frame storage, roots, admission closure and running/queued/parked thread
drain remain separately required for shrink. This candidate is not a replacement
for full donor retirement or a reason to retry the unchanged shrink failure.

## Build boundary

The first validation is an incremental GNU source-core build in an isolated
tree, with host-adaptive make jobs and a shared compiler processor budget. The
whole core budget remains 180 seconds. It is not a fresh configure, complete
two-pass bootstrap, upstream suite pass or Gerbil acceptance. Native migration
must use the resulting checked runtime identity and unchanged canonical fixture.

## Actual component results

The isolated incremental core build passed in 118.015712 seconds. Exactly seven
source inputs changed relative to the parent identity: `_thread.scm`, its C
output, and the five associated library/compiler/interpreter generated links.
All 16 locked candidate source hashes and the resulting runtime identity were
checked. No fresh configure or full bootstrap admission is inferred.

The byte-identical compiled migration fixture that failed on the parent now
passes: compilation 18.552292 seconds, execution 2.841135 seconds. It traversed
all detected processors consecutively and forced GC after each migration.
The fixture was not pinned, changed or weakened for the positive run. Parent
failure and candidate success have separate executable/runtime identities.
Their elapsed times are not a performance A/B claim because the parent aborted
in the first iteration while the candidate completed all iterations.

Durable component receipts and runtime identity are in
`evidence/source-results/fixtures/thread-migration-resume-gate`. Complete native,
cancellation/exception/retirement, bootstrap and Gerbil acceptance remain open.

The parent's unchanged interpreted slot-reuse/forced-GC control also passes in
6.416253 seconds, and mixed-key GC passes in 0.494942 seconds. These are correctness
checks under the existing 30-second process budget, not matched speedup results.
The reuse elapsed time is higher than the earlier parent observation; it is
retained rather than hidden, and performance remains unqualified.
