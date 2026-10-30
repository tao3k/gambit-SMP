// Candidate ownership architecture, not a projection of a repair patch or a native C23 proof.
module runtime_ownership {
 type State={phase:int,epoch:int,completed:int,alive:Set[int],owners:int->int,
  cache:int->int,slots:Set[int],frozen:Set[int],view:int->int,location:int->int,
  manifest:Set[int],task:int->int,taskOwner:int->int,worker:int->int,
  childDecided:bool,childTicket:int,retired:Set[int],native:int->int,
  captured:bool,everCaptured:bool,programDropped:bool,descriptor:bool,
  resumes:int,resumeLease:bool,writes:int->int}
 pure val contexts=Set(0,1)
 pure val rootIds=Set(0,1,2)
 pure val taskIds=Set(0,1,2,3)
 pure val workers=Set(0,1)
 pure val carriers=Set(1,2)
 pure val initial:State={phase:0,epoch:0,completed:0,alive:contexts,owners:Map(0->1,1->2),
  cache:Map(0->0,1->0),slots:Set(0,1),frozen:Set(),view:Map(0->0,1->0,2->0),
  location:Map(0->0,1->0,2->0,3->0),manifest:Set(),task:Map(0->0,1->0,2->0,3->0),
  taskOwner:Map(0->0,1->0,2->0,3->0),worker:Map(0->0,1->0),
  childDecided:false,childTicket:0,retired:Set(),native:Map(1->0,2->0),
  captured:false,everCaptured:false,programDropped:false,descriptor:true,
  resumes:0,resumeLease:false,writes:Map(0->0,1->0)}
 var s:State
 action init=s'=initial
 pure def canRetireCarrier(x:State,p:int):bool=p==2 and not(x.retired.contains(p)) and
  contexts.forall(c=>x.owners.get(c)!=p) and x.native.get(p)==0
 val rootCustody=s.alive.subseteq(s.slots) and
  (s.captured implies (s.slots.contains(2) and s.descriptor)) and
  (s.phase>=1 implies s.manifest.subseteq(s.slots))
 val noExpiredOwner=contexts.forall(c=>s.owners.get(c)==0 or
  (s.alive.contains(c) and not(s.retired.contains(s.owners.get(c))) and s.cache.get(c)==s.completed))
 val ownerExclusive=not(s.owners.get(0)>0 and s.owners.get(0)==s.owners.get(1))
 val scanCut=s.phase<2 or s.manifest.subseteq(s.frozen)
 val workerCustody=taskIds.forall(t=>(s.task.get(t)==2) == (s.taskOwner.get(t)>0)) and
  workers.forall(w=>s.worker.get(w)==0 or
   (s.task.get(s.worker.get(w)-1)==2 and s.taskOwner.get(s.worker.get(w)-1)==w+1)) and
  taskIds.forall(t=>s.taskOwner.get(t)==0 or s.worker.get(s.taskOwner.get(t)-1)==t+1)
 val noHiddenWork=s.childTicket==0 or (s.phase==2 and s.task.get(0)==2 and s.childDecided)
 val closedComplete=s.phase!=3 or (taskIds.forall(t=>s.task.get(t)==0 or s.task.get(t)==3) and
  workers.forall(w=>s.worker.get(w)==0) and s.childTicket==0 and
  s.manifest.forall(r=>s.location.get(r)==s.epoch))
 val rootReload=s.phase!=0 or s.slots.forall(r=>s.location.get(r)==s.completed)
 val nativeLifetime=s.retired.forall(p=>s.native.get(p)==0)
 val frameUse=not(s.resumeLease) or (s.captured and s.descriptor and s.owners.get(0)>0 and s.location.get(2)==s.completed)
 val multishot=not(s.everCaptured and not(s.programDropped)) or s.captured
 val safe=all{rootCustody,noExpiredOwner,ownerExclusive,scanCut,workerCustody,noHiddenWork,
  closedComplete,rootReload,nativeLifetime,frameUse,multishot,s.epoch>=0,s.epoch<=2,
  s.completed>=0,s.completed<=s.epoch,s.resumes>=0,s.resumes<=2,
  taskIds.forall(t=>s.task.get(t)>=0 and s.task.get(t)<=3)}
 action mutate(c:int):bool=all{s.phase<=1,s.alive.contains(c),s.owners.get(c)>0,not(s.frozen.contains(c)),
  s.writes.get(c)<1,s'={...s,writes:s.writes.set(c,s.writes.get(c)+1)}}
 action park(c:int):bool=all{s.phase==0,s.owners.get(c)>0,not(c==0 and s.resumeLease),s'={...s,owners:s.owners.set(c,0)}}
 action capture=all{s.phase==0,s.owners.get(1)>0,not(s.everCaptured),s.descriptor,
  s'={...s,captured:true,everCaptured:true,slots:s.slots.union(Set(2)),location:s.location.set(2,s.completed)}}
 action enterNative(p:int):bool=all{s.phase==0,not(s.retired.contains(p)),s.native.get(p)==0,
  contexts.exists(c=>s.owners.get(c)==p),s'={...s,native:s.native.set(p,1)}}
 action leaveNative(p:int):bool=all{s.native.get(p)==1,s'={...s,native:s.native.set(p,0)}}
 action retireCarrier(p:int):bool=all{canRetireCarrier(s,p),s'={...s,retired:s.retired.union(Set(p))}}
 action requestGc=all{s.phase==0,s.epoch<2,not(s.resumeLease),
  s'={...s,phase:1,epoch:s.epoch+1,manifest:s.slots,frozen:Set(),
  task:Map(0->0,1->0,2->0,3->0),taskOwner:Map(0->0,1->0,2->0,3->0),
  worker:Map(0->0,1->0),childDecided:false,childTicket:0}}
 action freezeRoot(r:int):bool=all{s.phase==1,s.manifest.contains(r),not(s.frozen.contains(r)),
  s'={...s,frozen:s.frozen.union(Set(r)),view:s.view.set(r,s.epoch),
  owners:if(r<2) s.owners.set(r,0) else s.owners}}
 action beginTrace=all{s.phase==1,s.manifest.subseteq(s.frozen),
  s'={...s,phase:2,task:Map(0->(if(s.manifest.contains(0))1 else 0),
    1->(if(s.manifest.contains(1))1 else 0),2->(if(s.manifest.contains(2))1 else 0),3->0)}}
 action retireContext=all{s.phase==2,s.alive.contains(1),s.owners.get(1)==0,s.native.get(2)==0,
  s'={...s,alive:s.alive.exclude(Set(1))}}
 action claim(t:int,w:int):bool=all{s.phase==2,s.task.get(t)==1,s.worker.get(w)==0,
  s'={...s,task:s.task.set(t,2),taskOwner:s.taskOwner.set(t,w+1),worker:s.worker.set(w,t+1)}}
 action decideNoChild=all{s.phase==2,s.task.get(0)==2,not(s.childDecided),
  s'={...s,childDecided:true}}
 action reserveChild=all{s.phase==2,s.task.get(0)==2,not(s.childDecided),
  s'={...s,childDecided:true,childTicket:1}}
 action publishChild=all{s.phase==2,s.childTicket==1,s.task.get(3)==0,
  s'={...s,childTicket:0,task:s.task.set(3,1)}}
 action transfer(t:int,donor:int,recipient:int):bool=all{s.phase==2,donor!=recipient,s.task.get(t)==2,
  s.taskOwner.get(t)==donor+1,s.worker.get(recipient)==0,
  s'={...s,taskOwner:s.taskOwner.set(t,recipient+1),worker:s.worker.set(donor,0).set(recipient,t+1)}}
 action finishTask(t:int,w:int):bool=all{s.phase==2,s.task.get(t)==2,s.taskOwner.get(t)==w+1,
  t!=0 or (s.childDecided and s.childTicket==0),
  s'={...s,task:s.task.set(t,3),taskOwner:s.taskOwner.set(t,0),worker:s.worker.set(w,0),location:s.location.set(t,s.epoch)}}
 action closeTrace=all{s.phase==2,taskIds.forall(t=>s.task.get(t)==0 or s.task.get(t)==3),
  workers.forall(w=>s.worker.get(w)==0),s.childTicket==0,
  s'={...s,phase:3,completed:s.epoch}}
 action finishGc=all{s.phase==3,s'={...s,phase:0}}
 action acquire(c:int,p:int):bool=all{s.phase==0,s.alive.contains(c),s.owners.get(c)==0,
  not(s.retired.contains(p)),contexts.forall(k=>s.owners.get(k)!=p),
  s'={...s,owners:s.owners.set(c,p),cache:s.cache.set(c,s.location.get(c))}}
 action resumeCapture=all{s.phase==0,s.captured,s.descriptor,s.resumes<2,not(s.resumeLease),
  s.owners.get(0)>0,s.location.get(2)==s.completed,
  s'={...s,resumes:s.resumes+1,resumeLease:true}}
 action finishResume=all{s.resumeLease,s'={...s,resumeLease:false}}
 action programDropCapture=all{s.phase==0,s.resumes==2,not(s.resumeLease),s.captured,
  s'={...s,captured:false,programDropped:true}}
 action releaseDeadRoot=all{s.phase==0,not(s.alive.contains(1)),s.task.get(1)==3,
  s.slots.contains(1),s'={...s,slots:s.slots.exclude(Set(1))}}
 action releaseFrameRoot=all{s.phase==0,s.programDropped,not(s.resumeLease),s.slots.contains(2),
  s'={...s,slots:s.slots.exclude(Set(2))}}
 action retireDescriptor=all{s.phase==0,not(s.captured),not(s.resumeLease),not(s.slots.contains(2)),s.descriptor,
  s'={...s,descriptor:false}}
 action step=any{mutate(0),mutate(1),park(0),park(1),capture,enterNative(1),enterNative(2),
  leaveNative(1),leaveNative(2),retireCarrier(2),requestGc,freezeRoot(0),freezeRoot(1),freezeRoot(2),
  beginTrace,retireContext,decideNoChild,reserveChild,publishChild,
  claim(0,0),claim(1,0),claim(2,0),claim(3,0),claim(0,1),claim(1,1),claim(2,1),claim(3,1),
  transfer(0,0,1),transfer(1,0,1),transfer(2,0,1),transfer(3,0,1),
  transfer(0,1,0),transfer(1,1,0),transfer(2,1,0),transfer(3,1,0),
  finishTask(0,0),finishTask(1,0),finishTask(2,0),finishTask(3,0),
  finishTask(0,1),finishTask(1,1),finishTask(2,1),finishTask(3,1),
  closeTrace,finishGc,acquire(0,1),acquire(1,1),acquire(0,2),acquire(1,2),
  resumeCapture,finishResume,programDropCapture,releaseDeadRoot,releaseFrameRoot,retireDescriptor,s'=s}
 // Mutation witnesses are architectural alternatives, not allegations about current C reachability.
 action omitRoot=s'={...s,slots:s.slots.exclude(Set(1))}
 action staleAcquire=s'={...s,owners:s.owners.set(0,1),cache:s.cache.set(0,0)}
 action closeWithPrivate=s'={...s,phase:3,completed:s.epoch}
 action dropDescriptor=s'={...s,descriptor:false}
 action consumeCapture=s'={...s,captured:false}
 action retirePinnedCarrier=s'={...s,retired:s.retired.union(Set(2))}
 action freezeTwo=requestGc.then(freezeRoot(0)).then(freezeRoot(1)).then(beginTrace)
 action scanTwo=claim(0,0).then(decideNoChild).then(finishTask(0,0)).then(claim(1,1)).then(finishTask(1,1)).then(closeTrace).then(finishGc)
 action frozenFrame=init.then(capture).then(park(1)).then(retireCarrier(2)).then(requestGc).then(freezeRoot(0)).then(freezeRoot(1)).then(freezeRoot(2)).then(beginTrace).then(retireContext)
 action scanFrame=claim(0,0).then(decideNoChild).then(finishTask(0,0)).then(claim(1,1)).then(transfer(1,1,0)).then(finishTask(1,0)).then(claim(2,1)).then(finishTask(2,1)).then(closeTrace).then(finishGc)
 run multishotAfterOriginRetiresTest=frozenFrame.then(scanFrame).then(releaseDeadRoot).then(acquire(0,1)).then(resumeCapture).then(finishResume).then(resumeCapture).then(finishResume).then(programDropCapture).then(releaseFrameRoot).then(retireDescriptor).then(all{assert(safe),assert(s.resumes==2),assert(not(s.alive.contains(1))),assert(not(s.descriptor)),s'=s})
 run childCustodyTest=init.then(freezeTwo).then(claim(0,0)).then(reserveChild).then(claim(1,1)).then(finishTask(1,1)).then(publishChild).then(finishTask(0,0)).then(claim(3,1)).then(finishTask(3,1)).then(closeTrace).then(finishGc).then(all{assert(safe),s'=s})
 run nativePinTest=init.then(enterNative(2)).then(park(1)).then(all{assert(not(canRetireCarrier(s,2))),s'=s}).then(leaveNative(2)).then(retireCarrier(2)).then(all{assert(safe),s'=s})
 run twoEpochReloadTest=init.then(freezeTwo).then(scanTwo).then(acquire(0,1)).then(mutate(0)).then(freezeTwo).then(scanTwo).then(acquire(0,1)).then(all{assert(safe),assert(s.cache.get(0)==2),s'=s})
 run mutationDuringRendezvousTest=init.then(requestGc).then(mutate(0)).then(freezeRoot(0)).then(freezeRoot(1)).then(beginTrace).then(scanTwo).then(all{assert(safe),s'=s})
 run missingRootNegativeTest=frozenFrame.then(omitRoot).then(all{assert(not(safe)),s'=s})
 run staleReloadNegativeTest=init.then(freezeTwo).then(scanTwo).then(staleAcquire).then(all{assert(not(safe)),s'=s})
 run privateWorkNegativeTest=init.then(freezeTwo).then(claim(0,0)).then(reserveChild).then(closeWithPrivate).then(all{assert(not(safe)),s'=s})
 run descriptorNegativeTest=init.then(capture).then(dropDescriptor).then(all{assert(not(safe)),s'=s})
 run oneShotNegativeTest=init.then(capture).then(consumeCapture).then(all{assert(not(safe)),s'=s})
 run nativeRetirementNegativeTest=init.then(enterNative(2)).then(park(1)).then(retirePinnedCarrier).then(all{assert(not(safe)),s'=s})
}
