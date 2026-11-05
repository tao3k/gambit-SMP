/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/runtime/ffi/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitFfi {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def ForeignBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute parked : Boolean;
        attribute rootCustodianLive : Boolean;
        attribute managedBorrowEnded : Boolean;
        attribute reentering : Boolean;
        attribute executionReacquired : Boolean;
        attribute movedValuesReloaded : Boolean;
    }

    requirement def ParkLaw {
        subject boundary : ForeignBoundary;
        require constraint { not boundary.parked or (boundary.rootCustodianLive and boundary.managedBorrowEnded) }
    }

    requirement def ReentryLaw {
        subject boundary : ForeignBoundary;
        require constraint { not boundary.reentering or (boundary.executionReacquired and boundary.movedValuesReloaded) }
    }

}
