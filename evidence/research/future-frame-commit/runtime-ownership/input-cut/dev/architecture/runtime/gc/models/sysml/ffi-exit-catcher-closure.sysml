/* Modern generated C FFI exception exit research; no native admission. */
package GambitFfiExitCatcherClosure {
 private import ScalarValues::*;
 part def ExitState { attribute localReady : Boolean; attribute localEffectsDone : Boolean; attribute catcherRestored : Boolean; attribute registersRestored : Boolean; attribute resultRooted : Boolean; attribute receiverNeeded : Boolean; attribute receiverRegistered : Boolean; }
 requirement def LocalExitLaw { subject e : ExitState; require constraint { not e.localReady or (e.localEffectsDone and e.catcherRestored and e.registersRestored and e.resultRooted and (not e.receiverNeeded or e.receiverRegistered)) } }
 part def DebtState { attribute sourcePins : Integer; attribute currentEffects : Integer; attribute futureTasks : Integer; attribute futureGate : Boolean; attribute independentCustody : Boolean; attribute admissionClosed : Boolean; attribute dataClosed : Boolean; }
 requirement def DataSealLaw { subject d : DebtState; require constraint { not d.dataClosed or (d.sourcePins==0 and d.currentEffects==0 and d.admissionClosed and (d.futureTasks==0 or (d.futureGate and d.independentCustody))) } }
 ref part inheritedLayout32=GambitManagedMarkerLayout::layout32;
 ref part inheritedLayout64=GambitManagedMarkerLayout::layout64;
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/ffi_exit_catcher_closure.qnt";
 attribute :>> subjectScope="ffi_exit_catcher_closure:37-named-histories;admitted;SFUN+CFUN-OOL;seed=17;each100x100";
 attribute :>> premise="One original activation, propagation receiver, OOL caller and cleanup callback; separate local close, source pins, callback custody, future-epoch nonexecution gate and whole current-data seal; SFUN and CFUN profiles; correct catcher identity, complete effect manifest, target thread lifetime and atomic transitions are premises; not source, ABI, weak-memory, full nested continuation or liveness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="GambitSMP.FfiExitCatcherClosure:catcherRequired;registersRequired;propagationReceiverRequired;conversionPendingRejects;markerPendingRejects;missingResultRootRejects;receiverTransferPreserves;receiverTransferKeepsBorrowCount;receiverTransferNeverZero;callbackReservePreserves;callbackReserveAddsDebt;callbackMovePreserves;callbackMoveDoesNotDischarge;sourceFinishPreserves;receiverFinishPreserves;callbackFinishPreserves;stepPreserves;tracePreserves;pendingReceiverBlocksCleanup;independentDebtBlocksSeal;zeroSourcePinsNotDataClosed;dataClosedHasNoDebts;admissionCloseDoesNotDrain;futureTaskStillOwed;futureSealNeedsExecutionGate;deferredSealHasNoCurrentBorrowers";
 attribute :>> premise="26 conditional declarations: exit prerequisites, accounted debt Step/Trace, propagation transfer preserves borrow count, callback transfer retains debt zero source pins do not imply whole data closure, and DeferredSeal retains future task debt under nonexecution gate; not all QNT actions or C refinement";
 }
 part exitPlan : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-EXIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="EX-EXIT:actual-source-refinement";
 attribute :>> premise="Scheme generator emits typed exit plans for void/SCMOBJ/typed SFUN and inline/OOL CFUN, including acquire-completed conversion cleanup bits and result/root disposition; ActivationExitReady follows final local effects, marker retirement and relevant own restore (OOL caller reload remains on a separate ticket), but DataWriteClosed is signed only by coordinator after current propagated/caller/callback effects drain and admission closes; an unstarted future task may remain only under VM-independent custody and a qualified current-epoch nonexecution gate; no existing END macro alone is a valid full issuer";
 }
 part catcher : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-CATCHER";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="EX-CATCHER:actual-source-refinement";
 attribute :>> premise="Saved catcher identity and native frame/thread incarnation are pinned before installing local guard; restoring the exact predecessor is a write under source borrow before dropping that guard; generated state used after jump lives in protected off-stack storage, not changed nonvolatile automatic locals; borrowed jmp_buf remains a live same-thread target and is never handed to GC/helper worker for longjmp; builtin/library/dynamic-import profiles require separate C/backend qualification";
 }
 part propagation : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-PROPAGATE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="EX-PROPAGATE:actual-source-refinement";
 attribute :>> premise="propagate_error NO_ERR returns but still reads native context, nonzero calls throw_error and THROW writes longjmp_err then jumps; reserve propagation receiver and root/code/PSTATE duty before original close/drop; matching ___call restores frame after local catcher restoration, nonmatching rethrows to outer target; trampoline-only trips keep original guard alive; ordinary CFUN conversion errors return/jump to handler before propagate_error, UNWIND_C_STACK can reach it; no arbitrary replay of throw";
 }
 part borrows : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-BORROW";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="EX-BORROW:actual-source-refinement";
 attribute :>> premise="PSTATE pins cover catcher/longjmp_err, conversion temps, fp/R0 restore, W_ALL/R_ALL and CFUN_OOL caller status reads; local close cannot set total borrow count to zero while outer receiver/caller/nested activation remains; source cleanup permit needs all source pins zero plus observed VM acceptance and physical unlink/root-view evidence; activation identity is not processor or reused stack address";
 }
 part callbacks : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-CALLBACK";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="EX-CALLBACK:actual-source-refinement";
 attribute :>> premise="Conversion release helpers, AT_END text, release_foreign and procedural interrupt execute_fn are separate effect producers; register child cleanup duty before callback exposure or parent discharge; invoke only admitted origin/thread/effect profile, transfer root/native/code custody before dropping source pin, and keep child data debt after VM-independent transfer; deferral of unstarted child into a successor epoch additionally needs no current write authority or queued native invocation, closed admission and future reentry gate, preserving task/root/native debt; unknown acceptance or callback longjmp retains duty, cannot guess completion or refund";
 }
 part retirement : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-RETIRE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="EX-RETIRE:actual-source-refinement";
 attribute :>> premise="Replace managed generated END/cleanup exits and raw marker retirement with one off-stack exit service and exactly-once disposition, route shrink/rollback/shutdown/exported cleanup through permit; cleanup callback registration competes with final admission cut atomically; callback added after cut must refuse or enter a separately counted successor cohort before domain freeze, never reopen old seal; failed/unknown native join retains thread/TLS/code envelope independently of data closure";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="EX-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/FfiExitCatcherClosure.lean";
 attribute :>> subjectScope="EX-ORDER:actual-C-and-native-order-refinement";
 attribute :>> premise="Original-to-receiver and parent-to-callback ticket publication precedes source release with one canonical authority; coordinator acquire sees all closures and zero outstanding effects; cleanup acquires accepted VM view and exact zero source-pin census under admission exclusion; native C emitter preserves standard setjmp call context, lifetime and local-value rules or qualified builtin profile, and atomic/lock implementation, layout and compiler code-motion remain unproved";
 }
 ref part priorEndpoint=GambitDataWriteClosureCustody::endpoint;
 ref part priorEnrollment=GambitDataWriteClosureCustody::enrollment;
 ref part priorEscrow=GambitDataWriteClosureCustody::escrow;
 ref part priorCleanup=GambitDataWriteClosureCustody::cleanup;
 ref part priorJoin=GambitDataWriteClosureCustody::joinOutcome;
 ref part priorOrder=GambitDataWriteClosureCustody::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitPlan; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitPlan; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitPlan; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=catcher; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=catcher; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=catcher; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=propagation; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=propagation; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=propagation; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=borrows; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=borrows; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=borrows; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=callbacks; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=callbacks; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=callbacks; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitPlan; ref part :>> prerequisite=priorEndpoint; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitPlan; ref part :>> prerequisite=catcher; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=catcher; ref part :>> prerequisite=priorEndpoint; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=propagation; ref part :>> prerequisite=catcher; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=propagation; ref part :>> prerequisite=priorEnrollment; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=borrows; ref part :>> prerequisite=propagation; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=borrows; ref part :>> prerequisite=priorEscrow; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=borrows; ref part :>> prerequisite=priorCleanup; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=callbacks; ref part :>> prerequisite=borrows; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=callbacks; ref part :>> prerequisite=priorEnrollment; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=callbacks; ref part :>> prerequisite=priorEscrow; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=exitPlan; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=callbacks; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=priorJoin; }
 part exitPlanRoute : GambitHostRootsRefinement::Route { ref part :>> need=exitPlan;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2840-3030,3145-3187;include/gambit.h.in:10043-10059;include/gambit.h.in:10186-10255;lib/mem.c:1715-1739;gsc/_ptree2.scm:3239-3329;gsc/_t-c-2.scm:124-218,239;include/gambit.h.in:10325-10380;include/gambit.h.in:10382-10400;gsc/_ptree2.scm:3240-3321;include/gambit.h.in:10353-10397;include/gambit.h.in:10473-10525;lib/c_intf.c:1731-1802;lib/mem.c:756-825;lib/setup.c:3395-3420;lib/c_intf.c:6509-6564";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Scheme generator emits typed exit plans for void/SCMOBJ/typed SFUN and inline/OOL CFUN, including acquire-completed conversion cleanup bits and result/root disposition; ActivationExitReady follows final local effects, marker retirement and relevant own restore (OOL caller reload remains on a separate ticket), but DataWriteClosed is signed only by coordinator after current propagated/caller/callback effects drain and admission closes; an unstarted future task may remain only under VM-independent custody and a qualified current-epoch nonexecution gate; no existing END macro alone is a valid full issuer";
 attribute :>> failureCustodian="Original guard retains source duty until exact successor/root/native/code custody accepted; receiver/caller/cleanup tickets survive original close; unknown jump/cleanup outcome retains debt, never replays; failed/unknown join retains native envelope independently; data freeze waits every admitted effect and root-view obligation";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part catcherRoute : GambitHostRootsRefinement::Route { ref part :>> need=catcher;
 attribute :>> sourceAnchors="include/gambit.h.in:9981-10007,11699-11700;lib/setup.c:4755;lib/setup.c:839-865;include/gambit.h.in:9987;lib/setup.c:3355-3390;lib/setup.c:3395-3420;lib/c_intf.c:6509-6564;include/gambit.h.in:1618-1668,8590,9981-9987;lib/setup.c:5319;examples/tcltk/tcltk.scm:124-194";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Saved catcher identity and native frame/thread incarnation are pinned before installing local guard; restoring the exact predecessor is a write under source borrow before dropping that guard; generated state used after jump lives in protected off-stack storage, not changed nonvolatile automatic locals; borrowed jmp_buf remains a live same-thread target and is never handed to GC/helper worker for longjmp; builtin/library/dynamic-import profiles require separate C/backend qualification";
 attribute :>> failureCustodian="Original guard retains source duty until exact successor/root/native/code custody accepted; receiver/caller/cleanup tickets survive original close; unknown jump/cleanup outcome retains debt, never replays; failed/unknown join retains native envelope independently; data freeze waits every admitted effect and root-view obligation";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part propagationRoute : GambitHostRootsRefinement::Route { ref part :>> need=propagation;
 attribute :>> sourceAnchors="include/gambit.h.in:10353-10397;include/gambit.h.in:9981-10007,11699-11700;lib/setup.c:4755;lib/setup.c:839-865;include/gambit.h.in:9987;lib/setup.c:3355-3390;include/gambit.h.in:6802-6803,10325-10380;gsc/_t-c-2.scm:213-218";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="propagate_error NO_ERR returns but still reads native context, nonzero calls throw_error and THROW writes longjmp_err then jumps; reserve propagation receiver and root/code/PSTATE duty before original close/drop; matching ___call restores frame after local catcher restoration, nonmatching rethrows to outer target; trampoline-only trips keep original guard alive; ordinary CFUN conversion errors return/jump to handler before propagate_error, UNWIND_C_STACK can reach it; no arbitrary replay of throw";
 attribute :>> failureCustodian="Original guard retains source duty until exact successor/root/native/code custody accepted; receiver/caller/cleanup tickets survive original close; unknown jump/cleanup outcome retains debt, never replays; failed/unknown join retains native envelope independently; data freeze waits every admitted effect and root-view obligation";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part borrowsRoute : GambitHostRootsRefinement::Route { ref part :>> need=borrows;
 attribute :>> sourceAnchors="gsc/_t-c-2.scm:124-218,239;include/gambit.h.in:10325-10380;include/gambit.h.in:9981-10007,11699-11700;lib/setup.c:4755;lib/setup.c:3355-3390;include/gambit.h.in:6802-6803,10325-10380;gsc/_t-c-2.scm:213-218;lib/setup.c:924-980,4569-4599,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="PSTATE pins cover catcher/longjmp_err, conversion temps, fp/R0 restore, W_ALL/R_ALL and CFUN_OOL caller status reads; local close cannot set total borrow count to zero while outer receiver/caller/nested activation remains; source cleanup permit needs all source pins zero plus observed VM acceptance and physical unlink/root-view evidence; activation identity is not processor or reused stack address";
 attribute :>> failureCustodian="Original guard retains source duty until exact successor/root/native/code custody accepted; receiver/caller/cleanup tickets survive original close; unknown jump/cleanup outcome retains debt, never replays; failed/unknown join retains native envelope independently; data freeze waits every admitted effect and root-view obligation";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part callbacksRoute : GambitHostRootsRefinement::Route { ref part :>> need=callbacks;
 attribute :>> sourceAnchors="include/gambit.h.in:10186-10255;lib/mem.c:1715-1739;include/gambit.h.in:10382-10400;gsc/_ptree2.scm:3240-3321;include/gambit.h.in:10473-10525;lib/c_intf.c:1731-1802;lib/mem.c:756-825;lib/mem.c:4387-4451;lib/c_intf.c:1683-1715;gsc/_ptree2.scm:2590-2670;lib/setup.c:143-204,365-419";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Conversion release helpers, AT_END text, release_foreign and procedural interrupt execute_fn are separate effect producers; register child cleanup duty before callback exposure or parent discharge; invoke only admitted origin/thread/effect profile, transfer root/native/code custody before dropping source pin, and keep child data debt after VM-independent transfer; deferral of unstarted child into a successor epoch additionally needs no current write authority or queued native invocation, closed admission and future reentry gate, preserving task/root/native debt; unknown acceptance or callback longjmp retains duty, cannot guess completion or refund";
 attribute :>> failureCustodian="Original guard retains source duty until exact successor/root/native/code custody accepted; receiver/caller/cleanup tickets survive original close; unknown jump/cleanup outcome retains debt, never replays; failed/unknown join retains native envelope independently; data freeze waits every admitted effect and root-view obligation";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part retirementRoute : GambitHostRootsRefinement::Route { ref part :>> need=retirement;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2840-3030,3145-3187;include/gambit.h.in:10043-10059;gsc/_ptree2.scm:3239-3329;gsc/_t-c-2.scm:124-218,239;include/gambit.h.in:10325-10380;include/gambit.h.in:10353-10397;lib/setup.c:3395-3420;lib/c_intf.c:6509-6564;lib/mem.c:4387-4451;lib/c_intf.c:1683-1715;gsc/_ptree2.scm:2590-2670;lib/setup.c:143-204,365-419;lib/setup.c:924-980,4569-4599,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Replace managed generated END/cleanup exits and raw marker retirement with one off-stack exit service and exactly-once disposition, route shrink/rollback/shutdown/exported cleanup through permit; cleanup callback registration competes with final admission cut atomically; callback added after cut must refuse or enter a separately counted successor cohort before domain freeze, never reopen old seal; failed/unknown native join retains thread/TLS/code envelope independently of data closure";
 attribute :>> failureCustodian="Original guard retains source duty until exact successor/root/native/code custody accepted; receiver/caller/cleanup tickets survive original close; unknown jump/cleanup outcome retains debt, never replays; failed/unknown join retains native envelope independently; data freeze waits every admitted effect and root-view obligation";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2840-3030,3145-3187;include/gambit.h.in:10043-10059;include/gambit.h.in:10186-10255;lib/mem.c:1715-1739;gsc/_ptree2.scm:3239-3329;gsc/_t-c-2.scm:124-218,239;include/gambit.h.in:10325-10380;include/gambit.h.in:10382-10400;gsc/_ptree2.scm:3240-3321;include/gambit.h.in:10353-10397;include/gambit.h.in:10473-10525;lib/c_intf.c:1731-1802;lib/mem.c:756-825;include/gambit.h.in:9981-10007,11699-11700;lib/setup.c:4755;lib/setup.c:839-865;include/gambit.h.in:9987;lib/setup.c:3355-3390;lib/setup.c:3395-3420;lib/c_intf.c:6509-6564;include/gambit.h.in:6802-6803,10325-10380;gsc/_t-c-2.scm:213-218;lib/mem.c:4387-4451;lib/c_intf.c:1683-1715;gsc/_ptree2.scm:2590-2670;lib/setup.c:143-204,365-419;lib/setup.c:924-980,4569-4599,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592;include/gambit.h.in:1618-1668,8590,9981-9987;lib/setup.c:5319;examples/tcltk/tcltk.scm:124-194";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Original-to-receiver and parent-to-callback ticket publication precedes source release with one canonical authority; coordinator acquire sees all closures and zero outstanding effects; cleanup acquires accepted VM view and exact zero source-pin census under admission exclusion; native C emitter preserves standard setjmp call context, lifetime and local-value rules or qualified builtin profile, and atomic/lock implementation, layout and compiler code-motion remain unproved";
 attribute :>> failureCustodian="Original guard retains source duty until exact successor/root/native/code custody accepted; receiver/caller/cleanup tickets survive original close; unknown jump/cleanup outcome retains debt, never replays; failed/unknown join retains native envelope independently; data freeze waits every admitted effect and root-view obligation";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="sfun-generator-order";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2840-3030,3145-3187;include/gambit.h.in:10043-10059";
 attribute :>> actualChain="Recursive conversion wrappers surround SFUN_CALL; error loop can call Scheme again, result conversion then marker kill then propagate";
 attribute :>> hazard="Call return or result assignment leaves conversion/marker/error effects";
 attribute :>> replacement="Generate acquisition/disposition/exit plan per three SFUN families, shared off-stack guarded exit service";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="sfun-conversion-releases";
 attribute :>> sourceAnchors="include/gambit.h.in:10186-10255;lib/mem.c:1715-1739";
 attribute :>> actualChain="END_SFUN numeric/foreign argument conversions release still SCMOBJ after body; longjmp can bypass those lexical ends";
 attribute :>> hazard="All acquired conversions cannot be inferred from uninitialized or changed C locals after jump";
 attribute :>> replacement="Record acquisition after successful conversion; normal/exceptional path consumes each exact cleanup duty once";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="cfun-generator-raw-return";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:3239-3329";
 attribute :>> actualChain="build-c-lambda wraps optional cleanup TRY and AT_END; ___return uses goto local label; raw C text remains possible";
 attribute :>> hazard="Arbitrary return/longjmp/spawn bypasses local label or cleanup";
 attribute :>> replacement="Typed effect/exit manifest and managed return form; otherwise refuse controlled-cohort admission";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="cfun-inline-ool-selection";
 attribute :>> sourceAnchors="gsc/_t-c-2.scm:124-218,239;include/gambit.h.in:10325-10380";
 attribute :>> actualChain="Generator defaults inline false; OOL avoids setjmp interfering with C TCO; caller spills/restores and inspects temp1 after cproc return";
 attribute :>> hazard="Callee close cannot release caller fp/register/status borrow or impose setjmp on every GVM host";
 attribute :>> replacement="Separate callee exit ticket and caller postlude ticket; keep qualified out-of-line boundary for TCO";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="cfun-try-and-at-end";
 attribute :>> sourceAnchors="include/gambit.h.in:10382-10400;gsc/_ptree2.scm:3240-3321";
 attribute :>> actualChain="AT_END appears inside protected body before END_TRY then R_ALL_INL; an earlier throw skips AT_END";
 attribute :>> hazard="Moving AT_END after catch would newly execute user effects, not automatically preserve semantics";
 attribute :>> replacement="Record original execution condition; separate guaranteed service cleanup from optional user AT_END; explicit opt-in for changed semantics";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="cfun-conversion-error-routes";
 attribute :>> sourceAnchors="include/gambit.h.in:10353-10397";
 attribute :>> actualChain="CFUN_CONV_ERROR excludes NO_ERR and UNWIND; ordinary errors set temp fields then inline jump/OOL return before subsequent propagate_error";
 attribute :>> hazard="Blanket claim every error executes propagate_error or END_CFUN misses real exits";
 attribute :>> replacement="Distinct handler-return and UNWIND propagation tickets; outer caller remains pinned through read/reload/dispatch";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="cfun-native-release-helpers";
 attribute :>> sourceAnchors="include/gambit.h.in:10473-10525;lib/c_intf.c:1731-1802;lib/mem.c:756-825";
 attribute :>> actualChain="END_CFUN function/string conversions release RC-backed native values; string-list release can release child strings";
 attribute :>> hazard="Conversion lexical scope includes cleanup after user body/AT_END; skipping duplicates loses roots/resources";
 attribute :>> replacement="Acquired-only cleanup ledger with native/root/code ownership; exact helper effect profile, no speculative cleanup replay";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="try-catcher-stack";
 attribute :>> sourceAnchors="include/gambit.h.in:9981-10007,11699-11700;lib/setup.c:4755";
 attribute :>> actualChain="TRY saves old catcher, installs local jbuf, reads longjmp_err on jump and END restores old pointer; setup initializes catcher0";
 attribute :>> hazard="Stack jbuf and saved predecessor require live target/thread; restoration is PSTATE write";
 attribute :>> replacement="Pin exact catcher chain and native activation; restore before source borrow release; off-stack service state";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="propagate-and-throw";
 attribute :>> sourceAnchors="lib/setup.c:839-865;include/gambit.h.in:9987";
 attribute :>> actualChain="NO_ERR propagate returns; otherwise throw_error executes THROW setting longjmp_err and jumping via catcher";
 attribute :>> hazard="Seal before propagation misses a physical PSTATE write; replay can jump twice or to dead target";
 attribute :>> replacement="Reserve successor propagation debt and target pin before close; only original qualified thread executes jump";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="call-match-rethrow-trampoline";
 attribute :>> sourceAnchors="lib/setup.c:3355-3390";
 attribute :>> actualChain="Local TRY exits restore catcher; trampoline trip can repeat; only matching marker UNWIND restores fp/R0, nonmatch rethrows";
 attribute :>> hazard="Treating trampoline trip as final exit or dropping outer target pin loses live activation";
 attribute :>> replacement="Keep guard for internal trips; matching return has explicit postlude; nonmatch hands debt outward before jump";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="run-kill-skipped";
 attribute :>> sourceAnchors="lib/setup.c:3395-3420;lib/c_intf.c:6509-6564";
 attribute :>> actualChain="___run marker kill is inside TRY normal path; marker construction may allocate with input-root TODO";
 attribute :>> hazard="A thrown ___call can skip kill; new universal cleanup cannot free a marker still borrowed elsewhere";
 attribute :>> replacement="Guarded acquisition and canonical retirement result; protect proc before allocation; root/return-right duties remain separate";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="gvm-reload-consumers";
 attribute :>> sourceAnchors="include/gambit.h.in:6802-6803,10325-10380;gsc/_t-c-2.scm:213-218";
 attribute :>> actualChain="CFUN context reload and temp1/handler dispatch lead to JUMPRET; exact host macros depend on target";
 attribute :>> hazard="R_ALL or temp publication after callee seal remains source PSTATE access";
 attribute :>> replacement="Keep caller ticket until final source access or explicit GVM successor handoff; no whole-PSTATE0 from local guard";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="foreign-cleanup-callback";
 attribute :>> sourceAnchors="lib/mem.c:4387-4451;lib/c_intf.c:1683-1715;gsc/_ptree2.scm:2590-2670";
 attribute :>> actualChain="Sweep/cleanup clears foreign release fields and calls release_fn; generator emits release wrappers or supplied id";
 attribute :>> hazard="Native side effect may outlive wrapper or throw; cleared fields alone do not prove disposition";
 attribute :>> replacement="Reserve callback task/root/native/code duty before destructive detach, only admitted exception/thread/effect profiles";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="interrupt-cleanup-callback";
 attribute :>> sourceAnchors="lib/setup.c:143-204,365-419";
 attribute :>> actualChain="Normal service invokes execute_fn outside queue lock; cleanup invokes execute_fn(intr,false) while holding lock";
 attribute :>> hazard="Release callback reentrant enqueue can need same mutex; queue empty is not external admission closed";
 attribute :>> replacement="Close producers and reserve work before callback; do not wait/reenter under lock; source adaptation remains open";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="cleanup-and-native-lifetime";
 attribute :>> sourceAnchors="lib/setup.c:924-980,4569-4599,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> actualChain="Shrink/rollback/shutdown destroy PSTATE memory; ignored join follows shrink; VM later destroys shared facilities";
 attribute :>> hazard="An exception-close receipt does not retain physical backing or prove native thread termination";
 attribute :>> replacement="Require VM acceptance, independent root/domain and all pins0 before data cleanup; failed/unknown join keeps native envelope";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="setjmp-profile-boundary";
 attribute :>> sourceAnchors="include/gambit.h.in:1618-1668,8590,9981-9987;lib/setup.c:5319;examples/tcltk/tcltk.scm:124-194";
 attribute :>> actualChain="Header selects compiler builtin/library/dynamic import; BEGIN_TRY assigns setjmp return to err; real native callbacks exercise wrappers";
 attribute :>> hazard="ISO context/local/thread rules and GCC builtin constraints differ; unqualified raw longjmp/foreign ABI cannot be inferred safe";
 attribute :>> replacement="Modern C emitter gives explicit backend profile; standard setjmp in permitted context; portable guard state and no cross-thread helper jump";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Exit issuer precision";
 attribute :>> removedWork="Remove guessed closure after SFUN_CALL, END_SFUN or result delivery";
 attribute :>> bound="0 existing full issuers; 2 distinct observations: ActivationExitReady versus whole DataWriteClosed";
 attribute :>> addedCost="Typed exit plans, acquired cleanup bits and scoped receipts";
 attribute :>> condition="All conversion/error/restore/callback effects covered; raw escape refuses qualification";
 }
 part cost1 : CostRow {
 attribute :>> capability="Catcher lifetime";
 attribute :>> removedWork="Avoid stale jbuf and changed automatic-state recovery";
 attribute :>> bound="Exact predecessor/thread/frame identity; 0 helper-thread longjmp in selected protocol";
 attribute :>> addedCost="Pinned catcher chain and off-stack exit/result state";
 attribute :>> condition="Library/builtin/dynamic-import C profiles separately qualified; no blanket volatile or fence proof";
 }
 part cost2 : CostRow {
 attribute :>> capability="Propagation handoff";
 attribute :>> removedWork="Remove zero-borrow gap between original exit and outer exception receiver";
 attribute :>> bound="Register receiver before source release; transfer preserves owed work and source borrow count";
 attribute :>> addedCost="Receiver ticket, target/root/code pin and conditional restore endpoint";
 attribute :>> condition="Late or unknown propagation retains ticket; no rethrow replay from missing ACK";
 }
 part cost3 : CostRow {
 attribute :>> capability="CFUN caller postlude";
 attribute :>> removedWork="Avoid dropping PSTATE while caller reloads registers or reads temp1";
 attribute :>> bound="Separate OOL callee and caller obligations; caller pin lasts through final read/dispatch";
 attribute :>> addedCost="Generated caller ticket; preserve existing TCO-friendly OOL placement";
 attribute :>> condition="Inlining setjmp into GVM hot host is not assumed free; standard-C ABI qualification open";
 }
 part cost4 : CostRow {
 attribute :>> capability="Conversion cleanup";
 attribute :>> removedWork="Avoid skipped or repeated release_scmobj/function/string/list cleanup";
 attribute :>> bound="1 disposition per acquired conversion; no cleanup for a conversion that never succeeded";
 attribute :>> addedCost="Acquisition ledger and guarded normal/exception exit";
 attribute :>> condition="Exactly-once service decision requires original native outcome evidence; unknown effects cannot simply retry";
 }
 part cost5 : CostRow {
 attribute :>> capability="AT_END semantics";
 attribute :>> removedWork="Preserve original user cleanup execution condition";
 attribute :>> bound="0 automatic promotion of optional AT_END to universal finally";
 attribute :>> addedCost="Separate user text from guaranteed runtime-service cleanup";
 attribute :>> condition="Running skipped user text after throw is a semantic change requiring explicit admission";
 }
 part cost6 : CostRow {
 attribute :>> capability="Cleanup child debt";
 attribute :>> removedWork="Keep finalizer/interrupt callbacks counted after parent exit";
 attribute :>> bound="Reserve before child exposure/parent discharge; moving child off PSTATE does not reduce data debt";
 attribute :>> addedCost="Root/native/code tickets, callback profile and admission gate";
 attribute :>> condition="Closed enrollment rejects new child or uses separately counted successor cohort; no seal reopening";
 }
 part cost7 : CostRow {
 attribute :>> capability="Source cleanup versus GC";
 attribute :>> removedWork="Allow independent VM callback after source data cleanup, without premature freeze";
 attribute :>> bound="Source pins0 can coexist with owed callback>0; whole seal requires all current data debt0 or qualified unstarted future-epoch gate; future task debt retained";
 attribute :>> addedCost="Independent physical backing/root scan view and domain closure census";
 attribute :>> condition="Unqualified managed callback thread/GC state remains blocked; no arbitrary-death progress proof";
 }
 part cost8 : CostRow {
 attribute :>> capability="Conditional saved work";
 attribute :>> removedWork="Avoid response-loss replay of throw/cleanup/refund";
 attribute :>> bound="0 native jump/free/allocation replay from selected observation query";
 attribute :>> addedCost="Canonical protected lookup and retained unknown outcomes";
 attribute :>> condition="Positive net requires avoided duplicate effects/waits exceed ticket and retention costs; no measured speedup";
 }
 part cost9 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Retain one result/marker backing across exit and custody transfer";
 attribute :>> bound="Inherited marker +24*M(t); exit metadata O(A+J+K); Peak=max_t(H+P+N+Q)";
 attribute :>> addedCost="A activation records, J receiver/caller tickets, K cleanup debts, retained roots/code/native envelopes";
 attribute :>> condition="Metadata sizeof/alignment unqualified; unknown outcomes may retain Q indefinitely; no peak decrease proved";
 }
 part cost10 : CostRow {
 attribute :>> capability="Retirement conditions";
 attribute :>> removedWork="Replace managed END/error/cleanup scatter with generated exit service";
 attribute :>> bound="0 production paths retired today; one semantic source emits both exit and caller-postlude contracts";
 attribute :>> addedCost="Generator, runtime typed ABI, all loaded-module effect manifests and source simulation";
 attribute :>> condition="Only managed qualified cohort retires raw paths; legacy uncontrolled C cannot be silently included";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C mainline";
 attribute :>> removedWork="Preserve Gambit Scheme continuation/TCO and C portability with explicit ownership";
 attribute :>> bound="No language-specific GC/stop proof; 0 Zig-only necessary-support saving established";
 attribute :>> addedCost="Portable C/backend profiles and same root/custody/exception obligations";
 attribute :>> condition="Architecture benefit comes from compositional ownership and generated contracts; native performance still unknown";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="scheme"; attribute :>> labelText="Scheme conversion / exception semantics\\ntyped exit and cleanup plan"; }
 part node1 : DiagramNode { attribute :>> nodeId="local"; attribute :>> labelText="SFUN / CFUN local effects\\nconversion + marker + result root"; }
 part node2 : DiagramNode { attribute :>> nodeId="catcher"; attribute :>> labelText="Restore exact own catcher\\ninline reload; OOL caller ticket"; }
 part node3 : DiagramNode { attribute :>> nodeId="reserve"; attribute :>> labelText="Reserve outer receiver duty\\nbefore source can close"; }
 part node4 : DiagramNode { attribute :>> nodeId="ready"; attribute :>> labelText="ActivationExitReady\\nlocal effects closed"; }
 part node5 : DiagramNode { attribute :>> nodeId="propagate"; attribute :>> labelText="propagate / THROW / GVM dispatch\\ncounted successor effects"; }
 part node6 : DiagramNode { attribute :>> nodeId="borrow"; attribute :>> labelText="Receiver + caller postlude closed\\ncallback source pins checked separately"; }
 part node7 : DiagramNode { attribute :>> nodeId="callback"; attribute :>> labelText="Reserve cleanup child before exposure\\nVM transfer keeps data debt"; }
 part node8 : DiagramNode { attribute :>> nodeId="vm"; attribute :>> labelText="VM custody and physical root/domain audit"; }
 part node9 : DiagramNode { attribute :>> nodeId="cleanup"; attribute :>> labelText="PSTATE data cleanup permit\\nVM-independent child may remain"; }
 part node10 : DiagramNode { attribute :>> nodeId="seal"; attribute :>> labelText="DataWriteClosed / domain freeze\\nadmission closed + current debt0\\nfuture task retains custody"; }
 part node11 : DiagramNode { attribute :>> nodeId="retain"; attribute :>> labelText="Unknown target / callback / join\\nretain roots and native envelope"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C profile gaps open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="generate per exit variant"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="last local effects settled"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="exception or handler route"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="successor counted first"; }
 part edge4 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node4; attribute :>> labelText="normal no-error route"; }
 part edge5 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="successor owns pending effects"; }
 part edge6 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="receiver and caller finish"; }
 part edge7 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node7; attribute :>> labelText="before destructive cleanup"; }
 part edge8 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="independent root/native custody"; }
 part edge9 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node9; attribute :>> labelText="original / receiver / caller pins zero"; }
 part edge10 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="observed physical acceptance"; }
 part edge11 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node10; attribute :>> labelText="drain current effects or qualified future gate"; }
 part edge12 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node10; attribute :>> labelText="all current propagation drained"; }
 part edge13 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node10; attribute :>> labelText="closed registered root view"; }
 part edge14 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node11; attribute :>> labelText="unknown native envelope"; }
 part edge15 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node11; attribute :>> labelText="unknown live target or result"; }
 part edge16 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node3; attribute :>> labelText="debt preservation"; }
 part edge17 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node10; attribute :>> labelText="conditional source refinement"; }
}
