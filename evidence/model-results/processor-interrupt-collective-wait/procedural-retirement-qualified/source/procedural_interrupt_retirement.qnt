module procedural_interrupt_retirement {
  // Three semantic roles, not a host thread-count limit. Sequentially consistent
  // admission and successful join are premises, not an implementation proof.
  // A procedural callback is detached before execute_fn and later relocks.
  type State = { policy: str, writer: str, registryOpen: bool,
    directOpen: bool, reader: str, producer: str, callback: str,
    queue: Set[int], alive: bool, badAccess: bool,
    badWakeTail: bool, badCallback: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, writer: "live", registryOpen: true, directOpen: true,
    reader: "new", producer: "new", callback: "queued", queue: Set(0),
    alive: true, badAccess: false, badWakeTail: false, badCallback: false,
  }
  action init = s' = initial("closed-drained")
  action initRegistryOnly = s' = initial("registry-only")
  action initMutexOnly = s' = initial("ignore-wake-tail")
  action initQueueOnly = s' = initial("ignore-detached-callback")
  action readerEnter = all { s.reader == "new", s.registryOpen,
    s' = { ...s, reader: "use" } }
  action readerUse = all { s.reader == "use",
    s' = { ...s, reader: "done", badAccess: s.badAccess or not(s.alive) } }
  action readerReject = all { s.reader == "new", not(s.registryOpen),
    s' = { ...s, reader: "done" } }
  action enter = all { s.producer == "new", s.directOpen,
    s' = { ...s, producer: "admitted" } }
  action reject = all { s.producer == "new", not(s.directOpen),
    s' = { ...s, producer: "done" } }
  action enqueue = all { s.producer == "admitted",
    s' = { ...s, producer: "locked", queue: s.queue.union(Set(1)),
      badAccess: s.badAccess or not(s.alive) } }
  action unlock = all { s.producer == "locked",
    s' = { ...s, producer: "wake" } }
  // ___raise_interrupt_pstate still touches stack-trip and select-abort here.
  action wake = all { s.producer == "wake",
    s' = { ...s, producer: "done", badAccess: s.badAccess or not(s.alive) } }
  action detach = all { s.callback == "queued", s.writer == "live",
    s' = { ...s, callback: "running", queue: s.queue.exclude(Set(0)) } }
  // Includes execute_fn return AND service loop's subsequent mutex reacquire.
  action callbackReturn = all { s.callback == "running",
    s' = { ...s, callback: "done", badAccess: s.badAccess or not(s.alive) } }
  action close = all { s.writer == "live",
    s' = { ...s, writer: "drain", registryOpen: false,
      directOpen: s.policy == "registry-only" } }
  val producerQuiet = s.producer == "new" or s.producer == "done"
  action drain = all { s.writer == "drain", s.reader != "use",
    producerQuiet or (s.policy == "ignore-wake-tail" and s.producer == "wake"),
    s.callback != "running" or s.policy == "ignore-detached-callback",
    s' = { ...s, writer: "clear" } }
  action clearQueue = all { s.writer == "clear",
    s' = { ...s, writer: "destroy", queue: Set(),
      callback: if (s.callback == "queued") "done" else s.callback } }
  action destroy = all { s.writer == "destroy",
    s' = { ...s, writer: "done", alive: false,
      badWakeTail: s.badWakeTail or s.producer == "wake",
      badCallback: s.badCallback or s.callback == "running" } }
  val terminal = s.writer == "done" and s.producer == "done" and
    s.callback == "done" and s.reader == "done"
  action finished = all { terminal, s' = s }
  action step = any { readerEnter, readerUse, readerReject, enter, reject,
    enqueue, unlock, wake, detach, callbackReturn, close, drain, clearQueue,
    destroy, finished }
  val admissionSafe = not(s.badAccess)
  val wakeTailSafe = not(s.badWakeTail)
  val detachedCallbackSafe = not(s.badCallback)
  val safe = admissionSafe and wakeTailSafe and detachedCallbackSafe
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
  run emptyQueueIsNotQuiescenceTest = init.then(detach)
    .then(all { assert(s.queue == Set()), assert(s.callback == "running"), s' = s })
  run closedAdmissionDrainTest = init.then(enter).then(enqueue).then(unlock)
    .then(close).then(wake).then(drain).then(clearQueue).then(destroy)
    .then(readerReject).then(all { assert(terminal), assert(safe), s' = s })
  run lateDirectControlTest = initRegistryOnly.then(close).then(drain)
    .then(clearQueue).then(destroy).then(enter).then(enqueue)
    .then(all { assert(not(admissionSafe)), s' = s })
  run wakeTailControlTest = initMutexOnly.then(enter).then(enqueue).then(unlock)
    .then(close).then(drain).then(clearQueue).then(destroy)
    .then(all { assert(not(wakeTailSafe)), s' = s })
  run detachedCallbackControlTest = initQueueOnly.then(detach).then(close)
    .then(drain).then(clearQueue).then(destroy)
    .then(all { assert(not(detachedCallbackSafe)), s' = s })
}
