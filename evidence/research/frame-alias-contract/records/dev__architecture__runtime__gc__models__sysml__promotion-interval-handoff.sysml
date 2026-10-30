/* Modern C target schema: source anchors are evidence routes, not satisfied laws. */
package GambitPromotionIntervalHandoff {
 private import ScalarValues::*;
 part def RegionReceipt {
  attribute allocationId : Integer; attribute reuseGeneration : Integer;
  attribute lo : Integer; attribute hi : Integer; attribute capacity : Integer;
  attribute requested : Integer; attribute backingIssued : Boolean;
  attribute placementValidated : Boolean; attribute regionsDisjoint : Boolean;
  attribute sourceCutClosed : Boolean; attribute allowForwarding : Boolean;
 }
 requirement def RegionLaw { subject r : RegionReceipt;
  require constraint { r.lo>=0 and r.hi>=r.lo and r.capacity>=r.hi and r.requested>=0 and
   (not r.allowForwarding or (r.backingIssued and r.placementValidated and r.regionsDisjoint and
    r.sourceCutClosed and r.requested<=r.hi-r.lo)) }
 }
 part def TailReceipt {
  attribute expectedOwner : Integer; attribute committedOwner : Integer; attribute transferId : Integer;
  attribute prefixEnd : Integer; attribute allocationEnd : Integer; attribute physicalEnd : Integer;
  attribute epochMatched : Boolean; attribute prefixReady : Boolean; attribute scanDebtSettled : Boolean;
  attribute sourceFrozen : Boolean; attribute targetAccepted : Boolean; attribute commitKnown : Boolean;
  attribute workerMayAllocate : Boolean; attribute contextMayAllocate : Boolean;
 }
 requirement def TailLaw { subject r : TailReceipt;
  require constraint { r.prefixEnd>=0 and r.prefixEnd<=r.allocationEnd and r.allocationEnd<=r.physicalEnd and
   not (r.workerMayAllocate and r.contextMayAllocate) and
   (not r.contextMayAllocate or (r.epochMatched and r.prefixReady and r.scanDebtSettled and
    r.sourceFrozen and r.targetAccepted and r.commitKnown)) }
 }
 part def RetirementReceipt {
  attribute retired : Boolean; attribute livePins : Integer; attribute unparentedAdmissionClosed : Boolean;
  attribute queuedAndDequeuedCovered : Boolean; attribute unknownOutcome : Boolean;
  attribute resetRequested : Boolean; attribute payloadDead : Boolean; attribute regionOwnerLive : Boolean;
  attribute freeRegionRequested : Boolean;
 }
 requirement def RetirementLaw { subject r : RetirementReceipt;
  require constraint { r.livePins>=0 and r.queuedAndDequeuedCovered and
   (not r.resetRequested or (r.retired and r.unparentedAdmissionClosed and r.livePins==0 and not r.unknownOutcome)) and
   (not r.freeRegionRequested or (r.retired and r.livePins==0 and r.payloadDead and not r.regionOwnerLive and not r.unknownOutcome)) }
 }
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "IH-H"; attribute :>> kind = "interleaving";
 attribute :>> subjectPath = "models/gambit/promotion_interval_handoff.qnt"; attribute :>> subjectScope = "promotion_interval_handoff:19-named-histories;safe;seed=17;100x80";
 attribute :>> premise = "Finite one-region, two-pin ownership/reader kernel; interval, transfer and omission histories, not full source GC";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "IH-I"; attribute :>> kind = "induction";
 attribute :>> subjectPath = "models/gambit/lean/PromotionIntervalHandoff.lean"; attribute :>> subjectScope = "GambitSMP.PromotionIntervalHandoff:splitConserves;noCrossBoundary;sumDoesNotFitFragment;commitExclusive;ackDoesNotRestoreWorker;dequeuePreservesPin;noReadersNoTasks;handoffNoZeroGap;liveOwnerForbidsFree;reuseBound;peakReuse;lateRefundCannotBeatPre;peakBelowRequiresBoth";
 attribute :>> premise = "Conditional interval arithmetic, task pin custody and no-free predicates; full transitions, C pointer provenance and source census remain open";
 }
 part extents : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "IH-EXTENTS"; attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/gambit/lean/PromotionIntervalHandoff.lean"; attribute :>> subjectScope = "IH-EXTENTS:actual-source-refinement";
 attribute :>> premise = "All allocator-issued backing objects, offsets, permissions and actual partial-commit intervals; checked placement and disjoint roles, not sum-only or RSS promise";
 }
 part tail : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "IH-TAIL"; attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/gambit/lean/PromotionIntervalHandoff.lean"; attribute :>> subjectScope = "IH-TAIL:actual-source-refinement";
 attribute :>> premise = "Every prepare_mem_pstate, heap/stack growth/undo, setup/resize and next-GC consumer adopts prefix/frontier/fudge and idempotent ownership commit";
 }
 part readers : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "IH-READERS"; attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/gambit/lean/PromotionIntervalHandoff.lean"; attribute :>> subjectScope = "IH-READERS:actual-source-refinement";
 attribute :>> premise = "Local, queued and dequeued scans, forwarding/frame helpers, roots/FFI, resize/free/cleanup and diagnostics acquire-before-exposure and last-use pins or reject unknown consumers";
 }
 part memory : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "IH-MEMORY"; attribute :>> kind = "native-memory-order";
 attribute :>> subjectPath = "vendor/gambit/lib/mem.c"; attribute :>> subjectScope = "IH-MEMORY:actual-source-refinement";
 attribute :>> premise = "Short lifecycle-lock acquisition protects descriptor+pin atomically; queue pin transfer, release/acquire, no lock inversion, provenance/size/WX and backing-platform admission remain open";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = extents; ref part :>> prerequisite = history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = extents; ref part :>> prerequisite = induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = extents; ref part :>> prerequisite = GambitRuntimeAssurance::work.source; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = extents; ref part :>> prerequisite = GambitPromotionResidual::induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = tail; ref part :>> prerequisite = history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = tail; ref part :>> prerequisite = induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = tail; ref part :>> prerequisite = extents; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = tail; ref part :>> prerequisite = GambitRuntimeAssurance::work.source; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = tail; ref part :>> prerequisite = GambitRuntimeAssurance::control.source; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = tail; ref part :>> prerequisite = GambitRcFreezePublication::publication; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = readers; ref part :>> prerequisite = history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = readers; ref part :>> prerequisite = induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = readers; ref part :>> prerequisite = GambitRcFreezePublication::census; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = readers; ref part :>> prerequisite = GambitRcFreezePublication::freeze; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = readers; ref part :>> prerequisite = GambitRetainedRcScan::lifetime; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = memory; ref part :>> prerequisite = history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = memory; ref part :>> prerequisite = induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = memory; ref part :>> prerequisite = GambitGenerationalBarrier::memoryOrder; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = GambitPromotionResidual::bound; ref part :>> prerequisite = extents; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = GambitPromotionResidual::bound; ref part :>> prerequisite = tail; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = GambitPromotionResidual::residual; ref part :>> prerequisite = readers; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = GambitPromotionResidual::residual; ref part :>> prerequisite = memory; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = GambitPromotionResidual::memory; ref part :>> prerequisite = memory; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = GambitPromotionResidual::ffi; ref part :>> prerequisite = readers; }
 part def CallerRow {
 attribute callerId : String;
 attribute sourceAnchors : String;
 attribute actualChain : String;
 attribute ownership : String;
 attribute failure : String;
 }
 part caller0 : CallerRow {
 attribute :>> callerId = "backing";
 attribute :>> sourceAnchors = "mem.c:540-598,891-1079;os_base.c:445-477";
 attribute :>> actualChain = "alloc_mem_aligned_aux -> alloc_mem_heap -> allocator/WX-profile path; adjust_msections publishes every successful section";
 attribute :>> ownership = "Actual storage object identity and aligned offsets; partial expansion retained and inspected";
 attribute :>> failure = "Sum-free or requested target count is not a placement certificate; no resident-memory guarantee";
 }
 part caller1 : CallerRow {
 attribute :>> callerId = "local-scan";
 attribute :>> sourceAnchors = "mem.c:3241-3305,4252-4382";
 attribute :>> actualChain = "end_heap_chunk -> scan_movable_objs_to_scan -> scan_complete_heap_chunk";
 attribute :>> ownership = "Queued/dequeued/local/private cursor retain exact descriptor and interval pins until final load/store";
 attribute :>> failure = "Queue-empty or returning a chunk link is not reader drain";
 }
 part caller2 : CallerRow {
 attribute :>> callerId = "steal";
 attribute :>> sourceAnchors = "mem.c:6692-6771";
 attribute :>> actualChain = "scan loop steals chunk under owner queue lock -> scans ptr+1 after unlock -> returns to local scan";
 attribute :>> ownership = "Transfer pin with the task before queue unlock; last-use release before idle decrement";
 attribute :>> failure = "Worker idle count cannot replace all task/root/native reader tokens";
 }
 part caller3 : CallerRow {
 attribute :>> callerId = "frame";
 attribute :>> sourceAnchors = "mem.c:3490-3811;gambit.h.in:9224-9226";
 attribute :>> actualChain = "mark_array initializer and mark_captured_continuation decode/copy using source and destination";
 attribute :>> ownership = "Initializer, frame descriptor, stack region and alias-rewrite footprint remain pinned";
 attribute :>> failure = "Forward address visible before readiness; FrameRef stack encodings need typed handling";
 }
 part caller4 : CallerRow {
 attribute :>> callerId = "restore";
 attribute :>> sourceAnchors = "mem.c:4525-4562,4717,7080,7215,7358,7402,7500";
 attribute :>> actualChain = "prepare_mem_pstate called by setup, GC return, stack overflow paths, stack undo and heap_limit";
 attribute :>> ownership = "Six call endpoints plus helper definition use committed context layout; no restoring stale PSTATE limits";
 attribute :>> failure = "Existing same-PSTATE tail reuse is credited; new cross-owner reuse is not a measured saving";
 }
 part caller5 : CallerRow {
 attribute :>> callerId = "resize";
 attribute :>> sourceAnchors = "setup.c:884-950;mem.c:6316-6468,7038-7049";
 attribute :>> actualChain = "resize VM -> optional GC -> cleanup departing processor; resize_heap -> adjust_msections contraction/expansion";
 attribute :>> ownership = "Source root/cursor/reader domains outlive thread exit; partial growth and unknown status stay ledger-owned";
 attribute :>> failure = "resize/fudge/restore branches cannot free a section still used by independent worker/context";
 }
 part caller6 : CallerRow {
 attribute :>> callerId = "root-ffi";
 attribute :>> sourceAnchors = "mem.c:703-829,3969-3986;c_intf.c:6511-6562;os_dyn.c:744-795";
 attribute :>> actualChain = "mark_rc reads cached next/data -> root rewrite; callback marker and dynamic closure reads";
 attribute :>> ownership = "Finite raw/descriptor borrow pins separate from durable RootRegistry membership";
 attribute :>> failure = "Do not wait for whole callback lifetime when callback awaits this GC; unknown aliases refuse cut";
 }
 part caller7 : CallerRow {
 attribute :>> callerId = "shutdown";
 attribute :>> sourceAnchors = "setup.c:4665-4673,4773-4780;mem.c:4928-4966";
 attribute :>> actualChain = "cleanup_pstate -> mem cleanup/RC release; cleanup_vmstate -> destroy sync -> free_msections";
 attribute :>> ownership = "Close ingress, settle tickets, drain real pins/debts and transfer retained roots before destroy/free";
 attribute :>> failure = "Current p0 TODO/assumptions are not evidence of a modern complete shutdown census";
 }
 part def BenefitRow {
 attribute capability : String;
 attribute removedWork : String;
 attribute bound : String;
 attribute addedCost : String;
 attribute condition : String;
 }
 part benefit0 : BenefitRow {
 attribute :>> capability = "placement";
 attribute :>> removedWork = "Eliminate retry after destructive forwarding due only to optimistic capacity counters";
 attribute :>> bound = "Validate every object/segment placement before forwarding; sum capacity alone is insufficient";
 attribute :>> addedCost = "Preflight extents/layout traversal plus interval/claim/partial-result records";
 attribute :>> condition = "Correctness benefit; no measured reduction of total allocation or pause";
 }
 part benefit1 : BenefitRow {
 attribute :>> capability = "tail reuse";
 attribute :>> removedWork = "Avoid fresh context reserve only when transferable suffix already covers an actual demand";
 attribute :>> bound = "0<=q_i<=min(usableTail_i,requestedResume_i), with alignment/contiguity; Q=sum(q_i)";
 attribute :>> addedCost = "Transferred tail still belongs to committed destination; protect fudge and prefix indexes";
 attribute :>> condition = "Savings are relative to a naive separated-worker/context design; current same-PSTATE restore already reuses tails";
 }
 part benefit2 : BenefitRow {
 attribute :>> capability = "peak";
 attribute :>> removedWork = "Subtract accepted reuse from additional fresh context storage, never from destination and resume twice";
 attribute :>> bound = "Peak=max(phase peaks); pre-copy subtract only preflight-guaranteed Qg, post-copy may also subtract opportunistic Qo; never count either twice";
 attribute :>> addedCost = "Allocator headers, alignment, claim/layout/task/pin records and two card banks remain charged";
 attribute :>> condition = "Post-copy refunds cannot lower an earlier peak; preflight Qg must exceed any extra destination/metadata/held-partial cost; RSS/OOM still needs platform evidence";
 }
 part benefit3 : BenefitRow {
 attribute :>> capability = "reader lifetime";
 attribute :>> removedWork = "Replace implicit phase/pstate lifetime assumptions with explicit last-use custody";
 attribute :>> bound = "One short lifecycle-lock acquire/release per finite borrow; task handoff preserves one token; nested calls counted";
 attribute :>> addedCost = "Pin records and lock/condvar contention; per-thread generation alone is insufficient";
 attribute :>> condition = "No unparented old reader after retire; derived child acquired before releasing parent; no forced timeout unpin";
 }
 part benefit4 : BenefitRow {
 attribute :>> capability = "bounded retention";
 attribute :>> removedWork = "Prevent silent accumulation of old banks and unresolved allocations";
 attribute :>> bound = "Two preallocated card banks; no third epoch-bank publication until the older bank drains";
 attribute :>> addedCost = "A stalled reader can block progress; finite held-partial budget and unresolved operation slots remain owned";
 attribute :>> condition = "Safety by backpressure/refusal/quarantine, not a liveness or crashed-thread recovery theorem";
 }
 part extentsRoute : GambitHostRootsRefinement::Route {
 ref part :>> need = extents;
 attribute :>> sourceAnchors = "mem.c:540-598,891-1079;os_base.c:445-477";
 attribute :>> patchAnchors = "Existing cumulative patch unchanged; no interval/pin runtime implementation";
 attribute :>> projection = "All allocator-issued backing objects, offsets, permissions and actual partial-commit intervals; checked placement and disjoint roles, not sum-only or RSS promise";
 attribute :>> failureCustodian = "Authoritative region/transfer/reader ledger; unknown outcomes retain storage and pins, never timeout refund";
 attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part tailRoute : GambitHostRootsRefinement::Route {
 ref part :>> need = tail;
 attribute :>> sourceAnchors = "mem.c:3490-3811;gambit.h.in:9224-9226; mem.c:4525-4562,4717,7080,7215,7358,7402,7500; setup.c:884-950;mem.c:6316-6468,7038-7049";
 attribute :>> patchAnchors = "Existing cumulative patch unchanged; no interval/pin runtime implementation";
 attribute :>> projection = "Every prepare_mem_pstate, heap/stack growth/undo, setup/resize and next-GC consumer adopts prefix/frontier/fudge and idempotent ownership commit";
 attribute :>> failureCustodian = "Authoritative region/transfer/reader ledger; unknown outcomes retain storage and pins, never timeout refund";
 attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part readersRoute : GambitHostRootsRefinement::Route {
 ref part :>> need = readers;
 attribute :>> sourceAnchors = "mem.c:3241-3305,4252-4382; mem.c:6692-6771; mem.c:3490-3811;gambit.h.in:9224-9226; mem.c:4525-4562,4717,7080,7215,7358,7402,7500; setup.c:884-950;mem.c:6316-6468,7038-7049; mem.c:703-829,3969-3986;c_intf.c:6511-6562;os_dyn.c:744-795; setup.c:4665-4673,4773-4780;mem.c:4928-4966";
 attribute :>> patchAnchors = "Existing cumulative patch unchanged; no interval/pin runtime implementation";
 attribute :>> projection = "Local, queued and dequeued scans, forwarding/frame helpers, roots/FFI, resize/free/cleanup and diagnostics acquire-before-exposure and last-use pins or reject unknown consumers";
 attribute :>> failureCustodian = "Authoritative region/transfer/reader ledger; unknown outcomes retain storage and pins, never timeout refund";
 attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part memoryRoute : GambitHostRootsRefinement::Route {
 ref part :>> need = memory;
 attribute :>> sourceAnchors = "mem.c:540-598,891-1079;os_base.c:445-477; mem.c:3241-3305,4252-4382; mem.c:6692-6771; setup.c:4665-4673,4773-4780;mem.c:4928-4966";
 attribute :>> patchAnchors = "Existing cumulative patch unchanged; no interval/pin runtime implementation";
 attribute :>> projection = "Short lifecycle-lock acquisition protects descriptor+pin atomically; queue pin transfer, release/acquire, no lock inversion, provenance/size/WX and backing-platform admission remain open";
 attribute :>> failureCustodian = "Authoritative region/transfer/reader ledger; unknown outcomes retain storage and pins, never timeout refund";
 attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part def ViewNode {
 attribute nodeId : String;
 attribute labelText : String;
 }
 part node0 : ViewNode {
 attribute :>> nodeId = "bound";
 attribute :>> labelText = "Closed layout demand";
 }
 part node1 : ViewNode {
 attribute :>> nodeId = "region";
 attribute :>> labelText = "Actual extent placement receipt";
 }
 part node2 : ViewNode {
 attribute :>> nodeId = "copy";
 attribute :>> labelText = "Copy prefix and settle scan debt";
 }
 part node3 : ViewNode {
 attribute :>> nodeId = "offer";
 attribute :>> labelText = "Freeze suffix and offer transfer";
 }
 part node4 : ViewNode {
 attribute :>> nodeId = "commit";
 attribute :>> labelText = "One authoritative ownership commit";
 }
 part node5 : ViewNode {
 attribute :>> nodeId = "context";
 attribute :>> labelText = "Context allocates committed suffix";
 }
 part node6 : ViewNode {
 attribute :>> nodeId = "pins";
 attribute :>> labelText = "Local, queued and dequeued reader pins";
 }
 part node7 : ViewNode {
 attribute :>> nodeId = "retire";
 attribute :>> labelText = "Retire old descriptor and close new readers";
 }
 part node8 : ViewNode {
 attribute :>> nodeId = "reset";
 attribute :>> labelText = "Drain tokens then recycle metadata";
 }
 part node9 : ViewNode {
 attribute :>> nodeId = "hold";
 attribute :>> labelText = "Retain custody and query unknown outcome";
 }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer = node0; ref part :>> consumer = node1; attribute :>> labelText = "place"; }
 part edge1 : ViewEdge { ref part :>> producer = node1; ref part :>> consumer = node2; attribute :>> labelText = "accepted"; }
 part edge2 : ViewEdge { ref part :>> producer = node1; ref part :>> consumer = node9; attribute :>> labelText = "partial/refused"; }
 part edge3 : ViewEdge { ref part :>> producer = node2; ref part :>> consumer = node3; attribute :>> labelText = "ready"; }
 part edge4 : ViewEdge { ref part :>> producer = node3; ref part :>> consumer = node4; attribute :>> labelText = "accepted"; }
 part edge5 : ViewEdge { ref part :>> producer = node4; ref part :>> consumer = node5; attribute :>> labelText = "read back"; }
 part edge6 : ViewEdge { ref part :>> producer = node4; ref part :>> consumer = node9; attribute :>> labelText = "unknown ack"; }
 part edge7 : ViewEdge { ref part :>> producer = node2; ref part :>> consumer = node6; attribute :>> labelText = "borrow"; }
 part edge8 : ViewEdge { ref part :>> producer = node6; ref part :>> consumer = node7; attribute :>> labelText = "close ingress"; }
 part edge9 : ViewEdge { ref part :>> producer = node7; ref part :>> consumer = node8; attribute :>> labelText = "zero readers"; }
}

