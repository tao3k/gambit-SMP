module execution_finalization_custody {
  // Completion, evidence custody and performance admission are distinct facts.
  type State = { policy: str, completed: bool, quiescent: bool,
    exceeded: bool, grace: bool, receipt: bool, killed: bool,
    performancePass: bool, historicalFailures: int }
  var s: State
  pure def initial(policy: str): State = { policy: policy, completed: false,
    quiescent: false, exceeded: false, grace: false, receipt: false,
    killed: false, performancePass: false, historicalFailures: 1 }
  action init = s' = initial("checked")
  action initWallKill = s' = initial("wall-kill")
  action initFalsePass = s' = initial("false-pass")
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
  action step = any { complete, expire, commit, hold }
  val preserveCompleted = (s.completed and s.exceeded).implies(not(s.killed))
  val honestPerformance = s.performancePass.implies(s.receipt and not(s.exceeded))
  val retainedFailures = s.historicalFailures == 1
  val safe = preserveCompleted and honestPerformance and retainedFailures
  run completedOverrunTest = init.then(complete).then(expire).then(commit)
    .then(all { assert(safe), assert(s.receipt), assert(not(s.performancePass)), s' = s })
  run unfinishedTimeoutTest = init.then(expire)
    .then(all { assert(s.killed), assert(not(s.receipt)), s' = s })
  run wallKillControlTest = initWallKill.then(complete).then(expire)
    .then(all { assert(not(preserveCompleted)), s' = s })
  run falsePassControlTest = initFalsePass.then(complete).then(expire).then(commit)
    .then(all { assert(not(honestPerformance)), s' = s })
}
