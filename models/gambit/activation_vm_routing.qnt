// Fixed origin journals and direct canonical locators; resident router anchor is outside cleanup.
module activation_vm_routing {
 val W=2
 val K=3
 val E=2
 val Origins=Set(0,1)
 val Keys=0.to(K*E-1)
 type S={phase:int,epoch:int,vmGen:int,data:bool,ready:bool,adminCredit:bool,adminDone:bool,
  next:int,floor:int,op:int->int,serial:int->int,locator:int->int,parent:int->int,seen:Set[int],homeRoot:Set[int],
  issued:Set[int],records:Set[int],source:Set[int],roots:Set[int],needed:Set[int],terminal:Set[int],settled:Set[int],
  owner:int->int,stamp:int->int,closed:Set[int],escrow:Set[int],sourceAck:Set[int],resultAck:Set[int],
  cellPins:Set[int],gc:bool,scan:Set[int],sourceScan:Set[int],effects:int->int,
  routerPin:bool,pinEpoch:int,pinVm:int,pinMode:int,readEpoch:int,readPinEpoch:int,unsafeReads:int,
  effectPhase:int,allocations:int,originOom:int,rejections:int}
 var s:S
 // phase0 offline,1 starting,2 online,3 quiescing/status-only,4 detached pending reader drain.
 action init=s'={phase:0,epoch:0,vmGen:0,data:false,ready:false,adminCredit:false,adminDone:false,next:0,floor:0,
  op:Origins.mapBy(_=>0),serial:Origins.mapBy(_=>0),locator:Origins.mapBy(_=>-1),parent:Origins.mapBy(_=>-1),seen:Set(),homeRoot:Set(),
  issued:Set(),records:Set(),source:Set(),roots:Set(),needed:Set(),terminal:Set(),settled:Set(),owner:Keys.mapBy(_=>-1),stamp:Keys.mapBy(_=>-1),
  closed:Set(),escrow:Set(),sourceAck:Set(),resultAck:Set(),cellPins:Set(),gc:false,scan:Set(),sourceScan:Set(),effects:Keys.mapBy(_=>0),
  routerPin:false,pinEpoch:0,pinVm:0,pinMode:0,readEpoch:0,readPinEpoch:0,unsafeReads:0,effectPhase:0,allocations:0,originOom:0,rejections:0}
 def current(k:int):bool=k/K+1==s.epoch
 def located(o:int):bool={val k=s.locator.get(o)
   k>=0 and s.records.contains(k) and current(k) and s.owner.get(k)==o and s.stamp.get(k)==s.serial.get(o)}
 action startSetup=all{s.phase==0,not(s.data),not(s.routerPin),s.epoch<E,s.records.size()==0,
   s'={...s,phase:1,epoch:s.epoch+1,vmGen:s.vmGen+1,next:0,floor:0,op:Origins.mapBy(_=>0),serial:Origins.mapBy(_=>0),locator:Origins.mapBy(_=>-1),parent:Origins.mapBy(_=>-1),seen:Set(),homeRoot:Set(),adminDone:false}}
 action initializeVm=all{s.phase==1,not(s.data),s'={...s,data:true,adminCredit:true}}
 action setupFail=all{s.phase==1,not(s.routerPin),s.records.size()==0,s'={...s,phase:0,data:false,ready:false,adminCredit:false}}
 action publishVm=all{s.phase==1,s.data,s.adminCredit,s'={...s,phase:2,ready:true}}
 action rejectRepeatedSetup=all{s.phase!=0,s'={...s,rejections:s.rejections+1}}
 // Each base/parent origin journal is pre-admitted. Nested origin1 needs live origin0.
 action prepare(o:int):bool=all{s.phase==2,s.ready,s.op.get(o)==0,s.serial.get(o)<2,
   o==0 or s.op.get(0)==3,
   s'={...s,op:s.op.set(o,1),serial:s.serial.set(o,s.serial.get(o)+1),locator:s.locator.set(o,-1),parent:s.parent.set(o,if(o==1)s.locator.get(0) else -1),homeRoot:s.homeRoot.union(Set(o)),seen:s.seen.exclude(Set(o))}}
 action failBeforeBind(o:int):bool=all{s.op.get(o)==1,s'={...s,op:s.op.set(o,0),parent:s.parent.set(o,-1),homeRoot:s.homeRoot.exclude(Set(o)),originOom:s.originOom+1}}
 // This atomic abstract transaction includes record + authoritative journal locator, before any effect.
 action claimBind(o:int):bool=all{s.phase==2,s.ready,s.op.get(o)==1,s.homeRoot.contains(o),s.next<K,s.next-s.floor<W,
   val k=(s.epoch-1)*K+s.next
   s'={...s,next:s.next+1,op:s.op.set(o,2),locator:s.locator.set(o,k),issued:s.issued.union(Set(k)),records:s.records.union(Set(k)),
    owner:s.owner.set(k,o),stamp:s.stamp.set(k,s.serial.get(o)),source:s.source.union(Set(k)),needed:s.needed.union(Set(k)),allocations:s.allocations+1}}
 action finishBind(o:int):bool=all{s.op.get(o)==2,located(o),s'={...s,op:s.op.set(o,3)}}
 action loseReturn(o:int):bool=all{s.op.get(o)>=2,s'={...s,seen:s.seen.exclude(Set(o))}}
 action queryOrigin(o:int,tokenSerial:int):bool=all{s.data,s.homeRoot.contains(o),
  if(tokenSerial==s.serial.get(o) and s.op.get(o)>=2 and located(o)) s'={...s,seen:s.seen.union(Set(o))}
  else s'={...s,rejections:s.rejections+1}}
 action findByOrigin(o:int):bool=all{s.op.get(o)>=2,located(o),queryOrigin(o,s.serial.get(o))}

 action retryClaim(o:int):bool=all{s.op.get(o)>=2,located(o),s'=s}
 action routeEnvelope(tokenEpoch:int,tokenVm:int,mode:int):bool=all{not(s.routerPin),
  if(s.ready and tokenEpoch==s.epoch and tokenVm==s.vmGen and (s.phase==2 or (s.phase==3 and mode==2)))
   s'={...s,routerPin:true,pinEpoch:tokenEpoch,pinVm:tokenVm,pinMode:mode}
  else s'={...s,rejections:s.rejections+1}}
 action pinRoute(mode:int):bool=all{s.ready,(s.phase==2 or (s.phase==3 and mode==2)),routeEnvelope(s.epoch,s.vmGen,mode)}
 action unpinRoute=all{s.routerPin,s'={...s,routerPin:false}}
 action readPinned=all{s.routerPin,s.data,s.pinEpoch==s.epoch,s.pinVm==s.vmGen,
   s'={...s,readEpoch:s.epoch,readPinEpoch:s.pinEpoch}}
 action rejectOldEnvelope=all{s.epoch>1,routeEnvelope(s.epoch-1,s.vmGen-1,1)}
 action rejectNoVm=all{not(s.ready),routeEnvelope(s.epoch,s.vmGen,1)}
 action pinCell(o:int):bool=all{s.routerPin,s.data,s.op.get(o)>=2,located(o),
   s'={...s,cellPins:s.cellPins.union(Set(s.locator.get(o)))}}
 action unpinCell(o:int):bool=all{s.cellPins.contains(s.locator.get(o)),s'={...s,cellPins:s.cellPins.exclude(Set(s.locator.get(o)))}}
 action accept(o:int):bool=all{s.phase==2,s.ready,s.routerPin,s.pinMode==1,s.op.get(o)==3,located(o),not(s.gc),
   s.source.contains(s.locator.get(o)),not(s.closed.contains(s.locator.get(o))),s.effects.get(s.locator.get(o))==0,
   s'={...s,roots:s.roots.union(Set(s.locator.get(o))),effects:s.effects.set(s.locator.get(o),1),effectPhase:s.phase}}
 action closeActivation(o:int):bool=all{s.op.get(o)>=2,located(o),s'={...s,closed:s.closed.union(Set(s.locator.get(o)))}}
 action takeEscrow(o:int):bool=all{s.op.get(o)>=2,located(o),s'={...s,escrow:s.escrow.union(Set(s.locator.get(o)))}}
 action exceptionalExit(o:int):bool=all{s.op.get(o)>=2,located(o),s.escrow.contains(s.locator.get(o)),s.closed.contains(s.locator.get(o)),s'=s}
 action terminalOutcome(o:int):bool=all{located(o),not(s.gc),s.closed.contains(s.locator.get(o)),
   s'={...s,terminal:s.terminal.union(Set(s.locator.get(o))),needed:s.needed.exclude(Set(s.locator.get(o))),roots:s.roots.exclude(Set(s.locator.get(o)))}}
 action sourceAck(o:int):bool=all{located(o),s.roots.contains(s.locator.get(o)) or s.terminal.contains(s.locator.get(o)),s'={...s,sourceAck:s.sourceAck.union(Set(s.locator.get(o)))}}
 action releaseSource(o:int):bool=all{located(o),s.sourceAck.contains(s.locator.get(o)),not(s.sourceScan.contains(s.locator.get(o))),s'={...s,source:s.source.exclude(Set(s.locator.get(o)))}}
 action ackResult(o:int):bool=all{located(o),s.terminal.contains(s.locator.get(o)),s'={...s,resultAck:s.resultAck.union(Set(s.locator.get(o)))}}
 action retire(o:int):bool=all{located(o),Origins.forall(child=>s.parent.get(child)!=s.locator.get(o)),s.closed.contains(s.locator.get(o)),s.terminal.contains(s.locator.get(o)),s.sourceAck.contains(s.locator.get(o)),s.resultAck.contains(s.locator.get(o)),not(s.source.contains(s.locator.get(o))),not(s.cellPins.contains(s.locator.get(o))),not(s.scan.contains(s.locator.get(o))),
   s'={...s,records:s.records.exclude(Set(s.locator.get(o))),settled:s.settled.union(Set(s.locator.get(o))),op:s.op.set(o,0),locator:s.locator.set(o,-1),parent:s.parent.set(o,-1),homeRoot:s.homeRoot.exclude(Set(o)),seen:s.seen.exclude(Set(o))}}
 action advance=all{s.floor<s.next,s.settled.contains((s.epoch-1)*K+s.floor),s'={...s,floor:s.floor+1}}
 action closeGc=all{s.data,(s.phase==2 or s.phase==3),not(s.gc),s'={...s,gc:true,scan:s.source.union(s.roots),sourceScan:s.source}}
 action endGc=all{s.gc,s'={...s,gc:false,scan:Set(),sourceScan:Set()}}
 action beginCleanup=all{s.phase==2,s'={...s,phase:3}}
 // Dedicated preallocated teardown lane is not subject to ordinary request admission.
 action adminProgress=all{s.phase==3,s.data,s.adminCredit,s'=s}
 action adminUnknown=all{s.phase==3,s.data,s.adminCredit,s'=s}
 // External membership/teardown result receipt; not inferred from resize return, ignored join, or setup_state.
 action ackAdmin=all{s.phase==3,s.data,s.adminCredit,s'={...s,adminDone:true,adminCredit:false}}
 action discardPrepared(o:int):bool=all{s.phase==3,s.op.get(o)==1,s'={...s,op:s.op.set(o,0),parent:s.parent.set(o,-1),homeRoot:s.homeRoot.exclude(Set(o))}}
 action detach=all{s.phase==3,s.adminDone,s.records.size()==0,s.homeRoot.size()==0,Origins.forall(o=>s.op.get(o)==0),not(s.gc),s.cellPins.size()==0,
   s'={...s,phase:4,ready:false}}
 action freeVm=all{s.phase==4,not(s.routerPin),s'={...s,phase:0,data:false}}
 action idle=s'=s
 val safe=all{s.epoch<=E,s.vmGen==s.epoch,s.floor<=s.next,s.next<=K,s.next-s.floor<=W,s.records.size()<=W,
   s.issued.size()==s.allocations,Origins.forall(o=>s.parent.get(o)<0 or s.records.contains(s.parent.get(o))),s.needed.subseteq(s.source.union(s.roots)),s.sourceScan.subseteq(s.source),s.scan.subseteq(s.source.union(s.roots)),
   s.roots.subseteq(s.records),s.cellPins.subseteq(s.records),
   Origins.forall(o=>s.op.get(o)<2 or located(o)),
   s.records.forall(k=>s.op.get(s.owner.get(k))>=2 and s.locator.get(s.owner.get(k))==k and s.stamp.get(k)==s.serial.get(s.owner.get(k))),
   s.records.forall(k=>current(k)),
   s.settled.forall(k=>s.closed.contains(k) and s.sourceAck.contains(k) and s.resultAck.contains(k)),
   not(s.routerPin) or (s.data and s.pinEpoch==s.epoch and s.pinVm==s.vmGen),
   s.readEpoch==s.readPinEpoch,s.unsafeReads==0,(s.effectPhase==0 or s.effectPhase==2),
   s.phase!=0 or (not(s.data) and not(s.ready) and s.records.size()==0),
   s.phase!=1 or not(s.ready),s.phase!=2 or (s.ready and s.data),
   s.phase!=4 or (not(s.ready) and s.records.size()==0 and s.homeRoot.size()==0),
   s.ready or s.phase!=3,
   Keys.forall(k=>s.effects.get(k)<=1)}
 action step=any{startSetup,initializeVm,setupFail,publishVm,rejectRepeatedSetup,pinRoute(1),pinRoute(2),unpinRoute,readPinned,rejectOldEnvelope,rejectNoVm,
  closeGc,endGc,beginCleanup,adminProgress,adminUnknown,ackAdmin,detach,freeVm,advance,idle,
  nondet o=Origins.oneOf()
  any{prepare(o),failBeforeBind(o),claimBind(o),finishBind(o),loseReturn(o),findByOrigin(o),retryClaim(o),pinCell(o),unpinCell(o),accept(o),closeActivation(o),takeEscrow(o),exceptionalExit(o),terminalOutcome(o),sourceAck(o),releaseSource(o),ackResult(o),retire(o),discardPrepared(o)}}
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action online=init.then(startSetup).then(initializeVm).then(publishVm)
 action bound=online.then(prepare(0)).then(claimBind(0)).then(finishBind(0))
 action accepted=bound.then(pinRoute(1)).then(accept(0)).then(unpinRoute)
 action finish(o:int):bool=closeActivation(o).then(terminalOutcome(o)).then(sourceAck(o)).then(releaseSource(o)).then(ackResult(o)).then(retire(o))
 action clean=beginCleanup.then(ackAdmin).then(detach).then(freeVm)
 action restarted=online.then(clean).then(startSetup).then(initializeVm).then(publishVm)
 action badDuplicateClaim=s'={...s,allocations:s.allocations+1}
 action badLostLocator=s'={...s,locator:s.locator.set(0,-1)}
 action badSerialReuse=s'={...s,serial:s.serial.set(0,s.serial.get(0)+1)}
 action badFreePinned=s'={...s,data:false,phase:0,ready:false}
 action badEarlyDetach=s'={...s,phase:4,ready:false}
 action badResetAnchor=s'={...s,epoch:0}
 action badOldRead=s'={...s,readEpoch:s.epoch,readPinEpoch:s.epoch-1,unsafeReads:s.unsafeReads+1}
 action badEarlySource=s'={...s,source:Set()}
 action badEraseResult=s'={...s,records:Set(),settled:s.settled.union(s.records),op:Origins.mapBy(_=>0),locator:Origins.mapBy(_=>-1),homeRoot:Set()}
 run lostBindReturnUsesExistingJournalTest=bound.then(loseReturn(0)).then(findByOrigin(0)).then(retryClaim(0)).then(check)
 run lostPartialBindCompletesSameSlotTest=online.then(prepare(0)).then(claimBind(0)).then(loseReturn(0)).then(findByOrigin(0)).then(finishBind(0)).then(check)
 run duplicateRegisterOneEffectTest=accepted.then(loseReturn(0)).then(findByOrigin(0)).then(retryClaim(0)).then(check)
 run nestedOriginsHaveSeparateLocatorsTest=bound.then(prepare(1)).then(claimBind(1)).then(finishBind(1)).then(findByOrigin(0)).then(findByOrigin(1)).then(check)
 run originOomHasNoIssuedRequestTest=online.then(prepare(0)).then(failBeforeBind(0)).then(check)
 run partialBindExceptionEscrowTest=online.then(prepare(0)).then(claimBind(0)).then(takeEscrow(0)).then(closeActivation(0)).then(exceptionalExit(0)).then(findByOrigin(0)).then(finishBind(0)).then(finish(0)).then(check)
 run gcCloseRetainsPartialBindSourceTest=online.then(prepare(0)).then(claimBind(0)).then(closeGc).then(findByOrigin(0)).then(finishBind(0)).then(endGc).then(check)
 run gcScanRetainsSourceAfterAckTest=accepted.then(closeGc).then(sourceAck(0)).then(check)
 run closingRejectsRepeatedSetupTest=online.then(beginCleanup).then(rejectRepeatedSetup).then(check)
 run onlineRejectsRepeatedSetupTest=online.then(rejectRepeatedSetup).then(check)
 run setupFailureConsumesEpochTest=init.then(startSetup).then(initializeVm).then(setupFail).then(startSetup).then(initializeVm).then(publishVm).then(rejectOldEnvelope).then(check)
 run cleanRestartRejectsOldEnvelopeTest=restarted.then(rejectOldEnvelope).then(check)
 run routePinSurvivesLogicalDetachTest=online.then(pinRoute(2)).then(beginCleanup).then(ackAdmin).then(detach).then(readPinned).then(unpinRoute).then(freeVm).then(check)
 run statusQueryAllowedDuringCleanupTest=accepted.then(beginCleanup).then(pinRoute(2)).then(readPinned).then(unpinRoute).then(finish(0)).then(ackAdmin).then(detach).then(freeVm).then(check)
 run pinnedUserCannotExecuteAfterCloseTest=bound.then(pinRoute(1)).then(beginCleanup).then(readPinned).then(unpinRoute).then(finish(0)).then(check)
 run ordinaryWindowFullStillHasAdminCreditTest=bound.then(prepare(1)).then(claimBind(1)).then(finishBind(1)).then(beginCleanup).then(adminProgress).then(adminUnknown).then(check)
 run preparedOriginDiscardedBeforeDetachTest=online.then(prepare(0)).then(beginCleanup).then(discardPrepared(0)).then(ackAdmin).then(detach).then(freeVm).then(check)
 run boundOriginKeepsCleanupDebtTest=bound.then(beginCleanup).then(ackAdmin).then(findByOrigin(0)).then(finish(0)).then(detach).then(freeVm).then(check)
 run reclaimedSlotUsesNewOriginSerialTest=bound.then(finish(0)).then(advance).then(prepare(0)).then(claimBind(0)).then(finishBind(0)).then(check)
 run queryPinDrainsBeforeRetireTest=accepted.then(pinRoute(2)).then(pinCell(0)).then(unpinCell(0)).then(unpinRoute).then(finish(0)).then(check)
 run finalSessionExhaustionRefusesTest=restarted.then(clean).then(all{assert(s.epoch==E),s'=s}).then(check)
 run absentVmReturnsNoDataTest=init.then(rejectNoVm).then(check)
 run duplicateClaimCounterexampleTest=bound.then(badDuplicateClaim).then(reject)
 run lostJournalLocatorCounterexampleTest=bound.then(badLostLocator).then(reject)
 run originSerialChangedWhileLiveCounterexampleTest=bound.then(badSerialReuse).then(reject)
 run oldRoutePinCannotFreeVmCounterexampleTest=online.then(pinRoute(2)).then(beginCleanup).then(ackAdmin).then(detach).then(badFreePinned).then(reject)
 run pendingActivationPreventsDetachCounterexampleTest=bound.then(beginCleanup).then(ackAdmin).then(badEarlyDetach).then(reject)
 run gstateCleanupCannotResetAnchorCounterexampleTest=restarted.then(badResetAnchor).then(reject)
 run staleSessionCannotReadNewVmCounterexampleTest=restarted.then(badOldRead).then(reject)
 run partialBindCannotLoseSourceCounterexampleTest=online.then(prepare(0)).then(claimBind(0)).then(badEarlySource).then(reject)
 run resultAckStillRequiredCounterexampleTest=accepted.then(closeActivation(0)).then(terminalOutcome(0)).then(sourceAck(0)).then(releaseSource(0)).then(badEraseResult).then(reject)
 action badFreeParent=s'={...s,records:s.records.exclude(Set(s.locator.get(0)))}
 action badCloseEffect=s'={...s,effectPhase:s.phase}
 run nestedChildDrainsBeforeParentTest=bound.then(prepare(1)).then(claimBind(1)).then(finishBind(1)).then(finish(1)).then(finish(0)).then(check)
 run sourceScanCannotReleaseOnRootCoverageCounterexampleTest=accepted.then(closeGc).then(sourceAck(0)).then(badEarlySource).then(reject)
 run liveChildPinsParentJournalCounterexampleTest=bound.then(prepare(1)).then(claimBind(1)).then(finishBind(1)).then(badFreeParent).then(reject)
 run closedUserGateNeedsRecheckCounterexampleTest=bound.then(pinRoute(1)).then(beginCleanup).then(badCloseEffect).then(reject)
 action staleOriginQuery=all{s.serial.get(0)>1,queryOrigin(0,s.serial.get(0)-1)}
 run staleOriginSerialRejectsAfterReuseTest=bound.then(finish(0)).then(advance).then(prepare(0)).then(claimBind(0)).then(finishBind(0)).then(staleOriginQuery).then(check)
 run oldVmGenerationRejectsInCurrentSessionTest=online.then(routeEnvelope(s.epoch,s.vmGen-1,1)).then(check)
 run userEnvelopeRejectedDuringCloseTest=online.then(beginCleanup).then(routeEnvelope(s.epoch,s.vmGen,1)).then(check)
 action negativeInit=

restarted
 action negativeStep=badOldRead
}
