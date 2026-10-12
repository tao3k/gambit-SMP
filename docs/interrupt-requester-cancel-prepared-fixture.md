# Prepared Non-Atomic Cancellation Validation

The cancellation QNT now separates request, waiter unlink and actual termination.
Normal result arrival may interleave before unlink; a prior wake is not itself
a post-termination wake. Initiated cancellation must drain before terminal.
Typechecking and fixed-input validation passed. The subsequent independent
exhaustive result is recorded in `interrupt-requester-cancel-model-result.md`:
192 distinct states, safety and weak-fair completion checked, three controls.

Six lightweight Quint trajectories now pass: retained receiver ownership after
cancellation, result arrival before unlink followed by cancellation, and three
controls for dead wake, lost lifetime and wrong ownership, plus a detached-waiter
wake before termination commits. The latter closes a model observation gap:
result wake exclusion begins at unlink rather than only at final termination.
The initial command
also selected helper actions named `*ForTest` as independent uninitialized
tests and failed three times; renaming helpers to `*Step` preserved every real
trajectory and action. The latest command exited zero, six passing, in
73 ms after initializer refinement. These local trajectories are not a portable exhaustive receipt or
native acceptance.

`models/gambit/native/interrupt_requester_cancel_gc.scm` compiled with the checked
current source-core candidate and GNU GCC 16.2.0 in 1.883 seconds, exit zero,
no timeout, quiescent process group, under the unchanged 60-second cap.
Runtime/source identity was checked before and after compilation. It then
passed execution in 0.722 seconds. The later added post-cancellation GC
scenario compiled in 1.597 seconds and passed in 0.865 seconds. Exact snapshots
and remaining limits are in `interrupt-requester-cancel-native-result.md`.
It uses actual synchronous interrupts, distinct
host-selected processor placements, release/acquire milestone flags, callback
payload relocation, thread-state confirmation of receiver-owned result waiting,
requester termination/join, receiver completion and absence of late requester
continuation. The observation helper returns void so it does not intentionally
retain the result mutex in the orchestrator across cancellation.

Yielding polls observe actual milestones; sleeps or output heartbeats do not
stand in for progress. A run must remain under the existing process budget and
retain timeout/exit/teardown as failure evidence. Callback and state API native
behavior are not established merely because this Scheme file exists.

The shared owner has exclusive repair/qualification inputs after the real
full graph DENY. This task changes only unregistered QNT/fixture/contract/docs,
not its canonical registry, shared Python or test files. The model/control
validation window has completed and was explicitly released. The next separately
coordinated window completed the native diagnostics above. Any future native failure must
refine the model's source assumptions,
not be retried unchanged or hidden behind a larger timeout.
