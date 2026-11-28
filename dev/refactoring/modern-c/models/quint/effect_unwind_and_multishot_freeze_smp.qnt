// Quint formal specification for exception-unwind metacontinuation coherency,
// generator cross-call fault propagation, and concurrent resume vs resume-multishot
// freeze safety.

module effect_unwind_and_multishot_freeze_smp {

  // Generator states
  pure val GEN_INIT      = 0
  pure val GEN_RUNNING   = 1
  pure val GEN_SUSPENDED = 2
  pure val GEN_DONE      = 3

  // Continuation states
  pure val EC_LIVE       = 0
  pure val EC_CONSUMED   = 1
  pure val EC_MULTISHOT  = 2

  type McFrame = {
    fid: int,
    scope: int,       // 0 = transparent (inside active trampoline); >0 = catcher scope id
    isGen: bool,
    savedMarks: int,
    savedCatcher: int
  }

  // Thread-local metacontinuation & exception-catcher stack model
  var mc: List[McFrame]
  var activeCatcher: int      // 1 = top-level, 2, 3 = nested with-exception-catcher
  var trampolineActive: bool
  var marksDepth: int
  var nextFid: int
  var genState: int
  var genSubKValid: bool
  var genCall1Catcher: int
  var lastDeliveredCatcher: int
  var expectedCatcherOnThrow: int
  var staleReturnDetected: bool
  var deliveredWrongCatcher: bool
  var stuckGenOnThrow: bool

  // Concurrent resume vs resume-multishot race model (2 threads)
  var ecState: int
  var ecPframeFrozen: bool
  var ecPrefixFrozen: bool
  var t0Phase: int   // 0=idle, 1=cas-won-1shot, 2=saw-multishot, 3=replayed
  var t1Phase: int   // 0=idle, 1=cas-won-promote, 2=froze, 3=replayed
  var unfrozenReplayDetected: bool
  var doubleConsumeDetected: bool
  var oneShotWinners: int

  pure def listPopTop(xs: List[McFrame]): List[McFrame] =
    if (xs.length() <= 1) List() else xs.slice(1, xs.length())

  pure def hasGenInTop(xs: List[McFrame], count: int): bool =
    xs.slice(0, count).foldl(false, (acc, f) => acc or f.isGen)

  // Find 1-based count to pop through the first frame with scope != 0; 0 if none.
  pure def findScopeBoundary(xs: List[McFrame]): int = {
    val res = xs.foldl({ found: 0, idx: 0 }, (st, f) =>
      if (st.found > 0) st
      else if (f.scope != 0) { found: st.idx + 1, idx: st.idx + 1 }
      else { found: 0, idx: st.idx + 1 }
    )
    res.found
  }

  action init = all {
    mc' = List(),
    activeCatcher' = 1,
    trampolineActive' = false,
    marksDepth' = 0,
    nextFid' = 1,
    genState' = GEN_INIT,
    genSubKValid' = false,
    genCall1Catcher' = 1,
    lastDeliveredCatcher' = 0,
    expectedCatcherOnThrow' = 1,
    staleReturnDetected' = false,
    deliveredWrongCatcher' = false,
    stuckGenOnThrow' = false,
    ecState' = EC_LIVE,
    ecPframeFrozen' = false,
    ecPrefixFrozen' = false,
    t0Phase' = 0,
    t1Phase' = 0,
    unfrozenReplayDetected' = false,
    doubleConsumeDetected' = false,
    oneShotWinners' = 0,
  }

  // Enter a new with-exception-catcher scope (clears trampolineActive because
  // the new catcher replaces current-exception-handler in denv).
  action enterCatcher = all {
    activeCatcher < 3,
    activeCatcher' = activeCatcher + 1,
    trampolineActive' = false,
    expectedCatcherOnThrow' = activeCatcher + 1,
    mc' = mc,
    marksDepth' = marksDepth,
    nextFid' = nextFid,
    genState' = genState,
    genSubKValid' = genSubKValid,
    genCall1Catcher' = genCall1Catcher,
    lastDeliveredCatcher' = lastDeliveredCatcher,
    staleReturnDetected' = staleReturnDetected,
    deliveredWrongCatcher' = deliveredWrongCatcher,
    stuckGenOnThrow' = stuckGenOnThrow,
    ecState' = ecState,
    ecPframeFrozen' = ecPframeFrozen,
    ecPrefixFrozen' = ecPrefixFrozen,
    t0Phase' = t0Phase,
    t1Phase' = t1Phase,
    unfrozenReplayDetected' = unfrozenReplayDetected,
    doubleConsumeDetected' = doubleConsumeDetected,
    oneShotWinners' = oneShotWinners,
  }

