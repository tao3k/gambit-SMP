module resume_seal_cleanup {
  // One GC-selected foreign object, one owner and one release task.
  // task0 source wrapper;1 reserved;2 accepted;3 executing;4 known result;
  // task5 isolated native outcome unknown;6 handoff transaction unknown.
  type State={task:int,origin:int,profile:bool,semanticDelay:bool,managed:bool,
    isolated:bool,covered:int,rootDebt:bool,rootsClosed:bool,weakClosed:bool,
    accepted:bool,cleanupSettled:bool,capacity:int,prepared:bool,resultCommitted:bool,
    writersClosed:bool,binding:bool,gatesReleased:bool,pins:bool,serviceOwns:bool,
    sourceOwns:bool,wrapperRetired:bool,backingFreed:bool,freeDispositionKnown:bool,
    calls:int,noticeLost:bool,observerCancelled:bool,releaseSuccess:bool,
    requested:bool,seal:bool,epoch:int,generation:int,sealEpoch:int,sealGeneration:int,
    permit:bool,reloaded:bool,ownerWaitsSeal:bool,cleanupWaitsOwner:bool}
  var s:State
  action init=s'={task:0,origin:0,profile:false,semanticDelay:false,managed:false,
    isolated:true,covered:2,rootDebt:false,rootsClosed:false,weakClosed:false,
    accepted:false,cleanupSettled:false,capacity:0,prepared:false,resultCommitted:false,
    writersClosed:true,binding:true,gatesReleased:true,pins:false,serviceOwns:false,
    sourceOwns:true,wrapperRetired:false,backingFreed:false,freeDispositionKnown:false,
    calls:0,noticeLost:false,observerCancelled:false,releaseSuccess:false,
    requested:true,seal:false,epoch:1,generation:1,sealEpoch:0,sealGeneration:0,
    permit:false,reloaded:false,ownerWaitsSeal:true,cleanupWaitsOwner:false}
  val rootSafe=s.covered==2 and not(s.rootDebt) and s.rootsClosed
  val custody=s.accepted and s.serviceOwns and s.pins and not(s.sourceOwns)
  val canHandoff=s.task==1 and s.origin==0 and s.profile and s.semanticDelay and
    s.isolated and rootSafe and s.weakClosed and s.writersClosed and s.gatesReleased
  val safeDeferred=custody and s.isolated and rootSafe and s.task!=6
  val canSettle=s.weakClosed and safeDeferred and not(s.cleanupWaitsOwner)
  val canSeal=s.rootsClosed and s.weakClosed and s.cleanupSettled and rootSafe and
    (s.capacity==1 or s.capacity==2) and s.prepared and s.resultCommitted and
    s.writersClosed and s.binding and s.gatesReleased and safeDeferred
  val validSeal=s.seal and s.sealEpoch==s.epoch and s.sealGeneration==s.generation
  val safe=s.calls<=1 and not(s.sourceOwns and s.serviceOwns) and
    (not(s.wrapperRetired) or custody) and
    (not(s.cleanupSettled) or safeDeferred) and
    (not(s.backingFreed) or (s.task==4 and s.freeDispositionKnown)) and
    (not(s.permit) or (validSeal and canSeal)) and
    (not(s.managed) or s.calls==0 or s.permit) and
    not(s.ownerWaitsSeal and s.cleanupWaitsOwner) and
    (s.task!=6 or (s.sourceOwns and s.pins and not(s.permit))) and
    (not(s.reloaded) or s.permit)
  action qualify=s'={...s,profile:true,semanticDelay:true}
  action chooseManaged=all{s.task==0,s'={...s,managed:true,covered:0,rootDebt:true}}
  action chooseExplicit=all{s.task==0,s'={...s,origin:1}}
  action registerRoots=all{s.task<=1,s.covered==0,s'={...s,covered:1}}
  action rescanRoots=all{s.covered==1,not(s.weakClosed),s'={...s,covered:2,rootDebt:false}}
  action closeRoots=all{s.covered==2,not(s.rootDebt),s'={...s,rootsClosed:true}}
  action closeWeak=all{s.rootsClosed,s'={...s,weakClosed:true}}
  action reserve=all{s.task==0,s'={...s,task:1,pins:true}}
  // Reservation/source custody precedes destructive wrapper field retirement.
  action handoff=all{canHandoff,s'={...s,task:2,accepted:true,serviceOwns:true,sourceOwns:false}}
  action loseAcceptNotice=all{s.task==2,s'={...s,noticeLost:true}}
  action queryAccepted=all{s.accepted,s'={...s,noticeLost:false}}
  action retireWrapper=all{custody,s'={...s,wrapperRetired:true}}
  action cancelObserver=all{s.accepted,s'={...s,observerCancelled:true}}
  action unknownHandoff=all{s.task==1,s'={...s,task:6,noticeLost:true}}
  action observeUnknownHandoff=all{s.task==6,s'=s}
  action settleCleanup=all{canSettle,s'={...s,cleanupSettled:true}}
  action capacitySuccess=all{s.cleanupSettled,s'={...s,capacity:1}}
  action capacityError=all{s.cleanupSettled,s'={...s,capacity:2}}
  action capacityUnknown=all{s.cleanupSettled,s.capacity==0,s'={...s,capacity:3}}
  action prepareContext=all{s.capacity==1 or s.capacity==2,s'={...s,prepared:true}}
  action commitResult=all{s.prepared,s'={...s,resultCommitted:true}}
  action rootWriterUnknown=all{not(s.seal),s'={...s,writersClosed:false}}
  action bindingUnknown=all{not(s.seal),s'={...s,binding:false}}
  action gateStillHeld=all{not(s.seal),s'={...s,gatesReleased:false}}
  action publishSeal=all{canSeal,s'={...s,seal:true,sealEpoch:s.epoch,sealGeneration:s.generation}}
  action retireTargetGeneration=all{s.seal,not(s.permit),s'={...s,generation:s.generation+1,prepared:false,resultCommitted:false}}
  action acquire=all{validSeal,canSeal,s'={...s,permit:true,ownerWaitsSeal:false}}
  action reload=all{s.permit,s'={...s,reloaded:true}}
  action invokeNative=all{s.task==2,not(s.managed),s.isolated,s'={...s,task:3,calls:s.calls+1}}
  action invokeManaged=all{s.task==2,s.managed,s.permit,s'={...s,task:3,calls:s.calls+1}}
  action finishSuccess=all{s.task==3,s'={...s,task:4,freeDispositionKnown:true,releaseSuccess:true}}
  action finishFailure=all{s.task==3,s'={...s,task:4,freeDispositionKnown:false,releaseSuccess:false}}
  action finishErrorFreed=all{s.task==3,s'={...s,task:4,freeDispositionKnown:true,releaseSuccess:false,backingFreed:true}}
  action loseNativeOutcome=all{s.task==3,not(s.managed),s.isolated,s'={...s,task:5,noticeLost:true}}
  action queryTerminal=all{s.task==4,s'={...s,noticeLost:false}}
  action freeBacking=all{s.task==4,s.freeDispositionKnown,not(s.backingFreed),s'={...s,backingFreed:true}}
  action stutter=s'=s
  action step=any{qualify,chooseManaged,chooseExplicit,registerRoots,rescanRoots,closeRoots,
    closeWeak,reserve,handoff,loseAcceptNotice,queryAccepted,retireWrapper,cancelObserver,
    unknownHandoff,observeUnknownHandoff,settleCleanup,capacitySuccess,capacityError,
    capacityUnknown,prepareContext,commitResult,rootWriterUnknown,bindingUnknown,
    gateStillHeld,publishSeal,retireTargetGeneration,acquire,reload,invokeNative,
    invokeManaged,finishSuccess,finishFailure,finishErrorFreed,loseNativeOutcome,queryTerminal,freeBacking,stutter}
  action cohort=qualify.then(closeRoots).then(closeWeak).then(reserve).then(handoff)
  action readySeal=settleCleanup.then(capacitySuccess).then(prepareContext).then(commitResult).then(publishSeal)
  action managedCohort=qualify.then(chooseManaged).then(registerRoots).then(rescanRoots).then(closeRoots).then(closeWeak).then(reserve).then(handoff)
  action unsafeSeal=s'={...s,seal:true,permit:true,sealEpoch:s.epoch,sealGeneration:s.generation}
  action unsafeFree=s'={...s,backingFreed:true}
  action unsafeManagedCall=s'={...s,task:3,calls:s.calls+1}
  action unsafeCycle=s'={...s,cleanupWaitsOwner:true}
  action unsafeRetire=s'={...s,wrapperRetired:true}
  action unsafeReplay=s'={...s,calls:s.calls+1}
  run unqualifiedCannotHandoffWitnessTest=init.then(reserve).expect(safe and not(canHandoff))
  run explicitOriginNotBlanketDeferredTest=init.then(qualify).then(chooseExplicit).then(closeRoots).then(closeWeak).then(reserve).expect(safe and not(canHandoff))
  run reserveKeepsSourceTest=init.then(reserve).expect(safe and s.sourceOwns and not(s.serviceOwns))
  run nativeTaskAcceptanceTest=init.then(cohort).expect(safe and custody and s.calls==0)
  run lostAcceptanceReplyQueriesRecordTest=init.then(cohort).then(loseAcceptNotice).then(queryAccepted).expect(safe and s.accepted and s.calls==0)
  run observerCancelKeepsCustodyTest=init.then(cohort).then(cancelObserver).expect(safe and custody)
  run wrapperRetiresAfterHandoffTest=init.then(cohort).then(retireWrapper).expect(safe and s.wrapperRetired and not(s.backingFreed))
  run queuedDestructorDoesNotBlockSealTest=init.then(cohort).then(readySeal).then(acquire).then(reload).expect(safe and s.calls==0 and s.reloaded)
  run nativeExecutionMayOverlapRoundCompletionTest=init.then(cohort).then(invokeNative).then(readySeal).then(acquire).expect(safe and s.task==3)
  run isolatedUnknownOutcomeDoesNotBlockGcTest=init.then(cohort).then(invokeNative).then(loseNativeOutcome).then(readySeal).then(acquire).expect(safe and s.task==5 and not(s.backingFreed))
  run managedRootsRequireRescanTest=init.then(qualify).then(chooseManaged).then(registerRoots).then(reserve).expect(safe and not(canHandoff) and s.rootDebt)
  run managedCallbackRunsAfterPermitTest=init.then(managedCohort).then(readySeal).then(acquire).then(invokeManaged).then(finishSuccess).expect(safe and s.calls==1)
  run queuedManagedTaskDoesNotWaitInsideCleanupTest=init.then(managedCohort).then(readySeal).expect(safe and s.calls==0 and s.ownerWaitsSeal)
  run handoffUnknownRefusesSealTest=init.then(qualify).then(closeRoots).then(closeWeak).then(reserve).then(unknownHandoff).then(observeUnknownHandoff).expect(safe and s.sourceOwns and not(canSeal))
  run capacityUnknownRefusesSealTest=init.then(cohort).then(settleCleanup).then(capacityUnknown).expect(safe and not(canSeal))
  run capacityErrorNeedsPreparedErrorPathTest=init.then(cohort).then(settleCleanup).then(capacityError).then(prepareContext).then(commitResult).then(publishSeal).then(acquire).expect(safe and s.capacity==2)
  run missingResultRefusesSealTest=init.then(cohort).then(settleCleanup).then(capacitySuccess).then(prepareContext).expect(safe and not(canSeal))
  run unknownWriterRefusesSealTest=init.then(cohort).then(rootWriterUnknown).then(settleCleanup).then(capacitySuccess).then(prepareContext).then(commitResult).expect(safe and not(canSeal))
  run unknownBindingRefusesSealTest=init.then(cohort).then(bindingUnknown).then(readySealWithoutPublish).expect(safe and not(canSeal))
  action readySealWithoutPublish=settleCleanup.then(capacitySuccess).then(prepareContext).then(commitResult)
  run heldGateRefusesSealTest=init.then(cohort).then(gateStillHeld).then(readySealWithoutPublish).expect(safe and not(canSeal))
  run staleTargetRejectsPermitTest=init.then(cohort).then(readySeal).then(retireTargetGeneration).expect(safe and not(validSeal))
  run failedDestructorKeepsBackingTest=init.then(cohort).then(invokeNative).then(finishFailure).then(readySeal).then(acquire).expect(safe and not(s.backingFreed))
  run knownSuccessCanReleaseNativeBackingTest=init.then(cohort).then(invokeNative).then(finishSuccess).then(freeBacking).then(readySeal).then(acquire).expect(safe and s.backingFreed)
  run errorCanAlreadyHaveFreedStorageTest=init.then(cohort).then(invokeNative).then(finishErrorFreed).then(readySeal).then(acquire).expect(safe and s.backingFreed and not(s.releaseSuccess) and s.calls==1)
  run queryDoesNotReplayTest=init.then(cohort).then(invokeNative).then(finishSuccess).then(queryTerminal).then(queryTerminal).expect(safe and s.calls==1)
  run earlySealCounterexampleTest=init.then(unsafeSeal).expect(not(safe))
  run enqueueMeansFreeCounterexampleTest=init.then(cohort).then(unsafeFree).expect(not(safe))
  run callbackBeforePermitCounterexampleTest=init.then(managedCohort).then(unsafeManagedCall).expect(not(safe))
  run cleanupOwnerCycleCounterexampleTest=init.then(managedCohort).then(unsafeCycle).expect(not(safe))
  run wrapperWithoutCustodyCounterexampleTest=init.then(reserve).then(unsafeRetire).expect(not(safe))
  run lostNativeResultReplayCounterexampleTest=init.then(cohort).then(invokeNative).then(loseNativeOutcome).then(unsafeReplay).expect(not(safe))
}
