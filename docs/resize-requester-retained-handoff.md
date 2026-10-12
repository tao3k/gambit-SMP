# Resize Requester Retained Handoff

## Source And Observation Boundary

The candidate is reproducible from `vendor/gambit` at
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, the cumulative patch
`patches/fixtures/resize-requester-retained-handoff.patch`, and
`evidence/fixtures/resize-requester-retained-handoff/source.lock.json`.
All 18 locked files were independently reconstructed from Git and verified
against their base and candidate hashes. No cache tree is source authority.

The SMP Scheme entry migrates a nonzero requester to retained P0 before the
native resize. Migration acquires the destination through the sync-aware lock
helper before clearing the donor's current-thread root. The non-SMP entry
remains an alias of the raw primitive. This is not a Darwin-only correctness
claim: the retirement protocol is shared by SMP platforms.

GNU GCC incremental core build passed in 10.945 seconds. It is not a fresh
two-pass bootstrap. Durable receipts are in
`evidence/source-results/fixtures/resize-requester-retained-handoff/`.

| Local native observation | Seconds | Result |
| --- | --- | --- |
| Compiled migration target | 0.470 | Pass |
| Compiled strict interrupt delivery | 0.463 / 0.020 / 0.017 | Three passes |
| Original interpreted still reuse | 0.491 / 0.040 / 0.043 | Three passes |
| Original interpreted resize/GC lifecycle | 0.050 / 0.049 / 0.058 | Three passes |
| Original compiled resize/GC lifecycle | 0.647 / 0.045 / 0.051 | Three passes |
| Mixed-key GC | 0.045 | Pass |

These are selected **observations**, not sealed Recipe admission, full native
qualification, Gerbil acceptance, or performance measurements. The original
fixtures were not weakened or pinned to hide requester retirement. Process
budgets remain 30 seconds, fixture compilation 60 seconds and core build 180
seconds. Capacity is host-selected, not a fixed processor count.

The compiled lifecycle observation is separately archived as
`compiled-lifecycle-observation.json`; compilation took 1.033 seconds. Both
runtime identity and fixture hash were checked before and after execution.

## Model And Remaining Protocol Work

The one-request model `resize_requester_retained_handoff.qnt` reproduces the
old lost-requester counterexample and checks save/publish/resume-before-resize
with exact terminal status delivery. Its finite result does not establish
concurrent resize correctness or physical root preservation.

Source inspection still permits another P0 resize coordinator to retire a
processor whose requester has not yet resumed on P0. Retirement calls
`___thread_exit` without draining arbitrary running or queued Scheme threads.
A mutex acquired after migration cannot protect the migration preceding it.
Waiting for P0 handoff completion inside the native collective is also
insufficient: P0 cannot schedule the handoff while participating in that wait.

`resize_concurrent_handoff_drain.qnt` therefore tests an explicit design
obligation: close admission, drain already-admitted handoffs while scheduling
is possible, then enter the collective. This abstraction is **not implemented**
by the current source candidate. Arbitrary active/queued/pinned threads,
multiple resize epochs, cancellation, failed joins, direct foreign C entry,
invalid-argument validation ordering, and lock-error unwinding remain open.

TLC reproduced the concurrent lost-requester counterexample in 3.906 seconds
and checked the abstract drain protocol's safety and fair completion in
3.878 seconds. Results are published and registered in
`evidence/model-results/fixtures/resize-requester-retained-handoff/concurrent-drain-contract/`.
The initial sandbox loopback denial was not a model result; it was retained
separately before rerunning with the required local-backend permission.

## Queue Lifetime Across Slot Reuse

This audit reuses the existing `resize_scheme_thread_drain.qnt` thread-role
obligations and `resize_saved_stack_retirement.qnt` backing-storage obligations.
Neither is repeated or treated as satisfied by requester handoff.

The exact candidate contains these relevant source transitions:

| Source | Fact | Unresolved obligation |
| --- | --- | --- |
| `setup.c:setup_processor_scmobj_pstate` | All processor structure fields are set to false on setup. | Existing queue/root ownership must move before slot initialization. |
| `_thread#.scm:macro-processor-init!` | Run, timeout, idle and interrupt queues are initialized. | No live queue entry may be discarded by reuse. |
| `_thread.scm:##lock-processor-for-enqueue!` | Target locking services sync operations but has no admission/generation validation. | A lock on a permanent object is not a lifetime lease. |
| `_thread.scm` pinned enqueue helpers | Publisher retains a processor reference and inserts after locking. | Revalidate target lifetime under the publication lock. |
| `_thread.scm` work stealing | Pinned and migration-target threads are not stealable. | Ordinary work stealing cannot be the complete retirement drain. |
| `mem.c:mark_processor_scmobj` | Current participant's Scheme processor fields are scanned. | Root retention across inactive slots and physical frame transfer needs full GC refinement. |

`resize_queue_epoch_reuse.qnt` adds only the missing queue/publication/reuse
interaction: one preexisting queued thread and one delayed publisher capture
the same permanent slot. Controls reproduce undrained queue loss on reset
(12 distinct states) and stale publication into a reused slot (13 states).
The proposed close/drain/epoch protocol passes safety and fair completion
(12 states). Times are 3.927, 3.932 and 3.803 seconds respectively.

These are source-inspired design counterexamples, not new native crash reports.
Epoch, admission closure and safe fallback are not implemented by this candidate.
Fallback assumes a live retained owner and transferable, unpinned work; it does
not authorize clearing a public pin or migration target. Timeout, IO, interrupt
and blocked queues, active execution, cancellation, collector phases and failed
joins require composition before source admission.

The sealed materializer previously rejected the 18-file lock against its
11-file allowed inventory. The framework owner has been authorized to develop
a generic immutable-source contract with negative controls and a new seal.
No diagnostic observation is promoted around that capability boundary.

After the editable framework implementation changed, the actual materializer
successfully reproduced all 18 locked files in a fresh directory. Its
`source-slice-reproduced` receipt retains `runtimeAdmitted: false` and
`configuredToolchainReproduced: false`. This closes the local file-inventory
limitation, not the new-seal or runtime qualification gates.

The new `source-lock-035` seal was independently verified (1,293 files and
host tool hashes) before executing the candidate's source-core Recipe. All
five steps and the native rule terminal passed; verified readback checked
the original artifacts and inputs. Whole time was 154.211 seconds under the
unchanged 420-second recipe budget. The fresh seed took 12.487 seconds and
full regenerated core build took 95.417 seconds, each under its 180-second
budget. SMP, multiple VMs and multiple threaded VMs were all enabled.

The Git-stored `sealed-source-core-summary.json` is a portable observation,
not a substitute sealed receipt. It binds original receipt hashes and the
reproduction Recipe without publishing personal absolute paths or build trees.
This fresh core is stronger evidence than the earlier incremental build, but
it remains explicitly **not** a complete two-pass bootstrap or native/Gerbil
qualification. The new queue/drain design is not implemented by this binary.

## Evidence Integration Gate

The Reflection and protocol-evidence framework checks passed 34/34 with no
skips. Adding protocol-report-link tests gave 40 passes and one error across
41 tests, also with no skips. The error is an evidence-index contract mismatch:
it requires `status: DENY` and historical upstream test log shapes, whereas
eight retained source/native observations encode their actual denial using
`accepted: false` and custom SCM outcomes. Their original bytes remain intact.
This is not a native Gambit assertion failure, nor may it be hidden by changing
old receipts, dropping failures or manufacturing an upstream log. The framework
owner was notified to audit typed observation admission. Full Datalog graph
integration remains unqualified until that check passes.
