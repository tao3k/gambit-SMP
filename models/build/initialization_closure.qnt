module initialization_closure {
  import initialization_parameters.* from "./initialization_parameters"
  val Consumers = 0.to(ConsumerCount - 1)
  val Gates = 0.to(GateCount - 1)
  val Nodes = 0.to(NodeCount - 1)
  type State = { gates: Set[int], status: int, instances: int, identity: int,
    generation: int, published: int, accepting: bool, pins: Set[int],
    work: Set[int], nextTicket: int, owner: int, calls: List[int],
    snapshotReady: bool, sharedWrite: bool, reclaimed: bool,
    reached: Set[int], expanded: Set[int] }
  var s: State
  pure def initial(gates: Set[int]): State = {
    gates: gates, status: 0, instances: 0, identity: 42,
    generation: 0, published: 0, accepting: false, pins: Set(),
    work: Set(), nextTicket: 0, owner: -1, calls: List(),
    snapshotReady: false, sharedWrite: false, reclaimed: false,
    reached: Nodes, expanded: Nodes }
  action init = s' = initial(Gates)
  action initActual = s' = { ...initial(if (ObservedClosure) Gates else Set()), reached: Set(0), expanded: Set() }
  action initPartial = s' = { ...initial(Gates), reached: Set(0), expanded: Set() }
  action initMissing = s' = initial(Gates.exclude(Set(6)))
  action beginInit = all { s.status == 0, s' = { ...s, status: 1, instances: 1 } }
  action completeInit = all { s.status == 1, s' = { ...s, status: 2 } }
  action failInit = all { s.status == 1, s' = { ...s, status: 3 } }
  action unknownInit = all { s.status == 1, s' = { ...s, status: 4 } }
  def knownCutClosed = s.reached == Nodes and s.expanded == Nodes
  action discover(n: int): bool = all { s.reached.contains(n), not(s.expanded.contains(n)),
    s' = { ...s, reached: s.reached.union(CallerDeps.get(n)), expanded: s.expanded.union(Set(n)) } }
  def freezeReady = s.status == 2 and s.gates == Gates and knownCutClosed and not(s.reclaimed)
  action publish = all { freezeReady, not(s.accepting), s.generation == s.published,
    s' = { ...s, accepting: true, snapshotReady: true } }
  action pin(c: int): bool = all { s.accepting, s.snapshotReady,
    s.published == s.generation, not(s.pins.contains(c)),
    s' = { ...s, pins: s.pins.union(Set(c)) } }
  // work is disjoint consumer work or immutable image access, not raw mutable macro invocation.
  action beginWork(c: int): bool = all { s.pins.contains(c),
    s' = { ...s, work: s.work.union(Set(c)) } }
  // Reference order is fixed before admission; unrestricted scheduler order is not proved equivalent.
  action enterOwner(c: int): bool = all { s.work.contains(c), s.owner == -1,
    c == s.nextTicket, s.status == 2,
    s' = { ...s, owner: c } }
  action returnOwner = all { s.owner != -1,
    s' = { ...s, calls: s.calls.append(s.owner), nextTicket: s.nextTicket + 1, owner: -1 } }
  action release(c: int): bool = all { s.pins.contains(c), s.owner != c,
    s' = { ...s, pins: s.pins.exclude(Set(c)), work: s.work.exclude(Set(c)) } }
  action revoke = s' = { ...s, accepting: false, generation: s.generation + 1 }
  action reclaim = all { not(s.accepting), s.pins == Set(), s.owner == -1,
    s' = { ...s, reclaimed: true, snapshotReady: false } }
  def safe = s.instances <= 1 and s.identity == 42 and not(s.sharedWrite)
    and (not(s.accepting) or freezeReady)
    and (not(s.reclaimed) or (s.pins == Set() and s.owner == -1))
    and s.work.subseteq(s.pins)
    and s.expanded.subseteq(s.reached)
    and s.expanded.forall(n => CallerDeps.get(n).subseteq(s.reached))
    and (s.owner == -1 or s.work.contains(s.owner))
    and s.calls == (if (s.nextTicket == 0) List() else if (s.nextTicket == 1) List(0) else List(0, 1))
  action step = any { beginInit, completeInit, failInit, unknownInit, publish,
    nondet n = Nodes.oneOf()
    discover(n),
    nondet c = Consumers.oneOf()
    any { pin(c), beginWork(c), enterOwner(c), release(c) },
    returnOwner, revoke, reclaim, s' = s }
  // Explicitly unsafe transitions retained only as negative controls.
  action bypassPublish = s' = { ...s, accepting: true, snapshotReady: true }
  action duplicateInstance = s' = { ...s, instances: s.instances + 1 }
  action rebaseInstance = s' = { ...s, identity: 43 }
  action rawWrite = s' = { ...s, sharedWrite: true }
  action earlyReclaim = s' = { ...s, reclaimed: true }
  action wrongOrder = s' = { ...s, calls: List(1), nextTicket: 1 }
  action omitReader = s' = { ...s, reached: s.reached.exclude(Set(ReaderBody)) }
  run partialCutDeniedTest = initPartial.then(beginInit).then(completeInit).expect(safe and not(freezeReady))
  run readerCycleDiscoveredTest = initPartial.then(discover(0)).then(discover(1)).then(discover(2)).then(discover(5))
    .then(discover(ReaderBody)).expect(safe and s.reached.contains(2) and s.expanded.contains(ReaderBody))
  run actualClosureDeniedTest = initActual.then(beginInit).then(completeInit).expect(safe and not(freezeReady))
  run successfulPublishTest = init.then(beginInit).then(completeInit).then(publish).expect(safe and s.accepting)
  run missingGateDeniedTest = initMissing.then(beginInit).then(completeInit).expect(safe and not(freezeReady))
  run failureRetainsInstanceTest = init.then(beginInit).then(failInit).expect(safe and s.instances == 1 and not(freezeReady))
  run unknownSetupDeniedTest = init.then(beginInit).then(unknownInit).expect(safe and not(freezeReady))
  run consumersParallelTest = init.then(beginInit).then(completeInit).then(publish)
    .then(pin(0)).then(pin(1)).then(beginWork(0)).then(beginWork(1)).expect(safe and s.work == Consumers)
  run ownerOrderedTest = init.then(beginInit).then(completeInit).then(publish)
    .then(pin(0)).then(pin(1)).then(beginWork(0)).then(beginWork(1))
    .then(enterOwner(0)).then(returnOwner).then(enterOwner(1)).then(returnOwner)
    .expect(safe and s.instances == 1 and s.calls == List(0, 1))
  run revocationRetainsPinsTest = init.then(beginInit).then(completeInit).then(publish)
    .then(pin(0)).then(revoke).expect(safe and s.pins.contains(0) and not(s.accepting))
  run drainThenReclaimTest = init.then(beginInit).then(completeInit).then(publish)
    .then(pin(0)).then(revoke).then(release(0)).then(reclaim).expect(safe and s.reclaimed)
  run incompletePublishControlTest = initMissing.then(beginInit).then(completeInit).then(bypassPublish).expect(not(safe))
  run failedPublishControlTest = init.then(beginInit).then(failInit).then(bypassPublish).expect(not(safe))
  run duplicateInstanceControlTest = init.then(beginInit).then(duplicateInstance).expect(not(safe))
  run reboundInstanceControlTest = init.then(beginInit).then(rebaseInstance).expect(not(safe))
  run rawMutationControlTest = init.then(beginInit).then(rawWrite).expect(not(safe))
  run reclaimPinnedControlTest = init.then(beginInit).then(completeInit).then(publish).then(pin(0)).then(earlyReclaim).expect(not(safe))
  run reorderedEffectControlTest = init.then(beginInit).then(completeInit).then(wrongOrder).expect(not(safe))
  run omittedReaderControlTest = init.then(beginInit).then(completeInit).then(omitReader).then(bypassPublish).expect(not(safe))
}
