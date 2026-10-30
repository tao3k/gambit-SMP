# Actual C root/work withdrawal and caller result coverage

2026-10-22. repair-9-12. Research-only source refinement of [the unified plan](smp-retirement-integrated-plan.md). Native acceptance remains **8/12**. No runtime/framework implementation, producer, Recipe, budget or peer operation is changed.

B = vendored Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882. P = retained handler-quiet-while-pending-cumulative.patch SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. P numbers are patch-file lines. The actual checked-in generated `_kernel.c` is examined as source, **not** qualified as the implementation worker's generated/compiled producer. Renaming the Scheme primitive in P changes generated labels; regenerate for a real candidate and confirm the same macro path before claiming native coverage.

## New bounded conclusions

1. **Normal Scheme return already has a concrete caller root.** The c-lambda wrapper writes its SCMOBJ result to PSR1, which is r[1] and is scanned by mark_registers. Its inspected final normal return path has no Scheme allocation, callback, safepoint or collective between last current-value read and that assignment. This permits a cooperative no-GC bridge; a new generic caller-root API is not automatically necessary.
2. **That does not root an error across nested GC.** Existing local err, sync_op.arg[], longjmp_err and a C++ throw struct are not automatically traced SCMOBJ containers. Current resize/OS errors are encoded immediates; preserving arbitrary movable callback error detail is a newly introduced preparation obligation, not an existing observed return failure.
3. **Work closure includes scanner return and the GC epilogue.** Queue removal is before scan_complete_heap_chunk returns; root/weak-phase barriers precede later GC work and fp/hp restoration. The collective cut must follow full per-member GC return, not a queue-empty snapshot or the weak-phase barrier.
4. **List splicing is a narrower operation than withdrawal.** Existing transfer covers still/RC lists/counters under MISC_MEM_LOCK; it neither protects against an unlocked root scanner nor moves donor will lists, active frames or private work. Live-donor handoff still requires a source-specific quiescent cut and typed coverage before processor_count changes.

## Complete ordinary-return chain and exact root transition

| Step / source | Data location and existing guarantee | Disposition |
| --- | --- | --- |
| Scheme callers `##cvmr`, `_thread.scm`:3158–3159,6892–6893 -> primitive `_kernel.scm`:2353–2362 | c-lambda has argument types `(scheme-object int)` and **scheme-object result**. An error code returned as result is Scheme data; it is not automatically thrown by the FFI. | **Existing.** P:956–976 migrates the initiating Scheme continuation to P0 first. Do not confuse this definition in `_kernel.scm` with unrelated `_thread#.scm` declarations. |
| P `___current_vm_resize` -> current_vm_resize_admitted -> on_all_processors -> execute_sync_op_loop -> execute_sync_op(OP_VM_RESIZE) | SFUN admission close/reopen brackets the call; resize result is copied through local `err`, `result.arg[0]`, `sop.arg[0]` (P:4895–4917,5055–5105). | **Existing only for represented value lifetime.** These C locations are not registered roots. A preparation error kept across subsequent GC must instead be rooted/reloaded. |
| P shrink returns heap-overflow/unknown/admission/join results | Explicit FIX error constants; P os_thread.c repair returns FIX(ERRNO_ERR(pthread_join result)), P:4147–4155. B os_base.c:1060–1076 also encodes errno as FIX. | **Existing immediate values.** They do not move and need no RC carrier. Preserve exact OS result semantics. The callback ABI alone does not restrict arbitrary execute_fn results to these immediate cases. |
| Generated `_kernel.c`:6256–6288, helper _____kernel_23_12 | `___return(val)` assigns local `___result`, then `___CFUN_SET_RESULT_SCMOBJ`; no result conversion or result-release callback occurs. The integer argument conversion is before the native call; its END macro is just a brace. | **Existing pinned normal-return path.** `___CFUN_ASSIGN` is direct assignment (header:10316); END_CFUN_BODY has empty AT_END in this generated body. A future cleanup/reentry/GC hook would invalidate this exclusion. |
| Header:10387,10403;7082; generated caller:26342–26366 | `___CFUN_SET_RESULT_SCMOBJ` writes `___CFUN_RESULT = ___result`; CFUN_RESULT is PSR1; PSR1 is `___ps->r[1]`. Out-of-line caller publishes context and restores registers, then JUMPRET; mark_registers mem.c:6508–6523 scans r[]. | **Existing caller root.** After installation, a later GC updates that slot. Do not overwrite it with a stale C copy after GC. |
| Cooperative return window | GC uses on_all_processors, B setup.c:1182–1199; barrier snapshots full current cohort. A peer may request GC, but cannot complete it without the current participating P0 entering service. The final inspected return/assignment path does not enter service. | **Source-backed conditional exclusion**, not a hardware no-preemption claim. Keep the processor a valid participant through the bridge. Raw foreign/concurrent collector entry or inserted callback/allocation is outside this proof. |

