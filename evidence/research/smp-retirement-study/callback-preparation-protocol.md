# Callback preparation: entry, roots, escape, and partial teardown

2026-10-23. Evidence and Grok implementation contract only. Qualification remains
8/12; no runtime, qualifier, recipe or historical receipt is changed. No native
run, other-thread operation, commit or push.

## What already exists, and what must not be inferred

The 4b8ae711 saved mem.c already contains
`___prepare_device_foreigns_vmstate` at4819. It visits active processor still
lists, selects exactly `___device_cleanup_from_ptr`, calls
`___release_foreign`, stops on a non-NO_ERR result and does not free still blocks.
setup.c calls it after resize/join and consumer checks, before checked IO cleanup
(:6829ff). This is a real device-specific preparation path, not a missing helper
we should reimplement under another name. Its canonical device failure owns a
still-linked native group; that guarantee is not inherited by arbitrary foreign
or procedural callbacks. The active processor loop is not itself a scan of the
proposed pending donor-domain registry. Existing strict no-pending cleanup may
exclude those donors; the general protocol must either prove that exclusion or
explicitly cover their roots, never assume coverage from processor_count.

9a03 `_thread.scm:3153–3229` already contains mapped Scheme exception/escape
control, cursor suffix retention and a VM-rooted fault-control record. Reuse its
mechanisms, not its terminal policy: `##fault-control-run!` ends in no-cleanup
exit, uses a singleton active item (slot7), and is not an arbitrary nesting-safe,
returnable generic cleanup driver. No generated generic preparation landing is
present/proved by these saved bytes.

All source locations below refer to immutable files recorded in
`callback-preparation-protocol.json`: setup/mem from4b8ae711,
c_intf/_thread(.scm/.c)/header from9a03, OS IO/_kernel(.scm/.c) frombad1e9aa.
They are per-file observations, not a coherent source-to-gsi producer binding.

## Actual entry routes and proposed change points

| Actual route | Safe preparation entry / required control |
|---|---|
| live Scheme resize -> native sync/resize -> worker interrupt disposal -> marker retirement -> OS exit | run owner-specific preparation at an unlocked Scheme landing BEFORE count commit/worker exit, while old cohort can service nested GC. `service_sync_op` cannot restore/allocate a Scheme frame or invoke generic callbacks under collective locks. Publish PREPARED or common retained failure, not member-local early return. |
| ___main / host -> ___cleanup / ___cleanup_checked | split checked cleanup into begin/prepare/finish. Begin acquires an owner capability before root admission closes or setup/IO state mutates. If an already mapped owner can dispatch the registered helper, use it. After the original ___run returned, a fresh private ___run of a startup-registered rooted preparation thunk needs explicit checked VM/P0/context validity. It is a proposed entry, not something current cleanup already does. |
| native embedding with no valid Scheme context | return NEEDS_SCHEME_PREPARATION/retained status before any destructive mutation. Do not fabricate a continuation or call a raw Scheme closure from C. A separately proven native-only device path may retain its narrower contract. Void legacy cleanup must not report success and allow host backing to be freed. |
| permanent fault coordinator | extend existing rooted record with a dedicated cleanup-job registry/stack; route recursive exit as intent using the existing route-exit mechanism. Do not restart coordinator or overwrite outer active item. |
| procedural interrupt disposal, setup.c:1473 -> release_procedural_interrupt:267 | current cleanup executes execute_fn(intr,FAL) while holding procedural mutex. Detach a capability-owned job/segment under lock, unlock, then dispatch its documented owner/context. Normal service_procedural_interrupts_pstate:280 already removes one node and calls execute_fn(...,TRU) outside lock; reuse that detach discipline, but add explicit retained current-job state on error/escape. |
| foreign-release! / GC sweep / native still cleanup | distinguish explicit Scheme release, GC finalization and terminal cleanup. All share release_foreign, but they do NOT have interchangeable context/root assumptions. See below. |

Owner affinity is a field of each job: portable P0 work, exact worker/OS owner,
or native-only. Never move an owner-bound C callback to P0 merely because the
fault coordinator is pinned there. A worker that still owns a callback cannot be
reported prepared or joined. A blocked callback can retain its generation; it
cannot be safely cancelled into a fabricated ACK. Arbitrary blocking callback
code on a GC participant also prevents a general cohort-progress proof.

## Concrete carrier and native job ledger

