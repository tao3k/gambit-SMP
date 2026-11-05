package GambitOriginalSmpMvp {
  private import ScalarValues::*;
  ref part family1=GambitModernCDeliveryPlan::a1;
  ref part family2=GambitModernCDeliveryPlan::a2;
  ref part family3=GambitModernCDeliveryPlan::a3;
  attribute stage:String="independent-smp-first-three";
  attribute scope:String="One complete self-hosted C-backend and original-suite delivery. Freeze 568e0276 as the control. Qualify one canonical source tree, both source bootstrap passes, stock core and original 408-case GSI/GSC under the existing profile, cache and budgets. Attach generated C to its producer and preserve unrelated pending work.";
  attribute formalDuty:String="Existing GVM frame/root and multi-shot requirements remain. Source refinement checks logical labels and frame descriptors against physical host placement, opaque-C refusal and loader bounds. QNT temporal GC/worker protocols and Lean frame/range laws retain their existing owners. No duplicate model or generalized timing theorem is introduced.";
  attribute sourceCases:String="host-graph;opaque-c;label-setup;fixnum-overflow;thread-lifetime;assertion-runtime;generated-cohort";
  attribute requiredCases:String="two-pass-bootstrap;stock-core;original-gsi;original-gsc;negative-controls;source-construction";
  part submission:GambitCommitGates::SubmissionUnit {
    attribute :>> kind="integration";
    attribute :>> result="original-smp-mvp";
    attribute :>> progressDelta=1;
    attribute :>> supportPaths="";
  }
  part def Need {
    ref part gate:GambitCommitGates::Gate;
    attribute id:String;
    attribute method:String;
    attribute artifact:String;
    attribute scope:String;
  }
  part tests:Need {
    ref part :>> gate=GambitCommitGates::tests;
    attribute :>> id="SMP-MVP-TESTS";
    attribute :>> method="native";
    attribute :>> artifact="evidence/research/retained/modern-c/frozen-568e0276-smp/submission/qualification.json";
    attribute :>> scope="One producer, actual two-pass bootstrap and stock core, original GSI408 and one entire GSC408 campaign, exact manifests and natural settled exits, numeric90 and whole300 caps, original continuation assertions and retained failures.";
  }
  part learning:Need {
    ref part :>> gate=GambitCommitGates::learning;
    attribute :>> id="SMP-MVP-LEARNING";
    attribute :>> method="source-analysis";
    attribute :>> artifact="dev/refactoring/modern-c/independent-smp-audit.org";
    attribute :>> scope="Separate logical GVM points from physical C hosts, replace repeated graph/dispatch work, preserve opaque-C boundaries, fix fused fixnum overflow and test target lifetime, and account for one shared assertion build and every independent process load.";
  }
  part process:Need {
    ref part :>> gate=GambitCommitGates::process;
    attribute :>> id="SMP-MVP-PROCESS";
    attribute :>> method="source-analysis";
    attribute :>> artifact="dev/refactoring/modern-c/branch-checklist.org";
    attribute :>> scope="Publish one complete MVP after all first-three family receipts close. Preserve historical1/12 and2/12, current3/12 and nine later families. Keep release/still and unqualified Changes under their existing review owners.";
  }
  part models:Need {
    ref part :>> gate=GambitCommitGates::models;
    attribute :>> id="SMP-MVP-MODELS";
    attribute :>> method="native";
    attribute :>> artifact="evidence/research/retained/modern-c/frozen-568e0276-smp/submission/qualification.json";
    attribute :>> scope="Actual native SysML projection and ASCENT source/profile/manifest admission plus missing/stale/fragment and nonpositive-benefit rejection controls. Existing QNT and Lean duties are unchanged.";
  }
  part questions:Need {
    ref part :>> gate=GambitCommitGates::questions;
    attribute :>> id="SMP-MVP-QUESTIONS";
    attribute :>> method="source-analysis";
    attribute :>> artifact="dev/refactoring/modern-c/independent-smp-audit.org";
    attribute :>> scope="Explain GVM semantic/physical separation, PointId and frame preservation, tail-call and multi-shot boundaries, loader refusal, actual cost and source-period limits. Whole SMP, arbitrary CFFI, GC redesign and release speedup remain outside this delivery.";
  }
}
