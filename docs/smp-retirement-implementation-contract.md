# Gate 9 implementation contract: preparation cuts, queue ownership, epochs and typed roots

2026-10-22. Work item repair-9-12. Design and executed finite research only. Native acceptance remains **8/12**. This specifies proposed edits; it does not edit runtime code or operate the implementation worker.

B denotes vendor Gambit 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882; P denotes retained handler-quiet-while-pending-cumulative.patch SHA256 8d2181df5f5878c0f1ab2c321425f935ede86c0786c09f39c5636ae82f2aa8c7. P numbers are patch-file lines. Findings apply to this pinned research source, not an uninspected moving Grok producer.

## The three cuts, concrete owners and operations

| Cut | Existing call sites | Proposed exact condition / publication | Forbidden shortcut |
| --- | --- | --- | --- |
| **C1 local callback completion** | cleanup_interrupts_pstate B setup.c:396–417; release_procedural_interrupt B:158–166 | On each donor, one callback has returned or been caught locally; its persistent cursor/status/error root is settled. Publish `(retire_epoch, retire_status=Ready/Failed)` only after no callback remains on that donor and its queue disposition is known. | Queue empty, dequeue complete, or a callback throwing out of the collective does not establish return/quiescence. Local Ready does not authorize source-root removal or leaving service. |
| **C2 global preparation closure** | ___vm_resize_pstate P:4704ff; execute_sync_op_loop B:1049–1116, retained growth extension P:4920–5013 | P0 coordinates a same-old-cohort decision round: every member's C1 and every remaining P0 fallible/root preparation completed; current GC finished; no admitted producer can add preparation work. Success/abort decision is tagged with this transaction epoch. | A local `gc==0` read, first observed error, or all donor statuses without P0 closure. Do not offer OP_SET_PROCESSOR_COUNT or enter join before this cut. |
| **C3 common completion / authorized return** | proposed abort/commit operation in existing dispatcher; outer ___current_vm_resize P:5090–5105; shrink/recovery join P:4650–4697,4833–4870 | Abort: old cohort observes current-epoch decision/acks, source coverage and queue disposition are settled, and common completion authorizes outer returns; then admission may reopen. Success: exact typed handoff and no-fallible-work cut precede count change; only OS exit tail/join/resource record remains. | An individual abort ack permitting early return; outer ON_THROW reopening admission before peers finish; changing count back after partly destroyed workers to pretend rollback. |

`barrier_sync_op` already has round-specific sync messages and snapshots processor_count (B:541–714). Reuse its actual round/return protocol. New integer counters are not a replacement for it. Nested on_all_processors offers its own request; do not infer parent re-election merely from a suspended resize C frame. Outer preparation must keep serving while nested GC returns to its own caller.

## Smaller queue refactor: pop one request, retain the suffix in the existing queue

The earlier bounded-prefix detachment design is possible but introduces suffix reattachment ownership. The smaller preferred source adaptation uses the structure already present in service_procedural_interrupts_pstate B:170–200:

1. Close the supported raw-producer lifetime externally: stop issuing work and drain/join admitted native producers. The raw void export ___raise_procedural_interrupt_pstate B:365–392 has no admission check. SFUN/registry gates do not close this population. No new flag can repair already dangling raw pointers.
2. Under procedural_interrupts_mut, pop **one** head, update head/tail, and persist callback progress/in-flight state for this epoch. Unlock before execute_fn(self,false). The uncalled suffix remains in the existing queue, owned by the old pstate; no copied suffix list or reattachment is needed on a recoverable abort.
3. Enter a local supported runtime catcher on the same OS thread. Record next/progress before external code; after callback return or throw, never inspect or requeue self, which may already have freed itself. An ordinary return error is handled as well as a supported throw. Persistent state avoids indeterminate nonvolatile locals across setjmp.
4. On success, continue finite admitted cleanup while servicing nested GC as required. On failure, stop invoking further callbacks on that donor, retain the untouched suffix, publish Failed and remain in old-cohort service. Successful callbacks on other donors are not replayed. Failure aborts shrink; it does not reverse callback effects.
5. At C3, resume ordinary queue service only if the never-invoked suffix is still independently owned/live under the callback contract. Rearm INTR_OTHER after unlocking when pending requests must be serviced; B:389–392 and service_interrupts_pstate B:211–242 show existing wake/retry mechanisms. Do not silently clear the pending flag and strand the suffix. Queue ordering relative to any newly admitted producers must use the existing mutex after admission is reopened.

