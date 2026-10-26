# Old-cohort result ACK, successor activation and final RC-carrier release

Evidence-only continuation of [synchronous repark](synchronous-repark-protocol.md). All coordinates refer to the same reproduced lock-main revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the cumulative foreign-release-claim patch; the source receipt is bound in the companion JSON. Vendor HEAD is a separate project. New function/field names below are implementation proposals, not existing runtime capabilities. No runtime/generator/qualifier/Recipe/history changes, native generation/execution, other-thread operations, commit or push occur here. Recorded qualification remains8/12.

## Independent refinement: ACK is not quiescence, GO is not root release

The earlier single departure ACK abstracted three different lifetimes. Keep them separate:

1. **Result installation ACK:** an old member acquire-observed the same prepared successor/result and recorded its key/status. This alone does not mean that its barrier forwarding, mutex/condition-variable operations or native helper tail have returned.
2. **Old communication tail/descriptor pin:** protects every remaining reference to predecessor ranks, channels and result storage. A member copies its next ticket/status/cursor first, finishes all predecessor accesses, then drops this pin exactly once. No later read/write through that reference.
3. **Parent RC/root carrier:** outlives callback repark and native host execution, survives repeated frozen-domain GC, and remains until final rejoin/restoration installs replacement roots and all carrier readers/borrowers leave. Neither result ACK nor GO releases it.

A successor may begin while predecessor pins remain only if its communication storage is independent. The current barrier uses per-pstate sync_id*/sync_op* fields. Reusing those fields while old tails can write them is unsafe even if a new descriptor carries an epoch. The recommended protocol allocates/reserves **per-cohort/per-round channel state in a pinned transition/cohort descriptor**, with full VM incarnation/epoch/round/phase validation. If retaining current shared mailboxes instead, require a separate complete predecessor communication-tail drain before enabling any successor barrier. These alternatives cannot be mixed by assuming an ACK bit provides the missing isolation.

## Concrete existing functions and the missing phases

| Same-generation source | Actual behavior | Grok change and exit condition |
| --- | --- | --- |
| `setup.c:751 barrier_sync_op`,705..732 message macros | Child payloads are read after acquire flag; logical id/count computes tree. Parent reply at902 is copied, then winner is forwarded to children at917..928; local sop result is written and function returns at938..940. | Add immutable predecessor descriptor/rank/channel argument, common phase key and real local pin. An ACK cannot imply code after it no longer accesses the descriptor. Sender's SYNC_SEND_MSG still performs mutex unlock and condvar signal after flag publication. |
| `barrier_sync_noop:948` | One barrier call; not an independent last-reader fence. | Do not insert an untagged extra NOOP locally. All old roles must execute the same result-install/ACK/GO phases, including Scheme callers, native post-run workers and departing B. |
| `execute_sync_op_loop:1600` | Local first_iter/startup state and OP_NOOP may break; errors are delivered at loop end; operation completion is identified by opcode/winner. | Add explicit PREPARED_RESULT → OLD_ACK → GO/ABORT state. Native departure returns only after GO is acquired and its predecessor tail is ended. Survivors enter only successor-tagged rounds. Deferred error/ABORT reaches common completion before any local return/throw. No local timeout deletes an old member. |
| `on_all_processors:1731`, `service_sync_op:1716`, native worker loop1006..1036 | Shared outer engine exists, but no old/new descriptor ACK/pin protocol. | Use one service engine and result object for all roles. Retained prepublication failures keep old membership and root ownership and remain serviceable. Do not wait for a remote native borrower inside the common window. |
| `mem.c:4405 mark_rc`,732..855 RC API | mark_rc writes actual h->data; payload is unscanned. release_rc unlinks and frees at zero; register/addref/release are plain owner-local operations. | Use a typed rooted carrier or explicitly scanned cells. Separate native descriptor pin/ref ledger from RC's ordinary count. Queue final carrier release to its authorized owner; never remote-unlink from a scan owner's worker or from departing native callback tail. |
| `header:6386 THREAD_RESTORE`,6400..6437 JUMP_THREAD_RESTORE2..5 | Restores current stack-break link, consumes saved continuation by writing END marker, sets current thread/handler; argument pushes and final jump follow. | Root-install ACK belongs in the **reached compiled completion landing**, after restored stack/register/result roots are installed. Clearing the saved continuation or calling restore is not itself the ACK. On restore/landing error before ACK, retain the carrier and current ownership; do not repeat a consumed restore. |
| `gsc/_t-c-2.scm:4272 thread-restore! emitter`,847/890..926 return-map emission | Emits the jump with fp/register bookkeeping and compiler liveness maps. | Generate explicit success/error completion landings and audit their real map bits. The final-release helper must not be emitted as ordinary code after a nonreturning restore jump. |

