// Quint Formal Specification:
// Structured-Concurrency Nursery & with-finally 3-Phase Unwind-Hook Coherency
// Across SRFI-226/Effect Non-Local Escapes, Plus Post-Close rx-fast/tx-fast ABA Guard.

module fiber_nursery_finally_unwind_and_close_aba_smp {
  // Nursery lifecycle states: 0=live, 1=cancelled, 2=closed
  pure val N_LIVE      = 0
  pure val N_CANCELLED = 1
  pure val N_CLOSED    = 2

  // Control flow scope phase
  pure val S_OUTSIDE   = 0
  pure val S_IN_SCOPE  = 1
  pure val S_SUSPENDED = 2
  pure val S_EXITED    = 3

  // Channel close / fast-slot ABA states
  pure val CH_OPEN   = 0
  pure val CH_CLOSED = 1

  var scopePhase: int
  var nState: int
  var nActive: int          // >= 0: parent (1) + live children
  var nJoined: bool
  var nGuardOnMc: bool
  var childSpawned: bool
  var childDone: bool
  var childSawCancel: bool
  var orphanAfterExit: bool
  var activeWentNegative: bool

  var finallyCount: int
  var finallyGuardOnMc: bool

  var chState: int
  var rxfOccupied: bool
  var postCloseDelivery: bool

  action init = all {
    scopePhase' = S_OUTSIDE,
    nState' = N_LIVE,
    nActive' = 0,
    nJoined' = false,
    nGuardOnMc' = false,
    childSpawned' = false,
    childDone' = false,
    childSawCancel' = false,
    orphanAfterExit' = false,
    activeWentNegative' = false,
    finallyCount' = 0,
    finallyGuardOnMc' = false,
    chState' = CH_OPEN,
    rxfOccupied' = false,
    postCloseDelivery' = false,
  }

  // Enter with-nursery + with-finally inside an active outer prompt/handler
  action enterScope: bool = all {
    scopePhase == S_OUTSIDE,
    scopePhase' = S_IN_SCOPE,
    nState' = N_LIVE,
    nActive' = 1,
    nJoined' = false,
    nGuardOnMc' = true,
    childSpawned' = false,
    childDone' = false,
    childSawCancel' = false,
    orphanAfterExit' = false,
    activeWentNegative' = false,
    finallyCount' = 0,
    finallyGuardOnMc' = true,
    chState' = chState,
    rxfOccupied' = rxfOccupied,
    postCloseDelivery' = postCloseDelivery,
  }

  // Spawn child fiber into live nursery
  action spawnChild: bool = all {
    scopePhase == S_IN_SCOPE,
    nState != N_CLOSED,
    not(childSpawned),
    nActive' = nActive + 1,
    childSpawned' = true,
    childDone' = false,
    scopePhase' = scopePhase,
    nState' = nState,
    nJoined' = nJoined,
    nGuardOnMc' = nGuardOnMc,
    childSawCancel' = childSawCancel,
    orphanAfterExit' = orphanAfterExit,
    activeWentNegative' = activeWentNegative,
    finallyCount' = finallyCount,
    finallyGuardOnMc' = finallyGuardOnMc,
    chState' = chState,
    rxfOccupied' = rxfOccupied,
    postCloseDelivery' = postCloseDelivery,
  }

  // Child fiber completes asynchronously on peer worker
  action childFinish: bool = all {
    childSpawned,
    not(childDone),
    nActive > 0,
    childDone' = true,
    childSawCancel' = (nState != N_LIVE),
    nActive' = nActive - 1,
    scopePhase' = scopePhase,
    nState' = nState,
    nJoined' = nJoined,
    nGuardOnMc' = nGuardOnMc,
    childSpawned' = childSpawned,
    orphanAfterExit' = orphanAfterExit,
    activeWentNegative' = activeWentNegative,
    finallyCount' = finallyCount,
    finallyGuardOnMc' = finallyGuardOnMc,
    chState' = chState,
    rxfOccupied' = rxfOccupied,
    postCloseDelivery' = postCloseDelivery,
  }

  // Outer algebraic effect perform ('suspend phase):
  // Neither with-nursery nor with-finally tears down on 'suspend!
  action effectSuspend: bool = all {
    scopePhase == S_IN_SCOPE,
    scopePhase' = S_SUSPENDED,
    nGuardOnMc' = false,
    finallyGuardOnMc' = false,
    nState' = nState,
    nActive' = nActive,
    nJoined' = nJoined,
    childSpawned' = childSpawned,
    childDone' = childDone,
    childSawCancel' = childSawCancel,
    orphanAfterExit' = orphanAfterExit,
    activeWentNegative' = activeWentNegative,
    finallyCount' = finallyCount,
    chState' = chState,
    rxfOccupied' = rxfOccupied,
    postCloseDelivery' = postCloseDelivery,
  }

