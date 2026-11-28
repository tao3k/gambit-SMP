module exit_drain_mutex_lock_order {
  // Two processor actors, not a machine CPU setting. Locks: 0 free, 1 peer, 2 target.
  // Logical ownership does not mean the low-level mutex lock is held.
  type State = { releaseOnContention: bool, releaseSlow: bool, peer: int, target: int,
    mutexLock: int, threadLock: int, logicallyOwned: bool,
    terminated: bool, observedTerminated: bool, slowChecked: bool,
    childStarted: bool, childJoined: bool, gcBranch: int, resultMutex: int,
    headStarted: bool, headFinished: bool, headJoined: bool, otherFinished: int,
    observerQueued: bool, observerRan: bool,
    // Zero-timeout thread-join! is not the blocking head join.
    // headProbeReturned means the timeout-already-reached path returned.
    // headProbeSpinning means macro-lock-thread! is still retrying.
    syncOpPending: bool, headProbeReturned: bool, headProbeSpinning: bool,
    // SMP thread-start! queues and returns. starterCurrent stays true
    // until a later schedule point. queuedRootRan is not headFinished.
    starterCurrent: bool, rootOnCurrent: bool, idleWake: bool,
    quantumExhausted: bool, queuedRootRan: bool, underQuantumStayed: bool }
  var s: State
  pure def initial(releaseOnContention: bool, releaseSlow: bool): State = {
    releaseOnContention: releaseOnContention, releaseSlow: releaseSlow, peer: 0, target: 0,
    mutexLock: 0, threadLock: 0, logicallyOwned: true,
    terminated: false, observedTerminated: false, slowChecked: false,
    childStarted: false, childJoined: false, gcBranch: 0, resultMutex: 0,
    headStarted: false, headFinished: false, headJoined: false, otherFinished: 0,
    observerQueued: false, observerRan: false,
    syncOpPending: false, headProbeReturned: false, headProbeSpinning: false,
    starterCurrent: true, rootOnCurrent: false, idleWake: false,
    quantumExhausted: false, queuedRootRan: false, underQuantumStayed: false
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
  // Net effect of ##thread-start!: lock the child, mark it started, enqueue,
  // unlock. That body does not call macro-mutex-lock!. Outside step so it
  // cannot starve weakFair(step). Not a model of the temporary thread hold.
  action startChild = all {
    s.threadLock == 0, s.mutexLock == 0, not(s.childStarted),
    s' = { ...s, childStarted: true },
  }
  // Net effect of ##thread-join! on the end condvar. It does not call
  // macro-mutex-lock!. Atomic net only: the temporary thread and condvar
  // holds are not a second lock-order proof.
  action joinChild = all {
    s.childStarted, not(s.childJoined), s.threadLock == 0, s.mutexLock == 0,
    s' = { ...s, childJoined: true },
  }
  // Net effect of the interpreted busy-sleep loop. No child, no mutex, and
  // no thread lock. Outside step. This module has no processor-0 GC clock,
  // no barrier, and no pthread_cond_wait, so the action cannot explain a
  // GC-real wall gap.
  action delayOutsideLockOrder = all {
    s.peer == 0, s.target == 0, s.mutexLock == 0, s.threadLock == 0,
    not(s.childStarted), not(s.childJoined),
    s' = s,
  }
  // ##interrupt-some-thread-async! calls the thunk when a thread is current.
  // ##handle-gc-interrupt! is ##gc-finalize! plus ##execute-jobs!. That
  // definition does not call macro-mutex-lock!. Finalizers and jobs are not
  // expanded. This is the post-window notification, not the collector barrier,
  // and it is outside step.
  action gcNotifyCurrentThread = all {
    s.gcBranch == 0, s.mutexLock == 0, s.threadLock == 0, s.resultMutex == 0,
    s' = { ...s, gcBranch: 1 },
  }
  // No current thread: ##thread-intr! of the primordial thread with async #t
  // calls macro-mutex-lock! once on a fresh result mutex, then returns. The
  // synchronous second lock is not taken. Fast path only: contention drop is
  // a different action and is not implied. The exit-drain mutex stays free.
  action gcNotifyNoCurrentThread = all {
    s.gcBranch == 0, s.threadLock == 0, s.resultMutex == 0,
    s' = { ...s, gcBranch: 2, resultMutex: 1 },
  }
  // Scheme go starts every root, then thread-join! walks the list from the
  // head. The join waits on that thread's end condvar and does not call
  // macro-mutex-lock!. A later root finishing does not unblock the head
  // join. Outside step. Not a measure of how many roots are running.
  action startPopulation = all {
    not(s.headStarted), s.mutexLock == 0, s.threadLock == 0,
    s' = { ...s, headStarted: true },
  }
  action finishOtherRoot = all {
    s.headStarted, not(s.headJoined),
    s' = { ...s, otherFinished: s.otherFinished + 1 },
  }
  action finishHead = all {
    s.headStarted, not(s.headFinished),
    s' = { ...s, headFinished: true },
  }
  action joinHead = all {
    s.headFinished, not(s.headJoined), s.mutexLock == 0, s.threadLock == 0,
    s' = { ...s, headJoined: true },
  }
  // ##absrel-timeout->timeout maps a fixnum <= 0 to #f. ##thread-join!
  // then sees the timeout as already reached. If the end condvar still
  // exists it returns timeout-val; if the condvar is already gone it
  // returns the thread result. Neither branch waits on the condvar.
  // Both sit after macro-lock-thread!. That macro spins in
  // ##lock-scheduler-object-with-sync-participation! while the trylock
  // fails and INTR_SYNC_OP is clear. The spin is not the condvar wait,
  // not a duration, and outside step.
  action zeroTimeoutProbeReturns = all {
    s.headStarted, not(s.headProbeReturned), s.threadLock == 0, s.mutexLock == 0,
    s' = { ...s, headProbeReturned: true, headProbeSpinning: false },
  }
  action zeroTimeoutProbeSpins = all {
    s.headStarted, not(s.headProbeReturned), s.threadLock != 0, not(s.syncOpPending),
    s' = { ...s, headProbeSpinning: true },
  }
  // enable-smp ##thread-start! locks the child, marks it started, and
  // calls macro-add-thread-to-run-queue-of-some-processor!. The
  // reschedule call is commented out. When the VM trylock fails or the
  // idle deque's head is the VM, the child is inserted on the current
  // processor only. The starter stays current and the child has not run.
  // startPopulation remains the net "all roots queued" effect and does
  // not choose this queue. Outside step. Not a 25-second measurement.
  action startQueuesOnCurrentProcessor = all {
    not(s.headStarted), s.threadLock == 0, s.mutexLock == 0, s.starterCurrent,
    s' = { ...s, headStarted: true, rootOnCurrent: true, idleWake: false,
      queuedRootRan: false },
  }
  // The other branch removes one idle processor from the VM deque,
  // inserts the child there, and ##wait-abort-no-remove!s that processor.
  // ##wait! is what puts an empty processor on that deque. Waking it
  // does not switch the starter, and this action does not claim the
  // child executed. Outside step.
  action startWakesIdleProcessor = all {
    not(s.headStarted), s.threadLock == 0, s.mutexLock == 0, s.starterCurrent,
    s' = { ...s, headStarted: true, idleWake: true, rootOnCurrent: false,
      queuedRootRan: false },
  }
  // enable-smp macro-thread-reschedule-if-needed! expands to ##void.
  // ##thread-heartbeat! calls it only while quantum-used is still below
  // the quantum. That call does not switch. The non-SMP else branch is
  // a different macro. Outside step. Not a delivered heartbeat.
  action underQuantumHeartbeatStays = all {
    s.headStarted, s.starterCurrent, s.rootOnCurrent, not(s.quantumExhausted),
    not(s.queuedRootRan),
    s' = { ...s, underQuantumStayed: true },
  }
  // Assumption only: this is not a timer transition and does not assert
  // that a heartbeat arrived. ##thread-yield! then runs when
  // macro-if-btq-next finds a leftmost thread. The starter is requeued
  // and ##thread-schedule-with-acquired-processor! runs that thread.
  // queuedRootRan is not headFinished.
  action noteQuantumExhausted = all {
    s.headStarted, s.starterCurrent, not(s.quantumExhausted),
    s' = { ...s, quantumExhausted: true },
  }
  action quantumYieldRunsQueuedRoot = all {
    s.headStarted, s.starterCurrent, s.rootOnCurrent, s.quantumExhausted,
    not(s.queuedRootRan),
    s' = { ...s, starterCurrent: false, queuedRootRan: true },
  }
  // ##thread-sleep! removes the current thread and puts it on the processor
  // timeout queue. ##thread-check-timeouts! later ##btq-insert!s it on that
  // processor's run queue. Insertion is not execution: ##thread-schedule
  // runs macro-btq-leftmost, the highest effective priority. Equal priorities
  // are not ranked here. ##thread-heartbeat! calls ##thread-yield! when
  // quantum-used is no longer below the quantum, and that yield also queues
  // the current thread when another runnable thread exists. Outside step.
  // Not a queue-length measurement and not a CPU sample.
  action queueSleepingObserver = all {
    s.headStarted, not(s.observerQueued), not(s.observerRan),
    s.mutexLock == 0, s.threadLock == 0,
    s' = { ...s, observerQueued: true },
  }
  action countOtherWhileObserverQueued = all {
    s.observerQueued, not(s.observerRan),
    s' = { ...s, otherFinished: s.otherFinished + 1 },
  }
  action runQueuedObserver = all {
    s.observerQueued, not(s.observerRan),
    s' = { ...s, observerRan: true },
  }
  // Source constants from the SMP macros. Not a clock and not a wait.
  // 10000 is (exact->inexact 1/100) in microseconds. 20000 is the root quantum.
  // 168012 is the one-processor p5 minus p4 non-GC wall, already measured.
  val heartbeatIntervalMicros = 10000
  val rootQuantumMicros = 20000
  val observedOutsideGcMicros = 168012
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
  // Same formula, separate name so the entry-only negative control can name
  // its own initializer. Not a new safety property.
  val entryChecked = checked
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
  // Coverage separation only. These runs do not explain the TFIB timeout.
  run tfibJoinWithoutMutexTest = initOld.then(startChild).then(joinChild)
    .then(all {
      assert(s.childStarted), assert(s.childJoined),
      assert(s.mutexLock == 0), assert(s.threadLock == 0), assert(s.peer == 0),
      assert(not(waitCycle)), s' = s
    })
  run fixedTfibJoinWithoutMutexTest = initFixed.then(startChild).then(joinChild)
    .then(all {
      assert(s.childStarted), assert(s.childJoined),
      assert(s.mutexLock == 0), assert(s.threadLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  run probeNotTfibTest = initFixed.then(checkOwner).then(releaseCheck).then(lockMutex)
    .then(all {
      assert(s.peer == 3), assert(s.mutexLock == 1),
      assert(not(s.childStarted)), assert(not(s.childJoined)),
      s' = s
    })
  // The measured delay loop is this stutter, not waitCycle. Passing it does
  // not attribute processor-0 GC wall to the patched mutex macro.
  run delayLoopOutsideLockOrderTest = initOld.then(delayOutsideLockOrder)
    .then(all {
      assert(s.peer == 0), assert(s.target == 0),
      assert(s.mutexLock == 0), assert(s.threadLock == 0),
      assert(not(s.childStarted)), assert(not(s.childJoined)),
      assert(not(waitCycle)), s' = s
    })
  run gcNotifyCurrentThreadSkipsMutexTest = initFixed.then(gcNotifyCurrentThread)
    .then(all {
      assert(s.gcBranch == 1), assert(s.resultMutex == 0),
      assert(s.mutexLock == 0), assert(s.threadLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  run gcNotifyNoCurrentThreadUsesResultMutexTest = initFixed
    .then(gcNotifyNoCurrentThread)
    .then(all {
      assert(s.gcBranch == 2), assert(s.resultMutex == 1),
      assert(s.mutexLock == 0), assert(s.threadLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  run timerConstantsOutsideDelayTest = initOld.then(delayOutsideLockOrder)
    .then(all {
      assert(heartbeatIntervalMicros != observedOutsideGcMicros),
      assert(rootQuantumMicros != observedOutsideGcMicros),
      assert(heartbeatIntervalMicros == 10000),
      assert(rootQuantumMicros == 20000),
      assert(not(waitCycle)), s' = s
    })
  run orderedJoinWaitsOnHeadTest = initFixed.then(startPopulation).then(finishOtherRoot)
    .then(all {
      assert(s.headStarted), assert(s.otherFinished == 1),
      assert(not(s.headFinished)), assert(not(s.headJoined)),
      assert(s.mutexLock == 0), assert(s.threadLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  run queuedObserverIsNotYetRunningTest = initFixed.then(startPopulation)
    .then(queueSleepingObserver).then(countOtherWhileObserverQueued)
    .then(all {
      assert(s.headStarted), assert(s.observerQueued), assert(not(s.observerRan)),
      assert(s.otherFinished == 1), assert(not(s.headJoined)),
      assert(s.mutexLock == 0), assert(s.threadLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  // The list head has not finished. A zero timeout still returns, and
  // that return is not headJoined. Source correspondence only.
  run zeroTimeoutProbeDoesNotWaitOnHeadTest = initFixed.then(startPopulation)
    .then(zeroTimeoutProbeReturns)
    .then(all {
      assert(s.headStarted), assert(not(s.headFinished)), assert(not(s.headJoined)),
      assert(s.headProbeReturned), assert(not(s.headProbeSpinning)),
      assert(s.threadLock == 0), assert(s.mutexLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  // beginExit holds the thread lock. The probe cannot take it, and a
  // clear sync-op flag does not leave the retry. Not a native sample.
  run heldThreadLockSpinsWithoutSyncOpTest = initFixed.then(startPopulation)
    .then(beginExit).then(zeroTimeoutProbeSpins)
    .then(all {
      assert(s.headStarted), assert(s.threadLock == 2), assert(not(s.syncOpPending)),
      assert(s.headProbeSpinning), assert(not(s.headProbeReturned)),
      assert(not(s.headJoined)),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  // thread-start! returned. The root is on the current processor and
  // has not run. This is the enable-smp body, not the non-SMP reschedule.
  run startLeavesRootOnCurrentProcessorTest = initFixed
    .then(startQueuesOnCurrentProcessor)
    .then(all {
      assert(s.headStarted), assert(s.rootOnCurrent), assert(not(s.idleWake)),
      assert(s.starterCurrent), assert(not(s.queuedRootRan)),
      assert(not(s.headFinished)), assert(not(s.headJoined)),
      assert(s.threadLock == 0), assert(s.mutexLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  // An idle processor can be woken from inside thread-start!. The
  // starter is still current, and the child executing is not asserted.
  run idleWakeLeavesStarterCurrentTest = initFixed
    .then(startWakesIdleProcessor)
    .then(all {
      assert(s.headStarted), assert(s.idleWake), assert(not(s.rootOnCurrent)),
      assert(s.starterCurrent), assert(not(s.queuedRootRan)),
      assert(not(s.headFinished)),
      assert(s.threadLock == 0), assert(s.mutexLock == 0),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  // While the quantum remains, heartbeat's reschedule macro is void.
  run underQuantumHeartbeatStaysOnStarterTest = initFixed
    .then(startQueuesOnCurrentProcessor).then(underQuantumHeartbeatStays)
    .then(all {
      assert(s.underQuantumStayed), assert(s.starterCurrent),
      assert(s.rootOnCurrent), assert(not(s.quantumExhausted)),
      assert(not(s.queuedRootRan)), assert(not(s.headFinished)),
      assert(not(waitCycle)), assert(safe), s' = s
    })
  // The quantum flag is assumed, not delivered. Yield can then run the
  // queued root. That run is not completion of tfib.
  run assumedQuantumYieldRunsQueuedRootTest = initFixed
    .then(startQueuesOnCurrentProcessor).then(noteQuantumExhausted)
    .then(quantumYieldRunsQueuedRoot)
    .then(all {
      assert(s.quantumExhausted), assert(s.queuedRootRan),
      assert(not(s.starterCurrent)), assert(s.rootOnCurrent),
      assert(not(s.headFinished)), assert(not(s.headJoined)),
      assert(not(waitCycle)), assert(safe), s' = s
    })
}

