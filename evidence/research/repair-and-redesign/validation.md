# Repair And Redesign Relation Validation

## Exact Research Input

| Input | SHA-256 |
| --- | --- |
| `facts.json` | `805da79e4f3f7da1aed61d3d34c9a35943119119f29dec1e9222a8f445dea4a5` |
| `tests/test_repair_redesign_evidence.py` | `072552cdab965a0bca2c9e4be40ec879342b11b8accc00f1e28253431b847736` |
| Existing `evidence/scenarios/parallel-gc/design.ss` | `498b644760d58de3c22bbb72e7a3eb3e537e76605ac56f65a79a96b6158e28e9` |
| Existing `evidence/scenarios/parallel-gc/components.json` | `6cb0291e2d4afea0665d5420f7cde7a9331ce77c9e3b0527073ff6981fc7cf2d` |

Command:

```sh
.venv/bin/python -m unittest tests.test_repair_redesign_evidence -v
```

Three tests passed in 6.649 s through the existing native Scheme constructor
`make-parallel-gc-review`. The test checks every declared source hash before and
after evaluation. No production Python inference, new relation implementation,
CLI or registration interface was added.

## Actual Oracles

- All four declared transfer conditions have their source premises. All eight
  composition properties remain explicit gaps: three model-interface gaps and
  five source-composition gaps. These are research interfaces, not eight native
  gate IDs or a revised 9/12 count.
- Current repair and Experimental scopes retain their distinct model locations
  and cannot cross-bind a checked relation from the wrong scope.
- Removing a required source or a current formal check exposes its missing or
  stale binding without deleting any research/native obligation.
- Replacing the current scan-phase check with the historical receipt hash
  produces `model-check-unbound-or-stale`. The older pass is not inherited by
  the revised model.
- Removing the unrelated historical receipt from the query input does not
  invalidate the independently rechecked current relation. History is retained
  for provenance, not made an execution dependency of current evidence.
- Repeating the unchanged native evaluation reuses its result. A synthetic
  correctly scoped binding control still grants no native acceptance credit.
  The real research facts contain no `satisfies` or `composition_binding` rows.

The formal results and preserved typed-set assertion failure are recorded in
[scan-phase validation](../root-registry-retirement/scan-phase-validation.md).
The existing partial coverage declarations remain partial, including the new
global-scan/resume projection's assumed local-root readiness. There is no full
C source refinement, same-slot writer or physical moving-GC proof here.

## Research Decision

The new source combination adds the missing distinction between per-domain
entry ownership and the collective's global-root completion. Gambit already
has GC phase barrier call sites; the useful current question is whether each
supported caller is covered by them. Architecture-disabled dynamic closure
code is counterevidence to selecting a TLS patch merely from a visible TODO.
The expected benefit is avoiding unsupported fixes and narrowing the handoff
Recipe; no runtime speedup or native failure cause is established.

No runtime source, native fixture, current-runtime model algorithm, bootstrap,
native test, dependency pin or another thread's acceptance state changed.
This is direct research evaluation through the existing DSL, not qualification
of a registered Session/Clue entry or the entire framework/CI.
