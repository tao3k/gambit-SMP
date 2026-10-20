# Current SMP Repair Research

## Objective And Separation

This research serves the owner's current **9/12 -> 12/12** objective. It does not
recount native gates, replace the implementation owner's source or authorize an
execution. Current failure analysis and bounded source repair belong with the
existing executable models even when the cause or implementation is still open.
Only a changed architectural mechanism belongs in
[Experimental](../models/experimental/README.md). In particular, adding another
finite waiter phase is not itself a refactor milestone.

No runtime, compiler, source lock, qualification manifest, checkpoint or native
test is changed here. The current
[producer handoff](experimental/native-failure-producer-handoff.md) retains
the structure-consumer, compiler-representation, handler-generation and pending-
owner distinctions. These are research tracks, not a claim that they are the
three remaining native gate identities. Historical reports with older aggregate
counts do not reset the owner's current progress or certify a newer candidate.

Sources are pinned submodules: Gambit
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, Chez
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd`, OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`. Current overlay observations remain
distinct from those baselines and from an accepted executable.

## Pending Ownership: What Can Be Reused Now

| Existing model/proof | Relevant current contract | Still required from the actual candidate |
| --- | --- | --- |
| [root cleanup retention](../models/gambit/root_cleanup_sticky_retention.qnt) | Saved join failure retains storage/error and refuses destructive setup; P0 routing differs from merely requesting a pin. | A source-reachable recovery operation, actual exclusive host owner and same worker incarnation. Retained failure is not natural-error-then-success recovery. |
| [foreign origin retirement](../models/gambit/foreign_origin_owner_retirement.qnt) | Admission/frame publication, source-owned TLS, thread exit, successful join and reclamation are separate events. | New-owner attachment cannot be inferred from a P0 pointer or a zero frame count. The modeled valid callback runs on its owning OS thread. |
| [nested foreign unwind](../models/gambit/nested_foreign_unwind.qnt) | Inner and outer C frames clean up on their origins, exactly once, preserving the original outcome. | `routeOuter` is a source-refinement obligation, not an implemented transfer queue or permission to resume an expired C stack on another host thread. |
| [work accounting](../models/gambit/lean/WorkAccounting.lean) | `zeroCountAndEmptyQueuesExcludeHiddenWork` requires `ProducerLifetimeSafe`; `missingLifetimeCounterexample` already rejects a hidden producer. | Enumerate the actual private producers and their root/work handoff. The theorem cannot discover an omitted producer or make a partial snapshot complete. |

Reuse these existing counterexamples and contracts. No new generic QNT/Lean
model is needed merely to restate them. Their algorithmic sources are unchanged
so another thread's source-bound native acceptance is not invalidated.

## Collector Census Must Be Phase-Correct

Chez [thread.c](../vendor/chez/c/thread.c):261-341 processes remembered data,
closes thread-local allocation and transfers guardians before releasing `tc`;
it retains/recycles `thread_gc` because heap segments can still name that owner.
[alloc.c](../vendor/chez/c/alloc.c):305-323 requires its allocation mutex or
collector-guaranteed exclusivity when closing segments, then clears the segment
cursors. The useful unit is **owned data plus its collector interpretation and
last producer**, not simply the disappeared thread or an empty public queue.

OCaml [domain.c](../vendor/ocaml/runtime/domain.c):2262-2360 keeps a terminating
domain participating while emptying the minor heap and finishing/orphaning work.
Orphaning can create more marking/sweeping work, so completion is rechecked. Its
participant removal is serialized against incoming STW requests. Neither that
collector protocol nor Chez's segment closer is a drop-in Gambit operation.

Gambit [mem.c](../vendor/gambit/lib/mem.c):3251-3307 `end_heap_chunk` writes a
chunk marker/link, publishes FIFO data with two ordered barriers and may wake
scanners. It is a mutation of a particular collector phase, not a read-only
quiescence check. At 6991-7044, GC recovers `fp`/`hp`, sets up collector state
and performs phased marking; `prepare_mem_pstate`:4525-4564 publishes resulting
stack/heap pointers back to processor state. Therefore a cursor's initialization
or an address comparison alone does not establish that it describes all roots
and private work at the retirement boundary.

The inspected retained mutex-return overlay's `___transfer_mem_pstate` splices
still-object and
RC ownership under the memory lock. Its implementation does not by itself
enumerate all live Scheme activation roots, pending private scan work or queue
borrowers. The owner's cumulative patch was inspected at SHA-256
`49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55`;
that observation is not imported here as a reproducible source input or a newly
qualified producer. The already published producer handoff records the candidate
identity boundary. Do not infer that an unenumerated producer exists on every
legal path; the complete census and source phase remain obligations to discharge.