If full-prefix detachment is retained instead, its head/tail need explicit phase ownership; only a proven live never-invoked suffix may be returned under mutex. Invoked nodes cannot be requeued. This is an alternative with extra proof burden, not the minimum default.

**Unresolved contract, not a pointer-validation algorithm:** an arbitrary callback may invalidate another node/resource. The header's function-pointer type (B header:11585–11589) does not promise self-only disposal, no queue mutation, or continued worker usability. A callback that frees Y while Y is still queued already defeats the ownership premise of ordinary queue service. Do not walk a questionable suffix to test whether its pointers are alive. For that unsupported/unknown case, retain an opaque failure record and refuse normal resume/cleanup traversal until an explicit owner disposition exists; terminal retention is not successful recovery. If such cross-node effects must be supported, the callback API needs a stable independent request-owner protocol, exceeding this small internal refactor.

### Additional source defect to avoid copying

B service_procedural_interrupts_pstate unlocks the queue before execute_fn(...,true), breaks on non-NO_ERR, then executes the function's unconditional final mutex unlock without the success-path relock (B:190–200). This is a source-visible **conditional lock imbalance** on the error branch. It is not a demonstrated cause of the native 9/12 failure. Do not call that service function as the preparation helper: it also uses true rather than release(false). A helper sharing the pop/unlock pattern must make lock ownership explicit on every return/throw. The current cleanup(false) loop instead ignores errors and holds its mutex across callbacks, so it is not a drop-in recoverable helper either.

## Minimal fields: typed state, not one more done boolean

Proposed names are specification names, not existing symbols. Avoid redundant fields where the exact selected producer already has equivalent ownership.

| Owner / location | Minimal semantic state | Initialization and last consumer |
| --- | --- | --- |
| VM, header near existing lifecycle/startup fields | `retire_epoch`, `retire_phase` (Preparing, Deciding, Aborting, Committing, Complete), old/target counts, saved request rooted handle, first-error attribution | Exclusive resize owner initializes before publication. Keep separate from startup_epoch unless equal lifetime/meaning is proved. Request handle lives through outer result consumption; no raw SCMOBJ in an unscanned VM field. |
| Each old pstate | `(retire_epoch, retire_status)` and callback in-flight/progress/disposition; rooted error handle when needed | Initialize every epoch before participating. Publish own status after persistent callback outcome. A Failed donor remains a participant. With one-node pop there is no need for new detached-prefix head/tail fields. |
| Abort acknowledgement / operation | Exact current epoch and decision, observed through existing collective protocol | Existing message sequence may discharge ack storage; if stored, compare full `(VM lifetime, transaction epoch, member/incarnation)` under the existing owner. Do not accept `ack!=0`, `ack>=1`, or a startup-ready bit. |
| Per-slot join/recovery record | OS handle state, slot incarnation, exact join outcome, transfer completion, terminal-retained vs recovered | Used after C3 success. Preserve the successful-join event so recovery does not rejoin it; aggregate errno/success cannot discharge another slot's failure. Current quiet=false-after-success reachability remains a separate proof, not an automatic observed defect. |

For repeated epochs, finish all prior callback/result/queue consumers before reinitialization; then publish the new epoch before statuses/acks become eligible. Reset cursors/in-flight/error disposition and root contents at actual new entry. Old acknowledgement values may remain physically stored if equality rejects them. Incarnation and VM lifetime must not alias reused storage. Refuse/wait for safe quiescence before epoch overflow/reuse; the finite two-epoch check does not establish native counter wraparound or arbitrary stale-reader safety. No new process-global ID allocator is implied.

## Actual root and work classes: what may be retained, transferred or excluded

