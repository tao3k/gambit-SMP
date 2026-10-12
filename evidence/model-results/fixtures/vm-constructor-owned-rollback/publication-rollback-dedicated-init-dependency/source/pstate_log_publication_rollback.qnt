module pstate_log_publication_rollback {
  import pstate_constructor_configuration as P from "./pstate_constructor_configuration"
  import vm_activity_log_abort as L from "./vm_activity_log_abort"
  // Fresh exclusive P0; all destructors return. Memory setup's log callee
  // is expanded, not assumed to unwind via cleanup_mem_pstate.
  var phase: int
  var vmOnly: bool
  var innerCleanup: bool
  action initializeFor(threaded: bool, vmOnlyPolicy: bool, cleanupPolicy: bool): bool = {
    nondet failure = Set(0, 1, 2, 4, 5).oneOf()
    nondet borrowed = Set(false, true).oneOf()
    nondet logFailure = Set("array", "mutex", "transitions", "stack", "none").oneOf()
    nondet logging = Set(false, true).oneOf()
    all {
      P::s' = P::initialStateFor(0, borrowed, failure, threaded),
      L::logState' = L::initial("fixed", logging, true, logFailure),
      phase' = 0, vmOnly' = vmOnlyPolicy, innerCleanup' = cleanupPolicy,
    }
  }
  action initialize(vmOnlyPolicy: bool, cleanupPolicy: bool): bool =
    initializeFor(true, vmOnlyPolicy, cleanupPolicy)
  action initFixedConfigured(threaded: bool): bool = initializeFor(threaded, false, true)
  action initFixed = initialize(false, true)
  // Dedicated standalone entry avoids Quint's init/step action alias limit.
  // Exactly initializeFor(true, false, true); constructor entry is unchanged.
  action initStandaloneFixed = {
    nondet failure = Set(0, 1, 2, 4, 5).oneOf()
    nondet borrowed = Set(false, true).oneOf()
    nondet logFailure = Set("array", "mutex", "transitions", "stack", "none").oneOf()
    nondet logging = Set(false, true).oneOf()
    all {
      P::s' = P::initialStateFor(0, borrowed, failure, true),
      L::logState' = L::initial("fixed", logging, true, logFailure),
      phase' = 0, vmOnly' = false, innerCleanup' = true,
    }
  }
  action initVMOnly = all {
    P::s' = P::initialState(0, true, 5),
    L::logState' = L::initial("fixed", true, true, "none"),
    phase' = 0, vmOnly' = true, innerCleanup' = false,
  }
  action initDelayed = all {
    P::s' = P::initialState(0, true, 5),
    L::logState' = L::initial("fixed", true, true, "none"),
    phase' = 0, vmOnly' = false, innerCleanup' = false,
  }
  action vmLog = all {
    phase == 0, Set("array", "mutex").contains(L::logState.phase),
    any { L::array, L::mutex }, P::s' = P::s,
    phase' = phase, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action vmLogReady = all {
    phase == 0, Set("transitions", "success", "rollback").contains(L::logState.phase),
    P::s' = P::s, L::logState' = L::logState,
    phase' = if (L::logState.phase == "rollback") 2 else 1, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  val processorNotStarted = phase == 1 and P::s.phase == 0
  action abortBeforeProcessor = all {
    processorNotStarted, P::s' = P::s,
    L::logState' = { ...L::logState, phase: "rollback" },
    phase' = 2, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  val logResourcesReleased = L::logState.owned == Set()
  action beginPublicationAbort = all {
    phase == 4, P::s.phase == 8,
    P::s' = { ...P::s, phase: 6, failed: true },
    L::logState' = L::logState, phase' = 1,
    vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  val protocolState = (P::s, L::logState, phase, vmOnly, innerCleanup)
  action hold = all {
    P::s' = P::s, L::logState' = L::logState, phase' = phase,
    vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action memoryLog = all {
    phase == 1, P::s.phase == 2,
    Set("transitions", "stack", "start").contains(L::logState.phase),
    any { L::transitions, L::stack, L::start },
    P::s' = P::s, phase' = phase, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action memoryFailure = all {
    phase == 1, P::s.phase == 2, L::logState.phase == "rollback", P::s.failure != 3,
    P::s' = { ...P::s, failure: 3 }, L::logState' = L::logState,
    phase' = phase, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action processorStep = all {
    phase == 1, not(P::terminal),
    P::s.phase != 2 or L::logState.phase == "success" or
      (L::logState.phase == "rollback" and P::s.failure == 3),
    P::step, L::logState' = L::logState, phase' = phase, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action handoff = all {
    phase == 1, P::terminal, P::s' = P::s,
    P::s.phase != 7 or not(innerCleanup) or
      L::logState.owned.intersect(Set(2, 3)) == Set(),
    L::logState' = if (P::s.phase == 7) { ...L::logState, phase: "rollback" } else L::logState,
    phase' = if (P::s.phase == 7) 2 else 4, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action processorLogAbort = all {
    phase == 1, P::s.phase == 7, innerCleanup,
    L::logState.owned.intersect(Set(2, 3)).size() > 0,
    // Successful memory setup transferred P0 log buffers to the inner caller.
    // cleanup_actlog_pstate runs after OS/memory rollback and before error return.
    P::s' = P::s,
    L::logState' = { ...L::logState, owned: L::logState.owned.exclude(Set(2, 3)),
      started: false },
    phase' = phase, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action releaseLogs = all {
    phase == 2, not(vmOnly), L::logState.owned.size() > 0,
    L::releaseOwned, P::s' = P::s, phase' = phase, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action vmOnlyAbort = all {
    phase == 2, vmOnly,
    L::logState' = { ...L::logState, phase: "error", owned: L::logState.owned.exclude(Set(0, 1)) },
    P::s' = { ...P::s, intr: false }, phase' = 3, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action outerDone = all {
    phase == 2, not(vmOnly), L::logState.owned.size() == 0,
    L::errorReturn, P::s' = { ...P::s, intr: false },
    phase' = 3, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  val terminal = Set(3, 4).contains(phase)
  action finished = all {
    terminal, P::s' = P::s, L::logState' = L::logState, phase' = phase, vmOnly' = vmOnly, innerCleanup' = innerCleanup,
  }
  action step = any { vmLog, vmLogReady, memoryLog, memoryFailure,
    processorStep, processorLogAbort, handoff, releaseLogs, vmOnlyAbort, outerDone, finished }
  val returnOwnershipSafe = phase != 2 or
    L::logState.owned.intersect(Set(2, 3)) == Set()
  val failureOwnershipSafe = phase != 3 or
    (L::logState.owned == Set() and not(P::s.intr) and not(P::s.os) and
     not(P::s.mem) and not(P::s.mut) and not(P::s.cv))
  val publicationSafe = phase != 4 or (P::safe and L::initializationSafe)
  val safe = returnOwnershipSafe and failureOwnershipSafe and publicationSafe and L::destroySafe and
    L::cleanupReadSafe and not(P::s.badDestroy) and not(P::s.badOrder)
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set((P::s, L::logState, phase, vmOnly, innerCleanup))).implies(eventually(terminal))
}
