module nested_foreign_unwind {
  // Two C frames on distinct processor stacks, not a host CPU limit.
  type State = { policy: int, phase: int, fault: bool, error: int,
    pending: int, delivered: int, current: int, frames: Set[int],
    markers: Set[int], kills: int -> int, wrongOwner: bool, retired: bool }
  var s: State
  pure def initial(policy: int, fault: bool, error: int): State = {
    policy: policy, phase: 0, fault: fault, error: error,
    pending: 0, delivered: 0, current: 0, frames: Set(0),
    markers: Set(0), kills: Map(0 -> 0, 1 -> 0),
    wrongOwner: false, retired: false
  }
  action initFixed = {
    nondet error = Set(0, 7, 9).oneOf()
    s' = initial(0, error != 0, error)
  }
  action initInnerLeak = s' = initial(1, true, 7)
  action initWrongOwner = s' = initial(2, true, 7)
  action initDoubleCleanup = s' = initial(3, true, 7)
  action initErrorErase = s' = initial(4, true, 7)
  action initEarlyRetire = s' = initial(5, true, 7)
  action migrateAndEnterInner = all {
    s.phase == 0,
    s' = { ...s, phase: 1, current: 1,
      frames: s.frames.union(Set(1)), markers: s.markers.union(Set(1)) },
  }
  action innerOutcome = all {
    s.phase == 1,
    s' = { ...s, phase: 2, pending: s.error },
  }
  // An inner catcher owns only its own C frame, not the suspended outer one.
  action cleanInner = all {
    s.phase == 2,
    s' = if (s.policy == 1 and s.fault) { ...s, phase: 3 }
      else { ...s, phase: 3, frames: s.frames.exclude(Set(1)),
        markers: s.markers.exclude(Set(1)), kills: s.kills.set(1, 1) },
  }
  // Returning or propagating to the outer C frame requires origin routing.
  // This is a source-refinement obligation, not an implemented message queue.
  action routeOuter = all {
    s.phase == 3,
    s' = { ...s, phase: 4, current: if (s.policy == 2) 1 else 0 },
  }
  action cleanOuter = all {
    s.phase == 4,
    s' = { ...s, phase: 5, frames: s.frames.exclude(Set(0)),
      markers: s.markers.exclude(Set(0)), kills: s.kills.set(0, 1),
      wrongOwner: s.current != 0 },
  }
  action propagate = all {
    s.phase == 5,
    s' = { ...s, phase: 6,
      kills: if (s.policy == 3) s.kills.set(1, 2) else s.kills,
      delivered: if (s.policy == 4) 0 else s.pending },
  }
  action retire = all {
    not(s.retired), s.phase == 6 or s.policy == 5,
    s' = { ...s, retired: true },
  }
  val terminal = s.phase == 6 and s.retired
  action finished = all { terminal, s' = s }
  action step = any { migrateAndEnterInner, innerOutcome, cleanInner,
    routeOuter, cleanOuter, propagate, retire, finished }
  val innerDrained = (s.phase >= 3).implies(not(s.frames.contains(1)))
  val ownerCleanup = not(s.wrongOwner)
  val exactOnce = Set(0, 1).forall(p => s.kills.get(p) <= 1)
  val honestError = (s.phase == 6).implies(s.delivered == s.error)
  val retirementSafe = s.retired.implies(s.frames.size() == 0)
  val markerOwnership = s.markers == s.frames
  val progressEnabled = terminal or enabled(step)
  val safe = innerDrained and ownerCleanup and exactOnce and honestError
    and retirementSafe and markerOwnership and progressEnabled
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}
