module gc_work_closure {
  import WorkObligations.* from "../library/gc/WorkObligations"
  // Paper-guided composition: two workers, graph 1 -> 2 -> 1, two phases.
  // One object stands for a chunk's pending region, not a real block layout.
  // Queue release/acquire and count/wait are atomic abstractions. Mutators stop.
  // Fault controls are not claims that the current Gambit source permits them.
  type QueueObservation = Acquired(int) | ConfirmedEmpty | Unobserved
  // Small finite qualification horizons, not runtime limits or build options.
  pure val generationCeiling = 3
  type State = { fault: int, phase: int, work: int -> int,
    owner: int -> int, copied: int -> int, visible: int -> int,
    scans: int -> int, active: int -> bool, arrived: int -> bool,
    observation: int -> QueueObservation, observedPhase: int -> int, observedQueue: int -> int,
    queueRevision: int -> int, observedRevision: int -> int,
    unsettled: int -> bool, badIdle: bool,
    claimStage: int -> int, claimItem: int -> int, claimQueue: int -> int,
    claimPhase: int -> int, claimSerial: int -> int, claimReaders: int -> int,
    heldGate: int -> int, gateUseClosed: int -> bool,
    queryOpen: int -> bool, writerOpen: int -> bool, writerBorrow: int -> int,
    writerGeneration: int -> int, writerToken: int -> int,
    writerValidated: int -> bool,
    count: int, done: bool, staleRead: bool, badPhase: bool }
  // Work: 0 undiscovered, 1 local root, 2 private copy, 3 claimed but linked, 4 queued,
  // 5 scanning, 6 scanned. A forwarding identity may exist in state 2.
  pure def initialState(fault: int): State = {
    fault: fault, phase: 0, work: Map(1 -> 1, 2 -> 0),
    owner: Map(1 -> 1, 2 -> 0), copied: Map(1 -> 0, 2 -> 0),
    visible: Map(1 -> 0, 2 -> 0), scans: Map(1 -> 0, 2 -> 0),
    active: Map(1 -> true, 2 -> true), arrived: Map(1 -> false, 2 -> false),
    observation: Map(1 -> Unobserved, 2 -> Unobserved),
    observedQueue: Map(1 -> 0, 2 -> 0),
    observedPhase: Map(1 -> -1, 2 -> -1), queueRevision: Map(1 -> 0, 2 -> 0),
    observedRevision: Map(1 -> -1, 2 -> -1), unsettled: Map(1 -> false, 2 -> false),
    badIdle: false,
    claimStage: Map(1 -> 0, 2 -> 0), claimItem: Map(1 -> 0, 2 -> 0),
    claimQueue: Map(1 -> 0, 2 -> 0), claimPhase: Map(1 -> -1, 2 -> -1),
    claimSerial: Map(1 -> 0, 2 -> 0), claimReaders: Map(1 -> 0, 2 -> 0),
    heldGate: Map(1 -> 0, 2 -> 0),
    gateUseClosed: Map(1 -> false, 2 -> false),
    queryOpen: Map(1 -> false, 2 -> false), writerOpen: Map(1 -> false, 2 -> false),
    writerBorrow: Map(1 -> 0, 2 -> 0), writerGeneration: Map(1 -> 1, 2 -> 1),
    writerToken: Map(1 -> 0, 2 -> 0),
    writerValidated: Map(1 -> false, 2 -> false),
    count: 2, done: false, staleRead: false, badPhase: false,
  }
  action initOld = s' = initialState(1)
  action initEarlyIdle = s' = initialState(2)
  action initDuplicateClaim = s' = initialState(3)
  action initEarlyPhase = s' = initialState(4)
  action initLatePublisher = s' = initialState(5)
  action initFixed = s' = initialState(0)
  action initExhaustedSerial = s' = { ...initialState(0), claimSerial: Map(1 -> generationCeiling, 2 -> generationCeiling) }
  var s: State

