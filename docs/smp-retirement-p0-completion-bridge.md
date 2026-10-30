# P0 raw c-lambda and direct-C completion bridge

2026-10-22, repair-9-12. Research only; native acceptance remains **8/12**. This refines the [safe-point protocol](smp-retirement-safe-point-protocol.md). No runtime/framework/compiler/Recipe/budget changes, native execution or implementation-worker operations.

Sources are B = Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882 and P = retained `handler-quiet-while-pending-cumulative.patch`, SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. P references are patch-file lines; this does not inspect the other worker's producer.

## Finding and preferred small refactor

There is an actual C-to-Scheme primitive: **`___call`**, B setup.c:3276–3388. It builds a return-to-C frame on the Scheme stack, installs the marker and original R0, enters the trampoline, and returns normally only on a matching `UNWIND_C_STACK` destination. It can be the basis of a private P0 completion bridge while the outer resize C activation remains alive. P0 therefore need not return an internal token through its public raw c-lambda merely to enter Scheme. Direct C callers can share this bridge **when they are the current P0 owner with a valid prepared Scheme context**.

This is a concrete reusable control mechanism, not yet a complete executable implementation. The bridge must be placed outside an unfinished collective round, preserve actual GC-visible context/descriptor roots, distinguish matching normal return from raw unwind, and run only a private nonescaping completion procedure. The existing public SFUN wrapper is not the bridge: its admission check rejects entry while the retirement gate is closed. Reopening admission to call it breaks the transaction. `___run` is not a drop-in alternative: it resets R0 to handler_break before entering Scheme.

## Existing call paths and exact return semantics

| Path / source | Existing behavior | Consequence for completion |
| --- | --- | --- |
| P Scheme wrapper `_kernel.scm`, P:956–976; B raw c-lambda:2353–2362 | Migrates initiating Scheme caller to P0, then calls `___current_vm_resize` | Keep the external c-lambda signature and return only the final result. An internal helper request must not escape as its SCMOBJ result. |
| Generated B `_kernel.c`:26342–26366; header:10325–10326,10366–10372 | Stores arguments/RA in generated frame, publishes register context through CFUN_CTX/W_ALL, calls out-of-line C, then reloads through R_ALL | Existing outer Scheme frame can remain in the scanned Scheme stack while a nested C-to-Scheme call runs. The local `___arg1` or saved raw fp in arbitrary C code is not an additional traced root. |
| Public `___current_vm_resize`, P:5067–5103 | Closes admission, calls `current_vm_resize_admitted`, then reopens; ON_THROW also reopens and rethrows | Completion and safe unwind must finish inside the admitted driver before either reopen branch. Its present outer catch is not sufficient cleanup for a new nested bridge. |
| `current_vm_resize_admitted`, P:5056–5065 | Builds an automatic sync-op request, invokes `on_all_processors`, returns arg[0] | Add a persistent rooted transaction and a bounded internal service/completion driver. If an internal round returns, no pointer to an expired automatic sync-op request may survive. |
| Shutdown, P:5698–5708 | Calls **current_vm_resize_admitted directly**, checks its error, then cleans pstate/VM | Putting helper completion only in the public C wrapper or Scheme wrapper misses this path. Shared admitted driver must resolve or preserve pending completion before returning to teardown. Actual shutdown context/helper availability still needs a source/runtime proof. |
| `___make_sfun_stack_marker`, B c_intf.c:6511–6547; `___make_vector`, mem.c:1778–1815 | Marker is a **still vector with initial refcount 1** for nonnull ps; element0 proc, element1 processor ID | Marker address itself is stable while retained; its procedure slot is scanned. Marker creation may collect or fail; preallocation/ownership must be established before a destructive commit. |
| `___call`, setup.c:3340ff | Saves old PSR0 and marker into return frame, installs return_to_c RA, nargs, pc and SELF, invokes trampoline | Use actual generated call conventions and prepared stack space. Do not memcpy C activations, restore a stale raw fp after GC, or assume all unrelated GVM registers survive unchanged. |
| `return_to_c`, B `_kernel.scm`:1017–1073 | Checks processor ID, detects false/dead marker, spills frame/registers and throws UNWIND_C_STACK | Existing wrong-processor path may invoke a Scheme handler; this is not proof the private helper stays pinned. Forbid helper migration, escaping continuations and ordinary thread scheduling by an actual source contract. Preserve GC service. |
| Matching return, setup.c:3375–3388 | After catcher restoration, accepts only UNWIND_C_STACK with **this marker** at frame slot; advances fp and restores original PSR0; returns NO_ERR | This is internal reentry into the still-live outer C activation. It is not external API completion and not a helper success status by itself. Read the helper outcome from its rooted descriptor/result protocol. |
| Nonmatching/error return, same source | Calls `___throw_error` before normal frame pop/R0 restore | Arbitrary raw C throw/nonlocal escape does **not** establish a restored original context. Never blindly retry ___call, drop its marker or reopen the gate as if normal matching return occurred. |
| `___kill_sfun_stack_marker`, c_intf.c:6555–6562 | Sets marker[0]=false and decrements still refcount | Kill exactly once after matching return, or after a separately proved exceptional cleanup/continuation discard. Never invalidate it while its Scheme return frame can still be used. |

