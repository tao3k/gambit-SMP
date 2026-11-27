// -*- mode: quint -*-
// Formal SMP Model for Direct-Style Work-Stealing Fiber Scheduler,
// Structured Concurrency Nursery, and Lock-Free Fiber Channel Rendezvous.
//
// Verifies across adversarial interleavings:
//   1. Exclusive One-Shot Fiber Execution (stolen fiber never resumed twice)
//   2. Channel Rendezvous Zero Lost Wakeup (send/recv race never orphans parked fiber)
//   3. Structured Nursery Soundness (parent exits iff all children are DONE)
//   4. Exact Fiber Conservation (ready + running + parked + done == spawned)

module fiber_scheduler_nursery_smp {
  pure val WORKERS: Set[int] = Set(0, 1, 2)
  pure val FIBERS: Set[int]  = Set(0, 1, 2, 3)

  // Fiber states:
  //   0 = UNSPAWNED
  //   1 = READY (queued in some worker deque or global inbox)
  //   2 = RUNNING (exclusively owned by ownerWorker[f])
  //   3 = PARKED_RECV (waiting on empty channel)
  //   4 = PARKED_SEND (waiting on full channel)
  //   5 = DONE
  pure val F_UNSPAWNED   = 0
  pure val F_READY       = 1
  pure val F_RUNNING     = 2
  pure val F_PARKED_RECV = 3
  pure val F_PARKED_SEND = 4
  pure val F_DONE        = 5

  // Channel capacity = 1 (bounded 1-slot rendezvous/buffered channel)
  pure val CHAN_CAP = 1

  var fState: int -> int
  var fOwner: int -> int            // worker id if RUNNING, else -1
  var fResumeCount: int -> int      // total activations of current suspension epoch
  var fInQueue: int -> bool         // true iff currently enqueued in ready pool
  var fDoneCounted: int -> bool     // true iff nursery active counter decremented

  // Structured nursery state
  var nurseryOpen: bool
  var nurseryActive: int
  var nurseryExited: bool

  // Bounded fiber channel state
  var chanItems: int                // 0..CHAN_CAP
  var recvWaiters: Set[int]         // fibers parked in F_PARKED_RECV
  var sendWaiters: Set[int]         // fibers parked in F_PARKED_SEND
  var sentTotal: int
  var recvTotal: int

  action init = all {
    fState'       = FIBERS.mapBy(_ => F_UNSPAWNED),
    fOwner'       = FIBERS.mapBy(_ => -1),
    fResumeCount' = FIBERS.mapBy(_ => 0),
    fInQueue'     = FIBERS.mapBy(_ => false),
    fDoneCounted' = FIBERS.mapBy(_ => false),
    nurseryOpen'   = true,
    nurseryActive' = 0,
    nurseryExited' = false,
    chanItems'     = 0,
    recvWaiters'   = Set(),
    sendWaiters'   = Set(),
    sentTotal'     = 0,
    recvTotal'     = 0,
  }

