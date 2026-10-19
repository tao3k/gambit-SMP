module predicate_lock_retry_rooting {
  // A bounded owner and waiter, not a native processor-count constraint.
  // CAS atomicity, accurate GC roots and finite contenders remain premises.
  // Separate projection: service_sync_op can resize, throw or retire, not
  // only collect. No claim that a new C wait adapter already exists.
  // Registry acquisition here is non-reentrant; platform recursion differs.
  type Effects = { policy: int, phase: int, op: int, registryHeld: bool,
    metadataHeld: bool, temporary: bool, blocked: bool, error: int }
  pure def effectsInitial(policy: int, op: int): Effects = {
    policy: policy, phase: 0, op: op, registryHeld: policy == 1,
    metadataHeld: policy == 4, temporary: true, blocked: false, error: 0,
  }
  type State = { helper: bool, spill: bool, phase: str, requested: bool,
    joined: Set[int], ownerHolds: bool, peerHolds: bool, gcDone: bool,
    epoch: int, reference: int, stackRoot: int, invalidAccess: bool,
    effects: Effects }
  var s: State
  pure def initial(helper: bool, spill: bool): State = {
    helper: helper, spill: spill, phase: "probe", requested: false,
    joined: Set(), ownerHolds: true, peerHolds: false, gcDone: false,
    epoch: 0, reference: 0, stackRoot: 0, invalidAccess: false,
    effects: effectsInitial(0, 0),
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

  action initEffects = {
    nondet op = Set(0, 1, 2, 3).oneOf()
    s' = { ...initial(true, true), effects: effectsInitial(0, op) }
  }
  action initRegistryService = s' = { ...initial(true, true), effects: effectsInitial(1, 1) }
  action initResourceAcrossExit = s' = { ...initial(true, true), effects: effectsInitial(2, 3) }
  action initErasedServiceError = s' = { ...initial(true, true), effects: effectsInitial(3, 2) }
  action initMetadataService = s' = { ...initial(true, true), effects: effectsInitial(4, 0) }
  // Discharge only an owned non-Scheme temporary before the generic service.
  // Rooted Scheme activation remains a separate existing protocol premise.
  action prepareEffects = all {
    s.effects.phase == 0,
    s' = { ...s, effects: { ...s.effects, phase: 1,
      temporary: s.effects.policy == 2 } },
  }
  action dispatchEffects = all {
    s.effects.phase == 1,
    s' = { ...s, effects: { ...s.effects, phase: 2,
      blocked: s.effects.op == 1 and s.effects.registryHeld,
      error: if (s.effects.op == 2 and s.effects.policy != 3) 7 else 0 } },
  }
  // Exit may bypass C return-site cleanup; this action cannot repair leaks.
  action finishEffects = all {
    s.effects.phase == 2, not(s.effects.blocked),
    s' = { ...s, effects: { ...s.effects, phase: 3 } },
  }
  action effectsFinished = all { s.effects.phase == 3, s' = s }
  action effectsStep = any { prepareEffects, dispatchEffects, finishEffects, effectsFinished }
  val effectRegistrySafe = not(s.effects.blocked)
  val effectMetadataSafe = s.effects.phase == 0 or not(s.effects.metadataHeld)
  val effectOrderSafe = effectRegistrySafe and effectMetadataSafe
  val effectExitSafe = s.effects.phase != 3 or not(s.effects.temporary)
  val effectErrorSafe = s.effects.phase != 3 or s.effects.op != 2 or s.effects.error == 7
  val effectsSafe = effectOrderSafe and effectExitSafe and effectErrorSafe
  temporal effectsCompletion = weakFair(effectsStep, s).implies(eventually(s.effects.phase == 3))
}
