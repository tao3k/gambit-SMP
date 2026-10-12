module vm_activity_log_abort {
  // Resource identities: VM activities, VM mutex, P0 transitions, P0 stack.
  type State = { policy: str, enabled: bool, posix: bool, failAt: str,
    phase: str, owned: Set[int], started: bool, badRead: bool, badDestroy: bool }
  var logState: State
  pure def initial(policy: str, logEnabled: bool, posix: bool, failAt: str): State = {
    policy: policy, enabled: logEnabled, posix: posix, failAt: failAt,
    phase: "array", owned: Set(), started: false, badRead: false, badDestroy: false,
  }
  action initOld = logState' = initial("normal-cleanup", true, true, "transitions")
  action initLeak = logState' = initial("normal-cleanup", true, true, "after-p0")
  action initIgnoredMutex = logState' = initial("normal-cleanup", true, true, "mutex")
  action initDouble = logState' = initial("double", true, true, "stack")
  action initFixed = {
    nondet logEnabled = Set(false, true).oneOf()
    nondet posix = Set(false, true).oneOf()
    nondet failAt = Set("array", "mutex", "transitions", "stack", "after-p0", "none").oneOf()
    logState' = initial("fixed", logEnabled, posix, failAt)
  }
  action array = all {
    logState.phase == "array",
    logState' = if (not(logState.enabled)) { ...logState,
        phase: if (logState.failAt == "after-p0") "rollback" else "success" }
      else if (logState.failAt == "array") { ...logState, phase: "rollback" }
      else { ...logState, phase: "mutex", owned: Set(0) },
  }
  action mutex = all {
    logState.phase == "mutex",
    logState' = if (logState.posix and logState.failAt == "mutex") { ...logState,
        phase: if (logState.policy == "normal-cleanup") "transitions" else "rollback" }
      else { ...logState, phase: "transitions", owned: logState.owned.union(Set(1)) },
  }
  action transitions = all {
    logState.phase == "transitions",
    logState' = if (logState.failAt == "transitions") { ...logState, phase: "rollback" }
      else { ...logState, phase: "stack", owned: logState.owned.union(Set(2)) },
  }
  action stack = all {
    logState.phase == "stack",
    // Actual helper frees the temporary transitions if stack allocation fails.
    logState' = if (logState.failAt == "stack") { ...logState, phase: "rollback", owned: logState.owned.exclude(Set(2)) }
      else { ...logState, phase: "start", owned: logState.owned.union(Set(3)) },
  }
  action start = all {
    logState.phase == "start",
    logState' = { ...logState, started: true,
      phase: if (logState.failAt == "after-p0") "rollback" else "success" },
  }
  action normalCleanup = all {
    logState.phase == "rollback", logState.policy == "normal-cleanup",
    // Normal VM cleanup dumps P0 but does not release its log buffers.
    logState' = { ...logState, phase: "error", owned: logState.owned.exclude(Set(0, 1)),
      badRead: logState.enabled and not(logState.started) },
  }
  action doubleCleanup = all {
    logState.phase == "rollback", logState.policy == "double",
    logState' = { ...logState, phase: "error", owned: Set(),
      badDestroy: not(logState.owned.contains(2)) },
  }
  action releaseOwned = all {
    logState.phase == "rollback", logState.policy == "fixed", logState.owned.size() > 0,
    // Abort never dumps P0; release initialized PS ownership before VM ownership.
    val resource = if (logState.owned.contains(3)) 3 else if (logState.owned.contains(2)) 2
      else if (logState.owned.contains(1)) 1 else 0
    logState' = { ...logState, owned: logState.owned.exclude(Set(resource)),
      badDestroy: logState.badDestroy or not(logState.owned.contains(resource)) },
  }
  action errorReturn = all {
    logState.phase == "rollback", logState.policy == "fixed", logState.owned.size() == 0,
    logState' = { ...logState, phase: "error", started: false },
  }
  val terminal = Set("success", "error").contains(logState.phase)
  action finished = all { terminal, logState' = logState }
  action step = any { array, mutex, transitions, stack, start,
    normalCleanup, doubleCleanup, releaseOwned, errorReturn, finished }
  val cleanupReadSafe = not(logState.badRead)
  val failureSafe = logState.phase != "error" or logState.owned.size() == 0
  val initializationSafe = logState.phase != "success" or not(logState.enabled) or
    (logState.owned == Set(0, 1, 2, 3) and logState.started)
  val destroySafe = not(logState.badDestroy)
  val safe = cleanupReadSafe and failureSafe and initializationSafe and destroySafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(logState)).implies(eventually(terminal))
}
