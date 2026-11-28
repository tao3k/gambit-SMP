// One exact member: GC/context custody and resolver retirement companion.
// Sequential steps require qualified lock/collective refinement, not C weak memory.
module task_group_roots {
 type S={generation:int,sourceHeld:bool,roots:Set[int],slot:int->int,gcEpoch:int,frozen:bool,manifest:Set[int],scanned:bool,
   published:bool,schemeDone:bool,process:int,effectsClosed:bool,resultKnown:bool,resultPublished:bool,
   queueRefs:int,observerOpen:bool,pins:Set[int],issued:Set[int],descriptorHeld:bool,contextHeld:bool,retired:bool,successor:bool}
 val initial:S={generation:1,sourceHeld:true,roots:Set(),slot:Map(0->10,1->20),gcEpoch:0,frozen:false,manifest:Set(),scanned:false,
   published:false,schemeDone:false,process:0,effectsClosed:false,resultKnown:false,resultPublished:false,
   queueRefs:0,observerOpen:true,pins:Set(),issued:Set(),descriptorHeld:true,contextHeld:true,retired:false,successor:false}
 var r:S
 action init=r'=initial
 def exact(g:int):bool=g==r.generation and not(r.retired)
 action registerPayload=all{not(r.retired),not(r.frozen),not(r.published),r.sourceHeld,r'={...r,roots:r.roots.union(Set(0)),slot:r.slot.set(0,10+r.gcEpoch)}}
 val canTransferSource=not(r.retired) and r.roots.contains(0) and not(r.frozen)
 action transferSource=all{canTransferSource,r'={...r,sourceHeld:false}}
 val canPublish=not(r.retired) and not(r.frozen) and r.roots.contains(0) and not(r.published)
 action publish=all{canPublish,r'={...r,published:true,queueRefs:1}}
 action claim=all{not(r.retired),r.published,r.queueRefs==1,r'={...r,queueRefs:0}}
 action launchUnknown=all{not(r.retired),r.published,r.queueRefs==0,r.process==0,not(r.schemeDone),r'={...r,process:1}}
 action schemeExit=all{not(r.retired),r.published,r.queueRefs==0,r'={...r,schemeDone:true}}
 // process=1 is unresolved; 2 is terminal/reaped. Closing effects is separate.
 action terminalWitness=all{not(r.retired),r.process==1,r'={...r,process:2}}
 action closeEffects=all{not(r.retired),r.process!=1,r.schemeDone,r'={...r,effectsClosed:true}}
 action registerResult=all{not(r.retired),not(r.frozen),r.schemeDone,r.process!=1,r.effectsClosed,r'={...r,roots:r.roots.union(Set(1)),slot:r.slot.set(1,20+r.gcEpoch)}}
 action commitResult=all{not(r.retired),r.roots.contains(1),not(r.frozen),r.schemeDone,r.process!=1,r.effectsClosed,r'={...r,resultKnown:true,resultPublished:true}}
 def canPin(g:int,p:int):bool=exact(g) and r.observerOpen and not(r.issued.contains(p)) and Set(0,1).contains(p)
 action pin(g,p)=all{canPin(g,p),r'={...r,pins:r.pins.union(Set(p)),issued:r.issued.union(Set(p))}}
 def canUnpin(g:int,p:int):bool=exact(g) and r.pins.contains(p)
 action unpin(g,p)=all{canUnpin(g,p),r'={...r,pins:r.pins.exclude(Set(p))}}
 action closeObservers=all{not(r.retired),r'={...r,observerOpen:false}}
 // GC freeze never waits for observer/root-cell pins. No new slot/remove while frozen.
 action freeze=all{not(r.frozen),not(r.retired),r'={...r,frozen:true,manifest:r.roots,scanned:false}}
 action scan=all{r.frozen,not(r.scanned),r'={...r,gcEpoch:r.gcEpoch+1,slot:r.slot.keys().mapBy(i=>if(r.manifest.contains(i)) 10*(i+1)+r.gcEpoch+1 else r.slot.get(i)),scanned:true}}
 action thaw=all{r.frozen,r.scanned,r'={...r,frozen:false}}
 def currentSlot(i:int):bool=not(r.frozen) and r.roots.contains(i) and r.slot.get(i)==10*(i+1)+r.gcEpoch
 val canRetire=not(r.retired) and not(r.observerOpen) and r.pins==Set() and r.schemeDone and r.process!=1 and r.effectsClosed and r.resultKnown and r.queueRefs==0 and not(r.sourceHeld) and not(r.frozen)
 action retire=all{canRetire,r'={...r,roots:Set(),descriptorHeld:false,contextHeld:false,retired:true}}
 // All other preparation checks are caller premises; no speed/source admission here.
 action successor=all{not(r.retired),r.resultKnown,r.schemeDone,r.process!=1,r.effectsClosed,r.queueRefs==0,r'={...r,successor:true}}
 action step=any{registerPayload,transferSource,publish,claim,launchUnknown,schemeExit,terminalWitness,closeEffects,registerResult,commitResult,closeObservers,freeze,scan,thaw,retire,successor,
   pin(1,0),pin(1,1),unpin(1,0),unpin(1,1),r'=r}
 val safe=(r.published and not(r.retired) implies r.roots.contains(0)) and
   (r.resultPublished and not(r.retired) implies r.roots.contains(1)) and
   (r.roots!=Set() implies r.contextHeld and r.descriptorHeld) and
   (not(r.frozen) implies r.roots.forall(i=>currentSlot(i))) and
   (r.frozen implies r.manifest==r.roots) and
   (r.retired implies r.pins==Set() and not(r.observerOpen) and r.schemeDone and r.process!=1 and r.effectsClosed and r.resultKnown and not(r.sourceHeld) and r.queueRefs==0 and not(r.frozen)) and
   (r.successor implies r.process!=1 and r.resultKnown and r.effectsClosed)
 action ready=registerPayload.then(transferSource).then(publish).then(claim)
 action finished=ready.then(schemeExit).then(closeEffects).then(registerResult).then(commitResult)
 run rootBeforePublicationTest=init.expect(safe and not(canPublish) and not(canTransferSource))
 run sourceTransferCoverageTest=init.then(registerPayload).then(transferSource).expect(safe and r.roots.contains(0) and not(r.sourceHeld))
 run gcUpdatesPayloadTest=init.then(ready).then(freeze).then(scan).then(thaw).expect(safe and currentSlot(0) and r.slot.get(0)==11)
 run gcUpdatesResultTest=init.then(finished).then(freeze).then(scan).then(thaw).expect(safe and currentSlot(0) and currentSlot(1))
 run unknownProcessBlocksRetirementTest=init.then(ready).then(launchUnknown).then(schemeExit).then(closeObservers).expect(safe and not(canRetire) and r.contextHeld)
 run terminalIsNotEffectsClosureTest=init.then(ready).then(launchUnknown).then(schemeExit).then(terminalWitness).expect(safe and not(r.effectsClosed) and not(canRetire))
 run latePinBlocksRetirementTest=init.then(finished).then(pin(1,0)).then(closeObservers).expect(safe and not(canRetire))
 run closeRefusesLateObserverTest=init.then(finished).then(closeObservers).expect(safe and not(canPin(1,0)) and canRetire)
 run duplicateUnpinRefusedTest=init.then(finished).then(pin(1,0)).then(unpin(1,0)).expect(safe and not(canUnpin(1,0)) and not(canPin(1,0)))
 run gcDoesNotWaitForObserverTest=init.then(finished).then(pin(1,0)).then(freeze).then(scan).then(thaw).expect(safe and r.pins==Set(0) and currentSlot(1))
 run frozenManifestBlocksRetirementTest=init.then(finished).then(closeObservers).then(freeze).expect(safe and not(canRetire))
 run exceptionWithUnknownKeepsCustodyTest=init.then(ready).then(launchUnknown).then(schemeExit).then(pin(1,0)).expect(safe and r.contextHeld and r.descriptorHeld and not(canRetire))
 run terminalDrainThenRetireTest=init.then(ready).then(launchUnknown).then(schemeExit).then(terminalWitness).then(closeEffects).then(registerResult).then(commitResult).then(closeObservers).then(retire).expect(safe and r.retired)
 run staleGenerationRefusesPinTest=init.then(finished).expect(safe and not(canPin(0,0)))
 run successorDoesNotRetireResultTest=init.then(finished).then(pin(1,0)).then(successor).expect(safe and r.successor and not(canRetire) and r.roots.contains(1))
 action loseRootControl=r'={...r,roots:Set()}
 run missingRootNegativeControlTest=init.then(ready).then(loseRootControl).expect(not(safe))
 action staleWordControl=r'={...r,slot:r.slot.set(0,10)}
 run staleWordAfterGcNegativeControlTest=init.then(ready).then(freeze).then(scan).then(thaw).then(staleWordControl).expect(not(safe))
 action earlyRetireControl=r'={...r,roots:Set(),contextHeld:false,descriptorHeld:false,retired:true}
 run unknownEarlyRetireNegativeControlTest=init.then(ready).then(launchUnknown).then(schemeExit).then(closeObservers).then(earlyRetireControl).expect(not(safe))
}
