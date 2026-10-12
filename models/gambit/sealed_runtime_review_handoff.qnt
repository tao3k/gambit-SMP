module sealed_runtime_review_handoff {
  // Identities are abstract equality tokens, not cryptographic verification.
  type Identity = { source: int, engine: int, tool: int, fixture: int,
                    failure: int, runtime: int }
  type State = { current: Identity, reviewed: Identity, producerPass: bool,
                 reviewedPass: bool, spent: int, actualSpent: int,
                 launched: bool, bypassProducer: bool, bypassIdentity: bool,
                 allowReset: bool }
  var s: State
  pure val base = { source: 0, engine: 0, tool: 0, fixture: 0,
                    failure: 0, runtime: 0 }
  pure def initial(producer: bool, identity: bool, reset: bool): State = {
    current: base, reviewed: base, producerPass: false, reviewedPass: false,
    spent: 0, actualSpent: 0, launched: false, bypassProducer: producer,
    bypassIdentity: identity, allowReset: reset,
  }
  action init = s' = initial(false, false, false)
  action initUnqualified = s' = initial(true, false, false)
  action initStale = s' = initial(false, true, false)
  action initReset = s' = initial(false, false, true)

  // PASS and successful review stand for external verified obligations.
  // They do not establish source refinement, GC correctness or test success.
  action produce = all {
    not(s.launched), not(s.producerPass), s.actualSpent < 3,
    s' = { ...s, producerPass: true, spent: s.spent + 1,
           actualSpent: s.actualSpent + 1 },
  }
  action review = all {
    not(s.launched), not(s.reviewedPass), s.actualSpent < 3,
    s' = { ...s, reviewed: s.current, reviewedPass: true,
           spent: s.spent + 1, actualSpent: s.actualSpent + 1 },
  }
  action drift = all {
    not(s.launched),
    any {
      all { s.current.source == 0, s' = { ...s, current: { ...s.current, source: 1 } } },
      all { s.current.engine == 0, s' = { ...s, current: { ...s.current, engine: 1 } } },
      all { s.current.tool == 0, s' = { ...s, current: { ...s.current, tool: 1 } } },
      all { s.current.fixture == 0, s' = { ...s, current: { ...s.current, fixture: 1 } } },
      all { s.current.failure == 0, s' = { ...s, current: { ...s.current, failure: 1 } } },
      all { s.current.runtime == 0, s' = { ...s, current: { ...s.current, runtime: 1 } } },
    },
  }
  action work = all {
    not(s.launched), s.actualSpent < 4,
    s' = { ...s, spent: s.spent + 1, actualSpent: s.actualSpent + 1 },
  }
  action reset = all {
    not(s.launched), s.allowReset, s.spent > 0,
    s' = { ...s, spent: 0 },
  }
  action launch = all {
    not(s.launched), s.reviewedPass,
    s.producerPass or s.bypassProducer,
    s.current == s.reviewed or s.bypassIdentity,
    s.spent + 1 <= 3,
    s' = { ...s, launched: true, spent: s.spent + 1,
           actualSpent: s.actualSpent + 1 },
  }
  action hold = s' = s
  action step = any { produce, review, drift, work, reset, launch, hold }
  val qualified = s.launched implies s.producerPass
  val exactIdentity = s.launched implies s.current == s.reviewed
  val budgetRetained = s.spent == s.actualSpent
  val bounded = s.launched implies s.actualSpent <= 3
  val safe = qualified and exactIdentity and budgetRetained and bounded
  val eligible = not(s.launched) and s.reviewedPass and s.producerPass and
    s.current == s.reviewed and s.spent + 1 <= 3
  // Only a continuously eligible launch is promised under weak fairness.
  // Review availability, elapsed time and reaching eligibility are not proved.
  temporal completion = weakFair(launch, Set(s)).implies(
    always(eligible.implies(eventually(s.launched or not(eligible)))))
  run admittedHandoffTest = init.then(produce).then(review).then(launch)
    .then(all { assert(s.launched), assert(safe), s' = s })
  run unqualifiedProducerControlTest = initUnqualified.then(review).then(launch)
    .then(all { assert(not(qualified)), s' = s })
  run staleIdentityControlTest = initStale.then(produce).then(review).then(drift).then(launch)
    .then(all { assert(not(exactIdentity)), s' = s })
  run budgetResetControlTest = initReset.then(produce).then(review).then(work)
    .then(reset).then(launch)
    .then(all { assert(not(budgetRetained)), assert(not(bounded)), s' = s })
}
