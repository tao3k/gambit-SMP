// -*- mode: Bluespec; -*-
// Phase C42: Fiber Channel Cross-Scheduler Exchange-Cancel Routing,
// Seq-Cst Dekker Recv/Parker Ordering, Linearizable Unbuffered Try-Ops
// & Closed-Nursery Spawn Rejection.

module fiber_channel_dekker_cross_sched_and_nursery_close_smp {
  pure val SCHED_A = 0
  pure val SCHED_B = 1

  pure val NURSERY_LIVE = 0
  pure val NURSERY_CANCELLED = 1
  pure val NURSERY_CLOSED = 2

  // Cross-scheduler quiescence accounting
  var spawnedA: int
  var completedA: int
  var spawnedB: int
  var completedB: int

  // Exchange-cancel state: worker on SCHED_A extracts foreign fk owned by SCHED_B
  var rxfOwner: int      // -1 = empty, 0 = SCHED_A, 1 = SCHED_B
  var fkBOwner: int
  var fkAResumed: bool
  var fkBResumed: bool

  // Dekker buffered recv-park vs sender-push state
  var seqPublished: bool
  var rxwPublished: bool
  var senderSawWaiter: bool
  var recvSawSeq: bool
  var senderDone: bool
  var recvDone: bool

  // Unbuffered cap==0 try-recv state
  var unbufSenderParked: bool
  var unbufTryRecvGot: bool

  // Nursery lifecycle state (0=live, 1=cancelled, 2=closed)
  var nurseryState: int
  var nurseryActive: int
  var spawnAfterCloseRejected: bool

  var violation: bool

  pure def wakeTargetSched(callerSched: int, fkSched: int): int =
    if (callerSched == fkSched) callerSched else fkSched

  pure def isNurseryCancelled(st: int): bool = (st != NURSERY_LIVE)
  pure def canSpawnIntoNursery(st: int): bool = (st != NURSERY_CLOSED)

  action init = all {
    spawnedA' = 1,
    completedA' = 0,
    spawnedB' = 1,
    completedB' = 0,
    rxfOwner' = SCHED_B,
    fkBOwner' = SCHED_B,
    fkAResumed' = false,
    fkBResumed' = false,
    seqPublished' = false,
    rxwPublished' = false,
    senderSawWaiter' = false,
    recvSawSeq' = false,
    senderDone' = false,
    recvDone' = false,
    unbufSenderParked' = true,
    unbufTryRecvGot' = false,
    nurseryState' = NURSERY_LIVE,
    nurseryActive' = 1,
    spawnAfterCloseRejected' = false,
    violation' = false,
  }

  // Step 1: SCHED_A's fiber hits exchange-cancel and extracts SCHED_B's fk from rxf.
  // With `%wake-fk!`, fkB is routed strictly to SCHED_B (its owning %fk-sched),
  // while fkA was already woken on SCHED_A by the concurrent sender.
  action crossSchedExchangeCancel = all {
    not(fkAResumed),
    val target = wakeTargetSched(SCHED_A, fkBOwner)
    val bad = (target != SCHED_B)
    all {
      rxfOwner' = -1,
      fkAResumed' = true,
      fkBResumed' = true,
      completedA' = completedA + 1,
      completedB' = if (target == SCHED_B) completedB + 1 else completedB,
      spawnedA' = spawnedA,
      spawnedB' = spawnedB,
      fkBOwner' = fkBOwner,
      seqPublished' = seqPublished,
      rxwPublished' = rxwPublished,
      senderSawWaiter' = senderSawWaiter,
      recvSawSeq' = recvSawSeq,
      senderDone' = senderDone,
      recvDone' = recvDone,
      unbufSenderParked' = unbufSenderParked,
      unbufTryRecvGot' = unbufTryRecvGot,
      nurseryState' = nurseryState,
      nurseryActive' = nurseryActive,
      spawnAfterCloseRejected' = spawnAfterCloseRejected,
      violation' = (violation or bad),
    }
  }