For a newly rooted movable preparation error, a small normal-return implementation can reload the traced value **after the final possible GC**, then release the temporary handle and immediately traverse the proven no-GC return window into PSR1. `___release_rc` B mem.c:758–779 unlinks/frees native RC storage and does not call the Scheme collector. It is not a general guarantee about arbitrary allocator hooks. Alternatively retain the handle until caller installation, if that is already supported by the chosen caller convention. Do not add both ownership schemes without a last-consumer reason.

The C locals in this narrow window need not each be registered roots, because no collection can run there. They must still contain the **current** post-GC value. A pre-GC cached local returned through the same window is invalid even though PSR1 is later scanned. This distinction removes an unnecessary broad root-interface change while preserving the actual moving-GC obligation.

## Error propagation routes: existing, requires modification, or unsupported

| Route | Already guaranteed | Required change / unsupported boundary |
| --- | --- | --- |
| Ordinary resize encoded result to Scheme | Immediate result survives any GC; inspected c-lambda installs PSR1 without intervening collector work. | Preserve final straight-line path. No new root is needed for the immediate error itself. |
| Returned callback error retained while other donors/P0 still collect | Current cleanup(false) ignores execute_fn return and has no recoverable error publication. | New preparation must classify immediate vs movable result and install movable detail in actual traced storage **before** rejoining any GC-capable collective. Reload for propagation/result use. Do not claim this is already fixed by a struct field. |
| `___throw_error`/`___propagate_error` B setup.c:839–867; header:9981–10006 | C setjmp mode stores error in ps->longjmp_err and jumps to origin catcher; END_TRY restores previous catcher. C++ mode catches a throw_struct. These control operations themselves do not invoke GC. | No scanner in inspected mem.c names longjmp_err or throw_struct. A live origin and no-GC throw-to-catch stretch can transport the value; before the catch path allocates/serves GC, store any movable value into a traced owner. Do not treat catcher metadata as a root or arbitrary foreign longjmp as supported unwind. |
| Outer resize ON_THROW P:5096–5097; execute_sync_op_loop final throw P:5010ff | Outer handler reopens SFUN admission and rethrows; setup_state==2 changes final throw behavior. | A recoverable preparation error must be caught/published locally and complete C3 first; otherwise outer control may escape while peers still need service. This is separate from value rooting. |
| Direct C caller of ___current_vm_resize | Raw function returns SCMOBJ; an immediate encoded error can be held without tracing. It has no generated CFUN_SET_RESULT/PSR1 step on this route. | Movable values retained across later Scheme/GC entry need explicit caller-owned registered RC data or another supported root. A raw C local is not automatically supported. A non-P0 C origin that can retire itself is not saved by the Scheme-only migration wrapper. |
| C -> Scheme -> C via ___call, SFUN marker | B setup.c:3290–3389 builds origin return frame/marker and restores caller; SFUN_RESULT is PSR1 (header:10066). P preserves origin/SFUN admission protections. | After SFUN_SET_RESULT copies PSR1 to C local, marker kill/frame leave does not make that local a general moving root. A later GC/reentry needs explicit C ownership. Frame leave before propagation is not the last native activation access. |
| Shutdown void cleanup | B setup.c:4859 calls resize from C; P adds pending-cohort/foreign-frame rejection at ___cleanup_vmstate, P:5398–5420. | There is no Scheme result wrapper to manufacture ownership here. Preserve encoded status/retained-failure semantics. A terminal opaque record must prevent future service/teardown from traversing invalid requests; ordinary Scheme return is not enough to define that host policy. |

