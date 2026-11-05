module gerbil_session_closure {
  import gerbil_session_topology.* from "./gerbil_session_topology"
  val Sessions = Set(0, 1)
  val Domains = Set(0, 1, 2, 3, 4, 5)
  val Addresses = 0.to(15).union(Set(99))
  type State = { sealed: Set[int], census: bool, effects: bool,
    locations: int -> (int -> int), heap: int -> int,
    active: Set[int], done: Set[int], pins: Set[int], cancelled: Set[int],
    epoch: int, supportEpoch: int -> int, snapshot: int -> int,
    fault: int, evicted: bool, badAdmission: bool, badPublication: bool }
  var s: State
  pure def initial(census: bool, effects: bool, fault: int): State = {
    sealed: Required, census: census, effects: effects,
    locations: Sessions.mapBy(w => Domains.mapBy(d =>
      if (fault == 1 and w == 1 and d == 1) 1
      else if (fault == 6 and w == 1 and d == 3) 3 else w * 10 + d)),
    heap: Addresses.mapBy(_ => 0), active: Set(), done: Set(), pins: Set(),
    cancelled: Set(), epoch: 0, supportEpoch: Nodes.mapBy(_ => 0),
    snapshot: Sessions.mapBy(_ => -1), fault: fault, evicted: false,
    badAdmission: false, badPublication: false }
  // Qualified is a hypothetical complete-census premise, never a source receipt.
  action init = s' = initial(true, true, 0)
  action initActual = s' = initial(ObservedCensus, false, 0)
  action initEffects = s' = initial(true, false, 0)
  action initMissing = s' = { ...initial(true, true, 0), sealed: Required.exclude(Set(7)) }
  action initAlias = s' = initial(true, true, 1)
  action initMutable = s' = initial(true, true, 2)
  action initStale = s' = initial(true, true, 3)
  action initEarlyEvict = s' = initial(true, true, 4)
  action initLiftedQuote = s' = initial(true, true, 6)
  def separated = Domains.forall(a => Domains.forall(b =>
    s.locations.get(0).get(a) != s.locations.get(1).get(b)))
  def supportReady = Required.subseteq(s.sealed) and
    Required.forall(n => s.supportEpoch.get(n) == s.epoch) and not(s.evicted)
  def admitted = s.census and s.effects and separated and supportReady
  def canStart(w: int): bool = admitted and not(s.active.contains(w)) and not(s.done.contains(w))
  action start(w: int): bool = all {
    not(s.active.contains(w)), not(s.done.contains(w)),
    admitted or s.fault == 1 or s.fault == 6,
    s' = { ...s, active: s.active.union(Set(w)), pins: s.pins.union(Set(w)),
      snapshot: s.snapshot.set(w, s.epoch), badAdmission: s.badAdmission or not(admitted) }
  }
  action writeCell(w: int, d: int): bool = all {
    s.active.contains(w),
    s' = { ...s, heap: s.heap.set(s.locations.get(w).get(d),
      s.heap.get(s.locations.get(w).get(d)) + 1) }
  }
  action mutateShared = all { s.fault == 2, s.active.size() > 0,
    s' = { ...s, heap: s.heap.set(99, 1) } }
  action cancel(w: int): bool = all { s.active.contains(w),
    s' = { ...s, cancelled: s.cancelled.union(Set(w)) } }
  action finish(w: int): bool = all { s.active.contains(w),
    s' = { ...s, active: s.active.exclude(Set(w)), done: s.done.union(Set(w)) } }
  action release(w: int): bool = all { s.done.contains(w), s.pins.contains(w),
    s' = { ...s, pins: s.pins.exclude(Set(w)) } }
  action invalidate = s' = { ...s, epoch: s.epoch + 1 }
  action publish(w: int): bool = all {
    s.done.contains(w), not(s.cancelled.contains(w)),
    s.snapshot.get(w) == s.epoch or s.fault == 3,
    s' = { ...s, badPublication: s.badPublication or s.snapshot.get(w) != s.epoch }
  }
  action evict = all { s.pins.size() == 0 or s.fault == 4,
    s' = { ...s, evicted: true } }
  def safe = not(s.badAdmission) and not(s.badPublication) and s.heap.get(99) == 0
    and (not(s.evicted) or s.pins.size() == 0)
    and s.active.subseteq(s.pins)
  action step = any {
    nondet w = Sessions.oneOf()
    nondet d = Domains.oneOf()
    any { start(w), writeCell(w, d), cancel(w), finish(w), release(w), publish(w) },
    invalidate, evict, s' = s
  }
  run sourceCensusBlocksTest = initActual.expect(safe and not(canStart(0)))
  run unknownEffectsBlockTest = initEffects.expect(safe and not(canStart(0)))
  run missingSsxiBlocksTest = initMissing.expect(safe and not(canStart(0)))
  run emittedRuntimeExcludedTest = init.expect(safe and not(Required.contains(9)))
  run independentWritesTest = init.then(start(0)).then(start(1)).then(writeCell(0, 1))
    .expect(safe and s.heap.get(s.locations.get(1).get(1)) == 0)
  run oppositeOrderTest = init.then(start(0)).then(start(1))
    .then(writeCell(1, 1)).then(writeCell(0, 1))
    .expect(safe and s.heap.get(1) == 1 and s.heap.get(11) == 1)
  run cancellationPinsTest = init.then(start(0)).then(cancel(0))
    .expect(safe and s.active.contains(0) and s.pins.contains(0))
  run physicalExitStillPinsTest = init.then(start(0)).then(cancel(0)).then(finish(0))
    .expect(safe and s.pins.contains(0))
  run finalReleaseTest = init.then(start(0)).then(cancel(0)).then(finish(0))
    .then(release(0)).then(evict).expect(safe and s.evicted)
  run staleSupportBlocksNewSessionTest = init.then(invalidate)
    .expect(safe and not(canStart(0)))
  run sameEpochPublicationTest = init.then(start(0)).then(finish(0)).then(publish(0))
    .expect(safe and not(s.badPublication))
  run deepAliasControlTest = initAlias.then(start(0)).then(start(1)).then(writeCell(0, 1))
    .expect(not(safe) and s.heap.get(s.locations.get(1).get(1)) == 1)
  run mutableSharedControlTest = initMutable.then(start(0)).then(mutateShared)
    .expect(not(safe) and s.heap.get(99) == 1)
  run staleCommitControlTest = initStale.then(start(0)).then(invalidate).then(finish(0)).then(publish(0))
    .expect(not(safe) and s.badPublication)
  run pinnedEvictionControlTest = initEarlyEvict.then(start(0)).then(evict)
    .expect(not(safe) and s.pins.contains(0))
  run liftedSyntaxQuoteAliasControlTest = initLiftedQuote.then(start(0)).then(start(1))
    .then(writeCell(0, 3)).expect(not(safe) and s.heap.get(s.locations.get(1).get(3)) == 1)
}
