module vm_registry_cross_vm_progress {
  // Two independent VM owners, two resource-replacement cycles each. Old barrier
  // arrival and successful OS join are explicit assumptions, not proved here.
  // One bounded global signal request; SC atomics and external host ownership.
  // Reader 4 owns a replay lease; delivery/release is distinct from admission.
  // Incarnation labels are ghost identities, not C startup/scheduler epochs.
  type State = { phase: int -> int, epoch: int -> int, captured: int -> int,
    mutex: int, closed: bool, reader: int, badRead: bool, bypass: bool,
    drainReplay: bool, retireEarly: bool, keepVisible: bool,
    live: int -> Set[int], visible: int -> Set[int],
    capturedResources: int -> Set[int], retiring: int -> int }
  var s: State
  pure def initial(bypass: bool): State = {
    phase: Map(1 -> 0, 2 -> 0), epoch: Map(1 -> 0, 2 -> 0),
    captured: Map(1 -> 0, 2 -> 0), mutex: 0, closed: false,
    reader: 0, badRead: false, bypass: bypass, drainReplay: true,
    retireEarly: false, keepVisible: false,
    live: Map(1 -> Set(1, 2), 2 -> Set(1, 2)),
    visible: Map(1 -> Set(1), 2 -> Set(1)),
    capturedResources: Map(1 -> Set(), 2 -> Set()), retiring: Map(1 -> 0, 2 -> 0),
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  action initReplayDrainLost = s' = { ...initial(false), drainReplay: false }
  action initEarlyReclaim = s' = { ...initial(false), retireEarly: true }
  action initNoWithdrawal = s' = { ...initial(false), keepVisible: true }
  def at(id: int, stage: int): bool =
    s.phase.get(id) < 16 and s.phase.get(id) % 8 == stage
  action acquire(id: int): bool = all {
    at(id, 0), s.mutex == 0 or s.bypass,
    s.live.get(id).contains(s.epoch.get(id) + 2),
    s' = { ...s, mutex: id, phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  action prepare(id: int): bool = all {
    at(id, 0), not(s.live.get(id).contains(s.epoch.get(id) + 2)),
    s' = { ...s, live: s.live.set(id, s.live.get(id).union(Set(s.epoch.get(id) + 2))) },
  }
  action reclaimEarly(id: int): bool = all {
    s.retireEarly, at(id, 1), s.live.get(id).contains(s.epoch.get(id) + 1),
    s' = { ...s, live: s.live.set(id, s.live.get(id).exclude(Set(s.epoch.get(id) + 1))) },
  }
  action close(id: int): bool = all {
    at(id, 1), s.mutex == id,
    s' = { ...s, closed: true, phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  action drain(id: int): bool = all {
    at(id, 2), s.mutex == id, s.reader != 1,
    s.reader != 4 or not(s.drainReplay),
    s' = { ...s, phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  action publish(id: int): bool = all {
    at(id, 3), s.mutex == id,
    s' = { ...s, epoch: s.epoch.set(id, s.epoch.get(id) + 1),
      visible: s.visible.set(id, if (s.keepVisible)
        s.visible.get(id).union(Set(s.epoch.get(id) + 2)) else Set(s.epoch.get(id) + 2)),
      retiring: s.retiring.set(id, s.epoch.get(id) + 1),
      phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  action reopen(id: int): bool = all {
    at(id, 4), s.mutex == id,
    s' = { ...s, closed: false, phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  action unlock(id: int): bool = all {
    at(id, 5), s.mutex == id,
    s' = { ...s, mutex: 0, phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  // Another writer may close admission before replay. A failed replay attempt
  // leaves the pending request owned; it must not be counted as delivery.
  action replay(id: int): bool = all {
    at(id, 6),
    s' = { ...s, reader: if (s.reader == 2 and not(s.closed)) 4 else s.reader,
      captured: if (s.reader == 2 and not(s.closed)) s.epoch else s.captured,
      capturedResources: if (s.reader == 2 and not(s.closed)) s.visible else s.capturedResources,
      phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  action join(id: int): bool = all {
    at(id, 7),
    s' = { ...s, live: s.live.set(id, s.live.get(id).exclude(Set(s.retiring.get(id)))),
      phase: s.phase.set(id, s.phase.get(id) + 1) },
  }
  action request = all {
    s.reader == 0,
    s' = { ...s, reader: if (s.closed) 2 else 1, captured: s.epoch,
      capturedResources: s.visible },
  }
  def allLive(snapshot: int -> Set[int]): bool = Set(1, 2).forall(id =>
    snapshot.get(id).forall(generation => s.live.get(id).contains(generation)))
  action leave = all {
    s.reader == 1 or s.reader == 4,
    s' = { ...s, reader: 3,
      badRead: s.badRead or s.captured != s.epoch or not(allLive(s.capturedResources)) },
  }
  action flush = all {
    s.reader == 2, not(s.closed),
    s' = { ...s, reader: 4, captured: s.epoch, capturedResources: s.visible },
  }
  val terminal = s.phase.get(1) == 16 and s.phase.get(2) == 16 and s.reader == 3
  action finished = all { terminal, s' = s }
  action step = {
    nondet id = Set(1, 2).oneOf()
    any { prepare(id), acquire(id), reclaimEarly(id), close(id), drain(id), publish(id), reopen(id),
      unlock(id), replay(id), join(id), request, leave, flush, finished }
  }
  val ownerSafe = Set(1, 2).forall(id =>
    (s.phase.get(id) % 8 >= 1 and s.phase.get(id) % 8 <= 5)
      implies s.mutex == id)
  val resourceSafe = (s.closed or allLive(s.visible)) and
    ((s.reader == 1 or s.reader == 4) implies allLive(s.capturedResources))
  val visibleRetirementSafe = resourceSafe
  val safe = ownerSafe and resourceSafe and not(s.badRead) and
    ((s.reader == 1 or s.reader == 4) implies s.captured == s.epoch)
  val contract = safe and (terminal or enabled(step))
  // Every nonterminal transition advances a finite phase or reader state.
  // Weak fairness excludes infinite stuttering, not an OS latency guarantee.
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
  run writerBypassControlTest = initBypass.then(acquire(1)).then(acquire(2))
    .then(all { assert(not(ownerSafe)), s' = s })
  run readerDrainTest = init.then(request).then(acquire(1)).then(close(1))
    .then(leave).then(drain(1)).then(publish(1)).then(reopen(1))
    .then(unlock(1)).then(replay(1)).then(join(1))
    .then(all { assert(safe), assert(s.epoch.get(1) == 1), s' = s })
  run deferredReplayTest = init.then(acquire(1)).then(close(1)).then(request)
    .then(drain(1)).then(publish(1)).then(reopen(1)).then(unlock(1))
    .then(acquire(2)).then(close(2)).then(replay(1)).then(join(1))
    .then(all { assert(s.reader == 2), s' = s })
    .then(drain(2)).then(publish(2)).then(reopen(2)).then(unlock(2))
    .then(replay(2)).then(leave).then(join(2))
    .then(all { assert(s.reader == 3), assert(safe), s' = s })
  run replayDrainControlTest = initReplayDrainLost.then(acquire(1)).then(close(1))
    .then(request).then(drain(1)).then(publish(1)).then(reopen(1)).then(unlock(1))
    .then(replay(1)).then(acquire(2)).then(close(2)).then(drain(2)).then(publish(2))
    .then(all { assert(s.reader == 4), assert(not(safe)), s' = s })
  run replayLeaseDrainTest = init.then(acquire(1)).then(close(1)).then(request)
    .then(drain(1)).then(publish(1)).then(reopen(1)).then(unlock(1)).then(replay(1))
    .then(acquire(2)).then(close(2))
    .then(all { assert(s.reader == 4), assert(safe), s' = s })
    .then(leave).then(drain(2)).then(publish(2)).then(reopen(2)).then(unlock(2))
    .then(replay(2)).then(join(2)).then(join(1))
    .then(all { assert(s.reader == 3), assert(safe), s' = s })
  run earlyReclaimControlTest = initEarlyReclaim.then(acquire(1)).then(reclaimEarly(1))
    .then(all { assert(not(resourceSafe)), s' = s })
  run withdrawalControlTest = initNoWithdrawal.then(acquire(1)).then(close(1)).then(request)
    .then(drain(1)).then(publish(1)).then(reopen(1)).then(unlock(1)).then(replay(1))
    .then(join(1)).then(all { assert(s.reader == 4), assert(not(resourceSafe)), s' = s })
  run postPublicationRetirementTest = init.then(acquire(1)).then(close(1)).then(request)
    .then(drain(1)).then(publish(1)).then(reopen(1)).then(unlock(1)).then(replay(1))
    .then(join(1)).then(all { assert(s.reader == 4), assert(safe),
      assert(not(s.live.get(1).contains(1))), assert(s.capturedResources.get(1) == Set(2)), s' = s })
    .then(leave).then(all { assert(safe), s' = s })
}
