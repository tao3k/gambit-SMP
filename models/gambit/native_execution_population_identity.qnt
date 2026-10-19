module native_execution_population_identity {
  // Finite execution-role evidence contract, not a CPU-count default or a
  // guarantee about an Agent. Native role/probe authenticity is a premise.
  type State = { phase: int, runner: int, fixture: int, reported: int,
    role: str, fixed: bool, single: bool }
  var s: State
  pure def initial(runner: int, fixture: int, fixed: bool): State = {
    phase: 0, runner: runner, fixture: fixture, reported: 0,
    role: "none", fixed: fixed, single: false,
  }
  action initFixed = {
    nondet runner = Set(1, 2).oneOf()
    nondet fixture = Set(1, 2, 3).oneOf()
    s' = initial(runner, fixture, true)
  }
  action initOld = s' = initial(1, 3, false)
  action observe = all {
    s.phase == 0,
    s' = { ...s, phase: 1,
      reported: if (s.fixed) s.fixture else s.runner,
      role: if (s.fixed) "fixture" else "runner" },
  }
  action classify = all {
    s.phase == 1,
    s' = { ...s, phase: 2, single: s.reported == 1 },
  }
  action hold = all { s.phase == 2, s' = s }
  action step = any { observe, classify, hold }
  val safe = s.phase == 2 implies
    (s.role == "fixture" and s.reported == s.fixture and
     s.single == (s.fixture == 1))
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.phase == 2))
}
