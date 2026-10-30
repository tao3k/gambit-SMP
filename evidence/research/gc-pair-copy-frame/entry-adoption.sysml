/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitRefactoring {
    private import ScalarValues::*;

    part def ReplacementDecision {
        attribute modernCRequired : Boolean;
        attribute cCapabilityPreserved : Boolean;
        attribute zigSelected : Boolean;
        attribute namedResponsibilityReplaced : Boolean;
        attribute incrementalBenefitEstablished : Boolean;
        attribute oldImplementationRetired : Boolean;
        attribute singleSemanticOwner : Boolean;
    }
    requirement def BaselineLaw {
        subject decision : ReplacementDecision;
        require constraint { decision.modernCRequired and
            decision.cCapabilityPreserved and decision.singleSemanticOwner }
    }
    requirement def ZigIncrementLaw {
        subject decision : ReplacementDecision;
        require constraint { not decision.zigSelected or
            (decision.namedResponsibilityReplaced and
             decision.incrementalBenefitEstablished and decision.oldImplementationRetired) }
    }

}
