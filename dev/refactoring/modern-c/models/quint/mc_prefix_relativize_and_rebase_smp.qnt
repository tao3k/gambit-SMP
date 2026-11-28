// -*- mode: quint; -*-
// Phase C54: Metacontinuation Prefix Relativization & Pointer-Shared Tail Re-Basing
// (`srfi/226/prompt.scm`, `srfi/226/cont.scm`, `effect/handler.scm`, `effect/resume.scm`,
// `effect/generator.scm`).

module mc_prefix_relativize_and_rebase_smp {

  // Symbolic tokens:
  //   Marks:    10=outer_m, 11=inner_m, 12=resumer1_m, 13=resumer2_m
  //   Handlers: 20=e_outer, 21=e_inner, 22=resumer1_h, 23=resumer2_h
  //   Barriers: 30=resumer1_b, 31=resumer2_b

  // Immutable captured template (relativized at capture time)
  var capMarks: List[int]       // [11, 10]
  var capHandlers: List[int]    // [21]
  var relPfMarks: List[int]     // [10]  (marks between pt-in and pt-out)
  var relPfBarriers: List[int]  // []
  var relPfHandlers: List[int]  // []    (handlers between pt-in and e-outer)

  // Live replayed extent state
  var phase: str                // "captured" | "in_inner" | "after_inner"
  var activeExtent: int         // 0=none, 1=extent1, 2=extent2
  var curMarks: List[int]
  var curBarriers: List[int]
  var curHandlers: List[int]
  var pfInMarks: List[int]
  var pfInBarriers: List[int]
  var pfInHandlers: List[int]
  var queriedInnerMarks: List[int]
  var resumerBarrierTok: int
  var resumerMarkTok: int
  var resumerHandlerTok: int

  pure def listContains(xs: List[int], v: int): bool =
    xs.foldl(false, (acc, x) => acc or x == v)

  pure def concatLists(a: List[int], b: List[int]): List[int] =
    b.foldl(a, (acc, x) => acc.append(x))

  // Drop first k elements from xs
  pure def dropN(xs: List[int], k: int): List[int] =
    xs.foldl({ i: 0, acc: [] }, (st, x) =>
      if (st.i < k) { i: st.i + 1, acc: st.acc }
      else { i: st.i + 1, acc: st.acc.append(x) }
    ).acc

  // Take first k elements from xs
  pure def takeN(xs: List[int], k: int): List[int] =
    xs.foldl({ i: 0, acc: [] }, (st, x) =>
      if (st.i < k) { i: st.i + 1, acc: st.acc.append(x) }
      else { i: st.i + 1, acc: st.acc }
    ).acc

  // Mirror %tail-for-rel: exact suffix of newList corresponding to rel ++ baseList
  pure def tailForRel(rel: List[int], capLen: int, newList: List[int], baseList: List[int]): List[int] =
    if (length(rel) == 0) baseList
    else {
      if (length(rel) <= capLen) dropN(newList, capLen - length(rel))
      else concatLists(rel, baseList)
    }

  action init = all {
    capMarks' = [11, 10],
    capHandlers' = [21],
    relPfMarks' = [10],
    relPfBarriers' = [],
    relPfHandlers' = [],
    phase' = "captured",
    activeExtent' = 0,
    curMarks' = [],
    curBarriers' = [],
    curHandlers' = [],
    pfInMarks' = [],
    pfInBarriers' = [],
    pfInHandlers' = [],
    queriedInnerMarks' = [],
    resumerBarrierTok' = 0,
    resumerMarkTok' = 0,
    resumerHandlerTok' = 0,
  }

