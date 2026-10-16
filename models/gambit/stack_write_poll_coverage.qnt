module stack_write_poll_coverage {
  import stack_trip_owner_limit as A from "./stack_trip_owner_limit"
  // Refine the SAME owner-limit protocol by withdrawing its poll coverage
  // premise. This is a conditional envelope, not native reachability proof.
  var skipPoll: bool
  var storeObserver: bool
  // Keep the parent's exact initial-state set, but do not share an action
  // across TLC initializer selections (Quint QNT409).
  pure def initial(burst: int): A::State = {
    phase: "switch", sender: "sample", sampled: 0, start: 12,
    limit: 8, trip: 8, fp: 12, target: 12, burst: burst,
    ownerGuard: true, switched: false
  }
  action init = {
    nondet burst = Set(1, 2, 4).oneOf()
    all { A::s' = initial(burst), skipPoll' = false, storeObserver' = false }
  }
  action initUnpolled = {
    nondet burst = Set(1, 2, 4).oneOf()
    all { A::s' = initial(burst), skipPoll' = true, storeObserver' = false }
  }
  action initObservedStores = {
    nondet burst = Set(1, 2, 4).oneOf()
    all { A::s' = initial(burst), skipPoll' = true, storeObserver' = true }
  }
  action hold = all { skipPoll' = skipPoll, storeObserver' = storeObserver }
  action bypassPoll = all {
    skipPoll, A::s.phase == "poll", A::s.target >= 32,
    A::s' = {...A::s, phase: "write"}, hold
  }
  action permittedWrite = all {
    not(storeObserver) or A::s.fp - A::s.burst >= 32,
    A::write, hold
  }
  action denyWrite = all {
    storeObserver, A::s.phase == "write", A::s.fp - A::s.burst < 32,
    A::s' = {...A::s, phase: "denied"}, hold
  }
  action step = any {
    all { A::sample, hold }, all { A::publish, hold },
    all { A::switchSection, hold }, all { A::poll, hold },
    all { A::overflow, hold }, bypassPoll, permittedWrite, denyWrite,
    all { A::s.phase == "denied", A::s' = A::s, hold }
  }
  val safe = A::safe
  // A terminal denial preserves bytes by aborting; it does not complete work.
}
