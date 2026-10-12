module thread_migration_destination_claim {
  // Donor, destination and thief are roles, not a runtime worker limit.
  type State = { fixed: bool, oldPinned: bool, pinned: bool,
    phase: int, saved: bool, executing: bool, owner: int, returned: bool }
  var s: State
  pure def initial(fixed: bool, oldPinned: bool): State = {
    fixed: fixed, oldPinned: oldPinned, pinned: oldPinned, phase: 0,
    saved: false, executing: true, owner: 0, returned: false,
  }
  action initOld = s' = initial(false, false)
  action initFixed = {
    nondet oldPinned = Set(false, true).oneOf()
    s' = initial(true, oldPinned)
  }
  action capture = all { s.phase == 0,
    s' = { ...s, phase: 1, saved: true } }
  action relinquish = all { s.phase == 1,
    s' = { ...s, phase: 2, executing: false, owner: -1,
      pinned: if (s.fixed) true else s.pinned } }
  action publish = all { s.phase == 2,
    s' = { ...s, phase: 3 } }
  // Local queue extraction allows pinned threads; remote stealing rejects them.
  action destinationClaim = all { s.phase == 3,
    s' = { ...s, phase: 4, owner: 1 } }
  action thiefClaim = all { s.phase == 3, not(s.pinned),
    s' = { ...s, phase: 4, owner: 2 } }
  action restoreAffinity = all { s.phase == 4,
    s' = { ...s, phase: 5, pinned: s.oldPinned } }
  action returnCaller = all { s.phase == 5,
    s' = { ...s, phase: 6, executing: true, returned: true } }
  val destinationSafe = not(s.phase >= 4) or s.owner == 1
  val savedBeforePublication = not(s.phase >= 3) or s.saved
  val exclusiveExecution = not(s.phase >= 2 and s.phase <= 5) or not(s.executing)
  val affinityRestored = not(s.returned) or s.pinned == s.oldPinned
  val safe = destinationSafe and savedBeforePublication and exclusiveExecution and affinityRestored
  action finished = all { s.returned, s' = s }
  action step = any { capture, relinquish, publish, destinationClaim,
    thiefClaim, restoreAffinity, returnCaller, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.returned))
}