  // Step 2a: Dekker sender publishes seq (seq_cst), then loads rxw (seq_cst)
  action dekkerSenderStep = all {
    not(senderDone),
    seqPublished' = true,
    senderSawWaiter' = rxwPublished,
    senderDone' = true,
    spawnedA' = spawnedA,
    completedA' = completedA,
    spawnedB' = spawnedB,
    completedB' = completedB,
    rxfOwner' = rxfOwner,
    fkBOwner' = fkBOwner,
    fkAResumed' = fkAResumed,
    fkBResumed' = fkBResumed,
    rxwPublished' = rxwPublished,
    recvSawSeq' = recvSawSeq,
    recvDone' = recvDone,
    unbufSenderParked' = unbufSenderParked,
    unbufTryRecvGot' = unbufTryRecvGot,
    nurseryState' = nurseryState,
    nurseryActive' = nurseryActive,
    spawnAfterCloseRejected' = spawnAfterCloseRejected,
    violation' = violation,
  }

  // Step 2b: Dekker receiver publishes rxw (seq_cst), then loads head & seq (seq_cst)
  action dekkerRecvStep = all {
    not(recvDone),
    rxwPublished' = true,
    recvSawSeq' = seqPublished,
    recvDone' = true,
    spawnedA' = spawnedA,
    completedA' = completedA,
    spawnedB' = spawnedB,
    completedB' = completedB,
    rxfOwner' = rxfOwner,
    fkBOwner' = fkBOwner,
    fkAResumed' = fkAResumed,
    fkBResumed' = fkBResumed,
    seqPublished' = seqPublished,
    senderSawWaiter' = senderSawWaiter,
    senderDone' = senderDone,
    unbufSenderParked' = unbufSenderParked,
    unbufTryRecvGot' = unbufTryRecvGot,
    nurseryState' = nurseryState,
    nurseryActive' = nurseryActive,
    spawnAfterCloseRejected' = spawnAfterCloseRejected,
    violation' = violation,
  }

  // Step 3: Unbuffered lock-synchronized try-recv sees parked sender (no spurious miss)
  action unbufTryRecvStep = all {
    unbufSenderParked,
    unbufSenderParked' = false,
    unbufTryRecvGot' = true,
    spawnedA' = spawnedA,
    completedA' = completedA,
    spawnedB' = spawnedB,
    completedB' = completedB,
    rxfOwner' = rxfOwner,
    fkBOwner' = fkBOwner,
    fkAResumed' = fkAResumed,
    fkBResumed' = fkBResumed,
    seqPublished' = seqPublished,
    rxwPublished' = rxwPublished,
    senderSawWaiter' = senderSawWaiter,
    recvSawSeq' = recvSawSeq,
    senderDone' = senderDone,
    recvDone' = recvDone,
    nurseryState' = nurseryState,
    nurseryActive' = nurseryActive,
    spawnAfterCloseRejected' = spawnAfterCloseRejected,
    violation' = violation,
  }

  // Step 4a: Nursery cancel then close on quiescence
  action nurseryCancelStep = all {
    nurseryState == NURSERY_LIVE,
    nurseryState' = NURSERY_CANCELLED,
    nurseryActive' = nurseryActive,
    spawnAfterCloseRejected' = spawnAfterCloseRejected,
    spawnedA' = spawnedA,
    completedA' = completedA,
    spawnedB' = spawnedB,
    completedB' = completedB,
    rxfOwner' = rxfOwner,
    fkBOwner' = fkBOwner,
    fkAResumed' = fkAResumed,
    fkBResumed' = fkBResumed,
    seqPublished' = seqPublished,
    rxwPublished' = rxwPublished,
    senderSawWaiter' = senderSawWaiter,
    recvSawSeq' = recvSawSeq,
    senderDone' = senderDone,
    recvDone' = recvDone,
    unbufSenderParked' = unbufSenderParked,
    unbufTryRecvGot' = unbufTryRecvGot,
    violation' = violation,
  }