### Correction to the preceding source note

The preceding document accurately quoted the TODO in **B**, but did not account for P's corresponding repair. **P:2074–2090 already wraps marker allocation with `GC_SAVE1/GC_RESTORE1(proc_or_false)` and removes that TODO.** Thus proc-or-false protection across marker allocation is an existing B+P guarantee, not a remaining mandatory repair at that site. P:783–789 also clears saved scratch and releases the public SFUN lease on allocation throw. This does not root every new descriptor/local automatically, and it does not make shared `ps->saved[]` a nestable root stack.

## Proposed function-level control sequence

These are proposed names/responsibilities, not runtime code added by this study.

1. **`current_vm_resize_admitted`** creates/retains an epoch/incarnation-tagged descriptor while old context and membership are intact. Validate current OS-thread pstate, P0 ownership, prepared Scheme stack/space, helper availability and allowed origin before C2. Preallocate/retain a private still marker and traced helper/descriptor carrier where possible, so marker allocation failure can abort before commit. Keep per-slot join and completion claims separate.
2. **`execute_sync_op_loop` plus a retirement-aware internal round helper** returns a tagged internal request only after a completed round: ContinueService, CallP0Completion, SchemeDonorCompletion or Terminal. The driver retains its public C activation. Consume an elected request once; derive waiting offers from persistent phase, with GC priority above waiting preparation. Do not leave other members blocked in an unfinished barrier when invoking Scheme. Normal GC/sync callers can retain their current wrapper interface; no public new lifecycle API is required merely for this internal state.
3. **Private `retire_call_completion_p0(ps, descriptor)`** verifies exact owner/epoch and the closed gate, roots the procedure/descriptor and any movable pending result, and preserves the outer generated context in scanned storage. Use a zero-argument private helper reading a traced transaction owner, or correctly generated argument marshaling; do not fabricate PUSH_ARGS from guessed offsets. Install a scoped catcher, invoke `___call`, and distinguish matching NO_ERR from exceptional unwind. Any C fields across setjmp must obey the existing volatile/persistent-state rules.
4. **Private Scheme `##retire-complete!`** runs on P0 without migration, arbitrary callbacks, continuation escape or ordinary scheduler reentry. It can service/produce GC under the outcome's correct cohort, then claims and publishes one saved thread owner. Its ordinary Scheme exceptions are caught **inside Scheme** and converted into a descriptor status, followed by ordinary return through its matching marker. It must not restore the donor's saved user thread on P0: abort donor restore belongs to that donor's own safe-point path.
5. **Bridge finish** reads a current rooted status after the last helper GC, invalidates/releases the marker only after matching return, and restores/resumes the outer C driver through the existing return frame rather than a stale C snapshot. C3-success plus helper failure remains CommittedPending; C3-abort plus helper failure remains AbortPending. Neither is terminal success. Recovery is conditional on the fault/ownership contract, never reversal of C3-success membership.
6. **Final driver completion** requires every execution-owner completion/restore obligation, current result-root ownership, and explicit disposition of pending joins. Only now may public `___current_vm_resize` reopen admission and return/rethrow. Shared shutdown caller must refuse teardown on any pending completion. Direct C result retention still needs an explicit caller root if the value can move across later Scheme/GC entry.

Minimal changed surfaces are the admitted C driver + retirement dispatch return contract, one private C bridge/descriptor declaration, one private Scheme completion entry and donor safe-point helper, and the existing error/join completion checks. Reuse current compiler frame ABI and collector. The newly discovered P marker-root repair needs **no duplicate fix**. Changing only a Scheme wrapper, only the public C wrapper or merely adding a marker cannot cover the full call graph.

A lower-risk alternative is a Scheme begin/poll/finish wrapper for Scheme callers plus explicit refusal for unsupported C callers, but it narrows the API. It does not satisfy required successful direct-C/shutdown coverage. The private shared bridge is preferred for preserving the blocking C interface; its context/error proofs below remain requirements, not accomplished facts.

## Root and error coverage through every crossing

