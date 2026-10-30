# Processor shrink and lifecycle recovery: contract review for Grok

2026-10-23. **Proposed contract, not an installed qualification rule. Count8/12.**
Evidence/QNT only; no runtime, observer, recipe, milestone or historical receipt
changes. No native campaign, peer operation, staging, commit or push.

## Terminology and review decision

Processor retirement means withdrawing and eventually reclaiming one generation
of a worker during SMP shrink. It does **not** mean removing SMP, abandoning its
implementation or deprecating threaded execution. `smp-retirement-study` is a
historical evidence namespace; its paths are retained to preserve immutable
references. This document uses processor shrink and lifecycle recovery instead.

Review the conjunction below, rather than replacing one stdout regexp:

1. A real accepted shrink creates observable, generation-keyed unfinished debt.
2. Throughout Pending, roots, native storage and last-consumer ownership remain
   valid, with repeated actual GC and continued survivor progress.
3. The originally assigned native join owner observes one actual join0 for the
   same VM/worker incarnation/handle. A later caller only polls its completion.
4. Completion is acquired, validated, drained and finalized exactly once before
   slot reuse. Requested operation completion differs from partial debt progress.
5. Actual join errors independently retain ownership and resources with their
   exact origin. A nonrecoverable error is not forced to become successful.
6. Two independent native campaigns exercise these obligations on the same
   completed producer, including the original first-eight protections.

This preserves resource safety and repeatable deferred completion. It does NOT
prove the old concrete event “a nonzero/non22 Darwin join return later becomes0
under the same P0”. That event is a changed requirement requiring explicit review.
No implementation/model result below authorizes changing the live gate. Preserve
old6/12 and8/12 history, failed transcripts and the other three open gates.

## Obligation-by-obligation review matrix

| Old requirement / purpose | Proposed required evidence | Difference and rejection |
|---|---|---|
| Real OS error, not a pre-join banner | Separate exact native-result record, including adapter encoded error and raw platform errno where actually captured | Pending is not an errno. Injected return is labelled injected, not OS. No required Darwin error→success theorem is claimed. |
| Same owner eventually joins | Assign one native owner capability before exposing Pending; bind its lifetime generation and actual OS identity on claim and syscall return | P0→reaper is an architecture change. A logical VM owner or recycled pthread_t is insufficient; review it explicitly. |
| Same original retirement | Immutable key K=(VM instance, resize epoch, slot incarnation, native-handle lifetime, join-lane generation); compare every component at consumption | Wrong slot, stale completion, reused handle, new incarnation and other donor join0 must all reject. |
| Error path does not join again | Error callback stores result under K, publishes RetainedError, returns through common protocol; no retry in storage block | Supported Darwin hard errors remain retained. Any future retry needs a platform-specific recoverability proof and same-owner capability; not this proposal. |
| No transfer before successful join | Real join0 is necessary, followed by completion acquire and all scan/handler/queue/wake/native-reader grace | Exit ack, no current requests, stop ack or pending0 alone cannot authorize free. |
| Rooted failure/recovery | Old-cohort materialization plus exactly one active/pending scan owner; every GC updates actual still/RC locations | A saved raw fp, cached SCMOBJ, native malloc ledger or boolean rootsCovered is insufficient. |
| Recovery persists across re-entry | Poll same K; latch join0 permanently; JoinedAwaitingGrace cannot rejoin; complete the requested resize or report explicit partial result | Clearing debt or returning recovery-only NO_ERR for an unperformed grow rejects. |
| Two lifecycle receipts | Two genuine executions, each two donors/two epochs, same completed source/compiler/generated-C/GSI identity | Never overwrite recovery-1/2 or borrow another producer's39 passes. |

## Function-level implementation order

The source anchors below refer to the immutable per-file observation under
`.cache/tasks/repair-9-12/processes/audit/runs/bad1e9aa8d7d47e2a1304a6225f6f2ae/outputs/integrated-growth-source-observation/observed`.
They are observations, not certification of a coherent built generation. The
mutable c86 directory name is only a location hint. Rebind the final producer.

