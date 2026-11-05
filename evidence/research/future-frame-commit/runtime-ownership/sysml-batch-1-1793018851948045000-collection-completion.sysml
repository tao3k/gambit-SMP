/* Necessary architecture predicates and source/refinement metadata only.
 * No runtime layout, implemented producer gate, QNT transition or proof instance.
 * Source facts, correction status and lifecycle edges are the authored view source. */
package GambitCollectionCompletion {
    private import ScalarValues::*;
    private import GambitRuntimeInterfaces::*;

    enum def ScanPhase { Strong; Weak; }
    part def PhaseScope {
        part collection : CollectionScope;
        part workerTeam : ResourceScope;
        attribute phase : ScanPhase;
        attribute round : Integer;
        attribute producerGeneration : Integer;
    }
    part def ProducerClosure {
        part scope : PhaseScope;
        attribute externalEnrollmentClosed : Boolean;
        attribute producerCensusComplete : Boolean;
        attribute activeProducerRights : Integer;
        attribute privateCredits : Integer;
        attribute queuedCredits : Integer;
        attribute scanningCredits : Integer;
        attribute transferCredits : Integer;
        attribute reservedChildCredits : Integer;
        attribute closureSerializedWithAdmission : Boolean;
        attribute phaseDrainPublished : Boolean;
    }
    requirement def PhaseDrainAdmissionLaw {
        subject cut : ProducerClosure;
        require constraint {
            not cut.phaseDrainPublished or
            (cut.externalEnrollmentClosed and cut.producerCensusComplete and
             cut.closureSerializedWithAdmission and cut.activeProducerRights == 0 and
             cut.privateCredits == 0 and cut.queuedCredits == 0 and
             cut.scanningCredits == 0 and cut.transferCredits == 0 and
             cut.reservedChildCredits == 0)
        }
    }
    requirement def CreditDomainLaw {
        subject cut : ProducerClosure;
        require constraint {
            cut.activeProducerRights >= 0 and cut.privateCredits >= 0 and
            cut.queuedCredits >= 0 and cut.scanningCredits >= 0 and
            cut.transferCredits >= 0 and cut.reservedChildCredits >= 0
        }
    }
    part def PhaseDrainTransition {
        part preCut : ProducerClosure;
        part postCut : ProducerClosure;
    }
    requirement def PhaseDrainStabilityLaw {
        subject step : PhaseDrainTransition;
        require constraint {
            not step.preCut.phaseDrainPublished or
            step.preCut.scope.collection.vmId != step.postCut.scope.collection.vmId or
            step.preCut.scope.collection.vmGeneration != step.postCut.scope.collection.vmGeneration or
            step.preCut.scope.collection.collectionEpoch != step.postCut.scope.collection.collectionEpoch or
            step.preCut.scope.phase != step.postCut.scope.phase or
            step.preCut.scope.round != step.postCut.scope.round or
            (step.preCut.scope.producerGeneration == step.postCut.scope.producerGeneration and
             step.preCut.scope.workerTeam.resourceId == step.postCut.scope.workerTeam.resourceId and
             step.preCut.scope.workerTeam.resourceGeneration == step.postCut.scope.workerTeam.resourceGeneration and
             step.preCut.scope.collection.rootCutEpoch == step.postCut.scope.collection.rootCutEpoch and
             step.postCut.phaseDrainPublished and step.postCut.externalEnrollmentClosed and
             step.postCut.producerCensusComplete and step.postCut.activeProducerRights == 0 and
             step.postCut.privateCredits == 0 and step.postCut.queuedCredits == 0 and
             step.postCut.scanningCredits == 0 and step.postCut.transferCredits == 0 and
             step.postCut.reservedChildCredits == 0)
        }
    }
    /* Credits are logical work obligations. A concrete worker/chunk counter
     * needs a refinement, not one new atomic counter per object by assumption. */
    part def DerivedWorkTransfer {
        attribute childRequired : Boolean;
        attribute parentReleased : Boolean;
        attribute childReservedBeforeParentRelease : Boolean;
        attribute childCustodyCommitted : Boolean;
        attribute transferFailed : Boolean;
        attribute sourceCustodianLive : Boolean;
    }
    requirement def ParentChildCustodyLaw {
        subject transfer : DerivedWorkTransfer;
        require constraint {
            (not transfer.childRequired or not transfer.parentReleased or
             (transfer.childReservedBeforeParentRelease and transfer.childCustodyCommitted)) and
            (not transfer.transferFailed or transfer.sourceCustodianLive or transfer.childCustodyCommitted)
        }
    }
    part def CollectionCompletion {
        part scope : CollectionScope;
        attribute phaseReceiptsMatch : Boolean;
        attribute strongDrainKnown : Boolean;
        attribute weakDrainKnown : Boolean;
        attribute continuationMoveAccounted : Boolean;
        attribute cleanupCustodyAccounted : Boolean;
        attribute requiredParticipantsAcknowledged : Boolean;
        attribute terminalResultKnown : Boolean;
        attribute capacityRequestSucceeded : Boolean;
        attribute completionPublished : Boolean;
    }
    requirement def CollectionCompletionLaw {
        subject cycle : CollectionCompletion;
        require constraint {
            not cycle.completionPublished or
            (cycle.phaseReceiptsMatch and cycle.strongDrainKnown and cycle.weakDrainKnown and
             cycle.continuationMoveAccounted and cycle.cleanupCustodyAccounted and
             cycle.requiredParticipantsAcknowledged and cycle.terminalResultKnown)
        }
    }
    /* Target-required cuts differ. A still wrapper can be freed during cleanup;
     * full collection delivery is not imposed on that earlier source path. */
    enum def ReclaimCut {
        WeakAndNativeReleaseReturn; PostCleanupResize;
        CollectionDeliveryAndLastUse; NativeDeliveryAndLastUse;
    }
    part def ReclaimPermission {
        attribute requiredCut : ReclaimCut;
        part target : ResourceScope;
        attribute requiredCutIdentified : Boolean;
        attribute requiredCutSatisfied : Boolean;
        attribute targetUserCensusComplete : Boolean;
        attribute targetAdmissionClosed : Boolean;
        attribute noRemainingTargetUsers : Boolean;
        attribute noLateTargetIssuers : Boolean;
        attribute deferredCustodyValid : Boolean;
        attribute fullCycleReceiptRequired : Boolean;
        attribute matchingFullCycleReceiptKnown : Boolean;
        attribute permitIssued : Boolean;
    }
    requirement def ReclaimPermissionLaw {
        subject permit : ReclaimPermission;
        require constraint {
            not permit.permitIssued or
            (permit.requiredCutIdentified and permit.requiredCutSatisfied and
             permit.targetUserCensusComplete and permit.targetAdmissionClosed and permit.noRemainingTargetUsers and
             permit.noLateTargetIssuers and permit.deferredCustodyValid and
             (not permit.fullCycleReceiptRequired or permit.matchingFullCycleReceiptKnown))
        }
    }
    part def PermitConsumption {
        part permitTarget : ResourceScope;
        part actualTarget : ResourceScope;
        attribute admissionGenerationMatches : Boolean;
        attribute permitId : Integer;
        attribute permitGeneration : Integer;
        attribute issuedPermitKnown : Boolean;
        attribute unusedPermit : Boolean;
        attribute postConsumed : Boolean;
        attribute backingReleased : Boolean;
    }
    requirement def PermitConsumptionLaw {
        subject consumption : PermitConsumption;
        require constraint {
            not consumption.backingReleased or
            (consumption.permitTarget.resourceId == consumption.actualTarget.resourceId and
             consumption.permitTarget.resourceGeneration == consumption.actualTarget.resourceGeneration and
             consumption.admissionGenerationMatches and consumption.issuedPermitKnown and
             consumption.unusedPermit and consumption.postConsumed)
        }
    }
    part def LateWorkCustody {
        attribute attemptedAfterClosedPhase : Boolean;
        attribute samePhaseAccepted : Boolean;
        attribute retainedForRetry : Boolean;
        attribute validPriorLease : Boolean;
        attribute sourceCustodianLive : Boolean;
        attribute relabeledIntoNewPhase : Boolean;
        attribute newPhaseAdmitted : Boolean;
        attribute stableRootOrHandleValid : Boolean;
        attribute carriesUnresolvedOldAlias : Boolean;
        attribute oldBackingAlreadyReleased : Boolean;
        attribute dereferencesOldBacking : Boolean;
    }
    requirement def LateWorkCustodyLaw {
        subject late : LateWorkCustody;
        require constraint {
            (not late.attemptedAfterClosedPhase or not late.samePhaseAccepted) and
            (not late.retainedForRetry or (late.validPriorLease and late.sourceCustodianLive and not late.oldBackingAlreadyReleased)) and
            (not late.relabeledIntoNewPhase or (late.newPhaseAdmitted and late.stableRootOrHandleValid and not late.carriesUnresolvedOldAlias)) and
            (not late.oldBackingAlreadyReleased or not late.dereferencesOldBacking)
        }
    }
    part def PhaseTransition {
        attribute fromState : String;
        attribute toState : String;
        attribute guard : String;
        attribute evidenceBoundary : String;
    }
    part def SourceAnchor {
        attribute sourceId : String;
        attribute path : String;
        attribute firstLine : String;
        attribute lastLine : String;
        attribute fact : String;
        attribute limit : String;
    }
    part def SupportingModel {
        attribute contractId : String;
        attribute kind : String;
        attribute path : String;
        attribute symbols : String;
        attribute scope : String;
    }
    part lifecycle {
        part transition0 : PhaseTransition {
            attribute :>> fromState = "RootsEnrolled";
            attribute :>> toState = "StrongOpen";
            attribute :>> guard = "Count root scanners before drain probe";
            attribute :>> evidenceBoundary = "source-order plus producer coverage owed";
        }
        part transition1 : PhaseTransition {
            attribute :>> fromState = "StrongOpen";
            attribute :>> toState = "StrongDrained";
            attribute :>> guard = "Seal external ingress; all producer/credit obligations empty";
            attribute :>> evidenceBoundary = "PhaseDrainAdmissionLaw remains unproved";
        }
        part transition2 : PhaseTransition {
            attribute :>> fromState = "StrongDrained";
            attribute :>> toState = "WeakOpen";
            attribute :>> guard = "Phase barrier; admit process_wills as weak seed";
            attribute :>> evidenceBoundary = "legitimate same-collection next-phase work";
        }
        part transition3 : PhaseTransition {
            attribute :>> fromState = "WeakOpen";
            attribute :>> toState = "WeakDrained";
            attribute :>> guard = "Drain weak work under its own producer scope";
            attribute :>> evidenceBoundary = "separate weak counter, not a reused strong done bit";
        }
        part transition4 : PhaseTransition {
            attribute :>> fromState = "WeakDrained";
            attribute :>> toState = "CleanupCustody";
            attribute :>> guard = "Account continuation movement; enter cleanup";
            attribute :>> evidenceBoundary = "source order, not complete native last-use proof";
        }
        part transition5 : PhaseTransition {
            attribute :>> fromState = "CleanupCustody";
            attribute :>> toState = "CollectionComplete";
            attribute :>> guard = "Participant/result and cleanup custody accounted";
            attribute :>> evidenceBoundary = "deferred resource lifetime remains target-specific";
        }
        part transition6 : PhaseTransition {
            attribute :>> fromState = "CleanupCustody";
            attribute :>> toState = "TargetPermit";
            attribute :>> guard = "Target policy permits still-header release after native callback return";
            attribute :>> evidenceBoundary = "earlier than full cycle return; not native-resource success";
        }
        part transition7 : PhaseTransition {
            attribute :>> fromState = "CollectionComplete";
            attribute :>> toState = "TargetPermit";
            attribute :>> guard = "Target-specific users and late issuers closed";
            attribute :>> evidenceBoundary = "completion alone is insufficient";
        }
        part transition8 : PhaseTransition {
            attribute :>> fromState = "TargetPermit";
            attribute :>> toState = "Reclaimed";
            attribute :>> guard = "Match resource and admission generations; consume once";
            attribute :>> evidenceBoundary = "no stale permit or new borrower";
        }
        part transition9 : PhaseTransition {
            attribute :>> fromState = "StrongOpen";
            attribute :>> toState = "RetainedFailure";
            attribute :>> guard = "Transfer fails while source still owns work";
            attribute :>> evidenceBoundary = "registered custody required";
        }
        part transition10 : PhaseTransition {
            attribute :>> fromState = "CollectionComplete";
            attribute :>> toState = "ProtocolViolation";
            attribute :>> guard = "Attempt to enqueue into a completed phase";
            attribute :>> evidenceBoundary = "reject; no retrospective lifetime repair";
        }
        part transition11 : PhaseTransition {
            attribute :>> fromState = "Reclaimed";
            attribute :>> toState = "ProtocolViolation";
            attribute :>> guard = "Stale raw-pointer request";
            attribute :>> evidenceBoundary = "no dereference; not recoverable by renaming epoch";
        }
    }
    part sourceAnchors {
        part source0 : SourceAnchor {
            attribute :>> sourceId = "QUEUE-PUBLISH";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3249";
            attribute :>> lastLine = "3306";
            attribute :>> fact = "end_heap_chunk publishes a completed chunk with ordered barriers and signals waiters";
            attribute :>> limit = "Queue publication and active-producer closure use different synchronization; memory refinement owed";
        }
        part source1 : SourceAnchor {
            attribute :>> sourceId = "COPY-PRODUCER";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3549";
            attribute :>> lastLine = "3663";
            attribute :>> fact = "mark_array can copy locally, publish a chunk and enqueue a still object";
            attribute :>> limit = "Forwarding identity precedes full payload copy; not equivalent to queued scan visibility";
        }
        part source2 : SourceAnchor {
            attribute :>> sourceId = "CONT-PRODUCER";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3668";
            attribute :>> lastLine = "3812";
            attribute :>> fact = "mark_captured_continuation allocates frame copies and may end a heap chunk";
            attribute :>> limit = "Every suspended/raw origin and caller remains a census obligation";
        }
        part source3 : SourceAnchor {
            attribute :>> sourceId = "LOCAL-DRAIN";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4210";
            attribute :>> lastLine = "4390";
            attribute :>> fact = "Local fixed point drains still objects, queued and incomplete movable chunks";
            attribute :>> limit = "An empty public FIFO does not expose all local unfinished work";
        }
        part source4 : SourceAnchor {
            attribute :>> sourceId = "PHASE-COUNTS";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3456";
            attribute :>> lastLine = "3459";
            attribute :>> fact = "Two scan worker counters start at processor_count";
            attribute :>> limit = "Source integer counts are not overflow or complete participant proofs";
        }
        part source5 : SourceAnchor {
            attribute :>> sourceId = "TERMINATION";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6667";
            attribute :>> lastLine = "6772";
            attribute :>> fact = "Idle decrements the phase counter under the termination mutex; waking increments if not zero";
            attribute :>> limit = "Producer lifetime, queue visibility, waits and fairness need refinement";
        }
        part source6 : SourceAnchor {
            attribute :>> sourceId = "WEAK-SEED";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6894";
            attribute :>> lastLine = "6902";
            attribute :>> fact = "process_wills runs before a second mark fixed point; move_continuation follows it";
            attribute :>> limit = "Strong drain cannot be modeled as immutable whole-collection completion";
        }
        part source7 : SourceAnchor {
            attribute :>> sourceId = "WILL-MARK";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "5032";
            attribute :>> lastLine = "5108";
            attribute :>> fact = "process_wills invokes mark_array on wills and selected testators";
            attribute :>> limit = "Legitimate derived weak work, not a late violation of the strong phase";
        }
        part source8 : SourceAnchor {
            attribute :>> sourceId = "INLINE-FREE";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4379";
            attribute :>> lastLine = "4407";
            attribute :>> fact = "Unmarked still cleanup calls release_foreign then frees aligned wrapper storage";
            attribute :>> limit = "Return error is not used to prove resource success or deferred task custody";
        }
        part source9 : SourceAnchor {
            attribute :>> sourceId = "FOREIGN-RELEASE";
            attribute :>> path = "vendor/gambit/lib/c_intf.c";
            attribute :>> firstLine = "1683";
            attribute :>> lastLine = "1713";
            attribute :>> fact = "release_foreign clears pointer and release function before calling the native release function";
            attribute :>> limit = "Native release success, deferred completion and root ownership need caller-specific evidence";
        }
        part source10 : SourceAnchor {
            attribute :>> sourceId = "COLLECTIVE";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6989";
            attribute :>> lastLine = "7034";
            attribute :>> fact = "Setup/strong/weak/cleanup/resize are barrier separated; resize runs at processor zero";
            attribute :>> limit = "Barrier build profile, merged outcomes and failure custody remain separate";
        }
        part source11 : SourceAnchor {
            attribute :>> sourceId = "BARRIER-CHOICE";
            attribute :>> path = "vendor/gambit/lib/setup.h";
            attribute :>> firstLine = "63";
            attribute :>> lastLine = "67";
            attribute :>> fact = "BARRIER is empty for single-threaded VMs and collective otherwise";
            attribute :>> limit = "Do not assign SMP synchronization to every compiled profile";
        }
    }
    part support {
        part workerPhase : SupportingModel {
            attribute :>> contractId = "GC-WORK-CLOSURE";
            attribute :>> kind = "quint";
            attribute :>> path = "models/gambit/gc_work_closure.qnt";
            attribute :>> symbols = "initFixed; step; safe; counted; terminationSafe; phaseSafe; nextPhase; finished";
            attribute :>> scope = "Two workers, two-object graph and two phases; fault=0; atomic visibility only; no fresh checking";
        }
    }
}
