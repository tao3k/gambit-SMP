module gc_recheck_visibility_completion {
  import gc_recheck_visibility as W from "./gc_recheck_visibility"
  var policy: str

  action initFixed = {
    nondet handoff = Set(false, true).oneOf()
    all {
      policy' = "fixed",
      W::s' = if (handoff) { ...W::initial, producer: "active",
        queued: true, notified: true, acquiredPublication: true }
        else W::initial,
    }
  }
  action initEarlyUnlock = all {
    policy' = "early-unlock", W::s' = W::initial,
  }
  action initUncountedProducer = all {
    policy' = "uncounted-producer", W::s' = W::initial,
  }
  action probe = {
    nondet seen = Set(false, true).oneOf()
    W::recheck(seen)
  }
  // Fault injection: release M before condition registration, not at wait.
  action earlyUnlock = all {
    policy == "early-unlock", W::s.waiter == "recheck",
    W::s.mutex == "waiter",
    W::s' = { ...W::s, waiter: "register-unlocked", mutex: "free",
      count: W::s.count - 1 },
  }
  action lateRegistration = all {
    policy == "early-unlock", W::s.waiter == "register-unlocked",
    W::s.mutex == "free",
    W::s' = { ...W::s, waiter: "waiting" },
  }
  // Fault injection: a producer awaiting M no longer contributes to count.
  action dropProducer = all {
    policy == "uncounted-producer", W::s.producer == "signal",
    W::s' = { ...W::s, producer: "signal-uncounted", count: W::s.count - 1 },
  }
  val noPrematureTermination = not(W::s.terminated)
  val registrationProtected = not(W::s.waiter == "waiting" and
    W::s.producer == "active" and W::s.queued and W::s.notified)
  val safe = W::safe and registrationProtected
  val terminal = W::s.waiter == "active" and W::s.producer == "active"
  action finished = all { terminal, W::s' = W::s }
  action step = all {
    policy' = policy,
    any { W::publish, probe, W::registerWait, W::acquireSignal,
      W::notify, W::releaseSignal, W::resume, earlyUnlock,
      lateRegistration, dropProducer, finished },
  }
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set((W::s, policy))).implies(eventually(terminal))
}
