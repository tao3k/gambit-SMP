/* Source-grounded design of an unimplemented QNT refinement.
 * No satisfy/assert instance, executable transition or native ABI change. */
package GambitAtomicRefinement {
    private import ScalarValues::*;
    private import GambitCollectionCompletion::*;
    part def ForwardingWitness {
        part scope : PhaseScope;
        attribute forwardingIdentityKnown : Boolean;
        attribute canonicalObligationLiveOrSettled : Boolean;
        attribute bodyInitialized : Boolean;
        attribute scannerAdmissionCommitted : Boolean;
        attribute readinessClaimed : Boolean;
        attribute losingAttemptSettledWinner : Boolean;
    }
    requirement def ForwardingReadinessLaw {
        subject witness : ForwardingWitness;
        require constraint {
            (not witness.forwardingIdentityKnown or witness.canonicalObligationLiveOrSettled) and
            (not witness.readinessClaimed or (witness.bodyInitialized and witness.scannerAdmissionCommitted)) and
            not witness.losingAttemptSettledWinner
        }
    }
    part def ChunkPublicationWitness {
        attribute initializedPrefix : Boolean;
        attribute descriptorAndEndMarkerValid : Boolean;
        attribute coveragePartitionKnown : Boolean;
        attribute deferredTailEdgeOwned : Boolean;
        attribute profileVisibilityProved : Boolean;
        attribute publishedReadable : Boolean;
    }
    requirement def ChunkPublicationCutLaw {
        subject witness : ChunkPublicationWitness;
        require constraint {
            not witness.publishedReadable or
            (witness.initializedPrefix and witness.descriptorAndEndMarkerValid and
             witness.coveragePartitionKnown and witness.deferredTailEdgeOwned and witness.profileVisibilityProved)
        }
    }
    part def DequeueWitness {
        part scope : PhaseScope;
        attribute queueEntryRemoved : Boolean;
        attribute countedScannerAccepted : Boolean;
        attribute descriptorAndRangeLive : Boolean;
        attribute samePhaseAndGeneration : Boolean;
        attribute queueDebtSettledWithoutScanner : Boolean;
    }
    requirement def DequeueCustodyLaw {
        subject witness : DequeueWitness;
        require constraint {
            (not witness.queueEntryRemoved or
             (witness.countedScannerAccepted and witness.descriptorAndRangeLive and witness.samePhaseAndGeneration)) and
            not witness.queueDebtSettledWithoutScanner
        }
    }
    part def ParentScanWitness {
        attribute allRequiredEdgesCovered : Boolean;
        attribute acceptedOrSettledChildrenKnown : Boolean;
        attribute uncommittedHandoffsAbsent : Boolean;
        attribute parentScanSettled : Boolean;
    }
    requirement def ParentScanSettlementLaw {
        subject witness : ParentScanWitness;
        require constraint {
            not witness.parentScanSettled or
            (witness.allRequiredEdgesCovered and witness.acceptedOrSettledChildrenKnown and witness.uncommittedHandoffsAbsent)
        }
    }
    part def SimulationWitness {
        attribute initialStatesRelated : Boolean;
        attribute nativeStepsMatchedOrStutter : Boolean;
        attribute abstractGuardsPreserved : Boolean;
        attribute observationsPreserved : Boolean;
        attribute failureAndLateDomainCovered : Boolean;
        attribute safetyRefinementClaimed : Boolean;
        attribute noInfiniteInternalStutter : Boolean;
        attribute fairnessAndFiniteProductionKnown : Boolean;
        attribute progressRefinementClaimed : Boolean;
    }
    requirement def SimulationAdmissionLaw {
        subject witness : SimulationWitness;
        require constraint {
            (not witness.safetyRefinementClaimed or
             (witness.initialStatesRelated and witness.nativeStepsMatchedOrStutter and
              witness.abstractGuardsPreserved and witness.observationsPreserved and witness.failureAndLateDomainCovered)) and
            (not witness.progressRefinementClaimed or
             (witness.safetyRefinementClaimed and witness.noInfiniteInternalStutter and witness.fairnessAndFiniteProductionKnown))
        }
    }
    part def RefinementStep {
        attribute stepId : String;
        attribute path : String;
        attribute firstLine : String;
        attribute lastLine : String;
        attribute nativeOperation : String;
        attribute custody : String;
        attribute currentAction : String;
        attribute plannedAction : String;
        attribute projectionClass : String;
        attribute missingPremise : String;
        attribute obligationId : String;
    }
    part def ProofTarget {
        attribute targetId : String;
        attribute obligationId : String;
        attribute proposition : String;
        attribute premises : String;
        attribute existingSupport : String;
    }
    part def ProjectionEdge {
        attribute edgeId : String;
        attribute fromState : String;
        attribute toState : String;
        attribute abstractEffect : String;
        attribute evidenceClass : String;
    }
    part sourceSteps {
        part Reserve : RefinementStep {
            attribute :>> stepId = "Reserve";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3537";
            attribute :>> lastLine = "3572";
            attribute :>> nativeOperation = "Reserve destination capacity and speculative header";
            attribute :>> custody = "Source producer holds attempt plus required edge";
            attribute :>> currentAction = "claim";
            attribute :>> plannedAction = "reserveAttempt then canonical claim";
            attribute :>> projectionClass = "internal-or-segment";
            attribute :>> missingPremise = "A speculative attempt is not a second canonical ticket; padding and rollback remain private";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
        }
        part CasWin : RefinementStep {
            attribute :>> stepId = "CasWin";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3572";
            attribute :>> lastLine = "3598";
            attribute :>> nativeOperation = "Forwarding CAS wins before payload copy";
            attribute :>> custody = "Winner remains initialization and scan custodian";
            attribute :>> currentAction = "claim";
            attribute :>> plannedAction = "canonicalClaim; readiness remains false";
            attribute :>> projectionClass = "conditional-match";
            attribute :>> missingPremise = "Do not turn forwarding address into publish or acquire";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
        }
        part CasLose : RefinementStep {
            attribute :>> stepId = "CasLose";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3582";
            attribute :>> lastLine = "3595";
            attribute :>> nativeOperation = "CAS loser rolls back header and redirects root cell";
            attribute :>> custody = "Winner obligation remains live; only losing attempt disappears";
            attribute :>> currentAction = "none";
            attribute :>> plannedAction = "aliasCanonical plus settleAttempt";
            attribute :>> projectionClass = "internal-with-history";
            attribute :>> missingPremise = "Current QNT has no speculative-attempt state or duplicate-CAS action";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
        }
        part Copy : RefinementStep {
            attribute :>> stepId = "Copy";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3597";
            attribute :>> lastLine = "3626";
            attribute :>> nativeOperation = "Body copy then optional chunk boundary publication";
            attribute :>> custody = "Private copy or queued region plus live tail-edge producer";
            attribute :>> currentAction = "copyWord; publish";
            attribute :>> plannedAction = "copyProgress then publishBatch";
            attribute :>> projectionClass = "segmented-match";
            attribute :>> missingPremise = "Two abstract copy words represent progress classes, not concrete byte count";
            attribute :>> obligationId = "WC-REGION-COVER";
        }
        part TailEdge : RefinementStep {
            attribute :>> stepId = "TailEdge";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3599";
            attribute :>> lastLine = "3627";
            attribute :>> nativeOperation = "First field delegated to tail marking after possible chunk publish";
            attribute :>> custody = "Tail marker owns first edge while scan may own remaining fields";
            attribute :>> currentAction = "finishScan";
            attribute :>> plannedAction = "discoverChild while parent remains scanning; settleParent later";
            attribute :>> projectionClass = "current-shape-gap";
            attribute :>> missingPremise = "PAIR fast path and default skip first field; partition edge responsibility";
            attribute :>> obligationId = "WC-DISCOVERY-REFINE";
        }
        part ChunkWrite : RefinementStep {
            attribute :>> stepId = "ChunkWrite";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3254";
            attribute :>> lastLine = "3281";
            attribute :>> nativeOperation = "End marker and next FIFO link written under chunk lock";
            attribute :>> custody = "Publisher retains pending batch; provisional link not readiness proof";
            attribute :>> currentAction = "publish";
            attribute :>> plannedAction = "prepareBatch; publication stays pending";
            attribute :>> projectionClass = "internal-before-commit";
            attribute :>> missingPremise = "Outside-lock empty precheck is not a completed empty proof";
            attribute :>> obligationId = "WC-MEMORY-ORDER";
        }
        part ChunkCommit : RefinementStep {
            attribute :>> stepId = "ChunkCommit";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3283";
            attribute :>> lastLine = "3306";
            attribute :>> nativeOperation = "Ordered barriers, FIFO tail, unlock and notification";
            attribute :>> custody = "Batch custody commits to queue; signal does not create another task";
            attribute :>> currentAction = "publish";
            attribute :>> plannedAction = "publishBatch at a justified in-lock commit cut";
            attribute :>> projectionClass = "conditional-match";
            attribute :>> missingPremise = "Choose cut only after actual profile visibility and locked consumer proof";
            attribute :>> obligationId = "WC-MEMORY-ORDER";
        }
        part LocalChunk : RefinementStep {
            attribute :>> stepId = "LocalChunk";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3264";
            attribute :>> lastLine = "3266";
            attribute :>> nativeOperation = "Currently scanned chunk bypasses FIFO insertion";
            attribute :>> custody = "Local cursor and counted producer keep unfinished region live";
            attribute :>> currentAction = "scanLocal";
            attribute :>> plannedAction = "scanLocal with growing region coverage";
            attribute :>> projectionClass = "region-gap";
            attribute :>> missingPremise = "Already-scanned prefix, private suffix and tail dependencies require disjoint cover";
            attribute :>> obligationId = "WC-REGION-COVER";
        }
        part OwnDequeue : RefinementStep {
            attribute :>> stepId = "OwnDequeue";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4340";
            attribute :>> lastLine = "4375";
            attribute :>> nativeOperation = "Local FIFO head moves, lock released, chunk scanned";
            attribute :>> custody = "Queued obligation becomes counted scanning obligation at head removal";
            attribute :>> currentAction = "acquire";
            attribute :>> plannedAction = "acquireBatch then per-region scan";
            attribute :>> projectionClass = "conditional-match";
            attribute :>> missingPremise = "One FIFO chunk may represent many canonical object and edge obligations";
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
        }
        part StealDequeue : RefinementStep {
            attribute :>> stepId = "StealDequeue";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6704";
            attribute :>> lastLine = "6727";
            attribute :>> nativeOperation = "Remote FIFO head moves under remote lock then scan outside lock";
            attribute :>> custody = "Stealer is counted; source queue no longer owns the removed range";
            attribute :>> currentAction = "acquire";
            attribute :>> plannedAction = "acquireBatch with same-scope scanner acceptance";
            attribute :>> projectionClass = "conditional-match";
            attribute :>> missingPremise = "No gap between removal and logical scanner custody; interrupted handoff stays unresolved";
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
        }
        part Discover : RefinementStep {
            attribute :>> stepId = "Discover";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3999";
            attribute :>> lastLine = "4207";
            attribute :>> nativeOperation = "scan dispatch may mark/copy/publish children before parent scan returns";
            attribute :>> custody = "Parent scanning debt and accepted child debt coexist";
            attribute :>> currentAction = "finishScan";
            attribute :>> plannedAction = "discoverChild before finishParent; canonical aliases reuse ticket";
            attribute :>> projectionClass = "current-shape-gap";
            attribute :>> missingPremise = "Current finishScan both settles parent and first creates child root";
            attribute :>> obligationId = "WC-DISCOVERY-REFINE";
        }
        part ScanDone : RefinementStep {
            attribute :>> stepId = "ScanDone";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4268";
            attribute :>> lastLine = "4271";
            attribute :>> nativeOperation = "scan_and_advance completes this pending object/region";
            attribute :>> custody = "Parent settles only after required edges have custody";
            attribute :>> currentAction = "finishScan";
            attribute :>> plannedAction = "finishParent with all-edge coverage guard";
            attribute :>> projectionClass = "planned-guard";
            attribute :>> missingPremise = "Do not require accepted children already scanned; do require no unknown handoff";
            attribute :>> obligationId = "WC-DISCOVERY-REFINE";
        }
        part Idle : RefinementStep {
            attribute :>> stepId = "Idle";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6736";
            attribute :>> lastLine = "6772";
            attribute :>> nativeOperation = "Worker decrements phase count after local and stealing loop";
            attribute :>> custody = "No producer rights or private/scanning/transit debt may escape count";
            attribute :>> currentAction = "idle";
            attribute :>> plannedAction = "idle after complete participant ledger cut";
            attribute :>> projectionClass = "conditional-match";
            attribute :>> missingPremise = "Native guard is procedural; QNT guard checks global queued and owner work";
            attribute :>> obligationId = "WC-PRODUCER-CLOSE";
        }
        part Wake : RefinementStep {
            attribute :>> stepId = "Wake";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6756";
            attribute :>> lastLine = "6769";
            attribute :>> nativeOperation = "Wait returns; count increments if phase count still positive";
            attribute :>> custody = "Awake seeker is counted even when notification was spurious";
            attribute :>> currentAction = "wake";
            attribute :>> plannedAction = "wakeSeeker for count-positive phase";
            attribute :>> projectionClass = "current-guard-gap";
            attribute :>> missingPremise = "Current QNT wake additionally requires queued work; direct counted projection fails otherwise";
            attribute :>> obligationId = "WC-WAKE-REFINE";
        }
        part FailureLate : RefinementStep {
            attribute :>> stepId = "FailureLate";
            attribute :>> path = "vendor/gambit/lib/c_intf.c";
            attribute :>> firstLine = "1683";
            attribute :>> lastLine = "1713";
            attribute :>> nativeOperation = "Native release can fail after foreign fields were cleared";
            attribute :>> custody = "Independent failure custodian retains payload and accepted descendants";
            attribute :>> currentAction = "none";
            attribute :>> plannedAction = "separate failure ledger and closed-phase admission";
            attribute :>> projectionClass = "outside-selected-domain";
            attribute :>> missingPremise = "Current copy/publish/dequeue are void paths, not transport APIs with rollback status";
            attribute :>> obligationId = "WC-FAILURE-LATE";
        }
    }
    part proofTargets {
        part Partition : ProofTarget {
            attribute :>> targetId = "Partition";
            attribute :>> obligationId = "WC-REGION-COVER";
            attribute :>> proposition = "Every live object, range and deferred edge maps to unfinished canonical coverage";
            attribute :>> premises = "Stable region identities; exact scan layouts; disjoint cover; phase/generation equality";
            attribute :>> existingSupport = "WorkAccounting has no object-to-region map";
        }
        part Canonical : ProofTarget {
            attribute :>> targetId = "Canonical";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
            attribute :>> proposition = "CAS winner owns initialization/scan debt; losing attempts do not settle canonical work";
            attribute :>> premises = "No ABA; winner live or known settled; immutable identity across redirect";
            attribute :>> existingSupport = "CollectionContract claim/redirect separates identity from initialization";
        }
        part Discover : ProofTarget {
            attribute :>> targetId = "Discover";
            attribute :>> obligationId = "WC-DISCOVERY-REFINE";
            attribute :>> proposition = "Child acceptance can precede parent scan completion without dropping either debt";
            attribute :>> premises = "Explicit edge coverage; canonical deduplication; same phase; no unresolved handoff";
            attribute :>> existingSupport = "gc_work_closure finishScan currently combines discovery and settlement";
        }
        part Publication : ProofTarget {
            attribute :>> targetId = "Publication";
            attribute :>> obligationId = "WC-MEMORY-ORDER";
            attribute :>> proposition = "Acquired chunk exposes initialized scan inputs while tail-edge debt stays owned";
            attribute :>> premises = "Actual macro profile; lock/barrier semantics; byte/layout and nonoverlap proof";
            attribute :>> existingSupport = "gc_work_closure publicationSafe assumes atomic visibility";
        }
        part Acquire : ProofTarget {
            attribute :>> targetId = "Acquire";
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
            attribute :>> proposition = "Head removal preserves total debt by transferring to counted scanner";
            attribute :>> premises = "Matching phase/range; exclusive dequeue; interruption policy";
            attribute :>> existingSupport = "acquire models queue-to-scanning as one step";
        }
        part Failure : ProofTarget {
            attribute :>> targetId = "Failure";
            attribute :>> obligationId = "WC-FAILURE-LATE";
            attribute :>> proposition = "Rejected attempt, canonical winner and unknown effect retain distinct obligations";
            attribute :>> premises = "Pre-effect knowledge; durable acceptance; reconciliation; stable payload/handle";
            attribute :>> existingSupport = "Existing WorkAccounting lifetime theorem has no effect status";
        }
        part Late : ProofTarget {
            attribute :>> targetId = "Late";
            attribute :>> obligationId = "WC-FAILURE-LATE";
            attribute :>> proposition = "Closed same-phase work cannot be relabeled to hide old raw aliases";
            attribute :>> premises = "Admission cut; valid lease; old backing retained; new phase separately admitted";
            attribute :>> existingSupport = "Existing CollectionContract not(done) guard is already present";
        }
        part Wake : ProofTarget {
            attribute :>> targetId = "Wake";
            attribute :>> obligationId = "WC-WAKE-REFINE";
            attribute :>> proposition = "Native count changes match active seekers even with empty queue";
            attribute :>> premises = "Positive phase count; predicate-loop progress; weak fairness";
            attribute :>> existingSupport = "Current QNT wake requires queued work and has no seeker split";
        }
        part SafetySimulation : ProofTarget {
            attribute :>> targetId = "SafetySimulation";
            attribute :>> obligationId = "CROSS-SIMULATION";
            attribute :>> proposition = "Each admitted source step preserves relation through a model step or stutter";
            attribute :>> premises = "Initial relation; endpoint observations; coverage; actual enabled guards";
            attribute :>> existingSupport = "No existing mechanized native-to-QNT simulation";
        }
        part ProgressSimulation : ProofTarget {
            attribute :>> targetId = "ProgressSimulation";
            attribute :>> obligationId = "CROSS-SIMULATION";
            attribute :>> proposition = "Internal stuttering cannot conceal divergence or stranded required work";
            attribute :>> premises = "Well-founded internal rank; finite production; scheduling/delivery fairness";
            attribute :>> existingSupport = "WorkAccounting proves conditional safety, not progress";
        }
    }
    part projectionEdges {
        part phaseclose : ProjectionEdge {
            attribute :>> edgeId = "phaseclose";
            attribute :>> fromState = "ParentSettled";
            attribute :>> toState = "PhaseClosed";
            attribute :>> abstractEffect = "Only when all producers and unfinished ledgers drain";
            attribute :>> evidenceClass = "global cut, not parent completion alone";
        }
        part identity : ProjectionEdge {
            attribute :>> edgeId = "identity";
            attribute :>> fromState = "Undiscovered";
            attribute :>> toState = "ClaimedUnready";
            attribute :>> abstractEffect = "CAS chooses canonical identity";
            attribute :>> evidenceClass = "source-order; copy custody owed";
        }
        part initialize : ProjectionEdge {
            attribute :>> edgeId = "initialize";
            attribute :>> fromState = "ClaimedUnready";
            attribute :>> toState = "Initialized";
            attribute :>> abstractEffect = "copy progress, readiness still unpublished";
            attribute :>> evidenceClass = "source-order; profile visibility owed";
        }
        part publish : ProjectionEdge {
            attribute :>> edgeId = "publish";
            attribute :>> fromState = "Initialized";
            attribute :>> toState = "QueuedRegion";
            attribute :>> abstractEffect = "publishBatch";
            attribute :>> evidenceClass = "conditional simulation cut";
        }
        part local : ProjectionEdge {
            attribute :>> edgeId = "local";
            attribute :>> fromState = "Initialized";
            attribute :>> toState = "ScanningParent";
            attribute :>> abstractEffect = "scanLocal";
            attribute :>> evidenceClass = "local cursor coverage owed";
        }
        part acquire : ProjectionEdge {
            attribute :>> edgeId = "acquire";
            attribute :>> fromState = "QueuedRegion";
            attribute :>> toState = "ScanningParent";
            attribute :>> abstractEffect = "acquireBatch";
            attribute :>> evidenceClass = "queue-to-scanner custody owed";
        }
        part discover : ProjectionEdge {
            attribute :>> edgeId = "discover";
            attribute :>> fromState = "ScanningParent";
            attribute :>> toState = "ChildAccepted";
            attribute :>> abstractEffect = "discoverChild; parent remains scanning";
            attribute :>> evidenceClass = "required QNT design change";
        }
        part settle : ProjectionEdge {
            attribute :>> edgeId = "settle";
            attribute :>> fromState = "ChildAccepted";
            attribute :>> toState = "ParentSettled";
            attribute :>> abstractEffect = "finishParent; accepted child may remain unfinished";
            attribute :>> evidenceClass = "required all-edge coverage guard";
        }
        part continueChild : ProjectionEdge {
            attribute :>> edgeId = "continueChild";
            attribute :>> fromState = "ChildAccepted";
            attribute :>> toState = "ClaimedUnready";
            attribute :>> abstractEffect = "fresh child claim; existing aliases retain their own state";
            attribute :>> evidenceClass = "not a new collection or phase";
        }
        part unknown : ProjectionEdge {
            attribute :>> edgeId = "unknown";
            attribute :>> fromState = "ScanningParent";
            attribute :>> toState = "RetainedFailure";
            attribute :>> abstractEffect = "unknown effect keeps unfinished debt";
            attribute :>> evidenceClass = "outside current QNT domain";
        }
        part late : ProjectionEdge {
            attribute :>> edgeId = "late";
            attribute :>> fromState = "PhaseClosed";
            attribute :>> toState = "LateRetained";
            attribute :>> abstractEffect = "closed-phase admission rejection; stable custody required";
            attribute :>> evidenceClass = "same-phase reopening forbidden";
        }
    }
}
