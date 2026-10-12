# Interrupt Queue Payload Root Native Observation

## Result

The new `models/gambit/native/interrupt_queue_payload_roots.scm` compiled
against the actual thread-completion source-core candidate in 2.344 seconds
and executed in 0.640 seconds. Both processes exited zero, did not time out
and had quiescent process groups. Each retained its 60-second diagnostic cap.
Requested processors came from the host capacity function, observed 12;
this observation does not independently probe physical processor population.

The compiled fixture checks processor-queue and extracted-local ownership
windows. A non-inlined helper creates and registers the request, then returns
only void. Neither caller stores the payload independently. Each window forces
two GCs, verifies no early delivery, validates payload contents during dispatch
and checks the delivery count. Assertion failure causes a nonzero exit; success
requires exactly one `INTERRUPT-QUEUE-PAYLOAD-ROOTS-OK` marker.

The first compile exited 70 because the uninstalled source runtime could not
resolve default `~~bin`. That observation is retained. Explicitly binding the
current source runtime's `~~` directory repaired tool resolution without source
changes, global installation, compiler substitution or a larger budget.

Actual runtime identity was checked after execution, and independent sealed
source-core read returned CURRENT/PASS with runtime/source admission false.
Portable fixture snapshot, exact identity, logs, raw observation hashes and
bounded summary are under
`evidence/source-results/fixtures/interrupt-queue-payload-roots/native-diagnostic`.

## Boundary

This is a direct diagnostic compiler/executable observation using the shared
process capture utility, not a sealed typed suite or ASCENT causal-review
admission. It cannot discharge the formal continuation gap or complete native
test gates. No feature-specific Python producer was added.

Removing the independent lexical payload root improves sensitivity but does
not prove absence of every conservative/transient runtime root. Two GCs do
not prove physical relocation; generated-C liveness and address forwarding
are not qualified here. Thread-queue, concurrent cancellation/retirement,
weak/strong phases, repeated stress, complete bootstrap and Gerbil acceptance
remain OPEN. This result does not establish or repair a new runtime defect.
