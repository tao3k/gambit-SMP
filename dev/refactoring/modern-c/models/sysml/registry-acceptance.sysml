package GambitRegistryAcceptance {
  private import ScalarValues::*;
  ref part family = GambitModernCDeliveryPlan::a8;
  ref part composition = GambitSmpDevComposition::f8;
  attribute baseline:String="1b1aa854";
  attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
  attribute mode:String="native-make";
  attribute inventory:String="registry";
  attribute wholeSeconds:Integer=300;
  attribute maxCompilerRssGiB:Integer=8;
  attribute protocol:String="Execute the complete current-source shared VM registry, ordered synchronization (native and emulated), binding activation, runtime roles, globals snapshot, symkey publication, and pipe domain native targets on one sealed producer. Enforce lifetime-before-read, VM incarnation matching, live-reader drain before reclamation, and zero stale-incarnation loads.";
  attribute formalDuty:String="SysML owns Family 8 fixture identities, make targets, and retirement criteria. Quint vm_registry.qnt owns incarnation transitions, concurrent resize/reuse, held-reader exclusion, and drained-retry negatives. Lean VmRegistryRefinement.lean owns incarnation monotonicity, borrower non-reclamation, and stale-token refusal algebra. CBMC registry/incarnation-guard/harness.c owns C-level slot/generation bounds and live-borrower reclamation refusal.";
  attribute manifestPath:String="evidence/research/retained/modern-c/registry/manifest.json";
  part def Fixture { attribute target:String; attribute source:String; attribute sha256:String; attribute kind:String; }
  part case0:Fixture { attribute :>> target="test-vm-lifecycle"; attribute :>> source="vendor/gambit/tests/smp/gc/vm-lifecycle.scm"; attribute :>> sha256="5aea2c385099aecda38d33160e84c49d0736b594e6b847b507081498ae14062f"; attribute :>> kind="registry-lifecycle"; }
  part case1:Fixture { attribute :>> target="test-vm-lifecycle"; attribute :>> source="vendor/gambit/tests/smp/gc/vm-lifecycle-host.scm"; attribute :>> sha256="758b82e13c51eaf5ef334dfd5b740d3943f9bb2b8aeac0238e8693abbd9eadcc"; attribute :>> kind="registry-host"; }
  part case2:Fixture { attribute :>> target="test-ordered-sync"; attribute :>> source="vendor/gambit/tests/ordered-sync.c"; attribute :>> sha256="aaba4665709cc9fadfb18b5a4713f24e399bd9635f29e793332c88dd63b7c1e4"; attribute :>> kind="ordered-sync-native"; }
  part case3:Fixture { attribute :>> target="test-ordered-sync-emulated"; attribute :>> source="vendor/gambit/tests/ordered-sync.c"; attribute :>> sha256="aaba4665709cc9fadfb18b5a4713f24e399bd9635f29e793332c88dd63b7c1e4"; attribute :>> kind="ordered-sync-emulated"; }
  part case4:Fixture { attribute :>> target="test-binding-activation"; attribute :>> source="vendor/gambit/tests/binding-activation.scm"; attribute :>> sha256="414dbd4c2876df46e719fb5afdef56602adb2a06e3885f66e811f4596d7b164b"; attribute :>> kind="binding-activation"; }
  part case5:Fixture { attribute :>> target="test-runtime-roles"; attribute :>> source="vendor/gambit/tests/runtime-roles.c"; attribute :>> sha256="b49d87ba4de85803097461863a73dc4e3b54f37ee04b8bbc38e2f3a3bc5c8383"; attribute :>> kind="runtime-roles"; }
  part case6:Fixture { attribute :>> target="test-pipe-domain"; attribute :>> source="vendor/gambit/tests/pipe.scm"; attribute :>> sha256="a49a3a1bbbf6443c7affd8c11e99f71e13ad87692f53fd7744897e5545513ca3"; attribute :>> kind="pipe-domain"; }
}
