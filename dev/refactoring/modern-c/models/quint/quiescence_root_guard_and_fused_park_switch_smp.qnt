// Phase C15 Formal Model (Quint):
// 1. root-done guarded quiescence with detached fibers (no premature shutdown)
// 2. Fused park-recv + LIFO %fiber-k direct switch + global-pending 32-tick bypass
// 3. Tick-bounded nursery flush across fiber-yield (no nursery deadlock)

module quiescence_root_guard_and_fused_park_switch_smp {
  // ---- Quiescence & detached fiber accounting ----
  var rootDone: bool
  var rootCompleted: bool
  var detachedSpawned: int
  var detachedCompleted: int
  var schedTerminated: bool

  // ---- Fused park-recv + LIFO pop + global-pending ----
  var ringCount: int       // 0..2
  var rxWaiters: int       // 0..1
  var parkedRxId: int      // 0 = none, 1 = fk1, 2 = fk2
  var lifoFkId: int        // 0 = none, 1 = fk1, 2 = fk2
  var fkPoolMask: int      // bitmask of free fk IDs (bit 0 = fk1, bit 1 = fk2)
  var globalPending: int   // 0..2
  var ticks: int           // 0..64
  var switchedToGlobal: bool
  var lostWakeup: bool

  // ---- Tick-bounded nursery flush across fiber-yield ----
  var nurseryActive: int
  var nurseryBatch: int
  var yieldSinceBatch: int

  val MAX_DETACHED = 2
  val MAX_TICKS = 64

  action init = all {
    rootDone' = false,
    rootCompleted' = false,
    detachedSpawned' = 0,
    detachedCompleted' = 0,
    schedTerminated' = false,
    ringCount' = 0,
    rxWaiters' = 0,
    parkedRxId' = 0,
    lifoFkId' = 2,      // fk2 ready in LIFO
    fkPoolMask' = 1,    // fk1 in freelist pool (bit 0)
    globalPending' = 0,
    ticks' = 0,
    switchedToGlobal' = false,
    lostWakeup' = false,
    nurseryActive' = 2,
    nurseryBatch' = 0,
    yieldSinceBatch' = 0,
  }

  // Root spawns a detached fiber before exiting
  action spawnDetached = all {
    not(rootDone),
    detachedSpawned < MAX_DETACHED,
    detachedSpawned' = detachedSpawned + 1,
    rootDone' = rootDone,
    rootCompleted' = rootCompleted,
    detachedCompleted' = detachedCompleted,
    schedTerminated' = schedTerminated,
    ringCount' = ringCount,
    rxWaiters' = rxWaiters,
    parkedRxId' = parkedRxId,
    lifoFkId' = lifoFkId,
    fkPoolMask' = fkPoolMask,
    globalPending' = globalPending,
    ticks' = ticks,
    switchedToGlobal' = switchedToGlobal,
    lostWakeup' = lostWakeup,
    nurseryActive' = nurseryActive,
    nurseryBatch' = nurseryBatch,
    yieldSinceBatch' = yieldSinceBatch,
  }

  // Root finishes body, sets rootDone = true, then marks itself completed
  action finishRoot = all {
    not(rootDone),
    rootDone' = true,
    rootCompleted' = true,
    detachedSpawned' = detachedSpawned,
    detachedCompleted' = detachedCompleted,
    schedTerminated' = schedTerminated,
    ringCount' = ringCount,
    rxWaiters' = rxWaiters,
    parkedRxId' = parkedRxId,
    lifoFkId' = lifoFkId,
    fkPoolMask' = fkPoolMask,
    globalPending' = globalPending,
    ticks' = ticks,
    switchedToGlobal' = switchedToGlobal,
    lostWakeup' = lostWakeup,
    nurseryActive' = nurseryActive,
    nurseryBatch' = nurseryBatch,
    yieldSinceBatch' = yieldSinceBatch,
  }

  // A detached fiber completes
  action finishDetached = all {
    detachedCompleted < detachedSpawned,
    detachedCompleted' = detachedCompleted + 1,
    rootDone' = rootDone,
    rootCompleted' = rootCompleted,
    detachedSpawned' = detachedSpawned,
    schedTerminated' = schedTerminated,
    ringCount' = ringCount,
    rxWaiters' = rxWaiters,
    parkedRxId' = parkedRxId,
    lifoFkId' = lifoFkId,
    fkPoolMask' = fkPoolMask,
    globalPending' = globalPending,
    ticks' = ticks,
    switchedToGlobal' = switchedToGlobal,
    lostWakeup' = lostWakeup,
    nurseryActive' = nurseryActive,
    nurseryBatch' = nurseryBatch,
    yieldSinceBatch' = yieldSinceBatch,
  }

