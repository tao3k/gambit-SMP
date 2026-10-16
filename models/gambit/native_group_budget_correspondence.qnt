module native_group_budget_correspondence {
  // Preserve an original whole group's scope and deadline inside a larger grid.
  // Preparation counts against the group cap; eligibility is not runtime green.
  type State = { original: Set[int], group: Set[int], whole: Set[int],
    originalCap: int, groupCap: int, prepared: int, executed: int,
    reviewed: bool, used: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    original: Set(1, 2), group: Set(1, 2), whole: Set(1, 2, 3),
    originalCap: 3, groupCap: 3, prepared: 0, executed: 0,
    reviewed: false, used: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  val bound = s.original == s.group and s.group.subseteq(s.whole) and
    s.groupCap <= s.originalCap and s.prepared + s.executed <= s.groupCap and s.reviewed
  action review = all { not(s.used), not(s.reviewed), s' = { ...s, reviewed: true } }
  action omitGroup = all { not(s.used), s.group.contains(2), s' = { ...s, group: Set(1) } }
  action omitWhole = all { not(s.used), s.whole.contains(2), s' = { ...s, whole: Set(1, 3) } }
  action expand = all { not(s.used), s.groupCap == 3, s' = { ...s, groupCap: 4 } }
  action prepare = all { not(s.used), s.prepared < 4, s' = { ...s, prepared: s.prepared + 1 } }
  action execute = all { not(s.used), s.executed < 4, s' = { ...s, executed: s.executed + 1 } }
  action use = all { not(s.used), bound or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { review, omitGroup, omitWhole, expand, prepare, execute, use, hold }
  val safe = s.used implies bound
  run exactGroupTest = init.then(review).then(prepare).then(execute).then(use)
    .then(all { assert(s.used), assert(safe), s' = s })
  run omittedGroupControlTest = initBypass.then(review).then(omitGroup).then(use)
    .then(all { assert(not(safe)), s' = s })
  run omittedWholeControlTest = initBypass.then(review).then(omitWhole).then(use)
    .then(all { assert(not(safe)), s' = s })
  run expandedCapControlTest = initBypass.then(review).then(expand).then(use)
    .then(all { assert(not(safe)), s' = s })
  run preparationExpenditureControlTest = initBypass.then(review)
    .then(prepare).then(prepare).then(execute).then(execute).then(use)
    .then(all { assert(not(safe)), s' = s })
}
