module gc_source_wait_induction {
  import gc_recursive_queue_induction.* from "./gc_recursive_queue_induction"
  import gc_recursive_wait_recheck.* from "./gc_recursive_wait_recheck"
  // Reuse the exact candidate domain and safety predicates, not old verdicts.
  // The matrix checks the new actions without adding guards to them.
}
