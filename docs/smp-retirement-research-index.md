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


## Two donors and repeated GC

The [multi-donor study](smp-retirement-multi-donor.md), [QNT model](../models/gambit/retirement_multi_donor.qnt) and [validation](../evidence/research/smp-retirement-study/multi-donor-validation.json) add two positive safety/liveness passes, seven decoded mutation controls and one explicit trajectory. A Ready donor stays available while another fails; a second GC updates donor and error roots before current-epoch abort. Callback/global closure/common completion are distinct. Source refinement and complete native gates remain open; acceptance stays 8/12.


## Queue, epoch and typed-root implementation contract

The [gate-9 implementation contract](smp-retirement-implementation-contract.md), [two-epoch QNT](../models/gambit/retirement_epoch_queue_roots.qnt) and [validation](../evidence/research/smp-retirement-study/epoch-queue-roots-validation.json) specify local callback completion, global preparation closure and common completion. Prefer one-node pop with the untouched suffix retained in the existing queue. Two positive checks, ten decoded mutations and two explicit trajectories pass. Will/testator strongification, unscanned RC payloads, stale real prior-epoch acks and unsafe suffix reuse are rejected. Four minimal edit surfaces and unresolved callback/root/native premises are explicit; acceptance remains 8/12.


## Unified mechanism model and implementation handoff

The [integrated plan](smp-retirement-integrated-plan.md), [single QNT](../models/gambit/retirement_integrated.qnt) and [validation](../evidence/research/smp-retirement-study/integrated-validation.json) now combine P0/two donors, two GC rounds per epoch, two epochs, queue disposition and typed root coverage in one state machine. Three safety/conditional-completion passes, seventeen decoded controls and two named trajectories pass under existing caps. Four function-level implementation surfaces, call order and remaining sufficiency blockers are explicit. The earlier integrated run is retained with its narrower will-owner assumption; no native gate is upgraded.


## Actual C work closure and caller-root refinement

The [C handoff audit](smp-retirement-c-handoff.md), [unified-model successor](../models/gambit/retirement_c_handoff.qnt) and [validation](../evidence/research/smp-retirement-study/c-handoff-validation.json) distinguish encoded immediate errors, cross-GC saved error roots, normal Scheme PSR1 installation, explicitly rooted external C callers and unsupported raw/catcher-only retention. Work closure includes late publication, scanner return and the full GC epilogue; typed still/RC/frame/will ownership is explicit. Five TLC positives and twenty-six decoded controls pass. Three default Rust trajectory calls fail at evaluator recursion parsing and remain recorded; the exact same model passes three actual named trajectories on the installed TypeScript evaluator under unchanged caps. This is source/finite evidence, not native admission; acceptance stays 8/12.


## Donor Scheme execution ownership and private work

The [donor ownership audit](smp-retirement-donor-ownership.md), [unified successor](../models/gambit/retirement_donor_ownership.qnt), [importing trajectory tests](../models/gambit/retirement_donor_ownership_tests.qnt) and [validation](../evidence/research/smp-retirement-study/donor-ownership-validation.json) distinguish active GC-visible frames, stack-backed thread-save, typed captured-continuation materialization, private incomplete chunks and unique scheduler ownership. Five positives, 32 decoded controls and three trajectories pass under original limits. Existing scanners/save/restore can be reused; a concrete Scheme-safe-point/C-collective scheduler publication/abort protocol remains the largest source-refinement blocker. The interrupted output-truncated batch and its reconciliation remain explicit; no runtime/framework change or native admission.


## Scheme safe-point and C collective protocol