These results justify two supported caller classes in the new model: the pinned Scheme PSR1 path and an explicitly registered external C owner. “Unregistered C caller” and “catcher field only” are negative controls, not newly supported APIs. There is no silent conversion of arbitrary callback failures into UNKNOWN_ERR to avoid rooting; exact callback-result semantics remain an API decision if non-immediate results are allowed.

## Actual work/roots chain and the last-consumer cut

| Source operation | Producer/consumer ordering actually present | New source obligation at retirement |
| --- | --- | --- |
| end_heap_chunk B mem.c:3251–3311 | Writes end marker, links a nonempty unscanned chunk to FIFO under its spinlock, publishes with ordered barriers, signals scan termination condition. Can be reached while marking/copying. | Do not call this as a generic teardown fence. It can create work. Close all legitimate producers before admitting retirement work-closed. |
| Steal -> scan B:6698–6727 | Stealer removes queued chunk, unlocks, **then** calls scan_complete_heap_chunk. | FIFO empty does not imply the last scanner returned. Retiring storage/locks must outlive that call. |
| mark_reachable_from_marked and P:3545–3574 | Active-scanner count and condition wait; P rechecks queues under their locks before decrementing. | Preserve these guards. A retirement ready bit cannot replace scanner ownership or a full same-phase return. |
| ___garbage_collect_pstate B:6995–7085 | Setup/strong/weak/cleanup/resize phases have barriers. After them, heap-fudge work, statistics/GC interrupt and prepare_mem_pstate still run before return. | Count the **whole per-member call**, not the last root/weak barrier, as a producer/consumer interval. A new common old-cohort round after full GC return discharges the tail; no redundant native tail counters if existing messages prove it. |
| prepare_mem_pstate B:4525–4571 | Writes ps->fp, ps->hp, limits and refreshes interrupt detection; these are used by later scanners/execution. | Do not free/repurpose donor memory because another member already passed a GC barrier. The model's tail tags represent completed field restoration, not new C atomics mandated by the model. |
| setup_stack_heap_vmstate B:3410–3467, GC setup B:6778–6810 | Next GC iterates only processor_count, reassigns stack/heap sections, resets work queues, and sets worker counts for that population. | A retained retired pstate is not automatically scanned. Slot bytes alone cannot preserve its roots/work after count reduction. |
| P ___transfer_mem_pstate:3301–3353 | MISC_MEM_LOCK protects still/RC link splicing/counters. mark_rc B:3969–3991 traverses RC links without this lock; still scanning has its own GC phase. | MISC_MEM_LOCK alone is **not** an exclusion against the collector. Require actual no-concurrent-scanner/no-future-producer collective cut, then splice once. Joined-donor precondition cannot silently become live-donor quiescence. |
| B ___cleanup_mem_pstate:4928–4936 and cleanup_rc:685–700 | Frees still objects and remaining registered RC blocks; cleanup_rc walks/frees remaining nodes rather than preserving their external refcounts. | Transfer/empty/discharge actual owners before cleanup, prove all external borrowers gone, and do not redo precommit transfer postjoin. |
| mark_continuation/move_continuation B:3898–3966,6223–6255; _thread.scm:3131–3148 | GC decodes real frame maps; move_continuation copies **this processor's** stack into its own collection space. Scheme thread-migrate-to uses macro-thread-save and scheduler queue insertion. | Neither GC stack relocation nor moving still/RC chains migrates a native C activation or proves other donors' Scheme execution has been saved. P moves the initiating caller, not every donor. Actual live donor frame/thread/deque reachability remains a blocking census, not an assumed all-frame copy. |
| Wills/weak lists and other roots | Existing RC/per-member root scan and strong/weak/will phases are detailed in the prior census. | Separate still/RC splice, supported saved-continuation ownership and typed will-list owner. No strongification of weak fields, no arbitrary pstate memcpy, no dropping native-origin lifetime. |