## Proposed common state and ordering

A stable transition object holds {VM incarnation, source/successor epoch, round, phase, old ranks, successor ranks, initialized scan domains, result, per-member ACK, per-member native-tail pin, independent phase channels, GO/ABORT}. Build its successor root/domain ownership completely before publishing PREPARED_RESULT. Initial preparation may allocate while active; the chosen common commit/result window allocates no Scheme objects and runs no arbitrary callback.

```
old cohort finishes selected GC/resize and all scanner/native operation readers
READERS_EXITED(old,round)
initialize successor descriptor + frozen B root ownership + common result
release PREPARED_RESULT; each old member acquire-validates same full key
record RESULT_ACK(old,round,member) using pinned transition state
leader acquire-observes every old ACK, release-publishes GO (or common ABORT)
member acquire GO; finish predecessor forwarding/native accesses; drop own old pin
  B: return native callback only after its old tail ended; keep parent job RC root
  survivor: enter successor channels/ranks; retain own predecessor pin until last access
last predecessor pin/reader: reclaim descriptor via its separate claim
```

GO establishes one successor membership/scan owner; it is not permission to free predecessor state. Independent channels allow survivors to acquire GO at different times. The first successor GC still gathers **all successor members** before scanning; a leader's local GO observation is not all-arrived. A member never chooses the old tree after acquiring GO. Message phase key and pins prevent old-round ABA/reuse; plain acquire/release on a flag does not by itself prove lifetime.

If using shared pstate mailboxes, change the schedule: copy transition wait capability into independent stable state, finish/drop all predecessor communication tails, gather a separate DRAINED ACK, then publish successor GO. Participants must not wait for GO while still holding a tail whose drain is required for GO. That circular dependency is why simply adding another old-tree barrier is not a valid implementation.

GC requests arriving during this fixed window remain persistent debt; their root snapshot waits for GO/ABORT and stable membership. On common ABORT before publication, old cohort remains active and keeps the carrier; native retained service permits later GC and classified retry. After ambiguous publication, neither old nor new cohort can be selected from a local Boolean: use a separately proven shared reconciliation/terminal policy. This handoff does not solve a nonresponding active member by excluding it.

## Last-consumer matrix

| Resource | Consumers that must end | Release site / owner |
| --- | --- | --- |
| Old result/descriptor/channel record | Old gather/broadcast/forwarding functions; transition readers; native helper tails, each holding a real pin | Proposed `cohort_retire_descriptor` after zero predecessor pins/readers; no Scheme roots still depend solely on it. Independent successor storage remains live. |
| Child callback marker | Nested ___call and supported conversion/error paths; typed roots transferred before marker close | Checked SFUN epilogue kills once. This ends child logical return permission, not callback native tail or parent job. |
| Callback native tail | In-place service helper/catcher, native callback value/status copy and final metadata access | Proposed checked SFUN native-return epilogue, after GO and local predecessor tail; copy result first, then drop token last. No detached ps/R_ALL access. |
| Parent RC carrier | Frozen-domain scans on every GC; host job; rejoin/restore landing; accepted readers/borrowers; queued ACK/reclaim records | Proposed `park_owner_reclaim_batch` in authorized owner window after replacement-root ACK and per-carrier grace. Not at park/GO/child marker close. |
| Destination Scheme result/error/continuation roots | Current restored stack/thread/GVM roots with actual compiler map or another registered destination | Remain after carrier release. They can relocate on subsequent GC; cached body/SCMOBJ copies are not authoritative. |
| Full job/ticket metadata | Root release record and all native/queue borrowers, independent of RC payload | Separate last native reference; copy cursor/status before final decrement. Avoid a reclaim callback that reads the just-freed job. |

## Exact generated-C correspondence and proposed landing shape

Archived `lib/_thread.c:6604..6611` supplies a concrete restore control:

```c
___DEF_SLBL(24,___L24___thread_23_)
   ___IF_NARGS_EQ(2,___SET_R3(___NUL))
   ___GET_REST(24,2,0,0)
   ___SET_STK(1,___R1)
   ___SET_R1(___LBL(25))
   ___ADJFP(1)
   ___JUMP_THREAD_RESTORE4(___JUMPNOTSAFE)
___DEF_SLBL(25,___L25___thread_23_)
```

