package GambitBranchQualification {
  private import ScalarValues::*;
  part def Campaign { attribute branch:String; attribute repository:String; attribute evidenceRoot:String; }
  part campaign:Campaign {
    attribute :>> branch="modern-c";
    attribute :>> repository="vendor/gambit";
    attribute :>> evidenceRoot="evidence/refactoring/modern-c";
  }
  ref part ownershipComponent=GambitRuntimeRoleRealization::cut0;
  attribute profile:String="evidence/research/worker-role-handoff/profile.json";
  attribute scope:String="Independent exact-commit branch qualification. Read Git objects, never dirty vendor files. Use the one existing Modern C SDK with explicit source transition and preserved completed products. Source, generated artifacts, compiler seed and native outcomes have separate identities.";
  attribute formalDuty:String="SysML owns test scope and original semantic requirement references. ASCENT admits only matching source/profile/producer/inventory observations. The existing bounded recipe recorder executes commands. QNT schedules and Lean laws stay with their owning runtime components; source identity and process receipts do not duplicate them.";
  attribute progressRule:String="PASS of a named case supplies only that exact test contract. No patch-line8/12, research-tree test or structural commit gate transfers into branch progress. Semantic requirements remain unestablished until their whole contracts and source refinement are independently reviewed.";
  part def Case { attribute id:String; attribute budgetSeconds:Integer; attribute scope:String; attribute prerequisite:String; }
  part source:Case { attribute :>> id="source-binding"; attribute :>> budgetSeconds=30; attribute :>> scope="Git branch/head/tree and all archived source byte/mode identities; no overlay; original unit/stress/helper inventories"; attribute :>> prerequisite="none"; }
  part bootstrap:Case { attribute :>> id="bootstrap"; attribute :>> budgetSeconds=600; attribute :>> scope="Existing Bazel C23 profile and Make from-scratch; phases1-4 exactly twice; all expected generated C; canonical source unchanged; actual linked output identities and quiescent completion; preserve failed phases"; attribute :>> prerequisite="source-binding"; }
  part gsi:Case { attribute :>> id="original-gsi"; attribute :>> budgetSeconds=300; attribute :>> scope="Entire original branch unit inventory through its own unchanged run-unit-tests.scm; parentp1 childp2; exact PASSED ALL inventory marker plus original assertions and unchanged fixtures; no supplemented count"; attribute :>> prerequisite="bootstrap"; }
  part gsc:Case { attribute :>> id="original-gsc"; attribute :>> budgetSeconds=300; attribute :>> scope="Entire original compiled inventory with upstream loader/assertions and bound per-file/group limits. Do not execute or admit until the existing original per-file limit contract is resolved; no censored partial PASS"; attribute :>> prerequisite="bootstrap;original-limit-contract"; }
  part ffi:Case { attribute :>> id="official-gc-ffi"; attribute :>> budgetSeconds=90; attribute :>> scope="Unchanged branch Make test7/test8/test9 recipes, native mem/server/dynamic loading and expected-output diff; existing heap flags; support coverage only"; attribute :>> prerequisite="bootstrap"; }
  part control:Case { attribute :>> id="map-multishot"; attribute :>> budgetSeconds=90; attribute :>> scope="Branch-committed frame-continuation.scm: actual Scheme map, dynamic-wind, C call, forced GC and repeated restoration; own native compile and run; no injected research worker protocol"; attribute :>> prerequisite="bootstrap"; }
  part def RequirementUse { ref part original:GambitModernCCommitAdmission::BaselineAssessment; attribute status:String="UNESTABLISHED-ON-BRANCH"; }
  part bootstrapGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineBootstrap; }
  part gsiGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineGsi; }
  part prGsiGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselinePrGsi; }
  part gscGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineGsc; }
  part prGscGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselinePrGsc; }
  part stressGsiGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineStressGsi; }
  part stressGscGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineStressGsc; }
  part registryGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineRegistry; }
  part lifecycleGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineFaults; }
  part ffiGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineFfi; }
  part gerbilGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselineGerbil; }
  part performanceGate:RequirementUse { ref part :>> original=GambitModernCCommitAdmission::baselinePerformance; }
}
