package GambitVmLayoutRetirement {
 private import ScalarValues::*;
 attribute stage:String="vm-layout-retirement";
 attribute baseline:String="169b5705b73ecda570a1536e47064bf403b0e3db";
 attribute scope:String="Retire the two remaining dormant authority table templates after authority-service-retirement. Existing lifecycle activation and RC source authority remain the sole actual owners. No new padding, token registry, namespace, allocation or Scheme control semantics.";
 attribute formalDuty:String="This cut removes unreachable storage, not a transition in the entry/RC protocol. Reuse native_entry_admission.qnt, root_store_projection.qnt and existing RootSpan Lean arithmetic without duplicating them. Native C layout, actual caller census, generated module size descriptor, loader refusal and source/artifact custody are source-refinement obligations.";
 attribute sourceCases:String="unused-storage;actual-owner;descriptor-refusal;source-custody;failure-period";
 attribute requiredCases:String="baseline-module;old-refusal;new-module;roots;original-consumers;model;cost;source-custody";
 attribute refinements:String="sourceMap;moduleMap;exitMap";
 part def Refinement { attribute actions:String; attribute source:String; attribute guard:String; attribute obligation:String; attribute quint:String; attribute leanDuty:String default="No new arithmetic theorem or duplicated entry/root protocol."; }
 part sourceMap:Refinement {
  attribute :>> actions="publish;write;borrow;freeze;scan";
  attribute :>> source="lib/_c_intf/sfun-entry.inc;lib/_mem/rc-allocation.inc;lib/_setup/vm-lifecycle.inc;include/_gambit/vm_state.h.in;include/_gambit/write_authority.h.in";
  attribute :>> guard="The deleted type and field have no remaining HEAD or generated runtime readers/writers. Actual activation/source fields and algorithms remain byte-identical. A naming search alone is not an ownership proof; build/archive and real consumers must agree.";
  attribute :>> obligation="VM-LAYOUT-OWNER";
  attribute :>> quint="dev/refactoring/modern-c/models/quint/native_entry_admission.qnt;dev/refactoring/modern-c/models/quint/root_store_projection.qnt";
 }
 part moduleMap:Refinement {
  attribute :>> actions="describe;checkSize;rejectOld;loadNew";
  attribute :>> source="include/_gambit/module_generation.h.in;lib/setup.c setup_module;GSC generated C descriptors";
  attribute :>> guard="Every retained native object is invalidated after the composed header changes. Existing module size check rejects an unchanged old module before fixup. New module compiled with its own complete header/archive runs. Independently compiled application and module layout absolutes are not interchangeable.";
  attribute :>> obligation="VM-LAYOUT-ABI";
  attribute :>> quint="No distributed protocol added; native module producer/loader source refinement only.";
 }
 part exitMap:Refinement {
  attribute :>> actions="revoke;returnBorrow;physicalExit;retire";
  attribute :>> source="Existing lifecycle/RC physical last-use and scan leases; actual SFUN/RC/frame consumers";
  attribute :>> guard="No stop, join, permission or reclamation right follows from removing unused bytes. All existing physical exit/unknown owner assumptions remain. Multi-shot continuation root and dynamic-wind semantics are unchanged.";
  attribute :>> obligation="VM-LAYOUT-CONSUMERS";
  attribute :>> quint="dev/refactoring/modern-c/models/quint/native_entry_admission.qnt";
 }
 part def Obligation { attribute id:String; attribute status:String; attribute premise:String; }
 attribute obligations:String="owner;abi;consumers;originals;reuse;costProof;sourceProof";
 part owner:Obligation { attribute :>> id="VM-LAYOUT-OWNER"; attribute :>> status="CLOSED"; attribute :>> premise="Exact caller/writer census and existing actual authority; no unused slot protocol survives."; }
 part abi:Obligation { attribute :>> id="VM-LAYOUT-ABI"; attribute :>> status="CLOSED"; attribute :>> premise="Old compiled module executes on baseline, rejects on candidate, new module executes; actual compiler context distinguishes absolute layout measurements."; }
 part consumers:Obligation { attribute :>> id="VM-LAYOUT-CONSUMERS"; attribute :>> status="CLOSED"; attribute :>> premise="Actual SFUN/RC PBT replay/shrink and frame/map multi-shot GC consumers run against rebuilt products."; }
 part originals:Obligation { attribute :>> id="VM-LAYOUT-ORIGINALS"; attribute :>> status="CLOSED"; attribute :>> premise="Original population and focused division in identical conditions; retain historical combined experiment separately and never infer its cause from a later pass."; }
 part reuse:Obligation { attribute :>> id="VM-LAYOUT-REUSE"; attribute :>> status="CLOSED"; attribute :>> premise="Same cache/profile, all51 generated artifacts unchanged, actual native objects rebuilt after ABI change and old seed retained."; }
 part costProof:Obligation { attribute :>> id="VM-LAYOUT-COST"; attribute :>> status="CLOSED"; attribute :>> premise="Native VM/GSTATE bytes and unchanged RC/activation/context sizes; fixed4096-call matched cohorts, no stable speedup without causal evidence."; }
 part sourceProof:Obligation { attribute :>> id="VM-LAYOUT-SOURCE"; attribute :>> status="CLOSED"; attribute :>> premise="Exact two-template selected source, old/index/working dispositions and nine-group queue preserve unrelated changes."; }
 part submission:GambitCommitGates::SubmissionUnit { attribute :>> kind="integration"; attribute :>> result="vm-layout-retirement"; attribute :>> progressDelta=1; attribute :>> supportPaths=""; }
 part def Need { ref part gate:GambitCommitGates::Gate; attribute id:String; attribute method:String; attribute artifact:String; attribute scope:String; }
 part tests:Need { ref part :>> gate=GambitCommitGates::tests; attribute :>> id="VM-LAYOUT-TESTS"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/vm-layout-retirement/qualification.json"; attribute :>> scope="Complete changed-layout native producer, actual roots/entry/exit and module consumers, fixed populations."; }
 part learning:Need { ref part :>> gate=GambitCommitGates::learning; attribute :>> id="VM-LAYOUT-LEARNING"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/vm-layout-retirement.org"; attribute :>> scope="Runtime authority belongs to actual source/activation, not an independent fixed identity table."; }
 part process:Need { ref part :>> gate=GambitCommitGates::process; attribute :>> id="VM-LAYOUT-PROCESS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/vm-layout-retirement.org"; attribute :>> scope="One complete VM representation owner; separate historical framework failures and independent SMP1/12."; }
 part models:Need { ref part :>> gate=GambitCommitGates::models; attribute :>> id="VM-LAYOUT-MODELS"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/vm-layout-retirement/qualification.json"; attribute :>> scope="Native OpenSysML SDK and ASCENT source-bound obligations; no duplicate QNT or Lean."; }
 part questions:Need { ref part :>> gate=GambitCommitGates::questions; attribute :>> id="VM-LAYOUT-QUESTIONS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/vm-layout-retirement.org"; attribute :>> scope="ABI invalidation, shared semantics/multi-shot roots, old failure attribution, exact net memory versus unproved speed benefit."; }
}
