/* T0 target contracts. Native structural checking only; no behavior,
 * satisfied instance, C memory-order refinement or implemented runtime layout. */
package GambitRuntimeRoles {
    private import ScalarValues::*;

    enum def ParticipantKind { ContextRoots; VmRoots; ForeignRoots; }
    enum def ParticipantMode { Registered; Freezing; Acknowledged; Scanning; Released; Retained; }
    part def EpochParticipant {
        ref part vm : GambitSharedRuntime::VmRecord;
        ref part carrier : GambitSharedRuntime::RootCarrierRecord;
        attribute participantId : Integer;
        attribute incarnation : Integer;
        attribute vmGeneration : Integer;
        attribute carrierGeneration : Integer;
        attribute acknowledgedIncarnation : Integer;
        attribute kind : ParticipantKind;
        attribute mode : ParticipantMode;
        attribute membershipGeneration : Integer;
        attribute admittedMembershipGeneration : Integer;
        attribute membershipOpen : Boolean;
        attribute admitted : Boolean;
        attribute requestEpoch : Integer;
        attribute rootCutEpoch : Integer;
        attribute acknowledgedEpoch : Integer;
        attribute originContextId : Integer;
        attribute originContextGeneration : Integer;
        attribute writerSetComplete : Boolean;
        attribute rootLocationsComplete : Boolean;
        attribute mutationExcluded : Boolean;
        attribute finalValueVersion : Integer;
        attribute acknowledgedValueVersion : Integer;
        attribute publicationEstablished : Boolean;
        attribute acknowledgementPublished : Boolean;
        attribute removalRequested : Boolean;
        attribute removalIngressClosed : Boolean;
        attribute requiredEpochSettled : Boolean;
        attribute replacementMembershipCommitted : Boolean;
        attribute replacementRootCustodianLive : Boolean;
        attribute scannerUsersDrained : Boolean;
        attribute descriptorReadersDrained : Boolean;
    }
    requirement def ParticipantAcknowledgementLaw {
        subject p : EpochParticipant;
        require constraint { not p.acknowledgementPublished or
            (p.admitted and p.carrier.vmId == p.vm.vmId and p.vmGeneration == p.vm.generation and
             p.carrierGeneration == p.carrier.generation and p.acknowledgedIncarnation == p.incarnation and
             p.membershipGeneration == p.admittedMembershipGeneration and
             p.requestEpoch == p.vm.requestEpoch and p.acknowledgedEpoch == p.requestEpoch and
             p.writerSetComplete and p.rootLocationsComplete and p.mutationExcluded and
             p.finalValueVersion == p.acknowledgedValueVersion and p.publicationEstablished and
             p.carrier.initializedPublication and p.carrier.supportedRootKind and p.carrier.scannerCustodianLive) }
    }
    requirement def ParticipantRemovalLaw {
        subject p : EpochParticipant;
        require constraint { not p.removalRequested or
            (not p.membershipOpen and p.removalIngressClosed and p.scannerUsersDrained and
             p.descriptorReadersDrained and p.carrier.noScannerUsers and
             (p.requiredEpochSettled or
              (p.replacementMembershipCommitted and p.replacementRootCustodianLive))) }
    }
    part def RoleHandoff {
        ref part execution : GambitRuntime::ExecutionGrant;
        ref part participant : EpochParticipant;
        ref part work : GambitGc::CollectorWorkContext;
        attribute scanGranted : Boolean;
        attribute scannerAcquireEstablished : Boolean;
        attribute membershipCutSealed : Boolean;
        attribute resumeGranted : Boolean;
        attribute commonResultAccepted : Boolean;
        attribute terminalResultKnown : Boolean;
        attribute relocationCommitted : Boolean;
        attribute capacitySatisfied : Boolean;
        attribute resultEpoch : Integer;
        attribute relocationWritersDrained : Boolean;
        attribute scanUsersDrained : Boolean;
    }
    requirement def RoleScanHandoffLaw {
        subject cut : RoleHandoff;
        require constraint { not cut.scanGranted or
            (cut.membershipCutSealed and cut.participant.acknowledgementPublished and cut.participant.admitted and
             cut.participant.writerSetComplete and cut.participant.rootLocationsComplete and
             cut.participant.mutationExcluded and cut.participant.publicationEstablished and
             cut.participant.carrier.initializedPublication and cut.participant.carrier.supportedRootKind and cut.participant.carrier.scannerCustodianLive and
             cut.participant.carrier.vmId == cut.participant.vm.vmId and
             cut.participant.vmGeneration == cut.participant.vm.generation and
             cut.participant.carrierGeneration == cut.participant.carrier.generation and
             cut.participant.acknowledgedIncarnation == cut.participant.incarnation and
             cut.participant.membershipGeneration == cut.participant.admittedMembershipGeneration and
             cut.participant.finalValueVersion == cut.participant.acknowledgedValueVersion and
             cut.participant.requestEpoch == cut.participant.vm.requestEpoch and
             cut.participant.acknowledgedEpoch == cut.participant.requestEpoch and
             cut.work.vm.vmId == cut.participant.vm.vmId and
             cut.work.vm.generation == cut.participant.vm.generation and
             cut.work.workEpoch == cut.participant.requestEpoch and cut.work.taskGrantLive and
             cut.work.phaseScope.collection.rootCutEpoch == cut.participant.rootCutEpoch and
             cut.work.phaseScope.phase == cut.work.coordinatorScope.phase and
             cut.work.phaseScope.round == cut.work.coordinatorScope.round and
             cut.work.teamGrantLive and cut.work.descriptorLeaseLive and cut.scannerAcquireEstablished and
             cut.work.phaseScope.collection.vmId == cut.work.vm.vmId and
             cut.work.phaseScope.collection.vmGeneration == cut.work.vm.generation and
             cut.work.phaseScope.collection.collectionEpoch == cut.work.workEpoch and
             cut.work.phaseScope.workerTeam.resourceId == cut.work.teamId and
             cut.work.phaseScope.workerTeam.resourceGeneration == cut.work.teamGeneration and
             (cut.participant.kind != ParticipantKind::ContextRoots or
              (cut.execution.identity.vm.vmId == cut.participant.vm.vmId and
               cut.execution.identity.vmGeneration == cut.participant.vm.generation and
               cut.participant.originContextId == cut.execution.identity.contextRecord.contextId and
               cut.participant.originContextGeneration == cut.execution.identity.contextGeneration and
               not cut.execution.live and not cut.execution.identity.contextRecord.executionOwned))) }
    }
    requirement def RoleResumeLaw {
        subject cut : RoleHandoff;
        require constraint { not cut.resumeGranted or
            (cut.commonResultAccepted and cut.terminalResultKnown and cut.relocationCommitted and cut.relocationWritersDrained and
             cut.scanUsersDrained and cut.resultEpoch == cut.participant.requestEpoch and
             cut.resultEpoch == cut.execution.identity.vm.requestEpoch and
             cut.resultEpoch == cut.execution.identity.vm.completedRelocationEpoch and
             cut.execution.identity.vm.vmId == cut.participant.vm.vmId and
             cut.execution.identity.vmGeneration == cut.participant.vm.generation and
             cut.participant.kind == ParticipantKind::ContextRoots and
             cut.participant.originContextId == cut.execution.identity.contextRecord.contextId and
             cut.participant.originContextGeneration == cut.execution.identity.contextGeneration and
             cut.execution.live and cut.execution.pendingRequestReconciled and
             cut.execution.identity.contextRecord.executionOwned and cut.execution.identity.contextRecord.requestReconciled and
             cut.execution.identity.contextRecord.allRequiredValuesReloaded and cut.execution.identity.contextRecord.oldAliasesInvalidated and
             cut.execution.identity.contextRecord.loadedRelocationEpoch == cut.resultEpoch) }
    }
    /* No membership/worker/context cardinality equality is assumed. This graph
     * is a shared-contract boundary, not an execution sequence. */
    part def RoleContractGraph {
        ref part execution : GambitRuntime::ExecutionGrant;
        ref part participant : EpochParticipant;
        ref part work : GambitGc::CollectorWorkContext;
        ref part handoff : RoleHandoff;
        ref part rootHandoff : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.rootHandoff;
        ref part controlOrigin : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.controlOrigin;
        ref part retirement : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.retirementWindow;
        ref part workClosure : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.workClosure;
        connection finalRootCustody connect execution to participant;
        connection epochScanGrant connect participant to work;
        connection reloadAndResume connect work to execution;
        connection executionProtocol connect handoff to execution;
        connection participantProtocol connect handoff to participant;
        connection collectorProtocol connect handoff to work;
        connection scanAgreement connect handoff to rootHandoff;
        connection continuationOrigins connect handoff to controlOrigin;
        connection finalUseDrain connect handoff to retirement;
        connection completeWorkCustody connect handoff to workClosure;
    }
    part formalBridge : RoleContractGraph;
    dependency scanNeedsHandoff from RoleScanHandoffLaw to GambitRuntimeModelRelations::relations::rootHandoff;
    dependency resumeNeedsOrigins from RoleResumeLaw to GambitRuntimeModelRelations::relations::controlOrigin;
    dependency removalNeedsRetirement from ParticipantRemovalLaw to GambitRuntimeModelRelations::relations::retirementWindow;
    dependency workerNeedsWorkClosure from GambitGc::WorkCustodyReleaseLaw to GambitRuntimeModelRelations::relations::workClosure;
}
