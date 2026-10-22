module gerbil_phase_readiness {
  import gerbil_phase_topology.* from "./gerbil_phase_topology"
  // Finite target protocol, not a Scheme/compiler implementation.
  type State = { phase: int -> int, output: int -> List[int],
    p: int, body: int, opt: int, fault: int, held: Set[int], executed: Set[int],
    session: int -> int, stable: bool, cancelled: bool,
    badOrder: bool, badReuse: bool, stalePublish: bool }
  var s: State
  pure def key(n: int, p: int, b: int, o: int): List[int] =
    if (n <= 2) List(p) else if (n <= 6) List(p, o)
    else if (n == 7) List(b) else List(p, b, o)
  pure def initial(p: int, b: int, o: int, fault: int): State = {
    phase: Nodes.mapBy(_ => 0), output: Nodes.mapBy(n => key(n, 0, 0, 0)),
    p: p, body: b, opt: o, fault: fault, held: Set(), executed: Set(),
    session: Nodes.mapBy(_ => -1), stable: true, cancelled: false,
    badOrder: false, badReuse: false, stalePublish: false }
  action init = s' = initial(1, 0, 0, 0)
  action initBody = s' = initial(0, 1, 0, 0)
  action initOpt = s' = initial(0, 0, 1, 0)
  action initNoChange = s' = initial(0, 0, 0, 0)
  action initBadReuse = s' = initial(1, 0, 0, 1)
  action initEarly = s' = initial(1, 0, 0, 2)
  action initStale = s' = initial(1, 0, 0, 3)
  action initRefund = s' = initial(1, 0, 0, 4)
  action initShared = s' = initial(1, 0, 0, 5)
  def ready(n: int): bool = deps(n).forall(d => s.phase.get(d) == 3)
  action reuse(n: int): bool = all {
    s.stable, not(s.cancelled), s.phase.get(n) == 0, ready(n),
    s.output.get(n) == key(n, s.p, s.body, s.opt) or s.fault == 1,
    s' = { ...s, phase: s.phase.set(n, 3),
      badReuse: s.badReuse or s.output.get(n) != key(n, s.p, s.body, s.opt) }
  }
  action start(n: int): bool = all {
    s.stable, not(s.cancelled), s.phase.get(n) == 0, s.held.size() < 2,
    ready(n) or (s.fault == 2 and n == 2 and s.phase.get(0) == 3),
    s.output.get(n) != key(n, s.p, s.body, s.opt),
    s' = { ...s, phase: s.phase.set(n, 1), held: s.held.union(Set(n)),
      executed: s.executed.union(Set(n)),
      session: if (n == 3 or n == 4)
        s.session.set(n, if (s.fault == 5) 0 else n) else s.session,
      badOrder: s.badOrder or not(ready(n)) }
  }
  action finish(n: int): bool = all { s.phase.get(n) == 1,
    s' = { ...s, phase: s.phase.set(n, 2), held: s.held.exclude(Set(n)) } }
  action publish(n: int): bool = all {
    s.phase.get(n) == 2, (s.stable and not(s.cancelled)) or s.fault == 3,
    s' = { ...s, phase: s.phase.set(n, 3),
      output: s.output.set(n, key(n, s.p, s.body, s.opt)),
      stalePublish: s.stalePublish or not(s.stable) or s.cancelled }
  }
  action cancel = all { not(s.cancelled),
    s' = { ...s, cancelled: true, held: if (s.fault == 4) Set() else s.held } }
  action invalidate = all { s.stable, s' = { ...s, stable: false } }
  action discard(n: int): bool = all {
    s.phase.get(n) == 2, not(s.stable) or s.cancelled,
    s' = { ...s, phase: s.phase.set(n, 4) }
  }
  def accounting = s.held == Nodes.filter(n => s.phase.get(n) == 1)
  def isolated = s.session.get(3) == -1 or s.session.get(4) == -1
    or s.session.get(3) != s.session.get(4)
  def safe = accounting and s.held.size() <= 2 and isolated
    and not(s.badOrder) and not(s.badReuse) and not(s.stalePublish)
  action step = any {
    nondet n = Nodes.oneOf()
    any { reuse(n), start(n), finish(n), publish(n), discard(n) },
    cancel, invalidate, s' = s
  }

  run noChangeTest = initNoChange.then(reuse(0)).then(reuse(1)).then(reuse(2)).then(reuse(3)).then(reuse(4)).then(reuse(5)).then(reuse(6)).then(reuse(7)).then(reuse(8)).expect(safe and s.executed.size() == 0)
  run phaseNeedsSupportTest = init.then(start(0)).then(finish(0)).then(publish(0))
    .expect(safe and not(ready(2)))
  run concurrentConsumersTest = init.then(start(0)).then(finish(0)).then(publish(0)).then(start(1)).then(finish(1)).then(publish(1)).then(start(2)).then(finish(2)).then(publish(2)).then(start(3)).then(start(4))
    .expect(safe and s.held == Set(3, 4) and s.phase.get(7) == 0)
  run bodyOnlyCutoffTest = initBody.then(reuse(0)).then(reuse(1)).then(reuse(2))
    .then(reuse(3)).then(reuse(4)).then(reuse(5)).then(reuse(6)).then(start(7))
    .expect(safe and s.executed == Set(7))
  run optimizerChangeTest = initOpt.then(reuse(0)).then(reuse(1)).then(reuse(2))
    .then(start(3)).then(start(4)).expect(safe and s.executed == Set(3, 4))
  run cancelRetainsCreditTest = init.then(start(0)).then(cancel)
    .expect(safe and s.held == Set(0))
  run physicalExitRefundTest = init.then(start(0)).then(cancel).then(finish(0)).then(discard(0))
    .expect(safe and s.held.size() == 0 and s.phase.get(0) == 4)
  run finishedNotPublishedTest = init.then(start(0)).then(finish(0))
    .expect(safe and s.phase.get(0) == 2 and not(ready(1)))
  run snapshotLossDiscardTest = init.then(start(0)).then(invalidate).then(finish(0)).then(discard(0))
    .expect(safe and s.phase.get(0) == 4)
  run ssiOnlyControlTest = initEarly.then(start(0)).then(finish(0)).then(publish(0)).then(start(2))
    .expect(not(safe) and s.badOrder)
  run forgedReuseControlTest = initBadReuse.then(reuse(0)).expect(not(safe) and s.badReuse)
  run stalePublicationControlTest = initStale.then(start(0)).then(finish(0)).then(invalidate).then(publish(0))
    .expect(not(safe) and s.stalePublish)
  run earlyRefundControlTest = initRefund.then(start(0)).then(cancel)
    .expect(not(safe) and not(accounting))
  run sharedContextControlTest = initShared.then(start(0)).then(finish(0)).then(publish(0)).then(start(1)).then(finish(1)).then(publish(1)).then(start(2)).then(finish(2)).then(publish(2)).then(start(3)).then(start(4))
    .expect(not(safe) and not(isolated))
  run pipelineOverlapTest = init.then(start(0)).then(finish(0)).then(publish(0)).then(start(1)).then(finish(1)).then(publish(1)).then(start(2)).then(finish(2)).then(publish(2)).then(start(3)).then(start(4)).then(finish(3)).then(publish(3)).then(start(5))
    .expect(safe and s.held == Set(4, 5))
  run completeMacroRequestTest = init.then(start(0)).then(finish(0)).then(publish(0)).then(start(1)).then(finish(1)).then(publish(1)).then(start(2)).then(finish(2)).then(publish(2)).then(start(3)).then(start(4)).then(finish(3)).then(publish(3)).then(start(5))
    .then(finish(5)).then(publish(5)).then(finish(4)).then(publish(4))
    .then(start(6)).then(finish(6)).then(publish(6)).then(reuse(7))
    .then(start(8)).then(finish(8)).then(publish(8))
    .expect(safe and s.executed == Set(0, 1, 2, 3, 4, 5, 6, 8)
      and Nodes.forall(n => s.phase.get(n) == 3))
  run completeBodyRequestTest = initBody.then(reuse(0)).then(reuse(1)).then(reuse(2)).then(reuse(3)).then(reuse(4)).then(reuse(5)).then(reuse(6)).then(start(7)).then(finish(7)).then(publish(7)).then(start(8)).then(finish(8)).then(publish(8))
    .expect(safe and s.executed == Set(7, 8)
      and Nodes.forall(n => s.phase.get(n) == 3))

}

