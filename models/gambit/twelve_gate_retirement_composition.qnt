module twelve_gate_retirement_composition {
  // One retiring cohort A and one independent VM B; post-exit entry only.
  // Readers are actual admitted users, not a census of undelivered OS signals.
  // p=0 correct, 1 early release, 2 root gap, 3 hidden producer,
  // 4 terminal error mislabeled as successful recovery.
  type State = { p: int, fault: bool, phase: int, open: bool,
    reader: bool, producer: bool, work: bool, sourceRoot: bool,
    targetRoot: bool, live: bool, claimed: bool, b: int }
  var s: State
  pure def initial(p: int, fault: bool): State = {
    p: p, fault: fault, phase: 0, open: true, reader: true,
    producer: true, work: false, sourceRoot: true,
    targetRoot: false, live: true, claimed: false, b: 0 }
  action initNormal = s' = initial(0, false)
  action initTerminal = s' = initial(0, true)
  action initEarlyRelease = s' = initial(1, false)
  action initRootGap = s' = initial(2, false)
  action initHiddenProducer = s' = initial(3, false)
  action initFalseRecovery = s' = initial(4, true)
  action seal = all { s.open, s' = { ...s, open: false } }
  action readerReturn = all { s.reader, s' = { ...s, reader: false } }
  action readmit = all { s.open, not(s.reader), s' = { ...s, reader: true } }
  // Finishing allocation/orphaning can publish work after an empty snapshot.
  action finishProducer = all { s.producer,
    s' = { ...s, producer: false, work: true } }
  action drain = all { s.work, s' = { ...s, work: false } }
  // targetRoot means observed registration, not just a release store.
  action publishRoot = all { not(s.targetRoot), s.sourceRoot,
    s' = { ...s, targetRoot: true } }
  action dropRoot = all { s.sourceRoot, s.targetRoot or s.p == 2,
    s' = { ...s, sourceRoot: false } }
  action join = all { s.phase == 0, not(s.fault),
    s' = { ...s, phase: 1 } }
  action joinError = all { s.phase == 0, s.fault,
    s' = { ...s, phase: 2, claimed: s.p == 4 } }
  val cut = not(s.open) and not(s.reader) and not(s.producer) and
    not(s.work) and s.targetRoot
  action transfer = all { s.phase == 1,
    cut or s.p == 1 or (s.p == 3 and not(s.open) and not(s.reader)
      and not(s.work) and s.targetRoot),
    s' = { ...s, phase: 3 } }
  action release = all { s.phase == 3, s.live,
    s' = { ...s, phase: 4, live: false } }
  // B has separate state: retirement/retained errors on A cannot gate B.
  action otherVM = all { s.b < 2, s' = { ...s, b: s.b + 1 } }
  val terminal = (s.phase == 4 or s.phase == 2) and not(s.open)
    and not(s.reader) and not(s.producer) and not(s.work) and s.b == 2
  action done = all { terminal, s' = s }
  action step = any { seal, readerReturn, readmit, finishProducer, drain,
    publishRoot, dropRoot, join, joinError, transfer, release, otherVM, done }
  val rootCoverage = s.sourceRoot or s.targetRoot
  val noUseAfterFree = s.live or (not(s.reader) and not(s.producer) and not(s.work))
  val transferClosed = s.phase < 3 or cut
  val retainedIsNotSuccess = s.phase != 2 or (s.live and not(s.claimed))
  val safe = rootCoverage and noUseAfterFree and transferClosed and retainedIsNotSuccess
  temporal completion = weakFair(seal, Set(s))
    .and(weakFair(readerReturn, Set(s)))
    .and(weakFair(finishProducer, Set(s)))
    .and(weakFair(drain, Set(s)))
    .and(weakFair(publishRoot, Set(s)))
    .and(weakFair(join, Set(s)))
    .and(weakFair(joinError, Set(s)))
    .and(weakFair(transfer, Set(s)))
    .and(weakFair(release, Set(s)))
    .and(weakFair(otherVM, Set(s)))
    .implies(eventually(terminal))
  run errorRetainsAWhileBCompletes = initTerminal.then(joinError)
    .then(otherVM).then(otherVM)
    .expect(s.phase == 2 and s.live and not(s.claimed) and s.b == 2 and safe)
  run emptySnapshotIsNotClosure = initNormal.then(seal).then(readerReturn)
    .then(join).then(publishRoot)
    .expect(not(s.work) and s.producer and not(cut))
    .then(finishProducer).expect(s.work and not(cut))
    .then(drain).then(transfer).then(release).expect(safe and not(s.live))
}
