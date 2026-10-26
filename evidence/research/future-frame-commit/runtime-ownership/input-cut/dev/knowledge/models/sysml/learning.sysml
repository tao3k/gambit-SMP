/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitKnowledge {
    private import ScalarValues::*;

    part def MechanismLearning {
        attribute sourceIdentity : String;
        attribute upstreamFact : String;
        attribute gambitMismatch : String;
        attribute proposedInference : String;
        attribute decisionRequested : Boolean;
        attribute assumptionsExplicit : Boolean;
        attribute counterexampleRecorded : Boolean;
    }
    requirement def LearningAdmissionLaw {
        subject learning : MechanismLearning;
        require constraint { not learning.decisionRequested or
            (learning.assumptionsExplicit and learning.counterexampleRecorded) }
    }

}
