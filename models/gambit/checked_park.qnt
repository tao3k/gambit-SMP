module checked_park {
  // B is a non-P0 worker; C includes the still-active P0/GC coordinator.
  // Atomic GC here refines a completed GC window, not its internal C barriers.
  type S={mode:int,bug:int,phase:int,approved:bool,isP0:bool,refused:bool,
    saved:bool,carrier:bool,registered:bool,material:bool,frozen:bool,
    activeB:bool,workers:int,scanOwner:int,epoch:int,nativeCtx:bool,marker:bool,
    bodyRan:bool,jobDone:bool,callback:bool,callbackDone:bool,rejoinRequested:bool,freshStack:bool,
    restores:int,restoreSource:int,liveRoot:bool,gcBit:bool,valueBit:bool,
    domain:bool,retained:bool,cProgress:bool,owner:int,ticket:int,acceptedTicket:int,
    stillScan:bool,rcScan:bool,stillBit:bool,rcBit:bool,privateWork:int,scanCopies:int}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,phase:0,approved:m!=4,isP0:m==5,
    refused:false,saved:false,carrier:false,registered:false,material:false,
    frozen:false,activeB:true,workers:2,scanOwner:1,epoch:0,nativeCtx:true,
    marker:true,bodyRan:false,jobDone:false,callback:false,callbackDone:false,rejoinRequested:false,
    freshStack:false,restores:0,restoreSource:0,liveRoot:true,gcBit:false,
    valueBit:false,domain:false,retained:false,cProgress:false,owner:1,ticket:7,acceptedTicket:7,stillScan:true,rcScan:true,stillBit:false,rcBit:false,privateWork:1,scanCopies:1}
  action initReturn=s'=initial(0,0)
  action initPrepareFail=s'=initial(1,0)
  action initCommitFail=s'=initial(2,0)
  action initPostCommitFault=s'=initial(3,0)
  action initUnsafeAbi=s'=initial(4,0)
  action initP0Refusal=s'=initial(5,0)
  action initCallback=s'=initial(6,0)
  action initRollbackFail=s'=initial(7,0)
  action initRejoinFail=s'=initial(8,0)
  action initOmitStillScan=s'=initial(0,13)
  action initOmitRcScan=s'=initial(0,14)
  action initKeepPrivateWork=s'=initial(0,15)
  action initDoubleScan=s'=initial(0,16)
  action initCallbackCompletesParent=s'=initial(6,17)
  action initSaveIsMaterial=s'=initial(0,1)
  action initSplitMembership=s'=initial(0,2)
  action initWrongWorkers=s'=initial(0,3)
  action initDropFrozenRoot=s'=initial(3,4)
  action initKillRunMarker=s'=initial(0,5)
  action initOldFpRestore=s'=initial(1,6)
  action initParkP0=s'={...initial(0,7),isP0:true}
  action initDirectCallback=s'=initial(6,8)
  action initStaleTicket=s'=initial(0,9)
  action initDoubleRestore=s'=initial(0,10)
  action initRollbackDrop=s'=initial(7,11)
  action initRemoteOwner=s'=initial(0,12)
  action refuse=all {s.phase==0,not(s.approved) or (s.isP0 and s.bug!=7),
    s'={...s,phase:9,refused:true}}
  action enter=all {s.phase==0,s.approved,not(s.isP0) or s.bug==7,
    s'={...s,phase:1}}
  action save=all {s.phase==1,s'={...s,phase:2,saved:true,carrier:true,
    registered:true,domain:true,liveRoot:false,valueBit:s.gcBit}}
  action materialize=all {s.phase==2,s.mode!=1,
    s'={...s,phase:3,material:true,valueBit:s.gcBit,privateWork:0}}
  action freeze=all {s.phase==3,s'={...s,phase:4,frozen:true}}
  action failPrepare=all {s.phase==2,s.mode==1,s'={...s,phase:10}}
  action failCommit=all {s.phase==4,s.mode==2,s'={...s,phase:10,frozen:false}}
  action failRollback=all {s.phase==4,s.mode==7,s'={...s,phase:12,retained:true}}
  action commit=all {s.phase==4,not(Set(2,7).contains(s.mode)),s.privateWork==0,
    s'={...s,phase:5,activeB:false,workers:1,scanOwner:2,epoch:1}}
  action nativeBody=all {s.phase==5,not(s.bodyRan),s.mode!=3,
    s'={...s,bodyRan:true}}
  action bodyReturn=all {s.phase==5,s.bodyRan,s.mode!=6 or s.callbackDone,
    s'={...s,phase:6,jobDone:true,rejoinRequested:true}}
  action callbackRequest=all {s.phase==5,s.bodyRan,s.mode==6,not(s.callbackDone),
    s'={...s,phase:6,callback:true,rejoinRequested:true}}
  action postCommitFault=all {s.phase==5,s.mode==3,
    s'={...s,phase:12,retained:true}}
  action failRejoin=all {s.phase==6,s.mode==8,s'={...s,phase:12,retained:true}}
  action rejoin=all {s.phase==6,s.mode!=8,s.rejoinRequested,s.owner==1,s.ticket==s.acceptedTicket,
    s'={...s,phase:7,activeB:true,workers:2,scanOwner:1,epoch:if(s.callbackDone) 4 else 2,freshStack:true}}
  action callbackReturn=all {s.phase==7,s.callback,not(s.callbackDone),
    s'={...s,phase:13,callbackDone:true,material:false,frozen:false,privateWork:1}}
  action callbackMaterialize=all {s.phase==13,not(s.material),
    s'={...s,material:true,frozen:true,privateWork:0}}
  action reparkCallback=all {s.phase==13,s.privateWork==0,s.material,s.frozen,
    s'={...s,phase:5,activeB:false,workers:1,scanOwner:2,epoch:3,
      rejoinRequested:false,freshStack:false}}
  // Scheme/native result conversion resumes only after fresh attachment.
  action restore=all {s.phase==7,not(s.callback) or (s.callbackDone and s.jobDone),s'={...s,phase:8,restores:s.restores+1,
    restoreSource:1,liveRoot:true,jobDone:true}}
  action abortRestore=all {s.phase==10,s'={...s,phase:8,restores:s.restores+1,
    restoreSource:1,liveRoot:true}}
  action finalDrop=all {s.phase==8,s'={...s,phase:9,carrier:false,registered:false,domain:false}}
  action gc=all {s.phase>=2,s'={...s,gcBit:not(s.gcBit),
    valueBit:if(s.carrier and s.registered) not(s.gcBit) else s.valueBit,cProgress:true,
    stillBit:if(s.activeB or s.stillScan) not(s.gcBit) else s.stillBit,
    rcBit:if(s.activeB or s.rcScan) not(s.gcBit) else s.rcBit}}
  action mutant=any {
    all {s.bug==17,s.phase==7,s.callback,not(s.callbackDone),
      s'={...s,restores:1,restoreSource:1,liveRoot:true}},
    all {s.bug==13,s.phase==5,s.stillScan,s'={...s,stillScan:false}},
    all {s.bug==14,s.phase==5,s.rcScan,s'={...s,rcScan:false}},
    all {s.bug==15,s.phase==5,s'={...s,privateWork:1}},
    all {s.bug==16,s.phase==5,s'={...s,scanCopies:2}},
    all {s.bug==1,s.phase==2,s'={...s,phase:5,activeB:false,workers:1,scanOwner:2,epoch:1}},
    all {s.bug==2,s.phase==4,s'={...s,workers:1}},
    all {s.bug==3,s.phase==5,s'={...s,workers:2}},
    all {s.bug==4,s.phase==12,not(s.activeB),s'={...s,carrier:false,domain:false}},
    all {s.bug==5,s.phase==5,s'={...s,marker:false}},
    all {s.bug==6,s.phase==10,s.gcBit,s'={...s,phase:8,restoreSource:2,restores:1,liveRoot:true}},
    all {s.bug==8,s.phase==6,not(s.activeB),s'={...s,restores:1,restoreSource:1,liveRoot:true}},
    all {s.bug==9,s.phase==6,s'={...s,phase:7,activeB:true,workers:2,scanOwner:1,
      epoch:2,freshStack:true,ticket:8}},
    all {s.bug==10,s.phase==8,s'={...s,restores:2}},
    all {s.bug==11,s.phase==12,s.activeB,s'={...s,carrier:false,registered:false,domain:false}},
    all {s.bug==12,s.phase==6,s'={...s,phase:7,activeB:true,workers:2,scanOwner:1,
      epoch:2,freshStack:true,owner:2}}
  }
  action idle=s'=s
  action step=any {refuse,enter,save,materialize,freeze,failPrepare,failCommit,
    failRollback,commit,nativeBody,bodyReturn,callbackRequest,postCommitFault,
    failRejoin,rejoin,callbackReturn,callbackMaterialize,reparkCallback,restore,abortRestore,finalDrop,gc,mutant,idle}
  val safe=all {
    s.nativeCtx and s.marker,s.scanCopies==1,
    s.activeB or (s.privateWork==0 and s.stillBit==s.gcBit and s.rcBit==s.gcBit),
    s.liveRoot or (s.carrier and s.registered and s.domain),
    not(s.carrier) or (s.registered and s.valueBit==s.gcBit),
    if(s.activeB) s.workers==2 and s.scanOwner==1 else
      s.workers==1 and s.scanOwner==2 and s.material and s.frozen and s.carrier and s.domain and not(s.isP0),
    not(s.bodyRan) or (s.approved and (s.activeB or (s.material and s.frozen))),
    s.restores<=1,s.restoreSource!=2,
    s.restores==0 or not(s.callback) or (s.callbackDone and s.jobDone),
    s.restores==0 or s.activeB,
    not(Set(2,4).contains(s.epoch)) or (s.activeB and s.freshStack and s.owner==1 and s.ticket==s.acceptedTicket),
    not(s.retained) or (s.carrier and s.registered and s.domain),
    not(s.refused) or (not(s.bodyRan) and s.epoch==0)}
  val goal=if(Set(3,7,8).contains(s.mode)) s.retained and s.carrier and s.cProgress
    else s.phase==9 and (if(Set(4,5).contains(s.mode)) s.refused else s.restores==1)
  temporal fairness=all {weakFair(refuse,Set(s)),weakFair(enter,Set(s)),weakFair(save,Set(s)),
    weakFair(materialize,Set(s)),weakFair(freeze,Set(s)),weakFair(failPrepare,Set(s)),
    weakFair(failCommit,Set(s)),weakFair(failRollback,Set(s)),weakFair(commit,Set(s)),
    weakFair(nativeBody,Set(s)),weakFair(bodyReturn,Set(s)),weakFair(callbackRequest,Set(s)),
    weakFair(postCommitFault,Set(s)),weakFair(failRejoin,Set(s)),weakFair(rejoin,Set(s)),weakFair(callbackReturn,Set(s)),weakFair(callbackMaterialize,Set(s)),weakFair(reparkCallback,Set(s)),weakFair(restore,Set(s)),
    weakFair(abortRestore,Set(s)),weakFair(finalDrop,Set(s)),weakFair(gc,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
}
