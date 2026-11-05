# Shrink admission, rooted hints and request-release ownership

2026-10-24. Implementation handoff for Grok against main7c490c3 and `scan-session-cut.lock.json` (patch0949fbbf). This is a specification plus bounded model evidence, not applied runtime code. The audit changes evidence only. It refines the preceding function matrix; earlier8/8 native evidence does not admit the new protocol.

## Independent decision

For the first integrated producer, choose **collective early refusal whenever delivery responsibility remains**, rather than attempt to run Scheme or retire an active donor inside the C resize collective. This gives a bounded fail-fast behavior with preserved roots and the old cohort. It does not guarantee a shrink eventually succeeds under an infinite flood or a nonreturning thunk. Queued-hint transfer is an optional optimization with stricter eligibility, not a precondition for shipping this conservative safety policy.

A second correction is necessary: actual mutex owner alone is not sufficient during a partially completed unlock. Current slow unlock removes the old owner-list entry before changing the owner field. The release commit needs a no-escape region; cleanup must not blindly repeat that unlink.

Neither correction supplies the existing lifecycle errno transcript, fixes TFIB, or changes8/12.

## Actual source boundaries

| Current source | Established behavior | Consequence for the implementation |
|---|---|---|
| `setup.c:1644` `execute_sync_op(OP_VM_RESIZE)` →1364 `___vm_resize_pstate` | All elected resize participants enter the native operation. Existing result round uses `OP_VM_RESIZE_RESULT`, then returns the common error. | Put the new common guard **before** calling1364. Do not return only from P0 while others descend into BARRIER. |
| `___vm_resize_pstate:1400` | P0 writes target_processor_count_; growth changes startup_epoch. Heap guard and possible GC follow at1413ff. | Guard must precede these writes, not merely precede OP_SET_PROCESSOR_COUNT. Rejection cannot be described as side-effect-free if target bookkeeping was already changed. |
| `setup.c:1510..1523` | Shrink writes handler_quiet/join_pending/pending_join_count before OP_SET_PROCESSOR_COUNT. | No delivery-busy rejection after this prefix. Preserve all these fields on refusal. |
| `barrier_sync_op:896..913` | P0 updates processor_count in the selected operation; VM registry readers bracket the count change. | This does not establish delivery quiescence. The VM-list reader gate is not a request/hint/continuation reference counter. |
| `setup.c:1450..1475` donor exit | Removes blocked-P deque links, cleans native interrupt/OS state, sets handler_quiet, calls thread_exit. | No Scheme hint callback/continuation materialization landing is present here. Do not add ordinary Scheme execution to this native tail. |
| `setup.c:1263..1299` donor checks | Test native GC workers/work queues/still chains, not Scheme high-level queues. | They cannot witness hint transfer or active request-frame completion. |
| `mem.c:7786..7819`, strong phase8118/8134 | `mark_processor_scmobj` marks the active P object's whole body; P0 marks VM object. Hints in a P head/tail chain and closure fields are real Scheme roots while that root domain is scanned. | A count/pin is not itself a root. Removing a P from future GC participation cannot rely on its native pointer retaining Scheme values. |
| `_thread#.scm:1994` processor layout | Fields20/21 are Scheme high-level head/tail; hints and ordinary processor procedures share this queue. | Relocate only explicitly tagged, target-rerouting hints. Moving a normal processor procedure to P0 changes its execution-location contract. |
| `_thread.scm:4020..4119` slow unlock | Old-owner deq removal precedes waiter BTQ/TOQ removal and link to new owner. Runnable insertion precedes final mutex unlock. | A naked owner snapshot and the reference's thunk-completed flag are insufficient. Separate preparation, atomic ownership commit and remaining wake responsibility. |
| `_thread#.scm:1116..1140` link/unlink macros | Link inserts in the thread-owned deq then sets owner; unlink initializes links then sets state. | Owner value and list membership form a protected transition, not two independent recovery predicates. |
| `_thread.scm:1819` `##btq-abandon!` | Assumes an owned linked BTQ; first removes its owner-list entry. | Do not call twice, after transfer, or on a half-unlinked mutex. |

## A. Complete responsibility accounting and early common refusal

Add a VM-native `delivery_admission` word with Closed plus count under **one** atomic modification order. Reuse the *algorithm shape* of the current registry gate, not the registry's state or count. Use checked, nonwrapping increments, actual supported lock-free word atomics, and an explicit generation/lifetime binding. Initialize before publishing this VM to any producer. Do not reset it on a shrink/retry while borrowers remain.

