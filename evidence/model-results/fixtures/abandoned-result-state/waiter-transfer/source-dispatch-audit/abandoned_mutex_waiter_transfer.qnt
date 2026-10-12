module abandoned_mutex_waiter_transfer {
  // A queued caller requests ownership for a distinct target thread.
  // The target can end before the previous owner releases the mutex.
  // Transfer examines target state under its low-level lock.
  type State = { fixed: bool, phase: int, targetEnded: bool,
                 previousAbandoned: bool, mutexAbandoned: bool,
                 resumeAbandoned: bool, outcomeAbandoned: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, targetEnded: false, previousAbandoned: false,
    mutexAbandoned: false, resumeAbandoned: false, outcomeAbandoned: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action enqueue = all { s.phase == 0, s' = { ...s, phase: 1 } }
  action targetEnds = all {
    s.phase == 1, not(s.targetEnded), s' = { ...s, targetEnded: true },
  }
  action previousEnds = all {
    s.phase == 1, not(s.previousAbandoned),
    s' = { ...s, previousAbandoned: true },
  }
  action transfer = all {
    s.phase == 1,
    s' = { ...s, phase: 2, mutexAbandoned: s.targetEnded,
      resumeAbandoned: s.previousAbandoned or (s.fixed and s.targetEnded) },
  }
  action resume = all {
    s.phase == 2, s' = { ...s, phase: 3, outcomeAbandoned: s.resumeAbandoned },
  }
  val transferSafe = s.phase < 2 or not(s.mutexAbandoned) or s.resumeAbandoned
  val outcomeSafe = s.phase < 3 or
    s.outcomeAbandoned == (s.previousAbandoned or s.targetEnded)
  val safe = transferSafe and outcomeSafe
  val terminal = s.phase == 3
  action finished = all { terminal, s' = s }
  action step = any { enqueue, targetEnds, previousEnds, transfer, resume, finished }
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
