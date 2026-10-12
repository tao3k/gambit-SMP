module pstate_scan_lock_ownership {
  // Quiescence is a caller obligation, not inferred from an ownership bit.
  type State = { policy: str, backend: str, threaded: bool, failLog: bool,
    failLock: bool, phase: str, owned: bool, live: bool, log: bool,
    closing: bool, users: int, cleanups: int, generation: int,
    badUse: bool, badDestroy: bool, missedRollback: bool }
  var s: State
  pure def initial(policy: str, backend: str, threaded: bool, failLog: bool, failLock: bool): State = {
    policy: policy, backend: backend, threaded: threaded, failLog: failLog,
    failLock: failLock, phase: "log", owned: false, live: false, log: false,
    closing: true, users: 0, cleanups: 0, generation: 0,
    badUse: false, badDestroy: false, missedRollback: false,
  }
  action initIgnored = s' = initial("ignored", "posix-mutex", true, false, true)
  action initLeak = s' = initial("leak", "posix-mutex", true, false, false)
  action initBlind = s' = initial("blind", "posix-mutex", true, false, true)
  action initDouble = s' = initial("double", "posix-mutex", true, false, false)
  action initEarly = s' = initial("early", "posix-mutex", true, false, false)
  action initLate = s' = initial("late", "posix-mutex", true, false, false)
  action initFixed = {
    nondet backend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet threaded = Set(false, true).oneOf()
    nondet failLog = Set(false, true).oneOf()
    nondet failLock = Set(false, true).oneOf()
    s' = initial("fixed", backend, threaded, failLog, failLock)
  }
  action allocateLog = all {
    s.phase == "log",
    s' = if (s.failLog) { ...s, phase: "failed" }
      else { ...s, phase: "lock", log: true },
  }
  action initializeLock = all {
    s.phase == "lock",
    val failed = s.threaded and s.backend == "posix-mutex" and s.failLock
    s' = if (failed) {
      ...s, phase: if (s.policy == "ignored") "ready" else "failed",
      closing: s.policy != "ignored", log: s.policy == "ignored",
      missedRollback: s.policy == "ignored",
      badDestroy: s.policy == "blind",
    } else { ...s, phase: "ready", closing: false,
      owned: s.threaded, live: s.threaded and s.backend != "ticket" },
  }
  action enter = all {
    Set("ready", "retiring").contains(s.phase), s.users == 0,
    not(s.closing) or s.policy == "late",
    s' = { ...s, users: 1, badUse: s.badUse or s.closing or (s.threaded and not(s.owned)) },
  }
  action leave = all { s.users == 1, s' = { ...s, users: 0 } }
  action closeAdmission = all {
    s.phase == "ready", s' = { ...s, phase: "retiring", closing: true },
  }
  action cleanup = all {
    Set("retiring", "cleaned").contains(s.phase), s.cleanups < 2,
    s.users == 0 or s.policy == "early",
    val attempts = s.threaded and s.policy != "leak" and (s.owned or s.policy == "double")
    s' = { ...s, phase: if (s.cleanups == 1) "done" else "cleaned",
      cleanups: s.cleanups + 1, log: false,
      live: if (attempts) false else s.live,
      owned: if (attempts and s.policy != "double") false else s.owned,
      badDestroy: s.badDestroy or (attempts and (not(s.owned) or s.users != 0 or
        (s.backend != "ticket" and not(s.live)))) },
  }
  action reuse = all {
    s.phase == "done", s.generation == 0, s.users == 0,
    s' = { ...s, phase: "log", generation: 1, cleanups: 0,
      missedRollback: s.missedRollback or s.owned or s.live },
  }
  val terminal = s.phase == "failed" or (s.phase == "done" and s.generation == 1)
  action finished = all { terminal, s' = s }
  action step = any { allocateLog, initializeLock, enter, leave, closeAdmission, cleanup, reuse, finished }
  val rollbackSafe = not(s.missedRollback) and (s.phase != "failed" or not(s.log))
  val destroySafe = not(s.badDestroy)
  val cleanupSafe = not(s.phase == "done") or (not(s.owned) and not(s.live))
  val admissionSafe = not(s.closing and s.phase == "retiring" and s.users > 0 and s.cleanups > 0)
  val useSafe = not(s.badUse)
  val safe = rollbackSafe and destroySafe and cleanupSafe and useSafe and admissionSafe
  temporal progress = always(terminal or enabled(step)) and
    (weakFair(closeAdmission, Set(s)) and weakFair(leave, Set(s)) and
     weakFair(cleanup, Set(s)) and weakFair(reuse, Set(s)) and
     weakFair(allocateLog, Set(s)) and weakFair(initializeLock, Set(s))).implies(eventually(terminal))
}
