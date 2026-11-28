module gc_datagram_witness {
  // Two completed callbacks are finite events, not a host CPU limit.
  // Datagram boundaries and nonblocking socket semantics are OS assumptions.
  // No transition proves useful mutator work or original suite termination.
  type State = {
    callbacks: int, sent: Set[int], cursor: int, before: int, renewed: bool,
    event: int, heap: int, baselineHeap: int, portWrites: int,
    blocked: bool, framed: bool, completed: bool,
    expectedPid: int, packetPid: int, expectedCookie: int, packetCookie: int,
    active: bool, sourceBound: bool,
    mutatorClaim: bool, admitted: bool, mode: str
  }
  var s: State
  pure def initial(mode: str): State = {
    callbacks: 0, sent: Set(), cursor: 0, before: 0, renewed: false,
    event: 0, heap: 0, baselineHeap: 0, portWrites: 0,
    blocked: false, framed: true, completed: false,
    expectedPid: 1, packetPid: 1,
    expectedCookie: if (mode == "old-cookie") 2 else 1, packetCookie: 1,
    active: mode != "inactive", sourceBound: mode != "source",
    mutatorClaim: false, admitted: false, mode: mode
  }
  action initFixed = s' = initial("fixed")
  action initAllocating = s' = initial("allocating")
  action initPortWriter = s' = initial("port")
  action initBlocking = s' = initial("blocking")
  action initInterleaved = s' = initial("interleaved")
  action initWrongIdentity = s' = initial("identity")
  action initOldFileCookie = s' = initial("old-cookie")
  action initInactiveChild = s' = initial("inactive")
  action initWrongSource = s' = initial("source")
  action initReplay = s' = initial("replay")
  action initNoise = s' = initial("noise")
  action initMutatorClaim = s' = initial("mutator")
  action initAdmission = s' = initial("admission")

  // Actual post-GC callback entry is the precondition, not a timer tick.
  action callback = all {
    s.callbacks < 2,
    s' = { ...s, callbacks: s.callbacks + 1,
      sent: s.sent.union(Set(s.callbacks + 1)),
      heap: if (s.mode == "allocating") s.heap + 1 else s.heap,
      portWrites: if (s.mode == "port") s.portWrites + 1 else s.portWrites,
      blocked: s.mode == "blocking", renewed: false },
  }
  action receive = {
    nondet n = s.sent.oneOf()
    all {
      s.sent.size() > 0,
      s' = { ...s, sent: s.sent.exclude(Set(n)), event: n, before: s.cursor,
        cursor: if (n > s.cursor) n else s.cursor,
        renewed: n > s.cursor or s.mode == "replay",
        framed: s.mode != "interleaved",
        packetPid: if (s.mode == "identity") 2 else 1,
        completed: true, mutatorClaim: s.mode == "mutator",
        admitted: s.mode == "admission" },
    }
  }
  // Queue overflow, EINTR and reordering may lose evidence, never invent it.
  action drop = {
    nondet n = s.sent.oneOf()
    all { s.sent.size() > 0,
      s' = { ...s, sent: s.sent.exclude(Set(n)), renewed: false } }
  }
  action replay = all {
    s.cursor > 0,
    s' = { ...s, event: s.cursor, before: s.cursor, renewed: s.mode == "replay" },
  }
  action noise = s' = { ...s, event: 0, completed: false,
    renewed: s.mode == "noise" }
  action deliver = any { receive, drop }
  action step = any { callback, deliver, replay, noise }
  val allocationSafe = s.heap == s.baselineHeap
  val portSafe = s.portWrites == 0
  val nonblocking = not(s.blocked)
  val framingSafe = not(s.renewed) or s.framed
  val identitySafe = not(s.renewed) or s.packetPid == s.expectedPid
  val cookieSafe = not(s.renewed) or s.packetCookie == s.expectedCookie
  val activeSafe = not(s.renewed) or s.active
  val sourceSafe = not(s.renewed) or s.sourceBound
  // Replays cannot count as a new delivery. Callback counters may skip values.
  val replaySafe = not(s.renewed) or s.event > s.before
  val completionSafe = not(s.renewed) or s.completed
  val attributionSafe = not(s.mutatorClaim)
  val admissionSafe = not(s.admitted)
  val safe = allocationSafe and portSafe and nonblocking and framingSafe and
    identitySafe and cookieSafe and activeSafe and sourceSafe and replaySafe and
    completionSafe and attributionSafe and admissionSafe
  // Fair delivery can drain the finite transport. No fairness is imposed on
  // the application's production of GC events or on mutator termination.
  temporal drain = weakFair(deliver, s).implies(
    always((s.sent.size() > 0).implies(eventually(s.sent.size() == 0))))
}
