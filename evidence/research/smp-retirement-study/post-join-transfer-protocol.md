# Join0 to memory transfer, scan-domain removal and final reclamation

2026-10-23 source/design review. The audit recorded qualification 8/12; that is an observed result, not a policy that fixes the count. Statements about no runtime/native/qualifier/recipe edits describe the original author's evidence-only execution scope, not a prohibition on another implementation owner.

Implementation sequences below are conditional design dependencies, not an approved executable work order or permission grant. They must first be resolved against one current, coherent source/generator/header/generated-C/producer identity. Per-file historical line numbers are evidence coordinates, never cross-generation patch offsets. This scope clarification does not alter the original observations, model logs, native receipts or qualification predicate.

See [recursive-ffi-journal.md](recursive-ffi-journal.md) for the corrected status: the cumulative one-winner foreign release patch is recorded as landed, while journals/control-reference lifetime, internal wills, checked bridges and new generated C remain unimplemented proposals in these reports. Plain-release-function observations below describe their saved snapshots and must not be read as instructions to redo the landed claim. The lock is the source authority here; the separate vendor engineering checkout is not required to match it and is not a drift test. Patch/lock agreement is not a configured build or current gsi certificate.

## Findings that change the implementation plan

`___transfer_mem_pstate` is a bounded-refactor candidate for a **conditionally
non-failing mutation core**. It allocates nothing, invokes no foreign callbacks
and makes no OS call directly. This does not make generic cleanup non-failing.
The current functions return void and omit checks for some native operations.
A void API is absence of error reporting, not proof that nothing can fail.

Use a checked preflight, a noninterruptible list-move core, per-resource ownership
progress at recoverable boundaries, and separately checked empty-donor cleanup.
Do not implement rollback by restoring a complete old pstate or re-running
generic cleanup. Preserve a quarantine descriptor when physical destruction fails.
This protocol handles supported explicit failure returns; it cannot recover
arbitrary pointer corruption, asynchronous longjmp/cancellation or process death
halfway through a multi-pointer ring splice. A native ownership journal is not a
crash-consistent transaction log.

## Exact observed source and failure inventory

The companion JSON binds the new per-file stable observation from mutable c86:
`.cache/tasks/repair-9-12/processes/audit/runs/9a03f325fe6d44c8822ade738df7c474/outputs/post-join-transfer-observation`.
These bytes are not a coherent completed producer/binary certification. The
user-reported new boot-p1 and p11 four-thread smoke exit0 were not rerun or bound
to receipts here. Old GSI7263fe03 and its39 checks do not certify these bytes.

