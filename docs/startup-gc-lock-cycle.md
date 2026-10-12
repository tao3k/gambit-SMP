# Startup GC and Pinned Enqueue Wait Cycle

## Source and Native Evidence

The source authority is the pinned Gambit submodule plus semantic fixture locks
and cumulative overlays, not an execution cache. The collective heap-guard
runtime completes the second grow, but the original reuse regression remains
DENY at the second worker start. It is not an accepted repair of the whole
lifecycle.

An isolated host `sample` observation of that runtime maps the main thread to
offset 1236 in the pinned enqueue function. Disassembly maps this offset to the
target processor's ticket-lock spin, before queue insertion. Eleven peers are
in `___sync_wait`. The sample alone does not identify their synchronous round.

Two diagnostic-only overlays add startup-thunk and GC stage observations. The
second adds the GC request before the initial collective barrier, rather than
only observing entry to the collector. Its last stderr events are:

```text
SMP-STAGE startup-thunk-enter processor=11
SMP-STAGE gc-request processor=11
```

The reuse fixture has already returned from second grow and entered
`thread-start!`, but not returned. No processor enters the subsequent collector.
The request/entry distinction is essential: a missing GC entry does not mean
that no GC was requested. Each native run retains its 30-second whole-process
budget and ends with a quiescent process group.

These are separately identified runs, not a fabricated same-run full trace.
They support the source wait-cycle explanation: startup still owns the initial
processor lock and needs collective GC, while the requester waits for that lock
inside an interrupts-disabled enqueue path. Requester GC participation is then
missing. The collector-stage and frame/root details remain source refinements.
Logging can change scheduling; diagnostic overlays are not release repairs.

## Model Feedback

`resize_startup_gc_lock_cycle.qnt` models initialization, unlock, return, lock
wait and collective GC participation separately. Its old path has a short
explicit wait-cycle counterexample in the Rust backend. A fixed design delays
return until unlock while preserving old-member GC participation. Bounded Rust
checks are not exhaustive or temporal proofs.

The first TLC check using `enabled(step)` reached `Starting` but provided no
state counts before its unchanged 90-second budget. Its source snapshot and
DENY are retained in
`evidence/model-results/fixtures/startup-gc-stage-observation/enabled-check-timeout`.
A distinct explicit-predicate check then failed its 10-second `quint --version`
preflight. Neither denial is reclassified as a protocol counterexample or green
model; no checker budget was increased.

`resize_startup_generation_failure.qnt` adds two generation tokens and terminal
success/failure publication. Its negative controls address accepting old ready
and omitting a failed startup outcome. Atomic outcome publication is a design
abstraction, not implemented C behavior or an established rollback protocol.
Both generation/failure negative controls were observed in the Rust backend;
the fixed design found no invariant violation in 80 samples of up to 20 steps.
The GC-lock fixed design also found no violation under the same bounded limits.
These receipts are retained under
`evidence/model-results/fixtures/startup-gc-stage-observation/bounded-design-controls`.
They are deliberately not registered as exhaustive `protocol_checked` facts.

## Required Source Refinement

- Bind readiness to the current resize generation and its member set; clear or
  supersede previous-generation state before slot reuse.
- Publish success only after scheduler queues, root thread and lock state are
  usable, with explicit C release/acquire ordering.
- Publish terminal startup failure and establish real rollback/quarantine;
  a success-only ready flag can leave all waiters blocked forever.
- Service actual collective GC while waiting without holding a processor or
  VM queue lock that startup or collector needs. A busy readiness spin is not
  an accepted repair.
- Bind nested GC/barrier rounds, retirement idle-queue unlink, physical root
  ownership, failed joins and cancellation to this protocol.
- Validate the resulting source repair with original native reuse/GC regressions,
  full bootstrap, upstream suites and Gerbil before performance admission.

## Durable References

Stack/disassembly binding:
`evidence/source-results/fixtures/collective-resize-heap-guard/stack-observation.json`.
Diagnostic source/native binding:
`evidence/source-results/fixtures/startup-gc-request-observation/observation.json`.
Models, diagnostic overlays and source locks live in the repository. Python
framework/provider code was not changed. Runtime/release admission remains false.