| Order / actual anchor | Grok implementation requirement | Publication / final consumer |
|---|---|---|
| 1. `gambit.h.in` VM/pstate declarations; `_thread#.scm` VM layout | Bounded ledger with full K, fixed owner, phase, actual-result origin, join-call count, native-entry/scan/wake borrowers, root-carrier index, completion/service sequence, transfer/free latch. Use explicit typed VM root field; preserve fault coordinator. | Process-lived registry/slot synchronization; nonwrapping generation; reject capacity exhaustion before commit. No raw Scheme pointer in native mailbox. |
| 2. `_thread.scm` resize entry/save/restore; `mem.c:mark_captured_continuation` | Scheme preparation outside T/P locks and count-changing collective. Materialize frames with old cohort serving nested GC. Drain callback prefix once, retain suffix/error. Donor2 failure requires all-member ABORT acknowledgement and reader grace. | Existing active roots remain authoritative until atomic count/scan-owner commit; rollback uses current GC-updated continuation once, not old frame bytes. |
| 3. `setup.c:___vm_resize_pstate` (~1340), staged creation; `os_thread.c:___thread_create` | Reserve bounded join lanes for accepted donors before commit; one live lane per blocked donor, no serial queue head-of-line requirement. Assign owner/K before Pending. A lane has native data only and no Scheme pstate. | Failed lane setup aborts before membership commit. Its actual creator/host must join any created prefix before freeing it. |
| 4. `setup.c:1428–1430`, `1470–1498` current exit/join/transfer | Replace count-before-unprepared-exit with prepared commit; donor native tail cannot run Scheme callbacks or touch moved frames. Publish persistent debt and count/scan-domain transition in one GC-excluding collective. | Original slot owns native lists until finalization. Current direct join loop only checks success and returns first error; it is not a persistent recovery ledger. |
| 5. `os_thread.c:548–560`, actual `___thread_join` | Lane releases every mutex needed by donor before the blocking call; one call using immutable handle. Record exact scalar result; success only from NO_ERR. Error enters RetainedError; no speculative retry/cancel/detach. | Original join capability cannot move while syscall is outstanding. Raw errno is available inside adapter; outside it current result is encoded `___ERRNO_ERR`, not automatically a positive errno. |
| 6. New native completion publish + survivor poll | Initialize payload then release-publish DONE; consumer acquires then validates full K/owner/result origin. Hint failure cannot discard mailbox. Poll via existing independent wait-return service, preserve original absolute deadline. | Completion, record/VM borrow and join-lane reference survive until explicit keyed consumption; ordinary poll caller never becomes join owner. |
| 7. `mem.c:setup_still_objs_to_scan`, `mark_rc`, GC phases; `___transfer_mem_pstate:5257`, cleanup5307 | Scan pending owner once per GC with active collector allocation context; write forwarded RC values to real header data. In agreed post-GC/native-service window, select one eligible donor, verify grace, transfer lists and roots, remove domain, cleanup. | Destination root installed before carrier release. No allocation/callback/GC inside final native transfer transaction. Existing transfer must be audited/preflighted as no-fail, or use a durable per-resource progress ledger; half-transfer rollback is not supplied by this contract. |
| 8. `c_intf.c:6520–6544`, `setup.c` checked cleanup/native consumer checks | Keep marker-reader and post-marker C tail separate; include reaper writes, completion readers, scan readers, handler/queue/wake/selector leases. Close fresh admission before drain. | Worker join0 covers worker tail, not other native readers. Lane stop ack then host join, completion drain and all references precede VM/ledger destruction. Failure preserves roots/key/resources and refuses reuse. |

