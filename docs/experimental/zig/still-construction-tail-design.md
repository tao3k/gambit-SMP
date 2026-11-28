# Still Construction, Cross-GC Credit and Copy-Tail Handoff

Reviewed: 2026-10-20. SharedRuntimeContract architecture research only. No
implementation, native test, model/solver/engine execution, checked proof or
positive net-benefit bound. This refines GCM04--08 and GAL01--08 in the
[capacity study](gc-capacity-result-design.md), with the
[source/paper ledger](still-construction-tail-evidence.md),
[matched maintenance matrix](still-construction-tail-cost-matrix.md) and
[document trace map](still-construction-tail-traceability.json).

The [InitSpec and next-collection study](init-spec-segment-layout-design.md)
now binds selected real producer completion endpoints and the layout's GC/check/
accounting consumers. It clarifies STL04: next GC traces actual roots and scans
new copied destination work; old copied/context runs are not automatically roots.
The trigger reserve in STL03 is nominal capacity: completed objects can occupy
it before a later check and must be classified/accounted as actual objects at
freeze. This refinement is conditional design, not an implemented adapter.

The decision is a substantial replacement of processor-owned C allocation,
publication and layout assumptions, not a Zig wrapper around malloc. Gambit
retains subtype, root, continuation, allocation-check and GC policy semantics.
One native heap service owns actual storage and allocation rights; it can be
implemented in modern C or Zig. LLVM does not supply this runtime service.

## 1. Real Callers Separate Four Different Events

| ID | Source observation | Architectural consequence |
| --- | --- | --- |
| SCU01 | alloc_scmobj_still precharges or obtains GC capacity, then allocates native storage. Small allocations defer accounting. It links the still object before writing refcount/length/header; the caller initializes its body before another allocation [SC-S01]. | Existing processor participation, not independently readable list membership, protects construction. Reordering the list pointer alone cannot introduce independent scanners. |
| SCU02 | still_obj_refcount_dec and release_scmobj only decrement. Sweep later frees unmarked storage and recomputes actual words; force cleanup frees all entries [SC-S02/S03]. | Dropping a construction reference, reclaiming native storage and refunding unused credit are different events. A refcount is not a shutdown lease. |
| SCU03 | UTF-8 conversion can encounter an error after allocating a string; it calls release_scmobj and returns an encoding error. UDP receive constructs a bytevector, copies bytes, drops its construction reference and returns it [SC-S04/S05]. | A failed conversion can still leave charged storage awaiting GC. A dropped reference can also accompany successful publication. Neither return class alone determines a quota refund. |
| SCU04 | Weak-table construction drops the still reference before filling flags/counters/slots. scan reads weak metadata. scan skips string/numeric/foreign payloads [SC-S06/S07]. | Valid headers and all-zero bodies are not a universal ScanReady condition. A caller's not-interrupt declaration is not a proof for an independent collector. |
| SCU05 | POINTER_to_SCMOBJ fills tags, release function and pointer before returning. release_foreign reads these fields, clears function/pointer, then calls native code [SC-S08]. | GC scanning, native destructor readiness and language visibility require separate conditions. Preserve opaque FOREIGN payload semantics; do not infer a new traced tags field. |
| SCU06 | still-copy saves/reloads registers around allocation, then copies the reloaded source body; pair/vector constructors restrict movable inputs [SC-S09]. | Preserve actual root/reload requirements. A Zig pointer or slice does not replace a Gambit root, and no new movable-input support follows from this design. |
| SCU07 | Aligned allocation saves the native container pointer separately from the aligned base. Free recovers that pointer [SC-S10]. | Record the real deallocator/container identity. Logical still words, aligned object bytes and native allocation bytes are distinct quantities. |

This is a selected, explicitly enumerated caller slice. Generated primitives,
all foreign clients, permanent allocation when ps=NULL and alternative build
profiles still need their own closure; no global allocator migration is admitted.

