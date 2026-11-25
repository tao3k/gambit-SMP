module smp_interpreter_tail_deopt {
  // Proposed two-call abstraction. A compact location is not a Scheme object;
  // an observer first receives a rooted stable cell. Source stack maps,
  // allocation failure, interrupts and C memory ordering need refinement.
  type State = { call: int, arg: int, compactRooted: bool, cell: int,
    cellReady: bool, cellRooted: bool, requested: bool, captured: bool, pending: bool, failed: bool,
    firstLocation: int, laterLocation: int, laterValue: int,
    observed: int, resumes: int, bindingValid: bool, primitiveTrusted: bool, effect: int,
    bindingAtCommit: bool, fallback: bool }
  var s: State
  action init = s' = { call: 1, arg: 10, compactRooted: true, cell: 0,
    cellReady: false, cellRooted: false, requested: false, captured: false, pending: false, failed: false,
    firstLocation: 0, laterLocation: 0, laterValue: 0,
    observed: 0, resumes: 0, bindingValid: true, primitiveTrusted: true, effect: 0,
    bindingAtCommit: false, fallback: false }
  // Preparation may fail without publishing a partial cell or losing roots.
  action beginMaterialization = all { s.call == 1, not(s.cellReady), not(s.pending),
    s' = {...s, pending: true} }
  action failMaterialization = all { s.pending,
    s' = {...s, pending: false, failed: true} }
  action materialize = all { s.call == 1, s.pending, s.compactRooted, not(s.cellReady),
    s' = {...s, cell: s.arg, cellReady: true, cellRooted: true, pending: false, failed: false} }
  action requestCapture = all { s.call == 1, not(s.requested), not(s.captured),
    s' = {...s, requested: true} }
  action capture = all { s.call == 1, s.requested, s.cellReady, s.cellRooted, not(s.pending), not(s.captured),
    s' = {...s, captured: true, firstLocation: 1} }
  // A later debugger observation has its own stable location.
  action inspectLaterPoll = all { s.call == 2, s.captured, s.laterLocation == 0,
    s' = {...s, laterLocation: 2, laterValue: s.arg} }
  // A new logical call may reuse a compact carrier, never an escaped cell.
  action tailCall = all { s.call == 1, not(s.pending), (not(s.requested) or s.captured),
    s' = {...s, call: 2, arg: 22} }
  action mutateCaptured = all { s.captured, s.cellReady, s.cellRooted, s.cell != 12,
    s' = {...s, cell: 12} }
  action resume = all { s.captured, s.cellReady, s.cellRooted, s.resumes < 2,
    s' = {...s, observed: s.cell, resumes: s.resumes + 1} }
  // Binding validation is an abstract atomic guard. The implementation must
  // establish the real read/commit ordering or fall back before any effect.
  action invalidateBinding = all { s.bindingValid, s' = {...s, bindingValid: false} }
  action mutatePrimitive = all { s.primitiveTrusted, s' = {...s, primitiveTrusted: false} }
  action fastEffect = all { s.bindingValid, s.primitiveTrusted, not(s.fallback), s.effect == 0,
    s' = {...s, effect: 1, bindingAtCommit: s.bindingValid and s.primitiveTrusted} }
  action slowFallback = all { (not(s.bindingValid) or not(s.primitiveTrusted)), not(s.fallback),
    s' = {...s, fallback: true} }
  action collect = all { s.compactRooted, (s.captured implies s.cellRooted), s' = s }
  action step = any { beginMaterialization, failMaterialization, materialize, requestCapture, capture, tailCall,
    inspectLaterPoll, mutateCaptured, resume, invalidateBinding, mutatePrimitive, fastEffect, slowFallback, collect, s' = s }
  val safe = all { s.compactRooted, s.captured implies (s.cellReady and s.cellRooted),
    s.captured implies s.firstLocation != 0,
    s.laterLocation != 0 implies (s.call == 2 and s.captured
      and s.laterLocation != s.firstLocation and s.laterValue == s.arg),
    s.resumes > 0 implies s.captured, s.pending implies not(s.cellReady),
    (s.requested and not(s.captured)) implies s.call == 1,
    s.captured implies (s.cell == 10 or s.cell == 12),
    s.effect > 0 implies s.bindingAtCommit }
  run captureBeforeTailTest = init.then(beginMaterialization).then(requestCapture).then(collect).then(materialize).then(capture).then(tailCall)
    .then(mutateCaptured).then(collect).then(resume).then(resume)
    .expect(s.observed == 12 and s.arg == 22 and s.resumes == 2 and safe)
  run asynchronousPollLocationsTest = init.then(requestCapture).then(beginMaterialization)
    .then(materialize).then(capture).then(collect).then(tailCall).then(inspectLaterPoll)
    .then(collect).then(mutateCaptured).then(resume)
    .expect(s.observed == 12 and s.laterValue == 22 and safe)
  run asynchronousPollAliasControlTest = init.then(requestCapture).then(beginMaterialization)
    .then(materialize).then(capture).then(tailCall)
    .then(all { s' = {...s, laterLocation: s.firstLocation, laterValue: s.arg} })
    .expect(not(safe))
  run allocationFailureRetainsTest = init.then(requestCapture).then(beginMaterialization).then(failMaterialization)
    .expect(s.arg == 10 and s.compactRooted and not(s.cellReady) and safe)
    .then(beginMaterialization).then(materialize).then(capture).then(resume).expect(s.observed == 10 and safe)
  run tailWithoutExposureTest = init.then(tailCall).then(collect)
    .expect(s.arg == 22 and not(s.captured) and safe)
  run unmaterializedCaptureControlTest = init
    .then(all { s' = {...s, captured: true} }).expect(not(safe))
  run missingRootControlTest = init.then(requestCapture).then(beginMaterialization).then(materialize).then(capture)
    .then(all { s' = {...s, cellRooted: false} }).expect(not(safe))
  run overwriteEscapedCellControlTest = init.then(requestCapture).then(beginMaterialization).then(materialize).then(capture)
    .then(all { s' = {...s, call: 2, arg: 22, cell: 22} }).expect(not(safe))
  run captureRaceControlTest = init.then(requestCapture)
    .then(all { s' = {...s, call: 2, arg: 22} }).expect(not(safe))
  run changedBindingFallbackTest = init.then(invalidateBinding).then(slowFallback)
    .expect(s.fallback and s.effect == 0 and safe)
  run committedEffectFallbackTest = init.then(fastEffect).then(invalidateBinding).then(slowFallback)
    .expect(s.fallback and s.effect == 1 and safe)
  run changedBindingEffectControlTest = init.then(invalidateBinding)
    .then(all { s' = {...s, effect: 1, bindingAtCommit: false} }).expect(not(safe))
  run changedPrimitiveFallbackTest = init.then(mutatePrimitive).then(slowFallback)
    .expect(s.fallback and s.effect == 0 and safe)
  run changedPrimitiveEffectControlTest = init.then(mutatePrimitive)
    .then(all { s' = {...s, effect: 1, bindingAtCommit: false} }).expect(not(safe))
}
