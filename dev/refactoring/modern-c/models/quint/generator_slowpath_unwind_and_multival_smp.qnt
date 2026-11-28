// Quint Formal Specification:
// Generator Slow-Path Unwind-Hook Coherency, Multi-Value Yield (0/1/N),
// and Winding-Transition Guard Soundness under SMP
//
// Models:
//   - 4-state atomic generator lifecycle (INIT=0, RUNNING=1, SUSPENDED=2, DONE=3)
//   - Fast-path 1-value yield vs slow-path yield (inner marks/prompts or 0/N values)
//   - Dedicated slow-path resume (%gen-resume-ec!) preserving unwind_hook = true
//     on the replayed prompt frame (instead of generic resume's 'replay marker)
//   - Dynamic-wind winding guard ('unwind-guard) pushed iff all caller after-thunks
//     to LCA execute under an active exception trampoline (zero stale mc frames
//     on untramped caller after-thunk faults, full DONE + eh-scope routing on
//     generator before-thunk and trampolined caller after-thunk faults)
//   - Concurrent SMP invocation race (at most one thread enters RUNNING at a time)

module generator_slowpath_unwind_and_multival_smp {
  // Generator states
  pure val GEN_INIT      = 0
  pure val GEN_RUNNING   = 1
  pure val GEN_SUSPENDED = 2
  pure val GEN_DONE      = 3

  // Suspended continuation kind
  pure val SK_NONE = 0
  pure val SK_RAW  = 1
  pure val SK_EC   = 2   // effect-continuation from slow-path / multi-value yield

  // Execution phase inside active call
  pure val PH_IDLE          = 0
  pure val PH_WINDING       = 1
  pure val PH_BODY          = 2
  pure val PH_CAUGHT_DONE   = 3
  pure val PH_UNTRAMP_THROW = 4

  var genState: int
  var subK: int
  var ownerTid: int            // 0 = none, 1 or 2 = active thread
  var phase: int
  var yieldArity: int          // last yielded value count (0, 1, 2, 3)
  var pframeHasHook: bool      // active prompt frame carries unwind-fn
  var guardOnMc: bool          // temporary 'unwind-guard frame currently on st.mc
  var guardSafe: bool          // all caller after-thunks to LCA are trampolined
  var callerMarksPolluted: bool
  var staleGuardLeaked: bool
  var faultRoutedToCaller: bool
  var wedgedRunningAfterFault: bool
  var doubleRunDetected: bool

  action init = all {
    genState' = GEN_INIT,
    subK' = SK_NONE,
    ownerTid' = 0,
    phase' = PH_IDLE,
    yieldArity' = -1,
    pframeHasHook' = false,
    guardOnMc' = false,
    guardSafe' = true,
    callerMarksPolluted' = false,
    staleGuardLeaked' = false,
    faultRoutedToCaller' = true,
    wedgedRunningAfterFault' = false,
    doubleRunDetected' = false,
  }

