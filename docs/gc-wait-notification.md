# GC Wait And Work Notification

## Pre-Code Review

Existing models correctly distinguish active producer work from an empty queue,
but abstract waking too strongly: queue availability alone enables a waiter to
wake. The actual POSIX source uses unbuffered condition notifications. This new
model refines that boundary; it does not repeat a denied native route. Potential
parallel-work latency benefit is plausible but unmeasured. No end-to-end speedup,
native deadlock or historical compiler-crash explanation is claimed.

## Source Facts

Candidate027 `mem.c:3402-3456` publishes under the queue spinlock, releases that
lock and signals the scan condition without the termination mutex.
`mark_reachable_from_marked:6910-6957` performs its final steal attempts before
acquiring that mutex and decrementing the active count. `CONDVAR_WAIT` registers
and releases the mutex at line 6973. Publication/notification can therefore fall
between the final probe and waiter registration. Source uses the mutex for
termination signals at lines 6957-6964, so those are a different protocol.

Own-queue scanning is not omitted: `scan_movable_objs_to_scan:4502-4536` drains
the producer's complete chunks before returning to the idle-count path. Together
with counted eager activity, this may still complete the collection even when
a helper misses a work notification. A missed parallel-work opportunity is not
automatically a deadlock or a correctness violation. Do not conflate them.

The configured POSIX macros map to `pthread_cond_wait`/`pthread_cond_signal`
(`include/gambit.h:10923-10924`). Atomic registration/unlock, mutex reacquisition
and an unbuffered notification are protocol assumptions, not a full OS proof.
The GHC/HotSpot termination principle supplies the separate completion obligation;
neither paper proves Gambit's condition-variable handshake.

## Model And Controls

One producer/helper and one chunk separate probe, mutex lock, decrement,
registration, notification, wake, count restoration and local drain. One optional
spurious helper wake checks that count restoration still obeys the zero-count
exit branch; unbounded spurious behavior and scheduler fairness remain open.

Three independent negative controls show:

- Source notification can arrive before registration and be lost.
- Protecting only signal still loses a notification before the waiter locks.
- Rechecking only the predicate still loses an unprotected signal after that
  recheck but before registration.

The characterization initializer explores source and all three proposal policies.
`guardSound` requires count/closure correctness for all of them, and reliable work
notification only for the combined recheck/protected-signal contract. Progress
must still finish for the source policy via producer drain and protected final
termination notification. The repaired proposal is abstract, not implemented C.

The model has no global serialization requirement for copying or eager scanning.
It does not impose whole-object ownership after tail export. It assumes coherent
single queue claims, initialized sync resources and no teardown during the phase.

## Repair Admission

Before C changes, bind the predicate to actual per-processor queues and prove
queue/termination lock ordering; do not add an inverse nested lock. Model multiple
publishers, condition errors and arbitrary repeated wakeups. Keep initialization
and retirement ownership obligations open. Validate constructor and phase-barrier
composition, then actual native lifecycle/GC regressions, full bootstrap and
Gerbil correctness/performance. No unchanged native retry is admitted here.

## Verified Receipt

`quint typecheck models/gambit/gc_wait_notification.qnt` passed before model
checking. Campaign `gc-wait-notification-001` found all three expected missed-work
notification counterexamples. Positive characterization completed safety and
weak-fair progress across all four policies: 466 distinct states, 826 generated,
zero queued in 38.665 seconds. Context remained stable; workers were detected
from the host. Portable evidence is in `evidence/model-results/gc-wait-notification/`.
No runtime repair or native test was run; runtime and release admission are false.

After registration, the wait-notification, eager-chain, constructor-contract and
report-link modules passed 20 framework tests in 35.755 seconds. These checks
validate model/evidence boundaries; they do not execute Gambit's native GC.
