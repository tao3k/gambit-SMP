module native_build_driver_correspondence {
  // Eligibility for a compiler-budget investigation, never correctness.
  type State = { policy: str, category: str, original: bool, current: bool,
    samePath: bool, configured: bool, changed: bool, scope: bool, producer: bool,
    originalCap: int, requestedCap: int, reviewed: bool, admitted: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, category: "budget", original: true, current: true,
    samePath: true, configured: true, changed: true, scope: true, producer: true,
    originalCap: 90, requestedCap: 90, reviewed: true, admitted: false,
  }
  action init = s' = initial("bound")
  action initBypass = s' = initial("hash-only")
  action alter = all { not(s.admitted), any {
    s' = { ...s, category: "assertion" },
    s' = { ...s, category: "signal" },
    s' = { ...s, original: false },
    s' = { ...s, current: false },
    s' = { ...s, samePath: false },
    s' = { ...s, configured: false },
    s' = { ...s, changed: false },
    s' = { ...s, scope: false },
    s' = { ...s, producer: false },
    s' = { ...s, requestedCap: 91 },
    s' = { ...s, reviewed: false }
  } }
  val bound = s.category == "budget" and s.original and s.current and
    s.samePath and s.configured and s.changed and s.scope and s.producer and
    s.requestedCap <= s.originalCap and s.reviewed
  action admit = all { not(s.admitted),
    s.policy == "hash-only" or bound, s' = { ...s, admitted: true } }
  action finished = s' = s
  action step = any { alter, admit, finished }
  val safe = not(s.admitted) or bound
  run validBudgetTest = init.then(admit)
    .then(all { assert(safe), assert(s.admitted), s' = s })
  run unknownOriginalControlTest = initBypass
    .then(s' = { ...s, original: false }).then(admit)
    .then(all { assert(not(safe)), s' = s })
  run assertionControlTest = initBypass
    .then(s' = { ...s, category: "assertion" }).then(admit)
    .then(all { assert(not(safe)), s' = s })
  run expandedBudgetControlTest = initBypass
    .then(s' = { ...s, requestedCap: 91 }).then(admit)
    .then(all { assert(not(safe)), s' = s })
}