| Class / source fields | Actual scanner or consumer | Required retirement correspondence |
| --- | --- | --- |
| Movable SCMOBJ in `r`, `saved`, `type_cache` | mark_registers/mark_saved/mark_type_cache B mem.c:6508–6553 | Keep donor participating through prepare/abort. At successful withdrawal, prove each live value is already represented elsewhere or transfer through a supported traced location. Do not claim caches/frames are dead merely because release callbacks returned. Root locations are updated by GC; reload values. |
| Active Scheme continuation / fp, frame RA/link/gcmap | mark_continuation B:3898–3966; move_continuation after weak phase B:6902 | Preserve existing generated frame interpretation. P:956–976 migrates the initiating Scheme continuation to P0, which is useful but not a census of all donor frames. No raw frame copy or native C activation migration. Unsupported live origin frames block withdrawal. |
| Scheme processor object, its high-level interrupt queue and VM links | mark_processor_scmobj B:6556–6570; high-level enqueue/dequeue B setup.c:258–312 | This Scheme queue is distinct from native procedural request headers. Deque unlink P:4757–4776 changes reachability; audit surviving thread/VM links before dropping pstate scanning. A native suffix pointer is not automatically traced via this object. |
| RC blocks / `rc_head_` | mark_rc scans **header.data only**, B:3969–3991; P:3579–3582 scans per participating processor | Save request on a surviving owner; donor-local error handles can be preallocated/registered locally and scanned while old cohort lives. Only data is an SCMOBJ root; arbitrary C payload fields are not. ___data_rc reload after GC; ___release_rc after last result/callback consumer. Avoid unsynchronized remote mutation of P0's RC list. |
| Still objects / still_objs_, external refcount | setup_still_objs_to_scan B:4210–4233; later scanner; ___transfer_mem_pstate P:3301–3353 | Preserve refcount/graph interpretation. Existing transfer moves still/RC lists and counters only; its joined-donor/borrower-drain premise is not a live-preparation handoff theorem. A valid pre-withdrawal quiescent transfer or alternative surviving scanner owner must be proved. |
| Nonexecuting/executable will lists; testator versus action | scan weak case B:4040–4065; determine_will_executability B:4996–5029; process_wills B:5032–5110; weak phase B:6872–6902 | Action is strong; testator is weak during initial reachability. Determine executable status before the subsequent testator marking/list migration. Preserve tagged list links/ownership. Turning every field into a strong RC root can suppress finalizer eligibility. Existing still/RC transfer does not move will lists. |
| Weak-key/value GC hash tables / reached_gc_hash_tables_ | weak flags in scan B:4069ff and subsequent GC hash processing | Preserve existing weak policy and phase ordering, not a generic strong-root carrier. New model does not cover the full hash-table/ephemeron semantics. |
| Private scan_ptr_, chunk FIFO/frontiers, still_objs_to_scan_, scan workers | header:11383–11403; P:3545–3574 termination recheck | These are GC work/borrower state, not just roots. Require actual publication/scanner return and same-cohort phase completion; do not root an unfinished chunk to pretend work drained. |
| VM/global Scheme roots | mark_vm_scmobj/mark_global_variables B:6573–6630 and GC call sites B:6847–6852 | Preserve P0/global partition coverage. They do not automatically cover arbitrary new VM C fields. |
| Procedural native request self/next, C payloads, catcher/longjmp errors | B setup.c:143–166,365–417; header:9981–9986 and11585–11589 | Native ownership is separate from GC roots. If returned error is encoded immediate, no movable root is needed; if supported payload is movable, retain it in an actual traced slot before another GC. The function-pointer ABI alone guarantees neither property. A catcher requires a live origin activation through unwind. |

The QNT extension represents RC data, frame-root coverage and an isolated will/testator discriminator. It does not execute Gambit's collector or establish the full census above. In its isolated will scenario the testator has no other strong path; initial strongification makes the will nonexecutable, matching the source discriminator. Later marking of the testator is legal **after** that determination. It is not a model in which a testator must disappear immediately in the same GC.

## Smallest required edit surfaces for gate 9

1. **setup.c callback preparation:** replace the shrink path's GC-capable cleanup-after-withdrawal with a preparation-only pop-one/unlocked release(false)/local-catcher helper and explicit suffix/error policy. Leave postcommit OS-only cleanup separate. Fix/audit lock pairing in any ordinary-service helper that is reused or touched. Unknown callback contracts remain an admission blocker, not a success flag.
2. **setup.c collective dispatcher and resize owner:** distinguish outer preparation from nested service, implement C1 -> C2 -> C3 on the old cohort, defer outer throw/admission reopening, and enforce epoch identity/reset. Header declarations hold the minimal state. Reuse existing sync rounds; preserve independent VM behavior and existing root/termination barriers.
3. **mem.c plus setup.c typed withdrawal boundary:** establish actual strong-root/list/work coverage before publishing smaller count, including join-failure cases where a withdrawn OS thread remains live. Do not blindly move the existing joined-donor helper earlier. Unsupported live root/work classes must prevent commit; safe refusal alone does not close the success inventory.
4. **setup.c shrink/recover bookkeeping:** one shared per-slot join/transfer state contract, no duplicate successful join, exact incarnation error attribution, retained postcommit failures distinct from successful recovery. Keep OS errors and partial cleanup evidence.

