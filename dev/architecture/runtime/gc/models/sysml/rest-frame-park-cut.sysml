/* Modern generated C rest construction/park cut research; no native acceptance. */
package GambitRestFrameParkCut {
 private import ScalarValues::*;
 part def ConstructionCut { attribute issued : Boolean; attribute remaining : Integer; attribute vectorComplete : Boolean; attribute fullFrame : Boolean; attribute mapped : Boolean; attribute rootLease : Boolean; attribute entryClosed : Boolean; attribute rawBorrowers : Integer; attribute writers : Integer; attribute unknownWrite : Boolean; attribute exactSpillGeneration : Boolean; attribute nativeFrameLive : Boolean; attribute vmAccepted : Boolean; attribute capacityGranted : Boolean; }
 requirement def RestParkReceiptLaw { subject c : ConstructionCut; require constraint { not c.issued or (c.remaining==0 and c.vectorComplete and c.fullFrame and c.mapped and c.rootLease and c.entryClosed and c.rawBorrowers==0 and c.writers==0 and not c.unknownWrite and c.exactSpillGeneration and c.nativeFrameLive and c.vmAccepted and c.capacityGranted) } }
 part def TerminalState { attribute normalClaims : Integer; attribute exitClaims : Integer; attribute pendingExit : Boolean; attribute scanning : Boolean; }
 requirement def TerminalIntentLaw { subject t : TerminalState; require constraint { t.normalClaims+t.exitClaims<=1 and (t.normalClaims==0 or not t.pendingExit) and (t.exitClaims==0 or t.pendingExit) and (not t.scanning or t.normalClaims+t.exitClaims==0) } }
 part def RepairBound { attribute actual : Integer; attribute formal : Integer; attribute remaining : Integer; attribute pairBody : Integer; attribute vectorBody : Integer; attribute wordBytes : Integer; attribute pairWords : Integer=2+pairBody; attribute completionWords : Integer=remaining*pairWords+formal+vectorBody; attribute completionBytes : Integer=completionWords*wordBytes; attribute vectorWords : Integer=formal+vectorBody; }
 part repairW4R0B1 : RepairBound { attribute :>> actual=4; attribute :>> formal=1; attribute :>> remaining=3; attribute :>> pairBody=1; attribute :>> vectorBody=1; attribute :>> wordBytes=4; }
 part repairW4R0B2 : RepairBound { attribute :>> actual=4; attribute :>> formal=1; attribute :>> remaining=3; attribute :>> pairBody=2; attribute :>> vectorBody=2; attribute :>> wordBytes=4; }
 part repairW4R1B1 : RepairBound { attribute :>> actual=4; attribute :>> formal=2; attribute :>> remaining=2; attribute :>> pairBody=1; attribute :>> vectorBody=1; attribute :>> wordBytes=4; }
 part repairW4R1B2 : RepairBound { attribute :>> actual=4; attribute :>> formal=2; attribute :>> remaining=2; attribute :>> pairBody=2; attribute :>> vectorBody=2; attribute :>> wordBytes=4; }
 part repairW8R0B1 : RepairBound { attribute :>> actual=4; attribute :>> formal=1; attribute :>> remaining=3; attribute :>> pairBody=1; attribute :>> vectorBody=1; attribute :>> wordBytes=8; }
 part repairW8R0B2 : RepairBound { attribute :>> actual=4; attribute :>> formal=1; attribute :>> remaining=3; attribute :>> pairBody=2; attribute :>> vectorBody=2; attribute :>> wordBytes=8; }
 part repairW8R1B1 : RepairBound { attribute :>> actual=4; attribute :>> formal=2; attribute :>> remaining=2; attribute :>> pairBody=1; attribute :>> vectorBody=1; attribute :>> wordBytes=8; }
 part repairW8R1B2 : RepairBound { attribute :>> actual=4; attribute :>> formal=2; attribute :>> remaining=2; attribute :>> pairBody=2; attribute :>> vectorBody=2; attribute :>> wordBytes=8; }
 ref part inheritedLayout32=GambitManagedMarkerLayout::layout32;
 ref part inheritedLayout64=GambitManagedMarkerLayout::layout64;
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/rest_frame_park_cut.qnt";
 attribute :>> subjectScope="rest_frame_park_cut:40-named-histories;admitted;req0+req1-debts;four-args;epochs0and1;seed=17;each100x100";
 attribute :>> premise="One existing invocation, four logical argument identities, zero/one required argument, real rest list ordering and vector-slot completion, one raw borrow/pre-close writer, pending exit, exclusive scan/normal/exit claims and epochs0/1; physical capacity, complete ingress/root census, generated map and coherent C atomics remain premises; nonexhaustive, no native execution or liveness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="GambitSMP.RestFrameParkCut:consPreserves;completionHasExactRest;completedPairCount;popAndPrependPreservesOrder;concreteRestOrder;repairWordsExact;actualRestFourNoHandles;actualRestFixedNoHandles;partialRestRejects;partialVectorRejects;missingMapRejects;rawBorrowRejects;lateWriterRejects;unknownWriteRejects;staleSpillRejects;deadNativeFrameRejects;missingCapacityRejects;acceptPreserves;loseResponsePreserves;lostResponseKeepsAcceptance;scanPreserves;movePreserves;finishScanPreserves;reloadPreserves;normalPreserves;exitPreserves;requestPreserves;pendingExitBlocksNormal;unrequestedExitRejected;resumeDoesNotReinvoke;resumeDoesNotRecons;normalExcludesExit;scanBlocksTerminalClaim;missingWholeRoundRejects;stepPreserves;tracePreserves";
 attribute :>> premise="36 conditional declarations: argument/pair conservation, pop-prepend order, completion-word arithmetic, rest/frame/borrow/generation eligibility, canonical response preservation and exclusive scan/normal/exit Authority Step/Trace; not all QNT actions, actual C frame decoding or ABI/source simulation";
 }
 part safePoint : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-SAFE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="RF-SAFE:actual-source-refinement";
 attribute :>> premise="Source chain GET_REST -> handler7 -> finish remaining CONS -> fully initialize packed vector -> two-argument Scheme helper -> save R0/proc/args and install return frame -> FRAME_STORE_RA/W_ALL -> actual GC; first W_ALL calls noncollecting heap_limit before repair and is ineligible for park; generated RestConstructionPlan binds exact progress, complete-frame PointId/FrameSpec and scan map, not arbitrary partial C stack locals";
 }
 part rootView : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-ROOT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="RF-ROOT:actual-source-refinement";
 attribute :>> premise="Reserve a construction lease before destructive argument pops; no collecting/reentrant call while partial argument stack/vector lacks complete scan layout; keep partial rest, remaining/required arguments, proc/temp1 and original continuation under exclusive source custody; transfer proc/packed-vector to generated register/frame roots before local scope ends; collector-updateable cells and fresh post-GC handle reload, plus marker/native ancestor roots; all-domain RC/raw alias integration remains open";
 }
 part exclusion : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-EXCLUDE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="RF-EXCLUDE:actual-source-refinement";
 attribute :>> premise="Close new native root borrowers and writers under same registry cut; pre-close writer remains counted through its actual final effect, then materialize matching root generation; relevant borrowed moving values must drain or use admitted stable handles, native-only argv/code/result backing can remain leased; a queued/issued store cannot be revoked by entry closure; late write after receipt invalidates protocol and requires exclusion proof, unknown result retains source duty and blocks receipt";
 }
 part receipt : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-RECEIPT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="RF-RECEIPT:actual-source-refinement";
 attribute :>> premise="FrameReady after full vector initialization, full mapped Scheme call frame, RA/GVM spill, exact root generation and native-frame/capacity lease precedes release-published offer; source pins until canonical VM accept, lost ACK does not restore old authority; one park attempt owns scan/resume/exit arbitration; offer is not scanner permission; no side-effecting rollback or duplicate constructor from unknown acceptance";
 }
 part resume : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-RESUME";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="RF-RESUME:actual-source-refinement";
 attribute :>> premise="After scan/root readers drain, whole-round/capacity result, context preparation, same live owner binding and relocated-root reload, claim exactly one normal or exit authority in next epoch; normal branch reloads the same packed vector and proc, restores np arguments, sets nargs=-1 and jumps target, so GET_REST cannot rebuild the rest list; same original native invocation/catcher continues, no replay or helper-thread longjmp";
 }
 part semantics : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-SEMANTICS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="RF-SEMANTICS:actual-source-refinement";
 attribute :>> premise="Ordinary exception/continuation request during unscannable repair is latched until mandatory bounded completion and root handoff; do not call arbitrary Scheme handler in partial-frame zone; after scan/round readiness atomically choose normal resume only without pending exit, or generated same-owner exit guard only with pending exit, never both; current heap-overflow helper may raise and retry GC while retaining proc/args; request epochs and park attempts must not consume a stale receipt; unmanaged asynchronous nonlocal escape/dead stack is rejected, not silently translated to managed cancel";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RF-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/RestFrameParkCut.lean";
 attribute :>> subjectScope="RF-ORDER:actual-C-memory-and-adapter-refinement";
 attribute :>> premise="Preflight physically reserves repair words, stack/frame and root/control metadata before pops; close new native writer/borrow admission, settle actual old final effects, complete vector and FrameSpec/GVM writes, release-publish offer, canonical accept/acquire scan; scanner writes release before whole-round/context/binding/acquire reload; exclusive fresh normal/exit claim prevents late scan and duplicate nargs resume; all raw aliases share the cut; no locks held across owner/GC wait; actual C atomic layout, helper visibility and native ABI refinement remain open";
 }
 ref part priorSafe=GambitParticipatingParkRootView::safePoint;
 ref part priorRoots=GambitParticipatingParkRootView::rootView;
 ref part priorExclusion=GambitParticipatingParkRootView::exclusion;
 ref part priorReceipt=GambitParticipatingParkRootView::receipt;
 ref part priorResume=GambitParticipatingParkRootView::resume;
 ref part priorOrder=GambitParticipatingParkRootView::order;
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
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=priorSafe; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=rootView; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootView; ref part :>> prerequisite=priorRoots; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exclusion; ref part :>> prerequisite=priorExclusion; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=priorReceipt; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=rootView; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=receipt; ref part :>> prerequisite=exclusion; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=priorResume; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=receipt; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=safePoint; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=exclusion; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=semantics; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootView; ref part :>> prerequisite=priorExclusion; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=safePoint; ref part :>> prerequisite=exclusion; }
 part safePointRoute : GambitHostRootsRefinement::Route { ref part :>> need=safePoint;
 attribute :>> sourceAnchors="tests/mix.scm:703-706,775-782;tests/test5.ok:15745-15772;gsc/_t-c-2.scm:718-772;include/gambit.h.in:8170-8193;lib/setup.c:4740,5235;lib/_kernel.scm:491-535;include/gambit.h.in:6995-7033;lib/_kernel.scm:536-545;include/gambit.h.in:3149-3153,5313-5325;lib/_kernel.scm:546-559;lib/mem.c:7428-7505,4525-4567;lib/_kernel.scm:560-576;lib/mem.h:63-78;lib/_kernel.scm:577-590;include/gambit.h.in:3160-3167;lib/_kernel.scm:1992-2000;lib/_kernel.c:16779-16826,30101-30104;lib/mem.c:3823-3966,6511-6574;lib/_kernel.scm:2030-2048";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Source chain GET_REST -> handler7 -> finish remaining CONS -> fully initialize packed vector -> two-argument Scheme helper -> save R0/proc/args and install return frame -> FRAME_STORE_RA/W_ALL -> actual GC; first W_ALL calls noncollecting heap_limit before repair and is ineligible for park; generated RestConstructionPlan binds exact progress, complete-frame PointId/FrameSpec and scan map, not arbitrary partial C stack locals";
 attribute :>> failureCustodian="Source retains partial list/arguments and physical repair lease until completed frame accepted; VM canonical park owns scan control after accept even if ACK lost; same native owner keeps live stack/catcher; unknown relevant write/capacity blocks receipt, scan/context unknown blocks terminal claim; no replay, re-CONS, guessed refund or worker longjmp";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part rootViewRoute : GambitHostRootsRefinement::Route { ref part :>> need=rootView;
 attribute :>> sourceAnchors="lib/_kernel.scm:491-535;include/gambit.h.in:6995-7033;lib/_kernel.scm:536-545;include/gambit.h.in:3149-3153,5313-5325;lib/_kernel.scm:577-590;include/gambit.h.in:3160-3167;lib/_kernel.scm:1992-2000;lib/_kernel.c:16779-16826,30101-30104;lib/mem.c:3823-3966,6511-6574;lib/_kernel.scm:2030-2048;include/gambit.h.in:10043-10064;lib/c_intf.c:6509-6564;examples/tcltk/tcltk.scm:178-194;lib/setup.c:170-204,365-393;lib/mem.c:3969-3987,6844-6850";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Reserve a construction lease before destructive argument pops; no collecting/reentrant call while partial argument stack/vector lacks complete scan layout; keep partial rest, remaining/required arguments, proc/temp1 and original continuation under exclusive source custody; transfer proc/packed-vector to generated register/frame roots before local scope ends; collector-updateable cells and fresh post-GC handle reload, plus marker/native ancestor roots; all-domain RC/raw alias integration remains open";
 attribute :>> failureCustodian="Source retains partial list/arguments and physical repair lease until completed frame accepted; VM canonical park owns scan control after accept even if ACK lost; same native owner keeps live stack/catcher; unknown relevant write/capacity blocks receipt, scan/context unknown blocks terminal claim; no replay, re-CONS, guessed refund or worker longjmp";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part exclusionRoute : GambitHostRootsRefinement::Route { ref part :>> need=exclusion;
 attribute :>> sourceAnchors="examples/tcltk/test.scm:9-33;examples/tcltk/tcltk.scm:124-175,221-228,572-593,673-674;lib/_kernel.scm:546-559;lib/mem.c:7428-7505,4525-4567;include/gambit.h.in:10043-10064;lib/c_intf.c:6509-6564;examples/tcltk/tcltk.scm:178-194;lib/setup.c:170-204,365-393;lib/mem.c:3969-3987,6844-6850;lib/setup.c:3276-3420;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Close new native root borrowers and writers under same registry cut; pre-close writer remains counted through its actual final effect, then materialize matching root generation; relevant borrowed moving values must drain or use admitted stable handles, native-only argv/code/result backing can remain leased; a queued/issued store cannot be revoked by entry closure; late write after receipt invalidates protocol and requires exclusion proof, unknown result retains source duty and blocks receipt";
 attribute :>> failureCustodian="Source retains partial list/arguments and physical repair lease until completed frame accepted; VM canonical park owns scan control after accept even if ACK lost; same native owner keeps live stack/catcher; unknown relevant write/capacity blocks receipt, scan/context unknown blocks terminal claim; no replay, re-CONS, guessed refund or worker longjmp";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part receiptRoute : GambitHostRootsRefinement::Route { ref part :>> need=receipt;
 attribute :>> sourceAnchors="lib/_kernel.scm:560-576;lib/mem.h:63-78;lib/_kernel.scm:577-590;include/gambit.h.in:3160-3167;lib/_kernel.scm:1992-2000;lib/_kernel.c:16779-16826,30101-30104;lib/mem.c:3823-3966,6511-6574;lib/_kernel.scm:2030-2048;include/gambit.h.in:10043-10064;lib/c_intf.c:6509-6564;examples/tcltk/tcltk.scm:178-194;lib/setup.c:170-204,365-393;lib/mem.c:3969-3987,6844-6850";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="FrameReady after full vector initialization, full mapped Scheme call frame, RA/GVM spill, exact root generation and native-frame/capacity lease precedes release-published offer; source pins until canonical VM accept, lost ACK does not restore old authority; one park attempt owns scan/resume/exit arbitration; offer is not scanner permission; no side-effecting rollback or duplicate constructor from unknown acceptance";
 attribute :>> failureCustodian="Source retains partial list/arguments and physical repair lease until completed frame accepted; VM canonical park owns scan control after accept even if ACK lost; same native owner keeps live stack/catcher; unknown relevant write/capacity blocks receipt, scan/context unknown blocks terminal claim; no replay, re-CONS, guessed refund or worker longjmp";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part resumeRoute : GambitHostRootsRefinement::Route { ref part :>> need=resume;
 attribute :>> sourceAnchors="tests/mix.scm:703-706,775-782;tests/test5.ok:15745-15772;examples/tcltk/test.scm:9-33;examples/tcltk/tcltk.scm:124-175,221-228,572-593,673-674;lib/_kernel.scm:1992-2000;lib/_kernel.c:16779-16826,30101-30104;lib/_kernel.scm:2005-2028;lib/_kernel.c:16871-16913;include/gambit.h.in:8176-8178;lib/_kernel.scm:1992-2004;lib/_kernel.c:16800-16823;lib/setup.c:3276-3420;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;lib/mem.c:7003-7085,4525-4567;lib/os_thread.c:697-710;lib/setup.c:924-980";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="After scan/root readers drain, whole-round/capacity result, context preparation, same live owner binding and relocated-root reload, claim exactly one normal or exit authority in next epoch; normal branch reloads the same packed vector and proc, restores np arguments, sets nargs=-1 and jumps target, so GET_REST cannot rebuild the rest list; same original native invocation/catcher continues, no replay or helper-thread longjmp";
 attribute :>> failureCustodian="Source retains partial list/arguments and physical repair lease until completed frame accepted; VM canonical park owns scan control after accept even if ACK lost; same native owner keeps live stack/catcher; unknown relevant write/capacity blocks receipt, scan/context unknown blocks terminal claim; no replay, re-CONS, guessed refund or worker longjmp";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part semanticsRoute : GambitHostRootsRefinement::Route { ref part :>> need=semantics;
 attribute :>> sourceAnchors="lib/_kernel.scm:491-535;include/gambit.h.in:6995-7033;lib/_kernel.scm:560-576;lib/mem.h:63-78;lib/_kernel.scm:1992-2004;lib/_kernel.c:16800-16823;include/gambit.h.in:10043-10064;lib/c_intf.c:6509-6564;examples/tcltk/tcltk.scm:178-194;lib/setup.c:3276-3420;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;lib/mem.c:7003-7085,4525-4567;lib/os_thread.c:697-710;lib/setup.c:924-980";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Ordinary exception/continuation request during unscannable repair is latched until mandatory bounded completion and root handoff; do not call arbitrary Scheme handler in partial-frame zone; after scan/round readiness atomically choose normal resume only without pending exit, or generated same-owner exit guard only with pending exit, never both; current heap-overflow helper may raise and retry GC while retaining proc/args; request epochs and park attempts must not consume a stale receipt; unmanaged asynchronous nonlocal escape/dead stack is rejected, not silently translated to managed cancel";
 attribute :>> failureCustodian="Source retains partial list/arguments and physical repair lease until completed frame accepted; VM canonical park owns scan control after accept even if ACK lost; same native owner keeps live stack/catcher; unknown relevant write/capacity blocks receipt, scan/context unknown blocks terminal claim; no replay, re-CONS, guessed refund or worker longjmp";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="tests/mix.scm:703-706,775-782;tests/test5.ok:15745-15772;examples/tcltk/test.scm:9-33;examples/tcltk/tcltk.scm:124-175,221-228,572-593,673-674;gsc/_t-c-2.scm:718-772;include/gambit.h.in:8170-8193;lib/setup.c:4740,5235;lib/_kernel.scm:491-535;include/gambit.h.in:6995-7033;lib/_kernel.scm:536-545;include/gambit.h.in:3149-3153,5313-5325;lib/_kernel.scm:546-559;lib/mem.c:7428-7505,4525-4567;lib/_kernel.scm:560-576;lib/mem.h:63-78;lib/_kernel.scm:577-590;include/gambit.h.in:3160-3167;lib/_kernel.scm:1992-2000;lib/_kernel.c:16779-16826,30101-30104;lib/mem.c:3823-3966,6511-6574;lib/_kernel.scm:2030-2048;lib/_kernel.scm:2005-2028;lib/_kernel.c:16871-16913;include/gambit.h.in:8176-8178;lib/_kernel.scm:1992-2004;lib/_kernel.c:16800-16823;include/gambit.h.in:10043-10064;lib/c_intf.c:6509-6564;examples/tcltk/tcltk.scm:178-194;lib/setup.c:170-204,365-393;lib/mem.c:3969-3987,6844-6850;lib/setup.c:3276-3420;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072;lib/mem.c:7003-7085,4525-4567;lib/os_thread.c:697-710;lib/setup.c:924-980";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Preflight physically reserves repair words, stack/frame and root/control metadata before pops; close new native writer/borrow admission, settle actual old final effects, complete vector and FrameSpec/GVM writes, release-publish offer, canonical accept/acquire scan; scanner writes release before whole-round/context/binding/acquire reload; exclusive fresh normal/exit claim prevents late scan and duplicate nargs resume; all raw aliases share the cut; no locks held across owner/GC wait; actual C atomic layout, helper visibility and native ABI refinement remain open";
 attribute :>> failureCustodian="Source retains partial list/arguments and physical repair lease until completed frame accepted; VM canonical park owns scan control after accept even if ACK lost; same native owner keeps live stack/catcher; unknown relevant write/capacity blocks receipt, scan/context unknown blocks terminal claim; no replay, re-CONS, guessed refund or worker longjmp";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="real-rest-source-and-calls";
 attribute :>> sourceAnchors="tests/mix.scm:703-706,775-782;tests/test5.ok:15745-15772";
 attribute :>> actualChain="f3 . a returns list containing a; run-f3 calls with zero to four args; retained expected C contains generic GET_REST";
 attribute :>> hazard="Expected C is static source, not current-host build or proof that every specialized call takes generic/slow entry";
 attribute :>> replacement="Use f3(0..3 logical ids) as bounded real contract, both generic dispatch and heap-limit trigger conditional";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="native-callback-real-rest-call";
 attribute :>> sourceAnchors="examples/tcltk/test.scm:9-33;examples/tcltk/tcltk.scm:124-175,221-228,572-593,673-674";
 attribute :>> actualChain="Button command make-setter closure calls tcl; procedure arguments are exported, scheme_call_cmd -> tcltk_call -> apply invokes closure -> tcltk#tcl command . args";
 attribute :>> hazard="Generic rest slow path may be specialized away and GC pressure not forced; borrowed argv and original native frame still alive";
 attribute :>> replacement="Source-reachable callback/rest composition, not a recorded native execution; preserve synchronous result and stack";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="generator-dispatch";
 attribute :>> sourceAnchors="gsc/_t-c-2.scm:718-772;include/gambit.h.in:8170-8193;lib/setup.c:4740,5235";
 attribute :>> actualChain="targ-gen-label-entry derives required/optional/rest dispatch; GET_REST puts target in temp1 and jumps handler for nonnegative nargs";
 attribute :>> hazard="Rest reconstruction would repeat if restored nargs treated as fresh count";
 attribute :>> replacement="RestConstructionPlan separates original generic entry and resume sentinel; conditional source admission";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="register-arguments-and-underflow";
 attribute :>> sourceAnchors="lib/_kernel.scm:491-535;include/gambit.h.in:6995-7033";
 attribute :>> actualChain="handler7 reads np/na, pushes register args; insufficient nargs shifts operator/args and tail raises wrong-nargs exception";
 attribute :>> hazard="Raw pending argument stack is not a complete continuation frame";
 attribute :>> replacement="Keep source construction lease and separate wrong-arity exit plan before rest pops";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="pair-progress";
 attribute :>> sourceAnchors="lib/_kernel.scm:536-545;include/gambit.h.in:3149-3153,5313-5325";
 attribute :>> actualChain="CONS pops last pending arg and prepends it to local rest_param_list; decrements i";
 attribute :>> hazard="Unregistered C local list and partial stack cannot be frozen as if W_ALL covered them";
 attribute :>> replacement="Preserve pending-prefix plus built-suffix order and one pair per rest arg under noncollecting construction lease";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="noncollecting-limit-call";
 attribute :>> sourceAnchors="lib/_kernel.scm:546-559;lib/mem.c:7428-7505,4525-4567";
 attribute :>> actualChain="W_ALL -> heap_limit -> R_ALL; heap_limit adjusts msection/context or returns need-GC; actual GC is later";
 attribute :>> hazard="Replacing this helper with implicit GC/callback would expose unrooted locals/incomplete frames";
 attribute :>> replacement="Keep no-collection/no-managed-reentry effect contract; full helper/transitive origin proof remains open";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="mandatory-repair-tail";
 attribute :>> sourceAnchors="lib/_kernel.scm:560-576;lib/mem.h:63-78";
 attribute :>> actualChain="On need-GC finish every remaining CONS before any GC; bounded by actual args; no repeated limit check inside tail";
 attribute :>> hazard="Fudge constant alone does not prove enough physical words for all remaining pairs and vector";
 attribute :>> replacement="Preflight RepairCapacityReceipt with remaining*(2+PAIR_BODY)+np+VECTOR_BODY and actual physical interval; refuse before destructive start if unqualified";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="vector-initialization";
 attribute :>> sourceAnchors="lib/_kernel.scm:577-590;include/gambit.h.in:3160-3167";
 attribute :>> actualChain="Write vector header and last slot rest; pop required args into prior slots; END_ALLOC advances hp; push target and vector";
 attribute :>> hazard="Header publication or hp change is not fully initialized vector/root transfer";
 attribute :>> replacement="Keep no-park region through all np fields; publish typed completed packet only after initialized slots complete";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="full-helper-frame";
 attribute :>> sourceAnchors="lib/_kernel.scm:1992-2000;lib/_kernel.c:16779-16826,30101-30104";
 attribute :>> actualChain="Helper stores R0,R1,R2 at stack slots1,2,3, installs return label2, adjusts fp by8 and calls gc-without-exceptions; return descriptor fs5/link0/gcmap7";
 attribute :>> hazard="Pushing proc/vector or completing vector alone is not a complete spill/frame receipt";
 attribute :>> replacement="FrameReady after actual call frame plus RA/W_ALL spill; verify current generator maps separately from retained C specimen";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="real-frame-scanner";
 attribute :>> sourceAnchors="lib/mem.c:3823-3966,6511-6574;lib/_kernel.scm:2030-2048";
 attribute :>> actualChain="mark_frame scans gcmap slots from1, mark_continuation decodes return metadata; gc helper saves RA/W_ALL and reloads after actual GC";
 attribute :>> hazard="Frozen SCMOBJ value copies or native raw aliases become stale after collector updates cells";
 attribute :>> replacement="Canonical updateable frame/register/native root handles plus post-copy reload";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="resume-sentinel";
 attribute :>> sourceAnchors="lib/_kernel.scm:2005-2028;lib/_kernel.c:16871-16913;include/gambit.h.in:8176-8178";
 attribute :>> actualChain="Resume pops proc/vector, pushes vector fields in order, loads register args, jumps target with nargs=-1; GET_REST requires nargs>=0";
 attribute :>> hazard="Reentering ordinary native wrapper or generic nargs would reconstruct list and duplicate effects";
 attribute :>> replacement="Resume same packet and target after fresh epoch claim; zero new rest pairs due to resume";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="heap-overflow-exception";
 attribute :>> sourceAnchors="lib/_kernel.scm:1992-2004;lib/_kernel.c:16800-16823";
 attribute :>> actualChain="GC overflow raises heap-overflow exception; returning handler retries with retained proc/args; nonreturn uses continuation exit";
 attribute :>> hazard="Overflow is not successful resume or permission to reinitialize packed args";
 attribute :>> replacement="Retain packet roots through handler/retry; model one chosen round only, cross-round attempt freshness remains open";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="native-borrows-and-markers";
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10064;lib/c_intf.c:6509-6564;examples/tcltk/tcltk.scm:178-194";
 attribute :>> actualChain="SFUN conversion/marker/call, marker kill and Tcl delete release distinct resources";
 attribute :>> hazard="Closing borrow admission does not revoke in-flight raw data_rc accesses or native result/code aliases";
 attribute :>> replacement="All-domain native root/borrow handles, exact same stack/catcher and final access completion; unknown duty retained";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="late-writes-and-queue";
 attribute :>> sourceAnchors="lib/setup.c:170-204,365-393;lib/mem.c:3969-3987,6844-6850";
 attribute :>> actualChain="Owned callback dequeues before execute; publisher touches PSTATE after unlock; RC root cell scanned by address only P0 branch";
 attribute :>> hazard="Empty queue or pointer generation does not exclude old writers/claimed callbacks or cover nonzero RC roots";
 attribute :>> replacement="Import complete writer/borrow census and all-domain adapter; accepted receipt must match last root generation";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="exception-return-arbitration";
 attribute :>> sourceAnchors="lib/setup.c:3276-3420;include/gambit.h.in:9981-9987;lib/_kernel.scm:1020-1072";
 attribute :>> actualChain="Native call installs catcher; Scheme return tests processor/live marker and throws to own catcher; propagation may escape";
 attribute :>> hazard="Exit during scan could destroy root/stack backing; completed inner callback not outer native stop";
 attribute :>> replacement="Latch managed exit then same-owner guard after reader/round readiness; one terminal claim; raw forced longjmp rejects profile";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="round-context-and-owner";
 attribute :>> sourceAnchors="lib/mem.c:7003-7085,4525-4567;lib/os_thread.c:697-710;lib/setup.c:924-980";
 attribute :>> actualChain="Strong/weak/cleanup/resize result then prepare fp/hp/limits, GC notice earlier; binding/resize cleanup have separate lifetime";
 attribute :>> hazard="Scan done, notification or failed/unknown join cannot recreate live original native stack";
 attribute :>> replacement="Whole-round/context/binding/root reload and fresh epoch permission; death/unknown owner retains debt and forbids same-call resume";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Current rest work";
 attribute :>> removedWork="Preserve mandatory ordered list construction";
 attribute :>> bound="k=na-np+1 pairs, one per excess arg; resume adds0 pairs";
 attribute :>> addedCost="Explicit progress/root/effect descriptor";
 attribute :>> condition="This work already exists; not a new pair-allocation saving or measured speedup";
 }
 part cost1 : CostRow {
 attribute :>> capability="Completion upper bound";
 attribute :>> removedWork="Make unchecked repair work physically budgeted";
 attribute :>> bound="Brepair=r*(2+PAIR_BODY)+np+VECTOR_BODY words after checked CONS";
 attribute :>> addedCost="Preflight physical interval and stack/frame reserve; helper allocation effects classified";
 attribute :>> condition="Fudge/global free count alone insufficient; actual selected capacity mapping remains source-open";
 }
 part cost2 : CostRow {
 attribute :>> capability="Actual four-arg no-handles examples";
 attribute :>> removedWork="Separate unavoidable pairs from slow-path packet";
 attribute :>> bound="f3:11 repair words after first CONS, vector2 words; f4/tcl shape:9 repair words, vector3 words";
 attribute :>> addedCost="One initialized vector and existing mapped helper frame";
 attribute :>> condition="Numbers are macro/profile arithmetic, not actual allocator pages/RSS or forced slow-path run";
 }
 part cost3 : CostRow {
 attribute :>> capability="Safe frame cut";
 attribute :>> removedWork="Replace blanket W_ALL safepoint inference";
 attribute :>> bound="Retained helper stores3 live slots, adjusts fp8 words, descriptor fs5/map0x7";
 attribute :>> addedCost="Generated FrameSpec/PointId, spill and constructor validation";
 attribute :>> condition="No new arbitrary partial-stack scanner; current-host regeneration and all maps not proved";
 }
 part cost4 : CostRow {
 attribute :>> capability="Native borrow exclusion";
 attribute :>> removedWork="Allow native stack to remain without relevant raw heap access";
 attribute :>> bound="0 relevant raw borrowers and pre-close writers before receipt";
 attribute :>> addedCost="Borrow/effect census and matching final-write generation";
 attribute :>> condition="Native-only input/code backing can remain leased under isolation; unknown relevant access blocks park";
 }
 part cost5 : CostRow {
 attribute :>> capability="Receipt and unknown ACK";
 attribute :>> removedWork="Keep one canonical construction/park attempt";
 attribute :>> bound="One accept; protected queries add0 invocations and0 CONS";
 attribute :>> addedCost="Pinned source packet/root/code backing and canonical outcome lookup";
 attribute :>> condition="Lost response cannot authorize rollback, packet rebuild or old permit restoration";
 }
 part cost6 : CostRow {
 attribute :>> capability="Exception and resume choice";
 attribute :>> removedWork="Avoid conflicting stack teardown and resume";
 attribute :>> bound="NormalClaims+ExitClaims<=1 in bounded model; no body entry on exit branch";
 attribute :>> addedCost="Pending-exit state and scan/exit/resume arbitration";
 attribute :>> condition="Managed deferred exit only; arbitrary signal/native longjmp cannot be equivalently delayed by assumption";
 }
 part cost7 : CostRow {
 attribute :>> capability="Fresh resume";
 attribute :>> removedWork="Retain same constructed packet, procedure and native invocation";
 attribute :>> bound="Reload np fields, nargs=-1, no new rest pairs/native entry due to resume";
 attribute :>> addedCost="Scan reader drain + round/context/binding/reload + new permission";
 attribute :>> condition="Existing Gambit already resumes in-call; this preserves it while separating collector workers";
 }
 part cost8 : CostRow {
 attribute :>> capability="Root/control metadata";
 attribute :>> removedWork="Describe and retain actual roots rather than whole graph copies";
 attribute :>> bound="O(A+R+D) metadata and O(R) root visits; repair time O(r+np)";
 attribute :>> addedCost="Activation/root/borrow/control records and generation publication";
 attribute :>> condition="May extend reachability/native stack lifetime; full root and recursive activation coverage open";
 }
 part cost9 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Distinguish slow packet, existing pairs, stack and protocol pools";
 attribute :>> bound="Peak=max_t(H+P+N+Q); packet=(np+VECTOR_BODY)*wordBytes; helper stack8*wordBytes in retained specimen";
 attribute :>> addedCost="Existing pairs plus packet retained through GC/overflow retry; unknown resources charged";
 attribute :>> condition="Packet/frame already exist on current slow path; no demonstrated whole-round peak reduction; protocol may increase it";
 }
 part cost10 : CostRow {
 attribute :>> capability="Retirement";
 attribute :>> removedWork="Retire implicit partial-zone and raw root-write responsibility";
 attribute :>> bound="0 production paths retired; no change to C portability or Scheme tail/continuation semantics";
 attribute :>> addedCost="Scheme-generated RestConstructionPlan + typed C capacity/root/park services";
 attribute :>> condition="Generic GET_REST, CONS and R/W transfer can remain generated operations; source/order/ABI closure before replacement";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C mainline";
 attribute :>> removedWork="Share FrameSpec/root/activation contracts across native services";
 attribute :>> bound="0 Zig-only necessary runtime support eliminated by this component";
 attribute :>> addedCost="Both languages require same GC/borrow/frame/capacity/exception proof";
 attribute :>> condition="Net CPU benefit needs actual removed baseline work > extra protocol work; graph/lifetime correctness is a separate benefit";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="entry"; attribute :>> labelText="Real rest entry\\nGET_REST / native callback envelope"; }
 part node1 : DiagramNode { attribute :>> nodeId="lease"; attribute :>> labelText="Reserve physical repair + root lease\\nclose new relevant writers / borrowers"; }
 part node2 : DiagramNode { attribute :>> nodeId="repair"; attribute :>> labelText="CONS remaining args in order\\nno collection or managed handler"; }
 part node3 : DiagramNode { attribute :>> nodeId="packet"; attribute :>> labelText="Initialize every vector slot\\nproc + completed args packet"; }
 part node4 : DiagramNode { attribute :>> nodeId="frame"; attribute :>> labelText="Scheme helper full frame\\nR0/proc/args + map + RA/W_ALL"; }
 part node5 : DiagramNode { attribute :>> nodeId="offer"; attribute :>> labelText="Publish exact rooted frame generation\\nsource pins until canonical accept"; }
 part node6 : DiagramNode { attribute :>> nodeId="acceptPark"; attribute :>> labelText="VM accepts same park attempt\\nscan / exit / resume arbitration"; }
 part node7 : DiagramNode { attribute :>> nodeId="scan"; attribute :>> labelText="Collector updates root cells\\nrelease scan/readers + whole round"; }
 part node8 : DiagramNode { attribute :>> nodeId="prepare"; attribute :>> labelText="Context prepare + same owner bind\\nreload relocated proc / vector"; }
 part node9 : DiagramNode { attribute :>> nodeId="resumeCall"; attribute :>> labelText="Fresh next epoch normal OR exit claim\\nnargs=-1 / same native call"; }
 part node10 : DiagramNode { attribute :>> nodeId="custody"; attribute :>> labelText="Native stack/catcher/root/code custody\\ntransfer is not disposal"; }
 part node11 : DiagramNode { attribute :>> nodeId="refuse"; attribute :>> labelText="Unknown write / capacity / dead frame\\nretain source or canonical VM debt"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and native-order gaps open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="before destructive argument pops"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="known physical budget and local roots"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="all excess pairs completed"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="no partial vector published"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="last write and root spill complete"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="atomic accept, not ACK delivery"; }
 part edge6 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="acquire updateable complete view"; }
 part edge7 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="whole-round readiness, not notification"; }
 part edge8 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="exclusive claim; no replay or re-CONS"; }
 part edge9 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node1; attribute :>> labelText="native/root/control budget retained"; }
 part edge10 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node6; attribute :>> labelText="original catcher and result contract"; }
 part edge11 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node9; attribute :>> labelText="same native stack stays live"; }
 part edge12 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node10; attribute :>> labelText="retain invocation envelope"; }
 part edge13 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node11; attribute :>> labelText="unknown physical or effect proof"; }
 part edge14 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node11; attribute :>> labelText="unknown acceptance -> same-key query"; }
 part edge15 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node11; attribute :>> labelText="scan/owner/root readiness unknown"; }
 part edge16 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node4; attribute :>> labelText="construction and frame evidence"; }
 part edge17 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node9; attribute :>> labelText="exclusive terminal claim and lineage"; }
}
