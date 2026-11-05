# Pending-to-join0 lifecycle contract and reaper refinement proposal

2026-10-23. Evidence/model proposal only. Formal qualification remains8/12.
No runtime, observer, recipe or milestone was changed. No native campaign ran.
No other thread was operated on; no staging, commit or push occurred.

## 1. What changes and what must remain proved

The old formal predicate requires an actual nonzero/non22 OS join return and
later same-OS-owner join0. Darwin's supported exclusive/no-cancellation shrink
graph has no established trigger for it. `darwin-join-feasibility.md` supplies
the conditional platform analysis. A counter edit, forged errno or pending flag
cannot fix this. This proposal does **not** preserve or claim that specific OS
error-recovery sequence: it removes that infeasible trigger only through a
separately authorized contract review and replaces it with stronger observable
retirement obligations. Until that migration is reviewed and executed, remain8/12.

The intended resource-safety statements survive as explicit conjunctions:

| Original purpose | Required pending-contract proof | Distinguishing rejection |
|---|---|---|
| Join failure must not imply exit or disposal | Pending and actual native error both preserve original slot/epoch ownership; only actual join0 certifies OS exit | Publish pending as EDEADLK; reclaim before actual0 |
| A single owner later completes the same retirement | One fixed native reaper owns the join capability from its first claim; immutable VM/slot/generation/handle identity on each completion | Different owner, stale epoch, other donor's success, duplicate join |
| No use-after-free through GC or private work | Old cohort prepares roots/work before withdrawal; donor storage remains leased while a traced carrier covers reachability; explicit post-join borrower grace precedes transfer | Ready donor plus failed donor loses coverage; free scan/handler/queue state early |
| Error can return without losing resources | An explicit Pending result leaves debt inspectable and is completed later; actual OS error is retained/poisoned, never synthetic success | Sticky error silently cleared; pending treated as success |
| Re-entry and resizing are consistent | Same-generation poll completes existing debt; requested grow is actually executed or returns a documented distinct result | Recovery-only NO_ERR masquerades as requested grow |
| Recovery is repeatable | Two campaigns on one completed producer, each with two donors/two epochs, nested GC, rooted old-generation payload and exact-once reclamation | Single lucky run, old payload lost on ledger reset |

Native OS-error retention is a **separate required control**, not erased from the
contract. Its completion is allowed to be checked retained failure; it does not
pretend every OS error is transient. Pending success requires eventual worker
retirement, reaper execution and survivor polling. A timeout, nonreturning callback
or permanently blocked join never becomes a successful recovery.

## 2. Three permissions, one immutable ledger key

Proposed native types live with processor/VM declarations in `gambit.h.in`.
Names below are proposed interfaces, not functions that exist in GSI7263fe03....

Key: `(VM instance generation, retirement epoch, donor slot incarnation,
original native handle, reaper instance generation)`. A printed pthread_t or
slot index alone is not an identity. Epoch counters must not wrap while old
records/messages are reachable; fail closed on exhaustion. Multi-donor results
are attributed per key, never by VM-global errno/success flags.

| Permission / owner | Fields and allowed operations | Final release |
|---|---|---|
| Slot storage lease / original donor ledger | `phase`, immutable key, root-carrier token, borrower obligations, queue/work ownership, first native error; blocks setup/reuse | P0 finalization after exact keyed join0, completion consumption and all grace |
| Native join capability / fixed reaper | `join_owner`, `join_claimed`, stable handle copy; one `___thread_join` call for that generation | Keyed result published and consumed; never transfer to another live joiner |
| Root scanning / traced VM carrier then P0 | Scheme object references in a typed VM-rooted carrier; completion contains only native keys/status | Drop carrier only after reachability is installed in the destination and donor last consumers are gone |

Native mailbox memory is not a GC root. Do not put an untraced `___SCMOBJ` into
a malloc record or infer scanning from retention of its allocation. A carrier
adds tracing coverage; it does not transfer ownership of donor still/RC memory
before join. Existing `___transfer_mem_pstate` remains a post-join operation.

Ledger states: Preparing→Prepared→Committed/JoinPending→JoinedAwaitingGrace→
Transferred→Reclaimed. Separate precommit Aborted and postcommit RetainedError.
Native join success is latched permanently; never call join again if grace is
not yet complete. Pending count is the number of unreclaimed ledger entries,
not active processor_count. No new epoch may reuse a leased slot.