| Observed function/field | Actual operation and failure boundary | Required implementation consequence |
|---|---|---|
| `mem.c:5482–5529 ___transfer_mem_pstate` | Equal donor/receiver returns silently. MISC_MEM_LOCK is the donor VM's `misc_mem_lock_` (336,386), then still splice, counts, RC ring splice, unlock. No allocation/callback/explicit error return. | Reject same pstate, different VM/generation, nonclosed mutation admission, nonzero borrowers and invalid receiver before mutation. Lock ownership must be established; do not treat ignored boolean lock result as ownership. |
| `5499–5506` still move | Traverses donor chain to tail; tail links old receiver head, receiver head becomes donor head, donor head clears. | O(number of still objects), not constant time. Valid acyclic list and preflight bounded count are prerequisites. During writes both heads can briefly alias; no GC/signal handler may observe intermediate ownership. |
| `5509–5512` accounting | Adds both donor word counters to receiver, then zeros donors. | Preflight range/overflow and conservation; log per-class accounting completion with splice. Replaying from a partial write can double count. Validate deferred-word semantics separately; do not arbitrarily combine counters. |
| `5514–5526` RC ring | Reparents first.prev, last.next, old receiver-first.prev, target.next, then resets donor sentinel. | Several dependent writes, neither atomic nor generally restartable. Validate both sentinels/ring ownership and native mutation quiescence. A callback or GC between these writes cannot be supported by a phase bit alone. |
| `5532–5546 ___cleanup_mem_pstate` | Calls free_still_objs, cleanup_rc, then destroys ready scan lock and unconditionally clears readiness. | Shrink finalization must use a distinct checked **empty donor** path. Do not use generic destructive cleanup as evidence that all live resources moved. |
| `4843–4862 free_still_objs` | Clears donor still head BEFORE loop; calls release_foreign for foreign subtype, ignores its result, then frees backing storage. | If leftovers exist, callback can fail/reenter/escape after list root was detached. Require empty donor before entering final cleanup; unexpected leftovers refuse/quarantine without invoking callbacks. |
| `c_intf.c:1683–1714 ___release_foreign` | Saves release_fn/ptr, clears fields, invokes arbitrary release function, returns non-NO_ERR. | Error after an irreversible user side effect is not safe retry. Do not reconstruct the old pointer/function or replay callback. This belongs to separate rooted callback/suffix/error preparation, outside finalization/GC exclusion. |
| `mem.c:690–705 cleanup_rc` | Clears RC sentinel before freeing each header via FREE_MEM; no Scheme callback in this body. | Empty-donor finalization should have no headers to free. Generic cleanup is destructive and not a recovery log for partial traversal. |
| `gambit.h.in:6149,6270–6286,10928–10930` | Ticket-lock destroy is empty; mutex spinlock selection maps destroy/lock/unlock to POSIX boolean macros. | Which branch is selected requires final preprocessing/config flags. In mutex branch destruction can return false; current cleanup ignores it and clears ready. Record raw native return in a checked wrapper; do not infer errno from a boolean. No actual destroy failure was observed here. |
| `os_base.c:265–324,385–414,479–505` | Standard free has no recoverable result. Low-level executable-heap branch can route to munmap/VirtualFree, whose status is ignored by void free_mem_code. | Shrink empty-donor cleanup avoids these frees. Whole-VM allocator cleanup is a different contract; do not claim all configurations have a reportable or non-failing free. Corrupt allocator state is outside safe rollback. |
| `setup.c:2089–2107` | Real join0→setup_native_tail_leave→transfer→cleanup; failed join stores result and retains tail. | Tail end certifies worker C-tail exit only. Install keyed finalizer/record/VM borrow BEFORE releasing tail, or prove an existing equivalent borrow spans every remaining access. Do not equate native_tails0 with reclaimable. |
| `setup.c:847–873 setup_publish_clean` | Also checks outer_owner/context readers/native_entry_users; tail0 alone does not currently make CLEAN. | A premature-free event is NOT established by the tail ordering alone. Audit every entry/teardown route; explicitly encode finalizer debt rather than relying on unrelated outer setup ownership. |
| `mem.c:7355–7415` scan work stealing | Remote workers access another pstate queue/lock and scan stolen chunk after unlock. | Queue-empty or lock-unlocked is not a grace certificate. Track lifetime of actual stolen-work references and GC snapshot; close fresh admission before waiting for zero. |

`___transfer_mem_pstate` does not move arbitrary processor registers, Scheme/C
frames, heap chunks, msection ownership, interrupt queues or device handles.
Those must already be prepared/drained or accounted for by their own owners.
This protocol does not silently broaden what these two list splices accomplish.

## Proposed state, ownership log and linearization points

One entry per immutable K=(VM instance, resize epoch, donor slot incarnation,
native-handle lifetime, join-lane generation). A finalizer ticket additionally
binds the current stable receiver incarnation and elected service sequence.
Storage is reserved before shrink commit. Native fields contain no untraced
movable Scheme values. Typed VM carriers root any Scheme data independently.

Add the following proposed native fields with their checked owner protocol:

- `join_zero_latched`, `finalizer_users`, `scan_admission_closed`, `scan_readers`,
  handler/queue/wake/selector/native borrower counters and finalizer ticket;
