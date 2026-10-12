module gc_recursive_wait_recheck {
  import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"

  // The audited source rechecks queues in descending processor order and returns on
  // the first pending queue. The other 20 original action branches are kept.
  def recheckReady(w: int, q: int): bool =
    s.mode.get(w) == "recheck" and s.mutex == w and
    s.remaining.get(w).contains(q) and s.remaining.get(w).forall(x => x <= q) and
    s.queueOwner.get(q) == -1
  action recheckQueue(w: int, q: int): bool = all {
    recheckReady(w, q),
    s' = if (queuePending(q))
      { ...s, mode: s.mode.set(w, "active"), mutex: -1,
        remaining: s.remaining.set(w, Set()), found: s.found.set(w, false) }
    else
      { ...s, remaining: s.remaining.set(w, s.remaining.get(w).exclude(Set(q))) }
  }
  action orderedRecheck = {
    nondet w = workers.oneOf()
    nondet q = queues.oneOf()
    recheckQueue(w, q)
  }

  // Condition returns are not bounded by the once-per-worker test budget.
  action conditionReturn(w: int): bool = all {
    s.mode.get(w) == "waiting",
    s' = { ...s, mode: s.mode.set(w, "woken") }
  }
  action unboundedWake = {
    nondet w = workers.oneOf()
    conditionReturn(w)
  }

  action sourceWaitInit = initCombined
  action sourceWaitStep = any { copyWord, beginPublish, publish, releasePublication,
    acquireSignalMutex, signalWork, finishHead, claimLocal, claimQueue, popQueue,
    markTail, finishScan, startProbe, probeEmptyQueue, finishProbe, lockTermination,
    orderedRecheck, countOrRetry, registerWait, unboundedWake, resume, finished }

  // These are candidate obligations, not completed proof or C refinement.
  val sourceWaitSafety = safe
  temporal aggregateProgress = weakFair(sourceWaitStep, Set(s))
    .implies(eventually(terminal))
}
