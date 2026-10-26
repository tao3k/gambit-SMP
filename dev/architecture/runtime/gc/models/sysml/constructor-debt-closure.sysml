/* Modern C research. Business completion and uncovered GC debt are distinct. */
package GambitConstructorDebtClosure {
 private import ScalarValues::*;
 part def ConstructionEscrow { attribute identity : String; attribute nativeStage : String; attribute rootView : String; attribute resultSlot : String; attribute nativeLease : String; attribute ticket : String; attribute epoch : Integer; attribute generation : Integer; attribute callbackFrameChain : String; attribute knownDisposition : Boolean; ref releaseRight : GambitReleaseProducerAdmission::ReleaseRight; ref frozenRoots : GambitNativeRootReentry::FrozenState; ref rootReentry : GambitNativeRootReentry::ReentryState; ref roundSeal : GambitResumeSealCleanup::SealState; }
 part def ClosureState { attribute seal : Boolean; attribute businessPending : Boolean; attribute uncoveredManagedDebt : Integer; attribute rootsCurrent : Boolean; attribute custodyKnown : Boolean; attribute writerStopped : Boolean; attribute noOwnerReverseWait : Boolean; }
 requirement def CoveredDebtLaw { subject s : ClosureState; require constraint { not s.seal or (s.uncoveredManagedDebt == 0 and s.rootsCurrent and s.custodyKnown and s.writerStopped and s.noOwnerReverseWait) } }
 part def RecoveryCut { attribute capturedResult : Boolean; attribute nativeOnlyIsolated : Boolean; attribute callbackSuspendedCovered : Boolean; attribute resourceOutcomeKnown : Boolean; attribute gcMetadataKnown : Boolean; }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/constructor_debt_closure.qnt";
 attribute :>> subjectScope="constructor_debt_closure:33-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One invocation/escrow/ticket and one abstract callback frame; captured-result, native-only isolation or suspended-callback cuts are assumed qualification; other whole-round gates, exact root descriptors and native effects remain premises";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="GambitSMP.ConstructorDebtClosure:businessCompletionIndependent;isolatedOutcomeIndependent;unknownCustodyRejects;liveManagedWriterRejects;missingTraceRejects;gateHeldRejects;reverseWaitRejects;noCoverageRejects;freezeConserves;wrapConserves;disposeConserves;stepConserves;traceConserves;waitRankDecreases;noReverseOwnerWait;noServiceWaitsOwner;noTwoCycle;parentNotCleanupTarget;unknownDispositionKeepsTicket;readersKeepTicket;replayNotRecovery;rootComposition";
 attribute :>> premise="22 conditional declarations: credit Step/Trace, coverage/custody rejection, business-completion independence and decreasing declared wait rank; no all-action QNT/C simulation or native fairness";
 }
 part cut : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-CUT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="CD-CUT:actual-source-refinement";
 attribute :>> premise="Separate business completion debt from uncovered GC debt: wrapper allocation can itself call GC; captured native result plus frozen complete roots may close GC without returning the constructor. No direct refinement claim to prior total-constructor-zero law; mapping and source pause cuts must be proved";
 }
 part escrow : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-ESCROW";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="CD-ESCROW:actual-source-refinement";
 attribute :>> premise="Before native production reserve backed no-GC ticket/root/result slots, exact native leases and code; publish frozen construction view before conversion allocation may GC; retain physical owner across failure, payload capture and wrapper/result root publication";
 }
 part failures : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-FAILURES";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="CD-FAILURES:actual-source-refinement";
 attribute :>> premise="Accept rollback targets created client not borrowed server; process return-slot failure retains dev/pid/pipe/status and temporary-string duties with original error mapping; Win32 removed message retains MSG/RC and external message ownership; no false replay/rollback of external effects";
 }
 part unknown : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-UNKNOWN";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="CD-UNKNOWN:actual-source-refinement";
 attribute :>> premise="Only known root/custody/authority metadata with native-only bounded effects permits outcome-isolated resume; unknown root writers/profile/slot owner refuses seal. Accepted query is not reexecution, native disposition proof or ticket refund; process side effects and MSG pointer payloads need exact independent profiles";
 }
 part reentry : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-REENTRY";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="CD-REENTRY:actual-source-refinement";
 attribute :>> premise="Seal captures current epoch/generation, blocks managed writers, scans all ancestor/callback/root views; active-permit reentry consumes the frozen view and restores managed writer authority before allocation/callback/result delivery; late native-only result stores cannot add managed roots";
 }
 part progress : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-PROGRESS";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="CD-PROGRESS:actual-source-refinement";
 attribute :>> premise="Owner may wait GC; GC may wait bounded root-view scanning; scanning/cleanup may not acquire owner port mutex, callback permit, PSTATE wait scratch or new collector allocation capacity. Declared rank is valid only if all transitive service/lock edges are covered; no arbitrary native-call timeout guarantee";
 }
 part order : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="CD-ORDER";
 attribute :>> kind="native-memory-order";
 attribute :>> subjectPath="models/gambit/lean/ConstructorDebtClosure.lean";
 attribute :>> subjectScope="CD-ORDER:actual-C-memory-refinement";
 attribute :>> premise="Release/acquire escrow view and result publication; gate close/reservation capture; borrowed native device/RC chain lifetime; generation-safe result/reader/ticket retirement and no-escape initialization require actual C/platform proof";
 }
 ref part priorBudget=GambitReleaseProducerAdmission::budget;
 ref part priorRoots=GambitReleaseProducerAdmission::roots;
 ref part priorEffects=GambitReleaseProducerAdmission::effects;
 ref part priorOrigins=GambitReleaseProducerAdmission::origins;
 ref part priorOrder=GambitReleaseProducerAdmission::order;
 ref part roundSeal=GambitResumeSealCleanup::sealLaw;
 ref part roundDispatch=GambitResumeSealCleanup::dispatch;
 ref part roundHandoff=GambitResumeSealCleanup::handoff;
 ref part roundRecovery=GambitResumeSealCleanup::recovery;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cut; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cut; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cut; ref part :>> prerequisite=order; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=order; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failures; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failures; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failures; ref part :>> prerequisite=order; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unknown; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unknown; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unknown; ref part :>> prerequisite=order; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=history; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=induction; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=order; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=history; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=induction; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=order; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=history; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=induction; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=order; ref part :>> prerequisite=priorOrder; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cut; ref part :>> prerequisite=escrow; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cut; ref part :>> prerequisite=progress; }
 part dependency23 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=cut; ref part :>> prerequisite=roundSeal; }
 part dependency24 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=priorBudget; }
 part dependency25 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=priorRoots; }
 part dependency26 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=escrow; ref part :>> prerequisite=roundHandoff; }
 part dependency27 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failures; ref part :>> prerequisite=escrow; }
 part dependency28 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=failures; ref part :>> prerequisite=priorOrigins; }
 part dependency29 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unknown; ref part :>> prerequisite=priorEffects; }
 part dependency30 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unknown; ref part :>> prerequisite=escrow; }
 part dependency31 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=unknown; ref part :>> prerequisite=roundRecovery; }
 part dependency32 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=priorRoots; }
 part dependency33 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=roundRecovery; }
 part dependency34 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reentry; ref part :>> prerequisite=cut; }
 part dependency35 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=roundDispatch; }
 part dependency36 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=progress; ref part :>> prerequisite=priorEffects; }
 part cutRoute : GambitHostRootsRefinement::Route { ref part :>> need=cut;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1667,1677-1728;lib/c_intf.c:5156-5223;lib/mem.c:1677-1709;lib/os_io.c:10930-10970;lib/_kernel.scm:4370-4374;lib/_io.scm:8395-8446;lib/os_io.c:11471-11490;lib/_kernel.scm:4442-4446;lib/_io.scm:9685-9730";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Separate business completion debt from uncovered GC debt: wrapper allocation can itself call GC; captured native result plus frozen complete roots may close GC without returning the constructor. No direct refinement claim to prior total-constructor-zero law; mapping and source pause cuts must be proved";
 attribute :>> failureCustodian="Canonical escrow retains exact native stage, roots, result slot and ticket; unknown metadata/writer/transfer refuses resume; only qualified resource-only uncertainty is isolated; no replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part escrowRoute : GambitHostRootsRefinement::Route { ref part :>> need=escrow;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1667,1677-1728;lib/c_intf.c:5156-5223;lib/mem.c:1677-1709;lib/os_io.c:5591-5676,6067-6125;lib/os_io.c:9101-9185,9250-9345,9472-9508;lib/os_io.c:7109-7154;lib/mem.c:684-780;Microsoft PeekMessageA Remarks;lib/os_io.c:196-244,1579-1685;lib/os_io.h:74-91;lib/mem.c:684-703,4023-4038,4390-4451,4932-4935;lib/setup.c:4572-4590";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Before native production reserve backed no-GC ticket/root/result slots, exact native leases and code; publish frozen construction view before conversion allocation may GC; retain physical owner across failure, payload capture and wrapper/result root publication";
 attribute :>> failureCustodian="Canonical escrow retains exact native stage, roots, result slot and ticket; unknown metadata/writer/transfer refuses resume; only qualified resource-only uncertainty is isolated; no replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part failuresRoute : GambitHostRootsRefinement::Route { ref part :>> need=failures;
 attribute :>> sourceAnchors="lib/os_io.c:5591-5676,6067-6125;lib/os_io.c:10930-10970;lib/_kernel.scm:4370-4374;lib/_io.scm:8395-8446;lib/os_io.c:9101-9185,9250-9345,9472-9508;lib/os_io.c:10553-10648;lib/_kernel.scm:4309-4316;lib/_io.scm:7166-7203;lib/os_io.c:3520-3593,3598-3617,3804-3864;lib/os_io.c:7109-7154;lib/mem.c:684-780;Microsoft PeekMessageA Remarks;lib/os_io.c:11471-11490;lib/_kernel.scm:4442-4446;lib/_io.scm:9685-9730";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Accept rollback targets created client not borrowed server; process return-slot failure retains dev/pid/pipe/status and temporary-string duties with original error mapping; Win32 removed message retains MSG/RC and external message ownership; no false replay/rollback of external effects";
 attribute :>> failureCustodian="Canonical escrow retains exact native stage, roots, result slot and ticket; unknown metadata/writer/transfer refuses resume; only qualified resource-only uncertainty is isolated; no replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part unknownRoute : GambitHostRootsRefinement::Route { ref part :>> need=unknown;
 attribute :>> sourceAnchors="lib/os_io.c:5591-5676,6067-6125;lib/os_io.c:9101-9185,9250-9345,9472-9508;lib/os_io.c:3520-3593,3598-3617,3804-3864;lib/os_io.c:7109-7154;lib/mem.c:684-780;Microsoft PeekMessageA Remarks;lib/os_io.c:196-244,1579-1685;lib/os_io.h:74-91;lib/mem.c:684-703,4023-4038,4390-4451,4932-4935;lib/setup.c:4572-4590";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Only known root/custody/authority metadata with native-only bounded effects permits outcome-isolated resume; unknown root writers/profile/slot owner refuses seal. Accepted query is not reexecution, native disposition proof or ticket refund; process side effects and MSG pointer payloads need exact independent profiles";
 attribute :>> failureCustodian="Canonical escrow retains exact native stage, roots, result slot and ticket; unknown metadata/writer/transfer refuses resume; only qualified resource-only uncertainty is isolated; no replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part reentryRoute : GambitHostRootsRefinement::Route { ref part :>> need=reentry;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1667,1677-1728;lib/c_intf.c:5156-5223;lib/mem.c:1677-1709;lib/os_io.c:10930-10970;lib/_kernel.scm:4370-4374;lib/_io.scm:8395-8446;lib/os_io.c:7109-7154;lib/mem.c:684-780;Microsoft PeekMessageA Remarks;lib/os_io.c:11471-11490;lib/_kernel.scm:4442-4446;lib/_io.scm:9685-9730;gsc/_ptree2.scm:2586-2678;include/gambit.h.in:10247-10250,10592-10595;lib/_kernel.scm:4309-4316,4370-4374,4442-4446";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Seal captures current epoch/generation, blocks managed writers, scans all ancestor/callback/root views; active-permit reentry consumes the frozen view and restores managed writer authority before allocation/callback/result delivery; late native-only result stores cannot add managed roots";
 attribute :>> failureCustodian="Canonical escrow retains exact native stage, roots, result slot and ticket; unknown metadata/writer/transfer refuses resume; only qualified resource-only uncertainty is isolated; no replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part progressRoute : GambitHostRootsRefinement::Route { ref part :>> need=progress;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1667,1677-1728;lib/os_io.c:10930-10970;lib/_kernel.scm:4370-4374;lib/_io.scm:8395-8446;lib/os_io.c:3520-3593,3598-3617,3804-3864;lib/os_io.c:11471-11490;lib/_kernel.scm:4442-4446;lib/_io.scm:9685-9730;lib/os_io.c:196-244,1579-1685;lib/os_io.h:74-91;lib/mem.c:684-703,4023-4038,4390-4451,4932-4935;lib/setup.c:4572-4590;gsc/_ptree2.scm:2586-2678;include/gambit.h.in:10247-10250,10592-10595;lib/_kernel.scm:4309-4316,4370-4374,4442-4446";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Owner may wait GC; GC may wait bounded root-view scanning; scanning/cleanup may not acquire owner port mutex, callback permit, PSTATE wait scratch or new collector allocation capacity. Declared rank is valid only if all transitive service/lock edges are covered; no arbitrary native-call timeout guarantee";
 attribute :>> failureCustodian="Canonical escrow retains exact native stage, roots, result slot and ticket; unknown metadata/writer/transfer refuses resume; only qualified resource-only uncertainty is isolated; no replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part orderRoute : GambitHostRootsRefinement::Route { ref part :>> need=order;
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1667,1677-1728;lib/c_intf.c:5156-5223;lib/mem.c:1677-1709;lib/os_io.c:5591-5676,6067-6125;lib/os_io.c:10930-10970;lib/_kernel.scm:4370-4374;lib/_io.scm:8395-8446;lib/os_io.c:9101-9185,9250-9345,9472-9508;lib/os_io.c:10553-10648;lib/_kernel.scm:4309-4316;lib/_io.scm:7166-7203;lib/os_io.c:3520-3593,3598-3617,3804-3864;lib/os_io.c:7109-7154;lib/mem.c:684-780;Microsoft PeekMessageA Remarks;lib/os_io.c:11471-11490;lib/_kernel.scm:4442-4446;lib/_io.scm:9685-9730;lib/os_io.c:196-244,1579-1685;lib/os_io.h:74-91;lib/mem.c:684-703,4023-4038,4390-4451,4932-4935;lib/setup.c:4572-4590;gsc/_ptree2.scm:2586-2678;include/gambit.h.in:10247-10250,10592-10595;lib/_kernel.scm:4309-4316,4370-4374,4442-4446";
 attribute :>> patchAnchors="Design-only refactoring cut; no runtime patch or native test";
 attribute :>> projection="Release/acquire escrow view and result publication; gate close/reservation capture; borrowed native device/RC chain lifetime; generation-safe result/reader/ticket retirement and no-escape initialization require actual C/platform proof";
 attribute :>> failureCustodian="Canonical escrow retains exact native stage, roots, result slot and ticket; unknown metadata/writer/transfer refuses resume; only qualified resource-only uncertainty is isolated; no replay/refund";
 attribute :>> status="source-and-native-order-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="still-allocation-gc-cut";
 attribute :>> sourceAnchors="lib/mem.c:1487-1500,1593-1667,1677-1728";
 attribute :>> actualChain="alloc_scmobj_still can release allocation lock then call GC before allocating/linking still wrapper";
 attribute :>> hazard="Constructor return can depend on the GC it invoked; object body initialization belongs to caller before next allocation";
 attribute :>> replacement="Frozen escrow root view and ticket before entry; no collector wait for business completion";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="foreign-wrapper-publish";
 attribute :>> sourceAnchors="lib/c_intf.c:5156-5223;lib/mem.c:1677-1709";
 attribute :>> actualChain="Allocate FOREIGN then write tags/release_fn/ptr and result slot; allocation may have collected before fields exist";
 attribute :>> hazard="Native resource exists while Scheme wrapper does not; partially initialized body may not be exposed to scanner";
 attribute :>> replacement="Preinstalled ResultSlot/RootView; bounded initialized-body publication with no implicit safepoint; source proof open";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="accept-native-producer";
 attribute :>> sourceAnchors="lib/os_io.c:5591-5676,6067-6125";
 attribute :>> actualChain="accept socket; setup client; close socket on setup failure; TLS SSL_new/SSL_accept; transfer close responsibility";
 attribute :>> hazard="Server borrower, accepted socket, client storage and TLS state are distinct; callbacks/configuration unqualified";
 attribute :>> replacement="Client escrow identity plus server lease and staged socket/TLS custody; do not re-accept on lost result";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="accept-failure-consumer";
 attribute :>> sourceAnchors="lib/os_io.c:10930-10970;lib/_kernel.scm:4370-4374;lib/_io.scm:8395-8446";
 attribute :>> actualChain="C wrapper conversion fails then cleanup(d server); Scheme read holds port mutex, retries EINTR, releases lock for EAGAIN, raises other errors";
 attribute :>> hazard="Wrong rollback target and owner-held port mutex; generic replay can consume a different connection";
 attribute :>> replacement="Rollback only captured client; scanner never takes port mutex; preserve Scheme error/return boundary";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="process-native-producer";
 attribute :>> sourceAnchors="lib/os_io.c:9101-9185,9250-9345,9472-9508";
 attribute :>> actualChain="Mask interrupts; create pipes/fork; read exec status; setup device and transfer close responsibility; unmask; Windows has distinct handles";
 attribute :>> hazard="Live child may exist before setup/result publication; native pipe/dev failure not inverse of fork/exec";
 attribute :>> replacement="Separate child identity/status duty, device/fd stages, string temporaries and source-visible result; no generic kill or refork";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="process-failure-consumer";
 attribute :>> sourceAnchors="lib/os_io.c:10553-10648;lib/_kernel.scm:4309-4316;lib/_io.scm:7166-7203";
 attribute :>> actualChain="String-list conversions; native process setup; wrapper failure lacks local device cleanup, then string temporaries released; Scheme expects fixnum or device";
 attribute :>> hazard="Failure path can return result #f from converter while dev duty persists; generated function counts do not close ownership";
 attribute :>> replacement="Typed return slot commits original error e and retains dev/child escrow; audit semantics/correction before admission";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="process-status-and-disposal";
 attribute :>> sourceAnchors="lib/os_io.c:3520-3593,3598-3617,3804-3864";
 attribute :>> actualChain="Device records pid/status/cleanuped; POSIX status updated asynchronously; close polls status; Win32 closes process/thread handles";
 attribute :>> hazard="Closing pipes/handles/device storage does not prove child exit or termination; signal/group reader may still use it";
 attribute :>> replacement="Separate native process/status borrower pins and acknowledged close disposition; teardown waits exact readers, not inferred process death";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="message-native-producer";
 attribute :>> sourceAnchors="lib/os_io.c:7109-7154;lib/mem.c:684-780;Microsoft PeekMessageA Remarks";
 attribute :>> actualChain="Allocate/register RC MSG; PeekMessage(PM_REMOVE) may dispatch sent messages and then consume queued message; direct conversion return";
 attribute :>> hazard="Thread-affine reentry, consumed message, arbitrary pointer payload and RC owner lifetime";
 attribute :>> replacement="Reserve before read; known MSG escrow before wrapper allocation; suspended-callback view only with complete parent/callback roots";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="message-failure-consumer";
 attribute :>> sourceAnchors="lib/os_io.c:11471-11490;lib/_kernel.scm:4442-4446;lib/_io.scm:9685-9730";
 attribute :>> actualChain="Outer C propagates error; Scheme event read holds mutex and retries EINTR/EAGAIN or raises; wrapper success drops still hold";
 attribute :>> hazard="Conversion failure after PM_REMOVE cannot be rolled back by re-reading; RC data field starts FAL but does not root arbitrary MSG pointers";
 attribute :>> replacement="Keep original consumed message/RC duty; no requeue/replay equivalence claim; preserve thread dispatch and exception boundary";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="shared-device-native-lease";
 attribute :>> sourceAnchors="lib/os_io.c:196-244,1579-1685;lib/os_io.h:74-91";
 attribute :>> actualChain="Group links, refcount, close responsibility; cleanup unlinks, may wait and device_release can free despite error";
 attribute :>> hazard="Group membership/refcount is not independent collector lifetime/atomic ownership; owner callback can need resume permit";
 attribute :>> replacement="Dedicated native lease/custody and WaitContext; typed physical disposition; drain before group/RC/OS withdrawal";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="existing-root-and-cleanup-path";
 attribute :>> sourceAnchors="lib/mem.c:684-703,4023-4038,4390-4451,4932-4935;lib/setup.c:4572-4590";
 attribute :>> actualChain="FOREIGN payload opaque; sweep releases before free; cleanup_rc unconditionally frees chain before OS cleanup";
 attribute :>> hazard="Escrow raw native pointers are not managed root handles; addref does not survive processor teardown";
 attribute :>> replacement="Canonical root-domain registration/scan and physical RC transfer/drain; imported proof obligations stay open";
 }
 part caller11 : CallerRow {
 attribute :>> callerId="scheme-native-boundary";
 attribute :>> sourceAnchors="gsc/_ptree2.scm:2586-2678;include/gambit.h.in:10247-10250,10592-10595;lib/_kernel.scm:4309-4316,4370-4374,4442-4446";
 attribute :>> actualChain="Generated conversion templates and scheme-object C stubs expose result/error boundaries";
 attribute :>> hazard="Moving native work to generic worker may change c-lambda, callback, exception and held-lock semantics";
 attribute :>> replacement="Scheme keeps semantic/FrameSpec contract; modern C consumes typed constructor/root/result specs with origin-specific adapters";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="Business versus GC debt";
 attribute :>> removedWork="Remove dependency GC -> constructor return when the return itself needs GC";
 attribute :>> bound="For F frozen pending invocations, GC does not wait for F business completions; GC-critical uncovered debt must be zero";
 attribute :>> addedCost="F stable escrow records, no-GC publication and root scanning";
 attribute :>> condition="No claim all native producers can freeze; absent profile/stop/root evidence still refuses";
 }
 part cost1 : CostRow {
 attribute :>> capability="Non-cyclic root scanning";
 attribute :>> removedWork="Scan roots independently of owner port mutex/callback permit";
 attribute :>> bound="Declared wait rank owner=2 > GC=1 > bounded scan service=0";
 attribute :>> addedCost="Pre-backed scan metadata, pinned handles and transitive lock audit";
 attribute :>> condition="No deadlock proof beyond declared wait graph; all hidden callbacks/locks need source refinement";
 }
 part cost2 : CostRow {
 attribute :>> capability="Native-call count";
 attribute :>> removedWork="Query canonical result instead of re-accept/re-fork/re-read";
 attribute :>> bound="At most 1 native producer invocation and 1 wrapper/result delivery per modeled attempt";
 attribute :>> addedCost="Attempt identity, result/root slot and outcome-retention metadata";
 attribute :>> condition="This saves duplicate work only relative to an incorrect replay strategy, not a claimed speedup over current C";
 }
 part cost3 : CostRow {
 attribute :>> capability="Conditional GC critical path";
 attribute :>> removedWork="Keep admitted constructor completion/rollback wait off root closure";
 attribute :>> bound="Delta critical work = eliminated reverse-wait dependency minus freeze/scan/ledger costs; no finite wait-time bound on external calls";
 attribute :>> addedCost="Capture/freeze/scan/reentry actions and result root publication";
 attribute :>> condition="Positive only when service never waits on owner and added work is cheaper; not a wall-time measurement";
 }
 part cost4 : CostRow {
 attribute :>> capability="Ticket reuse";
 attribute :>> removedWork="Transfer existing persistent credit from source -> escrow -> wrapper or terminal";
 attribute :>> bound="Live duties <= pre-reserved slots; one duty remains charged while business result or disposal unknown";
 attribute :>> addedCost="Canonical record/receipt generation and reader/child drain";
 attribute :>> condition="No additional ticket for ordinary continuation of same duty; fanout needs separate reservation";
 }
 part cost5 : CostRow {
 attribute :>> capability="Control-memory bound";
 attribute :>> removedWork="Share immutable profile; keep per-attempt escrow and frozen view";
 attribute :>> bound="Control capacity = M*(escrowBytes+resultSlotBytes+receiptBytes)+rootCells*cellBytes+scan/wait pools+allocator overhead";
 attribute :>> addedCost="Physical resident backing exists before native effect";
 attribute :>> condition="Logical quota alone cannot guarantee no allocation failure; layouts/sizes remain unmeasured";
 }
 part cost6 : CostRow {
 attribute :>> capability="Whole-round peak";
 attribute :>> removedWork="Avoid requiring both old and copied payloads when exact ownership transfers";
 attribute :>> bound="Peak=max_t(heap+actual pools+unique native backing+root backing+quarantine)";
 attribute :>> addedCost="Captured client/process/MSG may outlive the GC; unknown outcome retains it";
 attribute :>> condition="Count shared native backing once; no whole-round peak reduction proved";
 }
 part cost7 : CostRow {
 attribute :>> capability="Native budget boundaries";
 attribute :>> removedWork="Bound process-local memory/handles without claiming external process/network memory";
 attribute :>> bound="Native bytes/handles charged by exact staged recipe; child process heap and OS/global resources have separate bounds";
 attribute :>> addedCost="Per-provider bound, temporary strings/pipes/TLS/RC overhead and side-effect state";
 attribute :>> condition="Unknown bounds refuse bounded admission; kernel/external resources are not covered by Scheme heap quota";
 }
 part cost8 : CostRow {
 attribute :>> capability="Failure-path modernization";
 attribute :>> removedWork="Unify custody support while preserving three different source semantics";
 attribute :>> bound="3 failure cuts: accepted client vs server; process result/error+dev duty; consumed MSG/RC duty";
 attribute :>> addedCost="Source correction, per-stage disposal and exception/error mapping";
 attribute :>> condition="No existing path retired; fixnum/device/#f behavior needs independent semantic acceptance";
 }
 part cost9 : CostRow {
 attribute :>> capability="Unknown outcome isolation";
 attribute :>> removedWork="Allow GC closure when only bounded native outcome is unknown";
 attribute :>> bound="0 extra invocation and 0 physical refund from timeout/notification loss; query then known-result reentry";
 attribute :>> addedCost="Potentially indefinite quarantine and retained roots/code/resource budget";
 attribute :>> condition="Unknown managed writer, dependency shape, callback frame or owner transfer is not isolatable";
 }
 part cost10 : CostRow {
 attribute :>> capability="Modern C and Zig";
 attribute :>> removedWork="Scheme-generated contracts and shared modern C service support";
 attribute :>> bound="No incremental Zig runtime-work saving established";
 attribute :>> addedCost="Both need escrow/root/lock/ABI/effect and memory-order proofs";
 attribute :>> condition="Modern C mandatory; a language switch supplies neither GC coverage nor deadlock freedom";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="reserve"; attribute :>> labelText="Pre-backed ticket + dependency/result slots\\nScheme/native inputs remain rooted"; }
 part node1 : DiagramNode { attribute :>> nodeId="native"; attribute :>> labelText="Native producer / exact staged resource duty\\naccept, process creation, message consume"; }
 part node2 : DiagramNode { attribute :>> nodeId="known"; attribute :>> labelText="Captured native result escrow\\nwrapper conversion may invoke GC"; }
 part node3 : DiagramNode { attribute :>> nodeId="callback"; attribute :>> labelText="Suspended callback / ancestor frames\\nonly a fully covered stop cut qualifies"; }
 part node4 : DiagramNode { attribute :>> nodeId="isolated"; attribute :>> labelText="Native-only bounded outcome unknown\\nno managed access / callback / hidden roots"; }
 part node5 : DiagramNode { attribute :>> nodeId="freeze"; attribute :>> labelText="Close managed publication authority\\nfreeze epoch + root/custody view"; }
 part node6 : DiagramNode { attribute :>> nodeId="scan"; attribute :>> labelText="Independent bounded root scan\\nnever acquire owner port mutex"; }
 part node7 : DiagramNode { attribute :>> nodeId="seal"; attribute :>> labelText="Whole-round gates + covered debt zero\\nbusiness completion may remain pending"; }
 part node8 : DiagramNode { attribute :>> nodeId="resume"; attribute :>> labelText="Consume seal and reacquire runtime\\nrestore roots / writer permission"; }
 part node9 : DiagramNode { attribute :>> nodeId="result"; attribute :>> labelText="Exact result-slot query or one conversion\\nroot result before delivery / rollback"; }
 part node10 : DiagramNode { attribute :>> nodeId="retain"; attribute :>> labelText="Unknown GC-critical metadata\\nretain custody; refuse this resume"; }
 part node11 : DiagramNode { attribute :>> nodeId="refund"; attribute :>> labelText="Known disposal + readers/children drain\\nphysical backing release then ticket recycle"; }
 part node12 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT -> QNT / Lean\\nsource and C-memory gates open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="reserve before irreversible effect"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="capture exact output"; }
 part edge2 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node3; attribute :>> labelText="real reentrant stop cut"; }
 part edge3 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node4; attribute :>> labelText="qualified native-only effects"; }
 part edge4 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node5; attribute :>> labelText="before wrapper allocation"; }
 part edge5 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node5; attribute :>> labelText="all parent/callback roots"; }
 part edge6 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="bounded resource-only uncertainty"; }
 part edge7 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="immutable complete view"; }
 part edge8 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="current-round trace receipt"; }
 part edge9 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="no GC -> owner-return edge"; }
 part edge10 : DiagramEdge { ref :>> producer=node8; ref :>> consumer=node9; attribute :>> labelText="query / convert / preserve original error"; }
 part edge11 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node11; attribute :>> labelText="known custody and disposition"; }
 part edge12 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node10; attribute :>> labelText="unknown writers / roots / lease"; }
 part edge13 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node10; attribute :>> labelText="unknown managed publication"; }
 part edge14 : DiagramEdge { ref :>> producer=node12; ref :>> consumer=node7; attribute :>> labelText="conditional model only"; }
}
