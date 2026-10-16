module shared_msection_successor {
  import stack_allocator_frame_lifetime as A from "./stack_allocator_frame_lifetime"
  // Logical sections, not CPU counts, raw addresses or candidate numbers.
  type Global = { phase: str, cursor: int, next: int -> int, observed: bool }
  var global: Global
  pure def initial(observed: bool): Global = {
    phase: "allocate", cursor: 1,
    next: Map(0 -> 1, 1 -> 2, 2 -> 3, 3 -> -1), observed: observed }
  action init = all { A::s' = A::initial(0), global' = initial(false) }
  action initObservedFreshReturn = all {
    A::s' = A::initial(0), global' = initial(true)
  }
  action selectSuccessor = all {
    global.phase == "allocate", not(global.observed), A::s.poolHead == -1,
    global' = { ...global, phase: "selected", cursor: global.next.get(global.cursor) },
    A::s' = A::s
  }
  // The native record observes the post-return cursor, not its predecessor's
  // stored next word. Do not manufacture a header writer or corrupt next here.
  action importFailedReturn = all {
    global.phase == "allocate", global.observed, A::s.poolHead == -1,
    global' = { ...global, phase: "rejected", cursor: A::nonSection },
    A::s' = A::s
  }
  action install = {
    val key = A::cell(global.cursor, A::s.space)
    all {
      global.phase == "selected",
      A::s' = { ...A::s, stack: global.cursor,
        virgin: A::s.virgin.exclude(Set(global.cursor)),
        previous: A::s.previous.set(global.cursor, A::s.stack),
        payloadPrevious: A::s.payloadPrevious.set(global.cursor, A::s.stack),
        eligible: A::s.eligible.union(Set(global.cursor)),
        generations: A::s.generations.set(key, A::s.generations.get(key) + 1) },
      global' = { ...global, phase: "done" }
    }
  }
  action step = any { selectSuccessor, importFailedReturn, install,
    all { Set("done", "rejected").contains(global.phase), global' = global, A::s' = A::s } }
  val safe = A::safe and A::sections.contains(global.cursor)
}
