module vm_constructor_rollback_composition {
  import pstate_log_rollback_composition as C from "./pstate_log_rollback_composition"
  import vm_mem_setup_transaction as M from "./vm_mem_setup_transaction"
  // Exact imported constructor protocols; global ownership is initially ready.
  // Fresh exclusive VM and returning destructors remain explicit premises.
  var outer: int
  var policy: int
  var count: int
  var globalsLive: bool
  var badCleanup: bool
  action initConstructor = {
    nondet failure = Set(0, 2, 4, 5).oneOf()
    nondet logFailure = Set("array", "mutex", "transitions", "stack", "none").oneOf()
    nondet logging = Set(false, true).oneOf()
    nondet threaded = Set(false, true).oneOf()
    nondet multi = Set(false, true).oneOf()
    nondet spinBackend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet memoryFailure = Set("none", "spin", "scanMutex", "scanCond", "roots",
      "sections-table", "sections-empty", "sections-partial").oneOf()
    all {
      C::P::s' = C::P::initialState(0, true, failure),
      C::L::logState' = C::L::initial("fixed", logging, true, logFailure),
      C::phase' = 0, C::vmOnly' = false, C::innerCleanup' = true,
      M::vmMemory' = M::initial("fixed", memoryFailure, threaded, multi, spinBackend),
      outer' = 0, policy' = 0, count' = 0, globalsLive' = true, badCleanup' = false,
    }
  }
  action initEarlyCount = all {
    C::P::s' = C::P::initialState(0, true, 5),
    C::L::logState' = C::L::initial("fixed", true, true, "none"),
    C::phase' = 0, C::vmOnly' = false, C::innerCleanup' = true,
    M::vmMemory' = M::initial("fixed", "none", true, true, "ticket"),
    outer' = 0, policy' = 1, count' = 1, globalsLive' = true, badCleanup' = false,
  }
  action initEarlyReturn = all {
    C::P::s' = C::P::initialState(0, true, 5),
    C::L::logState' = C::L::initial("fixed", true, true, "none"),
    C::phase' = 0, C::vmOnly' = false, C::innerCleanup' = true,
    M::vmMemory' = M::initial("fixed", "none", true, true, "ticket"),
    outer' = 0, policy' = 2, count' = 0, globalsLive' = true, badCleanup' = false,
  }
  action initBlanket = all {
    C::P::s' = C::P::initialState(0, true, 0),
    C::L::logState' = C::L::initial("fixed", true, true, "none"),
    C::phase' = 0, C::vmOnly' = false, C::innerCleanup' = true,
    M::vmMemory' = M::initial("blanket", "sections-partial", true, true, "ticket"),
    outer' = 0, policy' = 0, count' = 0, globalsLive' = true, badCleanup' = false,
  }
  action keepOuter = all {
    outer' = outer, policy' = policy, count' = count,
    globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action logPrefix = all {
    outer == 0, C::phase == 0, C::step,
    M::vmMemory' = M::vmMemory, keepOuter,
  }
  action receiveLog = all {
    outer == 0, Set(1, 2).contains(C::phase), C::hold,
    M::vmMemory' = M::vmMemory,
    outer' = if (C::phase == 1) 1 else 4,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action memoryConstructor = all {
    outer == 1, not(M::terminal), M::step, C::hold, keepOuter,
  }
  action receiveMemory = all {
    outer == 1, M::terminal, M::vmMemory' = M::vmMemory,
    if (M::vmMemory.phase == "error") C::abortBeforeProcessor else C::hold,
    outer' = if (M::vmMemory.phase == "error") 4 else 2,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action processorConstructor = all {
    outer == 2, C::phase == 1, C::step,
    M::vmMemory' = M::vmMemory, keepOuter,
  }
  action receiveProcessor = all {
    outer == 2, Set(2, 4).contains(C::phase), C::hold,
    M::vmMemory' = if (C::phase == 2) { ...M::vmMemory, phase: "rollback" } else M::vmMemory,
    outer' = if (C::phase == 2) 3 else 6,
    count' = if (C::phase == 4) 1 else count,
    policy' = policy, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action memoryAbort = all {
    outer == 3, not(M::terminal), M::step, C::hold, keepOuter,
  }
  action receiveMemoryAbort = all {
    outer == 3, M::vmMemory.phase == "error", C::hold,
    M::vmMemory' = M::vmMemory, outer' = 4,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action logAbort = all {
    outer == 4, C::phase == 2, C::step,
    M::vmMemory' = M::vmMemory, keepOuter,
  }
  action receiveLogAbort = all {
    outer == 4, C::phase == 3, C::hold,
    M::vmMemory' = M::vmMemory, outer' = 5,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action cleanupGlobal = all {
    outer == 5, C::hold, M::vmMemory' = M::vmMemory,
    outer' = 7, policy' = policy, count' = 0,
    globalsLive' = (policy == 2 and count == 0),
    badCleanup' = (badCleanup or count > 0),
  }
  val terminal = Set(6, 7).contains(outer)
  action finished = all { terminal, C::hold, M::vmMemory' = M::vmMemory, keepOuter }
  action step = any { logPrefix, receiveLog, memoryConstructor, receiveMemory,
    processorConstructor, receiveProcessor, memoryAbort, receiveMemoryAbort,
    logAbort, receiveLogAbort, cleanupGlobal, finished }
  val p0CleanupSafe = not(badCleanup) and M::pstateCleanupSafe
  val outerOwnershipSafe = outer != 7 or not(globalsLive)
  val failureSafe = outer != 7 or (count == 0 and C::logResourcesReleased and
    M::vmMemory.owned == Set() and not(M::vmMemory.linked))
  val publicationSafe = outer != 6 or (count == 1 and C::phase == 4 and
    globalsLive and C::safe and M::initializationSafe)
  val safe = C::safe and M::safe and p0CleanupSafe and outerOwnershipSafe and
    failureSafe and publicationSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set((outer, policy, count, globalsLive, badCleanup,
      C::protocolState, M::vmMemory))).implies(eventually(terminal))
}
