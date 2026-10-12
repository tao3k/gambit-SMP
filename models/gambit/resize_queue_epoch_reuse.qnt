module resize_queue_epoch_reuse {
  // One queued thread and one delayed publisher target the same permanent slot.
  // Epoch/admission checks below are proposed protocol, not source fields.
  type State = { policy: str, epoch: int, capturedEpoch: int, phase: str,
    admission: bool, locked: bool, queueRetained: bool, queuedMoved: bool,
    publisherDone: bool, publisherMoved: bool, stalePublication: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, epoch: 1, capturedEpoch: 1, phase: "running",
    admission: true, locked: false, queueRetained: true, queuedMoved: false,
    publisherDone: false, publisherMoved: false, stalePublication: false,
  }
  action initFixed = s' = initial("epoch-drain")
  action initDropQueue = s' = initial("drop-queue")
  action initStalePublisher = s' = initial("stale-publisher")
  action acquirePublisher = all {
    not(s.publisherDone), not(s.locked),
    s.admission, s.phase == "running" or s.phase == "reused",
    s.policy == "stale-publisher" or s.capturedEpoch == s.epoch,
    s' = { ...s, locked: true },
  }
  // Revalidate while holding the target lock; a captured pointer is not a lease.
  action rejectStalePublisher = all {
    not(s.publisherDone), not(s.locked), s.policy != "stale-publisher",
    not(s.admission) or s.capturedEpoch != s.epoch,
    s' = { ...s, publisherDone: true, publisherMoved: true },
  }
  action publish = all {
    s.locked, not(s.publisherDone),
    s' = { ...s, locked: false, publisherDone: true,
      publisherMoved: false, queueRetained: true,
      stalePublication: s.capturedEpoch != s.epoch },
  }
  action closeAdmission = all {
    s.phase == "running", not(s.locked),
    s' = { ...s, admission: false, phase: "closed" },
  }
  action drain = all {
    s.phase == "closed", not(s.locked), s.queueRetained,
    s.policy != "drop-queue",
    s' = { ...s, queueRetained: false, queuedMoved: true,
      publisherMoved: s.publisherMoved or s.publisherDone },
  }
  action retire = all {
    s.phase == "closed", not(s.locked),
    not(s.queueRetained) or s.policy == "drop-queue",
    s' = { ...s, phase: "retired" },
  }
  // Source setup clears fields before Scheme run/timeout queue initialization.
  action reuse = all {
    s.phase == "retired", not(s.locked),
    s' = { ...s, epoch: 2, phase: "reused", admission: true,
      queueRetained: false },
  }
  val terminal = s.phase == "reused" and s.publisherDone
  action finished = all { terminal, s' = s }
  action step = any { acquirePublisher, rejectStalePublisher, publish,
    closeAdmission, drain, retire, reuse, finished }
  val queuedRootSurvives = s.queueRetained or s.queuedMoved
  val publicationEpochSafe = not(s.stalePublication)
  val publisherRootSurvives = not(s.publisherDone) or s.publisherMoved or s.queueRetained
  val safe = queuedRootSurvives and publicationEpochSafe and publisherRootSurvives
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