  action claim(o: int, w: int): bool = all {
    not(s.done), s.active.get(w), s.work.get(o) == 1, s.owner.get(o) == w,
    not(s.unsettled.get(w)),
    s' = { ...s, work: s.work.set(o, 2) },
  }
  action copyWord(o: int): bool = all {
    not(s.done), s.work.get(o) == 2, s.active.get(s.owner.get(o)),
    s.copied.get(o) < 2,
    not(s.unsettled.get(s.owner.get(o))),
    s' = { ...s, copied: s.copied.set(o, s.copied.get(o) + 1) },
  }
  action publishAt(o: int, phase: int): bool = all {
    not(s.done), s.work.get(o) == 2, s.active.get(s.owner.get(o)),
    phase == s.phase or s.fault == 5,
    s.copied.get(o) == 2 or s.fault == 1,
    not(s.unsettled.get(s.owner.get(o))),
    s.heldGate.get(s.owner.get(o)) == 0,
    s' = { ...s, work: s.work.set(o, 4),
      queueRevision: s.queueRevision.set(s.owner.get(o), s.queueRevision.get(s.owner.get(o)) + 1),
      visible: s.visible.set(o, s.copied.get(o)),
      badPhase: s.badPhase or phase != s.phase },
  }
  action publish(o: int): bool = publishAt(o, s.phase)
  // A logical phase witness, not a claim that current C checks this token.
  action rejectLatePublication(phase: int): bool = all {
    phase != s.phase, s' = s,
  }
  // Failed gate acquisition observes no queue state and changes no count.
  def canObserve(w: int): bool = not(s.done) and s.active.get(w) and not(s.unsettled.get(w))
  action busyTakeFrom(w: int, target: int): bool = all {
    canObserve(w),
    s' = { ...s, observation: s.observation.set(w, Unobserved),
      observedQueue: s.observedQueue.set(w, target),
      observedRevision: s.observedRevision.set(w, -1) },
  }
  action busyTake(w: int): bool = busyTakeFrom(w, w)
  action observeEmpty(w: int, target: int): bool = all {
    not(s.done), s.active.get(w), not(s.unsettled.get(w)),
    s.heldGate.get(target) == 0,
    Set(1, 2).forall(o => not(s.work.get(o) == 4 and s.owner.get(o) == target)),
    s' = { ...s, observation: s.observation.set(w, ConfirmedEmpty),
      observedQueue: s.observedQueue.set(w, target),
      observedPhase: s.observedPhase.set(w, s.phase),
      observedRevision: s.observedRevision.set(w, s.queueRevision.get(target)) },
  }
  action observeOwnEmpty(w: int): bool = observeEmpty(w, w)
  action scanLocal(o: int, w: int): bool = all {
    not(s.done), s.active.get(w), s.owner.get(o) == w,
    s.work.get(o) == 2, s.copied.get(o) == 2,
    not(s.unsettled.get(w)),
    s' = { ...s, work: s.work.set(o, 5),
      scans: s.scans.set(o, s.scans.get(o) + 1) },
  }
  def canStartTake(o: int, w: int): bool = all {
    canObserve(w), s.work.get(o) == 4, s.heldGate.get(s.owner.get(o)) == 0,
    s.claimReaders.get(w) == 0,
    not(s.queryOpen.get(w)), not(s.writerOpen.get(w)), s.writerBorrow.get(w) == 0,
    s.claimSerial.get(w) < generationCeiling,
    Set(1, 2).forall(i => not(s.owner.get(i) == w and Set(3, 5).contains(s.work.get(i)))),
    s.fault == 3 or s.claimStage.get(w) == 0,
  }
  action acquire(o: int, w: int): bool = all {
    canStartTake(o, w),
    s' = { ...s, work: s.work.set(o, if (s.fault == 3) 4 else 5),
      owner: s.owner.set(o, w), scans: s.scans.set(o, s.scans.get(o) + 1),
      queueRevision: s.queueRevision.set(s.owner.get(o), s.queueRevision.get(s.owner.get(o)) + 1),
      observation: s.observation.set(w, Acquired(o)),
      observedQueue: s.observedQueue.set(w, s.owner.get(o)),
      observedRevision: s.observedRevision.set(w, -1),
      claimStage: s.claimStage.set(w, 6), claimItem: s.claimItem.set(w, o),
      claimQueue: s.claimQueue.set(w, s.owner.get(o)), claimPhase: s.claimPhase.set(w, s.phase),
      claimSerial: s.claimSerial.set(w, s.claimSerial.get(w) + 1),
      gateUseClosed: s.gateUseClosed.set(w, true),
      queryOpen: s.queryOpen.set(w, true), writerOpen: s.writerOpen.set(w, true),
      staleRead: s.staleRead or s.visible.get(o) != 2 },
  }
  // Internal claim commits, but its delivery is unknown. This is NOT the
  // certain Unobserved/busy result. While unsettled the outcome field is invalid.
  action loseClaimOutcome(o: int, w: int): bool = all {
    canStartTake(o, w),
    s' = { ...s, work: s.work.set(o, 5), owner: s.owner.set(o, w),
      scans: s.scans.set(o, s.scans.get(o) + 1),
      queueRevision: s.queueRevision.set(s.owner.get(o), s.queueRevision.get(s.owner.get(o)) + 1),
      unsettled: s.unsettled.set(w, true), observedQueue: s.observedQueue.set(w, s.owner.get(o)),
      claimStage: s.claimStage.set(w, 5), claimItem: s.claimItem.set(w, o),
      claimQueue: s.claimQueue.set(w, s.owner.get(o)), claimPhase: s.claimPhase.set(w, s.phase),
      claimSerial: s.claimSerial.set(w, s.claimSerial.get(w) + 1),
      gateUseClosed: s.gateUseClosed.set(w, true),
      queryOpen: s.queryOpen.set(w, true), writerOpen: s.writerOpen.set(w, true),
      observedRevision: s.observedRevision.set(w, -1) },
  }
  def matchingClaim(w: int, phase: int, serial: int): bool =
    s.claimStage.get(w) != 0 and s.claimPhase.get(w) == phase and s.claimSerial.get(w) == serial
  def canSettleClaim(o: int, w: int, phase: int, serial: int): bool = all {
    matchingClaim(w, phase, serial), s.claimStage.get(w) == 5,
    s.claimItem.get(w) == o, s.unsettled.get(w), s.work.get(o) == 5, s.owner.get(o) == w,
    writerAuthorized(w) or (s.writerOpen.get(w) and s.writerBorrow.get(w) == 0),
  }
  action settleClaimAt(o: int, w: int, phase: int, serial: int): bool = all {
    canSettleClaim(o, w, phase, serial),
    s' = { ...s, unsettled: s.unsettled.set(w, false),
      claimStage: s.claimStage.set(w, 6),
      writerBorrow: s.writerBorrow.set(w, 0), writerToken: s.writerToken.set(w, 0),
      writerValidated: s.writerValidated.set(w, false),
      observation: s.observation.set(w, Acquired(o)) },
  }
  action settleClaim(o: int, w: int): bool = settleClaimAt(o, w, s.phase, s.claimSerial.get(w))

  // Retained microsteps of one bounded slot per worker. heldGate models only
  // these interrupted fragments; ordinary completed calls above stay atomic.
  // Stage1 intent,2 claimed-but-linked,3 detached,4 committed/gate-held,
  // 5 gate released/return pending,6 delivered. No arbitrary crash repair.
  action prepareTake(o: int, w: int): bool = all {
    canStartTake(o, w),
    s' = { ...s, unsettled: s.unsettled.set(w, true),
      claimStage: s.claimStage.set(w, 1), claimItem: s.claimItem.set(w, o),
      claimQueue: s.claimQueue.set(w, s.owner.get(o)), claimPhase: s.claimPhase.set(w, s.phase),
      claimSerial: s.claimSerial.set(w, s.claimSerial.get(w) + 1),
      gateUseClosed: s.gateUseClosed.set(w, false),
      queryOpen: s.queryOpen.set(w, true), writerOpen: s.writerOpen.set(w, true),
      writerBorrow: s.writerBorrow.set(w, 1), writerToken: s.writerToken.set(w, s.writerGeneration.get(w)),
      writerValidated: s.writerValidated.set(w, true),
      heldGate: s.heldGate.set(s.owner.get(o), w), observedRevision: s.observedRevision.set(w, -1) },
  }
  def canMarkPrepared(w: int): bool = all {
    writerAuthorized(w),
    s.claimStage.get(w) == 1, s.heldGate.get(s.claimQueue.get(w)) == w,
    s.work.get(s.claimItem.get(w)) == 4,
  }
  action markPreparedClaim(w: int): bool = all {
    canMarkPrepared(w),
    val o = s.claimItem.get(w)
    s' = { ...s, work: s.work.set(o, 3),
      owner: s.owner.set(o, w), scans: s.scans.set(o, s.scans.get(o) + 1) },
  }
  action recordClaimMarked(w: int): bool = all {
    writerAuthorized(w),
    s.claimStage.get(w) == 1, s.work.get(s.claimItem.get(w)) == 3,
    s.owner.get(s.claimItem.get(w)) == w,
    s' = { ...s, claimStage: s.claimStage.set(w, 2) },
  }
  def canDetachPrepared(w: int): bool = all {
    writerAuthorized(w),
    s.claimStage.get(w) == 2, s.heldGate.get(s.claimQueue.get(w)) == w,
    s.work.get(s.claimItem.get(w)) == 3,
  }
  action detachPreparedClaim(w: int): bool = all {
    canDetachPrepared(w),
    val o = s.claimItem.get(w)
    s' = { ...s, work: s.work.set(o, 5),
      queueRevision: s.queueRevision.set(s.claimQueue.get(w), s.queueRevision.get(s.claimQueue.get(w)) + 1) },
  }
  action recordClaimDetached(w: int): bool = all {
    writerAuthorized(w),
    s.claimStage.get(w) == 2, s.work.get(s.claimItem.get(w)) == 5,
    s' = { ...s, claimStage: s.claimStage.set(w, 3) },
  }
  action commitPreparedClaim(w: int): bool = all {
    writerAuthorized(w),
    s.claimStage.get(w) == 3, s.heldGate.get(s.claimQueue.get(w)) == w,
    s' = { ...s, claimStage: s.claimStage.set(w, 4) },
  }
  action closeClaimGate(w: int): bool = all {
    writerAuthorized(w),
    s.claimStage.get(w) == 4, s.heldGate.get(s.claimQueue.get(w)) == w,
    s' = { ...s, heldGate: s.heldGate.set(s.claimQueue.get(w), 0),
      gateUseClosed: s.gateUseClosed.set(w, true) },
  }
  action recordClaimGateClosed(w: int): bool = all {
    writerAuthorized(w),
    s.claimStage.get(w) == 4, s.gateUseClosed.get(w),
    s' = { ...s, claimStage: s.claimStage.set(w, 5) },
  }
  // Cooperative cancellation, or a helper with separately established source
  // writer closure. Query alone never supplies that authority. Stage1 may lag
  // the physical claim, so cancellation also checks actual work remains queued.
  action cancelUnclaimedIntent(w: int): bool = all {
    canMarkPrepared(w),
    s' = { ...s, claimStage: s.claimStage.set(w, 7), unsettled: s.unsettled.set(w, false),
      writerBorrow: s.writerBorrow.set(w, 0), writerToken: s.writerToken.set(w, 0),
      writerValidated: s.writerValidated.set(w, false),
      heldGate: s.heldGate.set(s.claimQueue.get(w), 0), gateUseClosed: s.gateUseClosed.set(w, true) },
  }
  def claimView(w: int, phase: int, serial: int): str =
    if (not(matchingClaim(w, phase, serial))) "not-current-observation"
    else if (s.claimStage.get(w) < 4) "partial-pending"
    else if (s.claimStage.get(w) == 4) "committed-release-unconfirmed"
    else if (s.claimStage.get(w) == 5) "committed-return-pending"
    else if (s.claimStage.get(w) == 7) "known-unclaimed-abort"
    else "delivered"
  action pinClaim(w: int, phase: int, serial: int): bool = all {
    canPinQueryStorage(w), matchingClaim(w, phase, serial),
    s' = { ...s, claimReaders: s.claimReaders.set(w, 1) },
  }
  action queryClaim(w: int, phase: int, serial: int): bool = all {
    matchingClaim(w, phase, serial), s.claimReaders.get(w) == 1, s' = s,
  }
  action unpinClaim(w: int): bool = all {
    s.claimReaders.get(w) == 1, s' = { ...s, claimReaders: s.claimReaders.set(w, 0) },
  }
  // Exposes pin-before-key-check to the close/reuse interleaving.
  def canPinQueryStorage(w: int): bool = s.queryOpen.get(w) and s.claimReaders.get(w) == 0
  action rejectQueryAdmission(w: int): bool = all { not(canPinQueryStorage(w)), s' = s }
  action pinQueryStorage(w: int): bool = all {
    canPinQueryStorage(w),
    s' = { ...s, claimReaders: s.claimReaders.set(w, 1) },
  }
  action sealQuery(w: int): bool = all { s.queryOpen.get(w),
    s' = { ...s, queryOpen: s.queryOpen.set(w, false) } }
  action sealWriters(w: int): bool = all { s.writerOpen.get(w),
    s' = { ...s, writerOpen: s.writerOpen.set(w, false) } }
  def writerAuthorized(w: int): bool = s.writerBorrow.get(w) == 1 and s.writerValidated.get(w) and
    s.writerToken.get(w) == s.writerGeneration.get(w)
  action leaveWriter(w: int): bool = all { writerAuthorized(w),
    s' = { ...s, writerBorrow: s.writerBorrow.set(w, 0), writerToken: s.writerToken.set(w, 0),
      writerValidated: s.writerValidated.set(w, false) } }
  def canEnterWriter(w: int, phase: int, serial: int, generation: int): bool = all {
    matchingClaim(w, phase, serial), s.writerOpen.get(w), not(s.arrived.get(w)),
    s.writerBorrow.get(w) == 0, s.writerGeneration.get(w) == generation,
  }
  action enterWriter(w: int, phase: int, serial: int, generation: int): bool = all {
    canEnterWriter(w, phase, serial, generation),
    s' = { ...s, writerBorrow: s.writerBorrow.set(w, 1), writerToken: s.writerToken.set(w, generation),
      writerValidated: s.writerValidated.set(w, true) },
  }
  // Real entry is pin-before-key/generation-check; the atomic entry above is
  // the completed abstraction. An unvalidated pin grants no payload writes.
  action pinWriterAdmission(w: int): bool = all {
    s.writerOpen.get(w), s.claimStage.get(w) != 0, not(s.arrived.get(w)), s.writerBorrow.get(w) == 0,
    s' = { ...s, writerBorrow: s.writerBorrow.set(w, 1), writerToken: s.writerToken.set(w, 0),
      writerValidated: s.writerValidated.set(w, false) },
  }
  action validateWriter(w: int, phase: int, serial: int, generation: int): bool = all {
    s.writerBorrow.get(w) == 1, not(s.writerValidated.get(w)), matchingClaim(w, phase, serial),
    s.writerGeneration.get(w) == generation,
    s' = { ...s, writerToken: s.writerToken.set(w, generation), writerValidated: s.writerValidated.set(w, true) },
  }
  action rejectWriter(w: int, phase: int, serial: int, generation: int): bool = all {
    s.writerBorrow.get(w) == 1, not(s.writerValidated.get(w)),
    not(matchingClaim(w, phase, serial)) or s.writerGeneration.get(w) != generation,
    s' = { ...s, writerBorrow: s.writerBorrow.set(w, 0), writerToken: s.writerToken.set(w, 0) },
  }
  def canRotateWriter(w: int): bool = not(s.writerOpen.get(w)) and s.writerBorrow.get(w) == 0 and
    s.claimStage.get(w) != 0 and not(s.arrived.get(w)) and s.writerGeneration.get(w) < generationCeiling
  action rotateWriter(w: int): bool = all { canRotateWriter(w),
    s' = { ...s, writerGeneration: s.writerGeneration.set(w, s.writerGeneration.get(w) + 1),
      writerOpen: s.writerOpen.set(w, true) } }
  def canRetireClaim(w: int): bool = all {
    not(s.queryOpen.get(w)), not(s.writerOpen.get(w)), s.claimReaders.get(w) == 0,
    s.writerBorrow.get(w) == 0, not(s.unsettled.get(w)), s.gateUseClosed.get(w),
    s.claimStage.get(w) == 7 or (s.claimStage.get(w) == 6 and s.work.get(s.claimItem.get(w)) == 6),
  }
  action retireClaim(w: int): bool = all { canRetireClaim(w),
    s' = { ...s, claimStage: s.claimStage.set(w, 0),
      writerGeneration: s.writerGeneration.set(w, 1) } }
  // Loss of owner knowledge grants no write, reclaim or replacement executor.
  action observeUnknownOwner(w: int): bool = all { s.unsettled.get(w), s' = s }
  def canFinishScan(o: int): bool = all {
    not(s.done), s.work.get(o) == 5, s.active.get(s.owner.get(o)),
    not(s.unsettled.get(s.owner.get(o))),
  }
  action finishScan(o: int): bool = all {
    canFinishScan(o),
    // Scanning reveals an edge. Already discovered canonical work is retained.
    val target = if (o == 1) 2 else 1
    val fresh = s.work.get(target) == 0
    s' = { ...s,
      work: if (fresh) s.work.set(o, 6).set(target, 1) else s.work.set(o, 6),
      owner: if (fresh) s.owner.set(target, s.owner.get(o)) else s.owner },
  }
  def emptyFresh(w: int): bool = s.observation.get(w) == ConfirmedEmpty and
    s.observedQueue.get(w) == w and
    s.observedPhase.get(w) == s.phase and
    s.observedRevision.get(w) == s.queueRevision.get(w)
  def localDrainReady(w: int): bool = not(s.unsettled.get(w)) and emptyFresh(w) and
    localDrained(s.work, s.owner, Set(1, 2), Set(1, 2, 3, 4, 5), w)
  def canIdle(w: int): bool = not(s.done) and s.active.get(w) and
    (s.fault == 2 or localDrainReady(w))
  action idle(w: int): bool = all {
    canIdle(w),
    s' = { ...s, active: s.active.set(w, false),
      badIdle: s.badIdle or s.unsettled.get(w) or not(emptyFresh(w)) or
        not(localDrained(s.work, s.owner, Set(1, 2), Set(1, 2, 3, 4, 5), w)),
      count: s.count - 1, done: s.count == 1 },
  }
  action wake(w: int): bool = all {
    not(s.done), not(s.active.get(w)), s.count > 0,
    // C re-counts every nonterminal return, including a spurious wake.
    s' = { ...s, active: s.active.set(w, true), count: s.count + 1,
      observation: s.observation.set(w, Unobserved), observedRevision: s.observedRevision.set(w, -1) },
  }
  action arrive(w: int): bool = all {
    s.done or s.fault == 4, not(s.arrived.get(w)),
    s' = { ...s, arrived: s.arrived.set(w, true),
      queryOpen: s.queryOpen.set(w, false), writerOpen: s.writerOpen.set(w, false) },
  }
  def phaseClosed: bool = s.done and s.arrived.get(1) and s.arrived.get(2) and
    Set(1, 2).forall(w => not(s.unsettled.get(w)) and s.claimReaders.get(w) == 0 and
      s.heldGate.get(w) == 0 and not(s.queryOpen.get(w)) and not(s.writerOpen.get(w)) and s.writerBorrow.get(w) == 0)
  action nextPhase = all {
    s.phase == 0, s.arrived.get(1), s.arrived.get(2),
    Set(1, 2).forall(w => not(s.unsettled.get(w))),
    phaseClosed or s.fault == 4,
    s' = { ...initialState(s.fault), phase: 1,
      staleRead: s.staleRead, badIdle: s.badIdle,
      badPhase: s.badPhase or not(s.done) or
        Set(1, 2).exists(w => s.claimReaders.get(w) != 0 or s.heldGate.get(w) != 0) or
        Set(1, 2).exists(o => s.work.get(o) != 6) },
  }
  action finished = all {
    s.phase == 1, phaseClosed, s' = s,
  }
  action step = any {
    claim(1, 1), claim(1, 2), claim(2, 1), claim(2, 2),
    copyWord(1), copyWord(2), publish(1), publish(2),
    scanLocal(1, 1), scanLocal(1, 2), scanLocal(2, 1), scanLocal(2, 2),
    acquire(1, 1), acquire(1, 2), acquire(2, 1), acquire(2, 2),
    busyTake(1), busyTake(2), busyTakeFrom(1, 2), busyTakeFrom(2, 1),
    observeOwnEmpty(1), observeOwnEmpty(2),
    observeEmpty(1, 2), observeEmpty(2, 1),
    loseClaimOutcome(1, 1), loseClaimOutcome(1, 2), loseClaimOutcome(2, 1), loseClaimOutcome(2, 2),
    settleClaim(1, 1), settleClaim(1, 2), settleClaim(2, 1), settleClaim(2, 2),
    prepareTake(1, 1), prepareTake(1, 2), prepareTake(2, 1), prepareTake(2, 2),
    markPreparedClaim(1), markPreparedClaim(2), recordClaimMarked(1), recordClaimMarked(2),
    detachPreparedClaim(1), detachPreparedClaim(2), recordClaimDetached(1), recordClaimDetached(2),
    commitPreparedClaim(1), commitPreparedClaim(2), closeClaimGate(1), closeClaimGate(2),
    recordClaimGateClosed(1), recordClaimGateClosed(2),
    cancelUnclaimedIntent(1), cancelUnclaimedIntent(2), observeUnknownOwner(1), observeUnknownOwner(2),
    pinClaim(1, s.phase, s.claimSerial.get(1)), pinClaim(2, s.phase, s.claimSerial.get(2)),
    queryClaim(1, s.phase, s.claimSerial.get(1)), queryClaim(2, s.phase, s.claimSerial.get(2)),
    unpinClaim(1), unpinClaim(2),
    pinQueryStorage(1), pinQueryStorage(2), sealQuery(1), sealQuery(2),
    rejectQueryAdmission(1), rejectQueryAdmission(2),
    sealWriters(1), sealWriters(2), leaveWriter(1), leaveWriter(2), rotateWriter(1), rotateWriter(2),
    enterWriter(1, s.phase, s.claimSerial.get(1), s.writerGeneration.get(1)),
    enterWriter(2, s.phase, s.claimSerial.get(2), s.writerGeneration.get(2)), retireClaim(1), retireClaim(2),
    pinWriterAdmission(1), pinWriterAdmission(2),
    validateWriter(1, s.phase, s.claimSerial.get(1), s.writerGeneration.get(1)),
    validateWriter(2, s.phase, s.claimSerial.get(2), s.writerGeneration.get(2)),
    rejectWriter(1, s.phase, s.claimSerial.get(1), s.writerGeneration.get(1) - 1),
    rejectWriter(2, s.phase, s.claimSerial.get(2), s.writerGeneration.get(2) - 1),
    finishScan(1), finishScan(2), idle(1), idle(2), wake(1), wake(2),
    arrive(1), arrive(2), nextPhase, finished,
  }
  val publicationSafe = not(s.staleRead)
  val terminationSafe = not(s.done) or allWorkComplete(s.work, Set(1, 2), 6)
  val ownershipSafe = Set(1, 2).forall(o => s.scans.get(o) <= 1)
  val phaseSafe = not(s.badPhase)
  val counted = s.count == activeCount(s.active, Set(1, 2))
  val producerCoverage = producersCovered(s.work, s.owner, s.active,
    Set(1, 2), Set(1, 2, 3, 4, 5))
  val unsettledCustody = Set(1, 2).forall(w => all {
    s.unsettled.get(w) == Set(1, 2, 3, 4, 5).contains(s.claimStage.get(w)),
    not(s.unsettled.get(w)) or (s.active.get(w) and not(s.done)),
    if (s.claimStage.get(w) == 1)
      (s.work.get(s.claimItem.get(w)) == 4 and s.owner.get(s.claimItem.get(w)) == s.claimQueue.get(w)) or
      (s.work.get(s.claimItem.get(w)) == 3 and s.owner.get(s.claimItem.get(w)) == w)
    else if (s.claimStage.get(w) == 2)
      Set(3, 5).contains(s.work.get(s.claimItem.get(w))) and s.owner.get(s.claimItem.get(w)) == w
    else if (Set(3, 4, 5).contains(s.claimStage.get(w)))
      s.work.get(s.claimItem.get(w)) == 5 and s.owner.get(s.claimItem.get(w)) == w
    else true,
    if (Set(1, 2, 3).contains(s.claimStage.get(w)) or
      (s.claimStage.get(w) == 4 and not(s.gateUseClosed.get(w))))
      s.heldGate.get(s.claimQueue.get(w)) == w else true,
    if (Set(5, 6, 7).contains(s.claimStage.get(w))) s.gateUseClosed.get(w) else true,
  })
  val workExtractionEquivalent = all {
    terminationSafe == (not(s.done) or Set(1, 2).forall(o => s.work.get(o) == 6)),
    counted == (s.count == (if (s.active.get(1)) 1 else 0) +
                          (if (s.active.get(2)) 1 else 0)),
  }
  val slotGateSafe = Set(1, 2).forall(w => all {
    Set(0, 1).contains(s.claimReaders.get(w)), Set(0, 1).contains(s.writerBorrow.get(w)),
    if (s.writerBorrow.get(w) == 1 and s.writerValidated.get(w)) s.writerToken.get(w) == s.writerGeneration.get(w)
    else s.writerToken.get(w) == 0,
    s.writerBorrow.get(w) != 0 or not(s.writerValidated.get(w)),
  })
  val safe = publicationSafe and terminationSafe and ownershipSafe and phaseSafe and counted and producerCoverage and unsettledCustody and slotGateSafe and not(s.badIdle)

  // Source-adapter witnesses, not a pthread/weak-memory or worker-death model.
  // C idle must establish local ownership drain, not global FIFO emptiness.
  // Every unfinished item's queue/private custodian stays active. Unknown
  // stop cannot decrement that count; existing retirement models own last-use.
  run lastPublishBeforeIdleTest = initFixed.then(observeOwnEmpty(2)).then(idle(2))
    .then(claim(1, 1)).then(copyWord(1)).then(copyWord(1)).then(publish(1))
    .expect(safe and s.count == 1 and not(s.done) and s.work.get(1) == 4)
  run wakeClaimRetainsProducerTest = initFixed.then(observeOwnEmpty(2)).then(idle(2))
    .then(claim(1, 1)).then(copyWord(1)).then(copyWord(1)).then(publish(1))
    .then(wake(2)).then(acquire(1, 2)).then(observeOwnEmpty(1)).then(idle(1))
    .expect(safe and s.count == 1 and s.work.get(1) == 5 and not(s.done))
  run uncountedPrivateControlTest = initEarlyIdle.then(idle(2))
    .then(claim(1, 1)).then(idle(1))
    .expect(not(terminationSafe) and s.work.get(1) == 2)
  run earlyPublicationControlTest = initOld.then(claim(1, 1))
    .then(publish(1)).then(acquire(1, 2)).expect(not(publicationSafe))
  run earlyPhaseControlTest = initEarlyPhase.then(arrive(1)).then(arrive(2))
    .then(nextPhase).expect(not(phaseSafe))
  run localIdleWithForeignQueueTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(busyTakeFrom(2, 1))
    .then(observeOwnEmpty(2)).then(idle(2)).expect(safe and s.work.get(1) == 4 and s.count == 1)
  run spuriousWakeRecountsTest = initFixed.then(observeOwnEmpty(2)).then(idle(2)).then(wake(2))
    .expect(safe and s.count == 2 and s.work.get(1) == 1)
  // The fault explicitly omits localDrained. It witnesses the missing premise,
  // not a proven reachable C gate-holder schedule or a native failure.
  run busyOwnQueueCannotCertifyIdleControlTest = initEarlyIdle.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(busyTake(1)).then(idle(1))
    .expect(not(producerCoverage) and s.work.get(1) == 4 and s.count == 1)
  run phaseReopenRejectsOldPublisherTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(scanLocal(1, 1)).then(finishScan(1))
    .then(claim(2, 1)).then(copyWord(2)).then(copyWord(2))
    .then(scanLocal(2, 1)).then(finishScan(2))
    .then(observeOwnEmpty(1)).then(idle(1)).then(observeOwnEmpty(2)).then(idle(2))
    .then(arrive(1)).then(arrive(2)).then(nextPhase)
    .then(rejectLatePublication(0)).expect(safe and s.phase == 1 and s.count == 2
      and not(emptyFresh(1)) and not(emptyFresh(2)))
  run stalePublicationControlTest = initLatePublisher.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publishAt(1, 1))
    .expect(not(phaseSafe))
  run busyPreservesPublisherCustodyTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(busyTake(1))
    .expect(safe and s.observation.get(1) == Unobserved and s.owner.get(1) == 1
      and s.work.get(1) == 4 and s.active.get(1) and not(emptyFresh(1)))
  run confirmedEmptyIsNotPrivateDrainTest = initFixed.then(observeOwnEmpty(1))
    .expect(safe and emptyFresh(1) and not(localDrained(s.work, s.owner,
      Set(1, 2), Set(1, 2, 4, 5), 1)))
  run publicationRevokesEmptyTest = initFixed.then(observeOwnEmpty(1))
    .then(claim(1, 1)).then(copyWord(1)).then(copyWord(1)).then(publish(1))
    .expect(safe and s.observation.get(1) == ConfirmedEmpty and not(emptyFresh(1)))
  run acquiredDoesNotFinishTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(acquire(1, 2))
    .expect(safe and s.observation.get(2) == Acquired(1) and s.owner.get(1) == 2
      and s.work.get(1) == 5 and not(s.done))
  run unknownClaimRetainsUntilSettlementTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(loseClaimOutcome(1, 2))
    .expect(safe and s.unsettled.get(2) and s.owner.get(1) == 2 and s.count == 2
      and not(canIdle(2)) and not(canFinishScan(1)) and not(canObserve(2)))
    .then(settleClaim(1, 2)).expect(safe and not(s.unsettled.get(2))
      and s.observation.get(2) == Acquired(1) and s.scans.get(1) == 1)
  run busyRevokesEmptyWitnessTest = initFixed.then(observeOwnEmpty(2)).then(busyTake(2))
    .expect(safe and not(emptyFresh(2)) and s.observation.get(2) == Unobserved)
  run foreignEmptyCannotAuthorizeOwnIdleTest = initFixed.then(observeEmpty(2, 1))
    .expect(safe and s.observation.get(2) == ConfirmedEmpty and not(emptyFresh(2))
      and not(canIdle(2)))
  run ownerDrainThenPhaseCloseTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(busyTake(1))
    .expect(safe and not(localDrainReady(1)) and s.count == 2)
    .then(acquire(1, 2)).then(observeOwnEmpty(1)).then(idle(1))
    .then(finishScan(1)).then(claim(2, 2)).then(copyWord(2)).then(copyWord(2))
    .then(scanLocal(2, 2)).then(finishScan(2)).then(observeOwnEmpty(2)).then(idle(2))
    .then(arrive(1)).then(arrive(2)).expect(safe and phaseClosed)
    .then(nextPhase).expect(safe and s.phase == 1)
  run wakeRequiresDrainRefreshTest = initFixed.then(observeOwnEmpty(2))
    .then(idle(2)).then(wake(2)).expect(safe and not(localDrainReady(2)))
    .then(observeOwnEmpty(2)).then(idle(2)).expect(safe and s.count == 1)
  run unresolvedClaimPreventsClosureTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(loseClaimOutcome(1, 2))
    .then(observeOwnEmpty(1)).then(idle(1))
    .expect(safe and s.count == 1 and not(localDrainReady(2)) and not(phaseClosed))
  run partialStoresQueryWithoutReclaimTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(pinClaim(2, 0, 1)).then(queryClaim(2, 0, 1)).then(queryClaim(2, 0, 1))
    .expect(safe and s.scans.get(1) == 0 and s.owner.get(1) == 1)
    .then(markPreparedClaim(2)).then(queryClaim(2, 0, 1))
    .expect(safe and s.claimStage.get(2) == 1 and s.work.get(1) == 3 and not(canMarkPrepared(2)))
    .then(recordClaimMarked(2)).then(detachPreparedClaim(2)).then(queryClaim(2, 0, 1))
    .expect(safe and s.claimStage.get(2) == 2 and s.work.get(1) == 5 and not(canDetachPrepared(2)))
    .then(recordClaimDetached(2)).then(commitPreparedClaim(2)).then(closeClaimGate(2))
    .then(queryClaim(2, 0, 1))
    .expect(safe and s.claimStage.get(2) == 4 and s.gateUseClosed.get(2)
      and not(canSettleClaim(1, 2, 0, 1)))
    .then(recordClaimGateClosed(2)).then(queryClaim(2, 0, 1))
    .then(settleClaimAt(1, 2, 0, 1)).then(queryClaim(2, 0, 1)).then(queryClaim(2, 0, 1))
    .then(unpinClaim(2)).expect(safe and s.scans.get(1) == 1
      and claimView(2, 0, 1) == "delivered" and not(canSettleClaim(1, 2, 0, 1)))
  run unknownOwnerRetainsLinkedClaimTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(markPreparedClaim(2)).then(observeUnknownOwner(2))
    .then(pinClaim(2, 0, 1)).then(queryClaim(2, 0, 1)).then(unpinClaim(2))
    .expect(safe and s.heldGate.get(1) == 2 and s.work.get(1) == 3 and s.owner.get(1) == 2
      and s.count == 2 and not(canIdle(2)) and not(phaseClosed)
      and claimView(2, 0, 1) == "partial-pending")
  run committedBeforeReleaseCannotDeliverTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(markPreparedClaim(2)).then(recordClaimMarked(2)).then(detachPreparedClaim(2))
    .then(recordClaimDetached(2)).then(commitPreparedClaim(2))
    .then(pinClaim(2, 0, 1)).then(queryClaim(2, 0, 1)).then(unpinClaim(2))
    .expect(safe and claimView(2, 0, 1) == "committed-release-unconfirmed"
      and s.heldGate.get(1) == 2 and not(canSettleClaim(1, 2, 0, 1)))
  run receiptPinPreventsSlotReuseTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(acquire(1, 2)).then(finishScan(1))
    .then(claim(2, 2)).then(copyWord(2)).then(copyWord(2)).then(publish(2))
    .then(pinClaim(2, 0, 1)).then(queryClaim(2, 0, 1))
    .expect(safe and not(canStartTake(2, 2))).then(sealQuery(2)).then(sealWriters(2))
    .then(unpinClaim(2)).then(retireClaim(2)).then(acquire(2, 2))
    .expect(safe and s.claimSerial.get(2) == 2 and s.scans.get(2) == 1
      and claimView(2, 0, 1) == "not-current-observation" and not(canSettleClaim(2, 2, 0, 1)))
    .then(pinWriterAdmission(2)).expect(safe and not(writerAuthorized(2)))
    .then(rejectWriter(2, 0, 1, 1)).expect(safe and s.scans.get(2) == 1 and s.writerBorrow.get(2) == 0)
  run knownUnclaimedAbortPreservesPublisherTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(cancelUnclaimedIntent(2)).then(pinClaim(2, 0, 1)).then(queryClaim(2, 0, 1)).then(unpinClaim(2))
    .expect(safe and s.work.get(1) == 4 and s.owner.get(1) == 1 and s.scans.get(1) == 0
      and claimView(2, 0, 1) == "known-unclaimed-abort" and not(emptyFresh(2)))
  run pinBeforeIdentityBlocksRetireTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(acquire(1, 2)).then(finishScan(1))
    .then(pinQueryStorage(2)).then(sealQuery(2)).then(sealWriters(2))
    .expect(safe and not(canRetireClaim(2)) and not(canPinQueryStorage(2)))
    .then(unpinClaim(2)).then(retireClaim(2))
    .expect(safe and s.claimStage.get(2) == 0 and s.work.get(2) == 1)
  run sealedQueryRejectsLatePinTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(loseClaimOutcome(1, 2))
    .then(sealQuery(2)).expect(safe and not(canPinQueryStorage(2)) and s.claimReaders.get(2) == 0)
  run closedWritersDrainBeforeHelperTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(sealWriters(2)).expect(safe and s.writerBorrow.get(2) == 1 and not(canRotateWriter(2)))
    .then(leaveWriter(2)).then(rotateWriter(2))
    .expect(safe and not(canEnterWriter(2, 0, 1, 1)) and canEnterWriter(2, 0, 1, 2))
    .then(enterWriter(2, 0, 1, 2)).then(markPreparedClaim(2))
    .expect(safe and s.claimSerial.get(2) == 1 and s.scans.get(1) == 1)
  run interruptedHelperRetainsWriterTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(sealWriters(2)).then(leaveWriter(2)).then(rotateWriter(2)).then(enterWriter(2, 0, 1, 2))
    .then(markPreparedClaim(2)).then(sealWriters(2)).then(observeUnknownOwner(2))
    .expect(safe and s.writerBorrow.get(2) == 1 and not(canRotateWriter(2)))
    .then(leaveWriter(2)).then(rotateWriter(2))
    .expect(safe and not(canEnterWriter(2, 0, 1, 2)))
    .then(enterWriter(2, 0, 1, 3)).then(recordClaimMarked(2)).then(detachPreparedClaim(2))
    .expect(safe and s.scans.get(1) == 1 and s.claimSerial.get(2) == 1)
  run zeroPinsDoNotFinishClaimTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(acquire(1, 2))
    .then(sealQuery(2)).then(sealWriters(2))
    .expect(safe and not(canRetireClaim(2)) and s.work.get(1) == 5)
    .then(finishScan(1)).then(retireClaim(2)).expect(safe and s.work.get(2) == 1 and s.count == 2)
  run staleHelperPinnedBeforeValidationTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(sealWriters(2)).then(leaveWriter(2)).then(rotateWriter(2)).then(pinWriterAdmission(2))
    .expect(safe and not(writerAuthorized(2)) and not(canMarkPrepared(2)) and not(canRotateWriter(2)))
    .then(rejectWriter(2, 0, 1, 1)).expect(safe and s.writerBorrow.get(2) == 0 and s.scans.get(1) == 0)
  run validatedHelperUsesExistingClaimTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(sealWriters(2)).then(leaveWriter(2)).then(rotateWriter(2)).then(pinWriterAdmission(2))
    .then(validateWriter(2, 0, 1, 2)).then(markPreparedClaim(2))
    .expect(safe and s.claimSerial.get(2) == 1 and s.scans.get(1) == 1)
  run helperGenerationExhaustionRetainsTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(prepareTake(1, 2))
    .then(sealWriters(2)).then(leaveWriter(2)).then(rotateWriter(2)).then(sealWriters(2))
    .then(rotateWriter(2)).then(sealWriters(2))
    .expect(safe and s.writerGeneration.get(2) == generationCeiling and not(canRotateWriter(2))
      and s.unsettled.get(2) and s.heldGate.get(1) == 2 and s.count == 2)
  run operationGenerationExhaustionRefusesTest = initExhaustedSerial.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1))
    .expect(safe and not(canStartTake(1, 2)) and s.work.get(1) == 4 and s.owner.get(1) == 1)
  run fullQueryAdmissionPreservesBorrowTest = initFixed.then(claim(1, 1))
    .then(copyWord(1)).then(copyWord(1)).then(publish(1)).then(acquire(1, 2)).then(pinQueryStorage(2))
    .then(rejectQueryAdmission(2))
    .expect(safe and not(canPinQueryStorage(2)) and s.claimReaders.get(2) == 1
      and s.scans.get(1) == 1 and s.owner.get(1) == 2)
}
