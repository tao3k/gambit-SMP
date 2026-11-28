/* Future epoch gate and reentry research for modern C; no native admission. */
package GambitFutureEpochReentryGate {
 private import ScalarValues::*;
 part def GateState { attribute issued : Boolean; attribute producerClosed : Boolean; attribute publicationDebt : Integer; attribute claimDebt : Integer; attribute unstarted : Boolean; attribute nativeInvocationExcluded : Boolean; attribute vmCustody : Boolean; }
 requirement def FutureGateLaw { subject g : GateState; require constraint { not g.issued or (g.producerClosed and g.publicationDebt==0 and g.claimDebt==0 and g.unstarted and g.nativeInvocationExcluded and g.vmCustody) } }
 part def ReentryState { attribute authorized : Boolean; attribute expectedEpoch : Integer; attribute currentEpoch : Integer; attribute roundComplete : Boolean; attribute contextReady : Boolean; attribute ownerBound : Boolean; attribute rootsReloaded : Boolean; }
 requirement def ReentryLaw { subject r : ReentryState; require constraint { not r.authorized or (r.expectedEpoch==r.currentEpoch and r.roundComplete and r.contextReady and r.ownerBound and r.rootsReloaded) } }
 ref part inheritedLayout32=GambitManagedMarkerLayout::layout32;
 ref part inheritedLayout64=GambitManagedMarkerLayout::layout64;
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/future_epoch_reentry_gate.qnt";
 attribute :>> subjectScope="future_epoch_reentry_gate:37-named-histories;admitted;queued+running;epochs0and1;seed=17;each100x100";
 attribute :>> premise="One owned async task, publication ticket, queue/claim/native-issue/running/parked/future/completed states and two epochs; queued and running profiles; early native gate, complete adapters, atomic claim/cancel, participating parked root view and whole-round preparation are premises; no full collector, arbitrary recursion, C source/ABI/weak-memory or liveness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="GambitSMP.FutureEpochReentryGate:closeDoesNotRevokeReservation;closeDoesNotDrainWriter;claimedBlocksSeal;writerBlocksSeal;publicationBlocksSeal;startedCannotDefer;issuedCannotDefer;synchronousCannotDefer;deferredKeepsRoots;deferredKeepsResources;staleEpochRejected;staleRootRejected;unpreparedContextRejected;missingBindingRejected;notificationAloneInsufficient;claimPreserves;parkPreserves;resumePreserves;finishPreserves;resumeDoesNotReinvoke;claimUsesFreshEpoch;stepPreserves;tracePreserves;completedCannotClaimAgain";
 attribute :>> premise="24 conditional declarations: gate closure does not drain existing work, deferred-task exclusions, epoch/context/root/binding authorization and custody Step/Trace, parked resume keeps invocation count; not every QNT action or C source simulation";
 }
 part issuance : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-ISSUE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="FG-ISSUE:actual-source-refinement";
 attribute :>> premise="No existing future-epoch execution-gate issuer; introduce VM-owned AdmissionDomain keyed by VM/domain/epoch/incarnation, with early native ingress covering every callback origin before data_rc, marker allocation, PSTATE reads or closure-self mutation; stop current publication admission, reconcile publication postludes and all claim reservations, then sign FutureEpochGate for retained unstarted async tasks only after canonical VM root/resource/code custody and manifest/exclusion evidence";
 }
 part queueCut : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-QUEUE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="FG-QUEUE:actual-source-refinement";
 attribute :>> premise="Owned procedural interrupt queue needs one ordered dequeue-to-claim and close-to-detach cut under compatible exclusion; register claim before removing head/unlocking, count publisher from header initialization through queue insertion and post-unlock raise_interrupt_pstate; queued task may move to VM future queue with exact execution/release operation semantics, borrowed argument snapshot and custody; preserve accepted enqueue order and per-origin result causality, including canceled claim position unless reordering separately admitted; empty old queue or interrupt masking is not zero in-flight work";
 }
 part inflight : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-FLIGHT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="FG-FLIGHT:actual-source-refinement";
 attribute :>> premise="Already claimed/native-issued/running invocation is not an unstarted future task; unissued owned claim may cancel only under same atomic arbitration as native issue/start, lost claim response remains canonical duty; running invocation either completes or participates in GC with a qualified parked-current root/continuation/PSTATE view and revoked current write permit; parked native activation retains catcher/code/resource identity and resumes in place, never replayed as new callback";
 }
 part reentry : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-REENTRY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="FG-REENTRY:actual-source-refinement";
 attribute :>> premise="After full strong/weak/cleanup/capacity result and selected context preparation, bind exact live owner/VM context, reload relocated root handles, then publish next epoch authority; GC interrupt notification alone precedes prepare_mem_pstate and is not WholeRoundResumeSeal; claimFuture atomically joins next epoch before marker allocation and Scheme entry, parked resume obtains fresh write authority for same native activation; stale old epoch/context/root/owner rejects without guessed rebind";
 }
 part custody : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-CUSTODY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="FG-CUSTODY:actual-source-refinement";
 attribute :>> premise="Future task and parked current invocation retain GC-visible roots, immutable input snapshots or qualified borrowed storage, native payload/code/catcher leases and exact result identity; VM transfer is not disposal, nonzero processor roots require all-domain scanner integration, native deletion/refcount decrement cannot reclaim before old invocation borrowers drain; unknown native or claim outcome retains custody and cannot authorize replay/refund";
 }
 part semantics : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-SEMANTICS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="FG-SEMANTICS:actual-source-refinement";
 attribute :>> premise="Defer only an origin whose request/result contract permits retained asynchronous task and whose pre-entry transport has no unknown issued invocation; direct synchronous Tcl scheme_call_cmd needs immediate char-string result and borrowed argv, so deferring inside it or returning invented success/pending is not equivalent; gate upstream initiation, qualify participating wait on original invocation, or refuse future-task admission; no synchronous GC wait for a callback whose entry waits for that same GC";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="FG-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/FutureEpochReentryGate.lean";
 attribute :>> subjectScope="FG-ORDER:actual-C-memory-and-adapter-refinement";
 attribute :>> premise="Close/claim/cancel/native-issue publish under one canonical atomic/exclusion protocol; release certificate follows last current writer and publisher postlude, acquire certifier sees roots and parked views; next epoch release follows capacity/context/binding/root reload and acquire claimant joins matching epoch; all raw callbacks use compatible lifetime-protected ingress before first managed effect; counter generation alone cannot revoke issued stores or cached function pointers, actual C atomic layout and native ABI remain open";
 }
 ref part priorCatcher=GambitFfiExitCatcherClosure::catcher;
 ref part priorPropagation=GambitFfiExitCatcherClosure::propagation;
 ref part priorBorrows=GambitFfiExitCatcherClosure::borrows;
 ref part priorCallbacks=GambitFfiExitCatcherClosure::callbacks;
 ref part priorRetirement=GambitFfiExitCatcherClosure::retirement;
 ref part priorOrder=GambitFfiExitCatcherClosure::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=queueCut; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=queueCut; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=queueCut; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inflight; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inflight; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inflight; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=priorRetirement; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=issuance; ref part :>> prerequisite=queueCut; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=queueCut; ref part :>> prerequisite=priorCallbacks; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inflight; ref part :>> prerequisite=queueCut; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inflight; ref part :>> prerequisite=priorBorrows; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=inflight; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=priorCatcher; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=priorCallbacks; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=priorRetirement; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=priorPropagation; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=semantics; ref part :>> prerequisite=issuance; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=custody; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=inflight; ref part :>> prerequisite=priorCatcher; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=queueCut; }
 part issuanceRoute : GambitHostRootsRefinement::Route { ref part :>> need=issuance;
 attribute :>> sourceAnchors="lib/setup.c:365-393,66-91;lib/setup.c:143-154;include/gambit.h.in:11588,13469-13477,14946-14954;lib/os_dyn.c:744-790,1045-1058;gsc/_ptree2.scm:2902-3030,3145-3187;include/gambit.h.in:10043-10059;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6138-6142;tests/server.scm:15-35";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="No existing future-epoch execution-gate issuer; introduce VM-owned AdmissionDomain keyed by VM/domain/epoch/incarnation, with early native ingress covering every callback origin before data_rc, marker allocation, PSTATE reads or closure-self mutation; stop current publication admission, reconcile publication postludes and all claim reservations, then sign FutureEpochGate for retained unstarted async tasks only after canonical VM root/resource/code custody and manifest/exclusion evidence";
 attribute :>> failureCustodian="Canonical VM service retains future task and parked-current roots/resource/code/native identity; old publisher/claimed/issued duty survives closure and unknown response; no invocation replay, guessed cleanup/refund or helper-thread longjmp; mismatch refuses reentry; native lifetime remains separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part queueCutRoute : GambitHostRootsRefinement::Route { ref part :>> need=queueCut;
 attribute :>> sourceAnchors="lib/setup.c:365-393,66-91;lib/setup.c:170-204;lib/setup.c:158-166,396-419;lib/setup.c:143-154;include/gambit.h.in:11588,13469-13477,14946-14954";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Owned procedural interrupt queue needs one ordered dequeue-to-claim and close-to-detach cut under compatible exclusion; register claim before removing head/unlocking, count publisher from header initialization through queue insertion and post-unlock raise_interrupt_pstate; queued task may move to VM future queue with exact execution/release operation semantics, borrowed argument snapshot and custody; preserve accepted enqueue order and per-origin result causality, including canceled claim position unless reordering separately admitted; empty old queue or interrupt masking is not zero in-flight work";
 attribute :>> failureCustodian="Canonical VM service retains future task and parked-current roots/resource/code/native identity; old publisher/claimed/issued duty survives closure and unknown response; no invocation replay, guessed cleanup/refund or helper-thread longjmp; mismatch refuses reentry; native lifetime remains separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part inflightRoute : GambitHostRootsRefinement::Route { ref part :>> need=inflight;
 attribute :>> sourceAnchors="lib/setup.c:170-204;lib/setup.c:158-166,396-419;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;lib/os_thread.c:697-710;lib/setup.c:815-833,6400-6411;lib/setup.c:3276-3420;lib/_kernel.scm:1020-1072;include/gambit.h.in:9981-9987;lib/setup.c:924-980,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Already claimed/native-issued/running invocation is not an unstarted future task; unissued owned claim may cancel only under same atomic arbitration as native issue/start, lost claim response remains canonical duty; running invocation either completes or participates in GC with a qualified parked-current root/continuation/PSTATE view and revoked current write permit; parked native activation retains catcher/code/resource identity and resumes in place, never replayed as new callback";
 attribute :>> failureCustodian="Canonical VM service retains future task and parked-current roots/resource/code/native identity; old publisher/claimed/issued duty survives closure and unknown response; no invocation replay, guessed cleanup/refund or helper-thread longjmp; mismatch refuses reentry; native lifetime remains separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part reentryRoute : GambitHostRootsRefinement::Route { ref part :>> need=reentry;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030,3145-3187;include/gambit.h.in:10043-10059;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;lib/mem.c:7003-7085;lib/setup.c:1182-1200;lib/mem.c:4525-4567,7040-7085;lib/mem.c:3969-3987,6844-6867;lib/mem.c:684-825;lib/os_thread.c:697-710;lib/setup.c:815-833,6400-6411;lib/setup.c:3276-3420;lib/_kernel.scm:1020-1072;include/gambit.h.in:9981-9987";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="After full strong/weak/cleanup/capacity result and selected context preparation, bind exact live owner/VM context, reload relocated root handles, then publish next epoch authority; GC interrupt notification alone precedes prepare_mem_pstate and is not WholeRoundResumeSeal; claimFuture atomically joins next epoch before marker allocation and Scheme entry, parked resume obtains fresh write authority for same native activation; stale old epoch/context/root/owner rejects without guessed rebind";
 attribute :>> failureCustodian="Canonical VM service retains future task and parked-current roots/resource/code/native identity; old publisher/claimed/issued duty survives closure and unknown response; no invocation replay, guessed cleanup/refund or helper-thread longjmp; mismatch refuses reentry; native lifetime remains separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part custodyRoute : GambitHostRootsRefinement::Route { ref part :>> need=custody;
 attribute :>> sourceAnchors="lib/os_dyn.c:744-790,1045-1058;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;examples/tcltk/tcltk.scm:178-194,58-120;lib/c_intf.c:1757-1802;lib/mem.c:3969-3987,6844-6867;lib/mem.c:684-825;lib/setup.c:3276-3420;lib/_kernel.scm:1020-1072;include/gambit.h.in:9981-9987;lib/setup.c:924-980,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Future task and parked current invocation retain GC-visible roots, immutable input snapshots or qualified borrowed storage, native payload/code/catcher leases and exact result identity; VM transfer is not disposal, nonzero processor roots require all-domain scanner integration, native deletion/refcount decrement cannot reclaim before old invocation borrowers drain; unknown native or claim outcome retains custody and cannot authorize replay/refund";
 attribute :>> failureCustodian="Canonical VM service retains future task and parked-current roots/resource/code/native identity; old publisher/claimed/issued duty survives closure and unknown response; no invocation replay, guessed cleanup/refund or helper-thread longjmp; mismatch refuses reentry; native lifetime remains separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part semanticsRoute : GambitHostRootsRefinement::Route { ref part :>> need=semantics;
 attribute :>> sourceAnchors="lib/setup.c:158-166,396-419;lib/setup.c:143-154;include/gambit.h.in:11588,13469-13477,14946-14954;examples/tcltk/tcltk.scm:124-175,221-228;examples/tcltk/tcltk.scm:178-194,58-120;lib/c_intf.c:1757-1802;lib/setup.c:3276-3420;lib/_kernel.scm:1020-1072;include/gambit.h.in:9981-9987";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Defer only an origin whose request/result contract permits retained asynchronous task and whose pre-entry transport has no unknown issued invocation; direct synchronous Tcl scheme_call_cmd needs immediate char-string result and borrowed argv, so deferring inside it or returning invented success/pending is not equivalent; gate upstream initiation, qualify participating wait on original invocation, or refuse future-task admission; no synchronous GC wait for a callback whose entry waits for that same GC";
 attribute :>> failureCustodian="Canonical VM service retains future task and parked-current roots/resource/code/native identity; old publisher/claimed/issued duty survives closure and unknown response; no invocation replay, guessed cleanup/refund or helper-thread longjmp; mismatch refuses reentry; native lifetime remains separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/setup.c:365-393,66-91;lib/setup.c:170-204;lib/setup.c:158-166,396-419;lib/setup.c:143-154;include/gambit.h.in:11588,13469-13477,14946-14954;lib/os_dyn.c:744-790,1045-1058;gsc/_ptree2.scm:2902-3030,3145-3187;include/gambit.h.in:10043-10059;lib/c_intf.c:6509-6564;lib/mem.c:1778-1821;examples/tcltk/tcltk.scm:124-175,221-228;examples/tcltk/tcltk.scm:178-194,58-120;lib/c_intf.c:1757-1802;lib/mem.c:7003-7085;lib/setup.c:1182-1200;lib/mem.c:4525-4567,7040-7085;lib/mem.c:3969-3987,6844-6867;lib/mem.c:684-825;lib/os_thread.c:697-710;lib/setup.c:815-833,6400-6411;lib/setup.c:3276-3420;lib/_kernel.scm:1020-1072;include/gambit.h.in:9981-9987;lib/setup.c:924-980,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592;include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6138-6142;tests/server.scm:15-35";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Close/claim/cancel/native-issue publish under one canonical atomic/exclusion protocol; release certificate follows last current writer and publisher postlude, acquire certifier sees roots and parked views; next epoch release follows capacity/context/binding/root reload and acquire claimant joins matching epoch; all raw callbacks use compatible lifetime-protected ingress before first managed effect; counter generation alone cannot revoke issued stores or cached function pointers, actual C atomic layout and native ABI remain open";
 attribute :>> failureCustodian="Canonical VM service retains future task and parked-current roots/resource/code/native identity; old publisher/claimed/issued duty survives closure and unknown response; no invocation replay, guessed cleanup/refund or helper-thread longjmp; mismatch refuses reentry; native lifetime remains separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="publication-through-wakeup";
 attribute :>> sourceAnchors="lib/setup.c:365-393,66-91";
 attribute :>> actualChain="Publisher writes h.next before lock, links queue under mutex, unlocks then raises interrupt using target PSTATE and select-abort";
 attribute :>> hazard="Closing only queue link leaves post-unlock PSTATE writes or native device wakeup outstanding";
 attribute :>> replacement="Publication lease begins before header effect and ends after wakeup; close producer admission, preserve exact target incarnation";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="dequeue-before-call";
 attribute :>> sourceAnchors="lib/setup.c:170-204";
 attribute :>> actualChain="Service removes head and updates tail under mutex, unlocks before execute_fn(intr,true)";
 attribute :>> hazard="Queue empty while callback claimed or executing; no current active-call registry in this route";
 attribute :>> replacement="Publish claim under same exclusion as dequeue before unlocking; close gate wins or registered claim remains owed";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="cleanup-callback-under-lock";
 attribute :>> sourceAnchors="lib/setup.c:158-166,396-419";
 attribute :>> actualChain="Cleanup walks queue and invokes execute_fn(intr,false) while queue mutex held";
 attribute :>> hazard="Calling Scheme or reentrant enqueue under lock can wait on this GC or same lock";
 attribute :>> replacement="Detach admitted release duties under lock; execute later with explicit effect/owner profile, not guessed cancellation semantics";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="external-execute-function";
 attribute :>> sourceAnchors="lib/setup.c:143-154;include/gambit.h.in:11588,13469-13477,14946-14954";
 attribute :>> actualChain="Init accepts arbitrary execute_fn; GSTATE exports init/raise interface";
 attribute :>> hazard="Local queue code cannot prove external producer quiescence, borrowed payload stability or true/false operation equivalence";
 attribute :>> replacement="Typed origin/effect/result manifest and unregister/drain or owned queue exclusion; refuse unregistered raw origins";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="raw-c-closure-trampoline";
 attribute :>> sourceAnchors="lib/os_dyn.c:744-790,1045-1058";
 attribute :>> actualChain="Native closure writes global c_closure_self before generated converter; RC payload stores Scheme proc";
 attribute :>> hazard="Gate solely inside ___call is after raw ingress effect/root read; cached function pointer survives logical generation change";
 attribute :>> replacement="Stable typed native entry thunk and metadata/code lease before first relevant effect; qualify global/TLS closure identity redesign";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="generated-sfun-entry";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030,3145-3187;include/gambit.h.in:10043-10059";
 attribute :>> actualChain="Generated callback fetches PSTATE, allocates marker, converts parameters, calls Scheme and may retry handler";
 attribute :>> hazard="Late gate after BEGIN_SFUN already touched owner context and roots";
 attribute :>> replacement="Generate admission/epoch/owner ticket before PSTATE-dependent conversions and marker allocation; preserve result ABI";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="marker-input-roots";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564;lib/mem.c:1778-1821";
 attribute :>> actualChain="make_marker allocates vector before copying proc; source root TODO remains; kill clears then refcount decrements";
 attribute :>> hazard="Future queue metadata alone does not protect movable input or keep native frame valid";
 attribute :>> replacement="VM root handle before marker allocation, fresh root reload after GC, retained native activation for parked path";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="tcl-synchronous-result";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-175,221-228";
 attribute :>> actualChain="scheme_call_cmd calls tcltk_call synchronously and immediately installs returned char string into Tcl";
 attribute :>> hazard="Returning pending/success while Scheme result not computed changes command semantics; argv strings borrowed from native call";
 attribute :>> replacement="No blanket task deferral; upstream host initiation gate or participating same-call wait, with separate result/input ownership";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="tcl-delete-and-result-free";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:178-194,58-120;lib/c_intf.c:1757-1802";
 attribute :>> actualChain="Delete callback releases Scheme object and RC client_data; result release later invokes Gambit release_string";
 attribute :>> hazard="Deletion or wrapper refcount alone is no proof every copied/native invocation pointer has drained";
 attribute :>> replacement="Native library origin lifetime evidence plus wrapper active leases; result and client_data custody survive deletion until actual borrower drain";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="gc-phases-and-notification";
 attribute :>> sourceAnchors="lib/mem.c:7003-7085;lib/setup.c:1182-1200";
 attribute :>> actualChain="Strong/weak/cleanup barriers and P0 resize precede per-PSTATE continuation prep; P0 raises INTR_GC before prepare_mem_pstate";
 attribute :>> hazard="GC notification is not proof all context/root/phase gates ready for external reentry";
 attribute :>> replacement="Coordinator canonical whole-round result and participant preparation receipts before next epoch publish; no current gate issuer inferred";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="context-capacity-preparation";
 attribute :>> sourceAnchors="lib/mem.c:4525-4567,7040-7085";
 attribute :>> actualChain="prepare_mem_pstate writes fp/hp and stack/heap limits, refreshes interrupt limits; heap fudge can acquire next msection";
 attribute :>> hazard="A root-safe task still cannot use old allocators/context limits after GC";
 attribute :>> replacement="Bind next context incarnation/capacity outcome and reload roots before claim authorizes any managed allocation";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="root-view-all-domains";
 attribute :>> sourceAnchors="lib/mem.c:3969-3987,6844-6867;lib/mem.c:684-825";
 attribute :>> actualChain="Per-PSTATE RC payloads; mark_rc occurs in P0 branch; continuation/register/saved roots scanned per processor";
 attribute :>> hazard="Transferred nonzero roots or native-held closure cannot be inferred covered from current P0 scan";
 attribute :>> replacement="All-domain VM root registry and frozen parked view, stable handles with post-copy reload; preserve independent RC and still ownership";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="owner-binding";
 attribute :>> sourceAnchors="lib/os_thread.c:697-710;lib/setup.c:815-833,6400-6411";
 attribute :>> actualChain="thread_set_pstate sets binding/TLS and affinity; startup attaches owner before execution";
 attribute :>> hazard="Processor integer/TLS pointer alone is not next-epoch permission or native activation identity";
 attribute :>> replacement="Exact VM/context/native-thread incarnation binding and fresh permission; unknown/mismatched owner refuses entry";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="native-return-continuation";
 attribute :>> sourceAnchors="lib/setup.c:3276-3420;lib/_kernel.scm:1020-1072;include/gambit.h.in:9981-9987";
 attribute :>> actualChain="___call and return handler preserve native marker/catcher return rights; wrong processor or repeat return rejected";
 attribute :>> hazard="Parked same call cannot be replayed as a fresh task or jumped by worker thread";
 attribute :>> replacement="Participating wait keeps catcher/continuation roots/native stack live; resume same invocation under new write lease";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="resize-cleanup-join";
 attribute :>> sourceAnchors="lib/setup.c:924-980,4665-4672,4834-4875;lib/mem.c:4928-4964;lib/os_thread.c:546-592";
 attribute :>> actualChain="PSTATE cleanup destroys still/RC/OS resources; shrink joins later and ignores result; VM destroys shared scan facilities";
 attribute :>> hazard="Future task or parked native borrower may outlive source; failed/unknown join does not authorize code/context free";
 attribute :>> replacement="Canonical VM custody and source borrower closure before data cleanup; retain native envelope on unknown stop";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="opaque-native-escape";
 attribute :>> sourceAnchors="include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6138-6142;tests/server.scm:15-35";
 attribute :>> actualChain="Public native callback/marker/interrupt functions and real c-define callbacks expose entry capabilities";
 attribute :>> hazard="Swapping pointer or emptying owned queue cannot revoke cached foreign pointer or already-issued machine invocation";
 attribute :>> replacement="Complete loaded origin/entry manifest, early stable thunk and transport exclusion receipt; unknown alias keeps qualification open";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Gate issuance";
 attribute :>> removedWork="Replace assumed unstarted bit with ordered source-backed exclusion";
 attribute :>> bound="0 existing full issuers; close producers + publication debt0 + exact claim census";
 attribute :>> addedCost="AdmissionDomain, origin registry and canonical certificate";
 attribute :>> condition="Unknown raw aliases or transport invocation refuse task qualification";
 }
 part cost1 : CostRow {
 attribute :>> capability="Publisher lifetime";
 attribute :>> removedWork="Include writes after queue publication";
 attribute :>> bound="1 publication ticket spans header, queue and PSTATE wakeup";
 attribute :>> addedCost="One ticket per active publisher and target/code lease";
 attribute :>> condition="Queue detach alone cannot retire source PSTATE or wakeup resources";
 }
 part cost2 : CostRow {
 attribute :>> capability="Queue versus claim";
 attribute :>> removedWork="Avoid treating queue empty as callback quiescence";
 attribute :>> bound="Reserve claim before dequeue unlock; close and claim have one ordered winner";
 attribute :>> addedCost="Claim state and canonical outcome query";
 attribute :>> condition="Unknown claim response retains obligation; no replay from missing ACK";
 }
 part cost3 : CostRow {
 attribute :>> capability="Already-running invocation";
 attribute :>> removedWork="Allow participating pause without demanding callback completion before its GC";
 attribute :>> bound="Started invocation remains parked-current; resume does not increment invocation count";
 attribute :>> addedCost="Frozen roots, revoked current write permit, native catcher/owner lease";
 attribute :>> condition="Unqualified active callback must drain or remain unresolved; never reclassify as unstarted future task";
 }
 part cost4 : CostRow {
 attribute :>> capability="Synchronous result boundary";
 attribute :>> removedWork="Avoid deferred result changing Tcl command semantics";
 attribute :>> bound="0 automatic async conversion of synchronous callback";
 attribute :>> addedCost="Origin/result/input ownership classification, upstream gate if possible";
 attribute :>> condition="Future-task path rejected unless async contract or equivalent same-call participating wait is proved";
 }
 part cost5 : CostRow {
 attribute :>> capability="Fresh next-epoch reentry";
 attribute :>> removedWork="Remove reliance on stale PSTATE/root/epoch permission";
 attribute :>> bound="Next claim after whole-round, context preparation, owner binding and root reload; old seal immutable";
 attribute :>> addedCost="Prepared context/root version, per-claim epoch membership and C entry ticket";
 attribute :>> condition="INTR_GC notification or reused processor id alone insufficient";
 }
 part cost6 : CostRow {
 attribute :>> capability="Root and native custody";
 attribute :>> removedWork="Retain original task backing across GC and source removal";
 attribute :>> bound="1 physical task/result backing; queued and parked live objects retain roots/resources/code";
 attribute :>> addedCost="VM all-domain root view, stable handles, transitive payload and code leases";
 attribute :>> condition="Transfer is not refund; unknown deletion/readers keep custody and may retain memory";
 }
 part cost7 : CostRow {
 attribute :>> capability="Wait-cycle avoidance";
 attribute :>> removedWork="Permit GC without executing an unstarted future task";
 attribute :>> bound="No coordinator wait for future task execution; same-call parked path retains return identity";
 attribute :>> addedCost="Admission gate and participating wait/resume handshake";
 attribute :>> condition="Callback cannot wait on GC while holding required queue/publication locks; gate premise still needs native proof";
 }
 part cost8 : CostRow {
 attribute :>> capability="Canonical task execution";
 attribute :>> removedWork="Avoid duplicate invocation on lost claim/result response";
 attribute :>> bound="At most1 initial invocation per modeled task; parked resume adds0; query adds0";
 attribute :>> addedCost="Canonical task identity/claim record and protected lookup";
 attribute :>> condition="Native invocation issue/cancel arbitration required; no exactly-once external side-effect proof";
 }
 part cost9 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Transfer backing instead of copying task merely for epoch change";
 attribute :>> bound="Inherited marker +24*M(t); gate metadata O(P+C+T); Peak=max_t(H+P+N+Q)";
 attribute :>> addedCost="P publishers, C claim/parked leases, T future tasks, roots/code/native envelopes";
 attribute :>> condition="Deferred task memory remains charged; unbounded arrivals/unknown readers can make Q unbounded; no peak decrease proved";
 }
 part cost10 : CostRow {
 attribute :>> capability="Retirement conditions";
 attribute :>> removedWork="Replace unsafe raw managed enqueue/dequeue/direct-entry and notification-as-permission paths";
 attribute :>> bound="0 production paths retired today; owned qualified cohort only";
 attribute :>> addedCost="Scheme-generated ingress/exit profile plus modern C AdmissionDomain and all-domain roots";
 attribute :>> condition="Every origin, producer postlude, parked participant, next-epoch and native-order gap must close first";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C architecture";
 attribute :>> removedWork="Make asynchronous tasks, native activation and execution context compositional";
 attribute :>> bound="0 Zig-only necessary-support reduction established; same native transport/root/GC semantics";
 attribute :>> addedCost="Typed C service and Scheme effect generator, separate context/participant/worker roles";
 attribute :>> condition="Net benefit conditional on removed waits/replays/duplication exceeding gate and retention costs; no measured speedup";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="origin"; attribute :>> labelText="Origin / effect / result manifest\\nasync task or synchronous native call"; }
 part node1 : DiagramNode { attribute :>> nodeId="producer"; attribute :>> labelText="Close publisher admission\\nretain header + wakeup tickets"; }
 part node2 : DiagramNode { attribute :>> nodeId="entry"; attribute :>> labelText="Close early native entry gate\\nclaim before dequeue unlock"; }
 part node3 : DiagramNode { attribute :>> nodeId="future"; attribute :>> labelText="FutureEpochGate\\nunstarted task; VM roots/resources held"; }
 part node4 : DiagramNode { attribute :>> nodeId="active"; attribute :>> labelText="Claimed / issued / running\\nnot an unstarted future task"; }
 part node5 : DiagramNode { attribute :>> nodeId="park"; attribute :>> labelText="Complete or parked-current\\nfrozen roots + native return identity"; }
 part node6 : DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="Current data quiescence -> GC\\nfuture execution not required"; }
 part node7 : DiagramNode { attribute :>> nodeId="prepare"; attribute :>> labelText="Whole-round result + context capacity\\nowner binding + relocated root reload"; }
 part node8 : DiagramNode { attribute :>> nodeId="nextEpoch"; attribute :>> labelText="Publish fresh next epoch authority\\nold seal stays immutable"; }
 part node9 : DiagramNode { attribute :>> nodeId="claim"; attribute :>> labelText="Atomic future claim / parked resume\\nbefore marker allocation and Scheme"; }
 part node10 : DiagramNode { attribute :>> nodeId="custody"; attribute :>> labelText="VM task/root/native/code custody\\ntransfer is not disposal"; }
 part node11 : DiagramNode { attribute :>> nodeId="refuse"; attribute :>> labelText="Unknown raw call / sync result / owner\\nretain debt; refuse unsafe admission"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C memory gaps open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="admitted origins only"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="publication postludes drain"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="queued and invocation excluded"; }
 part edge3 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node4; attribute :>> labelText="claim won or already issued"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="no forced completion wait cycle"; }
 part edge5 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node6; attribute :>> labelText="cannot execute in current epoch"; }
 part edge6 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="qualified frozen current view"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="GC notification alone insufficient"; }
 part edge8 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="all readiness receipts"; }
 part edge9 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="fresh membership before effects"; }
 part edge10 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node3; attribute :>> labelText="root/resource/code accepted before gate"; }
 part edge11 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node5; attribute :>> labelText="native/root backing retained"; }
 part edge12 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node9; attribute :>> labelText="reload stable root handles"; }
 part edge13 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node11; attribute :>> labelText="unqualified sync or raw contract"; }
 part edge14 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node11; attribute :>> labelText="unknown invocation or park proof"; }
 part edge15 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node11; attribute :>> labelText="stale context / roots / binding"; }
 part edge16 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node10; attribute :>> labelText="prepare canonical backing"; }
 part edge17 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node8; attribute :>> labelText="fresh authorization proof"; }
}
