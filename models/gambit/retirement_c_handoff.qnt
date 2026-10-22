module retirement_c_handoff {
  // Single transition system: P0+A+B, two GC rounds per epoch, two epochs.
  // mode 0 abort/abort; 1 abort/success; 2 invalid suffix -> opaque containment.
  // Mutation policies are enumerated in the accompanying source contract.
  type State = { policy: int, mode: int, epoch: int, phase: int, cohort: int,
    a: int, b: int, aCalls: int, bCalls: int, yCalls: int,
    totalA: int, totalB: int, totalY: int,
    xFreed: bool, xQueued: bool, usedFreed: bool,
    yAlive: bool, yDisposition: int, invalidSuffix: bool,
    round: int, gcPhase: int, lastGC: int, version: int,
    arrival0: int, arrivalA: int, arrivalB: int, staleGC: bool,
    sourceA: bool, sourceB: bool, versionA: int, versionB: int,
    receiverA: bool, receiverB: bool, receiverVA: int, receiverVB: int,
    rcRegistered: bool, frameA: bool, frameB: bool, framesElsewhere: bool,
    requestRoot: bool, requestVersion: int,
    error: bool, errorRoot: bool, errorVersion: int, consumed: bool,
    willOwner: bool, willReceiver: bool, actionMarked: bool, testatorMarked: bool,
    willDecided: bool, willExecutable: bool,
    p0Prepared: bool, handoff: bool, ack0: int, ackA: int, ackB: int,
    staleAck: bool, common: bool, resumed: bool, retained: bool,
    left0: bool, leftA: bool, leftB: bool, badReuse: bool,
    workPublished: bool, scannerActive: bool, producerOpen: bool,
    tail0: int, tailA: int, tailB: int, staleTail: bool, listsReceiver: bool,
    originClear: bool, returnStage: int, localVersion: int, callerRoot: bool,
    callerVersion: int, postReturnChecked: bool, movable: bool, callerMode: int, bridgeGC: bool }
  var s: State
  pure def initial(policy: int, mode: int): State = {
    policy: policy, mode: mode, epoch: 0, phase: 0, cohort: 3,
    a: 0, b: 0, aCalls: 0, bCalls: 0, yCalls: 0,
    totalA: 0, totalB: 0, totalY: 0,
    xFreed: false, xQueued: false, usedFreed: false,
    yAlive: false, yDisposition: 0, invalidSuffix: false,
    round: 0, gcPhase: 0, lastGC: 0, version: 0,
    arrival0: 0, arrivalA: 0, arrivalB: 0, staleGC: false,
    sourceA: true, sourceB: true, versionA: 0, versionB: 0,
    receiverA: false, receiverB: false, receiverVA: -1, receiverVB: -1,
    rcRegistered: true, frameA: true, frameB: true, framesElsewhere: false,
    requestRoot: false, requestVersion: 0,
    error: false, errorRoot: false, errorVersion: -1, consumed: false,
    willOwner: true, willReceiver: false, actionMarked: false, testatorMarked: false,
    willDecided: false, willExecutable: false,
    p0Prepared: false, handoff: false, ack0: 0, ackA: 0, ackB: 0,
    staleAck: false, common: false, resumed: false, retained: false,
    left0: false, leftA: false, leftB: false, badReuse: false,
    workPublished: false, scannerActive: false, producerOpen: false,
    tail0: 0, tailA: 0, tailB: 0, staleTail: false, listsReceiver: false,
    originClear: true, returnStage: 0, localVersion: -1, callerRoot: false,
    callerVersion: -1, postReturnChecked: false, movable: true, callerMode: 0, bridgeGC: false }
  action initAbortTwice = s' = initial(0,0)
  action initAbortThenCommit = s' = initial(0,1)
  action initOpaqueSuffix = s' = initial(0,2)
  action initEarlyReturn = s' = initial(1,0)
  action initEarlySourceDrop = s' = initial(2,0)
  action initStaleGCRound = s' = initial(3,0)
  action initStaleGCEpoch = s' = initial(4,0)
  action initStaleAbortEpoch = s' = initial(5,0)
  action initEarlyErrorRelease = s' = initial(6,0)
  action initReplay = s' = initial(7,0)
  action initDeadSuffixResume = s' = initial(8,2)
  action initStrongifyWeak = s' = initial(9,0)
  action initWithdrawFrame = s' = initial(10,0)
  action initDropWillOwner = s' = initial(11,0)
  action initEarlyDecision = s' = initial(12,0)
  action initStaleCursor = s' = initial(13,0)
  action initPrematureReuse = s' = initial(14,0)
  action initUnscannedPayload = s' = initial(15,0)
  action initMissingHandoff = s' = initial(17,1)
  action initFreedNodeAccess = s' = initial(16,0)
  action initImmediateErrors = s' = { ...initial(0,0), movable: false }
  action initRegisteredCCaller = s' = { ...initial(0,0), callerMode: 1 }
  action initScanStillActive = s' = initial(18,0)
  action initSkippedGCTail = s' = initial(19,0)
  action initLateWorkProducer = s' = initial(20,1)
  action initMissingStillRC = s' = initial(21,1)
  action initLiveNativeOrigin = s' = { ...initial(22,1), originClear: false }
  action initGCInReturnGap = s' = initial(23,0)
  action initStaleReturnCopy = s' = initial(24,0)
  action initUnregisteredCCaller = s' = { ...initial(25,0), callerMode: 2 }
  action initCatcherOnly = s' = { ...initial(26,0), callerMode: 3 }
  val shouldFail = s.epoch == 1 or s.mode != 1
  val gcKey = s.epoch * 10 + s.round
  val allArrived = s.arrival0 == gcKey and s.arrivalA == gcKey and s.arrivalB == gcKey
  val allAcked = s.ack0 == s.epoch and s.ackA == s.epoch and s.ackB == s.epoch
  val tailsReturned = s.tail0 == gcKey and s.tailA == gcKey and s.tailB == gcKey
  val workClosed = not(s.workPublished) and not(s.scannerActive) and not(s.producerOpen)
  val resultReleased = s.consumed and not(s.requestRoot) and not(s.errorRoot) and s.postReturnChecked
  val allLeft = s.left0 and s.leftA and s.leftB
  action openEpoch = all { s.phase == 0, s.epoch < 2,
    s' = { ...s, epoch: s.epoch + 1, phase: 1, a: 0, b: 0,
      aCalls: 0, bCalls: if(s.policy == 13 and s.epoch == 1) s.bCalls else 0,
      yCalls: 0, xFreed: false, xQueued: false, usedFreed: false,
      yAlive: true, yDisposition: 0, invalidSuffix: false,
      round: 0, gcPhase: 0, lastGC: 0,
      sourceA: true, sourceB: true, versionA: s.version, versionB: s.version,
      receiverA: false, receiverB: false, receiverVA: -1, receiverVB: -1,
      rcRegistered: s.policy != 15, frameA: s.policy != 10, frameB: true, framesElsewhere: false,
      requestRoot: true, requestVersion: s.version,
      error: false, errorRoot: false, errorVersion: -1, consumed: false,
      willOwner: s.policy != 11, willReceiver: false, actionMarked: false, testatorMarked: false,
      willDecided: false, willExecutable: false,
      p0Prepared: false, handoff: false, common: false, resumed: false, retained: false,
      left0: false, leftA: false, leftB: false,
      workPublished: false, scannerActive: false, producerOpen: false,
      listsReceiver: false, returnStage: 0, localVersion: -1, callerRoot: false,
      callerVersion: -1, postReturnChecked: false, bridgeGC: false } }
  action startA = all { s.phase == 1, s.a == 0,
    s' = { ...s, a: 1, aCalls: s.aCalls + 1, totalA: s.totalA + 1 } }
  action readyA = all { s.phase == 1, s.a == 1, s.gcPhase == 0,
    s' = { ...s, a: 2, receiverA: true, receiverVA: s.version,
      sourceA: s.policy != 2 } }
  // Atomic one-node pop under existing mutex, then unlocked callback.
  // Y remains queue-owned and never invoked during a failed preparation.
  action popAndStartB = all { s.phase == 1, s.b == 0,
    s' = { ...s, b: 1, bCalls: s.bCalls + 1, totalB: s.totalB + 1 } }
  action requestGC1 = all { s.phase == 1, s.b == 1, s.round == 0,
    s' = { ...s, round: 1, gcPhase: 1, workPublished: true, producerOpen: true } }
  action outcomeB = all { s.phase == 1, s.b == 1, s.a == 2,
    s.lastGC == s.epoch * 10 + 1, s.gcPhase == 0,
    s' = { ...s, b: if(shouldFail) 3 else 2, xFreed: true,
      error: shouldFail, errorRoot: shouldFail, errorVersion: if(shouldFail) s.version else -1,
      yAlive: s.mode != 2, invalidSuffix: s.mode == 2,
      usedFreed: s.policy == 16 } }
  action requestGC2 = all { s.phase == 1, s.b >= 2, s.round == 1, s.gcPhase == 0,
    s' = { ...s, round: 2, gcPhase: 1, workPublished: true, producerOpen: true } }
  action arriveP0 = all { s.phase == 1, s.gcPhase == 1, not(s.left0), s.arrival0 != gcKey,
    s' = { ...s, arrival0: gcKey } }
  action arriveA = all { s.phase == 1, s.gcPhase == 1, not(s.leftA), s.arrivalA != gcKey,
    s' = { ...s, arrivalA: gcKey } }
  action arriveB = all { s.phase == 1, s.gcPhase == 1, not(s.leftB), s.arrivalB != gcKey,
    s' = { ...s, arrivalB: gcKey } }
  // Strong roots first. The GC key contains both epoch and within-epoch round.
  action markStrong = all { s.phase == 1, s.gcPhase == 1,
    allArrived or
      (s.policy == 3 and s.round == 2 and s.arrival0 >= s.epoch * 10 + 1 and s.arrivalA >= s.epoch * 10 + 1 and s.arrivalB >= s.epoch * 10 + 1) or
      (s.policy == 4 and s.epoch == 2 and s.arrival0 > 0 and s.arrivalA > 0 and s.arrivalB > 0),
    s' = { ...s, gcPhase: 2, scannerActive: true, workPublished: false, staleGC: s.staleGC or not(allArrived), version: s.version + 1,
      versionA: if(s.sourceA and s.frameA) s.version + 1 else s.versionA,
      versionB: if(s.sourceB and s.frameB) s.version + 1 else s.versionB,
      receiverVA: if(s.receiverA) s.version + 1 else s.receiverVA,
      receiverVB: if(s.receiverB) s.version + 1 else s.receiverVB,
      requestVersion: if(s.requestRoot and s.rcRegistered) s.version + 1 else s.requestVersion,
      errorVersion: if(s.errorRoot and s.rcRegistered) s.version + 1 else s.errorVersion,
      actionMarked: s.willOwner, testatorMarked: s.policy == 9 } }
  action determineWill = all { s.phase == 1, s.gcPhase == 2,
    s' = { ...s, gcPhase: 3, willDecided: true,
      willExecutable: s.willExecutable or (s.willOwner and not(s.testatorMarked)) } }
  // process_wills/marking may publish additional work. Empty FIFO != scan return.
  action publishWeakWork = all { s.phase == 1, s.gcPhase == 3,
    s' = { ...s, gcPhase: 4, workPublished: true, producerOpen: false } }
  action dequeueLastWork = all { s.phase == 1, s.gcPhase == 4, s.workPublished,
    s' = { ...s, workPublished: false } }
  action returnScanner = all { s.phase == 1, s.gcPhase == 4,
    not(s.workPublished), s.scannerActive,
    s' = { ...s, gcPhase: 5, scannerActive: false } }
  action finishGC = all { s.phase == 1,
    (s.gcPhase == 5 and workClosed) or
      (s.policy == 18 and s.gcPhase == 4 and not(s.workPublished)),
    s' = { ...s, gcPhase: 6, testatorMarked: s.willOwner } }
  // Full GC epilogue includes fp/hp restoration, not just the weak-phase barrier.
  action tailP0 = all { s.phase == 1, s.gcPhase == 6, s.tail0 != gcKey,
    s' = { ...s, tail0: gcKey } }
  action tailA = all { s.phase == 1, s.gcPhase == 6, s.tailA != gcKey,
    s' = { ...s, tailA: gcKey } }
  action tailB = all { s.phase == 1, s.gcPhase == 6, s.tailB != gcKey,
    s' = { ...s, tailB: gcKey } }
  action completeGCReturn = all { s.phase == 1, s.gcPhase == 6,
    tailsReturned or s.policy == 19,
    s' = { ...s, gcPhase: 0, lastGC: gcKey, staleTail: s.staleTail or not(tailsReturned) } }
  // Success must discharge Y before the no-future-callback cut.
  action cancelYOnSuccess = all { s.phase == 1, not(s.error), s.b == 2,
    s.lastGC == s.epoch * 10 + 2, s.gcPhase == 0, s.yAlive, s.yCalls == 0,
    s' = { ...s, yAlive: false, yCalls: 1, totalY: s.totalY + 1 } }
  action settlePreparation = all { s.phase == 1, s.a == 2, s.b >= 2,
    s.lastGC == s.epoch * 10 + 2, s.gcPhase == 0, workClosed, tailsReturned, not(s.p0Prepared),
    s.error or s.yCalls == 1,
    s' = { ...s, p0Prepared: true,
      yDisposition: if(not(s.error)) 3 else if(s.yAlive or s.policy == 8) 1 else 2 } }
  // Abstract typed handoff: values/continuations already on supported surviving owners.
  // This is a C refinement premise, NOT raw native frame migration.
  action spliceStillRC = all { s.phase == 1, s.p0Prepared, not(s.error), not(s.listsReceiver),
    s' = { ...s, listsReceiver: true, receiverB: true, receiverVB: s.version } }
  action handoffFrameValues = all { s.phase == 1, s.p0Prepared, not(s.error), not(s.framesElsewhere),
    s.originClear or s.policy == 22,
    s' = { ...s, framesElsewhere: true } }
  action handoffWillLists = all { s.phase == 1, s.p0Prepared, not(s.error), not(s.willReceiver),
    s' = { ...s, willReceiver: true } }
  action prepareHandoff = all { s.phase == 1, s.p0Prepared, not(s.error), not(s.handoff),
    (s.listsReceiver or s.policy == 21), s.framesElsewhere, s.willReceiver, workClosed,
    s' = { ...s, handoff: true, receiverB: true, receiverVB: s.version } }
  action lateProducer = all { s.policy == 20, s.phase == 1, s.p0Prepared, not(s.producerOpen),
    s' = { ...s, producerOpen: true, workPublished: true } }
  action earlyReturn = all { s.policy == 1, s.phase == 1, s.error, not(s.leftB),
    s' = { ...s, leftB: true } }
  action releaseErrorEarly = all { s.policy == 6, s.errorRoot, not(s.consumed),
    s' = { ...s, errorRoot: false } }
  action replayX = all { s.policy == 7, s.error, not(s.xQueued),
    s' = { ...s, xQueued: true, bCalls: s.bCalls + 1 } }
  action decide = all { s.phase == 1, s.a == 2, s.b >= 2, s.gcPhase == 0,
    (s.p0Prepared and (s.error or s.handoff or s.policy == 17)) or s.policy == 12,
    s' = { ...s, phase: 2 } }
  action ackP0 = all { s.phase == 2, s.ack0 != s.epoch, s' = { ...s, ack0: s.epoch } }
  action ackA = all { s.phase == 2, s.ackA != s.epoch, s' = { ...s, ackA: s.epoch } }
  action ackB = all { s.phase == 2, s.ackB != s.epoch, s' = { ...s, ackB: s.epoch } }
  action commonCompletion = all { s.phase == 2,
    allAcked or (s.policy == 5 and s.epoch == 2 and s.ack0 > 0 and s.ackA > 0 and s.ackB > 0),
    s' = { ...s, phase: if(s.error) 3 else 4, common: true,
      staleAck: not(allAcked), cohort: if(s.error) 3 else 1,
      retained: s.error and s.yDisposition == 2,
      resumed: s.error and s.yDisposition == 1,
      receiverA: if(s.error) false else s.receiverA,
      sourceA: if(s.error) s.sourceA else false,
      sourceB: if(s.error) s.sourceB else false,
      willOwner: if(s.error) s.willOwner else false } }
  action leaveP0 = all { s.common, not(s.left0), s' = { ...s, left0: true } }
  action leaveA = all { s.common, not(s.leftA), s' = { ...s, leftA: true } }
  action leaveB = all { s.common, not(s.leftB), s' = { ...s, leftB: true } }
  // Last read from traced storage; no collective GC until caller installation.
  // The existing c-lambda normal-return bridge is such a cooperative no-GC path.
  action consumeResult = all { s.common, allLeft, s.returnStage == 0,
    s' = { ...s, returnStage: 1,
      localVersion: if(s.policy == 24) s.version - 1 else if(s.error) s.errorVersion else s.version } }
  action releaseResult = all { s.returnStage == 1, s.requestRoot or s.errorRoot,
    s' = { ...s, returnStage: 2, requestRoot: false, errorRoot: false } }
  action gcInGap = all { s.policy == 23, s.returnStage == 2, not(s.bridgeGC),
    s' = { ...s, bridgeGC: true } }
  action installCallerRoot = all { s.returnStage == 2,
    s' = { ...s, returnStage: 3, consumed: true,
      callerRoot: s.callerMode <= 1, callerVersion: s.localVersion } }
  // Relocation discriminator after caller installation, not a third full GC protocol.
  action checkCallerRelocation = all { s.returnStage == 3, not(s.postReturnChecked),
    s' = { ...s, postReturnChecked: true,
      callerVersion: if(s.callerRoot) s.version + 1 else s.callerVersion,
      localVersion: s.localVersion, version: s.version + 1,
      versionA: if(s.sourceA) s.version + 1 else s.versionA,
      versionB: if(s.sourceB) s.version + 1 else s.versionB,
      receiverVA: if(s.receiverA) s.version + 1 else s.receiverVA,
      receiverVB: if(s.receiverB) s.version + 1 else s.receiverVB } }
  action serviceYAfterAbort = all { s.phase == 3, s.resumed, resultReleased,
    s.yAlive, s.yCalls == 0,
    s' = { ...s, yAlive: false, yCalls: 1, totalY: s.totalY + 1 } }
  action nextEpoch = all { s.common, s.epoch == 1, not(s.retained),
    (resultReleased and allLeft and s.yCalls == 1) or s.policy == 14,
    s' = { ...s, phase: 0,
      badReuse: not(resultReleased and allLeft and s.yCalls == 1) } }
  val terminal = s.common and resultReleased and allLeft and
    (s.retained or (s.epoch == 2 and s.yCalls == 1))
  action done = all { terminal, s' = s }
  action step = any { openEpoch, startA, readyA, popAndStartB, requestGC1,
    outcomeB, requestGC2, arriveP0, arriveA, arriveB, markStrong, determineWill,
    finishGC, publishWeakWork, dequeueLastWork, returnScanner, tailP0, tailA, tailB, completeGCReturn,
    cancelYOnSuccess, settlePreparation, spliceStillRC, handoffFrameValues, handoffWillLists, prepareHandoff, lateProducer, earlyReturn,
    releaseErrorEarly, replayX, decide, ackP0, ackA, ackB, commonCompletion,
    leaveP0, leaveA, leaveB, consumeResult, releaseResult, gcInGap, installCallerRoot, checkCallerRelocation, serviceYAfterAbort, nextEpoch, done }
  val strongCoverage = ((s.sourceA and s.cohort == 3 and s.frameA and s.versionA == s.version) or
      (s.receiverA and s.receiverVA == s.version)) and
    ((s.sourceB and s.cohort == 3 and s.frameB and s.versionB == s.version) or
      (s.receiverB and s.receiverVB == s.version))
  val resultCoverage = (s.phase == 0 or s.consumed or s.returnStage == 2 or
      (s.requestRoot and s.rcRegistered and s.requestVersion == s.version)) and
    (not(s.error) or not(s.movable) or
      ((s.errorRoot and s.rcRegistered and s.errorVersion == s.version) or
       (s.returnStage >= 1 and s.returnStage <= 2 and not(s.bridgeGC) and s.localVersion == s.version) or
       (s.callerRoot and s.callerVersion == s.version)))
  val transferCoverage = s.cohort == 3 or (s.listsReceiver and s.willReceiver and s.framesElsewhere and workClosed)
  val workSafety = (s.gcPhase != 6 or workClosed) and (not(s.p0Prepared) or workClosed) and not(s.staleTail)
  val framesCovered = s.cohort == 3 and s.frameA and s.frameB or s.framesElsewhere
  val weakSemantics = ((s.willOwner and s.cohort == 3) or s.willReceiver) and (not(s.willDecided) or (s.actionMarked and s.willExecutable))
  val serving = s.common or (s.cohort == 3 and not(s.left0) and not(s.leftA) and not(s.leftB))
  val closedDecision = s.phase != 2 or (s.p0Prepared and s.lastGC == s.epoch * 10 + 2)
  val queueSafe = s.aCalls <= 1 and s.bCalls <= 1 and s.yCalls <= 1 and not(s.xQueued) and not(s.usedFreed) and
    (not(s.resumed) or (not(s.invalidSuffix) and s.yDisposition == 1))
  val safe = strongCoverage and resultCoverage and transferCoverage and workSafety and
    (not(s.framesElsewhere) or s.originClear) and framesCovered and weakSemantics and serving and
    closedDecision and queueSafe and not(s.staleGC) and not(s.staleAck) and not(s.badReuse)
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
  action gcRound = arriveA.then(arriveB).then(arriveP0).then(markStrong).then(determineWill).then(publishWeakWork).then(dequeueLastWork)
    .then(returnScanner).then(finishGC).then(tailA).then(tailB).then(tailP0).then(completeGCReturn)
  action prepareFailingEpoch = startA.then(readyA).then(popAndStartB).then(requestGC1).then(gcRound)
    .then(outcomeB).then(requestGC2).then(gcRound).then(settlePreparation).then(decide)
    .then(ackA).then(ackP0).then(ackB).then(commonCompletion)
    .then(leaveB).then(leaveA).then(leaveP0).then(consumeResult).then(releaseResult).then(installCallerRoot).then(checkCallerRelocation)
  run combinedAbortAcrossTwoEpochs = initAbortTwice.then(openEpoch).then(prepareFailingEpoch)
    .expect(s.epoch == 1 and s.version == 3 and s.errorVersion == 2 and s.cohort == 3 and safe)
    .then(serviceYAfterAbort).then(nextEpoch).then(openEpoch)
    .expect(s.epoch == 2 and s.ack0 == 1 and s.arrival0 == 12 and s.bCalls == 0)
    .then(prepareFailingEpoch).then(serviceYAfterAbort)
    .expect(terminal and safe and s.version == 6 and s.totalA == 2 and s.totalB == 2 and s.totalY == 2)
  run abortThenSuccessfulHandoff = initAbortThenCommit.then(openEpoch).then(prepareFailingEpoch)
    .then(serviceYAfterAbort).then(nextEpoch).then(openEpoch)
    .then(startA).then(readyA).then(popAndStartB).then(requestGC1).then(gcRound)
    .then(outcomeB).then(requestGC2).then(gcRound).then(cancelYOnSuccess)
    .then(settlePreparation).then(spliceStillRC).then(handoffFrameValues).then(handoffWillLists).then(prepareHandoff).then(decide)
    .then(ackB).then(ackA).then(ackP0).then(commonCompletion)
    .then(leaveA).then(leaveP0).then(leaveB).then(consumeResult).then(releaseResult).then(installCallerRoot).then(checkCallerRelocation)
    .expect(terminal and safe and s.cohort == 1 and s.version == 6 and s.framesElsewhere)
  run registeredCCallerKeepsCurrentValue = initRegisteredCCaller.then(openEpoch).then(prepareFailingEpoch)
    .expect(s.callerMode == 1 and s.callerRoot and s.callerVersion == s.version and safe)
}
