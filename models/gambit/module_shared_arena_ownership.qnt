module module_shared_arena_ownership {
  // Two distinct module roles, not a machine processor-count configuration.
  // No collection/reclamation occurs while a preparation owns its allocation.
  val modules = Set(0, 1)
  type State = { policy: int, cursor: int, owners: Set[int],
    phase: int -> int, snapshots: int -> int, allocations: int -> int,
    failures: Set[int] }
  var s: State
  pure def initial(policy: int, failures: Set[int]): State = {
    policy: policy, cursor: 0, owners: Set(),
    phase: Map(0 -> 0, 1 -> 0), snapshots: Map(0 -> -1, 1 -> -1),
    allocations: Map(0 -> -1, 1 -> -1), failures: failures,
  }
  action initFixed = {
    nondet failures = Set(Set(), Set(0), Set(1), Set(0, 1)).oneOf()
    s' = initial(0, failures)
  }
  action initPerModuleOnly = s' = initial(1, Set())
  action initCursorRollback = s' = initial(2, Set(0))
  action claim = {
    nondet id = modules.oneOf()
    all {
      s.phase.get(id) == 0,
      s.policy == 1 or s.owners.size() == 0,
      s' = { ...s, owners: s.owners.union(Set(id)),
        phase: s.phase.set(id, 1) },
    }
  }
  action readCursor = {
    nondet id = modules.oneOf()
    all {
      s.phase.get(id) == 1,
      s' = { ...s, snapshots: s.snapshots.set(id, s.cursor),
        phase: s.phase.set(id, 2) },
    }
  }
  action allocate = {
    nondet id = modules.oneOf()
    all {
      s.phase.get(id) == 2,
      s' = { ...s, cursor: s.snapshots.get(id) + 1,
        allocations: s.allocations.set(id, s.snapshots.get(id)),
        phase: s.phase.set(id, 3) },
    }
  }
  action publish = {
    nondet id = modules.oneOf()
    all {
      s.phase.get(id) == 3,
      s' = { ...s, owners: s.owners.exclude(Set(id)),
        cursor: if (s.policy == 2 and s.failures.contains(id))
          s.snapshots.get(id) else s.cursor,
        phase: s.phase.set(id, if (s.failures.contains(id)) 5 else 4) },
    }
  }
  val terminal = modules.forall(id => s.phase.get(id) >= 4)
  action finished = all { terminal, s' = s }
  action step = any { claim, readCursor, allocate, publish, finished }
  val disjointOwnership = s.allocations.get(0) < 0 or
    s.allocations.get(1) < 0 or s.allocations.get(0) != s.allocations.get(1)
  val retainedAllocation = modules.forall(id => s.allocations.get(id) < 0 or
    s.allocations.get(id) < s.cursor)
  val safe = disjointOwnership and retainedAllocation
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}
