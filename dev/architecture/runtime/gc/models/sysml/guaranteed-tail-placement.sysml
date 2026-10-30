/* Modern generated C target. Requirements are not satisfied runtime instances. */
package GambitGuaranteedTailPlacement {
 private import ScalarValues::*;
 part def GuaranteedPlan {
  attribute copyWriteEnd : Integer; attribute copyAddressEnd : Integer; attribute copyFence : Integer;
  attribute futureStart : Integer; attribute futureEnd : Integer; attribute allowance : Integer; attribute guard : Integer;
  attribute backed : Boolean; attribute placementComplete : Boolean; attribute contextSetMatched : Boolean;
  attribute roleMatched : Boolean; attribute acceptedBeforeForward : Boolean; attribute allowForward : Boolean;
 }
 requirement def GuaranteedPlanLaw { subject p : GuaranteedPlan;
  require constraint { p.copyWriteEnd>=0 and p.copyAddressEnd>=0 and p.futureStart>=0 and
   p.allowance>=0 and p.guard>=0 and p.futureEnd>=p.futureStart and
   (not p.allowForward or (p.backed and p.placementComplete and p.contextSetMatched and p.roleMatched and
    p.acceptedBeforeForward and p.copyWriteEnd<=p.copyFence and p.copyAddressEnd<=p.copyFence and
    p.copyFence<=p.futureStart and p.futureStart+p.allowance+p.guard<=p.futureEnd)) }
 }
 part def ResumeAssurance {
  attribute epoch : Integer; attribute proofEpoch : Integer; attribute cursor : Integer; attribute limit : Integer;
  attribute writeBound : Integer; attribute addressBound : Integer; attribute endOffset : Integer;
  attribute rootsReady : Boolean; attribute codeAndLayoutMatched : Boolean; attribute lowerBoundChecked : Boolean;
  attribute commitKnown : Boolean; attribute roleMatched : Boolean; attribute spanMayRun : Boolean;
 }
 requirement def ResumeLaw { subject r : ResumeAssurance;
  require constraint { r.writeBound>=0 and r.addressBound>=0 and
   (not r.spanMayRun or (r.epoch==r.proofEpoch and r.rootsReady and r.codeAndLayoutMatched and
    r.lowerBoundChecked and r.commitKnown and r.roleMatched and r.cursor<=r.limit and
    r.limit+r.writeBound<=r.endOffset and r.limit+r.addressBound<=r.endOffset)) }
 }
 part def PeakEvidence {
  attribute guaranteedCredit : Integer; attribute lateRefund : Integer; attribute addedBacking : Integer;
  attribute addedMetadata : Integer; attribute heldPartial : Integer;
  attribute allPhasesCovered : Boolean; attribute matchedBaseline : Boolean; attribute everyPhaseBelowBaselinePeak : Boolean;
  attribute netCreditCountedOnce : Boolean; attribute measured : Boolean; attribute strictPeakGainClaimed : Boolean;
 }
 requirement def PeakLaw { subject p : PeakEvidence;
  require constraint { p.guaranteedCredit>=0 and p.lateRefund>=0 and p.addedBacking>=0 and
   p.addedMetadata>=0 and p.heldPartial>=0 and
   (not p.strictPeakGainClaimed or (p.allPhasesCovered and p.matchedBaseline and
    p.everyPhaseBelowBaselinePeak and p.netCreditCountedOnce)) }
 }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="GT-H"; attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/guaranteed_tail_placement.qnt"; attribute :>> subjectScope="guaranteed_tail_placement:17-named-histories;safe;seed=17;100x80"; attribute :>> premise="One region/context model with copy fence, guarded resume, unknown commit and accumulated peak; abstract words, not native memory measurements"; }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="GT-I"; attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/GuaranteedTailPlacement.lean"; attribute :>> subjectScope="GambitSMP.GuaranteedTailPlacement:spanContained;copyAndFutureDisjoint;restoreAllowance;sequentialBound;vectorBoxBoundMonotone;noDoubleReserve;guardCannotBeCountedAsAllowance;lateRefundKeepsRecordedPeak;threePhasePeakBelow;dominantUnchangedNoStrictGain;creditNeedsNetGain;largerDestinationCancelsCredit"; attribute :>> premise="Parametric containment, ordered bounds and peak inequalities; whole QNT/source and baseline phase coverage open"; }
 part placement : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="GT-PLAN"; attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/GuaranteedTailPlacement.lean"; attribute :>> subjectScope="GT-PLAN:actual-source-refinement"; attribute :>> premise="Before forwarding, backed disjoint copy-write/address fence and accepted future context interval; immutable participant/role/layout identity and exact physical counterfactual"; }
 part checks : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="GT-CHECK"; attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/GuaranteedTailPlacement.lean"; attribute :>> subjectScope="GT-CHECK:actual-source-refinement"; attribute :>> premise="Actual ordered allocation span W/P/minima, flonum materialization, runtime/custom helpers and first resume PointId; L+B<=end and reload or reject unknown bounds"; }
 part restore : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="GT-RESTORE"; attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/GuaranteedTailPlacement.lean"; attribute :>> subjectScope="GT-RESTORE:actual-source-refinement"; attribute :>> premise="All six prepare_mem_pstate endpoints and kernel heap/rest/exception exits use current role-specific grant; keep distinct stack, GC-completion and failure reserves"; }
 part peak : GambitAssuranceRouting::ModelNeed { ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="GT-PEAK"; attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/GuaranteedTailPlacement.lean"; attribute :>> subjectScope="GT-PEAK:actual-source-refinement"; attribute :>> premise="Matched separated/current baselines, every acquisition/copy/restore/failure phase and held-partial bytes; Qg net credit vs late Qo; no bank/root/allocator double accounting"; }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=placement; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=placement; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=placement; ref part :>> prerequisite=GambitPromotionIntervalHandoff::induction; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=placement; ref part :>> prerequisite=GambitRuntimeAssurance::work.source; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=checks; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=checks; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=checks; ref part :>> prerequisite=placement; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=checks; ref part :>> prerequisite=GambitGenerationalBarrier::writers; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=checks; ref part :>> prerequisite=GambitRuntimeAssurance::control.source; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=history; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=induction; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=placement; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=history; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=induction; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=placement; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=restore; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=GambitPromotionIntervalHandoff::readers; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitPromotionIntervalHandoff::extents; ref part :>> prerequisite=placement; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitPromotionIntervalHandoff::tail; ref part :>> prerequisite=checks; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitPromotionIntervalHandoff::tail; ref part :>> prerequisite=restore; }
 part dependency22 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitPromotionResidual::bound; ref part :>> prerequisite=peak; }
 part def CallerRow {
 attribute callerId : String;
 attribute sourceAnchors : String;
 attribute actualChain : String;
 attribute hazard : String;
 attribute replacement : String;
 }
 part caller0 : CallerRow {
 attribute :>> callerId="compiler";
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:108-119;_t-c-2.scm:345-413,1120-1141";
 attribute :>> actualChain="heap reserve/debt plus fp-cache estimate -> check -> return label";
 attribute :>> hazard="Compiler fudge4096 is not current runtime fudge8194 or an actual target span certificate";
 attribute :>> replacement="Scheme emits ordered span/code/layout/PointId proof; runtime issues interval assurance";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="boxing";
 attribute :>> sourceAnchors="gsc/_t-c-2.scm:2480-2486,2607-2635,2820-2866;gambit.h.in:3137-3162";
 attribute :>> actualChain="allocation reserve -> operand materialization -> BEGIN/ADD/END; dirty floats may box";
 attribute :>> hazard="Reserve/reset counters do not bound every actual post-check write/address event";
 attribute :>> replacement="Include actual boxing versions and constructor/completion grammar; unknown indirect helper refuses finite B";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="check";
 attribute :>> sourceAnchors="gambit.h.in:8544-8560;lib/_kernel.scm:303-334,1964-1990";
 attribute :>> actualChain="CHECK_HEAP tests hp>limit -> internal frame/register save -> check-heap -> heap_limit and optional GC";
 attribute :>> hazard="Runtime check ignores parameter m here; equality hp==limit is a successful guard";
 attribute :>> replacement="Generate L+max(Bwrite,Baddress)<=end and matching lower/alignment bounds; reissue after rebase";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="restore";
 attribute :>> sourceAnchors="lib/mem.c:4525-4562,4717,7080,7215,7358,7402,7500";
 attribute :>> actualChain="six prepare_mem_pstate calls derive hp/fp/limits from private cursors and approximate free space";
 attribute :>> hazard="Old same-PSTATE tail reuse is real; independent worker/context cannot restore stale limits";
 attribute :>> replacement="Use exact committed role grants and first-resume assurance; preserve separate stack/failure roles";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="completion";
 attribute :>> sourceAnchors="lib/_kernel.scm:506-596,900-971,1992-2022;mem.h:76-78";
 attribute :>> actualChain="rest/keyword handler finishes list and argument vector before GC, then reloads/resumes or raises";
 attribute :>> hazard="Pending GC completion may allocate before roots are in fully scannable form";
 attribute :>> replacement="Reserve bounded completion demand separately or move only under a proved equivalent root/continuation protocol";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="copy";
 attribute :>> sourceAnchors="lib/mem.c:3241-3410,3490-3811,7038-7049";
 attribute :>> actualChain="payload/chunk links/frame copies -> resize -> guarantee heap fudge -> restore";
 attribute :>> hazard="Actual alloc cursor is not the maximum copy/link/address frontier; prepare may obtain another section";
 attribute :>> replacement="Seal write/address fence before Qg suffix; precommit all destination/resume/metadata roles before forwarding";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="failure";
 attribute :>> sourceAnchors="lib/mem.c:891-1057,6316-6468;lib/setup.c:884-950;lib/_kernel.scm:1964-2022";
 attribute :>> actualChain="partial expansion/reserve adjustment -> overflow exception/retry or context resize";
 attribute :>> hazard="Failure delivery or successful retry may create a new phase peak and require a different binding";
 attribute :>> replacement="Actual successful extents remain operation-owned; no forwarding rollback, role substitution or unknown-commit refund";
 }
 part def CostRow {
 attribute capability : String;
 attribute removedWork : String;
 attribute bound : String;
 attribute addedCost : String;
 attribute condition : String;
 }
 part cost0 : CostRow {
 attribute :>> capability="guaranteed credit";
 attribute :>> removedWork="Avoid one matched fresh resume backing allocation before collection starts";
 attribute :>> bound="Qg counts only exact preaccepted role-compatible suffixes outside all copy/check/completion footprints";
 attribute :>> addedCost="Placement/guard/index metadata and potentially larger copy arenas";
 attribute :>> condition="Credit is zero unless it substitutes an actual separate allocation; current same-PSTATE restoration already reuses tails";
 }
 part cost1 : CostRow {
 attribute :>> capability="span guard";
 attribute :>> removedWork="Use smaller actual per-span guard only after complete generated bounds";
 attribute :>> bound="Context extent requires allowance+B, with L+B<=end; guard bytes are not reusable allowance";
 attribute :>> addedCost="Ordered lowering analysis, slow-edge root/reload and schedule/layout identity checks";
 attribute :>> condition="Current4096/8194 constants are different contracts; no universal finite B established";
 }
 part cost2 : CostRow {
 attribute :>> capability="whole-round peak";
 attribute :>> removedWork="Strict reduction only if every phase is below matched baseline peak";
 attribute :>> bound="PeakCandidate=max(all acquisition,copy,commit,restore,failure occupancies); phase net Qg must beat added backing/metadata/retention";
 attribute :>> addedCost="Include context set, stack/emergency roles, old readers, partial acquisitions and later metadata overlap";
 attribute :>> condition="Positive pre-copy credit does not imply lower round peak; unchanged dominant phase or larger arenas can cancel all gain";
 }
 part cost3 : CostRow {
 attribute :>> capability="late refund";
 attribute :>> removedWork="Lower post-GC occupancy by actual released backing";
 attribute :>> bound="Qo=opportunistic suffix recognized after copy; earlier observed peak remains recorded";
 attribute :>> addedCost="Read-back, pin drain, alignment/role match and deallocation closure";
 attribute :>> condition="Cannot retrospectively relabel Qo as Qg or erase earlier peak";
 }
 part cost4 : CostRow {
 attribute :>> capability="failure custody";
 attribute :>> removedWork="Avoid double spending and unsafe resume after refused/unknown transfer";
 attribute :>> bound="Known pre-forward private claims refundable; published plan and unknown commit stay ledger-owned";
 attribute :>> addedCost="Bounded held-partial/operation slots and protected completion/failure capacity";
 attribute :>> condition="Retention/quarantine may block progress; no RSS/OOM or recovery-time guarantee";
 }
 part placementRoute : GambitHostRootsRefinement::Route { ref part :>> need=placement;
 attribute :>> sourceAnchors="lib/mem.c:3241-3410,3490-3811,7038-7049;lib/mem.c:891-1057,6316-6468;lib/setup.c:884-950;lib/_kernel.scm:1964-2022";
 attribute :>> patchAnchors="Cumulative runtime patch unchanged; no guaranteed-tail implementation";
 attribute :>> projection="Before forwarding, backed disjoint copy-write/address fence and accepted future context interval; immutable participant/role/layout identity and exact physical counterfactual";
 attribute :>> failureCustodian="Same epoch plan/region/transfer ledger; unknown keeps ownership, rooted pending work and original peak history";
 attribute :>> status="target-contract-specified-concrete-source-and-memory-open"; }
 part checksRoute : GambitHostRootsRefinement::Route { ref part :>> need=checks;
 attribute :>> sourceAnchors="gsc/_t-c-1.scm:108-119;_t-c-2.scm:345-413,1120-1141; gsc/_t-c-2.scm:2480-2486,2607-2635,2820-2866;gambit.h.in:3137-3162; gambit.h.in:8544-8560;lib/_kernel.scm:303-334,1964-1990";
 attribute :>> patchAnchors="Cumulative runtime patch unchanged; no guaranteed-tail implementation";
 attribute :>> projection="Actual ordered allocation span W/P/minima, flonum materialization, runtime/custom helpers and first resume PointId; L+B<=end and reload or reject unknown bounds";
 attribute :>> failureCustodian="Same epoch plan/region/transfer ledger; unknown keeps ownership, rooted pending work and original peak history";
 attribute :>> status="target-contract-specified-concrete-source-and-memory-open"; }
 part restoreRoute : GambitHostRootsRefinement::Route { ref part :>> need=restore;
 attribute :>> sourceAnchors="gambit.h.in:8544-8560;lib/_kernel.scm:303-334,1964-1990; lib/mem.c:4525-4562,4717,7080,7215,7358,7402,7500; lib/_kernel.scm:506-596,900-971,1992-2022;mem.h:76-78";
 attribute :>> patchAnchors="Cumulative runtime patch unchanged; no guaranteed-tail implementation";
 attribute :>> projection="All six prepare_mem_pstate endpoints and kernel heap/rest/exception exits use current role-specific grant; keep distinct stack, GC-completion and failure reserves";
 attribute :>> failureCustodian="Same epoch plan/region/transfer ledger; unknown keeps ownership, rooted pending work and original peak history";
 attribute :>> status="target-contract-specified-concrete-source-and-memory-open"; }
 part peakRoute : GambitHostRootsRefinement::Route { ref part :>> need=peak;
 attribute :>> sourceAnchors="lib/mem.c:4525-4562,4717,7080,7215,7358,7402,7500;lib/mem.c:891-1057,6316-6468;lib/setup.c:884-950;lib/_kernel.scm:1964-2022";
 attribute :>> patchAnchors="Cumulative runtime patch unchanged; no guaranteed-tail implementation";
 attribute :>> projection="Matched separated/current baselines, every acquisition/copy/restore/failure phase and held-partial bytes; Qg net credit vs late Qo; no bank/root/allocator double accounting";
 attribute :>> failureCustodian="Same epoch plan/region/transfer ledger; unknown keeps ownership, rooted pending work and original peak history";
 attribute :>> status="target-contract-specified-concrete-source-and-memory-open"; }
 part def ViewNode {
 attribute nodeId : String;
 attribute labelText : String;
 }
 part node0 : ViewNode {
 attribute :>> nodeId="spans";
 attribute :>> labelText="Scheme spans and resume demands";
 }
 part node1 : ViewNode {
 attribute :>> nodeId="plan";
 attribute :>> labelText="Backed copy fence plus future context suffix";
 }
 part node2 : ViewNode {
 attribute :>> nodeId="guard";
 attribute :>> labelText="AllocationCheckSpec: allowance plus guard";
 }
 part node3 : ViewNode {
 attribute :>> nodeId="copy";
 attribute :>> labelText="Copy stays outside guaranteed suffix";
 }
 part node4 : ViewNode {
 attribute :>> nodeId="commit";
 attribute :>> labelText="Confirm ownership and current binding";
 }
 part node5 : ViewNode {
 attribute :>> nodeId="resume";
 attribute :>> labelText="Context resumes under fresh assurance";
 }
 part node6 : ViewNode {
 attribute :>> nodeId="peaks";
 attribute :>> labelText="Compare every phase with matched baseline";
 }
 part node7 : ViewNode {
 attribute :>> nodeId="refund";
 attribute :>> labelText="Late surplus: refund only after known commit and drain";
 }
 part node8 : ViewNode {
 attribute :>> nodeId="hold";
 attribute :>> labelText="Keep pending work and owned extents";
 }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="place"; }
 part edge1 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node2; attribute :>> labelText="bound"; }
 part edge2 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node1; attribute :>> labelText="role demand"; }
 part edge3 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node3; attribute :>> labelText="preflight"; }
 part edge4 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="ready"; }
 part edge5 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="known"; }
 part edge6 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node8; attribute :>> labelText="refused/unknown"; }
 part edge7 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node8; attribute :>> labelText="unknown reply"; }
 part edge8 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="observe"; }
 part edge9 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node7; attribute :>> labelText="opportunistic"; }
 part edge10 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node6; attribute :>> labelText="preserve past peak"; }
 part edge11 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node7; attribute :>> labelText="known commit/drain"; }
}

