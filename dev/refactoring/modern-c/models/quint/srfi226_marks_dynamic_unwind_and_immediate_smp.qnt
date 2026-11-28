// -*- mode: Bluespec; -*-
// Phase C41: Thread-Safe Dynamic Continuation-Mark Frame Unwind,
// Tail-Checked Immediate Marks & Prompt-Scoped `continuation-marks` Slicing.

module srfi226_marks_dynamic_unwind_and_immediate_smp {
  type MarkFrame = { fid: int, k: int, v: int }

  pure val NO_RA = 0
  pure val MARK_POP_RA = 1
  pure val PROMPT_RA = 2
  pure val NONTAIL_RA = 3

  pure val KEY_OUTER = 1
  pure val KEY_INNER = 2
  pure val KEY_RESUMER = 3

  pure val VAL_DEAD = 100
  pure val VAL_INNER1 = 201
  pure val VAL_INNER2 = 202
  pure val VAL_RESUMER = 300
  pure val VAL_DEFAULT = -1

  // Pop innermost frame matching `targetFid` (and any unpopped inner frames above it).
  pure def popByFid(ms: List[MarkFrame], targetFid: int): List[MarkFrame] = {
    val idx = ms.indices().fold(-1, (found, i) =>
      if (found != -1) found
      else if (ms[i].fid == targetFid) i
      else -1
    )
    if (idx == -1) ms
    else ms.slice(idx + 1, ms.length())
  }

  // Immediate mark lookup strictly requiring caller r0 == MARK_POP_RA
  pure def immediateMark(ms: List[MarkFrame], r0: int, key: int): int =
    if (r0 == MARK_POP_RA and ms.length() > 0 and ms[0].k == key)
      ms[0].v
    else
      VAL_DEFAULT

  // Check if `suffix` is element-wise equal to a prefix of `stop`
  pure def tailMatchesPrefix(suffix: List[MarkFrame], stop: List[MarkFrame]): bool =
    if (suffix.length() > stop.length()) false
    else suffix.indices().forall(i => suffix[i] == stop[i])

  // Exact prompt-tag mark slicing (`%marks-slice-until-stop`)
  pure def sliceUntilStop(marks: List[MarkFrame], stop: List[MarkFrame]): List[MarkFrame] = {
    if (stop.length() == 0) marks
    else {
      val cut = marks.indices().fold(-1, (found, i) =>
        if (found != -1) found
        else if (tailMatchesPrefix(marks.slice(i, marks.length()), stop)) i
        else -1
      )
      if (cut == -1) marks else marks.slice(0, cut)
    }
  }

  // State: 2 SMP threads
  var marks0: List[MarkFrame]
  var marks1: List[MarkFrame]
  var nextFid: int
  var capturedMarks: List[MarkFrame]
  var capturedFid: int
  var capturedDone: bool
  var thread0ExitedOuter: bool
  var replayCount: int
  var lastCaughtMarks: List[MarkFrame]
  var lastImmNonTail: int
  var lastImmTail: int
  var violation: bool

  action init = all {
    marks0' = List(),
    marks1' = List(),
    nextFid' = 1,
    capturedMarks' = List(),
    capturedFid' = 0,
    capturedDone' = false,
    thread0ExitedOuter' = false,
    replayCount' = 0,
    lastCaughtMarks' = List(),
    lastImmNonTail' = VAL_DEFAULT,
    lastImmTail' = VAL_DEFAULT,
    violation' = false,
  }

  // Thread 0 captures a composable continuation inside outer(DEAD) -> prompt ->
  // inner(VAL_INNER1) -> tail-replace inner(VAL_INNER2), then exits outer(DEAD).
  action captureAndExitThread0 = all {
    not(capturedDone),
    val fidInner = nextFid + 1
    val innerFrame: MarkFrame = { fid: fidInner, k: KEY_INNER, v: VAL_INNER2 }
    all {
      capturedMarks' = List(innerFrame),
      capturedFid' = fidInner,
      nextFid' = nextFid + 2,
      capturedDone' = true,
      thread0ExitedOuter' = true,
      marks0' = List(),
      marks1' = marks1,
      replayCount' = replayCount,
      lastCaughtMarks' = lastCaughtMarks,
      lastImmNonTail' = immediateMark(List(innerFrame), NONTAIL_RA, KEY_INNER),
      lastImmTail' = immediateMark(List(innerFrame), MARK_POP_RA, KEY_INNER),
      violation' = violation,
    }
  }

  // Same-thread replay on Thread 0 under resumer(VAL_RESUMER) + exception unwind
  action replayAndRaiseThread0 = all {
    capturedDone,
    replayCount < 4,
    val fidRes = nextFid
    val resFrame: MarkFrame = { fid: fidRes, k: KEY_RESUMER, v: VAL_RESUMER }
    val preRaise = capturedMarks.concat(List(resFrame)).concat(marks0)
    val postUnwind = popByFid(preRaise, capturedFid)
    val bad = (postUnwind.length() != marks0.length() + 1)
              or (postUnwind[0] != resFrame)
              or (postUnwind.indices().exists(i => postUnwind[i].v == VAL_DEAD or postUnwind[i].fid == capturedFid))
    all {
      nextFid' = nextFid + 1,
      replayCount' = replayCount + 1,
      lastCaughtMarks' = postUnwind,
      marks0' = marks0,
      marks1' = marks1,
      capturedMarks' = capturedMarks,
      capturedFid' = capturedFid,
      capturedDone' = capturedDone,
      thread0ExitedOuter' = thread0ExitedOuter,
      lastImmNonTail' = lastImmNonTail,
      lastImmTail' = lastImmTail,
      violation' = (violation or bad),
    }
  }

