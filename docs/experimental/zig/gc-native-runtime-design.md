# GC Architecture for a Complete Zig Native Runtime

Design only. The [current mechanism audit](gc-current-mechanism-audit.md)
distinguishes existing full copying/still tracing from the proposed collector.
Read the [source/paper ledger](gc-native-runtime-evidence.md),
[conditional arguments](gc-native-runtime-arguments.md) and
[benefit/cost matrix](gc-native-runtime-cost-matrix.md).
No implementation, preprocessor/compiler/native test or performance validation.

**Select a complete research candidate: context-local young allocation, VM-wide
coordinated parallel young evacuation with direct promotion of survivors,
shared nonmoving mature/pinned spaces, and a concurrent major marking design
with explicit mutation/root/publication protocols and synchronized phase cuts.**
This is a proposed target, not an admitted collector or a minimal patch.
Young collection is stop-the-world for the participating VM. Mature collection
concurrency is a separate obligation, not something inherited from Zig.
All parts require one admitted compiler/runtime/FFI cohort.

![Heap domains and ownership](gc-native-heap-domains.svg)
[D2 source](gc-native-heap-domains.d2).

## Heap, Allocation and Promotion

| ID | Decision / owner | Contract |
| --- | --- | --- |
| GD01 | Scheme compiler and runtime jointly define ObjectLayout/TraceSpec | Tagged words, subtype/size/alignment, strong/weak/nonpointer fields, mutable slots, closure cells and frame/point meaning are explicit. Native C/Zig/LLVM consumers use the same facts; no independent Zig liveness analysis. |
| GD02 | AllocationContext owns actual young intervals | Bump-allocate complete objects with bounded writes/formed addresses, explicit safe points and post-relocation reload. Native Zig allocators are for auxiliary storage, not substitutes for managed Scheme allocation [GC-S05/S13]. |
| GD03 | Large/pinned/mature spaces have distinct runtime ownership | Large or stable-address native API objects can allocate directly in nonmoving managed spaces. Native external refcounts/handles retain their declared protection meaning, not universal reference-counted Scheme management. Permanent image data retains a closed immutable/permanent-only graph or explicit root-bearing classification. |
| GD04 | Promotion policy is direct survivor promotion | Every reachable young object moves to mature on this candidate's minor collection. There is no age-tuned survivor nursery in this chosen design. Such an alternative needs its own cost/barrier proof; current MOVABLE1/2 constants do not implement it. |
| GD05 | Minor evacuation is parallel under a VM coordination cut | Freeze actual contexts, foreign root carriers and relevant collector producers; enumerate active roots and remembered source locations; copy reachable young objects with a claimed/complete forwarding protocol; update every scanned reference. Failure retains source/destination custody; no restore-old-hp shortcut after publication. |
| GD06 | All contexts' young spaces are collected together | Cross-context young references within the same VM are permitted only under the admitted Scheme memory model and complete publication. All young spaces move at the shared cut, so ordinary reads need no per-object moving-young read barrier outside it. VM-to-VM raw Scheme heap pointers remain disallowed unless a separately specified transfer mechanism exists. |
| GD07 | CollectorWorkContext is distinct from executing context state | Roots describe frozen contexts, not whatever PSTATE a worker happens to occupy. Independent worker count W and context count U are separate; copying destinations, scratch, queue claims, roots and capacity have explicit owners. Reuse the earlier collector/SegmentLayout/receipt contracts [GC-S13]. |
| GD08 | New mature objects enter a marking epoch explicitly | Fully initialize before trace visibility. While major marking is active, newly allocated/promoted objects are protected for the current cycle and their strong mature referents are shaded/enqueued through completion/publication; weak slots enter their typed weak protocol. No marker scans an uninitialized body. This is our conservative protocol, not a claim of the paper's exact allocation algorithm. |
| GD09 | Concurrent major collection is nonmoving | Mature/pinned pools carry explicit mark/sweep/page state. Mark workers scan only published nonmoving objects through qualified field accesses, not unprotected young pointers or actively mutating Scheme frames. Concurrent sweeping, if used, consumes only a closed dead set and cannot reuse a page still owned by allocators or readers. |
| GD10 | A minor cut can interrupt the major schedule | Park or acknowledge major workers at a cut with no unprotected young dereference/borrow. Evacuation updates roots/remembered locations; promotion records mature marking work before major workers resume. A major worker cannot observe a reset young page through stale metadata. |

