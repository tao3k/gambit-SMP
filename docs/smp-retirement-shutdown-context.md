# Shutdown context, helper registration, P0 affinity and raw unwind

2026-10-22; repair-9-12; research only. Native acceptance remains **8/12**. Successor to [the P0 bridge study](smp-retirement-p0-completion-bridge.md). No runtime/framework/compiler changes, native execution, producer qualification, Recipe/budget changes or implementation-worker operations.

B is the retained vendored source associated with Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882; P is retained handler-quiet-while-pending-cumulative.patch, SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. Exact file-byte identities in the receipt define this study; P line numbers refer to the patch file, not applied C. No moving implementation candidate is inspected.

## Result: shutdown context is conditional, not universally complete

Three distinct events must not be conflated: C setup admitted cleanup; Scheme threading/helper initialization completed; the last host-to-Scheme invocation returned through its matching marker. Existing source proves neither of the latter from `setup_state==1`.

| Real entry | Source chain / proven state | Helper admission |
| --- | --- | --- |
| Top-level thunk returns normally | B setup.c:6425 -> ___run:3394 -> matching ___call return:3375ff -> marker kill -> setup returns NO_ERR -> main.c:1361–1364 cleanup | Strongest reusable context case: return frame/R0 restored and marker invalidated. Still validate current P0 ownership, current Scheme thread, prepared call-stack space, per-VM helper readiness and no teardown. No blanket shutdown-readiness proof follows from NO_ERR alone. |
| Scheme `(exit 0)` | B `_kernel.scm`:4734–4735 encodes status+1; exit-with-err-code-no-cleanup:4697–4704 calls propagate_error -> raw throw -> ___call rethrows nonmatching error without normal pop -> ___run catches -> setup.c:6435–6436 cleanup | **Normal requested process exit can use the raw-unwind path.** It is not the previous prepared-C positive. Do not invoke a new completion helper on this context by assuming normal matching return occurred. |
| Setup/module/VM initialization error | setup_state=1 at B:6335, before setup_modules, setup_kernel_handlers:6369, setup_vmstate and Scheme startup-threading | Partial-prefix cleanup can be legal, but helper or scheduler may not exist. P's processor_count==0 branch does native prefix cleanup without resize. A nonzero count alone does not prove Scheme readiness. |
| Raw error inside an internal completion helper | ___call restores its catcher, then rethrows before normal fp/R0 restore when marker/error mismatch | Existing outer ON_THROW does not repair the Scheme frame. Retain known roots/marker and stop normal execution/teardown until a proved disposition. No blind retry. |
| Child/global cleanup | P close_cleanup_sfun_vms:5588ff closes foreign admission; global cleanup prechecks child count==1/pending_join_count==0 before sealing | A drained foreign lease population and registry closure do not prove a current Scheme helper context. Child owners must resolve their own execution and native consumers first. |

**Interrupt correction:** B os_setup.c:518–523 `___cleanup_all_interrupt_handling` calls cleanup_user/heartbeat/child handling. It does not destroy all pstate sync machinery. B setup.c:66–93 raises sync interrupts by updating flags, stack trip and device-select abort; terminated workers' B:798–802 loop continues service_sync_op. Therefore stopping those OS notifications is not evidence that nested collective GC is unavailable. Preserve and prove actual sync flags, stack trip, condition variables, wake resources and explicit service until the last member leaves; final pstate/OS cleanup is the later destructive boundary.

P's cleanup sequence is close foreign admission -> cleanup_phase=1/setup_state=2 -> stop OS notifications -> seal registry -> admitted resize -> pstate/VM teardown. Any new helper failure must branch before the final teardown and must not reopen the cleanup gate. Also audit final collector notification paths against the sealed registry; direct per-VM GC service is not proof that every global completion notification succeeds after sealing.

## Minimal registration using an existing scanned slot

There is a smaller root carrier than a new global handler ABI. B `_thread#.scm`:2140–2184 defines a preallocated VM structure whose fields 2–8 and 10–16 are unused; header:6525 sets VM_SIZE=20. B setup.c:445–466 initializes every VM field false; mem.c:6573–6590 mark_vm_scmobj scans all VM_SIZE fields. The inspected retained P does not claim field 2. A bounded source search found no current use of the corresponding unused-field2 accessor.

