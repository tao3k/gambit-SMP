// Phase C23: Heterogeneous Straggler-Evicting Work-Stealing + Adaptive OS Parker
//            + Symmetric Lock-Free tx-fast / rx-fast Bounded Channel Protocol
//
// Models:
//   1. Adaptive OS futex/ulock parker (seq, waiters, Dekker double-check) +
//      unconditional Rayon/Tokio steal-cascade wakeup across 3 workers.
//   2. Idle-searcher-aware LIFO-to-deque straggler spill (when searching > 0).
//   3. Symmetric bounded channel (cap = 1) with lock-free rx-fast and tx-fast
//      Dekker park/cancel/handoff.

module hetero_straggler_parker_txfast_smp {
  pure val WORKERS: Set[int] = Set(0, 1, 2) // 0,1 = P-cores, 2 = E-core
  pure val CAP: int = 1

  // Worker scheduler & parker state
  var lifo: int -> int        // task count in private LIFO (0 or 1)
  var dq: int -> int          // task count in stealable deque
  var sleeping: int -> bool   // worker parked in OS parker
  var searching: int          // active steal-searchers
  var parkSeq: int            // monotonic futex/ulock wake sequence
  var parkWaiters: int        // Dekker waiter count
  var totalSpawned: int
  var totalCompleted: int

  // Symmetric lock-free bounded channel (cap = 1) state
  var ringCount: int          // 0 or 1
  var rxFastParked: bool      // receiver parked in lock-free rx-fast
  var txFastParked: bool      // sender parked in lock-free tx-fast
  var chSent: int
  var chRecv: int

  var faultLostWakeup: bool
  var faultDeadlockCh: bool

  pure def totalTasks(l: int -> int, d: int -> int): int =
    WORKERS.fold(0, (acc, w) => acc + l.get(w) + d.get(w))

  pure def anyDqNonEmpty(d: int -> int): bool =
    WORKERS.exists(w => d.get(w) > 0)

  pure def countSleeping(sl: int -> bool): int =
    WORKERS.fold(0, (acc, w) => if (sl.get(w)) acc + 1 else acc)

  action init = all {
    lifo' = Map(0 -> 0, 1 -> 0, 2 -> 1), // E-core 2 starts with 1 straggler task
    dq' = Map(0 -> 0, 1 -> 0, 2 -> 0),
    sleeping' = Map(0 -> false, 1 -> false, 2 -> false),
    searching' = 0,
    parkSeq' = 0,
    parkWaiters' = 0,
    totalSpawned' = 1,
    totalCompleted' = 0,
    ringCount' = 0,
    rxFastParked' = false,
    txFastParked' = false,
    chSent' = 0,
    chRecv' = 0,
    faultLostWakeup' = false,
    faultDeadlockCh' = false
  }

  // Idle worker starts searching (bounded by max(1, W/2) = 2 here)
  action startSearching(w: int): bool = all {
    not(sleeping.get(w)),
    lifo.get(w) == 0,
    dq.get(w) == 0,
    searching < 2,
    searching' = searching + 1,
    lifo' = lifo,
    dq' = dq,
    sleeping' = sleeping,
    parkSeq' = parkSeq,
    parkWaiters' = parkWaiters,
    totalSpawned' = totalSpawned,
    totalCompleted' = totalCompleted,
    ringCount' = ringCount,
    rxFastParked' = rxFastParked,
    txFastParked' = txFastParked,
    chSent' = chSent,
    chRecv' = chRecv,
    faultLostWakeup' = faultLostWakeup,
    faultDeadlockCh' = faultDeadlockCh
  }

