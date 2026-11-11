# Map Continuations in a Modern Generated C Collector

Architecture research only. No compiler, Scheme/native test, model or
performance experiment was run. Read the [source evidence](map-continuation-gc-evidence.md),
[conditional arguments](map-continuation-gc-arguments.md),
[benefit matrix](map-continuation-gc-benefit-matrix.md) and
[learning and reflection](map-continuation-gc-learning.md).
The [trace](map-continuation-gc-traceability.json) binds selected source bytes,
not an executed collector. Operation and state names below are proposed.

CG01. Start from Gambit's own requirements: cheap ordinary calls and capture,
proper tail transfer, general repeated continuation invocation, dynamic-wind,
foreign calls and inspectable frames. Study OCaml's mechanisms to expose
choices and counterexamples; do not adopt a collector or one-shot control
restriction because another system succeeded with it. Scheme semantic
completion and generated C remain the mainline. [CE01–CE05, LP01–LP03]

## What the Current Code Actually Does

CG02. Public map saves a callback result while recursively mapping the tail,
then builds its output pair. Stored L2 returns from the callback and L4 from
recursion; L5 is the post-CONS heap-check resumption. Capture inside the
callback therefore retains both that callback's continuation and pending map
frames from earlier elements. Capture inside a poll handler can instead retain
an internal frame, requiring the RETI saved-register/actual-return interpretation.
The existing point inventory remains a correspondence oracle. [CE01, CE06]

`CONTINUATION_CAPTURE` initially writes the continuation header, frame and
dynamic environment on the Scheme stack, introduces a break boundary and may
leave the captured frame chain stack-backed. `mark_captured_continuation` later
copies such frames to heap FRAME objects, recording forwarding links to preserve
shared frames. Heap-frame scanning still uses normal/internal descriptors.
The break handler restores a heap frame by copying it to the execution stack;
it does not generally consume the saved heap frame. [CE02–CE04]

`##continuation-copy` copies the two-field continuation shell and shares its
frame/denv references. `##frame-set!`, `##continuation-set!`, frame/denv setters
and `##continuation-next!` are real mutation paths. `_io.scm`'s
`##implode-frame` actually allocates a frame and fills it through `##frame-set!`.
Thus ordinary replay is different from unrestricted immutability of every
captured frame. Unconditional deep-copy or copy-on-write would need an alias
semantics argument, not merely a GC optimization rationale. [CE05]

## Source-Composed Case, Not an Observed Execution

CG03. The following history composes the real map and call/cc implementations
with an arbitrary permitted callback. It is an inert reasoning scenario, not
a newly run program or a claim that every callback captures:

| Step | Event | Values and ownership that must survive |
| --- | --- | --- |
| T0 | Map has processed an input prefix and invokes proc on element j | Earlier pending results, current input pair, proc, surrounding continuation/dynamic state |
| T1 | Proc captures k and stores it in a reachable global/native carrier | Continuation shell, captured frame chain, denv, code/maps; original stack storage is still owned if capture is lazy |
| T2 | Proc allocates or enters a legal GC/foreign participation point | k and all pending values have admitted roots before movement; marker creation is not retroactive protection |
| T3 | Minor cut materializes needed stack frames and promotes reachable young objects | One destination identity per source object/frame activation; every copied edge and root updated |
| T4 | Original call returns through L2; recursive map continues | Relocated current pair/proc/result homes are reloaded; cdr read follows callback return |
| T5 | Original map returns result list A; k remains reachable | Pending captured frames, their values and code remain live even though this invocation returned |
| T6 | Later minor/major collections run | Minor need not retraverse an unchanged fully mature captured graph; major must still trace it |
| T7 | k is invoked, possibly repeatedly | Winding/value delivery, root handoff and execution-frame restoration; A is not destructively reused by the implementation |
| T8 | Explicit frame mutation or another capture occurs | Respect shared-frame identity, remembered edges, active-major protection and new frame/stack ownership |

