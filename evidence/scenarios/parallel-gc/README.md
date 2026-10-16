# Parallel GC Repair Review

This is a downstream declarative ASCENT Evidence DSL scenario, not a compiled
Scheme package. Python supplies facts through the Library C ABI; Library-owned
loading and macro expansion execute `define-evidence`, sources, outputs,
relations, joins, negation and aggregation. There are no downstream imports,
exports or compiler tasks. Fragment is unnecessary for these relations.

`facts.json` binds real pinned Gambit baseline and Chez source hashes, the
cached GHC 2008 paper, and actual finite-control receipts. `design.ss` derives
design comparisons, reference requirements, missing Gambit obligations and
model observations/counterexamples. The five obligations include moving-root
retirement, same-candidate native acceptance and matched performance. The
current runtime candidate is intentionally unbound: this scene cannot silently
apply baseline conclusions to a newer overlay.

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
Local run 001 completed in 3.517 seconds under the unchanged 15-second process
cap with no input drift or timeout and a quiescent process group. It used the
existing journal-069-003 sealed Library, not the newly reported producer CI
head. Raw logs and receipt are archived alongside model results. This scenario
is not yet registered in the full current Action Catalog/graph; it is not a
full-consumer or Gambit native qualification.

See `docs/parallel-gc-design-comparison.md` for source positions and performance
tradeoffs. The models and references serve Gambit SMP, multiple-threaded VM and
parallel GC repair, not a ranking of runtimes.
