// Phase C52 Quint Specification:
// Deep-Handler Delegation & Dynamic Scope Isolation for Tail-Resumptive Effects:
// 1. Zero-allocation scope shift st.handlers = (cdr fs) during tail proc execution
//    (eliminating self-recursion on delegation & inner-handler scope hijacking)
// 2. Exact cross-extent prefix splicing after outer suspending perform/resume
//    under an extra resumer handler
// 3. Exact exception-handler restore before delegating to cur-eh (preserving
//    outer tail handler for inner catcher AND outer scope on continuable return)

module effect_tail_handler_delegation_and_scope_isolation_smp {
  // Frame IDs:
  //   1 = inner e2 handler (inside H_e1)
  //   2 = H_e1 tail handler being invoked
  //   3 = outer e1/e2 handler (outside H_e1)
  //   4 = extra resumer handler installed around (resume k ...)
  var stHandlers: Set[int]
  var phase: str                  // "body" | "in_tail" | "suspended" | "in_eh" | "caught" | "done"
  var resumerActive: bool
  var selfRecursions: int         // MUST stay 0!
  var scopeHijacks: int           // MUST stay 0!
  var resumerHandlersLost: int    // MUST stay 0!
  var catcherMissingH1: int       // MUST stay 0!
  var delegatedOk: bool

  action init = all {
    stHandlers' = Set(1, 2, 3),
    phase' = "body",
    resumerActive' = false,
    selfRecursions' = 0,
    scopeHijacks' = 0,
    resumerHandlersLost' = 0,
    catcherMissingH1' = 0,
    delegatedOk' = false,
  }

  // Body calls (perform e1): finds frame 2, shifts st.handlers to outer = {3}
  action enterTailHandler = all {
    phase == "body",
    stHandlers' = Set(3),
    phase' = "in_tail",
    resumerActive' = resumerActive,
    selfRecursions' = selfRecursions,
    scopeHijacks' = scopeHijacks,
    resumerHandlersLost' = resumerHandlersLost,
    catcherMissingH1' = catcherMissingH1,
    delegatedOk' = delegatedOk,
  }

  // Inside tail handler proc: delegate (perform e1) or (perform e2) -> sees ONLY {3}!
  action delegateInsideTail = all {
    phase == "in_tail",
    selfRecursions' = if (stHandlers.contains(2)) selfRecursions + 1 else selfRecursions,
    scopeHijacks' = if (stHandlers.contains(1)) scopeHijacks + 1 else scopeHijacks,
    delegatedOk' = (stHandlers.contains(3) and not(stHandlers.contains(1)) and not(stHandlers.contains(2))),
    stHandlers' = stHandlers,
    phase' = phase,
    resumerActive' = resumerActive,
    resumerHandlersLost' = resumerHandlersLost,
    catcherMissingH1' = catcherMissingH1,
  }

  // Inside tail handler proc: perform outer suspending effect handled by frame 3
  action suspendToOuter = all {
    phase == "in_tail",
    stHandlers' = Set(),
    phase' = "suspended",
    resumerActive' = resumerActive,
    selfRecursions' = selfRecursions,
    scopeHijacks' = scopeHijacks,
    resumerHandlersLost' = resumerHandlersLost,
    catcherMissingH1' = catcherMissingH1,
    delegatedOk' = delegatedOk,
  }

  // Resume suspended continuation under extra resumer handler 4 (curH = {3, 4} != {3})
  action resumeUnderExtraHandler = all {
    phase == "suspended",
    stHandlers' = Set(3, 4),
    phase' = "in_tail",
    resumerActive' = true,
    selfRecursions' = selfRecursions,
    scopeHijacks' = scopeHijacks,
    resumerHandlersLost' = resumerHandlersLost,
    catcherMissingH1' = catcherMissingH1,
    delegatedOk' = delegatedOk,
  }

  // Normal return from tail proc: splice paused prefix {1, 2} onto current stHandlers!
  action returnFromTail = all {
    phase == "in_tail",
    {
      val restored = stHandlers.union(Set(1, 2))
      all {
        stHandlers' = restored,
        phase' = "done",
        resumerHandlersLost' = if (resumerActive and not(restored.contains(4))) resumerHandlersLost + 1 else resumerHandlersLost,
        resumerActive' = resumerActive,
        selfRecursions' = selfRecursions,
        scopeHijacks' = scopeHijacks,
        catcherMissingH1' = catcherMissingH1,
        delegatedOk' = delegatedOk,
      }
    }
  }

