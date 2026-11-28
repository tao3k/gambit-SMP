// Phase C49 Quint Specification:
// 1. Linearizable Zero-Orphan Nursery Close & Non-Zero Refill CAS
// 2. Zero-Capture Continuable-Exception Parity for with-finally & with-nursery
// 3. Seq-Cst Parker Searching-Counter Wakeup Freedom from Lost Wakeups

module nursery_cas_close_continuable_finally_and_parker_seq_smp {
  // --- Subsystem 1: Nursery active/cancelled/batch lifecycle ---
  var active: int             // total live credits (parent=1 + live children + cached batches)
  var cancelled: int          // 0=live, 1=cancelled, 2=closed
  var parentPhase: str        // "body" | "teardown" | "returned"
  var liveChildren: int       // spawned children not yet finished
  var cachedBatch: int        // parent carrier's pre-reserved unused credits
  var orphansSpawned: int     // must remain 0 forever

  // --- Subsystem 2: with-finally / with-nursery continuable exception guard ---
  var scopeState: str         // "active" | "in_eh" | "eh_suspended" | "resumed" | "exited"
  var inEh: bool
  var suspended: bool
  var finallyRuns: int
  var nurseryLive: bool
  var bodyResumed: bool
  var catcherSawCleaned: bool

  // --- Subsystem 3: Parker searching seq-cst wakeup ---
  var dqTail: int
  var waiters: int            // 1 = worker B already parked; 2 = worker A also parked
  var searching: int          // 1 = worker A searching, 0 = released
  var workerASawTail: int     // -1 = not scanned, 0 = missed, 1 = saw work
  var workerAParked: bool
  var wakeupSent: int

  action init = all {
    active' = 1,
    cancelled' = 0,
    parentPhase' = "body",
    liveChildren' = 0,
    cachedBatch' = 0,
    orphansSpawned' = 0,

    scopeState' = "active",
    inEh' = false,
    suspended' = false,
    finallyRuns' = 0,
    nurseryLive' = true,
    bodyResumed' = false,
    catcherSawCleaned' = true,

    dqTail' = 0,
    waiters' = 1,
    searching' = 1,
    workerASawTail' = -1,
    workerAParked' = false,
    wakeupSent' = 0,
  }

  // --- Nursery actions ---

