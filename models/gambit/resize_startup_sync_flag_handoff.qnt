module resize_startup_sync_flag_handoff {
  // Old/new are cohort representatives, not a runtime processor limit.
  type State = { fixed: bool, lateRequest: bool, phase: int,
    oldFlag: bool, newFlag: bool, pending: bool, waiting: bool }
  var s: State
  pure def initial(fixed: bool, lateRequest: bool): State = {
    fixed: fixed, lateRequest: lateRequest, phase: 0,
    oldFlag: false, newFlag: false, pending: false, waiting: false,
  }
  action initOld = s' = initial(false, false)
  action initFixed = {
    nondet lateRequest = Set(false, true).oneOf()
    s' = initial(true, lateRequest)
  }
  // Old members already reset their flag in the original resize first round.
  // The new READY caller raises SYNC for all members after that reset.
  action requestReady = all {
    s.phase == 0,
    s' = { ...s, phase: 1, oldFlag: true, newFlag: true },
  }
  action receiveReady = all {
    s.phase == 1,
    s' = { ...s, phase: 2, newFlag: false,
      oldFlag: if (s.fixed) false else s.oldFlag },
  }
  action commonNoopExit = all {
    s.phase == 2, s' = { ...s, phase: 3 },
  }
  // A genuinely new request after the collective exit must remain visible.
  action requestAfterExit = all {
    s.phase == 3, s.lateRequest, not(s.pending),
    s' = { ...s, oldFlag: true, newFlag: true, pending: true },
  }
  action pollOld = all {
    s.phase == 3, not(s.lateRequest) or s.pending,
    s' = { ...s, phase: 4, waiting: s.oldFlag },
  }
  action serviceRepresentedRequest = all {
    s.phase == 4, s.waiting, s.newFlag, s.pending,
    s' = { ...s, phase: 5, oldFlag: false, newFlag: false,
      pending: false, waiting: false },
  }
  action noRequest = all {
    s.phase == 4, not(s.waiting), s' = { ...s, phase: 5 },
  }
  val noStrandedSync = not(s.waiting) or s.newFlag
  val newRequestVisible = not(s.phase == 3 and s.pending) or s.oldFlag
  val safe = noStrandedSync and newRequestVisible
  val terminal = s.phase == 5
  action finished = all { terminal, s' = s }
  action step = any { requestReady, receiveReady, commonNoopExit,
    requestAfterExit, pollOld, serviceRepresentedRequest, noRequest, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
