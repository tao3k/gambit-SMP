module gc_multi_recheck_visibility {
  import gc_recheck_visibility as V from "./gc_recheck_visibility"
  // Abstract semantic roles, not a machine CPU/thread limit.
  pure val waiters = Set(0, 1)
  pure val producers = Set(2, 3)
  type State = { policy: str, producer: int -> str, waiter: int -> str,
    mutex: int, published: Set[int], handedOff: Set[int],
    acquired: int -> Set[int], remaining: int -> Set[int], count: int }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, producer: producers.mapBy(p => "publish"),
    waiter: waiters.mapBy(w => "lock"), mutex: -1,
    published: Set(), handedOff: Set(),
    acquired: waiters.mapBy(w => Set()), remaining: waiters.mapBy(w => producers),
    count: 4,
  }
  action initFixed = s' = initial("fixed")
  action initEarlyUnlock = s' = initial("early-unlock")
  action initIgnoreHandoff = s' = initial("ignore-handoff")
  action publish = {
    nondet p = producers.oneOf()
    all { s.producer.get(p) == "publish",
      s' = { ...s, producer: s.producer.set(p, "signal"),
        published: s.published.union(Set(p)) } }
  }
  action acquireSignal = {
    nondet p = producers.oneOf()
    all { s.producer.get(p) == "signal", s.mutex == -1,
      s' = { ...s, producer: s.producer.set(p, "locked"), mutex: p } }
  }
  action notify = {
    nondet p = producers.oneOf()
    val waiting = waiters.filter(w => s.waiter.get(w) == "waiting")
    nondet wake = (if (waiting == Set()) Set(-1) else waiting).oneOf()
    all { s.producer.get(p) == "locked", s.mutex == p,
      s' = { ...s, producer: s.producer.set(p, "notified"),
        waiter: if (wake == -1) s.waiter else s.waiter.set(wake, "woken") } }
  }
  action releaseSignal = {
    nondet p = producers.oneOf()
    all { s.producer.get(p) == "notified", s.mutex == p,
      s' = { ...s, producer: s.producer.set(p, "active"), mutex: -1,
        handedOff: s.handedOff.union(Set(p)) } }
  }
  action acquireRecheck = {
    nondet w = waiters.oneOf()
    all { s.waiter.get(w) == "lock", s.mutex == -1,
      s' = { ...s, waiter: s.waiter.set(w, "recheck"), mutex: w,
        acquired: s.acquired.set(w, s.handedOff) } }
  }
  action probe = {
    nondet w = waiters.oneOf()
    nondet q = producers.oneOf()
    nondet seen = Set(false, true).oneOf()
    val observation = { ...V::initial, queued: s.published.contains(q),
      acquiredPublication: s.policy != "ignore-handoff" and s.acquired.get(w).contains(q) }
    all { s.waiter.get(w) == "recheck", s.mutex == w,
      s.remaining.get(w).contains(q), s.remaining.get(w).forall(x => x <= q),
      V::allowedRead(observation, seen),
      s' = if (seen) { ...s, waiter: s.waiter.set(w, "active"), mutex: -1,
        remaining: s.remaining.set(w, Set()) }
        else { ...s, remaining: s.remaining.set(w, s.remaining.get(w).exclude(Set(q))) } }
  }
  action countIdle = {
    nondet w = waiters.oneOf()
    all { s.waiter.get(w) == "recheck", s.remaining.get(w) == Set(), s.mutex == w,
      s' = { ...s, count: s.count - 1,
        waiter: s.waiter.set(w, if (s.policy == "early-unlock") "unregistered" else "register"),
        mutex: if (s.policy == "early-unlock") -1 else s.mutex } }
  }
  action registerWait = {
    nondet w = waiters.oneOf()
    all { (s.waiter.get(w) == "register" and s.mutex == w) or
        (s.policy == "early-unlock" and s.waiter.get(w) == "unregistered" and s.mutex == -1),
      s' = { ...s, waiter: s.waiter.set(w, "waiting"), mutex: -1 } }
  }
  action resume = {
    nondet w = waiters.oneOf()
    all { s.waiter.get(w) == "woken", s.mutex == -1,
      s' = { ...s, waiter: s.waiter.set(w, "active"), count: s.count + 1,
        acquired: s.acquired.set(w, s.handedOff) } }
  }
  val counted = producers.size() + waiters.filter(w =>
    Set("lock", "recheck", "active").contains(s.waiter.get(w))).size()
  val countSafe = s.count == counted and s.count >= producers.size()
  val notificationSafe = not(producers.forall(p => s.producer.get(p) == "active") and
    waiters.exists(w => s.waiter.get(w) == "waiting"))
  val earlyRegistrationSafe = notificationSafe
  val handoffVisibilitySafe = notificationSafe
  val ownersValid = s.mutex == -1 or
    (producers.contains(s.mutex) and
      Set("locked", "notified").contains(s.producer.get(s.mutex))) or
    (waiters.contains(s.mutex) and
      Set("recheck", "register").contains(s.waiter.get(s.mutex)))
  val safe = countSafe and notificationSafe and ownersValid
  val terminal = producers.forall(p => s.producer.get(p) == "active") and
    waiters.forall(w => s.waiter.get(w) == "active")
  action finished = all { terminal, s' = s }
  action step = any { publish, acquireSignal, notify, releaseSignal, acquireRecheck,
    probe, countIdle, registerWait, resume, finished }
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