Initialization, reaching a trigger, actual capacity assurance and completion
publication remain different events. The predecessor's isolated no-handles
pair B=3 applies only to that admitted local operation. Barrier logs, frame
construction, native conversions and promotion have separate space/bound
contracts. Mature/young capacity and copying reserve are accounted separately;
the old two-half msection formulas cannot simply be reused after the heap split.

## Unified Managed-Store Protocol

The selected source has plain stores at many real writer sites [GC-S04/S11].
Replacing only set-cdr! is not a generational or concurrent collector migration.
The [writer-family inventory](gc-native-store-inventory.json) is a selected
necessary-work inventory, not a declaration that every raw store is classified.

| ID | Operation family | Required invariant / slow path |
| --- | --- | --- |
| WB01 | Private InitStore and PublishObject | Direct initialization is allowed only inside an exclusive unexposed construction interval with rooted inputs and no unclassified safepoint. Publication supplies young-edge remembering and active-major referent shading before the object becomes traceable/shared. It is not an ordinary mutator write. |
| WB02 | MutateStore into a published managed field | Before overwrite, protect/enqueue the old mature referent for active SATB marking. Record the source location when a non-young container receives a young reference. Then perform the qualified store with appropriate visibility. Immediate values and declared nonpointer slots avoid pointer work only after classification. |
| WB03 | Remembered source ownership | A record identifies a stable owner/object plus slot/range and epoch, or a properly owned card/page recipe. A raw address into a moving frame or freed native RC cell is not a durable record. Repeated dirtying may coalesce only with safe coverage, re-dirty and phase-reset ordering. |
| WB04 | RootWrite/register/unregister/transfer | Native root cells, global cells, active frame homes and root-carrier transfers participate in major-root snapshot/deletion/insertion obligations. Hold a root cell while snapshots/logs/readers can use it; unlink is not immediate free. A new handle is accepted only from an already valid live reference, never a fabricated pointer. |
| WB05 | Atomic compare/exchange | Preserve Scheme atomic semantics and only successful-store edge creation. Conservatively logging attempted old references/remembering candidate locations may be valid; failed CAS is not a successful mutation. Recompute obligations after retry; root owner/location cannot disappear during the attempt. |
| WB06 | Bulk writes and weak/typed slots | Bulk fill/copy/shrink, GC tables, closure cells, native markers and runtime initialization require typed variants and complete old/new edge coverage. Weak edges do not become strong merely because a generic barrier logs values. Collector relocation stores are separately admitted collector operations, not silently barrier-free mutator stores. |
| WB07 | Log/remember capacity and interruption | Reserve finite native log capacity before a store's commit interval. If unavailable, keep destination/new/old values protected and enter a legal slow/safe-point path before overwriting. After that boundary reload locations/values and the current epoch, then retry the obligations. No allocation, callback, park or epoch change inside a claimed no-safepoint commit. Local defer does not enforce this protocol. |
| WB08 | Managed memory model and reader agreement | Concurrent scanner loads and mutator stores need a qualified atomic/access protocol for each mutable word and epoch. A memory fence on a queue does not fix C data races or replace generational remembering. Read-barrier-free young movement does not mean unsynchronized concurrent major scanning is safe. |

The SATB pre-write obligation and young remembered-set obligation solve different
problems. They share a typed operation but cannot cancel each other.
Exact memory orders, atomic representation, root/frame mutation coverage and
all primitive/native writers remain unresolved admission work in both modern
C and Zig. C ABI interoperability alone does not admit raw external writes to
managed pointer fields.

## Roots, Continuation and FFI

