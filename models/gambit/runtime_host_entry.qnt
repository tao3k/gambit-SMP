module runtime_host_entry {
  // Experimental caller-ownership contract. Does not implement attachment.
  // Per-entry TLS and a lifetime lease are intentionally not execution rights.
  type Entry = { phase: int, target: int, tls: int, previous: int,
    registered: bool, lease: bool }
  type State = { policy: int, entries: int -> Entry, owners: int -> int }
  var s: State
  pure def entry(target: int, previous: int, registered: bool): Entry = {
    phase: 0, target: target, tls: previous, previous: previous,
    registered: registered, lease: false,
  }
  pure def initial(policy: int, sameProcessor: bool, a: bool, b: bool): State = {
    policy: policy,
    entries: Map(0 -> entry(0, 7, a),
      1 -> entry(if (sameProcessor) 0 else 1, 8, b)),
    owners: Map(0 -> -1, 1 -> -1),
  }
  action initFixed = {
    nondet same = Set(false, true).oneOf()
    nondet a = Set(false, true).oneOf()
    nondet b = Set(false, true).oneOf()
    s' = initial(0, same, a, b)
  }
  action initLeaseOnly = s' = initial(1, true, true, true)
  action initLostBinding = s' = initial(2, false, true, true)
  action initMissingRegistration = s' = initial(3, false, false, true)
  // A counterexample to universalSerialization is a legal parallel witness,
  // not a bad runtime execution or a failing ownership protocol.
  action initIndependentWitness = s' = initial(0, false, true, true)
  action bind(i: int): bool = {
    val e = s.entries.get(i)
    all {
      e.phase == 0,
      s' = { ...s, entries: s.entries.set(i,
        if (e.registered or s.policy == 3)
          { ...e, phase: 1, tls: e.target, lease: true }
        else { ...e, phase: 4 }) },
    }
  }
  action enter(i: int): bool = {
    val e = s.entries.get(i)
    all {
      e.phase == 1,
      s.policy == 1 or s.owners.get(e.target) == -1,
      s' = { ...s, entries: s.entries.set(i, { ...e, phase: 2 }),
        owners: if (s.policy == 1) s.owners else s.owners.set(e.target, i) },
    }
  }
  action leave(i: int): bool = {
    val e = s.entries.get(i)
    all {
      e.phase == 2,
      s' = { ...s, entries: s.entries.set(i, { ...e, phase: 3, lease: false }),
        owners: if (s.owners.get(e.target) == i)
          s.owners.set(e.target, -1) else s.owners },
    }
  }
  action restore(i: int): bool = {
    val e = s.entries.get(i)
    all {
      e.phase == 3,
      s' = { ...s, entries: s.entries.set(i, { ...e, phase: 4,
        tls: if (s.policy == 2) e.target else e.previous }) },
    }
  }
  val terminal = Set(0, 1).forall(i => s.entries.get(i).phase == 4)
  action finished = all { terminal, s' = s }
  action step = {
    nondet i = Set(0, 1).oneOf()
    any { bind(i), enter(i), leave(i), restore(i), finished }
  }
  val executionExclusive = not(s.entries.get(0).phase == 2 and
    s.entries.get(1).phase == 2 and
    s.entries.get(0).target == s.entries.get(1).target)
  val memberSafe = Set(0, 1).forall(i =>
    s.entries.get(i).phase != 2 or s.entries.get(i).registered)
  val ownerSafe = Set(0, 1).forall(i =>
    s.entries.get(i).phase != 2 or
      s.owners.get(s.entries.get(i).target) == i)
  val bindingRestored = Set(0, 1).forall(i =>
    s.entries.get(i).phase != 4 or
      s.entries.get(i).tls == s.entries.get(i).previous)
  val drained = not(terminal) or (s.owners.get(0) == -1 and
    s.owners.get(1) == -1 and Set(0, 1).forall(i => not(s.entries.get(i).lease)))
  val universalSerialization = not(s.entries.get(0).phase == 2 and
    s.entries.get(1).phase == 2)
  val safe = executionExclusive and memberSafe and ownerSafe and bindingRestored and drained
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}
