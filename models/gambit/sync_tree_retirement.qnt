module sync_tree_retirement {
  // Source tree: children 2*p+1 and 2*p+2; shrink retains a prefix.
  // Bounds 2..5 are verification sizes, never a machine thread setting.
  // Old upward reduction has finished; this models downward send completion.
  type State = { policy: str, population: int, target: int,
    edge: int -> str, received: Set[int], exited: Set[int],
    joined: Set[int], nextRound: Set[int], destroyed: Set[int] }
  var s: State
  pure def initial(policy: str, population: int, target: int): State = {
    policy: policy, population: population, target: target,
    edge: 1.to(population - 1).mapBy(_ => "absent"),
    received: Set(0), exited: Set(), joined: Set(), nextRound: Set(), destroyed: Set(),
  }
  // Separate init actions avoid Quint 0.33's shared-init conversion limitation.
  action initOld = {
    nondet population = 2.to(5).oneOf()
    nondet target = 1.to(population - 1).oneOf()
    s' = initial("child", population, target)
  }
  action initJoinOnly = {
    nondet population = 2.to(5).oneOf()
    nondet target = 1.to(population - 1).oneOf()
    s' = initial("join-only", population, target)
  }
  action initFixed = {
    nondet population = 2.to(5).oneOf()
    nondet target = 1.to(population - 1).oneOf()
    s' = initial("join-and-next-round", population, target)
  }
  val retired = s.target.to(s.population - 1)
  val retained = 0.to(s.target - 1)
  pure def parent(child: int): int = (child - 1) / 2
  def children(node: int): Set[int] =
    Set(2 * node + 1, 2 * node + 2).filter(c => c < s.population)
  def completed(node: int): bool = s.received.contains(node) and
    children(node).forall(c => s.edge.get(c) == "done")

  action publish = {
    nondet child = 1.to(s.population - 1).oneOf()
    val p = parent(child)
    all {
      s.received.contains(p), s.edge.get(child) == "absent",
      // The source calls child1 before child2, including unlock and signal.
      if (child == 2 * p + 1) true else s.edge.get(child - 1) == "done",
      s' = { ...s, edge: s.edge.set(child, "published") },
    }
  }
  action unlock = {
    nondet child = 1.to(s.population - 1).oneOf()
    all { s.edge.get(child) == "published",
      s' = { ...s, edge: s.edge.set(child, "unlocked") } }
  }
  action signal = {
    nondet child = 1.to(s.population - 1).oneOf()
    all { s.edge.get(child) == "unlocked",
      s' = { ...s, edge: s.edge.set(child, "done") } }
  }
  action receive = {
    nondet child = 1.to(s.population - 1).oneOf()
    all { s.edge.get(child) != "absent", not(s.received.contains(child)),
      s' = { ...s, received: s.received.union(Set(child)) } }
  }
  action exitChild = {
    nondet node = retired.oneOf()
    all { completed(node), not(s.exited.contains(node)),
      s' = { ...s, exited: s.exited.union(Set(node)),
        destroyed: if (s.policy == "child") s.destroyed.union(Set(node)) else s.destroyed } }
  }
  action joinChild = {
    nondet node = retired.oneOf()
    all { completed(0), s.exited.contains(node), not(s.joined.contains(node)),
      s' = { ...s, joined: s.joined.union(Set(node)) } }
  }
  action enterNextRound = {
    nondet node = retained.oneOf()
    all { completed(node), not(s.nextRound.contains(node)),
      node != 0 or retired.subseteq(s.joined),
      s' = { ...s, nextRound: s.nextRound.union(Set(node)) } }
  }
  action reclaim = all {
    s.policy != "child", retired.subseteq(s.joined),
    s.destroyed != retired,
    s.policy == "join-only" or retained.subseteq(s.nextRound),
    s' = { ...s, destroyed: retired },
  }
  val terminal = s.destroyed == retired and retired.subseteq(s.joined) and
    retained.subseteq(s.nextRound)
  action finished = all { terminal, s' = s }
  action step = any { publish, unlock, signal, receive, exitChild,
    joinChild, enterNextRound, reclaim, finished }
  val signalSafe = s.destroyed.forall(node => s.edge.get(node) == "done")
  val joinSafe = s.joined.subseteq(s.exited)
  val populationSafe = s.destroyed.intersect(retained) == Set()
  val safe = signalSafe and joinSafe and populationSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
