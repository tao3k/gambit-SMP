/* Canonical source for runtime model bindings, dependency and obligation metadata.
 * String statuses are evidence classifications, not satisfaction certificates.
 * Normative predicates remain in interfaces.sysml and shared-runtime-contract.sysml.
 * No existing QNT/Lean source, runtime code or historical receipt is changed. */
package GambitRuntimeModelRelations {
    private import ScalarValues::*;
    alias completionContract for GambitCollectionCompletion;
    alias producerContract for GambitProducerCustody;
    alias atomicRefinement for GambitAtomicRefinement;
    alias childDiscovery for GambitChildDiscovery;
    alias executionOwner for GambitDevelopmentOrganization::development::architecture::runtime::execution;
    alias gcOwner for GambitDevelopmentOrganization::development::architecture::runtime::gc;
    alias controlOwner for GambitDevelopmentOrganization::development::architecture::runtime::control;
    alias ffiOwner for GambitDevelopmentOrganization::development::architecture::runtime::ffi;
    part def ContractBinding {
        attribute contractId : String;
        attribute ownerPath : String;
        attribute participantPaths : String;
        attribute producer : String;
        attribute consumer : String;
        attribute phaseScope : String;
        attribute structureModel : String;
        attribute structuralSymbols : String;
        attribute quintSource : String;
        attribute quintSymbols : String;
        attribute quintInitializer : String;
        attribute quintStep : String;
        attribute quintParameters : String;
        attribute quintCohort : String;
        attribute quintProperty : String;
        attribute temporalProperty : String;
        attribute leanSource : String;
        attribute leanSymbols : String;
        attribute argumentOrg : String;
        attribute evidenceReport : String;
        attribute inputManifest : String;
        attribute reportScope : String;
        attribute resultClass : String;
        attribute compositionStatus : String;
    }
    part def ProofObligation {
        attribute obligationId : String;
        attribute contractId : String;
        attribute responsibleModule : String;
        attribute proposition : String;
        attribute evidenceClass : String;
        attribute disposition : String;
        attribute missingPremise : String;
        attribute evidenceSource : String;
    }
    part relations {
        part rootHandoff : ContractBinding {
            attribute :>> contractId = "ROOT-HANDOFF";
            attribute :>> ownerPath = "dev/architecture/runtime/execution";
            attribute :>> participantPaths = "dev/architecture/runtime/execution; dev/architecture/runtime/gc; dev/architecture/runtime/ffi";
            attribute :>> producer = "execution + FFI root custodian";
            attribute :>> consumer = "GC scanner";
            attribute :>> phaseScope = "Final root-value handoff before scanner admission; no whole-VM census implied";
            attribute :>> structureModel = "dev/architecture/runtime/interfaces/models/sysml/interfaces.sysml";
            attribute :>> structuralSymbols = "RootHandoffAdmissionLaw; RootCutClosureLaw; ScanGrantLaw";
            attribute :>> quintSource = "models/gambit/host_root_participation.qnt";
            attribute :>> quintSymbols = "freezeRootState; releaseExecution; observeRoots; finalRootObserved; readerEligible; participationCompletion";
            attribute :>> quintInitializer = "initParticipation";
            attribute :>> quintStep = "participationStep";
            attribute :>> quintParameters = "No outer constants; imported release/acquire variant chosen by scenario";
            attribute :>> quintCohort = "p.policy == 0; omission cohorts 1 and 2 are negative controls";
            attribute :>> quintProperty = "participationSafe";
            attribute :>> temporalProperty = "participationCompletion";
            attribute :>> leanSource = "models/gambit/lean/HostRootParticipation.lean";
            attribute :>> leanSymbols = "frozenHandoffComposesRelocation; recordPublicationIsNotParticipation";
            attribute :>> argumentOrg = "dev/modeling/correspondence.org::#root-handoff";
            attribute :>> evidenceReport = "evidence/research/host-root-publication/participation-validation.md";
            attribute :>> inputManifest = "evidence/research/host-root-publication/participation.manifest.json";
            attribute :>> reportScope = "Historical report covers selected QNT and Lean input identities; no native refinement";
            attribute :>> resultClass = "historical-report-conditional-only";
            attribute :>> compositionStatus = "unresolved";
        }
        part controlOrigin : ContractBinding {
            attribute :>> contractId = "CONTROL-ORIGIN";
            attribute :>> ownerPath = "dev/architecture/runtime/control";
            attribute :>> participantPaths = "dev/architecture/runtime/control; dev/architecture/runtime/gc";
            attribute :>> producer = "control save/restore/capture";
            attribute :>> consumer = "GC continuation traversal";
            attribute :>> phaseScope = "Inventory sealed before root cut; resolution only after saved-frame traversal";
            attribute :>> structureModel = "dev/architecture/runtime/interfaces/models/sysml/interfaces.sysml";
            attribute :>> structuralSymbols = "OriginClosureLaw; ResumptionLaw";
            attribute :>> quintSource = "models/gambit/continuation_saved_stack_origin.qnt";
            attribute :>> quintSymbols = "saveCurrent; restoreNext; scanCurrentRoots; queueSavedContinuation; scanSavedContinuation; linkOwnership; rootCoverage; savedFrameRetained; traversalOrigin";
            attribute :>> quintInitializer = "init";
            attribute :>> quintStep = "step";
            attribute :>> quintParameters = "Two distinct selected live thread/origin IDs from 0..2";
            attribute :>> quintCohort = "Selected save/restore/root-scan/saved-traversal slice";
            attribute :>> quintProperty = "guardSound";
            attribute :>> temporalProperty = "progress";
            attribute :>> leanSource = "models/gambit/lean/SavedStackRetirementWindow.lean";
            attribute :>> leanSymbols = "nonConsumingUsePreservesRawOrigin; completeOriginsBoundLastRawAccess";
            attribute :>> argumentOrg = "dev/modeling/correspondence.org::#control-origin";
            attribute :>> evidenceReport = "evidence/research/host-root-publication/retirement-window-validation.md";
            attribute :>> inputManifest = "evidence/research/host-root-publication/retirement-window.manifest.json";
            attribute :>> reportScope = "Historical report covers Lean companion only; selected saved-stack-origin QNT is not a bound input of that report";
            attribute :>> resultClass = "Lean-report-only-QNT-source-characterization";
            attribute :>> compositionStatus = "unresolved";
        }
        part retirementWindow : ContractBinding {
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> ownerPath = "dev/architecture/runtime/gc";
            attribute :>> participantPaths = "dev/architecture/runtime/gc; dev/architecture/runtime/control; dev/architecture/runtime/ffi";
            attribute :>> producer = "GC phase coordinator + control/FFI producers";
            attribute :>> consumer = "resource reclamation / next collection reuse";
            attribute :>> phaseScope = "After strong/weak/cleanup and target-user drain; before backing reuse";
            attribute :>> structureModel = "dev/architecture/runtime/interfaces/models/sysml/interfaces.sysml";
            attribute :>> structuralSymbols = "StableRetirementLaw; FinalUseLaw";
            attribute :>> quintSource = "models/gambit/saved_stack_retirement_window.qnt";
            attribute :>> quintSymbols = "freezeProducers; witnessQueue; transferQueue; finishStrong; finishWeak; finishCleanup; windowSafe; queueCoverage; fullPhaseCoverage; windowCompletion";
            attribute :>> quintInitializer = "initWindow";
            attribute :>> quintStep = "windowStep";
            attribute :>> quintParameters = "Imported source cohort plus declared queue roles";
            attribute :>> quintCohort = "sourceCohort and w.fault == 0; omission cases remain separate";
            attribute :>> quintProperty = "windowSafe";
            attribute :>> temporalProperty = "windowCompletion";
            attribute :>> leanSource = "models/gambit/lean/SavedStackRetirementWindow.lean";
            attribute :>> leanSymbols = "emptyWitnessNeedsStableWindow; foreignFrameClosureDoesNotEmptySchemeQueue; phaseCompletionOrdersReuse";
            attribute :>> argumentOrg = "dev/modeling/correspondence.org::#retire-window";
            attribute :>> evidenceReport = "evidence/research/host-root-publication/retirement-window-validation.md";
            attribute :>> inputManifest = "evidence/research/host-root-publication/retirement-window.manifest.json";
            attribute :>> reportScope = "Historical report covers selected QNT and Lean input identities; no native refinement";
            attribute :>> resultClass = "historical-report-conditional-only";
            attribute :>> compositionStatus = "unresolved";
        }
        part workClosure : ContractBinding {
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> ownerPath = "dev/architecture/runtime/gc";
            attribute :>> participantPaths = "dev/architecture/runtime/gc; dev/architecture/runtime/execution";
            attribute :>> producer = "collector workers";
            attribute :>> consumer = "GC completion / execution reentry";
            attribute :>> phaseScope = "Bounded item/phase work; whole collection and target permission require separate refinements";
            attribute :>> structureModel = "dev/architecture/runtime/interfaces/models/sysml/interfaces.sysml";
            attribute :>> structuralSymbols = "WorkClosureLaw; CompletedEpochStabilityLaw; PhaseDrainAdmissionLaw; CreditDomainLaw; PhaseDrainStabilityLaw; CollectionCompletionLaw; ReclaimPermissionLaw; PermitConsumptionLaw; SuccessfulCollectionCompletionLaw; TicketConservationLaw; ChildAcceptanceLaw; FailedTransferCustodyLaw; ServiceWithdrawalLaw; ForwardingReadinessLaw; ChunkPublicationCutLaw; DequeueCustodyLaw; ParentScanSettlementLaw; SimulationAdmissionLaw; CanonicalSelectionLaw; DiscoverChildCommitLaw; FinishParentGuardLaw; ObjectPhaseClosureLaw; BatchPartitionLaw; ChildTaskBalanceLaw";
            attribute :>> quintSource = "models/library/gc/CollectionContract.qnt";
            attribute :>> quintSymbols = "publish; acquire; scan; rescan; finish; closureSafe; Safe";
            attribute :>> quintInitializer = "init";
            attribute :>> quintStep = "step";
            attribute :>> quintParameters = "Relocate=true, Mutation=none; also inspect Relocate=false separately";
            attribute :>> quintCohort = "One object, two roots, stopped mutators; not(done) excludes the withdrawn direct terminal-reopen trace";
            attribute :>> quintProperty = "Safe";
            attribute :>> temporalProperty = "";
            attribute :>> leanSource = "models/gambit/lean/WorkAccounting.lean";
            attribute :>> leanSymbols = "zeroCountAndEmptyQueuesExcludeHiddenWork; reopenedWorkRevokesZeroCount";
            attribute :>> argumentOrg = "dev/modeling/correspondence.org::#gc-work-closure";
            attribute :>> evidenceReport = "";
            attribute :>> inputManifest = "";
            attribute :>> reportScope = "No validation report admitted for this selected work-closure mapping";
            attribute :>> resultClass = "source-guard-excludes-withdrawn-trace";
            attribute :>> compositionStatus = "unresolved-producer-phase-permit-refinement";
        }
        /* Dependencies are consumer -> prerequisite, phase-scoped rather than
         * blocking waits. Inventory construction does not wait for GC completion. */
        dependency traversalNeedsHandoff from controlOrigin to rootHandoff;
        dependency workNeedsHandoff from workClosure to rootHandoff;
        dependency workNeedsOrigins from workClosure to controlOrigin;
        dependency retirementNeedsOrigins from retirementWindow to controlOrigin;
        dependency retirementNeedsWork from retirementWindow to workClosure;
    }
    part obligations {
        part rhcensus : ProofObligation {
            attribute :>> obligationId = "RH-CENSUS";
            attribute :>> contractId = "ROOT-HANDOFF";
            attribute :>> responsibleModule = "dev/architecture/runtime/execution";
            attribute :>> proposition = "All supported live roots and final writers appear in the handoff inventory";
            attribute :>> evidenceClass = "source-coverage";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Generated/native/foreign producer census and stable slot lifetime";
            attribute :>> evidenceSource = "docs/host-root-participation-source-map.md";
        }
        part rhorder : ProofObligation {
            attribute :>> obligationId = "RH-ORDER";
            attribute :>> contractId = "ROOT-HANDOFF";
            attribute :>> responsibleModule = "dev/architecture/runtime/execution";
            attribute :>> proposition = "Final writes precede release and scanner acquire in the same ownership epoch";
            attribute :>> evidenceClass = "memory-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Concrete atomics/collective ordering and host nonmutation";
            attribute :>> evidenceSource = "models/gambit/host_root_participation.qnt";
        }
        part rhreloc : ProofObligation {
            attribute :>> obligationId = "RH-RELOC";
            attribute :>> contractId = "ROOT-HANDOFF";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Logical identity projection relates old and relocated addresses without erasing missing/stale roots";
            attribute :>> evidenceClass = "conditional-proof-report";
            attribute :>> disposition = "conditional-only";
            attribute :>> missingPremise = "Identity-preserving abstraction and native slot/update mapping";
            attribute :>> evidenceSource = "models/gambit/lean/HostRootParticipation.lean";
        }
        part colink : ProofObligation {
            attribute :>> obligationId = "CO-LINK";
            attribute :>> contractId = "CONTROL-ORIGIN";
            attribute :>> responsibleModule = "dev/architecture/runtime/control";
            attribute :>> proposition = "Restore moves the resumed slot while another saved raw origin remains distinct";
            attribute :>> evidenceClass = "source-characterization";
            attribute :>> disposition = "source-slice-established";
            attribute :>> missingPremise = "All captures, denv/frame writers, serialization and exceptional exits still need coverage";
            attribute :>> evidenceSource = "vendor/gambit/include/gambit.h.in";
        }
        part cocensus : ProofObligation {
            attribute :>> obligationId = "CO-CENSUS";
            attribute :>> contractId = "CONTROL-ORIGIN";
            attribute :>> responsibleModule = "dev/architecture/runtime/control";
            attribute :>> proposition = "Every actual retained raw origin is declared before backing may be reclaimed";
            attribute :>> evidenceClass = "conditional-proof-report";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Whole continuation/FFI origin inventory; generic set inclusion is only a premise";
            attribute :>> evidenceSource = "models/gambit/lean/SavedStackRetirementWindow.lean";
        }
        part coresume : ProofObligation {
            attribute :>> obligationId = "CO-RESUME";
            attribute :>> contractId = "CONTROL-ORIGIN";
            attribute :>> responsibleModule = "dev/architecture/runtime/control";
            attribute :>> proposition = "Resumption reloads relocated roots and retains general multi-shot semantics under the admitted native boundary";
            attribute :>> evidenceClass = "source-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Concrete compiler/runtime frame map and dynamic-wind/native-exit refinement";
            attribute :>> evidenceSource = "vendor/gambit/lib/_kernel.scm";
        }
        part rwstable : ProofObligation {
            attribute :>> obligationId = "RW-STABLE";
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Empty-before and no-arrival imply empty-after in the same producer scope";
            attribute :>> evidenceClass = "conditional-proof-report";
            attribute :>> disposition = "conditional-only";
            attribute :>> missingPremise = "Actual queue freeze/transfer custody and no late issuers";
            attribute :>> evidenceSource = "models/gambit/lean/SavedStackRetirementWindow.lean";
        }
        part rwphase : ProofObligation {
            attribute :>> obligationId = "RW-PHASE";
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Transitive strong-before-weak-before-cleanup order precedes backing reuse";
            attribute :>> evidenceClass = "conditional-proof-report";
            attribute :>> disposition = "conditional-only";
            attribute :>> missingPremise = "Actual epoch identity, barrier semantics and full caller coverage";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part rwusers : ProofObligation {
            attribute :>> obligationId = "RW-USERS";
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> responsibleModule = "dev/architecture/runtime/ffi";
            attribute :>> proposition = "No target scanner, saved origin, native return or deferred foreign cleanup still uses reclaimed backing";
            attribute :>> evidenceClass = "source-coverage";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Target-specific last consumers and cancellation/failure custody";
            attribute :>> evidenceSource = "docs/saved-stack-retirement-window-recipe.md";
        }
        part wccount : ProofObligation {
            attribute :>> obligationId = "WC-COUNT";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Zero count plus producer-lifetime and queue premises exclude hidden private/queued work";
            attribute :>> evidenceClass = "conditional-proof-source";
            attribute :>> disposition = "conditional-only";
            attribute :>> missingPremise = "Scanning/continuation/weak/deferred work must project to the accounted workers";
            attribute :>> evidenceSource = "models/gambit/lean/WorkAccounting.lean";
        }
        part wcterminal : ProofObligation {
            attribute :>> obligationId = "WC-TERMINAL";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "A closed scan phase excludes same-phase producer steps; prior finish/rescan claim is withdrawn for the matching guarded source";
            attribute :>> evidenceClass = "guard-inspection-and-evidence-correction";
            attribute :>> disposition = "source-guard-excludes-prior-trace";
            attribute :>> missingPremise = "Current rescan has not(done); terminal stuttering, producer census, phase scope and formal requalification remain owed";
            attribute :>> evidenceSource = "models/library/gc/CollectionContract.qnt";
        }
        part wcprogress : ProofObligation {
            attribute :>> obligationId = "WC-PROGRESS";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Worker-team completion and epoch-specific result delivery follow under justified fairness";
            attribute :>> evidenceClass = "liveness-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Actual enrollment, merged resize requests, starvation/failure and worker drain";
            attribute :>> evidenceSource = "dev/architecture/runtime/gc/studies/gc-capacity-result-design.org";
        }
        part crossidentity : ProofObligation {
            attribute :>> obligationId = "CROSS-IDENTITY";
            attribute :>> contractId = "ALL";
            attribute :>> responsibleModule = "dev/architecture/runtime/interfaces";
            attribute :>> proposition = "VM/generation/context/epoch/resource identities agree across every mapped event";
            attribute :>> evidenceClass = "composition-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Bounded QNT slices erase identities carried by SysML; choose explicit injection/quotient";
            attribute :>> evidenceSource = "dev/architecture/runtime/interfaces/models/sysml/shared-runtime-contract.sysml";
        }
        part crossstep : ProofObligation {
            attribute :>> obligationId = "CROSS-STEP";
            attribute :>> contractId = "ALL";
            attribute :>> responsibleModule = "dev/architecture/runtime/interfaces";
            attribute :>> proposition = "Initial states and every allowed shared/hidden transition preserve neighbor rely conditions";
            attribute :>> evidenceClass = "composition-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Joint simulation and stable terminal behavior; no inference from separate checks";
            attribute :>> evidenceSource = "dev/modeling/standards.org";
        }
        part crossprogress : ProofObligation {
            attribute :>> obligationId = "CROSS-PROGRESS";
            attribute :>> contractId = "ALL";
            attribute :>> responsibleModule = "dev/architecture/runtime/interfaces";
            attribute :>> proposition = "Safety composition and liveness composition have independently discharged premises";
            attribute :>> evidenceClass = "liveness-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Fairness preservation under hiding; absence of circular waits and publication-before-wait";
            attribute :>> evidenceSource = "dev/modeling/standards.org";
        }
        part wcproducerclose : ProofObligation {
            attribute :>> obligationId = "WC-PRODUCER-CLOSE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "External enrollment closes while every admitted root/copy/still/continuation producer stays accounted";
            attribute :>> evidenceClass = "source-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Prove worker/chunk lifetime and exact phase membership from all entry paths";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wchandoffaccount : ProofObligation {
            attribute :>> obligationId = "WC-HANDOFF-ACCOUNT";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "A derived child is reserved and committed before its parent relinquishes custody";
            attribute :>> evidenceClass = "accounting-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Private, queued, scanning and transit domains are disjoint and complete";
            attribute :>> evidenceSource = "models/gambit/lean/WorkAccounting.lean";
        }
        part wcphasescope : ProofObligation {
            attribute :>> obligationId = "WC-PHASE-SCOPE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Strong and weak scans have distinct counters and weak wills can seed work after strong drain";
            attribute :>> evidenceClass = "source-characterization";
            attribute :>> disposition = "source-slice-established";
            attribute :>> missingPremise = "No claim of full worker or barrier refinement from source order";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wclateorder : ProofObligation {
            attribute :>> obligationId = "WC-LATE-ORDER";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Admission and phase completion serialize so a losing request cannot enqueue into a closed phase";
            attribute :>> evidenceClass = "concurrency-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Linearization, current rights, stable backing and memory order";
            attribute :>> evidenceSource = "dev/architecture/runtime/interfaces/models/sysml/collection-completion.sysml";
        }
        part wcterminalstutter : ProofObligation {
            attribute :>> obligationId = "WC-TERMINAL-STUTTER";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Terminal stuttering preserves scope and state without disabling legitimate next-phase work";
            attribute :>> evidenceClass = "temporal-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Selected CollectionContract has no finished stutter; phase and whole-cycle projections differ";
            attribute :>> evidenceSource = "models/library/gc/CollectionContract.qnt";
        }
        part rwpermitcustody : ProofObligation {
            attribute :>> obligationId = "RW-PERMIT-CUSTODY";
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Each resource permit binds its required phase cut, target generation, closed admission and last users";
            attribute :>> evidenceClass = "lifetime-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Do not impose full-cycle return on still-header cleanup or infer native disposal from it";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part rwforeigndelivery : ProofObligation {
            attribute :>> obligationId = "RW-FOREIGN-DELIVERY";
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> responsibleModule = "dev/architecture/runtime/ffi";
            attribute :>> proposition = "Deferred cleanup owns payload roots and resource custody before the original wrapper can disappear";
            attribute :>> evidenceClass = "foreign-custody-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Real native release callers, asynchronous delivery, failure and owner-thread restrictions";
            attribute :>> evidenceSource = "vendor/gambit/lib/c_intf.c";
        }
        part crosscompletionscope : ProofObligation {
            attribute :>> obligationId = "CROSS-COMPLETION-SCOPE";
            attribute :>> contractId = "ALL";
            attribute :>> responsibleModule = "dev/architecture/runtime/interfaces";
            attribute :>> proposition = "Phase drain, collection completion and target reclaim permission are distinct projections";
            attribute :>> evidenceClass = "composition-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Match strong/weak phase and producer generation without inventing a new collection epoch";
            attribute :>> evidenceSource = "models/gambit/gc_work_closure.qnt";
        }
        part wccallsitemap : ProofObligation {
            attribute :>> obligationId = "WC-CALLSITE-MAP";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Selected collector call-like occurrences are reproducibly mapped to source and producer families";
            attribute :>> evidenceClass = "source-census";
            attribute :>> disposition = "source-slice-established";
            attribute :>> missingPremise = "Lexical census does not prove generated/root/writer or dynamic callback closure";
            attribute :>> evidenceSource = "dev/architecture/runtime/interfaces/models/sysml/producer-custody.sysml";
        }
        part wccanonicalowner : ProofObligation {
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "CAS loser reuses a live canonical copy and scan obligation without settling the winner";
            attribute :>> evidenceClass = "concurrency-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Winner initialization visibility, ABA-free identity and scanning ownership";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wctransferrefine : ProofObligation {
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Native publish/dequeue substeps refine atomic finishScan while retaining in-flight obligations";
            attribute :>> evidenceClass = "accounting-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Private cursors, scan credit and unknown-effect custody across actual locks and barriers";
            attribute :>> evidenceSource = "models/gambit/gc_work_closure.qnt";
        }
        part rwcleanupproducers : ProofObligation {
            attribute :>> obligationId = "RW-CLEANUP-PRODUCERS";
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> responsibleModule = "dev/architecture/runtime/ffi";
            attribute :>> proposition = "Every admitted native release issuer retains descendant custody through failure and reentry";
            attribute :>> evidenceClass = "foreign-custody-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Open-world callbacks, vtables, explicit release, converter failure and teardown share issuer admission";
            attribute :>> evidenceSource = "vendor/gambit/lib/c_intf.c";
        }
        part rwteardownorder : ProofObligation {
            attribute :>> obligationId = "RW-TEARDOWN-ORDER";
            attribute :>> contractId = "RETIRE-WINDOW";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "RC and scanner services outlive every cleanup task that can still use them";
            attribute :>> evidenceClass = "shutdown-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "P0 cleanup TODO and destruction-before-cleanup order need replacement-specific admission";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wcdiscoveryshape : ProofObligation {
            attribute :>> obligationId = "WC-DISCOVERY-SHAPE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Current finishScan first seeds a fresh child while also settling the parent scan";
            attribute :>> evidenceClass = "source-characterization";
            attribute :>> disposition = "source-slice-established";
            attribute :>> missingPremise = "Source shape only; no native refinement follows";
            attribute :>> evidenceSource = "models/gambit/gc_work_closure.qnt";
        }
        part wcdiscoveryrefine : ProofObligation {
            attribute :>> obligationId = "WC-DISCOVERY-REFINE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Separate child discovery from parent settlement to expose native child progress before parent return";
            attribute :>> evidenceClass = "simulation-design";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Guarded discovery/edge coverage and canonical alias mapping preserve parent and child debt";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wcregioncover : ProofObligation {
            attribute :>> obligationId = "WC-REGION-COVER";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Object copies, growing scan regions and delegated first edges form a complete nonduplicated custody cover";
            attribute :>> evidenceClass = "layout-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Explicit region/edge projection rather than one physical chunk equals one abstract object";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wcmemoryorder : ProofObligation {
            attribute :>> obligationId = "WC-MEMORY-ORDER";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Actual profile visibility justifies chunk publication and scanner acceptance cuts";
            attribute :>> evidenceClass = "memory-model-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "CAS-before-copy is not ready; byte visibility, lock/barrier profile and tail-edge ownership";
            attribute :>> evidenceSource = "vendor/gambit/include/gambit.h.in";
        }
        part wcwakerefine : ProofObligation {
            attribute :>> obligationId = "WC-WAKE-REFINE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Counted seek after wake can occur without queued work while a phase producer remains active";
            attribute :>> evidenceClass = "guard-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Current QNT wake queued-work guard differs from native count-positive return path";
            attribute :>> evidenceSource = "models/gambit/gc_work_closure.qnt";
        }
        part wcfailurelate : ProofObligation {
            attribute :>> obligationId = "WC-FAILURE-LATE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Failed/unknown transfer and closed-phase late work preserve unfinished custody without duplicate issue";
            attribute :>> evidenceClass = "failure-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "No invented rollback return on void native marking paths; separate native-resource effects";
            attribute :>> evidenceSource = "vendor/gambit/lib/c_intf.c";
        }
        part crosssimulation : ProofObligation {
            attribute :>> obligationId = "CROSS-SIMULATION";
            attribute :>> contractId = "ALL";
            attribute :>> responsibleModule = "dev/architecture/runtime/interfaces";
            attribute :>> proposition = "Composed source-to-QNT relation preserves guards and observations with separate progress premises";
            attribute :>> evidenceClass = "composition-refinement";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Initial relation, finite internal rank, native visibility and failure-domain admission";
            attribute :>> evidenceSource = "dev/architecture/runtime/interfaces/models/sysml/atomic-refinement.sysml";
        }
        part wcdiscoveryguard : ProofObligation {
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Commit edge coverage only after matching reference handling and target custody while parent stays scanning";
            attribute :>> evidenceClass = "action-preservation";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Sealed slot census, current receipt, immediate policy, unique slot writer and unknown transfer exclusion";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wcfragmentclosure : ProofObligation {
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "A body fragment can settle without implying tail, object or phase closure";
            attribute :>> evidenceClass = "fragment-preservation";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Physical visit and exact assigned-edge completion; no recursive wait for child completion";
            attribute :>> evidenceSource = "dev/architecture/runtime/interfaces/models/sysml/child-discovery.sysml";
        }
        part wccanonicalphase : ProofObligation {
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Canonical collection identity persists while phase-scoped scan obligations have independent admission";
            attribute :>> evidenceClass = "identity-preservation";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Actual header writer census and skip/import certificates; do not reset native canonical identity";
            attribute :>> evidenceSource = "models/gambit/gc_work_closure.qnt";
        }
        part wcbatchpartition : ProofObligation {
            attribute :>> obligationId = "WC-BATCH-PARTITION";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Exact byte layout and exact semantic edge ownership compose without losing delegated first fields";
            attribute :>> evidenceClass = "coverage-preservation";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "Object/padding/marker partition differs from Body/Tail assignment; special layouts need separate adapters";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wctailsource : ProofObligation {
            attribute :>> obligationId = "WC-TAIL-SOURCE";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Movable copy first-field delegation matches inspected PAIR/default scanner skip branches";
            attribute :>> evidenceClass = "source-characterization";
            attribute :>> disposition = "source-slice-established";
            attribute :>> missingPremise = "Only named conditions and branches; generated descriptors and full native coverage remain open";
            attribute :>> evidenceSource = "vendor/gambit/lib/mem.c";
        }
        part wcnegativecontrols : ProofObligation {
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> responsibleModule = "dev/architecture/runtime/gc";
            attribute :>> proposition = "Retain legacy fault controls and legitimate sharing/cycles while adding richer omitted-guard scenarios";
            attribute :>> evidenceClass = "scenario-preservation";
            attribute :>> disposition = "open";
            attribute :>> missingPremise = "No new exploration claimed; per-fragment ownership and phase identity adapters must preserve witnesses";
            attribute :>> evidenceSource = "models/gambit/gc_work_closure.qnt";
        }
    }
}
