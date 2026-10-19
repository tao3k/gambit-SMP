module processor_interrupt_ticket {
  // Source correspondence for ##thread-intr-propagate!: failed trylock,
  // membership recheck, rooted payload publication, release, then notify
  // the target processor. Not the sampled owner, sop.op, or native acceptance.
  // The exported C enqueue still reserves if called; this positive run does not.
  // A holder entering a collective while holding a ticket is a premise here.
  // Relocation is atomic. The processor object is ___PERM; the payload can move.
  // Caller ps is not the target. One queue operation, two roles, one collective.
  type State = {
    strategy: int, rooted: bool, repeat: bool, early: bool, op: str,
    member: bool, stalePublish: bool, localDone: bool,
    next: int, current: int, ticket: int,
    ownerHolds: bool, waiterHolds: bool, requested: bool,
    ownerIn: bool, waiterIn: bool, collectiveDone: bool,
    epoch: int, payloadEpoch: int,
    published: bool, released: bool, notified: bool, staleAccess: bool
  }
  var s: State
  pure def initial(strategy: int, rooted: bool, repeat: bool,
                   early: bool, op: str, member: bool,
                   stalePublish: bool): State = {
    strategy: strategy, rooted: rooted, repeat: repeat, early: early, op: op,
    member: member, stalePublish: stalePublish, localDone: false,
    next: 0, current: 0, ticket: -1,
    ownerHolds: false, waiterHolds: false, requested: false,
    ownerIn: false, waiterIn: false, collectiveDone: false,
    epoch: 0, payloadEpoch: 0,
    published: false, released: false, notified: false, staleAccess: false
  }
  // 0 is the raw C reservation. 1 is served-ticket polling, retained only
  // as a negative-control strategy. 2 is the Scheme failed-trylock repair.
  action initParticipating = {
    nondet op = Set("gc", "resize", "noop").oneOf()
    nondet member = Set(true, false).oneOf()
    s' = initial(2, true, false, false, op, member, false)
  }
  action initRaw = s' = initial(0, true, false, false, "gc", true, false)
  action initUnrooted = s' = initial(1, false, false, false, "gc", true, false)
  action initRereserve = s' = initial(1, true, true, false, "gc", true, false)
  action initEarlyNotify = s' = initial(2, true, false, true, "gc", true, false)
  action initUnmembered = s' = initial(2, true, false, false, "gc", false, true)
  action ownerAcquire = all {
    s.next == 0, s' = { ...s, next: 1, ownerHolds: true },
  }
  action reserve = all {
    s.strategy != 2, s.next == 1, s.ticket == -1, not(s.waiterIn),
    s' = { ...s, next: 2, ticket: 1 },
  }
  action requestCollective = all {
    s.ownerHolds, not(s.requested),
    s' = { ...s, requested: true, ownerIn: true },
  }
  action joinCollective = all {
    s.strategy != 0, s.requested, not(s.collectiveDone),
    not(s.waiterIn), not(s.waiterHolds),
    s' = { ...s, waiterIn: true },
  }
  action completeCollective = all {
    s.ownerIn, s.waiterIn, not(s.collectiveDone),
    val epoch = if (s.op == "gc") 1 else 0
    s' = { ...s, collectiveDone: true, ownerIn: false, waiterIn: false,
      epoch: epoch,
      payloadEpoch: if (s.rooted) epoch else s.payloadEpoch },
  }
  action ownerRelease = all {
    s.ownerHolds, not(s.requested) or s.collectiveDone,
    s' = { ...s, ownerHolds: false, current: 1 },
  }
  action acquireReserved = all {
    s.strategy != 2, s.ticket == s.current, s.ticket >= 0,
    not(s.waiterHolds), not(s.released), not(s.waiterIn),
    s' = { ...s, waiterHolds: true },
  }
  action tryAcquire = all {
    s.strategy == 2, s.member, s.next == 1, s.current == s.next,
    not(s.waiterIn), not(s.waiterHolds), not(s.localDone),
    s' = { ...s, next: 2, ticket: 1, waiterHolds: true },
  }
  action scheduleLocal = all {
    s.strategy == 2, not(s.member), not(s.stalePublish),
    not(s.waiterHolds), not(s.published), not(s.localDone),
    s' = { ...s, localDone: true },
  }
  action publishUnmembered = all {
    s.stalePublish, not(s.member), not(s.published), not(s.localDone),
    s' = { ...s, published: true, waiterHolds: true },
  }
  action rereserve = all {
    s.repeat, s.ticket == 1, s.current == 0, s.collectiveDone,
    s' = { ...s, next: 3, ticket: 2 },
  }
  action publish = all {
    s.waiterHolds, s.member, not(s.published), not(s.stalePublish),
    s' = { ...s, published: true,
      staleAccess: s.staleAccess or s.payloadEpoch != s.epoch },
  }
  action release = all {
    s.waiterHolds, s.published,
    s' = { ...s, waiterHolds: false, current: s.current + 1, released: true },
  }
  action notify = all {
    s.published, not(s.notified), s.released or s.early,
    s' = { ...s, notified: true },
  }
  val terminal = (s.member and s.released and s.notified) or s.localDone
  action protocol = any {
    ownerAcquire, reserve, requestCollective, joinCollective,
    completeCollective, ownerRelease, acquireReserved, tryAcquire,
    scheduleLocal, rereserve, publish, publishUnmembered, release, notify
  }
  action finished = all { terminal, s' = s }
  action step = any { protocol, finished }
  val exclusion = not(s.ownerHolds and s.waiterHolds)
  val referenceSafe = not(s.staleAccess)
  val reservationSafe = s.ticket <= 1
  val notificationSafe = s.notified implies (s.released or s.localDone)
  val collectiveSafe = s.collectiveDone implies s.requested
  val membershipSafe = s.published implies s.member
  val singleAcquire = not(s.ownerHolds and s.waiterHolds)
  val progressPossible = terminal or enabled(protocol)
  val safe = exclusion and referenceSafe and reservationSafe and
    notificationSafe and collectiveSafe and membershipSafe and
    singleAcquire and progressPossible
  temporal completion = weakFair(protocol, Set(s)).implies(eventually(terminal))
}
