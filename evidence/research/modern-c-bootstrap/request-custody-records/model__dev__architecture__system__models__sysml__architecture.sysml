/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/system/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitArchitecture {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def FoundationBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute modernCRequired : Boolean;
        attribute cCapabilityRetained : Boolean;
        attribute semanticOwnerCount : Integer;
        attribute implementationOwnerCount : Integer;
    }

    requirement def SingleSemanticOwner {
        subject boundary : FoundationBoundary;
        require constraint { boundary.semanticOwnerCount == 1 }
    }

    requirement def RetainMandatoryC {
        subject boundary : FoundationBoundary;
        require constraint { boundary.modernCRequired and boundary.cCapabilityRetained }
    }

    requirement def SingleSelectedImplementation {
        subject boundary : FoundationBoundary;
        require constraint { boundary.implementationOwnerCount == 1 }
    }

}