| Interval | Required owner / actual last consumer |
| --- | --- |
| Before marker allocation | Existing generated frame and traced transaction carrier retain current Scheme execution, helper proc, descriptor, thunk and pending movable result. P's GC_SAVE1 protects only the marker proc argument during this allocation. |
| Marker allocated, before call | Still marker refcount owns its bytes/procedure slot; descriptor has an independent traced owner. Do not use generic saved[0] across arbitrary nested allocation: SAVE writes and RESTORE clears it, rather than pushing/popping a stack. |
| Scheme helper / nested GC | Actual call return frame owns marker and original RA; typed descriptor/RC/still roots cover parked threads and payloads. Full collector return updates references. No raw fp/context pointer retained in a C local is permission to overwrite the new fp. |
| Caught Scheme exception | Catch and store a movable error in traced descriptor before any further collecting work. Then return normally to this marker. B ___call returns NO_ERR for control return, so a separate status distinguishes operation failure. |
| Marker allocation error before ___call | No new return frame was installed. Keep admission closed; release only initialized resources, then abort before C2 or retain/retry a postcommit pending record. Preallocate before C2 to avoid making this an ordinary postcommit allocation dependency. |
| Raw C unwind / mismatched marker | Scoped catcher restoration alone does not restore fp/R0. Retain descriptor/error and establish a proven exceptional return/discard path before cleanup. If no such path exists, supported controlled-failure policy is required; successful recovery remains unproved. No arbitrary user continuation may escape the private helper. |
| Matching return before marker kill | Reload helper result/status from current root, kill marker once, retain pending descriptor until activation/restore and caller result are settled. |
| Final public return | Existing generated CFUN writes final SCMOBJ into PSR1, then R_ALL/continuation return. Keep this final-read-to-PSR1 interval free of collecting work. External C callers do not obtain that Scheme caller root automatically. |

P's public SFUN counter is not a substitute for this internal completion claim: publicly entering while gate is closed fails, while bypassing it indiscriminately would admit foreign work. The private bridge needs exact current-owner/epoch authorization, prohibits nested public resize/teardown, and remains a live origin until its matched return and cleanup finish. No blanket public-admission bypass or temporary gate reopen is proposed.

## Unified model refinement and its exact scope

`retirement_p0_bridge.qnt` keeps the single prior two-donor/two-epoch/three-GC relation. It adds explicit bridge stages: bg=0 idle/retry, 1 rooted prepared context, 2 live marker, 3 Scheme entry, 4 matched return, 5 completed bridge, 6 caught failure/status. `roots/bv` retain and relocate bridge-owned payloads; `ctx` records intact outer-context authorization, `mk` marker lifetime, `gv` closed gate, `attempt/bf` one bounded failure/retry scenario, `entry` the entry case, `fault` forbidden control paths.

Ordinary success/abort, a **prepared P0 direct-C** caller, marker allocation failure and **Scheme-caught** helper failure are positives. Caught helper status must pass `matchCaughtReturn` before cleanup/retry; it is not raw C unwinding. A retry scenario is an ownership/control feasibility proof under recoverable finite failure, not a native retry policy or unlimited retry loop. Production marker preparation should precede C2; the model also tests retaining pending ownership if that fallible step occurs late. No capacity/timing acceptance follows.

The full helper GC updates bridge root versions alongside prior thread/error/list roots. Existing old/new cohort selection is preserved. Marker allocation's own nested GC is represented by the root-entry contract, not separately enumerated allocator internals. `ctx` abstracts the true generated frame/return path; it is not evidence that saving a pointer or copying a C register structure restores it. Claim/link updates and Scheme exception conversion remain abstract atomic transitions requiring source refinement.

New negative controls reject missing bridge roots, public SFUN entry through a closed gate, temporary reopening, ___run-style original-context clobber, wrong marker treated as a normal return, nested resize, early marker kill, stale bridge payload after GC, final API return before bridge close, caught-error cleanup bypass, entry from an unprepared/wrong direct-C context, and blind ordinary resume after raw C unwind. Source-real guards may reject these before the modeled failure; a model counterexample is not a native bug reproduction.

## Remaining proof obligations

