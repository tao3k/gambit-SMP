# Shrink preparation: nested GC, callback abort and root coverage

2026-10-22. Work item repair-9-12. Design and bounded formal evidence only; acceptance remains 8/12. No runtime or framework implementation is changed, and no operation is sent to the implementation worker.

This follows [the pre-exit source audit](smp-pre-exit-retirement.md) and [the function/consumer inventory](smp-retirement-source-correspondence.md). Source boundary: Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882 plus retained handler-quiet-while-pending-cumulative.patch SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. P line numbers refer to the patch, B to baseline. Proposed fields/helpers are not existing runtime symbols and are not the other worker's current candidate.

## The nested-GC obstacle is operation election, not just a missing wait

`barrier_sync_op` chooses the lower encoded operation when child/self offers differ (B setup.c:578–640). The retained priorities include SET_PROCESSOR_COUNT=1, VM_RESIZE=2, GARBAGE_COLLECT=3 and NOOP=63. In `execute_sync_op_loop`, the caller's operation is normally changed to NOOP only **after** `execute_sync_op` returns (B:1099–1108). A GC-capable release callback nested inside that execution cannot safely be introduced by just moving the cleanup loop before count publication: the original outstanding resize can still outrank the nested GC, replay resize or prevent the required GC election. A plain barrier/OS join/busy wait at P0 likewise cannot service the requested GC.

The existing growth path demonstrates a useful, narrower mechanism: P:4920–5013 keeps old participants in collective service while scheduler_status/startup_epoch report pending initialization, but lets nested startup/GC callers leave their own loop. It does not already implement shrink preparation or arbitrary callback unwind. Reuse its service-loop structure after designing separate phase state, not its booleans or startup-role test verbatim.

## Proposed functions and fields

| Function/structure | Proposed exact responsibility | Ownership and source obligation |
| --- | --- | --- |
| `___current_vm_resize` / `current_vm_resize_admitted` | Keep existing Scheme migration-to-P0 and SFUN admission close/reopen. Allocate/retain any request/error root storage before preparation can allocate; preserve the original resize result separately from the active election offer. | Existing owner; no new global runtime serialization. Do not reinterpret SFUN frame zero as a full host lifetime. |
| VM `retire_prepare_epoch`, `retire_old_count`, `retire_target_count`, `retire_prepare_phase`, `retire_prepare_error` | One exact owner/incarnation-scoped transaction with phases Idle, Preparing, Deciding, Committing, Aborting, Complete. Commit/error result survives nested operations. | P0 owns phase/decision; peer acknowledgements identify this epoch. Startup epoch is not silently reused as an interchangeable identity. A Scheme error payload requires an actual traced slot. |
| VM `retire_saved_request_root` | Hold the saved Scheme thunk/result using existing registered root machinery across nested GC, not an untraced `___sync_op_struct.arg[]` copy or C local. | An RC handle is an option: `___alloc_rc`/`___register_rc`, `___set_data_rc`, `mark_rc`, `___data_rc`. Only `rc_header.data` is scanned; arbitrary C payload fields are not automatically roots. Register on a surviving processor, preserve its lifetime and reload from the updated slot after GC. Source constructor/alias proof still required. |
| Per-slot `retire_prepare_epoch`, `retire_prepare_status`, `retire_cancel_next`, `retire_prepare_error`, `retire_handoff_status` | Statuses Pending, CallbackRunning, Ready, Failed. Track detached request progress and exactly which root/work classes have been discharged. A Ready acknowledgement is published after callback and coverage completion. | Each processor publishes its own status with release; P0 reads matching epoch/status with acquire. Save next before invoking external code. Do not dereference/requeue a request after a callback that may have freed it. Returned heap errors/arguments must have proper root ownership. |
| Proposed `prepare_retire_interrupts_pstate` | Detach a bounded admitted queue prefix under procedural_interrupts_mut, unlock, execute each release(false) once under a local supported runtime catcher, persist outcome/cursor; return to collective service on error. | Close/stop raw producers using the existing supported caller contract first. No wait or user callback while holding its queue mutex. Callback can request GC while the donor remains in old cohort. The catcher does not intercept arbitrary host longjmp outside the runtime or process termination. |
| `execute_sync_op_loop` plus proposed prepare/decision operation cases | Consume the outer resize election offer into saved phase state **before** running any GC-capable callback. Its active offer becomes NOOP/service; nested GC offers can win. Ready members continue servicing old-cohort operations. | Separate outer transaction owner from nested GC caller; a nested caller returns after its own operation, not after shrink commit. Prevent recursive resize admission during prepare. Do not replace the parent request with an unrooted C pointer. |
| Proposed `retire_prepare_try_decide` in `___vm_resize_pstate`/dispatcher | Old-cohort decision operation runs after GC in priority order; require all matching callbacks/acks and no pending GC. Success enters a nonallocating commit section; error enters a common abort handshake. | Define priority order GC before preparation readiness/decision and both before NOOP. Do not submit high-priority OP_SET_PROCESSOR_COUNT while unprocessed GC is still eligible. Exact new op encodings must be checked against existing cases, rather than copied from the finite model. |
| `___transfer_mem_pstate` / root handoff helper | After all fallible callbacks/preparation succeed, finalize actual still/RC ownership splice and phase-specific root/work discharge at a valid old-cohort GC boundary. Publish new count only after receiver coverage is established. | Keep destructive splice/drop out of fallible callback steps. Temporary receiver root registration may happen earlier; source stays covered. Preserve wills/weak semantics and existing frame interpretation. No raw stack memcpy or arbitrary end_heap_chunk call. |
| shrink/recover join and final cleanup | After commit, OS-only exit tail and join result handling use separate exact per-slot state. Failure retains the OS/resource record and cannot undo cohort commit or claim successful recovery. | Existing local quiet-before-exit and no-GC inspected OS cleanup remain useful. Join succeeds once; an error does not assert exit or authorize slot reuse. |

