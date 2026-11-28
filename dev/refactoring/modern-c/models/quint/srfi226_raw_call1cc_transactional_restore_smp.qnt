// Quint formal model for (srfi 226):
//   Transactional full control-state restoration (st.mc, st.marks, st.barriers,
//   st.handlers) on raw call/1cc invocation across inner prompts, marks, effect
//   handlers, continuation barriers, and dynamic-wind after-thunks.

module srfi226_raw_call1cc_transactional_restore_smp {
  // Phases:
  //   0 = captured raw call/1cc at depth 0 (mc=0, marks=0, handlers=0)
  //   1 = inside inner prompt + mark + effect handler + dynamic-wind (depth 1)
  //   2 = running dynamic-wind after-thunk during raw call/1cc unwind
  //   3 = landed at captured raw call/1cc continuation (depth 0 restored)
  //   4 = after-thunk threw exception caught inside inner prompt (depth 1 intact)
  var phase: int
  var mcDepth: int
  var marksDepth: int
  var handlersDepth: int
  var hasBarrier: bool
  var hasDynwind: bool
  var rawConsumed: bool
  var zombiePromptAfterLand: bool
  var afterSawCorruptedState: bool
  var barrierBypassed: bool

  action init = all {
    phase' = 0,
    mcDepth' = 0,
    marksDepth' = 0,
    handlersDepth' = 0,
    hasBarrier' = false,
    hasDynwind' = false,
    rawConsumed' = false,
    zombiePromptAfterLand' = false,
    afterSawCorruptedState' = false,
    barrierBypassed' = false,
  }

  // Enter inner prompt + continuation mark + effect handler (with optional dynwind/barrier)
  action enterInnerScope(withDw: bool, withBar: bool): bool = all {
    phase == 0,
    phase' = 1,
    mcDepth' = 1,
    marksDepth' = 1,
    handlersDepth' = 1,
    hasDynwind' = withDw,
    hasBarrier' = withBar,
    rawConsumed' = rawConsumed,
    zombiePromptAfterLand' = zombiePromptAfterLand,
    afterSawCorruptedState' = afterSawCorruptedState,
    barrierBypassed' = barrierBypassed,
  }

  // Invoke raw call/1cc when no dynwind separates target (fast path: direct restore)
  action invokeRawFast = all {
    phase == 1,
    not(rawConsumed),
    not(hasDynwind),
    // Note: escaping OUT of a barrier is allowed (only entering a barrier is blocked)
    phase' = 3,
    mcDepth' = 0,
    marksDepth' = 0,
    handlersDepth' = 0,
    rawConsumed' = true,
    zombiePromptAfterLand' = false,
    hasBarrier' = false,
    hasDynwind' = hasDynwind,
    afterSawCorruptedState' = afterSawCorruptedState,
    barrierBypassed' = barrierBypassed,
  }

  // Invoke raw call/1cc across dynamic-wind: defer st commit until after-thunk completes
  action invokeRawStartUnwind = all {
    phase == 1,
    not(rawConsumed),
    hasDynwind,
    phase' = 2,
    // Transactional: inner mc/marks/handlers remain intact during after-thunk!
    mcDepth' = mcDepth,
    marksDepth' = marksDepth,
    handlersDepth' = handlersDepth,
    rawConsumed' = true,
    hasBarrier' = hasBarrier,
    hasDynwind' = hasDynwind,
    zombiePromptAfterLand' = zombiePromptAfterLand,
    afterSawCorruptedState' = (afterSawCorruptedState or mcDepth != 1 or marksDepth != 1 or handlersDepth != 1),
    barrierBypassed' = barrierBypassed,
  }

  // Dynamic-wind after-thunk completes normally -> landing thunk restores exact captured st
  action afterThunkCompleteAndLand = all {
    phase == 2,
    phase' = 3,
    mcDepth' = 0,
    marksDepth' = 0,
    handlersDepth' = 0,
    hasBarrier' = false,
    hasDynwind' = false,
    rawConsumed' = rawConsumed,
    zombiePromptAfterLand' = false,
    afterSawCorruptedState' = afterSawCorruptedState,
    barrierBypassed' = barrierBypassed,
  }