## 2. Records and Responsibilities

The notation below describes data and authority, not implemented APIs. Pre-reserve
noncollecting metadata and root slots before native effects. Reuse the existing
G operation authority, C custody authority and T trace authority. H names the
heap service's short accounting/allocation-rights authority, replacing the
appropriate allocation-lock responsibility rather than adding a separate
language-specific service. No G/C/T/H/L nesting, callback, allocation, scan,
layout write or blocking wait occurs inside these short gates. Actual native
delivery must provide qualified happens-before edges [SC-P01].

| ID | Proposed record | Authority and lifetime |
| --- | --- | --- |
| SCR01 | StillGrant: VM/reuse identity, GrantId, originating batch/member, word demand, activation reference, grant state and current ledger membership. | H enrolls/charges prepared Reserved grants before G activates the exact batch; denied batches have no new usable credit. H serializes claim/unused-disposal/consume/refund. Minting epoch remains historical; current ledger revision changes. Tokens do not grant authority by copying. A pinned immutable activation result can cross G to H without nested gates. |
| SCR02 | ConstructionRecord: AllocationId, grant, NativeBlockId, aligned base, real container/deallocator, logical words, native extent, owner, initialization profile, root/input/effect leases and actual disposition. | Prepared and enrolled before calling the native allocator; its custodian survives observer loss. Known storage is committed to private actual accounting before the operation is reported Consumed. No fallible metadata allocation follows an untracked native effect. |
| SCR03 | InitSpec: actual Gambit subtype/header/length and alignment, traced cell ranges, weak/frame/continuation metadata rules, native destructor arming, permitted safepoints and completion endpoint. | Gambit semantic definitions/compiler supply it; the heap service executes and checks the profile. No guessed uniform zero-fill, subtype substitution or Zig-derived pointer tracing. Custom/unknown constructors are rejected from the new profile. |
| SCR04 | ConstructionScanEntry and publication disposition. | Actual roots/list membership become visible through the qualified target adapter, with construction rooting and exact physical-cell writer ownership. C root membership and G epoch publication retain their existing ordered handoff. H charge membership is a different fact; no nested commit is assumed. |
| SCR05 | RecountCut and RecountImage: VM/heap identity, held admission cut, shard/layout revisions, settled native dispositions, actual live block set and carried unused grants. | G coordinates participant exclusion; H seals/adopts accounting metadata. Stable pinned lists and borrower exclusion precede traversal. Rechecking a revision after reading freed memory is insufficient. |
| SCR06 | SegmentLayout and IntervalGrant: SectionId/reuse, active half, typed segments, bounds/alignment/guards, writer, readers, grant revision and resume binding. | VM retains the physical section. H owns disjoint writable interval rights; G publishes context resume authority only after actual placement/setup. T releases old trace work separately. Worker lifetime is not section lifetime. |

### Credit consumption is not public-list publication

![Construction lifecycle](still-construction-lifecycle.svg)
[D2 source](still-construction-lifecycle.d2).

