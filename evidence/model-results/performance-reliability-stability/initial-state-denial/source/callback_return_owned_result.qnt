module callback_return_owned_result {
  // Two processor identities, not a host CPU limit. Value identity is opaque.
  type State = { policy: int, origin: int, current: int, phase: int,
    value: int, result: int, saved: int, rooted: bool, epoch: int,
    savedEpoch: int, migration: bool }
  var s: State
  action initFixed = {
    nondet origin = Set(0, 1).oneOf()
    nondet value = Set(0, 1, 2).oneOf()
    nondet migration = Set(false, true).oneOf()
    s' = { policy: 0, origin: origin, current: origin, phase: 0,
      value: value, result: value, saved: -1, rooted: false, epoch: 0,
      savedEpoch: 0, migration: migration }
  }
  action initLostResult = s' = { policy: 1, origin: 0, current: 0, phase: 0,
    value: 2, result: 2, saved: -1, rooted: false, epoch: 0,
    savedEpoch: 0, migration: true }
  action initUnrooted = s' = { policy: 2, origin: 0, current: 0, phase: 0,
    value: 2, result: 2, saved: -1, rooted: false, epoch: 0,
    savedEpoch: 0, migration: true }
  action bodyReturn = all {
    s.phase == 0,
    s' = if (s.migration) { ...s, current: 1 - s.origin, phase: 1 }
      else { ...s, phase: 5 },
  }
  action routeToOrigin = all {
    s.phase == 1,
    s' = { ...s, phase: 2, result: -1,
      saved: if (s.policy == 1) -1 else s.result, rooted: s.policy == 0 },
  }
  // A moving collection while the migration continuation is suspended.
  action collect = all {
    s.phase == 2,
    s' = { ...s, phase: 3, epoch: 1,
      savedEpoch: if (s.rooted) 1 else s.savedEpoch },
  }
  action resume = all {
    s.phase == 3,
    s' = { ...s, phase: 4, current: s.origin },
  }
  action restore = all {
    s.phase == 4,
    s' = { ...s, phase: 5, result: s.saved },
  }
  val terminal = s.phase == 5
  action finished = all { terminal, s' = s }
  action step = any { bodyReturn, routeToOrigin, collect, resume, restore, finished }
  val resultPreserved = terminal.implies(s.result == s.value)
  val rootCurrent = (s.phase >= 3 and s.migration and s.policy != 1)
    .implies(s.savedEpoch == s.epoch)
  val returnsToOwner = terminal.implies(s.current == s.origin)
  val safe = resultPreserved and rootCurrent and returnsToOwner
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}