**Proposed contract, not an implemented allocation:** repurpose VM structure slot 2 as `retire_owner`, containing an actual Scheme record/vector with completion procedure, transaction descriptor, saved threads, marker/pending result and generation. Give it matching Scheme accessor and C field macro. Keep VM_SIZE and existing handler label numbers unchanged. Publish a Scheme-created rooted record into this slot under the existing VM ownership discipline, without allocating between the last root read and slot publication. A native SCMOBJ field elsewhere would need explicit scanning and is not equivalent.

| Registration step | Concrete source hook / required operation |
| --- | --- |
| Code available | setup_modules followed by setup_kernel_handlers, B setup.c:6354–6370, establishes existing primitive/linker machinery. setup_kernel_handlers:5226–5244 currently binds fixed labels for return_to_c/break; **do not insert a label and shift that ABI**. Define a separate private Scheme procedure with normal generated primitive registration. |
| VM/threading ready | At the end of the C-target `##startup-threading!`, B `_thread.scm`:3181–3243, after VM/processor initialization, primordial/current-thread publication and interrupt-vector initialization, allocate/publish the per-VM retire_owner record containing that actual procedure. This new hook is required; setup_state and worker startup status are insufficient substitutes. |
| Worker ready | P:1819–1828 publishes initialized worker queues through ___processor_startup_complete; P:4880–4892 acknowledges scheduler_epoch/status | Reuse its existing semantics for workers. P0 is not proved ready by checking this worker status: P initializes scheduler_status to 0 and the startup-ready operation checks target>0. |
| Preflight | `current_vm_resize_admitted` / private bridge validates VM incarnation/record, current native owner==this VM's P0, current-thread and prepared stack/context, initialized helper procedure and no pending incompatible transaction. No runtime lookup/registration after destructive commit. |
| Last consumer | Keep retire_owner and procedure rooted through helper return, raw failure retention, pending activation/restore and every caller/error consumer. Clear only in actual VM teardown after all these claims have closed, not merely at setup_state=2 or scheduler stop. |

Field 2 availability is a pinned-source finding, not a reservation against the implementation worker. Before a real patch, reconcile with that selected producer's ownership. Allocation failure during startup leaves helper readiness false; do not publish a ready bit before the rooted record. The model's registration generation is a bounded key, not a counter-wraparound or arbitrary VM-reuse proof.

## Fixing execution on P0 requires more than a pin bit

B has a thread `pinned` field; scheduler stealing excludes pinned threads. P:1457–1472 also respects migration-target in queue selection, and P:1813–1814 excludes both from stealing. However P:1830–1858 `##thread-migrate-to!` performs explicit migration without rejecting an active private bridge merely because the thread is pinned. **Pinning prevents stealing, not every explicit migration or ordinary scheduler reentry.**

Proposed function-level order:

1. `retire_call_completion_p0`: validate actual current pstate/OS-thread/VM identity, P0 membership, correct epoch/incarnation and retire_owner. Claim an internal `bridge_active` phase before creating/entering the call frame. Root previous affinity state if it is an SCMOBJ; do not borrow a raw pointer to the processor object across GC.
2. Private `##retire-complete!`: execute only in the claimed P0 context; establish temporary P0 affinity on the actual helper carrier/current thread, preserve prior value, use a nonescaping internal procedure and structured Scheme exception-to-status handling. Preserve explicit GC/sync service even when ordinary asynchronous scheduling is inhibited.
3. `##thread-migrate-to!`: before THREAD_SAVE or queue publication, reject explicit migration when the **current execution** holds this internal bridge claim. `##thread-schedule!`, `##thread-reschedule!` and the helper's reachable calls need an equivalent no-ordinary-switch proof/guard. Avoid prohibiting legitimate scheduling merely because another processor owns a bridge. New user callbacks are outside the private helper contract.
4. Reuse P's `##lock-processor-with-sync-participation!` / scheduler-object trylock-and-service pattern where applicable; do not hold a ticket while waiting for a member that needs our GC participation. P already removes B's migration busy-loop workaround; it does not need another copy of that repair. Audit the actual helper's queue link/claim critical section for allocation/throw/polling.
5. Return through the original marker on its creating P0. Existing return_to_c wrong-processor detection is a fallback diagnostic that can call Scheme; it is not the proof of affinity. Restore previous affinity and clear bridge_active only at a proved matching-return cleanup boundary, with every exceptional branch retaining the claim until its owner disposes it.

