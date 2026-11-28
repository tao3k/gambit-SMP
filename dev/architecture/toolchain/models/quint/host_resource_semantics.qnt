// Resource-boundary simulation, not extracted howto-verify GVM or a scheduler.
module host_resource_semantics {
 val R=Set(0,1,2)
 val K=Set(0,1)
 type FrameSpec={fs:int,link:int,bitmap:int}
 def liveBit(bitmap:int,index:int):bool=(bitmap/(2^index))%2==1
 def ordinarySlots(f:FrameSpec):Set[int]=1.to(f.fs).filter(slot=>liveBit(f.bitmap,slot-1) and slot!=f.link+1)
 // Test fixture follows the current one-based source contract; NOT an actual howto row.
 val frame:FrameSpec={fs:3,link:1,bitmap:7}
 val roots=ordinarySlots(frame).map(slot=>slot-1)
 type Evidence={cBody:bool,resources:bool,frames:bool,profile:bool,descriptorHeld:bool,ifdOccurrences:int}
 val howtoEvidence:Evidence={cBody:false,resources:false,frames:false,profile:false,descriptorHeld:false,ifdOccurrences:153}
 def canInstantiate(e:Evidence):bool=e.cBody and e.resources and e.frames and e.profile and e.descriptorHeld
 type Control={pc:int,nargs:int,fp:int,frameId:int,denv:int}
 type Machine={regs:int->int,control:Control,trace:List[int],world:int}
 type Host={base:Machine,locals:int->int}
 type Snapshot={regs:int->int,control:Control}
 type State={reference:Machine,target:Host,captured:bool,left:Snapshot,right:Snapshot}
 val initialMachine:Machine={regs:Map(0->1,1->2,2->3),control:{pc:3,nargs:1,fp:8,frameId:42,denv:5},trace:[],world:0}
 def load(m:Machine):Host={base:m,locals:R.mapBy(r=>if(K.contains(r)) m.regs.get(r) else 0)}
 def observe(h:Host):Machine={...h.base,regs:R.mapBy(r=>if(K.contains(r)) h.locals.get(r) else h.base.regs.get(r))}
 def snapshot(m:Machine):Snapshot={regs:m.regs,control:m.control}
 val initial:State={reference:initialMachine,target:load(initialMachine),captured:false,left:snapshot(initialMachine),right:snapshot(initialMachine)}
 var s:State
 action init=s'=initial
 val related=s.reference==observe(s.target) and (s.captured implies s.left==s.right)
 def copy(m:Machine,d:int,r:int):Machine={...m,regs:m.regs.set(d,m.regs.get(r))}
 def copyHost(h:Host,d:int,r:int):Host={...h,locals:h.locals.set(d,h.locals.get(r))}
 action copyCovered(d,r)=all{K.contains(d),K.contains(r),s'={...s,reference:copy(s.reference,d,r),target:copyHost(s.target,d,r)}}
 def moved(rs:int->int,mask:Set[int]):int->int=R.mapBy(r=>if(mask.contains(r)) rs.get(r)+10 else rs.get(r))
 def gc(m:Machine,mask:Set[int]):Machine={...m,regs:moved(m.regs,mask),trace:m.trace.append(100)}
 def gcSnapshot(k:Snapshot):Snapshot={...k,regs:moved(k.regs,roots)}
 action poll= s'={...s,reference:gc(s.reference,roots),target:load(gc(observe(s.target),roots)),
   left:if(s.captured) gcSnapshot(s.left) else s.left,right:if(s.captured) gcSnapshot(s.right) else s.right}
 def effect(m:Machine):Machine={...m,regs:m.regs.set(2,m.regs.get(2)+5),trace:m.trace.append(400),world:m.world+1}
 action opaqueEffect=s'={...s,reference:effect(s.reference),target:load(effect(observe(s.target)))}
 def land(m:Machine):Machine={...m,control:{...m.control,pc:9},trace:m.trace.append(500)}
 action exceptionLanding=s'={...s,reference:land(s.reference),target:load(land(observe(s.target)))}
 action capture=s'={...s,captured:true,left:snapshot(s.reference),right:snapshot(observe(s.target))}
 def restore(m:Machine,k:Snapshot):Machine={regs:k.regs,control:k.control,trace:m.trace.append(300),world:m.world}
 action resume=all{s.captured,s'={...s,reference:restore(s.reference,s.left),target:load(restore(observe(s.target),s.right))}}
 // Explicit bad lowerings are retained counterexamples, never part of safeStep.
 action omitReadControl=s'={...s,reference:copy(s.reference,0,2),target:copyHost(s.target,0,2)}
 action omitWriteControl=s'={...s,reference:copy(s.reference,2,0),target:copyHost(s.target,2,0)}
 action missingRootControl=s'={...s,reference:gc(s.reference,roots),target:load(gc(observe(s.target),Set(0)))}
 action noReloadControl=s'={...s,reference:gc(s.reference,roots),target:{base:gc(observe(s.target),roots),locals:s.target.locals}}
 action loseWritebackControl=s'={...s,target:load(s.target.base)}
 action duplicateEffectControl=s'={...s,reference:effect(s.reference),target:load(effect(effect(observe(s.target))))}
 action staleSnapshotControl=all{s.captured,s'={...s,reference:gc(s.reference,roots),target:load(gc(observe(s.target),roots)),left:gcSnapshot(s.left)}}
 action wrongFrameControl=all{s.captured,s'={...s,reference:restore(s.reference,s.left),target:load(restore(observe(s.target),{...s.right,control:{...s.right.control,frameId:99}}))}}
 action eraseHistoryControl=all{s.captured,s'={...s,reference:restore(s.reference,s.left),target:load(restore({...observe(s.target),trace:[]},s.right))}}
 action safeStep=any{copyCovered(0,1),copyCovered(1,0),poll,opaqueEffect,exceptionLanding,capture,resume}
 run copySimulationTest=init.then(copyCovered(0,1)).expect(related and s.reference.regs.get(0)==2)
 run rootMaterializeReloadTest=init.then(copyCovered(0,1)).then(poll).expect(related and s.target.locals.get(0)==12 and observe(s.target).regs.get(2)==13)
 run opaqueBoundaryTest=init.then(copyCovered(1,0)).then(opaqueEffect).expect(related and s.reference.trace==[400] and s.reference.regs.get(2)==8)
 run exceptionLandingTest=init.then(copyCovered(0,1)).then(exceptionLanding).expect(related and s.reference.control.pc==9 and s.reference.control.frameId==42)
 run multiShotHistoryTest=init.then(capture).then(resume).then(opaqueEffect).then(resume).expect(related and s.reference.trace==[300,400,300] and s.reference.regs.get(2)==3 and s.reference.world==1)
 run capturedRootGcTest=init.then(capture).then(poll).then(resume).expect(related and s.reference.regs.get(0)==11 and s.reference.regs.get(2)==13)
 run omittedReadCounterexampleTest=init.then(omitReadControl).expect(not(related) and s.reference.regs.get(0)!=observe(s.target).regs.get(0))
 run omittedWriteCounterexampleTest=init.then(omitWriteControl).expect(not(related))
 run missingRootCounterexampleTest=init.then(missingRootControl).expect(not(related) and s.reference.regs.get(2)!=observe(s.target).regs.get(2))
 run noReloadCounterexampleTest=init.then(noReloadControl).expect(not(related) and s.reference.regs.get(0)!=observe(s.target).regs.get(0))
 run lostWritebackCounterexampleTest=init.then(copyCovered(0,1)).then(loseWritebackControl).expect(not(related))
 run duplicateEffectCounterexampleTest=init.then(duplicateEffectControl).expect(not(related) and observe(s.target).trace==[400,400])
 run staleCapturedRootCounterexampleTest=init.then(capture).then(staleSnapshotControl).expect(not(related) and s.left.regs.get(2)!=s.right.regs.get(2))
 run wrongFrameCounterexampleTest=init.then(capture).then(wrongFrameControl).expect(not(related))
 run erasedHistoryCounterexampleTest=init.then(capture).then(opaqueEffect).then(eraseHistoryControl).expect(not(related))
 run physicalFrameCoordinatesTest=init.expect(ordinarySlots(frame)==Set(1,3) and roots==Set(0,2) and not(ordinarySlots(frame).contains(frame.link+1)))
 run howtoCountIsNotDescriptorWitnessTest=init.expect(howtoEvidence.ifdOccurrences==153 and not(canInstantiate(howtoEvidence)))
 run incompleteResourcesRejectWitnessTest=init.expect(not(canInstantiate({...howtoEvidence,cBody:true,frames:true,profile:true,descriptorHeld:true})))
 run closedFixtureAdmitsWitnessTest=init.expect(canInstantiate({cBody:true,resources:true,frames:true,profile:true,descriptorHeld:true,ifdOccurrences:0}))
}
