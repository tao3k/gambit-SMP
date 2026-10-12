module interrupted_producer_recovery {
  // Equality tokens abstract verified hashes. Time includes downtime; no clock reset.
  // A checkpoint restores evidence, not an unobserved process or a new budget.
  type State = { phase: int, passed: bool, committed: bool, quiescent: bool,
    current: int, bound: int, spent: int, actualSpent: int,
    bypassReceipt: bool, bypassIdentity: bool, bypassQuiescence: bool,
    resetBudget: bool, launched: bool }
  var s: State
  pure def initial(receipt: bool, identity: bool, quiescence: bool, reset: bool): State = {
    phase: 0, passed: false, committed: false, quiescent: true,
    current: 0, bound: 0, spent: 0, actualSpent: 0,
    bypassReceipt: receipt, bypassIdentity: identity,
    bypassQuiescence: quiescence, resetBudget: reset, launched: false,
  }
  action init = s' = initial(false, false, false, false)
  action initMissing = s' = initial(true, false, false, false)
  action initStale = s' = initial(false, true, false, false)
  action initLive = s' = initial(true, false, true, false)
  action initReset = s' = initial(false, false, false, true)
  action start = all {
    s.phase == 0, s.spent + 1 <= 3,
    s' = { ...s, phase: 1, quiescent: false,
      spent: s.spent + 1, actualSpent: s.actualSpent + 1 },
  }
  action finish = all {
    s.phase == 1,
    s' = { ...s, phase: 2, passed: true, quiescent: true },
  }
  // This boundary represents an atomic durable receipt plus all output bindings.
  // A log line or an in-memory result does not constitute this commit.
  action commit = all {
    s.phase == 2, not(s.committed),
    s' = { ...s, committed: true, bound: s.current },
  }
  action interrupt = all {
    Set(1, 2).contains(s.phase), s' = { ...s, phase: 3 },
  }
  action elapsed = all {
    not(s.launched), s.actualSpent < 5,
    s' = { ...s, spent: s.spent + 1, actualSpent: s.actualSpent + 1 },
  }
  action drift = all {
    Set(3, 4).contains(s.phase), s.current == 0, s' = { ...s, current: 1 },
  }
  action reset = all {
    s.phase == 3, s.resetBudget, s.spent > 0, s' = { ...s, spent: 0 },
  }
  val admissible = ((s.committed and s.passed) or s.bypassReceipt) and
    (s.current == s.bound or s.bypassIdentity) and
    (s.quiescent or s.bypassQuiescence) and s.spent + 1 <= 3
  action recover = all {
    s.phase == 3, admissible,
    s' = { ...s, phase: 4 },
  }
  // Repeat the same checks at consumption: recovery is not perpetual admission.
  action launch = all {
    s.phase == 4, admissible,
    s' = { ...s, phase: 5, launched: true, spent: s.spent + 1,
      actualSpent: s.actualSpent + 1 },
  }
  action hold = s' = s
  action step = any { start, finish, commit, interrupt, elapsed, drift, reset, recover, launch, hold }
  val qualified = s.launched.implies(s.committed and s.passed)
  val identity = s.launched.implies(s.current == s.bound)
  val teardown = s.launched.implies(s.quiescent)
  val budget = s.spent == s.actualSpent and s.launched.implies(s.actualSpent <= 3)
  val safe = qualified and identity and teardown and budget
  run resumedCommittedTest = init.then(start).then(finish).then(commit)
    .then(interrupt).then(elapsed).then(recover).then(launch)
    .then(all { assert(s.launched), assert(safe), s' = s })
  run interruptedRunningTest = init.then(start).then(interrupt)
    .then(all { assert(not(s.committed)), assert(not(s.quiescent)), assert(safe), s' = s })
  run expiredCheckpointTest = init.then(start).then(finish).then(commit)
    .then(interrupt).then(elapsed).then(elapsed)
    .then(all { assert(s.committed), assert(not(admissible)), assert(safe), s' = s })
  run postRecoveryDriftTest = init.then(start).then(finish).then(commit)
    .then(interrupt).then(recover).then(drift)
    .then(all { assert(s.phase == 4), assert(not(admissible)), assert(safe), s' = s })
  run missingReceiptControlTest = initMissing.then(start).then(finish)
    .then(interrupt).then(recover).then(launch)
    .then(all { assert(not(qualified)), s' = s })
  run staleOutputControlTest = initStale.then(start).then(finish).then(commit)
    .then(interrupt).then(drift).then(recover).then(launch)
    .then(all { assert(not(identity)), s' = s })
  run liveProcessControlTest = initLive.then(start).then(interrupt).then(recover).then(launch)
    .then(all { assert(not(teardown)), s' = s })
  run deadlineResetControlTest = initReset.then(start).then(finish).then(commit)
    .then(interrupt).then(elapsed).then(elapsed).then(reset).then(recover).then(launch)
    .then(all { assert(not(budget)), s' = s })
}
