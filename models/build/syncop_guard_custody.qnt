module syncop_guard_custody {
 import syncop_guard_parameters.* from "./syncop_guard_parameters"
 pure val Roster=0.to(ParticipantCount-1)
 // One selected GC (direct GC request or resize's nested GC), then a deferred or admitted shrink.
 type State={vmFacilities:bool,kind:int,gcEpoch:int,rootVersion:int,pendingGc:bool,resizeDeferred:bool,phase:int,members:Set[int],service:Set[int],interrupts:Set[int],
  guard:bool,origin:bool,rootReady:bool,stopped:bool,joined:Set[int],reset:Set[int],entered:Set[int],gcReturned:Set[int],
  scanned:bool,cleared:bool,noopArrived:Set[int],noopSelected:bool,syncReturned:Set[int],restored:bool,loaded:int,deferredError:bool,
  marker:bool,markerClosed:bool,terminal:int,error:int,destination:int,catcherRestored:bool,secondary:bool,
  guardSettled:bool,outcomeVm:bool,withdrawn:bool,propagated:bool,pin:bool,reader:bool,unknown:bool,
  ffiOpen:bool,wantShrink:bool,deferred:bool,foreignClosed:bool,foreignDebt:int,
  moved:bool,storageAck:bool,storageUnknown:bool,permit:bool,votes:Set[int],rosterPublished:bool,topologyTails:Set[int],retainedConverged:bool,
  memoryFreed:bool,exitInvoked:bool,joinKnown:bool,joinUnknown:bool,reused:bool}
 pure val initial:State={vmFacilities:true,kind:0,gcEpoch:1,rootVersion:0,pendingGc:true,resizeDeferred:false,phase:0,members:Roster,service:Roster,interrupts:Roster,
  guard:false,origin:true,rootReady:false,stopped:false,joined:Set(),reset:Set(),entered:Set(),gcReturned:Set(),
  scanned:false,cleared:false,noopArrived:Set(),noopSelected:false,syncReturned:Set(),restored:false,loaded:0,deferredError:false,
  marker:false,markerClosed:false,terminal:0,error:0,destination:7,catcherRestored:false,secondary:false,
  guardSettled:false,outcomeVm:false,withdrawn:false,propagated:false,pin:false,reader:false,unknown:false,
  ffiOpen:true,wantShrink:false,deferred:false,foreignClosed:false,foreignDebt:1,
  moved:false,storageAck:false,storageUnknown:false,permit:false,votes:Set(),rosterPublished:false,topologyTails:Set(),retainedConverged:false,
  memoryFreed:false,exitInvoked:false,joinKnown:false,joinUnknown:false,reused:false}
 var s:State
 action init=s'=initial
 action initResize=s'={...initial,kind:1,pendingGc:false}
 action initCollision=s'={...initial,kind:2,pendingGc:true}
 action installGuard=all{s.phase==0,s.ffiOpen,not(s.guard),s'={...s,guard:true}}
 action acquirePin=all{s.guard,s.ffiOpen,not(s.withdrawn),not(s.permit),not(s.memoryFreed),s'={...s,pin:true}}
 action acquireReader=all{s.rootReady,s.ffiOpen,not(s.permit),not(s.withdrawn),s'={...s,reader:true}}
 action publishReady=all{s.guard,s.phase==0,s.origin,not(s.rootReady),s'={...s,rootReady:true,origin:false,stopped:true}}
 action requestSync=all{s.phase==0,s.rootReady,s.stopped,s.service==Roster,s'={...s,phase:1}}
 action join(w)=all{s.phase==1,s.members.contains(w),s.service.contains(w),s.interrupts.contains(w),s'={...s,joined:s.joined.union(Set(w))}}
 action selectGc=all{s.phase==1,s.joined==Roster,s.rootReady,s.stopped,s'={...s,phase:2}}
 action resetFlag(w)=all{s.phase==2,s.joined.contains(w),s'={...s,reset:s.reset.union(Set(w))}}
 action enterGc(w)=all{s.phase==2,s.reset.contains(w),s'={...s,entered:s.entered.union(Set(w))}}
 action scanOwnerRoot=all{s.phase==2,s.entered==Roster,s.rootReady,s'={...s,scanned:true,rootVersion:s.gcEpoch}}
 action returnGc(w)=all{s.phase==2,s.scanned,s.entered.contains(w),s'={...s,gcReturned:s.gcReturned.union(Set(w))}}
 // A selected resize cannot wait for the guard whose caller is blocked in this loop.
 action decideSelectedResize=all{s.phase==2,s.gcReturned==Roster,
  if(s.kind==0) s'=s else s'={...s,resizeDeferred:true,deferred:true,wantShrink:true,ffiOpen:false}}
 action reselectPendingGc=all{s.phase==2,s.kind==2,s.resizeDeferred,s.pendingGc,s.gcReturned==Roster,
  s'={...s,kind:0,gcEpoch:s.gcEpoch+1,entered:Set(),gcReturned:Set(),scanned:false,cleared:false,noopArrived:Set()}}
 action acknowledgeRequest=all{s.phase==2,s.gcReturned.contains(1),s.kind==0 or (s.kind==1 and s.resizeDeferred),s'={...s,cleared:true,pendingGc:false}}
 action arriveNoop(w)=all{s.phase==2,s.gcReturned.contains(w),s.cleared,s'={...s,noopArrived:s.noopArrived.union(Set(w))}}
 action chooseNoop=all{s.phase==2,not(s.pendingGc),s.noopArrived==Roster,s.reset==Roster,s'={...s,phase:3,noopSelected:true}}
 action returnSync(w)=all{s.phase==3,s.noopSelected,s.noopArrived.contains(w),s'={...s,syncReturned:s.syncReturned.union(Set(w))}}
 action recordDeferredError=all{s.phase==2,s.rootReady,s'={...s,deferredError:true,error:23}}
 action catchLoopFailure=all{s.phase==3,s.syncReturned.contains(1),s.deferredError,s.terminal==0,s.guard,s.rootReady,
  s'={...s,terminal:2,error:23,destination:7}}
 action restoreOwner=all{s.phase==3,not(s.deferredError),s.syncReturned.contains(1),s.members.contains(1),s.interrupts.contains(1),s.rootReady,s.scanned,s.terminal==0,
  s'={...s,restored:true,loaded:s.rootVersion,stopped:false}}
 action allocateMarker=all{s.restored,s.loaded==s.rootVersion,s.terminal==0,not(s.marker),s'={...s,marker:true}}
 action normalReturn=all{s.restored,s.marker,s.terminal==0,s'={...s,terminal:1}}
 action catchThrow=all{s.guard,s.restored,s.terminal==0,s'={...s,terminal:2,error:23,destination:7}}
 action restoreCatcher=all{s.terminal!=0,s'={...s,catcherRestored:true}}
 action closeMarker=all{s.terminal!=0,s.catcherRestored,s'={...s,marker:false,markerClosed:true}}
 action recordSecondary=all{s.terminal==2,not(s.permit),s'={...s,secondary:true}}
 action failNormalCleanup=all{s.terminal==1,not(s.guardSettled),s.rootReady,s'={...s,terminal:2,error:23,destination:7}}
 action settleGuard=all{s.terminal!=0,s.catcherRestored,s.markerClosed,not(s.unknown),s'={...s,guardSettled:true}}
 action handoffOutcome=all{s.guardSettled,s.rootReady,s.terminal!=0,not(s.unknown),s'={...s,outcomeVm:true}}
 action withdrawRoot=all{s.guardSettled,s.outcomeVm,not(s.pin),not(s.reader),not(s.unknown),s.syncReturned==Roster,
  s'={...s,rootReady:false,withdrawn:true}}
 action propagate=all{s.terminal==2,s.guardSettled,s.catcherRestored,s.markerClosed,s.outcomeVm,s.error==23,s.destination==7,s'={...s,propagated:true}}
 action markUnknown=all{s.guard,s.terminal!=0,not(s.permit),not(s.withdrawn),s'={...s,unknown:true}}
 action settleUnknown=all{s.unknown,s.terminal!=0,s'={...s,unknown:false}}
 action releasePin=all{s.terminal!=0,not(s.unknown),not(s.memoryFreed),s'={...s,pin:false}}
 action releaseReader=all{s.reader,s'={...s,reader:false}}
 action requestShrink=all{not(s.rosterPublished),s'={...s,wantShrink:true,ffiOpen:false}}
 action deferShrink=all{s.wantShrink,not(s.permit),s'={...s,deferred:true}}
 // Receipt from foreign release coordinator, not an execution of arbitrary destructors in this model.
 action drainForeign=all{s.guardSettled,s.outcomeVm,s.syncReturned==Roster,s.interrupts.contains(1),not(s.unknown),s'={...s,foreignClosed:true,foreignDebt:0}}
 action commitStorageMove=all{not(s.moved),s.withdrawn,s.guardSettled,not(s.pin),not(s.reader),not(s.unknown),s.syncReturned==Roster,s.foreignClosed,s.foreignDebt==0,
  s'={...s,moved:true,storageAck:false}}
 action acknowledgeStorage=all{s.moved,s'={...s,storageAck:true,storageUnknown:false}}
 action loseStorageReply=all{s.moved,not(s.permit),s'={...s,storageAck:false,storageUnknown:true}}
 def exitReady=s.wantShrink and not(s.ffiOpen) and s.syncReturned==Roster and s.guardSettled and s.outcomeVm and s.withdrawn and
  not(s.pin) and not(s.reader) and not(s.unknown) and s.foreignClosed and s.foreignDebt==0 and s.moved and s.storageAck and not(s.storageUnknown)
 action permitExit=all{exitReady,s.interrupts.contains(1),s'={...s,permit:true}}
 action vote(w)=all{s.permit,s.members.contains(w),s'={...s,votes:s.votes.union(Set(w))}}
 action publishRoster=all{s.permit,s.votes==Roster,s.members==Roster,s'={...s,members:Set(0),rosterPublished:true}}
 action finishTopologyTail(w)=all{s.rosterPublished,Roster.contains(w),s'={...s,topologyTails:s.topologyTails.union(Set(w))}}
 action convergeRetained=all{s.rosterPublished,s.topologyTails==Roster,s'={...s,retainedConverged:true}}
 action disableInterrupts=all{s.permit,s.rosterPublished,s.retainedConverged,s.topologyTails==Roster,not(s.members.contains(1)),s'={...s,interrupts:s.interrupts.exclude(Set(1)),service:s.service.exclude(Set(1))}}
 action cleanupInertRc=all{not(s.memoryFreed),s.permit,s.rosterPublished,not(s.interrupts.contains(1)),exitReady,s'={...s,memoryFreed:true}}
 action invokeExit=all{not(s.exitInvoked),s.memoryFreed,s'={...s,exitInvoked:true}}
 action joinSucceeded=all{s.exitInvoked,s'={...s,joinKnown:true,joinUnknown:false}}
 action joinUnresolved=all{s.exitInvoked,not(s.joinKnown),s'={...s,joinUnknown:true}}
 action reuseSlot=all{not(s.reused),s.joinKnown,not(s.joinUnknown),s'={...s,reused:true}}
 def safe=((s.rootReady or s.outcomeVm or s.phase==1 or s.phase==2) implies s.vmFacilities) and
  (s.noopSelected implies not(s.pendingGc) and s.cleared) and
  (s.cleared and s.kind==1 implies s.resizeDeferred) and s.joined.subseteq(Roster) and s.reset.subseteq(s.joined) and s.entered.subseteq(s.reset) and s.gcReturned.subseteq(s.entered) and
  s.noopArrived.subseteq(s.gcReturned) and s.syncReturned.subseteq(s.noopArrived) and
  (s.phase==1 or s.phase==2 implies s.service==Roster and s.interrupts==Roster and s.members==Roster) and
  (s.phase==2 implies s.rootReady and s.stopped and s.joined==Roster) and
  (s.syncReturned!=Set() implies s.noopSelected and s.reset==Roster and s.gcReturned==Roster and s.cleared) and
  (s.restored implies not(s.deferredError) and s.syncReturned.contains(1) and s.scanned and s.loaded==s.rootVersion) and
  (s.guard and not(s.guardSettled) implies s.origin or s.rootReady) and
  (s.guardSettled implies s.terminal!=0 and s.catcherRestored and s.markerClosed) and
  (s.withdrawn implies s.guardSettled and s.outcomeVm and not(s.pin) and not(s.reader) and not(s.rootReady)) and
  (s.terminal==2 implies s.error==23 and s.destination==7) and
  (s.propagated implies s.phase==3 and s.syncReturned.contains(1) and s.guardSettled and s.outcomeVm and s.catcherRestored and s.error==23 and s.destination==7) and
  (s.permit implies exitReady) and
  (s.rosterPublished implies s.permit and s.votes==Roster and s.members==Set(0)) and
  (not(s.rosterPublished) implies s.members==Roster) and
  (not(s.interrupts.contains(1)) implies s.permit and s.rosterPublished and s.retainedConverged and s.topologyTails==Roster) and
  (s.memoryFreed implies s.permit and exitReady and not(s.interrupts.contains(1)) and s.rosterPublished) and
  (s.joinKnown implies s.exitInvoked) and (s.reused implies s.joinKnown and not(s.joinUnknown))
 action step={nondet w=Roster.oneOf();any{installGuard,acquirePin,acquireReader,publishReady,requestSync,join(w),selectGc,resetFlag(w),enterGc(w),scanOwnerRoot,returnGc(w),decideSelectedResize,reselectPendingGc,acknowledgeRequest,arriveNoop(w),chooseNoop,returnSync(w),recordDeferredError,catchLoopFailure,restoreOwner,allocateMarker,normalReturn,catchThrow,restoreCatcher,closeMarker,recordSecondary,failNormalCleanup,settleGuard,handoffOutcome,withdrawRoot,propagate,markUnknown,settleUnknown,releasePin,releaseReader,requestShrink,deferShrink,drainForeign,commitStorageMove,acknowledgeStorage,loseStorageReply,permitExit,vote(w),publishRoster,finishTopologyTail(w),convergeRetained,disableInterrupts,cleanupInertRc,invokeExit,joinSucceeded,joinUnresolved,reuseSlot,s'=s}}
 action ready=installGuard.then(publishReady).then(requestSync)
 action innerBody=join(0).then(join(1)).then(selectGc).then(resetFlag(0)).then(resetFlag(1)).then(enterGc(0)).then(enterGc(1)).then(scanOwnerRoot).then(returnGc(0)).then(returnGc(1))
 action gcBody=innerBody.then(decideSelectedResize).then(acknowledgeRequest)
 action finishLoopOnly=arriveNoop(0).then(arriveNoop(1)).then(chooseNoop).then(returnSync(0)).then(returnSync(1))
 action finishLoop=finishLoopOnly.then(restoreOwner)
 action normal=ready.then(gcBody).then(finishLoop).then(allocateMarker).then(normalReturn).then(restoreCatcher).then(closeMarker).then(settleGuard).then(handoffOutcome)
 action thrown=ready.then(gcBody).then(finishLoop).then(allocateMarker).then(catchThrow).then(restoreCatcher).then(closeMarker).then(settleGuard).then(handoffOutcome)
 action transfer=withdrawRoot.then(drainForeign).then(commitStorageMove).then(acknowledgeStorage)
 action shrink=requestShrink.then(permitExit).then(vote(0)).then(vote(1)).then(publishRoster).then(finishTopologyTail(0)).then(finishTopologyTail(1)).then(convergeRetained).then(disableInterrupts).then(cleanupInertRc).then(invokeExit)
 action forceDestroyVm=s'={...s,vmFacilities:false}
 action forceNoop=s'={...s,phase:3,noopSelected:true,cleared:true}
 action forceSleep=s'={...s,service:Set(0)}
 action forceReturn=s'={...s,syncReturned:Set(1)}
 action forceResetSkip=s'={...s,entered:s.entered.union(Set(1))}
 action forceRestore=s'={...s,restored:true,loaded:1}
 action forceClearRoot=s'={...s,rootReady:false,origin:false}
 action forceSettle=s'={...s,guardSettled:true}
 action forceErrorOverwrite=s'={...s,error:99}
 action forcePropagate=s'={...s,propagated:true}
 action forceDisable=s'={...s,interrupts:Set(0)}
 action forceFree=s'={...s,memoryFreed:true}
 action forcePermit=s'={...s,permit:true}
 action forcePublish=s'={...s,members:Set(0),rosterPublished:true}
 action forceReuse=s'={...s,reused:true}
 action forceLateForeign=s'={...s,foreignDebt:s.foreignDebt+1}
 run nonzeroParticipantTest=init.then(ready).then(gcBody).expect(safe and s.gcReturned==Roster and s.syncReturned==Set())
 run loopReturnTest=init.then(ready).then(gcBody).then(finishLoop).expect(safe and s.restored and s.members==Roster)
 run resizeNestedGcTest=initResize.then(ready).then(gcBody).then(finishLoop).expect(safe and s.kind==1)
 run deferredLoopFailureTest=init.then(ready).then(gcBody).then(recordDeferredError).then(finishLoopOnly).then(catchLoopFailure).then(restoreCatcher).then(closeMarker).then(settleGuard).then(handoffOutcome).then(propagate).expect(safe and not(s.restored) and s.error==23)
 run priorityCollisionTest=initCollision.then(ready).then(innerBody).then(decideSelectedResize).then(reselectPendingGc).then(enterGc(0)).then(enterGc(1)).then(scanOwnerRoot).then(returnGc(0)).then(returnGc(1)).then(acknowledgeRequest).then(finishLoop).expect(safe and s.gcEpoch==2 and s.loaded==2 and s.resizeDeferred)
 run normalGuardTest=init.then(normal).expect(safe and s.guardSettled and not(s.marker))
 run cleanupFailureBecomesErrorTest=init.then(ready).then(gcBody).then(finishLoop).then(allocateMarker).then(normalReturn).then(restoreCatcher).then(closeMarker).then(failNormalCleanup).then(settleGuard).then(handoffOutcome).then(propagate).expect(safe and s.terminal==2)
 run exactUnwindTest=init.then(thrown).then(recordSecondary).then(propagate).expect(safe and s.error==23 and s.destination==7 and s.secondary)
 run propagateBeforeStorageFreeTest=init.then(thrown).then(propagate).expect(safe and s.rootReady and not(s.memoryFreed))
 run deferWhileGcTest=init.then(ready).then(requestShrink).then(deferShrink).then(gcBody).then(finishLoop).expect(safe and s.members==Roster and not(s.memoryFreed))
 run pinRetainedGuardTest=init.then(installGuard).then(acquirePin).then(publishReady).then(requestSync).then(gcBody).then(finishLoop).then(catchThrow).then(restoreCatcher).then(closeMarker).then(settleGuard).then(handoffOutcome).then(propagate).expect(safe and s.pin and s.rootReady)
 run unknownTransferTest=init.then(normal).then(withdrawRoot).then(drainForeign).then(commitStorageMove).then(loseStorageReply).expect(safe and s.moved and not(s.storageAck) and not(s.permit))
 run queryTransferTest=init.then(normal).then(transfer).then(loseStorageReply).then(acknowledgeStorage).then(shrink).then(joinSucceeded).then(reuseSlot).expect(safe and s.reused)
 run knownJoinTest=init.then(thrown).then(propagate).then(transfer).then(shrink).then(joinSucceeded).expect(safe and s.memoryFreed and s.joinKnown)
 run unknownJoinTest=init.then(normal).then(transfer).then(shrink).then(joinUnresolved).expect(safe and not(s.reused) and s.joinUnknown)
 run vmFacilityCustodyControlTest=init.then(normal).then(forceDestroyVm).expect(not(safe))
 run internalGcNotRequestCompletionControlTest=initCollision.then(ready).then(innerBody).then(decideSelectedResize).then(forceNoop).expect(not(safe))
 run collectiveUnwindControlTest=init.then(ready).then(gcBody).then(recordDeferredError).then(forcePropagate).expect(not(safe))
 run ignoreDeferredErrorControlTest=init.then(ready).then(gcBody).then(recordDeferredError).then(finishLoopOnly).then(forceRestore).expect(not(safe))
 run sleepingParticipantControlTest=init.then(ready).then(forceSleep).expect(not(safe))
 run returnBeforeNoopControlTest=init.then(ready).then(gcBody).then(forceReturn).expect(not(safe))
 run skipFlagResetControlTest=init.then(ready).then(join(0)).then(join(1)).then(selectGc).then(forceResetSkip).expect(not(safe))
 run restoreBeforeLoopControlTest=init.then(ready).then(gcBody).then(forceRestore).expect(not(safe))
 run rootDroppedDuringGcControlTest=init.then(ready).then(forceClearRoot).expect(not(safe))
 run guardBeforeCatcherControlTest=init.then(ready).then(gcBody).then(finishLoop).then(catchThrow).then(forceSettle).expect(not(safe))
 run overwriteOriginalErrorControlTest=init.then(thrown).then(forceErrorOverwrite).expect(not(safe))
 run propagateBeforeCustodyControlTest=init.then(ready).then(gcBody).then(finishLoop).then(catchThrow).then(forcePropagate).expect(not(safe))
 run disableBeforePermitControlTest=init.then(normal).then(forceDisable).expect(not(safe))
 run cleanupWithPinControlTest=init.then(normal).then(acquirePin).then(forceFree).expect(not(safe))
 run unknownStoragePermitControlTest=init.then(normal).then(withdrawRoot).then(drainForeign).then(commitStorageMove).then(loseStorageReply).then(requestShrink).then(forcePermit).expect(not(safe))
 run incompleteVoteControlTest=init.then(normal).then(transfer).then(requestShrink).then(permitExit).then(vote(0)).then(forcePublish).expect(not(safe))
 run messageTailRetirementControlTest=init.then(normal).then(transfer).then(requestShrink).then(permitExit).then(vote(0)).then(vote(1)).then(publishRoster).then(forceDisable).expect(not(safe))
 run lateForeignAfterPermitControlTest=init.then(normal).then(transfer).then(requestShrink).then(permitExit).then(forceLateForeign).expect(not(safe))
 run unknownJoinReuseControlTest=init.then(normal).then(transfer).then(shrink).then(joinUnresolved).then(forceReuse).expect(not(safe))
}