These are possible event orders, not a promise of collection at every step.
The callback may instead raise, diverge, block or never capture. Multi-list map
also traverses cars/cdrs/apply helper states with their own allocations, roots
and sentinel policy. The earlier complete map path remains required. [CE01,
CE04, CE08; RD01]

![Map capture, promotion and replay](map-continuation-gc-lifecycle.svg)
[D2 source](map-continuation-gc-lifecycle.d2).

## Heap and Capture Decisions

CG04. Retain the researched full candidate: context-local young bump allocation,
VM-wide coordinated parallel young evacuation with direct survivor promotion,
shared nonmoving mature/pinned managed storage and concurrent major tracing.
Execution stacks are a distinct owned root/frame region, not an unregistered
part of an ordinary nursery. Young, still/pinned, permanent and stack-backed
objects need explicit TraceSpec/region treatment. Current still/permanent
classes and movable header tags are not already an age-based collector.
[CE07; RD02]

CG05. Preserve lazy stack-backed capture as an intended fast path, subject to
an explicit capture/segment ownership record. The record holds context/segment
identity, the actual frame frontier, normal/internal FrameSpec/PointIds, denv,
code lifetime and pending publication obligations. It cannot be a raw pointer
whose stack segment is free to rewind or retire. Multiple captures of one
dynamic frame can share it; equal static FrameSpecs do not identify equal
dynamic activations. A restored execution copy gets its own activation custody.

At an acknowledged cut, or before an admitted transfer to another owner,
stabilize the needed chain into mature FRAME objects, preserving sharing through
a dynamic-identity forwarding map. Concurrent major workers never chase an
unprotected stack-backed frame in a running context. A newly published mature
continuation shell that still has a stack-backed chain carries explicit
owner-side scan/stabilization debt; it is not an ordinary ready-to-scan object.
Shell retention/colour alone does not discharge its referents. Existing same-VM
cross-context legality and native stack-marker restrictions remain separate
control contracts; this design does not invent unrestricted cross-VM replay.
[CE02–CE05, CE08–CE09]

CG06. Distinguish private construction, scan publication and executable
handoff. At capture, stack writes and shell/denv initialization are recorded in
the completed operation. Before the original segment can be reused, the runtime
must either keep the stack capture intact under its lease or finish the
materialized replacement and update every referring anchor. At a materialization
cut, ordinary mutators and relevant frame readers/writers are parked; a GC-owned
rewrite is not an ordinary unbarriered mutator write. After publication, frame
and continuation mutations use typed writer protocols. [CE02–CE05]

## Minor Collection Closure

CG07. An admitted minor collection has these ordered obligations:

1. Freeze membership and close current root/store/capture producer epochs.
   Running, parked and foreign contexts acknowledge complete roots; relevant
   major workers relinquish leases which could touch young/stack storage.
2. Enumerate actual roots: register/saved homes, active normal/internal frames,
   break/capture anchors, current-thread/denv/global cells, native RC/handle
   carriers and accepted task/collector-owned root buffers. Use explicit owner
   records; worker PSTATE is not the mutator's root identity.
3. Materialize reachable stack-backed captures and trace young roots plus
   remembered non-young source locations. Newly created frames must enter this
   work set before their source stack storage can be reused.
4. Claim destinations, initialize bodies, preserve dynamic sharing, publish
   forwarding for admitted collector readers, scan/fix child edges and account
   every outstanding copy/scan/publication task. A forwarded body may still
   contain unprocessed young edges; it cannot escape the collecting phase yet.
5. Settle typed weak/will/ephemeron work under its separately admitted policy.
   Publish promotion-to-major work and final root/field updates. No strong
   carrier or collector queue may retain a reclaimed young/stack address.
6. Rebind allocation/root/layout leases, acknowledge global completion, then
   recycle source storage and resume. Forwarding visibility is not completion.

