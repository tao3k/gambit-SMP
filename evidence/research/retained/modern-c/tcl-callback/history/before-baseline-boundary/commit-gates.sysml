package GambitCommitGates {
  private import ScalarValues::*;
  part def Gate { attribute id : String; attribute purpose : String; }
  part tests : Gate { attribute :>> id = "tests"; attribute :>> purpose = "All tests required by this source cut must finish with exact source and profile receipts; missing, timeout, unknown and failed results block"; }
  part learning : Gate { attribute :>> id = "learning"; attribute :>> purpose = "State each claimed benefit, mechanism, retired responsibility, added cost and corresponding test/source evidence. Separate measured results from theoretical conditions; no inferred speedup"; }
  part process : Gate { attribute :>> id = "process"; attribute :>> purpose = "Disclose the current refactoring stage, dependencies, remaining steps and acceptance boundary. Justify every official-source change by the selected responsibility replacement; retain official names and build entrypoints unless their replacement is necessary and evidenced"; }
  part models : Gate { attribute :>> id = "models"; attribute :>> purpose = "Native SysML drives ASCENT; select QNT schedules and Lean laws only for applicable semantic changes, with distinct duties and actual source-refinement boundaries"; }
  part questions : Gate { attribute :>> id = "questions"; attribute :>> purpose = "Answer the mandatory Gambit-paper, semantic, amplification and counterexample questions within the claimed cut; unresolved mandatory answers block"; }
  part revisionAudit {
    attribute allRevisions : Boolean = true;
    attribute fields : String = "responsibility,retired,validation,benefits,costs,process,checklist,models,open";
    attribute rule : String = "Every REV, including small corrections, must publish its reviewed audit in the Git commit body: exact responsibility/retirement, reproducible tests and results, evidenced benefits, added costs, current process, repository Org checklist, distinct model duties and remaining gaps. Bind the report before ASCENT admission and reject later changes. Every user-facing progress/final report must identify the problem solved or still under qualification, stable checklist item, closed and remaining obligations with their counting unit, position/dependencies in the programme, and why the retired authority/work is a fundamental responsibility replacement with a falsifier. A planned item, scoped leaf, whole-stage closure and full SMP acceptance are different units; never derive an SMP percentage from test or REV counts. DEV refactoring progress is independent of SMP patch-line milestones; no 8-12 credit transfers";
  }
}