  // Outer handler calls resume ('restore phase):
  // Re-installs both unwind guards and resumes body with nursery still live.
  action effectResume: bool = all {
    scopePhase == S_SUSPENDED,
    scopePhase' = S_IN_SCOPE,
    nGuardOnMc' = true,
    finallyGuardOnMc' = true,
    nState' = nState,
    nActive' = nActive,
    nJoined' = nJoined,
    childSpawned' = childSpawned,
    childDone' = childDone,
    childSawCancel' = childSawCancel,
    orphanAfterExit' = orphanAfterExit,
    activeWentNegative' = activeWentNegative,
    finallyCount' = finallyCount,
    chState' = chState,
    rxfOccupied' = rxfOccupied,
    postCloseDelivery' = postCloseDelivery,
  }

  // Normal return or exception exit from scope:
  // Pops guards, runs finally strictly once, joins any live child, seals nursery CLOSED.
  action normalOrExcExit: bool = {
    val liveChild = childSpawned and not(childDone)
    all {
      scopePhase == S_IN_SCOPE,
      scopePhase' = S_EXITED,
      nGuardOnMc' = false,
      finallyGuardOnMc' = false,
      finallyCount' = if (finallyCount == 0) 1 else finallyCount,
      // Teardown waits for liveChild (if any) to complete before sealing N_CLOSED
      childDone' = if (liveChild) true else childDone,
      childSawCancel' = childSawCancel,
      nActive' = if (not(nJoined)) 0 else nActive,
      nJoined' = true,
      nState' = N_CLOSED,
      orphanAfterExit' = false,
      activeWentNegative' = activeWentNegative,
      childSpawned' = childSpawned,
      chState' = chState,
      rxfOccupied' = rxfOccupied,
      postCloseDelivery' = postCloseDelivery,
    }
  }

  // Non-local escape via abort-current-continuation or call/1cc ('unwind phase):
  // Runs finally strictly once, cancels nursery, joins all live children, seals N_CLOSED!
  action nonLocalUnwindEscape: bool = {
    val liveChild = childSpawned and not(childDone)
    all {
      scopePhase == S_IN_SCOPE,
      nGuardOnMc,
      finallyGuardOnMc,
      scopePhase' = S_EXITED,
      nGuardOnMc' = false,
      finallyGuardOnMc' = false,
      finallyCount' = if (finallyCount == 0) 1 else finallyCount,
      childSawCancel' = if (liveChild) true else childSawCancel,
      childDone' = if (liveChild) true else childDone,
      nActive' = if (not(nJoined)) 0 else nActive,
      nJoined' = true,
      nState' = N_CLOSED,
      orphanAfterExit' = false,
      activeWentNegative' = activeWentNegative,
      childSpawned' = childSpawned,
      chState' = chState,
      rxfOccupied' = rxfOccupied,
      postCloseDelivery' = postCloseDelivery,
    }
  }

  // Multi-shot replay exit hitting already-joined nursery teardown:
  // Idempotent joined guard prevents nActive from going negative!
  action multishotReplayExit: bool = all {
    scopePhase == S_EXITED,
    nJoined,
    // Idempotent: nActive remains 0, finallyCount remains 1
    nActive' = nActive,
    activeWentNegative' = (nActive < 0),
    finallyCount' = finallyCount,
    scopePhase' = scopePhase,
    nState' = nState,
    nJoined' = nJoined,
    nGuardOnMc' = nGuardOnMc,
    childSpawned' = childSpawned,
    childDone' = childDone,
    childSawCancel' = childSawCancel,
    orphanAfterExit' = orphanAfterExit,
    finallyGuardOnMc' = finallyGuardOnMc,
    chState' = chState,
    rxfOccupied' = rxfOccupied,
    postCloseDelivery' = postCloseDelivery,
  }

  // Channel receiver attempts rx-fast park:
  // Pre-CAS check rejects parking whenever chState == CH_CLOSED (no post-close ABA!).
  action chParkRxFast: bool = all {
    not(rxfOccupied),
    if (chState == CH_OPEN) all {
      rxfOccupied' = true,
    } else all {
      rxfOccupied' = false,
    },
    chState' = chState,
    postCloseDelivery' = postCloseDelivery,
    scopePhase' = scopePhase,
    nState' = nState,
    nActive' = nActive,
    nJoined' = nJoined,
    nGuardOnMc' = nGuardOnMc,
    childSpawned' = childSpawned,
    childDone' = childDone,
    childSawCancel' = childSawCancel,
    orphanAfterExit' = orphanAfterExit,
    activeWentNegative' = activeWentNegative,
    finallyCount' = finallyCount,
    finallyGuardOnMc' = finallyGuardOnMc,
  }

