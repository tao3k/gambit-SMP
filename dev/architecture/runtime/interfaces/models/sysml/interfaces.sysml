/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitRuntimeInterfaces {
    private import ScalarValues::*;

    /* One specification vocabulary for the existing composition interfaces.
     * These fields describe proof obligations and impose no runtime layout. */
    part def InterfaceContract {
        attribute identityScope : String;
        attribute callerRequires : String;
        attribute supplierEnsures : String;
        attribute frameCondition : String;
        attribute environmentAssumption : String;
        attribute interferenceGuarantee : String;
        attribute invalidation : String;
        attribute failureCustody : String;
        attribute progressObligation : String;
        attribute synchronization : String;
        attribute sourceObligation : String;
        attribute modelObligation : String;
        attribute nativeObligation : String;
        attribute status : String;
    }
    part def AllocationGrantState {
        attribute ownerMatches : Boolean;
        attribute backingLive : Boolean;
        attribute cursorInside : Boolean;
        attribute footprintCovered : Boolean;
        attribute preparatoryBacking : Boolean;
        attribute currentView : Boolean;
        attribute grantPublished : Boolean;
    }
    requirement def AllocationGrantLaw {
        subject grant : AllocationGrantState;
        require constraint { not grant.grantPublished or
            (grant.ownerMatches and grant.backingLive and grant.cursorInside and
             grant.footprintCovered and grant.preparatoryBacking and grant.currentView) }
    }

    /* Logical comparison scopes, not a selected runtime memory layout. */
    part def CollectionScope {
        attribute vmId : Integer;
        attribute vmGeneration : Integer;
        attribute collectionEpoch : Integer;
        attribute rootCutEpoch : Integer;
    }
    part def ResourceScope {
        attribute resourceId : Integer;
        attribute resourceGeneration : Integer;
    }
    part def RootHandoff {
        part collection : CollectionScope;
        part carrier : ResourceScope;
        attribute contextId : Integer;
        attribute contextGeneration : Integer;
        attribute finalValuesFrozen : Boolean;
        attribute executionReleased : Boolean;
        attribute rootInventoryComplete : Boolean;
        attribute scannerCustodianLive : Boolean;
        attribute scanRequested : Boolean;
    }
    requirement def RootHandoffAdmissionLaw {
        subject handoff : RootHandoff;
        require constraint { not handoff.scanRequested or
            (handoff.finalValuesFrozen and handoff.executionReleased and
             handoff.rootInventoryComplete and handoff.scannerCustodianLive) }
    }
    part def ControlOrigins {
        part resolutionCollection : CollectionScope;
        part backing : ResourceScope;
        attribute inventoryGeneration : Integer;
        attribute currentFrameOrigin : Integer;
        attribute retainedOriginInventoryIdentity : String;
        attribute allRawOriginsDeclared : Boolean;
        attribute allDeclaredOriginsResolved : Boolean;
        attribute backingReleaseRequested : Boolean;
    }
    requirement def OriginClosureLaw {
        subject origins : ControlOrigins;
        require constraint { not origins.backingReleaseRequested or
            (origins.allRawOriginsDeclared and origins.allDeclaredOriginsResolved) }
    }
    part def RetirementWindow {
        part collection : CollectionScope;
        part target : ResourceScope;
        attribute noLateProducers : Boolean;
        attribute allTargetUsersDrained : Boolean;
        attribute strongDone : Boolean;
        attribute weakDone : Boolean;
        attribute cleanupDone : Boolean;
        attribute reuseRequested : Boolean;
    }
    requirement def StableRetirementLaw {
        subject window : RetirementWindow;
        require constraint { not window.reuseRequested or
            (window.noLateProducers and window.allTargetUsersDrained and
             window.strongDone and window.weakDone and window.cleanupDone) }
    }
    /* Aggregate whole-collection work closure; not a strong/weak scan receipt.
     * Phase-scoped drainage is modeled by GambitCollectionCompletion. */
    part def WorkClosure {
        part collection : CollectionScope;
        part workerTeam : ResourceScope;
        attribute privateWorkDrained : Boolean;
        attribute queuedWorkDrained : Boolean;
        attribute scanningWorkDrained : Boolean;
        attribute producersClosed : Boolean;
        attribute successfulCompletionPublished : Boolean;
    }
    requirement def WorkClosureLaw {
        subject work : WorkClosure;
        require constraint { not work.successfulCompletionPublished or
            (work.privateWorkDrained and work.queuedWorkDrained and
             work.scanningWorkDrained and work.producersClosed) }
    }

    part def WorkClosureTransition {
        part preWork : WorkClosure;
        part postWork : WorkClosure;
    }
    requirement def CompletedEpochStabilityLaw {
        subject step : WorkClosureTransition;
        require constraint {
            not step.preWork.successfulCompletionPublished or
            step.preWork.collection.vmId != step.postWork.collection.vmId or
            step.preWork.collection.vmGeneration != step.postWork.collection.vmGeneration or
            step.preWork.collection.collectionEpoch != step.postWork.collection.collectionEpoch or
            (step.postWork.workerTeam.resourceId == step.preWork.workerTeam.resourceId and
             step.postWork.workerTeam.resourceGeneration == step.preWork.workerTeam.resourceGeneration and
             step.postWork.collection.rootCutEpoch == step.preWork.collection.rootCutEpoch and
             step.postWork.successfulCompletionPublished and
             step.postWork.privateWorkDrained and step.postWork.queuedWorkDrained and
             step.postWork.scanningWorkDrained and step.postWork.producersClosed)
        }
    }
    /* A different VM generation/collection epoch requires separate admission.
     * A changed team or root cut cannot reopen the same completed epoch.
     * This law prohibits work reopening under the same completed identity;
     * it is not an assertion that any existing QNT or runtime implements it. */
}
