/* Modern C participating park design; no native acceptance. */
package GambitParticipatingParkRootView {
 private import ScalarValues::*;
 part def ParkState { attribute issued : Boolean; attribute safePoint : Boolean; attribute completeInit : Boolean; attribute materialized : Boolean; attribute rootView : Boolean; attribute effects : Integer; attribute writers : Integer; attribute unknownEffect : Boolean; attribute entryClosed : Boolean; attribute rootBacking : Boolean; attribute borrows : Integer; attribute nested : Integer; attribute mutatorPermit : Boolean; attribute vmAccepted : Boolean; attribute nativeFrame : Boolean; }
 requirement def ParkReceiptLaw { subject p : ParkState; require constraint { not p.issued or (p.safePoint and p.completeInit and p.materialized and p.rootView and p.effects==0 and p.writers==0 and not p.unknownEffect and p.entryClosed and p.rootBacking and p.borrows==0 and p.nested==0 and not p.mutatorPermit and p.vmAccepted and p.nativeFrame) } }
 part def ResumeState { attribute authorized : Boolean; attribute scannerReaders : Integer; attribute wholeRound : Boolean; attribute contextReady : Boolean; attribute ownerBound : Boolean; attribute reloaded : Boolean; attribute originalCallLive : Boolean; }
 requirement def SameInvocationResumeLaw { subject r : ResumeState; require constraint { not r.authorized or (r.scannerReaders==0 and r.wholeRound and r.contextReady and r.ownerBound and r.reloaded and r.originalCallLive) } }
 ref part inheritedLayout32=GambitManagedMarkerLayout::layout32;
 ref part inheritedLayout64=GambitManagedMarkerLayout::layout64;
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/participating_park_root_view.qnt";
 attribute :>> subjectScope="participating_park_root_view:36-named-histories;admitted;clean+debts;epochs0and1;seed=17;each100x100";
 attribute :>> premise="One live native invocation and root-cell view, bounded one effect/writer/borrow/nested debt, root relocation and two epochs; safe-point completeness, construction maps, native frame survival, coherent atomics and complete adapter census are premises; nonexhaustive finite simulation, not C source or liveness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="GambitSMP.ParticipatingParkRootView:safePointRequired;constructionRequired;materializationRequired;inFlightRejects;writerRejects;borrowRejects;nestedRejects;unknownRejects;deadFrameRejects;offerPreserves;acceptPreserves;claimPreserves;movePreserves;releasePreserves;reloadPreserves;resumePreserves;resumeDoesNotReinvoke;freezePermitsCollectorMutation;relocatedCacheNeedsReload;lostResponseKeepsAcceptance;lostResponseKeepsBacking;lostResponsePreserves;roundRequired;scannerBlocksResume;staleEpochRejects;stepPreserves;tracePreserves";
 attribute :>> premise="27 conditional declarations: Eligible boundary exclusions, exclusive mutator/collector root-cell authority, relocation/cache refresh, same-invocation resume and View Step/Trace preservation; separate Ready and Boundary premises; no complete QNT/C/ABI simulation or native weak-memory proof";
 }
 part safePoint : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-SAFE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="PP-SAFE:actual-source-refinement";
 attribute :>> premise="ParticipatingParkReceipt requires a generated SafePointSpec with return PointId, FrameSpec and initialized-field map after all relevant writes, complete continuation frame and register/saved/native root materialization; ___W_ALL is module/procedure-specific GVM state transfer, not arbitrary C stack scanning; rest/keyword construction calls W_ALL before complete frames are built, so that location cannot issue a receipt; retain Scheme completion plan or reject until scan-safe";
 }
 part rootView : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-ROOT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="PP-ROOT:actual-source-refinement";
 attribute :>> premise="Freeze root topology, writer admission and backing lifetime, not immutable SCMOBJ values; collector owns updateable canonical root cells while owner is parked; include continuation/frame map, registers, saved/type-cache/processor roots, all RC domains, generated native handles, marker and construction roots; publish after last writer and permit release, scan only after canonical VM acceptance; nonzero RC scan and raw cached SCMOBJ aliases remain open source obligations";
 }
 part exclusion : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-EXCLUDE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="PP-EXCLUDE:actual-source-refinement";
 attribute :>> premise="Retain the existing native invocation stack/catcher/code/result/input envelope, but reconcile every GC-relevant effect, raw root borrower, helper and nested activation before park; closing entry cannot revoke issued stores; native-only external operation may remain active only under separately proved no-managed-access and no-GC-critical-wait profile, not by renaming its count zero; unqualified or unknown relevant operation retains source debt and blocks receipt";
 }
 part receipt : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-RECEIPT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="PP-RECEIPT:actual-source-refinement";
 attribute :>> premise="Source retains root/native/pool custody through Prepare and Offer; canonical VM accept under scan/resume exclusion transfers control responsibility and signs identity-bound ParticipatingParkReceipt for same live activation, park attempt, epoch, SafePointSpec, root view, borrow census and native-frame lease; release/acquire publication precedes scanning; lost acceptance ACK is resolved by protected canonical query, never permit restoration, task replay or disposal";
 }
 part resume : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-RESUME";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="PP-RESUME:actual-source-refinement";
 attribute :>> premise="Resume same native invocation only after scan claim/release, whole strong/weak/cleanup/capacity result, context preparation, exact same live native owner/VM incarnation binding and relocated-root reload; scan claim and resume claim share atomic state arbitration; acquire fresh next-epoch write permit before resumed managed access, retire old scan capability and root view only after readers drain; notification, receipt ACK or GC request alone does not authorize reentry";
 }
 part semantics : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-SEMANTICS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="PP-SEMANTICS:actual-source-refinement";
 attribute :>> premise="Preserve synchronous Tcl char-string result and borrowed argv while Scheme body reaches a real safe point, not callback replay or invented pending return; nested callbacks need complete activation-stack census and LIFO native/catcher roots; exception/continuation escape is a separate same-owner exit path whose guard settles park/result/marker debt before native stack destruction; helper longjmp, arbitrary thread death and uninstrumented foreign stack movement cannot qualify same-call resume";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="PP-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/ParticipatingParkRootView.lean";
 attribute :>> subjectScope="PP-ORDER:actual-C-memory-and-adapter-refinement";
 attribute :>> premise="Owner closes new admission under shared registry exclusion; last relevant effect/borrow completion and generated materialization precede release-published root-view offer, canonical park acceptance and acquire scan claim; collector root updates precede release scan completion and owner acquire reload; whole-round context/binding precede fresh epoch permit and resume claim; scan claim, cancellation/exit and resume arbitrate on one canonical state, no mutex held while awaiting owner/GC callback; actual C layout, lock order, weak-memory and raw adapter coverage remain open";
 }
 ref part priorIssuance=GambitFutureEpochReentryGate::issuance;
 ref part priorQueue=GambitFutureEpochReentryGate::queueCut;
 ref part priorCustody=GambitFutureEpochReentryGate::custody;
 ref part priorSemantics=GambitFutureEpochReentryGate::semantics;
 ref part priorReentry=GambitFutureEpochReentryGate::reentry;
 ref part priorOrder=GambitFutureEpochReentryGate::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootView; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootView; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootView; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exclusion; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exclusion; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exclusion; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=priorIssuance; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=exclusion; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootView; ref part :>> prerequisite=priorCustody; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exclusion; ref part :>> prerequisite=priorQueue; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=rootView; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=exclusion; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=priorReentry; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=receipt; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=priorSemantics; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=safePoint; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=semantics; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootView; ref part :>> prerequisite=safePoint; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exclusion; ref part :>> prerequisite=priorIssuance; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=priorCustody; }
 part safePointRoute : GambitHostRootsRefinement::Route { ref part :>> need=safePoint;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2132-2168;include/gambit.h.in:6801-6803,6983-6991,7058-7091;lib/_kernel.c:9017-9020,12117-12120;lib/_kernel.scm:270-285,306-338,1960-1978;include/gambit.h.in:8514-8554;lib/_kernel.scm:1428-1444;lib/setup.c:1049-1149,1182-1200;lib/_kernel.scm:536-575,908-942;lib/mem.c:1487-1500,1677-1693,1778-1821;lib/c_intf.c:6509-6564";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="ParticipatingParkReceipt requires a generated SafePointSpec with return PointId, FrameSpec and initialized-field map after all relevant writes, complete continuation frame and register/saved/native root materialization; ___W_ALL is module/procedure-specific GVM state transfer, not arbitrary C stack scanning; rest/keyword construction calls W_ALL before complete frames are built, so that location cannot issue a receipt; retain Scheme completion plan or reject until scan-safe";
 attribute :>> failureCustodian="Source pins root/native backing until canonical acceptance; accepted VM owns park control even if ACK lost, native owner retains live stack/catcher lease; unknown relevant effect blocks receipt, unknown scan/round/context blocks resume; query never replays or refunds; dead native invocation cannot resume";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part rootViewRoute : GambitHostRootsRefinement::Route { ref part :>> need=rootView;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2132-2168;include/gambit.h.in:6801-6803,6983-6991,7058-7091;lib/_kernel.c:9017-9020,12117-12120;lib/mem.c:1487-1500,1677-1693,1778-1821;lib/c_intf.c:6509-6564;lib/mem.c:3898-3966;lib/mem.c:6511-6574,6844-6867;lib/mem.c:684-825,3969-3987,6844-6850";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Freeze root topology, writer admission and backing lifetime, not immutable SCMOBJ values; collector owns updateable canonical root cells while owner is parked; include continuation/frame map, registers, saved/type-cache/processor roots, all RC domains, generated native handles, marker and construction roots; publish after last writer and permit release, scan only after canonical VM acceptance; nonzero RC scan and raw cached SCMOBJ aliases remain open source obligations";
 attribute :>> failureCustodian="Source pins root/native backing until canonical acceptance; accepted VM owns park control even if ACK lost, native owner retains live stack/catcher lease; unknown relevant effect blocks receipt, unknown scan/round/context blocks resume; query never replays or refunds; dead native invocation cannot resume";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part exclusionRoute : GambitHostRootsRefinement::Route { ref part :>> need=exclusion;
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-175,221-228;include/gambit.h.in:10043-10064;gsc/_ptree2.scm:2902-3030,3145-3187;lib/setup.c:170-204,365-393,396-419;lib/_kernel.scm:4503-4519;lib/os_io.c:1472-1503,1532-1549;lib/setup.c:3276-3391;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;include/gambit.h.in:10043-10064;lib/setup.c:3393-3420,4665-4672;examples/tcltk/tcltk.scm:178-194;lib/setup.c:924-980,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Retain the existing native invocation stack/catcher/code/result/input envelope, but reconcile every GC-relevant effect, raw root borrower, helper and nested activation before park; closing entry cannot revoke issued stores; native-only external operation may remain active only under separately proved no-managed-access and no-GC-critical-wait profile, not by renaming its count zero; unqualified or unknown relevant operation retains source debt and blocks receipt";
 attribute :>> failureCustodian="Source pins root/native backing until canonical acceptance; accepted VM owns park control even if ACK lost, native owner retains live stack/catcher lease; unknown relevant effect blocks receipt, unknown scan/round/context blocks resume; query never replays or refunds; dead native invocation cannot resume";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part receiptRoute : GambitHostRootsRefinement::Route { ref part :>> need=receipt;
 attribute :>> sourceAnchors="lib/_kernel.scm:1428-1444;lib/setup.c:1049-1149,1182-1200;lib/mem.c:3898-3966;lib/mem.c:684-825,3969-3987,6844-6850;lib/setup.c:170-204,365-393,396-419;lib/setup.c:3276-3391;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;lib/setup.c:924-980,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Source retains root/native/pool custody through Prepare and Offer; canonical VM accept under scan/resume exclusion transfers control responsibility and signs identity-bound ParticipatingParkReceipt for same live activation, park attempt, epoch, SafePointSpec, root view, borrow census and native-frame lease; release/acquire publication precedes scanning; lost acceptance ACK is resolved by protected canonical query, never permit restoration, task replay or disposal";
 attribute :>> failureCustodian="Source pins root/native backing until canonical acceptance; accepted VM owns park control even if ACK lost, native owner retains live stack/catcher lease; unknown relevant effect blocks receipt, unknown scan/round/context blocks resume; query never replays or refunds; dead native invocation cannot resume";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part resumeRoute : GambitHostRootsRefinement::Route { ref part :>> need=resume;
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-175,221-228;gsc/_t-c-1.scm:2132-2168;include/gambit.h.in:6801-6803,6983-6991,7058-7091;lib/_kernel.c:9017-9020,12117-12120;lib/_kernel.scm:1428-1444;lib/setup.c:1049-1149,1182-1200;lib/mem.c:6511-6574,6844-6867;lib/setup.c:3276-3391;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;lib/mem.c:4525-4567,7003-7085;lib/os_thread.c:697-710;lib/setup.c:924-980,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Resume same native invocation only after scan claim/release, whole strong/weak/cleanup/capacity result, context preparation, exact same live native owner/VM incarnation binding and relocated-root reload; scan claim and resume claim share atomic state arbitration; acquire fresh next-epoch write permit before resumed managed access, retire old scan capability and root view only after readers drain; notification, receipt ACK or GC request alone does not authorize reentry";
 attribute :>> failureCustodian="Source pins root/native backing until canonical acceptance; accepted VM owns park control even if ACK lost, native owner retains live stack/catcher lease; unknown relevant effect blocks receipt, unknown scan/round/context blocks resume; query never replays or refunds; dead native invocation cannot resume";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part semanticsRoute : GambitHostRootsRefinement::Route { ref part :>> need=semantics;
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-175,221-228;include/gambit.h.in:10043-10064;gsc/_ptree2.scm:2902-3030,3145-3187;lib/_kernel.scm:536-575,908-942;lib/mem.c:1487-1500,1677-1693,1778-1821;lib/c_intf.c:6509-6564;lib/_kernel.scm:4503-4519;lib/os_io.c:1472-1503,1532-1549;lib/setup.c:3276-3391;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;include/gambit.h.in:10043-10064;lib/setup.c:3393-3420,4665-4672;examples/tcltk/tcltk.scm:178-194";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Preserve synchronous Tcl char-string result and borrowed argv while Scheme body reaches a real safe point, not callback replay or invented pending return; nested callbacks need complete activation-stack census and LIFO native/catcher roots; exception/continuation escape is a separate same-owner exit path whose guard settles park/result/marker debt before native stack destruction; helper longjmp, arbitrary thread death and uninstrumented foreign stack movement cannot qualify same-call resume";
 attribute :>> failureCustodian="Source pins root/native backing until canonical acceptance; accepted VM owns park control even if ACK lost, native owner retains live stack/catcher lease; unknown relevant effect blocks receipt, unknown scan/round/context blocks resume; query never replays or refunds; dead native invocation cannot resume";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-175,221-228;include/gambit.h.in:10043-10064;gsc/_ptree2.scm:2902-3030,3145-3187;gsc/_t-c-1.scm:2132-2168;include/gambit.h.in:6801-6803,6983-6991,7058-7091;lib/_kernel.c:9017-9020,12117-12120;lib/_kernel.scm:270-285,306-338,1960-1978;include/gambit.h.in:8514-8554;lib/_kernel.scm:1428-1444;lib/setup.c:1049-1149,1182-1200;lib/_kernel.scm:536-575,908-942;lib/mem.c:1487-1500,1677-1693,1778-1821;lib/c_intf.c:6509-6564;lib/mem.c:3898-3966;lib/mem.c:6511-6574,6844-6867;lib/mem.c:684-825,3969-3987,6844-6850;lib/setup.c:170-204,365-393,396-419;lib/_kernel.scm:4503-4519;lib/os_io.c:1472-1503,1532-1549;lib/setup.c:3276-3391;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;include/gambit.h.in:10043-10064;lib/setup.c:3393-3420,4665-4672;examples/tcltk/tcltk.scm:178-194;lib/mem.c:4525-4567,7003-7085;lib/os_thread.c:697-710;lib/setup.c:924-980,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Owner closes new admission under shared registry exclusion; last relevant effect/borrow completion and generated materialization precede release-published root-view offer, canonical park acceptance and acquire scan claim; collector root updates precede release scan completion and owner acquire reload; whole-round context/binding precede fresh epoch permit and resume claim; scan claim, cancellation/exit and resume arbitrate on one canonical state, no mutex held while awaiting owner/GC callback; actual C layout, lock order, weak-memory and raw adapter coverage remain open";
 attribute :>> failureCustodian="Source pins root/native backing until canonical acceptance; accepted VM owns park control even if ACK lost, native owner retains live stack/catcher lease; unknown relevant effect blocks receipt, unknown scan/round/context blocks resume; query never replays or refunds; dead native invocation cannot resume";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="synchronous-tcl-native-frame";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-175,221-228";
 attribute :>> actualChain="scheme_call_cmd -> tcltk_call(data_rc,argv+1) -> Scheme apply -> result C string installed in Tcl";
 attribute :>> hazard="Deferral/replay loses synchronous result, borrowed native args and original return stack";
 attribute :>> replacement="Retain same native activation/input/result/code leases; park only at admitted Scheme/generated boundary";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="sfun-conversion-before-call";
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10064;gsc/_ptree2.scm:2902-3030,3145-3187";
 attribute :>> actualChain="SFUN fetches PSTATE, allocates marker, converts and calls ___call; conversion errors can call Scheme handler";
 attribute :>> hazard="An entry gate in ___call is after marker allocation and raw root effects";
 attribute :>> replacement="Scheme generator emits origin/safe-point/exit plan; modern C ingress owns full conversion activation and root census";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="gvm-materialization";
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:2132-2168;include/gambit.h.in:6801-6803,6983-6991,7058-7091;lib/_kernel.c:9017-9020,12117-12120";
 attribute :>> actualChain="W_ALL selects generated M/P macros; supplied kernel output writes selected heap/fp/registers; R macros reload";
 attribute :>> hazard="Materializes specific GVM locals, not all arbitrary C roots or complete object initialization";
 attribute :>> replacement="SafePointSpec records actual required fields and maps; prove generated spill coverage and post-GC reload";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="heap-and-stack-safepoints";
 attribute :>> sourceAnchors="lib/_kernel.scm:270-285,306-338,1960-1978;include/gambit.h.in:8514-8554";
 attribute :>> actualChain="Stack/heap checks save RA and GVM regs, W_ALL, run limit/GC, R_ALL and restore RA";
 attribute :>> hazard="Reaching POLL/limit request is not itself completion of spill/root/initialization duties";
 attribute :>> replacement="Receipt cut after completion plan, not check predicate; use FrameSpec and exact resume PointId";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="sync-op-participation";
 attribute :>> sourceAnchors="lib/_kernel.scm:1428-1444;lib/setup.c:1049-1149,1182-1200";
 attribute :>> actualChain="sync interrupt saves RA/W_ALL -> service_sync_op -> barrier/combined operation loop; result delivered before R_ALL";
 attribute :>> hazard="Current processor is both execution context and collector participant; interrupt request alone cannot authorize independent worker";
 attribute :>> replacement="Split context freeze, participant acknowledgment and worker scan authority; preserve merged operation result/round identity";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="partial-rest-frame";
 attribute :>> sourceAnchors="lib/_kernel.scm:536-575,908-942";
 attribute :>> actualChain="Rest/keyword CONS loop W_ALL -> heap_limit -> R_ALL, then explicitly builds complete frames before GC";
 attribute :>> hazard="W_ALL before frame repair is a real inadmissible receipt location";
 attribute :>> replacement="Carry constructor progress/root plan through complete-frame cut or scan-safe shell; do not park at every W_ALL";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="still-and-marker-construction";
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1677-1693,1778-1821;lib/c_intf.c:6509-6564";
 attribute :>> actualChain="Still allocation links storage before caller field init; make marker allocates before copying input procedure with root TODO";
 attribute :>> hazard="Unknown initialization or unrooted moving input cannot be cured by park flag";
 attribute :>> replacement="Generated InitSpec with scan-safe fields and root-before-allocation; retain construction escrow until complete";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="continuation-stack-scanner";
 attribute :>> sourceAnchors="lib/mem.c:3898-3966";
 attribute :>> actualChain="mark_continuation reads ps.fp, return-specific frame size/link/gcmap and captured continuation";
 attribute :>> hazard="Native C stack is not this scanner; stale frame map/cursor or changed stack break loses roots";
 attribute :>> replacement="Frozen FrameSpec-backed topology and live native frame; collector updates described stack/heap root cells";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="register-saved-and-processor-roots";
 attribute :>> sourceAnchors="lib/mem.c:6511-6574,6844-6867";
 attribute :>> actualChain="mark_registers/saved/type_cache/processor scan actual PSTATE arrays after continuation";
 attribute :>> hazard="Freeze snapshot of SCMOBJ values becomes stale after relocation; descriptions and backing must survive";
 attribute :>> replacement="Exclusive updateable cells plus post-scan R_ALL/handle reload; participant-independent root adapter";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="rc-all-domain-root-gap";
 attribute :>> sourceAnchors="lib/mem.c:684-825,3969-3987,6844-6850";
 attribute :>> actualChain="RC data cells in per-PSTATE list are passed by address to mark_array; mark_rc selected in P0 branch";
 attribute :>> hazard="Nonzero RC coverage and raw data_rc setters/borrowers not solved by current P0 scan";
 attribute :>> replacement="All-domain RootRegistry enumerates stable RC backing and controlled access; freeze link topology and release old readers";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="queue-native-issue-cut";
 attribute :>> sourceAnchors="lib/setup.c:170-204,365-393,396-419";
 attribute :>> actualChain="Publisher spans queue unlock to PSTATE wakeup; service removes task before native execute_fn";
 attribute :>> hazard="Empty queue/closed entry misses claimed callback, late postlude and nested cleanup work";
 attribute :>> replacement="Import early ingress, publisher lease and dequeue-to-claim protocol; nested activation debt stays counted";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="device-wait-not-universal-park";
 attribute :>> sourceAnchors="lib/_kernel.scm:4503-4519;lib/os_io.c:1472-1503,1532-1549";
 attribute :>> actualChain="condvar select wrapper W_ALL before os select, R_ALL after return; select-abort writes wakeup pipe";
 attribute :>> hazard="Blocking syscall and wakeup do not establish root-view acceptance or arbitrary syscall interruption";
 attribute :>> replacement="Qualify native wait lock/effect/borrow profile; return to participating boundary or explicit no-managed-access native wait";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="native-catcher-and-return";
 attribute :>> sourceAnchors="lib/setup.c:3276-3391;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072";
 attribute :>> actualChain="___call saves marker/frame and installs stack catcher; return checks processor and live marker then unwinds";
 attribute :>> hazard="Moving to helper thread, repeated entry or destroying stack invalidates native return rights";
 attribute :>> replacement="Preserve same native thread/catcher lease, original call count and exception guard; no collector longjmp";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="nested-exit-and-cleanup";
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10064;lib/setup.c:3393-3420,4665-4672;examples/tcltk/tcltk.scm:178-194";
 attribute :>> actualChain="SFUN kill/propagate path, ___run catcher and Tcl delete release resources across native boundaries";
 attribute :>> hazard="Parked activation is not completed; deletion or inner return cannot retire outer root/catcher backing";
 attribute :>> replacement="Activation stack census, exit-vs-scan arbitration, deferred resource disposition and outer native-frame retention";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="round-completion-and-reload";
 attribute :>> sourceAnchors="lib/mem.c:4525-4567,7003-7085;lib/os_thread.c:697-710";
 attribute :>> actualChain="GC barriers, cleanup/resize/fudge then notify GC before prepare fp/hp/limits; binding function sets TLS/affinity";
 attribute :>> hazard="Notification or TLS pointer is not fresh context/root authorization";
 attribute :>> replacement="Whole-round/context/binding/root reload then atomic fresh permit; scanned root alone not complete round";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="owner-teardown-and-join";
 attribute :>> sourceAnchors="lib/setup.c:924-980,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> actualChain="PSTATE cleanup frees RC/still/OS state; thread join comes later and errors do not preserve canonical envelope";
 attribute :>> hazard="Death/failed join cannot prove arbitrary in-flight store stopped or native stack recoverable";
 attribute :>> replacement="Retain VM root/resource debt; known stop may allow cleanup but never resurrect dead native invocation; unknown refuses receipt/resume";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Same-call GC progress";
 attribute :>> removedWork="Avoid adding callback-completion wait when separating collector workers";
 attribute :>> bound="One admitted current invocation -> one park accept + one resume; extra native invocations=0";
 attribute :>> addedCost="SafePointSpec, root view, canonical park/scan/resume state";
 attribute :>> condition="Current Gambit already collects inside callbacks; this preserves that ability during worker separation, not a new measured speedup";
 }
 part cost1 : CostRow {
 attribute :>> capability="Safe-point precision";
 attribute :>> removedWork="Replace blanket W_ALL assumption with generated completion cut";
 attribute :>> bound="One complete spill/root/constructor map per park; no park at known incomplete rest frame";
 attribute :>> addedCost="Scheme completion plans, verifier and descriptor/code lifetime";
 attribute :>> condition="Actual generated spill and constructor coverage must close before old macro logic can retire";
 }
 part cost2 : CostRow {
 attribute :>> capability="Root storage";
 attribute :>> removedWork="Use described canonical cells instead of duplicating every root value";
 attribute :>> bound="Metadata O(A+R+D); root visit O(R); no mandatory O(reachable heap) snapshot";
 attribute :>> addedCost="A activations, R distinct root slots, D active native/effect obligations";
 attribute :>> condition="Alias census must be complete; caller-held copies require handles/reload, not an invented immutable value snapshot";
 }
 part cost3 : CostRow {
 attribute :>> capability="Native-call exclusion";
 attribute :>> removedWork="Drain only relevant issued effects, not require original native call return";
 attribute :>> bound="Native invocation stays live; GC-relevant effects/borrowers/nested writers must be0";
 attribute :>> addedCost="Effect/origin registry, completion evidence and lock dependency profile";
 attribute :>> condition="Native-only outstanding work requires separate isolation proof; unknown relevant work cannot become zero on timeout";
 }
 part cost4 : CostRow {
 attribute :>> capability="Canonical receipt";
 attribute :>> removedWork="Avoid retrying native operation after lost park acceptance ACK";
 attribute :>> bound="One canonical accept per park identity; query adds0 invocations";
 attribute :>> addedCost="Protected attempt/result lookup and retained source pins until resolution";
 attribute :>> condition="Failed preaccept retains source; accepted unknown response remains VM duty; no receipt reuse across attempts";
 }
 part cost5 : CostRow {
 attribute :>> capability="Collector authority";
 attribute :>> removedWork="Permit root rewriting while mutator is parked";
 attribute :>> bound="At most one modeled scan claim; no simultaneous mutator permit";
 attribute :>> addedCost="Release/acquire view, exclusive scan/resume state and reader drainage";
 attribute :>> condition="Full C order proof and independent-worker integration still open; no relaxed load shortcut";
 }
 part cost6 : CostRow {
 attribute :>> capability="Fresh reentry";
 attribute :>> removedWork="Avoid stale registers/handles after relocation";
 attribute :>> bound="One context prepare/bind/reload sequence per resumed park; starts stays1";
 attribute :>> addedCost="Whole-round result, root generation and exact owner incarnation";
 attribute :>> condition="Same native stack must remain alive; moving raw C catcher to different worker is refused";
 }
 part cost7 : CostRow {
 attribute :>> capability="Nested callbacks / exceptions";
 attribute :>> removedWork="Retain full activation chain instead of treating inner return as outer quiescence";
 attribute :>> bound="O(A) live activation/exit records; all relevant nested debts settle before park";
 attribute :>> addedCost="LIFO marker/catcher roots and exit-vs-scan arbitration";
 attribute :>> condition="Continuation escape uses generated exit guard; arbitrary native longjmp/unregistered roots reject profile";
 }
 part cost8 : CostRow {
 attribute :>> capability="Wait-cycle removal";
 attribute :>> removedWork="GC waits for park handoff rather than synchronous result completion";
 attribute :>> bound="Removes edge GC -> callback-finish when qualified park exists";
 attribute :>> addedCost="No GC-critical lock held by parked owner; cleanup/root dependencies explicit";
 attribute :>> condition="No universal latency or liveness bound; cleanup requiring owner entry must be delayed or rejected";
 }
 part cost9 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="No task payload duplication merely to park same call";
 attribute :>> bound="Peak=max_t(H+P+N+Q); delta inherited marker 24*M(t) plus park/view/log pools and longer retention";
 attribute :>> addedCost="Native stack, roots, code, borrowed inputs and unresolved resources stay charged";
 attribute :>> condition="No measured/proved peak decrease; unknown debt can retain backing indefinitely";
 }
 part cost10 : CostRow {
 attribute :>> capability="Retirement";
 attribute :>> removedWork="Replace direct managed entry / blanket park flag / unqualified PSTATE lifetime";
 attribute :>> bound="0 production paths retired; admitted cohort only after source/order/ABI obligations";
 attribute :>> addedCost="Scheme-generated safe-point/exit plans and typed modern C RootRegistry/AdmissionDomain";
 attribute :>> condition="Keep C portable backend; low-level W/R instructions may be generated internally, not falsely claimed eliminated";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C versus Zig";
 attribute :>> removedWork="Share semantic plans and typed lifetime protocol without second runtime language";
 attribute :>> bound="0 Zig-only runtime work elimination shown for park/root/native safety";
 attribute :>> addedCost="Both need same safepoint, borrow/scan, native stack, atomic and exception proofs";
 attribute :>> condition="Choose modern C mainline; CPU benefit needs actual removed baseline work > added protocol work; wait-cycle removal is a separate graph property, current cooperative GC already resumes in-call";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="call"; attribute :>> labelText="Same live native invocation\\nTcl -> SFUN -> Scheme"; }
 part node1 : DiagramNode { attribute :>> nodeId="close"; attribute :>> labelText="Close new entry / nested admission\\nexisting effects remain owed"; }
 part node2 : DiagramNode { attribute :>> nodeId="drain"; attribute :>> labelText="Safe point + complete init\\ndrain relevant writes / borrows"; }
 part node3 : DiagramNode { attribute :>> nodeId="spill"; attribute :>> labelText="Materialize RA / frames / roots\\nrevoke old mutator permit"; }
 part node4 : DiagramNode { attribute :>> nodeId="offer"; attribute :>> labelText="Offer updateable root view\\nsource keeps backing pins"; }
 part node5 : DiagramNode { attribute :>> nodeId="acceptPark"; attribute :>> labelText="Canonical VM acceptance\\nParticipatingParkReceipt"; }
 part node6 : DiagramNode { attribute :>> nodeId="scan"; attribute :>> labelText="Acquire scan claim\\ncollector may update root cells"; }
 part node7 : DiagramNode { attribute :>> nodeId="releaseScan"; attribute :>> labelText="Release scan / root readers\\nwhole-round result"; }
 part node8 : DiagramNode { attribute :>> nodeId="prepare"; attribute :>> labelText="Prepare context + same owner bind\\nreload relocated roots"; }
 part node9 : DiagramNode { attribute :>> nodeId="resumeCall"; attribute :>> labelText="Fresh next-epoch resume claim\\nsame native stack; starts stays1"; }
 part node10 : DiagramNode { attribute :>> nodeId="custody"; attribute :>> labelText="Native/root/code/result custody\\ntransfer is not release"; }
 part node11 : DiagramNode { attribute :>> nodeId="refuse"; attribute :>> labelText="Unknown relevant write / dead frame\\nretain debt; refuse unsafe receipt"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C-order gaps open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="original stack and result contract"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="close does not revoke issued work"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="complete maps and census"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="last write before publication"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="atomic accept; ACK may be lost"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="acquire complete view"; }
 part edge6 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="write back relocated roots"; }
 part edge7 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="round readiness, not notification"; }
 part edge8 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="exclusive claim before managed access"; }
 part edge9 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node4; attribute :>> labelText="source pins before acceptance"; }
 part edge10 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node5; attribute :>> labelText="VM control; native owner still live"; }
 part edge11 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node9; attribute :>> labelText="backing retained across GC"; }
 part edge12 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node10; attribute :>> labelText="reserve roots/resources/code"; }
 part edge13 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node11; attribute :>> labelText="unknown effect / borrow / construction"; }
 part edge14 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node11; attribute :>> labelText="unknown acceptance -> query, no replay"; }
 part edge15 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node11; attribute :>> labelText="dead/mismatched owner or stale root"; }
 part edge16 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node5; attribute :>> labelText="conditional receipt obligations"; }
 part edge17 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node9; attribute :>> labelText="fresh authority + no reinvocation"; }
}
