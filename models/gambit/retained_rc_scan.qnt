module retained_rc_scan {
  // TARGET protocol. One retained domain and one active proxy; not native traces.
  // Membership, scan executor and physical donor lifetime are separate facts.
  type State = { workers: Set[int], registered: bool, frozen: bool,
    donorAlive: bool, joined: bool, joinOutcome: int, owner: int, revision: int,
    phase: int, pin: bool, exclusive: bool, snapshotOwner: int, snapshotRevision: int,
    gcEpoch: int, rootEpoch: int, executor: int, stillPrepared: bool,
    stillTraced: bool, accounted: bool, work: int, transfer: int,
    receiptSeen: bool, intakeClosed: bool }
  var s: State
  action init = s' = { workers: Set(0, 1), registered: true, frozen: false,
    donorAlive: true, joined: false, joinOutcome: -1, owner: 1, revision: 0,
    phase: 0, pin: false, exclusive: false, snapshotOwner: 1, snapshotRevision: 0,
    gcEpoch: 0, rootEpoch: 0, executor: 0, stillPrepared: false,
    stillTraced: false, accounted: false, work: 0, transfer: 0,
    receiptSeen: false, intakeClosed: false }
  val collecting = s.phase > 0 and s.phase < 6
  val safe = s.registered and (s.owner != 1 or s.donorAlive) and
    (not(s.pin) or (s.snapshotOwner == s.owner and s.snapshotRevision == s.revision and not(s.exclusive))) and
    (not(s.exclusive) or not(s.pin)) and
    (not(collecting) or (s.pin and s.frozen and s.workers.contains(s.executor))) and
    (s.phase < 3 or (s.stillPrepared and s.rootEpoch == s.gcEpoch)) and
    (s.phase != 6 or (s.accounted and s.stillTraced and s.work == 0)) and
    (s.workers.contains(1) or s.frozen or s.intakeClosed) and
    (s.joinOutcome != 1 or not(s.joined))
  action freezeWriters = all { not(s.exclusive), not(s.pin),
    s' = { ...s, frozen: true } }
  action retire = all { s.frozen, s.registered, s.workers.contains(1),
    not(s.pin), not(s.exclusive), (s.phase == 0 or s.phase == 6),
    s' = { ...s, workers: Set(0) } }
  action joinFailed = all { not(s.workers.contains(1)), not(s.joined), s.transfer == 0,
    s' = { ...s, joinOutcome: 1, joined: false } }
  action joinUnknown = all { not(s.workers.contains(1)), not(s.joined), s.transfer == 0,
    s' = { ...s, joinOutcome: -1, joined: false } }
  action joinSuccess = all { not(s.workers.contains(1)), not(s.joined), s.transfer == 0,
    s' = { ...s, joinOutcome: 0, joined: true } }
  // Missing freeze evidence forbids both collection and further allocating entry.
  action quarantineUnknown = all { not(s.frozen), s.phase == 0,
    s' = { ...s, workers: Set(0), intakeClosed: true, joinOutcome: -1 } }
  action beginGC = all { s.registered, s.frozen, not(s.exclusive), not(s.pin),
    (s.phase == 0 or s.phase == 6), not(s.intakeClosed),
    s' = { ...s, phase: 1, pin: true, snapshotOwner: s.owner,
      snapshotRevision: s.revision, gcEpoch: s.gcEpoch + 1, executor: 0,
      stillPrepared: false, stillTraced: false, accounted: false, work: 0 } }
  action prepareStill = all { s.phase == 1, s.pin,
    s' = { ...s, phase: 2, stillPrepared: true } }
  action scanRoots = all { s.phase == 2, s.pin, s.stillPrepared,
    s.snapshotOwner == s.owner, s.snapshotRevision == s.revision,
    s.workers.contains(s.executor),
    s' = { ...s, phase: 3, rootEpoch: s.gcEpoch, work: 1 } }
  action drainTrace = all { s.phase == 3, s.work > 0, s.pin,
    s' = { ...s, work: 0, stillTraced: true } }
  action weakComplete = all { s.phase == 3, s.work == 0, s.stillTraced, s.pin,
    s' = { ...s, phase: 4 } }
  action cleanupAccount = all { s.phase == 4, s.pin,
    s' = { ...s, phase: 5, accounted: true } }
  action finishGC = all { s.phase == 5, s.pin, s.accounted, s.work == 0,
    s' = { ...s, phase: 6, pin: false } }
  action prepareTransfer = all { s.joined, s.frozen, not(s.pin), not(s.exclusive),
    s.owner == 1, s.transfer == 0, (s.phase == 0 or s.phase == 6),
    s' = { ...s, exclusive: true, transfer: 1 } }
  // All list links/counters precede this abstract commit; readers cannot observe the interval.
  action commitTransfer = all { s.exclusive, not(s.pin), s.transfer == 1,
    s' = { ...s, owner: 0, revision: s.revision + 1, exclusive: false,
      transfer: 2, receiptSeen: false } }
  action abortPrepared = all { s.exclusive, s.transfer == 1, s.owner == 1,
    s' = { ...s, transfer: 0, exclusive: false } }
  action resolveCommitted = all { s.transfer == 2, s.owner == 0,
    s' = { ...s, receiptSeen: true } }
  action cleanupDonor = all { s.joined, s.transfer == 2, s.receiptSeen,
    s.owner == 0, not(s.pin), not(s.exclusive), (s.phase == 0 or s.phase == 6),
    s' = { ...s, donorAlive: false } }
  action step = any { freezeWriters, retire, joinFailed, joinUnknown, joinSuccess,
    quarantineUnknown, beginGC, prepareStill, scanRoots, drainTrace, weakComplete,
    cleanupAccount, finishGC, prepareTransfer, commitTransfer, abortPrepared,
    resolveCommitted, cleanupDonor }
  action badForgetDomain = s' = { ...s, registered: false }
  action badUseDonorExecutor = s' = { ...s, executor: 1 }
  action badConcurrentSplice = s' = { ...s, owner: 0, revision: s.revision + 1 }
  action badEarlyUnpin = s' = { ...s, pin: false }
  action badSkipStill = s' = { ...s, phase: 3, rootEpoch: s.gcEpoch }
  action badSkipAccounting = s' = { ...s, phase: 6, pin: false }
  action badFalseJoinSuccess = s' = { ...s, joinOutcome: 1, joined: true }
  action badFreeDonor = s' = { ...s, donorAlive: false }
  action badReuseGeneration = s' = { ...s, revision: s.revision + 1 }
  run failedJoinProxyScanTest = init.then(freezeWriters).then(retire).then(joinFailed)
    .then(beginGC).then(prepareStill).then(scanRoots).then(drainTrace).then(weakComplete)
    .then(cleanupAccount).then(finishGC).expect(safe and s.owner == 1 and s.donorAlive)
  run nextEpochRescansTest = init.then(freezeWriters).then(retire).then(joinUnknown)
    .then(beginGC).then(prepareStill).then(scanRoots).then(drainTrace).then(weakComplete)
    .then(cleanupAccount).then(finishGC).then(beginGC).then(prepareStill).then(scanRoots)
    .expect(safe and s.rootEpoch == 2 and s.executor == 0)
  run unknownWithoutFreezeQuarantineTest = init.then(quarantineUnknown)
    .expect(safe and s.intakeClosed and s.phase == 0)
  run committedReceiptLostTest = init.then(freezeWriters).then(retire).then(joinSuccess)
    .then(prepareTransfer).then(commitTransfer).expect(safe and not(s.receiptSeen) and s.owner == 0)
  run resolveBeforeCleanupTest = init.then(freezeWriters).then(retire).then(joinSuccess)
    .then(prepareTransfer).then(commitTransfer).then(resolveCommitted).then(cleanupDonor)
    .then(beginGC).then(prepareStill).then(scanRoots).expect(safe and not(s.donorAlive))
  run precommitAbortTest = init.then(freezeWriters).then(retire).then(joinSuccess)
    .then(prepareTransfer).then(abortPrepared).then(beginGC).expect(safe and s.owner == 1)
  run missingEnrollmentControlTest = init.then(freezeWriters).then(retire).then(joinFailed)
    .then(badForgetDomain).expect(not(safe))
  run retiredExecutorControlTest = init.then(freezeWriters).then(retire).then(beginGC)
    .then(badUseDonorExecutor).expect(not(safe))
  run mutexOnlySpliceControlTest = init.then(freezeWriters).then(retire).then(beginGC)
    .then(badConcurrentSplice).expect(not(safe))
  run earlyUnpinControlTest = init.then(freezeWriters).then(retire).then(beginGC)
    .then(prepareStill).then(scanRoots).then(badEarlyUnpin).expect(not(safe))
  run missingStillSetupControlTest = init.then(freezeWriters).then(retire).then(beginGC)
    .then(badSkipStill).expect(not(safe))
  run missingAccountingControlTest = init.then(freezeWriters).then(retire).then(beginGC)
    .then(prepareStill).then(scanRoots).then(drainTrace).then(weakComplete)
    .then(badSkipAccounting).expect(not(safe))
  run failedJoinIsNotStoppedControlTest = init.then(freezeWriters).then(retire).then(joinFailed)
    .then(badFalseJoinSuccess).expect(not(safe))
  run retainedHeaderFreeControlTest = init.then(freezeWriters).then(retire).then(joinUnknown)
    .then(badFreeDonor).expect(not(safe))
  run snapshotAbaControlTest = init.then(freezeWriters).then(retire).then(beginGC)
    .then(badReuseGeneration).expect(not(safe))
}
