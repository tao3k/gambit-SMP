module retired_rc_exit_tail {
  import retired_rc_gc_visibility as R from "./retired_rc_gc_visibility"
  // POSIX exit executes cleanup/TLS callbacks. A callback allocating another
  // donor root is an explicit FFI premise, not an observed Gambit corruption.
  var exitPhase: str
  var policy: str
  var badTailUse: bool
  action init = all { R::s' = R::initial("ack-transfer-before-resume"),
    exitPhase' = "before-exit", policy' = "after-tail", badTailUse' = false }
  action initPreExitAck = all { R::s' = R::initial("ack-transfer-before-resume"),
    exitPhase' = "before-exit", policy' = "pre-exit", badTailUse' = false }
  action keepExit = all { exitPhase' = exitPhase, policy' = policy,
    badTailUse' = badTailUse }
  action shrink = all { R::shrink, keepExit }
  action joinFailure = all { R::joinFails, keepExit }
  action handoff = all { R::transfer, keepExit }
  action resume = all { R::returnResult, keepExit }
  action gc = all { R::collect, keepExit }
  action rootStep = all {
    any { R::shrink, R::joinFails, R::transfer, R::returnResult, R::collect,
      R::retry, R::recovered, R::reclaim },
    exitPhase' = exitPhase, policy' = policy, badTailUse' = badTailUse }
  action beginExit = all { R::s.phase != "active", exitPhase == "before-exit",
    exitPhase' = "callback", R::s' = R::s, policy' = policy, badTailUse' = badTailUse }
  action callback = all { exitPhase == "callback",
    exitPhase' = "done", policy' = policy,
    badTailUse' = (badTailUse or (R::s.rootAtOwner and not(R::s.joined))),
    // A new donor RC entry is not in the previously transferred owner list.
    R::s' = { ...R::s, rootAtOwner: false, rootEpoch: 0 } }
  action acknowledge = all {
    (exitPhase == "done" or (policy == "pre-exit" and exitPhase == "before-exit")),
    R::donorStops, exitPhase' = exitPhase, policy' = policy, badTailUse' = badTailUse }
  action joined = all { exitPhase == "done", R::joinSucceeds,
    exitPhase' = exitPhase, policy' = policy, badTailUse' = badTailUse }
  val terminal = R::terminal and exitPhase == "done"
  action finished = all { terminal, R::s' = R::s, exitPhase' = exitPhase,
    policy' = policy, badTailUse' = badTailUse }
  action step = any { rootStep, beginExit, callback, acknowledge, joined, finished }
  val safe = R::safe and not(badTailUse)
  val noStall = terminal or enabled(step)
  run preExitAckControlTest = initPreExitAck.then(shrink).then(joinFailure)
    .then(acknowledge).then(handoff).then(beginExit).then(callback)
    .then(all { assert(badTailUse), assert(not(safe)), R::s' = R::s,
      exitPhase' = exitPhase, policy' = policy, badTailUse' = badTailUse })
  run tailBeforeHandoffTest = init.then(shrink).then(joinFailure)
    .then(beginExit).then(callback).then(acknowledge).then(handoff)
    .then(resume).then(gc)
    .then(all { assert(safe), assert(R::s.pending), R::s' = R::s,
      exitPhase' = exitPhase, policy' = policy, badTailUse' = badTailUse })
}
