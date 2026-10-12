module thread_processor_lock_gc_cycle {
  // Three protocol roles, not a fixed native CPU population.
  // A owns a thread lock and waits for B's processor lock. C waits for A.
  type State = { fixed: bool, requested: bool, joined: Set[int], gcDone: bool,
    processorLocked: bool, threadLocked: bool, aWaiting: bool, cWaiting: bool,
    aDone: bool, cDone: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, requested: false, joined: Set(), gcDone: false,
    processorLocked: true, threadLocked: true, aWaiting: true, cWaiting: true,
    aDone: false, cDone: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action requestGc = all {
    not(s.requested), s' = { ...s, requested: true, joined: Set(1) },
  }
  // Existing processor-wait helper allows A to participate while holding T.
  action joinA = all {
    s.requested, not(s.joined.contains(0)),
    s' = { ...s, joined: s.joined.union(Set(0)) },
  }
  // Merely fixing processor waits cannot get C past its earlier thread wait.
  action joinC = all {
    s.requested, not(s.joined.contains(2)), not(s.cWaiting) or s.fixed,
    s' = { ...s, joined: s.joined.union(Set(2)) },
  }
  action finishGc = all {
    s.joined == Set(0, 1, 2), not(s.gcDone),
    s' = { ...s, gcDone: true },
  }
  action releaseProcessor = all {
    s.gcDone, s.processorLocked, s' = { ...s, processorLocked: false },
  }
  action finishA = all {
    not(s.processorLocked), not(s.aDone),
    s' = { ...s, aWaiting: false, aDone: true, threadLocked: false },
  }
  action finishC = all {
    not(s.threadLocked), not(s.cDone),
    s' = { ...s, cWaiting: false, cDone: true },
  }
  val terminal = s.gcDone and s.aDone and s.cDone
  action finished = all { terminal, s' = s }
  action step = any { requestGc, joinA, joinC, finishGc,
    releaseProcessor, finishA, finishC, finished }
  val progressPossible = terminal or not(s.requested) or
    (s.requested and not(s.joined.contains(0))) or
    (s.requested and not(s.joined.contains(2)) and (not(s.cWaiting) or s.fixed)) or
    (s.joined == Set(0, 1, 2) and not(s.gcDone)) or
    (s.gcDone and s.processorLocked) or
    (not(s.processorLocked) and not(s.aDone)) or
    (not(s.threadLocked) and not(s.cDone))
  val locksPreserved = (not(s.processorLocked) implies s.gcDone) and
    (not(s.threadLocked) implies s.aDone)
  val safe = progressPossible and locksPreserved
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