Count every accepted responsibility until its last consumer: initial issuer/route activation before any participating lock, queued/active request, synchronous sender's wait/result read, fresh-hint allocation/queue/dispatch/forwarding, and post-unlock cleanup/return activation. Some responsibility groups overlap; their pins must not collapse into a single decrement at thunk return. Async requests still keep target/handler responsibility after the issuer returns. Each owner stops all resource access before its final decrement. Physical roots are the current T/P queues, mapped Scheme frames and receiver root, independently of the native count.

Use CAS Open,count→Open,count+unit before entering a T/P/SYNC path. Shrink uses CAS Open,0→Closed,0. Release is a checked decrement on the same word. SC atomics are the straightforward first implementation; a different release/acquire implementation needs its own C memory-model argument. The QNT abstracts an indivisible word and does not prove compiler/hardware lowering. A zero load followed by a separate close store is forbidden.

At elected `execute_sync_op(OP_VM_RESIZE)`, add a native `delivery_shrink_guard` **before** `___vm_resize_pstate`. P0 tries the zero-count close; every old member receives the same result in an explicit guard-result phase using the existing fixed-round result transport. Check phase identity; do not assign a new opcode number by guesswork. No Scheme callbacks, allocation or T/P lock acquisition in this guard. A failed guard returns a common genuine busy/error status through the existing resize result/loop, with old count, target count, startup/join fields, queues and roots preserved. Do not set pending or invent an OS join error. A callback requesting shrink while its own pin is live gets refusal, never waits for itself.

A successful zero-count guard keeps delivery admission closed through the count/root-domain change and the stable result boundary. Reopen only after the survivors have acknowledged the matching resize generation/result and no old delivery accessor survives. Do not infer this from P0 finishing a local barrier call. On a mismatched/failed result/ACK retain the generation and Closed gate, rather than publish a new incarnation or fake completion. Native sync/bootstrap tails retain their **separate** lifetime accounting.

**Required ingress audit:** current C `___raise_high_level_interrupt_pstate` is void and the reference raw-id bridge is unchecked. An external producer not registered before queue access invalidates the zero-count conclusion. Before enabling concurrent shrink, convert all relevant queue publishers/consumers to checked admission with visible refusal/defer responsibility, or establish and test host quiescence under the existing lifetime contract. A void no-op or a spin inside a callback is not a solution. Existing external/native ABI paths outside that contract remain unsupported; this handoff does not grant arbitrary stale C pointers admission.

This conservative guard can change resize availability and fault-exit behavior. A permanent-fault coordinator cannot bypass it while accepted requests remain live: it must finish real abandonment/drain, or retain the VM/resources and take the declared terminal failure. An old graceful-fault receipt cannot be relabeled as still passing if the new producer only retains/fails. These compatibility controls belong to the same producer's regression set.

## B. Optional queued-hint handoff: exact roots and last ownership

Only consider this after the early-refusal path works. Eligibility requires all donor-local executing/cleanup/issuer/native-reader activations gone, target thread already owned/rooted on a surviving scheduler domain, and only **explicitly tagged relocatable delivery hints** remaining. A reference two-field procedure hint has no such tag; add an internal explicit kind/target representation and regenerate its callers. Generic P procedures, donor-pinned/running threads, raw C procedural nodes, unknown layout, and active callbacks are ineligible and cause precommit refusal.

Actual order, under closed publishing admission and a **proved** no-GC/no-reentrant-mutator transaction:

1. Root the receiver through the existing surviving P Scheme queue or a separately installed, scanned carrier. A C local `___SCMOBJ` without saved-map/RC registration is not a root.
2. Install the new traced reference before removing the donor's last root. Validate all required queue links/head/tail; preserve ordering and opaque procedure semantics. The transfer performs no callback/allocation/GC and does not acquire a lock held by a participating member. Collective arrival by itself does not prove participants arrived without T/P locks or cached queue references; a valid preparation boundary is required.
3. Commit unique queue ownership and detach/reset donor links only inside that transaction. On any failure before this commit, donor keeps the root and ownership. Unknown partial transfer retains the generation/roots; do not reset and retry a splice blindly.
4. Acknowledge receiver root/ownership and old accessor exit before count/domain removal. After commit, receiver owns hint→target routing; the donor performs no access after its last pin release. Post-commit GC must scan the receiver's actual head/closure, not a cached scalar value.

