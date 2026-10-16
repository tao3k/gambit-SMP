module sfun_allocation_unwind {
  // Two distinct processors, not a runtime worker count. No same-processor
  // concurrent mutators or full VM retirement protocol is represented here.
  val processors = Set(0, 1)
  type State = { policy: int, phase: int -> int, fault: int -> int,
    leases: int -> int, owned: Set[int], root: Set[int],
    catcher: int -> int, delivered: int -> int }
  var s: State
  pure def initial(policy: int, f0: int, f1: int): State = {
    policy: policy, phase: Map(0 -> 0, 1 -> 0),
    fault: Map(0 -> f0, 1 -> f1), leases: Map(0 -> 0, 1 -> 0),
    owned: Set(), root: Set(), catcher: Map(0 -> 0, 1 -> 0),
    delivered: Map(0 -> 0, 1 -> 0)
  }
  action init = {
    nondet a = Set(0, 1, 2).oneOf()
    nondet b = Set(0, 1, 2).oneOf()
    s' = initial(0, a, b)
  }
  action initRootLeak = s' = initial(1, 2, 0)
  action initLeaseLeak = s' = initial(2, 2, 0)
  action initWrongProcessor = s' = initial(3, 2, 0)
  action initEarlyRethrow = s' = initial(4, 2, 0)
  action enter = {
    nondet p = processors.oneOf()
    all { s.phase.get(p) == 0,
      s' = { ...s, phase: s.phase.set(p, 1),
        leases: s.leases.set(p, s.leases.get(p) + 1),
        owned: s.owned.union(Set(p)) } }
  }
  action protect = {
    nondet p = processors.oneOf()
    all { s.phase.get(p) == 1,
      s' = { ...s, phase: s.phase.set(p, 2), catcher: s.catcher.set(p, 1) } }
  }
  action saveRoot = {
    nondet p = processors.oneOf()
    all { s.phase.get(p) == 2,
      s' = { ...s, phase: s.phase.set(p, 3), root: s.root.union(Set(p)) } }
  }
  // 0: allocation succeeds; 1: ordinary error return; 2: nonlocal throw.
  // Both return paths execute GC_RESTORE1. Throw bypasses it.
  action allocate = {
    nondet p = processors.oneOf()
    all { s.phase.get(p) == 3,
      s' = { ...s, phase: s.phase.set(p, 4),
        root: if (s.fault.get(p) == 2) s.root else s.root.exclude(Set(p)) } }
  }
  action restoreCatcher = {
    nondet p = processors.oneOf()
    all { s.phase.get(p) == 4,
      s' = if (s.policy == 4 and s.fault.get(p) == 2)
        { ...s, phase: s.phase.set(p, 7), delivered: s.delivered.set(p, 2) }
      else { ...s, phase: s.phase.set(p, 5), catcher: s.catcher.set(p, 0) } }
  }
  action resolve = {
    nondet p = processors.oneOf()
    val q = if (s.policy == 3 and s.fault.get(p) == 2) 1-p else p
    val failed = s.fault.get(p) != 0
    val leak = s.policy == 2 and s.fault.get(p) == 2
    all { s.phase.get(p) == 5,
      s' = { ...s, phase: s.phase.set(p, 6),
        root: if (s.policy == 1 and s.fault.get(p) == 2) s.root else s.root.exclude(Set(p)),
        leases: if (failed and not(leak)) s.leases.set(q, s.leases.get(q)-1) else s.leases,
        owned: if (failed and not(leak)) s.owned.exclude(Set(p)) else s.owned } }
  }
  // Successful helper returns transfer the live lease to the wrapper. Model
  // wrapper completion separately; failed allocation must never reach it.
  action finish = {
    nondet p = processors.oneOf()
    all { s.phase.get(p) == 6,
      s' = { ...s, phase: s.phase.set(p, 7),
        leases: if (s.fault.get(p) == 0) s.leases.set(p, s.leases.get(p)-1) else s.leases,
        owned: if (s.fault.get(p) == 0) s.owned.exclude(Set(p)) else s.owned,
        delivered: s.delivered.set(p, s.fault.get(p)) } }
  }
  val terminal = processors.forall(p => s.phase.get(p) == 7)
  action hold = all { terminal, s'=s }
  action step = any { enter, protect, saveRoot, allocate, restoreCatcher, resolve, finish, hold }
  val countExact = processors.forall(p => s.leases.get(p) == (if (s.owned.contains(p)) 1 else 0))
  val catcherRestored = processors.forall(p => (s.phase.get(p) >= 5).implies(s.catcher.get(p) == 0))
  val rootsCleared = processors.forall(p => (s.phase.get(p) >= 6).implies(not(s.root.contains(p))))
  val errorsReleased = processors.forall(p =>
    (s.phase.get(p) >= 6 and s.fault.get(p) != 0).implies(not(s.owned.contains(p))))
  val delivered = processors.forall(p => (s.phase.get(p) == 7).implies(s.delivered.get(p) == s.fault.get(p)))
  val finalRelease = terminal.implies(s.owned.size() == 0)
  val safe = countExact and catcherRestored and rootsCleared and errorsReleased and delivered and finalRelease
}