- `resource_owner[STILL,RC]` = DONOR/RECEIVER, `intent_mask`, `moved_mask`,
  `accounted_mask`, source/destination sentinel/head/tail identities and planned
  scalar counters; these are native descriptors, not copied SCMOBJ roots;
- `scan_owner_mask` for pending donor resource classes and receiver normal roots;
- `destroy_attempted`, `destroy_outcome` (NOT_ATTEMPTED/SUCCEEDED/FAILED/UNKNOWN),
  `scan_lock_ready`, `cleanup_error`, `quarantine`, `reclaim_complete`;
- actual origin-labelled errors, monotonic phase/service sequence and exactly-once
  transfer/reclaim latches. No epoch reset while any entry/reader can use it.

States: JoinedAwaitingGrace→PreparedTransfer→StillMoved→RcMoved→DomainRemoved→
Destroyed→Reclaimed. Failures at proven boundaries retain the last state and
per-resource owner; they do not roll back successful joins or completed moves.
Retained preflight is donor-owned; retained partial transfer is split-owned;
retained destroy failure is receiver-owned data plus quarantined donor control.

### A. Before first destructive write

1. Acquire/validate completion release publication for exact K and actual join0.
   Latch it once. Acquire the finalizer record/VM lifetime borrow before decrementing
   the worker-tail obligation; this is a responsibility handoff, not a zero gap.
2. Close fresh donor scan/queue/native mutation admission. Drain old readers and
   exported chunks. A joined worker cannot mutate its lists, but remote/host RC
   users still need established quiescence. Receiver must be stable, pinned and
   excluded from another resize/cleanup through transaction completion.
3. Enter the already elected all-member GC-quiescent service window. Complete
   the previous GC's accounting/barriers; no new root snapshot starts in it.
   Keep every participant on the same result/barrier transcript, even on refusal.
4. Establish required native lock ownership before mutations. Preflight keys,
   lists, counts, root destination, owner masks, all resources needed by the
   mutation and empty private work. Reject corrupted/unbounded chains before
   splice. Validation itself assumes registered valid storage; it cannot safely
   dereference arbitrary corrupt pointers. No allocation/callback/OS call or
   fallible validation is permitted after the first write inside a splice unit.

The preferred normal path executes both splice units in one window. The log
allows an explicit failure/abort only BETWEEN complete units. It is not permission
to return between first.prev and target.next writes.

### B. Move still, then RC; publish ownership before GC resumes

5. Under the exclusion, record STILL intent and precomputed counter deltas. Move
   still chain, clear donor chain, commit both counter transfers exactly once,
   and set owner/moved/accounted masks as one non-failing unit. Destination roots
   are authoritative before donor coverage is removed for this class.
6. Do the same for RC ring reparenting and donor sentinel reset. No headers freed,
   no release callbacks run. Keep real header->data for active GC writeback; a
   cached value in the native log is not its root location.
7. Before leaving ANY supported partial boundary, align scan ownership with
   completed units: receiver scans moved STILL, pending domain scans unmoved RC.
   Exactly one owner per resource class. Publish masks/root visibility in the
   same GC-excluded transaction as the pointer changes. A future GC cannot scan
   the moved chain both through donor and receiver, or neither.
8. Once both units and accounting are complete, pending donor scan_owner_mask is
   empty. Remove its **scan domain** inside the same exclusion after old snapshot
   grace. Do not remove its lifetime/quarantine registry entry. The emptied scan
   domain and retained native cleanup descriptor have different purposes.
9. Publish common success/retained result through the collective transcript;
   release native locks, then leave the service window. If unlock ownership is
   unknown, do not enable GC/mutators or pretend to return safely: mark fatal
   quarantine through a proven independent path. Journal state alone cannot
   repair an uncertain native mutex or inconsistent collective. Progress is not
   claimed for this fault class.

### C. Checked empty-donor destruction and final release

10. Proposed `___cleanup_empty_mem_pstate_checked(entry)` verifies donor still
    head0, RC sentinel empty, both counters0, private queues drained, no admission
    or readers, no scan-domain membership, all moved/accounted masks and stable
    key. It must NOT call free_still_objs/cleanup_rc on nonempty leftovers.