  // Tail proc raises exception: macro-dynamic-bind restores {1,2} onto curH BEFORE delegating
  action raiseInsideTail = all {
    phase == "in_tail",
    stHandlers' = stHandlers.union(Set(1, 2)),
    phase' = "in_eh",
    resumerActive' = resumerActive,
    selfRecursions' = selfRecursions,
    scopeHijacks' = scopeHijacks,
    resumerHandlersLost' = resumerHandlersLost,
    catcherMissingH1' = catcherMissingH1,
    delegatedOk' = delegatedOk,
  }

  // Inner catcher (between frame 1 and frame 2) catches exception: frame 1 popped, {2, 3} intact!
  action escapeToInnerCatcher = all {
    phase == "in_eh",
    {
      val afterInnerPop = stHandlers.exclude(Set(1))
      all {
        stHandlers' = afterInnerPop,
        phase' = "caught",
        catcherMissingH1' = if (not(afterInnerPop.contains(2))) catcherMissingH1 + 1 else catcherMissingH1,
        resumerActive' = resumerActive,
        selfRecursions' = selfRecursions,
        scopeHijacks' = scopeHijacks,
        resumerHandlersLost' = resumerHandlersLost,
        delegatedOk' = delegatedOk,
      }
    }
  }

  // Outer with-exception-handler returns continuably: re-hide {1, 2} so proc continues in outer scope!
  action continuableReturnToTail = all {
    phase == "in_eh",
    stHandlers' = stHandlers.exclude(Set(1, 2)),
    phase' = "in_tail",
    resumerActive' = resumerActive,
    selfRecursions' = selfRecursions,
    scopeHijacks' = scopeHijacks,
    resumerHandlersLost' = resumerHandlersLost,
    catcherMissingH1' = catcherMissingH1,
    delegatedOk' = delegatedOk,
  }

  action step = any {
    enterTailHandler,
    delegateInsideTail,
    suspendToOuter,
    resumeUnderExtraHandler,
    returnFromTail,
    raiseInsideTail,
    escapeToInnerCatcher,
    continuableReturnToTail,
  }

  // --- Safety Invariants ---
  val invNoSelfRecursion = selfRecursions == 0
  val invNoScopeHijack = scopeHijacks == 0
  val invNoResumerLost = resumerHandlersLost == 0
  val invCatcherSeesOuter = catcherMissingH1 == 0
  val invTailScopeClean =
    (phase == "in_tail") implies (not(stHandlers.contains(1)) and not(stHandlers.contains(2)) and stHandlers.contains(3))
  val invDoneRestoresPrefix =
    (phase == "done") implies (stHandlers.contains(1) and stHandlers.contains(2) and stHandlers.contains(3))

  val allInvs = and {
    invNoSelfRecursion,
    invNoScopeHijack,
    invNoResumerLost,
    invCatcherSeesOuter,
    invTailScopeClean,
    invDoneRestoresPrefix,
  }

  // --- 5 Deterministic Unit Tests ---
  run tailDelegationNoSelfRecursionTest =
    init
      .then(enterTailHandler)
      .then(delegateInsideTail)
      .expect(allInvs and delegatedOk and selfRecursions == 0 and scopeHijacks == 0)
      .then(returnFromTail)
      .expect(allInvs and stHandlers == Set(1, 2, 3))

  run tailSuspendResumePreservesResumerHandlerTest =
    init
      .then(enterTailHandler)
      .then(suspendToOuter)
      .then(resumeUnderExtraHandler)
      .then(delegateInsideTail)
      .then(returnFromTail)
      .expect(allInvs and stHandlers == Set(1, 2, 3, 4) and resumerHandlersLost == 0)

  run tailEscapeToInnerCatcherKeepsOuterHandlerTest =
    init
      .then(enterTailHandler)
      .then(raiseInsideTail)
      .then(escapeToInnerCatcher)
      .expect(allInvs and stHandlers == Set(2, 3) and catcherMissingH1 == 0)

  run tailContinuableExceptionPreservesOuterScopeTest =
    init
      .then(enterTailHandler)
      .then(raiseInsideTail)
      .then(continuableReturnToTail)
      .then(delegateInsideTail)
      .then(returnFromTail)
      .expect(allInvs and delegatedOk and stHandlers == Set(1, 2, 3))

  run tailSuspendThenContinuableThenReturnTest =
    init
      .then(enterTailHandler)
      .then(suspendToOuter)
      .then(resumeUnderExtraHandler)
      .then(raiseInsideTail)
      .then(continuableReturnToTail)
      .then(returnFromTail)
      .expect(allInvs and stHandlers == Set(1, 2, 3, 4))
}
