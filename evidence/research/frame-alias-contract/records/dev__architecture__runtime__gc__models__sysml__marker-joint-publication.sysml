/* Modern C split publication and freeze research. No runtime admission. */
package GambitMarkerJointPublication {
 private import ScalarValues::*;
 part def PublicationState { attribute committed : Boolean; attribute initialized : Boolean; attribute linked : Boolean; attribute rootInstalled : Boolean; attribute capacityLive : Boolean; attribute inputRoot : Boolean; attribute permitHeld : Boolean; }
 requirement def JointPublicationLaw { subject p : PublicationState; require constraint { not p.committed or (p.initialized and p.linked and p.rootInstalled and p.capacityLive) } }
 part def FreezeState { attribute issued : Boolean; attribute admissionsClosed : Boolean; attribute activePublishers : Integer; attribute rootWritersClosed : Boolean; attribute membersStable : Boolean; attribute allSetup : Boolean; attribute marking : Boolean; }
 requirement def FreezeLaw { subject f : FreezeState; require constraint { not f.issued or (f.admissionsClosed and f.activePublishers==0 and f.rootWritersClosed and f.membersStable) } }
 requirement def SetupLaw { subject f : FreezeState; require constraint { not f.marking or (f.issued and f.allSetup) } }
 ref part inheritedLayout32=GambitManagedMarkerLayout::layout32;
 ref part inheritedLayout64=GambitManagedMarkerLayout::layout64;
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/marker_joint_publication.qnt";
 attribute :>> subjectScope="marker_joint_publication:32-named-histories;admitted;two-operations;two-domains;same+split;seed=17;each100x100";
 attribute :>> premise="Two canonical operations and two physical domains, same processor-one owner and split-owner profiles; split body/link/root/commit/release fragments and at most two epochs; external stop certificates, complete input-root relocation and gate atomicity are premises; no C execution or fairness/liveness proof";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="GambitSMP.MarkerJointPublication:grantPreserves;fillPreserves;linkPreserves;installPreserves;commitPreserves;releasePreserves;closePreserves;freezePreserves;stepPreserves;tracePreserves;frozenHasPairedMembership;partialLinkBlocksFreeze;unknownWriterCannotWrite;closingRejectsGrant;commitCreditConserves;unknownCreditConserves;queryNeverRefunds;unknownDebtKeepsRoot;unknownDebtKeepsCharge;publishedInputRejectsWithdrawal;frozenInputRemainsRooted";
 attribute :>> premise="21 conditional declarations: one-transaction publication Step/Trace preservation, paired membership under freeze, unknown-stop guard, closing admission and credit/debt conservation; not full two-operation QNT or C memory refinement";
 }
 part entryRoots : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-ENTRY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="JP-ENTRY:actual-source-refinement";
 attribute :>> premise="Pre-backed entry root slots admit explicit procedure or frozen actual RC closure data/code lease before any capacity check, native allocation or possible GC; root enrollment shares epoch membership admission, rejected enrollment preserves upstream rooted custody; private raw storage contains no untracked SCMOBJ; reload collector-updated input slot only after publication permit; foreign-thread and mutable closure origin require qualified binding";
 }
 part publication : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-PUBLISH";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="JP-PUBLISH:actual-source-refinement";
 attribute :>> premise="One canonical operation holds VM-epoch publisher lease plus exclusive physical-domain link authority; bounded nonallocating fragments fill body, write next/head, install reserved root, commit result and live credit, then withdraw lease; raw refcount0, header/length/mark valid before link; all GC/header/root/diagnostic observers honor the lease/commit boundary; never hold capacity lock across grant or permit while requesting GC";
 }
 part freeze : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-FREEZE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="JP-FREEZE:actual-source-refinement";
 attribute :>> premise="Close new root/publisher enrollment first, retain precise active operation set, drain known publisher/root writers without holding a lock they need, freeze matching root and physical-list membership, retain frozen input-root cells through failed native result/rollback until view drain, setup every domain then mark; same-domain link serialization prevents lost head updates, split domains can publish concurrently; resize/teardown cannot remove an active domain or invalidate permit identity";
 }
 part recovery : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-RECOVER";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="JP-RECOVER:actual-source-refinement";
 attribute :>> premise="Known private pre-permit failure uses matched allocator disposition; unknown malloc/free keeps canonical input root and capacity debt without replay; after any visible list/root fragment the service retains permit and rolls forward only after original writer stop and valid complete journal/layout, never guessed unlink/free; unknown writer stop or partial structure blocks freeze, not converted into isolated native debt; response loss alone queries committed result";
 }
 part accounting : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-ACCOUNT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="JP-ACCOUNT:actual-source-refinement";
 attribute :>> premise="Reserve exact operation/native/root/control credits before permit; transfer reserved to live once at canonical commit and to returned only on known no-allocation/free, quarantine unknown outcome; reconcile per-domain counters and native-only pending storage across sweep/resize without double-counting legacy requested_words_still or refunded temporary estimate; physical mmap/free backend and actual allocation receipt remain profile-specific";
 }
 part integration : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-INTEGRATE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="JP-INTEGRATE:actual-source-refinement";
 attribute :>> premise="Replace make_sfun_stack_marker caller-fill/count1 path only for controlled cohort; SFUN/___run/kernel/GSTATE consumers accept no result before canonical commit and root-backed delivery; processor-one root/list domains remain stable across callback exit, resize and cleanup; metadata query cannot return into dead C activation or free marker; preserve original owner/thread and continuation guard contracts, legacy paths and raw APIs separately admitted";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="JP-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/MarkerJointPublication.lean";
 attribute :>> subjectScope="JP-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Actual C synchronization must refine membership/grant linearization, per-domain link exclusion, fragment writes before release permit, freeze acquire/revalidation and all-setup-before-mark; input root relocation/write permission and metadata reclamation cannot race ordinary field reads; unknown stop cannot be inferred from missing ACK or a scalar count; lock order excludes GC/allocator/owner cycles";
 }
 ref part priorLayout=GambitManagedMarkerLayout::layout;
 ref part priorIdentity=GambitManagedMarkerLayout::identity;
 ref part priorAdmission=GambitManagedMarkerLayout::admission;
 ref part priorScan=GambitManagedMarkerLayout::scanDomain;
 ref part priorLifetime=GambitManagedMarkerLayout::lifetime;
 ref part priorOrder=GambitManagedMarkerLayout::order;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=entryRoots; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=entryRoots; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=entryRoots; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=publication; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=publication; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=publication; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=accounting; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=accounting; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=accounting; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=integration; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=integration; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=integration; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=entryRoots; ref part :>> prerequisite=priorAdmission; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=entryRoots; ref part :>> prerequisite=priorIdentity; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=publication; ref part :>> prerequisite=priorLayout; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=publication; ref part :>> prerequisite=entryRoots; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=publication; ref part :>> prerequisite=accounting; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=publication; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=freeze; ref part :>> prerequisite=priorScan; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=publication; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=priorLifetime; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=accounting; ref part :>> prerequisite=priorAdmission; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=integration; ref part :>> prerequisite=priorIdentity; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=integration; ref part :>> prerequisite=priorLifetime; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=integration; ref part :>> prerequisite=priorScan; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=integration; ref part :>> prerequisite=recovery; }
 part entryRootsRoute : GambitHostRootsRefinement::Route { ref part :>> need=entryRoots;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:540-600,1560-1606;lib/os_base.c:445-475;lib/mem.c:702-825,3969-3987,6844-6851;include/gambit.h.in:10043-10059,13224-13230;gsc/_ptree2.scm:2902-3030,3145-3187;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Pre-backed entry root slots admit explicit procedure or frozen actual RC closure data/code lease before any capacity check, native allocation or possible GC; root enrollment shares epoch membership admission, rejected enrollment preserves upstream rooted custody; private raw storage contains no untracked SCMOBJ; reload collector-updated input slot only after publication permit; foreign-thread and mutable closure origin require qualified binding";
 attribute :>> failureCustodian="Entry/root service retains input and budget through private/unknown native outcome; active publisher retains lease across every fragment; linked failure rolls forward only with certified stop and exact journal; unknown managed writer blocks freeze; committed result remains root-backed independently of response";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part publicationRoute : GambitHostRootsRefinement::Route { ref part :>> need=publication;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1677-1709,1778-1821;lib/mem.c:540-600,1560-1606;lib/os_base.c:445-475;lib/mem.c:376-384,1608-1650;lib/setup.c:1182-1200;lib/mem.c:276-306,4644-4651;lib/mem.c:4210-4251,6775-6810,7003-7031;include/gambit.h.in:10043-10059,13224-13230;gsc/_ptree2.scm:2902-3030,3145-3187;lib/setup.c:3276-3420;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="One canonical operation holds VM-epoch publisher lease plus exclusive physical-domain link authority; bounded nonallocating fragments fill body, write next/head, install reserved root, commit result and live credit, then withdraw lease; raw refcount0, header/length/mark valid before link; all GC/header/root/diagnostic observers honor the lease/commit boundary; never hold capacity lock across grant or permit while requesting GC";
 attribute :>> failureCustodian="Entry/root service retains input and budget through private/unknown native outcome; active publisher retains lease across every fragment; linked failure rolls forward only with certified stop and exact journal; unknown managed writer blocks freeze; committed result remains root-backed independently of response";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part freezeRoute : GambitHostRootsRefinement::Route { ref part :>> need=freeze;
 attribute :>> sourceAnchors="lib/mem.c:376-384,1608-1650;lib/setup.c:1182-1200;lib/mem.c:276-306,4644-4651;lib/setup.c:479-488,542-708,1012-1150,1182-1200;lib/mem.c:4210-4251,6775-6810,7003-7031;lib/mem.c:3625-3651,4020-4180,6844-6865;lib/mem.c:4387-4427,6256-6296,6302-6375,6414-6475;lib/setup.c:763-801;lib/mem.c:4432-4451,4928-4964";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Close new root/publisher enrollment first, retain precise active operation set, drain known publisher/root writers without holding a lock they need, freeze matching root and physical-list membership, retain frozen input-root cells through failed native result/rollback until view drain, setup every domain then mark; same-domain link serialization prevents lost head updates, split domains can publish concurrently; resize/teardown cannot remove an active domain or invalidate permit identity";
 attribute :>> failureCustodian="Entry/root service retains input and budget through private/unknown native outcome; active publisher retains lease across every fragment; linked failure rolls forward only with certified stop and exact journal; unknown managed writer blocks freeze; committed result remains root-backed independently of response";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part recoveryRoute : GambitHostRootsRefinement::Route { ref part :>> need=recovery;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:540-600,1560-1606;lib/os_base.c:445-475;lib/mem.c:1658-1674;lib/os_base.c:335-407,476-507;include/gambit.h.in:10043-10059,13224-13230;gsc/_ptree2.scm:2902-3030,3145-3187;lib/setup.c:3276-3420;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;lib/setup.c:763-801;lib/mem.c:4432-4451,4928-4964;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303;lib/os_base.c:335-407,445-507;include/gambit.h.in:15017-15024";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Known private pre-permit failure uses matched allocator disposition; unknown malloc/free keeps canonical input root and capacity debt without replay; after any visible list/root fragment the service retains permit and rolls forward only after original writer stop and valid complete journal/layout, never guessed unlink/free; unknown writer stop or partial structure blocks freeze, not converted into isolated native debt; response loss alone queries committed result";
 attribute :>> failureCustodian="Entry/root service retains input and budget through private/unknown native outcome; active publisher retains lease across every fragment; linked failure rolls forward only with certified stop and exact journal; unknown managed writer blocks freeze; committed result remains root-backed independently of response";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part accountingRoute : GambitHostRootsRefinement::Route { ref part :>> need=accounting;
 attribute :>> sourceAnchors="lib/mem.c:540-600,1560-1606;lib/os_base.c:445-475;lib/mem.c:376-384,1608-1650;lib/setup.c:1182-1200;lib/mem.c:1658-1674;lib/os_base.c:335-407,476-507;lib/mem.c:4210-4251,6775-6810,7003-7031;lib/mem.c:4387-4427,6256-6296,6302-6375,6414-6475;lib/os_base.c:335-407,445-507;include/gambit.h.in:15017-15024";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Reserve exact operation/native/root/control credits before permit; transfer reserved to live once at canonical commit and to returned only on known no-allocation/free, quarantine unknown outcome; reconcile per-domain counters and native-only pending storage across sweep/resize without double-counting legacy requested_words_still or refunded temporary estimate; physical mmap/free backend and actual allocation receipt remain profile-specific";
 attribute :>> failureCustodian="Entry/root service retains input and budget through private/unknown native outcome; active publisher retains lease across every fragment; linked failure rolls forward only with certified stop and exact journal; unknown managed writer blocks freeze; committed result remains root-backed independently of response";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part integrationRoute : GambitHostRootsRefinement::Route { ref part :>> need=integration;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:276-306,4644-4651;lib/mem.c:702-825,3969-3987,6844-6851;lib/setup.c:479-488,542-708,1012-1150,1182-1200;include/gambit.h.in:10043-10059,13224-13230;gsc/_ptree2.scm:2902-3030,3145-3187;lib/setup.c:3276-3420;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;lib/setup.c:763-801;lib/mem.c:4432-4451,4928-4964;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Replace make_sfun_stack_marker caller-fill/count1 path only for controlled cohort; SFUN/___run/kernel/GSTATE consumers accept no result before canonical commit and root-backed delivery; processor-one root/list domains remain stable across callback exit, resize and cleanup; metadata query cannot return into dead C activation or free marker; preserve original owner/thread and continuation guard contracts, legacy paths and raw APIs separately admitted";
 attribute :>> failureCustodian="Entry/root service retains input and budget through private/unknown native outcome; active publisher retains lease across every fragment; linked failure rolls forward only with certified stop and exact journal; unknown managed writer blocks freeze; committed result remains root-backed independently of response";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/os_dyn.c:744-790,1045-1058;lib/mem.c:1487-1500,1677-1709,1778-1821;lib/mem.c:540-600,1560-1606;lib/os_base.c:445-475;lib/mem.c:376-384,1608-1650;lib/setup.c:1182-1200;lib/mem.c:1658-1674;lib/os_base.c:335-407,476-507;lib/mem.c:276-306,4644-4651;lib/mem.c:702-825,3969-3987,6844-6851;lib/setup.c:479-488,542-708,1012-1150,1182-1200;lib/mem.c:4210-4251,6775-6810,7003-7031;lib/mem.c:3625-3651,4020-4180,6844-6865;lib/mem.c:4387-4427,6256-6296,6302-6375,6414-6475;include/gambit.h.in:10043-10059,13224-13230;gsc/_ptree2.scm:2902-3030,3145-3187;lib/setup.c:3276-3420;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759;lib/setup.c:763-801;lib/mem.c:4432-4451,4928-4964;examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303;lib/os_base.c:335-407,445-507;include/gambit.h.in:15017-15024";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Actual C synchronization must refine membership/grant linearization, per-domain link exclusion, fragment writes before release permit, freeze acquire/revalidation and all-setup-before-mark; input root relocation/write permission and metadata reclamation cannot race ordinary field reads; unknown stop cannot be inferred from missing ACK or a scalar count; lock order excludes GC/allocator/owner cycles";
 attribute :>> failureCustodian="Entry/root service retains input and budget through private/unknown native outcome; active publisher retains lease across every fragment; linked failure rolls forward only with certified stop and exact journal; unknown managed writer blocks freeze; committed result remains root-backed independently of response";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="marker-input-origin";
 attribute :>> sourceAnchors="lib/c_intf.c:6509-6545;lib/os_dyn.c:744-790,1045-1058";
 attribute :>> actualChain="make_sfun_stack_marker allocates vector before explicit proc or global closure data copy; TODO names proc relocation hazard";
 attribute :>> hazard="A raw native local or reread global closure identity is not a frozen input root";
 attribute :>> replacement="Pre-backed entry root and actual closure/code borrow before every allocating operation; rejected enrollment retains upstream custody";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="generic-still-filler";
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1677-1709,1778-1821";
 attribute :>> actualChain="alloc_scmobj_still links then sets initial count1; make_vector fills body afterwards";
 attribute :>> hazard="Caller-fill contract relies on current cooperative safe points; zero-count/independent worker cannot observe intermediate state";
 attribute :>> replacement="Dedicated typed private preparation and lease-covered body/list/root/commit; generic controlled-subtype allocation refused";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="private-native-allocation";
 attribute :>> sourceAnchors="lib/mem.c:540-600,1560-1606;lib/os_base.c:445-475";
 attribute :>> actualChain="Aligned wrapper allocates native storage with backpointer; fast still path allocates then adds deferred words";
 attribute :>> hazard="Native allocation is not root/list publication; storing movable proc too early can leave stale private payload";
 attribute :>> replacement="Raw no-managed-edge shell plus persistent input root; native call outside publication permit";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="capacity-lock-and-gc";
 attribute :>> sourceAnchors="lib/mem.c:376-384,1608-1650;lib/setup.c:1182-1200";
 attribute :>> actualChain="ALLOC_MEM_LOCK protects occupied/deferred accounting; released before ___garbage_collect/on_all_processors";
 attribute :>> hazard="Allocation lock is not a still-list/root lock; holding future permit through GC self-blocks freeze";
 attribute :>> replacement="Reserve before lease; separate capacity lock from epoch/domain authority; drop all publication permits before capacity-triggered GC";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="failure-refund";
 attribute :>> sourceAnchors="lib/mem.c:1658-1674;lib/os_base.c:335-407,476-507";
 attribute :>> actualChain="After slow allocation failure old code subtracts words; free wrapper hides free/munmap result";
 attribute :>> hazard="Null, unknown allocation and unknown release are different; free_mem_code ignores munmap result";
 attribute :>> replacement="Canonical reserved/live/returned/quarantine dispositions; no refund or second free from unknown reply";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="processor-physical-domain";
 attribute :>> sourceAnchors="lib/mem.c:276-306,4644-4651";
 attribute :>> actualChain="still_objs, scan queue, deferred words and RC head are PSTATE fields, independently initialized";
 attribute :>> hazard="P0-only shared registry does not include processor-one lists/roots; processor id reuse invalidates raw ownership";
 attribute :>> replacement="Stable physical-domain identity and grant generation, enumerate every domain; resize pins mapping while permits exist";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="rc-root-entry";
 attribute :>> sourceAnchors="lib/mem.c:702-825,3969-3987,6844-6851";
 attribute :>> actualChain="register_rc links per-PSTATE RC header; mark_rc walks its data, invoked only in processor0 strong branch";
 attribute :>> hazard="Adding another RC cell on processor1 is not a proven root adapter";
 attribute :>> replacement="VM root domain includes construction/procedure slots directly; require qualified RC closure data transfer";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="cooperative-gc-callers";
 attribute :>> sourceAnchors="lib/setup.c:479-488,542-708,1012-1150,1182-1200";
 attribute :>> actualChain="GC sync op combines requested words, raises VM sync interrupt and rendezvous executes GC per processor";
 attribute :>> hazard="Current SMP uses cooperative participation, not arbitrary concurrent still mutations; combined request is not physical credit ownership";
 attribute :>> replacement="Keep original sync behavior for legacy; managed frozen-root/native participation and independent worker contract require source refactoring";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="setup-and-deferred-fold";
 attribute :>> sourceAnchors="lib/mem.c:4210-4251,6775-6810,7003-7031";
 attribute :>> actualChain="Setup resets zero-count marks and folds deferred words; barrier precedes strong mark";
 attribute :>> hazard="Freeze between root/list fragments or setup after cross-domain CAS loses root/work/accounting";
 attribute :>> replacement="Close admission, drain leases, snapshot paired membership and counters, all-domain setup completion before any mark";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="zero-count-mark-task";
 attribute :>> sourceAnchors="lib/mem.c:3625-3651,4020-4180,6844-6865";
 attribute :>> actualChain="mark_array still CAS links object to scanner work; body scanner needs managed subtype case";
 attribute :>> hazard="Raw count0 does not itself root object; failed/unknown task claim cannot drop scan obligation";
 attribute :>> replacement="Frozen canonical root feeds existing CAS with explicit scanner task responsibility and updateable cells";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="sweep-and-recount";
 attribute :>> sourceAnchors="lib/mem.c:4387-4427,6256-6296,6302-6375,6414-6475";
 attribute :>> actualChain="Sweep rebuilds list and words_still; determine_occupied_words sums all PSTATE live words; resize temporarily assumes requested words live";
 attribute :>> hazard="Pending raw native storage is absent from swept list; repeated requested budget can charge twice or be erased by recount";
 attribute :>> replacement="Separate pending native credit ledger from published live words; generation-stable reconciliation at sweep/resize";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="native-entry-producers";
 attribute :>> sourceAnchors="include/gambit.h.in:10043-10059,13224-13230;gsc/_ptree2.scm:2902-3030,3145-3187";
 attribute :>> actualChain="Generated static/dynamic SFUN and GSTATE create/kill function pointers consume marker contract";
 attribute :>> hazard="Old object ABI and caller-fill/count1 assumptions cannot consume new result slot blindly";
 attribute :>> replacement="Scheme emits typed entry/root/activation descriptors; C service returns root-backed canonical result with module capability admission";
 }
 part caller12 : CallerRow {
 attribute :>> callerId="run-return-consumers";
 attribute :>> sourceAnchors="lib/setup.c:3276-3420;lib/_kernel.scm:149-178,1020-1072;lib/_kernel.c:10845,11745-11759";
 attribute :>> actualChain="___run creates/calls/kills marker; ___call matches rooted marker; source and generated kernel read vector fields";
 attribute :>> hazard="Response receipt is not live native return authority; forgotten generated C consumers bypass checks";
 attribute :>> replacement="Preserve original activation/thread/guard, no result exposure before committed custody; regenerate or reject old consumers";
 }
 part caller13 : CallerRow {
 attribute :>> callerId="processor-exit-and-cleanup";
 attribute :>> sourceAnchors="lib/setup.c:763-801;lib/mem.c:4432-4451,4928-4964";
 attribute :>> actualChain="Child ___run exit sends error to P0 then services sync ops; teardown frees still/RC and VM cleanup names P0 with other-processors TODO";
 attribute :>> hazard="Logical processor exit is not native writer stop; extra root/permit does not survive unconditional teardown";
 attribute :>> replacement="Drain or transfer all per-domain operations/root/native credits before domain and lock destruction; unknown stop refuses removal";
 }
 part caller14 : CallerRow {
 attribute :>> callerId="actual-callbacks";
 attribute :>> sourceAnchors="examples/tcltk/tcltk.scm:124-194,221-228,269-276;tests/server.scm:15-35;tests/mem.scm:274-303";
 attribute :>> actualChain="Tcl command, server error callback and function-valued callback instantiate real native entries";
 attribute :>> hazard="Nested callback/error/delete can leave construction result or native resource in flight";
 attribute :>> replacement="Reuse canonical entry/activation/root service with explicit exception custody; no hidden Tcl semantics rewrite";
 }
 part caller15 : CallerRow {
 attribute :>> callerId="allocator-backend-scope";
 attribute :>> sourceAnchors="lib/os_base.c:335-407,445-507;include/gambit.h.in:15017-15024";
 attribute :>> actualChain="SUPPORT_LOWLEVEL_EXEC routes heap alloc/free to code allocator; mmap path adds two size words, release discards munmap status";
 attribute :>> hazard="103/67 aligned-wrapper bytes are not universally OS allocation/RSS or proven successful release";
 attribute :>> replacement="Profile records malloc versus mmap backend and known/unknown disposition; page/usable/RSS costs remain unresolved";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Publication visibility";
 attribute :>> removedWork="Remove half list/root snapshots without double-word atomic pointer commit";
 attribute :>> bound="4 modeled payload/link/root/canonical fragments under 1 operation lease; 0 allocating calls inside permit";
 attribute :>> addedCost="Epoch grant/drain and per-domain authority plus staged journal";
 attribute :>> condition="Logical fragments are not 4 C instructions; every observer must honor same boundary";
 }
 part cost1 : CostRow {
 attribute :>> capability="Nonzero processor coverage";
 attribute :>> removedWork="Reuse still CAS and physical list mechanics for processor1";
 attribute :>> bound="O(D+R) domain/root enumeration plus existing queue/graph work";
 attribute :>> addedCost="Stable domain generations, input roots and independent scanner context";
 attribute :>> condition="D counts every physical domain; no P0-only mark_rc shortcut";
 }
 part cost2 : CostRow {
 attribute :>> capability="Same-domain concurrency";
 attribute :>> removedWork="Prevent overwritten still head/link and preserve both objects";
 attribute :>> bound="At most1 publisher holding link authority per physical domain; different domains may overlap";
 attribute :>> addedCost="Per-domain exclusion and VM active-operation registry";
 attribute :>> condition="No wall-clock bound or contention reduction measured; grant cannot block holding another required lock";
 }
 part cost3 : CostRow {
 attribute :>> capability="GC close window";
 attribute :>> removedWork="Avoid global freeze waiting for unstarted/private constructor work";
 attribute :>> bound="Closing forbids new grants; freeze requires exact active lease set empty";
 attribute :>> addedCost="Roots for private constructors remain scanned; close/drain orchestration";
 attribute :>> condition="Unknown actual writer stop can still block freeze; timeout or missing response never clears lease";
 }
 part cost4 : CostRow {
 attribute :>> capability="Allocation count";
 attribute :>> removedWork="Avoid duplicate allocation on lost committed reply";
 attribute :>> bound="At most1 native allocation invocation per canonical operation; 0 allocation on query";
 attribute :>> addedCost="Operation/result storage, stable id and root-backed delivery";
 attribute :>> condition="No generic recovery of lost malloc pointer; unknown disposition remains charged";
 }
 part cost5 : CostRow {
 attribute :>> capability="Partial publication failure";
 attribute :>> removedWork="Avoid guessed unlink/free and lost initialized responsibility";
 attribute :>> bound="Before permit known private rollback; after list write selected recovery is roll-forward";
 attribute :>> addedCost="Stopped-writer certificate and exact progress/shape journal";
 attribute :>> condition="Unknown stop/header/link result refuses freeze; no universal owner-death recovery";
 }
 part cost6 : CostRow {
 attribute :>> capability="Relocation correctness";
 attribute :>> removedWork="Remove stale procedure copy from GC-before-publish";
 attribute :>> bound="One current input-root reload per body-fill fragment; private raw body not scanned before commit";
 attribute :>> addedCost="Pre-backed entry root through allocation/native wait and publication";
 attribute :>> condition="Root revision model is not full moving-collector proof; every real input origin must be included";
 }
 part cost7 : CostRow {
 attribute :>> capability="Capacity conservation";
 attribute :>> removedWork="Keep one token moving reserved -> live/returned/quarantine";
 attribute :>> bound="0 refund from unknown malloc/free or receipt ACK; no second requested_words_still charge";
 attribute :>> addedCost="Separate pending native ledger and sweep/resize reconciliation";
 attribute :>> condition="Legacy temporary resize estimate is not physical allocation; current byte counters cannot reconstruct unknown outcome";
 }
 part cost8 : CostRow {
 attribute :>> capability="SMP marker footprint";
 attribute :>> removedWork="Keep prior exact typed-marker representation";
 attribute :>> bound="2W+24 body bytes; +24 bytes per marker versus current SMP, including known private markers";
 attribute :>> addedCost="Root/control/journal pools additionally consume storage";
 attribute :>> condition="Inherited native layout authority; no new runtime memory measurement";
 }
 part cost9 : CostRow {
 attribute :>> capability="Backend requested bytes";
 attribute :>> removedWork="Bound known private requests without calling them RSS";
 attribute :>> bound="Aligned wrapper request103 bytes at W8 or67 at W4 in inherited assumptions";
 attribute :>> addedCost="LOWLEVEL_EXEC mmap adds2*sizeof(SIZE_TS), with OS page effects separate";
 attribute :>> condition="Backend/malloc usable size and munmap success unknown; no page count or physical peak claim";
 }
 part cost10 : CostRow {
 attribute :>> capability="Whole-round peak";
 attribute :>> removedWork="Avoid counting service handoff as extra object allocation";
 attribute :>> bound="Peak=max_t(Hpublished+Pprivate+Ncontrol+Qunknown); unique allocation counted once";
 attribute :>> addedCost="Private/quarantined blocks and procedure/code retention may increase peak";
 attribute :>> condition="Closed active-lease count does not bound all unknown native debts; require separate admission budgets";
 }
 part cost11 : CostRow {
 attribute :>> capability="Modern C net value";
 attribute :>> removedWork="Share epoch, root, receipt and capacity support across constructor/GC/FFI";
 attribute :>> bound="0 raw managed refcount decrements; 0 production paths retired today; 0 Zig-specific necessary-support savings proved";
 attribute :>> addedCost="Scheme generator, C service, root/GC/teardown and memory refinement all required";
 attribute :>> condition="Positive net requires avoided duplication/retention/wait/fault cost exceed lease/trace/record costs; no measured speedup";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="entry"; attribute :>> labelText="Pre-backed input root + canonical operation\\nexplicit proc / frozen closure origin"; }
 part node1 : DiagramNode { attribute :>> nodeId="private"; attribute :>> labelText="Reserve capacity -> native allocation\\nraw private storage; no SCMOBJ edge"; }
 part node2 : DiagramNode { attribute :>> nodeId="grant"; attribute :>> labelText="Running epoch + domain authority\\ngrant one publisher lease"; }
 part node3 : DiagramNode { attribute :>> nodeId="body"; attribute :>> labelText="Reload current rooted proc\\nvalid header / body / count0"; }
 part node4 : DiagramNode { attribute :>> nodeId="link"; attribute :>> labelText="Write next + physical still head\\nlease retains responsibility"; }
 part node5 : DiagramNode { attribute :>> nodeId="root"; attribute :>> labelText="Install reserved root entry\\nnot independently snapshot-visible"; }
 part node6 : DiagramNode { attribute :>> nodeId="commit"; attribute :>> labelText="Canonical result + live credit commit\\nrelease lease; root-backed delivery"; }
 part node7 : DiagramNode { attribute :>> nodeId="closing"; attribute :>> labelText="Close new enrollment / grants\\ndrain exact active leases"; }
 part node8 : DiagramNode { attribute :>> nodeId="frozen"; attribute :>> labelText="Paired root / list / credit snapshot\\nall domains setup before marking"; }
 part node9 : DiagramNode { attribute :>> nodeId="failure"; attribute :>> labelText="Known stop + exact journal\\nlinked path rolls forward"; }
 part node10 : DiagramNode { attribute :>> nodeId="debt"; attribute :>> labelText="Unknown native allocation/free\\nretain input root + quarantine credit"; }
 part node11 : DiagramNode { attribute :>> nodeId="scan"; attribute :>> labelText="Existing still CAS + typed scan\\nstrong / weak / sweep / reconcile"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and memory-order gaps open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="root before any safepoint"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="no GC request under permit"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="bounded nonallocating writes"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="initialized before link"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="permit covers half state"; }
 part edge5 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="single canonical outcome"; }
 part edge6 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node7; attribute :>> labelText="preexisting permits finish"; }
 part edge7 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="all writers settled"; }
 part edge8 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node8; attribute :>> labelText="membership paired at cut"; }
 part edge9 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node11; attribute :>> labelText="global setup completion"; }
 part edge10 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node9; attribute :>> labelText="owner fails mid-publication"; }
 part edge11 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node5; attribute :>> labelText="qualified roll-forward"; }
 part edge12 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node10; attribute :>> labelText="native outcome unknown"; }
 part edge13 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node8; attribute :>> labelText="only stopped native-only debt"; }
 part edge14 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node7; attribute :>> labelText="unknown stop blocks freeze"; }
 part edge15 : DiagramEdge { ref :>> producer=node11; ref :>> consumer=node2; attribute :>> labelText="next epoch + reload"; }
 part edge16 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node8; attribute :>> labelText="conditional refinement only"; }
}
