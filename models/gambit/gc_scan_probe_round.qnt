module gc_scan_probe_round {
  import gc_recheck_visibility as W from "./gc_recheck_visibility"
  // Finite arithmetic/handshake composition, not a machine CPU configuration.
  type Round = { population: int, owner: int, remaining: int,
    visited: Set[int], legacy: bool }
  var round: Round
  action init = {
    nondet population = 1.to(16).oneOf()
    nondet owner = 0.to(population - 1).oneOf()
    nondet handoff = Set(false, true).oneOf()
    all {
      W::s' = if (handoff) { ...W::initial, producer: "active",
        queued: true, notified: true, acquiredPublication: true } else W::initial,
      round' = { population: population, owner: owner,
        remaining: population, visited: Set(), legacy: false }
    }
  }
  action initLegacySingleRound = {
    nondet population = 2.to(16).oneOf()
    nondet owner = 0.to(population - 1).oneOf()
    nondet handoff = Set(false, true).oneOf()
    all {
      W::s' = if (handoff) { ...W::initial, producer: "active",
        queued: true, notified: true, acquiredPublication: true } else W::initial,
      round' = { population: population, owner: owner,
        remaining: population - 1, visited: Set(), legacy: true }
    }
  }
  action probe = {
    val i = round.remaining - 1
    val victim = if (round.legacy)
      (i + i % (round.population - 1) + 1) % round.population
      else (round.owner + i) % round.population
    all {
      round.remaining > 0,
      round' = { ...round, remaining: i, visited: round.visited.union(Set(victim)) },
      W::s' = W::s
    }
  }
  action handoff = all {
    round.remaining == 0, round' = round,
    any { W::publish, predicate, W::registerWait, W::acquireSignal,
      W::notify, W::releaseSignal, W::resume,
      all { W::s.waiter == "active", W::s.producer == "active", W::s' = W::s } }
  }
  action predicate = {
    nondet seen = Set(false, true).oneOf()
    W::recheck(seen)
  }
  action step = any { probe, handoff }
  val coverage = (round.remaining == 0).implies(
    round.visited == 0.to(round.population - 1))
  val registrationProtected = not(W::s.waiter == "waiting" and
    W::s.producer == "active" and W::s.queued and W::s.notified)
  val safe = coverage and W::safe and registrationProtected
  // Visibility and notification assumptions remain those of W; probe coverage
  // does not prove payload lifetime or attribute the native TFIB timeout.
}