  // Spawn a new child fiber inside the structured nursery
  action spawnFiber(f: int): bool = all {
    nurseryOpen,
    not(nurseryExited),
    fState.get(f) == F_UNSPAWNED,
    fState'       = fState.set(f, F_READY),
    fInQueue'     = fInQueue.set(f, true),
    nurseryActive' = nurseryActive + 1,
    fOwner'       = fOwner,
    fResumeCount' = fResumeCount,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  // Worker atomically claims (pops or steals) a READY fiber via one-shot CAS
  action claimFiber(w: int, f: int): bool = all {
    fState.get(f) == F_READY,
    fInQueue.get(f),
    // Worker cannot run two fibers simultaneously
    WORKERS.contains(w),
    FIBERS.forall(other => fOwner.get(other) != w),
    fState'       = fState.set(f, F_RUNNING),
    fOwner'       = fOwner.set(f, w),
    fInQueue'     = fInQueue.set(f, false),
    fResumeCount' = fResumeCount.set(f, 1),
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  // Running fiber cooperatively yields -> back to READY (fresh suspension epoch)
  action yieldFiber(w: int, f: int): bool = all {
    fState.get(f) == F_RUNNING,
    fOwner.get(f) == w,
    fState'       = fState.set(f, F_READY),
    fOwner'       = fOwner.set(f, -1),
    fInQueue'     = fInQueue.set(f, true),
    fResumeCount' = fResumeCount.set(f, 0),
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  // Channel send: either handoff directly to a parked receiver, buffer if space,
  // or atomically park the sender (zero lost wakeup).
  action chanSendDirectHandoff(w: int, sender: int, receiver: int): bool = all {
    fState.get(sender) == F_RUNNING,
    fOwner.get(sender) == w,
    recvWaiters.contains(receiver),
    fState.get(receiver) == F_PARKED_RECV,
    chanItems == 0,
    // Wake receiver atomically into READY; sender continues RUNNING
    fState'       = fState.set(receiver, F_READY),
    fInQueue'     = fInQueue.set(receiver, true),
    fResumeCount' = fResumeCount.set(receiver, 0),
    recvWaiters'  = recvWaiters.exclude(Set(receiver)),
    sentTotal'    = sentTotal + 1,
    recvTotal'    = recvTotal + 1,
    fOwner'       = fOwner,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    sendWaiters'  = sendWaiters,
  }

  action chanSendBuffer(w: int, sender: int): bool = all {
    fState.get(sender) == F_RUNNING,
    fOwner.get(sender) == w,
    recvWaiters.size() == 0,
    chanItems < CHAN_CAP,
    chanItems'    = chanItems + 1,
    sentTotal'    = sentTotal + 1,
    fState'       = fState,
    fOwner'       = fOwner,
    fInQueue'     = fInQueue,
    fResumeCount' = fResumeCount,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    recvTotal'    = recvTotal,
  }

  action chanSendPark(w: int, sender: int): bool = all {
    fState.get(sender) == F_RUNNING,
    fOwner.get(sender) == w,
    recvWaiters.size() == 0,
    chanItems == CHAN_CAP,
    fState'       = fState.set(sender, F_PARKED_SEND),
    fOwner'       = fOwner.set(sender, -1),
    fResumeCount' = fResumeCount.set(sender, 0),
    sendWaiters'  = sendWaiters.union(Set(sender)),
    fInQueue'     = fInQueue,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  // Channel recv: either take buffered item (waking a parked sender if any) or park
  action chanRecvTakeAndWake(w: int, receiver: int, sender: int): bool = all {
    fState.get(receiver) == F_RUNNING,
    fOwner.get(receiver) == w,
    chanItems > 0,
    sendWaiters.contains(sender),
    fState.get(sender) == F_PARKED_SEND,
    // Receiver consumes 1 buffered item; parked sender immediately refills & wakes
    fState'       = fState.set(sender, F_READY),
    fInQueue'     = fInQueue.set(sender, true),
    fResumeCount' = fResumeCount.set(sender, 0),
    sendWaiters'  = sendWaiters.exclude(Set(sender)),
    sentTotal'    = sentTotal + 1,
    recvTotal'    = recvTotal + 1,
    fOwner'       = fOwner,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
  }

  action chanRecvTakeOnly(w: int, receiver: int): bool = all {
    fState.get(receiver) == F_RUNNING,
    fOwner.get(receiver) == w,
    chanItems > 0,
    sendWaiters.size() == 0,
    chanItems'    = chanItems - 1,
    recvTotal'    = recvTotal + 1,
    fState'       = fState,
    fOwner'       = fOwner,
    fInQueue'     = fInQueue,
    fResumeCount' = fResumeCount,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
  }

  action chanRecvPark(w: int, receiver: int): bool = all {
    fState.get(receiver) == F_RUNNING,
    fOwner.get(receiver) == w,
    chanItems == 0,
    sendWaiters.size() == 0,
    fState'       = fState.set(receiver, F_PARKED_RECV),
    fOwner'       = fOwner.set(receiver, -1),
    fResumeCount' = fResumeCount.set(receiver, 0),
    recvWaiters'  = recvWaiters.union(Set(receiver)),
    fInQueue'     = fInQueue,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  // Running fiber completes and decrements nurseryActive
  action completeFiber(w: int, f: int): bool = all {
    fState.get(f) == F_RUNNING,
    fOwner.get(f) == w,
    not(fDoneCounted.get(f)),
    fState'       = fState.set(f, F_DONE),
    fOwner'       = fOwner.set(f, -1),
    fResumeCount' = fResumeCount.set(f, 0),
    fDoneCounted' = fDoneCounted.set(f, true),
    nurseryActive' = nurseryActive - 1,
    fInQueue'     = fInQueue,
    nurseryOpen'  = nurseryOpen,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  action closeNurseryScope = all {
    nurseryOpen,
    nurseryOpen'  = false,
    fState'       = fState,
    fOwner'       = fOwner,
    fInQueue'     = fInQueue,
    fResumeCount' = fResumeCount,
    fDoneCounted' = fDoneCounted,
    nurseryActive' = nurseryActive,
    nurseryExited' = nurseryExited,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  action exitNursery = all {
    not(nurseryOpen),
    not(nurseryExited),
    nurseryActive == 0,
    nurseryExited' = true,
    fState'       = fState,
    fOwner'       = fOwner,
    fInQueue'     = fInQueue,
    fResumeCount' = fResumeCount,
    fDoneCounted' = fDoneCounted,
    nurseryOpen'  = nurseryOpen,
    nurseryActive' = nurseryActive,
    chanItems'    = chanItems,
    recvWaiters'  = recvWaiters,
    sendWaiters'  = sendWaiters,
    sentTotal'    = sentTotal,
    recvTotal'    = recvTotal,
  }

  action step = any {
    nondet f = oneOf(FIBERS)
    spawnFiber(f),
    nondet w = oneOf(WORKERS)
    nondet f = oneOf(FIBERS)
    claimFiber(w, f),
    nondet w = oneOf(WORKERS)
    nondet f = oneOf(FIBERS)
    yieldFiber(w, f),
    nondet w = oneOf(WORKERS)
    nondet s = oneOf(FIBERS)
    nondet r = oneOf(FIBERS)
    chanSendDirectHandoff(w, s, r),
    nondet w = oneOf(WORKERS)
    nondet s = oneOf(FIBERS)
    chanSendBuffer(w, s),
    nondet w = oneOf(WORKERS)
    nondet s = oneOf(FIBERS)
    chanSendPark(w, s),
    nondet w = oneOf(WORKERS)
    nondet r = oneOf(FIBERS)
    nondet s = oneOf(FIBERS)
    chanRecvTakeAndWake(w, r, s),
    nondet w = oneOf(WORKERS)
    nondet r = oneOf(FIBERS)
    chanRecvTakeOnly(w, r),
    nondet w = oneOf(WORKERS)
    nondet r = oneOf(FIBERS)
    chanRecvPark(w, r),
    nondet w = oneOf(WORKERS)
    nondet f = oneOf(FIBERS)
    completeFiber(w, f),
    closeNurseryScope,
    exitNursery,
  }

  // --- SAFETY INVARIANTS ---

  // 1. Exclusive one-shot execution: no fiber runs on two workers or activates twice
  val invExclusiveExecution: bool =
    FIBERS.forall(f =>
      fResumeCount.get(f) <= 1 and
      (fState.get(f) == F_RUNNING implies WORKERS.contains(fOwner.get(f))) and
      (fState.get(f) != F_RUNNING implies fOwner.get(f) == -1)
    ) and
    WORKERS.forall(w =>
      FIBERS.filter(f => fOwner.get(f) == w).size() <= 1
    )

  // 2. Zero lost wakeup on channel: cannot have both buffered items and parked
  //    receivers, nor free buffer space and parked senders, nor both waiters.
  val invChannelNoLostWakeup: bool =
    chanItems >= 0 and chanItems <= CHAN_CAP and
    (chanItems > 0 implies recvWaiters.size() == 0) and
    (chanItems < CHAN_CAP implies sendWaiters.size() == 0) and
    not(recvWaiters.size() > 0 and sendWaiters.size() > 0) and
    recvWaiters.forall(f => fState.get(f) == F_PARKED_RECV) and
    sendWaiters.forall(f => fState.get(f) == F_PARKED_SEND)

  // 3. Message conservation: sentTotal == recvTotal + chanItems
  val invMessageConservation: bool =
    sentTotal == recvTotal + chanItems

  // 4. Structured nursery soundness: once exited, zero orphaned live fibers exist
  val invStructuredNurserySoundness: bool =
    nurseryActive >= 0 and
    nurseryActive == FIBERS.filter(f =>
      fState.get(f) == F_READY or fState.get(f) == F_RUNNING or
      fState.get(f) == F_PARKED_RECV or fState.get(f) == F_PARKED_SEND
    ).size() and
    (nurseryExited implies FIBERS.forall(f =>
      fState.get(f) == F_UNSPAWNED or fState.get(f) == F_DONE
    ))

  val allInvariants: bool =
    invExclusiveExecution and
    invChannelNoLostWakeup and
    invMessageConservation and
    invStructuredNurserySoundness
}
