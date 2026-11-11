# Split constructor failure window and refused global error cleanup

2026-10-24. Evidence and implementation handoff only. Source binding remains scan-session-cut.lock.json/main7c490c3/patch0949fbbf, not vendor HEAD. No runtime, qualifier, Recipe or historical receipt edits, peer operations, native campaign, commit or push. The previous41-control model is retained unchanged. This new QNT slice separates boundaries that its combined localFailureRetry transition could not establish.

## Required C edits, in implementation order

### A. Revoke a failed local constructor before any cleanup/return

Add internal `___gc_diag_revoke_pstate(ps)` in mem.c and declare it in internal mem.h under the same SMP conditions as the existing helpers. The synchronous caller must own a live pstate descriptor, with no scanner concurrently executing on it. The helper performs only native immediate-field writes; no allocation, GC, callback, mutex, wait or destruction:

```
eligible = 0                 // first: future owner_matches cannot grant
pending_cut = 0; cut = 0
attached = 0; coverage = 0
session = 0; slot = -1
prev_p = &private_prev; cur_p = &private_cur
```

Do not clear native owner READY/CLAIMED, setup_seen, session_serial, shared owner/seq/records, mapping or local sequence. Detaching local pointers is not permission to reclaim shared storage. A duplicate call is harmless. The old native claim stays consumed; the next constructor already clears local state and will fail its one-use claim CAS. Do not move the original claim only to constructor success: diagnostic GC during allocation would then be lost.

Call order on the exact locked setup.c:

1. **Interrupt error5868**: setup_interrupts_pstate returns an error -> revoke local diagnostic capability -> return that same error. This branch bypasses cleanup_failed_pstate; patching only that helper misses it.
2. **OS/memory error5878**: operation returns error -> cleanup_failed_pstate entry revokes -> existing interrupt/OS-memory/log cleanup -> return same error.
3. **Sync error5942**: setup_sync_op_pstate returns error -> same revoke at cleanup_failed_pstate entry -> existing cleanup -> same error.
4. **VM memory publication failure after P0 READY, return6192**: ___publish_mem_vmstate returns error -> revoke the failed P0 **before cleanup_sync_op_pstate** -> existing sync teardown -> cleanup_failed_pstate (idempotent revoke) -> existing VM abort prefix -> return same error. Revoke only inside this failed-after-P0 path; early VM errors6157/6166 have not claimed P0 and must not accidentally revoke another owner.

Do not close the global diagnostic session for one worker's failure. Another already-ready owner in the stable VM must remain capable of recording. A whole global setup failure may subsequently close the session through its own error path.

### B. Close before the global direct error return

At ___setup7870, wrap the init_symkey_glo2 error branch so ___gc_diag_close_session executes before returning err. This direct return is after setup_state1 and preparation but does not use the final cleanup branch. Preserve the original error and runtime cleanup semantics. The existing global failures7828/7848 already close; pre-admission returns7749/7753 stay before session consumption.

### C. Close before invoking global error cleanup

At ___setup7955..7959 use an error block: close diagnostics first, then call ___cleanup, then preserve the existing return if control returns normally. Do not rely on ___cleanup_checked6294 for this invariant:6258/6265/6282/6293 can leave before that close. On cleanup refusal ___cleanup invokes ___fatal_error. A fatal-handler callback/nonlocal escape is not a successful cleanup or a normal setup error return; the diagnostic session must already be closed before that handoff.

Keep the existing ___cleanup_checked6294 close after its admission checks for **independent cleanup of an otherwise live runtime**. Moving that close above every admission check would disable diagnostics even when an ordinary live cleanup was refused. Error-setup close belongs at its caller. This distinction is part of the model and the native controls.

## QNT events and the actual empty interval

New model: `models/gambit/scan_failure_handoff.qnt`. Replay: `evidence/research/smp-retirement-study/verify-scan-failure-handoff.py`. It models the following separate events:

```
synchronous operation reports failure
 -> local revoke (or deliberate mutant omits/delays it)
 -> cleanup entry / error return exposes the failed context
 -> owned still-live-descriptor observation, before any retry
 -> retry entry clears local fields
 -> used-slot refusal in the same global epoch
```

The safety obligation begins at cleanup/return exposure, not at an arbitrary CPU instruction immediately after error recognition. The straight-line revoke may not introduce a safepoint/callback between detection and revocation. Observation before retry is a real distinct model state. The RetryOnly mutant still clears local fields at retry entry, yet fails earlier at the error return. LateArm checks a separate invariant and continues to the observation: it admits the stale capability before retry. Thus the earlier combined transition no longer hides this interval.

For global errors the sequence is failure -> caller pre-close -> cleanup invocation -> accepted cleanup or refusal -> fatal-handler handoff -> normal process termination or possible host nonlocal escape -> later setup remains diagnostic-ineligible. The refusal negative checks `closedOnRefusal`, so its counterexample must actually reach a refused cleanup, not merely stop at an earlier open gate. A separate live-cleanup-refusal positive must leave the existing session usable.

