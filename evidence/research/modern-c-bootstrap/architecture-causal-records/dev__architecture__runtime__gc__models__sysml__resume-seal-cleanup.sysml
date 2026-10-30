/* Modern C design; no source or native admission asserted. */
package GambitResumeSealCleanup {
 private import ScalarValues::*;
 part def SealState { attribute issued : Boolean; attribute rootsClosed : Boolean; attribute rootsCovered : Boolean; attribute weakClosed : Boolean; attribute cleanupSettled : Boolean; attribute capacityKnown : Boolean; attribute contextPrepared : Boolean; attribute resultKnown : Boolean; attribute writerClosed : Boolean; attribute bindingKnown : Boolean; attribute gatesReleased : Boolean; }
 requirement def WholeRoundSealLaw { subject s : SealState; require constraint { not s.issued or (s.rootsClosed and s.rootsCovered and s.weakClosed and s.cleanupSettled and s.capacityKnown and s.contextPrepared and s.resultKnown and s.writerClosed and s.bindingKnown and s.gatesReleased) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/resume_seal_cleanup.qnt";
 attribute :>> subjectScope="resume_seal_cleanup:31-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One selected foreign wrapper, one task/owner and one round; qualified semantic delay, isolation, roots, physical effects and safe error recovery are premises; no full-GC or real callback/fairness model";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="GambitSMP.ResumeSealCleanup:missingCleanupRejects;missingRootsRejects;unknownCapacityRejects;unpreparedContextRejects;missingResultRejects;unknownWriterRejects;unknownBindingRejects;heldGateRejects;isolatedNativeOutcomeIndependent;queueOnlyInsufficient;unknownTransferRejects;noDelayPermissionRejects;acceptConserves;completionConserves;unknownRetainsCredit;stepConserves;traceConserves;unknownReleaseBlocksFree;errorCodeNotFreeAuthority;alreadyFreedRejectsRepeat;waitingOwnerCannotCallback;deferredCleanupBreaksThisCycle;staleSealRejected;acknowledgementNotZeroBacking;noReplayFromOutcomeLoss";
 attribute :>> premise="25 conditional declarations: complete seal gates, source/service credit Step/Trace, isolated outcome independence, disposition distinct from error, callback cycle and stale seal rejection; no all-action QNT/C simulation";
 }
 part sealLaw : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-SEAL";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="RS-SEAL:actual-source-refinement";
 attribute :>> premise="Every admitted strong/weak/private/cleanup duty closes or has qualified deferred handoff; capacity success or safe-error outcome, context preparation, result delivery, binding, writer closure and current generation precede active permit; domain-wide finalizer inventory required";
 }
 part handoff : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-HANDOFF";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="RS-HANDOFF:actual-source-refinement";
 attribute :>> premise="Reserve before destructive wrapper retirement; canonical task owns payload/dependencies/credits and accepted decision before source drops custody; queue notification or transport loss is not acceptance/completion";
 }
 part rootCustody : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-ROOTS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="RS-ROOTS:actual-source-refinement";
 attribute :>> premise="Foreign payload is opaque to scan; deferred managed dependencies must already be traced and rooted or trigger pre-seal rescan; native/RC/code/library storage survives actual cleanup_rc and old-reader drain";
 }
 part dispatch : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-DISPATCH";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="RS-DISPATCH:actual-source-refinement";
 attribute :>> premise="Only qualified native-only execution may overlap GC; owner/managed callback waits until active permit and rooted activation, while cleanup never waits for that callback; explicit WaitContext replaces PSTATE scratch";
 }
 part origins : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-ORIGINS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="RS-ORIGINS:actual-source-refinement";
 attribute :>> premise="GC, explicit foreign-release!, constructor rollback and teardown have different invocation/error/timing contracts; at-most-once invocation preserved and delay permission is explicit, not inferred from unreachable wrapper";
 }
 part recovery : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-RECOVERY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="RS-RECOVERY:actual-source-refinement";
 attribute :>> premise="Unknown handoff/root/writer/capacity/binding/gate states refuse resume; isolated native result unknown may retain resources while GC resumes; typed effect/disposition forbids replay or refund inferred from scalar error";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RS-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/ResumeSealCleanup.lean";
 attribute :>> subjectScope="RS-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Release/acquire handoff/terminal/seal publication, code/root/native pin drain, generation wrap and external effect/stop boundary require actual C/platform refinement; no arbitrary owner-death repair";
 }
 ref part roundFinish=GambitRootScanArbitration::finish;
 ref part roundReturn=GambitRootScanArbitration::returnGate;
 ref part roundWait=GambitRootScanArbitration::waitGraph;
 ref part roundOrder=GambitRootScanArbitration::order;
 ref part nativeRoots=GambitNativeRootReentry::coverage;
 ref part nativeEntry=GambitNativeRootReentry::reentry;
 ref part nativeFfi=GambitNativeRootReentry::foreign;
 ref part nativeEnvelope=GambitStillCompletionLifetime::envelope;
 ref part nativeRestore=GambitStillCompletionLifetime::restore;
 ref part release=GambitRuntimeAssurance::release.source;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=handoff; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=handoff; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=dispatch; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=dispatch; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=history; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=induction; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=history; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=induction; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=roundOrder; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=roundFinish; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=roundReturn; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=roundWait; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=handoff; ref part :>> prerequisite=roundWait; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=handoff; ref part :>> prerequisite=release; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=handoff; ref part :>> prerequisite=nativeEnvelope; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=nativeRoots; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=handoff; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=rootCustody; ref part :>> prerequisite=nativeFfi; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=dispatch; ref part :>> prerequisite=rootCustody; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=dispatch; ref part :>> prerequisite=nativeEntry; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=dispatch; ref part :>> prerequisite=roundWait; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=handoff; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=release; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=origins; ref part :>> prerequisite=dispatch; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=sealLaw; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=handoff; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=nativeEnvelope; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=nativeEntry; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=order; }
 part dependency35 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=rootCustody; }
 part dependency36 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=sealLaw; ref part :>> prerequisite=origins; }
 part dependency37 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=recovery; ref part :>> prerequisite=nativeRestore; }
 part sealLawRoute : GambitHostRootsRefinement::Route { ref part :>> need=sealLaw;
 attribute :>> sourceAnchors="doc/gambit.txi:19006-19044;lib/_kernel.scm:3884-3894;lib/mem.c:4390-4451,4932-4935;lib/mem.c:4023-4038,684-703,4932-4935;lib/setup.c:4572-4590;lib/mem.c:6998-7085,4525-4568;lib/setup.c:1065-1113;include/gambit.h.in:10325-10334";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Every admitted strong/weak/private/cleanup duty closes or has qualified deferred handoff; capacity success or safe-error outcome, context preparation, result delivery, binding, writer closure and current generation precede active permit; domain-wide finalizer inventory required";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part handoffRoute : GambitHostRootsRefinement::Route { ref part :>> need=handoff;
 attribute :>> sourceAnchors="lib/mem.c:4390-4451,4932-4935;lib/c_intf.c:1683-1711,5155-5189;lib/c_intf.c:5287-5312,5322-5347,5357-5382;lib/os_io.c:10162-10176,10458-10472";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Reserve before destructive wrapper retirement; canonical task owns payload/dependencies/credits and accepted decision before source drops custody; queue notification or transport loss is not acceptance/completion";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part rootCustodyRoute : GambitHostRootsRefinement::Route { ref part :>> need=rootCustody;
 attribute :>> sourceAnchors="lib/c_intf.c:1683-1711,5155-5189;lib/os_io.c:3948-3973,5124-5140;OpenSSL SSL_CTX_free documentation;lib/mem.c:4023-4038,684-703,4932-4935;lib/setup.c:4572-4590";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Foreign payload is opaque to scan; deferred managed dependencies must already be traced and rooted or trigger pre-seal rescan; native/RC/code/library storage survives actual cleanup_rc and old-reader drain";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part dispatchRoute : GambitHostRootsRefinement::Route { ref part :>> need=dispatch;
 attribute :>> sourceAnchors="lib/os_io.c:1625-1681;lib/os_io.c:930-1023,1435-1488;lib/os_io.h:74-116;lib/os_io.c:3948-3973,5124-5140;OpenSSL SSL_CTX_free documentation;lib/mem.c:6998-7085,4525-4568;lib/setup.c:1065-1113;include/gambit.h.in:10325-10334";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Only qualified native-only execution may overlap GC; owner/managed callback waits until active permit and rooted activation, while cleanup never waits for that callback; explicit WaitContext replaces PSTATE scratch";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part originsRoute : GambitHostRootsRefinement::Route { ref part :>> need=origins;
 attribute :>> sourceAnchors="doc/gambit.txi:19006-19044;lib/_kernel.scm:3884-3894;lib/mem.c:4390-4451,4932-4935;lib/c_intf.c:5287-5312,5322-5347,5357-5382;lib/os_io.c:10162-10176,10458-10472;lib/mem.c:4023-4038,684-703,4932-4935;lib/setup.c:4572-4590";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="GC, explicit foreign-release!, constructor rollback and teardown have different invocation/error/timing contracts; at-most-once invocation preserved and delay permission is explicit, not inferred from unreachable wrapper";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part recoveryRoute : GambitHostRootsRefinement::Route { ref part :>> need=recovery;
 attribute :>> sourceAnchors="lib/mem.c:4390-4451,4932-4935;lib/os_io.c:1625-1681;lib/os_io.c:1603-1622,5831-5860;lib/mem.c:6998-7085,4525-4568;lib/setup.c:1065-1113;include/gambit.h.in:10325-10334";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Unknown handoff/root/writer/capacity/binding/gate states refuse resume; isolated native result unknown may retain resources while GC resumes; typed effect/disposition forbids replay or refund inferred from scalar error";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="doc/gambit.txi:19006-19044;lib/_kernel.scm:3884-3894;lib/mem.c:4390-4451,4932-4935;lib/c_intf.c:1683-1711,5155-5189;lib/c_intf.c:5287-5312,5322-5347,5357-5382;lib/os_io.c:10162-10176,10458-10472;lib/os_io.c:1625-1681;lib/os_io.c:930-1023,1435-1488;lib/os_io.h:74-116;lib/os_io.c:1603-1622,5831-5860;lib/os_io.c:3948-3973,5124-5140;OpenSSL SSL_CTX_free documentation;lib/mem.c:4023-4038,684-703,4932-4935;lib/setup.c:4572-4590;lib/mem.c:6998-7085,4525-4568;lib/setup.c:1065-1113;include/gambit.h.in:10325-10334";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Release/acquire handoff/terminal/seal publication, code/root/native pin drain, generation wrap and external effect/stop boundary require actual C/platform refinement; no arbitrary owner-death repair";
 attribute :>> failureCustodian="Source retains reserved/unknown detach; accepted service retains native/root/code/wait backing and exact task identity; unknown GC-critical state refuses resume; isolated native outcome debt cannot authorize replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="public-invocation-contract";
 attribute :>> sourceAnchors="doc/gambit.txi:19006-19044;lib/_kernel.scm:3884-3894";
 attribute :>> actualChain="Manual requires at-most-once release invocation; explicit call returns/raises using release result";
 attribute :>> hazard="Queue acceptance is not invocation/completion; error and timing cannot be redefined silently";
 attribute :>> replacement="Origin-specific adapters; opt-in effect/delay profile and public observation contract";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="gc-sweep-and-teardown";
 attribute :>> sourceAnchors="lib/mem.c:4390-4451,4932-4935";
 attribute :>> actualChain="GC sweep and free_still_objs call release_foreign then free wrapper; cleanup_mem_pstate then frees RC chain";
 attribute :>> hazard="Deferred native dependencies can outlive wrapper/PSTATE; task enqueue cannot authorize native free";
 attribute :>> replacement="Detach only after stable accepted custody; drain or actually transfer RC/native/code ownership before teardown";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="release-function-dispatch";
 attribute :>> sourceAnchors="lib/c_intf.c:1683-1711,5155-5189";
 attribute :>> actualChain="POINTER_to_SCMOBJ stores release_fn and native pointer; release_foreign clears both then invokes arbitrary C function";
 attribute :>> hazard="Cleared fields prevent retry; failure can follow destructive effects; source has no typed effect/affinity schema";
 attribute :>> replacement="Preinstalled descriptor/attempt; no raw clear-to-publish gap or blind replay";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="conversion-rollback";
 attribute :>> sourceAnchors="lib/c_intf.c:5287-5312,5322-5347,5357-5382";
 attribute :>> actualChain="Three constructor conversions directly invoke release_fn on conversion failure";
 attribute :>> hazard="Ownership starts before a Scheme wrapper exists; new deferral can change return/error/cleanup ordering";
 attribute :>> replacement="Keep caller synchronous semantics unless separately qualified; reserve/native payload custody before failure transfer";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="device-foreign-registration";
 attribute :>> sourceAnchors="lib/os_io.c:10162-10176,10458-10472";
 attribute :>> actualChain="Raw fd and stream constructors register device_cleanup_from_ptr and synchronously cleanup on wrapping error";
 attribute :>> hazard="Not every registration/rollback/leaf is qualified by one function pointer";
 attribute :>> replacement="Shared DeviceReleaseSpec plus per-leaf/origin profile; no installed-target coverage claim";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="device-cleanup-waits";
 attribute :>> sourceAnchors="lib/os_io.c:1625-1681";
 attribute :>> actualChain="Unlink group; close read/write; EAGAIN waits in device_select; finally release";
 attribute :>> hazard="Destructive partial failures, unbounded I/O wait and native users; no proof of owner callback in this helper alone";
 attribute :>> replacement="Resumable direction/effect state and dedicated WaitContext; no group-unlink retry";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="implicit-wait-context";
 attribute :>> sourceAnchors="lib/os_io.c:930-1023,1435-1488;lib/os_io.h:74-116";
 attribute :>> actualChain="select/poll uses stack-local state, PSTATE fdset and abort channel";
 attribute :>> hazard="Independent executor cannot borrow a released or destroyed context scratch lifetime";
 attribute :>> replacement="Owned wait buffers/capacity/wake endpoint; dependency pins and no managed collective in leaf wait";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="error-versus-storage";
 attribute :>> sourceAnchors="lib/os_io.c:1603-1622,5831-5860";
 attribute :>> actualChain="device_release invokes virtual release then frees self even on error; close stage can change before OS error";
 attribute :>> hazard="Nonzero error does not imply native allocation alive or safe retry";
 attribute :>> replacement="Typed effects and allocation disposition; FailedFreed differs from AlivePartial/Unknown";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="library-hidden-callbacks";
 attribute :>> sourceAnchors="lib/os_io.c:3948-3973,5124-5140;OpenSSL SSL_CTX_free documentation";
 attribute :>> actualChain="TLS wrappers free strings, SSL_CTX/SSL and RC; configured session-remove callbacks may run inside SSL_CTX_free";
 attribute :>> hazard="Library call name is not a no-callback proof; local callback configuration/installed library unqualified";
 attribute :>> replacement="Bind effect profile to code/library/config revision; retain library and native dependency pins";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="opaque-roots-and-shutdown";
 attribute :>> sourceAnchors="lib/mem.c:4023-4038,684-703,4932-4935;lib/setup.c:4572-4590";
 attribute :>> actualChain="FOREIGN scan is opaque; teardown frees still/RC before OS cleanup";
 attribute :>> hazard="Opaque payload is not a Scheme root descriptor; RC addref does not survive unconditional cleanup_rc";
 attribute :>> replacement="Existing traced root-domain ownership or rescan; drain/physical transfer before RC, wait, callback code withdrawal";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="gc-recovery-consumers";
 attribute :>> sourceAnchors="lib/mem.c:6998-7085,4525-4568;lib/setup.c:1065-1113;include/gambit.h.in:10325-10334";
 attribute :>> actualChain="GC phases then resize/fudge/prepare, sync result delivery, CFUN register reload";
 attribute :>> hazard="RootAck/queue empty do not establish fresh fp/hp/limits, correct result or protected reload";
 attribute :>> replacement="Immutable WholeRoundResumeSeal plus current-generation active permit, safe error continuation and reload";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="GC critical path";
 attribute :>> removedWork="Move only qualified delayed release body off round-critical cleanup";
 attribute :>> bound="Serial conditional work: old=Tcore+sum(Fi), new=Tcore+sum(Hi)+ledger/rescan costs";
 attribute :>> addedCost="Reservation/handoff, root closure and new queue contention";
 attribute :>> condition="Saving only if Fi exceeds Hi plus added costs and delay semantics permit; no measured time or universal positive benefit";
 }
 part cost1 : CostRow {
 attribute :>> capability="Task support";
 attribute :>> removedWork="Reuse shared descriptor/queue/attempt/result machinery across eligible leaves";
 attribute :>> bound="One reserve, acceptance, claim and terminal-publication transition per ordinary task; notifications/queries separate";
 attribute :>> addedCost="Stable metadata, source/service custody and bounded admission pools";
 attribute :>> condition="These are design operations, not four machine atomics or four syscall costs";
 }
 part cost2 : CostRow {
 attribute :>> capability="Root coverage";
 attribute :>> removedWork="Preserve callback procedure/managed dependencies across delayed execution";
 attribute :>> bound="Additional root scanning O(Rdeps); newly discovered roots require closed rescan before seal";
 attribute :>> addedCost="Root-domain records, relocation-safe handles and retained dependency backing";
 attribute :>> condition="Opaque foreign payload cannot silently become scanned; no new unseen managed edge after closure";
 }
 part cost3 : CostRow {
 attribute :>> capability="Native result ambiguity";
 attribute :>> removedWork="GC can resume despite isolated native outcome uncertainty";
 attribute :>> bound="Zero additional invocation on outcome query; zero refund without known disposition";
 attribute :>> addedCost="Native task/backing retained, possibly indefinitely";
 attribute :>> condition="Only effect-isolated admitted cohort; handoff/root/gate/capacity uncertainty still refuses resume";
 }
 part cost4 : CostRow {
 attribute :>> capability="Error and disposition";
 attribute :>> removedWork="Avoid replay/free based on scalar error";
 attribute :>> bound="At most one invocation per foreign release attempt; FailedFreed must not free again";
 attribute :>> addedCost="Typed effect progress and allocation-disposition ledger";
 attribute :>> condition="Current device_release can free on error; external close outcome and device-storage outcome differ";
 }
 part cost5 : CostRow {
 attribute :>> capability="Owner callback cycle";
 attribute :>> removedWork="Publish accepted callback task then let owner reacquire before executing it";
 attribute :>> bound="Cleanup waits handoff/root closure, not owner callback completion";
 attribute :>> addedCost="Post-seal dispatch and activation/root/binding protocol";
 attribute :>> condition="Unknown affinity/hidden callback or delayed-effect semantics rejects profile; no guaranteed callback latency";
 }
 part cost6 : CostRow {
 attribute :>> capability="Admission memory";
 attribute :>> removedWork="Reserve delivery/root/native-dependency budget before released GC profile is admitted";
 attribute :>> bound="For M admitted possible jobs: O(M) task slots plus exact retained native/root backing budget";
 attribute :>> addedCost="Registration/reservation capacity can raise resident/peak memory";
 attribute :>> condition="Pool failure before destructive transfer retains source; never block GC waiting for owner that waits for seal";
 }
 part cost7 : CostRow {
 attribute :>> capability="Whole-round peak";
 attribute :>> removedWork="Keep physical backing distinct from wrapper retirement and receipt ACK";
 attribute :>> bound="Peak=max_t(existing backing+task/receipt/wait pools+retained roots/native payload+quarantine)";
 attribute :>> addedCost="Deferred cleanup may postpone native/RC/library release beyond this GC";
 attribute :>> condition="Do not add independent maxima or refund on enqueue; no whole-round peak reduction proved";
 }
 part cost8 : CostRow {
 attribute :>> capability="Modern C architecture";
 attribute :>> removedWork="Reuse Scheme semantic/FrameSpec output and C representation/conversion machinery";
 attribute :>> bound="Zero additional Zig runtime-work reduction established";
 attribute :>> addedCost="Both require effect/origin profiles, root transfer, stop/restore and ordering proofs";
 attribute :>> condition="Modernization gain is role/ownership/phase separation, not a language-provided GC or automatic finalization proof";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="phases"; attribute :>> labelText="Strong + weak frontier closed\\nroot/view obligations retained"; }
 part node1 : DiagramNode { attribute :>> nodeId="profile"; attribute :>> labelText="Origin + effect + delay admission\\nreserve native/root/code/wait budget"; }
 part node2 : DiagramNode { attribute :>> nodeId="handoff"; attribute :>> labelText="Canonical accepted release task\\nsource -> service custody"; }
 part node3 : DiagramNode { attribute :>> nodeId="cleanup"; attribute :>> labelText="GC cleanup handback\\nno wait for owner callback"; }
 part node4 : DiagramNode { attribute :>> nodeId="prepare"; attribute :>> labelText="Capacity outcome + context prepare\\nresult / writer / binding checks"; }
 part node5 : DiagramNode { attribute :>> nodeId="seal"; attribute :>> labelText="WholeRoundResumeSeal\\nactive permit then root reload"; }
 part node6 : DiagramNode { attribute :>> nodeId="owner"; attribute :>> labelText="Owner callback / native executor\\nqualified activation + WaitContext"; }
 part node7 : DiagramNode { attribute :>> nodeId="outcome"; attribute :>> labelText="Known effects + storage disposition\\nseparate native backing release"; }
 part node8 : DiagramNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Unknown GC-critical state\\nretain custody; refuse resume"; }
 part node9 : DiagramNode { attribute :>> nodeId="isolated"; attribute :>> labelText="Isolated native result unknown\\nretain backing; no replay"; }
 part node10 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT\\nQNT / Lean / source-order gaps"; }
 part edge0 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="reserve before destructive detach"; }
 part edge1 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node2; attribute :>> labelText="roots covered; no unseen edges"; }
 part edge2 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node3; attribute :>> labelText="known accepted custody"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="critical debt settled"; }
 part edge4 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="all current-round gates"; }
 part edge5 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node6; attribute :>> labelText="native-only may run; managed waits seal"; }
 part edge6 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="callback permission after reload"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="publish actual disposition"; }
 part edge8 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node9; attribute :>> labelText="lost isolated native outcome"; }
 part edge9 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node8; attribute :>> labelText="unknown acceptance or root transfer"; }
 part edge10 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node8; attribute :>> labelText="unknown capacity / binding / gate"; }
 part edge11 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node3; attribute :>> labelText="allowed only under proved isolation"; }
 part edge12 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node3; attribute :>> labelText="known completion also admissible"; }
 part edge13 : DiagramEdge { ref :>> producer=node10; ref :>> consumer=node5; attribute :>> labelText="conditional refinement only"; }
}
