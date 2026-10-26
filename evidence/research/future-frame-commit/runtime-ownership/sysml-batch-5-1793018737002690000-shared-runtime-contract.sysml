/* Maintained Org-linked copy. The original draft header below records historical
 * validation status; current strict-diagnostic status is in dev/research/validation.org.
 * No model behavior, solver, Gambit compiler or native test has been executed. */
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
        attribute carrierState : CarrierState;
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
        attribute protocolEvent : ProtocolEvent;
        part preState : BoundarySnapshot;
        part postState : BoundarySnapshot;
    }

    requirement def VmCarrierIdentityLaw {
        subject subjectSnapshot : BoundarySnapshot;
        require constraint {
            subjectSnapshot.vmLeaseLive and
            subjectSnapshot.vm.vmId == subjectSnapshot.context.vmId and
            subjectSnapshot.vm.vmId == subjectSnapshot.carrier.vmId
        }
    }
    requirement def ParkCommitLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT08 or
            (step.preState.metadataGateOwned and step.preState.vmLeaseLive and
             step.preState.context.mode == ContextMode::Publishing and
             step.preState.context.executionOwned and
             (step.preState.vm.phase == EpochPhase::Idle or
              step.preState.vm.phase == EpochPhase::Completed) and
             step.preState.carrier.initializedPublication and
             step.preState.carrier.scannerCustodianLive and
             step.preState.context.noManagedAliasesOrMutation and
             step.preState.context.gcWorkerBorrowersDrained and
             step.postState.context.mode == ContextMode::ParkedNative and
             not step.postState.context.executionOwned and
             step.postState.carrier.carrierState == CarrierState::Published and
             step.postState.vm.requestEpoch == step.preState.vm.requestEpoch)
        }
    }
    requirement def CollectionRequestLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT09 or
            step.postState.ticket.kind != RequestKind::Collect or
            (step.preState.metadataGateOwned and
             step.postState.ticket.epoch == step.preState.vm.requestEpoch + 1 and
             step.postState.vm.requestEpoch == step.postState.ticket.epoch and
             step.postState.vm.phase == EpochPhase::Requested and
             step.postState.ticket.workerTeamSealed and
             step.postState.ticket.sufficientWorkersLive and
             step.postState.ticket.contributorCoverageEstablished and
             not step.postState.ticket.rootCutSealed)
        }
    }
    requirement def RootCutClosureLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.protocolEvent != ProtocolEvent::RootCutSealed or
            (step.preState.metadataGateOwned and
             step.preState.vm.phase == EpochPhase::Requested and
             step.preState.ticket.allRequiredMembersAcknowledged and
             step.preState.ticket.contributorCoverageEstablished and
             step.preState.ticket.contributorDescriptorsStable and
             step.preState.ticket.noUnknownRelevantMutators and
             step.postState.ticket.stableLocationLawEstablished and
             step.postState.ticket.rootCutSealed and
             step.postState.ticket.exactLocationCoverageEstablished and
             step.postState.ticket.epoch == step.preState.vm.requestEpoch and
             step.postState.vm.phase == EpochPhase::Frozen)
        }
    }
    requirement def ScanGrantLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT11 or
            ((step.preState.vm.phase == EpochPhase::Frozen or
              step.preState.vm.phase == EpochPhase::Scanning) and
             step.preState.ticket.epoch == step.preState.vm.requestEpoch and
             step.preState.ticket.allRequiredMembersAcknowledged and
             step.preState.ticket.rootCutSealed and
             step.preState.ticket.contributorCoverageEstablished and
             step.preState.ticket.noUnknownRelevantMutators and
             step.preState.ticket.stableLocationLawEstablished and
             step.preState.ticket.exactLocationCoverageEstablished and
             step.preState.ticket.workerTeamSealed and
             step.preState.context.noUnknownHostUsers and
             step.preState.carrier.supportedRootKind and
             step.preState.carrier.initializedPublication and
             step.preState.carrier.scannerCustodianLive)
        }
    }
    requirement def SuccessfulCollectionCompletionLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT13 or
            step.preState.ticket.kind != RequestKind::Collect or
            not step.postState.ticket.successful or
            (step.preState.metadataGateOwned and
             step.preState.ticket.relocationWritersDrained and
             step.preState.ticket.terminalResultKnown and
             step.postState.vm.phase == EpochPhase::Completed and
             step.postState.vm.completedRelocationEpoch == step.preState.ticket.epoch)
        }
    }
    requirement def ReentryGrantLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT15 or
            not step.postState.resumePermitted or
            (step.postState.vmLeaseLive and step.postState.context.executionOwned and
             (step.postState.vm.phase == EpochPhase::Idle or
              step.postState.vm.phase == EpochPhase::Completed) and
             step.postState.context.requestReconciled and
             step.postState.context.allRequiredValuesReloaded and
             step.postState.context.oldAliasesInvalidated and
             step.postState.context.mode == ContextMode::OwnedActive and
             step.postState.invocation.originLive and step.postState.image.codeAndMapsLive and
             step.postState.context.loadedRelocationEpoch ==
                 step.postState.vm.completedRelocationEpoch)
        }
    }
    requirement def HandleResolutionLaw {
        subject subjectSnapshot : BoundarySnapshot;
        require constraint {
            not subjectSnapshot.handleResolutionAccepted or
            (subjectSnapshot.vmLeaseLive and subjectSnapshot.handle.directoryLeaseLive and
            subjectSnapshot.handle.rootOperationAuthorized and
            subjectSnapshot.handle.vmId == subjectSnapshot.vm.vmId and
            subjectSnapshot.handle.carrierId == subjectSnapshot.carrier.carrierId and
            subjectSnapshot.handle.carrierGeneration == subjectSnapshot.carrier.generation)
        }
    }
    requirement def InvocationDeliveryLaw {
        subject step : BoundaryTransition;
        require constraint {
            step.operation != OperationKind::RT16 or
            (step.postState.invocation.matchingBindingRestored and
             step.postState.invocation.resultCustodyTransferred)
        }
    }
    requirement def FinalUseLaw {
        subject subjectSnapshot : BoundarySnapshot;
        require constraint {
            not subjectSnapshot.reclaimed or
            (subjectSnapshot.reclaimedTargetId == subjectSnapshot.targetResourceId and
             subjectSnapshot.targetAdmissionClosed and
             subjectSnapshot.targetDependencyClosureEstablished and
             subjectSnapshot.noRemainingTargetUsers and
             subjectSnapshot.noLateTargetIssuers and
             subjectSnapshot.noUnknownTargetUsers)
        }
    }
    requirement def NativeProductAdmissionLaw {
        subject subjectSnapshot : BoundarySnapshot;
        require constraint {
            subjectSnapshot.session.profileIdentityMatches and
            subjectSnapshot.session.ownedBytesValidated and
            subjectSnapshot.session.executorTerminalResultKnown
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
