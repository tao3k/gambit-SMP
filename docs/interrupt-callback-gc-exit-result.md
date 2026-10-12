# Interrupt Callback GC And Exit Result

## Model And Native Observation

The source-bound QNT composition passed safety and explicit weak-fair progress
over 48 distinct states, 87 generated and zero queued. Three controls found
required callback-root, early-success and lost-exception counterexamples.
The complete campaign took 13.330 seconds under unchanged 90-second check
budgets. Portable validated model evidence is at
`evidence/model-results/research/interrupt-callback-gc-exit`.

The current thread-completion candidate compiled the corresponding native
fixture in 1.310 seconds and ran both normal and exceptional callback cases
in 0.952 seconds, exit zero, no timeout, quiescent groups. Requested processor
population came from host capacity, observed 12, not a fixed source constant.
Compile and execution each retained the 60-second diagnostic cap.

Payload is created inside the executing callback, not captured from its caller.
An unregistered integer remembers its address without dereferencing it. Each
case forces GC and requires actual address change plus intact vector contents.
The normal case returns the intact vector and joins a normally completed
target. The exceptional case requires an abandoned result mutex for the
requester and an uncaught exception when joining the target. Both require
exactly one callback. Assertion failure exits nonzero; the observer requires
the single two-case completion marker.

The target is pinned only to control the diagnostic scheduling window; SMP
and the multi-VM/threaded-VM configuration remain enabled. This is not arbitrary
peer scheduling or a production performance result. Actual source/runtime
identity was rechecked after execution.

## Boundary

Portable native fixture, logs, identity and summary are at
`evidence/source-results/fixtures/interrupt-callback-gc-exit/native-diagnostic`.
The summary binds the corresponding checked model receipt, but does not infer
source refinement from matching names or passing processes. No Python producer
or runtime source repair was introduced.

This closes a concrete diagnostic observation gap between dequeue, moving GC,
normal result publication and exception-driven target termination. It does not
prove every generated root map, concurrent caller cancellation, nested foreign
callbacks, arbitrary request graphs, processor retirement or GC phase ordering.
Formal sealed suite continuation, complete native tests, fresh two-pass
bootstrap, same-candidate Gerbil and production reliability remain OPEN.
Shared graph inputs remain owner-frozen; no global Reflection was overwritten.
