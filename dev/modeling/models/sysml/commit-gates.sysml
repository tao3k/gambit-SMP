package GambitCommitGates {
  private import ScalarValues::*;
  part def Gate { attribute id : String; attribute purpose : String; }
  part tests : Gate { attribute :>> id = "tests"; attribute :>> purpose = "All tests required by this source cut must finish with exact source and profile receipts; missing, timeout, unknown and failed results block"; }
  part learning : Gate { attribute :>> id = "learning"; attribute :>> purpose = "State what the architecture taught us, what it amplifies, its actual retirement and added costs; no inferred speedup"; }
  part process : Gate { attribute :>> id = "process"; attribute :>> purpose = "Disclose the current refactoring stage, dependencies, remaining steps and acceptance boundary"; }
  part models : Gate { attribute :>> id = "models"; attribute :>> purpose = "Native SysML drives ASCENT; select QNT schedules and Lean laws only for applicable semantic changes, with distinct duties and actual source-refinement boundaries"; }
  part questions : Gate { attribute :>> id = "questions"; attribute :>> purpose = "Answer the mandatory Gambit-paper, semantic, amplification and counterexample questions within the claimed cut; unresolved mandatory answers block"; }
}
