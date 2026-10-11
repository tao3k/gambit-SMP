# Collector Work Closure

## Decision Before Source Changes

- Direction: the GHC ISMM 2008 paper's sections 3.1-3.6 describe interacting
  collector-worker protocols, not just a block layout.
- Prior coverage: forwarding, ticket acquisition and worker termination were
  checked separately. Their assumptions omit the combined local-work,
  recursive-discovery and phase-transition state space.
- Value: test the shared protocol obligations before recommending another C
  patch. A public forwarding address is not permission to scan copied payload.
- Expected benefit: stronger correctness guidance; no measured speedup or
  claim of a newly discovered source defect.

## Bounded Composition

`gc_work_closure.qnt` has two workers, a cyclic reachable graph `1 -> 2 -> 1`
and two abstract scan phases. The root starts as private work; scanning it
discovers the second object. An object represents a pending region rather
than an actual block layout. The state distinguishes discovery, private
copying, shared publication, active scanning and completed scanning. Copying
uses two stores; private work keeps its owner counted while helper workers
may wait. Shared work requires reactivation before acquisition. Barriers
close the first phase before resetting work in the second phase.

Canonical revisits of already discovered graph nodes do not create new work.
Competing forwarding CAS remains a separate model: this composition assumes
that canonical identity is already unique. It does not reproduce the complete
weak-reference traversal, byte layout, allocation failure or VM resizing.

The source correspondences are `mark_array`, `end_heap_chunk`,
`scan_movable_objs_to_scan`, `scan_complete_heap_chunk`,
`mark_reachable_from_marked` and the barriers in `___garbage_collect_pstate`.
Queue release/acquire visibility and count/wait updates are abstract atomic
contracts, not proofs of their implementation or the C memory model. The
GHC claim-copy-forward protocol is not substituted for Gambit's existing
forward-before-copy protocol.

## Checked Results

Quint 0.33.0 / TLC found all four independent injected faults:

| Fault control | Rejected property |
| --- | --- |
| Publish before both copy stores | No scan of incomplete payload |
| Become idle with private unfinished work | Termination implies reachable work completed |
| Acquire without removing queued work | At most one scanner claims each region |
| Acknowledge a barrier before phase completion | No unfinished work crosses the phase boundary |

The positive protocol exhausted 254 distinct / 379 generated states, search
depth 34, with zero states remaining on the queue. All five verifier checks
were admitted and the model source remained unchanged. The four portable
counterexamples are frozen under `models/gambit/counterexamples/`; the receipt
is `evidence/model-results/gc-work-closure.json`. Original verifier logs remain
in `.data/gc-work-closure-model-001/` because they contain machine-local paths.

These are bounded safety results. They do not prove scheduling fairness,
condition-variable progress, source refinement, full SMP correctness or a
Darwin-specific cause. No new runtime patch follows solely from the positive
model. Before changing C, identify which actual source transition can violate
an obligation, bind the counterexample to that transition and add an unchanged
native regression. The outstanding architecture models include mutator
quiescence/root admission composed with synchronized operations, worker
membership changes, and representation/lifetime obligations for special
readers. Complete bootstrap and Gerbil acceptance remain separate gates.

## Existing Candidate Coverage Boundary

The already-started runtime026 compiled campaign is DENY after 640.152 seconds,
not a full-suite green result. It used 127 planned batches with one file per
worker, host-selected three workers/three child processors and a 300-second
budget per batch. The first 31 batches cover 93 completed files. In batch31,
`fltruncate.scm` and `flzerop.scm` separately pass; `_num.scm` exhausts its
remaining 298.950-second shard budget without a completed-file marker. No
assertion failure was observed. Its generated C exists, but this campaign does
not record separate compile-stage timings.

The earlier runtime021 unchanged `_num.scm` phase diagnostic already records
Scheme-to-C success in 30.818 seconds followed by C-module compilation budget
denial. That is prior evidence, not proof of runtime026's exact timeout cause.
Do not repeat the unchanged route or treat this budget failure as a GC model
counterexample. The terminal receipt and failed-shard log are retained under
`evidence/model-results/native-upstream-compiled-atomic-026-deny.*` and indexed
as a budget denial. This campaign tests existing code; it is not admission of
a repair derived from the new composition model.
