package GambitReleaseAcceptance {
  private import ScalarValues::*;
  ref part family = GambitModernCDeliveryPlan::a12;
  ref part composition = GambitSmpDevComposition::f12;
  attribute baseline:String="1b1aa854";
  attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
  attribute mode:String="paired-release";
  attribute inventory:String="release";
  attribute maxCompilerRssGiB:Integer=8;
  attribute requiredFamilies:String="bootstrap;gsi;gsc;pr-gsi;pr-gsc;stress-gsi;stress-gsc;registry;lifecycle;gc-ffi;gerbil;release";
  attribute protocol:String="Pair matched baseline and candidate sealed producers on identical hardware, compiler, profile, and original workload budgets (4096-request binding/service cohort, composed resume/GC cohort, and stress/RSS ceiling observations). Retain exact baseline/candidate digests, completed work, censoring/timeouts, pause and wall tails, CPU, and peak RSS (< 8 GiB). Whole 12/12 release admission requires same-source conjunction of all 12 families on one final source tree; cross-source splicing is strictly forbidden.";
  attribute formalDuty:String="SysML owns Family 12 paired-cohort accounting, censoring retention, and non-splicing conjunction rules. Quint release_cohort_admission.qnt owns same-source 12/12 conjunction, matched-cohort pairing, censoring retention, RSS cap enforcement, and cross-source splice refusal histories. Lean ReleaseCohortAlgebra.lean owns formal conjunction soundness, monotone veto preservation, and impossibility of promoting a 12/12 claim from disjoint source trees.";
  attribute manifestPath:String="evidence/research/retained/modern-c/release/manifest.json";
  part def MetricGate { attribute id:String; attribute unit:String; attribute rule:String; }
  part m0:MetricGate { attribute :>> id="completed-work"; attribute :>> unit="count"; attribute :>> rule="Report exact completed requests/cases and retain every censored or timed-out item without omission."; }
  part m1:MetricGate { attribute :>> id="wall-and-pause-tails"; attribute :>> unit="milliseconds"; attribute :>> rule="Report p50/p95/p99 wall and GC pause quantiles for both paired baseline and candidate cohorts."; }
  part m2:MetricGate { attribute :>> id="peak-rss-cap"; attribute :>> unit="bytes"; attribute :>> rule="Peak process-group RSS across bootstrap, compilation, and runtime execution must remain strictly below 8 GiB (8589934592 bytes)."; }
  part m3:MetricGate { attribute :>> id="same-source-conjunction"; attribute :>> unit="boolean"; attribute :>> rule="Every admitted family in a whole-runtime numerator must bind the exact same source tree digest, profile digest, and sealed producer identity; zero cross-source splicing."; }
}
