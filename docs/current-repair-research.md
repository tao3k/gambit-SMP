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
