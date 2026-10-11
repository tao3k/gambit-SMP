module setup_outer_ownership {
  // Global ___setup prefix: VM list lock -> early VM0 interrupt lock -> OS/mem.
  // Both locks are GLOBAL-owned here; VM0 pstate later only borrows its lock.
  // Failing OS/mem helper is assumed to unwind its own partial resources.
  type State = { unwind: bool, multipleVMs: bool, failAt: str,
    phase: str, listLive: bool, interruptLive: bool,
    failed: bool, cleanupEnabled: bool }
  var s: State
  pure def initial(unwind: bool, multipleVMs: bool, failAt: str): State = {
    unwind: unwind, multipleVMs: multipleVMs, failAt: failAt,
    phase: "list", listLive: false, interruptLive: false,
    failed: false, cleanupEnabled: false,
  }
  action initInterruptFailure = s' = initial(false, true, "interrupt")
  action initOSFailure = s' = initial(false, true, "os-mem")
  action initFixed = {
    nondet multipleVMs = Set(false, true).oneOf()
    nondet failAt = Set("none", "interrupt", "os-mem").oneOf()
    s' = initial(true, multipleVMs, failAt)
  }
  action setupList = all {
    s.phase == "list", s' = { ...s, phase: "interrupt", listLive: s.multipleVMs },
  }
  action setupInterrupt = all {
    s.phase == "interrupt",
    s' = { ...s, phase: if (s.failAt == "interrupt") "failure" else "os-mem",
      failed: s.failAt == "interrupt", interruptLive: s.failAt != "interrupt" },
  }
  action setupOSMem = all {
    s.phase == "os-mem",
    s' = { ...s, phase: if (s.failAt == "os-mem") "failure" else "success",
      failed: s.failAt == "os-mem", cleanupEnabled: s.failAt != "os-mem" },
  }
  // Public ___cleanup is disabled for this prefix. No implicit cleanup action.
  action unwindInterrupt = all {
    s.phase == "failure", s.unwind, s.interruptLive,
    s' = { ...s, interruptLive: false },
  }
  action unwindList = all {
    s.phase == "failure", s.unwind, not(s.interruptLive), s.listLive,
    s' = { ...s, listLive: false },
  }
  action returnError = all {
    s.phase == "failure",
    not(s.unwind) or (not(s.listLive) and not(s.interruptLive)),
    s' = { ...s, phase: "returned" },
  }
  val terminal = Set("returned", "success").contains(s.phase)
  action finished = all { terminal, s' = s }
  action step = any { setupList, setupInterrupt, setupOSMem,
    unwindInterrupt, unwindList, returnError, finished }
  val globalOwnershipSafe = s.phase != "returned" or
    (not(s.listLive) and not(s.interruptLive))
  val successOwnsResources = s.phase != "success" or
    (s.interruptLive and s.listLive == s.multipleVMs)
  val safe = globalOwnershipSafe and successOwnsResources
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
