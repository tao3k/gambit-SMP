/* Shared modeling-method policy. Modules own needs/models; ASCENT owns joins
 * and gap inference. No runner execution or native permission is granted. */
package GambitAssuranceRouting {
    private import ScalarValues::*;
    part def MethodRule {
        attribute kind : String;
        attribute method : String;
        attribute requiredCheck : String;
    }
    part interleaving : MethodRule {
        attribute :>> kind = "interleaving";
        attribute :>> method = "QNT";
        attribute :>> requiredCheck = "bounded-histories";
    }
    part induction : MethodRule {
        attribute :>> kind = "induction";
        attribute :>> method = "Lean";
        attribute :>> requiredCheck = "inductive-preservation";
    }
    part sourceRefinement : MethodRule {
        attribute :>> kind = "source-refinement";
        attribute :>> method = "Lean";
        attribute :>> requiredCheck = "source-simulation";
    }
    part nativeMemoryOrder : MethodRule {
        attribute :>> kind = "native-memory-order";
        attribute :>> method = "C-memory";
        attribute :>> requiredCheck = "native-memory-refinement";
    }
    part environmentRefinement : MethodRule {
        attribute :>> kind = "environment-refinement";
        attribute :>> method = "SourceAudit";
        attribute :>> requiredCheck = "snapshot-and-io-refinement";
    }
    part def ModelNeed {
        ref part owner : GambitAssuranceRelations::ComponentModelUse;
        attribute obligationId : String;
        attribute kind : String;
        attribute premise : String;
        attribute subjectPath : String;
        attribute subjectScope : String;
    }
    part def ComponentStudy {
        ref part component : GambitAssuranceRelations::ComponentModelUse;
        attribute quintSource : String;
        attribute quintScope : String;
        attribute baselineModel : String;
        attribute leanSource : String;
        attribute leanScope : String;
        attribute sourcePath : String;
        attribute sourceAnchors : String;
        attribute stateProjection : String;
        attribute eventProjection : String;
        attribute invariant : String;
        attribute abstractionBoundary : String;
    }
    part def SharedContract {
        ref part producer : GambitAssuranceRelations::ComponentModelUse;
        ref part consumer : GambitAssuranceRelations::ComponentModelUse;
        attribute contractId : String;
        attribute phaseScope : String;
        attribute guarantee : String;
        attribute rely : String;
        attribute failureCustodian : String;
    }
    part def NeedDependency {
        ref part dependent : ModelNeed;
        ref part prerequisite : ModelNeed;
    }
    part def Planner { attribute selectionOnly : Boolean; }
    part def QntChecker { attribute nativeRuntimeAcceptance : Boolean; }
    part def LeanChecker { attribute sourceSimulationEstablished : Boolean; }
    part def ScopedReceipt { attribute exactSourceAndScopeRequired : Boolean; }
    part def OpenFrontier { attribute runtimeAuthority : Boolean; }
    part def RoutingGraph {
        ref part componentNeed : ModelNeed;
        ref part methodPolicy : MethodRule;
        part ascent : Planner;
        part quint : QntChecker;
        part lean : LeanChecker;
        part receipt : ScopedReceipt;
        part frontier : OpenFrontier;
        connection needs connect componentNeed to ascent;
        connection methodSelection connect methodPolicy to ascent;
        connection histories connect ascent to quint;
        connection induction connect ascent to lean;
        connection qntScope connect quint to receipt;
        connection leanScope connect lean to receipt;
        connection sourceBoundFeedback connect receipt to ascent;
        connection unresolved connect ascent to frontier;
        connection researchFeedback connect frontier to componentNeed;
    }
}