11. Destroy only the initialized scan lock. Ticket-lock no-op is an explicit
    backend success; POSIX mutex wrapper returns actual status. Clear ready only
    on confirmed success. On failure retain error, ready and native descriptor,
    keep slot nonreusable, and report TransferredCleanupRetained. Roots/data stay
    at receiver and can continue being collected; do not splice them back.
12. Destroy failure does not justify blind retry: another attempt requires a
    documented native postcondition showing the object remains initialized and
    why the failure is now resolvable. UNKNOWN is not retryable. Confirmed
    success must never be destroyed again. Whole-pstate/OS cleanup, already
    executed by worker, must not be repeated from this memory-finalizer path.
13. After finalizer/metadata/completion readers acknowledge, release record/slot
    lease and carrier only when its remaining references have a live destination.
    Publish Reclaimed once, then release the last VM/finalizer borrow after the
    final access. No new incarnation until all native/helper lifetime consumers
    are clear. Helpers idle on VM-owned lane controls are still VM consumers.

## Recovery table: no reverse splice

| Failure or interruption boundary | Authoritative ownership | Next supported step |
|---|---|---|
| Preflight refusal / held reader | Donor still+RC, scan domain and carrier intact, join0 latched | Correct explicit precondition then same-key preflight. No second join. Other donors may progress. |
| After full STILL unit, before RC unit | Receiver STILL/counters; donor RC; split scan-owner masks | Acquire same finalizer ticket in another elected window, verify log, skip STILL+its accounting, move RC. No old-byte rollback. |
| After RC unit before domain removal | Receiver all lists; donor empty; native domain still registered with empty mask | Check both masks; remove empty scan domain under exclusion/grace. Never replay either splice. |
| After domain removal / lock destroy fails | Receiver data; donor lock/slot/control quarantined; no donor scan class | Preserve actual failure/readiness. Independently review conditional retry; ordinary GC scans receiver and never touches quarantine scan lock. |
| After confirmed destroy, before reclaim publication | Receiver all data; native record still pinned; lock destroyed | Complete metadata/reclaim acknowledgement only; never destroy/join/transfer again. |
| Unexpected residual foreign object | Whoever owns untouched resource; no callback invoked by empty cleanup | Stop before disposal, diagnose missing ownership; route only through separately rooted callback protocol if authorized. Never erase callback fn/ptr to manufacture completion. |
| Mid-splice fault / lock release unknown | Inconsistent or unverifiable native state | No safe automatic continuation promised. Stop execution through an independent fatal mechanism; preserve evidence. WAL or a phase bit does not make arbitrary C faults recoverable. |

The log lives across supported operation failures in a live process. It is not
persisted for restarting a dead process, and no on-disk Scheme-pointer recovery
or whole-memory restoration is proposed. If recoverable failure must occur
inside a splice, replace that representation with versioned descriptors and
reader protocol; do not add a try/catch around raw pointer writes.

## Grok implementation and acceptance checklist

1. In `mem.c`, factor checked preflight and native move core from existing5482.
   Keep the historical exported signature/other call contracts intact until
   their callers are reviewed; new shrink path uses checked helpers and ledger.
   Suggested private helpers: `retirement_transfer_preflight`,
   `retirement_move_still_no_fail`, `retirement_move_rc_no_fail`,
   `retirement_publish_scan_owners`, `cleanup_empty_mem_pstate_checked`.
2. In `setup.c`, replace join0→tail_leave→void transfer/cleanup with exact-key
   join latch→finalizer borrow→tail release→deferred service protocol. Adapt
   cleanup/native-consumer/CLEAN checks to include unreclaimed entries, including
   transferred-but-destroy-failed ones. Do not store only a global last error.
3. In `gambit.h.in` and typed VM layout, bind per-entry ownership masks, checked
   lock outcomes, lifetime references and receiver generation. Preserve existing
   callback/fault roots. Registry masks and pointer/list ownership must agree
   before every future root snapshot. Preallocation/capacity failure is precommit.