### Root And Private-Work Inventory

The pinned collector supplies a concrete starting inventory, not a proof that
all of these states remain live on a removed processor. Each current candidate
must establish **absent at the legal retirement boundary**, **retained under a
live owner**, or **transferred and observed by the recipient** for each applicable
row. A nonzero field alone does not prove live work; a zero public counter alone
does not prove its absence. Strong-root coverage and work accounting are separate.

| Inventory class | Actual pinned consumer | Current source correspondence still required |
| --- | --- | --- |
| Active and captured Scheme continuations | `mem.c`:3900-3966 walks `fp`, return-address maps, stack breaks and captured frames. | The retirement boundary must preserve or discharge the actual continuation and its interpretation metadata, not just retain the msection bytes. |
| GVM register, saved, cache and processor roots | `mem.c`:6508-6576 marks `r`, `saved`, `type_cache` and the processor Scheme object. | Show the candidate's generated-state publication and surviving root owner; copying allocation cursors does not enumerate these slots. |
| VM, globals, symbols and registered C data | `mem.c`:3969-3989,6579-6663,6845-6852 separates RC data from VM/global/symbol roots and their processor assignment. | In this baseline `mark_rc` traverses the current processor's RC list and the strong phase calls it on P0. A donor-list splice needs an explicit P0-consumer bridge; arbitrary-recipient reachability is not inferred. |
| Still-object roots and private scan chain | `mem.c`:4210-4276 builds the refcount-root scan chain, then consumes it. | Preserving `still_objs` ownership is not by itself proof that an in-flight `still_objs_to_scan` chain has finished or been handed over. |
| Public chunks, claimed chunks and incomplete local copying | `mem.c`:4279-4382,6672-6767 distinguishes queued chunks, a stolen chunk being scanned and the local `scan_ptr`/allocation frontier. | Stable queue endpoints need the real cohort/phase and producer/borrower discharge. A stolen chunk is no longer necessarily represented by its donor's queue. |
| Weak-phase and cleanup obligations | `mem.c`:5032-5113,6824-6935 processes wills, weak traversal and reached GC hash tables after strong marking. | Classify executable/nonexecutable wills and reached tables at the actual boundary; do not mark weak work complete merely because strong queues are empty. |

Reuse `WorkAccounting.lean` for counted private producers and reopened work,
`ffi_gc_frame_protocol.qnt` for published/reloaded and nested roots,
`shared_msection_copy_retirement.qnt` for range/borrower lifetime, and
`scan_barrier_quiescence.qnt` for callback-to-cohort closure. These projections
have different premises. `ProducerLifetimeSafe` is not a root-enumeration or
foreign-frame theorem; model composition cannot fill an omitted source row.

Chez `thread.c`:274-305 gives a useful countercheck against a list-only handoff:
remembered data is processed before local allocation is closed, and guardian
entries are transferred separately. Its `thread_gc` carrier outlives `tc`
because segments may still refer to it (:324-335). OCaml `domain.c`:2276-2338
likewise distinguishes finishing work, orphaning ephemerons/finalisers, checking
for newly created work, orphaning the heap and leaving the participant set.
The transferable requirement is **enumerate and close each actual consumer**;
neither reference proves that Gambit needs their heap layout or permanent carrier.

### Host And External-Frame Ownership

Gambit's own pinned sources already distinguish heap reachability from a live
foreign return destination. `setup.c`:3294-3345 describes the return marker in
the Scheme frame and the live C activation it represents. `c_intf.c`:6511-6570
constructs that marker, records the processor in threaded mode, invalidates its
procedure slot on return and releases its still-object reference. Marker
retention therefore does not make an expired C stack or copied TLS pointer valid.

The same constructor contains an explicit TODO about `proc_or_false` surviving
the allocating `___make_vector`. This is a pinned-baseline source warning, not a
demonstrated failure in the current overlay. Its candidate correspondence must
identify the actual traced owner across allocation, including nested entry;
neither the TODO nor a finite root model establishes current native causality.