Proposed Scheme carrier: a typed cleanup record reachable from the existing
fault-control record (extend it with a new field; do not overwrite VM slot2 or
slot7), containing pending jobs, a per-invocation active-frame STACK, error/result
records, requested exit intent and retained jobs. Publish this root before any
original source root is removed. Existing `mark_vm_scmobj` (:7914) scans the VM
structure through mark_array/VM_SIZE; generated Scheme objects then trace the
nested carrier. Native control stores indices/full K and scalar tickets, never
untraced movable SCMOBJ pointers.

Each job's immutable identity is full VM/entry K + operation id + invocation
nonce + owner affinity + callback class. Native job state records native fn/ptr
ownership, result classification, parent capability and completed resource mask.
A checked native invocation stack associates the exact OS owner, full K, active nonce and parent capability with supported ___call/___run re-entry. DRAINING re-entry may derive only from that verified live parent; a TLS pstate pointer alone grants nothing. Nested calls push separate entries and leave the outer entry intact. The normal/TRY error finalizer pops exactly its own entry after its last VM access. Unsupported native unwind cannot silently pop or transfer this authority.

The Scheme job keeps the foreign wrapper or typed argument carrier, saved error,
continuation guard and suffix link. An opaque procedural `void *intr` is NOT a
root descriptor: every producer must declare native-only payload or supply a
typed root/capability carrier. Unsupported payloads fail closed.

Preparation sequence:

1. While source ownership is still intact, acquire parent lifetime and allocate
   job/carrier at a valid Scheme safepoint. On allocation/GC failure, leave the
   source linked; use GC-updated values, never restore old body pointers.
2. Under the relevant ownership exclusion, initialize full job and transfer
   source ownership to the already rooted job. Publish pending -> active frame
   before any next safepoint. No callback/allocation/GC under T/P/VM/procedural
   mutex or native list lock. Native list `next` cached across a generic callback
   is invalid if callback can mutate/reclaim that list; use stable job links.
3. Push a fresh invocation frame holding parent + child roots, exact nonce,
   recovery continuation and live flag. Mark CALLING and consume callback token
   before invocation. Invoke with locks released and a valid owner context.
4. After return, save scalar/result/exception classification before popping the
   active frame. Nested child results cannot overwrite the parent's frame or
   error. Resume from the stable job queue, not a freed C node or old list next.
5. Publish PREPARED only when no unresolved callback, child job, queued request or
   callback-created root remains. Actual GC and domain-transfer protocol still
   applies. Keep record and generation through all ACKs and native reader grace.
6. Drop roots and parent only after the last access; final native destruction
   uses the distinct exclusive ticket and resource mask. A parent is not dropped
   and reborrowed after entering DRAINING. Last release must have no VM tail.

Existing device preparation can remain a proven native-only specialization only
if callback/transitive virtual-method/context contracts are audited. The saved
`___device_cleanup` (:1773ff in OS IO) can select with positive-infinity timeout
on EAGAIN, and retries select EINTR. Thus “canonical device callback” does not
mean bounded or nonblocking. Carry the existing caller's absolute deadline into
prepared device progress; on known busy, retain the job and schedule later.
Do not reset the deadline per retry or expand the campaign cap. Retrying select
EINTR is distinct from repeating a close after uncertain EINTR; saved close-once
policy forbids the latter. Progress still depends on the device eventually
settling or an explicit terminal policy.

## Invocation state, failure retention and legal recovery

| State / observation | Preserved ownership | Permitted next step |
|---|---|---|
| QUEUED, never called | source-transferred job, root, parent, suffix | first invocation or explicit cancellation disposition with a registered disposer |
| CALLING | exact invocation frame/root + parent; original fn/ptr may be consumed | wait for that invocation's supported return/escape; no second invocation |
| RETURNED_OK | completed callback receipt and resource mask | process remaining jobs; no re-execution |
| RETURNED_ERROR / supported Scheme escape | error/result root, job and native resource debt, untouched suffix | continue independent never-called jobs only when dependency graph allows; do not infer external resource intact or freed solely from error code |
| native call did not reach supported landing | active root/capability remains; outcome unknown | quarantine/terminal containment; no automatic retry, reset or reuse |
| known native destructor BUSY before mutation | retain exclusive ticket and completed mask | retry only that unfinished native unit under same generation after recorded BUSY clears |
| partial native teardown with unknown outcome | retain backing for all unfinished/uncertain consumers; terminal phase stays closed | no rollback to OPEN; local quarantine or independent shared-fault stop according to actual failure domain |

