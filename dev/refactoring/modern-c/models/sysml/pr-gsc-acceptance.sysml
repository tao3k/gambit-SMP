package GambitPrGsc {
 private import ScalarValues::*;
 ref part family=GambitModernCDeliveryPlan::a5;
 attribute baseline:String="7f2ede964e9f2269d0fe47d773be76e72d2a6cbf";
 attribute canonicalTree:String="65a4a2e265ef337239b09088486a2684bafa7362";
 attribute publishedTree:String="dd4a2349de1e3132b52c426fcfb33669b5b0e0e5";
 attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
 attribute producer:String="870648b81ad8dee65149b148adaa4cf8aab7f9c530cbbd3edbec7f8c1bea740b";
 attribute wholeSeconds:Integer=300;
 attribute innerSeconds:Integer=295;
 attribute processors:String="1;2";
 attribute jobs:String="1:5;2:3";
 attribute mode:String="gsc";
 attribute controlRefinementEvidence:String="evidence/research/retained/modern-c/pr-gsc/control-refinement.json";
 attribute legacySuite:String="evidence/research/retained/modern-c/pr-gsi/original-full-suite.recipe.json";
 attribute originalSuite:String="evidence/research/retained/modern-c/pr-gsc/original-compiled.recipe.json";
 attribute threadCompletionSeconds:Integer=120;
 attribute threadCompletionFiles:String="06-thread/thread_interrupt.scm";
 attribute originalSelection:String="evidence/research/retained/modern-c/pr-gsi/original-pr-selection.recipe.json";
 attribute protocol:String="Original compiled unit-test harness and runner; independent compilation/loading in fixture processes, exact completed-file counters, actual topology probes and original300/295-second global limits. Per-file limits retain interpreted PR guards and the compiled pipe60-second guard; preserve the original120-second thread-completion group over the selected control. One shared deadline covers both required topologies. No patch application, source substitution, extra executor, heap increase or timeout extension.";
 attribute requestProjection:String="producer-thread-request-constructor";
 attribute requestProjectionEvidence:String="evidence/research/retained/modern-c/pr-gsi/request-constructor-refinement.json";
 attribute formalDuty:String="This is native consumer qualification of published C/GVM semantics; no collector or scheduler protocol changes. QNT keeps temporal ownership duties; Lean keeps frame/range laws. Neither substitutes for original native fixture execution.";
 part def Fixture { attribute target:String; attribute source:String; attribute sha256:String; attribute kind:String; attribute seconds:Integer; }
 part case0:Fixture { attribute :>> target="12-os/process_spawn.scm"; attribute :>> source="models/gambit/native/process_spawn.scm"; attribute :>> sha256="eba139d1aa995cc78e53891d5bcf93fd7ce33eff08f6080f52efb78a8f5c98c7"; attribute :>> kind="additional"; attribute :>> seconds=0; }
 part case1:Fixture { attribute :>> target="06-thread/thread_interrupt_ended.scm"; attribute :>> source="models/gambit/native/pr1047/thread_interrupt_ended.scm"; attribute :>> sha256="5034a9937f3ac8df8dddf5182d48a08b0cac095bd239355b97de638768b73a6d"; attribute :>> kind="additional"; attribute :>> seconds=20; }
 part case2:Fixture { attribute :>> target="09-io/pipe_concurrent.scm"; attribute :>> source="models/gambit/native/pr1037/pipe_concurrent_read_deadline.scm"; attribute :>> sha256="760513881622cd51bbf258eebd8ac09562ef85e4f84330c33fbc1020df366f93"; attribute :>> kind="additional"; attribute :>> seconds=60; }
 part case3:Fixture { attribute :>> target="10-tables/serialization.scm"; attribute :>> source="models/gambit/native/pr1038/serialization.scm"; attribute :>> sha256="ef42cdb7b317e44baf7cd435438383447ca462284f95f63b46aa867f45c17baa"; attribute :>> kind="additional"; attribute :>> seconds=0; }
 part case4:Fixture { attribute :>> target="10-tables/serialization_gc.scm"; attribute :>> source="models/gambit/native/pr1038/serialization_gc.scm"; attribute :>> sha256="6d1e709df3fde6dce5d99a34d9309d49434d45440924c8b1e5f47c9144de7741"; attribute :>> kind="additional"; attribute :>> seconds=60; }
 part case5:Fixture { attribute :>> target="06-thread/thread_interrupt.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/06-thread/thread_interrupt.scm"; attribute :>> sha256="af61e64661fa33fc809bbabdcea74c648d7028a60bddf6a3911b91cbcc561f1d"; attribute :>> kind="source-refined-control"; attribute :>> seconds=0; }
 part case6:Fixture { attribute :>> target="09-io/write_shared.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/09-io/write_shared.scm"; attribute :>> sha256="8890f435a99778a441c1d0ca9c578d4e02fccbbe88c170ec84114db853e2f86d"; attribute :>> kind="original-control"; attribute :>> seconds=0; }
 part case7:Fixture { attribute :>> target="10-tables/table-search.scm"; attribute :>> source="vendor/gambit/tests/unit-tests/10-tables/table-search.scm"; attribute :>> sha256="f6b99bea276edc4217e2a36a9b3c544a06e05efd42f82d2990a315bf9507aafa"; attribute :>> kind="original-control"; attribute :>> seconds=0; }
}
