module completed_producer_handoff {
  // A completed stage certificate is not continuation of a live/failed job.
  // Equality and observed completion are external verified obligations.
  type State = { passed: bool, quiescent: bool, twoPass: bool, exact: bool,
                 producerSpent: int, retainedSpent: int, consumerSpent: int,
                 loaded: bool, reviewed: bool, launched: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    passed: true, quiescent: true, twoPass: true, exact: true,
    producerSpent: 2, retainedSpent: 2, consumerSpent: 0,
    loaded: false, reviewed: false, launched: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  val producerQualified = s.passed and s.quiescent and s.twoPass and s.exact
  val budgetRetained = s.retainedSpent == s.producerSpent
  action load = all {
    not(s.loaded), not(s.launched),
    (producerQualified and budgetRetained) or s.bypass,
    s' = { ...s, loaded: true },
  }
  action review = all {
    s.loaded, not(s.reviewed), not(s.launched),
    s' = { ...s, reviewed: true, consumerSpent: s.consumerSpent + 1 },
  }
  action launch = all {
    s.loaded, s.reviewed, not(s.launched), s.consumerSpent + 1 <= 3,
    (producerQualified and budgetRetained) or s.bypass,
    s' = { ...s, launched: true, consumerSpent: s.consumerSpent + 1 },
  }
  action invalidate = all {
    not(s.launched),
    any {
      all { s.passed, s' = { ...s, passed: false } },
      all { s.quiescent, s' = { ...s, quiescent: false } },
      all { s.twoPass, s' = { ...s, twoPass: false } },
      all { s.exact, s' = { ...s, exact: false } },
    },
  }
  action resetProducerCharge = all {
    not(s.launched), s.bypass, s.retainedSpent > 0,
    s' = { ...s, retainedSpent: 0 },
  }
  action consume = all {
    not(s.launched), s.consumerSpent < 3,
    s' = { ...s, consumerSpent: s.consumerSpent + 1 },
  }
  action hold = s' = s
  action step = any { load, review, launch, invalidate, resetProducerCharge, consume, hold }
  val safe = s.launched implies
    (producerQualified and budgetRetained and s.consumerSpent <= 3)
  run completedHandoffTest = init.then(load).then(review).then(launch)
    .then(all { assert(safe), assert(s.launched), s' = s })
  run loadedIsNotAdmissionTest = init.then(load)
    .then(all { assert(not(s.launched)), assert(not(s.reviewed)), s' = s })
  run driftAfterReviewTest = init.then(load).then(review).then(invalidate)
    .then(all { assert(not(producerQualified)), assert(not(s.launched)), s' = s })
  run failedCertificateControlTest = initBypass.then(invalidate).then(load).then(review).then(launch)
    .then(all { assert(not(safe)), s' = s })
  run producerChargeResetControlTest = initBypass.then(load).then(review).then(resetProducerCharge).then(launch)
    .then(all { assert(not(safe)), assert(s.producerSpent == 2), s' = s })
}
