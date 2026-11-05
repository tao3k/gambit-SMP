module interrupt_fault_disposition_tests {
 import interrupt_fault_disposition.* from "./interrupt_fault_disposition"
 action executeCallback=lockQueue.then(detachForCallback)
 .then(unlockBeforeCallback).then(callbackReturns)
 run callbackErrorReturnsWithoutSecondUnlock=initCallbackError.then(executeCallback)
 .then(returnError).then(reportCallbackError)
 .expect(done and safe and s.executions==1 and s.releases==0 and not(s.lock))
 run oldErrorBranchAttemptsAnUnheldUnlock=initDoubleUnlock.then(executeCallback)
 .then(returnError).expect(not(safe) and s.badUnlock)
 run pendingReleaseRunsOutsideQueueMutex=initPendingCleanup.then(closeAndDetachBatch)
 .then(unlockBatch).then(releasePending)
 .expect(done and safe and s.releases==1 and s.executions==0)
 run onlyAuthorizedTargetEndAbandonsSchemeReply=initAuthorizedTargetEnd.then(lockQueue)
 .then(detachForCallback).then(unlockBeforeCallback).then(targetEnd)
 .expect(done and safe and s.reply==2 and s.ended and s.targetAuthorized)
 run joinedOwnerKeepsExistingLockedReleaseContract=initPendingCleanup
 .then(closeAndDetachBatch).then(releasePending)
 .expect(safe and s.lock and not(s.callbackUnderLock) and s.releases==1)
 .then(unlockReleaseEpilogue).expect(done and safe and not(s.lock))
}