- Prepared P0 context/stack-space proof at each real entry: raw c-lambda, admitted direct C owner, child/root shutdown, startup/no-Scheme and foreign/SFUN callers. Do not infer valid execution context merely from a nonnull pstate or processor ID zero. Shutdown still has unresolved helper/context readiness; the prepared-C positive does not qualify it.
- Exact generated helper registration, nested frame/RA layout, scoped catcher behavior in setjmp and C++ configurations, rooting before the first allocation, matching-marker return and complete raw-unwind disposition. P's existing proc protection reduces this work but does not complete it.
- Helper pinning and nonescape, no ordinary scheduler reentry before publication is consistent, GC-safe locks, structured exception-to-status conversion and post-publication partial-fault idempotence. Existing return_to_c wrong-processor/multiple-return detection is detection, not a completion proof.
- Runtime visibility, collective wait arbitration and barrier generation, multi-donor activation completion, origin/admission lifetime, full native fault/FFI/GC/join and first-eight regression tests within original budgets. Native acceptance remains 8/12.

### Entry admission and minimal persistent fields

A direct C call on a departing/non-P0 native thread cannot be made safe by moving its C activation to P0. Reject it before preparation or implement an explicit P0-owned request protocol with the caller retained until completion; that protocol is additional work, not supplied here. A direct P0 call without a valid current generated context/initialized Scheme runtime is also outside the prepared-C positive. For shutdown, helper invocation must precede pstate/VM teardown and requires actual initialization/remaining-root proof at that call site.

Proposed descriptor fields for the private bridge are `completion_proc` and `completion_payload` in actual scanned storage, `completion_marker` with initialized/live ownership, `completion_epoch/incarnation`, `bridge_phase`, `bridge_owner`, and a traced `pending_error/result`. Native scalars may describe phase/claims; native SCMOBJ fields are not traced merely by declaration. Existing generated frames and marker-return mechanics supply outer execution coverage; a raw `saved_fp` member is deliberately not an executable restoration protocol. Resolve/register the private Scheme procedure at initialization or prepare it before C2; there is no existing `retire-complete` procedure to look up for free at commit. Choosing its generated primitive/handler registration and root binding is part of the remaining implementation delta.

Use the low-level marker and ___call protocol only in the private admitted owner, with its own complete cleanup contract. Do not partially expand public SFUN macros, skip their enter, and then execute their END_SFUN: P's END_SFUN also performs `___sfun_frame_leave`, which would release a lease never acquired. Conversely, marking the new internal bridge as a public foreign entry would encounter the closed gate. There is no need to duplicate or weaken public SFUN admission to represent the owner's internal completion obligation.

## Executed validation and retained history

All **65 checks accepted**: typecheck, eight TLC safety/conditional-completion positives, 51 decoded negative controls and five TypeScript trajectories on the same imported transition module. Original combined 30-second per-check cap, 12 workers, 1 GiB heap, 8 MiB stack and compiler capture limit remain.

| Positive | Distinct states | Seconds |
| --- | --- | --- |
| initAbortTwice | 334 | 16.529 |
| initAbortThenCommit | 330 | 12.171 |
| initOpaqueSuffix | 166 | 6.98 |
| initImmediateErrors | 334 | 6.932 |
| initRegisteredCCaller | 334 | 7.928 |
| initDirectCPrepared | 330 | 8.941 |
| initMarkerFailureRetry | 336 | 10.186 |
| initCaughtSchemeRetry | 342 | 9.481 |

Core model SHA256 `0dece1e4f7e817c174cfe4356efc1f93523b04bd345e86433ea4e739602e80c1`; trajectory SHA256 `1f29e59a174682c8be240643a092d76f8a6f486f9c4443ff48ba42ecef32e0d8`. [Validation receipt](../evidence/research/smp-retirement-study/p0-bridge-validation.json) retains exact checker/model/source identities and decoded distinguishing witnesses. Existing compact field mapping remains [here](../models/gambit/retirement_safe_point_fields.json); new bridge fields keep their explicit names.

Initial audit `a69aa08192db4678a88c05d69844ada2` was stopped by signaling only its identified own research supervisor when source inspection invalidated the error-cleanup abstraction; partial results remain historical and are not reused as qualification. Existing APIs reconciled its 24 registered children and resumed audit custody. Corrected audit `ebd9928b58fe477e999e597f1635abd3` executes the changed relation; its 183 own children are reconciled. No peer process was operated on. Runtime source hashes match the previous audit and remain unchanged. No native execution or gate upgrade.


## Shutdown entry successor

The [shutdown audit](smp-retirement-shutdown-context.md) resolves why the prepared-C positive cannot be generalized: setup_state is published before Scheme readiness, and ordinary Scheme exit may raw-unwind rather than match-return. It specifies a per-VM scanned slot registration and P0 claim, identifies explicit migration despite pinning, and narrows raw unwind to retained failure until a landing/disposition is proved. Existing ___run marker kill is only on normal return. OS notification stop and synchronous GC service are separate. New unified results separate normal completion from retained-context terminals; no native sufficiency claim.
