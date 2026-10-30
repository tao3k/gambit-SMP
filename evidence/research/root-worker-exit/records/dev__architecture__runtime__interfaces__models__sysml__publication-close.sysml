/* Modern-C reference protocol and source inventory. Necessary predicates only;
 * no runtime implementation, concrete mutex mapping, satisfaction or proof run. */
package GambitPublicationClose {
    private import ScalarValues::*;
    enum def PublicationOutcome { Prepared; Committed; Rejected; Unknown; }
    part def GateDomain {
        ref part revocation : GambitMembershipRevocation::PhaseRevocation;
        attribute gateId : Integer;
        attribute generation : Integer;
        attribute gateHeld : Boolean;
        attribute queueHeld : Boolean;
        attribute miscAcquireRequested : Boolean;
        attribute payloadCopyWhileGateHeld : Boolean;
        attribute allocationWhileLocked : Boolean;
        attribute receiptWaitWhileLocked : Boolean;
        attribute nativeCallbackWhileLocked : Boolean;
        attribute unhandledControlExitWhileLocked : Boolean;
    }
    requirement def LockDisciplineLaw {
        subject gate : GateDomain;
        require constraint {
            gate.gateId > 0 and gate.generation > 0 and
            (not gate.queueHeld or gate.gateHeld) and
            (not gate.miscAcquireRequested or (not gate.gateHeld and not gate.queueHeld)) and
            not gate.payloadCopyWhileGateHeld and not gate.allocationWhileLocked and
            not gate.receiptWaitWhileLocked and not gate.nativeCallbackWhileLocked and
            not gate.unhandledControlExitWhileLocked }
    }
    part def PublicationTicket {
        ref part gate : GateDomain;
        ref part work : GambitGc::CollectorWorkContext;
        attribute ticketId : Integer;
        attribute ticketGeneration : Integer;
        attribute chunkId : Integer;
        attribute chunkGeneration : Integer;
        attribute reservationKnown : Boolean;
        attribute reservationCut : Boolean;
        attribute publishCut : Boolean;
        attribute acquireCut : Boolean;
        attribute settlementCut : Boolean;
        attribute reservationFresh : Boolean;
        attribute stableRecordPublished : Boolean;
        attribute issuerAccounted : Boolean;
        attribute producerOrDrainRightLive : Boolean;
        attribute unfinishedCreditLive : Boolean;
        attribute publicationReceiptDebtLive : Boolean;
        attribute payloadInitialized : Boolean;
        attribute coverageBoundToBatch : Boolean;
        attribute queueVisible : Boolean;
        attribute firstCommit : Boolean;
        attribute queueOwnershipCommitted : Boolean;
        attribute payloadPublicationEstablished : Boolean;
        attribute outcome : PublicationOutcome;
        attribute dequeued : Boolean;
        attribute scannerOrTransferCustodianLive : Boolean;
        attribute queueOwnershipReleased : Boolean;
        attribute parentSettled : Boolean;
        attribute allEdgesCovered : Boolean;
        attribute requiredChildrenAccepted : Boolean;
        attribute settlementSingleUse : Boolean;
        attribute ownerLastUseComplete : Boolean;
    }
    requirement def ReservationLaw {
        subject ticket : PublicationTicket;
        require constraint { not ticket.reservationCut or
            (ticket.reservationKnown and ticket.ticketId > 0 and ticket.ticketGeneration > 0 and
             ticket.chunkId > 0 and ticket.chunkGeneration > 0 and
             ticket.reservationFresh and ticket.stableRecordPublished and ticket.issuerAccounted and
             ticket.producerOrDrainRightLive and ticket.unfinishedCreditLive and
             ticket.publicationReceiptDebtLive and not ticket.gate.revocation.effectivePublished) }
    }
    /* Cut flags select transition witnesses, not persistent state invariants.
     * In particular, a visible queue need not keep locks held after commit. */
    requirement def PublishCommitLaw {
        subject ticket : PublicationTicket;
        require constraint { not ticket.publishCut or
            (ticket.queueVisible and ticket.reservationKnown and ticket.gate.gateHeld and ticket.gate.queueHeld and
             ticket.firstCommit and ticket.payloadInitialized and ticket.coverageBoundToBatch and
             ticket.unfinishedCreditLive and ticket.publicationReceiptDebtLive and
             ticket.queueOwnershipCommitted and ticket.payloadPublicationEstablished and
             ticket.outcome == PublicationOutcome::Committed and
             ticket.work.taskGrantLive and ticket.work.teamGrantLive and ticket.work.descriptorLeaseLive and
             ticket.work.phaseScope.collection.vmId == ticket.gate.revocation.closure.scope.collection.vmId and
             ticket.work.phaseScope.collection.vmGeneration == ticket.gate.revocation.closure.scope.collection.vmGeneration and
             ticket.work.phaseScope.collection.collectionEpoch == ticket.gate.revocation.closure.scope.collection.collectionEpoch and
             ticket.work.phaseScope.collection.rootCutEpoch == ticket.gate.revocation.closure.scope.collection.rootCutEpoch and
             ticket.work.phaseScope.phase == ticket.gate.revocation.closure.scope.phase and
             ticket.work.phaseScope.round == ticket.gate.revocation.closure.scope.round and
             ticket.work.phaseScope.producerGeneration == ticket.gate.revocation.closure.scope.producerGeneration and
             ticket.work.phaseScope.workerTeam.resourceId == ticket.gate.revocation.closure.scope.workerTeam.resourceId and
             ticket.work.phaseScope.workerTeam.resourceGeneration == ticket.gate.revocation.closure.scope.workerTeam.resourceGeneration) }
    }
    requirement def AcquireCustodyLaw {
        subject ticket : PublicationTicket;
        require constraint { not ticket.acquireCut or
            (ticket.dequeued and ticket.gate.gateHeld and ticket.gate.queueHeld and ticket.queueOwnershipReleased and
             ticket.scannerOrTransferCustodianLive and ticket.unfinishedCreditLive and
             not ticket.parentSettled) }
    }
    requirement def SettlementLaw {
        subject ticket : PublicationTicket;
        require constraint { not ticket.settlementCut or
            (ticket.parentSettled and ticket.allEdgesCovered and ticket.requiredChildrenAccepted and
             ticket.settlementSingleUse and ticket.ownerLastUseComplete and
             not ticket.unfinishedCreditLive) }
    }
    part def UnknownOutcomeCustody {
        ref part ticket : PublicationTicket;
        attribute outcomeUnknown : Boolean;
        attribute preEnrolledReconcilerLive : Boolean;
        attribute stablePriorRootOrHandleLease : Boolean;
        attribute sourceOrTransferCustodianLive : Boolean;
        attribute receiptDebtRetained : Boolean;
        attribute sameTicketIdentityRetained : Boolean;
        attribute blindRepublish : Boolean;
        attribute backingReleased : Boolean;
    }
    requirement def UnknownCustodyLaw {
        subject effect : UnknownOutcomeCustody;
        require constraint { not effect.outcomeUnknown or
            (effect.preEnrolledReconcilerLive and effect.stablePriorRootOrHandleLease and
             effect.sourceOrTransferCustodianLive and effect.receiptDebtRetained and
             effect.ticket.publicationReceiptDebtLive and effect.sameTicketIdentityRetained and
             not effect.blindRepublish and not effect.backingReleased) }
    }
    /* Batch tickets project onto existing credits. They do not replace still,
     * root-seed, private-copy or Tail producer accounting. */
    part def CloseSnapshot {
        ref part gate : GateDomain;
        ref part rootWriters : RootWriterClosure;
        attribute unfinishedBatchTickets : Integer;
        attribute batchLedgerComplete : Boolean;
        attribute ledgerProjectionEstablished : Boolean;
        attribute observedRevision : Integer;
        attribute currentRevision : Integer;
        attribute writerDomainClosed : Boolean;
        attribute closeCut : Boolean;
        attribute closedPublished : Boolean;
    }
    requirement def CloseCutLaw {
        subject cut : CloseSnapshot;
        require constraint { cut.unfinishedBatchTickets >= 0 and
            (not cut.closeCut or
             (cut.closedPublished and cut.gate.gateHeld and cut.batchLedgerComplete and cut.ledgerProjectionEstablished and
              cut.unfinishedBatchTickets == 0 and cut.writerDomainClosed and
              cut.rootWriters.scanGranted and
              cut.rootWriters.membership.collection.vmId == cut.gate.revocation.closure.scope.collection.vmId and
              cut.rootWriters.membership.collection.vmGeneration == cut.gate.revocation.closure.scope.collection.vmGeneration and
              cut.rootWriters.membership.collection.collectionEpoch == cut.gate.revocation.closure.scope.collection.collectionEpoch and
              cut.rootWriters.membership.collection.rootCutEpoch == cut.gate.revocation.closure.scope.collection.rootCutEpoch and
              cut.observedRevision == cut.currentRevision and
              cut.gate.revocation.effectivePublished)) }
    }
    part def RootWriterClosure {
        ref part membership : GambitMembershipRevocation::MembershipCut;
        attribute concreteWriterCensusComplete : Boolean;
        attribute unknownNativeWriterAdmitted : Boolean;
        attribute unorderedWriters : Integer;
        attribute scannerRelocationWriterRegistered : Boolean;
        attribute scanGranted : Boolean;
    }
    requirement def RootWriterAdmissionLaw {
        subject roots : RootWriterClosure;
        require constraint { roots.unorderedWriters >= 0 and
            (not roots.scanGranted or
             (roots.membership.rootSetSealed and roots.concreteWriterCensusComplete and
              not roots.unknownNativeWriterAdmitted and roots.unorderedWriters == 0 and
              roots.scannerRelocationWriterRegistered)) }
    }
    part def SynchronousSpecialization {
        attribute publisherDebtErased : Boolean;
        attribute reserveCommitFused : Boolean;
        attribute everyPublisherLifetimeEnclosed : Boolean;
        attribute issuerLiveThroughPublisherLastUse : Boolean;
        attribute noPublisherEscape : Boolean;
        attribute producerLedgerComplete : Boolean;
        attribute allCurrentCallerBindingsCovered : Boolean;
        attribute accessProfileQualified : Boolean;
        attribute privatePrefixProtected : Boolean;
        attribute stableTicketStorageReady : Boolean;
        attribute fusedCommitPreservesDebt : Boolean;
    }
    requirement def SupportErasureLaw {
        subject refinement : SynchronousSpecialization;
        require constraint {
            (not refinement.publisherDebtErased or
             (refinement.everyPublisherLifetimeEnclosed and refinement.issuerLiveThroughPublisherLastUse and
              refinement.noPublisherEscape and refinement.producerLedgerComplete and
              refinement.allCurrentCallerBindingsCovered and refinement.accessProfileQualified)) and
            (not refinement.reserveCommitFused or
             (refinement.privatePrefixProtected and refinement.stableTicketStorageReady and
              refinement.fusedCommitPreservesDebt and refinement.accessProfileQualified)) }
    }
    part def CallerSite {
        ref part family : GambitProducerCustody::ProducerFamily;
        ref part formal : GambitRuntimeModelRelations::ContractBinding;
        attribute callerId : String;
        attribute role : String;
        attribute sourcePath : String;
        attribute sourceLines : String;
        attribute chain : String;
        attribute closingCut : String;
        attribute coverageLimit : String;
    }
    part def RefinementDuty {
        ref part formal : GambitRuntimeModelRelations::ContractBinding;
        attribute dutyId : String;
        attribute lawSymbol : String;
        attribute sourcePath : String;
        attribute openPremise : String;
    }
    part caller0 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.MovableCopy;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "PUB-MOVE-SPACE";
        attribute :>> role = "publisher";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3550";
        attribute :>> chain = "mark_array capacity rollover -> end_heap_chunk";
        attribute :>> closingCut = "accepted batch and live issuer until drain";
        attribute :>> coverageLimit = "Word-size padding and allocation frontier proof remain required";
    }
    part caller1 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.MovableCopy;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "PUB-MOVE-SIZE";
        attribute :>> role = "publisher";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3619";
        attribute :>> chain = "mark_array copied threshold -> end_heap_chunk";
        attribute :>> closingCut = "complete prefix publication and private Tail custody";
        attribute :>> coverageLimit = "Forwarding visibility precedes body initialization";
    }
    part caller2 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CapturedFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "PUB-FRAME-SPACE";
        attribute :>> role = "publisher";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3747";
        attribute :>> chain = "mark_captured_continuation rollover -> end_heap_chunk";
        attribute :>> closingCut = "frame copy and root debt retained across publication";
        attribute :>> coverageLimit = "MISC lock is already held on this path";
    }
    part caller3 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CapturedFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "PUB-FRAME-SIZE";
        attribute :>> role = "publisher";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3797";
        attribute :>> chain = "mark_captured_continuation threshold -> end_heap_chunk";
        attribute :>> closingCut = "complete frame prefix with pending frame scan retained";
        attribute :>> coverageLimit = "Frame coordinates and descriptor coverage remain open";
    }
    part caller4 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.VmRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "SEED-STRONG";
        attribute :>> role = "producer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "6845-6864";
        attribute :>> chain = "strong phase -> VM/symkey/RC/global/control/register/saved/cache/processor scans";
        attribute :>> closingCut = "every root seed and descendants counted before idle";
        attribute :>> coverageLimit = "Full admitted native root/writer domain not closed";
    }
    part caller5 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.StillSeeds;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "SEED-STILL";
        attribute :>> role = "producer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "4210-4232;6800";
        attribute :>> chain = "GC setup -> setup_still_objs_to_scan";
        attribute :>> closingCut = "external still seeds remain local work until scanned";
        attribute :>> coverageLimit = "External refcount writers require separate admission";
    }
    part caller6 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.WeakWills;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "SEED-WEAK";
        attribute :>> role = "producer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "5063-5099;6898-6902";
        attribute :>> chain = "weak phase -> process_wills -> mark_array -> reachable -> move_continuation";
        attribute :>> closingCut = "new phase census and later continuation last use";
        attribute :>> coverageLimit = "Will enqueue is not execution of the Scheme action";
    }
    part caller7 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.StillScan;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "SCAN-STILL";
        attribute :>> role = "producer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "4235-4250;6688";
        attribute :>> chain = "mark_reachable -> remove still head -> scan -> mark_array";
        attribute :>> closingCut = "scanner custody survives list removal";
        attribute :>> coverageLimit = "Empty still list does not imply completed scan";
    }
    part caller8 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ChunkScanSteal;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "SCAN-LOCAL";
        attribute :>> role = "producer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "4329;4365";
        attribute :>> chain = "scan_movable -> local cursor or dequeue -> scan_complete_heap_chunk";
        attribute :>> closingCut = "private or acquired debt survives unlock";
        attribute :>> coverageLimit = "Currently scanned chunk can bypass FIFO";
    }
    part caller9 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ChunkScanSteal;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "SCAN-REMOTE";
        attribute :>> role = "producer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "6708-6727";
        attribute :>> chain = "steal head under lock -> unlock -> scan_complete_heap_chunk";
        attribute :>> closingCut = "exclusive acquired chunk and descendants";
        attribute :>> coverageLimit = "Unlocked hint and actual profile need C access refinement";
    }
    part caller10 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ObjectDispatch;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "SCAN-PAIR";
        attribute :>> role = "producer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "4196-4204";
        attribute :>> chain = "scan_and_advance PAIR -> mark_array -> pending ptr advance";
        attribute :>> closingCut = "parent edge and frontier debt until advance completed";
        attribute :>> coverageLimit = "Fast path is not ordinary scan dispatch";
    }
    part caller11 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.VmRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-RC-LINK";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "703-831;3969-3987";
        attribute :>> chain = "alloc_rc -> register_rc; release_rc removes; set_data_rc writes; mark_rc scans data";
        attribute :>> closingCut = "admit every owner chain and exclude mutation during scan";
        attribute :>> coverageLimit = "Nonzero registration versus processor-zero scan remains unresolved";
    }
    part caller12 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.GeneratedForeign;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-RC-CLOSURE";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/os_dyn.c";
        attribute :>> sourceLines = "748-769";
        attribute :>> chain = "make_c_closure -> alloc_rc -> set_data_rc(proc)";
        attribute :>> closingCut = "RC payload root protection and owner-bound callback";
        attribute :>> coverageLimit = "Architecture-specific trampoline; global c_closure_self has TLS TODO";
    }
    part caller13 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.GeneratedForeign;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-RC-TCL";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/examples/tcltk/tcltk.scm";
        attribute :>> sourceLines = "292-341";
        attribute :>> chain = "tcltk-define-procedure -> vector write -> set_data_rc -> Tcl_CreateCommand";
        attribute :>> closingCut = "callback/delete lifetime and creation-failure custody";
        attribute :>> coverageLimit = "Tcl callback concurrency and failure ownership remain admitted-service obligations";
    }
    part caller14 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.GeneratedForeign;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-MARKER";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/c_intf.c";
        attribute :>> sourceLines = "6509-6567";
        attribute :>> chain = "make_sfun_stack_marker -> make_vector -> marker slots; kill marker clears";
        attribute :>> closingCut = "protect proc before allocation and preserve nested callback owner";
        attribute :>> coverageLimit = "Source TODO explicitly warns proc_or_false may have been collected";
    }
    part caller15 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ProcessorRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-SAVED-KERNEL";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_kernel.scm";
        attribute :>> sourceLines = "2433;2626;2660;2694;2728;2762;2795;2828;3073;3577;4964";
        attribute :>> chain = "11 GC_SAVE1 sites in vector/closure/frame/structure constructors";
        attribute :>> closingCut = "saved slots stable through allocation then restore and clear";
        attribute :>> coverageLimit = "Generated C mirrors Scheme; inline native extensions remain open";
    }
    part caller16 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ProcessorRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-SAVED-NUM";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_num.scm";
        attribute :>> sourceLines = "7889-7906;7965-7970";
        attribute :>> chain = "bignum.make -> direct saved[0..2] writes -> reload/clear";
        attribute :>> closingCut = "every direct writer joins root cut";
        attribute :>> coverageLimit = "not interrupts-enabled alone is not a worker scan grant";
    }
    part caller17 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ProcessorRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-CACHE";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceLines = "5068-5084;5148;5237;5351;5809";
        attribute :>> chain = "cache-fill macros at 3 input and 1 output call sites -> PSTATE type_cache";
        attribute :>> closingCut = "owner-bound cache writes excluded from scan cut";
        attribute :>> coverageLimit = "Macro-expanded/generated call closure and all profiles remain open";
    }
    part caller18 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CurrentFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-SPILL";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_kernel.scm";
        attribute :>> sourceLines = "1428-1446";
        attribute :>> chain = "sync-op-interrupt -> FRAME_STORE_RA/W_ALL -> service_sync_op -> R_ALL";
        attribute :>> closingCut = "final registers/frame pointer published before root scan; reload after";
        attribute :>> coverageLimit = "Compiler-specific local register and frame descriptors still need proof";
    }
    part caller19 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.GlobalRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-GLOBAL";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/include/gambit.h.in";
        attribute :>> sourceLines = "5953-5958;6756-6777";
        attribute :>> chain = "GLOBALVARSET and SET_GLO -> global cell; GSC GLOBALVARSET emission";
        attribute :>> closingCut = "SINGLE_VM/global-list and multi-VM partition census";
        attribute :>> coverageLimit = "Header writer interface; full generated-module census is not established";
    }
    part caller20 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.VmRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-SYMKEY";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "1899-1915;1930-1985";
        attribute :>> chain = "intern_symkey -> bucket/next rewrites -> symkey_table_set";
        attribute :>> closingCut = "GSTATE-shared root table publication and reader lifetime";
        attribute :>> coverageLimit = "Cross-VM GSTATE sharing cannot be assumed VM-local";
    }
    part caller21 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CurrentFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.controlOrigin;
        attribute :>> callerId = "ROOT-CONTROL";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_kernel.scm";
        attribute :>> sourceLines = "3154-3162;3439-3464;3512";
        attribute :>> chain = "continuation frame/denv setters and frame-set!/continuation-set!";
        attribute :>> closingCut = "all saved/current/captured origins and writer exclusion";
        attribute :>> coverageLimit = "Exported primitives allow future callers beyond selected source";
    }
    part caller22 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CurrentFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.controlOrigin;
        attribute :>> callerId = "ROOT-DESERIALIZE";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_system.scm";
        attribute :>> sourceLines = "4138-4153;4211-4230";
        attribute :>> chain = "deserialize -> continuation setters and live frame-slot setters";
        attribute :>> closingCut = "construction roots protected until publication and scan admission";
        attribute :>> coverageLimit = "Serialized bytes are not a stable native root descriptor";
    }
    part caller23 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CurrentFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.controlOrigin;
        attribute :>> callerId = "ROOT-IMPLODE";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceLines = "11706-11724";
        attribute :>> chain = "implode-frame -> make-frame -> frame-set! loop";
        attribute :>> closingCut = "frame initialization and completion endpoint";
        attribute :>> coverageLimit = "Further reflective callers require source/ABI admission";
    }
    part caller24 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CurrentFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-RELOCATE";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3583-3597;3813;3957-3985";
        attribute :>> chain = "mark_array writes actual root cells; frame and RC scans call it";
        attribute :>> closingCut = "scanner is an admitted writer; root owners reload updated values";
        attribute :>> coverageLimit = "Initial root freeze does not authorize independent mutator writes";
    }
    part caller25 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ProcessorRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-PSTATE-INIT";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/setup.c";
        attribute :>> sourceLines = "4704-4727";
        attribute :>> chain = "setup_pstate -> initialize r/saved/type_cache";
        attribute :>> closingCut = "initialize before context/member publication";
        attribute :>> coverageLimit = "Resize failure and native thread start still need receipts";
    }
    part caller26 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.VmRoots;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-VM-PROC";
        attribute :>> role = "root-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/setup.c";
        attribute :>> sourceLines = "421-466;4714;4811";
        attribute :>> chain = "setup processor and VM Scheme objects -> object field initialization";
        attribute :>> closingCut = "publish initialized VM/processor fields before membership";
        attribute :>> coverageLimit = "Scheduler Scheme field mutations and native embedding remain open";
    }
    part caller27 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ForeignWrapper;
        ref part :>> formal = GambitRuntimeModelRelations::relations.retirementWindow;
        attribute :>> callerId = "RELEASE-OPEN";
        attribute :>> role = "extension-boundary";
        attribute :>> sourcePath = "vendor/gambit/lib/c_intf.c";
        attribute :>> sourceLines = "1683-1707";
        attribute :>> chain = "release_foreign clears fields -> release_fn(ptr)";
        attribute :>> closingCut = "native resource/root custodian before wrapper retirement";
        attribute :>> coverageLimit = "Arbitrary callback effect/reentry not admitted by tracing grant";
    }
    part caller28 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ChunkScanSteal;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "COUNT-RESET";
        attribute :>> role = "phase-control";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "3408-3461;6789-6796";
        attribute :>> chain = "GC setup -> setup_stack_heap_vmstate -> both counts=processor_count";
        attribute :>> closingCut = "old scope fully drained before resetting queue/team state";
        attribute :>> coverageLimit = "Reference target separates census from team size";
    }
    part caller29 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.ChunkScanSteal;
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> callerId = "COUNT-CLOSE";
        attribute :>> role = "phase-control";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> sourceLines = "6737-6770";
        attribute :>> chain = "mark_reachable idle decrement -> zero/broadcast or wait/reincrement";
        attribute :>> closingCut = "complete producer lifetime and all unfinished work before terminal cut";
        attribute :>> coverageLimit = "Current two-lock structure alone neither proves a bug nor admits new async publishers";
    }
    part caller30 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.CurrentFrames;
        ref part :>> formal = GambitRuntimeModelRelations::relations.controlOrigin;
        attribute :>> callerId = "ROOT-DENV";
        attribute :>> role = "root-graph-writer";
        attribute :>> sourcePath = "vendor/gambit/lib/_thread.scm";
        attribute :>> sourceLines = "345-370";
        attribute :>> chain = "parameter lookup promotes denv cache entries through thread field setters";
        attribute :>> closingCut = "exclude or order all relevant dynamic-environment field writers";
        attribute :>> coverageLimit = "Selected live heap/control writer, not a claim that every denv mutation is enumerated";
    }
    part caller31 : CallerSite {
        ref part :>> family = GambitProducerCustody::producerFamilies.GeneratedForeign;
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> callerId = "ROOT-FFI-ENTRY";
        attribute :>> role = "root-writer-entry";
        attribute :>> sourcePath = "vendor/gambit/include/gambit.h.in";
        attribute :>> sourceLines = "10043-10059;10325-10335";
        attribute :>> chain = "generated BEGIN_SFUN variants call make/kill marker; BEGIN_CFUN_CTX spills frame and W_ALL";
        attribute :>> closingCut = "owner-bound entry and protected roots before allocation; acquired cleanup on return";
        attribute :>> coverageLimit = "GSC _ptree2 emits these entry variants; arbitrary inline C and loaded modules remain open";
    }
    part duty0 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "PC-RESERVE";
        attribute :>> lawSymbol = "GambitPublicationClose::ReservationLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Live issuer protects private copy; reserve batch and publisher receipt before observable enqueue";
    }
    part duty1 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "PC-COMMIT";
        attribute :>> lawSymbol = "GambitPublicationClose::PublishCommitLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Phase gate then FIFO lock, initialized batch coverage, same-scope commit and source barrier refinement";
    }
    part duty2 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "PC-ACQUIRE";
        attribute :>> lawSymbol = "GambitPublicationClose::AcquireCustodyLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Atomic queue-to-scanner transfer of unchanged unfinished debt before unlock";
    }
    part duty3 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "PC-SETTLE";
        attribute :>> lawSymbol = "GambitPublicationClose::SettlementLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "All edges and pending cursor advance covered; child acceptance precedes unique parent settlement";
    }
    part duty4 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.retirementWindow;
        attribute :>> dutyId = "PC-UNKNOWN";
        attribute :>> lawSymbol = "GambitPublicationClose::UnknownCustodyLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Pre-enrolled reconciliation custody and stable root/backing lease; receipt debt survives completed scanning";
    }
    part duty5 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "PC-CLOSE";
        attribute :>> lawSymbol = "GambitPublicationClose::CloseCutLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "Complete all-producer projection, coherent same-gate zero snapshot, no publishers or unresolved outcomes";
    }
    part duty6 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "PC-LOCK";
        attribute :>> lawSymbol = "GambitPublicationClose::LockDisciplineLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "MISC before gate before queue; all participating C accesses use qualified synchronization; no unmanaged exit inside locks";
    }
    part duty7 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.rootHandoff;
        attribute :>> dutyId = "PC-WRITERS";
        attribute :>> lawSymbol = "GambitPublicationClose::RootWriterAdmissionLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/c_intf.c";
        attribute :>> openPremise = "Real root-writer and carrier census including RC, callbacks, generated modules, saved/control restoration and GSTATE sharing";
    }
    part duty8 : RefinementDuty {
        ref part :>> formal = GambitRuntimeModelRelations::relations.workClosure;
        attribute :>> dutyId = "PC-ERASE";
        attribute :>> lawSymbol = "GambitPublicationClose::SupportErasureLaw";
        attribute :>> sourcePath = "vendor/gambit/lib/mem.c";
        attribute :>> openPremise = "All synchronous publisher last uses enclosed by counted producer; private preparation safely fuses with commit; no escape or C access gap";
    }
    part def PublicationGraph {
        ref part gate : GateDomain;
        ref part ticket : PublicationTicket;
        ref part close : CloseSnapshot;
        ref part roots : RootWriterClosure;
        ref part unknown : UnknownOutcomeCustody;
        ref part specialization : SynchronousSpecialization;
        ref part rootHandoff : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.rootHandoff;
        ref part controlOrigin : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.controlOrigin;
        ref part retirement : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.retirementWindow;
        ref part workClosure : GambitRuntimeModelRelations::ContractBinding = GambitRuntimeModelRelations::relations.workClosure;
        connection sameGate connect gate to ticket;
        connection coherentClose connect gate to close;
        connection rootCensus connect roots to close;
        connection finalRootValues connect roots to rootHandoff;
        connection savedOrigins connect roots to controlOrigin;
        connection receiptResponsibility connect ticket to unknown;
        connection retainedBacking connect unknown to retirement;
        connection conservedWork connect ticket to workClosure;
        connection allProducerClosure connect close to workClosure;
        connection qualifiedContainment connect specialization to ticket;
        connection equivalentCut connect specialization to gate;
    }
    part formalBridge : PublicationGraph;
    dependency commitNeedsReservation from PublishCommitLaw to ReservationLaw;
    dependency commitNeedsLock from PublishCommitLaw to LockDisciplineLaw;
    dependency commitNeedsWorkScope from PublishCommitLaw to GambitGc::WorkContextDomainLaw;
    dependency acquireNeedsLock from AcquireCustodyLaw to LockDisciplineLaw;
    dependency settleNeedsChildren from SettlementLaw to GambitCollectionCompletion::ParentChildCustodyLaw;
    dependency unknownNeedsPriorLease from UnknownCustodyLaw to GambitCollectionCompletion::LateWorkCustodyLaw;
    dependency closeNeedsEffectiveRevoke from CloseCutLaw to GambitMembershipRevocation::RevocationEffectiveLaw;
    dependency closeNeedsAllCredits from CloseCutLaw to GambitCollectionCompletion::PhaseDrainAdmissionLaw;
    dependency closeNeedsCreditDomain from CloseCutLaw to GambitCollectionCompletion::CreditDomainLaw;
    dependency closeNeedsStableTerminal from CloseCutLaw to GambitCollectionCompletion::PhaseDrainStabilityLaw;
    dependency closeNeedsRootCensus from CloseCutLaw to RootWriterAdmissionLaw;
    dependency rootNeedsSeal from RootWriterAdmissionLaw to GambitMembershipRevocation::RootSealLaw;
    dependency rootNeedsSavedOrigins from RootWriterAdmissionLaw to GambitRuntimeModelRelations::relations::controlOrigin;
    dependency eraseNeedsReservation from SupportErasureLaw to ReservationLaw;
    dependency eraseNeedsCommit from SupportErasureLaw to PublishCommitLaw;
    dependency eraseNeedsLocks from SupportErasureLaw to LockDisciplineLaw;
}
