module notifier_root_retirement {
  import notifier_root_parameters.* from "./notifier_root_parameters"
  type State = { phase: int, arg: bool, reg: bool, saved: bool, stack: bool,
    suspended: bool, captures: Set[int], errors: bool, tainted: bool, failed: bool,
    returned: bool, prepared: bool, windAfter: bool, rootCut: bool,
    closed: bool, effectQualified: bool, receipt: bool, accepted: bool,
    generation: int, attempt: int, epoch: int, receiptGeneration: int, receiptAttempt: int,
    receiptEpoch: int, deliveries: int, resumes: int }
  pure val initial: State = { phase: 0, arg: false, reg: false, saved: false, stack: false,
    suspended: false, captures: Set(), errors: false, tainted: false, failed: false,
    returned: false, prepared: false, windAfter: false, rootCut: false,
    closed: false, effectQualified: true, receipt: false, accepted: false,
    generation: ReceiptGeneration, attempt: 1, epoch: 3, receiptGeneration: -1,
    receiptAttempt: -1, receiptEpoch: -1, deliveries: 0, resumes: 0 }
  var s: State
  action init = s' = initial
  action initUnqualified = s' = { ...initial, effectQualified: false }
  action dispatch = all { s.phase == 0, s' = { ...s, phase: 1, arg: true, reg: true, stack: true } }
  action prepare = all { s.phase == 1, s' = { ...s, prepared: true } }
  action save = all { s.phase == 1, s.reg, s' = { ...s, saved: true } }
  action restore = all { s.saved, not(s.rootCut), s' = { ...s, saved: false, reg: true } }
  action suspend = all { s.phase == 1, s' = { ...s, suspended: true } }
  action restoreSuspended = all { s.suspended, not(s.rootCut), s' = { ...s, suspended: false, reg: true } }
  action capture = all { s.phase == 1, s' = { ...s, captures: s.captures.union(Set(1)), tainted: true } }
  action copyCapture = all { s.captures.contains(1), s' = { ...s, captures: s.captures.union(Set(2)) } }
  action dropFirst = s' = { ...s, captures: s.captures.exclude(Set(1)) }
  action dropSecond = s' = { ...s, captures: s.captures.exclude(Set(2)) }
  action returnAction = all { s.phase == 1, s' = { ...s, phase: 2, arg: false, returned: true } }
  action windEscape = all { s.phase == 1, s' = { ...s, phase: 2, arg: false, returned: false, failed: true, windAfter: true } }
  action raiseError = all { s.phase == 1,
    s' = { ...s, phase: 2, arg: false, failed: true, tainted: true, errors: true, captures: s.captures.union(Set(1)) } }
  action dropError = s' = { ...s, errors: false }
  action resumeCapture = all { s.captures.size() > 0, s.phase == 2, not(s.rootCut),
    s' = { ...s, phase: 1, arg: true, reg: true, stack: true, returned: false, resumes: (s.resumes + 1) % 3 } }
  action dropStack = all { s.phase == 2, s' = { ...s, stack: false } }
  action retireRegister = all { s.phase == 2, s' = { ...s, reg: false } }
  def rootsAbsent = not(s.arg or s.reg or s.saved or s.stack or s.suspended or s.errors) and s.captures.size() == 0
  def canCut = s.phase == 2 and s.returned and s.prepared and rootsAbsent and s.effectQualified and not(s.tainted or s.failed)
  action retireCut = all { canCut, s' = { ...s, rootCut: true, closed: true, phase: 3 } }
  action issueReceipt = all { s.rootCut, s.closed, not(s.receipt),
    s' = { ...s, receipt: true, receiptGeneration: s.generation, receiptAttempt: s.attempt, receiptEpoch: s.epoch } }
  def matched = s.receiptGeneration == s.generation and s.receiptAttempt == s.attempt and s.receiptEpoch == s.epoch
  def valid = s.prepared and s.returned and rootsAbsent and s.rootCut and s.closed and s.effectQualified and
    not(s.tainted or s.failed) and matched
  action accept = all { s.receipt, valid, not(s.accepted), s' = { ...s, accepted: true, deliveries: 1 } }
  action replayDelivery = all { s.accepted, valid, s' = s }
  action rotateAttempt = all { s.receipt, not(s.accepted), s' = { ...s, attempt: 2 } }
  action rotateEpoch = all { s.receipt, not(s.accepted), s' = { ...s, epoch: 4 } }
  action rotateGeneration = all { s.receipt, not(s.accepted), s' = { ...s, generation: s.generation + 1 } }
  def safe = (s.rootCut implies rootsAbsent and s.closed and not(s.tainted or s.failed)) and
    (s.accepted implies s.receipt and valid and s.deliveries == 1)
  action step = any { dispatch, prepare, save, restore, suspend, restoreSuspended,
    capture, copyCapture, dropFirst, dropSecond, returnAction, windEscape, raiseError, dropError,
    resumeCapture, dropStack, retireRegister, retireCut, issueReceipt, accept, replayDelivery,
    rotateAttempt, rotateEpoch, rotateGeneration, s' = s }
  // Deliberately invalid adapters. Both receipt and accepted are forged so controls test semantics, not one missing flag.
  action forge = s' = { ...s, receipt: true, accepted: true, deliveries: 1,
    receiptGeneration: s.generation, receiptAttempt: s.attempt, receiptEpoch: s.epoch }
  action forgeRootCut = s' = { ...s, rootCut: true, closed: true }
  action restoreAfterCut = s' = { ...s, reg: true }
  action duplicate = s' = { ...s, deliveries: 2 }
  action forgeStale = s' = { ...s, accepted: true, deliveries: 1 }
  run dispatchRootsTest = init.then(dispatch).then(prepare).expect(safe and not(rootsAbsent))
  run returnLeavesRegistersTest = init.then(dispatch).then(prepare).then(returnAction).expect(safe and s.reg and not(canCut))
  run stackRemovalInsufficientTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).expect(safe and not(canCut))
  run registerRemovalInsufficientTest = init.then(dispatch).then(prepare).then(returnAction).then(retireRegister).expect(safe and not(canCut))
  run savedRootRemainsTest = init.then(dispatch).then(prepare).then(save).then(returnAction).then(dropStack).then(retireRegister).expect(safe and s.saved and not(canCut))
  run savedClearTransfersTest = init.then(dispatch).then(prepare).then(save).then(returnAction).then(dropStack).then(retireRegister).then(restore).expect(safe and not(s.saved) and s.reg and not(canCut))
  run qualifiedRetirementTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(accept).expect(safe and s.accepted)
  run saveRestoreThenRetireTest = init.then(dispatch).then(prepare).then(save).then(restore).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(accept).expect(safe and s.accepted)
  run suspendedRestoreThenRetireTest = init.then(dispatch).then(prepare).then(suspend).then(returnAction).then(dropStack).then(retireRegister).then(restoreSuspended).then(retireRegister).then(retireCut).then(issueReceipt).then(accept).expect(safe and s.accepted)
  run copyKeepsCaptureTest = init.then(dispatch).then(prepare).then(capture).then(copyCapture).then(returnAction).then(dropFirst).then(dropStack).then(retireRegister).expect(safe and s.captures.contains(2) and not(canCut))
  run multiShotResumeTest = init.then(dispatch).then(prepare).then(capture).then(returnAction).then(resumeCapture).then(returnAction).then(resumeCapture).then(returnAction).expect(safe and s.resumes == 2 and s.tainted)
  run dropAllStillTaintedTest = init.then(dispatch).then(prepare).then(capture).then(copyCapture).then(returnAction).then(dropFirst).then(dropSecond).then(dropStack).then(retireRegister).expect(safe and rootsAbsent and not(canCut))
  run errorKeepsControlTest = init.then(dispatch).then(prepare).then(raiseError).then(dropStack).then(retireRegister).expect(safe and s.errors and not(canCut))
  run errorResumeStillFailedTest = init.then(dispatch).then(prepare).then(raiseError).then(dropError).then(resumeCapture).then(returnAction).then(dropFirst).then(dropStack).then(retireRegister).expect(safe and s.returned and s.failed and not(canCut))
  run windAfterInsufficientTest = init.then(dispatch).then(prepare).then(windEscape).then(dropStack).then(retireRegister).expect(safe and s.windAfter and not(canCut))
  run duplicateSettlesTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(accept).then(replayDelivery).then(replayDelivery).expect(safe and s.deliveries == 1)
  run unqualifiedDeniedTest = initUnqualified.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).expect(safe and not(canCut))
  run staleAttemptDeniedTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(rotateAttempt).expect(safe and not(valid))
  run earlyReturnControlTest = init.then(dispatch).then(prepare).then(returnAction).then(forge).expect(not(safe))
  run savedSlotControlTest = init.then(dispatch).then(prepare).then(save).then(returnAction).then(dropStack).then(retireRegister).then(forgeRootCut).then(forge).expect(not(safe))
  run savedTransferControlTest = init.then(dispatch).then(prepare).then(save).then(returnAction).then(dropStack).then(retireRegister).then(restore).then(forgeRootCut).then(forge).expect(not(safe))
  run suspendedControlTest = init.then(dispatch).then(prepare).then(suspend).then(returnAction).then(dropStack).then(retireRegister).then(forgeRootCut).then(forge).expect(not(safe))
  run copiedCaptureControlTest = init.then(dispatch).then(prepare).then(capture).then(copyCapture).then(returnAction).then(dropFirst).then(dropStack).then(retireRegister).then(forgeRootCut).then(forge).expect(not(safe))
  run dropCaptureTaintControlTest = init.then(dispatch).then(prepare).then(capture).then(returnAction).then(dropFirst).then(dropStack).then(retireRegister).then(forgeRootCut).then(forge).expect(not(safe))
  run windControlTest = init.then(dispatch).then(prepare).then(windEscape).then(dropStack).then(retireRegister).then(forgeRootCut).then(forge).expect(not(safe))
  run errorResumeControlTest = init.then(dispatch).then(prepare).then(raiseError).then(resumeCapture).then(returnAction).then(dropError).then(dropFirst).then(dropStack).then(retireRegister).then(forgeRootCut).then(forge).expect(not(safe))
  run futureRestoreControlTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(accept).then(restoreAfterCut).expect(not(safe))
  run staleAttemptControlTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(rotateAttempt).then(forgeStale).expect(not(safe))
  run staleEpochControlTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(rotateEpoch).then(forgeStale).expect(not(safe))
  run staleGenerationControlTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(rotateGeneration).then(forgeStale).expect(not(safe))
  run duplicateControlTest = init.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(retireCut).then(issueReceipt).then(accept).then(duplicate).expect(not(safe))
  run unqualifiedControlTest = initUnqualified.then(dispatch).then(prepare).then(returnAction).then(dropStack).then(retireRegister).then(forgeRootCut).then(forge).expect(not(safe))
}
