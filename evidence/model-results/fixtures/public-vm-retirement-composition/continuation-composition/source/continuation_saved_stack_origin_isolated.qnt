module continuation_saved_stack_origin_isolated {
  // Two selected live Scheme threads, not processor or machine-count constants.
  // Witness slice: save current, restore another, then collect before stack reuse.
  // Raw frame IDs abstract retained stack addresses, not destination allocation.
  type State = { previous: int, next: int, active: int, phase: int,
    breakNext: int, savedPrevious: int, savedNext: int, raw: Set[int],
    rootCopied: Set[int], continuationQueued: bool, scanInput: str }
  var originState: State

  action init = {
    nondet previous = 0.to(2).oneOf()
    nondet resumed = 0.to(2).oneOf()
    all {
      previous != resumed,
      originState' = { previous: previous, next: resumed, active: previous, phase: 0,
        breakNext: previous, savedPrevious: -1, savedNext: resumed,
        raw: Set(previous, resumed), rootCopied: Set(),
        continuationQueued: false, scanInput: "none" },
    }
  }

  action initOld = {
    nondet previous = 0.to(2).oneOf()
    nondet resumed = 0.to(2).oneOf()
    all {
      previous != resumed,
      originState' = { previous: previous, next: resumed, active: previous, phase: 0,
        breakNext: previous, savedPrevious: -1, savedNext: resumed,
        raw: Set(previous, resumed), rootCopied: Set(),
        continuationQueued: false, scanInput: "none" },
    }
  }

  // ___THREAD_SAVE stores the current frame and installs/preserves a break.
  action saveCurrent = all {
    originState.phase == 0,
    originState' = { ...originState, phase: 1, savedPrevious: originState.active, breakNext: originState.active },
  }
  // ___THREAD_RESTORE rewrites BREAK_FRAME_NEXT, then clears the resumed cont.
  action restoreNext = all {
    originState.phase == 1,
    originState' = { ...originState, phase: 2, active: originState.next, breakNext: originState.savedNext, savedNext: -1 },
  }
  // mark_continuation follows the current break link, not all saved threads.
  action scanCurrentRoots = all {
    originState.phase == 2,
    originState' = { ...originState, phase: 3, raw: originState.raw.exclude(Set(originState.breakNext)),
      rootCopied: originState.rootCopied.union(Set(originState.breakNext)) },
  }
  // mark_array copies a reachable continuation container; its raw frame field
  // is not chased by this copy. scan:___sCONTINUATION performs that operation.
  action queueSavedContinuation = all {
    originState.phase == 3,
    originState' = { ...originState, phase: 4, continuationQueued: true },
  }
  action rootBarrier = all { originState.phase == 4, originState' = { ...originState, phase: 5 } }
  action scanSavedContinuation = all {
    originState.phase == 5, originState.continuationQueued,
    originState' = { ...originState, phase: 6, continuationQueued: false,
      scanInput: if (originState.raw.contains(originState.savedPrevious)) "stack" else "forwarded" },
  }
  val terminal = originState.phase == 6
  action finished = all { terminal, originState' = originState }
  action step = any { saveCurrent, restoreNext, scanCurrentRoots,
    queueSavedContinuation, rootBarrier, scanSavedContinuation, finished }

  val linkOwnership = originState.phase < 2 or
    (originState.savedPrevious == originState.previous and originState.breakNext == originState.next and originState.savedNext == -1)
  val rootCoverage = originState.phase < 3 or
    (originState.rootCopied == Set(originState.next) and not(originState.raw.contains(originState.next)))
  val savedFrameRetained = originState.phase < 2 or originState.raw.contains(originState.savedPrevious)
  val traversalOrigin = not(terminal) or originState.scanInput == "stack"
  val guardSound = linkOwnership and rootCoverage and savedFrameRetained and traversalOrigin
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(originState)).implies(eventually(terminal))
}