| ID | Ordered operation | Failure / custody rule |
| --- | --- | --- |
| SCO01 | Acquire activated grant and construction/input/root/VM leases; H claims Reserved -> Claimed once. | After grant, authorized runtime disposal of unused demand can win first and refund. Observer cancellation alone cannot alter frozen batch demand/decision; its custodian resolves the grant. Once Claimed, cancellation only requests resolution, never refund/revocation of a live allocator permit. |
| SCO02 | Allocate native storage outside gates, using the already enrolled ConstructionRecord. | Qualified allocator phase cannot invoke Scheme GC/reentry that waits for this same construction cut. A known no-effect allocation failure permits UnusedRefunded. A missing/unknown return keeps Claimed, quota and dependencies held. |
| SCO03 | Report actual NativeBlockId/deallocator and logical charge to H; commit Claimed -> Consumed(AllocationId). | This is the credit consumption cut: actual **private** storage is tracked even before a scan list sees it. If reporting is interrupted, the enrolled operation owns the unknown effect; no speculative second allocation/free/refund is legal. |
| SCO04 | Establish the selected initialization profile outside gates. | Inputs are rooted/reloaded as required; body writes stay with one owner. No final safepoint acknowledgement while untracked/unsafe construction can be read. Physical storage remains actual charge even if semantic initialization fails. |
| SCO05 | Publish the safe root/list carrier via the target adapter; obtain actual publication disposition before allowing a GC acknowledgement. | Complete safe stores precede adapter publication through qualified synchronization. During H-accounted -> C-rooted -> G-epoch-visible gaps, the held construction cut pins storage/roots/VM; no collector may skip the gap. Partial membership is retained and resolved, not guessed absent. |
| SCO06 | Finish semantic initialization and publish the Scheme result with owner/consumer synchronization; relinquish construction rooting only after valid destination rooting/use. | ScanReady is not language-visible readiness. A successful return that drops refcount still owes actual result/root delivery. For unpublished failure, remove construction root only under admitted mutation/GC rules; a registered object remains actual charge until real reclamation. |
| SCO07 | Reclaim a private aborted block only after proving no list/root/effect/read borrower and known destructor disposition; or let admitted sweep reclaim an enrolled object. | Native free uses the original allocator/container. ActualFreeSettled removes actual charge exactly once. A consumed grant stays historically Consumed; reclamation never revives/refunds its unused credit. Unknown free/effect retains custody and blocks exact affected rebudget. |
| SCO08 | Release operation/result/constructor records only after all physical users and publication/resolution obligations settle. | Refcount zero and response delivery do not discharge these leases. Forced still cleanup must join this service's producer/constructor drain; it cannot traverse half-initialized FOREIGN fields or free an active constructor. |

This refines the previous coarse CommittedActual into private actual storage and
separate publication states. For the immutable original batch, grant disposition
is Reserved, Claimed, Consumed or UnusedRefunded; each original demand is in one
state. Current live occupancy is a different ledger and decreases on actual free.
A constructor error after SCO03 follows actual reclamation, never a second
unused-credit refund. An unsynchronized observer cannot infer disposition from
an unprotected record field.

### Two admitted initialization profiles

| ID | Profile | Safe-point and effect conditions |
| --- | --- | --- |
| SCI01 | PrivateAtomicInit | Keep the block unlinked/private until its full InitSpec is satisfied. A rooted, noncollecting construction phase must finish/publish or settle abort before its owner acknowledges a final GC cut. No managed callback, GC-dependent wait or raw pointer escape. This is not holding H while constructing. Existing alloc_scmobj's raw return ABI needs a compiler/caller completion endpoint or a qualified legacy C island retaining current participation. |
| SCI02 | ScanReadyConstruction | Before allowing GC, install valid actual header/length, safe traced fields and subtype metadata, valid effect state, strong construction root and input handles through SCO05. Later writes are admitted mutator operations outside moving scan; reload relocated inputs after GC and obey the selected collector's write protocol. Then finish semantic fields before SCO06. No general concurrent-mutator collector or guessed write barrier is introduced. |
| SCI03 | Subtype-specific safe defaults | Pair/vector traced slots need legal rooted/immediate values. Weak tables require meaningful NEXT/FLAGS/count/free/unused-slot state and exclusion from conflicting weak-list writers. Frames/continuations need their full structural descriptors. Pointer-free string/numeric data need not be zeroed just for GC scanning, but language readers must not see unfinished bytes [SC-S06/S07/S09]. |
| SCI04 | Foreign native ownership | The known raw pointer remains with its real source owner until an explicit constructor arm transfers native release responsibility. Publish a valid no-release state or fully initialized tags/function/pointer before cleanup can read it. No safepoint/cleanup during a partially armed write sequence. A later abort must settle the one armed release owner, including dependencies and thread affinity from the release study [SC-S08]. |

