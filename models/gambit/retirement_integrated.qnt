module retirement_integrated {
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
    left0: bool, leftA: bool, leftB: bool, badReuse: bool }
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
    left0: false, leftA: false, leftB: false, badReuse: false }
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
  val shouldFail = s.epoch == 1 or s.mode != 1
  val gcKey = s.epoch * 10 + s.round
  val allArrived = s.arrival0 == gcKey and s.arrivalA == gcKey and s.arrivalB == gcKey
  val allAcked = s.ack0 == s.epoch and s.ackA == s.epoch and s.ackB == s.epoch
  val resultReleased = s.consumed and not(s.requestRoot) and not(s.errorRoot)
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
      left0: false, leftA: false, leftB: false } }
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
    s' = { ...s, round: 1, gcPhase: 1 } }
  action outcomeB = all { s.phase == 1, s.b == 1, s.a == 2,
    s.lastGC == s.epoch * 10 + 1, s.gcPhase == 0,
    s' = { ...s, b: if(shouldFail) 3 else 2, xFreed: true,
      error: shouldFail, errorRoot: shouldFail, errorVersion: if(shouldFail) s.version else -1,
      yAlive: s.mode != 2, invalidSuffix: s.mode == 2,
      usedFreed: s.policy == 16 } }
  action requestGC2 = all { s.phase == 1, s.b >= 2, s.round == 1, s.gcPhase == 0,
    s' = { ...s, round: 2, gcPhase: 1 } }
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
    s' = { ...s, gcPhase: 2, staleGC: s.staleGC or not(allArrived), version: s.version + 1,
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
  action finishGC = all { s.phase == 1, s.gcPhase == 3,
    s' = { ...s, gcPhase: 0, lastGC: gcKey, testatorMarked: s.willOwner } }
  // Success must discharge Y before the no-future-callback cut.
  action cancelYOnSuccess = all { s.phase == 1, not(s.error), s.b == 2,
    s.lastGC == s.epoch * 10 + 2, s.gcPhase == 0, s.yAlive, s.yCalls == 0,
    s' = { ...s, yAlive: false, yCalls: 1, totalY: s.totalY + 1 } }
  action settlePreparation = all { s.phase == 1, s.a == 2, s.b >= 2,
    s.lastGC == s.epoch * 10 + 2, s.gcPhase == 0, not(s.p0Prepared),
    s.error or s.yCalls == 1,
    s' = { ...s, p0Prepared: true,
      yDisposition: if(not(s.error)) 3 else if(s.yAlive or s.policy == 8) 1 else 2 } }
  // Abstract typed handoff: values/continuations already on supported surviving owners.
  // This is a C refinement premise, NOT raw native frame migration.
  action prepareHandoff = all { s.phase == 1, s.p0Prepared, not(s.error), not(s.handoff),
    s' = { ...s, handoff: true, receiverB: true, receiverVB: s.version, framesElsewhere: true, willReceiver: true } }
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
  action consumeResult = all { s.common, allLeft, not(s.consumed), s' = { ...s, consumed: true } }
  action releaseResult = all { s.consumed, s.requestRoot or s.errorRoot,
    s' = { ...s, requestRoot: false, errorRoot: false } }
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
    finishGC, cancelYOnSuccess, settlePreparation, prepareHandoff, earlyReturn,
    releaseErrorEarly, replayX, decide, ackP0, ackA, ackB, commonCompletion,
    leaveP0, leaveA, leaveB, consumeResult, releaseResult, serviceYAfterAbort, nextEpoch, done }
  val strongCoverage = ((s.sourceA and s.cohort == 3 and s.frameA and s.versionA == s.version) or
      (s.receiverA and s.receiverVA == s.version)) and
    ((s.sourceB and s.cohort == 3 and s.frameB and s.versionB == s.version) or
      (s.receiverB and s.receiverVB == s.version))
  val resultCoverage = (s.phase == 0 or s.consumed or
      (s.requestRoot and s.rcRegistered and s.requestVersion == s.version)) and
    (not(s.error) or s.consumed or (s.errorRoot and s.rcRegistered and s.errorVersion == s.version))
  val framesCovered = s.cohort == 3 and s.frameA and s.frameB or s.framesElsewhere
  val weakSemantics = ((s.willOwner and s.cohort == 3) or s.willReceiver) and (not(s.willDecided) or (s.actionMarked and s.willExecutable))
  val serving = s.common or (s.cohort == 3 and not(s.left0) and not(s.leftA) and not(s.leftB))
  val closedDecision = s.phase != 2 or (s.p0Prepared and s.lastGC == s.epoch * 10 + 2)
  val queueSafe = s.aCalls <= 1 and s.bCalls <= 1 and s.yCalls <= 1 and not(s.xQueued) and not(s.usedFreed) and
    (not(s.resumed) or (not(s.invalidSuffix) and s.yDisposition == 1))
  val safe = strongCoverage and resultCoverage and framesCovered and weakSemantics and serving and
    closedDecision and queueSafe and not(s.staleGC) and not(s.staleAck) and not(s.badReuse)
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
  action gcRound = arriveA.then(arriveB).then(arriveP0).then(markStrong).then(determineWill).then(finishGC)
  action prepareFailingEpoch = startA.then(readyA).then(popAndStartB).then(requestGC1).then(gcRound)
    .then(outcomeB).then(requestGC2).then(gcRound).then(settlePreparation).then(decide)
    .then(ackA).then(ackP0).then(ackB).then(commonCompletion)
    .then(leaveB).then(leaveA).then(leaveP0).then(consumeResult).then(releaseResult)
  run combinedAbortAcrossTwoEpochs = initAbortTwice.then(openEpoch).then(prepareFailingEpoch)
    .expect(s.epoch == 1 and s.version == 2 and s.errorVersion == 2 and s.cohort == 3 and safe)
    .then(serviceYAfterAbort).then(nextEpoch).then(openEpoch)
    .expect(s.epoch == 2 and s.ack0 == 1 and s.arrival0 == 12 and s.bCalls == 0)
    .then(prepareFailingEpoch).then(serviceYAfterAbort)
    .expect(terminal and safe and s.version == 4 and s.totalA == 2 and s.totalB == 2 and s.totalY == 2)
  run abortThenSuccessfulHandoff = initAbortThenCommit.then(openEpoch).then(prepareFailingEpoch)
    .then(serviceYAfterAbort).then(nextEpoch).then(openEpoch)
    .then(startA).then(readyA).then(popAndStartB).then(requestGC1).then(gcRound)
    .then(outcomeB).then(requestGC2).then(gcRound).then(cancelYOnSuccess)
    .then(settlePreparation).then(prepareHandoff).then(decide)
    .then(ackB).then(ackA).then(ackP0).then(commonCompletion)
    .then(leaveA).then(leaveP0).then(leaveB).then(consumeResult).then(releaseResult)
    .expect(terminal and safe and s.cohort == 1 and s.version == 4 and s.framesElsewhere)
}
