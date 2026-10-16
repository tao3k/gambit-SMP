# Repeated Source Checkpoint Optimization

## Implementation

`recipes.FingerprintPlan` snapshots the bound path/SHA pairs after input and
tool inventory collection. Recipe checkpoints reuse only this path metadata.
Every checkpoint still reads every file and computes SHA-256. No digest, mtime,
size, or inode cache establishes currentness. Missing files still fail closed;
a digest mismatch does not skip the remaining paths in that plan.

The existing initial inventory discovery, source preparation, observed-input
checks, published tree checks, final checks, admission rules and budgets remain
in place. This change does not add an execution capability or a Python reasoner.
It does not change the existing fixed-inventory semantics into tree discovery.

## Matched Measurement

Local raw files: `.data/framework-fingerprint-plan-001`.
Both variants ran in the same process with the same 4,688-path manifest and
expected hashes. Three alternating-order pairs each performed 17 complete
checkpoints: 239,088 byte reads and SHA computations per variant. The baseline
uses the original `fingerprints(Path(name) for name in expected) == expected`;
the candidate uses the prepared plan. Plan construction is outside the repeated
checkpoint interval, as it is in the recipe; whole-process time includes it.

| Pair | Baseline Seconds | Candidate Seconds |
| --- | ---: | ---: |
| 0 | 2.595289 | 2.014718 |
| 1 | 2.546066 | 1.858832 |
| 2 | 2.470126 | 1.857694 |
| Median | 2.546066 | 1.858832 |

The median checkpoint cost decreased by approximately 27%. Parent exit was 0,
timeout false, group quiescent true, 13.409476 seconds under the 90-second
matched-performance ceiling. These are checkpoint measurements, not an
end-to-end research, cold-start, Actor or consumer speedup.

The preceding cProfile diagnostic retained under
`.data/chez-framework-integrity-profile-001` measured 17 baseline checkpoints
at 4.026425 seconds with profiling instrumentation. Do not compare that number
against the unprofiled candidate as a speedup.

## Regression Boundary

`.data/framework-fingerprint-tests-001` records all 58 recipe/native-recipe
tests passing in 0.582758 parent seconds under 15 seconds, without timeout and
with process-group quiescence. New controls exercise equal-size content change
with restored mtime, restored bytes, deletion, expected-map mutation, and full
plan traversal after a mismatch. Existing recipe drift/STALE tests remain.

These tests are not complete consumer qualification. Latest Library packaging,
fixed source/archive identity, a matching new research seal, full consumer
regression and a CURRENT information graph remain required. Historical Library
receipts cannot qualify that new candidate. Loading and expansion costs are
not closed by this checkpoint optimization.

## Latest Library Integration

The new UF Library source archive is bound by SHA-256
`da15ff83ae841371ac802dce770fc4cabd9cdc29a2bbb6d7e66525571c6f7fa2`.
The current-framework seal `.data/research-engine-fingerprint-uf-001` has engine
ID `ba611348c9e46fe58bca6e89180e4509abee5c45ac31ba02fab20506ddbbd205`.
Its first full consumer run, `.data/framework-fingerprint-uf-consumers-001`,
completed 1,093 tests with zero skips, zero assertion failures and two errors.
Parent exit was 2, timeout false, reaped and quiescent, 241.694102/300 seconds;
the complete input inventory was stable. The embedded 105-test sealed review
passed in 54.904545/60 seconds. The whole run remains DENY.

Both errors reject a historical source-unit receipt whose recorded
`recipes.py` SHA differs from the current optimization. No source check was
weakened. The existing source-schedule Recipe was freshly run under this seal:
`.data/source-schedule-fingerprint-uf-001`, 6.957272/90 seconds, all eight
controls and terminal inference PASS. Its complete raw source-component
observations are archived under
`evidence/source-results/fixtures/sync-retirement-fingerprint-uf-001`.
The current correspondence selects that new receipt; the old 038 receipt and
its exact SHA are retained in the historical list. This is mock component
evidence, not a Gambit runtime or source-refinement result. A new complete
consumer run and CURRENT graph are still necessary after this causal change.
