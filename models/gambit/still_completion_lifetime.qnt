module still_completion_lifetime {
  // One native operation plus an already completed peer at sequence2.
  // phase:0 registered,1 entered,2 returned privately,3 ready,4 settled.
  // txn:0 outside,1 validated,2 partial writes,3 committed awaiting unlock.
  type State={phase:int,guard:int,alive:bool,poison:bool,txn:int,outcome:int,
    physical:bool,charge:int,credits:int,applied:bool,root:bool,binding:bool,
    pendingCancel:bool,delivered:bool,ack1:bool,ack2:bool,floor:int,
    record1:bool,record2:bool,pin1:int,pin2:int,handed:bool,oldAccepted:bool}
  var s:State
  action init=s'={phase:0,guard:0,alive:true,poison:false,txn:0,outcome:0,
    physical:false,charge:2,credits:0,applied:false,root:false,binding:true,
    pendingCancel:false,delivered:false,ack1:false,ack2:false,floor:0,
    record1:true,record2:true,pin1:0,pin2:0,handed:false,oldAccepted:false}
  val producerClosed=s.guard==0 or not(s.alive)
  val handoffReady=s.phase==4 and s.txn==0 and not(s.poison) and s.root and s.binding and producerClosed
  val canLookup1=s.floor<1 and s.record1 and not(s.poison) and s.txn==0
  val safe=s.credits>=0 and s.credits<=1 and s.charge>=0 and s.charge<=2 and
    (s.txn==2 or s.poison or s.charge+2*s.credits==2) and
    (not(s.physical) or s.charge==2) and
    (not(s.applied) or s.phase==4) and
    (not(s.alive) or not(s.phase==1 or s.phase==2) or s.guard>0) and
    (not(s.record1) or s.pin1>=0) and
    (s.record1 or (s.floor>=1 and s.pin1==0)) and
    (s.record2 or (s.floor==2 and s.pin2==0)) and
    (s.floor==0 or (s.applied and s.ack1 and producerClosed)) and
    (s.floor<2 or s.ack2) and
    (not(s.handed) or handoffReady) and not(s.oldAccepted)
  action guardEnter=all{s.alive,s.phase==0,s.guard==0,not(s.poison),s'={...s,guard:1}}
  action guardNest=all{s.alive,s.phase==0,s.guard==1,s'={...s,guard:2}}
  action guardUnnest=all{s.alive,s.guard==2,s'={...s,guard:1}}
  action requestCancel=s'={...s,pendingCancel:true}
  action rawEnter=all{s.alive,s.guard>0,s.phase==0,s'={...s,phase:1}}
  action rawOk=all{s.alive,s.guard>0,s.phase==1,s'={...s,phase:2,outcome:1,physical:true}}
  action rawFail=all{s.alive,s.guard>0,s.phase==1,s'={...s,phase:2,outcome:2}}
  action publish=all{s.alive,s.guard>0,s.phase==2,s.record1,s'={...s,phase:3}}
  action protect=all{s.phase>=3,s.txn==0,not(s.poison),s'={...s,root:true}}
  action txBegin=all{s.phase==3,s.txn==0,not(s.poison),s'={...s,txn:1}}
  action rejectBeforeWrite=all{s.txn==1,not(s.poison),s'={...s,txn:0}}
  action partialWrite=all{s.txn==1,not(s.poison),s'={...s,txn:2,charge:if(s.outcome==2)0 else 2}}
  action txCommit=all{s.txn==2,not(s.poison),s'={...s,phase:4,applied:true,credits:if(s.outcome==2)1 else 0,txn:3}}
  action txUnlock=all{s.txn==3,not(s.poison),s'={...s,txn:0}}
  action guardLeave=all{s.alive,s.guard==1,s.phase>=3,s.root,s.binding,s.txn==0,not(s.poison),s'={...s,guard:0}}
  // Qualified full-stop witness is a premise; this is not a pthread_join model.
  action ownerStopped=all{s.alive,s'={...s,alive:false,poison:s.poison or s.txn>0}}
  action deliver=all{s.applied,s.txn==0,not(s.poison),s.record1,s'={...s,delivered:true}}
  action loseDelivery=s'={...s,delivered:false}
  action ackFirst=all{s.applied,s.txn==0,not(s.poison),s'={...s,ack1:true}}
  action ackSecond=s'={...s,ack2:true}
  action pinFirst=all{canLookup1,s.pin1==0,s'={...s,pin1:1}}
  action dropFirst=all{s.pin1==1,s'={...s,pin1:0}}
  action pinSecond=all{s.floor<2,s.record2,s.pin2==0,s.txn==0,not(s.poison),s'={...s,pin2:1}}
  action dropSecond=all{s.pin2==1,s'={...s,pin2:0}}
  action floorFirst=all{s.txn==0,not(s.poison),producerClosed,s.applied,s.ack1,s.floor==0,s'={...s,floor:1}}
  action floorSecond=all{s.txn==0,not(s.poison),producerClosed,s.applied,s.ack1,s.ack2,s.floor<2,s'={...s,floor:2}}
  action recycleFirst=all{s.txn==0,not(s.poison),s.floor>=1,s.pin1==0,s.record1,s'={...s,record1:false}}
  action recycleSecond=all{s.txn==0,not(s.poison),s.floor==2,s.pin2==0,s.record2,s'={...s,record2:false}}
  action handoff=all{handoffReady,s'={...s,handed:true}}
  action stutter=s'=s
  action step=if(s.handed)stutter else any{guardEnter,guardNest,guardUnnest,requestCancel,rawEnter,rawOk,rawFail,
    publish,protect,txBegin,rejectBeforeWrite,partialWrite,txCommit,txUnlock,guardLeave,ownerStopped,
    deliver,loseDelivery,ackFirst,ackSecond,pinFirst,dropFirst,pinSecond,dropSecond,floorFirst,
    floorSecond,recycleFirst,recycleSecond,handoff,stutter}
  action publishedOk=guardEnter.then(rawEnter).then(rawOk).then(publish)
  action publishedFail=guardEnter.then(rawEnter).then(rawFail).then(publish)
  action settle=txBegin.then(partialWrite).then(txCommit).then(txUnlock)
  action complete=publishedOk.then(protect).then(settle).then(guardLeave)
  action failComplete=publishedFail.then(protect).then(settle).then(guardLeave)
  action unsafeRestore=s'={...s,guard:0}
  action unsafeUnlock=s'={...s,txn:0}
  action unsafeRecycle=s'={...s,record1:false}
  action unsafeOldAccept=s'={...s,oldAccepted:true}
  action unsafeHandoff=s'={...s,handed:true}
  run preemptionKeepsGuardTest=init.then(guardEnter).then(rawEnter).then(stutter).expect(safe and s.guard==1 and not(handoffReady))
  run cancelDeferredDuringNativeTest=init.then(guardEnter).then(rawEnter).then(requestCancel).then(rawOk).then(publish).expect(safe and s.pendingCancel and s.guard==1)
  run nestedGuardRestoresOuterTest=init.then(guardEnter).then(guardNest).then(guardUnnest).then(rawEnter).expect(safe and s.guard==1)
  run privateResultNotQueryableTest=init.then(guardEnter).then(rawEnter).then(rawOk).expect(safe and s.phase==2 and not(handoffReady))
  run rawDeathRefusesHandoffTest=init.then(guardEnter).then(rawEnter).then(rawOk).then(ownerStopped).expect(safe and s.charge==2 and s.phase==2 and not(handoffReady))
  run enteredDeathRetainsGrantTest=init.then(guardEnter).then(rawEnter).then(ownerStopped).expect(safe and s.charge==2 and not(handoffReady))
  run publishedDeathServiceRecoveryTest=init.then(publishedOk).then(ownerStopped).then(protect).then(settle).then(handoff).expect(safe and s.handed)
  run publishedFailureRecoveryTest=init.then(publishedFail).then(ownerStopped).then(protect).then(settle).then(handoff).expect(safe and s.handed and s.credits==1)
  run expectedRejectLeavesLedgerTest=init.then(publishedFail).then(txBegin).then(rejectBeforeWrite).expect(safe and s.charge==2 and not(s.applied))
  run retryAfterExpectedRejectTest=init.then(publishedFail).then(txBegin).then(rejectBeforeWrite).then(protect).then(settle).then(guardLeave).expect(safe and s.credits==1)
  run cancelDuringPartialWaitsTest=init.then(publishedFail).then(txBegin).then(partialWrite).then(requestCancel).then(txCommit).then(txUnlock).then(protect).then(guardLeave).expect(safe and s.pendingCancel and s.credits==1)
  run partialDeathPoisonsTest=init.then(publishedFail).then(txBegin).then(partialWrite).then(ownerStopped).expect(safe and s.poison and not(handoffReady))
  run committedLockedDeathRefusesTest=init.then(publishedFail).then(txBegin).then(partialWrite).then(txCommit).then(ownerStopped).expect(safe and s.applied and s.poison and not(handoffReady))
  run unlockedDeathCanRecoverTest=init.then(publishedOk).then(protect).then(settle).then(ownerStopped).then(handoff).expect(safe and s.handed)
  run lostDeliveryDoesNotUndoTest=init.then(complete).then(deliver).then(loseDelivery).then(deliver).expect(safe and s.applied and s.delivered)
  run ackAloneRetainsPinnedTest=init.then(complete).then(pinFirst).then(ackFirst).then(floorFirst).expect(safe and s.record1 and s.pin1==1 and not(canLookup1))
  run pinDrainEnablesReuseTest=init.then(complete).then(pinFirst).then(ackFirst).then(floorFirst).then(dropFirst).then(recycleFirst).expect(safe and not(s.record1))
  run noNewLookupBelowFloorTest=init.then(complete).then(ackFirst).then(floorFirst).expect(safe and not(canLookup1))
  run prefixHoleRetainsSecondTest=init.then(ackSecond).expect(safe and s.floor==0 and s.record2)
  run prefixClosureRecyclesBothTest=init.then(complete).then(ackSecond).then(ackFirst).then(floorSecond).then(recycleFirst).then(recycleSecond).expect(safe and not(s.record1) and not(s.record2))
  run secondPinRetainsRecordTest=init.then(complete).then(pinSecond).then(ackFirst).then(ackSecond).then(floorSecond).expect(safe and s.record2 and s.pin2==1)
  run failureReceiptCanRetireTest=init.then(failComplete).then(ackFirst).then(floorFirst).then(recycleFirst).expect(safe and s.charge==0 and s.credits==1)
  run unknownFirstBlocksPrefixTest=init.then(guardEnter).then(rawEnter).then(rawOk).then(ownerStopped).then(ackSecond).expect(safe and s.floor==0 and s.record1 and s.record2)
  run restoredContextHandoffTest=init.then(complete).then(handoff).expect(safe and s.handed and s.binding and s.root)
  run earlyRestoreCounterexampleTest=init.then(guardEnter).then(rawEnter).then(rawOk).then(unsafeRestore).expect(not(safe))
  run partialUnlockCounterexampleTest=init.then(publishedFail).then(txBegin).then(partialWrite).then(unsafeUnlock).expect(not(safe))
  run pinnedReuseCounterexampleTest=init.then(complete).then(pinFirst).then(ackFirst).then(floorFirst).then(unsafeRecycle).expect(not(safe))
  run staleKeyAcceptCounterexampleTest=init.then(complete).then(ackFirst).then(floorFirst).then(recycleFirst).then(unsafeOldAccept).expect(not(safe))
  run rawGapHandoffCounterexampleTest=init.then(guardEnter).then(rawEnter).then(rawOk).then(ownerStopped).then(unsafeHandoff).expect(not(safe))
}
