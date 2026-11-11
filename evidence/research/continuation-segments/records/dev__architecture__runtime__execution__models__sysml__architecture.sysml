/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/runtime/execution/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitRuntime {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def ExecutionBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute managedActive : Boolean;
        attribute exclusiveOwner : Boolean;
        attribute vmLive : Boolean;
        attribute rootsPublished : Boolean;
        attribute reclaimRequested : Boolean;
        attribute lastUsersDrained : Boolean;
    }

    /* Target logical identities/grants; not a chosen C structure or one per
     * Scheme thread/OS thread. Existing ContextRecord stays the state owner. */
    part def ContextIdentity {
        ref part vm : GambitSharedRuntime::VmRecord;
        ref part contextRecord : GambitSharedRuntime::ContextRecord;
        attribute vmGeneration : Integer;
        attribute contextGeneration : Integer;
    }
    part def ExecutionGrant {
        ref part identity : ContextIdentity;
        attribute ownerThreadId : Integer;
        attribute ownerThreadGeneration : Integer;
        attribute grantSerial : Integer;
        attribute live : Boolean;
        attribute admissionClosed : Boolean;
        attribute managedEntry : Boolean;
        attribute pendingRequestReconciled : Boolean;
    }
    requirement def ContextGrantLaw {
        subject grant : ExecutionGrant;
        require constraint { not grant.managedEntry or
            (grant.live and not grant.admissionClosed and
             grant.identity.contextRecord.vmId == grant.identity.vm.vmId and
             grant.identity.vmGeneration == grant.identity.vm.generation and
             grant.identity.vm.admissionOpen and grant.identity.contextRecord.executionOwned and
             grant.pendingRequestReconciled and grant.identity.contextRecord.requestReconciled and
             grant.identity.contextRecord.allRequiredValuesReloaded and grant.identity.contextRecord.oldAliasesInvalidated and
             grant.identity.contextRecord.loadedRelocationEpoch == grant.identity.vm.completedRelocationEpoch) }
    }
    part def ExecutionGrantPair {
        ref part firstGrant : ExecutionGrant;
        ref part secondGrant : ExecutionGrant;
    }
    requirement def ExclusiveContextGrantLaw {
        subject pair : ExecutionGrantPair;
        require constraint {
            not (pair.firstGrant.live and pair.secondGrant.live) or
            pair.firstGrant.identity.vm.vmId != pair.secondGrant.identity.vm.vmId or
            pair.firstGrant.identity.vmGeneration != pair.secondGrant.identity.vmGeneration or
            pair.firstGrant.identity.contextRecord.contextId != pair.secondGrant.identity.contextRecord.contextId or
            pair.firstGrant.identity.contextGeneration != pair.secondGrant.identity.contextGeneration or
            (pair.firstGrant.grantSerial == pair.secondGrant.grantSerial and
             pair.firstGrant.ownerThreadId == pair.secondGrant.ownerThreadId and
             pair.firstGrant.ownerThreadGeneration == pair.secondGrant.ownerThreadGeneration)
        }
    }

    requirement def ExecutionAdmissionLaw {
        subject boundary : ExecutionBoundary;
        require constraint { not boundary.managedActive or (boundary.exclusiveOwner and boundary.vmLive) }
    }

    requirement def ReclaimLaw {
        subject boundary : ExecutionBoundary;
        require constraint { not boundary.reclaimRequested or (boundary.rootsPublished and boundary.lastUsersDrained) }
    }

}
