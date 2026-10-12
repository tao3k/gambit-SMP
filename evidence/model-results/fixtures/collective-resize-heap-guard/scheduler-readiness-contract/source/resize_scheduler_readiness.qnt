module resize_scheduler_readiness {
  // One new slot abstracts scheduler readiness, not host CPU capacity.
  type State = { fixed: bool, resultConsumed: bool, noopAcknowledged: bool,
    initialized: bool, unlocked: bool, returned: bool, enqueueRequested: bool,
    enqueued: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, resultConsumed: false, noopAcknowledged: false,
    initialized: false, unlocked: false, returned: false,
    enqueueRequested: false, enqueued: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action consumeResult = all {
    not(s.resultConsumed), s' = { ...s, resultConsumed: true },
  }
  action acknowledgeNoop = all {
    s.resultConsumed, not(s.noopAcknowledged),
    s' = { ...s, noopAcknowledged: true },
  }
  action initializeScheduler = all {
    s.noopAcknowledged, not(s.initialized),
    s' = { ...s, initialized: true },
  }
  action unlockScheduler = all {
    s.initialized, not(s.unlocked), s' = { ...s, unlocked: true },
  }
  action returnResize = all {
    s.noopAcknowledged, not(s.returned), not(s.fixed) or s.unlocked,
    s' = { ...s, returned: true },
  }
  action requestEnqueue = all {
    s.returned, not(s.enqueueRequested),
    s' = { ...s, enqueueRequested: true },
  }
  action enqueue = all {
    s.enqueueRequested, s.unlocked, not(s.enqueued),
    s' = { ...s, enqueued: true },
  }
  val readyAtReturn = not(s.returned) or (s.initialized and s.unlocked)
  val queueOwnership = not(s.enqueued) or s.unlocked
  val terminal = s.enqueued
  action finished = all { terminal, s' = s }
  action step = any { consumeResult, acknowledgeNoop, initializeScheduler,
    unlockScheduler, returnResize, requestEnqueue, enqueue, finished }
  val noDeadlock = terminal or enabled(step)
  val safe = readyAtReturn and queueOwnership and noDeadlock
  temporal progress = always(noDeadlock) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
