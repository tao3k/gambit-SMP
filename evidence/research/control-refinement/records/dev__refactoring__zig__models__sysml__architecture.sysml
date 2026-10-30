/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/refactoring/zig/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitZig {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def EvolutionCandidate {
        part identity : Identity;
        port service : NativeService;
        attribute adoptionRequested : Boolean;
        attribute cContractPreserved : Boolean;
        attribute replacementOwnerNamed : Boolean;
        attribute incrementalBenefitEstablished : Boolean;
        attribute oldOwnerRetirementClosed : Boolean;
    }

    requirement def EvolutionAdmissionLaw {
        subject boundary : EvolutionCandidate;
        require constraint { not boundary.adoptionRequested or (boundary.cContractPreserved and boundary.replacementOwnerNamed and boundary.incrementalBenefitEstablished and boundary.oldOwnerRetirementClosed) }
    }

}
