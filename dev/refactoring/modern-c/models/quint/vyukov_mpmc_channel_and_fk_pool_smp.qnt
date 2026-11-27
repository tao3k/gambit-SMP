// Phase C8 Formal Model: Lock-Free Vyukov Bounded MPMC Ring + Dekker Waiter
// Protocol + Linearizable Direct Handoff + Per-Carrier %fiber-k Freelist +
// Zero-Capture Nursery Exception Abort Unwinding (SMP)

module vyukov_mpmc_channel_and_fk_pool_smp {
  pure val CAP = 2
  pure val MAX_MSG = 4

  // Ring state (rHead / rTail avoid Quint list builtins head/tail)
  var rTail: int
  var rHead: int
  var seq0: int
  var seq1: int
  var buf0: int
  var buf1: int

  // Waiter state (protected by waitLock)
  var waitLock: int
  var recvWaiters: int
  var sendWaiters: int
  var parkedSendMsg: int
  var parkedRecvFk: int
  var parkedSendFk: int

  // Dekker in-flight protocol state
  var prodPhase: int
  var nextSendId: int
  var consPhase: int
  var consGotMsg: int
  var nextRecvExpected: int
  var totalReceived: int

  // Per-worker %fiber-k pool safety model (0=FREE_IN_POOL, 1=ACTIVE_PARKED)
  var fkState: int -> int
  var fkHasRawK: int -> bool

  // Zero-capture nursery abort model:
  // 0=RUNNING, 1=RAISED_UNWINDING, 2=AFTER_DONE, 3=CHILD_DONE
  var childPhase: int
  var nurseryActive: int
  var afterRan: bool

  action init = all {
    rTail' = 0,
    rHead' = 0,
    seq0' = 0,
    seq1' = 1,
    buf0' = 0,
    buf1' = 0,
    waitLock' = 0,
    recvWaiters' = 0,
    sendWaiters' = 0,
    parkedSendMsg' = 0,
    parkedRecvFk' = 0,
    parkedSendFk' = 0,
    prodPhase' = 0,
    nextSendId' = 1,
    consPhase' = 0,
    consGotMsg' = 0,
    nextRecvExpected' = 1,
    totalReceived' = 0,
    fkState' = Map(1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0),
    fkHasRawK' = Map(1 -> false, 2 -> false, 3 -> false, 4 -> false),
    childPhase' = 0,
    nurseryActive' = 2,
    afterRan' = false,
  }

  // Producer fast path 1: linearizable direct handoff when recvWaiters > 0 AND rTail == rHead
  action prod_direct_handoff = {
    val msg = nextSendId
    val rk = parkedRecvFk
    all {
      prodPhase == 0,
      nextSendId <= MAX_MSG,
      waitLock == 0,
      recvWaiters > 0,
      rk != 0,
      rTail == rHead, // REQUIRED linearizability guard: zero unpopped buffered items!
      recvWaiters' = recvWaiters - 1,
      parkedRecvFk' = 0,
      nextSendId' = nextSendId + 1,
      nextRecvExpected' = if (msg == nextRecvExpected) nextRecvExpected + 1 else nextRecvExpected,
      totalReceived' = totalReceived + 1,
      fkState' = fkState.set(rk, 0),
      fkHasRawK' = fkHasRawK.set(rk, false),
      rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
      waitLock' = waitLock, sendWaiters' = sendWaiters,
      parkedSendMsg' = parkedSendMsg, parkedSendFk' = parkedSendFk,
      prodPhase' = 0, consPhase' = consPhase, consGotMsg' = consGotMsg,
      childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
    }
  }

  // Producer fast path 2: lock-free Vyukov push into ring
  action prod_vyukov_push = {
    val idx = rTail % CAP
    val slotSeq = if (idx == 0) seq0 else seq1
    all {
      prodPhase == 0,
      nextSendId <= MAX_MSG,
      slotSeq == rTail,
      rTail' = rTail + 1,
      buf0' = if (idx == 0) nextSendId else buf0,
      buf1' = if (idx == 1) nextSendId else buf1,
      seq0' = if (idx == 0) rTail + 1 else seq0,
      seq1' = if (idx == 1) rTail + 1 else seq1,
      nextSendId' = nextSendId + 1,
      prodPhase' = 1,
      rHead' = rHead, waitLock' = waitLock, recvWaiters' = recvWaiters,
      sendWaiters' = sendWaiters, parkedSendMsg' = parkedSendMsg,
      parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
      consPhase' = consPhase, consGotMsg' = consGotMsg,
      nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
      fkState' = fkState, fkHasRawK' = fkHasRawK,
      childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
    }
  }

