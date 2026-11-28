module smp_interpreter_stepper_race {
  // A proposed inlining guard and the original helper do not necessarily
  // read the stepper at the same point. Interruption is modeled only between
  // whole actions, not as a C memory-model or real stack-map proof.
  type State = { enabled: bool, cached: bool, originalObserved: bool,
    fastObserved: bool, calls: int, effect: int, fastCommitted: bool }
  var s: State
  action init = s' = { enabled: false, cached: false, originalObserved: false,
    fastObserved: false, calls: 0, effect: 0, fastCommitted: false }
  action earlyGuard = s' = {...s, cached: s.enabled}
  action enableStepper = s' = {...s, enabled: true}
  action originalRead = s' = {...s, originalObserved: s.enabled}
  action staleRead = s' = {...s, fastObserved: s.cached}
  action currentRead = s' = {...s, fastObserved: s.enabled}
  // An enabled handler can call the callback more than once, with values
  // supplied by the handler. These are modeled as two distinct effects.
  action handlerTwice = all { s.fastObserved,
    s' = {...s, calls: 2, effect: 7 + 11} }
  action staleDirect = all { not(s.fastObserved),
    s' = {...s, calls: 1, effect: 3, fastCommitted: true} }
  val stepperEquivalent = s.originalObserved == s.fastObserved
  run staleGuardNegativeTest = init.then(earlyGuard).then(enableStepper)
    .then(originalRead).then(staleRead).then(staleDirect)
    .expect(not(stepperEquivalent) and s.fastCommitted and s.effect == 3)
  run lateGuardControlTest = init.then(earlyGuard).then(enableStepper)
    .then(originalRead).then(currentRead).then(handlerTwice)
    .expect(stepperEquivalent and s.calls == 2 and s.effect == 18)
  run noStepperControlTest = init.then(earlyGuard).then(originalRead)
    .then(currentRead).then(staleDirect)
    .expect(stepperEquivalent and s.calls == 1 and s.effect == 3)
}
