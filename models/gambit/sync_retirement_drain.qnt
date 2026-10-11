module sync_retirement_drain {
  // Composes resource users with two incarnations of one processor slot.
  // A captured slot reference is NOT admitted resource access. Admission must
  // atomically check sealing and incarnation before registering its reservation.
  // This is a required contract, not a claim that Gambit has a generation field.
  type State = { fault: int, generation: int, phase: int,
    mutexLive: bool, cvLive: bool, sender: int, waiter: int, flag: bool,
    probe: int, probeGeneration: int, badAdmission: bool, badEpoch: bool,
    badReservation: bool, badSetup: bool }
  var s: State
  pure def initialState(fault: int): State = {
    fault: fault, generation: 1, phase: 0, mutexLive: true, cvLive: true,
    sender: 0, waiter: 0, flag: false, probe: 0, probeGeneration: 0,
    badAdmission: false, badEpoch: false, badReservation: false, badSetup: false,
  }
  action initFixed = s' = initialState(0)
  action initUnsealedAdmission = s' = initialState(1)
  action initStaleReference = s' = initialState(2)
  action initUncountedReservation = s' = initialState(3)
  action initPartialSetup = s' = initialState(4)
  val senderHolds = s.sender == 2 or s.sender == 3
  val waiterHolds = s.waiter == 1 or s.waiter == 3
  val senderLive = Set(1, 2, 3, 4).contains(s.sender)
  val waiterLive = Set(1, 2, 3).contains(s.waiter)
  action beginSend = all {
    s.phase == 0, s.generation == 1, s.sender == 0,
    s' = { ...s, sender: 1 },
  }
  action lock = all {
    s.sender == 1, not(waiterHolds), s.mutexLive,
    s' = { ...s, sender: 2 },
  }
  action publish = all { s.sender == 2, s' = { ...s, sender: 3, flag: true } }
  action unlock = all { s.sender == 3, s' = { ...s, sender: 4 } }
  action signal = all { s.sender == 4, s.cvLive, s' = { ...s, sender: 5 } }
  action beginWait = all {
    s.phase == 0, s.generation == 1, s.waiter == 0, not(senderHolds),
    s' = { ...s, waiter: 1 },
  }
  action sleep = all { s.waiter == 1, not(s.flag), s' = { ...s, waiter: 2 } }
  action ready = all { s.waiter == 1, s.flag, s' = { ...s, waiter: 3 } }
  action wake = all {
    s.waiter == 2, s.flag, not(senderHolds), s' = { ...s, waiter: 3 },
  }
  action leaveWait = all { s.waiter == 3, s' = { ...s, waiter: 4 } }
  action captureReference = all {
    s.phase == 0, s.generation == 1, s.probe == 0,
    s' = { ...s, probe: 1, probeGeneration: s.generation },
  }
  action admitReference = all {
    s.probe == 1,
    s.phase == 0 or (s.phase == 1 and s.fault == 1),
    s.probeGeneration == s.generation or s.fault == 2,
    s' = { ...s, probe: 2,
      badAdmission: s.badAdmission or s.phase != 0,
      badEpoch: s.badEpoch or s.probeGeneration != s.generation },
  }
  action rejectReference = all {
    s.probe == 1, s.phase != 0 or s.probeGeneration != s.generation,
    s' = { ...s, probe: 3 },
  }
  action releaseReference = all { s.probe == 2, s' = { ...s, probe: 3 } }
  // Receiving the published flag does not imply unlock or signal has finished.
  action seal = all {
    s.phase == 0, s.generation == 1, s.flag,
    s' = { ...s, phase: 1 },
  }
  action destroy = all {
    s.phase == 1, not(senderLive), not(waiterLive),
    s.probe != 2 or s.fault == 3,
    s' = { ...s, phase: 2, mutexLive: false, cvLive: false,
      badReservation: s.badReservation or s.probe == 2 },
  }
  action initMutex = all {
    s.phase == 2, s' = { ...s, generation: 2, phase: 3, mutexLive: true, flag: false },
  }
  action initCondition = all { s.phase == 3, s' = { ...s, phase: 4, cvLive: true } }
  action setupFailure = all {
    s.phase == 3, s' = { ...s, phase: 5, mutexLive: false, cvLive: false },
  }
  action reopen = all {
    s.phase == 4 or (s.phase == 3 and s.fault == 4),
    s' = { ...s, phase: 0, badSetup: s.badSetup or not(s.cvLive) },
  }
  action finished = all {
    (s.generation == 2 and s.phase == 0) or s.phase == 5,
    s.probe == 0 or s.probe == 3, not(senderLive), not(waiterLive), s' = s,
  }
  action step = any { beginSend, lock, publish, unlock, signal,
    beginWait, sleep, ready, wake, leaveWait, captureReference, admitReference,
    rejectReference, releaseReference, seal, destroy, initMutex, initCondition,
    setupFailure, reopen, finished }
  val admissionSafe = not(s.badAdmission)
  val epochSafe = not(s.badEpoch)
  val reservationSafe = not(s.badReservation)
  val setupSafe = not(s.badSetup) and (s.phase != 5 or not(s.mutexLive) and not(s.cvLive))
  val resourceSafe = (not(senderLive) and not(waiterLive) and s.probe != 2) or
    (s.mutexLive and s.cvLive)
  val safe = admissionSafe and epochSafe and reservationSafe and setupSafe and resourceSafe
  val terminal = ((s.generation == 2 and s.phase == 0) or s.phase == 5) and
    (s.probe == 0 or s.probe == 3) and not(senderLive) and not(waiterLive)
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
