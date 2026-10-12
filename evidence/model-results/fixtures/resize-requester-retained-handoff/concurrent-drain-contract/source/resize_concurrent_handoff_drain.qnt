module resize_concurrent_handoff_drain {
  // A P0 coordinator may shrink while one other requester is handing off.
  // Abstract admission/drain is a design obligation, not an existing field.
  type State = { fixed: bool, caller: int, pending: bool, closed: bool,
    saved: bool, published: bool, collective: bool, retired: bool,
    resultReady: bool, returned: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, caller: 1, pending: true, closed: false,
    saved: false, published: false, collective: false, retired: false,
    resultReady: false, returned: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action closeAdmission = all {
    not(s.closed), not(s.collective), s' = { ...s, closed: true },
  }
  action save = all {
    s.pending, not(s.saved), not(s.retired), not(s.collective),
    s' = { ...s, saved: true },
  }
  action publish = all {
    s.saved, not(s.published), not(s.retired), not(s.collective),
    s' = { ...s, published: true },
  }
  action resumeRetained = all {
    s.pending, s.published, not(s.collective), not(s.retired),
    s' = { ...s, caller: 0, pending: false },
  }
  action enterCollective = all {
    not(s.collective), s.closed,
    not(s.fixed) or not(s.pending),
    s' = { ...s, collective: true },
  }
  action retireDonor = all {
    s.collective, not(s.retired), s' = { ...s, retired: true },
  }
  action deliverResult = all {
    s.retired, not(s.resultReady), s' = { ...s, resultReady: true },
  }
  action returnResult = all {
    s.resultReady, s.caller == 0, not(s.returned),
    s' = { ...s, returned: true },
  }
  val terminal = s.returned and not(s.pending)
  action finished = all { terminal, s' = s }
  action step = any { closeAdmission, save, publish, resumeRetained,
    enterCollective, retireDonor, deliverResult, returnResult, finished }
  val requesterSurvives = not(s.retired) or s.caller == 0
  val handoffRooted = not(s.published) or s.saved
  val drainBeforeCollective = not(s.collective) or not(s.pending)
  val safe = requesterSurvives and handoffRooted and drainBeforeCollective
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
