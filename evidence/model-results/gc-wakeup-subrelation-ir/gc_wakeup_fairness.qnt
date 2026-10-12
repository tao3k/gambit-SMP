module gc_wakeup_fairness {
  import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"

  // Focused scheduler audit from the original Init, not whole-GC termination.
  // The two root producers retain private work; helpers probe empty queues.
  // All copied actions are imported unchanged. Only wake boundedness differs.
  action wakeUnbounded = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "waiting",
      s' = { ...s, mode: s.mode.set(w, "woken") } }
  }

  action helperSteps = any { startProbe, probeEmptyQueue, finishProbe,
    lockTermination, probeRecheckQueue, countOrRetry, registerWait, resume }
  action stepBounded = any { copyWord, helperSteps, spuriousWake }
  action stepUnbounded = any { copyWord, helperSteps, wakeUnbounded }
  action fullUnbounded = any { copyWord, beginPublish, publish, releasePublication,
    acquireSignalMutex, signalWork, finishHead, claimLocal, claimQueue, popQueue, markTail, finishScan,
    startProbe, probeEmptyQueue, finishProbe, lockTermination, probeRecheckQueue,
    countOrRetry, registerWait, wakeUnbounded, resume, finished }

  val copiedRoot = s.copied.get(0) > 0 or s.copied.get(2) > 0
  val focusSafe = safe and not(s.terminated) and s.count >= 2 and
    objects.forall(o => s.work.get(o) == initial(s.policy, "none").work.get(o))

  temporal boundedAggregate = weakFair(step, Set(s)).implies(eventually(copiedRoot))
  temporal unboundedAggregate = weakFair(fullUnbounded, Set(s)).implies(eventually(copiedRoot))
  // This is an explicit scheduling assumption, not a runtime repair.
  temporal unboundedCopyFair = (weakFair(fullUnbounded, Set(s)) and
    weakFair(copyWord, Set(s))).implies(eventually(copiedRoot))
}
