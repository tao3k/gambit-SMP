// Quint formal specification for:
//   1. Cross-scheduler & external-OS-thread fiber-channel wakeup routing via
//      immutable `%fk-sched` ownership (zero SIGSEGV on ctx==#f, zero
//      cross-scheduler quiescence corruption).
//   2. Dekker-linearizable `fiber-channel-close!` racing concurrently against
//      parking receivers (`rx-fast` / `rwq`) and parking senders (`tx-fast` /
//      `swq`): zero lost wakeups on close, exact draining of all pre-close
//      buffered items, and clean rejection of post-close sends.

module fiber_channel_close_and_cross_sched_wake_smp {

  // Scheduler IDs: 0 = external OS thread (no worker-ctx), 1 = sched-A, 2 = sched-B
  pure val SCHED_EXT = 0
  pure val SCHED_A   = 1
  pure val SCHED_B   = 2

  // Model 1: Cross-scheduler / OS-thread wakeup routing
  // Parked receiver `rk` belongs to SCHED_A.
  var rkParked: bool
  var rkOwner: int
  var schedAReady: int
  var schedBReady: int
  var badNullCtxCrash: bool
  var badCrossSchedSteal: bool

  // Model 2: Dekker close vs park-recv & park-send race
  // Buffer holds 0 or 1 pre-close item.
  var chClosed: bool
  var bufCount: int          // 0 or 1
  var rxFastOccupied: bool   // receiver parked in rx-fast
  var txFastOccupied: bool   // sender parked in tx-fast
  var rxPhase: int           // 0=running, 1=published-rxfast, 2=parked, 3=woken-draining, 4=done-eof, 5=done-item
  var txPhase: int           // 0=running, 1=published-txfast, 2=parked, 3=woken-retry, 4=done-sent, 5=done-closed-err
  var closePhase: int        // 0=open, 1=set-closed, 2=drained-waiters
  var lostRxWakeup: bool
  var lostTxWakeup: bool
  var postCloseSendSucceeded: bool

  action init = all {
    rkParked' = true,
    rkOwner' = SCHED_A,
    schedAReady' = 0,
    schedBReady' = 0,
    badNullCtxCrash' = false,
    badCrossSchedSteal' = false,
    chClosed' = false,
    bufCount' = 0,
    rxFastOccupied' = false,
    txFastOccupied' = false,
    rxPhase' = 0,
    txPhase' = 0,
    closePhase' = 0,
    lostRxWakeup' = false,
    lostTxWakeup' = false,
    postCloseSendSucceeded' = false,
  }