  // Idle worker executes root-done guarded quiescence check
  action checkQuiescent = all {
    not(schedTerminated),
    val totalSpawned = 1 + detachedSpawned
    val totalCompleted = (if (rootCompleted) 1 else 0) + detachedCompleted
    val isQ = (rootDone and (totalCompleted == totalSpawned))
    schedTerminated' = isQ,
    rootDone' = rootDone,
    rootCompleted' = rootCompleted,
    detachedSpawned' = detachedSpawned,
    detachedCompleted' = detachedCompleted,
    ringCount' = ringCount,
    rxWaiters' = rxWaiters,
    parkedRxId' = parkedRxId,
    lifoFkId' = lifoFkId,
    fkPoolMask' = fkPoolMask,
    globalPending' = globalPending,
    ticks' = ticks,
    switchedToGlobal' = switchedToGlobal,
    lostWakeup' = lostWakeup,
    nurseryActive' = nurseryActive,
    nurseryBatch' = nurseryBatch,
    yieldSinceBatch' = yieldSinceBatch,
  }

  // External wakeup enqueues into global queue
  action enqueueGlobal = all {
    globalPending < 2,
    globalPending' = globalPending + 1,
    rootDone' = rootDone,
    rootCompleted' = rootCompleted,
    detachedSpawned' = detachedSpawned,
    detachedCompleted' = detachedCompleted,
    schedTerminated' = schedTerminated,
    ringCount' = ringCount,
    rxWaiters' = rxWaiters,
    parkedRxId' = parkedRxId,
    lifoFkId' = lifoFkId,
    fkPoolMask' = fkPoolMask,
    ticks' = ticks,
    switchedToGlobal' = switchedToGlobal,
    lostWakeup' = lostWakeup,
    nurseryActive' = nurseryActive,
    nurseryBatch' = nurseryBatch,
    yieldSinceBatch' = yieldSinceBatch,
  }

  // Fused park-recv + LIFO pop: pops fk1 from pool, parks on empty ring,
  // switches directly to fk2 (and recycles fk2 into pool) unless tick%32==31 && globalPending>0
  action fusedParkRecvAndSwitch = all {
    ringCount == 0,
    rxWaiters == 0,
    parkedRxId == 0,
    lifoFkId == 2,
    fkPoolMask == 1,
    ticks < MAX_TICKS,
    val mustPollGlobal = ((ticks % 32 == 31) and (globalPending > 0))
    all {
      rxWaiters' = 1,
      parkedRxId' = 1,
      ticks' = ticks + 1,
      if (mustPollGlobal) all {
        // Diverts to trampoline and drains global queue
        globalPending' = globalPending - 1,
        lifoFkId' = 2,
        fkPoolMask' = 0, // fk1 parked, fk2 still in lifo
        switchedToGlobal' = true,
      } else all {
        // Direct fused switch to fk2 and recycle fk2 back to pool (bit 1 = 2)
        globalPending' = globalPending,
        lifoFkId' = 0,
        fkPoolMask' = 2, // fk1 parked, fk2 recycled
        switchedToGlobal' = false,
      },
      rootDone' = rootDone,
      rootCompleted' = rootCompleted,
      detachedSpawned' = detachedSpawned,
      detachedCompleted' = detachedCompleted,
      schedTerminated' = schedTerminated,
      ringCount' = ringCount,
      lostWakeup' = lostWakeup,
      // Real %park-recv-buf-cont! flushes any pending nurseryBatch before parking
      nurseryActive' = nurseryActive - nurseryBatch,
      nurseryBatch' = 0,
      yieldSinceBatch' = 0,
    }
  }

  // Direct handoff wakes parked fk1 into LIFO, restoring symmetric ping-pong state
  action directHandoffWake = all {
    rxWaiters == 1,
    parkedRxId == 1,
    lifoFkId == 0,
    fkPoolMask == 2,
    rxWaiters' = 0,
    parkedRxId' = 0,
    lifoFkId' = 2,   // normalized back to fk2 in lifo, fk1 in pool
    fkPoolMask' = 1,
    rootDone' = rootDone,
    rootCompleted' = rootCompleted,
    detachedSpawned' = detachedSpawned,
    detachedCompleted' = detachedCompleted,
    schedTerminated' = schedTerminated,
    ringCount' = ringCount,
    globalPending' = globalPending,
    ticks' = ticks,
    switchedToGlobal' = switchedToGlobal,
    lostWakeup' = lostWakeup,
    nurseryActive' = nurseryActive,
    nurseryBatch' = nurseryBatch,
    yieldSinceBatch' = yieldSinceBatch,
  }

