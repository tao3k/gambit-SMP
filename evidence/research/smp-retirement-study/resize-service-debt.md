# Resize-internal GC debt and stable-cohort handoff

2026-10-23. Source-bound design/evidence only for repair-9-12. No runtime,
qualification inputs, native execution, other-thread operation, commit or push.
The adjacent JSON binds the unchanged c86dff86 source and gsi7263fe03. Formal
qualification remains8/12; the pending-contract proposal is still inactive.

## 1. Judgment and two different debts

A VM-owned service ledger can survive growth, shrink and precommit rollback.
It must not live in a processor slot or be reset with startup_epoch. A stable
cohort must accept it in a common elected phase; a function's local return is
not that phase. Admission of the next resize must first honor the service cut
captured for that attempt. This addresses debt loss and overtaking, conditionally
on a stable, serviceable cohort actually becoming available.

**Service debt** means a native registry/mailbox snapshot has not yet received a
complete bounded service pass. **Retirement resource debt** means a donor still
owns storage/roots/handle or has borrowers. They must not share a clear bit.
A pass may record 'blocked A: retained' and successfully finalize eligible B,
then acknowledge its inspected service cut. A's resource debt remains rooted,
scanned, leased and unavailable for reuse. Waiting for all donors before service
ACK would recreate the global blocking rejected in the prior progress model.

This is not a sufficient implementation proof. In particular the current
post-count pthread_create failure is fatal and has no rollback protocol. A
retained terminal fault is not a stable cohort, restored service or completed
resize. The model deliberately distinguishes that outcome from successful debt
service and precommit rollback.

## 2. Source facts and exact proposed hook positions

| Actual source in bound producer | What exists | Proposed change/order |
|---|---|---|
| `setup.c:1054 ___vm_resize_pstate`, heap guard1086 | Calls ___garbage_collect_pstate directly before setup/count changes | Issue VM service demand **before** direct GC; finish GC; broadcast common GC outcome before any member branches/returns; never splice native domains during this transaction |
| `mem.c:7400-7546 ___garbage_collect_pstate` | Local overflow initialized0; P0 assigns resize_heap result; final prepare_mem_pstate precedes return | Do not assume every member's local overflow return equals P0's; do not restore pre-GC roots on failure |
| `setup.c:1143+` setup prefix and failure cleanup | P0 prepares additional pstates, may clean prefix and return before count publication | Preserve debt; broadcast the common PRECOUNT_ABORT outcome, then old-cohort ABORT/reader agreement; publish stable-old certificate only after actual ACKs |
| `barrier_sync_op:703`, count publication near805 | P0 publishes count while broadcasting through a tree based on captured old n | Bind count plus native scan-domain ownership to the same commit; transfer ledger lifetime to VM, not exiting slot; no service ACK here |
| `setup.c:1117+` retiring branch | Donor cleans/dequeues and exits OS thread, never returning to caller | Existing retirement proposal moves Scheme work before commit and join to fixed independent lanes. Donor is excluded from new collective but retains its storage/root domain |
| `setup.c:1170+` current shrink join loop | P0 synchronously joins and transfers memory | This blocks handoff on any stuck donor; candidate must use previously reserved lanes and return Pending to the **survivor** result protocol |
| `setup.c:1196+` growth OS create loop | Count already published; create failure calls ___fatal_error | No recoverable post-count rollback exists. Never certify stable from count alone or pretend this error restores old cohort |
| `execute_sync_op:1259` resize case | Calls vm_resize_pstate then a P0-result barrier in the currently participating count | Preserve that result independently. Queue HANDOFF_PENDING only after the common result phase; do not insert an arbitrary extra barrier after this local branch |
| `start_processor_execution:980-1001` | New processor enters startup NOOP sync loop, not old caller's resize branch | Handoff must be an outer elected operation or fixed selected-GC/READY transcript reached by all current members |
| `_thread.scm:3316-3336 ##startup-processor!` | Initializes processor queues, unlocks P, calls ___processor_startup_complete, then enables interrupts/schedules | Existing readiness location is useful; exact matching status1/epoch for every new member is required before stable certificate |
| `execute_sync_op:1244`, `___processor_startup_complete:1455` | READY is broadcast as an operation, sets scheduler_status=1 | At each selected READY, all members run the fixed native try-handoff transcript. P0 alone proposes either EMPTY or a matching stable certificate; no local 'last ready' barrier |
| `execute_sync_op_loop:1348-1380` | Old members wait for startup; status0 or epoch mismatch is pending; -1 records failed startup | Keep startup callers able to leave for Scheme initialization. **status!=0 is not readiness**. A -1 member cannot certify stable; common retained/fatal disposition is separate |
| `execute_sync_op_loop:1409-1413` | Resize-specific delayed-error backfill and eventual P0 throw | Recoverable error must pass common abort/result/handoff and required service cut before return/throw; VM-fatal error instead retains debt and closes admission |