`___release_foreign` (c_intf:1683) reads release_fn/ptr, clears both fields, then
calls release_fn. A non-NO_ERR can occur after the callback freed something.
The journal must capture fn/ptr ownership before this consumption, but **must not
reinsert consumed pointers into the foreign object or call them again**. Only a
callback-specific acknowledged idempotent recovery protocol could authorize a
new recovery operation; this is absent for arbitrary callbacks. Device group
retention is one concrete specialization, not universal rollback.

The existing Scheme wrapper `_kernel.scm:3905` raises an OS exception on a
nonzero status. A preparation driver catches/classifies that result in its mapped
frame; it does not erase the failure and call cleanup again. Existing fault
cursor advances suffix before invocation, roots current item in slot7, then
clears it after its wrapper returns. That is usable sequential containment, but
nested cleanup requires a frame stack; destructive state cannot live only in a
reusable singleton slot.

`dynamic-wind` exit handling can contain supported Scheme continuation escape;
a per-invocation live/nonce check rejects stale re-entry before executing user
code. A callback that requests exit only updates intent until outer preparation
settles. A native longjmp that bypasses Gambit's TRY/marker/dynamic-wind discipline,
OS cancellation or process crash is not made recoverable by this wrapper.
Explicitly forbid unsupported returns at the callback ABI, or treat them as
terminal/unknown; do not claim Scheme handlers catch arbitrary C unwind.

“Recovery” is therefore forward completion of proven unfinished work. Before
any callback token consumption/source publication, preparation can abort by
returning still-owned, GC-updated roots. After side effects or a native destructor
succeeded, generic rollback is unavailable. Resume uses monotone masks and exact
receipts; no replay of successful P0, callback, close or native release.

## Root and generated C correspondence

| Saved generated/source bytes | What is actually shown | What remains to implement/verify |
|---|---|---|
| _thread.scm:3153 callback wrapper | continuation-capture + dynamic-wind + exception catcher; live/returned flags; item included in rooted escape record | per-invocation nonce/frame stack and callback ownership outcomes; supported Scheme escapes only |
| _thread.c:21039ff, :21100–21180 | compiler closures capture record/item/recovery/live state; exception path builds vector and writes slot5; heap checks precede continuation-return | regenerate the new preparation helpers with independent maps; no copied bitmap or raw native continuation |
| _thread.c:31037–31048 | callback descriptors include RETI(0,0,0x3f), RETI(8,0,0x3f07), RETN(5,0,0x3) | these maps cover existing compiler frames only; changed liveness/nesting requires new actual descriptors |
| _thread.c:21183ff / :31049–31051 | cursor active-item/suffix stores, RETN(5,1,0x1e) | nested jobs keep outer item in separate traced frames; no singleton overwrite |
| _thread.c:21347ff / _thread.scm:3217 | record allocation, pinned coordinator, VM field2 root | extend the rooted record and all constructors consistently, before callbacks/GC; don't repurpose an occupied field |
| _kernel.scm:3905 / _kernel.c:22108 | raw ___release_foreign call, scalar status then exception branch; no executed W_ALL/R_ALL at this call in saved C | declarations PW_ALL are not a GC-capable arbitrary callback bridge. Either preserve proven native-only/no-GC ABI here or regenerate a proper context veneer/rooted landing for allowed re-entry; W_ALL alone cannot root raw C locals |
| c_intf.c:1683 release_foreign | fields cleared before native callback | no generic GC_SAVE of a raw ptr can prove its resource ownership; Scheme wrapper/object roots need traced carrier and readback after moving GC |
| mem.c:4787 sweep / :4819 prepare-device / :4844 free-still | three callers with different GC/context properties | audit separately; generic Scheme entry from GC sweep is not allowed. Queue an owned typed finalizer job for a post-GC landing, or preserve an explicitly native/no-GC callback class |

Deferring sweep callbacks changes timing/lifetime and possibly resurrection
observations. Do not silently claim compatibility with the first eight gates.
If queued foreign finalization is adopted, specify exactly-once observable
semantics, root retention and allowed resurrection, then rerun relevant GC/FFI
controls on the same native producer. If it is not adopted, enforce the existing
callback class/context restrictions; reject generic reentrant callbacks at that
entry. Current code alone does not prove either complete policy.

## Grok implementation and focused validation order

1. Register rooted preparation thunk/record during startup; add begin/prepare/
   finish to checked cleanup and resize preparation landing. Keep scalar READY
   helper non-GC; it is not the new callback bridge. Reject invalid external
   contexts before mutation. Bind caller/VM/owner K and stable parent unit.
