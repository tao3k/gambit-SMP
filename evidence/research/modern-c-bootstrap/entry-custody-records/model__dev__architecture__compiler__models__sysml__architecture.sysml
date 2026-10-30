/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/compiler/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitCompiler {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def LoweringBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute transformRequested : Boolean;
        attribute effectLegalityKnown : Boolean;
        attribute rootLegalityKnown : Boolean;
        attribute controlLegalityKnown : Boolean;
        attribute productPublished : Boolean;
        attribute contractIdentityMatched : Boolean;
    }

    requirement def TransformLaw {
        subject boundary : LoweringBoundary;
        require constraint { not boundary.transformRequested or (boundary.effectLegalityKnown and boundary.rootLegalityKnown and boundary.controlLegalityKnown) }
    }

    requirement def ProductLaw {
        subject boundary : LoweringBoundary;
        require constraint { not boundary.productPublished or boundary.contractIdentityMatched }
    }

}
