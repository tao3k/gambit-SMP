module synchronous_publication {
  // TARGET component model, not current native GC, C weak memory or a heap layout.
  // Four selected sites; owner 0 = movable, owner 1 = captured frame.
  // mode 0: split + explicit P; 1: fused + explicit P; 2: fused + enclosing R.
  // fault 1: erased-P escape; 2: residual debt dropped; 3: return before notify;
  // fault 4: fuse uninitialized prefix. Faults are design controls, not native bugs.
  val Sites = Set(0, 1, 2, 3)
  val Workers = Set(0, 1)
  pure def owner(i: int): int = if (i < 2) 0 else 1
  type State = { mode: int, fault: int, stage: int -> int,
    ready: int -> bool, pub: int -> bool, unknown: int -> bool,
    notified: int -> bool, returned: int -> bool, residual: int -> bool,
    localDone: int -> bool, retained: int -> bool, receiver: int -> bool,
    busy: int -> int, awake: int -> bool, scanOwner: int -> int, count: int,
    sealed: bool, closed: bool, issued: int, settled: int, refunded: int,
    gates: int, queues: int }
  // stage 0 unused; 1 private; 2 reserved; 3 queued; 4 scanning;
  // 5 scan settled; 7 local/bypass. Work state and receipt state are orthogonal.
  var s: State
  pure def initial(mode: int, fault: int): State = {
    mode: mode, fault: fault, stage: Sites.mapBy(_ => 0),
    ready: Sites.mapBy(_ => false), pub: Sites.mapBy(_ => false),
    unknown: Sites.mapBy(_ => false), notified: Sites.mapBy(_ => true),
    returned: Sites.mapBy(_ => false), residual: Sites.mapBy(_ => false),
    localDone: Sites.mapBy(_ => false), retained: Sites.mapBy(_ => true),
    receiver: Sites.mapBy(_ => false), busy: Workers.mapBy(_ => -1),
    awake: Workers.mapBy(_ => true), scanOwner: Sites.mapBy(_ => -1), count: 2, sealed: false, closed: false,
    issued: 0, settled: 0, refunded: 0, gates: 0, queues: 0 }
  action init = s' = initial(2, 0)
  action initReference = s' = initial(0, 0)
  action initFusedExplicit = s' = initial(1, 0)
  action initEscape = s' = initial(2, 1)
  action initResidual = s' = initial(2, 2)
  action initEarlyReturn = s' = initial(2, 3)
  action initUnready = s' = initial(2, 4)
  def unfinished: int = Sites.filter(i => Set(2, 3, 4).contains(s.stage.get(i))).size()
  def receipts: int = Sites.filter(i => s.pub.get(i)).size()
  def enclosing(i: int): bool = s.awake.get(owner(i)) and s.busy.get(owner(i)) == i
  def beginEnabled(i: int): bool = not(s.closed) and not(s.sealed) and
    s.stage.get(i) == 0 and s.awake.get(owner(i)) and s.busy.get(owner(i)) == -1
  action begin(i: int): bool = all { beginEnabled(i),
    s' = { ...s, stage: s.stage.set(i, 1), residual: s.residual.set(i, true),
      busy: s.busy.set(owner(i), i) } }
  action prepare(i: int): bool = all { s.stage.get(i) == 1, enclosing(i), not(s.ready.get(i)),
    s' = { ...s, ready: s.ready.set(i, true) } }
  action reserve(i: int): bool = all { s.mode == 0, not(s.closed),
    s.stage.get(i) == 1, s.ready.get(i), enclosing(i), not(s.pub.get(i)),
    s' = { ...s, stage: s.stage.set(i, 2), pub: s.pub.set(i, true),
      issued: s.issued + 1, gates: s.gates + 1 } }
  action commit(i: int): bool = all { s.mode == 0, not(s.closed),
    s.stage.get(i) == 2, s.ready.get(i), enclosing(i), not(s.unknown.get(i)),
    s' = { ...s, stage: s.stage.set(i, 3), notified: s.notified.set(i, false),
      gates: s.gates + 1, queues: s.queues + 1 } }
  action fused(i: int): bool = all { s.mode > 0, not(s.closed),
    s.stage.get(i) == 1, (s.ready.get(i) or s.fault == 4), enclosing(i),
    s' = { ...s, stage: s.stage.set(i, 3), pub: s.pub.set(i, true),
      notified: s.notified.set(i, false), issued: s.issued + 1,
      gates: s.gates + 1, queues: s.queues + 1 } }
  action notify(i: int): bool = all { Set(3, 4, 5).contains(s.stage.get(i)),
    not(s.notified.get(i)), not(s.closed),
    s' = { ...s, notified: s.notified.set(i, true) } }
  action acquire(i: int, w: int): bool = all { s.stage.get(i) == 3,
    not(s.closed), s.awake.get(w), s.ready.get(i),
    s' = { ...s, stage: s.stage.set(i, 4), scanOwner: s.scanOwner.set(i, w),
      gates: s.gates + 1, queues: s.queues + 1 } }
  action finishScan(i: int): bool = all { s.stage.get(i) == 4, not(s.closed),
    s' = { ...s, stage: s.stage.set(i, 5), settled: s.settled + 1, gates: s.gates + 1 } }
  action returnPublisher(i: int): bool = all {
    Set(3, 4, 5).contains(s.stage.get(i)), s.pub.get(i), not(s.unknown.get(i)),
    (s.notified.get(i) or s.fault == 3), enclosing(i),
    s' = { ...s, pub: s.pub.set(i, false), returned: s.returned.set(i, true),
      gates: s.gates + (if (s.mode == 2) 0 else 1) } }
  action bypass(i: int): bool = all { s.stage.get(i) == 1, enclosing(i),
    s' = { ...s, stage: s.stage.set(i, 7), returned: s.returned.set(i, true) } }
  action scanLocal(i: int): bool = all { s.stage.get(i) == 7, enclosing(i),
    not(s.localDone.get(i)), s' = { ...s, localDone: s.localDone.set(i, true) } }
  action drainCaller(i: int): bool = all { enclosing(i), s.returned.get(i),
    not(s.unknown.get(i)), s.stage.get(i) != 7 or s.localDone.get(i),
    s' = { ...s, residual: s.residual.set(i, false), busy: s.busy.set(owner(i), -1) } }
  action loseOutcome(i: int): bool = all { Set(2, 3, 4, 5).contains(s.stage.get(i)),
    s.pub.get(i), not(s.unknown.get(i)),
    s' = { ...s, unknown: s.unknown.set(i, true) } }
  action transferUnknown(i: int): bool = all { s.unknown.get(i), enclosing(i),
    Set(3, 4, 5).contains(s.stage.get(i)), s.mode != 2 or s.fault == 1,
    s' = { ...s, receiver: s.receiver.set(i, true), residual: s.residual.set(i, false),
      busy: s.busy.set(owner(i), -1) } }
  action reconcileCommitted(i: int): bool = all { s.unknown.get(i),
    Set(3, 4, 5).contains(s.stage.get(i)), s.notified.get(i),
    s.retained.get(i), s.receiver.get(i) or enclosing(i), not(s.closed),
    s' = { ...s, unknown: s.unknown.set(i, false), pub: s.pub.set(i, false),
      returned: s.returned.set(i, true), gates: s.gates + (if (s.mode == 2) 0 else 1) } }
  action rejectBeforeEffect(i: int): bool = all { s.stage.get(i) == 2, enclosing(i),
    s.pub.get(i), s.refunded < 1,
    s' = { ...s, stage: s.stage.set(i, 1), pub: s.pub.set(i, false),
      unknown: s.unknown.set(i, false), refunded: s.refunded + 1, gates: s.gates + 1 } }
  action dropResidual(i: int): bool = all { s.fault == 2, enclosing(i), s.returned.get(i),
    s' = { ...s, busy: s.busy.set(owner(i), -1) } }
  def idleEnabled(w: int): bool = s.awake.get(w) and s.busy.get(w) == -1 and
    Sites.forall(i => not(s.stage.get(i) == 4 and s.scanOwner.get(i) == w))
  action idle(w: int): bool = all { idleEnabled(w),
    s' = { ...s, awake: s.awake.set(w, false), count: s.count - 1 } }
  action wake(w: int): bool = all { not(s.awake.get(w)), not(s.closed),
    s.count > 0 or unfinished > 0 or (s.mode != 2 and receipts > 0),
    s' = { ...s, awake: s.awake.set(w, true), count: s.count + 1 } }
  action seal = all { not(s.sealed), s' = { ...s, sealed: true } }
  def closeEnabled: bool = s.sealed and not(s.closed) and s.count == 0 and
    unfinished == 0 and (s.mode == 2 or receipts == 0)
  action close = all { closeEnabled, s' = { ...s, closed: true } }
  action stutter = s' = s
  action step = any {
    nondet i = Sites.oneOf()
    any { begin(i), prepare(i), reserve(i), commit(i), fused(i), notify(i),
      finishScan(i), returnPublisher(i), bypass(i), scanLocal(i), drainCaller(i),
      loseOutcome(i), transferUnknown(i), reconcileCommitted(i), rejectBeforeEffect(i), dropResidual(i),
      nondet w = Workers.oneOf()
      any { acquire(i, w), idle(w), wake(w) } },
    seal, close, stutter }
  val accounting = s.issued == unfinished + s.settled + s.refunded and
    s.count == Workers.filter(w => s.awake.get(w)).size()
  val readyBeforeScan = Sites.forall(i => not(Set(3, 4, 5).contains(s.stage.get(i))) or s.ready.get(i))
  val producerCoverage = s.mode != 2 or Sites.forall(i => not(s.pub.get(i)) or enclosing(i))
  val closedSafe = not(s.closed) or Sites.forall(i => not(s.pub.get(i)) and
    not(s.unknown.get(i)) and not(s.residual.get(i)) and s.notified.get(i))
  val safe = accounting and readyBeforeScan and producerCoverage and closedSafe
  run finishOne(i: int): bool = notify(i).then(acquire(i, 0)).then(finishScan(i))
    .then(returnPublisher(i)).then(drainCaller(i))
  run allFourFusedTest = init.then(begin(0)).then(prepare(0)).then(fused(0)).then(finishOne(0))
    .then(begin(1)).then(prepare(1)).then(fused(1)).then(finishOne(1))
    .then(begin(2)).then(prepare(2)).then(fused(2)).then(finishOne(2))
    .then(begin(3)).then(prepare(3)).then(fused(3)).then(finishOne(3))
    .then(seal).then(idle(0)).then(idle(1)).then(close)
    .expect(safe and s.closed and s.gates == 12 and s.queues == 8)
  run referenceCostTest = initReference.then(begin(0)).then(prepare(0)).then(reserve(0)).then(commit(0))
    .then(finishOne(0)).expect(safe and s.gates == 5 and s.queues == 2)
  run fusedExplicitCostTest = initFusedExplicit.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(finishOne(0)).expect(safe and s.gates == 4 and s.queues == 2)
  run notifyLastUseTest = init.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(acquire(0, 1)).then(finishScan(0))
    .expect(safe and not(idleEnabled(0)) and not(s.notified.get(0)))
  run callerResidualTest = init.then(begin(2)).then(prepare(2)).then(fused(2))
    .then(notify(2)).then(returnPublisher(2)).expect(safe and not(idleEnabled(1)) and s.residual.get(2))
  run unknownRetainedTest = initFusedExplicit.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(notify(0)).then(acquire(0, 1)).then(finishScan(0)).then(loseOutcome(0))
    .then(transferUnknown(0)).then(seal).then(idle(0)).then(idle(1))
    .expect(safe and not(closeEnabled) and unfinished == 0 and receipts == 1)
  run unknownReconciledTest = initFusedExplicit.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(notify(0)).then(acquire(0, 1)).then(finishScan(0)).then(loseOutcome(0))
    .then(transferUnknown(0)).then(seal).then(idle(0)).then(idle(1))
    .then(reconcileCommitted(0)).then(close).expect(safe and s.closed)
  run erasedUnknownKeepsIssuerTest = init.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(loseOutcome(0)).expect(safe and enclosing(0) and not(idleEnabled(0)))
  run rejectRestoresPrivateTest = initReference.then(begin(0)).then(prepare(0)).then(reserve(0))
    .then(loseOutcome(0)).then(rejectBeforeEffect(0))
    .expect(safe and s.stage.get(0) == 1 and enclosing(0) and s.refunded == 1)
  run localBypassTest = init.then(begin(3)).then(bypass(3)).then(scanLocal(3)).then(drainCaller(3))
    .then(seal).then(idle(0)).then(idle(1)).then(close).expect(safe and s.gates == 0)
  run resumeBeforeWorkTest = init.then(seal).then(idle(0)).then(wake(0))
    .expect(safe and s.count == 2)
  run escapedErasureCounterexampleTest = initEscape.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(notify(0)).then(acquire(0, 1)).then(finishScan(0)).then(loseOutcome(0))
    .then(transferUnknown(0)).then(seal).then(idle(0)).then(idle(1)).then(close)
    .expect(not(safe) and s.closed and receipts == 1)
  run residualCounterexampleTest = initResidual.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(notify(0)).then(acquire(0, 1)).then(finishScan(0)).then(returnPublisher(0))
    .then(dropResidual(0)).then(seal).then(idle(0)).then(idle(1)).then(close)
    .expect(not(closedSafe) and s.residual.get(0))
  run earlyReturnCounterexampleTest = initEarlyReturn.then(begin(0)).then(prepare(0)).then(fused(0))
    .then(acquire(0, 1)).then(finishScan(0)).then(returnPublisher(0)).then(drainCaller(0))
    .then(seal).then(idle(0)).then(idle(1)).then(close)
    .expect(not(closedSafe) and not(s.notified.get(0)))
  run unreadyFusionCounterexampleTest = initUnready.then(begin(2)).then(fused(2))
    .expect(not(readyBeforeScan))
}