| ID | Root or control domain | Design decision and actual dependency |
| --- | --- | --- |
| GR01 | Active Scheme context | At safe points publish semantic root homes, frame frontier, register materialization, dynamic state and PointIds before participation acknowledgement; restore current owner/PSTATE and reload after movement [GC-S08/S14]. |
| GR02 | Captured continuation graph | Preserve actual logical frames, return links and dynamic environment; young captures are promoted/traced, mature captured frames use typed field/publication/barrier contracts. Activation during major marking supplies a valid scan epoch before saved state becomes mutable execution state [GC-S09, GC-P03]. |
| GR03 | Multi-shot restore | Repeated invocation must not consume a linear native borrow/lock/allocation token from a prior activation or mutate earlier map results. Each activation acquires current allocation and owner bindings. Live frames retain code/maps/image users [GC-S14]. |
| GR04 | Native roots and RC replacement | A VM RootRegistry explicitly owns RootSlots/carrier lifetimes and scan cuts across every context. Registry insertion, payload replacement, transfer and teardown follow WB04. It replaces reliance on PSTATE-local RC registration plus a processor-0 scan assumption; actual native callers must migrate [GC-S11]. |
| GR05 | Foreign entry, borrow, blocking and callback | Protect proc/arguments before any marker/conversion allocation. Raw movable borrowing is limited to an admitted nonallocating/nonblocking/no-callback interval. Longer access uses rooted handles, copied native data or an actual pinned lease. Blocking relinquishes execution only after stable root publication; callback reacquires permitted VM/owner state and restores dynamic binding on every exit. |
| GR06 | Weak/finalization/resource lifetime | Preserve selected will/weak/hash semantics under minor/major treatment; keep weak remembering distinct from strong tracing. Heap death can enqueue owner-affine release tasks whose payload/code/VM remain held until completion. Explicit release races with GC release need per-object/resource arbitration and failure ownership [GC-S10]. |

For minor collection, active execution roots are scanned. A mature captured
frame's young fields can be covered by the remembered-set contract rather than
traversing the entire mature continuation graph each time. That optimization
requires complete frame-publication/mutation coverage and an independent root
oracle; otherwise account the conservative full scan. Major collection still
traces the live mature continuation graph. Generations cannot make map's
pending control state or captured values disappear.

An immutable image/permanent object may reference only its closed permanent
graph in the retained category. A runtime structure holding mutable/young data
must instead be an explicitly traced root/container. Treating it as permanently
unscanned would be unsound. Stable native addresses and Scheme liveness are
separate properties.

## Coordinated Phase State

![Minor and major phase protocol](gc-native-phase-protocol.svg)
[D2 source](gc-native-phase-protocol.d2).

| ID / state | Entry/exit obligation |
| --- | --- |
| GP01 Running | Context allocation leases and active-major store/root policy are valid. A collection request records the actual requested scope/participant epoch; it is not completed when merely queued. |
| GP02 Rendezvous | Freeze membership and relevant root/store producers, acknowledge running/parked/foreign contexts and affected major workers; no native frame/partial initializer is falsely accepted as a complete root carrier. An uncooperative unknown native effect keeps the request unresolved. |
| GP03 Minor evacuation | Freeze remembered work, scan active/foreign roots and relevant non-young fields, claim/copy/finish forwarding, scan destination work and update references. Handle weak families and promotion-major handoff according to their declared contracts. |
| GP04 Minor close/resume | No source young reference remains in admitted roots/containers/queues; all copied bodies and new mark work are published; capacity/layout and actual context leases are rebound. Only then recycle young pages and acknowledge completion. |
| GP05 Major start/mark | Establish a root/young-to-mature snapshot with the active write/root protocol. For this candidate a young evacuation at the start cut may simplify that snapshot, but its cost is explicit. Continue marking nonmoving published mature objects, draining actual log/producer work. |
| GP06 Major closing cut | Coordinate mutators/foreign/root/publication producers and workers, drain acknowledged logs and work to quiescence, rescan required roots and process weak/will dependencies. Queue emptiness alone is not completion. New producer epochs may not publish into the closed cycle. |
| GP07 Sweep/release | Sweep only the closed reclaimable set; publish page allocator rights separately from scan completion. Foreign cleanup is delivered to its admitted owner, not executed arbitrarily on a worker. Unknown cleanup retains actual custody. |
| GP08 Retirement | Stop new entries/producers, transfer root carriers while scan facilities exist, drain accepted/derived release tasks, close workers and drop code/maps/storage only after their last users. Removing a PSTATE or native refcount is not this proof. |