## 3. Function-level implementation plan for Grok

Actual anchors are from producer c86dff86, bound in the final verification index.
New interfaces require review/integration and generated-C checks before use.

| Existing call chain / anchor | Proposed code and ordering | Source proof still required |
|---|---|---|
| `_thread.scm:##current-vm-resize` callers, `##cvmr`; `setup.c:___current_vm_resize` → `on_all_processors(OP_VM_RESIZE)` | Split native begin/poll/finalize internally: `___vm_retirement_begin`, `___vm_retirement_poll`, `___vm_retirement_finalize`. Introduce an explicit internal Pending status, never encode it as an errno. Preserve public resize success/error behavior through a Scheme safe-point waiter, or explicitly review an API change. | All survivors agree on commit/rollback/result. Pending polling services private GC and normal scheduler work outside P locks. A P0-only return must not strand peers in a barrier. |
| `_thread.scm:##thread-migrate-to!`, `macro-thread-save!`, `##thread-resume-execution!`; C `___vm_resize_pstate` before count commit | New Scheme retirement landing pad and `___retirement_prepare_pstate`: stop new public work for donor, capture mapped continuation and root actual live thread state, drain or move private work, register carrier. No user callback after final preparation acknowledgement. | Arbitrary live C frames cannot be copied by a native helper. Returnable C/sfun markers must finish or cause refusal before commit; existing marker guards remain. Preparation may invoke GC only while old cohort participates. |
| `gambit.h.in:___thread_struct`; `os_thread.c:start_pthread_thread`, `___thread_create` | New native-only `___retirement_reaper_start/entry`. Create/check helper before shrink commit. `data_ptr` names native ledger, `data_scmobj=___FAL`; never use `start_processor_execution` or set a worker pstate. A native handle does not need Scheme TLS. | Actual thread factory/trampoline error paths, signal mask, cancellation-disabled lifetime, and host consumer pin must be audited. Helper creation failure rolls back preparation consistently. |
| `___vm_resize_pstate` count publication and old worker exit branch | Commit only after all preparations and helper readiness. Publish a bounded native record with release ordering; worker may finish native cleanup then OS exit. Reaper takes the native join capability exactly once. | Root carrier remains VM-traced even when donor is off-cohort. Handler-generation admission and remote GC/queue borrowers are distinct from local interrupt cleanup. |
| New `___retirement_reaper_entry` → existing `___thread_join` | Snapshot key/handle under short native mailbox lock, release it, then block in one actual join. No T/P lock, VM-list lock, GC lock or mailbox lock across join; no Scheme allocation/callback on helper. | Any lock needed by target exit must already be released. One slow target serializes this reaper but cannot stop survivor GC; target liveness remains a premise. |
| New result mailbox publication / safe-point polling | Plain payload fields then release-publish terminal state; P0 acquire-load then compare full key/owner/phase. Notification is a hint; mailbox is persistent until consumed. A bounded poll independent of abort-pipe success ensures re-observation. | C memory-order refinement: the atomic QNT action does not prove implementation visibility. Stale/wrong-key completion is rejected without freeing anything. Polling must preserve the real user deadline. |
| `mem.c:___transfer_mem_pstate`, `___cleanup_mem_pstate` | After keyed join0, wait for explicit old-handler, GC/scan queue and remote scheduler borrower grace. Transfer still/RC and root/work ownership once; then destroy scan lock and release slot/carrier. | These functions' comments require drain; their calls do not establish it. Private GC work, donor frames and every root class need concrete source evidence. |
| `setup.c:vm_native_consumers_clear`, `___cleanup_checked`, `cleanup_vmstate_locked` | Include ledger/reaper/completion consumer references. On teardown: close admission→finish/retain debt→request helper stop→observe ack→host joins helper→free mailbox/carrier/VM storage. Move waits outside VM-list/GC locks. | Helper stop ack is not helper join. Never free VM memory while helper can write a completion or P0 can poll. Existing sticky retained cleanup is not reset/reopened to resume. |

The fixed reaper is a different OS thread from P0. Same logical VM administration
is not the old same-P0-OS-owner predicate. The reviewed replacement must name the
new owner from the first join claim, rather than redefining owner after failure.

## 4. Root and work handoff inventory

