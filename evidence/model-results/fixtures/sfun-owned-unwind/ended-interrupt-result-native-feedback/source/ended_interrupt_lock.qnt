module ended_interrupt_lock {
  // PR1047: validated target may terminate before propagation acquires its
  // low-level lock. Lock acquisition/check/return are abstract atomic steps.
  // Termination outcome is normal or exceptional; memory ordering is assumed.
  type State = { fixed: bool, phase: int, ended: bool, exceptional: bool,
                 locked: bool, delivered: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, ended: false, exceptional: false,
    locked: false, delivered: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action validate = all {
    s.phase == 0, not(s.ended), s' = { ...s, phase: 1 },
  }
  action terminate(exceptional: bool): bool = all {
    s.phase == 1, not(s.ended),
    s' = { ...s, ended: true, exceptional: exceptional },
  }
  action acquire = all {
    s.phase == 1, not(s.locked), s' = { ...s, phase: 2, locked: true },
  }
  action propagate = all {
    s.phase == 2, s.locked,
    s' = { ...s, phase: 3, locked: s.ended and not(s.fixed),
           delivered: not(s.ended) },
  }
  action observe = all { s.phase == 3, s' = { ...s, phase: 4 } }
  action finished = all { s.phase == 4, s' = s }
  action step = any { validate, terminate(false), terminate(true), acquire,
                     propagate, observe, finished }
  val releaseSafe = s.phase < 3 or not(s.locked)
  val deliverySafe = not(s.delivered) or not(s.ended)
  val safe = releaseSafe and deliverySafe
}
