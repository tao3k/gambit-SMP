module retirement_prepare_phase {
  // Old cohort = P0 + one retiring donor. One nested moving GC.
  // policy 0 corrected; 1 parent RESIZE still eligible; 2 parked P0;
  // 3 replay a failed callback; 4 source root dropped early;
  // 5 receiver bytes not registered; 6 commit despite callback failure;
  // 7 supported runtime throw escapes before the abort handshake.
  type State = { policy: int, outcome: int, phase: int, cohort: int,
    parentEligible: bool, resizeEntries: int, p0Serving: bool, p0Ready: bool,
    callback: int, calls: int, effects: bool, error: bool, escaped: bool,
    gc: int, gcDone: bool, p0Arrived: bool, donorArrived: bool,
    version: int, dRoot: bool, dVersion: int, rPresent: bool,
    rRoot: bool, rVersion: int, observed: bool,
    p0AbortAck: bool, donorAbortAck: bool, returned: bool }
  var s: State
  pure def initial(policy: int, outcome: int): State = {
    policy: policy, outcome: outcome, phase: 0, cohort: 2,
    parentEligible: false, resizeEntries: 0, p0Serving: true, p0Ready: false,
    callback: 0, calls: 0, effects: false, error: false, escaped: false,
    gc: 0, gcDone: false, p0Arrived: false, donorArrived: false,
    version: 0, dRoot: true, dVersion: 0, rPresent: false,
    rRoot: false, rVersion: -1, observed: false,
    p0AbortAck: false, donorAbortAck: false, returned: false }
  action initSuccess = s' = initial(0,0)
  action initReturnError = s' = initial(0,1)
  action initCaughtThrow = s' = initial(0,2)
  action initParentReplay = s' = initial(1,0)
  action initParkedCoordinator = s' = initial(2,0)
  action initCallbackReplay = s' = initial(3,1)
  action initEarlyRootDrop = s' = initial(4,0)
  action initUnregisteredReceiver = s' = initial(5,0)
  action initCommitOnError = s' = initial(6,1)
  action initEscapedThrow = s' = initial(7,2)
  action beginPrepare = all { s.phase == 0,
    s' = { ...s, phase: 1, resizeEntries: 1, parentEligible: s.policy == 1 } }
  // Ready does not mean permitted to leave collective service.
  action p0Ready = all { s.phase == 1, not(s.p0Ready),
    s' = { ...s, p0Ready: true, p0Serving: s.policy != 2 } }
  action enterCallback = all { s.phase == 1, s.callback == 0,
    s' = { ...s, callback: 1, calls: s.calls + 1, effects: true } }
  action requestGC = all { s.phase == 1, s.callback == 1, not(s.gcDone), s.gc == 0,
    s' = { ...s, gc: 1 } }
  // The original priority RESIZE(2) < GC(3) must not re-elect the parent.
  action replayResize = all { s.phase == 1, s.gc == 1, s.parentEligible,
    s' = { ...s, resizeEntries: s.resizeEntries + 1 } }
  action arriveP0 = all { s.phase == 1, s.gc == 1, not(s.parentEligible),
    s.p0Serving, not(s.p0Arrived), s' = { ...s, p0Arrived: true } }
  action arriveDonor = all { s.phase == 1, s.gc == 1, not(s.parentEligible),
    not(s.donorArrived), s' = { ...s, donorArrived: true } }
  action finishGC = all { s.phase == 1, s.gc == 1, s.p0Arrived, s.donorArrived,
    s' = { ...s, gc: 0, gcDone: true, version: s.version + 1,
      dVersion: if (s.dRoot) s.version + 1 else s.dVersion,
      rVersion: if (s.rRoot) s.version + 1 else s.rVersion } }
  action callbackOutcome = all { s.phase == 1, s.callback == 1, s.gcDone,
    s' = { ...s, callback: if (s.outcome == 0) 2 else 3,
      error: s.outcome != 0, escaped: s.policy == 7 and s.outcome == 2 } }
  action retryFailed = all { s.phase == 1, s.policy == 3, s.callback == 3,
    s' = { ...s, callback: 0 } }
  // May publish before/after nested GC; both root locations are updated by it.
  action publishReceiver = all { s.phase == 1, not(s.rPresent),
    s' = { ...s, rPresent: true, rRoot: s.policy != 5, rVersion: s.dVersion } }
  action observeReceiver = all { s.phase == 1, s.rPresent, not(s.observed),
    (s.rRoot and s.rVersion == s.version) or s.policy == 5,
    s' = { ...s, observed: true } }
  action dropDonorRoot = all { s.phase == 1, s.dRoot,
    s.policy == 4 or (s.callback == 2 and s.gcDone and s.observed),
    s' = { ...s, dRoot: false } }
  action commit = all { s.phase == 1, s.p0Ready, s.gc == 0,
    (s.callback == 2 and s.gcDone and s.observed and not(s.dRoot)) or
      (s.policy == 6 and s.callback == 3),
    s' = { ...s, phase: 4, cohort: 1, returned: true } }
  // Abort keeps old cohort and donor root; no destructive ownership undo.
  action beginAbort = all { s.phase == 1, s.callback == 3, s.p0Ready,
    s.gc == 0, not(s.escaped), s' = { ...s, phase: 5 } }
  action ackAbortP0 = all { s.phase == 5, not(s.p0AbortAck),
    s' = { ...s, p0AbortAck: true } }
  action ackAbortDonor = all { s.phase == 5, not(s.donorAbortAck),
    s' = { ...s, donorAbortAck: true } }
  action finishAbort = all { s.phase == 5, s.p0AbortAck, s.donorAbortAck,
    s' = { ...s, phase: 6, returned: true, rPresent: false, rRoot: false, observed: false } }
  val terminal = s.phase == 4 or s.phase == 6
  action done = all { terminal, s' = s }
  action step = any { beginPrepare, p0Ready, enterCallback, requestGC,
    replayResize, arriveP0, arriveDonor, finishGC, callbackOutcome,
    retryFailed, publishReceiver, observeReceiver, dropDonorRoot,
    commit, beginAbort, ackAbortP0, ackAbortDonor, finishAbort, done }
  val rootsCovered = (s.dRoot and s.dVersion == s.version) or
    (s.rRoot and s.rVersion == s.version)
  val onceOnly = s.resizeEntries <= 1 and s.calls <= 1
  val serviceUntilDecision = s.gc == 0 or (s.p0Serving and s.cohort == 2)
  val commitAfterSuccess = s.phase != 4 or
    (not(s.error) and s.callback == 2 and s.gcDone and s.rRoot and s.rVersion == s.version)
  val safeAbort = s.phase != 6 or (s.cohort == 2 and s.dRoot and s.p0AbortAck and s.donorAbortAck)
  val caughtBeforeReturn = not(s.escaped)
  val safe = rootsCovered and onceOnly and serviceUntilDecision and
    commitAfterSuccess and safeAbort and caughtBeforeReturn
  // Correct-policy graph is finite and has no nonterminal stutter/cycle.
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
  run movingGCUpdatesBothRoots = initSuccess.then(beginPrepare).then(p0Ready)
    .then(enterCallback).then(publishReceiver).then(observeReceiver).then(requestGC)
    .then(arriveDonor).then(arriveP0).then(finishGC)
    .expect(s.version == 1 and s.dVersion == 1 and s.rVersion == 1 and safe)
    .then(callbackOutcome).then(dropDonorRoot).then(commit).expect(terminal and safe)
  run failedCallbackDoesNotReplay = initReturnError.then(beginPrepare).then(enterCallback)
    .then(requestGC).then(arriveP0).then(arriveDonor).then(finishGC)
    .then(publishReceiver).then(callbackOutcome).then(p0Ready).then(beginAbort)
    .then(ackAbortDonor).then(ackAbortP0).then(finishAbort)
    .expect(s.phase == 6 and s.effects and s.calls == 1 and s.cohort == 2 and safe)
}