These are four implementation surfaces: interrupt cleanup/catcher, collective dispatcher, root/ownership handoff, and join/result bookkeeping. Field names specify the design contract; they are not a request for a new generic transaction framework or replacement collector.

## Operational sequence for nested GC

1. Admit one shrink owner while the old count is unchanged. Save the requested thunk/result into a surviving scanner-visible root owner. Clear the active outer resize election offer to NOOP; retain the original requested operation in phase state.
2. Old members enter Preparing. Retiring processors detach requests and invoke release callbacks outside the queue lock. Their `prepare_status=CallbackRunning`; they are still legitimate GC participants. A ready processor stays in the service loop rather than returning to Scheme, entering pthread_join or sleeping at a plain barrier.
3. When a callback's allocation requests GC, its nested `on_all_processors(OP_GARBAGE_COLLECT)` and the old members' service offers rendezvous. GC outranks the prepare/decision offer because the parent VM_RESIZE is no longer eligible. The existing collector runs with the **old count**, existing root barrier and old participant interpretation. Once this GC operation completes, its caller resumes the callback; it does not wait for the outer shrink transaction to finish.
4. Callback completion, root registration and private-work closure produce per-slot matching Ready or Failed. Constructing a root carrier can itself allocate, so Ready cannot precede it. All ready members continue serving until the shared decision. A final old-cohort decision must drain any pending GC before making the no-more-allocation commitment.
5. Success executes only the validated nonallocating ownership splice/drop and OP_SET_PROCESSOR_COUNT. No user callback, new root allocation or fallible preparation remains in that commit section. After commit, surviving GC can run safely even if an OS thread has not yet exited and its join fails. Only the narrow audited OS tail remains on the withdrawn processor.

The required dispatcher change includes priority and reentrancy handling. Merely adding a ready bit to the current blocking function does not implement steps 1–3. Multiple VMs keep their existing separate cohorts; do not wait under process-global registry/list locks for a callback that needs those locks or GC to progress.

