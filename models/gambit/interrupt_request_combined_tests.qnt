module interrupt_request_combined_tests {
  import interrupt_request_lifecycle.* from "./interrupt_request_lifecycle"
  action firstRoute = dequeue.then(targetMovesBeforeDispatch)
    .then(recheckReceiver).then(dispatch).then(beginMove).then(moveCollect)
    .then(publishMove).then(restoreMove)
  action childPath = nest.then(wait).then(firstRoute).then(actionCollect)
    .then(finishAction).then(replyCollect).then(unlock).then(dispatchAckInner).then(consume)
    .then(returnToParent).then(closeInner)
  action earlyBeforeClose = firstRoute.then(childPath).then(actionCollect)
    .then(finishAction).then(replyCollect).then(unlock).then(wait).then(consume)
  action earlyCombined = earlyBeforeClose.then(dispatchAckOuter).then(closeOuter)
  run earlyReplyNestedMigration = initEarlyNested.then(earlyCombined)
    .expect(done and safe and s.outer.wakeCount == 0 and s.inner.wakeCount == 1
      and s.outer.consumed and s.inner.consumed and s.gcCount == 6)
  run caughtReplyNestedMigration = initCaught.then(earlyCombined)
    .expect(done and safe and s.outer.status == 1 and s.outer.consumed)
  run opaqueExitRetainsParent = initOpaque.then(wait).then(firstRoute)
    .then(childPath).then(actionCollect).then(finishAction)
    .expect(done and safe and s.outer.owner == 8 and not(s.outer.consumed)
      and s.outer.mutexRoot and s.inner.consumed)
  run callerReturnDoesNotCloseDispatcher = initEarlyNested.then(earlyBeforeClose)
    .expect(s.outer.consumed and not(s.outer.closed)
      and not(s.outer.dispatchDone) and safe)
  run childContextOutlivesConsumption = initEarlyNested.then(firstRoute)
    .then(nest).then(wait).then(firstRoute).then(actionCollect)
    .then(finishAction).then(replyCollect).then(unlock).then(dispatchAckInner)
    .then(consume).expect(s.active == 2 and s.inner.consumed
      and not(s.inner.closed) and safe)
  run nestedMigrationHasOneActionOneReply = initEarlyNested.then(earlyCombined)
    .expect(done and safe and s.outer.executions == 1 and s.outer.resultWrites == 1
      and s.outer.replies == 1 and s.inner.executions == 1
      and s.inner.resultWrites == 1 and s.inner.replies == 1)
  run targetDiesBeforeAction = initTerminate.then(wait).then(dequeue)
    .then(abandonBeforeDispatch).then(replyCollect).then(unlock)
    .then(dispatchAckOuter).then(consume).then(closeOuter)
    .expect(done and safe and s.outer.executions == 0 and s.outer.resultWrites == 0
      and s.outer.replies == 1 and s.outer.status == 2)
  run targetDiesAfterEntry = initTerminate.then(wait).then(firstRoute)
    .then(childPath).then(actionCollect).then(finishAction).then(replyCollect)
    .then(unlock).then(dispatchAckOuter).then(consume).then(closeOuter)
    .expect(done and safe and s.outer.executions == 1 and s.outer.resultWrites == 0
      and s.outer.replies == 1 and s.outer.status == 2)
  run caughtResultHasOneReply = initCaught.then(earlyCombined)
    .expect(done and safe and s.outer.status == 1 and s.outer.executions == 1
      and s.outer.resultWrites == 1 and s.outer.replies == 1)
  run opaqueExitCannotInventReply = initOpaque.then(wait).then(firstRoute)
    .then(childPath).then(actionCollect).then(finishAction)
    .expect(done and safe and s.outer.phase == 9 and s.outer.executions == 1
      and s.outer.resultWrites == 0 and s.outer.replies == 0
      and not(s.outer.consumed) and not(s.outer.closed))

  action deliveredReply = deliveryHandoff.then(dispatch).then(actionCollect)
    .then(finishAction).then(fastReply).then(unlock).then(consume)
    .then(dispatchAckOuter).then(closeOuter)
  run deliveryStaleRouteReroutesOnce = initDelivery.then(deliveryMove)
    .then(deliveryPop).then(deliveryReroute).then(deliveryThreadDrain)
    .then(deliveredReply).expect(done and safe and s.outer.executions == 1
      and s.outer.replies == 1 and s.outer.consumed)
  run deliveryRecheckUsesCurrentOwner = initDelivery.then(deliveryPop)
    .then(deliveryMove).then(deliveryRecheck).then(deliveryReceive)
    .then(deliveredReply).expect(done and safe and s.outer.executions == 1)
  run deliveryWakeIsNotReply = initDelivery.then(deliveryClearWake)
    .expect(safe and s.outer.blocked and not(s.outer.unlocked) and owners1 == 1)
  run deliveryDetachedRequestIsNotLost = initDelivery.then(deliveryPop)
    .expect(safe and d.local == 1 and not(inProcessor1) and not(d.tq))
  run deliveryTailRetryPreservesSuccessor = initDelivery.then(deliveryTailRetry)
    .then(deliveryPop).expect(safe and inProcessor2 and d.local == 1)
}
