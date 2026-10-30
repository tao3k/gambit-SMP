# Parallel GC Repair Review

This is a downstream declarative ASCENT Evidence DSL scenario, not a compiled
Scheme package. Python transports facts to the installed ASCENT Library; Library-owned
loading and macro expansion execute `define-evidence`, sources, outputs,
relations, joins, negation and aggregation. There are no downstream imports,
exports or compiler tasks. Fragment is unnecessary for these relations.

`facts.json` binds real pinned Gambit baseline and Chez source hashes, the
versioned GHC 2008 analysis notes (PDF identity remains in `papers.lock.json`),
OCaml domain/blocking source, Chez activation/destruction source, and actual
finite-control receipts. `design.ss` derives
design comparisons, reference requirements, missing Gambit obligations and
model observations/counterexamples. The five obligations include moving-root
retirement, same-candidate native acceptance and matched performance. The
current runtime candidate is intentionally unbound: this scene cannot silently
apply baseline conclusions to a newer overlay.

`transfer_condition`, `source_section` and `model_scope` extend this same
declarative scenario, not a second registry or workflow. `transfer_evidence`
joins both source identities/sections, a transfer premise and an existing
model's digest/coverage/gap. The five current chains cover backup service,
inactive roots, retirement work, retained descriptors and foreign reentry.
All five are partial correspondence, not an executable refinement proof.
`transfer_gap` exposes their known omissions. `transfer_unbound` reports missing
sections, source observations or model scope; an empty supported-evidence slice
therefore cannot be read as a closed obligation. No relation produces an
action or derives `satisfies` from this reference research.

`transfer_premise` adds supporting source findings and remaining applicability
conditions to the same chains. `transfer_premise_evidence` expands them with
source identity/section provenance; missing supporting sources/sections also
produce `transfer_unbound`. A surviving core comparison does not hide a missing
premise, and a source finding is not a verified runtime contract. See
[`Experimental transfer applicability`](../../../docs/experimental/transfer-applicability.md)
for bounded adaptation versus separate Experimental milestone boundaries.
The [stage-one review](../../../docs/stage-one-refactor-review.md) supplies
source-bound scope, benefit, cost and acceptance decisions through those same
premise relations. Deferred/conditional refactor descriptions are not selected
actions, newly proved models or native repairs.

`satisfies` is an explicit external evidence boundary. Neither a reference
design nor a finite control derives it. Its rows require independent
same-candidate admission; this scenario supplies none. It does not grant
authorization, retry eligibility, source correctness or performance acceptance.

Run the actual consumer test with an identity-bound installed ASCENT API:

```sh
python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

The test validates source bytes and selected recorded control identities,
executes the real DSL, reuses the session, withdraws/restores Chez provenance,
and checks independent explanation ownership and closed-session rejection.
The extended test also withdraws OCaml/Gambit source, a reference section and a
model binding, checking that unsupported chains disappear and explicit unknowns
remain; restoration recovers the original answers in the same Session.

Historical local run 001 completed in 3.517 seconds under the unchanged 15-second process
cap with no input drift or timeout and a quiescent process group. It used the
existing journal-069-003 sealed Library, not the newly reported producer CI
head. Raw logs and receipt are archived alongside model results. This scenario
is not yet registered in the full current Action Catalog/graph; it is not a
full-consumer or Gambit native qualification.

See `docs/parallel-gc-design-comparison.md` for source positions and performance
tradeoffs. The models and references serve Gambit SMP, multiple-threaded VM and
parallel GC repair, not a ranking of runtimes.
The expanded research interpretation is in
[`docs/experimental/smp-design-foundations.md`](../../../docs/experimental/smp-design-foundations.md).

`runtime-entry-facts.json` reuses this same registered `design.ss` and Session
for two additional Experimental research slices: runtime-shared metadata and
host execution/lifetime authority. `runtime-entry.manifest.json` uses the
existing verifier for their missing reservation and entry contracts. No new
DSL, Python inference or runtime admission is added. The focused consumer is
`test_runtime_entry_formal.py`; its withdrawn-source checks preserve explicit
unknowns and its Lean checks use the guarded process runner. The
[audit and model index](../../../docs/experimental/runtime-entry-contracts.md)
distinguishes the baseline source, current overlay review, reused models and
Stage-One versus Stage-Two scope.
