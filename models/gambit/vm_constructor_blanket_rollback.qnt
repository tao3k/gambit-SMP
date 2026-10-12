module vm_constructor_blanket_rollback {
  import pstate_log_publication_rollback.* from "./pstate_log_publication_rollback"
  import vm_private_memory_constructor as M from "./vm_private_memory_constructor"
  import vm_constructor_root_publication as R from "./vm_constructor_root_publication"
  // Exact imported constructor protocols; global ownership is initially ready.
  // Fresh exclusive VM and returning destructors remain explicit premises.
  var outer: int
  var policy: int
  var count: int
  var globalsLive: bool
  var badCleanup: bool
  pure val policyDomain = Set(3)
  action initConstructor = {
    nondet selectedPolicy = policyDomain.oneOf()
    nondet threaded = Set(false, true).oneOf()
    nondet multi = Set(false, true).oneOf()
    nondet spinBackend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet memoryFailure = Set("none", "spinMisc", "spinAlloc", "scanMutex", "scanCond", "roots",
      "sections-table", "sections-empty", "sections-partial").oneOf()
    all {
      initFixedConfigured(threaded),
      M::vmMemory' = M::initial(if (selectedPolicy == 3) "blanket" else "fixed",
        memoryFailure, threaded, multi, spinBackend),
      R::publication' = R::initial("fixed"),
      outer' = 0, policy' = selectedPolicy,
      count' = if (selectedPolicy == 1) 1 else 0,
      globalsLive' = true, badCleanup' = false,
    }
  }
  action keepOuter = all {
    outer' = outer, policy' = policy, count' = count,
    globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action keepRoots = R::publication' = R::publication
  action logPrefix = all {
    outer == 0, phase == 0, step,
    M::vmMemory' = M::vmMemory, keepRoots, keepOuter,
  }
  action receiveLog = all {
    outer == 0, Set(1, 2).contains(phase), hold,
    M::vmMemory' = M::vmMemory,
    R::publication' = if (phase == 2) { ...R::publication, phase: "abort" } else R::publication,
    outer' = if (phase == 1) 1 else 4,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action memoryConstructor = all {
    outer == 1, not(M::terminal), M::step, hold, keepOuter,
    if (M::vmMemory.phase == "roots")
      (if (M::vmMemory.multi and M::vmMemory.failAt == "roots")
        R::publication' = { ...R::publication, phase: "abort" }
        else R::prepareRoots)
      else keepRoots,
  }
  action receiveMemory = all {
    outer == 1, M::terminal, M::vmMemory' = M::vmMemory,
    if (M::vmMemory.phase == "error") abortBeforeProcessor else hold,
    R::publication' = if (M::vmMemory.phase == "error")
      { ...R::publication, phase: "abort" } else R::publication,
    outer' = if (M::vmMemory.phase == "error") 4 else 2,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action processorConstructor = all {
    outer == 2, phase == 1, step,
    M::vmMemory' = M::vmMemory, keepRoots, keepOuter,
  }
  action receiveProcessor = all {
    outer == 2, Set(2, 4).contains(phase), hold,
    M::vmMemory' = if (phase == 2) { ...M::vmMemory, phase: "rollback" } else M::vmMemory,
    R::publication' = { ...R::publication,
      phase: if (phase == 2) "abort" else "publish", ready: phase == 4 },
    outer' = if (phase == 2) 3 else 8,
    count' = count,
    policy' = policy, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action memoryAbort = all {
    outer == 3, not(M::terminal), M::step, hold, keepRoots, keepOuter,
  }
  action receiveMemoryAbort = all {
    outer == 3, M::vmMemory.phase == "error", hold,
    M::vmMemory' = M::vmMemory, keepRoots, outer' = 4,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action logAbort = all {
    outer == 4, phase == 2, step,
    M::vmMemory' = M::vmMemory, keepRoots, keepOuter,
  }
  action receiveLogAbort = all {
    outer == 4, phase == 3, hold,
    M::vmMemory' = M::vmMemory, keepRoots, outer' = 5,
    policy' = policy, count' = count, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  action cleanupGlobal = all {
    outer == 5, hold, M::vmMemory' = M::vmMemory, R::abort,
    outer' = 7, policy' = policy, count' = 0,
    globalsLive' = (policy == 2 and count == 0),
    badCleanup' = (badCleanup or count > 0),
  }
  action globalWriter = all {
    M::vmMemory.multi, not(constructorTerminal), R::registerGlobal,
    hold, M::vmMemory' = M::vmMemory, keepOuter,
  }
  action rootPublication = all {
    outer == 8, R::publication.phase == "publish", R::publish,
    hold, M::vmMemory' = M::vmMemory, keepOuter,
  }
  action receivePublication = all {
    outer == 8, Set("abort", "running").contains(R::publication.phase), keepRoots,
    if (R::publication.phase == "abort") beginPublicationAbort else hold,
    M::vmMemory' = if (R::publication.phase == "running")
      { ...M::vmMemory, phase: "published", linked: M::vmMemory.multi } else M::vmMemory,
    outer' = if (R::publication.phase == "abort") 2 else 6,
    count' = if (R::publication.phase == "running") 1 else count,
    policy' = policy, globalsLive' = globalsLive, badCleanup' = badCleanup,
  }
  val constructorTerminal = Set(6, 7).contains(outer)
  action constructorFinished = all { constructorTerminal, hold, M::vmMemory' = M::vmMemory, keepRoots, keepOuter }
  action constructorStep = any { logPrefix, receiveLog, memoryConstructor, receiveMemory,
    processorConstructor, receiveProcessor, memoryAbort, receiveMemoryAbort,
    logAbort, receiveLogAbort, cleanupGlobal, globalWriter,
    rootPublication, receivePublication, constructorFinished }
  val p0CleanupSafe = not(badCleanup) and M::pstateCleanupSafe
  val outerOwnershipSafe = outer != 7 or not(globalsLive)
  val failureSafe = outer != 7 or (count == 0 and logResourcesReleased and
    M::vmMemory.owned == Set() and not(M::vmMemory.linked) and
    R::publication.phase == "error" and R::publication.roots == Set() and
    R::publication.count == 0 and not(R::publication.linked))
  val vmPublicationSafe = outer != 6 or (count == 1 and phase == 4 and
    globalsLive and safe and R::publication.phase == "running" and R::safe and
    M::vmMemory.phase == "published" and M::heapResources.subseteq(M::vmMemory.owned) and
    (not(M::vmMemory.threaded) or (M::vmMemory.spinReady and
      Set(M::rMutex, M::rCond).subseteq(M::vmMemory.owned) and
      (M::vmMemory.spinBackend == "ticket" or M::spinResources.subseteq(M::vmMemory.owned)))) and
    (not(M::vmMemory.multi) or (M::vmMemory.linked and M::vmMemory.owned.contains(M::rRoots))))
  val earlyCountSafe = policy != 1 or p0CleanupSafe
  val earlyReturnSafe = policy != 2 or outerOwnershipSafe
  val memoryRollbackSafe = policy != 3 or M::safe
  val composedSafe = safe and M::safe and p0CleanupSafe and outerOwnershipSafe and
    failureSafe and vmPublicationSafe and R::safe
  val constructorSafe = policy != 0 or composedSafe
  val earlyCountProgress = policy == 1
  val earlyReturnProgress = policy == 2
  val blanketProgress = policy == 3
  temporal constructorProgress = always(constructorTerminal or enabled(constructorStep)) and
    weakFair(constructorStep, Set((outer, policy, count, globalsLive, badCleanup,
      protocolState, M::vmMemory, R::publication))).implies(eventually(constructorTerminal))
}
