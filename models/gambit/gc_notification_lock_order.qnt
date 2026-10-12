module gc_notification_lock_order {
  // Three abstract roles, each identity explored as the waiter. Not a CPU cap.
  type State = { policy: str, helper: int, publishers: Set[int],
    phase: int -> int, queues: int -> int, published: Set[int],
    mutex: int, helperPhase: int, target: int, remaining: Set[int] }
  var s: State
  pure def initial(policy: str, helper: int): State = {
    policy: policy, helper: helper,
    publishers: Set(0, 1, 2).exclude(Set(helper)),
    phase: Map(0 -> 0, 1 -> 0, 2 -> 0),
    queues: Map(0 -> -1, 1 -> -1, 2 -> -1), published: Set(),
    mutex: -1, helperPhase: 0, target: -1,
    remaining: Set(0, 1, 2).exclude(Set(helper)),
  }
  action initOld = {
    nondet helper = Set(0, 1, 2).oneOf()
    s' = initial("nested-signal", helper)
  }
  action init = {
    nondet helper = Set(0, 1, 2).oneOf()
    nondet policy = Set("source", "signal-after-unlock").oneOf()
    s' = initial(policy, helper)
  }
  action publisherLocks = {
    nondet p = s.publishers.oneOf()
    all { s.phase.get(p) == 0, s.queues.get(p) == -1,
      s' = { ...s, phase: s.phase.set(p, 1), queues: s.queues.set(p, p) } }
  }
  action publish = {
    nondet p = s.publishers.oneOf()
    all { s.phase.get(p) == 1, s.queues.get(p) == p,
      s' = { ...s, phase: s.phase.set(p, 2),
        published: s.published.union(Set(p)) } }
  }
  // Current source releases the queue spinlock before signalling. Preserve it.
  action releaseQueue = {
    nondet p = s.publishers.oneOf()
    all { s.phase.get(p) == 2, s.policy != "nested-signal",
      s' = { ...s, phase: s.phase.set(p, 3), queues: s.queues.set(p, -1) } }
  }
  action sourceSignal = {
    nondet p = s.publishers.oneOf()
    all { s.phase.get(p) == 3, s.policy == "source",
      s' = { ...s, phase: s.phase.set(p, 5) } }
  }
  action signalLocks = {
    nondet p = s.publishers.oneOf()
    all { s.policy != "source", s.mutex == -1,
      s.phase.get(p) == (if (s.policy == "nested-signal") 2 else 3),
      s' = { ...s, mutex: p, phase: s.phase.set(p, 4) } }
  }
  action protectedSignal = {
    nondet p = s.publishers.oneOf()
    all { s.phase.get(p) == 4, s.mutex == p,
      s' = { ...s, mutex: -1, phase: s.phase.set(p, 5),
        queues: s.queues.set(p, -1) } }
  }
  // Proposed waiter-side predicate recheck holds termination M, then one Q.
  action waiterLocks = all {
    s.helperPhase == 0, s.mutex == -1,
    s' = { ...s, mutex: s.helper, helperPhase: 1 },
  }
  action selectQueue = {
    nondet p = s.remaining.oneOf()
    all { s.helperPhase == 1,
      s' = { ...s, target: p, helperPhase: 2 } }
  }
  action recheckQueue = all {
    s.helperPhase == 2, s.queues.get(s.target) == -1,
    s' = { ...s, queues: s.queues.set(s.target, s.helper), helperPhase: 3 },
  }
  // Read only: no chunk scanning or allocation under the termination mutex.
  action releaseRecheck = all {
    s.helperPhase == 3,
    s' = { ...s, queues: s.queues.set(s.target, -1), helperPhase: 1,
      remaining: s.remaining.exclude(Set(s.target)), target: -1 },
  }
  action waiterUnlocks = all {
    s.helperPhase == 1, s.remaining == Set(),
    s' = { ...s, mutex: -1, helperPhase: 4 },
  }
  val terminal = s.helperPhase == 4 and s.publishers.forall(p => s.phase.get(p) == 5)
  val noLockCycle = not(s.policy == "nested-signal" and s.helperPhase == 2 and
    s.mutex == s.helper and s.queues.get(s.target) == s.target and
    s.phase.get(s.target) == 2)
  val ownersValid = s.publishers.forall(p => {
    val owner = s.queues.get(p)
    owner == -1 or
      (owner == p and Set(1, 2, 4).contains(s.phase.get(p))) or
      (owner == s.helper and s.helperPhase == 3 and s.target == p)
  }) and (s.mutex == -1 or
    (s.mutex == s.helper and Set(1, 2, 3).contains(s.helperPhase)) or
    s.publishers.exists(p => s.mutex == p and s.phase.get(p) == 4))
  val safe = noLockCycle and ownersValid
  action finished = all { terminal, s' = s }
  action step = any { publisherLocks, publish, releaseQueue, sourceSignal,
    signalLocks, protectedSignal, waiterLocks, selectQueue, recheckQueue,
    releaseRecheck, waiterUnlocks, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
