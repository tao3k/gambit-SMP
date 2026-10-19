module processor_interrupt_ticket {
  // Candidate source lock 651f18da, materialized under the retained reader
  // repair. Not the unmodified vendor tree. abandonment_gc_publication is a
  // different protocol and is not refined here.
  //
  // lib/setup.c:364 ___raise_high_level_interrupt_pstate reserves with
  // ___PRIMLOCK, splices the interrupt queue, ___PRIMUNLOCK, then
  // ___raise_interrupt_pstate(___INTR_OTHER). Reservation is
  // ___TICKETLOCK_LOCK2 (fetch-add of next, spin until current matches).
  // That loop does not read INTR_SYNC_OP. Trylock is a compare-and-swap of
  // next and is a different operation.
  //
  // lib/_thread.scm:1479 takes the processor ticket with
  // ##lock-processor-with-sync-participation! and lib/_thread.scm:1483
  // releases it before lib/_thread.scm:1496 calls
  // ##raise-high-level-interrupt. The C acquire is a new reservation.
  // ##lock-scheduler-object-with-sync-participation! (lib/_thread.scm:690)
  // calls ##sync-op-interrupt! only after a failed trylock, before it owns
  // the ticket. Rooting of the interrupt object across that retry is an
  // assumption of initOpen, not a discharged proof.
  //
  // lib/_thread.scm:2752 ##thread-check-devices! assumes the processor
  // ticket is already held and calls ##wait! (lib/_thread.scm:2657), which
  // blocks in ##os-condvar-select! without polling INTR_SYNC_OP.
  // lib/_thread.scm:3138 calls that body before the unlock at
  // lib/_thread.scm:3152. lib/_thread.scm:6426 is a second top-level
  // definition in the same enable-smp branch and reserves with
  // ##primitive-lock!. Which definition the retained image calls was not
  // observed.
  //
  // barrier_sync_op is the common wait. Callers of on_all_processors set
  // OP_GARBAGE_COLLECT, OP_VM_RESIZE, OP_PROCESSOR_STARTUP_READY,
  // OP_FDSET_RESIZE, OP_ACTLOG_START, OP_ACTLOG_STOP, and
  // OP_PROCESSOR_0_THROW_ERROR. The retained sample does not record sop.op.
  //
  // owner 0 means unidentified. owner 1 is only an illustration that the
  // scheduler-across-select holder is possible. saw* records the other
  // source-reachable holders and ops. claimedOwner/claimedOp are collapses
  // this run does not support. holderInBarrier is a hypothetical
  // holder-in-collective cycle, not the observed cause: the sampled spinner
  // is the raise acquire loop, and the sampled peers are in barrier_sync_op.

  type State = {
    phase: int,
    owner: int,
    op: int,
    raiser: int,
    peerIn: bool,
    holderInBarrier: bool,
    nested: bool,
    rooted: bool,
    claimedOwner: bool,
    claimedOp: bool,
    sawSched: bool,
    sawStartup: bool,
    sawOther: bool,
    sawDevices: bool,
    sawGc: bool,
    sawResize: bool,
    sawReady: bool,
    sawFdset: bool,
    sawActlog: bool,
    sawThrow: bool,
    sawCount: bool,
    published: bool,
    spinPolled: bool,
    trylockPolled: bool
  }

  pure def open(): State = {
    phase: 0, owner: 0, op: 0, raiser: 0, peerIn: false,
    holderInBarrier: false, nested: false, rooted: true,
    claimedOwner: false, claimedOp: false,
    sawSched: false, sawStartup: false, sawOther: false, sawDevices: false,
    sawGc: false, sawResize: false, sawReady: false, sawFdset: false,
    sawActlog: false, sawThrow: false, sawCount: false,
    published: false, spinPolled: false, trylockPolled: false
  }

  action initOpen = s' = open()

  pure def tick(s: State): State = {
    phase: s.phase + 1,
    owner: if (s.phase == 8) 1 else s.owner,
    op: 0,
    raiser: if (s.phase == 7) 1 else s.raiser,
    peerIn: s.peerIn or (s.phase == 6),
    holderInBarrier: false,
    nested: s.nested or (s.phase == 8),
    rooted: true,
    claimedOwner: false,
    claimedOp: false,
    sawSched: s.sawSched or (s.phase == 0),
    sawStartup: s.sawStartup or (s.phase == 1),
    sawOther: s.sawOther or (s.phase == 2),
    sawDevices: s.sawDevices or (s.phase == 3),
    sawGc: s.sawGc or (s.phase == 4),
    sawResize: s.sawResize or (s.phase == 4),
    sawReady: s.sawReady or (s.phase == 4),
    sawFdset: s.sawFdset or (s.phase == 4),
    sawActlog: s.sawActlog or (s.phase == 4),
    sawThrow: s.sawThrow or (s.phase == 4),
    sawCount: s.sawCount or (s.phase == 4),
    published: false,
    spinPolled: false,
    trylockPolled: s.trylockPolled or (s.phase == 5)
  }

  action advance = all { s.phase < 12, s' = tick(s) }
  val terminal = s.phase == 12
  action finished = all { terminal, s' = s }
  val forward = s.phase < 12
  action step = any { advance, finished }
  val live = terminal or forward

  val witnessed = s.sawSched and s.sawStartup and s.sawOther and s.sawDevices and
    s.sawGc and s.sawResize and s.sawReady and s.sawFdset and s.sawActlog and
    s.sawThrow and s.sawCount and s.trylockPolled and s.peerIn and
    (s.raiser == 1) and s.nested and (s.owner == 1) and (s.op == 0) and
    not(s.published) and not(s.holderInBarrier) and s.rooted and not(s.spinPolled)
  val terminalWitness = (not(terminal) or witnessed)
  val ownerUnclaimed = not(s.claimedOwner)
  val opUnclaimed = not(s.claimedOp) and (s.op == 0)
  val unclaimed = ownerUnclaimed and opUnclaimed
  val exclusive = not(s.nested) or (s.owner == 1)
  val rootSafe = s.rooted
  val publishAfterRelease = not(s.published) or ((s.owner == 0) and (s.raiser == 2))
  val cycleNotObserved = not(s.holderInBarrier and s.claimedOwner)
  val reservationBlind = not(s.spinPolled)
  val sampleSplit = not(s.raiser == 1 and s.peerIn and s.holderInBarrier)
  val safe = unclaimed and exclusive and rootSafe and publishAfterRelease and
    cycleNotObserved and reservationBlind and sampleSplit and terminalWitness and
    live and (live == enabled(step)) and
    (terminal implies (s.raiser == 1 and s.peerIn and not(s.claimedOwner)))
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))

  // Negative controls. Each initial state is already a bad collapse.
  // None of them is an established source fix.
  action initClaimGc = s' = { ...open(), phase: 12, claimedOp: true, op: 1,
    raiser: 1, peerIn: true, sawGc: true }
  action initClaimSched = s' = { ...open(), phase: 12, claimedOwner: true,
    owner: 1, raiser: 1, peerIn: true, sawSched: true }
  action initCycle = s' = { ...open(), phase: 12, holderInBarrier: true,
    claimedOwner: true, owner: 1, raiser: 1, peerIn: true }
  action initNestedGrant = s' = { ...open(), phase: 12, nested: true, owner: 2,
    sawDevices: true, sawSched: true }
  action initUnrooted = s' = { ...open(), phase: 12, rooted: false,
    trylockPolled: true }
  action initPublishHeld = s' = { ...open(), phase: 12, published: true,
    owner: 1, raiser: 2 }
  action initSpinPoll = s' = { ...open(), phase: 12, spinPolled: true, raiser: 1 }
}
