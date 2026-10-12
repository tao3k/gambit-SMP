# Module Initialization Ownership Audit

## Current Source Boundary

Authority: pinned `vendor/gambit` plus the checked-cleanup candidate source lock.
The audit uses its reproduced `setup.c`, `mem.c`, `setup.h` and `_thread.scm`,
not an unrelated historical build tree. No runtime code is changed here.

The manual's C-interface section documents setup before calling Scheme and
cleanup before process exit. It does not promise repeated global setup. Keep the
observed second-setup crash, but do not invent a repeated-generation requirement
or classify its complete reconstruction as the only acceptable API design.
Multiple VMs inside one global runtime are a separate explicit feature.

## Source-Derived Design Constraints

| Path | Fact | Consequence / Unclosed Condition |
| --- | --- | --- |
| `setup.c:setup_module_fixup` | DONE is set before metadata validation and fallible preparation; three exact-source retry controls fail. | Separate exclusive ownership, readiness and retained error; clearing DONE alone is insufficient after partial rewriting. |
| `setup.c:___os_load_object_file` | Linkfile loaded marker is set after a failing `setup_modules` result too. | Determine whether it quarantines unsafe reload; preserve original failure semantics rather than merely removing the marker. |
| `_module.scm:##get-module-from-file`, `_eval.scm:##load-object-file` | Inspected calls invoke the C primitive without proving cross-VM serialization. | Audit callers/entry discipline before claiming the hypothetical overlapping-reader schedule is reachable. |
| `mem.c:___alloc_scmobj` | NULL processor selects permanent allocation. | Do not model these calls as ordinary processor moving-heap allocation that necessarily requests GC. |
| `mem.c:alloc_mem_aligned_perm` | Fast path reads and writes global `mem.palloc_ptr` without a local lock in that function. | A per-module owner alone does not establish serialization of allocation from different modules; caller-side serialization is still an open premise. This is not a native-observed collision. |
| `mem.c:___make_global_var` | Permanent allocation precedes `___glo_list_add`; symbol global-field assignment follows it. | Existing list locking does not by itself establish the entire allocation/find/create/publication transaction. Audit symbol ownership and duplicate creation. |
| `mem.c:___glo_list_add` | Current candidate holds `vm_list_mut` while ensuring live VM segments and publishing the count. | A new loader lock needs a proven lock order with VM creation/retirement; it must not imply a reverse nested acquisition. |
| `_thread.scm:##lock-scheduler-object-with-sync-participation!` | Failed try-lock services only pending synchronous operations and then retries. | Reuse the verified participation requirement; do not blindly transplant a Scheme helper into a C loader with different root/ownership constraints. |
| `setup.h:service_sync_op`, `setup.c:service_sync_op` | Native sync-only entry executes the synchronous-operation loop. | Establish which roots and locks remain live across the call before using it in a wait loop. |

## Design Review Outcome

The next protocol must address shared runtime metadata, not just a mutex on one
module descriptor. Compare a globally serialized metadata transaction with
separately synchronized allocator/intern/global publication. Evaluate both with
actual VM-list nesting, initialization failure ownership and collective-wait
participation. Neither design is selected, implemented or performance-qualified.

Paper accounting principles guide claims about work and drain; they do not make
the permanent allocator's caller discipline or C memory ordering correct. The
existing module publication model assumes an exclusive owner and abstract payload
preparation; this audit exposes the source conditions still missing from that
abstraction. Do not run a native race campaign before modeling and establishing
the corresponding admitted callers.

## Datalog Registration Closure

Twelve recent protocol bundles were absent from the global registry. They are
now registered with their original source-bound receipts. This includes the
`current_processor_gc_wait` and `scheduler_retry_gc_participation` parents of
the shared GC compositions. No composition edge was removed. The actual global
collector returns 79 bundles, 908 bound inputs, 84 models, 81 checked models,
105 composition edges and 305 open obligations. The union with canonical
`models/gambit/cases.json` has no unknown composition target.

These counts are input-collection evidence, not a completed ASCENT export,
whole-runtime correctness or Green admission. Three unqualified models and all
open obligations remain explicit. The downstream owner was notified of the
exact registry hash for fresh consumption-path checks. Twenty-six protocol
evidence tests pass; no Python framework files were edited.