  // Exit an inner with-exception-catcher normally (only when no unpopped prompt
  // belongs to this catcher scope, restoring outer trampoline iff top mc frame
  // belongs directly to the enclosing catcher).
  action exitCatcher = all {
    activeCatcher > 1,
    (mc.length() == 0 or mc[0].savedCatcher < activeCatcher),
    val outerCatcher = activeCatcher - 1
    all {
      activeCatcher' = outerCatcher,
      trampolineActive' = (mc.length() > 0 and mc[0].savedCatcher == outerCatcher),
      expectedCatcherOnThrow' = outerCatcher,
      mc' = mc,
      marksDepth' = marksDepth,
      nextFid' = nextFid,
      genState' = genState,
      genSubKValid' = genSubKValid,
      genCall1Catcher' = genCall1Catcher,
      lastDeliveredCatcher' = lastDeliveredCatcher,
      staleReturnDetected' = staleReturnDetected,
      deliveredWrongCatcher' = deliveredWrongCatcher,
      stuckGenOnThrow' = stuckGenOnThrow,
      ecState' = ecState,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
      t0Phase' = t0Phase,
      t1Phase' = t1Phase,
      unfrozenReplayDetected' = unfrozenReplayDetected,
      doubleConsumeDetected' = doubleConsumeDetected,
      oneShotWinners' = oneShotWinners,
    }
  }

  // Enter a prompt or suspending with-handler frame.
  action enterPrompt = all {
    mc.length() < 4,
    val scopeToken = if (trampolineActive) 0 else activeCatcher
    val f: McFrame = {
      fid: nextFid,
      scope: scopeToken,
      isGen: false,
      savedMarks: marksDepth,
      savedCatcher: activeCatcher,
    }
    all {
      mc' = List(f).concat(mc),
      trampolineActive' = true,
      nextFid' = nextFid + 1,
      activeCatcher' = activeCatcher,
      marksDepth' = marksDepth,
      genState' = genState,
      genSubKValid' = genSubKValid,
      genCall1Catcher' = genCall1Catcher,
      lastDeliveredCatcher' = lastDeliveredCatcher,
      expectedCatcherOnThrow' = activeCatcher,
      staleReturnDetected' = staleReturnDetected,
      deliveredWrongCatcher' = deliveredWrongCatcher,
      stuckGenOnThrow' = stuckGenOnThrow,
      ecState' = ecState,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
      t0Phase' = t0Phase,
      t1Phase' = t1Phase,
      unfrozenReplayDetected' = unfrozenReplayDetected,
      doubleConsumeDetected' = doubleConsumeDetected,
      oneShotWinners' = oneShotWinners,
    }
  }

  // Push a continuation mark inside an active prompt.
  action pushMark = all {
    mc.length() > 0,
    marksDepth < 5,
    marksDepth' = marksDepth + 1,
    mc' = mc,
    activeCatcher' = activeCatcher,
    trampolineActive' = trampolineActive,
    nextFid' = nextFid,
    genState' = genState,
    genSubKValid' = genSubKValid,
    genCall1Catcher' = genCall1Catcher,
    lastDeliveredCatcher' = lastDeliveredCatcher,
    expectedCatcherOnThrow' = expectedCatcherOnThrow,
    staleReturnDetected' = staleReturnDetected,
    deliveredWrongCatcher' = deliveredWrongCatcher,
    stuckGenOnThrow' = stuckGenOnThrow,
    ecState' = ecState,
    ecPframeFrozen' = ecPframeFrozen,
    ecPrefixFrozen' = ecPrefixFrozen,
    t0Phase' = t0Phase,
    t1Phase' = t1Phase,
    unfrozenReplayDetected' = unfrozenReplayDetected,
    doubleConsumeDetected' = doubleConsumeDetected,
    oneShotWinners' = oneShotWinners,
  }

