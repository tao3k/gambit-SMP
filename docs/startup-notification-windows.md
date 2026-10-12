# Startup notification windows

## Why this contract is needed

The earlier `resize_startup_sync_flag_handoff` model treats a received READY
round atomically and only inserts a new request after common exit. Native passes
do not close the resulting independent-member timing obligation.

`resize_startup_notification_windows` instead separates each member's proposal,
waiting, reply receipt, flag reset, operation-slot commit and NOOP return. A
member can propose its next round before its peer commits the previous one.
An exited member can issue one later READY, GC or ERROR while its peer is still
returning from the prior NOOP round. Barrier generations must match, and a
published reply remains available until both members finish that generation.

The root's initial first-iteration reset already happened; its initial flag was
rearmed by the peer's READY. The old control omits the READY reset. The fixed
protocol models the exact reset condition in the clean source overlay.

## Source binding and explicit limits

The manifest binds the cumulative `startup-sync-flag-handoff` source lock and
patch. Operation codes are ERROR 0, GC 14, READY 24 and NOOP 252. In the pinned
source, `barrier_sync_op` gathers proposals before publishing a winning reply;
`execute_sync_op_loop` resets a member's flag after receiving that reply, then
commits only a matching owned slot or combining operation. The model retains
the peer's pending later request until its winning operation commits.

Both members must have committed READY before the next generation can elect
NOOP. Consequently, a new call from an exited member cannot precede the peer's
previous READY reset in this represented topology. Its notification can overlap
the peer's local NOOP receive/reset/commit/return steps, which are individually
scheduled rather than one global atomic action.

Two members are a model bound, not a host concurrency setting. This contract
does not implement GC execution, ERROR propagation/rollback, combining requests,
arbitrary tree topology, membership changes or a weak-memory refinement. It does
not license unowned foreign request-slot mutation. Those requirements remain in
the manifest and must be composed with source/native evidence before full green.

## Retained model defect

The first independent-step model incorrectly classified a member waiting to
read an already-published reply as stranded when its peer had exited. Its fixed
run violated that assertion after 271 distinct states. The trace showed a NOOP
reply already elected for the root's current round: `rootRound = electedRound =
1`, while the peer had exited to round 2. The root's receive action remained
enabled. This is a model predicate defect, not evidence of a new source deadlock.

The corrected invariant requires the root to be waiting in a generation without
a published reply before diagnosing a new unmatched collective. The failed
attempt, original model bytes, logs and checker identity are archived at
`evidence/model-results/fixtures/startup-sync-flag-handoff/notification-windows-published-reply-misclassification`.
That archive is non-admitted and is not registered as a checked protocol.

## Exhaustive result

The reply-aware old control reproduces the missing READY reset failure in 64
distinct / 105 generated states. The fixed safety and temporal completion check
passes with 516 distinct / 846 generated states. The checks took 21.713 and
22.457 seconds respectively, including backend startup. Worker selection used
the framework's detected host capacity and memory budget, not a fixed count.

The portable positive/control receipt is
`evidence/model-results/fixtures/startup-sync-flag-handoff/notification-windows-contract/receipt.json`.
It is registered in the Datalog bundle registry. This is finite protocol evidence,
not runtime or release admission. It strengthens the prior atomic-round model;
it does not replace the broader open source/GC/lifecycle requirements.
