module native_resource_plan_correspondence {
  // Original runner/host capacity may be unknown: old demand is a child lower bound.
  type State = { oldChildDemand: int, newTotalDemand: int, capacity: int,
    originalBound: bool, currentBound: bool, scopeBound: bool, budgetBound: bool,
    reviewed: bool, category: str, used: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    oldChildDemand: 8, newTotalDemand: 4, capacity: 4,
    originalBound: true, currentBound: true, scopeBound: true, budgetBound: true,
    reviewed: true, category: "budget", used: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  action alter = all { not(s.used), any {
    s' = { ...s, oldChildDemand: 4 },
    s' = { ...s, newTotalDemand: 0 },
    s' = { ...s, newTotalDemand: 5 },
    s' = { ...s, originalBound: false },
    s' = { ...s, currentBound: false },
    s' = { ...s, scopeBound: false },
    s' = { ...s, budgetBound: false },
    s' = { ...s, reviewed: false },
    s' = { ...s, category: "assertion" },
    s' = { ...s, category: "signal" }
  } }
  val bound = s.newTotalDemand > 0 and s.newTotalDemand <= s.capacity and
    s.newTotalDemand < s.oldChildDemand and s.originalBound and s.currentBound and
    s.scopeBound and s.budgetBound and s.reviewed and s.category == "budget"
  action use = all { not(s.used), bound or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { alter, use, hold }
  val safe = not(s.used) or bound
  run sharedCapacityTest = init.then(use)
    .then(all { assert(safe), assert(s.used), s' = s })
  run unknownOriginalControlTest = initBypass.then(s' = { ...s, originalBound: false })
    .then(use).then(all { assert(not(safe)), s' = s })
  run equalDemandControlTest = initBypass.then(s' = { ...s, oldChildDemand: 4 })
    .then(use).then(all { assert(not(safe)), s' = s })
  run assertionControlTest = initBypass.then(s' = { ...s, category: "assertion" })
    .then(use).then(all { assert(not(safe)), s' = s })
}
