package GambitLifecycleAcceptance {
  private import ScalarValues::*;
  ref part family = GambitModernCDeliveryPlan::a9;
  ref part composition = GambitSmpDevComposition::f9;
  attribute baseline:String="1b1aa854";
  attribute profile:String="884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69";
  attribute mode:String="native-make";
  attribute inventory:String="lifecycle";
  attribute wholeSeconds:Integer=300;
  attribute maxCompilerRssGiB:Integer=8;
  attribute protocol:String="Execute all 10 fault modes of test-startup-publication (--nonzero, --marker-gc, --calibration, --early-retire, --unknown, --unknown-create, --unknown-expanded, --unknown-retire, --unknown-requester, --unknown-vm), test-vm-lifecycle, test-mutex-suspension (p1 and p2 priority/cycle/queue/handoff), and unknown-join-worker-domains on one sealed producer. Verify healthy-VM GC completes while unknown-join custody retains its roots and native debt without premature free.";
  attribute formalDuty:String="Adversarial architecture-challenge models (not passive sync): SysML owns Family 9 fault-injection matrix and custody separation rules. Quint vm_resize_transaction.qnt, startup_custody.qnt, and v2/smp_migration_and_wills_v2.qnt challenge reserve/create/commit/rollback/unknown histories, cross-core c-define migration pinning, and non-reentrant will finalization via mutation-killing falsifiers. Lean VMResizeTransaction.lean, StartupCustody.lean, VmLifecycleClosureRefinement.lean, and RawF64ScrubRefinement.lean prove 0-sorry disjoint healthy-VM GC progress, generation-guarded retry custody, and raw-F64 GC-root safety. CBMC lifecycle/unknown-join-isolation/harness.c challenges C-level unknown-join bitmask/refcount retention and healthy-VM collection independence.";
  attribute manifestPath:String="evidence/research/retained/modern-c/lifecycle/manifest.json";
  part def Fixture { attribute target:String; attribute source:String; attribute sha256:String; attribute kind:String; }
  part case0:Fixture { attribute :>> target="test-startup-publication"; attribute :>> source="vendor/gambit/tests/startup-publication.scm"; attribute :>> sha256="3b42b8305e66cd0ad50b45ffa06dc7bbf3aa29dd136f6e6f8459930b24bfaab6"; attribute :>> kind="startup-fault-custody"; }
  part case1:Fixture { attribute :>> target="test-vm-lifecycle"; attribute :>> source="vendor/gambit/tests/smp/gc/vm-lifecycle.scm"; attribute :>> sha256="5aea2c385099aecda38d33160e84c49d0736b594e6b847b507081498ae14062f"; attribute :>> kind="vm-lifecycle"; }
  part case2:Fixture { attribute :>> target="test-mutex-suspension"; attribute :>> source="vendor/gambit/tests/mutex-suspension.scm"; attribute :>> sha256="240deb17f5a9999e082eb3ab4f1951f5a4d6859c4b698e83c1e4a9c001585776"; attribute :>> kind="mutex-suspension"; }
  part case3:Fixture { attribute :>> target="unknown-join-worker-domains"; attribute :>> source="vendor/gambit/tests/smp/gc/unknown-join-worker-domains.scm"; attribute :>> sha256="98f8362b0d7754b6de44faebba74f3a37a84ecceb58a0ae73c4368e5ab983df3"; attribute :>> kind="unknown-join-isolation"; }
}
