package GambitRootScanWorker {
 private import ScalarValues::*;
 attribute stage:String="root-scan-worker";
 attribute baseline:String="c438df5cc193ea1a17102b3d0c72e4285cfea96c";
 attribute scope:String="Complete six-source scan execution boundary: collective passes its actual worker through RC, VM, bank, stack, globals and symbol/keyword adapters and private/census consumers. Preserve source-specific publication, claim, completion, locks, epochs, leases and frame rewriting. No carrier rebinding or arbitrary worker migration authority.";
 attribute formalDuty:String="Existing QNT owns task histories and frame/copy/phase ownership. Existing Lean owns root/range/capacity laws. This cut changes concrete C argument/refusal refinement only. Native PBT must exercise actual six adapters, wrong-worker rejection without task mutation, replay/shrink and moving multi-shot roots. No duplicate QNT or Lean protocol.";
 attribute sourceCases:String="callers;explicit-worker;source-gates;frame-semantics;custody";
 attribute requiredCases:String="native;root-pbt;moving-consumers;original;model;cost";
 attribute obligations:String="worker;guards;nullRoute;frames;callers;reuse;costProof";
 attribute refinements:String="claimMap;scanMap;finishMap";
 part def Obligation { attribute id:String; attribute status:String; attribute premise:String; }
 part worker:Obligation { attribute :>> id="SCAN-WORKER"; attribute :>> status="CLOSED"; attribute :>> premise="The collective's work is the direct argument through all six scan consumers; no adapter silently selects another worker."; }
 part guards:Obligation { attribute :>> id="SCAN-GUARDS"; attribute :>> status="CLOSED"; attribute :>> premise="Existing live-source/canonical-context, source kind, executor, epoch, CLAIMED and one lease checks precede scanning. Supplied work must match the current carrier binding, carrier and VM; outer lifetime remains a premise."; }
 part nullRoute:Obligation { attribute :>> id="SCAN-NULL"; attribute :>> status="CLOSED"; attribute :>> premise="A null work value is admissible only when the existing executor has no collector. Existing standalone permanent-only/empty-stack controls remain; live stack/copy never acquire authority from null."; }
 part frames:Obligation { attribute :>> id="SCAN-FRAMES"; attribute :>> status="CLOSED"; attribute :>> premise="Same mark_continuation, frame locks, descriptors and multi-shot repair algorithm; actual map restores and moving root coverage required."; }
 part callers:Obligation { attribute :>> id="SCAN-CALLERS"; attribute :>> status="CLOSED"; attribute :>> premise="All collective, private, preflight census and actual replay consumers use explicit arguments. No legacy scan overload or implicit worker-selection alias remains."; }
 part reuse:Obligation { attribute :>> id="SCAN-REUSE"; attribute :>> status="CLOSED"; attribute :>> premise="One existing cache/profile, exact predecessor artifacts, no repeated Scheme C generation, fixed original/native/PBT budgets and all failures retained."; }
 part costProof:Obligation { attribute :>> id="SCAN-COST"; attribute :>> status="DENIED_NET_BENEFIT"; attribute :>> premise="Additional argument and worker-binding validation are costs; equal Scheme bytes/zero GC exclude only differential Scheme GC in the historical one-argument cohort. No stable speedup without matched evidence."; }
 part def Refinement { attribute actions:String; attribute source:String; attribute guard:String; attribute obligation:String; attribute quint:String; attribute leanDuty:String default="Reuse existing roots/range laws; no new arithmetic or theorem for argument identity."; }
 part claimMap:Refinement {
  attribute :>> actions="publish;claim";
  attribute :>> source="lib/_mem/root-tasks.inc;lib/root.h";
  attribute :>> guard="Source-specific RC mutex or confined stopped source/current executor protects the existing task. READY to CLAIMED acquires no extra lease or worker migration permission.";
  attribute :>> obligation="SCAN-GUARDS";
  attribute :>> quint="dev/refactoring/modern-c/models/quint/root_store_projection.qnt;models/gambit/host_roots_contract.qnt";
 }
 part scanMap:Refinement {
  attribute :>> actions="validateWorker;scan";
  attribute :>> source="lib/_mem/root-origins.inc;lib/_mem/rc-roots.inc;lib/_mem/continuation-roots.inc;lib/_mem/collection-round.inc;lib/_mem/copy-planning.inc";
  attribute :>> guard="Compare explicit worker identity before dereferencing it or source payload. Normal scan changes CLAIMED to SCANNING to SCANNED using that work; wrong-worker refusal leaves task and lease untouched. Current VM and stopped-round lifetime are externally held, not established by pointer equality.";
  attribute :>> obligation="SCAN-WORKER";
  attribute :>> quint="Existing root_store_projection and gc_chunk_cursor_operations; no new requeue/unknown recovery step.";
 }
 part finishMap:Refinement {
  attribute :>> actions="finish;joinRound;restore";
  attribute :>> source="lib/_mem/root-tasks.inc;existing collection/restoration consumers";
  attribute :>> guard="Only source-matching SCANNED can finish; unknown scan retains lease and source custody. Local DONE is not whole-round reclamation. No change to physical restoration or unknown-join isolation.";
  attribute :>> obligation="SCAN-FRAMES";
  attribute :>> quint="Existing host_roots_contract and GC phase/closure protocols; no duplicated Lean schedules.";
 }
 part submission:GambitCommitGates::SubmissionUnit { attribute :>> kind="integration"; attribute :>> result="root-scan-worker"; attribute :>> progressDelta=1; attribute :>> supportPaths=""; }
 part def Need { ref part gate:GambitCommitGates::Gate; attribute id:String; attribute method:String; attribute artifact:String; attribute scope:String; }
 part tests:Need { ref part :>> gate=GambitCommitGates::tests; attribute :>> id="SCAN-TESTS"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/root-scan-worker/qualification.json"; attribute :>> scope="Actual C/PBT/replay/shrink and moving frame/RC/SFUN consumers plus existing original unit population; unchanged limits."; }
 part learning:Need { ref part :>> gate=GambitCommitGates::learning; attribute :>> id="SCAN-LEARNING"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/root-scan-worker.org"; attribute :>> scope="Separate explicit scan execution authority from physical carrier and frozen source ownership; retain all synchronization and layout semantics."; }
 part process:Need { ref part :>> gate=GambitCommitGates::process; attribute :>> id="SCAN-PROCESS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/root-scan-worker.org"; attribute :>> scope="One complete six-source call chain, not one setter. Original pending path inventory and independent SMP counters remain separate."; }
 part models:Need { ref part :>> gate=GambitCommitGates::models; attribute :>> id="SCAN-MODELS"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/root-scan-worker/qualification.json"; attribute :>> scope="Native OpenSysML SDK drives explicit C refinement/ASCENT obligations with missing/stale controls; QNT and Lean remain existing disjoint owners."; }
 part questions:Need { ref part :>> gate=GambitCommitGates::questions; attribute :>> id="SCAN-QUESTIONS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/root-scan-worker.org"; attribute :>> scope="Actual source/worker/epoch identity, wrong-worker refusal, nullable standalone path, multi-shot semantics, source-period CI and unmeasured stable net speed resolved or explicitly bounded."; }
}
