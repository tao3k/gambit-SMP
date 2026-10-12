module scan_barrier_quiescence {
  // Complete callback return is a premise; this is not GC payload tracing.
  type State = { policy: str, population: int, target: int,
    users: Set[int], returned: Set[int], upward: Set[int], destroyed: Set[int],
    resized: bool, nextGc: bool, badDestroy: bool, badAdmission: bool }
  var s: State
  pure def initial(policy: str, population: int, target: int): State = {
    policy: policy, population: population, target: target,
    users: 0.to(population - 1), returned: Set(), upward: Set(), destroyed: Set(),
    resized: false, nextGc: false, badDestroy: false, badAdmission: false,
  }
  action initLocal = s' = initial("local-return", 3, 1)
  action initEarlyAdmission = s' = initial("early-admission", 3, 1)
  action initFixed = {
    nondet population = 2.to(5).oneOf()
    nondet target = 1.to(population - 1).oneOf()
    s' = initial("fixed", population, target)
  }
  val processors = 0.to(s.population - 1)
  val retired = s.target.to(s.population - 1)
  val retained = 0.to(s.target - 1)
  pure def children(node: int, population: int): Set[int] =
    Set(node * 2 + 1, node * 2 + 2).filter(child => child < population)
  def queueUser(queue: int): bool = s.users.exists(user =>
    (user + 1) % (if (s.resized) s.target else s.population) == queue)
  action finishCallback = {
    nondet node = processors.oneOf()
    all { not(s.nextGc), s.users.contains(node),
      s' = { ...s, users: s.users.exclude(Set(node)), returned: s.returned.union(Set(node)) } }
  }
  action aggregateUpward = {
    nondet node = processors.oneOf()
    all { s.returned.contains(node), not(s.upward.contains(node)),
      children(node, s.population).subseteq(s.upward),
      s' = { ...s, upward: s.upward.union(Set(node)) } }
  }
  action changePopulation = all {
    not(s.resized), s.upward.contains(0),
    s' = { ...s, resized: true },
  }
  action cleanupRetired = {
    nondet node = retired.oneOf()
    all {
      not(s.destroyed.contains(node)),
      if (s.policy == "local-return") s.returned.contains(node) else s.resized,
      s' = { ...s, destroyed: s.destroyed.union(Set(node)),
        badDestroy: s.badDestroy or queueUser(node) },
    }
  }
  action beginNextGc = all {
    not(s.nextGc),
    if (s.policy == "early-admission") s.returned.contains(0)
      else s.resized and retired.subseteq(s.destroyed),
    s' = { ...s, nextGc: true,
      users: if (s.policy == "early-admission") processors else retained,
      badAdmission: s.policy == "early-admission" and not(s.resized) },
  }
  val terminal = s.nextGc and retired.subseteq(s.destroyed)
  action finished = all { terminal, s' = s }
  action step = any { finishCallback, aggregateUpward, changePopulation, cleanupRetired, beginNextGc, finished }
  val callbackClosure = not(s.upward.contains(0)) or processors.subseteq(s.returned)
  val destroySafe = not(s.badDestroy)
  val admissionSafe = not(s.badAdmission)
  val liveQueueSafe = s.destroyed.forall(queue => not(queueUser(queue)))
  val safe = callbackClosure and destroySafe and admissionSafe and liveQueueSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
