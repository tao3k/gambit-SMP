// -*- mode: quint -*-
// Phase C7 Formal Adversarial SMP Model:
//   1. Relaxed Empty/Full Channel Hint + Authoritative Locked Re-Check
//      (proves ZERO lost wakeups & exact FIFO message conservation even when
//       relaxed hints return arbitrary stale values!)
//   2. Owner-Only Single-Writer Release Store on 128B-Padded Sharded Counters

module channel_relaxed_hint_and_owner_stlr_smp {
  pure val CAP = 2
  pure val MAX_ITEMS = 4

  // Channel state protected by spinlock
  var buf: List[int]
  var sendWaiters: int  // 0 or 1 (producer parked)
  var recvWaiters: int  // 0 or 1 (consumer parked)

  // Producer & Consumer states:
  // prodState: 0=READY, 1=HINT_PARK_PENDING (passed relaxed full hint, not yet locked), 2=PARKED, 3=DONE
  // consState: 0=READY, 1=HINT_PARK_PENDING (passed relaxed empty hint, not yet locked), 2=PARKED, 3=DONE
  var prodState: int
  var prodNext: int
  var prodPendingVal: int
  var consState: int
  var consReceived: List[int]

  // Owner-only single-writer monotonic counters
  var spawned0: int
  var completed0: int
  var completed1: int

  // Fault latches
  var lostWakeup: bool
  var orderViolation: bool

  action init = all {
    buf'            = List(),
    sendWaiters'    = 0,
    recvWaiters'    = 0,
    prodState'      = 0,
    prodNext'       = 1,
    prodPendingVal' = 0,
    consState'      = 0,
    consReceived'   = List(),
    spawned0'       = 2, // producer + consumer
    completed0'     = 0,
    completed1'     = 0,
    lostWakeup'     = false,
    orderViolation' = false,
  }

  // Producer takes relaxed full hint (EVEN IF STALE/ADVERSARIAL!) -> enters %park-send!
  action prodTakeRelaxedHint: bool = all {
    prodState == 0,
    prodNext <= MAX_ITEMS,
    prodState'      = 1,
    prodPendingVal' = prodNext,
    prodNext'       = prodNext + 1,
    buf'            = buf,
    sendWaiters'    = sendWaiters,
    recvWaiters'    = recvWaiters,
    consState'      = consState,
    consReceived'   = consReceived,
    spawned0'       = spawned0,
    completed0'     = completed0,
    completed1'     = completed1,
    lostWakeup'     = lostWakeup,
    orderViolation' = orderViolation,
  }

