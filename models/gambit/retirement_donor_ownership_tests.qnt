module retirement_donor_ownership_tests {
  import retirement_donor_ownership.* from "./retirement_donor_ownership"
  action captureAtSafePoint = closeDonorScheduling.then(saveDonorThread).then(publishThreadAnchor)
  action copyIfNeeded = if(s.copyTried) all { s' = s } else materializeCapturedFrames
  action scanPrivateIfNeeded = if(s.privateTodo) scanPrivateChunk.then(returnPrivateScan) else all { s' = s }
  action gcRound = arriveA.then(arriveB).then(arriveP0).then(markStrong).then(copyIfNeeded).then(determineWill).then(publishWeakWork).then(dequeueLastWork)
    .then(scanPrivateIfNeeded).then(returnScanner).then(finishGC).then(tailA).then(tailB).then(tailP0).then(completeGCReturn)
  action prepareFailingEpoch = captureAtSafePoint.then(startA).then(readyA).then(popAndStartB).then(requestGC1).then(gcRound)
    .then(outcomeB).then(requestGC2).then(gcRound).then(settlePreparation).then(decide)
    .then(ackA).then(ackP0).then(ackB).then(commonCompletion).then(restoreThreadOnAbort)
    .then(leaveB).then(leaveA).then(leaveP0).then(consumeResult).then(releaseResult).then(installCallerRoot).then(checkCallerRelocation)
  run combinedAbortAcrossTwoEpochs = initAbortTwice.then(openEpoch).then(prepareFailingEpoch)
    .expect(s.epoch == 1 and s.version == 3 and s.errorVersion == 2 and s.cohort == 3 and safe)
    .then(serviceYAfterAbort).then(nextEpoch).then(openEpoch)
    .expect(s.epoch == 2 and s.ack0 == 1 and s.arrival0 == 12 and s.bCalls == 0)
    .then(prepareFailingEpoch).then(serviceYAfterAbort)
    .expect(terminal and safe and s.version == 6 and s.totalA == 2 and s.totalB == 2 and s.totalY == 2)
  run abortThenSuccessfulHandoff = initAbortThenCommit.then(openEpoch).then(prepareFailingEpoch)
    .then(serviceYAfterAbort).then(nextEpoch).then(openEpoch)
    .then(captureAtSafePoint).then(startA).then(readyA).then(popAndStartB).then(requestGC1).then(gcRound)
    .then(outcomeB).then(requestGC2).then(gcRound).then(cancelYOnSuccess)
    .then(settlePreparation).then(spliceStillRC).then(handoffFrameValues).then(publishRunnableOnReceiver).then(handoffWillLists).then(prepareHandoff).then(decide)
    .then(ackB).then(ackA).then(ackP0).then(commonCompletion)
    .then(leaveA).then(leaveP0).then(leaveB).then(consumeResult).then(releaseResult).then(installCallerRoot).then(checkCallerRelocation)
    .expect(terminal and safe and s.cohort == 1 and s.version == 6 and s.framesElsewhere)
  run registeredCCallerKeepsCurrentValue = initRegisteredCCaller.then(openEpoch).then(prepareFailingEpoch)
    .expect(s.callerMode == 1 and s.callerRoot and s.callerVersion == s.version and safe)
}
