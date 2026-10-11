module gc_sync_membership {
  // Three possible processors; grow 2->3 or shrink 2->1. Resize invokes a
  // nested GC over the OLD population, then a post-resize GC over the new one.
  // Tree barriers, root-copy completion and thread setup are abstract actions;
  // condition variables, forwarding and allocation rollback are separate models.
  // Faults are injected controls, not identified bugs in current source.
  type State = { fault: int, members: Set[int], target: Set[int],
    prepared: Set[int], live: Set[int], parked: Set[int], joined: Set[int],
    gcMembers: Set[int], roots: Set[int], complete: Set[int],
    scanned: Set[int], finalAck: Set[int], gc: int, rounds: int,
    resize: int, badResume: bool }
  var s: State
  val processors = Set(0, 1, 2)
  pure def initialState(fault: int, population: int): State = {
    fault: fault, members: Set(0, 1),
    target: if (population == 3) Set(0, 1, 2) else Set(0),
    prepared: Set(0, 1), live: Set(0, 1), parked: Set(), joined: Set(),
    gcMembers: Set(), roots: Set(), complete: Set(), scanned: Set(),
    finalAck: Set(), gc: 0, rounds: 0, resize: 0, badResume: false,
  }
  action initOld = any { s' = initialState(1, 1), s' = initialState(1, 3) }
  action initEarlyScan = any { s' = initialState(2, 1), s' = initialState(2, 3) }
  action initTargetPopulation = any { s' = initialState(3, 1), s' = initialState(3, 3) }
  action initEarlyResume = any { s' = initialState(4, 1), s' = initialState(4, 3) }
  action initFixed = any { s' = initialState(0, 1), s' = initialState(0, 3) }

  action requestResize = all {
    s.resize == 0, s.gc == 0,
    s' = { ...s, resize: 1 },
  }
  action requestGC = all {
    s.gc == 0, (s.resize == 1 or s.resize == 4), s.rounds < 2,
    s' = { ...s, gc: 1,
      gcMembers: if (s.fault == 3 and s.resize == 1) s.target else s.members,
      roots: Set(), complete: Set(), scanned: Set(), finalAck: Set() },
  }
  action park(w: int): bool = all {
    s.gc == 1, s.gcMembers.contains(w), s.live.contains(w),
    not(s.parked.contains(w)),
    s' = { ...s, parked: s.parked.union(Set(w)) },
  }
  action enterRoots = all {
    s.gc == 1,
    s.gcMembers.subseteq(s.parked) or
      (s.fault == 1 and s.parked.size() > 0),
    s' = { ...s, gc: 2 },
  }
  action publishRoot(w: int): bool = all {
    s.gc == 2, s.gcMembers.contains(w), s.parked.contains(w),
    not(s.roots.contains(w)),
    s' = { ...s, roots: s.roots.union(Set(w)) },
  }
  action completeRoot(w: int): bool = all {
    s.gc == 2, s.roots.contains(w), not(s.complete.contains(w)),
    s' = { ...s, complete: s.complete.union(Set(w)) },
  }
  action enterScan = all {
    s.gc == 2,
    s.complete == s.gcMembers or (s.fault == 2 and s.roots.size() > 0),
    s' = { ...s, gc: 3 },
  }
  // This abstracts each participant's closure contract, NOT its graph scan.
  // gc_work_closure separately checks private/shared work closure.
  action finishScan(w: int): bool = all {
    s.gc == 3, s.gcMembers.contains(w), not(s.scanned.contains(w)),
    s' = { ...s, scanned: s.scanned.union(Set(w)) },
  }
  action enterFinalBarrier = all {
    s.gc == 3, s.scanned == s.gcMembers,
    s' = { ...s, gc: 4 },
  }
  action acknowledgeGC(w: int): bool = all {
    s.gc == 4, s.gcMembers.contains(w), not(s.finalAck.contains(w)),
    s' = { ...s, finalAck: s.finalAck.union(Set(w)) },
  }
  action leaveGC = all {
    s.gc == 4, s.finalAck == s.gcMembers,
    s' = { ...s, gc: 0, rounds: s.rounds + 1,
      resize: if (s.resize == 1) 2 else s.resize,
      parked: if (s.resize == 1) s.parked else Set() },
  }
  action prepare(w: int): bool = all {
    s.resize == 2, s.gc == 0, s.target.contains(w),
    not(s.prepared.contains(w)),
    s' = { ...s, prepared: s.prepared.union(Set(w)) },
  }
  // Corresponds to synchronized OP_SET_PROCESSOR_COUNT over old participants.
  action commitPopulation = all {
    s.resize == 2, s.gc == 0, s.target.subseteq(s.prepared),
    s.members.subseteq(s.parked),
    s' = { ...s, members: s.target, resize: 3 },
  }
  action retire(w: int): bool = all {
    s.resize == 3, not(s.members.contains(w)), s.live.contains(w),
    s' = { ...s, live: s.live.exclude(Set(w)),
      parked: s.parked.exclude(Set(w)), prepared: s.prepared.exclude(Set(w)) },
  }
  action start(w: int): bool = all {
    s.resize == 3, s.members.contains(w), s.prepared.contains(w),
    not(s.live.contains(w)),
    s' = { ...s, live: s.live.union(Set(w)), parked: s.parked.union(Set(w)) },
  }
  // A new thread enters execute_sync_op_loop before it may run its thunk.
  action joinResize(w: int): bool = all {
    s.resize == 3, s.members.contains(w), s.live.contains(w),
    s.parked.contains(w), not(s.joined.contains(w)),
    s' = { ...s, joined: s.joined.union(Set(w)) },
  }
  action resumeResize = all {
    s.resize == 3, s.live == s.members,
    s.joined == s.members or s.fault == 4,
    s' = { ...s, resize: 4, parked: Set(),
      badResume: s.badResume or s.joined != s.members },
  }
  action finished = all { s.resize == 4, s.gc == 0, s.rounds == 2, s' = s }
  action step = any {
    requestResize, requestGC, park(0), park(1), park(2), enterRoots,
    publishRoot(0), publishRoot(1), publishRoot(2),
    completeRoot(0), completeRoot(1), completeRoot(2), enterScan,
    finishScan(0), finishScan(1), finishScan(2), enterFinalBarrier,
    acknowledgeGC(0), acknowledgeGC(1), acknowledgeGC(2), leaveGC,
    prepare(0), prepare(1), prepare(2), commitPopulation,
    retire(0), retire(1), retire(2), start(0), start(1), start(2),
    joinResize(0), joinResize(1), joinResize(2), resumeResize, finished,
  }
  val quiescenceSafe = s.gc < 2 or s.live.subseteq(s.parked)
  val rootSafe = s.gc < 3 or s.complete == s.gcMembers
  val membershipSafe = s.gc == 0 or
    (s.gcMembers == s.members and s.gcMembers.subseteq(s.live))
  val startupSafe = not(s.badResume)
  val safe = quiescenceSafe and rootSafe and membershipSafe and startupSafe
}
