package GambitGerbilAcceptance {
  private import ScalarValues::*;
  ref part family = GambitModernCDeliveryPlan::a11;
  ref part composition = GambitSmpDevComposition::f11;
  attribute baseline:String="1b1aa854";
  attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
  attribute mode:String="gerbil-consumer";
  attribute inventory:String="gerbil";
  attribute stages:String="boot-gxi;stage0;stage1;stdlib;libgerbil;lang;tools;correctness";
  attribute maxCompilerRssGiB:Integer=8;
  attribute protocol:String="Bind the pinned Gerbil consumer stages (boot-gxi, stage0, stage1, stdlib, libgerbil, lang, tools, correctness) and exact gambit_smp.gerbil_build implementation identity to one sealed Gambit producer (exact gsi/gsc/libgambit.a/gambit.h SHA-256 and runtime capability profile). Refuse mixed generated/runtime images, detached cache reuse, or unsealed external overrides; partial consumer runs remain scoped.";
  attribute formalDuty:String="Adversarial architecture-challenge models (not passive sync): SysML owns Family 11 downstream stage closure and 4-way dynamic .o1 ABI export policy. Quint gerbil_consumer_closure.qnt challenges stage invalidation, dynamicAbiClosed (___IMP_FUNC/___GSTATE/setup.c/___EXT incl. ___publish_raw_stack_span), mixed-image refusal, and partial-stage non-promotion. Lean GerbilProducerClosure.lean proves 0-sorry transitive 8-stage producer closure and unexported-symbol rejection. CBMC gerbil/abi-seal-check/harness.c and ASCENT-routed abi-closure-auditor exhaustively challenge all 329+ ___IMP_FUNC macro call sites against bare dynamic .o1 leaks.";
  attribute manifestPath:String="evidence/research/retained/modern-c/gerbil/manifest.json";
  part def StageSpec { attribute ordinal:Integer; attribute name:String; attribute requiresPrevious:Boolean; attribute consumesGambitAbi:Boolean; }
  part s0:StageSpec { attribute :>> ordinal=0; attribute :>> name="boot-gxi"; attribute :>> requiresPrevious=false; attribute :>> consumesGambitAbi=true; }
  part s1:StageSpec { attribute :>> ordinal=1; attribute :>> name="stage0"; attribute :>> requiresPrevious=true; attribute :>> consumesGambitAbi=true; }
  part s2:StageSpec { attribute :>> ordinal=2; attribute :>> name="stage1"; attribute :>> requiresPrevious=true; attribute :>> consumesGambitAbi=true; }
  part s3:StageSpec { attribute :>> ordinal=3; attribute :>> name="stdlib"; attribute :>> requiresPrevious=true; attribute :>> consumesGambitAbi=true; }
  part s4:StageSpec { attribute :>> ordinal=4; attribute :>> name="libgerbil"; attribute :>> requiresPrevious=true; attribute :>> consumesGambitAbi=true; }
  part s5:StageSpec { attribute :>> ordinal=5; attribute :>> name="lang"; attribute :>> requiresPrevious=true; attribute :>> consumesGambitAbi=true; }
  part s6:StageSpec { attribute :>> ordinal=6; attribute :>> name="tools"; attribute :>> requiresPrevious=true; attribute :>> consumesGambitAbi=true; }
  part s7:StageSpec { attribute :>> ordinal=7; attribute :>> name="correctness"; attribute :>> requiresPrevious=true; attribute :>> consumesGambitAbi=true; }
}