These are bounded control checks around the existing scheduler/bridge, not a replacement scheduler. For a shutdown context with no valid current Scheme thread, setting a pin field is not an entry mechanism: that context must take a native-only no-helper path or a separately proved landing pad.

## Raw C unwind: defensible disposition and the missing recovery construction

**Existing gap in ___run:** B setup.c:3408–3417 calls kill_sfun_stack_marker only after ___call returns normally inside TRY. A raw throw jumps to END_TRY and skips the kill. The inspected P repairs public SFUN finalization and marker-proc rooting, but does not add an equivalent all-path finalizer to ___run. This is a source lifetime gap, not a native crash reproduction or proof that every retained marker is subsequently used.

A minimal necessary finalizer in `___run` must distinguish uninitialized allocation, live marker, matched return and escaped raw unwind. Store marker-initialized/ownership state in a setjmp-safe invocation-local record or appropriately volatile native state (marker is a still/refcounted object). Catcher restoration comes first; invalidate/release an initialized marker exactly once when its native host invocation is no longer returnable. Never run SFUN leave without having acquired a public SFUN lease. Root any movable error before subsequent allocation; longjmp_err/C++ throw_struct is not the new root owner. A nested host call needs separate invocation identity, not one overwritten global marker.

**Invalidating that marker does not normalize fp/R0.** It prevents an old saved Scheme continuation from pretending its departed C invocation is still returnable; it does not license overwriting fp with a stale saved C pointer, dropping current frame/continuation roots or rerunning the helper. Arbitrary native locks, callbacks and external borrowers also cannot be undone by changing the marker.

For valid P0 Scheme exit, a candidate smaller route is to finish necessary retirement/completion at a controlled **pre-exit Scheme landing point**, before `_kernel.scm`'s exit-with-err-code-no-cleanup calls propagate_error. Then the later raw exit need not enter a fresh Scheme helper during native cleanup. This requires defining shutdown's treatment of pending runnable work, exact exception semantics, worker-to-P0 exit dispatch, repeat/reentrant exit and root/GC closure; it is a proposed new hook, not an existing guarantee. Exit jobs/final wills run in exit-cleanup before this low-level propagate path, so their fallible/GC work must precede the final no-new-work cut. Abrupt exit and raw native faults need separate policies. A general fresh-context reconstruction after arbitrary unwind is **not yet justified as a small safe refactor**.

Until such a landing/disposition is proved, the defensible fallback is **RetainedUnsafeContext**, not normal bridge entry or successful teardown: retain known initialized roots/resources, record a stable failure via checked cleanup, prohibit further collecting helper entry/normal scheduling/destructive cleanup, and leave explicit host disposition outstanding. A raw failure inside a bridge additionally retains its live marker and transaction claim until nonreturnability/discard is proved. This is a terminal **model containment outcome only**, not restored VM usability, completed native shutdown or proof that concurrently running arbitrary code is contained. It requires external producer/admission and member-service assumptions; no peer is stopped by this study.

P's existing cleanup_phase=2 is useful for retaining failures but only records the returned error; a complete new raw-unwind descriptor/disposition is not supplied by that scalar. Its public void cleanup wrapper treats checked-cleanup failure as fatal. A real design must explicitly select checked failure/host fail-stop behavior and preserve original exit status plus secondary cleanup error; it cannot label fatal refusal as successful recovery.

## Unified model/source correspondence

`retirement_shutdown_bridge.qnt` extends the one P0/two-donor/two-epoch/three-GC bridge relation. It adds `boot` (code registered vs Scheme ready), `slot/reg` (scanned helper owner and bounded incarnation), `fresh` (matching/preflight-valid context), `sd` (runtime/prepared shutdown/raw shutdown), `pin/cpu`, separate `osOff/syncOK`, and `q/payload/dead` (retained unsafe-context obligations).

- registerKernelHelper then publishVMHelper precede normal preparation. A raw shutdown may retain before opening an epoch. `setup_state==1` is deliberately not the readiness condition.
- Prepared shutdown keeps sync service after OS notification stop. The predicate abstracts actual wake/round availability, not restoration of signal handlers.
- During a live bridge, pinning **and actual cpu==0** are required. An explicit migration control defeats a pin-only shortcut.
- Raw helper unwind enters bg=7 retained context; it does not pass through matchCaughtReturn, restore a fake fp or complete activation. No normal transition continues out of q. Deliberate negative mutations can attempt teardown, GC or root release there and are rejected.
- Retention satisfies conditional terminal containment, not normal completion. Normal prepared shutdown and retained raw-shutdown positives must be reported separately. The detailed execution token still represents one donor; arbitrary helper carriers, allocator internals, full C stack/locks and VM topology are not enumerated.

