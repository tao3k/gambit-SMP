package GambitModernCBootstrapCohort {
  private import ScalarValues::*;
  ref part target = GambitRuntimeRoleRealization::cut0;
  ref part submissionGate = GambitModernCCommitAdmission::tests;
  attribute nativeAcceptance : Boolean = false;
  attribute referencePatchSourceImported : Boolean = false;
  part ownershipLifecycle : Boundary {
    attribute :>> id="ownership-lifecycle";
    attribute :>> route="allocator authority -> emitter operation inventory -> backed service -> repaired root and cursor view -> unique commit";
    attribute :>> invariant="Every operation binds owner, region generation, physical extent and access to its activation/group/attempt. Root-view revisions and region retirement have separate lifetimes. Full macro/store coverage and actual C provenance remain open source obligations.";
    attribute :>> benefit="Localize failures to capacity, demand accounting, backing lifetime, root reload or return geometry using the first violated source contract.";
    attribute :>> cost="Implement source-bound inventory and independent macro/store correspondence in existing research and Make lineage; qualify compiler progress separately.";
  }
  part def OwnershipContract {
    ref part boundary:Boundary;
    ref part systemInterface:GambitRuntimeComposition::BlueprintInterface;
    attribute id:String;
    attribute supplier:String;
    attribute consumer:String;
    attribute source:String;
    attribute formalDuty:String;
    attribute distinguishingObservation:String;
    attribute precondition:String;
    attribute postcondition:String;
    attribute frameCondition:String;
    attribute invalidation:String;
    attribute linearization:String;
    attribute workOrder:String default = "dev/refactoring/modern-c/tfib-producer-retry.org#family6-ownership-blueprint";
    attribute status:String="OPEN";
  }
  part physicalAuthorityContract:OwnershipContract {
    ref part :>> boundary=ownershipLifecycle;
    ref part :>> systemInterface=GambitRuntimeComposition::allocationGrantInterface;
    attribute :>> id="BC-OWN-PHYSICAL";
    attribute :>> precondition="Current allocator claim, object provenance and representable aligned footprint are independently established.";
    attribute :>> postcondition="Admit the full selected path or distinguish valid shortage from invalid authority before construction effects.";
    attribute :>> frameCondition="Demand and diagnostic metadata may change; they do not authorize construction stores outside the selected footprint.";
    attribute :>> invalidation="Region retirement or reassignment; current execution view must be reacquired after a relevant service or transfer.";
    attribute :>> linearization="Allocator claim validation under the existing gate plus continued execution custody; numeric pointer inclusion is not ownership.";
    attribute :>> supplier="section allocator and lifecycle";
    attribute :>> consumer="write-group footprint check";
    attribute :>> source="vendor/gambit/lib/_mem/allocation-limits.inc";
    attribute :>> formalDuty="Lean interval arithmetic; existing Quint ownership retirement/reuse and custody histories";
    attribute :>> distinguishingObservation="Valid shortage versus expired owner or outside cursor before any unbacked spill";
  }
  part groupDemandContract:OwnershipContract {
    ref part :>> boundary=ownershipLifecycle;
    ref part :>> systemInterface=GambitRuntimeComposition::blueprintInterface0;
    attribute :>> id="BC-OWN-DEMAND";
    attribute :>> precondition="A complete independent effect inventory identifies the executed fast or slow lowering path.";
    attribute :>> postcondition="The selected demand covers that path before its first effect; fast pairs and full slow reservation are not interchangeable.";
    attribute :>> frameCondition="No already committed effect may be charged again or replayed during retry.";
    attribute :>> invalidation="Changed lowering, macro expansion, alignment, handler preparation or conditional path.";
    attribute :>> linearization="Whole-group admission for the current attempt; later commit cannot authorize an earlier store.";
    attribute :>> supplier="GVM emitter and C macro effect definitions";
    attribute :>> consumer="group admission";
    attribute :>> source="vendor/gambit/gsc/_t-c-2.scm; vendor/gambit/include/gambit.h.in";
    attribute :>> formalDuty="FrameContract.lean complete operation inventory and prospective demand correspondence";
    attribute :>> distinguishingObservation="Closure allocation followed by copies and adjustment distinguishes repeated demand charging and retry-frame growth";
  }
  part serviceBackingContract:OwnershipContract {
    ref part :>> boundary=ownershipLifecycle;
    ref part :>> systemInterface=GambitRuntimeComposition::generatedEntryInterface;
    attribute :>> id="BC-OWN-SERVICE";
    attribute :>> precondition="Old-view spill backing, exact old root map and current demand identity precede handler displacement.";
    attribute :>> postcondition="Service preserves source custody and exposes the actual current return view, or a bounded diagnosed failure.";
    attribute :>> frameCondition="Backed service metadata is allowed; it is distinct from protected rest-construction effects.";
    attribute :>> invalidation="Frame displacement, callback, nested service, collection, or ownership change.";
    attribute :>> linearization="Read demand while still in its old authorized view, before the first displacement or spill.";
    attribute :>> supplier="admission old-frame/root view";
    attribute :>> consumer="limit handler and nested service";
    attribute :>> source="vendor/gambit/lib/_kernel.scm; vendor/gambit/lib/_mem/allocation-limits.inc";
    attribute :>> formalDuty="FrameContract.lean preEnterSpillNeedsOldExtent; rest_frame_publication.qnt demand and service identity";
    attribute :>> distinguishingObservation="Demand read precedes handler displacement; complete preparatory stores have prior backing";
  }
  part repairedViewContract:OwnershipContract {
    ref part :>> boundary=ownershipLifecycle;
    ref part :>> systemInterface=GambitRuntimeComposition::blueprintInterface1;
    attribute :>> id="BC-OWN-RETURN";
    attribute :>> precondition="Collector/root publication and the actual unwind descriptor belong to this invocation.";
    attribute :>> postcondition="The consumer reloads current roots and derives its first store from the actual returned local cursor.";
    attribute :>> frameCondition="Relocated root words may change; unrelated caller state and Scheme alias semantics remain protected.";
    attribute :>> invalidation="Root revision, cursor displacement or a new collection between save, unwind and use.";
    attribute :>> linearization="Consumer-side reload and post-unwind view acquisition, not a saved handler cursor.";
    attribute :>> supplier="collector/root consumers and internal return";
    attribute :>> consumer="resumed generated group";
    attribute :>> source="vendor/gambit/lib/mem.c; vendor/gambit/lib/_kernel.scm";
    attribute :>> formalDuty="Quint current root revision and reloading; FrameContract.lean firstStoreAddressFromUnwind";
    attribute :>> distinguishingObservation="Independent saved handler, post-unwind and first-store cursors plus current reloaded references";
  }
  part uniqueSettlementContract:OwnershipContract {
    ref part :>> boundary=ownershipLifecycle;
    ref part :>> systemInterface=GambitRuntimeComposition::generatedEntryInterface;
    attribute :>> id="BC-OWN-SETTLEMENT";
    attribute :>> precondition="Current per-protocol owner, activation, attempt and generation authorize the pending operation.";
    attribute :>> postcondition="The authorized operation settles once; legitimate user continuation reuse remains available.";
    attribute :>> frameCondition="No internal delivery or committed construction effect is replayed by cleanup, retry or user restoration.";
    attribute :>> invalidation="Attempt retirement, lost ownership or a later generation at the same address.";
    attribute :>> linearization="The protocol's existing guarded commit or READY claim; group phase and rest-record delivery are separate identities.";
    attribute :>> supplier="current grant and attempt lifecycle";
    attribute :>> consumer="generated writes, publication and commit";
    attribute :>> source="vendor/gambit/gsc/_t-c-2.scm; vendor/gambit/lib/_mem/allocation-limits.inc";
    attribute :>> formalDuty="rest_frame_publication.qnt unique effects, abandonment and retry progress; Lean final footprint";
    attribute :>> distinguishingObservation="One authorized attempt writes and publishes once across service return and nested interruption";
  }
  part def Boundary { attribute id:String; attribute route:String; attribute invariant:String; attribute benefit:String; attribute cost:String; }
  part refusalReentryContract:OwnershipContract {
    ref part :>> boundary=ownershipLifecycle;
    ref part :>> systemInterface=GambitRuntimeComposition::generatedEntryInterface;
    attribute :>> id="BC-OWN-REFUSAL-REENTRY";
    attribute :>> supplier="Exception unwind and diagnostic-fixture cleanup";
    attribute :>> consumer="The next rest or handler entry in the same execution context";
    attribute :>> source="vendor/gambit/lib/_kernel.scm; vendor/gambit/lib/_mem/rc-allocation.inc; vendor/gambit/lib/_mem/allocation-limits.inc";
    attribute :>> formalDuty="rest_frame_publication.qnt caught-entry composition and FrameContract.lean readiness distinction; actual C unwind refinement remains open";
    attribute :>> distinguishingObservation="Fresh exact fit versus refused-then-exact-fit in one process, with independent current fp, backing, roots and armed-probe state";
    attribute :>> precondition="A reported refusal is caught and returns control to Scheme; process-fatal exits are a separate outcome.";
    attribute :>> postcondition="Either the next public entry has its current backing/root/attempt prerequisites or the earlier transition remains diagnosed and unresolved.";
    attribute :>> frameCondition="No construction effect from the refused attempt; this does not require rolling back legitimate GC movement or service metadata.";
    attribute :>> invalidation="Exception unwinding, diagnostic limit restoration, stale local cursors or incomplete per-attempt retirement.";
    attribute :>> linearization="The observed return to the public continuation and validation of the next entry, not merely raising the exception.";
    attribute :>> workOrder="dev/refactoring/modern-c/family6-mechanism-assurance.org#refusal-composition";
  }
  part logicalSourceExtentContract:OwnershipContract {
    ref part :>> boundary=ownershipLifecycle;
    ref part :>> systemInterface=GambitRuntimeComposition::blueprintInterface1;
    attribute :>> id="BC-OWN-LOGICAL-EXTENT";
    attribute :>> supplier="Caller/capture producer's logical stop and successor descriptor";
    attribute :>> consumer="Frame walk and cross-break source custody";
    attribute :>> source="vendor/gambit/lib/_kernel.scm; vendor/gambit/lib/_mem/heap-sections.inc; vendor/gambit/lib/_mem/continuation-roots.inc";
    attribute :>> formalDuty="FrameContract.lean boundedCallerWalkStaysInSegment and smp_rest_record_lifetime histories; source provenance and actual successor reachability remain open";
    attribute :>> distinguishingObservation="A deep call chain may remain a current-break prefix; require a real successor edge with old pin held through final metadata use";
    attribute :>> precondition="Physical section/half and logical continuation extent have separate authoritative suppliers.";
    attribute :>> postcondition="A prefix result is not treated as a complete continuation walk or a cross-break witness.";
    attribute :>> frameCondition="Read only admitted source words and metadata; pin/release metadata changes are explicit.";
    attribute :>> invalidation="Changing the logical stop, following a break link, retiring a source half or releasing its last custody.";
    attribute :>> linearization="Successor admission while the old source pin still protects its final required use.";
    attribute :>> workOrder="dev/refactoring/modern-c/family6-mechanism-assurance.org#logical-extent";
  }
  // The image is an observation input, not an admitted native producer.
  part linkedImage84138 {
    ref part logicalExtent=logicalSourceExtentContract;
    ref part repairedReturn=repairedViewContract;
    ref part physicalAuthority=physicalAuthorityContract;
    attribute kind:String="linked-image-cuts";
    attribute profile:String="tests/contracts/modern-c/rest-native/image-cuts/84138e91.contract.json";
    attribute identities:String="{\"tests/contracts/modern-c/rest-native/image-cuts/84138e91.contract.json\":\"8f4edbcd80cee180ebbfdd39b8fe46a756f7f264445a02deb79ad1fe7baa11e4\"}";
    attribute sourceCorrespondence:String="UNESTABLISHED";
    attribute frameCondition:String="Read immutable image bytes only; no execution, memory mutation, breakpoint insertion, source substitution or native admission.";
    attribute observationWindow:String="Old parent is a numeric caller-SP slot value before overwrite; roots, pins, repaired fp, attempt and delivery need separate native observations.";
    attribute reachability:String="Valid current-half prefix, post-GC soft publication and caller-slot lifetime have separate assumptions; opposite terminal outcomes use separate invocations on one image.";
    attribute nativeAcceptance:Boolean=false;
  }
  part def Family6ChecklistItem {
    attribute number:Integer;
    attribute contractRefs:String;
    attribute delivery:String;
    attribute nativeClosure:String;
    attribute status:String="OPEN";
    attribute workOrder:String="dev/refactoring/modern-c/tfib-producer-retry.org#family6-checklist-4-12-contracts";
  }
  part def Family6EngineeringDomain {
    attribute id:String;
    attribute checklist:String;
    attribute question:String;
    attribute quintModules:String;
    attribute sourceObligation:String;
    attribute contractRefs:String;
    attribute workflowEntry:String="dev/refactoring/modern-c/family6-engineering.org#family6-engineering-domains";
    attribute nativeStatus:String="OPEN";
  }
  part compilerDomain:Family6EngineeringDomain {
    attribute :>> id="F6-COMPILER";
    attribute :>> checklist="4,5";
    attribute :>> question="First source failure and actual target second-pass progress";
    attribute :>> quintModules="bootstrap_cohort.qnt::bootstrap_cohort, grant_stability.qnt::grant_stability";
    attribute :>> sourceObligation="Matched source/host/input/prelude, reader/front-end binding and progress observations, distinguishing regression, complete self-pass lineage";
    attribute :>> contractRefs="BC-OWN-DEMAND, BC-OWN-SERVICE, BC-OWN-RETURN as implicated";
  }
  part footprintDomain:Family6EngineeringDomain {
    attribute :>> id="F6-FOOTPRINT";
    attribute :>> checklist="4,6";
    attribute :>> question="Complete prospective footprint and already-owned preparatory backing";
    attribute :>> quintModules="stack_interval_authority.qnt::stack_interval_authority, rest_argument_cursor.qnt::rest_argument_cursor";
    attribute :>> sourceObligation="FrameContract.lean complete inventory, physical provenance, demand origin and actual stores; StackIntervalAuthority.lean owned span";
    attribute :>> contractRefs="BC-OWN-PHYSICAL, BC-OWN-DEMAND, BC-OWN-SERVICE";
  }
  part custodyDomain:Family6EngineeringDomain {
    attribute :>> id="F6-CUSTODY";
    attribute :>> checklist="7";
    attribute :>> question="Source pin survives break until successor authority and last required old metadata use";
    attribute :>> quintModules="smp_resume_closure_extent.qnt::smp_rest_record_lifetime, smp_resume_closure_extent.qnt::smp_rest_reentry";
    attribute :>> sourceObligation="Complete native source-use inventory and actual pin/close/retire/reuse events";
    attribute :>> contractRefs="BC-OWN-PHYSICAL, BC-OWN-RETURN";
  }
  part deliveryDomain:Family6EngineeringDomain {
    attribute :>> id="F6-DELIVERY";
    attribute :>> checklist="8";
    attribute :>> question="Independent region/root/cursor revisions and one resumed delivery";
    attribute :>> quintModules="stack_interval_authority.qnt::rest_authority_revision, rest_frame_publication.qnt::rest_frame_publication, rest_slot_repair.qnt::rest_slot_repair";
    attribute :>> sourceObligation="Actual current region, root projection/reload, decoded unwind and first-store locals for the same activation/group/attempt";
    attribute :>> contractRefs="BC-OWN-RETURN, BC-OWN-SETTLEMENT";
  }
  part contentionDomain:Family6EngineeringDomain {
    attribute :>> id="F6-CONTENTION";
    attribute :>> checklist="9";
    attribute :>> question="One complete section claim by two contenders under locked validation";
    attribute :>> quintModules="rest_section_grant.qnt::rest_section_grant, rest_section_grant.qnt::rest_section_claim";
    attribute :>> sourceObligation="Real lock/atomic memory order, capacity, linearization, unsuccessful-contender custody and rollback correspondence";
    attribute :>> contractRefs="BC-OWN-PHYSICAL, BC-OWN-SETTLEMENT";
  }
  part qualificationDomain:Family6EngineeringDomain {
    attribute :>> id="F6-QUALIFICATION";
    attribute :>> checklist="10,11,12";
    attribute :>> question="One qualified sealed product, complete Family A and original eight natural completions";
    attribute :>> quintModules="bootstrap_cohort prerequisites and conditional local domain histories";
    attribute :>> sourceObligation="Same-image full Family A, original p2/jobs=3 then p1/jobs=4 in one 295/300 campaign, independent source/C/object/link audit";
    attribute :>> contractRefs="All five local contracts plus native producer and campaign evidence";
  }
  part def Family6DomainPremise {
    ref part supplier:Family6EngineeringDomain;
    ref part consumer:Family6EngineeringDomain;
    attribute fact:String;
  }
  part emittedOperationPremise:Family6DomainPremise {
    ref part :>> supplier=compilerDomain;
    ref part :>> consumer=footprintDomain;
    attribute :>> fact="Actual generated operation inventory, macro effects and emitted frame descriptors";
  }
  part priorBackingPremise:Family6DomainPremise {
    ref part :>> supplier=footprintDomain;
    ref part :>> consumer=deliveryDomain;
    attribute :>> fact="Physical old-frame spill backing and complete granted footprint";
  }
  part sourceCustodyPremise:Family6DomainPremise {
    ref part :>> supplier=custodyDomain;
    ref part :>> consumer=deliveryDomain;
    attribute :>> fact="Live source/root metadata custody through required reads and successor authority";
  }
  part currentClaimPremise:Family6DomainPremise {
    ref part :>> supplier=contentionDomain;
    ref part :>> consumer=deliveryDomain;
    attribute :>> fact="Current complete exclusive destination authority from actual synchronized claim";
  }
  part nativeDeliveryPremise:Family6DomainPremise {
    ref part :>> supplier=deliveryDomain;
    ref part :>> consumer=qualificationDomain;
    attribute :>> fact="Current same-image full Family A observations alongside qualified producer lineage";
  }
  part anchoredEffectsPremise:Family6DomainPremise {
    ref part :>> supplier=compilerDomain;
    ref part :>> consumer=footprintDomain;
    attribute :>> fact="Decode every lowered macro/inliner store and signed frame adjustment against one admission origin; local maxima at different cursors cannot establish the total footprint. FrameContract.lean stackOriginRebase and anchoredNewStackStoresInside are conditional on that complete inventory.";
  }
  part serviceRootMapPremise:Family6DomainPremise {
    ref part :>> supplier=compilerDomain;
    ref part :>> consumer=deliveryDomain;
    attribute :>> fact="Decode the fixed retry descriptor at the actual service edge: Scheme stack and register roots, raw spills and return geometry. Equal slot extent alone is insufficient. Later logical frame identity changes need not invalidate a non-servicing body; retain physical and representation correspondence.";
  }
  part independentCursorProbePremise:Family6DomainPremise {
    ref part :>> supplier=deliveryDomain;
    ref part :>> consumer=qualificationDomain;
    attribute :>> fact="Bind handler-save, post-unwind, grant and actual first-store events to the same image, processor, activation, group, attempt and current region/root view. Equal fp values are allowed; copying a grant sample into a store field is not independent observation. Pre-enter spill uses prior backing.";
  }
  attribute ownershipDeliveryScope:String="Family 6 implementation checklist 4-12. Local contract and model work follows the observed failure; native family ledger stays 5/12 until independent qualification.";
  part family6Item4:Family6ChecklistItem {
    attribute :>> number=4;
    attribute :>> contractRefs="BC-OWN-PHYSICAL, BC-OWN-DEMAND, BC-OWN-SERVICE, BC-OWN-RETURN, BC-OWN-SETTLEMENT as implicated";
    attribute :>> delivery="Repair the first target-GSC source defect, including reader/parser/binding or compiler progress when failure precedes emission.";
    attribute :>> nativeClosure="Matched host/input/prelude, first invalid contract and a before/after distinguishing regression.";
  }
  part family6Item5:Family6ChecklistItem {
    attribute :>> number=5;
    attribute :>> contractRefs="Item 4 repair; relevant demand/return/progress contracts and complete Make lineage";
    attribute :>> delivery="Complete actual target second-pass bootstrap with bounded demand/descriptor growth where implicated.";
    attribute :>> nativeClosure="Complete second-pass products and natural completion under the existing budget; retain historical _std timeout.";
  }
  part family6Item6:Family6ChecklistItem {
    attribute :>> number=6;
    attribute :>> contractRefs="BC-OWN-PHYSICAL, BC-OWN-DEMAND, BC-OWN-SERVICE";
    attribute :>> delivery="Whole-region one-word-short refusal with physical extent and parameter-cursor correspondence.";
    attribute :>> nativeClosure="Same sealed GSI records complete bounds and zero writes, pops or parameter mutation on refusal.";
  }
  part family6Item7:Family6ChecklistItem {
    attribute :>> number=7;
    attribute :>> contractRefs="BC-OWN-PHYSICAL, BC-OWN-RETURN";
    attribute :>> delivery="Preserve old source-segment custody across break until successor authority and last required metadata use.";
    attribute :>> nativeClosure="Same sealed GSI records native pin, handoff, last read and justified release.";
  }
  part family6Item8:Family6ChecklistItem {
    attribute :>> number=8;
    attribute :>> contractRefs="BC-OWN-RETURN, BC-OWN-SETTLEMENT";
    attribute :>> delivery="Current owner/epoch, root reload and unique delivery for all three rest spellings.";
    attribute :>> nativeClosure="Joint same-GSI identity, moved roots, actual resumed view and single delivery receipts.";
  }
  part family6Item9:Family6ChecklistItem {
    attribute :>> number=9;
    attribute :>> contractRefs="BC-OWN-PHYSICAL, BC-OWN-SETTLEMENT";
    attribute :>> delivery="Locked capacity validation and unique claim of the final eligible section by two contenders.";
    attribute :>> nativeClosure="Real same-GSI contention yields one claim with unsuccessful-contender custody and no overlapping authority.";
  }
  part family6Item10:Family6ChecklistItem {
    attribute :>> number=10;
    attribute :>> contractRefs="Production and complete same-image Family A evidence";
    attribute :>> delivery="Original p2, jobs=3, four cases.";
    attribute :>> nativeClosure="Four natural completions in the first leg of the original shared-budget campaign.";
  }
  part family6Item11:Family6ChecklistItem {
    attribute :>> number=11;
    attribute :>> contractRefs="Item 10 campaign and identical sealed GSI";
    attribute :>> delivery="Original p1, jobs=4, four cases after p2 in the same run.";
    attribute :>> nativeClosure="Four natural completions within the shared 295-second inner and 300-second outer limits.";
  }
  part family6Item12:Family6ChecklistItem {
    attribute :>> number=12;
    attribute :>> contractRefs="Items 4-11 evidence, complete Family A and source/product identity correspondence";
    attribute :>> delivery="Independent audit and Family 6 registration.";
    attribute :>> nativeClosure="Original eight natural completions and assertions in topology order, full Family A, exact source lock and patch, Make lineage and final maps, and Gate 2 evidence for the selected GSC and sealed GSI; only then update 5/12.";
  }
  part host : Boundary { attribute :>> id="host"; attribute :>> route="complete current compiler source graph -> independent AOT host ABI -> emitter for target ABI; interpreted igsc retained as a diagnostic"; attribute :>> invariant="Compile all compiler modules together, not a partial backend overlay. Host native ABI and emitted target ABI are distinct; host runtime is never linked into target. Source/SDK/argv and dependency assumptions remain explicit."; attribute :>> benefit="Break old-C/new-header bootstrap cycle and remove interpreted compiler execution from each target emission without restoring carrier aliases or importing repair runtime"; attribute :>> cost="One whole host compiler AOT build and host SDK storage; no automatic cache-reuse claim without complete source/effect dependency closure"; }
  part argv : Boundary { attribute :>> id="argv"; attribute :>> route="process.scm command-line/script-command-line -> igsc canonical processed argv -> main.scm command-args"; attribute :>> invariant="Strip Make runtime aliases from effective script argv, clear the obsolete script view, and preserve all compiler argument words"; attribute :>> benefit="Eliminate two inconsistent option views; real Make prelude/warnings/source arguments produce C instead of zero-output returns"; attribute :>> cost="One normalization per invocation; no general shell string decoder or global FFI rewrite claim"; }
  part inventory : Boundary { attribute :>> id="inventory"; attribute :>> route="leased source-state inputs -> all top-level lib/gsi/gsc _*.c -> bootclean -> complete generated hash inventory"; attribute :>> invariant="Required module and linker C units are known before deletion; failed emission cannot shrink the required set to zero"; attribute :>> benefit="Old module metadata cannot silently survive a changed FrameSpec/ModuleSpec/runtime ABI"; attribute :>> cost="All affected C products must be regenerated; correctness work is added, not an incremental-build speedup"; }
  part targetNative : Boundary { attribute :>> id="target-native"; attribute :>> route="same Bazel configure profile -> generated C -> target libgambit/gsi/gsc"; attribute :>> invariant="Existing O1 modules/O3 runtime and SMP/multiple-VM/threaded-VM flags; exact effective argv/headers recorded; artifact success and quiescence required"; attribute :>> benefit="One explicit target cohort replaces accidental reuse of old generated carrier accesses"; attribute :>> cost="No old C shortcut across incompatible layout; canonical compiler/root/lifetime consumers still need native acceptance"; }
  part temporaryRoots : Boundary { attribute :>> id="temporary-roots"; attribute :>> route="GC_SAVE/RESTORE1..3 and os_setup six service families -> execution_context.saved -> mark_execution_roots -> reload/clear"; attribute :>> invariant="All raw temporary-root consumers migrate with their scanner. 78 os_setup accesses retain existing conversion/result/error clearing behavior. No carrier alias is restored; fixed three-slot capacity is not arbitrary nested-FFI admission."; attribute :>> benefit="Source-complete execution-root ownership covers generated allocation helpers and OS service constructors instead of only six previously compiled C units"; attribute :>> cost="Existing context indirection at each access; no additional root slots or root-scan range; native GC/FFI progress remains to qualify"; }
  part selfPass : Boundary { attribute :>> id="self"; attribute :>> route="new target gsc -> fresh bootclean -> target self-source pass -> hash/identity receipt"; attribute :>> invariant="hostedSource and regeneration checkpoints are distinct; a host pass cannot suppress the real self pass"; attribute :>> benefit="Compiler/runtime agreement is checked through an actual target compiler invocation"; attribute :>> cost="Second source generation/compilation pass; no model or first-pass result substitutes for it"; }
  part semantics : Boundary { attribute :>> id="semantics"; attribute :>> route="new target gsc -exe -> tests/frame-continuation-roots.scm -> real map capture, two restores, GC and native call"; attribute :>> invariant="Original, 20 and 200 restored map results; 80 retained roots; expected wind/visit history; 11 completed forced GCs; native call count 3"; attribute :>> benefit="Exercise Gambit multi-shot semantics together with frame/GC/native consumers"; attribute :>> cost="Independent carrier retirement, all FFI callbacks and failed membership remain separate open gates"; }
  part startupCapacity : Boundary { attribute :>> id="startup-capacity"; attribute :>> route="current_vm_resize -> vm_resize_pstate -> GC resize_heap -> setup_pstate/setup_mem_pstate -> two physical startup sections per new context"; attribute :>> invariant="GC membership is the closed existing set; requested contexts are future consumers. A grant must cover already assigned physical sections plus two per pending context and bounded resume reserve. Unknown allocation or capped capacity below the floor cannot publish a grant. Proposed planner is not implemented."; attribute :>> benefit="Replace nominal global minimum with a physical reservation contract before member/thread publication; source and native evidence explain the host-budget p11 startup failure"; attribute :>> cost="Explicit growth reservation can increase peak physical sections; interval/allocator/rollback and C refinement remain open. No larger heap or forced p1 setting qualifies the failed SMP lane."; }
  part def Link { ref part producer:Boundary; ref part consumer:Boundary; }
  part e0:Link { ref part :>> producer=host; ref part :>> consumer=argv; }
  part e1:Link { ref part :>> producer=argv; ref part :>> consumer=inventory; }
  part e2:Link { ref part :>> producer=inventory; ref part :>> consumer=temporaryRoots; }
  part er:Link { ref part :>> producer=temporaryRoots; ref part :>> consumer=targetNative; }
  part e3:Link { ref part :>> producer=targetNative; ref part :>> consumer=selfPass; }
  part e4:Link { ref part :>> producer=selfPass; ref part :>> consumer=startupCapacity; }
  part ec:Link { ref part :>> producer=startupCapacity; ref part :>> consumer=semantics; }
  part def Obligation { ref part boundary:Boundary; attribute id:String; attribute method:String; attribute artifact:String; attribute premise:String; }
  part hostCheck:Obligation { ref part :>> boundary=host; attribute :>> id="BC-HOST"; attribute :>> method="native-host"; attribute :>> artifact="evidence/research/retained/modern-c/stress-gsi/dev-bc-host-audit.json"; attribute :>> premise="Historical executable, plan, probe and SDK bytes are retained. Current generator inputs differ. Qualify the complete current compiler graph and resolved host macro/ABI closure with real Make-shaped emission; historical host success is not current admission."; }
  part hostReceiptControl:Obligation { ref part :>> boundary=host; attribute toolRecoveryReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-bc-host-tool-recovery.json"; attribute compilerResourceReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-gradual-compiler-memory-guard.json"; attribute :>> id="BC-HOST-RECEIPT"; attribute :>> method="python-fixture"; attribute :>> artifact="evidence/research/retained/modern-c/stress-gsi/dev-bc-host-framework-nested-after.json"; attribute :>> premise="Conservatively bind nested gsc/lib Scheme inputs and reject external file aliases; actual read closure remains separate. Reject absent or malformed producer receipts, incomplete or unsettled two-pass histories, wrong generator/host ancestry and target runtime linkage. Decode the exact digest-checked receipt bytes. Fixture success qualifies the metadata checker only; native host and family gates remain open."; }
  attribute currentHostConstruction:String="evidence/research/retained/modern-c/stress-gsi/dev-c-host-scope.json; coherent-host FrameSpec has 2387 checks, 306 fixtures, 290 retained layout assertions, 31 unit-plan checks and 86 write-group checks. Current configured GCC/C23 standalone consumers execute 102 frame cases and preserve mem.h frame reserve ABI. Numeric C preserves one raw declaration, five out-of-line functions and five entry stubs; quiet and existing verbose modes both preserve the entire pending-plan C byte stream and line count; no C audit comment is emitted. Host policy is unchanged, all C host-dependency qualifications remain open, no target GSI or family credit; 5/12.";
  part def CSectionRole { attribute caseSource:String default = ""; attribute caseAnchor:String default = ""; attribute caseDuty:String default = ""; attribute id:String; attribute source:String; attribute anchor:String; attribute nativeKey:String; attribute consumerSource:String; attribute consumerAnchor:String; attribute placement:String; attribute custody:String; attribute gap:String; }
  part rawCDeclaration:CSectionRole { attribute :>> id="c-scope-declaration"; attribute :>> source="vendor/gambit/gsc/_ptree2.scm"; attribute :>> anchor="(define (add-c-decl declaration-string)"; attribute :>> nativeKey="declarations"; attribute :>> consumerSource="vendor/gambit/gsc/_t-c-1.scm"; attribute :>> consumerAnchor="(if (pair? c-decls)"; attribute :>> placement="Declarations are emitted before BEGIN_M_COD; file-level location does not prove that macro/private-name effects are independent of later host layout."; attribute :>> custody="Raw file-level declaration text remains distinct from compiler-produced wrappers; preserve order and identity."; attribute :>> gap="Header, macro, private host-name and callback dependency closure remains open; a raw string is not a host-neutrality proof."; attribute :>> caseSource="vendor/gambit/lib/_num.scm"; attribute :>> caseAnchor="(c-declare \"#include \\\"mem.h\\\"\" procedure-host)"; attribute :>> caseDuty="The actual numeric declaration includes internal mem.h. Qualify its effective macro/header and host-private dependency closure; file-level placement is not host neutrality."; }
  part outlinedCFunction:CSectionRole { attribute :>> id="c-scope-outlined-function"; attribute :>> source="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> anchor="(list 'c-function-decl"; attribute :>> nativeKey="out-of-line-functions"; attribute :>> consumerSource="vendor/gambit/include/_gambit/foreign_conversion.h.in"; attribute :>> consumerAnchor="#define ___BEGIN_CFUN_DEF(cproc)"; attribute :>> placement="OOL selection emits its own C function; CFUN_OOL saves/reloads context and returns conversion errors through temp1 and the caller label."; attribute :>> custody="The non-inline CFUN_SELECT branch has an explicit independent C-function node; its opaque body is preserved."; attribute :>> gap="The tag proves producer provenance only. Root, callback, error and private label dependencies require qualification before changing host policy."; attribute :>> caseSource="vendor/gambit/lib/_num.scm"; attribute :>> caseAnchor="(define ##mult-inner-loop"; attribute :>> caseDuty="The numeric OOL body writes existing bignum payload through native pointers and defines BIG_END_MINT_FLIP. Preserve preprocessor order, payload lifetime and conversion/return protocol; compiler-owned wrapper provenance does not make its body pure."; }
  part cEntryStub:CSectionRole { attribute :>> id="c-scope-entry-stub"; attribute :>> source="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> anchor="(define (targ-scan-c-procedure c-proc c-decls-queue)"; attribute :>> nativeKey="procedures"; attribute :>> consumerSource="vendor/gambit/gsc/_t-c-1.scm"; attribute :>> consumerAnchor="(targ-begin-cod rd-res wr-res"; attribute :>> placement="The Scheme C-entry stub remains one procedure host with its argument/RA stores and return descriptor; correct-arity pcontext and caller coverage before first writes remain open."; attribute :>> custody="Keep argument and return-address writes, CFUN_OOL context save/reload, JUMPRET and the all-live return descriptor together."; attribute :>> gap="Native callback/error, moving-GC root and multi-shot return coverage still required in the same target product."; attribute :>> caseSource="vendor/gambit/lib/_num.scm"; attribute :>> caseAnchor="(define (##flonum->ieee754-32 x)"; attribute :>> caseDuty="Four numeric bit-conversion c-lambda sites use typed argument/result conversion. Preserve entry root maps, all-live return descriptor, conversion errors and possible allocating result conversion together."; }
  part cInitializer:CSectionRole { attribute :>> id="c-scope-initializer"; attribute :>> source="vendor/gambit/gsc/_ptree2.scm"; attribute :>> anchor="(define (add-c-init initialization-code-string)"; attribute :>> nativeKey="initializers"; attribute :>> consumerSource="vendor/gambit/include/_gambit/module_generation.h.in"; attribute :>> consumerAnchor="#define ___BEGIN_MOD_C_INIT"; attribute :>> placement="Module initialization has its own init_mod function and existing ordered setup; moving ordinary Scheme procedures must not duplicate or reorder it."; attribute :>> custody="Initialization remains module-owned and ordered; zero observations in one module are not a global absence proof."; attribute :>> gap="Host/data dependencies and initialization order remain unqualified for other modules."; }
  part cForeignObject:CSectionRole { attribute :>> id="c-scope-object"; attribute :>> source="vendor/gambit/gsc/_ptree2.scm"; attribute :>> anchor="(define (add-c-obj name obj)"; attribute :>> nativeKey="objects"; attribute :>> consumerSource="vendor/gambit/gsc/_t-c-1.scm"; attribute :>> consumerAnchor="(if (pair? c-objs)"; attribute :>> placement="Module object macros are emitted before declarations and physical hosts; label/object references must keep the existing host-independent label mapping and root lifetime."; attribute :>> custody="Preserve existing module symbol, object identity and root lifetime; scope role adds no relocation authorization."; attribute :>> gap="Object/code identity, callback lifetime and moving-GC coverage remain native/source obligations."; }
  part foreignHostQualification:Obligation { attribute qualificationContract:String="dev/refactoring/modern-c/host-placement.org"; ref part :>> boundary=targetNative; attribute :>> id="BC-FOREIGN-HOST"; attribute :>> method="source-native"; attribute :>> artifact="evidence/research/retained/modern-c/stress-gsi/dev-pending-group-plan.json"; attribute :>> premise="OPEN: qualify declaration, generated C wrapper and opaque host-code effects before replacing the compilation-unit any-C fallback. Actual GCC selection is single host with limit zero; do not change the frozen profile, treat lexical absence of host macros as proof, or infer compiler memory from source size. Require C/GC/root/return consumers and existing FFI tests, then matched guarded compilation and same-product acceptance. This is source/native qualification, not a new Lean or duplicate QNT proof."; }
  part foreignResourceClosure:Obligation { ref part :>> boundary=targetNative; attribute :>> id="BC-FOREIGN-RESOURCES"; attribute :>> method="source-native"; attribute :>> artifact="evidence/research/retained/modern-c/stress-gsi/dev-c-host-procedure-qualification.json"; attribute :>> premise="OPEN: the DEV producer variant changes only the physical host policy. Its first configured GCC compilation found seven functions with undeclared r4: raw floating spills constructed set-r directly and raw reloads constructed register operands without resource accounting. Each generated host must own the read/write/declaration closure for every implicit spill/reload, not inherit another procedure resource union. Reuse targ-loc-no-invalidate for raw stores and record raw register reads, preserving cache state, code points, frame descriptors and body effects. The joint DEV numeric object compiles with unchanged configured GCC/C23 argv in 24.629 seconds and 1076969472 bytes sampled group RSS; only the host tag and 21 register resource definitions differ. Checkout Scheme remains unchanged. Candidate object compilation is not linked callback/root, target bootstrap or family admission. Existing QNT temporal and Lean frame obligations are unchanged; this closure has a source/native compiler oracle."; }
  part cEntryGeometry:Obligation { ref part :>> boundary=targetNative; attribute :>> id="BC-CENTRY-GEOMETRY"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/FrameContract.lean"; attribute :>> premise="Arithmetic owner only: cEntryExtraBound and cEntryCoveredByArrivalBacking prove that existing incoming stacked parameters leave at most 10 new words at current 3 argument registers/reserve 3/alignment 4; conservative 5-register handler backing is 15. restoreMarginFromBudget and restoredArrivalBacking cover disjoint lower loans conditional on one real interval. Pointer ownership, actual ABI equality and source extraction are not theorems here."; }
  part cEntryTemporal:Obligation { ref part :>> boundary=targetNative; attribute :>> id="BC-CENTRY-TEMPORAL"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/rest_frame_publication.qnt"; attribute :>> premise="Temporal owner only: 32 histories include caller/callee grant identity, fresh root-view scope, one commit, shortage custody, repaired epoch and stale post-poll refusal. Pre-service raw spill stores require already-owned slots and the exact raw-slot map; future refill cannot authorize an earlier store. Four legacy dimensional checks moved to Lean; no arithmetic or physical geometry is proved by Quint. Source/native delivery remains open."; }
  part cEntryRefinement:Obligation { ref part :>> boundary=targetNative; attribute :>> id="BC-CENTRY-REFINE"; attribute :>> method="source-native"; attribute :>> artifact="evidence/research/retained/modern-c/stress-gsi/dev-c-entry-arrival-adapter.json"; attribute :>> premise="OPEN: bind all ten delivery cuts to current producer/ABI and one GSI. Prefer an existing arrival handler-backing guarantee over a new per-C-entry allocation/retry protocol. Reserve at the resulting frame pointer, preserve after poll via the current restore interval, and never reuse the consumed caller token or stale root descriptor. No larger heap/census, new CFFI lifetime redesign or new runtime admission is credited."; }
  part def CEntryCluePublication { attribute id:String; attribute path:String; attribute formalClaim:String; attribute nativeClaim:String; attribute scope:String; }
  part admissionClues:CEntryCluePublication { attribute :>> id="modern-c-resumption-admission-contract"; attribute :>> path="evidence/scenarios/modern-c/resumption-admission-contract.view.json"; attribute :>> formalClaim="modern-c-resumption-admission-formal-controls-recorded"; attribute :>> nativeClaim="modern-c-resumption-admission-native-qualification-established"; attribute :>> scope="dev-resumption-admission-contract"; }
  part def CEntryProofJoin { attribute id:String; attribute seam:String; attribute qpath:String; attribute quintCheck:String; attribute lpath:String; attribute lemma:String; attribute receipt:String; attribute scope:String; attribute cuts:String; }
  part entryEnvelopeProof:CEntryProofJoin { attribute :>> id="entry-envelope"; attribute :>> seam="incoming pcontext / caller transfer / CFUN frame"; attribute :>> qpath="dev/refactoring/modern-c/models/quint/rest_frame_publication.qnt"; attribute :>> quintCheck="callerDoneThenEntryFreshGrantTest"; attribute :>> lpath="dev/refactoring/modern-c/models/lean/FrameContract.lean"; attribute :>> lemma="producerEnvelopeWithMacroClosure"; attribute intervalContract:String="dev/refactoring/modern-c/allocation-intervals.org"; attribute raProjectionReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-host-ra-projection-review.json"; attribute macroSources:String="vendor/gambit/include/_gambit/object_access.h.in,vendor/gambit/include/_gambit/value_types.h.in,vendor/gambit/gsc/_t-c-1.scm"; attribute preprocessorReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-gcc-macro-context.json"; attribute pointPreprocessorReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-gcc-point-context.json"; attribute :>> receipt="evidence/research/retained/modern-c/stress-gsi/dev-c-entry-proof-ownership.json"; attribute :>> scope="Conditional formal inputs only; arithmetic and temporal duties are exclusive; actual source mapping and same-GSI A remain open."; attribute :>> cuts="caller-transfer,grant-extent,c-entry-stores,native-entry"; }
  part restoredEnvelopeProof:CEntryProofJoin { attribute :>> id="restored-envelope"; attribute :>> seam="R root owners / W worker tails / lower loan / current epoch"; attribute :>> qpath="dev/refactoring/modern-c/models/quint/rest_frame_publication.qnt"; attribute :>> quintCheck="cEntryRefillHasFreshEpochTest"; attribute :>> lpath="dev/refactoring/modern-c/models/lean/FrameContract.lean"; attribute :>> lemma="restoredArrivalBacking"; attribute :>> receipt="evidence/research/retained/modern-c/stress-gsi/dev-c-entry-proof-ownership.json"; attribute :>> scope="Conditional formal inputs only; arithmetic and temporal duties are exclusive; actual source mapping and same-GSI A remain open."; attribute :>> cuts="resume-plan,resume-loan,resume-copy,post-poll-transfer"; }
  part handlerReturnProof:CEntryProofJoin { attribute :>> id="handler-return"; attribute :>> seam="handler FrameSpec / service effect boundary / actual internal return"; attribute :>> qpath="dev/refactoring/modern-c/models/quint/rest_frame_publication.qnt"; attribute :>> quintCheck="settledServiceAllowsNestedInterruptTest"; attribute :>> lpath="dev/refactoring/modern-c/models/lean/FrameContract.lean"; attribute :>> lemma="handlerAndRetryDifferent"; attribute :>> receipt="evidence/research/retained/modern-c/stress-gsi/dev-c-entry-proof-ownership.json"; attribute :>> scope="Conditional formal inputs only. Handler and retry coordinates differ; service completion is not entry authorization. Source/native evidence remains open."; attribute :>> cuts="handler-unwind,service-effects"; }
  part def CEntryDeliveryCut { attribute id:String; attribute source:String; attribute anchor:String; attribute duty:String; attribute nativeOracle:String; attribute obligation:String; attribute prerequisites:String; }
  part callerTransfer:CEntryDeliveryCut { attribute :>> id="caller-transfer"; attribute :>> source="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> anchor="(define (targ-gen-jump opnd ret nb-args poll? safe? next-lbl)"; attribute :>> duty="Plan write extent and handler backing at the resulting fp before changing RA or aliasing the callee; do not count backing slack as initialized roots. The shared targ-admit-write-group path first emits dirty unboxed spills and a raw-slot return map. Prove those spill slots already backed before their first store; the requested future refill cannot back them retroactively. The cache field-zero growth count is not a proved dirty/live boxing count: freeze the actual boxing inventory before admission and bind its bound to this same plan."; attribute :>> nativeOracle="Actual entry/call control: shortage before the first RA/argument store; full-region sentinel and original roots retained. Include dirty stack/register floats in the actual retry FrameSpec: raw spill bits are not pointer roots, boxed aliases remain roots, and post-GC reload consumes the repaired slot exactly once."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites=""; }
  part pollTransfer:CEntryDeliveryCut { attribute :>> id="post-poll-transfer"; attribute :>> source="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> anchor="(define (targ-end-of-block-checks poll? sn)"; attribute :>> duty="A poll may move the stack and epoch after the old write group commits. Obtain arrival backing from the repaired context/interval, not the pre-poll grant."; attribute :>> nativeOracle="Force the existing poll/GC path, record repaired fp/epoch and arrival extent before the first callee store; no duplicated call."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites="grant-extent,resume-copy,handler-unwind"; }
  part grantExtent:CEntryDeliveryCut { attribute :>> id="grant-extent"; attribute :>> source="vendor/gambit/lib/_mem/allocation-limits.inc"; attribute :>> anchor="static int group_footprint_fits"; attribute :>> duty="Resolve the owned active interval independently of the cursor, clip shared-stack room, check integer extents before forming pointers, and compose arrival backing with the actual retry view. Physical backing and logical initialized prefix are distinct. A resumed attempt must retain one finalized request shape; prove immutable emitted operands or reject extent mismatch before stores."; attribute :>> nativeOracle="Same-GSI accepted demand records logical end and arrival bound; one-word-short refusal retains custody with no sentinel or parameter mutation."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites="caller-transfer"; }
  part resumePlan:CEntryDeliveryCut { attribute :>> id="resume-plan"; attribute :>> source="vendor/gambit/lib/_mem/copy-planning.inc"; attribute :>> anchor="length>(___MSECTION_SIZE>>1)-___MSECTION_FUDGE"; attribute :>> duty="Keep source length plus existing fudge inside one destination half for every R owner; this is independent of the W worker ordinal."; attribute :>> nativeOracle="R=3 W=2: bind all three source lengths, owners, contexts and epochs to accepted physical intervals without extra sections."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites=""; }
  part resumeLoan:CEntryDeliveryCut { attribute :>> id="resume-loan"; attribute :>> source="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> anchor="___HIDDEN ___SIZE_TS restore_loan_words"; attribute :>> duty="The independent context lower heap loan is capped by space minus source length minus fudge; active workers and nonworkers must both retain the same arrival minimum."; attribute :>> nativeOracle="Observe actual loan limit and stack floor for both cases; prove no overlap or double-accounted worker tail at fixed heap budget."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites="resume-plan"; }
  part resumeCopy:CEntryDeliveryCut { attribute :>> id="resume-copy"; attribute :>> source="vendor/gambit/lib/_mem/capacity-resize.inc"; attribute :>> anchor="___HIDDEN ___BOOL move_continuation"; attribute :>> duty="Tie source_words, destination top and stack floor to the real post-copy cursor and current owner/epoch before publishing restored completion."; attribute :>> nativeOracle="Capture final copy cursor, context reload and first post-handler entry; no source-frame or old-epoch substitution."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites="resume-loan"; }
  part cEntryStores:CEntryDeliveryCut { attribute :>> id="c-entry-stores"; attribute :>> source="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> anchor="(define (targ-scan-c-procedure c-proc c-decls-queue)"; attribute :>> duty="Derive the additional extent from the incoming pcontext and existing aligned argument/RA frame. With a valid arrival grant, preserve the old no-safepoint spill and normal return descriptor."; attribute :>> nativeOracle="Cover 0/1/3/4/5 and large arities, CFUN context slot, moving GC/callback/error returns. If a retry is needed, derive roots from this pcontext; never a previous procedure frame."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites="post-poll-transfer,native-entry"; }
  part nativeEntry:CEntryDeliveryCut { attribute :>> id="native-entry"; attribute :>> source="vendor/gambit/lib/setup.c"; attribute :>> anchor="___SCMOBJ ___run"; attribute :>> duty="Existing bootstrap and native gateways must consume the same context arrival backing; this does not add a new FFI ownership system."; attribute :>> nativeOracle="Use existing startup and callback consumers on the identical GSI; source/ABI qualification only, not a claim that all later gc-ffi obligations are closed."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites=""; }
  part handlerUnwind:CEntryDeliveryCut { attribute :>> id="handler-unwind"; attribute :>> source="vendor/gambit/lib/_kernel.scm"; attribute :>> anchor="/* make ___fp point to internal return address */"; attribute :>> duty="Normalize only through the existing internal-return protocol: decode stored CFS, reverse RETI_RA, pop registers and remove alignment padding. Never replace resumed locals with the GC handler-frame cursor. Query actual post-unwind locals before first writes."; attribute :>> nativeOracle="Same GSI records handler fp, decoded stored/expanded frame size, post-pop fp, actual retry fp and first grant; prove addresses are the proper distinct views and no cursor is rolled backward."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites="service-effects"; }
  part serviceEffects:CEntryDeliveryCut { attribute :>> id="service-effects"; attribute :>> source="vendor/gambit/lib/_kernel.scm"; attribute :>> anchor="___group_demand_after(___ps, overflow);"; attribute :>> duty="Current source publishes a saved hp/fp and phase 2 before Scheme interrupt delivery. A pure demand hint must settle before effects; it owns no result/root bank. Recheck current locals after unwind. Do not clear construction results, RC roots or physical leases under this rule."; attribute :>> nativeOracle="Run actual allocation/heap-section change in an interrupt callback without a GC epoch change, plus nested slow admission. Published objects stay intact, no saved cursor replay, no occupied parent slot blocks the nested call. Cover stack handler and check-heap paths."; attribute :>> obligation="BC-CENTRY-REFINE"; attribute :>> prerequisites="resume-copy"; }
  part livePrefixLayout:Obligation { ref part :>> boundary=host; attribute :>> id="BC-LIVE-PREFIX"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/FrameContract.lean"; attribute :>> premise="requiredDepthCovers and requiredDepthLeast prove a least prefix for a supplied complete one-based required-slot list. Live raw values and stacked return addresses are required; dead logical tail slots are not. GVM extraction, fused pre-producer correspondence, C provenance and same-image GC remain source/native premises. QNT retains only temporal admission, retry and commit duties."; }
  attribute reverseEngineeringBoundary:String="Stop work and report to the user before any disassembly, decompilation or binary-to-source reconstruction is required. Source, declared metadata and artifact hashes suffice for the present host qualification work.";
  attribute hostNestedSupport:String="prim/prim support source is retained in the original SDK and historical source identities but omitted from the effective host copy. Bind the coherent source input under the existing lease; its availability is not evidence of branch activation or actual read closure.";
  part hostReadClosure:Obligation { ref part :>> boundary=host; attribute :>> id="BC-HOST-READS"; attribute :>> method="source-refinement"; attribute :>> artifact="evidence/research/retained/modern-c/stress-gsi/dev-bc-host-read-closure.json"; attribute :>> premise="The top-level input envelope is not the actual read closure. Observe path-reference, source path, runtime aliases, current readtable and macro-generated includes. The prim/prim include is conditional and omitted from the effective host copy; matching source is retained in the original SDK. Actual branch activation remains open. Quoted include data is not a read."; }
  part def HostDeliveryStage { attribute id:String; attribute prerequisite:String; attribute work:String; attribute receipt:String; attribute refusal:String; }
  part hostInputs:HostDeliveryStage { attribute :>> id="BC-HOST-INPUT"; attribute :>> prerequisite="retained host audit"; attribute :>> work="Reconcile complete current compiler inputs, host producer/SDK and effective include resolution. Keep the host ABI coherent and separate from the emitted target ABI."; attribute :>> receipt="Source-stable per-file before/after inventory, actual input resolution, GCC/profile identities and resolved host module closure."; attribute :>> refusal="Historical hashes match but generator bytes differ; partial emitter overlays and rewriting historical hashes cannot admit current emission."; }
  part hostControl:HostDeliveryStage {
    ref part sourceInputs = hostInputs;
    attribute :>> id="BC-HOST-CONTROL";
    attribute :>> prerequisite="BC-HOST-INPUT";
    attribute :>> work="Compare two identified interpreters on one actual module with the same formal Make prelude and compiler closure before any whole-host build, target inventory regeneration or core.";
    attribute :>> receipt="Matching comparison key, declared and executed host and loader per leg, and quiescent terminal receipts. The selected host returns from parse, exits naturally, emits fresh nonempty C and passes configured GCC/C23.";
    attribute :>> refusal="Missing reference, unbound or changed evidence, prelude drift, selected-host failure, false exit zero or reference-only success leaves the build prerequisite open.";
    attribute status:String="OPEN";
    attribute admitted:Boolean=false;
    attribute workOrder:String="dev/refactoring/modern-c/tfib-producer-retry.org#family6-formal-prelude-host-control";
  }
  part hostEmit:HostDeliveryStage { ref part control = hostControl; attribute :>> id="BC-HOST-EMIT"; attribute :>> prerequisite="BC-HOST-CONTROL"; attribute :>> work="Build the complete current host graph in the existing host role. Qualify Make-shaped compilation and linker emission using existing hosted seed entrypoints."; attribute :>> receipt="Current host bytes, actual compiler/link argv, cwd/environment and header/library inputs; natural exit, expected C output and current-emitter preflight/frame-map correspondence."; attribute :>> refusal="AOT emission qualification does not fabricate the complete two-pass producer required by bootstrap-input. Missing backing, outside-half cursors or absent output keep the stage open."; }
  part targetEmit:HostDeliveryStage { attribute currentNativeAudit:String="evidence/research/retained/modern-c/stress-gsi/dev-bc-host-audit.json"; attribute :>> id="BC-TARGET-C"; attribute :>> prerequisite="BC-HOST-EMIT"; attribute :>> work="Capture all required module and linker C names before destructive generation, then regenerate under the existing Make and target GCC/C23 profile."; attribute :>> receipt="Total required-name inventory, fresh source-to-output ownership, stable source inputs and actual target headers/argv; no host runtime linkage."; attribute :>> refusal="An empty post-clean directory cannot shrink coverage. One generated file or a hand-aligned kernel does not establish a coherent target cohort."; }
  part def HostControlBinding {
    ref part stage:HostDeliveryStage;
    attribute fixedInputs:String;
    attribute variedInput:String;
    attribute observationKey:String;
    attribute measures:String;
    attribute openRefinement:String;
  }
  part formalPreludeBinding:HostControlBinding {
    ref part :>> stage=hostControl;
    attribute :>> fixedInputs="Current source lock and compiler closure, module digest, resolved formal prelude and transitive includes, normalized Make command and environment, GCC/C23 profile and diagnostic ceiling.";
    attribute :>> variedInput="Selected interpreter and its coherent loader dependencies. Retain per-leg declared and actual identities. Private output paths are recorded coordinates.";
    attribute :>> observationKey="Run terminal receipt hash, module step, emission command, stream SHA-256 and line. Preserve actual argv, cwd, native outcome and process custody.";
    attribute :>> measures="Phase entry and return, completed macro and source position, work count, allocation and post-GC live-word deltas for a matched prefix, and signal with native fault PC where observed.";
    attribute :>> openRefinement="Join both legs on the full key with explicit missing observations. Distinguish current-source comparison from production admission and runtime performance.";
  }
  part hostControlAscent:Obligation {
    ref part :>> boundary=argv;
    ref part stage = hostControl;
    attribute :>> id="BC-HOST-CONTROL-ASCENT";
    attribute :>> method="receipt-bound ASCENT";
    attribute :>> artifact="evidence/dsl/checkpoint.ss";
    attribute :>> premise="Use make-repair-loop frontier and signals for each failed cut, compilerTraces for both legs, and a caller-owned paired selector. Reject stale or mixed event streams. Keep pair-to-native correspondence open.";
  }
  part hostControlQnt:Obligation {
    ref part :>> boundary=argv;
    ref part stage = hostControl;
    attribute :>> id="BC-HOST-CONTROL-QNT";
    attribute :>> method="quint";
    attribute :>> artifact="dev/refactoring/modern-c/models/quint/bootstrap_cohort.qnt";
    attribute :>> premise="family6CanBuild requires the matched pair and completion by the selected host. Preserve a bound reference failure. Run absence, substitution and phase/exit controls. Bind these predicates to actual receipts before native construction.";
  }
  part hostControlLean:Obligation {
    ref part :>> boundary=argv;
    ref part stage = hostControl;
    attribute :>> id="BC-HOST-CONTROL-LEAN";
    attribute :>> method="lean";
    attribute :>> artifact="dev/refactoring/modern-c/models/lean/BootstrapCohort.lean";
    attribute :>> premise="HostPair key equality and candidate output are necessary. Refine the key from actual source and input bytes, with immutable native receipts owning the premises.";
  }
  part hostControlWriteRefinement:Obligation {
    ref part :>> boundary=targetNative;
    ref part stage = targetEmit;
    attribute :>> id="BC-FAMILY6-WRITE-REFINE";
    attribute :>> method="quint and lean with native correspondence";
    attribute :>> artifact="dev/refactoring/modern-c/models/quint/rest_frame_publication.qnt";
    attribute geometry:String="dev/refactoring/modern-c/models/lean/FrameContract.lean";
    attribute workOrder:String="dev/refactoring/modern-c/tfib-producer-retry.org#family6-gate2-seven-sites";
    attribute status:String="OPEN";
    attribute :>> premise="Bind interpreted emission, new C, object, handler and allocator to one candidate image. Track every legacy site and variable path. BC-SELF separately qualifies target self-emission.";
  }
  part def Gate2LegacyUnit {
    attribute source:String;
    attribute sha256:String;
  }
  part gate2Prims:Gate2LegacyUnit { attribute :>> source="vendor/gambit/gsc/_prims.c"; attribute :>> sha256="e2262104d093b54498756e8cec83e190fe11402e83fbe94237e4ad449a1ad53c"; }
  part gate2Ptree:Gate2LegacyUnit { attribute :>> source="vendor/gambit/gsc/_ptree2.c"; attribute :>> sha256="54edbe817aff8cd1ff1bfeead029a4d5cb1c56a3c05dc5a17fa5490ef978a8fd"; }
  part gate2Eval:Gate2LegacyUnit { attribute :>> source="vendor/gambit/lib/_eval.c"; attribute :>> sha256="b1980ca2ff8bd5b1c610d99de11c6a5671492eaf554bc1bd88e7ae24d74dd4ef"; }
  part def Gate2LegacySite {
    ref part unit:Gate2LegacyUnit;
    attribute id:String;
    attribute line:Integer;
    attribute procedure:String;
    attribute block:String;
    attribute successor:String;
  }
  part gate2Site1:Gate2LegacySite { ref part :>> unit=gate2Prims; attribute :>> id="F6-20-1"; attribute :>> line=48593; attribute :>> procedure="c#setup-prim-expanders"; attribute :>> block="SLBL 40"; attribute :>> successor="new-cst, return 41"; }
  part gate2Site2:Gate2LegacySite { ref part :>> unit=gate2Prims; attribute :>> id="F6-20-2"; attribute :>> line=49606; attribute :>> procedure="c#setup-prim-expanders"; attribute :>> block="SLBL 124"; attribute :>> successor="heap check 1630, new-ref, return 125"; }
  part gate2Site3:Gate2LegacySite { ref part :>> unit=gate2Prims; attribute :>> id="F6-20-3"; attribute :>> line=49929; attribute :>> procedure="c#setup-prim-expanders"; attribute :>> block="SLBL 151"; attribute :>> successor="heap check 1642, new-ref, return 152"; }
  part gate2Site4:Gate2LegacySite { ref part :>> unit=gate2Prims; attribute :>> id="F6-20-4"; attribute :>> line=50178; attribute :>> procedure="c#setup-prim-expanders"; attribute :>> block="SLBL 171"; attribute :>> successor="heap check 1653, new-ref, return 172"; }
  part gate2Site5:Gate2LegacySite { ref part :>> unit=gate2Prims; attribute :>> id="F6-20-5"; attribute :>> line=59814; attribute :>> procedure="c#setup-prim-expanders"; attribute :>> block="GLBL 2331"; attribute :>> successor="poll 1918, new-ref, return 1342"; }
  part gate2Site6:Gate2LegacySite { ref part :>> unit=gate2Ptree; attribute :>> id="F6-20-6"; attribute :>> line=13837; attribute :>> procedure="c#br-app"; attribute :>> block="SLBL 10"; attribute :>> successor="prc-body, return 11"; }
  part gate2Site7:Gate2LegacySite { ref part :>> unit=gate2Eval; attribute :>> id="F6-20-7"; attribute :>> line=30201; attribute :>> procedure="##comp-do"; attribute :>> block="SLBL 20"; attribute :>> successor="heap check 21, ##sourcify, return 22"; }
  part gate2EmissionPair:Obligation {
    ref part :>> boundary=targetNative;
    ref part consumer=hostControlWriteRefinement;
    attribute :>> id="BC-FAMILY6-EMISSION-PAIR";
    attribute :>> method="focused Make emitter replay and independent translation review";
    attribute :>> artifact="evidence/fixtures/dev-family6-engineering/gate2-emission.recipe.json";
    attribute quint:String="dev/refactoring/modern-c/models/quint/bootstrap_cohort.qnt";
    attribute lean:String="dev/refactoring/modern-c/models/lean/BootstrapCohort.lean";
    attribute source:String="vendor/gambit/gsc/_front.scm";
    attribute anchor:String="(virtual.dump-gvm module-procs gvm-port)";
    attribute :>> premise="Freeze the selected emitter and its original module inputs. GVM and byte-matching C must come from one completed invocation. Validate each semantic edge and lowered effect separately. Keep successor observations indexed by their own Make generation.";
  }
  part gate2NativeWitness:Obligation {
    ref part :>> boundary=targetNative;
    ref part refinement=hostControlWriteRefinement;
    ref part emissionEvidence=gate2EmissionPair;
    attribute nativeCollection:String="gambit.gate2-collect / native-frame";
    attribute nativeIdentity:String="Source lock, Make generation, selected image and member, checked correspondence, named procedure, retry label, context, activation and invocation.";
    attribute settlement:String="One checked stream proves the backed old slots, handler save, independent unwind, repair grant, first effect and retirement. Expose a counterexample when any committed effect or entry is observed again before retirement.";
    attribute :>> id="BC-FAMILY6-CURSOR-WITNESS";
    attribute :>> method="same-image native evidence and ASCENT correspondence";
    attribute :>> artifact="vendor/gambit/lib/_mem/allocation-limits.inc";
    attribute :>> premise="For each legacy ID bind source span, GVM edge, exact emitted group, old descriptor, retry and return labels and the first effective store address. Use a rewrite or reachability witness if a site disappears.";
    attribute demandRead:String="Read pending demand with the caller cursor on the old side of the soft limit before handler displacement. Test complete physical footprint under current ownership separately.";
    attribute handlerSave:String="Read fp_saved at group_demand_after, with its frame role and owner, epoch and attempt.";
    attribute unwind:String="Independently decode and read fp_unwound at the internal-return retry edge before resume_view can assign the saved cursor.";
    attribute firstStore:String="Grant base matches fp_unwound. Read fp_write and effective address independently. Include signed displacement from authorized intervening adjustments, preserve the repaired view and observe one settlement.";
    attribute preEnterSpill:String="Every raw pre-enter spill slot needs exact old map classification and existing physical backing before its first store. The handler's own reserve is a separate check.";
    attribute refusal:String="A saved handler cursor that overwrites the caller after unwind, any unbacked pre-enter store, or a missing observation keeps Gate 2 open.";
  }
  part groupDemandAdmission:Obligation {
    ref part :>> boundary=targetNative;
    ref part nativeWitness=gate2NativeWitness;
    attribute :>> id="BC-FAMILY6-LOCAL-GROUP-ADMISSION";
    attribute :>> method="Quint route controls, Lean identity and interval contracts, C and native refinement";
    attribute :>> artifact="dev/refactoring/modern-c/family6-checklist-6-12-handoff.org#family6-production-successor";
    attribute :>> premise="Complete stack and heap footprint fits the current owned view before the first effect. The fitting zero-heap and positive-heap paths cross no safepoint, poll, reentry or pending service settlement and make no VM-wide attempt CAS.";
    attribute slowOwner:String="Mapped shortage uses an exclusive slot writer and a nonzero sequence scoped to the VM lifetime and processor incarnation. Validate context, activation, group point and current view. Protect pending service across transfer and reject reuse before retirement.";
    attribute invariants:String="Preserve old-frame backing, actual post-unwind cursors, fresh GC epoch, once-only effects, collector recovery reserve and locked shared-section claim.";
    attribute quint:String="dev/refactoring/modern-c/models/quint/rest_frame_publication.qnt";
    attribute lean:String="dev/refactoring/modern-c/models/lean/FrameContract.lean";
    attribute openEvidence:String="Require native current-image correspondence and source-backed attribution of shared attempt issuance. Performance remains conditional until the original ordered campaign completes.";
  }
  part def NumericHostCut { attribute id:String; attribute source:String; attribute anchor:String; attribute duty:String; attribute oracle:String; }
  part numericClassify:NumericHostCut { attribute :>> id="C scope and host resources"; attribute :>> source="vendor/gambit/gsc/_t-c-1.scm"; attribute :>> anchor="(define (targ-plan-compilation-unit"; attribute :>> duty="Preserve raw declarations and macro order. A whole opaque Scheme procedure must keep its entry and return labels. Prove all host resources, including dirty unboxed register spills and reloads."; attribute :>> oracle="Match PointIds, FrameSpecs and register use against a same-source paired emission. Reject unclassified raw bodies."; }
  part numericMovable:NumericHostCut { attribute emissionReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-numeric-production-emission.json"; attribute :>> id="Movable bignum admission"; attribute :>> source="vendor/gambit/lib/_num.scm"; attribute :>> anchor="(define-prim (##bignum.make k x complement?)"; attribute :>> duty="Publish k, x, complement and RA before service. Compute demand without moving hp. Under the current owner and epoch grant the whole aligned span before the header or payload store."; attribute :>> oracle="Force exact fit and short by one. Observe the actual hp, header and full destination independently."; }
  part numericReload:NumericHostCut { attribute :>> id="Moving GC reload and terminal settlement"; attribute :>> source="vendor/gambit/lib/_num.scm"; attribute :>> anchor="fits = !overflow && ___heap_alloc_fits"; attribute :>> duty="After GC reload repaired roots and RA and re-evaluate capacity for the same attempt. Unknown commit keeps roots and the original result until query and delivery settle."; attribute :>> oracle="Use GC relocation and lost commit response, then verify one initialization and one delivery."; }
  part numericStill:NumericHostCut { attribute :>> id="Still allocation branch"; attribute :>> source="vendor/gambit/lib/_mem/object-allocation.inc"; attribute :>> anchor="___EXP_FUNC(___WORD,___alloc_scmobj)"; attribute :>> duty="Keep still allocation separate from movable span authority. Preserve explicit refcount and result-root lifetime until Scheme owns the result."; attribute :>> oracle="Test both width branches and the still threshold, with allocation failure and actual result publication."; }
  part numericCEntry:NumericHostCut { attribute :>> id="Outlined C wrappers"; attribute :>> source="vendor/gambit/include/_gambit/foreign_conversion.h.in"; attribute :>> anchor="#define ___CFUN_OOL(cproc)"; attribute :>> duty="Preserve context publication, conversion failures, return label and typed conversions. Keep bignum raw pointers live only across their existing no-move lifetime."; attribute :>> oracle="Run multiply and four bit conversions with native success, conversion failure, moving GC and map continuation controls on the target."; }
  part numericDeclaration:NumericHostCut { attribute universalSource:String="vendor/gambit/gsc/_t-univ-2.scm"; attribute universalAnchor:String="(define (old-univ-rtlib-feature ctx feature)"; attribute stdSource:String="vendor/gambit/lib/_std.scm"; attribute stdAnchor:String="procedure-host"; attribute unicodeSource:String="vendor/gambit/lib/gambit/char/char#.scm"; attribute unicodeAnchor:String="(sort-by-decreasing-freq (table->list tbl))"; attribute compilerReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-declared-procedure-host.json"; attribute :>> id="Source-declared procedure host"; attribute :>> source="vendor/gambit/gsc/_ptree2.scm"; attribute :>> anchor="'c-procedure-host-decl"; attribute :>> duty="Preserve the declared raw C bytes and module order. All declarations must carry the unit contract, foreign procedures must be outlined, and no initializers or foreign objects may qualify through this route. Keep whole procedures without indexed sub-host splitting."; attribute :>> oracle="A real compiler must emit distinct layouts for marked and unmarked units, preserve C text, and pass existing FrameSpec and register resource controls. No old probe object enters the target link."; }
  part numericOwnedHeap:NumericHostCut { attribute :>> id="Owned heap interval"; attribute :>> source="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> anchor="current_heap_interval_matches"; attribute :>> duty="Use the current execution context and heap section claim. Validate [heapStart,hp,hardLimit] before subtracting integers. When sharing, bound hardLimit by the active or parked stack floor."; attribute :>> oracle="At hp equal to hardLimit, with one word still inside the physical half, refuse the one-word request without moving the cursor. Repeat with a stale heap owner and both stack states."; }
  part numericFitConsumer:NumericHostCut { attribute diagnosticReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-numeric-owned-interval.json"; attribute :>> id="Current capacity consumer"; attribute :>> source="vendor/gambit/lib/_mem/allocation-limits.inc"; attribute :>> anchor="int ___heap_alloc_fits"; attribute :>> duty="The production predicate uses the owned interval and aligned remaining words. Keep movable callers in the current owner and require the actual numeric and group consumer traces. Keep allocation-policy soft limit separate from the safety boundary."; attribute :>> oracle="Compile and run existing group callers plus numeric allocation against exact fit, hard-short by one, unowned half, and service success without sufficient room."; }
  part numericBank:NumericHostCut { attribute :>> id="GC scratch roots and return"; attribute :>> source="vendor/gambit/lib/_mem/root-origins.inc"; attribute :>> anchor="mark_saved (work, source);"; attribute :>> duty="The bank task scans the source context saved array. The mapped caller frame or break owns RA. Reload before using argument addresses and restore the original argument shape on both terminal paths."; attribute :>> oracle="Force relocation of x and observe the matching bank origin and RA under W less than R. Failure leaves the restored arguments available to the existing heap-overflow handler."; }
  part universalHostPlacement:Obligation { attribute startupSource:String="vendor/gambit/lib/setup.c"; attribute startupAnchor:String="___CALL_LABEL_HOST(___ps->context->pc,___ps);"; ref part :>> boundary=targetNative; attribute currentSource:String="vendor/gambit/gsc/_t-univ-2.scm"; attribute currentAnchor:String="(define-macro (define-old-univ-rtlib-feature"; attribute :>> id="BC-UNIV-HOST"; attribute :>> method="native-host-placement"; attribute :>> artifact="evidence/research/retained/modern-c/stress-gsi/dev-universal-procedure-host.json"; attribute :>> premise="Place feature registration groups and legacy branches in top-level procedures with explicit lexical parameters. Preserve table installation order, case keys, feature selection, result and unknown-feature error. Bound physical hosts, confirm the original GCC/C23 compile, and keep linked compiler semantics and self-emission as independent gates."; }
  part numericOrdering:Obligation { ref part :>> boundary=targetNative; attribute receipt:String="evidence/research/retained/modern-c/stress-gsi/dev-numeric-host-admission.json"; attribute :>> id="BC-NUM-ORDER"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/numeric_host_admission.qnt"; attribute :>> premise="Temporal order, identity and commit custody for the movable path only. Exact representation and source execution are separate gates."; }
  part numericGeometry:Obligation { ref part :>> boundary=targetNative; attribute theorem:String="footprintInside"; attribute :>> id="BC-NUM-GEOMETRY"; attribute :>> method="lean-source-refinement"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/NumericHostSpan.lean"; attribute :>> premise="OPEN: relate checked C23 byte-to-word rounding and optional 32-bit alignment to half-open physical header/payload bounds, without pointer overflow. No temporal ownership proof here."; }
  part kernelDispatch:Obligation { ref part :>> boundary=targetNative; ref part stage = targetSelf; attribute :>> id="BC-KERNEL-DISPATCH"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/kernel_handler_dispatch.qnt"; attribute emitterSource:String="vendor/gambit/gsc/_t-c-2.scm"; attribute emitterAnchor:String="(targ-gen-label-return* pre 'return-internal)"; attribute roleSource:String="vendor/gambit/lib/_kernel.scm"; attribute roleAnchor:String="(define-prim (##kernel-handlers)"; attribute bindingEmitterSource:String="vendor/gambit/gsc/_t-c-1.scm"; attribute bindingEmitterAnchor:String="(define (targ-dump-kernel-role-bindings objs)"; attribute setupSource:String="vendor/gambit/lib/setup.c"; attribute setupAnchor:String="setup_kernel_handlers ___PVOID"; attribute schemaSource:String="vendor/gambit/lib/setup.h"; attribute schemaAnchor:String="#define ___KERNEL_ROLES(X)"; attribute candidateReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-kernel-role-candidate.json"; attribute :>> premise="A setup-visible handler role must select its semantic entry in the same generated label table. Internal retry entries may change layout. Validate role-to-label binding before publishing handler pointers. Quint owns publish/reject/dispatch histories; source extraction and a linked GSI own actual layout and native qualification."; }
  part targetSelf:HostDeliveryStage { attribute :>> id="BC-SELF"; attribute :>> prerequisite="BC-TARGET-C"; attribute :>> work="Build and self-regenerate the target compiler with the new protocol. Exercise the existing small input before sealing a runtime."; attribute :>> receipt="Complete required phases, finite successful emission, matched current generator and target runtime identity, unchanged budget and quiescent processes."; attribute :>> refusal="Finite invariant failure is diagnosis only. Linking old-emitter objects with changed headers does not establish the new protocol."; }
  part sameImageA:HostDeliveryStage { attribute semanticTestSource:String="vendor/gambit/tests/smp/gc/rest-parameter-cuts.scm"; attribute semanticTestAnchor:String="(define (rest-cut-deep-drive form)"; attribute :>> id="BC-A"; attribute :>> prerequisite="BC-SELF"; attribute :>> work="Use one sealed GSI for all three rest spellings, cross-break custody, GC owner/epoch, full-region zero-write refusal and competing final-section claims."; attribute :>> receipt="Production-cut observations bound to that GSI, generator, generated C, headers, object and link inputs; query unknown outcomes without duplicate execution."; attribute :>> refusal="One-word sentinels, separate diagnostic binaries or model arithmetic cannot close the full-region and lifetime obligations."; }
  part restSectionCommit:Obligation {
    ref part :>> boundary=targetNative;
    ref part stage = sameImageA;
    attribute :>> id="BC-REST-SECTION-COMMIT";
    attribute :>> method="quint";
    attribute :>> artifact="dev/refactoring/modern-c/models/quint/rest_section_grant.qnt";
    attribute source:String="vendor/gambit/lib/_mem/heap-sections.inc";
    attribute anchor:String="___BOOL ___rest_extend_interval";
    attribute :>> premise="Validate before claiming under the VM lock, then preserve the selected geometry and custody through publication. A short request leaves the shared cursor and count unchanged. The sealed GSI must still establish actual last-section contention and full-range refusal.";
  }
  part def RestImplementationCut {
    ref part stage:HostDeliveryStage;
    ref part contract:OwnershipContract;
    attribute source:String;
    attribute branch:String;
    attribute model:String;
    attribute proofDuty:String;
    attribute nativePremise:String;
  }
  part restFullAdmissionCut:RestImplementationCut {
    ref part :>> stage=sameImageA;
    ref part :>> contract=groupDemandContract;
    attribute :>> source="vendor/gambit/lib/_mem/rc-allocation.inc";
    attribute :>> branch="allocation-grant/rest-demand/full-admission";
    attribute :>> model="rest_soft_grant.qnt; RestNativeObservation.oneWordShortCannotAuthorize";
    attribute :>> proofDuty="Compare the same complete demand against owned heap and stack room before effects; checking a grant does not debit it.";
    attribute :>> nativePremise="Bind actual lowered effects and the terminal refusal to the same sealed GSI; current source is not the old linked image.";
  }
  part restCallerPrefixCut:RestImplementationCut {
    ref part :>> stage=sameImageA;
    ref part :>> contract=logicalSourceExtentContract;
    attribute :>> source="vendor/gambit/lib/_kernel.scm; vendor/gambit/lib/_mem/heap-sections.inc; vendor/gambit/lib/_mem/continuation-roots.inc";
    attribute :>> branch="rest-source/custody/caller-prefix";
    attribute :>> model="captured_chain_seal; rest_section_claim; RestNativeObservation.pinCoversBothUses; RestNativeObservation.currentTailFitsIff";
    attribute :>> proofDuty="A valid current prefix does not acquire a successor. Admit the real break link independently; retain the old pin through both its last use and successor acquisition. Distinguish invalid reload, stack shortage, soft-only shortage and physical heap shortage.";
    attribute :>> nativePremise="Item 7 needs the actual successor descriptor and last old-source use. Item 9 needs two independently valid post-recovery views with physical shortage and one shared eligible candidate.";
  }
  part restReadyDeliveryCut:RestImplementationCut {
    ref part :>> stage=sameImageA;
    ref part :>> contract=uniqueSettlementContract;
    attribute :>> source="vendor/gambit/lib/_mem/rc-allocation.inc";
    attribute :>> branch="rest-activation/settlement/ready-delivery";
    attribute :>> model="rest_soft_grant.qnt; RestNativeObservation.deliveryNeedsPreservation";
    attribute :>> proofDuty="Capacity does not imply pin, root view, phase, writer or undelivered state. Preserve these obligations until settlement or complete fallible preparation before construction.";
    attribute :>> nativePremise="Actual mapped root movement, reloaded coordinates and one body delivery for all required forms.";
  }
  part restClaimPublicationCut:RestImplementationCut {
    ref part :>> stage=sameImageA;
    ref part :>> contract=physicalAuthorityContract;
    ref part claim=restSectionCommit;
    attribute :>> source="vendor/gambit/lib/_mem/heap-sections.inc";
    attribute :>> branch="allocation-grant/rest-section/claim-publication";
    attribute :>> model="rest_section_claim; RestNativeObservation.predictedRoomSurvivesPublication";
    attribute :>> proofDuty="Lock-held validation and fresh claim own global uniqueness. Post-lock publication preserves the claimed section and half under stable geometry and custody, and exposes the full room to the same attempt.";
    attribute :>> nativePremise="Observe the last eligible candidate, one claim, nonmutating loser, actual winner publication and renewed grant in the same VM and epoch. An unlock marker or sequential source check does not prove publication.";
  }
  part originalFamily:HostDeliveryStage {
    ref part admission = sameImageA;
    ref part runtimeRefinement = groupDemandAdmission;
    attribute identityControlReceipt:String="evidence/research/retained/modern-c/stress-gsi/dev-ordered-stress-identity-control.json";
    attribute :>> id="BC-FAMILY6";
    attribute :>> prerequisite="BC-A";
    attribute :>> work="Run the original four cases on the same sealed GSI, p2 with three jobs then p1 with four jobs. Preserve assertions, original heap, census and process custody.";
    attribute :>> receipt="One complete unspliced natural-exit family receipt within the shared envelope.";
    attribute :>> refusal="Partial, reordered or timed-out campaign retains DEV 5/12. Historical patch progress supplies counterexamples only.";
    attribute innerSeconds:Integer=295;
    attribute outerSeconds:Integer=300;
    attribute acceptedPrefix:Integer=5;
  }
  part argvCheck:Obligation { ref part :>> boundary=argv; attribute :>> id="BC-ARGV"; attribute :>> method="native-host"; attribute :>> artifact="vendor/gambit/gsc/igsc.scm"; attribute :>> premise="Effective script/process compiler argv and a real generated C output; no exit-zero-only success"; }
  part products:Obligation { ref part :>> boundary=targetNative; attribute :>> id="BC-PRODUCTS"; attribute :>> method="native-first-pass"; attribute :>> artifact=".cache/research/legacy-evidence/evidence/research/modern-c-bootstrap/hash-index-reviewed-bootstrap.recipe.json"; attribute :>> premise="All 51 generated products and three linked target artifacts with stable source and quiescent successful first pass; not complete self bootstrap or GC semantics"; }
  part rootControl:Obligation { ref part :>> boundary=temporaryRoots; attribute :>> id="BC-TEMP"; attribute :>> method="native-control"; attribute :>> artifact="vendor/gambit/tests/runtime-roles.c"; attribute :>> premise="All three scratch-root macro families reload collector-updated roots, clear them and isolate contexts; old macro compilation fails; projection only, not linked GC"; }
  part qnt:Obligation { ref part :>> boundary=inventory; attribute :>> id="BC-QNT"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/bootstrap_cohort.qnt"; attribute :>> premise="Two abstract coverage classes require universal coverage of all 51 native filenames, including 5 linker products; argv agreement, self-pass distinction and no host linkage; finite safety is not native success"; }
  part coverage:Obligation { ref part :>> boundary=inventory; attribute :>> id="BC-COVER"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/BootstrapCohort.lean"; attribute :>> premise="Universal per-class coverage reflects complete filename coverage only under total required-name mapping. One representative per class is insufficient. Actual source manifest/compilation correctness remains a native refinement obligation."; }
  part lean:Obligation { ref part :>> boundary=temporaryRoots; attribute :>> id="BC-REFINE"; attribute :>> method="lean-source-refinement"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/RuntimeRoles.lean"; attribute :>> premise="OPEN: prove actual generated FrameSpec/root consumers and C barriers preserve the existing conditional root laws; host compiler semantic trust stays explicit"; }
  part native:Obligation { ref part :>> boundary=selfPass; attribute :>> id="BC-NATIVE"; attribute :>> method="native"; attribute :>> artifact=".cache/research/legacy-evidence/evidence/research/modern-c-bootstrap/hash-index-reviewed-bootstrap.recipe.json"; attribute :>> premise="Actual source and self passes plus real semantic case required. Complete official bootstrap additionally needs two occurrences of each phase1..4. Known pre-generated/uncanonical argv failures and interpreted timeout remain retained."; }
  part earlyGC:Obligation { ref part :>> boundary=semantics; attribute :>> id="BC-EARLY-GC"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/lib/mem.c"; attribute :>> premise="Default-heap new compiler must initialize primitive tables across real GC before any map admission. Larger initial heap is diagnostic only. Five observed collections and a heap-sensitive outcome do not prove the exact lost root or responsible refactoring."; }
  part ascent:Obligation { ref part :>> boundary=semantics; attribute :>> id="BC-ADMISSION"; attribute :>> method="ascent"; attribute :>> artifact="dev/modeling/ascent/commit-admission.rules.scm"; attribute :>> premise="T-COHORT/T-MAP/T-SMP and M-REFINE stay missing until exact current-source observations exist; no synthetic or historical score transfer"; }
  part capacityQnt:Obligation { ref part :>> boundary=startupCapacity; attribute :>> id="BC-CAP-QNT"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/context_startup_capacity.qnt"; attribute :>> premise="Proposed growth grant/initialization conservation; old unclamped floor, dense live regions, closed-census-as-target and unknown-as-grant counterexamples; not current C correctness"; }
  part capacityLean:Obligation { ref part :>> boundary=startupCapacity; attribute :>> id="BC-CAP-LEAN"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/ContextStartupCapacity.lean"; attribute :>> premise="Physical-section arithmetic is conditional on allocator correspondence, checked bounds, complete roots and actual successful reservation"; }
  part capacityNative:Obligation { ref part :>> boundary=startupCapacity; attribute :>> id="BC-CAP-NATIVE"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/lib/setup.c"; attribute :>> premise="OPEN: unchanged profile host-budget p11 GSC and compiled program must initialize without fatal heap overflow; single-context map success cannot close this gap"; }
  part ownershipLifecycleRefinement : Obligation {
    ref part :>> boundary=ownershipLifecycle;
    attribute :>> id="BC-OWNERSHIP-LIFECYCLE";
    attribute :>> method="source refinement with Lean geometry, Quint histories and receipt-bound ASCENT";
    attribute :>> artifact="dev/refactoring/modern-c/tfib-producer-retry.org#family6-ownership-lifecycle";
    attribute :>> premise="OPEN: bind complete actual write/allocation/spill inventories to FrameContract.lean and actual authority/root/service/return/commit events to rest_frame_publication.qnt. Preserve missing evidence, original 295/300 campaign and native progress 5/12.";
  }
}
