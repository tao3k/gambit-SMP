// Phase C50 Quint Specification:
// 1. Structural Defense-in-Depth in %mc-return1 / %mc-return-vals / %mc-return1-with-fn
//    (skipping any 'unwind-guard frames so continuation-return never receives #f)
// 2. Zero-Leak Tail-Capability Guard Pop on Escaping Exceptions & Restore on Continuable Return
// 3. Zero-Capture, Zero-Leak, Continuable-Safe Fork-Join Combinators (%with-fork-join-guard)

module unwind_guard_return_safety_cap_pop_and_fork_join_smp {
  // --- Subsystem 1: Metacontinuation return guard-skip safety ---
  // Stack modeled top-first: "prompt" has valid escape-k, "guard" has escape-k=#f
  var mcTopIsGuard: bool
  var mcGuardCount: int
  var mcHasPrompt: bool
  var skippedHooksRun: int
  var nullEscapeKDeref: int   // MUST stay 0 forever!

  // --- Subsystem 2: Tail-capability guard lifecycle inside prompt + catcher/eh ---
  var capState: str           // "active" | "in_eh" | "resumed" | "exited"
  var capGuardOnMc: bool
  var capLive: bool

  // --- Subsystem 3: Fork-join right-future guard lifecycle ---
  var fjState: str            // "running_left" | "in_eh" | "eh_suspended" | "resumed_left" | "done"
  var fjGuardOnMc: bool
  var fjInEh: bool
  var fjSuspended: bool
  var fjRightDone: bool
  var fjRightJoins: int
  var fjCatcherSawJoined: bool
  var fjLeftCompleted: bool

  action init = all {
    mcTopIsGuard' = false,
    mcGuardCount' = 0,
    mcHasPrompt' = true,
    skippedHooksRun' = 0,
    nullEscapeKDeref' = 0,

    capState' = "active",
    capGuardOnMc' = true,
    capLive' = true,

    fjState' = "running_left",
    fjGuardOnMc' = true,
    fjInEh' = false,
    fjSuspended' = false,
    fjRightDone' = false,
    fjRightJoins' = 0,
    fjCatcherSawJoined' = true,
    fjLeftCompleted' = false,
  }

  // --- Subsystem 1: mc-return guard skip ---
  action pushStrayGuardOnPrompt = all {
    mcHasPrompt,
    mcGuardCount < 3,
    mcTopIsGuard' = true,
    mcGuardCount' = mcGuardCount + 1,
    mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun,
    nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
    fjState' = fjState, fjGuardOnMc' = fjGuardOnMc, fjInEh' = fjInEh,
    fjSuspended' = fjSuspended, fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins, fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
  }

  // %mc-return* pops any guard frames (firing their unwind hooks) before returning to prompt
  action mcReturnSkipGuards = all {
    mcHasPrompt,
    if (mcTopIsGuard and mcGuardCount > 0) all {
      mcGuardCount' = mcGuardCount - 1,
      mcTopIsGuard' = (mcGuardCount - 1 > 0),
      skippedHooksRun' = skippedHooksRun + 1,
      mcHasPrompt' = mcHasPrompt,
      nullEscapeKDeref' = nullEscapeKDeref,
    } else all {
      // Top is real prompt with valid escape-k -> safe return, zero null deref!
      mcHasPrompt' = false,
      mcTopIsGuard' = false,
      mcGuardCount' = 0,
      skippedHooksRun' = skippedHooksRun,
      nullEscapeKDeref' = nullEscapeKDeref,
    },
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
    fjState' = fjState, fjGuardOnMc' = fjGuardOnMc, fjInEh' = fjInEh,
    fjSuspended' = fjSuspended, fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins, fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
  }

  // --- Subsystem 2: Tail-capability guard pop/restore ---
  action capRaiseToNonTrampEh = all {
    capState == "active",
    // Pops guard-frame AND deactivates capLive BEFORE calling cur-eh!
    capState' = "in_eh",
    capGuardOnMc' = false,
    capLive' = false,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    fjState' = fjState, fjGuardOnMc' = fjGuardOnMc, fjInEh' = fjInEh,
    fjSuspended' = fjSuspended, fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins, fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
  }

  action capEhEscape = all {
    capState == "in_eh",
    // Escaping catcher lands with capGuardOnMc == false (0 stale guards!) and capLive == false
    capState' = "exited",
    capGuardOnMc' = false,
    capLive' = false,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    fjState' = fjState, fjGuardOnMc' = fjGuardOnMc, fjInEh' = fjInEh,
    fjSuspended' = fjSuspended, fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins, fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
  }

  action capEhReturnContinuable = all {
    capState == "in_eh",
    // Continuable return restores BOTH guard-frame AND capLive
    capState' = "resumed",
    capGuardOnMc' = true,
    capLive' = true,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    fjState' = fjState, fjGuardOnMc' = fjGuardOnMc, fjInEh' = fjInEh,
    fjSuspended' = fjSuspended, fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins, fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
  }

  action capNormalExit = all {
    (capState == "active" or capState == "resumed"),
    capState' = "exited",
    capGuardOnMc' = false,
    capLive' = false,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    fjState' = fjState, fjGuardOnMc' = fjGuardOnMc, fjInEh' = fjInEh,
    fjSuspended' = fjSuspended, fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins, fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
  }

  // --- Subsystem 3: Fork-join zero-capture guard ---
  action fjLeftRaise = all {
    fjState == "running_left",
    fjState' = "in_eh",
    fjInEh' = true,
    fjSuspended' = false,
    fjGuardOnMc' = fjGuardOnMc,
    fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins,
    fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
  }

