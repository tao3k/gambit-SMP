module will_action_admission {
  import will_action_parameters.* from "./will_action_parameters"
  type State = { pc: int, ptr: bool, selfRoot: bool, registers: bool, restore: bool,
    finalized: bool, status: int, wrapperReleased: bool, failed: bool, capture: bool,
    normal: bool, hashMatch: bool, uuidMatch: bool, generation: bool, config: bool,
    masks: bool, restricted: bool, futureNotifier: bool, atBatch: bool, notice: bool, issuer: int,
    genericFailurePremise: bool }
  pure val initial: State = { pc: 0, ptr: true, selfRoot: true, registers: true, restore: false,
    finalized: false, status: 0, wrapperReleased: false, failed: false, capture: false,
    normal: false, hashMatch: RetainedCiMatch, uuidMatch: true, generation: false, config: false,
    masks: ActionMaskAvailable, restricted: RestrictedAction, futureNotifier: false, atBatch: false,
    notice: false, issuer: -1, genericFailurePremise: false }
  var s: State
  action init = s' = initial
  action initClosed = s' = { ...initial, ptr: false }
  action initFailureHypothesis = s' = { ...initial, genericFailurePremise: true }
  // Counterfactual new restricted notifier, already completed. This is NOT SQLite action admission.
  action initQualified = s' = { ...initial, pc: 5, ptr: false, selfRoot: false, registers: false,
    normal: true, generation: true, config: true, masks: true, restricted: true, futureNotifier: true }
  action enter = all { s.pc == 0, s' = { ...s, pc: 1 } }
  action skipClosed = all { s.pc == 1, not(s.ptr), s' = { ...s, pc: 5, normal: true, selfRoot: false } }
  action finalizeOK = all { s.pc == 1, s.ptr, s.selfRoot, s' = { ...s, pc: 2, finalized: true, status: 0 } }
  action finalizeErrorStatus = all { s.pc == 1, s.ptr, s.selfRoot, s' = { ...s, pc: 2, finalized: true, status: 1 } }
  action releaseWrapper = all { s.pc == 2, s.selfRoot, s' = { ...s, pc: 3, wrapperReleased: true } }
  action clearSlot = all { s.pc == 3, s.selfRoot, s' = { ...s, pc: 4, ptr: false } }
  action returnAction = all { s.pc == 4, s' = { ...s, pc: 5, selfRoot: false, normal: true } }
  action pollSnapshot = all { s.pc < 5, s' = { ...s, restore: true } }
  action restoreSnapshot = all { s.restore, not(s.notice), s' = { ...s, restore: false, registers: true } }
  action failRelease = all { s.pc == 2, s.genericFailurePremise,
    s' = { ...s, pc: 6, failed: true, capture: true, normal: false } }
  action enterBatch = all { s.pc >= 5, s' = { ...s, atBatch: true } }
  def rootFree = not(s.selfRoot or s.registers or s.restore or s.capture)
  def ready = s.futureNotifier and s.normal and not(s.failed) and rootFree and
    s.generation and s.config and s.masks and s.restricted
  action issuePerAction = all { s.pc == 5, ready, s' = { ...s, notice: true, issuer: 0 } }
  action issueBatch = all { s.atBatch, ready, s' = { ...s, notice: true, issuer: 1 } }
  def needsSelf = s.pc < 4
  def safe = (needsSelf implies s.selfRoot) and
    (s.wrapperReleased implies s.finalized) and (s.notice implies ready and (s.issuer == 0 or s.atBatch))
  action step = any { enter, skipClosed, finalizeOK, finalizeErrorStatus, releaseWrapper, clearSlot,
    returnAction, pollSnapshot, restoreSnapshot, failRelease, enterBatch, issuePerAction, issueBatch, s' = s }
  action earlyRetire = s' = { ...s, selfRoot: false }
  action forgeIssue = s' = { ...s, notice: true, issuer: 0 }
  action missingMap = s' = { ...s, masks: false }
  action missingGeneration = s' = { ...s, generation: false }
  action missingConfig = s' = { ...s, config: false }
  action legacyCleanup = s' = { ...s, restricted: false, futureNotifier: false }
  action retainedRestore = s' = { ...s, restore: true }
  action retainedRegister = s' = { ...s, registers: true }
  action captureAfterReturn = s' = { ...s, capture: true }
  run registeredActionLiveTest = init.then(enter).expect(safe and s.selfRoot)
  run afterFinalizeLiveTest = init.then(enter).then(finalizeOK).expect(safe and s.selfRoot and s.finalized)
  run afterReleaseLiveTest = init.then(enter).then(finalizeOK).then(releaseWrapper).expect(safe and s.selfRoot and s.wrapperReleased)
  run normalCleanupTest = init.then(enter).then(finalizeOK).then(releaseWrapper).then(clearSlot).then(returnAction).expect(safe and s.normal and not(ready))
  run errorStatusStillDestroyedTest = init.then(enter).then(finalizeErrorStatus).expect(safe and s.finalized and s.status == 1)
  run errorStatusCleanupTest = init.then(enter).then(finalizeErrorStatus).then(releaseWrapper).then(clearSlot).then(returnAction).expect(safe and s.normal and not(ready))
  run closedSkipsTest = initClosed.then(enter).then(skipClosed).expect(safe and s.normal and not(s.finalized) and not(ready))
  run normalBatchNotAdmissionTest = init.then(enter).then(finalizeOK).then(releaseWrapper).then(clearSlot).then(returnAction).then(enterBatch).expect(safe and not(ready))
  run hashNotGenerationTest = init.expect(safe and s.hashMatch and not(s.generation))
  run uuidNotMapsTest = init.expect(safe and s.uuidMatch and not(s.masks))
  run pollKeepsRestoreTest = init.then(enter).then(finalizeOK).then(pollSnapshot).then(releaseWrapper).then(clearSlot).then(returnAction).expect(safe and s.restore and not(ready))
  run restoreTransfersTest = init.then(enter).then(finalizeOK).then(pollSnapshot).then(releaseWrapper).then(clearSlot).then(returnAction).then(restoreSnapshot).expect(safe and s.registers and not(ready))
  run conditionalFailureTest = initFailureHypothesis.then(enter).then(finalizeOK).then(failRelease).expect(safe and s.failed and s.ptr and not(ready))
  run futurePerActionTest = initQualified.then(issuePerAction).expect(safe and s.notice)
  run futureBatchTest = initQualified.then(enterBatch).then(issueBatch).expect(safe and s.notice)
  run futureMapDeniedTest = initQualified.then(missingMap).expect(safe and not(ready))
  run entryRetireControlTest = init.then(enter).then(earlyRetire).expect(not(safe))
  run finalizeRetireControlTest = init.then(enter).then(finalizeOK).then(earlyRetire).expect(not(safe))
  run releaseRetireControlTest = init.then(enter).then(finalizeOK).then(releaseWrapper).then(earlyRetire).expect(not(safe))
  run normalIssueControlTest = init.then(enter).then(finalizeOK).then(releaseWrapper).then(clearSlot).then(returnAction).then(forgeIssue).expect(not(safe))
  run batchIssueControlTest = init.then(enter).then(finalizeOK).then(releaseWrapper).then(clearSlot).then(returnAction).then(enterBatch).then(forgeIssue).expect(not(safe))
  run hashIssueControlTest = init.then(forgeIssue).expect(not(safe))
  run uuidIssueControlTest = init.then(forgeIssue).expect(not(safe))
  run missingMapControlTest = initQualified.then(missingMap).then(forgeIssue).expect(not(safe))
  run missingGenerationControlTest = initQualified.then(missingGeneration).then(forgeIssue).expect(not(safe))
  run missingConfigControlTest = initQualified.then(missingConfig).then(forgeIssue).expect(not(safe))
  run legacyCleanupControlTest = initQualified.then(legacyCleanup).then(forgeIssue).expect(not(safe))
  run restoreControlTest = initQualified.then(retainedRestore).then(forgeIssue).expect(not(safe))
  run registerControlTest = initQualified.then(retainedRegister).then(forgeIssue).expect(not(safe))
  run capturedControlTest = initQualified.then(captureAfterReturn).then(forgeIssue).expect(not(safe))
  run conditionalFailureControlTest = initFailureHypothesis.then(enter).then(finalizeOK).then(failRelease).then(forgeIssue).expect(not(safe))
}
