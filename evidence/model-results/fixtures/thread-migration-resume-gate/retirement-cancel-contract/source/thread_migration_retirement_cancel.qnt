module thread_migration_retirement_cancel {
  // Roles: donor=0, destination=1. A saved continuation is assumed.
  // Cancellation is cooperative, as in the started-thread interrupt path.
  type State = { fixed: bool, phase: int, owner: int, queued: int,
    closing: bool, alive: bool, borrowed: bool, cancel: bool,
    outcome: int }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, owner: -1, queued: 1,
    closing: false, alive: true, borrowed: true, cancel: false, outcome: 0,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action cancelRequest = all {
    s.outcome == 0, not(s.cancel), s' = { ...s, cancel: true },
  }
  action closeAdmission = all {
    not(s.closing), s' = { ...s, closing: true },
  }
  action destinationClaim = all {
    s.phase == 0, s.alive, not(s.closing),
    s' = { ...s, phase: 1, queued: -1, owner: 1 },
  }
  // A closed destination drains a queued handoff back to a live donor.
  // The donor is a design assumption, not established by current C resize.
  action rollbackQueued = all {
    s.fixed, s.phase == 0, s.closing,
    s' = { ...s, phase: 2, queued: -1, owner: 0, borrowed: false },
  }
  action finishDestination = all {
    s.phase == 1, s.alive,
    s' = { ...s, phase: 3, owner: -1, borrowed: false,
      outcome: if (s.cancel) 2 else 1 },
  }
  action finishRollback = all {
    s.phase == 2,
    s' = { ...s, phase: 3, owner: -1,
      outcome: if (s.cancel) 2 else 3 },
  }
  // The old policy models retirement without a Scheme handoff drain.
  action reclaimDestination = all {
    s.closing, s.alive, not(s.fixed) or not(s.borrowed),
    s' = { ...s, alive: false },
  }
  action finished = all { s.outcome != 0, s' = s }
  action step = any { cancelRequest, closeAdmission, destinationClaim,
    rollbackQueued, finishDestination, finishRollback, reclaimDestination, finished }
  val lifetimeSafe = s.alive or not(s.borrowed)
  val queueExclusive = s.owner == -1 or s.queued == -1
  val cancellationNotSuccess = not(s.cancel) or s.outcome != 1
  val safe = lifetimeSafe and queueExclusive and cancellationNotSuccess
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.outcome != 0))
}