`mark_processor_scmobj` supplies the existing scanned receiver root. `owner_service_batch`1734/`ack_service_window`1760 are explicitly native/no-callback windows and do not implement this preparation, rooting or ACK. They must not be described as an implemented transfer. Without a proven preparation path, stay with early refusal. Do not attempt to migrate a live donor Scheme frame merely by moving its hint.

## C. Actual mutex owner, partial unlink and exception cleanup

Preferred request-specific implementation:

1. Keep dynamic protection from thunk through result publication and real release. Reuse current heap precheck and lock-drop/SYNC retry **before** any destructive owner-list/BTQ mutation. Preserve immutable target and pending outcome/error in mapped frames.
2. Prepare target/possible sender/waiter/TOQ/destination-P locks with try/release/retry and revalidate actual head, owner, linked state and route after each participation. Do not block a collective with a reserved ticket. This is a request-specific checked release path, not a rollback to an older generic unlock.
3. Once preparation succeeds, enter a bounded no-allocation/no-SYNC/no-callback/no-escape commit: unlink old owner once; unlink waiter/timeout once; publish actual new mutex owner/state and resume disposition; install the selected runnable/root handoff. A mapped release activation may hold the pending-wake thread after physical ownership transfer; this is a rooted WakePending responsibility, not a completed wake. Make ordering explicit in generated C. No fallible acquisition or safepoint is allowed halfway through this sequence. If necessary, move an existing helper's participating lock acquisition into preparation.
If ordinary Scheme code generation inserts a safepoint/call inside the prepared ownership commit, move just that prepared bounded field-store transaction into a private no-allocation C leaf (for example `___thread_intr_release_commit`) behind a generated checked bridge with explicit register/root preservation. Do not hand-edit `_thread.c`, insert GC-capable tree/lock work into the leaf, or make the leaf responsible for callbacks. Native fault inside it is a retained terminal fault, not a Scheme recovery path.

4. After owner transfer, do not abandon or overwrite the published success/failure just because the release helper has not returned. Keep wake/cleanup and sender-result pins until their actual last use. A completed logical result is not zero lifetime debt. If runnable insertion follows the ownership commit, retain the mapped waiter and wake pin, reacquire/revalidate its T/scheduler membership before insertion, and skip an already completed/running handoff; an enqueue failure retains this wake responsibility. Do not lose or insert a waiter twice after removing it from its old BTQ.
5. `##thread-intr-abandon-owned!` acquires target T and mutex under the current order, then revalidates **current** owner and release stage under the locks that protect mutation. If target still owns a fully linked, precommit mutex, use a checked/extracted locked abandonment body exactly once. Do not take the mutex lock twice. If any lock is dropped before mutation, recheck rather than use the snapshot.
6. If owner is sender or already unlinked/not-owned after sender consumption, cleanup does not alter success, deq or sender ownership. If an unexpected fault finds old owner but partial unlink, retain pins/roots and record an incomplete/fault disposition; do not call raw `##btq-abandon!` or claim recovery. A native longjmp bypassing dynamic-wind is not covered by the Scheme helper.

This corrects the preceding matrix's unlock-M-then-call-raw-abandon sketch: that sketch is acceptable only with a proof no ownership mutation can intervene and no partial unlink exists. Prefer keeping validation and mutation inside the checked helper's protected transaction. The actual owner check is necessary but not sufficient; a `released?` boolean, `completed?` thunk flag or diagnostic phase cannot substitute for the transaction.

## Conditional QNT and what it establishes

`models/gambit/delivery_shrink_release.qnt` models publisher-frame, donor queue, survivor queue and dispatch-frame roots; explicit sender and executor consumers; common refusal before mutation; atomic zero-count closure; an eligible receiver-root transfer; actual owner transfer/consumption; partial-unlink retention; and last-release access. Positive blocked-donor refusal does not assume the donor returns. Handoff positive assumes eligibility and the no-GC transfer transaction; it is not a proof that the current C provides either.

The count has abstract responsibility bundles. Sender/executor liveness remains explicit and a bundle can be released only after both actual consumers end. It is not a claim that the native K count equals the model's small integer. GC checks root domains separately from count.