The two profiles are choices for the complete architecture, not a minimal patch
ceiling. A caller census must choose one or retain/reject its legacy profile.
Preserving an unqualified alloc_scmobj wrapper and independently scanning its
list would retain the original unsafe assumption. OCaml's distinction between
safe initialized allocation and low-level initialize-before-allocation is useful
precedent [SC-P03]; its barriers/tags are not Gambit contracts.

## 3. Consumption and Refund Across a GC Recount

![Cross-GC accounting](still-credit-recount.svg)
[D2 source](still-credit-recount.d2).

At an authoritative settled cut, in logical still words, let A be distinct known
allocated blocks, including private constructions, enrolled objects and detached
pending-free blocks; let R be Reserved grants without storage. Then:

```
still_charge = sum(words(a), a in A) + sum(demand(g), g in R)
```

These are disjoint actual-storage and unmaterialized-promise sets. Deferred actual
words are a subset of A, not a third addend after recount. Native bytes and
movable policy charge have separate ledgers. Claimed effects must settle to
known dispositions before this exact recount equation can authorize a new
budget. Unknown actual storage/free/publication prevents that affected exact
cut, rather than being silently set to zero. A conservative continuation bound
for unknown effects has not been designed.

R also includes held, prepared capacity grants that are charged but not yet
activated by G. A new selected batch contributes its demand through those exact
GrantIds once, not through both a scalar D and a second carried-grant term.
Existing carried grants and new selected demand are distinguished in the image.
The heap policy may prepare/adopt new grants only with actual capacity; G later
activates them with the matching outcome. If terminal preparation fails, their
runtime custodian retains or settles unused disposal under H; observer
cancellation cannot rewrite the historical selected decision.

| ID | Recount step / race | Required ordering and responsibility |
| --- | --- | --- |
| SCA01 | Acquire held RecountCut; close new independent claims/publications/mutations/donor handoffs for this cut. | Pin existing grants/constructors/shards and participating owners. Already enrolled constructors may complete their counted publication/abort before traversal freezes; admission closure cannot deny the very operation needed to settle. Do not hold H while waiting. |
| SCA02 | Settle in-flight allocation/free/list reports; acquire actual safepoint/root readiness. | PrivateAtomicInit finishes or aborts; ScanReadyConstruction supplies its actual rooted carrier. Claiming GC while an allocator waits on that same GC is disallowed by SCO02/SCI01. Unknown effects keep the cut held, with no finite progress claim. |
| SCA03 | Freeze traversed membership/writers and pin physical storage before traversal; run admitted GC child mutations and sweep under their exclusive ownership. | Do not copy mutable lists and hope revision validation fixes races. Sweep and deferred release report separate dispositions. A parked release task can remain known-live with valid pinned/rooted carriers and no unsafe writer; queuing cleanup is not actual free. Do not wait in GC for an owner callback that needs this GC to complete. |
| SCA04 | After relevant sweep/storage dispositions are known, build RecountImage outside H from actual surviving/private/detached blocks and Reserved GrantIds. | Include worker/retired-context shards once. Known held blocks of deferred callbacks stay in A across this GC; run them later with required servicing available. An already running opaque unknown free cannot use that classification. A payload and object block may have separate qualified frees: retain/account each resource until its own disposal, without scanning a freed header. |
| SCA05 | Prevalidate all shard/grant/disposition vectors outside H under exclusion; H checks the authoritative held-cut identity, aggregate heap revision and prepared-image handle, then adopts image/carry membership. | Use one prepared handle commit, not perobject/pergrant traversal or fallible allocation in H. Every admitted mutation updates the checked heap revision. The prevalidation remains valid only while its writers/admission stay excluded. New admissions wait for the matching reopen. |
| SCA06 | G receives the qualified H completion outside H, binds it to GC decision/resume obligations and publishes the matching public outcome. | Charge adoption alone cannot release mutators or complete GC. A lost delivery retains the image, grant authority and held VM cut; an idempotent resolver reads the same operation instead of recounting/refunding again. |
| SCA07 | Reserved refund races with the cut. | If refund wins before sealing, the image excludes that grant. If adoption wins, the same GrantId is carried and a later H refund removes it from the **current** ledger. Never subtract from a mint-epoch scalar or require credit to expire merely because GC advanced. |
| SCA08 | Consume races with the cut. | H serializes claim against seal. If already Claimed, SCA02 waits for actual disposition; if sealed first, claim waits. Consumed storage replaces the promise once, whether private or enrolled. One object cannot also remain in R. |
| SCA09 | Free/refcount/donor mutation races with recount. | Refcount mutation must obey the safepoint/atomic/root protocol; it does not remove A. Current increments/decrements are plain stores [SC-S02]; cross-owner access requires owner serialization or a qualified synchronized replacement and valid count domain. Actual free/list transfer is excluded or an admitted cut mutation. Donor splice must move one storage/accounting identity under the held cut [SC-S03/S11]. |