This is an existing structural control, not a regenerated staged producer. Header's RESTORE4 expands to POP_ARGS → THREAD_RESTORE → PUSH_ARGS2 → jump. Therefore the new ACK cannot be an arbitrary line immediately after invocation, nor can an ACK before PUSH_ARGS prove the destination results are rooted. The reached staged success/error landing must establish all live destination slots/GVM values, execute the actual register-save/return-label protocol for any C helper, then publish the full-key ACK. The old carrier remains until that ACK and its independent readers are done. Existing `##sync-op-interrupt!` generated W_ALL/service/R_ALL is suitable only for active returns; detached B must not take its normal R_ALL/RETURN.

Proposed generated behavior (not actual emitted C):

```
active final rejoin -> COMPLETE converts native result/error into rooted destination
THREAD_RESTOREn(... compiled_complete_landing ...)  // consumes parent once
compiled_complete_landing:
  install destination result/error and current-thread/frame roots
  publish ROOT_INSTALLED_ACK(full job/restore generation)
  queue owner reclaim eligibility; continue normal Scheme or mapped Scheme error
owner common reader-free window:
  if per-carrier borrow/scanner/ACK reader busy: keep root, skip record, continue batch
  otherwise claim once, close carrier-reader admission, unlink/release_rc locally
  finish all job/cursor accesses before final metadata pin drop
```

A Scheme error path needs the same explicit destination-root/ACK handoff or retention. Do not release the carrier merely because an error was recorded, a callback marker died, or the saved continuation field became END. A supported mapped error is not proof of completed root installation.

## Failure and GC boundaries

- **Before common result:** old cohort scans the carrier; preparation failure keeps original membership and native activation. No ACK/GO for an uninitialized successor.
- **During result/ACK:** GC cannot start inside the fixed commit window; its request stays pending. Member error/early return cannot bypass common ACK/ABORT. A silent/nonresponding member prevents progress; retention protects memory but does not establish system liveness.
- **After GO, before old tails end:** successor may collect only with independent channels and complete successor participation. Old descriptor remains pinned. Its stale scan ownership is not used as a second root domain; successor descriptor is authoritative.
- **After B callback return, before host completion:** frozen parent carrier remains registered/scanned; no RC release, join/transfer/cleanup or new incarnation. Native body holds only admitted native payload.
- **After host completion, before root ACK:** final rejoin and current generated roots are required; failures retain carrier. A consumed continuation cannot be restored again to simulate rollback.
- **After root ACK, reader/borrow busy:** preserve carrier and reclaim record, skip it within the bounded owner batch. Another record can progress; no spin/wait holding P/T/shared locks or whole cohort window. If no later borrower exit/fair service, reclamation is not promised.
- **Last release:** use actual relocated RC data until the reader-free claim. RC unlink/free is owner-local. Do not turn its plain count into a cross-thread lease. Destination roots survive subsequent GC; no read through the final released carrier/job pointer.

## Grok implementation order and same-producer targeted checks

1. Introduce immutable epoch/rank/domain and transition records with explicit channels, result key, ACKs and descriptor/native-tail pins. Decide **independent epoch channels** versus **full communication-tail drain before GO**; implement one complete schedule.
2. Change barrier_sync_op/execute_sync_op_loop/service_sync_op and all return/error/native-worker callers to the same tagged phases. Initialize domains before result, gather all old ACKs, publish one GO/ABORT, retain persistent GC debt and keep local pins through actual last accesses. Validate startup/resize nesting under this same schedule.
3. Extend the staged SFUN emitter and final completion landing, compiler return-label maps and actual W_ALL/R_ALL paths. Separate callback native return from final parent restoration; preserve root carrier until reached success/error ROOT_INSTALLED_ACK.
4. Implement owner-local queued RC reclamation with per-carrier scanner/native/ACK-reader grace and a one-shot claim. Busy record skips; descriptor pin and RC/job lifetimes have independent ledgers. Audit cleanup/close admission against every retained token.
5. On one source/generated/header/object/link-bound producer pause a leaf after result flag publication but before mutex unlock/signal/forwarding return; force another member to acquire GO and request GC. Assert independent new channels, predecessor pin retention and no old-round mailbox overwrite. Repeat with each member and delayed GO acquisition.
6. Inject member error/early return before ACK, transient preparation refusal, unknown commit and delayed old-tail drop. Verify common ABORT/retention versus terminal/shared-fault outcomes; never infer GO from timeout or banner. Check native host activation/owner stays unchanged.
7. Inject GC between host completion and restore; between destination install and ACK; after ACK while a carrier reader is live; after RC release. Assert actual relocated carrier/destination roots and exactly one restore/release. Hold one carrier borrow while another reclaim record progresses; release it later and require a subsequent bounded batch to reclaim it. Exercise mapped Scheme-error landing and restore failure separately.

