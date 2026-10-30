/* Modern C target: durable card coverage, optional hint logs, no hidden GC.
 * Scope includes writer/cut and destructive-promotion custody, not a complete collector. */
package GambitGenerationalBarrier {
    private import ScalarValues::*;
    /* Runtime schema candidates. Constraints are requirements, not satisfaction
     * claims; source actions must refine them under the declared WB needs. */
    part def StoreTicket {
        attribute vmId : Integer;
        attribute regionGeneration : Integer;
        attribute currentEpoch : Integer;
        attribute proofEpoch : Integer;
        attribute permitLive : Boolean;
        attribute descriptorLive : Boolean;
        attribute managedPointerField : Boolean;
        attribute heapSource : Boolean;
        attribute oldSource : Boolean;
        attribute youngValue : Boolean;
        attribute cardCovered : Boolean;
        attribute rootMembershipKnown : Boolean;
        attribute rootedIdentityMatched : Boolean;
        attribute elisionClaimed : Boolean;
        attribute committed : Boolean;
        attribute collectionCalled : Boolean;
    }
    requirement def StoreAdmissionLaw {
        subject ticket : StoreTicket;
        require constraint {
            not ticket.collectionCalled and
            (not ticket.elisionClaimed or
             (ticket.proofEpoch == ticket.currentEpoch and ticket.rootedIdentityMatched and
              not (ticket.oldSource and ticket.youngValue))) and
            (not ticket.committed or (ticket.permitLive and ticket.descriptorLive and
             (not ticket.managedPointerField or
              ((not ticket.heapSource or not ticket.oldSource or not ticket.youngValue or ticket.cardCovered) and
               (ticket.heapSource or ticket.rootMembershipKnown)))))
        }
    }
    part def RememberedCut {
        attribute vmEpoch : Integer;
        attribute snapshotEpoch : Integer;
        attribute activeWriters : Integer;
        attribute ingressClosed : Boolean;
        attribute rootCensusKnown : Boolean;
        attribute endpointsKnown : Boolean;
        attribute descriptorPinsLive : Boolean;
        attribute selectedCoverageComplete : Boolean;
        attribute scanAllowed : Boolean;
        attribute scanComplete : Boolean;
        attribute aliasesRewritten : Boolean;
        attribute residualCoverageRearmed : Boolean;
        attribute nextEnumerationComplete : Boolean;
        attribute resetRequested : Boolean;
    }
    requirement def CutAndResetLaw {
        subject cut : RememberedCut;
        require constraint {
            cut.activeWriters >= 0 and
            (not cut.scanAllowed or (cut.ingressClosed and cut.activeWriters == 0 and
             cut.vmEpoch == cut.snapshotEpoch and cut.rootCensusKnown and cut.endpointsKnown and
             cut.descriptorPinsLive and cut.selectedCoverageComplete)) and
            (not cut.resetRequested or (cut.ingressClosed and cut.activeWriters == 0 and
             cut.scanComplete and cut.aliasesRewritten and cut.residualCoverageRearmed and cut.nextEnumerationComplete))
        }
    }
    part def CopyReservation {
        attribute epoch : Integer;
        attribute reservedWords : Integer;
        attribute usedWords : Integer;
        attribute totalWords : Integer;
        attribute physicalCapacityAccepted : Boolean;
        attribute forwardPublished : Boolean;
        attribute initializationOwnerLive : Boolean;
        attribute scanOwnerLive : Boolean;
        attribute payloadReady : Boolean;
        attribute scanComplete : Boolean;
        attribute aliasesRewritten : Boolean;
        attribute usedCreditReturned : Boolean;
        attribute allRequiredObjectsHandled : Boolean;
        attribute quarantine : Boolean;
        attribute resumeRequested : Boolean;
        attribute sourceReleaseRequested : Boolean;
    }
    requirement def PromotionCustodyLaw {
        subject copy : CopyReservation;
        require constraint {
            copy.reservedWords >= 0 and copy.usedWords >= 0 and
            copy.reservedWords + copy.usedWords <= copy.totalWords and
            (not copy.forwardPublished or (copy.physicalCapacityAccepted and copy.usedWords > 0 and not copy.usedCreditReturned and
             (copy.payloadReady or copy.initializationOwnerLive) and (copy.scanComplete or copy.scanOwnerLive))) and
            (not copy.resumeRequested or (not copy.quarantine and
             (not copy.forwardPublished or (copy.payloadReady and copy.scanComplete and copy.aliasesRewritten)))) and
            (not copy.sourceReleaseRequested or (not copy.quarantine and
             copy.allRequiredObjectsHandled and copy.aliasesRewritten and copy.scanComplete and
             (not copy.forwardPublished or copy.payloadReady)))
        }
    }
    part def BarrierPolicy {
        attribute authority : String;
        attribute fastPath : String;
        attribute overflow : String;
        attribute cut : String;
        attribute rootStore : String;
        attribute publication : String;
        attribute promotion : String;
        attribute failure : String;
        attribute elision : String;
        attribute scopeBoundary : String;
    }
    part protocol : BarrierPolicy {
        attribute :>> authority = "Preallocated per-region card table is complete; per-context bounded dirty-card hints accelerate enumeration but are not the only root boundary record";
        attribute :>> fastPath = "Validate source/class and write extent; premark all touched cards before store/CAS; complete finite no-safepoint primitive before acknowledging stop; no allocation, callback or collection inside barrier";
        attribute :>> overflow = "Sticky epoch overflow before unhinted store; keep durable dirty cards; after stop scan allocated card metadata, then dirty object/frame ranges; never overwrite unconsumed hints or clear coverage";
        attribute :>> cut = "Close new writes; settle admitted stores; acquire every context/native writer acknowledgement and local log endpoint; seal same VM/region/generation epoch; exclude reset, unlink and region reuse";
        attribute :>> rootStore = "RC and external root slots use RootRegistry identity and final-value park/reload; native RC headers are not managed-heap cards; scan all admitted root slots";
        attribute :>> publication = "Premark and field store sequenced before writer release acknowledgement; coordinator acquire before card/root scan; collector address rewrite before release completion and acquired rooted reload";
        attribute :>> promotion = "Before first forwarding reserve physical destination, header/alignment, captured-frame expansion, copy/task metadata and worker slack; published forwarding retains initialization and descendant scan owner; root redirection need not imply readable payload";
        attribute :>> failure = "Preflight rejection retains original source, committed stores and dirty state; unpublished local reserve may refund; after any forwarding no whole-epoch rollback or mutator resume until completion; unexpected breach quarantines both spaces and debts";
        attribute :>> elision = "Scheme proves current young source or nonyoung value under point/epoch/region identity; GC, reentry or promotion expires the premise unless revalidated; private mature initialization needs publish-time coverage; concurrent-major barriers remain separate";
        attribute :>> scopeBoundary = "Ordinary C data-race freedom and mixed generated-C semantics need their own proof; weak/will, full reserve bound, full VM/product/source simulation and native performance stay open";
    }
    part history : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "WB-H";
        attribute :>> kind = "interleaving";
        attribute :>> subjectPath = "models/gambit/generational_barrier.qnt";
        attribute :>> subjectScope = "generational_barrier:Test$";
        attribute :>> premise = "Twenty-six finite histories plus sampled positive steps; three slots/two cards/one copy object; no source or liveness proof";
    }
    part induction : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "WB-I";
        attribute :>> kind = "induction";
        attribute :>> subjectPath = "models/gambit/lean/GenerationalBarrier.lean";
        attribute :>> subjectScope = "GambitSMP.GenerationalBarrier:recordPreservesCoverage;commitPreservesCoverage;recordDoesNotCollect;commitDoesNotCollect;markPreservesLogCompleteness;selectedCoversDirty;sourceSlotsCovered;nextEpochSeedComplete;noFinishWithCopyDebt;noRollbackAfterForward;claimPreservesBudget;reclaimRequiresRewrite;validatedElision;amplificationWorkPositive";
        attribute :>> premise = "Parametric card/slot coverage, bounded-log fallback, no-collect target transforms and conditional copy/credit guards; full QNT/C refinement open";
    }
    part writers : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "WB-WRITERS";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/GenerationalBarrier.lean";
        attribute :>> subjectScope = "WB-WRITERS:actual-source-refinement";
        attribute :>> premise = "Continuation heap/stack setters, denv caches/bindings, decoder/bulk/init, generic/CAS and native RootWrite or reject all unknown aliases";
    }
    part logs : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "WB-LOG";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/GenerationalBarrier.lean";
        attribute :>> subjectScope = "WB-LOG:actual-source-refinement";
        attribute :>> premise = "Durable card table, bounded hint writes, sticky overflow and complete object/frame ranges; no allocator/callback/GC in barrier lowering";
    }
    part scanCut : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "WB-SNAPSHOT";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/GenerationalBarrier.lean";
        attribute :>> subjectScope = "WB-SNAPSHOT:actual-source-refinement";
        attribute :>> premise = "Every admitted writer finishes or aborts before final-value acknowledgement; immutable same-epoch card/root/region snapshot, no concurrent reset";
    }
    part promotion : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "WB-PROMOTE";
        attribute :>> kind = "source-refinement";
        attribute :>> subjectPath = "models/gambit/lean/GenerationalBarrier.lean";
        attribute :>> subjectScope = "WB-PROMOTE:actual-source-refinement";
        attribute :>> premise = "Physical no-fail destination/work reservation, alias rewrite, partial-copy/Tail custody and all failure endpoints including unexpected breach";
    }
    part memoryOrder : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "WB-MEMORY";
        attribute :>> kind = "native-memory-order";
        attribute :>> subjectPath = "vendor/gambit/lib/mem.c";
        attribute :>> subjectScope = "WB-MEMORY:actual-source-refinement";
        attribute :>> premise = "Atomic card updates, final stores/acks, scan/reset and forwarding readiness happens-before; source plain/atomic access and native lock/progress complete";
    }
    part dependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitGenerationalAdmission::source;
        ref part :>> prerequisite = history;
    }
    part dependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitGenerationalAdmission::source;
        ref part :>> prerequisite = induction;
    }
    part dependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitGenerationalAdmission::source;
        ref part :>> prerequisite = writers;
    }
    part dependency3 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitGenerationalAdmission::source;
        ref part :>> prerequisite = logs;
    }
    part dependency4 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitGenerationalAdmission::source;
        ref part :>> prerequisite = scanCut;
    }
    part dependency5 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitGenerationalAdmission::source;
        ref part :>> prerequisite = promotion;
    }
    part dependency6 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitGenerationalAdmission::source;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency7 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = writers;
        ref part :>> prerequisite = history;
    }
    part dependency8 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = writers;
        ref part :>> prerequisite = induction;
    }
    part dependency9 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = writers;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency10 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = logs;
        ref part :>> prerequisite = history;
    }
    part dependency11 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = logs;
        ref part :>> prerequisite = induction;
    }
    part dependency12 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = logs;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency13 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scanCut;
        ref part :>> prerequisite = history;
    }
    part dependency14 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scanCut;
        ref part :>> prerequisite = induction;
    }
    part dependency15 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scanCut;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency16 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = promotion;
        ref part :>> prerequisite = history;
    }
    part dependency17 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = promotion;
        ref part :>> prerequisite = induction;
    }
    part dependency18 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = promotion;
        ref part :>> prerequisite = memoryOrder;
    }
    part dependency19 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = memoryOrder;
        ref part :>> prerequisite = GambitRuntimeAssurance::work.platform;
    }
    part dependency20 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = memoryOrder;
        ref part :>> prerequisite = GambitRcFreezePublication::memoryOrder;
    }
    part dependency21 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = writers;
        ref part :>> prerequisite = GambitRuntimeAssurance::control.source;
    }
    part dependency22 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = writers;
        ref part :>> prerequisite = GambitRcFreezePublication::census;
    }
    part dependency23 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = logs;
        ref part :>> prerequisite = writers;
    }
    part dependency24 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scanCut;
        ref part :>> prerequisite = logs;
    }
    part dependency25 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scanCut;
        ref part :>> prerequisite = GambitRcFreezePublication::freeze;
    }
    part dependency26 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = scanCut;
        ref part :>> prerequisite = GambitRetainedRcScan::membership;
    }
    part dependency27 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = promotion;
        ref part :>> prerequisite = scanCut;
    }
    part dependency28 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = promotion;
        ref part :>> prerequisite = GambitRuntimeAssurance::work.source;
    }
    part def WriterRoute {
        attribute writerId : String;
        attribute sourceAnchors : String;
        attribute actualChain : String;
        attribute storeClass : String;
        attribute boundary : String;
    }
    part writer0 : WriterRoute {
        attribute :>> writerId = "FRAME";
        attribute :>> sourceAnchors = "_kernel.scm:3439-3558; _io.scm:11706-11727";
        attribute :>> actualChain = "reader frame dispatch -> implode-frame -> make-frame -> frame-set; continuation-set has heap and stack branches";
        attribute :>> storeClass = "Mature heap slot: MutateStore/range card; active stack slot: root/frame write permit";
        attribute :>> boundary = "Interrupt masking is not no-GC proof; frame-link structural edits require FrameSpec validity";
    }
    part writer1 : WriterRoute {
        attribute :>> writerId = "SHELL";
        attribute :>> sourceAnchors = "_kernel.scm:3154-3162,3595-3727; gambit.h.in:5908-5931; _t-c-2.scm:4263-4273";
        attribute :>> actualChain = "frame/denv setters; make/copy shell and continuation-next cursor update";
        attribute :>> storeClass = "InitStore before safe publication or ordinary mature MutateStore; preserve shared aliases";
        attribute :>> boundary = "Shallow shell copy does not duplicate reachable mutable Scheme state";
    }
    part writer2 : WriterRoute {
        attribute :>> writerId = "SMP-DENV";
        attribute :>> sourceAnchors = "_thread.scm:340-565; _thread#.scm:735-886; _gambit#.scm:638-643";
        attribute :>> actualChain = "dynamic-ref cache2/cache3/miss -> cache writes; dynamic-set -> pair cdr/default/cache; dynamic-let -> persistent env construction";
        attribute :>> storeClass = "Thread/denv/vector/pair managed stores; proven private young init may elide";
        attribute :>> boundary = "SMP env-insert! is reader-commented; cache1 hit alone is not the whole lookup path";
    }
    part writer3 : WriterRoute {
        attribute :>> writerId = "OTHER-DENV";
        attribute :>> sourceAnchors = "_thread.scm:9-44,5351-5368,5654-5874; _thread#.scm:2990-3039";
        attribute :>> actualChain = "Conditional non-SMP dynamic lookup/set/let and active destructive env insertion";
        attribute :>> storeClass = "Profile-specific generic field/pair/card writes";
        attribute :>> boundary = "Source branch inventory only; configured/loaded selection not executed";
    }
    part writer4 : WriterRoute {
        attribute :>> writerId = "CONTROL";
        attribute :>> sourceAnchors = "_kernel.scm:1354-1378,1115-1346; gambit.h.in:6314-6330,6377-6387,6654-6665,6716-6736";
        attribute :>> actualChain = "dynamic-env-bind install/restore; scheduler save/restore; graft/return denv and cache assignments";
        attribute :>> storeClass = "Managed thread/shell stores plus exact active-root handoff; collector/control relocation authority distinct";
        attribute :>> boundary = "Current thread being active does not imply its managed object is young; nonlocal exits need winding cleanup";
    }
    part writer5 : WriterRoute {
        attribute :>> writerId = "DECODE";
        attribute :>> sourceAnchors = "_io.scm:11756-11824,12726-12845,12883-12908,13729-13798";
        attribute :>> actualChain = "reader deserialization and delayed closure/list/vector fixups -> real setters";
        attribute :>> storeClass = "BulkWrite/MutateStore after rooted valid initialization; all touched card and pointer-slot ranges";
        attribute :>> boundary = "General cyclic/forward frame repair is not established; do not invent a frame fixup callback";
    }
    part writer6 : WriterRoute {
        attribute :>> writerId = "GENERIC";
        attribute :>> sourceAnchors = "gambit.h.in:5328-5329,5482-5485,6764-6771; _t-c-2.scm:3356-3365";
        attribute :>> actualChain = "pair/vector/global writes and vector CAS; inactive SSB reservation hook";
        attribute :>> storeClass = "Premark before store/CAS; failed CAS may leave harmless dirty card; globals are roots";
        attribute :>> boundary = "Successful-CAS-only logging needs separate race proof; unused hook is not an active barrier";
    }
    part writer7 : WriterRoute {
        attribute :>> writerId = "FFI-ROOT";
        attribute :>> sourceAnchors = "mem.c:703-829,3969-3986; os_dyn.c:744-795; examples/tcltk/tcltk.scm:125-195,288-342";
        attribute :>> actualChain = "RC allocation/register/data write; dynamic C closure and Tcl ClientData producers/readers/delete";
        attribute :>> storeClass = "RootRegistry RootWrite and final-value freeze; C writes into managed payload require validated owner/range barrier";
        attribute :>> boundary = "Raw RC data is not a heap card; unknown native aliases/threads cannot be repaired just by scanning cards";
    }
    part writer8 : WriterRoute {
        attribute :>> writerId = "FFI-ENTRY";
        attribute :>> sourceAnchors = "c_intf.c:6511-6562; setup.c:3275-3422; gambit.h.in:10040-10138,10325-10480";
        attribute :>> actualChain = "SFUN and run marker allocation; CFUN conversions/writeback/reentry and cleanup";
        attribute :>> storeClass = "Protected handles before declared allocating points; barrier primitive cannot call back; reacquire/reload after GC";
        attribute :>> boundary = "Existing cumulative patch protects some paths; full generated/embedded C and nonlocal exit closure remains open";
    }
    part writer9 : WriterRoute {
        attribute :>> writerId = "COLLECTOR";
        attribute :>> sourceAnchors = "mem.c:3490-3665,3667-3966,4210-4245";
        attribute :>> actualChain = "forwarding CAS before payload copy; captured-stack expansion; chunk publication and tail scan";
        attribute :>> storeClass = "Collector-exclusive relocation and explicit initialization/scan custody, not a recursive mutator barrier";
        attribute :>> boundary = "Root redirection may precede copy completion; payload consumption and phase completion may not";
    }
    part def Amplification {
        attribute capability : String;
        attribute mechanism : String;
        attribute removedWork : String;
        attribute addedWork : String;
        attribute condition : String;
        attribute falsifier : String;
    }
    part benefit0 : Amplification {
        attribute :>> capability = "Scheme semantic leverage";
        attribute :>> mechanism = "Generator carries source-age/value/escape and checkpoint evidence into semantic stores";
        attribute :>> removedWork = "E proved-unnecessary generational barrier operations out of W pointer stores";
        attribute :>> addedWork = "Analysis/contract validation and remaining W-E barriers; major barriers separate";
        attribute :>> condition = "Elision receipt valid for actual source/value and publication lifetime";
        attribute :>> falsifier = "Captured alias, callback escape or allocating constructor invalidates young/private premise";
    }
    part benefit1 : Amplification {
        attribute :>> capability = "Reusable multi-shot continuations";
        attribute :>> mechanism = "FrameSpec scan ranges plus all frame/denv writes recorded";
        attribute :>> removedWork = "Repeated scan/copy of unchanged mature captured frames across eligible minor epochs";
        attribute :>> addedWork = "Dirty frame/card ranges, alias rewrites, active roots and activation work";
        attribute :>> condition = "Every setter/decoder/FFI/control writer covered; sharing and eq? identity retained";
        attribute :>> falsifier = "One omitted mature write or structural frame edit invalidates skip";
    }
    part benefit2 : Amplification {
        attribute :>> capability = "Tail-call and high-order execution";
        attribute :>> mechanism = "Semantic call/checkpoint plan separates poll/allocation from noncollecting stores";
        attribute :>> removedWork = "Hidden GC/root-spill path from a barrier; redundant barriers only when proved";
        attribute :>> addedWork = "Explicit poll latency bound, roots at declared safepoints and mandatory stores";
        attribute :>> condition = "Finite barrier region and correct allocation/poll placement; tail-call semantics retained";
        attribute :>> falsifier = "Unbounded no-poll tail loop, callback in barrier, or hidden log allocation";
    }
    part benefit3 : Amplification {
        attribute :>> capability = "C-friendly multicore embedding";
        attribute :>> mechanism = "RootRegistry park/reload plus fixed-size card metadata and no surprise store safepoint";
        attribute :>> removedWork = "Repeated whole-mature scan when complete dirty precision is available";
        attribute :>> addedWork = "Atomic card operations, writer acknowledgements, root scan and rejected raw escapes";
        attribute :>> condition = "All native writers enrolled; DRF/atomic field access and VM binding specified";
        attribute :>> falsifier = "Unmediated C store or copying an unsafe volatile pattern from another runtime";
    }
    part benefit4 : Amplification {
        attribute :>> capability = "Overflow without lost coverage";
        attribute :>> mechanism = "Durable cards plus bounded context hints; sticky overflow selects bitmap walk";
        attribute :>> removedWork = "On normal epochs enumeration of all C card entries; no per-store log growth";
        attribute :>> addedWork = "Hint appends, duplicate filtering, overflow O(C) metadata walk plus dirty-range scan";
        attribute :>> condition = "Every relevant write marks card; snapshot has complete per-context overflow/hints";
        attribute :>> falsifier = "Lost dirty bit, concurrent reset or missing range/region identity";
    }
    part benefit5 : Amplification {
        attribute :>> capability = "Parallel promotion with custody";
        attribute :>> mechanism = "No-fail reserve before forwarding and explicit partial-copy owner";
        attribute :>> removedWork = "Whole-epoch restart/duplicate canonical copying can be avoided under the contract";
        attribute :>> addedWork = "Worst-case destination/task reserve, worker slack and failure retention";
        attribute :>> condition = "Physical reservation bound covers layout expansion, stack capture and all simultaneous claims";
        attribute :>> falsifier = "Reserve covers only likely survivors; premature refund or discarded initialization task";
    }
    part writersRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = writers;
        attribute :>> sourceAnchors = writer0.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460; retained repairs do not implement generational stores or reserve receipts";
        attribute :>> projection = protocol.elision;
        attribute :>> failureCustodian = protocol.failure;
        attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
    }
    part logsRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = logs;
        attribute :>> sourceAnchors = writer6.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460; retained repairs do not implement generational stores or reserve receipts";
        attribute :>> projection = protocol.overflow;
        attribute :>> failureCustodian = protocol.failure;
        attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
    }
    part scanCutRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = scanCut;
        attribute :>> sourceAnchors = writer7.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460; retained repairs do not implement generational stores or reserve receipts";
        attribute :>> projection = protocol.cut;
        attribute :>> failureCustodian = protocol.failure;
        attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
    }
    part promotionRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = promotion;
        attribute :>> sourceAnchors = writer9.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460; retained repairs do not implement generational stores or reserve receipts";
        attribute :>> projection = protocol.promotion;
        attribute :>> failureCustodian = protocol.failure;
        attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
    }
    part memoryOrderRoute : GambitHostRootsRefinement::Route {
        ref part :>> need = memoryOrder;
        attribute :>> sourceAnchors = writer9.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460; retained repairs do not implement generational stores or reserve receipts";
        attribute :>> projection = protocol.publication;
        attribute :>> failureCustodian = protocol.failure;
        attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
    }
    part def ViewNode { attribute nodeId : String; attribute labelText : String; }
    part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
    part semantic : ViewNode { attribute :>> nodeId = "semantic"; attribute :>> labelText = "Scheme semantic StorePlan: proved elision / declared checkpoints"; }
    part writeOp : ViewNode { attribute :>> nodeId = "writeOp"; attribute :>> labelText = "Finite noncollecting store / bulk / CAS"; }
    part cards : ViewNode { attribute :>> nodeId = "cards"; attribute :>> labelText = "Durable per-region dirty cards"; }
    part hints : ViewNode { attribute :>> nodeId = "hints"; attribute :>> labelText = "Bounded local hints + sticky overflow"; }
    part cut : ViewNode { attribute :>> nodeId = "cut"; attribute :>> labelText = "Same-epoch cut: all writers settled / roots parked"; }
    part capacity : ViewNode { attribute :>> nodeId = "capacity"; attribute :>> labelText = "Physical destination + copy-work reserve"; }
    part pendingCopy : ViewNode { attribute :>> nodeId = "pendingCopy"; attribute :>> labelText = "Forwarding visible: copy initialization still owned"; }
    part readyCopy : ViewNode { attribute :>> nodeId = "readyCopy"; attribute :>> labelText = "Ready payload + descendant scan + alias rewrite"; }
    part complete : ViewNode { attribute :>> nodeId = "complete"; attribute :>> labelText = "Epoch completion / dirty reset / source reclaim"; }
    part retry : ViewNode { attribute :>> nodeId = "retry"; attribute :>> labelText = "Pre-forward failure: retain original stores and dirty state"; }
    part quarantine : ViewNode { attribute :>> nodeId = "quarantine"; attribute :>> labelText = "Post-forward unexpected failure: retain both spaces / debts"; }
    part edge0 : ViewEdge { ref part :>> producer = semantic; ref part :>> consumer = writeOp; attribute :>> labelText = "generated semantic contract"; }
    part edge1 : ViewEdge { ref part :>> producer = writeOp; ref part :>> consumer = cards; attribute :>> labelText = "premark before heap write"; }
    part edge2 : ViewEdge { ref part :>> producer = writeOp; ref part :>> consumer = hints; attribute :>> labelText = "optional acceleration"; }
    part edge3 : ViewEdge { ref part :>> producer = cards; ref part :>> consumer = cut; attribute :>> labelText = "overflow: enumerate dirty-card metadata"; }
    part edge4 : ViewEdge { ref part :>> producer = hints; ref part :>> consumer = cut; attribute :>> labelText = "normal: deduplicate hinted cards"; }
    part edge5 : ViewEdge { ref part :>> producer = cut; ref part :>> consumer = capacity; attribute :>> labelText = "no unfinished mutator store"; }
    part edge6 : ViewEdge { ref part :>> producer = capacity; ref part :>> consumer = pendingCopy; attribute :>> labelText = "all required capacity reserved"; }
    part edge7 : ViewEdge { ref part :>> producer = capacity; ref part :>> consumer = retry; attribute :>> labelText = "reject before any forwarding"; }
    part edge8 : ViewEdge { ref part :>> producer = pendingCopy; ref part :>> consumer = readyCopy; attribute :>> labelText = "initialize before payload read"; }
    part edge9 : ViewEdge { ref part :>> producer = pendingCopy; ref part :>> consumer = quarantine; attribute :>> labelText = "no rollback or mutator resume"; }
    part edge10 : ViewEdge { ref part :>> producer = readyCopy; ref part :>> consumer = complete; attribute :>> labelText = "all root/field aliases updated"; }
    part edge11 : ViewEdge { ref part :>> producer = complete; ref part :>> consumer = writeOp; attribute :>> labelText = "next epoch"; }
    part edge12 : ViewEdge { ref part :>> producer = retry; ref part :>> consumer = writeOp; attribute :>> labelText = "safe checkpoint retry / error"; }
}
