module rc_freeze_publication {
  // Target protocol: native storage leases are not raw Scheme-value borrows.
  type State = { initialized: bool, published: bool, executor: bool, closed: bool,
    known: bool, writers: int, callbacks: Set[int], raw: Set[int], receipt: bool,
    generation: int, receiptGeneration: int, revision: int, receiptRevision: int,
    pin: bool, rootVersion: int, deleteRequested: bool, reserved: bool,
    queued: bool, nativeOnly: bool, waitsTask: bool, deleteWaitsSelf: bool, freed: bool }
  var s: State
  action init = s' = { initialized: false, published: false, executor: true,
    closed: false, known: true, writers: 0, callbacks: Set(), raw: Set(),
    receipt: false, generation: 1, receiptGeneration: 0, revision: 1,
    receiptRevision: 0, pin: false, rootVersion: 0, deleteRequested: false,
    reserved: false, queued: false, nativeOnly: true, waitsTask: false,
    deleteWaitsSelf: false, freed: false }
  val frozen = s.closed and s.known and s.writers == 0 and s.raw.size() == 0
  val current = s.receiptGeneration == s.generation and s.receiptRevision == s.revision
  val safe = (not(s.published) or s.initialized) and
    (s.executor or s.published) and
    (not(s.receipt) or (frozen and current and s.published)) and
    (not(s.pin) or (s.receipt and not(s.freed))) and
    s.raw.subseteq(s.callbacks) and
    (not(s.queued) or (s.reserved and s.nativeOnly)) and
    not(s.waitsTask and s.pin and s.queued) and not(s.deleteWaitsSelf) and
    (not(s.freed) or (not(s.pin) and s.writers == 0 and s.raw.size() == 0 and s.callbacks.size() == 0 and not(s.queued)))
  action prepare = all { not(s.initialized), not(s.freed), s' = { ...s, initialized: true, reserved: true } }
  action publish = all { s.initialized, not(s.freed), not(s.published), s' = { ...s, published: true } }
  action enter = all { s.published, not(s.closed), not(s.deleteRequested), not(s.freed), not(s.callbacks.contains(0)),
    s' = { ...s, callbacks: s.callbacks.union(Set(0)), raw: s.raw.union(Set(0)) } }
  action nestedEnter = all { not(s.closed), not(s.deleteRequested), s.callbacks.contains(0),
    not(s.callbacks.contains(1)), s' = { ...s, callbacks: s.callbacks.union(Set(1)), raw: s.raw.union(Set(1)) } }
  action beginWrite = all { s.initialized, not(s.closed), s.writers == 0, not(s.freed),
    s' = { ...s, writers: 1 } }
  action finishWrite = all { s.writers == 1,
    s' = { ...s, writers: 0, rootVersion: s.rootVersion + 1 } }
  action close = all { not(s.closed), s' = { ...s, closed: true } }
  action park = all { s.closed, s' = { ...s, raw: Set() } }
  action issue = all { frozen, s.published, not(s.freed),
    s' = { ...s, receipt: true, receiptGeneration: s.generation, receiptRevision: s.revision } }
  action removeExecutor = all { s.receipt, current, s.published,
    s' = { ...s, executor: false } }
  action pin = all { s.receipt, current, not(s.pin), not(s.freed), s' = { ...s, pin: true } }
  // Collector authority bypasses the CLOSED mutator gate, not root registration.
  action relocate = all { s.pin, s.raw.size() == 0, s' = { ...s, rootVersion: s.rootVersion + 1 } }
  action requestDelete = s' = { ...s, deleteRequested: true }
  action enqueueCleanup = all { s.pin, s.reserved, s.nativeOnly, not(s.queued),
    s' = { ...s, queued: true } }
  action endGC = all { s.pin, not(s.waitsTask), s' = { ...s, pin: false } }
  action reopen = all { not(s.pin), s.executor, not(s.deleteRequested),
    s' = { ...s, closed: false, receipt: false } }
  action reload = all { not(s.closed), not(s.pin), s.callbacks.size() > 0,
    s' = { ...s, raw: s.callbacks } }
  action leaveNested = all { s.callbacks.contains(1),
    s' = { ...s, callbacks: s.callbacks.exclude(Set(1)), raw: s.raw.exclude(Set(1)) } }
  action leave = all { s.callbacks == Set(0),
    s' = { ...s, callbacks: Set(), raw: Set() } }
  action finishCleanup = all { s.queued, not(s.pin), s.callbacks.size() == 0,
    s' = { ...s, queued: false } }
  action free = all { s.initialized, frozen, s.deleteRequested, not(s.pin), not(s.queued), s.callbacks.size() == 0,
    s' = { ...s, freed: true } }
  action step = any { prepare, publish, enter, nestedEnter, beginWrite, finishWrite,
    close, park, issue, removeExecutor, pin, relocate, requestDelete, enqueueCleanup,
    endGC, reopen, reload, leaveNested, leave, finishCleanup, free }
  action badPublish = s' = { ...s, published: true }
  action badRemove = s' = { ...s, executor: false }
  action badIssue = s' = { ...s, receipt: true, receiptGeneration: s.generation, receiptRevision: s.revision }
  action escape = s' = { ...s, known: false }
  action badABA = s' = { ...s, generation: s.generation + 1 }
  action badFree = s' = { ...s, freed: true }
  action badWaitTask = s' = { ...s, waitsTask: true }
  action badDeleteWait = s' = { ...s, deleteWaitsSelf: true }
  action badLateManagedRoot = s' = { ...s, nativeOnly: false }
  run callbackCanParkThroughGCTest = init.then(prepare).then(publish).then(enter)
    .then(close).then(park).then(issue).then(pin).then(relocate).then(endGC)
    .then(reopen).then(reload).then(leave).expect(safe and s.rootVersion == 1)
  run nestedDeleteDrainsTest = init.then(prepare).then(publish).then(enter).then(nestedEnter)
    .then(requestDelete).then(close).then(park).then(issue).then(pin).then(enqueueCleanup)
    .then(endGC).then(leaveNested).then(leave).then(finishCleanup).then(free).expect(safe)
  run finalWriterBeforeIssueTest = init.then(prepare).then(publish).then(beginWrite)
    .then(close).then(finishWrite).then(issue).then(removeExecutor).then(pin).expect(safe)
  run earlyPublicationControlTest = init.then(badPublish).expect(not(safe))
  run earlyRemovalControlTest = init.then(badRemove).expect(not(safe))
  run rawBorrowControlTest = init.then(prepare).then(publish).then(enter).then(close)
    .then(badIssue).expect(not(safe))
  run writerControlTest = init.then(prepare).then(publish).then(beginWrite).then(close)
    .then(badIssue).expect(not(safe))
  run unknownWriterControlTest = init.then(prepare).then(publish).then(close).then(escape)
    .then(badIssue).expect(not(safe))
  run staleGenerationControlTest = init.then(prepare).then(publish).then(close).then(issue)
    .then(badABA).expect(not(safe))
  run pinFreeControlTest = init.then(prepare).then(publish).then(close).then(issue).then(pin)
    .then(badFree).expect(not(safe))
  run cleanupWaitCycleControlTest = init.then(prepare).then(publish).then(close).then(issue)
    .then(pin).then(enqueueCleanup).then(badWaitTask).expect(not(safe))
  run selfDeleteWaitControlTest = init.then(prepare).then(publish).then(enter)
    .then(requestDelete).then(badDeleteWait).expect(not(safe))
  run lateManagedPayloadControlTest = init.then(prepare).then(publish).then(close).then(issue)
    .then(pin).then(enqueueCleanup).then(badLateManagedRoot).expect(not(safe))
}
