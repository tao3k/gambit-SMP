# Patch specification: old-cohort materialization and retirement GC owners

2026-10-23. Repository evidence and QNT only. No runtime/native execution,
other-thread operation, staging, commit or push. Current acceptance stays8/12;
no observer, sealed recipe or milestone migration is performed.

## 1. Concrete decisions

Use the existing capture/GC machinery instead of copying live C stacks. Add a
native **scan-owner registry**, distinct from active processor membership:

- PREPARING/PREPARED donor: still an active GC participant and native list owner;
  its registration is not an additional scan domain.
- PENDING/JOINED donor: no longer participates, but its frozen native still/RC
  lists are scanned by an active collector using a pinned owner descriptor.
- RECEIVER ownership: after successful join, borrower drain and one collective
  transfer, the same native lists belong to the receiver and are no longer in
  the pending registry.

At every GC setup, each native list has exactly one scan owner. Scheme root
references may overlap harmlessly; native lists/scan links must not be enrolled
twice. This distinction closes a hole in a naive 'register before commit' patch.

## 2. Proposed fields, with actual layout anchors

These are new fields/interfaces to implement, not existing guarantees.

| Location | Proposed fields | Access discipline |
|---|---|---|
| VM native state (`gambit.h.in`) | `retirement_epoch`, `retirement_domain_version`, `retirement_entries`, `retirement_registry_mut`, `retirement_gc_readers`, `retirement_finalizing` | Native addresses retained by valid VM borrow; registry metadata/readers protected by one mutex; structural changes additionally require GC collective exclusion |
| Native entry | Full immutable VM/slot/handle incarnation; `prepare_state`, `native_list_owner`, `prepared_gc_epoch`, `abort_requested`, `abort_ack_epoch`, join/mailbox state from prior proposal | Same-generation prepare/abort acknowledgements; never infer success from active count or a VM-global witness |
| VM Scheme object | Append `retirement-roots` to `_thread#.scm:define-type vm` and `macro-make-vm`; update `gambit.h.in:___VM_SIZE` together | Typed VM field scanned by `mark_vm_scmobj`; preserve existing field2 fault coordinator and existing field offsets |
| Per-entry Scheme root record | Thread/continuation; authoritative register/saved/cache vectors where live; processor/request/queue references; preparation callback cursor/current/suffix/error; abort continuation/state | Access through rooted Scheme references; no movable carrier/body pointer cached in a malloc entry across GC |
| Native GC snapshot | Immutable generation/version, frozen `___processor_state` owner pointers, active/pending classification and list ownership tokens | No movable SCMOBJ payload pointers; acquire reader lease at setup and retain through cleanup/accounting/last use |

Use a new integer GC-completion stamp if needed; do not repurpose floating-point
`nb_gcs` as an atomic synchronization token. A stamp only records a completed,
validated rendezvous. It is not evidence by itself that every live reference was
exported. Per-entry native key must not be truncated into an unchecked fixnum.

## 3. Frame materialization: actual chain and implementation sequence

Actual anchors: `_thread#.scm:1422` delegates macro-thread-save to
`##thread-save!`; `gambit.h.in:6319` `___THREAD_SAVE` can assign raw fp into
`___THREAD_CONT_FIELD(thread)`'s frame slot. `mem.c:3822`
`mark_captured_continuation` recognizes the stack representation, copies frames,
writes forwarding links and updates the actual captured-root reference.
`mem.c:4053` `mark_continuation` walks fp/stack_break with real frame maps.

### Scheme preparation entry, outside the count-changing C collective

Proposed `##retirement-prepare!` / `##retirement-landing!` in `_thread.scm`:

1. P0 allocates and roots the per-epoch carrier and native registry prefix while
   all old processors remain members. Invoke private preparation only outside
   held T/P locks and before `___current_vm_resize` enters OP_VM_RESIZE.
2. Each donor closes public work admission for this epoch, saves its live Scheme
   thread through the supported save path and publishes the saved thread/root
   record into the already rooted carrier. Migrate queued runnable work and
   result-mutex request ownership through existing lock-protected mechanisms.
3. Detach preparation callback suffix under its native queue lock, release the
   lock, then invoke callbacks with rooted current/suffix/error state. Current
   `cleanup_interrupts_pstate` calls `execute_fn(intr, ___FAL)` under the native
   mutex; do not copy that into a GC-capable preparation loop. Retain non-NO_ERR
   and nonlocal escape disposition using the existing protected control pattern.
   Do not re-run consumed callback prefixes during rollback.
