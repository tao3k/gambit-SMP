module resize_requester_retained_handoff {
  // One resize request; processor 0 is retained, processor 1 may retire.
  type State = { fixed: bool, caller: int, saved: bool, published: bool,
    begun: bool, donorRetired: bool, resultReady: bool, status: int,
    observed: int, returned: bool }
  var s: State
  pure def initial(fixed: bool, caller: int, status: int): State = {
    fixed: fixed, caller: caller, saved: false, published: false,
    begun: false, donorRetired: false, resultReady: false,
    status: status, observed: -1, returned: false,
  }
  action initOld = s' = initial(false, 1, 0)
  action initFixed = {
    nondet caller = Set(0, 1).oneOf()
    nondet status = Set(0, 7).oneOf()
    s' = initial(true, caller, status)
  }
  action save = all {
    s.fixed, s.caller == 1, not(s.saved), not(s.begun),
    s' = { ...s, saved: true },
  }
  action publish = all {
    s.saved, not(s.published), not(s.begun),
    s' = { ...s, published: true },
  }
  action resumeRetained = all {
    s.published, s.caller == 1, not(s.begun),
    s' = { ...s, caller: 0 },
  }
  action beginResize = all {
    not(s.begun), not(s.fixed) or s.caller == 0,
    s' = { ...s, begun: true },
  }
  action retireDonor = all {
    s.begun, not(s.donorRetired), s' = { ...s, donorRetired: true },
  }
  action deliverResult = all {
    s.donorRetired, not(s.resultReady), s' = { ...s, resultReady: true },
  }
  action returnResult = all {
    s.resultReady, not(s.returned), s.caller == 0 or not(s.donorRetired),
    s' = { ...s, observed: s.status, returned: true },
  }
  val terminal = s.returned
  action finished = all { terminal, s' = s }
  action step = any { save, publish, resumeRetained, beginResize,
    retireDonor, deliverResult, returnResult, finished }
  val requesterSurvives = not(s.donorRetired) or s.caller == 0
  val handoffRooted = not(s.published) or s.saved
  val exactResult = not(s.returned) or s.observed == s.status
  val safe = requesterSurvives and handoffRooted and exactResult
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
