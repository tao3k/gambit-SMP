module retained_completion_revalidation {
  // Exact hashes, quiescence and stage success are abstract observations.
  // Recovery rechecks a false-stale final verdict, never a failed stage.
  type State = { policy: str, stages: bool, exact: bool, journal: bool,
    finalBytes: bool, withinBudget: bool, quiescent: bool, recovered: bool,
    history: int, originalDenied: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, stages: true,
    exact: true, journal: true, finalBytes: true, withinBudget: true,
    quiescent: true, recovered: false, history: 3, originalDenied: true }
  action init = s' = initial("checked")
  action initFailed = s' = initial("failed-stage")
  action initDrift = s' = initial("drift")
  action initReset = s' = initial("reset")
  action stageFailure = all { not(s.recovered), s.stages, s' = { ...s, stages: false } }
  action drift = all { not(s.recovered), s.exact, s' = { ...s, exact: false } }
  action lose = all { not(s.recovered), s.finalBytes, s' = { ...s, finalBytes: false } }
  action exhaust = all { not(s.recovered), s.withinBudget, s' = { ...s, withinBudget: false } }
  action recover = all { not(s.recovered), s.journal, s.withinBudget, s.quiescent,
    (s.stages or s.policy == "failed-stage"),
    ((s.exact and s.finalBytes) or s.policy == "drift"),
    s' = { ...s, recovered: true,
      history: if (s.policy == "reset") 0 else s.history } }
  action hold = s' = s
  action step = any { stageFailure, drift, lose, exhaust, recover, hold }
  val allStages = s.recovered.implies(s.stages)
  val boundBytes = s.recovered.implies(s.exact and s.finalBytes and s.journal)
  val retainedHistory = s.history == 3 and s.originalDenied
  val safe = allStages and boundBytes and retainedHistory and
    s.recovered.implies(s.withinBudget and s.quiescent)
  val noStall = enabled(step)
  temporal progress = weakFair(recover, Set(s)).implies(eventually(
    s.recovered or not(s.stages and s.exact and s.finalBytes and s.withinBudget)))
  run retainedCompletionTest = init.then(recover)
    .then(all { assert(safe), assert(s.recovered), s' = s })
  run failedStageControlTest = initFailed.then(stageFailure).then(recover)
    .then(all { assert(not(allStages)), s' = s })
  run driftControlTest = initDrift.then(drift).then(recover)
    .then(all { assert(not(boundBytes)), s' = s })
  run resetControlTest = initReset.then(recover)
    .then(all { assert(not(retainedHistory)), s' = s })
}
