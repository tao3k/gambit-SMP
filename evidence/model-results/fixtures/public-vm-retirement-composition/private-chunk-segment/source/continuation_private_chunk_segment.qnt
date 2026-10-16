module continuation_private_chunk_segment {
  // Chunk IDs are finite proof bounds, not CPU counts or runtime capacities.
  // Existing chunk-link words store the private chain; endpoints are local.
  type State = { early: bool, count: int, closed: int, complete: int,
    privateChunks: Set[int], queued: Set[int], scanned: Set[int],
    done: bool, active: bool, premature: bool }
  var s: State
  action initOld = {
    nondet count = 1.to(4).oneOf()
    s' = { early: true, count: count, closed: 0, complete: 0,
      privateChunks: Set(), queued: Set(), scanned: Set(),
      done: false, active: true, premature: false }
  }
  action init = {
    nondet count = 1.to(4).oneOf()
    s' = { early: false, count: count, closed: 0, complete: 0,
      privateChunks: Set(), queued: Set(), scanned: Set(),
      done: false, active: true, premature: false }
  }
  // A later frame may complete the previous chunk's last frame link.
  action closeChunk = all {
    s.closed < s.count,
    s' = { ...s, closed: s.closed + 1,
      privateChunks: if (s.early) s.privateChunks else s.privateChunks.union(Set(s.closed)),
      queued: if (s.early) s.queued.union(Set(s.closed)) else s.queued }
  }
  action finishLink = all {
    s.complete < s.closed,
    s' = { ...s, complete: s.complete + 1 }
  }
  action finishCopy = all {
    s.closed == s.count, s.complete == s.count, not(s.done),
    s' = { ...s, done: true }
  }
  // One queue-lock release publishes the chain only after all link writes.
  action splice = all {
    s.done, s.privateChunks.size() > 0,
    s' = { ...s, queued: s.queued.union(s.privateChunks), privateChunks: Set() }
  }
  action consume = {
    nondet chunk = s.queued.oneOf()
    s' = { ...s, queued: s.queued.exclude(Set(chunk)),
      scanned: s.scanned.union(Set(chunk)),
      premature: s.premature or chunk >= s.complete }
  }
  // The producing collector remains active until its private work is public.
  action idle = all {
    s.done, s.privateChunks.size() == 0, s.active,
    s' = { ...s, active: false }
  }
  val terminal = s.done and not(s.active) and s.scanned.size() == s.count
  action finished = all { terminal, s' = s }
  action step = any { closeChunk, finishLink, finishCopy, splice, consume, idle, finished }
  val readySafe = not(s.premature)
  val conservation = s.privateChunks.intersect(s.queued).size() == 0 and
    s.privateChunks.intersect(s.scanned).size() == 0 and
    s.queued.intersect(s.scanned).size() == 0 and
    s.privateChunks.union(s.queued).union(s.scanned) == 0.to(s.closed - 1)
  val noHiddenIdle = not(s.active).implies(s.privateChunks.size() == 0 and s.done)
  val endpointsBounded = s.complete <= s.closed and s.closed <= s.count
  val safe = readySafe and conservation and noHiddenIdle and endpointsBounded
  val noStall = terminal or enabled(step)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}