  // Channel close: seals tail bit 0 and drains rx-fast atomically
  action chClose: bool = all {
    chState == CH_OPEN,
    chState' = CH_CLOSED,
    rxfOccupied' = false,
    postCloseDelivery' = postCloseDelivery,
    scopePhase' = scopePhase,
    nState' = nState,
    nActive' = nActive,
    nJoined' = nJoined,
    nGuardOnMc' = nGuardOnMc,
    childSpawned' = childSpawned,
    childDone' = childDone,
    childSawCancel' = childSawCancel,
    orphanAfterExit' = orphanAfterExit,
    activeWentNegative' = activeWentNegative,
    finallyCount' = finallyCount,
    finallyGuardOnMc' = finallyGuardOnMc,
  }

  // Sender tries fast-path A1 direct handoff on rx-fast
  action chSendDirectHandoff: bool = all {
    rxfOccupied,
    rxfOccupied' = false,
    postCloseDelivery' = (chState == CH_CLOSED),
    chState' = chState,
    scopePhase' = scopePhase,
    nState' = nState,
    nActive' = nActive,
    nJoined' = nJoined,
    nGuardOnMc' = nGuardOnMc,
    childSpawned' = childSpawned,
    childDone' = childDone,
    childSawCancel' = childSawCancel,
    orphanAfterExit' = orphanAfterExit,
    activeWentNegative' = activeWentNegative,
    finallyCount' = finallyCount,
    finallyGuardOnMc' = finallyGuardOnMc,
  }

  action step = any {
    enterScope,
    spawnChild,
    childFinish,
    effectSuspend,
    effectResume,
    normalOrExcExit,
    nonLocalUnwindEscape,
    multishotReplayExit,
    chParkRxFast,
    chClose,
    chSendDirectHandoff,
  }

  // Invariants
  val invNoOrphanOnExit =
    (scopePhase == S_EXITED) implies
      (not(orphanAfterExit) and nState == N_CLOSED and nActive == 0 and
       (not(childSpawned) or childDone))

  val invFinallyExactOnce =
    ((scopePhase == S_IN_SCOPE or scopePhase == S_SUSPENDED) implies finallyCount == 0) and
    ((scopePhase == S_EXITED) implies finallyCount == 1)

  val invNoNegativeActive = (nActive >= 0) and not(activeWentNegative)

  val invNoStaleGuardAfterExit =
    (scopePhase == S_EXITED) implies (not(nGuardOnMc) and not(finallyGuardOnMc))

  val invNoPostCloseRxFastAba =
    not(postCloseDelivery) and ((chState == CH_CLOSED) implies not(rxfOccupied))

  val allInvs =
    invNoOrphanOnExit and
    invFinallyExactOnce and
    invNoNegativeActive and
    invNoStaleGuardAfterExit and
    invNoPostCloseRxFastAba

  // 5 Unit Tests
  run abortEscapesNurseryAndFinallyTest = {
    init
      .then(enterScope)
      .then(spawnChild)
      .then(nonLocalUnwindEscape)
      .expect(allInvs and childDone and childSawCancel and nState == N_CLOSED and finallyCount == 1)
  }

  run effectSuspendAndResumeKeepsNurseryLiveTest = {
    init
      .then(enterScope)
      .then(spawnChild)
      .then(effectSuspend)
      .then(effectResume)
      .then(normalOrExcExit)
      .expect(allInvs and childDone and nState == N_CLOSED and finallyCount == 1)
  }

  run effectSuspendResumeThenAbortTest = {
    init
      .then(enterScope)
      .then(spawnChild)
      .then(effectSuspend)
      .then(effectResume)
      .then(nonLocalUnwindEscape)
      .expect(allInvs and childDone and childSawCancel and finallyCount == 1)
  }

  run multishotIdempotentTeardownTest = {
    init
      .then(enterScope)
      .then(spawnChild)
      .then(childFinish)
      .then(normalOrExcExit)
      .then(multishotReplayExit)
      .expect(allInvs and nActive == 0 and finallyCount == 1)
  }

  run postCloseRxFastBlockedTest = {
    init
      .then(chParkRxFast)
      .then(chClose)
      .then(chParkRxFast)
      .expect(allInvs and not(rxfOccupied) and not(postCloseDelivery))
  }
}
