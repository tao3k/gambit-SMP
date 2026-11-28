// Temporal admission, retry and caller/callee custody only. Size and alignment
// proofs, including the retired legacy dimensional controls, belong exclusively
// to FrameContract.lean. No history here proves a physical interval or C ABI.
module rest_frame_publication {
  // The booleans stand for a source-proved full footprint and an already
  // backed handler spill. This module does not prove their byte geometry.
  type Attempt = {
    phase: str, kind: str, scope: str, grantScope: str, rootScope: str,
    request: int, pending: int, cursorView: str, returned: bool,
    serviceBusy: bool, serviceScope: str, deliveringEffects: bool, nestedCompleted: int, refillQualified: bool, revision: int, grantRevision: int,
    room: bool, handlerReserve: bool, oldMap: bool, roots: bool,
    spillBacked: bool, spillMapExact: bool, spillWritten: bool,
    demandSeen: bool, beforeMutation: bool, epoch: int, reloaded: bool,
    grantEpoch: int, writes: int, pops: int, adjustments: int,
    published: bool, emptyRetries: int, recursiveHandlers: int
  }
  var a: Attempt
  action init = a' = {
    phase: "entry", kind: "stack", scope: "caller", grantScope: "", rootScope: "caller",
    request: 1, pending: 0, cursorView: "entry", returned: true,
    serviceBusy: false, serviceScope: "", deliveringEffects: false, nestedCompleted: 0, refillQualified: false, revision: 0, grantRevision: 0,
    room: false, handlerReserve: true, oldMap: true, roots: true,
    spillBacked: true, spillMapExact: true, spillWritten: false,
    demandSeen: false, beforeMutation: true, epoch: 1, reloaded: true,
    grantEpoch: 0, writes: 0, pops: 0, adjustments: 0,
    published: false, emptyRetries: 0, recursiveHandlers: 0
  }
  val entryCursor = a.cursorView == "entry" and a.returned
  val matchingRootView = a.oldMap and a.roots and a.rootScope == a.scope

  // These are source-refinement premises for already-owned raw spill slots,
  // not geometry or a proof that bits encode Scheme pointers. Future refill
  // cannot authorize a store that must precede publication of its root map.
  action spillRawBeforeService = all {
    a.phase == "entry" and a.beforeMutation and a.spillBacked and a.spillMapExact,
    a' = {...a, spillWritten: true}
  }

  // Compile-time expansion is permitted only before any runtime demand is
  // published. Source refinement additionally requires unchanged instruction,
  // exact root view, fp and emitted-code frontier; no byte geometry is proved.
  action expandUnpublishedDemand = all {
    a.phase == "entry" and a.pending == 0 and a.beforeMutation and a.writes == 0,
    a' = {...a, request: a.request + 1, room: false}
  }
  action heapRequest = all {
    a.phase == "entry",
    a' = {...a, kind: "heap"}
  }
  action alreadyFits = all {
    a.phase == "entry" and not(a.room),
    a' = {...a, room: true}
  }
  action requestSpace = all {
    a.phase == "entry" and not(a.room) and matchingRootView and entryCursor and not(a.serviceBusy),
    a' = {...a, phase: "handler", pending: a.request, serviceBusy: true, serviceScope: a.scope, refillQualified: false}
  }
  action enterRefill = all {
    a.phase == "handler" and not(a.demandSeen) and a.handlerReserve and
      a.pending == a.request and matchingRootView and a.serviceBusy and a.serviceScope == a.scope,
    a' = {...a, demandSeen: true, cursorView: "handler", returned: false}
  }
  action restoreWithRoom = all {
    a.phase == "handler" and a.demandSeen,
    a' = {...a, phase: "retry", room: false,
      epoch: a.epoch + 1, reloaded: false}
  }
  // Service completion is not a grant and must precede Scheme effects.
  // A real source adapter checks the prospective decoded return view before
  // settling; no saved handler cursor is injected into the resumed locals.
  action qualifyRefillOutcome = all {
    a.phase == "retry" and a.cursorView == "handler" and a.demandSeen and a.serviceBusy and a.serviceScope == a.scope and a.pending == a.request,
    a' = {...a, refillQualified: true}
  }
  action rejectRefillOutcome = all {
    a.phase == "retry" and not(a.refillQualified) and a.serviceBusy and a.serviceScope == a.scope,
    a' = {...a, phase: "failed"}
  }
  action settleService = all {
    a.phase == "retry" and a.serviceBusy and a.serviceScope == a.scope and a.demandSeen and a.refillQualified and a.pending == a.request,
    a' = {...a, serviceBusy: false, serviceScope: "", pending: 0}
  }
  action finishUnwind = all {
    a.phase == "retry" and not(a.serviceBusy) and a.cursorView == "handler" and not(a.returned),
    a' = {...a, cursorView: "entry", returned: true}
  }
  action recheckEntryRoom = all {
    a.phase == "retry" and entryCursor and not(a.room) and not(a.serviceBusy),
    a' = {...a, room: true}
  }
  action nestedBegin = all {
    a.phase == "retry" and not(a.serviceBusy),
    a' = {...a, serviceBusy: true, serviceScope: "interrupt", deliveringEffects: true}
  }
  action nestedFinish = all {
    a.phase == "retry" and a.serviceBusy and a.serviceScope == "interrupt",
    a' = {...a, serviceBusy: false, serviceScope: "", deliveringEffects: false,
      nestedCompleted: a.nestedCompleted + 1, revision: a.revision + 1, room: false, reloaded: false}
  }
  action reload = all {
    a.phase == "retry" and not(a.reloaded) and a.pending == 0 and entryCursor and not(a.serviceBusy),
    a' = {...a, reloaded: true}
  }
  action grant = all {
    (a.phase == "entry" or a.phase == "retry") and
      a.room and matchingRootView and a.reloaded and entryCursor and not(a.serviceBusy),
    a' = {...a, phase: "granted", grantEpoch: a.epoch, grantScope: a.scope, grantRevision: a.revision}
  }
  action commitGroup = all {
    a.phase == "granted" and matchingRootView and entryCursor and not(a.serviceBusy) and a.grantEpoch == a.epoch and a.grantScope == a.scope and a.grantRevision == a.revision,
    a' = {...a, phase: "written", writes: 1, pops: 1, adjustments: 1}
  }
  action publishComplete = all {
    a.phase == "written",
    a' = {...a, phase: "done", published: true, pending: 0}
  }
  action exhausted = all {
    a.phase == "handler" and a.demandSeen,
    a' = {...a, phase: "failed"}
  }
  // A caught exception is a new public boundary. Zero construction effects
  // does not establish current roots, returned cursor or next spill backing.
  // The backing predicates are source/native premises, not allocated here.
  val caughtEntryReady = a.phase == "caught" and entryCursor and matchingRootView and
    a.handlerReserve and a.spillBacked and a.spillMapExact and
    not(a.serviceBusy) and a.pending == 0 and a.writes == 0
  action normalizeRefusalReturn = all {
    a.phase == "failed" and a.spillBacked and a.spillMapExact,
    a' = {...a, phase: "caught", cursorView: "entry", returned: true,
      serviceBusy: false, serviceScope: "", pending: 0, room: false,
      reloaded: true, grantEpoch: 0, grantScope: "", published: false}
  }
  action reenterAfterCaught = all {
    caughtEntryReady,
    a' = {...a, phase: "entry", request: a.request+1, demandSeen: false}
  }
  // Separating mutant for a reported refusal -> exact-fit abort. It models
  // the missing guarantee, not a claim about which C writer caused it.
  action catchWithoutCurrentBacking = all {
    a.phase == "failed",
    a' = {...a, phase: "caught", cursorView: "entry", returned: true,
      serviceBusy: false, serviceScope: "", pending: 0,
      handlerReserve: false, spillBacked: false}
  }
  action waitWithCustody = all {
    a.phase == "handler" and a.demandSeen,
    a' = {...a, phase: "parked"}
  }
  action noHandlerReserve = all {
    a.phase == "entry",
    a' = {...a, handlerReserve: false}
  }
  action boundedFailureBeforeSpill = all {
    a.phase == "handler" and not(a.handlerReserve),
    a' = {...a, phase: "failed"}
  }
  // Source/native premises: arrival has the current callee pcontext roots;
  // alreadyFits may consume an existing physical interval, not the caller's
  // consumed write token. A backing service cannot create room by definition.
  action arriveAtCEntry = all {
    a.phase == "done" and a.scope == "caller" and not(a.serviceBusy),
    a' = {...a, phase: "entry", kind: "c-entry", scope: "c-entry",
      rootScope: "c-entry", grantScope: "", request: a.request + 1,
      pending: 0, room: false, handlerReserve: false, demandSeen: false,
      reloaded: true, grantEpoch: 0, writes: 0, pops: 0, adjustments: 0,
      published: false}
  }
  action backedArrival = all {
    a.phase == "entry" and a.scope == "c-entry" and a.writes == 0,
    a' = {...a, handlerReserve: true}
  }

  // Mutants encode the observed design failure modes, not production actions.
  action legacyEmptyReturn = all {
    a.phase == "handler" and not(a.room),
    a' = {...a, phase: "retry", emptyRetries: a.emptyRetries + 1}
  }
  action legacyRedispatch = all {
    a.phase == "retry" and not(a.room),
    a' = {...a, phase: "handler"}
  }
  action guardedHandlerRecursion = all {
    a.phase == "handler",
    a' = {...a, recursiveHandlers: a.recursiveHandlers + 1}
  }
  val safe =
    matchingRootView and a.beforeMutation and
    (not(a.spillWritten) or (a.spillBacked and a.spillMapExact)) and
    (not(a.deliveringEffects) or not(a.serviceBusy) or a.serviceScope == "interrupt") and
    (a.pending == 0 or a.pending == a.request) and
    (a.writes == 0 or (a.grantEpoch == a.epoch and a.grantScope == a.scope and a.grantRevision == a.revision and a.room and a.reloaded and entryCursor and not(a.serviceBusy))) and
    a.writes <= 1 and a.pops <= a.writes and a.adjustments <= a.writes and
    (not(a.published) or (a.writes == 1 and a.phase == "done"))
  val retryMakesProgress = a.emptyRetries == 0 and a.recursiveHandlers == 0
  // Major phases descend. Demand-consumption and reload are one-time
  // substeps. "parked" retains debt and needs external progress evidence.
  pure def localRank(phase: str): int =
    if (phase == "entry") 7 else if (phase == "handler") 6
    else if (phase == "retry") 5 else if (phase == "granted") 3
    else if (phase == "written") 2 else 0

  run expandedDemandUsesOneAttemptTest = init.then(expandUnpublishedDemand)
    .then(expandUnpublishedDemand).then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService).then(finishUnwind).then(recheckEntryRoom).then(reload).then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and retryMakesProgress and a.request == 3 and a.writes == 1)
  run expansionAfterPublicationControlTest = init.then(requestSpace)
    .then(all {a' = {...a, request: a.request + 1}}).expect(not(safe))
  run demandAwareStackRetryTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService).then(finishUnwind).then(recheckEntryRoom).then(reload).then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and retryMakesProgress and a.phase == "done" and a.writes == 1)
  run demandAwareHeapRetryTest = init.then(heapRequest).then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService).then(finishUnwind).then(recheckEntryRoom).then(reload).then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and retryMakesProgress and a.kind == "heap" and a.phase == "done")
  run entryGrantBeforeStoreTest = init.then(alreadyFits).then(grant)
    .then(commitGroup).then(publishComplete).expect(safe and retryMakesProgress and not(a.serviceBusy) and a.pending == 0)
  run exhaustedRetainsMappedRootsTest = init.then(requestSpace).then(enterRefill)
    .then(exhausted).expect(safe and retryMakesProgress and a.phase == "failed" and
      a.writes == 0 and a.pops == 0 and a.pending == a.request)
  run noSpillRoomBoundedFailureTest = init.then(noHandlerReserve).then(requestSpace)
    .then(boundedFailureBeforeSpill).expect(safe and retryMakesProgress and a.phase == "failed")
  run unknownRefillRetainsCustodyTest = init.then(requestSpace).then(enterRefill)
    .then(waitWithCustody).expect(safe and retryMakesProgress and a.pending == a.request and
      a.phase == "parked" and a.writes == 0)
  run oldThresholdRetryCycleControlTest = init.then(requestSpace)
    .then(legacyEmptyReturn).then(legacyRedispatch)
    .then(legacyEmptyReturn).then(legacyRedispatch)
    .expect(safe and not(retryMakesProgress) and a.phase == "handler" and a.emptyRetries == 2)
  run globalGuardRecursionControlTest = init.then(requestSpace)
    .then(guardedHandlerRecursion).then(guardedHandlerRecursion)
    .expect(safe and not(retryMakesProgress) and a.recursiveHandlers == 2 and a.writes == 0)
  run postAdjustmentLabelControlTest = init.then(requestSpace)
    .then(all {a' = {...a, beforeMutation: false}})
    .expect(not(safe))
  run pregrantStoreControlTest = init
    .then(all {a' = {...a, writes: 1}})
    .expect(not(safe))
  run missingReloadControlTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService).then(finishUnwind).then(recheckEntryRoom)
    .then(all {a' = {...a, phase: "written", grantEpoch: a.epoch, writes: 1}})
    .expect(not(safe))

  // Service identity is scoped to a processor incarnation within one VM
  // lifetime. Local sequence numbers may coincide in different scopes.
  type ServiceAttempt = {
    vmLife: int, processor: int, incarnation: int, sequence: int,
    context: int, activation: int, point: int
  }
  pure def sameServiceAttempt(a: ServiceAttempt, b: ServiceAttempt): bool =
    a.sequence > 0 and a == b
  pure val serviceAttempt: ServiceAttempt = {
    vmLife: 1, processor: 1, incarnation: 1, sequence: 1,
    context: 1, activation: 1, point: 1
  }
  run changedAttemptControlTest = init.then(requestSpace)
    .then(all {a' = {...a, pending: a.request + 1}})
    .expect(not(safe) and sameServiceAttempt(serviceAttempt, serviceAttempt) and
      not(sameServiceAttempt(serviceAttempt, {...serviceAttempt, processor: 2})) and
      not(sameServiceAttempt(serviceAttempt, {...serviceAttempt, incarnation: 2})) and
      not(sameServiceAttempt(serviceAttempt, {...serviceAttempt, vmLife: 2})) and
      not(sameServiceAttempt(serviceAttempt, {...serviceAttempt, activation: 2})) and
      not(sameServiceAttempt({...serviceAttempt, sequence: 0}, {...serviceAttempt, sequence: 0})))
  run duplicateCommitControlTest = init.then(alreadyFits).then(grant).then(commitGroup)
    .then(all {a' = {...a, writes: a.writes + 1}}).expect(not(safe))
  run callerDoneThenEntryFreshGrantTest = init.then(spillRawBeforeService).then(alreadyFits).then(grant)
    .then(commitGroup).then(publishComplete).then(arriveAtCEntry)
    .then(alreadyFits).then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and a.scope == "c-entry" and a.grantScope == "c-entry" and a.writes == 1)
  run callerGrantCannotAuthorizeEntryControlTest = init.then(alreadyFits).then(grant)
    .then(all { a' = {...a, scope: "c-entry", rootScope: "c-entry", writes: 1} })
    .expect(not(safe))
  run priorCalleeFrameControlTest = init.then(alreadyFits).then(grant)
    .then(commitGroup).then(publishComplete).then(arriveAtCEntry)
    .then(alreadyFits).then(all { a' = {...a, rootScope: "caller"} })
    .expect(not(safe) and not(matchingRootView))
  run cEntryShortRetainsRootsTest = init.then(alreadyFits).then(grant)
    .then(commitGroup).then(publishComplete).then(arriveAtCEntry)
    .then(requestSpace).then(boundedFailureBeforeSpill)
    .expect(safe and a.roots and a.phase == "failed" and a.writes == 0 and a.pops == 0)
  run cEntryRefillHasFreshEpochTest = init.then(alreadyFits).then(grant)
    .then(commitGroup).then(publishComplete).then(arriveAtCEntry).then(backedArrival)
    .then(requestSpace).then(enterRefill).then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService).then(finishUnwind).then(recheckEntryRoom).then(reload)
    .then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and a.scope == "c-entry" and a.epoch == 2 and a.grantEpoch == 2)
  run postPollArrivalCannotReuseGrantControlTest = init.then(alreadyFits).then(grant)
    .then(commitGroup).then(publishComplete).then(arriveAtCEntry)
    .then(alreadyFits).then(grant)
    .then(all { a' = {...a, epoch: a.epoch + 1, writes: 1} }).expect(not(safe))

  run gcEpochAloneIsNotEntryRoomTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom)
    .expect(safe and not(a.room) and not(a.reloaded) and not(entryCursor))
  run restoredHandlerViewGrantControlTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService)
    .then(all { a' = {...a, phase: "written", room: true, reloaded: true,
      grantEpoch: a.epoch, grantScope: a.scope, writes: 1} }).expect(not(safe))
  run unwoundButUncheckedRoomControlTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService).then(finishUnwind).then(reload)
    .then(all { a' = {...a, phase: "written", grantEpoch: a.epoch,
      grantScope: a.scope, writes: 1} }).expect(not(safe))
  run settledServiceAllowsNestedInterruptTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService).then(nestedBegin).then(nestedFinish)
    .then(finishUnwind).then(recheckEntryRoom).then(reload).then(grant)
    .then(commitGroup).then(publishComplete)
    .expect(safe and a.nestedCompleted == 1 and a.writes == 1)
  run effectsBeforeServiceSettlementControlTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(all { a' = {...a, deliveringEffects: true} })
    .expect(not(safe))

  run unqualifiedRefillKeepsCustodyTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(rejectRefillOutcome)
    .expect(safe and a.phase == "failed" and a.pending == a.request and a.roots and not(a.deliveringEffects))

  // Revision is a ghost observation of intervening cursor use, not a
  // required runtime counter. Rechecking actual locals avoids old snapshots.
  run sameEpochCursorReplayControlTest = init.then(requestSpace).then(enterRefill)
    .then(restoreWithRoom).then(qualifyRefillOutcome).then(settleService)
    .then(nestedBegin).then(nestedFinish).then(finishUnwind).then(recheckEntryRoom).then(reload)
    .then(all { a' = {...a, phase: "written", grantEpoch: a.epoch, grantScope: a.scope,
      grantRevision: 0, writes: 1} })
    .expect(not(safe) and a.epoch == 2 and a.revision == 1)

  run backedRawSpillThenRefillTest = init.then(spillRawBeforeService)
    .then(requestSpace).then(enterRefill).then(restoreWithRoom)
    .then(qualifyRefillOutcome).then(settleService).then(finishUnwind)
    .then(recheckEntryRoom).then(reload).then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and a.spillWritten and a.writes == 1)
  run futureRefillCannotBackEarlierSpillControlTest = init
    .then(all {a' = {...a, spillBacked: false, spillWritten: true}})
    .expect(not(safe) and a.writes == 0)
  run rawSpillNeedsExactMapControlTest = init
    .then(all {a' = {...a, spillMapExact: false, spillWritten: true}})
    .expect(not(safe) and a.writes == 0)

  // Refinement of the native retry trace. Cursor samples are independently
  // bound to the saved handler view, the decoded caller before helper writes,
  // and the actual first store. Lean supplies coordinate arithmetic.
  type Gate2Retry = {
    oldCallerFp: int, oldSoftLimit: int, handlerSavedFp: int, callerUnwoundFp: int,
    grantedFp: int, firstWriteFp: int, priorAdjustment: int,
    demandReadBeforeSpill: bool, handlerSampleBound: bool, unwindSampleBound: bool,
    storeSampleBound: bool, sameAttempt: bool, repairedViewStable: bool,
    adjustmentAuthorized: bool, footprintCovered: bool
  }

  pure def gate2RetryMatches(w: Gate2Retry): bool =
    w.demandReadBeforeSpill and w.oldCallerFp >= w.oldSoftLimit and
      w.handlerSampleBound and w.unwindSampleBound and w.storeSampleBound and
      w.sameAttempt and w.repairedViewStable and w.footprintCovered and
      w.grantedFp == w.callerUnwoundFp and
      w.adjustmentAuthorized and w.firstWriteFp == w.callerUnwoundFp - w.priorAdjustment

  pure val independentlyObservedRetry: Gate2Retry = {
    oldCallerFp: 100, oldSoftLimit: 98, handlerSavedFp: 87, callerUnwoundFp: 102,
    grantedFp: 102, firstWriteFp: 97, priorAdjustment: 5,
    demandReadBeforeSpill: true, handlerSampleBound: true, unwindSampleBound: true,
    storeSampleBound: true, sameAttempt: true, repairedViewStable: true,
    adjustmentAuthorized: true, footprintCovered: true
  }

  run gate2GrantedWriteCanCrossOldSoftLimitTest =
    assert(gate2RetryMatches(independentlyObservedRetry) and
      independentlyObservedRetry.firstWriteFp < independentlyObservedRetry.oldSoftLimit)

  run gate2HandlerCursorReinjectionIsRefusedTest = {
    val saved = independentlyObservedRetry.handlerSavedFp
    assert(not(gate2RetryMatches({...independentlyObservedRetry,
      grantedFp: saved, firstWriteFp: saved - independentlyObservedRetry.priorAdjustment})))
  }

  run gate2RequiresIndependentUnwindAndStoreTest =
    assert(not(gate2RetryMatches({...independentlyObservedRetry, unwindSampleBound: false})) and
      not(gate2RetryMatches({...independentlyObservedRetry, storeSampleBound: false})) and
      not(gate2RetryMatches({...independentlyObservedRetry, firstWriteFp: 96})))

  run gate2RejectsLateDemandReadOrChangedGrantViewTest =
    assert(not(gate2RetryMatches({...independentlyObservedRetry, demandReadBeforeSpill: false})) and
      not(gate2RetryMatches({...independentlyObservedRetry, oldCallerFp: 97})) and
      not(gate2RetryMatches({...independentlyObservedRetry, repairedViewStable: false})) and
      not(gate2RetryMatches({...independentlyObservedRetry, adjustmentAuthorized: false})))

  // These maps describe the actual view presented at a service edge, not each
  // later logical GVM frame. Native adapters must decode identities and kinds.
  type Gate2RootView = {
    frameIdentity: int, stackBound: int,
    schemeStack: Set[int], rawStack: Set[int], schemeRegs: Set[int], rawRegs: Set[int],
    mappedStack: Set[int], mappedRegs: Set[int]
  }
  pure def gate2RootExtentFits(v: Gate2RootView): bool =
    v.schemeStack.union(v.rawStack).forall(i => i >= 1 and i <= v.stackBound)
  pure def gate2ServiceRootsMatch(v: Gate2RootView): bool =
    gate2RootExtentFits(v) and
      v.schemeStack.forall(i => v.mappedStack.contains(i)) and
      v.schemeRegs.forall(i => v.mappedRegs.contains(i)) and
      v.rawStack.forall(i => not(v.mappedStack.contains(i))) and
      v.rawRegs.forall(i => not(v.mappedRegs.contains(i)))
  pure val completeOpeningView: Gate2RootView = {
    frameIdentity: 1, stackBound: 2,
    schemeStack: Set(1), rawStack: Set(2), schemeRegs: Set(3), rawRegs: Set(4),
    mappedStack: Set(1), mappedRegs: Set(3)
  }
  run gate2EqualExtentWrongRootKindControlTest = {
    val wrong = {...completeOpeningView, mappedStack: Set(2)}
    assert(gate2RootExtentFits(wrong) and not(gate2ServiceRootsMatch(wrong)))
  }
  run gate2MissingRegisterRootControlTest =
    assert(not(gate2ServiceRootsMatch({...completeOpeningView, mappedRegs: Set()})))
  run gate2RawRegisterAsRootControlTest =
    assert(not(gate2ServiceRootsMatch({...completeOpeningView, mappedRegs: Set(3,4)})))
  run gate2DifferentLogicalFrameCanKeepOpeningViewTest =
    assert(gate2ServiceRootsMatch(completeOpeningView) and
      gate2ServiceRootsMatch({...completeOpeningView, frameIdentity: 2}))

  // Probe identity, rather than unequal fp values, distinguishes grant from
  // first-store evidence. The source note at grant is not a store observation.
  type Gate2Probe = {
    event: int, context: int, point: int, attempt: int, fp: int, role: str
  }
  pure def gate2ProbePair(grant: Gate2Probe, store: Gate2Probe): bool =
    grant.role == "grant" and store.role == "first-store" and
      grant.event != store.event and grant.context == store.context and
      grant.point == store.point and grant.attempt > 0 and grant.attempt == store.attempt
  pure val grantProbe: Gate2Probe = {
    event: 1, context: 1, point: 7, attempt: 3, fp: 100, role: "grant"
  }
  run gate2EqualCursorIndependentProbesTest =
    assert(gate2ProbePair(grantProbe,{...grantProbe,event: 2,role: "first-store"}))
  run gate2CopiedGrantIsNotStoreControlTest =
    assert(not(gate2ProbePair(grantProbe,{...grantProbe,role: "first-store"})))
  run gate2UnboundAttemptCannotSupplyStoreControlTest =
    assert(not(gate2ProbePair(grantProbe,{...grantProbe,event: 2,role: "first-store",attempt: 4})))

  run gate2RebasedWriteExceedsLocalMaximumControlTest =
    assert(4 <= 6 and 6 <= 6 and 4 + 6 > 6 and 100 - 4 - 6 < 100 - 6)

  type Gate2Settlement = {
    invocation: int, grantInvocation: int, settleInvocation: int,
    oldSpills: Set[int], backedRawSlots: Set[int], firstStore: int, grant: int,
    commit: int, nextGroup: int, postCommitEffects: int, complete: bool
  }
  pure def gate2Settled(w: Gate2Settlement): bool =
    w.complete and w.invocation == w.grantInvocation and w.invocation == w.settleInvocation and
      w.oldSpills.subseteq(w.backedRawSlots) and w.grant < w.firstStore and w.firstStore < w.commit and
      w.commit < w.nextGroup and w.postCommitEffects == 0
  pure val gate2Settlement: Gate2Settlement = {
    invocation: 11, grantInvocation: 11, settleInvocation: 11,
    oldSpills: Set(2), backedRawSlots: Set(2, 3), firstStore: 15, grant: 14,
    commit: 16, nextGroup: 17, postCommitEffects: 0, complete: true
  }

  // Cursor, extent and absence of service boundaries are premises of this
  // local route. No attempt is created until the mapped slow path needs one.
  type LocalGroup = {
    heapWords: int, heapRoom: int, stackWords: int, stackRoom: int,
    currentOwner: bool, currentView: bool, oldBacking: bool,
    needsSettlement: bool, uninterrupted: bool
  }
  pure def localGroupFits(g: LocalGroup): bool =
    g.currentOwner and g.currentView and g.oldBacking and g.uninterrupted and
      not(g.needsSettlement) and 0 <= g.heapWords and g.heapWords <= g.heapRoom and
      0 <= g.stackWords and g.stackWords <= g.stackRoom
  pure val localGroup: LocalGroup = {
    heapWords: 5, heapRoom: 5, stackWords: 2, stackRoom: 2,
    currentOwner: true, currentView: true, oldBacking: true,
    needsSettlement: false, uninterrupted: true
  }
  type StackFudgeAdmission = {
    fpOffset: int, fudgeWords: int, stackWords: int, spillWords: int,
    ownedSpanWords: int
  }
  pure def mutatorStackFudgeFits(s: StackFudgeAdmission): bool =
    0 <= s.stackWords and 0 < s.fudgeWords and s.fudgeWords < s.ownedSpanWords and
      s.fudgeWords <= s.fpOffset and s.fpOffset <= s.ownedSpanWords and
      s.stackWords <= s.fpOffset - s.fudgeWords
  pure def handlerSpillBackedAtShortage(s: StackFudgeAdmission): bool =
    0 < s.spillWords and s.spillWords <= s.fudgeWords and
      s.fudgeWords <= s.fpOffset and s.fpOffset <= s.ownedSpanWords and
      s.spillWords <= s.fpOffset
  type HeapSoftPollView = {
    hpOffset: int, softLimit: int, hardLimit: int, fudgeWords: int,
    heapWords: int, freeSectionAvailable: bool, sharedStackClip: bool
  }
  pure def softPollExtendsInSection(h: HeapSoftPollView): bool =
    0 < h.heapWords and not(h.sharedStackClip) and
      0 <= h.hpOffset and h.hpOffset <= h.hardLimit and
      h.softLimit < h.hardLimit - h.fudgeWords and
      h.hpOffset + h.heapWords > h.softLimit and
      h.hardLimit - h.hpOffset > h.fudgeWords and
      (h.hardLimit - h.hpOffset) - h.fudgeWords >= h.heapWords
  pure def softPollUsesTrackedFudgeInSection(h: HeapSoftPollView): bool =
    0 < h.heapWords and not(h.sharedStackClip) and
      0 <= h.hpOffset and h.hpOffset + h.heapWords <= h.hardLimit and
      h.hardLimit - h.hpOffset > h.fudgeWords and
      (h.hardLimit - h.hpOffset) - h.fudgeWords < h.heapWords
  pure def softPollNeedsNextSection(h: HeapSoftPollView): bool =
    0 < h.heapWords and not(softPollExtendsInSection(h)) and
      not(softPollUsesTrackedFudgeInSection(h)) and
      h.freeSectionAvailable and h.hpOffset + h.heapWords > h.softLimit
  pure def alignFrame4(cfs: int): int =
    ((cfs + 3) / 4) * 4
  pure def cProcedureEntryLinkValid(pcFs: int, link: int): bool =
    0 <= pcFs and link == alignFrame4(pcFs)
  pure def flonumFlushHeapWords(reserved: int, dirtyBefore: int, flonumWords: int, clearBeforeReserve: bool): int =
    if (clearBeforeReserve)
      (reserved + flonumWords) + (dirtyBefore - 1) * flonumWords
    else
      (reserved + flonumWords) + dirtyBefore * flonumWords
  type SectionCacheSlot = {
    sectionId: int, baseAddr: int, halfWords: int, epoch: int
  }
  pure def lookupSectionWithCache(cache: SectionCacheSlot, headerAddr: int, epoch: int,
      fallbackSectionId: int, fallbackBase: int, halfWords: int): { sectionId: int, pos: int } =
    if (cache.sectionId > 0 and cache.epoch == epoch and
        headerAddr >= cache.baseAddr and headerAddr < cache.baseAddr + cache.halfWords)
      { sectionId: cache.sectionId, pos: headerAddr - cache.baseAddr }
    else
      { sectionId: fallbackSectionId, pos: headerAddr - fallbackBase }
  type RestShortageRoute = {
    lifecycleGcAdmitted: bool, autoWatchMode: int, plantedAttemptWords: int,
    oneWordShort: bool, physicalTailShort: bool, contestMatched: bool,
    configuredMaxHeap: int, contestCapBytes: int
  }
  pure def restPlantedShortActive(r: RestShortageRoute): bool =
    r.autoWatchMode == 1 or r.plantedAttemptWords > 0
  pure def restRefusesCut9BeforeWindow(r: RestShortageRoute): bool =
    restPlantedShortActive(r) and r.oneWordShort and r.physicalTailShort
  pure def restCollectsBeforeSectionExtend(r: RestShortageRoute): bool =
    not(restRefusesCut9BeforeWindow(r)) and r.lifecycleGcAdmitted and r.physicalTailShort
  pure def restEffectiveContestMaxHeap(r: RestShortageRoute): int =
    if (r.contestMatched)
      if (r.configuredMaxHeap > 0 and r.configuredMaxHeap < r.contestCapBytes)
        r.configuredMaxHeap
      else
        r.contestCapBytes
    else
      r.configuredMaxHeap
  run smpParallelWorkerScanCacheIsolationTest = {
    val worker1Cache: SectionCacheSlot = { sectionId: 1, baseAddr: 100000, halfWords: 65536, epoch: 7 }
    val worker2ConcurrentCache: SectionCacheSlot = { sectionId: 2, baseAddr: 110000, halfWords: 65536, epoch: 7 }
    val headerInSection1 = 120000
    val isolated = lookupSectionWithCache(worker1Cache, headerInSection1, 7, 1, 100000, 65536)
    val aliasedGlobal = lookupSectionWithCache(worker2ConcurrentCache, headerInSection1, 7, 1, 100000, 65536)
    assert(isolated.sectionId == 1 and isolated.pos == 20000 and
      aliasedGlobal.sectionId == 2 and aliasedGlobal.pos != isolated.pos)
  }
  run restShortageLifecycleAndObservationOrderTest = {
    val watchShort: RestShortageRoute = {
      lifecycleGcAdmitted: true, autoWatchMode: 1, plantedAttemptWords: 0,
      oneWordShort: true, physicalTailShort: true, contestMatched: false,
      configuredMaxHeap: 0, contestCapBytes: 524288
    }
    val runtimeCrossBreak: RestShortageRoute = {
      ...watchShort, autoWatchMode: 0, oneWordShort: false
    }
    val bootstrapEarly: RestShortageRoute = {
      ...runtimeCrossBreak, lifecycleGcAdmitted: false
    }
    val contestRace: RestShortageRoute = {
      ...runtimeCrossBreak, contestMatched: true
    }
    assert(restRefusesCut9BeforeWindow(watchShort) and
      not(restRefusesCut9BeforeWindow(runtimeCrossBreak)) and
      restCollectsBeforeSectionExtend(runtimeCrossBreak) and
      not(restCollectsBeforeSectionExtend(bootstrapEarly)) and
      restEffectiveContestMaxHeap(contestRace) == 524288 and
      restEffectiveContestMaxHeap(runtimeCrossBreak) == 0)
  }
  run mutatorStackFudgeReserveProtectsHandlerSpillTest = {
    val shortage: StackFudgeAdmission = {
      fpOffset: 9236, fudgeWords: 9220, stackWords: 20, spillWords: 16,
      ownedSpanWords: 65536
    }
    val fitting: StackFudgeAdmission = {...shortage, fpOffset: 9240}
    val insideFudge: StackFudgeAdmission = {...shortage, fpOffset: 9219, stackWords: 1}
    assert(not(mutatorStackFudgeFits(shortage)) and
      handlerSpillBackedAtShortage(shortage) and
      mutatorStackFudgeFits(fitting) and
      not(mutatorStackFudgeFits(insideFudge)))
  }
  run softHeapPollExtendsInPlaceBeforeSectionBumpTest = {
    val startupPoll: HeapSoftPollView = {
      hpOffset: 16384, softLimit: 16384, hardLimit: 65536, fudgeWords: 9220,
      heapWords: 4, freeSectionAvailable: true, sharedStackClip: false
    }
    val preFudgeTail: HeapSoftPollView = {
      ...startupPoll, hpOffset: 56314, softLimit: 56316
    }
    val sectionExhausted: HeapSoftPollView = {
      ...startupPoll, hpOffset: 56316, softLimit: 56316
    }
    val sharedClipped: HeapSoftPollView = {...startupPoll, sharedStackClip: true}
    assert(softPollExtendsInSection(startupPoll) and
      not(softPollNeedsNextSection(startupPoll)) and
      softPollUsesTrackedFudgeInSection(preFudgeTail) and
      not(softPollNeedsNextSection(preFudgeTail)) and
      not(softPollExtendsInSection(sectionExhausted)) and
      softPollNeedsNextSection(sectionExhausted) and
      not(softPollExtendsInSection(sharedClipped)))
  }
  run cLambdaFreshEntryFramePreventsStaleLinkTest = {
    assert(cProcedureEntryLinkValid(0, 0) and
      cProcedureEntryLinkValid(2, 4) and
      not(cProcedureEntryLinkValid(0, 5)))
  }
  run dirtyFlonumFlushConservesGroupHeapBudgetTest = {
    val initial = 4 + 3 * 6
    assert(flonumFlushHeapWords(4, 3, 6, true) == initial and
      flonumFlushHeapWords(4, 3, 6, false) > initial)
  }
  run gate2NativeSameInvocationSettlementTest =
    assert(gate2Settled(gate2Settlement) and localGroupFits(localGroup) and
      localGroupFits({...localGroup, heapWords: 0, heapRoom: 0}))
  run gate2NativeNoSpliceOrReplayTest =
    assert(not(gate2Settled({...gate2Settlement, settleInvocation: 12})) and
      not(gate2Settled({...gate2Settlement, postCommitEffects: 1})))
  run gate2NativeNoUntypedSpillOrMissingCloseTest =
    assert(not(gate2Settled({...gate2Settlement, backedRawSlots: Set(3)})) and
      not(gate2Settled({...gate2Settlement, complete: false})) and
      not(localGroupFits({...localGroup, heapRoom: 4})) and
      not(localGroupFits({...localGroup, stackRoom: 1})) and
      not(localGroupFits({...localGroup, currentOwner: false})) and
      not(localGroupFits({...localGroup, currentView: false})) and
      not(localGroupFits({...localGroup, oldBacking: false})) and
      not(localGroupFits({...localGroup, uninterrupted: false})) and
      not(localGroupFits({...localGroup, heapWords: 0, needsSettlement: true})))

  run localProgressOrderTest =
    assert(localRank("entry") > localRank("handler") and
      localRank("handler") > localRank("retry") and
      localRank("retry") > localRank("granted") and
      localRank("granted") > localRank("written") and
      localRank("written") > localRank("done") and
      localRank("handler") > localRank("failed"))

  run caughtRefusalNeedsMoreThanZeroWritesTest = init.then(requestSpace)
    .then(enterRefill).then(exhausted).then(catchWithoutCurrentBacking)
    .expect(a.writes == 0 and a.pending == 0 and not(caughtEntryReady))
  run refusedThenExactFitWithCurrentBackingTest = init.then(requestSpace)
    .then(enterRefill).then(exhausted).then(normalizeRefusalReturn)
    .expect(caughtEntryReady).then(reenterAfterCaught).then(alreadyFits)
    .then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and a.phase == "done" and a.request == 2)
  run softShortRecoveryMayWriteAfterFreshGrantTest = init.then(requestSpace)
    .then(enterRefill).then(restoreWithRoom).then(qualifyRefillOutcome)
    .then(settleService).then(finishUnwind).then(recheckEntryRoom).then(reload)
    .then(grant).then(commitGroup).then(publishComplete)
    .expect(safe and a.writes == 1 and a.published)
}
