module migration_return_observation {
  // A valid migration return need not keep an interpreted observer atomic.
  // Source declarations are enforced by the compiler, not the interpreter.
  type State = { atomic: bool, phase: int, owner: int, target: int,
    returnedOnTarget: bool, observed: int, rescheduled: bool }
  var s: State
  pure def initial(atomic: bool): State = {
    atomic: atomic, phase: 0, owner: 0, target: 1,
    returnedOnTarget: false, observed: -1, rescheduled: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action destinationClaim = all {
    s.phase == 0, s' = { ...s, phase: 1, owner: s.target },
  }
  action returnCaller = all {
    s.phase == 1, s.owner == s.target,
    s' = { ...s, phase: 2, returnedOnTarget: true },
  }
  action schedulerInterleave = all {
    s.phase == 2, not(s.atomic), not(s.rescheduled),
    s' = { ...s, owner: 2, rescheduled: true },
  }
  action readProcessorId = all {
    s.phase == 2, s' = { ...s, phase: 3, observed: s.owner },
  }
  val terminal = s.phase == 3
  action finished = all { terminal, s' = s }
  action step = any { destinationClaim, returnCaller,
    schedulerInterleave, readProcessorId, finished }
  val validMigration = s.phase < 2 or s.returnedOnTarget
  val observedDestination = not(terminal) or s.observed == s.target
  val safe = validMigration and observedDestination
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
