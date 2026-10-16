module foreign_origin_word_bounds {
  // Small semantic word width exposes wrap; not a native CPU or nesting limit.
  val tokens = Set(0, 1)
  var policy: str
  var gate: int
  var leases: int
  var calls: int -> int
  var closed: bool
  var removed: bool
  // Keep explicit initializer actions: Quint's TLA backend cannot share an
  // initializer action with the trajectory-test step context (QNT409).
  action init = all {
    policy' = "checked", gate' = 0, leases' = 0, calls' = Map(0 -> 0, 1 -> 0),
    closed' = false, removed' = false }
  action initGateWrap = all {
    policy' = "gate-wrap", gate' = 0, leases' = 0, calls' = Map(0 -> 0, 1 -> 0),
    closed' = false, removed' = false }
  action initLeaseWrap = all {
    policy' = "lease-wrap", gate' = 0, leases' = 0, calls' = Map(0 -> 0, 1 -> 0),
    closed' = false, removed' = false }
  action enter(t: int): bool = all { calls.get(t) == 0,
    if (closed or removed or (gate == 2 and policy != "gate-wrap"))
      all { calls' = calls.set(t, 4), gate' = gate }
    else all { calls' = calls.set(t, 1),
      gate' = if (policy == "gate-wrap") (gate + 2) % 4 else gate + 2 },
    policy' = policy, leases' = leases, closed' = closed, removed' = removed }
  action publish(t: int): bool = all { calls.get(t) == 1,
    if (leases == 1 and policy != "lease-wrap")
      all { calls' = calls.set(t, 4), leases' = leases }
    else all { calls' = calls.set(t, 2),
      leases' = if (policy == "lease-wrap") (leases + 1) % 2 else leases + 1 },
    gate' = gate - 2, policy' = policy, closed' = closed, removed' = removed }
  action returnFrame(t: int): bool = all { calls.get(t) == 2,
    calls' = calls.set(t, 3), gate' = gate, leases' = leases,
    policy' = policy, closed' = closed, removed' = removed }
  action release(t: int): bool = all { calls.get(t) == 3,
    calls' = calls.set(t, 4), leases' = leases - 1, gate' = gate,
    policy' = policy, closed' = closed, removed' = removed }
  action close = all { not(closed), not(removed), gate == 0,
    closed' = true, policy' = policy, gate' = gate,
    leases' = leases, calls' = calls, removed' = removed }
  action retire = all { closed, leases == 0,
    removed' = true, policy' = policy, gate' = gate,
    leases' = leases, calls' = calls, closed' = closed }
  action callStep = {
    nondet t = tokens.oneOf()
    any { enter(t), publish(t), returnFrame(t), release(t) }
  }
  val terminal = tokens.forall(t => calls.get(t) == 4) and (closed or removed)
  action observe = all { policy' = policy, gate' = gate, leases' = leases,
    calls' = calls, closed' = closed, removed' = removed }
  action finished = all { terminal, observe }
  action step = any { callStep, close, retire, finished }
  val holders = tokens.filter(t => calls.get(t) == 2 or calls.get(t) == 3)
  val safe = gate == 2 * tokens.filter(t => calls.get(t) == 1).size() and
    leases == holders.size() and gate >= 0 and gate <= 2 and
    leases >= 0 and leases <= 1 and (not(removed) or holders.size() == 0)
  val noStall = terminal or enabled(step)
  run gateSaturationTest = init.then(enter(0)).then(enter(1))
    .then(all { assert(safe), assert(calls.get(1) == 4), observe })
  run leaseSaturationTest = init.then(enter(0)).then(publish(0))
    .then(enter(1)).then(publish(1))
    .then(all { assert(safe), assert(calls.get(1) == 4), observe })
    .then(returnFrame(0)).then(release(0)).then(close).then(retire)
    .then(all { assert(safe), assert(removed), observe })
}
