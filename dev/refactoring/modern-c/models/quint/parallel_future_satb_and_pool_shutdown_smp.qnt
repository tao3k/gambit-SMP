// Quint formal model for (gambit parallel):
//   1. SATB-safe single-run ws-future state machine (PENDING -> RUNNING -> DONE)
//      with eager thunk clearing before release publication of DONE.
//   2. Concurrent multi-caller idempotent work-stealing-pool-shutdown!
//      (RUNNING=0 -> SHUTTING_DOWN=1 -> SHUTDOWN_DONE=2) with unique joiner
//      and wait-for-quiescence barrier.

module parallel_future_satb_and_pool_shutdown_smp {
  // Future state constants
  pure val F_PENDING = 0
  pure val F_RUNNING = 1
  pure val F_DONE_OK = 2
  pure val F_DONE_ERR = 3

  // Pool shutdown state constants
  pure val P_RUNNING = 0
  pure val P_SHUTTING_DOWN = 1
  pure val P_SHUTDOWN_DONE = 2

  pure val RACERS = Set(0, 1, 2)
  pure val SHUTTERS = Set(0, 1, 2)

  // Future state variables
  var fState: int
  var fThunkAlive: bool
  var fSatbActive: bool
  var fSatbShadedThunk: bool
  var fRuns: int
  var fWinner: int          // -1 if unclaimed, else racer id
  var fClearedThunk: bool   // winner cleared f.thunk before publishing DONE
  var fObservedVal: int -> int // -1 = none, 0 = ok, 1 = err

  // Pool shutdown state variables
  var pShutState: int
  var pJoinCalls: int
  var pWorkersAlive: bool
  var pCallerReturned: int -> bool
  var pCallerSawAliveOnReturn: bool

  action init = all {
    fState' = F_PENDING,
    fThunkAlive' = true,
    fSatbActive' = true,
    fSatbShadedThunk' = false,
    fRuns' = 0,
    fWinner' = -1,
    fClearedThunk' = false,
    fObservedVal' = RACERS.mapBy(_ => -1),
    pShutState' = P_RUNNING,
    pJoinCalls' = 0,
    pWorkersAlive' = true,
    pCallerReturned' = SHUTTERS.mapBy(_ => false),
    pCallerSawAliveOnReturn' = false,
  }

  // Racer attempts atomic CAS(fState, PENDING -> RUNNING)
  action claimFuture(r: int): bool = all {
    fState == F_PENDING,
    fWinner == -1,
    fState' = F_RUNNING,
    fWinner' = r,
    fRuns' = fRuns + 1,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fClearedThunk' = fClearedThunk,
    fObservedVal' = fObservedVal,
    pShutState' = pShutState,
    pJoinCalls' = pJoinCalls,
    pWorkersAlive' = pWorkersAlive,
    pCallerReturned' = pCallerReturned,
    pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
  }

  // Winner eagerly clears f.thunk with SATB pre-write shade before publishing DONE
  action clearThunkWithSatb(r: int): bool = all {
    fState == F_RUNNING,
    fWinner == r,
    fThunkAlive,
    fThunkAlive' = false,
    fSatbShadedThunk' = if (fSatbActive) true else fSatbShadedThunk,
    fClearedThunk' = true,
    fState' = fState,
    fSatbActive' = fSatbActive,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fObservedVal' = fObservedVal,
    pShutState' = pShutState,
    pJoinCalls' = pJoinCalls,
    pWorkersAlive' = pWorkersAlive,
    pCallerReturned' = pCallerReturned,
    pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
  }

  // Winner publishes DONE_OK or DONE_ERR with release ordering after clearing thunk
  action publishFutureResult(r: int, isErr: bool): bool = all {
    fState == F_RUNNING,
    fWinner == r,
    fClearedThunk,
    fState' = if (isErr) F_DONE_ERR else F_DONE_OK,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fClearedThunk' = fClearedThunk,
    fObservedVal' = fObservedVal,
    pShutState' = pShutState,
    pJoinCalls' = pJoinCalls,
    pWorkersAlive' = pWorkersAlive,
    pCallerReturned' = pCallerReturned,
    pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
  }

  // Any racer observes published DONE state via acquire load
  action observeFuture(r: int): bool = all {
    (fState == F_DONE_OK or fState == F_DONE_ERR),
    fObservedVal.get(r) == -1,
    fObservedVal' = fObservedVal.set(r, if (fState == F_DONE_OK) 0 else 1),
    fState' = fState,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fClearedThunk' = fClearedThunk,
    pShutState' = pShutState,
    pJoinCalls' = pJoinCalls,
    pWorkersAlive' = pWorkersAlive,
    pCallerReturned' = pCallerReturned,
    pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
  }

  // Caller wins CAS(pShutState, RUNNING -> SHUTTING_DOWN) and joins workers once
  action shutdownClaimAndJoin(c: int): bool = all {
    pShutState == P_RUNNING,
    not(pCallerReturned.get(c)),
    pShutState' = P_SHUTTING_DOWN,
    pJoinCalls' = pJoinCalls + 1,
    pWorkersAlive' = false,
    pCallerReturned' = pCallerReturned,
    pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
    fState' = fState,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fClearedThunk' = fClearedThunk,
    fObservedVal' = fObservedVal,
  }

  // Winner marks SHUTDOWN_DONE after all worker threads have joined
  action shutdownComplete(c: int): bool = all {
    pShutState == P_SHUTTING_DOWN,
    not(pWorkersAlive),
    not(pCallerReturned.get(c)),
    pShutState' = P_SHUTDOWN_DONE,
    pCallerReturned' = pCallerReturned.set(c, true),
    pCallerSawAliveOnReturn' = (pCallerSawAliveOnReturn or pWorkersAlive),
    pJoinCalls' = pJoinCalls,
    pWorkersAlive' = pWorkersAlive,
    fState' = fState,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fClearedThunk' = fClearedThunk,
    fObservedVal' = fObservedVal,
  }

