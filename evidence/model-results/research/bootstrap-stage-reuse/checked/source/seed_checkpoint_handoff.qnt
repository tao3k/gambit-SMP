module seed_checkpoint_handoff {
  // Finite transport contract, not a proof of C refinement or GC correctness.
  // Exactness includes generator, dependency closure, source, profile and tools.
  type State = { exact: bool, quiescent: bool, closure: bool,
                 charged: int, spent: int, loaded: bool, reviewed: bool,
                 bootstrapped: bool, admitted: bool, parentDeny: bool,
                 expired: bool, resumed: bool, bypass: bool, reset: bool }
  var s: State
  pure def initial(bypass: bool, reset: bool): State = {
    exact: true, quiescent: true, closure: true, charged: 3, spent: 0,
    loaded: false, reviewed: false, bootstrapped: false, admitted: false,
    parentDeny: true, expired: true, resumed: false, bypass: bypass, reset: reset,
  }
  action init = s' = initial(false, false)
  action initBypass = s' = initial(true, false)
  action initReset = s' = initial(false, true)
  val bound = s.exact and s.quiescent and s.closure
  val retained = s.charged == 3
  action load = all {
    not(s.loaded), not(s.bootstrapped), bound, retained,
    s' = { ...s, loaded: true },
  }
  action review = all {
    s.loaded, not(s.reviewed), not(s.bootstrapped), bound, retained,
    s.spent < 3, s' = { ...s, reviewed: true, spent: s.spent + 1 },
  }
  action bootstrap = all {
    s.loaded, not(s.bootstrapped), s.spent < 3,
    (s.reviewed and bound and retained) or s.bypass,
    s' = { ...s, bootstrapped: true, admitted: true, spent: s.spent + 1 },
  }
  action drift = all {
    not(s.bootstrapped),
    any {
      all { s.exact, s' = { ...s, exact: false } },
      all { s.quiescent, s' = { ...s, quiescent: false } },
      all { s.closure, s' = { ...s, closure: false } },
    },
  }
  action resetCharge = all {
    s.reset, not(s.bootstrapped), s.charged > 0,
    s' = { ...s, charged: 0 },
  }
  action hold = s' = s
  action step = any { load, review, bootstrap, drift, resetCharge, hold }
  val safe = all {
    s.parentDeny, not(s.resumed),
    s.admitted implies (s.bootstrapped and s.reviewed and bound and retained),
    retained, s.charged + s.spent <= 6,
  }
  run checkedHandoffTest = init.then(load).then(review).then(bootstrap)
    .then(all { assert(safe), assert(s.admitted), s' = s })
  run seedIsNotRuntimeTest = init.then(load)
    .then(all { assert(safe), assert(not(s.admitted)), s' = s })
  run expiredIsNotResumeTest = init.then(load).then(review)
    .then(all { assert(s.expired), assert(not(s.resumed)), assert(s.parentDeny), s' = s })
  run sourceDriftTest = init.then(load).then(review).then(drift)
    .then(all { assert(not(bound)), assert(not(s.admitted)), s' = s })
  run reviewBypassControlTest = initBypass.then(load).then(bootstrap)
    .then(all { assert(not(safe)), s' = s })
  run chargeResetControlTest = initReset.then(load).then(resetCharge)
    .then(all { assert(not(safe)), s' = s })
}
