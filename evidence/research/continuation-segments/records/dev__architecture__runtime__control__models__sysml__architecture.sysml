/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/runtime/control/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitControl {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def ResumptionBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute resuming : Boolean;
        attribute ownerValid : Boolean;
        attribute rootsLive : Boolean;
        attribute resumptionAvailable : Boolean;
        attribute crossesNativeFrame : Boolean;
        attribute nativeBoundaryAdmitted : Boolean;
    }

    requirement def ResumptionLaw {
        subject boundary : ResumptionBoundary;
        require constraint { not boundary.resuming or (boundary.ownerValid and boundary.rootsLive and boundary.resumptionAvailable) }
    }

    requirement def NativeControlLaw {
        subject boundary : ResumptionBoundary;
        require constraint { not boundary.crossesNativeFrame or boundary.nativeBoundaryAdmitted }
    }

}