| Actual source family / last consumer | Required preparation and coverage |
|---|---|
| GC `mark_continuation`, `mark_registers`, `mark_saved`, `mark_type_cache` | Reach a supported Scheme landing pad and retain mapped continuation/environment plus explicit rooted values. A boolean Ready cannot retire live raw C frames. |
| `mark_processor_scmobj`, current-thread/migration/scheduler queues, result-mutex requests | Donor keeps original slot lease; carrier/destination references cover all live thread/request values. Preserve unique queue link ownership; no request disappears merely because processor_count shrank. |
| `setup_still_objs_to_scan`, `mark_rc`, still-object external refs | Trace externally referenced donor objects while native still/RC lists remain donor-owned; after join and drain splice them once into receiver. Enumerate how pending donor lists are reached by every GC. |
| Heap/scan queues, msections, shared copy references | Finish or hand off current GC work before excluding donor. New work publication must see retirement admission closed. Join0 alone cannot establish that no remote scanner holds a donor lock/pointer. |
| Interrupt handlers / wake writers / selectors | Close generation admission, observe actual borrower grace, retain descriptors and processor storage until final consumer. Existing abort-writer/selector SC guards remain independent. |
| `___run`, sfun marker list and C↔Scheme callbacks | Returnable marker blocks precommit retirement or is finalized by its legitimate caller. Native reaper cannot unwind another worker's C stack. |
| Exit jobs/final wills/current callback/error | Existing rooted fault coordinator continues to own suffix/current/error. Reaper never runs Scheme finalizers or public exit jobs; errors do not steal its root carrier. |

If any row lacks a concrete saving/tracing path, implementation admission stops
before membership commit. Do not paper over it with an initialized vector, an
unproved memcpy of processor state, or a new `rootsCovered=true` field.

## 5. Failure disposition and final consumers

- Preparation callback error / donor2 not Ready: old cohort remains intact;
  restore admission collectively, preserve consumed callback prefix and rooted
  suffix/error. Rollback does not reverse already executed user side effects or
  replay callbacks. New requests need their own safe admission decision.
- Helper startup or bounded mailbox capacity failure: refuse before commit;
  retire any actually created helper prefix through its real owner. No orphan
  helper or unregistered VM borrow is permitted.
- Actual worker join error: record exact native return and key; retain original
  donor handle/storage/roots and native consumer pin. Close that epoch to slot
  reuse. Do not classify it as pending→success or assume retry will fix it.
- Completion hint/abort write failure: preserve release-published mailbox;
  survivor polling reads it. Notification loss cannot discard a completed join.
- Stuck worker / blocked join: bounded observation reports retained failure,
  never changes native return or kills/detaches/cancels the helper/target.
  A blocked helper remains a last VM consumer; host checked teardown refuses.
- Post-join grace incomplete: keep JoinedAwaitingGrace, with no second join.
  Transfer waits for real consumers. A final exit acknowledgement before
  pthread_exit is not an OS join result.
- Wrong VM/epoch/slot/handle/reaper result: reject and retain; attribute the event
  separately. Never pair donorA's failure with donorB's successful join.
- Root/helper cleanup error: existing sticky failure is preserved. Stop ack,
  OS helper join and completion-consumer drain precede freeing native ledger.

## 6. Native acceptance design: real pending, no fabricated errno

Proposal criteria are in `lifecycle-pending-join.contract-proposal.json`.
They are **not installed** in the dispatcher, observer, sealed recipe or milestone.
Grok should implement only after a separate integration/contract authorization.

1. Use the existing repair-9-12 task/custody and publish one completed registered
   source-bound producer. Bind configure/profile/compiler, ten runtime source
   inputs, generated C/header, helper code and exact GSI to both campaigns.
2. Compile a narrow fixture that holds a worker at a supported **native test gate
   after root preparation but before OS exit**. The holder never waits for a
   Scheme callback or for the reaper, and does not add a join cycle. The test
   observer has independent release responsibility and an unchanged watchdog.
3. Obtain structured Pending from the real ledger while that worker is still
   held: unreclaimed key, original slot lease, stable reaper join capability and
   no native success result. A before-join marker is not evidence the reaper is
   already blocked inside libc; report claim and actual return separately.
4. While gate held, survivor invokes repeated real GC and verifies original
   payloads/threads/requests and an epoch1 payload during epoch2. Observe Pending
   again without clearing debt; try grow/slot reuse and cleanup admission and
   verify refusal/retention, without destructively entering global teardown.
