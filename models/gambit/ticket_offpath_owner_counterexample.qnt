module ticket_offpath_owner_counterexample {
  // A stack word can equal a ticket without being that ticket's spill.
  // The actual owner keeps its ticket in a register. No counter wrap or race
  // is needed. Ground truth is used only by the property, not the observer.
  var accepted: int
  var observed: bool
  val realOwner = 1
  val serving = 1
  val stackWord1 = -1
  val stackWord2 = 1

  action init = all { accepted' = 0, observed' = false }
  action observe = all {
    not(observed),
    val match1 = stackWord1 == serving
    val match2 = stackWord2 == serving
    accepted' = if (match1 and not(match2)) 1
      else if (match2 and not(match1)) 2 else 0,
    observed' = true,
  }
  action finished = all { observed, accepted' = accepted, observed' = observed }
  action step = any { observe, finished }
  val ownerSound = accepted == 0 or accepted == realOwner
}
