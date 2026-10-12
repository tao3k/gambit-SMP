module checked_cleanup_failure_disposition {
  import cleanup_resize_error_contract as C from "./cleanup_resize_error_contract"
  // Host lifecycle calls are serialized. Fail-stop is not successful cleanup.
  type Host = { policy: int, legacy: bool, observed: bool,
    alive: bool, reported: int, attempted: bool, acceptedSetup: bool }
  var h: Host
  action initFixed = {
    nondet legacy = Set(false, true).oneOf()
    all {
      h' = { policy: 0, legacy: legacy, observed: false, alive: true,
        reported: 0, attempted: false, acceptedSetup: false },
      C::s' = { policy: 1, phase: 0, count: 2, join: 0, exited: false,
        setup: 1, freed: false, outcome: 0 },
    }
  }
  action initSilentLegacy = all {
    h' = { policy: 1, legacy: true, observed: false, alive: true,
      reported: 0, attempted: false, acceptedSetup: false },
    C::s' = { policy: 1, phase: 0, count: 2, join: 0, exited: false,
      setup: 1, freed: false, outcome: 0 },
  }
  action initSetupOverwrite = all {
    h' = { policy: 2, legacy: false, observed: false, alive: true,
      reported: 0, attempted: false, acceptedSetup: false },
    C::s' = { policy: 1, phase: 0, count: 2, join: 0, exited: false,
      setup: 1, freed: false, outcome: 0 },
  }
  action cleanupStep = all {
    any { C::publishCleanup, C::reducePopulation, C::joinFails,
      C::joinSucceeds, C::reclaim, C::quarantine }, h' = h,
  }
  action observe = all {
    C::s.phase == 4, not(h.observed), C::s' = C::s,
    h' = { ...h, observed: true,
      alive: not(h.legacy and C::s.outcome == 2 and h.policy != 1),
      reported: if (h.legacy and h.policy == 1) 0 else C::s.outcome },
  }
  action attemptSetup = all {
    h.observed, not(h.attempted), C::s' = C::s,
    h' = { ...h, attempted: true,
      acceptedSetup: h.alive and (C::s.freed or h.policy == 2) },
  }
  val terminal = h.observed and h.attempted
  action finished = all { terminal, h' = h, C::s' = C::s }
  action step = any { cleanupStep, observe, attemptSetup, finished }
  val failureExplicit = not(h.observed) or C::s.outcome != 2 or
    (if (h.legacy) not(h.alive) else h.reported == 2)
  val retainedSetupSafe = not(h.acceptedSetup) or C::s.freed
  val safe = C::safe and failureExplicit and retainedSetupSafe
  temporal completion = weakFair(step, Set((h, C::s))).implies(eventually(terminal))
}
