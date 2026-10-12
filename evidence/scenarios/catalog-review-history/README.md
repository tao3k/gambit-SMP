# Catalog, Review And History

This scenario uses the actual complete Evidence inventory, failure receipts,
current source bindings and declared model dependencies. It is not the
left/right scope fixture. `scenario.json` selects the three production entries
in the small manifest at `evidence/dsl/components.json`.

## Definition Modules

- Catalog declarations define the relation contracts once. Report rules derive
  missing snapshots and report/model dependencies. Observation rules classify
  actual exits, signals and timeouts and retain missing metadata. Protocol rules
  derive transitive contracts, open obligations and missing recorded checks.
- Review declarations define candidate, receipt, source and premise contracts.
  Receipt rules reject stale inputs, missing dependencies and cycles. Decision
  rules retain unchanged failures, missing causes and missing premises.
- History declarations define previous/current rows and individual source
  bindings. Result rules derive added/removed/retained answers. Source rules
  derive added/removed/changed paths without folding the inventory into a hash.

Each entry is a declarative `define-evidence` form. `sources` declares the
relations that may receive caller facts; `outputs` declares public result
bindings. Ordinary upstream `relation`, `<--`, negation, aggregates, lattices
and hygienic macros retain their execution semantics. History expresses its
relations and rules directly, without `.ref` or hand-built Programs:

```scheme
((added Q R) <-- (current_row Q R) (not (previous_row Q R)))
((removed Q R) <-- (previous_row Q R) (not (current_row Q R)))
((retained Q R) <-- (current_row Q R) (previous_row Q R))
```

Catalog retains independent report/observation/protocol rule groups through
upstream `include`; review retains its receipt-closure component. Fragment
values are used only for those reusable groups. History has no Fragment layer.
Previous declaration-only and single-use rule wrappers are preserved byte for
byte under `tests/fixtures/evidence-dsl-previous`, not presented as the scenario.
The Library links the manifest dependencies; no Python rule interpreter or
dependency resolver is introduced. The downstream definitions contain no
`import`, `module`, `export`, package manifest or compile task.

## Actual Consumer Route

Python `load_component_catalog` transports the manifest and exact source bytes
to the ASCENT Library C ABI. `evidence_index`, `ascent_review` and
`reasoning_history` use those entries. The complete manifest inventory, including
unselected definitions, is individually hash-bound; only the selected native
dependency closure is expanded. This is selective expansion, not lazy file IO.

The underlying Library is not restricted to this table-oriented adapter.
For example, a consumer transports these same assets directly through Python:

```python
import json
from pathlib import Path
from ascent_engine import Engine

directory = Path("evidence/dsl")
manifest = json.loads((directory / "components.json").read_text())
sources = {item["source"]: (directory / item["source"]).read_text()
           for item in manifest["components"]}
with Engine() as library:
    with library.evidence_components(manifest, sources, "catalog", "make-catalog",
                                     trusted=True) as session:
        session.replace(current_facts)
        observation = session.run(queries=["observed_gap", "contract_path"])
        with session.result(observation) as result:
            gaps = result.rows("observed_gap")
```

`current_facts` contains validated original observations; it is not generated
by an inference implementation in Python. The project adapter additionally
binds the complete source and artifact inventory before and after execution.
General `library.components(...).call(...)` and owned values remain available
for ordinary exported functions, constructors, closures and operators. The
relational session is a convenience for this workflow, not the DSL boundary.

The investigation entry in the same manifest already uses hygienic macros,
native relational projection, recursion, negation, count aggregates and a max
lattice over the actual failure inventory. Its independent scenario exercises
those capabilities without introducing Scheme imports or Compile downstream.

`tests/test_evidence_dsl_mainpaths.py` runs the complete catalog and real review
facts, compares all answers with the previous definitions, then replaces,
withdraws and restores actual catalog answer/source tuples in a retained
history session. Historical original receipts and logs are not rewritten.

Native result execution is separate from explanation availability. Recorded
dependencies and missing premises are not per-row proofs, causal admission,
retry eligibility or execution authorization. Default fact capacity remains
unlimited; explicit caller limits and original execution-time budgets remain.

## Qualification Boundary

Scope fixtures now live in `tests/fixtures/components`. Their pass cannot
qualify this scenario. This refactoring still needs matching current Library
and consumer receipts, complete regressions, a current full graph and matched
performance evidence before whole-consumer completion can be claimed.
