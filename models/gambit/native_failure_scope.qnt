module native_failure_scope {
  // Mode/phase correspondence is externally bound to immutable receipts.
  // Unknown scope overlaps both modes; a containing campaign never enlarges a cap.
  type State = { scope: int, mode: int, reviewed: bool, used: bool,
                 caseCap: int, caseSpent: int, wholeCap: int, wholeSpent: int,
                 bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    scope: 0, mode: 1, reviewed: false, used: false,
    caseCap: 2, caseSpent: 0, wholeCap: 4, wholeSpent: 0, bypass: bypass,
  }
  action init = {
    nondet scope = 0.to(2).oneOf()
    nondet mode = 1.to(2).oneOf()
    s' = { ...initial(false), scope: scope, mode: mode }
  }
  action initBypass = s' = initial(true)
  val overlaps = s.scope == 0 or s.scope == s.mode
  val permitted = (not(overlaps) or s.reviewed) and
    s.caseSpent <= s.caseCap and s.wholeSpent <= s.wholeCap
  action review = all { not(s.used), not(s.reviewed), s' = { ...s, reviewed: true } }
  action spend = all { not(s.used), s.wholeSpent < 5,
    s' = { ...s, caseSpent: s.caseSpent + 1, wholeSpent: s.wholeSpent + 1 } }
  action use = all { not(s.used), permitted or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { review, spend, use, hold }
  val safe = s.used implies permitted
  run unknownScopeTest = initBypass
    .then(all { assert(overlaps), assert(not(permitted)), s' = s })
  run matchingReviewedTest = initBypass.then(review).then(use)
    .then(all { assert(safe), s' = s })
  run nestedBudgetControlTest = initBypass.then(review).then(spend).then(spend).then(spend).then(use)
    .then(all { assert(s.wholeSpent <= s.wholeCap), assert(not(safe)), s' = s })
}
