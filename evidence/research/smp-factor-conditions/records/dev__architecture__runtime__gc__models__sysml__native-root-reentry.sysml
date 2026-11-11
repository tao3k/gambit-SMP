/* Modern C refactoring model; all source/native-order obligations remain open. */
package GambitNativeRootReentry {
 private import ScalarValues::*;
 part def FrozenState { attribute published : Boolean; attribute coverageComplete : Boolean; attribute writers : Integer; attribute rawBorrowers : Integer; attribute rootLocationsPinned : Boolean; attribute nativeMembershipPublished : Boolean; }
 requirement def FreezeLaw { subject f : FrozenState; require constraint { not f.published or (f.coverageComplete and f.writers==0 and f.rawBorrowers==0 and f.rootLocationsPinned and f.nativeMembershipPublished) } }
 part def ReentryState { attribute reloadAllowed : Boolean; attribute activePermit : Boolean; attribute scannerPins : Integer; attribute completedEpoch : Integer; attribute currentEpoch : Integer; attribute bindingMatches : Boolean; }
 requirement def ReentryLaw { subject e : ReentryState; require constraint { not e.reloadAllowed or (e.activePermit and e.scannerPins==0 and e.completedEpoch==e.currentEpoch and e.bindingMatches) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/native_root_reentry.qnt";
 attribute :>> subjectScope="native_root_reentry:31-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One context, two abstract canonical root cells, two collection epochs, one nested callback and independent worker2; frame/denv root completeness and platform binding are premises; no real handler, stop or C weak-memory proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="GambitSMP.NativeRootReentry:coverageTransitive;missingRootRejects;writerDebtRejectsScan;borrowDebtRejectsScan;unknownWriterRejectsScan;rawOutcomeNotScanAuthority;entryConservesDuties;reentryConservesDuties;dutyStepConserves;dutyTraceConserves;scanBlocksGrant;staleEpochRejectsGrant;grantClosesNewScan;movingRootMustReload;reloadRestoresEpoch;unrootedCallbackRejects;nestedNeedsOuterPin;freshParentView;oldActivationRejected;workerContextDistinctWitness;reclaimBlockedByScanner;rootTaskCountPreserved";
 attribute :>> premise="22 conditional declarations: coverage composition, active/frozen duty Step/Trace conservation, relocation reload, reentry exclusion, activation and view lifetime; no induction over all QNT actions or C simulation";
 }
 part coverage : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-COVERAGE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="NR-COVERAGE:actual-source-refinement";
 attribute :>> premise="Point-specific live roots include exported GVM registers, saved values, type caches, frame/denv roots, host locals and all RC domains; address/location coverage, lifetime and writable relocation slots required; no arbitrary C-stack inference";
 }
 part freeze : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-FREEZE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="NR-FREEZE:actual-source-refinement";
 attribute :>> premise="At a qualified safepoint spill live values, close ordinary root/payload writers and raw Scheme borrowers, pin frame/root locations; publish descriptor and NativeFrozen membership together; frozen locations permit collector writeback";
 }
 part member : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-MEMBER";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="NR-MEMBER:actual-source-refinement";
 attribute :>> premise="Active mutator ack becomes a frozen-root obligation in the same phase gate; collection includes every context generation exactly once; worker identity is independent of context or processor count";
 }
 part scan : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-SCAN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="NR-SCAN:actual-source-refinement";
 attribute :>> premise="Role-qualified worker owns writable canonical cells and relocation completion; moving roots updated in place or through proved writeback mapping; global collection/mutator barriers remain required";
 }
 part reentry : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-REENTRY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="NR-REENTRY:actual-source-refinement";
 attribute :>> premise="Reentry request closes new round admission, honors already-enlisted pending/in-flight root scans, validates current epoch/roots/binding and grants active participation before reload; no second scan may race protected reload; metadata pins retire after use";
 }
 part foreign : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-FFI";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="NR-FFI:actual-source-refinement";
 attribute :>> premise="Acquire callback permission before RC payload/marker access, root proc before allocation, retain suspended parent activation roots, publish fresh parent view on callback exit; unknown writers, closure identity or nonlocal exit reject transfer";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NR-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/NativeRootReentry.lean";
 attribute :>> subjectScope="NR-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Release/acquire descriptor, scan completion and phase-gate publication must order root stores and reload; no racing plain C root loads or lock-free/liveness claim; generation wrap and aliases need platform refinement";
 }
 ref part nativeEnvelope=GambitStillCompletionLifetime::envelope;
 ref part nativeRestore=GambitStillCompletionLifetime::restore;
 ref part hostRc=GambitHostRootsRefinement::rc;
 ref part hostMarker=GambitHostRootsRefinement::marker;
 ref part hostBinding=GambitHostRootsRefinement::bindingState;
 ref part lifetime=GambitRetainedRcScan::lifetime;
 ref part collector=GambitRuntimeAssurance::work.source;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=coverage; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=coverage; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=member; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=member; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scan; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scan; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=history; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=induction; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=foreign; ref part :>> prerequisite=history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=foreign; ref part :>> prerequisite=induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=coverage; ref part :>> prerequisite=hostRc; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=coverage; ref part :>> prerequisite=hostMarker; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=coverage; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=nativeEnvelope; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=lifetime; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=member; ref part :>> prerequisite=freeze; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=member; ref part :>> prerequisite=collector; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scan; ref part :>> prerequisite=member; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=scan; ref part :>> prerequisite=order; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=scan; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=nativeRestore; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=hostBinding; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=foreign; ref part :>> prerequisite=reentry; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=foreign; ref part :>> prerequisite=hostRc; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=foreign; ref part :>> prerequisite=hostMarker; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=foreign; ref part :>> prerequisite=lifetime; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=collector; }
 part coverageRoute : GambitHostRootsRefinement::Route { ref part :>> need=coverage;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020;gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538;_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590;mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676;mem.c:3490-3655,6510-6589;mem.c:684-829,3969-3987,6844-6849;examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359;c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417;c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276;os_dyn.c:744-788,1045-1059;c_intf.c:6536;os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663;mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> patchAnchors="Selected source/refactoring cut only; no runtime patch or native test";
 attribute :>> projection="coverage: canonical writable root locations, GC role/membership and activation-scoped native reentry require independent source refinement";
 attribute :>> failureCustodian="Canonical root/activation service retains frozen locations, root domains, parent frames and unknown outcome responsibility; unqualified writes or root/binding ambiguity deny transfer";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part freezeRoute : GambitHostRootsRefinement::Route { ref part :>> need=freeze;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020;gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538;_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590;mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676;mem.c:3490-3655,6510-6589;mem.c:684-829,3969-3987,6844-6849;examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359;c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417;c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276;os_dyn.c:744-788,1045-1059;c_intf.c:6536;os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663;mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> patchAnchors="Selected source/refactoring cut only; no runtime patch or native test";
 attribute :>> projection="freeze: canonical writable root locations, GC role/membership and activation-scoped native reentry require independent source refinement";
 attribute :>> failureCustodian="Canonical root/activation service retains frozen locations, root domains, parent frames and unknown outcome responsibility; unqualified writes or root/binding ambiguity deny transfer";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part memberRoute : GambitHostRootsRefinement::Route { ref part :>> need=member;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020;gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538;_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590;mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676;mem.c:3490-3655,6510-6589;mem.c:684-829,3969-3987,6844-6849;examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359;c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417;c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276;os_dyn.c:744-788,1045-1059;c_intf.c:6536;os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663;mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> patchAnchors="Selected source/refactoring cut only; no runtime patch or native test";
 attribute :>> projection="member: canonical writable root locations, GC role/membership and activation-scoped native reentry require independent source refinement";
 attribute :>> failureCustodian="Canonical root/activation service retains frozen locations, root domains, parent frames and unknown outcome responsibility; unqualified writes or root/binding ambiguity deny transfer";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part scanRoute : GambitHostRootsRefinement::Route { ref part :>> need=scan;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020;gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538;_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590;mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676;mem.c:3490-3655,6510-6589;mem.c:684-829,3969-3987,6844-6849;examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359;c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417;c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276;os_dyn.c:744-788,1045-1059;c_intf.c:6536;os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663;mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> patchAnchors="Selected source/refactoring cut only; no runtime patch or native test";
 attribute :>> projection="scan: canonical writable root locations, GC role/membership and activation-scoped native reentry require independent source refinement";
 attribute :>> failureCustodian="Canonical root/activation service retains frozen locations, root domains, parent frames and unknown outcome responsibility; unqualified writes or root/binding ambiguity deny transfer";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part reentryRoute : GambitHostRootsRefinement::Route { ref part :>> need=reentry;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020;gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538;_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590;mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676;mem.c:3490-3655,6510-6589;mem.c:684-829,3969-3987,6844-6849;examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359;c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417;c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276;os_dyn.c:744-788,1045-1059;c_intf.c:6536;os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663;mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> patchAnchors="Selected source/refactoring cut only; no runtime patch or native test";
 attribute :>> projection="reentry: canonical writable root locations, GC role/membership and activation-scoped native reentry require independent source refinement";
 attribute :>> failureCustodian="Canonical root/activation service retains frozen locations, root domains, parent frames and unknown outcome responsibility; unqualified writes or root/binding ambiguity deny transfer";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part foreignRoute : GambitHostRootsRefinement::Route { ref part :>> need=foreign;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020;gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538;_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590;mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676;mem.c:3490-3655,6510-6589;mem.c:684-829,3969-3987,6844-6849;examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359;c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417;c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276;os_dyn.c:744-788,1045-1059;c_intf.c:6536;os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663;mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> patchAnchors="Selected source/refactoring cut only; no runtime patch or native test";
 attribute :>> projection="foreign: canonical writable root locations, GC role/membership and activation-scoped native reentry require independent source refinement";
 attribute :>> failureCustodian="Canonical root/activation service retains frozen locations, root domains, parent frames and unknown outcome responsibility; unqualified writes or root/binding ambiguity deny transfer";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020;gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538;_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590;mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676;mem.c:3490-3655,6510-6589;mem.c:684-829,3969-3987,6844-6849;examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359;c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417;c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276;os_dyn.c:744-788,1045-1059;c_intf.c:6536;os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663;mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> patchAnchors="Selected source/refactoring cut only; no runtime patch or native test";
 attribute :>> projection="order: canonical writable root locations, GC role/membership and activation-scoped native reentry require independent source refinement";
 attribute :>> failureCustodian="Canonical root/activation service retains frozen locations, root domains, parent frames and unknown outcome responsibility; unqualified writes or root/binding ambiguity deny transfer";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="gvm-registers";
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2131-2159;gambit.h.in:6802-6803,6978-6992,10325-10334;lib/_kernel.c:9017-9020";
 attribute :>> actualChain="Scheme resource-set generator -> R/W_ALL spill/reload; C-fun context saves RA and writes locals to PSTATE";
 attribute :>> hazard="Spill macros are not a participation transition or coverage of arbitrary C locals";
 attribute :>> replacement="Reuse generated resource/liveness selection; add explicit safe-point/root/membership contract";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="saved-local-roots";
 attribute :>> sourceAnchors="gambit.h.in:8059-8085,11618-11625;_kernel.scm:2420-2440,3568-3586;mem.c:6525-6538";
 attribute :>> actualChain="SAVE1/2/3 -> three PSTATE slots -> GC mark_saved -> RESTORE and clear";
 attribute :>> hazard="Nested activation may reuse same three slots; standalone copied value can become stale";
 attribute :>> replacement="Activation-scoped host-root bank or equivalent proven spill stack; never infer all C locals covered";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="cache-and-processor-roots";
 attribute :>> sourceAnchors="_io.scm:5067-5082;setup.c:4721-4727;mem.c:6540-6590";
 attribute :>> actualChain="I/O macros write type_cache; setup clears root arrays; GC scans processor object";
 attribute :>> hazard="Not all PSTATE words are Scheme roots; temp1..4 and pc require point-specific classification";
 attribute :>> replacement="Root descriptor distinguishes pointer, scalar, RA and unboxed materialization states";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="continuation-stack-denv";
 attribute :>> sourceAnchors="mem.c:3820-3965;gambit.h.in:5915-5929,6658-6665,6726-6733;_thread.scm:352-380,1637,6676";
 attribute :>> actualChain="Frame GC maps and break frame -> captured continuation; restore rewrites thread denv/caches";
 attribute :>> hazard="Collector rewrites frame links/slots; callback can change dynamic environment; frozen values are not immutable";
 attribute :>> replacement="Pin locations/FrameSpec; give collector write authority; reload/reconcile before running";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="collector-writeback";
 attribute :>> sourceAnchors="mem.c:3490-3655,6510-6589";
 attribute :>> actualChain="mark_array copies/forwards objects and writes updated reference to *cell";
 attribute :>> hazard="Scanning a detached value copy without canonical writeback leaves C locals/RC payload stale";
 attribute :>> replacement="Exclusive cell relocation lease plus completion epoch; no concurrent ordinary read/write";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="rc-producers";
 attribute :>> sourceAnchors="mem.c:684-829,3969-3987,6844-6849";
 attribute :>> actualChain="alloc_rc/register_rc link to current PSTATE; set_data_rc writes data; release/addref/data access use raw header";
 attribute :>> hazard="mark_rc is invoked only from processor0 branch; plain list/refcount/data operations have no freeze permission";
 attribute :>> replacement="Canonical RC root domain per owner; enumerate every domain; migrate write/borrow/delete admission";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="tcl-callback-first-read";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:134-196,217-227,288-339,350-359";
 attribute :>> actualChain="DoOneEvent/Tcl callback -> data_rc -> tcltk_call; delete callback releases data and header";
 attribute :>> hazard="Payload read precedes C-to-Scheme marker; deletion can race scan/in-flight callback; still vector children can move";
 attribute :>> replacement="Opaque callback identity/header lease first; reacquire before data_rc; deletion retires through root service";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="marker-and-entry";
 attribute :>> sourceAnchors="c_intf.c:6511-6562;gambit.h.in:10043-10059;setup.c:3330-3417";
 attribute :>> actualChain="SFUN wrapper obtains PSTATE then allocates marker, writes proc/processor ID, calls Scheme and invalidates marker";
 attribute :>> hazard="Source root-protection TODO before marker allocation; raw callback proc cannot survive arbitrary GC";
 attribute :>> replacement="Activation token and proc root before marker allocation; result/root custody before release";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="native-conversion";
 attribute :>> sourceAnchors="c_intf.c:3210-3258,3270-3290;examples/tcltk/tcltk.scm:271-276";
 attribute :>> actualChain="Scheme string conversion allocates RC native byte buffer then C operation";
 attribute :>> hazard="Conversion itself reads Scheme data and must run while active; scheme-object FFI arguments remain managed references";
 attribute :>> replacement="Finish copy/handle conversion before FrozenNative; pure-native uses bytes plus opaque IDs only";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="closure-identity";
 attribute :>> sourceAnchors="os_dyn.c:744-788,1045-1059;c_intf.c:6536";
 attribute :>> actualChain="C closure stores global c_closure_self, converter recovers procedure from RC data";
 attribute :>> hazard="Explicit source TODO for thread locality; TLS alone does not restore identity after nested callback";
 attribute :>> replacement="Per-thread and per-activation identity/restore stack; reject unsupported generated trampoline profile";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="binding-and-global-roots";
 attribute :>> sourceAnchors="os_thread.c:697-710;setup.c:3348-3353,3387-3388;mem.c:6593-6663";
 attribute :>> actualChain="thread_set_pstate updates binding; call rewrites GVM fp/self; global roots partition by processor count";
 attribute :>> hazard="PSTATE binding is not a mutator permit; old partition cannot be reinterpreted as independent worker count";
 attribute :>> replacement="Explicit context generation, worker work-context and separate global/root ownership";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="epoch-and-cleanup";
 attribute :>> sourceAnchors="mem.c:6775-6805,6812-6870,6998-7048,4928-4935;setup.c:903-978";
 attribute :>> actualChain="Collective setup/strong/weak/cleanup barriers; retiring PSTATE cleans still/RC state";
 attribute :>> hazard="Root image does not eliminate global moving-GC coordination or authorize early frame/RC free";
 attribute :>> replacement="Preserve phase obligations; scan/return pins and stop evidence precede metadata/root facility withdrawal";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Native barrier participation";
 attribute :>> removedWork="Remove admitted pure-native contexts from active ack waiting, retain their root tasks";
 attribute :>> bound="For N contexts and K qualified frozen contexts: active ack targets N-K; root obligations still N";
 attribute :>> addedCost="Membership ledger and explicit phase admission per transition";
 attribute :>> condition="No runtime speedup or bounded native-call time; other managed contexts/global collector still coordinate";
 }
 part cost1 : CostRow {
 attribute :>> capability="Root transport";
 attribute :>> removedWork="Adopt canonical spill/RC/frame cells instead of duplicating all values";
 attribute :>> bound="Entry metadata O(D+U) if block descriptors and existing spills suffice; value-copy mode O(R)";
 attribute :>> addedCost="Descriptor blocks D, additional exported locals U, frame/root pins";
 attribute :>> condition="Coverage and writable canonical mapping must be proved; no universal constant-time freeze";
 }
 part cost2 : CostRow {
 attribute :>> capability="Return and callbacks";
 attribute :>> removedWork="Reload relocated values under active permit; no repeated native operation required";
 attribute :>> bound="Reload O(U) live exported locals; existing frames/RC cells updated in place";
 attribute :>> addedCost="Epoch/binding check, scan drain, activation root bank and callback marker";
 attribute :>> condition="Permission precedes first Scheme read; publication alone is not a callback token";
 }
 part cost3 : CostRow {
 attribute :>> capability="Root scanning work";
 attribute :>> removedWork="No existing root traversal proved removable by freezing";
 attribute :>> bound="Required scan work remains O(R); view creation does not reduce live root count";
 attribute :>> addedCost="Exclusive relocation-cell authority and per-epoch acknowledgement";
 attribute :>> condition="A stale detached root copy fails even when it kept the object alive";
 }
 part cost4 : CostRow {
 attribute :>> capability="Native argument copies";
 attribute :>> removedWork="Pure-native code can run without managed payload access";
 attribute :>> bound="Bcopy bytes for copied input/output buffers; opaque handles retain root obligations";
 attribute :>> addedCost="Copy/encoding work and buffer backing may raise peak";
 attribute :>> condition="Raw pointers into STILL payload do not certify graph stability or race freedom";
 }
 part cost5 : CostRow {
 attribute :>> capability="Nested activation lifetime";
 attribute :>> removedWork="Keep parent continuation/denv/host roots valid during callback";
 attribute :>> bound="Retained memory includes all suspended parent frame/root spans until their pins drain";
 attribute :>> addedCost="O(A) activation descriptors plus live retained spans for A nested activations";
 attribute :>> condition="Do not add independent maxima as measured whole-round peak";
 }
 part cost6 : CostRow {
 attribute :>> capability="Unknown state handling";
 attribute :>> removedWork="Allow root scan with unknown native result only when root-writer closure remains independently valid";
 attribute :>> bound="Root scan can be admissible while operation handoff remains denied";
 attribute :>> addedCost="Unknown writer/binding/closure identity or dead-held gate keeps custody and can block progress";
 attribute :>> condition="No automatic corruption detection, general owner-death recovery or allocator-progress guarantee";
 }
 part cost7 : CostRow {
 attribute :>> capability="Modern C boundary";
 attribute :>> removedWork="Reuse Scheme liveness/FrameSpec generation, C root cells and FFI conversion machinery";
 attribute :>> bound="Zero additional Zig runtime-work reduction established";
 attribute :>> addedCost="Modern C still needs activation banks, canonical RC domains, phase tokens and ordering proofs";
 attribute :>> condition="Language replacement does not establish coverage or safe native access";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="managed"; attribute :>> labelText="Managed context\\nexclusive write / participation permit"; }
 part node1 : DiagramNode { attribute :>> nodeId="freeze"; attribute :>> labelText="Safepoint spill + root coverage\\nclose writers / raw borrowers"; }
 part node2 : DiagramNode { attribute :>> nodeId="view"; attribute :>> labelText="Publish canonical root view\\ntransfer ack -> frozen-root duty"; }
 part node3 : DiagramNode { attribute :>> nodeId="native"; attribute :>> labelText="Pure native bytes / opaque IDs\\nno Scheme payload access"; }
 part node4 : DiagramNode { attribute :>> nodeId="scan"; attribute :>> labelText="Independent worker scan lease\\nwrite relocated canonical cells"; }
 part node5 : DiagramNode { attribute :>> nodeId="request"; attribute :>> labelText="Return / callback reentry request\\nhonor owed scan; close new rounds"; }
 part node6 : DiagramNode { attribute :>> nodeId="grant"; attribute :>> labelText="Drain scan; validate latest epoch\\ngrant active participation"; }
 part node7 : DiagramNode { attribute :>> nodeId="reload"; attribute :>> labelText="Reload roots / protect callback proc\\nthen marker and Scheme execution"; }
 part node8 : DiagramNode { attribute :>> nodeId="parent"; attribute :>> labelText="Callback exit exports result\\npublish fresh parent view"; }
 part node9 : DiagramNode { attribute :>> nodeId="deny"; attribute :>> labelText="Unknown writer / stale binding\\nretain custody; refuse transfer"; }
 part node10 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT\\nQNT / Lean / native-order gap"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="revoke ordinary writes"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="phase-gated publication"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="issue native permit"; }
 part edge3 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node4; attribute :>> labelText="root duty remains live"; }
 part edge4 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node5; attribute :>> labelText="before first managed read"; }
 part edge5 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node6; attribute :>> labelText="completion epoch + cell updates"; }
 part edge6 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="mutator / scan arbitration"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="permit protects reload window"; }
 part edge8 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node0; attribute :>> labelText="ordinary return"; }
 part edge9 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="nested callback path"; }
 part edge10 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node2; attribute :>> labelText="fresh revision; parent roots retained"; }
 part edge11 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node9; attribute :>> labelText="unqualified managed access"; }
 part edge12 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node9; attribute :>> labelText="writer / coverage gap"; }
 part edge13 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node6; attribute :>> labelText="conditional refinement only"; }
}