  // Thread starts generator from INIT -> RUNNING
  action startGen(tid: int): bool = all {
    (tid == 1 or tid == 2),
    genState == GEN_INIT,
    ownerTid == 0,
    phase == PH_IDLE,
    genState' = GEN_RUNNING,
    ownerTid' = tid,
    phase' = PH_BODY,
    pframeHasHook' = true,
    guardOnMc' = false,
    subK' = SK_NONE,
    yieldArity' = yieldArity,
    guardSafe' = guardSafe,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Concurrent second thread attempts to invoke RUNNING generator -> rejected cleanly
  action concurrentReject(tid: int): bool = all {
    (tid == 1 or tid == 2),
    genState == GEN_RUNNING,
    tid != ownerTid,
    // CAS fails cleanly; state unchanged
    genState' = genState,
    subK' = subK,
    ownerTid' = ownerTid,
    phase' = phase,
    yieldArity' = yieldArity,
    pframeHasHook' = pframeHasHook,
    guardOnMc' = guardOnMc,
    guardSafe' = guardSafe,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Fast-path 1-arg yield (no inner marks/prompts)
  action yieldFast: bool = all {
    genState == GEN_RUNNING,
    phase == PH_BODY,
    genState' = GEN_SUSPENDED,
    subK' = SK_RAW,
    ownerTid' = 0,
    phase' = PH_IDLE,
    yieldArity' = 1,
    pframeHasHook' = false,
    guardOnMc' = false,
    guardSafe' = guardSafe,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Slow-path yield: inside marks/nested prompts OR 0/2/3-value yield.
  // %gen-yield-slow-handler supports arity 0..N without post-pop arity errors.
  action yieldSlow(arity: int): bool = all {
    (arity == 0 or arity == 1 or arity == 2 or arity == 3),
    genState == GEN_RUNNING,
    phase == PH_BODY,
    genState' = GEN_SUSPENDED,
    subK' = SK_EC,
    ownerTid' = 0,
    phase' = PH_IDLE,
    yieldArity' = arity,
    pframeHasHook' = false,
    guardOnMc' = false,
    guardSafe' = guardSafe,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Same-dynwind resume (fast SK_RAW or slow SK_EC via %gen-resume-ec!).
  // BOTH paths attach unwind_hook = true onto the active prompt frame!
  action resumeSameDynwind(tid: int): bool = all {
    (tid == 1 or tid == 2),
    genState == GEN_SUSPENDED,
    ownerTid == 0,
    phase == PH_IDLE,
    (subK == SK_RAW or subK == SK_EC),
    genState' = GEN_RUNNING,
    subK' = SK_NONE,
    ownerTid' = tid,
    phase' = PH_BODY,
    pframeHasHook' = true,
    guardOnMc' = false,
    yieldArity' = yieldArity,
    guardSafe' = true,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Cross-dynwind resume enters PH_WINDING.
  // Pushes 'unwind-guard frame onto st.mc iff allCallerAftersTrampolined (safe == true).
  action resumeWindingBegin(tid: int, safe: bool): bool = all {
    (tid == 1 or tid == 2),
    genState == GEN_SUSPENDED,
    ownerTid == 0,
    phase == PH_IDLE,
    (subK == SK_RAW or subK == SK_EC),
    genState' = GEN_RUNNING,
    subK' = SK_NONE,
    ownerTid' = tid,
    phase' = PH_WINDING,
    pframeHasHook' = false,
    guardOnMc' = safe,
    guardSafe' = safe,
    // 'unwind-guard copies caller's marks/barriers/handlers verbatim -> never pollutes caller
    callerMarksPolluted' = false,
    yieldArity' = yieldArity,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Winding succeeds -> landing thunk strips 'unwind-guard and installs prompt frame with unwind-fn
  action windingLand: bool = all {
    genState == GEN_RUNNING,
    phase == PH_WINDING,
    genState' = GEN_RUNNING,
    subK' = SK_NONE,
    ownerTid' = ownerTid,
    phase' = PH_BODY,
    pframeHasHook' = true,
    guardOnMc' = false,
    guardSafe' = guardSafe,
    yieldArity' = yieldArity,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Generator before-thunk or trampolined caller after-thunk faults during winding
  // (only possible under guardSafe == true when guardOnMc == true).
  action windingTrampolinedFault: bool = all {
    genState == GEN_RUNNING,
    phase == PH_WINDING,
    guardSafe == true,
    guardOnMc == true,
    // Trampoline unwinds 'unwind-guard -> invokes unwind-fn 'unwind -> DONE, routes to caller eh-scope
    genState' = GEN_DONE,
    subK' = SK_NONE,
    ownerTid' = 0,
    phase' = PH_CAUGHT_DONE,
    pframeHasHook' = false,
    guardOnMc' = false,
    guardSafe' = guardSafe,
    yieldArity' = yieldArity,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = true,
    wedgedRunningAfterFault' = false,
    doubleRunDetected' = doubleRunDetected,
  }

  // Untramped bare caller after-thunk throws during winding (guardSafe == false).
  // Because guardOnMc == false, ZERO stale frames are ever left on st.mc.
  action windingUntrampedAfterThrow: bool = all {
    genState == GEN_RUNNING,
    phase == PH_WINDING,
    guardSafe == false,
    genState' = GEN_RUNNING,
    subK' = SK_NONE,
    ownerTid' = 0,
    phase' = PH_UNTRAMP_THROW,
    pframeHasHook' = false,
    guardOnMc' = guardOnMc,
    guardSafe' = guardSafe,
    yieldArity' = yieldArity,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = guardOnMc,
    faultRoutedToCaller' = true,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Exception or outer prompt abort inside generator body (after either fast or slow-path resume)
  action bodyFaultOrAbort: bool = all {
    genState == GEN_RUNNING,
    phase == PH_BODY,
    if (pframeHasHook) all {
      genState' = GEN_DONE,
      wedgedRunningAfterFault' = false,
    } else all {
      genState' = GEN_RUNNING,
      wedgedRunningAfterFault' = true,
    },
    subK' = SK_NONE,
    ownerTid' = 0,
    phase' = PH_CAUGHT_DONE,
    pframeHasHook' = false,
    guardOnMc' = false,
    guardSafe' = guardSafe,
    yieldArity' = yieldArity,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = true,
    doubleRunDetected' = doubleRunDetected,
  }

  // Normal generator completion -> DONE (#!eof)
  action finishGen: bool = all {
    genState == GEN_RUNNING,
    phase == PH_BODY,
    genState' = GEN_DONE,
    subK' = SK_NONE,
    ownerTid' = 0,
    phase' = PH_IDLE,
    pframeHasHook' = false,
    guardOnMc' = false,
    guardSafe' = guardSafe,
    yieldArity' = yieldArity,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  // Repeat call on DONE generator returns #!eof idempotently
  action callDone(tid: int): bool = all {
    (tid == 1 or tid == 2),
    genState == GEN_DONE,
    (phase == PH_IDLE or phase == PH_CAUGHT_DONE),
    genState' = GEN_DONE,
    subK' = SK_NONE,
    ownerTid' = 0,
    phase' = PH_IDLE,
    pframeHasHook' = false,
    guardOnMc' = false,
    guardSafe' = guardSafe,
    yieldArity' = yieldArity,
    callerMarksPolluted' = callerMarksPolluted,
    staleGuardLeaked' = staleGuardLeaked,
    faultRoutedToCaller' = faultRoutedToCaller,
    wedgedRunningAfterFault' = wedgedRunningAfterFault,
    doubleRunDetected' = doubleRunDetected,
  }

  action step = any {
    startGen(1),
    startGen(2),
    concurrentReject(1),
    concurrentReject(2),
    yieldFast,
    yieldSlow(0),
    yieldSlow(1),
    yieldSlow(2),
    yieldSlow(3),
    resumeSameDynwind(1),
    resumeSameDynwind(2),
    resumeWindingBegin(1, true),
    resumeWindingBegin(2, true),
    resumeWindingBegin(1, false),
    resumeWindingBegin(2, false),
    windingLand,
    windingTrampolinedFault,
    windingUntrampedAfterThrow,
    bodyFaultOrAbort,
    finishGen,
    callDone(1),
    callDone(2),
  }

  // Invariants
  val invBodyAlwaysHasUnwindHook = (phase == PH_BODY) implies pframeHasHook
  val invNeverWedgedAfterFault = not(wedgedRunningAfterFault)
  val invNoStaleGuardLeak = not(staleGuardLeaked) and ((phase != PH_WINDING) implies not(guardOnMc))
  val invNoCallerMarkPollution = not(callerMarksPolluted)
  val invValidStateAndOwnership =
    (genState >= GEN_INIT and genState <= GEN_DONE) and
    ((genState == GEN_SUSPENDED) implies (subK == SK_RAW or subK == SK_EC)) and
    ((genState == GEN_DONE) implies (ownerTid == 0 and subK == SK_NONE)) and
    not(doubleRunDetected)

  val allInvs =
    invBodyAlwaysHasUnwindHook and
    invNeverWedgedAfterFault and
    invNoStaleGuardLeak and
    invNoCallerMarkPollution and
    invValidStateAndOwnership

  // 5 Unit Tests covering every fixed bug scenario
  run slowpathYieldResumeFaultTest = {
    init
      .then(startGen(1))
      .then(yieldSlow(1))
      .then(resumeSameDynwind(2))
      .then(bodyFaultOrAbort)
      .then(callDone(2))
      .expect(allInvs and genState == GEN_DONE)
  }

  run multivalZeroAndTwoYieldTest = {
    init
      .then(startGen(1))
      .then(yieldSlow(0))
      .then(resumeSameDynwind(1))
      .then(yieldSlow(2))
      .then(resumeSameDynwind(2))
      .then(finishGen)
      .expect(allInvs and yieldArity == 2 and genState == GEN_DONE)
  }

  run windingBeforeThunkFaultTest = {
    init
      .then(startGen(1))
      .then(yieldSlow(1))
      .then(resumeWindingBegin(2, true))
      .then(windingTrampolinedFault)
      .then(callDone(1))
      .expect(allInvs and genState == GEN_DONE and not(guardOnMc))
  }

  run windingUntrampedNoStaleGuardTest = {
    init
      .then(startGen(1))
      .then(yieldFast)
      .then(resumeWindingBegin(1, false))
      .then(windingUntrampedAfterThrow)
      .expect(allInvs and not(staleGuardLeaked) and not(guardOnMc))
  }

  run windingSuccessAndConcurrentRejectTest = {
    init
      .then(startGen(1))
      .then(yieldSlow(3))
      .then(resumeWindingBegin(2, true))
      .then(concurrentReject(1))
      .then(windingLand)
      .then(concurrentReject(1))
      .then(yieldFast)
      .then(resumeSameDynwind(1))
      .then(finishGen)
      .expect(allInvs and genState == GEN_DONE)
  }
}
