module predicate_lock_retry_rooting {
  // A bounded owner and waiter, not a native processor-count constraint.
  // CAS atomicity, accurate GC roots and finite contenders remain premises.
  type State = { helper: bool, spill: bool, phase: str, requested: bool,
    joined: Set[int], ownerHolds: bool, peerHolds: bool, gcDone: bool,
    epoch: int, reference: int, stackRoot: int, invalidAccess: bool }
  var s: State
  pure def initial(helper: bool, spill: bool): State = {
    helper: helper, spill: spill, phase: "probe", requested: false,
    joined: Set(), ownerHolds: true, peerHolds: false, gcDone: false,
    epoch: 0, reference: 0, stackRoot: 0, invalidAccess: false,
  }
  action initFixed = s' = initial(true, true)
  action initRaw = s' = initial(false, true)
  action initUnrooted = s' = initial(true, false)
  action requestGc = all {
    not(s.requested),
    s' = { ...s, requested: true, joined: Set(0) },
  }
  action tryAcquire = all {
    s.phase == "probe",
    s' = if (s.reference != s.epoch)
      { ...s, phase: "invalid", invalidAccess: true }
    else if (s.ownerHolds)
      { ...s, phase: "wait" }
    else
      { ...s, phase: "held", peerHolds: true },
  }
  action retry = all {
    s.phase == "wait", not(s.requested) or s.gcDone,
    s' = { ...s, phase: "probe" },
  }
  action joinPeer = all {
    s.phase == "wait", s.requested, not(s.gcDone), s.helper,
    s' = { ...s, phase: "sync", stackRoot: s.reference,
      joined: s.joined.union(Set(1)) },
  }
  action collect = all {
    s.phase == "sync", s.joined == Set(0, 1), not(s.gcDone),
    s' = { ...s, phase: "restore", gcDone: true, epoch: 1,
      stackRoot: if (s.spill) 1 else s.stackRoot },
  }
  action restore = all {
    s.phase == "restore",
    s' = { ...s, phase: "probe", reference: s.stackRoot },
  }
  action releaseOwner = all {
    s.gcDone, s.ownerHolds, s' = { ...s, ownerHolds: false },
  }
  action releasePeer = all {
    s.phase == "held", s.peerHolds,
    s' = { ...s, phase: "done", peerHolds: false },
  }
  val terminal = s.phase == "done" and not(s.ownerHolds)
  action finished = all { terminal, s' = s }
  action step = any { requestGc, tryAcquire, retry, joinPeer, collect,
    restore, releaseOwner, releasePeer, finished }
  val references = not(s.invalidAccess)
  val collective = s.gcDone implies s.joined == Set(0, 1)
  val exclusion = not(s.ownerHolds and s.peerHolds)
  // Raw ticket waiting cannot acknowledge the owner-requested collective.
  val participation = not(s.requested and not(s.gcDone) and
    s.phase == "wait" and not(s.helper))
  val safe = references and collective and exclusion and participation
  temporal completion = (weakFair(requestGc, Set(s)) and
    weakFair(tryAcquire, Set(s)) and weakFair(joinPeer, Set(s)) and
    weakFair(collect, Set(s)) and weakFair(restore, Set(s)) and
    weakFair(releaseOwner, Set(s)) and weakFair(retry, Set(s)) and
    weakFair(releasePeer, Set(s))).implies(eventually(terminal))
}
