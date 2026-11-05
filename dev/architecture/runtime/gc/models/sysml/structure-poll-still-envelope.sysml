/* Mandatory modern C. Target admission requirements; no satisfied runtime instance. */
package GambitStructurePollStillEnvelope {
 private import ScalarValues::*;
 part def PollBudget { attribute knownCode : Boolean; attribute rootsCurrent : Boolean;
  attribute effectsBounded : Boolean; attribute exitsBounded : Boolean;
  attribute capturesBounded : Boolean; attribute receiptAllowed : Boolean;
 }
 requirement def PollLaw { subject p : PollBudget;
  require constraint { not p.receiptAllowed or (p.knownCode and p.rootsCurrent and
    p.effectsBounded and p.exitsBounded and p.capturesBounded) }
 }
 part def Constructor { attribute allocated : Boolean; attribute initialized : Boolean;
  attribute typeRooted : Boolean; attribute resultRooted : Boolean;
  attribute safePointAckAllowed : Boolean; attribute grantKnown : Boolean;
  attribute returnAllowed : Boolean;
 }
 requirement def ConstructorLaw { subject c : Constructor;
  require constraint { (not c.safePointAckAllowed or not c.allocated or c.initialized) and
   (not c.returnAllowed or (c.allocated and c.initialized and c.typeRooted and c.resultRooted and c.grantKnown)) }
 }
 part def PeakCut { attribute everyPhaseCovered : Boolean; attribute matchedBaseline : Boolean;
  attribute acquisitionOmitted : Boolean; attribute actualCustodyKnown : Boolean;
  attribute strictNetPerGlobalMaximum : Boolean; attribute strictGainClaimed : Boolean;
 }
 requirement def PeakLaw { subject p : PeakCut;
  require constraint { not p.strictGainClaimed or (p.everyPhaseCovered and p.matchedBaseline and
   p.acquisitionOmitted and p.actualCustodyKnown and p.strictNetPerGlobalMaximum) }
 }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SP-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/structure_poll_still_envelope.qnt";
 attribute :>> subjectScope="structure_poll_still_envelope:18-named-histories;safe;seed=17;100x80";
 attribute :>> premise="One constructor, a255 batch, abstract backing units and bounded effects; initialization, stale binding, unknown retention and historical peak; no source simulation";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SP-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StructurePollStillEnvelope.lean";
 attribute :>> subjectScope="GambitSMP.StructurePollStillEnvelope:recursiveStack;heapFrameExtent;recursiveHeapFrames;firstInternalFrameDefault;transferPostCheck;selectedTransfer;smallThreshold;stillCharge;stillRequestCap;deferredSplit;accountingSettlementIsNotFree;poolReturnKeepsBacking;netPhaseGain;allPhasePeak;unboundedHandler;unchangedDominant;lateFreeKeepsPeak";
 attribute :>> premise="Conditional source-layout arithmetic, list-of-phases maximum and independent physical/pending/pool ledger; not C steps or QNT induction";
 }
 part poll : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SP-POLL";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StructurePollStillEnvelope.lean";
 attribute :>> subjectScope="SP-POLL:actual-source-refinement";
 attribute :>> premise="RETI save -> stack_limit or GC -> interrupt handler -> internal return; caller/control roots, bounded effects/exits/captures or refuse finite-envelope receipt";
 }
 part frames : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SP-FRAMES";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StructurePollStillEnvelope.lean";
 attribute :>> subjectScope="SP-FRAMES:actual-source-refinement";
 attribute :>> premise="Real fs5 frame stride8/heap7; break/transfer post-check, moved/captured aliases and pool reuse versus new acquired backing; no sum-to-placement shortcut";
 }
 part still : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SP-STILL";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StructurePollStillEnvelope.lean";
 attribute :>> subjectScope="SP-STILL:actual-source-refinement";
 attribute :>> premise="a+6 still charge, deferred/VM/GC paths, actual allocator request and failure refund; initialize before safepoint acknowledgement and return-root publication";
 }
 part peak : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SP-PEAK";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StructurePollStillEnvelope.lean";
 attribute :>> subjectScope="SP-PEAK:actual-source-refinement";
 attribute :>> premise="Distinct acquired containers across poll/frame/GC/still/exception/unknown; Qg is role-compatible omitted acquisition, not pool return, still charge or late Qo";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=poll; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=poll; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=poll; ref part :>> prerequisite=GambitRuntimeAssurance::control.source; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=poll; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=poll; ref part :>> prerequisite=GambitRestGcResumeEnvelope::completion; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=frames; ref part :>> prerequisite=history; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=frames; ref part :>> prerequisite=induction; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=frames; ref part :>> prerequisite=poll; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=frames; ref part :>> prerequisite=GambitPromotionIntervalHandoff::extents; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=frames; ref part :>> prerequisite=GambitRuntimeAssurance::control.source; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=still; ref part :>> prerequisite=history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=still; ref part :>> prerequisite=induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=still; ref part :>> prerequisite=poll; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=still; ref part :>> prerequisite=frames; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=still; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=poll; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=frames; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=still; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=GambitRestGcResumeEnvelope::lifetime; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=GambitPromotionIntervalHandoff::readers; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitRestGcResumeEnvelope::resume; ref part :>> prerequisite=poll; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitRestGcResumeEnvelope::peak; ref part :>> prerequisite=peak; }
 part pollRoute : GambitHostRootsRefinement::Route { ref part :>> need=poll;
 attribute :>> sourceAnchors="lib/_kernel.scm:229-298,1285-1344,1448-1477;lib/_thread.scm:3232-3252;lib/_kernel.c:23950-23986,30605-30610;include/gambit.h.in:8510-8536,9262-9299";
 attribute :>> patchAnchors="Existing cumulative patch and vendor bytes unchanged; generated kernel source is not native profile evidence";
 attribute :>> projection="RETI save -> stack_limit or GC -> interrupt handler -> internal return; caller/control roots, bounded effects/exits/captures or refuse finite-envelope receipt";
 attribute :>> failureCustodian="Current root/initializer owner, epoch backing ledger and authoritative same-ID transfer; retain pending/allocated result and old readers on unknown, no replay/refund";
 attribute :>> status="source-chain-traced-bounded-effects-physical-layout-and-source-simulation-open";
 }
 part framesRoute : GambitHostRootsRefinement::Route { ref part :>> need=frames;
 attribute :>> sourceAnchors="lib/mem.c:3065-3235,3671-3811,6209-6255,7098-7408;lib/_kernel.c:23950-23986,30610;include/gambit.h.in:9219-9226";
 attribute :>> patchAnchors="Existing cumulative patch and vendor bytes unchanged; generated kernel source is not native profile evidence";
 attribute :>> projection="Real fs5 frame stride8/heap7; break/transfer post-check, moved/captured aliases and pool reuse versus new acquired backing; no sum-to-placement shortcut";
 attribute :>> failureCustodian="Current root/initializer owner, epoch backing ledger and authoritative same-ID transfer; retain pending/allocated result and old readers on unknown, no replay/refund";
 attribute :>> status="source-chain-traced-bounded-effects-physical-layout-and-source-simulation-open";
 }
 part stillRoute : GambitHostRootsRefinement::Route { ref part :>> need=still;
 attribute :>> sourceAnchors="lib/_kernel.scm:43-112;lib/_kernel.c:23856-23904;lib/mem.c:526-535,553-598,1457-1467,1556-1708,4387-4420,6357-6488;lib/os_base.c:190-226,445-505";
 attribute :>> patchAnchors="Existing cumulative patch and vendor bytes unchanged; generated kernel source is not native profile evidence";
 attribute :>> projection="a+6 still charge, deferred/VM/GC paths, actual allocator request and failure refund; initialize before safepoint acknowledgement and return-root publication";
 attribute :>> failureCustodian="Current root/initializer owner, epoch backing ledger and authoritative same-ID transfer; retain pending/allocated result and old readers on unknown, no replay/refund";
 attribute :>> status="source-chain-traced-bounded-effects-physical-layout-and-source-simulation-open";
 }
 part peakRoute : GambitHostRootsRefinement::Route { ref part :>> need=peak;
 attribute :>> sourceAnchors="lib/mem.c:891-1057,3065-3235,3388-3455,4387-4420,6316-6488,7041-7087,7098-7408;include/gambit.h.in:11279-11303";
 attribute :>> patchAnchors="Existing cumulative patch and vendor bytes unchanged; generated kernel source is not native profile evidence";
 attribute :>> projection="Distinct acquired containers across poll/frame/GC/still/exception/unknown; Qg is role-compatible omitted acquisition, not pool return, still charge or late Qo";
 attribute :>> failureCustodian="Current root/initializer owner, epoch backing ledger and authoritative same-ID transfer; retain pending/allocated result and old readers on unknown, no replay/refund";
 attribute :>> status="source-chain-traced-bounded-effects-physical-layout-and-source-simulation-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="poll-dispatch";
 attribute :>> sourceAnchors="_kernel.scm:229-298,1285-1344;gambit.h.in:9262-9299";
 attribute :>> actualChain="save GVM+RA -> stack_limit && GC -> interrupt-handler -> internal return";
 attribute :>> hazard="First POLL can service arbitrary Scheme callbacks; R0 heap0 does not cover handler";
 attribute :>> replacement="Effect/capture/exit budget plus fresh PointId/binding after every slow return";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="stack-section";
 attribute :>> sourceAnchors="mem.c:3065-3235,7098-7359";
 attribute :>> actualChain="local free-list reuse or VM unassigned msection or heap sharing; transfer frames";
 attribute :>> hazard="next_stack does not itself call malloc; five/100 checks occur after frame traversal";
 attribute :>> replacement="Backing identity versus assignment ledger; exact post-check transfer envelope";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="recursive-frame";
 attribute :>> sourceAnchors="_kernel.c:23958-23986,30610;mem.c:3671-3811";
 attribute :>> actualChain="RETN fs5 -> stack stride8; heap frame header+RA+fs=7";
 attribute :>> hazard="Captured frame copies/old stack can overlap; return does not force last-alias death";
 attribute :>> replacement="Typed FrameSpec coordinates, canonical frame identity and durable reader roots";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="still-allocator";
 attribute :>> sourceAnchors="_kernel.scm:43-112;mem.c:1556-1708";
 attribute :>> actualChain="words=a+6; deferred <=1024 or VM charge/GC; native malloc after charge";
 attribute :>> hazard="Successful accounting is not successful allocation or completed initialization";
 attribute :>> replacement="Separate reserved/charged/allocated/initialized/published/failed states";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="still-return-failure";
 attribute :>> sourceAnchors="_kernel.c:23856-23904;mem.c:1457-1467,4387-4420";
 attribute :>> actualChain="dec native ref -> initialize -> result; failure exception may return/retry";
 attribute :>> hazard="refcount0 is neither GC-ready uninitialized data nor immediate free";
 attribute :>> replacement="No new safepoint ack before InitSpec completion; rooted exact error/retry lineage";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="actual-release";
 attribute :>> sourceAnchors="mem.c:989,1065-1083,4387-4420,7371-7408;os_base.c:479-505";
 attribute :>> actualChain="stack undo -> pool; aligned free at resize/cleanup and dead still sweep";
 attribute :>> hazard="Stack pool return and VM-counter refund leave acquired bytes unchanged";
 attribute :>> replacement="Actual allocator-free receipt and last-alias/reader drain; preserve earlier peak";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="first POLL";
 attribute :>> removedWork="Expose hidden internal-return and arbitrary interrupt work";
 attribute :>> bound="Default GVM5,cfs0 gives stack12/heap11 internal frame; cfs8 gives stack20/heap19; no whole-call cap from a alone";
 attribute :>> addedCost="Bounded handler allocation, retained captures, nested/retry count and failure effects";
 attribute :>> condition="Refuse finite-peak receipt for unknown effects; do not disable interrupts or change Scheme semantics";
 }
 part cost1 : CostRow {
 attribute :>> capability="recursive stack and heap";
 attribute :>> removedWork="Replace padded-stack-as-heap assumption with exact frame descriptor";
 attribute :>> bound="r=a-1<=8191; stack8r<=65528 words; one canonical heap-frame cohort7r<=57337 words";
 attribute :>> addedCost="Break/internal frames, copied roots, duplicate live captured versions and task metadata";
 attribute :>> condition="Not a whole physical bound; every active version/cohort and transitive graph must be charged";
 }
 part cost2 : CostRow {
 attribute :>> capability="stack transfer";
 attribute :>> removedWork="Avoid pretending100 is an exact copy cap";
 attribute :>> bound="Before final frame words<100; transferred words<=99+maxFrame; threshold count<=5 source-premised";
 attribute :>> addedCost="First break4, extra break4, default internal frame12 and possible larger frames";
 attribute :>> condition="With one default cfs8 RETI and <=4 selected RETN frames, transfer<=52 plus first break4; reaching break may transfer none; other callers need actual descriptors";
 }
 part cost3 : CostRow {
 attribute :>> capability="still request";
 attribute :>> removedWork="Separate object charge from requested allocator container";
 attribute :>> bound="a>=255; charge a+6 words; normal WS8 pointer8 allocator request8a+63<=65599 bytes";
 attribute :>> addedCost="Deferred d, VM lock/GC, allocator overhead beyond request and retained failed paths";
 attribute :>> condition="Low-level-exec/custom allocator and actual generated profile remain unresolved; no RSS bound";
 }
 part cost4 : CostRow {
 attribute :>> capability="deferred vs VM";
 attribute :>> removedWork="Centralize ownership without treating counters as backing";
 attribute :>> bound="a+6+d<=1024 iff a+d<=1018; at d0 a<=1018 defers, a1019 requires VM path";
 attribute :>> addedCost="Known allocation failure refunds its exact charge; pending settlement is not free";
 attribute :>> condition="d belongs to all previous still allocations, not just structure; account before/after GC independently";
 }
 part cost5 : CostRow {
 attribute :>> capability="msection acquisition";
 attribute :>> removedWork="Reuse already-acquired sections before additional native backing";
 attribute :>> bound="Pool/VM assignment delta acquired bytes0; new section request=WS*ceil(sizeof_msection/WS)+alignment extra";
 attribute :>> addedCost="Directory replacement overlap, copy envelopes, guards and partial native acquisitions";
 attribute :>> condition="Conditional LP64 sizeof_msection_base32 gives1048615 requested bytes per section; not measured allocator usable bytes";
 }
 part cost6 : CostRow {
 attribute :>> capability="Qg whole peak";
 attribute :>> removedWork="Omit an actually unnecessary acquisition before peak overlap";
 attribute :>> bound="c_t<=b_t-q_t+o_t; strict gain requires every c_t<max(b); role-compatible demand only";
 attribute :>> addedCost="Exact container provenance, accepted transfer, effect budget and all held partials";
 attribute :>> condition="Heap/stack tail cannot pay separately allocated still block; unchanged still/error phase can erase whole-round gain";
 }
 part cost7 : CostRow {
 attribute :>> capability="release and Qo";
 attribute :>> removedWork="Reduce later occupancy only after real release";
 attribute :>> bound="Stack undo/pool return and pending-charge settlement delta acquired bytes0";
 attribute :>> addedCost="Last alias/captured-root/reader closure; actual shrink/free receipt";
 attribute :>> condition="Late free never lowers historical peak; existing same-PSTATE/free-list reuse is already in baseline";
 }
 part cost8 : CostRow {
 attribute :>> capability="failure and unknown";
 attribute :>> removedWork="Preserve initialization and roots rather than retrying unsafe ownership";
 attribute :>> bound="No collector admission with allocated/uninitialized body; unknown keeps pins and grants unavailable";
 attribute :>> addedCost="Bounded pending slots, fail-delivery/effect budget, same-ID query and quarantine";
 attribute :>> condition="Synchronous C allocator returns known status; unknown is proposed split-service protocol, not an invented malloc behavior";
 }
 part def ViewNode { attribute nodeId : String; attribute labelText : String; }
 part node0 : ViewNode { attribute :>> nodeId="poll"; attribute :>> labelText="First structure POLL: save internal return"; }
 part node1 : ViewNode { attribute :>> nodeId="stack"; attribute :>> labelText="Stack section assignment / pool / sharing"; }
 part node2 : ViewNode { attribute :>> nodeId="effects"; attribute :>> labelText="Interrupt effects + exits + captures"; }
 part node3 : ViewNode { attribute :>> nodeId="frames"; attribute :>> labelText="Recursive stack8 / heap frame7"; }
 part node4 : ViewNode { attribute :>> nodeId="gc"; attribute :>> labelText="GC backing + readers + copy work"; }
 part node5 : ViewNode { attribute :>> nodeId="still"; attribute :>> labelText="Still charge a+6; native allocation"; }
 part node6 : ViewNode { attribute :>> nodeId="init"; attribute :>> labelText="refcount dec -> initialize; no GC ack"; }
 part node7 : ViewNode { attribute :>> nodeId="return"; attribute :>> labelText="Rooted result; unwind recursive frames"; }
 part node8 : ViewNode { attribute :>> nodeId="pool"; attribute :>> labelText="Stack undo: pool reuse, not free"; }
 part node9 : ViewNode { attribute :>> nodeId="free"; attribute :>> labelText="Last alias + readers -> actual shrink/sweep free"; }
 part node10 : ViewNode { attribute :>> nodeId="hold"; attribute :>> labelText="Failure / unknown: durable custody"; }
 part node11 : ViewNode { attribute :>> nodeId="peak"; attribute :>> labelText="All actual backing phases; Qg omission vs late Qo"; }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="stack cause"; }
 part edge1 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node2; attribute :>> labelText="all slow returns"; }
 part edge2 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node4; attribute :>> labelText="GC requested"; }
 part edge3 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="bounded admitted continuation"; }
 part edge4 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="later POLL / frame copy"; }
 part edge5 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node3; attribute :>> labelText="fresh current binding"; }
 part edge6 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node5; attribute :>> labelText="base case n=a"; }
 part edge7 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node4; attribute :>> labelText="charge requests GC before allocation"; }
 part edge8 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="known successful pointer"; }
 part edge9 : ViewEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="complete initialization"; }
 part edge10 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node8; attribute :>> labelText="break undo"; }
 part edge11 : ViewEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="not enough without death/drain"; }
 part edge12 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node10; attribute :>> labelText="known failure / unknown service"; }
 part edge13 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node10; attribute :>> labelText="forwarded incomplete work"; }
 part edge14 : ViewEdge { ref part :>> producer=node10; ref part :>> consumer=node11; attribute :>> labelText="retained peak cost"; }
 part edge15 : ViewEdge { ref part :>> producer=node9; ref part :>> consumer=node11; attribute :>> labelText="late free retains history"; }
 part edge16 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node11; attribute :>> labelText="preaccepted omitted acquisition"; }
 part edge17 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node11; attribute :>> labelText="unknown budget forbids finite receipt"; }
}
