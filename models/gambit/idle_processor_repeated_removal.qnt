module idle_processor_repeated_removal {
  // Sentinel 0 and processors 1,2 are protocol roles, not a CPU cap.
  type State = { fixed: bool, phase: int, next: int -> int, prev: int -> int }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0,
    next: Map(0 -> 1, 1 -> 0, 2 -> 2),
    prev: Map(0 -> 1, 1 -> 0, 2 -> 2),
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  pure def remove(st: State, node: int): State = {
    val n = st.next.get(node)
    val p = st.prev.get(node)
    val ns = st.next.set(p, n)
    val ps = st.prev.set(n, p)
    { ...st, next: if (st.fixed) ns.set(node, node) else ns,
      prev: if (st.fixed) ps.set(node, node) else ps }
  }
  // Wake-up removes processor 1 while holding the VM lock.
  action wake = all { s.phase == 0, s' = { ...remove(s, 1), phase: 1 } }
  // Processor 2 parks before processor 1 returns from its select call.
  action parkOther = all {
    s.phase == 1,
    s' = { ...s, phase: 2, next: s.next.set(0, 2).set(2, 0),
      prev: s.prev.set(0, 2).set(2, 0) },
  }
  action selectReturns = all {
    s.phase == 2, s' = { ...remove(s, 1), phase: 3 },
  }
  action finished = all { s.phase == 3, s' = s }
  action step = any { wake, parkOther, selectReturns, finished }
  val otherPreserved = s.phase < 2 or
    (s.next.get(0) == 2 and s.prev.get(0) == 2 and
     s.next.get(2) == 0 and s.prev.get(2) == 0)
  val detached = s.phase == 0 or
    (s.next.get(1) == 1 and s.prev.get(1) == 1)
  val safe = otherPreserved and detached
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.phase == 3))
}
