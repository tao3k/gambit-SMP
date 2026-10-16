module native_environment_correspondence {
  // Probe authenticity, same-run provenance and syscall meaning are source obligations.
  // A current permission observation is not a lease or a successful full native test.
  type State = { recordedPermissionDenial: bool, controlledEnvironmentCause: bool,
    originalRetained: bool, originalBudgetBound: bool, sameRun: bool,
    currentProducerBound: bool, operationBound: bool, probeComplete: bool,
    probeAvailable: bool, reviewed: bool, used: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    recordedPermissionDenial: true, controlledEnvironmentCause: false,
    originalRetained: true, originalBudgetBound: true, sameRun: true,
    currentProducerBound: true, operationBound: true, probeComplete: false,
    probeAvailable: false, reviewed: false, used: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  val eligible = (s.recordedPermissionDenial or s.controlledEnvironmentCause) and
    s.originalRetained and s.originalBudgetBound and s.sameRun and
    s.currentProducerBound and s.operationBound and s.probeComplete and
    s.probeAvailable and s.reviewed
  action observe = all { not(s.used), not(s.probeComplete),
    s' = { ...s, probeComplete: true, probeAvailable: true } }
  action control = all { not(s.used), s.recordedPermissionDenial,
    s' = { ...s, recordedPermissionDenial: false, controlledEnvironmentCause: true } }
  action review = all { not(s.used), not(s.reviewed), s' = { ...s, reviewed: true } }
  action invalidate = all { not(s.used), any {
    all { s.originalRetained, s' = { ...s, originalRetained: false } },
    all { s.originalBudgetBound, s' = { ...s, originalBudgetBound: false } },
    all { s.sameRun, s' = { ...s, sameRun: false } },
    all { s.currentProducerBound, s' = { ...s, currentProducerBound: false } },
    all { s.operationBound, s' = { ...s, operationBound: false } },
    all { s.probeAvailable, s' = { ...s, probeAvailable: false } },
    all { s.recordedPermissionDenial or s.controlledEnvironmentCause,
      s' = { ...s, recordedPermissionDenial: false, controlledEnvironmentCause: false } },
  } }
  action use = all { not(s.used), eligible or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { observe, control, review, invalidate, use, hold }
  val safe = s.used implies eligible
  run permissionProbeTest = init.then(observe).then(review).then(use)
    .then(all { assert(s.used), assert(safe), s' = s })
  run controlledEnvironmentTest = init.then(control).then(observe).then(review).then(use)
    .then(all { assert(s.used), assert(safe), s' = s })
  run probeIsNotReviewTest = init.then(observe)
    .then(all { assert(not(eligible)), assert(not(s.used)), s' = s })
  run invalidBindingControlTest = initBypass.then(observe).then(review).then(invalidate).then(use)
    .then(all { assert(not(safe)), s' = s })
}
