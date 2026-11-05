module pipe_predicate_gc_participation {
  // Two protocol roles and two predicate classes, not native CPU limits.
  // One finite contender, truthful collective acknowledgements and atomic
  // root relocation are assumptions; unbounded-arrival starvation is excluded.
  type State = { kind: str, helper: bool, rooted: bool, syncOnly: bool,
    requested: bool, joined: Set[int], gcDone: bool, ownerHolds: bool,
    peerHolds: bool, peerDone: bool, epoch: int, peerReference: int,
    callbackUnderLock: bool }
  var s: State
  pure def initial(kind: str, helper: bool, rooted: bool, syncOnly: bool): State = {
    kind: kind, helper: helper, rooted: rooted, syncOnly: syncOnly,
    requested: false, joined: Set(), gcDone: false, ownerHolds: true,
    peerHolds: false, peerDone: false, epoch: 0, peerReference: 0,
    callbackUnderLock: false,
  }
  action initFixed = {
    nondet kind = Set("mutex", "condvar").oneOf()
    s' = initial(kind, true, true, true)
  }
  action initRaw = s' = initial("condvar", false, true, true)
  action initUnrooted = s' = initial("mutex", true, false, true)
  action initCallbacks = s' = initial("condvar", true, true, false)
  action requestGc = all {
    not(s.requested),
    s' = { ...s, requested: true, joined: Set(0) },
  }
  // The owner cannot release its predicate until collective GC returns.
  action joinPeer = all {
    s.requested, s.helper, not(s.joined.contains(1)),
    s' = { ...s, joined: s.joined.union(Set(1)),
      callbackUnderLock: not(s.syncOnly) and s.ownerHolds },
  }
  action collect = all {
    s.joined == Set(0, 1), not(s.gcDone),
    s' = { ...s, gcDone: true, epoch: s.epoch + 1,
      peerReference: if (s.rooted) s.epoch + 1 else s.peerReference },
  }
  action releaseOwner = all {
    s.gcDone, s.ownerHolds, s' = { ...s, ownerHolds: false },
  }
  action acquirePeer = all {
    not(s.ownerHolds), not(s.peerHolds), not(s.peerDone),
    s' = { ...s, peerHolds: true },
  }
  action releasePeer = all {
    s.peerHolds, s' = { ...s, peerHolds: false, peerDone: true },
  }
  val terminal = s.gcDone and not(s.ownerHolds) and s.peerDone
  action finished = all { terminal, s' = s }
  action step = any { requestGc, joinPeer, collect, releaseOwner,
    acquirePeer, releasePeer, finished }
  val progressPossible = terminal or not(s.requested) or
    (s.requested and s.helper and not(s.joined.contains(1))) or
    (s.joined == Set(0, 1) and not(s.gcDone)) or
    (s.gcDone and s.ownerHolds) or
    (not(s.ownerHolds) and not(s.peerHolds) and not(s.peerDone)) or s.peerHolds
  val exclusion = not(s.ownerHolds and s.peerHolds)
  val collective = s.gcDone implies s.joined == Set(0, 1)
  val references = (s.peerHolds or s.peerDone) implies s.peerReference == s.epoch
  val callbackExclusion = not(s.callbackUnderLock)
  val safe = exclusion and collective and references and
    not(s.callbackUnderLock) and progressPossible
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
