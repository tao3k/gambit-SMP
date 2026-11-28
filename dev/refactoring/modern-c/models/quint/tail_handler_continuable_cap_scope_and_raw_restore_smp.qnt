// Quint Formal Specification:
// Zero-Capture Tail-Resumptive with-handler Continuable-Exception Parity,
// Lexical Tail-Capability Scope Safety (Including Multi-Shot Replay),
// and Raw call/1cc Exact LCA Unwind/Restore Hook Coherency.

module tail_handler_continuable_cap_scope_and_raw_restore_smp {
  // Tail-resumptive handler scope states
  pure val TH_OUTSIDE     = 0
  pure val TH_ACTIVE      = 1
  pure val TH_IN_OUTER_EH = 2
  pure val TH_EXITED      = 3

  // Lexical tail-capability states
  pure val CAP_OUTSIDE   = 0
  pure val CAP_ACTIVE    = 1
  pure val CAP_SUSPENDED = 2
  pure val CAP_EXITED    = 3

  var thPhase: int
  var thFrameInstalled: bool
  var thOuterSawInner: bool
  var thBodyContinued: bool
  var thContinuationLost: bool

  var capPhase: int
  var capLive: bool
  var capEscapedAbuse: bool
  var capMultishotBlocked: bool

  // Raw call/1cc cross-prompt LCA model:
  // Frame 0 = shared outer LCA (active in both),
  // Frame 1 = branch A frame (in cur-mc only -> dropped),
  // Frame 2 = branch B frame (in cap-mc only -> reentered)
  var f0State: int   // 1 = active, 0 = unwound
  var f1State: int
  var f2State: int
  var f0SpuriousTouch: bool

  action init = all {
    thPhase' = TH_OUTSIDE,
    thFrameInstalled' = false,
    thOuterSawInner' = false,
    thBodyContinued' = false,
    thContinuationLost' = false,
    capPhase' = CAP_OUTSIDE,
    capLive' = false,
    capEscapedAbuse' = false,
    capMultishotBlocked' = false,
    f0State' = 1,
    f1State' = 1,
    f2State' = 0,
    f0SpuriousTouch' = false,
  }

