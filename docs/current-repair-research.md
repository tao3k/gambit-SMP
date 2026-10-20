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