  // Producer Dekker check: if recvWaiters == 0, done with ZERO spinlock!
  action prod_check_no_waiters = all {
    prodPhase == 1,
    recvWaiters == 0,
    prodPhase' = 0,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
    waitLock' = waitLock, recvWaiters' = recvWaiters, sendWaiters' = sendWaiters,
    parkedSendMsg' = parkedSendMsg, parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
    nextSendId' = nextSendId, consPhase' = consPhase, consGotMsg' = consGotMsg,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    fkState' = fkState, fkHasRawK' = fkHasRawK,
    childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
  }

  // Producer Dekker slow path: recvWaiters > 0 -> wake parked receiver and hand off ring head
  action prod_wake_receiver = {
    val idx = rHead % CAP
    val slotSeq = if (idx == 0) seq0 else seq1
    val msg = if (idx == 0) buf0 else buf1
    val rk = parkedRecvFk
    all {
      prodPhase == 1,
      waitLock == 0,
      recvWaiters > 0,
      rk != 0,
      slotSeq == rHead + 1,
      rHead' = rHead + 1,
      buf0' = if (idx == 0) 0 else buf0,
      buf1' = if (idx == 1) 0 else buf1,
      seq0' = if (idx == 0) rHead + CAP else seq0,
      seq1' = if (idx == 1) rHead + CAP else seq1,
      recvWaiters' = recvWaiters - 1,
      parkedRecvFk' = 0,
      prodPhase' = 0,
      nextRecvExpected' = if (msg == nextRecvExpected) nextRecvExpected + 1 else nextRecvExpected,
      totalReceived' = totalReceived + 1,
      fkState' = fkState.set(rk, 0),
      fkHasRawK' = fkHasRawK.set(rk, false),
      rTail' = rTail, waitLock' = waitLock, sendWaiters' = sendWaiters,
      parkedSendMsg' = parkedSendMsg, parkedSendFk' = parkedSendFk,
      nextSendId' = nextSendId, consPhase' = consPhase, consGotMsg' = consGotMsg,
      childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
    }
  }

  // Consumer fast path: lock-free Vyukov pop from ring
  action cons_vyukov_pop = {
    val idx = rHead % CAP
    val slotSeq = if (idx == 0) seq0 else seq1
    val msg = if (idx == 0) buf0 else buf1
    all {
      consPhase == 0,
      parkedRecvFk == 0,
      slotSeq == rHead + 1,
      rHead' = rHead + 1,
      buf0' = if (idx == 0) 0 else buf0,
      buf1' = if (idx == 1) 0 else buf1,
      seq0' = if (idx == 0) rHead + CAP else seq0,
      seq1' = if (idx == 1) rHead + CAP else seq1,
      consGotMsg' = msg,
      nextRecvExpected' = if (msg == nextRecvExpected) nextRecvExpected + 1 else nextRecvExpected,
      totalReceived' = totalReceived + 1,
      consPhase' = 1,
      rTail' = rTail, waitLock' = waitLock, recvWaiters' = recvWaiters,
      sendWaiters' = sendWaiters, parkedSendMsg' = parkedSendMsg,
      parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
      prodPhase' = prodPhase, nextSendId' = nextSendId,
      fkState' = fkState, fkHasRawK' = fkHasRawK,
      childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
    }
  }

  // Consumer Dekker check: no parked senders -> done with ZERO spinlock!
  action cons_check_no_senders = all {
    consPhase == 1,
    sendWaiters == 0,
    consPhase' = 0,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
    waitLock' = waitLock, recvWaiters' = recvWaiters, sendWaiters' = sendWaiters,
    parkedSendMsg' = parkedSendMsg, parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
    prodPhase' = prodPhase, nextSendId' = nextSendId, consGotMsg' = consGotMsg,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    fkState' = fkState, fkHasRawK' = fkHasRawK,
    childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
  }

