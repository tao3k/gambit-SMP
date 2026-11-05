module advantage_architecture {
 // Finite architecture protocol. Predicate receipts are assumptions, not source proofs.
 type State={sem:int,source:int,layout:int,tool:int,planSem:int,planSource:int,cLayout:int,oTool:int,
 plan:bool,emitted:bool,native:bool,traceClosed:bool,support:bool,sealed:bool,
 ownerA:int,ownerB:int,a:bool,b:bool,hits:int,frameAbi:int,codeAbi:int,loadedAbi:int,
 captured:bool,identity:int,roots:bool,mature:bool,edge:bool,remembered:bool,reserved:bool,
 closed:bool,frozen:Set[int],gc:bool,debt:int,copying:bool,copyPublished:bool,
 epoch:int,restored:int,running:bool,shots:int,worker:int,
 nativeDebt:bool,result:bool,unknown:bool,arena:bool}
 pure val initial:State={sem:1,source:1,layout:1,tool:1,planSem:0,planSource:0,cLayout:0,oTool:0,
 plan:false,emitted:false,native:false,traceClosed:true,support:true,sealed:false,
 ownerA:0,ownerB:1,a:false,b:false,hits:0,frameAbi:1,codeAbi:1,loadedAbi:1,
 captured:false,identity:1,roots:false,mature:false,edge:false,remembered:false,reserved:false,
 closed:false,frozen:Set(),gc:false,debt:0,copying:false,copyPublished:false,
 epoch:0,restored:0,running:false,shots:0,worker:0,
 nativeDebt:false,result:false,unknown:false,arena:true}
 var s:State
 action init=s'=initial
 val safe=all{
 s.plan implies (s.planSem==s.sem and s.planSource==s.source and s.sealed),
 s.emitted implies (s.plan and s.cLayout==s.layout),
 s.native implies (s.emitted and s.oTool==s.tool),
 (s.a or s.b) implies (s.plan and s.support and s.traceClosed),
 (s.a and s.b) implies s.ownerA!=s.ownerB,
 s.codeAbi==s.frameAbi and s.loadedAbi==s.codeAbi,
 s.identity==1,
 s.captured implies s.roots,
 s.edge implies (s.remembered or s.reserved),
 s.gc implies (s.closed and s.frozen==Set(0,1) and s.roots and not(s.running)),
 s.copying implies (s.gc and s.debt>0 and s.roots),
 s.running implies (not(s.gc) and s.restored==s.epoch and s.loadedAbi==s.frameAbi),
 (s.nativeDebt or s.unknown) implies (s.roots and s.arena),
 s.debt>=0,s.shots>=0 and s.shots<=2}
 action sealPlan=all{s.traceClosed,s.support,not(s.a),not(s.b),s'={...s,plan:true,sealed:true,planSem:s.sem,planSource:s.source}}
 action emitC=all{s.plan,s.planSem==s.sem,s'={...s,emitted:true,cLayout:s.layout}}
 action compileNative=all{s.emitted,s'={...s,native:true,oTool:s.tool}}
 action backendEdit=all{s'={...s,tool:s.tool+1,native:false}}
 action layoutEdit=all{s'={...s,layout:s.layout+1,emitted:false,native:false}}
 action semanticEdit=all{not(s.a),not(s.b),s'={...s,sem:s.sem+1,plan:false,sealed:false,emitted:false,native:false}}
 action macroEdit=all{not(s.a),not(s.b),s'={...s,source:s.source+1,plan:false,sealed:false,emitted:false,native:false}}
 action cacheHit=all{s.plan,s.traceClosed,s.planSem==s.sem,s.planSource==s.source,s'={...s,hits:s.hits+1}}
 action startConsumer(i)=all{s.plan,s.sealed,s.support,s.traceClosed,if(i==0)not(s.a)else not(s.b),s'={...s,a:s.a or i==0,b:s.b or i==1}}
 action finishConsumers=all{s'={...s,a:false,b:false}}
 action bindModule=all{s.native,not(s.roots),not(s.captured),not(s.nativeDebt),s'={...s,loadedAbi:s.layout,frameAbi:s.layout,codeAbi:s.layout}}
 action materializeRoots=all{not(s.gc),s.loadedAbi==s.frameAbi,s'={...s,roots:true}}
 action capture=all{s.roots,s'={...s,captured:true}}
 action matureFrame=all{s.captured,not(s.gc),s'={...s,mature:true}}
 action reserveBarrier=all{s.mature,not(s.closed),not(s.gc),s'={...s,reserved:true}}
 action storeYoung=all{s.reserved,not(s.closed),not(s.gc),s'={...s,edge:true,remembered:true,reserved:false}}
 action closeMembership=all{s.roots,not(s.running),s'={...s,closed:true}}
 action freeze(p)=all{s.closed,s.roots,not(s.running),s'={...s,frozen:s.frozen.union(Set(p))}}
 action beginMinor=all{s.closed,s.frozen==Set(0,1),s.roots,not(s.running),not(s.gc),s.debt==0,not(s.copying),s'={...s,gc:true,debt:2,copyPublished:false}}
 action reserveCopy=all{s.gc,s.debt>0,not(s.copying),s'={...s,copying:true,debt:s.debt+1}}
 action publishCopy=all{s.copying,s.gc,s'={...s,copying:false,copyPublished:true}}
 action scan=all{s.gc,s.debt>0,not(s.copying),s'={...s,debt:s.debt-1}}
 action handoffWorker=all{s.gc,s'={...s,worker:1-s.worker}}
 action finishMinor=all{s.gc,s.debt==0,not(s.copying),s'={...s,gc:false,closed:false,frozen:Set(),epoch:s.epoch+1}}
 action reload=all{not(s.gc),s.roots,not(s.running),s'={...s,restored:s.epoch}}
 action resume=all{s.captured,s.roots,not(s.closed),not(s.gc),not(s.running),s.restored==s.epoch,s.shots<2,s'={...s,running:true,shots:s.shots+1}}
 action returnShot=all{s.running,s'={...s,running:false}}
 action parkNative=all{s.running,s.roots,not(s.nativeDebt),s'={...s,running:false,nativeDebt:true,result:false}}
 action deliverResult=all{s.nativeDebt,s'={...s,result:true}}
 action loseResult=all{s.nativeDebt,s'={...s,unknown:true}}
 action settleNative=all{s.nativeDebt,s.result,not(s.gc),s.restored==s.epoch,s'={...s,nativeDebt:false,unknown:false}}
 action step=any{bindModule,sealPlan,emitC,compileNative,backendEdit,layoutEdit,semanticEdit,macroEdit,cacheHit,startConsumer(0),startConsumer(1),finishConsumers,materializeRoots,capture,matureFrame,reserveBarrier,storeYoung,closeMembership,freeze(0),freeze(1),beginMinor,reserveCopy,publishCopy,scan,handoffWorker,finishMinor,reload,resume,returnShot,parkNative,deliverResult,loseResult,settleNative,all{s'=s}}
 action build=sealPlan.then(emitC).then(compileNative)
 action snapshot=materializeRoots.then(capture).then(matureFrame)
 action cut=closeMembership.then(freeze(0)).then(freeze(1)).then(beginMinor)
 action collect=cut.then(scan).then(scan).then(finishMinor)
 run completeCrossDomainTest=init.then(build).then(snapshot).then(reserveBarrier).then(storeYoung).then(resume).then(parkNative).then(collect).then(deliverResult).then(reload).then(settleNative).then(resume).then(returnShot).then(backendEdit).then(cacheHit).then(startConsumer(0)).then(startConsumer(1)).then(all{assert(safe and s.shots==2 and s.captured and s.a and s.b),s'=s})
 run boundCohortTest=init.then(build).then(bindModule).then(materializeRoots).then(capture).then(all{assert(safe and s.loadedAbi==s.frameAbi),s'=s})
 run backendKeepsSemanticPlanTest=init.then(build).then(backendEdit).then(cacheHit).then(all{assert(safe and s.plan and s.emitted and not(s.native)),s'=s})
 run layoutKeepsSemanticPlanTest=init.then(build).then(layoutEdit).then(cacheHit).then(all{assert(safe and s.plan and not(s.emitted)),s'=s})
 run semanticChangeInvalidatesTest=init.then(build).then(semanticEdit).then(all{assert(safe and not(s.plan) and not(s.native)),s'=s})
 run macroSupportChangeInvalidatesTest=init.then(build).then(macroEdit).then(all{assert(safe and not(s.plan)),s'=s})
 run twoPrivateConsumersTest=init.then(build).then(startConsumer(0)).then(startConsumer(1)).then(all{assert(safe and s.a and s.b),s'=s})
 run multishotNotConsumedTest=init.then(snapshot).then(resume).then(returnShot).then(resume).then(returnShot).then(all{assert(safe and s.identity==1 and s.captured and s.shots==2),s'=s})
 run rememberedWriteTest=init.then(snapshot).then(reserveBarrier).then(storeYoung).then(collect).then(all{assert(safe and s.edge and s.remembered),s'=s})
 run copyDebtSurvivesWorkerTest=init.then(snapshot).then(cut).then(reserveCopy).then(handoffWorker).then(all{assert(safe and s.copying and s.debt==3 and s.worker==1),s'=s})
 run publishedCopyDrainsTest=init.then(snapshot).then(cut).then(reserveCopy).then(publishCopy).then(scan).then(scan).then(scan).then(finishMinor).then(all{assert(safe and s.copyPublished and s.debt==0),s'=s})
 run unknownNativeKeepsCustodyTest=init.then(snapshot).then(resume).then(parkNative).then(loseResult).then(collect).then(all{assert(safe and s.nativeDebt and s.unknown and s.roots and s.arena),s'=s})
 run staleSemanticCacheControlTest=init.then(build).then(all{s'={...s,sem:2}}).then(all{assert(not(safe)),s'=s})
 run missingSupportControlTest=init.then(build).then(startConsumer(0)).then(all{s'={...s,support:false}}).then(all{assert(not(safe)),s'=s})
 run mixedFrameAbiControlTest=init.then(snapshot).then(all{s'={...s,codeAbi:2}}).then(all{assert(not(safe)),s'=s})
 run missingCapturedRootControlTest=init.then(snapshot).then(all{s'={...s,roots:false}}).then(all{assert(not(safe)),s'=s})
 run unrememberedStoreControlTest=init.then(snapshot).then(all{s'={...s,edge:true}}).then(all{assert(not(safe)),s'=s})
 run partialMemberCutControlTest=init.then(snapshot).then(closeMembership).then(freeze(0)).then(all{s'={...s,gc:true}}).then(all{assert(not(safe)),s'=s})
 run copyDebtDiscardedControlTest=init.then(snapshot).then(cut).then(reserveCopy).then(all{s'={...s,debt:0}}).then(all{assert(not(safe)),s'=s})
 run resumeBeforeReloadControlTest=init.then(snapshot).then(collect).then(all{s'={...s,running:true}}).then(all{assert(not(safe)),s'=s})
 run nativeCustodyLostControlTest=init.then(snapshot).then(resume).then(parkNative).then(loseResult).then(all{s'={...s,arena:false}}).then(all{assert(not(safe)),s'=s})
 run sharedPrivateContextControlTest=init.then(build).then(startConsumer(0)).then(startConsumer(1)).then(all{s'={...s,ownerB:0}}).then(all{assert(not(safe)),s'=s})
 run consumedIdentityControlTest=init.then(snapshot).then(resume).then(returnShot).then(all{s'={...s,identity:0}}).then(all{assert(not(safe)),s'=s})
}