  // Call generator (INIT -> RUNNING or SUSPENDED -> RUNNING).
  // Records caller's activeCatcher in frame.scope whenever caller is outside trampoline.
  action callGenerator = all {
    mc.length() < 4,
    (genState == GEN_INIT or genState == GEN_SUSPENDED),
    val scopeToken = if (trampolineActive) 0 else activeCatcher
    val f: McFrame = {
      fid: nextFid,
      scope: scopeToken,
      isGen: true,
      savedMarks: marksDepth,
      savedCatcher: activeCatcher,
    }
    all {
      mc' = List(f).concat(mc),
      trampolineActive' = true,
      nextFid' = nextFid + 1,
      genState' = GEN_RUNNING,
      genSubKValid' = false,
      genCall1Catcher' = if (genState == GEN_INIT) activeCatcher else genCall1Catcher,
      activeCatcher' = activeCatcher,
      marksDepth' = marksDepth,
      lastDeliveredCatcher' = lastDeliveredCatcher,
      expectedCatcherOnThrow' = activeCatcher,
      staleReturnDetected' = staleReturnDetected,
      deliveredWrongCatcher' = deliveredWrongCatcher,
      stuckGenOnThrow' = stuckGenOnThrow,
      ecState' = ecState,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
      t0Phase' = t0Phase,
      t1Phase' = t1Phase,
      unfrozenReplayDetected' = unfrozenReplayDetected,
      doubleConsumeDetected' = doubleConsumeDetected,
      oneShotWinners' = oneShotWinners,
    }
  }

  // Generator yields back to caller (RUNNING -> SUSPENDED).
  action yieldGenerator = all {
    mc.length() > 0,
    trampolineActive,
    mc[0].isGen,
    genState == GEN_RUNNING,
    val top = mc[0]
    all {
      mc' = listPopTop(mc),
      marksDepth' = top.savedMarks,
      activeCatcher' = top.savedCatcher,
      trampolineActive' = (top.scope == 0),
      genState' = GEN_SUSPENDED,
      genSubKValid' = true,
      nextFid' = nextFid,
      genCall1Catcher' = genCall1Catcher,
      lastDeliveredCatcher' = lastDeliveredCatcher,
      expectedCatcherOnThrow' = top.savedCatcher,
      staleReturnDetected' = staleReturnDetected,
      deliveredWrongCatcher' = deliveredWrongCatcher,
      stuckGenOnThrow' = stuckGenOnThrow,
      ecState' = ecState,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
      t0Phase' = t0Phase,
      t1Phase' = t1Phase,
      unfrozenReplayDetected' = unfrozenReplayDetected,
      doubleConsumeDetected' = doubleConsumeDetected,
      oneShotWinners' = oneShotWinners,
    }
  }

  // Normal return from top prompt/generator frame.
  action normalReturn = all {
    mc.length() > 0,
    trampolineActive,
    val top = mc[0]
    all {
      // If top frame belonged to a different catcher than activeCatcher, a stale frame leaked!
      staleReturnDetected' = (staleReturnDetected or (top.savedCatcher != activeCatcher)),
      mc' = listPopTop(mc),
      marksDepth' = top.savedMarks,
      activeCatcher' = top.savedCatcher,
      trampolineActive' = (top.scope == 0),
      genState' = if (top.isGen) GEN_DONE else genState,
      genSubKValid' = if (top.isGen) false else genSubKValid,
      nextFid' = nextFid,
      genCall1Catcher' = genCall1Catcher,
      lastDeliveredCatcher' = lastDeliveredCatcher,
      expectedCatcherOnThrow' = top.savedCatcher,
      deliveredWrongCatcher' = deliveredWrongCatcher,
      stuckGenOnThrow' = stuckGenOnThrow,
      ecState' = ecState,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
      t0Phase' = t0Phase,
      t1Phase' = t1Phase,
      unfrozenReplayDetected' = unfrozenReplayDetected,
      doubleConsumeDetected' = doubleConsumeDetected,
      oneShotWinners' = oneShotWinners,
    }
  }

