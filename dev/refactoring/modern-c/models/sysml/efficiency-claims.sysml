package GambitEfficiencyClaims {
  private import ScalarValues::*;
  attribute defaultClaim:String="foundation";
  attribute upgradeClaim:String="efficiency-upgrade";
  attribute requiredMetrics:String="pause;throughput;rss";
  attribute includedCosts:String="build;load;allocation;gc;cleanup";
  attribute fixedOverhead:String="fixed-overhead";
  attribute rule:String="Correctness closure and a local positive measurement establish foundation work. An efficiency-upgrade claim additionally needs a complete predeclared paired benchmark population with matching workload and resource limits, all planned repeated observations, pause/throughput/RSS rows and explicit fixed-overhead accounting. Build, load, allocation, GC and cleanup costs stay included. Missing or unmeasured dimensions deny the upgrade claim. Retain unfavorable observations; one favorable row cannot cancel a measured regression. RSS must identify its scope and must not be relabeled as physical peak memory. This is necessary evidence, not a statistical or universal speedup theorem.";
}
