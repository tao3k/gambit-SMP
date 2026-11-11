# scan-session-cut: actual implementation versus conditional QNT

2026-10-24. Source authority is scan-session-cut.lock.json, main7c490c3, cumulative patch0949fbbf52fa77cf60bfd30135dcd2f0d1a32620ca2b0ec4678d53c20aace40a. All26 candidate files were reconstructed from SHA-checked base bytes and verified against this lock. Current source copies, exhaustive selected-symbol references and parsed function return indexes are retained in the source audit referenced by the companion JSON. No managed producer, runtime, qualifier, Recipe or historical receipt is changed. No native compilation/execution, whole inventory, peer action, commit or push. The41 prior QNT controls are reused by exact hash; none is rerun or relabeled as new native acceptance.

## Implemented conditions

| Mechanism | Actual current functions/fields | Source conclusion / QNT boundary |
| --- | --- | --- |
| First setup consumption | mem.c3940 ___gc_diag_begin_setup consumes setup_seen once; setup.c7756 calls it after admission/parameter validation and before state resets. Repeat calls close session. | Implemented for the serialized host contract. QNT SetupRetry/RepeatSetup/BeforePrepareFailure describe the required consumed-session behavior; error-exit close is separately incomplete below. |
| Prepared mapping versus open session | prepare4017 publishes pointer/bind-state2 then opens only if setup_eligible; close3933 revokes open, never resets claims or unmaps. | Mapping retention no longer grants a second session. PREPARING/READY helper reentry returns without spinning. QNT helper reentry is conditional on modeled atomic steps, not proof of C host concurrency. |
| Same-epoch retry entry | setup_pstate zeroes attached/session/slot/eligible/pending/private pointers, then claim5858. Claim4104 again clears local capability before CAS. | Retry at the identical pstate address cannot inherit the first capability: owner claim is already used and the CAS refuses. This part of LocalRetry is implemented. Immediate failure-exit revocation is not. |
| One-use selected-VM claim | claim requires selected vmstate0, open state2, fresh parent slot and EMPTY->CLAIMED CAS; payload precedes release READY; local eligible is set last. owner_matches3965 acquire-checks READY, session, slot, ps and vms. | No old sequence adoption or VM-local-id-only grant remains. A failed fresh-slot check retains CLAIMED. QNT one-use claims apply; actual selected-VM validity and caller/pointer legality remain source/API premises. |
| Committed cut token | publish4200 zeroes output, returns0 on refusal/exhaustion, consumes matching pending cut once, invalidates footer before overwrite, release-commits then returns seq. | Source now implements token and cut5 ordering conditions. Partial cuts4/5/3 exit84/85/86 before complete footer; cut6 exits87 after complete commit. QNT MixedCut5 and TokenBeforeFooter remain discriminating controls, not current native failures. |
| Both actual loads | CELL4414 and HEADER4440 each use a fresh local committed_cut and token; NULL probe requires token!=0 and matching cut. Original cell/header loads remain later. | A stale stack cut cannot alone authorize either injection. Cuts1/2 are still null-probe survival controls, not evidence that the original selected GC address faulted. |

## Complete setup return audit and remaining edits

These are current coordinates, not the previous prepare-lock line numbers.

