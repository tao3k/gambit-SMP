module interrupt_fault_disposition_tests {
 import interrupt_fault_disposition.* from "./interrupt_fault_disposition"
 action executeCallback=lockQueue.then(detachForCallback)
 .then(unlockBeforeCallback).then(callbackReturns)
 run callbackErrorReturnsWithoutSecondUnlockTest=initCallbackError.then(executeCallback)
 .then(returnError).then(reportCallbackError)
 .expect(done and safe and s.executions==1 and s.releases==0 and not(s.lock))
 run oldErrorBranchAttemptsAnUnheldUnlockTest=initDoubleUnlock.then(executeCallback)
 .then(returnError).expect(not(safe) and s.badUnlock)
 run pendingReleaseRunsOutsideQueueMutexTest=initPendingCleanup.then(closeAndDetachBatch)
 .then(unlockBatch).then(releasePending)
 .expect(done and safe and s.releases==1 and s.executions==0)
 run onlyAuthorizedTargetEndAbandonsSchemeReplyTest=initAuthorizedTargetEnd.then(lockQueue)
 .then(detachForCallback).then(unlockBeforeCallback).then(targetEnd)
 .expect(done and safe and s.reply==2 and s.ended and s.targetAuthorized)
 run joinedOwnerKeepsExistingLockedReleaseContractTest=initPendingCleanup
 .then(closeAndDetachBatch).then(releasePending)
 .expect(safe and s.lock and not(s.callbackUnderLock) and s.releases==1)
 .then(unlockReleaseEpilogue).expect(done and safe and not(s.lock))
}
