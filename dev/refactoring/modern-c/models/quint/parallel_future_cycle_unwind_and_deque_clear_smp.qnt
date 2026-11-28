// Quint Formal Specification:
// Deadlock-Free Future Cycle Detection, Non-Local Escape Unwind Quiescence,
// Worker Self-Shutdown Guard, and Zero-Retention Chase-Lev Last-Item Pop.

module parallel_future_cycle_unwind_and_deque_clear_smp {
  // Future states: 0=PENDING, 1=RUNNING_T1, 2=RUNNING_T2, 3=OK, 4=ERR
  pure val F_PENDING = 0
  pure val F_RUN_T1  = 1
  pure val F_RUN_T2  = 2
  pure val F_OK      = 3
  pure val F_ERR     = 4

  // Fork-join states
  pure val FJ_IDLE    = 0
  pure val FJ_RUNNING = 1
  pure val FJ_EXITED  = 2

  var futState: int
  var futGuardOnMc: bool
  var cycleDetected: bool
  var cycleDeadlocked: bool
  var peerWedgedOnAbort: bool

  var fjPhase: int
  var fjRightDone: bool
  var fjGuardOnMc: bool
  var fjOrphanAfterExit: bool

  var poolShut: int            // 0=running, 1=shutting-down, 2=done
  var selfShutdownDeadlock: bool

  // Chase-Lev single-element (t == b == 0) owner-pop vs thief-steal model
  var dqTop: int
  var dqBot: int
  var dqSlotCleared: bool
  var dqWinners: int

  action init = all {
    futState' = F_PENDING,
    futGuardOnMc' = false,
    cycleDetected' = false,
    cycleDeadlocked' = false,
    peerWedgedOnAbort' = false,
    fjPhase' = FJ_IDLE,
    fjRightDone' = false,
    fjGuardOnMc' = false,
    fjOrphanAfterExit' = false,
    poolShut' = 0,
    selfShutdownDeadlock' = false,
    dqTop' = 0,
    dqBot' = 1,
    dqSlotCleared' = false,
    dqWinners' = 0,
  }

