module native_campaign_budget_correspondence {
  // Matching campaigns retain exact scope and budget regime; whole campaigns
  // may change worker topology. Atomic batch caps never become whole-run caps.
  // This is execution eligibility only, not SMP correctness or performance.
  type State = { original: Set[int], current: Set[int], originalAtomic: bool, currentAtomic: bool,
    modeBound: bool, originalCap: int, currentCap: int, fileCapsBound: bool,
    reviewed: bool, spent: int, used: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    original: Set(1, 2), current: Set(1, 2), originalAtomic: false, currentAtomic: false, modeBound: true,
    originalCap: 3, currentCap: 3, fileCapsBound: true, reviewed: false,
    spent: 0, used: false, bypass: bypass,
  }
  action initWhole = s' = initial(false)
  action initAtomic = s' = { ...initial(false), originalAtomic: true, currentAtomic: true }
  action init = any { initWhole, initAtomic }
  action initBypass = any {
    s' = initial(true),
    s' = { ...initial(true), originalAtomic: true, currentAtomic: true }
  }
  val bound = s.original == s.current and s.originalAtomic == s.currentAtomic and s.modeBound and
    s.currentCap <= s.originalCap and s.fileCapsBound and s.reviewed and
    s.spent <= s.currentCap
  action review = all { not(s.used), not(s.reviewed), s' = { ...s, reviewed: true } }
  action omit = all { not(s.used), s.current.contains(2), s' = { ...s, current: Set(1) } }
  action add = all { not(s.used), not(s.current.contains(3)), s' = { ...s, current: s.current.union(Set(3)) } }
  action changeMode = all { not(s.used), s.modeBound, s' = { ...s, modeBound: false } }
  action atomicToWhole = all { not(s.used), s' = { ...s, currentAtomic: not(s.currentAtomic) } }
  action expand = all { not(s.used), s.currentCap == 3, s' = { ...s, currentCap: 4 } }
  action dropFileCap = all { not(s.used), s.fileCapsBound, s' = { ...s, fileCapsBound: false } }
  action spend = all { not(s.used), s.spent < 5, s' = { ...s, spent: s.spent + 1 } }
  action use = all { not(s.used), bound or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { review, omit, add, changeMode, atomicToWhole, expand, dropFileCap, spend, use, hold }
  val safe = s.used implies bound
  run exactWholeTest = initWhole.then(review).then(use)
    .then(all { assert(s.used), assert(safe), s' = s })
  run exactAtomicTest = initAtomic.then(review).then(use)
    .then(all { assert(s.used), assert(safe), s' = s })
  run scopeOmissionControlTest = initBypass.then(review).then(omit).then(use)
    .then(all { assert(not(safe)), s' = s })
  run scopeAdditionControlTest = initBypass.then(review).then(add).then(use)
    .then(all { assert(not(safe)), s' = s })
  run atomicConversionControlTest = initBypass.then(review).then(atomicToWhole).then(use)
    .then(all { assert(not(safe)), s' = s })
  run nestedCapControlTest = initBypass.then(review).then(dropFileCap).then(use)
    .then(all { assert(not(safe)), s' = s })
}
