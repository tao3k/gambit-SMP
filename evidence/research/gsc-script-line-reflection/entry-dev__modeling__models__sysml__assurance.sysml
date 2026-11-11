/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitAssuranceRelations {
    private import ScalarValues::*;

    part def ModelRelation {
        attribute relationId : String;
        attribute semanticOwner : String;
        attribute producer : String;
        attribute consumer : String;
        attribute sourceArtifact : String;
        attribute targetArtifact : String;
        attribute stateProjection : String;
        attribute eventProjection : String;
        attribute assumptions : String;
        attribute counterexample : String;
        attribute sourceIdentityBound : Boolean;
        attribute initialStatesRelated : Boolean;
        attribute stepsRefinedOrStutter : Boolean;
        attribute assumptionsDischarged : Boolean;
        attribute progressRefined : Boolean;
        attribute compositionClaimed : Boolean;
    }
    requirement def CompositionAdmissionLaw {
        subject relation : ModelRelation;
        require constraint { not relation.compositionClaimed or
            (relation.sourceIdentityBound and relation.initialStatesRelated and
             relation.stepsRefinedOrStutter and relation.assumptionsDischarged and
             relation.progressRefined) }
    }
    /* These are necessary obligations. No model relation instance is declared
     * checked; no satisfy usage or external proof receipt is synthesized. */


    /* Source-chain and model associations; no native refinement asserted. */
    part def ReasoningProjection {
        attribute projectionId : String;
        attribute sourceModel : String;
        attribute selectorPath : String;
        attribute requestPath : String;
        attribute exports : String;
        attribute scope : String;
        attribute admissionBoundary : String;
    }
    part componentReasoning : ReasoningProjection {
        attribute :>> projectionId = "component-models";
        attribute :>> sourceModel = "dev/modeling/models/sysml/assurance.sysml";
        attribute :>> selectorPath = "dev/modeling/ascent/component-models.ss";
        attribute :>> requestPath = "dev/modeling/ascent/component-models.request.scm";
        attribute :>> exports = "Internal association/artifact/contractFactor joins; output clue(id,claim,polarity,source) and factor(id,name,value)";
        attribute :>> scope = "Derived model/source/receipt associations; journal scope selected by the caller task";
        attribute :>> admissionBoundary = "Hypotheses only; source identity is not model truth, native observation or execution authority";
    }
    part def FormalModelSet {
        attribute modelSetId : String;
        attribute ownerPath : String;
        attribute quintSource : String;
        attribute quintSymbols : String;
        attribute leanSource : String;
        attribute leanSymbols : String;
        attribute evidenceReport : String;
        attribute scope : String;
        attribute obligationIds : String;
    }
    part def ComponentModelUse {
        attribute componentId : String;
        attribute ownerPath : String;
        attribute bindingKind : String;
        attribute bindingId : String;
        attribute requiredModel : String;
        attribute stateProjection : String;
        attribute eventProjection : String;
        attribute openPremises : String;
        attribute obligationIds : String;
    }
    part formalSet0 : FormalModelSet {
        attribute :>> modelSetId = "incremental-build";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> quintSource = "models/build/incremental_build.qnt";
        attribute :>> quintSymbols = "initNoChange; initLeaf; initMacro; reuse; start; finish; publish; invalidate; cancel; discard; step; safe; noChangeWork; PopulationNodes; populationDeps; selectedInjection; inventoryAcyclic; initCut; beginCut; observeInput; sealCut; publishCut; worldWrite; cutPublicationSafe; smallDeps; boundaryDeps; selectedGraphExact; phasesRelated; boundaryReady; boundarySignature; frozenBoundary; reusableReceipt; commonIdentity; cConsumerEquivalent; linkerConsumerEquivalent; sameLengthIsInsufficient; bytesWellFormed; linkEligible; linkCutoff; cCutoff; failureBlocks; malformedBlocks; frameDatum; frameShape; scalarPayloadShape; shallowPairCounterexample; valueStable; rootEligible; valueEligible; mutate; relocate; rawReloadNeeded; missingRootBlocks; mutationBlocks";
        attribute :>> leanSource = "models/build/IncrementalBuild.lean";
        attribute :>> leanSymbols = "unaffectedDependency; emptyChangeHasNoAffected; reuseMatchesClean; projectionCutoff; validNoOpWork; budgetStepPreserves; budgetTracePreserves; returnedCreditCannotIncrease; agreementOnSmallerCut; completeCutCanGrow; affectedEdgeExtension; immutableReadExtendsTrace; receiptReuseMatchesClean; allConsumerCutoff; projectedStepPreserves; adaptiveTraceReplay; adaptiveOutputUnique; receiptBackedAdaptiveReuse; selectedIndexInjective; selectedEdgesExact; fullReadyProjects; selectedAndBoundaryReady; fullBudgetBoundsSelected; changedBoundaryRejectsFrozen; relationalTraceSafety; concreteSafetyFromRefinement; capabilityCoverageAppend; uncoveredCapabilityRejects; observationEqualityReflection; factorizationSufficient; scalarSummariesLoseOrder; byteEncodingInjective; framedAtomInjective; atomTagsSeparate; admittedCodecInjective; cleanConsumerCutoff; nonSuccessCannotIssue; reflectedFailureExcluded; readDatumFrameAppend; recursiveRoundtrip; recursiveEncodingInjective; decodeWholeEncoded; trailingTokensRejected; shortFrameRejected; emptyDatumRejected; emptyPairFrameRejected; canonicalNameIdentity; uninternedNameCollision; changedReachableValueRejects; logicalRelocationPreservesAdmission; rawAddressCopyCanBecomeStale; directSelfPairRefused; admissionNeedsRootCoverage; schemeReadbackConsumerReflection; equalEndpointsPermitDifferentRead; equalStringTreesCanLoseIdentity";
        attribute :>> evidenceReport = "evidence/research/gsc-scheme-value-admission/formal-results.json";
        attribute :>> scope = "Logical heap admission with explicit scalar/canonical/rank predicates; source-backed managed/RC root and writer/readback boundaries; actual Scheme acquisition, mutation exclusion, root/native scanner and consumer reflection remain open";
        attribute :>> obligationIds = "BF-BUILD-CUT; BF-BUILD-BUDGET";
    }
    part modelUse0 : ComponentModelUse {
        attribute :>> componentId = "build-planner";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> bindingKind = "model-set";
        attribute :>> bindingId = "incremental-build";
        attribute :>> requiredModel = "Dependency graph, complete input cuts, invalidation closure and output projections";
        attribute :>> stateProjection = "QNT signatures/outputs to Lean CutAgreement/CutComplete; current producer reads to cut members";
        attribute :>> eventProjection = "reuse/publish versus reuseMatchesClean/projectionCutoff; exact signature adequacy remains open";
        attribute :>> openPremises = "V-SNAPSHOT through V-COST refine D-SCALAR/D-BRIDGE and reuse ROOT-HANDOFF; stable interval, actual interner, moving roots, scalar/readback and consumer/effect bridge remain open";
        attribute :>> obligationIds = "BF-BUILD-CUT";
    }
    part modelUse1 : ComponentModelUse {
        attribute :>> componentId = "build-scheduler";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> bindingKind = "model-set";
        attribute :>> bindingId = "incremental-build";
        attribute :>> requiredModel = "Ready/running/staged/published/cancelled actions and shared credits";
        attribute :>> stateProjection = "QNT phase=1 count and used to Lean Budget; real nested jobs to weighted ownership";
        attribute :>> eventProjection = "start/finish to BudgetStep, traces to BudgetTrace; phase dependency and native progress still open";
        attribute :>> openPremises = "B-PROGRESS and B-POPULATION: one full-population host budget, parent-await-child token policy, job weights, fairness and memory pressure";
        attribute :>> obligationIds = "BF-BUILD-BUDGET";
    }
    part modelUse2 : ComponentModelUse {
        attribute :>> componentId = "build-publisher";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> bindingKind = "model-set";
        attribute :>> bindingId = "incremental-build";
        attribute :>> requiredModel = "Staging/commit, cancellation and input-generation stability";
        attribute :>> stateProjection = "QNT staged/out/stable to real output manifest; Lean projection theorem is not a commit proof";
        attribute :>> eventProjection = "publish/invalidate/cancel need per-step transactional refinement; no publication theorem claimed";
        attribute :>> openPremises = "B-SNAPSHOT and B-GROUP: coherent source image plus validated output catalogue, revocation/commit linearization, complete groups, reader lifetime and failure custody";
        attribute :>> obligationIds = "BF-BUILD-CUT";
    }
    part modelUse3 : ComponentModelUse {
        attribute :>> componentId = "gc-work";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> bindingKind = "runtime-binding";
        attribute :>> bindingId = "GC-WORK-CLOSURE";
        attribute :>> requiredModel = "Producer closure, private/queued/claimed/descendant custody and termination";
        attribute :>> stateProjection = "Reuse existing binding projection; no copy of GC model into build semantics";
        attribute :>> eventProjection = "Existing action/theorem correspondence remains conditional and source-specific";
        attribute :>> openPremises = "All real scan/weak/foreign producers, partial-copy frames and C weak-memory refinement";
        attribute :>> obligationIds = "BF-WORK";
    }
    part modelUse4 : ComponentModelUse {
        attribute :>> componentId = "host-roots";
        attribute :>> ownerPath = "dev/architecture/runtime/ffi";
        attribute :>> bindingKind = "runtime-binding";
        attribute :>> bindingId = "ROOT-HANDOFF";
        attribute :>> requiredModel = "Root value/slot publication and block/reentry participation";
        attribute :>> stateProjection = "Existing root handoff token is not a complete actual native root inventory";
        attribute :>> eventProjection = "Use exact existing binding; do not promote Boolean publication to native relocation proof";
        attribute :>> openPremises = "Actual writers, marker-before-allocation protection, nested acquired effects and reentry reload";
        attribute :>> obligationIds = "BF-PARTICIPATION";
    }
    part modelUse5 : ComponentModelUse {
        attribute :>> componentId = "continuation";
        attribute :>> ownerPath = "dev/architecture/runtime/control";
        attribute :>> bindingKind = "runtime-binding";
        attribute :>> bindingId = "CONTROL-ORIGIN";
        attribute :>> requiredModel = "Saved/current origins, frame traversal and resumption lifetime";
        attribute :>> stateProjection = "Existing binding abstraction; richer continuation graph remains open";
        attribute :>> eventProjection = "Existing source/theorem pair, no unbound companion result promotion";
        attribute :>> openPremises = "All frame/denv/deserialize/FFI writers and generation barriers";
        attribute :>> obligationIds = "BF-GENERATION";
    }
    part modelUse6 : ComponentModelUse {
        attribute :>> componentId = "resource-exit";
        attribute :>> ownerPath = "dev/architecture/runtime/execution";
        attribute :>> bindingKind = "runtime-binding";
        attribute :>> bindingId = "RETIRE-WINDOW";
        attribute :>> requiredModel = "Producer closure, ordered phases and target last use";
        attribute :>> stateProjection = "Existing retirement state is not the entire resource/OS-user shutdown";
        attribute :>> eventProjection = "Compose accepted release descendants and outcomes separately";
        attribute :>> openPremises = "WaitContext wake, thread affinity, OS joins, late callbacks and result disposition";
        attribute :>> obligationIds = "BF-RELEASE; BF-EXIT";
    }
}
