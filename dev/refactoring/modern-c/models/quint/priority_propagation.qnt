module priority_propagation {
  // Custody and scheduling-key algebra only. RB topology and frame/root
  // layout retain their existing QNT and Lean obligations.
  pure def orderedKeys = Set("bottom", "low", "high")
  pure def payloads = orderedKeys.union(Set("nan"))
  pure def key(x: str): str = if (x == "nan") "bottom" else x
  pure def join(x: str, y: str): str =
    if (x == "high" or y == "high") "high"
    else if (x == "low" or y == "low") "low" else "bottom"
  pure def le(x: str, y: str): bool = join(x, y) == y
  pure def cycleSolution(x: str, y: str, a: str, b: str): bool =
    x == join(a, y) and y == join(b, x)
  // Exhaustive finite algebra laws, not samples of native floating-point bits.
  pure def joinLaws = orderedKeys.forall(a => orderedKeys.forall(b => orderedKeys.forall(c =>
    join(a, a) == a and join(a, "bottom") == a and
    join(a, b) == join(b, a) and
    join(a, join(b, c)) == join(join(a, b), c))))
  pure def leastCycleLaw = orderedKeys.forall(a => orderedKeys.forall(b => {
    val m = join(a, b)
    cycleSolution(m, m, a, b) and orderedKeys.forall(x => orderedKeys.forall(y =>
      cycleSolution(x, y, a, b) implies (le(m, x) and le(m, y))))
  }))
  type State = { mode: str, phase: str, callerAlive: bool,
    ownerReserved: bool, ownerPending: bool, commitHeld: bool,
    terminates: bool, gcRequested: bool, cyclic: bool,
    leftRaw: str, rightRaw: str, leftExternal: str, rightExternal: str,
    leftKey: str, rightKey: str, plannedLeft: str, plannedRight: str }
  var s: State
  pure def initial(mode: str): State = {
    mode: mode, phase: "prepare", callerAlive: true,
    ownerReserved: false, ownerPending: false, commitHeld: false,
    terminates: mode != "cyclic", gcRequested: false, cyclic: true,
    leftRaw: "nan", rightRaw: "nan", leftExternal: "bottom", rightExternal: "bottom",
    leftKey: "bottom", rightKey: "bottom", plannedLeft: "bottom", plannedRight: "bottom",
  }
  action initSplit = s' = initial("split")
  action initPlanned = s' = initial("planned")
  action initCyclic = s' = initial("cyclic")
  action initClosure = {
    nondet l = payloads.oneOf()
    nondet r = payloads.oneOf()
    nondet e = orderedKeys.oneOf()
    nondet f = orderedKeys.oneOf()
    nondet oldl = orderedKeys.oneOf()
    nondet oldr = orderedKeys.oneOf()
    nondet cyclic = Set(true, false).oneOf()
    s' = { ...initial("closure"), leftRaw: l, rightRaw: r,
      leftExternal: e, rightExternal: f, leftKey: oldl, rightKey: oldr, cyclic: cyclic }
  }
  action reserveOwner = all {
    s.mode != "split", s.phase == "prepare", s.callerAlive,
    s' = { ...s, ownerReserved: true },
  }
  action solveClosure = all {
    s.mode == "closure", s.phase == "prepare", s.ownerReserved, s.callerAlive,
    val a = join(key(s.leftRaw), s.leftExternal)
    val b = join(key(s.rightRaw), s.rightExternal)
    s' = { ...s, phase: "solved", plannedLeft: if (s.cyclic) join(a, b) else a,
           plannedRight: join(a, b) },
  }
  action publishRoot = all {
    s.callerAlive,
    (s.mode == "closure" and s.phase == "solved") or
      (s.mode != "closure" and s.phase == "prepare"),
    s.mode == "split" or s.ownerReserved,
    s' = { ...s, phase: "published",
      ownerPending: s.mode == "split" or s.mode == "closure",
      commitHeld: s.mode != "split",
      leftKey: if (s.mode == "closure") s.plannedLeft else s.leftKey },
  }
  action finishOwner = all {
    s.phase == "published", s.callerAlive, s.terminates,
    s' = { ...s, phase: "done", ownerPending: false, commitHeld: false,
      rightKey: if (s.mode == "closure") s.plannedRight else s.rightKey },
  }
  action unwindCaller = all {
    s.phase != "done", s.callerAlive,
    s.mode == "split" or s.phase == "prepare" or s.phase == "solved",
    s' = { ...s, phase: "unwound", callerAlive: false },
  }
  action requestGC = all { not(s.gcRequested), s' = { ...s, gcRequested: true } }
  action step = any { reserveOwner, solveClosure, publishRoot, finishOwner,
                      unwindCaller, requestGC, s' = s }
  val safe = not(s.ownerPending and not(s.callerAlive))
  val solved = if (s.mode == "closure" and s.phase == "done") {
    val a = join(key(s.leftRaw), s.leftExternal)
    val b = join(key(s.rightRaw), s.rightExternal)
    if (s.cyclic) cycleSolution(s.leftKey, s.rightKey, a, b) and
      orderedKeys.forall(x => orderedKeys.forall(y => cycleSolution(x, y, a, b) implies
        (le(s.leftKey, x) and le(s.rightKey, y))))
    else s.leftKey == a and s.rightKey == join(a, b)
  } else true
  val admissible = safe and solved and joinLaws and leastCycleLaw and
    not(s.commitHeld and s.gcRequested and not(s.terminates))
  // The finite two-node instance. General prefix/cycle refinement and native
  // bounded loop premises are separate source obligations, not a Lean rewrite.
  temporal completion = weakFair(finishOwner, Set(s)).implies(
    always((s.mode == "closure" and s.phase == "published").implies(eventually(s.phase == "done"))))
}
