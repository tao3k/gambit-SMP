# GC Entry And Processor Membership

## Review Before Runtime Changes

The GHC parallel-copying paper discusses a collector that runs with mutators
paused and begins by evacuating roots (section 3.5). Its work-closure protocol
therefore assumes root admission and collector participation already hold.
Our work-closure model inherited that assumption. This new model checks an
earlier boundary, guided by the paper but specified from Gambit's selected
runtime026 source. It does not transplant GHC's scheduler or generations.

- Direction: compose synchronized operations, mutator quiescence, root-copy
  completion and changing processor membership before introducing another
  runtime repair.
- Prior work: `sync_tree_rounds` assumes a fixed population;
  `gc_scan_barrier` abstracts one root-phase frame;
  `vm_resize_rollback` checks failed preparation separately. None closes this
  entry/membership interaction.
- Value: prevent plan capacity from being mistaken for live participants and
  prevent root scanning or Scheme execution from crossing rendezvous early.
- Expected benefit: correctness guidance only; no performance claim.

## Source Correspondence

| Abstract transition | Selected runtime026 source |
| --- | --- |
| Request and rendezvous | `on_all_processors` raises `___INTR_SYNC_OP`; `execute_sync_op_loop` selects a synchronized operation through `barrier_sync_op` |
| Nested collection before growth | `___vm_resize_pstate` may call `___garbage_collect_pstate` before changing `processor_count`; `target_processor_count_` is planned capacity, not the active barrier population |
| Root publication and completion | `garbage_collect_mark_strong_phase` marks continuations/registers/saved roots, then crosses its root-completion `BARRIER()` before `mark_reachable_from_marked` |
| GC completion | The GC phase pipeline crosses barriers before cleanup, resize and allocation-headroom admission |
| Population commit | `OP_SET_PROCESSOR_COUNT` is applied at the tree root after old participants rendezvous; `barrier_sync_op` uses its captured local `n` for the outgoing replies |
| Growth readiness | Processor states are prepared before the count update; new OS threads start afterward, set their processor state and call `execute_sync_op_loop(..., 0)` before running the thunk |
| Shrink retirement | Excluded processors clean up and exit after the count-setting barrier; processor0 joins reclaimed threads |

This is a reviewed correspondence, not a C implementation proof. In particular,
membership temporarily differs from live OS-thread population during resize;
the model allows that intermediate state and prohibits a new GC there. It does
not incorrectly require every committed member to have an OS thread at the
instant `processor_count` changes.

## Model And Results

`gc_sync_membership.qnt` has three possible processors, with both initial
choices: grow2to3 and shrink2to1. Each path runs a nested GC over the old two
participants, performs the population transition, and runs a second GC over
the new population. Prepared, live, parked and joined sets are separate.
Roots may be published before their copy is complete. Entry into scanning
requires completed roots from every admitted participant; GC exit requires
final acknowledgments. New threads must join before Scheme thunk execution.

Quint 0.33.0 / TLC found all four independently injected faults:

| Control | Rejected invariant |
| --- | --- |
| Enter roots before all mutators park | `quiescenceSafe` |
| Scan before every root copy completes | `rootSafe` |
| Use target capacity as current GC population | `membershipSafe` |
| Resume before resize participants join | `startupSafe` |

The positive protocol exhausts **129 distinct / 198 generated states**, depth
44, with zero queued states. Both initial population choices are included.
All five verifier checks are admitted with unchanged model bytes. Receipt:
`evidence/model-results/gc-sync-membership.json`; four digest-bound traces are
under `models/gambit/counterexamples/gc_sync_membership-*.json`.

Attempt001 is retained as a Quint init-action translation denial. Attempt002
actually produces a counterexample, but its receipt is denied because the old
strict parser cannot decode integer sets. Attempt003 uses strict typed set
decoding; sets remain distinct from tuples, duplicate/malformed members are
rejected, and changing cardinality does not alter a state's declared shape.
No denied receipt is rewritten. Original logs containing machine paths remain
under their `.data/` attempt directories, not in public evidence files.

## Composition Contracts And Remaining Work

The model assumes tree rounds and message acquisition are correct, and that
each abstract `finishScan` fulfills work closure. Those contracts reference
`sync_tree_rounds`, `sync_message_acquire` and `gc_work_closure` in the case
manifest. Datalog exports their transitive dependency paths and missing native
adapters. A contract edge records an assumption; it does not prove semantic
composition, source refinement or native acceptance.

The first four-receipt export exposed three dependency edges without designated
receipts, involving `sync_tree_rounds` and `sync_message_acquire`. Their earlier
successes were documented, but original receipts were absent from the retained
cache. Current unchanged model bytes were therefore checked again to recover
binding, rather than promoting prose to proof or repeating denied native runs.
Tree safety and channel-drain properties each exhaust 724 distinct / 1,961
generated states. Message publication's three negative controls are accepted;
its positive exhausts six distinct / nine generated states. Both receipts are
now under `evidence/model-results/`, designated in the case manifest. All six
models in this dependency closure have digest-checked recorded admissions;
the missing-designated-receipt query is empty. This is not executable semantic
refinement of the contracts or complete native acceptance.

Operation-priority/combining arbitration, allocation/setup failures and their
rollback, OS-thread creation/join failures, exact roots/object representations,
C memory ordering and scheduling fairness remain outside this bound. The
root barrier is already present in the selected candidate; this model does not
justify adding another barrier or claiming a new repair. Before a new runtime
patch, bind an actual violated source transition to a model counterexample,
check its failure paths and derive a native regression. Complete bootstrap,
compiled suites and Gerbil build/test are still required for full green.
