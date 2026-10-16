module continuation_saved_stack_origin {
  // Two selected live Scheme threads, not processor or machine-count constants.
  // Witness slice: save current, restore another, then collect before stack reuse.
  // Raw frame IDs abstract retained stack addresses, not destination allocation.
  type State = { previous: int, next: int, active: int, phase: int,
    breakNext: int, savedPrevious: int, savedNext: int, raw: Set[int],
    rootCopied: Set[int], continuationQueued: bool, scanInput: str }
  var s: State

  action init = {
    nondet previous = 0.to(2).oneOf()
    nondet resumed = 0.to(2).oneOf()
    all {
      previous != resumed,
      s' = { previous: previous, next: resumed, active: previous, phase: 0,
        breakNext: previous, savedPrevious: -1, savedNext: resumed,
        raw: Set(previous, resumed), rootCopied: Set(),
        continuationQueued: false, scanInput: "none" },
    }
  }

  // ___THREAD_SAVE stores the current frame and installs/preserves a break.
  action saveCurrent = all {
    s.phase == 0,
    s' = { ...s, phase: 1, savedPrevious: s.active, breakNext: s.active },
  }
  // ___THREAD_RESTORE rewrites BREAK_FRAME_NEXT, then clears the resumed cont.
  action restoreNext = all {
    s.phase == 1,
    s' = { ...s, phase: 2, active: s.next, breakNext: s.savedNext, savedNext: -1 },
  }
  // mark_continuation follows the current break link, not all saved threads.
  action scanCurrentRoots = all {
    s.phase == 2,
    s' = { ...s, phase: 3, raw: s.raw.exclude(Set(s.breakNext)),
      rootCopied: s.rootCopied.union(Set(s.breakNext)) },
  }
  // mark_array copies a reachable continuation container; its raw frame field
  // is not chased by this copy. scan:___sCONTINUATION performs that operation.
  action queueSavedContinuation = all {
    s.phase == 3,
    s' = { ...s, phase: 4, continuationQueued: true },
  }
  action rootBarrier = all { s.phase == 4, s' = { ...s, phase: 5 } }
  action scanSavedContinuation = all {
    s.phase == 5, s.continuationQueued,
    s' = { ...s, phase: 6, continuationQueued: false,
      scanInput: if (s.raw.contains(s.savedPrevious)) "stack" else "forwarded" },
  }
  val terminal = s.phase == 6
  action finished = all { terminal, s' = s }
  action step = any { saveCurrent, restoreNext, scanCurrentRoots,
    queueSavedContinuation, rootBarrier, scanSavedContinuation, finished }

  val linkOwnership = s.phase < 2 or
    (s.savedPrevious == s.previous and s.breakNext == s.next and s.savedNext == -1)
  val rootCoverage = s.phase < 3 or
    (s.rootCopied == Set(s.next) and not(s.raw.contains(s.next)))
  val savedFrameRetained = s.phase < 2 or s.raw.contains(s.savedPrevious)
  val traversalOrigin = not(terminal) or s.scanInput == "stack"
  val guardSound = linkOwnership and rootCoverage and savedFrameRetained and traversalOrigin
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