The [edge inventory](map-continuation-gc-edges.json) covers selected real writer
families, not all primitive/FFI/weak callers. Failure to enumerate any root or
writer keeps the full profile unresolved. [CE03–CE09; RD02–RD03]

CG08. Promotion requires capacity for destinations, forwarding metadata,
remembered/mark work and root/capture stabilization. Reserve before irreversible
publication, or retain the collecting phase and all source/destination custody
under a specified failure outcome. Once any forwarding/root replacement is
visible, rewinding one worker's heap pointer is not rollback. Allocation pressure,
collector worker count and mutator-context count require separate ledgers.
This study does not establish an allocation-failure recovery implementation or
a finite upper bound for arbitrary foreign/callback delay. [CE03, CE07–CE09]

## Two Barrier Purposes and Explicit Frame Mutation

CG09. A strong managed write has distinct obligations: generational remembering
preserves a non-young source containing a young reference; active-major deletion
protection preserves required overwritten mature referents. Neither replaces
the other. A candidate prepare/commit sequence roots inputs, reserves bounded
log capacity, resolves a stable source/slot, acquires admitted access/epoch
rights, records required old/new obligations, commits the qualified store and
settles publication debt. Slow preparation may collect; recompute addresses and
values after it. The commit interval cannot allocate, park or invoke Scheme.

| Selected writer | Young-collection obligation | Concurrent-major obligation |
| --- | --- | --- |
| New output pair / private frame initialization | Root inputs and finish body; fresh young private stores need no remembered entry | Publish required mature edges before readiness; allocation colour alone does not trace fields |
| Global/RC/native root receives k or a young value | Enumerate an owned root cell, or remember its stable location by an admitted root protocol | Snapshot/root adoption/deletion policy and actual carrier lifetime |
| Mature continuation frame/denv or frame slot changes | Remember destination slot if it now refers young; retain owner until drain | Preserve overwritten required mature referent; synchronize scanner/writer access |
| Restore k into execution stack; rewrite thread denv/caches | New active root frontier and managed thread/cache writes both covered | Root activation and all managed heap-field writes join current marking epoch |
| Materialization/evacuation forwarding and link repair | Collector-exclusive relocation; update all strong locations before source reuse | Major workers parked or use a separately admitted relocation protocol |
| Frame reconstruction in `##implode-frame` | Fully trace-safe initialized representation during every possible allocation/check; do not infer no GC from interrupt masking | Private construction can specialize barriers only after escape/safe-point analysis; otherwise use normal protected stores |

CG10. Ordinary restore copies saved content to the executing context. Explicit
mutation can modify a shared saved frame, including one shared by
`##continuation-copy`; preserve that identity. A mature frame cannot be classified
as forever immutable just because the ordinary restore path leaves it intact.
Use a per-object/frame read/write access protocol: scanner claims a read/scan
lease, writer prepares capacity outside its exclusive no-safepoint commit,
then revalidates owner/epoch/layout and commits the typed slot update. Shared
metadata/header changes need atomic interpretation and explicit transitions.
No plain C load/store races are excused by adding a fence.

Frame/continuation introspection can also modify links, cursor or denv. Raw
control slots cannot silently be treated as ordinary strong fields; preserve
descriptor interpretation or validate a reconstructed frame as a new declared
control state. All selected internal users, including serialization, need this
classification. COW that changes aliases or forbidding a supported mutation is
not an equivalent substitute. Complete external/internal caller closure,
memory orders, lease progress and structural-mutation acceptance are still
unresolved. [CE05–CE06; LP04–LP05]

## Roots, Major Marking and Repeated Resume

