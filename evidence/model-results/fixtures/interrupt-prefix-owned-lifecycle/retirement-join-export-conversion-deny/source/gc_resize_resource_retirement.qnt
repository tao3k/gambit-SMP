module gc_resize_resource_retirement {
  // Source-tree refinement with a queue operation crossing GC/resize admission.
  // Cardinalities are finite verification bounds, never runtime worker limits.
  type State = { policy: str, population: int, target: int, phase: str,
    scanWorker: int, queueOwner: int,
    scan: str, queueEmpty: bool, gcArrived: Set[int], edge: int -> str,
    received: Set[int], exited: Set[int], joined: Set[int], nextRound: Set[int],
    queueAlive: Set[int], syncAlive: Set[int], storageAlive: Set[int],
    reclaimed: bool, invalidQueue: bool }
  var s: State
  pure def initial(policy: str, population: int, target: int,
    scanWorker: int, queueOwner: int): State = {
    policy: policy, population: population, target: target, phase: "gc",
    scanWorker: scanWorker, queueOwner: queueOwner,
    scan: "queued", queueEmpty: false, gcArrived: Set(),
    edge: 1.to(population - 1).mapBy(_ => "absent"), received: Set(),
    exited: Set(), joined: Set(), nextRound: Set(),
    queueAlive: 0.to(population - 1), syncAlive: 0.to(population - 1),
    storageAlive: 0.to(population - 1), reclaimed: false, invalidQueue: false,
  }
  action initOld = s' = initial("all-at-exit", 2, 1, 0, 1)
  action initQueueOnly = s' = initial("queue-only", 2, 1, 0, 1)
  action initJoinOnly = s' = initial("join-only", 4, 2, 0, 3)
  action initFixed = {
    nondet population = 2.to(5).oneOf()
    nondet target = 1.to(population - 1).oneOf()
    nondet scanWorker = 0.to(population - 1).oneOf()
    nondet queueOwner = 0.to(population - 1).oneOf()
    s' = initial("split-lifetimes", population, target, scanWorker, queueOwner)
  }
  val retired = s.target.to(s.population - 1)
  val retained = 0.to(s.target - 1)
  pure def parent(child: int): int = (child - 1) / 2
  def children(node: int): Set[int] =
    Set(2 * node + 1, 2 * node + 2).filter(c => c < s.population)
  def completed(node: int): bool = s.received.contains(node) and
    children(node).forall(c => s.edge.get(c) == "done")
  action claimQueue = all {
    s.scan == "queued",
    s' = { ...s, scan: "locked",
      invalidQueue: s.invalidQueue or not(s.queueAlive.contains(s.queueOwner)) },
  }
  action popQueue = all {
    s.scan == "locked", s' = { ...s, scan: "pending-unlock", queueEmpty: true },
  }
  action releaseQueue = all {
    s.scan == "pending-unlock",
    s' = { ...s, scan: "scanning",
      invalidQueue: s.invalidQueue or not(s.queueAlive.contains(s.queueOwner)) or
        not(s.storageAlive.contains(s.queueOwner)) },
  }
  action finishScan = all { s.scan == "scanning", s' = { ...s, scan: "done" } }
  action arriveGC = {
    nondet node = 0.to(s.population - 1).oneOf()
    all {
      s.phase == "gc", not(s.gcArrived.contains(node)),
      node != s.scanWorker or s.scan == "done" or (s.policy == "queue-only" and s.queueEmpty),
      s' = { ...s, gcArrived: s.gcArrived.union(Set(node)) },
    }
  }
  action beginResize = all {
    s.phase == "gc", s.gcArrived == 0.to(s.population - 1),
    s' = { ...s, phase: "resize", received: Set(0) },
  }
  action publish = {
    nondet child = 1.to(s.population - 1).oneOf()
    val p = parent(child)
    all {
      s.phase == "resize", s.received.contains(p), s.edge.get(child) == "absent",
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
    all {
      completed(node), not(s.exited.contains(node)),
      s' = { ...s, exited: s.exited.union(Set(node)), queueAlive: s.queueAlive.exclude(Set(node)),
        syncAlive: if (s.policy == "all-at-exit") s.syncAlive.exclude(Set(node)) else s.syncAlive },
    }
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
    s.policy != "all-at-exit", not(s.reclaimed), retired.subseteq(s.joined),
    s.policy == "join-only" or retained.subseteq(s.nextRound),
    s' = { ...s, syncAlive: s.syncAlive.exclude(retired),
      storageAlive: s.storageAlive.exclude(retired), reclaimed: true },
  }
  action legacyReclaim = all {
    s.policy == "all-at-exit", not(s.reclaimed), retired.subseteq(s.joined),
    retained.subseteq(s.nextRound),
    s' = { ...s, storageAlive: s.storageAlive.exclude(retired), reclaimed: true },
  }
  val terminal = s.reclaimed and retired.subseteq(s.joined) and
    retained.subseteq(s.nextRound) and s.scan == "done"
  action finished = all { terminal, s' = s }
  action step = any { claimQueue, popQueue, releaseQueue, finishScan, arriveGC,
    beginResize, publish, unlock, signal, receive, exitChild, joinChild,
    enterNextRound, reclaim, legacyReclaim, finished }
  val queueSafe = not(s.invalidQueue)
  val syncSafe = retired.exclude(s.syncAlive).forall(node => s.edge.get(node) == "done")
  val storageSafe = retired.exclude(s.storageAlive).forall(node =>
    s.edge.get(node) == "done" and s.joined.contains(node))
  val safe = queueSafe and syncSafe and storageSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
