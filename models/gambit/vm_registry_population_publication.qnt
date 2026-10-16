module vm_registry_population_publication {
  // Three semantic slots distinguish grow/shrink/no-op, not a CPU limit.
  // Non-atomic count accesses require registry ordering, not just volatile.
  type State = { guarded: bool, target: int, count: int, prepared: Set[int],
    arrived: Set[int], owner: str, gate: bool, lease: bool, reader: str,
    snapshot: int, writes: int, badWrite: bool, badResource: bool }
  var s: State
  pure def initial(guarded: bool, target: int): State = {
    guarded: guarded, target: target, count: 2, prepared: Set(0, 1),
    arrived: Set(), owner: "collect", gate: true, lease: false,
    reader: "new", snapshot: 0, writes: 0, badWrite: false, badResource: false }
  action init = {
    nondet target = Set(1, 2, 3).oneOf()
    s' = initial(true, target)
  }
  action initGrowth = s' = initial(false, 3)
  action initNoop = s' = initial(false, 2)
  action arrive = {
    nondet p = Set(0, 1).oneOf()
    all { s.owner == "collect", not(s.arrived.contains(p)),
      s' = { ...s, arrived: s.arrived.union(Set(p)) } }
  }
  action prepare = all { s.owner == "collect", s.arrived == Set(0, 1),
    s.target == 3, not(s.prepared.contains(2)),
    s' = { ...s, prepared: s.prepared.union(Set(2)) } }
  action collected = all { s.owner == "collect", s.arrived == Set(0, 1),
    s.target <= s.prepared.size(),
    s' = if (s.guarded and s.target == s.count) { ...s, owner: "done" }
      else { ...s, owner: if (s.guarded or s.target < s.count) "close" else "publish" } }
  action enter = all { s.reader == "new", s.gate,
    s' = { ...s, reader: "snapshot", lease: true } }
  action snapshot = all { s.reader == "snapshot",
    s' = { ...s, reader: "leave", snapshot: s.count,
      badResource: s.badResource or s.count > s.prepared.size() } }
  action leave = all { s.reader == "leave",
    s' = { ...s, reader: "done", lease: false } }
  action close = all { s.owner == "close", s.arrived == Set(0, 1),
    s' = { ...s, gate: false, owner: "drain" } }
  action drain = all { s.owner == "drain", not(s.lease),
    s' = { ...s, owner: "publish" } }
  action publish = all { s.owner == "publish",
    s' = { ...s, count: s.target, writes: s.writes + 1,
      badWrite: s.badWrite or s.lease,
      owner: if (s.gate) "done" else "open" } }
  action reopen = all { s.owner == "open",
    s' = { ...s, gate: true, owner: "done" } }
  val terminal = s.owner == "done" and s.reader == "done"
  action finished = all { terminal, s' = s }
  action step = any { arrive, prepare, collected, enter, snapshot, leave,
    close, drain, publish, reopen, finished }
  val orderedAccess = not(s.badWrite)
  val preparedPublication = not(s.badResource) and s.count <= s.prepared.size()
  val noopNoWrite = not(s.guarded and s.target == 2) or s.writes == 0
  val safe = orderedAccess and preparedPublication and noopNoWrite
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}