4. Retirees park at a supported Scheme control state that still participates in
   private sync/GC. New helper dispatch must not block the old cohort in a C
   collective while waiting for a Scheme callback to run.
5. Force a completed old-cohort GC/materialization rendezvous after all live
   captures are in the carrier/global root graph. Confirm continuation-frame
   references have their current GC-updated representation, and each live
   register/saved/cache/processor value has an authoritative traced owner.
   Only then publish PREPARED(g) with the prior release/acquire protocol.
6. Keep preparation frozen: no post-materialization callback, new captured raw
   user frame or user work may be added on the retiring side. A supported final
   nonreturning C entry may use native epoch/slot IDs only. It must not touch
   Scheme deque objects after population commit; move that work earlier.

`##gc` is not a magic cure: if a reference was absent from the root graph, a GC
cannot discover it. A new capture after the rendezvous invalidates preparation.
An arbitrary raw C frame cannot be made resumable by saving fp or invoking
thread-restore. Returnable foreign/sfun-marker paths require a valid landing
context or refusal before commit. Inspect generated C for the nonreturning tail.

### GC failure and rollback are not reversal of the collector

In current `___garbage_collect_pstate`, setup/strong/weak/cleanup are followed by
heap resize, `prepare_mem_pstate`, and return of `overflow`. Objects may already
have moved even if requested space is insufficient. Do not restore pre-GC fp,
fromspace selectors or register bit copies on that error path.

Proposed `##retirement-abort!` sends epoch-specific ABORT to every old member.
A Ready donor resumes/re-enqueues via its **current** rooted thread/continuation
and supported `##thread-restore!` path, with GC-forwarded references. Error/suffix
and consumed callback cursor remain rooted. A donor that never saved a new
continuation acknowledges remaining in its existing state; it is not forced
through another donor's restore path.

P0 does not drop the carrier, clear preparation records or admit a new epoch
until all old members' ABORT_ACK(g) and relevant native reader grace are observed.
No count or native list ownership changed, so PREPARING entries can be removed
without splicing still/RC lists. Partial preparation does not authorize reclaim.
If a member fails to acknowledge, retain the carrier/epoch and report failure;
never manufacture rollback completion. Existing sticky VM cleanup remains separate.

## 4. Pending still/RC scanning: proposed mem.c helpers

Keep existing collector allocation context. Do not call whole-GC helpers with
retired donor ps as if it were an active collector. Factor **owner traversal**
from **collector mark/work machinery**:

| Proposed function | Source to reuse | Exact job |
|---|---|---|
| `retirement_gc_snapshot_begin(collector, vm, view)` | `garbage_collect_setup_phase:7230`, `___garbage_collect_pstate:7466` | Under registry mutex pin pending owners/version. Build active owners plus eligible PENDING/JOINED owners, assert disjoint identity/list ownership. Release mutex before traversal. PREPARING entries are excluded. |
| `setup_still_owner_to_scan(collector, owner, tail)` | `setup_still_objs_to_scan:4365` | Reset every owned header's mark state; enqueue nonzero-external-ref objects into collector work list. Compose active and pending owner lists once, after collector's own setup, before existing setup barrier. Do not overwrite the pending queue with another initialization call. |
| `mark_rc_owner(collector, owner)` | `mark_rc:4124` | Walk owner's stable RC headers and invoke `mark_array(collector, &header->data, 1)`. Update the actual data slot when objects move; a temporary copied Scheme value or carrier cache is insufficient. |
| `retirement_gc_mark_pending(collector, view)` | `garbage_collect_mark_strong_phase:7268` | P0 marks pending RC roots in its active context; other ordinary Scheme carrier references are reached through `mark_vm_scmobj`, not stale native addresses into moved carriers. |
| `retirement_gc_account(view)` | `determine_occupied_words:6684`, `words_still_objs_` and deferred accounting | Include pending retained native storage/still bytes once; preserve deferred allocation counters until charged/cleared consistently. List transfer changes ownership, not total allocation. |
| `retirement_gc_snapshot_end(vm, view)` | End of `___garbage_collect_pstate` | Release only after strong/weak/cleanup, accounting/resize and any later snapshot use. Returning before last use is not grace. Error paths must also release only after the collector has finished those uses. |

Proposed per-GC C-shaped outline (design, not an applied patch):

