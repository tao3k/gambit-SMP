module resize_collective_heap_guard {
  // Finite processor populations are model bounds, not runtime worker limits.
  type State = { fixed: bool, count: int, free: int, vote: int -> int,
    decision: int -> int, entered: Set[int], collected: bool, allocated: bool }
  var s: State
  pure def initial(fixed: bool, count: int, free: int): State = {
    fixed: fixed, count: count, free: free, vote: 0.to(count - 1).mapBy(_ => -1),
    decision: 0.to(count - 1).mapBy(_ => -1), entered: Set(),
    collected: false, allocated: false,
  }
  action initOld = s' = initial(false, 2, 2)
  action initFixed = {
    nondet count = Set(2, 3).oneOf()
    nondet free = Set(0, 1, 2).oneOf()
    s' = initial(true, count, free)
  }
  val members = 0.to(s.count - 1)
  action checkHeap = {
    nondet p = members.oneOf()
    val need = if (s.free < 2) 1 else 0
    all { s.vote.get(p) == -1,
      s' = { ...s, vote: s.vote.set(p, need),
        decision: if (s.fixed) s.decision else s.decision.set(p, need) } }
  }
  action collectiveDecision = all {
    s.fixed, members.forall(p => s.vote.get(p) >= 0), s.decision.get(0) == -1,
    val need = if (members.exists(p => s.vote.get(p) == 1)) 1 else 0
    s' = { ...s, decision: members.mapBy(_ => need) },
  }
  action enterGC = {
    nondet p = members.oneOf()
    all { s.decision.get(p) == 1, not(s.entered.contains(p)),
      s' = { ...s, entered: s.entered.union(Set(p)) } }
  }
  action finishGC = all { s.entered == members, not(s.collected),
    s' = { ...s, free: 4, collected: true } }
  // P0 setup consumes sections. Without a collective decision, a late peer
  // can evaluate the same source condition against the changed shared count.
  action setupNewProcessor = all {
    not(s.allocated), s.decision.get(0) >= 0,
    s.decision.get(0) == 0 or s.collected,
    s' = { ...s, free: s.free - 2, allocated: true },
  }
  val terminal = s.allocated and members.forall(p => s.decision.get(p) >= 0) and
    (s.entered == Set() or s.collected)
  action finished = all { terminal, s' = s }
  action step = any { checkHeap, collectiveDecision, enterGC, finishGC,
    setupNewProcessor, finished }
  val uniform = members.forall(p => members.forall(q =>
    (s.decision.get(p) >= 0 and s.decision.get(q) >= 0)
      .implies(s.decision.get(p) == s.decision.get(q))))
  val noDeadlock = terminal or enabled(step)
  val safe = uniform and noDeadlock and s.free >= 0
  temporal progress = always(noDeadlock) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
