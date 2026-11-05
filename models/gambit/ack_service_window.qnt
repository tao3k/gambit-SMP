module ack_service_window {
  // Logical B/C owners; membership, scan domains and native ownership differ.
  // phase: election, root scan, GC native tail, reader-exit rendezvous,
  //        bounded owner service, service-done rendezvous.
  type S={mode:int,bug:int,phase:int,activeB:bool,parkedB:bool,frozenB:bool,
    materialB:bool,scanOwnerB:int,cohortEpoch:int,rootB:bool,rootC:bool,
    domainB:bool,domainC:bool,debtB:bool,debtC:bool,borrowB:bool,
    readB:bool,readC:bool,window:bool,visitedB:bool,visitedC:bool,
    cleanupB:int,cleanupC:int,detachC:int,doneB:bool,doneC:bool,
    pendingGc:bool,gcBeat:bool,requestBeat:bool,serviceSeen:bool,nativeSeen:bool,
    latePublished:bool,extraRoot:bool,extraDebt:bool,extraDone:bool,cutExtra:bool,
    vmFree:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,phase:0,activeB:true,parkedB:false,
    frozenB:false,materialB:false,scanOwnerB:1,cohortEpoch:0,rootB:true,rootC:true,
    domainB:true,domainC:true,debtB:true,debtC:true,borrowB:m==1,
    readB:false,readC:false,window:false,visitedB:false,visitedC:false,
    cleanupB:0,cleanupC:0,detachC:0,doneB:false,doneC:false,pendingGc:true,
    gcBeat:false,requestBeat:false,serviceSeen:false,nativeSeen:false,
    latePublished:false,extraRoot:false,extraDebt:false,extraDone:false,cutExtra:false,vmFree:false}
  action initAllFinish=s'=initial(0,0)
  action initBusyB=s'=initial(1,0)
  action initParkedB=s'=initial(2,0)
  action initNativeSync=s'=initial(4,0)
  action initLateAck=s'=initial(5,0)
  action initRejoin=s'=initial(6,0)
  action initStrictGc=s'=initial(1,1)
  action initSerialB=s'=initial(1,2)
  action initGlobalBorrow=s'=initial(1,3)
  action initActiveBlocked=s'=initial(3,0)
  action initUnfair=s'=initial(0,0)
  action initEarlyWindow=s'=initial(0,4)
  action initConcurrentGc=s'=initial(0,5)
  action initRemoteParkedDetach=s'=initial(2,6)
  action initSkipFreeze=s'=initial(2,7)
  action initLoseLateDebt=s'=initial(5,8)
  action initDoubleDetach=s'=initial(0,9)
  action initDropParkedRoot=s'=initial(2,10)
  val membersAvailable=s.mode!=3
  action parkPrepare=all {Set(2,6).contains(s.mode),s.phase==0,s.cohortEpoch==0,not(s.frozenB),
    s'={...s,frozenB:true,materialB:true}}
  // Abstract collective commit. C scans frozen B storage, never frees B's RC cell.
  action parkCommit=all {Set(2,6).contains(s.mode),s.phase==0,s.cohortEpoch==0,
    s.frozenB,s.materialB,not(s.readB),
    s'={...s,activeB:false,parkedB:true,scanOwnerB:2,cohortEpoch:1}}
  action rejoin=all {s.mode==6,s.phase==0,s.parkedB,s.serviceSeen,
    s'={...s,activeB:true,parkedB:false,scanOwnerB:1,cohortEpoch:2}}
  action requestGc=s'={...s,pendingGc:true,requestBeat:not(s.requestBeat)}
  action startGc=all {s.phase==0,s.pendingGc,
    s.mode!=6 or not(s.parkedB) or not(s.serviceSeen),
    not(Set(2,6).contains(s.mode)) or s.cohortEpoch>0,
    s'={...s,phase:1,pendingGc:false,readB:s.rootB,readC:s.rootC}}
  // Finishing the root loop alone does not mean the full GC operation returned.
  action finishScan=all {s.phase==1,membersAvailable,s'={...s,phase:2}}
  action gcReturn=all {s.phase==2,membersAvailable,
    s'={...s,phase:if(s.bug==1) 0 else 3,pendingGc:if(s.bug==1) true else s.pendingGc,
      readB:if(s.bug==4) s.readB else false,readC:if(s.bug==4) s.readC else false,
      gcBeat:not(s.gcBeat)}}
  action beginWindow=all {s.phase==3,membersAvailable,
    s'={...s,phase:4,window:true,visitedB:false,visitedC:false,cutExtra:s.extraDebt}}
  action visitB=all {s.phase==4,not(s.visitedB),
    val eligible=s.activeB and not(s.borrowB) and s.debtB
    s'={...s,visitedB:true,rootB:if(eligible) false else s.rootB,
      domainB:if(eligible) false else s.domainB,debtB:if(eligible) false else s.debtB,
      cleanupB:if(eligible) 1 else s.cleanupB,doneB:s.doneB or eligible,
      nativeSeen:s.nativeSeen or s.mode==4}}
  action visitC=all {s.phase==4,not(s.visitedC),
    not(s.bug==2 and not(s.doneB)),not(s.bug==3 and s.borrowB),
    s'={...s,visitedC:true,rootC:false,domainC:false,debtC:false,doneC:true,
      cleanupC:2,detachC:if(s.debtC) s.detachC+1 else s.detachC,
      extraRoot:if(s.cutExtra) false else s.extraRoot,
      extraDebt:if(s.cutExtra) false else s.extraDebt,extraDone:s.extraDone or s.cutExtra}}
  action publishLate=all {s.mode==5,s.phase==4,s.visitedC,not(s.latePublished),
    s'={...s,latePublished:true,extraRoot:true,extraDebt:true}}
  action closeWindow=all {s.phase==4,s.visitedB,s.visitedC,s.mode!=5 or s.latePublished,
    s'={...s,phase:5,extraDebt:if(s.bug==8) false else s.extraDebt}}
  action serviceDone=all {s.phase==5,membersAvailable,s'={...s,phase:0,window:false,serviceSeen:true}}
  action mutant=any {
    all {s.bug==5,s.phase==4,s'={...s,phase:1,readB:s.rootB,readC:s.rootC}},
    all {s.bug==6,s.parkedB,s.phase==4,s'={...s,rootB:false,domainB:false,debtB:false,cleanupB:2}},
    all {s.bug==7,s.phase==0,not(s.frozenB),s'={...s,activeB:false,parkedB:true,scanOwnerB:2,cohortEpoch:1}},
    all {s.bug==9,s.doneC,s'={...s,detachC:s.detachC+1}},
    all {s.bug==10,s.parkedB,s'={...s,rootB:false,domainB:false,vmFree:true}}
  }
  action idle=s'=s
  action step=any {parkPrepare,parkCommit,rejoin,requestGc,startGc,finishScan,gcReturn,
    beginWindow,visitB,visitC,publishLate,closeWindow,serviceDone,mutant,idle}
  val safe=all {
    s.activeB!=s.parkedB,
    not(s.parkedB) or (s.frozenB and s.materialB and s.scanOwnerB==2),
    not(s.activeB) or s.scanOwnerB==1,
    not(s.window) or (Set(4,5).contains(s.phase) and not(s.readB) and not(s.readC)),
    not(s.readB) or s.rootB,not(s.readC) or s.rootC,
    not(s.debtB) or (s.rootB and s.domainB),
    not(s.debtC) or (s.rootC and s.domainC),
    not(s.rootB) or s.domainB,not(s.rootC) or s.domainC,
    s.rootB or s.cleanupB==1,s.rootC or s.cleanupC==2,s.detachC<=1,
    not(s.extraRoot) or s.extraDebt,
    not(s.latePublished) or s.extraRoot or s.extraDone,
    not(s.vmFree) or (not(s.domainB) and not(s.domainC) and not(s.extraRoot))}
  val goal=if(s.mode==1 or s.mode==2)
    s.doneC and s.rootB and s.domainB and s.debtB
    else if(s.mode==4) s.doneB and s.doneC and s.nativeSeen
    else if(s.mode==5) s.doneC and s.extraDone
    else s.doneB and s.doneC
  temporal fairness=all {weakFair(parkPrepare,Set(s)),weakFair(parkCommit,Set(s)),
    weakFair(rejoin,Set(s)),weakFair(requestGc,Set(s)),weakFair(startGc,Set(s)),
    weakFair(finishScan,Set(s)),weakFair(gcReturn,Set(s)),weakFair(beginWindow,Set(s)),
    weakFair(visitB,Set(s)),weakFair(visitC,Set(s)),weakFair(publishLate,Set(s)),
    weakFair(closeWindow,Set(s)),weakFair(serviceDone,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
  temporal noSchedulerAssumption=eventually(goal)
}
