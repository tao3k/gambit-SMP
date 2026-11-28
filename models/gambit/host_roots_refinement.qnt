module host_roots_refinement {
  // Target protocol and deliberately faulty controls; not C execution traces.
  // Epoch is an object-location generation, not an address or object identity.
  type State = { rcOwner: int, scan: Set[int], retained: bool,
    epoch: int, rootEpoch: int, localEpoch: int, protected: bool,
    slotOwner: int, frames: List[int], markers: Set[int], count: int,
    binding: int, priorBindings: List[int], nextId: int }
  var s: State
  action init = s' = { rcOwner: 1, scan: Set(0), retained: true,
    epoch: 0, rootEpoch: 0, localEpoch: 0, protected: false,
    slotOwner: 0, frames: [], markers: Set(), count: 0,
    binding: 1, priorBindings: [], nextId: 1 }
  val rcCovered = s.scan.contains(s.rcOwner)
  val localCurrent = s.localEpoch == s.epoch
  val balanced = s.count == s.frames.length() and
    s.markers == s.frames.indices().map(i => s.frames[i]) and
    s.priorBindings.length() == s.frames.length()
  action scanNonzero = s' = { ...s, scan: s.scan.union(Set(1)) }
  // Unknown join keeps allocation custody; it does not itself enroll a scanner.
  action retireUnknown = s' = { ...s, scan: Set(0), retained: true }
  // Abstract atomic handoff: source must supply stop/drain and lock exclusion.
  action transferCommitted = all { s.retained,
    s' = { ...s, rcOwner: 0, scan: Set(0), retained: false } }
  action reserve = all { s.slotOwner == 0,
    s' = { ...s, slotOwner: s.nextId, protected: true, rootEpoch: s.localEpoch } }
  action allocateMoving = all { s.protected, s.slotOwner == s.nextId,
    s.rootEpoch == s.epoch,
    s' = { ...s, epoch: s.epoch + 1, rootEpoch: s.epoch + 1 } }
  action reload = all { s.protected, s.slotOwner == s.nextId,
    s' = { ...s, localEpoch: s.rootEpoch } }
  action releaseSlot = all { s.protected, localCurrent,
    s' = { ...s, slotOwner: 0, protected: false } }
  action scratchClobber = s' = { ...s, rootEpoch: -1, slotOwner: -1 }
  action preEntryMove = s' = { ...s, epoch: s.epoch + 1 }
  action allocationThrowCleanup = all { s.protected,
    s' = { ...s, slotOwner: 0, protected: false } }
  action enter = all { not(s.protected), localCurrent,
    s' = { ...s, frames: s.frames.append(s.nextId),
      markers: s.markers.union(Set(s.nextId)), count: s.count + 1,
      priorBindings: s.priorBindings.append(s.binding), nextId: s.nextId + 1 } }
  // Matched return and controlled rethrow both settle the top activation once.
  action settleTop = all { s.frames.length() > 0,
    s' = { ...s, frames: s.frames.slice(0, s.frames.length() - 1),
      markers: s.markers.exclude(Set(s.frames[s.frames.length() - 1])),
      count: s.count - 1,
      binding: s.priorBindings[s.priorBindings.length() - 1],
      priorBindings: s.priorBindings.slice(0, s.priorBindings.length() - 1) } }
  action wrongMarkerCleanup = all { s.frames.length() == 2,
    s' = { ...s, frames: s.frames.slice(0, 1), count: s.count - 1,
      markers: s.markers.exclude(Set(s.frames[0])),
      priorBindings: s.priorBindings.slice(0, 1) } }
  action bindingDrift = s' = { ...s, binding: 2 }
  action countOnlyExit = all { s.frames.length() > 0,
    s' = { ...s, frames: [], markers: Set(), count: 0, priorBindings: [] } }
  run missingNonzeroScanControlTest = init.expect(not(rcCovered))
  run activeNonzeroScanTest = init.then(scanNonzero).expect(rcCovered)
  run retainedDonorControlTest = init.then(scanNonzero).then(retireUnknown)
    .expect(s.retained and not(rcCovered))
  run receiverCommitTest = init.then(transferCommitted).expect(rcCovered and not(s.retained))
  run allocationReloadTest = init.then(reserve).then(allocateMoving).then(reload)
    .then(releaseSlot).then(enter).expect(localCurrent and balanced)
  run protectionWithoutReloadControlTest = init.then(reserve).then(allocateMoving)
    .expect(not(localCurrent) and s.protected)
  run fixedSlotClobberControlTest = init.then(reserve).then(scratchClobber)
    .expect(s.protected and s.rootEpoch != s.epoch and s.slotOwner != s.nextId)
  run lateProtectionControlTest = init.then(preEntryMove).then(reserve)
    .expect(s.protected and s.rootEpoch != s.epoch)
  run allocationThrowTest = init.then(reserve).then(allocateMoving).then(allocationThrowCleanup)
    .expect(not(s.protected) and s.slotOwner == 0 and balanced)
  run nestedMatchedReturnTest = init.then(enter).then(enter).then(settleTop)
    .expect(balanced and s.frames == [1] and s.markers == Set(1))
  run nestedRethrowDrainTest = init.then(enter).then(enter).then(settleTop).then(settleTop)
    .expect(balanced and s.count == 0 and s.binding == 1)
  run wrongMarkerControlTest = init.then(enter).then(enter).then(wrongMarkerCleanup)
    .expect(not(balanced))
  run countIsNotBindingControlTest = init.then(enter).then(bindingDrift).then(countOnlyExit)
    .expect(balanced and s.binding != 1)
  run bindingRestoreTest = init.then(enter).then(bindingDrift).then(settleTop)
    .expect(balanced and s.binding == 1)
}
