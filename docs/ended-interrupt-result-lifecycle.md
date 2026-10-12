# Ended Interrupt Result Lifecycle

## Source Audit

The earlier `ended_interrupt_lock.qnt` checks target-lock release only; its
scope explicitly excludes request-result delivery. The cumulative source has
the repaired terminal propagation branch, but requester completion also
depends on owned-mutex termination cleanup.

Pinned source plus `sfun-owned-unwind` overlay establishes these obligations:

| Path in `lib/_thread.scm` | Required protocol |
| --- | --- |
| `##thread-interrupt!` | Validate active target under its low-level lock |
| `##thread-intr!` | Register result mutex with target ownership before propagation |
| `##mutex-lock-out-of-line!` | Reject terminated new owner with abandoned exception |
| `##thread-intr-propagate!` | Release target lock even if target ended after validation |
| `##thread-end-locked!` and `##btq-abandon!` | Abandon every owned mutex on target termination |
| `##other-interrupt!` | Publish thunk result before unlocking result mutex |

An owned result mutex does not by itself imply a stuck requester: the target's
termination protocol abandons it. No runtime change is justified solely by
observing the propagation helper return without directly unlocking that mutex.

## Composition Model

`ended_interrupt_result_lifecycle.qnt` explores target termination before
registration, between registration and propagation, and after propagation.
It combines target-lock release, ownership registration, abandonment and
requester outcome. Independent controls omit terminal unlock or owned-mutex
abandonment. Positive checking must establish safety, absence of nonterminal
deadlock and completion under the stated finite-model fairness assumption.

This model does not prove a simulation relation to the older model. Atomic
lock/register/termination abstractions assume the native primitive contracts.
It omits global interrupt queue reclamation, multiple requesters, thunk
exceptions, request cancellation, weak-memory publication, processor retirement,
moving-GC roots and starvation-free native scheduling. A model pass cannot
close these omissions or replace source-bound native tests.

## Native Feedback: Abandoned State Lost

The first source-bound ownership fixture failed both normal and exceptional
termination cases in interpreted execution: requester `mutex-lock!` returned
`#t` instead of raising `abandoned-mutex-exception?`. This is not a timeout.
The earlier include-path fixture failure is separately retained.

In the SMP `##mutex-lock-out-of-line!` unlocked branch, `owner` records the
prior mutex state, but `state` becomes the new live owner. The subsequent
exception check only compares `state` with the abandoned marker, losing an
already-abandoned `owner`. The positive abstraction had assumed this exception
contract. `initLostAbandonedException` now removes that assumption explicitly:
it reports success for an abandoned result and must violate `outcomeSafe`.
A proposed repair must preserve both prior abandonment and rejection of a
terminated new owner; it must not alter the fast path or serialize SMP.
