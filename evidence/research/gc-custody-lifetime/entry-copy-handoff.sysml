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
}