  // Cross-thread SMP replay on Thread 1 under resumer(VAL_RESUMER) + exception unwind.
  action replayAndRaiseThread1 = all {
    capturedDone,
    replayCount < 4,
    val fidRes = nextFid
    val resFrame: MarkFrame = { fid: fidRes, k: KEY_RESUMER, v: VAL_RESUMER }
    val preRaise = capturedMarks.concat(List(resFrame)).concat(marks1)
    val postUnwind = popByFid(preRaise, capturedFid)
    val bad = (postUnwind.length() != marks1.length() + 1)
              or (postUnwind[0] != resFrame)
              or (postUnwind.indices().exists(i => postUnwind[i].v == VAL_DEAD or postUnwind[i].fid == capturedFid))
    all {
      nextFid' = nextFid + 1,
      replayCount' = replayCount + 1,
      lastCaughtMarks' = postUnwind,
      marks0' = marks0,
      marks1' = marks1,
      capturedMarks' = capturedMarks,
      capturedFid' = capturedFid,
      capturedDone' = capturedDone,
      thread0ExitedOuter' = thread0ExitedOuter,
      lastImmNonTail' = lastImmNonTail,
      lastImmTail' = lastImmTail,
      violation' = (violation or bad),
    }
  }

  // Nested self-replay + prompt-tag slicing verification step
  action checkSelfReplaySlice = all {
    capturedDone,
    val fA: MarkFrame = { fid: 90, k: KEY_INNER, v: 1 }
    val fB: MarkFrame = { fid: 91, k: KEY_OUTER, v: 2 }
    val fE: MarkFrame = { fid: 92, k: KEY_RESUMER, v: 3 }
    val sliced = sliceUntilStop(List(fA, fB, fA, fB), List(fA, fB, fE))
    val bad = (sliced != List(fA, fB))
    all {
      marks0' = marks0,
      marks1' = marks1,
      nextFid' = nextFid,
      capturedMarks' = capturedMarks,
      capturedFid' = capturedFid,
      capturedDone' = capturedDone,
      thread0ExitedOuter' = thread0ExitedOuter,
      replayCount' = replayCount,
      lastCaughtMarks' = lastCaughtMarks,
      lastImmNonTail' = lastImmNonTail,
      lastImmTail' = lastImmTail,
      violation' = (violation or bad),
    }
  }

  action step = any {
    captureAndExitThread0,
    replayAndRaiseThread0,
    replayAndRaiseThread1,
    checkSelfReplaySlice,
  }

  val noViolationInv = not(violation)
  val thread0CleanAfterExitInv = thread0ExitedOuter implies (marks0.length() == 0)
  val immediateNonTailAlwaysDefaultInv = (lastImmNonTail == VAL_DEFAULT)
  val immediateTailExactInv = capturedDone implies (lastImmTail == VAL_INNER2)
  val allInvs = noViolationInv and thread0CleanAfterExitInv and immediateNonTailAlwaysDefaultInv and immediateTailExactInv

  run sameAndCrossThreadReplayTest =
    init
      .then(captureAndExitThread0)
      .then(replayAndRaiseThread0)
      .then(replayAndRaiseThread1)
      .then(checkSelfReplaySlice)
      .expect(not(violation) and marks0.length() == 0 and lastImmNonTail == VAL_DEFAULT and lastImmTail == VAL_INNER2)

  run tailReplacePreservesFidPopTest = {
    val f1: MarkFrame = { fid: 10, k: KEY_INNER, v: VAL_INNER2 }
    val fRes: MarkFrame = { fid: 20, k: KEY_RESUMER, v: VAL_RESUMER }
    val popped = popByFid(List(f1, fRes), 10)
    init.expect(popped == List(fRes))
  }

  run innerUnpoppedMarkUnwoundTooTest = {
    val fSub: MarkFrame = { fid: 11, k: KEY_INNER, v: 999 }
    val f1: MarkFrame = { fid: 10, k: KEY_INNER, v: VAL_INNER1 }
    val fRes: MarkFrame = { fid: 20, k: KEY_RESUMER, v: VAL_RESUMER }
    val popped = popByFid(List(fSub, f1, fRes), 10)
    init.expect(popped == List(fRes))
  }

  run immediateMarkChecksR0Test = {
    val f1: MarkFrame = { fid: 10, k: KEY_INNER, v: VAL_INNER1 }
    init.expect(
      immediateMark(List(f1), MARK_POP_RA, KEY_INNER) == VAL_INNER1 and
      immediateMark(List(f1), NONTAIL_RA, KEY_INNER) == VAL_DEFAULT and
      immediateMark(List(f1), PROMPT_RA, KEY_INNER) == VAL_DEFAULT
    )
  }

  run selfReplaySliceExactTest = {
    val fA: MarkFrame = { fid: 1, k: 1, v: 10 }
    val fB: MarkFrame = { fid: 2, k: 2, v: 20 }
    val fE: MarkFrame = { fid: 3, k: 3, v: 30 }
    init.expect(
      sliceUntilStop(List(fA, fB, fA, fB), List(fA, fB, fE)) == List(fA, fB) and
      sliceUntilStop(List(fA, fB), List(fE)) == List(fA, fB) and
      sliceUntilStop(List(fA, fB), List(fA, fB, fE)) == List()
    )
  }
}
