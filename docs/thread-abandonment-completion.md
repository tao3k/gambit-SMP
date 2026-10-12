# Thread Abandonment And Completion

## Source And Report

This model audits the ownership/completion portion of
[PR #1035](https://github.com/gambit/gambit/pull/1035) at
`ad2bd23fcc689ce76a96c725e4c579d77bcdc71d`. The manifest binds its complete
three-file API patch page and refreshed public snapshot, plus candidate027
`_thread.scm` and `_thread#.scm`. No PR patch was applied.

Candidate027's SMP `##thread-end-locked!` clears end-condvar before its mutex
abandonment loop while retaining the thread lock. The patch drops the thread
lock before taking an owned mutex lock, then reacquires and checks its owner.
This solves a different obligation from simply removing a lock cycle: once
the lock is dropped, public unlock/ownership transfer can invalidate the
selected mutex. The patch also uses the existing continuation termination
marker to reject new grants while retaining end-condvar until cleanup finishes.
Both join and terminal thread-state visibility must wait for that completion.

The author reports 18/18 targeted runs, not complete runtime correctness.
Serialization failures and a larger diagnostic crash remain reported in both
versions. These failures are retained; the model does not reclassify them.

## Bounded Model

The state tracks two mutex identities, one closing owner, a different live
owner, pending selected mutex, transferred ownership and join visibility.
The two-mutex bound is disclosed finite verification scope, not a machine or
package-specific constant. Ownership sets derive from the owner map. Completion
is permitted only when no mutex remains owned by the terminating thread.

| Incomplete Repair | Derived Violation | Counterexample States |
| --- | --- | --- |
| Drop the thread lock but retain early end-condvar clearing | Join can return while the owner still holds mutexes. | 4 |
| Reorder locks but omit owner revalidation | Cleanup abandons a mutex transferred to a live owner. | 5 |
| Delay completion but keep admission tied only to end-condvar | A closing thread accepts a new mutex grant. | 5 |

These are intentionally incomplete repair controls, not three alleged new
native failures. The fixed contract checks safety and progress over **42
distinct / 50 generated states, zero queued**, in **29.694 seconds**.
Receipts and all three traces are in
`evidence/model-results/thread-abandonment-completion/`.

The first run found the four-state join counterexample, but the framework
rejected its unsupported TLC map syntax. The denied original receipt remains
in `.data/audit-thread-abandonment-001`. Strict generic integer-map parsing
was added to the existing uv package; run 002 recovered the same log without
rerunning that TLC check. The other two negatives took 29.997 and 25.107
seconds. Both model/source contexts were stable. The current shared framework
regression passed **214 tests in 43.905 seconds**; this is not a native pass.

## Deliberate Limits And Next Obligations

The model abstracts ordered lock acquisition as one transition; it does not
prove the whole lock graph. There are no waiting callers, priority inheritance,
thread-group removal, asynchronous interruption, moving GC or weak memory.
The fixed policy rejects new grants, but its implementation must still be
audited at every mutex admission call site. Fairness and finite transfers are
explicit assumptions, not arbitrary-thread progress proofs.

Next compose the waiting thread's requested owner, abandonment exception and
run-queue publication with #1029/#1047; then priority donation with #1050 and
thread-group operations with #1026/#1031. Do not rerun the unchanged broader
crash just to show it still exists. A changed candidate needs source-bound
thread/mutex ownership observations, then interpreted/compiled regression,
all-three-flags bootstrap and complete real tests. No native, bootstrap or
performance acceptance is granted here.
