/* Target-component assurance: executable QNT, parametric Lean and reasoning
 * selection are distinct from C refinement or native runtime acceptance. */
package GambitSynchronousPublication {
    private import ScalarValues::*;
    part modelSet : GambitAssuranceRelations::FormalModelSet {
        attribute :>> modelSetId = "synchronous-publication";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> quintSource = "models/gambit/synchronous_publication.qnt";
        attribute :>> quintSymbols = "init; initReference; initFusedExplicit; step; safe; allFourFusedTest; escapedErasureCounterexampleTest";
        attribute :>> leanSource = "models/gambit/lean/SynchronousPublication.lean";
        attribute :>> leanSymbols = "zeroOwnersDischargesAllDebt; receiptCoverageAloneInsufficient; reservePreserves; settlementPreserves; knownReturnPreserves";
        attribute :>> evidenceReport = "evidence/research/sync-publication-assurance/checks.json";
        attribute :>> scope = "Four symbolic sites, two workers, three protocols, explicit notify/residual/unknown ownership; parametric debt and accounting lemmas; no source or weak-memory simulation";
        attribute :>> obligationIds = "SP-COVER; SP-FUSE; SP-LASTUSE; SP-EXIT; SP-SOURCE; SP-MEMORY";
    }
    part component : GambitAssuranceRelations::ComponentModelUse {
        attribute :>> componentId = "gc-synchronous-publication";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> bindingKind = "target-component-model";
        attribute :>> bindingId = "synchronous-publication";
        attribute :>> requiredModel = "Executable publication/idle/close histories and independent inductive ownership/accounting";
        attribute :>> stateProjection = "busy and residual approximate counted producer lifetime; stage approximates batch custody; pub and notified separate receipt from last use";
        attribute :>> eventProjection = "begin/prepare/reserve/commit/fused/notify/returnPublisher/drainCaller/idle/wake/close; retained unknown handoff";
        attribute :>> openPremises = "Actual C paths, custom allocator/fatal hooks, cancellation policy, MISC/ALLOC/G/Q order, layout and native memory model; finite model does not discharge them";
        attribute :>> obligationIds = "SP-COVER; SP-FUSE; SP-LASTUSE; SP-EXIT; SP-SOURCE; SP-MEMORY";
    }
    part def LifetimeCut {
        attribute erasePublisherCounter : Boolean;
        attribute allFourSitesCovered : Boolean;
        attribute initialCountBeforeEntry : Boolean;
        attribute phaseAndOwnerMatch : Boolean;
        attribute liveBeforeFirstEffect : Boolean;
        attribute notifyLastUseBeforeRelease : Boolean;
        attribute callerResidualBeforeIdle : Boolean;
        attribute noUnknownEscapesRight : Boolean;
        attribute hooksAndExitsAdmitted : Boolean;
        attribute concreteAccessQualified : Boolean;
    }
    requirement def LifetimeContainmentLaw {
        subject cut : LifetimeCut;
        require constraint { not cut.erasePublisherCounter or
            (cut.allFourSitesCovered and cut.initialCountBeforeEntry and cut.phaseAndOwnerMatch and
             cut.liveBeforeFirstEffect and cut.notifyLastUseBeforeRelease and cut.callerResidualBeforeIdle and
             cut.noUnknownEscapesRight and cut.hooksAndExitsAdmitted and cut.concreteAccessQualified) }
    }
    part def FusionCut {
        attribute fusionGranted : Boolean;
        attribute prefixReady : Boolean;
        attribute privateRootCustodianLive : Boolean;
        attribute stableRecordPrepared : Boolean;
        attribute sameGateAndScope : Boolean;
        attribute singleCanonicalAcceptance : Boolean;
        attribute noObservableIntermediateRequired : Boolean;
        attribute bypassCoveragePreserved : Boolean;
        attribute rejectionRestoresPrivateCustody : Boolean;
        attribute noAllocationOrCallbackUnderGate : Boolean;
    }
    requirement def FusionAdmissionLaw {
        subject cut : FusionCut;
        require constraint { not cut.fusionGranted or
            (cut.prefixReady and cut.privateRootCustodianLive and cut.stableRecordPrepared and
             cut.sameGateAndScope and cut.singleCanonicalAcceptance and cut.noObservableIntermediateRequired and
             cut.bypassCoveragePreserved and cut.rejectionRestoresPrivateCustody and
             cut.noAllocationOrCallbackUnderGate) }
    }
    part def LastUseCut {
        attribute producerReleaseGranted : Boolean;
        attribute notificationAndPublisherUsesComplete : Boolean;
        attribute callerCursorAndTailAccounted : Boolean;
        attribute locksAndDescriptorReadersReleased : Boolean;
        attribute allRequiredWorkScannedOrAccepted : Boolean;
        attribute unknownOutcome : Boolean;
        attribute independentCustodianAccepted : Boolean;
        attribute priorRootAndBackingLeaseRetained : Boolean;
    }
    requirement def LastUseReleaseLaw {
        subject cut : LastUseCut;
        require constraint { not cut.producerReleaseGranted or
            (cut.notificationAndPublisherUsesComplete and cut.callerCursorAndTailAccounted and
             cut.locksAndDescriptorReadersReleased and cut.allRequiredWorkScannedOrAccepted and
             (not cut.unknownOutcome or
              (cut.independentCustodianAccepted and cut.priorRootAndBackingLeaseRetained))) }
    }
    part def ExitCut {
        attribute reuseGranted : Boolean;
        attribute unmanagedLockedExit : Boolean;
        attribute processTerminated : Boolean;
        attribute actualCustodyKnown : Boolean;
        attribute completeResumeStateAccepted : Boolean;
        attribute locksReleasedOrQualifiedRecovery : Boolean;
    }
    requirement def ExitAdmissionLaw {
        subject cut : ExitCut;
        require constraint { not cut.reuseGranted or
            (not cut.unmanagedLockedExit and not cut.processTerminated and cut.actualCustodyKnown and
             cut.completeResumeStateAccepted and cut.locksReleasedOrQualifiedRecovery) }
    }
    part def SourceRoute {
        attribute routeId : String;
        attribute sourcePath : String;
        attribute sourceLines : String;
        attribute afterReturn : String;
        attribute idleCut : String;
        attribute qualification : String;
    }
    part route0 : SourceRoute {
        attribute :>> routeId = "MOVABLE-ROLLOVER";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3543-3555;3375-3406";
        attribute :>> afterReturn = "next_heap_msection -> prepare_heap_msection -> reload alloc/limit; copy and local scan still owed";
        attribute :>> idleCut = "only later at mark_reachable_from_marked:6740 after private/local/steal work";
        attribute :>> qualification = "custom_msection_alloc, fatal heap path, allocator locks and all native exits must be admitted";
    }
    part route1 : SourceRoute {
        attribute :>> routeId = "MOVABLE-THRESHOLD";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3598-3625";
        attribute :>> afterReturn = "start_heap_chunk; reload alloc; possible goto again for Tail marking";
        attribute :>> idleCut = "mark_array returns through local/root scan before idle decrement";
        attribute :>> qualification = "publisher return does not discharge Tail or scan-frontier debt";
    }
    part route2 : SourceRoute {
        attribute :>> routeId = "CAPTURED-ROLLOVER";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3696;3742-3752;3804-3810";
        attribute :>> afterReturn = "msection helpers while MISC held; remaining frame copy/links; MISC unlock at outer endpoint";
        attribute :>> idleCut = "outer captured/root or object scan returns before mark_reachable idle";
        attribute :>> qualification = "include existing MISC -> ALLOC order; no G/Q-held allocation and no unmanaged hook escape";
    }
    part route3 : SourceRoute {
        attribute :>> routeId = "CAPTURED-THRESHOLD";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3794-3813";
        attribute :>> afterReturn = "start_heap_chunk; pending ptr/cf and next_frame traversal; final pointer normalization and MISC unlock";
        attribute :>> idleCut = "publication itself has no worker-count decrement";
        attribute :>> qualification = "guard uses alloc_heap_ptr rather than local alloc; QNT site enablement does not prove actual threshold reachability";
    }
    /* Method selection is data, keyed by obligation kind rather than prose keywords. */
    ref part method0 : GambitAssuranceRouting::MethodRule = GambitAssuranceRouting::interleaving;
    ref part method1 : GambitAssuranceRouting::MethodRule = GambitAssuranceRouting::induction;
    ref part method2 : GambitAssuranceRouting::MethodRule = GambitAssuranceRouting::sourceRefinement;
    ref part method3 : GambitAssuranceRouting::MethodRule = GambitAssuranceRouting::nativeMemoryOrder;
    part need0 : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = component;
        attribute :>> obligationId = "SP-HISTORY";
        attribute :>> kind = "interleaving";
        attribute :>> subjectScope = "synchronous_publication:Test$";
        attribute :>> subjectPath = modelSet.quintSource;
        attribute :>> premise = "Positive and fault-controlled last-use/idle/unknown/fusion histories; no native reachability claim";
    }
    part need1 : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = component;
        attribute :>> obligationId = "SP-INDUCTION";
        attribute :>> kind = "induction";
        attribute :>> subjectScope = "GambitSMP.SynchronousPublication:9-local-lemmas";
        attribute :>> subjectPath = modelSet.leanSource;
        attribute :>> premise = "Parametric finite owner/debt cover and issued/unfinished/settled/returned conservation";
    }
    part need2 : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = component;
        attribute :>> obligationId = "SP-SOURCE";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectScope = "gc-synchronous-publication:C-step-simulation";
        attribute :>> subjectPath = modelSet.leanSource;
        attribute :>> premise = "Initial relation and each actual C step refines a QNT step or justified stutter; progress and complete writer/hook domain";
    }
    part need3 : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = component;
        attribute :>> obligationId = "SP-MEMORY";
        attribute :>> kind = "native-memory-order";
        attribute :>> subjectScope = "gc-synchronous-publication:C-happens-before";
        attribute :>> subjectPath = route0.sourcePath;
        attribute :>> premise = "Actual compiler and synchronization access paths; C happens-before, OS errors and lifetime";
    }
    part dependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = need2;
        ref part :>> prerequisite = need0;
    }
    part dependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = need2;
        ref part :>> prerequisite = need1;
    }
    part dependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = need2;
        ref part :>> prerequisite = need3;
    }
    part def AssuranceGraph {
        ref part targetComponent : GambitAssuranceRelations::ComponentModelUse = component;
        ref part formalModels : GambitAssuranceRelations::FormalModelSet = modelSet;
        ref part containment : LifetimeCut;
        ref part fusion : FusionCut;
        ref part lastUse : LastUseCut;
        ref part exits : ExitCut;
        ref part histories : GambitAssuranceRouting::ModelNeed = need0;
        ref part induction : GambitAssuranceRouting::ModelNeed = need1;
        ref part sourceRefinement : GambitAssuranceRouting::ModelNeed = need2;
        ref part memoryOrder : GambitAssuranceRouting::ModelNeed = need3;
        connection needsOwnedModels connect targetComponent to formalModels;
        connection lifetime connect targetComponent to containment;
        connection equivalentFusion connect targetComponent to fusion;
        connection finalUse connect containment to lastUse;
        connection admittedExit connect lastUse to exits;
        connection qntSelection connect formalModels to histories;
        connection leanSelection connect formalModels to induction;
        connection nativeSimulation connect targetComponent to sourceRefinement;
        connection concreteMemory connect targetComponent to memoryOrder;
    }
    part graph : AssuranceGraph;
    dependency containmentNeedsSourceLaw from LifetimeContainmentLaw to GambitPublicationClose::SupportErasureLaw;
    dependency lastUseNeedsCustody from LastUseReleaseLaw to GambitPublicationClose::UnknownCustodyLaw;
    dependency fusionNeedsReservation from FusionAdmissionLaw to GambitPublicationClose::ReservationLaw;
    dependency fusionNeedsCommit from FusionAdmissionLaw to GambitPublicationClose::PublishCommitLaw;
}