  // Idle-searcher-aware LIFO-to-DQ straggler spill:
  // When searching > 0 (or parkWaiters > 0), worker spills its private LIFO task
  // into stealable dq and wakes one sleeping worker if any.
  action stragglerSpillLifoToDq(w: int): bool = {
    val wakeTarget = WORKERS.filter(u => sleeping.get(u))
    val doWake = (parkWaiters > 0 and wakeTarget.size() > 0)
    all {
      not(sleeping.get(w)),
      lifo.get(w) == 1,
      (searching > 0 or parkWaiters > 0),
      lifo' = lifo.set(w, 0),
      dq' = dq.set(w, dq.get(w) + 1),
      if (doWake) {
        nondet u = oneOf(wakeTarget)
        all {
          sleeping' = sleeping.set(u, false),
          parkWaiters' = parkWaiters - 1,
          parkSeq' = parkSeq + 1
        }
      } else all {
        sleeping' = sleeping,
        parkWaiters' = parkWaiters,
        parkSeq' = parkSeq
      },
      searching' = searching,
      totalSpawned' = totalSpawned,
      totalCompleted' = totalCompleted,
      ringCount' = ringCount,
      rxFastParked' = rxFastParked,
      txFastParked' = txFastParked,
      chSent' = chSent,
      chRecv' = chRecv,
      faultLostWakeup' = faultLostWakeup,
      faultDeadlockCh' = faultDeadlockCh
    }
  }

  // Work-stealing with unconditional Rayon/Tokio cascade wakeup:
  // Thief claims 1 task from victim's dq, decrements searching, and UNCONDITIONALLY
  // wakes 1 sleeping worker if parkWaiters > 0 (never gating on victim dq size!).
  action stealTaskWithCascade(thief: int, victim: int): bool = {
    val wakeTarget = WORKERS.filter(u => sleeping.get(u))
    val doWake = (parkWaiters > 0 and wakeTarget.size() > 0)
    all {
      thief != victim,
      not(sleeping.get(thief)),
      lifo.get(thief) == 0,
      dq.get(victim) > 0,
      searching > 0,
      dq' = dq.set(victim, dq.get(victim) - 1),
      lifo' = lifo.set(thief, 1),
      searching' = searching - 1,
      if (doWake) {
        nondet u = oneOf(wakeTarget)
        all {
          sleeping' = sleeping.set(u, false),
          parkWaiters' = parkWaiters - 1,
          parkSeq' = parkSeq + 1
        }
      } else all {
        sleeping' = sleeping,
        parkWaiters' = parkWaiters,
        parkSeq' = parkSeq
      },
      totalSpawned' = totalSpawned,
      totalCompleted' = totalCompleted,
      ringCount' = ringCount,
      rxFastParked' = rxFastParked,
      txFastParked' = txFastParked,
      chSent' = chSent,
      chRecv' = chRecv,
      faultLostWakeup' = faultLostWakeup,
      faultDeadlockCh' = faultDeadlockCh
    }
  }

  // Adaptive Dekker park: worker sleeps ONLY if all stealable deques are empty
  // (after seq_cst waiters++ re-check).
  action parkWorkerDekker(w: int): bool = all {
    not(sleeping.get(w)),
    lifo.get(w) == 0,
    not(anyDqNonEmpty(dq)),
    sleeping' = sleeping.set(w, true),
    parkWaiters' = parkWaiters + 1,
    searching' = if (searching > 0) searching - 1 else 0,
    lifo' = lifo,
    dq' = dq,
    parkSeq' = parkSeq,
    totalSpawned' = totalSpawned,
    totalCompleted' = totalCompleted,
    ringCount' = ringCount,
    rxFastParked' = rxFastParked,
    txFastParked' = txFastParked,
    chSent' = chSent,
    chRecv' = chRecv,
    faultLostWakeup' = faultLostWakeup,
    faultDeadlockCh' = faultDeadlockCh
  }

  // Spawn a new task onto worker w's dq (waking a sleeper if any)
  action spawnToDq(w: int): bool = {
    val wakeTarget = WORKERS.filter(u => sleeping.get(u))
    val doWake = (parkWaiters > 0 and wakeTarget.size() > 0)
    all {
      not(sleeping.get(w)),
      totalSpawned < 8,
      dq' = dq.set(w, dq.get(w) + 1),
      totalSpawned' = totalSpawned + 1,
      if (doWake) {
        nondet u = oneOf(wakeTarget)
        all {
          sleeping' = sleeping.set(u, false),
          parkWaiters' = parkWaiters - 1,
          parkSeq' = parkSeq + 1
        }
      } else all {
        sleeping' = sleeping,
        parkWaiters' = parkWaiters,
        parkSeq' = parkSeq
      },
      lifo' = lifo,
      searching' = searching,
      totalCompleted' = totalCompleted,
      ringCount' = ringCount,
      rxFastParked' = rxFastParked,
      txFastParked' = txFastParked,
      chSent' = chSent,
      chRecv' = chRecv,
      faultLostWakeup' = faultLostWakeup,
      faultDeadlockCh' = faultDeadlockCh
    }
  }

