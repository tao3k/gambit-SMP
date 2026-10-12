module thread_migration_interrupt_requeue {
  // Processor identities are protocol roles, not a runtime CPU limit.
  type State = { fixed: bool, queued: int, destination: int, owner: int,
    gate: bool, interrupted: bool, pinned: bool, returned: bool }
  var s: State
  pure def initial(fixed: bool, pinned: bool): State = {
    fixed: fixed, queued: 1, destination: 1, owner: -1,
    gate: true, interrupted: false, pinned: pinned, returned: false,
  }
  action initOld = s' = initial(false, false)
  action initFixed = {
    nondet pinned = Set(false, true).oneOf()
    s' = initial(true, pinned)
  }
  // The interrupt helper removes the old queue entry under its locks.
  // Legacy routing chooses the user pin or the interrupt sender, not
  // the pending migration destination. The proposed policy retains it.
  action interruptRequeue = all {
    s.owner == -1, not(s.interrupted),
    s' = { ...s, interrupted: true,
      queued: if (s.fixed and s.gate) s.destination else if (s.pinned) 0 else 2 },
  }
  action localClaim = all {
    s.owner == -1, s' = { ...s, owner: s.queued, queued: -1 },
  }
  action returnCaller = all {
    s.owner != -1, not(s.returned),
    s' = { ...s, gate: false, returned: true },
  }
  action finished = all { s.returned, s' = s }
  action step = any { interruptRequeue, localClaim, returnCaller, finished }
  val destinationSafe = s.owner == -1 or s.owner == s.destination
  val queueExclusive = s.owner == -1 or s.queued == -1
  val safe = destinationSafe and queueExclusive
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.returned))
}