Mutants distinguish: unregistered publisher, open zero check followed by publication, P0-only rejection, target bookkeeping changed before refusal, donor-root removal before receiver rooting, raw untraced carrier, blind abandon after transfer, stale owner snapshot, early lifetime drop, post-release access, owner-only cleanup of partial unlink, and release before sender consumption. Reachability controls require actual reject/commit/abandon/consume/retain states, preventing vacuous reject-everything success. There is no fairness/liveness or C11 memory-order proof. The earlier26-check version is retained separately and is superseded, not added to the final count.

## Grok same-producer acceptance order

1. Bind current lock plus extra headers, generated SMP C, compiler/flags, objects/archive, final GSI SHA/UUID and fixtures. Implement complete accounting/guard and checked request release before optional nonempty handoff. No native loop or test is executed by this evidence audit.
2. Use controlled publisher cuts **after registration/before queue insertion**, queued hint, active thunk, result transferred/before helper return, and sender before result consumption. Shrink must return the same refusal to all old members before target/pending/count changes. Check roots with actual GC while the old cohort remains active. No barrier waits on an actor whose T/P lock the test holds.
3. Empty-debt control must shrink successfully. A callback's self-triggered shrink must refuse without self-wait. Continuous flood/blocked donor tests establish bounded refusal, not eventual shrink. Test growth/reuse never resets a live delivery generation.
4. For nonempty transfer, first prove eligibility and receiver root using actual generated C/RC/scanned P queue. Test eligible hint with surviving target, ineligible ordinary P procedure, donor-pinned target, active callback, publisher/native reader in flight, and GC before/after the transaction. Every ineligible case must refuse unchanged. Do not enable transfer if locked/foreign/native-sync preparation is unproved.
5. Exercise both no-waiter and waiter release branches at before-preparation, before-commit, after-actual-transfer/pre-return and after-sender-consumption cuts. Normal target ownership gives one real abandonment; sender/no-owner gives none. An injected partial-commit observation is an expected retained fault, not successful cleanup. Do not inject Scheme callbacks while holding the very locks cleanup needs.
6. Run nested/migration/exception/continuation and permanent-wake-fault controls, including the prior graceful-fault expectations. Then run the retained two8-round p11 flood batches under the existing12-second per-round cap and focused controls under their existing30-second caps. No parameter/heap relaxation, no whole inventory, no fixture expectation rewrite. One binary through the entire set; source/binary drift invalidates the comparison.

Record actual admitted/refused status, responsibility owner/count/generation, real T/P lock state, source and receiver roots/queue owners, selected cohort/result phase, target/join fields before/after, actual mutex owner and link/release stage, exactly-once unlink/wake/consume, GC payload check, timeout/exit and real process quiescence. Missing cuts/ACK, unavailable root maps or a retained fault are not a successful shrink/release receipt.

## Sufficiency judgment

The **logical safety** of the refusal path can close without promising eventual shrink: closed admission plus complete accounting, common early refusal, preserved old root domain and correct last-consumer release. It does not need arbitrary donor callbacks to terminate. Nonempty hint transfer and recoverable partial unlock do **not** close merely from owner equality or current donor checks. The concrete changes are the pre-call collective guard, full responsibility accounting, checked release preparation/commit, and optional rooted/tagged transfer only after legal preparation exists. Current C/generated-code/native evidence for those changes is still required. Do not mark9/12 or describe TFIB as fixed on this model's result.


## Retained final verification

Final model SHA256 `c6be670a5a12a05d56bd4d517dc9da8f16c69188e8a8cff971f8c150915dd3c8`:9 safety checks,12 expected decoded mutant witnesses and9 positive reachability witnesses (30 controls), each under the unchanged30-second cap. Receipt `.cache/tasks/repair-9-12/processes/audit/runs/60109b25f92046f0949e454c9e949954/outputs/delivery-shrink-release/receipt.json`, SHA256 `3763bb6b89648379783292576dc576b97325453da91c32e25242e95d40a2bdf0`. The earlier26-control version and its failures/receipts remain historical; they are not added to30. Native executions:0. Source refinement admission:false.

### 2026-10-24 commit/entry/return refinement

See [delivery-commit-entry-return.md](delivery-commit-entry-return.md). Generic unlock is not a no-GC leaf; all delivery entrances and the native procedural callback error/cleanup edges must be covered. Common refusal includes original winner result transport and outer sfun reopen; stale-phase retention is a distinct fault path. The new40 controls are conditional specifications, not a runtime certificate.