5. Release the actual worker gate. Observe that worker exit and the one actual
   `___thread_join` return0 produce the exact-key persistent completion. Check
   owner identity, one call/transfer/cleanup, all borrower grace, pending0,
   requested resize actually completed and old payload still valid.
6. Repeat with two donors and two epochs, including donor1 Ready/donor2 failure
   rollback. Run a notification-loss variant proving mailbox re-observation and
   an actual fault-control/injection variant proving retained error, separately
   labelled. Existing request/wake/device/callback protections and first-eight
   contracts must remain valid on this same final producer.
7. Run two independent native campaign executions with natural exit0, original
   topology/budgets, reaped parent and quiescent process group. Reuse the completed
   producer through typed references; do not compile twice merely to get two
   receipt names. Preserve all historical failures and immutable old run1/2.

Each receipt needs `(VM, epoch, slot incarnation, native handle identity,
reaper generation/OS identity, event sequence, pending status, root/work carrier,
actual syscall return, grace evidence, transfer/free counts)` and native logs.
Probe summary output alone is insufficient. Observer tests must reject fake
Pending, synthetic zero, wrong donor/epoch, missing roots, duplicate join,
missing grace, live helper teardown and recovery-only success without requested
grow. Actual OS-error controls retain exact errno and fail closed.

Only after reviewed contract migration, actual source implementation, matched
native campaigns and these negatives may a future observer count9/12. The old
error11→same-owner0 requirement is archived as superseded/inapplicable to this
supported Darwin graph, never retroactively marked PASS. Other three gates remain
open, and39 focused passes do not establish this lifecycle result.

## 7. QNT correspondence and evidence boundary

`models/gambit/retirement_reaper_contract.qnt` separates slot storage/root coverage
from fixed join capability and completion consumption. Candidate scenarios:
normal two donors/two epochs; donor2 preparation failure; helper startup failure;
donor1 reclaimed/donor2 native join error; lost notification with durable mailbox;
and stuck worker retained without native return. Pending is observed before
worker exit and two modeled GCs occur while it remains pending. A precommit GC
occurs after donor1 preparation. Prior-generation transferred root tokens survive
epoch reset. Helper stop ack and helper join precede VM destruction.

Ten mutants target early commit, duplicate join, wrong owner, stale completion
in epoch2, reclaim before grace, missing pending root, VM free under retained
failure, Pending relabelled errno, discarded mailbox and lost prior-generation
roots. They must produce decoded invariant counterexamples, not parser failures.

The model uses atomic transitions and explicit abstract preparation/grace. It
proves finite protocol properties **conditional on** correct C/Scheme refinement,
GC tracing, atomics, collective agreement and helper setup. It does not establish
those missing source paths, arbitrary callback termination, a wall-clock response
bound, platform ABI portability or runtime admission. Retained failure is a
terminal report with resources still owned, not successful cleanup.

Reproduction uses the registered audit role,30s per case, unchanged TLC memory
limits and no native execution:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-retirement-reaper-contract.py
```

See the companion verification JSON for the final model identity, exact result
rows and retained earlier parser failure. Formal qualifier source, recipe,
probe and milestone hashes are rechecked unchanged by this evidence update.

Costs to measure on an integrated producer: one native helper/stack per active
VM, bounded records per leased slot, root-carrier tracing until reclamation,
short native mailbox locking and survivor polling. Reusing an existing bounded
wait-return cadence avoids a new busy loop; it does not guarantee deadline
latency or a performance gain. One serial reaper can suffer head-of-line blocking;
retain/report pending instead of adding competing join owners. No processor-count
reduction, heap expansion or weaker fixture is part of this proposal.


## C refinement follow-up: concrete root domain and three HB edges

`reaper-c-root-publication.md` shows why thread-save alone is not materialization
and why native pending still/RC owners need repeated GC setup/mark/accounting.
Current post-count cleanup can invoke release callbacks. The function-level
plan adds an old-cohort Scheme preparation boundary, typed VM root layout,
collector/owner GC helpers and one GC-quiescent finalization transaction.
Donor PREPARED→P0, P0 READY→reaper and reaper DONE→P0 are separate matching
release/acquire edges; record/VM lifetime and scan admission are separate proofs.
New19-control refinement passed one safety/fair-completion candidate and18
decoded negatives, but is not a complete C11 checker or native implementation.
No runtime or current acceptance contract was changed; count remains8/12.
