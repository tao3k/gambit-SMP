# Failed Join Ownership Gap

## Current Source Observation

The resize-grace lock binds setup.c to
`9d028d74abdf9efa98e9f8616ffeb6a6b66aeedd63ccbee91ed5731b1c41c2a2`.
`___vm_resize_pstate` publishes the reduced processor count through
`barrier_sync_op` before joining the departed processor cohort. On a join error
it returns the first error without transferring or cleaning that processor's
memory. This correctly retains resources locally, but active processor count
is already reduced.

`___cleanup_owned_vmstate` rejects the root VM and count != 1, but does not
check outstanding join ownership outside the active cohort. It calls
`cleanup_vmstate_locked`, whose all-slot loop destroys synchronization and
interrupt resources before VM OS/memory cleanup. Therefore count == 1 alone
does not establish the helper's stated precondition that every cohort has
joined. This is a source-derived counterexample, not a native crash receipt.
The explicit direct-user join precondition remains separate.

## Model Contract

`vm_registry_failed_join_retention.qnt` distinguishes active membership from
pending OS-thread joins. Its count-only control publishes count 1, observes a
join failure, and permits cleanup while pending ownership remains. The proposed
contract rejects cleanup and retains resources until a successful retry join.
Exclusive lifecycle ownership and atomic protocol steps are assumptions; no
OS join recovery, memory-order refinement or general progress proof is claimed.

Source repair must record outstanding cohort ownership before shrink publication,
clear it only after successful joins, prevent cleanup and slot reuse while it
remains, and define a real recovery path. Merely adding a permanent rejection
flag is insufficient for recoverable errors. Thread creation failure rollback,
root cleanup, public void cleanup and direct embedding ownership also require
audit. Native fault injection must bind the actual current artifact and prove
that the injected join route was reached; a passing ordinary join is not enough.

## Bound Model Result

Recipe `smp-failed-join-retention-contract` consumed the current source lock and
default-profile completed producer through the existing handoff protocol.
Run: `.data/fixtures/vm-registry-reader-lease/failed-join-retention-bound-model-run`.
The safe protocol exhausted 9 distinct / 18 generated states with an empty
queue. The count-only negative control produced a four-state trace: active,
reduced-count/pending-join, failed-join, resource cleanup while join remains
pending. All four declared trajectories passed. Whole time was 31.588413
seconds; sealed readback CURRENT/PASS, without runtime or refinement admission.
The first unbound model recipe was denied before execution and was corrected
by adding the existing locked-source producer path, not bypassing that policy.

This is defensive API and recovery-contract evidence. Existing ordinary fixtures
abort on resize errors, so the model does not assert that their observed passing
paths call cleanup after a failed join. Such a caller may also violate the helper's
documented joined-cohort precondition. Slot reuse on a subsequent grow still
requires explicit ownership auditing. Actual source repair and native injected
failure verification remain open; this model pass does not close that gate.
