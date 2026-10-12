module pstate_log_rollback_composition {
  import pstate_setup_transaction as P from "./pstate_setup_transaction"
  import vm_activity_log_abort as L from "./vm_activity_log_abort"
  // Fresh exclusive P0; all destructors return. Memory setup's log callee
  // is expanded, not assumed to unwind via cleanup_mem_pstate.
  var phase: int
  var vmOnly: bool
  action initialize(vmOnlyPolicy: bool): bool = {
    nondet failure = Set(0, 2, 4, 5).oneOf()
    nondet logFailure = Set("array", "mutex", "transitions", "stack", "none").oneOf()
    nondet logging = Set(false, true).oneOf()
    all {
      P::s' = P::initialState(0, true, failure),
      L::logState' = L::initial("fixed", logging, true, logFailure),
      phase' = 0, vmOnly' = vmOnlyPolicy,
    }
  }
  action initFixed = initialize(false)
  action initVMOnly = all {
    P::s' = P::initialState(0, true, 5),
    L::logState' = L::initial("fixed", true, true, "none"),
    phase' = 0, vmOnly' = true,
  }
  action vmLog = all {
    phase == 0, Set("array", "mutex").contains(L::logState.phase),
    any { L::array, L::mutex }, P::s' = P::s,
    phase' = phase, vmOnly' = vmOnly,
  }
  action vmLogReady = all {
    phase == 0, Set("transitions", "success", "rollback").contains(L::logState.phase),
    P::s' = P::s, L::logState' = L::logState,
    phase' = if (L::logState.phase == "rollback") 2 else 1, vmOnly' = vmOnly,
  }
  action memoryLog = all {
    phase == 1, P::s.phase == 2,
    Set("transitions", "stack", "start").contains(L::logState.phase),
    any { L::transitions, L::stack, L::start },
    P::s' = P::s, phase' = phase, vmOnly' = vmOnly,
  }
  action memoryFailure = all {
    phase == 1, P::s.phase == 2, L::logState.phase == "rollback", P::s.failure != 3,
    P::s' = { ...P::s, failure: 3 }, L::logState' = L::logState,
    phase' = phase, vmOnly' = vmOnly,
  }
  action processorStep = all {
    phase == 1, not(P::terminal),
    P::s.phase != 2 or L::logState.phase == "success" or
      (L::logState.phase == "rollback" and P::s.failure == 3),
    P::step, L::logState' = L::logState, phase' = phase, vmOnly' = vmOnly,
  }
  action handoff = all {
    phase == 1, P::terminal, P::s' = P::s,
    L::logState' = if (P::s.phase == 7) { ...L::logState, phase: "rollback" } else L::logState,
    phase' = if (P::s.phase == 7) 2 else 4, vmOnly' = vmOnly,
  }
  action releaseLogs = all {
    phase == 2, not(vmOnly), L::logState.owned.size() > 0,
    L::releaseOwned, P::s' = P::s, phase' = phase, vmOnly' = vmOnly,
  }
  action vmOnlyAbort = all {
    phase == 2, vmOnly,
    L::logState' = { ...L::logState, phase: "error", owned: L::logState.owned.exclude(Set(0, 1)) },
    P::s' = { ...P::s, intr: false }, phase' = 3, vmOnly' = vmOnly,
  }
  action outerDone = all {
    phase == 2, not(vmOnly), L::logState.owned.size() == 0,
    L::errorReturn, P::s' = { ...P::s, intr: false },
    phase' = 3, vmOnly' = vmOnly,
  }
  val terminal = Set(3, 4).contains(phase)
  action finished = all {
    terminal, P::s' = P::s, L::logState' = L::logState, phase' = phase, vmOnly' = vmOnly,
  }
  action step = any { vmLog, vmLogReady, memoryLog, memoryFailure,
    processorStep, handoff, releaseLogs, vmOnlyAbort, outerDone, finished }
  val failureOwnershipSafe = phase != 3 or
    (L::logState.owned == Set() and not(P::s.intr) and not(P::s.os) and
     not(P::s.mem) and not(P::s.mut) and not(P::s.cv))
  val publicationSafe = phase != 4 or (P::safe and L::initializationSafe)
  val safe = failureOwnershipSafe and publicationSafe and L::destroySafe and
    L::cleanupReadSafe and not(P::s.badDestroy) and not(P::s.badOrder)
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set((P::s, L::logState, phase, vmOnly))).implies(eventually(terminal))
}
