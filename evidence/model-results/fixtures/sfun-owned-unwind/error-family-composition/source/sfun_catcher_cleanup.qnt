module sfun_catcher_cleanup {
  // Kinds: void, Scheme object, converted integer. Not processor counts.
  type State = { policy: int, kind: int, fault: int, phase: int,
    marker: bool, made: int, killed: int, catcher: int,
    error: int, delivered: int, handlerCalled: bool }
  var s: State
  pure def initial(policy: int, kind: int, fault: int): State = {
    policy: policy, kind: kind, fault: fault, phase: 0, marker: false,
    made: 0, killed: 0, catcher: 0, error: 0, delivered: 0,
    handlerCalled: false
  }
  action initFixed = {
    nondet kind = Set(0, 1, 2).oneOf()
    nondet fault = (if (kind == 2) Set(0, 1, 2, 3) else Set(0, 1, 2)).oneOf()
    s' = initial(0, kind, fault)
  }
  action initTailOnly = s' = initial(1, 2, 2)
  action initCatcherLeak = s' = initial(2, 1, 2)
  action initDoubleKill = s' = initial(3, 0, 0)
  action initUnallocatedKill = s' = initial(4, 2, 1)
  action initErrorErase = s' = initial(5, 2, 3)
  action allocate = all {
    s.phase == 0,
    s' = if (s.fault == 1) { ...s, phase: 5, error: 11 }
      else { ...s, phase: 1, marker: true, made: 1 },
  }
  action install = all {
    s.phase == 1,
    s' = { ...s, phase: 2, catcher: if (s.policy == 1) 0 else 1 },
  }
  action callAndConvert = all {
    s.phase == 2,
    s' = { ...s, phase: if (s.policy == 1 and s.fault >= 2) 5 else 3,
      error: if (s.fault == 2) 17 else if (s.fault == 3) 23 else 0,
      handlerCalled: s.fault == 3 },
  }
  action leaveTry = all {
    s.phase == 3,
    s' = { ...s, phase: 4, catcher: if (s.policy == 2) 1 else 0 },
  }
  action invalidate = all {
    s.phase == 4,
    s' = { ...s, phase: 5, marker: false,
      killed: if (s.policy == 3) 2 else 1 },
  }
  action propagate = all {
    s.phase == 5,
    s' = { ...s, phase: 6, delivered: if (s.policy == 5) 0 else s.error,
      killed: if (s.policy == 4) 1 else s.killed },
  }
  val terminal = s.phase == 6
  action finished = all { terminal, s' = s }
  action step = any { allocate, install, callAndConvert, leaveTry,
    invalidate, propagate, finished }
  val cleanupBeforePropagation = (s.phase >= 5).implies(not(s.marker))
  val catcherRestored = (s.phase >= 4).implies(s.catcher == 0)
  val exactlyOnce = s.killed <= 1
  val allocationSafe = s.killed <= s.made
  val expectedError = if (s.fault == 1) 11 else if (s.fault == 2) 17
    else if (s.fault == 3) 23 else 0
  val honestError = terminal.implies(s.delivered == expectedError)
  val finalCleanup = terminal.implies(s.made == s.killed)
  val conversionHandler = (s.phase >= 3 and s.fault == 3).implies(s.handlerCalled)
  val progressEnabled = terminal or enabled(step)
  val safe = cleanupBeforePropagation and catcherRestored and exactlyOnce
    and allocationSafe and honestError and finalCleanup and conversionHandler
    and progressEnabled
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}
