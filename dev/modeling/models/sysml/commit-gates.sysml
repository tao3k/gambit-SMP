package GambitCommitGates {
  private import ScalarValues::*;
  part def Gate { attribute id : String; attribute purpose : String; }
  part tests : Gate { attribute :>> id = "tests"; attribute :>> purpose = "All tests required by this source cut must finish with exact source and profile receipts. Missing, timeout, unknown or newly introduced/related failures block. A retained baseline failure may be classified outside the cut only by an explicit SysML/ASCENT source-input equivalence and scope-disjointness proof, complete unchanged manifests and real scoped tests; it remains a failure and vetoes whole-family acceptance. No name-only allowlist, manifest reduction or retry-until-green qualifies"; }
  part learning : Gate { attribute :>> id = "learning"; attribute :>> purpose = "State each claimed benefit, mechanism, retired responsibility, added cost and corresponding test/source evidence. Separate measured results from theoretical conditions; no inferred speedup"; }
  part process : Gate { attribute :>> id = "process"; attribute :>> purpose = "Disclose the current refactoring stage, dependencies, remaining steps and acceptance boundary. Justify every official-source change by the selected responsibility replacement; retain official names and build entrypoints unless their replacement is necessary and evidenced"; }
  part models : Gate { attribute :>> id = "models"; attribute :>> purpose = "Native SysML drives ASCENT; select QNT schedules and Lean laws only for applicable semantic changes, with distinct duties and actual source-refinement boundaries"; }
  part questions : Gate { attribute :>> id = "questions"; attribute :>> purpose = "Answer the mandatory Gambit-paper, semantic, amplification and counterexample questions within the claimed cut; unresolved mandatory answers block"; }
  part def MetricEvidenceRef {
    attribute path : String;
    attribute pointer : String;
  }
  part def MetricObservation {
    attribute value : Real;
    attribute unit : String;
    attribute samples : Integer;
    part origin : MetricEvidenceRef;
  }
  part def BenefitCostRow {
    attribute id : String;
    attribute kind : String;
    attribute metric : String;
    attribute unit : String;
    attribute direction : String;
    attribute workload : String;
    attribute method : String;
    attribute limitation : String;
    part baseline : MetricEvidenceRef [0..1];
    part candidate : MetricEvidenceRef [0..1];
    part evidence : MetricEvidenceRef [1..*];
  }
  part revisionAudit {
    attribute allRevisions : Boolean = true;
    attribute matrixRequired : Boolean = true;
    attribute matrixFields : String = "id,kind,metric,unit,direction,baseline,candidate,workload,method,evidence,limitation";
    attribute matrixKinds : String = "measurement,control,accounted-cost,structural,unmeasured";
    attribute matrixRule : String = "Every future REV audit binds a nonempty structured benefit/cost matrix to the same base/tree/profile. Numeric values, units and sample counts come from durable source-bound evidence, with raw origin pointers checked against the recorded values, not literal narrative guesses. Record workload, method and limitation for each row. Compute signed delta/percent only with defined baselines; zero baseline has no percentage or ratio. Single observations remain observations; control timings, source accounting and structural benefits are not runtime speedup. Missing/stale matrix, row fields or evidence block ASCENT admission. Historical published audit packets remain immutable; later supplements are labeled separately.";
    attribute fields : String = "responsibility,retired,validation,benefits,costs,process,checklist,models,open";
    attribute rule : String = "Every REV, including small corrections, must publish its reviewed audit in the Git commit body: exact responsibility/retirement, reproducible tests and results, evidenced benefits, added costs, current process, repository Org checklist, distinct model duties and remaining gaps. Bind the report before ASCENT admission and reject later changes. Every user-facing progress/final report must identify the problem solved or still under qualification, stable checklist item, closed and remaining obligations with their counting unit, position/dependencies in the programme, and why the retired authority/work is a fundamental responsibility replacement with a falsifier. A planned item, scoped leaf, whole-stage closure and full SMP acceptance are different units; never derive an SMP percentage from test or REV counts. DEV refactoring progress is independent of SMP patch-line milestones; no 8-12 credit transfers";
  }
}
