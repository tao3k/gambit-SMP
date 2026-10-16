module host_environment_recovery {
  // Probe results and immutable receipt equality are external obligations.
  // A successful bind is not a lease, tool success, or native admission.
  type State = { observedDenial: bool, prelaunch: bool, sameEpoch: bool, freshAttempt: bool,
                 spentRetained: bool,
                 retained: bool, budget: bool, available: bool,
                 retried: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    observedDenial: true, prelaunch: true, sameEpoch: false, freshAttempt: true, spentRetained: true,
    retained: true, budget: true, available: false, retried: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  val eligible = s.observedDenial and s.prelaunch and (s.sameEpoch or s.freshAttempt) and s.spentRetained and
    s.retained and s.budget and s.available
  action observeAvailable = all { not(s.retried), not(s.available), s' = { ...s, available: true } }
  action invalidate = all { not(s.retried), any {
    all { s.observedDenial, s' = { ...s, observedDenial: false } },
    all { s.prelaunch, s' = { ...s, prelaunch: false } },
    all { s.freshAttempt, s' = { ...s, freshAttempt: false } },
    all { s.spentRetained, s' = { ...s, spentRetained: false } },
    all { s.retained, s' = { ...s, retained: false } },
    all { s.budget, s' = { ...s, budget: false } },
  } }
  action retry = all { not(s.retried), eligible or s.bypass, s' = { ...s, retried: true } }
  action hold = s' = s
  action step = any { observeAvailable, invalidate, retry, hold }
  val safe = s.retried implies eligible
  run observedTransitionTest = init.then(observeAvailable).then(retry)
    .then(all { assert(safe), assert(s.retried), s' = s })
  run unknownFailureTest = init.then(invalidate).then(observeAvailable)
    .then(all { assert(not(eligible)), assert(not(s.retried)), s' = s })
  run missingCurrentProbeTest = init.then(all { assert(not(eligible)), s' = s })
  run bypassControlTest = initBypass.then(observeAvailable).then(invalidate).then(retry)
    .then(all { assert(not(safe)), s' = s })
}
