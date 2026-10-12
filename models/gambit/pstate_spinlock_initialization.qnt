module pstate_spinlock_initialization {
  // One remote queue user is an abstract interleaving witness, not a CPU limit.
  type State = { policy: str, backend: str, threaded: bool, initFails: bool,
    phase: str, worker: str, ready: bool, live: bool, active: bool,
    closing: bool, initError: bool, invalidUse: bool, invalidDestroy: bool }
  var s: State
  pure def initial(policy: str, backend: str, threaded: bool, initFails: bool): State = {
    policy: policy, backend: backend, threaded: threaded, initFails: initFails,
    phase: "init", worker: "pending", ready: false, live: false, active: false,
    closing: false, initError: false, invalidUse: false, invalidDestroy: false,
  }
  action initOld = s' = initial("legacy", "posix-mutex", true, true)
  action initLeak = s' = initial("legacy", "posix-mutex", true, false)
  action initEarly = s' = initial("early-destroy", "posix-mutex", true, false)
  action initBlind = s' = initial("blind-destroy", "posix-mutex", true, true)
  action initFixed = {
    nondet backend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet threaded = Set(false, true).oneOf()
    nondet fails = Set(false, true).oneOf()
    s' = initial("fixed", backend, threaded, fails)
  }
  action setup = all {
    s.phase == "init",
    val failed = s.threaded and s.backend == "posix-mutex" and s.initFails
    s' = if (failed) { ...s, phase: if (s.policy == "legacy") "running" else "abort",
      initError: true }
      else { ...s, phase: "running", ready: true,
        live: s.threaded and s.backend != "ticket" },
  }
  action enter = all {
    s.phase == "running", s.worker == "pending", not(s.closing),
    s' = { ...s, worker: "using", active: true, invalidUse: not(s.ready) },
  }
  action access = all {
    s.worker == "using",
    s' = { ...s, worker: "done", active: false,
      invalidUse: s.invalidUse or not(s.ready) },
  }
  action retire = all {
    s.phase == "running",
    s' = { ...s, phase: "retiring", closing: true,
      worker: if (s.worker == "pending") "done" else s.worker },
  }
  action destroy = all {
    s.phase == "retiring",
    not(s.active) or s.policy == "early-destroy",
    s' = { ...s, phase: "done", ready: false,
      live: if (s.policy == "legacy") s.live else false,
      invalidDestroy: s.active },
  }
  action abort = all {
    s.phase == "abort",
    s' = { ...s, phase: "done", worker: "done", closing: true,
      invalidDestroy: s.policy == "blind-destroy" and not(s.live) },
  }
  val terminal = s.phase == "done" and s.worker == "done"
  action finished = all { terminal, s' = s }
  action step = any { setup, enter, access, retire, destroy, abort, finished }
  val initializationSafe = not(s.initError) or s.phase != "running"
  val useSafe = not(s.invalidUse)
  val ownedCleanupSafe = not(terminal) or not(s.live)
  val destroySafe = not(s.invalidDestroy)
  val safe = initializationSafe and useSafe and ownedCleanupSafe and destroySafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
