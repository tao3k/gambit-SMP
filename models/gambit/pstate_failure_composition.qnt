module pstate_failure_composition {
  import pstate_setup_transaction.* from "./pstate_setup_transaction"
  // Refines the existing VM handoff's assumed pstate self-unwind using the
  // actual five-stage setup model. Early VM0 interrupt mutex is borrowed.
  // Outer OS/mem is already owned; successful destructors and quiescence
  // remain premises. Live-slot reuse and native ABI are not modeled here.
  type Outer = { policy: int, failAt: int, phase: int, count: int,
    logLive: bool, vmLive: bool, globalsLive: bool, badCleanup: bool }
  var o: Outer
  pure def outerInitial(policy: int, failAt: int): Outer = {
    policy: policy, failAt: failAt, phase: 0, count: 1,
    logLive: false, vmLive: false, globalsLive: true, badCleanup: false,
  }
  action initComposed = {
    nondet failure = Set(0, 1, 2, 3, 4, 5).oneOf()
    nondet outerFailure = Set(0, 1, 2).oneOf()
    all { s' = initialState(0, true, failure), o' = outerInitial(0, outerFailure) }
  }
  action initLegacy = all { s' = initialState(0, true, 5), o' = outerInitial(1, 0) }
  action initVMOnly = all { s' = initialState(0, true, 5), o' = outerInitial(2, 0) }
  action initEarlyReturn = all { s' = initialState(0, true, 0), o' = outerInitial(1, 2) }
  action setupLog = all {
    o.phase == 0, s' = s,
    o' = { ...o, phase: if (o.failAt == 1) 4 else 1, logLive: o.failAt != 1 },
  }
  action setupVM = all {
    o.phase == 1, s' = s,
    o' = { ...o, phase: if (o.failAt == 2) 4 else 2,
      vmLive: o.failAt != 2, count: if (o.failAt == 2) 0 else o.count },
  }
  action runPstate = all { o.phase == 2, not(terminal), step, o' = o }
  action receivePstate = all {
    o.phase == 2, terminal, s' = s,
    o' = { ...o, phase: if (s.phase == 8) 3 else 4 },
  }
  action constructorUnwind = all {
    o.phase == 4, o.policy != 1, s' = s,
    o' = { ...o, phase: 5, count: 0, vmLive: false, logLive: false },
  }
  action legacyReturn = all { o.phase == 4, o.policy == 1, s' = s, o' = { ...o, phase: 5 } }
  action cleanupOuter = all {
    o.phase == 5,
    s' = if (o.policy == 0) { ...s, intr: false } else s,
    o' = if (o.count == 0 and o.policy != 0) { ...o, phase: 6 }
      else { ...o, phase: 6, count: 0, globalsLive: false,
        vmLive: false, logLive: false, badCleanup: s.phase != 8 and o.count > 0 },
  }
  val composedTerminal = Set(3, 6).contains(o.phase)
  action composedFinished = all { composedTerminal, s' = s, o' = o }
  action composedStep = any { setupLog, setupVM, runPstate, receivePstate,
    constructorUnwind, legacyReturn, cleanupOuter, composedFinished }
  val processorCleanupSafe = not(o.badCleanup)
  val outerCleanupSafe = o.phase != 6 or
    (not(o.globalsLive) and not(o.vmLive) and not(o.logLive) and
     not(s.intr) and not(s.os) and not(s.mem) and not(s.mut) and not(s.cv))
  val successfulPublicationSafe = o.phase != 3 or
    (o.count == 1 and o.globalsLive and o.vmLive and o.logLive and s.phase == 8 and safe)
  val composedSafe = processorCleanupSafe and outerCleanupSafe and
    successfulPublicationSafe and (o.phase != 2 or safe)
  temporal composedProgress = weakFair(composedStep, Set((s, o)))
    .implies(eventually(composedTerminal))
}
