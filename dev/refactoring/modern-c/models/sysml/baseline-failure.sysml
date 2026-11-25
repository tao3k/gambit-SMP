package GambitBaselineFailure {
  private import ScalarValues::*;
  ref part testGate=GambitCommitGates::tests;
  attribute id:String="baseline-failure-boundary";
  attribute fields:String="profile;tool;argv;cwd;limits;manifest;unit-sources;driver-rules;executable;dynamic-dependencies;effective-environment;paired-full-environment;quiescence";
  attribute roles:String="baseline;candidate";
  attribute traceVariables:String="CODEX_TOOL_CALL_ID;GAMBIT_SMP_TASK_RUN";
  attribute permittedDisposition:String="retained-outside-scope";
  attribute rule:String="A complete manifest and valid source/profile witnesses must cover both roles. For every observed candidate failure, a same-signature baseline failure and equal controlled input footprint plus a reviewed disjoint changed-source set are required. All related native cases and remaining original prerequisites must pass. Unknown outcomes, missing dependency/field, altered environment, new signature, related change or skipped case blocks scope admission. Retain every failed result; do not infer a failure-frequency or whole-runtime non-regression theorem.";
  attribute sourceDuty:String="The failing unit, include/helper closure, interpreter and declared startup/module paths must exclude the selected Tcl bridge. Compare actual configured Make/driver actions, all408 original unit sources, tools, executable and load commands, environment and limits. A static archive is not a runtime dependency of an already linked executable; do not infer this without load-command evidence.";
  attribute environmentDuty:String="Historical trace metadata differs and is retained as raw environment hashes. Only the two listed supervisor bookkeeping variables may be excluded after source non-use review; all other differences refuse. A fresh same-supervisor baseline/candidate pair must have byte-identical full environments, argv,cwd and resource bounds. Host scheduling and clock history need not be identical; stochastic failure-rate claims remain open.";
  attribute scopeOutcome:String="scopeReady permits only the selected responsibility REV; original cases are observed/classified, never converted from failed to passed. A green latest run cannot erase historical failure.";
  attribute familyOutcome:String="familyBlocked remains for every retained candidate failure, even when scopeReady holds and the latest paired candidate passes. No whole-family/SMP closure follows from a local REV.";
  attribute invalidation:String="Changed unit/driver/executable/load graph, startup/configuration, unreviewed environment key, manifest/population/limit or source reachability invalidates the comparison. Missing evidence remains unresolved; no generic skip flag or scheduler repair is introduced.";
}
