/* Modern C design-only extension. Imported needs remain unqualified. */
package GambitStillReceiptAdmission {
 private import ScalarValues::*;
 part def SettlementState { attribute creditAllowed : Boolean; attribute outcomeKnown : Boolean; attribute backendSuccessOrNoBlock : Boolean; attribute exactGeneration : Boolean; attribute fresh : Boolean; attribute gateHeld : Boolean; }
 requirement def CreditLaw { subject r : SettlementState; require constraint { not r.creditAllowed or (r.outcomeKnown and r.backendSuccessOrNoBlock and r.exactGeneration and r.fresh and r.gateHeld) } }
 part def AdmissionState { attribute commitAllowed : Boolean; attribute gateHeld : Boolean; attribute tupleMatches : Boolean; attribute rootsClosed : Boolean; attribute producersClosed : Boolean; attribute mutationLeases : Integer; attribute nativeInFlight : Integer; }
 requirement def AdmissionLaw { subject g : AdmissionState; require constraint { not g.commitAllowed or (g.gateHeld and g.tupleMatches and g.rootsClosed and g.producersClosed and g.mutationLeases==0 and g.nativeInFlight==0) } }
 part def LiabilityState { attribute charged : Integer; attribute held : Integer; attribute grants : Integer; attribute uncertain : Integer; }
 requirement def LiabilityLaw { subject l : LiabilityState; require constraint { l.charged==l.held+l.grants+l.uncertain and l.held>=0 and l.grants>=0 and l.uncertain>=0 } }

 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_receipt_admission.qnt";
 attribute :>> subjectScope="still_receipt_admission:19-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One two-word allocation and release, separate raw effect, completion publication, settlement and delivery; gate and sweep exclusion; finite cooperative model, not native death recovery";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillReceiptAdmission.lean";
 attribute :>> subjectScope="GambitSMP.StillReceiptAdmission:stepConserves;traceConserves;refundBound;duplicateNoCredit;unknownNoCredit;failedReleaseNoCredit;staleGateRejected;busyGateRejected;releasedStillCharged;metadataPeak";
 attribute :>> premise="Conditional accounting Step/Trace induction and gate arithmetic; no C weak-memory refinement";
 }
 part issuance : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-ISSUE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillReceiptAdmission.lean";
 attribute :>> subjectScope="RA-ISSUE:actual-source-refinement";
 attribute :>> premise="Backend result captured before completion release publication; caller delivery is separate; raw effect before capture remains unqueryable without a qualified cooperative adapter";
 }
 part settlement : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-SETTLE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillReceiptAdmission.lean";
 attribute :>> subjectScope="RA-SETTLE:actual-source-refinement";
 attribute :>> premise="Exact operation/domain/block/grant generations and one gate jointly apply charge and consumed state; replay only queries completion; no duplicate free or credit";
 }
 part gate : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-GATE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillReceiptAdmission.lean";
 attribute :>> subjectScope="RA-GATE:actual-source-refinement";
 attribute :>> premise="Same short domain gate protects owner, revisions, intents, writer and sweep leases and admission; pending native calls exclude commit; no raw allocation, finalizer or GC under gate";
 }
 part sweep : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RA-SWEEP";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillReceiptAdmission.lean";
 attribute :>> subjectScope="RA-SWEEP:actual-source-refinement";
 attribute :>> premise="Retire and unique release permit under gate after scan/root/raw-reader closure; native call outside gate; unknown outcome retains charge and release exclusion; metadata outlives payload without raw authority";
 }
 ref part ledgerIntent=GambitStillLedgerSnapshot::intent;
 ref part ledgerView=GambitStillLedgerSnapshot::viewCut;
 ref part ledgerReclaim=GambitStillLedgerSnapshot::reclaim;
 ref part ownerClosure=GambitStillAuthorityHandoff::closure;
 ref part readerLifetime=GambitRetainedRcScan::lifetime;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=settlement; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=settlement; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=gate; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=gate; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sweep; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sweep; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=ledgerIntent; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=settlement; ref part :>> prerequisite=issuance; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=gate; ref part :>> prerequisite=settlement; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=gate; ref part :>> prerequisite=ledgerView; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=gate; ref part :>> prerequisite=ownerClosure; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sweep; ref part :>> prerequisite=gate; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sweep; ref part :>> prerequisite=ledgerReclaim; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sweep; ref part :>> prerequisite=readerLifetime; }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Completion replay";
 attribute :>> removedWork="One published outcome services k lost deliveries with zero repeated native calls";
 attribute :>> bound="k queries require zero new native calls; no existing retry-work reduction measured";
 attribute :>> addedCost="One retained operation record, acquire read per query; transport not benchmarked";
 attribute :>> condition="Completion remains pinned; raw pre-publication loss is excluded";
 }
 part cost1 : CostRow {
 attribute :>> capability="Duplicate accounting";
 attribute :>> removedWork="At most one refund per exact generation; subsequent requests credit zero";
 attribute :>> bound="Refund count in {0,1}; credit is W only after known failure or release";
 attribute :>> addedCost="Gate entry plus consumed-state lookup per settlement; not free";
 attribute :>> condition="Generation reuse forbidden before replay exclusion and reader drain";
 }
 part cost2 : CostRow {
 attribute :>> capability="Admission gate";
 attribute :>> removedWork="Removes check-then-owner-CAS window";
 attribute :>> bound="O(1) tuple check after inventory is prepared; no inventory pass eliminated";
 attribute :>> addedCost="One per-domain short critical section per transition; contention remains";
 attribute :>> condition="All relevant writers share gate/lease; version wrap rejected";
 }
 part cost3 : CostRow {
 attribute :>> capability="Sweep retirement";
 attribute :>> removedWork="Unique native release permit prevents duplicate free of same generation";
 attribute :>> bound="No payload copy during owner-only commit; release still one call";
 attribute :>> addedCost="Retired or unknown W stays charged until outcome settlement";
 attribute :>> condition="Roots, raw readers, scan and initializer writes closed before release";
 }
 part cost4 : CostRow {
 attribute :>> capability="Peak backing";
 attribute :>> removedWork="No new payload copying required by receipt protocol";
 attribute :>> bound="Delta actual held backing is retained released-late blocks; no unconditional saving";
 attribute :>> addedCost="Upper metadata M*Rop + N*Rblock + D*Rgate + V*Rview bytes";
 attribute :>> condition="Metadata size and bounded reclamation unmeasured; allocator internals and RSS excluded";
 }
 part cost5 : CostRow {
 attribute :>> capability="Legacy retirement";
 attribute :>> removedWork="Can retire local small/large compensation branches and sweep counter inference after adoption";
 attribute :>> bound="Zero extra whole-chain scans proved removable in current code";
 attribute :>> addedCost="Backend adapters, generations, permit and completion lifecycle remain necessary";
 attribute :>> condition="Msection/perm/RC/external API callers not silently moved into still ledger";
 }
 part cost6 : CostRow {
 attribute :>> capability="Language choice";
 attribute :>> removedWork="Modern C implements required contracts directly";
 attribute :>> bound="No additional Zig runtime-work saving established";
 attribute :>> addedCost="Zig still needs same gate, outcome capture, root and release proof";
 attribute :>> condition="Separate language/toolchain cost needs independent positive evidence";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="intent"; attribute :>> labelText="Registered intent + capacity grant"; }
 part node1 : DiagramNode { attribute :>> nodeId="native"; attribute :>> labelText="Native call outside gate"; }
 part node2 : DiagramNode { attribute :>> nodeId="rawGap"; attribute :>> labelText="Raw result not published\\nunknown custody retained"; }
 part node3 : DiagramNode { attribute :>> nodeId="outcome"; attribute :>> labelText="Immutable outcome slot\\nrelease / acquire"; }
 part node4 : DiagramNode { attribute :>> nodeId="gate"; attribute :>> labelText="Domain gate\\nsettle once + revisions"; }
 part node5 : DiagramNode { attribute :>> nodeId="view"; attribute :>> labelText="Snapshot compare + owner commit"; }
 part node6 : DiagramNode { attribute :>> nodeId="retired"; attribute :>> labelText="Sweep retirement + release permit"; }
 part node7 : DiagramNode { attribute :>> nodeId="receipt"; attribute :>> labelText="Replayable receipt + delivery"; }
 part node8 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT\\nQNT / Lean + source gaps"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="register before enter"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="interrupted before ready"; }
 part edge2 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node3; attribute :>> labelText="cooperative capture"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="validate exact identity"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node7; attribute :>> labelText="apply once; replay"; }
 part edge5 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="pending=0; same tuple"; }
 part edge6 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node6; attribute :>> labelText="scan and readers closed"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node1; attribute :>> labelText="release permit; unlock first"; }
 part edge8 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node5; attribute :>> labelText="DENY admission"; }
 part edge9 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node4; attribute :>> labelText="refinement duty"; }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="small-still";
 attribute :>> sourceAnchors="mem.c:1571-1605,1677-1708";
 attribute :>> actualChain="alloc_scmobj_still -> aligned heap -> deferred charge -> still chain";
 attribute :>> hazard="Capture unknown result before existing counter/list update; stop alone cannot recover pointer";
 attribute :>> replacement="Managed intent plus backing identity before exposure";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="large-still";
 attribute :>> sourceAnchors="mem.c:1610-1675;setup.c:1183-1198";
 attribute :>> actualChain="VM precharge or GC -> aligned heap -> failure subtract words";
 attribute :>> hazard="Deferred old words differ from new grant; aggregate GC request has no per-intent identity";
 attribute :>> replacement="Exact grant receipt; no whole aggregate refund";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="still-sweep";
 attribute :>> sourceAnchors="mem.c:4387-4427;c_intf.c:1683-1711";
 attribute :>> actualChain="unmarked chain -> release_foreign -> free aligned heap -> recount";
 attribute :>> hazard="User C may reenter; return ignored by caller; physical release status unavailable";
 attribute :>> replacement="Retire/list unlink and release permit before call; separate destructor and backing outcomes";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="still-cleanup";
 attribute :>> sourceAnchors="mem.c:4432-4456,4928-4935";
 attribute :>> actualChain="free_still_objs -> free aligned heap; then cleanup_rc";
 attribute :>> hazard="Stop or shutdown does not turn unknown free into success";
 attribute :>> replacement="Common release registry; cleanup waits outside gate or refuses completion";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="msection-perm";
 attribute :>> sourceAnchors="mem.c:989-1016,1077,1126,1222";
 attribute :>> actualChain="msection grow/shrink/cleanup and psection allocation/free use SAME heap wrapper";
 attribute :>> hazard="Global wrapper replacement would mix still, movable and permanent capacity domains";
 attribute :>> replacement="Backend receipt may be shared; domain-specific ledger adapters required";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="aligned-native";
 attribute :>> sourceAnchors="mem.c:554-599,657-667;os_base.c:445-514";
 attribute :>> actualChain="aligned pointer -> stored container -> heap route";
 attribute :>> hazard="Logical base is not native free argument; lowlevel exec changes backend";
 attribute :>> replacement="Snapshot exact container/range and backend before release, outside freed payload";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="code-native";
 attribute :>> sourceAnchors="os_base.c:326-415";
 attribute :>> actualChain="code alloc -> mmap plus two header words; code free -> munmap, or VirtualAlloc/Free, or malloc/free";
 attribute :>> hazard="munmap and VirtualFree results discarded; fallback/TempNewHandle are configuration-dependent";
 attribute :>> replacement="Status-preserving adapters selected by effective profile; no unsupported branch admission";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="ordinary-native";
 attribute :>> sourceAnchors="os_base.c:190-323;mem.c:684-829;gambit.h.in:15018-15058";
 attribute :>> actualChain="malloc/free via exported/debug macros; RC and many OS buffers share wrappers";
 attribute :>> hazard="Debug log after malloc and before free; not a completion record; external embeddings remain open";
 attribute :>> replacement="Keep unmanaged entry points until every consumer classified; no process-wide receipt claim";
 }
 part issuanceRoute : GambitHostRootsRefinement::Route { ref part :>> need=issuance;
 attribute :>> sourceAnchors="mem.c:554-667,1556-1708,4387-4456,6256-6293;os_base.c:190-415,445-514;c_intf.c:1683-1711;gambit.h.in:15018-15058";
 attribute :>> patchAnchors="No runtime patch; selected source caller census; public FFI embeddings open";
 attribute :>> projection="issuance: native outcome publication, single-gate settlement and sweep/admission exclusion require C refinement";
 attribute :>> failureCustodian="Stable canonical domain registry retains grant/block/release permit; unknown native effect cannot be replayed; death while mutating gate state refuses recovery";
 attribute :>> status="source-refinement-open";
 }
 part settlementRoute : GambitHostRootsRefinement::Route { ref part :>> need=settlement;
 attribute :>> sourceAnchors="mem.c:554-667,1556-1708,4387-4456,6256-6293;os_base.c:190-415,445-514;c_intf.c:1683-1711;gambit.h.in:15018-15058";
 attribute :>> patchAnchors="No runtime patch; selected source caller census; public FFI embeddings open";
 attribute :>> projection="settlement: native outcome publication, single-gate settlement and sweep/admission exclusion require C refinement";
 attribute :>> failureCustodian="Stable canonical domain registry retains grant/block/release permit; unknown native effect cannot be replayed; death while mutating gate state refuses recovery";
 attribute :>> status="source-refinement-open";
 }
 part gateRoute : GambitHostRootsRefinement::Route { ref part :>> need=gate;
 attribute :>> sourceAnchors="mem.c:554-667,1556-1708,4387-4456,6256-6293;os_base.c:190-415,445-514;c_intf.c:1683-1711;gambit.h.in:15018-15058";
 attribute :>> patchAnchors="No runtime patch; selected source caller census; public FFI embeddings open";
 attribute :>> projection="gate: native outcome publication, single-gate settlement and sweep/admission exclusion require C refinement";
 attribute :>> failureCustodian="Stable canonical domain registry retains grant/block/release permit; unknown native effect cannot be replayed; death while mutating gate state refuses recovery";
 attribute :>> status="source-refinement-open";
 }
 part sweepRoute : GambitHostRootsRefinement::Route { ref part :>> need=sweep;
 attribute :>> sourceAnchors="mem.c:554-667,1556-1708,4387-4456,6256-6293;os_base.c:190-415,445-514;c_intf.c:1683-1711;gambit.h.in:15018-15058";
 attribute :>> patchAnchors="No runtime patch; selected source caller census; public FFI embeddings open";
 attribute :>> projection="sweep: native outcome publication, single-gate settlement and sweep/admission exclusion require C refinement";
 attribute :>> failureCustodian="Stable canonical domain registry retains grant/block/release permit; unknown native effect cannot be replayed; death while mutating gate state refuses recovery";
 attribute :>> status="source-refinement-open";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="darwin-path-buffer";
 attribute :>> sourceAnchors="os_files.c:1672-1712,1788-1803;_kernel.scm:4221-4224;_nonstd.scm:2684,3040,3055";
 attribute :>> actualChain="Scheme executable-path users -> C primitive -> _NSGetExecutablePath growth -> direct malloc/free";
 attribute :>> hazard="Bypasses generic allocation wrappers; conversion can allocate Scheme objects while native path buffer remains live";
 attribute :>> replacement="Keep native path-buffer domain separate; backend interception alone cannot claim process-wide receipt closure";
 }
 part cost7 : CostRow {
 attribute :>> capability="Unbatched event budget";
 attribute :>> removedWork="Four basic gate visits per one allocation/free pair, before other duties";
 attribute :>> bound="2A+2F+S+H+K visits for completed calls and settlement queries";
 attribute :>> addedCost="Initializer publication, closure, scans, pool and reclamation add visits";
 attribute :>> condition="Unbatched; retire plus release-enter fused; not a time or throughput prediction";
 }
}
