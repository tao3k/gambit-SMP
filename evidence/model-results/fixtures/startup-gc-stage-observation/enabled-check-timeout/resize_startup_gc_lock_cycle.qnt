module resize_startup_gc_lock_cycle {
  // One retained and one new member abstract a wait cycle, not CPU capacity.
  type State = { fixed: bool, needsGC: bool, gc: int, initialized: bool,
    unlocked: bool, returned: bool, waitingLock: bool, enqueued: bool }
  var s: State
  pure def initial(fixed: bool, needsGC: bool): State = {
    fixed: fixed, needsGC: needsGC, gc: 0, initialized: false,
    unlocked: false, returned: false, waitingLock: false, enqueued: false,
  }
  action initOld = s' = initial(false, true)
  action initFixed = {
    nondet needsGC = Set(false, true).oneOf()
    s' = initial(true, needsGC)
  }
  action requestGC = all {
    s.needsGC, s.gc == 0, s' = { ...s, gc: 1 },
  }
  // Startup allocations may need the retained processor's GC participation.
  // A ticket wait with Scheme interrupts disabled cannot service that request.
  action participateOld = all {
    s.gc == 1, not(s.waitingLock), s' = { ...s, gc: 2 },
  }
  action finishGC = all { s.gc == 2, s' = { ...s, gc: 3 } }
  action initialize = all {
    not(s.initialized), not(s.needsGC) or s.gc == 3,
    s' = { ...s, initialized: true },
  }
  action unlock = all {
    s.initialized, not(s.unlocked), s' = { ...s, unlocked: true },
  }
  // The proposed wait must service GC; a busy-spin readiness wait is not fixed.
  action returnResize = all {
    not(s.returned), not(s.fixed) or s.unlocked,
    s' = { ...s, returned: true },
  }
  action startEnqueue = all {
    s.returned, not(s.waitingLock), not(s.enqueued),
    s' = { ...s, waitingLock: true },
  }
  action finishEnqueue = all {
    s.waitingLock, s.unlocked,
    s' = { ...s, waitingLock: false, enqueued: true },
  }
  val terminal = s.enqueued
  action finished = all { terminal, s' = s }
  action step = any { requestGC, participateOld, finishGC, initialize,
    unlock, returnResize, startEnqueue, finishEnqueue, finished }
  val noDeadlock = terminal or enabled(step)
  val ownership = not(s.enqueued) or (s.initialized and s.unlocked)
  val safe = ownership and noDeadlock
  temporal progress = always(noDeadlock) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