Use the later `retirement-progress-protocol.md` independent lanes and mandatory
post-GC service window; the older single-reaper paragraph in
`lifecycle-pending-reaper-contract.md` is insufficient for a blocked donor.
Reserve lane resources before commit, bound them by accepted slots, retain them
on blocked exit, and refuse additional admission at capacity. This has a native
stack/resource cost, not an unmeasured performance benefit. A blocked worker can
prevent its own completion and whole-VM destruction; it must not prevent another
eligible donor from progressing or survivor GC. Callback termination remains a
premise for success, not for preservation of retained failure.

Use `generated-root-handoff.md` for actual Scheme→generated-C spill/map/reload,
native helper no-GC restriction, nonnested guard/slot borrowing and P0 C-tail
coverage. These are implementation preconditions, not facts established by a
QNT state assignment. Mandatory native-service epilogues also cover resize-internal
GC via `resize-service-debt.md`; a later resize cannot overwrite earlier service
debt. No lock is held across Scheme callbacks, GC, barrier wait or blocking join.

## Reviewable QNT correspondence

New supplement: `models/gambit/lifecycle_contract_review.qnt`, checked by
`evidence/research/smp-retirement-study/verify-lifecycle-contract-review.py`.
It checks four sequential operations (two epochs in each of two campaigns),
same modeled producer, immutable owner/incarnation/key, pending before exit,
two abstract GC observations, real-result transition before publication/acquire,
grace before transfer/free, and a separately retained error terminal state.

| Model transition / invariant | Native obligation | Distinguishing mutant |
|---|---|---|
| claim→pending, debt and roots | Accepted keyed ledger before public Pending | Pending printed as errno, lost debt, lost root |
| exitWorker→joinZero | Actual worker exit and actual native join return | Synthetic zero before exit, duplicate join |
| publish→consume, matching fields | Release/acquire mailbox; full K/owner/source binding | Wrong owner, wrong incarnation, stale key, producer drift, omitted acquire |
| drain→transfer→reclaim | Real last-consumer grace and unique transfer/free | Transfer with no grace |
| error retained, no reclaim | Exact-origin failure keeps resources and identity | Erased error/debt/roots |

The supplement abstracts full K into bounded tokens and repeated GC into scan
actions. It does not prove C memory ordering, frame maps, scanning, native errno,
independent lanes, rollback, recurrent-GC fairness or donor termination. Those
have separate existing models (`retirement_progress.qnt`,
`retirement_reaper_contract.qnt`, `integrated_growth.qnt`) and source refinement
obligations. This turn is not a new combined proof of all those models. Prior
integrated84 controls superseded the old69 failure-return obligation-erasure
claim; neither is native admission. A passing error scenario means safe retained
failure, not successful recovery. Model campaign tokens are not two native runs.

