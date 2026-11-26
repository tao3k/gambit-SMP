package GambitGcFfiAcceptance {
  private import ScalarValues::*;
  ref part family = GambitModernCDeliveryPlan::a10;
  ref part composition = GambitSmpDevComposition::f10;
  attribute baseline:String="1b1aa854";
  attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
  attribute mode:String="native-make";
  attribute inventory:String="gc-ffi";
  attribute wholeSeconds:Integer=300;
  attribute maxCompilerRssGiB:Integer=8;
  attribute protocol:String="Execute original upstream test7 (mem.scm), test8 (client.c + server.scm), test9 (dynamic mem.o1), plus test-sfun-entry (all 6 modes), test-marker-input, test-root-task (all 9 modes), test-symkey-views, test-symkey-callback, test-rest-parameters, test-frame-contract, test-entry, test-rc-roots, test-collector-diagnostics, and W<R worker-arena/worker-root-domains checks on one sealed producer. Verify moving roots, nested callbacks, nonlocal unwind, slot-oracle missed-root detection, and W<R worker-root decoupling.";
  attribute formalDuty:String="Adversarial architecture-challenge models (not passive sync): SysML owns Family 10 GC/FFI inventory and worker/root decoupling contracts. Quint ffi_root_admission.qnt, gc_ffi_worker_domain.qnt, and v2/gc_ffi_worker_domain_v2.qnt challenge moving-root admission, W<R worker-root conservation, primary P0 contiguous live-carrier prefix, overflow demand retirement, physical-exit SFUN borrow custody, raw-F64 scrub, and slot-oracle missed-root detection via mutation-killing falsifiers. Lean GcFfiRootRefinement.lean and RawF64ScrubRefinement.lean prove 0-sorry conservation, contiguous live-executor soundness, double-retry spill preservation, and negative-control counterexamples. CBMC gc-ffi/entry-root-bundle/harness.c challenges C-level EntryRootBundle, non-contiguous launch gaps, and IEEE-754 double-retry carrier hygiene.";
  attribute manifestPath:String="evidence/research/retained/modern-c/gc-ffi/manifest.json";
  part def Fixture { attribute target:String; attribute source:String; attribute sha256:String; attribute kind:String; }
  part case0:Fixture { attribute :>> target="test7"; attribute :>> source="vendor/gambit/tests/mem.scm"; attribute :>> sha256="0467a127ffc863289935c59f1e37d20c7392f50d47e75fb02fdd49c21951a387"; attribute :>> kind="upstream-gc-ffi"; }
  part case1:Fixture { attribute :>> target="test8"; attribute :>> source="vendor/gambit/tests/client.c"; attribute :>> sha256="35ed57764f27d99723d4847e717b1d905b90bc9c0511cf342382df8c8885fd77"; attribute :>> kind="upstream-c-server"; }
  part case2:Fixture { attribute :>> target="test8"; attribute :>> source="vendor/gambit/tests/server.scm"; attribute :>> sha256="38e61258ad9a780767f417b9204466e663f41422799e43633e37674e855f1d76"; attribute :>> kind="upstream-c-server"; }
  part case3:Fixture { attribute :>> target="test9"; attribute :>> source="vendor/gambit/tests/mem.scm"; attribute :>> sha256="0467a127ffc863289935c59f1e37d20c7392f50d47e75fb02fdd49c21951a387"; attribute :>> kind="upstream-dynamic-o1"; }
  part case4:Fixture { attribute :>> target="test-sfun-entry"; attribute :>> source="vendor/gambit/tests/sfun-entry.scm"; attribute :>> sha256="bbbc8b9344c28c97459d60aa27074944db6a8eeb4eb451035a97412f70ebba0a"; attribute :>> kind="sfun-entry-roots"; }
  part case5:Fixture { attribute :>> target="test-root-task"; attribute :>> source="vendor/gambit/tests/root-task.scm"; attribute :>> sha256="be6a8406fece6b95596786787a1cabd13e0558949672e075bdb867510a193063"; attribute :>> kind="root-task-union"; }
  part case6:Fixture { attribute :>> target="test-rc-roots"; attribute :>> source="vendor/gambit/tests/rc-root-origin.scm"; attribute :>> sha256="df9b9270beb0ed0eef9d045dc7e6174b1aaad4888b184b79696f8f5d81945567"; attribute :>> kind="rc-root-origin"; }
  part case7:Fixture { attribute :>> target="test-frame-contract"; attribute :>> source="vendor/gambit/tests/frame-contract.c"; attribute :>> sha256="e1512da1f211f9e0734de7b0e1bfd0d83d2be86e6abd8313e34d65afafcde5fe"; attribute :>> kind="frame-contract"; }
  part case8:Fixture { attribute :>> target="test-entry"; attribute :>> source="vendor/gambit/tests/test-entry.c"; attribute :>> sha256="5b2064ce6ff4c78adc5fb5ba6dbd2eb3bf0fcd9cecba74b2a53fd7d5211d9e08"; attribute :>> kind="entry-boundary"; }
  part case9:Fixture { attribute :>> target="test-collector-diagnostics"; attribute :>> source="vendor/gambit/tests/collector-diagnostics.c"; attribute :>> sha256="d09106c011802b47df321253cd9e0991c0e4c1322005b3cb1941a0ddc295494c"; attribute :>> kind="collector-diagnostics"; }
  part case10:Fixture { attribute :>> target="test-rest-parameters"; attribute :>> source="vendor/gambit/tests/smp/gc/rest-parameter-semantics.scm"; attribute :>> sha256="bda9867064a748c0c92ce84817973d875dbf3558b2fc5a2bbebc8e5ad6fc7562"; attribute :>> kind="rest-parameters"; }
  part case11:Fixture { attribute :>> target="worker-root-domains"; attribute :>> source="vendor/gambit/tests/smp/gc/worker-root-domains.scm"; attribute :>> sha256="f14bacf61b52402e091662e4e1ea1c46864f9061e5127944a18985dae32f7adc"; attribute :>> kind="worker-decoupling"; }
}