The source reveals a control-flow risk, not a newly executed native failure:
local GC overflow and a P0-only pre-count setup error must not make members take
different follow-up barrier schedules. A patch needs an explicit common outcome
phase. Do not infer native deadlock from this read alone; native fault validation
is still absent.

## 3. Native ledger and stable certificate

New native VM fields, separate from mutable processor slots:

- `service_demand_seq`, `service_acked_seq`: demand and completed-cut watermark;
- `service_sweep`: pinned registry snapshot, cut, full VM generation, member
  generation/count, sweep sequence, cursor and common result/ACK state;
- `resize_txn_epoch`, `resize_phase`, `resize_admit_cut`, deferred common outcome;
- `membership_generation`, `stable_cohort_generation`, matching stable certificate;
- persistent per-donor records/lane control from the previous proposal.

All counters are checked nonwrapping. Exhaustion closes admission and retains
records; never reset a live sequence on resize failure or reuse an epoch while
old commands/borrowers exist. These are native synchronization fields, not new
Scheme roots. The existing typed VM-root carrier remains responsible for actual
thread/continuation/error/queue references and current GC-forwarded values.

P0 serializes lifecycle admission and records a finite `resize_admit_cut` from
the current demand at the admission attempt's linearization. Before the attempt
may mutate target count/heap membership, common service must cover that cut.
A new publication after the cut does not force endless restarting of that same
attempt; it remains outstanding for the post-resize stable handoff or next
admission. No second resize may acquire an old cached cut to leapfrog existing
debt. A selected request rejected by the gate preserves its request and result
identity; do not return NO_ERR for an operation that did not happen.

Native lane completion publishes its keyed result before issuing service demand;
a demand acquire must make the preceding result visible. Direct internal GC
issues demand before entry so an error/nonreturn cannot erase it. P0 acquires
mailboxes and performs the same per-entry key validation as before. Snapshot and
reader lifetime protect native records; no movable Scheme body pointer is cached
through a collector or a sweep.

## 4. Common handoff protocol, not a return-hook barrier

Proposed `OP_VM_RESIZE_HANDOFF = OP_MAKE(9,0)=36` is unused in the bound table.
Prior proposed retirement service/AND guard use priorities7/8; none are installed.
Operation9 needs an explicit phase-tagged envelope for HANDOFF and pre-count GC
outcomes, with opcode/phase checks, not an overloaded unchecked arg[0]. An
implementation can instead reserve distinct opcodes if that makes phase safety
simpler; it must review the complete table and result handling together.

1. `___resize_publish_outcome_pstate` records the common result and VM-owned
   HANDOFF_PENDING state after the appropriate result/rollback boundary. It
   does not itself assume all members are returning through the same C stack.
2. `___prepare_sync_candidate` in the outer collective dispatcher preserves
   each caller's original operation/result. While the admission gate is closed,
   an incoming OP_VM_RESIZE is deferred and represented by the pending handoff/
   service obligation, not allowed to win repeatedly and immediately reenter
   resize. No loss of the deferred caller's arguments/rooting is permitted.
3. `___resize_try_handoff_pstate` runs only at a **shared selected operation**:
   the elected HANDOFF, each selected READY, and the fixed completed-normal-GC
   epilogue. Every member executes its fixed transcript, including EMPTY. P0
   broadcasts authoritative phase/key; others cannot take a local early return.
   This also prevents continuous selected GC from starving priority9 HANDOFF:
   its common stability check is part of that completed-GC service window.
4. P0 proposes a stable certificate only after exact membership generation,
   old-result/abort completion, actual current count, and every required
   scheduler_status==1 at the expected startup epoch are checked. Each active
   member acknowledges the same certificate. New members' initial NOOP return
   and an old caller's resize return are not certificates.
5. With that certificate, the stable cohort accepts the VM service snapshot.
   It performs the prior bounded rotating native service protocol. Successful
   per-entry dispositions include TRANSFERRED or checked RETAINED with roots
   and owners intact. All snapshot entries and common result consumers must be
   covered before `service_acked_seq = sweep.cut` is release-published.
6. ACK only the captured cut. An arriving completion/GC demand raises the VM
   demand independently and must remain visible; never store ack=currentDemand
   or clear a VM-global pending boolean at completion. Member ACKs carry service
   sequence and member generation; stale old-cohort ACKs do not advance it.
7. Reevaluate admission against the saved cut, deliver the deferred common
   result/error in its legal context, and retain later service demand. Maintain
   the existing sync interrupt reset/rearm discipline: latch and notify the
   obligation after relevant common resets. No result-mutex high-level hint is
   used as the sole delivery guarantee.

During WAIT_STARTUP the old cohort must still service GC, and startup callers
must be allowed to run Scheme initialization. Do not hold them inside a 'wait
for all ready' handoff barrier; that would prevent their own READY publication.
A requested HANDOFF that is not yet eligible must not busy-loop at a priority
that prevents startup/GC. It reports common NOT_STABLE, preserves debt and lets
those required transitions proceed. New **resize admission** remains blocked.

