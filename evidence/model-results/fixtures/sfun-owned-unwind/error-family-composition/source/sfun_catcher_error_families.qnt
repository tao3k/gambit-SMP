module sfun_catcher_error_families {
  import sfun_catcher_cleanup as W from "./sfun_catcher_cleanup"

  // Reuse the qualified transition relation; extend handler-error coverage
  // to all wrapper families, as observed with the configured-header unit.
  action initFixed = {
    nondet kind = Set(0, 1, 2).oneOf()
    nondet fault = Set(0, 1, 2, 3).oneOf()
    W::s' = W::initial(0, kind, fault)
  }
  action initTailOnly = W::initTailOnly
  action initCatcherLeak = W::initCatcherLeak
  action initDoubleKill = W::initDoubleKill
  action initUnallocatedKill = W::initUnallocatedKill
  action initErrorErase = W::initErrorErase
  action step = W::step
  val cleanupBeforePropagation = W::cleanupBeforePropagation
  val catcherRestored = W::catcherRestored
  val exactlyOnce = W::exactlyOnce
  val allocationSafe = W::allocationSafe
  val honestError = W::honestError
  val safe = W::safe
  temporal completion = W::completion
}