  // Concurrent / repeat caller waits until pShutState == SHUTDOWN_DONE then returns
  action shutdownWaiterReturn(c: int): bool = all {
    pShutState == P_SHUTDOWN_DONE,
    not(pCallerReturned.get(c)),
    pCallerReturned' = pCallerReturned.set(c, true),
    pCallerSawAliveOnReturn' = (pCallerSawAliveOnReturn or pWorkersAlive),
    pShutState' = pShutState,
    pJoinCalls' = pJoinCalls,
    pWorkersAlive' = pWorkersAlive,
    fState' = fState,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fClearedThunk' = fClearedThunk,
    fObservedVal' = fObservedVal,
  }

  // Buggy action: publishes DONE without clearing thunk (reproduces closure retention leak)
  action buggyPublishWithoutClearingThunk(r: int): bool = all {
    fState == F_RUNNING,
    fWinner == r,
    fState' = F_DONE_OK,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fClearedThunk' = fClearedThunk,
    fObservedVal' = fObservedVal,
    pShutState' = pShutState,
    pJoinCalls' = pJoinCalls,
    pWorkersAlive' = pWorkersAlive,
    pCallerReturned' = pCallerReturned,
    pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
  }

  // Buggy action: non-atomic shutdown allows duplicate join call
  action buggyDuplicateShutdownJoin(c: int): bool = all {
    pShutState == P_SHUTTING_DOWN,
    pJoinCalls' = pJoinCalls + 1,
    pShutState' = pShutState,
    pWorkersAlive' = pWorkersAlive,
    pCallerReturned' = pCallerReturned,
    pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
    fState' = fState,
    fThunkAlive' = fThunkAlive,
    fSatbActive' = fSatbActive,
    fSatbShadedThunk' = fSatbShadedThunk,
    fRuns' = fRuns,
    fWinner' = fWinner,
    fClearedThunk' = fClearedThunk,
    fObservedVal' = fObservedVal,
  }

  action step = any {
    nondet r = oneOf(RACERS)
    any {
      claimFuture(r),
      clearThunkWithSatb(r),
      publishFutureResult(r, false),
      publishFutureResult(r, true),
      observeFuture(r),
    },
    nondet c = oneOf(SHUTTERS)
    any {
      shutdownClaimAndJoin(c),
      shutdownComplete(c),
      shutdownWaiterReturn(c),
    },
    // Stutter once terminal
    all {
      (fState == F_DONE_OK or fState == F_DONE_ERR),
      pShutState == P_SHUTDOWN_DONE,
      fState' = fState,
      fThunkAlive' = fThunkAlive,
      fSatbActive' = fSatbActive,
      fSatbShadedThunk' = fSatbShadedThunk,
      fRuns' = fRuns,
      fWinner' = fWinner,
      fClearedThunk' = fClearedThunk,
      fObservedVal' = fObservedVal,
      pShutState' = pShutState,
      pJoinCalls' = pJoinCalls,
      pWorkersAlive' = pWorkersAlive,
      pCallerReturned' = pCallerReturned,
      pCallerSawAliveOnReturn' = pCallerSawAliveOnReturn,
    }
  }

  // Safety invariants
  val invSingleRun: bool = (fRuns <= 1)
  val invDoneClearsThunk: bool =
    ((fState == F_DONE_OK or fState == F_DONE_ERR) implies (not(fThunkAlive) and fSatbShadedThunk))
  val invConsistentObservations: bool =
    RACERS.forall(r1 => RACERS.forall(r2 =>
      (fObservedVal.get(r1) != -1 and fObservedVal.get(r2) != -1)
        implies (fObservedVal.get(r1) == fObservedVal.get(r2))))
  val invUniqueJoiner: bool = (pJoinCalls <= 1)
  val invShutdownReturnQuiescent: bool = not(pCallerSawAliveOnReturn)

  val safety: bool = all {
    invSingleRun,
    invDoneClearsThunk,
    invConsistentObservations,
    invUniqueJoiner,
    invShutdownReturnQuiescent,
  }

  run normalFutureLifecycleTest = {
    init
      .then(claimFuture(0))
      .then(clearThunkWithSatb(0))
      .then(publishFutureResult(0, false))
      .then(observeFuture(1))
      .then(observeFuture(2))
      .expect(safety and fRuns == 1 and not(fThunkAlive) and fSatbShadedThunk)
  }

  run errFutureBroadcastTest = {
    init
      .then(claimFuture(2))
      .then(clearThunkWithSatb(2))
      .then(publishFutureResult(2, true))
      .then(observeFuture(0))
      .then(observeFuture(1))
      .expect(safety and fObservedVal.get(0) == 1 and fObservedVal.get(1) == 1)
  }

  run concurrentIdempotentShutdownTest = {
    init
      .then(shutdownClaimAndJoin(0))
      .then(shutdownComplete(0))
      .then(shutdownWaiterReturn(1))
      .then(shutdownWaiterReturn(2))
      .expect(safety and pJoinCalls == 1 and pCallerReturned.get(1) and pCallerReturned.get(2))
  }

  run buggyThunkLeakDetectedTest = {
    init
      .then(claimFuture(0))
      .then(buggyPublishWithoutClearingThunk(0))
      .expect(not(invDoneClearsThunk))
  }

  run buggyDuplicateJoinDetectedTest = {
    init
      .then(shutdownClaimAndJoin(0))
      .then(buggyDuplicateShutdownJoin(1))
      .expect(not(invUniqueJoiner))
  }
}