Model controls cover interrupt, OS/memory, sync and VM publication failure; direct global failure; accepted/refused global error cleanup; failure before preparation; and live cleanup refusal. Mutants delay revocation until retry, omit local revocation, revoke after sync cleanup, omit global direct close, depend on refused cleanup to close, admit a stale arm, globally close on a local failure, or close on a live cleanup refusal. Positive reachability controls exclude the vacuous solution of never exposing a failure or refusing every operation.

This is a conditional protocol model, not current-C acceptance. A pstate descriptor is assumed legally live at the observation point and owned by the controller; a failed native slot is not assumed to be a runnable Scheme thread. A controlled stale-arm witness does not establish that an ordinary Scheme caller can reach that failed processor. Published mappings and consumed claim history stay retained. No actual setjmp/longjmp path, concurrent C field visibility, arbitrary host callback behavior, generated root maps, OS resource teardown or eventual callback completion is proved. Both fatal termination and host escape are modeled possibilities; neither is reported as a newly observed Darwin result.

## Same final producer: targeted native acceptance for Grok

Implement A, B and C together, then build/freeze one producer under legitimate exclusive custody using its actual compiler and flags. Record lock/source/configured header/generated fixture C/object/archive/gsi hashes and UUID. No relinking between rows. Execute actual helpers through the existing registered native harness; copied standalone helpers are not evidence.

1. **Spare-worker controls**: keep one valid owner active in an otherwise live selected VM. Fail a spare slot at interrupt, OS-memory and sync setup, after the diagnostic claim. At the cleanup-entry/error-return hook capture eligible/session/slot/pending/attached/coverage/native owner state and shared-bank hash **before retry**. They must show local revocation and consumed native claim; the other owner/session remains usable. Then retry the identical slot in the same global epoch: it must remain diagnostic-ineligible and leave shared bytes unchanged.
2. **Legal observation boundary**: for a failed spare slot whose native descriptor and VM remain live, test the real arm helper between failed return and retry; expect refusal. Do not invoke any helper after the descriptor/VM was destroyed. Where a failed P0 teardown destroys its context, take the observation inside the owned pre-teardown hook instead.
3. **VM-publication control**: fail ___publish_mem_vmstate after P0 setup succeeds. Snapshot revocation before the first cleanup_sync_op_pstate action; require it to remain revoked through common cleanup and abort. Repeated revoke must not reset native claims or shared records.
4. **Direct symkey error**: inject the actual init_symkey_glo2 failure; observe session_open0 before direct return7870, with original err preserved. Separately keep pre-prepare/global-memory failures as existing-positive controls. Invalid setup parameters before consumption must not spend a new session.
5. **Error cleanup refusal**: from a failed global setup, make the real cleanup admission refuse before6294. Observe session_open0 at cleanup entry, refusal and fatal-handler entry. In an explicitly supported owned handler-escape control, escape without claiming cleanup success; retain mapping/claims, then require a later serialized setup to keep diagnostics disabled. A default process-exit outcome is retained separately. If no legal handler-escape harness exists, mark that native path uncovered; do not simulate a returned cleanup or rewrite its status.
6. **Independent live cleanup refusal**: without a preceding setup failure, refuse cleanup admission. Existing diagnostic session/other owner must remain usable. This detects a tempting but incorrect global fix that closes before every cleanup check.
7. **Token regressions on that unchanged producer**: arm then revoke/coverage-loss/close/exhaustion must produce token0 and cut0 with no null fault; match CELL/HEADER tokens exactly; preserve the baseline across partial cuts4/5/3 and retain raw exits84/85/86; cut6 remains committed87. Explicit arm0 is the cancellation mechanism for an unmatched operation, not an invented automatic mark_array cancellation.

For each row retain raw argv/env/cwd, actual injected/reached source cut, error, failure-exit snapshot, before-retry snapshot, retry refusal, other-owner progress, original claim/record hashes, raw process status, timeout and all-writer quiescence. If a required hook is missing, the row is BLOCKED rather than satisfied by a model state or banner. No whole inventory or altered expectations.

The original historical two-worker fixture is still unlocated. Any comparison must first recover its actual inputs/topology; otherwise label a new control separately. Preserve its20-second command window and90/3600-second limits elsewhere. No time increase or replacement of old receipts is authorized.

## Formal lifecycle boundary remains separate

These diagnostic edits and model controls never call pthread_join. They cannot emit the required two OS-JOIN-ERROR / SAME-OWNER-JOIN0 receipts or change8/12. The existing Darwin reachability issue remains a distinct contract-review blocker. A native reaper fixed from its first attempt is a different owner from P0; its success must not be reported as P0's same-owner recovery. No qualifier/probe/history migration or reaper implementation is authorized by this evidence work.


## Retained verification

New model SHA256 `0f84fc24ba8acd07ab4834bcb6a33fbc1ed3d0614258c76be16336a23c4f9787`:9 safety checks,9 expected parsed mutant traces,9 positive reachability controls and1 termination witness all matched expectations (28 new controls), within30 seconds per check. Verification receipt: `.cache/tasks/repair-9-12/processes/audit/runs/75b103f797ad425a8491ae93e912b023/outputs/scan-failure-handoff/receipt.json`. Prior41-control model and receipts are not rerun, overwritten or counted as new. Native executions:0; sourceRefinementAdmitted remains false.