No perpetual per-object external hash log is prescribed. Per-grant and
in-flight construction metadata must survive unresolved users; settled compact
state can reside in an object/shard descriptor and retire when no borrower
needs it. A batched/deferred fast path requires a bounded exclusive shard quota
window and a closure rule for unused window balance. Existing deferred counters
are reusable evidence, not proof of that new window protocol. Charging every
small object through a global gate may erase the intended benefit; this is a
cost condition, not an accepted optimized implementation.

## 4. Worker Tail Is an Interval, Not a Free Section

![Tail handoff](worker-tail-interval.svg)
[D2 source](worker-tail-interval.d2).

end_heap_chunk writes a FORW-tagged chunk link even for an empty chunk;
prepare_heap_msection reserves two end markers. scan_complete_heap_chunk reads
headers until that tag; partial scans use actual scan/allocation cursors.
mark_array has target-word-width alignment/padding rules. Heap/stack sharing and
prepare_mem_pstate derive limits from processor section state [SC-S12/S13/S14].
These are actual layout dependencies that must be replaced or qualified.

Use checked **word offsets within one actual section**, not comparisons or
subtraction across unrelated native allocations. M=131072 and F=8193 plus
SUBTYPED_BODY are source constants. One active half is M/2 words, not M-2F
usable words. At final admitted phase/borrower drain, let its bounds be [h0,h1),
with h1=h0+M/2, and let p be the actual frozen next-free worker offset.

| ID | Proposed interval/layout obligation | Exact boundary |
| --- | --- | --- |
| STL01 | Validate h0 <= p <= h1 and all old chunk/forwarding/scan obligations. | [h0,p) is a retained VM-owned prefix with its existing typed layout, not a tail credit. StrongClosed alone does not settle weak/will/continuation/cleanup/prepare or physical queue/cursor users. |
| STL02 | Reserve closing metadata z_close, target object-start alignment modulus a/residue r, and end guards z_end. For x=p+z_close choose the least q>=x with q mod a=r; choose b<=h1-z_end using checked arithmetic. | Object start and body alignment are different; r accounts for header/body offset. Closing writes and [p,q) gap have explicit layout types. If the cursor already includes a closing marker, do not reserve/write it twice. If no qualified closure fits, tail contributes zero. Exact z_close/z_end come from a qualified target layout, not a guessed universal one-word marker. |
| STL03 | Grant [q,b) exclusively, including its own F-word overrun reserve; require b-q >= F+u_min and initial hp=q. | The checked-allocation trigger heap_limit <= b-F. u_min and alignment/padding/check frequency come from Gambit's actual generated allocation contract. A request exceeding this profile uses the admitted slow/still path; no arbitrary giant object fits by aggregate quota. |
| STL04 | SegmentLayout distinguishes copied GC chunks, closure/alignment gap, context object run, overrun reserve and end guards. | A FORW marker is not an ordinary object header. The next collector/root/occupancy adapter must enumerate valid segments/runs; it cannot linearly parse an arbitrary gap or stop at an old marker and omit later context objects. Filler encoding is an alternative only with its own parser proof. |
| STL05 | No overlap with context stacks, another buffer, old writer rights or guards. | A selected initial profile grants a whole eligible tail to one context. Multiple disjoint buffers require per-buffer guards/alignment and replacement of whole-msection ownership/sharing/statistics assumptions; they are not presumed safe or forbidden forever. |
| STL06 | ContextResumeBinding uses actual grant, hp, trigger, bound, owner, stack placement and layout revision. | Replace/qualify prepare_mem_pstate, next_msection fallback, shared stack/heap limit adjustment, words_prev_msections and occupancy reduction for migrated intervals. A raw PSTATE field copy cannot grant the remaining whole half [SC-S13/S14]. |
| STL07 | Physical and managed accounting stay distinct. | Count the SectionId once and live/allocated segments once, retaining old fromspace/users as required. Old factor-two movable occupancy is a policy view, not a second physical section. Neither free tail nor worker retirement releases the copied prefix. |