| Current path | Present behavior | Grok action |
| --- | --- | --- |
| ___setup returns7749/7753 | Cleanup-admission or parameter rejection precedes begin_setup. | Preserve: no new session consumption/closure on those rejects. |
| ___setup returns7828/7848 | P0 interrupt-init and global OS/memory failures explicitly close the session. | Implemented. Preserve runtime errno and cleanup order; published mapping remains retained. |
| ___setup return7870 | init_symkey_glo2 failure returns directly after mapping preparation/setup_state1, with no diagnostic close. | **Missing.** Add a diagnostic close before this direct error return. Do not substitute pending/errno or alter runtime error semantics. |
| ___setup breaks7882/7898/7906/7917 and error from ___run ->7957/7959 | Error cleanup invokes ___cleanup; ___cleanup_checked closes only after its admission checks. Earlier refusal invokes ___fatal_error through ___cleanup. | **Not an unconditional close proof.** Close diagnostics explicitly before calling error cleanup. Do not rely on a default fatal handler's termination to establish the diagnostic invariant; no claim is made here that fatal_error actually returns. |
| ___setup_pstate errors5868/5878/5942 | Claim precedes interrupt/OS-memory/sync setup. Interrupt failure returns directly; other failures call cleanup_failed_pstate, which only cleans interrupts/OS/memory/logs. | **Missing at failure exit.** Revoke this local capability/pending request before cleanup/error return; leave the one-use process claim consumed and other owners/session open. |
| ___setup_pstate success5947 | Local claim remains valid. | Preserve. Do not move claim only to the final success point: that would drop diagnostics for GC during constructor allocation. |
| ___setup_vmstate errors6157/6166 | Failures precede P0 construction/claim. | Preserve existing cleanup; do not clear another owner's claim or globally close a still-live process because a child VM failed. |
| ___setup_vmstate success6178 | P0 setup and ___publish_mem_vmstate succeeded. | Preserve. |
| ___setup_vmstate publication failure ->6192 | cleanup_sync_op_pstate occurs before cleanup_failed_pstate. No diagnostic revoke precedes it. | **Missing.** Revoke the failed P0 local capability before the first teardown action, not only after sync cleanup. Retain native claim history. |
| ___cleanup_checked returns6258/6265/6282/6293 | Admission refusal or no-op before close6294. | For a live runtime's independent cleanup refusal, preserve recording. For a failed global setup, the explicit caller-side error close above must already have happened. |
| ___cleanup_checked returns6313/6329/6360 | Accepted cleanup closes first; empty-VM success, resize failure retained, and normal cleanup all remain closed. | Implemented for session admission; not a native reclamation proof. |

### Minimal local revocation helper

Proposed internal `___gc_diag_revoke_pstate(ps)` clears eligible first, then pending_cut/legacy cut/session/slot/attached/coverage and detaches pointers to the initialized private records (or disables them consistently with all guards). It performs no GC, allocation, callback, waiting, native claim reset or shared-bank write. It must not reset another owner, native READY/CLAIMED, setup_seen, session serial, shared seq or mapping. Local seq should remain non-reusable; the next constructor already initializes it but cannot reclaim the consumed slot.

Call it at cleanup_failed_pstate entry before existing cleanup. Also call it explicitly for the interrupt-init error return5868, which bypasses that helper. For VM publication failure, call it before cleanup_sync_op_pstate. Idempotent duplicate revocation is acceptable. Revoke on the currently owning control path after a synchronous constructor operation returns, not concurrently against an executing scanner. A constructor that nonlocally escapes instead of returning is outside this return-path proof and must not be called a recovered failure.

This is a narrow diagnostic capability edit. It is not permission to change runtime cleanup, join ownership or scan-domain retirement. Immediately after a failed constructor, current eligible/session/native READY can still match until the next constructor entry clears them; therefore entry-clearing alone does not prove failure-exit safety. No real exploitation, SIGSEGV causality or post-free helper execution is claimed by this source finding.

## Pending-cut lifetime: correct the earlier correspondence

Actual outer mark_array exit4598..4601 clears depth and legacy gc_diag_cut, **not gc_diag_pending_cut**. An unmatched HEADER cut can therefore survive a mark_array call that only scanned immediate words. This is not automatically a defect: the next matching admitted HEADER can legitimately occur in another array invocation within the same GC. Blindly clearing pending at every array exit could prevent the intended control from ever firing.

The existing QNT endScanUnmatched transition is a cancellation policy event; it is **not implemented by the current legacy-cut reset**. For targeted acceptance, map it to the fixture's explicit successful ___gc_diag_arm(ps,0) after the declared operation finishes without reaching the selected cut. Record NOT_REACHED in the control receipt. Current arm0 clears pending even after admission is revoked, provided the pstate descriptor remains legally live. Do not call it on a destroyed VM/pstate.

If a bounded GC-level lifetime is desired instead, define and implement that specific GC-return boundary and change the correspondence separately. No new automatic GC/array cancellation hook is required merely to validate the two source fixes above. Duplicate nonzero arm is already rejected; publication refusal/exhaustion clears pending; normal matching publication consumes it once. A close alone currently rejects later operations rather than iterating every pending pstate field.

## Exact QNT reuse, not a new C proof

Prior model: scan_session_commit.qnt SHA2159be973e5752050c26a27839464a2c75a30b561aedf61a2432e4abc73bfa4c. Its15 safety checks,11 mutant traces and15 positive reachability witnesses stay bound to their original verification receipt. This audit confirms bytes and maps them to the new C; it does not rerun them against an executable or promote their source lock.

