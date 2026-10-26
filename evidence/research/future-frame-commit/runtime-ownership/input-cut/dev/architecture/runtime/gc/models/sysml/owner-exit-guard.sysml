/* Modern C original-owner exit guard research; logical marker != heap clear. */
package GambitOwnerExitGuard {
 private import ScalarValues::*;
 part def GuardRecord { attribute rootCellsDurable : Boolean; attribute writerStopped : Boolean; attribute dutyTransferred : Boolean; attribute logicalMarkerClosed : Boolean; attribute catcherRestored : Boolean; attribute mayPop : Boolean; }
 requirement def PopLaw { subject g : GuardRecord; require constraint { not g.mayPop or (g.rootCellsDurable and g.writerStopped and g.dutyTransferred and g.logicalMarkerClosed and g.catcherRestored) } }
 part def ExitPacket { attribute destinationIdentity : String; attribute currentFrameCoordinate : String; attribute originalOwner : String; attribute invocationGeneration : Integer; attribute kindTag : String; }
 part def MarkerRetirement { attribute logicalClosed : Boolean; attribute heapWritePermit : Boolean; attribute physicalCleared : Boolean; }
 requirement def MarkerWriteLaw { subject m : MarkerRetirement; require constraint { not m.physicalCleared or (m.logicalClosed and m.heapWritePermit) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/owner_exit_guard.qnt";
 attribute :>> subjectScope="owner_exit_guard:29-named-histories;safe;seed=17;100x100";
 attribute :>> premise="Three original-owner activations: root ___run and two nested SFUNs; native-only settlement, complete off-stack roots, stopped writers and qualified bridge policy are premises; marker state means logical validity, not actual heap clearing or refcount; no weak-memory, arbitrary library unwind or dynamic-wind simulation";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="GambitSMP.OwnerExitGuard:settlePreservesRootTotal;settlePreservesInitTotal;settlePreservesCommit;settlePreservesResultRoot;settleRetainsInitDuty;settledMarkerDead;settlePreservesWellFormed;otherFrameUnchanged;liveTargetPreserved;transportFpPreserved;destinationPreserved;stepPreservesDestination;stepPreservesFp;stepPreservesTargetFrame;tracePreservesTargetFrame;tracePreservesFp;missingCatcherRejects;stackOnlyRootsReject;unknownStopRejects;wrongOwnerRejects;bridgeDebtRejects";
 attribute :>> premise="21 conditional declarations: root/init accounting, committed-result preservation, non-target settlement Step/Trace and pop gates; not complete QNT/source simulation or C lifetime/GC proof";
 }
 part emission : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-EMIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="UG-EMIT:actual-source-refinement";
 attribute :>> premise="Scheme c-make-function/c-function emits guards for void, SCMOBJ and native-result SFUN families before marker allocation; protected entry/result/error roots and typed exit descriptors cover argument/result conversions and conversion-handler reentry; static module entry and dynamic C-closure proc origins differ; no body/END-only placement";
 }
 part runBoundary : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-RUN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="UG-RUN:actual-source-refinement";
 attribute :>> premise="Reuse ___run catcher while adding persistent entry record before allocating marker and one outcome funnel after END_TRY; normal/matching return and C error retain existing return-code contract; startup/processor error propagation stays separate from SFUN rethrow; nested external ___run has no automatic admitted profile";
 }
 part transport : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-TRANSPORT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="UG-TRANSPORT:actual-source-refinement";
 attribute :>> premise="Preserve current continuation destination and logical GVM frame coordinate through inner guard and CFUN bridges; never restore abandoned entry fp or invoke winding/destructor callbacks during settlement; only matched ___call consumes target frame; internal UNWIND_C_STACK_TO_TRAMPOLINE trips remain consumed by its loop and never close invocation; original activation/OS thread/processor generation and nonlocal-jump ABI remain mandatory";
 }
 part rootCustody : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-ROOTS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="UG-ROOTS:actual-source-refinement";
 attribute :>> premise="Root cells and error/result/destination descriptors outlive every escaped C frame; logical activation close precedes pop, actual marker clear/refcount decrement waits exclusive root/heap write permission; return handler validates authoritative activation state without changing processor-hook ordering; queued return requests cannot resurrect closed activations; nonzero RC scan/teardown closure still required";
 }
 part duty : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-DUTY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="UG-DUTY:actual-source-refinement";
 attribute :>> premise="Guard closes bounded writers, publishes exact stopped initialization duty to pre-backed service escrow and preserves already committed wrapper/result right; no replay, rollback, root retirement or ticket refund from exception/unknown response; unknown managed stop/layout refuses admission or fail-stops violated admitted premise, never waits in an owner/GC cycle or fabricates ordinary return";
 }
 part bridge : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-BRIDGE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="UG-BRIDGE:actual-source-refinement";
 attribute :>> premise="Existing CFUN TRY, W_ALL/R_ALL, argument conversion releases and custom AT_END effects remain caller obligations; qualify every intervening native frame and cleanup origin, settle native temporaries or explicitly transfer permitted duties before propagation; foreign-library continuation escape unsupported without contract, not converted to Tcl success/error by fiat";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="UG-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/OwnerExitGuard.lean";
 attribute :>> subjectScope="UG-ORDER:actual-C-memory-refinement";
 attribute :>> premise="C memory/lifetime refinement for stable pre-setjmp record handle, canonical result read, activation close/return claim, off-stack root publication, deferred physical marker write/refcount, catcher restore before propagation and generation reuse; acquire/release or locks never make raw racing SCMOBJ reads safe";
 }
 ref part priorMarker=GambitForeignShellUnwind::marker;
 ref part priorUnwind=GambitForeignShellUnwind::unwind;
 ref part priorCommit=GambitForeignShellUnwind::commit;
 ref part priorReclaim=GambitForeignShellUnwind::reclaim;
 ref part priorOrder=GambitForeignShellUnwind::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=emission; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=emission; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=emission; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runBoundary; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runBoundary; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runBoundary; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=transport; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=transport; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=transport; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=duty; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=duty; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=duty; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bridge; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bridge; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bridge; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=emission; ref part :>> prerequisite=priorUnwind; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runBoundary; ref part :>> prerequisite=rootCustody; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=runBoundary; ref part :>> prerequisite=transport; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=transport; ref part :>> prerequisite=priorMarker; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=priorMarker; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=priorUnwind; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=duty; ref part :>> prerequisite=rootCustody; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=duty; ref part :>> prerequisite=priorCommit; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=duty; ref part :>> prerequisite=priorReclaim; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bridge; ref part :>> prerequisite=transport; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bridge; ref part :>> prerequisite=duty; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=bridge; ref part :>> prerequisite=emission; }
 part emissionRoute : GambitHostRootsRefinement::Route { ref part :>> need=emission;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030;gsc/_ptree2.scm:3145-3187;lib/os_dyn.c:744-790,1045-1058;include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Scheme c-make-function/c-function emits guards for void, SCMOBJ and native-result SFUN families before marker allocation; protected entry/result/error roots and typed exit descriptors cover argument/result conversions and conversion-handler reentry; static module entry and dynamic C-closure proc origins differ; no body/END-only placement";
 attribute :>> failureCustodian="Original owner guard retains exact packet and canonical result; stopped initialization and off-stack roots transfer to backed service before C pop; live destination remains valid; unknown managed state rejects admission or fail-stops violated premise; no rollback/refund from escape";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part runBoundaryRoute : GambitHostRootsRefinement::Route { ref part :>> need=runBoundary;
 attribute :>> sourceAnchors="lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072;lib/setup.c:3395-3420;include/gambit.h.in:9981-10007;lib/setup.c:763-835,6400-6443";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Reuse ___run catcher while adding persistent entry record before allocating marker and one outcome funnel after END_TRY; normal/matching return and C error retain existing return-code contract; startup/processor error propagation stays separate from SFUN rethrow; nested external ___run has no automatic admitted profile";
 attribute :>> failureCustodian="Original owner guard retains exact packet and canonical result; stopped initialization and off-stack roots transfer to backed service before C pop; live destination remains valid; unknown managed state rejects admission or fail-stops violated premise; no rollback/refund from escape";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part transportRoute : GambitHostRootsRefinement::Route { ref part :>> need=transport;
 attribute :>> sourceAnchors="lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072;lib/setup.c:3395-3420;include/gambit.h.in:9981-10007;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;lib/_kernel.scm:1034-1064,1838-1849;lib/_thread.scm:3127-3151;lib/_thread.scm:4794-4812,4915-4995";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Preserve current continuation destination and logical GVM frame coordinate through inner guard and CFUN bridges; never restore abandoned entry fp or invoke winding/destructor callbacks during settlement; only matched ___call consumes target frame; internal UNWIND_C_STACK_TO_TRAMPOLINE trips remain consumed by its loop and never close invocation; original activation/OS thread/processor generation and nonlocal-jump ABI remain mandatory";
 attribute :>> failureCustodian="Original owner guard retains exact packet and canonical result; stopped initialization and off-stack roots transfer to backed service before C pop; live destination remains valid; unknown managed state rejects admission or fail-stops violated premise; no rollback/refund from escape";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part rootCustodyRoute : GambitHostRootsRefinement::Route { ref part :>> need=rootCustody;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:3145-3187;lib/os_dyn.c:744-790,1045-1058;include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821,684-825,6844-6850;lib/_kernel.scm:1034-1064,1838-1849;lib/_thread.scm:3127-3151;examples/tcltk/tcltk.scm:124-194,221-228,269-276";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Root cells and error/result/destination descriptors outlive every escaped C frame; logical activation close precedes pop, actual marker clear/refcount decrement waits exclusive root/heap write permission; return handler validates authoritative activation state without changing processor-hook ordering; queued return requests cannot resurrect closed activations; nonzero RC scan/teardown closure still required";
 attribute :>> failureCustodian="Original owner guard retains exact packet and canonical result; stopped initialization and off-stack roots transfer to backed service before C pop; live destination remains valid; unknown managed state rejects admission or fail-stops violated premise; no rollback/refund from escape";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part dutyRoute : GambitHostRootsRefinement::Route { ref part :>> need=duty;
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;lib/setup.c:3395-3420;include/gambit.h.in:9981-10007;lib/setup.c:763-835,6400-6443;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821,684-825,6844-6850;examples/tcltk/tcltk.scm:124-194,221-228,269-276";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Guard closes bounded writers, publishes exact stopped initialization duty to pre-backed service escrow and preserves already committed wrapper/result right; no replay, rollback, root retirement or ticket refund from exception/unknown response; unknown managed stop/layout refuses admission or fail-stops violated admitted premise, never waits in an owner/GC cycle or fabricates ordinary return";
 attribute :>> failureCustodian="Original owner guard retains exact packet and canonical result; stopped initialization and off-stack roots transfer to backed service before C pop; live destination remains valid; unknown managed state rejects admission or fail-stops violated premise; no rollback/refund from escape";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part bridgeRoute : GambitHostRootsRefinement::Route { ref part :>> need=bridge;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030;include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;lib/_thread.scm:4794-4812,4915-4995;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Existing CFUN TRY, W_ALL/R_ALL, argument conversion releases and custom AT_END effects remain caller obligations; qualify every intervening native frame and cleanup origin, settle native temporaries or explicitly transfer permitted duties before propagation; foreign-library continuation escape unsupported without contract, not converted to Tcl success/error by fiat";
 attribute :>> failureCustodian="Original owner guard retains exact packet and canonical result; stopped initialization and off-stack roots transfer to backed service before C pop; live destination remains valid; unknown managed state rejects admission or fail-stops violated premise; no rollback/refund from escape";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030;gsc/_ptree2.scm:3145-3187;lib/os_dyn.c:744-790,1045-1058;include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178;lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072;lib/setup.c:3395-3420;include/gambit.h.in:9981-10007;lib/setup.c:763-835,6400-6443;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821,684-825,6844-6850;lib/_kernel.scm:1034-1064,1838-1849;lib/_thread.scm:3127-3151;lib/_thread.scm:4794-4812,4915-4995;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="C memory/lifetime refinement for stable pre-setjmp record handle, canonical result read, activation close/return claim, off-stack root publication, deferred physical marker write/refcount, catcher restore before propagation and generation reuse; acquire/release or locks never make raw racing SCMOBJ reads safe";
 attribute :>> failureCustodian="Original owner guard retains exact packet and canonical result; stopped initialization and off-stack roots transfer to backed service before C pop; live destination remains valid; unknown managed state rejects admission or fail-stops violated premise; no rollback/refund from escape";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="generator-function-families";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030";
 attribute :>> actualChain="c-make-function emits void, SCMOBJ and typed-native BEGIN/ERROR/END families; reorders scheme-object parameters before other conversions";
 attribute :>> hazard="Guard inside SFUN_BODY misses earlier marker/argument allocation and later result/error conversion";
 attribute :>> replacement="One enclosing entry/exit plan for all three families; generated adapters retain native result ABI";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="generator-procedure-origin";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:3145-3187;lib/os_dyn.c:744-790,1045-1058";
 attribute :>> actualChain="c-function selects module MLBL for c-define, false for dynamic C closure; trampoline stores global self";
 attribute :>> hazard="Static module/code pin and dynamic closure/root lease have different proof obligations";
 attribute :>> replacement="Typed ProcOrigin, capture closure before reentry, stable code/RC/root leases";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="sfun-error-reentry";
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10059;lib/_kernel.scm:149-178";
 attribute :>> actualChain="SFUN conversion errors write temps then call handler; default handler raises Scheme conversion exception";
 attribute :>> hazard="Error handler can reenter, escape or return; PSTATE scratch is not durable parent storage";
 attribute :>> replacement="Protect per-invocation error/result roots and separate transport tag from Scheme handler semantics";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="call-frame-consumption";
 attribute :>> sourceAnchors="lib/setup.c:3276-3390;lib/_kernel.scm:1020-1072";
 attribute :>> actualChain="___call builds marker frame; wrong marker/error rethrows; only matching unwind advances fp and restores R0";
 attribute :>> hazard="Restoring inner entry fp destroys outer destination; killing destination marker prevents legal return";
 attribute :>> replacement="Inner settlement preserves rooted destination/coordinate; matching ___call alone consumes frame";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="run-error-funnel";
 attribute :>> sourceAnchors="lib/setup.c:3395-3420;include/gambit.h.in:9981-10007";
 attribute :>> actualChain="___run catcher catches C throw and returns err; marker kill occurs only on normal call path";
 attribute :>> hazard="Replacing this with unconditional rethrow changes boundary contract; kill may be skipped";
 attribute :>> replacement="Reuse catcher, persistent marker-ready state and common post-TRY settlement; code return distinct from resource disposition";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="run-real-startup-callers";
 attribute :>> sourceAnchors="lib/setup.c:763-835,6400-6443";
 attribute :>> actualChain="Child processor ___run error enters OP_PROCESSOR_0_THROW_ERROR collective and then sync service; startup ___run error triggers cleanup";
 attribute :>> hazard="Native exit guard must not swallow/relabel processor termination or skip final sync participation";
 attribute :>> replacement="Keep original coordination after guarded ___run returns; no independent-worker or nested-run admission claim";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="cfun-cleanup-bridge";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392";
 attribute :>> actualChain="cleanup? selects CFUN_BODY_CLEANUP TRY with W_ALL/R_ALL; AT_END and conversion-end releases occur on generator paths";
 attribute :>> hazard="A new SFUN guard cannot replace intermediate native cleanup or assume AT_END has no callbacks";
 attribute :>> replacement="Retain or explicitly migrate each temporary/release origin and audit register reload at transport edges";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="marker-physical-clear";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564;lib/mem.c:1778-1821,684-825,6844-6850";
 attribute :>> actualChain="make marker can collect before proc copy; kill writes vector[0]=false and decrements still refcount; GC mark_rc is inside P0 branch";
 attribute :>> hazard="Frozen root view/independent worker cannot be bypassed by old direct marker store or RC addref";
 attribute :>> replacement="Root before allocation, logical activation close then authorized physical clear; source RC scan/teardown gap retained";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="processor-return-order";
 attribute :>> sourceAnchors="lib/_kernel.scm:1034-1064,1838-1849;lib/_thread.scm:3127-3151";
 attribute :>> actualChain="Wrong-processor return routes through hook; _thread installs migration; invalid marker checked afterward";
 attribute :>> hazard="Changing check order changes hooks/errors; worker or processor identity alone is not a live original C activation";
 attribute :>> replacement="Preserve route ordering; owner-local authoritative return claim and generation reject stale/queued requests";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="scheme-winding";
 attribute :>> sourceAnchors="lib/_thread.scm:4794-4812,4915-4995";
 attribute :>> actualChain="Continuation winding invokes before/after procedures and uses their continuation/denv";
 attribute :>> hazard="A native finally callback could duplicate/reorder winds or retarget a packet already selected";
 attribute :>> replacement="Scheme retains winding; C packet selected at actual native catcher, settlement itself performs no Scheme callback";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="actual-tcl-nested-boundary";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-194,221-228,269-276";
 attribute :>> actualChain="Tcl command calls tcltk_call, Scheme may call tcltk_eval whose error calls tcltk_eval_error c-define; result string handed to Tcl";
 attribute :>> hazard="This is a real nested callback route but does not prove arbitrary cross-Tcl continuation unwind is legal";
 attribute :>> replacement="Explicit library-boundary policy, per-invocation root/native-string custody; no fabricated TCL_OK result";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="host-server-and-memory-callback";
 attribute :>> sourceAnchors="tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> actualChain="Server c-define returns string and catches errors in Scheme; memory example passes function-valued hop to C foo";
 attribute :>> hazard="Source is an actual generator consumer, not a native acceptance run or nested continuation witness";
 attribute :>> replacement="Use to instantiate typed native-result/function origin profiles; preserve Scheme error-to-string policy";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Guard placement";
 attribute :>> removedWork="Cover all SFUN entry/conversion/body/error/result edges";
 attribute :>> bound="One stable guard record per admitted SFUN invocation across all 3 result families";
 attribute :>> addedCost="New enclosing catch boundary, rooted slots and generator descriptors";
 attribute :>> condition="Guard after marker or only around ___call is incomplete; emitted code and target ABI remain unqualified";
 }
 part cost1 : CostRow {
 attribute :>> capability="___run reuse";
 attribute :>> removedWork="Close skipped marker cleanup without changing root error contract";
 attribute :>> bound="Reuse existing TRY/catcher; one common outcome settlement per admitted ___run";
 attribute :>> addedCost="Persistent marker-ready/result/error bookkeeping";
 attribute :>> condition="No extra catcher is inherently required; child processor collective and startup cleanup remain";
 }
 part cost2 : CostRow {
 attribute :>> capability="Nested escape";
 attribute :>> removedWork="Settle each abandoned activation exactly once";
 attribute :>> bound="k escaped frames -> k logical marker closes and O(k) bounded guard operations; target excluded";
 attribute :>> addedCost="Per-frame guarded duty/root/catcher transfer and qualified CFUN bridges";
 attribute :>> condition="No O(k) bound on arbitrary native finalizers or Scheme winding; these are outside the bounded guard";
 }
 part cost3 : CostRow {
 attribute :>> capability="Root/init custody";
 attribute :>> removedWork="Remove dependency on C automatic locals after longjmp";
 attribute :>> bound="Transfer ownership of existing stable cells, not copies of moving SCMOBJ payloads";
 attribute :>> addedCost="O(d+R) record/root capacity for depth d and additional live roots R";
 attribute :>> condition="Nonzero-processor RC scan and physical cleanup transfer not proven; changed nonvolatile locals are not ledger";
 }
 part cost4 : CostRow {
 attribute :>> capability="Logical versus physical marker";
 attribute :>> removedWork="Avoid direct heap writes under frozen collector view";
 attribute :>> bound="1 logical close per escaped activation; physical clear/refcount release performed once later under permission";
 attribute :>> addedCost="Authoritative return validation and deferred-clear duty; marker/procedure roots stay live longer";
 attribute :>> condition="Requires kernel return-check and kill path redesign; logical close alone is not actual body mutation proof";
 }
 part cost5 : CostRow {
 attribute :>> capability="Committed result";
 attribute :>> removedWork="Preserve native authority despite exceptional delivery";
 attribute :>> bound="0 new native production or wrapper commit on outcome query; 0 rollback of already committed right";
 attribute :>> addedCost="Canonical record acquire, generation check, result/code/native leases";
 attribute :>> condition="A rooted result does not authorize return into dead marker or cancel existing borrower obligations";
 }
 part cost6 : CostRow {
 attribute :>> capability="Existing bridges";
 attribute :>> removedWork="Share settlement without duplicating cleanup machinery";
 attribute :>> bound="Existing CFUN TRY and conversion-release support reused where exact effects qualify";
 attribute :>> addedCost="Audit custom AT_END, every temporary and native-library crossing";
 attribute :>> condition="Cannot retire CFUN cleanup as a class; arbitrary library stack escape still rejected";
 }
 part cost7 : CostRow {
 attribute :>> capability="Critical progress";
 attribute :>> removedWork="Bound admitted guard settlement independently of GC/owner callback completion";
 attribute :>> bound="Remove only admitted reverse wait; guard performs no allocation, Scheme callback or destructor";
 attribute :>> addedCost="Pre-reserved metadata/deferred-clear budget; later service drain";
 attribute :>> condition="Unknown managed writer/layout is pre-entry rejection or violated-premise fail-stop, not false recovery; no liveness/fairness proof";
 }
 part cost8 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Reuse one canonical record/right across body, error and escape";
 attribute :>> bound="Peak=max_t(H+P+N+Q); no credit refund at logical close, result ACK or C frame pop";
 attribute :>> addedCost="Retained marker/procedure/error/results and stopped-init/native backing; physical pool size charged once";
 attribute :>> condition="Record layouts unknown; whole-round peak reduction unproven; bounded reservation may exhaust and reject entry";
 }
 part cost9 : CostRow {
 attribute :>> capability="Modern C net benefit";
 attribute :>> removedWork="Retire normal-tail-only SFUN/___run settlement for qualified cohort";
 attribute :>> bound="0 production paths retired in this research; scheme semantics and C ABI retained as proof obligations";
 attribute :>> addedCost="Generated exit/root metadata, one shared C guard/custody service and C-memory refinement";
 attribute :>> condition="Positive runtime gain requires removed wait/replay work to exceed guard/scan/retention costs; no measured speedup or incremental Zig advantage";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="entry"; attribute :>> labelText="Scheme emits typed entry / exit plan\\nroots + stable owner record before marker"; }
 part node1 : DiagramNode { attribute :>> nodeId="calls"; attribute :>> labelText="___call trampoline and SFUN conversions\\nScheme winding / error handlers may nest"; }
 part node2 : DiagramNode { attribute :>> nodeId="packet"; attribute :>> labelText="Capture actual native transport\\noriginal owner + rooted destination"; }
 part node3 : DiagramNode { attribute :>> nodeId="guard"; attribute :>> labelText="Bounded no-callback guard\\nstop writer, retain roots, transfer duty"; }
 part node4 : DiagramNode { attribute :>> nodeId="close"; attribute :>> labelText="Logical activation close\\nexactly once; target excluded"; }
 part node5 : DiagramNode { attribute :>> nodeId="catcher"; attribute :>> labelText="Restore previous catcher before propagation\\nkeep current GVM destination coordinate"; }
 part node6 : DiagramNode { attribute :>> nodeId="bridge"; attribute :>> labelText="Qualified CFUN/native bridge cleanup\\nretain existing temporary/effect obligations"; }
 part node7 : DiagramNode { attribute :>> nodeId="target"; attribute :>> labelText="Matching ___call consumes destination\\n___run returns code through original caller"; }
 part node8 : DiagramNode { attribute :>> nodeId="service"; attribute :>> labelText="Authorized root/heap writer\\nphysical marker clear + deferred duty drain"; }
 part node9 : DiagramNode { attribute :>> nodeId="result"; attribute :>> labelText="Canonical committed result retained\\nquery only; no rollback or replay"; }
 part node10 : DiagramNode { attribute :>> nodeId="reject"; attribute :>> labelText="Unknown managed stop / layout / legal unwind\\nreject admission or fail-stop violated premise"; }
 part node11 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C-memory obligations open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="guard encloses all phases"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="actual caught transport"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="nonmatching or error"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="stable custody first"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="no stale fp restore"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="propagate exact packet"; }
 part edge6 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node2; attribute :>> labelText="next abandoned boundary"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="only after bridge settled"; }
 part edge8 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node8; attribute :>> labelText="physical clear deferred"; }
 part edge9 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node9; attribute :>> labelText="commit survives escape"; }
 part edge10 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node7; attribute :>> labelText="live target still required"; }
 part edge11 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node10; attribute :>> labelText="unsafe premise"; }
 part edge12 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node10; attribute :>> labelText="reject before native entry"; }
 part edge13 : DiagramEdge { ref :>> producer=node11; ref :>> consumer=node3; attribute :>> labelText="conditional model only"; }
}
