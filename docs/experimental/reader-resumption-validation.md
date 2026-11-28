# Reader Resumption And Stage-One Handoff Validation

This is research qualification for the [resumption contract](reader-resumption-contract.md)
and [existing handoff](stage-one-handoff-recipe.md), not runtime implementation.
No runtime source, native fixture, bootstrap, stress or native checkpoint was
changed or executed. Historical native progress is neither reset nor advanced.
The [earlier wait/index observations](stage-one-handoff-validation.md) retain
their original hashes; the extended proof context is qualified separately here.

## Bound Inputs

| Input | SHA-256 |
| --- | --- |
| Reader contract | `62ad4fc11ef7c80631e80967f5d5026e4e298e738fd97dd25821ddddccff2315` |
| `gc_table_iteration.qnt` | `70f604d64bdb89eb36638db27fab0f4f2b4710b699135c452b5ccf1757208c19` |
| `predicate_lock_retry_rooting.qnt` | `fb22f40731548dda4816e3611e16c2af0fd8a32035760a8449d595d8c1cff35f` |
| `RuntimeEntryContracts.lean` | `ee016a4ead811b3d21b97ad12c132f9ccdc4b4ef81a4020b770371a64522544c` |
| False-claim controls | `3907143123a5bfbc99c461365ed7ad8112caa97d0d92f153d5ce29d0610b72c4` |
| Replay manifest | `f1498d322624ff1d725a75a5bb33c8c761f75c7197267ca8b069bd1396cef3a4` |
| Wait manifest | `49f1a73e90cf160eaa6c145515f657e971f93f3dde237f7f6436307395ab8f20` |

The manifests bind the pinned reference files and existing Gambit overlay, not
the native owner's newer candidate or an unadopted cache prototype. Scheduling
used the existing host-auto policy: this host exposed 12 processors; controls
ran in pairs with six TLC workers each and positive checks used 12. These are
observed resource choices, not a hardcoded model or workload requirement.

## Inspected Counterexamples

| Query | Actual distinguishing trace |
| --- | --- |
| Return-site free | Five states; the original callback errors, storage is released, and the first explicit resumption reports `badStorage=true` while the saved continuation remains reachable. |
| Untraced retention | Six states; a collection (`epoch=1`) reclaims untraced storage before resumption. Merely retaining raw bytes does not establish collector reachability. |
| Fresh-table substitution | Seven states; current membership becomes `{0,1,2}` while the capture remains `{0,1}`. Resumed delivery includes an uncaptured member without requiring collection. |
| Imported one-shot consumption | Seven states; the second invocation is rejected after the first use consumes `saved`. This contradicts the modeled supported Scheme-only multi-shot contract. |
| Global exactly-once effects | Six states under the correct protocol; one explicit resumption makes `secondVisits=2`, with valid traced storage and no membership violation. This is legal repeated user behavior, not a runtime defect. |

The positive resumption safety and weak-fair completion check passed over
**52 distinct / 88 generated states**. It covers the finite normal/error origin
branches, optional collection and membership growth, two explicit resumptions
and discard. It assumes actual traced reachability and a valid Scheme control
origin. It does not establish real root maps, collector relocation, C weak
memory, arbitrary FFI migration, unlimited re-entry or native reclamation.

The existing capture projection was rechecked at the extended model digest:
**five expected controls**, positive safety/completion **59 distinct / 89
generated states**. The wait/index projection was rechecked with the final
Lean context: **two expected controls**, positive safety/completion **35
distinct / 53 generated states**. Its leaf-owner completion and explicitly
parked participant remain alternative premises, not interchangeable OS waits.

| Existing-verifier receipt in cache | SHA-256 |
| --- | --- |
| `runtime-entry-models/reader-resumption-typed-controls/receipt.json` | `b3bf8685008bab3b487b7dec339ed6d9563399916523846fdd1428998a2ca8e3` |
| `runtime-entry-models/reader-capture-preserved/receipt.json` | `786c117b75d411c371400eba5222a5a7fa727e35c611629ed20c7f099356f7d6` |
| `runtime-entry-models/research-publication-wait/receipt.json` | `779ea0119fc0021c3ce7e6c25ca2083d53d29f1021d1a081be0e2a337521d556` |

All three report stable context, no timeout, native `not-run`, and no runtime or
release admission. Raw outputs stay in `.cache`; their availability is not a
reproducible source dependency. The existing manifests reproduce the campaigns.

## Proof, DSL And Historical Identity Checks

The guarded Lean build and direct check passed with **22 theorem inventories**,
only the established standard axioms and no `sorryAx`. All **12 deliberately
false claims** were rejected, including the claim that replay has no duplicates.
This proves the stated mathematical implications, not their C-source premises.
Observations in `.cache/runtime-entry-formal/run-6larz_pq/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `9ef8ed74f8f3a6a97150e303a38278c2173d3a597cbf12e1f78459c736403b1f` |
| `axioms.json` | `5fa818c2d8cc35b2dc30497ff4a18aa3716e4761e0550b67595c200fdf50e705` |
| `false-claims.json` | `b92234bab0e396cd0006eab7fe0fd1e2e77e761f74ca0e31f8c4298088433d56` |

No guarded observation timed out or left an active process group. The focused
research suite passed **3 tests (5.308 s)**; the unchanged parallel-GC evidence
scenario passed **1 test (0.518 s)**. Source withdrawal/restoration and Session
reuse use the existing Scheme relations. All model scopes remain `partial`,
three native obligations remain missing, and `satisfies=[]`. No production
Python inference, parser, endpoint or workflow was added.

The previous PR's framework CI rejected five frozen traces after their models
were extended: their predecessor source bindings had not been published.
The existing historical registry now binds those exact trace bytes to two
small predecessor QNT sources. Both snapshots match the corresponding original
models at `b67da6262a973a0ae898002d5c7f5be2d8b5a90d` byte-for-byte. The trace hashes
and failure expectations are unchanged. These are durable counterexample source
authorities, not disposable generated checker caches and not current-model
proofs. The existing export check passed **1 test (1.031 s)**; it treats these
five traces as historical rather than current. That other lane's test file is
not part of this research publication.

An initial replay manifest incorrectly supplied a list where the existing
checker expects one initializer per invariant. Loading failed with `TypeError`
before exploration. Splitting the root-retention control into its own named
predicate fixed the configuration without changing the framework or weakening
the checks. This rejection is not a protocol counterexample or successful run.

## Reproduction And Handoff Boundary

```sh
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry-replay.manifest.json --case gc_table_iteration --out .cache/runtime-entry-models/replay-recheck
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case gc_table_iteration --out .cache/runtime-entry-models/capture-recheck
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry-wait.manifest.json --case predicate_lock_retry_rooting --out .cache/runtime-entry-models/wait-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

Use fresh checker output paths and retain rejected attempts. The implementation
owner still needs the whole enabled-caller/effect census, actual binding-to-VM
root and generated-frame correspondence, valid callback/continuation exits,
init/retirement joins, unified repaired producer identity and complete rebuild.
Original native correctness and performance gates remain separate. No research
result here changes a native failure or claims the SMP milestone is complete.