Independent sufficiency judgment: result/GO/pin separation and explicit root-install ACK close conceptual holes in the prior atomic model, and identify real functions that must change. They still require generated C/map evidence, implemented channel/pin memory ordering and reader admission, complete frozen scanning/weak/finalizer semantics, unknown-commit policy and same-producer native tests. A safe retained state is not a proof of eventual completion with a stuck participant or borrower. No formal9/12 gate is closed here.

Reproduce this research slice from the SMP root with `PYTHONPATH=src python3 evidence/research/smp-retirement-study/verify-cohort-ack-rc.py` after normal audit-role admission. It reuses the registered audit scope and unchanged30s case budget. This is a model-verification command, not a native implementation test. The native checks above require Grok's actual new producer/harness and their source/object/link-bound receipts; no invented native command or modified sealed Recipe is supplied as if it already existed.

## Recorded QNT controls and proof limits

Final `models/gambit/cohort_ack_rc.qnt`: Quint0.33.0/TLC,22 expected controls:3 exhaustive safety scenarios,15 independently decoded negative witnesses,4 distinct reachability witnesses. All matched expectations, maxcase7.008s under unchanged30s per-case cap. Receipt:`.cache/tasks/repair-9-12/processes/audit/runs/9aa92d7fd9d3481bb3447de7aab4d2ad/outputs/cohort-ack-rc/receipt.json`. Projections reproduced byte-for-byte; Python checker explicitly decodes TLC $integerSet values before testing member sets. Source33 files and protected20 inputs reverified unchanged.

Positive safety scenarios are success, transient preparation refusal/retry and permanent retained prepublication refusal. Reachability proves successor GC with old descriptor tails still pinned (a separate newGc flag excludes a precommit-GC false witness), root carrier release with destination roots, retained old-cohort GC/service, and retry followed by all-old ACK/GO. Negative controls cover early GO/activation/member return, old descriptor free at ACK, old-tail/postrelease access, RC free at GO or with outstanding borrower/reader, root ACK without installed roots, stale destination map after GC, detached GVM access, duplicate release, failure-root loss and aliased epoch channels. SharedMailbox is a rejected protocol precondition, not a C execution demonstrating physical mailbox corruption; that operational claim requires the native paused-tail test above.

This finite model has3 old members,2 survivors,one carrier,2 abstract borrowers/readers and one epoch handoff. It assumes atomic common-window/domain publication, destination root installation and reliable phase delivery. It does not prove C11 ordering, arbitrary epoch reuse/ABA, multiple queued carriers or eventual reclamation under endless readers/borrowers. The previous repark model supplies a separate conditional service/debt slice; these are not a fully refined single C-runtime proof. No liveness success is claimed for an absent old member or permanent borrower.

Research diagnostics are preserved: audit b060332d81934f32afcdeee5d713c5c2 (parameterized-action annotation parse error), dc3e3e520ba74a71974136ce6b647151 (reserved next identifier), and1402ac649c494250b36acb8d4f1f2ba1 (predecessor independent Set-witness decode failure). They are not admitted model evidence; only the final receipt is used above. Each failed own audit was normally reconciled after real lease quiescence, without touching the native work item lease or another thread.

Archived generated control SHA256:`ee46b495cf81d10b2b07c71efab4772b76fdb93b502c41907b129f79286e1af2`; lines6604..6611. This is not regenerated candidate landing/root-map evidence. Native executions0; no runtime or qualification admission.

## Subsequent multi-epoch and current implementation distinction

[Epoch mailbox/pin/ABA/two-carrier study](epoch-mailbox-reclaim-protocol.md) binds the newly supplied cohort-ack-rc cumulative patch separately. That implementation chooses drain-before-GO and has no certified root-release landing; it is not the overlap-capable proposal. The new21-control combined proposal model and6-control drain-admission comparison preserve this distinction and prior immutable receipts.
