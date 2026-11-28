# Donor frame ownership, captured continuations and private GC work

2026-10-22. Work item repair-9-12. Research-only continuation of [the C handoff audit](smp-retirement-c-handoff.md). Native acceptance remains **8/12**. No runtime/framework implementation, producer, compiler build, Recipe, budget or implementation-worker operation is changed.

Source boundary: B = vendored Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882; P = retained handler-quiet-while-pending-cumulative.patch SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. P numbers are patch-file lines. This is not a source/producer review of the other worker's changing candidate.

## Main result: there is a reusable path, but the present retirement path does not establish it

Gambit already has a typed Scheme thread-save/restore and captured-continuation scanner. They can supply the representation machinery for a bounded retirement refactor. Saving a thread initially records a stack reference; it does **not** immediately make the captured frames heap-resident. A reachable actual thread/continuation object must be scanned while the donor stack is still valid, and all copying/scan work must finish before the stack can be discarded.

The normal sync-interrupt wrapper preserves the currently executing register/frame context for the current GC, but does not call thread-save or publish a saved runnable-thread owner. Retained P retires donors by unlinking their Scheme processor deque node, releasing interrupts, performing OS cleanup and exiting; the inspected branch does not save/migrate each donor's active Scheme execution. P's migration-to-P0 wrapper protects the **initiating caller**, not the other donors. This is a missing source precondition for preserving arbitrary live donor execution, not a newly demonstrated native crash trace.

The private-work side is narrower: the existing collector already scans both complete queued chunks and its local incomplete chunk, including frame-copy allocations. Reuse that full old-cohort GC/return boundary. Do not invent a second chunk-transfer collector or treat an empty public FIFO as complete scanning.

## Exact frame chain and actual owner

| Operation / concrete fields | Existing source behavior | What it does and does not prove |
| --- | --- | --- |
| ##sync-op-interrupt!, B `_kernel.scm`:1428–1448 | FRAME_STORE_RA, W_ALL, service_sync_op, R_ALL, reload RA | **Existing current-GC protection.** It publishes generated registers/fp for the current processor's scanner. It does not execute THREAD_SAVE or establish a saved Scheme-thread continuation suitable for a disappearing processor. |
| macro-thread-save!/restore!, B `_thread#.scm`:1413–1423,3563–3567 | Expand to ##thread-save!/##thread-restore! | **Reusable language primitives.** They must be used from a valid generated Scheme calling context, not pasted into setup.c with arbitrary native locals. |
| C backend lowering B `gsc/_t-c-2.scm`:4235–4262 | Emits end-of-block/frame checks, adjusts Scheme stack and THREAD_SAVE/RESTORE jump inline; tracks fp/r0 changes | **Reusable compiler interpretation.** No new frame ABI or collector decoder is needed merely to invoke this existing primitive. Regenerate affected Scheme-generated C for a real candidate. |
| THREAD_SAVE, B header:6314–6328 | Preserves RA/break-frame link, obtains CURRENTTHREAD, stores `frame` into CONTINUATION_FRAME_FIELD(THREAD_CONT_FIELD(thread)) | **Stack capture representation.** `frame` can still be an address in the donor stack; it is not evidence of a completed heap copy or a surviving scheduler owner. |
| Thread and processor fields, header:6476–6516 | THREAD_CONT_FIELD is a field of the Scheme thread structure; PROCESSOR_CURRENT_THREAD_FIELD is a field of the Scheme processor object | **Existing reachable roots may suffice while old cohort remains.** mark_processor_scmobj scans the processor object, and normal structure scanning follows its thread/continuation fields. If that current-thread field is cleared, establish another real root first. Do not allocate an extra carrier when an existing root actually remains valid. |
| scan subtype CONTINUATION, B mem.c:4096–4099 | Calls mark_captured_continuation on the actual continuation frame field, then scans remaining fields | **Typed scanning entry point.** A bare encoded stack address stored in generic RC data does not use this subtype dispatch; ordinary mark_array treats its fixnum-like representation as an immediate. Root the actual thread/continuation object, not its raw stack address. This negative premise excludes an alternative live typed root. |
| mark_captured_continuation, B mem.c:3667–3815 | Handles stack reference or already heap-resident representation; decodes RA/frame size/link, uses forwarding links, allocates FRAME objects, updates original pointer, may call end_heap_chunk/next_heap_msection | **Reusable physical materialization and alias repair.** It can produce queued/private GC work. The original stack and all necessary typed roots must remain live until this traversal completes; a stored address or an initial root visit is not completion. |
| FRAME scanning, B mem.c:4101–4150 | Decodes actual gcmap/RA/link, marks frame fields and follows/retags frame links | **Reusable interpretation of copied frames.** Heap residency does not by itself prove all frame contents/links were scanned or all borrowers returned. |
| move_continuation, B mem.c:6223–6255 | Moves the current processor's active stack into that processor's GC stack area and resets its break-frame section link | **Current-processor relocation**, not thread migration, not native C activation migration and not publication into a survivor's scheduler queue. |
| THREAD_RESTORE, header:6377–6388 | Reads thread.cont, installs its continuation in the current break frame, consumes saved continuation with END_OF_CONT_MARKER, restores interrupt mask and thread/processor relation | **Reusable exclusive restore.** A running thread can have END_OF_CONT_MARKER in its stored continuation while its actual current frames live under pstate.fp. Do not infer a running thread is saved merely because its object exists. Abort must use a valid restore/continuation path, not both resume the saved thread and fall through an old continuation. |
| ##thread-migrate-to!, B `_thread.scm`:3131–3148 | THREAD_SAVE -> destination processor lock -> BTQ insertion -> current-thread clear -> scheduler | **Reusable ownership-order ingredients.** It also contains an explicit busy-loop/TODO workaround; do not copy it wholesale as a proven production retirement rendezvous. Use existing save/queue/restore semantics with an epoch-bound protocol and original deadlines. |
| Scheduler restore B `_thread.scm`:2810–2842; suspension example:1795–1816 | Removes next thread from run queue under locks before restoring; suspension publishes queue ownership before clearing current thread | **Existing unique execution-owner pattern.** A thread must be parked, queued once or running once. GC root reachability alone does not prevent duplicate scheduling. |

