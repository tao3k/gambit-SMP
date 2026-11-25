package GambitStressGsc {
 private import ScalarValues::*;
 ref part family=GambitModernCDeliveryPlan::a7;
 attribute baseline:String="6c17d19032e91d1a9c5c42cbedcca65a08755297";
 attribute sourceTree:String="fdfec33a";
 attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
 attribute mode:String="gsc";
 attribute inventory:String="stress";
 attribute wholeSeconds:Integer=300;
 attribute innerSeconds:Integer=295;
 attribute maxCompilerRssGiB:Integer=8;
 attribute processors:String="2;1";
 attribute jobs:String="2:3;1:4";
 attribute compiledValidationContract:String="Three-phase scheme-to-c (.c) and c-to-dynamic-module (.o1) SHA-256 artifact binding, independent Compiled-Host Translation Validation (write-group dominance, RETI/RETN/IFD descriptor decoding, post-safepoint R_HEAP reload, not-safe back-edge POLL retention), 5 mutated-host negative controls, and native .o1 wire-trace controls on the exact same sealed producer.";
 attribute protocol:String="Unchanged four upstream stress sources, original compiled runner (run-unit-tests.scm -gsc -stress), and all original parameters and assertions. Run original adaptive p2/jobs=3 population first, then p1/jobs=4 within one shared 295/300-second wall clock; unstarted work is unresolved. Peak compiler RSS must stay strictly below 8 GiB; no heap changes, timeout renewal, load reduction, or result splicing.";
 attribute formalDuty:String="SysML and the installed strict OpenSysML SDK own fixture identities, topology order, wall budget, and RSS cap. Quint compiled_host_admission.qnt owns concurrent .o1 admission, shortage/GC/reload, cross-module interrupt settlement, and back-edge poll histories. Lean CompiledHostRefinement.lean owns basic-block dominance, descriptor soundness, and <6000-label guard observational equivalence. CBMC owns Fix 1C register scrub and C macro equivalence. Native completion, artifact hashes, and process custody remain separate empirical evidence.";
 part def Fixture { attribute target:String; attribute source:String; attribute sha256:String; attribute kind:String; attribute seconds:Integer; }
 part case0:Fixture { attribute :>> target="06-thread/tfib_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/tfib_stress.scm"; attribute :>> sha256="09c974798657feb49fe4ef23d45aac10efcaa4700f19197a5e6762f8b5fbf7e9"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
 part case1:Fixture { attribute :>> target="06-thread/thread_interrupt2_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/thread_interrupt2_stress.scm"; attribute :>> sha256="0f3ec300493e0601c528676473eb4547405875c268391c2925899cac2aae5430"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
 part case2:Fixture { attribute :>> target="06-thread/thread_interrupt_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/thread_interrupt_stress.scm"; attribute :>> sha256="eb38f6c1bf8f080b04a6740977d4d12989f22b9af08b29fec758bcc8cd8ebc51"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
 part case3:Fixture { attribute :>> target="06-thread/thread_terminate_stress.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/thread_terminate_stress.scm"; attribute :>> sha256="d21049a3b45a4a73d2aa7cc3952a76b9059688ec5099092a6bf627b22890a6e7"; attribute :>> kind="original-stress"; attribute :>> seconds=0; }
}
