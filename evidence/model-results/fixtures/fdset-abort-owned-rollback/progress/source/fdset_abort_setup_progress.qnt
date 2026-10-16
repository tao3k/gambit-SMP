module fdset_abort_setup_progress {
  import fdset_abort_setup_ownership as O from "./fdset_abort_setup_ownership"
  action init=O::init
  action initOldCleanup=O::initOldCleanup
  action step=O::step
  val safe=O::safe
  val cleanupComplete=O::cleanupComplete
  // Modeled allocator/OS calls return. Fair execution eventually takes the
  // remaining finite setup/rollback/cleanup steps, not an OS hang guarantee.
  temporal completion=weakFair(step,O::s).implies(eventually(O::terminal))
}