  // Replay captured continuation in Extent 1 (resumer1_m=12, resumer1_b=30, resumer1_h=22)
  action replayInExtent1 = {
    val baseM = [12]
    val baseB = [30]
    val baseH = [20, 22]
    val newM = concatLists(capMarks, baseM)
    val newB = baseB
    val newH = concatLists(capHandlers, baseH)
    val reM = tailForRel(relPfMarks, length(capMarks), newM, baseM)
    val reB = tailForRel(relPfBarriers, 0, newB, baseB)
    val reH = tailForRel(relPfHandlers, length(capHandlers), newH, baseH)
    all {
      phase == "captured" or phase == "after_inner",
      phase' = "in_inner",
      activeExtent' = 1,
      curMarks' = newM,
      curBarriers' = newB,
      curHandlers' = newH,
      pfInMarks' = reM,
      pfInBarriers' = reB,
      pfInHandlers' = reH,
      queriedInnerMarks' = [],
      resumerMarkTok' = 12,
      resumerBarrierTok' = 30,
      resumerHandlerTok' = 22,
      capMarks' = capMarks,
      capHandlers' = capHandlers,
      relPfMarks' = relPfMarks,
      relPfBarriers' = relPfBarriers,
      relPfHandlers' = relPfHandlers,
    }
  }

  // Replay same multi-shot template in Extent 2 (resumer2_m=13, resumer2_b=31, resumer2_h=23)
  action replayInExtent2 = {
    val baseM = [13]
    val baseB = [31]
    val baseH = [20, 23]
    val newM = concatLists(capMarks, baseM)
    val newB = baseB
    val newH = concatLists(capHandlers, baseH)
    val reM = tailForRel(relPfMarks, length(capMarks), newM, baseM)
    val reB = tailForRel(relPfBarriers, 0, newB, baseB)
    val reH = tailForRel(relPfHandlers, length(capHandlers), newH, baseH)
    all {
      phase == "captured" or phase == "after_inner",
      phase' = "in_inner",
      activeExtent' = 2,
      curMarks' = newM,
      curBarriers' = newB,
      curHandlers' = newH,
      pfInMarks' = reM,
      pfInBarriers' = reB,
      pfInHandlers' = reH,
      queriedInnerMarks' = [],
      resumerMarkTok' = 13,
      resumerBarrierTok' = 31,
      resumerHandlerTok' = 23,
      capMarks' = capMarks,
      capHandlers' = capHandlers,
      relPfMarks' = relPfMarks,
      relPfBarriers' = relPfBarriers,
      relPfHandlers' = relPfHandlers,
    }
  }

  // Query (current-continuation-marks pt-in): stops at exact pointer-shared pfInMarks tail
  action queryInnerPromptMarks = {
    val prefixLen = length(curMarks) - length(pfInMarks)
    val res = takeN(curMarks, prefixLen)
    all {
      phase == "in_inner",
      dropN(curMarks, prefixLen) == pfInMarks,
      queriedInnerMarks' = res,
      phase' = phase,
      activeExtent' = activeExtent,
      curMarks' = curMarks,
      curBarriers' = curBarriers,
      curHandlers' = curHandlers,
      pfInMarks' = pfInMarks,
      pfInBarriers' = pfInBarriers,
      pfInHandlers' = pfInHandlers,
      resumerMarkTok' = resumerMarkTok,
      resumerBarrierTok' = resumerBarrierTok,
      resumerHandlerTok' = resumerHandlerTok,
      capMarks' = capMarks,
      capHandlers' = capHandlers,
      relPfMarks' = relPfMarks,
      relPfBarriers' = relPfBarriers,
      relPfHandlers' = relPfHandlers,
    }
  }

  // Normal return from replayed inner prompt pt-in: restores re-based (pfInMarks, pfInBarriers, pfInHandlers)
  action innerPromptReturn = all {
    phase == "in_inner",
    phase' = "after_inner",
    curMarks' = pfInMarks,
    curBarriers' = pfInBarriers,
    curHandlers' = pfInHandlers,
    activeExtent' = activeExtent,
    pfInMarks' = pfInMarks,
    pfInBarriers' = pfInBarriers,
    pfInHandlers' = pfInHandlers,
    queriedInnerMarks' = queriedInnerMarks,
    resumerMarkTok' = resumerMarkTok,
    resumerBarrierTok' = resumerBarrierTok,
    resumerHandlerTok' = resumerHandlerTok,
    capMarks' = capMarks,
    capHandlers' = capHandlers,
    relPfMarks' = relPfMarks,
    relPfBarriers' = relPfBarriers,
    relPfHandlers' = relPfHandlers,
  }

