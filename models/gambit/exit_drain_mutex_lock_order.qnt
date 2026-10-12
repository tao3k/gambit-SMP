module exit_drain_mutex_lock_order {
  // Two processor actors, not a machine CPU setting. Locks: 0 free, 1 peer, 2 target.
  // Logical ownership does not mean the low-level mutex lock is held.
  type State = { releaseOnContention: bool, releaseSlow: bool, peer: int, target: int,
    mutexLock: int, threadLock: int, logicallyOwned: bool,
    terminated: bool, observedTerminated: bool, slowChecked: bool }
  var s: State
  pure def initial(releaseOnContention: bool, releaseSlow: bool): State = {
    releaseOnContention: releaseOnContention, releaseSlow: releaseSlow, peer: 0, target: 0,
    mutexLock: 0, threadLock: 0, logicallyOwned: true,
    terminated: false, observedTerminated: false, slowChecked: false,
  }
  action initOld = s' = initial(false, false)
  action initEntryOnly = s' = initial(true, false)
  action initFixed = s' = initial(true, true)

  // Public third-party owner validation acquires and then releases T.
  action checkOwner = all {
    s.peer == 0, s.threadLock == 0,
    s' = { ...s, peer: 1, threadLock: 1 },
  }
  action releaseCheck = all {
    s.peer == 1, s.threadLock == 1,
    s' = { ...s, peer: 2, threadLock: 0 },
  }
  action lockMutex = all {
    s.peer == 2, s.mutexLock == 0,
    s' = { ...s, peer: 3, mutexLock: 1 },
  }
  action lockOwner = all {
    s.peer == 3, s.threadLock == 0,
    s' = { ...s, peer: 4, threadLock: 1 },
  }
  // Candidate only: preserve the two-lock fast path but drop M on contention.
  // The subsequent path acquires T before M and rechecks state under both.
  action dropMutex = all {
    s.peer == 3, s.threadLock == 2, s.releaseOnContention,
    s' = { ...s, peer: 5, mutexLock: 0 },
  }
  action waitOwner = all {
    s.peer == 5, s.threadLock == 0,
    s' = { ...s, peer: 6, threadLock: 1 },
  }
  action reacquireMutex = all {
    s.peer == 6, s.mutexLock == 0,
    s' = { ...s, peer: 4, mutexLock: 1 },
  }
  // This is the state-inspection boundary, not a successful logical mutex-lock!
  // Do not reuse the initialized-thread observation made before acquiring M.
  action inspectOwner = all {
    s.peer == 4, s.threadLock == 1, s.mutexLock == 1,
    s' = { ...s, peer: 7, observedTerminated: s.terminated },
  }
  action releasePeer = all {
    s.peer == 7, s.observedTerminated or s.slowChecked,
    s' = { ...s, peer: 8, threadLock: 0, mutexLock: 0 },
  }
  // The real out-of-line path drops T, retains M, then reacquires thread locks.
  // Fixing only macro entry does not protect this second acquisition boundary.
  action enterSlow = all {
    s.peer == 7, not(s.observedTerminated), not(s.slowChecked),
    s' = { ...s, peer: 9, threadLock: 0 },
  }
  action slowOwner = all {
    s.peer == 9, s.threadLock == 0,
    s' = { ...s, peer: 7, threadLock: 1, slowChecked: true,
      observedTerminated: s.terminated },
  }
  action slowDropMutex = all {
    s.peer == 9, s.threadLock == 2, s.releaseSlow,
    s' = { ...s, peer: 10, mutexLock: 0 },
  }
  action slowWaitOwner = all {
    s.peer == 10, s.threadLock == 0,
    s' = { ...s, peer: 11, threadLock: 1 },
  }
  action slowReacquireMutex = all {
    s.peer == 11, s.mutexLock == 0,
    s' = { ...s, peer: 7, mutexLock: 1, slowChecked: true,
      observedTerminated: s.terminated },
  }

  // Target end marker is published under T, before the owned-deque drain.
  action beginExit = all {
    s.target == 0, s.threadLock == 0,
    s' = { ...s, target: 1, threadLock: 2, terminated: true },
  }
  action lockDrain = all {
    s.target == 1, s.mutexLock == 0,
    s' = { ...s, target: 2, mutexLock: 2 },
  }
  action abandon = all {
    s.target == 2,
    s' = { ...s, target: 3, mutexLock: 0, logicallyOwned: false },
  }
  action releaseTarget = all {
    s.target == 3,
    s' = { ...s, target: 4, threadLock: 0 },
  }
  val terminal = s.peer == 8 and s.target == 4
  action finished = all { terminal, s' = s }
  action step = any { checkOwner, releaseCheck, lockMutex, lockOwner,
    dropMutex, waitOwner, reacquireMutex, inspectOwner, releasePeer,
    enterSlow, slowOwner, slowDropMutex, slowWaitOwner, slowReacquireMutex,
    beginExit, lockDrain, abandon, releaseTarget, finished }
  val waitCycle = Set(3, 9).contains(s.peer) and s.target == 1 and
    s.mutexLock == 1 and s.threadLock == 2
  // The candidate can escape this state; a wait graph alone is not deadlock.
  // Quint's TypeScript runtime does not implement enabled; enumerate guards
  // for executable trajectories, and check equivalence with ENABLED in TLC.
  val serviceable = terminal or
    (s.peer == 0 and s.threadLock == 0) or s.peer == 1 or
    (s.peer == 2 and s.mutexLock == 0) or
    (s.peer == 3 and (s.threadLock == 0 or s.releaseOnContention)) or
    s.peer == 4 or s.peer == 7 or
    (Set(5, 10).contains(s.peer) and s.threadLock == 0) or
    (Set(6, 11).contains(s.peer) and s.mutexLock == 0) or
    (s.peer == 9 and (s.threadLock == 0 or s.releaseSlow)) or
    (s.target == 0 and s.threadLock == 0) or
    (s.target == 1 and s.mutexLock == 0) or Set(2, 3).contains(s.target)
  val ownership =
    (s.mutexLock == 1).implies(Set(3, 4, 7, 9).contains(s.peer)) and
    (s.threadLock == 1).implies(Set(1, 4, 6, 7, 11).contains(s.peer)) and
    (s.mutexLock == 2).implies(s.target == 2) and
    (s.threadLock == 2).implies(Set(1, 2, 3).contains(s.target)) and
    (s.target >= 3).implies(not(s.logicallyOwned))
  val revalidated = (s.peer == 7).implies(s.observedTerminated == s.terminated)
  val safe = serviceable and ownership and revalidated
  val checked = safe and (serviceable == enabled(step))
  temporal progress = always(safe) and
    weakFair(step, Set(s)).implies(eventually(terminal))

  run originalCycleTest = initOld.then(checkOwner).then(releaseCheck)
    .then(lockMutex).then(beginExit)
    .then(all { assert(waitCycle), assert(not(serviceable)), assert(ownership), s' = s })
  run candidateEscapeTest = initFixed.then(checkOwner).then(releaseCheck)
    .then(lockMutex).then(beginExit).then(dropMutex).then(lockDrain)
    .then(abandon).then(releaseTarget).then(waitOwner).then(reacquireMutex)
    .then(inspectOwner).then(releasePeer)
    .then(all { assert(terminal), assert(s.observedTerminated), assert(safe), s' = s })
  run peerFirstTest = initFixed.then(checkOwner).then(releaseCheck)
    .then(lockMutex).then(lockOwner).then(inspectOwner).then(enterSlow)
    .then(slowOwner).then(releasePeer)
    .then(beginExit).then(lockDrain).then(abandon).then(releaseTarget)
    .then(all { assert(terminal), assert(not(s.observedTerminated)), assert(safe), s' = s })
  run targetFirstTest = initFixed.then(beginExit).then(lockDrain)
    .then(abandon).then(releaseTarget).then(checkOwner).then(releaseCheck)
    .then(lockMutex).then(lockOwner).then(inspectOwner).then(releasePeer)
    .then(all { assert(terminal), assert(s.observedTerminated), assert(safe), s' = s })
  run logicalOwnershipTest = initOld.then(all {
    assert(s.logicallyOwned), assert(s.mutexLock == 0), assert(s.threadLock == 0),
    s' = s,
  })
  run entryOnlyStillCyclesTest = initEntryOnly.then(checkOwner).then(releaseCheck)
    .then(lockMutex).then(lockOwner).then(inspectOwner).then(enterSlow)
    .then(beginExit)
    .then(all { assert(waitCycle), assert(not(serviceable)), assert(ownership), s' = s })
  run slowEscapeTest = initFixed.then(checkOwner).then(releaseCheck)
    .then(lockMutex).then(lockOwner).then(inspectOwner).then(enterSlow)
    .then(beginExit).then(slowDropMutex).then(lockDrain).then(abandon)
    .then(releaseTarget).then(slowWaitOwner).then(slowReacquireMutex)
    .then(releasePeer)
    .then(all { assert(terminal), assert(s.observedTerminated), assert(safe), s' = s })
}
