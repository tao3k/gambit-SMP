module repark_cohort {
  // Starts after callback Scheme result conversion; original host C frame is live.
  // phase0 epilogue,1 request,2 operation done,3 reader grace,4 validated,
  // 5 committed old-cohort tail,6 retained active service,7 departure ACK,8 returned.
  type S={mode:int,bug:int,phase:int,active:bool,serving:bool,host:bool,
    jobRoot:bool,cbRoot:bool,g:bool,jg:bool,cg:bool,dirty:bool,valid:bool,
    materialized:bool,pending:bool,window:bool,readers:bool,committed:bool,
    ack:bool,returned:bool,tail:bool,error:bool,deferred:bool,failed:bool,
    serviced:bool,tlock:bool,plock:bool,mapJob:bool,mapCb:bool,
    usedCached:bool,cached:bool,rankOk:bool,catcher:bool,gcDebt:bool,gcDemand:bool,gcAccepted:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,phase:0,active:true,serving:true,host:true,
    jobRoot:true,cbRoot:true,g:false,jg:false,cg:false,dirty:false,valid:false,
    materialized:false,pending:false,window:false,readers:true,committed:false,
    ack:false,returned:false,tail:true,error:m==1,deferred:false,failed:false,
    serviced:false,tlock:false,plock:false,mapJob:true,mapCb:true,
    usedCached:false,cached:false,rankOk:true,catcher:true,gcDebt:false,gcDemand:false,gcAccepted:false}
  action initSuccess=s'=initial(0,0)
  action initError=s'=initial(1,0)
  action initRetry=s'=initial(2,0)
  action initRetained=s'=initial(3,0)
  action initDropGcDebt=s'=initial(0,15)
  action initOuterJump=s'=initial(0,1)
  action initLocalDetach=s'=initial(0,2)
  action initLostDebt=s'=initial(0,3)
  action initStopService=s'=initial(3,4)
  action initGcInWindow=s'=initial(0,5)
  action initStaleCommit=s'=initial(0,6)
  action initMissingJobMap=s'=initial(0,7)
  action initMissingCallbackMap=s'=initial(1,8)
  action initStaleLocal=s'=initial(0,9)
  action initEarlyReturn=s'=initial(1,10)
  action initEarlyTail=s'=initial(0,11)
  action initLockHeld=s'=initial(0,12)
  action initOldRank=s'=initial(0,13)
  action initThrowFromService=s'=initial(1,14)
  action prepare=all {s.phase==0,s'={...s,phase:1,materialized:true,pending:true,deferred:s.error}}
  // Every GC election owes the following fixed service window. It is not
  // another competing low-priority opcode; repeated collections cannot skip it.
  action collect=all {Set(1,6).contains(s.phase),s.active,s.serving,
    s'={...s,phase:2,gcDebt:false,gcAccepted:s.gcDemand,g:not(s.g),jg:if(s.jobRoot and s.mapJob) not(s.g) else s.jg,
      cg:if(s.cbRoot and s.mapCb) not(s.g) else s.cg,dirty:true,valid:false,readers:true}}
  action noGc=all {Set(1,6).contains(s.phase),not(s.gcDebt),s'={...s,phase:2,readers:true}}
  action readerExit=all {s.phase==2,s'={...s,phase:3,readers:false,window:true}}
  action validate=all {s.phase==3,s.materialized,s'={...s,phase:4,valid:true,dirty:false,serviced:not(s.serviced)}}
  action commit=all {s.phase==4,s.pending,(s.mode!=3 and (s.mode!=2 or s.failed)),
    s'={...s,phase:5,committed:true,active:false,serving:false,rankOk:true,pending:false}}
  action retain=all {s.phase==4,s.mode==3 or (s.mode==2 and not(s.failed)),
    s'={...s,phase:6,failed:true,window:false,valid:false,active:true,serving:true}}
  action departureAck=all {s.phase==5,s'={...s,phase:7,ack:true,window:false}}
  action nativeReturn=all {s.phase==7,s'={...s,phase:8,returned:true,tail:false,cbRoot:false}}
  // Frozen root scanner remains active after B is excluded. No B C local reload.
  action parkedGc=all {s.phase==8,s'={...s,gcDebt:false,gcAccepted:s.gcDemand,g:not(s.g),jg:if(s.mapJob) not(s.g) else s.jg}}
  action requestGc=all {s.window,not(s.gcDemand),s'={...s,gcDebt:true,gcDemand:true,gcAccepted:false}}
  action mutant=any {
    all {s.bug==15,s.gcDebt,s'={...s,gcDebt:false}},
    all {s.bug==1,s.phase==4,s'={...s,host:false}},
    all {s.bug==2,s.phase==1,s'={...s,active:false}},
    all {s.bug==3,s.phase==2,s'={...s,pending:false}},
    all {s.bug==4,s.phase==6,s'={...s,serving:false}},
    all {s.bug==5,s.phase==4,s'={...s,g:not(s.g),jg:not(s.g),cg:not(s.g),dirty:true}},
    all {s.bug==6,s.phase==2,s.dirty,s'={...s,phase:5,committed:true,active:false,serving:false}},
    all {s.bug==7,s.phase==1,s'={...s,mapJob:false}},
    all {s.bug==8,s.phase==1,s'={...s,mapCb:false}},
    all {s.bug==9,s.phase==3,s.g!=s.cached,s'={...s,usedCached:true}},
    all {s.bug==10,s.phase==4,s'={...s,returned:true,tail:false}},
    all {s.bug==11,s.phase==5,s'={...s,tail:false}},
    all {s.bug==12,s.phase==1,s'={...s,tlock:true}},
    all {s.bug==13,s.phase==5,s'={...s,rankOk:false}},
    all {s.bug==14,s.phase==4,s.error,s'={...s,catcher:false,host:false}}
  }
  action idle=s'=s
  action step=any {prepare,collect,noGc,readerExit,validate,commit,retain,departureAck,nativeReturn,parkedGc,requestGc,mutant,idle}
  val safe=all {not(s.gcDemand) or s.gcDebt or s.gcAccepted,s.host,s.catcher,not(s.tlock),not(s.plock),s.rankOk,
    s.jobRoot and s.jg==s.g,not(s.cbRoot) or s.cg==s.g,
    not(s.usedCached) or s.cached==s.g,
    not(s.window and s.valid) or not(s.dirty),
    not(s.committed) or (s.valid and not(s.dirty) and not(s.readers)),
    s.active or s.committed,
    not(s.active) or s.serving,
    s.phase==0 or s.pending or s.committed,
    not(s.returned) or (s.committed and s.ack and not(s.active)),
    s.tail or s.returned,
    not(s.error and s.phase>0) or s.deferred}
  val goal=if(s.mode==3) s.phase==6 and s.failed else s.phase==8
  temporal fairness=all {weakFair(prepare,Set(s)),weakFair(collect,Set(s)),weakFair(noGc,Set(s)),
    weakFair(readerExit,Set(s)),weakFair(validate,Set(s)),weakFair(commit,Set(s)),
    weakFair(retain,Set(s)),weakFair(departureAck,Set(s)),weakFair(nativeReturn,Set(s)),weakFair(parkedGc,Set(s)),weakFair(requestGc,Set(s))}
  temporal progress=fairness.implies(all {eventually(goal),always(s.gcDemand.implies(eventually(s.gcAccepted))),
    if(s.mode==3) all {always(eventually(s.serviced)),always(eventually(not(s.serviced)))} else true})
}
