module cleanup_resize_error_contract {
  // The callee's reduced count is not a successful join witness.
  // Models current global cleanup and a conditional quarantine contract.
  type State = { policy: int, phase: int, count: int, join: int,
    exited: bool, setup: int, freed: bool, outcome: int }
  var s: State
  pure def initial(policy: int): State = {
    policy: policy, phase: 0, count: 2, join: 0, exited: false,
    setup: 1, freed: false, outcome: 0,
  }
  action initOld = s' = initial(0)
  action initFixed = s' = initial(1)
  action publishCleanup = all {
    s.phase == 0, s' = { ...s, phase: 1, setup: 2 },
  }
  action reducePopulation = all {
    s.phase == 1, s' = { ...s, phase: 2, count: 1 },
  }
  action joinFails = all {
    s.phase == 2, s' = { ...s, phase: 3, join: -1 },
  }
  action joinSucceeds = all {
    s.phase == 2, s' = { ...s, phase: 3, join: 1, exited: true },
  }
  action reclaim = all {
    s.phase == 3, s.policy == 0 or s.join == 1,
    s' = { ...s, phase: 4, freed: true, outcome: 1 },
  }
  action quarantine = all {
    s.phase == 3, s.policy == 1, s.join == -1,
    s' = { ...s, phase: 4, outcome: 2 },
  }
  action finished = all { s.phase == 4, s' = s }
  action step = any { publishCleanup, reducePopulation, joinFails,
    joinSucceeds, reclaim, quarantine, finished }
  val exitWitness = not(s.freed) or (s.join == 1 and s.exited)
  val outcomeExplicit = s.phase != 4 or
    ((s.outcome == 1 and s.freed) or (s.outcome == 2 and not(s.freed)))
  val safe = exitWitness and outcomeExplicit
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.phase == 4))
}
