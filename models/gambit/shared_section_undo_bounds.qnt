module shared_section_undo_bounds {
  // Relative word coordinates per section; not ABI constants or host sizing.
  pure val end = 64
  pure val fudge = 4
  type State = { phase: str, stack: int, heap: int, previous: int,
    stackLimit: int, heapLimit: int, heapFront: int, frameWords: int,
    stackFront: int, eligible: bool, reserveFrames: bool, restoreBounds: bool }
  var s: State
  pure def initial(words: int, reserve: bool, restore: bool): State = {
    phase: "share", stack: 0, heap: 1, previous: -1,
    stackLimit: 0, heapLimit: end, heapFront: 0, frameWords: words,
    stackFront: if (reserve) end - words else end,
    eligible: false, reserveFrames: reserve, restoreBounds: restore }
  action init = {
    nondet words = Set(4, 8, 16, 32, 48).oneOf()
    s' = initial(words, true, true)
  }
  action initOriginalGCReservation = {
    nondet words = Set(4, 8, 16, 32, 48).oneOf()
    s' = initial(words, false, true)
  }
  action initOriginalUndo = {
    nondet words = Set(4, 8, 16, 32, 48).oneOf()
    s' = initial(words, true, false)
  }
  action initSeparateSection = s' = { ...initial(4, false, false),
    phase: "leave", stackFront: end - 4 }
  // Share the new stack and reserve the heap's two end-marker words.
  action shareDuringCopy = {
    val space = (s.stackFront - s.stackLimit - 2 * fudge) / 4
    all { s.phase == "share", s.stack != s.heap,
      s' = { ...s, phase: "allocate", heap: s.stack,
        stackLimit: s.stackFront - (space + fudge),
        heapFront: 1, heapLimit: 3 * space + fudge - 2 } }
  }
  action allocateLiveHeap = {
    // Finalization need not change heaps when the GC heap fudge remains.
    nondet front = 1.to(s.heapLimit - fudge).oneOf()
    all { s.phase == "allocate",
      s' = { ...s, phase: "relocate", heapFront: front } }
  }
  // Both versions copy to the same stack_start, but only one reserved it.
  action moveContinuation = all { s.phase == "relocate",
    s' = { ...s, phase: "leave", stackFront: end - s.frameWords } }
  // resize_heap has supplied a fresh section after copying completes.
  action leaveSharedStack = all { s.phase == "leave",
    s' = { ...s, phase: "undo", previous: s.stack, stack: 2,
      stackLimit: 0, stackFront: end, eligible: true } }
  // The native eligibility check excludes the current heap, not the old one.
  action restore = all { s.phase == "undo", s.stack != s.heap, s.eligible,
    s' = { ...s, phase: "done", stack: s.previous,
      stackFront: end - s.frameWords,
      stackLimit: if (s.restoreBounds and s.previous == s.heap) s.heapLimit else 0,
      eligible: false } }
  action step = any { shareDuringCopy, allocateLiveHeap, moveContinuation, leaveSharedStack,
    restore, all { s.phase == "done", s' = s } }
  val partition = (s.stack == s.heap).implies(s.stackLimit >= s.heapLimit)
  val bounds = s.stackFront >= s.stackLimit and s.heapFront <= s.heapLimit
  val payloadDisjoint = (s.stack == s.heap and
    Set("leave", "done").contains(s.phase)).implies(s.stackFront >= s.heapFront)
  val safe = partition and bounds and payloadDisjoint
  // Source-derived boundaries, not attribution of the captured first writer.
}
