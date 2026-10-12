# Evidence Investigation For Agentic AI

This real consumer scenario submits its own DSL definitions through Python.
The files in `evidence/dsl/` contain functions, hygienic macros and native
ASCENT expressions, with no Scheme imports, module wrappers or exports.
The consumer does not install Gerbil or maintain a Scheme build configuration.
ASCENT is the Library that owns native expansion, execution and inference.

## Research Question

Given the complete canonical failure inventory, original process outcomes,
receipt hashes, exact JSON pointers, control references and model contracts:
which observations failed, which metadata is absent, and which declared
obligations transitively depend on others?

Strict DENY entries remain distinct from raw observations. Missing identities
stay gaps; different-runtime controls remain recorded references. Answers do
not grant retry, source refinement or authorization.

## Python Entry

`entry.json` names the component manifest, entry, constructor and source bindings.
Python hashes and transports separate exact bytes; it does not concatenate this
scenario, parse rules or implement inference. The Library links the dependency
scope and composes native macros, relations and operators.

```python
catalog = load_component_catalog(
    ROOT / entry['manifest'], entry=entry['entry'],
    constructor=entry['constructor'], trusted=True)
with engine_api() as (engine, backend):
    answers, receipt = evaluate(engine, sources, catalog, entry['queries'])
```

The explicit trust flag authorizes host Scheme code, not a sandbox.
`sources` comes from actual `evidence_index.export()` and the complete inventory.
The constructor uses native recursion, negation, count aggregates, max lattice
and upstream relational projection with real native handles. Fragment is only
an internal composition unit. One retained native session supports repeated
queries, source replacement and withdrawal.

## Verification

`tests/test_evidence_investigation_scenario.py` checks complete input binding,
actual answers, withdrawal of a fixture-hash field, aggregate/lattice decrement,
restoration, retained-owner reuse, independent explanations and rejected
released handles. Explanations preserve native dependencies, generation, full
source rows, receipt hashes, JSON pointers and the explicit per-row-proof gap.
The proof gap does not restrict execution.

The same complete contract inventory also enters `definitions(catalog)`.
`dependency.ss` returns an actual Scheme closure over a retained upstream
operator session; union/join/project/fix derives transitive dependencies.
Repeated replacement, real edge withdrawal and restoration are compared with
the recursive Evidence relation. A finite typed relation/arrow transformer
independently compiles the same inventory. Semantic comparison occurs in
Scheme, not a Python graph algorithm. The owner returns native multi-value
graphs and opaque closure references without requesting a finite projection.
Only the Library internally imports the public higher-order constructors.

The same exact contract edges also enter an upstream Actor Session. A Scheme
closure owns that session and exposes replacement, run, state, cancellation and
close operations through ordinary Python/C ABI value handles. Tests compare its
complete transitive relation against the business rules with 1, 2 and 4 workers,
withdraw a real edge, restore it, explicitly drain/close and reject post-close
requests. This uses no downstream import or compiler. Only the pure positive
dependency subgraph selects Actors; aggregate, negation and lattice rules retain
their original semantics. Correct Actor execution is not a measured speedup.

Historical import-free API045 execution passed with SDK/toolchain hidden:
1 scenario test, no skips, exit 0, no timeout, quiescent process group,
2.939 seconds within the original 15-second budget. The independent 19-test
consumer audit passed in 6.729 seconds / 15 seconds. These are local prepared
build observations, not portable-wheel or whole-consumer admission.

Historical 041 compiled-module receipts remain in `.data/ascent-investigation-041/`;
they do not qualify this corrected interface. Catalog/review/history now use
consumer-owned import-free DSL constructors, but complete production history
and all main-path qualification are separate gates. Caller-owned unlimited
capacity now replaces the old finite default; original finite DENY receipts
remain unchanged. The current modular scenario requires new matching receipts
and cannot reuse API045 as current qualification.