`setup.c`:3350-3391 has distinct direct-host-tail-call and trampoline routes,
with catcher setup and marker-matched unwind. `___run`:3397-3422 places marker
cleanup after `___call` inside its try region. Generated SFUN macros at
`gambit.h.in`:10043-10061 have their own cleanup/error propagation ordering.
Thus inspect each actual normal, caught-error and nonlocal path rather than
assert that an ordinary tail is universal cleanup, or that the baseline path
still exists unchanged in the candidate. The existing nested-unwind model's
origin-routing event remains conditional until bound to that candidate path.

Chez's C-chain/paired activation and OCaml's rooted result carrier provide
different examples of **who releases what after which control transfer**.
They do not grant a new Gambit host thread ownership of another thread's catcher,
live C stack or processor merely because heap roots survive. General attachment
or migration semantics belong in Experimental; checking the current supported
entry and its exact acquired-effect cleanup belongs in the current repair.

### Per-Consumer Release, Not Blanket Retention

The references also reject retaining every input until OS join. OCaml
`callback.c`:30-44 explicitly limits callback argument/closure root lifetimes.
Its bytecode path (:98-141) copies arguments to the traced stack before an
allocating stack-parent operation and no longer reads the old argument array
afterwards. The native path (:180-211) roots closure/argument across that
allocation, ends those roots before the assembly callback, and retains the
stack-parent continuation separately. These are different source mechanisms;
the inspected C wrapper does not by itself prove the native assembly convention.

Chez `schlib.c`:223-244 immobilizes code needed by C return addresses, including
the more immediate caller when `lock_ts` applies. Its cleanup and final restore
(:257-289) concern those code objects, not indefinite retention of the original
closure, which may already have moved or been reclaimed. Conversely, OCaml
`domain.c`:1346-1455 retains `term_sync` through domain teardown and the final
mutex unlock, then removes the global root. A short-lived callback argument and
a still-locked termination carrier cannot share one generic release deadline.

For current Gambit repair, the low-cost objective is to prove each existing
consumer's last use and successor owner, not to add a permanent root for every
pstate field or extend every C-local lifetime until join. A smaller safe root
scope is a design opportunity, not measured speedup. Nested callers, generated
map liveness, relocating GC and original exception/continuation behavior remain
mandatory premises before shortening a scope.

| Existing contract | Exact current correspondence to establish | What remains unproved |
| --- | --- | --- |
| `ffi_gc_frame_protocol.qnt`: publication, nested roots, reload | A successor traced slot owns a still-needed input before allocating or waiting; resume reads the relocated value. | Copying into an arbitrary C local is not root transfer; the reference callback convention is not Gambit's generated ABI. |
| `callback_retirement_composition.qnt`: `convertResult`, `killMarker`, `enterCollective` | Interpret `killMarker` as completed origin-owned exit effects, not merely the literal marker invalidation call. | That action clears both `marker` and `cFrame`. Actual SFUN macros invalidate the marker before `___propagate_error`; `setup.c`:853-866 may then use the current catcher. Marker-dead alone cannot instantiate full C-tail discharge. |
| `nested_foreign_unwind.qnt`: `cleanInner`, `routeOuter`, `cleanOuter`, `propagate` | Match each acquired origin frame and its catcher restoration, preserving the original outcome across supported routing. | Heap reachability, a processor ID and an abstract routing event do not establish a live foreign return target. |
| `vm_retirement_join_composition.qnt` plus `sync_slot_retained_resources.qnt` | OS exit/join of a receiver and completion of all remote sender tails are different events. | `initJoinOnlyCleanup` already exposes the distinction. `recoverJoin` assumes a bounded recoverable join; it does not establish a legal POSIX error-to-success route for the candidate. |
| `RuntimeEntryContracts.lean`: `descriptorRetirementExcludesConsumers`; `WorkAccounting.lean`: `rootsDoNotPermitConcurrentMutation`, `reuseRevokesOldIdentity` | Supply the actual live consumers, root publication/mutation boundary and same-incarnation identity. | The conditional proofs neither enumerate omitted consumers nor make an earlier census stable across a new GC, admission or slot reuse. |

This source-refinement gap belongs to the current repair's use of existing
models. It is not evidence that those abstract actions are automatically unsafe,
nor proof of a current crash cause. If the source cannot implement a suitable
exit linearization, its current composition must be refined before it supports
the repair; a local model pass cannot substitute for that missing bridge.
Generalized foreign-host attachment or a new independent carrier remains an
Experimental architectural change instead.

### Bounded Repair Recipe