  // Parent spawns using cached credit (0 atomics) or non-zero CAS refill (+32 -> +1 child, +31 batch)
  action parentSpawn = all {
    parentPhase == "body",
    liveChildren < 2,
    if (cachedBatch >= 1) all {
      cachedBatch' = cachedBatch - 1,
      liveChildren' = liveChildren + 1,
      active' = active,
    } else all {
      active > 0,
      active' = active + 4,      // small refill batch (4 = 1 child + 3 cached)
      cachedBatch' = 3,
      liveChildren' = liveChildren + 1,
    },
    cancelled' = cancelled,
    parentPhase' = parentPhase,
    orphansSpawned' = orphansSpawned,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // External fiber holding leaked nursery attempts spawn via non-zero CAS (cur > 0 -> cur + 1)
  action attackerSpawnCas = all {
    liveChildren < 3,
    if (active > 0) all {
      active' = active + 1,
      liveChildren' = liveChildren + 1,
      orphansSpawned' = if (parentPhase == "returned") orphansSpawned + 1 else orphansSpawned,
    } else all {
      // Closed: active == 0 is absorbing; CAS fails closed
      active' = active,
      liveChildren' = liveChildren,
      orphansSpawned' = orphansSpawned,
    },
    cancelled' = cancelled,
    parentPhase' = parentPhase,
    cachedBatch' = cachedBatch,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Child finishes and subtracts 1 from active
  action childFinish = all {
    liveChildren > 0,
    active > 0,
    liveChildren' = liveChildren - 1,
    active' = active - 1,
    cancelled' = cancelled,
    parentPhase' = parentPhase,
    cachedBatch' = cachedBatch,
    orphansSpawned' = orphansSpawned,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Parent enters teardown: flushes cachedBatch + drops parent credit (1) atomically
  action parentEnterTeardown = all {
    parentPhase == "body",
    active' = active - (cachedBatch + 1),
    cachedBatch' = 0,
    parentPhase' = "teardown",
    cancelled' = cancelled,
    liveChildren' = liveChildren,
    orphansSpawned' = orphansSpawned,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Parent finishes teardown once active == 0 and seals cancelled = 2
  action parentFinishTeardown = all {
    parentPhase == "teardown",
    active == 0,
    parentPhase' = "returned",
    cancelled' = 2,
    active' = active,
    liveChildren' = liveChildren,
    cachedBatch' = cachedBatch,
    orphansSpawned' = orphansSpawned,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // --- Continuable-exception with-finally / with-nursery actions ---

  // Body raises an exception; macro-dynamic-bind handler sets inEh = true before delegating
  // (even if SRFI-226 trampoline fires 'unwind hook, inEh == true suppresses premature cleanup)
  action raiseException = all {
    scopeState == "active",
    scopeState' = "in_eh",
    inEh' = true,
    suspended' = false,
    finallyRuns' = finallyRuns,
    nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed,
    catcherSawCleaned' = catcherSawCleaned,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Outer exception handler performs an algebraic effect (suspends dynamic-wind without cleanup)
  action ehPerformSuspend = all {
    scopeState == "in_eh",
    scopeState' = "eh_suspended",
    suspended' = true,
    inEh' = inEh,
    finallyRuns' = finallyRuns,
    nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed,
    catcherSawCleaned' = catcherSawCleaned,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Algebraic effect resumes back into outer exception handler
  action ehPerformResume = all {
    scopeState == "eh_suspended",
    scopeState' = "in_eh",
    suspended' = false,
    inEh' = inEh,
    finallyRuns' = finallyRuns,
    nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed,
    catcherSawCleaned' = catcherSawCleaned,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Outer with-exception-handler returns a value (continuable!): body resumes with resource live!
  action ehReturnContinuable = all {
    scopeState == "in_eh",
    not(suspended),
    scopeState' = "resumed",
    inEh' = false,
    bodyResumed' = true,
    suspended' = false,
    finallyRuns' = finallyRuns,
    nurseryLive' = nurseryLive,
    catcherSawCleaned' = catcherSawCleaned,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Outer with-exception-catcher escapes: cold-path dynamic-wind after runs cleanup BEFORE catcher
  action ehEscapeToCatcher = all {
    scopeState == "in_eh",
    not(suspended),
    scopeState' = "exited",
    inEh' = false,
    suspended' = false,
    finallyRuns' = if (finallyRuns == 0) 1 else finallyRuns,
    nurseryLive' = false,
    bodyResumed' = bodyResumed,
    catcherSawCleaned' = true,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Direct abort-current-continuation / call/1cc (inEh == false): unwind-guard runs cleanup once
  action directAbort = all {
    (scopeState == "active" or scopeState == "resumed"),
    not(inEh),
    scopeState' = "exited",
    inEh' = false,
    suspended' = false,
    finallyRuns' = if (finallyRuns == 0) 1 else finallyRuns,
    nurseryLive' = false,
    bodyResumed' = bodyResumed,
    catcherSawCleaned' = catcherSawCleaned,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // Normal exit of body (after initial run or after continuable resume)
  action normalScopeExit = all {
    (scopeState == "active" or scopeState == "resumed"),
    not(inEh),
    scopeState' = "exited",
    inEh' = false,
    suspended' = false,
    finallyRuns' = if (finallyRuns == 0) 1 else finallyRuns,
    nurseryLive' = false,
    bodyResumed' = bodyResumed,
    catcherSawCleaned' = catcherSawCleaned,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    dqTail' = dqTail, waiters' = waiters, searching' = searching,
    workerASawTail' = workerASawTail, workerAParked' = workerAParked, wakeupSent' = wakeupSent,
  }

  // --- Parker seq-cst searching wakeup actions ---

  // Worker A scans deque and releases searching (seq_cst)
  action workerAScanAndRelease = all {
    searching == 1,
    workerASawTail == -1,
    workerASawTail' = dqTail,
    searching' = 0,
    dqTail' = dqTail,
    waiters' = waiters,
    workerAParked' = workerAParked,
    wakeupSent' = wakeupSent,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
  }

  // Worker A attempts park: increments waiters, then re-checks dqTail (seq_cst)
  action workerAParkCheck = all {
    searching == 0,
    workerASawTail == 0,
    not(workerAParked),
    if (dqTail == 0) all {
      waiters' = waiters + 1,
      workerAParked' = true,
    } else all {
      // Observed work on pre-park recheck; aborts wait
      waiters' = waiters,
      workerAParked' = false,
    },
    dqTail' = dqTail,
    searching' = searching,
    workerASawTail' = if (dqTail == 0) workerASawTail else 1,
    wakeupSent' = wakeupSent,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
  }

  // Producer pushes work (STLR dqTail=1) then checks waiters (seq_cst) && searching == 0 (seq_cst)
  action producerPushAndWake = all {
    dqTail == 0,
    dqTail' = 1,
    wakeupSent' = if (waiters > 0 and searching == 0) wakeupSent + 1 else wakeupSent,
    waiters' = waiters,
    searching' = searching,
    workerASawTail' = workerASawTail,
    workerAParked' = workerAParked,
    active' = active, cancelled' = cancelled, parentPhase' = parentPhase,
    liveChildren' = liveChildren, cachedBatch' = cachedBatch, orphansSpawned' = orphansSpawned,
    scopeState' = scopeState, inEh' = inEh, suspended' = suspended,
    finallyRuns' = finallyRuns, nurseryLive' = nurseryLive,
    bodyResumed' = bodyResumed, catcherSawCleaned' = catcherSawCleaned,
  }

  action step = any {
    parentSpawn,
    attackerSpawnCas,
    childFinish,
    parentEnterTeardown,
    parentFinishTeardown,
    raiseException,
    ehPerformSuspend,
    ehPerformResume,
    ehReturnContinuable,
    ehEscapeToCatcher,
    directAbort,
    normalScopeExit,
    workerAScanAndRelease,
    workerAParkCheck,
    producerPushAndWake,
  }

  // --- Safety Invariants ---
  val invZeroOrphans = orphansSpawned == 0

  val invActiveAccounting =
    active == (if (parentPhase == "body") 1 else 0) + liveChildren + cachedBatch

  val invClosedAbsorbing =
    (parentPhase == "returned") implies (active == 0 and liveChildren == 0 and cancelled == 2)

  val invContinuableSafe =
    (scopeState == "resumed") implies (finallyRuns == 0 and nurseryLive and bodyResumed)

  val invFinallyOnce =
    finallyRuns <= 1 and ((scopeState == "exited") implies (finallyRuns == 1 and not(nurseryLive)))

  val invNoLostWakeup =
    not(dqTail > 0 and workerAParked and searching == 0 and wakeupSent == 0)

  val allInvs = and {
    invZeroOrphans,
    invActiveAccounting,
    invClosedAbsorbing,
    invContinuableSafe,
    invFinallyOnce,
    invNoLostWakeup,
  }

  // --- 5 Deterministic Unit Tests ---
  run zeroOrphanAfterTeardownTest =
    init
      .then(parentSpawn)
      .then(parentEnterTeardown)
      .then(attackerSpawnCas)   // live child still active -> awaited!
      .then(childFinish)
      .then(childFinish)
      .then(parentFinishTeardown)
      .then(attackerSpawnCas)   // active == 0 -> rejected!
      .expect(allInvs and orphansSpawned == 0 and active == 0 and cancelled == 2)

  run continuableReturnThenNormalExitTest =
    init
      .then(raiseException)
      .then(ehReturnContinuable)
      .expect(allInvs and finallyRuns == 0 and nurseryLive and bodyResumed)
      .then(normalScopeExit)
      .expect(allInvs and finallyRuns == 1 and not(nurseryLive))

  run continuableWithEffectSuspendResumeTest =
    init
      .then(raiseException)
      .then(ehPerformSuspend)
      .expect(allInvs and finallyRuns == 0 and nurseryLive and suspended)
      .then(ehPerformResume)
      .then(ehReturnContinuable)
      .then(normalScopeExit)
      .expect(allInvs and finallyRuns == 1 and bodyResumed)

  run escapingCatcherAndDirectAbortTest =
    init
      .then(raiseException)
      .then(ehEscapeToCatcher)
      .expect(allInvs and finallyRuns == 1 and not(nurseryLive) and catcherSawCleaned)

  run parkerSeqCstNoLostWakeupTest =
    init
      .then(workerAScanAndRelease)
      .then(producerPushAndWake)
      .then(workerAParkCheck)
      .expect(allInvs and wakeupSent == 1 and not(workerAParked))
}