  // Symmetric channel: Send fast (direct handoff to rxFast, or ring push, or park in txFast)
  action chSendStep: bool = {
    val nextRx = if (rxFastParked and ringCount == 0) false else if (ringCount < CAP) rxFastParked else if (not(txFastParked) and not(rxFastParked)) false else rxFastParked
    val nextTx = if (rxFastParked and ringCount == 0) txFastParked else if (ringCount < CAP) txFastParked else if (not(txFastParked) and not(rxFastParked)) true else txFastParked
    val nextRing = if (rxFastParked and ringCount == 0) 0 else if (ringCount < CAP) ringCount + 1 else ringCount
    val nextSent = if ((rxFastParked and ringCount == 0) or ringCount < CAP) chSent + 1 else chSent
    val nextRecv = if (rxFastParked and ringCount == 0) chRecv + 1 else chRecv
    all {
      chSent < 10,
      rxFastParked' = nextRx,
      txFastParked' = nextTx,
      ringCount' = nextRing,
      chSent' = nextSent,
      chRecv' = nextRecv,
      lifo' = lifo,
      dq' = dq,
      sleeping' = sleeping,
      searching' = searching,
      parkSeq' = parkSeq,
      parkWaiters' = parkWaiters,
      totalSpawned' = totalSpawned,
      totalCompleted' = totalCompleted,
      faultLostWakeup' = faultLostWakeup,
      faultDeadlockCh' = (nextRx and nextTx)
    }
  }

  // Symmetric channel: Recv fast (pop ring + lock-free txFast wake, or park in rxFast)
  action chRecvStep: bool = {
    val nextRx = if (ringCount > 0) rxFastParked else if (not(rxFastParked) and not(txFastParked)) true else rxFastParked
    val nextTx = if (ringCount > 0) false else if (not(rxFastParked) and not(txFastParked)) false else txFastParked
    val nextRing = if (ringCount > 0) (if (txFastParked) ringCount else ringCount - 1) else 0
    val nextSent = if (ringCount > 0 and txFastParked) chSent + 1 else chSent
    val nextRecv = if (ringCount > 0) chRecv + 1 else chRecv
    all {
      rxFastParked' = nextRx,
      txFastParked' = nextTx,
      ringCount' = nextRing,
      chSent' = nextSent,
      chRecv' = nextRecv,
      lifo' = lifo,
      dq' = dq,
      sleeping' = sleeping,
      searching' = searching,
      parkSeq' = parkSeq,
      parkWaiters' = parkWaiters,
      totalSpawned' = totalSpawned,
      totalCompleted' = totalCompleted,
      faultLostWakeup' = faultLostWakeup,
      faultDeadlockCh' = (nextRx and nextTx)
    }
  }

  action step = any {
    nondet w = oneOf(WORKERS)
    startSearching(w),
    nondet w = oneOf(WORKERS)
    stragglerSpillLifoToDq(w),
    nondet t = oneOf(WORKERS)
    nondet v = oneOf(WORKERS)
    stealTaskWithCascade(t, v),
    nondet w = oneOf(WORKERS)
    parkWorkerDekker(w),
    nondet w = oneOf(WORKERS)
    spawnToDq(w),
    chSendStep,
    chRecvStep
  }

  // Safety Invariants
  val invExactTaskConservation = totalTasks(lifo, dq) + totalCompleted == totalSpawned
  val invNoAllAsleepWithDqWork = not(countSleeping(sleeping) == 3 and anyDqNonEmpty(dq))
  val invWaitersConsistent = parkWaiters == countSleeping(sleeping)
  val invNoRxTxMutualDeadlock = not(rxFastParked and txFastParked) and not(faultDeadlockCh)
  val invExactChannelConservation = chSent == ringCount + chRecv

  val invAll =
    invExactTaskConservation and
    invNoAllAsleepWithDqWork and
    invWaitersConsistent and
    invNoRxTxMutualDeadlock and
    invExactChannelConservation
}