The first-stage scope is the existing `setup.c` retirement/recovery caller and
`mem.c` ownership handoff, with generated state/root and foreign-frame boundaries
as dependencies. It preserves the C backend, FFI, proper tail calls, supported
continuations, ordinary allocation and resolved-access fast paths.
Qualification uses one repaired revision/effective configuration with all
affected generated/header-dependent objects rebuilt, not a new setup object
linked into an old archive. Applicable unchanged checkpoint stages remain reusable.

| Source join | Required evidence | Rejected shortcut |
| --- | --- | --- |
| Collective closure -> retirement | Match actual cohort/phase, completed callback return and the existing upward aggregation bridge. | Zero scan-worker count or a broadcast alone; adding a universal extra barrier without a demonstrated missing edge. |
| Retained donor -> collector-visible owner | Show which valid roots, still/RC state, private work and interpretation metadata remain owned or are transferred; publish under the collector's real phase/lock contract. | Calling `end_heap_chunk` from arbitrary cleanup, copying Chez's closer or setting a `fullProducerCensus` boolean. |
| Join-zero -> handoff -> clear | Bind the successful OS join to the same incarnation, retain joined-but-unhanded state if transfer is busy, and clear only after actual transfer completes. | Rejoining an already joined thread, or treating join success as complete root/borrower discharge. |
| Join error -> possible recovery | Establish a still-supported target and a legal exclusive source owner/entry; preserve original failure and resources until that operation succeeds. | Detached/self-join controls, injected errno, private pending-field writes or equating a normal join-zero fixture with real error recovery. |
| Exceptional C return -> owner release | Account for each actually acquired frame, root and entry effect on its origin, with the original outcome preserved. | Assuming cleanup after an ordinary C return also runs on every nonlocal exit, or transferring a raw TLS/frame pointer to a new host thread. |

This is a small-refactor candidate scope, **not** a selected runtime patch or a
promise that it closes the natural-error recovery gate. The implementation owner
must instantiate these conditions in its current repair package. If the needed
public owner-transfer operation is absent, that absence remains explicit; a
model must not manufacture the missing event or assert universal impossibility.

For the implementation handoff, keep successful join and completed transfer as
separate durable facts about the same incarnation. If the transfer cannot finish,
the already joined donor remains owned and non-reusable without another OS join.
On retry, a previously valid census must still be applicable: no recipient
collection, callback admission or phase transition may silently invalidate its
root addresses or interpretation. This is a required source argument, not a
proposal for a new checkpoint interface or a claim that every retry races.

The source repair is ready for full native qualification only when the actual
candidate binds the above inventory, the legal exclusive host/entry, successful
OS completion, recipient-visible handoff and destructive cleanup in that order.
Current research has not established this conjunction. BUSY or retained failure
can be correct intermediate outcomes; neither is successful recovery. No new
global lock, full-heap scan, TLS change or unconditional collector barrier is
selected by this audit.

### Destructive Cleanup Is Not Just Bookkeeping

The pinned `mem.c`:4932-4935 cleanup calls `free_still_objs` and `cleanup_rc`.
`free_still_objs`:4432-4453 detaches its local still list, invokes
`___release_foreign` for foreign objects and frees their storage. The separate
GC cleanup at :4387-4419 releases unmarked foreign objects as well. Therefore
"joined, then cleanup" can include external C effects, not just pointer clearing.

`c_intf.c`:1683-1713 clears the foreign object's release-function/pointer fields
before invoking its C release function; a nonzero returned error does not restore
them. The two inspected `mem.c` cleanup loops do not consume that error result.
The manual `gambit.txi`:18999-19045 permits custom C cleanup, including reference
count/table changes and default C++ destructors, and specifies at-most-once
release. This is not proof that arbitrary Scheme callback/re-entry or concurrent
release of one object is supported. No such call is introduced by this research.

The current small-repair handoff must distinguish an emptied donor whose
resources have actual surviving owners from a donor that still needs release.
For a release-bearing tail, enumerate its supported C effects, required context,
locks and error disposition before declaring the donor reusable. In particular,
do not hold a new handoff lock across external code without a demonstrated legal
effect/lock contract, or call an already invalidated release function again as
"rollback". Conversely, do not require a callback or new general finalizer
protocol on a legal path where the owner has proved the donor list empty.

Keep OS-join success, recipient ownership and external-release side effects as
separate facts. They are not an all-or-nothing transaction: a later cleanup
failure does not undo a successful OS join or recreate the already cleared
release-function fields. The existing exact-once/error and retained-resource
models constrain those boundaries, but their successful abstract cleanup cannot
stand in for an unenumerated C tail or a new native failure rollback witness.

