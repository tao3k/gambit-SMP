module gc_chunk_cursor_operations {
  // Source-directed per-arena cursor/FIFO operations. Addresses are words.
  // Each object has one eager-owned field and one scanner-owned tail field.
  // P0 owns this arena's allocation cursor; P1 only steals from its FIFO.
  pure val addresses = (-1).to(192)
  type State = { fault: int, rootCopies: int, extraCopies: int, roots: bool,
    alloc: int, start: int, limit: int, savedScan: int,
    mainPtr: int, taskPtr: int, thiefPtr: int, head: int, tail: int,
    kind: int -> int, link: int -> int, field: int -> int,
    visits: int -> int, objects: Set[int],
    phase: str, thief: str, done: bool, badInput: bool, badHeader: bool,
    lateClaim: int, continuation: bool, privateFirst: int, privateLast: int,
    pendingLinks: Set[int], section: int, sectionLimit: int,
    shareStack: bool, stackLow: int, badReuse: bool, badOverlap: bool,
    generation: int -> int, freeHead: int, peerBase: int }
  var s: State
  pure def initial(fault: int, copies: int): State = {
    fault: fault, rootCopies: copies, extraCopies: 2, roots: true,
    alloc: 1, start: 1, limit: 7, savedScan: 1,
    mainPtr: 1, taskPtr: 0, thiefPtr: 0, head: -1, tail: -1,
    kind: addresses.mapBy(_ => 0), link: addresses.mapBy(_ => 0),
    field: addresses.mapBy(_ => 0), visits: addresses.mapBy(_ => 0),
    objects: Set(), phase: "local", thief: "idle", done: false,
    badInput: false, badHeader: false, lateClaim: 0, continuation: false,
    privateFirst: 0, privateLast: 0, pendingLinks: Set(),
    section: 0, sectionLimit: 14, shareStack: false, stackLow: 46,
    badReuse: false, badOverlap: false, generation: addresses.mapBy(_ => -1),
    freeHead: 128, peerBase: -1,
  }
  action init = {
    nondet copies = 1.to(4).oneOf()
    nondet continuation = Set(false, true).oneOf()
    nondet shareStack = Set(false, true).oneOf()
    nondet stackLow = 46.to(48).oneOf()
    s' = { ...initial(0, copies), continuation: continuation,
      shareStack: shareStack, stackLow: stackLow }
  }
  action initPublishLocal = s' = initial(1, 2)
  action initLateClaim = s' = initial(2, 4)
  action initRewindLocal = s' = initial(3, 4)
  action initEarlyPrivatePublication = s' = { ...initial(4, 2), continuation: true }
  action initReuseSection = s' = initial(5, 4)
  action initMissingAllocationClaim = s' = initial(6, 4)

  // mark_array: body copy completes, threshold closes chunk, then start moves.
  // The FIFO update is one lock-protected transaction, not a uniqueness guard.
  pure def closeChunk(a: State): State = {
      val closed = { ...a, alloc: a.alloc + 1,
        kind: a.kind.set(a.alloc, 3), link: a.link.set(a.alloc, 0) }
      val publish = a.fault == 1 or not(a.savedScan >= a.start and a.savedScan < a.alloc + 1)
      val queued = if (not(publish)) closed
        else if (a.continuation and a.fault != 4) { ...closed,
          privateFirst: if (a.privateFirst == 0) a.start - 1 else a.privateFirst,
          privateLast: a.start - 1,
          link: if (a.privateFirst == 0) closed.link
            else closed.link.set(a.privateLast, a.start - 1) }
        else { ...closed, link: closed.link.set(a.tail, a.start - 1), tail: a.start - 1 }
      queued
  }
  pure def startChunk(a: State): State = { ...a, start: a.alloc, limit: a.alloc + 6 }
  // next_heap_msection + prepare_heap_msection. Exhaustion closes even an
  // empty chunk. The new section first gets its prefix marker, not an object.
  // Unit fudge=1 preserves the source's quarter-gap arithmetic and two markers.
  pure def rollover(a: State): State = {
    val closed = closeChunk(a)
    val base = if (a.fault == 5) 0 else if (a.shareStack) 32 else a.freeHead
    val quarter = (a.stackLow - 32 - 2) / 4
    val limit = if (a.shareStack) base + 3 * quarter + 1 - 2 else base + 14
    startChunk({ ...closed, alloc: base + 1, section: a.section + 1,
      sectionLimit: limit, kind: closed.kind.set(base, 3),
      link: closed.link.set(base, 0),
      freeHead: if (a.shareStack) a.freeHead else a.freeHead + 32 })
  }
  pure def allocate(a: State): State = {
    val ready = if (a.alloc + 3 > a.sectionLimit) rollover(a) else a
    val end = ready.alloc + 3
    val copied = { ...ready, alloc: end,
      kind: ready.kind.set(ready.alloc, 1).set(ready.alloc + 2, 2),
      field: ready.field.set(ready.alloc + 2, if (ready.continuation) 2 else 0),
      pendingLinks: if (ready.continuation) ready.pendingLinks.union(Set(ready.alloc + 2)) else ready.pendingLinks,
      objects: ready.objects.union(Set(ready.alloc)),
      generation: ready.generation.set(ready.alloc, ready.section),
      badReuse: ready.badReuse or ready.objects.contains(ready.alloc),
      badOverlap: ready.badOverlap or (ready.shareStack and ready.section > 0
        and end > ready.stackLow) }
    if (end < ready.limit) copied else startChunk(closeChunk(copied))
  }
  // mark_captured_continuation resolves frame links before publishing its
  // private segment. Queued scanners do not acquire the producer's misc lock.
  pure def finishBatch(a: State): State = {
    val resolved = { ...a, pendingLinks: Set(),
      field: a.pendingLinks.fold(a.field, (payload, p) => payload.set(p, 0)) }
    if (a.privateFirst == 0) resolved else { ...resolved,
      link: resolved.link.set(a.tail, a.privateFirst), tail: a.privateLast,
      privateFirst: 0, privateLast: 0 }
  }
  action rootCopy = all { s.roots, s.rootCopies > 0,
    s' = { ...allocate(s), rootCopies: s.rootCopies - 1 } }
  action rootBarrier = all { s.roots, s.rootCopies == 0,
    s' = { ...finishBatch(s), roots: false } }

  // scan_and_advance may recursively allocate before its caller's local ptr
  // advances. savedScan stays at the source's last saved boundary meanwhile.
  action beginLocalScan = all { not(s.roots), s.phase == "local",
    s.mainPtr != s.alloc, s.kind.get(s.mainPtr) != 3,
    s' = { ...s, phase: "callback-local",
      visits: s.visits.set(s.mainPtr, s.visits.get(s.mainPtr) + 1),
      field: s.field.set(s.mainPtr + 2, 1),
      badHeader: s.badHeader or s.kind.get(s.mainPtr) != 1,
      badInput: s.badInput or s.field.get(s.mainPtr + 2) != 0 } }
  action callbackCopy = all { s.phase == "callback-local" or s.phase == "callback-queued",
    s.extraCopies > 0, s' = { ...allocate(s), extraCopies: s.extraCopies - 1 } }
  action returnLocalScan = all { s.phase == "callback-local",
    s' = { ...finishBatch(s), mainPtr: s.mainPtr + 3, phase: "local" } }
  action localMarker = all { not(s.roots), s.phase == "local",
    s.mainPtr != s.alloc, s.kind.get(s.mainPtr) == 3,
    s' = { ...s, savedScan: s.mainPtr, phase: "queue" } }
  action localCaughtUp = all { not(s.roots), s.phase == "local", s.mainPtr == s.alloc,
    s' = { ...s, savedScan: s.mainPtr, phase: "idle" } }

  // scan_movable_objs_to_scan and the thief claim the SAME head under Q.
  // The head is advanced before either releases Q and scans the payload.
  action ownClaim = all { not(s.roots), s.phase == "queue", s.head != s.tail,
    {
      val prefix = s.link.get(s.head)
      s' = { ...s, head: prefix, taskPtr: prefix + 1, phase: "queued" }
    } }
  action thiefClaim = all { not(s.roots), s.thief == "idle", s.head != s.tail,
    {
      val prefix = s.link.get(s.head)
      s' = { ...s, head: if (s.fault == 2) s.head else prefix,
        thiefPtr: prefix + 1, thief: "scan", lateClaim: prefix }
    } }
  action beginQueuedScan = all { s.phase == "queued", s.kind.get(s.taskPtr) != 3,
    s' = { ...s, phase: "callback-queued",
      visits: s.visits.set(s.taskPtr, s.visits.get(s.taskPtr) + 1),
      field: s.field.set(s.taskPtr + 2, 1),
      badHeader: s.badHeader or s.kind.get(s.taskPtr) != 1,
      badInput: s.badInput or s.field.get(s.taskPtr + 2) != 0 } }
  action returnQueuedScan = all { s.phase == "callback-queued",
    s' = { ...finishBatch(s), taskPtr: s.taskPtr + 3, phase: "queued" } }
  action ownChunkDone = all { s.phase == "queued", s.kind.get(s.taskPtr) == 3,
    s' = { ...s, phase: "queue" } }
  action thiefScan = all { s.thief == "scan", s.kind.get(s.thiefPtr) != 3,
    s' = { ...s, thiefPtr: s.thiefPtr + 3,
      visits: s.visits.set(s.thiefPtr, s.visits.get(s.thiefPtr) + 1),
      field: s.field.set(s.thiefPtr + 2, 1),
      badHeader: s.badHeader or s.kind.get(s.thiefPtr) != 1,
      badInput: s.badInput or s.field.get(s.thiefPtr + 2) != 0 } }
  action thiefChunkDone = all { s.thief == "scan", s.kind.get(s.thiefPtr) == 3,
    s' = { ...s, thief: "idle", head: if (s.fault == 2) s.lateClaim else s.head } }
  action resumeIncomplete = all { s.phase == "queue", s.head == s.tail,
    {
      val ptr = if (s.fault == 3) 1 else s.start
      s' = { ...s, mainPtr: ptr, savedScan: ptr, phase: "local" }
    } }
  action finish = all { s.phase == "idle", s.thief == "idle", s.head == s.tail,
    s' = { ...s, done: true } }
  // Project a second processor's section request onto the SAME locked VM
  // free-list cursor. Its payload arena is not scanned by this component.
  action peerReserve = all { not(s.shareStack), s.peerBase == -1,
    s' = { ...s, peerBase: s.freeHead,
      freeHead: if (s.fault == 6) s.freeHead else s.freeHead + 32 } }
  action advance = any { rootCopy, rootBarrier, beginLocalScan, callbackCopy,
    returnLocalScan, localMarker, localCaughtUp, ownClaim, thiefClaim,
    beginQueuedScan, returnQueuedScan, ownChunkDone, thiefScan, thiefChunkDone,
    resumeIncomplete, peerReserve, finish }
  action step = any { all { not(s.done), advance }, s' = s }

  val physicalSlotSafe = not(s.badInput) and not(s.badHeader)
    and s.objects.forall(p => s.visits.get(p) <= 1)
  val completionSafe = not(s.done) or s.objects.forall(p => s.visits.get(p) == 1)
  val allocatorSafe = s.peerBase == -1 or s.objects.forall(p =>
    p + 3 <= s.peerBase or p >= s.peerBase + 16)
  val safe = physicalSlotSafe and completionSafe and not(s.badReuse) and not(s.badOverlap)
    and allocatorSafe
  temporal completion = weakFair(advance, s).implies(eventually(s.done))
}
