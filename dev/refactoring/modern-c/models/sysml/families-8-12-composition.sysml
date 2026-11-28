package GambitFamilies8To12Composition {
  private import ScalarValues::*;
  ref part p02 = GambitBindingReadActivationP02::fastPrimitiveRef;
  ref part f8Acceptance = GambitRegistryAcceptance::family;
  ref part f9Acceptance = GambitLifecycleAcceptance::family;
  ref part f10Acceptance = GambitGcFfiAcceptance::family;
  ref part f11Acceptance = GambitGerbilAcceptance::family;
  ref part f12Acceptance = GambitReleaseAcceptance::family;
  attribute scope:String="Unified SysML v2 composition for Families 8 through 12 plus P0-2 binding-read activation and Stage 10 unconditional dynamic ABI. Extends GambitSmpDevComposition additively so sealed Family 7 (stress-gsc) input hashes remain cryptographically intact.";
  attribute nonSplicingRule:String="Families 8-12 proofs and same-producer receipts never splice cross-source credit into the 5/12 same-source prefix ledger until Families 2-5 are re-signed on the identical source tree and sealed producer.";
  part def FormalBinding {
    attribute ordinal:Integer;
    attribute familyName:String;
    attribute sysmlModel:String;
    attribute quintModel:String;
    attribute leanModel:String;
    attribute cbmcHarness:String;
    attribute manifest:String;
  }
  part bindP02:FormalBinding {
    attribute :>> ordinal=0;
    attribute :>> familyName="p0-2-binding-read";
    attribute :>> sysmlModel="dev/refactoring/modern-c/models/sysml/binding-read-activation-p02.sysml";
    attribute :>> quintModel="dev/refactoring/modern-c/models/quint/binding_read_activation.qnt";
    attribute :>> leanModel="dev/refactoring/modern-c/models/lean/BindingReadActivationRefinement.lean";
    attribute :>> cbmcHarness="tests/contracts/modern-c/binding-read/activation-equivalence/harness.c";
    attribute :>> manifest="evidence/research/retained/modern-c/registry/manifest.json";
  }
  part bind8:FormalBinding {
    attribute :>> ordinal=8;
    attribute :>> familyName="registry";
    attribute :>> sysmlModel="dev/refactoring/modern-c/models/sysml/registry-acceptance.sysml";
    attribute :>> quintModel="dev/refactoring/modern-c/models/quint/vm_registry.qnt";
    attribute :>> leanModel="dev/refactoring/modern-c/models/lean/VmRegistryRefinement.lean";
    attribute :>> cbmcHarness="tests/contracts/modern-c/registry/incarnation-guard/harness.c";
    attribute :>> manifest="evidence/research/retained/modern-c/registry/manifest.json";
  }
  part bind9:FormalBinding {
    attribute :>> ordinal=9;
    attribute :>> familyName="lifecycle";
    attribute :>> sysmlModel="dev/refactoring/modern-c/models/sysml/lifecycle-acceptance.sysml";
    attribute :>> quintModel="dev/refactoring/modern-c/models/quint/vm_resize_transaction.qnt";
    attribute :>> leanModel="dev/refactoring/modern-c/models/lean/VmLifecycleClosureRefinement.lean";
    attribute :>> cbmcHarness="tests/contracts/modern-c/lifecycle/unknown-join-isolation/harness.c";
    attribute :>> manifest="evidence/research/retained/modern-c/lifecycle/manifest.json";
  }
  part bind10:FormalBinding {
    attribute :>> ordinal=10;
    attribute :>> familyName="gc-ffi";
    attribute :>> sysmlModel="dev/refactoring/modern-c/models/sysml/gc-ffi-acceptance.sysml";
    attribute :>> quintModel="dev/refactoring/modern-c/models/quint/gc_ffi_worker_domain.qnt";
    attribute :>> leanModel="dev/refactoring/modern-c/models/lean/GcFfiRootRefinement.lean";
    attribute :>> cbmcHarness="tests/contracts/modern-c/gc-ffi/entry-root-bundle/harness.c";
    attribute :>> manifest="evidence/research/retained/modern-c/gc-ffi/manifest.json";
  }
  part bind11:FormalBinding {
    attribute :>> ordinal=11;
    attribute :>> familyName="gerbil";
    attribute :>> sysmlModel="dev/refactoring/modern-c/models/sysml/gerbil-acceptance.sysml";
    attribute :>> quintModel="dev/refactoring/modern-c/models/quint/gerbil_consumer_closure.qnt";
    attribute :>> leanModel="dev/refactoring/modern-c/models/lean/GerbilProducerClosure.lean";
    attribute :>> cbmcHarness="tests/contracts/modern-c/gerbil/abi-seal-check/harness.c";
    attribute :>> manifest="evidence/research/retained/modern-c/gerbil/manifest.json";
  }
  part bind12:FormalBinding {
    attribute :>> ordinal=12;
    attribute :>> familyName="release";
    attribute :>> sysmlModel="dev/refactoring/modern-c/models/sysml/release-acceptance.sysml";
    attribute :>> quintModel="dev/refactoring/modern-c/models/quint/release_cohort_admission.qnt";
    attribute :>> leanModel="dev/refactoring/modern-c/models/lean/ReleaseCohortAlgebra.lean";
    attribute :>> cbmcHarness="";
    attribute :>> manifest="evidence/research/retained/modern-c/release/manifest.json";
  }
}
