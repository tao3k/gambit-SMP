module abandoned_mutex_waiter_dispatch {
  // Source dispatch matters: normal unlock has its own dead-new-owner check.
  // The SMP abandonment helper is called with previousAbandoned=true.
  type State = { correctDispatch: bool, phase: int, targetEnded: bool,
                 previousAbandoned: bool, route: str, mutexAbandoned: bool,
                 resumeAbandoned: bool, outcomeAbandoned: bool }
  var s: State
  pure def initial(correctDispatch: bool): State = {
    correctDispatch: correctDispatch, phase: 0, targetEnded: false,
    previousAbandoned: false, route: "none", mutexAbandoned: false,
    resumeAbandoned: false, outcomeAbandoned: false,
  }
  action initWrongDispatch = s' = initial(false)
  action initSourceDispatch = s' = initial(true)
  action enqueue = all { s.phase == 0, s' = { ...s, phase: 1 } }
  action targetEnds = all {
    s.phase == 1, not(s.targetEnded), s' = { ...s, targetEnded: true },
  }
  action previousEnds = all {
    s.phase == 1, not(s.previousAbandoned),
    s' = { ...s, previousAbandoned: true },
  }
  action dispatch = all {
    s.phase == 1,
    s' = { ...s, phase: 2,
      route: if (s.correctDispatch and not(s.previousAbandoned)) "unlock" else "abandon" },
  }
  action transfer = all {
    s.phase == 2,
    s' = { ...s, phase: 3, mutexAbandoned: s.targetEnded,
      resumeAbandoned: if (s.route == "unlock") s.targetEnded else s.previousAbandoned },
  }
  action resume = all {
    s.phase == 3, s' = { ...s, phase: 4, outcomeAbandoned: s.resumeAbandoned },
  }
  val dispatchSafe = s.phase < 2 or s.route != "abandon" or s.previousAbandoned
  val outcomeSafe = s.phase < 4 or
    s.outcomeAbandoned == (s.previousAbandoned or s.targetEnded)
  val safe = dispatchSafe and outcomeSafe
  val terminal = s.phase == 4
  action finished = all { terminal, s' = s }
  action step = any { enqueue, targetEnds, previousEnds, dispatch, transfer, resume, finished }
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
