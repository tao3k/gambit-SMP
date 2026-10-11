module sync_resource_users {
  // One external sender and one receiver/waiter; successful and failed setup.
  // Destroy/reinitialize is only a candidate protocol, not a source repair.
  type State = { fault: int, outcome: int, phase: int, sealed: bool,
    mutexLive: bool, cvLive: bool, sender: int, waiter: int, flag: bool,
    badHolder: bool, badWaiter: bool, badSignal: bool,
    badAdmission: bool, badRollback: bool }
  var s: State
  pure def initialState(fault: int, outcome: int): State = {
    fault: fault, outcome: outcome, phase: 0, sealed: false,
    mutexLive: true, cvLive: false, sender: 0, waiter: 0, flag: false,
    badHolder: false, badWaiter: false, badSignal: false,
    badAdmission: false, badRollback: false,
  }
  action initOld = any { s' = initialState(1, 0), s' = initialState(1, 1) }
  action initWaiter = any { s' = initialState(2, 0), s' = initialState(2, 1) }
  action initSignal = any { s' = initialState(3, 0), s' = initialState(3, 1) }
  action initAdmission = any { s' = initialState(4, 0), s' = initialState(4, 1) }
  action initRollback = any { s' = initialState(5, 0), s' = initialState(5, 1) }
  action initFixed = any { s' = initialState(0, 0), s' = initialState(0, 1) }

  // Mutex initialization succeeded; condition initialization may fail.
  action setup = all {
    s.phase == 0,
    s' = { ...s, phase: if (s.outcome == 0) 1 else 3,
                 cvLive: s.outcome == 0 },
  }
  action rollback = all {
    s.phase == 3,
    s' = { ...s, phase: 4, sealed: true, mutexLive: s.fault == 5,
                 badRollback: s.fault == 5 },
  }
  val senderHolds = s.sender == 1 or s.sender == 2
  val waiterHolds = s.waiter == 1 or s.waiter == 3
  val holders = senderHolds or waiterHolds
  val waiters = s.waiter == 2
  val signalers = s.sender == 3

  action beginSend = all {
    s.phase == 1, not(s.sealed), s.sender == 0, not(waiterHolds),
    s' = { ...s, sender: 1 },
  }
  action publish = all {
    s.sender == 1,
    s' = { ...s, sender: 2, flag: true },
  }
  action unlock = all {
    s.sender == 2,
    s' = { ...s, sender: 3 },
  }
  action signal = all {
    s.sender == 3,
    s' = { ...s, sender: 4, badSignal: s.badSignal or not(s.cvLive) },
  }
  action beginWait = all {
    s.phase == 1 or s.phase == 2, not(s.sealed),
    s.waiter == 0, not(senderHolds), s.mutexLive, s.cvLive,
    s' = { ...s, waiter: 1,
      badAdmission: s.badAdmission or s.phase == 2 },
  }
  // Condition wait atomically releases the lock; predicate loop is assumed.
  action sleep = all {
    s.waiter == 1, not(s.flag), s' = { ...s, waiter: 2 },
  }
  action predicateReady = all {
    s.waiter == 1, s.flag, s' = { ...s, waiter: 3 },
  }
  action wake = all {
    s.waiter == 2, s.flag, not(senderHolds),
    s' = { ...s, waiter: 3 },
  }
  action leaveWait = all {
    s.waiter == 3, s' = { ...s, waiter: 4 },
  }
  // Fast-path retirement may happen while the publisher still holds the lock.
  action retire = all {
    s.phase == 1, s.flag,
    s' = { ...s, phase: 2, sealed: s.fault != 4 },
  }
  action destroy = all {
    s.phase == 2,
    not(holders) or s.fault == 1,
    not(waiters) or s.fault == 2,
    not(signalers) or s.fault == 3,
    s' = { ...s, phase: 4, mutexLive: false, cvLive: false,
      badHolder: s.badHolder or holders,
      badWaiter: s.badWaiter or waiters,
      badSignal: s.badSignal or signalers },
  }
  action finished = all { s.phase == 4, s' = s }
  action step = any { setup, rollback, beginSend, publish, unlock, signal,
    beginWait, sleep, predicateReady, wake, leaveWait, retire, destroy, finished }
  val holderSafe = not(s.badHolder)
  val waiterSafe = not(s.badWaiter)
  val signalSafe = not(s.badSignal)
  val admissionSafe = not(s.badAdmission)
  val rollbackSafe = not(s.badRollback)
  val safe = holderSafe and waiterSafe and signalSafe and admissionSafe and rollbackSafe

  // Verification-only overlay; the original state transitions are unchanged.
  val obligationTerminal = s.phase == 4
  action obligationStep = all { not(true and (s.phase == 2 and s.sender == 2)), step }
  val obligationEnabled = obligationTerminal or enabled(obligationStep)
  temporal obligationProgress = always(obligationEnabled) and
    weakFair(obligationStep, Set(s)).implies(eventually(obligationTerminal))
}
