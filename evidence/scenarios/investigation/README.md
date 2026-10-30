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

The public Python Evidence API exports `engine_api` and `repository_clues`
from `gambit_smp`. Normal Python introspection exposes their signatures,
Scheme relation schema, slice response and checkpoint contract. The installed
CLI for the same implementation is `gambit-smp trajectory clues`.
Its `--help` exposes the Scheme declaration contract and source relation
signatures. It evaluates caller-authored queries against registered Evidence
and returns source-bound incremental slices; it requires no Context selection.
The interface is documented in
[the framework API](../../../docs/smp-trajectory-application.md#direct-logical-evidence-reads).

## Low-Level Scenario Evaluation

The following is the scenario's whole-view evaluation API, not the scoped
incremental Evidence slice interface. It does not perform anchor selection,
presentation folding or checkpoint comparison.

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

The same complete contract edges enter the maintenance-precompiled transitive
Graph closure through `Engine.core_graph`. Its fixed C ABI owner retains the Core
session; replacement, real edge withdrawal and restoration are compared with
the recursive Evidence relation at 1, 2 and 4 Rayon workers. Python only transports
inputs and compares complete answers; it implements no graph algorithm. Closing
the owner invalidates calls while already-owned result observations are independent.

Runtime ordinary Scheme procedures and mutable closure factories were removed
from the current dependency asset and its declared exports under the explicitly
approved declarative contract. Their exact old files and tests remain in
`evidence/library/compiled-graph-057/contract-history`, not a compatibility path.
The current dependency asset contains only statically lowered rule helpers.
Aggregate, negation, lattice and recorded-only explanation boundaries are unchanged.
This does not claim the old arbitrary-procedure or Actor API was implemented in
the new backend, nor that correctness controls establish a performance gain.

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
