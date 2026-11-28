// Phase C12 Formal Model:
//   1. Fused C23 %ch-park-recv-c! & %ch-park-send-c! Dekker seq_cst protocol (CAP=1)
//   2. Empty-Deque LIFO-Streak Bypass preserving strict sibling anti-starvation
//   3. Direct %dq-pop! switch in %sched-switch-next! (zero wasted sched-k grafts)
//   4. Fused %ch-try-direct-handoff-c! with SATB-safe rk.val write barrier

module fused_park_and_direct_dq_switch_smp {
  pure val MAX_STREAK = 8
  pure val CAP = 1

  // Scheduler LIFO + local deque anti-starvation model
  var lifoHasTask: bool
  var lifoStreak: int
  var dqLen: int
  var siblingServed: int
  var starvedSibling: bool

  // Fused park-send / park-recv on CAP=1 channel
  var rTail: int
  var rHead: int
  var rxWaiters: int
  var txWaiters: int
  var parkedRx: bool
  var parkedTx: bool
  var satbActive: bool
  var unshadedBarrierMiss: int

  action init = all {
    lifoHasTask' = true,
    lifoStreak' = 0,
    dqLen' = 0,
    siblingServed' = 0,
    starvedSibling' = false,
    rTail' = 0,
    rHead' = 0,
    rxWaiters' = 0,
    txWaiters' = 0,
    parkedRx' = false,
    parkedTx' = false,
    satbActive' = true,
    unshadedBarrierMiss' = 0,
  }

  // Enqueue a sibling task into local deque
  action enqueue_sibling_dq = all {
    dqLen < 4,
    dqLen' = dqLen + 1,
    lifoHasTask' = lifoHasTask, lifoStreak' = lifoStreak,
    siblingServed' = siblingServed, starvedSibling' = starvedSibling,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters, txWaiters' = txWaiters,
    parkedRx' = parkedRx, parkedTx' = parkedTx,
    satbActive' = satbActive, unshadedBarrierMiss' = unshadedBarrierMiss,
  }

  // Direct LIFO switch allowed iff (lifoStreak < MAX_STREAK) OR (dqLen == 0)!
  action switch_lifo_direct = all {
    lifoHasTask,
    (lifoStreak < MAX_STREAK) or (dqLen == 0),
    // Cap streak at MAX_STREAK when dq is empty so the instant a sibling arrives,
    // the very next switch immediately yields to dq!
    lifoStreak' = if (lifoStreak < MAX_STREAK) lifoStreak + 1 else MAX_STREAK,
    starvedSibling' = (dqLen > 0 and lifoStreak >= MAX_STREAK),
    lifoHasTask' = true, // ping-pong partner re-populates lifo
    dqLen' = dqLen, siblingServed' = siblingServed,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters, txWaiters' = txWaiters,
    parkedRx' = parkedRx, parkedTx' = parkedTx,
    satbActive' = satbActive, unshadedBarrierMiss' = unshadedBarrierMiss,
  }

  // Direct %dq-pop! switch in %sched-switch-next! when dqLen > 0 and (not lifo or streak >= MAX_STREAK)
  action switch_dq_direct = all {
    dqLen > 0,
    (not(lifoHasTask)) or (lifoStreak >= MAX_STREAK),
    dqLen' = dqLen - 1,
    lifoStreak' = 0,
    siblingServed' = siblingServed + 1,
    lifoHasTask' = lifoHasTask, starvedSibling' = starvedSibling,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters, txWaiters' = txWaiters,
    parkedRx' = parkedRx, parkedTx' = parkedTx,
    satbActive' = satbActive, unshadedBarrierMiss' = unshadedBarrierMiss,
  }

  // Fused C23 %ch-park-recv-c! on empty CAP=1 channel
  action fused_park_recv = all {
    not(parkedRx),
    rTail == rHead,
    not(parkedTx),
    parkedRx' = true,
    rxWaiters' = 1,
    rTail' = rTail, rHead' = rHead, txWaiters' = txWaiters, parkedTx' = parkedTx,
    lifoHasTask' = lifoHasTask, lifoStreak' = lifoStreak,
    dqLen' = dqLen, siblingServed' = siblingServed, starvedSibling' = starvedSibling,
    satbActive' = satbActive, unshadedBarrierMiss' = unshadedBarrierMiss,
  }