**Small-change boundary:** implement a new typed handoff caller only after proving it runs at the existing collective's full work-closed boundary. It may reuse mechanical list-link code with a separately stated live-quiescent precondition. It may not broaden the old joined-donor helper contract merely by renaming it. If live frame/private-work coverage cannot be established for a legal shrinking member, reject/defer commit and report that production success coverage remains incomplete. Safe rejection is not gate completion.

## Refinement of the single QNT and specific negative controls

`retirement_c_handoff.qnt` is a successor of the unified state machine, not a separate standalone result model. It retains multi-donor callbacks, repeated GC, two epochs and queue outcomes, and refines two former atomic steps:

- Each GC explicitly publishes late weak work, dequeues the last work item, waits for the scanner to return, then waits for each member's GC tail. Only then is the GC return key recorded. Global preparation and handoff require work closed.
- Success separately performs still/RC list ownership, frame-value ownership exclusion, and will-list handoff before commit. A live native origin cannot be “migrated” by setting a root receiver.
- Return explicitly reloads the current traced value, releases the temporary roots within a cooperative no-GC bridge, and installs either PSR1 or caller-owned RC storage. A post-installation relocation discriminator verifies the current value stays covered; this extra move is **not** a third full GC protocol per epoch. Cached pre-GC locals, unregistered C locals and catcher-only storage are rejected.

Nine new decoded controls supplement the previous seventeen: scanner still active despite empty queue; missing GC tail; producer publishes after global closure; missing still/RC ownership; live native-origin transfer; GC-capable step inserted in the return gap; stale cached return value; unregistered C caller; catcher-only result. Five positives include the three original campaigns, an immediate-error path, and an explicitly rooted C caller. Three named trajectories exercise unified abort/reuse, abort/commit and rooted external return.

The generic requestRoot in the model represents an actually live saved SCMOBJ. As the prior def-use audit notes, shrink-only thunk use may be absent and no new carrier is then necessary. The model does not force every immediate or dead field to be rooted. It also does not model the concrete generated frame encoding, all weak hash semantics, arbitrary allocator hooks, arbitrary native callbacks or the actual OS join state machine.

## What is now discharged and what still blocks sufficiency

**Discharged at pinned source level:** actual normal Scheme return destination PSR1/r[1]; the inspected normal return exclusion of GC-capable work; immediate error representation; lack of automatic tracing for sync args/raw C/catcher metadata; work producer/dequeue/scan-return/GC-tail ordering; exact limited scope of still/RC transfer and its lock. No observed current native fault is attributed merely from these source facts.

**Must change for proposed preparation:** rooted capture/reload of any non-immediate saved error across nested GC; local catch plus old-cohort common completion; typed handoff after full work closure; preservation of root/weak/continuation interpretation; exact one-time cleanup; caller root ownership if the return path differs from the checked normal c-lambda bridge. A normal-return hook/API is not a blanket requirement.

**Cannot claim support yet:** arbitrary callbacks/foreign longjmp or self-retiring unregistered C origins; continued service on a possibly invalid suffix; moving values retained by raw C after reentry without roots; relocating a native activation; treating MISC_MEM_LOCK as a collector fence; retaining unscanned donor bytes as roots; legal donor frames/private work without a concrete disposition; full native faults/reuse/topology and first-eight regression qualification. The new finite model narrows the assumptions; it is not a C refinement theorem or production admission.


## Actual results and evaluator boundary

