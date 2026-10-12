# Requester Cancellation Source Audit

## Concrete Source Sequence

The pinned `lib/_thread.scm:##thread-end!` does not directly remove a started
requester and free its result. It sends a synchronous interrupt whose thunk
calls `##thread-end-current-thread!`. Its inactive/abandoned exception catcher
allows a termination race, but that is not proof of successful peer shutdown.

`##thread-intr-propagate!` uses `##thread-lock-remove-btq-toq!`. That helper
locks the thread and inspects its blocked-queue container. A mutex/condition
container is acquired by trylock to avoid inverted cross-locking; failed
acquisition releases the thread and retries. Successful acquisition removes
the thread from the blocked queue before its termination interrupt is made
runnable. Queue removal does not abandon a mutex owned by another thread.

`##thread-end-locked!` separately iterates queues owned by the exiting thread
and abandons them. Thus the original receiver-owned result mutex and the
new termination-request mutex have different owners. Treating all result
objects as resources of the old requester would conflate these protocols.

## Model Limitation And Native Plan

The initial cancellation model projected an atomic successful waiter removal
and termination. Source feedback has now split request, unlink and actual
termination into separate transitions, allowing result arrival before unlink.
Trylock/retry, rescheduling and the actual low-level memory operations remain
premises. Cancellation cannot begin after an already observed return; if a
result arrives after request but before unlink, a historical wake must not be
misclassified as a post-termination wake. These scope limits remain explicit
before exhaustive/native acceptance.

A native fixture must establish that the requester is actually waiting, that
the receiver callback is in flight, and that requester termination has actually
completed before allowing callback return/exception. It must then verify
receiver payload across moving GC, caller join outcome, no late requester
continuation and target exit under bounded teardown. No sleeps or synthetic
heartbeat may stand in for these milestones. Distinct processor placements
must come from available host capacity, retaining SMP rather than serializing
the runtime to make the fixture pass.

The finite cancellation model subsequently checked 192 states, safety and
weak-fair completion, with three required fault controls. Two compiled native
diagnostics now confirm actual blocked result waiting, requester termination
and join, no late continuation, and payload survival with GC before and after
termination while the receiver callback remains alive. These observations
do not establish every unlink/retry schedule or physical memory-order premise.

The original framework failures were repaired and passed on prior inputs.
The later registration exposed a fixed-tail historical-registry test assumption;
that DENY is retained and the test owner is coordinating version-chain repair.
No shared Python, tests or canonical native-failure inventory was edited here.