  action nurseryCloseStep = all {
    nurseryState != NURSERY_CLOSED,
    nurseryState' = NURSERY_CLOSED,
    nurseryActive' = 0,
    spawnAfterCloseRejected' = spawnAfterCloseRejected,
    spawnedA' = spawnedA,
    completedA' = completedA,
    spawnedB' = spawnedB,
    completedB' = completedB,
    rxfOwner' = rxfOwner,
    fkBOwner' = fkBOwner,
    fkAResumed' = fkAResumed,
    fkBResumed' = fkBResumed,
    seqPublished' = seqPublished,
    rxwPublished' = rxwPublished,
    senderSawWaiter' = senderSawWaiter,
    recvSawSeq' = recvSawSeq,
    senderDone' = senderDone,
    recvDone' = recvDone,
    unbufSenderParked' = unbufSenderParked,
    unbufTryRecvGot' = unbufTryRecvGot,
    violation' = violation,
  }

  action attemptSpawnAfterClose = all {
    nurseryState == NURSERY_CLOSED,
    not(spawnAfterCloseRejected),
    val allowed = canSpawnIntoNursery(nurseryState)
    all {
      spawnAfterCloseRejected' = not(allowed),
      nurseryActive' = if (allowed) nurseryActive + 1 else nurseryActive,
      violation' = (violation or allowed),
      nurseryState' = nurseryState,
      spawnedA' = spawnedA,
      completedA' = completedA,
      spawnedB' = spawnedB,
      completedB' = completedB,
      rxfOwner' = rxfOwner,
      fkBOwner' = fkBOwner,
      fkAResumed' = fkAResumed,
      fkBResumed' = fkBResumed,
      seqPublished' = seqPublished,
      rxwPublished' = rxwPublished,
      senderSawWaiter' = senderSawWaiter,
      recvSawSeq' = recvSawSeq,
      senderDone' = senderDone,
      recvDone' = recvDone,
      unbufSenderParked' = unbufSenderParked,
      unbufTryRecvGot' = unbufTryRecvGot,
    }
  }

  action step = any {
    crossSchedExchangeCancel,
    dekkerSenderStep,
    dekkerRecvStep,
    unbufTryRecvStep,
    nurseryCancelStep,
    nurseryCloseStep,
    attemptSpawnAfterClose,
  }

  // Safety invariants
  val noViolationInv = not(violation)
  val dekkerNoLostWakeupInv = (senderDone and recvDone) implies (senderSawWaiter or recvSawSeq)
  val crossSchedQuiescenceBoundedInv = (completedA <= spawnedA) and (completedB <= spawnedB)
  val closedNurseryZeroActiveInv = (nurseryState == NURSERY_CLOSED) implies (nurseryActive == 0 and isNurseryCancelled(nurseryState))
  val allInvs = noViolationInv and dekkerNoLostWakeupInv and crossSchedQuiescenceBoundedInv and closedNurseryZeroActiveInv

  // Unit tests
  run dekkerSenderFirstTest =
    init
      .then(dekkerSenderStep)
      .then(dekkerRecvStep)
      .expect(dekkerNoLostWakeupInv and recvSawSeq)

  run dekkerRecvFirstTest =
    init
      .then(dekkerRecvStep)
      .then(dekkerSenderStep)
      .expect(dekkerNoLostWakeupInv and senderSawWaiter)

  run crossSchedRoutingConvergesTest =
    init
      .then(crossSchedExchangeCancel)
      .expect(completedA == spawnedA and completedB == spawnedB and not(violation))

  run unbufTryRecvLinearizableTest =
    init
      .then(unbufTryRecvStep)
      .expect(unbufTryRecvGot and not(unbufSenderParked))

  run nurseryCloseRejectsSpawnTest =
    init
      .then(nurseryCancelStep)
      .then(nurseryCloseStep)
      .then(attemptSpawnAfterClose)
      .expect(spawnAfterCloseRejected and nurseryActive == 0 and isNurseryCancelled(nurseryState) and not(violation))
}