```c
/* ___garbage_collect_pstate, after the initial collective barrier: */
if (is_P0) view = retirement_gc_snapshot_begin(active_collector, vm);
garbage_collect_setup_phase(active_collector, is_P0 ? &view : NULL); /* A */
BARRIER();                                    /* existing setup -> mark boundary */
garbage_collect_mark_strong_phase(active_collector, is_P0 ? &view : NULL); /* B */
BARRIER();                                    /* existing strong -> weak boundary */
/* Existing weak/cleanup/resize/accounting, with pending owner coverage. */
if (is_P0) retirement_gc_snapshot_end(vm, view); /* after its final use */

/* A: INSIDE garbage_collect_setup_phase, after active still setup: */
setup_still_objs_to_scan(active_collector);     /* existing active owner */
if (is_P0) setup_pending_still_owners(active_collector, view);
/* Function returns to the existing setup-phase barrier. */

/* B: INSIDE garbage_collect_mark_strong_phase, in the root prefix: */
/* existing VM/global/RC/continuation/register/saved/cache/processor roots */
if (is_P0) mark_pending_rc_owners(active_collector, view);
BARRIER();                                    /* existing INTERNAL root barrier */
mark_reachable_from_marked(active_collector);  /* existing shared closure */
```

`view` is a native local in `___garbage_collect_pstate`; extend the two internal
phase helper signatures explicitly to receive it (NULL for other collectors).
Do not introduce a hidden global movable root pointer. The concrete RC traversal
uses `head = &owner->mem.rc_head_`, then marks `&header->data` with the active
collector context; it must not resolve the old `rc_head` macro against the donor
as collector. Pending still setup can prepend each externally referenced native
header to the collector's existing `still_objs_to_scan_` list after mark reset,
using existing header/link conventions and unique-owner checks.

The pending RC insertion must precede the **internal root barrier and strong
closure**, not follow the return from the whole strong-mark function. Pending
still setup likewise precedes the setup completion barrier and cannot be
subsequently overwritten by active-owner initialization. The snapshot passed
between phases contains fixed native owner pointers, not cached addresses into
moving Scheme carrier vectors. Root carrier references are updated through the
ordinary VM/object graph marking path.

Freeze mutation of the donor native lists with respect to its exiting thread.
Active Scheme setters such as `___set_data_rc` may legally change actual RC data
between GCs under the existing participation discipline; the next GC must read
and forward that new value. Nonparticipating external host C callers require
explicit GC-safe admission/quiescence; a lifetime borrow alone is not that rule.

Conservatively defer sweeping/freeing pending owners' dead still objects and
foreign finalizers until successful ownership transfer. **Still initialize marks
and trace their live external/reachable objects each cycle.** Retained memory
must be accounted separately from true live-object statistics (for example a
`retirement_retained_words` capacity term); do not label conservative retention
as proof of live reachability. No retained bytes may vanish from allocation
limits or be counted twice on transfer; it is not permission to mark everything live or omit roots.
Do not globally disable sweep for ordinary active owners. Receiver's normal
sweep owns the transferred lists once pending ownership is removed.

## 5. Atomic membership/domain commit and finalization

### Active→Pending commit

Add a reviewed collective commit branch in setup.c. With all preparation tokens
validated and no GC view in progress, change native list ownership from ACTIVE
to PENDING and publish reduced processor_count as **one GC-excluding transaction**.
Publishing either side earlier lets a collector miss a donor or enroll it twice.
A prepared registry entry can exist earlier, but is not scan-eligible earlier.

### Pending→Receiver removal

New `OP_VM_RETIRE_FINALIZE` should be a noncombining operation, with a reviewed
priority/result protocol in `execute_sync_op` / `execute_sync_op_loop`:

1. All current survivors select the same operation; prior GC has finished its
   full view lifetime. Verify actual keyed join0, acquired completion/consume
   ownership, no old handlers/queue borrowers and zero native GC readers.
2. Close new pending-owner snapshots under the registry mutex while the agreed
   collective excludes GC. If unavailable, return JoinedAwaitingGrace/Pending;
   do not wait while holding locks or rejoin a successfully joined worker.
3. Install destination Scheme roots; splice donor still/RC to receiver with
   `___transfer_mem_pstate` under its existing MISC_MEM_LOCK; update owner records
   and accounting; remove pending registry membership. No collector can observe
   the interim states. Structural native owner transfer and removal are one
   transaction even if implemented as several instructions.
4. Clean empty donor native lists/scan lock with `___cleanup_mem_pstate`, then
   release carrier/slot lease only after all associated final consumers are gone.
   Retain on any error; descriptor close remains behind its own grace checks.