  // Consumer parks when ring is empty (re-checking under waitLock)
  action cons_park_recv = {
    val idx = rHead % CAP
    val slotSeq = if (idx == 0) seq0 else seq1
    all {
      consPhase == 0,
      waitLock == 0,
      parkedRecvFk == 0,
      slotSeq != rHead + 1,
      fkState.get(1) == 0,
      recvWaiters' = recvWaiters + 1,
      parkedRecvFk' = 1,
      fkState' = fkState.set(1, 1),
      fkHasRawK' = fkHasRawK.set(1, true),
      rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
      waitLock' = waitLock, sendWaiters' = sendWaiters,
      parkedSendMsg' = parkedSendMsg, parkedSendFk' = parkedSendFk,
      prodPhase' = prodPhase, nextSendId' = nextSendId,
      consPhase' = consPhase, consGotMsg' = consGotMsg,
      nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
      childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
    }
  }

  // Zero-capture nursery exception abort: raise -> graft unwinds dynamic-wind after -> child-done
  action nursery_child_raise = all {
    childPhase == 0,
    childPhase' = 1,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
    waitLock' = waitLock, recvWaiters' = recvWaiters, sendWaiters' = sendWaiters,
    parkedSendMsg' = parkedSendMsg, parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
    prodPhase' = prodPhase, nextSendId' = nextSendId,
    consPhase' = consPhase, consGotMsg' = consGotMsg,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    fkState' = fkState, fkHasRawK' = fkHasRawK,
    nurseryActive' = nurseryActive, afterRan' = afterRan,
  }

  action nursery_graft_runs_after = all {
    childPhase == 1,
    childPhase' = 2,
    afterRan' = true,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
    waitLock' = waitLock, recvWaiters' = recvWaiters, sendWaiters' = sendWaiters,
    parkedSendMsg' = parkedSendMsg, parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
    prodPhase' = prodPhase, nextSendId' = nextSendId,
    consPhase' = consPhase, consGotMsg' = consGotMsg,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    fkState' = fkState, fkHasRawK' = fkHasRawK,
    nurseryActive' = nurseryActive,
  }

  action nursery_abort_marks_done = all {
    childPhase == 2,
    afterRan == true,
    childPhase' = 3,
    nurseryActive' = nurseryActive - 1,
    rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
    waitLock' = waitLock, recvWaiters' = recvWaiters, sendWaiters' = sendWaiters,
    parkedSendMsg' = parkedSendMsg, parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
    prodPhase' = prodPhase, nextSendId' = nextSendId,
    consPhase' = consPhase, consGotMsg' = consGotMsg,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    fkState' = fkState, fkHasRawK' = fkHasRawK,
    afterRan' = afterRan,
  }

  action stutter = all {
    rTail' = rTail, rHead' = rHead, seq0' = seq0, seq1' = seq1, buf0' = buf0, buf1' = buf1,
    waitLock' = waitLock, recvWaiters' = recvWaiters, sendWaiters' = sendWaiters,
    parkedSendMsg' = parkedSendMsg, parkedRecvFk' = parkedRecvFk, parkedSendFk' = parkedSendFk,
    prodPhase' = prodPhase, nextSendId' = nextSendId,
    consPhase' = consPhase, consGotMsg' = consGotMsg,
    nextRecvExpected' = nextRecvExpected, totalReceived' = totalReceived,
    fkState' = fkState, fkHasRawK' = fkHasRawK,
    childPhase' = childPhase, nurseryActive' = nurseryActive, afterRan' = afterRan,
  }

  action step = any {
    prod_direct_handoff,
    prod_vyukov_push,
    prod_check_no_waiters,
    prod_wake_receiver,
    cons_vyukov_pop,
    cons_check_no_senders,
    cons_park_recv,
    nursery_child_raise,
    nursery_graft_runs_after,
    nursery_abort_marks_done,
    stutter,
  }

  val inv_bounds_and_conservation =
    rHead <= rTail and
    (rTail - rHead) <= CAP and
    totalReceived + (rTail - rHead) == (nextSendId - 1)

  val inv_strict_fifo =
    nextRecvExpected == totalReceived + 1

  val inv_no_lost_wakeup =
    (prodPhase == 0) implies not ((rTail > rHead) and (recvWaiters > 0))

  val inv_fk_pool_clean =
    Set(1, 2, 3, 4).forall(id =>
      (fkState.get(id) == 0) implies (not (fkHasRawK.get(id)) and parkedRecvFk != id and parkedSendFk != id)
    )

  val inv_nursery_unwind_before_done =
    (nurseryActive < 2) implies afterRan

  val inv_all =
    inv_bounds_and_conservation and
    inv_strict_fifo and
    inv_no_lost_wakeup and
    inv_fk_pool_clean and
    inv_nursery_unwind_before_done
}
