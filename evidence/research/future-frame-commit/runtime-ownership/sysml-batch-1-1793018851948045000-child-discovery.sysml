/* Necessary design predicates and unimplemented QNT action contracts.
 * Object identity, fragment identity and edge identity are distinct domains.
 * No runtime counter, QNT transition, satisfy instance or Lean theorem added. */
package GambitChildDiscovery {
    private import ScalarValues::*;
    private import GambitCollectionCompletion::*;
    private import GambitRuntimeInterfaces::*;
    enum def EdgeProgress { Unseen; Resolving; Covered; }
    enum def FragmentProgress { Preparing; Scanning; Settled; }
    part def CanonicalObjectKey {
        part collection : CollectionScope;
        part oldOrigin : ResourceScope;
    }
    part def EdgeIdentity {
        part scope : PhaseScope;
        part sourceFragment : ResourceScope;
        attribute slotIndex : Integer;
        attribute descriptorRevision : Integer;
    }
    part def CanonicalSelectionWitness {
        attribute freshWinner : Boolean;
        attribute existingAlias : Boolean;
        attribute winnerCustodyKnown : Boolean;
        attribute sameCollectionOrigin : Boolean;
        attribute canonicalBefore : Integer;
        attribute canonicalAfter : Integer;
        attribute selectionCommitted : Boolean;
    }
    requirement def CanonicalSelectionLaw {
        subject selection : CanonicalSelectionWitness;
        require constraint {
            not selection.selectionCommitted or
            (selection.sameCollectionOrigin and selection.winnerCustodyKnown and
             selection.canonicalBefore >= 0 and
             ((selection.freshWinner and not selection.existingAlias and
               selection.canonicalAfter == selection.canonicalBefore + 1) or
              (selection.existingAlias and not selection.freshWinner and
               selection.canonicalAfter == selection.canonicalBefore)))
        }
    }
    part def DiscoverCommitWitness {
        attribute parentBefore : FragmentProgress;
        attribute parentAfter : FragmentProgress;
        attribute edgeBefore : EdgeProgress;
        attribute edgeAfter : EdgeProgress;
        attribute assignedSlotExclusive : Boolean;
        attribute phaseAndDescriptorMatch : Boolean;
        attribute sourceReferenceUpdateKnown : Boolean;
        attribute canonicalCustodyOrValidClosure : Boolean;
        attribute noUnknownAcceptance : Boolean;
        attribute canonicalBefore : Integer;
        attribute canonicalAfter : Integer;
        attribute parentDebtBefore : Integer;
        attribute parentDebtAfter : Integer;
        attribute discoveryCommitted : Boolean;
    }
    requirement def DiscoverChildCommitLaw {
        subject stepWitness : DiscoverCommitWitness;
        require constraint {
            not stepWitness.discoveryCommitted or
            (stepWitness.parentBefore == FragmentProgress::Scanning and
             stepWitness.parentAfter == FragmentProgress::Scanning and
             stepWitness.edgeBefore == EdgeProgress::Resolving and
             stepWitness.edgeAfter == EdgeProgress::Covered and
             stepWitness.assignedSlotExclusive and stepWitness.phaseAndDescriptorMatch and
             stepWitness.sourceReferenceUpdateKnown and stepWitness.canonicalCustodyOrValidClosure and
             stepWitness.noUnknownAcceptance and stepWitness.canonicalBefore == stepWitness.canonicalAfter and
             stepWitness.parentDebtBefore == 1 and stepWitness.parentDebtAfter == 1)
        }
    }
    part def FinishFragmentWitness {
        attribute parentBefore : FragmentProgress;
        attribute parentAfter : FragmentProgress;
        attribute assignedInventorySealed : Boolean;
        attribute uncoveredAssignedEdges : Integer;
        attribute unresolvedTransfers : Integer;
        attribute physicalVisitComplete : Boolean;
        attribute scopeAndCustodianMatch : Boolean;
        attribute parentDebtBefore : Integer;
        attribute parentDebtAfter : Integer;
        attribute finishCommitted : Boolean;
    }
    requirement def FinishParentGuardLaw {
        subject stepWitness : FinishFragmentWitness;
        require constraint {
            not stepWitness.finishCommitted or
            (stepWitness.parentBefore == FragmentProgress::Scanning and
             stepWitness.parentAfter == FragmentProgress::Settled and
             stepWitness.assignedInventorySealed and stepWitness.uncoveredAssignedEdges == 0 and
             stepWitness.unresolvedTransfers == 0 and stepWitness.physicalVisitComplete and
             stepWitness.scopeAndCustodianMatch and stepWitness.parentDebtBefore == 1 and
             stepWitness.parentDebtAfter == 0)
        }
    }
    part def ObjectPhaseClosureWitness {
        attribute copyAndInitializationCustodySettled : Boolean;
        attribute bodyFragmentsSettled : Boolean;
        attribute tailFragmentsSettled : Boolean;
        attribute importedCoverageValid : Boolean;
        attribute noUnknownObjectUsers : Boolean;
        attribute objectPhaseClosedClaimed : Boolean;
    }
    requirement def ObjectPhaseClosureLaw {
        subject closure : ObjectPhaseClosureWitness;
        require constraint {
            not closure.objectPhaseClosedClaimed or
            (closure.copyAndInitializationCustodySettled and closure.bodyFragmentsSettled and
             closure.tailFragmentsSettled and closure.importedCoverageValid and closure.noUnknownObjectUsers)
        }
    }
    part def BatchPartitionWitness {
        attribute physicalLayoutExact : Boolean;
        attribute descriptorPhaseValid : Boolean;
        attribute bodyTailEdgeSetsDisjoint : Boolean;
        attribute requiredEdgesCompletelyAssigned : Boolean;
        attribute skippedRelationsClassified : Boolean;
        attribute everyDeferredTailHasCustodian : Boolean;
        attribute emptyEdgeVisitObligationsCovered : Boolean;
        attribute batchReadableClaimed : Boolean;
    }
    requirement def BatchPartitionLaw {
        subject batch : BatchPartitionWitness;
        require constraint {
            not batch.batchReadableClaimed or
            (batch.physicalLayoutExact and batch.descriptorPhaseValid and
             batch.bodyTailEdgeSetsDisjoint and batch.requiredEdgesCompletelyAssigned and
             batch.skippedRelationsClassified and batch.everyDeferredTailHasCustodian and
             batch.emptyEdgeVisitObligationsCovered)
        }
    }
    part def TaskBalanceTransition {
        attribute issuedBefore : Integer;
        attribute issuedAfter : Integer;
        attribute settledBefore : Integer;
        attribute settledAfter : Integer;
        attribute unfinishedBefore : Integer;
        attribute unfinishedAfter : Integer;
        attribute newTasks : Integer;
        attribute newlySettled : Integer;
        attribute transitionClaimed : Boolean;
    }
    requirement def ChildTaskBalanceLaw {
        subject ledger : TaskBalanceTransition;
        require constraint {
            not ledger.transitionClaimed or
            (ledger.issuedBefore >= 0 and ledger.settledBefore >= 0 and ledger.unfinishedBefore >= 0 and
             ledger.newTasks >= 0 and ledger.newlySettled >= 0 and ledger.unfinishedAfter >= 0 and
             ledger.issuedBefore == ledger.settledBefore + ledger.unfinishedBefore and
             ledger.issuedAfter == ledger.issuedBefore + ledger.newTasks and
             ledger.settledAfter == ledger.settledBefore + ledger.newlySettled and
             ledger.unfinishedAfter == ledger.unfinishedBefore + ledger.newTasks - ledger.newlySettled and
             ledger.issuedAfter == ledger.settledAfter + ledger.unfinishedAfter)
        }
    }
    part def StateDomain {
        attribute domainId : String;
        attribute identityScope : String;
        attribute stateFields : String;
        attribute invariant : String;
        attribute obligationId : String;
    }
    part def ActionContract {
        attribute actionId : String;
        attribute guard : String;
        attribute updateRule : String;
        attribute accounting : String;
        attribute frameRule : String;
        attribute obligationId : String;
    }
    part def ScenarioContract {
        attribute caseId : String;
        attribute kind : String;
        attribute currentInitializer : String;
        attribute history : String;
        attribute requiredOutcome : String;
        attribute evidenceBoundary : String;
        attribute obligationId : String;
    }
    part def PreservationCase {
        attribute caseId : String;
        attribute actionIds : String;
        attribute guardPremises : String;
        attribute establishedAfter : String;
        attribute obligationId : String;
    }
    part def DiagramEdge {
        attribute diagramId : String;
        attribute groupId : String;
        attribute groupLabel : String;
        attribute edgeId : String;
        attribute fromState : String;
        attribute toState : String;
        attribute actionId : String;
        attribute label : String;
    }
    part def SourceFact {
        attribute sourceId : String;
        attribute path : String;
        attribute firstLine : String;
        attribute lastLine : String;
        attribute fact : String;
        attribute limit : String;
    }
    part stateDomains {
        part Canonical : StateDomain {
            attribute :>> domainId = "Canonical";
            attribute :>> identityScope = "collection + old-origin generation, not phase";
            attribute :>> stateFields = "canonical : ObjKey -> destination/copy-task; copyReady : ObjKey -> Bool";
            attribute :>> invariant = "One winning destination per admitted old object; strong-to-weak admission retains identity";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
        part Attempt : StateDomain {
            attribute :>> domainId = "Attempt";
            attribute :>> identityScope = "collection + AttemptId + owner";
            attribute :>> stateFields = "attempt : AttemptId -> Open/Settled; canonicalWinner : optional ObjKey";
            attribute :>> invariant = "Losing speculative attempt can settle without settling or reminting canonical work";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
        }
        part CopyTask : StateDomain {
            attribute :>> domainId = "CopyTask";
            attribute :>> identityScope = "collection + CopyTaskId";
            attribute :>> stateFields = "copy : CopyTaskId -> Copying/Initialized/Settled; owner and publication children";
            attribute :>> invariant = "Forwarding does not imply readiness; copy settles only with accepted required fragment custody";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
        }
        part Fragment : StateDomain {
            attribute :>> domainId = "Fragment";
            attribute :>> identityScope = "phase/round + FragmentId + descriptor revision";
            attribute :>> stateFields = "fragment : Preparing/Scanning/Settled; role Body/Tail/Root/Frame/Still; assignedEdges; visitComplete";
            attribute :>> invariant = "Body fragment settlement does not close tail fragment or whole object; no wait-for-child completion";
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
        }
        part Edge : StateDomain {
            attribute :>> domainId = "Edge";
            attribute :>> identityScope = "phase/round + FragmentId + slot + descriptor revision";
            attribute :>> stateFields = "edge : Unseen/Resolving/Covered; targetReceipt; referenceUpdate; unknownTransfer";
            attribute :>> invariant = "Two slots may reuse one canonical target; each has its own exactly-once coverage receipt";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part Region : StateDomain {
            attribute :>> domainId = "Region";
            attribute :>> identityScope = "phase + RegionId/generation + exact interval manifest";
            attribute :>> stateFields = "objects/padding/markers; fragment membership; queue/scanner custodian";
            attribute :>> invariant = "Physical layout partition and semantic edge partition are different axes; descriptor reads may overlap";
            attribute :>> obligationId = "WC-BATCH-PARTITION";
        }
        part Ledger : StateDomain {
            attribute :>> domainId = "Ledger";
            attribute :>> identityScope = "matching collection/phase identities + typed TaskId";
            attribute :>> stateFields = "issued; unfinished; settled; producer rights; unknown transfers";
            attribute :>> invariant = "Typed attempt/copy/fragment/transfer tasks have unique ownership; edges are obligations contained by live fragments";
            attribute :>> obligationId = "WC-HANDOFF-ACCOUNT";
        }
    }
    part actionContracts {
        part finishCopy : ActionContract {
            attribute :>> actionId = "finishCopy";
            attribute :>> guard = "Copy Initialized; matching Body acceptance is PrivateCursor, QueuedOrScanning or known Settled; required Tail live/settled; no unknown copy effect";
            attribute :>> updateRule = "Only copy task -> Settled; retain canonical identity, payload readiness and all child TaskIds";
            attribute :>> accounting = "Settle one copy task only; Body/Tail and source-parent debts unchanged; private acceptance may precede later batch publication";
            attribute :>> frameRule = "Private receipt requires live counted cursor/descriptor and eventual scan path; no child-completion wait or cross-worker visibility inferred";
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
        }

        part redirectReference : ActionContract {
            attribute :>> actionId = "redirectReference";
            attribute :>> guard = "Parent Scanning; edge Resolving; matching canonical target and exclusively owned live source slot; write disposition known";
            attribute :>> updateRule = "Redirect this slot to canonical destination and record referenceUpdate receipt; edge remains Resolving";
            attribute :>> accounting = "No task creation or settlement; canonical readiness and parent debt unchanged";
            attribute :>> frameRule = "Only the exact owned slot and its update receipt change; unknown effect remains unresolved";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }

        part reserveFragments : ActionContract {
            attribute :>> actionId = "reserveFragments";
            attribute :>> guard = "Live copy custodian; admitted subtype/length/roles and exact copy identity; before that copy can be included in published prefix";
            attribute :>> updateRule = "Enroll unique Preparing Body and eligible Tail roles; Tail source activation/cell owns obligation before byte traversal";
            attribute :>> accounting = "Mint each required fragment once while parent/copy remains live; excluded Tail has no phantom task";
            attribute :>> frameRule = "Earlier-prefix publication may occur before this target is claimed; reservation is not payload readiness or scanner start";
            attribute :>> obligationId = "WC-BATCH-PARTITION";
        }
        part startFragment : ActionContract {
            attribute :>> actionId = "startFragment";
            attribute :>> guard = "Preparing local/Tail fragment; relevant field/root inputs ready; descriptor/phase and counted owner match";
            attribute :>> updateRule = "Fragment -> Scanning; retain all Unseen/Resolving edge obligations";
            attribute :>> accounting = "No task creation or settlement";
            attribute :>> frameRule = "No claim of whole-object closure; queued Body uses acquireBatch instead";
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
        }

        part beginDiscover : ActionContract {
            attribute :>> actionId = "beginDiscover";
            attribute :>> guard = "Parent Scanning; edge Unseen in sealed assigned inventory; matching phase/descriptor; slot owned";
            attribute :>> updateRule = "Edge -> Resolving; bind sampled origin and resolver; parent stays Scanning";
            attribute :>> accounting = "No canonical issue and no fragment settlement; edge debt remains contained in parent";
            attribute :>> frameRule = "Do not change another edge, phase, queue or scanner";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part claimCanonical : ActionContract {
            attribute :>> actionId = "claimCanonical";
            attribute :>> guard = "Resolver admitted; target absent; native CAS wins; old-header interpretation and origin stable";
            attribute :>> updateRule = "Insert one canonical destination and live copy custodian; readiness false";
            attribute :>> accounting = "Mint one copy task; if attempt exists settle only that attempt with separate ledger deltas";
            attribute :>> frameRule = "Source edge can remain Resolving; no body-read admission from CAS alone";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
        part rejectAttempt : ActionContract {
            attribute :>> actionId = "rejectAttempt";
            attribute :>> guard = "Known losing CAS or known pre-effect rejection; matching AttemptId and live required-edge custodian";
            attribute :>> updateRule = "Settle only speculative attempt; alias winning ObjKey when known";
            attribute :>> accounting = "No canonical decrement and no assumed padding/storage refund";
            attribute :>> frameRule = "No change to winner readiness, queue entry, assigned edges or fragment completion";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
        }
        part discoverChild : ActionContract {
            attribute :>> actionId = "discoverChild";
            attribute :>> guard = "Parent Scanning; edge Resolving; canonical identity/custody or imported closure valid; reference update known; no unknown acceptance";
            attribute :>> updateRule = "Edge -> Covered with target receipt; parent remains Scanning";
            attribute :>> accounting = "No new canonical task and no parent settlement; child may remain Copying/Queued/Scanning";
            attribute :>> frameRule = "Does not require target completion and does not mutate another slot receipt";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part coverImmediate : ActionContract {
            attribute :>> actionId = "coverImmediate";
            attribute :>> guard = "Parent Scanning; edge Resolving; target classified terminal by admitted descriptor/runtime policy; slot handling known";
            attribute :>> updateRule = "Edge -> Covered with terminal-policy receipt";
            attribute :>> accounting = "No managed child task minted; policy proof covers any separately rooted nonmovable data";
            attribute :>> frameRule = "Do not treat every permanent/still/frame/weak object as an immediate";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part replayReceipt : ActionContract {
            attribute :>> actionId = "replayReceipt";
            attribute :>> guard = "Same EdgeId, descriptor and scope; edge already Covered; receipt registry still live";
            attribute :>> updateRule = "Read existing coverage receipt; no new discovery effect";
            attribute :>> accounting = "All task and completion counts unchanged";
            attribute :>> frameRule = "No late enqueue, second slot mutation or fabricated receipt";
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
        }
        part initializeCopy : ActionContract {
            attribute :>> actionId = "initializeCopy";
            attribute :>> guard = "Canonical winner with live custody; selected payload/padding bytes copied and required role inputs/descriptors known";
            attribute :>> updateRule = "Copy -> Initialized; local payload readiness true; keep reserved Body/Tail and private cursor custody";
            attribute :>> accounting = "No fragment remint, queue commit or task settlement";
            attribute :>> frameRule = "Local initialized bytes do not establish remote visibility; Tail may remain Preparing";
            attribute :>> obligationId = "WC-BATCH-PARTITION";
        }
        part publishBatch : ActionContract {
            attribute :>> actionId = "publishBatch";
            attribute :>> guard = "Exact completed prefix manifest; initialized boundaries/profile visibility; every included required Tail has counted/accepted custody";
            attribute :>> updateRule = "Transfer only manifest Body members to queue, or retain qualified local scanner on bypass; exclude unclaimed upcoming target";
            attribute :>> accounting = "No canonical issue or task settlement; Body membership conserved; Tail debts unchanged";
            attribute :>> frameRule = "Signal not acceptance; private suffix may publish later after its copy task already settled under valid private custody";
            attribute :>> obligationId = "WC-BATCH-PARTITION";
        }
        part acquireBatch : ActionContract {
            attribute :>> actionId = "acquireBatch";
            attribute :>> guard = "Matching queue entry and phase manifest; counted scanner owns removed region; readiness/visibility valid";
            attribute :>> updateRule = "Body fragments -> Scanning under scanner custody; local path admits matching cursor fragments";
            attribute :>> accounting = "Queue removal transfers debt without settling it";
            attribute :>> frameRule = "No duplicate claim of same FragmentId; Tail fragments keep their own owners";
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
        }
        part finishParent : ActionContract {
            attribute :>> actionId = "finishParent";
            attribute :>> guard = "Parent Scanning; sealed assigned edges all Covered; physical visit done; no unknown transfers; scope/custodian match";
            attribute :>> updateRule = "Only this fragment -> Settled";
            attribute :>> accounting = "Settle exactly one fragment; canonical children and other fragments retain their debts";
            attribute :>> frameRule = "No requirement that children finish; no implication that object or phase is closed";
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
        }
        part nextPhase : ActionContract {
            attribute :>> actionId = "nextPhase";
            attribute :>> guard = "Prior phase receipt valid; participants and next seed/skip policy admitted";
            attribute :>> updateRule = "Preserve collection canonical map; create only required next-phase seed/deferred fragment ledger";
            attribute :>> accounting = "No recopy merely because phase changed; no clearing old unresolved work";
            attribute :>> frameRule = "Imported closure requires descriptor/phase certificate; forwarding address alone is insufficient";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
        part finishPhase : ActionContract {
            attribute :>> actionId = "finishPhase";
            attribute :>> guard = "Root/descriptor/issuer census sealed; no live producer rights or unfinished task/transfer in this phase";
            attribute :>> updateRule = "Publish stable phase receipt; retain collection and target-specific outstanding scopes";
            attribute :>> accounting = "No hidden Unseen edge can survive in a settled fragment; no cancellation to force zero";
            attribute :>> frameRule = "Weak admission and resource-release completion remain separate cuts";
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
        }
    }
    part scenarioContracts {
        part EarlyPublish : ScenarioContract {
            attribute :>> caseId = "EarlyPublish";
            attribute :>> kind = "legacy-negative";
            attribute :>> currentInitializer = "initOld";
            attribute :>> history = "Publish before copy progress ready; later acquire observes stale payload";
            attribute :>> requiredOutcome = "Preserve publicationSafe violation under equivalent omitted-readiness guard";
            attribute :>> evidenceBoundary = "Existing fault 1 source is preserved; no fresh model execution";
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
        }
        part EarlyIdle : ScenarioContract {
            attribute :>> caseId = "EarlyIdle";
            attribute :>> kind = "legacy-negative";
            attribute :>> currentInitializer = "initEarlyIdle";
            attribute :>> history = "Last active worker idles with private or scanning/delegated work still owned";
            attribute :>> requiredOutcome = "Preserve terminationSafe violation when lifetime guard is intentionally omitted";
            attribute :>> evidenceBoundary = "Existing fault 2 source is preserved; extend projection to richer hidden domains";
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
        }
        part DuplicateAcquire : ScenarioContract {
            attribute :>> caseId = "DuplicateAcquire";
            attribute :>> kind = "legacy-negative";
            attribute :>> currentInitializer = "initDuplicateClaim";
            attribute :>> history = "Acquire leaves same fragment queued; second acquire scans it again";
            attribute :>> requiredOutcome = "Preserve duplicate acquisition violation per FragmentId, not total scans per physical object";
            attribute :>> evidenceBoundary = "Existing fault 3 source preserved; Body and Tail are legitimate distinct fragments";
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
        }
        part EarlyPhase : ScenarioContract {
            attribute :>> caseId = "EarlyPhase";
            attribute :>> kind = "legacy-negative";
            attribute :>> currentInitializer = "initEarlyPhase";
            attribute :>> history = "Participants arrive and next phase begins before prior debt drains";
            attribute :>> requiredOutcome = "Preserve badPhase/old-debt witness across phase admission";
            attribute :>> evidenceBoundary = "Existing fault 4 source preserved; no resetting canonical map to hide it";
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
        }
        part DuplicateCanonical : ScenarioContract {
            attribute :>> caseId = "DuplicateCanonical";
            attribute :>> kind = "design-negative";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Two resolving slots target same old ObjKey and each mints a canonical copy";
            attribute :>> requiredOutcome = "Unique canonical identity/count invariant must fail in omitted-dedup control";
            attribute :>> evidenceBoundary = "Hypothetical mutation, not an observed native duplicate-copy failure";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
        part MissingTail : ScenarioContract {
            attribute :>> caseId = "MissingTail";
            attribute :>> kind = "design-negative";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Body fragment settles and queue empties while Tail fragment remains Preparing/Scanning";
            attribute :>> requiredOutcome = "Object/phase closure must remain false; omitted tail census must retain a witness";
            attribute :>> evidenceBoundary = "Source split motivates the scenario; no executed counterexample";
            attribute :>> obligationId = "WC-BATCH-PARTITION";
        }
        part PrematureParent : ScenarioContract {
            attribute :>> caseId = "PrematureParent";
            attribute :>> kind = "design-negative";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "One target known but another assigned edge Unseen, or transfer result unknown";
            attribute :>> requiredOutcome = "finishParent disabled; weakening all-edge/unknown guard must expose lost custody";
            attribute :>> evidenceBoundary = "Parent target-exists alone is not coverage of the sealed inventory";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part LeafVisit : ScenarioContract {
            attribute :>> caseId = "LeafVisit";
            attribute :>> kind = "design-negative";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Assigned edge set empty but cursor/object physical visit not complete";
            attribute :>> requiredOutcome = "finishParent disabled despite vacuous all-edge coverage";
            attribute :>> evidenceBoundary = "Payload-free leaves still require admitted physical layout/cursor handling";
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
        }
        part PhaseRecopy : ScenarioContract {
            attribute :>> caseId = "PhaseRecopy";
            attribute :>> kind = "design-negative";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Reset canonical map at weak admission and reinterpret old origin as a fresh copy";
            attribute :>> requiredOutcome = "Identity-preserving phase projection must reject this reinterpretation";
            attribute :>> evidenceBoundary = "Current QNT resets abstract work; not a claim native code recopies here";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
        part LateEnqueue : ScenarioContract {
            attribute :>> caseId = "LateEnqueue";
            attribute :>> kind = "design-negative";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Replay or new edge creates work after same-phase completion";
            attribute :>> requiredOutcome = "No same-phase enqueue; retain valid old custodian or reject unsupported stale origin";
            attribute :>> evidenceBoundary = "Existing guarded CollectionContract rescan stays guarded; no withdrawn trace revival";
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
        }
        part SelfAndShared : ScenarioContract {
            attribute :>> caseId = "SelfAndShared";
            attribute :>> kind = "positive";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Self-edge and two source slots reuse one live canonical task; each slot covers independently";
            attribute :>> requiredOutcome = "Parents can settle with accepted unfinished children; no recursive completion wait";
            attribute :>> evidenceBoundary = "Required positive control, not a new accepted run";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part ChildBeforeParent : ScenarioContract {
            attribute :>> caseId = "ChildBeforeParent";
            attribute :>> kind = "positive";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Child claimed, initialized and queued while parent retains another unresolved edge";
            attribute :>> requiredOutcome = "Child may progress; parent still Scanning until its assigned inventory closes";
            attribute :>> evidenceBoundary = "Preserve native permitted ordering; do not repair by blocking discovery";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part StrongWeakReuse : ScenarioContract {
            attribute :>> caseId = "StrongWeakReuse";
            attribute :>> kind = "positive";
            attribute :>> currentInitializer = "none";
            attribute :>> history = "Weak seeds reuse strong canonical identities and introduce only phase-required new obligations";
            attribute :>> requiredOutcome = "Preserve canonical map and actual skip/deferred semantics without global rescan mandate";
            attribute :>> evidenceBoundary = "Finite two-phase model must gain an explicit phase/identity adapter";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
    }
    part preservationCases {
        part Identity : PreservationCase {
            attribute :>> caseId = "Identity";
            attribute :>> actionIds = "claimCanonical; rejectAttempt";
            attribute :>> guardPremises = "Admitted old-header writers, no ABA, stable collection key, one winner";
            attribute :>> establishedAfter = "One canonical copy; loser only settles attempt; origin identity preserved";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
        part Discovery : PreservationCase {
            attribute :>> caseId = "Discovery";
            attribute :>> actionIds = "beginDiscover; redirectReference; discoverChild; coverImmediate";
            attribute :>> guardPremises = "Sealed descriptor inventory, exclusive source slot, accepted canonical custody or valid closure";
            attribute :>> establishedAfter = "Edge state progresses without settling parent or child; every Covered edge has a valid receipt";
            attribute :>> obligationId = "WC-DISCOVERY-GUARD";
        }
        part Replay : PreservationCase {
            attribute :>> caseId = "Replay";
            attribute :>> actionIds = "replayReceipt";
            attribute :>> guardPremises = "Matching immutable EdgeId/descriptor/scope and live receipt registry";
            attribute :>> establishedAfter = "Idempotent read preserves every ledger and cannot reopen a phase";
            attribute :>> obligationId = "WC-NEGATIVE-CONTROLS";
        }
        part Layout : PreservationCase {
            attribute :>> caseId = "Layout";
            attribute :>> actionIds = "reserveFragments; initializeCopy; publishBatch";
            attribute :>> guardPremises = "Exact object/padding/marker layout; initialized prefix; phase/subtype edge inventory";
            attribute :>> establishedAfter = "Physical cover and Body/Tail edge cover both preserved; byte-view overlap is not duplicate edge ownership";
            attribute :>> obligationId = "WC-BATCH-PARTITION";
        }
        part Acceptance : PreservationCase {
            attribute :>> caseId = "Acceptance";
            attribute :>> actionIds = "publishBatch; acquireBatch; startFragment";
            attribute :>> guardPremises = "Qualified profile visibility, exact region membership, counted scanner, all tails retained";
            attribute :>> establishedAfter = "Work custody moves without losing scanner/tail obligations or reminting canonical tasks";
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
        }
        part Settlement : PreservationCase {
            attribute :>> caseId = "Settlement";
            attribute :>> actionIds = "finishParent; finishCopy";
            attribute :>> guardPremises = "All assigned edges Covered, physical visit done, zero unknown transfers, matching custodian";
            attribute :>> establishedAfter = "Exactly one fragment settles; other object/child/tail obligations remain";
            attribute :>> obligationId = "WC-FRAGMENT-CLOSURE";
        }
        part Balance : PreservationCase {
            attribute :>> caseId = "Balance";
            attribute :>> actionIds = "claimCanonical; reserveFragments; finishCopy; finishParent";
            attribute :>> guardPremises = "Typed task identities are disjoint, creation/settlement unique, nonnegative finite ledger";
            attribute :>> establishedAfter = "issued = settled + unfinished with explicit new/settled deltas; no arithmetic-as-native-atomicity claim";
            attribute :>> obligationId = "WC-HANDOFF-ACCOUNT";
        }
        part Phase : PreservationCase {
            attribute :>> caseId = "Phase";
            attribute :>> actionIds = "nextPhase; finishPhase";
            attribute :>> guardPremises = "Complete root/issuer census, prior phase receipt, phase-specific skip/import certificates";
            attribute :>> establishedAfter = "Canonical map stable across phases; old work cannot be erased or imported by forwarding alone";
            attribute :>> obligationId = "WC-CANONICAL-PHASE";
        }
    }
    part sourceFacts {
        part CasOrder : SourceFact {
            attribute :>> sourceId = "CasOrder";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3555";
            attribute :>> lastLine = "3598";
            attribute :>> fact = "Speculative alignment/header before CAS; losing branch decrements header cursor and redirects; winner redirects before payload copy";
            attribute :>> limit = "Do not infer total padding refund or copied readiness";
        }
        part TailSplit : SourceFact {
            attribute :>> sourceId = "TailSplit";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3599";
            attribute :>> lastLine = "3627";
            attribute :>> fact = "For words>0 and subtype<=BOXVALUES, first field is held for tail marking after optional chunk publication";
            attribute :>> limit = "Subtype/length/profile qualification is mandatory";
        }
        part BodySkip : SourceFact {
            attribute :>> sourceId = "BodySkip";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4168";
            attribute :>> lastLine = "4178";
            attribute :>> fact = "Matching movable/default scanning skips first field; still/default path scans whole body";
            attribute :>> limit = "No blanket first-field skip for still or special frame/weak layouts";
        }
        part PairFast : SourceFact {
            attribute :>> sourceId = "PairFast";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4190";
            attribute :>> lastLine = "4207";
            attribute :>> fact = "PAIR fast path marks ptr+2 for PAIR_SIZE-1, excluding copied first field";
            attribute :>> limit = "NO_FAST_PATH route needs matching default descriptor proof";
        }
        part Still : SourceFact {
            attribute :>> sourceId = "Still";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3630";
            attribute :>> lastLine = "3647";
            attribute :>> fact = "Still CAS establishes a local to-scan list custodian rather than movable copying";
            attribute :>> limit = "Different canonical/list adapter; not the movable tail partition";
        }
        part Batch : SourceFact {
            attribute :>> sourceId = "Batch";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3249";
            attribute :>> lastLine = "3306";
            attribute :>> fact = "End marker and queued chunk link/tail publication differ from currently-scanned chunk bypass";
            attribute :>> limit = "Exact region membership and actual visibility profile remain unproved";
        }
        part Weak : SourceFact {
            attribute :>> sourceId = "Weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4040";
            attribute :>> lastLine = "4088";
            attribute :>> fact = "Will/weak table slot selection depends on phase and flags, including intentionally weak fields";
            attribute :>> limit = "Skipped relation classification is not always deferred tracing work";
        }
        part Phase : SourceFact {
            attribute :>> sourceId = "Phase";
            attribute :>> path = "models/gambit/gc_work_closure.qnt";
            attribute :>> firstLine = "54";
            attribute :>> lastLine = "90";
            attribute :>> fact = "finishScan combines fresh child and parent settlement; nextPhase reconstructs initialState";
            attribute :>> limit = "Bounded abstract graph reset is not native copying behavior";
        }
    }
    part diagramEdges {
        part edge0 : DiagramEdge {
            attribute :>> diagramId = "child-discovery";
            attribute :>> groupId = "edge";
            attribute :>> groupLabel = "Reference edge\n(parent Scanning)";
            attribute :>> edgeId = "begin";
            attribute :>> fromState = "Unseen";
            attribute :>> toState = "Resolving";
            attribute :>> actionId = "beginDiscover";
            attribute :>> label = "beginDiscover";
        }
        part edge1 : DiagramEdge {
            attribute :>> diagramId = "child-discovery";
            attribute :>> groupId = "edge";
            attribute :>> groupLabel = "Reference edge\n(parent Scanning)";
            attribute :>> edgeId = "managed";
            attribute :>> fromState = "Resolving";
            attribute :>> toState = "Managed Covered";
            attribute :>> actionId = "discoverChild";
            attribute :>> label = "discoverChild";
        }
        part edge2 : DiagramEdge {
            attribute :>> diagramId = "child-discovery";
            attribute :>> groupId = "edge";
            attribute :>> groupLabel = "Reference edge\n(parent Scanning)";
            attribute :>> edgeId = "terminal";
            attribute :>> fromState = "Resolving";
            attribute :>> toState = "Terminal Covered";
            attribute :>> actionId = "coverImmediate";
            attribute :>> label = "coverImmediate";
        }
        part edge3 : DiagramEdge {
            attribute :>> diagramId = "child-discovery";
            attribute :>> groupId = "identity";
            attribute :>> groupLabel = "Canonical identity\n(collection)";
            attribute :>> edgeId = "canonical";
            attribute :>> fromState = "Absent";
            attribute :>> toState = "Copying / live custodian";
            attribute :>> actionId = "claimCanonical";
            attribute :>> label = "claimCanonical";
        }
        part edge4 : DiagramEdge {
            attribute :>> diagramId = "child-discovery";
            attribute :>> groupId = "parent";
            attribute :>> groupLabel = "Parent fragment\n(phase)";
            attribute :>> edgeId = "finish";
            attribute :>> fromState = "Scanning / debt retained";
            attribute :>> toState = "Only this fragment settled";
            attribute :>> actionId = "finishParent";
            attribute :>> label = "finishParent";
        }
        part edge5 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "body";
            attribute :>> fromState = "Exact object / padding / marker layout";
            attribute :>> toState = "Preparing Body fragments";
            attribute :>> actionId = "reserveFragments";
            attribute :>> label = "reserve Body";
        }
        part edge6 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "tail";
            attribute :>> fromState = "Exact object / padding / marker layout";
            attribute :>> toState = "Preparing Tail fragments";
            attribute :>> actionId = "reserveFragments";
            attribute :>> label = "reserve Tail";
        }
        part edge7 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "publish";
            attribute :>> fromState = "Preparing Body fragments";
            attribute :>> toState = "Queued Body fragments";
            attribute :>> actionId = "publishBatch";
            attribute :>> label = "after initialization / publishBatch";
        }
        part edge8 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "acquire";
            attribute :>> fromState = "Queued Body fragments";
            attribute :>> toState = "Scanning Body fragments";
            attribute :>> actionId = "acquireBatch";
            attribute :>> label = "acquireBatch";
        }
        part edge9 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "bodyscan";
            attribute :>> fromState = "Scanning Body fragments";
            attribute :>> toState = "Body fragment settled";
            attribute :>> actionId = "finishParent";
            attribute :>> label = "finishParent";
        }
        part edge10 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "tailstart";
            attribute :>> fromState = "Preparing Tail fragments";
            attribute :>> toState = "Scanning Tail fragments";
            attribute :>> actionId = "startFragment";
            attribute :>> label = "after initialization / startFragment";
        }
        part edge11 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "tailscan";
            attribute :>> fromState = "Scanning Tail fragments";
            attribute :>> toState = "Tail fragment settled";
            attribute :>> actionId = "finishParent";
            attribute :>> label = "finishParent";
        }
        part edge12 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "bodyclosure";
            attribute :>> fromState = "Body fragment settled";
            attribute :>> toState = "Object closure: all relevant custody";
            attribute :>> actionId = "none";
            attribute :>> label = "necessary, not sufficient";
        }
        part edge13 : DiagramEdge {
            attribute :>> diagramId = "child-batch-coverage";
            attribute :>> groupId = "";
            attribute :>> groupLabel = "";
            attribute :>> edgeId = "tailclosure";
            attribute :>> fromState = "Tail fragment settled";
            attribute :>> toState = "Object closure: all relevant custody";
            attribute :>> actionId = "none";
            attribute :>> label = "necessary, not sufficient";
        }
    }
}