Chez transfers guardian entries before releasing `tc`; this is distinct from
proving all arbitrary finalizer code safe in a teardown lock. OCaml's ordinary
termination orphans finaliser work, whereas its last-domain path
`domain.c`:2378-2394 explicitly adopts heaps and runs custom finalisers before
orphaning/freeing the shared heap. These different paths are counterevidence to
one universal cleanup deadline. The current model correspondence remains open
for any actual external tail; a future generalized finalization/attachment
mechanism belongs in Experimental, not an assumed event in today's join model.

The cheapest applicable boundary remains processor retirement inside a surviving
VM: a live recipient can own transferred roots/resources if VM admission and
cleanup cannot invalidate it first. The pthread synchronization storage declared
in `gambit.h.in`:10893-10914,11518-11527,11947-11979 belongs to C state, not to an
OCaml-style GC wrapper. A Scheme root around a C pointer cannot prevent explicit
VM-state destruction. Draining all actual consumers before that destruction is
the current requirement; allowing those consumers to outlive the VM would need
the separate Experimental carrier/lifetime architecture. Do not impose that
larger redesign on a source path that can satisfy the surviving-VM boundary.

## Exception And OS Join Are Different Contracts

OCaml `domain.c`:1392-1455 routes backup-thread installation failure, domain
initialization failure and callback outcomes through its termination machinery
after successful domain creation. Rooted result publication is not a raw C
unwind that skips teardown. At 1512-1547, thread-creation failure frees the
parent's root carrier; successful creation transfers that carrier to the child,
the parent services STW requests while awaiting startup, and a started child
is **detached**. Startup failure takes the OS-join path. In
[domain.ml](../vendor/ocaml/stdlib/domain.ml):291-303, language `Domain.join`
waits for the termination result under its mutex and returns or rethrows it.
It is not successful retry of Gambit's pending `pthread_join`. Detaching an
already pending Gambit worker would destroy, not discharge, that obligation.

Chez [thread.c](../vendor/chez/c/thread.c):209-244 records whether an activation
created, reactivated or merely reused a context and reverses only that effect
on ordinary paired exit; the W/X branch differs. The libffi callback at
[ffi.c](../vendor/chez/c/ffi.c):604-623,692-700,793-797 uses this pairing.
It does not license moving another thread's live context or imply that its
ordinary callback tail is the whole nonlocal-unwind protocol.

Chez [schlib.c](../vendor/chez/c/schlib.c):217-289 explicitly maintains a C-chain,
jump buffers and code retention for nested returns/errors. Its
[foreign-call contract](../vendor/chez/csug/foreign.stex):1375-1410 explains
that stale foreign return contexts are trapped; arbitrary continuation
invocation is not permission to return through a stale C frame. Thus a proposed
new recovery owner needs a live entry and supported return protocol, not just
retained heap bytes or a copied old context. Preserve Gambit's own continuation
and FFI behavior instead of importing Chez's ABI or assuming OCaml exceptions
have identical control semantics.

## Architectural Work Kept Separate

Generalized host attachment/owner capabilities, independent root/synchronization
carriers across VM destruction, or decoupling language completion from OS-thread
ownership require explicit lifecycle/GC/FFI redesign and coordinated migration.
Those are Experimental milestones, not small bookkeeping fixes or permission to
replace Gambit's shared heap, C backend or supported continuations. The existing
[architectural composition](experimental/retirement-handoff-model.md) checks
some conditional subcontracts but is not a complete redesign or current repair.

The current lane instead binds the actual failure and proposed bounded repair
to existing models, source/configuration and native obligations. Formal passes,
mirrors and source observations never add a native gate. This audit supplies
source requirements and falsifiers; the separate implementation thread owns
source changes and complete native/Gerbil acceptance.

## Executable Current Composition And Evidence Feedback

The [current exit/handoff QNT](../models/gambit/retirement_exit_handoff.qnt)
imports the existing callback-result, saved-stack and remote sender/resource
machines plus shared work definitions. It adds the previously missing
composition, rather than changing historical models or creating a second GC.
Marker invalidation and origin-tail exit, donor work and recipient-owned work,
OS join and handoff, release invocation and release-tail completion are distinct
events. A failed join retains the donor without manufacturing a successful retry.
The recipient VM survives; generalized post-VM carriers remain Experimental.

