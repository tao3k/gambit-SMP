/* Mandatory modern C target. No satisfied runtime instance or native admission. */
package GambitStillInitSafepoint {
 private import ScalarValues::*;
 part def InitGate { attribute hasOwnedBody : Boolean; attribute fullyInitialized : Boolean;
  attribute rootsCurrent : Boolean; attribute resultRooted : Boolean; attribute exactRequest : Boolean;
  attribute unknownResult : Boolean; attribute generationalMode : Boolean;
  attribute rememberedCoverageReady : Boolean; attribute acknowledgementAllowed : Boolean;
 }
 requirement def InitGateLaw { subject g : InitGate;
  require constraint { not g.acknowledgementAllowed or (g.rootsCurrent and g.exactRequest and
   not g.unknownResult and (not g.hasOwnedBody or (g.fullyInitialized and g.resultRooted)) and
   (not g.generationalMode or g.rememberedCoverageReady)) }
 }
 part def ActivationCustody { attribute outerRootRetained : Boolean; attribute distinctTokens : Boolean;
  attribute ownOnlyCleanup : Boolean; attribute initializerRetained : Boolean;
  attribute unknownStorageCharged : Boolean; attribute boundaryAllowed : Boolean;
 }
 requirement def CustodyLaw { subject a : ActivationCustody;
  require constraint { not a.boundaryAllowed or (a.outerRootRetained and a.distinctTokens and
   a.ownOnlyCleanup and a.initializerRetained and a.unknownStorageCharged) }
 }
 part def ParticipationLease { attribute participating : Boolean; attribute executingGc : Boolean;
  attribute mutatorMayRun : Boolean; attribute rootSnapshotValid : Boolean;
  attribute requestEpoch : Integer; attribute acknowledgementEpoch : Integer;
  attribute ownerGeneration : Integer; attribute receiptGeneration : Integer;
 }
 requirement def ParticipationLaw { subject p : ParticipationLease;
  require constraint { p.requestEpoch>=0 and p.acknowledgementEpoch>=0 and
   p.acknowledgementEpoch<=p.requestEpoch and
   (not p.participating or (not p.mutatorMayRun and p.rootSnapshotValid and
    p.ownerGeneration==p.receiptGeneration)) and
   (not p.executingGc or (p.participating and p.acknowledgementEpoch==p.requestEpoch)) }
 }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SI-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_init_safepoint.qnt";
 attribute :>> subjectScope="still_init_safepoint:21-named-histories;safe;seed=17;100x80";
 attribute :>> premise="One initializer/two root activations; requested versus acknowledged GC, interrupt delivery, nested cleanup and unknown block8 custody; source and C memory model open";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SI-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillInitSafepoint.lean";
 attribute :>> subjectScope="GambitSMP.StillInitSafepoint:noUninitializedAck;noUnrootedAck;requestIsNotAck;freshRequestInvalidates;initializedPublication;childReleasePreservesParent;releasedChildAbsent;unknownCannotAck;unknownChargeRetained;accountingSettlementNotFree;sourceRefcountIsNotReadiness;boundedRootSlots;wholePeakNeedsAllPhases";
 attribute :>> premise="13 conditional gate/token/epoch/storage propositions; not complete QNT induction, native roots or C atomics";
 }
 part admission : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SI-GATE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillInitSafepoint.lean";
 attribute :>> subjectScope="SI-GATE:actual-source-refinement";
 attribute :>> premise="Alloc->link/header->decrement->initialize->publish; request/trip is not barrier participation; forbid acknowledgement/delivery/reentry with uninitialized owned body; match request and root epoch";
 }
 part custody : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="SI-CUSTODY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillInitSafepoint.lean";
 attribute :>> subjectScope="SI-CUSTODY:actual-source-refinement";
 attribute :>> premise="Outer type/result roots use distinct activation tokens; every callback/throw/unknown keeps exact initializer and full storage liability; fixed saved[3]/marker patch not nested-root proof";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitStructurePollStillEnvelope::poll; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitRuntimeAssurance::work.source; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=admission; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=GambitHostRootsRefinement::marker; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=GambitHostRootsRefinement::exitState; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=GambitHostRootsRefinement::rc; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=admission; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::peak; ref part :>> prerequisite=custody; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitGenerationalBarrier::writers; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitGenerationalBarrier::scanCut; }
 part admissionRoute : GambitHostRootsRefinement::Route { ref part :>> need=admission;
 attribute :>> sourceAnchors="lib/_kernel.scm:43-112,229-298,1426-1477,4950-4981;lib/mem.c:1487-1498,1556-1708,6526-6538,6858,7071;lib/setup.c:50-90,206-241,313-352,1012-1201;lib/os_setup.c:3037-3042";
 attribute :>> patchAnchors="Cumulative patch:524-548,753-768,2010-2029; patch recipe separate from base vendor bytes and qualified native build";
 attribute :>> projection="Alloc->link/header->decrement->initialize->publish; request/trip is not barrier participation; forbid acknowledgement/delivery/reentry with uninitialized owned body; match request and root epoch";
 attribute :>> failureCustodian="Generation-bound root activation and operation ledger own pointer/prefix/unknown bound; child cleanup cannot clear parent; no GC acknowledgement or new callback until safe";
 attribute :>> status="selected-callers-and-target-contract-known-complete-source-and-native-memory-refinement-open";
 }
 part custodyRoute : GambitHostRootsRefinement::Route { ref part :>> need=custody;
 attribute :>> sourceAnchors="include/gambit.h.in:8059-8086,11623;lib/c_intf.c:1683-1711,6511-6562;lib/setup.c:3275-3413;lib/mem.c:4387-4412;examples/tcltk/tcltk.scm:100-194,221-227;lib/_kernel.c:23856-23904";
 attribute :>> patchAnchors="Cumulative patch:524-548,753-768,2010-2029; patch recipe separate from base vendor bytes and qualified native build";
 attribute :>> projection="Outer type/result roots use distinct activation tokens; every callback/throw/unknown keeps exact initializer and full storage liability; fixed saved[3]/marker patch not nested-root proof";
 attribute :>> failureCustodian="Generation-bound root activation and operation ledger own pointer/prefix/unknown bound; child cleanup cannot clear parent; no GC acknowledgement or new callback until safe";
 attribute :>> status="selected-callers-and-target-contract-known-complete-source-and-native-memory-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="structure-init";
 attribute :>> sourceAnchors="_kernel.scm:43-112,4950-4981;_kernel.c:23856-23904";
 attribute :>> actualChain="GC_SAVE type -> still allocate -> native refcount dec -> restore type -> fill -> return";
 attribute :>> hazard="Linked/header-valid/refcount0 body is not yet scannable";
 attribute :>> replacement="Generation-bound InitSpec completion and published result root before yielding";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="sync-producer";
 attribute :>> sourceAnchors="setup.c:1140-1201,66-90";
 attribute :>> actualChain="GC call -> OP_GARBAGE_COLLECT -> raise INTR_SYNC_OP -> trip flag -> execute_sync_op_loop";
 attribute :>> hazard="Request and delivery flag are not a participant acknowledgement";
 attribute :>> replacement="Separate monotonic request identity, root freeze and actual barrier-entry receipt";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="sync-consumer";
 attribute :>> sourceAnchors="_kernel.scm:1426-1446;setup.c:1012-1129";
 attribute :>> actualChain="Saved RA/registers -> service_sync_op -> barrier -> GC pstate";
 attribute :>> hazard="Disable interrupts leaves sync-op enabled; no-GC comes from admitted C interval";
 attribute :>> replacement="Modern C safe-point gate cannot be replaced by interrupt masking";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="interrupt-delivery";
 attribute :>> sourceAnchors="setup.c:206-241;_kernel.scm:1448-1477;os_setup.c:3037-3042";
 attribute :>> actualChain="Record/trip -> lowest pending code -> Scheme handler; procedural callback for OTHER";
 attribute :>> hazard="Posting, clearing, servicing and Scheme callback are different transitions";
 attribute :>> replacement="Queue during init, deliver after complete roots; do not wait synchronously on own GC request";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="root-scratch";
 attribute :>> sourceAnchors="gambit.h.in:8059-8086,11623;mem.c:6526-6538,6858";
 attribute :>> actualChain="GC_SAVE1 stores saved[0]; mark_saved scans saved[3] per participant";
 attribute :>> hazard="Nested saves/clears can overwrite outer type; patch marker protection is not a stack";
 attribute :>> replacement="Token-owned root records and own-only unwind; complete replacement census before retiring scratch";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="callback-marker";
 attribute :>> sourceAnchors="c_intf.c:6511-6562;setup.c:3275-3413;gambit.h.in:SFUN macros";
 attribute :>> actualChain="SFUN marker allocation -> call/trampoline -> return/unwind -> marker invalidation";
 attribute :>> hazard="Before-marker GC and exceptional nonlocal exit have independent obligations";
 attribute :>> replacement="Reuse HR-MARKER/EXIT/RC/binding requirements; park roots and initializer or refuse unsafe entry";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="cleanup-reentry";
 attribute :>> sourceAnchors="mem.c:4387-4412;c_intf.c:1683-1711";
 attribute :>> actualChain="GC cleanup -> release_foreign -> native release_fn";
 attribute :>> hazard="Arbitrary hook exists; actual legal reentry into Scheme during GC is not established";
 attribute :>> replacement="Qualify/desugar deferred destructor handoff; no inference that Tcl deletion runs during this constructor";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="sibling-allocators";
 attribute :>> sourceAnchors="_kernel.scm:inline-allocation family;_num.scm:7941;_system.scm:1404;c_intf.c:4381-5653";
 attribute :>> actualChain="Vector/word/atomic constructors, bignum/weak helpers and native conversions also allocate";
 attribute :>> hazard="One structure audit does not prove all custom initializers, raw FFI hooks or blocked/native paths";
 attribute :>> replacement="Typed payload/effect classification and complete admitted-caller census; unqualified paths remain open";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="init completion gate";
 attribute :>> removedWork="Replace implicit cannot-GC-here reasoning with a checkable C/GC boundary";
 attribute :>> bound="Selected structure fills a words once; withholding ack adds no required second O(a) fill";
 attribute :>> addedCost="Init token, prefix/completion and request/owner generation metadata; mature-to-young remembered coverage before minor-GC admission";
 attribute :>> condition="No bounded pause follows from word count; native blocking/interposition hooks need effect contracts";
 }
 part cost1 : CostRow {
 attribute :>> capability="request vs acknowledgement";
 attribute :>> removedWork="Avoid treating trip/mask/pending bit as roots-ready";
 attribute :>> bound="Default path already posts VM-wide sync request and uses barrier; no new fanout saving";
 attribute :>> addedCost="Fresh request generation, root freeze and participant lifetime";
 attribute :>> condition="Do not re-enable a frozen context before completing or withdrawing its participation";
 }
 part cost2 : CostRow {
 attribute :>> capability="nested roots";
 attribute :>> removedWork="Eliminate unowned slot0 overwrite/clear hazards after complete migration";
 attribute :>> bound="Existing saved array is3 root words; target scan sum R_i over retained activation records";
 attribute :>> addedCost="O(K) root records and O(sum R_i) root scan; dual support during migration is extra work";
 attribute :>> condition="Only a full SAVE/RESTORE/marker/native caller census can retire fixed scratch scanning";
 }
 part cost3 : CostRow {
 attribute :>> capability="unknown allocation";
 attribute :>> removedWork="Keep an unobserved successful allocation and its roots accountable";
 attribute :>> bound="Held unknown charge >= full possible container request plus operation metadata";
 attribute :>> addedCost="Bounded pending slots, same-ID query, generation and initializer ownership";
 attribute :>> condition="No refund, replay, release or acknowledgement solely on timeout/cancel; liveness not proved";
 }
 part cost4 : CostRow {
 attribute :>> capability="callbacks and exceptions";
 attribute :>> removedWork="Prevent cycles: GC waits initializer while callback waits GC";
 attribute :>> bound="No callback inside selected unfinished C fill; after completion reuse normal semantics";
 attribute :>> addedCost="Own-token cleanup and retained exception/continuation roots; result-style service boundaries";
 attribute :>> condition="Unsafe hook either finishes, obtains an independently proved scan-safe representation, or is refused admission";
 }
 part cost5 : CostRow {
 attribute :>> capability="alternative scan-safe partials";
 attribute :>> removedWork="Permit later exploration of GC inside a constructor only with initialized valid slots";
 attribute :>> bound="Sentinel prefill costs a extra writes before final a writes; partial descriptors require separate proof";
 attribute :>> addedCost="Extra O(a) writes or field-validity metadata/scan logic";
 attribute :>> condition="Not needed for selected one-pass fill; not implemented or counted as a gain";
 }
 part cost6 : CostRow {
 attribute :>> capability="whole peak";
 attribute :>> removedWork="Make root/init/unknown retention explicit in phase maximum";
 attribute :>> bound="Actual existing still request8a+63 remains; root/ledger bytes added to every overlapping phase";
 attribute :>> addedCost="Root metadata, pending full storage and delayed reclamation";
 attribute :>> condition="Positive Qg still requires omitted actual acquisition > added costs at every dominant phase; no measured or unconditional gain";
 }
 part def ViewNode { attribute nodeId : String; attribute labelText : String; }
 part node0 : ViewNode { attribute :>> nodeId="roots"; attribute :>> labelText="Activation-owned type/result roots"; }
 part node1 : ViewNode { attribute :>> nodeId="alloc"; attribute :>> labelText="Known private allocation / linked still body"; }
 part node2 : ViewNode { attribute :>> nodeId="init"; attribute :>> labelText="Initializer owns prefix; no GC ack or callback"; }
 part node3 : ViewNode { attribute :>> nodeId="request"; attribute :>> labelText="GC request / trip / pending interrupt"; }
 part node4 : ViewNode { attribute :>> nodeId="publish"; attribute :>> labelText="Complete body + result roots + required remembered coverage"; }
 part node5 : ViewNode { attribute :>> nodeId="gc"; attribute :>> labelText="Fresh participant acknowledgement -> GC"; }
 part node6 : ViewNode { attribute :>> nodeId="callback"; attribute :>> labelText="Deliver handler / nested callback with child root token"; }
 part node7 : ViewNode { attribute :>> nodeId="exit"; attribute :>> labelText="Own-only cleanup; retain outer roots and captured state"; }
 part node8 : ViewNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown result: full storage + roots + same operation"; }
 part node9 : ViewNode { attribute :>> nodeId="peak"; attribute :>> labelText="All-phase backing, root and pending-record peak"; }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="root before allocation"; }
 part edge1 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="pointer is not initialization receipt"; }
 part edge2 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node4; attribute :>> labelText="finish original fill"; }
 part edge3 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node2; attribute :>> labelText="pending request does not force entry"; }
 part edge4 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="exact epoch + roots"; }
 part edge5 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node6; attribute :>> labelText="safe callback boundary"; }
 part edge6 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="after GC restore current roots"; }
 part edge7 : ViewEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="child cleanup only"; }
 part edge8 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node0; attribute :>> labelText="parent survives"; }
 part edge9 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node8; attribute :>> labelText="service result unknown"; }
 part edge10 : ViewEdge { ref part :>> producer=node8; ref part :>> consumer=node2; attribute :>> labelText="resolve same ID; initializer continues"; }
 part edge11 : ViewEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="charge whole possible block"; }
 part edge12 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node9; attribute :>> labelText="hold root/init metadata"; }
 part edge13 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node9; attribute :>> labelText="captured aliases delay free"; }
}