5. Publish common result and only then let survivors leave to schedule or start
   another GC. Keep helper/VM consumer pins until their independent completion,
   stop acknowledgement and actual helper join.

`execute_sync_op_loop:1301` elects an operation via barrier, dispatches it and
loops until common NOOP. Existing resize additionally broadcasts a result with
`OP_VM_RESIZE_RESULT`; `resize_caller` has special deferred-error handling.
Do not add an opcode and forget its common result/throw path. Extend the same
agreement discipline for finalize so one member cannot return/throw while peers
wait at another barrier. Do not select a numeric priority without reviewing the
existing combining/priority scheme.

The finalize branch must not allocate Scheme objects, invoke callbacks, issue
`on_all_processors` recursively, or wait on reaper/foreign code. Then selected
GC and selected finalize are sequential operations of this loop, rather than
concurrent operations hidden inside one another. MISC_MEM_LOCK alone supplies
neither that exclusion nor safe object lifetime. Native helper threads are not
participants in this collective and remain explicit last consumers.

## 6. Ordered patch work and tests for Grok

1. Add typed carrier/epoch/cursor/abort fields and preparation parking path in
   `_thread#.scm`, `_thread.scm`, `gambit.h.in`; preserve fault field2. Before any
   count change test raw captured frames, successful old-cohort materialization,
   allocation error after GC forwarding, donor2 error after donor1 Ready, suffix
   error/nonlocal escape, current-continuation restore and all-member ABORT_ACK.
2. Factor RC/still owner helpers and add snapshot leases/accounting in mem.c/h.
   With active membership unchanged, validate normal scanning parity first.
   Then implement explicit active/pending owner selection and count/domain commit
   together; never enable pending enrollment while a donor remains active.
3. Add native pending-domain tests: two consecutive GCs, new RC data between
   them, actual RC-slot writeback, still mark reinitialization, no duplicate scan
   enrollment, retained-memory accounting and no premature foreign finalization.
4. Add elected finalize/result path in setup.c, reuse transfer/cleanup only after
   exact join+grace. Force join0 while a native GC snapshot lease is held;
   require finalize refusal until GC completes, without another native join.
   Test GC requested on either side of the selected operation and stale epochs.
5. Integrate with the fixed reaper/mailbox protocol and native worker-gate tests
   from earlier contract evidence. Regenerate C/header, bind one completed
   producer and run matched focused regressions before any approved formal
   pending-contract migration. Do not relabel existing39 passes as coverage.

Acceptance must verify **real locations and object values**, not Ready/rooted
booleans: source-bound generated frame representation, carrier references after
GC, native header->data after relocation/mutation, list identity enrollment,
result/callback prefix counts, active population restored on abort, snapshot
reader counts and exactly-once transfer/cleanup. No changed timeout, heap floor,
processor count, expected output or historical receipt is part of the repair.

## 7. QNT refinement, assumptions and retained boundaries

`models/gambit/retirement_materialization_domain.qnt` adds two donors and explicit
active/pending/receiver native-list domains. Four candidate initializers cover
normal completion, donor2 failure, heap-space failure after GC has updated roots,
and join completion while a GC snapshot is still live. It includes two pending
GCs with an intervening RC mutation and authoritative slot forwarding.

Twelve mutants target raw-frame commit, a missing native scan-owner interval,
double active/pending enrollment, RC writeback omission, second-GC still reset
omission, pre-GC frame restore, callback prefix replay, carrier drop before ABORT
acknowledgements, domain removal during a scan, domain removal before receiver,
free while a scan lease exists, and next-epoch reuse before abort completion.

Frame/RC address versions are abstract relocation tokens, not actual stack or
heap addresses. Common collective selection and closed-domain transfer are
explicit model transitions whose C refinement is owed. The model does not prove
C frame-map validity, arbitrary external host participation, callback termination
or that a new opcode was implemented correctly. It complements, rather than
reruns or replaces, the existing reaper/publication models.

The bounded audit runner retains logs, model snapshot and decoded negatives:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-retirement-materialization-domain.py
```

Formal native admission still requires a separately reviewed pending contract,
actual implementation and real receipts. This document/model is not native9/12.

## Landing and collective refinement (2026-10-23)

See [retirement-landing-collective.md](retirement-landing-collective.md) for
verified entry classes, consumptive restore/ABORT agreement, losing finalize
retention after GC, common result errors and 19 additional model controls.
These interfaces remain proposed; the native post-run loop still needs an
explicit supported context classification.
