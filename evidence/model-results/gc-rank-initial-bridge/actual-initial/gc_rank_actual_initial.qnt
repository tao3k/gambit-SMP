module gc_rank_actual_initial {
  import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"
  import gc_recursive_queue_induction.* from "./gc_recursive_queue_induction"
  import gc_recursive_queue_rank.* from "./gc_recursive_queue_rank"
  // Actual source/combined protocol starts, not arbitrary candidate-domain states.
  action initActual = {
    nondet policy = Set("source", "combined").oneOf()
    all {
      s' = initial(policy, "none"), priorPrimary' = 0,
      priorWorkers' = Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0), advanced' = false,
    }
  }
  val initialRankSafe = candidateInvariant and componentBound and rankStep
}
