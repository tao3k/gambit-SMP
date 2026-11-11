/* Partial-order design and source facts, not executable QNT or runtime code. */
package GambitCopyHandoff {
    private import ScalarValues::*;
    private import GambitCollectionCompletion::*;
    enum def BodyAcceptance { None; PrivateCursor; QueuedOrScanning; Settled; }
    part def TailEscrowWitness {
        part phase : PhaseScope;
        attribute targetInPublishedPrefix : Boolean;
        attribute tailRequired : Boolean;
        attribute tailIdentityReserved : Boolean;
        attribute tailCustodyLiveOrSettled : Boolean;
        attribute reservationBeforeCommit : Boolean;
        attribute publicationCommitted : Boolean;
    }
    requirement def TailBeforePublicationLaw {
        subject escrow : TailEscrowWitness;
        require constraint {
            not escrow.publicationCommitted or not escrow.targetInPublishedPrefix or not escrow.tailRequired or
            (escrow.tailIdentityReserved and escrow.tailCustodyLiveOrSettled and escrow.reservationBeforeCommit)
        }
    }
    part def VisibilityWitness {
        attribute payloadInitialized : Boolean;
        attribute fragmentInputsKnown : Boolean;
        attribute profileVisibilityEstablished : Boolean;
        attribute initializedPrefixExact : Boolean;
        attribute crossWorkerReadableClaimed : Boolean;
    }
    requirement def InitializedIsNotPublishedLaw {
        subject payload : VisibilityWitness;
        require constraint {
            not payload.crossWorkerReadableClaimed or
            (payload.payloadInitialized and payload.fragmentInputsKnown and
             payload.profileVisibilityEstablished and payload.initializedPrefixExact)
        }
    }
    part def CopyAcceptanceWitness {
        attribute body : BodyAcceptance;
        attribute payloadInitialized : Boolean;
        attribute manifestAndCopyIdentityMatch : Boolean;
        attribute bodyReceiptKnown : Boolean;
        attribute privateCursorOwnerLive : Boolean;
        attribute privateCursorRangeRetained : Boolean;
        attribute eventualScanPathRepresented : Boolean;
        attribute queuedRangeVisibilityKnown : Boolean;
        attribute settledBodyReceiptValid : Boolean;
        attribute tailRequired : Boolean;
        attribute tailReceiptLiveOrSettled : Boolean;
        attribute unresolvedCopyEffect : Boolean;
        attribute copySettled : Boolean;
    }
    requirement def FinishCopyAcceptanceLaw {
        subject acceptance : CopyAcceptanceWitness;
        require constraint {
            not acceptance.copySettled or
            (acceptance.payloadInitialized and acceptance.manifestAndCopyIdentityMatch and
             acceptance.bodyReceiptKnown and not acceptance.unresolvedCopyEffect and
             (not acceptance.tailRequired or acceptance.tailReceiptLiveOrSettled) and
             ((acceptance.body == BodyAcceptance::PrivateCursor and acceptance.privateCursorOwnerLive and
               acceptance.privateCursorRangeRetained and acceptance.eventualScanPathRepresented) or
              (acceptance.body == BodyAcceptance::QueuedOrScanning and acceptance.queuedRangeVisibilityKnown) or
              (acceptance.body == BodyAcceptance::Settled and acceptance.settledBodyReceiptValid)))
        }
    }
    part def PrefixCutWitness {
        attribute closesEarlierPrefix : Boolean;
        attribute targetNotClaimedYet : Boolean;
        attribute targetListedInBatch : Boolean;
        attribute manifestMatchesExactCursor : Boolean;
        attribute prefixCommitClaimed : Boolean;
    }
    requirement def PrefixIdentityLaw {
        subject prefix : PrefixCutWitness;
        require constraint {
            not prefix.prefixCommitClaimed or
            (prefix.manifestMatchesExactCursor and
             (not prefix.closesEarlierPrefix or not prefix.targetNotClaimedYet or not prefix.targetListedInBatch))
        }
    }
    part def CopyFailureWitness {
        attribute requiredEffectStillUnresolved : Boolean;
        attribute externalClaimVisible : Boolean;
        attribute originalCustodianLive : Boolean;
        attribute replacementCustodyAccepted : Boolean;
        attribute canonicalClaimRolledBack : Boolean;
        attribute successfulCompletionClaimed : Boolean;
    }
    requirement def CopyFailureCustodyLaw {
        subject failure : CopyFailureWitness;
        require constraint {
            not failure.requiredEffectStillUnresolved or
            ((failure.originalCustodianLive or failure.replacementCustodyAccepted) and
             (not failure.externalClaimVisible or not failure.canonicalClaimRolledBack) and
             not failure.successfulCompletionClaimed)
        }
    }
    part def CopySettlementDelta {
        attribute copyBefore : Integer;
        attribute copyAfter : Integer;
        attribute bodyBefore : Integer;
        attribute bodyAfter : Integer;
        attribute tailBefore : Integer;
        attribute tailAfter : Integer;
        attribute settlementClaimed : Boolean;
    }
    requirement def CopySettlementFrameLaw {
        subject delta : CopySettlementDelta;
        require constraint {
            not delta.settlementClaimed or
            (delta.copyBefore == 1 and delta.copyAfter == 0 and
             delta.bodyBefore >= 0 and delta.tailBefore >= 0 and
             delta.bodyAfter == delta.bodyBefore and delta.tailAfter == delta.tailBefore)
        }
    }
    part def ActionBinding {
        attribute actionId : String;
    }
    part def CopyRoute {
        attribute routeId : String;
        attribute scope : String;
        attribute orderedCuts : String;
        attribute acceptance : String;
        attribute failureCustodian : String;
        attribute obligationId : String;
    }
    part def FailureCut {
        attribute failureId : String;
        attribute cut : String;
        attribute custody : String;
        attribute forbidden : String;
        attribute boundary : String;
        attribute obligationId : String;
    }
    part def PreservationCase {
        attribute caseId : String;
        attribute premises : String;
        attribute preserved : String;
        attribute existingSupport : String;
        attribute obligationId : String;
    }
    part def SourceFact {
        attribute sourceId : String;
        attribute path : String;
        attribute firstLine : String;
        attribute lastLine : String;
        attribute fact : String;
        attribute limit : String;
    }
    part def DiagramEdge {
        attribute diagramId : String;
        attribute edgeId : String;
        attribute fromState : String;
        attribute toState : String;
        attribute label : String;
        attribute boundary : String;
    }
    part routes {
        part EarlierPrefix : CopyRoute {
            attribute :>> routeId = "EarlierPrefix";
            attribute :>> scope = "Batch contains prior completed copies, not the upcoming target";
            attribute :>> orderedCuts = "Save alloc cursor -> end_heap_chunk -> next/prepare msection -> target header/CAS -> reserve its fragments";
            attribute :>> acceptance = "Only prefix members transfer to queue; no obligation claimed for not-yet-copied target";
            attribute :>> failureCustodian = "Existing root/resolver keeps upcoming target; published prefix has queue/local owners";
            attribute :>> obligationId = "WC-COPY-HANDOFF-ORDER";
        }
        part BoundaryCopy : CopyRoute {
            attribute :>> routeId = "BoundaryCopy";
            attribute :>> scope = "One admitted ordinary movable copy in the closing chunk";
            attribute :>> orderedCuts = "Canonical claim -> cell selects Tail if required -> reserve fragments -> complete payload/padding -> initializeCopy -> publishBatch -> finishCopy after known acceptance";
            attribute :>> acceptance = "Body moves to queue; Tail remains with counted source activation until separately started/settled";
            attribute :>> failureCustodian = "Unknown publication keeps source/transfer ownership; no undo after visible forwarding";
            attribute :>> obligationId = "WC-TAIL-ESCROW";
        }
        part PrivateSuffix : CopyRoute {
            attribute :>> routeId = "PrivateSuffix";
            attribute :>> scope = "Initialized object not yet at chunk threshold";
            attribute :>> orderedCuts = "reserveFragments -> initializeCopy -> accept Body under private cursor -> finishCopy -> later cursor flush/publication/local scan";
            attribute :>> acceptance = "Live private owner retains exact local alloc range, descriptor and future scan path; Tail separately retained";
            attribute :>> failureCustodian = "If private cursor cannot survive interruption, copy cannot settle or interruptible profile is rejected";
            attribute :>> obligationId = "WC-COPY-LOCAL-ACCEPT";
        }
        part CurrentScanBypass : CopyRoute {
            attribute :>> routeId = "CurrentScanBypass";
            attribute :>> scope = "end_heap_chunk sees current scanning interval";
            attribute :>> orderedCuts = "Initialize members -> marker/link boundary -> retain local scanner/cursor custody; no FIFO insertion -> copy settlement only with receipt";
            attribute :>> acceptance = "Existing counted scanner/local producer owns unscanned suffix; no fictitious queue token";
            attribute :>> failureCustodian = "Source/scanner retains unknown descriptor or handoff; empty FIFO is not completion";
            attribute :>> obligationId = "WC-COPY-LOCAL-ACCEPT";
        }
        part AlreadySettledChild : CopyRoute {
            attribute :>> routeId = "AlreadySettledChild";
            attribute :>> scope = "Child fragment can finish before source copy ghost settlement";
            attribute :>> orderedCuts = "Initialize/reserve -> accepted fragment work -> valid fragment settlement -> finishCopy";
            attribute :>> acceptance = "Known settled receipt substitutes for live child owner; canonical identity remains";
            attribute :>> failureCustodian = "Lost or stale receipt is not proof of completion; block affected copy settlement";
            attribute :>> obligationId = "WC-COPY-BALANCE";
        }
        part NoTail : CopyRoute {
            attribute :>> routeId = "NoTail";
            attribute :>> scope = "words == 0 or subtype excludes ordinary Tail role";
            attribute :>> orderedCuts = "Reserve only required Body/visit roles -> initialize -> qualified private/queue acceptance -> finishCopy";
            attribute :>> acceptance = "No dummy Tail task; special descriptors and leaf visits still apply";
            attribute :>> failureCustodian = "Do not apply movable Tail split to still/frame/weak special adapters without evidence";
            attribute :>> obligationId = "WC-TAIL-ESCROW";
        }
    }
    part failureCuts {
        part BeforeClaim : FailureCut {
            attribute :>> failureId = "BeforeClaim";
            attribute :>> cut = "Before winning forwarding CAS";
            attribute :>> custody = "Attempt/resolver retains required source edge; unused reservation may settle";
            attribute :>> forbidden = "No canonical issue or physical padding refund inferred from cancellation";
            attribute :>> boundary = "Proposed failure policy; native mark_array is void";
            attribute :>> obligationId = "WC-COPY-FAILURE";
        }
        part AfterClaim : FailureCut {
            attribute :>> failureId = "AfterClaim";
            attribute :>> cut = "CAS visible before fragment enrollment or bytes complete";
            attribute :>> custody = "Winning initializer remains counted with canonical copy debt; repair/help only after accepted custody";
            attribute :>> forbidden = "Do not restore old header or erase redirected references";
            attribute :>> boundary = "No existing recoverable metadata-allocation failure path established";
            attribute :>> obligationId = "WC-COPY-FAILURE";
        }
        part TailReservation : FailureCut {
            attribute :>> failureId = "TailReservation";
            attribute :>> cut = "Tail selected/reserved but not initialized or started";
            attribute :>> custody = "Counted activation owns cell, region and Tail obligation; copy remains until acceptance is known";
            attribute :>> forbidden = "Preparing cannot be treated as absent or already scanned";
            attribute :>> boundary = "Source automatic variables, not a new runtime registration API";
            attribute :>> obligationId = "WC-TAIL-ESCROW";
        }
        part PartialPublish : FailureCut {
            attribute :>> failureId = "PartialPublish";
            attribute :>> cut = "Link written, tail/barrier/unlock outcome unknown in proposed executor";
            attribute :>> custody = "Keep transfer and source obligation until exact membership and destination acceptance reconciled";
            attribute :>> forbidden = "No speculative re-enqueue, source free or second canonical task";
            attribute :>> boundary = "Current function has no partial-publish error return; profile proof still owed";
            attribute :>> obligationId = "WC-COPY-FAILURE";
        }
        part PrivateOwnerLoss : FailureCut {
            attribute :>> failureId = "PrivateOwnerLoss";
            attribute :>> cut = "Copy settled to private Body then owner may exit/migrate";
            attribute :>> custody = "Body/Tail obligations and cursor descriptor need accepted replacement before loss";
            attribute :>> forbidden = "Do not count old copy settlement as permission to forget private suffix";
            attribute :>> boundary = "If this cannot be guaranteed, exclude such interruption rather than invent recovery";
            attribute :>> obligationId = "WC-COPY-LOCAL-ACCEPT";
        }
        part RetryAndLate : FailureCut {
            attribute :>> failureId = "RetryAndLate";
            attribute :>> cut = "Receipt lost, replayed or delivered after a phase cut";
            attribute :>> custody = "Resolve exact existing TaskId/BatchId; keep valid old lease and pending custody if needed";
            attribute :>> forbidden = "No new same-phase work after closure; no stale raw-pointer relabeling";
            attribute :>> boundary = "Safety may remain blocked without liveness; no new model execution";
            attribute :>> obligationId = "WC-COPY-FAILURE";
        }
    }
    part preservationCases {
        part Reserve : PreservationCase {
            attribute :>> caseId = "Reserve";
            attribute :>> premises = "Tail eligibility and subtype/length fixed; active source, unique role IDs, exact slot/region";
            attribute :>> preserved = "Enroll each required fragment once while canonical copy/root debt still exists";
            attribute :>> existingSupport = "ChildTaskBalanceLaw needs real identity partition and no duplicate issue";
            attribute :>> obligationId = "WC-TAIL-ESCROW";
        }
        part Initialize : PreservationCase {
            attribute :>> caseId = "Initialize";
            attribute :>> premises = "All selected bytes/padding initialized; descriptor valid; fragment reservations retained";
            attribute :>> preserved = "Payload readiness changes without any publication or fragment settlement";
            attribute :>> existingSupport = "Existing copied count abstracts initialization, not cross-worker visibility";
            attribute :>> obligationId = "WC-COPY-HANDOFF-ORDER";
        }
        part Prefix : PreservationCase {
            attribute :>> caseId = "Prefix";
            attribute :>> premises = "Published manifest equals actual end cursor and object boundaries";
            attribute :>> preserved = "Earlier prefix excludes a target not yet claimed; members keep correct canonical IDs";
            attribute :>> existingSupport = "Current QNT publish has one item and no prefix membership identity";
            attribute :>> obligationId = "WC-COPY-HANDOFF-ORDER";
        }
        part Publish : PreservationCase {
            attribute :>> caseId = "Publish";
            attribute :>> premises = "Actual profile barriers/locks; initialized range; all delegated Tail owners; queued or local destination";
            attribute :>> preserved = "Exact Body custody transfers; Tail and parent/root debts unchanged";
            attribute :>> existingSupport = "publicationSafe assumes atomic visibility; full source refinement still open";
            attribute :>> obligationId = "WC-TAIL-ESCROW";
        }
        part PrivateAcceptance : PreservationCase {
            attribute :>> caseId = "PrivateAcceptance";
            attribute :>> premises = "Private cursor and descriptor remain live, counted and discoverable by eventual scan path";
            attribute :>> preserved = "Copy can settle without cross-worker visibility while Body/Tail unfinished work remains";
            attribute :>> existingSupport = "WorkAccounting privateWork premise must cover local alloc beyond public cursor";
            attribute :>> obligationId = "WC-COPY-LOCAL-ACCEPT";
        }
        part SettleCopy : PreservationCase {
            attribute :>> caseId = "SettleCopy";
            attribute :>> premises = "Matching Body/Tail live or settled receipts; no unresolved copy effect; initialized copy";
            attribute :>> preserved = "Only copy debt decrements; no mutation of canonical map or child/parent debts";
            attribute :>> existingSupport = "ChildTaskBalanceLaw plus CopySettlementFrameLaw, not native atomicity from arithmetic";
            attribute :>> obligationId = "WC-COPY-BALANCE";
        }
        part Failure : PreservationCase {
            attribute :>> caseId = "Failure";
            attribute :>> premises = "Known effect class and source/transfer owner, no ABA, accepted replacement before retirement";
            attribute :>> preserved = "Required work retains custody; visible forwarding not rolled back; no false success";
            attribute :>> existingSupport = "Existing QNT has no unknown-effect states or worker-loss recovery proof";
            attribute :>> obligationId = "WC-COPY-FAILURE";
        }
    }
    part sourceFacts {
        part SpaceCut : SourceFact {
            attribute :>> sourceId = "SpaceCut";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3537";
            attribute :>> lastLine = "3555";
            attribute :>> fact = "Space shortage flushes prior alloc cursor and closes old chunk before target header/CAS";
            attribute :>> limit = "Earlier batch is not the upcoming target copy";
        }
        part Claim : SourceFact {
            attribute :>> sourceId = "Claim";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3572";
            attribute :>> lastLine = "3598";
            attribute :>> fact = "Forwarding becomes visible and root slot redirects before body copy";
            attribute :>> limit = "Does not establish body readiness or recoverable failure";
        }
        part TailEscrow : SourceFact {
            attribute :>> sourceId = "TailEscrow";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3599";
            attribute :>> lastLine = "3603";
            attribute :>> fact = "cell = alloc retains the first-field location for eligible Tail role before copying/publishing";
            attribute :>> limit = "Must bind active activation, descriptor, exact slot and region lifetime";
        }
        part Payload : SourceFact {
            attribute :>> sourceId = "Payload";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3604";
            attribute :>> lastLine = "3626";
            attribute :>> fact = "Whole object bytes/padding copied before threshold closure; goto again follows possible publication";
            attribute :>> limit = "Copy completion is not outgoing-edge completion";
        }
        part PrivateCursor : SourceFact {
            attribute :>> sourceId = "PrivateCursor";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3659";
            attribute :>> lastLine = "3664";
            attribute :>> fact = "Final alloc_heap_ptr update exposes local alloc cursor after nested/tail traversal";
            attribute :>> limit = "Private suffix can exist before public cursor refresh";
        }
        part Publication : SourceFact {
            attribute :>> sourceId = "Publication";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3254";
            attribute :>> lastLine = "3306";
            attribute :>> fact = "End marker, conditional FIFO branch, ordered link/tail/barriers, then signal";
            attribute :>> limit = "Currently scanned chunk stays local; notification not task acceptance by itself";
        }
        part LocalScan : SourceFact {
            attribute :>> sourceId = "LocalScan";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4323";
            attribute :>> lastLine = "4381";
            attribute :>> fact = "Local scanning compares against alloc_heap_ptr and later scans incomplete chunk";
            attribute :>> limit = "Separate private cursor must remain represented before this path can see it";
        }
        part CountedLifetime : SourceFact {
            attribute :>> sourceId = "CountedLifetime";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6686";
            attribute :>> lastLine = "6772";
            attribute :>> fact = "Worker scans local/queued work and decrements phase count only after its scan/steal path";
            attribute :>> limit = "Producer census and actual memory-order proof still required";
        }
        part CapturedBoundary : SourceFact {
            attribute :>> sourceId = "CapturedBoundary";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3741";
            attribute :>> lastLine = "3806";
            attribute :>> fact = "Captured frames have MISC_MEM_LOCK, frame links and their own publication condition";
            attribute :>> limit = "Do not transplant ordinary first-field cut or local-variable guard unchanged";
        }
        part AbstractGap : SourceFact {
            attribute :>> sourceId = "AbstractGap";
            attribute :>> path = "models/gambit/gc_work_closure.qnt";
            attribute :>> firstLine = "25";
            attribute :>> lastLine = "53";
            attribute :>> fact = "Current copyWord/publish/scanLocal/acquire use one work state and bounded copied progress";
            attribute :>> limit = "No private acceptance receipt, separate copy settlement or multi-member batch contract";
        }
    }
    part diagramEdges {
        part edge0 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "reserve";
            attribute :>> fromState = "Claimed copy";
            attribute :>> toState = "Reserved Body and optional Tail";
            attribute :>> label = "reserveFragments";
            attribute :>> boundary = "Copy debt and counted source stay live";
        }
        part edge1 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "init";
            attribute :>> fromState = "Reserved Body and optional Tail";
            attribute :>> toState = "Payload initialized";
            attribute :>> label = "initializeCopy";
            attribute :>> boundary = "Local bytes ready; no remote-read claim";
        }
        part edge2 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "private";
            attribute :>> fromState = "Payload initialized";
            attribute :>> toState = "Private Body accepted";
            attribute :>> label = "private cursor receipt";
            attribute :>> boundary = "Exact live cursor and future scan path required";
        }
        part edge3 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "queue";
            attribute :>> fromState = "Payload initialized";
            attribute :>> toState = "Queued Body accepted";
            attribute :>> label = "publishBatch";
            attribute :>> boundary = "Qualified prefix/visibility; Tail owner unchanged";
        }
        part edge4 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "local";
            attribute :>> fromState = "Payload initialized";
            attribute :>> toState = "Local scanner accepted";
            attribute :>> label = "current-scan branch";
            attribute :>> boundary = "No FIFO entry invented";
        }
        part edge5 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "finishprivate";
            attribute :>> fromState = "Private Body accepted";
            attribute :>> toState = "Copy task settled";
            attribute :>> label = "finishCopy";
            attribute :>> boundary = "Body/Tail debts persist";
        }
        part edge6 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "finishqueue";
            attribute :>> fromState = "Queued Body accepted";
            attribute :>> toState = "Copy task settled";
            attribute :>> label = "finishCopy";
            attribute :>> boundary = "Body/Tail debts persist";
        }
        part edge7 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "finishlocal";
            attribute :>> fromState = "Local scanner accepted";
            attribute :>> toState = "Copy task settled";
            attribute :>> label = "finishCopy";
            attribute :>> boundary = "Body/Tail debts persist";
        }
        part edge8 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "later";
            attribute :>> fromState = "Private Body accepted";
            attribute :>> toState = "Queued Body accepted";
            attribute :>> label = "later qualified publication";
            attribute :>> boundary = "Copy may already be settled; same Body TaskId";
        }
        part edge9 : DiagramEdge {
            attribute :>> diagramId = "copy-handoff";
            attribute :>> edgeId = "unknown";
            attribute :>> fromState = "Payload initialized";
            attribute :>> toState = "Retained transfer custody";
            attribute :>> label = "unknown effect";
            attribute :>> boundary = "No success or speculative duplicate publish";
        }
    }
    part actionBindings {
        part reserveFragments : ActionBinding {
            attribute :>> actionId = "reserveFragments";
        }
        part initializeCopy : ActionBinding {
            attribute :>> actionId = "initializeCopy";
        }
        part publishBatch : ActionBinding {
            attribute :>> actionId = "publishBatch";
        }
        part finishCopy : ActionBinding {
            attribute :>> actionId = "finishCopy";
        }
    }


    /* Necessary predicates over a proposed lifecycle witness, not proved behavior. */
    part def CustodyLifetimeWitness {
        attribute finishUseClaimed : Boolean;
        attribute exactIdentityAndGeneration : Boolean;
        attribute initializedAndDescriptorValid : Boolean;
        attribute bodyCurrentCustodyOrSettled : Boolean;
        attribute tailCurrentCustodyOrSettled : Boolean;
        attribute noUnknownEffect : Boolean;
        attribute singleSettlementRight : Boolean;
        attribute ownerRetired : Boolean;
        attribute allPrivateAndTailTransferredOrSettled : Boolean;
        attribute noOpenInitializerOrTransfer : Boolean;
        attribute noRemainingContainerUsers : Boolean;
        attribute transferSourceReleased : Boolean;
        attribute destinationAccepted : Boolean;
        attribute destinationCountedOrQualifiedQueue : Boolean;
        attribute exactCursorAndTaskFrame : Boolean;
        attribute executionRightExclusive : Boolean;
        attribute tailDelegationRequired : Boolean;
        attribute bodyPublished : Boolean;
        attribute tailPreservedIndependently : Boolean;
        attribute privateReceiptUsed : Boolean;
        attribute privateOwnerCountedAndReachable : Boolean;
        attribute cursorDescriptorAndStorageRetained : Boolean;
        attribute eventualScanRepresented : Boolean;
    }
    requirement def CurrentCopyReceiptLaw {
        subject lease : CustodyLifetimeWitness;
        require constraint {
            not lease.finishUseClaimed or
            (lease.exactIdentityAndGeneration and lease.initializedAndDescriptorValid and
             lease.bodyCurrentCustodyOrSettled and lease.tailCurrentCustodyOrSettled and
             lease.noUnknownEffect and lease.singleSettlementRight)
        }
    }
    requirement def PrivateCursorLeaseLaw {
        subject lease : CustodyLifetimeWitness;
        require constraint {
            not lease.privateReceiptUsed or
            (lease.privateOwnerCountedAndReachable and lease.cursorDescriptorAndStorageRetained and
             lease.eventualScanRepresented)
        }
    }
    requirement def CustodianRetirementLaw {
        subject lease : CustodyLifetimeWitness;
        require constraint {
            not lease.ownerRetired or
            (lease.allPrivateAndTailTransferredOrSettled and lease.noOpenInitializerOrTransfer and
             lease.noRemainingContainerUsers)
        }
    }
    requirement def AcceptedTransferBeforeReleaseLaw {
        subject lease : CustodyLifetimeWitness;
        require constraint {
            not lease.transferSourceReleased or
            (lease.destinationAccepted and lease.destinationCountedOrQualifiedQueue and
             lease.exactCursorAndTaskFrame and lease.executionRightExclusive)
        }
    }
    requirement def TailSurvivesBodyPublicationLaw {
        subject lease : CustodyLifetimeWitness;
        require constraint {
            not lease.bodyPublished or not lease.tailDelegationRequired or lease.tailPreservedIndependently
        }
    }
    part def LifetimeStep {
        attribute stepId : String;
        attribute fromState : String;
        attribute toState : String;
        attribute guard : String;
        attribute custody : String;
        attribute taskFrame : String;
        attribute obligationId : String;
    }
    part def ReceiptRule {
        attribute ruleId : String;
        attribute cut : String;
        attribute validity : String;
        attribute limit : String;
        attribute obligationId : String;
    }
    part def LifetimeCounterexample {
        attribute scenarioId : String;
        attribute classification : String;
        attribute history : String;
        attribute failure : String;
        attribute requiredGuard : String;
        attribute obligationId : String;
    }
    part lifetimeSteps {
        part entry0 : LifetimeStep {
            attribute :>> stepId = "Enter";
            attribute :>> fromState = "Public cursor";
            attribute :>> toState = "Private activation";
            attribute :>> guard = "Snapshot alloc/limit; select cell; retain region and activation identity";
            attribute :>> custody = "Counted phase participant owns unfinished copy/Tail and private suffix";
            attribute :>> taskFrame = "No task settles; C automatic locals are the inspected representation";
            attribute :>> obligationId = "WC-PRIVATE-LIFETIME";
        }
        part entry1 : LifetimeStep {
            attribute :>> stepId = "TailLoop";
            attribute :>> fromState = "Private activation";
            attribute :>> toState = "Private activation";
            attribute :>> guard = "goto again follows Tail synchronously; each new copy may derive further tasks";
            attribute :>> custody = "Current cell plus remaining start/n and alloc/limit must survive; completed Tail edge can derive copy debt";
            attribute :>> taskFrame = "Tail progress is not whole-object or descendant completion";
            attribute :>> obligationId = "WC-TAIL-LIFETIME";
        }
        part entry2 : LifetimeStep {
            attribute :>> stepId = "Flush";
            attribute :>> fromState = "Private activation";
            attribute :>> toState = "Public local cursor";
            attribute :>> guard = "Write alloc_heap_ptr at threshold/space cut or normal mark_array return";
            attribute :>> custody = "Cursor becomes visible to local scan; Tail may remain on stack at threshold";
            attribute :>> taskFrame = "Same Body identities; no settlement from cursor assignment";
            attribute :>> obligationId = "WC-PRIVATE-LIFETIME";
        }
        part entry3 : LifetimeStep {
            attribute :>> stepId = "Publish";
            attribute :>> fromState = "Public local cursor";
            attribute :>> toState = "Queue or local scanner";
            attribute :>> guard = "Exact end marker/prefix and profile lock/barriers; current-scan branch stays local";
            attribute :>> custody = "Body queue/local custodian accepts; source retains Tail; queue container stays pinned";
            attribute :>> taskFrame = "Move Body custody without changing task set";
            attribute :>> obligationId = "WC-TAIL-LIFETIME";
        }
        part entry4 : LifetimeStep {
            attribute :>> stepId = "PrepareTransfer";
            attribute :>> fromState = "Private activation";
            attribute :>> toState = "Frozen transfer";
            attribute :>> guard = "Proposed migration only: freeze old execution right; preserve full continuation/cursor/role frame";
            attribute :>> custody = "Source stays counted until destination or counted transfer service accepts; no idle gap";
            attribute :>> taskFrame = "No task reissue; old and new may be counted simultaneously";
            attribute :>> obligationId = "WC-OWNER-TRANSFER";
        }
        part entry5 : LifetimeStep {
            attribute :>> stepId = "AcceptTransfer";
            attribute :>> fromState = "Frozen transfer";
            attribute :>> toState = "Successor custodian";
            attribute :>> guard = "Accept exact collection/phase/region/activation generation and unfinished task set";
            attribute :>> custody = "One execution right; durable acceptance before source release; unknown outcome retains transfer";
            attribute :>> taskFrame = "Task ownership changes; issued/settled sets unchanged";
            attribute :>> obligationId = "WC-OWNER-TRANSFER";
        }
        part entry6 : LifetimeStep {
            attribute :>> stepId = "DrainIdle";
            attribute :>> fromState = "Local scanner or successor";
            attribute :>> toState = "Phase idle";
            attribute :>> guard = "No private activation/Tail/initializer/transfer debt; complete local scan/steal path before count decrement";
            attribute :>> custody = "Queued tasks can reside in pinned queue while owner idle; phase closure needs complete producer inventory";
            attribute :>> taskFrame = "Idle differs from PSTATE destruction and does not settle queued tasks";
            attribute :>> obligationId = "WC-OWNER-RETIRE";
        }
        part entry7 : LifetimeStep {
            attribute :>> stepId = "Retire";
            attribute :>> fromState = "Phase idle";
            attribute :>> toState = "Retired storage";
            attribute :>> guard = "No remaining raw-pointer/container/scanner users; all unfinished rights accepted elsewhere or settled";
            attribute :>> custody = "Keep queues/locks/msections alive until users drain or container migration is accepted";
            attribute :>> taskFrame = "Thread exit alone is not a reclamation permit";
            attribute :>> obligationId = "WC-OWNER-RETIRE";
        }
    }
    part receiptRules {
        part entry0 : ReceiptRule {
            attribute :>> ruleId = "IssuePrivate";
            attribute :>> cut = "At candidate finishCopy cut";
            attribute :>> validity = "Exact initialized copy, generation, local alloc range/role frame, counted activation and future scan path; required Tail retained";
            attribute :>> limit = "No native receipt API exists; ghost cut requires source simulation";
            attribute :>> obligationId = "WC-RECEIPT-CURRENCY";
        }
        part entry1 : ReceiptRule {
            attribute :>> ruleId = "ConsumeOnce";
            attribute :>> cut = "Actual finishCopy settlement";
            attribute :>> validity = "Revalidate current custody or accepted successor/settled receipts and one settlement right; no unknown effects";
            attribute :>> limit = "An old Boolean accepted flag or worker ID alone is insufficient";
            attribute :>> obligationId = "WC-RECEIPT-CURRENCY";
        }
        part entry2 : ReceiptRule {
            attribute :>> ruleId = "Advance";
            attribute :>> cut = "After publication or migration";
            attribute :>> validity = "Replace authority by exact same-task successor chain; historical settlement remains true";
            attribute :>> limit = "Do not revive Copy debt or use stale private lease as current execution authority";
            attribute :>> obligationId = "WC-OWNER-TRANSFER";
        }
        part entry3 : ReceiptRule {
            attribute :>> ruleId = "PublishBody";
            attribute :>> cut = "At threshold closure before goto again";
            attribute :>> validity = "Only Body custody advances to queue/scanner; Tail remains source-owned until explicit transfer or discharge";
            attribute :>> limit = "Signal is not receipt; queue ownership is not whole-object ownership";
            attribute :>> obligationId = "WC-TAIL-LIFETIME";
        }
        part entry4 : ReceiptRule {
            attribute :>> ruleId = "IdleAndExit";
            attribute :>> cut = "Before counted retirement or storage destruction";
            attribute :>> validity = "Idle forbids owner-private/Tail/transfer work; destruction additionally forbids queue/lock/storage users";
            attribute :>> limit = "Native root scanning starts counted before mark_reachable; arbitrary forced OS exit unqualified";
            attribute :>> obligationId = "WC-OWNER-RETIRE";
        }
        part entry5 : ReceiptRule {
            attribute :>> ruleId = "Reuse";
            attribute :>> cut = "After phase/region/worker slot reuse";
            attribute :>> validity = "Historical receipts remain records; new authority requires matching fresh generation; old settled receipt authorizes no storage access";
            attribute :>> limit = "Same address or processor index does not authenticate new custody";
            attribute :>> obligationId = "WC-RECEIPT-CURRENCY";
        }
    }
    part lifetimeCounterexamples {
        part entry0 : LifetimeCounterexample {
            attribute :>> scenarioId = "UnflushedExit";
            attribute :>> classification = "design-negative";
            attribute :>> history = "reserve -> initialize -> private accept -> finishCopy -> discard activation -> all counts zero";
            attribute :>> failure = "Body lies beyond alloc_heap_ptr; queue empty hides unfinished task";
            attribute :>> requiredGuard = "Reject idle/exit or accept complete replacement before release";
            attribute :>> obligationId = "WC-PRIVATE-LIFETIME";
        }
        part entry1 : LifetimeCounterexample {
            attribute :>> scenarioId = "PublishedTailLost";
            attribute :>> classification = "design-negative";
            attribute :>> history = "select cell -> copy -> publish Body -> drop source Tail -> remote Body finishes";
            attribute :>> failure = "PAIR/default skips delegated first field; Tail target never traced";
            attribute :>> requiredGuard = "Retain source cell/continuation until Tail settles/transfers";
            attribute :>> obligationId = "WC-TAIL-LIFETIME";
        }
        part entry2 : LifetimeCounterexample {
            attribute :>> scenarioId = "AnnounceThenExit";
            attribute :>> classification = "design-negative";
            attribute :>> history = "freeze -> announce destination -> source decrements/exits -> destination rejects";
            attribute :>> failure = "Announcement leaves no accepted counted custodian";
            attribute :>> requiredGuard = "Acceptance-before-release; failure keeps old/frozen counted owner";
            attribute :>> obligationId = "WC-OWNER-TRANSFER";
        }
        part entry3 : LifetimeCounterexample {
            attribute :>> scenarioId = "TwinExecutors";
            attribute :>> classification = "design-negative";
            attribute :>> history = "destination accepts -> old resumes goto again while new resumes same cell";
            attribute :>> failure = "Double traversal/settlement despite balanced scalar count";
            attribute :>> requiredGuard = "Exclusive execution right with exact transfer generation";
            attribute :>> obligationId = "WC-OWNER-TRANSFER";
        }
        part entry4 : LifetimeCounterexample {
            attribute :>> scenarioId = "StaleReceipt";
            attribute :>> classification = "design-negative";
            attribute :>> history = "issue private receipt -> migrate/reuse same worker index -> consume old receipt";
            attribute :>> failure = "Old address/index passes while task/region generation changed";
            attribute :>> requiredGuard = "Current successor/settled evidence plus one-shot Copy settlement";
            attribute :>> obligationId = "WC-RECEIPT-CURRENCY";
        }
        part entry5 : LifetimeCounterexample {
            attribute :>> scenarioId = "IdleQueueFreed";
            attribute :>> classification = "design-negative";
            attribute :>> history = "publish -> worker goes idle -> destroy origin PSTATE/FIFO lock -> thief reads queue";
            attribute :>> failure = "Idle can retain queued chunks; reader uses freed container/storage";
            attribute :>> requiredGuard = "Retire only after container users and queue references drain/transfer";
            attribute :>> obligationId = "WC-OWNER-RETIRE";
        }
        part entry6 : LifetimeCounterexample {
            attribute :>> scenarioId = "ResizeInsideCopy";
            attribute :>> classification = "reachability-unresolved";
            attribute :>> history = "hypothetical forced resize/exit between cell selection and goto again";
            attribute :>> failure = "Inspected synchronized resize path is outside active GC calls; no legal mid-copy caller demonstrated";
            attribute :>> requiredGuard = "Retain as future executor fault history, not current native reachable trace";
            attribute :>> obligationId = "WC-LIFETIME-SOURCE";
        }
        part entry7 : LifetimeCounterexample {
            attribute :>> scenarioId = "WholeObjectPublished";
            attribute :>> classification = "design-negative";
            attribute :>> history = "publication receipt for Body -> settle Copy and Tail as one task";
            attribute :>> failure = "One receipt deletes independent Tail/parent debt";
            attribute :>> requiredGuard = "finishCopy removes exactly CopyTask; keep descendant task identity";
            attribute :>> obligationId = "WC-TAIL-LIFETIME";
        }
    }
    part lifetimePreservation {
        part entry0 : PreservationCase {
            attribute :>> caseId = "ActivationFrame";
            attribute :>> premises = "Complete alloc/limit/cell/start/n plus region/descriptor inventory and admitted special-role adapters";
            attribute :>> preserved = "Every private word/edge represented by a live counted custodian; synchronous tail chain maps to explicit tasks";
            attribute :>> existingSupport = "Existing privateWork Bool lacks frame/range completeness";
            attribute :>> obligationId = "WC-PRIVATE-LIFETIME";
        }
        part entry1 : PreservationCase {
            attribute :>> caseId = "TailAdvance";
            attribute :>> premises = "Exact eligible first-field identity; current cell traced before caller may return; child issue retained";
            attribute :>> preserved = "Discharge only traced edge and preserve newly derived copy/fragment debts";
            attribute :>> existingSupport = "No Body/Tail states in current QNT";
            attribute :>> obligationId = "WC-TAIL-LIFETIME";
        }
        part entry2 : PreservationCase {
            attribute :>> caseId = "FlushAndPublish";
            attribute :>> premises = "Exact initialized prefix; local cursor flush distinguished from remote visibility and queue container pin";
            attribute :>> preserved = "Same task identities advance custody; Tail unaffected";
            attribute :>> existingSupport = "Current publish is one atomic item; local scan lacks private/public cursor split";
            attribute :>> obligationId = "WC-TAIL-LIFETIME";
        }
        part entry3 : PreservationCase {
            attribute :>> caseId = "TransferCommit";
            attribute :>> premises = "Freeze execution, source counted, destination accepted and counted/qualified queue, fresh generation, unknown-effect resolution";
            attribute :>> preserved = "No zero-custody gap and no duplicate execution; map updates exact unfinished domain";
            attribute :>> existingSupport = "No migration/transfer actions in current QNT or concrete Lean map";
            attribute :>> obligationId = "WC-OWNER-TRANSFER";
        }
        part entry4 : PreservationCase {
            attribute :>> caseId = "ReceiptConsumption";
            attribute :>> premises = "Current successor closure or valid settled receipt, one settlement right, descriptor and phase match";
            attribute :>> preserved = "Copy settles once; historical event remains true while authority evolves";
            attribute :>> existingSupport = "Current Lean generation lemma only covers scalar identity invalidation";
            attribute :>> obligationId = "WC-RECEIPT-CURRENCY";
        }
        part entry5 : PreservationCase {
            attribute :>> caseId = "IdleAndRetire";
            attribute :>> premises = "No owner-private/Tail/initializer/transit obligations; all container/raw-pointer users drained before destruction";
            attribute :>> preserved = "ProducerLifetimeSafe remains invariant; idle does not imply reclaim permission";
            attribute :>> existingSupport = "Existing idle guard conflates queue globally; no PSTATE lifetime model";
            attribute :>> obligationId = "WC-OWNER-RETIRE";
        }
        part entry6 : PreservationCase {
            attribute :>> caseId = "ProjectionProgress";
            attribute :>> premises = "Exact state/step mapping; native impossible mid-call migration not silently added to old source; finite internal stutter for liveness";
            attribute :>> preserved = "History witnesses do not change original observations or assume future acceptance";
            attribute :>> existingSupport = "Safety simulation and progress require separate proof; no new execution";
            attribute :>> obligationId = "WC-LIFETIME-SOURCE";
        }
    }
    part lifetimeSources {
        part EntryCursor : SourceFact {
            attribute :>> sourceId = "EntryCursor";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3502";
            attribute :>> lastLine = "3518";
            attribute :>> fact = "alloc/limit and cell/start/n are local activation state; goto again stays in this call";
            attribute :>> limit = "OS scheduling suspension that retains stack is not ownership transfer";
        }
        part PhaseEnrollment : SourceFact {
            attribute :>> sourceId = "PhaseEnrollment";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "3417";
            attribute :>> lastLine = "3459";
            attribute :>> fact = "All participant heaps/FIFOs are initialized and both scan counts set to np before root scans";
            attribute :>> limit = "Participant stability and barrier profile remain proof premises";
        }
        part RootBeforeScan : SourceFact {
            attribute :>> sourceId = "RootBeforeScan";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "6835";
            attribute :>> lastLine = "6870";
            attribute :>> fact = "Root marking precedes mark_reachable_from_marked on same synchronous path";
            attribute :>> limit = "Root producers are counted before scan-loop entry; no independent worker protocol";
        }
        part ResizeExit : SourceFact {
            attribute :>> sourceId = "ResizeExit";
            attribute :>> path = "vendor/gambit/lib/setup.c";
            attribute :>> firstLine = "900";
            attribute :>> lastLine = "936";
            attribute :>> fact = "Optional GC returns before barrier and processor cleanup/thread exit in resize path";
            attribute :>> limit = "No evidence of legal asynchronous migration of active mark_array locals";
        }
        part PhaseBarriers : SourceFact {
            attribute :>> sourceId = "PhaseBarriers";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "7000";
            attribute :>> lastLine = "7042";
            attribute :>> fact = "Setup, strong, weak and cleanup calls are separated by barriers before heap resize";
            attribute :>> limit = "Not proof of all callers or recovery from killed OS thread";
        }
        part CleanupNoCursorTransfer : SourceFact {
            attribute :>> sourceId = "CleanupNoCursorTransfer";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> firstLine = "4928";
            attribute :>> lastLine = "4935";
            attribute :>> fact = "cleanup_mem_pstate invokes free_still_objs and cleanup_rc";
            attribute :>> limit = "This function is not a private alloc/cell handoff API";
        }
    }
    part lifetimeDiagram {
        part lifeEdge0 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life0";
            attribute :>> fromState = "Private activation";
            attribute :>> toState = "Public local cursor";
            attribute :>> label = "flush cursor; Tail retained";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge1 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life1";
            attribute :>> fromState = "Public local cursor";
            attribute :>> toState = "Pinned queue Body";
            attribute :>> label = "qualified publishBatch";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge2 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life2";
            attribute :>> fromState = "Private activation";
            attribute :>> toState = "Frozen transfer";
            attribute :>> label = "freeze; source stays counted";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge3 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life3";
            attribute :>> fromState = "Frozen transfer";
            attribute :>> toState = "Successor custodian";
            attribute :>> label = "accept exact state + exclusive right";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge4 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life4";
            attribute :>> fromState = "Frozen transfer";
            attribute :>> toState = "Retained source custody";
            attribute :>> label = "reject or unknown outcome";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge5 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life5";
            attribute :>> fromState = "Successor custodian";
            attribute :>> toState = "Local work drained";
            attribute :>> label = "scan or transfer remaining work";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge6 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life6";
            attribute :>> fromState = "Private activation";
            attribute :>> toState = "Local work drained";
            attribute :>> label = "trace Tail; flush and scan Body";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge7 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life7";
            attribute :>> fromState = "Pinned queue Body";
            attribute :>> toState = "Remote scanner";
            attribute :>> label = "dequeue; container pinned";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge8 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life8";
            attribute :>> fromState = "Remote scanner";
            attribute :>> toState = "Fragment settled";
            attribute :>> label = "scan + accepted descendants";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge9 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life9";
            attribute :>> fromState = "Local work drained";
            attribute :>> toState = "Phase idle";
            attribute :>> label = "no private or transit obligations";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
        part lifeEdge10 : DiagramEdge {
            attribute :>> diagramId = "custody-lifetime";
            attribute :>> edgeId = "life10";
            attribute :>> fromState = "Phase idle";
            attribute :>> toState = "Retired storage";
            attribute :>> label = "no queue/lock/region users";
            attribute :>> boundary = "Proposed acceptance guards; existing synchronous source only where mapped";
        }
    }
}
