# Current SMP Repair Research

## Objective And Separation

This research serves closure of **items 9 through 12**, including item 9 itself.
It does not mean nine native gates have passed: the inspected native audit
records eight completed contracts and four open contracts. It does not replace
the implementation owner's source or authorize an execution. Current failure
analysis and bounded source repair belong with the
existing executable models even when the cause or implementation is still open.
Only a changed architectural mechanism belongs in
[Experimental](../models/experimental/README.md). In particular, adding another
finite waiter phase is not itself a refactor milestone.

The [gate-to-evidence checklist](current-repair-obligation-map.md) separates the
owner's native gate identities from the source research clauses below and records
the missing registration, applicability and acceptance connections.

No runtime, compiler, source lock, qualification manifest, checkpoint or native
test is changed here. The current
[producer handoff](experimental/native-failure-producer-handoff.md) retains
the structure-consumer, compiler-representation, handler-generation and pending-
owner distinctions. These are research tracks, not a claim that they are the
remaining native gate identities. Earlier references below to a "9/12 objective"
mean work on items 9 through 12, not an additional completion receipt.
Historical reports do not erase partial successes or certify a newer candidate.

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


## Independent Current Work Audit (2026-10-20)

At the owner's explicit stop request, the three Grok repair workers were stopped
and their records preserved. They are not resumed by this audit. This section
records verification of the current 9/12 research and its remaining obligations;
it neither resets the owner's progress nor adds a native gate. No runtime source,
checkpoint, native inventory or Gerbil build was changed or launched here.

| Audited layer | Executed result | What the result supports |
| --- | --- | --- |
| Four current gate-boundary QNT models | 16/16 checks accepted; original 30 s watchdogs; context stable. | Lifecycle entry separation, numerical completion/inventory, fault observation and performance-sample admission policies. These are characterization models, not implementations. |
| Current exit/handoff QNT composition | Safety/progress explored 621 distinct states; seven decoded omission counterexamples and two reachable success/failure witnesses accepted. Exact QNT inputs remained unchanged. | The declared finite root/work population and surviving recipient VM, under the model's returning-C and fairness assumptions. |
| Current Lean companion | Guarded check passed on the updated source, including source/refinement identity and interface-bundle lemmas. | Conditional contracts and counterexamples. This is not an inductive refinement of the whole QNT machine or native C execution. |
| ASCENT composition evidence | Two tests passed, including stale/changed identities, source withdrawal, interface coverage and cross-process checkpoint resume. | Applicable scoped evidence is distinguished from missing source-composition evidence; no `satisfies` or native admission is inferred. |

An actual test-harness error was corrected: the cross-process `capture` call now
passes its environment. The first audit also hit the sandbox's loopback restriction.
A subsequent combined run detected concurrent Lean/ASCENT edits and correctly
failed freshness/arity checks; that mixed run is retained and is not a whole-suite
pass. Unchanged QNT receipts were reused only after checking their input hashes;
the changed Lean and ASCENT domains were checked separately on stable inputs.
The [audit receipts](../evidence/review/current-work-model-audit-20261020/audit.json)
retain the commands, input identities, successes and rejected attempts.

The next source-level obligation is an enumerated and phase-correct last-consumer
contract: origin C/exception tails, actual roots and descriptors, private and
claimed collector work, remote senders, and release-callback tails must be absent,
retained or transferred to a live owner. A queue snapshot, join result, pointer
identity or assigned boolean cannot establish that contract. The current QNT
`childQuiet`, `finishWithinCap` and handoff events remain abstract requirements;
they do not observe their corresponding runtime completion.

Source custody was checked against the newer
`handler-quiet-while-pending.lock.json`: all 26 declared source files match.
`setup.c` and `gambit.h.in` intentionally differ from the predecessor mutex-return
lock, so old source/binary receipts cannot be relabeled as this successor.
The new `handler_quiet` flag is published by a release store immediately before
`___thread_exit` and read with acquire after a successful join, before transfer.
That is a concrete source publication, not caller attestation. It covers that
handler exit path; it is not a census of every root, producer or borrower.
The added processor field changes public layout, so dependent generated/native
objects must be rebuilt and requalified together before any runtime claim.
This audit does not establish that binary dependency closure.

A general trace/conservation proof must be distinguished from the current Lean
conditional lemmas. Actual owner/incarnation authorization, C memory ordering,
producer publication and source-to-model correspondence remain explicit premises.
Real header/type/producer evidence, source-reachable pending-join completion,
actual numerical compilation and complete native/Gerbil acceptance remain separate
implementation evidence. The stopped Grok drafts, mirrors and formal passes do
not discharge those obligations.


## Stability Beyond The Current Milestone

The current 9/12 objective remains source-bound qualification. Completing its
remaining gates does not discharge repeated-operation, cancellation, identity,
resource-growth or fault-sensitivity obligations. The
[repair and stability test contract](retirement-repair-test-contract.md) maps
those obligations to supported stimuli, legal synchronization points, independent
observations and omission controls. It reuses the existing watchdog, failure-scope
and capacity models instead of introducing another clock or acceptance counter.

The [repeated campaign model](../models/gambit/retirement_repair_campaign.qnt)
executes the existing exit/handoff machine across two distinct cohort
incarnations. Credit comes from completed protocol observations and matching
source/build/receipt identity. It rejects stale builds, replayed receipts,
partial coverage, failed-join success claims and erasure of retained failure.
Cancellation and source change are reachable retained/refused outcomes.

Audit found a further composition defect in an earlier passing campaign model:
resetting the next donor also forgot work and roots already handed to the
surviving recipient. That was an abstraction defect, not an observed C regression.
The repaired model carries independent received, live-owned and completed
recipient obligations across cohort starts; a separate last-consumer event can
finish the prior work. An explicit loss-on-restart counterexample prevents a
model reset from hiding this obligation. A valid repeated-success witness leaves
recipient-owned work live, while another witness completes it. There is no
blanket requirement to drain the whole recipient VM before retiring a donor.

The [campaign Lean proof](../models/gambit/lean/RetirementRepairCampaign.lean)
adds arbitrary finite test-event trace properties: join-once receipts, retention
of failed states, refusal to restart unfinished work, source/configuration/VM/
incarnation identity, and a separate resource-ledger conservation and exclusivity
proof. These extend the earlier conditional handoff lemmas; they do not establish
native event authenticity, all root enumeration, memory ordering or a C refinement.
Executed checks and the inadequate earlier model/compile attempts are retained in
[the campaign validation](../evidence/research/retirement-repair-campaign/validation.md).
The original retirement step relation is unchanged; its new configuration
projection and separate restart action support composition, with the existing
single-cohort checks requalified on the changed source.

Experimental supplies useful falsifiers for independent synchronization lifetime,
OS-return versus full waiter exit, per-consumer release and GC participation.
These become current test obligations where the source supports them. Independent
post-VM carriers and generalized attachment remain architectural work; an
Experimental pass cannot satisfy a current native gate. Its unchanged QNT/Lean
source identities were checked against the existing retained validation, without
relabelling that historical execution as a new run.

The next native fixtures must establish actual joined-but-unhanded resumption,
last-reader/sender/callback completion, correct generated/header/archive closure,
and independent semantic/resource oracles before the repeated campaign can be
used as runtime evidence. No runtime source, native test, bootstrap, Grok session
or release benchmark was started for this model/test-contract extension.


## Task Storage And Lifecycle Audit (2026-10-20)

The current repair campaign needs one stable source/task identity across Codex
and Grok. The storage audit and executable migration boundary are documented in
[Task workspace lifecycle](task-workspace-lifecycle.md). New managed worktrees
belong in `.data/worktrees/<task>` and outputs in `.cache/tasks/<task>`; pending
request state is durable, outside cache expiry. October 19–20 are the retained
calendar window for disposable historical outputs. Active checkpoints, dirty
source checkouts, budget ledgers and process ownership require separate custody.
This organizational repair does not advance the native 9/12 milestone or restart
Grok. Complete legacy-writer migration and long-lived-task run retention remain
explicit gates rather than being inferred from a successful cleanup pass.

### Storage Audit Outcome

The applied purge removed 1,759 legacy cache/data entries and verified all
selected paths absent. Four stopped owner directories were consolidated into
`repair-9-12`; source checkouts, state stores and active checkpoint locations
were retained. The request-store migration preserves all 612 rows, fences old
cache writers, and rejects retired-cache fallback if durable state is lost.
The final targeted run passed 89/90 and correctly rejected a concurrent Zig
view edit; individual recheck passed, alongside 15 action integration tests.
The independent Zig observation-contract failure remains a separate open issue.
All five checkpoint paths remain present, but three were updated during shared
source/build work, so byte stability and native dependency closure are not
admitted by this audit. Remaining legacy writers, open-campaign run retention,
and interpreter/dependency binding are explicit migration gates. See the
[storage audit receipt](../evidence/review/storage-lifecycle-20261020/audit.json).

### Existing Paths And Launchers: Intermediate Migration (Superseded)

The existing campaign's physical dependencies are registered in place. A
checkout-level default task policy brings CLI calls without `--task` into the
common execution scope. Script migration rewrites real source into
`campaigns/repair-9-12/scripts/`, uses normal task output allocation and validates
execution custody/source seals. Old executable entries are removed; no old-mode
forwarders, runtime source translators or legacy path resolvers remain in the
execution design. Original bytes survive only as audit archives. Retired Grok
and archived owner scripts remain disabled, and none is executed by migration.
Migration waits for the live task lease rather than interrupting 9/12.

The shared Python protocol records durable attempts, checks inherited held-lock
custody, rejects another checkout's framework, bounds generic supervision, and
requires explicit reconciliation after interruption. Completion inspects pending
SQLite requests, dependency identities, process groups, open paths and quarantine.
It does not reset state, replay actions, restore memory or claim native pending-
join recovery. Both providers use the same protocol. Prepared script migration
can resume only after original/archive/new-source hashes and identities match;
prepared or changed source cannot execute.

New outputs use per-attempt directories inside the campaign cache. Completed
runs can expire after two Shanghai calendar days while the task stays open.
Dependency pins block task cleanup and legacy manifest application, including
pre-adoption manifests. Explicit pin release requires quiescence and no pending
requests and preserves history. Python write guards do not replace native source
locks or contain arbitrary native processes.

The initial extended validation passed 163/164 and correctly rejected concurrent
`models/gambit/host_root_participation.qnt` mutation. A subsequent run overlapped
source/document changes and retained two stale-input failures. These receipts
are not rewritten into passing results. Final direct-migration verification is
recorded in [the follow-up lifecycle receipt](../evidence/review/storage-lifecycle-20261020/followup.json).
This work does not close native 9/12 or admit complete model/native/Gerbil
build/test qualification; the owning repair continues independently.

Direct retirement completed for 50 scripts: all old executable paths are
absent and the compatibility module has been removed. Nineteen Codex audit
scripts are enabled; 31 Grok/archived/profile scripts remain disabled. Five checkpoint hashes/inodes matched across the migration;
six lease deferrals were honored. Source migration did not execute the migrated
scripts. The remaining 587 physical dependency pins retain recovery custody; 25 retired
script pins are recorded separately as migrated source history. A second-level
inventory preserves three sealed-engine workers and five immutable profiling
fixture modules as source-bound inputs rather than altering them as launchers.

Final related framework/action validation passed all 169 tests in one stable
window. After removal of the temporary migration-input decoder, the final
entry/lifecycle suite passed 45 tests. All 50 current script hashes match their
seals and all old executable paths are absent. The durable request journal still
matches the retired 612-row source exactly (zero pending requests; integrity
`ok`). These are framework/storage results, not native pending-join restoration
or native/Gerbil build/test acceptance.


### Corrective Python Lifecycle And Retention Audit

The intermediate script move was insufficient: it introduced an invalid root
`campaigns/`, pinned every adopted output indefinitely, and left direct module
and imported `main()` entry policies inconsistent. The corrective implementation
removes that directory. All 50 exact program hashes now live under
`.cache/tasks/repair-9-12/programs`; original and relocated bytes remain custody
archives. Existing stopped Grok programs stay disabled. Layout normalization did
not change the five observed checkpoint file hashes/inodes.

The sole public command dispatcher now covers console, adapter-module and
imported-main execution. Codex and Grok share attempt, lease, process observation,
reconciliation, completion and cleanup functions. New child contexts validate a
real held descriptor and current run. Provider tools closing their FDs receive
that same lease through an authenticated local Unix descriptor transfer. Tests
use actual local provider doubles and subprocesses, not a model's approval.
Grok resume is bound to task/owner/authorization; a timeout cannot immediately
retry without real reconciliation. No external Grok/Codex service was launched.

Python write policy rejects the forbidden root before OS mutation and rejects
aliases, parent traversal and unregistered task outputs. It is enforced by the
allocator/common execution scope and at framework import for the reserved root;
there is no catch-and-rerun or memory restoration. Native programs still require
their existing bounded supervisors and source locks.

The former 587 blanket pins became 18 explicit source/shared/recovery pins and
569 two-day output candidates. One actual sweep examined every candidate, keeping
recent data and refusing unknown SQL/Git state. Further schema/producer/log/child
checks identified historical validation scheduler queues: 16 expired validation
roots were removed after preserving consistent SQLite snapshots and exact root
custody records. Unclaimed test jobs remain unclaimed in those archives; they
were not declared completed or replayed. Unknown stores and nested Git remain
explicit deferred decisions, not permission to delete pending operational state.
There are now 571 registered physical paths; 16 expired histories remain indexed.

Real interruption controls kill a supervisor while its child holds the actual
lock, and separately close the child FD while its kernel process group remains
alive. Both block recovery until the child actually exits. Reconciliation keeps
the interrupted outcome, repeated resume does not reset its expiry, and subsequent
execution/finish is exercised. Another child process dies after a partial actual
deletion; restart rejects a newly added backdated file and then removes only the
unchanged remainder. Failed test queues are archived with their NULL-lane jobs,
and a real SQLite writer transaction blocks deletion. Fixture isolation removes
production task context while keeping the actual parent lease held.

Per-path cutoff/retention decisions, deletion inventories and exact archive hashes
are durable under `.state/storage/` and `.state/task-dependencies/`. Historical
JSON can be read by original path plus SHA without recreating cached bytes.
The correction also removes redundant path resolution from unscoped removals;
no native timeout was increased. The initial real sweep finished normally, and
no cleanup or native process was signalled during that correction.

Final verification is recorded in the v3 lifecycle receipt. This audit neither
closes native 9/12 nor substitutes framework tests for actual pending-join
recovery or native/Gerbil build/test acceptance. The active repair was not reset,
restarted or moved; current native acceptance belongs to its owning execution.

The final entry audit also consolidated 12 standalone helpers into the `tool NAME`
family and routed 19 synchronous adapters through the shared custody/process
journal. Imported action modules now depend on `task_entry`, which lazily reaches
the single dispatcher; the command transport is source-sealed, while a direct
kernel import of CLI/historical producers remains denied. The three focused
static-boundary controls passed.

The expanded review gate remains separate: the concurrently maintained Zig
research view contains an out-of-repository reference and stale source bindings
(including `trajectory_exploration.py`, whose entry policy changed here). Its
producer must regenerate/rebind that view against the intended source snapshot;
this audit does not rewrite reference hashes or another owner's claims merely
to make collection pass. The broad failure is retained. Final lifecycle
acceptance isolates this exact open collection gate explicitly, rather than
reporting full graph/native acceptance.

Final results: 238 lifecycle/related tests executed, 237 passed and one discovery
was denied because concurrent Zig/host-root inputs changed during the read. That
single test passed on a subsequent bounded fresh read; its original failure is
retained, and the 238-test run is not relabeled green. All 11 actual interruption
controls and seven local provider controls passed in this final run. The three
static-import boundary controls also passed. Compilation and scoped whitespace
checks passed. All 16 recorded audit-source hashes stayed unchanged in the final
window. No unregistered immediate `.cache/` or `.data/` entries were found.
The final 612-row request journal still exactly matches its retired source, with
zero pending requests and SQLite integrity `ok`.

The source hashes, raw negative controls, per-path storage results and explicit
open gates are published in
[`corrective-v3.json`](../evidence/review/storage-lifecycle-20261020/corrective-v3.json).
Full review graph collection remains denied; the 21 unknown operational stores
and two nested Git checkouts remain protected. No real model service was started,
and no native repair process or checkpoint was restarted, replaced or moved.

## 2026-10-20: Work-item/process ownership and binding/custody closure

Task roots now represent maintained work items. `docs/work-items.json` admits
unique scopes and bounded reusable process roles; provider names, audit names and
dates do not create additional task roots. Admission is serialized across task
names. The existing combined 9–12 owner and checkpoints remain in place. The
independent host-root publication research owner retains its separate scope.
The cache currently has those two work-item roots.

The extra `lifecycle-audit` task introduced during this audit was naturally
finished, then absorbed into `repair-9-12/processes/audit/history/lifecycle-audit`.
The relocation preserves the directory inode and exact receipt bytes, archives
original paths/hashes, retains the original closure deadline, and leaves no
runtime forwarding alias. Historical failed broad runs remain failed records.
New audits reuse `workspace process-run repair-9-12 audit`; attempts live below
that process and do not allocate new task roots.

Each maintenance process has actual FD custody, a bounded role, separate run and
child journals, explicit interrupted-process reconciliation, and the same
Asia/Shanghai two-calendar-day cutoff on startup, normal return and collection.
A maintenance process cannot write sibling/native checkpoint cache areas through
the Python policy. Parent completion checks all process leases and actual child
observations. A state boolean cannot release an active child or admit restoration.
Codex and Grok use the same code paths; the controls use local children without
starting a real model service. See `task-workspace-lifecycle.md`.

The Zig research Evidence declaration now has a real materialization producer,
source review records, exact external Git base/patch snapshots, publication CAS
and a producer-bound receipt checked by full graph collection. The source review
workflow reproduces explicit deltas and enumerates affected citations; reviewed
semantic imports preserve concurrent new facts. The final producer execution ran
under the existing work item's `evidence` process. It evaluated the real engine:
818 traceable claims, 99 references, 983 evidence paths, 12,186 dependency paths
and zero unbound rows. The 52 missing requirements and 1,591 blocked rows remain
open. These counts are binding/query qualification, not runtime/model completion.
See `evidence-view-generation.md`.

All 21 previously protected historical validation-store roots now have proved
producer/queue custody, consistent SQLite backups and exact archive records, and
were removed by the owning collector. Unclaimed fixture jobs and failures were
preserved without execution or relabeling. A reused process-group number was
identified by the real current leader birth time; no signal was sent to that new
owner. The dependency registry now has 550 paths and 37 expired histories.

The two nested Git roots have explicit project and package ownership. Both main
heads are reachable from the named canonical integration, but `.ok` remains
untracked in `agentic-interface-065-uv`, and `trajectory-release-069` retains 15
dirty project paths plus a dirty nested `gerbil-poo` manifest. They remain
protected by source custody, not by a time-based exemption. Their integration,
dirty-source and nested-package release conditions are checked by the common
collector. Their resource audit is durable; updating the task dependency rows
remains deferred while the native owner's task lease is held. No lock was borrowed
or released to force that metadata write.

The 612-row durable request journal has zero pending requests and SQLite integrity
`ok`; all 50 sealed relocated programs still match their recorded hashes. There
is no root `campaigns/` directory. No native checkpoint was moved or restored,
and this framework audit does not claim native/Gerbil build/test acceptance.
The new public receipt is `evidence/review/storage-lifecycle-20261020/binding-custody-v4.json`;
prior v3 and earlier receipts retain their original results.

Final expanded regression executed 296 tests: 292 passed, one failed and three
errored; no tests were excluded. The audit's eight recorded producer/storage
sources and eight process/framework sources stayed unchanged in their recorded
windows. The broad result remains negative: another active Evidence author
changed OpenSysML traceability, the view registry and loader contracts during
execution. An earlier actual full-graph collection had passed, but a subsequent
fresh read correctly rejects the now-changed `evidence_views.py` and
`trajectory_exploration.py` references. Their new availability contract is not
silently admitted under the previous source review. Final full-graph acceptance
requires exact source review and real regeneration after that author's changes
settle. No generated view hash was patched to bypass this condition.

The first fresh four-test check passed the discovery and historical-view controls,
retained the strict source-binding rejection, and also exposed a test-runner
mistake: its action fixture inherited the production process output policy and
was denied creation under `.cache/tests`. That denial is preserved. The action
fixture is checked separately with the documented isolated-test context while
the actual parent audit FD remains held. Framework tests do not use production
request rows or borrow native execution authority.

Both isolated fresh action/historical-view controls passed (2 tests, 8.437 seconds).
The strict graph binding gate remains open for the two concurrent loader changes;
this successful read/control check does not relabel either broad negative run.
Scoped compilation and whitespace checks passed. The audit process returned
naturally, and neither the repair work item nor its native owner was finished.

## 2026-10-20: Cache-only runtime generation and incremental build storage

New supervised executions keep provider private streams, generated engine
Python/provider/policy trees, bytecode, uv and XDG caches under Cache. The common
Python write policy rejects generated pro/profile/prompt/policy/private/provider-
source subtrees under source, vendor, provider/provide/VR and environment areas,
including managed worktree source roots. Ordinary source editing is preserved.
The imported engine-seal API now applies the CLI's in-repository output allocator
before inventory or creation; explicit external export/test directories retain
their existing contract. The Python guard does not sandbox arbitrary native tools.
Both providers share the same runtime cache environment and restore the caller's
settings when their execution scope exits. No in-flight owner was reconfigured.

`workspace.build_output` allocates a stable task/process-local build directory
under `.cache/tasks`, independent of provider and attempt ID. The namespace binds
the selected compiler path/bytes, explicit flags and inherited build environment.
Matching configuration metadata is checked without rewriting it or changing its
mtime. A changed configuration selects an empty namespace; source edits in the
same work area remain subject to the native build tool's dependency graph.
Existing explicitly leased in-place workspaces and 9–12 checkpoints remain intact.
A cache hit does not skip the native build command, source checks or acceptance.
Transitive toolchain/dependency identity still belongs to its declared Recipe.

Real C/make controls observed 2 compilations cold, 0 with unchanged inputs, and
1 after changing one of two source files; the other object retained its mtime.
Codex and Grok reused the same build location. Different flags selected a fresh
location. This is a bounded fixture work-count result, not a measured full Gambit
or Gerbil speedup or native repair acceptance.

Build payloads participate in two-day owner-scoped collection. Pending requests,
live references, unknown databases, Git custody, unreconciled owner interruption
and registered recovery dependencies prevent cleanup. Real collector process
exit left a prepared inventory; a new old-dated file then blocked continuation.
After that file was removed, cleanup resumed without discarding custody records.
A separately killed build owner retained its payload until actual explicit
reconciliation. Registered dependencies require the existing owner release.

The final seven focused controls passed with all five recorded source/test hashes
unchanged during execution. They cover directory denial, shared provider cache
environment, actual incremental compilation/configuration invalidation, recovery
pins, collector death, owner death and engine-source archive preservation. Scoped
compilation and whitespace checks passed. Earlier development/broader negative
and source-drift receipts remain unchanged; they are not relabeled full-suite
acceptance. The prior full-graph/native acceptance boundaries remain separate.
Raw controls and exact source identities are published in
`evidence/review/storage-lifecycle-20261020/cache-build-layout-v5.json`.

## 2026-10-20: Mechanism granularity behind repeated debugging

The retained 9–12 failures support a granularity problem at the boundaries
between observation, mechanism, model premise and acceptance. This is a source
and public-artifact audit: 16 inputs were hashed in one unchanged read window,
and all 10 artifacts in the retained collector/alias review matched their
original size/hash manifest. No native run, new model check, raw debugger-memory
read, runtime/model edit or worker interruption was performed.

The existing obligation map already distinguishes admission from mechanism.
This audit makes the corresponding small discriminating controls explicit;
it does not create another framework, numbered workflow or campaign task.
The other research session is currently maintaining handler-return,
last-consumer and reclamation-order correspondence. Its model/Recipe ownership
remains intact.

| Boundary still compressed | Concrete retained source/evidence | Required distinguishing observation/control |
| --- | --- | --- |
| Worker recovery becomes a VM success flag | `handler-quiet-while-pending-cumulative.patch` records VM-wide `lifecycle_os_join_errno` and `lifecycle_same_owner_joined`; `recover_retired_processors` can set success after any later successful join while the VM errno is positive. | Bind actual error and success to the same worker incarnation, same exclusive owner and relevant generation; include quiet publication/observation and transfer order. A conditional A-error/B-success schedule must not earn A recovery. This is a correspondence counter-schedule, not an observed native fault. Model the supported real errno path or retain a terminal non-recoverable outcome. |
| Probe wording becomes recovery evidence | `lifecycle_join_recovery_probe.scm` prints SAME-OWNER after aggregate VM/errno checks. Its positive condition accepts a positive non-EINVAL errno, while `handler-quiet-join-recovery.recipe.json` requires literal errno 11 in stdout. | A printed phrase is not a per-worker event chain. Declare the supported errno population and bind structured events to source identities; reject cross-worker/owner/generation substitution. Do not widen an expected string or inject errno to manufacture a recovery pass. |
| Header observation chooses the cause | `structure_fault_observation.qnt` record actions directly select causes 1–4; `repairSelected` then sets solved. | Retain these as admission/characterization premises. Use the existing `structure_type_lifetime` transitions to distinguish initialization, publication, overwrite, relocation, stale reference and pre-read state. A real header/type record may support several hypotheses or none; it does not automatically identify the first faulty writer or prove a repair. |
| Observer success becomes object validity or one global snapshot | Retained collector review separates valid capture from bad descriptor; its freeze review still has a publication-to-stop/GC gap. An earlier hook failed before memory read, and an unbuilt generated-C file had the wrong source identity. | Independently establish exact loaded image/source, collector API readiness, record publication, relevant mutator/GC interval, actual stop and actual read. Test valid capture of an invalid object, failed read as unknown/error, owner collision and GC between publication and stop. Do not replace memory, hide invalid values as zero, or equate tag compatibility with mapped/live/type validity. |
| Compile exit becomes requested-pass coverage | Both retained dump probes exited zero but produced no alias dumps; the probe source had no function, so the required intraprocedural pass was not exercised. | Qualify accepted options and a nontrivial externally visible function first; require the requested phase artifact and its identities. Preserve option rejection, pass-not-exercised, incomplete observation, timeout and actual compiler defect as different outcomes. This control need not repeat the original numerical compilation. |
| Structural count becomes a cost/correctness model | The retained alias model failed its canonical storage-unit control; candidate and proposed oracle shared union/projection logic. PHI/CFG counts alone did not reproduce the original PTA wall. | Name the units: universe elements, merged classes, projected slots and actual pass work. Compare with independent reachability/set-closure semantics, including mixed-kind, duplicate, transitive and cyclic cases. Couple cost claims to the real relevant pass and unchanged semantics before another expensive source-repair experiment. |

The practical criterion is whether two states permit different legal operations,
observations or reclamation. Such states require distinct representation and
source witnesses. Adding arbitrary booleans, every machine instruction or another
aggregate PASS does not establish that distinction.

For each existing mechanism bundle, refine only the missing transition and its
source correspondence: identity/ownership before and after, actual publication
and consumption, error/partial completion, interruption/resume, and last access
before reclamation where applicable. Reuse QNT for reachable schedules and
negative controls, Lean for stated order/conservation/correspondence lemmas,
and Scheme for exact evidence support/revocation. A proof does not authenticate
an unobserved native event. Preserve separate counter-observations for a model
premise, observer prerequisite, source-correspondence gap and actual runtime
failure instead of flattening all of them into FAILED.

The smallest useful control should falsify a concrete mechanism premise and
retain its relevant input/observer identities. Existing checkpoint applicability,
material availability and custody determine stage reuse; prior=null or an
unrelated model update must not silently trigger or justify repeated configure,
seed and core builds. Independent investigations need not follow the artificial
ordering in the aggregate `lifecycle_gate_split` model. A changed premise may
justify a new experiment; an unchanged failed route supplies no new repair credit.
Full native and Gerbil build/test remain the final acceptance inventory after a
source-causal candidate is established, rather than the probe for every missing
diagnostic prerequisite.

The compact source-bound audit is retained in
`evidence/review/repair-trajectory-closure/mechanism-granularity-audit.json`.
These findings are a handoff to the existing source/model owners, not a claim
that the six mechanism gaps or native items 9–12 have been repaired.

## Mechanism granularity implementation and acceptance (2026-10-20)

The six gaps in the preceding audit now have executable refinements in the
existing QNT files, `RetirementRepairCampaign.lean`, the
`make-modeling-guidance` component and their tests. Execution uses the existing
`repair-9-12` validation, evidence and audit process roles. The active native
9–12 investigation continued independently.

| Gap | Implemented distinction and checked control |
| --- | --- |
| Worker identity and recovery | `retirement_repair_campaign.qnt` contains the pure `retirement_recovery_model`: source, configuration, VM incarnation, worker, generation and exclusive owner are part of every recovery event key. Scheme also binds the run. Foreign keys, old generations, another owner and contradictory target/event records cannot supply the missing join. Lean proves foreign-key exclusion and invariant preservation over arbitrary finite traces. |
| Actual error-to-success chain | A declared still-joinable error precedes a successful join for that same key. The finite test population uses errno 11 and 35; errno 22, a missing error and cross-key success are rejected. These are conditional model inputs, not qualification of an OS recovery path. A terminal error retains pending state and resources. The native probe and its literal errno expectation were not widened. |
| Header observation and causal diagnosis | `structure_fault_observation.qnt` and Scheme distinguish accepted capture from an invalid descriptor and from compatible hypotheses. Valid capture can retain a bad word and four hypotheses. Existing cause-selection actions remain admission premises; neither a header nor a model run identifies a faulty native writer. |
| Observer interval and last access | Capture acceptance checks loaded/expected image, record/copy owner, copy/stop epoch, API readiness, publication/stop/read stage and actual read success. A GC gap or failed read revokes capture support. Tag compatibility does not establish mapped/live/type validity. Conflicting records with one capture ID cannot be cherry-picked. |
| Requested compiler pass | `native_compiler_probe_correspondence.qnt`, Lean and Scheme require a positive declared function population and the requested artifact with matching source/compiler identities. Compile exit zero alone, missing dumps, warnings, identity mismatch and timeout do not exercise the requested phase. Contradictory compiler samples are rejected. |
| Alias semantics and units | Universe elements, merged classes, projected slots and measured work retain distinct units. Generic relation saturation is compared against an independent per-start queue BFS on six bounded fixtures: transitivity, cycles, duplicates, disconnected components, singleton and mixed-kind identities. The oracle does not call candidate saturation or projection. This is not GCC PTA equivalence or a compiler-time result. |

The consumer census is explicit. Handler body completion retains the handler
consumer; actual handler return removes it. Each private consumer requires its
own last-read event. The sequence is same-key join, observation of an empty
consumer census, transfer, pending-clear and reclamation. Missing consumers,
borrowed last-read IDs, contradictory consumer roles, terminal errors, reopening
and late consumer entry prevent a Scheme recovery chain. Source withdrawal
revokes support, and restoring the exact source rederives it. Native completeness
of this census, publication ordering and the event-to-C correspondence remain
separate obligations.

The corrected bounded policy has safety and conditional progress checks.
Progress assumes weak fairness of a changing, rank-decreasing recovery action;
it permits successful recovery or retained terminal failure. It does not promise
successful OS recovery. Four broken policies produce decoded TLC counterexamples
for mixed identity, body-end mistaken for return, early pending-clear and early
reclamation. Separate traces establish successful completion and terminal
retention as reachable states. Lean's `recovery_step_preserves` and
`recovery_trace_preserves` depend on no axioms; the complete file retains the
existing `propext`/`Quot.sound` ceiling, with no `sorryAx` or `Classical.choice`.

Compilation and source ownership are now explicit test inputs. The original
campaign module body is preserved, and recovery tests occupy another module in
that same QNT file. Test inputs copy literal maintained module bytes with a
recorded range/hash and bind the maintained container and dependencies. They do
not duplicate the transition implementation. The old and new tests share a
process-owned real compiler fixture and immutable compiled-control helper.
Named TLC configurations select properties from the actual unchanged generated
TLA. Tool readiness has a bounded preparation record; each compiler/checker
call retains its 30-second total budget, and the legacy Lean check retains
15 seconds. The cross-process guidance test now calls the framework's child
transport directly and retains stderr on failure. Its raw-child control exposes
`inherited task descriptor is closed`; the managed child preserves custody and
exits zero.

Acceptance is retained under
`evidence/model-results/repair-trajectory-closure/mechanism-granularity-03/`:

- The seven new Python tests passed, including ten named QNT mechanism runs,
  six oracle fixtures, Scheme withdrawal/identity/order controls and all 35
  printed Lean theorem audits.
- The bounded recovery control graph completed with 480 distinct states and
  zero queued states, including final temporal-property checking for the
  corrected policy. Its four mutation counterexamples and two reachability
  witnesses retain their actual states and logs.
- The existing campaign completed with 46,924 distinct states, zero queued
  states and finished temporal checking. All twelve existing campaign TLC
  checks (including five reachability witnesses) and its Lean regression passed.
- The related 22-test batch passed 21 cases and correctly rejected one read
  while the other session updated `repair-9-12-native-observation.json`.
  Only that case was rerun against a fresh snapshot and passed. The original
  batch remains recorded as an error, alongside the successful replay; it is
  not relabelled as a blanket pass. All 29 requested/related test cases have
  completed successful checks across these source-bound runs.

`mechanism-granularity.view.source.json` was materialized through the existing
producer after exact baseline/patch reviews. The registered view now exposes
`clue`, `factor`, `link` and inventory, and an actual repository read discovers
the worker-identity obligation. Its checkpoint continuation omits already-read
families. Six declared reference edges connect these observations to the existing
join-identity, producer-cause, observer-correspondence and numerical-completion
requirements. Their existing contracts retain their authority. Six native
requirements in this bundle remain `unclosed`; `applicable`,
`recovery_valid`, `capture_valid` and `pass_observed` are empty in this published
bundle. Synthetic positive control events were not inserted into the corpus.
The cost/oracle boundary remains one of the six explicit model-coverage gaps.

Prior rejected compilations, missing temporal receipts, source-race rejections,
the matched pre-change campaign baseline and the earlier checked cohorts are
retained with their identities. No generated hash or previous result was edited
to grant support. These results qualify model distinctions and evidence rules.
The ongoing source repair still needs its supported native same-incarnation
error/join chain, complete last-consumer and handoff witnesses, actual header/type
capture and exercised compiler-pass evidence. Complete native and Gerbil
build/test acceptance remains with the active 9–12 workflow and its retained
checkpoint; this model audit did not trigger another configure/seed/core cycle.


## Publication And Framework Entry Audit (2026-10-20)

The complete working snapshot was committed as `33c3a4d` and integrated into
SMP PR #1 as `f42828f`, preserving both the local snapshot and the existing
published research history. The separate gerbil-bazel checkout was published as
`260f944` in draft PR #57. It remains divergent from its current main branch;
publication does not claim a conflict-free merge or native qualification. No
active runtime checkout, worker or retained native checkpoint was reset.

The first exact-head SMP CI attempt exposed a real migration omission. Both
the three-flag build/patch jobs (`39413685638`) and framework job
(`39413684443`) rejected execution before validation because the fresh checkout
had no adopted work item. This is a framework entry failure, not a native test
failure, an inactivity verdict or a model counterexample. The original logs
are retained under `evidence/review/framework-publication-20261020/`.

The existing composite setup action now adopts the same `repair-9-12` work
item. The lightweight patch job does so explicitly and invokes the existing
`tool process-observation` dispatcher. CI output, engine archives and native
runtime transfers use that work item's Cache tree. The source-controlled runtime
input declaration, archive producer, upload, download and import paths agree.
The shared SDK checkout uses the existing tools cache. This adds no compatibility
entry, provider-specific task or new supervisor. Contract tests use the same
fixture isolation context as the full validation runner, so fixture cleanup does
not borrow production task custody. Existing execution and inactivity budgets
remain unchanged.

Two further transport gaps were corrected in the existing implementation. Direct
process budgets and progress windows reject NaN, infinity and booleans before
spawning, polling or journaling a process. The cross-process checkpoint test uses
the existing managed child transport, preserves child stderr, deletes the
disposable run files and then checks the immutable prefix in a fresh process.
Its production-task execution passed after the original failing attempt; it does
not restore worker memory or inherit producer liveness. Intermediate test
failures, including the temporary run-path/function name collision, are retained
rather than relabelled.

The current native observation still reports **8/12**, with native and runtime
admission false. Its recorded pre-join flag is not an OS join error; acquire-load
or compiler temporary changes have not produced complete native acceptance.
The lifecycle qualification helper checks a supported transcript and source
markers, but these alone are not a worker/generation/owner event census or a C
refinement proof. The existing mechanism model's complete identity, consumer
return/exit and reclaim ordering obligations remain the required distinction.
Actual header/type reads, complete alias-pass population and cost units, real
same-incarnation pending-join recovery, and full native/Gerbil build and test
receipts remain with the active repair. This audit did not start another local
bootstrap, runtime build or native acceptance campaign.

Final directed validation completed **34/34 tests in 29.669 s**, with all nine
input hashes unchanged. The real owned checkpoint-replay test also passed
separately in 9.008 s. The receipt binds the production audit process run and
retains both rejected intermediate runs and successful controls. This is local
framework evidence; the next GitHub head still requires its own CI result.


## SMP-Only CI Publication Closure And Storage Audit (2026-10-20)

The owner clarified that publication and repair scope is SMP PR #1 only. The
incorrect outer-repository draft PR #57 was closed and its isolated, uncommitted
merge attempt removed. No outer merge was published; existing commits and the
active SMP/native checkouts were preserved.

At SMP head `d35a485`, framework run `39419273023` returned producer exit 1
before collecting a test inventory. Its retained `process.log` identifies
`ReferenceUnavailable` for the root-signal comparison and constructor receipts.
This is a publication-closure failure, not a failing model or a deadlock. The
three-flag run `39419273003` was cancelled; its build/module outcomes are not
complete native results.

Checking every registered view against the prospective Git tree identified four
Cache-only dependencies: those two receipts, the runtime-retirement receipt and
the mechanism-granularity-03 receipt. An initial exact-byte inclusion candidate
was examined but not pushed. The reviewed reproduction boundary instead keeps
those runtime observations in Cache and withdraws their current qualification
support. Historical identities and verdicts are preserved, not rehashed into
current proof. The mechanism view is regenerated through its existing producer
with its reproducible sources and missing qualification explicit. A regression
checks each remaining published reference against the exact Git blob or pinned
submodule blob. Merely finding it in a developer's ignored output directory is
insufficient. No native campaign was started by this publication repair.

The stable concurrent cohort also includes explicit task-bound CI commands, the
editable source installation correction, retained-runtime cache-miss handling,
stronger join-qualification controls, handler-return/consumer evidence and Zig
research. These are audited and tested as their own layers; docs, source-shape
controls, compiler-cache reuse and formal evidence do not admit pending-join
recovery or increment the native milestone.

The proposed native-script symlink exception exposed a real authority escape.
Both a cross-task write and a cross-process write succeeded before the fix. The
existing storage policy now constrains a link to its storage owner and applies
the same task/process policy to its resolved target. Same-owner script timestamp
updates remain permitted. The complete nine-test cache/layout group passed after
this correction, including a real cold/no-op/edit compiler cycle and configurable
cache invalidation. The two denied-write controls retain their original failures.

The initial 81-test related batch passed 79 cases and recorded two local sandbox
Unix-socket bind denials. Both affected broker/cache tests passed with real socket
access on a separate two-test replay; the original batch is not relabelled as a
blanket pass. Seven consumer-interface tests passed in 132.886 seconds, including
the guarded Lean contracts, published model closures, source-correspondence gaps
and actual graph/checkpoint queries. Native recovery, compiler type/header
witnesses, alias-pass semantics and complete native/Gerbil acceptance remain
separate requirements of the running repair.

The broader workspace/custody/storage regressions passed **68/68 in 79.977 s**.
The publication-tree check passed against the exact prospective merged Git tree,
including the hashes of Git blobs and pinned submodule blobs. It reads the
published registry and views from those blobs, rather than mixing an immutable
publication with ongoing worktree edits. The earlier Zig cohort is retained as
a checked snapshot; subsequent collector/root research edits remain pending
until their own source and generated views settle.

The independent Cache-publication/withdrawal group passed **15/15 in 110.791 s**.
Head `23ae26e` then exposed a separate stale Zig producer binding in framework
run `39429329663`, again before test collection. Source inspection found the
exact `outputSha256` mismatch; the SC20 loader citation/source updates also needed
to be represented in the authored declaration. The other author published
`5e2a373` using the reviewed producer. The merged publication audit checks the
declaration, generated output and generator Git blobs together, as well as every
reference and pinned submodule blob. It does not bless working-tree hashes or
grant native authority. Subsequent Zig research drafts remain outside this
checked cohort. Execution logs and this audit’s detailed receipts stay in the
existing work-item Cache; Current Work records their conclusions.

Detailed execution evidence is retained under `.cache/tasks/repair-9-12/processes/audit/runs/513d452a3f44415dabc9d0d682567f48/outputs/acceptance/smp-ci-publication` (including the initial failures and explicit rejection controls).
The final Git-blob/reference/producer closure check passed in 10.804 seconds;
this checks publication consistency and does not certify runtime recovery.

At integration head `9e2d238`, `patch-contracts` passed. Native build run
`39431722547` failed before construction: its seal step still invoked the
dispatcher without an explicit task, while the framework workflow already
declared one. All four native research actions (seal, run, export and module
import/run) now explicitly use `--task repair-9-12`. The wiring regression checks
every native execution line, so adopting during setup cannot conceal another
unmigrated call site. Module jobs were skipped after that failed build and are
not acceptance evidence. This is an entry-policy failure, not a native fault or
a request to widen any budget.

All twenty CI wiring, source-lock, candidate and clean-checkout controls passed
in 4.243 seconds after the explicit native-task correction. A real Git-index
control restored the stale `23ae26e` Zig binding and the publication check
rejected it; the valid index was then restored. That expected rejection is
retained separately from the successful producer/reference check.


### Full-Campaign Failures And Scoped Repairs

The full `5e2a373` campaign retained 1,982 tests, 116 errors and seven failures.
The subsequent `c500a7b` campaign retained 1,987 tests, 117 errors and seven
failures. These are actual failed campaigns, not whole-suite successes. The
sealed native owner stderr identifies the first cascading cause:
`ModuleNotFoundError: gambit_smp` before its isolated `serve()` path installed
the sealed package search path. The native build reached its verdict stage and
failed through the same evaluator startup path. Deferred controller-side task
transport import fixes startup without reopening a terminal owner or replacing
its `closed` flag. A real `python -I -B` packaged-source regression now reaches
the missing-manifest boundary; 24 owner/API-scope controls passed in 1.224 s.

Other exact-log repairs distinguish fixtures and historical claims from live
state: lifecycle controls now construct their own failed-join/banner fixtures;
historical transport drift is calculated from all actual inputs; changed model
projection inputs remain unqualified; partial private source maps do not become
portable native witnesses; old Current Work citations expose missing Scheme
premises instead of acquiring new hashes; and historical CLI reproduction still
requires an explicit owned fixture task. The fixture restores its caller's
root environment. Eighteen affected controls passed in 40.657 s. The clue oracle
follows real checkpoint pages and rejects repeated cursors rather than assuming
that the expanded graph fits into one display packet.

Both formal harnesses now honor the explicit pinned `QUINT_TLC_JAR`. A local
replay used an actual separate copy of the pinned Jar and retained its exact
command path. Its positive TLC attempt exceeded the unchanged 30-second cap
before reporting states; the composite local attempt was interrupted at 180 s.
It is not a passing model replay or counterexample. No checker cap was widened.
The owned compiler receipt records real termination, reaping and group absence;
only the auditor's validation process was explicitly reconciled.

The two changed harness references were reviewed with exact c500a7b baselines
and applicable patches under
`evidence/review/repair-trajectory-closure/declared-jar-source/`. The real view
producer first rejected the incomplete reference update; its interrupted audit
process was reconciled before the second explicit review. Final generation
produced `2f2f0680ae765c7224c1d3436fb477807b78516e42c34b05c29e639d5d57cff3`,
retaining six native requirements unclosed and zero `applicable`,
`recovery_valid`, `capture_valid` and `pass_observed` rows. This is genuine source
binding and query evaluation, not a forged recovery or fresh formal PASS.

## Repeated Native Build Starts: Actual Cache Audit (2026-10-20)

The user's Repair 9-11 report concerns model-created build attempts inside the
existing combined `repair-9-12` owner; it does not authorize splitting that live
owner. Inspection found eight `typeid-witness-runtime{,-2,...,-8}` requests with
no `prior`. All declared `workspacePolicy: isolated`. Each had a different
source-lock digest, so they must not be described as eight byte-identical
builds. The configure profile and Recipe bytes were unchanged. Several attempts
again completed configure, seed and core. A directory suffix was acting as a
fresh execution identity across successive source revisions.

The existing `build_output` allocator already preserves a build work area across
Codex/Grok and run IDs, and the explicit in-place Recipe path already uses real
workspace leases. However, the audited Recipe still selected isolated cloning;
the allocator's presence did not enforce its use. The completed-producer guard
only searched explicitly registered completed references, leaving ordinary
failed/intermediate and unexported attempts outside its duplicate-start check.

The existing reasoning-history checkpoint transaction now refuses a new
expensive native-build header without the latest matching prior lineage. The
same Recipe remains one lineage across changed source locks. Independently
renamed Recipes also collide when their source/configuration dependency graph
matches, independent of step names, output paths, engine seals and budgets.
The check spans task-level and maintenance-role paths, reads old authenticated
headers, and executes under the existing `BEGIN IMMEDIATE`; it adds no state
database, compatibility launcher or provider-specific framework. A rejected
start commits no execution prefix and launches no sealed child/compiler.

This is a launch guard, not an artifact admission or a recovery result. Explicit
prior edges still pass the runner's existing quiescence, source/tool, budget and
stage-consumption checks. Source changes can invalidate passed stages. Actual
incremental execution still requires the existing owned in-place/state or
seed/completed-producer path, native dependency invalidation and current output
verification. The active isolated Recipe and existing sealed worker were not
silently converted while running. Cache existence, a model result or a Python
flag does not establish an incremental build or repair 9/12.

Validation and retained failures:

- Final nine start controls passed in 8.922 s, including competing real
  processes, an actually killed producer, durable history after Cache loss,
  cross-role starts, renamed declarations, changed sources and latest-prior
  selection. No killed producer was relabeled recovered or successful.
- The 51-test history/runner/control replay passed in 75.077 s after fixing
  three old CLI fixtures to create and use their own real temporary task/root.
  The first replay's three default-owner routing errors remain retained. An
  attempted reconciliation was refused by the expected-run assertion when the
  real owner had already advanced; no newer owner record was overwritten.
- An earlier 16-test host run passed in 23.159 s, covering seven initial start
  controls and all nine build-layout controls. Actual CC/make compilation
  counts were cold=2, no-op=0, one-source-edit=1, with separate flag invalidation.
  The initial sandbox's Unix-socket bind failures remain retained, not passes.

Exact logs, inspected header hashes, changed source hashes and remaining scope
are archived in Cache only:
`.cache/tasks/repair-9-12/processes/audit/runs/7491ec80b692432c9635af183a8a92cc/outputs/acceptance/repeated-build-starts/receipt.json`.

Remaining acceptance is explicit: migrate the actual isolated native/Gerbil
build adapters to their existing owned workspace/state or validated producer
path at a safe owner boundary, then measure real cold/no-op/source-edit/config
invalidation and interrupted continuation there. Artifact expiry must preserve
lineage and expenditure; unavailable objects require an explained rebuild,
never invented recovery. These local controls do not establish that migration,
complete native/Gerbil qualification, or a new runtime milestone.

## Actual Incremental Recipe Migration and Recovery Audit (2026-10-21)

This extends the earlier repeated-build-start audit with actual adapters. It does
not establish repair 9/12, full native qualification, or full Gerbil qualification.
The running worker, original two Recipe declarations, native repair sources and
retained failed receipts were not stopped, redirected or rewritten. Both original
Recipe hashes still match the authored migration declaration.

The maintained CI native Recipe now selects the existing `gambit-core` build
product. Explicit successors for the typeid witness, handler recovery and combined
native/Gerbil flow are authored under `evidence/research/incremental-builds/`.
`docs/work-items.json` declares exactly two products for repair 9–12: `gambit-core`
and `gerbil`. Both sealed research and the Python Recipe runner, including v1,
refuse future isolated/unpartitioned configure launches before native execution.
Provider, run number, renamed Recipe and materialization storage routing cannot
create an independent expensive-build lineage. There is no compatibility launcher
and no new dispatcher, task root or state database.

The migration declaration binds each original source Recipe and its allowed
successors. Its `--prior` edge retains actual history/expenditure through existing
checks. `restoredStages` is empty and runtime admission is false. It does not
import an old isolated compiled runtime or assert recovery from its presence. A
first managed build without a verified existing managed product remains cold.
Active sealed code keeps its original bytes until a safe owner boundary.

Actual build behavior now follows the managed source workspace:

- Cold verified, unpublished staging moves into the empty leased source root
  without a second full source copy; the root inode is retained. Warm source
  materialization archives only old/new overlay paths and retains the full
  source inventory. Only changed source bytes receive fresh timestamps, leaving
  unrelated objects eligible for the native builder's normal dependency checks.
  A pending source delta is durable before mutation, including partial cold
  transfers. Unknown bytes are rejected rather than overwritten.
- Compiler/backend/tool bytes, flags/environment, base revision, build profiles
  and configuration input changes partition workspaces. Native configure reuse
  binds its raw completed/quiescent process record and nine generated files,
  and still probes real effective SMP/VM macros. A successful command summary
  inconsistent with the original process record is rejected.
- Source regeneration keeps actual bootclean command/log bytes, gsc-boot bytes
  and the generated-source inventory before real `make core`. An interrupted
  make continues through that builder without repeating destructive bootclean.
- Gerbil consumes the exact same-producer Gambit runtime/identity, installs its
  actual payload, and calls the pinned upstream build driver's stages. It avoids
  upstream prepare's deletion and unconditional second Gambit bootstrap. Only
  completed bootstrap stages with exact process, input/dependency, output and
  internal-alias proofs can be reused; downstream dependency-aware builders run.
  The pinned existing source checkout and an authored exact compiler overlay are
  read inputs, not a new clone or a modification to the live checkout.
- Actual source-lock file descriptors propagate through framework execution,
  process observation and Python helpers. A killed controller cannot surrender
  the workspace while the last make/compiler consumer remains alive, including
  within the same long-lived worker and generation. Later generations also need
  actual previous-owner reconciliation and process-group checks. Neither a
  boolean nor a passed model replaces these checks.

Validation boundaries and retained failures:

- Real CC/make controls exercise Codex→Grok reuse: cold=2 compilations, no-op=0,
  one-source-edit=1, changed configuration=2 in a distinct workspace. Other real
  controls kill the supervisor after one object, interrupt a source delta and
  a cold transfer, and deny reuse while the actual last consumer remains alive.
- The Gerbil adapter fixture invokes real shell stages, CC and make with an
  explicit small Git source/runtime fixture. Cold=5 actions, warm=0 extra
  compilations, a stdlib edit=1, and changed runtime identity=5 in a new product.
  A real timed-out stage1 resumes using only completed boot-gxi/stage0 receipts.
  Changing the gxi alias forces the actual stage again. This is transport/build
  control evidence, not a real Gerbil Scheme/bootstrap test-suite pass.
- The 153-test broader replay completed in 139.179 s with one failing immediate
  quiescence assertion. Darwin returned an unknown initial kernel probe after
  killing a timed-out fixture. A later 42-test replay hit the same assumption
  in the regeneration fixture. Both tests now require a separate actual ESRCH
  absence observation before reconciliation; the original unknown/timeout
  receipt remains unchanged. No production admission rule was weakened.
- A 35-test replay retained one test-code assertion mistake: it compared a
  manifest with `checked_manifest`'s returned tuple. The assertion was corrected
  to inspect that return contract. The subsequent 50-test proof/native-Recipe/
  Gerbil-driver replay passed in 32.528 s, including rejection of a failed raw
  configure observation hidden behind a successful summary.
- The actual upstream Gambit adapter test did compile os_thread.o/os_shell.o and
  complete cold/no-op/source-edit phases in earlier attempts. Its full four-phase
  control has not passed: three 240 s audit wrappers timed out at the final new
  configuration; the latest cold-transfer revision timed out in configure's
  unchanged 90 s configure-context ceiling (test duration 126.097 s). An earlier fixture
  selected ambient Nix tool paths and configure exited 77; the test now selects
  production `native.host_tools`. These failures remain failures. Warm archive
  work was reduced to delta paths and cold source transfer measured 13.757 s
  versus an earlier 22.109 s sample; these are host-local observations, not a
  controlled end-to-end speed claim. No timeout was increased to obtain green.
- Role startup now clears the prior run's exit field. An earlier forced audit
  timeout had retained a stale exit=0 alongside timedOut=true. That historical
  receipt is preserved; a real regression now checks a subsequent interrupted
  run cannot inherit that zero exit.

The final owned recovery replay result is recorded with the archived logs below.
Remaining native acceptance is the complete upstream configuration/object control,
full native build/test, and full Gerbil build/test on a genuinely qualified
same-producer runtime. This audit deliberately did not launch those expensive
campaigns against the other worker's active 9–12 source or claim them passed.
Build products use existing two-calendar-day retention and owner/child/reference
checks; active Git/database payloads keep their existing release conditions.

Final recovery replay: **18/18 passed in 57.474 s**. The separate proof/Recipe/driver replay was **50/50 passed in 32.528 s**. Earlier failures above remain retained.

Cache-only archive: `.cache/tasks/repair-9-12/processes/audit/runs/c301ff4ff9784347885590821e963969/outputs/acceptance/incremental-recipe-migration/receipt.json`. It records current source hashes, original declaration checks, audit-run receipts and retained failed-fixture process/configuration records.

## Configure Cost and Retained-Runtime Qualification (2026-10-21)

This audit continues the preceding incremental Recipe work without stopping,
restarting, editing or hot-resealing the other repair worker. Test attempts and
failed receipts remain separate from native repair admission.

The configure failures had two different boundaries. Three earlier controls hit
their 240 s aggregate wrapper during a second cold configuration. The later
control exhausted its 90 s configure context. Retained logs show advancing
Autoconf probes, not a fixed non-quiescent probe. The framework had selected
`/usr/bin` xcrun dispatchers as its assembler/linker/make/m4 identities. A matched
six-pair actual GCC compile/link control measured mean system-dispatch time
0.268346 s versus 0.222068 s with the resolved developer-tool directories. These
small host-local observations do not establish an end-to-end speedup.

`native.host_tools` now resolves the selected Darwin tools through xcrun once,
binds their actual executable bytes and puts those directories in GCC's search
path. The actual upstream four-phase object control then passed in **211.447 s**
under the unchanged 240 s wrapper and 90 s configure contexts. Configure took
68.927 s and 73.439 s; warm/no-op and single-source-edit configure observations
were 1.198 s and 0.856 s. Actual compilation counts remained **2 / 0 / 1 / 2**.
This closes that control; it does not establish full native/Gerbil acceptance.

The first sealed full-test attempt exposed a separate real failure: source
materialization took 37.425 s and exhausted its unchanged 30 s gate after Git
archive and before patch inventory. A matched 200-file deep-Cache extraction
profile measured Python `tarfile` data extraction at 2.156588 s versus 0.178300 s
for fully prevalidated supervised native extraction, with identical contents.
The Python profile recorded 400 realpath calls and 8,200 lstat calls. This
identifies per-file extraction/path/metadata overhead; it is not a compiler stall
or evidence for increasing the materialization cap.

Git and Gerbil source archives now use the existing supervisor's native tar
process after validating all member names/types/modes, internal link targets and
the absence of symlink ancestors. Both controller exit and actual process-group
quiescence are required before advancing. No arbitrary caller shell body is
accepted. Runtime archive extraction additionally retains its complete member,
manifest, raw-receipt and byte/mode/link checks. Cold native payload transfer is
durable before writing, retains the leased root inode and original object/source
timestamps, and verifies the complete installed tree. Warm import extracts only
metadata and checks every original payload entry in the same product workspace.
Generated test outputs do not become authored source or native admission.

That native extraction initially exposed a legitimate mode mismatch: Git archive
records 0664/0775 while the prior Python data filter produced 0644/0755. All source
SHA values matched, but 2,072 mode entries differed. The source guard correctly
refused the import. Source extraction now applies the matching fixed child-only
umask without altering another worker or the controller's umask. Frozen runtime
payloads retain their actual archived modes and timestamps. The source identity
comparison was not weakened and no stored hash was edited.

The runtime reused for qualification is the existing numeric-host archive, whose
gsi bytes equal the ready `c86dff86...` managed workspace. All original producer
source inputs were checked unchanged. Its original sealed generation is
explicitly pinned by the new input declaration and independently authenticated;
the new consumer does not load or execute the producer's Python. Source lock,
full source identity, original compiler/tool bytes, raw completed/quiescent
process receipts and all runtime output bytes remain mandatory. This is completed
artifact transport, not interrupted-stage restoration, a retry grant, a new
bootstrap, or a model-derived recovery claim.

Official native test consumers now publish a new observed runtime/identity view
after their real test outputs, so a following consumer can bind that new view
without rewriting the earlier producer's recorded tree identity. Both native
qualification and Gerbil build/test use the existing managed product workspaces.
Gerbil qualification uses the pinned unmodified upstream compiler: the earlier
diagnostic identifier/type-coercion overlay is deliberately excluded from this
acceptance contract. Its build and default recursive gxtest keep user/cache
writes in the managed product. No repair 9/12 claim follows from this baseline.

A real killed transfer control also covers a dangling internal alias created
before its target. Only the previously recorded pending link/bytes can continue,
after actual custody reconciliation; the final complete tree must resolve all
links. Native archive traversal, symlink-ancestor and mode/timestamp controls
exercise the same existing APIs. The last pre-qualification seal followed
**83/83 controls passing in 36.616 s**. Earlier 45/28-test runs exposed two import
helper errors (a missing name import and a Path/string contract mismatch), and
an 88-test replay exposed one transport-stage fixture expectation; those failed
logs remain retained. The corrected 55-test mode/import/Recipe/driver replay
passed in 28.842 s before the final process-quiescence checks were added.

Full qualification outcomes and their exact checkpoint/run references follow.

A subsequent retry found an additional executable-version boundary: prior-prefix
consumption restored the old materializer's PASS even after its implementation
changed. The rejected runtime import therefore still saw the old 0664/0775 view.
Checkpoint consumption now requires the same authenticated executor generation
in addition to the existing source/tool/output/quiescence evidence. Across an
executor change, history and expenditure remain, but execution stages are not
silently restored. Completed compiled bytes still travel through the explicitly
pinned, fully checked runtime archive into the same managed product. This avoids
both stale adapter output reuse and repeated native bootstrap. The old source
view and both rejected import receipts remain unchanged.

The retained runtime then imported successfully. A real environment probe exited
in 0.72 s, but its unchanged 10 s stage expired at 11.537 s because runtime
validation repeatedly resolved every ordinary source path. The held full-tree
inventory now supplies those same byte proofs directly; links retain real
containment checks and lease release retains full hashing. A real 956-source-file
profile measured validation at 0.2541 s, versus 3.3317 s for just one redundant
path-resolution pass. Initial lease validation took 9.1825 s and final full-byte
verification 4.0432 s; neither was removed. The next environment stage passed in
6.33 s with its actual native command taking 0.34 s.

That continuation exposed a further 15 s review timeout at 39.87 s: adding one
review fixture copied the entire native runtime and discarded its held-inventory
reuse. The review now copies only tests. Its campaign identity retains every
actual native entry and substitutes the complete actual prospective unit-test
inventory, including modes/aliases, before comparing it with actual execution.
No stored campaign hash is edited. Managed fixture reinstallation requires the
recorded transfer plan and identical declared/installed bytes; upstream inputs
cannot be replaced. Source synchronization also retains the original regeneration
and fixture-transfer custody, which their consumers still independently verify.
The corrected regression seal passed **120/120 controls in 50.227 s**. Complete
native and Gerbil outcomes are recorded below after actual execution.

The first complete review rejected a mismatched historical `setup.c` identity.
The existing `bazel-profile-gsi-intent.json` already binds the exact numeric-host
checkpoint, so the qualification Recipe now consumes that declaration. Historical
intent, source hashes, rejected receipts and policy premises were not rewritten.
The next review reached its original gate at 15.873 s. Diagnostic profiles exposed
another concrete cost: 420 APFS file clones were followed by 438 metadata-copy
operations (including directory copies), with repeated chmod/utime accounting for
seconds of avoidable work. Successful file clones now compare actual mode,
atime/mtime and flags and copy metadata only when those values differ. A real
APFS control verifies preserved executable mode and nanosecond timestamps,
different inodes, and independent mutation of the clone. Byte-copy fallback and
permission failures retain their original behavior. Diagnostic refusals for an
editable executor and a terminal journal remain recorded and confer no admission.

With redundant metadata writes removed, the real review completed in **9.425 s**
under the original 15 s cap and returned a genuine policy DENY. The remaining
route was `019-prim-port-budget`: its original single-file budget is **20 s**,
which a 250 s whole-Make limit cannot represent. The new transport observes the
exact upstream runner's flushed file frames, enforces those file deadlines, and
retains the enclosing fixed wall deadline. Missing/unfinished required file
intervals cannot pass. The original retry policy is unchanged; a sealed additive
fragment makes its scoped budget relation applicable to this actual bounded Make
transport. Per-file budget comparisons and all causal premises remain required.
The audit-only Make contract also records the real `ut ut-C:` and `st st-C:`
headers and their different unit/stress inventories; it does not infer nonexistent
single-name Make headers. The running repair worker's existing contracts remain
unchanged. Full execution of this transport is still pending the controls below.

The first actual Gerbil qualification reached **stage0 TIMEOUT at 600.931 s**
under the unchanged 600 s build cap; recursive tests were BLOCKED. Source
materialization and retained-runtime import passed (14.538 s / 16.630 s). Native
process observation shows twelve concurrent GSC jobs, including parents retaining
large Scheme heaps while waiting for real C compiler children. This is not a
completed build or test pass. Two concurrent validation wrappers also exhausted
their unchanged 120 s cap; their failed logs remain retained. Validation was
reconciled through the framework's actual child/custody checks before a focused
replay after the Gerbil workload quiesced.

Source audit found that upstream stage0 copies and compiles all bootstrap modules
unconditionally. Its worker catches and prints compilation exceptions, so global
exit/output presence alone is insufficient for fine-grained reuse. The remaining
adapter work is to record real per-module completion and exact output bytes,
retain only those completed prefixes, and bound actual compiler concurrency.
A partial object without its completed process receipt is not a reusable module.
The 600 s cap is not being increased.

The new real process controls passed for a killed file deadline, an observed
completed interval, missing-frame refusal, and exact managed-fixture custody.
A focused five-control replay also exposed a real integration error: `require`
forwarded `boundary` without declaring its default. The C producer was DENY with
`NameError`, leaving its consumer BLOCKED. The parameter is now explicit and the
aggregate replay is running again; no failed result was relabeled. A stricter
header audit additionally found the existing core-recursive declaration omitted
a real multi-target header. The complete audit contract records it, and the test
now distinguishes the incomplete legacy declaration from its explicit complete
successor. The old data file remains untouched while the other worker uses it.

### Continued execution and independently retained controls

The interrupted validation owner was reconciled through the framework before
relaunch. Some earlier `/tmp`-only controller transcripts were no longer present;
they were not reconstructed. Sealed Recipe receipts in task Cache remain. New
controls write their receipts and raw logs directly into the existing task/process
Cache rather than relying on temporary controller files.

The real four-phase upstream configure/object replay passed again in **112.327 s**
under the original 240 s wrapper and 90 s configure contexts. Actual compilation
counts remain **2 / 0 / 1 / 2** across Codex cold, Grok no-op, Codex source edit,
and Grok configuration invalidation. Cold configure observations were 44.083 s
and 45.791 s; the no-op/source-edit observations were 0.512 s / 0.447 s. Every
phase's actual configure/process logs, configuration and source-state inventories
were copied before fixture cleanup into:
`.cache/tasks/repair-9-12/processes/validation/runs/39b131166e4645e6b9c3b4aa79d63061/outputs/acceptance/native-gerbil-qualification/configure-object-control/`.
These are independent host-local controls, not a claim of general speedup.

The cold crash-journal control's original 10 s limit exposed installed ASCENT
inventory traversal and repeated API-boundary work. Inventory validation now
checks path components with call-local reuse and rechecks all paths at exit;
normal host root aliases are canonicalized before rejecting aliases inside the
package. Source/resource byte checks remain. Initial storage routing owns one
native API boundary covering construction and query, with full byte checks at
entry and exit. The real child then retained its journal and exited with its
expected code 7 inside the unchanged limit. The corrected seal/resource/Recipe/
process cohort passed **181/181 in 20.418 s**; the later target-configuration and
forged-module-receipt cohort passed **184/184 in 27.764 s**. The preceding failed
181-control cohort is retained separately.

Gerbil bootstrap now uses actual per-module GSC invocations, an observed compiler
processor count of one, and one build worker. It preserves unchanged copied-input
timestamps, records the complete input-copy plan before writes, and explicitly
names each `.o1` output. Module source bytes are checked after actual compilation.
A completed module requires its raw successful/quiescent process receipt, exact
output bytes/mode, and an independently authenticated completion in the existing
execution checkpoint. Rewriting a mutable receipt and its hash cannot substitute
for that checkpoint; the negative control forces actual recompilation. A global
stage0 receipt without the complete module inventory is no longer sufficient.
Partial outputs without completed receipts are compiled again. No timeout was
increased and no native VM memory restoration is performed by this adapter.

The full native attempt then reached actual upstream `TEST 2` and exited 70 with
`Heap overflow` before the error-handling fixture began. A matched same-binary,
same-fixture, same-stdin control passed with one processor in 0.178 s and produced
the exact upstream expected stdout hash; twelve processors failed during startup
in 0.015 s. The original min/max heap options were retained. Qualification now
states a target-specific single-processor configuration for this independent
legacy heap test. Real Make controls verify that it cannot reach sibling targets;
the API rejects overrides on unit suites or dependency closures.

A subsequent actual observation caught another genuine binding gap: the probe
used eleven processors while Make's implicit runtime default was six. Official
Make consumers now explicitly adopt their same-producer environment observation
and measure that configuration before execution. The campaign binds this actual
population. Only `TEST 2` receives its declared target-specific value; complete
unit and stress invocations retain the observed SMP population. Neither the heap
budget nor any native test deadline was increased. Full acceptance outcomes follow
only after those real commands finish.

### Git and task-checkpoint source custody migration (2026-10-21)

The duplicate-source audit found two producers in the existing Evidence
framework: source-binding reviews replayed a baseline plus a patch, and Git
imports wrote source/base/working-patch triples under `evidence/source-snapshots`.
Both normal paths now use immutable Git or existing task execution-checkpoint
identities. `ascent.source-binding-review.v2` binds exact before/after bytes,
affected citations and retained scope; v1 cannot be submitted as a new review.
Git import still checks the declared revision, live bytes and declared dirty
delta, but no longer replays or publishes that delta. Source identities are
read through the same existing authenticated journal used by other execution
checkpoints; no parallel storage framework or task namespace was introduced.

The real audit execution `4783cd7c307e40a19ed4a9bfc61d8c8a` migrated all nine
legacy source reviews, fourteen referenced documents and thirty-four redundant
source/baseline/patch artifacts. The plan and original-document identity map are
in `evidence/review/source-storage-migration.json`. Exact original review and
receipt bytes remain available through their checkpoint identities. Historical
model-result inputs retain their independent evidence custody; only the extra
review baselines and generated source-copy store were removed. Runtime repair
patches under `patches/` were outside this duplicate-review migration.

All three maintained declaration views were regenerated by the real producer,
then regenerated again after the final producer implementation changed. The
second producer run `a87c8eea15014f31a7370cc29225be30` reported `engineEvaluated=true` for
reasoning-methods, mechanism-granularity and zig-native research. Each returned
zero `unbound` rows. The mechanism view still reports its six model gaps and
five mechanism gaps; regeneration does not turn those into recovery success.
The Zig view preserves exact previously cited versions of concurrently dirty
documents through Git identities. The previously cited reader bytes use a reachable Git identity; the imported
Gerbil source uses a verified historical checkpoint identity. No cited digest was
refreshed merely to accept a changed current file.

Initial targeted validation passed 39 tests, including real interrupted
migration publication/resumption, concurrent edit refusal, Git object tampering,
checkpoint transport expiry and exact historical review retention. An extended
92-test read run then exposed a genuine fixture dependency: isolated history
stores did not contain the newly referenced source checkpoints (30 errors and
one consequential assertion failure). The fixture now seeds the exact,
authenticated original checkpoint/observation rows into its isolated database;
ordinary prefix verification remains enabled. The two failing representative
cross-scope/cross-process reads passed after that correction. Final regression
results are recorded below after completion.

This work did not launch a native build, attach a debugger, signal the active
9–12 worker, or claim native/Gerbil acceptance. A fresh clone without the task
journal must fail on local-only checkpoint references; publishing those
references requires retaining the existing journal or rebinding exact bytes to
committed Git identities, never ignoring missing custody.

A final producer replay after the identity-review API update also loaded all
41 registered views through the real loader and checked generated bindings.
All 34 removed artifact identities were independently resolved again; a scan of
maintained source, docs, tests and Evidence found no remaining path consumers of
the removed copies (the migration map retains their old paths as provenance).
The additional abrupt-child-exit test passed in 1.134 seconds: the child exited
17 after the authenticated migration plan commit, left the original copies
intact, and the parent resumed that exact plan to completion.

One validation supervisor invocation (`95b5d2ccd200471c8a39773b294dbff0`)
incorrectly inherited production task custody into test fixtures instead of
using `isolated_test_context`; its 300-second deadline expired. Its original
failed run is retained. A planned spawn record
`b735853856c34ca0a0e63c93d943c298` has no committed PID/birth observation, so
`process-resume` correctly refuses reconciliation. No journal was hand-edited,
removed or marked recovered. This auditor-owned validation role remains held
for explicit spawn reconciliation; it does not confer native acceptance or
alter the other worker's 9–12 role. The corrected regression invocation uses
the existing isolated test context and a separate auditor-owned execution.

The isolated aggregate regression (`9bb102caa3c543ad8fe6ce8f40caa7c5`) also
reached its unchanged 300-second supervisor deadline before a terminal unittest
summary. It is incomplete, not a 92-test PASS. The audit role was subsequently
reconciled through `process-resume` using real recorded group observations; the
separate unresolved validation spawn remains held. Functional controls are being
completed in their natural test-class batches with the same per-run ceiling.
Their individual results do not erase the aggregate timeout or establish a
whole-suite latency result.

The source-identity, storage-binding, Evidence, source-block, progressive-query and API-scope class batch passed 55/55 tests in 24.282 seconds (audit run `f79e2cb228d04633a68c38875488a09b`). This includes the actual abrupt-child-exit migration test.

The first 19 CLI controls passed 19/19 in 88.319 seconds before an additional
checkpoint-granularity improvement. Inspection found that the hot imported
Gerbil source reference authenticated one compound checkpoint with 59 entries
and 3,860,892 encoded bytes. New captures now use one content identity per
existing execution-checkpoint record, deduplicating equal bytes within a
capture. The maintained reference was rebound to a one-entry, 61,300-byte
encoded record and the views regenerated; the compound record remains immutable
historical evidence. A dedicated control verifies that a small source does not
share its checkpoint payload with an unrelated megabyte source. This changes
neither the task namespace nor the database, and creates no new build workspace.
The final complete related test run retains the same 300-second ceiling.

Final related regression passed **94/94 tests in 222.304 seconds**, within the
unchanged 300-second supervisor ceiling, at audit execution
`7c7e50e1862f4608a146637bb4f64c5b`. This final run includes all migration,
source-binding, Evidence loader/projection, progressive CLI/checkpoint and
API-observation controls listed above, including abrupt child exit and the
single-content checkpoint granularity test. The earlier failed and timed-out
runs retain their original outcomes.

Final receipt production independently verified the real test process exit 0
and parent reap, loaded and checked all 41 registered views again, verified the
checkpoint/Git identities of all 34 removed artifacts, and confirmed the files
remain absent. Its receipt records post-run implementation/test hashes and the
reported unittest summary, explicitly without native admission:
`.cache/tasks/repair-9-12/processes/audit/runs/b10a810b13f04cc29434d7d73f5f1417/outputs/source-custody-acceptance/receipt.json`.
The unresolved spawn from the incorrectly isolated earlier validation attempt
remains explicitly held; this successful source-custody verification neither
clears it nor substitutes for real operational recovery. No other 9–12 worker
was stopped, resumed, signalled, or attached to during this migration.

### Spawn birth custody and legacy reconciliation (2026-10-21)

The held spawn `b735853856c34ca0a0e63c93d943c298` belonged to this auditor's
validation run `95b5d2ccd200471c8a39773b294dbff0`, not the parallel 9–12 worker.
Its planned timestamp was `11:01:15.700046+08:00`; the watchdog's actual parent
reap ended at `11:01:15.712657+08:00`. That run contained 5,770 finished children,
one interrupted child and this one unbound plan. The original command hash was
`3437e92e09c695cd3624999847aa96d489438939312e9b6c1747ded59c328a93`.

A controlled read-only Evidence query reconstructed the exact command before
executing it and matched the original argv hash:
`git --no-optional-locks -C <SMP> rev-parse --verify 33c3a4db0db28e66ba70b96213cbe38f37074ad3^{commit}`.
No PID or birth was invented for the historical call. Native kernel inspection
confirmed the old supervisor/child identities had exited and their group was
absent. Two same-UID process censuses (640 entries each) had no surviving birth
in the launch interval, including the conservative one-second timestamp margin.
The raw inspection is retained at
`.cache/tasks/repair-9-12/processes/audit/runs/dbb00ec91dc54ec08eafd4f87a458f31/outputs/spawn-forensics/inspection.json`.

The existing `workspace process-resume` entry then performed the narrow metadata
read discard under the validation role's real locks. Its receipt preserves the
original planned journal bytes, argv binding, producer exit/reap, parent/group
observations and both full censuses:
`.state/task-processes/repair-9-12/95b5d2ccd200471c8a39773b294dbff0/b735853856c34ca0a0e63c93d943c298.legacy/receipt.json`.
The old run stays `interrupted`, exit -9. Historical target execution stays
`unknown`; outputs, replay and native admission are false. Only the operational
role was reconciled. There was no hand edit, fabricated PID, blanket force flag,
or replay of the old command. Arbitrary unbound commands remain rejected.

The source defect was the parent-only sequence `planned -> Popen -> started`:
controller death could fall after kernel creation and before PID publication.
The existing task, workspace, Grok, generic capture and sealed research paths
now share a child-owned birth/exec barrier. A launcher inherits actual per-token
custody, writes its kernel birth before target execution, and waits for parent
permission after the parent durably commits that birth. If the controller dies,
EOF cancels an unpermitted target. If the target has permission, recovery still
requires real custody release, kernel-birth observation and group quiescence;
no completed execution is synthesized. `started` explicitly names the
birth-before-exec phase, while native completion still needs real exit/output
receipts. The internal launcher interpreter is isolated from target site hooks
and target environment injection. The original environment crosses only a
private pipe after birth; no environment secrets are written to the request.

Runtime request, birth and permission files use the existing task/run Cache.
This turn's three early prototype directories were moved out of State only
after real quiescence, retaining inode identities and bytes through the framework
checker. No new task ID, worktree, database or build workspace was created.
Fixed deadlines now include startup handshaking; no program timeout was enlarged.
A request-write failure closes all newly opened descriptors, and genuine exec
failure preserves its real OSError plus nonexecution observations.

Real interruption controls cover controller SIGKILL before Popen, a kernel child
paused before birth publication, birth committed with no parent PID record,
birth committed before permission, and a live executed target after controller
death. That live target blocks resume until its own verified process group exits;
the old side effect is not replayed. Further controls verify target site hooks
run only after birth, actual exec failure, request failure without FD leaks,
and refusal to execute after an expired absolute deadline. Existing compiler
last-consumer, Grok, watchdog, workspace and sealed research controls are included.

The first complete related run passed 168 tests with stable pre/post source
identities. Further FD-failure and absolute-deadline checks led to the final
source revision; the definitive result and raw receipt follow below. No other
9–12 process was signalled, attached, stopped or resumed. These are host-local
framework controls, not native SMP/Gerbil repair acceptance or remote CI.

Final verification passed **173/173 tests in 46.522 seconds**, with zero failures,
zero errors and identical pre/post implementation/test hashes. The definitive
raw log and receipt are:
`.cache/tasks/repair-9-12/processes/audit/runs/a749cd4a5502463cb083a8da4890492b/outputs/spawn-birth-validation/tests.log`
and the adjacent `receipt.json`. The prior 168- and 171-test receipts remain
historical intermediate source revisions, not substitutions for this result.

The final entry audit also aligned Python APIs with the existing CLI rule that
provider sessions belong to the work-item execution owner, while registered
maintenance processes run bounded tools. Both Grok's API and direct
Codex/Grok workspace execution now reject the wrong owner before creating a
child. The two added controls use isolated fake providers; no external model
was launched. One new fixture initially attempted to create its test host-tools
inside the already active maintenance scope and was correctly rejected by the
storage policy; preparation moved before that scope, with no production policy
relaxation. Request-write failure deliberately retains its real `spawn-failed`
record and errno; the corrected assertion requires that evidence rather than
incorrectly requiring an empty journal.

The formerly blocked validation role was also exercised through the real
supervisor in fresh generation `b57a15260c83401181d26d539476c932`, tagged with
provider `grok` but executing only a local Python identity probe. Its real PID
was 56476, PGID 56476, with kernel birth recorded before exec. It returned exit
0 and was reaped. This demonstrates reuse of the role through the same framework;
it is not a Grok model run or a repair test. The original failed run remains
interrupted, exit -9, and its historical metadata-read execution stays unknown.
All early prototype launch runtime files owned by audit/validation are now in
their existing task/run Cache rather than State. Other 9–12 work was untouched.

### Remaining process entries and end-to-end lifecycle acceptance (2026-10-21)

Scope: `codex/framework-dependency-dedup`, base HEAD `1a2d861`, existing
`repair-9-12` audit/validation roles. No production native source repair,
compiler restart, provider model invocation, timeout expansion, or change to the
other worker's processes was performed. Production bulk source migration is
**deferred by live custody**, not admitted as complete.

The source audit found real bypasses in workspace Git commands, cleanup's
`lsof` inventory, and patch validation/application. These now use the existing
task subprocess adapter. The package has one raw `Popen` call, inside the
transport's internal creation boundary; unscoped bootstrap/read-only synchronous
adapters remain nondurable. Active task launches reject missing or in-memory
recorders before Popen. The existing Python audit hook additionally rejects raw
Popen aliases/wrappers, system/shell, fork/posix-spawn and direct exec within a
managed scope. Internal creation and exec permissions are transient call guards;
actual durable birth, exec permission, descriptor custody, and kernel group
absence still establish recovery. They do not admit native restoration or exit
success. This covers framework entries, not arbitrary external programs that
never import the framework.

The audit also read the **actual 50 registered program sources**, rather than
stopping at `src/`. Twenty-six still contain 68 raw subprocess calls; seven of
those programs are enabled. `task_migration` now directly rewrites aliased
`Popen`, `run`, `check_output`, `call` and `check_call` calls into existing task
adapters. New migrations retain the original source archive identity correctly.
Existing registered programs are upgraded under their work-item execution owner,
with before/after bytes authenticated by existing task checkpoints. A prepared
record precedes fsynced replacement, and an interrupted replacement resumes from
either exact byte generation. `run-script` performs this direct source migration
before executing an old registered program; direct unmigrated/prepared entries
are rejected. Disabled programs stay disabled. No runtime compatibility loader
or additional public entry was added.

Two nonblocking attempts to acquire production work-item custody failed. The
final observation still found three real lease holders, with native PID/birth
observations retained in the receipt below. The 26 production files and their
source seals were consequently left unchanged. Their on-disk migration must
wait for normal exclusive ownership; restarting the other worker or editing
registry hashes to bypass this condition is not authorized by this acceptance.

Old sealed engines were another execution boundary. New seals declare the
process protocol, and `run_sealed` compares all eight transport implementation
file hashes against the current implementation after validating the actual
sealed inventory. Merely adding a protocol label cannot admit old code. Old
seals/checkpoints remain inspectable; incompatible interrupted continuations
are not silently replayed under another engine.

Validation and raw failure boundaries:

- **226 regression tests passed in 144.042 seconds**, including actual SIGKILL,
  last-consumer FD custody, source/configuration invalidation, real cc/make reuse,
  aliased child source migration, interruption after actual source replacement,
  and rejection of an old engine with a forged current protocol label. Raw log:
  `.cache/tasks/repair-9-12/processes/audit/runs/cd03f67896594f4b827dc5c73fe3a2c8/outputs/entry-final-acceptance/tests.log`.
  That combined controller later returned 1 during its separate lifecycle phase;
  it is not relabeled as a completely successful run.
- Earlier regressions exposed two stale fixture assumptions: `outputs/` now
  exists before target exec, and closing the task FD does not close inherited
  spawn custody. The fixture now uses idempotent mkdir and still requires actual
  custody/group absence. No wait budget was expanded. A focused 104-test check
  passed after the fixture and sealed-manifest contract updates.
- The combined lifecycle phase correctly refused a Grok resume with no retained
  session: its controlled provider had not emitted `init` before the one-second
  interruption. The fixture now emits its real initialization event before its
  framework/build work. It does not invent a session or rewrite a failed receipt.
- Final **real lifecycle recheck passed in 11.914 seconds**, with unchanged
  production source hashes throughout the recheck. It uses real controller
  processes and controlled local provider executables, not external models or
  mocked process creation. The existing workspace CLI starts, interrupts,
  reconciles and completes Codex execution; the existing Grok public API runs in
  separate controllers and resumes its actually observed session. Both share
  one fixture task and one incremental workspace. Its two C objects compile
  exactly once; recovery keeps the source inode, object timestamps, checkpoint
  input/observed identities and correct new generation/custody bindings.
- All **13 child records** in that final flow have real birth/protocol records.
  A still-open task is retained, a closed task inside the two-calendar-day window
  is retained, and an expired task with a genuinely open object file is retained
  by real `lsof` evidence. After closing that file, expired cache is removed,
  while durable task records, the interrupted outcome and Git survive collection.
  The supported collector clock is advanced to October 24; no production record
  timestamp or status is edited to simulate expiry.
- Successful and failed controlled Git fixtures are then drained through their
  own resume/finish checks, their small receipts archived, and the disposable
  checkout removed. This explicit test teardown follows the Git-preservation
  assertion; it is not a production Git cleanup. No controlled fixture Git
  checkout remains. Historical raw failure logs were moved from temporary tool
  capture into the existing audit output for ordinary retention.

Final real-flow receipt and source identities:
`.cache/tasks/repair-9-12/processes/audit/runs/e1d8e142ed0e4ab98ec9e9c53a13ff8c/outputs/entry-lifecycle-recheck/receipt.json`.
Its `provider-lifecycle/receipt.json` and `fixture-teardown.json` retain the
acceptance and teardown observations separately.

Registered-source inventory, actual lease holders, original logs and the explicit
production migration deferral:
`.cache/tasks/repair-9-12/processes/audit/runs/341836d345c4492c80f863f3f1cd779a/outputs/entry-audit-receipts/receipt.json`.
All 50 current program byte hashes still match their existing seals. The final
audit and validation roles returned normally; the evidence role's generation
`9d60c6b1f18e40539099e2296cd9835f` was not resumed or modified. These are framework
acceptance results, not full native/Gerbil build/test or repaired 9–12 admission.

### Registered run-script recovery and natural-release follow-up (2026-10-21)

The user authorized continued follow-up of the 26 existing program migrations,
waiting for natural lease release without interrupting 9–12. The latest normal
`execution_scope` attempt still could not obtain exclusive work-item custody;
no production program source, seal, enabled flag, or process state was changed.
The pending production migration is not complete.

The existing `tests/provider_lifecycle_acceptance.py` now also exposes
`accept_run_script` for actual registered-entry acceptance. This is an addition
to the existing acceptance fixture, not a new framework or production launcher.
It uses the real dispatcher to migrate an aliased Popen source, then executes
the registered key through `workspace run-script` with Codex and Grok provider
tags. It does not execute the old production sampling/debugger/native diagnostic
payloads or change their historical Evidence. An external Grok model is not used.

The real acceptance passed in **5.713 seconds**, with stable source hashes:

- One registered source is directly migrated; its original bytes remain bound
  to the original source identity, and the rewritten source has no raw process
  call. Enabled/disabled policy is not bypassed.
- The Codex controller is actually killed with SIGKILL after the registered
  program reaches its incremental checkpoint. The exact controller and surviving
  consumer kernel births are recorded. A real `workspace resume` attempt fails
  while that consumer still owns custody.
- A fixture release event lets the consumer exit naturally. No production
  process is signalled. Only then does the real resume entry reconcile the
  interrupted generation; it remains interrupted rather than being assigned a
  successful historical exit.
- Grok-tagged `run-script` starts a new generation with the same registered key,
  task, build path, source inode and object timestamps. The two C objects were
  compiled exactly once across cold, interrupted and recovered runs. All nine
  managed child records contain their real birth and spawn-protocol bindings.
- The fixture closes through the real completion checks, archives its retained
  receipts and removes its disposable Git checkout through the existing teardown.

Receipt, before/after source hashes, original CLI logs, interrupted generation,
birth records and recovered generation:
`.cache/tasks/repair-9-12/processes/audit/runs/f91d82c7b39d4ed6850dd32667dbeeb0/outputs/registered-run-script-acceptance/receipt.json`.
Its `lifecycle/receipt.json` and `lifecycle/fixture-teardown.json` retain the
flow and fixture cleanup independently. This is **pre-migration framework
qualification**; it does not close the 26 production migrations or replace the
required acceptance after those migrations.

A thread heartbeat, automation ID `smp`, is active at five-minute intervals.
It stays quiet while the lease is unchanged, waits for native custody to release
naturally, and then uses the existing migration/checkpoint mechanism under
normal exclusive ownership. It must verify every production source seal and
remaining process call, rerun this actual `run-script` acceptance after migration,
bind the results to the production migration receipt, update Current Work, and
pause itself on completion. It must not widen timeouts, enable disabled programs,
edit hashes to pass admission, signal the other worker, or claim native repair
acceptance. No new task, worktree, or compatibility loader was introduced.

### Production program migration completed after natural release (2026-10-21)

The previously deferred **26 production programs / 68 subprocess calls are now
directly migrated**. At the October 21 13:50 follow-up, the prior work-item
generation had returned, its supervisor and Grok target were absent in the
kernel, and no descriptor held the task lease. The normal `execution_scope`
then acquired exclusive custody in generation
`2df18cbfdc684eaba557cbc54feba4dc`. Earlier occupied observations and the race in
which a new Grok generation reacquired custody were respected; no holder was
stopped, signalled, sampled or debugged to obtain this window.

The existing `upgrade_process_calls` performed the actual source replacement.
Every before/after checkpoint was reopened and authenticated. For each of the
26 changed sources, the retained original hash matches the initial inventory,
the rewritten bytes exactly equal the direct migration of those original bytes,
and the new source bytes match their registered seal. All 50 registered sources
compile as Python; their paths and enabled flags are unchanged. The other 24
source hashes remain unchanged. There are zero pending call migrations or
prepared replacements. Disabled diagnostics were not executed or enabled.

Production migration receipt, complete verified inventory and checkpoint refs:
`.cache/tasks/repair-9-12/runs/2df18cbfdc684eaba557cbc54feba4dc/outputs/program-process-migration/receipt.json`.
The same output retains `before.json`; no registry hash was edited independently
of the real migration producer and source replacement.

**Post-migration actual registered-entry acceptance passed in 5.299 seconds.**
It reran `accept_run_script` through the real workspace CLI after the production
replacement, rather than reusing the pre-migration pass. Its receipt binds the
exact production migration receipt SHA-256, stable framework source hashes, and
all 50 production program seals before and after the acceptance:
`.cache/tasks/repair-9-12/processes/audit/runs/7b899bd7ec0e4497bb3f702eb1e07d0a/outputs/post-migration-run-script-acceptance/receipt.json`.

The controlled registered program exercised real aliased Popen migration and
Codex/Grok-tagged `run-script` invocations. Its controller was killed only after
the actual incremental checkpoint. A live last consumer prevented real resume;
the consumer then exited naturally before reconciliation succeeded. The old run
remains interrupted. Recovery starts a new generation with the same build path,
source inode and object timestamps. The two C objects compile exactly once over
cold, interrupted and recovered runs. All nine managed child records have real
kernel birth/protocol bindings. No model or native repair acceptance is inferred.
The fixture was finished, archived and removed by the existing teardown; its
Git checkout does not remain in Cache.

A secondary reference scan also examined the old disabled `profile-review`
program, which captures and wraps `subprocess.Popen` for profiling. That source
was outside the 26 direct-call migrations and remains disabled and byte-identical;
its profiling wrapper is not treated as launch authority. A captured raw Popen
alias outside the internal transport is rejected by the actual managed audit
hook. Five post-migration controls passed: captured alias/system denial, the
single audited raw framework boundary, missing-recorder rejection, real aliased
child execution after direct migration, and recovery after actual interrupted
source replacement. Their receipt is:
`.cache/tasks/repair-9-12/processes/audit/runs/813522e64f694512a391fad66d2cdaac/outputs/post-migration-alias-controls/receipt.json`.
This distinguishes an inert disabled profiling reference from an admitted
process-creation bypass; it does not claim arbitrary provider code is sandboxed.

Final checks found no unbound planned spawn in the audit or validation roles.
The 26-source production migration and its required post-migration framework
acceptance are complete. This does not establish native/Gerbil whole-build
success or close the other worker's 9–12 runtime repair. The app confirmed
automation `smp` was updated to `PAUSED` after this completion; the chat remains
available.

### SysML-owned repair investigation and discriminating evidence (2026-10-21)

The user designated `dev/organization.sysml` as the development entry and
repository `models/` as the unique executable-model owner serving repair through
12/12. This increment follows those owners: it extends the existing research
SysML and ResearchFunnel QNT/Lean sources rather than creating another framework,
gate catalogue or duplicate executable model. It does not change the other
worker's source repair, native acceptance inventory or milestone count. The
retained gate audit's historical 8/12 count and the current work on item 9 remain
distinct; no additional completed gate is awarded here.

`dev/research/models/sysml/architecture.sysml` now owns a typed mechanism
experiment and the numerical-compilation investigation association. The binding
names the gate definition, retained failure report, existing compiler-phase
implementation, competing hypotheses, distinguishing observation, source
refinement still required, acceptance boundary, and exact QNT/Lean symbols.
The development entry reaches this through its existing research responsibility.
`dev/research/index.org` explains the engineering loop, with its investigation
table generated from the actual OpenSysML API export. The existing
`dev/modeling/formal-bindings.json` records the same associations and source
hashes. Neither generated file is an independent authority or a satisfaction
certificate.

The current numerical example distinguishes generated-C representation cost,
configured driver/optimization, and observer/resource interference as competing
questions, not established causes. A meaningful experiment needs different
predictions and bound source, executable product, fixture, configuration and
generation identities. It must retain complete outcomes and the original phase
breakdown. A result outside both predictions invalidates that comparison;
missing output remains unknown. A class-count reduction is not an alias-universe
reduction, a measured compiler-work reduction or a completed native test.
Comparisons between changed configurations need their own correctly identified
cohorts, not relabeling as a same-configuration measurement.

The existing `models/library/ResearchFunnel.qnt` now supplies `distinguishes` and
executable controls for equal predictions, source/product/fixture/configuration
drift, stale generation, incomplete observations and an outcome outside the
predicted pair. Its Lean companion proves that equal predictions and stale
observations cannot discriminate, and that even a valid diagnostic
discrimination cannot advance native acceptance. The Lean identity tokens are
naturals; SysML/QNT integer tokens require a nonnegative projection for that
correspondence. No mechanized whole-language equivalence or native source
refinement is claimed. These token checks require the existing host Evidence
authentication; they do not authenticate receipts merely by equality.

The real development flow exposed and corrected a Python organization gap:
the storage policy did not recognize `dev/` as authored source, so managed view
generation failed before writing. `dev/` is now an explicit source owner, and
the existing view tool uses `task_processes.run` and current task output routing.
It can execute within the existing `repair-9-12` audit role without raw Popen
creation or another cache task. A focused real-scope test accepts the canonical
development model path and rejects an unrelated generated output root.

Final verification on stable current inputs:

- QNT test/type analysis executed the new positive and negative discrimination
  controls successfully. This is a directed finite check, not exhaustive TLC
  or a compiler performance result.
- The pinned Lean 4.34.1 compiler checked the full ResearchFunnel proof file.
  New equal-prediction/stale results use no axioms; diagnostic non-promotion uses
  `propext`. No `sorryAx` was admitted. Existing BootstrapCredit and StaleCredit
  controls both failed with the expected unsolved goals, preserving their
  negative meaning.
- Strict OpenSysML validation and real API export succeeded; the existing
  producer generated the views and a fresh check found zero drift. The merged
  current view reports 23 areas, four bindings, five dependencies and 41
  obligations. Concurrent child-discovery additions remain present and are not
  claimed as this increment's work.
- The canonical `dev/` storage test passed. All maintained SysML files, the
  shared view generator, changed QNT/Lean sources and storage policy were stable
  throughout the final verification.

Final receipt and raw checker/prover/producer logs:
`.cache/tasks/repair-9-12/processes/audit/runs/ffae3440c7dd4cfd95f04d4c174b426f/outputs/sysml-repair-concurrent-recheck/receipt.json`.
The first Lean record declaration error, the actual dev storage-policy refusal,
and a later run whose shared generator changed concurrently remain in their
original audit outputs (`6aa9f5bb515947cab77dea5dfc8d81f9`,
`d093eabff2714c0e9a8907e233e99c3b`, and
`8094123f7b174511ad98f0ed017f671a`). The unstable run's component passes are not
used as a stable final receipt. No source hash was manually repaired to conceal
drift. The next native mechanism experiment remains an owner-selected research
action; no numeric compilation, native repair, full Gerbil build/test, timeout
expansion or interruption of the other 9–12 worker occurred in this increment.

### Current repair is separate from Dev; real alias-pass discrimination (2026-10-21)

The user clarified that Dev and the current 9–12 repair are separate. The
concrete numerical investigation instance has therefore moved out of
`dev/research/models/sysml/architecture.sysml` into
`evidence/research/processor-interrupt-collective-wait/numeric-compilation-investigation.sysml`.
Dev retains reusable method vocabulary and organization only. Its current-case
table/bindings have no numerical instance; the real producer regenerated these
views rather than editing their hashes. The current case references the existing
`models/gambit/native_compiler_probe_correspondence.qnt` and its focused Lean
companion `models/gambit/lean/NumericCompilerExperiment.lean`.

The [current experiment dossier](../evidence/research/processor-interrupt-collective-wait/numeric-compilation-experiments.md)
binds actual compiler controls, source changes, raw outputs, model interpretation
and limitations. This is no longer only a workflow/admission exercise. The
earlier failed functionless dump probe was replaced by an authored observable
function under the existing retained GCC flag family. Three real small compiles
showed: functionless O1 exits zero with no dump; functionful O0 exits zero with
no dump; functionful O1 exits zero with both alias and ealias function/constraint
dumps. This corrects the prerequisite diagnosis: no dump in the old probe is not
evidence that GCC lacks these passes. It does not solve the original numerical
compilation cost or show a source-causal runtime improvement.

The existing compiler-cost implementation now executes this discrimination
through the managed process boundary, workspace lease, source delta and task
checkpoint. Each requested pass is checked independently against its actual dump
content; object creation alone cannot pass. The same audit incremental workspace
is reused with source/compiler/command/artifact verification; all later checks
reused the three original results without another compiler invocation. No
Gambit bootstrap, source clone or competing production build was started.

Final audit `5ae744f8573540b18b70d295578ebba9` retains
`outputs/current-numeric-discrimination-recheck/receipt.json`: source identities
stable, all observation/model checks accepted, seven QNT tests, three checked
Lean statements, strict current Evidence SysML validation, real development-view
derivation and five compiler-adapter tests passed. The QNT projection imports
the current model source, and the C fixture's immutable source bytes are retained
through the existing task checkpoint, not another Evidence source copy.

The experiment's incorrect descriptive checkpoint phase was rejected on reuse;
its repair used the existing checkpoint API only after verifying original owner
exit, actual process quiescence, source inputs and artifact hashes. Original
execution `3f9ace938c804aa29ee124268c93f059`, failed reuse and absolute-import
attempts, and recovery `e7ee880e702846bfb21ab19b6cf4511e` remain retained. No
failed result was rewritten to pass. The final flow's three GCC outcomes are
diagnostic capability evidence; the original numeric workload stayed unstarted,
its acceptance budget unchanged, and the other 9–12 worker was not interrupted.

### Original numeric IR: shared joins, configuration evidence and bounded attribution (2026-10-21)

The [current numerical dossier](../evidence/research/processor-interrupt-collective-wait/numeric-compilation-experiments.md#discrimination-2-the-full-original-cfgssa-rather-than-another-small-probe)
now analyzes the complete authenticated original CFG/SSA, beyond the small
alias-pass prerequisite. Audit `68927371a0074e1c948307a5ad04c257` retains
`outputs/current-numeric-original-discrimination/receipt.json`, its plans,
actual-observation QNT/Lean projections and raw validation logs. The qualified
three-way alias probe reused its existing checkpoint and incremental workspace;
there were no additional GCC compiles or production build directories.

The actual host has 16,639 PHIs, 223,240 operand occurrences and 51,927 distinct
incoming PHI edges, all supported by the earlier CFG. Two joins account for
183,280 operands (82.10%): external `___jumpext` state writeback/tail call has
eight PHIs sharing 15,539 predecessors, and the computed-goto dispatcher has
eight sharing 7,371 predecessors. The source map reaches the original SSA
blocks and authenticated header's `___END_COD`, `___W_ALL`, `___EXIT_HOST`,
jump and single/multiple-host selection macros. This supports a concrete
representation/configuration investigation, not a measured points-to explosion
or an established compiler speed cause.

The existing analysis implementation was repaired to parse abnormal `(ab)` SSA
annotations, classify the real register families, validate predecessor syntax
and support, and exclude predictor comments from indirect-goto counts. The old
report's generic `other` classification, 30,462 indirect-goto count and false
"21.936 below 10" comparison are explicitly superseded without rewriting its
historical bytes. Current QNT/Lean distinguish shared-edge multiplicity from
alias-set or time units. Eight QNT tests, five Lean statements and two
actual-row examples, strict current Evidence SysML validation and six focused
Python tests passed with stable source hashes and immutable task-source
checkpoints. This is an analysis-source repair; native source correctness and
full build acceptance are not inferred from it.

The retained no-PTA failure already answers part of the configuration question:
at 36.296 seconds its stack was in dominator/range propagation, and at 51.412
seconds it reached RTL combine/register work. It still timed out at 60.033
seconds with no module. This route was not rerun. Those observations reject
"disabling PTA completes the fix" and do not measure the PTA-enabled solver's
cost. The original graph compile's exit remains unknown after its historical
cancellation failure; successful parsing cannot recover it.

The exact 5,541,691-byte generated numeric test C (SHA256
`35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158`)
is absent, and the targeted task source-checkpoint lookup found no matching
entry. Existing `lib/_num.c` modules differ and were rejected as substitutes.
The dossier records concrete next controls: authenticate/restore the exact
producer input, obtain actual alias/ealias constraints using the qualified
probe syntax, then change only single/multiple-host configuration and compare
per-function joins against independent alias membership counts. Outcomes and
existing deadlines remain binding; no unchanged failed route was restarted.
No other 9–12 worker was interrupted. Original numeric source repair, runtime
recovery and complete native/Gerbil build/test acceptance remain open.

### Exact numeric C recovered; real host controls retain open alias gate (2026-10-21)

The [current numerical dossier](../evidence/research/processor-interrupt-collective-wait/numeric-compilation-experiments.md#original-c-recovered-bounded-full-input-controls-2026-10-21)
now closes the missing-source prerequisite. The retired original receipt binds
the exact Scheme fixture; its retained `gsc` and includes rebuilt only the
Scheme-to-C stage with original `_test` module and `_test.o1` linker names.
The result is **5,541,691 bytes, SHA256
`35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158`**.
The new canonical C is in the audit's stable registered `gambit-core` product
`923af547b5e2526673b48db269fec79a3350697b5e634e15ad5244123a9df520`,
under `source/tests/unit-tests/03-number/_num.c`. It is retained in audit
`0624078d62b543749acd9a13b61ae093`'s existing source checkpoint, prefix identity
`3ca3631c7d7db1ebf0ce0fd9811924fba3dc47e281fdf438935a7a1a494e4a32`.
Future recovery authenticates/reuses that checkpoint rather than substituting
`lib/_num.c`, recreating a legacy cache directory or bootstrapping Gambit.

The first reconstruction timed out at 60 seconds with a partial C. The actual
I/O configuration exposed an additional engineering cost: `io-settings=lu`
unbuffers file ports as well as the console. Changing only file ports to
`file-settings=lf` retained the same 60-second cap and generator, completed in
36.534 seconds and matched the original SHA exactly. The failed partial source,
logs and exit evidence remain retained. This verified buffered-file policy is
now the reconstruction adapter's default, while console settings and processor
selection are preserved. This is a source-recovery/configuration correction,
not a native numeric correctness or CPU-speed claim.

Three real full-input GCC controls then ran sequentially on that one source
workspace: single host, multiple hosts, and single host with shared rather
than inline jumps. All retained exit -9 / 60-second timeouts and no module.
No alias/ealias artifact was produced. The single/multiple argv pair differs
only in the host macro; the shared-jump pair differs only in the inline-jump
macro. Actual receipts are audits `854aa59b137f4977b6d0f5a898e114be`,
`d7cc23e2483f44b9a7f1996eef2e4776`, and
`c36dcee8eb8c47fd8bc1853044ea3f41`. They are not repeatedly executed after
failure; later checks reuse the receipts and verify the original artifact
bytes. No timeout, source expectation, hash or historical failure was changed.

Multiple-host CFG output contains 38 function sections, but its dominant
`___H___test_23_` still has 101,223 observed blocks, 155,452 observed edges and
fanout 7,613. Generic host splitting therefore leaves the large main test
procedure. The incomplete SSA is not accepted as a full correspondence, and
the shared-jump run produced no retained IR for a representation conclusion.
Absence of alias/ealias output is **unknown**, never an empty points-to set or
proof that alias work did not execute. Current QNT/Lean and the actual-dump
parser preserve this distinction and reject wrong-source recovery. The
verified small-probe dumps calibrate parsing only; they do not close the
original workload's alias or native gate. All native compiler children were
reaped and their groups absent; the other worker's 9–12 execution was untouched.
Original alias solutions, a causal runtime/source repair and full native /
Gerbil build/test acceptance remain open.


Validation and checkpoint closeout: audit ead4e017f9c44522b35529f4419b851e retains outputs/original-numeric-recovery-validation/receipt.json. Nine QNT tests, seven Lean statements, two observed-data Lean examples, strict current SysML validation and nine Python tests passed with stable source identities. Successful Lean logs contain no sorryAx. Initial Lean keyword/projection failures remain in audits 5183be855c0d4940962b2adf4575612b and 7a5af56eb9eb496aa4cc7e55fc3dcdeb; they are not rewritten. All compiler receipts were authenticated and reused during validation.

Audit 6676f6d5168f45b08403cd6b03ffaec8 additionally tested actual source-checkpoint rehydration under the existing workspace lease: it removed only the owned audit generated C after authenticating the retained bytes, observed the file missing, then used recover_original_numeric to restore the original 5,541,691 bytes and exact SHA through the normal checkpoint API. This controlled audit-cache loss test is not a production interruption or a native runtime recovery. Its outputs/original-numeric-checkpoint-closeout/restoration.json records both real observations. No generator or compiler rebuild was required.

### Numeric main-host refinement executed; representation and alias costs separated (2026-10-21)

The 101,223-block multiple-host main is now connected to an executed source
refinement, rather than another admission rule. Work reused the same audit
product `923af547b5e2526673b48db269fec79a3350697b5e634e15ad5244123a9df520`,
the retained generator and original source checkpoint. Original numeric C SHA
`35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158`,
all original Scheme/include inputs and the header remain unchanged. Candidate
C has a separate checkpoint identity; no historical source or failure receipt
was overwritten. The peer 9–12 worker was not interrupted or observed with a
debugger/sampler. Samples below target only kernel-birth-verified direct cc1
children of this audit's own compiler groups.

The generating chain explains why multiple hosts alone did not fix the main.
The assertion expansion in `tests/unit-tests/#.scm` is amplified by binding
checks/specialization in `gsc/_ptree2.scm`; the C target emits hosts per GVM
procedure, not per arbitrary local lambda. The original main contains 2,020
static `##eqv?` global call sites. Disabling only harness-comparator primitive
inlining halves that count to 1,010 and reduces main C body lines to 64,612,
but the new phase-isolated control still times out at 60 seconds. Its own cc1
samples show C parsing at 15 seconds and gimplification at 40 seconds, before
any retained alias solution. Thus an alias-only diagnosis is unsupported.
The separate original preprocessing control also reaches its 20-second cap;
that partial result is retained and is not retried.

The implemented driver `models/gambit/native/numeric-alias/outline-assertions.scm`
uses the real Gambit source reader and creates true private global procedure
groups, each with at most 32 contiguous eligible assertions. Definitions,
exception tests and all other forms remain barriers. It preserves original
source objects once and in order, with original include/source locations.
An independent plain Scheme reader confirms all 1,592 top-level forms and the
79-group partition; all 146 top-level exception-tail tests stay outside groups.
Arithmetic expressions, expected values and runtime roots/writeback are not
edited. A local no-inline prototype had increased the main to 119,029 generated
body lines because it did not introduce global host boundaries; that negative
experiment and the rejected uninterned-name generation are retained.

The global candidate emits 112 C procedures. Main CFG drops to 7,943 blocks /
12,543 edges / maximum fanout 789; the largest other groups have 3,522 blocks.
Detailed instrumentation now exposes 32 closed per-function ealias solutions,
with maximum observed named points-to set size four. This is a partial
translation-unit observation: later alias output is absent and the remaining
functions are unknown. Named summary targets, equivalence classes, solver
node IDs and concrete runtime locations remain distinct quantities.

Detailed IR output still times out at 60 seconds; its owned stacks are dominated
by tree dumping and fflush. A discriminating control reuses the **identical
25,363,697-byte preprocessed input** (SHA
`0db8fea9aa38b2b7b393bc5ece3279922edf0b9d34e82d750aaf6a966ecdc47a`),
retains O1 and all optimization settings, and removes only full-tree dump flags.
It compiles successfully within the same cap: 53.259 seconds observed driver
wall time. GCC's internal wall report totals 45.05 seconds: parsing 10.99,
optimization/generation 34.02, tree PTA 1.06, alias analysis 0.33 and SSA rewrite
0.14 seconds. Parent/detail rows must not be summed. GGC's 1,915M is cumulative
allocation, not peak RSS. Sampling and different candidate inputs preclude a
clean speedup claim or attribution of the unresolved original workload's cost.

The resulting module SHA is
`ec941bbca0c46338d282e7af8c15b4cb3e10ad69f2b03779250666b99b46b7e6`.
An initial load used the wrong explicit linker name and exited 70 before any
assertion ran. The adapter now uses the actual generated `_test.o1` linker;
the unchanged module was reused and loaded successfully, exit 0 in 2.776 seconds
with the unique original-assertions witness. The complete unchanged interpreted
numeric reference also passed, exit 0 in 3.204 seconds. No recompilation or
expected-result relaxation was needed for the loader correction.

Primary retained audit runs: comparator phase `193cdcef8cde4a1da10cd8937a7cbe1c`,
global-group detailed phase `d050d061cb084120b04bfdd953fa4f60`, low-output compile
`c57e6e05bcb145d88fe2b4bbaf09dd4e`, corrected real execution
`d9a2672a74f64165990ec4e44cea9f87`. Their managed outputs and the product's
source-keyed experiment directories contain raw logs, argv, compiler identities,
PID/birth records, source checkpoints and unmodified failed outcomes. This is
an audit-owned source refinement with real full-numeric-module execution;
it has not been installed into the peer's active production recipe and does
not close full native, GC/FFI, lifecycle, Gerbil build/test or release gates.

Current SysML binds the executed refinement to QNT `orderedFormPartition` and
Lean `partitionPreservesFormMembership`. These cover ordered form identities;
they do not assert general continuation/contextual equivalence. Actual native
and interpreted execution supply independent workload evidence. The detailed
case and source-chain references are in `numeric-compilation-experiments.md`.

Validation closeout: audit `4ab13782241e4416959bee5bdfa71aee`,
`outputs/numeric-global-group-validation/receipt.json`, authenticates/reuses
the actual compiler artifacts and corrected execution receipt without another
native compile. QNT source tests and the exact 1,592-form/32-solution observed
projection pass; the source and observed Lean files compile with pinned
Lean 4.34.1 and no sorryAx; strict current SysML plus imported dev models and
all 13 focused Python tests pass. Source identities match before/after.
The first literal-heavy observed QNT projection timed out at 45 seconds in
audit `011d854042364748877a8a165f87e45d`; an exact contiguous-range encoding
of the same verified indices passes under that unchanged cap. This changes
model input representation, not workload values or expected results. A
sandbox boot-identity read failure before spawn was reconciled with the normal
audit process-resume API, without hand-editing state. Failed observations remain
retained; no model success is substituted for native execution.

### Numeric grouping activated in existing Recipe consumers (2026-10-21)

The task lease was observed without an active descriptor and the normal
workspace execution scope then obtained exclusive custody. Integration run
`25aaff561463438a820921b0fc699db6` checkpoints the previous sources and binds
the verified grouping driver into the existing numeric-host observation,
GC/FFI inventory and complete compiled-suite Recipes. No active peer process
was interrupted, signaled, restarted, sampled or debugged. Subsequent brief
lease contention was respected; the next run acquired custody after natural
release. The Recipe change is explicit source/fixture identity data, not an
implicit override or compatibility launcher.

Both actual adapters now use that declaration: compiler observation and the
selected numeric file inside `run_suite_phases`. All other files retain their
original route. The driver SHA, exact original numeric fixture, private-name
absence in included helpers, generated manifest order, 1,592 forms, 79 groups
and maximum group size 32 are checked. The original C compiler invocation and
GSI CLI loader remain in place. Only generation file buffering follows the
already-verified policy. Recipe inputs include the real maintained driver;
historical receipts and sealed engines were not edited.

Regression run `28257a7f450940c19e8afc59ea4912c6` passed 39 tests across
compiler cost, compiled suite phases, compiler archive and numeric phase
Evidence. These include negative source/fixture/declaration controls and
actual Recipe-load checks. The existing production phase cap is 90 seconds;
it was not changed to accommodate this candidate. The earlier diagnostic
60-second cap is a separate observation regime and remains unchanged.

Actual sealed execution run `035fba9be3054511ac834e0d6cd3e392` uses engine
`e77ec09889d2f48dba37a8df5e860fc8bb61f4d7a71c611e0821a82e2e78106d`.
Its `outputs/numeric-recipe-native/acceptance/run/numeric/step-receipt.json`
records genuine Recipe execution: Scheme-to-C exit 0 in 15.242 seconds,
C-to-module exit 0 in 58.028 seconds, original GSI loader exit 0 in 1.712
seconds. Actual compiler stdout confirms O1 and the Recipe's configured
SINGLE_HOST, without detailed tree dumps or altered optimization flags. C SHA
`eae8ae9dddb62e1f8740e052f1341662e9e069a5d9769c2bf3c848f16f283e8d`
and module SHA
`26cb473cebc67c4424dd83a1581db2b6affb0555a863abc59c74a7d60d20cc55`
belong to this actual producer/configuration, separately from the earlier
multiple-host audit candidate. Official test7/test8/test9 also pass. The
retained completed source-core was reused in the existing managed build
product; no Gambit bootstrap was repeated.

The first seal attempt refused a currently installed ASCENT package that
differed from the old engine's packaged source inventory. A new seal uses the
current package's verified source inventory, rather than modifying either
package identity or old engine. Full native and Gerbil build/test acceptance
remain pending until their actual final receipts are available; numeric and
official GC/FFI success alone do not establish those gates.

Review identity follow-through: a grouped GSC campaign now authenticates and
includes its real grouping producer, instead of identifying the transformed
compiler input only by unchanged Scheme bytes. This does not fabricate a
retry authorization: an older review for another producer remains distinct.
Audit `5b1236ed37fa4021ba367adfd636c126` passes all 87 relevant tests and
seals the final adapters as engine
`f9c2f333978b4f427ed3645a0ea51e28e893b92bcba0f71820a87f51c6f06309`.
The prior broader regression retained one real timeout-control failure:
Make returned 2 rather than the test's assumed -9. The test now requires the
actual recorded nonzero parent exit, real timeout and quiescent teardown,
instead of inventing a deterministic signal result. Its 0.1-second window
was not increased; no production timeout/exit logic changed.

The auxiliary inventory's interpreted `tfib_stress` lane was an unnecessary
addition to the formal native plan: the source-bound upstream `st` contract
uses GSC. After 1,330.853 seconds, only this chat's kernel-birth-verified
runner group was explicitly canceled with SIGTERM (audit
`1aadbea024af4089aead6bf15f39dbc5`). Its real parent exit is 70, timeout false,
parent reaped and group quiescent. The inventory aggregate remains DENY and
subsequent inventory lanes remain BLOCKED; none is relabeled PASS. Numeric
and official successful stage receipts remain independently retained. This
cancellation does not involve the peer 9–12 worker.

Audit `058c4cacfa2f4e14b54bab312b7812e9` checkpoints the actual production
generated C and manifest through the existing source-identity API. It verifies
that the production manifest is byte-identical to the previously verified
QNT/Lean observed projection, authenticates the actual phase C hash, and
checks all 24 own child tokens quiescent. No C or patch copy is added to
Evidence. The next acceptance uses the existing `qualified-native.recipe.json`
and `qualified-gerbil.recipe.json`, including their formal complete Make and
Gerbil test selections. A new peer task lease was actually observed occupied;
formal acceptance waits for natural release rather than stealing custody.

Formal native attempt `0993bf800456484db3ee5f101cfd636a` then acquired normal
custody and executed `qualified-native.recipe.json`. The runtime import,
environment probe and typed review pass. Official Make check is **not PASS**:
`06-thread/issue_216.scm` exits 70 after t2 ended before its second interrupt
(`Thread is not active`, original line 37), and
`06-thread/mutex_race_timeout.scm` records HI=0/LO=11 (real SIGSEGV).
The unchanged official stage budget leaves 238.195 seconds for the Make child;
it times out after 238.228 seconds with exit -9 and its process group quiescent.
The incomplete prim_port interval had observed 11.104 seconds of its declared
20-second window when the whole deadline expired; this is not evidence that
its own 20-second deadline was exceeded. Unit/stress successors remain BLOCKED.
The raw log is under
`outputs/numeric-formal-native-gerbil/native/run/official/upstream-tests.stdout`.
This producer's gsi SHA is
`1e0e62b017d612a462dec42b5a5514f112cc801f581ccfce4dc8f318ab47856d`.
No mutex fixture, iteration count, processor configuration, runtime memory or
expected result was changed. The unchanged failed native route is not rerun;
these failures remain separate from the successful numeric source refinement.

Gerbil's first fresh entry was correctly refused by the durable-attempt guard.
The exact prior is audit `28f6666866f943de94ec14f8a999eaa9`,
`outputs/acceptance/native-gerbil-qualification/gerbil-full`, whose old adapter
SHA `4ab614e904239780c04bf16e057de75d57b353e5b070ed4f09bc8694827f8159`
has no per-module stage0 checkpoint support. The current adapter SHA
`3190555700d38c31a8ba79df39628f66378916c73d46720ac729a189bcc509e4`
does; this is a real adapter delta and the original 600-second stage limits
remain unchanged. Audit `d6c2b7ce84864cf08ab72a5148d9dc0f` supplies that exact
prior through the normal API and preserves its prefix identity. It then fails
before compilation because completed-runtime import applies per-role output
routing to the same work item's task-owned build product. No duplicate Gerbil
workspace was created to evade this refusal. The prepared narrow repair will
authenticate registered same-work-item build references while retaining the
existing exclusive workspace lease and ordinary output boundaries. Activation
waits for the actual live Grok task lease to release naturally.

The remaining maintained default/original-loader numeric declarations were
also audited and given the same explicit grouping binding:
`ci/bazel-profile-numeric.recipe.json`, `ci/gc-ffi-numeric.recipe.json` and
`ci/three-flag-numeric-inventory.recipe.json` (under `evidence/research/`).
Together with the initial two CI consumers and complete compiled-suite
consumer, all six declarations are checked by the data-driven regression.
Audit `911d030d4baf4449b9c390d6133ebe02` passes the final 11 compiled-phase
tests with stable source identities, including loading all six actual Recipe
graphs. This declaration coverage is not six independent native executions.

The cross-role producer-reference change is **prepared, not activated** in
`.cache/tasks/repair-9-12/processes/audit/runs/acce7a5c21ee4352a69f5b83e4378891/outputs/shared-producer-reference-proposal/proposal.json`.
It carries exact before/after source-identity checkpoint references for the
existing workspace/runtime-artifact modules and a real two-object cross-role
no-recompile regression. Proposed sources pass syntax compilation only; the
new regression and live Gerbil continuation must run after activation. No
framework source was changed while the peer Grok lease remained held. A
bounded normal-custody waiter exited on continued contention without taking
ownership or starting native work. The existing SMP follow-up now checks for
natural release every five minutes, stays quiet on unchanged state, refuses
source drift, and then continues this exact proposal/tests/prior. It never
repeats the unchanged native SIGSEGV route or treats a model/fixture result
as complete native or Gerbil acceptance.

Closeout audit `a1c369d3594b4916b031f7295140981b` checks quiescence for five
completed own runs, records the peer's live kernel births without touching it,
and retains the proposal JSON itself through the existing source checkpoint.
The fallback source reference below preserves the proposal beyond a loose
Cache filename; it conveys no activation or native admission:

```json
{"kind":"task-checkpoint","run":".cache/tasks/repair-9-12/processes/audit/runs/a1c369d3594b4916b031f7295140981b/outputs/source-identities/d70b9e3b7f96aab09d11513d2a316a92b2efbbc8cfd40c7467d7d1af59446a9e","identity":"2bf672f97dbce6d5420460357484917f6d08860ff003d5716aaa6ea8fdc6f0b4","sha256":"d70b9e3b7f96aab09d11513d2a316a92b2efbbc8cfd40c7467d7d1af59446a9e"}
```

### Shared producer references and real Gerbil module CLI repair (2026-10-22)

The peer lease released naturally. Actual lock descriptors and kernel PID/birth
records were checked before normal workspace resume, with no peer signal,
restart, sampler, debugger, lock deletion or state rewrite. The exact prepared
proposal was activated under exclusive task custody. Own audit
e2b3a5dfafce40119d8c759713594f36 interrupted after source writes because its
receipt path was outside managed outputs; the negative attempt remains and
normal resume reconciled it. Audit fae89ed90cec4956bba55364ae52eee7 subsequently
verified exact after bytes and passed 97 tests in 60.128 seconds within the
unchanged 300-second cap. The real fixtures include Codex creating two objects,
a Grok-provider Make command under audit reusing the same inode with zero
recompiles, source/configuration invalidation, controller interruption, active
consumer refusal and natural-exit recovery. These are compiler/process fixtures,
not a Grok API run or native admission. Canonical registered same-work-item
references retain original exclusive workspace leases, complete producer byte
checks and strict ordinary task_output boundaries.

Gerbil entry d02fc4f901fb496d8e7351ee6d76d921 was refused before compilation
because its original prior had a newer durable continuation. The immediate
prior d6c2b7ce84864cf08ab72a5148d9dc0f was authenticated to the original
28f6666866f943de94ec14f8a999eaa9 checkpoint; latest prefix
95ce156590421ea2e4adf11ee628dc1a3e2f34b51d868432952d47c7bbc1a2f5.
This follows existing durable lineage rather than bypassing duplicate-producer
checks. Audit 0881e2ad7e814e49ba162454fa1e492f then passes candidate and
runtime-import using the original task-owned c86dff86 Gambit build with no
runtime compiler command. It retains the original audit f876daf8 Gerbil workspace.

That actual run exposes a per-module adapter bug: -o OUTPUT follows -e EXPR.
Pinned Gambit gsi/main.scm stops parsing compiler options at the expression/file
argument boundary, warns that -o is misplaced, and reads the missing .o1 as
input. The first base.scm module exits 1 without timeout; tests remain BLOCKED.
Its negative receipt and raw logs are preserved. The adapter moves -o OUTPUT
before -e EXPR without changing module semantics, include, compiler or build
configuration. The C transport fixture now rejects the old invalid order.

Audit 0f33d153d54a4fbfbc5f2140094a571a retains before/after sources through
existing source_identity checkpoints and passes 102 tests in 106.923 seconds
within the same 300-second cap, including real module interruption/resumption.
Corrected arguments also execute with real completed GSC SHA
4134b78c53c1a593632eeb683fbffc24b645f472e7ca47f26b1073ea80aff88f.
A Scheme control creates a real .o1 in 1.610 seconds, exit 0, no warning and
no timeout under its 30-second cap; output SHA
1d13ef2ccc5519408390725a454d67867c2cbce79913ef797a2ee1d66702dc14.
This is a compiler CLI control, not full Gerbil acceptance. Fresh engine
9690e656a3475c5e0f9ca0cda6457a10d0acdcb9113d9bf3040bf63d77939a5e
uses the currently installed ASCENT source inventory.

The corrected production continuation is .cache/tasks/repair-9-12/processes/audit/runs/c6db583c97da4f8492bb97de00424b64/outputs/gerbil-option-order-continuation/acceptance,
with immediate prior 0881e2ad7e814e49ba162454fa1e492f, the same workspace and
original 600-second Gerbil stage limits. Actual aggregate: **DENY**.
Actual step outcomes: {"candidate": {"commands": 3, "outcome": "PASS", "reason": null}, "gerbil": {"commands": 78, "outcome": "TIMEOUT", "reason": "gerbil-stage0-module-17671f05bd5a0724 timed out"}, "runtime": {"commands": 0, "outcome": "PASS", "reason": null}, "tests": {"commands": 0, "outcome": "BLOCKED", "reason": null}, "verdict": {"commands": 0, "outcome": "DENY", "reason": "native ASCENT relation outcomes differ from the declared exact inventory"}}.
Completed module records at closeout: 72.
The adjacent closeout.json binds current source identities, workspace, actual
results and own-run quiescence.

The existing 1592-form/79-group manifest and QNT/Lean projection remain the
numeric source-refinement evidence; this framework/CLI repair changes no
numeric expressions or runtime repair model. Full native acceptance remains
open at issue_216 and the real mutex_race_timeout SIGSEGV from
0993bf800456484db3ee5f101cfd636a. That unchanged failed producer is not rerun.
No processor setting, fixture, expectation or timeout was weakened. Its formal
Recipe requires an authenticated source-causal new completed native producer.
Fixture/compiler-control passes do not close the native gate.

The final timeout is a cumulative build-stage boundary, not evidence that
core/module-sugar~1.scm intrinsically requires 600 seconds. It starts with only
6.285827833 seconds remaining, runs 6.310236875 seconds, and exits -9 with
timeout=true, parentReaped=true and processGroupQuiescent=true. The preceding
72 modules have genuine completed process/output witnesses; the interrupted
73rd module is not certified. The aggregate outer process does not time out
(timeout=false), but Gerbil's build step is TIMEOUT and tests are BLOCKED.
The original 600-second cumulative stage budget is unchanged. No unchanged
failed-route replay or fresh build namespace is used to replenish it. Further
work must distinguish actual module cost from remaining stage capacity and
authenticate any causal repair/recovery path rather than merely resealing an
unrelated engine or resetting the budget.

A final audit-role attempt to reconcile the parent task spawn journal was
correctly denied by StoragePolicyError (process cannot write another work-item
execution area). Its interruption is preserved and normally reconciled. The
parent was then checked through workspace.resume under its own exclusive task
custody; only role-owned observations were checked inside the audit scope.
This preserves the ordinary ownership boundary.

Final own-run audit: .cache/tasks/repair-9-12/processes/audit/runs/8b97571b9a65427c8b9459e57b18f51d/outputs/shared-producer-final-audit/receipt.json.
It checks completed own audit-process births/teardown, references the parent
normal-resume observation, and verifies source bytes still match the sealed
closeout. Full native and full Gerbil acceptance remain open; no own native
spawn is left unresolved by this closeout. The existing follow-up has been
updated to the latest checkpoint and refuses unchanged failed-route replay.

### Gerbil cumulative-budget cost and completion-witness audit (2026-10-22)

Read-only process/descriptor checks found no live task consumer before this
registered audit scope. No production compile, failed-route replay, timeout
change, parallelism/configuration change or new engine seal was performed.
The original c6db583c97da4f8492bb97de00424b64 command records distinguish
actual child time from intervals between commands: 599.635209 seconds from first child start to last child exit,
580.055525 seconds in recorded child commands,
576.397954 seconds in 73 GSC module commands (including the
interrupted last command), and 19.550233 seconds in command
intervals. Median interval is 0.039266 seconds.
These timestamps reject dominant checkpoint/publication overhead as the
explanation for this run. GSC command time is not a measurement of GCC alone: the
retained logs do not separate Scheme generation, CFG/SSA, alias/ealias and C/link
work, so no alias hotspot is inferred from it. The ten longest module records
are retained in the receipt; core/contract~10.scm takes 69.439 seconds,
core/match~1.scm 47.649 seconds and core/contract~9.scm 47.009 seconds.

All 72 completed module proofs were rechecked against their immutable journal
witnesses, current source/configuration identity, output bytes and modes using
the existing recovery predicate. All authenticate. The interrupted
core/module-sugar~1.scm has an .o1 file on disk but no completed witness; the
existing predicate refuses it. Binary presence does not repair the failed
process receipt. Its observed Scheme/C bytes are retained through existing
source_identity checkpoint references for forensics; the surviving C bytes are
not asserted to be a certified product of the interrupted attempt. No Evidence
source/patch copy or synthetic completion was created.

Cost/proof receipt: .cache/tasks/repair-9-12/processes/audit/runs/6ad1d754141f40098e9e3da08243a1e1/outputs/gerbil-cumulative-cost-audit/receipt.json.
The remaining engineering gate is a source-causal cost/recovery plan that
preserves the original budget and validates remaining work. Replaying the same
module queue with replenished cumulative time or an unrelated engine identity
is not admitted. Full native and Gerbil gates remain open.


### Repository publication of the twelve-gate and pre-exit research (2026-10-22)

The [repository research index](smp-retirement-research-index.md) now publishes the exact previously audit-only documents and QNT sources: the full twelve-gate matrix, eighteen-class last-consumer correspondence, pinned Chez/OCaml trade-off, and pre-exit join/callback/root frontier. Raw receipts remain under their original audit paths; source/model hashes are preserved in the index. Cumulative acceptance remains 8/12. The current-normal QNT timeout and the earlier two model timeouts are retained; no model result is a native repair or source-refinement claim. Preparation-phase nested GC, abort and root-coverage checks are still in progress. No runtime/framework source, Recipe, budget, seal or native build is changed by this documentation publication.


### Shrink preparation, nested GC and callback abort study (2026-10-22)

The [preparation-phase design](smp-retirement-prepare-phase.md) specifies proposed function/field changes: consume the parent resize election before GC-capable callbacks, keep ready old members servicing GC, catch supported callback errors and complete an old-cohort abort handshake, and retain scanner-visible source roots until registered receiver coverage. Callback effects cannot generally be reversed; failed callbacks are not replayed. The same-model normal-path diagnostic keeps the original combined 30-second cap and historical timeout. Actual formal outcomes are in the linked result table; these are finite design controls, not a C refinement theorem or runtime repair. Acceptance remains 8/12; runtime/framework source, Recipes, budgets and the implementation worker are unchanged.


### Preparation source refinement and multi-donor abort boundary (2026-10-22)

Commit `2211f9d400b65ecfeeb4b154004b8b43da0a36b1` checkpoints all user-authorized accumulated SMP changes; no push occurred. The [source-refinement follow-up](smp-retirement-prepare-refinement.md) distinguishes invocation-local operation offers from conditional parent-replay model assumptions, identifies the outer SFUN catcher as final propagation rather than a collective abort, maps RC allocation/registration/current-value reload/final release, and requires a global success cut before donor root withdrawal. Single-donor QNT does not prove multi-donor failure after another donor is Ready, repeated GC or uncalled queue-suffix disposition; those obligations remain explicit. This follow-up changes documentation only; no new QNT/native execution or runtime repair is claimed. Native acceptance remains 8/12.


### Two-donor repeated-GC preparation and abort controls (2026-10-22)

The [new study](smp-retirement-multi-donor.md) publishes retirement_multi_donor.qnt and multi-donor-validation.json. Existing bounded verifier results: abort 62 states and success 53 states pass safety plus conditional completion; seven mutations each produce a decoded distinguishing counterexample; explicit A-Ready/B-failure/second-GC/common-abort/result-root-release trajectory passes. A prior parser failure is retained. All old members continue service until global preparation closure and common completion; abort keeps cohort=3 and registered donor sources, and error roots outlive their last result consumer. Receiver handoff on success is an abstract obligation, not an existing live-donor C transfer guarantee. No runtime/framework edits or native execution; source identities stable, no operation sent to the implementation worker, native acceptance remains 8/12.


### Gate-9 queue, repeated-epoch and typed-root refinement (2026-10-22)

The [implementation contract](smp-retirement-implementation-contract.md) maps C1 local callback completion, C2 global preparation closure and C3 common completion into setup.c/header/mem.c. Preferred minimum is pop one native request under the existing queue mutex, invoke release(false) unlocked under a local catcher, and retain the never-invoked suffix in the old queue; unsafe aliasing/invalid suffixes prevent normal resume. Ordinary service error handling has a source-visible conditional unlock imbalance, not an established native crash cause. New retirement_epoch_queue_roots.qnt checks two complete epochs (38 states) and opaque invalid-suffix containment (18 states), plus ten decoded mutation controls and two named trajectories; all fifteen checks accepted within original 30-second caps. Actual RC-data/frame/will semantics, exact epoch/reset identity and last result consumers are mapped; full native root census/C refinement remain open. Four necessary edit surfaces are specified, without claiming sufficiency or upgrading 8/12. Runtime/framework source, Recipes, budgets and the implementation worker were not changed or operated.


### Single-model retirement composition and function-level handoff (2026-10-22)

The [integrated plan](smp-retirement-integrated-plan.md) publishes retirement_integrated.qnt and integrated-validation.json. In one transition system, two donors, two GCs per epoch and two actual epochs combine with native queue suffix disposition, moving representative strong/frame/RC roots, weak will semantics, exact message identity and result-root lifetime. Three positive campaigns pass: abort twice (144 states), abort then commit (145), opaque invalid-suffix containment (71). Seventeen mutations produce decoded distinguishing states, and two explicit combined trajectories pass; all 23 checks accepted under original 30-second per-check caps. An earlier complete integrated run is retained; final model makes successful will receiver ownership explicit and rejects missing typed handoff. The four function-level edit surfaces and sufficiency blockers are documented; shrink thunk def-use may remove an unnecessary carrier, but movable result return still needs actual caller-root ownership. Y successful cancellation is a finite nonallocating/no-reentry abstraction, not proof that arbitrary Y callbacks cannot fail/collect. No runtime/framework code, Recipe, seal or budget changes; no native execution or implementation-worker operation. Acceptance remains 8/12.


### Actual C work/GC-tail closure and caller result-root coverage (2026-10-22)

The [C handoff audit](smp-retirement-c-handoff.md) follows _thread Scheme callers -> _kernel.scm c-lambda -> generated CFUN -> ___current_vm_resize/dispatcher -> result arg/local -> PSR1/r[1]. Existing encoded errors are immediate; inspected normal Scheme return has a cooperative no-GC bridge into a scanned caller register, so a new generic caller-root API is not mandatory. Cross-GC callback detail, raw C retention and catcher-only metadata remain separate rooting obligations. The unified successor retirement_c_handoff.qnt explicitly models late GC work, dequeue versus scanner return, all-member epilogues, separate still/RC/frame/will handoff, current-value reload, caller installation and post-installation relocation discrimination. Five TLC positive safety/completion checks and 26 decoded negative controls pass. Three Rust evaluator trajectory calls failed before execution at recursion parsing; unchanged model bytes pass all three named trajectories with the installed supported TypeScript evaluator, original 30-second caps and original failures retained. Source identities/own child custody verified; no runtime/framework edits, native execution, source seal, budget changes or implementation-worker operation. Native acceptance remains 8/12; complete frame/work/native-error source refinement still blocks sufficiency.


### Donor active-frame, captured-thread and private-work ownership (2026-10-22)

The [donor ownership audit](smp-retirement-donor-ownership.md) traces sync interrupt spill versus compiler THREAD_SAVE, thread.cont stack references, typed CONTINUATION/FRAME scanning/forwarding, local incomplete-chunk scanning, and exclusive scheduler restore/publication. Existing collector/save/restore paths are reusable; raw encoded stack addresses in generic RC data and still/RC list transfer do not replace them. Active Scheme donors require a source-backed safe-point/helper or an explicit verified idle-only admission contract; prior C-only field/list proposals did not establish this. Unified retirement_donor_ownership.qnt plus importing trajectories pass typecheck, five positive safety/completion checks (310/318/154/310/310 states), 32 decoded controls and three TypeScript trajectories under original caps. First batch compiler output truncated at 64 KiB and was interrupted only for this chat's own identified runner, then reconciled through existing APIs; prefix-equivalent compact source and separated unused trajectory definitions recover verification without framework/timeout changes. Exact Scheme/C collective scheduler publication and abort restoration remain the largest constructive blocker, with callback/origin/full-native obligations retained. Runtime/framework source, Recipes, budgets, builds and the implementation worker were untouched. Native acceptance remains 8/12.


### 2026-10-22 Scheme safe-point / C collective completion protocol

Research-only repair-9-12 audit: [function-level protocol](smp-retirement-safe-point-protocol.md), `models/gambit/retirement_safe_point.qnt` and `evidence/research/smp-retirement-study/safe-point-validation.json`. Native acceptance stays 8/12. No runtime/framework/compiler/Recipe/budget edit, native rerun or implementation-worker operation. Source hashes match the preceding pinned donor audit.

The preferred trade-off retains a typed rooted nonrunnable owner across C3, then requires one survivor Scheme activation or one original-owner restore on common abort. It distinguishes internal Scheme/C helper yield from final API return and updates the last-consumer ledger. Full helper GC is added after two preparation GC rounds: old cohort on abort, reduced cohort on success, with exact epoch/round arrivals and full GC tails. Forty-eight effective checks accepted: typecheck, five safety/conditional-completion positives, 39 decoded mutations and three imported TypeScript trajectories. Original 30s/12-worker/1GiB/8MiB/capture limits remain.

Retained failures: 575a3720817c41a0a2899cce82906c2e compiler-output truncation before TLC, recovered by fieldwise-equivalent reset compaction; a8be2634256a4c1d80288adb3bc7195b correctly finds anchor loss earlier than the inherited witness predicate expected, so the audit stops. Final 470bf861fc4242aebdd2af5f83b1e7c3 requalifies that existing trace and runs only unfinished checks/corrected helper-cohort trajectories; no completed unchanged TLC check is repeated. Own child groups reconciled through APIs.

Source blockers are explicit: current service_sync_op returns void; the donor interrupt hook alone cannot enter P0 completion from its raw c-lambda C activation. Persistent begin/poll/finish or generated completion bridge, GC-prioritized wait offers, queue claim/link/wake critical-section refinement, pre-anchor entry and postcommit error/direct-C/shutdown coverage remain unproved. SFUN marker creation allocates and has an explicit proc_or_false rooting TODO; it is not a no-GC bridge. Model publication remains atomic and one representative detailed donor is modeled. These facts narrow the implementation contract; they do not establish gate-9 sufficiency or complete native/Gerbil acceptance.


### 2026-10-22 P0 raw c-lambda and direct-C completion bridge

Research-only repair-9-12: [function-level P0 bridge contract](smp-retirement-p0-completion-bridge.md), models/gambit/retirement_p0_bridge.qnt and evidence/research/smp-retirement-study/p0-bridge-validation.json. Native acceptance remains 8/12; no runtime/framework/compiler/Recipe/budget change, native execution or implementation-worker operation. Source byte identities match the prior audit.

Actual reusable control path: ___call constructs a Scheme return-to-C frame, runs trampoline and accepts only matching UNWIND_C_STACK/marker before popping fp/restoring R0. Prefer a private closed-gate completion bridge in the shared current_vm_resize_admitted driver; public-wrapper-only or Scheme-wrapper-only edits miss direct admitted shutdown. Public SFUN admission is blocked by the closed gate; ___run resets R0 and is not a drop-in. P already repairs the B marker proc_or_false rooting TODO with GC_SAVE1/RESTORE1; no duplicate repair is required. Marker bytes are still/refcounted.

Raw C unwind does not establish normal frame/R0 restoration. Ordinary helper errors must be caught in Scheme and match-return as descriptor status before cleanup/retry; arbitrary raw unwind requires a separately proved disposition. Eight safety/conditional-completion positives (including prepared P0 direct C and bounded allocation/caught-Scheme failure retries), 51 decoded negatives, five imported TypeScript trajectories and typecheck pass: 65 checks under original caps.

The initial own audit a69aa08192db4678a88c05d69844ada2 was deliberately interrupted/reconciled when source inspection disproved its raw-unwind retry abstraction; partial evidence is retained. Corrected ebd9928b58fe477e999e597f1635abd3 reruns the causally changed relation and reconciles all own children. Prepared entry/stack-space and helper registration, nonescape/pinning, raw exceptional cleanup, partial publication faults, complete shutdown/direct-C/origin census, real synchronization/capacity and full native first-eight/12-gate regressions remain open. Model success does not prove arbitrary direct C or shutdown is executable.


### 2026-10-22 Shutdown context, registered P0 helper and raw unwind disposition

Research-only repair-9-12: [source/call-order study](smp-retirement-shutdown-context.md), models/gambit/retirement_shutdown_bridge.qnt and evidence/research/smp-retirement-study/shutdown-context-validation.json. No runtime/framework/compiler/Recipe/budget edit, native execution or implementation-worker operation. Native acceptance stays 8/12.

Shutdown is not universally prepared: setup_state==1 precedes handlers/VM/Scheme threading; `(exit 0)` encodes a nonzero error and can reach setup cleanup after raw ___run unwind, bypassing matching marker pop/R0 restoration. ___run kills its marker only on normal return; P repairs public SFUN finalization but not this all-path run finalizer. A necessary finalizer still does not reconstruct fp/R0. A controlled pre-exit Scheme landing hook is a proposed smaller route for valid Scheme exit; arbitrary raw native faults remain unresolved.

Proposed registration uses currently unused VM Scheme structure slot 2 (already scanned by mark_vm_scmobj), with actual helper/transaction record published after startup-threading readiness and bound to VM incarnation. No fixed handler label renumbering or VM_SIZE expansion is required by that proposal. A current-execution P0 bridge claim must block explicit migration and ordinary switching; pinned alone only blocks stealing. P already supplies sync-aware locks and removes B migration busy-loop behavior. Stopping OS user/heartbeat/child notifications does not by itself remove per-VM sync GC service.

All 83 bounded checks accepted: typecheck; 11 safety/conditional-terminal positives, explicitly eight normal, one opaque-suffix retention and two retained-unsafe-context outcomes; 63 decoded negatives; eight imported TypeScript trajectories. Original caps remain. Raw-context retention prohibits normal helper entry, GC and teardown in the model and retains known roots/marker; it is not native containment, usable-VM recovery or completed shutdown. Actual landing/exception compatibility, full context/root/borrower census, concurrency/visibility, partial helper faults and complete native/Gerbil/first-eight regressions remain open. Own child custody and source stability are audited in the receipt.


### 2026-10-22 Pre-exit landing contract; original TFIB SIGSEGV becomes the causal priority

Research-only successor: `docs/smp-retirement-exit-landing.md`, unified `models/gambit/retirement_exit_landing.qnt`, named trajectory module and `evidence/research/smp-retirement-study/exit-landing-validation.json`. Source mapping distinguishes P0 versus worker exit, detached exit-job/final-will suffix ownership, ordinary callback failure, recursive exit, nested GC before retirement and all-path per-___run marker finalization. Worker controlled matching return before native C-only sync service, status/escape compatibility, shutdown work disposition and raw unwind remain unproved implementation premises. Typecheck and twelve explicitly selected TypeScript trajectories pass. Ten TLC positives/nineteen mutation initializers remain unvalidated: compiler RPC strict JSON exceeds the unchanged 20M string limit before TLC. Earlier type error, duplicate failed attempt and empty default trajectory selection are preserved; exit 0 with no selected tests was rejected. Existing 83-check shutdown result is not relabeled for the new model.

User reports `bazel-profile-gc-ffi-inventory-vector-inc-1` DENY at ~3737s; candidate/runtime/numeric/official PASS, original TFIB HI=0/LO=11, then interrupt2 fails to finish before the stress-gsi window (outer child exit -9, ~3695s); gsc/PR not started. These native observations are user-provided, not newly qualified by this research run. `docs/smp-repair9-tfib-sigsegv.md` and `evidence/research/smp-retirement-study/tfib-source-audit.json` retain that boundary. The runner elapsed 93.6s is a suite boundary, not a fault-PC timestamp. Original `(go 15 5000)` has 4,935,000 thread creation/start/join events on normal completion, 250 times repeat-20; these are not peak-live or measured precrash counts. TFIB has no direct vector-inc call. Offline reconstruction of all 21 declared candidate files matches the source-lock hashes; this does not establish the reported crashing gsi identity. Creation/initialization, join/end/wakeup queue transfer and saved-frame/GC last-consumer chains are mapped. Exact failure producer binding and retained crash-PC/stack/object evidence are needed before choosing a causal small refactor. No evidence connects this SIGSEGV to the proposed shutdown landing pad.

No runtime/framework/compiler/Recipe/budget/seal changes, native reproduction, whole-inventory retry, implementation-worker operation or push. Native acceptance remains 8/12. Own research children were reconciled through the registered audit role; publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/c468281facb6489da5f491488cb611d8/outputs/exit-landing-tfib-publication/receipt.json.


### 2026-10-22 Repair-9 TFIB producer/crash identity closure and GC source envelope

Research-only binding now verifies the previously user-reported inventory failure: `.cache/tasks/repair-9-12/fixtures/bazel-profile-gc-ffi-inventory-vector-inc-1` retains candidate/runtime/numeric/official PASS, stress-gsi TIMEOUT and aggregate DENY at 3737.177711s, with outer timeout=false. Imported completed `bazel-profile-numeric-host-vector-inc-build-4` source-core checkpoint, archive SHA e78a85b19fa32f67fcd40cb886c550b170b421eca11c984b82b60f2a14080a97, gsi SHA 5620dd70a28f46765551c07742bfc4b5877096008900f9addd486d90de1bf5ad and Mach-O UUID c823a9d8-418b-35f6-88bf-1330cef04de5 match existing crash report gsi-2026-10-22-220949.ips. Crashed PID 66761 has finished shard parent 66760 and 22:08:15.4931 -> 22:09:49.1350 +08:00 timing matching TFIB. All 21 source-lock candidate files were rechecked in the immutable archive. The build key/location alone does not identify a generation.

Offline disassembly identifies actual PC 0x1005e3d50 / link PC 0x10000fd50 / mark_array +104 as ldr x25,[x0], the presumed object-header load after low-bit tag test/masking (bound mem.c:3685–3686). Captured x0/FAR 0x3f947ae147ae1478 equals raw double 0.02 bits 0x3f947ae147ae147b masked by ~7. This is mask equivalence, not captured scalar provenance or a proved quantum-field origin. Optimized stack is incomplete; +780 follows end_heap_chunk in this image and cannot identify a recursive root caller. No core found in the explicitly checked PID/default locations or failed-run tree; exact report bytes and register/thread summaries retained. The first corrupting writer, input cell/container/GC map and native source-refinement cause remain open.

Bound generated _thread.c:14119–14157 initializes 37 structure fields; 14165–14175 constructs a typed seven-element F64 vector and installs its reference in slot 16. mem.c already skips F64/flonum payload, uses a root-copy barrier and locked/barriered chunk publication. Neither another scalar skip nor an assumed missing constructor default is a justified repair. `docs/smp-repair9-tfib-crash-binding.md` and `evidence/research/smp-retirement-study/tfib-crash-binding.json` record the exact chain and candidate-specific source boundaries.

`models/gambit/tfib_gc_handoff.qnt` plus importing trajectories form a compact source-bound envelope for two workers/two GC epochs, typed scanning, safe defaults, 38-word constructor reservation/generation, parked/handoff/caller roots, legal forwarding-before-copy, chunk/scanner completion and unique restore ownership. All 19 checks accepted: typecheck, normal safety/conditional completion (63 distinct states), allocation-failure retention (2 states), twelve decoded mutations and four explicit TypeScript trajectories. Original 30-second/check, twelve TLC workers, 1GiB heap/8MiB stack and capture/compiler limits retained. Reserved-name parse failure, earlier integer-set witness decoding rejection, successful narrower model and final checks remain separately recorded. The positive model assumes native refinement and weak fairness; it does not establish the first writer, 11-worker/C-memory correspondence or compose the earlier large shutdown proof.

No runtime/framework/compiler/Recipe/seal/budget change, gsi execution, build, full-inventory retry, live process/peer operation or push. Native remains 8/12. Only own registered audit children were reconciled. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/5eff4143b3df453dbdb425227a3904b2/outputs/tfib-binding-publication/receipt.json.


### 2026-10-23 mark_array entry provenance and minimal first-fault diagnostic design

Research-only continuation of the bound gsi 5620dd70… / UUID c823a9d8… / PID 66761 GC fault. `docs/smp-repair9-mark-array-origin.md` and `mark-array-entry-map.json` enumerate 29 direct mark_array calls in the verified archive mem.c. New attribution gaps: the pair fast path at 4354 bypasses scan(); mark_array sets cell to the copied object first field (3757) and goto again (3778), so the original root category is not necessarily the actual faulting container. Heap sFRAME selected payload and its separate return-label scan, captured-continuation link, RC, weak/table, global/register/saved/cache and processor/VM root spans are distinguished. Existing debug origin/body/line fields are per-pstate but insufficient. Frame FP_STK(fp,k)=fp[-k] run address/count correspondence is explicit.

`first-invalid-scan-plan.json` specifies diagnostic-only pre-cell and pre-header commits, raw input/target/presence fields, original/current cursor, selected extent, known parent header, frame/RA/map/ordinal and allocation-generation/write coverage/order at concrete functions. A preallocated shared carrier is proposed because existing IPS lacks pstate memory; no new crash handler or unsafe corrupt-object printing is assumed. Existing nb_gcs is an end-of-GC floating statistic, not a committed allocation/diagnostic epoch. Native record ordering/disassembly, carrier persistence, lifetime and overhead under unchanged budgets are unproved gates. Optional subsequent targeted stack/constructor/GC-copy/frame-write observations require an identified origin and matched allocation generation, overlap and preceding order; unknowns stay unknown. No diagnostic implementation was activated.

`models/gambit/tfib_scan_origin.qnt` and its importing trajectories pass 29 bounded checks: typecheck, three positive safety/conditional-terminal cases (all thirteen source scenarios: 180 distinct states; normal and unavailable-carrier retention: 14 each), eighteen decoded controls and seven explicit TypeScript trajectories. Same invalid word class is differentiated by trustworthy metadata; frame category is not a compiler-GC-map verdict, and a contaminated pointer field alone does not establish an earlier OOB writer. Negative controls include lost copy-tail/stale pair/frame metadata, pre-load ordering, mixed owner/epoch, torn/private/lost or overwritten records, unsafe pretty printing, skip-and-continue, raw-word-only attribution and unmatched old-generation/disjoint/unordered writer evidence. The first positive failed on stale current-admission after epoch change and was corrected; that failed run and the narrower successful 25-check version remain immutable history. Original 30s/check, twelve TLC workers, 1GiB heap, 8MiB stack/capture/compiler limits retained. Prior 19-check runtime-envelope and large shutdown-model boundaries are unchanged; no composed native proof is claimed.

All changes are research docs/QNT/JSON evidence. No runtime/header/compiler/framework/Recipe/budget edit, native gsi execution, suite retry, peer operation, signal or push. Native remains 8/12, actual missing scan-cell origin and first corrupting writer remain open. Only own audit children reconciled; publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/17adbf2b37fb4666894908b931ae809c/outputs/scan-origin-publication/receipt.json.


### 2026-10-23 New native-data boundaries: diagnostic carrier and in-flight interrupt requests

Research-only [new-data study](smp-repair9-new-data-boundaries.md) binds completed build-6 mark and build-7 origin archives separately from the original TFIB failure. Origin binary 9eca674b / UUID 1bcb0a1c differs from failing 5620dd70; selected _thread Scheme/generated C/sharp, setup.c and gambit.h match the original archive, while mem.c changes. Embedded receipt digests, binary, UUID and selected source bytes checked. Mark generation's noncanonical-word skip is rejected; reported 200s without a new crash on origin does not qualify original TFIB completion or inventory.

Actual origin carrier only implements pre-header source-level capture. Same-size ftruncate preserves old slots; processor id and seq==commit do not bind session/VM/GC epoch or fault. No pre-cell hook, current parent/frame/map/generation or explicit fault freeze. scan_start/remain are already-advanced outer cursor/count, and tail scans retain that outer metadata. Existing 4096-byte file decoded and copied as unbound forensic bytes (11 nonzero slots), not first-fault evidence. Native compiled ordering, last writer and reader quiescence remain unproved. This refines the prior diagnostic design versus actual newly discovered producer; it does not rewrite prior audit claims about what this chat activated.

Interrupt2 retained narrative reports reject sustained repair by wake, heap, queue-drain, target-placement or yield patches. Individual scratch trial receipts are not reconstructed here. Exact SMP source chain maps result mutex/caller -> processor queue -> dispatcher local -> reroute/thread queue/action -> result publication. Empty queues do not exclude dispatcher-owned requests; collective activity and target yielding are not reply acknowledgements. Next discriminating evidence is per-blocked-sender request ownership through reply/abandon, with typed root coverage, rather than additional aggregate polling.

New repair9_new_data_boundaries.qnt passes two exhaustive safety positives (3/6 distinct states) and two decoded distinguishing negatives: accepting an old committed slot after reopen and equating empty queues with completion while a request remains dispatcher-owned. Original 30s/check, twelve TLC workers, 1GiB heap/8MiB stack limits retained. Initial reserved-word parse rejection retained. No liveness, C/native refinement, implemented ledger, GC cause or composed native proof claimed; earlier 29-check model remains separately bound. Four research files published, no runtime/framework/Recipe/budget edit, native run, peer operation, push or stage/commit; native remains 8/12. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/d8b6d3e2a0e741fd974c7c713f4b6dd0/outputs/repair9-new-data-publication/receipt.json.


### 2026-10-23 Blocked synchronous interrupt request: reply GC gap and final-consumer ledger

Research-only [request lifecycle study](smp-repair9-interrupt-request-lifecycle.md) follows immutable origin build-7 SMP source from request/result-mutex construction through route/dequeue/resume dispatcher, action, result storage, mutex unlock/abandon, sender runnable publication, restore and final return/error. Existing processor and common thread queue macros already detach one node and clear its successor. The target stored in mutex specific is replaced by the callback result; it cannot remain the target-identity field. Both action paths store result before macro-mutex-unlock!, whose leading heap-limit check permits GC before unlock. Source root-map proof for these live ranges remains open. A result stored, sender made runnable and actual caller consumption are distinct boundaries. Early reply before sender blocks needs no wake; termination abandonment is preserved, while arbitrary handler escape/sender termination remain unproved.

Reviewed retained observations still do not identify one blocked sender/request across all transitions. A six-surface bounded token/owner/reply observation plan is saved, explicitly DESIGN_ONLY_NOT_ACTIVATED. Stable identities across moving GC, rooted mutex association, nested-owner retention, coverage/overflow, native ordering and cost remain obligations; no raw-address side-table shortcut or runtime implementation is claimed. New interrupt_request_lifecycle.qnt passes two exhaustive safety positives (8 states each) and four decoded negatives: premature completion at stored result, lost dispatcher-local root, stale address identity and dropped termination responsibility. A prior six-check version is retained; final version isolates identity failure from completion failure. Original 30s/check, twelve TLC workers, 1GiB heap and 8MiB stack unchanged. No liveness, native root-map refinement, multi-sender/nested/early-reply race proof or actual failure location claimed. Prior QNT evidence unchanged.

Four research files published; only own audit children reconciled. No runtime/header/compiler/framework/Recipe/budget edit, native run, peer operation, stage/commit or push. Native remains 8/12. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/c1f09f1cf0064beb904f469a7234b8de/outputs/interrupt-request-publication/receipt.json.


### 2026-10-23 Combined interrupt request model and emitted-C root coverage correction

[Combined study](smp-repair9-interrupt-composition.md) extends the same interrupt_request_lifecycle.qnt with early reply, nested parent/child tokens, predispatch stale-receiver reroute, captured activation migration, repeated GC, caught result, target abandonment and opaque Scheme/raw escape retention. Seven safety positives pass (25/92/92/89/77/77/68 states); nine decoded mutations distinguish missing early-reply wake logic, parent overwrite/root loss, duplicate migration ownership, result-root loss/stale reload, false escape success, dropped termination responsibility and stale dispatch. Three explicitly selected TypeScript trajectories pass, including early outer zero-wake + waiting child one-wake + six GC boundaries, caught result and opaque parent retention. Nineteen checks accepted under original caps. Reserved builtin put parse failure retained; original six-check model/receipt preserved at its immutable prior run. Safety and bounded trajectories are not native liveness, arbitrary exception/nested behavior or a C refinement theorem.

Important correction to prior source-only GC-gap claim: generated callback return blocks store mutex field 11 then directly PRIMITIVELOCK, without an emitted CHECK_HEAP there. The real collector-service opportunity is confirmed in later contended owner-lock helper (sync-op), plus callbacks/other call paths. Five generated return descriptor/slot memberships are mechanically checked: other L3 mutex ordinal2 map0x3, other L1 mutex/owner ordinals2/3 map0x7, resume L2 thunk/mutex ordinals2/3 map0x7, resume L3 thunk/mutex/owner ordinals2/3/4 map0xf, helper L1 object ordinal2 map0x3. Strong mutex field11 preserves stored result through generic pointer-bearing scan. No missing root is demonstrated at those inspected sites; native frame integrity/earlier writes and full callback maps remain open. Prior document has a visible correction notice; historical receipts remain unchanged.

Six observation surfaces now specify stable token/parent/sender/target/VM identity, transfer acknowledgement, actual wait insertion versus early reply, detached/nested activation, real GC return label/map, unlock/runnable publication and final return/error. Reviewed material still lacks an actual blocked sender's complete request trace. No instrumentation activated, no runtime/header/compiler/framework/Recipe/budget edit, native run, peer operation, stage/commit or push. Native remains 8/12. Only own audit children reconciled. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/da5b11b8c2124aeeb8592f095a64e355/outputs/interrupt-request-composition-publication/receipt.json.


### 2026-10-23 Minimal interrupt diagnostic contract and concrete current-candidate reply replay

[Minimal contract](smp-repair9-interrupt-minimal-contract.md) explicitly audits real changes under repair-9-12/build/gambit-core. Earlier exclusionary wording is corrected: source changes are present; missing historical run binding is a different question. Incremental files changed during reads, so per-file snapshots are not promoted to an atomic producer generation. Retained 863e Scheme481c2a0f/generated Cae2f27f6 show a concrete defect in both other-interrupt mutex arms: successful action/result/unlock falls through to propagation again after specific has become the result. Scheme AST branch shape and C L16→L17 / L26 edges agree. Original archived branch is execute-or-propagate. Restore proper else branches and regenerate/qualify is the proposed minimum source correction; this audit makes no runtime edit or native attribution. It is not proof of the old TFIB crash cause. Earlier live flight-probe bytes, main origin gsi9eca674b and distinct changing gsi.lastq identities are explicitly separated.

The chosen future diagnostic representation stores a private marker/ID/parent/thunk/hop descriptor in the existing private result mutex name, retaining request[next,mutex] and specific target→result semantics. IDs are session/VM/nonwrapping immediate serial, independent of moving addresses and OS processor IDs. Nested context belongs to the Scheme activation/dynamic environment, not native TLS. No new generic object field, native raw-address root map or RC handle is proposed. Descriptor/error-display consumer census, changed generated root maps, real publication/order and original-budget observer cost are required before activation. Logical CLOSE waits for caller consumption/error, dispatcher acknowledgement, and child context return/closure; Scheme memory remains GC-owned and native carrier outlives writers/readers. Unsupported escape and missing trace coverage remain unfinished/UNKNOWN, with no replay or rescue.

Same QNT passes seven safety positives and seventeen decoded negatives, plus five explicitly selected TypeScript trajectories: 29 accepted checks, original caps retained. New controls cover premature/opaque closure, ID reuse, native-TLS parent loss, address association across GC, evidence-gap verdict, post-reply replay and child close before context return. Original 19-check source and receipts retained separately. First extension run's inner-before-outer early-close witness was conservatively rejected; corrected active-request witness and child-pop guard are validated. Bounded identity/ownership evidence does not prove the descriptor implementation, native C root/memory refinement, actual blocked request location or stable native completion.

Six evidence surfaces now have a concrete identity/acknowledgement protocol and blocked-sender reconstruction algorithm. All changes are research docs/QNT/JSON only; no runtime/header/compiler/framework/Recipe/budget edit, native execution, peer operation, stage/commit or push. Native remains 8/12. Own audit children reconciled. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/3dd5b6fffdde44259cd442b95fab7f48/outputs/interrupt-minimal-publication/receipt.json.


### 2026-10-23 Reply-replay branches corrected: Scheme/C/object/scratch correspondence

[Current status audit](smp-repair9-reply-replay-current-status.md) confirms both other-interrupt mutex arms corrected in stable byte cut f4af8764: Scheme f987f557 and generated C52bd0c33. Exact diff against retained bad 863e is two parenthesis-only hunks restoring propagation to else. Current C success unlock-return labels L3/L10 return to drain loops, not propagation; callback labels L2/L9 retain mutex ordinal2 via fs5/map0x3. This chat made no runtime edits and did not inspect another chat's messages/process image. Actor is not established from file bytes; the shared workspace correction is established.

Current object98889408 and scratch gsi.lastq48fe88b5 have identical H___thread size128460 and 5122 same-position internal transfer entries (signature a1d3d6ad...). Main gsi9eca674b remains the original exported origin generation, with different size/signature; its original processor handler did not contain the newer candidate defect. All selected files stable during capture/re-read. Static correspondence is not a full C-to-object successful producer receipt, full binary equivalence or native execution/acceptance. Saved identities separate historical bad scratch/native observations from corrected current bytes. No unchanged failed full-inventory rerun initiated.

Same maintained QNT explicitly separates action executions, normal result writes and terminal reply publications. Seven safety positives, twenty-two decoded mutations and ten named TypeScript trajectories pass:39 checks. Added controls distinguish duplicate action/reply, target abandonment falsely reported as success, old-owner execution during migration and replay after opaque exit. Trajectories show one action/write/reply on normal nested migration, zero action/write plus one error reply for pre-dispatch termination, one action/no normal write/one error reply after action entry, caught ordinary result, and no invented opaque reply. Original30s/12-workers/1GiB/8MiB limits unchanged; previous model receipts immutable. At-most-once safety/finite trajectories are not native liveness or arbitrary exception semantics.

First-eight impact matrix distinguishes the two-branch semantic restoration from other current scheduler edits. No header/layout/GC change is required by the minimum fix; Scheme C and link/return tables still require coherent regeneration. Complete original bootstrap/GSI/GSC/PR/stress/registry qualification remains same-producer evidence, not inherited from old binaries or these static/model checks. Native count remains8/12; old TFIB fault cause and other pending request/acceptance gates stay open. Only research docs/QNT/JSON updated, own audit children reconciled. No runtime/compiler/framework/Recipe/budget mutation, gsi execution, peer operation, stage/commit or push. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/618e182235a942ff899a998e4682f06c/outputs/reply-once-publication/receipt.json.


### 2026-10-23 Corrected scratch generation, residual delivery and queue ownership

[Producer/delivery audit](smp-repair9-corrected-delivery-binding.md) separates saved corrected48fe88b5/UUIDbfb0e497 from new stable47a21556/UUID6ad9ce17. The Scheme f987f557, generated C52bd0c33 and object98889408 are unchanged; setup50ab21b7 adds tail-identity and self-loop guards. New scratch still matches the object H___thread internal-transfer signature a1d3d6ad (128460 bytes/5122 entries). Static match does not attest full compile/link provenance or the setup guards. Main origin9eca remains unchanged. Stable read1519aef6 and fingerprint423c8bf7 retained separately from prior cut.

Two saved sample UUIDs and13 retained scratch crash reports (two other UUIDs, FAR0x57/thread-host offsets) match neither corrected image. Published7/8/counter-build narrative reports a residual second-mutex-lock gap and an unexecuted request while target yields, but has no per-trial binary/request binding. The exact blocked R is not retroactively identified. No matching corrected native execution receipt established by these selected reads; this does not deny the real incremental code or scratch experiments.

Function-level map covers fresh request/target-owned result mutex, locked route snapshots, migration intent, thread/processor publication, detached local consumers, receiver recheck, yield/resume drains, wake versus reply, actual sender BTQ insertion, slow unlock/runnable publication and final consumption. Both queue pops clear next; normal propagation callers are construction and detached mismatch branches. The tail guard correctly rejects an already-tail re-raise, but literal C assignment controls show non-tail re-enqueue can orphan a successor. This is a conditional ownership violation, not an established reachable cause after branch correction. Empty queues exclude neither a detached activation nor nested work. Idle masking/wake debt and migration destination remain native refinement obligations; repeated wake/rescue/CAS experiments are retained failures.

Same QNT state now includes two-node intrusive delivery, detached owner, thread reroute, target move/recheck and separate notification feeding the existing once/reply/root lifecycle. Eight safety positives,28 decoded negatives and15 named trajectories pass (51 bounded checks), including six delivery controls and all previous controls on the new bytes. Original30s per-check/12-worker/1GiB/8MiB limits unchanged. The safe sleep predicate and unique ownership are explicit obligations, not assumptions silently attributed to C. No native liveness/GC-map/full-inventory conclusion follows.

Updated six-surface plan starts from actual sender BTQ mutex R, then token/hop queue commits and pops, receiver/reroute, callback nesting, result/unlock/runnable and final consumers. Request/session/VM IDs survive movement; overflow yields UNKNOWN. No instrumentation activated. Only research docs/QNT/JSON updated; no runtime edit/native execution/full inventory/peer operation/stage/commit/push. Native acceptance remains8/12. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/14947fb9cf0840499f20d63a74cb3b1b/outputs/interrupt-delivery-publication/receipt.json.


### 2026-10-23 Result-mutex structural delivery candidate: authoritative mailbox and scheduler handoff

[Bounded refactor design](smp-repair9-mailbox-handoff-design.md) respects the narrowed single-sender claim. The user clarified QNT, not Qwen; no external-model review or peer operation was performed. Existing measured result_mutex_delivery_obligation model, eight failed wake/select profiles and native qualification are left unchanged. Reported thread-only+OTHER5/8 and self-loop3/8 remain reverted failures. Stable cut a287113e confirms restored setup9d028d74 and gsi.lastq48fe88b5/UUIDbfb0e497, unchanged corrected thread Scheme/C/object; prior guard generation47a21556 remains historical. Counts930553/930553,0 terminated,930546/930545 second lock,908583 resume and19418 processor thunk entries are retained as human report, not retroactive binary/request binding.

Recommended research candidate centralizes four responsibilities: target-locked authoritative mailbox publication; rooted claim before withdrawal; pending-aware current-to-blocked commit; destination-locked runnable publication and park preparation/validation/wake handoff. Keep the two-slot request, result mutex and existing locks/queues; no request node in processor notification, no global strong-root registry, full-processor scan, timed rescue, reduced processors or new collector. Per-processor scalar bookkeeping may be needed; existing startup scheduler_status cannot be reused as a parking bit without proof. Proposed source table names publish/claim, suspension, migration/destination, wait and flag-service functions. GC maps, exceptions, lock/memory order, all transition sites, overflow/reuse and native performance remain unrefined. The independent stale-last-processor/migration-target schedule constrains broad source preservation; it is not asserted as this flood cause or conjoined with join.

New separate QNT result_mutex_mailbox_handoff has concrete queue/activation/runnable/park/generation/wake/execution/reply states, no arbitrary drop action. Four positives pass safety plus conditional fair completion (running459, idle270, migration2847, park-race315 distinct states). Six mutations have decoded bad-field witnesses; ten named trajectories pass:20 checks. A pending node can remain reachable while sleep has no remaining wake; noLost alone is insufficient. This source-independent control requires effective serviceability as well as ownership retention. Original30s/12-worker/1GiB/8MiB limits unchanged. Parse/type failures and superseded draft/compiler-cap failures remain retained and uncounted. No measured-profile overwrite or unified-lifecycle draft publication.

OCaml46e1c324 domain.c159–183,412–450,1182–1197,1523–1535 supports durable pending, recipient lock/condition wait and service responsibility; Chez41d5ffca thread.c158–184,209–235 supports publication recheck and precise acquired effects. Exact local bytes captured as references, not imported upstream architecture or native equivalence. Performance target is bounded O(1) per transition with existing queue/locks and no extra per-request allocation; callback/GC/contention and native latency are not certified by model state counts.

No source change or gambit-smp acceptance is initiated. Before implementation, complete source refinement and then a same-producer, original-budget comparison against the7/8 baseline. Flood8/8 is not9/12; two same-contract task receipts and other gates still required. Banner/pre-join LW_REFUSED/repeated Darwin EDEADLK are not admitted recovery. Native remains8/12. Only new research docs/QNT/JSON and append-only indexes updated; no runtime/compiler/framework/Recipe/budget edit, native run, peer operation, staging, commit or push. Publication receipt: .cache/tasks/repair-9-12/processes/audit/runs/bf8c2bdc109043039cb6acfcedbdaa60/outputs/result-mutex-mailbox-publication/receipt.json.


### 2026-10-23 Mailbox boundary refinement: runnable/park order, raw ticket acquisition and rooted exceptional exits

[Four-handoff source study](smp-repair9-mailbox-boundary-refinement.md) binds stable audit9fe4ebd6 and system-otool static auditbf83f4bb. Frozen setup.c9d028d74/setup.o0a30cc8c show ldaddal reservation followed by ordinary volatile ldr ticket wait and queue-data ldr, without acquire after observed grant. This is a concrete raw-lock visibility prerequisite, not an identified native first writer. Scheme T/P helpers use successful trylock CAS after availability observation and must be distinguished from raw C spinning. New source-shaped two-node QNT uses literal pop/enqueue assignments with explicit stale-observation premise; it is not a full ARM memory model.

Proposed park order is P prepare/release, V enroll/release, P ready/generation validation/commit/release, select, P cleanup/release, V unregister/release on every normal C return. Ready publication and committed wake decision share P. No reverse nested V/P or lock across select. Abort write before select persists and EAGAIN/full pipe coalesces; prior correspondence is corrected. Ignored EINTR/other write errors do not certify persistent wake. Saved generated maps bind wait processor STK(-6)/fs5/0x3 and resume mutex STK(-5)/fs5/0x7, helper0xf; other handler0x3. Retention elsewhere does not update an unmapped local. Abandonment is typed error, not fake normal reply; opaque continuation/C escape has no completion claim. Ten current-withdrawal sites preserve distinct wait semantics.

QNT:19 boundary cases (8 conditional-completion positives,1 safety-only escape,10 decoded negatives),20 named trajectories,3 ticket-visibility cases and2 P/V lock-order cases:44 checks. Original30s/check/12-worker/1GiB/8MiB limits unchanged. Draft mode5 store guard error retained and corrected, not relabeled runtime failure. Earlier20-check receipt and measured-failure obligation model unchanged. Evidence: result-mutex-mailbox-boundary-validation.json and source-contract.json in evidence/research/smp-retirement-study/. Full source refinement, arbitrary escapes, machine-word wrap/incarnation, multi-request/repeated epochs, first-eight preservation, performance and native gates remain open. No runtime/compiler/header/Recipe/budget edit, native execution, full inventory, peer operation, staging, commit or push. Native remains8/12.


### 2026-10-23 Ticket grant profiles and abort failure responsibility

[Focused source/model contract](smp-repair9-acquire-abort-contract.md), acquire-abort-source-contract.json and acquire-abort-validation.json record fresh stable auditb4150baa. Incremental header15f39cfd unchanged; normal canonical macro matches vendor/incremental/generated copies. setup65a4ea48, os_io22c2634f and os_io.h7e39f1c3 are changed source with blocking begin/end, pending check and conditional OTHER abort; they are not bound to the old setup.o generation. Leaf write still ignores byte count/errno. No new binary/run identity inferred.

Minimum acquire candidate is one effective fence after normal grant wait, before client protected access. Debug already has completion ordering and successful CAS differs; emulated_shared_memory_barrier is empty, so syntactic macro insertion does not prove that fallback. Current multi-VM registry guard already requires native GNU atomics. Generic lock footprint includes allocation/GC scan, processor/VM setup and condvar-device reacquisition, so all first-eight passes require changed-producer requalification. No ticket/ABI/layout/unlock rewrite proposed.

Abort contract follows publisher->pipe->awake receiver->same-epoch ready service. EAGAIN coalesces only with pipe/receiver responsibility; EINTR retains retry debt. Native abort must snapshot errno, honor signal context, and expose/record failure through conditional abort, interrupt raise, kernel VOID-erasing bridge and Scheme wait/runnable callers. No Scheme throw under held scheduler locks. A prior-epoch ack is insufficient. A permanent broken pipe plus sleeping target and no other channel has no recovery proof; fault retention is safety only, never delivery admission. Live-fd/incarnation/cleanup and deferred safe failure disposition remain open.

24 new checks:7 ticket profiles and9 abort cases (8 conditional-completion positives,1 retained-fault safety-only,7 decoded negatives), plus8 named TypeScript trajectories.30s/check,12 workers,1GiB/8MiB unchanged. Model transient EINTR bound is explicit; unbounded signal arrival has no time guarantee. Performance proposal: one fence per normal raw acquisition; one normal write, k interruptions imply k+1 attempts; scalar O(1) handoff bookkeeping, optional O(P) storage. No native cost measured, no budget/processor/expectation change. Prior44-check models/receipts and measured-failure obligation preserved. Research only: no runtime/compiler/header edit, native run/full inventory, peer operation, staging, commit or push. Native remains8/12.


End-of-turn source boundary for the acquire/abort study: final auditd3cca39d confirms published hashes, preserved history and24 checks. Live setup.c/os_io.c/os_io.h subsequently diverged from stable b4150baa while header/template still matched. Claims remain scoped to the sealed source cut and prior object generation; no latest-producer qualification or native execution inferred. No peer source chase or process operation followed.


### 2026-10-23 Abort fault ownership, lock-outside inspection and fd last consumers

[Source study](smp-repair9-abort-fault-lifetime.md), abort-fault-lifetime-source-contract.json and abort-fault-lifetime-validation.json bind stable auditd53671cb source. Worker resize1113-1138 closes interrupts/OS before thread_exit; P0 join1183-1196 authorizes later memory transfer, not earlier fd close. Destruction chain is cleanup_os_pstate->cleanup_io_pstate->close_half_duplex_pipe (read close/-1 then write close/-1). Existing OP_SET_PROCESSOR_COUNT803-819 already drains registry readers before publishing smaller count; ordinary synchronous Scheme aborts precede old-cohort arrival. These reusable protections are explicitly distinguished from unguarded exported raw-pstate C and deferred fault consumers. No invented global lifetime framework.

Proposed native scalar io_use_gate/io_instance/wake_fault_code provide valid-owner admission, retry lifetime and sticky atomic first-error publication. Record before releasing incarnation, preserve errno/signal safety, no ordinary callback/GC/throw under T/M/P/V. Propagate fallback1466-1471 holds T; mutex unlock queues waiter before unlock3/M4044-4054. Inspection candidates: thread-intr after propagate before second lock, restored resume after T/P unlock, and mapped wait return after V unlock. Inspection is not permission to invent cancellation/reply or throw in an unrelated thread. Raw ___THROW is not a safe landing pad.

Retirement contract: stop route admission, release scheduler locks, final valid cancellation/matching select-return witness, close admission, drain exact old consumers/reuse existing grace, destroy fd resources, dispose tagged faults before instance reset. EINTR keeps its original borrow; no cached fd before pin or old errno report after reuse. Fault owner outlives fd when needed; later success never clears unresolved error. Permanent broken channel still has safety retention only. Raw-C admission/refusal ABI, owner-specific terminal fault landing pad, every cleanup/reset source path and full request/scheduler composition remain substantive source-refinement gates.

25 new checks:13 integrated fd/fault cases (2 conditional-completion,1 retained-fault safety-only,10 decoded negatives),4 source-quiescence cases (2 conditional-completion,2 decoded negatives),8 named TypeScript trajectories. Earlier narrower10-case run retained.30s/check,12 workers,1GiB/8MiB unchanged; no wall-clock/native inference. Prior24/44 models/receipts and measured failure obligation preserved. No runtime/header/compiler/Recipe/budget edit, native run/full inventory, peer operation, staging, commit or push. Native remains8/12.


Terminal-error addendum to the abort lifetime study: setup.c927-976 routes returned ___run errors to P0 through OP_PROCESSOR_0_THROW_ERROR/on_all_processors;1431ff raises SYNC_OP using the same interrupt/abort chain before the collective. Kernel4712ff raw propagate/THROW provides no second wake carrier. Therefore this existing path does not prove recovery for a permanently broken pipe plus sleeping peer; it can depend on the very wake it lacks. Four extra QNT controls (healthy completion, broken-wait decoded negative, retained-fault safety-only, hypothetical independent-carrier completion) pass original limits. Hypothetical carrier is explicitly not implemented or source-admitted. Total this turn29 controls;25-check receipt preserved. Minimum production scope must state live-fd/progress premises or separately prove another terminal carrier. No native failure trace/acceptance, runtime change or peer operation inferred;8/12.


### 2026-10-23 External-C owner/refusal and accepted-request disposition refinement

[Source study](smp-repair9-external-c-owner-disposition.md), external-c-owner-disposition-source-contract.json and verification status bind audit6b62a880, frozen d53671cb source and separately identified c_intf supplement. Raw pstate/TLS/SFUN marker is not a VM/instance lifetime grant; this generated SFUN header has no historical P sfun_frame_enter lease. Pure native queue submission may use a foreign host thread under a valid outer owner; Scheme-vector publication additionally requires matching roots/collector context.

Reused existing procedural-interrupt joined-owner source lock7a031c22, patch8e6d68b0, native program688de26d, model328c7874 and portable receipt34990c8f. This witness joins producers and detached consumer before cleanup; no valid-program concurrent destruction inferred. Current void enqueue promises no supported concurrent-refusal outcome. Therefore retain contract A for minimum repair; typed expected-instance admission/refusal is optional B with coordinated ABI/bridge/caller and extractor work. REJECTED retains unmodified caller node; ACCEPTED_WAKE_FAULT remains accepted and cannot trigger free/re-enqueue.

Source error path service_procedural_interrupts_pstate: lock/pop/unlock/callback(non-NO_ERR)/break/unconditional unlock, with no reacquire. This is a static invalid unlock attempt, not a native reproduction or the Scheme-flood first writer. Minimum correction is an outside-lock error return/cleanup, preserving remaining queue/service debt and never replaying or release(false)-disposing the already executed node. Cleanup release callbacks currently run under mutex; reentrant release requires a distinct outside-lock batch design. Correction to earlier narrative: actual native callback asserts op=false/readiness/counts, not mutex ownership. Lock-held release is source-derived, not directly tested; do not rewrite old observations or fixture expectations.

Actual nonprimordial target termination owns the mapped current frame and abandons owned BTQs; sender-side manual unlock/cancel is invalid. Primordial branch enters VM exit before that loop; remote thread-end and P0 collective reuse the same failed delivery chain, so no independent recovery inferred. Opaque/nonimmediate C callback return cannot be stored unrooted in a native scalar field; an immediate diagnostic normalization or real root owner is required.

New QNT admission/disposition specs and11 named trajectories are authored:33 planned TLC profiles (13 conditional-completion,3 safety-only,17 negative), not accepted checks. Production descriptor inode630123644 and kernel PID/start identities show live final consumer28333 in c86dff86; no signal/sample/debug/lock takeover or model load imposed. Verifier retains original30s/12-worker/1GiB/8MiB caps and refuses observed active production custody. Status awaiting natural lease release, verificationLaunched=false, no new PASS. Existing25/29/24/44 receipts and source-bound native witness unchanged. No runtime/header/compiler/framework/Recipe/budget edit, native run, full inventory, peer operation, staging, commit or push. Native remains8/12.


External-C verifier preflight actually returned waiting-for-production-custody in audit4242aae9; verificationLaunched=false, allAccepted=null, no Quint/TLC/trajectory process started. Source publicationec0ab649 hashes, prior verified models/receipts and reused joined-owner native evidence remain preserved. Pending verification is recorded in external-c-owner-disposition-verification.json; no runtime or native gate progress inferred.


### 2026-10-23 Accepted hard-failure terminal consumers and callback deferral semantics

[Focused source study](smp-repair9-accepted-hard-failure.md) and accepted-hard-failure-source-contract.json bind immutable d53671cb setup/kernel/thread sources. service_procedural_interrupts_pstate non-NO_ERR branch attempts an extra unlock, but its caller preserves intr_flag/STACK_TRIP and returns FAL. It does not deliver a Scheme exception or request VM termination. The minimum proposed correction is direct return err on the unlocked branch, with zero new fields/locks/ABI changes and no post-callback header access. Remaining queue service debt must survive; executed headers must not replay or receive release(false). No native reproduction/first-writer claim.

Ordinary matching target termination abandons owned BTQs; primordial exits before that loop. Jobs/wills detach batches, will action/testator are cleared before invocation; failure and recursive exit do not provide durable suffix/completion ownership. Raw ___run errors bypass normal marker kill; cleanup_checked resize failure retains resources, not successful cleanup. Last consumers include writer outcome publication, detached callback through service return/retry publication, pending release batch, mapped target reply/abandonment, VM callback suffix/error, all-path nonreturnable marker finalization and old cohort/root/resource closure. Same failed abort pipe plus remote thread-end/P0 collective cannot establish independent recovery of an asleep receiver. Fault retention is safety only.

New accepted_interrupt_terminal.qnt is a finite contract projection, not a refinement/composition proof:13 authored profiles (4 conditional-completion,1 safety-only hard-wake retention,8 negatives). It covers two accepted obligations, remaining service debt, forbidden replay, ordinary versus primordial abandonment, job suffix, writer/FD grace and marker nonreturnability. Guarded verifier preserves30s/12-worker/1GiB/8MiB limits and defers model execution while production custody remains live. No typecheck/TLC/trajectory PASS for new bytes; prior external-C profiles remain pending. No runtime/header/compiler/framework/Recipe/native/full-inventory/peer operation, commit or push. Native remains8/12; source refinement, independent progress/terminal policy and same-producer acceptance remain open.


Verification guard receipt: `.cache/tasks/repair-9-12/processes/audit/runs/d7ea260f96d744cdb0f8d99d4fe92f4b/outputs/accepted-terminal-checks/receipt.json`. `verificationLaunched=false`, `allAccepted=null`, no checker rows. Original task lock holders remain; no Quint/TLC process was started. Registered metadata publication eaaf7bc6 completed; model verification stays pending natural production release.


### 2026-10-23 Stability-first delivery domain and independent wait return

[Design and function map](smp-repair9-stable-delivery-domain.md) records the user-directed priority change: structural stability over minimum change scope, while runtime edits/native runs remain prohibited. The design unifies authoritative mailbox, runnable/park publication, independent wait return, fault-domain coordination and resource-specific last consumers. A finite internal native wait bound armed before every indefinite sleep is the source-mappable observation baseline; dedicated OS events/signals require their own race, lifetime, portability and embedding proof. No q value or production performance claim is selected. Symbolic idle cost is approximately N/q wake returns per second, not measured.

Source-specific corrections: ##wait! releases V but its devices caller still owns P; native/##wait return is not uniformly a lock-free exception point. Bare idle wait ignores error code. device_timer_select_virt treats timeout_reached plus matching state.timeout as ready, so blindly capping delta can cause early device deadlines. Preserve real deadline, classify internal recheck separately, finish condvar/P unlocks before fault dispatch. Existing scheduler-error report uses synchronous primordial thread-intr! and is not independent rescue. Heartbeat is masked around native wait. Old pipe closure needs its writer/selector/observer/no-repark cut; retained mailbox/frames/VM storage have later consumers and cannot be freed at that fd cut.

New independent_wake_return QNT projection has14 authored TLC profiles (4 observation positives/10 negative controls) plus5 named trajectories. It distinguishes fault-only arming, pre-wait signal loss, internal deadline misclassification, lock-held report, stale ack, early close, fault erasure, root loss, fake completion and second-channel failure. Terminal authority and real backend behavior remain explicit unimplemented premises; separate model receipts are not a composition theorem. Verification pending natural production-lease release, no new PASS. Prior accepted-terminal/external-C models unchanged and pending. Existing native8/12 and prior source-bound controls unchanged. No runtime/Recipe/framework/header edit, native/full-inventory run, peer operation, staging, commit or push.


Independent-return verification guard receipt: `.cache/tasks/repair-9-12/processes/audit/runs/56229298b8f543d6af3e6c731e1d699b/outputs/independent-wake-checks/receipt.json`. Production inode630123644 remains held by27204/27223/27230 and final consumer28333. `verificationLaunched=false`, `allAccepted=null`, no TLC or trajectory rows. No new model process launched; natural production release is still required. This is not a failed model check or a PASS.


### 2026-10-23 Repository-owned combined wait/fault/exit model draft

The current [combined model](../models/gambit/wait_fault_exit_composition.qnt) is now maintained directly in the SMP repository. SHA256 004fd9036cd72feaf859492fa800444d56ffc56ba9e9390c8ef6cc2749db2312. It combines native independent return, caller-specific P/device unlock, original deadline preservation, fault-instance acknowledgment, coordinator registration/queue/restore on P0, repeated GC including after a caught job error, suffix/root retention, opaque-unwind retention, invocation finalization and VM disposition. Five positive profiles (four conditional completion, one retention safety only) and18 negative initializers are authored, not executed or admitted. See wait-fault-exit-composition-verification.json. Model transition guards are implementation obligations, not proof that the current runtime provides them. Production lease still holds; no Quint/native execution or runtime edits. User now authorizes eventual implementation/closure in the existing work item, after natural exclusive custody becomes available. No new task, other-thread operation, commit or push. Native remains8/12.


### 2026-10-23 Concrete backend/coordinator implementation contract

[Function/field/ordering contract](smp-repair9-wait-backend-coordinator-contract.md) binds the frozen wait/scheduler source and separately captured mem/time/config supplement. Native waits need a typed internal outcome so capped native sleeps do not become real device deadlines or globally visible cleanup EINTR. Native ___device_cleanup also waits and returns on any wait error; group cleanup breaks on error then frees the group. This source-only error ownership boundary must be included in backend migration. A one-shot finite relative OS wait can avoid a new absolute monotonic cap; internal retry designs need the actual monotonic backend/frequency, not a function-name assumption.

The proposed coordinator is a registered, traced, P0-pinned root thread queued/restored by the normal scheduler after P/device/V release, not a Scheme callback invoked from idle C. Preparation precedes interruption shutdown/registry sealing; suffix/error roots survive GC after callbacks. Marker, raw-unwind, failed join and failed device-close ownership remain explicit. Combined model now has27 profiles (4 completion candidates,3 retention safety-only,20 negatives) and8 named trajectories, all unverified. New source implementation is now within user scope but cannot proceed while production custody is held; no runtime/native edit or execution performed. Native8/12.


Combined-model canonical files now reside in models/gambit and the verification runner in evidence/research/smp-retirement-study. Current27 profiles/8 trajectories supersede earlier unverified23/25-profile drafts; no earlier model PASS is transferred. Guard55d334ba deferred on live production custody, with no Quint/TLC/native process started. Current model SHA256 b04215d4d80e6110f91ca30565661e685736020b70417f109a9e029045048450. No commit or push performed.


### 2026-10-23 Isolated research commit and source-bound backend proposal

Committed only the combined model, eight trajectories, guarded verifier/status, implementation contract and selected Current Work/index additions: `8a2fdd34b7626c62178dbfe3e941a04b351d230a` (7 files), no push. Other working-tree content was preserved. Registered commit receipt392bb2b7 retains parent, exact path set and staged hashes.

A concrete backend source proposal is now saved at evidence/research/smp-retirement-study/prepared-independent-wait-backend.patch with source/prepared identities in the companion JSON. It uses a private native wait cap/outcome and separates internal expiry from real device timeout; native cleanup retains its existing uncapped entry until ownership migration. Candidate50ms is unqualified and is not a test-budget change. Audit5ca6966c binds a read-stable c86dff86 os_io source snapshot and checks patch application against that captured source only. No patch was applied to the producer, no compilation/QNT/native execution occurred. Hard-fault ownership, unlocked hooks, registered P0 coordinator, native cleanup/group retention and fault injection remain required.

Production lock inode630123644 remains owned by27204/27223/27230 and final consumer28333; PID/birth identity was verified read-only. No takeover, signal/sample/debug, other-thread operation, duplicate worktree, full inventory or new seal. Applying/compiling the source is still conditional on natural release and normal workspace.execution_scope custody. Native remains8/12.


### 2026-10-23 Actual combined QNT/negative/trajectory execution

The user explicitly requested direct testing now. Only the repository-owned QNT verifier was enabled in registered audit scope during the observed production lease; no production custody was acquired/bypassed, source applied, native program launched or peer operated. Earlier guard-deferred receipts remain immutable; the updated runner and its authorization receipt are separately hashed.

[Actual validation](../evidence/research/smp-retirement-study/wait-fault-exit-composition-validation.json) records27 TLC profiles plus8 selected TypeScript trajectories,35 accepted checks. Four safety/fair-completion candidates each generate61 states/42 distinct; opaque/join/native-close retention profiles have29/37/37 distinct states and safety checks only. All20 mutations have decoded distinguishing witnesses. Total checker/trajectory time179.227179s; original30s/check and12-worker/1GiB/8MiB caps retained. No separate typecheck command is counted.

The negative witnesses cover P-held coordinator claim, internal device deadline, original-deadline overwrite, unregistered/wrong-P0/duplicate coordinator, missing VM/frame/error/suffix roots, early shrink/private-work loss, stale wait ack, returnable marker kill, writer-active free, opaque fake exit and device-group early free. This closes the finite model experiment for these exact bytes, not source refinement: registration, independent return, caller unlock, invocation nonreturnability and private-work handoff transitions still need actual C/Scheme implementation and fault injection. The native failure generation, first-eight gates and native8/12 result are unchanged. Production lock remained held at final read; no compilation or native injection was run. No additional commit, staging or push.


### 2026-10-23 Shared takeover predicate and actual native wait backend

The production lock holders had naturally exited before this work; no signal,
lock-file deletion or peer operation was performed. `resume` and fresh
`execution_scope` now share `transition_check(..., takeover=True)` under their
normal exclusive kernel task lease. All registered process-role consumers are
checked, not just task-owned children. Task/process build directories remain
occupancy barriers; merely opening a cache evidence/agent request file does not
block takeover. Registered dependency occupancy, pending requests, quarantines,
unresolved spawn journals and prior supervisor/legacy group checks remain.
Finish and reclamation retain whole-cache occupancy exclusion. Source mutation
still requires its independent existing workspace lease and byte identity check.

The focused five-module regression completed 56 tests, exit0, no timeout,
32.021427s: audit97735572b3b24811b6ec911098c380db/outputs/takeover-regression.
Real subprocesses held metadata or task/process build files. Both entries admit
the metadata reader and reject build readers, the kernel lease and an actual
registered outstanding process group even when it holds only a metadata file.
The registered-consumer test additionally checks natural exit recovery. Earlier
failed validation receipts are preserved: the first launch inherited production
fixture identity; the second exposed an over-specific mock call-count assertion,
which was replaced by a real process-group test.

The original c86dff86 build directory received the previously byte-bound
`lib/os_io.c` delta through `sync_build_source` under its real workspace lease.
No sibling workspace, configuration flag change, new commit, staging or push was
used. Source SHA256 is685d6c8680de87c18de802e13b4be5884d86bd3a5c14a8f17e1b5fd66e75ac0e.
The original raw baseline returned only two of five bare waits before its3s
control deadline (exit-9); it is retained, not counted as a completed baseline.
The first relink failed with system-symbol errors because the driver inherited
Nix's linker PATH. Its configure proof establishes the original Homebrew/system
PATH. The continuation restored that exact recorded environment, rebuilt os_io.o
and relinked GSI, deducting previously consumed build/link time from300s/60s caps.
No old seal or source-core completion receipt was rewritten.

Actual native continuation21000c11630447e9b15f75c2d78a1791 completed five bare
waits with exit0 in0.678825s; the250ms real deadline control measured0.253873s
and exited0. The original user/device deadline remains distinct from the50ms
internal return slice. Native compilation and actual execution are now established
for this backend delta, unlike the earlier prepared-only proposal.

Native injectione385b1ec087a47a893d60cb49f7cbf8d used a Darwin interpose library
compiled with the same GCC, against this exact new GSI atp11. It targets one-byte
zero writes to nonblocking FIFOs, matching the observed self-pipe write operation;
it does not close descriptors or mutate runtime source. Both independent-return
and ten-thread GC/root-value/deadline controls exited0 for ordinary delivery,
one EINTR and persistent EBADF. Recorded injected failures were1/183 for the
independent-return EINTR/EBADF controls and1/1235 for GC/deadline EINTR/EBADF.
All six controls have actual hit counters, terminal markers and exit0; they are
not model booleans. The GC control performs30 collections, retains vectors across
waits, checks their values and verifies60ms waits are not completed before50ms.
These tests exercise scheduler progress under failed wake writes; they do not
instrument or prove every P-lock ownership cut or VM-exit root type.

Portable source/artifact hashes, receipt paths and per-control results are in
`evidence/research/smp-retirement-study/native-wait-backend-validation.json`.
The fault coordinator remains unimplemented. The backend returns independently
but `___device_select_abort` still ignores permanent write errors: rooted fault
ownership, Scheme dispatch after releasing native/scheduler locks, controlled exit and last-consumer retirement
remain required. A lost result-mutex node is a separate ownership defect; a finite
wait does not make it reachable again. Native qualification remains8/12. No
full inventory, Gerbil acceptance, unrelated thread action, commit or push ran.

Final regression receipt: audit71e3466c563945dc92d751643d9c3154/outputs/takeover-regression,
56 tests OK,31.832862s, no timeout. This run includes natural child exit followed
by successful resume and execution without state edits. Source changes were
reviewed with path-scoped diff and whitespace checks; own native driver children
are reaped. The exact new GSI SHA256 is
c9776a92a2e942d25464666c7e0e65e77d518a6ce58252cd320b1135d9a5cadd.
The incremental source remains phase=building/diagnosticOnly, not a new complete
source-core or runtime producer admission. `gsc` was not rebuilt and no complete
native/Gerbil acceptance is claimed.


### 2026-10-23 Applied unique-request delivery, fault coordinator and native marker retirement

The original c86dff86 producer now contains actual compiled runtime changes,
not a prepared-only proposal. The canonical cumulative seven-file patch is
`evidence/research/smp-retirement-study/owned-request-fault-coordinator-native.patch`.
Audit3e43f81ca03b4c68a866886260fea55e replayed it against the retained baseline
and compared every resulting file byte-for-byte with the current producer.
`owned-request-native-validation.json` binds all source/generated-C/GSI hashes,
receipts, decoded model controls and remaining admission conditions. Detailed
source-operation/state/last-consumer/model correspondence and costs are in
`owned-request-native-closure.md` in the same directory.

Requests now have immutable targets and one thread-owned intrusive link, with
separate fresh processor hints. Execution/reply/failure and continuation escape
retain mapped Scheme roots through publication/unlock. Ticket grant has an
actual acquire barrier. Native procedural callback errors return without a
second unlock, preserving the queued suffix. A sticky wake-fault state posts one
VM-rooted P0 coordinator outside scheduler locks, preserves callback/error/suffix
roots across GC, closes new public request/job admission, records recursive exit
intent, and prepares a failing native exit. Defining-module kernel hook setters
fix a real generated-C constant-folding omission observed and retained earlier.

Matched C/Scheme marker ownership is registered per processor with still-object
external refs. Normal/throw returns retire once; nonreturning worker OS exit
retires the outstanding owner list before cleanup. A returnable P0 marker refuses
cleanup before mutation of the cohort. Writer admission and close now use a
paired SC count/flag handshake; separate acquire/release atomics alone did not
establish its exclusion. This adds SC operations per abort and one native
allocation/free per C/Scheme marker. The independent50ms return slice remains
separate from actual user/device deadlines. No matched performance gain is claimed.

Final GSI SHA256 is1a32b364a5b421ea674db68b67e8219570cebfe2d2398a120fec2096a29aa184.
All final native controls used this same GSI under supervised run
bf4296759c0f4a20b2ef6c43dbb2ab54 atp11:1000 exact request/replies;40 nested,
migration and GC rounds;ordinary exception and continuation-escape release;
one EINTR and persistent EBADF/held-write/persistent EINTR injections;600 nested
C/Scheme callbacks with real collection;live-owner cleanup refusal preserving
cohort11;and8/8 rounds of100000 requests under12s each. Hard faults intentionally
exit70 after P0 preparation, ten worker marker retirements and zero writer,
selector and marker grace; injection reports active=0 and badclose=0. The actual
C procedural-error suffix/re-enqueue control passes. Raw pre-prepared unwind
produces retained-resources fatal exit70 with no false grace witness: this is an
expected refusal negative, not graceful recovery. Child processes are reaped
and groups quiescent in the retained receipts.

Combined owned_request_fault_coordinator QNT passed candidate safety/fair
completion and twelve decoded negatives in auditeedc727ed7434d9b9e04e95d5f5cb41f.
New writer_close_admission QNT passed SC safety and exposed the weak-order
negative in audit3e43f81ca03b4c68a866886260fea55e. This litmus abstracts weak
observations, not the entire C11 memory model. Prior parser/type/conversion
failures and native generation/compilation/fixture failures remain retained;
no failed receipt has been rewritten. A test-marker interpretation typo in
06382db... is preserved; the final run used the actual retained fixture marker.

Qualification remains8/12, runtimeAdmitted=false, source generation building.
No full inventory, new source-core completion, new seal, commit, staging or push
was made. Live native ingress still requires the host's valid VM borrow and
external publisher quiescence. Arbitrary nonlocal coordinator callback escape,
nonterminating callbacks, and device-group cleanup's pre-close unlink/free-on-error
ownership path are not certified by these wake controls. Complete native/Gerbil
acceptance and same-contract repeated9/12 receipts remain open. No peer process
or other work thread was operated on.


Final same-executable supplement: nativef3034e01144342f2907ffff3dad92bb6 passed
five independent returns and preserved the250ms deadline at252.415895ms.
Native4d758a9fd98746f3a317e12c872601b5 passed permanent EBADF and persistent
EINTR while an already-accepted interrupt thunk remained active and its sender
still waited for the result. Exit callbacks observed that pending sender and
rooted payload across GC; P0 preparation, ten worker retirements and zero-consumer
grace then completed with exit70. This is explicit VM terminal failure, not an
invented request reply. `owned-request-native-supplement.json` binds these four
checks and unchanged source/GSI bytes. Together with the final primary receipts
there are24 targeted controls, including expected failure/refusal negatives,
on one executable;15 QNT controls are separately retained. Qualification stays
8/12, and the open conditions above remain unchanged.


### 2026-10-23 Applied device-error ownership and callback-escape closure

The two previously open paths now have actual source changes and same-producer
native controls. This supersedes the earlier device-close ownership and public
winding callback-escape limitations; historical receipts remain unchanged.
`evidence/research/smp-retirement-study/device-callback-native-validation.json`
binds the six-file delta, source/generated-C/GSI identities, actual patch replay,
37 targeted native controls and the new nine-control QNT receipt. The delta is
`device-callback-full-closure.patch`, applied after the preceding1a32b364 GSI
source generation. It is not a new workspace, framework seal or completed producer.

Native device close errors are sticky immediate codes. A hard read/write/select
error keeps the node linked and its owning reference intact. Close success is
required before unlink; release failure restores a retained allocation/reference
and group link, without re-entering the partly executed release callback. Checked
group/module cleanup returns the error and preserves the failed node and untouched
suffix. POSIX file/pipe/socket device close uses one syscall attempt: EINTR cannot
authorize a second close of an ambiguously consumed descriptor number. A readiness
select EINTR after close returned EAGAIN is instead rechecked as a soft wait event.
The native EAGAIN control exposed this distinction and it was fixed in source.

The actual final consumer is not only the group: still-object Scheme foreign
wrappers may retain the device release callback. `___prepare_device_foreigns_vmstate`
walks those canonical wrappers under sealed/quiescent teardown, calls their
one-shot `___release_foreign` while every VM root remains intact, and checks each
result. Device group cleanup follows only afterward. Normal `free_still_objs`
then sees disarmed wrappers and cannot double-release. Any failure returns from
`___cleanup_checked` before processor/VM/GC memory destruction. The error state is
retained and cannot be treated as a successful cleanup or a resumable VM.

Each fault exit job/final will runs inside `##fault-control-callback!`, with a
mapped recovery continuation outside a per-invocation dynamic-wind guard. Public
outward continuation return/graft is intercepted by the after action, which
retires that invocation, records a rooted escape diagnostic/current item, and
returns to the coordinator's recovery point. The consumed prefix stays consumed;
the remaining cursor continues once. The guard's before action rejects retired
continuation reentry. Item, suffix and error remain VM-rooted through nested GC.

Final GSI SHA256 is60b1260d3369b97b5c5f2bc50f9d7b7b1afb74dfdbbe6fcc548746029b6dee03.
Nativeed884cbaefe34fdd84498e8f59446198 passed five local device cases (success,
read failure, write failure, EAGAIN, release failure), exit-job call/cc escape,
final-will continuation-graft escape, retired-continuation attempts, global
device-error retention and real Scheme foreign wrapper success/failure. P1-created
wrappers were retained across GC and actual retirement handoff: success releases
once; failure leaves the wrapper disarmed, native owner linked and VM root live.
Both callback lanes preserve the suffix/error across GC and reach prepared exit.

Nativeb8ffeb54c80741cabf669e13c1f35a19 interposed actual Scheme file-port close
syscalls with EIO, EBADF, EINTR-before-close and EINTR-after-real-close. All four
record one original close attempt. Replacement files remain usable and close
through their own legitimate owner. Permanent device failures deliberately exit70
with retained runtime resources. The same final executable also passed every
prior targeted request/wake/FFI/active-sender/deadline control, including8/8 rounds
of100000 requests atp11. The250ms deadline measured255.076885ms. These are37
targeted control rows, including expected fatal/refusal negatives, not37 full
inventory gates. All recorded parents were reaped and groups quiescent.

Auditc211afe312e241249e728c66409823ae passed candidate safety/fair terminal
disposition and eight decoded QNT negatives: early unlink, free-group-on-error,
forgetting a close error because stage is CLOSED, callback escape, stale callback
replay, roots freed before IO outcome, failed release freeing allocation, and
group release before the foreign last-consumer handoff. Terminal disposition
includes checked retained failure; it does not assert that failed storage is freed.

Earlier fixture compile failures, the invalid raw VM-field probe/SIGSEGV, the
incorrect thread migration name, and fd-number reuse misclassification remain
retained. The final probes use the generated STRUCTUREREF representation and
distinguish the replacement file's valid close from an original-device retry.
One active audit/model launcher correctly blocked a production takeover; it
exited naturally and production continued through normal custody. No peer was
signalled or operated on.

Costs: one immediate error word per native device, a sticky-error branch on close,
one linear canonical-foreign traversal per VM teardown, and winding/recovery
allocation per fault callback. No matched application performance claim is made.
These controls establish the two requested paths on the Darwin producer under
the live/quiesced host and public winding API contracts. Nonterminating callback
code and raw private no-winding/native jumps are not made generally recoverable.
Qualification remains8/12; full native/Gerbil acceptance is not run. Source phase
remains building/runtimeAdmitted=false. No commit, staging, push, unrelated source
change or other-thread operation was performed.


### 2026-10-23 Verification-only handoff: protected coordinator and final device/root regression

The latest user instruction assigns runtime integration to Grok. Verification
performed after that boundary did not modify or recompile runtime sources; it
only exercised the already-built experimental producer, extended QNT negatives,
replayed existing patches in an audit fixture and retained evidence. No message
was sent to another thread. No new commit, staging, push or full inventory ran.

Final experimental GSI SHA256 is7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808.
Build3fc0e6d6492844bcb7ae9de0c46282e0 finished the previously started coordinator
owner protection. `##thread-terminate!` and `##thread-suspend!` reject the active
fault control thread at their private entry, outside held scheduler/thread locks
and before consuming its lifecycle state. This is necessary because actual
`##thread-end-current-thread!` terminates/schedules without a winding transition.
The per-callback dynamic-wind guard alone could not protect that path.

Native run0435aab786604b139a320715f8535ec4 binds all39 targeted control rows to
that one GSI. Permanent EBADF and persistent EINTR each triggered actual public
self-terminate and self-suspend attempts. Each attempt marker occurred once; the
coordinator survived, processed the suffix, retained the actual refusal/error
and payload through GC, then reached P0 preparation, ten worker marker retirements
and zero wake-writer/selector/marker grace with deliberate exit70. These are real
invocations, not merely checking that guard source exists.

The same final executable passed device read/write/release failures, EAGAIN wait
recheck, real file-port EIO/EBADF/EINTR-before-close/EINTR-after-close injection,
exit-job call/cc and final-will continuation-graft escape/reentry, canonical
foreign wrapper one-shot release, and P1-created wrappers across GC/retirement
handoff. Failed close/release retains the native owner and VM roots and reports
failure before destruction. Successful wrapper release happens once. Every
original file close was attempted once; a replacement descriptor was usable and
was closed by its own owner. The earlier24 request/wake/FFI/active-sender/deadline
controls also passed on these same bytes, including8/8 rounds of100000 requests
atp11 and600 nested C/Scheme calls across GC. The250ms wait measured255.118132ms.

Audit51de1dacc83d4ec48713e651e5ce7ee3 passed the final combined model's safety
and fair terminal-disposition control plus ten decoded negatives. Separate
terminate-coordinator and suspend-coordinator initializers expose loss of the
unique carrier; foreign last-consumer and premature root/group/device release
negatives remain. Terminal disposition includes checked retained failure and
does not require incorrectly freeing failed storage.

`evidence/research/smp-retirement-study/final-device-owner-verification.json`
is the final identity/receipt index. Existing device-callback-full-closure and
fault-owner-guard patches were replayed together in an audit fixture; the result
matches all six changed source files byte-for-byte, while the four other prior
source identities remain unchanged. They are experimental evidence for Grok's
integration, not an instruction that integration or qualification is complete.
The function/ownership/root correspondence is in `fault-owner-verification.md`.

Conclusion: the two named gaps are closed within the tested checked-host,
canonical-device and public-winding/protected-owner contracts. Valid quiesced VM
ownership and finite callback/unwind bodies remain prerequisites; arbitrary raw
private no-winding/C jumps keep the previously tested cleanup-refusal boundary.
This is not complete native/Gerbil or 9/12 acceptance. Qualification remains8/12,
producer source phase building/runtimeAdmitted=false. Runtime landing belongs to
Grok; this verification does not grant admission or modify the other thread.


Verification-only strict owner supplement: native5f62b1bf99b443e9b092f0766b300109
individually caught and validated the actual lifecycle-admission error for each
public terminate/suspend attempt, then rethrew it to the coordinator's outer
catcher. Both refusal markers occurred once under EBADF and persistent EINTR;
the rooted suffix/error and P0 prepared exit still completed. This rules out
inference based only on survival or the last callback's error. The final live
index now points to these stricter owner rows plus the37 unchanged final-GSI
rows from0435aab786604b139a320715f8535ec4:39 targeted rows total. All ten source
identities, generated C/header and GSI bytes were rechecked unchanged at finish.
No runtime source edits or production compilation occurred in verification.


### 2026-10-23 Grok implementation and qualification handoff

`evidence/research/smp-retirement-study/grok-native-handoff.md` records the
function-level integration checklist, ownership/root/last-consumer invariants,
focused regression commands, expected negative dispositions and formal 9/12
requirements. Its JSON companion rechecks all ten source files, three generated
files, final experimental GSI, eight historical native receipt groups and QNT
model/receipt against the final verification index. No new native execution or
model run occurred. The current qualifier still returns admitted=false, 8/12: the
two actual lifecycle join-error/later-success campaigns remain necessary. The
39 focused rows and finite QNT controls do not replace that contract. Integration
belongs to Grok; this task updated evidence only, with no runtime modification,
other-thread operation, staging, commit, push or full inventory.


### 2026-10-23 Formal lifecycle 9/12: source recovery and error-trigger gaps

The evidence-only follow-up `evidence/research/smp-retirement-study/lifecycle-join-recovery-gap.md`
and its JSON bind the final c86dff86 experiment and five historical campaign
snapshots. Final setup.c only transfers/cleans after join success; failure returns
without a pending ledger or later-entry recovery, while cleanup retains a sticky
error. Recovery1/2 PASS banners were written from a pre-join refusal flag and
remain inadmissible. OS1/later1/wait2 each actually recorded DENY/exit2 and
(11 0 1 0 11 0), not an OS-error/recovery sequence. Historical recovery code also
has VM-global cross-donor witness attribution, joined-but-not-quiet rejoin risk,
and a recovery-only NO_ERR return that does not execute the requested grow.
The current probe ignores the first resize result; its native errno accessor is
absent in the final experiment. Pending allocations alone do not establish GC
coverage after population reduction. A legal OS-error trigger for the unchanged
exact error11→same-owner0 recipe is still unestablished; independent QNT joinFail/
joinOk steps do not prove platform reachability. Grok implementation steps and
formal preconditions now require that feasibility decision before two new native
campaigns, per-donor/epoch ownership, joined/drain separation, traced handoff and
collective result/reopen agreement. Qualification was read-only observed8/12;
no runtime code, native/model execution, other thread, commit or push changed.


### 2026-10-23 Darwin lifecycle feasibility: native error versus runtime pending

`evidence/research/smp-retirement-study/darwin-join-feasibility.md` and JSON pin
Apple libpthread42d026df5b07825070f60134b980a1ec2552dfee (not matched to deployed
host library), local SDK semantics, the final experiment and10 new QNT controls.
Branch inspection supports no native nonzero/non22→same-owner0 path for the valid
exclusive-owner/no-cancellation Gambit shrink graph. Normal join can begin before
worker exit and blocks to0; interrupted native wait is not returned EINTR.
A wider target-cancellation cycle can reach11→0 with the original owner alive;
it is modeled explicitly and is not supported retirement admission. Runtime
missing-ledger/root/retry defects remain separate. Proposed stable native reaper
ownership plus traced deferred-retirement status needs implementation, source
proof and explicit reviewed contract migration; pending is not an OS errno.
Registered audit7a0968cc922c4c05878d8b6cc457f23d passed10 controls: restricted
platform safety, deferred safety/fair completion, wider cancellation safety,
one decoded wider-API reachability witness and six discriminating negatives.
No new native experiment, runtime edit, other-thread operation, commit or push.
The39 targeted controls remain distinct; lifecycle count stays8/12, with GC/FFI,
Gerbil correctness and release gates independently open.


### 2026-10-23 Proposed pending lifecycle contract and fixed reaper obligations

`evidence/research/smp-retirement-study/lifecycle-pending-reaper-contract.md`
and its contract-proposal/verification JSON preserve the intended resource-safety
obligations while explicitly separating the infeasible Darwin OS-error trigger
from supported runtime Pending. Original slot/epoch storage lease, traced root
carrier and fixed native reaper join capability are distinct permissions. New
function proposals cover old-cohort Scheme preparation, native-only helper setup,
short-lock claim/release/acquire mailbox, survivor polling, post-join borrower
grace, one transfer/reclaim, and stop-ack plus host helper join before VM free.
Actual join errors retain/poison resources; Pending does not fabricate errno or
clear existing sticky cleanup. Deterministic worker-gate native acceptance must
show pending during repeated GC, exact-key actual join0, old payload preservation,
requested resize completion, and two independent campaigns on one completed
producer. Observer/recipe/run-binding migration remains separately reviewed, not
performed here. Original formal qualifier/recipe/probe/milestone/review hashes
remain unchanged and read-only qualification remains8/12.

Final audit model43705c28af854703b5583892d499748d passed16 controls under the
unchanged30s per-case cap: six safety/fair terminal-disposition cases (normal two
donors/two epochs, donor2 rollback, helper startup failure, mixed donor join
failure, notification loss, stuck worker retention) and ten decoded negatives
(early commit, duplicate join, wrong owner, stale completion, early reclamation,
lost pending roots, retained-VM free, Pending-as-errno, discarded mailbox and lost
prior-generation roots). Atomic preparation/grace/root coverage are explicit
refinement premises, not implemented C guarantees. Initial three missing model
action-block braces produced a retained parser failure10db91510e91488db3d351113792472f;
normal audit reconciliation checked its consumers before correction. The earlier
15-control passing revision is retained; all16 controls reran after adding old
generation roots. No runtime edit, native experiment, other-thread action,
staging, commit or push occurred. The39 targeted controls and other three gates
remain independent; no native/lifecycle admission was granted by these models.


### 2026-10-23 Reaper C root-domain and release/acquire refinement

`evidence/research/smp-retirement-study/reaper-c-root-publication.md` and JSON
bind13 current source identities and lay out five ordered patch units. Actual
___THREAD_SAVE can save a donor-stack frame; mark_captured_continuation copies
and updates it later, so old-cohort materialization is required before count
withdrawal/section reuse. Active-only still setup, RC marking and memory
accounting require a pending-native-owner GC domain with explicit collector/owner
helpers, real RC data-slot writeback, repeated still initialization and snapshot
leases. A VM-rooted Scheme vector does not trace native linked lists. Current
cleanup_interrupts_pstate calls execute_fn(intr,FAL), and the retiring tail
manipulates Scheme deque nodes after count publication: neither may be assumed
callback-free/native-only. Preparation must be outside the count-changing C
collective with rooted failure/rollback, and final transfer/domain removal must
be one GC-quiescent collective transaction after actual join and borrower grace.

Manual conditional C11/GCC publication arguments separate donor PREPARED→P0,
P0 READY→reaper and native DONE→P0, each matching release/acquire on the same
generation token. Payloads are not read before claim or overwritten during
consume, and DONE is the producer final record access. Lifetime/scan admission
uses one mutex-protected registry state and preexisting valid VM borrow, rather
than assuming release/acquire on separate count/closed fields solves admission.
Native helper join and reader drain remain prerequisites to free VM storage.
QNT auditdff3cbb76eeb49198dba63e0a40b6b9b accepted19 controls under original30s
case limits: candidate safety/fair completion across repeated GC/two epochs and
18 decoded negatives for publication/root/reclamation gaps. The prior17-case
passing snapshot is retained. Weak-view traces are a conservative abstraction,
not a full C11 execution theorem; non-atomic races can be undefined behavior.
Actual generated C/tracing/atomic implementation/native tests remain required.
Formal observer/recipe/probe/milestone/review hashes and experimental GSI7263fe03
remain unchanged; current qualification is8/12. No runtime edit, native execution,
other-thread operation, staging, commit or push occurred.


### 2026-10-23 Old-cohort materialization, rollback and native scan-domain transfer

`evidence/research/smp-retirement-study/retirement-materialization-domain.md`
and patch-plan/verification JSON bind13 unchanged runtime source identities.
The proposed functions/fields now separate PREPARING registration (still active)
from PENDING native list scanning, then receiver ownership after actual join and
grace. Frame materialization reuses the old-cohort captured-continuation GC path;
space failure can occur after forwarding, so abort restores current rooted
continuations, never pre-GC fp/register/fromspace bits. All-member ABORT_ACK and
reader grace precede carrier release or next epoch; consumed callbacks are not
replayed. Pending still setup goes before setup barrier, and actual RC header
data-slot marking goes before the INTERNAL strong-root barrier and closure.
Collector context is distinct from stable native owner pointers; snapshots hold
leases through all uses, with retained native memory accounted separately from
true live-object statistics. Count/domain commit and post-join receiver/list/
registry transfer need GC-excluding collective transactions, common results and
no Scheme allocation/callback/nested collective. MISC_MEM_LOCK alone is not the
required collector exclusion. The existing sync loop is a source basis, not a
proof that a new opcode and its deferred errors are already implemented.

Audit4f25433e671e4ddc883e023f1a299dc1 passed16 QNT controls at unchanged30s/case:
4 candidate safety/fair terminal scenarios (normal, donor2 failure, post-GC heap
capacity failure, join while scan lease remains) and12 decoded negatives for raw
frame commit, domain gap/duplication, missing RC writeback/second still setup, old
frame restore/prefix replay, premature abort-carrier release, scan-time domain
removal/free, missing receiver and early epoch reuse. Address versions/collective
transactions remain abstractions requiring C refinement/native evidence. No
previous model was rerun or receipt rewritten. Formal observer/recipe/probe/
milestone/review and GSI7263fe03 remain unchanged, current qualification8/12.
No runtime edit, native execution, other-thread action, staging, commit or push.


### 2026-10-23 Landing entry, consumptive ABORT and collective result refinement

The same c86dff86 experimental producer and gsi 7263fe03 remain unchanged.
The actual Scheme resize wrapper first migrates the initiator to P0; it does
not land every donor. Sync service can run under a held thread lock, and the
post-___run native service loop has no Scheme return. A preparation notification
must survive unsafe sites until a supported lock-free context, or fail before
commit. ___THREAD_RESTORE consumes the saved continuation. ABORT therefore needs
a once-only current-root restore claim and private ACK trampoline, with no user
release before common agreement. Rollback failure retains roots and its epoch.
The existing election retains losing requests; GC winning must not clear a
pending finalize. New finalize requires common result consumption and delayed
error propagation, including the currently resize-specific caller error path.
Fallible finalize checks precede an infallible transfer transaction; partial
transfer recovery is not proved.

Evidence: evidence/research/smp-retirement-study/retirement-landing-collective.md
and its source-bound JSON/patch-plan. New Quint/TLC controls:19/19 expected,
5 positive safety/fair-terminal scenarios and14 decoded negative controls,
original30-second per-case cap. Receipt: .cache/tasks/repair-9-12/processes/audit/runs/dd6b59430ebc48c7a6672dd7be9ea4e1/outputs/retirement-landing-collective-model/receipt.json.
A retained-fault terminal state is not successful recovery. No C refinement,
native execution, formal contract migration, other-thread operation, commit or
push occurred. Existing 16/19-control earlier model receipts were not rerun.
Formal read remains admitted=false,count=8/12; all5 formal inputs unchanged.


### 2026-10-23 Independent sufficiency review and recurrent-GC progress gap

The retirement design is not yet sufficient for native9/12. Contract migration
is a changed claim, not proof of the old OS-error retry sequence. Independent
review identifies finalize starvation under recurrent higher-priority GC, serial
reaper head-of-line blocking on a nonexiting donor, and incomplete member-context
classification. The finite landing model does not prove recurrent-GC progress;
retained failure is safety evidence, not successful recovery or availability.
Actual ___transfer_mem_pstate has no allocation/callback/error return: prefer
prevalidation then an infallible GC-excluded splice, adding a journal only if
recoverable post-write failures are introduced. Its still traversal is linear.
See evidence/research/smp-retirement-study/retirement-independent-sufficiency-review.md
and JSON. No model rerun or native execution, runtime/contract change, other-thread
operation, commit or push. Existing source and formal-input hashes verified.
Count remains8/12.


### 2026-10-23 Recurrent-GC service windows and independent join lanes

The proposed progress refinement replaces priority-only finalize with a fixed
post-completed-GC native service transcript before mutator resumption, plus a
quiet-time standalone request. Proposed unused opcodes are priority7/noncombining
(28) and priority8/AND(33); neither is installed. P0 consumes independent durable
results, skips ineligible donors and rotates one transfer candidate per window.
A serial reaper is insufficient for permanent blocked donor isolation: reserve
one fixed persistent native join lane per admitted donor slot before commit,
or refuse admission. This changes the prior one-reaper proposal and requires
contract review. VM helper pins and per-donor grace are separate: B may finish
while A stays rooted/pinned; whole-VM teardown cannot succeed with A blocked.

New QNT has cyclic recurrent GC requests (no finite-GC-prefix cap), action-specific
fairness, blocked A, retained A grace, native join error, preflight error and
capacity refusal.15/15 expected controls accepted:6 safety/conditional-progress,
4 explicit temporal lasso/stutter counterexamples and5 safety negatives. Model
parse and evidence-classification failures retained. Corrected classification
reuses unchanged TLC logs; no repeated model execution or budget enlargement.
Receipt: .cache/tasks/repair-9-12/processes/audit/runs/3912e46fe71742d4959a9776efeb4afe/outputs/retirement-progress-reclassified/receipt.json. Function-level plan, performance costs
and assumptions are in evidence/research/smp-retirement-study/retirement-progress-protocol.md
and retirement-progress.patch-plan.json. Native/helper shutdown, C refinement,
all-entry coverage, first-eight regressions and latency remain unproved.
Source/generated/GSI and5 formal input hashes unchanged; formal count8/12.
No runtime change/native execution, other-thread operation, commit or push.

Final source cross-check also found direct resize heap-guard GC at setup.c:1086.
The candidate must retain service debt through that membership transaction and
hand it to a stable surviving cohort; no unconditional collector-return splice.
This handoff is not covered by the new QNT. Conditional progress additionally
requires eventual lifecycle exclusion release. Evidence and patch-plan now mark
this explicit remaining C/refinement gap; no added verification claim.


### 2026-10-23 Resize-internal GC service debt and stable cohort handoff

VM-owned service demand/cut ACK is distinct from retained donor resource debt.
Direct resize GC at setup.c:1086 must issue demand before entry and publish a
common outcome before any local error branch; no domain transfer inside count/
heap mutation. Growth stability requires exact matching Ready1 for every current
member, not count publication or status!=0. Shrink donors never return to the
old call point. Use a shared elected/READY/completed-GC HANDOFF transcript, not
an extra barrier blindly appended to a local resize return. Proposed priority9
HANDOFF(36) is unused, not installed. Captured admission cuts block subsequent
resize overtaking; ACK covers only its snapshot, leaving later demand intact.
The snapshot can retain blocked A and service B without clearing A's roots or
ownership. Deferred Scheme arguments require typed rooted tokens and fresh
post-GC resolution. Precount failure hands preserved demand to the real restored
old cohort after ACK/grace. Current post-count create failure is fatal: retained
failure is not recovered/stable VM; recoverable growth needs staged native start
gates and staged root/owner proof not supplied here.

New QNT controls18/18 expected:6 positive safety/conditional-progress scenarios,
9 safety negatives and3 temporal loop/stutter negatives. Two nonwrapping resize
epochs include growth/shrink order, overflow/setup rollback, late demand and
post-count retained fault. Original30-second case cap preserved; no unchanged
model rerun or native execution. Receipt: .cache/tasks/repair-9-12/processes/audit/runs/f3b7d82b295f4de59621a0d7be989127/outputs/resize-service-debt-model/receipt.json.
Evidence: evidence/research/smp-retirement-study/resize-service-debt.md and
resize-service-debt.patch-plan.json. This is not C/refinement sufficiency or
unbounded composition proof. Source/generated/GSI and5 formal inputs unchanged;
formal count8/12. No runtime/contract change, other-thread operation, commit/push.


### 2026-10-23 Native-shell staged workers, abort prefix and reservation ownership

Do not stage full inactive pstates across old-cohort GC: ___setup_mem_pstate
assigns stack/heap msections, while setup_stack_heap_vmstate redistributes by
active processor_count. Candidate instead precreates native-only unbound shells
behind VM-owned keyed WAIT/GO/ABORT gates, with typed rooted startup arguments.
Split fallible native setup from the final GC-excluded empty-pstate reservation/
count commit. Only then release GO, bind TLS, enter startup sync, resolve current
rooted thunk and run Scheme/READY. Before GO, partial-create ABORT needs actual
created-handle join0 and exact resource-prefix cleanup. Ordinary cleanup is not
proved to undo allocator cursor/counter reservations. Add checked reservation
undo, not whole-memory rewind. Failed undo retains GC exclusion/resources; it
does not prove continued old-cohort GC. Raw procedural pstate publication needs
checked staged-slot admission before accepting work; generic callback cleanup
is not safe in the nonallocating interval. VM service watermarks persist across
retry with new keys; no service ACK releases still-retained native owners.

New model21/21 expected:8 positive safety/conditional-progress scenarios,11
invariant negatives,2 temporal loop/stutter negatives. Partial create, gate init,
setup failure retry at epoch2, gate timeout, retained join/undo/post-GO failure
are distinguished. Original30-second cap; initial parse failure retained.
Receipt: .cache/tasks/repair-9-12/processes/audit/runs/3d3908cc6eb9468dbafd2fb4025d54ac/outputs/staged-growth-workers-model/receipt.json. Evidence and function plan are
evidence/research/smp-retirement-study/staged-growth-workers.md and its patch-plan.
This remains conditional: native setup split, allocator/custom-hook undo, checked
publisher admission, real gate/async error handling, generated root/marker proof
and native regressions are absent. Post-GO Scheme startup failure is not solved
by precreating OS threads. Source/generated/GSI and5 formal inputs unchanged;
formal count8/12. No runtime/native/other-thread action, commit or push.


### 2026-10-23 Replace allocator reversal with private construction; close admission race

Concrete candidate decisions replace two prior prerequisites rather than adding
more compensation. Default allocator: privately inspect a checked unused2*k-node
suffix under old-cohort GC/allocation exclusion, initialize only unpublished
local views, then commit shared cursor/counts once or discard views with no
shared allocator change. Existing direct set_stack/set_heap helpers support the
local split; next_msection and its fallback are excluded from this constructor.
GC-dependent limits are finalized against committed accounting. Preclose/drain
short VM registry readers before ALLOC lock; refactor count publish to consume
that guard, not close registry while holding ALLOC. Native OS cleanup can retain
its control/VM pin after private memory discard without holding old GC hostage.

Request entry: exact owner/incarnation validation plus producer lease is atomic
under one short admission mutex; release it before actual queue locks. Closing
rejects new leases, preserves existing publishers and accepted queue/wake work.
Exported void raw-pstate APIs must migrate to checked leased interfaces; no
silent binary/client fallback is claimed. _kernel adapter/GSTATE/header entries
and native clients must move together. Existing _thread.scm first publishes
the primary node to a thread queue, then creates a separate high-level hint:
denial of that hint cannot undo the already accepted primary request.

New QNT23/23 expected:7 safety/conditional-progress,14 invariant negatives,2
temporal loop/stutter negatives. Covers partial construction, old GC resumption
with retained native cleanup failure, atomic lease versus close, accepted-node
ownership, stale generation, two-epoch retry/debt preservation and nontrivial
prior allocation counts. Initial incorrect postcommit-cancel temporal goal
retained as a failed receipt; correction records TOO_LATE and normal draining
rather than requiring an eventual fault. New source controls all rerun under
original30-second cap. Receipt: .cache/tasks/repair-9-12/processes/audit/runs/14e8c2d84b1443988aec06e48de05c7b/outputs/private-reservation-admission-model/receipt.json.
Evidence: evidence/research/smp-retirement-study/private-reservation-admission.md
and its patch-plan. These two default-allocator/checked-client protocol choices
are concrete; implementation/root/C11/native regressions remain to be done.
No universal custom-hook or unleased-client compatibility is claimed. Sources/
generated/GSI and5 formal inputs unchanged; formal count8/12. No runtime/native/
other-thread action, commit or push.


### 2026-10-23 Integrated private reservation, checked leases and staged workers

One QNT now composes native shell creation/parking, exact private-view ABORT,
count/scan commit, GO/startup GC/READY, checked admission, overlapping publishers,
queue/wake last consumers, retained native faults, service cuts and retry epoch2.
Concrete composition fixes: count commit cannot open public admission; release
transaction roots separately from native gate/handle destruction; denied hint
preserves already accepted primary request; post-GO failure cannot restore old
allocator/membership. Function/field/order and native fault acceptance checklist:
evidence/research/smp-retirement-study/integrated-growth.md and patch-plan.json.

Final30/30 expected controls:9 safety/conditional-progress cases,18 decoded
distinguishing safety negatives,3 liveness negatives. Every case under original
30s cap. Final receipt: .cache/tasks/repair-9-12/processes/audit/runs/93375c6a60ea468297705dbebe4a619f/outputs/integrated-growth-model/receipt.json. Initial26-case receipt219ebc3392ea41d4922cc49cbac908ff retained but superseded; all30 cases reran
after separating carrier/control ownership, adding startup failure and requiring
VM-owned independent join/cleanup lanes to survive oldResume. Model
fairness is not an OS completion or performance guarantee. Native control remains
retained for a stuck join/close; old GC and unaffected lanes may progress.

Independent verdict: executable finite composition supports this protocol; no
C11/generated-frame/native closure or formal9/12 claim. Implement actual registry
guard/GC-excluded commit, GO and READY release/acquire, typed-root handoff and
checked API migration in this order, then run paused-boundary/prefix-fault/epoch/
request/debt native controls on one completed producer. No new native runner
claimed to exist. Saved observation contains9 changed source/generated files (initial precheck8); they drift from previous baseline; 5 formal contract inputs unchanged. Initial precheck saw the old GSI, but later
forensic observation captured replacement c65582f4ee491eaa4bcc7d40562b02a7b9116f40f21f93a4cc1ced7fa5c713ac.
User reports this linked GSI exits71 and old7263fe03 bytes were overwritten; no
new native run was performed by this audit. Per-file forensic copies in
audit bad1e9aa8d7d47e2a1304a6225f6f2ae are not a coherent source generation or a
compilation witness. Helpers are present but observed grow still creates workers
after count publication and setup opens request admission before Scheme READY.
Constructor OR membership check/pair reuse and remaining raw-void/forwarded-hint
paths require the concrete corrections in the handoff. Counter8/12. No runtime, full inventory, other-thread action,
commit or push; observer/recipe/milestone unchanged.


### 2026-10-23 Bootstrap admission exit71 attribution and concrete prerequisite

User-provided native debugger trace: main_char→main→setup+236→interrupt setup;
P0 vmstate null, computed id3360434, IMPL_LIMIT_ERR fixnum0xffffffff0e000010,
exit71. Saved setup.c383/736/5380/7291 and header threaded VM accessor/processor-id
pointer subtraction agree: early bootstrap uses identity established only later
in setup_pstate. main.c negative-error mapping confirms OSERR. Mutex UNKNOWN_ERR
fixnum differs; cleanup-phase refusal precedes the observed point. Separate
gcc-16 unresolved-libSystem direct-link failure cannot explain an already mapped
process entering main. Dynamic lookup is not thereby certified as production fix.

Grok sequence: explicit known live VM/slot identity before every lookup; prepare
native resources and admission CLOSED; reuse exact bootstrap record through P0
setup; Scheme READY then synchronized OPEN; exact prefix cleanup without later
identity/OPEN assumptions. Never null→slot0 alias or widen slot bound. Focused
startup/init-failure/invalid-owner/repeated-setup controls specified, not executed.
Evidence: evidence/research/smp-retirement-study/bootstrap-admission-regression.md
and JSON. Integrated30-case QNT assumes valid identity and does not certify this
bootstrap order; no unchanged model rerun/new native pass. No runtime/thread/
observer/recipe/commit/push operations; formal count remains observed8/12.


### 2026-10-23 Bootstrap identity/failure/reuse in the unified growth QNT

The same integrated_growth.qnt now starts from unbound bootstrap identity, then
explicit known VM/P0 validation/bind, native resource CLOSED preparation, Scheme
root/READY establishment, READY-before-OPEN rejection, and OPEN admission before
every prior growth/reservation/lease scenario. Added partial slot/proc/late init
failures, exact reverse prefix cleanup, retained cleanup failure, repeat setup
refusal over CLOSED/OPEN/DRAINING/retained, and clean failure/normal teardown to
epoch2. Failed checked OPEN after Scheme READY retains roots through original
C/Scheme return before cleanup; optional abstract GC may interleave.

Final53/53 expected controls:21 conditional safety/progress scenarios,29 decoded
safety negatives,3 liveness negatives, all below original30s/case. Receipt:
.cache/tasks/repair-9-12/processes/audit/runs/d2420daa2c3e434194e10e13539c6ad3/outputs/integrated-growth-model/receipt.json. Initial51-case receipt9cf6639a39234b5ca26a782db18f26c4
retained but superseded after OPEN-failure/return-root review; all53 reran.
Grok function order and focused native startup controls are in
evidence/research/smp-retirement-study/bootstrap-unified-protocol.md and patch-plan.
Concrete READY distinction: worker startup-complete dispatch requires target>0;
P0 needs a separate checked scalar certificate at SMP startup-threading tail,
after fault-control-make roots, not a no-op worker call or early native OPEN.

Model bootBorrow means aggregate last consumer, not producer0. One valid VM
identity/two epochs/abstract resources and supported C return are finite proof
assumptions; generated frame maps, native atomics, full initialization side
effects and arbitrary multi-VM/host pointers remain outside this result. No
new native run, runtime change, other-thread operation, commit or push. Existing
user-supplied exit71 attribution and linker distinction remain intact; model
passes do not certify mutable source/GSI binding. Qualification read:{"admitted": false, "count": "8/12", "closed": null, "runsOk": false}.


### 2026-10-23 Explicit setup ticket, original marker authority and P0 READY

The saved per-file source observation shows the earlier guard must be independent
of vm_list_mut, which is initialized inside ___setup. The Darwin/POSIX header
already provides PTHREAD_MUTEX_INITIALIZER. A process-lifetime short guard and
persistent registry record must reserve authority before setup/cleanup globals
or ___setup_vmstate's marker reset. The public wrappers refuse concurrent or
same-thread recursive fresh entries; private prepared helpers explicitly carry
instance/incarnation/nonce/stage across VM/P0 setup. No stack record or ambient
TLS owner supplies a retained failure's lifetime or a nested callback's authority.

___setup spans the original ___run invocation. The proposed native setup-context
borrow therefore belongs to its original marker scope, not just until READY.
Ordinary run/SFUN entry has no setup right; common marker retirement releases
the optional borrow exactly once on supported return/error/nonreturning owner
exit. The independent checked P0 READY landing is the SMP startup-threading tail
after fault-control-make, outside VM/P locks; worker READY excludes target0.
Root establishment precedes READY and separate OPEN. OPEN failure must return
through the original supported boundary with mapped roots and context retained.
CLEAN plus all final consumers permits fresh nonwrapping incarnation/nonce;
OPEN itself never renews a key. A private C helper is an internal discipline,
not protection against arbitrary native corruption or forged internal calls.

Same unified model:69/69 expected controls,28 safety/conditional-progress
positives,38 decoded safety negatives,3 liveness loop/stutter negatives. All
earlier53 controls reran on these bytes. Original30s/case cap unchanged; max
23.584s. Receipt:.cache/tasks/repair-9-12/processes/audit/runs/a6550d55c63749bfb2ad2a6241cf7989/outputs/integrated-growth-model/receipt.json.
Grok function order, lock/publication order, fields, failure-prefix and focused
native acceptance are in evidence/research/smp-retirement-study/setup-ticket-propagation.md
and its patch-plan.json. Guard on rare setup/cleanup only; ordinary requests
retain slot-lock fast path. The current collective resize setup_pstate call
needs an explicit staged transaction continuation, not a new lock-held public
setup wrapper. Multi-VM registration, native atomics, generated C frame maps,
unsupported host escapes and callback termination are not proved by this graph.

Read-only qualification:{"admitted": false, "count": "8/12", "closed": null, "runsOk": false}. Native count/contracts unchanged.
No runtime modification, native/GSI execution, full inventory, other-thread
operation, commit or push. The source snapshot is not a certified producer
binding; historical overwritten binary results are not inherited.


### 2026-10-23 Generated P0 root boundary, native tail and lock-lifetime publication

Saved generated _thread.c L9 calls fault-control-make with return L10; L10
currently returns VOID. Actual startup RETN maps are fs1/link0/map0x1; a new
helper requires regenerated descriptors, not copied constants. PW_ALL defines a
register set but is not an executed spill. The no-cleanup error bridge directly
propagates a scalar fixnum without explicit W_ALL at that generated site; it
is not evidence for an arbitrary GC/reentrant helper. Keep the new helper scalar
and non-GC, use a reviewed generated CFUN/save-RA/W_ALL/R_ALL context, and throw
only after native unlock and temporary entry-borrow return. Same-VM moving GC
belongs at actual compiler safepoints with live roots and reload. Final host
macros/register caching and absent-helper generated C are not yet certified.

Marker0 is not the last native reader: saved retire-all diagnostics read VM
fields after the final decrement, and setup.c1428 retires markers before OS
cleanup/thread_exit. Worker same-owner join0 and P0 outer-owner/native-tail
pins remain independent. Current cleanup does not destroy request-slot mutexes;
it does destroy procedural mutexes. Keep request-slot lock process-lived where
possible. New checked native-entry borrows protect registry/VM/destroyable
resource lifetime; validate key/phase/producers under slot mutex. No overlapping
guard/slot locks: borrow under guard, lock/validate slot after guard release,
return borrow only after last native access. Slot tuple release precedes registry
admission release; observer guard acquire/borrow precedes slot acquire/recheck.
This supersedes the earlier nested-lock and one-slot-only cost suggestion.
Conservative external acquisition adds two short guard sections plus slot lock.

Same unified QNT final84/84:32 safety/conditional-progress positives,49 decoded
safety negatives,3 temporal loop/stutter controls; original30s/case cap retained,
max23.334s. All69 prior scenarios reran after correcting bootReturn record erasure; the old69 result is not sufficient for that failure-return claim.
Receipt:.cache/tasks/repair-9-12/processes/audit/runs/1b0f52afa2a545799b249c516b38b664/outputs/integrated-growth-model/receipt.json. Four prior expanded/grouped compile batches hit
unchanged20MB JSON-string limits before state checking; failures remain. Superseded partial batches are also retained, including the original30-second timeout and the pre-correction bootReturn record reset. Final
per-case compiler inputs erase only unreferenced alternate initializers and
false immutable-bug branches, with explicit structural premises, hashes and
84 byte-exact projection reconstructions in this handoff audit. No invariants,
fairness, reachable negative branch, native limits or timeout were weakened.
Grok concrete functions/root maps/lifetime ends/native tests are in
evidence/research/smp-retirement-study/generated-root-handoff.md and patch-plan.

Read-only qualification:{"admitted": false, "count": "8/12", "closed": null, "runsOk": false}. Models still assume atomic
locks, real root-map correctness, complete native consumer accounting and fair
service; they do not prove C machine ordering, arbitrary host callbacks/escapes,
full cold topology or new native9/12 acceptance. No runtime change, native/GSI
execution, full suite, other-thread operation, commit or push.


### 2026-10-23 Processor shrink lifecycle contract review (inactive)

The historical smp-retirement-study namespace concerns withdrawal of individual worker generations during SMP shrink; it does not deprecate SMP. See docs/smp-processor-lifecycle-contract-review.md and the companion processor-lifecycle-contract-review.json for the explicit old-to-proposed obligation matrix, source-anchored Grok implementation order and two future native campaign designs. Pending completion and real OS-error retention remain distinct; assigning a fixed native join lane does not retroactively satisfy the old same-P0-owner error-to-zero event. Independent pre-reserved lanes and mandatory post-GC service replace the insufficient older serial-reaper assumption.

The new lifecycle_contract_review.qnt supplement passed 2 safety/conditional-completion controls and 12 decoded distinguishing counterexamples under unchanged 30-second case limits (maximum 5.753 seconds); receipt: .cache/tasks/repair-9-12/processes/audit/runs/abdf3e3d54a7499bb87a0df321ee4042/outputs/lifecycle-contract-review-model/receipt.json. The first parser failure is retained, not counted. The supplement is not a combined C/GC/atomics proof or two native executions. Source observations remain per-file, not a certified final producer. No native campaign or runtime/observer/recipe/milestone/historical-receipt change occurred. Qualification re-read remains 8/12, admitted=false; old6/12 and8/12 history and three other open gates remain unchanged. No peer operation, commit or push.


### 2026-10-23 Post-join transfer and checked empty-donor finalization

New per-file stable c86 observations are retained in .cache/tasks/repair-9-12/processes/audit/runs/9a03f325fe6d44c8822ade738df7c474/outputs/post-join-transfer-observation/receipt.json. They show join0 followed by worker-tail decrement before transfer; an independent finalizer/VM borrow must cover the remaining work, while outer_owner and other current guards mean premature-free is not established by this ordering alone. No coherent completed source/generated-C/GSI binding or native smoke receipt was certified. User-reported boot-p1 and four-thread p11 exit0 remain separately attributed.

The actual mem.c transfer contains still/RC pointer splices and accounting without allocation or callback. Conditional non-failure needs valid closed ownership, checked lock/preflight, GC exclusion and no mid-unit escape. Generic cleanup clears still head before invoking foreign release, can lose suffix ownership on escape, and discards scan-lock destroy outcome. Use checked empty-donor finalization; preserve a per-resource native ownership/accounting journal at complete-unit boundaries, roll forward after partial success, and retain native quarantine on destruction failure. Scan-domain removal is distinct from lifetime-registry removal. Unknown unlock or mid-splice C fault has no automatic recovery proof. See evidence/research/smp-retirement-study/post-join-transfer-protocol.md/.json for function-level Grok steps and future focused native controls.

post_join_finalize.qnt:6 safety/conditional-disposition candidates and12 decoded invariant mutants met expectations under unchanged30s/case (maximum 11.596s); receipt .cache/tasks/repair-9-12/processes/audit/runs/b148d68cd33144fbaef42044852c4e6d/outputs/post-join-finalize-model/receipt.json. The initial verifier map/set-decoding exception is retained, not counted as a counterexample; the QNT model was unchanged. This finite atomic-unit model is not C pointer/GC/ABI/native proof. Qualification remains8/12; protected observer, recipe, milestone and historical receipt inputs are byte-unchanged. No runtime, native execution, peer operation, commit or push.


### 2026-10-23 Finalizer/tail lifetime handoff and shared-lock failure boundary

Source-bound follow-up: evidence/research/smp-retirement-study/finalizer-tail-handoff.md/.json. Use one pre-registered keyed retirement-resource pin from acceptance to reclamation; claim finalizer before consuming exact donor tail, without dropping/reacquiring the lifetime pin. Aggregate tails are not finalizer debt. The observed vm_native_consumers_clear checks wake writers/selectors and sfun markers but lacks the proposed ledger; teardown must check shared per-VM debt before the first destructor, not merely setup_publish_clean afterwards. Raw RC/still mutation functions do not themselves acquire misc lock, so external mutation quiescence remains a real native premise. These source findings are not reproduced native failures.

Known refusal follows the common result/ACK transcript. Donor-local cleanup quarantine permits independent donor progress only after shared common exit and a proven dependency cut. Unknown shared guard/misc/sync unlock cannot use a possibly broken barrier or Scheme coordinator; current fatal_error invokes host/display and exit() hooks. The proposal adds a separately reviewed callback-free raw process termination branch. It is process-fatal, including embedding-host compatibility cost, not successful recovery. The previous post_join_finalize unknown-unlock terminal proved retained exclusion, not actual termination.

finalizer_handoff.qnt met22 expected results:8 candidates (1 whole cleanup,4 retained dispositions,3 process-termination dispositions),12 decoded safety counterexamples and2 temporal stutter counterexamples for waiting on a broken barrier/host hook. Original30s/case cap unchanged; maximum 16.777s. Receipt:.cache/tasks/repair-9-12/processes/audit/runs/484370ae8e7a4acc96a70e88d4903f30/outputs/finalizer-handoff-model/receipt.json. No native execution, coherent new producer binding, runtime/observer/recipe/milestone/historical-receipt change, peer operation, commit or push. Qualification re-read remains8/12/admitted=false.


### 2026-10-23 Source review of implemented pin/finalizer slice

See evidence/research/smp-retirement-study/implemented-pin-review.md/.json and the per-file4b8ae711 observation. The local pin/JOINED/claim/tail-token sequence and direct _Exit are present. Full VM/incarnation/epoch identity, sealed enrollment/destruction admission, receiver publication, final reader grace and nonblocking borrower checks remain source-refinement obligations. A newer observed setup.c contains a post-GC epilogue; this does not prove it was included in the user-reported objects/archive, and gsi was reported not relinked. donor_borrowers_clear still takes blocking guard/slot locks inside that epilogue. No native race/deadlock was reproduced. Existing22 model passes are not source admission; no unchanged model or native test reran. User-reported GC/FFI transport failure launched no suite child. Protected inputs unchanged; qualification8/12. Evidence only, no runtime/peer/commit/push.


### 2026-10-23 Four-gap finalizer integration protocol and combined model

See evidence/research/smp-retirement-study/finalizer-four-gap-protocol.md/.json. Full K is per VM, not a process-global slot. A single atomic phase/count word must carry reservation, accepted resource pin and derived service/reader units: closing rejects new root enrollment but lets existing debt drain; destruction CAS requires DRAINING,0 before any destructor. Reservation->pin is ownership conversion with no decrement/reborrow gap. CLAIMING gives one writer time to initialize receiver/ticket before release OWNED. Cohort checks use stable closed-gate certificates or try-only checks and common EMPTY/DEFER/result ACK. Service ACK is not resource reclamation.

Final combined QNT met28 expected controls:10 candidate scenarios,17 decoded safety counterexamples,1 temporal stutter counterexample. It includes two VMs sharing slot1, repeated epoch, close/enrol races, receiver publication and derived service units outliving the resource pin. Original30s/case retained; max 18.118s. Receipt:.cache/tasks/repair-9-12/processes/audit/runs/1b2361181b3a4ed7bbf8558d3576eff6/outputs/finalizer-registry-composition/receipt.json. Compiler inputs erase only provably unreferenced initializer declarations; all28 are reconstructed byte-for-byte at publication. Preserve the narrower25-control predecessor and the strengthened compile-stage30s TIMEOUT; neither is substituted for the final stronger result. This remains finite atomic protocol evidence, not C11/GC/native proof.

Independently read lifecycle-boundary-current-2: engine1dbcb6237581fd1cceb1c30715cd104eb68404000c80580e4a95552f96c877c7, outcome/childOutcome DENY, exit2, timeout=false, runtimeAdmitted=false. Source materialization is DENY for source revision drift; configure/seed/core/join-probe are BLOCKED and the verdict is DENY. No join probe executed. Source lock requires7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882; vendor HEAD8d2b40341a80083ba90e3f8e77d256d49b3e257a is attributed to user report and was not moved or independently read by this audit. This is not a join failure or same-owner success. Qualifier remains8/12. No runtime/observer/recipe/milestone/historical receipt edit, native execution, peer operation, commit or push.


### 2026-10-23 Admission word, last consumers, ABA and destruction funnel

Evidence: evidence/research/smp-retirement-study/admission-lifetime-aba.md/.json. Reviewed immutable 4b8ae711 per-file source, not a coherent native producer. Concrete gaps: destroy_admit is a snapshot rather than atomic close/enroll exclusion; exported pstate and raw memory destructors lack a shared destruction capability; cleanup_interrupt_resources_pstate reads producers and writes CLOSED outside the slot lock after close. The proposed fix uses bounded process-lifetime registry cells, nonwrapping VM and entry generations, token validation plus gate acquisition before VM dereference, one SC phase/count word, last-use-before-release, and an exclusive destructor ticket propagated before the first destructive call. Constructor aborts require proof of nonpublication and initialized-resource masks. Parent units cover asynchronous service/readers through their last access; a native count is not a Scheme root. Global OS/IO teardown needs its own sealed aggregate authority.

New token/gate/entry/destroy/same-address-reuse QNT boundary refinement met 12 expected controls: 3 candidates and 9 decoded invariant counterexamples; original 30-second case caps, maximum 5.935 seconds. Receipt: .cache/tasks/repair-9-12/processes/audit/runs/bd5f6b2c8760492d8bb6406f86cb9be5/outputs/admission-lifetime-aba/receipt.json. All 12 compiler inputs independently reconstructed byte-for-byte; erasure only of unreferenced initializers. This complements, rather than syntactically merges, the preceding two-VM/repeated-epoch 28-control composition. It does not prove C11 executions, all callback/foreign roots, all configured destruction callers or native completion. Grok steps and targeted native schedules are specified; no runtime, qualifier, recipe, milestone, historical receipt edit, native execution, other-thread operation, commit or push. Qualification remains 8/12; latest boundary join probe remains unexecuted due to source drift.


### 2026-10-23 Async ownership, generated roots and destruction caller closure

See evidence/research/smp-retirement-study/async-destruction-callers.md/.json. The retained inventory binds 19 immutable per-file inputs (18 selected files plus matching older generated-boundary header), 101 lexical occurrences and 4 cleanup function-table occurrences. Latest setup/mem are from 4b8ae711; c_intf/generated _thread/Scheme _thread from 9a03; remaining OS/kernel files from bad1. These do not form a certified coherent producer or complete configured/external call graph.

Newly explicit mandatory stage: prepare callback work under live ownership and traced roots before terminal destruction. free_still_objs clears its list then calls arbitrary foreign release; release_foreign consumes callback fields before invoking it. A zero admission count followed by generic callbacks cannot be treated as callback-free cleanup. Procedural disposal likewise invokes execute_fn under its queue mutex. Rooted/unlocked preparation, one-invocation result/escape records and retained suffix debt must precede exclusive empty-native destruction. Review also records void publish/release/IO status propagation and nested P0 destructor completion masks.

The newer saved _thread.c actually executes W_ALL/READY/R_ALL at 22313ff, then status branch and generated return; earlier READY-absent bytes are not substituted. retire_sfun_stack_markers performs VM fault/logging reads after marker0, so caller/donor/service ownership must outlive marker/helper release. No proven post-release UAF is inferred without checking enclosing ownership; no native binary binding is claimed.

Concurrent async_destruction_composition.qnt met 12 expected controls:3 safety candidates (normal, escape, retained callback),9 decoded invariant negatives. Normal/escape each explore84 distinct states; retained48. Interleavings include publication, close, dequeue, callback result/escape, caller tail, two abstract moving GCs and nested teardown masks. Maximum 5.343s under unchanged30s/case; receipt:.cache/tasks/repair-9-12/processes/audit/runs/3201b8c287b74c7b8a87c354967ab73b/outputs/async-destruction-composition/receipt.json. Compiler inputs independently reconstructed12/12. This is safety-only boundary composition, not all predecessor models merged, C11 memory proof, real frame-map proof, callback termination or native9/12. Focused native sequence is documented for Grok, not executed. No runtime/qualifier/recipe/history/peer/commit/push change. Qualification remains8/12.


Tree-wide follow-through: audited 1571 c86 C/header/template/Scheme files including ignored/hidden paths, 9 files matched nine top-level cleanup symbols; saved all matching bytes and rechecked all file hashes/file set. Extra callers lib/main.c:1363, tests/client.c:85 and examples/pthread/pthread.c:129 directly call ___cleanup and require the checked public/embedding policy. Receipt:.cache/tasks/repair-9-12/processes/audit/runs/979baf74a5c24947a433121369ad7311/outputs/async-destruction-tree-callers/source-observation.json. This is read-only source evidence, not a coherent producer or configured/external-host closure proof.


### 2026-10-23 Callback preparation entry, nested roots and forward-only recovery

Evidence: evidence/research/smp-retirement-study/callback-preparation-protocol.md/.json. Existing ___prepare_device_foreigns_vmstate in saved4b8ae711 mem.c:4819 handles only canonical device release and returns errors before still freeing; it is not absent or a generic callback ledger. The rooted fault coordinator and continuation guard in saved9a03 Scheme/generated C are reusable mechanics but have singleton item storage and terminal-exit policy. Generic preparation needs a checked mapped/host entry, separate nested active frames, full-K operation/nonce/affinity and root-before-detach ownership. Invalid C contexts refuse before mutation; worker-bound preparation precedes shrink commit rather than being invoked from service_sync_op.

___release_foreign clears fn/ptr before invocation: error/escape does not authorize replay or pointer restoration. Preserve unresolved job/root/parent/suffix and continue only proven independent never-called work. Partial native teardown uses monotone per-resource masks, retrying a known unfinished BUSY unit only; unknown side effects retain/quarantine or terminate. Arbitrary C unwind/blocked callbacks remain outside supported completion guarantees. Existing device cleanup can wait/select at infinity; preparation must inherit real deadline, not reset/expand limits. GC sweep foreign release and the generated raw _kernel call need explicit native-only vs deferred/mapped callback policy and compatibility tests.

callback_preparation.qnt met14 expected safety controls (4 candidates,10 decoded negatives), max7.602s under unchanged30s/case. Safety receipt:.cache/tasks/repair-9-12/processes/audit/runs/e613b45fb6cc4df38de8d8f12e7f33fd/outputs/callback-preparation/receipt.json. Two additional decoded existential completion witnesses cover Normal and PartialRetry after two abstract moving GCs and metadata reader grace, once-only parent/child and P0/VM, final root/owner release; receipt:.cache/tasks/repair-9-12/processes/audit/runs/c7a2d18d6b6048e49b5779fa0c9b7032/outputs/callback-preparation-completion/receipt.json. All16 compiler inputs independently reconstructed; completion adds only a pure observer, no action changes. This is not C11/frame-map/native proof or liveness. No runtime/qualifier/recipe/history/peer/commit/push change; count remains8/12.


### 2026-10-23 Sweep callback classes, will resurrection and checked C preparation

Evidence: evidence/research/smp-retirement-study/sweep-finalizer-context.md/.json. Saved mem.c distinguishes strong/weak marking, process_wills testator retention, then sweep free_unmarked_still_objs; Scheme ##gc-finalize!/##will-execute! executes after GC and clears will fields before action. The source-bound manual excerpt specifies at-most-once foreign release per wrapper, released/address0 after invocation, explicit release and GC release. Recommend audited bounded native-only inline callbacks and explicitly registered deferred classes using existing wills; do not transparently defer every legacy release or let internal actions strongly capture their testator before weak selection. Released wrapper resurrection cannot restore native pointers/re-arm release. Native pointer loans, callback module lifetime and multiple user-will ordering remain explicit C/ABI obligations.

Checked C entry refuses bad token/owner/context before mutation; an opt-in fresh private ___run requires the live VM/P0/native parent, startup-registered helper, marker/FFI readiness and unlocked/non-GC context. No implicit TLS replacement or arbitrary Scheme re-entry from legacy cleanup. Never-invoked work/known BUSY can roll forward; consumed errors/unknown callback effects retain roots/ownership; unsupported unwind or unsafe GC context without pre-established retention takes declared terminal policy. Historical front-eight receipts are unchanged; changed producer needs targeted root/FFI/compiled/stress/registry requalification.

Final sweep_finalizer_context.qnt met20 expected safety controls (8 candidates,12 decoded negatives), maximum6.443s under original30s/case; receipt:.cache/tasks/repair-9-12/processes/audit/runs/a6d6f079b71946f6934a680cf0f7613e/outputs/sweep-finalizer-context/receipt.json. Seven separately decoded existential witnesses cover deferred completion, resurrection, both explicit/will winner orders, valid bridge, no-context refusal and unsafe-GC termination; receipt:.cache/tasks/repair-9-12/processes/audit/runs/814198412e4347a8af084de4ee0553d7/outputs/sweep-finalizer-reachability/receipt.json. All27 compiler inputs independently reconstructed; observers change no action. Retain initial17 narrower graph, the actual rejected explicit-release/will-coupling model and subsequent narrower19-control predecessors. The final graph additionally preserves the independently regained strong root; older clauses did not prove that property. This is not liveness/C11/frame/native proof. No runtime/qualifier/recipe/history/peer/commit/push change; count remains8/12.


### 2026-10-23 Shared foreign release claim and native pointer loans

Evidence: evidence/research/smp-retirement-study/release-loan-protocol.md/.json. An atomic release-function exchange alone cannot protect a pointer in an admitted C call. Saved c_intf.c returns raw foreign fields and release_pointer is a no-op; saved generator type-needs-cleanup? excludes pointer/nonnull-pointer, c-make-function nests argument conversions and chooses cleanup only from parameter types, while pointer END macros do not release lifetime. A second-argument conversion failure must clean the successful pointer prefix. Result conversion/alias transfer and supported Gambit unwind must finish before the corresponding loan ends; outer VM authority must extend through R_ALL/status/native return tails. The saved ##init-mod direct FOREIGN_PTR_FIELD->init_mod call bypasses conversion macros. Sweep/bulk still cleanup currently release then unconditionally free, so a new BUSY/deferred/error path must not fall through to destruction.

Proposed full-key per-wrapper descriptor uses one conservative SC phase/count word; borrow increments before payload read, close blocks new loans, claim requires zero loans. Explicit release with a live loan returns a non-consuming BUSY instead of waiting on its own nested invocation; accepted will/VM preparation retains drain debt and a valid executor claims later. Last-loan completion only publishes readiness. Unknown callback effects retain descriptor/VM debt and never rearm the pointer. Exported alias/native-retention ownership must transfer before input-loan release; foreign-address integers remain unprotected address snapshots. Native pinning must not strongly capture a will testator before weak selection. Actual C/root/ABI/caller migration and same-producer native evidence remain open. No attribution of historical SIGSEGV/hang causality is made.

Combined model met22 expected controls:6 candidate safety,12 independently decoded negatives,4 existential outcomes; maximum12.150s under unchanged30s/case. Final receipt:.cache/tasks/repair-9-12/processes/audit/runs/8bb5fd63c7fc43c08c4d18cb87481a97/outputs/release-loan-decoded-validation/receipt.json. Initial syntax failure and tagged-integer-set decoder failure are retained; existing backend traces were re-decoded instead of repeating unchanged checks, and only missing/strengthened goals were run. All22 projected compiler inputs reconstructed at publication. Two abstract invocation scopes do not prove a recursive FFI stack, C11 ordering, actual root maps or unconditional progress. Protected14 inputs unchanged; qualifier remains admitted false8/12. No runtime/qualifier/history/peer/native/commit/push actions.


### 2026-10-23 Recursive FFI journals, return tails and corrected report authority

Evidence: evidence/research/smp-retirement-study/recursive-ffi-journal.md/.json. Corrected five report openings: no-runtime/no-native statements describe the author's audit execution, not a prohibition on another owner; implementation sequences are conditional review dependencies rather than executable work orders. Historical line numbers must be rebased to one producer. Existing proof/receipt bytes remain archived; no qualification/recipe/runtime change follows this clarification. Verified cumulative claim patch/lock/landed record agree on patch bd4dfe0d86a46f88d4c869427a98e04d1902f87975e809500028c4e1e7f93c86 and candidate c_intf.c 7d4d2a44..., base7c490c3.... The user clarified vendor belongs to another engineering context and the lock names its main-branch baseline: equality with vendor is neither required nor a drift test for this work. That patch wins release_fn then pointer exchanges and does not rearm on error; it has no loan journal/retained word/internal will/checked bridge/new generated kernel/thread C and no configured producer/GSI certificate. Do not repeat an already landed claim or pretend it closes SIGSEGV/interrupt/lifecycle gates.

Saved generated kernel CFUN demonstrates a pointer prefix before integer conversion; body-only TRY/AT_END cannot settle failed arguments. SFUN marker creation/___call/matching return versus mismatching rethrow and internal trampoline retry have different lifetime boundaries. Keep enclosing C loans on matching callback return and internal retry; drain only actually crossed invocation suffixes on unwind. Keep separate descriptor control references after pointer-loan zero, and VM/run authority through R_ALL/temp/marker/catcher/native tails; no descriptor/frame/ps access after its relevant last reference. SFUN returned pointer conversion must transfer ownership/root to a surviving parent or explicit export before marker death. Stable journal progress cannot depend on modified nonvolatile setjmp locals. Wrong-owner routing, stale continuation returns and terminal stack abandonment require separate checked ownership paths.

New recursive_ffi_loan_composition.qnt explicitly models CF1->SF2->CF3->SF4->CF5, intermediate/outer unwind, two root-version updates, separate resource/control/VM pins and SF4-to-CF3 result-loan transfer.33 expected controls:8 candidate safety,17 decoded negatives,8 existential targets; maximum16.059s under unchanged30s/case; receipt:.cache/tasks/repair-9-12/processes/audit/runs/1c90b7f12a204cf5b812feced048e422/outputs/recursive-ffi-composition/receipt.json. Strict research-local List[int] decoder handles variable-length native stacks without changing shared framework code. Backend syntax/type and decoder failures remain retained; eight unchanged successful backend cases were reused with reconstructed input identities. All33 final projected inputs and witnesses rechecked at publication. This is bounded same-native-owner atomic protocol evidence, not actual C11/unwinder/root/native proof or unconditional completion. Count remains8/12; no native/campaign/runtime/qualifier/history/peer/commit/push action.


### Lock-main source alignment, native owners and sender-owned root disposal

Evidence: evidence/research/smp-retirement-study/lock-main-native-owner-ffi.md/.json. Read only the explicit lock commit7c490c3... from the existing object database; checkout HEAD is not a comparison condition. Extracted33 files, reproduced all26 locked base hashes, replayed the exact cumulative claim patch on evidence copies and matched all26 candidate hashes; source receipt:.cache/tasks/repair-9-12/processes/audit/runs/74c30f8395714aa9ad03227dfe87436f/outputs/lock-main-ffi-source/receipt.json. No producer workspace/runtime source edited or compiler launched. The source layer is now coherent for this lock, not patched from mixed c86 observations.

Actual locked candidate uses ___sfun_frame_enter/leave and gate/counts, not historical c86 marker-owner entries. Simple marker kill has no owner registry; ___run kill is inside TRY and can be skipped by outward throw. END_SFUN leaves frame before propagate_error, which needs independent ps/native-tail lifetime. Header/compiler/GC path is bound from same source slice: liveness->IFD/OFD->mark_frame/mark_array, saved/register/RC traced cells. Archived _kernel.c remains baseline: wrong-processor call takes1 argument while patched Scheme preserves result and takes2. Baseline label11 RETN5/link0/map0x3 is not a new journal root map. Configured header/new kernel/thread C/gsi are not certified and must not be substituted with c86 bytes. This is a source-package correspondence finding, not evidence a current native producer executed stale C.

Choose fixed native C stacks with explicit semantic parent lineage, full VM/owner/incarnation/activation keys and owner-local journals. Never migrate a catcher or longjmp into another OS stack. Actual ___register_rc/release_rc are intrusive owner-local operations; receiver must publish its own current GC-updated root before ACK, sender detaches its carrier only at its own safe point. Sender scan-domain/message pin persists beyond frame_count0; parent C may resume before asynchronous sender cleanup, while destruction retains debt. Add separate native-tail/run units and common all-supported-exit run finalizer; counts/PSTATE/TLS alone do not authorize arbitrary native entry. Unknown cleanup remains retained, not a fabricated completion.

Final ffi_native_owner_handoff.qnt met32 expected controls:7 candidate safety,16 decoded negatives,7 scenario targets plus2 completion paths from recorded distinct prefix/body errors; max15.312s under unchanged30s/case; receipt:.cache/tasks/repair-9-12/processes/audit/runs/c05490acf963473bbc9f4e75ca06d47a/outputs/ffi-owner-distinct-errors/receipt.json. A narrower26-control abstract-bridge predecessor and rejected field-collision strengthening are retained. All32 projected compiler inputs reconstructed; this bounded same-VM atomic model assumes actual scanner/safe execution and does not prove C11, arbitrary recursion, external attachment or unconditional completion.

Observed supplied inventory rerun record and current-1 outer receipt: DENY/exit2/timeoutfalse/runtimeAdmittedfalse in12.814s at completed-producer drift validation, later stages BLOCKED; current-2 not launched due old seal workspace.py transport gap. No new native GC/FFI/stress result, no rerun or seal/qualifier/history mutation. Lifecycle banner still does not meet the existing OS-error predicate. Count remains8/12; no other-thread/native campaign/commit/push action.

### Lock-main run finalization and B-owner ACK service refinement

The lock-main candidate still places ___run marker invalidation inside TRY; supported outward errors can bypass it. Its marker is an initially refcounted still vector, so address relocation is not the same issue as skipped cleanup or setjmp cleanup-state validity. The common epilogue must keep an independent native entry/tail until its last ps access and restore only owned temporary-root tokens. Both observed callers are covered: setup error cleanup, and the worker native sync loop after run returns.

B ACK certifies receiver roots, not RC reclamation permission. Owner-local unlink needs full-key validation, no T/P locks and exclusion of mark_rc readers; local gc_active checks or only a Scheme interrupt hook cannot establish this. The handoff specifies a bounded jointly elected owner-service window, retained generation-tagged debt and separate sender scan-domain lifetime, plus Scheme resume and native sync-loop service entries. Permanently blocked owners still require root-preserving domain transfer or retained/terminal fault policy.

See evidence/research/smp-retirement-study/run-ack-source-protocol.md and .json. The additional Quint slice has 5 candidate safety checks, 11 decoded negatives and 6 reachability witnesses (22 expected controls, unchanged 30s per-case cap); it abstracts the proposed scanner-excluding window and proves neither its C implementation nor unconditional liveness. Actual generated C/configured header/root maps remain uncertified; the archived one-argument kernel C is a baseline control against the patched two-argument Scheme, not a claim about any current gsi. Initial parser failure is retained. Only evidence/model files changed; production descriptors were observed read-only and peer processes left untouched. No native campaign, qualifier/history/runtime changes, commit or push. Recorded qualification remains 8/12.

### ACK service windows: GC reader exit, native sync service and blocked-owner scope

The same lock-main tree orders ordinary operations by numeric priority and waits for every logical processor_count member. A low-priority ACK opcode can be starved by recurrent GC; a missing active owner cannot safely be skipped. The source-bound protocol now specifies a mandatory stable post-operation READERS_EXITED round, a bounded owner-local batch that skips busy entries, and an OWNER_SERVICE_DONE round before the next election/snapshot. GC root marking and the last internal barrier precede native tails; admission is after complete operation return. Native sync-only workers use the same engine; errors and startup/resize role changes require common convergence rather than local extra barriers.

Parked/frozen domains and active cohort membership must be independent. Checked preparation/materialization and old-cohort commit occur before blocking; an unprepared already-blocked active owner remains an unsupported progress case. The handoff enumerates dense-rank barrier changes, GC worker counts/global partitions/heap accounting, native root-domain scanning, leader/P0 limitations and checked rejoin. B root retention does not authorize C to unlink B RC cells. The larger membership dependency is explicit rather than described as a one-field fix.

See evidence/research/smp-retirement-study/ack-collective-service.md and .json. New ack_service_window.qnt: 20 expected controls (6 safety/conditional-progress, 7 safety counterexamples, 5 real temporal cycles, 2 reachability witnesses), recurrent GC without a finite collection counter, original 30s cap. Model abstraction does not prove the C membership/materialization implementation or generated roots. Exact-lock setup.h was retained as one additional unchanged input: threaded BARRIER uses barrier_sync_noop. Protected qualifier/Recipe/history/lock inputs unchanged; no native execution, runtime mutation, other-thread action, commit or push. Recorded qualification remains 8/12.

### Checked park: materialization certificate, internal native dispatch and rejoin

Lock-main THREAD_SAVE can store raw fp in a saved continuation; it does not by itself copy frames. Materialization uses the completed old-cohort GC/mark_captured_continuation path before a no-T/P-lock freeze/membership commit. THREAD_RESTORE consumes that continuation exactly once, so ABORT must restore current traced state and cannot restore old fp/fromspace. The proposed blocking ABI is prepare→Scheme landing/materialization→cohort commit→internal ___call dispatcher→checked rejoin→Scheme completion. Its ___call/___run marker and native activation survive park; ordinary outward run cleanup would invalidate the captured return destination.

The first supported contract refuses logical P0 and unclassified/raw-movable-address jobs before execution. Active GC worker count, logical slots and frozen root-domain count are distinct. The handoff enumerates active ranks, scanner termination/global partitions/heap accounting, typed frozen still/RC/frame scans with an active collector, callback classification and current pointer writeback. Park is not ___transfer_mem_pstate or cleanup of a joined donor. Callback entry must request rejoin before SFUN marker/conversion access; callback return requires another checked park before potentially blocking native body continuation, and only final host return consumes the parent continuation.

See evidence/research/smp-retirement-study/checked-park-source-protocol.md and .json. Final QNT evidence: 33 expected controls (9 safety/conditional progress, 17 decoded negatives, 5 distinct witnesses, 2 exact-state continuations showing GC after retained failure); original30s per-case cap. Prior24/28-control simplified callback models retained, not used as final nested-callback proof. Source/generation/native implementation gaps and active rollback-failure serviceability remain explicit. Native executions0, recorded8/12; no runtime/qualifier/history/other-thread changes, commit or push.

### Staged FFI: generator ownership and stack-preserving callback return

Lock-main generator/header/archived generated C show two distinct transitions: initial park before native entry may transfer to a resident ___call dispatcher; callback-return repark must preserve the still-live host C activation synchronously. An outer longjmp destroys that activation even when the parent Scheme marker is rooted. A new staged emitter must separate active PREPARE/COMPLETE from native BODY, transfer prefix cleanup ownership explicitly, install a live resident native catcher, and contain supported callback errors through an explicit native ABI instead of legacy END_SFUN/propagate_error. Child marker/SFUN cleanup precedes in-place repark while a separate native-tail pin remains; final Scheme result roots survive until handoff.

See evidence/research/smp-retirement-study/staged-ffi-generator-protocol.md and .json, models/gambit/staged_ffi_stack.qnt and verify-staged-ffi.py. Quint/TLC 32 expected controls: 10 safety/conditional progress,17 decoded negatives,5 reachability; original30s cap,max15.019s. This corrects the earlier atomic callback-repark abstraction without rewriting its receipts. Arbitrary recursive callbacks, actual generated root maps/cohort/scanner implementation and same-producer native validation remain unproved. Native executions0; recorded8/12. Evidence only; no runtime/qualifier/history/other-thread changes, commit or push.

### Synchronous callback repark: common service, departure ACK and actual RC roots

Source-bound research identifies the current entry on_all_processors→execute_sync_op_loop→barrier_sync_op, but no implemented synchronous repark/departure protocol. Repark needs a fixed post-operation reader-free validation/commit window, an initialized successor descriptor and final old-cohort result ACK before B returns into potentially blocking host C. Intervening GC updates actual registered root cells; stale C locals/old certificate bits cannot authorize commit. Failed prepublication repark remains active AND continues the common native service engine. Unknown membership/transport/shared-lock faults remain a separate reconciliation/terminal obligation, not a recoverable retention claim.

Concrete root finding: mem.c mark_rc traces only h->data, not arbitrary SCMOBJ fields in ___alloc_rc payload; ___register_rc/addref/release are plain owner-local chain/count operations. The staged emitter needs a rooted carrier or explicitly scanned fields and separate native pin/grace, with checked SFUN error containment and no detached R_ALL/RETURN. Exact archived sync C executes RA/W_ALL/service/R_ALL, but does not certify new staged maps.

See evidence/research/smp-retirement-study/synchronous-repark-protocol.md/.json, models/gambit/repark_cohort.qnt, verify-repark-cohort.py. Final23 expected controls:4 positives including recurrent service on permanent refusal,15 decoded negatives,4 targets including GC demand retained across departure; unchanged30s cap. Original21-control predecessor retained. Collector/commit atomicity, real generated maps and same-producer native evidence remain dependencies. Native executions0; recorded8/12. Evidence only; no runtime/qualifier/history/other-thread changes, commit or push.

### Old-cohort result ACK, successor channels and final root-carrier consumers

Lock-main barrier forwards results after parent reply and SYNC_SEND_MSG unlocks/signals after flag publication; result ACK is not proof of returned native tails. Separate pinned predecessor channels/descriptors from successor channels, or drain all old communication tails before successor enable. One GO after all old ACKs permits departure but never frees the parent RC root carrier. Archived _thread.c restore control and THREAD_RESTOREn show continuation consumption then argument push/jump; actual root-install ACK belongs in the reached compiled success/error completion landing. Final RC release is owner-local in a bounded reader-free batch after destination-root ACK and per-carrier scanner/native/ACK grace; busy entries retain and skip, rather than blocking the whole cohort.

See evidence/research/smp-retirement-study/cohort-ack-rc-protocol.md/.json, models/gambit/cohort_ack_rc.qnt and verify-cohort-ack-rc.py. Final22 expected controls:3 exhaustive safety,15 decoded negatives,4 reachability; no temporal-liveness or C-refinement claim. Source33/protected20 hashes unchanged. Parse/reserved-name/Set-decoder diagnostics retained and excluded from admission. Real generated maps/channel implementation/memory ordering/multiple epochs and same-producer native evidence remain open. Native executions0; recorded8/12. Evidence only; no runtime/qualifier/history/other-thread changes, commit or push.

### Epoch mailbox/pin/ABA and two-carrier reclaim; current drain patch kept distinct

The user-supplied cohort-ack-rc cumulative patch SHA3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7 was statically reproduced against lock-main7c490c3:26 locked hashes/33-file snapshot,strict whitespace apply/check, no production source/build change. Current new setup.c pins one channel per barrier, drops only its communication tail, and has definition-only result-ACK/GO helpers; ACK0/RC-intent1 and no certified rotation/root-install/reclaim remain. Its selected policy is drain-before-GO, distinct from the proposed overlap model. A zero-count scan needs a proved no-new-ordinary-entry phase or a checked CLOSED gate; the unwired helper is not reported as a demonstrated native race.

Evidence/research/smp-retirement-study/epoch-mailbox-reclaim-protocol.md/.json binds functions and acq_rel ordering, stable-registry pin admission, full keys/overflow refusal, ledger-held quarantine, and bounded per-carrier cutoff/cursor skipping. Models epoch_mailbox_reclaim.qnt and drain_go_admission.qnt record21 combined proposal controls and6 source-matched drain controls. Temporal negatives show safe-memory starvation by a global busy gate/stuck cursor, and deadlock if pin owners wait for GO needed to clear their own pins. Busy A/old tail do not prevent B conditional progress. Actual C11 implementation/maps, current drain integration and same-producer native acceptance remain open. Qualifier not run or changed; user reports8/12/admittedfalse/runsOkfalse and setup.o-only compilation separately. Native executions0; no runtime/history/other-thread changes, commit or push.

### Drain-only admission closure, multi-epoch ACK reset and channel reuse

Current cohort-ack-rc lock/patch3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7 remains source authority;33 snapshot/26 locked hashes reverified. Existing ack_service_window performs2 internal barrier phases, so closure must first reject new ordinary rounds while registered old drains finish, then SEALED excludes new communication/ACK writers before zero checks. ___cohort_record_result_ack and ___cohort_publish_go remain definition-only; current ACK1/GO1/init do not implement multi-attempt reset. Transition generation must distinguish ABORT/retry with unchanged cohort epoch; old GO-reader storage survives observation until actual final release. Common COMMIT/ABORT resume ACK precedes reopening; latched GC precedes another transition.

Source-specific lock finding: scheduler sync-participation helper and migration can enter service while thread ownership is retained. A new blocking control mutex on that path needs a proved landing or is unsafe; proposed atomic state/count lookup pin precedes stable epoch/index/full-key validation, while leader-side blocking setup/reset remains outside T/P locks. This is a design requirement, not implemented C proof.

See evidence/research/smp-retirement-study/drain-epoch-rotation-protocol.md/.json and models/gambit/drain_epoch_rotation.qnt.19 expected controls:3 safety/conditional progress,9 safety negatives,2 temporal lassos,5 targets; original30s cap. Actual C atomics/caller schedule/generated roots/dynamic cohort and same-producer native/lifecycle evidence remain open. rcHeld is intent only; recorded8/12, native executions0. No runtime/qualifier/history/other-thread changes, commit or push.

### Drain counted lookup, scheduler-lock-held service and registered capability authority

New drain lock/patch3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7 stays source authority (33 snapshot/26 locked files reverified). Migration retains the thread lock/current-thread root while destination trylock can enter ##sync-op-interrupt!. Proposed entry must use a configured lock-free counted lookup first, then acquire-read stable current key/index and validate member/operation/transition/round/phase/use; repeating OPEN/count bits are not authority. A blocking control mutex on that path requires a separately proved landing. Persist per-member service obligation before wake; poll it as well as interrupt hint, then authorize only via C registration. Late ordinary requests remain pending while their member serves the accepted old drain.

Communication/lookup/ACK-writer pins drain before SEALED zero; old registrations and GO-reader references persist separately and cannot keep that count nonzero. ACK payload precedes release READY, writer native tail precedes put, and initialized stable metadata/common resume precede release OPEN. Counters are preserved across mode changes. Actual lock-free instruction generation/ABI/capacity and C root/caller protocol remain unproved.

See evidence/research/smp-retirement-study/drain-cap-admission-protocol.md/.json and models/gambit/drain_cap_admission.qnt.26 expected controls:8 safety/conditional progress,11 decoded negatives,3 temporal lassos,4 targets,original30s cap. heldT/threadRoot are model preconditions, not C/GC proof; native executions0, qualifier not run, recorded8/12. No runtime/history/other-thread changes, commit or push.

### Drain sync implementation closure: target CAS, all direct entries and error boundary

New evidence-only [contract](../evidence/research/smp-retirement-study/drain-sync-closure-contract.md) binds the cohort-ack-rc lock/main source. Both local GCC16 and Apple Clang emitted inline casal/ldaddal for standalone aligned64-bit atomic controls; no runtime compiled or executed and no production-config claim. Full direct lib Scheme entry inventory exposes multi-ticket ordered/termination paths; setup.c1912 can throw without scheduler-scope check. Proposed implementation must combine registered phase authority, root-bearing operation records, native scheduler-scope/deferred errors and sealed-count/ACK ordering. Archived _thread.c lacks new helper/migration symbols; regenerated root maps remain mandatory. Combined QNT12 controls matched (3 conditional-progress positives,9 decoded negatives), original30s per-case budget. Report gives one coordinated Grok implementation/native acceptance order. No runtime/qualifier/history/other-thread/commit/push changes. Qualification remains recorded8/12; lifecycle predicate review and same-producer native/refinement evidence remain separate.

### 2026-10-24 Failure-selected alignment of drain handoff, TFIB and result-mutex stall

The new [causal alignment](../evidence/research/smp-retirement-study/repair9-failure-causal-alignment.md) narrows rather than expands the drain contract. Original TFIB5620dd70/UUIDc823a9d8 and diagnostic9eca/generated-root studies are different generations; current main-lock candidate is not either binary. Original producer/consumer outer+child receipts/stdout rehash, but two exact old raw-audit paths are currently unavailable; historical crash/disassembly attestation is not re-performed. Original scalar dispatch already skips F64/flonum, and inspected historical result/unlock frame slots are mapped. First invalid scan cell/container/map/writer is still unknown. Current running-target interrupt branch still publishes to processor high-level queue; a SYNC drain capability is not a result-mutex request claim or OTHER wake. Historical exclusive-branch defect was corrected; live-node alias after correction and the actual blocked request R remain unproved.22 bounded QNT controls match, including root-fixed/drain-complete but invalid-frame/heap/extent failures, concrete conditional intrusive-link loss, reachable masked park, dispatcher-owned empty queues and callback nonreturn. Report gives exact causal cuts and same-producer original TFIB/interrupt/flood/native verification order. No native execution, runtime/qualifier/history/Recipe/peer/commit/push action; recorded8/12 remains.

### 2026-10-24 Current-lock minimum scan/request diagnostic cut

The [diagnostic handoff](../evidence/research/smp-retirement-study/current-lock-minimal-diagnostics.md) binds all33 current candidate files, enumerates all29 mark_array entry roles and rebases the six request evidence surfaces to exact statements. Existing Darwin/GCC-only check_gc_write_target guards selected writes into msection headers; it does not capture original cell3930/header3945 reads. Current mem.c has no gc_origin/gc_diag recorder. Source-package thread C14320..14352/19061..19085 has procedure-only resume/other bodies corresponding to non-SMP Scheme, not the current SMP result-mutex implementation; no produced-gsi regression is inferred. Grok must generate/bind actual SMP C, then verify root maps and native record-before-fault ordering. Minimal observational request ID is an immediate third metadata element of private result-mutex vectors; next/payload/mutex name/specific/routing remain unchanged, and generic procedure nodes require safe discrimination. No extra queue link or mutex-name wrapper is prescribed. Report defines pre-cell/pre-header/current-tail/frame presence fields, exact event/last-consumer placement, partial-carrier UNKNOWN rules, one-producer original workload order and accepted diagnosis table. No native execution, model rerun, runtime/qualifier/history/Recipe/peer/commit/push action. Recorded8/12 remains.

### 2026-10-24 Diagnostic commit/read order and request identity refinement

The [focused evidence](../evidence/research/smp-retirement-study/diagnostic-order-id-generated-c.md) retains the current lock and minimum diagnostic scope. Registered audit compiled one standalone evidence C file to assembly with GCC16.2.0 and Apple Clang21.0.0 at O2/O3, without linking or running it. Release-only, signal-fence and seq_cst-store variants lack a full barrier before the ordinary load; full thread fence emits DMB ISH at both representative read placements. GCC uses STLUR/LFE and Clang STLR/cfi_endproc; initial extraction rejected GCC because of parser assumptions. Raw failure retained, corrected replay inspects the same bytes without recompilation:20 expected shape controls and three malformed-assembly rejection controls. No runtime reorder or crash-survival experiment is claimed. Request serial is immediate fixnum value preservation, distinct from node/mutex/result pointer rooting. Current source-package thread C remains non-SMP/procedure-only; new SMP serial labels/maps are unavailable. Six historical SMP files are SHA-checked as method controls only. Exact current Scheme, mem and TRY boundaries, migration/captured-frame obligations, no extra node retention and unsupported native/Scheme escape UNKNOWN rules are recorded. Acceptance requires one source-bound producer with actual generated root/value maps, final object order, owned crash-carrier survival and per-R causal records. Candidate33/protected20 unchanged; no runtime/generator/qualifier/Recipe/history/peer change, Gambit build/run, model rerun, commit or push. Recorded8/12 remains.

### 2026-10-24 Root-repair decision, external carrier lifetime and escape attribution

The [focused decision](../evidence/research/smp-retirement-study/fault-carrier-root-remedy.md) rejects more catches and further lifecycle expansion as substitutes for the retained failures. Current Scheme still appends running-target requests to P head/tail1507..1517 and nonrunning requests to T head/tail1530..1534; C425..454 mutates the same node next link. Recommended structural delivery repair is one T-owned inbox plus a reliable pending-service/park handoff, with P notification carrying no T-request node. Prior thread-only failures remain decisive evidence that inbox conversion alone is insufficient; retained R alias is not proved by aggregate counters/empty heads. No TFIB root cause is inferred from this recommendation. Carrier proposal is concretized as supervisor-owned fixed backing object, separate child shared mapping, no inherited-address-through-exec assumption, no VM cleanup truncation, and last release after writer quiescence and reader snapshot/hash. Framework137..230 provides launch/reap/group facts but no diagnostic mapping; exact source hashes are bound. Current candidate has no gc_diag or serial implementation. Actual Scheme dispatch/termination, native TRY/call/run and old procedure-only generated C define what can be associated; no new catch, native automatic current-R, guessed terminal event or extended Scheme root retention is prescribed. Grok sequence specifies normal/fault/partial/carrier refusal and nested/migration/error controls on one B, then per-R/per-cell causal repair selection and original targeted workloads. No native control or model rerun occurred. Candidate33/protected20 and framework2 inputs unchanged; no runtime/qualifier/Recipe/history/peer/commit/push action. Recorded8/12 remains.

### 2026-10-24 New scan-diagnostic patch writer-isolation review

The [new-lock review](../evidence/research/smp-retirement-study/current-lock-scan-diag-writer-review.md) binds fbf60628 patch and scan-diag lock. Candidate mem477f301e and O3 DMB/STR are advertised by the landed note; no exact new mem.o/canonical candidate receipt was independently verified this turn. Source review identifies process-global gc_diag_cur/prev, entry/parent and non-atomic sequence: simultaneous GC writers have no exclusive slot; footer atomicity and DMB do not protect plain payload or struct-copy snapshot. Sequence lacks wrap refusal. This is a diagnostic design defect, not an attribution of original TFIB. Moving the same global record to MAP_SHARED is insufficient. Grok sequence: isolated owner slots/local context, supervisor-retained shared backing, exact object publication proof, normal/cell-fault/header-fault/two-writer/partial-publication/refusal controls, then original TFIB. STR alone is neither accepted nor declared compiler defect without the full publication envelope. Request ID/regenerated SMP roots remain a separate missing lane; no new catch or broader protocol. Protected20 inputs unchanged. No runtime/native/model/qualifier/history/peer/commit/push action; recorded8/12 remains.

### 2026-10-24 Exclusive scan-slot fields, reentry and last-reader release

The [function-level handoff](../evidence/research/smp-retirement-study/scan-slot-implementation.md) reconstructs evidence-only mem.c477f301e by reversing the bound old mem diff, verifying main base317b5262, applying fbf60628 and checking exact new SHA. All new-lock files and protected20 inputs reverify;29 direct mark_array sites are rebound. Current locations: publish3901, cell4003/header4021, P setup5126/VM5261, P cleanup5673/VM5691, GC7776. Proposed fields and order specify nullable local views; FREE->CLAIMING->READY publication; actual native-worker binding after thread_set_pstate (P0 may create worker state first); per-GC no-spin active admission and explicit nullable context plumbing through existing helpers; two checked sequence reservations per attempt; no global context, struct-copy previous record or in-run slot recycling. Inactive-bank footer invalidation must precede overwrite; committed payload/footer/full-fence precede original read. Cleanup detaches only after existing writer-lifetime precondition, retains slot bytes; unresolved writer prevents diagnostic closure without new cohort wait. Fault may leave active1, so actual writer-group quiescence—not guard value—admits the reader. Harness retains shared backing through all reader completion and raw snapshot/hash; only a new object/run after final release may reuse bytes. Eight native controls specify two workers, reentry, exhaustion, partial commit, cleanup/address reuse, normal/fault exit, descendant writers and partial attach/refusal. These controls were not run. No new catch, request/lifecycle protocol, runtime edit, production compile, native/model run, qualifier/history/Recipe/peer/commit/push action. Recorded8/12 remains.

### 2026-10-24 READY, active and bank ordering against diagnostic close

The [memory-order handoff](../evidence/research/smp-retirement-study/scan-slot-memory-order.md) stays on scan-diag lock20e7af89, patchfbf60628 and reconstructed mem477f301e. Existing26 locked inputs/protected20 reverify. It refines the existing proposed fields only: initializer final CAS CLAIMING->READY (release) cannot reopen RETAINED after partial-init close; local view uses release/acquire with atomic detach; native identity requires separate BOUND publication; GC active CAS is followed by final acquire READY->READY RMW ordered with acq_rel close on state. Closure never proves drainage or permits unmap/reset. Original GC phases/return7923 execute on diagnostic refusal; normal owner releases active after last use, failed/nested owner cannot clear it. Bank invalidation/full ordering precedes overwrite; complete payload+commit/release footer/full ordering precedes original cell4003/header4021. No live payload reader or new latest-index protocol. Partial CLAIMING/BINDING slots are retained without metadata interpretation. A fatal path may leave active1; actual all-writer quiescence permits postmortem read without fabricating release, with raw snapshot/hash before final harness release. Eight native controls target initializer-close, admit-close, two writers/reentry, exhaustion, partial banks, actual faults, partial setup and retained slot/descendant lifetime. They were not run; no production build/model/runtime/qualifier/history/Recipe/peer/commit/push action. Recorded8/12 remains.

### 2026-10-24 Existing harness wiring for the eight scan controls

The [harness handoff](../evidence/research/smp-retirement-study/scan-controls-harness.md) binds current framework137..234, recipe run621..692, executable_test1563ff/native_test1730ff and runtime identity checker9..29, plus historical targeted-runner pattern167..207. Historical runner is hardcoded c86 and DYLD injection covers only write/close; it must not be run as current scan acceptance. Current lock has no slot hooks/carrier connection. Typed executable-test requires exit0 and native.test forbids signals as expected success; controlled scan faults must retain raw signed exit and separate observation verdict using existing owned execute path, without changing validators. Eight classes are assigned actual helper/GC/load injection points and explicit schedules; init-close races use actual-helper isolated slots plus separate legal setup integration, not concurrent destruction of a live VM. Static helper interposition/copy is rejected; actual compiled B helper connection remains to implement. Compiled fixture has its own image UUID/PC, distinct from B gsi; library identity alone cannot transfer fault offsets. Sidecar fields bind producer/control/object identities, actual reached cut, raw exit/fault data, backing and writer identities, quiescence, raw snapshot/hash and reasoned reader verdict. No imaginary CLI, new capability/recipe, raw unregistered descendant, budget expansion, catch or formal qualification change. No native compilation/execution/model rerun. New26 locked files/protected20 and all inspected harness inputs unchanged; recorded8/12 remains.

### 2026-10-24 Carrier lock: survival controls and unresolved two-worker timeout

The [current review](../evidence/research/smp-retirement-study/carrier-two-worker-review.md) reconstructs all26 bec577ea carrier-lock files; mem0c9e59a8, header9e823dc2 and setup84f2cbc1 bytes are retained under registered audit. Reported d03/E2BB92CC producer normal, injected cell/header SIGSEGV, split86 and bad-nonce results establish narrower real carrier progress; raw native artifacts are not independently re-attested from the summary. User raw entry.cache/repair-19 did not resolve in this checkout/parent, so absolute/check-out-qualified location was requested; no task19 is inferred.20-second double-worker timeout remains unlocated, not a proved bind deadlock. Actual GC7976/strong7847 -> mark_array4139 -> bind_owner4007/note_fault3915/bind_shared3934 is rebased. Binding has explicit state1 spin3948 plus lazy getenv/shm/mmap in collector; fault_ready claim precedes plain mode payload, with no completed-publication edge for concurrent configured modes. No-mode case does not alone exercise that payload race. Slot owner is plain VM-local processor ID; same-VM distinct IDs differ, multi-VM/reuse is unsupported. Current depth is not proposed active protocol; shared slot.coverage is never updated. Null probes4189/4211 precede original cell4191/header4213, so their fault PC/operand cannot be assumed to be the original load. Necessary local correction moves preparation/config publication before possible GC and removes scanner waiting, without claiming historical timeout causality. Actual fixture/phase/writer cuts determine next repair; no unchanged rerun, native/production/model action, timeout expansion, runtime/qualifier/history/Recipe/peer/commit/push change. Protected20 unchanged; recorded8/12 remains; TFIB not launched.


### 2026-10-24 Corrected carrier evidence entry and setup seam

The raw-data entry is `.cache/tasks/repair-9-12/`, superseding the earlier repair-19 spelling. The directory resolves; current bounded reads have not identified the exact two-worker native fixture/receipt/snapshot, so the20-second timeout location stays UNKNOWN, not a proved bind deadlock. [Carrier review](../evidence/research/smp-retirement-study/carrier-two-worker-review.md) now separates this limitation from existing task source changes/evidence. Locked setup.c5698 provides the candidate diagnostic-prepare seam after global OS setup and before global memory/module/VM initialization. Per-pstate setup is also called inside collective growth1488, so moving blocking mapping there would not remove the collective hazard. Explicit VM assignment and local record initialization5840ff remain before processor memory allocation. No runtime/qualifier/history/peer action, native run, budget change, commit or push;8/12 remains.


### 2026-10-24 Carrier initialization failure and repeat-setup boundaries

[Implementation handoff](../evidence/research/smp-retirement-study/carrier-init-cleanup-handoff.md) binds carrier-lock setup84f2cbc1/mem0c9e59a8. Preparation seam5698 precedes memory/module/VM startup. Early setup failures can bypass cleanup_state1; accepted cleanup6285 and explicit setup error paths need diagnostic close, while refused cleanup must retain the live session. Existing host serialization is an assumption, not a lock. Proposed first implementation keeps one bounded published mapping per process until exit, never reopens it on repeated setup, and refuses unsupported VM/slot reincarnations. Scanner becomes a bounded acquire/owner check with no OS calls/spin; injections require attributable publication. Spawn credentials are indexed separately from source/model matches; original two-worker receipt remains unlocated and timeout cause UNKNOWN. Full request index and source identities are retained under registered audit. No native test/compile/runtime/qualifier/history/peer/commit/push action or budget increase;8/12 remains.


### 2026-10-24 Prepare-lock implementation review

[Source review](../evidence/research/smp-retirement-study/scan-diag-prepare-review.md) verifies all26 e8b39380 lock files against main7c490c3. Startup preparation and bounded scanner acquisition are implemented; fstat error separation and delayed attached assignment are confirmed. Two source gaps remain: state2 survives repeated setup while local attachment resets and same VM-local owner_id is accepted; armed cuts1/2 still fault independently of successful void publication. Mapping retention is not incarnation exclusion, and null-probe survival is not original-read attribution. No native run/object rebuild, runtime/qualifier/history/peer/commit/push change; original20-second timeout remains UNKNOWN and8/12 remains.


### 2026-10-24 One-use diagnostic sessions and cut attribution

[Function-level handoff](../evidence/research/smp-retirement-study/scan-session-cut-handoff.md) verifies all26 prepare-lock files and defines proposed first-session eligibility before global setup resets, one-use setup-time owner claims before pstate allocation, acquire-only scanner validation and sticky refusal on repeated setup/VM/slot reuse. Arm admission is rechecked at publication; cuts1/2 receive the exact committed sequence while cuts3/4/5 remain explicitly partial transaction controls and cut6 committed. A newly identified source-derived negative witness shows cut5 can leave mixed payload with unchanged equal old footer/commit. Invalidation-before-overwrite is therefore required alongside commit receipts. No native/model execution, runtime/qualifier/history/peer edits, commit/push or budget change; original two-worker receipt remains unlocated and8/12 remains.

### 2026-10-24 One-use session, committed cuts and footer invalidation

The three diagnostic conditions from [scan-session-cut-handoff.md](../evidence/research/smp-retirement-study/scan-session-cut-handoff.md) are now in one cumulative patch, `patches/fixtures/scan-session-cut-cumulative.patch`, sha256 `0949fbbf52fa77cf60bfd30135dcd2f0d1a32620ca2b0ec4678d53c20aace40a`, lock `evidence/research/processor-interrupt-collective-wait/scan-session-cut.lock.json`, on main `7c490c3` over the prepare lock. `___gc_diag_begin_setup` consumes `setup_seen` once, before `setup_state` reset. A later setup closes admission and does not reopen a retained state-2 mapping. `___gc_diag_claim_pstate` CAS-claims one native owner for `vmstate0` only when the parent slot is fresh (`owner_id` -1, sequence 0, empty records) and does not adopt an old sequence. Another VM, a repeated setup, or a second claim refuses recording and does not clear the old slot. `gc_diag_publish` stores footer 0 and fences before payload writes. Cuts 1 and 2 take the null probe only when this call returns that committed sequence and the matching cut. Cuts 3, 4 and 5 still `_exit` 86/84/85 with footer 0, so they are partial records. Cut 6 exits after the footer release. Accepted cleanup and setup failures before `setup_state` 1 call `___gc_diag_close_session` without unmap. A refused cleanup leaves the session open. Apple clang compiled `lib/mem.o` and `lib/setup.o` for `--enable-smp --enable-multiple-threaded-vms`. That compile is not a gambit-smp receipt. The 20-second two-worker fixture is still UNKNOWN and was not rerun. `qualify_nine_of_twelve` remains admitted false, count 8/12, closed null, runsOk false. No qualifier, historical receipt, commit or push.

### 2026-10-24 Optimized publish order on the session-cut object

The same session-cut patch was configured with `--enable-smp --enable-multiple-threaded-vms` and Apple clang 21.0.0 `-O3`. `lib/mem.o` `_gc_diag_publish` is `0x61e0` through `0x6470`. A complete current record is copied to prev before `stlr xzr` clears the current footer. That store is followed by `dmb ish`, and the stage/cell stores come after the barrier. `_exit(84)` is after the barrier and before those stores. `_exit(85)` is after the cell store and before `commit_seq` and the new footer release. `_exit(86)` is after `commit_seq` and before `stlr` of the new footer. `_exit(87)` is after that `stlr` and another `dmb ish`. Cuts 1 and 2 write the returned cut and sequence only after the same release. `_mark_array_body` calls `_gc_diag_publish` at `0x5ca8` and `0x5cf8`; `ldr xzr` runs only when the returned sequence is nonzero and the stack cut is 1 or 2. That load uses a stack slot stored as zero, so it remains the null probe. The original cell load is the later `ldr x25,[x27]`, and the original header load is the later `ldr x20,[x20]`. This is not a gambit-smp receipt, not a gsi image, and not the missing 20-second two-worker run. Count remains 8/12.

### 2026-10-24 ##vector-inc! optional wrapper is already the primitive form

The current cumulative source already contains `(define-prim (##vector-inc! vect k #!optional (val 1)) (##vector-inc! vect k val))`. `define-prim` rejects an empty body when `#!optional` is present (`define-prim can't inline`), so that body stays. It is the manual three-argument primitive wrapper, and `gsc/_t-c-2.scm` inserts `(make-obj 1)` for a compiled two-operand call. `thread_interrupt2_stress.scm` calls `(##vector-inc! (thread-specific (current-thread)) 0)`. The numeric-host tar gsi is still the older three-argument procedure; it was not rebuilt, and the inventory route was not replayed. A rebuilt two-argument entry would still leave `thread_interrupt_stress.scm` inside the unchanged 3600-second stress step, and it would not create the lifecycle OS-join transcript. `qualify_nine_of_twelve` remains admitted false, count 8/12. No patch, qualifier edit, commit, or push.


### 2026-10-24 Setup/capability/token call-path and QNT closure

[Locked call-path handoff](../evidence/research/smp-retirement-study/scan-session-call-paths.md) enumerates all selected symbol references across26 prepare-lock files, including exported constructor APIs, growth1488, VM P0 setup6168, both CELL/HEADER publication sites and cut reset4389. Global returns7743/7747 precede consumption;7814 is before prepare;7830 and direct init_symkey_glo2 failure7852 need explicit diagnostic close; later breaks converge on cleanup. Local constructor errors5863/5873/5937 retain the one-use claim and clear only local capability. A same-global-epoch resize retry must refuse that slot while another READY owner remains usable; a global epoch alone is insufficient.

The final source-bound scan_session_commit QNT has15 positive safety checks,11 expected parsed mutant counterexamples and15 reachable target witnesses (41 controls), all within30 seconds per model check using the existing audit Quint/TLC backend. New controls include pre-prepare failure, terminal preparation refusal, PREPARING/READY reentry, READY-then-constructor failure, same-epoch stale local capability, uncommitted/stale token faults and postmortem cut5 mixed-record acceptance without invalidation. Results are conditional on the modeled atomic/order boundaries; selected-VM/host validity, target object memory ordering, actual GC roots and two-bank concurrent native behavior are not proved. Grok same-producer controls and unchanged20-second two-worker requirements are specified; historical original fixture/receipt remains unlocated. No runtime/qualifier/history/peer edits, native test, budget increase, commit or push;8/12 remains.


### 2026-10-24 Actual session-cut implementation versus QNT

[New-lock audit](../evidence/research/smp-retirement-study/scan-session-cut-implementation.md) reconstructs all26 scan-session-cut.lock files (patch0949fbbf). Same-epoch retry entry clears eligible/session/slot/pending before one-use claim5858, and committed token/footer checks4200/4414/4440 are implemented. Remaining source edits are explicit diagnostic close on direct init_symkey_glo2 return7870 and before global error cleanup7957, plus local revoke before pstate errors5868/5878/5942 and before VM publication-failure sync teardown. cleanup_failed_pstate currently does not revoke diagnostics. Retry-entry clearing therefore does not prove the interval immediately after failure.

Actual mark_array tail resets legacy cut, not pending_cut. The earlier unmatched-scan QNT cancellation must correspond to explicit fixture arm0 (or a separately defined later policy), not an automatic array-return hook; clearing HEADER pending at every immediate-only array could miss the intended cut. Prior41-control model SHA2159be97 and receipts are reused unchanged, with combined-transition/host/VM/memory-order limits explicit. Native targeted steps distinguish immediate failure exit from same-epoch retry and bind one producer; original20-second fixture remains unlocated. No runtime/qualifier/history/peer edits, native/model rerun, inventory, commit/push or budget change;8/12 remains.


### 2026-10-24 Split failure return, observation and retry; refused cleanup

[New handoff](../evidence/research/smp-retirement-study/scan-failure-window.md) fixes the earlier combined-transition limit by modeling failure recognition, local revoke, cleanup/return exposure, observation before retry, retry entry and used-slot refusal separately. Source edits remain proposed: revoke in cleanup_failed_pstate entry and interrupt error5868, before VM publication-failure sync teardown, close before direct global symkey error7870, and pre-close before global error cleanup7957. Independent live cleanup refusal must keep its existing session open; error-setup cleanup refusal must already be closed before fatal-handler handoff.

The new scan_failure_handoff QNT has9 positive safety checks,9 expected mutant counterexamples,9 target reachability witnesses and1 process-termination witness (28 new controls), all within30 seconds per check. RetryOnly fails before retry despite clearing at retry entry; LateArm reaches a stale admission in the still-live-descriptor observation window; RefusedCleanupOpen reaches actual modeled refusal before violating closedOnRefusal. Prior41 checks/model bytes remain unchanged. This is conditional protocol evidence, not proof of an ordinary Scheme path into a failed processor, actual C nonlocal escape, roots, native CPU ordering or callback termination. Same-producer hooks and snapshots are specified. No runtime/qualifier/history/peer changes, native inventory or other native run, commit/push or budget increase;8/12 remains. A fixed reaper is a different owner from P0 and cannot satisfy the existing same-owner transcript by relabeling.

### 2026-10-24 Lifecycle contract split from interrupt and TFIB stability

[Split handoff](../evidence/research/smp-retirement-study/split-contract-stability-handoff.md) separates the count contract from runtime stability. On the legal Darwin shrink, no errno-then-same-owner-join-0 path is proved reachable, so that path is not an implementation task. The implementable lifecycle target is one reaper fixed from its first join, pending retention of handle, incarnation and roots, transfer only after a real join 0, ownership retained on error, and one consumption of the completion. That target is not 9/12 and needs its own contract review. Interrupt repair has to close unique queue ownership, enqueue commit, migration recheck, and one execute-or-terminate reply. Thread-queue enqueue plus concurrent wakeup already failed native batches and is not a candidate again. TFIB still lacks the original fault's first illegal scan record; a null probe only checks the diagnostic carrier. Cells without a same-binary cause are marked 尚无方案. No runtime, qualifier, recipe, history, model rerun, commit, or push. Count remains 8/12.


### 2026-10-24 Delivery integration has native precedent; current lock lacks the complete mechanism

[Implementation contract](../evidence/research/smp-retirement-study/stability-integration-contract.md) narrows the stability work to one coherent delivery change. All26 scan-session-cut locked source hashes were checked, and the seven-file owned-request native reference was reconstructed exactly from retained before snapshots. Three raw receipts and eight retained flood logs rehash against GSI1a32b364; those are historical targeted passes, not fresh execution or current-lock qualification. Current source still has two-field result requests, P/T route choice, no independent notify/wake/execute/drain helpers and no capped wait backend. Do not transplant seven older files: preserve current routing/migration/SYNC/acquire/lifetime improvements. Integrate thread-owned request plus independent procedure hints, stale-hint predicate before BTQ/TOQ removal, unified active/reply/abandon ownership and real-deadline scheduler return/fault handling. Same-producer codegen and targeted controls are specified. The shared link alone is not a newly proven corrupting interleaving; exact historical blocked-R attribution remains absent.

TFIB's published binary/UUID/PC binding remains separate. Its old run-local crash audit receipt is absent at the named cache path; this audit records that gap rather than claiming fresh raw-PC verification. New original-load context must select scan-range, frame-map or earlier-writer repair. Injected null faults and independent delivery passes cannot choose that correction. Existing lifecycle observer/history/recipes and8/12 are unchanged; no runtime edit, peer operation, native/model rerun, whole inventory, commit or push.


### 2026-10-24 Function-level delivery rebase and three untested boundaries

[Current-lock function matrix](../evidence/research/smp-retirement-study/delivery-function-alignment.md) classifies each relevant Scheme/C function as reuse, merge or rewrite. All26 lock hashes and13 source controls verify; no native/model rerun. Preserve current T/P SYNC retries, migration target consumption, mutex head re-reads, Darwin acquire-read and explicit native-wait RA/register saves. Reference notify uses unchecked raw id; current source has no general checked P request lease. The default integration avoids delayed-id use by fresh Scheme hint publication under a revalidated P lock plus explicit unlocked wait/heartbeat service; existing runnable helpers' hidden post-unlock abort must also be avoided or actually lifetime-admitted. This is new work, not covered by historical8/8.

The reference dynamic-wind ends after thunk/catcher, before result store/unlock. Current unlock has heap check and SYNC retry; its full envelope needs protection. A request-specific cleanup must inspect actual mutex ownership and abandon only while target still owns it, never unlink after transfer to sender. Initial duplicate admission also needs its predicate before BTQ/TOQ removal. Native controls explicitly cut before and after actual transfer, permit nested service and preserve deadline/lock state. Donor-empty checks do not hand off Scheme hint queues: concurrent shrink needs legal service/transfer or early refusal before count change; a callback cannot wait for its own completion. Twelve same-producer controls specify this boundary. All runtime/qualifier/history/Recipe/peer inputs unchanged; no native execution, commit or push;8/12 unchanged.

### 2026-10-24 Early shrink refusal and linked-owner release

[Shrink and release protocol](../evidence/research/smp-retirement-study/delivery-shrink-owner-protocol.md) is now in `patches/fixtures/delivery-shrink-release-cumulative.patch`, sha256 `0c6e9e14d60a69faf4fb93e7a2ace56aebe708b259dc5cb3f485ec5a31510653`. Result requests stay on the target thread queue. Processor queues get a fresh Scheme hint. `delivery_admission` closes only by CAS from exact open zero, inside the elected resize and before `___vm_resize_pstate`. A nonzero count returns one `UNKNOWN_ERR` through the existing result round and does not write count, target, or pending join fields. Nonempty hint transfer is not implemented. Abandon unlinks once only when the mutex is still fully linked to the target. A self-linked mutex that still names the target is retained as phase 5 and is not passed to `##btq-abandon!`. Generated `_thread.c` was not regenerated, and the twelve native controls were not run. Count remains 8/12.

### 2026-10-24 Release leaf, procedural unlock and stale ACK

[Commit and return checklist](../evidence/research/smp-retirement-study/delivery-commit-entry-return.md) is partly in `patches/fixtures/delivery-commit-entry-cumulative.patch`, sha256 `ff2ea488b403bb66f9917e67d98a38e8d5bb29ed50d98f9fa96a77a198dffaf2`. A procedural callback error returns while the native mutex is already unlocked. Cleanup releases one detached header outside the lock and keeps the remaining suffix when that release fails. A mismatched delivery-guard generation sets `delivery_fault` and does not reopen delivery admission or the outer sfun gate. `___thread_intr_release_commit` stores the prepared link, owner and phase with no lock and no allocation; abandon calls it only for a fully linked target. The success path still uses generic `macro-mutex-unlock!`. Generated `_thread.c`/`_kernel.c` and the same-producer controls are absent, so this is not a closed loop. `lib/setup.o` compiled. Count remains 8/12.

### 2026-10-24 Procedural suffix return; leaf audit stopped

[Procedural suffix checklist](../evidence/research/smp-retirement-study/native-leaf-procedural-suffix.md) does not supply a reachable 9/12 path. The callback fix is in `patches/fixtures/procedural-suffix-cumulative.patch`, sha256 `6aca28e02e43991b90c17784c758f953541cc7feec06f799bb0681eae2c905cf`. Service copies the callable, unlocks, and on error returns unlocked without restoring the queue or retrying that callback. OTHER stays set. Cleanup calls the copied release outside the lock and keeps the suffix when release fails. An unlock failure sets `delivery_fault` and does not run the callback. `___thread_intr_release_commit` is not certified as a no-GC leaf: there is no final-producer preprocess or object graph. Generated C was not regenerated. Count remains 8/12.

### 2026-10-24 Prepared owned release

[Owned release](../evidence/research/smp-retirement-study/owned-release-restructure.md) is in `patches/fixtures/owned-release-cumulative.patch`, sha256 `a1ec07eaa5832c070f6b72b22f724b9675decf0146b14ee269f0de7082e053d3`. Release takes the mutex, then ordered thread and processor locks, and drops them before SYNC. Commit repairs both neighbor fields. The waiter comes from the blocked-tree leftmost. Prepared signal does not call `##mutex-signal-no-reschedule!`. A partial self-link stays phase 5 and keeps the target pin. The linked gsc still cannot start, and `_thread.c` is still the old generated file, so this source has not been run against `thread_interrupt_stress.scm`. Count remains 8/12.


### 2026-10-24 Early shrink refusal, rooted hint eligibility and physical-release ownership

[Function protocol](../evidence/research/smp-retirement-study/delivery-shrink-owner-protocol.md) selects complete-delivery-debt refusal as the first implementable shrink policy. Put the common old-cohort guard before execute_sync_op calls ___vm_resize_pstate: current code changes target bookkeeping before heap guard and pending join fields before count commit. Admission/count must share an atomic word; include publisher-before-enqueue, active/queued request, hint and sender/result/cleanup consumers. Pins are not GC roots. No Scheme callback in the native guard; refusal preserves old roots/count and cannot wait for its own callback. External unregistered void publishers invalidate zero; checked ingress or proved host quiescence remains required. Nonempty handoff is optional and only for tagged relocatable hints with surviving target and actual receiver root, no active donor/native reader/lock preparation gap. Ordinary processor procedures cannot simply move to P0.

A new source gap is explicit: slow unlock removes the old owner-list link before setting the new owner. Actual owner equality alone does not make raw abandon safe. Prepare fallible/participating acquisitions before a no-GC/no-escape ownership commit; preserve mapped pending-wake and sender-result responsibility afterward. Partial-unlink fault retains generation/pins, not successful rollback. Final delivery_shrink_release QNT has9 safety,12 decoded mutant and9 reachability controls (30 total), all under30s/case. Sender/executor liveness is explicit; the release-before-sender-consumption mutant reaches unsafe shrink. Partial-unlink owner-only cleanup also fails as intended. Eligible handoff is a conditional model, not implemented C; no fairness/C11/generated-map/native proof is claimed. Earlier26-check version is retained and not added. Source26 hashes and9 shape controls verify. No runtime/qualifier/history/Recipe/peer operation, native run, commit or push;8/12 remains.

### 2026-10-24 Release commit, entrance registration and common return

Current scan-session-cut lock/main7c490c3 remains authoritative. Evidence-only continuation: `evidence/research/smp-retirement-study/delivery-commit-entry-return.md` and matching JSON bind26 current source files, separately unadmitted generated references, and an entrance census. The current native procedural callback error edge breaks while unlocked and reaches a second unlock; source-confirmed, not a native crash attribution. Grok steps separate fallible preparation, bounded no-GC/no-escape native commit and rooted WakePending finish, cover nine entrance groups including legacy/native/reset paths, and preserve common guard result plus outer normal/throw sfun cleanup. Stale collective phase cannot use ordinary reopening. Forty new QNT controls matched expected safety, decoded negatives and reachability under unchanged30s case caps; receipt `.cache/tasks/repair-9-12/processes/audit/runs/5dac6b0fc04249eb828f6b16c1d1225b/outputs/delivery-commit-entry-return/receipt.json`. Generated SMP maps/leaf object purity, native lock balance, ABI caller coverage and same-producer tests remain required. No runtime/qualifier/history edit, native run, peer action, commit or push; count remains8/12.

### 2026-10-24 Native leaf macro boundaries and procedural error suffix

Evidence-only follow-up `evidence/research/smp-retirement-study/native-leaf-procedural-suffix.md` / JSON verifies26 current-lock files and12 source conditions. The macro inventory preserves conditional definitions rather than inventing configured preprocessing. Extra immutable main `_gambit#.scm` binds slot access expansion; installed producer binding remains open. Store operations resolve through UNCHECKEDSTRUCTURESET/BODY_AS/FXINDX, while Darwin GCC stack writes and emulated synchronization can call helpers. The proposed release leaf is absent; real generated-C/frame and object purity certificates remain mandatory. Current procedural callback non-NO_ERR skips relock then reaches trailing unlock; Grok must return already-unlocked, retain untouched/shared suffix and OTHER retrip, and keep self-free-safe activation context. Cleanup must detach/release outside mutex with checked status and retained escape/partial-release ownership. Ten new conditional QNT controls matched expected lock/suffix/pin/free witnesses and reachability under30s case caps; receipt `.cache/tasks/repair-9-12/processes/audit/runs/09c01640dc924e79b816e1120a6a9b59/outputs/procedural-suffix-lock/receipt.json`. Set-based model proves no FIFO or arbitrary native escape recovery. No runtime/qualifier/history change, native run, peer action, commit or push;8/12 unchanged.

### 2026-10-24 Procedural-suffix activation, root and cleanup audit

New authoritative source is `procedural-suffix.lock.json`, patch6aca28e02e43991b90c17784c758f953541cc7feec06f799bb0681eae2c905cf;26 candidate hashes reconstructed from immutable main7c490c3 and verified in audit snapshot `.cache/tasks/repair-9-12/processes/audit/runs/ae318b67840c43229f1121df652dfd82/outputs/activation-current-lock-source/receipt.json`. The ordinary error double-unlock/header-read edge is fixed in source; setup.o compilation is user-reported, with no final regenerated producer. `activation-root-escape-cleanup.md`/JSON binds exact new coordinates. Snapshot execute_fn/self are native locals, not a persistent activation or GC root. Existing RC scans only header.data, has unsynchronized owner-local intrusive mutation, and cleanup_rc ignores refcount; nested saved[] slots cannot anchor outer lifetime. Raw ___run still kills marker inside TRY, so thrown paths can skip it. New concrete cleanup gaps: empty-queue unlock failure returns NO_ERR; mutex destroy result is ignored; cleanup_pstate_locked and cleanup_failed_pstate discard cleanup errors then continue memory destruction. Lock-outside release still runs under some outer registry locks or post-shrink membership; implement preparation before those boundaries and callback-free checked destruction. Sixteen conditional QNT controls matched expectations under30s caps; model run retained prior scan-lock provenance and new source correspondence is a separate audit. Initial model compile failure and pre-subprocess storage-policy refusal retained; own audit reconciled without peer operations. No runtime/qualifier/history edits, native run, commit or push;8/12 unchanged.

### 2026-10-24 Freeze protocol scope: one interrupt-delivery integration

Primary implementation order is now `evidence/research/smp-retirement-study/delivery-integration-handoff.md` with JSON and `delivery-integration-native-plan.json`, against procedural-suffix lock/patch6aca28e0. All26 source identities and12 concrete source conditions rechecked. Current code already contains T-only requests, separate hints and explicit unlocked service; reuse those. Required corrections are exact pin transfer/unpublished-hint/escape release, locked-P versus reloaded-route identity, true owner-deque neighbor removal (the current leaf only self-links), real blocked waiter selection and signal lock preconditions, guarded last release and checked cleanup refusal. Six integration steps lead to one actual regenerated/linked producer. Immutable main original tests/loader/include bytes retained in audit output; 100000 flood remains short control, not substitute for original6000000 and six-state million-iteration interruption fixtures. Two originals share at most existing3600s stress window with unchanged topology/heap/loader and source-bound retry rules. Six diagnostic groups must identify a real LOCK2_ENTER without RETURN request and its committed prefix; missing/overflow records are UNKNOWN. No new protocol/model, native run, runtime/qualifier/recipe/history edit, peer action, commit or push. Producer binding remains null/executionReady=false;8/12 unchanged.

### 2026-10-24 Selected algorithm for owner adjacency, waiter and pins

The user requested concrete QNT-backed choice rather than another constraint list. `owned-release-restructure.md`/JSON selects request-specific all-locks-prepared mutation: M then unique ordered thread trylocks and coalesced TOQ/destination P trylocks, full release/SYNC/reload on contention; validate reciprocal owner links and actual M.leftmost; repair both neighbor fields before self-link; factor the mutation semantics of signal without its inverse/drop-lock acquisition branch. A guarded target/sender/hint unit scheme uses current vector CAS new/old order; private ID remains4 and target unit uses5. Function/field/pin table and same-producer short controls are explicit. Existing research plus immutable Chez41d5ffca/OCaml46e1c324 reference excerpts bound as limited design sources, not Gambit proofs. Fifteen focused QNT controls matched safety/decoded wrong-neighbor/waiter/lock/retry/unpin mutants/reachability under unchanged30s caps; no starvation/actual root-map proof. The native plan was refined but producer remains null and executionReady=false. No runtime/qualifier/recipe/history change, native test, peer operation, commit or push;8/12 unchanged.

### 2026-10-24 Prepared signal: concrete native no-GC boundary

`prepared-signal-native-commit.md`/JSON binds26 current procedural-suffix files and20 source conditions. Corrected preceding destination rule to migration-target→pinned→current-P. Selected one native nonblocking try-commit, including W-only discovery/release then unique ordered T/W/N and Q/D tries, revalidation, owner-neighbor unlink, BTQ/TOQ remove, resume/owner state, runnable insert, pending-D root and unlock. Retry returns zero locks before Scheme SYNC/GC. Port three iterative native tree kernels from current define-rbtree rather than relying on separate generated Scheme procedures under locks. Both normal and abandoned result release move together; early phase1557 is delayed to consistent commit. R-unit [armed,pending-D] retains notification destination through post-lock last use. Source gaps explicit: conditional grant acquire and volatile TRYLOCK read; bound abort ignores errors and native wait can be infinite, so prior scheduler-return proposal is not claimed installed. Actual generated maps, layout/oracle parity, object no-GC purity and same-B original pressure remain required. No new model run, native execution, runtime/qualifier/recipe/history edit, peer action, commit or push;8/12 unchanged.

Final refinement of that same native boundary: explicit unit argument selects R for target Normal/Abandon and lexical S for SenderFinal. Sender lock2 return/error guard final-unlocks the actually owned private mutex with no-waiter validation before S release, preserving request result/phase; no generic slow fallback on an unexpected waiter. Truthy non-thread N is retained/invalid before mutation. No native implementation or additional model claim.

### 2026-10-24 Failed notification ownership and no-GC/root certificate

`evidence/research/smp-retirement-study/delivery-service-roots.md` selects a finite integration: canonical queued work transfers responsibility to an admitted scheduler before the best-effort OS wake; native try-commit is pure/nonblocking and roots reload at unlocked retry/finish. Source correction: SMP bare idle already returns at50ms (`_thread.scm3227..3238`); the device/no-sleeper branch3247..3252 still passes infinity. Preserve P reacquire/device publication then unlock3262 and service3264; cap only scheduler waits without changing user deadline or setting readiness. Notification failure alone does not require an infinite producer-pin retention once durable receiver/domain ownership is proven; unknown ownership/native use still retains.

Quint/TLC15 controls matched expectations (3 positive safety/conditional-progress,9 decoded safety negatives,1 temporal no-bound stall,2 feasible permanent-wake-failure completion witnesses). Logs/receipt: `.cache/tasks/repair-9-12/processes/audit/runs/2389cea949e24b4ba5b2a5a606787fc1/outputs/delivery-service-roots/receipt.json`. Weak fairness, finite waits/obstruction and managed-owner participation remain explicit premises, not source facts. The actual generated-C/object/map certificate is null; source-package generated references are not admitted. Current lock inputs/protected qualification/history were hash-checked unchanged. No runtime edits, native compile/test, peer action, commit or push. Qualification remains8/12; TFIB/lifecycle/Gerbil/release remain independent.

Final limitation recorded for this same refinement: finite OS select is not a proof of finite P reacquire at os_io.c11782 or scheduler fairness. Same-B contended-P/pending-SYNC service is mandatory; no GC/callback may be added to the unmaterialized native condvar-array loop. Model pin is aggregate protection, not an implemented R/S/H release certificate. These remain explicit native certificate requirements, not model-established facts.

### 2026-10-24 Device return P reacquire and pending SYNC

`evidence/research/smp-retirement-study/device-relock-sync.md` replaces the provisional unconditional native P reacquire with a concrete capture/poll/try-deliver/finish split. Current os_io.c11782 blocks for P without SYNC; a P owner awaiting this GC participant creates a conditional cycle, not yet an identified historical failure. Raw condvars[] may not cross a newly inserted GC. Proposed scanned wait capsule preserves per-record readiness across unlocked SYNC and two moving GCs; native try-commit owns/returns all locks and uses epoch/borrow checks. All selected SMP scheduler callers must migrate together.

Additional source-visible mismatch: _thread.scm2893 unlocks P before2894 calls device-condvar-broadcast, but4477..4482 assumes P and detaches the deq. Replace that detach/signal with the pure prepared path; old generic broadcast is not a no-GC leaf. Checked device wait borrows must also constrain direct close, foreign cleanup, release and group cleanup; plain POSIX refcount is insufficient.

Quint/TLC14 expected controls passed:2 positive safety/conditional-progress,9 decoded safety negatives,1 conditional cycle temporal negative and2 completion witnesses, including two-result partial progress/two GCs/second-epoch old completion rejection. Receipt `.cache/tasks/repair-9-12/processes/audit/runs/f12ec6dce9024caaa13d6c252a4aa7c4/outputs/device-relock-sync/receipt.json`. All26 bound source hashes/protected qualifier/history rechecked unchanged. Actual regenerated C/map/native certificate remains null; native runs0, no peer operations/commit/push, count8/12. The handoff gives implementation/acceptance order without asserting the historical hanging request or closing TFIB/lifecycle/Gerbil/release.

### 2026-10-24 Scheduler deadline and native try-release

`patches/fixtures/delivery-service-roots-cumulative.patch` (SHA256 `a303931266e5773a9b089d7dec9ad094c112ac9fb776945288e41b4adaa1e625`) applies with `git apply --check --whitespace=error` on lock main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Drain claims a result only while holding the target lock and only from phase 1 to phase 2. Active and terminal nodes stay on the queue and the scan continues to a later queued request. After the thunk returns, the same request object is found again from the queue root and removed only if its phase is 3 or 4. Slot 6 is a one-shot capability: the claim arms it, the first dynamic-wind entry consumes it, and a captured continuation that enters again is refused while the request remains queued for termination. `___os_condvar_select` computes one `D_eff=min(D_user, now+0.05)` for both the empty-device and device-set paths. `#f` stays an immediate poll. `#t` is the explicit infinity case and becomes `now+0.05`. Repeated `EINTR` reuses that same `D_eff`. Port close waits at the direct `___device_select` infinity calls are unchanged. After select returns, the processor lock is reacquired, device readiness is published, then Scheme unlocks P and services. That reacquire is still the existing primitive lock; the scanned wait capsule in `device-relock-sync.md` is not implemented.

`___thread_intr_try_release` is one ordinary C call. It trylocks, and on contention unlocks everything and returns retry before any queue write. Scheme then runs unlocked SYNC and calls again, discarding the previous W/N/Q/D. The commit body does not call Scheme, allocate, or take a blocking ticket. Grant reads use an acquire load, including Apple clang. A result request stays on the target queue until its thunk returns, so thread termination can abandon that same request. Sender final release does not drop the target pin.

The regenerated wrapper for `##thread-intr-try-release!` spills the live request, mode, unit and action registers to the stack before the SYNC retry and reloads them on return. The native call itself has no `W_ALL`. That is not a frame-map or object-code certificate. `actualGeneratedBridgeCertificate` stays null. Same-tree gsi `f016292e644b3833a0379cb872d72bc50268333b998ec093ac2e0db919cc0245` finished the yield control with one thunk entry, result 41, and one request queued behind the active thunk also ran once. Termination during yield abandoned once. A captured continuation reentered the dynamic-wind and was refused. 200 interrupts then exited 0 with 0 failures. The original 6_000_000-iteration stress files were not run. Concurrent shrink while a queued interrupt remains is still refused by the admission pin, not by a new handoff. Vendor HEAD stayed `8d2b40341a80083ba90e3f8e77d256d49b3e257a`. Qualification remains 8/12.

### 2026-10-24 Review of runnable delivery implementation: retained-Active dispatch guard

`delivery-service-landed-review.md` binds the621449cf cumulative patch and existing landed record without reading or operating the peer producer. It recognizes native try-release/deadline implementation progress while retaining null generated-map/object certificate and unimplemented device capsule/P reacquire. The landed record distinguishes returned41 followed by exit70 on a subsequent join from the separate200-interrupt exit0 run.

Patch-level new finding: result requests remain queue-reachable during their thunk, yet drain unconditionally writes phase2 and executes the result head (patch2126..2128); resume and unlocked service call drain again. Yield/migration/nested service can therefore expose duplicate dispatch; phase2 is accepted by execute. This is a source-visible missing guard/path hypothesis, not a captured native duplicate or historical-hang diagnosis. Grok should claim only Queued1→Active2 under T, scan past Active/terminal nodes so eligible suffix is serviced, and re-find/unlink only the rooted claimed object after GC/reentry. Preserve termination reachability and once-only unit settlement; captured-continuation reentry additionally needs a real activation capability or explicit rejection, not a phase-only claim.

Focused same-B controls are listed for yield/migration, active-head suffix, terminal-before-unlink, termination and continuation boundaries, under unchanged30s caps. No runtime/qualifier/history edits, no native/model execution, no peer operation, commit or push. Count8/12.

### 2026-10-24 Active dispatch/suffix claim and completion unlink

`active-request-drain.md/json` binds621449cf patch-derived source snapshots reconstructed from immutable main7c490c3 (no runtime checkout edit). Queued1 alone may claim2; skip Active/terminal and continue suffix; procedure hints selected in the middle require exact detach. Preserve existing post-execute identity scan but require actual target R settlement or persistent rooted Retained handoff before unlink. Native terminal3/4 does not mean notification/R finish completed.

Termination must publish a rooted detached owner before clearing the queue, keep a failed/Retained node reachable while settling unrelated suffix, and not treat a native pin/fault bit as a Scheme root. The proposed small native claim/unlink leaves return unlocked for SYNC. Normal yield/migration resumes the original activation; runtime dispatch grants are distinct from arbitrary user multi-shot continuation side effects.

Final QNT16 expected controls passed (3 positive,9 safety mutants,1 temporal Active-head stall,3 witnesses). Receipt `.cache/tasks/repair-9-12/processes/audit/runs/dc108bb4cd8e44b9b19f6ba6fde6b9e1/outputs/active-request-drain/receipt.json`. It models a three-node chain, partial terminal/R finish and detached retention; Retained observation completion is not target teardown. `active-request-minimal.scm` provides unexecuted same-B yield/nested/migration controls under original30s cap. No native execution, runtime/qualifier/history modification, peer operation, commit or push. Actual generated certificate remains null; count8/12.

### 2026-10-24 Active dispatch/suffix claim and completion unlink

`active-request-drain.md/json` freezes naturally published a3039312 inputs and patch-derived source snapshots reconstructed from immutable main7c490c3 (no runtime checkout edit). The new guarded source and reported f016292e controls are distinguished from original621449cf/bef5468f. Queued1 alone may claim2; skip Active/terminal and continue suffix; procedure hints selected in the middle require exact detach. Preserve existing post-execute identity scan but require actual target R settlement or persistent rooted Retained handoff before unlink. Native terminal3/4 does not mean notification/R finish completed. Current payload storage precedes native owner validation; move it behind that same check with rooted outcome/grant operands, preserving whichever terminal outcome committed first.

Termination must publish a rooted detached owner before clearing the queue, keep a failed/Retained node reachable while settling unrelated suffix, and not treat a native pin/fault bit as a Scheme root. The proposed small native claim/unlink leaves return unlocked for SYNC. Normal yield/migration resumes the original activation; runtime dispatch grants are distinct from arbitrary user multi-shot continuation side effects.

Final QNT19 expected controls passed (4 positive,10 safety mutants,1 temporal Active-head stall,4 witnesses). Committed success is preserved through later termination; late payload overwrite has an independent negative. Receipt `.cache/tasks/repair-9-12/processes/audit/runs/3f7ebac3414a4aaea2428f32e51b8c9b/outputs/active-request-drain/receipt.json`. It models a three-node chain, partial terminal/R finish and detached retention; Retained observation completion is not target teardown. `active-request-minimal.scm` provides unexecuted same-B yield/nested/migration controls under original30s cap. No native execution, runtime/qualifier/history modification, peer operation, commit or push. Actual generated certificate remains null; count8/12.

### 2026-10-24 Settled unlink, retained root, and payload publication

The cumulative patch file now has SHA256 `35387b60dad77e6af5bf78fc7e4dc3cf7adc10ffcf12e4fb24cba7542294ccd9`. The previous bytes remain `a303931266e5773a9b089d7dec9ad094c112ac9fb776945288e41b4adaa1e625` with gsi `f016292e644b3833a0379cb872d72bc50268333b998ec093ac2e0db919cc0245`. `git apply --check --whitespace=error` passed on `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Drain still unlinks a request only when its phase is 3 or 4 and target R is settled: unit slot 0 is 0 and pending-D is absent. Termination saves the detached successor, calls release with no payload, and publishes any other disposition on VM structure slot 2. The link is R-unit slot 2, not request slot 0. `mark_vm_scmobj` already scans that VM object. `___thread_intr_try_release` writes mutex specific only after the owner, tree, grant, and phase-2 checks, and only for a two-slot outcome. Sender final and `#f` leave the stored value unchanged.

A migrating thread that is sitting on another processor's local run queue is removed and inserted on its migration target before `##thread-restore!`. Steal re-reads the migration target after the thread trylock and leaves the thread on that queue. Resume still refuses to run an interrupt on a processor that is not the recorded target. That refusal is not a second execution of the thunk.

Same-tree gsi `066f07d2849faef91e4d25b624aee00530d0fd28c9dcc89257791fdc27f5ce3a`, compiler `be9dc33152bd2dcdc9650878eab3c68c6bf14a8b57aea2c8f26c786ce1fb9c4e`, ran `active-request-minimal.scm` with `-:p11` and a 30 second cap. Yield once and nested once printed CONTROL-PASS and exited 0. Migrate did so on 20 of 20 runs. Generated `_thread.c` came from that gsc. `actualGeneratedBridgeCertificate` stays null. The 6_000_000-iteration stress was not run. Vendor HEAD stayed `8d2b40341a80083ba90e3f8e77d256d49b3e257a`. Qualification remains 8/12.

The same frozen image was then inspected in `delivery-generated-c-certificate.md`. Gsi UUID is `09F95D98-2CCA-3830-AF60-2C940273CD0A`. The try-release SYNC return map covers the request, unit, both actions, outcome, and grant, and the `-O3` object closure of `___thread_intr_try_release` has no allocator or poll. Admission still fails: `___fatal_error` has an unexpanded function pointer, the stack canary is unexpanded, linked `_kernel.c` is not the patched `_kernel.scm`, and the retain/execute/scheduler labels were not decoded. The certificate stays null.

### 2026-10-24 Exact 35387b60 producer roots and missing Retained consumer

`evidence/research/smp-retirement-study/producer-353-retained-audit.md/json` resolves the user-supplied `/tmp/gambit-7c490c3-activation` path: actual gsi is 066f07d2849faef91e4d25b624aee00530d0fd28c9dcc89257791fdc27f5ce3a. Exact-context immutable main7c490c3 plus patch35387b60 reproduces the three audited Scheme/native source files. Actual generated _thread.c is a180f93d6419ce4b448dd568e808f71ba8c0d0b336b7650ee11a7e7b0f6c1fef. Archive members match loose _thread/_kernel/setup objects; linked gsi has the changed bridge symbols. Registered artifact audit: .cache/tasks/repair-9-12/processes/audit/runs/44d936069bfb4dc19c903d864f41dd1a/outputs/producer-353-retained-audit/receipt.json.

Decoded actual return maps cover all seven release operands during unlocked SYNC, request/unit during retain publication retry, and detached request/suffix during termination release/retain. This is selected generated-map evidence, not the full transitive native no-GC or link-command certificate. Retained VM slot2 is scanned, but no retry/unlink consumer is implemented. MOVED with pending-D returns without retrying notification; normal drain skips terminal debt. The retain scan treats guard>1024 as absence; a literal 1030-node source-branch witness produces a cycle when re-publishing the deeper tail. Phase5 self-linked owner corruption is not a transient RETRY and cannot be auto-healed by decrementing the pin.

The handoff specifies notification-only idempotent finish, exact membership, a single bounded unlocked consumer using the existing VM root, classification of recoverable debt versus retained corruption, exact settled unlink and last-consumer custody. Eight same-final-producer fault-control groups retain30s/-:p11; no hook or native result is invented. No runtime/qualifier/Recipe/history edit, native execution, peer operation, commit or push. Full bridge certificate remains null; recorded count8/12. TFIB causality and lifecycle qualification remain independent.

### 2026-10-24 Retained integration: one finish owner, exact membership, last pass pin

`evidence/research/smp-retirement-study/retained-integration-353.md/json` selects function-level changes on frozen35387b60/066f07d2. Target unit gains membership and finish-owner fields; sender unit stays distinct. Existing VM slot2 remains retained root, unused SMP slot3 is proposed as the single scanned consumer context. Every unfinished valid target R is published even when still on a live queue, because ordinary drain skips terminal debt. Remove the1024 inference entirely. Per-R token ownership serializes body/after-thunk/termination/consumer; only notification is retried after a committed mutex transition.

Actual checked-abort backend retries EINTR against one50ms deadline and returns encoded EINTR on exhaustion, while Scheme currently treats that result as success. The specified correction accepts only backend0 and preserves D otherwise. A finite entry-snapshot consumer pass precedes arbitrary drain/hint callbacks, skips busy or integrity-failed A, and exact-unlinks settled B/C. A separate pass responsibility remains until all VM/context accesses finish, closing the zero-count window after last R decrement. No outcome journal, scheduler, lifecycle or reaper extension is added. Corrupt owner chains remain explicit unresolved faults.

The newly supplied generated-C certificate stays unadmitted: old _kernel.c does not contain changed _kernel.scm; host fatal callback/canary and remaining generated edges need closure in the new final B. Seven targeted same-B native control groups retain30s/-:p11; none ran here. Protocol cost and worst-case exact-rescan complexity are stated. No runtime, qualifier, Recipe/history, peer, commit or push operation; count remains recorded8/12.

### 2026-10-24 Integrated delivery closure: unwind arming and real VM destruction admission

The normative completion is appended to the existing `retained-integration-353.md/json`, not split into another independent feature. The prior isolated pass-pin sufficiency is withdrawn. Actual353 generated dynamic-wind calls before and then allocates/checks its environment; finish claim acquisition there has an unprotected failure interval. Acquire only inside the installed winding thunk, with a durable failure anchor, identity-checked nonthrowing/deferred cleanup and explicit stale-continuation refusal.

The current SFUN gate counts foreign frames only; ordinary ___run markers are explicitly not leases. Void/owned cleanup do not close delivery admission, global cleanup starts destructive side effects before its conditional shrink delivery check, and P0-only cleanup lacks that guard. Actual generated delivery-unpin still executes R1/JUMPRET and its caller after the final decrement. Thus the full chain needs combined destruction preflight and ordinary native-run/tail custody, rebound to existing run-entry research; pass pin alone cannot protect the generated return. Run lifetime must be distinct from SFUN/delivery participation to avoid preventing worker shutdown or resize. Workers native sync tails remain owned until real exit/join.

One final B must integrate membership/notification/consumer changes, the unwind-safe finish epilogue, run finalization outside END_TRY, all cleanup callers and regenerated Scheme/C. Five ordered whole-B injection groups precede the original failure workload; earlier local/model passes are not closure. No runtime, qualifier, Recipe/history, peer, commit or push change; no native/compilation/QNT run. Full generated bridge certificate remains null; recorded count8/12.

### 2026-10-24 Canonical integrated run/cleanup contract, not separate partial milestones

`retained-integration-353.md/json` is consolidated into one authoritative function-level handoff; exact earlier plan bytes remain in its registered publication snapshot. Frozen353 source checks expose another necessary path: a worker can directly thread_exit from resize, bypassing ___run finalization. Its native-owner records must stay counted through real join0 and safe root/memory transfer; legal shrink cannot be conditioned on ordinary worker run counts reaching zero beforehand. Recovery also needs a persistent OS_JOINED fact before borrower/transfer checks so a later retry never joins an already-joined worker again.

The plan separates destruction-only ordinary-run/native-parent lifetime from actual foreign frames and R/S/pass delivery duties. Child ___run return leaves its parent owner alive; the last host unit transfers into the unique destruction ticket rather than creating an unowned final-return window. PRIVATE_PREFIX, JOINED_DONOR, SELF_RETIRE and VM_DESTROY are checked cleanup purposes on one contract. Public pstate/VM/global cleanup, private setup/growth rollback, self-exit, both join0 branches and low-level memory/OS leaves are explicitly mapped. Unprepared retirement roots or unsupported raw host pointers cannot be made safe by forcing counters down.

One final B must contain the whole delivery/root/unwind/run/cleanup dependency set and regenerated kernel/thread C, then pass six ordered validation stages ending in the unchanged original failing interrupt workload. This audit ran source checks only; no runtime, qualifier, Recipe/history, peer, native/compiler/QNT, commit or push operation. Recorded count remains8/12; certificate null.

### 2026-10-24 Explicit native parent establishment and same-record destruction handoff

The canonical `retained-integration-353.md/json` now binds parent establishment to root main.c→setup→run→later cleanup, creator reservation→OS trampoline→worker startup, and checked external C/generated SFUN entry. Supplemental main/os_thread/c_intf/kernel Scheme sources are exactly reconstructed from frozen353/main7c490c3; receipt `.cache/tasks/repair-9-12/processes/audit/runs/96666dd004f74d14ba7d4da042299807/outputs/native-parent-source-353/receipt.json`. The baseline has no implemented parent-owner/owner-out ABI. Root parent must survive ___setup return, worker parent must exist before OS create and survive child run into native SYNC tails, and foreign child frame_leave must not release its enclosing native owner before propagate/error conversion.

Current pthread_create code assigns thread_id only after OS create returns; startup cannot depend on that late assignment. thread_init_common currently always succeeds, so no extra failure stage is invented. Generated CFUN R_ALL/ps temp accesses, SFUN propagate_error after frame_leave, delivery-unpin caller return and kernel outward exit are explicitly mapped to required parent protection.

Final transfer is one identity/state CAS on the existing HOST_OWNER record to DESTROY_OWNED with its count retained, not decrement-then-publish of a second ticket. The charged unit is consumed only at the last live VM metadata boundary under exclusive destruction ownership; remaining DONE/status storage is host-owned. Registry/global tails and partial destructive prefixes remain ticket-owned. New root/worker/callback/ticket-race controls are integrated into the one final-B sequence. No native/compiler/QNT execution, runtime/qualifier/history change, peer operation, commit or push; count remains recorded8/12 and certificate null.

### 2026-10-24 Checked owner ABI v1 fixed in canonical integrated handoff

`retained-integration-353.md/json` now fixes eighteen checked C signatures, a32-byte by-value handle and an80-byte result for the selected64-bit profile. Public results distinguish surviving owner/run/worker/ticket from DONE and preserve original/cleanup status independently. Version/size prefix is validated before admission mutation; stale keys resolve through process-stable native journal metadata before VM dereference. Native owners/children, pre-create reservation, real OS outcome/join fact and exact destruction prefix are separate owned fields.

Root owned setup/main, external attach, child run/marker finalization, worker reserve/create/claim/retire/join and destroy begin/step/finish are one ABI migration, with no unchecked GSTATE/legacy fallback. Child run must disable its marker before returning past the C frame even when other cleanup is retained. Ticket transfer is the same owner record/key and charged unit, with fixed before/after-CAS failure semantics; unknown physical-free outcome is not automatically replayed. Ordinary run lifetime remains destruction-only and cannot be charged as a foreign frame/delivery duty to block legal shrink.

The existing one-final-B sequence includes six ABI/creation/unwind/transfer controls followed by the original failure workload. Layout arithmetic and declaration checks are documentation checks, not a native ABI certificate. No runtime, qualifier, Recipe/history, peer, compiler/native/QNT, commit or push operation; count remains recorded8/12 and bridge certificate null.

### 2026-10-24 Current b945 checked-owner integration audit and complete same-B sequence

The actual temporary gsi hash matches b9451859ab973ed8c108db25623a1c812fa38074836de344cb27a4ba8473cc9f. Adjacent current source/generated C/object/archive hashes are preserved separately in the registered audit receipt referenced by retained-integration-353.json. No immutable source-to-binary build binding was found in this audit; the UUID and miniature passes remain user-reported.

The canonical retained-integration-353.md now adds one current-source integration assessment and final-B verification order. Public run APIs are result-only stubs; public worker reserve/create are not wired to actual creation and reject invalid preparation keys incorrectly. The journal has no active lifetime serialization and setup authorization is a global boolean. Current cleanup marks DONE before finish accepts it, while finish can discard its record after a failed final debit or before a completed step. The source conflict with reported normal exit0 is preserved rather than attributed to a binary without build provenance.

The same ABI must now denote actual transitions: pinned actor-checked journal lookup, private owned setup, one actual run/marker implementation, traced pre-create worker reservation and startup ACK, fixed join ownership, one scoped cleanup cursor/final debit and host-only finish. Ordinary-run lifetime remains destruction-only so legal shrink is not forbidden. The integrated handoff specifies failure cut points and exact receipt fields followed by the original unmodified interrupt stress on one final B; it does not add another protocol or substitute model/miniature success. Runtime/qualifier/history/peer untouched; no native/compiler/QNT execution, commit or push. Recorded count8/12, actual generated-C certificate null.

### 2026-10-24 b945 linked-code binding and finite repair closure criteria

Read-only nm/otool/dwarfdump of a frozen copied b945 verified UUID356F8E27-5E76-32F4-94ED-56560B07FA44. Archive main.o/setup.o equal loose objects; twelve selected setup function instruction streams match executable bytes outside recorded Mach-O relocations, with linked control flow inspected. The result-only run APIs, worker reserve/create gap, unpinned journal/global setup gate and failed-debit/free path are now tied to actual b945 code, not just adjacent source. A full historical compile manifest and generated root certificate remain distinct.

retained-integration-353.md/json now contains one ordered C→A→B→D implementation plan and six conjunctive final-B acceptance gates. They define when the scoped interrupt/lifetime repair can be declared closed and where an unsuccessful control points to the next concrete code defect; no generic protocol expansion or new model pass is required. Original unmodified pressure mode/argv/budgets must be retained. Exit0 alone does not establish that the complete begin/step/finish teardown ran.

Literal lifecycle credit requires independent review of a reachable pending→same designated owner/incarnation real join0 two-receipt contract preserving rooted retention, one join, one post-join transfer and failure ownership. Pending cannot become OS errno. No qualifier/Recipe/history/runtime/peer change, native/compiler/QNT execution, commit or push. Only registered audit inspector subprocesses ran; recorded8/12 unchanged.

### 2026-10-24 d64 thread-exit crash cause and dynamic-wind context review

Observed gsi d64a3b12c753991cf600a56e7915bbc2b800e890c7f8bd4a394b4a7bbd6760dd/UUID1092445F-495B-3CEC-B6B6-F6C79C0E4D1A is bound to its actual _thread.o/generated C for the two selected functions. Exit now detaches current before clearing denv in a call-free store sequence, corroborating the user-reported removal of the immediate dynamic-wind/#f read crash. This is a real causal advance, not inherited evidence from b945.

The new false-context dynamic-wind branch executes before, then straight-line thunk/after without dynwind registration. Its ordinary return label does not guarantee after on exception/continuation escape. Valid-denv behavior remains on the original recorded path. The canonical integrated handoff now keeps the exit repair, prioritizes proving/removing or narrowing the general fallback, and specifies same-B abnormal-exit/idle/all-blocked controls tied to finish claim/pass responsibility. No new protocol or model.

User-reported partial progress and retained debit/drop negatives are preserved separately from independently inspected artifacts. No full go6000000 completion; short progress/CPU observations are not a proof of final duration or a pass. Preserve the original3600s budget and old TFIB evidence. No native/compiler/QNT execution by this audit, runtime/checker/history/peer change, commit or push; recorded8/12 unchanged.

### 2026-10-24 d64 no-fallback cleanup, continuation and all-blocked function plan

The canonical integrated handoff now fixes one implementation order against immutable d64 source/generated-C snapshots. Restore real dynamic-wind; keep detach-before-denv-clear. Move existing retained publication before acceptance, prepare the existing cleanup token before Active claim, and use one native non-escaping cleanup core from real after, the pre-installation error catcher, termination and idle. A phase2 Active thunk is not eligible for arbitrary abandonment; only its actual closed/deferred after handoff or validated termination permits cleanup.

Two source-specific reuse gaps are explicit: ___thread_intr_try_release rejects false-current callers through its type sample, and the existing retained walk can clear a deferred owner then skip its remaining phase2 duty. Factor validated private cleanup/wake cores with explicit module type and exact request ownership. Idle consumes existing slot2 records and routes targets to runnable before real Scheme restoration; it does not invoke hint closures or invent a denv. No queue/service thread/public ABI/request phase added. Temporary native claim values in existing owner cells require consistent atomics and guaranteed native epilogue release; they are not allowed to persist unowned on a busy return.

Same-final-B acceptance now specifies allocation-before-claim failure, failure before dynwind installation, exception/continuation/reentry, a live Active versus deferred cleanup discriminator, all-blocked/no-device/device-return paths, close/last-release and original unchanged stress. No runtime or peer operation, native/compiler/QNT execution, checker/history change, commit or push. Recorded8/12 and null generated certificate preserved.

### 2026-10-25 794c failed stress: linked partial delta and context fallthrough

The supplied stress-794c-interrupt2-fault.json is preserved byte-for-byte. Actual image2fdf6840b1d23672ebccb764712ae3237561653ee7ffcc4b2820e2832de45b50/UUID794CB9D5-EC7B-38AC-AE2B-65304A1D272E is independently bound to four selected thread functions by object/link comparison outside recorded relocations. Compared with frozen d64, the inspected setup/main objects and header are unchanged; Scheme delta restores ordinary wind and adds retained denv/no-current hint guards, but no complete native idle/cleanup path.

A precise remaining hole is recorded: retained detects current-present/false-denv, marks fault and returns, but unlocked service checks current existence only and can continue to drain/hints. In this executable the dynwind vector read at linked unslid0x1002c35b0 would address0x9 for denv=-4. This is a conditional linked-code signature, not the missing crash PC. The actual interrupt2 SIGSEGV cause remains unassigned without fault PC/context. Next Grok change is the outer valid/no-current/invalid boundary plus already selected native idle/cleanup and short discriminatory controls, not another global wind fallback or immediate pressure rerun.

Raw POSIX wait11 decodes as SIGSEGV/core=false. Suite1791.2 is cumulative completion time, not known interrupt2 child duration. The following interrupt_stress got at most approximately1808.8s of the remaining suite, not a separate3600s run; its end-buffered output cannot prove it stalled at start. Wrapper exit0 is driver-only; the suite remains failed/timeout. No new load, runtime/checker/history/peer modification, native/compiler/QNT execution, commit or push; recorded8/12 unchanged.

### 2026-10-25 c0d2 failed cleanup after full iteration progress

Verified c0d2b2aa6602c9f9eec068c0802e5c4b8569d2a42b007f0ac03ee77f30996b64 / UUID4DC1A24C-6494-324E-A520-76F51E3889AA and archived matching setup/thread objects. Selected8 native and4 thread function bodies match outside relocation fields. Supplied stress naturally ended3338.2s, loader1, both children70; no timeout/SIGSEGV recorded. interrupt_stress reached6000000, then cleanup refused; inactive/abandoned counters are expected caught exceptions, not leak counts. interrupt2 inner exception remains absent. Optional vector-inc wrapper exists in this generated C.

Native idle can settle terminal R and release its pin without removing VM retained root; deferred Scheme pass blocks native service, and first8-only snapshots lack suffix fairness. These are concrete conditional progress defects, not proof of the actual refusal stage. Generic cleanup text covers begin/step/finish. Canonical retained-integration-353.md now specifies protected refusal attribution, shared native exact-unlink/deferred-pass completion, bounded fair service and same-final-B short positive/negative controls before original pressure. Preserve all refusal guards; do not clear roots/counters to force exit. Actual kernel exit/root certificate still needs binding. No runtime/checker/history/peer changes, new native/compiler/QNT run, commit or push; recorded8/12 unchanged.

### 2026-10-25 c0d2 exact last-consumer implementation order

Canonical retained-integration-353.md now specifies shared native exact unlink, an independent invocation pin through VM unlock/final debit, and one closed/deferred pass epilogue shared by Scheme and no-current native service. Deferred alone is not quiescence: close entry2, release/acquire publish the final carrier access, serialize the exact context and debit once; no post-release carrier writes. Existing unused traced VM4/5 are proposed for cursor/predecessor so eight productive picks continue across slices; all insertion/removal and destruction-root guards must maintain them. This adds iterator metadata, not a new queue or request phase. Current layout observation is preserved separately and not claimed as c0d2 compilation provenance.

Six same-final-B positive/negative controls cover actual helper unlink, notification debt, deferred/active pass races, ready ninth behind eight busy entries including GC/list mutation, last release/close, and distinct begin/step/finish diagnostics. The historical4dc1 branch and interrupt2 inner exception remain unrecorded; no generic cleanup string is assigned a cause. Only evidence updated: no runtime, qualifier/history, peer operation, compiler/native/QNT/load, commit or push; recorded8/12 unchanged.

### 2026-10-25 final delivery integration: generated C and teardown cuts

Nine old generated helper/caller bodies are now bound to frozen c0d2 objects/executable outside relocations. Canonical retained-integration-353.md maps actual C sites and return descriptors to the proposed shared helpers. Reflection fixes: migrate the Scheme saved-successor traversal together with idle; a rooted removed successor is not canonical membership. Replace the old post-debit token-write landing, use consistent release/acquire handoff accessors, maintain traced VM4/5 through every mutation, and keep the existing parent/run lifetime through the generated return after last delivery debit. No future helper or full GC certificate is claimed present.

Eight deterministic cuts G1..G8 specify actual helper boundaries, no GC/barrier inside locked native leaves, concurrent insertion/deletion/relocation and last-release checks, plus begin/step/finish failure attribution. Fixed closeout: one integrated final B, its static/generated/link certificate, short positive/negative controls, first interrupt2 inner cause, unchanged original workload and real teardown; lifecycle-contract review remains separate from delivery correctness. No runtime/checker/history/peer action, compiler/native/QNT/load, commit or push; recorded8/12 unchanged.

### 2026-10-25 delivery scope seal: publication payload and actual reader release

Canonical retained-integration-353.md fixes the cross-T/VM field manifest, deferred release/acquire and G1..G8 actual-helper identity. Seven frozen c0d2 owner/run bodies additionally match object/link instructions outside relocations. Native waiter commit currently writes terminal phase before pending-D destination: final-B terminal release must move after every result/runnable/notification payload write, not simply replace the early store. Existing native_lookup_unpin skips reader decrement on journal trylock failure; run begin refusal reads owner after unpin; native leave/finalize statuses are not a complete successful-release proof. These conditional source defects are not assigned as the historical4dc1 cause.

The same existing owner ABI must use exact atomic reader release, result copies before unpin and checked owned-drop/finalize with no last-release raw access. G7 now covers live generated return, real unpin contention and extra-reader refusal; all G cuts must name actual ordinary caller/helper code in one B, with data-selected negatives rather than copied fixtures/relinked binaries. Integration scope is fixed; no new phases/queue/ABI/model. Only evidence changed; no native/compiler/QNT/load, peer/runtime/checker/history modification, commit or push; recorded8/12 unchanged.

### 2026-10-25 b5a6 execution queue versus notification debt

Frozen b5a6b186b3104d521879632b3953438820c850883814f398134aa411f1b47c9f / UUID120CF807-25B6-33AD-BEA2-4375F0C0E3F5;7 thread and3 native bodies match object/executable outside relocations. The reported PID81043 CPU/sample data is user-supplied, not a new sample or measured queue-length trace. Actual claim/find/unlink walk from target head, and drain delays execution unlink until R settlement. A growing terminal prefix therefore introduces quadratic completed-history visits; this is not an ETA or native complexity benchmark.

Controlling Grok decision in retained-integration-353.md: result/abandon commit detaches execution membership under existing target T in O(1), independently of pending-D. Add one traced private result request predecessor slot, migrate all enqueue/remove/termination paths and generated C together, eliminate the second selection walk, keep Active reachable for termination, and keep debt on existing Retained roots until actual notification/reclamation. Existing VM cursor/deferred/owner work remains necessary but was insufficient alone. Short same-B operation-count, pending-D, nested/migration/termination/GC/legacy-node and actual-teardown positive/negative controls precede original load. No runtime/peer/process/checker/history modification, native/compiler/QNT/stress run, commit or push; original two-file workload not started here, recorded8/12 unchanged.

### 2026-10-25 b5a6 two-membership data-structure closure

The canonical Grok plan now supersedes the one-field sketch with two private traced result-request predecessor fields7/8, making result vectors9 fields and keeping R unit5 unchanged. b5a6 execution commit already holds target T; detach execution at actual result commit independent of pending-D. Its Retained unlink/reject still has delivery_find_retained fallback, so arbitrary Retained removal must migrate to independent8 adjacency too; VM cursor remains fairness selection only. Legacy procedure vectors keep their short shape. All enqueue/head/termination/GC/generated call paths migrate together.

Nine generated replacement bodies/descriptors are extracted from frozen b5a6. Same-final-B work-count controls separate both list searches, constant neighbor operations, live-depth costs, notification retries and debug witness cost; require zero normal retained-find visits and zero second selection scan, plus actual roots/debits/natural teardown. No native control run or complexity timing claimed. One complete integration/native validation remains, not merely a final rerun; no unsupported percent/ETA. Only evidence updated: no runtime/checker/history/peer action, native/compiler/QNT/stress, commit or push; recorded8/12 unchanged.

### 2026-10-25 fixed nine-field implementation card and termination suffix

Canonical retained-integration-353.md now has exact b5a6 source/generated anchors, fixed9-field two-chain mutation rules and E/R commit order. Reflection closes a concrete termination interaction: existing termination reverses detached nodes through request0; an already-detached native terminated-case completion must not clear0 and truncate that private suffix. Save/root suffix before helper calls; Retained roots independently cover remaining accepted requests. Original outcome/grant must remain traced across result trylock retry; do not retry normal completion without its payload or reexecute thunk.

Final-root cleanup must move attempt/token writes before release or keep independent outer invocation protection until all accesses finish; queue emptiness is not native-tail safety. Same-final-B card specifies constant neighbor-operation/zero fallback-search counters on1000/2000/4000 controls, nested/migration/termination/GC negatives and real teardown. No added protocol fields beyond fixed request7/8, no runtime/checker/history/peer action, native/compiler/QNT/stress run, commit or push; recorded8/12 unchanged.

### 2026-10-25 a062 reported linear controls and residual termination pin

Actual image a06291330b9c8dbd81aac172cd54d25771e44b968c1d30cf104c08de5bfe116c / UUIDBDBE43BD-BCF5-3C44-B071-B0A8C193EBB2 independently copied;6 generated and3 native function bodies match object/link outside relocations. User reports cut5 p1 result41 controls1000/2000/4000 with claim2000/4001/8002, no execution terminals or second/retained searches, and ordinary release of7000 debt entries with search0/root0/exit0. Same-image cut7 restores growing execution-history visits; cut6 produces221759 retained searches for1000 detaches. These are material reported native algorithm controls, not reruns by this audit; raw fixture/receipt paths were not supplied.

Separate explicit termination exits70/admission2. That word encodes one responsibility, not its class. Actual termination thunk does not normally return; existing end path can fail to claim its Active R, then generic BTQ abandon changes mutex owner, and later typed release returns MOVED without necessarily terminalizing R. This is a source-bound candidate, not actual surviving-unit attribution. Canonical plan fixes the next discriminator: exact R/S/pass/invocation identity, phase/claim/mutex and cleanup predicate. Keep one request-aware abandon transaction and safe nonreturning handoff, no generic result-mutex completion behind its journal. Next same-final-B controls cover termination/nested/migration/GC before unchanged original load. No runtime/checker/history/peer/process or native/compiler/QNT/stress execution, commit or push; original load unstarted, recorded8/12 unchanged.

### 2026-10-25 a062 nonreturning termination claim and generic-BTQ ordering

Four additional frozen generated functions match a062 object/link outside relocations: end-locked, generic BTQ abandon and target/sender finish. Canonical card fixes the narrow implementation order: at real nonreturning target landing surrender exact existing Active attempt (not a fresh false-CAS attempt); keep retained root; perform accepted result-mutex terminal-abandon transaction before generic BTQ sweep. Pending-D may remain after terminal commit. If nonterminal transaction cannot commit, retain/retry outside locks or fail truthfully, never generic-abandon that mutex behind its request journal. Nonterminal MOVED is not settlement; do not decrement R from owner mismatch. Current self branch compares target to processor, so successor self path needs actual-current-thread identity verification.

Single-request R/S/pass/invocation state discriminator comes first: admission2 alone does not identify the unit. Same-final-B short positives/negatives include exact claim handoff, contended generic-order cut, terminal/nonterminal MOVED, nested/repeated/self/unstarted termination, migration and GC roots. Private slot0 termination suffix and last-debit native tail remain protected. No new layout/phase/queue/ABI; no runtime/checker/history/peer/process operation, native/compiler/QNT/stress, commit or push. Recorded8/12 unchanged.

### 2026-10-25 cafbee reported termination closure and two final short injections

User supplied exact a062 residue: target R phase2/armed1/member1, original attempt, exec7=false/retained8=head, mutex no longer target-owned, S settled, enter8198/leave8197. This identifies the prior one-unit residue in reported native state. Independently copied cafbee168e98b073d10c1b561a066e9a586d516eb2b0af66dc6c209c1ddc9c17 / UUID0E6AA07E-BB1B-3ADF-B3A2-1BCD3219FB98;5 generated and2 native functions match object/link outside relocations. User reports original-attempt-first termination root0/exit0, cut9 generic-first phase2/R1/admission2/exit70, preserved linear counts and7000 debt drain, nested/GC/p4-yield/unstarted/self controls. Raw control paths were not supplied; records retain user-report provenance.

Canonical checklist narrows to C1 actual mutex/T trylock RETRY1 through generated9/3/0x7f safe-point map with original outcome/grant, and C2 legitimate pre-claim race leading typed MOVED2 then actual terminal3/4 reread and notification-only tail. No direct phase fabrication, forced stolen claim, VM-only contention mislabelled RETRY or copied helper qualifies. C1/C2 remain NOT_RUN and original two-file load remains unstarted. No runtime/checker/history/peer/process operation or gsi/compiler/QNT/stress, commit or push by this research; recorded8/12 unchanged.

### 2026-10-25 cafbee legal C1/C2 timing and reachability correction

Canonical timing card pins C1 to genuine native result-mutex ticket contention, not logical mutex ownership or VM-only unlink failure. Real status1 enters actual generated L1 frame9/link3/map0x7f and restores mode/outcome/grant; holder releases before explicit safe-point GC. C2 targets the unlocked native pre-claim interval between outer invocation and R4 acquisition: only an existing authorized completion may commit, then actual typed MOVED2 plus post-call terminal reread covers notification-only cleanup. No blocking/GC inside an unsaved native leaf.

Correction to prior sketch: phase3 normal completion does not grant a second executor authority. Actual terminal3 fast-entry is separate coverage, not proof of a normal3/MOVED race. Prioritize legal phase4 termination/native-consumer race; a phase3 race needs a demonstrated ordinary caller/claim schedule or a precise reachability disposition, never forced phase/claim writes or silent waiver. Both C1/C2 still open, original load unstarted; no runtime/checker/history/peer/process or native/compiler/QNT/load, commit or push; recorded8/12 unchanged.

### 2026-10-25 C1/C2 consolidated commit authority and reachability

Frozen cafbee admits a constructive phase4/MOVED source schedule: termination direct caller paused preclaim has no VM consumer; actual idle processor claims VM3, sees ended/detached target and may use its exact old attempt without deferred requirement, commits4, then original caller sees owner moved and post-call4. VM consumer excludes another list consumer, not this direct caller. This is source reachability, not a new native run. Reflection also finds native cleanup guard allows observed true or lost-CAS/stale-attempt callers to reach typed commit. Final existing helper must require actual claim ownership and refresh phase after acquisition; a strict successor may route drift to early terminal tail rather than force old MOVED coverage. No new writer/phase/field/API.

One minimal test package specifies actual result-ticket holder and real failure event for C1; safe native preclaim/actual-idle actor for C2; completion-wins, claim-wins/lost-CAS and cut9 nonterminal negatives. Bounded native rendezvous has no Scheme/GC dependency; existing consumer/SYNC refusal is NOT_OBSERVED, never cleared to force coverage. Same-final-B static/root/helper/linear/termination evidence precedes unchanged original load. No runtime/checker/history/peer/process operation or native/compiler/QNT/load, commit or push; C1/C2 NOT_RUN, original load unstarted, recorded8/12 unchanged.

### 2026-10-25 445e strict claim / real C1 evidence and finite delivery closeout

Frozen 445e879510a631c0e106fcb40ab19a3b39c79722baadd0fe22f22c6abf210cf7 / D489186A-7D82-321B-BC50-DB0BFEFED86F source/generated C/object/archive/executable audit9ef2b27be94140369c60c6ff283bdea3. Five generated helpers and two native helpers match linked bytes outside relocations (9842f1156fca4ce19c4f00a3a9972ccf / 85e2016326be4116bae8f3e1bcdf00a4). User reports real ticket-contention C1 success/termination and CAS refusal with one actual commit/debit, retained cut9 failure and linear dual-chain controls. This audit executes none of those native cases.

Strict exact-claim winner plus post-CAS phase refresh is implemented; losing cached attempt cannot call typed commit. C2 observed A-wins only. Old typed-MOVED race need not remain reachable: legal completion drift is checked through refusal, already-reclaimed or early terminal tail. Current preclaim hook silently continues after bounded spin exhaustion, so B-completes-first needs actual outcome events, not larger timeout/new writer. Drop-outcome selector is genuinely present in generated L7 (mode1/false/false); reported41 has no discriminating branch-hit/next-entry evidence. Post-release GC selector exists but was not enabled; holder must have actually unlocked before the real GC safe point. Three finite controls, generated retry roots, exact events and same-final-B closeout are consolidated in retained-integration-353.md, section445e closeout. No protocol expansion. No runtime/checker/history/peer change, native/compiler/QNT/stress execution, commit or push. Original load remains unstarted; recorded8/12 and independent lifecycle/TFIB gates unchanged.

### 2026-10-25 445e same-final-B three-control execution card

Added delivery-445e-final-b-acceptance.md/json under existing SMP research evidence. Frozen445e source/archive/generated C and selected linked helper receipts were rechecked read-only. The card binds R+/effective selector10 retry negative, selector12 actual post-release GC and selector13 real consumer-completes-first/opposite-order controls, exact event edges, verdicts and receipt fields, all on one final B. Existing holder status1 versus2/3, incomplete reset observations and typed-entry-versus-commit counts are explicit. c2_release occurs before cleanup notification/unlink/pin tail: it cannot certify B cleanup return. Fully settled B requires no A debit; deferred pending-D permits one final debit by its actual later claimant. A silent spin expiry, gc_done before GC or configured selector without branch-hit is not coverage. No new protocol/model/runtime/qualifier/history modification, native test/compiler/original workload, peer operation, commit or push. No control is newly claimed executed; recorded8/12 unchanged.

### 2026-10-25 445e three missing observations mapped to actual call boundaries

Refined existing delivery-445e-final-b-acceptance.md/json, section6, with exact Scheme/native/generated-C placement for NEG_HIT, GC_RETURN and B_CLEANUP_RETURN. NEG_HIT belongs only to selector10's selected mutation, and must match the next helper's actual arguments. GC_RETURN is the normal continuation after the selected real ##gc, not gc_done or generic L4 return. B_CLEANUP_RETURN belongs inside native idle after subject cleanup returns, before VM relock/cursor; generated idle has no inner return label, and typed c2_release precedes cleanup's pin tail. Events use bounded scalar association, no persisted moving address or extra payload root; post-cleanup records use only pre-copied identity/status, no dereference after final pin release. Separate completion versus typed unlock, explicit misses, same-final-B build/readback order and synthetic pass/fail examples are documented. No hooks implemented; no runtime/qualifier/history/peer changes, native/compiler/QNT/original workload, commit or push. Recorded8/12 unchanged.

### 2026-10-25 445e observation aliases, concrete scalar identity and publication

Frozen-source audit found actual observer roots: ##thread-intr! writes ##delivery-case-mutex/request at _thread.scm2436-2437, generated GLO43/44 at29590-29591; no later clearing assignment exists in frozen Scheme. These can mask request/unit/capability GC-root defects; G+ must clear observation-only aliases at its safe pre-GC Scheme boundary without saved copies, and audit holder/closure aliases. The sweep-during-retry counter also uses delivery-case-request; a zero count after clearing cannot certify absence unless the dedicated fixture rebinds that test observation.

Existing acceptance card section7 fixes request/unit field relations; proposes immediate subject tag in existing unused target thread-specific field30 for one-request dedicated controls only (generated accessor/setter checked); no request/layout/production identity field. Migration correlation is scalar continuation identity, never P/TLS. B binds under existing protected pick/T checks and logs only copied scalars after cleanup. Fixed actor-owned slots have EMPTY/WRITING/READY and release/acquire publication, explicit duplicate/overflow handling, no native Scheme pointer retention or observer payload roots. Final-B regenerated semantic slot maps/reloads, actual alias absence and scalar-only post-release object code are required. No hook implemented, native/compiler/QNT/original workload, runtime/qualifier/history/peer change, commit or push. Qualification recorded8/12 unchanged.

### 2026-10-25 Unified 445e observation closeout: aliases, identity and sweep

Replaced the fragmented handoff entry point with one controlling implementation cover at the top of delivery-445e-final-b-acceptance.md/json. Three proposed changes share one final-B build/readback/acceptance matrix: unique immediate target tag tied to one actual constructor; GLO43/44 cleared without saved copies at the real no-lock pre-GC Scheme boundary; actual sweep predicate rebound from GLO44 to tagged subject's real retry/terminal observation window. Existing generic sweep/claim/result/lifetime semantics stay unchanged. Generated crosswalk explicitly includes clear stores, semantic root slots/reloads, structure30 sweep load and scalar-only native cleanup return.

Metrics cannot hide failed observation: zero needs actual tagged SWEEP_ENTRY/window evidence. Existing cut9 may precede any ticket refusal; its retained-failure negative does not by itself prove early-sweep-counter hit. Minimum controls cover aliases intentionally retained, wrong tag, duplicate constructor, actual migration, post-commit sweep zero and actual window classification, all on one final B under unchanged short limits. No hooks applied, native/compiler/QNT/original workload, runtime/qualifier/history/peer operation, commit or push. Recorded8/12 unchanged.

### 2026-10-25 Complete 445e function-level handoff and same-B return-path audit

Updated the existing acceptance card cover in place, rather than adding another protocol/work package. F0-F7 specify fixture setup, actual constructor, retry wrapper/alias clearing, holder release, typed refusal/terminal observations, native idle cleanup return, existing sweep closure and fixed scalar records. The source-checked return audit preserves admission failures, retain3, unaccepted/async paths, SYNC/GC escapes, holder exhaustion, nonterminal MOVED/retained, terminal/idempotent, generic-first and retained-publication fatal behavior. Observer cleanup never releases algorithm pins/links, restores old GLO roots or converts failure to completion. One final-B generated slot/reload/alias/sweep/post-release crosswalk precedes the fixed R/G/identity/sweep/C2/regression/quiescent teardown sequence. No runtime/checker/history/peer changes, build/native/QNT/original workload, commit or push. Recorded8/12 unchanged.

### 2026-10-25 F0-F7 adversarial review and integrated corrections

Reviewed full frozen445e call chain against the existing handoff. Found a source-grounded observation-order defect in that proposal: delivery_publish_terminal publishes phase while target T is held, but proposed marker near1268 was after thread unlock1266; a valid sweep could read stale RETRY_OPEN. Correct placement is actual helper phase publication before T unlock, covering both existing terminal call sites. Additional counterexamples cover foreign constructor GLO rewriting, holder-frame/closure survival after unlock, tag ABA, good READY hiding duplicate/late invalidation, unwind/reentry correlation, prevalidation/postleave dereference and outer idle writer still live.

Revised existing single acceptance cover in place with X1-X8 exact corrections and one amended same-final-B sequence. These are observation/fixture changes and reject predicates, not a new runtime ownership protocol or native results. Bound writer assumptions and unsupported C/host mutations are explicit; generic zero-root/41/READY success does not close them. No hooks implemented, native/compiler/QNT/original load, runtime/qualifier/history/peer operation, commit or push. Recorded8/12 unchanged.

### 2026-10-25 X1-X8 consolidated implementation and acceptance packet

Existing acceptance cover sections4a/4b now provide one Grok change set and fixed final-B sequence. Holder root retirement is pinned to an actual native return, capture-cell clear and compiler-audited scalar-only tail landing, not unlock/status publication; final frame/register/closure audit is mandatory. Frozen generated hold-ticket wrapper28604-28631 has R1 argument→native call→scalar R1→JUMPRET; no caller-root certificate is inferred. Actual terminal phase and observation-close remain under the acquired target T inside delivery_publish_terminal, covering both existing callers. All symbolic alias writes are inventoried and accounted, not only tagged constructors. Tag ABA, hidden duplicate/late errors, after/unwind masquerading as GC return, invalid/postleave dereference and final outer-writer lifetime are handled in the same packet. Final acceptance waits for real runtime cleanup/process quiescence and preserved child status, not provisional inner PASS. No code implementation/build/native/QNT/original workload, qualifier/history/peer change, commit or push; recorded8/12 unchanged.

### 2026-10-25 bbf17dd9 rerun source-bound triage and bounded repair package

Preserved user pasted report and actual named fixtures; independently froze bbf17dd9 executable/source/generated C/object/archive, UUID2B5192A0-7BA7-32D5-A0D3-DD99F5DE83D8. Seven selected helpers match linked objects outside relocations. R+ ordinary/effective R− and the closed-window sweep have real reported controls. G+ twice missed actual contention/selected GC (retry0/hold exhaustion/holder3), while keep-cell negative formed GC; use that matched fixture as the no-extra-cell counterpart before changing runtime architecture. Current exec_* counters are plain C arrays with live reset/read and include native/Scheme/termination detach; aggregate excess18 needs scoped synchronized conservation, not relaxed equality or an assumed duplicate. Root2 maps VM3 consumer, and c1-term lacks post-stop join/teardown; final pass-owner status remains open. Source also corrects prior public API oracle: remote thread-terminate catches inner inactive/abandoned exceptions then returns void, unlike direct thread-interrupt sender. C2-A after-settlement idle-probe is idempotence, not live claim refusal.

Updated the sole acceptance cover to one source-grounded package: matched G pair/cooperative safe pre-ticket fixture order, synchronized target-scoped counters/no live reset, actual holder/pass/quiescence completion, real C2 opposite-order collision, and same-B original-load readiness only after focused invariants hold. No native/compiler/QNT/original workload, runtime/qualifier/history/peer operation, commit or push in this audit. Qualification8/12 unchanged.

### 2026-10-25 bbf17dd9 improved-source audit and integrated four-part function packet

Audited additional actual consumer/pass/counter and generated holder/service code against frozen bbf17dd9 objects/executable, adding ten selected comparisons to the earlier seven; all match outside relocations. Scope remains selected-source/linked-path audit, not a full runtime or GC-map certificate. Found published-pass release responsibility mismatch: native pass finish defers and preserves its pin on VM-lock refusal, while Scheme retained-service after may independently release armed pass. Native idle also returns COMMITTED for attempted handoff without helper-status propagation. Source facts do not prove either caused the user's root2 snapshot.

Updated the sole card sections3/4 in place: matched known-forming extra-cell/no-extra-cell GC fixture; target-scoped atomic monotonic counter implementation and actual detach-source classification; published/native versus never-published/local pass release with real VM contention/idempotence tests and actual idle finish status; real C2-A post-CAS contest, no current-thread spoof. Seven-step same-final-B source/map/object/fixture acceptance order includes API-correct sender behavior, safe join/teardown and no post-free VM read. No code edits/build/native/QNT/original workload, qualifier/history/peer operation, commit or push. Count8/12 unchanged.

### 2026-10-25 Confirmed1ac56ba0 progress and cleanup admission crossing

User explicitly bound latest entire table to1ac56ba07866ad3aa33dcb97cdd622a1c4ca18266b4fe78bf6e7fed8d2f46b67. Frozen artifact UUID27D1C1B5-3501-334C-81C6-26B05138A620 with stable source/generated C/objects/archive; eight native pin/pass/idle/root/counter comparisons pass outside relocations. Preserved actual first R- raw log /tmp/card-1ac56/rminus.log (not labelled a repository receipt). Delivery negative forms, but step DELIVERY_PINS/admission2/exit70 is accidental cleanup failure; later passing rerun does not close it. Admission increments2 per responsibility:2 means one, not two. Logger admission/predicate and later enter16/leave16 are separate times; slot samples-1 are unknown.

Current source supports a concrete crossing trace: destroy begin wins phase9 at zero while delivery remains open for shrink; live processor native idle registers before checking Retained work and does not check teardown owner phase; step rejects live invocation; leave can occur before counter print. Historical actor not identified. Updated sole cover with source/diagnostic distinction and bounded same-ticket optional-admission/drain/shrink controls, preserving real faults. Reported targetN=1000/2000/4000, formed G+/extra-root negatives and both C2 orders are retained as progress. Missing combined termination retry and heap/movement certificate remain. No runtime/qualifier/history/peer edits, native/compiler/QNT/original workload, commit or push. Count8/12 unchanged.

### 2026-10-25 Atomic admission cutoff and ticket-owned shrink plan after5c78 review

Read and froze actual5c78d0dc source/objects/executable, UUID13300D9E-8D3D-398A-8EB9-F81C397B9042; ten selected native object/link comparisons pass outside relocations. Source confirms after-enter empty rollback plus zero-poll/second-step still permits a new registered invocation between sample and step. Scheme crossing begin was correctly refused with live P0 run, hence not native crossing coverage. Existing test phase rewind must not be transplanted after real partial cleanup. Existing OP_VM_RESIZE closes only0->1 and reopens; early seal requires same-ticket/generation-owned closed recognition, not a boolean bypass.

Replaced current handoff cover in place with one function-level plan: atomically OR existing admission closed bit while preserving count, close ordinary fresh entries, retain authorized accepted-prefix completion, same LIVE_TICKET monotonic drain/shrink/resource stages and exclusive step/finish, destroy-owned shrink retains closed admission while ordinary resize preserves its own reopen semantics. Native real-cleanup hooks after run finalizer test both CAS orders and exact completion; stale/cross-VM/retained/partial-cleanup negatives remain. No new owner kind/public handle layout or arbitrary allow-when-closed flag. No implementation, native/compiler/QNT/original workload, qualifier/history/peer operation, commit or push. Count8/12 unchanged.

### 2026-10-25 Two bounded closeout units; lifecycle counter scope checked

Refined same acceptance card, without another work package: actual native destroy cutoff/prefix drain/same ticket and actual native first-try C1 holder ordering. The latter requires prepared checked B, no Scheme/GC dependency while A pauses, real same-mutex held and subject-specific failed trylock before release, then existing generated retry. Native timeout cannot silently become formed R+; unexpected SYNC/context is explicit missed coverage. Source-reachable idle race remains historically unconfirmed. Read-only tests/run_current_checkpoint_qualification.py619 shows9/12 lifecycle-only and others_open intentionally retains GC/FFI/Gerbil/release gates. No checker evaluation/edit, runtime/peer change, native/build/QNT/original workload, commit or push. Recorded8/12 unchanged.

### 2026-10-25 One integrated seal/holder implementation order

Updated the existing delivery-445e-final-b-acceptance.md cover in place with A1–A5/H1–H3: checked count-preserving seal, exact accepted-debt/pass completion, serialized same-ticket progress, close-origin-aware shrink and final cleanup; prepared rooted holder, actual same-subject first-try failure, real release/root retirement and generated retry. All are a single next-B integration rather than independent fixes. The native crossing uses actual cleanup after ordinary run finalization and real begin/ticket in enter-before-seal, seal-before-enter and stale-CAS orders. Required private seal ownership fields are explicitly proposed, not claimed present in5c78. Published/deferred pass fallback release and partial-cleanup false success must be fixed together. No runtime, observer/history, peer, native/QNT/build/load, commit or push operations; recorded8/12 unchanged.

### 2026-10-25 Supervised existing Grok debug dispatch: no LLDB execution yet

The user explicitly authorized Codex to supervise the existing tfib-repair Grok session and required Grok, rather than Codex, to execute LLDB and report raw observations. Resumed original session01a1617d-e9d9-7f33-81f3-125d5470b703 through normal task custody, grok-4.7/high. Attempts0043 (18 turns) and0044 (10 turns) ended at max_turn_requests without native debug completion;0044 invoked dispatcher debug --help, which is not LLDB execution. docs/work-items.json adds only this task's existing debug dispatcher capability under that explicit authorization; no unrestricted shell or runtime edit. The tightened next request forbids further discovery loops and requires either one genuinely bound debug control or an exact prerequisite report. Its launch was rejected by the normal dependency guard: task dependencies are occupied; transition deferred. No lock bypass, peer stop, Codex binary inspection/disassembly, runtime/observer/history change, original workload, commit or push.8/12 unchanged; no native conclusion is claimed. Public supervision record is stored under the corresponding audit output.

### 2026-10-25 Actual b962 terminal resume and c804 review hold

Resumed the explicitly selected Grok session in the exact SMP checkout through a controlling terminal after headless session_create stalls. Grok reproduced f249 bare-e exit70 and produced c804 bare-e/file exit0 text logs; source-only independent review withholds acceptance of scheduler_status0 blanket run-error suppression. Exact classification and existing READY frontier/genuine-error negative are required, not more error masking. The single delivery acceptance card now contains this checkpoint and references the copied raw logs. Original load, qualifier and historical receipts were not changed;8/12 remains recorded. Supervisor client ended with an exit-handling error; no continuing supervision or descendant closure is claimed from that.

### 2026-10-25 Supervised 9299938e call-local run outcome: source/text review

Grok implemented actual caller-stack outcomes, replacing the global processor-id refusal array and ambiguous CLOSED inference. Source review confirms exact ALLOC/JOURNAL/charge failure sites, four-field native-key comparison in the closed branch before lookup unpin, caller-owned setjmp-safe records and preservation of the native worker reservation until join/reclaim. Nine exit records at the executable path bound by the reported checkpoint show six exit0 controls and three propagated controlled error71 cases. Per-case records contain no independent image hash. The real rejected READY-growth wait and older f249/c804/00c370 failures remain distinct. SINGLE_VM scope, unobserved overflow/cross-VM, no object/GC-frame/full-inventory proof and formal8/12 boundary remain explicit. The sole acceptance card was updated in place; an observed source delta and copied raw records were retained, not a new runtime patch application by Codex. No original stress, observer/history edit, commit or push.

### 2026-10-25 9299938e targeted controls and implementation continuation

The same resumed Grok session ran local controls with before/after image hashes. Selected heap GC returned epoch5->6 with empty transfer/holder cells and quiet roots0; relocation was not observed. C2-B formed; target execution detach was1000/2000/4000 and7000 retained debts drained with find0/second0. Per-batch claim visits were not printed. cut6/cut7 reproduce historical quadratic scans and cut9 retains phase2/Rarmed1/roots5 and exits70 (sealed admission3 is bit1 plus one charge2). Ordinary resize and enter-before-seal charge crossing also formed.

This is not complete integration: C2-A exhausted before B attempted, holder termination timed out at45 seconds, and no real deferred-pass/destroy-ticket crossing occurred. Seal-first/stale cases lacked arming; migration had no processor-change witness. Extra legitimate keep-cell/alias roots are certificate negatives, not reasons to require a runtime error; exit0 does not accept a sole-root claim. An initial GC environment error was followed by a corrected explicit-env run; Grok reused its raw path, so the audit preserves the corrected run and describes the original without reconstructing a receipt.

Codex required actual repair and final-B regression rather than another missing-items-only report. Normal admission then deferred on a live workspace dependency from modern-c-frame-contract; the Python supervisor waits for natural release without signals or lock override, then will resume the same session. No qualifier/history/milestone edit, original workload, commit or push. Evidence review receipt: .cache/tasks/repair-9-12/processes/audit/runs/905ffed291a7468b80c84e11d0b8855a/outputs/b962-controls-first-review/receipt.json. Recorded8/12 remains unchanged.

### 2026-10-25 Unified pass/cleanup contract; native trial rounds stopped

User steering ended additional native trials. Grok's owned frontend returned0 after a no-descendant observation; no peer was signaled. Latest tested diagnostic B is82899fd8/UUID E3D95532-14E0-3916-83BB-4F859BD447BA, with the actual atomic C epilogue leaf and25 same-B local controls. Source snapshots of setup.c/_thread.scm/_thread.c remained unchanged during the stopped busy-drain unit. The remaining VM-busy, private-claim and post-GC-service obligations are explicit rather than patched by another unbounded loop.

The single integration model delivery_pass_cleanup_composition.qnt passed typecheck,12 discriminating invariant controls and fixed safety/liveness (1238 generated/411 distinct/0 queued,34.276s campaign, original90s per-check cap). Removing the GC service window yields a real temporal lasso (378 distinct, back to16); original DENY and the local text-parser mismatch are retained, with no TLC rerun. The root contract documents finite-holder/fairness/GC-domain premises and one frozen implementation/acceptance batch, not a guarantee about arbitrary callbacks or real-time completion. See evidence/research/smp-retirement-study/delivery-root-stability-contract.md and .json. Runtime/qualifier/history/milestones unchanged by Codex; recorded8/12; no native model-phase execution, commit or push.

### Integrated cleanup source gate: private context implemented, 3a3370e4 denied

2026-10-25. The same Grok session removed the global setup-context authority and compiled the explicit private-context implementation. Codex rejected the frozen source before any native execution: root dereference before borrower acquisition, nonatomic/premature claim release, completion service after the outer sync return rather than each stable post-GC boundary, and a diagnostic VM-lock return plus unreviewed lock-held paths. The single integration card and `delivery-root-stability-contract.md` contain the exact functions and required source boundaries. This is a source-gate rejection, not a native failure or admission; the29-case prepared batch did not run. No original workload/full inventory, qualifier/history change, commit or push. Recorded8/12 remains. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/fd86b99faf2b40ac889258f4794a58a8/outputs/b962-integrated-source-denial/receipt.json`.

### P0 native drain profile, preserved GC-starvation negative

2026-10-25. The same unified model now checks the exact proposed no-GC native cleanup slice before P0 joins the next collective. Conditional safety/liveness passes227 distinct states; the original GC-priority path remains a378-state temporal DENY. Real pending flags and later GC are native obligations. No60db native case ran; its new collective-debt code was rejected for local-history barrier divergence and unpaid-debt/expiry gaps. Existing root/claim improvements are preserved for the smaller source-grounded implementation. Details and exact model identity are in `delivery-root-stability-contract.md`; recorded8/12 remains. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/c4127d3c9af8450eade4f1348c53fa88/outputs/b962-native-drain-model-checked/receipt.json`.

### ceab native drain: actual25-case prefix, preserved journal-control DENY

2026-10-26. Frozen ceab/30F0A8B2 implements bounded accepted-pass native drain before P0 participates in GC; old collective bodies are unchanged. First batch ran25:24 diagnostic expectations matched (migration remains non-qualifying), then journal-unadmitted exit0 missed the post-charge fault because immediate P0 exit sealed first. Original DENY preserved; no timeout/identity drift. Root/claim code, G+ heap GC, C2, linear7000 detach/drain and termination facts are bound in the unified card. A same-B causal journal fixture plus five unexecuted controls were predeclared, without runtime changes or widened caps. Observed setup-only source delta and metadata are in `delivery-native-drain-3a337-to-ceab.patch` / `delivery-native-drain-ceab-source.json`; these are not a clean7c cumulative installation. Recorded8/12, no native admission, no commit/push. Prefix batch: `.cache/tasks/repair-9-12/runs/06937f25d5e5475aa0936cd28a743a99/outputs/b962-ceab-single-native-batch`.

### ceab final targeted evidence: actual root/claim/native-drain refactor

2026-10-26. Same frozen ceab/30F0A8B2 ran31 processes across30 case names:29 raw matcher matches,2 preserved denials,0 timeouts/crash signals/drifts. Journal negative now genuinely reaches site3 before cleanup. The pass-lock held/busy/retry/commit/debit path formed; its matcher DENY is a cross-thread fprintf order assumption, explained separately without rewriting it or rerunning. Final claim-BUSY/drop/debit/extra-record-borrower refusal controls all matched. No own native children remain. This is targeted evidence, not an original-suite PASS or formal9/12; count remains8/12. Conclusion and exact receipts are in `delivery-native-drain-ceab-conclusion.json`; unchanged-budget original-two-file plan is prepared but awaits clarification of the prior no-original-workload constraint. No runtime edit during tests, no commit/push.

### Original two-file pressure explicitly authorized and started

2026-10-26. The human explicitly lifted the no-original-workload restriction for the two unchanged interrupt stress files only. Same frozen ceab/30F0A8B2 runs the original loader with p11/GAMBOPT=p11 and one absolute3600-second wall deadline. The driver uses communicate_boundary, not the renewable progress watchdog; first native failure or deadline stops/reaps only its own group. Source/image/header/harness/file preflight hashes match. Actual start: `2026-10-25T16:28:42.305831+00:00`, native PID36486. At this observation the loader announced thread_interrupt2_stress and no child completion or pass is established. Run: `.cache/tasks/repair-9-12/runs/1025f0df699246eda3e83aff0c666196/outputs/b962-ceab-original-two-stress`. Start receipt: `.cache/tasks/repair-9-12/processes/audit/runs/b356b2c3e91e475ebde5001dd5308c64/outputs/b962-original-stress-started/receipt.json`. No qualifier, fixture, budget, runtime source, commit or push change. Recorded8/12.

### ceab original interrupt pressure failed; no original-load closure

2026-10-26. The human explicitly authorized the unchanged original two-interrupt pressure on the same ceab image, p11, one cumulative3600-second deadline. This run failed: the loader reported `thread_interrupt2_stress.scm` with `HI=70 LO=0` and an uncaught exception in `thread-join!` of thread3. No SIGSEGV was observed in this record. The loader then began `thread_interrupt_stress.scm`; that second child was cancelled with the owned group and has no result. No `PASSED ALL 2 UNIT TESTS` was observed. This contradicts any assertion that the targeted cleanup controls already establish original-load stability.

The last native progress sample is3322.382 seconds. The preserved loader excerpt starts the second file at cumulative3324.4 seconds. Neither is a precise first-child duration or kill timestamp. The original watchdog failed in its process-snapshot path after observing the first failure and before durably writing full stdout or its completion receipt. The loader became orphaned. Grok subsequently stopped only the owned PGID36486; the original parent did not reap its loader, so its authoritative wait status is unavailable. The checkpoint reports timeout false. Codex attempted a birth-checked original-deadline takeover, but the PID had already disappeared; it sent no signal. Independent kernel census after frontend return found no members of PGID36486 or28057. The frontend returned0, which is not a workload pass. The missing raw capture is a supervision defect, separate from the actual child exit70.

The frozen image and every recorded setup/header/Scheme/generated-C/original-fixture hash still match. No source edit, recompile, budget increase, automatic original retry, qualifier/history/milestone change, commit or push occurred. Raw run: `.cache/tasks/repair-9-12/runs/1025f0df699246eda3e83aff0c666196/outputs/b962-ceab-original-two-stress`. Review: `.cache/tasks/repair-9-12/processes/audit/runs/cba0b2ce4a204f0385649d3d57a6b468/outputs/b962-original-stress-result-audit/receipt.json`.

The source chain now narrows the next question without inventing a cause: SMP `##thread-end-with-uncaught-exception!` at `_thread.scm:2689` saves the original exception as the thread result; `##thread-join!`/done at3012/3019 passes that result to `##raise-uncaught-exception` at123 as its reason. `run` and `flood` contain nested joins, so the outer printed wrapper does not identify the original exception, request, or test1–test6. The current evidence cannot distinguish abandonment, an argument/primitive error, or another exception. None may be promoted to root cause from this text.

Before another original run, the existing runner must durably stream raw output before optional census, and all census failures must still reach owned-group stop/finalization. The smallest causal diagnostic is recursive uncaught-exception reason plus test/thread/request identity at the existing error boundary, retaining the original propagation and exit. This is a failure-capture requirement, not another delivery protocol or an accepted runtime patch. No repeat of the unchanged failing route is authorized by this receipt. Count remains recorded8/12 and the formal lifecycle predicate remains independent.

### ceab diagnostic capture verified; direct vector arity cause not supported

2026-10-26. Grok's next short-control runner initially failed before spawn because its Mach-O64 UUID header used a28-byte unpack format for32 bytes. That original error checkpoint remains unchanged. Codex copied and corrected only this owner-local test helper under normal repair-9-12 custody, and actually ran ten short processes on unchanged ceab: two/three-argument vector calls, nested-error/normal/abandoned Scheme controls, and five Python capture controls. All eight predeclared diagnostic predicates passed. Nested joins preserve the innermost `INNER-CAUSE-CONTROL` and exit70; abandoned mutex is distinguishable and still exits70; normal exits0. Partial bytes survive timeout, injected read error, and injected census error; all owned groups are absent. This certifies the tested capture paths, not all possible OS failures or runtime stability.

Source inspection found vector.scm195 optional third argument versus _std.c127248 three-argument procedure entry. However, actual direct two-argument and three-argument calls on this exact image both exited0 and produced vector #(1). The source-only arity hypothesis therefore does not explain the failed original literal-call path and does not authorize a primitive patch or regeneration. This control does not prove reflective apply behavior or compile binding of every _std.o.

A single follow-up diagnostic keeps ceab, p11, original interrupt2 bytes and loop counts, with a hard3600-second deadline. Its only wrapper reports recursive exception reasons after failure and propagates the same exception. It durably streams bytes before optional census and keeps cleanup in finally. It runs only the already-failed first original file; no second file/full inventory or automatic retry. This is diagnosis with wrapper startup perturbation, not an unperturbed performance or acceptance pass. Runtime, qualifier, historical receipts and count8/12 remain unchanged; no commit or push.

Controls: `.cache/tasks/repair-9-12/runs/ff8d2e7a4fbf453593979a0b6e8fee81/outputs/b962-causal-short-controls`. Publication: `.cache/tasks/repair-9-12/processes/audit/runs/ebc63f196922439185cf26bcb76f2c59/outputs/b962-causal-short-controls-publication/receipt.json`.

### ceab original interrupt diagnostic: progress and throughput boundary

## ceab full-budget diagnostic: forward progress, inadequate throughput, no exception cause

2026-10-26. A single diagnostic of the unchanged original interrupt2 file used ceab, p11 and one3600-second deadline. The recursive reporter produced no reason line before the deadline; no exception-landing breakpoint was hit after its mid-run attachment. The run timed out after3600.027 seconds including stop/reap observation. This is a diagnosis with a1-second sample, debugger stops, read-only data access and counter snapshots; it is not unperturbed acceptance. No original loop, heap or processor reduction, runtime edit, rebuild or automatic retry occurred. The earlier genuine exit70 remains a separate unsolved failure.

Two read-only snapshots of the existing per-processor atomic counters, bound to the ceab UUID and source layout, show execution detach66410021→74533942 in348.720996 seconds:8123921 more, approximately23296.3 per second. Retained-search and second-selection totals remained0. The original six tests at p11 request6×6×10×1000000=360000000 user interruptions, before incidental runtime work. These all-process counts prove forward completion in that observed late window, not an exact test number, root cause or full-file completion. They refute a global no-progress hang during that window and show that eliminating historical Retained search did not supply the needed throughput. The1-second sample heavily contains collective/GC wait and select, with retained/commit paths still active; it cannot measure their whole-run costs.

Deadline/debug-stop overlap exposed another supervision boundary: the parent recorded returncode0 while the group observation was still present. Stream timeout and missing completion dominate that0; it is not accepted as a native exit0. The checkpoint deliberately records noLiveNativeChildren=false and remains unchanged. Subsequent independent kernel PID/birth census found no group76708 members, both debugger owners returned0, and normal workspace.resume must reconcile before reuse. No peer was signaled. The first-exception data was not captured, so no error object or guessed reason is supplied.

The next implementation review must stay on the existing chain: every request takes a VM Retained lock, repeatedly allocates pass/attempt/hint objects, and global diagnostic atomics still run when observation is unconfigured. Counters use kind-major adjacent processor cells, which may contend on cache lines. Those are concrete review candidates, not yet benchmarked causes. Any cost refactor must preserve unique commit, real abandoned semantics, roots until last consumer, release/claim ordering and original negative controls, then demonstrate same-work comparisons before another original acceptance. Do not manufacture a new queue protocol, disable correctness counters to fabricate progress, or expand budgets. Count remains8/12, no qualifier change, commit or push.

Diagnostic: `.cache/tasks/repair-9-12/runs/109056c8f6264f558a1a7014f9e7f37c/outputs/b962-original-exception-diagnostic`. Counter watch: `.cache/tasks/repair-9-12/processes/audit/runs/e3c9ee40cc6444a69d1b23e32509863e/outputs/b962-completion-counter-landing`. Reconciled audit: `.cache/tasks/repair-9-12/processes/audit/runs/2c99eae5b357409fb0df257837675dcb/outputs/b962-diagnostic-cost-result/receipt.json`.

### Native Retained369e: rejected cost/branch equivalence

## Native Retained candidate369e: measured regression and exact source rejection

2026-10-26. Grok compiled and linked a real candidate369e55ed841310f4c9cae3d4707e0ab84bf3b84f76178477439c18ed91a3ab84, UUID9DD14BEA-33DB-3A0E-B819-4F530F9757C8. It changes READY Retained service to reuse the existing native idle slice and adds live phase2-deferred handling. The same20000-call, ten-sender, default-heap mini workload remained count20000/roots0/faultfalse/exit0, but regressed: p1 .6863605→1.0407007 seconds; p11 4.1452892→6.2817711. Ready service counts grew about20000→306000–328000 and native idle service was called about308000–328000 times. No original stress was run on this candidate.

Nested/yield, real C1 retry/termination/GC, C2 A/B and expected cut9 retained70 matched; the next pass-seal row failed to form its consumer and remained DENY despite exit0. Drop/debit and requested new native deferred/SYNC/contention controls were not run. Two preceding candidate invocations used a wrong relative fixture path and exited70 without executing the workload; those raw harness errors remain separate. Baselineceab and rejected candidate source/image identities and data remain in the run. No previous PASS is assigned to369e.

The specific source mismatch is now explicit: old READY `##thread-intr-service-retained-walk!` only retries deferred/terminal cleanup. Reused `___delivery_idle_slice` additionally calls `delivery_wake_try` for phase1 requests, generating additional scheduling and wake work. Its added phase2/live-only predicate also omits deferred phase1 supported by the old walk. This is a source rejection, not proof that the sole performance bottleneck is wakeups. The causal correction is an internal cleanup-only READY mode sharing the same native core; actual idle retains recovery wake. No new queues, entry ownership or resource protocol is required. The old accepted Scheme-pass path must remain serviceable and get an actually formed diagnostic control. Native retry may leave debt only while membership/roots and a future service obligation remain. A new source/targeted/measurement gate must precede original workloads.

Run: `.cache/tasks/repair-9-12/runs/56508f6b532444e3aecfa1c8a77d7657/outputs/b962-native-retained-service-cost`. Source review: `.cache/tasks/repair-9-12/processes/audit/runs/a45ee957eab34ea8b7a34e8c7bf04423/outputs/b962-native-ready-source-review/receipt.json`. Same client returned0, no owned native children, count8/12 and qualifier unchanged; no commit/push.

### Actual READY native cleanup2fe7: formed handoff and residual GC cost

## READY cleanup2fe7: actual source split, formed controls and cost limit

2026-10-26. Candidate2fe7e4073bd6615e9d5d1d86bbf5a274e99a881b455cb0e6c49c6ba3dfa854eb, UUIDC704D6EA-3309-3F96-A5E7-042DA0146AA9, was actually built from the same7c lock tree. `delivery_service_core(..., recovery_wake)` now shares one native implementation. `___delivery_ready_service` uses0 and never calls queued recovery wake; `___delivery_idle_slice` uses1 and preserves its recovery role. READY deferred phase1/2 ownership and terminal handling use the existing exact cleanup CAS/re-read. The existing Scheme deferred-consumer epilogue remains. The bounded native body does not allocate or invoke its Scheme action arguments; generated `_thread.c` was regenerated with realgsc and recorded. This is a scoped source review, not a full C11, arbitrary external-entry, or all-root certificate.

Same20000-call mini comparisons: ceab p1 .6863605s / p11 4.1452892s; rejected369e p1 1.0407007s / p11 6.2817711s; corrected2fe7 p1 1.0003394s / p11 3.5682833s. A later369e diagnostic repetition was .6909142s /5.9492836s, demonstrating timing variability rather than a formal confidence interval.2fe7's ready service count returned to about20000 rather than300000; the idle-entry count is not directly comparable because READY has its own entry. Six targets×ten senders×2000 calls completed120000 exactly in10.0796127s with roots0/faultfalse/exit0. These are bounded small-work observations, not original-load completion or a release performance claim.

Grok's first new distinguishing rows were source-audited as vacuous/unformed: synchronous interrupt completed before READY, pending-SYNC was not observed, vm-hold was not shown to lose a real native trylock, and consumerfacts0 did not witness pass installation. Their raw records remain smoke-only. Codex then used actual async enqueue onp1, with no forged phase/owner, to observe phase1/member1 before READY, the same phase/member with execution0/wake0 afterwards, then real phase3/root0/exit0. A separate new legacy fixture used the former pass's real entry CAS0→1, actual pass admission, old retained-body and native epilogue: consumer3, publishedtrue, armed1 while active; phase2/deferredtrue afterwards; target then completed. Shutdown produced eight genuine active refusals, native PASS-FINISH0/admission1 and seal2→3/one debit/exit0. The historical pass-seal DENY was not rewritten. These controls intentionally hold diagnostic references and are not independent GC-root-elimination certificates.

Existing C1 retry/GC and real termination, C2 A/B, cut9 retained70, drop-fail70 and debit-fail70 matched on2fe7. A1-second own-process six-target profile still heavily contains GC collective condition waits and select; it is diagnostic perturbation only. Another same120000-work p11 pair read built-in statistics only before/after: ceab real5.848736s, GC-real1.335742s,128 collections;2fe7 real5.117363s, GC-real1.209927s,129 collections. Allocation slot7 is computed by `mem.c:8796 ___bytes_allocated` from the current processor's memory, not a VM total. Its48210016 versus87406160 values must not be used to claim more or less total allocation. Source `os_time.c` uses RUSAGE_SELF for process CPU, a different scope. Removing Scheme service objects did not materially reduce VM GC count in this sample. No new original stress was started.

Exact observed ceab→2fe7 source delta: `delivery-native-ready-ceab-to-2fe7.patch`. It requires the listed exact ceab source hashes and is not a cumulative clean7c patch. Generated C/image/header identities, raw runs and distinctions: `delivery-native-ready-2fe7-evidence.json`. Current producer, earlier ceab and rejected369e identities remain separate. All owned native children and supervised clients returned; no runtime edit followed the freeze. Still missing: actual idle queued recovery, live deferred-owner accept-once, pending SYNC with debt, real VM-lock loss/retry, original exit70 inner cause, and full original budget acceptance. Count remains8/12; qualifier/history unchanged, no commit/push. Publication: `.cache/tasks/repair-9-12/processes/audit/runs/0eea9445e06643698a8d01e6c45124cd/outputs/b962-ready-final-publication/receipt.json`.


## 2fe7 original-parameter test2: first exception and GC comparison limit

2026-10-26. On unchanged2fe7e4073bd6615e9d5d1d86bbf5a274e99a881b455cb0e6c49c6ba3dfa854eb (UUIDC704D6EA-3309-3F96-A5E7-042DA0146AA9), one focused diagnostic preserved the original test2 body, million iterations, ten senders, six groups, p11, default heap and1000-second target sleep. Only the final test selection and absolute include path changed. The first-uncaught hook atomically claims reporting and passes the identical original exception to the original termination continuation. This is diagnosis, not full original-file acceptance.

The native process exited70 after1000.647255 seconds, before its fixed3600-second cap; its group was absent. The actual first error was inactive-thread-exception from thread-interrupt!, targeting a normally terminated thread whose counter was3155998, below the required10000000. Abandonment and subsequent cleanup refusal were not this first error. This establishes a concrete throughput-before-target-expiry failure on2fe7, not the identity of the old ceab3324-second excerpt. Catching the exception, extending1000, shrinking work or increasing heap does not repair this failure.

Later shutdown reported admission139, enter121158352 and leave121158283. Other senders were still active when failure initiated shutdown. Those outstanding responsibilities cannot be called leaks merely from this snapshot, and cannot be dropped to force cleanup success. Their accepted owner and last consumer must be preserved.

Completed-GC aggregate statistics correctly use slot16 (all-processor accumulated allocation), rather than current-processor slot7. The six spinning-target120000-call pair observed ceab692860144 allocation bytes/119 collections versus2fe7769096416/203; live data after GC stayed approximately0.2MB. However, those targets repeatedly thread-yield! until sender completion, and the yield count was uncontrolled. These samples do not isolate per-request allocation or establish a retained-memory leak. The next causal comparison uses matching sleeping targets and fixed requests before choosing a source refactor. Reported heap size is not usable allocation headroom: assigned msections, still occupancy and overflow reserve are subtracted in compute_free_heap_space_approximately. No heap/headroom tuning is justified by these samples.

Source, raw first-error stderr, immutable fixture transformation and native receipt are bound in delivery-2fe7-first-cause.json. Same Grok session continues under normal repair-9-12 custody with instructions to remove a measured hot-path cost, regenerate and freeze one final image, then perform meaningful existing controls and one unchanged original two-file p11/cumulative3600 acceptance. No qualifier/history edits, commit or push. Count remains8/12.


## Rejected sleep-repark candidate e574: source and native counterexample

2026-10-26. Same Grok session built e574780c2e66ce5936363b775745010b73a335224878511be88d6d5e1064080b, UUID201CDA1D-BB9D-3E81-9E1F-21E4EAAEA079, after regenerating _thread.c. Its scoped change delays reparking a sleep interrupted by delivery while checking the original timeout. This is an implemented candidate, not an accepted final B.

Codex rejects its source proof: interrupts-pending? reads the shared thread interrupt head without T ownership and uses only an acquire fence. A fence does not synchronize a plain reader with locked plain writers. The republish wait9.619288444519042e-4 is fitted to the short benchmark interval, without a general scheduling justification. Any replacement must retain the original absolute deadline, use checked queue access, release locks before service and reload after migration/GC; it must not defer timeout until a flood is drained.

The existing migration control actually exited SIGSEGV(-11), with no MIGRATE success line. This alone blocks original acceptance. Static queue access concerns do not by themselves establish the crash PC or unique root cause. Other passing controls cannot overrule the failure. The same120000-call sleeping-target observation also showed no meaningful improvement: interval6.275277 seconds versus2fe7's6.191784, allocation599165312 versus600950000 bytes, and105 versus95 collections. Those single short samples are not a confidence interval, but provide no evidence for the required throughput gain. No original load is justified on this candidate.

Corrected sleeping-target baseline pair removed the former uncontrolled target yield work: ceab644248528 bytes/103 collections,2fe7600950000/95, both120000 exact/root0/faultfalse/exit0. The first fixture attempt omitted handling terminated-thread-exception after real target termination and exited70; its raw failed receipt remains. The corrected fixture catches only that expected teardown exception. These controls remain diagnosis. Source identities, actual raw control outcomes, frozen matching artifacts and both cost samples are bound in delivery-e574-rejected-candidate.json. Grok has been sent the concrete blocking review in the same session; no qualifier/history edits, commits or push.


## e574 startup GC crash identity and bridge obligation

2026-10-26. The matching native DiagnosticReport gsi-2026-10-26-121743.ips binds UUID201CDA1D-BB9D-3E81-9E1F-21E4EAAEA079, PID37951, EXC_BAD_ACCESS address0x7. Its faulting worker stack is ___garbage_collect_pstate+916, execute_sync_op+432, execute_sync_op_loop+372, ___processor_startup_complete+184, then generated ##startup-processor!, ___call and ___run_with_outcome. This is actual startup collective GC evidence. It does not establish the new sleep queue read as the crash source.

Source review finds ___processor_startup_complete enters on_all_processors, which can service GC. Yet the matching generated startup primitive calls this helper without executing W_ALL/R_ALL; a PW_ALL declaration is not register saving. The Scheme call site is after releasing P. This is a concrete missing GC-capable bridge proof obligation, consistent with the fault stack, but not a source-line or unique-PC causal certificate. Grok has the matching report and specific function chain to verify frame markers, fp/hp, saved registers and reload, then fix the Scheme bridge and regenerate. The failed sleep optimization is rejected independently for no cost improvement and unsafe queue observation. The next source step restores that scoped delta, fixes the actual bridge, and investigates redundant continuation capture on the real delivery hot path before another original run. No qualifier/history, commit or push; formal count8/12.


## 60b3 actual startup bridge correction; throughput remains separate

2026-10-26. Grok restored the exact2fe7 sleep implementation, removed the failed polling delta, and changed both Scheme startup_complete call sites to FRAME_STORE_RA, W_ALL, native call, R_ALL, FRAME_FETCH_RA. The actual regenerated SMP _thread.c executes this sequence. New image60b3dfb237ad36891ecffb9a1d79702b78300f1da3615d0bf221b1be1a8cac7f, UUID70518855-4D43-304E-90AF-0516415B1FDE, source_thread.scm4f63edf8495e1ea2b7ecb7a615b12325252c4037748683a605e032a586efe063. Exact source-only2fe7-to60b3 delta is delivery-2fe7-to-60b3-startup-bridge.patch, not a clean-lock cumulative patch. Frozen matching image/source/object hashes and native rows are in delivery-60b3-startup-bridge.json.

The current control summaries record exit0 for resize/GC, C1 selected request GC and keep-cell, nested, migration, termination, both C2 orders, linear debt drain and file exit. cut9 still yields expected retained exit70. A later migration success does not erase e574's real SIGSEGV. Resize0/procs4/GC-count1→11 is a smoke observation, not independent proof that GC was selected inside the exact startup bridge; that narrower witness remains open.

Evidence limitation: Codex initially observed startup-boot-gc exit70 with BOOT-GC2. in controls.json. A subsequent attempt reused the same raw path and summary, now containing BOOT-GC1.2./exit0. This must not be represented as an initial pass. Supervisor requested preservation of the original failure and fixture correction with distinct attempt names. The observed initial summary is not reconstructed as an immutable raw receipt.

This source correction addresses a concrete GC-capable call-boundary gap. It does not remove the measured approximately5000-byte/request allocation cost or prove the historical crash's unique source instruction. Generic continuation objects are two fields in this header, so counting catcher/capture calls alone cannot attribute all that cost. The same Grok session continues with one bounded integrated allocation/handoff profile and a source-causal hot-path refactor, preserving all ownership and exception guarantees. No original load on this unchanged-cost route, no timeout/heap/processor/test changes, qualifier/history unchanged and count8/12. No commit or push.


## 60b3 fixed-work parallel handoff amplification and measurement limits

2026-10-26. Same frozen60b3, default heap, six sleepers×ten senders×2000 synchronous calls,120000 exact, target yield count0. Onp1 the interval was0.518624 seconds (process user+system CPU0.441902); onp11 it was5.697552 (CPU2.207835). Both returned exact count, roots0/faultfalse/exit0 and had no surviving group. P11 GC wall was1.551692 seconds and117 collections. This is a strong scheduling/handoff amplification observation; it does not uniquely identify select, work stealing or lock delay. Wall minus aggregate CPU is a lower bound on intervals with no process CPU, not an exact wait bucket. GC wall and aggregate CPU cannot be summed as disjoint categories.

P1 latest_gc_alloc was negative(-1617911544), so its allocation value is unusable. Source counters are F64; no32-bit-overflow explanation is established. P11's positive aggregate yields approximately4959 bytes/request conditionally, but does not validate the broken p1 accounting. Existing p11 global plain counters also lose increments: wind119359 versus actual120000; these are not exact event witnesses. Generated static object expressions total1088 bytes on the proposed success path, not a measured dynamic histogram, and do not attribute the remaining bytes. No hot-path refactor was applied from these estimates.

The failed first boot smoke is now preserved from its actual session tool result and spawn request: expression explicitly tested (> n 2) after one GC, observed n2 and exited70. The later fixture tested before/after1→2 and exited0. Raw files were overwritten; the recovered record declares its session-output origin and is not misrepresented as original raw stderr. This closes the documentary explanation, not selected-GC-inside-bridge coverage.

Source audit also finds ordinary preferred-current wake policy versus interrupt route's last-processor selection for nonrunning targets. Native result completion already chooses currentP unless an explicit migration/pin overrides it. One bounded p11 co-location diagnostic is now authorized in the same Grok session to test locality without changing VM processor count, workload, heap or deadline. It is not original acceptance; no production affinity change is justified until that causal comparison and ownership constraints support it. No original rerun, qualifier/history edits, commit or push. Detailed source estimates, raw comparison and supervisor corrections are bound in delivery-60b3-cost-attribution.json.


## Locality rejected; internal select wake is conflated with EINTR retry

2026-10-26. Same60b3, p11/default heap, fixed120000 requests: unbound interval6.533507 seconds, verified group co-location8.654798. Each of six colocated groups stayed on its respective0..5 processor for20011 placement observations; VM processor count remained11. Both exact count/root0/faultfalse/exit0. This diagnosis rejects the proposed locality optimization; no route or stealing change was applied. A one-second own-process sample found all11 processors in sync-op GC, including mark_captured_continuation and barrier waits; one window does not identify the entire-run wait cause.

A separate exact-source defect is now established in the wait return path. ___device_select drains the scheduler self-pipe and reports a successful internal abort as ERRNO(EINTR). ___os_condvar_select then retries that EINTR until its fixed50ms deff unless immediate polling or actual device readiness ends the loop. A consumed scheduler wake therefore does not promptly return to the existing unlocked Scheme service path. This conflates an internal scheduling event with an unrelated POSIX signal. The source behavior is verified; its quantitative contribution to original stress still requires same-image native before/after evidence.

The implementation instruction is to retain the public device_select ABI/errno behavior and expose a private per-call internal wake reason to os_condvar_select. Actual internal wake returns promptly after device-ready flags are preserved; true signal EINTR retries against the same absolute deadline. Merely FD_ISSET is insufficient: existing aborted is set before read, and select EINTR may leave fd sets unspecified. Classify actual positive pipe bytes or a real platform abort event, not EAGAIN, EOF or a fabricated flag. Reason state must be caller-local, nonallocating and independent of Scheme roots. Both bare and device-queue lock paths, simultaneous IO readiness and pending SYNC/P-lock re-acquisition remain required checks. No GC may be introduced while native arrays contain untracked Scheme references.

Same Grok session has been resumed under normal custody to implement this concrete return-semantics repair, build/freeze a new B, verify the actual backend and compare cost, then run one unchanged original two-file p11 cumulative3600 acceptance only if safety and measured gain justify it. No sleep polling, deadline/heap/processor/work reduction, qualifier/history changes, commit or push. Source snapshot and actual locality/sample results: delivery-select-abort-retry-gap.json. Count remains8/12.


## 048b internal wake return repair: real gain, incomplete fault closure

2026-10-26. Grok implemented a private per-call internal_wake result from device_select_impl while keeping the public device_select signature and ordinary errno return. os_condvar_select returns promptly for confirmed internal wake, after preserving device ready bits on the device-queue path. Ordinary signal EINTR retries against the same absolute deff. The changed code introduces no GC call or Scheme allocation in that return classification and retains the prior P-lock boundaries. Windows and other platforms are source-only, not native-validated here.

Initial aabbc99f/UUID709FB501 candidate had probe bits128, despite its process returning0. It is not a passed control. A later traced image048b7f9f8c247e8a35056ccdb3b1979f5810b89cd6da1858c50b4752225cb9fd, UUID09ED330D-6ED2-3897-9EC5-D869D3490DB3, formed an ordinary signal row: trace two waits, neither internal wake, EINTR then0, approximately55.8ms against the same50ms deadline (measurement includes scheduling). Internal wake returned in approximately10.8ms/one wait; the real Scheme wake comparison was approximately116.9ms on60b3 versus15.9ms on the initial new candidate. These are actual observed rows, not hard real-time bounds. Signal association must use events during the wait; a flag sampled only after joining its sender cannot identify an earlier return.

On the traced048b image, the same120000 sleeper calls completed exactly with roots0/faultfalse/exit0. Measured interval1.384971 seconds versus60b3's5.697552, approximately4.1x faster. Aggregate allocation was598748256 bytes and100 collections, roughly unchanged; GC wall was0.732118 seconds. This supports the wait-return correction as a substantial throughput cause without heap or workload changes. Existing C1 GC/keep-cell, nested, migration, termination, C2 A/B, linear drain, cut9 expected70 and file-exit rows matched on this image. It is not a full fault or formal9 certificate.

Blocking source-review limits remain: self-pipe EOF still returns no hard error, and its probe wrongly accepts that quiet outcome; diagnostic probe pointer publication/reset is not atomic; the immediate queue-lock check does not witness concurrent P contention with pending SYNC. These must not be erased by ordinary control success. The original two-file episode was started by Grok before the queued EOF review had been resolved, a supervision sequencing failure. Its actual output will be retained, with immutable running image and unchanged cumulative3600 deadline; it cannot substitute for complete fault closure. Future long runs will be separated from source-edit stages by an actual supervisor checkpoint.

The first-uncaught hook is loaded in the parent loader only. run-unit-tests.scm spawns a fresh ../gsi/gsi for each file; loaded Scheme hook state is not inherited by children. The parent also emits an improperly placed second-f warning. Preserve both facts; do not claim this invocation captures every child's innermost exception. Original input files, p11/default heap, qualifier/history and count8/12 remain unchanged. No commit or push. Frozen sources/objects/image, actual probe rows, safety results and current original progress snapshot: delivery-048b-select-return.json.


## 048b original result and final integration review boundary

2026-10-26. The unchanged two-file p11/default-heap episode on048b ended at child elapsed3600.033302 seconds and suite elapsed3600.046186, with timeout=true/returncode-9. The identity-checked group was killed at the original cutoff, parent reaped and group absent. File1 thread_interrupt2_stress.scm actually exited70 at cumulative2816.8 seconds; visible outer exception is thread-join! of thread3. The child innermost cause is unknown because the installed hook was parent-only. Do not attribute this new episode to the focused2fe7 inactive-thread case without evidence. File2 started afterwards and had only approximately783 seconds remaining; it has no completion line. It did not receive a separate3600-second budget.

File1 cleanup printed admission69, enter672804098, leave672804064. The34-count difference is consistent with the CLOSED bit plus34 accepted units in admission69. This is outstanding responsibility after failure, not an established pin leak; no debit or cleanup check was bypassed. Overall outcome remains DENY/TIMEOUT and count8/12. The4.1x short-control gain is preserved independently, not promoted to full acceptance.

Build integration review finds Makefile285 declares all module and normal objects depend on gambit.h. Current header mtime is Oct26 while mem.o, _io.o, _kernel.o, os_thread.o, os_time.o and main.o are Oct24. This does not alone prove a content/ABI mismatch, but recent manual selected-object archive updates do not authenticate the current preprocessing dependency closure. The next final B must rebuild or authenticate that declared closure in the same incremental workspace/configuration, without make clean or a duplicate workspace. Frozen048b remains available and is not silently rebound to new sources.

The next same-session stage is explicitly source/build/short-controls only: apply the concrete EOF/probe-race correction, check durable runnable work under P after servicing a native wake, use existing scheduler dispatch instead of parking over queued work, regenerate Scheme C, close header/object dependencies and prove the error hook actually enters a fresh pressure child. Prepared observer injection is parent-only; it preserves original source files and inserts the immutable error-only hook into the actual child argv. Its smoke must show childp11, hook present, first-inner marker, true child70 and parent0 before any long run. A later fail-fast runner will stop only its own identity-bound group after a known first failure and distinguish that stop from timeout. No next original run is authorized within that source-edit stage; Codex reviews the actual new source/producer/control checkpoint first.

Actual source observations and raw receipt hashes are updated in delivery-048b-select-return.json. No qualifier, Recipe, historical receipt or milestone changes, commit or push.


## c38e coherent wait-return integration and unresolved acceptance evidence

2026-10-26. Same-session Grok built c38e034363550cdeeea0e04bb70c0799f97eaf84340bc70626501eee0f2c1f45 (UUID020811A0-22C6-3411-9754-A3EB53F885F7) after the normal incremental Make header/object dependency closure and regeneration of changed _thread.c. Source changes make self-pipe EOF a hard EIO, use atomic diagnostic pointer/counter publication, and inspect runnable work under the sync-aware P lock after native wait/service returns. Nonempty runnable work enters the existing scheduler; the empty case retains the same absolute deadline. The original two-file stress was not started on this image.

The actual backend probe returned bits0, internal wake9.233ms, and ordinary-signal retry52.966ms with two internal-wake flags0. The observer toy verified actual child argv injection, child11 processors, hook present, innermost OBSERVER-CHILD-INNER, real child70, parent0 and absent group. These controls do not qualify the original workload. The same120000 requests completed in2.370086 seconds with exact count/root0/faultfalse/exit0, about598MB aggregate allocation and110 collections. GC count/allocation remain roughly unchanged. A linear extrapolation to60m sleeping-target requests is approximately1185 seconds; this is not an original measurement and establishes no margin against the original target's1000-second sleep.

A first GC-pair control timed out at45 seconds with no stdout. Two subsequent exit0 runs are preserved but do not explain or close that stall. Repark's initial control observed143us unlock-to-run and a2-second caller sleep, but its flags preceded actual blocking; they do not certify the intended park/unlock overlap. The synthetic fail-fast test executed only one child and assigned continuedAfterFailure=false; it did not exercise a real second loader child. These are explicit evidence gaps, not claimed runtime defects or resolved gates.

A source-only follow-up also observes that note_construct is guarded by obs_configured, whereas thread-intr! still writes its two diagnostic Scheme aliases and calls writer_begin/end unconditionally. The latter perform global atomic increments. This is a concrete remaining observation-path intrusion, not measured allocation attribution or an authorized removal of safety guards. A production cold gate must preserve enabled holder/GC controls and exact-helper identity before it can be accepted. Multiple exception catchers on the success path still capture continuations; their full dynamic byte cost is not established.

Supervision is now split at an actual checkpoint: source/build/short-control results must be reviewed before a separate original-only episode. A25-minute read-only Grok phase produced no native artifacts; its owned frontend was normally closed with exit0, after the current registered spawn list showed only that frontend. The same conversation ID is being resumed for one45-second GC-stall causal action, with own-child diagnosis only if the control remains active, no budget expansion and no original stress. No peer or preexisting native process was selected. A queued PTY message is not proof the model acknowledged it, and model reasoning is not execution evidence.

Structured source identities, actual controls and unresolved predicates are retained in delivery-c38e-wait-handoff.json. The048b cumulative3600-second DENY/TIMEOUT and the focused2fe7 inactive-target exception remain separate generations. No qualifier, Recipe, historical receipt, milestone, commit or push changed; completion stays8/12.


## Framework-first decision and frozen delivery refactor scope

2026-10-26. The next work is governed by the existing ASCENT Evidence relations, source-bound protocol bundles and verification receipts. Python remains process/artifact glue. A journal hypothesis is not an observation; a selected model reference is not native admission; missing provenance in historical vendor/zig/framework views is not a current-producer runtime defect. Existing checkpoint bfd7cb1cd192aad06c01cd76e5112dcbfcfeddcef03d120ada173aad5a03a297 retains that distinction. The c38e source/probe journal family and the2fe7 cost family are hypotheses without observations in that selected view. Their raw native receipts remain separately retained. No unknown is converted to support by writing another summary.

The existing delivery_service_roots.qnt had a concrete abstraction gap: after a finite returnWait it went directly through unlock to service. It could not express retrying native select after consuming an internal wake, or parking again over the runnable work just exposed. The same model now contains readInternalWake/retryAfterInternalWake, ordinarySignal and reparkQueued. The three actual transition mutations have reachable counterexamples for noRewaitAfterInternalWake, noReparkKnownRunnable and realDeadlinePreserved. Positive bare/device/internal-wake safety and temporal progress pass through the existing Quint/TLC adapter. D_eff identity is scoped to one native invocation; after legitimate service a new scheduling slice may be computed without resetting the user's absolute deadline.

The first manifest erroneously listed temporal progress as a state invariant. Its DENY is retained as a checker/configuration error, not a new runtime fault or liveness counterexample. Existing verify checks temporal progress alongside every positive invariant. The corrected final manifest uses --resume-from to authenticate and reuse all six unchanged valid checks, without rerunning TLC. publish-protocol returned PROTOCOL-EVIDENCE-OK. The portable receipt is evidence/model-results/research/delivery-wait-refinement/receipt.json and the standard protocol-bundles registry includes it. Evidence validation derived the exact model SHA3291e3653b96c240d0cea12c8e01312d65a74d1061428e94b7c94e66f40bb420 and recorded_protocol_checks receipt a729cea5f30c01d4586924e78d9dd2abf47197d77e1c55621f20abbcacb66ad2. The declared open obligations remain open; listing them in a manifest does not prove them.

| Fixed work boundary | Concrete functions / artifacts | Required result and current limit |
|---|---|---|
| Preserve the delivery ownership core | ##thread-intr-claim-active!, ___thread_intr_try_release, execution predecessor and Retained predecessor helpers, destroy seal/drain | Keep exact claim, O(1) detach, one final debit and rooted failure retention. Existing short receipts do not authorize redesigning these mechanisms again. |
| Finish the wait-return handoff | device_select_impl, selfpipe_consume_wake, ___os_condvar_select | Confirmed internal wake returns to service; ordinary signal retries the same invocation deadline; EOF/hard errors remain errors; device-ready results survive. c38e implements this source boundary. New QNT negative traces identify the prohibited conversions. |
| Finish service-to-dispatch handoff | ##thread-schedule-with-acquired-processor!, ##lock-processor-with-sync-participation!, generated _thread.c | After the native C arrays are gone, participate in SYNC before acquiring P, inspect runnable work under the actual P lock, then dispatch or retry the original user deadline. No GC under P or untracked raw C arrays. Full generated-root refinement remains a source obligation. |
| Preserve complete GC-capable bridges and build identity | ___processor_startup_complete call sites, _thread.scm -> generated _thread.c, current header and all linked archive members | Retain the actual RA/W_ALL/R_ALL correction and normal dependency-closure build. Do not substitute PW_ALL declarations, an old source lock or selected-object relinking for this identity. |
| Bound production observation and success-path work | ##thread-intr! observation publication; ___delivery_obs_writer_begin/end; ##thread-intr-drain!/execute!/release-finish-target! | The source still performs global observation writes/atomics when construct observation is disabled. Any cold gate must preserve enabled holder controls. Catchers still capture continuations. Neither contention cost nor all ~5KB/request has been attributed; removing exception/reentry/root guards is not an accepted optimization. A refactor here needs an existing source/cost adapter witness before implementation, not another guessed timer. |
| Integrate once through existing framework | Source-bound producer/adapter, protocol receipt, existing targeted native Recipe, then the unchanged original two-file load | Reuse only byte/config/owner-qualified prior products. If a needed edge is absent, retain it as an obligation and obtain that edge; do not expand a new matrix. No full inventory, blind duplicate campaign or new deadline. The first original child cause must be forwarded by the real child argv, and failure must be retained before any next run. |

This scope is a decision boundary, not a new runtime protocol or a claim of sufficient implementation. The model currently contains one abstract request, two abstract root moves, finite wait fallback and explicit action fairness. It does not prove repeated-GC throughput, original1000-second target survival, arbitrary populations or C11/acquire-release correctness. Those gaps cannot be closed by strengthening fairness assumptions or treating a short success as full admission. The old scheduler_wait_gc_contract likewise remains a conditional collective/root model, not evidence that the original workload completes.

The same Grok session's unproductive read-only phases were closed normally; both frontend exit receipts are retained. No new native child was registered in those phases and no original stress was started. Future Grok implementation is restricted to the source boundaries above after their existing Evidence/source-adapter obligations are addressed. A newly failed control is evidence to refine a named transition, not permission to keep adding controls. Formal lifecycle qualification is independently unchanged, as are the qualifier, Recipes, historical receipts and8/12 milestone. No runtime edit, commit or push was made by this model/evidence revision.


### Framework entry boundaries retained after model publication

The current Evidence adapter records delivery_service_roots SHA3291e3653b96c240d0cea12c8e01312d65a74d1061428e94b7c94e66f40bb420 and its portable model receipt a729cea5f30c01d4586924e78d9dd2abf47197d77e1c55621f20abbcacb66ad2. Six declared source/native obligations remain open. The caller supplied those obligations; the relation does not independently prove their text. The inert ASCENT request files and continuation checkpoint are retained in framework-query-index.json. No new Python inference or acceptance layer was created.

Two specific existing entries correctly refused continuation. Agent dry-run would not resume b962c586 because the tfib-repair provider-session record names another ID. That record was not overwritten, and no bare-PTY fallback or new conversation was used. Current human consent is present; a supported provider enrollment path must preserve the previous binding and actual provider identity. The old ascent-review entry rejected stale audit bytes for vendor/gambit/include/gambit.h.in before emitting a graph. Vendor is another source context. No vendor byte, historical expected digest or qualifier was changed to make this pass. Generic trajectory reads and current Evidence/Datalog validation remain usable. Model-scoped source review must be bound to the lock-main producer's actual context, rather than inheriting an unrelated global vendor audit. These are framework source/enrollment boundaries, not established causes of the native stress failure.

An interrupted audit metadata read was reconciled through the existing workspace process-resume command after normal consumer checks. No state file or lock was manually modified and no peer process was selected. These refusals and the model-manifest DENY are retained in the evidence record. No native run, runtime edit, commit or push followed this publication.


## Explicit provider enrollment through the existing framework

2026-10-26. The user authorized continued b962c586 supervision through the existing repair-9-12 framework. The prior tfib-repair binding names a different session, so ordinary resume correctly refuses it. The existing agent adapter now has an explicit --adopt-binding-sha256 option for this case. It requires the exact old task/owner bytes, leaves dry-run unchanged, retains those bytes inside the owned attempt, and publishes only after a successful non-timeout end-turn with every observed provider init/system/end ID equal to the requested UUID. It rechecks old bytes before publication. This does not relax task custody, tool grants, sealed script requirements, process birth, native budgets or admission. No state file is manually rewritten.

The existing launcher suite passed17 tests in49.747 seconds. After adding all-ID consistency and timeout-preserves-old behavior, the three directly affected controls passed in33.924 seconds. These are launcher fixtures with fake providers and temporary real custody, not Grok API or native Gambit acceptance. An initial new-test quoting error and an outer-scope test launch rejected by the durable subprocess policy were corrected without disabling that policy.

The actual same-session attempt is agents/tfib-repair/grok-runs/0045. It uses grok4.7/high, the normal task broker, a source-only six-turn prompt and600-second supervisor cap. At this publication it has zero provider events and stderr reports session_create running long. That is neither successful enrollment nor a Gambit native failure. It does not grant a reason to start another provider or bypass the adapter. The prior binding remains unchanged. Existing source snapshots were copied under normal task custody; audit cross-area writes were rejected and the maintenance role was reconciled by workspace process-resume.

The source-review input freezes current c38e C/Scheme/header bytes in the same owner directory, separating them from old vendor audit provenance. The actual runtime image remains unchanged. New source tests, pressure campaigns, model-property expansion, commits and pushes are not authorized by this metadata repair. Provider receipt and source/test identities are retained in provider-session-enrollment.json; model and native9/12 admission remain separate and count remains8/12.


### Final result of the explicit b962 framework attempt

The agent attempt agents/tfib-repair/grok-runs/0045 ended after600.596369583 seconds with timedOut=true, exit143, parentReaped=true and sessionCompleted=false. The actual event stream has zero bytes; stderr reports a long session_create. No provider initialization, tool execution or native pressure occurred. Mixpanel HTTP warnings do not identify the startup cause. This is a provider transport/init failure, not a Gambit failure. The exact prior provider-binding SHA71c2f9168f5eb5a8976033a266eec3cc62742457ec246927c2b2d64091101570 remains unchanged and no adoption is published. Current gsi remains c38e0343.

The supervisor deadline applies only to this model process; it does not enlarge any native acceptance budget. No second identical restore, bare PTY fallback, new session, peer action or speculative runtime patch followed. Normal workspace resume is used to reconcile actual consumers before the next execution. The framework enrollment delta and passing launcher controls are complete; actual Grok supervision remains blocked before init. The delivery source/cost and original-native obligations remain open. No original pressure, qualifier edit, milestone promotion, commit or push occurred. This result supersedes the earlier pending description without erasing it or any native failure.


Normal workspace resume after attempt0045 reconciled zero pending requests. Its current dependency identity census reports 121 mismatches among 123 registered paths and 121 reuse denials. Reconciled custody is not admitted resource reuse. No adoption, duplicate producer fallback, identity replacement or native rerun was performed to suppress these results. The unchanged gsi byte hash alone does not override the framework resource identity checks. This is a distinct current admission boundary, not a diagnosed Gambit runtime cause.


## Correction of dependency scope and provider replay diagnosis

2026-10-26. Source review of transition_check and task_dependencies.dependencies corrects the earlier blanket-blocker claim. Task execution passes observations to dependencies and checks actual consumer occupancy; this deliberately does not reject every legacy dev/inode mismatch. Strict dependency reuse and retention still reject replacement. The observation field reuseAdmitted=false is unconditional and is not a native attempt verdict. Therefore121 legacy mismatches are not a reason to rewrite the registry or halt all current repair work. No re-adoption or resource-identity replacement was performed. Actual source/build reuse must still be authenticated individually.

The provider's own issue40 describes headless resume stalling before events while draining the full updates.jsonl, with no internal deadline. The maintainer confirmed that load-response sequencing on October13. Current public headless.rs awaits open_session while in SessionCreate and emits init afterwards. This is upstream source/report evidence, not a tested local repair. The local1.0.60 session has an approximately254MB updates log versus0.78MB chat history; the600-second attempt produced no events and ended in the observed SessionCreate phase. This strongly supports replay cost as the transport investigation direction but does not identify a local PC or unique failing function. No repeated restore, offline history truncation, deletion, compaction or credential change was attempted.

The user previously requested Grok implementation and Codex verification. A concise clarification now offers Codex implementation within the same existing task/custody and frozen source scope versus retaining Grok and addressing its replay path first. Until that role boundary is clarified, no runtime source change or pressure run is started. The existing QNT/protocol receipt and native acceptance conditions are unchanged. Public references: https://github.com/xai-org/grok-build-plugin-cc/issues/40 and https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-pager/src/headless.rs .


## Codex takeover: bounded observation/unwind source repair and same-image native controls

2026-10-26. The human explicitly authorized Codex to implement the agreed repair after Grok's replay/init blockage. The existing physical producer was atomically moved, without copying or leaving an alias, into the registered repair-9-12 gambit-core workspace. Its directory inode and complete baseline tree identity were retained; the canonical source is recorded in codex-delivery-current-source.json. This is not a new task, duplicate producer, budget reset or vendor edit. All production edits/builds/native controls ran inside normal task execution custody and the exact workspace lease. This metadata publication uses the registered audit role.

Two bounded changes preserve the ownership/claim/queue/cleanup mechanisms. First, disabled observation no longer performs the global writer ledger and publishes two diagnostic Scheme aliases on each thread-intr!: the new native predicate permits only the validated configured subject or the existing test-only C1 arm. note_construct remains active for configured mismatch/duplicate diagnostics. The actual old image negative wrote1000 times and left aliases populated; the fixed image wrote0 with empty aliases. Enabled holder/GC and extra-alias negative controls still formed.

Second, thread-intr-execute! no longer captures a second exception continuation merely to catch, abandon and rethrow into the existing drain catcher. finish-mode starts at abandon and becomes normal only after the thunk and normal outcome return. The existing dynamic-wind after, original attempt, one-shot entry capability, surrounding drain catcher, exact claim and native result transaction remain. Actual throw and nonlocal-escape controls retain sender abandonment, target exception/escape and root0. A captured continuation reentry is rejected with interrupt-reentry: thunk count1, first result41, sender abandoned, target caught, root0 after clearing the fixture continuation and GC. This is native behavioral evidence; it is not a general compiler/frame-map or C11 proof.

Real qualified gsc regenerated _thread.c and the flat link module, followed by the normal incremental make dependency closure, under the unchanged cumulative300-second build limit/compiler/configuration. Final image aa406fc76d78d82905a585db4ff546e3ca0cc0f4753becc43d1c3fb3b5003a86 binds the exact Scheme, generated C, headers, objects and archive in codex-delivery-exception-build.json. The separate observation-only image cf33 remains a historical comparison, not rebound to this final image.

On aa406, throw, escape, cold observation, enabled selected-GC pair, retained-extra-alias negative, holder termination, nested and migration controls passed. C2-A/B, linear1000/2000/4000 and the expected retained cut9 also passed with authoritative process exits/group absence. The unchanged120000-request p11/default-heap cost control completed with exact count, root0, faultfalse, exit0. Allocation decreased from597808496 to503391680 bytes (about15.8 percent); collection delta115 to103; measured wall interval3.814001 to2.542662 seconds. These are two actual matched controls, not a latency distribution or full-load pass. The remaining roughly4.2KB/request is not explained away, and no performance margin against the original sleeping target's1000 seconds is claimed.

Failures are preserved. An initial observation-only cut9 assertion demanded literal roots5, but the actual retained root was1. Bit1 is Retained and bit4 is a separate deferred pass, not an observation alias. The continued semantic negative checks phase2, armed/membership, Retained bit, DELIVERY_PINS and admission/enter-minus-leave consistency; it does not rewrite that old failed assertion. During the first aa406 batch the legacy capture helper unconditionally killpg'ed during normal completion and raised EPERM at C2-A. No exit code was persisted or fabricated. Framework reconciliation authenticated birth/custody and absent group; its outcome stays unclaimed. Subsequent unfinished controls use existing task_processes.run, which waits/reaps normal exit without a normal-completion kill. No runtime failure or peer action is inferred from EPERM.

The existing QNT wait/service refinement and its discriminating negatives remain unchanged; they do not prove this exception refactor, generated root maps or native wall time. The next original episode uses the same frozen image, unchanged two files, p11/default heap and one shared3600-second deadline. Each original file has its own unchanged loader invocation, and the second is launched only after the first has exited0 and reported its one-file pass. This retains loader child semantics while enforcing first-failure stop. The actual fresh-child hook control must form before originals start. Consult the live original receipt; no original success or formal9/12 is claimed here. Qualifier, recipes, history, milestone, vendor, PR57, commits and pushes are unchanged.

Structured audit: evidence/research/smp-retirement-study/codex-delivery-takeover-audit.json.


## Correction: outer watchdog interrupted the aa406 original episode; no native verdict

2026-10-26. The actual child-observer smoke on aa406 formed: child processor count11, hook present, innermost OBSERVER-CHILD-INNER, true child wait status17920, parent0, group absent. The first original file then started; the second never started. The original runner retained p11/default heap and its inner cumulative3600-second deadline, but Codex omitted workspace run's explicit outer wall limit. Its default1800-second watchdog killed the driver first. This is a supervisor configuration mistake, not a Gambit timeout/failure/pass, and not an exhausted3600-second native stage. No original completion line or innermost runtime exception had been recorded at that boundary.

The driver was authoritatively reaped with -9. Its nested native loader had a separate registered group and survived that parent stop. Codex checked its exact recorded boot/birth/UID/PGID, signaled only that owned group and authenticated absent group afterwards. No peer was selected. The original native exit status and parent reaping are unavailable; they are not fabricated from raw output or from the driver status. The prior pending raw receipt is retained untouched, with this separately published supervision-interruption observation superseding its running description. Normal workspace resume reconciled custody. An unchanged-pressure retry was not started. Any future outer wall envelope must cover the unchanged inner3600 deadline plus bounded setup/finalization; this is not permission to enlarge the native budget.

A narrowly scoped callback-boundary projection was checked after the pressure group was quiescent, using the existing Quint/TLC adapter and90-second per-check cap. Four mutation controls found expected counterexamples (premature normal mode on escape, missing after on escape, callback replay and omitted GC mapping); the positive safety/conditional progress check passed. These five checks are not a lock/Retained/C11/frame-map proof. Their kind abstraction also omits a false-valued exception object. Current drain uses #f both for normal completion and the catcher's returned object; this source path needs a formed native control and cannot be claimed covered by this model. Adding that explicit open obligation reuses the same model checks through the verifier rather than repeating TLC.

Both attempted false-exception controls were refused before production execution: first a registered audit verifier still held spawn custody, then an actual workspace-lease consumer was active. The latter census found a live Python/make/gsc-boot chain holding workspace-leases/a11aadfaf30419821ef950059d8290f0accd6d45bb629eba9320224fde4995ed.lock, rooted at PID1773 with kernel start1793016752.293600. It is not the canceled original group. No peer signal, debugger, sampling, lock change or takeover was performed. Production edits/tests remain deferred while that real consumer holds custody; metadata audit remains registered separately.

Latest original observation: evidence/research/smp-retirement-study/codex-delivery-original.json. Runtime image remains aa406, count8/12; no qualifier/history/recipe/milestone edits, full inventory, commit or push.
