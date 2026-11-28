module retirement_carrier_handoff {
  // Mechanism experiment inspired by pinned Chez thread_gc lifetime and OCaml
  // term_sync rooting/unlock order. NOT their collector/FFI implementation.
  // root denotes an independent owner appropriate to the resource, not a
  // claim that a Scheme root keeps arbitrary C storage alive.
  type State = { policy: int, contextLive: bool, carrierLive: bool,
    independentOwner: bool, consumer: bool, locked: bool,
    resultPublished: bool, joinerReleased: bool, backref: bool }
  var s: State
  pure def initial(policy: int): State = {
    policy: policy, contextLive: true, carrierLive: true,
    independentOwner: true, consumer: true, locked: true,
    resultPublished: false, joinerReleased: false, backref: policy == 3 }
  action initFixed = s' = initial(0)
  action initFreeWithContext = s' = initial(1)
  action initDropOwnerBeforeUnlock = s' = initial(2)
  action initStaleBackreference = s' = initial(3)
  action initReleaseJoinerEarly = s' = initial(4)
  action publishResult = all { not(s.resultPublished),
    s' = { ...s, resultPublished: true } }
  action destroyContext = all {
    s.resultPublished, s.contextLive,
    s' = { ...s, contextLive: false,
      carrierLive: if (s.policy == 1) false else s.carrierLive } }
  action lastConsumer = all { s.consumer,
    s' = { ...s, consumer: false } }
  action unlockJoiners = all {
    s.resultPublished, s.locked, not(s.contextLive) or s.policy == 4,
    s' = { ...s, locked: false, joinerReleased: true } }
  action dropOwner = all {
    not(s.contextLive), not(s.consumer), s.independentOwner,
    not(s.locked) or s.policy == 2,
    s' = { ...s, independentOwner: false } }
  // Collection/reclamation is possible, not required, after the final owner.
  action finalizeCarrier = all {
    not(s.independentOwner), s.carrierLive,
    s' = { ...s, carrierLive: false } }
  val terminal = not(s.contextLive) and not(s.consumer) and
    not(s.locked) and not(s.independentOwner)
  action done = all { terminal, s' = s }
  action step = any { publishResult, destroyContext, lastConsumer,
    unlockJoiners, dropOwner, finalizeCarrier, done }
  val useHasStorage = not(s.consumer or s.locked) or s.carrierLive
  val releaseAfterTeardown = not(s.joinerReleased) or not(s.contextLive)
  val noDeadBackreference = not(s.consumer and not(s.contextLive)) or not(s.backref)
  val safe = useHasStorage and releaseAfterTeardown and noDeadBackreference
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
  run contextCanDieBeforeCarrier = initFixed.then(publishResult)
    .then(destroyContext)
    .expect(not(s.contextLive) and s.consumer and s.locked and s.carrierLive and safe)
    .then(lastConsumer).then(unlockJoiners).then(dropOwner)
    .expect(terminal and safe)
}
