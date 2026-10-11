module pstate_vm_failure_handoff {
  // Global OS/mem and early interrupt resources are already owned by ___setup.
  // VM constructor failures must not expose an unready P0 to global cleanup.
  type State = { policy: str, failAt: str, phase: str, count: int,
    psReady: bool, vmReady: bool, logReady: bool, failed: bool,
    globalsLive: bool, interruptLive: bool, badCleanup: bool }
  var s: State
  pure def initial(policy: str, failAt: str): State = {
    policy: policy, failAt: failAt, phase: "start", count: 0,
    psReady: false, vmReady: false, logReady: false, failed: false,
    globalsLive: true, interruptLive: true, badCleanup: false,
  }
  action initOld = s' = initial("legacy", "pstate")
  action initVMOnly = s' = initial("vm-only", "pstate")
  action initEarlyReturn = s' = initial("legacy", "vm")
  action initFixed = {
    nondet failAt = Set("none", "actlog", "vm", "pstate").oneOf()
    s' = initial("fixed", failAt)
  }
  action start = all {
    s.phase == "start", s' = { ...s, phase: "actlog", count: 1 },
  }
  action setupLog = all {
    s.phase == "actlog",
    s' = { ...s, phase: if (s.failAt == "actlog") "failure" else "vm",
      failed: s.failAt == "actlog", logReady: s.failAt != "actlog" },
  }
  action setupVM = all {
    s.phase == "vm",
    s' = { ...s, phase: if (s.failAt == "vm") "failure" else "pstate",
      failed: s.failAt == "vm", vmReady: s.failAt != "vm",
      count: if (s.failAt == "vm") 0 else s.count },
  }
  action setupP0 = all {
    s.phase == "pstate",
    // Failed pstate has self-unwound its owned resources; global interrupt stays.
    s' = { ...s, phase: if (s.failAt == "pstate") "failure" else "success",
      failed: s.failAt == "pstate", psReady: s.failAt != "pstate" },
  }
  action constructorUnwind = all {
    s.phase == "failure", s.policy != "legacy",
    s' = { ...s, phase: "vm-return", count: 0, vmReady: false, logReady: false },
  }
  action legacyReturn = all {
    s.phase == "failure", s.policy == "legacy", s' = { ...s, phase: "vm-return" },
  }
  action globalCleanup = all {
    s.phase == "vm-return",
    s' = if (s.count == 0 and s.policy != "fixed") { ...s, phase: "error-return" }
      else { ...s, phase: "error-return", count: 0,
        badCleanup: s.badCleanup or (s.count > 0 and not(s.psReady)),
        psReady: false, vmReady: false, logReady: false, globalsLive: false,
        interruptLive: if (s.policy == "fixed") false else s.interruptLive },
  }
  val terminal = Set("error-return", "success").contains(s.phase)
  action finished = all { terminal, s' = s }
  action step = any { start, setupLog, setupVM, setupP0,
    constructorUnwind, legacyReturn, globalCleanup, finished }
  val processorCleanupSafe = not(s.badCleanup)
  val outerCleanupSafe = s.phase != "error-return" or
    (not(s.psReady) and not(s.vmReady) and not(s.logReady) and
     not(s.globalsLive) and not(s.interruptLive))
  val completeFailureSafe = processorCleanupSafe and outerCleanupSafe
  val successOwnsResources = s.phase != "success" or
    (s.count == 1 and s.psReady and s.vmReady and s.logReady and s.globalsLive and s.interruptLive)
  val safe = completeFailureSafe and successOwnsResources
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
