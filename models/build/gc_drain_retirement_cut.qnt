module gc_drain_retirement_cut {
  import gc_drain_cut_parameters.* from "./gc_drain_cut_parameters"
  type State = { pc: int, r1: bool, r2: bool, cached4: bool, bank4: bool,
    saved: bool, snapshot: bool, capture: bool, failed: bool, normal: bool, called: bool, ticket: bool,
    taint: bool, bound: bool, deadMask: bool, sealed: bool, closed: bool,
    attempt: int, receiptAttempt: int, jobs: bool, deliveries: int }
  // Initial state is a conditional post-action register valuation, not an observed native trace.
  pure val initial: State = { pc: 0, r1: true, r2: true, cached4: true, bank4: true,
    saved: false, snapshot: false, capture: false, failed: false, normal: true, called: true, ticket: true,
    taint: false, bound: false, deadMask: true, sealed: false, closed: false,
    attempt: 1, receiptAttempt: -1, jobs: false, deliveries: 0 }
  var s: State
  action init = s' = initial
  action initCandidate = s' = { ...initial, bound: true }
  action initSkipped = s' = { ...initial, bound: true, normal: false, called: false }
  action initManual = s' = { ...initial, bound: true, ticket: false }
  action willEpilogue = all { s.pc == 0, s' = { ...s, pc: 1, r1: false } }
  action nextWillEmpty = all { s.pc == 1, s' = { ...s, pc: 2, r1: false } }
  action registryEmpty = all { s.pc == 2, s' = { ...s, pc: 3, r1: false, r2: false } }
  action handleToJobs = all { s.pc == 3, s' = { ...s, pc: 4, r1: false } }
  action enterJobs = all { s.pc == 4, s' = { ...s, pc: 5, jobs: true } }
  action jobsPollSnapshot = all { s.pc == 5,
    s' = { ...s, snapshot: s.snapshot or s.r1 or s.r2 or s.cached4 } }
  action clearBankOnly = all { not(s.closed), s' = { ...s, bank4: false } }
  action clearCacheOnly = all { not(s.closed), s' = { ...s, cached4: false } }
  action syncBank = all { not(s.closed), s' = { ...s, bank4: s.cached4 } }
  action saveRoot = all { not(s.closed), s.cached4, s' = { ...s, saved: true } }
  action restoreSaved = all { not(s.closed), s.saved, s' = { ...s, saved: false, cached4: true } }
  action retainSnapshot = all { not(s.closed), s' = { ...s, snapshot: true } }
  action restoreSnapshot = all { not(s.closed), s.snapshot, s' = { ...s, snapshot: false, cached4: true } }
  action captureControl = all { not(s.closed), s' = { ...s, capture: true, taint: true } }
  action dropCapture = s' = { ...s, capture: false }
  action failAction = all { not(s.closed), s' = { ...s, normal: false, failed: true, taint: true } }
  action markLive = all { not(s.closed), s' = { ...s, deadMask: false } }
  // Proposed generated cut: source-qualified dead locations only, all cache/bank copies synchronized.
  def descriptorProfile = GvmRegisters == 5 and WillInternalMask == 1009 and WillReturnMask == 1
  def cutPoint = s.pc == 1 or s.pc == 4
  def canRetire = descriptorProfile and cutPoint and s.bound and s.deadMask and s.normal and s.called and s.ticket and
    not(s.failed or s.taint or s.capture or s.saved or s.snapshot)
  action generatedRetire = all { canRetire,
    s' = { ...s, r1: false, r2: false, cached4: false, bank4: false, closed: true } }
  def rootFree = not(s.r1 or s.r2 or s.cached4 or s.bank4 or s.saved or s.snapshot or s.capture)
  def ready = descriptorProfile and s.closed and s.bound and s.normal and s.called and s.ticket and s.deadMask and not(s.failed or s.taint) and rootFree
  action issue = all { ready, not(s.sealed),
    s' = { ...s, sealed: true, receiptAttempt: s.attempt, deliveries: 1 } }
  action duplicateDelivery = all { s.sealed, s.receiptAttempt == s.attempt, s' = s }
  def safe = (s.closed implies ready) and (s.sealed implies ready and s.receiptAttempt == s.attempt and s.deliveries == 1)
  action step = any { willEpilogue, nextWillEmpty, registryEmpty, handleToJobs, enterJobs, jobsPollSnapshot,
    clearBankOnly, clearCacheOnly, syncBank, saveRoot, restoreSaved, retainSnapshot, restoreSnapshot,
    captureControl, dropCapture, failAction, markLive, generatedRetire, issue, duplicateDelivery, s' = s }
  // Counter-adapters force complete claimed issuance; failures are semantic guard failures.
  action forge = s' = { ...s, closed: true, sealed: true, receiptAttempt: s.attempt, deliveries: 1 }
  action lateRestore = s' = { ...s, cached4: true }
  action staleReceipt = s' = { ...s, receiptAttempt: 0 }
  action duplicateCommit = s' = { ...s, deliveries: 2 }
  run voidLeavesR2Test = init.then(willEpilogue).expect(safe and s.r2)
  run registryLeavesR4Test = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).expect(safe and not(s.r2) and s.cached4 and s.bank4)
  run jobsNotRootCutTest = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(enterJobs).expect(safe and s.jobs and not(rootFree))
  run pollPreservesRootTest = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(enterJobs).then(jobsPollSnapshot).expect(safe and s.snapshot)
  run bankClearRefilledTest = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(clearBankOnly).then(syncBank).expect(safe and s.bank4)
  run cacheClearBankRetainsTest = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(clearCacheOnly).expect(safe and s.bank4)
  run savedClearTransfersTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(saveRoot).then(clearCacheOnly).then(clearBankOnly).then(restoreSaved).expect(safe and not(s.saved) and s.cached4)
  run snapshotRestoreTransfersTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(retainSnapshot).then(clearCacheOnly).then(clearBankOnly).then(restoreSnapshot).expect(safe and not(s.snapshot) and s.cached4)
  run candidateEpilogueTest = initCandidate.then(willEpilogue).then(generatedRetire).then(issue).expect(safe and s.sealed)
  run candidateBatchTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(generatedRetire).then(issue).expect(safe and s.sealed)
  run restoreThenRetireTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(retainSnapshot).then(restoreSnapshot).then(generatedRetire).then(issue).expect(safe and s.sealed)
  run saveThenRetireTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(saveRoot).then(restoreSaved).then(generatedRetire).then(issue).expect(safe and s.sealed)
  run captureDropStillDeniedTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(captureControl).then(dropCapture).expect(safe and not(canRetire))
  run duplicateDeliveryTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(generatedRetire).then(issue).then(duplicateDelivery).then(duplicateDelivery).expect(safe and s.deliveries == 1)
  run jobsAfterSealTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(generatedRetire).then(issue).then(enterJobs).then(jobsPollSnapshot).expect(safe and s.jobs and s.sealed and not(s.snapshot))
  run retainedArtifactNoAdmissionTest = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).expect(safe and not(canRetire))
  run returnOnlyControlTest = init.then(willEpilogue).then(forge).expect(not(safe))
  run emptyQueueControlTest = init.then(willEpilogue).then(nextWillEmpty).then(forge).expect(not(safe))
  run registryControlTest = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(forge).expect(not(safe))
  run jobsControlTest = init.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(enterJobs).then(forge).expect(not(safe))
  run cachedBankControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(clearBankOnly).then(forge).expect(not(safe))
  run bankCacheControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(clearCacheOnly).then(forge).expect(not(safe))
  run savedControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(saveRoot).then(forge).expect(not(safe))
  run snapshotControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(retainSnapshot).then(forge).expect(not(safe))
  run restoredDestinationControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(retainSnapshot).then(restoreSnapshot).then(forge).expect(not(safe))
  run captureControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(captureControl).then(dropCapture).then(forge).expect(not(safe))
  run failureControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(failAction).then(forge).expect(not(safe))
  run liveRegisterControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(markLive).then(forge).expect(not(safe))
  run afterCutRestoreControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(generatedRetire).then(issue).then(lateRestore).expect(not(safe))
  run staleIdentityControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(generatedRetire).then(issue).then(staleReceipt).expect(not(safe))
  run duplicateCommitControlTest = initCandidate.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(generatedRetire).then(issue).then(duplicateCommit).expect(not(safe))
  run skippedNotNormalTest = initSkipped.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).expect(safe and not(canRetire))
  run manualNotGCTest = initManual.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).expect(safe and not(canRetire))
  run skippedReturnControlTest = initSkipped.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(forge).expect(not(safe))
  run manualTicketControlTest = initManual.then(willEpilogue).then(nextWillEmpty).then(registryEmpty).then(handleToJobs).then(forge).expect(not(safe))
}
