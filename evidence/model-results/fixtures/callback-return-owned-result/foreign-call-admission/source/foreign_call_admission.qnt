module foreign_call_admission {
  // Two nested/concurrent call tokens; the runtime entry is not a foreign lease.
  val tokens = Set(0, 1)
  type State = { policy: int, phase: int, closed: bool, retired: bool,
    calls: int -> int, fault: int -> int, owners: Set[int],
    markers: Set[int], count: int, updates: int, denied: Set[int],
    errors: Set[int], leaked: Set[int] }
  var s: State
  pure def initial(policy: int, f0: int, f1: int): State = {
    policy: policy, phase: 0, closed: false, retired: false,
    calls: Map(0 -> 0, 1 -> 0), fault: Map(0 -> f0, 1 -> f1),
    owners: Set(), markers: Set(), count: if (policy == 2) 1 else 0,
    updates: 0, denied: Set(), errors: Set(), leaked: Set()
  }
  action initFixed = {
    nondet f0 = Set(0, 1, 2).oneOf()
    nondet f1 = Set(0, 1, 2).oneOf()
    s' = initial(0, f0, f1)
  }
  action initSplitAdmission = s' = initial(1, 0, 0)
  action initCountRuntimeEntry = s' = initial(2, 0, 0)
  action initAllocationLeak = s' = initial(3, 1, 0)
  action initUnwindLeak = s' = initial(4, 2, 0)
  action initFalseShrinkSuccess = s' = initial(5, 0, 0)

  action enter = {
    nondet t = tokens.oneOf()
    all {
      s.calls.get(t) == 0,
      s' = if (s.closed) { ...s, calls: s.calls.set(t, 5),
        denied: s.denied.union(Set(t)) }
      else if (s.policy == 1) { ...s, calls: s.calls.set(t, 6) }
      else { ...s, calls: s.calls.set(t, 1), count: s.count + 1,
        owners: s.owners.union(Set(t)), updates: s.updates + 1 },
    }
  }
  // Bad check-then-increment admits a call after the closer observed zero.
  action finishSplitAdmission = {
    nondet t = tokens.oneOf()
    all {
      s.calls.get(t) == 6,
      s' = { ...s, calls: s.calls.set(t, 1), count: s.count + 1,
        owners: s.owners.union(Set(t)), updates: s.updates + 1 },
    }
  }
  action allocateMarker = {
    nondet t = tokens.oneOf()
    all {
      s.calls.get(t) == 1,
      s' = if (s.fault.get(t) == 1) { ...s, calls: s.calls.set(t, 3),
        errors: s.errors.union(Set(t)) }
      else { ...s, calls: s.calls.set(t, 2), markers: s.markers.union(Set(t)) },
    }
  }
  action callbackOutcome = {
    nondet t = tokens.oneOf()
    all {
      s.calls.get(t) == 2,
      s' = { ...s, calls: s.calls.set(t, 3),
        errors: if (s.fault.get(t) == 2) s.errors.union(Set(t)) else s.errors },
    }
  }
  // Allocation failure, normal return and nonlocal unwind share exact-once
  // cleanup. The real SFUN wrappers do not yet implement this design.
  action release = {
    nondet t = tokens.oneOf()
    all {
      s.calls.get(t) == 3,
      s' = if ((s.policy == 3 and s.fault.get(t) == 1) or
                  (s.policy == 4 and s.fault.get(t) == 2))
        { ...s, calls: s.calls.set(t, 4), leaked: s.leaked.union(Set(t)) }
      else { ...s, calls: s.calls.set(t, 4), count: s.count - 1,
        owners: s.owners.exclude(Set(t)), markers: s.markers.exclude(Set(t)),
        updates: s.updates + 1 },
    }
  }
  // A busy outcome occurs before any collective quiescence. It does not park
  // the processors that must execute the outstanding callback's return.
  action closeAttempt = all {
    s.phase == 0,
    s' = if (s.count == 0) { ...s, phase: 1, closed: true }
      else if (s.policy == 5) { ...s, phase: 1, closed: true }
      else { ...s, phase: 2 },
  }
  action closeAfterDrain = all {
    s.phase == 2, s.count == 0,
    s' = { ...s, phase: 1, closed: true },
  }
  action retire = all {
    s.phase == 1,
    s' = { ...s, phase: 3, retired: true },
  }
  val callsTerminal = tokens.forall(t => Set(4, 5).contains(s.calls.get(t)))
  val terminal = s.phase == 3 and callsTerminal
  action finished = all { terminal, s' = s }
  action step = any { enter, finishSplitAdmission, allocateMarker,
    callbackOutcome, release, closeAttempt, closeAfterDrain, retire, finished }
  val admissionSafe = s.closed.implies(s.count == 0 and s.owners.size() == 0)
  val countExact = s.count == s.owners.size()
  val retirementSafe = not(s.retired) or s.owners.size() == 0
  val markerOwned = s.markers.subseteq(s.owners)
  val exactlyOnce = s.count >= 0 and s.updates <= 4
  val noLeak = s.leaked.size() == 0
  val allocationRollback = noLeak
  val unwindRollback = noLeak
  val errorsRecorded = tokens.forall(t =>
    (Set(3, 4).contains(s.calls.get(t)) and s.fault.get(t) != 0)
      .implies(s.errors.contains(t)))
  val progressEnabled = terminal or enabled(step)
  val safe = admissionSafe and countExact and retirementSafe and markerOwned
    and exactlyOnce and noLeak and errorsRecorded and progressEnabled
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}
