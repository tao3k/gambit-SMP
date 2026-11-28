module will_domain_migration {
 import will_domain_parameters.* from "./will_domain_parameters"
 // Two movable wills share a testator. Lists are weak-domain membership, not strong roots.
 type State={phase:int,epoch:int,processors:Set[int],transferred:bool,closed:bool,writer:bool,
  nonexec:List[int],exec:List[int],detached:Set[int],addresses:int->int,nhead:int,ehead:int,links:int->int,
  actionFields:Set[int],testatorFields:Set[int],allocated:Set[int],userStrong:bool,strongSnapshot:bool,
  expected:Set[int],decided:Set[int],eligible:Set[int],weakQueue:Set[int],weakSeen:bool,lastPending:int,
  frames:Set[int],captures:Set[int],cleared:Set[int],started:Set[int],continuations:Set[int],frameOwner:int->int,effects:int->int}
 pure def members(xs:List[int]):Set[int]=xs.foldl(Set(),(acc,i)=>acc.union(Set(i)))
 pure def matching(xs:List[int],selected:Set[int]):List[int]=xs.foldl(List(),(acc,i)=>if(selected.contains(i)) acc.concat(List(i)) else acc)
 pure def listHead(xs:List[int],addresses:int->int):int=if(xs.length()==0) -1 else addresses.get(xs.nth(0))
 pure def link(i:int,n:List[int],e:List[int],addresses:int->int):int=
  if(n.length()==2 and n.nth(0)==i) addresses.get(n.nth(1)) else if(e.length()==2 and e.nth(0)==i) addresses.get(e.nth(1)) else -1
 pure val initial:State={phase:0,epoch:0,processors:Set(0,1),transferred:false,closed:false,writer:false,
  nonexec:List(1,0),exec:List(),detached:Set(),addresses:Map(0->100,1->200),nhead:200,ehead:-1,links:Map(0-> -1,1->100),
  actionFields:Set(0,1),testatorFields:Set(0,1),allocated:Set(0,1),userStrong:false,strongSnapshot:false,
  expected:Set(),decided:Set(),eligible:Set(),weakQueue:Set(),weakSeen:false,lastPending:0,
  frames:Set(),captures:Set(),cleared:Set(),started:Set(),continuations:Set(),frameOwner:Map(0->1,1->1),effects:Map(0->0,1->0)}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,userStrong:true}
 action initImmediate=s'={...initial,allocated:Set()}
 action initReady=s'={...initial,nonexec:List(1),exec:List(0),nhead:200,ehead:100,links:Map(0-> -1,1-> -1)}
 action beginWriter=all {s.phase==0,not(s.closed),not(s.writer),s'={...s,writer:true}}
 action finishWriter=all {s.writer,s.phase==0,s'={...s,writer:false}}
 action closeAdmission=all {not(s.closed),s'={...s,closed:true}}
 action transfer=all {s.phase==0,s.closed,not(s.writer),not(s.transferred),s.frames==Set(),s.continuations==Set(),s'={...s,transferred:true}}
 action depart=all {s.phase==0,s.transferred,s.processors.contains(1),
  s.frames.union(s.continuations).forall(i=>s.frameOwner.get(i)!=1),s'={...s,processors:s.processors.exclude(Set(1))}}
 action beginGC=all {s.phase==0,not(s.writer),s.frames.intersect(s.actionFields)==Set(),
  val strong=s.userStrong or s.captures!=Set();
  s'={...s,phase:1,strongSnapshot:strong,expected:if(strong) Set() else s.testatorFields.intersect(s.allocated),
    decided:Set(),eligible:Set(),weakQueue:Set(),weakSeen:false}}
 action decide(i)=all {s.phase==1,members(s.nonexec).contains(i),not(s.decided.contains(i)),
  s'={...s,decided:s.decided.union(Set(i)),eligible:if(s.expected.contains(i)) s.eligible.union(Set(i)) else s.eligible}}
 action rebuild=all {s.phase==1,s.decided==members(s.nonexec),
  val n=matching(s.nonexec,members(s.nonexec).exclude(s.eligible));
  val e=s.exec.concat(matching(s.nonexec,s.eligible));
  val addresses=0.to(WorkspaceCount-1).mapBy(i=>s.addresses.get(i)+1000);
  s'={...s,phase:2,nonexec:n,exec:e,addresses:addresses,nhead:listHead(n,addresses),ehead:listHead(e,addresses),
    links:0.to(WorkspaceCount-1).mapBy(i=>link(i,n,e,addresses)),
    weakQueue:if(s.strongSnapshot) Set() else members(n).union(members(e)).intersect(s.testatorFields).intersect(s.allocated)}}
 action scanWeak(i)=all {s.phase==2,s.weakQueue.contains(i),s'={...s,weakQueue:s.weakQueue.exclude(Set(i)),weakSeen:true}}
 action endGC=all {s.phase==2,s.weakQueue==Set(),s'={...s,phase:0,epoch:s.epoch+1,lastPending:0}}
 action popExecutable=all {s.phase==0,s.exec.length()>0,
  not(s.actionFields.contains(s.exec.nth(0))) or not(s.frames.contains(s.exec.nth(0))),
  val i=s.exec.nth(0); val e=s.exec.tail();
  s'={...s,exec:e,ehead:listHead(e,s.addresses),links:0.to(WorkspaceCount-1).mapBy(j=>link(j,s.nonexec,e,s.addresses)),
   detached:s.detached.union(Set(i)),frames:if(s.actionFields.contains(i)) s.frames.union(Set(i)) else s.frames,
   frameOwner:if(s.actionFields.contains(i)) s.frameOwner.set(i,if(s.transferred) 0 else 1) else s.frameOwner}}
 // Public explicit execution may precede GC eligibility, and does not unlink a nonexec will.
 action explicitClaim(i)=all {s.phase==0,s.actionFields.contains(i),not(s.frames.contains(i)),not(s.captures.contains(i)),
  s'={...s,frames:s.frames.union(Set(i)),frameOwner:s.frameOwner.set(i,if(s.transferred) 0 else 1)}}
 action captureAndClear(i)=all {s.phase==0,s.frames.contains(i),s.actionFields.contains(i),not(s.captures.contains(i)),
  s'={...s,captures:s.captures.union(Set(i)),cleared:s.cleared.union(Set(i)),actionFields:s.actionFields.exclude(Set(i)),testatorFields:s.testatorFields.exclude(Set(i))}}
 action invoke(i)=all {s.phase==0,s.frames.contains(i),s.captures.contains(i),s.cleared.contains(i),not(s.started.contains(i)),s'={...s,started:s.started.union(Set(i))}}
 action effect(i)=all {s.phase==0,s.frames.contains(i),s.started.contains(i),s'={...s,effects:s.effects.set(i,s.effects.get(i)+1)}}
 action captureContinuation(i)=all {s.phase==0,s.frames.contains(i),s.started.contains(i),s'={...s,continuations:s.continuations.union(Set(i))}}
 action returnAction(i)=all {s.phase==0,s.frames.contains(i),s.started.contains(i),
  s'={...s,frames:s.frames.exclude(Set(i)),captures:if(s.continuations.contains(i)) s.captures else s.captures.exclude(Set(i))}}
 action resume(i)=all {s.phase==0,s.continuations.contains(i),not(s.frames.contains(i)),s'={...s,frames:s.frames.union(Set(i))}}
 // External proof premise: no continuation can resume after this retirement receipt.
 action retireContinuation(i)=all {s.phase==0,s.continuations.contains(i),not(s.frames.contains(i)),s'={...s,continuations:s.continuations.exclude(Set(i)),captures:s.captures.exclude(Set(i))}}
 def safe=s.lastPending==0 and members(s.nonexec).intersect(members(s.exec))==Set() and members(s.nonexec).union(members(s.exec)).union(s.detached)==Set(0,1) and
  s.nonexec.length()==members(s.nonexec).size() and s.exec.length()==members(s.exec).size() and
  s.nhead==listHead(s.nonexec,s.addresses) and s.ehead==listHead(s.exec,s.addresses) and
  members(s.nonexec).union(members(s.exec)).forall(i=>s.links.get(i)==link(i,s.nonexec,s.exec,s.addresses)) and
  s.cleared.intersect(s.actionFields)==Set() and s.cleared.intersect(s.testatorFields)==Set() and s.started.subseteq(s.cleared) and
  s.continuations.subseteq(s.captures) and s.captures.subseteq(s.frames.union(s.continuations)) and
  ((s.phase==1 or s.phase==2) implies s.eligible==s.decided.intersect(s.expected) and s.strongSnapshot==(s.userStrong or s.captures!=Set())) and
  (s.phase==1 implies not(s.weakSeen)) and
  (not(s.processors.contains(1)) implies s.transferred and s.frames.union(s.continuations).forall(i=>s.frameOwner.get(i)!=1))
 action step={nondet i=0.to(WorkspaceCount-1).oneOf();any {beginWriter,finishWriter,closeAdmission,transfer,depart,beginGC,decide(i),rebuild,scanWeak(i),endGC,
  popExecutable,explicitClaim(i),captureAndClear(i),invoke(i),effect(i),captureContinuation(i),returnAction(i),resume(i),retireContinuation(i),s'=s}}
 action collect=beginGC.then(decide(0)).then(decide(1)).then(rebuild).then(scanWeak(0)).then(scanWeak(1)).then(endGC)
 action managed=closeAdmission.then(transfer).then(depart)
 action badExit=s'={...s,processors:s.processors.exclude(Set(1))}
 action badHeads=s'={...s,nhead:200,ehead:-1}
 action badStrongRoot=s'={...s,strongSnapshot:true,expected:Set()}
 action badPublish=s'={...s,phase:0,weakQueue:Set(),lastPending:s.weakQueue.size()}
 action badDropFrame=s'={...s,captures:Set()}
 action badInvoke=s'={...s,started:s.started.union(Set(0))}
 action badDuplicate=s'={...s,exec:s.exec.concat(s.exec)}
 action badWeakMark=s'={...s,weakSeen:true}
 action badDecision=s'={...s,decided:s.decided.union(Set(1)),eligible:s.eligible.exclude(Set(1))}
 action badClearSource=s'={...s,nonexec:List(),nhead:-1}
 run migratedCollectionTest=init.then(managed).then(collect).expect(safe and s.exec==List(1,0) and s.addresses.get(0)==1100)
 run sourceCollectionTest=init.then(collect).expect(safe and s.exec==List(1,0))
 run writerDrainTest=init.then(beginWriter).then(closeAdmission).then(finishWriter).then(transfer).then(depart).expect(safe)
 run strongTestatorTest=initOther.then(beginGC).then(decide(0)).then(decide(1)).then(rebuild).then(endGC).expect(safe and s.nonexec==List(1,0))
 run weakPendingTest=init.then(beginGC).then(decide(0)).then(decide(1)).then(rebuild).then(scanWeak(0)).expect(safe and s.weakQueue==Set(1))
 run automaticActionTest=init.then(managed).then(collect).then(popExecutable).then(captureAndClear(1)).then(invoke(1)).then(effect(1)).then(returnAction(1)).expect(safe and s.effects.get(1)==1)
 run explicitBeforeGcTest=init.then(explicitClaim(0)).then(captureAndClear(0)).then(invoke(0)).then(returnAction(0)).expect(safe and s.nonexec==List(1,0) and not(s.testatorFields.contains(0)))
 run continuationResumeTest=init.then(managed).then(collect).then(popExecutable).then(captureAndClear(1)).then(invoke(1)).then(effect(1)).then(captureContinuation(1)).then(returnAction(1)).then(resume(1)).then(effect(1)).then(returnAction(1)).expect(safe and s.effects.get(1)==2 and s.started==Set(1))
 run continuationRetirementTest=init.then(explicitClaim(0)).then(captureAndClear(0)).then(invoke(0)).then(captureContinuation(0)).then(returnAction(0)).then(retireContinuation(0)).then(managed).expect(safe)
 run capturedTestatorRootTest=init.then(explicitClaim(0)).then(captureAndClear(0)).then(invoke(0)).then(captureContinuation(0)).then(returnAction(0)).then(beginGC).then(decide(0)).then(decide(1)).then(rebuild).then(endGC).expect(safe and s.expected==Set() and s.continuations==Set(0))
 run immediateTestatorTest=initImmediate.then(beginGC).then(decide(0)).then(decide(1)).then(rebuild).then(endGC).expect(safe and s.nonexec==List(1,0))
 run explicitQueuedActionTest=init.then(collect).then(explicitClaim(1)).then(captureAndClear(1)).then(invoke(1)).then(returnAction(1)).then(popExecutable).expect(safe and s.started==Set(1))
 run readyAcrossGcTest=init.then(collect).then(beginGC).then(rebuild).then(scanWeak(0)).then(scanWeak(1)).then(endGC).expect(safe and s.exec==List(1,0) and s.addresses.get(0)==2100)
 run existingPrefixTest=initReady.then(beginGC).then(decide(1)).then(rebuild).then(scanWeak(0)).then(scanWeak(1)).then(endGC).expect(safe and s.exec==List(0,1))
 run reentrantNoopPopTest=init.then(collect).then(explicitClaim(1)).then(captureAndClear(1)).then(invoke(1)).then(popExecutable).then(effect(1)).then(returnAction(1)).expect(safe and s.effects.get(1)==1)
 run activeVmLaneExitTest=init.then(closeAdmission).then(transfer).then(collect).then(popExecutable).then(captureAndClear(1)).then(invoke(1)).then(depart).then(captureContinuation(1)).then(returnAction(1)).then(beginGC).then(rebuild).then(endGC).expect(safe and s.continuations==Set(1) and s.frameOwner.get(1)==0 and not(s.processors.contains(1)))
 run exitWithoutTransferControlTest=init.then(badExit).expect(not(safe))
 run staleHeadControlTest=init.then(collect).then(badHeads).expect(not(safe))
 run strongListRootControlTest=init.then(beginGC).then(badStrongRoot).expect(not(safe))
 run lostCaptureControlTest=init.then(explicitClaim(0)).then(captureAndClear(0)).then(invoke(0)).then(captureContinuation(0)).then(returnAction(0)).then(badDropFrame).expect(not(safe))
 run invokeBeforeClearControlTest=init.then(badInvoke).expect(not(safe))
 run duplicateQueueControlTest=init.then(collect).then(badDuplicate).expect(not(safe))
 run prematureWeakMarkControlTest=init.then(beginGC).then(decide(0)).then(badWeakMark).expect(not(safe))
 run weakContaminationControlTest=init.then(beginGC).then(decide(0)).then(badDecision).expect(not(safe))
 run lostSourceListControlTest=init.then(badClearSource).expect(not(safe))
 run pendingWeakFinishControlTest=init.then(beginGC).then(decide(0)).then(decide(1)).then(rebuild).then(scanWeak(0)).then(badPublish).expect(not(safe))
}
