# Interrupt Payload Physical Relocation Observation

## Actual Observation

The current thread-completion source-core candidate compiled the new fixture
in 1.697 seconds. Its three processor-queue, extracted-local and asynchronous
thread-queue windows all observed changed payload addresses after forced GC,
correct payload structure, no premature dispatch and exactly one callback.
The moving case exited zero in 0.523 seconds with exactly one success marker.

The separate no-GC control exited one in 0.517 seconds, with all three
relocation assertions reporting `GOT #f` and no success marker. That expected
fixture denial establishes sensitivity to a missing relocation observation;
it is not a runtime defect or a complete negative collector fault control.

The shared `process_observation.capture_batch` transport ran the two isolated
processes concurrently in 0.523 seconds under one unchanged 60-second budget.
Host capacity selected two workers and six requested processors per child,
not fixed twelve-processor jobs. Both process groups were quiescent; no
timeout, assertion weakening or runtime source change occurred.

## Root And Address Semantics

The payload is created in a non-inlined helper and escapes only via the actual
interrupt request/thunk. The caller does not retain it independently. C saves
only its tagged address in an unsigned integer; the old address is not a
registered root and is never dereferenced. The callback compares that saved
number with the current payload address and validates the payload contents.
Raw addresses are not printed or published.

The thread target is pinned only to create a collection-before-delivery window;
global SMP, multi-VM and threaded-VM flags remain enabled. This does not claim
arbitrary peer scheduling or scalable throughput. One forced GC per window is
intentional: two copying cycles can reuse the original address and obscure a
real intermediate move. Earlier two-GC content tests remain unchanged.

The exact identity was checked after execution. Portable fixture, identity,
logs and generated summary are under
`evidence/source-results/fixtures/interrupt-queue-payload-relocation/native-diagnostic`.
The compiled test includes an explicit nonzero failure exit, and the observer
requires the final marker plus the expected exit and no timeout.

## Remaining Proof Boundary

These observations close the earlier lack of any actual moving-address
evidence for these three diagnostic root windows. They do not prove absence
of every transient root, arbitrary root maps, publication memory order,
generation/weak-phase composition, cancellation, processor retirement or all
request graph shapes. No generated-C root-map qualification was performed.

This direct bounded compiler/executable observation is not a formal sealed
full-suite or ASCENT causal-review admission. Runtime, release and performance
admission remain false; full native suites, candidate two-pass bootstrap,
Gerbil and production reliability/performance remain OPEN. Shared graph
inputs remain frozen by their owner; this evidence has not silently replaced
an older Reflection snapshot or admitted a whole-GC claim.
