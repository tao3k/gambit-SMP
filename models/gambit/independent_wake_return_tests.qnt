module independent_wake_return_tests {
 import independent_wake_return.* from "./independent_wake_return"
 action sleepThenFault=precheck.then(commitWait).then(publishFault)
 action observeOutsideLocks= snapshot.then(callerUnlock).then(report)
 run sliceReturnsAcceptedOwnershipIntact=initSlice.then(sleepThenFault)
 .then(quantumReturn).then(observeOutsideLocks).then(writerEnds).then(close)
 .expect(safe and observedSafely and s.queueOwned and not(s.completed) and s.root)
 run atomicSignalSurvivesBeforeWait=initAtomicSignal.then(precheck)
 .then(publishFault).then(commitWait).then(signalReturn)
 .then(observeOutsideLocks).expect(safe and observedSafely)
 run faultOnlyArmingCannotChangeSleepingCall=initFaultOnlySlice
 .then(sleepThenFault).expect(not(safe) and stranded)
 run internalDeadlineCannotMarkDeviceReady=initEarlyDeviceTimeout
 .then(precheck).then(commitWait).then(quantumReturn)
 .expect(not(safe) and s.timerReady and not(s.realDeadline))
 run completionRequiresSeparateTerminalAuthority=initAuthorizedDisposition
 .then(sleepThenFault).then(quantumReturn).then(observeOutsideLocks)
 .then(writerEnds).then(close).then(dispose)
 .expect(safe and s.completed and s.terminalAuthorized and not(s.queueOwned))
}
