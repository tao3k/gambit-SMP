module resize_startup_collective_ack {
  // One retained member stands for the old cohort; one slot models reuse.
  type State = { policy: int, fails: bool, newPhase: int, oldPhase: int,
    gc: int, publishedGeneration: int, generation: int, status: int,
    terminalRound: bool, admitted: bool }
  var s: State
  pure def initial(policy: int, fails: bool): State = {
    policy: policy, fails: fails, newPhase: 0, oldPhase: 0, gc: 0,
    publishedGeneration: 1, generation: 2, status: 1,
    terminalRound: false, admitted: false,
  }
  action initEarlyReturn = s' = initial(1, false)
  action initReadyNoop = s' = initial(2, false)
  action initFixed = {
    nondet fails = Set(false, true).oneOf()
    s' = initial(0, fails)
  }
  action enterStartup = all {
    s.newPhase == 0, s' = { ...s, newPhase: 1 },
  }
  action oldReturnEarly = all {
    s.policy == 1, s.oldPhase == 0,
    s' = { ...s, oldPhase: 1 },
  }
  action startLockWait = all {
    s.oldPhase == 1, s.newPhase < 3,
    s' = { ...s, oldPhase: 2 },
  }
  action requestStartupGC = all {
    s.newPhase == 1, s.gc == 0,
    s' = { ...s, gc: 1 },
  }
  action collect = all {
    s.gc == 1, s.oldPhase != 2,
    s' = { ...s, gc: 2 },
  }
  action settleStartup = all {
    s.newPhase == 1, s.gc == 2,
    s' = { ...s, newPhase: 3, publishedGeneration: s.generation,
      status: if (s.fails) -1 else 1 },
  }
  // READY/ERROR is not NOOP. It prevents old members leaving the round
  // in which the new caller still has first_iter set and must run again.
  action terminalOperationRound = all {
    s.newPhase == 3, s.policy != 2,
    s' = { ...s, newPhase: 4, terminalRound: true },
  }
  action mistakenFirstNoop = all {
    s.policy == 2, s.newPhase == 3, s.oldPhase == 0,
    s' = { ...s, newPhase: 4, oldPhase: 3, admitted: true },
  }
  action finalNoop = all {
    s.newPhase == 4, s.oldPhase != 3,
    s.terminalRound, s.publishedGeneration == s.generation,
    s' = { ...s, newPhase: 5, oldPhase: 3, admitted: s.status == 1 },
  }
  val lockCycle = s.oldPhase == 2 and s.gc == 1
  val strandedStartup = s.oldPhase == 3 and s.newPhase == 4
  val terminal = s.oldPhase == 3 and s.newPhase == 5
  action finished = all { terminal, s' = s }
  action step = any { enterStartup, oldReturnEarly, startLockWait,
    requestStartupGC, collect, settleStartup, terminalOperationRound,
    mistakenFirstNoop, finalNoop, finished }
  val safe = not(lockCycle) and not(strandedStartup) and
    (not(s.admitted) or (s.status == 1 and s.terminalRound))
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