Reproduce the supplement in registered audit scope with existing30s per-case cap:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-lifecycle-contract-review.py
```

## Two native campaigns: implementation and review prerequisites

These are future steps, not executed receipts. Do not run the existing sealed
old recipe expecting it to accept Pending. Do not invent a runnable new command
until its fixture, observer schema, source binding and budgets are reviewed.
Keep the existing dispatcher/task/production custody; inspect its research help
when constructing the reviewed Recipe rather than introducing a second runner.

1. **Freeze inputs after integration.** Register one completed producer containing
   the changes above. Bind all relevant runtime/Scheme/generated-C/header bytes,
   configured compiler/linker flags and exact GSI, plus probe and observer version.
   Preserve source→generated-C→linked binary identity; no reuse of historical
   GSI7263fe03 checks for a replacement binary. Keep original topology and budget.
2. **Campaign A, two epochs/two donors.** Independent native fixture gate holds a
   fully prepared donor before OS exit. Actual Pending must name K/owner/phase;
   claim-before-call is not proof libc is already blocking. Survivor executes
   repeated real GC and verifies actual continuation/thread/request, still/RC
   payloads and forwarded slots. Attempted reuse/teardown must refuse while debt
   remains. Release gate independently; capture actual join return0, keyed
   completion acquire, all borrower grace, one transfer/free and requested resize
   completion. Preserve epoch1 payload across epoch2 and require natural exit0.
3. **Campaign B, same frozen producer, independent process.** Repeat success; add
   donorA blocked while donorB completes, continuous GC with eligible finalization,
   lost hint with mailbox re-observation, donorA Ready/donorB preparation failure
   with collective ABORT, stale/replayed completion rejection and grace delay after
   join0 without rejoin. These subcases must be declared within reviewed unchanged
   budgets; a timeout is retained failure, not PASS or a reason to extend limits.
4. **Error-origin control in both campaign manifests.** At adapter boundary an
   explicitly labelled injected result can test RetainedError and exact-once
   cleanup refusal. It proves error-path handling, not a Darwin OS occurrence.
   Record any naturally occurring actual OS error separately. Review whether
   deterministic injection suffices for the error-handling sub-obligation; no
   empirical error→success capability is claimed without a reachable native case.
5. **First-eight regression and final consumers.** Verify the actual frozen
   producer preserves bootstrap/ticket admission, request uniqueness, accepted
   fault/coordinator roots, device-close retention, callback escape and self-
   termination protection, plus original first-eight contract tests. Assert root
   coverage through errors/exit, no pending lane/completion/VM consumer, parent
   reaped and group quiescent. Existing39 receipts are historical controls only.
6. **Review acceptance separately.** Two new immutable executions under the same
   work item are required; do not overwrite old lifecycle-join-recovery-1/2.
   Structured events include K, owner/lane lifetime, producer identity, monotonic
   event order, actual/injected origin, raw/encoded result, root/scan/borrower
   evidence, join/transfer/free counts and terminal requested-operation result.
   Independent adjudication must reject forged stdout, missing join0, wrong key,
   producer drift, unobserved grace, early free and retained error relabelled as
   recovery. Review fixture/Recipe/observer/milestone migration together only
   after authorization. Until then the live qualifier correctly remains8/12.

## Sufficiency judgment

The replacement is useful because it makes delayed completion legally reachable
and tests the unsafe interval while retaining original ownership and GC coverage.
It is not equivalent to every old assertion, and a reaper alone is insufficient.
Remaining implementation blockers are real Scheme landing/generated-frame
coverage, pending still/RC scanning, transactional membership/scan ownership,
native memory-order refinement, independent join capacity, complete return-path
service debt, no-fail final transfer or durable transfer log, and actual native
matched campaigns. Fail closed on unsupported external-C roots or raw frames.
This is a concrete review/implementation checklist, not9/12 or a stable-runtime
claim. The GC/FFI, Gerbil TYPEID and release gates remain independent and open.


## Post-join transfer refinement

See `../evidence/research/smp-retirement-study/post-join-transfer-protocol.md` for the current checked preflight, complete-splice ownership log, scan-domain removal and checked empty-donor destruction protocol. Generic cleanup can invoke foreign release and ignores scan-lock destruction outcome; it is not a non-failing finalizer. Partial recovery is roll-forward between complete units, not arbitrary mid-write rollback. The later per-file c86 observation binds the new native-tail ordering but does not certify the user-reported smoke binary. The lifecycle contract remains inactive at8/12.


## Finalizer authority and fatal-disposition follow-up

`../evidence/research/smp-retirement-study/finalizer-tail-handoff.md` specifies a persistent per-donor resource pin across keyed finalizer claim and worker-tail release, shared before-destruction admission, known common-result refusal and isolated local quarantine. Unknown shared guard/misc/sync unlock cannot safely rely on that transport or current callback/exit-based fatal_error; proposed raw process fail-stop is a distinct, host-compatibility-reviewed failure disposition, never successful lifecycle recovery. New finite22 controls distinguish successful cleanup, retained debt and process termination. Native refinement remains open; count8/12.
