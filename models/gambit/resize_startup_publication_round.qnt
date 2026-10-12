module resize_startup_publication_round {
  // One old member and one new slot abstract a collective startup round.
  type State = { fixed: bool, fails: bool, proposed: bool, status: int,
    collective: bool, error: int, returned: bool, admitted: bool }
  var s: State
  pure def initial(fixed: bool, fails: bool): State = {
    fixed: fixed, fails: fails, proposed: false, status: 0,
    collective: false, error: 0, returned: false, admitted: false,
  }
  action initEarlyReady = s' = initial(false, false)
  action initEarlyFailure = s' = initial(false, true)
  action initFixed = {
    nondet fails = Set(false, true).oneOf()
    s' = initial(true, fails)
  }
  action propose = all {
    not(s.proposed),
    s' = { ...s, proposed: true,
      status: if (s.fixed) 0 else if (s.fails) -1 else 1 },
  }
  action terminalRound = all {
    s.proposed, not(s.collective), not(s.returned),
    s' = { ...s, collective: true, status: if (s.fails) -1 else 1,
      error: if (s.fails) 1 else 0 },
  }
  action returnNoop = all {
    s.status != 0, not(s.returned),
    s' = { ...s, returned: true, admitted: s.error == 0 },
  }
  val returnAfterRound = not(s.returned) or s.collective
  val failedNotAdmitted = not(s.returned and s.fails) or not(s.admitted)
  val safe = returnAfterRound and failedNotAdmitted
  action finished = all { s.returned, s' = s }
  action step = any { propose, terminalRound, returnNoop, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.returned))
}
