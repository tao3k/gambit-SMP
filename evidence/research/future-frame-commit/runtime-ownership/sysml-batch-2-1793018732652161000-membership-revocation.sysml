/* T0 modern-C target. Necessary predicates only: no behavior, satisfaction,
 * implemented registry, native atomic mapping, or new formal execution. */
package GambitMembershipRevocation {
    private import ScalarValues::*;

    part def MembershipCut {
        ref part collection : GambitRuntimeInterfaces::CollectionScope;
        attribute membershipGeneration : Integer;
        attribute frozenGeneration : Integer;
        attribute censusComplete : Boolean;
        attribute enrollmentClosed : Boolean;
        attribute freezeSerializedWithEnrollment : Boolean;
        attribute pendingEnrollments : Integer;
        attribute membershipFrozen : Boolean;
        attribute memberIncarnationsStable : Boolean;
        attribute requiredAcknowledgementsComplete : Boolean;
        attribute finalRootValuesPublished : Boolean;
        attribute writersExcluded : Boolean;
        attribute rootSetSealed : Boolean;
    }
    requirement def MemberFreezeLaw {
        subject cut : MembershipCut;
        require constraint { cut.pendingEnrollments >= 0 and
            (not cut.membershipFrozen or
             (cut.censusComplete and cut.enrollmentClosed and cut.freezeSerializedWithEnrollment and
              cut.pendingEnrollments == 0 and cut.membershipGeneration == cut.frozenGeneration and
              cut.memberIncarnationsStable)) }
    }
    requirement def RootSealLaw {
        subject cut : MembershipCut;
        require constraint { not cut.rootSetSealed or
            (cut.membershipFrozen and cut.requiredAcknowledgementsComplete and
             cut.finalRootValuesPublished and cut.writersExcluded) }
    }
    /* closure.scope is the immutable authority for this revocation, not a
     * second copied phase selector. Native coherent access remains an obligation.
     * New acquisition is closed before existing custody/drain leases expire. */
    part def PhaseRevocation {
        ref part closure : GambitCollectionCompletion::ProducerClosure;
        attribute announcementPublished : Boolean;
        attribute newAcquisitionClosed : Boolean;
        attribute closeSerializedWithAcquisition : Boolean;
        attribute outstandingCustodians : Integer;
        attribute drainRightsPreserved : Boolean;
        attribute publicationUsers : Integer;
        attribute descriptorReaders : Integer;
        attribute unknownTransfers : Integer;
        attribute effectivePublished : Boolean;
    }
    requirement def RevocationAnnouncementLaw {
        subject cut : PhaseRevocation;
        require constraint {
            cut.outstandingCustodians >= 0 and cut.publicationUsers >= 0 and
            cut.descriptorReaders >= 0 and cut.unknownTransfers >= 0 and
            (not cut.announcementPublished or
             (cut.newAcquisitionClosed and cut.closeSerializedWithAcquisition and
              (cut.outstandingCustodians == 0 or cut.drainRightsPreserved))) }
    }
    /* Must be conjoined with the existing PhaseDrainAdmissionLaw,
     * CreditDomainLaw and PhaseDrainStabilityLaw, not interpreted in isolation. */
    requirement def RevocationEffectiveLaw {
        subject cut : PhaseRevocation;
        require constraint { not cut.effectivePublished or
            (cut.announcementPublished and cut.newAcquisitionClosed and
             cut.closeSerializedWithAcquisition and cut.closure.phaseDrainPublished and
             cut.outstandingCustodians == 0 and cut.publicationUsers == 0 and
             cut.descriptorReaders == 0 and cut.unknownTransfers == 0) }
    }
    /* A worker may leave before the whole phase drains, but may not discard
     * private cursors, incomplete copies, Tail debt or an acquired chunk. */
    part def WorkerWithdrawal {
        ref part work : GambitGc::CollectorWorkContext;
        attribute newAcquisitionClosed : Boolean;
        attribute closeSerializedWithAcquisition : Boolean;
        attribute publicationUsersDrained : Boolean;
        attribute descriptorReadersDrained : Boolean;
        attribute releaseReceiptKnown : Boolean;
        attribute effectivePublished : Boolean;
    }
    requirement def WorkerWithdrawalLaw {
        subject cut : WorkerWithdrawal;
        require constraint { not cut.effectivePublished or
            (cut.newAcquisitionClosed and cut.closeSerializedWithAcquisition and
             cut.publicationUsersDrained and cut.descriptorReadersDrained and cut.releaseReceiptKnown and
             cut.work.releaseRequested and not cut.work.outcomeUnknown and
             ((not cut.work.taskGrantLive and cut.work.copyInitializationDebt == 0 and
               cut.work.privateCursorDebt == 0 and cut.work.tailDebt == 0 and cut.work.dequeuedChunkDebt == 0) or
              (cut.work.transferAccepted and cut.work.receiverCustodianLive and
               cut.work.completeRestoreStateTransferred and cut.work.phaseDebtTransferred))) }
    }
    part def LateDelivery {
        ref part revocation : PhaseRevocation;
        ref part work : GambitGc::CollectorWorkContext;
        ref part priorCustody : GambitCollectionCompletion::LateWorkCustody;
        attribute acceptedBeforeCut : Boolean;
        attribute derivedFromAdmittedParent : Boolean;
        attribute childReservedBeforeParentRelease : Boolean;
        attribute acceptanceCreditCommitted : Boolean;
        attribute payloadPublicationAcquired : Boolean;
        attribute samePhaseAccepted : Boolean;
        attribute effectUnknown : Boolean;
        attribute sourceOrTransferCustodianLive : Boolean;
        attribute stablePriorLease : Boolean;
        attribute debtRetained : Boolean;
        attribute rejectedPendingDisposition : Boolean;
        attribute sourceReleased : Boolean;
    }
    requirement def LateDeliveryLaw {
        subject delivery : LateDelivery;
        require constraint {
            delivery.samePhaseAccepted == delivery.priorCustody.samePhaseAccepted and
            (not delivery.samePhaseAccepted or
             (not delivery.revocation.effectivePublished and delivery.work.taskGrantLive and
              delivery.work.teamGrantLive and delivery.work.descriptorLeaseLive and
              delivery.work.phaseScope.collection.vmId == delivery.revocation.closure.scope.collection.vmId and
              delivery.work.phaseScope.collection.vmGeneration == delivery.revocation.closure.scope.collection.vmGeneration and
              delivery.work.phaseScope.collection.collectionEpoch == delivery.revocation.closure.scope.collection.collectionEpoch and
              delivery.work.phaseScope.collection.rootCutEpoch == delivery.revocation.closure.scope.collection.rootCutEpoch and
              delivery.work.phaseScope.phase == delivery.revocation.closure.scope.phase and
              delivery.work.phaseScope.round == delivery.revocation.closure.scope.round and
              delivery.work.phaseScope.producerGeneration == delivery.revocation.closure.scope.producerGeneration and
              delivery.work.phaseScope.workerTeam.resourceId == delivery.revocation.closure.scope.workerTeam.resourceId and
              delivery.work.phaseScope.workerTeam.resourceGeneration == delivery.revocation.closure.scope.workerTeam.resourceGeneration and
              (not delivery.revocation.newAcquisitionClosed or delivery.acceptedBeforeCut or
               (delivery.derivedFromAdmittedParent and delivery.childReservedBeforeParentRelease and
                delivery.revocation.drainRightsPreserved)) and
              delivery.acceptanceCreditCommitted and delivery.payloadPublicationAcquired)) and
            (not delivery.effectUnknown or
             (delivery.sourceOrTransferCustodianLive and delivery.stablePriorLease and
              delivery.debtRetained and not delivery.sourceReleased)) and
            (not delivery.rejectedPendingDisposition or
             (delivery.sourceOrTransferCustodianLive and delivery.stablePriorLease and
              delivery.debtRetained and not delivery.sourceReleased)) }
    }
    part def PhaseAdvance {
        ref part oldCut : PhaseRevocation;
        ref part successor : GambitCollectionCompletion::PhaseScope;
        attribute successorPublished : Boolean;
    }
    requirement def PhaseAdvanceLaw {
        subject step : PhaseAdvance;
        require constraint { not step.successorPublished or
            (step.oldCut.effectivePublished and
             step.oldCut.closure.scope.collection.vmId == step.successor.collection.vmId and
             step.oldCut.closure.scope.collection.vmGeneration == step.successor.collection.vmGeneration and
             step.oldCut.closure.scope.collection.collectionEpoch == step.successor.collection.collectionEpoch and
             step.oldCut.closure.scope.collection.rootCutEpoch == step.successor.collection.rootCutEpoch and
             step.successor.producerGeneration > step.oldCut.closure.scope.producerGeneration and
             (step.successor.phase != step.oldCut.closure.scope.phase or
              step.successor.round > step.oldCut.closure.scope.round)) }
    }
    part def ResizeRetirement {
        ref part participant : GambitRuntimeRoles::EpochParticipant;
        ref part worker : WorkerWithdrawal;
        ref part permit : GambitCollectionCompletion::ReclaimPermission;
        attribute rootMembershipRemovalCommitted : Boolean;
        attribute executionIngressClosed : Boolean;
        attribute executionUsersDrained : Boolean;
        attribute nativeThreadTerminationKnown : Boolean;
        attribute actualTargetMatchesPermit : Boolean;
        attribute consumedOnce : Boolean;
        attribute backingReleased : Boolean;
    }
    requirement def ResizeRetirementLaw {
        subject cut : ResizeRetirement;
        require constraint { not cut.backingReleased or
            (cut.executionIngressClosed and cut.executionUsersDrained and
             cut.rootMembershipRemovalCommitted and cut.participant.removalRequested and
             cut.worker.work.vm.vmId == cut.participant.vm.vmId and
             cut.worker.work.vm.generation == cut.participant.vm.generation and
             (cut.participant.requiredEpochSettled or
              (cut.participant.replacementMembershipCommitted and cut.participant.replacementRootCustodianLive)) and
             cut.worker.effectivePublished and cut.nativeThreadTerminationKnown and
             cut.permit.permitIssued and cut.actualTargetMatchesPermit and cut.consumedOnce) }
    }
    /* Source-to-law metadata is native-model owned. Its export is association
     * data only, never proof admission. Dependencies below own logical edges. */
    part def RefinementDuty {
        ref part formal : GambitRuntimeModelRelations::ContractBinding;
        attribute dutyId : String;
        attribute lawSymbol : String;
        attribute sourcePath : String;
        attribute openPremise : String;
    }
    part duty0 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> dutyId = "MR-MEMBER";
        attribute :>> lawSymbol = "GambitMembershipRevocation::MemberFreezeLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/setup.c";
        attribute :>> openPremise = "Complete current-root census and enroll/freeze linearization, including pending admissions";
    }
    part duty1 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.controlOrigin;
        attribute :>> dutyId = "MR-ROOT";
        attribute :>> lawSymbol = "GambitMembershipRevocation::RootSealLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "All final root locations, writers, saved/control origins and scanner acquire";
    }
    part duty2 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "MR-ANNOUNCE";
        attribute :>> lawSymbol = "GambitMembershipRevocation::RevocationAnnouncementLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Acquire/close serialization preserves accepted producer drain rights";
    }
    part duty3 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "MR-EFFECTIVE";
        attribute :>> lawSymbol = "GambitMembershipRevocation::RevocationEffectiveLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Complete producer, publisher, reader and transfer census; stable same-scope zero cut";
    }
    part duty4 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "MR-WITHDRAW";
        attribute :>> lawSymbol = "GambitMembershipRevocation::WorkerWithdrawalLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Complete copy/cursor/Tail/acquired-chunk state transfer and exclusive accepted custody";
    }
    part duty5 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "MR-LATE";
        attribute :>> lawSymbol = "GambitMembershipRevocation::LateDeliveryLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Publication, failure and unknown-effect refinement; full scope and valid prior lease before dereference";
    }
    part duty6 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "MR-ADVANCE";
        attribute :>> lawSymbol = "GambitMembershipRevocation::PhaseAdvanceLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Immutable successor generation, weak/continuation work closure and no native ABA";
    }
    part duty7 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.retirementWindow;
        attribute :>> dutyId = "MR-RESIZE";
        attribute :>> lawSymbol = "GambitMembershipRevocation::ResizeRetirementLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/setup.c";
        attribute :>> openPremise = "Replacement root acceptance, native last use, partial failure custody and actual single-consumed target permit";
    }
    /* Formal bindings reuse root authority; target obligations remain OPEN. */
    part def ClosureGraph {
        ref part membership : MembershipCut;
        ref part revoke : PhaseRevocation;
        ref part withdraw : WorkerWithdrawal;
        ref part late : LateDelivery;
        ref part resize : ResizeRetirement;
        ref part rootHandoff : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.rootHandoff;
        ref part controlOrigin : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.controlOrigin;
        ref part retirement : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.retirementWindow;
        ref part workClosure : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.workClosure;
        connection rootCut connect membership to rootHandoff;
        connection savedOrigins connect membership to controlOrigin;
        connection frozenRoots connect membership to resize;
        connection scopedDrain connect revoke to workClosure;
        connection acceptedWork connect revoke to late;
        connection custodyBeforeExit connect late to withdraw;
        connection workerExit connect withdraw to resize;
        connection targetLastUse connect resize to retirement;
    }
    part formalBridge : ClosureGraph;
    dependency sealRequiresFreeze from RootSealLaw to MemberFreezeLaw;
    dependency sealRequiresAcknowledgement from RootSealLaw to GambitRuntimeRoles::ParticipantAcknowledgementLaw;
    dependency sealRequiresControlOrigins from RootSealLaw to GambitRuntimeModelRelations::relations::controlOrigin;
    dependency revokeRequiresAnnouncement from RevocationEffectiveLaw to RevocationAnnouncementLaw;
    dependency revokeRequiresDrain from RevocationEffectiveLaw to GambitCollectionCompletion::PhaseDrainAdmissionLaw;
    dependency revokeRequiresCreditDomain from RevocationEffectiveLaw to GambitCollectionCompletion::CreditDomainLaw;
    dependency revokeRequiresTerminalStability from RevocationEffectiveLaw to GambitCollectionCompletion::PhaseDrainStabilityLaw;
    dependency withdrawRequiresCustody from WorkerWithdrawalLaw to GambitGc::WorkCustodyReleaseLaw;
    dependency lateRequiresDomain from LateDeliveryLaw to GambitGc::WorkContextDomainLaw;
    dependency lateRequiresPriorCustody from LateDeliveryLaw to GambitCollectionCompletion::LateWorkCustodyLaw;
    dependency advanceRequiresRevocation from PhaseAdvanceLaw to RevocationEffectiveLaw;
    dependency resizeRequiresParticipantRemoval from ResizeRetirementLaw to GambitRuntimeRoles::ParticipantRemovalLaw;
    dependency resizeRequiresWorkerRelease from ResizeRetirementLaw to WorkerWithdrawalLaw;
    dependency resizeRequiresPermission from ResizeRetirementLaw to GambitCollectionCompletion::ReclaimPermissionLaw;
    dependency resizeRequiresConsumption from ResizeRetirementLaw to GambitCollectionCompletion::PermitConsumptionLaw;
}
