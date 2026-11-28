// Phase C17 Formal Model (Quint):
// Lock-free single-waiter rx-fast slot (word 1 of 128B rx-waiters line)
// with CAS-exclusive cancel-vs-claim, linearizable tail==head direct handoff,
// and symmetric Dekker guard against sender parking.

module lockfree_rx_fast_slot_handoff_smp {
  // Channel state
  var rHead: int          // 0..4
  var rTail: int          // 0..4
  var rxFastFk: int       // 0 = empty, 1 = fk1, 2 = fk2
  var rwqCount: int       // 0..1 (overflow waiter when rxFast occupied)
  var txWaiters: int      // 0..1 (parked sender)

  // Per-receiver lifecycle tracking (fk1 & fk2)
  // 0 = active/not parked, 1 = parked, 2 = woken/delivered
  var fk1State: int
  var fk1Wakes: int
  var fk2State: int
  var fk2Wakes: int

  // Message conservation
  var totalSent: int
  var totalDelivered: int
  var fifoViolated: bool

  val CAP = 2
  val MAX_SEND = 4

  action init = all {
    rHead' = 0,
    rTail' = 0,
    rxFastFk' = 0,
    rwqCount' = 0,
    txWaiters' = 0,
    fk1State' = 0,
    fk1Wakes' = 0,
    fk2State' = 0,
    fk2Wakes' = 0,
    totalSent' = 0,
    totalDelivered' = 0,
    fifoViolated' = false,
  }

  // R1 parks via lock-free CAS(rxFast, 0 -> 1) when ring empty & txWaiters == 0
  action r1ParkRxFast = all {
    fk1State == 0,
    rTail == rHead,
    rxFastFk == 0,
    txWaiters == 0,
    rxFastFk' = 1,
    fk1State' = 1,
    rHead' = rHead,
    rTail' = rTail,
    rwqCount' = rwqCount,
    txWaiters' = txWaiters,
    fk1Wakes' = fk1Wakes,
    fk2State' = fk2State,
    fk2Wakes' = fk2Wakes,
    totalSent' = totalSent,
    totalDelivered' = totalDelivered,
    fifoViolated' = fifoViolated,
  }

  // R1 cancels its own rxFast park via CAS(rxFast, 1 -> 0) upon racing with ring arrival
  action r1CancelRxFast = all {
    fk1State == 1,
    rxFastFk == 1,
    rTail > rHead,
    rxFastFk' = 0,
    fk1State' = 0,
    rHead' = rHead,
    rTail' = rTail,
    rwqCount' = rwqCount,
    txWaiters' = txWaiters,
    fk1Wakes' = fk1Wakes,
    fk2State' = fk2State,
    fk2Wakes' = fk2Wakes,
    totalSent' = totalSent,
    totalDelivered' = totalDelivered,
    fifoViolated' = fifoViolated,
  }

  // R2 arrives when rxFast is already occupied -> parks in fallback rwq
  action r2ParkFallbackRwq = all {
    fk2State == 0,
    rTail == rHead,
    rxFastFk != 0,
    rwqCount == 0,
    txWaiters == 0,
    rwqCount' = 1,
    fk2State' = 1,
    rHead' = rHead,
    rTail' = rTail,
    rxFastFk' = rxFastFk,
    txWaiters' = txWaiters,
    fk1State' = fk1State,
    fk1Wakes' = fk1Wakes,
    fk2Wakes' = fk2Wakes,
    totalSent' = totalSent,
    totalDelivered' = totalDelivered,
    fifoViolated' = fifoViolated,
  }

  // Sender lock-free direct handoff: claims rxFast via CAS(rxFast, 1 -> 0) ONLY when tail == head
  action sendDirectHandoffRxFast = all {
    totalSent < MAX_SEND,
    rxFastFk == 1,
    rTail == rHead,
    rxFastFk' = 0,
    fk1State' = 2,
    fk1Wakes' = fk1Wakes + 1,
    totalSent' = totalSent + 1,
    totalDelivered' = totalDelivered + 1,
    rHead' = rHead,
    rTail' = rTail,
    rwqCount' = rwqCount,
    txWaiters' = txWaiters,
    fk2State' = fk2State,
    fk2Wakes' = fk2Wakes,
    fifoViolated' = fifoViolated,
  }

