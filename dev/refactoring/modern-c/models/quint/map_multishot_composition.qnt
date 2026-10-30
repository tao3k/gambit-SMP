// Architectural abstraction, not a translation of the C runtime.
// One pointer-bearing frame, one shared mutable object, two additional resumes.
// Frame/root enumeration, barriers and weak-memory realization are premises.
module map_multishot_composition {
 type State = { captured:bool, captureIssued:bool, mature:bool, saved:int, capturedValue:int, active:int,
   loc:int, savedRoot:int, activeRoot:int, frozenRoot:int,
   running:bool, parked:bool, rootsFrozen:bool, gc:bool, scanned:bool,
   epoch:int, loaded:int, borrow:bool, dirty:bool, edge:bool,
   shots:int, before:int, after:int, shared:int, resultPending:bool, outcomeRoot:int,
   resource:bool }
 var s:State
 action init = s'={captured:false,captureIssued:false,mature:false,saved:11,capturedValue:11,active:11,
   loc:1,savedRoot:0,activeRoot:1,frozenRoot:0,
   running:true,parked:false,rootsFrozen:false,gc:false,scanned:false,
   epoch:0,loaded:0,borrow:false,dirty:false,edge:false,
   shots:0,before:1,after:0,shared:0,resultPending:false,outcomeRoot:0,resource:false}
 action capture = all { s.running,not(s.captured),not(s.gc),
   s'={...s,captured:true,captureIssued:true,saved:s.active,capturedValue:s.active,savedRoot:s.activeRoot} }
 action mutatePrivate = all {s.running,not(s.gc),s'={...s,active:s.active+1}}
 action sharedWrite = all {s.running,not(s.gc),s'={...s,shared:s.shared+1}}
 action rememberWrite = all {s.running,s.mature,not(s.gc),
   s'={...s,edge:true,dirty:true}}
 // Every payload/derived pointer is surrendered before this cut.
 action park = all {s.running,s.captured,not(s.gc),not(s.borrow),
   s'={...s,running:false,parked:true,rootsFrozen:true,frozenRoot:s.activeRoot}}
 action nativeBorrow = all {s.running,not(s.gc),not(s.borrow),s'={...s,borrow:true}}
 action endBorrow = all {s.borrow,s'={...s,borrow:false}}
 action beginGc = all {s.parked,s.rootsFrozen,not(s.gc),not(s.borrow),
   s'={...s,gc:true,scanned:false}}
 // Atomic relocation/scan stands for a completed collector work protocol.
 action scan = all {s.gc,not(s.scanned),not(s.edge) or s.dirty,
   s'={...s,loc:s.loc+1,savedRoot:s.loc+1,frozenRoot:s.loc+1,
     outcomeRoot:if(s.resultPending) s.loc+1 else 0,
     mature:true,scanned:true,edge:false,dirty:false}}
 action finishGc = all {s.gc,s.scanned,s'={...s,gc:false,epoch:s.epoch+1}}
 // Reentry reloads; an old activeRoot is deliberately unusable while parked.
 action reload = all {s.parked,not(s.gc),s.frozenRoot==s.loc,
   s'={...s,running:true,parked:false,rootsFrozen:false,
     activeRoot:s.frozenRoot,loaded:s.epoch}}
 action finishShot = all {s.running,not(s.gc),not(s.borrow),
   not(s.resultPending),s'={...s,running:false,after:s.after+1}}
 action resume = all {s.captured,not(s.running),not(s.parked),not(s.gc),
   not(s.resultPending),s.shots<2,s.savedRoot==s.loc,
   s'={...s,running:true,active:s.saved,activeRoot:s.savedRoot,
     loaded:s.epoch,shots:s.shots+1,before:s.before+1}}
 // Task outcome/resource custody belongs to the VM, not the carrier stack.
 action commitResult = all {s.parked,not(s.resultPending),
   s'={...s,resultPending:true,outcomeRoot:s.loc,resource:true}}
 action deliverResult = all {s.running,not(s.gc),s.loaded==s.epoch,s.resultPending,
   s'={...s,resultPending:false,outcomeRoot:0,resource:false}}
 action carrierExit = all {s.parked,s'=s}
 action stutter = s'=s
 val safe = all {not(s.captureIssued) or s.captured,s.saved==s.capturedValue,
   not(s.captured) or s.savedRoot==s.loc,
   not(s.running) or (not(s.gc) and s.activeRoot==s.loc and s.loaded==s.epoch),
   not(s.parked) or (s.rootsFrozen and not(s.borrow)),
   not(s.edge) or s.dirty,
   s.before==s.shots+1,s.before==s.after+(if(s.running or s.parked) 1 else 0),
   s.resultPending==s.resource,not(s.resultPending) or s.outcomeRoot==s.loc}
 action step = any {capture,mutatePrivate,sharedWrite,rememberWrite,park,
   nativeBorrow,endBorrow,beginGc,scan,finishGc,reload,finishShot,resume,
   commitResult,deliverResult,carrierExit,stutter}
 action check = all {safe,s'=s}
 action twoShotCheck = all {safe,s.shots==2,s.active==s.saved,s'=s}
 action sharedCheck = all {safe,s.shots==2,s.shared==1,s'=s}
 action reject = all {not(safe),s'=s}
 action collect = beginGc.then(scan).then(finishGc)
 action ready = init.then(capture)
 action first = ready.then(park).then(collect).then(reload).then(finishShot)
 action unsafeConsume = all {s.captured,s'={...s,captured:false}}
 action unsafeWrite = all {s.mature,s.running,s'={...s,edge:true,dirty:false}}
 action unsafeReload = all {s.parked,not(s.gc),s'={...s,running:true,parked:false,loaded:s.epoch}}
 action unsafeLoseResult = all {s.resultPending,s'={...s,resource:false}}
 run repeatedResumeTest = first.then(resume).then(mutatePrivate).then(finishShot).then(resume).then(twoShotCheck)
 run sharedMutationNotRolledBackTest = first.then(resume).then(sharedWrite).then(finishShot).then(resume).then(sharedCheck)
 run blockedCarrierDoesNotOwnGcTest = ready.then(park).then(carrierExit).then(collect).then(reload).then(check)
 run lateOutcomeAcrossGcTest = ready.then(park).then(beginGc).then(commitResult).then(scan).then(finishGc).then(reload).then(deliverResult).then(check)
 run resultBeforeGcTest = ready.then(park).then(commitResult).then(collect).then(reload).then(deliverResult).then(check)
 run rememberedMutationTest = first.then(resume).then(rememberWrite).then(park).then(collect).then(reload).then(check)
 run rawBorrowEndsBeforeParkTest = ready.then(nativeBorrow).then(endBorrow).then(park).then(collect).then(reload).then(check)
 run twoCollectionsTest = ready.then(park).then(collect).then(collect).then(reload).then(check)
 run oneShotConsumptionCounterexampleTest = first.then(unsafeConsume).then(reject)
 run missingBarrierCounterexampleTest = first.then(resume).then(unsafeWrite).then(reject)
 run stalePointerCounterexampleTest = ready.then(park).then(collect).then(unsafeReload).then(reject)
 run lostOutcomeCustodyCounterexampleTest = ready.then(park).then(commitResult).then(unsafeLoseResult).then(reject)
 action negativeInit = ready.then(park).then(collect)
 action negativeStep = unsafeReload
}