  // Enter tail-resumptive with-handler
  action thEnter: bool = all {
    thPhase == TH_OUTSIDE,
    thPhase' = TH_ACTIVE,
    thFrameInstalled' = true,
    thOuterSawInner' = false,
    thBodyContinued' = false,
    thContinuationLost' = false,
    capPhase' = capPhase,
    capLive' = capLive,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Raise inside tail-resumptive with-handler:
  // macro-dynamic-bind pops frame BEFORE delegating to outer exception handler
  action thRaiseToOuter: bool = all {
    thPhase == TH_ACTIVE,
    thFrameInstalled,
    thPhase' = TH_IN_OUTER_EH,
    thFrameInstalled' = false,
    thOuterSawInner' = false,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    capPhase' = capPhase,
    capLive' = capLive,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Outer with-exception-handler returns a value (continuable exception!):
  // Restores frame and resumes remaining body!
  action thContinuableReturn: bool = all {
    thPhase == TH_IN_OUTER_EH,
    thPhase' = TH_ACTIVE,
    thFrameInstalled' = true,
    thBodyContinued' = true,
    thContinuationLost' = false,
    thOuterSawInner' = thOuterSawInner,
    capPhase' = capPhase,
    capLive' = capLive,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Outer with-exception-catcher escapes (never returns):
  // Frame is already popped!
  action thEscapingCatch: bool = all {
    thPhase == TH_IN_OUTER_EH,
    thPhase' = TH_EXITED,
    thFrameInstalled' = false,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    capPhase' = capPhase,
    capLive' = capLive,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Normal exit from tail-resumptive with-handler
  action thNormalExit: bool = all {
    thPhase == TH_ACTIVE,
    thPhase' = TH_EXITED,
    thFrameInstalled' = false,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    capPhase' = capPhase,
    capLive' = capLive,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Enter call-with-tail-capability: live-box = true
  action capEnter: bool = all {
    capPhase == CAP_OUTSIDE,
    capPhase' = CAP_ACTIVE,
    capLive' = true,
    capEscapedAbuse' = false,
    capMultishotBlocked' = false,
    thPhase' = thPhase,
    thFrameInstalled' = thFrameInstalled,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Outer perform ('suspend): live-box = false while outside lexical scope!
  action capSuspend: bool = all {
    capPhase == CAP_ACTIVE,
    capPhase' = CAP_SUSPENDED,
    capLive' = false,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
    thPhase' = thPhase,
    thFrameInstalled' = thFrameInstalled,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Resume / multi-shot replay ('restore): re-enables live-box = true!
  action capRestore: bool = all {
    (capPhase == CAP_SUSPENDED or capPhase == CAP_EXITED),
    capPhase' = CAP_ACTIVE,
    capLive' = true,
    capMultishotBlocked' = false,
    capEscapedAbuse' = capEscapedAbuse,
    thPhase' = thPhase,
    thFrameInstalled' = thFrameInstalled,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Normal exit, exception, or 'unwind from call-with-tail-capability: live-box = false
  action capExitOrUnwind: bool = all {
    capPhase == CAP_ACTIVE,
    capPhase' = CAP_EXITED,
    capLive' = false,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
    thPhase' = thPhase,
    thFrameInstalled' = thFrameInstalled,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Attempt to invoke escaped capability outside active scope -> MUST be rejected (capLive == false)
  action capAttemptEscapedCall: bool = all {
    (capPhase == CAP_SUSPENDED or capPhase == CAP_EXITED),
    capEscapedAbuse' = capLive,
    capPhase' = capPhase,
    capLive' = capLive,
    capMultishotBlocked' = capMultishotBlocked,
    thPhase' = thPhase,
    thFrameInstalled' = thFrameInstalled,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    f0State' = f0State,
    f1State' = f1State,
    f2State' = f2State,
    f0SpuriousTouch' = f0SpuriousTouch,
  }

  // Raw call/1cc jump from branch A (f1 -> f0) to branch B (f2 -> f0):
  // dropped = [f1] gets 'unwind, reentered = [f2] gets 'restore, shared f0 untouched!
  action rawJumpAToB: bool = all {
    f0State == 1,
    f1State == 1,
    f2State == 0,
    f0State' = 1,
    f1State' = 0,
    f2State' = 1,
    f0SpuriousTouch' = false,
    thPhase' = thPhase,
    thFrameInstalled' = thFrameInstalled,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    capPhase' = capPhase,
    capLive' = capLive,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
  }

  // Raw call/1cc jump back from branch B (f2 -> f0) to branch A (f1 -> f0)
  action rawJumpBToA: bool = all {
    f0State == 1,
    f1State == 0,
    f2State == 1,
    f0State' = 1,
    f1State' = 1,
    f2State' = 0,
    f0SpuriousTouch' = false,
    thPhase' = thPhase,
    thFrameInstalled' = thFrameInstalled,
    thOuterSawInner' = thOuterSawInner,
    thBodyContinued' = thBodyContinued,
    thContinuationLost' = thContinuationLost,
    capPhase' = capPhase,
    capLive' = capLive,
    capEscapedAbuse' = capEscapedAbuse,
    capMultishotBlocked' = capMultishotBlocked,
  }

  action step = any {
    thEnter,
    thRaiseToOuter,
    thContinuableReturn,
    thEscapingCatch,
    thNormalExit,
    capEnter,
    capSuspend,
    capRestore,
    capExitOrUnwind,
    capAttemptEscapedCall,
    rawJumpAToB,
    rawJumpBToA,
  }

  // Invariants
  val invTailHandlerCleanStack =
    ((thPhase == TH_EXITED or thPhase == TH_IN_OUTER_EH) implies not(thFrameInstalled)) and
    ((thPhase == TH_ACTIVE) implies thFrameInstalled) and
    not(thOuterSawInner) and
    not(thContinuationLost)

  val invCapLexicalSafety =
    ((capPhase == CAP_ACTIVE) implies capLive) and
    ((capPhase == CAP_SUSPENDED or capPhase == CAP_EXITED) implies not(capLive)) and
    not(capEscapedAbuse) and
    not(capMultishotBlocked)

  val invRawLcaCoherent =
    (f0State == 1) and ((f1State + f2State) == 1) and not(f0SpuriousTouch)

  val allInvs =
    invTailHandlerCleanStack and
    invCapLexicalSafety and
    invRawLcaCoherent

  // 5 Unit Tests
  run tailHandlerContinuableTest = {
    init
      .then(thEnter)
      .then(thRaiseToOuter)
      .then(thContinuableReturn)
      .then(thNormalExit)
      .expect(allInvs and thBodyContinued and not(thFrameInstalled))
  }

  run tailHandlerEscapingCatchTest = {
    init
      .then(thEnter)
      .then(thRaiseToOuter)
      .then(thEscapingCatch)
      .expect(allInvs and not(thFrameInstalled))
  }

  run tailCapEscapedRejectedTest = {
    init
      .then(capEnter)
      .then(capExitOrUnwind)
      .then(capAttemptEscapedCall)
      .expect(allInvs and not(capLive) and not(capEscapedAbuse))
  }

  run tailCapSuspendAndMultishotRestoreTest = {
    init
      .then(capEnter)
      .then(capSuspend)
      .then(capAttemptEscapedCall)
      .then(capRestore)
      .then(capExitOrUnwind)
      .then(capRestore)
      .then(capExitOrUnwind)
      .expect(allInvs and not(capLive) and not(capEscapedAbuse))
  }

  run rawCall1ccDivergentRestoreTest = {
    init
      .then(rawJumpAToB)
      .then(rawJumpBToA)
      .expect(allInvs and f0State == 1 and f1State == 1 and f2State == 0)
  }
}
