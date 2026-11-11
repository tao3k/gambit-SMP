module retirement_epoch_queue_roots {
  // Composes with the multi-donor service model, not a replacement collector.
  // Exactly two preparation epochs. Each invokes X, keeps never-invoked Y.
  // Policies 1 use freed X; 2 reattach dead Y; 3 requeue invoked X;
  // 4 accept epoch-1 acks in epoch 2; 5 put SCMOBJ in unscanned RC payload;
  // 6 strongify will testator; 7 withdraw frame root; 8 drop will-list owner;
  // 9 resume despite invalid suffix; 10 carry callback cursor into epoch 2.
  type State = { policy: int, independentSuffix: bool, epoch: int, phase: int,
    xCalls: int, totalXCalls: int, xFreed: bool, cursorAdvanced: bool,
    yAlive: bool, yDisposition: int, yCalls: int, totalYCalls: int,
    xQueued: bool, usedFreed: bool, lostSuffix: bool,
    ack0: int, ackA: int, ackB: int, staleAckUsed: bool,
    gcPhase: int, version: int, rcRegistered: bool, rcVersion: int,
    frameRegistered: bool, frameVersion: int, willOwner: bool,
    actionMarked: bool, testatorMarked: bool, willExecutable: bool,
    willDecided: bool, errorRoot: bool, errorConsumed: bool,
    common: bool, resumed: bool, terminalRetained: bool }
  var s: State
  pure def initial(policy: int, independentSuffix: bool): State = {
    policy: policy, independentSuffix: independentSuffix, epoch: 0, phase: 0,
    xCalls: 0, totalXCalls: 0, xFreed: false, cursorAdvanced: false,
    yAlive: false, yDisposition: 0, yCalls: 0, totalYCalls: 0,
    xQueued: false, usedFreed: false, lostSuffix: false,
    ack0: 0, ackA: 0, ackB: 0, staleAckUsed: false,
    gcPhase: 0, version: 0, rcRegistered: true, rcVersion: 0,
    frameRegistered: true, frameVersion: 0, willOwner: true,
    actionMarked: false, testatorMarked: false, willExecutable: false,
    willDecided: false, errorRoot: false, errorConsumed: false,
    common: false, resumed: false, terminalRetained: false }
  action initResumeTwoEpochs = s' = initial(0,true)
  action initInvalidSuffixRetained = s' = initial(0,false)
  action initFreedCursor = s' = initial(1,true)
  action initBlindReattach = s' = initial(2,false)
  action initReplayInvoked = s' = initial(3,true)
  action initStaleEpoch = s' = initial(4,true)
  action initUnscannedPayload = s' = initial(5,true)
  action initStrongifyWeak = s' = initial(6,true)
  action initWithdrawFrame = s' = initial(7,true)
  action initDropWillOwner = s' = initial(8,true)
  action initUnsafeResume = s' = initial(9,false)
  action initStaleCursor = s' = initial(10,true)
  // Epoch 2 is admitted only after the old result and reattached Y are consumed.
  action openEpoch = all { s.phase == 0, s.epoch < 2,
    s' = { ...s, epoch: s.epoch + 1, phase: 1,
      xCalls: if(s.policy == 10 and s.epoch == 1) s.xCalls else 0,
      xFreed: false, cursorAdvanced: false, yAlive: true, yDisposition: 0,
      yCalls: 0, xQueued: false, gcPhase: 0,
      rcRegistered: s.policy != 5, rcVersion: s.version,
      frameRegistered: s.policy != 7, frameVersion: s.version,
      willOwner: s.policy != 8, actionMarked: false, testatorMarked: false,
      willExecutable: false, willDecided: false,
      errorRoot: false, errorConsumed: false, common: false, resumed: false } }
  // Atomic detach under queue mutex; callback executes only after unlock.
  // Producer drain and non-sharing of Y are explicit caller premises.
  action detach = all { s.phase == 1,
    s' = { ...s, phase: 2, cursorAdvanced: s.policy != 1 } }
  action invokeX = all { s.phase == 2,
    s' = { ...s, phase: 3, xCalls: s.xCalls + 1, totalXCalls: s.totalXCalls + 1,
      xFreed: true, yAlive: s.independentSuffix, errorRoot: true,
      usedFreed: not(s.cursorAdvanced), xQueued: s.policy == 3 } }
  action markStrongRoots = all { s.phase == 3, s.gcPhase == 0,
    s' = { ...s, gcPhase: 1, version: s.version + 1,
      rcVersion: if(s.rcRegistered) s.version + 1 else s.rcVersion,
      frameVersion: if(s.frameRegistered) s.version + 1 else s.frameVersion,
      actionMarked: s.willOwner, testatorMarked: s.policy == 6 } }
  // Isolated testator: no other strong path. Strongification suppresses execution.
  action determineWill = all { s.phase == 3, s.gcPhase == 1,
    s' = { ...s, gcPhase: 2, willDecided: true,
      willExecutable: s.willOwner and not(s.testatorMarked) } }
  action processWill = all { s.phase == 3, s.gcPhase == 2,
    s' = { ...s, gcPhase: 3, testatorMarked: s.willOwner } }
  action disposeSuffix = all { s.phase == 3, s.gcPhase == 3,
    s' = { ...s, phase: 4,
      yDisposition: if(s.yAlive or s.policy == 2) 1 else 2,
      lostSuffix: not(s.yAlive) and s.policy == 2 } }
  action ackP0 = all { s.phase == 4, s.ack0 != s.epoch,
    s' = { ...s, ack0: s.epoch } }
  action ackA = all { s.phase == 4, s.ackA != s.epoch,
    s' = { ...s, ackA: s.epoch } }
  action ackB = all { s.phase == 4, s.ackB != s.epoch,
    s' = { ...s, ackB: s.epoch } }
  action completeAbort = all { s.phase == 4,
    (s.ack0 == s.epoch and s.ackA == s.epoch and s.ackB == s.epoch) or
      (s.policy == 4 and s.epoch == 2 and s.ack0 > 0 and s.ackA > 0 and s.ackB > 0),
    s' = { ...s, phase: 5, common: true,
      staleAckUsed: not(s.ack0 == s.epoch and s.ackA == s.epoch and s.ackB == s.epoch),
      resumed: s.yDisposition == 1 or s.policy == 9,
      terminalRetained: s.yDisposition == 2 } }
  action consumeError = all { s.phase == 5, not(s.errorConsumed),
    s' = { ...s, errorConsumed: true } }
  action releaseError = all { s.phase == 5, s.errorConsumed, s.errorRoot,
    s' = { ...s, errorRoot: false } }
  action runNeverInvokedY = all { s.phase == 5, s.resumed, s.yAlive,
    s.errorConsumed, not(s.errorRoot), s.yCalls == 0,
    s' = { ...s, yCalls: 1, totalYCalls: s.totalYCalls + 1, yAlive: false } }
  action nextEpoch = all { s.phase == 5, s.epoch == 1,
    s.resumed, s.yCalls == 1, not(s.errorRoot), s' = { ...s, phase: 0 } }
  val terminal = s.phase == 5 and s.errorConsumed and not(s.errorRoot) and
    (s.terminalRetained or (s.epoch == 2 and s.yCalls == 1))
  action done = all { terminal, s' = s }
  action step = any { openEpoch, detach, invokeX, markStrongRoots, determineWill,
    processWill, disposeSuffix, ackP0, ackA, ackB, completeAbort, consumeError,
    releaseError, runNeverInvokedY, nextEpoch, done }
  val queueSafe = not(s.usedFreed) and not(s.xQueued) and not(s.lostSuffix) and s.xCalls <= 1 and s.yCalls <= 1
  val rootsSafe = s.gcPhase == 0 or
    (s.rcRegistered and s.rcVersion == s.version and
     s.frameRegistered and s.frameVersion == s.version and s.willOwner and s.actionMarked)
  val weakSemantics = not(s.willDecided) or s.willExecutable
  val resumeSafe = not(s.resumed) or (s.common and s.yDisposition == 1 and not(s.terminalRetained))
  val safe = queueSafe and rootsSafe and weakSemantics and resumeSafe and not(s.staleAckUsed)
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
  action finishOneEpoch = detach.then(invokeX).then(markStrongRoots).then(determineWill)
    .then(processWill).then(disposeSuffix).then(ackA).then(ackP0).then(ackB)
    .then(completeAbort).then(consumeError).then(releaseError)
  run reuseResetsCursorAndRejectsOldAcks = initResumeTwoEpochs.then(openEpoch)
    .then(finishOneEpoch).then(runNeverInvokedY).then(nextEpoch).then(openEpoch)
    .expect(s.epoch == 2 and s.ack0 == 1 and s.ackA == 1 and s.ackB == 1 and s.xCalls == 0)
    .then(finishOneEpoch).then(runNeverInvokedY)
    .expect(terminal and safe and s.totalXCalls == 2 and s.totalYCalls == 2)
  run invalidSuffixPreventsResume = initInvalidSuffixRetained.then(openEpoch).then(finishOneEpoch)
    .expect(terminal and safe and s.terminalRetained and not(s.resumed) and s.yCalls == 0)
}
