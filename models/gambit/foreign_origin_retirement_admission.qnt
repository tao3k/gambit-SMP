module foreign_origin_retirement_admission {
  // Semantic origins: 0 retained, 1 removed. These are not CPU capacity limits.
  val tokens = Set(0, 1)
  type State = { policy: str, phase: str, gate: int, alive: Set[int],
    generation: int -> int, origin: int -> int, captured: int -> int,
    call: int -> int, count: int -> int, faults: int -> int,
    errors: Set[int], markers: Set[int], badRejection: bool, badRelease: bool }
  var s: State
  pure def initial(policy: str, o0: int, o1: int, f0: int, f1: int): State = {
    policy: policy, phase: "open", gate: 0, alive: Set(0, 1),
    generation: Map(0 -> 0, 1 -> 0), origin: Map(0 -> o0, 1 -> o1),
    captured: Map(0 -> -1, 1 -> -1), call: Map(0 -> 0, 1 -> 0),
    count: Map(0 -> 0, 1 -> 0), faults: Map(0 -> f0, 1 -> f1),
    errors: Set(), markers: Set(), badRejection: false, badRelease: false }
  action init = {
    nondet o0 = Set(0, 1).oneOf()
    nondet o1 = Set(0, 1).oneOf()
    nondet f0 = Set(0, 1, 2).oneOf()
    nondet f1 = Set(0, 1, 2).oneOf()
    s' = initial("origin-gate", o0, o1, f0, f1)
  }
  action initSplit = s' = initial("split-admission", 1, 0, 0, 0)
  action initGlobalBan = s' = initial("global-ban", 0, 0, 0, 0)
  action initUncheckedGeneration = s' = initial("unchecked-generation", 1, 0, 0, 0)
  action lookup(t: int): bool = all { s.call.get(t) == 0,
    s' = { ...s, call: s.call.set(t, 1),
      captured: s.captured.set(t, s.generation.get(s.origin.get(t))) } }
  // A brief gate reservation covers generation validation and count publication.
  // No gate reader is retained across Scheme execution, conversion or GC.
  action reserve(t: int): bool = all { s.call.get(t) == 1,
    s' = if (s.gate % 2 == 1 and s.policy != "split-admission")
      { ...s, call: s.call.set(t, 6) }
    else { ...s, gate: s.gate + 2, call: s.call.set(t, 2) } }
  action publish(t: int): bool = all { s.call.get(t) == 2,
    s' = if (not(s.alive.contains(s.origin.get(t))) or
                 (s.captured.get(t) != s.generation.get(s.origin.get(t)) and
                   s.policy != "unchecked-generation"))
      { ...s, gate: s.gate - 2, call: s.call.set(t, 6) }
    else { ...s, gate: s.gate - 2, call: s.call.set(t, 3),
      count: s.count.set(s.origin.get(t), s.count.get(s.origin.get(t)) + 1) } }
  action allocate(t: int): bool = all { s.call.get(t) == 3,
    s' = if (s.faults.get(t) == 1)
      { ...s, call: s.call.set(t, 5), errors: s.errors.union(Set(t)) }
    else { ...s, call: s.call.set(t, 4), markers: s.markers.union(Set(t)) } }
  action outcome(t: int): bool = all { s.call.get(t) == 4,
    s' = { ...s, call: s.call.set(t, 5),
      errors: if (s.faults.get(t) == 2) s.errors.union(Set(t)) else s.errors } }
  action release(t: int): bool = all { s.call.get(t) == 5,
    s' = { ...s, call: s.call.set(t, 6), markers: s.markers.exclude(Set(t)),
      count: s.count.set(s.origin.get(t), s.count.get(s.origin.get(t)) - 1),
      badRelease: s.badRelease or
        s.captured.get(t) != s.generation.get(s.origin.get(t)) } }
  // CAS(0, CLOSED) either seals publication or returns busy; never waits inside
  // the collective for a callback which requires those same processors.
  action close = all { s.phase == "open",
    s' = if (s.gate == 0) { ...s, gate: 1, phase: "inspect" }
         else { ...s, phase: "busy" } }
  action inspect = all { s.phase == "inspect",
    s' = if (s.count.get(1) != 0)
      { ...s, phase: "busy", gate: 0 }
    else if (s.policy == "global-ban" and s.count.get(0) != 0)
      { ...s, phase: "busy", gate: 0, badRejection: true }
    else { ...s, phase: "retire" } }
  action retire = all { s.phase == "retire",
    s' = { ...s, alive: Set(0), phase: "shrunk", gate: 0 } }
  // Reuse is a separate lifecycle transaction, modeled as atomic here. The
  // registry/constructor protocol must refine that assumption before runtime use.
  action reuse = all { s.phase == "shrunk", s.gate == 0, s.count.get(1) == 0,
    s' = { ...s, alive: Set(0, 1), generation: s.generation.set(1, 1), phase: "reused" } }
  val terminal = Set("busy", "shrunk", "reused").contains(s.phase) and
    tokens.forall(t => s.call.get(t) == 6)
  action finished = all { terminal, s' = s }
  action callStep = {
    nondet t = tokens.oneOf()
    any { lookup(t), reserve(t), publish(t), allocate(t), outcome(t), release(t) }
  }
  action step = any { callStep, close, inspect, retire, reuse, finished }
  val holders = tokens.filter(t => Set(3, 4, 5).contains(s.call.get(t)))
  val exactCount = Set(0, 1).forall(p =>
    s.count.get(p) == holders.filter(t => s.origin.get(t) == p).size())
  val frameAlive = holders.forall(t => s.alive.contains(s.origin.get(t)) and
    s.captured.get(t) == s.generation.get(s.origin.get(t)))
  val gateExact = s.gate / 2 == tokens.filter(t => s.call.get(t) == 2).size()
  val closedPublication = s.gate % 2 == 0 or s.gate == 1
  val markerOwned = s.markers.subseteq(holders)
  val safe = exactCount and frameAlive and gateExact and closedPublication and
    markerOwned and not(s.badRejection) and not(s.badRelease)
  val noStall = terminal or enabled(step)
  action observe = s' = s
  run retainedOriginTest = (s' = initial("origin-gate", 0, 0, 0, 0))
    .then(lookup(0)).then(reserve(0)).then(publish(0)).then(allocate(0))
    .then(close).then(inspect).then(retire)
    .then(all { assert(safe), assert(s.call.get(0) == 4), observe })
  run removedOriginBusyTest = (s' = initial("origin-gate", 1, 0, 0, 0))
    .then(lookup(0)).then(reserve(0)).then(publish(0)).then(allocate(0))
    .then(close).then(inspect)
    .then(all { assert(safe), assert(s.phase == "busy"), observe })
  run allocationRollbackTest = (s' = initial("origin-gate", 1, 0, 1, 0))
    .then(lookup(0)).then(reserve(0)).then(publish(0)).then(allocate(0)).then(release(0))
    .then(close).then(inspect).then(retire)
    .then(all { assert(safe), assert(s.errors.contains(0)), observe })
  run unwindRollbackTest = (s' = initial("origin-gate", 1, 0, 2, 0))
    .then(lookup(0)).then(reserve(0)).then(publish(0)).then(allocate(0))
    .then(outcome(0)).then(release(0)).then(close).then(inspect).then(retire)
    .then(all { assert(safe), assert(s.errors.contains(0)), observe })
  run staleLookupRejectedTest = (s' = initial("origin-gate", 1, 0, 0, 0))
    .then(lookup(0)).then(close).then(inspect).then(retire).then(reuse)
    .then(reserve(0)).then(publish(0))
    .then(all { assert(safe), assert(s.call.get(0) == 6), observe })
  run twoOriginLeasesTest = (s' = initial("origin-gate", 1, 1, 0, 0))
    .then(lookup(0)).then(reserve(0)).then(publish(0)).then(allocate(0))
    .then(lookup(1)).then(reserve(1)).then(publish(1)).then(allocate(1))
    .then(outcome(1)).then(release(1))
    .then(all { assert(safe), assert(s.count.get(1) == 1), observe })
    .then(outcome(0)).then(release(0)).then(close).then(inspect).then(retire)
    .then(all { assert(safe), assert(s.count.get(1) == 0), observe })
}
