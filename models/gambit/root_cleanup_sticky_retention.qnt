module root_cleanup_sticky_retention {
  type State = { policy: str, phase: str, pending: bool, allocated: bool,
    original: int, reported: int, calls: int, setupAttempted: bool, setupAccepted: bool,
    pinRequested: bool, onP0: bool }
  var s: State
  pure def initialState(policy) = { policy: policy, phase: "ready",
    pending: false, allocated: true, original: 0, reported: 0, calls: 0,
    setupAttempted: false, setupAccepted: false, pinRequested: false, onP0: false }
  action init = s' = initialState("sticky")
  action initReset = s' = initialState("reset")
  action initOverwrite = s' = initialState("overwrite")
  action initMetadataOnly = s' = initialState("metadata-only")
  action pinCurrent = all { s.phase == "ready", not(s.pinRequested),
    s' = { ...s, pinRequested: true } }
  action dispatchRetainer = all { s.phase == "ready", not(s.onP0),
    s' = { ...s, pinRequested: true, onP0: true } }
  action beginCleanup = all { s.phase == "ready", s.onP0 or s.policy == "metadata-only",
    s' = { ...s, phase: "joining", pending: true } }
  action joinFailure = all { s.phase == "joining",
    s' = { ...s, phase: "retained", original: 71, reported: 71, calls: 1 } }
  action repeatCleanup = all { s.phase == "retained", s.calls < 3,
    s' = { ...s, reported: if (s.policy == "reset") 0 else s.original,
      calls: s.calls + 1 } }
  action attemptSetup = all { s.phase == "retained", not(s.setupAttempted),
    s' = { ...s, setupAttempted: true, setupAccepted: s.policy == "overwrite" } }
  val terminal = s.calls == 3 and s.setupAttempted
  action finished = all { terminal, s' = s }
  action step = any { pinCurrent, dispatchRetainer, beginCleanup, joinFailure,
    repeatCleanup, attemptSetup, finished }
  val safe = (not(s.pending) or s.allocated) and
    (s.phase == "ready" or s.onP0) and
    (s.phase != "retained" or (s.reported == s.original and not(s.setupAccepted)))
  val noStall = terminal or enabled(step)
  val contract = safe and noStall
  run retainedRepeatTest = init.then(dispatchRetainer).then(beginCleanup).then(joinFailure)
    .then(repeatCleanup).then(attemptSetup).then(repeatCleanup)
    .then(all { assert(safe), assert(terminal), s' = s })
  run resetErrorControlTest = initReset.then(dispatchRetainer).then(beginCleanup).then(joinFailure)
    .then(repeatCleanup).then(all { assert(not(safe)), s' = s })
  run setupOverwriteControlTest = initOverwrite.then(dispatchRetainer).then(beginCleanup).then(joinFailure)
    .then(attemptSetup).then(all { assert(not(safe)), s' = s })
  run metadataOnlyControlTest = initMetadataOnly.then(pinCurrent).then(beginCleanup)
    .then(all { assert(not(safe)), s' = s })
}
