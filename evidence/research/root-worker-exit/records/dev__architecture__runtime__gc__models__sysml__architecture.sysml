/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/runtime/gc/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitGc {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def CollectorBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute scanning : Boolean;
        attribute rootCutSealed : Boolean;
        attribute contributorsAcknowledged : Boolean;
        attribute noUnknownMutator : Boolean;
        attribute skipMatureGraph : Boolean;
        attribute allMutationEdgesCovered : Boolean;
    }

    /* A collector task grant is independent of the mutator PSTATE which
     * supplied roots. Counts below are abstract responsibilities, not a
     * prescription for one physical atomic counter per task/slot. */
    part def CollectorWorkContext {
        ref part vm : GambitSharedRuntime::VmRecord;
        ref part phaseScope : GambitCollectionCompletion::PhaseScope;
        ref part coordinatorScope : GambitCollectionCompletion::PhaseScope;
        attribute workerId : Integer;
        attribute workerGeneration : Integer;
        attribute workEpoch : Integer;
        attribute teamId : Integer;
        attribute teamGeneration : Integer;
        /* Custody/drain lease, distinct from the new-acquisition gate in
         * GambitMembershipRevocation. Announcement does not discard work. */
        attribute teamGrantLive : Boolean;
        attribute taskGrantLive : Boolean;
        attribute copyInitializationDebt : Integer;
        attribute privateCursorDebt : Integer;
        attribute tailDebt : Integer;
        attribute dequeuedChunkDebt : Integer;
        attribute descriptorLeaseLive : Boolean;
        attribute releaseRequested : Boolean;
        attribute transferAccepted : Boolean;
        attribute receiverCustodianLive : Boolean;
        attribute completeRestoreStateTransferred : Boolean;
        attribute phaseDebtTransferred : Boolean;
        attribute outcomeUnknown : Boolean;
        attribute sourceCustodianRetained : Boolean;
    }
    requirement def WorkContextDomainLaw {
        subject work : CollectorWorkContext;
        require constraint {
            work.copyInitializationDebt >= 0 and work.privateCursorDebt >= 0 and
            work.tailDebt >= 0 and work.dequeuedChunkDebt >= 0 and
            (not work.taskGrantLive or
             (work.teamGrantLive and work.descriptorLeaseLive and
              work.phaseScope.collection.vmId == work.vm.vmId and
              work.phaseScope.collection.vmGeneration == work.vm.generation and
              work.phaseScope.collection.collectionEpoch == work.workEpoch and
              work.workEpoch == work.vm.requestEpoch and
              work.coordinatorScope.collection.vmId == work.vm.vmId and
              work.coordinatorScope.collection.vmGeneration == work.vm.generation and
              work.coordinatorScope.collection.collectionEpoch == work.workEpoch and
              work.phaseScope.collection.rootCutEpoch == work.coordinatorScope.collection.rootCutEpoch and
              work.phaseScope.phase == work.coordinatorScope.phase and
              work.phaseScope.round == work.coordinatorScope.round and
              work.phaseScope.producerGeneration == work.coordinatorScope.producerGeneration and
              work.coordinatorScope.workerTeam.resourceId == work.teamId and
              work.coordinatorScope.workerTeam.resourceGeneration == work.teamGeneration and
              work.phaseScope.workerTeam.resourceId == work.teamId and
              work.phaseScope.workerTeam.resourceGeneration == work.teamGeneration))
        }
    }
    requirement def WorkCustodyReleaseLaw {
        subject work : CollectorWorkContext;
        require constraint {
            (not work.releaseRequested or (not work.outcomeUnknown and
             ((not work.taskGrantLive and work.copyInitializationDebt == 0 and
              work.privateCursorDebt == 0 and work.tailDebt == 0 and work.dequeuedChunkDebt == 0) or
             (work.transferAccepted and not work.outcomeUnknown and work.receiverCustodianLive and
              work.completeRestoreStateTransferred and work.phaseDebtTransferred)))) and
            (not work.outcomeUnknown or work.sourceCustodianRetained)
        }
    }

    requirement def ScanAdmissionLaw {
        subject boundary : CollectorBoundary;
        require constraint { not boundary.scanning or (boundary.rootCutSealed and boundary.contributorsAcknowledged and boundary.noUnknownMutator) }
    }

    requirement def GenerationalSkipLaw {
        subject boundary : CollectorBoundary;
        require constraint { not boundary.skipMatureGraph or boundary.allMutationEdgesCovered }
    }

}
