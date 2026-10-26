module run_ack_refinement {
  // Refinement slice: real TRY exit, owner-local RC unlink, GC reader grace.
  // Modes: return, allocation failure, outward throw, trampoline retry, blocked B.
  type S={mode:int,bug:int,stage:int,marker:bool,kills:int,context:bool,catcher:bool,
    tail:bool,retried:bool,error:bool,msg:int,bRoot:bool,aRoot:bool,domain:bool,
    owner:bool,ack:bool,scan:bool,gc:int,bVersion:int,aVersion:int,locked:bool,
    lockUsed:bool,detaches:int,freed:bool,bad:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,stage:0,marker:false,kills:0,
    context:true,catcher:false,tail:false,retried:false,error:false,msg:0,
    bRoot:false,aRoot:false,domain:false,owner:true,ack:false,scan:false,
    gc:0,bVersion:0,aVersion:0,locked:false,lockUsed:false,detaches:0,freed:false,bad:false}
  action initReturn=s'=initial(0,0)
  action initAllocFailure=s'=initial(1,0)
  action initThrow=s'=initial(2,0)
  action initRetry=s'=initial(3,0)
  action initBlocked=s'=initial(4,0)
  action initBypassKill=s'=initial(2,1)
  action initTailBeforeKill=s'=initial(0,2)
  action initAckWithoutRoot=s'=initial(0,3)
  action initUnlinkDuringScan=s'=initial(0,4)
  action initRemoteUnlink=s'=initial(0,5)
  action initDropDomain=s'=initial(0,6)
  action initDuplicateKill=s'=initial(0,7)
  action initStaleRoot=s'=initial(0,8)
  action initPostFreeRead=s'=initial(0,9)
  action initRetryUnwinds=s'=initial(3,10)
  action initLockedDetach=s'=initial(0,11)
  action enter=all {s.stage==0,s'={...s,stage:1,catcher:true}}
  action allocationFailure=all {s.stage==1,s.mode==1,s'={...s,stage:3,error:true,catcher:false}}
  action allocate=all {s.stage==1,s.mode!=1,s'={...s,stage:2,marker:true}}
  action retry=all {s.stage==2,s.mode==3,not(s.retried),s'={...s,retried:true}}
  action publish=all {s.stage==2,s.msg==0,s.mode!=3 or s.retried,
    s'={...s,msg:1,bRoot:true,domain:true,bVersion:s.gc}}
  action bodyExit=all {s.stage==2,s.msg>=1,s.mode!=4,
    s'={...s,stage:3,catcher:false,error:s.mode==2}}
  action finalize=all {s.stage==3,not(s.scan),
    s'={...s,stage:4,marker:false,kills:if(s.marker) s.kills+1 else s.kills}}
  action nativeTail=all {s.stage==4,s'={...s,stage:5,tail:true,context:false}}
  action receive=all {s.msg==1,not(s.scan),s'={...s,msg:2,aRoot:true,aVersion:s.bVersion,ack:true}}
  action gcStart=all {not(s.scan),s.gc<2,not(s.freed),s'={...s,scan:true}}
  action gcFinish=all {s.scan,s'={...s,scan:false,gc:s.gc+1,
    bVersion:if(s.bRoot) s.gc+1 else s.bVersion,aVersion:if(s.aRoot) s.gc+1 else s.aVersion}}
  action lock=all {not(s.lockUsed),s.domain,s'={...s,locked:true,lockUsed:true}}
  action unlock=all {s.locked,s'={...s,locked:false}}
  action ownerDetach=all {s.msg==2,s.ack,s.owner,s.mode!=4,not(s.scan),not(s.locked),
    s'={...s,msg:3,bRoot:false,domain:false,detaches:s.detaches+1}}
  action releaseReceiver=all {s.msg==3,s.stage==5,not(s.scan),s'={...s,msg:4,aRoot:false}}
  action free=all {s.stage==5,not(s.domain),not(s.aRoot),not(s.scan),not(s.freed),s'={...s,freed:true}}
  action mutant=any {
    all {s.bug==1,s.stage==3,s.marker,s'={...s,stage:4}},
    all {s.bug==2,s.stage==3,s.marker,s'={...s,context:false,tail:true}},
    all {s.bug==3,s.msg==1,s'={...s,msg:2,ack:true}},
    all {s.bug==4,s.msg==2,s.scan,s'={...s,bRoot:false,bad:true}},
    all {s.bug==5,s.msg==2,s'={...s,bad:true}},
    all {s.bug==6,s.msg==1,s'={...s,domain:false}},
    all {s.bug==7,s.stage==4,s.kills==1,s'={...s,kills:2}},
    all {s.bug==8,s.msg==2,s.gc>0,not(s.scan),s'={...s,aVersion:0}},
    all {s.bug==9,s.freed,s'={...s,bad:true}},
    all {s.bug==10,s.stage==2,s.retried,s'={...s,marker:false,kills:1}},
    all {s.bug==11,s.msg==2,s.locked,s'={...s,bad:true}}
  }
  action step=any {enter,allocationFailure,allocate,retry,publish,bodyExit,finalize,
    nativeTail,receive,gcStart,gcFinish,lock,unlock,ownerDetach,releaseReceiver,free,mutant}
  val safe=not(s.bad) and s.kills<=1 and s.detaches<=1 and
    (s.stage<4 or not(s.marker)) and (not(s.tail) or (s.stage==5 and not(s.marker) and not(s.catcher))) and
    (s.stage!=2 or s.marker) and (s.stage>=5 or s.context) and
    (not(s.ack) or s.msg>=2) and (s.msg!=2 or s.aRoot) and
    (not(s.bRoot) or (s.domain and s.owner)) and
    (s.msg!=1 or s.bRoot) and (s.msg!=2 or s.bRoot) and
    (s.scan or ((not(s.bRoot) or s.bVersion==s.gc) and (not(s.aRoot) or s.aVersion==s.gc))) and
    (not(s.freed) or (s.stage==5 and not(s.context) and not(s.marker) and not(s.domain) and not(s.aRoot) and not(s.scan)))
}
