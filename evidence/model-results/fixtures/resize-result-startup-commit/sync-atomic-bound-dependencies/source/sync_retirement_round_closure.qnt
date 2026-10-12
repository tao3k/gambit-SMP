module sync_retirement_round_closure {
  // Old-tree send tails and the following retained-tree upward convergence.
  // Bounds are exploration limits, not runtime processor limits.
  type State = { policy: str, population: int, target: int,
    edge: int -> str, received: Set[int], exited: Set[int], joined: Set[int],
    entered: Set[int], upward: Set[int], reclaimed: bool }
  var s: State
  pure def initial(policy: str, population: int, target: int): State = {
    policy: policy, population: population, target: target,
    edge: 1.to(population - 1).mapBy(_ => "absent"), received: Set(0),
    exited: Set(), joined: Set(), entered: Set(), upward: Set(), reclaimed: false,
  }
  action initOld = s' = initial("joins-only", 4, 2)
  action initFixed = {
    nondet population = 2.to(5).oneOf()
    nondet target = 1.to(population - 1).oneOf()
    s' = initial("upward-convergence", population, target)
  }
  val retired = s.target.to(s.population - 1)
  val retained = 0.to(s.target - 1)
  pure def parent(node: int): int = (node - 1) / 2
  def children(node: int, limit: int): Set[int] =
    Set(2 * node + 1, 2 * node + 2).filter(c => c < limit)
  def oldReturned(node: int): bool = s.received.contains(node) and
    children(node, s.population).forall(c => s.edge.get(c) == "done")
  action publishOld = {
    nondet child = 1.to(s.population - 1).oneOf()
    val p = parent(child)
    all {
      s.received.contains(p), s.edge.get(child) == "absent",
      if (child == 2 * p + 1) true else s.edge.get(child - 1) == "done",
      s' = { ...s, edge: s.edge.set(child, "published") },
    }
  }
  action unlockOld = {
    nondet child = 1.to(s.population - 1).oneOf()
    all { s.edge.get(child) == "published",
      s' = { ...s, edge: s.edge.set(child, "unlocked") } }
  }
  action signalOld = {
    nondet child = 1.to(s.population - 1).oneOf()
    all { s.edge.get(child) == "unlocked",
      s' = { ...s, edge: s.edge.set(child, "done") } }
  }
  action receiveOld = {
    nondet child = 1.to(s.population - 1).oneOf()
    all { s.edge.get(child) != "absent", not(s.received.contains(child)),
      s' = { ...s, received: s.received.union(Set(child)) } }
  }
  action exitWorker = {
    nondet node = retired.oneOf()
    all { oldReturned(node), not(s.exited.contains(node)),
      s' = { ...s, exited: s.exited.union(Set(node)) } }
  }
  action joinWorker = {
    nondet node = retired.oneOf()
    all { oldReturned(0), s.exited.contains(node), not(s.joined.contains(node)),
      s' = { ...s, joined: s.joined.union(Set(node)) } }
  }
  action enterOuter = {
    nondet node = retained.oneOf()
    all { oldReturned(node), not(s.entered.contains(node)),
      node != 0 or retired.subseteq(s.joined),
      s' = { ...s, entered: s.entered.union(Set(node)) } }
  }
  action publishUpward = {
    nondet node = retained.exclude(Set(0)).oneOf()
    all { s.entered.contains(node), not(s.upward.contains(node)),
      children(node, s.target).subseteq(s.upward),
      s' = { ...s, upward: s.upward.union(Set(node)) } }
  }
  val rootConverged = s.entered.contains(0) and children(0, s.target).subseteq(s.upward)
  action reclaim = all {
    not(s.reclaimed), retired.subseteq(s.joined),
    s.policy == "joins-only" or rootConverged,
    s' = { ...s, reclaimed: true },
  }
  val closure = not(rootConverged) or retained.forall(node => oldReturned(node))
  val safe = closure and (not(s.reclaimed) or (retired.subseteq(s.exited) and
    retired.forall(node => s.edge.get(node) == "done")))
  val terminal = s.reclaimed and rootConverged and retired.subseteq(s.joined)
  action finished = all { terminal, s' = s }
  action step = any { publishOld, unlockOld, signalOld, receiveOld,
    exitWorker, joinWorker, enterOuter, publishUpward, reclaim, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