### Rooting the saved object with a small change

While the old cohort is intact, retaining the donor's current-thread field can keep the actual Scheme thread object traced. If the preparation path clears that field or parks the thread away from normal scheduling, a registered local RC header.data containing the **Scheme thread object** is a candidate root. P already scans each participating processor's RC list. A still/RC list handoff to the surviving owner can later keep that object traced after count reduction. No new generic root ABI is implied.

A typed Scheme queue/VM owner may also suffice if its actual object and links remain scanned. An unscanned VM C field or the raw continuation-frame address is insufficient. If another existing typed root already provides coverage, it discharges the obligation instead of requiring another RC object. The new model's threadRoot means this actual reachability, not necessarily a newly allocated root.

## Private work: ownership and existing closure to reuse

| Work class | Producer / current owner / last consumer | Correct boundary |
| --- | --- | --- |
| Complete chunk FIFO | end_heap_chunk B:3251–3311 publishes links/end marker; a stealer removes it then calls scan_complete_heap_chunk after unlocking, B:6698–6727 | Queue removal is before final use. Preserve the source msection and relevant scan resources through actual scanner return. |
| Current incomplete allocation chunk | Per-processor alloc_heap_chunk_start, scan_ptr, alloc_heap_ptr; scan_movable_objs_to_scan B:4282–4390 scans until ptr==alloc_heap_ptr, then handles completed FIFO and returns to the current incomplete chunk | Public FIFO can be empty while local copying work remains. The private frontier is GC work, not an SCMOBJ to retain in a generic carrier. |
| Continuation-copy output | mark_captured_continuation allocates FRAME objects and may end/publish chunks; mark_reachable_from_marked B:6684–6690 invokes still and movable scanners before the steal/idle loop | Capturing frames may reopen work. Run materialization under the existing collector and let its full local/stealing closure finish; do not publish Ready based solely on the first copy/forwarding pointer. |
| Still-object pending scan | setup_still_objs_to_scan B:4210–4233; scan_still_objs_to_scan; root references can add further movable work | Preserve the exact still refcount/graph interpretation and finish its scan list, not just the movable FIFO. |
| Global scanner-idle decision | Existing active scanner count/condition; P:3545–3574 rechecks queues before relinquishing active ownership | **Preserve**, not replace. Local private scanning must have completed before a worker joins this idle count. A new retire_ready flag is not a substitute. |
| GC epilogue | After strong/weak/cleanup/resize barriers, B mem.c:7040–7085 performs heap-fudge/statistics/interrupt refresh and prepare_mem_pstate's fp/hp/limit restoration | Full per-member GC return followed by a valid common old-cohort round closes the interval. Existing collective messages can establish this without new native tail counters. |
| Next GC population | setup_stack_heap_vmstate B:3410–3467 resets frontiers and allocates sections for processor_count | Only withdraw after captured execution and typed owners survive independently. Retaining an excluded pstate or stale frontier bytes does not cause the next GC to scan them. |