  // Exception raised inside active prompt/generator: %mc-unwind-and-raise!
  // Pops all frames through the first frame with scope != 0, marks traversed
  // generators DONE, restores savedMarks, and delivers to that scope's catcher.
  action raiseAndUnwind = all {
    mc.length() > 0,
    trampolineActive,
    val popCount = findScopeBoundary(mc)
    val boundary = mc[popCount - 1]
    val newMc = mc.slice(popCount, mc.length())
    val hitGen = hasGenInTop(mc, popCount)
    val delivered = boundary.scope
    all {
      popCount > 0,
      mc' = newMc,
      marksDepth' = boundary.savedMarks,
      lastDeliveredCatcher' = delivered,
      deliveredWrongCatcher' = (deliveredWrongCatcher or (delivered != expectedCatcherOnThrow)),
      genState' = if (hitGen) GEN_DONE else genState,
      genSubKValid' = if (hitGen) false else genSubKValid,
      // Catcher catches the exception and exits the catcher scope if > 1.
      activeCatcher' = if (delivered > 1) delivered - 1 else 1,
      expectedCatcherOnThrow' = if (delivered > 1) delivered - 1 else 1,
      // Restore trampoline status iff remaining outer mc belongs directly to enclosing catcher.
      trampolineActive' = (newMc.length() > 0 and newMc[0].savedCatcher == (if (delivered > 1) delivered - 1 else 1)),
      nextFid' = nextFid,
      genCall1Catcher' = genCall1Catcher,
      staleReturnDetected' = staleReturnDetected,
      stuckGenOnThrow' = stuckGenOnThrow,
      ecState' = ecState,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
      t0Phase' = t0Phase,
      t1Phase' = t1Phase,
      unfrozenReplayDetected' = unfrozenReplayDetected,
      doubleConsumeDetected' = doubleConsumeDetected,
      oneShotWinners' = oneShotWinners,
    }
  }

  // Buggy unguarded raise (reproduces pre-fix stale frame leak, stuck GEN_RUNNING,
  // and Call #2 generator catcher bypass).
  action buggyUnguardedRaise = all {
    mc.length() > 0,
    activeCatcher > 1,
    val top = mc[0]
    all {
      // Old code did NOT pop mc on exception, left genState == GEN_RUNNING,
      // and on generator Call #2 delivered to genCall1Catcher instead of activeCatcher.
      mc' = mc,
      marksDepth' = marksDepth,
      activeCatcher' = activeCatcher - 1,
      trampolineActive' = true,
      expectedCatcherOnThrow' = activeCatcher - 1,
      lastDeliveredCatcher' = if (top.isGen) genCall1Catcher else activeCatcher,
      deliveredWrongCatcher' = (deliveredWrongCatcher or (top.isGen and genCall1Catcher != activeCatcher)),
      stuckGenOnThrow' = (stuckGenOnThrow or (genState == GEN_RUNNING)),
      nextFid' = nextFid,
      genState' = genState,
      genSubKValid' = genSubKValid,
      genCall1Catcher' = genCall1Catcher,
      staleReturnDetected' = staleReturnDetected,
      ecState' = ecState,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
      t0Phase' = t0Phase,
      t1Phase' = t1Phase,
      unfrozenReplayDetected' = unfrozenReplayDetected,
      doubleConsumeDetected' = doubleConsumeDetected,
      oneShotWinners' = oneShotWinners,
    }
  }