The [Lean companion](../models/gambit/lean/RetirementExitHandoff.lean) reuses
`WorkAccounting`. Counterexamples, progress assumptions, non-vacuous success and
failure witnesses, checked identities and retained failed attempts are recorded
in the [validation](../evidence/research/retirement-exit-handoff/validation.md).
These checks support a current small repair but do not establish C linearization,
complete native roots/producers, weak memory or native/performance qualification.
The final local campaign passed three tests in 75.497 s: positive safety/progress,
seven decoded omission controls, two reachable success/retention paths and
fourteen conditional Lean statements. These are research results, not new gates.

The old ASCENT component exposed declared gap text but did not derive a new
coverage obligation when source observations introduced an event combination.
Its existing Scheme DSL now accepts scoped `composition_edge` facts and derives
requirements, checked-model evidence and source-composition gaps. A model check
matches its exact model and receipt hashes; all declared interfaces are required.
An optional source binding must also match both observed source hashes, the
scope/events/property and its refinement reference hash. Old local passes cannot
silently cover a new event, model, source version or scope. Empty declarations
are legal and do not establish completeness. Actual C bindings remain absent.

The [Clue view](../evidence/scenarios/parallel-gc/retirement-exit-handoff.view.json)
uses the existing constructor, registration and selection/Session interfaces.
Its observation digest binds the domain declaration profile, not only an
unchanged C file while the model/gap changes. Edge handles are configurable;
conflicting handles expose a gap instead of merging scopes. Clues return facts,
provenance and references, not a required investigation step. New source
semantics still require the Agent to declare relevant edges; this is not keyword
matching or automatic understanding of C. No Python inference or new CLI is added.

Publication adds only this research view to the PR registry. The active native
workspace's registry, historical model receipts, source locks and checkpoints
remain untouched. A metadata-only, automatically cleaned registration fixture
checks the real cross-process query/resume path without a runtime copy or build.

## Research Validation

Earlier published HEAD `972cbef62981100bddf7b34fa600313c5a0401b3` passed
[framework CI 39357149834](https://github.com/tao3k/gambit-SMP/actions/runs/39357149834):
1,809 tests, zero failures/errors/skips, complete inventory and unchanged inputs,
399.338984056 s, `frameworkValidated=true`, `runtimeAdmitted=false`.
Artifact `12236430086` has `test-result.json` SHA-256
`6a9c570836f3971254dce4a278fa3dbf501f01cdd5e22364161ec7780d78a642`.
This exact-head pass precedes the inventory/foreign-frame supplement; it does not
certify unpublished changes or the implementation owner's current candidate.

The inventory supplement was then published as
`e2515de2c3a9b3186902f1e6c040c76112a2ce4c` to SMP PR #1.
[Its framework CI 39358418639](https://github.com/tao3k/gambit-SMP/actions/runs/39358418639)
passed 1,809 tests with zero failures/errors/skips in 350.668556295 s, complete
inventory, unchanged inputs, `frameworkValidated=true`, `runtimeAdmitted=false`.
Artifact `12236816509` has `test-result.json` SHA-256
`7a8bb3d66dce541510112531bc25670906aa43d939e873de66be27dd765eebf5`.
Only that SHA's duplicate native workflow was cancelled; another task's native
acceptance and the shared index were not changed. This pass covers the published
inventory supplement, not the subsequent local per-consumer/cleanup research.

The existing Scheme consumer checks this supplement's source/model hashes,
expands its source-section/premise correspondences, withdraws/restores the new
sources and preserves explicit missing native requirements. Current and
architectural evidence remain partial and `satisfies=[]`; neither can qualify
the other. The inventory/foreign-frame supplement passed the two existing
current-correspondence/link checks in 3.077 s. That includes its added marker
source withdrawal, with missing native requirements preserved. Final
document/hash updates are checked again without repeating unchanged formal or
native work; earlier architecture consumer results are not relabeled as new runs.

The subsequent per-consumer/cleanup correspondence reuses the existing join and
slot-resource models without changing their algorithms or theorems. Its two
existing Scheme/link checks passed in 3.512 s, preserving partial model scopes,
all missing native requirements and source-withdrawal failures. This local
continuation is distinct from the published inventory supplement and its CI.

The earlier inventory supplements did not change QNT/Lean algorithms. The current
executable composition and companion above now close that research-model gap;
their source-refinement obligations remain open. Existing model algorithms and
historical receipts are preserved. The implementing workers retain ownership of
their runtime repair packages. No native run, Grok launch, bootstrap, debugger,
runtime change, checkpoint reset or budget change is introduced here; this work
does not increment or downgrade the owner's 9/12 count.