## 5. Growth, shrink and failure order

Growth success: old cohort preflight/admission cut -> internal GC/common outcome
-> setup -> count commit/native-domain bookkeeping -> new native workers enter
startup loop -> Scheme queue initialization -> exact READY operations -> common
stable-new certificate -> debt snapshot service -> deferred return/admission.
The certificate follows readiness, not the earlier publication of count.

Shrink success: prepare/roots/freeze and independent lanes reserved -> internal
GC/common outcome if required -> count/native-domain commit -> donors exit on
nonreturning tail -> survivor common resize result -> stable-survivor certificate
-> per-donor debt service. Join0 is a donor-specific completion, not a prerequisite
for the survivor cohort to be stable; blocked A must not delay service for B.
The current synchronous P0 join loop must be replaced for this order to hold.

GC overflow/setup failure before count commit: agree on failure, restore current
GC-updated continuations through once-only ABORT, preserve consumed callback
prefix and rooted suffix/error, wait old-cohort ACK/reader grace, then certify
stable-old and service preserved demand. Report the error after that recoverable
protocol. ABORT failure retains roots/epoch/debt and prevents new admission.

Post-count thread creation/startup failure: current source has a fatal path,
not an old-cohort rollback. Missing/failed members cannot certify stable. Keep
service debt and resource owners, deny new resize, and use the checked fatal/
retained disposition. There is no theorem of continued GC/VM availability for
an absent participant. A model terminal-retained state does not supply one.

For production **recoverable** growth failure, a further design is needed:
pre-create workers behind native start gates before publishing their membership,
check the entire prefix, then release gates after commit. On failure, gate-abort
and reap that uncommitted prefix without a join cycle or GC-unscanned staged
native roots. This requires specific ___setup_pstate/___thread_create/native
entry/start-gate and staged scan-domain changes. It is not implemented or covered
by this model; do not describe post-count rollback as already solved.

## 6. Model evidence and exact limits

`models/gambit/resize_service_debt.qnt` distinguishes membership generation,
resize epoch, demand, captured cut, ACK watermark, inspected entries, common
member ACK and retained donor roots. It models two nonwrapping epochs, growth/
shrink orders, common result/readiness, pre-count GC/setup rollback, post-count
retained fault and a demand publication racing a sweep. A permanently retained
donor remains rooted even after a service pass completes.

Positive safety/conditional-progress controls: grow->shrink, shrink->grow,
overflow rollback, post-count retained failure, late demand, setup rollback.
Safety negatives: clear on count, old cohort sweep, early stable growth,
rollback clears debt, service ACK drops retained root, late demand overwritten,
resize bypasses cut, stale generation ACK, failed startup treated as ready.
Temporal negatives: new-resize pressure disables service forever, service waits
for all donor resources, startup never reaches Ready. TLC loop/stutter evidence
is required for the latter controls; these are not timeout-as-success checks.

The progress property is conditional on action-specific scheduling fairness,
completed direct GC, actual old-cohort rollback ACK where applicable, and eventual
successful startup **or an explicit retained fault**. It does not prove a missing
worker becomes available. Finite two-epoch checking is not unbounded generation
or C11 proof. The previous recurrent-GC model covers infinite completed GC on a
stable cohort; this model supplies lifecycle handoff cases, not a verified
composition of every real callback/native entry with that infinite behavior.

Independent verdict: the ledger/cut and common-handoff protocol is a plausible
way to remove debt reset and resize overtaking. It is not yet a sufficient C
patch or9/12 proof. Key remaining work is actual collective candidate/result
refinement, rooting deferred requests, exact startup/error/cohort transitions,
interrupt rearming, recovering staged growth if required, and native fault tests
on a single completed producer. No formal gate is changed by these results.

### Deferred request rooting requirement

A deferred resize command cannot keep its thunk solely in a native copied
sync_op argument or malloc ticket across GC. Scheme preflight must put the
actual argument in the typed VM-rooted carrier. The native ticket holds only a
full-key root token; just before ___vm_resize_pstate executes, resolve the current
GC-updated thunk from that carrier. Keep the carrier through common result
consumption and the C caller's last use. Preserve original caller ownership;
HANDOFF is not execution of that caller's resize. Unsupported raw/foreign C
entries refuse before admission. This is a concrete required change, not a
claim that existing C locals are now proved rooted by ___W_ALL/___R_ALL.

Verification:18/18 expected model controls accepted:6 positive safety/conditional-
progress scenarios,9 decoded invariant negatives and3 temporal loop/stutter
negatives. Each executed check stayed below the original30-second cap.
Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/f3b7d82b295f4de59621a0d7be989127/outputs/resize-service-debt-model/receipt.json`. No old model rerun, native execution,
contract migration or counting change occurred.