  // Thread 0 calls `resume ek`: CAS LIVE -> CONSUMED; if observes MULTISHOT,
  // must idempotently freeze pframe & prefix before replay.
  action t0ResumeCas = all {
    t0Phase == 0,
    if (ecState == EC_LIVE) all {
      ecState' = EC_CONSUMED,
      t0Phase' = 1,
      oneShotWinners' = oneShotWinners + 1,
      doubleConsumeDetected' = (doubleConsumeDetected or (oneShotWinners > 0)),
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
    } else if (ecState == EC_MULTISHOT) all {
      ecState' = ecState,
      t0Phase' = 2,
      oneShotWinners' = oneShotWinners,
      doubleConsumeDetected' = doubleConsumeDetected,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
    } else all {
      ecState' = ecState,
      t0Phase' = 3, // rejected cleanly
      oneShotWinners' = oneShotWinners,
      doubleConsumeDetected' = doubleConsumeDetected,
      ecPframeFrozen' = ecPframeFrozen,
      ecPrefixFrozen' = ecPrefixFrozen,
    },
    mc' = mc,
    activeCatcher' = activeCatcher,
    trampolineActive' = trampolineActive,
    marksDepth' = marksDepth,
    nextFid' = nextFid,
    genState' = genState,
    genSubKValid' = genSubKValid,
    genCall1Catcher' = genCall1Catcher,
    lastDeliveredCatcher' = lastDeliveredCatcher,
    expectedCatcherOnThrow' = expectedCatcherOnThrow,
    staleReturnDetected' = staleReturnDetected,
    deliveredWrongCatcher' = deliveredWrongCatcher,
    stuckGenOnThrow' = stuckGenOnThrow,
    t1Phase' = t1Phase,
    unfrozenReplayDetected' = unfrozenReplayDetected,
  }

  // Fixed t0 multishot-branch freezes idempotently before entering %resume-checked
  action t0FreezeAndReplay = all {
    t0Phase == 2,
    ecPframeFrozen' = true,
    ecPrefixFrozen' = true,
    t0Phase' = 3,
    unfrozenReplayDetected' = unfrozenReplayDetected,
    mc' = mc,
    activeCatcher' = activeCatcher,
    trampolineActive' = trampolineActive,
    marksDepth' = marksDepth,
    nextFid' = nextFid,
    genState' = genState,
    genSubKValid' = genSubKValid,
    genCall1Catcher' = genCall1Catcher,
    lastDeliveredCatcher' = lastDeliveredCatcher,
    expectedCatcherOnThrow' = expectedCatcherOnThrow,
    staleReturnDetected' = staleReturnDetected,
    deliveredWrongCatcher' = deliveredWrongCatcher,
    stuckGenOnThrow' = stuckGenOnThrow,
    ecState' = ecState,
    t1Phase' = t1Phase,
    doubleConsumeDetected' = doubleConsumeDetected,
    oneShotWinners' = oneShotWinners,
  }

  // Thread 1 calls `resume-multishot ek`: step 1 CAS LIVE -> MULTISHOT
  action t1PromoteCas = all {
    t1Phase == 0,
    if (ecState == EC_LIVE) all {
      ecState' = EC_MULTISHOT,
      t1Phase' = 1,
    } else if (ecState == EC_MULTISHOT) all {
      ecState' = ecState,
      t1Phase' = 1,
    } else all {
      ecState' = ecState,
      t1Phase' = 3, // rejected (already consumed)
    },
    mc' = mc,
    activeCatcher' = activeCatcher,
    trampolineActive' = trampolineActive,
    marksDepth' = marksDepth,
    nextFid' = nextFid,
    genState' = genState,
    genSubKValid' = genSubKValid,
    genCall1Catcher' = genCall1Catcher,
    lastDeliveredCatcher' = lastDeliveredCatcher,
    expectedCatcherOnThrow' = expectedCatcherOnThrow,
    staleReturnDetected' = staleReturnDetected,
    deliveredWrongCatcher' = deliveredWrongCatcher,
    stuckGenOnThrow' = stuckGenOnThrow,
    ecPframeFrozen' = ecPframeFrozen,
    ecPrefixFrozen' = ecPrefixFrozen,
    t0Phase' = t0Phase,
    unfrozenReplayDetected' = unfrozenReplayDetected,
    doubleConsumeDetected' = doubleConsumeDetected,
    oneShotWinners' = oneShotWinners,
  }

