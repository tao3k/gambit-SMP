/* Model-owned assurance declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpAssurance {
 private import GambitSharedHeapSmp::*;

 part cutProtocol:Question {
  attribute :>> id="SH-CUT-Q";
  attribute :>> semanticKey="control/host-freeze-to-whole-round-resume";
  attribute :>> owner="quint";
  attribute :>> domain="control";
  attribute :>> artifact="dev/architecture/runtime/gc/models/quint/shared_heap_cut.qnt";
  attribute :>> symbols="shared_heap_cut:local-Test$";
  attribute :>> question="Does a local host-root completion permit early whole-round resume while copy/producer debt or stale reload remains?";
  attribute :>> boundary="LOCAL_FORMAL_ONLY";
 }
 part aliasLaw:Question {
  attribute :>> id="SH-ALIAS-L";
  attribute :>> semanticKey="data/relocation-preserves-authoritative-slot-equality";
  attribute :>> owner="lean";
  attribute :>> domain="data";
  attribute :>> artifact="dev/architecture/runtime/gc/models/lean/RelocationSlots.lean";
  attribute :>> symbols="Gambit.SharedHeapRelocation:aliasesRemainAliases;equalityObservationPreserved;missedSourceSlotBreaksAlias;collapsedAddressesBreakIdentity;aliasObservationRefinement;withSourceAdapter;rewriteBatchAt;batchCoverageProducesRewrittenOn;repeatedCanonicalSlotIsIdempotent";
  attribute :>> question="Do complete slot rewriting and injective forwarding preserve shared-cell equality observations for arbitrary slot/address types?";
  attribute :>> boundary="LOCAL_FORMAL_ONLY";
 }
 part cutSource:Question {
  attribute :>> id="SH-CUT-S";
  attribute :>> semanticKey="refinement/c-same-epoch-root-copy-resume-cut";
  attribute :>> owner="source";
  attribute :>> domain="refinement";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-tasks.inc";
  attribute :>> symbols="root-round-publish-claim-finish-and-resume-adapter";
  attribute :>> question="Does the map two-resume joint cut close actual writers and borrowers, scan a non-worker root source, and settle known pre-copy refusal separately from unknown reservation custody?";
  attribute :>> boundary="OPEN";
 }
 part aliasSource:Question {
  attribute :>> id="SH-ALIAS-S";
  attribute :>> semanticKey="refinement/c-authoritative-slots-and-injective-live-forwarding";
  attribute :>> owner="source";
  attribute :>> domain="refinement";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> symbols="all-source-slot-rewrites-and-live-object-address-map";
  attribute :>> question="Do FrameSpec, RC, globals and frame/denv adapters supply complete canonical slot rewriting, including reflective and generated writes, dirty overflow and residual young edges? The mature-slot replacement joins writer closure, independent slot oracle, overflow scan and next-epoch rearm before thaw; retain current census for this cut. Scheme-level full collector slot identity is a functional control. The collector exposes paired test-only cuts before planning and after the weak-work join before restoration. The p1 full collector observes actual frame and continuation denv slots at both cuts against independent RC roots. The DEV C23 bounded-log control executes overflow and next-bank rearm with supplied slot and generation premises. A p1 RC-staged full collector control observes relocation for bounded and overflow cases with no intervening logical store. A full collector sole-registration negative confirms that omitting next-round staging leaves a C-created referent unforwarded. A DEV collector overlay omits actual stationary frame and denv slots with census unchanged and detects stale values against independent roots. The DEV p1 overlay exercises recorded mature writes, omission, overflow and no-store rearm against independent RC roots. DEV native PBT exercises omitted rearm, sole-edge survival and overflow in the same selective path; paired DEV scan work is two versus four visits with 80 bytes of log storage. Production minor membership, writer admission, CPU, pause and peak remain open.";
  attribute :>> boundary="OPEN";
 }
 part boundarySource:Question {
  attribute :>> id="SH-BOUNDARY-S";
  attribute :>> semanticKey="semantics/cross-domain-control-resource-ownership";
  attribute :>> owner="source";
  attribute :>> domain="semantics";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> symbols="message-vm-control-and-native-last-use-policy";
  attribute :>> question="Which sharing/isolation boundaries and continuation/resource transfers are supported without changing shared Scheme or multi-shot semantics?";
  attribute :>> boundary="OPEN";
 }
 part nativeAcceptance:Question {
  attribute :>> id="SH-EXEC-N";
  attribute :>> semanticKey="native/current-source-whole-smp-gc-composition";
  attribute :>> owner="native";
  attribute :>> domain="native";
  attribute :>> artifact="dev/refactoring/modern-c/models/sysml/pending-cuts.sysml";
  attribute :>> symbols="currentRoutes:complete-affected-family-manifests";
  attribute :>> question="For the current full-GC handoff packet, do the exact-source official frame/entry/SFUN/RC/root/lifecycle targets and map two-resume controls complete under original budgets, with R3 W2, actual generated entry, non-worker source, alias repair, delayed publish/claim result, weak/restore and known/unknown exit controls? Actual implementation replay/shrink must reach the production cuts: map-worker-stop's substituted trial partly exercises fixture storage and is not whole-path coverage. Keep diagnostic mutation distinct from the independent slot oracle. Original GSI/GSC and affected Gerbil consumers retain full populations; a baseline failure needs same-condition attribution, not removal. Nursery clean/dirty/overflow/residual and promotion-refusal tests remain mandatory for the subsequent generational packet, not a requirement to implement that excluded feature in this full-GC packet.";
  attribute :>> boundary="OPEN";
 }
 part netBenefit:Question {
  attribute :>> id="SH-COST-N";
  attribute :>> semanticKey="native/matched-smp-gc-work-and-physical-cost";
  attribute :>> owner="native";
  attribute :>> domain="native";
  attribute :>> artifact="dev/refactoring/modern-c/post-delivery.org";
  attribute :>> symbols="matched-workload-source-profile-cost-and-peak";
  attribute :>> question="For the current full-GC handoff packet, compare the same source cohort/profile/topology/completed workload: no-probe official tfib/gcbench and map controls, per-shot bytes, actual root/claim/restore work, request-to-last-park, collection, restore/reentry, wake/dispatch and simultaneous physical peak. Diagnostic timing is a separate cohort. Performance regression needs retained attribution and an explicit architecture tradeoff; no unmeasured speedup or historical +2.93 percent transfer. The subsequent generational packet additionally compares full/minor-with-census/certified-minor over a major interval and charges barriers, remembered scans, promotion, residual retention and major work. No census removal, heap increase or timeout widening in this packet.";
  attribute :>> boundary="OPEN";
 }
 part generationSource:ImportedNeed {
  attribute :>> id="GC-GEN";
  attribute :>> authority="GambitGenerationalAdmission::source";
  attribute :>> artifact="dev/architecture/runtime/gc/models/sysml/generational-admission.sysml";
  attribute :>> premise="Authoritative source-slot rewrite and alias validity under the admitted full-scan route. Any future mature-scan exclusion additionally requires all generational writers, residual edges, major/weak/finalization and promotion-capacity premises; this packet grants no such exclusion. The map history requires both complete mature-to-young source slot selection and a separate pre-copy physical bound for any nursery census elimination.";
  attribute :>> boundary="EXISTING_OWNER_REQUIRES_SOURCE_BOUND_EVIDENCE";
 }
 part workSource:ImportedNeed {
  attribute :>> id="GW-S";
  attribute :>> authority="GambitRuntimeAssurance::work.source";
  attribute :>> artifact="dev/architecture/runtime/interfaces/models/sysml/component-assurance.sysml";
  attribute :>> premise="All copy/scan/chunk/Tail/private work producers and failure custody; queue emptiness is insufficient.";
  attribute :>> boundary="EXISTING_OWNER_REQUIRES_SOURCE_BOUND_EVIDENCE";
 }
 part hostFreeze:ImportedNeed {
  attribute :>> id="FZ-FREEZE";
  attribute :>> authority="GambitRcFreezePublication::freeze";
  attribute :>> artifact="dev/architecture/runtime/ffi/models/sysml/rc-freeze-publication.sysml";
  attribute :>> premise="Complete native writer/borrow/RC freeze and lifetime coverage, not merely an observed counter.";
  attribute :>> boundary="EXISTING_OWNER_REQUIRES_SOURCE_BOUND_EVIDENCE";
 }
 part controlBridge:ImportedNeed {
  attribute :>> id="CS-BRIDGE";
  attribute :>> authority="GambitContinuationSegments::bridge";
  attribute :>> artifact="dev/architecture/runtime/control/models/sysml/continuation-segments.sysml";
  attribute :>> premise="Actual shared-frame aliases, revisions, rooting, restore and dynamic-wind source correspondence.";
  attribute :>> boundary="EXISTING_OWNER_REQUIRES_SOURCE_BOUND_EVIDENCE";
 }
 part dependency0:Dependency { ref part :>> dependent=cutSource; ref part :>> prerequisite=cutProtocol; }
 part dependency1:Dependency { ref part :>> dependent=aliasSource; ref part :>> prerequisite=aliasLaw; }
 part dependency2:Dependency { ref part :>> dependent=boundarySource; ref part :>> prerequisite=cutProtocol; }
 part dependency3:Dependency { ref part :>> dependent=nativeAcceptance; ref part :>> prerequisite=cutSource; }
 part dependency4:Dependency { ref part :>> dependent=nativeAcceptance; ref part :>> prerequisite=aliasSource; }
 part dependency5:Dependency { ref part :>> dependent=nativeAcceptance; ref part :>> prerequisite=boundarySource; }
 part dependency6:Dependency { ref part :>> dependent=netBenefit; ref part :>> prerequisite=nativeAcceptance; }
 part external0:ExternalDependency { ref part :>> dependent=cutSource; ref part :>> prerequisite=hostFreeze; }
 part external1:ExternalDependency { ref part :>> dependent=cutSource; ref part :>> prerequisite=workSource; }
 part external2:ExternalDependency { ref part :>> dependent=aliasSource; ref part :>> prerequisite=generationSource; }
 part external3:ExternalDependency { ref part :>> dependent=aliasSource; ref part :>> prerequisite=controlBridge; }
 part external4:ExternalDependency { ref part :>> dependent=boundarySource; ref part :>> prerequisite=controlBridge; }
 part use0:Use { ref part :>> component=execution; ref part :>> question=cutProtocol; }
 part use1:Use { ref part :>> component=roots; ref part :>> question=cutProtocol; }
 part use2:Use { ref part :>> component=collector; ref part :>> question=cutProtocol; }
 part use3:Use { ref part :>> component=retirement; ref part :>> question=cutProtocol; }
 part use4:Use { ref part :>> component=roots; ref part :>> question=aliasLaw; }
 part use5:Use { ref part :>> component=control; ref part :>> question=aliasLaw; }
 part use6:Use { ref part :>> component=execution; ref part :>> question=cutSource; }
 part use7:Use { ref part :>> component=roots; ref part :>> question=cutSource; }
 part use8:Use { ref part :>> component=collector; ref part :>> question=cutSource; }
 part use9:Use { ref part :>> component=roots; ref part :>> question=aliasSource; }
 part use10:Use { ref part :>> component=control; ref part :>> question=aliasSource; }
 part use11:Use { ref part :>> component=generations; ref part :>> question=aliasSource; }
 part use12:Use { ref part :>> component=messages; ref part :>> question=boundarySource; }
 part use13:Use { ref part :>> component=control; ref part :>> question=boundarySource; }
 part use14:Use { ref part :>> component=retirement; ref part :>> question=boundarySource; }
 part use15:Use { ref part :>> component=qualification; ref part :>> question=nativeAcceptance; }
 part use16:Use { ref part :>> component=qualification; ref part :>> question=netBenefit; }
 part use17:Use { ref part :>> component=generations; ref part :>> question=netBenefit; }
 part sharingAliasUse:Use { ref part :>> component=sharing; ref part :>> question=aliasSource; }
 part sharingBoundaryUse:Use { ref part :>> component=sharing; ref part :>> question=boundarySource; }
 part placementCutUse:Use { ref part :>> component=allocationRegions; ref part :>> question=cutSource; }
 part placementCostUse:Use { ref part :>> component=allocationRegions; ref part :>> question=netBenefit; }
 part domainCutUse:Use { ref part :>> component=collectionDomains; ref part :>> question=cutSource; }
 part domainBoundaryUse:Use { ref part :>> component=collectionDomains; ref part :>> question=boundarySource; }
 part domainNativeUse:Use { ref part :>> component=collectionDomains; ref part :>> question=nativeAcceptance; }
 part workTransitions:SupportFactor {
  attribute :>> id="GW-work-transitions"; attribute :>> owner="quint"; attribute :>> domain="control";
  attribute :>> authority="GambitRuntimeAssurance::work.history";
  attribute :>> artifact="models/gambit/gc_work_contract.qnt";
  attribute :>> dependencies="models/library/gc/CollectionContract.qnt";
  attribute :>> scope="gc_work_contract:Test$";
  attribute :>> boundary="Existing finite private/publish/acquire/rescan histories only; no C source refinement";
  ref part :>> component=collector; ref part :>> requiredFor=nativeAcceptance;
 }
 part workSchedules:SupportFactor {
  attribute :>> id="GW-work-schedules"; attribute :>> owner="quint"; attribute :>> domain="control";
  attribute :>> authority="GambitRuntimeAssurance::work";
  attribute :>> artifact="models/gambit/gc_work_closure.qnt";
  attribute :>> dependencies="models/library/gc/WorkObligations.qnt";
  attribute :>> scope="gc_work_closure:initFixed/step/safe;seed3;1000samples;40steps;Test$";
  attribute :>> boundary="Typed queue results plus fixed worker-slot intent/claim/unlink/commit/release/delivery microsteps, lagging progress/query pins and stale-key settlement in existing two-worker abstraction; no exhaustive/liveness/C memory or general crash proof";
  ref part :>> component=collector; ref part :>> requiredFor=nativeAcceptance;
 }
 part workLifetimeAlgebra:SupportFactor {
  attribute :>> id="GW-work-lifetime-algebra"; attribute :>> owner="lean"; attribute :>> domain="data";
  attribute :>> authority="GambitRuntimeAssurance::work.induction";
  attribute :>> artifact="models/gambit/lean/WorkAccounting.lean";
  attribute :>> dependencies="";
  attribute :>> scope="GambitSMP.WorkAccounting:zeroCountAndEmptyQueuesExcludeHiddenWork;missingLifetimeCounterexample;reopenedWorkRevokesZeroCount;zeroCountAndProducerCoverageExcludeHiddenWork;missingPublishedLifetimeCounterexample;unobservedPreservesQueueCustody;confirmedEmptyRequiresEmptyQueue;acquiredObservationConservesWorkCount;busyMayRetainNonemptyQueue;mismatchedClaimKeyHasNoPayload;claimQueryReturnsOnlyRecordedItem;gateEncodingInjective;sealedGateZeroHasNoBorrowers;checkedBorrowStepFits;checkedGenerationSuccessor";
  attribute :>> boundary="Conditional ProducerLifetimeSafe algebra; current LeanPoo release identity in model; no scheduler or C census theorem";
  ref part :>> component=collector; ref part :>> requiredFor=nativeAcceptance;
 }
 part lastUserSchedules:SupportFactor {
  attribute :>> id="GW-last-users"; attribute :>> owner="quint"; attribute :>> domain="control";
  attribute :>> authority="GambitRuntimeAssurance::work.history";
  attribute :>> artifact="models/gambit/retirement_last_consumers.qnt";
  attribute :>> dependencies="models/gambit/runtime_retirement_quarantine.qnt";
  attribute :>> scope="retirement_last_consumers:all-declared-runs;runtime_retirement_quarantine:all-declared-runs";
  attribute :>> boundary="Existing finite last-consumer and unknown-join retention histories; distinct owner slices, not a joint C simulation or physical-stop proof";
  ref part :>> component=retirement; ref part :>> requiredFor=nativeAcceptance;
 }
 part workPublicationSource:SupportFactor {
  attribute :>> id="GW-publication-source"; attribute :>> owner="source"; attribute :>> domain="refinement";
  attribute :>> authority="GambitRuntimeAssurance::work.platform";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> dependencies="dev/knowledge/systems/shared-heap-smp-literature.org;dev/refactoring/modern-c/sharing-and-heap-domains.org;evidence/research/retained/modern-c/shared-heap-smp-design/take-current-translation-units.json;evidence/research/retained/modern-c/shared-heap-smp-design/take-input-attribution.json;evidence/research/retained/modern-c/shared-heap-smp-design/take-access-review.json;evidence/research/retained/modern-c/shared-heap-smp-design/take-translation-units.json;vendor/gambit/lib/mem.c;vendor/gambit/lib/makefile.in;vendor/gambit/lib/_mem/copy-reservations.inc;vendor/gambit/lib/_mem/object-scanning.inc;vendor/gambit/lib/_mem/continuation-roots.inc;vendor/gambit/lib/collector.h;vendor/gambit/lib/root.h;vendor/gambit/lib/_mem/rc-allocation.inc;vendor/gambit/include/_gambit/activity_log.h.in;vendor/gambit/lib/os_thread.c;vendor/gambit/lib/os_base.c;vendor/gambit/include/_gambit/setup_parameters.h.in;vendor/gambit/lib/lifecycle.h;vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> scope="Exact mem.c/os_thread.c TU provider binding -> initialized intent/publication -> unique source-closed claim settlement -> private/Tail custody under selected C memory order; lifetime disposal belongs to GW-termination-source";
  attribute :>> boundary="OPEN C producer/consumer and backend refinement; formal observations cannot satisfy this source factor";
  ref part :>> component=collector; ref part :>> requiredFor=nativeAcceptance;
 }
 part workTerminationSource:SupportFactor {
  attribute :>> id="GW-termination-source"; attribute :>> owner="source"; attribute :>> domain="refinement";
  attribute :>> authority="GambitRuntimeAssurance::work.source";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> dependencies="vendor/gambit/lib/os_setup.c;vendor/gambit/lib/_mem/root-tasks.inc;vendor/gambit/lib/_mem/heap-sections.inc;vendor/gambit/lib/_mem/object-scanning.inc;vendor/gambit/lib/_mem/copy-reservations.inc;vendor/gambit/lib/_mem/continuation-roots.inc;vendor/gambit/lib/_mem/memory-lifecycle.inc;vendor/gambit/lib/_mem/configuration.inc;vendor/gambit/lib/_mem/rc-allocation.inc;vendor/gambit/lib/_mem/copy-planning.inc;vendor/gambit/lib/collector.h;vendor/gambit/lib/root.h;vendor/gambit/lib/_setup/vm-lifecycle.inc;vendor/gambit/lib/setup.c;vendor/gambit/lib/os_thread.c;vendor/gambit/include/_gambit/activity_log.h.in;vendor/gambit/lib/os_base.c;vendor/gambit/include/_gambit/setup_parameters.h.in;vendor/gambit/lib/lifecycle.h;vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> scope="One publication-idle-phase-exit chain: producer lifetime through last publication, failed claim and idle; wait predicate, private/dequeued/Tail/weak debt, no postzero publisher and unknown-stop resource custody";
  attribute :>> boundary="OPEN complete C lifetime and phase/exit refinement; queue/count observations and conditional Lean laws alone are insufficient";
  ref part :>> component=collector; ref part :>> requiredFor=nativeAcceptance;
 }
 part dependency7:Dependency { ref part :>> dependent=aliasSource; ref part :>> prerequisite=cutSource; }
 part dependency8:Dependency { ref part :>> dependent=boundarySource; ref part :>> prerequisite=aliasSource; }
}