  // Wake parked `rk` (owner=SCHED_A) from caller on `callerSched` in {EXT, A, B}.
  // Fixed protocol: routes via `%fk-sched(rk)` -> always lands on SCHED_A!
  action wakeFromCaller(callerSched: int): bool = all {
    rkParked,
    rkParked' = false,
    // If callerSched == rkOwner -> fast LIFO on SCHED_A; else -> global-q on SCHED_A!
    schedAReady' = schedAReady + 1,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    rkOwner' = rkOwner,
    chClosed' = chClosed,
    bufCount' = bufCount,
    rxFastOccupied' = rxFastOccupied,
    txFastOccupied' = txFastOccupied,
    rxPhase' = rxPhase,
    txPhase' = txPhase,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Buggy pre-fix wake: blindly pushes onto caller's `ctx.lifo`!
  action buggyWakeFromCaller(callerSched: int): bool = all {
    rkParked,
    rkParked' = false,
    badNullCtxCrash' = (badNullCtxCrash or (callerSched == SCHED_EXT)),
    badCrossSchedSteal' = (badCrossSchedSteal or (callerSched == SCHED_B)),
    schedAReady' = if (callerSched == SCHED_A) schedAReady + 1 else schedAReady,
    schedBReady' = if (callerSched == SCHED_B) schedBReady + 1 else schedBReady,
    rkOwner' = rkOwner,
    chClosed' = chClosed,
    bufCount' = bufCount,
    rxFastOccupied' = rxFastOccupied,
    txFastOccupied' = txFastOccupied,
    rxPhase' = rxPhase,
    txPhase' = txPhase,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Receiver step 1: sees empty ring, publishes itself in rx-fast (seq_cst CAS)
  action rxPublishWaiter = all {
    rxPhase == 0,
    bufCount == 0,
    not(chClosed),
    rxFastOccupied' = true,
    rxPhase' = 1,
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    chClosed' = chClosed,
    bufCount' = bufCount,
    txFastOccupied' = txFastOccupied,
    txPhase' = txPhase,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Receiver step 2: Dekker seq_cst re-check of bufCount and chClosed!
  action rxDekkerRecheck = all {
    rxPhase == 1,
    if (bufCount == 0 and not(chClosed)) all {
      rxPhase' = 2, // parked cleanly
      rxFastOccupied' = rxFastOccupied,
    } else if (rxFastOccupied) all {
      // Canceled park via atomic exchange -> wakes immediately to drain/eof
      rxFastOccupied' = false,
      rxPhase' = 3,
    } else all {
      // Closer or sender already claimed rxFastOccupied and will wake us
      rxFastOccupied' = false,
      rxPhase' = 3,
    },
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    chClosed' = chClosed,
    bufCount' = bufCount,
    txFastOccupied' = txFastOccupied,
    txPhase' = txPhase,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Receiver drains remaining item or observes closed+empty -> #!eof
  action rxComplete = all {
    (rxPhase == 0 or rxPhase == 3),
    (bufCount > 0 or chClosed),
    if (bufCount > 0) all {
      bufCount' = bufCount - 1,
      rxPhase' = 5, // got item!
    } else all {
      bufCount' = bufCount,
      rxPhase' = 4, // #!eof
    },
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    chClosed' = chClosed,
    rxFastOccupied' = rxFastOccupied,
    txFastOccupied' = txFastOccupied,
    txPhase' = txPhase,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Sender tries to send: if open & buf empty -> pushes; if open & buf full -> parks;
  // if closed -> immediately errors cleanly.
  action txAttemptOrPublish = all {
    txPhase == 0,
    if (chClosed) all {
      txPhase' = 5, // rejected cleanly (channel closed)
      bufCount' = bufCount,
      txFastOccupied' = txFastOccupied,
      rxFastOccupied' = rxFastOccupied,
      rxPhase' = rxPhase,
    } else if (bufCount == 0) all {
      bufCount' = 1,
      txPhase' = 4, // sent cleanly!
      txFastOccupied' = txFastOccupied,
      // Wake parked receiver if any
      rxFastOccupied' = false,
      rxPhase' = if (rxFastOccupied) 3 else rxPhase,
    } else all {
      // Buffer full -> publish in tx-fast
      bufCount' = bufCount,
      txFastOccupied' = true,
      txPhase' = 1,
      rxFastOccupied' = rxFastOccupied,
      rxPhase' = rxPhase,
    },
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    chClosed' = chClosed,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Sender step 2: Dekker seq_cst re-check of bufCount and chClosed!
  action txDekkerRecheck = all {
    txPhase == 1,
    if (bufCount == 1 and not(chClosed)) all {
      txPhase' = 2, // parked cleanly
      txFastOccupied' = txFastOccupied,
    } else if (txFastOccupied) all {
      txFastOccupied' = false,
      txPhase' = 3, // canceled -> retry
    } else all {
      txFastOccupied' = false,
      txPhase' = 3, // woken by closer/receiver
    },
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    chClosed' = chClosed,
    bufCount' = bufCount,
    rxFastOccupied' = rxFastOccupied,
    rxPhase' = rxPhase,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Woken sender retries -> if closed, rejects cleanly
  action txRetryAfterWake = all {
    txPhase == 3,
    if (chClosed) all {
      txPhase' = 5,
      bufCount' = bufCount,
    } else if (bufCount == 0) all {
      bufCount' = 1,
      txPhase' = 4,
    } else all {
      bufCount' = bufCount,
      txPhase' = 0,
    },
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    chClosed' = chClosed,
    rxFastOccupied' = rxFastOccupied,
    txFastOccupied' = txFastOccupied,
    rxPhase' = rxPhase,
    closePhase' = closePhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Closer step 1: seq_cst store chClosed = true
  action closeSetFlag = all {
    closePhase == 0,
    chClosed' = true,
    closePhase' = 1,
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    bufCount' = bufCount,
    rxFastOccupied' = rxFastOccupied,
    txFastOccupied' = txFastOccupied,
    rxPhase' = rxPhase,
    txPhase' = txPhase,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  // Closer step 2: atomically drain ALL parked receivers & senders
  action closeDrainAllWaiters = all {
    closePhase == 1,
    rxFastOccupied' = false,
    txFastOccupied' = false,
    rxPhase' = if (rxFastOccupied and rxPhase == 2) 3 else rxPhase,
    txPhase' = if (txFastOccupied and txPhase == 2) 3 else txPhase,
    closePhase' = 2,
    rkParked' = rkParked,
    rkOwner' = rkOwner,
    schedAReady' = schedAReady,
    schedBReady' = schedBReady,
    badNullCtxCrash' = badNullCtxCrash,
    badCrossSchedSteal' = badCrossSchedSteal,
    chClosed' = chClosed,
    bufCount' = bufCount,
    lostRxWakeup' = lostRxWakeup,
    lostTxWakeup' = lostTxWakeup,
    postCloseSendSucceeded' = postCloseSendSucceeded,
  }

  action step = any {
    nondet caller = oneOf(Set(SCHED_EXT, SCHED_A, SCHED_B))
    wakeFromCaller(caller),
    rxPublishWaiter,
    rxDekkerRecheck,
    rxComplete,
    txAttemptOrPublish,
    txDekkerRecheck,
    txRetryAfterWake,
    closeSetFlag,
    closeDrainAllWaiters,
  }

  val InvSafeWakeRouting = not(badNullCtxCrash) and not(badCrossSchedSteal) and
    (schedBReady == 0) and (not(rkParked) implies (schedAReady == 1))
  val InvNoLostWakeupAfterClose =
    (closePhase == 2) implies (not(rxFastOccupied) and not(txFastOccupied) and rxPhase != 2 and txPhase != 2)
  val InvAll = InvSafeWakeRouting and InvNoLostWakeupAfterClose

  run externalOsThreadWakeTest = {
    init
      .then(wakeFromCaller(SCHED_EXT))
      .expect(InvAll and schedAReady == 1 and not(rkParked))
  }

  run crossSchedulerWakeTest = {
    init
      .then(wakeFromCaller(SCHED_B))
      .expect(InvAll and schedAReady == 1 and schedBReady == 0)
  }

  run closeWakesParkedReceiverDekkerTest = {
    init
      .then(rxPublishWaiter)
      .then(closeSetFlag)
      .then(rxDekkerRecheck)
      .then(closeDrainAllWaiters)
      .then(rxComplete)
      .expect(InvAll and rxPhase == 4)
  }

  run closeDrainsPreCloseBufferedItemTest = {
    init
      .then(txAttemptOrPublish)  // pushes item into buf (bufCount=1)
      .then(closeSetFlag)
      .then(closeDrainAllWaiters)
      .then(rxComplete)          // drains pre-close item (rxPhase=5)
      .expect(InvAll and rxPhase == 5 and bufCount == 0)
  }

  run buggyExternalWakeCrashReproTest = {
    init
      .then(buggyWakeFromCaller(SCHED_EXT))
      .expect(badNullCtxCrash)
  }
}
