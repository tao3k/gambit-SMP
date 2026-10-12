module gc_queue_wait_composition {
  // Two publishers and two waiters are finite roles, not a host worker setting.
  // Roles are symmetric within each class; no transition depends on ID order.
  type State = { policy: str, fault: str, mode: int -> str,
    pub: int -> int, work: int -> int, queueOwner: int -> int,
    scanOwner: int -> int, scans: int -> int, target: int -> int,
    remaining: int -> Set[int], found: int -> bool, headDone: Set[int],
    mutex: int, count: int, spuriousUsed: Set[int], lost: bool,
    terminated: bool }
  var s: State
  val workers = Set(0, 1, 2, 3)
  val publishers = Set(0, 1)
  pure def initial(policy: str, fault: str): State = {
    policy: policy, fault: fault,
    mode: Map(0 -> "active", 1 -> "active", 2 -> "active", 3 -> "active"),
    pub: Map(0 -> 0, 1 -> 0), work: Map(0 -> 0, 1 -> 0),
    queueOwner: Map(0 -> -1, 1 -> -1), scanOwner: Map(0 -> -1, 1 -> -1),
    scans: Map(0 -> 0, 1 -> 0), target: Map(0 -> -1, 1 -> -1, 2 -> -1, 3 -> -1),
    remaining: Map(0 -> Set(), 1 -> Set(), 2 -> Set(), 3 -> Set()),
    found: Map(0 -> false, 1 -> false, 2 -> false, 3 -> false),
    headDone: Set(), mutex: -1, count: 4, spuriousUsed: Set(),
    lost: false, terminated: false,
  }
  action initOld = s' = initial("source", "none")
  action initNoRestore = s' = initial("combined", "omit-restore")
  action initEarlyIdle = s' = initial("combined", "early-idle")
  action initSource = s' = initial("source", "none")
  action initCombined = s' = initial("combined", "none")
  action init = {
    nondet policy = Set("source", "combined").oneOf()
    s' = initial(policy, "none")
  }
  def ready(w: int): bool = not(publishers.contains(w)) or s.headDone.contains(w)
  val queued = publishers.filter(p => s.work.get(p) == 1)

  action beginPublish = {
    nondet p = publishers.oneOf()
    all { s.mode.get(p) == "active", s.pub.get(p) == 0, s.queueOwner.get(p) == -1,
      s' = { ...s, pub: s.pub.set(p, 1), queueOwner: s.queueOwner.set(p, p) } }
  }
  // A fully copied tail is exported before the producer finishes its eager head.
  action publish = {
    nondet p = publishers.oneOf()
    all { s.pub.get(p) == 1,
      s' = { ...s, pub: s.pub.set(p, 2), work: s.work.set(p, 1) } }
  }
  action releasePublication = {
    nondet p = publishers.oneOf()
    all { s.pub.get(p) == 2,
      s' = { ...s, pub: s.pub.set(p, 3), queueOwner: s.queueOwner.set(p, -1) } }
  }
  action acquireSignalMutex = {
    nondet p = publishers.oneOf()
    all { s.policy == "combined", s.pub.get(p) == 3, s.mutex == -1,
      s' = { ...s, pub: s.pub.set(p, 4), mutex: p } }
  }
  // Signal wakes one registered waiter, not all waiters or a future waiter.
  action signalWork = {
    nondet p = publishers.oneOf()
    val waiting = workers.filter(w => s.mode.get(w) == "waiting")
    nondet wake = (if (waiting == Set()) Set(-1) else waiting).oneOf()
    all { (s.policy == "source" and s.pub.get(p) == 3) or
        (s.policy == "combined" and s.pub.get(p) == 4 and s.mutex == p),
      s' = { ...s, pub: s.pub.set(p, 5),
        mutex: if (s.policy == "combined") -1 else s.mutex,
        mode: if (wake == -1) s.mode else s.mode.set(wake, "woken") } }
  }
  action finishHead = {
    nondet p = publishers.oneOf()
    all { s.pub.get(p) == 5, not(s.headDone.contains(p)),
      s' = { ...s, headDone: s.headDone.union(Set(p)) } }
  }
  action claimQueue = {
    nondet w = workers.oneOf()
    nondet p = publishers.oneOf()
    all { s.mode.get(w) == "active", ready(w), s.work.get(p) == 1,
      s.queueOwner.get(p) == -1,
      s' = { ...s, queueOwner: s.queueOwner.set(p, w),
        target: s.target.set(w, p), mode: s.mode.set(w, "claim-locked") } }
  }
  // Pop under Q, release Q before any scanning. No scan under termination M.
  action popQueue = {
    nondet w = workers.oneOf()
    val p = s.target.get(w)
    all { s.mode.get(w) == "claim-locked", s.work.get(p) == 1,
      s' = { ...s, work: s.work.set(p, 2), scanOwner: s.scanOwner.set(p, w),
        scans: s.scans.set(p, s.scans.get(p) + 1),
        queueOwner: s.queueOwner.set(p, -1), mode: s.mode.set(w, "scanning") } }
  }
  action finishScan = {
    nondet w = workers.oneOf()
    val p = s.target.get(w)
    all { s.mode.get(w) == "scanning",
      s' = { ...s, work: s.work.set(p, 3), scanOwner: s.scanOwner.set(p, -1),
        mode: s.mode.set(w, "active"),
        target: s.target.set(w, -1) } }
  }
  action finalEmptyProbe = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "active", queued == Set(),
      ready(w) or s.fault == "early-idle",
      s' = { ...s, mode: s.mode.set(w, "probed") } }
  }
  action lockTermination = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "probed", s.mutex == -1,
      s' = { ...s, mutex: w, mode: s.mode.set(w, "recheck"),
        remaining: s.remaining.set(w, if (s.policy == "combined") publishers else Set()),
        found: s.found.set(w, false) } }
  }
  // Atomic read-only Q critical section under M. No other same-Q transition
  // can intervene; other-Q actions commute. Lock-order is a separate contract.
  action probeRecheckQueue = {
    nondet w = workers.oneOf()
    nondet p = s.remaining.get(w).oneOf()
    all { s.mode.get(w) == "recheck", s.mutex == w, s.queueOwner.get(p) == -1,
      s' = { ...s,
        remaining: s.remaining.set(w, s.remaining.get(w).exclude(Set(p))),
        found: s.found.set(w, s.found.get(w) or s.work.get(p) == 1) } }
  }
  action countOrRetry = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "recheck", s.remaining.get(w) == Set(), s.mutex == w,
      s' = if (s.found.get(w))
        { ...s, mode: s.mode.set(w, "active"), found: s.found.set(w, false), mutex: -1 }
      else if (s.count == 1)
        { ...s, count: 0, terminated: true, mutex: -1,
          mode: workers.mapBy(x => if (x == w) "done" else
            if (s.mode.get(x) == "waiting") "woken" else s.mode.get(x)) }
      else { ...s, count: s.count - 1, mode: s.mode.set(w, "pre-wait") } }
  }
  action registerWait = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "pre-wait", s.mutex == w,
      s' = { ...s, mode: s.mode.set(w, "waiting"), mutex: -1,
        lost: s.lost or (queued != Set() and queued.forall(p => s.pub.get(p) == 5)) } }
  }
  action spuriousWake = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "waiting", not(s.spuriousUsed.contains(w)),
      s' = { ...s, mode: s.mode.set(w, "woken"), spuriousUsed: s.spuriousUsed.union(Set(w)) } }
  }
  // Reacquire/test/increment is folded under M, with no intervening publication.
  action resume = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "woken", s.mutex == -1,
      s' = if (s.count == 0) { ...s, mode: s.mode.set(w, "done") }
        else { ...s, mode: s.mode.set(w, "active"),
          count: s.count + (if (s.fault == "omit-restore") 0 else 1) } }
  }
  val activeModes = Set("active", "claim-locked", "scanning", "probed", "recheck")
  val counted = workers.filter(w => activeModes.contains(s.mode.get(w))).size()
  val countSafe = s.count == counted and s.count >= 0 and s.count <= workers.size()
  val ownershipSafe = publishers.forall(p => s.scans.get(p) <= 1 and
    (s.work.get(p) != 2 or s.mode.get(s.scanOwner.get(p)) == "scanning"))
  val closureSafe = not(s.terminated) or (s.count == 0 and s.headDone == publishers and
    publishers.forall(p => s.work.get(p) == 3))
  val notificationSafe = not(s.lost)
  val restoreSafe = countSafe
  val producerLifetimeSafe = publishers.forall(p => s.headDone.contains(p) or
    activeModes.contains(s.mode.get(p)))
  val safe = countSafe and ownershipSafe and closureSafe and producerLifetimeSafe and
    (s.policy != "combined" or notificationSafe)
  val sourceSafe = safe
  val combinedSafe = safe
  val terminal = s.terminated and workers.forall(w => s.mode.get(w) == "done")
  action finished = all { terminal, s' = s }
  action step = any { beginPublish, publish, releasePublication, acquireSignalMutex,
    signalWork, finishHead, claimQueue, popQueue, finishScan, finalEmptyProbe,
    lockTermination, probeRecheckQueue, countOrRetry, registerWait,
    spuriousWake, resume, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
