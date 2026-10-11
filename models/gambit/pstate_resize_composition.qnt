module pstate_resize_composition {
  // Grow 1 -> 3. Each new slot has five atomic owned setup stages.
  // Caller cleans successful new slots; failed slot must unwind itself.
  type State = { fault: int, failure: int, slot: int, stage: int,
    phase: int, active: int, target: int, prepared: Set[int], resources: Set[int] }
  var s: State
  pure def owned(slot: int): Set[int] = Set(0, 1, 2, 3, 4).map(i => slot * 10 + i)
  pure def initial(fault: int, failure: int): State = {
    fault: fault, failure: failure, slot: 1, stage: 0, phase: 0,
    active: 1, target: 3, prepared: Set(0), resources: owned(0),
  }
  action initOld = s' = initial(1, 15)
  action initCaller = s' = initial(2, 25)
  action initTarget = s' = initial(3, 15)
  action initEarly = s' = initial(4, 0)
  action initExisting = s' = initial(5, 25)
  action initFixed = {
    nondet failure = Set(0, 11, 12, 13, 14, 15, 21, 22, 23, 24, 25).oneOf()
    s' = initial(0, failure)
  }
  action setup = {
    val error = s.failure == s.slot * 10 + s.stage + 1
    all {
      s.phase == 0, s.slot <= 2, s.stage < 5,
      s' = { ...s, phase: if (error) 2 else 0,
        stage: if (error) s.stage else s.stage + 1,
        resources: if (error) s.resources else s.resources.union(Set(s.slot * 10 + s.stage)) },
    }
  }
  action prepared = all {
    s.phase == 0, s.stage == 5,
    s' = { ...s, prepared: s.prepared.union(Set(s.slot)),
      slot: s.slot + 1, stage: 0, phase: if (s.slot == 2) 1 else 0 },
  }
  action selfRollback = all {
    s.phase == 2,
    s' = { ...s, phase: 3,
      resources: if (s.fault == 1) s.resources else s.resources.exclude(owned(s.slot)) },
  }
  action callerRollback = {
    val prior = s.prepared.exclude(Set(0))
    nondet slot = prior.oneOf()
    val wrong = if (s.fault == 2) s.slot else if (s.fault == 5) 0 else slot
    all {
      s.phase == 3,
      s' = { ...s, prepared: s.prepared.exclude(Set(slot)),
        resources: s.resources.exclude(owned(wrong)) },
    }
  }
  action failReturn = all {
    s.phase == 3, s.prepared == Set(0),
    s' = { ...s, phase: 5, target: if (s.fault == 3) 3 else 1 },
  }
  action publish = all {
    s.phase == 1, s' = { ...s, phase: 5, active: 3 },
  }
  action earlyPublish = all {
    s.fault == 4, s.phase == 0,
    s' = { ...s, phase: 5, active: 3 },
  }
  val terminal = s.phase == 5
  action finished = all { terminal, s' = s }
  action step = any { setup, prepared, selfRollback, callerRollback,
    failReturn, publish, earlyPublish, finished }
  val localRollbackSafe = s.phase != 3 or s.resources.intersect(owned(s.slot)) == Set()
  val callerRollbackSafe = not(terminal and s.active == 1) or s.resources == owned(0)
  val targetSafe = not(terminal) or s.target == s.active
  val publicationSafe = s.active != 3 or
    (s.prepared == Set(0, 1, 2) and s.resources == owned(0).union(owned(1)).union(owned(2)))
  val existingSafe = owned(0).subseteq(s.resources)
  val safe = localRollbackSafe and callerRollbackSafe and targetSafe and publicationSafe and existingSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
