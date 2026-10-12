module gc_recheck_visibility {
  // One queue publication and one waiter, with successful POSIX operations.
  // A stale predicate is not a payload read; the source scans only after stealing.
  type State = { mutex: str, producer: str, waiter: str, queued: bool,
    notified: bool, acquiredPublication: bool, count: int, terminated: bool }
  var s: State
  pure val initial: State = { mutex: "waiter", producer: "publish",
    waiter: "recheck", queued: false, notified: false,
    acquiredPublication: false, count: 2, terminated: false }
  action init = s' = initial
  action publish = all { s.producer == "publish",
    s' = { ...s, queued: true, producer: "signal" } }
  action recheck(seen: bool): bool = all {
    s.waiter == "recheck", s.mutex == "waiter",
    seen.implies(s.queued),
    (s.acquiredPublication and s.queued).implies(seen),
    s' = if (seen) { ...s, waiter: "active", mutex: "free" }
      else { ...s, waiter: "register", count: s.count - 1,
        terminated: s.count == 1 }
  }
  action registerWait = all { s.waiter == "register", s.mutex == "waiter",
    s' = { ...s, waiter: "waiting", mutex: "free" } }
  action acquireSignal = all { s.producer == "signal", s.mutex == "free",
    s' = { ...s, producer: "signal-locked", mutex: "producer" } }
  action notify = all { s.producer == "signal-locked", s.mutex == "producer",
    s' = { ...s, notified: true,
      waiter: if (s.waiter == "waiting") "woken" else s.waiter } }
  action releaseSignal = all { s.producer == "signal-locked", s.notified,
    s' = { ...s, producer: "active", mutex: "free" } }
  action resume = all { s.waiter == "woken", s.mutex == "free",
    s' = { ...s, waiter: "active", count: s.count + 1,
      acquiredPublication: true } }
  val counted = 1 + (if (Set("register", "waiting", "woken")
    .contains(s.waiter)) 0 else 1)
  val safe = s.count == counted and not(s.terminated)

  run publicationBeforeRegistrationTest = init.then(publish).then(recheck(false))
    .expect(s.waiter == "register" and s.count == 1 and not(s.terminated))
  run stalePredicateStillGetsNotificationTest = init.then(publish)
    .then(recheck(false)).then(registerWait).then(acquireSignal).then(notify)
    .then(releaseSignal).then(resume)
    .expect(safe and s.waiter == "active" and s.acquiredPublication)
  run publicationAfterRegistrationTest = init.then(recheck(false))
    .then(registerWait).then(publish).then(acquireSignal).then(notify)
    .then(releaseSignal).then(resume).expect(safe and s.waiter == "active")
  run visiblePredicateRetainsOwnershipTest = init.then(publish).then(recheck(true))
    .expect(safe and s.count == 2 and s.waiter == "active")

  // Represents a later M acquisition after the completed producer unlock.
  // It is a separate ordering premise, not an assertion about ticket-lock acquire.
  action initAfterHandoff = s' = { ...initial, producer: "active",
    queued: true, notified: true, acquiredPublication: true }
  pure def allowedRead(st: State, seen: bool): bool =
    seen.implies(st.queued) and (st.acquiredPublication and st.queued).implies(seen)
  run completedMutexHandoffRequiresVisibilityTest = initAfterHandoff
    .expect(not(allowedRead(s, false)) and allowedRead(s, true))
}
