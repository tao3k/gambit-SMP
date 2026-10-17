module native_budget_toolchain_scope {
  // A changed cost environment or watchdog invalidates budget comparison only.
  type State = { budgetFailure: bool, compilerDistinct: bool, watchdogDistinct: bool, disjoint: bool,
    reviewed: bool, admitted: bool, bypass: bool }
  var s: State
  pure def initial(budgetFailure: bool, compilerDistinct: bool, watchdogDistinct: bool, bypass: bool): State = {
    budgetFailure: budgetFailure, compilerDistinct: compilerDistinct, watchdogDistinct: watchdogDistinct,
    disjoint: false, reviewed: false, admitted: false, bypass: bypass,
  }
  action initBudget = s' = initial(true, true, false, false)
  action initWatchdogBudget = s' = initial(true, false, true, false)
  action initAssertion = s' = initial(false, true, true, false)
  action initBypass = s' = initial(false, true, true, true)
  action init = any { initBudget, initWatchdogBudget, initAssertion }
  action classify = all {
    not(s.admitted), s.budgetFailure, s.compilerDistinct or s.watchdogDistinct,
    s' = { ...s, disjoint: true },
  }
  action review = all { not(s.admitted), s' = { ...s, reviewed: true } }
  action badClassify = all { s.bypass, not(s.admitted), s' = { ...s, disjoint: true } }
  action admit = all {
    not(s.admitted), s.disjoint or s.reviewed or s.bypass,
    s' = { ...s, admitted: true },
  }
  action hold = s' = s
  action step = any { classify, review, badClassify, admit, hold }
  val safe = s.admitted implies
    ((s.budgetFailure and (s.compilerDistinct or s.watchdogDistinct) and s.disjoint) or s.reviewed)
  run distinctBudgetTest = initBudget.then(classify).then(admit)
    .then(all { assert(s.admitted), assert(safe), s' = s })
  run watchdogBudgetTest = initWatchdogBudget.then(classify).then(admit)
    .then(all { assert(s.admitted), assert(safe), s' = s })
  run assertionReviewTest = initAssertion.then(review).then(admit)
    .then(all { assert(s.admitted), assert(safe), s' = s })
  run assertionDisjointControlTest = initBypass.then(badClassify).then(admit)
    .then(all { assert(not(safe)), s' = s })
}
