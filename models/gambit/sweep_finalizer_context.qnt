module sweep_finalizer_context {
  // Uses the existing will weak-selection/post-GC shape. Native-only sweep
  // release and mapped deferred release have intentionally different contexts.
  type S={mode:int,bug:int,kind:int,phase:int,context:bool,owner:bool,
    validToken:bool,accepted:bool,appRoot:bool,will:bool,captures:bool,
    eligible:bool,jobRoot:bool,released:bool,ptr:bool,calls:int,
    inGC:bool,gc:int,resurrected:bool,freed:bool,vmTouched:bool,
    refused:bool,fatal:bool,actionCleared:bool,calledInGC:bool,
    calledWithoutContext:bool,explicitReleased:bool,explicitDone:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,
    kind:if(m==2) 0 else if(m==5 or m==6) 2 else 1,
    phase:if(m==6) 3 else 0,context:not(Set(3,4,6).contains(m)),
    owner:m!=3,validToken:m!=3,accepted:m==6,appRoot:m!=6,
    will:false,captures:false,eligible:false,jobRoot:false,released:false,
    ptr:true,calls:0,inGC:m==6,gc:if(m==6) 1 else 0,
    resurrected:false,freed:false,vmTouched:false,refused:false,fatal:false,
    actionCleared:false,calledInGC:false,calledWithoutContext:false,explicitReleased:false,explicitDone:false}
  action initDeferred=s'=initial(0,0)
  action initResurrection=s'=initial(1,0)
  action initInlineNative=s'=initial(2,0)
  action initNoContextRefusal=s'=initial(3,0)
  action initCheckedBridge=s'=initial(4,0)
  action initUnknownRefusal=s'=initial(5,0)
  action initUnknownSweepStop=s'=initial(6,0)
  action initExplicitReleaseRace=s'=initial(7,0)
  action initStrongCapture=s'=initial(0,1)
  action initMappedInSweep=s'=initial(0,2)
  action initFreeQueuedWrapper=s'=initial(0,3)
  action initCallWithoutContext=s'=initial(4,4)
  action initRepeatAfterResurrection=s'=initial(1,5)
  action initRestoreReleasedPointer=s'=initial(1,6)
  action initDropPendingRoot=s'=initial(0,7)
  action initRefuseAfterAccess=s'=initial(3,8)
  action initAcceptUnknown=s'=initial(5,9)
  action initLateWillConsumption=s'=initial(0,10)
  action initRaceDoubleInvoke=s'=initial(7,11)
  action initEraseExternalRoot=s'=initial(7,12)
  action bridge=all {s.phase==0,s.mode==4,s.validToken,s.owner,
    s'={...s,phase:1,context:true,vmTouched:true}}
  action setup=all {s.phase==0 or s.phase==1,s.kind!=2,
    s.validToken,s.owner,s.context,
    s'={...s,phase:2,accepted:true,will:s.kind==1,vmTouched:true}}
  action refuse=all {s.phase==0,s.mode==3 or s.kind==2,
    s'={...s,phase:8,refused:true}}
  action startGc=all {s.phase==2,
    s'={...s,phase:3,appRoot:false,inGC:true,gc:1}}
  action weakSelect=all {s.phase==3,
    val chosen=s.will and not(s.appRoot) and not(s.captures)
    s'={...s,phase:4,eligible:chosen,jobRoot:chosen}}
  action sweep=all {s.phase==4,s.kind!=2,
    s'={...s,phase:5,inGC:false,
      calls:if(s.kind==0) 1 else 0,released:s.kind==0,
      ptr:s.kind!=0,freed:s.kind==0,calledInGC:s.kind==0}}
  action unknownStop=all {s.phase==4,s.kind==2,
    s'={...s,phase:9,fatal:true}}
  action runWill=all {s.phase==5,s.kind==1,s.eligible,s.jobRoot,
    s.context,s.owner,not(s.actionCleared),
    s.mode!=7 or s.appRoot,
    s'={...s,phase:6,actionCleared:true,calls:if(s.released) s.calls else s.calls+1,released:true,ptr:false,
      resurrected:s.mode==1,appRoot:s.appRoot or s.mode==1}}
  action regainFromWill=all {s.mode==7,s.phase==5,not(s.appRoot),
    s'={...s,appRoot:true}}
  action explicitRelease=all {s.mode==7,s.phase==5,not(s.released),
    s.context,s.owner,s.appRoot,
    s'={...s,calls:s.calls+1,released:true,ptr:false,
      explicitReleased:true,explicitDone:true,appRoot:true}}
  action explicitNoop=all {s.mode==7,s.phase==6,s.released,
    not(s.explicitDone),s.appRoot,
    s'={...s,explicitDone:true}}
  action nativeDone=all {s.phase==5,s.kind==0,
    s'={...s,phase:7,gc:2}}
  action secondGc=all {s.phase==6,s.mode!=7 or s.explicitDone,
    s'={...s,phase:7,gc:2,jobRoot:false,eligible:false,
      freed:not(s.appRoot)}}
  action mutant=any {
    all {s.bug==1,s.phase==2,s'={...s,captures:true}},
    all {s.bug==2,s.phase==4,s'={...s,calls:1,calledInGC:true}},
    all {s.bug==3,s.phase==5,s'={...s,freed:true}},
    all {s.bug==4,s.phase==0,not(s.context),
      s'={...s,calls:1,calledWithoutContext:true}},
    all {s.bug==5,s.phase==7,s.resurrected,
      s'={...s,calls:s.calls+1}},
    all {s.bug==6,s.released,s'={...s,ptr:true}},
    all {s.bug==7,s.phase==5,s'={...s,jobRoot:false}},
    all {s.bug==8,s.refused,s'={...s,vmTouched:true}},
    all {s.bug==9,s.phase==0,s.kind==2,
      s'={...s,accepted:true}},
    all {s.bug==10,s.phase==5,s.kind==1,
      s'={...s,calls:1,released:true,ptr:false}},
    all {s.bug==11,(s.explicitReleased and s.phase==5) or (s.phase==6 and s.mode==7 and not(s.explicitDone)),
      s'={...s,actionCleared:true,calls:s.calls+1}},
    all {s.bug==12,s.mode==7,s.phase==6,
      s'={...s,appRoot:false}}
  }
  action step=any {bridge,setup,refuse,startGc,weakSelect,sweep,unknownStop,
    runWill,regainFromWill,explicitRelease,explicitNoop,nativeDone,secondGc,mutant}
  val safe=all {s.calls<=1,not(s.captures),not(s.calledWithoutContext),
    not(s.released) or not(s.ptr),not(s.refused) or not(s.vmTouched),
    not(s.jobRoot) or not(s.freed),
    not(s.eligible) or s.released or s.jobRoot,
    s.kind!=1 or not(s.calledInGC),
    s.kind!=1 or s.calls==0 or s.actionCleared or s.explicitReleased,
    s.kind!=2 or not(s.accepted) or s.mode==6,
    not(s.resurrected) or (s.released and not(s.ptr)),
    s.mode!=7 or s.phase<6 or s.appRoot}
}
