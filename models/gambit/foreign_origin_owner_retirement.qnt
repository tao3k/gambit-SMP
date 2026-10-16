module foreign_origin_owner_retirement {
  // One removed OS-thread origin and its retained retirement coordinator.
  // These are semantic roles, not a host CPU limit. A valid callback executes
  // on the thread owning its TLS; an escaping/raw borrowed TLS is a fault control.
  type State = { policy: str, call: int, retirement: int, gate: int,
    leases: int, threadRunning: bool, parked: bool, joined: bool,
    storageAlive: bool, badRead: bool, marker: bool, root: int, epoch: int }
  var s: State
  pure def initial(p: str): State = { policy: p, call: 0,
    retirement: 0, gate: 0, leases: 0, threadRunning: true,
    parked: false, joined: false, storageAlive: true, badRead: false,
    marker: false, root: 7, epoch: 0 }
  action init = s' = initial("owner-join")
  action initBeforeJoin = s' = initial("free-before-join")
  action initBorrowedTLS = s' = initial("unowned-tls")

  // There is no Scheme allocation, interrupt poll or collective acknowledgment
  // between capture and lease publication in the source helper. Retirement can
  // request admission concurrently, but cannot exit/join this running thread.
  action capture = all { s.call == 0, s.threadRunning, not(s.parked),
    s' = { ...s, call: 1, badRead: s.badRead or not(s.storageAlive) } }
  action reserve = all { s.call == 1,
    s' = if (s.gate == 1) { ...s, call: 6 }
      else { ...s, call: 2, gate: 2,
        badRead: s.badRead or not(s.storageAlive) } }
  action publish = all { s.call == 2,
    s' = { ...s, call: 3, gate: 0, leases: 1,
      badRead: s.badRead or not(s.storageAlive) } }
  action allocateMarker = all { s.call == 3,
    s' = { ...s, call: 4, marker: true } }
  // Root relocation abstracts the separately checked marker/root protocol;
  // it is not an implementation of the parallel collector.
  action collect = all { s.call == 4, s.epoch == 0,
    s' = { ...s, epoch: 1, root: 8 } }
  action returnFrame = all { s.call == 4, s' = { ...s, call: 5 } }
  action release = all { s.call == 5,
    s' = { ...s, call: 6, marker: false, leases: 0 } }

  action close = all { s.retirement == 0,
    s' = if (s.gate == 0) { ...s, retirement: 1, gate: 1 }
      else { ...s, retirement: 6 } }
  action inspect = all { s.retirement == 1,
    s' = if (s.leases == 0) { ...s, retirement: 2 }
      else { ...s, retirement: 6, gate: 0 } }
  // A running C admission helper cannot acknowledge retirement in its middle.
  // Before capture, a processor can instead enter the retirement collective.
  action acknowledge = all { s.retirement == 2, not(s.parked),
    Set(0, 6).contains(s.call),
    s' = { ...s, parked: true, call: 6 } }
  action exitThread = all { s.retirement == 2, s.parked, s.threadRunning,
    s' = { ...s, retirement: 3, threadRunning: false } }
  action joinThread = all { s.retirement == 3, not(s.threadRunning),
    s' = { ...s, retirement: 4, joined: true } }
  // A failed join returns a pending-join error without freeing the origin.
  // Recovery/retry belongs to the existing join-failure lifecycle contract.
  action joinFailure = all { s.retirement == 3,
    s' = { ...s, retirement: 7 } }
  action reclaim = all { s.retirement == 4, s.joined, s.leases == 0,
    s' = { ...s, retirement: 5, storageAlive: false } }
  // Injected destruction of origin backing storage before join. This is not
  // an allegation that historical cleanup freed the embedded pstate struct.
  action prematureReclaim = all { s.policy == "free-before-join",
    s.retirement == 2, s.storageAlive,
    s' = { ...s, storageAlive: false } }
  // A raw handle copied to another OS thread violates the owner premise;
  // this is injected, not evidence that public FFI admits such an invocation.
  action borrowedRead = all { s.policy == "unowned-tls",
    s.retirement == 5, not(s.badRead),
    s' = { ...s, badRead: true } }

  val terminal = Set(5, 6, 7).contains(s.retirement) and s.call == 6
  action finished = all { terminal, s' = s }
  action step = any { capture, reserve, publish, allocateMarker, collect,
    returnFrame, release, close, inspect, acknowledge, exitThread,
    joinThread, joinFailure, reclaim, prematureReclaim, borrowedRead, finished }
  val ownerAlive = not(s.threadRunning) or s.storageAlive
  val frameAlive = s.leases == 0 or (s.threadRunning and s.storageAlive)
  val exactLease = s.leases == (if (Set(3, 4, 5).contains(s.call)) 1 else 0)
  val publicationExact = s.gate / 2 == (if (s.call == 2) 1 else 0)
  val rootSafe = not(s.marker) or (s.leases == 1 and s.root == 7 + s.epoch)
  val reclaimSafe = s.storageAlive or (s.joined and s.leases == 0)
  val safe = ownerAlive and frameAlive and exactLease and publicationExact and
    rootSafe and reclaimSafe and not(s.badRead)
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}
