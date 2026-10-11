module gc_epoch_work_bridge {
  // Two epochs, grow 1->2 or shrink 2->1, graph 1->2. Mutators are parked.
  // Queue publication is release/acquire; copy completion is abstracted by
  // root readiness. Faults are contract mutations, not demonstrated C bugs.
  type State = { fault: int, epoch: int, phase: int,
    members: Set[int], target: Set[int], participants: Set[int],
    parked: Set[int], roots: Set[int], ready: Set[int], active: Set[int],
    work: int -> int, owner: int -> int, ack: Set[int], previousAck: Set[int],
    prepared: Set[int], joined: Set[int], committed: bool, badEpoch: bool }
  var s: State
  val workers = Set(1, 2)
  pure def initialState(fault: int, grow: bool): State = {
    fault: fault, epoch: 1, phase: 0,
    members: if (grow) Set(1) else workers,
    target: if (grow) workers else Set(1),
    participants: if (grow) Set(1) else workers,
    parked: Set(), roots: Set(), ready: Set(), active: Set(),
    work: Map(1 -> 0, 2 -> 0), owner: Map(1 -> 0, 2 -> 0),
    ack: Set(), previousAck: Set(), prepared: Set(), joined: Set(),
    committed: false, badEpoch: false,
  }
  action initFixed = any { s' = initialState(0, true), s' = initialState(0, false) }
  action initEarlyRoots = any { s' = initialState(1, true), s' = initialState(1, false) }
  action initEarlyIdle = any { s' = initialState(2, true), s' = initialState(2, false) }
  action initEarlyPopulation = any { s' = initialState(3, true), s' = initialState(3, false) }
  action initStaleAck = any { s' = initialState(4, true), s' = initialState(4, false) }
  action park(w: int): bool = all {
    s.phase == 0, s.participants.contains(w), not(s.parked.contains(w)),
    s' = { ...s, parked: s.parked.union(Set(w)) },
  }
  action enterRoots = all {
    s.phase == 0, s.parked == s.participants, s' = { ...s, phase: 1 },
  }
  action root(w: int): bool = all {
    s.phase == 1, s.participants.contains(w), not(s.roots.contains(w)),
    s' = { ...s, roots: s.roots.union(Set(w)),
      work: s.work.set(w, 1), owner: s.owner.set(w, w) },
  }
  action completeRoot(w: int): bool = all {
    s.phase == 1, s.roots.contains(w), not(s.ready.contains(w)),
    s' = { ...s, ready: s.ready.union(Set(w)) },
  }
  action enterScan = all {
    s.phase == 1,
    s.ready == s.participants or (s.fault == 1 and s.roots.size() > 0),
    s' = { ...s, phase: 2, active: s.participants },
  }
  // 1 private, 2 queued, 3 scanning, 4 scanned. Scanning may create more work.
  action publish(o: int): bool = all {
    s.phase == 2, s.work.get(o) == 1, s.active.contains(s.owner.get(o)),
    s' = { ...s, work: s.work.set(o, 2) },
  }
  action scan(o: int, w: int): bool = all {
    s.phase == 2, s.active.contains(w),
    s.work.get(o) == 2 or (s.work.get(o) == 1 and s.owner.get(o) == w),
    s' = { ...s, work: s.work.set(o, 3), owner: s.owner.set(o, w) },
  }
  action finishScan(o: int): bool = all {
    s.phase == 2, s.work.get(o) == 3, s.active.contains(s.owner.get(o)),
    val discover = o == 1 and s.work.get(2) == 0
    s' = { ...s,
      work: if (discover) s.work.set(o, 4).set(2, 1) else s.work.set(o, 4),
      owner: if (discover) s.owner.set(2, s.owner.get(o)) else s.owner },
  }
  action idle(w: int): bool = all {
    s.phase == 2, s.active.contains(w),
    s.fault == 2 or workers.forall(o => s.work.get(o) != 2 and
      not(s.owner.get(o) == w and Set(1, 3).contains(s.work.get(o)))),
    s' = { ...s, active: s.active.exclude(Set(w)) },
  }
  action wake(w: int): bool = all {
    s.phase == 2, s.participants.contains(w), not(s.active.contains(w)),
    s.active.size() > 0, workers.exists(o => s.work.get(o) == 2),
    s' = { ...s, active: s.active.union(Set(w)) },
  }
  action closeWork = all {
    s.phase == 2, s.active.size() == 0, s' = { ...s, phase: 3 },
  }
  action acknowledge(w: int): bool = all {
    s.phase == 3, s.participants.contains(w), not(s.ack.contains(w)),
    s' = { ...s, ack: s.ack.union(Set(w)) },
  }
  action staleAcknowledge(w: int): bool = all {
    s.fault == 4, s.epoch == 2, s.phase == 3,
    s.participants.contains(w), s.previousAck.contains(w), not(s.ack.contains(w)),
    s' = { ...s, ack: s.ack.union(Set(w)), badEpoch: true },
  }
  action leaveGC = all {
    s.phase == 3, s.ack == s.participants,
    s' = { ...s, phase: if (s.epoch == 1) 4 else 5,
      previousAck: s.ack, prepared: s.members, joined: s.members.intersect(s.target) },
  }
  action prepare(w: int): bool = all {
    s.phase == 4, not(s.committed), s.target.contains(w), not(s.prepared.contains(w)),
    s' = { ...s, prepared: s.prepared.union(Set(w)) },
  }
  action commit = all {
    s.phase == 4, not(s.committed), s.target.subseteq(s.prepared),
    s' = { ...s, members: s.target, committed: true },
  }
  action earlyCommit = all {
    s.fault == 3, s.epoch == 1, s.phase == 2, s.members != s.target,
    s' = { ...s, members: s.target },
  }
  action join(w: int): bool = all {
    s.phase == 4, s.committed, s.members.contains(w), not(s.joined.contains(w)),
    s' = { ...s, joined: s.joined.union(Set(w)) },
  }
  action nextGC = all {
    s.phase == 4, s.committed, s.joined == s.members,
    s' = { ...s, epoch: 2, phase: 0, participants: s.members,
      parked: Set(), roots: Set(), ready: Set(), active: Set(), ack: Set(),
      work: Map(1 -> 0, 2 -> 0), owner: Map(1 -> 0, 2 -> 0) },
  }
  action finished = all { s.phase == 5, s' = s }
  action step = any {
    park(1), park(2), enterRoots, root(1), root(2), completeRoot(1), completeRoot(2),
    enterScan, publish(1), publish(2), scan(1, 1), scan(1, 2), scan(2, 1), scan(2, 2),
    finishScan(1), finishScan(2), idle(1), idle(2), wake(1), wake(2), closeWork,
    acknowledge(1), acknowledge(2), staleAcknowledge(1), staleAcknowledge(2), leaveGC,
    prepare(1), prepare(2), commit, earlyCommit, join(1), join(2), nextGC, finished,
  }
  val rootsSafe = not(Set(2, 3, 5).contains(s.phase)) or s.ready == s.participants
  val closureSafe = not(Set(3, 4, 5).contains(s.phase)) or
    workers.forall(o => s.work.get(o) == 4)
  val populationSafe = s.phase >= 4 or s.members == s.participants
  val epochSafe = not(s.badEpoch)
  val safe = rootsSafe and closureSafe and populationSafe and epochSafe
  temporal progress = always(s.phase == 5 or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(s.phase == 5))
}
