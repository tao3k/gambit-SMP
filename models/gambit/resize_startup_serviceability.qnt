module resize_startup_serviceability {
  // One startup slot; stage bounds never select host CPU capacity.
  type State = { fixed: bool, queuesReady: bool, roundDone: bool,
    responsive: bool, published: bool, callerReturned: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, queuesReady: false, roundDone: false,
    responsive: false, published: false, callerReturned: false,
  }
  action initQueueOnly = s' = initial(false)
  action initFixedDesign = s' = initial(true)
  action initializeQueues = all {
    not(s.queuesReady), s' = { ...s, queuesReady: true },
  }
  action completeReadyRound = all {
    s.queuesReady, not(s.roundDone),
    s' = { ...s, roundDone: true, published: not(s.fixed) },
  }
  // This is an obligation, not an abstraction of interrupt-enable alone:
  // physical lock waits, GC polling and scheduler entry must refine it.
  action establishServiceability = all {
    s.roundDone, not(s.responsive),
    s' = { ...s, responsive: true, published: true },
  }
  action returnResize = all {
    s.published, not(s.callerReturned),
    s' = { ...s, callerReturned: true },
  }
  val safe = not(s.callerReturned) or s.responsive
  val terminal = s.callerReturned and s.responsive
  action finished = all { terminal, s' = s }
  action step = any { initializeQueues, completeReadyRound,
    establishServiceability, returnResize, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