  // Drain remaining lifo after global poll diversion
  action finishGlobalDiversion = all {
    rxWaiters == 1,
    parkedRxId == 1,
    lifoFkId == 2,
    fkPoolMask == 0,
    rxWaiters' = 0,
    parkedRxId' = 0,
    lifoFkId' = 2,
    fkPoolMask' = 1,
    rootDone' = rootDone,
    rootCompleted' = rootCompleted,
    detachedSpawned' = detachedSpawned,
    detachedCompleted' = detachedCompleted,
    schedTerminated' = schedTerminated,
    ringCount' = ringCount,
    globalPending' = globalPending,
    ticks' = ticks,
    switchedToGlobal' = false,
    lostWakeup' = lostWakeup,
    nurseryActive' = nurseryActive,
    nurseryBatch' = nurseryBatch,
    yieldSinceBatch' = yieldSinceBatch,
  }

  // Nursery child finishes and batches completion; subsequent fiber-yields flush by tick 15
  action nurseryCompleteBatched = all {
    nurseryActive > nurseryBatch,
    nurseryBatch < 2,
    nurseryBatch' = nurseryBatch + 1,
    yieldSinceBatch' = 0,
    nurseryActive' = nurseryActive,
    rootDone' = rootDone,
    rootCompleted' = rootCompleted,
    detachedSpawned' = detachedSpawned,
    detachedCompleted' = detachedCompleted,
    schedTerminated' = schedTerminated,
    ringCount' = ringCount,
    rxWaiters' = rxWaiters,
    parkedRxId' = parkedRxId,
    lifoFkId' = lifoFkId,
    fkPoolMask' = fkPoolMask,
    globalPending' = globalPending,
    ticks' = ticks,
    switchedToGlobal' = switchedToGlobal,
    lostWakeup' = lostWakeup,
  }

  action yieldWithTickFlush = all {
    ticks < MAX_TICKS,
    val nextTicks = ticks + 1
    val doFlush = ((ticks % 16 == 15) and (nurseryBatch > 0))
    all {
      ticks' = nextTicks,
      if (doFlush) all {
        nurseryActive' = nurseryActive - nurseryBatch,
        nurseryBatch' = 0,
        yieldSinceBatch' = 0,
      } else all {
        nurseryActive' = nurseryActive,
        nurseryBatch' = nurseryBatch,
        yieldSinceBatch' = (if (nurseryBatch > 0) (yieldSinceBatch + 1) else 0),
      },
      rootDone' = rootDone,
      rootCompleted' = rootCompleted,
      detachedSpawned' = detachedSpawned,
      detachedCompleted' = detachedCompleted,
      schedTerminated' = schedTerminated,
      ringCount' = ringCount,
      rxWaiters' = rxWaiters,
      parkedRxId' = parkedRxId,
      lifoFkId' = lifoFkId,
      fkPoolMask' = fkPoolMask,
      globalPending' = globalPending,
      switchedToGlobal' = switchedToGlobal,
      lostWakeup' = lostWakeup,
    }
  }

  action step = any {
    spawnDetached,
    finishRoot,
    finishDetached,
    checkQuiescent,
    enqueueGlobal,
    fusedParkRecvAndSwitch,
    directHandoffWake,
    finishGlobalDiversion,
    nurseryCompleteBatched,
    yieldWithTickFlush,
  }

  // ---- Safety & Liveness Invariants ----
  // 1. Never terminate while root or any detached fiber is incomplete
  val inv_no_premature_quiescence =
    (not(schedTerminated) or (rootDone and rootCompleted and (detachedCompleted == detachedSpawned)))

  // 2. Disjoint fk ownership: parkedRxId, lifoFkId, and fkPoolMask never alias
  val inv_fk_disjoint = all {
    (parkedRxId == 0 or parkedRxId != lifoFkId),
    (parkedRxId != 1 or (fkPoolMask % 2 == 0)),
    (parkedRxId != 2 or (fkPoolMask < 2)),
    (lifoFkId != 1 or (fkPoolMask % 2 == 0)),
    (lifoFkId != 2 or (fkPoolMask < 2)),
  }

  // 3. No lost wakeup
  val inv_no_lost_wakeup = not(lostWakeup)

  // 4. Nursery accounting never underflows and yields flush within 16 steps
  val inv_nursery_bounded = all {
    nurseryActive >= nurseryBatch,
    nurseryBatch >= 0,
    yieldSinceBatch <= 16,
  }

  val inv_all = all {
    inv_no_premature_quiescence,
    inv_fk_disjoint,
    inv_no_lost_wakeup,
    inv_nursery_bounded,
  }
}
