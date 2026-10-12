module gc_wait_notification {
  // One producer/helper, one chunk, and at most one spurious helper wake.
  type State = { policy: str, producer: str, helper: str, mutex: str,
    count: int, queued: bool, chunkDone: bool, headDone: bool,
    signalDone: bool, terminated: bool, lost: bool, spuriousUsed: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, producer: "pending", helper: "active", mutex: "none",
    count: 2, queued: false, chunkDone: false, headDone: false,
    signalDone: false, terminated: false, lost: false, spuriousUsed: false,
  }
  action initOld = s' = initial("source")
  action initSignalOnly = s' = initial("signal-only")
  action initRecheckOnly = s' = initial("recheck-only")
  action init = {
    nondet policy = Set("source", "signal-only", "recheck-only", "both").oneOf()
    s' = initial(policy)
  }
  val protectsSignal = Set("signal-only", "both").contains(s.policy)
  val rechecksQueue = Set("recheck-only", "both").contains(s.policy)
  action publish = all {
    s.producer == "pending",
    s' = { ...s, producer: "published", queued: true },
  }
  // Work notification is not buffered when no waiter has registered.
  action signalWork = all {
    s.producer == "published", not(s.signalDone),
    not(protectsSignal) or s.mutex == "none",
    s' = { ...s, signalDone: true,
      helper: if (s.helper == "waiting") "woken" else s.helper },
  }
  action producerReturns = all {
    s.producer == "published", s.signalDone,
    s' = { ...s, producer: "returned", headDone: true },
  }
  action producerDrains = all {
    s.producer == "returned", s.queued,
    s' = { ...s, queued: false, chunkDone: true },
  }
  action helperSteals = all {
    s.helper == "active", s.queued,
    s' = { ...s, helper: "busy", queued: false },
  }
  action helperFinishes = all {
    s.helper == "busy",
    s' = { ...s, helper: "active", chunkDone: true },
  }
  action helperProbesEmpty = all {
    s.helper == "active", not(s.queued),
    s' = { ...s, helper: "probed" },
  }
  action helperLocks = all {
    s.helper == "probed", s.mutex == "none",
    s' = { ...s, helper: "locked", mutex: "helper" },
  }
  action helperCounts = all {
    s.helper == "locked", s.mutex == "helper",
    s' = if (rechecksQueue and s.queued)
      { ...s, helper: "active", mutex: "none" }
    else if (s.count == 1)
      { ...s, helper: "done", mutex: "none", count: 0, terminated: true,
        producer: if (s.producer == "waiting") "done" else s.producer }
    else { ...s, helper: "pre-wait", count: s.count - 1 },
  }
  // POSIX wait atomically registers the waiter and releases its mutex.
  action registerWait = all {
    s.helper == "pre-wait", s.mutex == "helper",
    s' = { ...s, helper: "waiting", mutex: "none",
      lost: s.lost or (s.signalDone and s.queued) },
  }
  action spuriousWake = all {
    s.helper == "waiting", not(s.spuriousUsed),
    s' = { ...s, helper: "woken", spuriousUsed: true },
  }
  action helperResumes = all {
    s.helper == "woken", s.mutex == "none",
    s' = if (s.count == 0) { ...s, helper: "done" }
      else { ...s, helper: "active", count: s.count + 1 },
  }
  // No further producer work exists here. Its count/wait/termination signal
  // uses the same mutex; unlike signalWork it cannot cross registerWait.
  action producerIdle = all {
    s.producer == "returned", not(s.queued), s.mutex == "none",
    s' = if (s.count == 1)
      { ...s, producer: "done", count: 0, terminated: true,
        helper: if (s.helper == "waiting") "woken" else s.helper }
    else { ...s, producer: "waiting", count: s.count - 1 },
  }
  val counted = (if (Set("pending", "published", "returned").contains(s.producer)) 1 else 0)
    + (if (Set("active", "busy", "probed", "locked").contains(s.helper)) 1 else 0)
  val closureSafe = s.count == counted and s.count >= 0 and s.count <= 2 and
    (not(s.terminated) or (s.count == 0 and s.headDone and s.chunkDone and not(s.queued)))
  val notificationSafe = not(s.lost)
  val signalOnlyWakeSafe = notificationSafe
  val recheckOnlyWakeSafe = notificationSafe
  val guardSound = closureSafe and (s.policy != "both" or notificationSafe)
  val terminal = s.terminated and s.producer == "done" and s.helper == "done"
  action finished = all { terminal, s' = s }
  action step = any { publish, signalWork, producerReturns, producerDrains,
    helperSteals, helperFinishes, helperProbesEmpty, helperLocks, helperCounts,
    registerWait, spuriousWake, helperResumes, producerIdle, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
