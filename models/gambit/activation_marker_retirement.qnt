module activation_marker_retirement {
  // One activation generation, two distinct transport deliveries, one GC view.
  // Complete root/stop/layout/owner admission is assumed. No C memory execution.
  type State={profile:int,activation:int,generation:int,requests:int->int,requestGen:int->int,
    delivered:int->int,current:int,closeRequested:bool,dutyAccepted:bool,popped:bool,
    clear:int,bodyCleared:bool,updating:bool,permit:bool,stopped:bool,
    pinHeld:bool,releases:int,cleanupDone:bool,notice:bool,rootHeld:bool,
    view:int,included:bool,borrowers:Set[int],readers:Set[int],recordLive:bool,
    markerFreed:bool,captured:bool,resultRooted:bool,legacyPhase:int,
    legacyApplied:int,legacyCounter:int,otherPins:int,race:bool}
  // activation: 0 Open,1 Returning,2 Closing,3 Closed.
  // request: 0 absent,1 queued,2 revocable reserve,3 owner-committed,4 consumed,5 revoked.
  // clear: 0 pending,1 known clear,2 outcome unknown; view:0 idle,1 published,2 scanning,3 traced.
  var s:State
  val ids=Set(0,1)
  val safe=ids.forall(i=>s.delivered.get(i)<=1) and s.releases<=1 and
    (s.activation!=1 or (s.current>=0 and s.requests.get(s.current)==3)) and
    (s.activation<2 or s.current==(-1)) and
    (not(s.popped) or (s.activation==3 and s.dutyAccepted)) and
    (not(s.cleanupDone) or (s.clear==1 and not(s.pinHeld))) and
    (not(s.markerFreed) or (not(s.rootHeld) and not(s.captured) and s.legacyCounter==0 and s.borrowers==Set() and s.view==0)) and
    (not(s.updating) or (s.permit and s.view==0)) and
    (not(s.permit) or s.view==0) and not(s.race) and s.legacyApplied<=1 and
    s.legacyCounter>=0 and s.resultRooted and
    (s.legacyPhase!=3 or (s.rootHeld and not(s.cleanupDone))) and
    (s.recordLive or (s.readers==Set() and s.current==(-1) and not(s.rootHeld))) and
    (s.profile!=1 or s.legacyCounter+s.legacyApplied==1+s.otherPins)
  def canCommit(i)=s.recordLive and s.activation==0 and s.requests.get(i)==2 and
    s.requestGen.get(i)==s.generation and s.current==(-1)
  val canClose=s.recordLive and s.activation==0 and s.current==(-1) and not(s.popped)
  val canClear=s.activation==3 and s.rootHeld and s.permit and s.view==0 and
    not(s.updating) and s.stopped and s.borrowers==Set() and not(s.markerFreed)
  val canGrant=s.activation==3 and s.rootHeld and s.view==0 and not(s.updating) and s.stopped and not(s.permit) and not(s.markerFreed) and s.borrowers==Set()
  val canDropRoot=s.activation==3 and s.popped and s.cleanupDone and s.view==0 and
    not(s.permit) and not(s.updating) and s.borrowers==Set()
  action base(p)=s'={profile:p,activation:0,generation:1,requests:Map(0->0,1->0),
    requestGen:Map(0->1,1->1),delivered:Map(0->0,1->0),current:(-1),
    closeRequested:false,dutyAccepted:false,popped:false,clear:0,bodyCleared:false,
    updating:false,permit:false,stopped:true,pinHeld:true,releases:0,cleanupDone:false,
    notice:false,rootHeld:true,view:0,included:false,borrowers:Set(),readers:Set(),
    recordLive:true,markerFreed:false,captured:false,resultRooted:true,
    legacyPhase:0,legacyApplied:0,legacyCounter:if(p==1)1 else 0,otherPins:0,race:false}
  action init=base(0)
  action legacyInit=base(1)
  action enqueue(i,g)=all{s.requests.get(i)==0,s'={...s,requests:s.requests.set(i,1),requestGen:s.requestGen.set(i,g)}}
  action reserve(i)=all{s.recordLive,s.activation==0,s.requests.get(i)==1,
    s.requestGen.get(i)==s.generation,s'={...s,requests:s.requests.set(i,2)}}
  action commitReturn(i)=all{canCommit(i),s'={...s,activation:1,current:i,requests:s.requests.set(i,3)}}
  action consumeReturn=all{s.activation==1,s.current>=0,s.requests.get(s.current)==3,
    s'={...s,activation:0,requests:s.requests.set(s.current,4),
      delivered:s.delivered.set(s.current,s.delivered.get(s.current)+1),current:(-1)}}
  action requestClose=s'={...s,closeRequested:true}
  action closeAdmissions=all{canClose,s'={...s,activation:2,
    requests:ids.mapBy(i=>if(s.requests.get(i)==1 or s.requests.get(i)==2)5 else s.requests.get(i))}}
  action acceptDuty=all{s.activation==2,s.rootHeld,s.stopped,
    s'={...s,dutyAccepted:true}}
  action publishClosed=all{s.activation==2,s.dutyAccepted,s.current==(-1),
    s'={...s,activation:3}}
  action pop=all{s.activation==3,s.dutyAccepted,s.current==(-1),s'={...s,popped:true}}
  action rejectLate(i)=all{s.requests.get(i)==1,
    not(s.recordLive) or s.activation>=2 or s.requestGen.get(i)!=s.generation,
    s'={...s,requests:s.requests.set(i,5)}}
  action query=s'=s
  // Actual owner/heap-write authority is an external source-refinement premise.
  action grantPermit=all{canGrant,s'={...s,permit:true}}
  action releasePermit=all{s.permit,not(s.updating),s'={...s,permit:false}}
  action beginClear=all{canClear,s.clear!=1,s'={...s,updating:true,stopped:false}}
  action finishClear=all{s.updating,s.permit,s.legacyPhase!=1,
    s'={...s,clear:1,bodyCleared:true,updating:false,stopped:true}}
  // These two outcomes include a qualified stopped-writer receipt, not a timeout.
  action stoppedClearUnknownBefore=all{s.updating,s.legacyPhase!=1,
    s'={...s,clear:2,bodyCleared:false,updating:false,stopped:true}}
  action stoppedClearUnknownAfter=all{s.updating,s.legacyPhase!=1,
    s'={...s,clear:2,bodyCleared:true,updating:false,stopped:true}}
  // Reapplying false is idempotent only with the root, permit and stopped old writer.
  action reconcileClear=all{canClear,s.clear==2,s'={...s,clear:1,bodyCleared:true}}
  action releaseLedgerPin=all{s.profile==0,canClear,s.clear==1,s.pinHeld,s.releases==0,
    s'={...s,pinHeld:false,releases:1,cleanupDone:true,notice:true}}
  action loseNotice=all{s.cleanupDone,s'={...s,notice:false}}
  action acknowledgeQuery=all{s.cleanupDone,s'={...s,notice:true}}
  action beginLegacyDebit=all{s.profile==1,canClear,s.clear==1,s.legacyPhase==0,
    s'={...s,legacyPhase:1,updating:true,stopped:false}}
  action finishLegacyDebit=all{s.profile==1,s.legacyPhase==1,s.updating,s.permit,
    s'={...s,legacyPhase:2,legacyApplied:1,legacyCounter:s.legacyCounter-1,
      updating:false,stopped:true,pinHeld:false,cleanupDone:true,notice:true}}
  action stoppedDebitUnknownBefore=all{s.profile==1,s.legacyPhase==1,s.updating,
    s'={...s,legacyPhase:3,updating:false,stopped:true}}
  action stoppedDebitUnknownAfter=all{s.profile==1,s.legacyPhase==1,s.updating,
    s'={...s,legacyPhase:3,legacyApplied:1,legacyCounter:s.legacyCounter-1,updating:false,stopped:true}}
  action otherLegacyInc=all{s.profile==1,s.permit,not(s.updating),
    s'={...s,otherPins:s.otherPins+1,legacyCounter:s.legacyCounter+1}}
  action otherLegacyDec=all{s.profile==1,s.permit,not(s.updating),s.otherPins>0,
    s'={...s,otherPins:s.otherPins-1,legacyCounter:s.legacyCounter-1}}
  action publishView=all{s.view==0,not(s.permit),not(s.updating),not(s.markerFreed),
    s'={...s,view:1,included:s.rootHeld or s.captured or s.legacyCounter>0}}
  action claimScan=all{s.view==1,not(s.permit),not(s.updating),s'={...s,view:2}}
  action traceScan=all{s.view==2,s'={...s,view:3}}
  action closeView=all{s.view==3,s'={...s,view:0}}
  val canBorrow=s.activation==0 and s.rootHeld and not(s.markerFreed) and s.clear==0 and not(s.updating)
  action borrowMarker=all{canBorrow,
    s'={...s,borrowers:Set(0)}}
  action dropBorrow=all{s.borrowers==Set(0),s'={...s,borrowers:Set()}}
  // Reader pin acquired with registry lookup; it does not imply a C jump right.
  action pinMetadata=all{s.recordLive,s'={...s,readers:Set(0)}}
  action unpinMetadata=s'={...s,readers:Set()}
  action captureContinuation=all{s.activation==0,not(s.markerFreed),s'={...s,captured:true}}
  action dropCaptured=s'={...s,captured:false}
  action dropRoot=all{canDropRoot,s'={...s,rootHeld:false}}
  action collectMarker=all{not(s.rootHeld),not(s.captured),s.legacyCounter==0,s.view==0,
    not(s.permit),not(s.updating),s.borrowers==Set(),s'={...s,markerFreed:true}}
  action retireRecord=all{s.activation==3,s.cleanupDone,not(s.rootHeld),s.readers==Set(),
    s.current==(-1),not(s.updating),s.view==0,
    s'={...s,recordLive:false}}
  action stutter=s'=s
  action step={nondet i=ids.oneOf();any{enqueue(i,1),reserve(i),commitReturn(i),consumeReturn,
    requestClose,closeAdmissions,acceptDuty,publishClosed,pop,rejectLate(i),query,
    grantPermit,releasePermit,beginClear,finishClear,stoppedClearUnknownBefore,
    stoppedClearUnknownAfter,reconcileClear,releaseLedgerPin,loseNotice,acknowledgeQuery,
    publishView,claimScan,traceScan,closeView,borrowMarker,dropBorrow,pinMetadata,
    unpinMetadata,captureContinuation,dropCaptured,dropRoot,collectMarker,retireRecord,stutter}}
  action legacyStep=any{step,beginLegacyDebit,finishLegacyDebit,stoppedDebitUnknownBefore,
    stoppedDebitUnknownAfter,otherLegacyInc,otherLegacyDec}
  action close=closeAdmissions.then(acceptDuty).then(publishClosed).then(pop)
  action physical=grantPermit.then(beginClear).then(finishClear).then(releaseLedgerPin).then(releasePermit)
  action legacyPrepare=close.then(grantPermit).then(beginClear).then(finishClear).then(beginLegacyDebit)
  action cycle=publishView.then(claimScan).then(traceScan).then(closeView)
  action unsafeCloseCommitted=s'={...s,activation:3,popped:true,dutyAccepted:true}
  action unsafeLateJump=s'={...s,current:0,requests:s.requests.set(0,3)}
  action unsafePop=s'={...s,popped:true}
  action unsafePermit=s'={...s,permit:true}
  action unsafeRace=s'={...s,race:true,bodyCleared:true}
  action unsafeDoubleRelease=s'={...s,releases:2}
  action unsafeReplayDebit=s'={...s,legacyApplied:s.legacyApplied+1,legacyCounter:s.legacyCounter-1}
  action unsafeRootDrop=s'={...s,rootHeld:false}
  action unsafeFree=s'={...s,markerFreed:true}
  action unsafeRepeatDelivery=s'={...s,delivered:s.delivered.set(0,2)}
  action unsafeResultDrop=s'={...s,resultRooted:false}
  action badStep=any{step,unsafePop}
  run reserveBeforeCloseIsRevokedTest=init.then(enqueue(0,1)).then(reserve(0)).then(close).expect(safe and s.requests.get(0)==5 and not(canCommit(0)))
  run committedReturnWinsCloseAttemptTest=init.then(enqueue(0,1)).then(reserve(0)).then(commitReturn(0)).then(requestClose).expect(safe and not(canClose) and s.current==0)
  run unknownReturnResponseDoesNotReplayTest=init.then(enqueue(0,1)).then(reserve(0)).then(commitReturn(0)).then(query).then(query).then(requestClose).expect(safe and s.activation==1 and s.delivered.get(0)==0 and not(canClose))
  run unknownCloseResponseKeepsDutyTest=init.then(close).then(query).then(query).expect(safe and s.activation==3 and s.dutyAccepted and s.rootHeld)
  run consumeThenCloseTest=init.then(enqueue(0,1)).then(reserve(0)).then(commitReturn(0)).then(consumeReturn).then(close).expect(safe and s.delivered.get(0)==1 and s.activation==3)
  run freshReturnSameLiveMarkerTest=init.then(enqueue(0,1)).then(reserve(0)).then(commitReturn(0)).then(consumeReturn).then(enqueue(1,1)).then(reserve(1)).then(commitReturn(1)).then(consumeReturn).expect(safe and s.delivered==Map(0->1,1->1) and s.activation==0)
  run oldDeliveryNotFreshReturnTest=init.then(enqueue(0,1)).then(reserve(0)).then(commitReturn(0)).then(consumeReturn).expect(safe and not(canCommit(0)))
  run queuedLateReturnRejectedTest=init.then(close).then(enqueue(0,1)).then(rejectLate(0)).expect(safe and s.requests.get(0)==5 and s.current==(-1))
  run staleGenerationRejectedTest=init.then(enqueue(0,0)).then(rejectLate(0)).expect(safe and s.requests.get(0)==5)
  run logicalCloseDoesNotClearBodyTest=init.then(close).expect(safe and not(s.bodyCleared) and s.pinHeld and s.rootHeld)
  run pendingViewBlocksPhysicalPermitTest=init.then(close).then(publishView).expect(safe and s.view==1 and not(s.permit))
  run scannedViewThenPhysicalCleanupTest=init.then(close).then(cycle).then(physical).expect(safe and s.cleanupDone and s.releases==1)
  run writerBlocksScannerTest=init.then(close).then(grantPermit).then(beginClear).expect(safe and s.updating and s.view==0)
  run unknownClearBeforeCanReconcileTest=init.then(close).then(grantPermit).then(beginClear).then(stoppedClearUnknownBefore).then(reconcileClear).then(releaseLedgerPin).expect(safe and s.cleanupDone and s.releases==1)
  run unknownClearAfterCanReconcileTest=init.then(close).then(grantPermit).then(beginClear).then(stoppedClearUnknownAfter).then(reconcileClear).then(releaseLedgerPin).expect(safe and s.cleanupDone and s.releases==1)
  run lostPinReceiptQueriesCanonicalRecordTest=init.then(close).then(physical).then(loseNotice).then(acknowledgeQuery).then(query).expect(safe and s.releases==1)
  run borrowerDefersPhysicalClearTest=init.then(borrowMarker).then(close).expect(safe and not(canGrant) and not(canClear) and s.rootHeld)
  run closedRejectsNewObjectBorrowTest=init.then(close).expect(safe and not(canBorrow) and s.rootHeld)
  run metadataObserverDoesNotPinMarkerTest=init.then(pinMetadata).then(close).then(physical).then(dropRoot).then(collectMarker).expect(safe and s.recordLive and s.markerFreed)
  run capturedContinuationKeepsClosedMarkerTest=init.then(captureContinuation).then(close).then(physical).then(dropRoot).then(enqueue(0,1)).then(rejectLate(0)).expect(safe and s.captured and not(s.markerFreed))
  run retiredMetadataLateReturnFailsClosedTest=init.then(close).then(physical).then(dropRoot).then(retireRecord).then(enqueue(0,1)).then(rejectLate(0)).expect(safe and not(s.recordLive) and s.requests.get(0)==5)
  run legacyKnownDecrementOnceTest=legacyInit.then(legacyPrepare).then(finishLegacyDebit).then(releasePermit).expect(safe and s.legacyApplied==1 and s.legacyCounter==0)
  run legacyUnknownBeforeRetainsRootTest=legacyInit.then(legacyPrepare).then(stoppedDebitUnknownBefore).then(releasePermit).then(cycle).expect(safe and s.rootHeld and s.legacyApplied==0 and not(s.cleanupDone))
  run legacyUnknownAfterRetainsRootTest=legacyInit.then(legacyPrepare).then(stoppedDebitUnknownAfter).then(releasePermit).then(cycle).expect(safe and s.rootHeld and s.legacyApplied==1 and not(s.cleanupDone))
  run ambiguousCounterBeforeTest=legacyInit.then(legacyPrepare).then(stoppedDebitUnknownBefore).expect(safe and s.legacyCounter==1 and s.legacyPhase==3 and s.legacyApplied==0)
  run ambiguousCounterAfterOtherPinTest=legacyInit.then(legacyPrepare).then(stoppedDebitUnknownAfter).then(otherLegacyInc).expect(safe and s.legacyCounter==1 and s.legacyPhase==3 and s.legacyApplied==1)
  run closeAcrossCommittedClaimCounterexampleTest=init.then(enqueue(0,1)).then(reserve(0)).then(commitReturn(0)).then(unsafeCloseCommitted).expect(not(safe))
  run lateJumpAfterCloseCounterexampleTest=init.then(close).then(unsafeLateJump).expect(not(safe))
  run popBeforeCloseCounterexampleTest=init.then(unsafePop).expect(not(safe))
  run publishedUnclaimedPermitCounterexampleTest=init.then(close).then(publishView).then(unsafePermit).expect(not(safe))
  run clearDuringScanCounterexampleTest=init.then(close).then(publishView).then(claimScan).then(unsafeRace).expect(not(safe))
  run duplicateLedgerReleaseCounterexampleTest=init.then(close).then(physical).then(unsafeDoubleRelease).expect(not(safe))
  run unknownLegacyDebitReplayCounterexampleTest=legacyInit.then(legacyPrepare).then(stoppedDebitUnknownAfter).then(unsafeReplayDebit).expect(not(safe))
  run unknownDebitRootRefundCounterexampleTest=legacyInit.then(legacyPrepare).then(stoppedDebitUnknownBefore).then(unsafeRootDrop).expect(not(safe))
  run freeingBorrowedMarkerCounterexampleTest=init.then(borrowMarker).then(unsafeFree).expect(not(safe))
  run duplicateTransportDeliveryCounterexampleTest=init.then(enqueue(0,1)).then(reserve(0)).then(commitReturn(0)).then(consumeReturn).then(unsafeRepeatDelivery).expect(not(safe))
  run discardedCommittedResultCounterexampleTest=init.then(close).then(physical).then(unsafeResultDrop).expect(not(safe))
}