  // Thread 1 step 2: freezes pframe & prefix, then replays
  action t1FreezeAndReplay = all {
    t1Phase == 1,
    ecPframeFrozen' = true,
    ecPrefixFrozen' = true,
    t1Phase' = 3,
    unfrozenReplayDetected' = unfrozenReplayDetected,
    mc' = mc,
    activeCatcher' = activeCatcher,
    trampolineActive' = trampolineActive,
    marksDepth' = marksDepth,
    nextFid' = nextFid,
    genState' = genState,
    genSubKValid' = genSubKValid,
    genCall1Catcher' = genCall1Catcher,
    lastDeliveredCatcher' = lastDeliveredCatcher,
    expectedCatcherOnThrow' = expectedCatcherOnThrow,
    staleReturnDetected' = staleReturnDetected,
    deliveredWrongCatcher' = deliveredWrongCatcher,
    stuckGenOnThrow' = stuckGenOnThrow,
    ecState' = ecState,
    t0Phase' = t0Phase,
    doubleConsumeDetected' = doubleConsumeDetected,
    oneShotWinners' = oneShotWinners,
  }

  action step = any {
    enterCatcher,
    exitCatcher,
    enterPrompt,
    pushMark,
    callGenerator,
    yieldGenerator,
    normalReturn,
    raiseAndUnwind,
    t0ResumeCas,
    t0FreezeAndReplay,
    t1PromoteCas,
    t1FreezeAndReplay,
  }

  // Safety invariants
  val InvNoStaleReturn = not(staleReturnDetected)
  val InvExactCatcherDelivery = not(deliveredWrongCatcher)
  val InvNoGeneratorStuckRunning = not(stuckGenOnThrow) and
    ((genState == GEN_RUNNING) implies (mc.length() > 0))
  val InvNoUnfrozenMultishotReplay = not(unfrozenReplayDetected) and
    ((ecState == EC_MULTISHOT and t0Phase == 3) implies (ecPframeFrozen and ecPrefixFrozen))
  val InvLinearOneShot = not(doubleConsumeDetected) and (oneShotWinners <= 1)

  val InvAll = all {
    InvNoStaleReturn,
    InvExactCatcherDelivery,
    InvNoGeneratorStuckRunning,
    InvNoUnfrozenMultishotReplay,
    InvLinearOneShot,
  }

  // Unit tests verifying both happy-path unwinding and exact bug reproduction
  run nestedPromptUnwindTest = {
    init
      .then(enterPrompt)     // outer prompt (scope=1)
      .then(enterCatcher)    // inner catcher (activeCatcher=2)
      .then(enterPrompt)     // inner prompt (scope=2)
      .then(pushMark)
      .then(raiseAndUnwind)  // unwinds inner prompt ONLY, delivers to catcher 2
      .then(normalReturn)    // outer prompt returns cleanly!
      .expect(InvAll and mc.length() == 0 and marksDepth == 0 and lastDeliveredCatcher == 2)
  }

  run generatorCall2FaultPropagationTest = {
    init
      .then(callGenerator)   // Call #1 under catcher 1
      .then(yieldGenerator)  // yields -> SUSPENDED
      .then(enterCatcher)    // Call #2 under catcher 2
      .then(callGenerator)   // resumes -> RUNNING with scope=2
      .then(raiseAndUnwind)  // fault on Call #2 delivers to catcher 2 & marks DONE
      .expect(InvAll and genState == GEN_DONE and lastDeliveredCatcher == 2 and mc.length() == 0)
  }

  run concurrentResumePromoteRaceTest = {
    init
      .then(t1PromoteCas)        // T1 promotes LIVE -> MULTISHOT (before freeze!)
      .then(t0ResumeCas)         // T0 sees MULTISHOT
      .then(t0FreezeAndReplay)   // T0 freezes idempotently before replay
      .then(t1FreezeAndReplay)   // T1 freezes and replays
      .expect(InvAll and ecPframeFrozen and ecPrefixFrozen)
  }

  run buggyUnwindReproTest = {
    init
      .then(enterPrompt)
      .then(enterCatcher)
      .then(callGenerator)
      .then(buggyUnguardedRaise)
      .then(normalReturn)
      .expect(staleReturnDetected and stuckGenOnThrow)
  }
}