For a purely illustrative layout, take [h0,h1)=[0,65536), p=40000,
z_close=1, a=2, r=0 and z_end=2. Then q=40002, b=65534 and the raw
grant has 25532 words. **If** the target's F=8194 and its allocation profile is
qualified, at most 17338 words precede the F-word reserve, before any further
per-object padding. With p=63000 the corresponding raw grant is only 2532 words
and cannot provide that reserve. These are conditional arithmetic examples,
not source-selected marker constants, executed placements, memory savings or
native qualification. The realizable saving can be zero for every worker tail.

### Handoff and partial-failure custody

| ID | Handoff transition | Responsible owner if interrupted |
| --- | --- | --- |
| STH01 | Prepare layout/record/resume plan and pins outside gates; obtain final epoch and old physical-user drain. Freeze donor allocation under the held VM cut. | Before claim, donor/VM retains rights; plan failure permits abandoning known private metadata only. Keep other allocations/epochs from reusing the interval. |
| STH02 | H claims WorkerOwned -> TransferPending with exact interval/generation; donor loses allocation permission. | One heap-service transaction owns pending rights. The worker cannot resume old allocation because delivery times out. T drain and G admission receipts are acquired separately, never by nested locks. |
| STH03 | Perform qualified closure/guard/layout writes only in the proved unused suffix, outside gates, with exclusive pending rights. | Known partial writes may remain unused VM layout; resolve to a valid sealed representation before reuse. Unknown writes keep pending ownership, pins and exclusion. Never overwrite the retained prefix or restart a second writer. |
| STH04 | H commits actual IntervalGrant, immutable SegmentLayout and accounting revision. | Allocation rights now belong to the target/coordinator custodian; section ownership remains VM. Before G publishes resume, the held transaction protects this gap. Failure is not permission to return rights to the worker or free the section. |
| STH05 | G consumes matching H completion plus actual stack/resume setup, publishes owner binding and later the GC outcome. Context acquires it before allocating. | Missing setup/delivery retains grant and VM under the coordinator; no guessed safe denial/resume. No context writes before the matching binding. The new GC layout must be installed before a later epoch can scan newly allocated suffix objects. |
| STH06 | Settle actual context installers/old worker users; retire worker scratch only. On context close, drain writes/root references and release unused rights under the layout protocol. | After first context use, new objects become retained VM segments. Cancellation cannot return the entire original tail to another writer. Reclaim section only after all prefix/suffix/root/old-half/native users prove dead or moved. |

This H->G handoff is ordered multi-authority publication, not an imaginary atomic
transaction across two locks. The held VM cut and actual transaction ownership
span the gap. Any design that permits a new GC/resume in that gap needs a stronger
adapter proof and is outside this profile. A live native writer cannot be taken
over merely because an observer reports timeout. Progress under an indefinitely
lost worker, allocator or destructor remains unresolved.

