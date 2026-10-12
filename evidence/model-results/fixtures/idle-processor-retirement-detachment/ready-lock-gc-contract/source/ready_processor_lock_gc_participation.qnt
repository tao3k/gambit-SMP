module ready_processor_lock_gc_participation {
  // Readiness does not imply that the peer can never reacquire its lock.
  type State = { fixed: bool, needsGc: bool, requested: bool, gcDone: bool,
    locked: bool, waiting: bool, enqueued: bool }
  var s: State
  pure def initial(fixed: bool, needsGc: bool): State = {
    fixed: fixed, needsGc: needsGc, requested: false, gcDone: false,
    locked: true, waiting: false, enqueued: false,
  }
  action initOld = s' = initial(false, true)
  action initFixed = {
    nondet needsGc = Set(false, true).oneOf()
    s' = initial(true, needsGc)
  }
  action requestGc = all {
    s.needsGc, not(s.requested), s' = { ...s, requested: true },
  }
  action requesterParticipates = all {
    s.requested, not(s.gcDone), not(s.waiting) or s.fixed,
    s' = { ...s, gcDone: true },
  }
  action releaseLock = all {
    s.locked, not(s.needsGc) or s.gcDone, s' = { ...s, locked: false },
  }
  action startEnqueue = all {
    not(s.waiting), not(s.enqueued), s' = { ...s, waiting: true },
  }
  action finishEnqueue = all {
    s.waiting, not(s.locked), not(s.enqueued),
    s' = { ...s, waiting: false, enqueued: true },
  }
  val terminal = s.enqueued and (not(s.needsGc) or s.gcDone)
  action finished = all { terminal, s' = s }
  action step = any { requestGc, requesterParticipates, releaseLock,
    startEnqueue, finishEnqueue, finished }
  // Explicit enabling predicates avoid the earlier enabled(step) checker route.
  val progressPossible = terminal or
    (s.needsGc and not(s.requested)) or
    (s.requested and not(s.gcDone) and (not(s.waiting) or s.fixed)) or
    (s.locked and (not(s.needsGc) or s.gcDone)) or
    (not(s.waiting) and not(s.enqueued)) or
    (s.waiting and not(s.locked) and not(s.enqueued))
  val ownership = not(s.enqueued) or not(s.locked)
  val safe = ownership and progressPossible
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
