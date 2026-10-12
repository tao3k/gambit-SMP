module vm_spinlock_initialization {
  // misc_mem_lock and alloc_mem_lock; backend selection is not a CPU limit.
  type State = { policy: str, backend: str, threaded: bool, failAt: int,
    phase: str, ready: Set[int], live: Set[int], invalidDestroy: bool }
  var s: State
  pure def initial(policy: str, backend: str, threaded: bool, failAt: int): State = {
    policy: policy, backend: backend, threaded: threaded, failAt: failAt,
    phase: "misc", ready: Set(), live: Set(), invalidDestroy: false,
  }
  action initOld = s' = initial("legacy", "posix-mutex", true, 0)
  action initSecond = s' = initial("legacy", "posix-mutex", true, 1)
  action initBlind = s' = initial("blind", "posix-mutex", true, 1)
  action initFixed = {
    nondet backend = Set("ticket", "posix-mutex", "void-mutex").oneOf()
    nondet threaded = Set(false, true).oneOf()
    nondet failAt = Set(0, 1, 2).oneOf()
    s' = initial("fixed", backend, threaded, failAt)
  }
  action setupMisc = all {
    s.phase == "misc",
    s' = if (not(s.threaded)) { ...s, phase: "success" }
      else if (s.backend == "posix-mutex" and s.failAt == 0)
        { ...s, phase: if (s.policy == "legacy") "alloc" else "rollback" }
      else { ...s, phase: "alloc", ready: Set(0),
        live: if (s.backend == "ticket") Set() else Set(0) },
  }
  action setupAlloc = all {
    s.phase == "alloc",
    s' = if (s.backend == "posix-mutex" and s.failAt == 1)
        { ...s, phase: if (s.policy == "legacy") "success" else "rollback" }
      else { ...s, phase: "success", ready: s.ready.union(Set(1)),
        live: if (s.backend == "ticket") s.live else s.live.union(Set(1)) },
  }
  action blindDestroy = all {
    s.phase == "rollback", s.policy == "blind",
    s' = { ...s, phase: "error", live: Set(),
      invalidDestroy: not(Set(0, 1).subseteq(s.live)) },
  }
  action releaseOwned = all {
    s.phase == "rollback", s.policy == "fixed", s.live.size() > 0,
    val lock = if (s.live.contains(1)) 1 else 0
    s' = { ...s, live: s.live.exclude(Set(lock)),
      invalidDestroy: s.invalidDestroy or not(s.live.contains(lock)) },
  }
  action errorReturn = all {
    s.phase == "rollback", s.policy == "fixed", s.live.size() == 0,
    s' = { ...s, phase: "error" },
  }
  val terminal = Set("success", "error").contains(s.phase)
  action finished = all { terminal, s' = s }
  action step = any { setupMisc, setupAlloc, blindDestroy, releaseOwned, errorReturn, finished }
  val initializationSafe = s.phase != "success" or not(s.threaded) or
    (s.ready == Set(0, 1) and (s.backend == "ticket" or s.live == Set(0, 1)))
  val failureSafe = s.phase != "error" or s.live.size() == 0
  val destroySafe = not(s.invalidDestroy)
  val safe = initializationSafe and failureSafe and destroySafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
