module promotion_interval_handoff {
  // Target kernel: offsets into ONE allocator-issued region [0,12), copied prefix
  // [0,6), guard [10,12), transferable suffix [6,10). Not a source allocator.
  type State = { phase: int, backed: bool, reserved: bool, workerOwns: bool,
    contextOwns: bool, forwarded: bool, ready: bool, scanDebt: bool,
    offered: bool, accepted: bool, committed: bool, ackKnown: bool,
    tx: int, cursor: int, layoutEpoch: int, offerEpoch: int,
    pins: Set[int], queued: Set[int], inFlight: Set[int], retired: bool,
    bankReset: bool, regionFreed: bool, payloadDead: bool, quarantined: bool }
  var s: State
  pure def fits(lo: int, hi: int, words: int): bool = lo >= 0 and lo <= hi and hi <= 12 and words <= hi-lo
  pure def phasePeak(pre: int, post: int): int = if (pre >= post) pre else post
  action init = s' = { phase: 0, backed: false, reserved: false, workerOwns: false,
    contextOwns: false, forwarded: false, ready: false, scanDebt: false,
    offered: false, accepted: false, committed: false, ackKnown: true,
    tx: 1, cursor: 6, layoutEpoch: 1, offerEpoch: 1,
    pins: Set(), queued: Set(), inFlight: Set(), retired: false,
    bankReset: false, regionFreed: false, payloadDead: false, quarantined: false }
  val safe = not(s.workerOwns and s.contextOwns) and
    (not(s.reserved) or (s.backed and fits(0,12,6))) and
    (not(s.forwarded) or (s.reserved and not(s.regionFreed))) and
    (not(s.offered) or (s.ready and not(s.scanDebt) and s.offerEpoch == s.layoutEpoch)) and
    (not(s.contextOwns) or (s.committed and s.accepted and not(s.workerOwns) and fits(6,10,3))) and
    s.cursor >= 6 and s.cursor <= 10 and
    s.queued.union(s.inFlight).subseteq(s.pins) and
    (not(s.bankReset) or (s.retired and s.pins.size()==0)) and
    (not(s.regionFreed) or (s.payloadDead and not(s.contextOwns) and not(s.workerOwns) and s.pins.size()==0)) and
    (not(s.quarantined) or (not(s.regionFreed) and not(s.contextOwns)))
  action backing = all { s.phase==0, s'={ ...s, backed:true, phase:1 } }
  action reserve = all { s.phase==1, s.backed, s'={ ...s, reserved:true, workerOwns:true, phase:2 } }
  action rejectReserve = all { s.phase<=1, not(s.forwarded), s'={ ...s, phase:8 } }
  action forward = all { s.phase==2, s.reserved, s'={ ...s, forwarded:true, scanDebt:true, phase:3 } }
  action completeCopy = all { s.phase==3, s'={ ...s, ready:true, scanDebt:false, phase:4 } }
  action offer = all { s.phase==4, s.workerOwns, s.ready, not(s.scanDebt),
    s'={ ...s, offered:true, phase:5 } }
  action accept = all { s.phase==5, s.offered, s'={ ...s, accepted:true } }
  action rejectTarget = all { s.phase==5, not(s.committed),
    s'={ ...s, offered:false, accepted:false, phase:4 } }
  // Single authoritative ownership commit. Lost acknowledgement never changes it.
  action commit = all { s.phase==5, s.accepted, s.offerEpoch==s.layoutEpoch,
    s'={ ...s, workerOwns:false, contextOwns:true, committed:true, ackKnown:false, phase:6 } }
  action readBack = all { s.phase==6, s.committed, s'={ ...s, ackKnown:true } }
  action contextAllocate = all { s.phase==6, s.contextOwns, s.ackKnown, s.cursor+1<=10,
    s'={ ...s, cursor:s.cursor+1 } }
  action pinRoot = all { not(s.retired), not(s.bankReset), not(s.regionFreed), s.pins.size()==0,
    s'={ ...s, pins:Set(0) } }
  // Under the lifecycle lock: child pin precedes parent release, even after retire.
  action deriveQueuedPin = all { s.pins.contains(0), not(s.pins.contains(1)),
    not(s.bankReset), s'={ ...s, pins:s.pins.union(Set(1)), queued:Set(1) } }
  action retire = all { not(s.retired), s'={ ...s, retired:true } }
  action dequeue = all { s.queued.contains(1), s'={ ...s, queued:Set(), inFlight:Set(1) } }
  action releaseRoot = all { s.pins.contains(0), s'={ ...s, pins:s.pins.exclude(Set(0)) } }
  action finishScan = all { s.inFlight.contains(1),
    s'={ ...s, inFlight:Set(), pins:s.pins.exclude(Set(1)) } }
  action resetBank = all { s.retired, s.pins.size()==0, s'={ ...s, bankReset:true } }
  action quarantine = all { s.forwarded, not(s.contextOwns),
    s'={ ...s, quarantined:true, phase:9 } }
  action stutter = s'=s
  action step = any {backing,reserve,rejectReserve,forward,completeCopy,offer,accept,
    rejectTarget,commit,readBack,contextAllocate,pinRoot,deriveQueuedPin,retire,
    dequeue,releaseRoot,finishScan,resetBank,quarantine,stutter}
  // Controls excluded from the transition relation.
  action badCounterOnlyReserve = s'={ ...s, reserved:true, workerOwns:true }
  action badDoubleOwner = s'={ ...s, contextOwns:true }
  action badEarlyOffer = s'={ ...s, offered:true }
  action badRollbackUnknown = s'={ ...s, workerOwns:true }
  action badStaleLayout = s'={ ...s, layoutEpoch:2 }
  action badDropQueuedPin = s'={ ...s, pins:Set() }
  action badDropInFlightPin = s'={ ...s, pins:Set() }
  action badResetWithReader = s'={ ...s, bankReset:true }
  action badFreeLiveRegion = s'={ ...s, regionFreed:true }
  action badNewPinAfterReset = s'={ ...s, pins:Set(0) }
  action copied = backing.then(reserve).then(forward).then(completeCopy)
  action transferred = copied.then(offer).then(accept).then(commit)
  run physicalExtentTest = init.then(backing).then(reserve).expect(safe)
  run counterOnlyControlTest = init.then(badCounterOnlyReserve).expect(not(safe))
  run fragmentationControlTest = init.expect(4+4>=6 and not(fits(0,4,6)) and not(fits(8,12,6)))
  run reserveFailureTest = init.then(backing).then(rejectReserve).expect(safe and not(s.forwarded))
  run tailTransferTest = init.then(transferred).then(readBack).then(contextAllocate).expect(safe and s.cursor==7)
  run targetRejectTest = init.then(copied).then(offer).then(rejectTarget).expect(safe and s.workerOwns)
  run lostAckTest = init.then(transferred).expect(safe and s.contextOwns and not(s.ackKnown))
  run unknownRollbackControlTest = init.then(transferred).then(badRollbackUnknown).expect(not(safe))
  run doubleOwnerControlTest = init.then(copied).then(badDoubleOwner).expect(not(safe))
  run unfinishedOfferControlTest = init.then(backing).then(reserve).then(forward).then(badEarlyOffer).expect(not(safe))
  run staleOfferControlTest = init.then(copied).then(offer).then(badStaleLayout).expect(not(safe))
  run derivedReaderDrainTest = init.then(pinRoot).then(retire).then(deriveQueuedPin).then(releaseRoot).then(dequeue).then(finishScan).then(resetBank).expect(safe)
  run queuedReaderControlTest = init.then(pinRoot).then(deriveQueuedPin).then(retire).then(badDropQueuedPin).expect(not(safe))
  run dequeuedReaderControlTest = init.then(pinRoot).then(deriveQueuedPin).then(dequeue).then(retire).then(badDropInFlightPin).expect(not(safe))
  run earlyResetControlTest = init.then(pinRoot).then(retire).then(badResetWithReader).expect(not(safe))
  run drainIsNotPayloadDeathControlTest = init.then(transferred).then(readBack).then(retire).then(resetBank).then(badFreeLiveRegion).expect(not(safe))
  run pinAfterResetControlTest = init.then(retire).then(resetBank).then(badNewPinAfterReset).expect(not(safe))
  run postForwardFailureTest = init.then(backing).then(reserve).then(forward).then(quarantine).expect(safe and s.reserved)
  // Abstract model units: a late refund of the 3-word fresh demand cannot undo
  // a previously held 12+3-word allocation. These are not native memory values.
  run lateRefundPeakControlTest = init.expect(phasePeak(12+3,12)==12+3)
}