New controls reject setup-flag-only entry, absent/stale rooted helper registration, missing pin, explicit migration despite pin, raw-shutdown entry without matching context, teardown/GC/root release after retention, clearing the helper before its last consumer, treating OS notification shutdown as loss of sync service, and teardown before matching bridge return. Previous controls remain in the same relation. Root reachability, no ordinary resume and no destructive release are checked; raw-context recovery is not claimed.

## What can now be reused and what still must change

Existing: scanned VM structure storage and unused slot, per-VM initialization, primitive/linker registration, typed marker/proc roots, matched return-to-C, pin/steal exclusions, P's sync-aware locks and migration repair, independent OS notification and sync-request mechanisms, checked cleanup retention.

Necessary additions: late per-VM helper-ready publication; exact private-bridge P0/context claim and migration/scheduling exclusion; shared admitted-driver completion checks; all-path ___run marker finalization; a valid pre-exit landing/disposition or explicit checked retained-failure path. Root and error ownership must survive every one of these boundaries.

Still blocks production sufficiency: valid shutdown current-thread/stack preparation at each entry, concrete pre-exit/worker-origin dispatch and exception compatibility, post-raw-unwind context reconstruction/disposition, no-allocation/lock-escape proof of helper publication, real memory-order/epoch reuse, complete multi-VM/FFI/GC/join failures and first-eight/native/Gerbil acceptance under original budgets. No universal shutdown-ready claim or gate upgrade follows from this model.

Additional inspected notification definitions support that separation: B os_io.c:8583–8594 resets SIGPIPE/SIGCHLD handlers/masks; os_tty.c:8804ff resets user signal handlers/masks; os_time.c's conditional backends stop timers/heartbeat threads (for example 1461ff and 1633ff). They are not the per-pstate procedural mutex/select-abort cleanup. P:4435–4448 separately drains procedural callbacks and destroys that pstate mutex; that later path still needs the callback/last-consumer rules. These reads are source correspondence, not a host-specific native shutdown test.

## Executed bounded validation

All **83 checks accepted**: typecheck, 11 TLC safety/conditional-terminal positives (**eight normal-completion scenarios, one retained opaque suffix, two retained unsafe contexts**), 63 decoded negative controls and eight imported TypeScript trajectories. Retention is not recovery or shutdown completion. Original combined 30-second cap per check, 12 workers, 1 GiB heap, 8 MiB stack and capture limit remain.

| Positive | Terminal meaning | Distinct states | Seconds |
| --- | --- | --- | --- |
| initAbortTwice | Conditional normal completion | 336 | 7.241 |
| initAbortThenCommit | Conditional normal completion | 332 | 7.178 |
| initOpaqueSuffix | Retained opaque suffix | 168 | 7.234 |
| initImmediateErrors | Conditional normal completion | 336 | 7.208 |
| initRegisteredCCaller | Conditional normal completion | 336 | 7.173 |
| initDirectCPrepared | Conditional normal completion | 332 | 7.144 |
| initMarkerFailureRetry | Conditional normal completion | 338 | 7.623 |
| initCaughtSchemeRetry | Conditional normal completion | 344 | 7.248 |
| initShutdownPrepared | Conditional normal completion | 335 | 7.629 |
| initRawShutdownRetained | Retained unsafe context | 12 | 6.955 |
| initRawHelperRetained | Retained unsafe context | 133 | 7.044 |

Core model SHA256 `e86139dee2a55794ebbae30613c7f9aa041530a74accd6945a9caf31cd731e44`; imported trajectory SHA256 `eda0d54efa71daed3f0e8920e59c7888a2b149bac6b4630e151afaa5a4fa1f55`. [Published receipt](../evidence/research/smp-retirement-study/shutdown-context-validation.json) retains exact source/checker identities, decoded distinguishing witnesses and raw audit `76538e8ed8dd4b39a84c7887ce2fca0a`. The 231 own registered children were reconciled through existing APIs. Primary source identities match the preceding study and remained stable; supplementary notification-definition identities are separately labeled. No runtime or native execution.