  // Producer executes authoritative locked %park-send! (re-checks recvWaiters & buf < CAP)
  action prodLockedParkOrSend: bool = all {
    prodState == 1,
    val v = prodPendingVal
    if (recvWaiters > 0) all {
      // Direct rendezvous handoff to parked consumer!
      recvWaiters'    = 0,
      consState'      = 0,
      consReceived'   = consReceived.append(v),
      prodState'      = if (prodNext > MAX_ITEMS) 3 else 0,
      completed0'     = if (prodNext > MAX_ITEMS) 1 else completed0,
      buf'            = buf,
      sendWaiters'    = sendWaiters,
      prodNext'       = prodNext,
      prodPendingVal' = 0,
      spawned0'       = spawned0,
      completed1'     = completed1,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    } else if (buf.length() < CAP) all {
      // Stale hint caught under lock: space available, push and immediately stay READY!
      buf'            = buf.append(v),
      prodState'      = if (prodNext > MAX_ITEMS) 3 else 0,
      completed0'     = if (prodNext > MAX_ITEMS) 1 else completed0,
      recvWaiters'    = recvWaiters,
      sendWaiters'    = sendWaiters,
      prodNext'       = prodNext,
      prodPendingVal' = 0,
      consState'      = consState,
      consReceived'   = consReceived,
      spawned0'       = spawned0,
      completed1'     = completed1,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    } else all {
      // Truly full under lock: park safely!
      sendWaiters'    = 1,
      prodState'      = 2,
      buf'            = buf,
      recvWaiters'    = recvWaiters,
      prodNext'       = prodNext,
      prodPendingVal' = v,
      consState'      = consState,
      consReceived'   = consReceived,
      spawned0'       = spawned0,
      completed0'     = completed0,
      completed1'     = completed1,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    }
  }

  // Producer fast-path locked send (no hint taken)
  action prodFastSend: bool = all {
    prodState == 0,
    prodNext <= MAX_ITEMS,
    recvWaiters > 0 or buf.length() < CAP,
    val v = prodNext
    if (recvWaiters > 0) all {
      recvWaiters'    = 0,
      consState'      = 0,
      consReceived'   = consReceived.append(v),
      prodNext'       = prodNext + 1,
      prodState'      = if (prodNext == MAX_ITEMS) 3 else 0,
      completed0'     = if (prodNext == MAX_ITEMS) 1 else completed0,
      buf'            = buf,
      sendWaiters'    = sendWaiters,
      prodPendingVal' = prodPendingVal,
      spawned0'       = spawned0,
      completed1'     = completed1,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    } else all {
      buf'            = buf.append(v),
      prodNext'       = prodNext + 1,
      prodState'      = if (prodNext == MAX_ITEMS) 3 else 0,
      completed0'     = if (prodNext == MAX_ITEMS) 1 else completed0,
      recvWaiters'    = recvWaiters,
      sendWaiters'    = sendWaiters,
      prodPendingVal' = prodPendingVal,
      consState'      = consState,
      consReceived'   = consReceived,
      spawned0'       = spawned0,
      completed1'     = completed1,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    }
  }

  // Consumer takes relaxed empty hint (EVEN IF STALE/ADVERSARIAL!) -> enters %park-recv!
  action consTakeRelaxedHint: bool = all {
    consState == 0,
    consReceived.length() < MAX_ITEMS,
    consState'      = 1,
    buf'            = buf,
    sendWaiters'    = sendWaiters,
    recvWaiters'    = recvWaiters,
    prodState'      = prodState,
    prodNext'       = prodNext,
    prodPendingVal' = prodPendingVal,
    consReceived'   = consReceived,
    spawned0'       = spawned0,
    completed0'     = completed0,
    completed1'     = completed1,
    lostWakeup'     = lostWakeup,
    orderViolation' = orderViolation,
  }

  // Consumer executes authoritative locked %park-recv!
  action consLockedParkOrRecv: bool = all {
    consState == 1,
    if (buf.length() > 0) {
      val msg = buf[0]
      val nextRec = consReceived.append(msg)
      val doneNow = nextRec.length() == MAX_ITEMS
      if (sendWaiters > 0) all {
        // Refill slot from parked sender & wake sender!
        buf'            = buf.tail().append(prodPendingVal),
        sendWaiters'    = 0,
        prodState'      = if (prodNext > MAX_ITEMS) 3 else 0,
        completed0'     = if (prodNext > MAX_ITEMS) 1 else completed0,
        prodPendingVal' = 0,
        consReceived'   = nextRec,
        consState'      = if (doneNow) 3 else 0,
        completed1'     = if (doneNow) 1 else completed1,
        recvWaiters'    = recvWaiters,
        prodNext'       = prodNext,
        spawned0'       = spawned0,
        lostWakeup'     = lostWakeup,
        orderViolation' = orderViolation,
      } else all {
        buf'            = buf.tail(),
        consReceived'   = nextRec,
        consState'      = if (doneNow) 3 else 0,
        completed1'     = if (doneNow) 1 else completed1,
        sendWaiters'    = sendWaiters,
        recvWaiters'    = recvWaiters,
        prodState'      = prodState,
        prodNext'       = prodNext,
        prodPendingVal' = prodPendingVal,
        spawned0'       = spawned0,
        completed0'     = completed0,
        lostWakeup'     = lostWakeup,
        orderViolation' = orderViolation,
      }
    } else if (sendWaiters > 0) {
      val nextRec = consReceived.append(prodPendingVal)
      val doneNow = nextRec.length() == MAX_ITEMS
      all {
        sendWaiters'    = 0,
        prodState'      = if (prodNext > MAX_ITEMS) 3 else 0,
        completed0'     = if (prodNext > MAX_ITEMS) 1 else completed0,
        prodPendingVal' = 0,
        consReceived'   = nextRec,
        consState'      = if (doneNow) 3 else 0,
        completed1'     = if (doneNow) 1 else completed1,
        buf'            = buf,
        recvWaiters'    = recvWaiters,
        prodNext'       = prodNext,
        spawned0'       = spawned0,
        lostWakeup'     = lostWakeup,
        orderViolation' = orderViolation,
      }
    } else all {
      // Truly empty under lock: park safely!
      recvWaiters'    = 1,
      consState'      = 2,
      buf'            = buf,
      sendWaiters'    = sendWaiters,
      prodState'      = prodState,
      prodNext'       = prodNext,
      prodPendingVal' = prodPendingVal,
      consReceived'   = consReceived,
      spawned0'       = spawned0,
      completed0'     = completed0,
      completed1'     = completed1,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    }
  }

  // Consumer fast-path locked recv (when buffer non-empty)
  action consFastRecv: bool = all {
    consState == 0,
    consReceived.length() < MAX_ITEMS,
    buf.length() > 0,
    val msg = buf[0]
    val nextRec = consReceived.append(msg)
    val doneNow = nextRec.length() == MAX_ITEMS
    if (sendWaiters > 0) all {
      buf'            = buf.tail().append(prodPendingVal),
      sendWaiters'    = 0,
      prodState'      = if (prodNext > MAX_ITEMS) 3 else 0,
      completed0'     = if (prodNext > MAX_ITEMS) 1 else completed0,
      prodPendingVal' = 0,
      consReceived'   = nextRec,
      consState'      = if (doneNow) 3 else 0,
      completed1'     = if (doneNow) 1 else completed1,
      recvWaiters'    = recvWaiters,
      prodNext'       = prodNext,
      spawned0'       = spawned0,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    } else all {
      buf'            = buf.tail(),
      consReceived'   = nextRec,
      consState'      = if (doneNow) 3 else 0,
      completed1'     = if (doneNow) 1 else completed1,
      sendWaiters'    = sendWaiters,
      recvWaiters'    = recvWaiters,
      prodState'      = prodState,
      prodNext'       = prodNext,
      prodPendingVal' = prodPendingVal,
      spawned0'       = spawned0,
      completed0'     = completed0,
      lostWakeup'     = lostWakeup,
      orderViolation' = orderViolation,
    }
  }

  action step = any {
    prodTakeRelaxedHint,
    prodLockedParkOrSend,
    prodFastSend,
    consTakeRelaxedHint,
    consLockedParkOrRecv,
    consFastRecv,
  }

  // --- SAFETY INVARIANTS ---

  // 1. NEVER deadlock / lost wakeup: cannot have both parked, nor parked consumer with non-empty buf/sender, nor parked producer with space/receiver
  val invZeroLostWakeup: bool =
    not(sendWaiters > 0 and recvWaiters > 0) and
    not(recvWaiters > 0 and (buf.length() > 0 or sendWaiters > 0)) and
    not(sendWaiters > 0 and (buf.length() < CAP or recvWaiters > 0)) and
    not(prodState == 3 and consState == 2)

  // 2. Exact FIFO ordering of all received items: [1, 2, ..., k]
  val invExactFifo: bool =
    0.to(consReceived.length() - 1).forall(i => consReceived[i] == i + 1)

  // 3. Exact message conservation: received + in-buf + pending-sender == prodNext - 1
  val invConservation: bool =
    consReceived.length() + buf.length() + (if (prodPendingVal > 0) 1 else 0) == prodNext - 1

  // 4. Sharded completion accounting matches fiber states
  val invShardedDone: bool =
    completed0 + completed1 <= spawned0 and
    (completed0 + completed1 == spawned0 implies (prodState == 3 and consState == 3 and consReceived.length() == MAX_ITEMS))

  val allInvariants: bool =
    invZeroLostWakeup and invExactFifo and invConservation and invShardedDone
}
