# SMP retirement research: repository publication

2026-10-22. Work item repair-9-12. Cumulative acceptance remains **8/12**.

Earlier audit output was durable locally but ignored by Git. This publication copies the exact audited research/model bytes into repository docs and models; raw logs and process receipts retain their original audit paths. It does not implement runtime repairs, modify the implementation worker, change budgets, or qualify a native producer. Earlier documents describe their original audit-only creation; the table below records their subsequent repository publication.

| Repository document | Contents |
| --- | --- |
| [Twelve-gate matrix](smp-twelve-gate-research-map.md) | All twelve contracts, remaining four candidates, and regression obligations for the first eight. |
| [Source correspondence](smp-retirement-source-correspondence.md) | Functions, proposed fields, call order and eighteen last-consumer classes. |
| [Pre-exit frontier](smp-pre-exit-retirement.md) | Actual shrink/GC/callback chain and pre-exit model, including the retained normal-path timeout. |
| [Trade-off and initial models](smp-retirement-tradeoff-correspondence.md) | Pinned Chez/OCaml mechanisms, explicit assumptions and earlier failed/timeout checks. |

The copied QNT files are research models under models/gambit. They have not become runtime acceptance tests or a checked C refinement merely by being versionable. Original filenames/module names and bytes are preserved so the model hashes still match their audit receipts.

Known results: initial handoff model has two retained 30-second timeouts; carrier mechanism passes its bounded checks; twelve-gate composition has two positive checks and four decoded mutation controls; last-consumer model has one positive and three decoded mutation controls. The pre-exit successor has two positive passes, three decoded mutation controls and two actual trajectory tests; its complete current-normal-path check **timed out at 30.511 seconds**, so aggregate acceptance is false. These results do not close gates 9 or 10. Pending preparation/rollback work must add its own source-bound results.

Original receipts and model identities:

| Published file | SHA-256 | Original retained source |
| --- | --- | --- |
| `docs/smp-retirement-tradeoff-correspondence.md` | `bb95ed648fed8ebcbe1bb615e3f18b653f001bbd3bea21586f4ca6cf516c2c13` | `.cache/tasks/repair-9-12/processes/audit/runs/d7e388fc67c74c11960755b9799d89aa/outputs/retirement-tradeoff-correspondence/source-state-last-consumer-model-tradeoff.md` |
| `docs/smp-twelve-gate-research-map.md` | `4bc8e9143a5ba708e73d80dabf5d14488892cfea78e44593609232573870ba19` | `.cache/tasks/repair-9-12/processes/audit/runs/479b70fffe794f38acdb789dc97facbc/outputs/twelve-gate-correspondence/twelve-gate-source-state-consumer-model.md` |
| `docs/smp-retirement-source-correspondence.md` | `c544303f94f48262e7ea4074c552764dceb421ff7a5cd092a794d649b514b8da` | `.cache/tasks/repair-9-12/processes/audit/runs/461e1d0006824db1bd5dcda6c22ee433/outputs/gates-nine-ten-design-closeout/gates-nine-ten-functions-fields-last-consumers.md` |
| `docs/smp-pre-exit-retirement.md` | `ab21a83bb03f4595d95e35dbae9b44ff2d3f46bc1a41f7c94b6740dedea7772c` | `.cache/tasks/repair-9-12/processes/audit/runs/4d9fd25e72894e4888086712db4e6af6/outputs/pre-exit-retirement-study/pre-exit-join-callback-root-frontier.md` |
| `models/gambit/retirement_handoff_refinement.qnt` | `80360c10d7b5a9de520f02f7a103234d52958049722477a8148489e8e2d31aac` | `.cache/tasks/repair-9-12/processes/audit/runs/d80b558a9c124df1807b3c92a289aa9f/outputs/retirement-handoff-refinement/retirement_handoff_refinement.qnt` |
| `models/gambit/retirement_carrier_handoff.qnt` | `e14e0f5abf01d6f856cba3397cabe74394b439d84485f7e11eb85490906a92eb` | `.cache/tasks/repair-9-12/processes/audit/runs/65e0a09a21bf43eba7e517315127fb51/outputs/retirement-carrier-handoff/retirement_carrier_handoff.qnt` |
| `models/gambit/twelve_gate_retirement_composition.qnt` | `4104ddced929d4ea0ca0c95ae06fd87d5bf3cee9d39616a37365b13f63ea684f` | `.cache/tasks/repair-9-12/processes/audit/runs/55da19bbe05b4980ab8adaa827a0a5b2/outputs/twelve-gate-small-refactor/twelve_gate_retirement_composition.qnt` |
| `models/gambit/retirement_last_consumers.qnt` | `e686ee5bc6d6a7f46999f3455b88ba980f7afcae8e4477ad2435955abe53acf4` | `.cache/tasks/repair-9-12/processes/audit/runs/f6caf05f9f114cedad8023d580fced77/outputs/gates-nine-ten-source-correspondence/retirement_last_consumers.qnt` |
| `models/gambit/retirement_pre_exit.qnt` | `b90b9a862a02b58aa03cc1ca2a634669e21ee5779556f28535202a4fafb2f7d2` | `.cache/tasks/repair-9-12/processes/audit/runs/4d9fd25e72894e4888086712db4e6af6/outputs/pre-exit-retirement-study/retirement_pre_exit.qnt` |


## Preparation-phase successor

[Preparation-phase function/field/state design](smp-retirement-prepare-phase.md) and [its QNT source](../models/gambit/retirement_prepare_phase.qnt) now record nested operation election, callback failure containment and continuous root coverage. The detailed result table retains every timeout/failure; no native gate changes. Source/model hashes and timing provenance are in `.cache/tasks/repair-9-12/processes/audit/runs/5cb2056899764ee59b9b1278db778b80/outputs/retirement-prepare-phase/receipt.json`.


## Versionable validation summary

The [compact validation summary](../evidence/research/smp-retirement-study/validation-summary.json) retains original model/receipt hashes, per-check outcomes, decoded mutation witnesses and the normal-path timing comparison in the repository. The original normal timeout remains; the same model, compiled TLA/config artifacts, JVM/jar and worker/heap configuration passed the diagnostic in 4.334 seconds within the same combined 30-second cap. The preparation model has three positive passes, seven decoded controls and two actual trajectory passes. Earlier timeout cases and the empty-selection test correction remain explicit. These are research results, not a change from native acceptance 8/12.