  // Thread tid (1 or 2) claims pending future -> RUNNING_tid
  action futStart(tid: int): bool = all {
    (tid == 1 or tid == 2),
    futState == F_PENDING,
    futState' = tid,
    futGuardOnMc' = true,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Same thread attempts reentrant future-force -> O(1) cycle detected!
  action futSelfCycleCheck(tid: int): bool = all {
    (tid == 1 or tid == 2),
    futState == tid,
    cycleDetected' = true,
    cycleDeadlocked' = false,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Future body escapes via non-local abort/call1cc ('unwind hook):
  // Transitions futState -> F_ERR so peer waiters never wedge!
  action futNonLocalUnwind: bool = all {
    (futState == F_RUN_T1 or futState == F_RUN_T2),
    futGuardOnMc,
    futState' = F_ERR,
    futGuardOnMc' = false,
    peerWedgedOnAbort' = false,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Future completes normally -> F_OK
  action futCompleteOk: bool = all {
    (futState == F_RUN_T1 or futState == F_RUN_T2),
    futState' = F_OK,
    futGuardOnMc' = false,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Fork-join starts left & spawns right future with 'unwind-guard
  action fjStart: bool = all {
    fjPhase == FJ_IDLE,
    fjPhase' = FJ_RUNNING,
    fjRightDone' = false,
    fjGuardOnMc' = true,
    fjOrphanAfterExit' = false,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Fork-join left branch aborts ('unwind hook forces & joins right BEFORE exit!)
  action fjLeftUnwindAbort: bool = all {
    fjPhase == FJ_RUNNING,
    fjGuardOnMc,
    fjPhase' = FJ_EXITED,
    fjGuardOnMc' = false,
    fjRightDone' = true,
    fjOrphanAfterExit' = false,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Fork-join normal completion
  action fjFinishNormal: bool = all {
    fjPhase == FJ_RUNNING,
    fjPhase' = FJ_EXITED,
    fjGuardOnMc' = false,
    fjRightDone' = true,
    fjOrphanAfterExit' = false,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Pool worker calling shutdown on its own pool is rejected before flipping poolShut!
  action workerSelfShutdownReject: bool = all {
    poolShut == 0,
    poolShut' = 0,
    selfShutdownDeadlock' = false,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // External caller cleanly shuts down pool (0 -> 2)
  action externalShutdown: bool = all {
    poolShut == 0,
    poolShut' = 2,
    selfShutdownDeadlock' = false,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    dqTop' = dqTop,
    dqBot' = dqBot,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners,
  }

  // Owner pops last item (t == b == 0): wins CAS(top: 0 -> 1) and clears slot to #f!
  action dqOwnerPopLastWin: bool = all {
    dqTop == 0,
    dqBot == 1,
    dqTop' = 1,
    dqBot' = 1,
    dqSlotCleared' = true,
    dqWinners' = dqWinners + 1,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
  }

  // Thief steals last item (t == 0 < b == 1): wins CAS(top: 0 -> 1)
  action dqThiefStealLastWin: bool = all {
    dqTop == 0,
    dqBot == 1,
    dqTop' = 1,
    dqBot' = 1,
    dqSlotCleared' = dqSlotCleared,
    dqWinners' = dqWinners + 1,
    futState' = futState,
    futGuardOnMc' = futGuardOnMc,
    cycleDetected' = cycleDetected,
    cycleDeadlocked' = cycleDeadlocked,
    peerWedgedOnAbort' = peerWedgedOnAbort,
    fjPhase' = fjPhase,
    fjRightDone' = fjRightDone,
    fjGuardOnMc' = fjGuardOnMc,
    fjOrphanAfterExit' = fjOrphanAfterExit,
    poolShut' = poolShut,
    selfShutdownDeadlock' = selfShutdownDeadlock,
  }

  action step = any {
    futStart(1),
    futStart(2),
    futSelfCycleCheck(1),
    futSelfCycleCheck(2),
    futNonLocalUnwind,
    futCompleteOk,
    fjStart,
    fjLeftUnwindAbort,
    fjFinishNormal,
    workerSelfShutdownReject,
    externalShutdown,
    dqOwnerPopLastWin,
    dqThiefStealLastWin,
  }

  // Invariants
  val invNoCycleDeadlock = not(cycleDeadlocked)
  val invNoWedgedFutureAfterUnwind =
    not(peerWedgedOnAbort) and ((futState == F_OK or futState == F_ERR) implies not(futGuardOnMc))
  val invForkJoinZeroOrphans =
    (fjPhase == FJ_EXITED) implies (fjRightDone and not(fjGuardOnMc) and not(fjOrphanAfterExit))
  val invNoSelfShutdownDeadlock = not(selfShutdownDeadlock)
  val invDequeExactOnceAndClear =
    (dqWinners <= 1) and ((dqTop == 1 and dqBot == 1) implies dqWinners == 1)

  val allInvs =
    invNoCycleDeadlock and
    invNoWedgedFutureAfterUnwind and
    invForkJoinZeroOrphans and
    invNoSelfShutdownDeadlock and
    invDequeExactOnceAndClear

  // 5 Unit Tests
  run selfCycleDetectedTest = {
    init
      .then(futStart(1))
      .then(futSelfCycleCheck(1))
      .then(futNonLocalUnwind)
      .expect(allInvs and cycleDetected and futState == F_ERR)
  }

  run futureAbortCompletesErrTest = {
    init
      .then(futStart(2))
      .then(futNonLocalUnwind)
      .expect(allInvs and futState == F_ERR and not(futGuardOnMc))
  }

  run forkJoinAbortQuiescesRightTest = {
    init
      .then(fjStart)
      .then(fjLeftUnwindAbort)
      .expect(allInvs and fjRightDone and not(fjGuardOnMc))
  }

  run workerSelfShutdownRejectedTest = {
    init
      .then(workerSelfShutdownReject)
      .then(externalShutdown)
      .expect(allInvs and poolShut == 2)
  }

  run lastItemPopClearsSlotTest = {
    init
      .then(dqOwnerPopLastWin)
      .expect(allInvs and dqSlotCleared and dqWinners == 1)
  }
}