  action fjEhPerformSuspend = all {
    fjState == "in_eh",
    fjState' = "eh_suspended",
    fjSuspended' = true,
    fjInEh' = fjInEh,
    fjGuardOnMc' = fjGuardOnMc,
    fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins,
    fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
  }

  action fjEhPerformResume = all {
    fjState == "eh_suspended",
    fjState' = "in_eh",
    fjSuspended' = false,
    fjInEh' = fjInEh,
    fjGuardOnMc' = fjGuardOnMc,
    fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins,
    fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
  }

  action fjEhReturnContinuable = all {
    fjState == "in_eh",
    not(fjSuspended),
    fjState' = "resumed_left",
    fjInEh' = false,
    fjSuspended' = false,
    fjGuardOnMc' = fjGuardOnMc,
    fjRightDone' = fjRightDone,
    fjRightJoins' = fjRightJoins,
    fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
  }

  action fjEhEscape = all {
    fjState == "in_eh",
    not(fjSuspended),
    fjState' = "done",
    fjInEh' = false,
    fjSuspended' = false,
    fjGuardOnMc' = false,
    fjRightDone' = true,
    fjRightJoins' = if (fjRightJoins == 0) 1 else fjRightJoins,
    fjCatcherSawJoined' = true,
    fjLeftCompleted' = fjLeftCompleted,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
  }

  action fjDirectAbort = all {
    (fjState == "running_left" or fjState == "resumed_left"),
    not(fjInEh),
    fjState' = "done",
    fjInEh' = false,
    fjSuspended' = false,
    fjGuardOnMc' = false,
    fjRightDone' = true,
    fjRightJoins' = if (fjRightJoins == 0) 1 else fjRightJoins,
    fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = fjLeftCompleted,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
  }

  action fjNormalFinish = all {
    (fjState == "running_left" or fjState == "resumed_left"),
    not(fjInEh),
    fjState' = "done",
    fjInEh' = false,
    fjSuspended' = false,
    fjGuardOnMc' = false,
    fjRightDone' = true,
    fjRightJoins' = if (fjRightJoins == 0) 1 else fjRightJoins,
    fjCatcherSawJoined' = fjCatcherSawJoined,
    fjLeftCompleted' = true,
    mcTopIsGuard' = mcTopIsGuard, mcGuardCount' = mcGuardCount, mcHasPrompt' = mcHasPrompt,
    skippedHooksRun' = skippedHooksRun, nullEscapeKDeref' = nullEscapeKDeref,
    capState' = capState, capGuardOnMc' = capGuardOnMc, capLive' = capLive,
  }

  action step = any {
    pushStrayGuardOnPrompt,
    mcReturnSkipGuards,
    capRaiseToNonTrampEh,
    capEhEscape,
    capEhReturnContinuable,
    capNormalExit,
    fjLeftRaise,
    fjEhPerformSuspend,
    fjEhPerformResume,
    fjEhReturnContinuable,
    fjEhEscape,
    fjDirectAbort,
    fjNormalFinish,
  }

  // --- Safety Invariants ---
  val invNoNullEscapeKDeref = nullEscapeKDeref == 0

  val invCapNoStaleGuardOnExit =
    (capState == "exited") implies (not(capGuardOnMc) and not(capLive))

  val invCapLiveWhenActiveOrResumed =
    (capState == "active" or capState == "resumed") implies (capGuardOnMc and capLive)

  val invFjNoStaleGuardOnDone =
    (fjState == "done") implies (not(fjGuardOnMc) and fjRightDone and fjRightJoins == 1)

  val invFjContinuableNotPrematureJoin =
    (fjState == "resumed_left") implies (fjRightJoins == 0 and fjGuardOnMc)

  val invFjJoinAtMostOnce = fjRightJoins <= 1 and fjCatcherSawJoined

  val allInvs = and {
    invNoNullEscapeKDeref,
    invCapNoStaleGuardOnExit,
    invCapLiveWhenActiveOrResumed,
    invFjNoStaleGuardOnDone,
    invFjContinuableNotPrematureJoin,
    invFjJoinAtMostOnce,
  }

  // --- 5 Deterministic Unit Tests ---
  run mcReturnSkipsStrayGuardsTest =
    init
      .then(pushStrayGuardOnPrompt)
      .then(pushStrayGuardOnPrompt)
      .then(mcReturnSkipGuards)
      .then(mcReturnSkipGuards)
      .then(mcReturnSkipGuards)
      .expect(allInvs and not(mcHasPrompt) and skippedHooksRun == 2 and nullEscapeKDeref == 0)

  run capEscapeLeavesNoStaleGuardTest =
    init
      .then(capRaiseToNonTrampEh)
      .then(capEhEscape)
      .expect(allInvs and not(capGuardOnMc) and not(capLive))

  run capContinuableRestoresGuardTest =
    init
      .then(capRaiseToNonTrampEh)
      .then(capEhReturnContinuable)
      .expect(allInvs and capGuardOnMc and capLive)
      .then(capNormalExit)
      .expect(allInvs and not(capGuardOnMc) and not(capLive))

  run fjContinuableWithSuspendResumeTest =
    init
      .then(fjLeftRaise)
      .then(fjEhPerformSuspend)
      .expect(allInvs and fjRightJoins == 0 and fjSuspended)
      .then(fjEhPerformResume)
      .then(fjEhReturnContinuable)
      .expect(allInvs and fjRightJoins == 0 and fjGuardOnMc)
      .then(fjNormalFinish)
      .expect(allInvs and fjLeftCompleted and fjRightDone and fjRightJoins == 1 and not(fjGuardOnMc))

  run fjEscapeAndAbortJoinRightOnceTest =
    init
      .then(fjLeftRaise)
      .then(fjEhEscape)
      .expect(allInvs and fjRightDone and fjRightJoins == 1 and not(fjGuardOnMc) and fjCatcherSawJoined)
}
