# Source-Bound Mutex Waiter Dispatch

## Correction From Native Evidence

The initial waiter-transfer abstraction conflated two SMP source paths. Its
counterexamples characterize a wrong dispatch, not an established runtime
defect. The actual queued-caller fixture passes both normal and exceptional
target termination cases, in interpreted0.588seconds and compiled3.326seconds,
with the two-pass rebuilt candidate and original60-second per-mode budgets.
The initial abstraction and correction record remain archived; no speculative
runtime patch is applied.

## Actual Call Paths

SMP `macro-mutex-unlock!` uses `##mutex-unlock-out-of-line!` for waiting callers.
That helper examines the saved new owner under the acquired thread locks and
selects `##thread-abandoned-mutex-action!` if it terminated.

The SMP calls to `##mutex-signal-no-reschedule!` in `##btq-abandon!` and the
other blocked-queue abandonment path pass `#t`. The macro calls passing `#f`
are in the non-SMP branch of `_thread#.scm`, with a different helper
implementation. Combining these branches into one unconstrained transition
was the abstraction error. This audit is not a proof about arbitrary external
calls to the internal helpers.

`abandoned_mutex_waiter_dispatch.qnt` explicitly distinguishes normal unlock
from abandonment dispatch. A wrong-dispatch control must violate the call-site
condition and the eventual outcome condition. Positive source-dispatch safety
and completion retain atomic locked-transfer and finite-model fairness
assumptions. New-owner termination after transfer, multiple callers, cancellation,
GC roots and primitive-progress/source refinement remain open.

The native fixture waits until the caller's actual `thread-state` names the
request mutex as its waiting object before allowing the target to terminate.
No relative sleeps or assertions removed. This tests normal-unlock dispatch;
it does not qualify every abandonment helper branch or full SMP lifecycle.
