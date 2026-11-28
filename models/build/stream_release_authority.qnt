module stream_release_authority {
  import stream_release_parameters.* from "./stream_release_parameters"
  type State = { open: bool, epoch: int, observed: int, generation: int,
    reservation: bool, root: bool, borrowed: bool, grantUnknown: bool, releaseUnknown: bool,
    caller: bool, trace: bool, control: bool, hiddenAlias: bool, coverage: bool,
    actionBackedge: bool, notifierPrivate: bool, willActive: bool, willEligible: bool,
    notice: bool, noticeEpoch: int, noticeGeneration: int,
    permit: bool, consumed: bool, acceptedAfterClose: bool, grants: int, executions: int }
  var s: State
  pure val initial: State = { open: true, epoch: 0, observed: -1, generation: OwnerGeneration,
    reservation: false, root: false, borrowed: false, grantUnknown: false, releaseUnknown: false,
    caller: true, trace: false, control: false, hiddenAlias: false, coverage: true,
    actionBackedge: false, notifierPrivate: true, willActive: false, willEligible: false,
    notice: false, noticeEpoch: -1, noticeGeneration: -1,
    permit: false, consumed: false, acceptedAfterClose: false, grants: 0, executions: 0 }
  action init = s' = initial
  action observeOpen = all { s.open, s' = { ...s, observed: s.epoch } }
  def canReserve = s.open and s.caller and s.observed == s.epoch and not(s.reservation) and not(s.borrowed) and not(s.releaseUnknown)
  action reserve = all { canReserve, s' = { ...s, reservation: true, executions: 0 } }
  action publishRoot = all { s.reservation, s.caller, s' = { ...s, root: true } }
  action commitBorrow = all { s.open, s.reservation, s.root, s.observed == s.epoch,
    s' = { ...s, reservation: false, borrowed: true, grants: s.grants + 1, executions: 1 } }
  action commitUnknown = all { s.open, s.reservation, s.root, s.observed == s.epoch,
    s' = { ...s, reservation: false, borrowed: true, grantUnknown: true, grants: s.grants + 1, executions: 1 } }
  action closeAdmission = all { s.open, s' = { ...s, open: false, epoch: s.epoch + 1 } }
  action rollback = all { not(s.open), s.reservation,
    s' = { ...s, reservation: false, root: false } }
  action dropCaller = all { not(s.reservation) or s.root, s' = { ...s, caller: false } }
  action settleGrant = all { s.grantUnknown, s' = { ...s, grantUnknown: false } }
  action canonicalReleaseUnknown = all { s.borrowed, not(s.grantUnknown),
    s' = { ...s, borrowed: false, root: false, releaseUnknown: true } }
  action settleRelease = all { s.releaseUnknown, s' = { ...s, releaseUnknown: false } }
  def strongReach = s.caller or s.trace or s.control or s.root or s.actionBackedge or s.willActive
  action installTrace = all { s.caller, s' = { ...s, trace: true } }
  action dropTraceWitness = s' = { ...s, trace: false }
  action installControl = all { s.caller, s' = { ...s, control: true } }
  action dropControlWitness = s' = { ...s, control: false }
  action monitorCapturesOwner = all { not(s.notice), s' = { ...s, actionBackedge: true } }
  action gcObserve = all { not(s.open), not(strongReach), not(s.reservation), not(s.borrowed),
    s' = { ...s, willEligible: true } }
  action startWill = all { s.willEligible, not(s.willActive), not(s.notice),
    s' = { ...s, willActive: true } }
  action finishPrivateWill = all { s.willActive, s.notifierPrivate,
    s' = { ...s, willActive: false, notice: true, noticeEpoch: s.epoch, noticeGeneration: s.generation } }
  def drained = not(s.reservation) and not(s.borrowed) and not(s.root) and not(s.grantUnknown) and not(s.releaseUnknown)
  def noticeValid = s.notice and s.noticeEpoch == s.epoch and s.noticeGeneration == s.generation
  def canPermit = not(s.open) and s.coverage and s.notifierPrivate and noticeValid and drained and not(strongReach) and not(s.hiddenAlias)
  action issuePermit = all { canPermit, s' = { ...s, permit: true } }
  action consume = all { s.permit, not(s.consumed), s' = { ...s, consumed: true } }
  action changeGeneration = all { not(s.permit), not(s.consumed), s.notice,
    s' = { ...s, generation: s.generation + 1 } }
  def safe = not(s.acceptedAfterClose) and s.executions <= 1 and
    (s.reservation implies s.caller or s.root) and (s.borrowed implies s.root) and
    (s.grantUnknown implies s.borrowed and s.root) and
    (s.releaseUnknown implies not(s.borrowed) and not(s.root)) and
    (s.permit implies canPermit) and (s.consumed implies s.permit)
  action step = any { observeOpen, reserve, publishRoot, commitBorrow, commitUnknown,
    closeAdmission, rollback, dropCaller, settleGrant, canonicalReleaseUnknown, settleRelease,
    installTrace, dropTraceWitness, installControl, dropControlWitness, gcObserve, startWill,
    finishPrivateWill, issuePermit, consume, changeGeneration, s' = s }
  action lateCommit = s' = { ...s, borrowed: true, acceptedAfterClose: true }
  action exposeUnrooted = s' = { ...s, reservation: false, borrowed: true }
  action clearGrantRoot = s' = { ...s, root: false }
  action erasePendingByPermit = s' = { ...s, permit: true }
  action duplicateUnknownGrant = s' = { ...s, grants: s.grants + 1, executions: s.executions + 1 }
  action uncoverRawAlias = s' = { ...s, hiddenAlias: true, coverage: false }
  action publicWill = s' = { ...s, notifierPrivate: false }
  action reserveWithoutCaller = s' = { ...s, reservation: true }
  action publicResurrection = all { s.willActive, not(s.notifierPrivate), s' = { ...s, caller: true } }
  run closedReadCannotReserveTest = init.then(observeOpen).then(closeAdmission).expect(safe and s.observed != s.epoch)
  run lostCallerCannotReserveTest = init.then(observeOpen).then(dropCaller).expect(safe and not(canReserve))
  run closeWithPreparedRootTest = init.then(observeOpen).then(reserve).then(publishRoot).then(closeAdmission).then(dropCaller).expect(safe and s.reservation and s.root and not(canPermit))
  run preparedRollbackTest = init.then(observeOpen).then(reserve).then(publishRoot).then(closeAdmission).then(rollback).then(dropCaller).expect(safe and drained)
  run unknownGrantKeepsRootTest = init.then(observeOpen).then(reserve).then(publishRoot).then(commitUnknown).then(closeAdmission).then(dropCaller).expect(safe and strongReach and not(drained))
  run canonicalReleaseRootlessAckTest = init.then(observeOpen).then(reserve).then(publishRoot).then(commitBorrow).then(closeAdmission).then(dropCaller).then(canonicalReleaseUnknown).expect(safe and not(strongReach) and s.releaseUnknown and not(drained))
  run gcNoticeWaitsAckTest = init.then(observeOpen).then(reserve).then(publishRoot).then(commitBorrow).then(closeAdmission).then(dropCaller).then(canonicalReleaseUnknown).then(gcObserve).then(startWill).then(finishPrivateWill).expect(safe and s.notice and not(canPermit))
  run releaseAckThenPermitTest = init.then(observeOpen).then(reserve).then(publishRoot).then(commitBorrow).then(closeAdmission).then(dropCaller).then(canonicalReleaseUnknown).then(gcObserve).then(startWill).then(finishPrivateWill).then(settleRelease).then(issuePermit).then(consume).expect(safe and s.consumed)
  run fullPermitTest = init.then(closeAdmission).then(dropCaller).then(gcObserve).then(startWill).then(finishPrivateWill).then(issuePermit).then(consume).expect(safe and s.consumed)
  run traceKeepsOwnerTest = init.then(installTrace).then(closeAdmission).then(dropCaller).expect(safe and strongReach and not(canPermit))
  run controlKeepsOwnerTest = init.then(installControl).then(closeAdmission).then(dropCaller).expect(safe and strongReach)
  run strongActionPreventsNoticeTest = init.then(monitorCapturesOwner).then(closeAdmission).then(dropCaller).expect(safe and strongReach and not(s.notice))
  run willCallbackNotDrainedTest = init.then(closeAdmission).then(dropCaller).then(gcObserve).then(startWill).expect(safe and strongReach and not(canPermit))
  run staleGenerationBlocksTest = init.then(closeAdmission).then(dropCaller).then(gcObserve).then(startWill).then(finishPrivateWill).then(changeGeneration).expect(safe and not(noticeValid) and not(canPermit))
  run lateCommitControlTest = init.then(observeOpen).then(closeAdmission).then(lateCommit).expect(not(safe))
  run lostCallerReservationControlTest = init.then(observeOpen).then(dropCaller).then(reserveWithoutCaller).expect(not(safe))
  run unrootedExposeControlTest = init.then(observeOpen).then(reserve).then(exposeUnrooted).expect(not(safe))
  run unknownGrantDropControlTest = init.then(observeOpen).then(reserve).then(publishRoot).then(commitUnknown).then(clearGrantRoot).expect(not(safe))
  run unresolvedReleasePermitControlTest = init.then(observeOpen).then(reserve).then(publishRoot).then(commitBorrow).then(closeAdmission).then(dropCaller).then(canonicalReleaseUnknown).then(erasePendingByPermit).expect(not(safe))
  run unknownGrantRetryControlTest = init.then(observeOpen).then(reserve).then(publishRoot).then(commitUnknown).then(duplicateUnknownGrant).expect(not(safe) and s.grants == 2)
  run wrapperWithoutCoverageControlTest = init.then(uncoverRawAlias).then(closeAdmission).then(dropCaller).then(gcObserve).then(startWill).then(finishPrivateWill).then(erasePendingByPermit).expect(not(safe))
  run publicResurrectionControlTest = init.then(publicWill).then(closeAdmission).then(dropCaller).then(gcObserve).then(startWill).then(publicResurrection).then(erasePendingByPermit).expect(not(safe))
  run oldGenerationPermitControlTest = init.then(closeAdmission).then(dropCaller).then(gcObserve).then(startWill).then(finishPrivateWill).then(changeGeneration).then(erasePendingByPermit).expect(not(safe))
  run eligibilityOnlyPermitControlTest = init.then(closeAdmission).then(dropCaller).then(gcObserve).then(erasePendingByPermit).expect(not(safe))
  run selfRootPermitControlTest = init.then(monitorCapturesOwner).then(closeAdmission).then(dropCaller).then(erasePendingByPermit).expect(not(safe))
}