  // Abort to replayed inner prompt pt-in: restores re-based (pfInMarks, pfInBarriers, pfInHandlers)
  action innerPromptAbort = all {
    phase == "in_inner",
    phase' = "after_inner",
    curMarks' = pfInMarks,
    curBarriers' = pfInBarriers,
    curHandlers' = pfInHandlers,
    activeExtent' = activeExtent,
    pfInMarks' = pfInMarks,
    pfInBarriers' = pfInBarriers,
    pfInHandlers' = pfInHandlers,
    queriedInnerMarks' = queriedInnerMarks,
    resumerMarkTok' = resumerMarkTok,
    resumerBarrierTok' = resumerBarrierTok,
    resumerHandlerTok' = resumerHandlerTok,
    capMarks' = capMarks,
    capHandlers' = capHandlers,
    relPfMarks' = relPfMarks,
    relPfBarriers' = relPfBarriers,
    relPfHandlers' = relPfHandlers,
  }

  action step = any {
    replayInExtent1,
    replayInExtent2,
    queryInnerPromptMarks,
    innerPromptReturn,
    innerPromptAbort,
  }

  // --- Safety Invariants ---
  val invNoMarkLeakAcrossInnerPrompt =
    (length(queriedInnerMarks) == 0) or
    (queriedInnerMarks == [11] and not(listContains(queriedInnerMarks, 10)) and not(listContains(queriedInnerMarks, resumerMarkTok)))

  val invResumerMarksPreserved =
    (phase == "captured") or
    (listContains(curMarks, 10) and listContains(curMarks, resumerMarkTok))

  val invResumerHandlersPreserved =
    (phase == "captured") or
    (listContains(curHandlers, 20) and listContains(curHandlers, resumerHandlerTok))

  val invResumerBarrierNeverBypassed =
    (phase == "captured") or
    (listContains(curBarriers, resumerBarrierTok) and listContains(pfInBarriers, resumerBarrierTok))

  val invTemplateImmutable =
    relPfMarks == [10] and relPfBarriers == [] and relPfHandlers == []

  val allInvs =
    invNoMarkLeakAcrossInnerPrompt and
    invResumerMarksPreserved and
    invResumerHandlersPreserved and
    invResumerBarrierNeverBypassed and
    invTemplateImmutable

  // --- 5 Unit Tests ---
  run replayedInnerPromptMarksBoundaryTest =
    init
      .then(replayInExtent1)
      .then(queryInnerPromptMarks)
      .expect(queriedInnerMarks == [11] and not(listContains(queriedInnerMarks, 10)) and not(listContains(queriedInnerMarks, 12)))

  run replayedInnerPromptReturnPreservesMarksAndHandlersTest =
    init
      .then(replayInExtent1)
      .then(innerPromptReturn)
      .expect(curMarks == [10, 12] and curHandlers == [20, 22])

  run replayedInnerPromptAbortPreservesExtentTest =
    init
      .then(replayInExtent1)
      .then(innerPromptAbort)
      .expect(curMarks == [10, 12] and curHandlers == [20, 22] and curBarriers == [30])

  run replayedInnerPromptPreservesResumerBarrierTest =
    init
      .then(replayInExtent1)
      .then(innerPromptReturn)
      .expect(listContains(curBarriers, 30))

  run multishotCrossExtentIndependentRebaseTest =
    init
      .then(replayInExtent1)
      .then(innerPromptReturn)
      .expect(curMarks == [10, 12] and curBarriers == [30] and curHandlers == [20, 22])
      .then(replayInExtent2)
      .then(queryInnerPromptMarks)
      .expect(queriedInnerMarks == [11])
      .then(innerPromptReturn)
      .expect(curMarks == [10, 13] and curBarriers == [31] and curHandlers == [20, 23] and relPfMarks == [10])
}