**What should not be transferred:** an unfinished scan_ptr or partly scanned chunk cannot simply be spliced into a surviving pstate as if it were a strong root. The smaller approach is to finish the current old-cohort collection and copying work before withdrawal, then let the existing next-GC section setup handle the reduced population. This depends on no later callback/allocator producing more work before the cut. If a legitimate producer remains, the cut has not been reached.

## Refined implementation sequence and the remaining executable gap

1. **Announce preparation before destructive native shrink.** Under the existing resize owner, publish epoch/target and stop donors from selecting new ordinary Scheme work. Every old member must still service nested GC. C-only idle/startup members and members with an actual current Scheme thread require distinct source cases; do not dereference false/current-thread placeholders as threads.
2. **At a valid Scheme safe point, save active donor execution.** The natural source hook is the retiring-member branch of ##sync-op-interrupt! before its C service body, using existing thread-save lowering. Non-retirement sync/GC keeps its existing fast path. Native foreign origins remain excluded by their actual lifetime/admission contract. Register/preserve actual thread-object reachability before clearing its current-thread owner.
3. **Materialize through a full old-cohort GC, if stack-backed capture remains.** The current resize's heap-pressure test does not guarantee GC on shrink. After all captures/roots are published, an explicit old-cohort collection is the simplest candidate for proving heap capture and private-work completion; already heap-resident captures can avoid it only after a source proof. Charge any added collection to the original stage budget and validate its cost; no timing pass is claimed here.
4. **Complete callbacks and typed ownership while still old cohort.** All fallible preparation and frame-copy work close before a nonallocating commit cut. Retain saved Scheme thread ownership exactly once; transfer still/RC/will ownership by their own rules. No native C stack memcpy.
5. **Abort restores on the valid old owner.** After common completion, restore the saved donor thread through the existing Scheme restore/scheduler path. Do not execute it twice by both restoring and returning through the unsaved pre-capture path. Queue/callback side effects remain subject to the previous suffix contract.
6. **Success publishes one supported execution owner before releasing storage.** The saved object must be kept rooted throughout any destination queue operation, pending join and result return. Restore on a survivor uses the existing scheduler/compiler continuation path. OS exit/join bookkeeping remains separate from execution-root publication.

**Correction to the earlier file-scope estimate:** for arbitrary active donor Scheme threads, a plan confined to setup.c/header/mem.c has not supplied the saving hook. The collective/dispatcher responsibility now includes a small Scheme safe-point/completion helper in `_kernel.scm`/`_thread.scm`, using existing primitives. No new compiler frame format or collector architecture is proposed, but regenerated Scheme C is necessary. The other three responsibility surfaces (callback preparation, typed memory handoff, one-time join/cleanup) remain.

**The exact remaining constructive gap:** the model's publishRunnableOnReceiver is a unique scheduler-owner publication action, not a proof that a real BTQ helper can run as a nonallocating step after C2. A Scheme helper may poll, allocate or require leaving C service. The implementation must either (a) complete all such fallible scheduler work before C2 while peers keep collective service and survivors cannot run the parked thread early, with a precise abort undo; or (b) keep a supported rooted parked-thread owner through commit and perform destination queue activation in a proven postcommit Scheme completion path. The latter must also cover postcommit join-error returns and direct C/shutdown callers that do not run a Scheme wrapper. Neither choreography is yet supplied/proved by the inspected source or this finite model. Do not label a root bit or a successful OS join as that proof.

An alternative smaller supported API could reject shrink unless all departing members are demonstrably idle and have no live user continuation/native origin. That requires a source-backed scheduler admission/idle handshake and an explicit contract; the current pinned shrink path has no such proven universal restriction. It would narrow semantics and does not close an inventory requiring migration of live work. Do not silently assume donors idle to obtain a pass.

## Unified QNT successor and source mapping

`retirement_donor_ownership.qnt` keeps the one P0/two-donor/two-GC-per-epoch/two-epoch state machine and prior callback, suffix, error and typed-list mechanisms. It refines the previous abstract frame-owner flag as:

| State/action | Source correspondence / premise |
| --- | --- |
| closeDonorScheduling / schedClosed | Proposed epoch-bound scheduler admission; prevents ordinary new execution after the donor freeze. Not an existing pstate boolean. |
| saveDonorThread / frameRep=1, runOwner=1 | Existing compiler THREAD_SAVE representation: stack-backed captured continuation, parked unique owner. Scheme entry/context is a source premise. |
| publishThreadAnchor / threadRoot, typedCont | Real thread/continuation object traced through existing processor/queue/RC reachability, rather than raw encoded address. No requirement for redundant roots when existing coverage suffices. |
| materializeCapturedFrames / frameRep=2, copyWork | Existing specialized scanner and forwarding/copying; produces further work, not immediate closure. Original stack remains live until copying/alias repair discharges it. |
| privateTodo/privateBusy and scanPrivateChunk/returnPrivateScan | Incomplete-chunk ownership and its actual scan return, in addition to public queue/scanner state. |
| frameKey plus GC-tail keys | Full current-epoch collection/return after captured frames and their content are processed; not a proposed second native barrier. |
| handoffFrameValues and publishRunnableOnReceiver / runOwner=2 | Required supported survivor execution owner and single queue publication. Actual C/Scheme/BTQ choreography is the unresolved implementation premise above. |
| restoreThreadOnAbort / runOwner=3 | Old-cohort exclusive restore before normal donor continuation exit; no native activation migration. |

A/B still represent two callback/retirement members, but detailed frame representation is one representative donor frame graph/ownership token. This is not an exhaustive census of distinct simultaneous continuations on every processor. GC and epoch tags, callback and suffix counts, traced result bridge and native-origin exclusions remain in the unified relation. Full frame decoding, weak/hash semantics, arbitrary topology and OS faults remain separate.

Six new decoded negative controls: skip the private chunk despite public queue drain; use only a raw stack address in generic RC storage; lose the actual thread root; publish a runnable thread twice; omit scheduler closure; free the original stack before capture materialization. They supplement the previous 26 controls; positive checks retain two aborts, abort/commit, invalid-suffix containment, immediate results and registered C results.

Named trajectories import this **same** transition module from `retirement_donor_ownership_tests.qnt`; they do not introduce another state machine or substitute simulations for TLC safety/completion. Identity branches in trajectory helpers leave state unchanged when a capture/private-scan step is already discharged. Those presentation steps are not native progress/performance evidence; full verification uses the model's step relation.

## Tool failure retained and bounded recovery

The first audit d07ba227ba884715b5441fe25079a13c typechecked but its compiled TLA text was truncated: each completed checker.log had a 65,536-byte compiler prefix and no complete module terminator, so TLC never ran. It is infrastructure failure, not a native/model counterexample. This chat interrupted **only its own identified research supervisor**, then reconciled its own 28 registered children and resumed the audit role through existing APIs. No peer was inspected or signaled, no state files were hand-edited.

The successor separates trajectory-only definitions from the compiler input and shortens long field identifiers while preserving the core state/step/property expressions under a reversible lexical renaming. The publication receipt verifies the source-prefix equivalence. The duplicate capture call found in an unexecuted trajectory helper was corrected before the actual tests. No framework capture policy, compiler, expectation, timeout or heap/stack limit is enlarged. Historical partial receipts remain immutable and are referenced below.

## What is now narrower, and what is not proved

**Reusable source mechanisms identified:** generated register spill for active GC; compiler thread-save/restore and break-frame encoding; typed continuation/frame scanners and forwarding; existing typed root reachability; existing complete/private chunk scanners; old-cohort collective/GC completion. A new generic stack copier, per-queue retirement scanner or replacement collector is not justified.

**Necessary small refactor identified:** distinguish GC-visible active state from saved execution ownership; announce/freeze retirement at the Scheme/C safe point; preserve actual saved-object roots and native origins; establish full capture/private-work closure; publish exactly one destination owner or restore the old owner on abort. Earlier C-only ready/list-transfer proposals did not establish this.

**Still blocks sufficiency:** executable Scheme-safe-point/C-collective scheduler publication and rollback protocol; complete donor frame/thread/deque liveness census; supported callback/suffix/origin contracts; direct-C and postcommit-error completion behavior; exact C synchronization/counter reuse; full native fault/GC/FFI and first-eight regression evidence within original budgets. The study has narrowed the largest source premise to an actual control/ownership handshake, not proved all 9/12 faults solved. Retained opaque failure is containment, not recovery.


## Actual retained results

