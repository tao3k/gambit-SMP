module workload_completion_visibility {
  // Two abstract roots, three result-bearing subtree completions each.
  // These are finite workload units, not host CPU or native test counts.
  type State = { a: int, b: int, observedIdle: int, semanticIdle: int,
    stopped: bool, done: bool, policy: int }
  var s: State
  pure def initial(policy: int): State = {
    a: 0, b: 0, observedIdle: 0, semanticIdle: 0,
    stopped: false, done: false, policy: policy,
  }
  action initRootOnly = s' = initial(0)
  action initNoise = s' = initial(2)
  action initFixed = s' = initial(1)
  val active = not(s.stopped) and not(s.done)
  action tick = all {
    active, s.observedIdle < 3,
    s' = { ...s, observedIdle: s.observedIdle + 1,
      semanticIdle: if (s.semanticIdle < 3) s.semanticIdle + 1 else 3 },
  }
  action completedSubtree = {
    nondet owner = Set(0, 1).oneOf()
    val previous = if (owner == 0) s.a else s.b
    val a = if (owner == 0) s.a + 1 else s.a
    val b = if (owner == 1) s.b + 1 else s.b
    all {
      active, s.observedIdle < 3, previous < 3,
      s' = { ...s, a: a, b: b, semanticIdle: 0,
        observedIdle: if (s.policy == 1 or previous == 2) 0 else s.observedIdle,
        done: a == 3 and b == 3 },
    }
  }
  action noise = all {
    active,
    s' = if (s.policy == 2) { ...s, observedIdle: 0 } else s,
  }
  action expire = all {
    active, s.observedIdle == 3, s' = { ...s, stopped: true },
  }
  action advance = any { tick, completedSubtree, expire }
  action step = any { advance, noise, s' = s }
  val truthfulClock = s.observedIdle == s.semanticIdle
  val noFalseTimeout = not(s.stopped) or s.semanticIdle == 3
  val noPrematureCompletion = not(s.done) or (s.a == 3 and s.b == 3)
  val contract = truthfulClock and noFalseTimeout and noPrematureCompletion
  val terminal = s.done or s.stopped
  temporal progress = weakFair(advance, s).implies(eventually(terminal))
}
