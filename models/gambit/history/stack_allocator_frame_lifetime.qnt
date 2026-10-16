module stack_allocator_frame_lifetime {
  // Per-processor section ownership before frame copy/return. Section ids are
  // logical raw C allocations, not CPU counts or observed process addresses.
  pure val sections = 0.to(3)
  pure val cells = 0.to(7)
  pure val nonSection = 9
  type State = { fault: int, phase: str, turns: int, epoch: int, space: int,
    stack: int, heap: int, virgin: Set[int], poolHead: int, poolNext: int -> int,
    previous: int -> int, eligible: Set[int], heapUsed: Set[int],
    generations: int -> int, roots: int -> int }
  var s: State
  pure def cell(section: int, space: int): int = section * 2 + space
  pure def poolWalk(st: State): { node: int, found: Set[int], cyclic: bool } =
    0.to(4).fold({ node: st.poolHead, found: Set(), cyclic: false }, (acc, _) =>
      if (acc.node == -1) acc else
        { node: st.poolNext.get(acc.node), found: acc.found.union(Set(acc.node)),
          cyclic: acc.cyclic or acc.found.contains(acc.node) })
  pure def poolSet(st: State): Set[int] = poolWalk(st).found
  pure def initial(fault: int): State = {
    fault: fault, phase: "mutator", turns: 0, epoch: 0, space: 0,
    stack: 0, heap: 1, virgin: Set(2, 3), poolHead: -1,
    poolNext: sections.union(Set(nonSection)).mapBy(_ => -1),
    previous: sections.mapBy(_ => -1), eligible: Set(), heapUsed: Set(1),
    generations: cells.mapBy(_ => 0), roots: cells.mapBy(_ => -1) }
  action init = s' = initial(0)
  action initMissingInvalidation = s' = initial(1)
  action initMissingPoolReset = s' = initial(2)
  action initEarlyResume = s' = initial(3)
  // Native observation violates this entry contract; it is not a source path.
  action initObservedNonSection = s' = { ...initial(4), phase: "observation" }
  // Import a failed entry observation, never a legal allocator transition.
  action observeNonSection = all { s.phase == "observation",
    s' = { ...s, phase: "mutator", poolHead: nonSection } }

  pure def stackChain(st: State): Set[int] = {
    val chain = 0.to(3).fold({ node: st.stack, found: Set() }, (acc, _) =>
      if (acc.node == -1) acc else
        { node: st.previous.get(acc.node), found: acc.found.union(Set(acc.node)) })
    chain.found
  }
  pure def available(st: State): Set[int] =
    if (st.stack != st.heap and st.poolHead != -1 and st.poolHead != st.heap)
      Set(st.poolHead)
    else if (st.virgin.size() > 0) st.virgin
    else if (st.stack != st.heap) Set(st.heap) else Set()

  action overflow = {
    nondet destination = available(s).oneOf()
    nondet retainUndo = Set(false, true).oneOf()
    val fromPool = s.poolHead != -1 and destination == s.poolHead
    val key = cell(destination, s.space)
    all { s.phase == "mutator", s.turns < 6, sections.contains(destination),
      s' = { ...s, turns: s.turns + 1, stack: destination,
        poolHead: if (fromPool) s.poolNext.get(destination) else s.poolHead,
        virgin: s.virgin.exclude(Set(destination)),
        previous: s.previous.set(destination, if (retainUndo) s.stack else -1),
        eligible: if (retainUndo) s.eligible.union(Set(destination))
                  else s.eligible.exclude(Set(destination)),
        // Sharing splits stack/heap bounds; it does not overwrite the heap.
        generations: if (destination == s.heap) s.generations
          else s.generations.set(key, s.generations.get(key) + 1) }
    }
  }
  action capture = {
    val chain = stackChain(s)
    val captured = chain.fold(s.roots, (roots, section) =>
      roots.set(cell(section, s.space), s.generations.get(cell(section, s.space))))
    all { s.phase == "mutator", s.turns < 6,
      s' = { ...s, turns: s.turns + 1, roots: captured,
        eligible: if (s.fault == 1) s.eligible else s.eligible.exclude(Set(s.stack)) }
    }
  }
  action undo = all { s.phase == "mutator", s.turns < 6,
    s.stack != s.heap, s.eligible.contains(s.stack),
    s' = { ...s, turns: s.turns + 1, stack: s.previous.get(s.stack),
      poolHead: s.stack, poolNext: s.poolNext.set(s.stack, s.poolHead) }
  }
  action beginGC = {
    val targetSpace = 1 - s.space
    all { s.phase == "mutator", s.turns < 6, s.epoch < 2,
      s' = { ...s, turns: s.turns + 1, phase: "gc", space: targetSpace,
        epoch: s.epoch + 1, stack: 0, heap: 1, virgin: Set(2, 3),
        poolHead: if (s.fault == 2) s.poolHead else -1,
        previous: sections.mapBy(_ => -1), eligible: Set(), heapUsed: Set(1),
        generations: s.generations
          .set(cell(0, targetSpace), s.generations.get(cell(0, targetSpace)) + 1)
          .set(cell(1, targetSpace), s.generations.get(cell(1, targetSpace)) + 1) }
    }
  }
  action evacuateRoots = all { s.phase == "gc", cells.exists(key => s.roots.get(key) >= 0),
    s' = { ...s, roots: cells.mapBy(_ => -1) } }
  action resume = all { s.phase == "gc", cells.forall(key => s.roots.get(key) == -1) or s.fault == 3,
    s' = { ...s, phase: "mutator" } }
  action idle = all { s.phase == "mutator", s.turns < 6,
    s' = { ...s, turns: s.turns + 1 } }
  action finish = all { s.phase == "mutator", s.turns == 6,
    s' = { ...s, phase: "done" } }
  action advance = any { overflow, capture, undo, beginGC, evacuateRoots, resume, idle, finish, observeNonSection }
  action step = any { advance, all { s.phase == "done", s' = s } }

  val poolTyped = poolSet(s).forall(section => sections.contains(section))
  val poolExclusive = not(poolWalk(s).cyclic) and
    poolSet(s).forall(section => section != s.stack and section != s.heap and
      not(s.virgin.contains(section)) and not(s.heapUsed.contains(section)))
  val rootsLive = cells.forall(key => s.roots.get(key) == -1 or
    (s.roots.get(key) == s.generations.get(key) and
    not(poolSet(s).contains(key / 2) and key % 2 == s.space)))
  val rawStackWriteSafe = sections.contains(s.stack) and sections.contains(s.heap)
  val safe = poolTyped and poolExclusive and rootsLive and rawStackWriteSafe
  // Completion of this six-transition finite prefix, not program termination.
  temporal completion = weakFair(advance, s).implies(eventually(s.phase == "done"))
}
