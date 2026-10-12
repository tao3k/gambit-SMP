# QNT And Lean Shared Driver Contract

## Ownership And Scope

Both backends must enter through the existing ASCENT Python driver. There is
no second orchestration framework, independent admission graph or rewritten
GC. QNT retains protocol exploration and counterexamples. Lean supplements
parameterized invariants, explicit refinement obligations and abstract work
bounds that have not been established by finite-instance checking.

This document is a design requirement, not an implemented Lean integration or
a completed proof. No Lean dependency or backend has been admitted yet.

The Lean asset declares `LeanPoo` as an immutable Git dependency in
`models/gambit/lean/lakefile.toml`, not a local checkout or floating branch.
It imports `LeanPoo.Functional.TransformationResources` and reuses resource
composition rather than duplicating that algebra. Configuration regression
checks live in `tests/test_lean_dependency_contract.py`; these do not elaborate
Lean or admit proofs. The shared driver must additionally bind the resolved
Lake manifest, transitive import closure and theorem axiom inventory.

## Common Evidence Boundary

Each check must bind the same requirement ID and source authority: pinned
submodule, source lock, model dependencies, assumptions and exact tool version.
The existing driver owns bounded execution, host-derived shared CPU capacity,
exit propagation, timeout retention and durable portable receipts. ASCENT
relates checks to requirements and reports unresolved obligations; it does not
infer a proof from a successful process exit.

QNT outcomes retain the explored domain, backend bounds, fairness assumptions
and typed counterexample. Lean outcomes retain the theorem statement, imports,
toolchain and axiom inventory. Incomplete proofs, `sorry`/admitted propositions,
unbound dependencies and assumed desired conclusions cannot qualify a result.
An axiom inventory is necessary but does not establish faithful source modeling.

Cross-backend correspondence must itself be explicit: equal requirement names
do not prove that the two transition definitions agree. A QNT counterexample
must remain a failure until its assumptions or implementation are resolved;
a Lean theorem cannot silently override it.

## First Complementary Obligation

Start with work accounting and safe termination: queued, active, private and
in-flight publication work must all be represented before declaring quiescence.
Generalization over processor and heap populations must state finite-resource,
primitive-progress and scheduler assumptions. Work bounds count operations,
not macOS elapsed time or guaranteed linear speedup.

Qualification still requires actual source-bound fault controls, complete
native tests, bootstrap and Gerbil correctness/performance. Model and proof
results are complementary inputs to that acceptance, never replacements.
