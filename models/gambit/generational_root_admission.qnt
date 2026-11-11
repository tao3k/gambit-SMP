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
  val oldTargets = oldSlots.map(i => s.slots.get(i)).exclude(Set(-1))
  val liveYoung = closure(oldTargets.union(if (s.rc >= 0) Set(s.rc) else Set()))
  val selected = if (s.fallback) oldSlots else s.dirty
  val selectedTargets = selected.map(i => s.slots.get(i)).exclude(Set(-1))
  val covered = oldSlots.filter(i => s.slots.get(i) >= 0).subseteq(selected)
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
  action scanOld = all { s.pinned, selected.exclude(s.scanned).size() > 0,
    nondet i = selected.exclude(s.scanned).oneOf()
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
