module guard_conflicting_assignment {
  var s: int
  action init = s' = 0
  action conflictingAssignments = all { s' = 0, s' = 1 }
  action step = conflictingAssignments
}
