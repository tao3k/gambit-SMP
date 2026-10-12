module eager_chain_work_closure {
  // Each chain object has one eager edge and one immediate tail field.
  // Cardinalities are finite exploration bounds, not runtime thread settings.
  type State = { policy: str, population: int, length: int,
    current: int, stage: int -> str, queued: Set[int], tailDone: Set[int],
    headDone: Set[int], scanner: int -> int, active: Set[int],
    producerReturned: bool, terminated: bool, weakStarted: bool, earlyPhase: bool }
  var s: State
  pure def initial(policy: str, population: int, chainLength: int): State = {
    policy: policy, population: population, length: chainLength, current: 1,
    stage: 1.to(chainLength).mapBy(i => if (i == 1) "reserved" else "undiscovered"),
    queued: Set(), tailDone: Set(), headDone: Set(),
    scanner: 0.to(population - 1).mapBy(_ => 0),
    active: 0.to(population - 1), producerReturned: false,
    terminated: false, weakStarted: false, earlyPhase: false,
  }
  action initOld = s' = initial("idle-on-export", 2, 2)
  action initEarlyPhase = s' = initial("early-weak-phase", 2, 2)
  action initFixed = {
    nondet population = 2.to(4).oneOf()
    nondet chainLength = 1.to(3).oneOf()
    s' = initial("count-until-return", population, chainLength)
  }
  val objects = 1.to(s.length)
  val workers = 0.to(s.population - 1)
  val copied = objects.filter(o => Set("copied", "published").contains(s.stage.get(o)))
  action copyCurrent = all {
    not(s.terminated), s.active.contains(0),
    s.stage.get(s.current) == "reserved",
    s' = { ...s, stage: s.stage.set(s.current, "copied") },
  }
  action exportCurrent = all {
    not(s.terminated), s.active.contains(0),
    s.stage.get(s.current) == "copied",
    s' = { ...s, stage: s.stage.set(s.current, "published"),
      queued: s.queued.union(Set(s.current)),
      active: if (s.policy == "idle-on-export") s.active.exclude(Set(0)) else s.active },
  }
  // Source goto-again can discover/copy another object after publishing this one.
  action markEager = all {
    not(s.terminated), s.active.contains(0),
    s.stage.get(s.current) == "published", not(s.headDone.contains(s.current)),
    val last = s.current == s.length
    s' = { ...s, headDone: s.headDone.union(Set(s.current)),
      stage: if (last) s.stage else s.stage.set(s.current + 1, "reserved"),
      current: if (last) s.current else s.current + 1,
      producerReturned: last },
  }
  action claimTail = {
    nondet worker = workers.oneOf()
    nondet object = objects.oneOf()
    all {
      not(s.terminated), s.active.contains(worker), s.scanner.get(worker) == 0,
      worker != 0 or s.producerReturned,
      s.queued.contains(object),
      s' = { ...s, queued: s.queued.exclude(Set(object)),
        scanner: s.scanner.set(worker, object) },
    }
  }
  action finishTail = {
    nondet worker = workers.oneOf()
    all { not(s.terminated), s.scanner.get(worker) != 0,
      s' = { ...s, tailDone: s.tailDone.union(Set(s.scanner.get(worker))),
        scanner: s.scanner.set(worker, 0) } }
  }
  action idle = {
    nondet worker = workers.oneOf()
    all {
      not(s.terminated), s.active.contains(worker), s.scanner.get(worker) == 0,
      s.queued == Set(), worker != 0 or s.producerReturned,
      s' = { ...s, active: s.active.exclude(Set(worker)) },
    }
  }
  action wake = {
    nondet worker = workers.oneOf()
    all { not(s.terminated), not(s.active.contains(worker)),
      s.active != Set(), s.queued != Set(),
      s' = { ...s, active: s.active.union(Set(worker)) } }
  }
  action terminate = all {
    not(s.terminated), s.active == Set(),
    s' = { ...s, terminated: true },
  }
  val closed = s.producerReturned and s.headDone == objects and s.tailDone == objects
    and s.queued == Set() and workers.forall(w => s.scanner.get(w) == 0)
  action beginWeak = all {
    not(s.weakStarted), s.terminated or s.policy == "early-weak-phase",
    s' = { ...s, weakStarted: true, earlyPhase: not(s.terminated) or not(closed) },
  }
  val terminal = s.weakStarted
  action finished = all { terminal, s' = s }
  action step = any { copyCurrent, exportCurrent, markEager, claimTail, finishTail,
    idle, wake, terminate, beginWeak, finished }
  val terminationSafe = not(s.terminated) or closed
  val phaseSafe = not(s.earlyPhase)
  val publicationSafe = s.queued.subseteq(copied) and s.tailDone.subseteq(copied)
    and workers.forall(w => s.scanner.get(w) == 0 or copied.contains(s.scanner.get(w)))
  val ownershipSafe = workers.forall(a => workers.forall(b =>
    a == b or s.scanner.get(a) == 0 or s.scanner.get(a) != s.scanner.get(b)))
  val activitySafe = workers.forall(w => s.scanner.get(w) == 0 or s.active.contains(w))
  val safe = terminationSafe and phaseSafe and publicationSafe and ownershipSafe and activitySafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
