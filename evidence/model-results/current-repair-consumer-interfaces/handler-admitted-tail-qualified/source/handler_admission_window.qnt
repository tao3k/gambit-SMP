module handler_admission_window {
  import runtime_generation_recovery as G from "./runtime_generation_recovery"

  // One OS-delivered old invocation is a counterexample population, not a
  // processor limit. Delivery epoch is ghost state, never a C-readable token.
  // The checked policy requires real OS invocation completion. No current
  // Gambit operation is claimed to provide that otherwise unobserved premise.
  type Invocation = { requireOsDrain: bool, stage: int, cReaders: int,
    deliveryEpoch: int, crossed: bool, admitted: bool, reopened: bool }
  var h: Invocation
  pure def initial(required: bool): Invocation = {
    requireOsDrain: required, stage: 0, cReaders: 0, deliveryEpoch: 1,
    crossed: false, admitted: false, reopened: false }
  action initCounter = all { G::s' = G::initial(2), h' = initial(false) }
  action initDrain = all { G::s' = G::initial(2), h' = initial(true) }
  action keepGeneration = G::s' = G::s
  // The invocation is delivered but has not executed its first C instruction.
  action seal = all { G::s.phase == 0, h.stage == 0,
    G::sealAdmitted, h' = h }
  action firstCInstruction = all { G::s.phase >= 3, h.stage == 0,
    keepGeneration, h' = { ...h, stage: 1, cReaders: 1 } }
  action admitNewGeneration = all { h.stage == 1, G::s.phase == 4,
    G::enterCross,
    h' = { ...h, stage: 2, admitted: true,
      crossed: h.deliveryEpoch != G::s.epoch } }
  action rejectSealed = all { h.stage == 1, G::s.phase == 3,
    keepGeneration, h' = { ...h, stage: 2 } }
  // A counted interval may end before the C invocation returns. Whether this
  // tail can touch an old resource is a separate, source-mapped obligation.
  action releaseCensus = all { h.stage == 2, h.admitted, h.cReaders == 1,
    keepGeneration, h' = { ...h, stage: 4, cReaders: 0 } }
  action returnInvocation = all { h.stage == 2 or h.stage == 4,
    G::s' = { ...G::s, oldHandler: false, hostQuiet: true },
    h' = { ...h, stage: 3, cReaders: 0 } }
  action reopen = all { G::s.phase == 3, h.cReaders == 0, not(h.reopened),
    not(h.requireOsDrain) or h.stage == 3,
    G::s' = { ...G::s, phase: 4, epoch: 2, sealed: false },
    h' = { ...h, reopened: true } }
  action finish = all { h.reopened, h.stage == 3,
    keepGeneration, h' = h }
  action step = any { seal, firstCInstruction, admitNewGeneration,
    rejectSealed, releaseCensus, returnInvocation, reopen, finish }
  val noCross = not(h.crossed)
  val drainSafe = not(h.requireOsDrain) or
    (noCross and (not(h.reopened) or h.stage == 3))
  val noCompletedDrain = not(h.requireOsDrain and h.reopened and h.stage == 3)
  val counterAccurate = h.cReaders == (if (h.stage == 1 or h.stage == 2) 1 else 0)
  val noPostReleaseTail = h.stage != 4
  val tailHasNoCountedLease = h.stage != 4 or h.cReaders == 0
  temporal progress = weakFair(step, Set((G::s, h)))
    .implies(eventually(h.reopened and h.stage == 3))
  run counterMissesDeliveredInvocation = initCounter.then(seal).then(reopen)
    .then(firstCInstruction).then(admitNewGeneration)
    .expect(h.crossed and h.admitted and h.cReaders == 1)
  run actualCompletionPrecedesReopen = initDrain.then(seal)
    .then(firstCInstruction).then(rejectSealed).then(returnInvocation).then(reopen)
    .expect(not(h.crossed) and h.cReaders == 0 and h.reopened)
  run countedIntervalEndsBeforeReturn = initCounter.then(seal).then(reopen)
    .then(firstCInstruction).then(admitNewGeneration).then(releaseCensus)
    .expect(h.admitted and h.cReaders == 0 and h.stage == 4)
}
