module checkpoint_budget_ledger {
  // Two competing requests and small cost units are finite abstractions, not
  // native CPU limits. Reservation/settlement need atomic durable refinement.
  val requests = Set(0, 1)
  val limit = 6
  type State = { policy: str, spent: int, phase: int -> str,
                 reserved: int -> int, used: int -> int, charged: int -> int,
                 quiescent: int -> bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, spent: 3,
    phase: Map(0 -> "idle", 1 -> "idle"), reserved: Map(0 -> 0, 1 -> 0),
    used: Map(0 -> 0, 1 -> 0), charged: Map(0 -> 0, 1 -> 0),
    quiescent: Map(0 -> true, 1 -> true),
  }
  action init = s' = initial("atomic")
  action initReleaseFirst = s' = initial("release-first")
  action initOmit = s' = initial("omit-consumer")
  action initDuplicate = s' = initial("duplicate-commit")
  val held = s.reserved.get(0) + s.reserved.get(1)
  val actual = 3 + s.used.get(0) + s.used.get(1)
  val accounted = 3 + s.charged.get(0) + s.charged.get(1)
  action reserve(t: int, cap: int): bool = all {
    s.phase.get(t) == "idle", cap > 0, s.spent + held + cap <= limit,
    s' = { ...s, phase: s.phase.set(t, "running"), reserved: s.reserved.set(t, cap),
           quiescent: s.quiescent.set(t, false) },
  }
  action consume(t: int): bool = all {
    s.phase.get(t) == "running", not(s.quiescent.get(t)), s.used.get(t) < s.reserved.get(t),
    s' = { ...s, used: s.used.set(t, s.used.get(t) + 1) },
  }
  // PASS and DENY have the same charging rule; failure is not free execution.
  action settle(t: int): bool = all {
    s.phase.get(t) == "running", s.quiescent.get(t),
    s' = if (s.policy == "release-first")
      { ...s, phase: s.phase.set(t, "gap"), reserved: s.reserved.set(t, 0) }
    else { ...s, phase: s.phase.set(t, "done"), reserved: s.reserved.set(t, 0),
           spent: s.spent + s.used.get(t), charged: s.charged.set(t, s.used.get(t)) },
  }
  action crash(t: int): bool = all {
    s.phase.get(t) == "running",
    s' = { ...s, phase: s.phase.set(t, "unknown") },
  }
  action terminate(t: int): bool = all {
    Set("running", "unknown").contains(s.phase.get(t)), not(s.quiescent.get(t)),
    s' = { ...s, quiescent: s.quiescent.set(t, true) },
  }
  // Missing completion/teardown cannot release budget. After proving no live
  // process, an exact bound receipt charges actual cost; otherwise charge cap.
  action recover(t: int, receiptBound: bool): bool = {
    val cost = if (receiptBound) s.used.get(t) else s.reserved.get(t)
    all {
      s.phase.get(t) == "unknown", s.quiescent.get(t),
      s' = { ...s, phase: s.phase.set(t, "done"), reserved: s.reserved.set(t, 0),
             spent: s.spent + cost, charged: s.charged.set(t, cost) },
    }
  }
  action omit(t: int): bool = all {
    s.policy == "omit-consumer", s.phase.get(t) == "done", s.charged.get(t) > 0,
    s' = { ...s, spent: s.spent - s.charged.get(t), charged: s.charged.set(t, 0) },
  }
  action duplicate(t: int): bool = all {
    s.policy == "duplicate-commit", s.phase.get(t) == "done", s.charged.get(t) > 0,
    s.spent <= limit,
    s' = { ...s, spent: s.spent + s.charged.get(t) },
  }
  action step = {
    nondet t = requests.oneOf()
    nondet cap = Set(1, 2, 3).oneOf()
    nondet receiptBound = Set(false, true).oneOf()
    any { reserve(t, cap), consume(t), settle(t), crash(t), terminate(t), recover(t, receiptBound),
          omit(t), duplicate(t), s' = s }
  }
  val safe = s.spent == accounted and s.spent + held >= actual and
    s.spent + held <= limit and requests.forall(t => s.phase.get(t) == "done" implies s.quiescent.get(t))
  run failedConsumerChargedTest = init.then(reserve(0, 2)).then(consume(0)).then(terminate(0)).then(settle(0))
    .then(reserve(1, 2)).then(consume(1)).then(consume(1)).then(terminate(1)).then(settle(1))
    .then(all { assert(safe), assert(s.spent == limit), s' = s })
  run interruptedReservationHeldTest = init.then(reserve(0, 3)).then(consume(0)).then(crash(0))
    .then(all { assert(safe), assert(s.spent + held == limit), s' = s })
  run boundRecoveryTest = init.then(reserve(0, 3)).then(consume(0)).then(crash(0)).then(terminate(0)).then(recover(0, true))
    .then(all { assert(safe), assert(s.spent == 4), assert(held == 0), s' = s })
  run unboundRecoveryChargedTest = init.then(reserve(0, 3)).then(crash(0)).then(terminate(0)).then(recover(0, false))
    .then(all { assert(safe), assert(s.spent == limit), s' = s })
  run concurrentReservationsTest = init.then(reserve(0, 1)).then(reserve(1, 2))
    .then(all { assert(safe), assert(s.phase.get(0) == "running"), assert(s.phase.get(1) == "running"), s' = s })
  run releaseBeforeChargeControlTest = initReleaseFirst.then(reserve(0, 2)).then(consume(0)).then(terminate(0)).then(settle(0))
    .then(all { assert(not(safe)), s' = s })
  run omitFailedConsumerControlTest = initOmit.then(reserve(0, 2)).then(consume(0)).then(terminate(0)).then(settle(0)).then(omit(0))
    .then(all { assert(not(safe)), s' = s })
  run duplicateSettlementControlTest = initDuplicate.then(reserve(0, 2)).then(consume(0)).then(terminate(0)).then(settle(0)).then(duplicate(0))
    .then(all { assert(not(safe)), s' = s })
}
