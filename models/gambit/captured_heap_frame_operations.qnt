module captured_heap_frame_operations {
  // Word-address projection of mark_captured_continuation -> scan(sFRAME)
  // -> break-handler heap return. Mutators stop; one shared MISC copy lock.
  // RA labels are permanent. No weak-memory or arbitrary stack-layout proof.
  pure val frames = Set(0, 1)
  pure val roots = Set(1, 2)
  pure val cells = 64.to(88).union(120.to(144))
  pure val endMarker = -36
  pure val breakLabel = 3001
  pure def label(frame: int): int = if (frame == 0) 1001 else 2001
  pure def frameSpace(fs: int): int = ((fs + 3 + 3) / 4) * 4

  type State = { fault: int, sizes: int -> int, links: int -> int,
    words: int -> int, refs: int -> int, remaining: Set[int],
    owner: int, current: int, copied: Set[int], queued: Set[int],
    scanned: Set[int], phase: str, consume: int,
    badRA: bool, badFrame: bool, badReuse: bool }
  var s: State
  pure def stackTop(st: State, frame: int): int =
    if (frame == 0) 64 else 64 + frameSpace(st.sizes.get(0))
  pure def stackBase(st: State, frame: int): int = stackTop(st, frame) + frameSpace(st.sizes.get(frame))
  pure def body(st: State, frame: int): int =
    if (frame == 0) 128 else 128 + st.sizes.get(0) + 2
  // Current configured REFERENCE_TO_BODY is one word: references name header.
  pure def rawHeapReference(bodyWord: int): int = (bodyWord - 1) * 8
  pure def heapLink(st: State, frame: int): int = body(st, frame) + st.sizes.get(frame) - st.links.get(frame)
  pure def initial(fault: int, fs0: int, link0: int, fs1: int, link1: int): State = {
    val base = { fault: fault, sizes: Map(0 -> fs0, 1 -> fs1), links: Map(0 -> link0, 1 -> link1),
      words: cells.mapBy(_ => -256), refs: roots.mapBy(_ => 64 * 8), remaining: roots,
      owner: 0, current: 0, copied: Set(), queued: Set(), scanned: Set(),
      phase: "gc", consume: 0, badRA: false, badFrame: false, badReuse: false }
    { ...base, words: base.words.set(64, label(0))
      .set(stackBase(base, 0) - link0 - 1, label(1))
      .set(stackBase(base, 1) - link1 - 1, breakLabel)
      .set(stackBase(base, 1) + 1, endMarker) }
  }
  action init = {
    nondet fs0 = 1.to(3).oneOf()
    nondet link0 = 0.to(fs0 - 1).oneOf()
    nondet fs1 = 1.to(3).oneOf()
    nondet link1 = 0.to(fs1 - 1).oneOf()
    s' = initial(0, fs0, link0, fs1, link1)
  }
  action initMissingRestore = s' = initial(1, 2, 0, 3, 1)
  action initWrongLinkCoordinate = s' = initial(2, 2, 1, 3, 1)
  action initEarlyPublication = s' = initial(3, 2, 0, 3, 1)
  action initMissingRA = s' = initial(4, 2, 0, 3, 1)
  action initEarlyResume = s' = initial(5, 2, 0, 3, 1)
  action initUntypedHeapLink = s' = initial(6, 2, 0, 3, 1)

  action acquire = {
    nondet actor = s.remaining.oneOf()
    all { s.phase == "gc", s.owner == 0,
      s' = { ...s, owner: actor, current: 0 } }
  }
  action capture = {
    val frame = s.current
    val fs = s.sizes.get(frame)
    val base = stackBase(s, frame)
    val ra = s.words.get(stackTop(s, frame))
    val callerRA = s.words.get(base - s.links.get(frame) - 1)
    val destination = body(s, frame)
    all { s.phase == "gc", s.owner != 0, frame < 2,
      if (ra != label(frame)) s' = { ...s, badRA: true }
      else if (callerRA % 8 == 0) {
        // Shared MISC lock lets the alias observe a completed forwarding link.
        s' = { ...s, refs: s.refs.set(s.owner, callerRA + 1),
          remaining: s.remaining.exclude(Set(s.owner)), owner: 0 }
      } else {
        val copied = 1.to(fs).fold(s.words, (words, i) =>
          words.set(destination + i, s.words.get(base - fs - 1 + i)))
        val withRA = if (s.fault == 4) copied else copied.set(destination, ra)
        val nextFrame = if (callerRA == breakLabel) s.words.get(base + 1) else base * 8
        val restored = if (callerRA == breakLabel or s.fault == 1) withRA else withRA.set(base, callerRA)
        val linkCell = destination + fs - s.links.get(frame) - (if (s.fault == 2) 1 else 0)
        val linked = restored.set(linkCell, nextFrame)
          .set(base - s.links.get(frame) - 1, rawHeapReference(destination))
        val incoming = if (frame == 0) linked else linked.set(heapLink(s, 0), rawHeapReference(destination))
        s' = { ...s, words: incoming,
          refs: if (frame == 0) s.refs.set(s.owner, rawHeapReference(destination)) else s.refs,
          current: frame + 1, copied: s.copied.union(Set(frame)),
          queued: if (s.fault == 3) s.queued.union(Set(frame)) else s.queued,
          badReuse: s.badReuse or s.copied.contains(frame) }
      }
    }
  }
  action publish = all { s.phase == "gc", s.owner != 0, s.current == 2,
    s' = { ...s, refs: s.refs.set(s.owner, s.refs.get(s.owner) + 1),
      remaining: s.remaining.exclude(Set(s.owner)), owner: 0,
      queued: s.queued.union(s.copied) } }
  action scan = {
    nondet frame = s.queued.oneOf()
    val location = heapLink(s, frame)
    val nextFrame = s.words.get(location)
    all { s.phase == "gc",
      s' = { ...s, queued: s.queued.exclude(Set(frame)), scanned: s.scanned.union(Set(frame)),
        badRA: s.badRA or s.words.get(body(s, frame)) != label(frame),
        badFrame: s.badFrame or not(s.copied.contains(frame)) or
          (nextFrame != endMarker and nextFrame != rawHeapReference(body(s, 1))),
        // scan temporarily hides a raw heap link from mark_frame, then retags it.
        // Other projected scalar slots have no relocatable payload here.
        words: if (nextFrame == endMarker or s.fault == 6) s.words else s.words.set(location, nextFrame + 1) }
    }
  }
  action resume = all { s.phase == "gc", s.owner == 0, s.remaining == Set(),
    (s.scanned == frames and s.queued == Set()) or s.fault == 5,
    s' = { ...s, phase: "consume", consume: 0 } }
  action consume = {
    val frame = s.consume
    val nextFrame = s.words.get(heapLink(s, frame))
    all { s.phase == "consume", frame < 2,
      s' = { ...s, badRA: s.badRA or s.words.get(body(s, frame)) != label(frame),
        badFrame: s.badFrame or s.refs.get(1) != rawHeapReference(body(s, 0)) + 1 or
          (if (frame == 0) nextFrame != rawHeapReference(body(s, 1)) + 1 else nextFrame != endMarker),
        consume: frame + 1, phase: if (frame == 1) "done" else "consume" }
    }
  }
  action advance = any { acquire, capture, publish, scan, resume, consume }
  action step = any { advance, all { s.phase == "done", s' = s } }
  val copiedRASafe = s.copied.forall(frame => s.words.get(body(s, frame)) == label(frame))
  val safe = not(s.badRA) and not(s.badFrame) and not(s.badReuse) and copiedRASafe
  temporal completion = weakFair(advance, s).implies(eventually(s.phase == "done"))
}
