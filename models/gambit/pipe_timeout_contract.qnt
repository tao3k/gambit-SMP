module pipe_timeout_contract {
  // Diagnostic API contract, not a runtime repair. Setting a relative port
  // timeout once stores an absolute deadline. No scheduling/latency bound.
  type State = { aware: bool, now: int, deadline: int, waiting: bool,
                 closed: bool, observed: bool, wrong: bool }
  var s: State
  pure def initial(aware: bool): State = {
    aware: aware, now: 0, deadline: 2, waiting: false,
    closed: false, observed: false, wrong: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action tick = all {
    not(s.observed), s.now < 3, s' = { ...s, now: s.now + 1 },
  }
  action wait = all {
    not(s.observed), not(s.waiting), s' = { ...s, waiting: true },
  }
  action close = all {
    not(s.observed), not(s.closed), s' = { ...s, closed: true },
  }
  action observeEOF = all {
    s.waiting, not(s.observed), s.closed or s.now >= s.deadline,
    s' = { ...s, observed: true, waiting: false,
           wrong: not(s.closed) and not(s.aware) },
  }
  action finished = all { s.observed, s' = s }
  action step = any { tick, wait, close, observeEOF, finished }
  val safe = not(s.wrong) and
             (not(s.observed) or s.closed or s.now >= s.deadline)
}