## Callback failure: containment and abort, not reversal of arbitrary effects

A callback may already have closed a native resource or freed its own request when it returns an error. Its actions cannot generally be undone. Therefore the supported precommit outcome is **aborted shrink with recorded effects and retained old cohort**, not a promise to restore the entire pre-call world.

- Persist callback progress/outcome; never replay a completed/failed callback merely by resetting an iterator or prepare status. The failed request is not blindly requeued; its lifetime/result ownership must be specified. Remaining detached requests stay under the phase owner until their documented disposition is decided.
- Convert an ordinary returned error or a supported Gambit `___THROW` into a per-slot Failed result while the old cohort remains intact. Use existing BEGIN_TRY/END_TRY or ON_THROW semantics with a frame on the originating OS thread. Persistent progress must be outside indeterminate nonvolatile locals across setjmp/longjmp. A catch path restores the original catcher and rejoins collective service; it does not throw out of the outer collective immediately.
- All old members acknowledge Aborting after active GC completes. Only after that common exit can the originating caller receive the error and admission reopen. Nobody is freed, removed from the count or left waiting for a participant that already returned.
- A temporary surviving root can be dropped on abort only while the original source root is still scanner-visible/current. Destructive list ownership handoff is deferred until successful commit, so abort does not copy stale pointer values back or reconstruct a freed list. If an implementation chooses irreversible transfer earlier, it needs explicit monotonic ownership on abort; the present smaller proposal avoids that choice.
- After the cohort commit, failures are reported and retained under the postcommit lifetime contract. Do not increment the count back to resurrect a partly destroyed worker. A stuck callback, arbitrary foreign longjmp bypassing runtime catchers, process termination, or an unjoined raw producer is outside this finite recoverable-abort proof; define an explicit host contract/terminal policy before production admission.

Error return thus has two meanings to preserve: the shrink did not commit, and callback side effects may already exist. If the public API requires failure atomicity of those arbitrary effects, it cannot be provided by this small generic cleanup refactor; the callback API itself needs transactional restrictions or different ownership semantics.

## Continuous root coverage and moving GC

The source and receiver are **root locations**, not immutable copies of an object address. A receiver slot must be registered with an actual scanner before the source root can be withdrawn. If a nested moving GC happens after receiver publication, the collector updates both registered locations. The consumer then reloads the receiver's current value. A cached C pointer from before the collection is not certified by an earlier acknowledgement.

The finite model tracks donor/receiver registration and the version of each slot across one moving collection. It tests publication before and after GC, and the normal/abort cases. The actual C correspondence still requires a full classification of r/saved/cache, still/RC, continuations, weak/will lists and private work; their semantics cannot all be replaced by strong roots. Existing marker-allocation rooting, per-processor mark_rc, GC root barrier, and scanner completion checks are preserved.

For successful commit, the final decision establishes that no fallible callback/future producer remains, relevant GC phases are closed, and receiver ownership is scanner-visible. For abort, source coverage and old cohort membership remain, and temporary receiver roots are removed only after both sides acknowledge. Arbitrary C payloads in an RC allocation are not traced automatically: the actual Scheme root must be in `data` or an independently registered supported root location.

## QNT scope and mutation controls

`retirement_prepare_phase.qnt` models P0 plus one donor, one nested moving GC, explicit arrivals from both members, a ready-but-serving coordinator, saved parent-election state, at-most-once callback effects, receiver registration/observation and two-sided abort acknowledgements. Normal completion, returned-error abort and supported-runtime-throw abort are separate initializers. The old cohort stays at two on abort and becomes one only on commit. The corrected graph has finite monotonic progress except terminal stutter; its weak-fair completion is conditional on every modeled actor returning/servicing its enabled finite step.

Seven mutations remove one obligation each: leave the outer resize eligible; park P0 after Ready; replay a failed callback; drop the source root early; treat unregistered receiver bytes as a root; commit after callback error; let a supported runtime throw escape before abort acknowledgement. The checker must produce a decoded state distinguishing that precise failure. Named trajectories check both registered roots updated by moving GC, and abort after irreversible callback effects without replay.