## 5. Conditional Arguments and Counterexamples

These are handwritten implications under explicit premises, **not checked
proofs**, executed models, native failures or runtime receipts.

| ID | Conditional claim | Premises and argument |
| --- | --- | --- |
| SCP01 | No unused credit is consumed/refunded twice. | With trusted activation and H-serialized unique claim, SCO01--03/07 permit one terminal grant disposition. Free changes actual occupancy, not historical Consumed. SCA07/08 use the same GrantId after adoption. Lost replies add users, not transitions. Actual allocator/ABA/visibility qualification is still required. |
| SCP02 | Exact recount preserves outstanding promises and actual storage. | SCA01--05 exclude unsafe writers, settle Claimed effects, pin actual lists and partition A/R by identity. A known consume removes one R and adds its actual block; known free removes one A; unused refund removes one R. Adoption carries all other terms. Unknown invalidates this premise and holds the affected cut. |
| SCP03 | GC cannot inspect an unsafe construction. | Every caller is routed through SCI01 or SCI02 with SCO04/05 and complete safepoint coverage. The first cannot acknowledge while unsafe; the second publishes all scan-safe metadata/roots before acknowledgement. Thus a legal collector sees no private partial body and only safe enrolled fields. Header validity alone is not the premise. |
| SCP04 | Aborted construction preserves native release ownership. | SCO02/03 enroll effects; SCI04 gives one known arm owner; SCO07 requires actual borrower/destructor/free disposition. Dropping refcount or caller error never independently refunds/frees. This assumes complete native effect/affinity/provider descriptions and all-exit cleanup, still unqualified. |
| SCP05 | A granted tail cannot overlap another writer. | STL01--05 validate actual offsets, boundaries and disjointness; STH01/02 retire donor rights before exclusive closure writes; STH04/05 allow one target writer. The held cut bars competing grants/epochs. Therefore all writes stay within one exclusive interval, conditional on allocation-check/alignment/fudge qualification. |
| SCP06 | Handoff retains all live copied/new objects and next-GC reachability. | STL04/06/07 and STH03--06 preserve prefix and exact layout, publish new runs before resume/next epoch, retain SectionId and old readers, and never free storage on worker retirement. Complete scanner/statistics/slow-path adapter closure remains a necessary premise. |
| SCP07 | Publication gaps and failed observers do not lose custody. | Enrolled transactions and pins span native return->H, H->C->G construction and H->G resume gaps; no cancellation reclaims unknown effects. Actual active writers settle before takeover. Safety follows conditionally; finite retention, cancellation latency and recovery progress do not. |
| SCP08 | The architecture does not assign common modernization value exclusively to Zig. | Same InitSpec, cut/credit/layout/GC/FFI and retirement premises apply to C-full/C-ZT/Z-full [SC-P04--06]. Only bounded avoided support after C helper/generator reuse, minus Zig-specific obligations, can establish an increment. No such bound is established by source algebra. |

