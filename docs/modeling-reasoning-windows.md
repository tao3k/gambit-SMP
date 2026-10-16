# Modeling as an optional reasoning window

The Action interface exposes an additional perspective, not a procedure for an Agentic AI to obey. The evidence graph constrains supported claims, identity and execution authorization; it does not constrain the model's reasoning universe. No read-count or attempt-count threshold, fixed ranking, mandatory QNT-before-Lean step, model-before-code gate, or exhaustion of the graph is introduced.

The caller-owned `evidence/dsl/modeling-guidance.ss` derives source-bound options through the existing declarative Evidence API. Python transport, Action selection and the sealed execution kernel are unchanged. Downstream still supplies definitions/data via Python/C ABI; no downstream import, build or compiler.

## Signals and options

* A source-bound report of non-discriminating inspection opens a model-fit review window. The module does not claim to observe tool reads or infer stagnation from elapsed time. A report without provenance cannot establish that condition.
* Unclear protocol/ownership transitions open state-machine investigation. QNT is an option for finite schedules, invariant violations and negative controls, not the compulsory next step.
* An explicit insufficient-coverage review opens model extension; an execution refutation opens assumption/abstraction repair. Preserve the failed experiment and distinguish a model gap from a runtime repair.
* An unmapped abstraction opens concrete-source correspondence review. It does not imply adding more unrelated models is useful.
* A finite-only result for an unbounded obligation opens an inductive/refinement investigation. Lean is an option; missing fairness or source assumptions remain explicit premises, not facts created by a proof tool.
* Empirical ambiguity opens discriminating observation or matched measurement. Mathematical models cannot establish actual object provenance, runtime causality or performance by themselves.

`method` is caller-declared, many-to-many data. Multiple methods for an obligation produce multiple options with no assigned order or exclusivity. No available option is a requirement to stop source reading or forbid an alternative investigation. A coverage declaration does not suppress a separately evidenced new question.

## Current example and evidence limits

`evidence/scenarios/concurrent-gc/modeling-024.view.json` binds the current candidate SHA and existing lifecycle audit/model source SHAs. It does not invent an inspection-stall event for the Working chat.

The selected `ContinuationVMTransfer` model explicitly assumes compatible VMs and caps generation requests at2. It represents a foreign lease as one boolean; it does not implement actual C frame nesting, multiple callback publications/revocations or all teardown interleavings. This is a declared insufficient-coverage assessment for callback retirement and finite-only assessment for full source refinement, not a checker-derived completeness verdict.

`ForeignPayloadPublication` explicitly excludes allocator/pointer tagging/data races/full C memory semantics and represents one foreign writer. Its integer payload/version projection cannot qualify arbitrary movable C pointer borrowing. The view exposes that coverage review rather than confusing the official rooted-object return control with a general raw-pointer lease theorem.

The empirical-performance option preserves the adverse small-heap parallel pause result. It requests matching baseline/repair observations, not more finite models as a performance proof.

All assessments remain trusted host review statements attached to exact sources. SHA matching establishes source identity, not review truth. Selecting a guidance action reads its Evidence answers; it does not run QNT/Lean, approve a retry or admit source correctness. An actual model experiment still needs a concrete question, current source correspondence, explicit assumptions, positive/negative controls and an already supported authorized Recipe. No new native or Lean execution capability is added here.

## Validation scope

Real Library tests cover current-source binding, provenance withdrawal, explicit refutation vs reported inspection, multiple method options and Action discover/select. They do not establish that this guidance improves Agentic AI task success or token usage; that needs matched real investigation trials. They also do not replace full consumer/current-graph qualification.

Actual final run `.data/modeling-guidance-025-002`:8tests/0skip, parent10.083s under the unchanged15s watchdog, exit0/timeoutfalse/group-quiescent; current Library008. Initial three-test run001 is preserved separately, not combined into final coverage. No production Python inference code or provider binary changed. `git diff --check` passed.
