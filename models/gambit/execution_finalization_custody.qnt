module execution_finalization_custody {
  // Completion, evidence custody and performance admission are distinct facts.
  type State = { policy: str, completed: bool, quiescent: bool,
    exceeded: bool, grace: bool, receipt: bool, killed: bool,
    performancePass: bool, historicalFailures: int,
    ownerPhase: int, ownerExpired: bool, ownerForced: bool, ownerAdmitted: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, completed: false,
    quiescent: false, exceeded: false, grace: false, receipt: false,
    killed: false, performancePass: false, historicalFailures: 1,
    ownerPhase: 0, ownerExpired: false, ownerForced: false, ownerAdmitted: false }
  action init = s' = initial("checked")
  action initWallKill = s' = initial("wall-kill")
  action initFalsePass = s' = initial("false-pass")
  action initReviewClock = s' = initial("review-clock")
  action complete = all { not(s.completed), not(s.killed),
    s' = { ...s, completed: true, quiescent: true } }
  action expire = all { not(s.exceeded), not(s.receipt),
    s' = { ...s, exceeded: true,
      grace: s.completed and s.quiescent and s.policy != "wall-kill",
      killed: not(s.completed and s.quiescent) or s.policy == "wall-kill" } }
  action commit = all { s.completed, s.quiescent, not(s.killed), not(s.receipt),
    s' = { ...s, receipt: true,
      performancePass: not(s.exceeded) or s.policy == "false-pass" } }
  action hold = s' = s
  // A completed recipe begins a separate, configured owner-close window.
  // Expiry of its former review window is not expiry of this new phase.
  action beginOwnerClose = all { s.completed, s.quiescent, not(s.killed), s.ownerPhase == 0,
    s' = { ...s, ownerPhase: 1 } }
  action ownerExits = all { s.ownerPhase == 1, not(s.ownerExpired),
    s' = { ...s, ownerPhase: 2,
      ownerAdmitted: s.policy != "review-clock" or not(s.exceeded) } }
  action ownerStalls = all { s.ownerPhase == 1,
    s' = { ...s, ownerPhase: 3, ownerExpired: true, ownerForced: true } }
  action step = any { complete, expire, commit, beginOwnerClose, ownerExits, ownerStalls, hold }
  val preserveCompleted = (s.completed and s.exceeded).implies(not(s.killed))
  val honestPerformance = s.performancePass.implies(s.receipt and not(s.exceeded))
  val retainedFailures = s.historicalFailures == 1
  val truthfulOwner = (s.ownerPhase == 2).implies(s.ownerAdmitted) and
    s.ownerAdmitted.implies(not(s.ownerForced) and not(s.ownerExpired))
  val safe = preserveCompleted and honestPerformance and retainedFailures and truthfulOwner
  run completedOverrunTest = init.then(complete).then(expire).then(commit)
    .then(all { assert(safe), assert(s.receipt), assert(not(s.performancePass)), s' = s })
  run unfinishedTimeoutTest = init.then(expire)
    .then(all { assert(s.killed), assert(not(s.receipt)), s' = s })
  run wallKillControlTest = initWallKill.then(complete).then(expire)
    .then(all { assert(not(preserveCompleted)), s' = s })
  run falsePassControlTest = initFalsePass.then(complete).then(expire).then(commit)
    .then(all { assert(not(honestPerformance)), s' = s })
  run completedReviewDoesNotExpireOwnerTest = init.then(complete).then(expire)
    .then(beginOwnerClose).then(ownerExits)
    .then(all { assert(safe), assert(s.ownerAdmitted), assert(not(s.performancePass)), s' = s })
  run oldReviewClockRejectsReapedOwnerTest = initReviewClock.then(complete).then(expire)
    .then(beginOwnerClose).then(ownerExits)
    .then(all { assert(not(truthfulOwner)), assert(not(s.ownerForced)), s' = s })
  run stalledOwnerRemainsRejectedTest = init.then(complete).then(beginOwnerClose).then(ownerStalls)
    .then(all { assert(safe), assert(s.ownerForced), assert(not(s.ownerAdmitted)), s' = s })
}
