module gc_recursive_queue_wait {
  // Two root producers, two helpers, four processor queues, graph 0 -> 1 -> 0 and
  // 2 -> 3 -> 2. These finite roles are not the host's TLC worker count.
  // Publication is coherent; this is not a C weak-memory refinement.
  type State = { policy: str, fault: str, mode: int -> str,
    work: int -> int, owner: int -> int, copied: int -> int,
    visible: int -> int, pub: int -> int, queueOf: int -> int,
    route: int -> str, queueOwner: int -> int,
    scans: int -> int, target: int -> int, probeIndex: int -> int,
    remaining: int -> Set[int],
    found: int -> bool, headDone: Set[int], tailDone: Set[int],
    headVisits: int -> int, foreignHeadWrite: bool, mutex: int, count: int,
    spuriousUsed: Set[int], staleRead: bool, terminated: bool }
  var s: State
  val workers = Set(0, 1, 2, 3)
  val objects = Set(0, 1, 2, 3)
  val queues = workers
  val edge = Map(0 -> 1, 1 -> 0, 2 -> 3, 3 -> 2)
  // First-occurrence order of the current np=4 steal-index formula. Repeated
  // unsuccessful probes stutter in this abstraction; successful steals may
  // select any queue. Exact 1000-cycle loop refinement remains an obligation.
  val probeOrder = [2, 0, 3, 1]
  val originQueue = Map(0 -> 0, 1 -> 0, 2 -> 1, 3 -> 1)
  // Work: -1 undiscovered, 0 private copy, 1 queued, 2 scanning, 3 scanned.
  pure def initial(policy: str, fault: str): State = {
    policy: policy, fault: fault,
    mode: workers.mapBy(w => "active"),
    work: Map(0 -> 0, 1 -> -1, 2 -> 0, 3 -> -1),
    owner: Map(0 -> 0, 1 -> -1, 2 -> 1, 3 -> -1),
    copied: objects.mapBy(o => 0), visible: objects.mapBy(o => 0),
    pub: objects.mapBy(o => 0), queueOf: objects.mapBy(o => -1),
    route: objects.mapBy(o => ""), queueOwner: queues.mapBy(q => -1),
    scans: objects.mapBy(o => 0), target: workers.mapBy(w => -1),
    probeIndex: workers.mapBy(w => 0),
    remaining: workers.mapBy(w => Set()), found: workers.mapBy(w => false),
    headDone: Set(), tailDone: Set(), headVisits: objects.mapBy(o => 0),
    foreignHeadWrite: false, mutex: -1, count: 4, spuriousUsed: Set(),
    staleRead: false, terminated: false,
  }
  action initEarlyPublish = s' = initial("combined", "early-publication")
  action initDuplicateClaim = s' = initial("combined", "duplicate-claim")
  action initEarlyIdle = s' = initial("combined", "early-idle")
  action initNoRestore = s' = initial("combined", "omit-restore")
  action initLocalReexport = s' = initial("combined", "local-reexport")
  action initWrongQueue = s' = initial("combined", "origin-queue")
  action initScanHead = s' = initial("combined", "scan-head-too")
  action initSkipLocalDrain = s' = initial("combined", "skip-local-drain")
  action initEarlyOwnerRelease = s' = initial("combined", "early-owner-release")
  action initSource = s' = initial("source", "none")
  action initCombined = s' = initial("combined", "none")
  action init = {
    nondet policy = Set("source", "combined").oneOf()
    s' = initial(policy, "none")
  }
  val activeModes = Set("active", "probe", "claim-locked", "scanning", "probed", "recheck")
  val queued = objects.filter(o => s.work.get(o) == 1)
  def queuePending(q: int): bool = queued.exists(o => s.queueOf.get(o) == q)
  // Canonical discovery is separate from copy readiness and scan permission.
  // Marking a tail may recursively copy children before the original scan returns.
  // These pending calls are counted; a complete, unexported child region remains
  // private scan work even after its eager marking calls have returned.
  def markingWork(w: int): bool = objects.exists(o => s.owner.get(o) == w and
    (not(s.headDone.contains(o)) or (s.pub.get(o) > 0 and s.pub.get(o) < 5)))
  def privateWork(w: int): bool = markingWork(w) or
    objects.exists(o => s.owner.get(o) == w and s.work.get(o) == 0)
  def ready(w: int): bool = not(privateWork(w))

