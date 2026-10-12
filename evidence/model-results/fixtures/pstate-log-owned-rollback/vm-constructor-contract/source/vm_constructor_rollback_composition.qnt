module vm_constructor_rollback_composition {
  import pstate_log_rollback_composition.* from "./pstate_log_rollback_composition"
  import vm_mem_setup_transaction as M from "./vm_mem_setup_transaction"
  // Exact imported constructor protocols; global ownership is initially ready.
  // Fresh exclusive VM and returning destructors remain explicit premises.
  var outer: int
  var policy: int
  var count: int
  var globalsLive: bool
  var badCleanup: bool
  action initConstructor = {
    nondet selectedPolicy = Set(0, 1, 2, 3).oneOf()
    nondet threaded = Set(false, true).oneOf()
    nondet multi = Set(false, true).oneOf()
    nondet spinBackend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet memoryFailure = Set("none", "spin", "scanMutex", "scanCond", "roots",
      "sections-table", "sections-empty", "sections-partial").oneOf()
    all {
      initFixed,
      M::vmMemory' = M::initial(if (selectedPolicy == 3) "blanket" else "fixed",
        memoryFailure, threaded, multi, spinBackend),
      outer' = 0, policy' = selectedPolicy,
      count' = if (selectedPolicy == 1) 1 else 0,
      globalsLive' = true, badCleanup' = false,
    }
  }
  action keepOuter = all {
    outer' = outer, policy' = policy, count' = count,
    globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action logPrefix = all {
    outer == 0, phase == 0, step,
    M::vmMemory' = M::vmMemory, keepOuter,
  }
  action receiveLog = all {
    outer == 0, Set(1, 2).contains(phase), hold,
    M::vmMemory' = M::vmMemory,
    outer' = if (phase == 1) 1 else 4,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action memoryConstructor = all {
    outer == 1, not(M::terminal), M::step, hold, keepOuter,
  }
  action receiveMemory = all {
    outer == 1, M::terminal, M::vmMemory' = M::vmMemory,
    if (M::vmMemory.phase == "error") abortBeforeProcessor else hold,
    outer' = if (M::vmMemory.phase == "error") 4 else 2,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action processorConstructor = all {
    outer == 2, phase == 1, step,
    M::vmMemory' = M::vmMemory, keepOuter,
  }
  action receiveProcessor = all {
    outer == 2, Set(2, 4).contains(phase), hold,
    M::vmMemory' = if (phase == 2) { ...M::vmMemory, phase: "rollback" } else M::vmMemory,
    outer' = if (phase == 2) 3 else 6,
    count' = if (phase == 4) 1 else count,
    policy' = policy, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action memoryAbort = all {
    outer == 3, not(M::terminal), M::step, hold, keepOuter,
  }
  action receiveMemoryAbort = all {
    outer == 3, M::vmMemory.phase == "error", hold,
    M::vmMemory' = M::vmMemory, outer' = 4,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action logAbort = all {
    outer == 4, phase == 2, step,
    M::vmMemory' = M::vmMemory, keepOuter,
  }
  action receiveLogAbort = all {
    outer == 4, phase == 3, hold,
    M::vmMemory' = M::vmMemory, outer' = 5,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action cleanupGlobal = all {
    outer == 5, hold, M::vmMemory' = M::vmMemory,
    outer' = 7, policy' = policy, count' = 0,
    globalsLive' = (policy == 2 and count == 0),
    badCleanup' = (badCleanup or count > 0),
  }
  val constructorTerminal = Set(6, 7).contains(outer)
  action constructorFinished = all { constructorTerminal, hold, M::vmMemory' = M::vmMemory, keepOuter }
  action constructorStep = any { logPrefix, receiveLog, memoryConstructor, receiveMemory,
    processorConstructor, receiveProcessor, memoryAbort, receiveMemoryAbort,
    logAbort, receiveLogAbort, cleanupGlobal, constructorFinished }
  val p0CleanupSafe = not(badCleanup) and M::pstateCleanupSafe
  val outerOwnershipSafe = outer != 7 or not(globalsLive)
  val failureSafe = outer != 7 or (count == 0 and logResourcesReleased and
    M::vmMemory.owned == Set() and not(M::vmMemory.linked))
  val vmPublicationSafe = outer != 6 or (count == 1 and phase == 4 and
    globalsLive and safe and M::initializationSafe)
  val earlyCountSafe = policy != 1 or p0CleanupSafe
  val earlyReturnSafe = policy != 2 or outerOwnershipSafe
  val memoryRollbackSafe = policy != 3 or M::safe
  val composedSafe = safe and M::safe and p0CleanupSafe and outerOwnershipSafe and
    failureSafe and vmPublicationSafe
  val constructorSafe = policy != 0 or composedSafe
  temporal constructorProgress = always(constructorTerminal or enabled(constructorStep)) and
    weakFair(constructorStep, Set((outer, policy, count, globalsLive, badCleanup,
      protocolState, M::vmMemory))).implies(eventually(constructorTerminal))
}