The [function-level protocol](smp-retirement-safe-point-protocol.md), [unified QNT](../models/gambit/retirement_safe_point.qnt), [trajectory module](../models/gambit/retirement_safe_point_tests.qnt) and [validation](../evidence/research/smp-retirement-study/safe-point-validation.json) replace the precommit runnable-publication shortcut with a rooted parked owner through C3, followed by exactly one survivor activation or original-owner restore. Five positives, 39 decoded controls and three trajectories pass (48 effective checks). A third helper GC uses old membership on abort and reduced membership on success. P0/direct-C helper entry, opcode wait/GC priority, queue critical-section refinement and postcommit faults remain implementation blockers; native acceptance remains 8/12.


## P0 raw c-lambda and direct-C bridge refinement

The [P0 bridge study](smp-retirement-p0-completion-bridge.md), [unified QNT](../models/gambit/retirement_p0_bridge.qnt) and [validation](../evidence/research/smp-retirement-study/p0-bridge-validation.json) identify the actual ___call/return_to_c/marker control mechanism and shared current_vm_resize_admitted placement, including shutdown bypass of the public wrapper. Eight positives, 51 decoded controls, five trajectories and typecheck pass (65 checks). Scheme-caught errors must match-return before retry; raw C unwind has no normal-frame restoration guarantee. P already fixes the B marker-proc root TODO. Prepared direct-C context, helper registration/pinning, exceptional disposition and native acceptance remain open; progress remains 8/12.


## Shutdown context and helper registration

The [shutdown context study](smp-retirement-shutdown-context.md), [unified QNT](../models/gambit/retirement_shutdown_bridge.qnt) and [validation](../evidence/research/smp-retirement-study/shutdown-context-validation.json) distinguish setup admission, Scheme/helper readiness and matching host return. `(exit 0)` can use raw unwind; ___run lacks an all-path marker finalizer. Proposed per-VM scanned slot-2 registration, P0 execution claims, explicit-migration exclusion and retained raw-context disposition are source-mapped. Eleven positives (eight normal, one opaque-suffix retention, two unsafe-context retentions), 63 decoded controls, eight trajectories and typecheck pass: 83 checks. Retention is not recovery; native acceptance remains 8/12.


## Pre-exit landing pad and original TFIB failure frontier

The [landing-pad source contract](smp-retirement-exit-landing.md), [experimental unified QNT](../models/gambit/retirement_exit_landing.qnt) and [validation summary](../evidence/research/smp-retirement-study/exit-landing-validation.json) add worker-origin intent, callback failure/reentrancy and per-invocation marker disposition. Typecheck and 12 explicitly selected TypeScript trajectories pass. TLC never starts because the unchanged compiler RPC string limit is exceeded; ten planned positives and nineteen negative initializers are not exhaustively validated. Previous 83-check evidence remains attached to its earlier hash.

The [repair-9 TFIB investigation](smp-repair9-tfib-sigsegv.md) records the user-reported original `(go 15 5000)` SIGSEGV separately from the subsequent interrupt2 timeout and retirement design. All 21 locked vector-inc candidate source files were reconstructed and hash-checked offline. Static normal-completion counts and the creation/join/wakeup/save/restore last-consumer table narrow the investigation; missing crashing-binary/PC evidence still prevents causal attribution. No runtime edit, native run, peer operation or gate upgrade; native acceptance remains 8/12.


## Verified TFIB crash and finite GC/handoff envelope

The [binary/crash/source study](smp-repair9-tfib-crash-binding.md), [QNT model](../models/gambit/tfib_gc_handoff.qnt), [binary binding](../evidence/research/smp-retirement-study/tfib-crash-binding.json) and [validation](../evidence/research/smp-retirement-study/tfib-gc-model-validation.json) bind source-core build-4 gsi 5620dd70… to the existing mark_array +104 crash by SHA/UUID/PID/parent/time. Correct generated defaults, scalar F64 dispatch, early forwarding versus copy readiness, root-copy/FIFO barriers and frame-map routes are distinguished. Nineteen checks pass: typecheck, two positives, twelve decoded controls and four trajectories. First corrupting writer/native source refinement and large shutdown-model composition remain open; no native run or gate upgrade, still 8/12.
