module tfib_gc_handoff_tests {
  import tfib_gc_handoff.* from "./tfib_gc_handoff"
  action gcRound = requestGC.then(arrive).then(arrive).then(beginGC)
    .then(announceForward).then(followForward).then(copyBody).then(publishChunk)
    .then(startScanner).then(finishScanner).then(finishGC).then(finishTail).then(finishTail).then(returnGC)
  run twoEpochNormal = init.then(initialize).then(publish).then(park)
    .then(gcRound).then(handoff).then(consumeResult).then(nextEpoch)
    .then(gcRound).then(handoff).then(consumeResult).expect(normalDone and safe)
  run announcedForwardIsNotScanPermission = init.then(initialize).then(publish).then(park)
    .then(requestGC).then(arrive).then(arrive).then(beginGC).then(announceForward)
    .then(followForward).expect(s.copy == 1 and not(s.queued) and not(s.scanning) and safe)
  run queueEmptyStillHasLastScanner = init.then(initialize).then(publish).then(park)
    .then(requestGC).then(arrive).then(arrive).then(beginGC).then(announceForward)
    .then(copyBody).then(publishChunk).then(startScanner)
    .expect(not(s.queued) and s.scanning and not(s.finished) and safe)
  run allocationFailureIsRetention = initAllocationFailure.then(allocationFailure)
    .expect(retainedFailure and not(normalDone) and safe)
}