A major cycle using conservative new-object shading can accumulate extra work.
No fixed-work or finite-pause theorem is imported from OCaml's different colour/
allocation protocol. Closing may require a coordinated cut; its pause cost and
foreign responsiveness remain explicit. Budget/pacing/log exhaustion and heap
pressure cannot be solved by an unbounded timeout or by freeing unknown work.

## Responsibilities and Replacement

GD11. Keep Scheme as the semantic producer of layouts, effects, roots, safe
points, language stores, closure/capture/value rules and initialization recipes.
Zig implements the selected allocator, collector, queues, root registry,
worker/coordinator services and native product realization. The collector's
algorithm semantics remain Gambit specifications; “Gambit owns GC” does not
require its implementation to remain C.

GD12. Existing full-collection traversal, subtype knowledge, frame semantics,
weak/will behavior and C API contracts are specification/reference assets.
Current copying-loop queue and forwarding code are mechanisms to inspect and
adapt, not proofs for new promotion, atomic ordering or concurrent workers.

GD13. Replace direct mutator writers with WB operations across Scheme-emitted
Zig, modern generated C, runtime helpers, FFI wrappers and admitted native
extensions. Unknown raw C pointer writes reject the new generational/concurrent
profile or require an explicitly bounded conservative island; they do not
silently remain fast uninstrumented stores.

GD14. Split collector scratch/copy destinations from execution-context
allocation state and scanning ownership. New young/mature/page capacity ledgers
must preserve the prior actual interval, InitSpec, SegmentLayout and failure
custody invariants. Reusing names does not port the old capacity proof.

GD15. Rewrite native root/marker/blocking/reentry support around an explicit
root owner and epoch protocol. The current RC scan discrepancy and marker
protection TODO are concrete modernization obligations, not justification for
inventing a new GC without fixing those entry contracts.

GD16. Rebuild modules, runtime layout/operations and all frame/FFI/primitive
consumers together. Correct Scheme values, C-facing interfaces and module
semantics are goals; preserving old inline macros or binary ordinals is a
separate declared compatibility choice.

GD17. LLVM/MLIR can receive explicit allocate/store/root/safe-point operations
and produce qualified native code/maps behind the shared runtime contract
[GC-P05/P06]. Zig source generation and a direct LLVM provider are alternatives.
LLVM supplies no collector, root registry, promotion policy or worker shutdown.

GD18. This full candidate includes GC algorithm modernization plus native
language reconstruction. Compare their benefits/costs separately, then the
complete product. Theoretical positive conditions and counterexamples are
specified in the [arguments](gc-native-runtime-arguments.md) and
[matrix](gc-native-runtime-cost-matrix.md). All native, writer/FFI completeness,
progress and economic admission remains open.

## Generated C and Captured-Frame Policy Refinement

The [modern generated-C mainline](generated-c-native-contract.md) supersedes
GD11's earlier mandatory Zig implementation placement: Scheme owns completed
semantic/native products and C owns the selected runtime policies. The
[map continuation study](map-continuation-gc-design.md) refines GR02/GP03/GP05
with lazy stack capture custody, shared-frame mutation and real reconstruction
writers, minor materialization/promotion closure, retained major root-value
snapshots and repeated root/stack activation. Mature captured frames are not
universally immutable; selective minor scanning requires every relevant writer
to be covered. The [matrix](map-continuation-gc-benefit-matrix.md) charges
promotion, access/barrier/root/major/phase and replay costs explicitly.
This is a Gambit-specific candidate informed by learning from OCaml, not a
copied collector or an implementation/native qualification.