This model makes the required service loop explicit but does not prove C implementation equivalence, unbounded callbacks/GC, real memory ordering, epoch reuse, multiple donors/GC rounds, arbitrary external throws, callback failure atomicity or complete native acceptance. Exact per-epoch source publication and source-specific root/weak semantics remain obligations. The new guards are proposed implementable rules, not evidence those guards already exist in C.

## Why the earlier normal-path check timed out

The retained normal-path receipt 4d9fd25e72894e4888086712db4e6af6 reports one total 30-second deadline, phase TLC, no state counts, timeout=true and reaped children. `tlc_execution.compiled_check` uses that same deadline for Java identity, Quint compilation and TLC final temporal checking. The own-child journals/argv and kernel birth records distinguish those phases: the compile child lived about 25.021 seconds from registered birth to finished observation; the TLC child about 3.974 seconds. The final log reaches semantic processing/Starting/temporal satisfiability setup, not an explored-state or liveness-counterexample report.

This identifies where the fixed budget went; it does not establish why compilation took that long, blame another worker, or prove model nontermination. Birth-to-finish spans include launch/recording overhead and are not isolated compiler CPU timings. A single same-model, same-property/configuration diagnostic is run below with the original **combined 30-second cap**; per-child journals are retained. Compilation is not precharged in a separate run and TLC is not given a reset 30-second budget. The old timeout remains historical even if the new run passes.

## Repository publication

The earlier [research index](smp-retirement-research-index.md) now contains the exact prior audit documents and model source hashes. This preparation-phase design, its QNT source and compact results are also written to ordinary repository docs/models. Raw process/checker receipts stay in the existing audit area. No Git commit or push is implied by writing these reviewable files. Runtime code, Recipes, seals, budgets and the other worker are untouched.


## Actual retained results

| Check | Result | Distinct states | Seconds |
| --- | --- | --- | --- |
| typecheck | PASS | n/a | 3.5083700830000453 |
| initSuccess | PASS | 52 | 4.023 |
| initReturnError | PASS | 63 | 4.069 |
| initCaughtThrow | PASS | 63 | 4.019 |
| initParentReplay | Decoded expected counterexample | 25 | 4.062 |
| initParkedCoordinator | Decoded expected counterexample | 31 | 4.1 |
| initCallbackReplay | Decoded expected counterexample | 75 | 4.24 |
| initEarlyRootDrop | Decoded expected counterexample | 59 | 4.032 |
| initUnregisteredReceiver | Decoded expected counterexample | 61 | 4.059 |
| initCommitOnError | Decoded expected counterexample | 52 | 4.051 |
| initEscapedThrow | Decoded expected counterexample | 49 | 4.091 |
| movingGCUpdatesBothRoots | PASS | n/a | 0.5490146249940153 |
| failedCallbackDoesNotReplay | PASS | n/a | 0.544995292002568 |

Normal-path diagnostic: PASS, 4.334 seconds, {'generated': 17, 'distinct': 13, 'queued': 0}. Both its same-model input and original combined 30-second budget were retained. The old timeout remains unchanged.

| Run | Phase | Registered child span seconds | Timeout |
| --- | --- | --- | --- |
| original | java-identity | 0.345218 | False |
| original | compile | 25.020677 | False |
| original | TLC | 3.974438 | True |
| diagnostic | java-identity | 0.203822 | False |
| diagnostic | compile | 3.441955 | False |
| diagnostic | TLC | 0.428285 | False |

Birth-to-finished-observation spans include launcher/recording overhead; they do not isolate CPU time. The same total budget covers identity, compiler and checker. New QNT results concern this finite design only; no native gate is upgraded.

Raw run: `.cache/tasks/repair-9-12/processes/audit/runs/5cb2056899764ee59b9b1278db778b80/outputs/retirement-prepare-phase`; complete timing provenance is `normal-path-diagnostic/timing.json`.
