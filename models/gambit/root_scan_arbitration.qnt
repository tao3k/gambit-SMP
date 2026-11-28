module root_scan_arbitration {
  // One admitted root task, two workers, one derived chunk, two bounded epochs.
  // task:1 pending,2 claimed,3 ready,4 acknowledged,5 quarantined.
  // phase:1 strong,2 weak,3 cleanup/capacity,4 resume-sealed.
  type State={epoch:int,gen:int,task:int,owner:int,cursor:int,writes:int,
    phase:int,child:int,privateDebt:bool,ready:bool,noticeLost:bool,
    checkpoint:bool,stopped:bool,available1:bool,available2:bool,
    requested:bool,permit:bool,reloaded:bool,viewPinned:bool,rootVersion:int,
    localVersion:int,seal:bool,rejected:int,duplicate:bool}
  var s:State
  action init=s'={epoch:1,gen:1,task:1,owner:0,cursor:0,writes:0,
    phase:1,child:0,privateDebt:false,ready:false,noticeLost:false,
    checkpoint:false,stopped:false,available1:true,available2:true,
    requested:false,permit:false,reloaded:false,viewPinned:true,rootVersion:0,
    localVersion:0,seal:false,rejected:0,duplicate:false}
  val rootAck=s.task==4
  val strongClosed=rootAck and s.child==2 and s.owner==0 and not(s.privateDebt)
  val canSeal=s.phase==3 and strongClosed
  val canGrant=s.requested and s.seal and s.phase==4 and strongClosed and s.viewPinned
  val safe=not(s.duplicate) and s.writes==s.cursor and s.cursor<=2 and
    (s.task!=1 or (s.owner==0 and s.viewPinned and (s.available1 or s.available2))) and
    (s.task!=2 or (s.owner!=0 and not(s.stopped) or s.checkpoint)) and
    (s.task!=3 or (s.owner!=0 and s.ready and s.cursor==2 and not(s.privateDebt))) and
    (s.task!=4 or (s.owner==0 and s.ready and s.cursor==2 and not(s.privateDebt))) and
    (s.task!=5 or (s.owner!=0 and s.viewPinned and not(s.permit))) and
    (s.phase==1 or strongClosed) and
    (not(s.seal) or (s.phase==4 and strongClosed)) and
    (not(s.permit) or (s.seal and s.phase==4 and strongClosed)) and
    (s.viewPinned or (s.reloaded and s.permit)) and
    (not(s.reloaded) or (s.permit and s.localVersion==s.rootVersion))
  action requestReturn=all{not(s.permit),s'={...s,requested:true}}
  // Request changes no task debt; admitted task remains claimable.
  action claim1=all{s.task==1,s.available1,s.phase==1,
    s'={...s,task:2,owner:1,stopped:false,checkpoint:false}}
  action claim2=all{s.task==1,s.available2,s.phase==1,
    s'={...s,task:2,owner:2,stopped:false,checkpoint:false}}
  action claimReplyLost=all{s.task==2,s'={...s,noticeLost:true}}
  action duplicateClaimQuery=all{s.task!=1,s'={...s,rejected:s.rejected+1}}
  action writePrefix=all{s.task==2,not(s.stopped),s.cursor==0,
    s'={...s,cursor:1,writes:s.writes+1,privateDebt:true,checkpoint:false}}
  // Root scan publishes one abstract descendant before root can be acknowledged.
  action finishBody=all{s.task==2,not(s.stopped),s.cursor==1,
    s'={...s,cursor:2,writes:s.writes+1,privateDebt:false,child:1,rootVersion:1,checkpoint:false}}
  action publishReady=all{s.task==2,not(s.stopped),s.cursor==2,not(s.privateDebt),
    s'={...s,task:3,ready:true}}
  action loseReadyNotice=all{s.task==3,s'={...s,noticeLost:true}}
  action acknowledge=all{s.task==3,s'={...s,task:4,owner:0,noticeLost:false}}
  // Checkpoint stands for the full qualified cursor/copy-frame/child-credit state,
  // not just a numeric PC; actual source completeness is deliberately open.
  action captureCheckpoint=all{s.task==2,not(s.stopped),s.cursor<2,
    s'={...s,checkpoint:true}}
  action stopAtCheckpoint=all{s.task==2,s.checkpoint,s'={...s,stopped:true}}
  action requeueStopped=all{s.task==2,s.checkpoint,s.stopped,
    (if(s.owner==1)s.available2 else s.available1),
    s'={...s,task:1,owner:0,gen:s.gen+1,stopped:false,checkpoint:false,
      available1:if(s.owner==1)false else s.available1,
      available2:if(s.owner==2)false else s.available2}}
  action staleGenerationClaim=all{s.gen>1,s'={...s,rejected:s.rejected+1}}
  action unknownWriterOutcome=all{s.task==2,not(s.checkpoint),
    s'={...s,task:5,noticeLost:true}}
  action stopWithoutCheckpoint=all{s.task==5,s'={...s,stopped:true}}
  action observeUnknown=all{s.task==5,s'=s}
  action exitIdle1=all{s.owner!=1,(s.task!=1 or s.available2),s'={...s,available1:false}}
  action exitIdle2=all{s.owner!=2,(s.task!=1 or s.available1),s'={...s,available2:false}}
  action finishChild=all{s.child==1,s'={...s,child:2}}
  action beginWeak=all{s.phase==1,strongClosed,s'={...s,phase:2}}
  // Actual weak phase may move continuation frames after the strong root scan.
  action weakComplete=all{s.phase==2,s'={...s,phase:3,rootVersion:2}}
  // Abstracts cleanup/resize result, context recovery and synchronized delivery.
  action publishResumeSeal=all{canSeal,s'={...s,phase:4,seal:true,rootVersion:3}}
  action grant=all{canGrant,s'={...s,permit:true}}
  action reload=all{s.permit,s.viewPinned,s'={...s,reloaded:true,localVersion:s.rootVersion}}
  action retireView=all{s.reloaded,s'={...s,viewPinned:false}}
  action nextEpoch=all{s.reloaded,s.epoch==1,
    s'={...s,epoch:2,gen:s.gen+1,task:1,owner:0,cursor:0,writes:0,phase:1,child:0,
      privateDebt:false,ready:false,noticeLost:false,checkpoint:false,stopped:false,
      available1:true,available2:true,requested:false,permit:false,reloaded:false,
      viewPinned:true,rootVersion:0,localVersion:0,seal:false}}
  action staleEpochClaim=all{s.epoch==2,s'={...s,rejected:s.rejected+1}}
  action stutter=s'=s
  action step=any{requestReturn,claim1,claim2,claimReplyLost,duplicateClaimQuery,writePrefix,
    finishBody,publishReady,loseReadyNotice,acknowledge,captureCheckpoint,stopAtCheckpoint,
    requeueStopped,staleGenerationClaim,unknownWriterOutcome,stopWithoutCheckpoint,
    observeUnknown,exitIdle1,exitIdle2,finishChild,beginWeak,weakComplete,publishResumeSeal,
    grant,reload,retireView,nextEpoch,staleEpochClaim,stutter}
  action body=writePrefix.then(finishBody).then(publishReady)
  action roots=claim1.then(body).then(acknowledge)
  action sealRound=finishChild.then(beginWeak).then(weakComplete).then(publishResumeSeal)
  action returnRound=requestReturn.then(roots).then(sealRound).then(grant).then(reload)
  action unsafeResume=s'={...s,permit:true}
  action unsafeDrop=s'={...s,task:4,owner:0,ready:true}
  action unsafeRestart=s'={...s,task:1,owner:0,cursor:0}
  action unsafeDuplicate=s'={...s,duplicate:true}
  action unsafeRetire=s'={...s,viewPinned:false}
  run enlistedPendingHasCustodianTest=init.expect(safe and s.task==1 and s.viewPinned)
  run returnCannotCancelOwedClaimTest=init.then(requestReturn).then(claim2).expect(safe and s.owner==2)
  run returnDuringClaimTest=init.then(claim1).then(requestReturn).then(body).then(acknowledge).expect(safe and rootAck and not(canGrant))
  run claimReplyUnknownKeepsOwnerTest=init.then(claim1).then(claimReplyLost).then(duplicateClaimQuery).expect(safe and s.owner==1 and s.task==2)
  run readyReplyLostQueriesSameRecordTest=init.then(claim1).then(body).then(loseReadyNotice).then(duplicateClaimQuery).then(acknowledge).expect(safe and s.writes==2 and rootAck)
  run rootAckStillOwesChildTest=init.then(roots).expect(safe and s.child==1 and not(strongClosed))
  run childBeforeRootAckTest=init.then(claim1).then(body).then(finishChild).then(acknowledge).expect(safe and strongClosed)
  run rootDoneDoesNotGrantReturnTest=init.then(requestReturn).then(roots).then(finishChild).expect(safe and strongClosed and not(canGrant))
  run weakStillMayMoveFramesTest=init.then(requestReturn).then(roots).then(finishChild).then(beginWeak).then(weakComplete).expect(safe and s.rootVersion==2 and not(canGrant))
  run roundSealThenProtectedReloadTest=init.then(returnRound).expect(safe and s.localVersion==3)
  run retireOnlyAfterReloadTest=init.then(returnRound).then(retireView).expect(safe and not(s.viewPinned))
  run idleWorkerExitKeepsPendingTest=init.then(exitIdle1).then(requestReturn).then(claim2).then(body).then(acknowledge).expect(safe and rootAck)
  run freshCheckpointExitTest=init.then(claim1).then(captureCheckpoint).then(stopAtCheckpoint).then(requeueStopped).then(claim2).then(body).then(acknowledge).expect(safe and s.writes==2)
  run partialCheckpointResumeNoRepeatTest=init.then(claim1).then(writePrefix).then(captureCheckpoint).then(stopAtCheckpoint).then(requeueStopped).then(claim2).then(finishBody).then(publishReady).then(acknowledge).expect(safe and s.writes==2)
  run lateOldGenerationRejectedTest=init.then(claim1).then(captureCheckpoint).then(stopAtCheckpoint).then(requeueStopped).then(staleGenerationClaim).expect(safe and s.task==1 and s.gen==2)
  run unknownWriterKeepsDebtTest=init.then(claim1).then(writePrefix).then(unknownWriterOutcome).then(requestReturn).then(observeUnknown).expect(safe and s.task==5 and not(canGrant))
  run stopAloneNotRecoveryTest=init.then(claim1).then(writePrefix).then(unknownWriterOutcome).then(stopWithoutCheckpoint).expect(safe and s.task==5 and not(canGrant))
  run noCheckpointNoRequeueWitnessTest=init.then(claim1).then(writePrefix).expect(safe and not(s.checkpoint))
  run pendingViewLifetimeTest=init.then(requestReturn).then(exitIdle1).expect(safe and s.viewPinned and s.task==1)
  run weakRequiresDescendantDrainTest=init.then(roots).expect(safe and not(strongClosed))
  run newEpochRejectsOldClaimTest=init.then(returnRound).then(nextEpoch).then(staleEpochClaim).expect(safe and s.epoch==2 and s.task==1)
  run replacementWorkerFinishesRoundTest=init.then(requestReturn).then(claim1).then(writePrefix).then(captureCheckpoint).then(stopAtCheckpoint).then(requeueStopped).then(claim2).then(finishBody).then(publishReady).then(acknowledge).then(sealRound).then(grant).then(reload).expect(safe and s.writes==2 and s.localVersion==3)
  run earlyPermitCounterexampleTest=init.then(unsafeResume).expect(not(safe))
  run queueEmptyDropClaimCounterexampleTest=init.then(claim1).then(unsafeDrop).expect(not(safe))
  run restartPartialCopyCounterexampleTest=init.then(claim1).then(writePrefix).then(unsafeRestart).expect(not(safe))
  run duplicateUnknownClaimCounterexampleTest=init.then(claim1).then(claimReplyLost).then(unsafeDuplicate).expect(not(safe))
  run retirePendingViewCounterexampleTest=init.then(requestReturn).then(unsafeRetire).expect(not(safe))
}
