package GambitBindingActivation {
  private import ScalarValues::*;
  attribute scope:String="One complete post-foundation binding-read owner: context admission, module publication, cooperative freeze/refresh, exit drain, raw-native boundary and measured cost. No scheduler/GC-capacity redesign or SMP credit.";
  attribute baseline:String="b39f694498c5dec23dcbffd21ffaeb58e57a49ce";
  attribute status:String="LOCAL_ADMITTED_COMPLETE_OWNER";
  attribute progress:String="Prior foundation4/4 and independent SMP1/12 checkpoints unchanged. This complete post-foundation unit passed five gates and49 rejection controls in a9b896c4; its source/native obligations do not promote a whole SMP family.";
  attribute formalDuty:String="Reuse native_entry_admission.qnt for native owner/root/freeze obligations and global_module_unload.qnt for borrowing/drain lifetime. module_fixup.qnt alone covers the new shared fixup publication protocol, with ghost caller identities and no C identity table. The new C VM-identity capability must refine the existing entry/root premises; existing model success alone is not that refinement. Lean retains representation/root laws; no duplicate state-machine proof or new theorem is claimed.";
  attribute authority:String="SysML owns this complete scope and its obligations; ASCENT joins exact source/profile/native facts after actual source/native qualification. Ambient LLM reviews caller closure and conditional memory-order reasoning; it cannot turn a missing run into evidence.";
  part def Component { attribute source:String; attribute responsibility:String; attribute lifetime:String; attribute protocol:String default = ""; attribute refinement:String default = ""; }
  part context:Component {
    attribute :>> protocol="dev/refactoring/modern-c/models/quint/native_entry_admission.qnt";
    attribute :>> refinement="Generated hosts consume actual retained entry/root ownership; clearing/refreshing one native VM pointer adds no protocol state or moving Scheme root.";
    attribute :>> source="vendor/gambit/lib/_setup/vm-registry.inc;vendor/gambit/include/_gambit/processor_state.h.in";
    attribute :>> responsibility="lifecycle_enter authenticates current processor/TLS/native owner and owns nested entry counts. A generated host borrows the stable native VM identity from its authenticated context. Actual entry counts and RootTask epoch/state are the sole authority; duplicate permit/epoch fields and the per-host admission hook are retired.";
    attribute :>> lifetime="Last leave, cooperative root freeze and context close revoke the permit. A refreshed permit cannot mint a new lifecycle entry.";
  }
  part module:Component {
    attribute :>> protocol="dev/refactoring/modern-c/models/quint/module_fixup.qnt";
    attribute :>> refinement="QNT claim/complete/refuse/unknown/publish map to guarded C fixup claim, release completion and acquire descriptor guard. Owner/winner are ghost call identities; no new C table.";
    attribute :>> source="vendor/gambit/lib/_mem/binding-views.inc;vendor/gambit/lib/setup.c;vendor/gambit/include/_gambit/module_generation.h.in";
    attribute :>> responsibility="Claim shared fixup under global_gate, initialize outside it and release READY after success. setup_module_collect_moddescrs acquires READY before exposing executable descriptors. Reads acquire the current existing directory; no module/directory cache or per-binding allocation remains.";
    attribute :>> lifetime="The context stores only a native VM identity. Existing pages remain sole cell and scan owners; directory growth retains prior pages. Stable VM identity may be borrowed locally during one host activation; no moving Scheme value is cached.";
  }
  part roots:Component {
    attribute :>> source="vendor/gambit/lib/_mem/root-tasks.inc;vendor/gambit/lib/_mem/rc-allocation.inc";
    attribute :>> responsibility="Clear the context identity before its source becomes frozen. Keep existing six-domain scan coverage; the native VM identity is not an additional Scheme root bank. Reopen only after exact root-task completion, physical restore and round release.";
    attribute :>> lifetime="GC updates cells read through the view. Existing entry/collective synchronization orders the owner-only identity field; no extra per-host atomic is required. Directory, ordinary value, primitive presence/value and PRMCELL template loads retain acquire semantics.";
  }
  part retirement:Component {
    attribute :>> protocol="dev/refactoring/modern-c/models/quint/global_module_unload.qnt";
    attribute :>> refinement="The existing entry/native/root drain retains VM and image lifetime. This cut clears context identity before last entry release and does not authorize a new unload operation.";
    attribute :>> source="vendor/gambit/lib/_setup/vm-lifecycle.inc;vendor/gambit/lib/_mem/memory-lifecycle.inc";
    attribute :>> responsibility="Revoke before closing context ownership; retain the existing VM pages/directories until entry/root/worker/cleanup debt drains. Unknown cleanup/owner outcomes retain the owning VM storage rather than exposing freed addresses.";
    attribute :>> lifetime="No callback or Scheme effect runs under the module publication gate. Public raw primitive/global services retain their checked native owner boundary; the private host hook is not a raw entry API.";
  }
  ref part executionContext = context;
  ref part moduleAddresses = module;
  ref part frozenRoots = roots;
  ref part vmRetirement = retirement;
  attribute obligations:String="admission;publication;scan;exitDrain;property;cost;models;emission";
  part def Obligation { attribute id:String; attribute status:String; attribute evidence:String; attribute premise:String; }
  part admission:Obligation { attribute :>> id="BA-ADMISSION"; attribute :>> status="CLOSED"; attribute :>> evidence="evidence/research/retained/modern-c/binding-activation/observation.json"; attribute :>> premise="All generated-host entrances, native callbacks and tail/trampoline transfers are covered by authenticated lifecycle ownership; no unregistered carrier can borrow the private hook."; }
  part publication:Obligation { attribute :>> id="BA-PUBLICATION"; attribute :>> status="CLOSED"; attribute :>> evidence="evidence/research/retained/modern-c/binding-activation/observation.json"; attribute :>> premise="Partial/unknown module fixup never publishes READY. This design allocates no view metadata; existing directory allocation failure leaves prior storage valid. The finite concurrent fixup protocol is checked by TLC; the native malformed-module case qualifies failure before descriptor publication. This is not a native exploration of all interleavings."; }
  part scan:Obligation { attribute :>> id="BA-SCAN"; attribute :>> status="CLOSED"; attribute :>> evidence="evidence/research/retained/modern-c/binding-activation/observation.json"; attribute :>> premise="Address views introduce no Scheme payload roots; the existing root census includes all ordinary cells and active primitive overrides across collection and repeated restoration."; }
  part exitDrain:Obligation { attribute :>> id="BA-EXIT"; attribute :>> status="CLOSED"; attribute :>> evidence="evidence/research/retained/modern-c/binding-activation/observation.json"; attribute :>> premise="Normal/nested/exceptional exit discharges exactly its own entry. Clear the identity while the last entry still retains context, then release that entry; zero-first permits use-after-free. The official lifecycle consumer requires p1. Baseline and candidate both pass under that exact parameter; earlier omitted-p1 failures remain as rejected execution-context witnesses. Native callbacks cover normal and exceptional return."; }
  part property:Obligation { attribute :>> id="BA-PBT"; attribute :>> status="CLOSED"; attribute :>> evidence="evidence/research/retained/modern-c/binding-activation/observation.json"; attribute :>> premise="Reuse existing root-task replay/shrink support without inheriting unrelated stale flat-global C adapters. Real GC/override/callback histories pass. The injected observation mutation shrinks13to1 and serializes/replays; this does not prove shrinking a production runtime defect or explore all schedules."; }
  part cost:Obligation { attribute :>> id="BA-COST"; attribute :>> status="CLOSED"; attribute :>> evidence="evidence/research/retained/modern-c/binding-activation/observation.json"; attribute :>> premise="Same profile/source workload, full4096 requests and composed8192 resumes/16GC; The published-source cohort has p1 request median -2.299%, composed +0.298%, overlapping samples: no stable runtime speedup. Correctness and eliminated source-level work are the benefit; memory and time remain separate budgets. Context+8, module+8 and this-profile GSTATE+512 bytes; no universal or cold-build speedup claim. Exact matching binaries/modules permit explicit measurement reuse."; }
  part models:Obligation { attribute :>> id="BA-MODELS"; attribute :>> status="CLOSED"; attribute :>> evidence="dev/refactoring/modern-c/models/sysml/binding-activation.sysml"; attribute :>> premise="SDK-derived scope drives ASCENT with missing/stale/unknown refusal. QNT and Lean retain distinct existing duties; native refinement premises remain explicit."; }
  part emission:Obligation { attribute :>> id="BA-EMISSION"; attribute :>> status="CLOSED"; attribute :>> evidence="evidence/research/retained/modern-c/binding-activation/observation.json"; attribute :>> premise="The selected generated C must preprocess PRM/GLO/BEGIN_COD to the actual admitted accessors and reject the retired per-host ENTER_BINDINGS hook. Header text presence is insufficient; the early capability guard was a real negative witness."; }
  part revisionStatus:Obligation { attribute :>> id="BA-REV"; attribute :>> status="LOCAL_ADMITTED"; attribute :>> evidence="dev/refactoring/modern-c/binding-activation.org"; attribute :>> premise="One complete responsibility REV only after all five gates close; matrix/evidence references in commit and exact existing PR branches. No partial integration credit."; }
  attribute stage:String="binding-read-activation";
  attribute sourceCases:String="caller-closure;publication;memory-order;reader-equivalence;source-custody;baseline-attribution";
  attribute requiredCases:String="binding-pbt;binding-nonzero;frame-roots;frame-continuation;frame-layout;globals;index-owner;vm-lifecycle;module-reject;old-module-reject;cost";
  part submission:GambitCommitGates::SubmissionUnit {
    attribute :>> kind="integration";
    attribute :>> result="binding-read-activation";
    attribute :>> progressDelta=1;
    attribute :>> supportPaths="";
  }
  part def Need { ref part gate:GambitCommitGates::Gate; attribute id:String; attribute method:String; attribute artifact:String; attribute scope:String; }
  part testGate:Need { ref part :>> gate=GambitCommitGates::tests; attribute :>> id="BA-TESTS"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/binding-activation/native-complete.json"; attribute :>> scope="All declared consumers; retain default-SMP failures with explicit source/mode equivalence, never claim whole-family success."; }
  part learningGate:Need { ref part :>> gate=GambitCommitGates::learning; attribute :>> id="BA-LEARNING"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/binding-activation.org"; attribute :>> scope="Rejected duplicate storage/per-host checks, evidence context correction, actual PRMCELL acquire and failed-product recovery."; }
  part processGate:Need { ref part :>> gate=GambitCommitGates::process; attribute :>> id="BA-PROCESS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/binding-activation.org"; attribute :>> scope="One full post-foundation binding owner; foundation4/4 and independent SMP1/12 unchanged; pending packages remain independent."; }
  part modelGate:Need { ref part :>> gate=GambitCommitGates::models; attribute :>> id="BA-FORMAL"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/binding-activation/native-complete.json"; attribute :>> scope="Strict SDK projection, source refinement, fixup TLC41 distinct states and six tests. Entry/unload QNT and Lean laws retain distinct duties."; }
  part questionGate:Need { ref part :>> gate=GambitCommitGates::questions; attribute :>> id="BA-QUESTIONS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/binding-activation.org"; attribute :>> scope="Conditional composed benefit, short-request neutrality, actual storage cost and unclaimed default-SMP/whole-product performance."; }
}
