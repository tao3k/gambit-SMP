/* Modern C writer-closure/custody refactoring; no runtime admission. */
package GambitDataWriteClosureCustody {
 private import ScalarValues::*;
 part def CohortState { attribute enrollmentClosed : Boolean; attribute everyWriterClosed : Boolean; attribute pendingEffects : Integer; attribute manifestComplete : Boolean; attribute certified : Boolean; }
 requirement def ClosureLaw { subject c : CohortState; require constraint { not c.certified or (c.enrollmentClosed and c.everyWriterClosed and c.pendingEffects==0 and c.manifestComplete) } }
 part def CleanupState { attribute vmAccepted : Boolean; attribute independentBacking : Boolean; attribute originalClosed : Boolean; attribute sourcePins : Integer; attribute admitted : Boolean; }
 requirement def CleanupLaw { subject c : CleanupState; require constraint { not c.admitted or (c.vmAccepted and c.independentBacking and c.originalClosed and c.sourcePins==0) } }
 ref part inheritedLayout32=GambitManagedMarkerLayout::layout32;
 ref part inheritedLayout64=GambitManagedMarkerLayout::layout64;
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/data_write_closure_custody.qnt";
 attribute :>> subjectScope="data_write_closure_custody:31-named-histories;admitted;original+helper;one-cohort;seed=17;each100x100";
 attribute :>> premise="One cohort and two registered writers; delayed application, enrollment cut, VM custody, PSTATE pins and join outcomes; ordinary/helper-entry profiles; complete manifest, closure endpoint, physical independence and atomic gate transitions are premises; not C source, weak-memory or arbitrary-death progress proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="GambitSMP.DataWriteClosureCustody:enrollmentMustClose;pendingRejectsCertificate;helperMustClose;rawEscapeRejectsCertificate;incompleteManifestRejectsCertificate;enrollmentCloseDoesNotDrain;registeredChildIsDebt;acceptPreserves;sourceDropPreserves;cleanupPreserves;joinPreserves;retirePreserves;pointerCopyInsufficient;pstateBorrowBlocksCleanup;pendingOriginalBlocksCleanup;failedOrUnknownJoinKeepsEnvelope;stepPreserves;joinKnowledgeMonotone;tracePreserves;freezeDoesNotRequireJoin;successfulJoinDoesNotCloseData;lostResponseCannotDecodeCustody";
 attribute :>> premise="22 conditional declarations: closure requirements, registered-child debt, Custody Step/Trace preservation, no-join envelope retention, and independent data-freeze condition; not full QNT or C simulation";
 }
 part census : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-CENSUS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="DW-CENSUS:actual-source-refinement";
 attribute :>> premise="Scheme emits a writer-effect descriptor per SFUN/CFUN variant and raw code site, with module/code identity, operation and transitive callees; managed marker cohort rejects unmanifested arbitrary C/FFI aliases, old generated kernel and escaped callback/native write capabilities; bounded symbol search is evidence of named routes, not an exhaustive whole-program effect analysis; no source-level DataWriteClosed issuer currently exists";
 }
 part endpoint : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-ENDPOINT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="DW-ENDPOINT:actual-source-refinement";
 attribute :>> premise="Original writer endpoint is after argument/result conversion, all conversion-error retry calls and generated release/conversion helpers, marker physical clear, exactly-once refcount handoff, result/root custody and final managed effect, but before a no-managed-reentry postlude; nonmatching ___call rethrow and ___run TRY escape require off-stack exceptional guard; AT_END is selected source text, not a universal finally; propagate_error/THROW and TRY catcher restoration remain effect or PSTATE-pin obligations, not assumed harmless epilogues; each nested activation closes only its own identity; borrowed stack/TLS/PSTATE pins remain separate";
 }
 part enrollment : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-ENROLL";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="DW-ENROLL:actual-source-refinement";
 attribute :>> premise="Every native helper, queued task and callback descendant registers its debt before parent can discharge its effect responsibility; one atomic admission cut orders helper registration against enrollment close; registered but not enqueued/dequeued helpers remain owed until completed or cancellation proves no effect; certify only after all members close and issued effects drain; helper work after certificate requires a newly counted cohort before domain freeze, never reopening an old seal";
 }
 part escrow : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-ESCROW";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="DW-ESCROW:actual-source-refinement";
 attribute :>> premise="VM service prepares canonical operation/root/domain/code/ticket backing before accepting custody with one authoritative decision and stable identity; acceptance survives lost response and query does not replay; backing audit rejects pointers to PSTATE list sentinels, stack roots, current closure TLS or locks still destroyed by source cleanup; transfer ownership without copying whole heap; source duty persists until exact acceptance observed; join failure or unknown never refunds debt or drops VM roots";
 }
 part cleanup : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-CLEANUP";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="DW-CLEANUP:actual-source-refinement";
 attribute :>> premise="Before cleanup_pstate, transfer controlled nodes and RC payload roots to VM-owned canonical domain and scan view, unlink transferred nodes from destructive source walks under excluded scan/sweep access, close original writes and drain source PSTATE pins; native postlude/thread/TLS envelope remains until its own stop and reader proof; cleanup_interrupts and free_still release_foreign can spawn effects, so classify and transfer finalizer/interrupt work before seal or open a separately registered cleanup cohort; procedural interrupt cleanup calls external execute_fn(intr,false) while holding its queue mutex, so reentrant enqueue cannot be drained under that lock; no synchronous owner/GC wait cycle";
 }
 part joinOutcome : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-JOIN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="DW-JOIN:actual-source-refinement";
 attribute :>> premise="Record exact native join return and target incarnation, with at most one join authority; successful native termination can support original stop but cannot certify helper closure, operation outcome, physical backing survival or whole-VM drain; failed/unknown join preserves native envelope and canonical VM custody; separately proven cooperative data closure may allow GC without native join; no blind second join on a reused identifier or destruction of TLS/code/locks still borrowed";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="DW-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/DataWriteClosureCustody.lean";
 attribute :>> subjectScope="DW-ORDER:actual-C-memory-refinement";
 attribute :>> premise="One synchronization domain orders registration, membership-close and seal; producer release closure follows every last effect and coordinator acquire sees all participants; VM acceptance release follows initialized independent backing/root scan registration and cleanup acquires canonical acceptance; source unlink and target scan view commit share exclusion; no plain/atomic access mix, compiler motion or arbitrary native cancellation silently assumed safe";
 }
 ref part priorIntent=GambitMarkerInterruptedPublication::intent;
 ref part priorLink=GambitMarkerInterruptedPublication::link;
 ref part priorStop=GambitMarkerInterruptedPublication::stop;
 ref part priorDecision=GambitMarkerInterruptedPublication::decision;
 ref part priorCustody=GambitMarkerInterruptedPublication::custody;
 ref part priorOrder=GambitMarkerInterruptedPublication::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=endpoint; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=endpoint; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=endpoint; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enrollment; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enrollment; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enrollment; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cleanup; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cleanup; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cleanup; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=joinOutcome; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=joinOutcome; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=joinOutcome; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=priorIntent; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=census; ref part :>> prerequisite=priorLink; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=endpoint; ref part :>> prerequisite=census; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=endpoint; ref part :>> prerequisite=priorStop; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enrollment; ref part :>> prerequisite=endpoint; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=enrollment; ref part :>> prerequisite=priorCustody; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=priorDecision; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=priorCustody; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cleanup; ref part :>> prerequisite=escrow; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cleanup; ref part :>> prerequisite=endpoint; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cleanup; ref part :>> prerequisite=enrollment; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=joinOutcome; ref part :>> prerequisite=cleanup; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=joinOutcome; ref part :>> prerequisite=priorStop; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=joinOutcome; ref part :>> prerequisite=escrow; }
 part censusRoute : GambitHostRootsRefinement::Route { ref part :>> need=census;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2590-2670,2840-3030,3145-3235;include/gambit.h.in:10010-10026,10043-10059;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;lib/os_dyn.c:744-790,1045-1058;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6204-6211;lib/os_thread.c:712-750";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Scheme emits a writer-effect descriptor per SFUN/CFUN variant and raw code site, with module/code identity, operation and transitive callees; managed marker cohort rejects unmanifested arbitrary C/FFI aliases, old generated kernel and escaped callback/native write capabilities; bounded symbol search is evidence of named routes, not an exhaustive whole-program effect analysis; no source-level DataWriteClosed issuer currently exists";
 attribute :>> failureCustodian="Before observed VM acceptance source retains duty; canonical accepted service retains roots/domain/code/tickets after response loss, failed or unknown join; native envelope remains until exact stop and reader drain; unknown data effects refuse dependent freeze; no replay/refund from timeout";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part endpointRoute : GambitHostRootsRefinement::Route { ref part :>> need=endpoint;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2590-2670,2840-3030,3145-3235;include/gambit.h.in:10010-10026,10043-10059;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;lib/c_intf.c:6509-6545;lib/mem.c:1778-1821;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484;lib/setup.c:839-865,3276-3420;include/gambit.h.in:9981-10007";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Original writer endpoint is after argument/result conversion, all conversion-error retry calls and generated release/conversion helpers, marker physical clear, exactly-once refcount handoff, result/root custody and final managed effect, but before a no-managed-reentry postlude; nonmatching ___call rethrow and ___run TRY escape require off-stack exceptional guard; AT_END is selected source text, not a universal finally; propagate_error/THROW and TRY catcher restoration remain effect or PSTATE-pin obligations, not assumed harmless epilogues; each nested activation closes only its own identity; borrowed stack/TLS/PSTATE pins remain separate";
 attribute :>> failureCustodian="Before observed VM acceptance source retains duty; canonical accepted service retains roots/domain/code/tickets after response loss, failed or unknown join; native envelope remains until exact stop and reader drain; unknown data effects refuse dependent freeze; no replay/refund from timeout";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part enrollmentRoute : GambitHostRootsRefinement::Route { ref part :>> need=enrollment;
 attribute :>> sourceAnchors="lib/setup.c:143-166,365-419,4665-4672;include/gambit.h.in:13469-13477,14946-14954;lib/os_dyn.c:744-790,1045-1058;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6204-6211;lib/os_thread.c:712-750";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Every native helper, queued task and callback descendant registers its debt before parent can discharge its effect responsibility; one atomic admission cut orders helper registration against enrollment close; registered but not enqueued/dequeued helpers remain owed until completed or cancellation proves no effect; certify only after all members close and issued effects drain; helper work after certificate requires a newly counted cohort before domain freeze, never reopening an old seal";
 attribute :>> failureCustodian="Before observed VM acceptance source retains duty; canonical accepted service retains roots/domain/code/tickets after response loss, failed or unknown join; native envelope remains until exact stop and reader drain; unknown data effects refuse dependent freeze; no replay/refund from timeout";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part escrowRoute : GambitHostRootsRefinement::Route { ref part :>> need=escrow;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1677-1693,1715-1739;lib/mem.c:684-825,3969-3987,6844-6851;lib/os_dyn.c:744-790;lib/setup.c:924-980;lib/setup.c:4569-4599,4665-4672,4834-4875,5975-5979;include/gambit.h.in:13328,14804;lib/os_setup.c:3146-3152;lib/os_io.c:11808-11833;lib/mem.c:4928-4964";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="VM service prepares canonical operation/root/domain/code/ticket backing before accepting custody with one authoritative decision and stable identity; acceptance survives lost response and query does not replay; backing audit rejects pointers to PSTATE list sentinels, stack roots, current closure TLS or locks still destroyed by source cleanup; transfer ownership without copying whole heap; source duty persists until exact acceptance observed; join failure or unknown never refunds debt or drops VM roots";
 attribute :>> failureCustodian="Before observed VM acceptance source retains duty; canonical accepted service retains roots/domain/code/tickets after response loss, failed or unknown join; native envelope remains until exact stop and reader drain; unknown data effects refuse dependent freeze; no replay/refund from timeout";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part cleanupRoute : GambitHostRootsRefinement::Route { ref part :>> need=cleanup;
 attribute :>> sourceAnchors="lib/mem.c:684-825,3969-3987,6844-6851;lib/os_dyn.c:744-790;lib/mem.c:4210-4251,4387-4451;lib/c_intf.c:1683-1715;lib/setup.c:143-166,365-419,4665-4672;include/gambit.h.in:13469-13477,14946-14954;lib/setup.c:924-980;lib/setup.c:4569-4599,4665-4672,4834-4875,5975-5979;include/gambit.h.in:13328,14804;lib/os_setup.c:3146-3152;lib/os_io.c:11808-11833;lib/mem.c:4928-4964";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Before cleanup_pstate, transfer controlled nodes and RC payload roots to VM-owned canonical domain and scan view, unlink transferred nodes from destructive source walks under excluded scan/sweep access, close original writes and drain source PSTATE pins; native postlude/thread/TLS envelope remains until its own stop and reader proof; cleanup_interrupts and free_still release_foreign can spawn effects, so classify and transfer finalizer/interrupt work before seal or open a separately registered cleanup cohort; procedural interrupt cleanup calls external execute_fn(intr,false) while holding its queue mutex, so reentrant enqueue cannot be drained under that lock; no synchronous owner/GC wait cycle";
 attribute :>> failureCustodian="Before observed VM acceptance source retains duty; canonical accepted service retains roots/domain/code/tickets after response loss, failed or unknown join; native envelope remains until exact stop and reader drain; unknown data effects refuse dependent freeze; no replay/refund from timeout";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part joinOutcomeRoute : GambitHostRootsRefinement::Route { ref part :>> need=joinOutcome;
 attribute :>> sourceAnchors="lib/setup.c:924-980;lib/setup.c:4569-4599,4665-4672,4834-4875,5975-5979;include/gambit.h.in:13328,14804;lib/os_thread.c:427-439,546-592,697-710;lib/os_base.c:1052-1077;lib/os_setup.c:3146-3152;lib/os_io.c:11808-11833;lib/mem.c:4928-4964;include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6204-6211;lib/os_thread.c:712-750";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Record exact native join return and target incarnation, with at most one join authority; successful native termination can support original stop but cannot certify helper closure, operation outcome, physical backing survival or whole-VM drain; failed/unknown join preserves native envelope and canonical VM custody; separately proven cooperative data closure may allow GC without native join; no blind second join on a reused identifier or destruction of TLS/code/locks still borrowed";
 attribute :>> failureCustodian="Before observed VM acceptance source retains duty; canonical accepted service retains roots/domain/code/tickets after response loss, failed or unknown join; native envelope remains until exact stop and reader drain; unknown data effects refuse dependent freeze; no replay/refund from timeout";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2590-2670,2840-3030,3145-3235;include/gambit.h.in:10010-10026,10043-10059;gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392;lib/c_intf.c:6509-6545;lib/mem.c:1778-1821;lib/c_intf.c:6551-6564;lib/mem.c:1441-1484;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;lib/setup.c:839-865,3276-3420;include/gambit.h.in:9981-10007;lib/mem.c:1487-1500,1677-1693,1715-1739;lib/mem.c:684-825,3969-3987,6844-6851;lib/os_dyn.c:744-790;lib/mem.c:4210-4251,4387-4451;lib/c_intf.c:1683-1715;lib/setup.c:143-166,365-419,4665-4672;include/gambit.h.in:13469-13477,14946-14954;lib/setup.c:924-980;lib/setup.c:4569-4599,4665-4672,4834-4875,5975-5979;include/gambit.h.in:13328,14804;lib/os_thread.c:427-439,546-592,697-710;lib/os_base.c:1052-1077;lib/os_setup.c:3146-3152;lib/os_io.c:11808-11833;lib/mem.c:4928-4964;lib/os_dyn.c:744-790,1045-1058;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6204-6211;lib/os_thread.c:712-750";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="One synchronization domain orders registration, membership-close and seal; producer release closure follows every last effect and coordinator acquire sees all participants; VM acceptance release follows initialized independent backing/root scan registration and cleanup acquires canonical acceptance; source unlink and target scan view commit share exclusion; no plain/atomic access mix, compiler motion or arbitrary native cancellation silently assumed safe";
 attribute :>> failureCustodian="Before observed VM acceptance source retains duty; canonical accepted service retains roots/domain/code/tickets after response loss, failed or unknown join; native envelope remains until exact stop and reader drain; unknown data effects refuse dependent freeze; no replay/refund from timeout";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="generator-all-three-sfun";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2590-2670,2840-3030,3145-3235;include/gambit.h.in:10010-10026,10043-10059";
 attribute :>> actualChain="c-define and function converters emit void, SCMOBJ and typed SFUN variants; argument/result conversions and generated release wrappers surround calls; errors may retry";
 attribute :>> hazard="End of successful Scheme call is before result conversion, error retry, marker clear and propagation";
 attribute :>> replacement="Generate effect/exit descriptors and explicit off-stack close guard for every variant; close after last managed effect, not after SFUN_CALL";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="generator-cfun-and-raw";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:3239-3329;include/gambit.h.in:10325-10392";
 attribute :>> actualChain="c-lambda emits inline/out-of-line context, optional cleanup TRY, user text or function, AT_END and result publication";
 attribute :>> hazard="Arbitrary C text can return/longjmp/spawn or retain aliases; AT_END does not wrap every escape";
 attribute :>> replacement="Managed raw C effect declaration plus admitted endpoint protocol, otherwise reject controlled cohort; preserve user Scheme semantics separately";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="marker-construction";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/mem.c:1778-1821";
 attribute :>> actualChain="make_vector allocates/fills before marker procedure/processor body writes; proc root TODO";
 attribute :>> hazard="Publishing seal at allocation return omits later body writes; local proc may lack root across allocation";
 attribute :>> replacement="Root proc before allocating; typed safe marker shell/initialization transaction and issuer after body/result publication";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="marker-retirement";
 attribute :>> sourceAnchors="lib/c_intf.c:6551-6564;lib/mem.c:1441-1484";
 attribute :>> actualChain="kill clears vector0 then decrements raw still refcount";
 attribute :>> hazard="Seal before kill misses both writes; repeated cleanup may decrement twice";
 attribute :>> replacement="Move physical marker retirement into canonical guarded effect; exactly-once decision not a second scalar authority";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="scheme-and-generated-readers";
 attribute :>> sourceAnchors="lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759";
 attribute :>> actualChain="Conversion handler and return-to-C inspect marker procedure/processor; generated C retains raw access";
 attribute :>> hazard="Scheme-only generator change leaves old generated readers and raw vector alias interpretation";
 attribute :>> replacement="Regenerate admitted modules; typed marker operations and fixed subtype/profile manifest; legacy module gated out of controlled cohort";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="call-and-run-exits";
 attribute :>> sourceAnchors="lib/setup.c:839-865,3276-3420;include/gambit.h.in:9981-10007";
 attribute :>> actualChain="___call matching return restores frame; nonmatching throws; ___run TRY can escape before normal kill";
 attribute :>> hazard="Normal END and C local guard do not cover every nonlocal exit or nested activation";
 attribute :>> replacement="Off-stack guard owns original identity/root/initialization duty; nested guard closes itself; preserve Scheme continuation return rights";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="still-link-and-body";
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1677-1693,1715-1739";
 attribute :>> actualChain="Allocator links next/head before count/length/header and caller-filled body; release decrements";
 attribute :>> hazard="Generic allocation end cannot certify caller initialization or helper/link stores";
 attribute :>> replacement="VM controlled domain preserves intent, shape and writer lineage; per-operation construction close distinct from whole domain scan close";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="rc-register-and-payload";
 attribute :>> sourceAnchors="lib/mem.c:684-825,3969-3987,6844-6851;lib/os_dyn.c:744-790";
 attribute :>> actualChain="RC sentinel per PSTATE, register links four fields, set_data writes payload, release unlinks/frees; closure producer fills root";
 attribute :>> hazard="Copying sentinel pointer to VM leaves PSTATE dependency; P0-only mark_rc branch does not scan transferred nonzero roots";
 attribute :>> replacement="Canonical VM root domain with physical relink and all-domain scan admission; RC and still accounting remain distinct";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="setup-sweep-and-finalizers";
 attribute :>> sourceAnchors="lib/mem.c:4210-4251,4387-4451;lib/c_intf.c:1683-1715";
 attribute :>> actualChain="Setup marks; sweep rewrites links/counters, free_still clears head and invokes foreign release functions";
 attribute :>> hazard="Cleanup itself writes and may call foreign producer after an earlier data seal";
 attribute :>> replacement="Phase-authorized cleanup cohort and finalizer effect profile; transfer task/root/native resource before original domain seal";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="interrupt-cleanup-producer";
 attribute :>> sourceAnchors="lib/setup.c:143-166,365-419,4665-4672;include/gambit.h.in:13469-13477,14946-14954";
 attribute :>> actualChain="Procedural interrupt enqueue takes target mutex; cleanup invokes execute_fn(intr,false) under that mutex, then clears head/tail before mem cleanup";
 attribute :>> hazard="An unclosed enqueue producer can race cleanup; cleanup interrupt release is outside SFUN generator coverage";
 attribute :>> replacement="Close external interrupt admission; transfer callback debt under queue lock then invoke admitted callback outside locks or reject reentrant handler; pin target incarnation";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="resize-shrink-and-rollback";
 attribute :>> sourceAnchors="lib/setup.c:924-980";
 attribute :>> actualChain="Shrink child cleanup then thread_exit; P0 join ignores return; grow setup failure cleans attempted states";
 attribute :>> hazard="Join happens after destructive cleanup; rollback is a separate cleanup caller, not evidence of initialized cohort";
 attribute :>> replacement="VM acceptance + detach/closure preflight common to shrink and partially initialized rollback; source bug speculation is outside this study";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="shutdown-and-exported-cleanup";
 attribute :>> sourceAnchors="lib/setup.c:4569-4599,4665-4672,4834-4875,5975-5979;include/gambit.h.in:13328,14804";
 attribute :>> actualChain="cleanup disables global interrupts, shrinks and calls cleanup_pstate; cleanup exported through GSTATE";
 attribute :>> hazard="Patching resize alone leaves direct shutdown/exported cleanup capable of destroying backing";
 attribute :>> replacement="Single cleanup admission service for every call route; distinguish no-publication rollback from live-cohort handoff";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="thread-identity-and-join";
 attribute :>> sourceAnchors="lib/os_thread.c:427-439,546-592,697-710;lib/os_base.c:1052-1077";
 attribute :>> actualChain="Starter invokes start_fn; join converts nonzero pthread return via errno; thread_set_pstate sets TLS/affinity";
 attribute :>> hazard="Failed/unknown join is no stop proof; data closure alone does not authorize reclaim of TLS/native envelope";
 attribute :>> replacement="Preserve raw return/incarnation/single join owner; retain envelope until known termination and native readers drain";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="os-and-vm-teardown";
 attribute :>> sourceAnchors="lib/os_setup.c:3146-3152;lib/os_io.c:11808-11833;lib/mem.c:4928-4964";
 attribute :>> actualChain="PSTATE OS cleanup closes select-abort handle; VM cleanup destroys memory/scan locks then P0 memory cleanup";
 attribute :>> hazard="VM-owned pointer can still depend on OS handle, scan lock or root storage being destroyed";
 attribute :>> replacement="Audit physical dependency graph and GC view before receipt; VM shutdown must drain service before its shared infrastructure";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="dynamic-closure-and-native-callback";
 attribute :>> sourceAnchors="lib/os_dyn.c:744-790,1045-1058;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35";
 attribute :>> actualChain="Function-valued callbacks use RC payload and current closure self; native libraries own callback/delete timing";
 attribute :>> hazard="Helper/callback capability can outlive parent; global closure self/TLS TODO and raw aliases defeat local closure proof";
 attribute :>> replacement="Register before native publication; foreign unregister/drain receipt, explicit closure identity/root/code lease; reject unbounded raw origins";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="helper-and-public-api-frontier";
 attribute :>> sourceAnchors="include/gambit.h.in:13224-13230,14564-14575;lib/setup.c:5894-5898,6204-6211;lib/os_thread.c:712-750";
 attribute :>> actualChain="GSTATE exposes marker/thread functions; emulated CAS takes hashed mutex; selected recovery helper is proposed, absent current source";
 attribute :>> hazard="Unregistered helper or abandoned backend lock invalidates closure; symbol search cannot prove all loaded C aliases";
 attribute :>> replacement="Typed helper admission before enqueue/effect; complete module/effect manifest; unknown holder keeps duty and blocks dependent GC domain";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Writer closure issuance";
 attribute :>> removedWork="Replace ambiguous call-end or logical-death checks with one generation-scoped proof";
 attribute :>> bound="0 current source issuers; selected certificate iff enrollment shut + all E members closed + issued effects0";
 attribute :>> addedCost="Per-writer descriptor, effect debt and release/acquire closure";
 attribute :>> condition="All aliases/helpers/exception endpoints manifested; escaped raw C falsifies qualification";
 }
 part cost1 : CostRow {
 attribute :>> capability="Helper enrollment";
 attribute :>> removedWork="Eliminate lost registered-but-not-enqueued work";
 attribute :>> bound="Register before parent release; close gate and register have one ordered winner";
 attribute :>> addedCost="One membership slot per admitted writer/task; cancel needs no-effect proof";
 attribute :>> condition="O(E) closure accounting; no finite E or latency bound from present source";
 }
 part cost2 : CostRow {
 attribute :>> capability="Generated endpoints";
 attribute :>> removedWork="Share three SFUN return variants and CFUN guarded exits through Scheme descriptor";
 attribute :>> bound="3 SFUN families; cleanup after marker clear/refcount plus result custody";
 attribute :>> addedCost="Generator/schema/exception edges must migrate; no universal AT_END finally";
 attribute :>> condition="Continuation/dynamic-wind/native stack semantics remain Gambit responsibilities";
 }
 part cost3 : CostRow {
 attribute :>> capability="VM custody acceptance";
 attribute :>> removedWork="Avoid reconstructing state from freed source PSTATE";
 attribute :>> bound="1 canonical acceptance outcome; 0 native replay or scalar refund on query";
 attribute :>> addedCost="Prepare root/domain/code/ticket view and independent-backing audit";
 attribute :>> condition="Lost response retains source duty until canonical observation; pointer copy alone invalid";
 }
 part cost4 : CostRow {
 attribute :>> capability="Cleanup independence";
 attribute :>> removedWork="Permit helper completion after original PSTATE data cleanup";
 attribute :>> bound="0 residual source-PSTATE borrowers at cleanup; every transferred node excluded from destructive old walk";
 attribute :>> addedCost="Relink/scan exclusion and root-registration receipt; native envelope lifetime separate";
 attribute :>> condition="Closed original and VM-independent helper needed; source sentinel or TLS edge blocks cleanup";
 }
 part cost5 : CostRow {
 attribute :>> capability="Join outcomes";
 attribute :>> removedWork="Avoid turning an ignored/failed join into reclaim authority";
 attribute :>> bound="Success/failure/unknown retained distinctly; 1 join authority per target incarnation";
 attribute :>> addedCost="Exact return receipt + retained thread/TLS/code envelope";
 attribute :>> condition="Failed join does not necessarily block data GC if cooperative closure proved; never proves native termination";
 }
 part cost6 : CostRow {
 attribute :>> capability="Cleanup-generated effects";
 attribute :>> removedWork="Avoid foreign destructor or interrupt enqueue reopening a sealed cohort";
 attribute :>> bound="0 unregistered post-seal data effects; separate counted cleanup cohort if needed";
 attribute :>> addedCost="Finalizer effect/owner classification, queue backing and shutdown drain";
 attribute :>> condition="Unclassified release_fn or raw interrupt target retains quarantine and blocks dependent domain";
 }
 part cost7 : CostRow {
 attribute :>> capability="GC integration";
 attribute :>> removedWork="Separate data freeze from native thread/metadata reclamation";
 attribute :>> bound="All contributing cohort seals before domain freeze; joinKnown not required by data seal alone";
 attribute :>> addedCost="VM all-domain root view + compatible setup/sweep iterator";
 attribute :>> condition="Unknown data effect or lost scan/root authority blocks GC; no arbitrary-death liveness claim";
 }
 part cost8 : CostRow {
 attribute :>> capability="Logical saved work";
 attribute :>> removedWork="Remove repeated allocation/clear/refund after lost handoff ACK";
 attribute :>> bound="0 selected query replay; 0 guessed cleanup/release of unaccepted object";
 attribute :>> addedCost="Stable canonical lookup/pin and two custody duties during uncertain response";
 attribute :>> condition="Positive net requires removed duplicate effects or stalls exceed registration/retention overhead";
 }
 part cost9 : CostRow {
 attribute :>> capability="Peak memory";
 attribute :>> removedWork="Transfer existing backing rather than duplicate heap payload";
 attribute :>> bound="Inherited marker +24*M(t); metadata O(E+O+D); Peak=max_t(H+P+N+Q), unique backing once";
 attribute :>> addedCost="Writer slots, custody receipts, root/code graph, unresolved native envelope retention";
 attribute :>> condition="No fixed bytes for atomic structs; unknown joins/readers can make Q unbounded; no peak decrease proved";
 }
 part cost10 : CostRow {
 attribute :>> capability="Retirement sequence";
 attribute :>> removedWork="Retire raw managed-cohort kill/list/root and ad hoc cleanup admission paths";
 attribute :>> bound="0 production paths retired today; legacy uncontrolled C remains separately gated";
 attribute :>> addedCost="One generated endpoint/schema and VM service replaces duplicated managed logic";
 attribute :>> condition="Only after writer manifest, source simulation, scan/sweep exclusion and native-order evidence close";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C versus Zig";
 attribute :>> removedWork="Keep Gambit Scheme semantics and portable C while making contracts explicit";
 attribute :>> bound="0 Zig-specific necessary-support saving shown; same root/custody/stop obligations";
 attribute :>> addedCost="Modern C needs typed generated ABI/atomics/service; Zig also needs all external capability qualification";
 attribute :>> condition="Language choice cannot create endpoint completeness or successful join; measured net benefit still open";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="manifest"; attribute :>> labelText="Scheme / raw / helper effect manifest"; }
 part node1 : DiagramNode { attribute :>> nodeId="register"; attribute :>> labelText="Register original + helper debt\\nbefore native publication"; }
 part node2 : DiagramNode { attribute :>> nodeId="cut"; attribute :>> labelText="Close enrollment atomically\\nqueued debt remains counted"; }
 part node3 : DiagramNode { attribute :>> nodeId="endpoint"; attribute :>> labelText="Last managed write / cleanup\\nexception guard per activation"; }
 part node4 : DiagramNode { attribute :>> nodeId="seal"; attribute :>> labelText="DataWriteClosed\\nall E writers + issued effects drained"; }
 part node5 : DiagramNode { attribute :>> nodeId="prepare"; attribute :>> labelText="Prepare independent VM roots\\nnode / domain / code / ticket"; }
 part node6 : DiagramNode { attribute :>> nodeId="accept"; attribute :>> labelText="Canonical VM custody accepted\\nlost ACK -> query, no replay"; }
 part node7 : DiagramNode { attribute :>> nodeId="detach"; attribute :>> labelText="Detach source physical chains\\nzero source PSTATE pins"; }
 part node8 : DiagramNode { attribute :>> nodeId="cleanup"; attribute :>> labelText="Admitted PSTATE data cleanup\\nhelper may continue on VM backing"; }
 part node9 : DiagramNode { attribute :>> nodeId="joinOutcome"; attribute :>> labelText="Exact join receipt\\nsuccess / failed / unknown"; }
 part node10 : DiagramNode { attribute :>> nodeId="freeze"; attribute :>> labelText="Domain GC freeze\\nall cohorts closed; native envelope separate"; }
 part node11 : DiagramNode { attribute :>> nodeId="retain"; attribute :>> labelText="Retain roots / domain / native envelope\\nunknown effect refuses dependent GC"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C refinement open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="admitted effect capabilities"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="one ordered admission cut"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="drain registered tasks"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="release after last possible effect"; }
 part edge4 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node5; attribute :>> labelText="custody may start before closure"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="release independent view"; }
 part edge6 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="canonical acceptance observed"; }
 part edge7 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node7; attribute :>> labelText="original close + source pins0"; }
 part edge8 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="exclude transferred nodes"; }
 part edge9 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="thread resources remain held"; }
 part edge10 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node10; attribute :>> labelText="all domain cohorts sealed"; }
 part edge11 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node10; attribute :>> labelText="registered VM roots required"; }
 part edge12 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node11; attribute :>> labelText="failed or unknown retains native backing"; }
 part edge13 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node11; attribute :>> labelText="unknown helper / raw origin"; }
 part edge14 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node11; attribute :>> labelText="dangling physical dependency"; }
 part edge15 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node0; attribute :>> labelText="bounded census not completeness"; }
 part edge16 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node4; attribute :>> labelText="conditional obligations"; }
 part edge17 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node6; attribute :>> labelText="custody preservation"; }
}