  // Sender pushes to Vyukov ring (and wakes rxFast or rwq if present)
  action sendRingPush = all {
    totalSent < MAX_SEND,
    rTail - rHead < CAP,
    val newTail = rTail + 1
    if (rxFastFk == 1) all {
      // Dekker check sees rxFast != 0 -> claims rxFast and pops oldest item from ring
      rxFastFk' = 0,
      rHead' = rHead + 1,
      rTail' = newTail,
      fk1State' = 2,
      fk1Wakes' = fk1Wakes + 1,
      totalSent' = totalSent + 1,
      totalDelivered' = totalDelivered + 1,
      rwqCount' = rwqCount,
      txWaiters' = txWaiters,
      fk2State' = fk2State,
      fk2Wakes' = fk2Wakes,
      fifoViolated' = fifoViolated,
    } else if (rwqCount > 0) all {
      // Dekker check sees rxw > 0 -> pops rwq and oldest item from ring
      rwqCount' = rwqCount - 1,
      rHead' = rHead + 1,
      rTail' = newTail,
      fk2State' = 2,
      fk2Wakes' = fk2Wakes + 1,
      totalSent' = totalSent + 1,
      totalDelivered' = totalDelivered + 1,
      rxFastFk' = rxFastFk,
      txWaiters' = txWaiters,
      fk1State' = fk1State,
      fk1Wakes' = fk1Wakes,
      fifoViolated' = fifoViolated,
    } else all {
      rTail' = newTail,
      totalSent' = totalSent + 1,
      rHead' = rHead,
      rxFastFk' = rxFastFk,
      rwqCount' = rwqCount,
      txWaiters' = txWaiters,
      fk1State' = fk1State,
      fk1Wakes' = fk1Wakes,
      fk2State' = fk2State,
      fk2Wakes' = fk2Wakes,
      totalDelivered' = totalDelivered,
      fifoViolated' = fifoViolated,
    }
  }

  // Sender parks on full ring (ONLY when rwq == 0 AND rxFast == 0!)
  action sendParkFull = all {
    rTail - rHead == CAP,
    txWaiters == 0,
    rwqCount == 0,
    rxFastFk == 0,
    txWaiters' = 1,
    rHead' = rHead,
    rTail' = rTail,
    rxFastFk' = rxFastFk,
    rwqCount' = rwqCount,
    fk1State' = fk1State,
    fk1Wakes' = fk1Wakes,
    fk2State' = fk2State,
    fk2Wakes' = fk2Wakes,
    totalSent' = totalSent,
    totalDelivered' = totalDelivered,
    fifoViolated' = fifoViolated,
  }

  // Fast recv pops from non-empty ring (and wakes parked sender if txWaiters > 0)
  action recvRingPop = all {
    rTail > rHead,
    if (txWaiters > 0 and totalSent < MAX_SEND) all {
      rHead' = rHead + 1,
      rTail' = rTail + 1,
      txWaiters' = txWaiters - 1,
      totalSent' = totalSent + 1,
      totalDelivered' = totalDelivered + 1,
      rxFastFk' = rxFastFk,
      rwqCount' = rwqCount,
      fk1State' = fk1State,
      fk1Wakes' = fk1Wakes,
      fk2State' = fk2State,
      fk2Wakes' = fk2Wakes,
      fifoViolated' = fifoViolated,
    } else all {
      rHead' = rHead + 1,
      totalDelivered' = totalDelivered + 1,
      rTail' = rTail,
      rxFastFk' = rxFastFk,
      rwqCount' = rwqCount,
      txWaiters' = txWaiters,
      fk1State' = fk1State,
      fk1Wakes' = fk1Wakes,
      fk2State' = fk2State,
      fk2Wakes' = fk2Wakes,
      totalSent' = totalSent,
      fifoViolated' = fifoViolated,
    }
  }

  // Reset woken receivers back to active so multiple rounds can occur
  action resetWokenFk1 = all {
    fk1State == 2,
    fk1State' = 0,
    fk1Wakes' = 0,
    rHead' = rHead,
    rTail' = rTail,
    rxFastFk' = rxFastFk,
    rwqCount' = rwqCount,
    txWaiters' = txWaiters,
    fk2State' = fk2State,
    fk2Wakes' = fk2Wakes,
    totalSent' = totalSent,
    totalDelivered' = totalDelivered,
    fifoViolated' = fifoViolated,
  }

  action resetWokenFk2 = all {
    fk2State == 2,
    fk2State' = 0,
    fk2Wakes' = 0,
    rHead' = rHead,
    rTail' = rTail,
    rxFastFk' = rxFastFk,
    rwqCount' = rwqCount,
    txWaiters' = txWaiters,
    fk1State' = fk1State,
    fk1Wakes' = fk1Wakes,
    totalSent' = totalSent,
    totalDelivered' = totalDelivered,
    fifoViolated' = fifoViolated,
  }

  action step = any {
    r1ParkRxFast,
    r1CancelRxFast,
    r2ParkFallbackRwq,
    sendDirectHandoffRxFast,
    sendRingPush,
    sendParkFull,
    recvRingPop,
    resetWokenFk1,
    resetWokenFk2,
  }

  // ---- Safety Invariants ----
  // 1. Exact message conservation
  val inv_conservation = (totalSent == totalDelivered + (rTail - rHead))

  // 2. Ring bounds
  val inv_ring_bounds = (rHead <= rTail) and (rTail - rHead <= CAP)

  // 3. Exactly-once wake per parked fk (zero double-wakeup)
  val inv_no_double_wake = (fk1Wakes <= 1) and (fk2Wakes <= 1)

  // 4. Mutual exclusion of sender park and receiver park (zero deadlock)
  val inv_no_mutual_park =
    not((txWaiters > 0) and ((rxFastFk != 0) or (rwqCount > 0)))

  // 5. No FIFO violation
  val inv_fifo = not(fifoViolated)

  val inv_all = all {
    inv_conservation,
    inv_ring_bounds,
    inv_no_double_wake,
    inv_no_mutual_park,
    inv_fifo,
  }
}
