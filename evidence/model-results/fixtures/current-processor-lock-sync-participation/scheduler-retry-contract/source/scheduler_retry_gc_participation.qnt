module scheduler_retry_gc_participation {
  // A queued thread's owner requests GC; scheduling retries its locked head.
  // Releasing the processor lock does not itself service the pending sync.
  type State = { poll: bool, phase: str, joined: bool, gcDone: bool,
    processorLocked: bool, queuedLocked: bool, returned: bool }
  var s: State
  pure def initial(poll: bool): State = {
    poll: poll, phase: "inspect", joined: false, gcDone: false,
    processorLocked: true, queuedLocked: true, returned: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action failedHeadTrylock = all {
    s.phase == "inspect", s.queuedLocked,
    s' = { ...s, phase: "retry", processorLocked: false },
  }
  action uncheckedRetry = all {
    s.phase == "retry", not(s.poll),
    s' = { ...s, phase: "inspect", processorLocked: true },
  }
  action joinAtUnlockedCheckpoint = all {
    s.phase == "retry", s.poll, not(s.joined),
    s' = { ...s, phase: "collective", joined: true },
  }
  action finishGc = all {
    s.phase == "collective", s.joined, not(s.gcDone),
    s' = { ...s, gcDone: true, phase: "release" },
  }
  action releaseQueued = all {
    s.phase == "release", s.gcDone,
    s' = { ...s, queuedLocked: false, phase: "resume" },
  }
  action resume = all {
    s.phase == "resume", not(s.queuedLocked),
    s' = { ...s, returned: true, phase: "done" },
  }
  val terminal = s.returned
  action finished = all { terminal, s' = s }
  action step = any { failedHeadTrylock, uncheckedRetry,
    joinAtUnlockedCheckpoint, finishGc, releaseQueued, resume, finished }
  // The retry boundary must have a service path, not only runnable steps.
  val serviceable = s.phase != "retry" or s.poll or s.joined
  val unlockedParticipation = s.joined implies not(s.processorLocked)
  val ownerPreserved = not(s.queuedLocked) implies s.gcDone
  val safe = serviceable and unlockedParticipation and ownerPreserved
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