  // Dynamic-wind after-thunk throws caught inside inner prompt -> inner scope intact!
  action afterThunkThrowCaughtInner = all {
    phase == 2,
    phase' = 4,
    mcDepth' = mcDepth,
    marksDepth' = marksDepth,
    handlersDepth' = handlersDepth,
    hasBarrier' = hasBarrier,
    hasDynwind' = false,
    rawConsumed' = rawConsumed,
    zombiePromptAfterLand' = zombiePromptAfterLand,
    afterSawCorruptedState' = (afterSawCorruptedState or mcDepth != 1 or marksDepth != 1 or handlersDepth != 1),
    barrierBypassed' = barrierBypassed,
  }

  // Buggy action: raw call/1cc jumps without restoring st.mc/marks/handlers (leaks zombie frames!)
  action buggyRawSkipRestore = all {
    phase == 1,
    not(rawConsumed),
    phase' = 3,
    mcDepth' = mcDepth,
    marksDepth' = marksDepth,
    handlersDepth' = handlersDepth,
    rawConsumed' = true,
    zombiePromptAfterLand' = (mcDepth != 0 or marksDepth != 0 or handlersDepth != 0),
    hasBarrier' = hasBarrier,
    hasDynwind' = hasDynwind,
    afterSawCorruptedState' = afterSawCorruptedState,
    barrierBypassed' = barrierBypassed,
  }

  // Buggy action: raw call/1cc wipes st BEFORE dynamic-wind after-thunk runs
  action buggyRawEagerWipeBeforeAfter = all {
    phase == 1,
    not(rawConsumed),
    hasDynwind,
    phase' = 2,
    mcDepth' = 0,
    marksDepth' = 0,
    handlersDepth' = 0,
    rawConsumed' = true,
    afterSawCorruptedState' = true,
    hasBarrier' = hasBarrier,
    hasDynwind' = hasDynwind,
    zombiePromptAfterLand' = zombiePromptAfterLand,
    barrierBypassed' = barrierBypassed,
  }

  action step = any {
    enterInnerScope(false, false),
    enterInnerScope(true, false),
    enterInnerScope(false, true),
    enterInnerScope(true, true),
    invokeRawFast,
    invokeRawStartUnwind,
    afterThunkCompleteAndLand,
    afterThunkThrowCaughtInner,
    // Stutter once terminal
    all {
      (phase == 3 or phase == 4),
      phase' = phase,
      mcDepth' = mcDepth,
      marksDepth' = marksDepth,
      handlersDepth' = handlersDepth,
      hasBarrier' = hasBarrier,
      hasDynwind' = hasDynwind,
      rawConsumed' = rawConsumed,
      zombiePromptAfterLand' = zombiePromptAfterLand,
      afterSawCorruptedState' = afterSawCorruptedState,
      barrierBypassed' = barrierBypassed,
    }
  }

  val invNoZombieOnLand: bool =
    ((phase == 3) implies (mcDepth == 0 and marksDepth == 0 and handlersDepth == 0 and not(zombiePromptAfterLand)))
  val invAfterThunkIntact: bool =
    ((phase == 2 or phase == 4) implies (mcDepth == 1 and marksDepth == 1 and handlersDepth == 1 and not(afterSawCorruptedState)))
  val invNoBarrierBypass: bool = not(barrierBypassed)

  val safety: bool = all {
    invNoZombieOnLand,
    invAfterThunkIntact,
    invNoBarrierBypass,
  }

  run fastRestoreNoZombieTest = {
    init
      .then(enterInnerScope(false, false))
      .then(invokeRawFast)
      .expect(safety and phase == 3 and mcDepth == 0 and marksDepth == 0 and handlersDepth == 0)
  }

  run transactionalDynwindCompleteTest = {
    init
      .then(enterInnerScope(true, false))
      .then(invokeRawStartUnwind)
      .then(afterThunkCompleteAndLand)
      .expect(safety and phase == 3 and mcDepth == 0 and marksDepth == 0 and handlersDepth == 0)
  }

  run transactionalDynwindThrowPreservesInnerTest = {
    init
      .then(enterInnerScope(true, false))
      .then(invokeRawStartUnwind)
      .then(afterThunkThrowCaughtInner)
      .expect(safety and phase == 4 and mcDepth == 1 and marksDepth == 1 and handlersDepth == 1)
  }

  run buggyZombieLeakDetectedTest = {
    init
      .then(enterInnerScope(false, false))
      .then(buggyRawSkipRestore)
      .expect(not(invNoZombieOnLand))
  }

  run buggyEagerWipeDetectedTest = {
    init
      .then(enterInnerScope(true, false))
      .then(buggyRawEagerWipeBeforeAfter)
      .expect(not(invAfterThunkIntact))
  }
}