2. Add job ledger (operation id, invocation nonce, callback class/affinity,
   consumed state, error/result classification and destructor mask). Add traced
   pending/active-frame/retained records; root before detach. Update procedural
   producers' payload/root contract. Extend fault record without slot collision.
3. Refactor cleanup_interrupts_pstate and native/foreign preparation to detach
   under lock, invoke outside lock, preserve current job plus suffix. Reuse
   normal service detach discipline and supported exception/escape machinery.
   ___release_foreign consumption becomes journal-visible, not retryable.
4. Implement explicit native-only vs mapped reentrant callback paths, including
   GC sweep decision. Regenerate _thread and affected _kernel C using the actual
   compiler/config; inspect frame descriptors, W/R context and nested root saves.
5. Pass empty-destructor ticket and monotone resource masks through pstate/VM/
   IO cleanup. Partial P0 success plus VM BUSY retries VM only. Unknown side
   effects retain/quarantine, never clear masks/reopen or rerun callbacks.
6. On one coherent relinked producer, test first p1/p11 startup and pre-mutation
   refusal; then parent/child callbacks with two actual moving GCs, exception,
   continuation escape/re-entry, recursive exit and nested request. Pause before
   detach, after root publication, while both frames live, and before final
   parent release. Require exact keys/invocation counts and actual root writeback.
7. Inject error after callback side effect and before status recording; assert no
   re-invocation, root/parent/suffix retained. Test native unsupported unwind only
   under its declared terminal/refusal contract. Nonreturning callback is retained
   debt/timeout, not completion. Independent queued jobs require explicit dependency
   classification, not blindly continuing after a parent failure.
8. Inject first-destructor success then known second-unit BUSY/failure; retry
   proves first unit unchanged/executed once. Inject unknown unlock/close outcome:
   no generic rollback or close replay. Preserve absolute deadlines/old caps.
9. Run GC/FFI/foreign callback timing/root controls affected by the policy plus
   existing narrow request/fault controls. These are prerequisites to separate
   formal lifecycle campaigns, not substitutes for them or authority to change
   the qualifier/history. New native test hooks are required; no invented
   executable command is represented as already available.

## Model and independent sufficiency judgment

`models/gambit/callback_preparation.qnt` combines two nested jobs, exactly-once
consumption, separate roots, two abstract moving GCs, metadata reader grace,
owner lifetime, supported escape/unknown retention and partial P0/VM teardown.
Four candidates cover normal, nested escape, unknown retained outcome and known
second-unit BUSY recovery. Ten negatives cover root-before-detach, nested root
overwrite, replay consumed callback, stale continuation execution, unknown-debt
release, missing GC writeback, root drop before reader grace, repeated P0
teardown, callback during terminal destruction and callback under lock.

The invariants derive root/count/phase constraints; no initialized PASS flag is
used. This finite composition assumes a valid generated entry and supported
escape landing. It does not prove C11 executions, real frame maps, arbitrary
native callbacks, unbounded nesting, eventual callback return or all first-eight
contracts. Reader/ACK lifetime and actual foreign ownership are required C
refinements. It complements earlier token and async-delivery models rather than
claiming a single mechanically linked C/native proof.

My judgment: a workable preparation/recovery contract is now specific, but the
arbitrary native-callback case still cannot promise general rollback or eventual
completion. The right closure condition is explicit supported callback/context
classes plus at-most-once ownership, rooted retention, monotone forward cleanup
and tested terminal policy. Without that ABI decision, a stronger gate/QNT cannot
turn unknown external side effects into safe retry. Count remains8/12.


### Checked completion witnesses

The companion verify-callback-completion.py adds only a pure target observation to the same action graph. It obtains decoded reachable terminal witnesses for Normal and PartialRetry after two abstract moving GCs and completed reader grace, with parent/child each invoked once, P0/VM each destroyed once, and carrier/owner released. PartialRetry includes a recorded BUSY then retry of VM only. This is existential reachability, not fairness or eventual completion. The 14 safety controls and these two reachability controls remain distinct evidence classes.


## Sweep/context follow-through

See sweep-finalizer-context.md/.json. Prefer explicitly registered deferred classes through existing will selection, not blanket transparent deferral. One foreign release claim must serve explicit release, will and cleanup, independently of consuming the will action; preserve a strong reference regained before their race. The saved manual specifies at-most-once per wrapper. Native pointer loans and valid checked C entry remain separate obligations. Deferred resource timing, multiple wills and C++ callback classification require compatibility review.
