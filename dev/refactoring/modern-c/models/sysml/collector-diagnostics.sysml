package GambitCollectorDiagnostics {
 private import ScalarValues::*;
 attribute stage:String="collector-diagnostics";
 attribute baseline:String="3a6aa3453d4145152d82c3ec2f082354bc009c5b";
 attribute scope:String="Replace implicit carrier lookup in the complete copy validator/error/report chain with explicit actual collector worker; bind diagnostic tag producers to the same selected worker and use the VM round destination. Keep carrier physical allocator guards and context roots distinct. Review all nine pending collector proposals; do not remove published locks or bounds.";
 attribute formalDuty:String="No new GC phase, task/lease, allocation algorithm or arithmetic law. Existing QNT owns copy/scan/closure transitions and existing Lean owns capacity/range laws. C source refinement proves the admitted diagnostic adapter uses the actual stable worker, VM map and accepted round. Native debug compilation and source fixture exercise the real definitions; no duplicate QNT/Lean or full debug VM claim.";
 attribute sourceCases:String="caller-closure;role-ownership;proposal-disposition;abi-isolation;source-custody";
 attribute requiredCases:String="baseline-compile;debug-consumers;fatal-control;production-pbt;original-consumers;model;cost;bindings";
 attribute refinements:String="writerMap;copyMap;reportMap";
 part def Refinement { attribute actions:String; attribute source:String; attribute guard:String; attribute obligation:String; attribute quint:String; attribute leanDuty:String default="Reuse existing range laws; no new theorem for diagnostic tag or deleted stale proposal."; }
 part writerMap:Refinement {
  attribute :>> actions="claimRoot;setReferenceLocation;markArray";
  attribute :>> source="lib/_mem/root-origins.inc;lib/_mem/rc-roots.inc;existing object/continuation/will diagnostic writers";
  attribute :>> guard="The existing RootTask executor adapter selects collector once during synchronous stopped-source scanning. Tags and actual mark_array use that selected worker; no scheduling/reentry/GC between them. Null worker permits only the existing permanent-root path and produces no worker tag. This does not retire the public executor bridge.";
  attribute :>> obligation="DIAG-WRITERS";
  attribute :>> quint="dev/refactoring/modern-c/models/quint/root_store_projection.qnt;models/gambit/host_roots_contract.qnt";
 }
 part copyMap:Refinement {
  attribute :>> actions="validateOld;readDestination;reportInvalid";
  attribute :>> source="lib/_mem/copy-reservations.inc mark_array_debug;lib/_mem/diagnostics.inc validate_old_obj";
  attribute :>> guard="The actual copying caller passes its live work explicitly after census/null-worker paths. Section map comes from work.vm, destination_offset from its accepted collection round; stale carrier tospace_offset and carrier.collector must not override either. Worker/VM/round storage remains protected by the existing whole-round lifetime.";
  attribute :>> obligation="DIAG-COPY";
  attribute :>> quint="models/gambit/gc_chunk_cursor_operations.qnt; no new publication or allocation action.";
 }
 part reportMap:Refinement {
  attribute :>> actions="bug;explainProblem;dumpMemoryMap";
  attribute :>> source="lib/_mem/diagnostics.inc;existing public global reflection helper in lib/_mem/global-bindings.inc";
  attribute :>> guard="All private validation/error/report consumers pass the same work. VM sections and worker arena/scan/tag/line are worker-owned; physical carrier allocation fields remain explicitly carrier adapters. Existing current-VM reflection ABI obtains current PSTATE, never invents context.mem. Controlled test sinks prove provenance, not production fatal cleanup or arbitrary corruption recovery.";
  attribute :>> obligation="DIAG-REPORT";
  attribute :>> quint="Source/native refinement only; no distributed history or new error-recovery protocol.";
 }
 part def Obligation { attribute id:String; attribute status:String; attribute premise:String; }
 attribute obligations:String="writers;copy;report;review;reuse;bindings;costProof";
 part writers:Obligation { attribute :>> id="DIAG-WRITERS"; attribute :>> status="CLOSED"; attribute :>> premise="Every reference_location writer and actual root/copy caller inventoried; bridge capture and optional no-worker premise explicit."; }
 part copy:Obligation { attribute :>> id="DIAG-COPY"; attribute :>> status="CLOSED"; attribute :>> premise="Real source/destination test uses round offset even with deliberately stale carrier projection; caller passes actual work."; }
 part report:Obligation { attribute :>> id="DIAG-REPORT"; attribute :>> status="CLOSED"; attribute :>> premise="Native DEBUG compile and real diagnostic definitions select worker7 over carrier decoy99; actual invalid path reaches controlled fatal sink."; }
 part review:Obligation { attribute :>> id="DIAG-REVIEW"; attribute :>> status="CLOSED"; attribute :>> premise="Five coordinate-only and two lock/bound-removal proposals rejected with all versions retained. GC-phase early allocation refusal stays unqualified; no misleading pending-count or speed credit."; }
 part reuse:Obligation { attribute :>> id="DIAG-REUSE"; attribute :>> status="CLOSED"; attribute :>> premise="Same C23 profile/cache,51 generated inputs and exact rebuilt production artifact identities; real frame/RC/SFUN and original consumers."; }
 part bindings:Obligation { attribute :>> id="DIAG-BINDINGS"; attribute :>> status="CLOSED"; attribute :>> premise="Three actual ASCENT producers replay114 historical references with facts/paths/hashes/old identities intact; current/cache substitution refuses, historical query gaps retained."; }
 part costProof:Obligation { attribute :>> id="DIAG-COST"; attribute :>> status="CLOSED"; attribute :>> premise="One worker selection per bank/RC/global adapter replaces repeated selection. Empty RC/global adapters add one lookup; source evaluation bounds do not prove hardware load or timing improvement. Native fields/layout unchanged; debug-only report work explicit. Original1-arg allocation/GC samples and static guard/code footprint are distinct from elapsed time."; }
 part submission:GambitCommitGates::SubmissionUnit { attribute :>> kind="integration"; attribute :>> result="collector-diagnostics"; attribute :>> progressDelta=1; attribute :>> supportPaths=""; }
 part def Need { ref part gate:GambitCommitGates::Gate; attribute id:String; attribute method:String; attribute artifact:String; attribute scope:String; }
 part tests:Need { ref part :>> gate=GambitCommitGates::tests; attribute :>> id="DIAG-TESTS"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/collector-diagnostics/qualification.json"; attribute :>> scope="Actual debug translation unit and isolated source consumers, production roots/PBT and original population without altered limits."; }
 part learning:Need { ref part :>> gate=GambitCommitGates::learning; attribute :>> id="DIAG-LEARNING"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/collector-diagnostics.org"; attribute :>> scope="Worker owns diagnostics and round destination; carrier/context/VM roles remain distinct, removing locks is not optimization."; }
 part process:Need { ref part :>> gate=GambitCommitGates::process; attribute :>> id="DIAG-PROCESS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/collector-diagnostics.org"; attribute :>> scope="Nine original collector paths reviewed; one complete caller/writer/validator/report replacement plus evidence-backed proposal dispositions. Independent SMP unchanged."; }
 part models:Need { ref part :>> gate=GambitCommitGates::models; attribute :>> id="DIAG-MODELS"; attribute :>> method="native"; attribute :>> artifact="evidence/research/retained/modern-c/collector-diagnostics/qualification.json"; attribute :>> scope="OpenSysML SDK drives ASCENT missing/stale source-native obligations; QNT/Lean remain disjoint unchanged owners."; }
 part questions:Need { ref part :>> gate=GambitCommitGates::questions; attribute :>> id="DIAG-QUESTIONS"; attribute :>> method="source-analysis"; attribute :>> artifact="dev/refactoring/modern-c/collector-diagnostics.org"; attribute :>> scope="Caller lifetime, debug ABI/sinks, physical guards, historical framework binding periods and original1-arg attribution answered with retained open boundaries."; }
}
