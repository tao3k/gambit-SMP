module suite_observation_transport {
  // Flags abstract externally checked properties, not filesystem proofs.
  type State = { policy: str, fresh: bool, regular: bool, bounded: bool,
    structured: bool, childPassed: bool, captured: bool, snapshotValid: bool,
    consumed: bool, admitted: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, fresh: true, regular: true, bounded: true,
    structured: true, childPassed: true, captured: false, snapshotValid: true,
    consumed: false, admitted: false,
  }
  action init = s' = initial("check-all")
  action initCaptureBypass = s' = initial("capture-bypass")
  action initHashBypass = s' = initial("hash-bypass")
  val validCapture = s.fresh and s.regular and s.bounded
    and s.structured and s.childPassed
  action changeInput = {
    nondet flag = Set("fresh", "regular", "bounded", "structured", "child").oneOf()
    all { not(s.captured), not(s.consumed),
      s' = { ...s, fresh: if (flag == "fresh") false else s.fresh,
        regular: if (flag == "regular") false else s.regular,
        bounded: if (flag == "bounded") false else s.bounded,
        structured: if (flag == "structured") false else s.structured,
        childPassed: if (flag == "child") false else s.childPassed } }
  }
  action capture = all { not(s.captured), not(s.consumed),
    validCapture or s.policy == "capture-bypass",
    s' = { ...s, captured: true } }
  action drift = all { s.captured, not(s.consumed),
    s' = { ...s, snapshotValid: false } }
  action consume = all { s.captured, not(s.consumed),
    s' = { ...s, consumed: true,
      admitted: s.snapshotValid or s.policy == "hash-bypass" } }
  action reject = all { not(s.consumed), not(s.captured), not(validCapture),
    s' = { ...s, consumed: true } }
  action finished = all { s.consumed, s' = s }
  action step = any { changeInput, capture, drift, consume, reject, finished }
  val safe = not(s.admitted) or (validCapture and s.snapshotValid and s.captured)
  val noStall = s.consumed or enabled(step)
  run invalidCaptureControlTest = initCaptureBypass
    .then(all { s' = { ...s, fresh: false } }).then(capture).then(consume)
    .then(all { assert(not(safe)), s' = s })
  run hashControlTest = initHashBypass.then(capture).then(drift).then(consume)
    .then(all { assert(not(safe)), s' = s })
  run goodTransportTest = init.then(capture).then(consume)
    .then(all { assert(safe), assert(s.admitted), s' = s })
  run driftRejectionTest = init.then(capture).then(drift).then(consume)
    .then(all { assert(safe), assert(not(s.admitted)), s' = s })
}
