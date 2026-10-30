/* Interrupted publication research for modern C; no runtime admission. */
package GambitMarkerInterruptedPublication {
 private import ScalarValues::*;
 part def StopState { attribute certified : Boolean; attribute exactIdentity : Boolean; attribute allWriters : Boolean; attribute pendingEffects : Integer; attribute lifetimeValid : Boolean; }
 requirement def StopLaw { subject w : StopState; require constraint { not w.certified or (w.exactIdentity and w.allWriters and w.pendingEffects==0 and w.lifetimeValid) } }
 part def DecisionState { attribute published : Boolean; attribute rootReady : Boolean; attribute envelopeReady : Boolean; attribute ticketRole : String; }
 requirement def DecisionLaw { subject d : DecisionState; require constraint { not d.published or (d.rootReady and d.envelopeReady and d.ticketRole=="Live") } }
 ref part inheritedLayout32=GambitManagedMarkerLayout::layout32;
 ref part inheritedLayout64=GambitManagedMarkerLayout::layout64;
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/marker_interrupted_publication.qnt";
 attribute :>> subjectScope="marker_interrupted_publication:32-named-histories;admitted;owner+helper;domain1;seed=17;each100x100";
 attribute :>> premise="One canonical operation in domain1, original writer and helper, delayed stores, old/new head observations and one decision; ordinary and helper-entry profiles; atomic head/decision effects, complete stop certificates and root/layout/domain custody are premises; not C weak-memory, arbitrary machine interruption or liveness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="GambitSMP.MarkerInterruptedPublication:settleEstablishesLink;linkedSettlementIsIdentity;settleIsIdempotent;noSelfLinkAfterSettlement;sameAckDifferentHead;ackAloneCannotDecode;generationDoesNotDrain;revokedPendingRemains;pendingRejectsStop;wrongIdentityRejectsStop;omittedHelperRejectsStop;failedJoinWithoutCooperationRejectsStop;stoppedButUnrootedRejectsTakeover;stoppedButInvalidShapeRejectsTakeover;unrecoverableLockRejectsTakeover;commitPreserves;commitIsIdempotent;derivedCreditConserves;stepPreserves;tracePreserves;commitAloneDoesNotDrain;nullSnapshotsSameObservation;noCompletePendingDecoder";
 attribute :>> premise="23 conditional declarations: link reconciliation/idempotence, ACK observation ambiguity, generation does not drain, stop/takeover gates, decision/query Step/Trace and derived-credit conservation; not every QNT transition or C source simulation";
 }
 part intent : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-INTENT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="IP-INTENT:actual-source-refinement";
 attribute :>> premise="Immutable LinkIntent publishes exact operation/VM/domain/generation, fresh node not already in the well-formed old chain, old head, body proof, root and allocation tickets before first link effect; journal ACKs follow data and may lag it; helpers never trust partly prepared record or ACK absence alone; intent, root cells, domain and native code backing outlive all original/helper borrowers";
 }
 part link : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-LINK";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="IP-LINK:actual-source-refinement";
 attribute :>> premise="Controlled cohort uses real atomic native head with all readers adapted; under stable exclusive domain authority after prior writer stop, head==old permits reconstruction of node.next from immutable intent then release publication, head==node with next==old confirms success without reinsertion, every other head/shape refuses; next remains immutable after head visibility until exclusive sweep; no mixing atomic head with old raw PSTATE stores";
 }
 part stop : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-STOP";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="IP-STOP:actual-source-refinement";
 attribute :>> premise="StopCertificate names exact operation, writer/thread incarnation, domain lease and every helper lineage; normal cooperative endpoint closes future stores, or exact successful native termination/join plus drained final effects supports native stop; logical Scheme exit, generation increment, timeout, pthread id reuse or failed/ignored join do not; known stop alone does not recover locks, freed storage or invalid structure";
 }
 part decision : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-DECISION";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="IP-DECISION:actual-source-refinement";
 attribute :>> premise="Commit publishes one pre-backed immutable DecisionEnvelope pointer by atomic compare-exchange after body/list/root installation; envelope holds stable root handles and allocation ticket, not untracked movable SCMOBJ; ticket role reserved/live and result come from same decision; no scalar increment/decrement replay; null before stop is pending observation, nonnull qualifies committed result but not writer drain";
 }
 part custody : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-CUSTODY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="IP-CUSTODY:actual-source-refinement";
 attribute :>> premise="Unknown head/commit result retains operation, root and domain lease; after known stop helpers reconcile actual atomic head/decision, finish exact existing operation and never allocate/free or jump native frame from query; committed outcome with pending writers still refuses GC freeze; GC coordinator does not block holding a lock needed by target/helper, no join/GC barrier wait cycle";
 }
 part retirement : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-RETIRE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="IP-RETIRE:actual-source-refinement";
 attribute :>> premise="DataWriteClosed covers original and all helpers before lease withdrawal and GC freeze; raw already-issued stores are not revoked by token change; protected metadata readers may outlive heap-write closure but prevent control/decision reuse; no ABA reuse while old borrowers can issue effect; move operation/domain/root backing to VM service before PSTATE cleanup and preserve committed result custody separately from native activation";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="IP-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/MarkerInterruptedPublication.lean";
 attribute :>> subjectScope="IP-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Actual C acquire/release and atomic object layout refine immutable-intent visibility, next-before-head publication, observed head classification and one decision CAS; all accesses use compatible types and lifetime protection; compiler/target lock-free support is not assumed, owner-death inside nonrecoverable atomic/lock backend remains unsupported; stop certificates establish no future effects before freeze/reuse";
 }
 ref part priorEntry=GambitMarkerJointPublication::entryRoots;
 ref part priorPublication=GambitMarkerJointPublication::publication;
 ref part priorFreeze=GambitMarkerJointPublication::freeze;
 ref part priorRecovery=GambitMarkerJointPublication::recovery;
 ref part priorAccounting=GambitMarkerJointPublication::accounting;
 ref part priorOrder=GambitMarkerJointPublication::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=link; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=link; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=link; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=decision; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=decision; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=decision; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=priorEntry; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=intent; ref part :>> prerequisite=priorPublication; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=link; ref part :>> prerequisite=intent; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=link; ref part :>> prerequisite=stop; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=decision; ref part :>> prerequisite=intent; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=decision; ref part :>> prerequisite=priorAccounting; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=link; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=decision; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=custody; ref part :>> prerequisite=priorRecovery; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=stop; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=priorFreeze; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=priorPublication; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=stop; ref part :>> prerequisite=priorRecovery; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=retirement; ref part :>> prerequisite=custody; }
 part intentRoute : GambitHostRootsRefinement::Route { ref part :>> need=intent;
 attribute :>> sourceAnchors="lib/mem.c:1677-1693;lib/mem.c:276-306,376-384;include/gambit.h.in:9981-10007,10043-10059;lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;lib/c_intf.c:6509-6564;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825,3969-3987,6844-6851";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Immutable LinkIntent publishes exact operation/VM/domain/generation, fresh node not already in the well-formed old chain, old head, body proof, root and allocation tickets before first link effect; journal ACKs follow data and may lag it; helpers never trust partly prepared record or ACK absence alone; intent, root cells, domain and native code backing outlive all original/helper borrowers";
 attribute :>> failureCustodian="Canonical operation/root/domain retains every unknown link/commit/stop duty; helper reconciles only with exact stopped-writer and valid structure; no native replay, guessed unlink/free or scalar refund; all writer lineages close before freeze, metadata reclamation separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part linkRoute : GambitHostRootsRefinement::Route { ref part :>> need=link;
 attribute :>> sourceAnchors="lib/mem.c:1677-1693;lib/mem.c:276-306,376-384;lib/mem.c:3625-3651;include/gambit.h.in:11004-11084;lib/mem.c:4210-4251,6775-6810,7003-7031;lib/mem.c:4387-4427,6256-6296;gsc/_ptree2.scm:2902-3030,3145-3187;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Controlled cohort uses real atomic native head with all readers adapted; under stable exclusive domain authority after prior writer stop, head==old permits reconstruction of node.next from immutable intent then release publication, head==node with next==old confirms success without reinsertion, every other head/shape refuses; next remains immutable after head visibility until exclusive sweep; no mixing atomic head with old raw PSTATE stores";
 attribute :>> failureCustodian="Canonical operation/root/domain retains every unknown link/commit/stop duty; helper reconciles only with exact stopped-writer and valid structure; no native replay, guessed unlink/free or scalar refund; all writer lineages close before freeze, metadata reclamation separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part stopRoute : GambitHostRootsRefinement::Route { ref part :>> need=stop;
 attribute :>> sourceAnchors="lib/os_thread.c:427-439,579-592;lib/setup.c:763-801;lib/os_thread.c:546-575;lib/os_base.c:1052-1077;lib/os_base.h:224;lib/setup.c:870-984;lib/setup.c:4569-4579;lib/mem.c:4432-4451,4928-4964;include/gambit.h.in:9981-10007,10043-10059;lib/setup.c:3276-3420;include/gambit.h.in:13224-13230;lib/setup.c:5894-5898,6204-6211;lib/mem.c:4432-4451";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="StopCertificate names exact operation, writer/thread incarnation, domain lease and every helper lineage; normal cooperative endpoint closes future stores, or exact successful native termination/join plus drained final effects supports native stop; logical Scheme exit, generation increment, timeout, pthread id reuse or failed/ignored join do not; known stop alone does not recover locks, freed storage or invalid structure";
 attribute :>> failureCustodian="Canonical operation/root/domain retains every unknown link/commit/stop duty; helper reconciles only with exact stopped-writer and valid structure; no native replay, guessed unlink/free or scalar refund; all writer lineages close before freeze, metadata reclamation separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part decisionRoute : GambitHostRootsRefinement::Route { ref part :>> need=decision;
 attribute :>> sourceAnchors="include/gambit.h.in:9981-10007,10043-10059;lib/setup.c:3276-3420;lib/mem.c:1608-1674,6302-6475;lib/setup.c:479-488,1182-1200;lib/c_intf.c:6509-6564;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825,3969-3987,6844-6851;lib/mem.c:540-600;lib/os_base.c:335-407,445-507;include/gambit.h.in:13224-13230;lib/setup.c:5894-5898,6204-6211;lib/mem.c:4432-4451";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Commit publishes one pre-backed immutable DecisionEnvelope pointer by atomic compare-exchange after body/list/root installation; envelope holds stable root handles and allocation ticket, not untracked movable SCMOBJ; ticket role reserved/live and result come from same decision; no scalar increment/decrement replay; null before stop is pending observation, nonnull qualifies committed result but not writer drain";
 attribute :>> failureCustodian="Canonical operation/root/domain retains every unknown link/commit/stop duty; helper reconciles only with exact stopped-writer and valid structure; no native replay, guessed unlink/free or scalar refund; all writer lineages close before freeze, metadata reclamation separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part custodyRoute : GambitHostRootsRefinement::Route { ref part :>> need=custody;
 attribute :>> sourceAnchors="lib/mem.c:1677-1693;lib/mem.c:4387-4427,6256-6296;lib/setup.c:870-984;lib/setup.c:4569-4579;lib/mem.c:4432-4451,4928-4964;include/gambit.h.in:9981-10007,10043-10059;lib/setup.c:3276-3420;lib/mem.c:540-600;lib/os_base.c:335-407,445-507;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Unknown head/commit result retains operation, root and domain lease; after known stop helpers reconcile actual atomic head/decision, finish exact existing operation and never allocate/free or jump native frame from query; committed outcome with pending writers still refuses GC freeze; GC coordinator does not block holding a lock needed by target/helper, no join/GC barrier wait cycle";
 attribute :>> failureCustodian="Canonical operation/root/domain retains every unknown link/commit/stop duty; helper reconciles only with exact stopped-writer and valid structure; no native replay, guessed unlink/free or scalar refund; all writer lineages close before freeze, metadata reclamation separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part retirementRoute : GambitHostRootsRefinement::Route { ref part :>> need=retirement;
 attribute :>> sourceAnchors="lib/mem.c:4210-4251,6775-6810,7003-7031;lib/mem.c:4387-4427,6256-6296;lib/os_thread.c:427-439,579-592;lib/setup.c:763-801;lib/setup.c:870-984;lib/setup.c:4569-4579;lib/mem.c:4432-4451,4928-4964;gsc/_ptree2.scm:2902-3030,3145-3187;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;include/gambit.h.in:13224-13230;lib/setup.c:5894-5898,6204-6211;lib/mem.c:4432-4451";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="DataWriteClosed covers original and all helpers before lease withdrawal and GC freeze; raw already-issued stores are not revoked by token change; protected metadata readers may outlive heap-write closure but prevent control/decision reuse; no ABA reuse while old borrowers can issue effect; move operation/domain/root backing to VM service before PSTATE cleanup and preserve committed result custody separately from native activation";
 attribute :>> failureCustodian="Canonical operation/root/domain retains every unknown link/commit/stop duty; helper reconciles only with exact stopped-writer and valid structure; no native replay, guessed unlink/free or scalar refund; all writer lineages close before freeze, metadata reclamation separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/mem.c:1677-1693;lib/mem.c:276-306,376-384;lib/mem.c:3625-3651;include/gambit.h.in:11004-11084;lib/mem.c:4210-4251,6775-6810,7003-7031;lib/mem.c:4387-4427,6256-6296;lib/os_thread.c:427-439,579-592;lib/setup.c:763-801;lib/os_thread.c:546-575;lib/os_base.c:1052-1077;lib/os_base.h:224;lib/setup.c:870-984;lib/setup.c:4569-4579;lib/mem.c:4432-4451,4928-4964;include/gambit.h.in:9981-10007,10043-10059;lib/setup.c:3276-3420;gsc/_ptree2.scm:2902-3030,3145-3187;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;lib/mem.c:1608-1674,6302-6475;lib/setup.c:479-488,1182-1200;lib/c_intf.c:6509-6564;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825,3969-3987,6844-6851;lib/mem.c:540-600;lib/os_base.c:335-407,445-507;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303;include/gambit.h.in:13224-13230;lib/setup.c:5894-5898,6204-6211;lib/mem.c:4432-4451";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Actual C acquire/release and atomic object layout refine immutable-intent visibility, next-before-head publication, observed head classification and one decision CAS; all accesses use compatible types and lifetime protection; compiler/target lock-free support is not assumed, owner-death inside nonrecoverable atomic/lock backend remains unsupported; stop certificates establish no future effects before freeze/reuse";
 attribute :>> failureCustodian="Canonical operation/root/domain retains every unknown link/commit/stop duty; helper reconciles only with exact stopped-writer and valid structure; no native replay, guessed unlink/free or scalar refund; all writer lineages close before freeze, metadata reclamation separate";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="real-link-stores";
 attribute :>> sourceAnchors="lib/mem.c:1677-1693";
 attribute :>> actualChain="Generic still allocator writes next, publishes PSTATE head, then count/length/header; body is caller-filled";
 attribute :>> hazard="There is no durable per-operation intent or ACK; current sequence is not the selected initialized-before-head profile";
 attribute :>> replacement="Controlled allocator prepares body/intent privately, atomic controlled-domain head, adapted setup/sweep readers; raw legacy chain remains separately admitted";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="per-domain-and-locks";
 attribute :>> sourceAnchors="lib/mem.c:276-306,376-384";
 attribute :>> actualChain="still list/queue and RC chain are per-PSTATE; ALLOC_MEM_LOCK protects capacity";
 attribute :>> hazard="A scalar memory lock or processor number is not stable domain/writer ownership";
 attribute :>> replacement="VM-owned domain incarnation and writer lineage; never hold a nonrecoverable lock across interruption assumed recoverable";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="mark-cas-prior-art";
 attribute :>> sourceAnchors="lib/mem.c:3625-3651;include/gambit.h.in:11004-11084";
 attribute :>> actualChain="Existing still marking uses CAS; header selects compiler builtins/emulated/sequential synchronization";
 attribute :>> hazard="Current CAS helper existence proves neither atomic object ABI nor owner-death progress for a new head/decision cell";
 attribute :>> replacement="New native atomic profile explicitly binds all loads/stores, alignment and backend; emulate only with separately qualified stop-safe lock behavior";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="actual-setup-reader";
 attribute :>> sourceAnchors="lib/mem.c:4210-4251,6775-6810,7003-7031";
 attribute :>> actualChain="Setup walks raw still head/next and resets marks; barrier precedes marking";
 attribute :>> hazard="Observer bypasses managed commit/lease cut if only allocator is changed";
 attribute :>> replacement="Controlled-domain iterator acquires frozen complete head after publisher closure; all domains setup before any mark";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="sweep-mutating-reader";
 attribute :>> sourceAnchors="lib/mem.c:4387-4427,6256-6296";
 attribute :>> actualChain="Sweep reads next, relinks live objects and recomputes per-PSTATE counts";
 attribute :>> hazard="Next cannot be rewritten by late helper after sweep starts; source head equality alone lacks ABA protection";
 attribute :>> replacement="No-future-write closure of all lineages before sweep; controlled/legacy/pending accounting reconciled without dual authoritative counters";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="real-thread-start-exit";
 attribute :>> sourceAnchors="lib/os_thread.c:427-439,579-592;lib/setup.c:763-801";
 attribute :>> actualChain="POSIX starter invokes start_fn; ___thread_exit calls pthread_exit; ___run return can continue sync service loop";
 attribute :>> hazard="Logical Scheme/processor task completion is not native thread termination";
 attribute :>> replacement="Distinguish activation-close/cooperative operation endpoint/native termination; certificate identifies exact native incarnation and scope";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="join-result";
 attribute :>> sourceAnchors="lib/os_thread.c:546-575;lib/os_base.c:1052-1077;lib/os_base.h:224";
 attribute :>> actualChain="POSIX join wrapper branches on pthread_join return, converts error through errno helper; helper maps errno0 to UNKNOWN_ERR";
 attribute :>> hazard="Original pthread error value is not retained; success/failure and target identity must remain explicit, not inferred from errno or absence";
 attribute :>> replacement="Store exact raw join return and successful target incarnation in service receipt; no stopped certificate from ignored/failed/unknown join";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="resize-join-caller";
 attribute :>> sourceAnchors="lib/setup.c:870-984";
 attribute :>> actualChain="Shrinking processor cleans PSTATE then exits; P0 joins and ignores result";
 attribute :>> hazard="Recovery after successful join is too late if PSTATE cleanup already freed operation/node/root backing";
 attribute :>> replacement="Transfer VM-owned construction/domain duties before cleanup; consume exact join receipt after known quiescence; failed join retains removal debt";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="physical-teardown";
 attribute :>> sourceAnchors="lib/setup.c:4569-4579;lib/mem.c:4432-4451,4928-4964";
 attribute :>> actualChain="cleanup_os_and_mem_pstate calls memory cleanup; still/RC freed; VM teardown destroys synchronization";
 attribute :>> hazard="Native stopped does not reconstruct freed objects or recover a destroyed domain lock";
 attribute :>> replacement="Service backing/roots/code outlive PSTATE; never issue takeover from join alone after storage destruction";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="nonlocal-exit-bridge";
 attribute :>> sourceAnchors="include/gambit.h.in:9981-10007,10043-10059;lib/setup.c:3276-3420";
 attribute :>> actualChain="setjmp/longjmp TRY machinery and SFUN error loops reuse marker; ___call consumes exact matching return frame";
 attribute :>> hazard="C stack local progress can disappear; logical unwind does not fence every native helper or foreign writer";
 attribute :>> replacement="Off-stack operation/intent/result and explicit guarded no-future-write endpoint; native return rights still belong to original live activation";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="generated-and-raw-access";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2902-3030,3145-3187;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759";
 attribute :>> actualChain="Generator emits native entry wrappers; source and generated kernel read marker slots";
 attribute :>> hazard="Unmigrated raw producer can write after token checks; changing generation does not revoke issued stores";
 attribute :>> replacement="Typed Scheme-generated entry/closure descriptors and complete raw-writer census; regenerate or reject old module profile";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="capacity-write-baseline";
 attribute :>> sourceAnchors="lib/mem.c:1608-1674,6302-6475;lib/setup.c:479-488,1182-1200";
 attribute :>> actualChain="Old allocation changes scalar occupied/deferred words; resize request combines and temporarily assumes live space";
 attribute :>> hazard="Repeating scalar delta after lost commit can charge/refund twice; temporary requested words are not operation outcome";
 attribute :>> replacement="One canonical allocation ticket role derived from decision; summary counters are reconciled views, never second outcome authority";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="rc-root-producer";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6564;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:702-825,3969-3987,6844-6851";
 attribute :>> actualChain="Marker proc copy has GC TODO; dynamic closure uses global self; RC roots per PSTATE, mark_rc only P0 branch";
 attribute :>> hazard="A stopped native writer and correct head do not establish root completeness or original closure identity";
 attribute :>> replacement="Pre-backed actual input root, stable handle in decision, all-domain root view and legacy marker gate imported unchanged";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="allocator-disposition";
 attribute :>> sourceAnchors="lib/mem.c:540-600;lib/os_base.c:335-407,445-507";
 attribute :>> actualChain="Native allocation/free can use malloc or mmap backend; void release hides outcome";
 attribute :>> hazard="Commit reconciliation cannot recover unknown native allocation or infer munmap success";
 attribute :>> replacement="Retain exact pending/quarantine ticket; no allocation/free in reconciliation, backend-specific original evidence still required";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="ffi-real-producers";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> actualChain="Real Tcl command/server/function-valued callbacks instantiate generated native entry and return paths";
 attribute :>> hazard="Nested callback/delete/error can close logical activation while cleanup result persists";
 attribute :>> replacement="Keep activation/root/native-resource duties separate from canonical commit, no foreign continuation compatibility assumed";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="metadata-reuse";
 attribute :>> sourceAnchors="include/gambit.h.in:13224-13230;lib/setup.c:5894-5898,6204-6211;lib/mem.c:4432-4451";
 attribute :>> actualChain="GSTATE exposes raw marker and thread functions; teardown can destroy storage independent of external handles";
 attribute :>> hazard="Plain external pointer or reused thread id cannot validate late query; metadata reclamation is separate from heap collection";
 attribute :>> replacement="Protected lookup/pin and nonreused operation/writer identities; stable decision/root backing until data writers/readers drain";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Link reconciliation";
 attribute :>> removedWork="Avoid duplicate insertion and self-link when head write succeeded but ACK did not";
 attribute :>> bound="3 outcomes: head old -> reconstruct, head node+next old -> confirm, other -> refuse";
 attribute :>> addedCost="Immutable old-head/node intent, exclusive domain and atomic head read";
 attribute :>> condition="Only after exact prior-writer stop/valid structure; no list search guessing or unbounded retry";
 }
 part cost1 : CostRow {
 attribute :>> capability="Journal ordering";
 attribute :>> removedWork="Permit progress ACK to lag real data effect safely";
 attribute :>> bound="2 link data effects: next then head; separate ACKs never lead data";
 attribute :>> addedCost="Pre-backed intent publication and progress cells; extra stores/observations";
 attribute :>> condition="No durability across process crash claimed; volatile release/acquire source refinement remains open";
 }
 part cost2 : CostRow {
 attribute :>> capability="Commit authority";
 attribute :>> removedWork="Remove separately replayed result/credit updates";
 attribute :>> bound="1 winning decision CAS per operation; 0 scalar credit deltas on selected commit path";
 attribute :>> addedCost="One immutable envelope + root handle/ticket and protected query";
 attribute :>> condition="Atomic profile required; attempts/query count is not bounded to1; no allocation during reconciliation";
 }
 part cost3 : CostRow {
 attribute :>> capability="Unknown response";
 attribute :>> removedWork="Query canonical state without repeating side effects";
 attribute :>> bound="0 native allocation/free or native jump from outcome query";
 attribute :>> addedCost="Control/root/decision backing remains alive";
 attribute :>> condition="Null before writer drain is Pending, not proven failure; committed decision alone does not permit GC";
 }
 part cost4 : CostRow {
 attribute :>> capability="Stop certificates";
 attribute :>> removedWork="Separate logical death and token revocation from physical effect drain";
 attribute :>> bound="Must cover every original/helper writer lineage; pending effects0 before permit release";
 attribute :>> addedCost="Cooperative endpoint or exact successful native termination/join, identity and domain checks";
 attribute :>> condition="Timeout, failed/ignored join, generation change and mere thread-id match are insufficient";
 }
 part cost5 : CostRow {
 attribute :>> capability="Nonzero processor shutdown";
 attribute :>> removedWork="Retain recoverable construction outside dying PSTATE";
 attribute :>> bound="1 VM service custody handoff before PSTATE cleanup; no post-free reconstruction";
 attribute :>> addedCost="Resize/cleanup ordering and per-domain root/code lifetime integration";
 attribute :>> condition="Current source cleans before exit and ignores join result; no existing native failure is inferred";
 }
 part cost6 : CostRow {
 attribute :>> capability="Helper recovery";
 attribute :>> removedWork="Roll forward existing operation instead of reallocate/undo linked object";
 attribute :>> bound="At most1 active effect writer per domain; each helper creates another closure obligation";
 attribute :>> addedCost="Bounded lineage/journal slots; helper must close its own writes too";
 attribute :>> condition="Owner stop alone does not cover helper; unknown lock/structure keeps GC blocked";
 }
 part cost7 : CostRow {
 attribute :>> capability="GC freeze";
 attribute :>> removedWork="Allow metadata readers while excluding future heap/list writers";
 attribute :>> bound="0 outstanding data effects at freeze; metadata pins need not be0";
 attribute :>> addedCost="Separate data-close versus metadata-reclamation lifetimes";
 attribute :>> condition="Readers must be control-only; root/object borrowers remain governed by imported view contract";
 }
 part cost8 : CostRow {
 attribute :>> capability="ABI and atomic backend";
 attribute :>> removedWork="Keep next immutable after head publication; atomic head is native side storage";
 attribute :>> bound="Inherited marker body remains2W+24 in selected layout; atomic side-record size unspecified";
 attribute :>> addedCost="All controlled-domain head/setup/sweep accessors and code generation must migrate";
 attribute :>> condition="No mixed atomic/plain access; no universal lock-free, ABI or stalled-owner progress guarantee";
 }
 part cost9 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Reuse one marker backing through original/helper/service custody";
 attribute :>> bound="Inherited SMP marker delta24*M(t); Peak=max_t(H+P+N+Q)";
 attribute :>> addedCost="Add immutable intent/envelope, writer/reader receipts and retained root/code graph";
 attribute :>> condition="Writer/readers may retain records and debt indefinitely; exact sizeof/padding and whole-round peak reduction unproved";
 }
 part cost10 : CostRow {
 attribute :>> capability="Conditional saved work";
 attribute :>> removedWork="Remove guessed push, repeated scalar debit and duplicate allocation";
 attribute :>> bound="0 repeat allocation/free in selected reconciliation; one canonical result/ticket role";
 attribute :>> addedCost="Acquire observations, identity checks, journal/stop service and retained records";
 attribute :>> condition="Positive net only if removed duplication/waits/retention exceed new costs; no wall-clock speedup measured";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C architecture";
 attribute :>> removedWork="Generate one typed publication/decision/root service across GC and FFI";
 attribute :>> bound="0 production paths retired today; 0 Zig-specific necessary-support savings demonstrated";
 attribute :>> addedCost="Same C ABI/root/stop/reclamation obligations for any implementation language";
 attribute :>> condition="Zig adds no native stop proof or automatic GC; source and memory-order gates remain necessary";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="intent"; attribute :>> labelText="Immutable intent before link\\nnode / old head / domain / root tickets"; }
 part node1 : DiagramNode { attribute :>> nodeId="next"; attribute :>> labelText="Private next = old head\\nwrite may precede journal ACK"; }
 part node2 : DiagramNode { attribute :>> nodeId="head"; attribute :>> labelText="Atomic release head = node\\nACK may still be absent"; }
 part node3 : DiagramNode { attribute :>> nodeId="stop"; attribute :>> labelText="Exact writer stop evidence\\nlogical death / token change insufficient"; }
 part node4 : DiagramNode { attribute :>> nodeId="classify"; attribute :>> labelText="Stable exclusive domain\\nold / node+next / unexpected head"; }
 part node5 : DiagramNode { attribute :>> nodeId="recover"; attribute :>> labelText="Reconstruct or confirm once\\nno duplicate push / no native replay"; }
 part node6 : DiagramNode { attribute :>> nodeId="root"; attribute :>> labelText="Installed rooted result handle\\npre-backed immutable DecisionEnvelope"; }
 part node7 : DiagramNode { attribute :>> nodeId="decision"; attribute :>> labelText="One canonical decision CAS\\nresult + ticket role share authority"; }
 part node8 : DiagramNode { attribute :>> nodeId="pending"; attribute :>> labelText="Null before writer drain = Pending\\nnonnull result is not GC permission"; }
 part node9 : DiagramNode { attribute :>> nodeId="drain"; attribute :>> labelText="Close original + every helper\\nretain roots / data-write permit"; }
 part node10 : DiagramNode { attribute :>> nodeId="gc"; attribute :>> labelText="All data effects drained -> GC freeze\\nmetadata-only reader may remain"; }
 part node11 : DiagramNode { attribute :>> nodeId="refuse"; attribute :>> labelText="Unknown stop / lock / structure\\nretain custody; refuse freeze"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nC and platform refinements open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="known payload before effect"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="next before head release"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="interruption / missing ACK"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="certified stop + lifetime"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="old or exact node head"; }
 part edge5 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node11; attribute :>> labelText="unexpected head / layout"; }
 part edge6 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="finish existing operation"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="prepare before publish"; }
 part edge8 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="query without replay"; }
 part edge9 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="committed still needs closure"; }
 part edge10 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node11; attribute :>> labelText="unproven / failed join"; }
 part edge11 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node10; attribute :>> labelText="all lineages + effects"; }
 part edge12 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node11; attribute :>> labelText="late writer still possible"; }
 part edge13 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node3; attribute :>> labelText="intent survives owner loss"; }
 part edge14 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node4; attribute :>> labelText="conditional refinement"; }
 part edge15 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node7; attribute :>> labelText="single outcome authority"; }
 part edge16 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node9; attribute :>> labelText="helper also owes closure"; }
 part edge17 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node11; attribute :>> labelText="unsettled stop retains custody"; }
}
