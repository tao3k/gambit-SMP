/* Modern C target; schema laws do not qualify runtime instances. */
package GambitStillAuthorityHandoff {
 private import ScalarValues::*;
 part def GateState { attribute ingressOpen : Boolean; attribute pendingGrants : Integer; attribute activeWriters : Integer; attribute borrowers : Integer; attribute closedReceipt : Boolean; }
 requirement def GateLaw { subject g : GateState; require constraint { g.pendingGrants>=0 and g.activeWriters>=0 and g.borrowers>=0 and (not g.closedReceipt or (not g.ingressOpen and g.pendingGrants==0 and g.activeWriters==0 and g.borrowers==0)) } }
 part def StopState { attribute scanRelease : Boolean; attribute operationClosed : Boolean; attribute rootSnapshot : Boolean; attribute stopAuthenticated : Boolean; attribute cooperativeClosure : Boolean; attribute storesIntegral : Boolean; }
 requirement def StopLaw { subject s : StopState; require constraint { not s.scanRelease or (s.operationClosed and s.rootSnapshot and (s.stopAuthenticated or s.cooperativeClosure) and s.storesIntegral) } }
 part def HandoffState { attribute cleanupAllowed : Boolean; attribute commitKnown : Boolean; attribute generationMatches : Boolean; attribute receiverDomainLive : Boolean; attribute oldReaders : Integer; attribute sourceAliasDetached : Boolean; attribute uniqueCharge : Boolean; attribute backingLive : Boolean; }
 requirement def HandoffLaw { subject h : HandoffState; require constraint { h.oldReaders>=0 and (not h.cleanupAllowed or (h.commitKnown and h.generationMatches and h.receiverDomainLive and h.oldReaders==0 and h.sourceAliasDetached and h.uniqueCharge and h.backingLive)) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AH-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_authority_handoff.qnt";
 attribute :>> subjectScope="still_authority_handoff:34-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One domain/two writers/pending grant/borrower/reader; two owners, four physical words; cancellation, unknown join and canonical transfer; no native progress proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AH-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillAuthorityHandoff.lean";
 attribute :>> subjectScope="GambitSMP.StillAuthorityHandoff:reserveAddsDebt;admitConservesDebt;closePreservesDebt;noReopenStep;closedDebtNonincreasing;noReopenTrace;closedTraceDebt;pendingBlocksClosure;activeBlocksClosure;stopDoesNotCloseBorrower;lostReceiptInsufficient;rawErrorRefused;staleIdentityRefused;foldPreservesCharge;duplicateDeferredOvercounts;omittingDeferredUndercounts;transferPreservesCharge;transferPreservesBacking;transferPreservesRoots;transferIdempotent;pinBlocksCleanup;metadataPeak";
 attribute :>> premise="22 named conditional statements; closed Gate Step/Trace debt and no-reopen induction; canonical account/owner algebra only; not whole QNT or C refinement";
 }
 part closure : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AH-CLOSE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillAuthorityHandoff.lean";
 attribute :>> subjectScope="AH-CLOSE:actual-source-refinement";
 attribute :>> premise="Close new grants atomically against reservation/admission; retain pending and active writer plus borrower debt; callbacks cannot reopen retired generation; no scan grant before root and write closure";
 }
 part stop : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AH-STOP";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillAuthorityHandoff.lean";
 attribute :>> subjectScope="AH-STOP:actual-source-refinement";
 attribute :>> premise="Exact raw native join return, unique join owner and executor generation; successful target stop does not drain borrowers or restore freed backing; independent cooperative WriteClosed alternative; lost join response is not safely rejoined";
 }
 part chain : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AH-CHAIN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillAuthorityHandoff.lean";
 attribute :>> subjectScope="AH-CHAIN:actual-source-refinement";
 attribute :>> premise="One canonical StillDomain retains physical chain, root census, valid scanner metadata and exact allocation ledger independent of PSTATE; prepare then owner-generation commit; reader pins protect legacy aliases; no duplicate charge or post-cleanup resurrection";
 }
 part admission : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="AH-ADMIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillAuthorityHandoff.lean";
 attribute :>> subjectScope="AH-ADMIT:actual-source-refinement";
 attribute :>> premise="Detach GC participant only after write closure, complete root snapshot and independent scan/accounting service acceptance; unknown transfer reply retains canonical backing and uses query; unknown raw writer or corrupted allocator still blocks";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closure; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closure; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=chain; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=chain; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closure; ref part :>> prerequisite=GambitStillMaterializationCustody::shell; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closure; ref part :>> prerequisite=GambitGenerationalBarrier::memoryOrder; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=closure; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=closure; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=GambitStillOwnerRetirement::stop; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=GambitRetainedRcScan::joinResult; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=chain; ref part :>> prerequisite=closure; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=chain; ref part :>> prerequisite=GambitHostRootsRefinement::rc; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=chain; ref part :>> prerequisite=GambitRetainedRcScan::lifetime; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=chain; ref part :>> prerequisite=GambitRcFreezePublication::publication; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=chain; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=closure; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=stop; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=chain; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitStillInitSafepoint::admission; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=admission; ref part :>> prerequisite=GambitRuntimeAssurance::release.source; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStillMaterializationCustody::writes; ref part :>> prerequisite=closure; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStillMaterializationCustody::roots; ref part :>> prerequisite=chain; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitStillMaterializationCustody::recovery; ref part :>> prerequisite=admission; }
 part closureRoute : GambitHostRootsRefinement::Route { ref part :>> need=closure;
 attribute :>> sourceAnchors="lib/setup.c:66-90,903-978,4554-4580,4665-4672,4825-4863,5978-5979,6207-6211;lib/os_thread.c:546-591;lib/mem.c:300-306,1443-1482,1556-1708,4222-4245,4387-4456,4647-4649,4928-4966,6256-6293,6775-6805,6912-6936;lib/c_intf.c:6511-6562;lib/_kernel.scm:43-112";
 attribute :>> patchAnchors="Base vendor source; cumulative fixture unchanged; exported embedding hooks outside selected internal caller closure remain admission gaps";
 attribute :>> projection="Close new grants atomically against reservation/admission; retain pending and active writer plus borrower debt; callbacks cannot reopen retired generation; no scan grant before root and write closure";
 attribute :>> failureCustodian="Canonical domain service retains backing/roots/accounting until commit is observed and old aliases drain; uncertain heap authority stays with donor generation; native lifecycle service retains raw join uncertainty";
 attribute :>> status="selected-internal-callers-known-external-hook-and-C-refinement-open";
 }
 part stopRoute : GambitHostRootsRefinement::Route { ref part :>> need=stop;
 attribute :>> sourceAnchors="lib/setup.c:66-90,903-978,4554-4580,4665-4672,4825-4863,5978-5979,6207-6211;lib/os_thread.c:546-591;lib/mem.c:300-306,1443-1482,1556-1708,4222-4245,4387-4456,4647-4649,4928-4966,6256-6293,6775-6805,6912-6936;lib/c_intf.c:6511-6562;lib/_kernel.scm:43-112";
 attribute :>> patchAnchors="Base vendor source; cumulative fixture unchanged; exported embedding hooks outside selected internal caller closure remain admission gaps";
 attribute :>> projection="Exact raw native join return, unique join owner and executor generation; successful target stop does not drain borrowers or restore freed backing; independent cooperative WriteClosed alternative; lost join response is not safely rejoined";
 attribute :>> failureCustodian="Canonical domain service retains backing/roots/accounting until commit is observed and old aliases drain; uncertain heap authority stays with donor generation; native lifecycle service retains raw join uncertainty";
 attribute :>> status="selected-internal-callers-known-external-hook-and-C-refinement-open";
 }
 part chainRoute : GambitHostRootsRefinement::Route { ref part :>> need=chain;
 attribute :>> sourceAnchors="lib/setup.c:66-90,903-978,4554-4580,4665-4672,4825-4863,5978-5979,6207-6211;lib/os_thread.c:546-591;lib/mem.c:300-306,1443-1482,1556-1708,4222-4245,4387-4456,4647-4649,4928-4966,6256-6293,6775-6805,6912-6936;lib/c_intf.c:6511-6562;lib/_kernel.scm:43-112";
 attribute :>> patchAnchors="Base vendor source; cumulative fixture unchanged; exported embedding hooks outside selected internal caller closure remain admission gaps";
 attribute :>> projection="One canonical StillDomain retains physical chain, root census, valid scanner metadata and exact allocation ledger independent of PSTATE; prepare then owner-generation commit; reader pins protect legacy aliases; no duplicate charge or post-cleanup resurrection";
 attribute :>> failureCustodian="Canonical domain service retains backing/roots/accounting until commit is observed and old aliases drain; uncertain heap authority stays with donor generation; native lifecycle service retains raw join uncertainty";
 attribute :>> status="selected-internal-callers-known-external-hook-and-C-refinement-open";
 }
 part admissionRoute : GambitHostRootsRefinement::Route { ref part :>> need=admission;
 attribute :>> sourceAnchors="lib/setup.c:66-90,903-978,4554-4580,4665-4672,4825-4863,5978-5979,6207-6211;lib/os_thread.c:546-591;lib/mem.c:300-306,1443-1482,1556-1708,4222-4245,4387-4456,4647-4649,4928-4966,6256-6293,6775-6805,6912-6936;lib/c_intf.c:6511-6562;lib/_kernel.scm:43-112";
 attribute :>> patchAnchors="Base vendor source; cumulative fixture unchanged; exported embedding hooks outside selected internal caller closure remain admission gaps";
 attribute :>> projection="Detach GC participant only after write closure, complete root snapshot and independent scan/accounting service acceptance; unknown transfer reply retains canonical backing and uses query; unknown raw writer or corrupted allocator still blocks";
 attribute :>> failureCustodian="Canonical domain service retains backing/roots/accounting until commit is observed and old aliases drain; uncertain heap authority stays with donor generation; native lifecycle service retains raw join uncertainty";
 attribute :>> status="selected-internal-callers-known-external-hook-and-C-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="resize-shrink";
 attribute :>> sourceAnchors="setup.c:903-978";
 attribute :>> actualChain="Collective resize -> retiring cleanup -> native exit; processor0 joins afterward";
 attribute :>> hazard="Join success arrives after physical cleanup; ignored join status is not custody evidence";
 attribute :>> replacement="Close grants, publish root/backing domain and retire context alias before cleanup; join handled by separate lifecycle service";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="shutdown-and-rollback";
 attribute :>> sourceAnchors="setup.c:950,4554-4580,4825-4863;mem.c:4928-4966";
 attribute :>> actualChain="Setup rollback and shutdown reach cleanup_mem_pstate; VM teardown destroys scan locks";
 attribute :>> hazard="Partially set-up owner has different obligations; scan facility destruction cannot precede retained-domain drain";
 attribute :>> replacement="Exact lifecycle generation and cleanup permit; never infer all-domain drain from processor count";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="native-join";
 attribute :>> sourceAnchors="os_thread.c:546-591;setup.c:6207-6211";
 attribute :>> actualChain="POSIX join -> errno-based mapping; export table publishes join/exit hooks";
 attribute :>> hazard="Raw returned status discarded; external hooks widen caller set; lost success cannot be blindly rejoined";
 attribute :>> replacement="Capture raw return plus generation under unique join owner; raw embeddings require explicit admission";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="still-allocation";
 attribute :>> sourceAnchors="mem.c:1556-1708";
 attribute :>> actualChain="Deferred or VM-charged reservation -> physical allocation -> link/header";
 attribute :>> hazard="Private allocation, deferred debt and published chain are not one atomic update";
 attribute :>> replacement="Target block/reservation ledger before exposure; freeze pending allocator mutations before transfer";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="still-scan-sweep";
 attribute :>> sourceAnchors="mem.c:4222-4245,4387-4456,6912-6936";
 attribute :>> actualChain="Enumerate still refcounts -> rewrite scan work -> sweep and relink/free";
 attribute :>> hazard="Whole chain includes garbage and foreign release callbacks, not only one protected initializer";
 attribute :>> replacement="Pin canonical domain; finish current scan/sweep before physical mutation handoff; release-affinity remains separate gate";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="still-accounting";
 attribute :>> sourceAnchors="mem.c:300-306,1571-1633,6256-6293,6804-6805";
 attribute :>> actualChain="Per-PSTATE deferred/live counters; VM global charge; GC recount loops processor_count";
 attribute :>> hazard="Removing processor or duplicating counters can omit or duplicate charge; old live counter is not target booked ledger";
 attribute :>> replacement="One inventory key per domain; reconstruct physical lengths and reservation state at migration cut; separate phase totals";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="marker-and-native-borrow";
 attribute :>> sourceAnchors="c_intf.c:6511-6562;mem.c:1443-1482,723-829";
 attribute :>> actualChain="Marker field mutation and still/RC refcounts may occur on callback exit";
 attribute :>> hazard="Payload stores are not all writers; native retained aliases and refcounts must drain too";
 attribute :>> replacement="Generation-scoped borrow/write permits; cleanup and callbacks fail closed after ingress close";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="generated-fill";
 attribute :>> sourceAnchors="_kernel.scm:43-112;_kernel.c:23864-23904";
 attribute :>> actualChain="Refcount decrement -> plain fill -> Scheme result";
 attribute :>> hazard="No cooperative native exit inside selected fill; arbitrary mid-loop death is not an established recoverable path";
 attribute :>> replacement="Keep synchronous fast path; batch safepoints and stopped-owner recovery need generated guards first";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="write-authority closure";
 attribute :>> removedWork="Prevent new grants from slipping behind a zero-writer snapshot";
 attribute :>> bound="For W active writers, P pending grants and B borrowers, closure requires W+P+B=0";
 attribute :>> addedCost="Generation gate and token accounting; at most batch b stores per cooperative lease, no time bound";
 attribute :>> condition="Closing ingress is not revoking existing raw aliases; fault/unknown writer cannot be ignored";
 }
 part cost1 : CostRow {
 attribute :>> capability="operation closure versus native join";
 attribute :>> removedWork="Allow GC after independent WriteClosed even when native join reply is unknown";
 attribute :>> bound="No join needed on GC critical path only when operation access and all root/scan duties are independently closed";
 attribute :>> addedCost="Two distinct receipts plus raw join identity retained for OS resource cleanup";
 attribute :>> condition="Unknown live managed writer or incomplete root snapshot still blocks; no unconditional GC liveness";
 }
 part cost2 : CostRow {
 attribute :>> capability="canonical whole-chain transfer";
 attribute :>> removedWork="Avoid recopying payload and duplicate donor/receiver physical inventories";
 attribute :>> bound="Zero payload bytes copied at descriptor commit; O(1) ownership change after a qualified frozen domain exists";
 attribute :>> addedCost="Domain descriptor, generation CAS and receiver admission; legacy adoption can require O(N) block walk";
 attribute :>> condition="O(1) is metadata commit only; scan/sweep/root closure and callbacks are not O(1)";
 }
 part cost3 : CostRow {
 attribute :>> capability="capacity conservation";
 attribute :>> removedWork="Prevent retired PSTATE loss from undercounting still space";
 attribute :>> bound="Sum each domain physical inventory and reservation once; fold booked+deferred without changing total";
 attribute :>> addedCost="Target ledger and collector census must replace processor_count aggregation";
 attribute :>> condition="Current words_still_objs is a phase statistic, not directly target booked; conversion proof remains open";
 }
 part cost4 : CostRow {
 attribute :>> capability="old-reader drain";
 attribute :>> removedWork="Keep new GC domain usable while legacy PSTATE metadata retirement waits";
 attribute :>> bound="Old alias pins postpone PSTATE reuse; canonical domain can still be scanned after context cleanup";
 attribute :>> addedCost="Pinned metadata retained and no source free before exact-generation commit query";
 attribute :>> condition="Unknown legacy writer/scan mutator is not a harmless reader; retains GC gate or requires earlier phase closure";
 }
 part cost5 : CostRow {
 attribute :>> capability="peak memory";
 attribute :>> removedWork="No second payload copy is required by ownership transfer";
 attribute :>> bound="For L retained chain words plus metadata M, target handoff adds M, not another L, if both aliases name one backing";
 attribute :>> addedCost="May retain an entire L-word chain and source metadata longer; staging S and inputs E remain separate";
 attribute :>> condition="No measured saving; peak only falls if max_t(P_t-Qg_t+A_t)<max_t(P_t), not from a late refund";
 }
 part cost6 : CostRow {
 attribute :>> capability="modern C and Zig";
 attribute :>> removedWork="Share one Scheme-generated permit/domain schema and collector contract";
 attribute :>> bound="Same stores, debt, fences, roots and ledger duties in either language";
 attribute :>> addedCost="Modern C atomics/ABI and source migration required; Zig adds another lowering/toolchain if chosen";
 attribute :>> condition="No additional Zig GC work reduction established; modern C is mandatory";
 }
 part def Node { attribute nodeId : String; attribute labelText : String; }
 part def Edge { ref part producer : Node; ref part consumer : Node; attribute labelText : String; }
 part node0 : Node { attribute :>> nodeId="open"; attribute :>> labelText="Ingress open\\npending grants + live writers"; }
 part node1 : Node { attribute :>> nodeId="close"; attribute :>> labelText="Close generation\\nretain W + P + B debt"; }
 part node2 : Node { attribute :>> nodeId="stop"; attribute :>> labelText="WriteClosed or authenticated stop\\nborrower drain + store integrity"; }
 part node3 : Node { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown raw writer / allocator\\nGC cannot detach"; }
 part node4 : Node { attribute :>> nodeId="domain"; attribute :>> labelText="Canonical StillDomain\\nroots + chain + ledger"; }
 part node5 : Node { attribute :>> nodeId="prepare"; attribute :>> labelText="Prepare receiver\\nsource retains custody"; }
 part node6 : Node { attribute :>> nodeId="commit"; attribute :>> labelText="Commit owner generation\\nno payload movement"; }
 part node7 : Node { attribute :>> nodeId="query"; attribute :>> labelText="Unknown reply\\nquery canonical identity"; }
 part node8 : Node { attribute :>> nodeId="scan"; attribute :>> labelText="GC census by domain key\\nscan + exact capacity"; }
 part node9 : Node { attribute :>> nodeId="readers"; attribute :>> labelText="Drain old PSTATE aliases\\nkeep backing live"; }
 part node10 : Node { attribute :>> nodeId="cleanup"; attribute :>> labelText="Cleanup permit\\nretire PSTATE, retain domain"; }
 part edge0 : Edge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="linearized against grant admission"; }
 part edge1 : Edge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="all authority accounted"; }
 part edge2 : Edge { ref part :>> producer=node1; ref part :>> consumer=node3; attribute :>> labelText="no closure evidence"; }
 part edge3 : Edge { ref part :>> producer=node2; ref part :>> consumer=node4; attribute :>> labelText="freeze links/accounting; root snapshot"; }
 part edge4 : Edge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="receiver resources accepted"; }
 part edge5 : Edge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="single canonical owner commit"; }
 part edge6 : Edge { ref part :>> producer=node5; ref part :>> consumer=node4; attribute :>> labelText="reject: donor keeps domain"; }
 part edge7 : Edge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="reply lost: keep both aliases"; }
 part edge8 : Edge { ref part :>> producer=node7; ref part :>> consumer=node6; attribute :>> labelText="read existing commit; no second transfer"; }
 part edge9 : Edge { ref part :>> producer=node4; ref part :>> consumer=node8; attribute :>> labelText="GC may use frozen retained domain"; }
 part edge10 : Edge { ref part :>> producer=node6; ref part :>> consumer=node8; attribute :>> labelText="canonical key unchanged"; }
 part edge11 : Edge { ref part :>> producer=node6; ref part :>> consumer=node9; attribute :>> labelText="detach old alias"; }
 part edge12 : Edge { ref part :>> producer=node9; ref part :>> consumer=node10; attribute :>> labelText="old readers zero; commit known"; }
 part edge13 : Edge { ref part :>> producer=node10; ref part :>> consumer=node8; attribute :>> labelText="next GC still enumerates backing"; }
 part edge14 : Edge { ref part :>> producer=node3; ref part :>> consumer=node2; attribute :>> labelText="requires real external closure evidence"; }
}
