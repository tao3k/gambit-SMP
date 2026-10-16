module vector_increment_arity_parity {
  // Arity agreement only: atomic arithmetic, roots and GC are not proved.
  type State = { fixed: bool, phase: int, arity: int,
    interpreted: bool, compiled: bool, delta: int }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, arity: 0,
    interpreted: false, compiled: false, delta: 0,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action choose(arity: int): bool = all {
    s.phase == 0, s' = { ...s, phase: 1, arity: arity },
  }
  action dispatch = all {
    s.phase == 1,
    s' = { ...s, phase: 2,
      interpreted: s.arity == 3 or (s.fixed and s.arity == 2),
      compiled: s.arity == 2 or s.arity == 3,
      delta: if (s.arity == 2) 1 else 7 },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any { choose(1), choose(2), choose(3), choose(4), dispatch, finished }
  val contract = s.phase != 2 or
    (s.interpreted == s.compiled and (s.arity == 2 implies s.delta == 1))
  run omittedDeltaControlTest = initOld.then(choose(2)).then(dispatch)
    .then(all { assert(not(contract)), s' = s })
  run omittedDeltaFixedTest = initFixed.then(choose(2)).then(dispatch)
    .then(all { assert(contract), assert(s.delta == 1), s' = s })
}
