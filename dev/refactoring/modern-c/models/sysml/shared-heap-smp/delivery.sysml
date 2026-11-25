/* Model-owned delivery declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpDelivery {
 private import GambitSharedHeapSmp::*;

 part orgView:View { attribute :>> kind="org"; attribute :>> path="dev/refactoring/modern-c/shared-heap-smp-design.org"; attribute :>> anchor="shared-heap-smp-contracts"; }
 part d2View:View { attribute :>> kind="d2"; attribute :>> path="dev/refactoring/modern-c/diagrams/shared-heap-smp.d2"; attribute :>> anchor=""; }
 part svgView:View { attribute :>> kind="svg"; attribute :>> path="dev/refactoring/modern-c/diagrams/shared-heap-smp.svg"; attribute :>> anchor=""; }
 part receiptView:View { attribute :>> kind="receipt"; attribute :>> path="evidence/research/retained/modern-c/shared-heap-smp-design/current-projection.json"; attribute :>> anchor=""; }
 part jointDelivery:Workstream {
  attribute :>> id="joint-delivery";
  attribute :>> label="Gambit safepoint, multi-shot and parallel GC joint delivery";
  attribute :>> authority="GambitRuntimeComposition / GambitSharedHeapSmp";
  attribute :>> unit="One source-bound implementation packet joins generated safepoints and complete FrameSpec, per-shot shared continuation identity, frozen RootOrigin tasks from R member domains dispatched to W workers, producer-aware strong/weak closure and restored reentry. Task/shard count is not R or W. SH-CUT-S, SH-ALIAS-S, SH-BOUNDARY-S, SH-EXEC-N and SH-COST-N remain five distinct gates, not five feature REVs. Generational scan exclusion consumes this foundation in a subsequent whole delivery.";
  attribute :>> 'entry'="Exact modern-c working-source identity and generated ABI; finite writer/source census plus declared external admission policy; existing QNT/Lean kernels and imported owner premises";
  attribute :>> 'exit'="All five exact-subject obligations and their inherited prerequisites close; QNT schedule refinement and Lean slot hypotheses hold in C; complete affected native/PBT populations and matched work/pause/peak costs pass the five REV gates";
  attribute :>> excluded="No claim of all-SMP completion, new generational scan exclusion, Actor migration or cold-build speedup; no source-location/SDK-pass credit and no runtime edits by this research task. Historical +2.93 percent common-cause attribution stays OPEN in its own evidence period and is not a current implementation delivery gate.";
  attribute :>> netBenefit="Current full-GC handoff earns no mature-scan-exclusion credit. It can replace scan-length source-lock occupancy with brief metadata exclusion only if frozen topology/node lifetime is proved. Scanned root words remain; charge source-view leases, once-only ACK/counter work, task/query synchronization, deferred unlink and UNKNOWN retention. Current direct K=2+4R gives K14 at R3, independent of W2. With direct source and already protected record validation, metadata targets O(K+Q); fresh key search over A retained activation records adds O(A) per lookup; deferred drain adds O(U) for U released nodes and can conservatively retain their reachable graph. Fresh observer attachments still pay existing registry lookup O(V) for V live VMs unless a proved direct route exists; reuse VM/source-local admission for repeated queries. A per-task pointer costs sizeof(void*)*(2+3P+D) payload for allocated member capacity P and RC domains D, plus padding. Peak includes deferred node bytes, retained referents, activations and logs. Known closure bounds retention to drain; UNKNOWN has no fixed bound. Only matched CPU/pause/throughput/physical peak establishes a benefit. Keep census/heap and future generation cost separate; no current speedup claim.";
 }
 part foundationWork:Workstream {
  attribute :>> id="foundation";
  attribute :>> label="Whole root handoff and resume refinement";
  attribute :>> authority="GambitModernCDeliveryPlan / GambitPendingCuts";
  attribute :>> unit="Next complete delivery: generated caller roots -> requester/child RC install and ACK -> still marker -> frozen RootTask/W<R scan -> source reentry/reload -> exceptional exit and last-user retirement; consume historical4/4 without changing its denominator";
  attribute :>> 'entry'="Reuse the published source-bound four deliveries; reconcile current dirty adapters separately";
  attribute :>> 'exit'="One source-bound implementation covers root/writer/borrow producers and consumers, parent ACK only after target install, source queries distinct from executor grants, relocation reload and pre-RUN VM-control pins; whole native/PBT/cost acceptance closes five REV gates, never point-by-point credit";
  attribute :>> excluded="No generations, Actor isolation, full SMP acceptance or cold-build claim inside foundation 4/4";
  attribute :>> netBenefit="Explicit source identity and durable ownership remove inferred carrier authority; gate/pin/scan/restore costs remain";
 }
 part acceptanceWork:Workstream {
  attribute :>> id="acceptance";
  attribute :>> label="Independent modern-c SMP qualification";
  attribute :>> authority="GambitModernCDeliveryPlan::a1..a12 / suite_coverage.accepted_smp_status / evidence/research/retained/modern-c/delivery-plan/current/accepted-smp-progress.json";
  attribute :>> unit="Twelve complete native families; exact branch/profile/artifact/population";
  attribute :>> 'entry'="Bind each family to current producer and original limits; preserve baseline failures";
  attribute :>> 'exit'="Complete affected whole families with assertions, natural exit, PBT replay/shrink and failure attribution";
  attribute :>> excluded="No patch-line pass transfer; local model/source review does not increment families";
  attribute :>> netBenefit="Establish reliable parallel behavior; test cost is not a runtime speedup";
 }
 part costWork:Workstream {
  attribute :>> id="fastpath";
  attribute :>> label="Binding and request hot-path cost";
  attribute :>> authority="GambitPendingCuts / post-delivery matched-cost-matrix";
  attribute :>> unit="Matched workload cost claim, separate from correctness and family counts";
  attribute :>> 'entry'="Exact baseline/candidate source, profile, topology, warm/cold state and complete population";
  attribute :>> 'exit'="Show avoided work exceeds lookup/permit/barrier/synchronization work and peak-space costs";
  attribute :>> excluded="No reuse of historical percentages as current checkout measurements; cold builds stay separate";
  attribute :>> netBenefit="Amortize identity/slot resolution at module/context admission and safe-point refresh; preserve freeze/exit exclusion";
 }
 part generationWork:Workstream {
  attribute :>> id="generations";
  attribute :>> label="Generational shared-heap GC";
  attribute :>> authority="GambitGenerationalAdmission / GambitGenerationalBarrier";
  attribute :>> unit="Whole allocation/store/minor/promotion/major contract";
  attribute :>> 'entry'="Complete roots and writers; forwarding/copy authority, contiguous reservation and restore are source-bound";
  attribute :>> 'exit'="Complete remembered sources, residual edges, promotion failure custody, major/weak/will and matched costs";
  attribute :>> excluded="Not another age policy or a duplicate QNT/Lean proof; concurrent major not assumed";
  attribute :>> netBenefit="Avoid proven-clean mature interiors; pay barriers, rendezvous, promotion, major traffic and physical reserve";
 }
 part actorWork:Workstream {
  attribute :>> id="actors";
  attribute :>> label="Actor message and control boundary";
  attribute :>> authority="GambitContinuationSegments / shared-heap boundary policy";
  attribute :>> unit="Admission contract for current same-VM shared messages, control and native resource affinity; future cross-VM isolation/monitor services are separate implementation work";
  attribute :>> 'entry'="Distinguish logical Actor, VM heap, execution context and carrier";
  attribute :>> 'exit'="Explicit same-VM sharing and cross-VM transfer admission; per-shot control and resource affinity remain valid";
  attribute :>> excluded="No forced share-nothing rewrite of Scheme; mailbox delivery alone grants no cross-VM continuation migration";
  attribute :>> netBenefit="Explicit isolation prevents global lifetime coupling; cloning/serialization, monitoring and retained pins cost work";
 }
 part buildWork:Workstream {
  attribute :>> id="build";
  attribute :>> label="Build and Darwin developer experience";
  attribute :>> authority="GambitPendingCuts::currentPackages/currentRoutes";
  attribute :>> unit="Producer/configuration/compile/link invalidation contract";
  attribute :>> 'entry'="Existing configure/Make/Bazel profile and same task-owned workspace";
  attribute :>> 'exit'="Source identity preserves completed products and rejects stale producer reuse; measure complete build separately";
  attribute :>> excluded="No new profile, executor or environment layer; not a runtime REV acceptance dependency by default";
  attribute :>> netBenefit="Remove repeated generation/configuration/compilation only with exact dependency proof; metadata checks have cost";
 }
 part foundationAxis:ProgressAxis {
  attribute :>> id="foundation-progress";
  attribute :>> authority="GambitPendingCuts / post-delivery.org";
  attribute :>> reported="Historical4/4 local foundation delivery record; source-period bound, not current integration-REV admission";
  attribute :>> meaning="Foundation responsibility replacement; not current-source full SMP or generational acceptance";
  attribute :>> credit="No cross-axis arithmetic, inherited pass or progress credit from this design flow";
 }
 part smpAxis:ProgressAxis {
  attribute :>> id="independent-smp";
  attribute :>> authority="GambitModernCDeliveryPlan::a1..a12 / suite_coverage.accepted_smp_status / evidence/research/retained/modern-c/delivery-plan/current/accepted-smp-progress.json";
  attribute :>> reported="Recorded5/12 at canonical65a4a2e2: bootstrap, gsi, gsc, pr-gsi and pr-gsc; seven remain. The planning snapshot revalidated both model-bound PR receipts without rerunning native workloads. This is the accepted evidence period, not current dirty HEAD or fresh remote CI. Read the authoritative accepted_smp_status ledger before any later report.";
  attribute :>> meaning="Independent whole-family modern-c native acceptance";
  attribute :>> credit="No cross-axis arithmetic, inherited pass or progress credit from this design flow";
 }
 part repairAxis:ProgressAxis {
  attribute :>> id="repair-history";
  attribute :>> authority="User report / repair-line evidence";
  attribute :>> reported="9/12 current user-reported repair checkpoint; not rerun here. Repair19 is a retained 2026-10-26 8/12 evidence cut, not a contradictory current numerator or modern-c credit.";
  attribute :>> meaning="Historical architecture failures and repairs inform hypotheses, not modern-c passes";
  attribute :>> credit="No cross-axis arithmetic, inherited pass or progress credit from this design flow";
 }
 part assignment0:Assignment {
  ref part :>> question=cutProtocol;
  ref part :>> workstream=foundationWork;
 }
 part assignment1:Assignment {
  ref part :>> question=aliasLaw;
  ref part :>> workstream=foundationWork;
 }
 part assignment2:Assignment {
  ref part :>> question=cutSource;
  ref part :>> workstream=foundationWork;
 }
 part assignment3:Assignment {
  ref part :>> question=aliasSource;
  ref part :>> workstream=foundationWork;
 }
 part assignment4:Assignment {
  ref part :>> question=boundarySource;
  ref part :>> workstream=actorWork;
 }
 part assignment5:Assignment {
  ref part :>> question=nativeAcceptance;
  ref part :>> workstream=acceptanceWork;
 }
 part assignment6:Assignment {
  ref part :>> question=netBenefit;
  ref part :>> workstream=costWork;
 }
 part jointSourceDependency:WorkDependency { ref part :>> dependent=jointDelivery; ref part :>> prerequisite=foundationWork; }
 part jointBoundaryDependency:WorkDependency { ref part :>> dependent=jointDelivery; ref part :>> prerequisite=actorWork; }
 part jointNativeDependency:WorkDependency { ref part :>> dependent=jointDelivery; ref part :>> prerequisite=acceptanceWork; }
 part jointCostDependency:WorkDependency { ref part :>> dependent=jointDelivery; ref part :>> prerequisite=costWork; }
 part workDependency0:WorkDependency {
  ref part :>> dependent=acceptanceWork;
  ref part :>> prerequisite=foundationWork;
 }
 part workDependency1:WorkDependency {
  ref part :>> dependent=costWork;
  ref part :>> prerequisite=foundationWork;
 }
 part workDependency2:WorkDependency {
  ref part :>> dependent=generationWork;
  ref part :>> prerequisite=foundationWork;
 }
 part workDependency3:WorkDependency {
  ref part :>> dependent=actorWork;
  ref part :>> prerequisite=foundationWork;
 }

 part integrationAxis:ProgressAxis {
  attribute :>> id="integration-admission";
  attribute :>> authority="GambitModernCOutcomes::execution / GambitRequestProduct::revisionAdmission / owner-closure-acceptance.json";
  attribute :>> reported="Keep the registry OPEN_INTEGRATION and the separately closed scoped requirement packet distinct from historical local4/4. Current selected-tree five-gate REV admission is not inferred from either count.";
  attribute :>> meaning="One source/scope-bound integration result versus its native prerequisites and publication admission; thirteen catalogue stages are not another denominator";
  attribute :>> credit="Do not rewrite historical model inputs or promote scoped native closures to current working-tree admission";
 }
 part nextQualification:Workstream {
  attribute :>> id="current-subject";
  attribute :>> label="Current-subject stress and marginal-work qualification";
  attribute :>> authority="Runtime owner selected source/ABI/profile/artifact subject; accepted_smp_status families stress-gsi/stress-gsc; DEV source and value review";
  attribute :>> unit="One joined source freeze, whole declared stress evidence and causal-work decision; no new progress denominator or isolated setter/MVP credit";
  attribute :>> 'entry'="Runtime owner freezes the complete selected responsibility and dirty/support boundary on the existing branch; bind generated C, headers, compiler, profile and linked artifacts. Accepted5/12 source period and archived DEV cache are evidence, not automatic identity of this subject.";
  attribute :>> 'exit'="Run original stress-gsi/stress-gsc populations under original limits, preserving passes, classified failures and unstarted work. On that same subject measure or explicitly bound slow-wait, capture/closure, physical arm, frame-materialization, scan, binding-read and root/metadata costs. Produce one complete next responsibility replacement or a justified no-change decision. A failing campaign may identify a falsifiable owner defect; it cannot advance a family.";
  attribute :>> excluded="This DEV task does not select/commit peer runtime hunks, rerun an archived cache as current HEAD, widen test populations/budgets, introduce static S or minor GC speculatively, or absorb build/CI/Darwin work beyond required dependency closure.";
  attribute :>> netBenefit="N_elim cannot exceed actual eligible slow entries; legal physical rearm does not multiply capture savings. Require measured avoided work or explicit correctness benefit to justify added admission/root/frame/retention costs. Prior +2.93 percent and other historical regressions do not explain current source by themselves. No new throughput/peak claim without a matched subject.";
 }
 part nextSourceDependency:WorkDependency { ref part :>> dependent=nextQualification; ref part :>> prerequisite=foundationWork; }
 part nextAcceptanceDependency:WorkDependency { ref part :>> dependent=acceptanceWork; ref part :>> prerequisite=nextQualification; }
 part nextCostDependency:WorkDependency { ref part :>> dependent=costWork; ref part :>> prerequisite=nextQualification; }
}
