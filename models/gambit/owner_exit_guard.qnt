module owner_exit_guard {
  // marker/killed represent logical close only; physical heap clear is outside this model.
  // Three original-owner activations: ___run and two nested SFUNs.
  // Native-only settlement, complete roots, bridge policy and stop are premises.
  type State={top:int,active:Set[int],roots:Set[int],guard:Set[int],marker:int->int,
    phase:int->int,initDuty:int->int,committed:Set[int],resultRoots:Set[int],
    retained:Set[int],killed:int->int,settled:Set[int],previous:int->int,catcher:int,
    packet:int,target:int,chosen:int,fp:int,transportFp:int,stage:int,
    stopped:Set[int],unknown:Set[int],bridges:Set[int],matched:Set[int],
    errorReturned:bool,fatal:bool,owner:int,entryOwner:int,delivered:Set[int]}
  // stage 0 no transport,1 selected packet,2 guard caught,3 duty transferred,
  // 4 marker invalidated,5 catcher restored. packet 1 continuation,2 C error,3 normal.
  var s:State
  val ids=Set(0,1,2)
  val safe=s.active.subseteq(s.roots) and s.active.subseteq(s.guard) and
    s.committed.subseteq(s.resultRoots) and ids.forall(i=>s.killed.get(i)<=1) and
    s.settled.forall(i=>s.marker.get(i)==2 and s.initDuty.get(i)!=1) and
    s.settled.subseteq(s.retained) and
    (s.packet==0 or s.fp==s.transportFp) and
    (s.packet!=1 or s.target==s.chosen) and
    (s.packet!=1 or (not(s.settled.contains(s.target)) and s.marker.get(s.target)==1)) and
    s.matched.forall(i=>s.marker.get(i)==1 or s.settled.contains(i) or (i==s.top and s.stage>=4)) and
    (s.stage<5 or s.catcher==s.previous.get(s.top)) and
    (s.stage<2 or s.owner==s.entryOwner) and (s.stage<2 or s.bridges==Set())
  def canCapture=s.top>=0 and s.stage==1 and s.guard.contains(s.top) and s.bridges==Set() and
    (s.packet==3 or s.packet==2 or s.top>s.target) and s.owner==s.entryOwner
  def canTransfer= s.stage==2 and (s.initDuty.get(s.top)!=1 or s.stopped.contains(s.top)) and
    not(s.unknown.contains(s.top))
  def canMatch=s.packet==1 and s.stage==1 and s.top==s.target and
    s.marker.get(s.top)==1 and s.bridges==Set() and s.owner==s.entryOwner
  action init=s'={top:0,active:Set(0),roots:Set(0),guard:Set(0),marker:Map(0->1,1->0,2->0),
    phase:Map(0->1,1->0,2->0),initDuty:Map(0->0,1->0,2->0),committed:Set(),resultRoots:Set(),
    retained:Set(),killed:Map(0->0,1->0,2->0),settled:Set(),previous:Map(0->(-1),1->0,2->1),catcher:0,
    packet:0,target:(-1),chosen:(-1),fp:0,transportFp:0,stage:0,stopped:Set(),unknown:Set(),bridges:Set(),
    matched:Set(),errorReturned:false,fatal:false,owner:7,entryOwner:7,delivered:Set()}
  action push=all{not(s.fatal),s.packet==0,s.top<2,s.phase.get(s.top+1)==0,
    s'={...s,top:s.top+1,active:s.active.union(Set(s.top+1)),roots:s.roots.union(Set(s.top+1)),
      guard:s.guard.union(Set(s.top+1)),marker:s.marker.set(s.top+1,1),
      phase:s.phase.set(s.top+1,1),catcher:s.top+1}}
  action startInit=all{not(s.fatal),s.packet==0,s.top>=0,s.initDuty.get(s.top)==0,
    not(s.committed.contains(s.top)),s'={...s,initDuty:s.initDuty.set(s.top,1)}}
  action rootResult=all{not(s.fatal),s.packet==0,s.top>=0,s.initDuty.get(s.top)==1,
    s'={...s,resultRoots:s.resultRoots.union(Set(s.top))}}
  action commit=all{not(s.fatal),s.packet==0,s.top>=0,s.initDuty.get(s.top)==1,
    s.resultRoots.contains(s.top),s'={...s,committed:s.committed.union(Set(s.top)),initDuty:s.initDuty.set(s.top,0)}}
  // Scheme winding/handler decisions finish BEFORE this transport selection.
  action selectEscape(t)=all{not(s.fatal),s.packet==0,s.top>t,t>=0,s.marker.get(t)==1,
    s'={...s,packet:1,target:t,chosen:t,fp:100+t,transportFp:100+t,stage:1}}
  action selectError=all{not(s.fatal),s.packet==0,s.top>=0,
    s'={...s,packet:2,target:(-1),chosen:(-1),fp:200,transportFp:200,stage:1}}
  action selectNormal=all{not(s.fatal),s.packet==0,s.top>=0,
    s'={...s,packet:3,target:s.top,chosen:s.top,transportFp:s.fp,stage:1}}
  action capture=all{not(s.fatal),canCapture,s'={...s,stage:2}}
  // END_TRY may restore the catcher before the common no-callback settlement funnel.
  action restoreEarly=all{not(s.fatal),s.stage==2,s'={...s,catcher:s.previous.get(s.top)}}
  action certifyStop=all{not(s.fatal),s.stage==2,not(s.unknown.contains(s.top)),
    s'={...s,stopped:s.stopped.union(Set(s.top))}}
  action transferDuty=all{not(s.fatal),canTransfer,s'={...s,stage:3,
    retained:s.retained.union(Set(s.top)),
    initDuty:s.initDuty.set(s.top,if(s.initDuty.get(s.top)==1)2 else s.initDuty.get(s.top))}}
  action invalidate=all{not(s.fatal),s.stage==3,s.marker.get(s.top)==1,
    s'={...s,stage:4,marker:s.marker.set(s.top,2),killed:s.killed.set(s.top,s.killed.get(s.top)+1)}}
  action restoreCatcher=all{not(s.fatal),s.stage==4,
    s'={...s,stage:5,catcher:s.previous.get(s.top)}}
  action popGuard=all{not(s.fatal),s.stage==5,s.initDuty.get(s.top)!=1,
    s'={...s,active:s.active.exclude(Set(s.top)),guard:s.guard.exclude(Set(s.top)),
      settled:s.settled.union(Set(s.top)),phase:s.phase.set(s.top,2),top:s.top-1,
      stage:if(s.packet==3 or s.top==0)0 else 1,
      packet:if(s.packet==3 or s.top==0)0 else s.packet,
      bridges:if(s.packet!=3 and s.top>0)s.bridges.union(Set(s.top)) else s.bridges,
      errorReturned:s.errorReturned or (s.packet==2 and s.top==0)}}
  // CFUN conversion/AT_END cleanup is a separate qualified bridge, not erased.
  action settleBridge(i)=all{not(s.fatal),s.stage==1,s.bridges.contains(i),
    s'={...s,bridges:s.bridges.exclude(Set(i))}}
  action matchTarget=all{not(s.fatal),canMatch,s'={...s,packet:0,stage:0,matched:s.matched.union(Set(s.top))}}
  action deliver=all{not(s.fatal),s.packet==0,s.top>=0,s.marker.get(s.top)==1,
    s.committed.contains(s.top),s'={...s,delivered:s.delivered.union(Set(s.top))}}
  action query(i)=all{s.committed.contains(i),s'=s}
  action loseStop=all{not(s.fatal),s.stage==2,s'={...s,unknown:s.unknown.union(Set(s.top))}}
  // No return into an unsafe activation is manufactured after an admitted premise fails.
  action failStop=all{not(s.fatal),s.stage==2,s.unknown.contains(s.top),s'={...s,fatal:true}}
  // Internal ___call trampoline trip is consumed locally, never an outer guard exit.
  action trampolineTrip=all{s.packet==0,s.top>=0,s'=s}
  action stutter=s'=s
  action step=any{push,startInit,rootResult,commit,selectEscape(0),selectEscape(1),selectError,
    selectNormal,trampolineTrip,capture,restoreEarly,certifyStop,transferDuty,invalidate,restoreCatcher,popGuard,
    settleBridge(1),settleBridge(2),matchTarget,deliver,query(0),query(1),query(2),loseStop,failStop,stutter}
  action settle=capture.then(certifyStop).then(transferDuty).then(invalidate).then(restoreCatcher).then(popGuard)
  action nested=push.then(push)
  action ready=startInit.then(rootResult).then(commit)
  action unsafeOldFp=s'={...s,fp:999}
  action unsafeKillTarget=s'={...s,marker:s.marker.set(s.target,2)}
  action unsafeDropResult=s'={...s,resultRoots:s.resultRoots.exclude(Set(2))}
  action unsafeSkipDuty=s'={...s,settled:s.settled.union(Set(2)),marker:s.marker.set(2,2)}
  action unsafeDoubleKill=s'={...s,killed:s.killed.set(2,2)}
  action unsafeRestore=s'={...s,stage:5}
  action unsafeChangeDestination=s'={...s,target:1}
  action unsafeStackRootDrop=s'={...s,retained:s.retained.exclude(Set(2))}
  action unsafeSkipBridge=s'={...s,stage:2}
  action unsafeWrongOwner=s'={...s,owner:8,stage:2}
  action badStep=any{step,unsafeOldFp}
  run normalSfunExitTest=init.then(push).then(ready).then(deliver).then(selectNormal).then(settle).expect(safe and s.marker.get(1)==2 and s.top==0)
  run internalTrampolineTripRetainsInvocationTest=init.then(nested).then(startInit).then(trampolineTrip).expect(safe and s.marker.get(2)==1 and s.killed.get(2)==0 and s.initDuty.get(2)==1)
  run normalRunExitTest=init.then(selectNormal).then(settle).expect(safe and s.top==(-1) and not(s.errorReturned))
  run runErrorReturnsCodeTest=init.then(selectError).then(settle).expect(safe and s.top==(-1) and s.errorReturned)
  run childEscapePreservesTargetTest=init.then(nested).then(selectEscape(1)).then(settle).then(settleBridge(2)).then(matchTarget).expect(safe and s.marker.get(1)==1 and s.marker.get(2)==2 and s.top==1)
  run twoLevelEscapeToRunTest=init.then(nested).then(selectEscape(0)).then(settle).then(settleBridge(2)).then(settle).then(settleBridge(1)).then(matchTarget).expect(safe and s.marker.get(0)==1 and s.settled==Set(1,2))
  run targetNormalExitAfterEscapeTest=init.then(nested).then(selectEscape(1)).then(settle).then(settleBridge(2)).then(matchTarget).then(selectNormal).then(settle).expect(safe and s.killed.get(1)==1 and s.killed.get(2)==1)
  run precommitDutyTransfersTest=init.then(nested).then(startInit).then(selectEscape(1)).then(settle).expect(safe and s.initDuty.get(2)==2 and not(s.committed.contains(2)))
  run postcommitResultSurvivesEscapeTest=init.then(nested).then(ready).then(selectEscape(1)).then(settle).then(query(2)).expect(safe and s.committed.contains(2) and s.resultRoots.contains(2))
  run conversionHandlerMayNestBeforeEscapeTest=init.then(push).then(push).then(selectEscape(0)).then(settle).then(settleBridge(2)).expect(safe and s.top==1 and s.target==0)
  run commonPostTrySettlementTest=init.then(nested).then(startInit).then(selectEscape(1)).then(capture).then(restoreEarly).then(certifyStop).then(transferDuty).then(invalidate).then(restoreCatcher).then(popGuard).expect(safe and s.catcher==1 and s.initDuty.get(2)==2)
  run catcherRestoredBeforePropagationTest=init.then(nested).then(selectEscape(0)).then(settle).expect(safe and s.catcher==1 and s.top==1)
  run escapedRootsStayOffStackTest=init.then(nested).then(ready).then(selectEscape(0)).then(settle).expect(safe and s.retained.contains(2) and rootResultAlive)
  val rootResultAlive=s.resultRoots.contains(2)
  run stopUnknownDoesNotTransferTest=init.then(nested).then(startInit).then(selectEscape(0)).then(capture).then(loseStop).expect(safe and not(canTransfer) and s.initDuty.get(2)==1)
  run failedPremiseStopsAdmissionTest=init.then(nested).then(startInit).then(selectEscape(0)).then(capture).then(loseStop).then(failStop).expect(safe and s.fatal and s.top==2 and s.guard.contains(2))
  run bridgeMustFinishBeforeTargetTest=init.then(nested).then(selectEscape(1)).then(settle).expect(safe and not(canMatch) and s.bridges==Set(2))
  run cErrorCrossesBothSfunGuardsTest=init.then(nested).then(ready).then(selectError).then(settle).then(settleBridge(2)).then(settle).then(settleBridge(1)).then(settle).expect(safe and s.errorReturned and s.committed.contains(2))
  run normalCommittedResultNeedsNoRollbackTest=init.then(push).then(ready).then(selectNormal).then(settle).then(query(1)).expect(safe and s.committed.contains(1) and s.resultRoots.contains(1))
  run matchedTargetMayLaterInvalidateDuringOwnExitTest=init.then(nested).then(selectEscape(1)).then(settle).then(settleBridge(2)).then(matchTarget).then(selectNormal).then(capture).then(certifyStop).then(transferDuty).then(invalidate).expect(safe and s.marker.get(1)==2 and not(s.settled.contains(1)))
  run staleChildFpCounterexampleTest=init.then(nested).then(selectEscape(0)).then(unsafeOldFp).expect(not(safe))
  run killedLiveTargetCounterexampleTest=init.then(nested).then(selectEscape(1)).then(unsafeKillTarget).expect(not(safe))
  run discardedCommittedResultCounterexampleTest=init.then(nested).then(ready).then(selectEscape(1)).then(unsafeDropResult).expect(not(safe))
  run escapedInitializerLostCounterexampleTest=init.then(nested).then(startInit).then(selectEscape(1)).then(unsafeSkipDuty).expect(not(safe))
  run doubleMarkerKillCounterexampleTest=init.then(nested).then(selectEscape(1)).then(settle).then(unsafeDoubleKill).expect(not(safe))
  run rethrowToOwnCatcherCounterexampleTest=init.then(nested).then(selectEscape(1)).then(capture).then(unsafeRestore).expect(not(safe))
  run retargetedTransportCounterexampleTest=init.then(nested).then(selectEscape(0)).then(unsafeChangeDestination).expect(not(safe))
  run reclaimedEscapedRootsCounterexampleTest=init.then(nested).then(selectEscape(1)).then(settle).then(unsafeStackRootDrop).expect(not(safe))
  run skippedBridgeCounterexampleTest=init.then(nested).then(selectEscape(0)).then(settle).then(unsafeSkipBridge).expect(not(safe))
  run crossOwnerGuardCounterexampleTest=init.then(nested).then(selectEscape(1)).then(unsafeWrongOwner).expect(not(safe))
}