| ID | Logical counterexample under violated premise | Consequence |
| --- | --- | --- |
| SCX01 | A converter returns an error; wrapper refunds credit although the still block remains linked. | Real storage and charge diverge; subsequent sweep can subtract/reclaim again. |
| SCX02 | UDP returns a bytevector after decref; wrapper treats decref as native free. | Successful result becomes dangling. |
| SCX03 | Recount sums only still lists, omitting Reserved grants. | Promised capacity vanishes across GC and can be granted twice. |
| SCX04 | Recount adds a Consumed grant to its object's length. | The same storage is charged twice. |
| SCX05 | Carried grant refund writes its old epoch scalar. | Current image retains a ghost promise or old storage is corrupted. |
| SCX06 | Native allocation succeeds but report is lost; cancellation refunds and retries. | Both an orphaned block and duplicate use of capacity are possible. |
| SCX07 | Optimistic recount follows a list, validates revision after a concurrent free. | Validation cannot undo a use-after-free during traversal. |
| SCX08 | Header is valid; weak flags/slots still contain garbage when a worker scans. | Wrong weak policy, invalid references or stale scan-list mutation. |
| SCX09 | All-zero initialization is assumed safe for every subtype. | Weak/frame metadata or value tags can be invalid. |
| SCX10 | Foreign release function is visible before its pointer is initialized. | Forced cleanup can call native code with invalid data. |
| SCX11 | Private constructor acknowledges GC then writes an unrooted movable input. | Collector can relocate/free the input before the write. |
| SCX12 | Constructor waits for GC awaiting its no-GC acknowledgement, or GC waits for a deferred owner destructor that requests this GC. | Circular wait. Constructors need admitted no-GC phases; known-live parked tasks must retain storage/roots and run with required servicing, not force a guessed release. |
| SCX13 | Dropping refcount is treated as sufficient drain for force cleanup. | Active constructor/resolver still accesses freed storage. |
| SCX14 | Strong queue empty is treated as terminal tail availability. | Later weak/continuation work or a physical chunk reader still uses the range. |
| SCX15 | M-2F is assigned as usable payload in one M/2 active half. | Nominal policy capacity crosses actual storage bounds. |
| SCX16 | Two contexts receive the same tail; aggregate free words look sufficient. | Writable cursors overlap. |
| SCX17 | End marker/gap is passed to the old linear parser as an ordinary object. | Invalid header scan, or later suffix objects are omitted. |
| SCX18 | Old prepare_mem_pstate/stack sharing widens a new interval's limit. | Context may allocate into another grant or guard. |
| SCX19 | H commits a target grant; failed G delivery restores donor rights. | Two authoritative writers exist across the publication gap. |
| SCX20 | Worker scratch retirement frees its whole copied section. | VM live prefix/root references dangle. |
| SCX21 | Context has allocated suffix objects; cancellation recycles its original whole tail. | New live objects are overwritten. |
| SCX22 | Perrecipient occupancy counts the entire shared prefix again, or ignores deferred/private actual blocks. | Heap policy uses inflated or understated live demand. |

## 6. Replacement Sequence and Remaining Gates

1. Inventory actual still constructors and GC/resize/cleanup entrants, including
   generated code, permanent branches and external FFI users; bind InitSpec,
   root/reload, native effect and completion endpoints for each. Preserve selected
   existing C refcount/aligned-allocation/save-reload/transfer support as credit.
2. Introduce one language-neutral native heap authority for persistent shard,
   grant, actual block and layout identity. Route current allocation/free/list/
   donor/statistics paths to it; no second authoritative Zig mirror of PSTATE.
3. Replace raw still publication assumptions with constructor profiles and actual
   all-exit disposition. Route cleanup through constructor/effect/borrower drain;
   retire old list mutation only when no unregistered producer/scanner remains.
4. Replace processor-only recount with held-cut actual storage plus carried
   promises. Preserve correctly partitioned deferred batching or explicitly
   account its replacement cost. Retire old scalar authority only after all
   writers/readers and error refunds are migrated.
5. Separate worker chunk cursors from persistent section layout and context
   buffers. Replace/qualify scan parser, next-section/heap-stack sharing,
   allocation checks, prepare, occupancy and shrink before granting tails.
6. Bind actual resume/layout/credit outcomes to common GC/resize delivery; retain
   explicit unresolved failures. Independent worker admission requires this full
   closure, not merely a selected tail example or a Zig build.

The full caller/build/semantic domain, no-bypass root/scan/effect coverage,
native memory order, exact layout/check bound, all-exit native dispositions,
termination/recovery and equal-capability maintenance costs remain unresolved.
No worker profile is qualified, C path retired, runtime receipt issued or
positive total/Zig-only net benefit established. The matching matrix makes those
unclosed economic conditions explicit instead of inferring them from language
features.