- LocalRetry/LocalStaleCapability constrain the **retry entry**: clear local capability, reject the used slot, preserve another READY owner. The atomic localFailureRetry model transition combines failure and retry-entry clearing. It does not model the interval after C failure but before that entry. The current missing exit revocation is therefore **not proved by that positive**. Native observation must check both cuts separately; a future split-transition model must retain this distinction.
- OwnerSetupFailure/PartialClaim retain process claim history, but need the return-audit revoke hooks before they refine the complete C failure path.
- SetupRetry/BeforePrepareFailure/PrepareFailure require global failure admission to stay closed. Current7828/7848 meet it; direct7870 and unconditional pre-error-cleanup close remain missing.
- MixedCut5/TokenBeforeFooter/UncommittedCut/OldToken map to implemented invalidation, zero outputs and exact per-call return checks. Actual target object/gsi identity, generated code and native signal records are still required.
- CloseInflight allows an already admitted writer to finish into retained storage; it does not permit a new arm/publish after close. Selected-VM checks, valid external contexts, C atomic memory order and actual GC roots remain separate premises.
- Nested-writer rejection is an abstract nonoverwrite control; actual nested mark_array clears coverage. Once coverage is lost, later armed publication must refuse and cannot be counted as full native coverage.

The model's cancellation and combined retry actions cannot be silently treated as literal C statements. Those are the important remaining refinement boundaries, not reasons to rerun unchanged model checks.

## Grok same-producer targeted acceptance

Implement only the explicit global closes and local revocation above; keep committed-token/footer logic unchanged unless a targeted failure establishes otherwise. Under legitimate exclusive custody, freeze one producer using its actual compiler/configuration: lock, modified source, configured header, generated fixture C, objects/archive/gsi hashes and executable UUID. The reported Apple-clang mem.o ordering is a separate object observation; it does not bind a linked gsi or substitute the producer flags. No relink between controls.

1. Inject the direct init_symkey_glo2 error and each later setup break/error cleanup cut. Before any fatal-handler callback or cleanup refusal can intervene, observe closed diagnostic admission. Preserve original runtime error, mapping retention and used claims. Include the pre-prepare interrupt failure and global memory failure as existing-positive controls. Pre-admission/invalid-parameter rejects must not consume a session.
2. Use a failed **spare worker slot in an otherwise live selected VM**, with another valid owner remaining active. Exercise interrupt init, OS/memory and sync-init errors after READY claim. Observe eligibility0/pending0 immediately at the failed exit, before retry; then retry in the same global epoch and require claim refusal, unchanged shared bytes and another owner's continued valid recording. Do not call helpers through a freed VM pointer. If failure destroys the descriptor, snapshot inside the owned cleanup hook before destruction instead.
3. For VM memory-publication failure after P0 is ready, snapshot local revocation **before** sync teardown. Retry cannot reclaim it. Separate this from child-VM failures before claim, which must not revoke the selected live owner globally.
4. Arm then close/coverage-loss/exhaustion: refuse publication with token0 and committed_cut0; no null fault. Wrong-stage scans preserve pending until a match or explicit cancellation. When the declared operation completes unmatched, call real arm0 and record NOT_REACHED; a second nonzero arm must then be fresh, not silently overwrite an old request.
5. On that same producer establish a complete baseline, then cuts4/5/3 must leave current rejected and prior complete baseline intact; retain raw84/85/86. Cut6 yields exact committed seq and raw87. Cuts1/2 require this invocation's committed token/stage and preserve raw SIGSEGV. Neither NULL probe proves the original cell/header load faulted.
6. Recover the historical two-worker fixture/argv/env/topology before claiming a comparison. Keep its original20 seconds, require both GC/worker returns and joins, raw exit0/timeout=false, all writers quiescent and hashed carrier before final parent release. It remains unlocated here. A new targeted fixture can be evidence under its own name, never a replacement historical receipt. Do not run the whole inventory, increase90/3600/20-second limits, change qualifier/history, or call these controls9/12.

Receipts must distinguish immediate failure-exit revocation from retry-entry refusal, and explicit cancellation from automatic array-return behavior. Source-only checks and the prior conditional QNT are insufficient to admit the missing native gates.
