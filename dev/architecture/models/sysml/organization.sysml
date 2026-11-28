/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitArchitectureComposition {
    private import ScalarValues::*;

    part def SystemComposition {
        part foundation : GambitArchitecture::FoundationBoundary;
        part collector : GambitGc::CollectorBoundary;
        part control : GambitControl::ResumptionBoundary;
        part foreign : GambitFfi::ForeignBoundary;
        part lowering : GambitCompiler::LoweringBoundary;
        part products : GambitToolchain::ArtifactBoundary;
    }
    /* Part structure describes responsibility. Runtime instances, port bindings
     * and cross-model step refinement remain explicit unresolved obligations. */

}
