// Experimental, sequentially consistent interleavings. Not a Gambit collector.
// Holders 10/11 are old/still roots; 1/2 are snapshot-live young objects.
// Allocation 3 is born black. No weak fields, arbitrary graph or progress proof.
module ConcurrentSATB {
  type State = { phase: str, policy: str, writer: int, edges: int -> int,
    cards: Set[int], scanned: Set[int], marked: Set[int],
    privateLog: Set[int], publishedLog: Set[int] }
  var s: State
  pure def initial(policy: str): State = {
    phase: "mark", policy: policy, writer: 0,
    edges: Map(10 -> 1, 11 -> 2),
    cards: if (policy == "omit-still-card") Set(10) else Set(10, 11),
    scanned: Set(), marked: Set(), privateLog: Set(), publishedLog: Set()
  }
  action init = s' = initial("checked")
  action initNoBarrier = s' = initial("omit-pre-barrier")
  action initEarlyCompletion = s' = initial("ignore-private-log")
  action initNoStillCard = s' = initial("omit-still-card")
  action allocate = all { s.phase == "mark", s.writer == 0,
    s' = { ...s, writer: 1, marked: s.marked.union(Set(3)) } }
  action preWrite = all { s.phase == "mark", s.writer == 1,
    s' = { ...s, writer: 2, privateLog:
      if (s.policy == "omit-pre-barrier") s.privateLog
      else s.privateLog.union(Set(s.edges.get(10))) } }
  action store = all { s.phase == "mark", s.writer == 2,
    s' = { ...s, writer: 3, edges: s.edges.set(10, 3) } }
  action finishWriter = all { s.phase == "mark", s.writer == 3,
    s' = { ...s, writer: 4 } }
  action publishLog = all { s.phase == "mark", s.privateLog.size() > 0,
    s' = { ...s, publishedLog: s.publishedLog.union(s.privateLog), privateLog: Set() } }
  action drainLog = all { s.phase == "mark", s.publishedLog.size() > 0,
    s' = { ...s, marked: s.marked.union(s.publishedLog), publishedLog: Set() } }
  action scan(holder: int): bool = all {
    s.phase == "mark", s.cards.contains(holder), not(s.scanned.contains(holder)),
    s' = { ...s, scanned: s.scanned.union(Set(holder)),
      marked: s.marked.union(Set(s.edges.get(holder))) }
  }
  // This terminal handshake stops admission. It is not a zero-pause claim.
  action complete = all {
    s.phase == "mark", s.writer == 0 or s.writer == 4,
    s.cards.subseteq(s.scanned), s.publishedLog.size() == 0,
    s.privateLog.size() == 0 or s.policy == "ignore-private-log",
    s' = { ...s, phase: "complete" }
  }
  action step = any { allocate, preWrite, store, finishWriter,
    publishLog, drainLog, scan(10), scan(11), complete }
  val Safe = s.phase == "complete" implies Set(1, 2).subseteq(s.marked)
}