  action copyWord = {
    nondet o = objects.oneOf()
    val w = s.owner.get(o)
    all { s.work.get(o) == 0, s.pub.get(o) == 0,
      Set("active", "scanning").contains(s.mode.get(w)), s.copied.get(o) < 2,
      s' = { ...s, copied: s.copied.set(o, s.copied.get(o) + 1) } }
  }
  action beginPublish = {
    nondet o = objects.oneOf()
    val w = s.owner.get(o)
    val q = if (s.fault == "origin-queue") originQueue.get(o) else w
    all { s.pub.get(o) == 0,
      (s.work.get(o) == 0 and Set("active", "scanning").contains(s.mode.get(w))) or
        (s.fault == "local-reexport" and s.work.get(o) == 2 and s.route.get(o) == "local"),
      s.copied.get(o) == 2 or s.fault == "early-publication",
      s.queueOwner.get(q) == -1,
      s' = { ...s, pub: s.pub.set(o, 1), queueOf: s.queueOf.set(o, q),
        queueOwner: s.queueOwner.set(q, w) } }
  }
  action publish = {
    nondet o = objects.oneOf()
    all { s.pub.get(o) == 1,
      s' = { ...s, pub: s.pub.set(o, 2), work: s.work.set(o, 1),
        visible: s.visible.set(o, s.copied.get(o)) } }
  }
  action releasePublication = {
    nondet o = objects.oneOf()
    all { s.pub.get(o) == 2,
      s' = { ...s, pub: s.pub.set(o, 3),
        queueOwner: s.queueOwner.set(s.queueOf.get(o), -1) } }
  }
  action acquireSignalMutex = {
    nondet o = objects.oneOf()
    val w = s.owner.get(o)
    all { s.policy == "combined", s.pub.get(o) == 3, s.mutex == -1,
      s' = { ...s, pub: s.pub.set(o, 4), mutex: w } }
  }
  // A signal selects one currently registered waiter; it is not buffered.
  action signalWork = {
    nondet o = objects.oneOf()
    val w = s.owner.get(o)
    val waiting = workers.filter(x => s.mode.get(x) == "waiting")
    nondet wake = (if (waiting == Set()) Set(-1) else waiting).oneOf()
    all { (s.policy == "source" and s.pub.get(o) == 3) or
        (s.policy == "combined" and s.pub.get(o) == 4 and s.mutex == w),
      s' = { ...s, pub: s.pub.set(o, if (s.work.get(o) == 3) 0 else 5),
        visible: if (s.work.get(o) == 3) s.visible.set(o, 0) else s.visible,
        owner: if (s.work.get(o) == 3 and s.headDone.contains(o)) s.owner.set(o, -1) else s.owner,
        mutex: if (s.policy == "combined") -1 else s.mutex,
        mode: if (wake == -1) s.mode else s.mode.set(wake, "woken") } }
  }
  action finishHead = {
    nondet o = objects.oneOf()
    val w = s.owner.get(o)
    val child = edge.get(o)
    val fresh = s.work.get(child) == -1
    val retired = s.work.get(o) == 3 and (s.pub.get(o) == 0 or s.pub.get(o) == 5)
    all { not(s.headDone.contains(o)), workers.contains(w), s.copied.get(o) == 2,
      Set("active", "scanning").contains(s.mode.get(w)),
      // First-field and tail references share canonical discovery, not ownership.
      s' = { ...s, headDone: s.headDone.union(Set(o)),
        headVisits: s.headVisits.set(o, s.headVisits.get(o) + 1),
        work: if (fresh) s.work.set(child, 0) else s.work,
        owner: (if (retired) s.owner.set(o, -1) else s.owner).set(child,
          if (fresh) w else s.owner.get(child)) } }
  }
  // A copied private region can be scanned by its owner without queue export.
  // The owner's nested marking calls return before it scans its local region.
  action claimLocal = {
    nondet w = workers.oneOf()
    nondet o = objects.oneOf()
    all { s.mode.get(w) == "active", s.owner.get(o) == w,
      s.work.get(o) == 0, s.pub.get(o) == 0, s.copied.get(o) == 2,
      not(markingWork(w)), not(queuePending(w)),
      s' = { ...s, work: s.work.set(o, 2), route: s.route.set(o, "local"),
        scans: s.scans.set(o, s.scans.get(o) + 1),
        target: s.target.set(w, o), mode: s.mode.set(w, "scanning") } }
  }
  action claimQueue = {
    nondet w = workers.oneOf()
    nondet o = queued.oneOf()
    val q = s.queueOf.get(o)
    all { (s.mode.get(w) == "active" and q == w and not(markingWork(w))) or
        (s.mode.get(w) == "probe" and ready(w)), s.queueOwner.get(q) == -1,
      s' = { ...s, queueOwner: s.queueOwner.set(q, w),
        target: s.target.set(w, o), probeIndex: s.probeIndex.set(w, 0),
        mode: s.mode.set(w, "claim-locked") } }
  }
  action popQueue = {
    nondet w = workers.oneOf()
    val o = s.target.get(w)
    all { s.mode.get(w) == "claim-locked", s.work.get(o) == 1,
      // Deliberate fault leaves the region available for a second claim.
      s' = { ...s, work: s.work.set(o, if (s.fault == "duplicate-claim") 1 else 2),
        scans: s.scans.set(o, s.scans.get(o) + 1),
        queueOwner: s.queueOwner.set(s.queueOf.get(o), -1), route: s.route.set(o, "queue"),
        mode: s.mode.set(w, "scanning"),
        staleRead: s.staleRead or s.visible.get(o) != 2,
        foreignHeadWrite: s.foreignHeadWrite or s.fault == "scan-head-too" } }
  }
  // Resolving the tail may install a child's forwarding identity while this
  // processor still owns the parent scan. Copy/eager-head/publication follow.
  action markTail = {
    nondet w = workers.oneOf()
    val o = s.target.get(w)
    val child = edge.get(o)
    val fresh = s.work.get(child) == -1
    all { s.mode.get(w) == "scanning", not(s.tailDone.contains(o)),
      s' = { ...s, tailDone: s.tailDone.union(Set(o)),
        work: if (fresh) s.work.set(child, 0) else s.work,
        owner: if (fresh) s.owner.set(child, w) else s.owner } }
  }
  action finishScan = {
    nondet w = workers.oneOf()
    val o = s.target.get(w)
    val settled = s.pub.get(o) == 0 or s.pub.get(o) == 5
    all { s.mode.get(w) == "scanning", s.tailDone.contains(o), not(markingWork(w)),
      s' = { ...s,
        work: s.work.set(o, 3),
        // Retire only after this object's eager head and publication settle.
        owner: if (settled and (s.headDone.contains(o) or s.fault == "early-owner-release"))
          s.owner.set(o, -1) else s.owner,
        route: s.route.set(o, ""), queueOf: s.queueOf.set(o, -1),
        pub: if (settled) s.pub.set(o, 0) else s.pub,
        visible: if (settled) s.visible.set(o, 0) else s.visible,
        mode: s.mode.set(w, "active"), target: s.target.set(w, -1) } }
  }
  action startProbe = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "active",
      (ready(w) and not(queuePending(w))) or s.fault == "early-idle" or
        (ready(w) and s.fault == "skip-local-drain"),
      s' = { ...s, mode: s.mode.set(w, "probe"), probeIndex: s.probeIndex.set(w, 0) } }
  }
  // An unlocked negative FIFO hint is not an atomic snapshot of other queues.
  action probeEmptyQueue = {
    nondet w = workers.oneOf()
    val index = s.probeIndex.get(w)
    all { s.mode.get(w) == "probe", index < 4,
      not(queuePending(probeOrder.nth(index))),
      s' = { ...s, probeIndex: s.probeIndex.set(w, index + 1) } }
  }
  action finishProbe = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "probe", s.probeIndex.get(w) == 4,
      // Work may have arrived in an already visited queue; do not recheck all
      // queues atomically here. The combined policy rechecks under M later.
      s' = { ...s, mode: s.mode.set(w, "probed"), probeIndex: s.probeIndex.set(w, 0) } }
  }
  action lockTermination = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "probed", s.mutex == -1,
      s' = { ...s, mutex: w, mode: s.mode.set(w, "recheck"),
        remaining: s.remaining.set(w, if (s.policy == "combined") queues else Set()),
        found: s.found.set(w, false) } }
  }
  // Same-Q reads are folded under Q; probes of different queues remain separate.
  action probeRecheckQueue = {
    nondet w = workers.oneOf()
    nondet q = s.remaining.get(w).oneOf()
    all { s.mode.get(w) == "recheck", s.mutex == w, s.queueOwner.get(q) == -1,
      s' = { ...s, remaining: s.remaining.set(w, s.remaining.get(w).exclude(Set(q))),
        found: s.found.set(w, s.found.get(w) or queuePending(q)) } }
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
      s' = { ...s, mode: s.mode.set(w, "waiting"), mutex: -1 } }
  }
  action spuriousWake = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "waiting", not(s.spuriousUsed.contains(w)),
      s' = { ...s, mode: s.mode.set(w, "woken"),
        spuriousUsed: s.spuriousUsed.union(Set(w)) } }
  }
  action resume = {
    nondet w = workers.oneOf()
    all { s.mode.get(w) == "woken", s.mutex == -1,
      s' = if (s.count == 0) { ...s, mode: s.mode.set(w, "done") }
        else { ...s, mode: s.mode.set(w, "active"),
          count: s.count + (if (s.fault == "omit-restore") 0 else 1) } }
  }
  val counted = workers.filter(w => activeModes.contains(s.mode.get(w))).size()
  val countSafe = s.count == counted and s.count >= 0 and s.count <= workers.size()
  val payloadSafe = not(s.staleRead) and objects.forall(o =>
    s.pub.get(o) < 2 or s.visible.get(o) == 2)
  val ownershipSafe = objects.forall(o => s.scans.get(o) <= 1 and
    (s.work.get(o) != 2 or workers.filter(w => s.mode.get(w) == "scanning" and
      s.target.get(w) == o).size() == 1))
  val producerLifetimeSafe = workers.forall(w =>
    privateWork(w).implies(activeModes.contains(s.mode.get(w))))
  val eagerOwnerSafe = objects.forall(o => (s.work.get(o) != -1 and
    (not(s.headDone.contains(o)) or (s.pub.get(o) > 0 and s.pub.get(o) < 5)))
      .implies(workers.contains(s.owner.get(o))))
  val localDrainSafe = workers.forall(w => Set("probe", "probed", "recheck", "pre-wait",
    "waiting", "woken", "done").contains(s.mode.get(w))
      .implies(ready(w) and not(queuePending(w))))
  val fieldPartitionSafe = not(s.foreignHeadWrite) and
    objects.forall(o => s.headVisits.get(o) <= 1 and
      s.headDone.contains(o).implies(s.headVisits.get(o) == 1))
  val closureSafe = not(s.terminated) or (s.count == 0 and s.headDone == objects and
    s.tailDone == objects and objects.forall(o => s.work.get(o) == 3))
  val restoreSafe = countSafe
  val localExportSafe = objects.forall(o => not(s.work.get(o) == 2 and
    s.route.get(o) == "local" and s.pub.get(o) > 0))
  val queueTopologySafe = queued.forall(o => s.queueOf.get(o) == s.owner.get(o))
  val safe = countSafe and payloadSafe and ownershipSafe and producerLifetimeSafe and
    closureSafe and localExportSafe and queueTopologySafe and fieldPartitionSafe and
    eagerOwnerSafe and localDrainSafe
  val sourceSafe = safe
  val combinedSafe = safe
  val terminal = s.terminated and workers.forall(w => s.mode.get(w) == "done")
  action finished = all { terminal, s' = s }
  action step = any { copyWord, beginPublish, publish, releasePublication,
    acquireSignalMutex, signalWork, finishHead, claimLocal, claimQueue, popQueue, markTail, finishScan,
    startProbe, probeEmptyQueue, finishProbe, lockTermination, probeRecheckQueue,
    countOrRetry, registerWait,
    spuriousWake, resume, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
