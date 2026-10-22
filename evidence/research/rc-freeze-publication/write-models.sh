#!/bin/bash
set -euo pipefail
cat > models/gambit/rc_freeze_publication.qnt <<'EOF'
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
    (not(s.freed) or (not(s.pin) and s.callbacks.size() == 0 and not(s.queued)))
  action prepare = all { not(s.initialized), s' = { ...s, initialized: true, reserved: true } }
  action publish = all { s.initialized, not(s.published), s' = { ...s, published: true } }
  action enter = all { not(s.closed), not(s.deleteRequested), not(s.freed), not(s.callbacks.contains(0)),
    s' = { ...s, callbacks: s.callbacks.union(Set(0)), raw: s.raw.union(Set(0)) } }
  action nestedEnter = all { not(s.closed), not(s.deleteRequested), s.callbacks.contains(0),
    not(s.callbacks.contains(1)), s' = { ...s, callbacks: s.callbacks.union(Set(1)), raw: s.raw.union(Set(1)) } }
  action beginWrite = all { not(s.closed), s.writers == 0, not(s.freed),
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
    s' = { ...s, callbacks: s.callbacks.exclude(1), raw: s.raw.exclude(1) } }
  action leave = all { s.callbacks == Set(0),
    s' = { ...s, callbacks: Set(), raw: Set() } }
  action finishCleanup = all { s.queued, not(s.pin), s.callbacks.size() == 0,
    s' = { ...s, queued: false } }
  action free = all { s.deleteRequested, not(s.pin), not(s.queued), s.callbacks.size() == 0,
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
EOF
cat > models/gambit/generational_root_admission.qnt <<'EOF'
module generational_root_admission {
  // Two young nodes 0 -> 1; old slots: captured frame, denv, still, promoted object.
  // RC slots are explicit roots scanned every minor, never inferred from old age.
  type State = { slots: int -> int, rc: int, registered: bool, dirty: Set[int],
    fallback: bool, closed: bool, known: bool, pinned: bool, scanned: Set[int],
    rcScanned: bool, promoted: Set[int], finished: bool, mutatorRunning: bool }
  var s: State
  val oldSlots = Set(0, 1, 2, 3)
  pure def closure(xs: Set[int]): Set[int] =
    if (xs.contains(0)) xs.union(Set(1)) else xs
  val oldTargets = oldSlots.map(i => s.slots.get(i)).exclude(-1)
  val liveYoung = closure(oldTargets.union(if (s.rc >= 0) Set(s.rc) else Set()))
  val selected = if (s.fallback) oldSlots else s.dirty
  val selectedTargets = selected.map(i => s.slots.get(i)).exclude(-1)
  val covered = liveYoung.subseteq(closure(selectedTargets.union(if (s.registered and s.rc >= 0) Set(s.rc) else Set())))
  val safe = (not(s.pinned) or (s.closed and s.known and not(s.mutatorRunning) and s.registered and covered)) and
    (not(s.finished) or (liveYoung.subseteq(s.promoted) and not(s.pinned) and s.rcScanned))
  action init = s' = { slots: Map(0 -> -1, 1 -> -1, 2 -> -1, 3 -> -1), rc: -1,
    registered: true, dirty: Set(), fallback: false, closed: false, known: true,
    pinned: false, scanned: Set(), rcScanned: false, promoted: Set(), finished: false,
    mutatorRunning: true }
  action mutate = all { not(s.closed), not(s.finished),
    nondet i = oldSlots.oneOf()
    nondet target = Set(0, 1).oneOf()
    s' = { ...s, slots: s.slots.set(i, target), dirty: s.dirty.union(Set(i)) } }
  action rcWrite = all { not(s.closed), not(s.finished),
    s' = { ...s, rc: 0 } }
  // A full log falls back BEFORE the heap write; neither store nor overflow collects.
  action overflowStore = all { not(s.closed), not(s.finished),
    s' = { ...s, slots: s.slots.set(3, 0), fallback: true } }
  action close = all { not(s.closed), s' = { ...s, closed: true, mutatorRunning: false } }
  action pin = all { s.closed, s.known, s.registered, covered, not(s.finished),
    s' = { ...s, pinned: true } }
  action scanOld = all { s.pinned, not(selected.diff(s.scanned).isEmpty()),
    nondet i = selected.diff(s.scanned).oneOf()
    s' = { ...s, scanned: s.scanned.union(Set(i)),
      promoted: s.promoted.union(closure(if (s.slots.get(i) >= 0) Set(s.slots.get(i)) else Set())) } }
  action scanRC = all { s.pinned, s.registered, not(s.rcScanned),
    s' = { ...s, rcScanned: true,
      promoted: s.promoted.union(closure(if (s.rc >= 0) Set(s.rc) else Set())) } }
  action finish = all { s.pinned, selected.subseteq(s.scanned), s.rcScanned,
    s' = { ...s, finished: true, pinned: false } }
  action step = any { mutate, rcWrite, overflowStore, close, pin, scanOld, scanRC, finish }
  action badDirectStore = s' = { ...s, slots: s.slots.set(0, 0) }
  action rawEscape = s' = { ...s, known: false }
  action badPin = s' = { ...s, pinned: true }
  action badDropRC = s' = { ...s, registered: false }
  action badClearDirty = s' = { ...s, dirty: Set(), fallback: false }
  action badFinish = s' = { ...s, finished: true, pinned: false, rcScanned: true }
  run rememberedFrameTest = init.then(mutate).then(close).then(pin).then(scanOld).then(scanRC).then(finish).expect(safe)
  run registeredRCTest = init.then(rcWrite).then(close).then(pin).then(scanRC).then(finish).expect(safe and s.promoted == Set(0, 1))
  run overflowFallbackTest = init.then(overflowStore).then(close).then(pin)
    .then(scanOld).then(scanOld).then(scanOld).then(scanOld).then(scanRC).then(finish).expect(safe)
  run cleanMatureSkipTest = init.then(close).then(pin).then(scanRC).then(finish).expect(safe and s.scanned.size() == 0)
  run unbarrieredFrameControlTest = init.then(badDirectStore).then(close).then(badPin).expect(not(safe))
  run rawEscapeControlTest = init.then(close).then(rawEscape).then(badPin).expect(not(safe))
  run unregisteredRCControlTest = init.then(rcWrite).then(close).then(badDropRC).then(badPin).expect(not(safe))
  run earlyDirtyClearControlTest = init.then(overflowStore).then(close).then(pin).then(badClearDirty).expect(not(safe))
  run skippedDescendantControlTest = init.then(rcWrite).then(close).then(pin).then(badFinish).expect(not(safe))
}
EOF
