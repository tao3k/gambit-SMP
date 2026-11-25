package GambitStressGsi {
 private import ScalarValues::*;
 ref part family=GambitModernCDeliveryPlan::a6;
 attribute baseline:String="6c17d19032e91d1a9c5c42cbedcca65a08755297";
 attribute canonicalTree:String="65a4a2e265ef337239b09088486a2684bafa7362";
 attribute publishedTree:String="2bab7a0a19e80f8df1aa1f232c95f60e46ccd785";
 attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
 attribute producer:String="870648b81ad8dee65149b148adaa4cf8aab7f9c530cbbd3edbec7f8c1bea740b";
 attribute mode:String="gsi";
 attribute inventory:String="stress";
 attribute wholeSeconds:Integer=300;
 attribute innerSeconds:Integer=295;
 attribute processors:String="2;1";
 attribute jobs:String="2:3;1:4";
 attribute originalSuite:String="evidence/research/retained/modern-c/stress-gsi/original-whole.recipe.json";
 attribute protocol:String="Unchanged four upstream stress sources, original interpreted runner and all original parameters/assertions. Run original adaptive p2 population first, then p1 within the same300-second wall bound; unstarted work is unresolved. Existing capacity and fixed suite pool; no compilation, heap changes, timeout renewal, lowering load or result splicing.";
 attribute formalDuty:String="SysML and the installed strict OpenSysML SDK own fixture identities, topology order and original wall budget. Native completion/exit/custody evidence is separate from model inference. Existing QNT temporal ownership and Lean frame/range duties are not duplicated. Root cause determines any later runtime refinement obligation.";
 part def Fixture { attribute target:String; attribute source:String; attribute sha256:String; attribute kind:String; attribute seconds:Integer; }
 part case0:Fixture { attribute :>> target="06-thread/tfib_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/tfib_stress.scm"; attribute :>> sha256="09c974798657feb49fe4ef23d45aac10efcaa4700f19197a5e6762f8b5fbf7e9"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
 part case1:Fixture { attribute :>> target="06-thread/thread_interrupt2_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/thread_interrupt2_stress.scm"; attribute :>> sha256="0f3ec300493e0601c528676473eb4547405875c268391c2925899cac2aae5430"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
 part case2:Fixture { attribute :>> target="06-thread/thread_interrupt_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/thread_interrupt_stress.scm"; attribute :>> sha256="eb38f6c1bf8f080b04a6740977d4d12989f22b9af08b29fec758bcc8cd8ebc51"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
 part case3:Fixture { attribute :>> target="06-thread/thread_terminate_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/thread_terminate_stress.scm"; attribute :>> sha256="d21049a3b45a4a73d2aa7cc3952a76b9059688ec5099092a6bf627b22890a6e7"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
}