These are four responsibility surfaces, primarily setup.c with header declarations and a source-proved mem.c handoff; not four promised one-line patches. No scheduler/collector replacement, generated frame ABI redesign or new lifecycle framework is proposed. Exact changed lines cannot be finalized against the other worker's producer without inspecting it, which this study deliberately does not do. Before implementing any new field/helper, compare whether that candidate already supplies the invariant.

This is the minimal **necessary** contract derived from the pinned source, not a claim that these edits are sufficient for all native faults. Gate 9 still requires the full legal fault/rollback/drain/reuse inventory on the causal implementation and regression of the first eight. Gate 10's full GC/FFI root census is not silently converted into a gate-9 model pass.

## New QNT coverage and limits

retirement_epoch_queue_roots.qnt executes **two complete preparation epochs** for a recoverable abort: X is invoked once and may self-free; Y is never invoked by preparation, remains queue-owned, and is serviced once after common abort. The next epoch cannot open until the old error is consumed/root released and Y's service completes. Old epoch-1 ack values remain stored at epoch-2 entry, proving equality rejects them; callback cursors reset. A second positive checks an invalidated suffix is retained opaquely and normal resume refused. That is containment, explicitly not successful recovery.

Ten decoded controls: access freed X; return invalid Y to usable queue; replay invoked X; accept real prior-epoch acks in epoch 2; save SCMOBJ only in unscanned RC payload; strongify weak testator before will determination; withdraw frame coverage; discard will-list owner; resume despite opaque suffix failure; carry old callback cursor into epoch 2. Two explicit trajectories check repeated epochs and invalid-suffix refusal.

This composes at the ownership-contract level with the prior multi-donor/two-GC model. It is **not** a single exhaustive product of arbitrary donors, GC rounds, queue lengths, callback effects and epoch counts. Each check retains the existing combined 30-second cap, 12 workers, 1 GiB heap and8 MiB stack. Weak-fair conditional completion assumes all modeled finite callbacks/actors progress. Real atomics, callback side-effect independence, source-to-model refinement, counter wraparound and complete native acceptance remain open. Existing models/results and parser-failure history are preserved.


## Actual results

| Check | Result | Distinct states | Seconds |
| --- | --- | --- | --- |
| typecheck | PASS | n/a | 0.558 |
| initResumeTwoEpochs | PASS | 38 | 4.220 |
| initInvalidSuffixRetained | PASS | 18 | 4.111 |
| initFreedCursor | Decoded expected counterexample | 4 | 4.116 |
| initBlindReattach | Decoded expected counterexample | 8 | 4.146 |
| initReplayInvoked | Decoded expected counterexample | 4 | 4.476 |
| initStaleEpoch | Decoded expected counterexample | 45 | 5.995 |
| initUnscannedPayload | Decoded expected counterexample | 5 | 5.861 |
| initStrongifyWeak | Decoded expected counterexample | 6 | 5.586 |
| initWithdrawFrame | Decoded expected counterexample | 5 | 5.555 |
| initDropWillOwner | Decoded expected counterexample | 5 | 4.493 |
| initUnsafeResume | Decoded expected counterexample | 16 | 4.496 |
| initStaleCursor | Decoded expected counterexample | 23 | 4.627 |
| reuseResetsCursorAndRejectsOldAcks | PASS | n/a | 0.651 |
| invalidSuffixPreventsResume | PASS | n/a | 0.623 |

All fifteen checks accepted. Source identities stable; raw run `.cache/tasks/repair-9-12/processes/audit/runs/e7609713ad54403497ed5a1d6704c50e/outputs/epoch-queue-roots`; model SHA256 `8bb357fb8ef90e08aea64202a506901005c3b1cd8c3b572c1867441ef9a430f7`. No runtime/native execution.


## Unified successor

The [integrated function-level handoff](smp-retirement-integrated-plan.md) supersedes the prior separate-component coverage limitation for the stated finite combined path. It does not remove callback-contract, C refinement, complete root/work census, OS outcome, capacity or native acceptance obligations. Existing component files/receipts are preserved.