| Check | Outcome | Distinct states | Seconds |
| --- | --- | --- | --- |
| typecheck | PASS | n/a | 1.402 |
| initAbortTwice | PASS | 310 | 5.826 |
| initAbortThenCommit | PASS | 318 | 6.235 |
| initOpaqueSuffix | PASS | 154 | 6.282 |
| initImmediateErrors | PASS | 310 | 5.878 |
| initRegisteredCCaller | PASS | 310 | 6.017 |
| initEarlyReturn | Decoded expected counterexample | 131 | 5.873 |
| initEarlySourceDrop | Decoded expected counterexample | 173 | 5.810 |
| initStaleGCRound | Decoded expected counterexample | 282 | 5.883 |
| initStaleGCEpoch | Decoded expected counterexample | 214 | 5.842 |
| initStaleAbortEpoch | Decoded expected counterexample | 317 | 5.821 |
| initEarlyErrorRelease | Decoded expected counterexample | 131 | 5.802 |
| initReplay | Decoded expected counterexample | 131 | 5.921 |
| initDeadSuffixResume | Decoded expected counterexample | 139 | 5.959 |
| initStrongifyWeak | Decoded expected counterexample | 58 | 8.796 |
| initWithdrawFrame | Decoded expected counterexample | 2 | 6.461 |
| initDropWillOwner | Decoded expected counterexample | 2 | 7.978 |
| initEarlyDecision | Decoded expected counterexample | 314 | 7.729 |
| initStaleCursor | Decoded expected counterexample | 180 | 6.370 |
| initPrematureReuse | Decoded expected counterexample | 163 | 6.360 |
| initUnscannedPayload | Decoded expected counterexample | 2 | 7.426 |
| initFreedNodeAccess | Decoded expected counterexample | 107 | 6.844 |
| initMissingHandoff | Decoded expected counterexample | 437 | 13.776 |
| initScanStillActive | Decoded expected counterexample | 85 | 6.319 |
| initSkippedGCTail | Decoded expected counterexample | 112 | 6.278 |
| initLateWorkProducer | Decoded expected counterexample | 131 | 7.232 |
| initMissingStillRC | Decoded expected counterexample | 328 | 8.049 |
| initLiveNativeOrigin | Decoded expected counterexample | 289 | 6.359 |
| initGCInReturnGap | Decoded expected counterexample | 153 | 6.064 |
| initStaleReturnCopy | Decoded expected counterexample | 152 | 5.961 |
| initUnregisteredCCaller | Decoded expected counterexample | 153 | 7.534 |
| initCatcherOnly | Decoded expected counterexample | 153 | 11.664 |
| initSkipPrivateChunk | Decoded expected counterexample | 167 | 14.905 |
| initRawStackInRC | Decoded expected counterexample | 289 | 11.725 |
| initLostThreadAnchor | Decoded expected counterexample | 289 | 7.633 |
| initDuplicateRunnable | Decoded expected counterexample | 301 | 6.019 |
| initUnsealedScheduling | Decoded expected counterexample | 130 | 5.806 |
| initFreedStackBeforeCopy | Decoded expected counterexample | 37 | 6.614 |
| combinedAbortAcrossTwoEpochs | TypeScript trajectory PASS | n/a | 1.540 |
| abortThenSuccessfulHandoff | TypeScript trajectory PASS | n/a | 1.543 |
| registeredCCallerKeepsCurrentValue | TypeScript trajectory PASS | n/a | 1.521 |

All 41 checks accepted: typecheck, five TLC safety/conditional-completion positives, 32 decoded negative controls and three TypeScript trajectory tests. Original per-check 30-second cap, 12 workers, 1 GiB heap and 8 MiB stack remain. Model SHA256 `8fe4b8fe1f83978d1e822cd9f4616c6fd51767e696fd26e2e8f78ba3e430ae9e`; imported trajectory source SHA256 `dbeedeec9ecd37c60d8dcf079fb15893fd103cc2c4235f08ce35dfbabae4589d`. Raw audit `.cache/tasks/repair-9-12/processes/audit/runs/b748bb9c237141389e8356d4c71806f7/outputs/donor-frame-ownership`. Original interrupted output-truncated run `.cache/tasks/repair-9-12/processes/audit/runs/d07ba227ba884715b5441fe25079a13c/outputs/donor-frame-ownership` remains historical. Source hashes and both own runs' child custody are checked; no native run.


## Scheme/C protocol successor

The [safe-point protocol](smp-retirement-safe-point-protocol.md) refines the previously atomic scheduler-publication premise: retain a rooted nonrunnable owner through common commit, activate once on a survivor, or restore once on the original owner after common abort. It explicitly models helper GC membership and rejects early external return. The actual generated P0/donor/direct-C helper bridge and queue/fault refinement remain unproved; previous results are preserved.
