package GambitStressGsiPrimitiveRefinement {
 private import ScalarValues::*;
 ref part family=GambitModernCDeliveryPlan::a6;
 attribute canonicalSource:String="65a4a2e265ef337239b09088486a2684bafa7362";
 attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
 attribute primitiveSource:String="vendor/gambit/lib/gambit/vector/vector.scm";
 attribute primitiveSha256:String="06fc9ef50203136c4e71e906c30883ad2d4f8d0baac6552d8e63db23c6d1b49d";
 attribute testSource:String="vendor/gambit/tests/unit-tests/07-vector/vector_incbang.scm";
 attribute testSha256:String="10e3494f7958510934aa552dbe123ad4d9579b758f67441189f93cbc8e6c2b13";
 attribute generatedStdSha256:String="56fe55015c54c67e0e2de4c713b443099bfc4ba3d8184778601c3984d8f5a29e";
 attribute candidateEvidence:String="evidence/research/retained/modern-c/stress-gsi/primitive-product-qualified.json";
 attribute generatedEvidence:String="evidence/research/retained/modern-c/stress-gsi/primitive-generated-interface.json";
 attribute geometryEvidence:String="evidence/research/retained/modern-c/stress-gsi/accounting-geometry.json";
 attribute accountingReview:String="evidence/research/retained/modern-c/stress-gsi/allocation-reassessment.json";
 attribute nextEnvironmentOwner:String="vendor/gambit/lib/_eval.scm::cprc-prc-req1 / macro-make-rte; refine existing CS-BRIDGE and CS-WRITERS before any deferred materialization or reuse";
 attribute reuseCorrection:String="evidence/research/retained/modern-c/stress-gsi/reuse-claim-correction.json";
 attribute rteSourceFrontier:String="evidence/research/retained/modern-c/stress-gsi/rte-source-frontier.json";
 attribute originalCaseEvidence:String="evidence/research/retained/modern-c/stress-gsi/interrupt2-original-diagnosis.json";
 attribute originalRunnerObservation:String="evidence/research/retained/modern-c/stress-gsi/interrupt2-original-runner-p1-diagnosis.json";
 attribute qualifiedP1Observation:String="evidence/research/retained/modern-c/stress-gsi/interrupt2-original-runner-p1-qualified-observation.json";
 attribute qualifiedP2Observation:String="evidence/research/retained/modern-c/stress-gsi/interrupt2-original-runner-p2-qualified-observation.json";
 attribute poolCounterexample:String="evidence/research/retained/modern-c/stress-gsi/runner-pool-counterevidence.json";
 attribute progress:String="Historical5/12 accepted; complete stress-GSI remains OPEN. Component qualification is not a producer or sixth-family receipt.";
 attribute protocol:String="Default delta1 is normalized at the callable primitive entry and delegates to the same three-argument atomic intrinsic. Descriptor and namespace stay unchanged. Original stress files are byte-identical. Extend the existing vector test only; preserve its original assertion prefix and force first-class calls through its non-inlined helper.";
 attribute formalDuty:String="Source and real C/native evidence own this argument-normalization refinement. Existing QNT temporal root/ownership and Lean frame/range laws remain unchanged; there is no new shared runtime state machine. Full same-source bootstrap/prerequisite and complete stress acceptance are separate obligations, not inferred from these component tests.";
 part def Finding { attribute id:String; attribute status:String; attribute evidence:String; attribute boundary:String; }
 part callable:Finding {
  attribute :>> id="callable-default-normalization"; attribute :>> status="SOURCE_AND_COMPONENT_NATIVE_QUALIFIED";
  attribute :>> evidence="Real generated C accepts nargs2 by setting delta to FIX1, accepts nargs3, rejects other counts, then invokes the existing VECTORINC operation without allocation.";
  attribute :>> boundary="No removed lock/check or new namespace. One additional argument-count branch in callable entry; whole runtime throughput/pause/RSS unmeasured. Other backends and full producer are not qualified.";
 }
 part controls:Finding {
  attribute :>> id="original-assertions-and-first-class-controls"; attribute :>> status="COMPONENT_NATIVE_QUALIFIED";
  attribute :>> evidence="Same extended existing fixture fails in baseline p2 GSI and GSC; candidate passes p1/p2 GSI/GSC with natural exits. Preserve18 original assertions and add8 covering omitted/explicit delta, stored result and rejected arities.";
  attribute :>> boundary="Baseline paired comparison is p2 only; p1 is additional candidate coverage. Separate unchanged original interrupt2 official-runner observations complete at actual p1 in126.50764816699666 seconds and p2 in139.1841997919837 seconds under checked framework imports, preserving all six subtests. These are independent one-case controls, never stitched into either full population or the whole300-second campaign. The earlier direct-load and different-transport observations keep their distinct scope. No full408-unit or producer qualification follows.";
 }
 part custody:Finding {
  attribute :>> id="generated-product-and-cache-custody"; attribute :>> status="COMPONENT_CUSTODY_CLOSED";
  attribute :>> evidence="Materialize the exact completed C through existing copy_changed without inheriting its stale timestamp. Planned and actual Make output must both contain zero Scheme-to-C regeneration; preserve the earlier false reuse claim and its real command echo. Recover23 unchanged byte-identical objects from authenticated archive, rebuild only std/linker objects and relink GSI. Retain16 execution product files in one stable non-source slot; all children settle and canonical/successor products restore.";
  attribute :>> boundary="Known config.status append-only log belongs to the existing Make owner; other unexpected writes still fail. Earlier source-view/cwd/write-set/environment failures and automatic-review rejection stay recorded. No hard links in the final operation and no new native workspace.";
 }
 part accounting:Finding {
  attribute :>> id="allocation-counter-interpretation"; attribute :>> status="SOURCE_AND_CONFIGURED_GEOMETRY_QUALIFIED";
  attribute :>> evidence="The movable accounting expression doubles occupied stack/heap words. Interpreted req1 materializes a3-slot RTE vector. Configured C23 static assertions confirm8-byte words and one-word vector headers; this local32-byte RTE contributes64 movable occupied units. The near diagnostic match is not a whole-workload attribution proof.";
  attribute :>> boundary="Neither allocation statistic nor cumulative extrapolation is RSS. Do not assert full TFIB allocation attribution or attainable budget improvement from the diagnostic alone. TFIB, terminate and complete p1/p2 workload remain open.";
 }
}