| Check | Backend / outcome | Distinct states | Seconds |
| --- | --- | --- | --- |
| typecheck | Quint typecheck PASS | n/a | 1.436 |
| initAbortTwice | TLC safety + completion PASS | 236 | 5.705 |
| initAbortThenCommit | TLC safety + completion PASS | 244 | 5.612 |
| initOpaqueSuffix | TLC safety + completion PASS | 117 | 5.564 |
| initImmediateErrors | TLC safety + completion PASS | 236 | 5.613 |
| initRegisteredCCaller | TLC safety + completion PASS | 236 | 6.025 |
| initEarlyReturn | TLC decoded counterexample | 98 | 11.569 |
| initEarlySourceDrop | TLC decoded counterexample | 140 | 12.325 |
| initStaleGCRound | TLC decoded counterexample | 212 | 11.254 |
| initStaleGCEpoch | TLC decoded counterexample | 158 | 9.750 |
| initStaleAbortEpoch | TLC decoded counterexample | 243 | 10.014 |
| initEarlyErrorRelease | TLC decoded counterexample | 98 | 5.775 |
| initReplay | TLC decoded counterexample | 98 | 5.762 |
| initDeadSuffixResume | TLC decoded counterexample | 106 | 5.724 |
| initStrongifyWeak | TLC decoded counterexample | 37 | 5.673 |
| initWithdrawFrame | TLC decoded counterexample | 2 | 5.480 |
| initDropWillOwner | TLC decoded counterexample | 2 | 5.578 |
| initEarlyDecision | TLC decoded counterexample | 240 | 5.540 |
| initStaleCursor | TLC decoded counterexample | 125 | 5.676 |
| initPrematureReuse | TLC decoded counterexample | 130 | 5.585 |
| initUnscannedPayload | TLC decoded counterexample | 2 | 5.593 |
| initFreedNodeAccess | TLC decoded counterexample | 74 | 5.647 |
| initMissingHandoff | TLC decoded counterexample | 327 | 6.033 |
| initScanStillActive | TLC decoded counterexample | 46 | 7.420 |
| initSkippedGCTail | TLC decoded counterexample | 78 | 6.260 |
| initLateWorkProducer | TLC decoded counterexample | 98 | 7.532 |
| initMissingStillRC | TLC decoded counterexample | 254 | 7.990 |
| initLiveNativeOrigin | TLC decoded counterexample | 219 | 9.007 |
| initGCInReturnGap | TLC decoded counterexample | 116 | 6.325 |
| initStaleReturnCopy | TLC decoded counterexample | 115 | 7.328 |
| initUnregisteredCCaller | TLC decoded counterexample | 116 | 5.845 |
| initCatcherOnly | TLC decoded counterexample | 116 | 5.722 |
| combinedAbortAcrossTwoEpochs | Rust evaluator recursion-limit failure; zero tests executed | n/a | 1.350 |
| abortThenSuccessfulHandoff | Rust evaluator recursion-limit failure; zero tests executed | n/a | 1.339 |
| registeredCCallerKeepsCurrentValue | Rust evaluator recursion-limit failure; zero tests executed | n/a | 1.285 |
| combinedAbortAcrossTwoEpochs | TypeScript evaluator: one actual test PASS | n/a | 1.300 |
| abortThenSuccessfulHandoff | TypeScript evaluator: one actual test PASS | n/a | 1.268 |
| registeredCCallerKeepsCurrentValue | TypeScript evaluator: one actual test PASS | n/a | 1.255 |

The original aggregate is false because all three Rust trajectory calls failed before executing tests. Its receipt/logs remain immutable. The installed Quint 0.33.0 CLI advertises test backends typescript/rust (CLI:201–205); the same model bytes pass all three explicit trajectories using `--backend typescript` within the original 30-second cap. No model/expectation/stack limit was changed to bypass the tool failure. Five TLC positives and twenty-six decoded controls passed; typecheck passed; the three actual trajectory passes come from the declared TypeScript evaluator, not Rust. The effective 35-check set records that distinction rather than rewriting the original failed calls.

Original run: `.cache/tasks/repair-9-12/processes/audit/runs/4fbd5930138b49478a621f6d7d08f125/outputs/c-handoff-refinement`. Trajectory recovery: `.cache/tasks/repair-9-12/processes/audit/runs/54c21e4ee1fd4da6b1631627d98a37c3/outputs/c-handoff-trajectory-recovery`. Model SHA256 `fff2e3f71f31356a52e2c7ed139d1c95ea6d312d7d9ac2cb209681c772ac067d`. Full hashes, decoded witnesses and original failures are in [validation](../evidence/research/smp-retirement-study/c-handoff-validation.json). Every verifier/checker child in both own runs was reconciled before publication; no peer process was sampled or controlled.
