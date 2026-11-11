/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/refactoring/modern-c/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitModernC {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def CRealization {
        part identity : Identity;
        port service : NativeService;
        attribute cBackendRetained : Boolean;
        attribute cAbiRetained : Boolean;
        attribute embeddingRetained : Boolean;
        attribute semanticPlanComplete : Boolean;
        attribute nativeEmissionRequested : Boolean;
    }

    requirement def CCapabilityLaw {
        subject boundary : CRealization;
        require constraint { boundary.cBackendRetained and boundary.cAbiRetained and boundary.embeddingRetained }
    }

    requirement def CompletedPlanLaw {
        subject boundary : CRealization;
        require constraint { not boundary.nativeEmissionRequested or boundary.semanticPlanComplete }
    }

}
