/* Modern C target specification. No satisfied instance or native admission. */
package GambitStillInitRecovery {
 private import ScalarValues::*;
 part def ProgressRecord { attribute committed : Integer; attribute physical : Integer;
  attribute writerIdle : Boolean; attribute inputStable : Boolean; attribute frozen : Boolean;
  attribute soleOwner : Boolean; attribute rootsRetained : Boolean; attribute transferAllowed : Boolean;
 }
 requirement def ProgressLaw { subject p : ProgressRecord;
  require constraint { p.committed>=0 and p.physical>=p.committed and
   (not p.writerIdle or p.physical==p.committed) and
   (not p.transferAllowed or (p.writerIdle and p.frozen and p.soleOwner and
    p.inputStable and p.rootsRetained)) }
 }
 part def ResultTransfer { attribute bodyComplete : Boolean; attribute serviceRoot : Boolean;
  attribute recipientRoot : Boolean; attribute receiptCommitted : Boolean; attribute exactIdentity : Boolean;
  attribute acceptanceCount : Integer; attribute sourceRelease : Boolean;
 }
 requirement def ResultLaw { subject t : ResultTransfer;
  require constraint { t.acceptanceCount>=0 and t.acceptanceCount<=1 and
   (not t.receiptCommitted or (t.bodyComplete and t.recipientRoot and t.exactIdentity and t.acceptanceCount==1)) and
   (not t.sourceRelease or (t.receiptCommitted and t.recipientRoot)) }
 }
 part def UnknownCustody { attribute unresolved : Boolean; attribute possibleBackingCharged : Boolean;
  attribute originalOperationRetained : Boolean; attribute initializationAuthorityRetained : Boolean;
  attribute mayReplay : Boolean; attribute mayRefund : Boolean;
 }
 requirement def UnknownLaw { subject u : UnknownCustody;
  require constraint { not u.unresolved or (u.possibleBackingCharged and
   u.originalOperationRetained and u.initializationAuthorityRetained and not u.mayReplay and not u.mayRefund) }
 }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IR-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_init_recovery.qnt";
 attribute :>> subjectScope="still_init_recovery:31-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One operation, three fields, two initializer owners and one receiver slot; in-flight write, partial and complete lost replies; no native progress or liveness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IR-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillInitRecovery.lean";
 attribute :>> subjectScope="GambitSMP.StillInitRecovery:stepPreserves;tracePreserves;progressNeverRewinds;boundaryCursorExact;uncommittedWriteNotTransferable;uniqueInitializer;revokedGenerationRejected;readbackPreservesProgress;admissionPreserves;admissionIdempotent;admissionAtMostOnce;acceptedHasReceiverRoot;overlapHandoff;senderReleaseRequiresReceiver;metadataRefundDoesNotFree;replayAvoidance";
 attribute :>> premise="16 exact conditional statements, including progress-kernel step/trace preservation and result-admission idempotence; not complete QNT induction or C refinement";
 }
 part progress : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IR-PROGRESS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillInitRecovery.lean";
 attribute :>> subjectScope="IR-PROGRESS:actual-source-refinement";
 attribute :>> premise="Actual byte/field/decoder cursor, immutable input, busy write and generation-bound frozen handoff; unknown acknowledgement cannot create a second initializer";
 }
 part roots : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IR-ROOT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillInitRecovery.lean";
 attribute :>> subjectScope="IR-ROOT:actual-source-refinement";
 attribute :>> premise="Complete body and result root publication; updateable input/result roots and remembered coverage; target enrollment before sender retirement, with reader drain";
 }
 part delivery : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IR-DELIVERY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillInitRecovery.lean";
 attribute :>> subjectScope="IR-DELIVERY:actual-source-refinement";
 attribute :>> premise="Atomic recipient root installation plus same-operation acceptance receipt; no duplicate OS read, initializer or continuation delivery; multi-shot calls use distinct activation identity; ingress fence before receipt retirement";
 }
 part abort : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IR-ABORT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillInitRecovery.lean";
 attribute :>> subjectScope="IR-ABORT:actual-source-refinement";
 attribute :>> premise="Typed pointer versus atomic payload, stopped writer, cancellation arbitration and full unknown backing; no unproved unlink, timeout refund or external-effect exactly-once claim";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=GambitStillInitSafepoint::admission; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=history; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=induction; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=progress; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=GambitHostRootsRefinement::rc; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=GambitHostRootsRefinement::marker; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=GambitGenerationalBarrier::writers; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=roots; ref part :>> prerequisite=GambitGenerationalBarrier::scanCut; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=delivery; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=delivery; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=delivery; ref part :>> prerequisite=roots; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=delivery; ref part :>> prerequisite=GambitHostRootsRefinement::exitState; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=delivery; ref part :>> prerequisite=GambitRuntimeAssurance::control.source; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=abort; ref part :>> prerequisite=history; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=abort; ref part :>> prerequisite=induction; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=abort; ref part :>> prerequisite=roots; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=abort; ref part :>> prerequisite=GambitRetainedRcScan::lifetime; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=abort; ref part :>> prerequisite=GambitRuntimeAssurance::release.source; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=progress; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=roots; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::still; ref part :>> prerequisite=delivery; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStructurePollStillEnvelope::peak; ref part :>> prerequisite=abort; }
 part progressRoute : GambitHostRootsRefinement::Route { ref part :>> need=progress;
 attribute :>> sourceAnchors="lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/mem.c:1487-1498,1677-1708,1730-1818,4016-4040,4170-4180;lib/c_intf.c:4335-4346,5413-5500,5678-5689,5732-5803;lib/os_io.c:11412-11428;lib/os_base.c:1735-1747;include/gambit.h.in:10033-10066,10269-10272";
 attribute :>> patchAnchors="No new runtime patch; predecessor marker/root recipe is not partial-initializer or result-receipt implementation";
 attribute :>> projection="Actual byte/field/decoder cursor, immutable input, busy write and generation-bound frozen handoff; unknown acknowledgement cannot create a second initializer";
 attribute :>> failureCustodian="Original operation record and unique generation-bound initializer; recipient slot takes result root only with atomic acceptance receipt; unresolved outcomes retain full backing and roots";
 attribute :>> status="selected-source-endpoints-known-native-refinement-open";
 }
 part rootsRoute : GambitHostRootsRefinement::Route { ref part :>> need=roots;
 attribute :>> sourceAnchors="lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/mem.c:1487-1498,1677-1708,1730-1818,4016-4040,4170-4180;lib/c_intf.c:4335-4346,5413-5500,5678-5689,5732-5803;lib/os_io.c:11412-11428;lib/os_base.c:1735-1747;include/gambit.h.in:10033-10066,10269-10272";
 attribute :>> patchAnchors="No new runtime patch; predecessor marker/root recipe is not partial-initializer or result-receipt implementation";
 attribute :>> projection="Complete body and result root publication; updateable input/result roots and remembered coverage; target enrollment before sender retirement, with reader drain";
 attribute :>> failureCustodian="Original operation record and unique generation-bound initializer; recipient slot takes result root only with atomic acceptance receipt; unresolved outcomes retain full backing and roots";
 attribute :>> status="selected-source-endpoints-known-native-refinement-open";
 }
 part deliveryRoute : GambitHostRootsRefinement::Route { ref part :>> need=delivery;
 attribute :>> sourceAnchors="lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/mem.c:1487-1498,1677-1708,1730-1818,4016-4040,4170-4180;lib/c_intf.c:4335-4346,5413-5500,5678-5689,5732-5803;lib/os_io.c:11412-11428;lib/os_base.c:1735-1747;include/gambit.h.in:10033-10066,10269-10272";
 attribute :>> patchAnchors="No new runtime patch; predecessor marker/root recipe is not partial-initializer or result-receipt implementation";
 attribute :>> projection="Atomic recipient root installation plus same-operation acceptance receipt; no duplicate OS read, initializer or continuation delivery; multi-shot calls use distinct activation identity; ingress fence before receipt retirement";
 attribute :>> failureCustodian="Original operation record and unique generation-bound initializer; recipient slot takes result root only with atomic acceptance receipt; unresolved outcomes retain full backing and roots";
 attribute :>> status="selected-source-endpoints-known-native-refinement-open";
 }
 part abortRoute : GambitHostRootsRefinement::Route { ref part :>> need=abort;
 attribute :>> sourceAnchors="lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/mem.c:1487-1498,1677-1708,1730-1818,4016-4040,4170-4180;lib/c_intf.c:4335-4346,5413-5500,5678-5689,5732-5803;lib/os_io.c:11412-11428;lib/os_base.c:1735-1747;include/gambit.h.in:10033-10066,10269-10272";
 attribute :>> patchAnchors="No new runtime patch; predecessor marker/root recipe is not partial-initializer or result-receipt implementation";
 attribute :>> projection="Typed pointer versus atomic payload, stopped writer, cancellation arbitration and full unknown backing; no unproved unlink, timeout refund or external-effect exactly-once claim";
 attribute :>> failureCustodian="Original operation record and unique generation-bound initializer; recipient slot takes result root only with atomic acceptance receipt; unresolved outcomes retain full backing and roots";
 attribute :>> status="selected-source-endpoints-known-native-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="structure";
 attribute :>> sourceAnchors="_kernel.scm:43-112;_kernel.c:23864-23904";
 attribute :>> actualChain="Allocate/link/refcount decrement -> fill -> RESULT/R3 -> R1/return";
 attribute :>> hazard="Current uninterrupted C path has no lost reply or progress journal";
 attribute :>> replacement="Preserve one-pass default; typed progress cuts only when service migration requires them";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="native-vector";
 attribute :>> sourceAnchors="mem.c:1743-1818";
 attribute :>> actualChain="make_pair/make_vector allocate -> write fields -> return refcount1";
 attribute :>> hazard="Inputs explicitly must not be movable; reference count is not field validity";
 attribute :>> replacement="Exact input leases and separate ready/result-root endpoint; do not silently broaden raw FFI contract";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="utf8-converter";
 attribute :>> sourceAnchors="c_intf.c:5413-5500,5678-5689";
 attribute :>> actualChain="Count UTF8 source -> allocate -> decode/write -> *obj/status; error releases partial result";
 attribute :>> hazard="Field index alone cannot restore decoder/source cursor; input can outlive native borrow";
 attribute :>> replacement="Stable byte image or explicit source lease; index+byte offset/decoder state; atomic payload failure separate";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="string-list";
 attribute :>> sourceAnchors="c_intf.c:5732-5803";
 attribute :>> actualChain="Convert str -> make_pair(str,lst) -> release str/lst -> next item -> *obj";
 attribute :>> hazard="Partial list, pending child and pair allocation span multiple ownership transfers";
 attribute :>> replacement="Parent/child operation identity and root receipts; body-only model does not prove whole list";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="directory";
 attribute :>> sourceAnchors="os_io.c:11412-11428";
 attribute :>> actualChain="device_directory_read -> borrowed name -> STRING_to_SCMOBJ -> release/return";
 attribute :>> hazard="Retrying wrapper repeats effectful directory advancement; backing name lease is not proven";
 attribute :>> replacement="Identity begins before I/O; completed constructor query never reruns directory read; caller/effect closure open";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="error-text";
 attribute :>> sourceAnchors="os_base.c:1735-1747";
 attribute :>> actualChain="Stack/native error buffer -> NONNULLSTRING_to_SCMOBJ -> release -> return";
 attribute :>> hazard="Async continuation cannot retain a dead stack buffer or rootless return value";
 attribute :>> replacement="Copy/pin source before yielding; retain result root through caller acceptance";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="sfun";
 attribute :>> sourceAnchors="gambit.h.in:10033-10066,10269-10272;setup.c:3275-3413";
 attribute :>> actualChain="Generated conversion scope -> Scheme call/result -> release/invalidate/propagate";
 attribute :>> hazard="Nested escape, raw output pointer and continuation reentry are not transactional delivery";
 attribute :>> replacement="Activation-specific recipient slot and own cleanup; no suppression of intentional multi-shot Scheme invocation";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="collector";
 attribute :>> sourceAnchors="mem.c:4016-4040,4170-4180,4222-4245";
 attribute :>> actualChain="Atomic payload skips body tracing; ordinary still pointer object scans all fields";
 attribute :>> hazard="Atomic string error cleanup cannot justify partial pointer-object admission";
 attribute :>> replacement="Typed abort, root drain and same GC gate; unresolved partial pointer body still blocks participation";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="normal initialization";
 attribute :>> removedWork="No mandatory fill/allocation removed versus current synchronous C";
 attribute :>> bound="a payload writes remain; no required sentinel pass";
 attribute :>> addedCost="Progress record and optional checkpoint ceil(a/q) publications";
 attribute :>> condition="q is an admitted nonreentrant batch; per-field publication is not required by default";
 }
 part cost1 : CostRow {
 attribute :>> capability="partial resume";
 attribute :>> removedWork="Never rewrite committed prefix or replay an ambiguous in-flight batch";
 attribute :>> bound="After known prefix p, remaining writes a-p; unsafe retry is not a legitimate performance baseline";
 attribute :>> addedCost="Freeze/owner-generation handoff and complete cursor/input/root snapshot";
 attribute :>> condition="In-flight or dead-owner ambiguity retains responsibility; no takeover from stale progress";
 }
 part cost2 : CostRow {
 attribute :>> capability="input stability";
 attribute :>> removedWork="Share one qualified input image across readback/resume";
 attribute :>> bound="Zero byte-copy only with proven borrow; otherwise E input bytes plus copy/scan work";
 attribute :>> addedCost="Input pin or immutable snapshot and lifetime/identity metadata";
 attribute :>> condition="A UTF8 field count does not reconstruct input byte position or guarantee immutable native storage";
 }
 part cost3 : CostRow {
 attribute :>> capability="result handoff";
 attribute :>> removedWork="Reuse the same completed object, not reconstruct it on lost response";
 attribute :>> bound="One accepted recipient slot per operation; overlapping roots refer to one backing object";
 attribute :>> addedCost="Source/recipient root overlap plus atomic acceptance receipt";
 attribute :>> condition="No extra object copy needed; direct C already returns one object, so no automatic net saving";
 }
 part cost4 : CostRow {
 attribute :>> capability="effectful callers";
 attribute :>> removedWork="Do not repeat directory advancement or invoke Scheme merely to query a result";
 attribute :>> bound="Readback performs zero initializer writes and zero delivery/OS effects";
 attribute :>> addedCost="Operation identity before effect; recipient activation identity and effect ledger";
 attribute :>> condition="Exactly-once external callbacks/crash recovery not established; unmediated raw consumers refused";
 }
 part cost5 : CostRow {
 attribute :>> capability="unknown retention";
 attribute :>> removedWork="Same-ID queries do not allocate another result";
 attribute :>> bound="One possible block B retained, not k blocks for k queries";
 attribute :>> addedCost="Outstanding records, full B, input image E and root scan sum R_i";
 attribute :>> condition="No timeout reclamation; permanently unknown owner may prevent GC progress";
 }
 part cost6 : CostRow {
 attribute :>> capability="receipt retirement";
 attribute :>> removedWork="Prevent stale retry/ABA from reinstalling retired result";
 attribute :>> bound="O(L+T) records for live operations L and retained dedup entries T";
 attribute :>> addedCost="Ingress fence, retry/reader drain and generation nonreuse";
 attribute :>> condition="No native bound on L or T and no timeout-only tombstone expiry";
 }
 part cost7 : CostRow {
 attribute :>> capability="whole-round peak";
 attribute :>> removedWork="Eliminate only actual duplicate backing introduced by an otherwise necessary service design";
 attribute :>> bound="Current selected still request8a+63 remains; saved payload allocation count0";
 attribute :>> addedCost="B+E+root/init/receipt bytes across all overlapping phases";
 attribute :>> condition="Qg lowers max only if actual omitted acquisition exceeds added costs at every dominant phase; no native peak saving measured";
 }
 part def ViewNode { attribute nodeId : String; attribute labelText : String; }
 part node0 : ViewNode { attribute :>> nodeId="input"; attribute :>> labelText="Stable input + activation roots + operation identity"; }
 part node1 : ViewNode { attribute :>> nodeId="write"; attribute :>> labelText="Sole initializer; reserved write may be in flight"; }
 part node2 : ViewNode { attribute :>> nodeId="cut"; attribute :>> labelText="Committed cursor; writer idle; exact physical prefix"; }
 part node3 : ViewNode { attribute :>> nodeId="freeze"; attribute :>> labelText="Frozen owner transfer; authoritative generation commit"; }
 part node4 : ViewNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown: query same operation; no replay/refund"; }
 part node5 : ViewNode { attribute :>> nodeId="complete"; attribute :>> labelText="Body complete + service result root + remembered coverage"; }
 part node6 : ViewNode { attribute :>> nodeId="offer"; attribute :>> labelText="Offer result to exact recipient activation"; }
 part node7 : ViewNode { attribute :>> nodeId="admit"; attribute :>> labelText="Atomic receiver root + acceptance receipt; duplicate is read-only"; }
 part node8 : ViewNode { attribute :>> nodeId="cleanup"; attribute :>> labelText="Retire sender roots after receipt and reader drain"; }
 part node9 : ViewNode { attribute :>> nodeId="peak"; attribute :>> labelText="Full backing + input + root/init/receipt phase peak"; }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="allocate once"; }
 part edge1 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="publish progress only after writes"; }
 part edge2 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node1; attribute :>> labelText="resume remaining suffix"; }
 part edge3 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="freeze at idle cut"; }
 part edge4 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node1; attribute :>> labelText="new generation; old owner revoked"; }
 part edge5 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node4; attribute :>> labelText="lost reply; original owner may continue"; }
 part edge6 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node4; attribute :>> labelText="complete but response unknown"; }
 part edge7 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node2; attribute :>> labelText="authoritative idle readback"; }
 part edge8 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="validate completed/rooted identity"; }
 part edge9 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node5; attribute :>> labelText="all fields done; publish result root"; }
 part edge10 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="no reconstruction"; }
 part edge11 : ViewEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="linearized accept or reject"; }
 part edge12 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node8; attribute :>> labelText="query receipt, then release"; }
 part edge13 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node7; attribute :>> labelText="same identity returns prior receipt"; }
 part edge14 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node9; attribute :>> labelText="retain full possible block"; }
 part edge15 : ViewEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="receipt retirement adds lifetime"; }
 part edge16 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node9; attribute :>> labelText="input lease/snapshot bytes"; }
}
