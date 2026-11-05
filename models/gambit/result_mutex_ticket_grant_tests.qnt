module result_mutex_ticket_grant_tests {
 import result_mutex_ticket_grant_contract.* from "./result_mutex_ticket_grant_contract"
 action oldTailSchedule=reserveTicket.then(observeOldTail).then(popOldA)
 .then(acceptGrant).then(clearNextB).then(publishTailB).then(linkB).then(senderSecondLock)
 run legacyReservationDoesNotAcquireGrant=initLegacy.then(oldTailSchedule)
 .expect(stranded and not(noLost) and s.head==0 and s.nextA==2)
 run completionFenceRefreshesTail=initPostGrantFence.then(oldTailSchedule)
 .then(claimB).then(executeB).expect(done and noLost)
 run debugAlreadyHasCompletionBarrier=initDebugExistingBarrier.then(oldTailSchedule)
 .then(claimB).then(executeB).expect(done and noLost)
 run emptyFallbackIsNotAnAcquire=initNoopFallback.then(oldTailSchedule)
 .expect(stranded and not(noLost) and s.acquireAfterGrant and not(s.effective))
}
