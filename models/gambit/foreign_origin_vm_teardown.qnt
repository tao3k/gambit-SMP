module foreign_origin_vm_teardown {
  // Two semantic VMs, one potential call per VM; not native topology limits.
  val vms = Set(0, 1)
  type State = { policy: str, phase: str, gates: int -> int,
    calls: int -> int, count: int -> int, alive: Set[int],
    acquired: Set[int], scan: int, interruptsDisabled: bool,
    storageDestroyed: bool, prematurelyCommitted: bool }
  var s: State
  pure def initial(p: str): State = {
    policy: p, phase: "open", gates: Map(0 -> 0, 1 -> 0),
    calls: Map(0 -> 0, 1 -> 0), count: Map(0 -> 0, 1 -> 0),
    alive: vms, acquired: Set(), scan: 0, interruptsDisabled: false,
    storageDestroyed: false, prematurelyCommitted: false }
  action init = s' = initial("lease-transaction")
  action initPopulationOnly = s' = initial("population-only")
  action initEarlyCommit = s' = initial("early-commit")
  action enter(v: int): bool = all { s.calls.get(v) == 0,
    s' = if (s.gates.get(v) != 0 or not(s.alive.contains(v)))
      { ...s, calls: s.calls.set(v, 4) }
    else { ...s, calls: s.calls.set(v, 1), gates: s.gates.set(v, 2) } }
  action publish(v: int): bool = all { s.calls.get(v) == 1,
    s' = { ...s, calls: s.calls.set(v, 2), gates: s.gates.set(v, 0),
      count: s.count.set(v, 1) } }
  action returnFrame(v: int): bool = all { s.calls.get(v) == 2,
    s' = { ...s, calls: s.calls.set(v, 3) } }
  action release(v: int): bool = all { s.calls.get(v) == 3,
    s' = { ...s, calls: s.calls.set(v, 4), count: s.count.set(v, 0) } }
  action beginCleanup = all { s.phase == "open",
    s' = { ...s, phase: "closing", interruptsDisabled: s.policy == "early-commit" } }
  action closeNext = all { s.phase == "closing", s.scan < 2,
    s' = if (s.gates.get(s.scan) != 0)
      { ...s, phase: "rollback" }
    else { ...s, gates: s.gates.set(s.scan, 1),
      acquired: s.acquired.union(Set(s.scan)), scan: s.scan + 1 } }
  action validate = all { s.phase == "closing", s.scan == 2,
    // Each VM already has only P0 and no pending joins. That population is
    // deliberately not a substitute for a native-frame quiescence check.
    s' = if (s.policy != "population-only" and vms.exists(v => s.count.get(v) != 0))
      { ...s, phase: "rollback" }
    else { ...s, phase: "commit" } }
  action rollback = all { s.phase == "rollback",
    s' = { ...s, phase: "busy", gates: vms.mapBy(v =>
      if (s.acquired.contains(v)) 0 else s.gates.get(v)), acquired: Set(),
      prematurelyCommitted: s.interruptsDisabled } }
  action commit = all { s.phase == "commit",
    s' = { ...s, phase: "closed", interruptsDisabled: true,
      storageDestroyed: true, alive: Set() } }
  action callStep = {
    nondet v = vms.oneOf()
    any { enter(v), publish(v), returnFrame(v), release(v) }
  }
  val terminal = Set("busy", "closed").contains(s.phase) and
    vms.forall(v => s.calls.get(v) == 4)
  action observe = s' = s
  action finished = all { terminal, observe }
  action step = any { callStep, beginCleanup, closeNext, validate, rollback, commit, finished }
  val holders = vms.filter(v => s.calls.get(v) == 2 or s.calls.get(v) == 3)
  val safe = holders.subseteq(s.alive) and
    vms.forall(v => s.count.get(v) == (if (holders.contains(v)) 1 else 0)) and
    vms.forall(v => (s.gates.get(v) / 2 == (if (s.calls.get(v) == 1) 1 else 0))) and
    (not(s.interruptsDisabled) or s.phase == "closed") and
    (not(s.storageDestroyed) or holders.size() == 0) and not(s.prematurelyCommitted)
  val noStall = terminal or enabled(step)
  run childP0BusyTest = (s' = initial("lease-transaction"))
    .then(enter(1)).then(publish(1)).then(beginCleanup).then(closeNext).then(closeNext)
    .then(validate).then(rollback)
    .then(all { assert(safe), assert(s.phase == "busy"),
      assert(s.gates == Map(0 -> 0, 1 -> 0)), observe })
  run rootP0BusyTest = (s' = initial("lease-transaction"))
    .then(enter(0)).then(publish(0)).then(beginCleanup).then(closeNext).then(closeNext)
    .then(validate).then(rollback)
    .then(all { assert(safe), assert(s.phase == "busy"), observe })
  run partialCloseRollbackTest = (s' = initial("lease-transaction"))
    .then(beginCleanup).then(closeNext).then(enter(1)).then(closeNext).then(rollback)
    .then(all { assert(safe), assert(s.gates == Map(0 -> 0, 1 -> 2)), observe })
    .then(publish(1)).then(returnFrame(1)).then(release(1))
    .then(all { assert(safe), observe })
  run quiescentCommitTest = (s' = initial("lease-transaction"))
    .then(enter(0)).then(publish(0)).then(returnFrame(0)).then(release(0))
    .then(beginCleanup).then(closeNext).then(closeNext).then(validate).then(commit)
    .then(enter(1)).then(all { assert(safe), assert(s.storageDestroyed),
      assert(s.calls.get(1) == 4), observe })
}
