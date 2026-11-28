/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/research/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitResearch {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def EvidenceBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute gatePromotionRequested : Boolean;
        attribute sourceIdentityMatched : Boolean;
        attribute requiredEvidenceClassComplete : Boolean;
        attribute modelValidationOnly : Boolean;
        attribute nativeAcceptanceClaimed : Boolean;
    }

    requirement def EvidenceClassLaw {
        subject boundary : EvidenceBoundary;
        require constraint { not boundary.gatePromotionRequested or (boundary.sourceIdentityMatched and boundary.requiredEvidenceClassComplete) }
    }

    requirement def NoNativePromotionFromModelLaw {
        subject boundary : EvidenceBoundary;
        require constraint { not boundary.modelValidationOnly or not boundary.nativeAcceptanceClaimed }
    }

    /* These are research observations, not launch permission or gate credit. */
    part def MechanismExperiment {
        attribute sourceIdentity : Integer;
        attribute observedSourceIdentity : Integer;
        attribute productIdentity : Integer;
        attribute observedProductIdentity : Integer;
        attribute hypothesisIdentity : Integer;
        attribute alternativeIdentity : Integer;
        attribute fixtureIdentity : Integer;
        attribute observedFixtureIdentity : Integer;
        attribute configurationIdentity : Integer;
        attribute observedConfigurationIdentity : Integer;
        attribute generation : Integer;
        attribute observedGeneration : Integer;
        attribute prediction : Integer;
        attribute alternativePrediction : Integer;
        attribute outcome : Integer;
        attribute complete : Boolean;
        attribute discriminationClaimed : Boolean;
    }
    requirement def DiscriminationLaw {
        subject experiment : MechanismExperiment;
        require constraint {
            not experiment.discriminationClaimed or
            (experiment.hypothesisIdentity != experiment.alternativeIdentity and
             experiment.prediction != experiment.alternativePrediction and
             experiment.sourceIdentity == experiment.observedSourceIdentity and
             experiment.productIdentity == experiment.observedProductIdentity and
             experiment.fixtureIdentity == experiment.observedFixtureIdentity and
             experiment.configurationIdentity == experiment.observedConfigurationIdentity and
             experiment.generation == experiment.observedGeneration and experiment.complete and
             (experiment.outcome == experiment.prediction or experiment.outcome == experiment.alternativePrediction))
        }
    }
    part def RepairInvestigation {
        attribute investigationId : String;
        attribute gateDefinition : String;
        attribute failureEvidence : String;
        attribute sourceMechanism : String;
        attribute competingHypotheses : String;
        attribute distinguishingObservation : String;
        attribute sourceRefinementRequired : String;
        attribute acceptanceBoundary : String;
        attribute quintSource : String;
        attribute quintSymbol : String;
        attribute leanSource : String;
        attribute leanSymbol : String;
        attribute disposition : String;
    }

}
