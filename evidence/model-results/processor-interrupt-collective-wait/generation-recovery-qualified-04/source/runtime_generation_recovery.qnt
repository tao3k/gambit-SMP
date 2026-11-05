module runtime_generation_recovery {
  type State = {
    phase: int, pending: int, joinable: bool, detached: bool,
    failed: bool, cleaned: bool, epoch: int, oldHandler: bool,
    hostQuiet: bool, sealed: bool, entered: bool, cross: bool,
    done: bool, control: int
  }
  var s: State
  pure def initial(c: int): State = {
    phase: 0,
    pending: if (c >= 2) 0 else 1,
    joinable: c == 0,
    detached: c == 1,
    failed: false,
    cleaned: false,
    epoch: 1,
    oldHandler: c >= 2,
    hostQuiet: c == 3,
    sealed: false,
    entered: false,
    cross: false,
    done: false,
    control: c
  }
  action initRecovery = s' = initial(0)
  action initDetached = s' = initial(1)
  action initCross = s' = initial(2)
  // Dedicated verifier initializer is not shared with the union initializer or runs.
  action initCrossCheck = s' = initial(2)
  action initQuiet = s' = initial(3)
  action init = any { initRecovery, initDetached, initCross, initQuiet }
  /// Exclusive-owner slot: actual join. Error retains pending; only ok join clears it.
  action envError = all {
    s.phase == 0,
    or { s.control == 0, s.control == 1 },
    s' = { ...s, phase: 1, failed: true }
  }
  action retryJoinOk = all {
    s.phase == 1, s.control == 0, s.joinable, not(s.detached),
    s' = { ...s, phase: 5, pending: 0, cleaned: true, failed: false, done: true }
  }
  /// Detached ownership breach is a separate non-recoverable premise: retry does not clear.
  action retryFail = all {
    s.phase == 1, s.control == 1, s.detached, not(s.joinable),
    s' = { ...s, phase: 5, failed: true, done: true }
  }
  /// Admitted drain/seal does not remove a pre-admission old handler and does not prove quiescence.
  action sealAdmitted = all {
    s.phase == 0, or { s.control == 2, s.control == 3 }, s.pending == 0, s.oldHandler,
    s' = { ...s, phase: 3, sealed: true }
  }
  action reopenKeepingOld = all {
    s.phase == 3, s.control == 2, s.sealed, s.oldHandler, not(s.hostQuiet),
    s' = { ...s, phase: 4, sealed: false, epoch: 2 }
  }
  /// hostQuiet is an explicit extra contract, not a source effect of seal or sigaction.
  action hostRemoveOld = all {
    s.phase == 3, s.control == 3, s.hostQuiet, s.sealed, s.oldHandler,
    s' = { ...s, oldHandler: false }
  }
  action reopenAfterQuiet = all {
    s.phase == 3, s.control == 3, s.hostQuiet, s.sealed, not(s.oldHandler),
    s' = { ...s, phase: 4, sealed: false, epoch: 2 }
  }
  action enterCross = all {
    s.phase == 4, s.epoch == 2, s.oldHandler, not(s.hostQuiet),
    s' = { ...s, phase: 5, entered: true, cross: true, done: true }
  }
  action enterNoCross = all {
    s.phase == 4, s.epoch == 2, not(s.oldHandler),
    s' = { ...s, phase: 5, entered: false, cross: false, done: true }
  }
  action doneLoop = all { s.done, s.phase == 5, s' = s }
  action step = any {
    envError, retryJoinOk, retryFail, sealAdmitted, reopenKeepingOld,
    hostRemoveOld, reopenAfterQuiet, enterCross, enterNoCross, doneLoop
  }
  val safe =
    (not(s.cleaned) or (s.pending == 0)) and
    (not(s.detached) or ((s.pending > 0) and not(s.cleaned))) and
    (not(s.cross) or ((s.control == 2) and not(s.hostQuiet)))
  val noCross = not(s.cross)
  val noFalseRecovery = not(s.detached and s.cleaned)
  /// Premise only: this finite toy protocol under weak fairness of step. Not an OS-wide claim.
  temporal progress = weakFair(step, Set(s)).implies(eventually(s.done))
  run conditionalRecoveryTest =
    initRecovery.then(envError).then(retryJoinOk).expect(s.cleaned and (s.pending == 0) and s.done and s.joinable)
  run blockedDetachedTest =
    initDetached.then(envError).then(retryFail).expect(s.detached and (s.pending > 0) and not(s.cleaned) and s.failed and s.done)
  run observedCrossTest =
    initCross.then(sealAdmitted).then(reopenKeepingOld).then(enterCross).expect(s.cross and s.entered and (s.epoch == 2))
  run quietSafeTest =
    initQuiet.then(sealAdmitted).then(hostRemoveOld).then(reopenAfterQuiet).then(enterNoCross).expect(not(s.cross) and not(s.oldHandler) and s.done and s.hostQuiet)
}