CG11. Make the major snapshot explicit. A candidate start cut first completes
the selected young evacuation/stabilization, then copies actual mature root
values and owned suspended-frame anchors into retained marking work. A list
of addresses in a live running stack is not a value snapshot. Major workers
subsequently scan published mature objects, not mutating execution stacks.
New/promoted objects and root adoptions publish mature-edge work in the current
epoch; heap/foreign/frame mutations satisfy the selected major invariant.
New young-to-mature edges require the same publication/deletion coverage as
other managed edges. Closing coordinates producers, drains work and weak
dependencies and only then admits sweep/release. [RD02; CE05–CE09]

This may permit an explicitly proven root-deletion specialization: dropping an
active-stack root whose mature value was already copied into the retained
snapshot needs no second SATB log solely for that deletion. It does not waive
heap-field deletion, new-root adoption, new object edges or minor root scanning.
Nor does it justify removing arbitrary stack materialization/checks. Without
the per-event proof, keep the conservative root protocol and charge its cost.
Root snapshots add storage, start-cut work and conservative retention; no short
pause theorem is claimed. [CG07, CG09; LP01]

CG12. Restore is an ownership transaction: protect k, delivered values, denv
and code; obtain a consistent saved frame view; prepare destination stack/root
capacity; restore normal/internal frame shape; enroll the new active root
frontier and thread state before releasing old carriers. Dynamic-wind can
execute arbitrary Scheme, collect, raise or capture again. Therefore split the
operation around such calls into resumable rooted stages, revalidate layout/
owner/epoch afterward, and retain the saved source on nonlocal exit. Repeated
resume allocates new output construction as required; it does not take away a
previously returned list or consume k's sole saved frame. Native return markers
retain their existing validity restriction. [CE04, CE08–CE09, LP02–LP03]

CG13. For an unchanged mature saved-frame graph, minor GC can inspect its root
pointer and remembered/dirty sources without retracing every mature frame and
descendant. This is a conditional elimination of repeated minor work, not of
all stack scanning: active/restored frames are roots each minor; newly
materialized/promoted frames need full processing; major still traces saved
graphs; explicit modifications create new dirty/mark work. Immediate promotion
may also retain short-lived frames in mature storage until a later major cycle.
[CG05–CG12]

## Generated C and Retirement Boundary

CG14. Scheme completion emits allocation/init/publication, capture-stabilize,
root handoff, typed frame/managed stores, checks and normal/internal resume
effects. It generates FrameSpec/PointId/TraceSpec and C products from those
facts. C policies implement actual nursery/mature allocation, forwarding,
root/remembered/major queues, leases and phase termination. The old emitter's
inactive SSB path, direct continuation/global/pair stores and raw frame helper
bodies cannot remain hidden exceptions. A future LLVM provider must implement
the same obligations through its own qualified physical maps/control path.
[CE01–CE09; RD01–RD03; LP07]

Retire old full-copy young/mature traversal and raw writer responsibilities
only after all selected root/primitive/FFI/frame/serialization consumers use
their replacements. Retain subtype/frame/dynamic-wind semantics and independent
readers as specification assets; zero paths retire in this research. The target
is a complete runtime reconstruction, not a claim that extracting metadata or
changing the implementation language implements a collector.

CG15. Local conditional closure is now specified for the source-composed map
history. Full writer/weak/FFI closure, concurrent memory-model realization,
progress/capacity failure handling and workload-specific positive total benefit
remain unresolved. The matrix states the positive and negative regions without
human-day scoring or invented runtime measurements.

## Real Writer and Native Caller Refinement

The [caller closure study](continuation-writer-closure-design.md) expands CG09–CG13
to actual denv/cache/default-parameter, feature-specific env insertion,
reader→implode construction, scheduler save/restore and RC/SFUN/CFUN/run paths.
Its [proof](continuation-minor-scan-proof.md) states the young-boundary conditions
for mature graph traversal omission, including unknown foreign writers and
unregistered roots which a narrow fallback cannot repair. Its
[matrix](continuation-writer-benefit-matrix.md) distinguishes graph traversal
from optional cooperative native root-cell elision. All replacements remain
design-only; full source/native/weak/progress/value admission remains open.