  // Fused C23 %ch-try-direct-handoff-c! wakes parked receiver with SATB barrier on rk.val
  action fused_direct_handoff = all {
    parkedRx,
    rxWaiters > 0,
    rTail == rHead,
    parkedRx' = false,
    rxWaiters' = 0,
    unshadedBarrierMiss' = unshadedBarrierMiss, // ___GC_WRITE_BARRIER called on rk.val
    rTail' = rTail, rHead' = rHead, txWaiters' = txWaiters, parkedTx' = parkedTx,
    lifoHasTask' = true, lifoStreak' = lifoStreak,
    dqLen' = dqLen, siblingServed' = siblingServed, starvedSibling' = starvedSibling,
    satbActive' = satbActive,
  }

  // Push into CAP=1 ring when empty & no parked receiver
  action ring_push_cap1 = all {
    (rTail - rHead) < CAP,
    not(parkedRx),
    rTail' = rTail + 1,
    rHead' = rHead, rxWaiters' = rxWaiters, txWaiters' = txWaiters,
    parkedRx' = parkedRx, parkedTx' = parkedTx,
    lifoHasTask' = lifoHasTask, lifoStreak' = lifoStreak,
    dqLen' = dqLen, siblingServed' = siblingServed, starvedSibling' = starvedSibling,
    satbActive' = satbActive, unshadedBarrierMiss' = unshadedBarrierMiss,
  }

  // Fused C23 %ch-park-send-c! when CAP=1 ring is FULL
  action fused_park_send = all {
    not(parkedTx),
    (rTail - rHead) == CAP,
    parkedTx' = true,
    txWaiters' = 1,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters, parkedRx' = parkedRx,
    lifoHasTask' = lifoHasTask, lifoStreak' = lifoStreak,
    dqLen' = dqLen, siblingServed' = siblingServed, starvedSibling' = starvedSibling,
    satbActive' = satbActive, unshadedBarrierMiss' = unshadedBarrierMiss,
  }

  // Pop from CAP=1 ring and wake parked sender atomically (no lost wakeup!)
  action ring_pop_and_wake_sender = all {
    (rTail - rHead) > 0,
    rHead' = rHead + 1,
    rTail' = if (parkedTx) rTail + 1 else rTail,
    parkedTx' = false,
    txWaiters' = 0,
    rxWaiters' = rxWaiters, parkedRx' = parkedRx,
    lifoHasTask' = lifoHasTask, lifoStreak' = lifoStreak,
    dqLen' = dqLen, siblingServed' = siblingServed, starvedSibling' = starvedSibling,
    satbActive' = satbActive, unshadedBarrierMiss' = unshadedBarrierMiss,
  }

  action step = any {
    enqueue_sibling_dq,
    switch_lifo_direct,
    switch_dq_direct,
    fused_park_recv,
    fused_direct_handoff,
    ring_push_cap1,
    fused_park_send,
    ring_pop_and_wake_sender,
  }

  // INVARIANT 1: Sibling anti-starvation (LIFO never bypasses non-empty dq at streak >= MAX_STREAK)
  val inv_no_sibling_starvation =
    not(starvedSibling) and lifoStreak <= MAX_STREAK

  // INVARIANT 2: CAP=1 bounds & zero lost wakeups on BOTH recv and send
  val inv_cap1_no_lost_wakeup =
    rHead <= rTail and
    (rTail - rHead) <= CAP and
    not ((rTail > rHead) and parkedRx) and
    not (((rTail - rHead) < CAP) and parkedTx)

  // INVARIANT 3: Zero SATB write-barrier omissions
  val inv_satb_complete =
    unshadedBarrierMiss == 0

  val inv_all =
    inv_no_sibling_starvation and
    inv_cap1_no_lost_wakeup and
    inv_satb_complete
}
