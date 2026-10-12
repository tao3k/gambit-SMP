module cleanup_quarantine_lifecycle {
  import cleanup_resize_error_contract as C from "./cleanup_resize_error_contract"
  // Compose the checked-cleanup proposal with embedding operations. A retained
  // failed cleanup is a terminal error, not permission to reuse or unload.
  type Host = { policy: int, setupTried: bool, unloadTried: bool,
    cleanupTried: bool, overwritten: bool, unloadedLive: bool,
    retriedWithoutWitness: bool }
  var h: Host
  pure def initial(policy: int): Host = {
    policy: policy, setupTried: false, unloadTried: false,
    cleanupTried: false, overwritten: false, unloadedLive: false,
    retriedWithoutWitness: false,
  }
  action initFixed = all { h' = initial(0), C::initFixed }
  action initSetupUnguarded = all { h' = initial(1), C::initFixed }
  action initUnloadUnguarded = all { h' = initial(2), C::initFixed }
  action initCleanupUnguarded = all { h' = initial(3), C::initFixed }
  action cleanupStep = all {
    any { C::publishCleanup, C::reducePopulation, C::joinFails,
      C::joinSucceeds, C::reclaim, C::quarantine }, h' = h,
  }
  action attemptSetup = all {
    C::s.phase > 0, not(h.setupTried),
    h' = { ...h, setupTried: true,
      overwritten: h.policy == 1 and not(C::s.freed) }, C::s' = C::s,
  }
  action attemptUnload = all {
    C::s.phase > 0, not(h.unloadTried),
    h' = { ...h, unloadTried: true,
      unloadedLive: h.policy == 2 and not(C::s.freed) }, C::s' = C::s,
  }
  action attemptCleanup = all {
    C::s.phase == 4, not(h.cleanupTried),
    h' = { ...h, cleanupTried: true,
      retriedWithoutWitness: h.policy == 3 and not(C::s.freed) },
    C::s' = C::s,
  }
  action finished = all {
    C::s.phase == 4, h.setupTried, h.unloadTried, h.cleanupTried,
    h' = h, C::s' = C::s,
  }
  action step = any { cleanupStep, attemptSetup, attemptUnload,
    attemptCleanup, finished }
  val setupSafe = not(h.overwritten)
  val unloadSafe = not(h.unloadedLive)
  val retrySafe = not(h.retriedWithoutWitness)
  val safe = C::safe and setupSafe and unloadSafe and retrySafe
  temporal completion = weakFair(step, Set((h, C::s))).implies(
    eventually(C::s.phase == 4 and h.setupTried and h.unloadTried and h.cleanupTried))
}
