/* Shared runtime architecture RESEARCH DRAFT, 2026-10-20.
 * No parser, resolver, interpreter, solver, compiler or native test was run.
 * Logical snapshots and necessary conditions, not executable runtime operations.
 * Publication/coverage/host-knowledge inputs still need source and memory-model
 * refinement. Part composition is modeling structure, not C/Zig ownership proof.
 */
package GambitSharedRuntime {
    private import ScalarValues::*;

    enum def ContextMode {
        OwnedActive; Publishing; ParkedNative; ReentryPending;
        Retiring; RetainedAfterFailure; Reclaimed;
    }
    enum def EpochPhase {
        Idle; Requested; Frozen; Scanning; Relocating; Completed; Failed;
    }
    enum def CarrierState { Private; Published; Closing; Drained; Reclaimed; }
    enum def RequestKind { Collect; Resize; IoCapacity; Interrupt; Noop; }
    enum def ResourceKind {
        VmDomain; ContextStorage; CarrierStorage; ImageStorage;
        TicketStorage; NativeSessionStorage;
    }
    enum def OperationKind {
        RT01; RT02; RT03; RT04; RT05; RT06; RT07; RT08; RT09;
        RT10; RT11; RT12; RT13; RT14; RT15; RT16; RT17; RT18;
        RT19; RT20; RT21; RT22; RT23; RT24; RT25; RT26;
    }
    enum def ProtocolEvent {
        RequestAdmitted; ContributorAcknowledged; RootCutSealed;
        ScanGranted; CollectionCompleted; ResumeGranted; ResourceWithdrawn;
    }

    part def VmRecord {
        attribute vmId : Integer;
        attribute generation : Integer;
        attribute admissionOpen : Boolean;
        attribute phase : EpochPhase;
        attribute requestEpoch : Integer;
        attribute completedRelocationEpoch : Integer;
    }
    part def ContextRecord {
        attribute contextId : Integer;
        attribute vmId : Integer;
        attribute mode : ContextMode;
        attribute executionOwned : Boolean;
        attribute noManagedAliasesOrMutation : Boolean;
        attribute gcWorkerBorrowersDrained : Boolean;
        attribute loadedRelocationEpoch : Integer;
        attribute requestReconciled : Boolean;
        attribute allRequiredValuesReloaded : Boolean;
        attribute oldAliasesInvalidated : Boolean;
        attribute currentMemberAcknowledged : Boolean;
        attribute noExecutionUsers : Boolean;
        attribute noUnknownHostUsers : Boolean;
    }
    part def RootCarrierRecord {
        attribute carrierId : Integer;
        attribute vmId : Integer;
        attribute generation : Integer;
        attribute state : CarrierState;
        attribute initializedPublication : Boolean;
        attribute scannerCustodianLive : Boolean;
        attribute supportedRootKind : Boolean;
        attribute noScannerUsers : Boolean;
    }
    part def HandleRecord {
        attribute vmId : Integer;
        attribute carrierId : Integer;
        attribute carrierGeneration : Integer;
        attribute directoryLeaseLive : Boolean;
        attribute rootOperationAuthorized : Boolean;
    }
    part def TicketRecord {
        attribute epoch : Integer;
        attribute kind : RequestKind;
        attribute allRequiredMembersAcknowledged : Boolean;
        attribute contributorCoverageEstablished : Boolean;
        attribute contributorDescriptorsStable : Boolean;
        attribute rootCutSealed : Boolean;
        attribute noUnknownRelevantMutators : Boolean;
        attribute stableLocationLawEstablished : Boolean;
        attribute exactLocationCoverageEstablished : Boolean;
        attribute workerTeamSealed : Boolean;
        attribute sufficientWorkersLive : Boolean;
        attribute relocationWritersDrained : Boolean;
        attribute terminalResultKnown : Boolean;
        attribute successful : Boolean;
    }
    part def InvocationRecord {
        attribute invocationId : Integer;
        attribute parentId : Integer;
        attribute originLive : Boolean;
        attribute matchingBindingRestored : Boolean;
        attribute resultCustodyTransferred : Boolean;
    }
    part def ImageRecord {
        attribute imageId : Integer;
        attribute entryClosed : Boolean;
        attribute codeAndMapsLive : Boolean;
        attribute noContinuationOrMapUsers : Boolean;
        attribute noNativeReturnUsers : Boolean;
    }
    part def SessionRecord {
        attribute requestIdentity : String;
        attribute productIdentity : String;
        attribute profileIdentityMatches : Boolean;
        attribute ownedBytesValidated : Boolean;
        attribute executorTerminalResultKnown : Boolean;
    }
    part def BoundarySnapshot {
        part vm : VmRecord;
        part context : ContextRecord;
        part carrier : RootCarrierRecord;
        part handle : HandleRecord;
        part ticket : TicketRecord;
        part invocation : InvocationRecord;
        part image : ImageRecord;
        part session : SessionRecord;
        attribute metadataGateOwned : Boolean;
        attribute vmLeaseLive : Boolean;
        attribute entryClosed : Boolean;
        attribute resumePermitted : Boolean;
        attribute handleResolutionAccepted : Boolean;
        attribute reclaimed : Boolean;
        attribute targetResourceId : Integer;
        attribute reclaimedTargetId : Integer;
        attribute targetKind : ResourceKind;
        attribute targetAdmissionClosed : Boolean;
        attribute targetDependencyClosureEstablished : Boolean;
        attribute noRemainingTargetUsers : Boolean;
        attribute noLateTargetIssuers : Boolean;
        attribute noUnknownTargetUsers : Boolean;
    }
    part def BoundaryTransition {
        attribute operation : OperationKind;
        attribute event : ProtocolEvent;
        part before : BoundarySnapshot;
        part after : BoundarySnapshot;
    }

    requirement def VmCarrierIdentityLaw {
        subject snapshot : BoundarySnapshot;
        require constraint {
            snapshot.vmLeaseLive and
            snapshot.vm.vmId == snapshot.context.vmId and
            snapshot.vm.vmId == snapshot.carrier.vmId
        }
    }
    requirement def ParkCommitLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT08 or
            (step.before.metadataGateOwned and step.before.vmLeaseLive and
             step.before.context.mode == ContextMode::Publishing and
             step.before.context.executionOwned and
             (step.before.vm.phase == EpochPhase::Idle or
              step.before.vm.phase == EpochPhase::Completed) and
             step.before.carrier.initializedPublication and
             step.before.carrier.scannerCustodianLive and
             step.before.context.noManagedAliasesOrMutation and
             step.before.context.gcWorkerBorrowersDrained and
             step.after.context.mode == ContextMode::ParkedNative and
             not step.after.context.executionOwned and
             step.after.carrier.state == CarrierState::Published and
             step.after.vm.requestEpoch == step.before.vm.requestEpoch)
        }
    }
    requirement def CollectionRequestLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT09 or
            step.after.ticket.kind != RequestKind::Collect or
            (step.before.metadataGateOwned and
             step.after.ticket.epoch == step.before.vm.requestEpoch + 1 and
             step.after.vm.requestEpoch == step.after.ticket.epoch and
             step.after.vm.phase == EpochPhase::Requested and
             step.after.ticket.workerTeamSealed and
             step.after.ticket.sufficientWorkersLive and
             step.after.ticket.contributorCoverageEstablished and
             not step.after.ticket.rootCutSealed)
        }
    }
    requirement def RootCutClosureLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.event != ProtocolEvent::RootCutSealed or
            (step.before.metadataGateOwned and
             step.before.vm.phase == EpochPhase::Requested and
             step.before.ticket.allRequiredMembersAcknowledged and
             step.before.ticket.contributorCoverageEstablished and
             step.before.ticket.contributorDescriptorsStable and
             step.before.ticket.noUnknownRelevantMutators and
             step.after.ticket.stableLocationLawEstablished and
             step.after.ticket.rootCutSealed and
             step.after.ticket.exactLocationCoverageEstablished and
             step.after.ticket.epoch == step.before.vm.requestEpoch and
             step.after.vm.phase == EpochPhase::Frozen)
        }
    }
    requirement def ScanGrantLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT11 or
            ((step.before.vm.phase == EpochPhase::Frozen or
              step.before.vm.phase == EpochPhase::Scanning) and
             step.before.ticket.epoch == step.before.vm.requestEpoch and
             step.before.ticket.allRequiredMembersAcknowledged and
             step.before.ticket.rootCutSealed and
             step.before.ticket.contributorCoverageEstablished and
             step.before.ticket.noUnknownRelevantMutators and
             step.before.ticket.stableLocationLawEstablished and
             step.before.ticket.exactLocationCoverageEstablished and
             step.before.ticket.workerTeamSealed and
             step.before.context.noUnknownHostUsers and
             step.before.carrier.supportedRootKind and
             step.before.carrier.initializedPublication and
             step.before.carrier.scannerCustodianLive)
        }
    }
    requirement def SuccessfulCollectionCompletionLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT13 or
            step.before.ticket.kind != RequestKind::Collect or
            not step.after.ticket.successful or
            (step.before.metadataGateOwned and
             step.before.ticket.relocationWritersDrained and
             step.before.ticket.terminalResultKnown and
             step.after.vm.phase == EpochPhase::Completed and
             step.after.vm.completedRelocationEpoch == step.before.ticket.epoch)
        }
    }
    requirement def ReentryGrantLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT15 or
            not step.after.resumePermitted or
            (step.after.vmLeaseLive and step.after.context.executionOwned and
             (step.after.vm.phase == EpochPhase::Idle or
              step.after.vm.phase == EpochPhase::Completed) and
             step.after.context.requestReconciled and
             step.after.context.allRequiredValuesReloaded and
             step.after.context.oldAliasesInvalidated and
             step.after.context.mode == ContextMode::OwnedActive and
             step.after.invocation.originLive and step.after.image.codeAndMapsLive and
             step.after.context.loadedRelocationEpoch ==
                 step.after.vm.completedRelocationEpoch)
        }
    }
    requirement def HandleResolutionLaw {
        subject snapshot : BoundarySnapshot;
        require constraint {
            not snapshot.handleResolutionAccepted or
            (snapshot.vmLeaseLive and snapshot.handle.directoryLeaseLive and
            snapshot.handle.rootOperationAuthorized and
            snapshot.handle.vmId == snapshot.vm.vmId and
            snapshot.handle.carrierId == snapshot.carrier.carrierId and
            snapshot.handle.carrierGeneration == snapshot.carrier.generation)
        }
    }
    requirement def InvocationDeliveryLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT16 or
            (step.after.invocation.matchingBindingRestored and
             step.after.invocation.resultCustodyTransferred)
        }
    }
    requirement def FinalUseLaw {
        subject snapshot : BoundarySnapshot;
        require constraint {
            not snapshot.reclaimed or
            (snapshot.reclaimedTargetId == snapshot.targetResourceId and
             snapshot.targetAdmissionClosed and
             snapshot.targetDependencyClosureEstablished and
             snapshot.noRemainingTargetUsers and
             snapshot.noLateTargetIssuers and
             snapshot.noUnknownTargetUsers)
        }
    }
    requirement def NativeProductAdmissionLaw {
        subject snapshot : BoundarySnapshot;
        require constraint {
            snapshot.session.profileIdentityMatches and
            snapshot.session.ownedBytesValidated and
            snapshot.session.executorTerminalResultKnown
        }
    }

    /* Requirements are proposed predicates over logical snapshots, not asserted
     * satisfaction. No concrete instance/defaults or fake true certificates.
     * The phase transitions, all operation outcomes, exact set coverage, epoch
     * progress/fairness, proof of host nonmutation, C/Zig atomics, root profiles,
     * descriptor semantics and multi-shot control refinement remain unmodeled.
     * Target users are indexed by the resource being reclaimed, not all VM users.
     * Request enrollment precedes final descriptor/root-cut closure. The latter
     * needs stable root entries or a separate frame relocation/accessor law.
     * Boolean names expose those obligations; they do not discharge them.
     */
}