4. Use the mandatory post-GC service window and independent donor lanes already
   specified in `retirement-progress-protocol.md`/`resize-service-debt.md`.
   Do not wait for a blocked donor or all VM helper pins to finalize another donor.
5. Native focused tests on ONE final bound producer (future authorization):
   empty/nonempty lists, multiple foreign objects and RC headers, repeated GC
   while pending and after split STILL transfer, same-key resume without double
   accounting/join, injected preflight failure, deterministic failure BETWEEN
   units, destroy-failure before success/readiness clear, success-before-reclaim
   delay, held exported scan chunk, attempted cleanup/reuse and receiver resize,
   two epochs, lost completion hint and stale receiver/K. Assert foreign release
   is never invoked by empty-donor finalization and transferred payloads survive.
6. Test mutex-backed and ticket-lock configurations separately using actual
   preprocessed headers/compiler flags. Label injected destroy/lock failure as
   injected; verify raw status retention. Do not simulate partial-write recovery
   by permitting GC inside an inconsistent ring. Unknown unlock path needs a
   separate no-resume/fatal control, not a normal PASS for VM continuation.
7. Capture list ownership and separate word/deferred counters, scan masks/leases,
   finalizer/VM pins, join/transfer/destroy/free counts and root payload identity.
   Native first-eight, final lifecycle campaigns and other open gates remain
   separate. New smoke results do not constitute these checks or9/12.

Performance: normal transfer still traversal is O(n); preflight validation adds
work and must stay within original watchdogs. Preparation can compute validated
tail/count hints only while list mutation is closed and must invalidate them on
change. Ledger storage is O(accepted donors); boundary updates are constant-size.
No extra callback, allocation or polling loop belongs in the splice core.
Costs and exclusion latency remain unmeasured until native integration.

## QNT evidence and proof boundary

`models/gambit/post_join_finalize.qnt` models a joined donor with STILL/RC owner
classes, close/drain, intent+exact-once transfer/accounting, per-class scan coverage,
receiver-root coverage, domain removal, checked destruction, finalizer pin and
supported partial roll-forward. Error terminals preserve state; an unknown unlock
retains exclusion and does not assert VM progress. Six candidates cover normal,
preflight refusal, partial resume, destroy failure, unknown unlock and held reader.
Twelve mutants target early domain removal, double splice/accounting, erased
partial log, ignored destroy failure, dropped pin, live reader transfer, callback
in cleanup, second join, resume after unknown unlock, early root drop and missing
intent. Negative controls require decoded distinguishing invariant witnesses.

The model starts after a valid actual join0; it does not create native evidence.
Resource-class moves and journal updates are atomic abstractions requiring the
non-failing core above. It does not prove a real RC ring's writes, GC maps,
counter ABI limits, C memory ordering or safe fatal handling. Two accounting units
abstract the actual distinct word/deferred counters, not their representation.
Future native fault injection and source-to-machine-code binding remain required.

Reproduce in registered audit role, unchanged30s/case TLC limits:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-post-join-finalize.py
```

The companion JSON records actual results and source hashes. This follow-up
narrows the previous contract's no-fail-or-log requirement into implementable
units; it does not change the still-active OS-error-to-same-owner-join0 gate.


## Lifetime and unknown-lock follow-up

See `finalizer-tail-handoff.md` for the keyed resource-pin protocol and actual teardown/fatal-call source correspondence. Keep one resource pin through tail-to-finalizer phase handoff; do not make two independent counters the reclamation certificate. Extend teardown admission BEFORE destructors, not just late CLEAN publication. The earlier initUnlockUncertain model retained exclusion and did not prove a real cohort exit; shared guard/misc/sync uncertainty now requires an independently reviewed callback-free process-fatal branch, while donor-local quarantine requires a proven dependency cut after common exit. Current fatal_error/exit hooks are not that branch. No runtime or formal gate change is implied.
