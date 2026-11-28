// Conditional refinement of leaf/entry/collective-return obligations. Not C admission.
module delivery_commit_entry_return {
  type State={mode:int,bug:int,kind:int,phase:int,registered:bool,count:int,
    closed:bool,valid:bool,callerOwns:bool,touched:bool,accepted:bool,
    rooted:bool,active:bool,locks:bool,unlinks:int,owner:int,woken:bool,
    wantGC:bool,gcInside:bool,escaped:bool,retained:bool,reset:bool,
    sfun:bool,decision:int,seen0:bool,seen1:bool,epoch:int,ackEpoch:int,
    result0:int,result1:int,ret0:bool,ret1:bool,done:bool}
  var s:State
  // Modes:0 entry,1 commit,2 common refusal,3 outer throw,4 invalid host,
  // 5 fatal partial commit,6 reset,7 closed host,8 wrong collective phase.
  pure def initial(mode:int,bug:int,kind:int):State={mode:mode,bug:bug,kind:kind,
    phase:0,registered:Set(1,5).contains(mode),
    count:if(Set(1,5).contains(mode)) 1 else if(mode==2) 2 else 0,
    closed:Set(6,7,8).contains(mode),valid:mode!=4,callerOwns:true,
    touched:false,accepted:false,rooted:true,active:false,locks:false,
    unlinks:0,owner:1,woken:false,wantGC:false,gcInside:false,escaped:false,
    retained:false,reset:false,sfun:Set(2,3,8).contains(mode),decision:0,
    seen0:false,seen1:false,epoch:1,ackEpoch:if(mode==8) 0 else 1,
    result0:0,result1:0,ret0:false,ret1:false,done:false}
  action initEntry=all {nondet k=Set(0,1,2,3,4,5,6,7,8).oneOf() s'=initial(0,0,k)}
  action initNoOwner=s'=initial(4,0,4)
  action initClosedHost=s'=initial(7,0,5)
  action initCommit=s'=initial(1,0,0)
  action initBusy=s'=initial(2,0,0)
  action initThrow=s'=initial(3,0,0)
  action initFault=s'=initial(5,0,0)
  action initReset=s'=initial(6,0,0)
  action initStaleGuard=s'=initial(8,0,0)
  action initMissingRegister=s'=initial(0,1,0)
  action initAsyncBypass=s'=initial(0,2,3)
  action initRawHost=s'=initial(4,3,4)
  action initLegacyDrop=s'=initial(7,4,5)
  action initEarlyPopRelease=s'=initial(0,5,6)
  action initLostPopRoot=s'=initial(0,6,6)
  action initGcInCommit=s'=initial(1,7,0)
  action initEscapeInCommit=s'=initial(1,8,0)
  action initRetryUnlink=s'=initial(1,9,0)
  action initLocalReturn=s'=initial(2,10,0)
  action initWrongError=s'=initial(2,11,0)
  action initMissingReopen=s'=initial(3,12,0)
  action initStaleAck=s'=initial(8,13,0)
  action initResetWithDebt=s'={...initial(6,14,0),count:1}

  val entryMode=Set(0,4,7).contains(s.mode)
  val collective=Set(2,3,8).contains(s.mode)
  val critical=Set(1,5).contains(s.mode) and Set(1,2,3).contains(s.phase)
  val safe=all {not(s.gcInside),not(s.escaped),s.unlinks<=1,
    not(entryMode and s.touched and s.phase<6) or s.registered,
    not(entryMode and s.accepted and s.phase<6) or s.rooted,
    not(entryMode and not(s.valid)) or not(s.touched),
    not(entryMode and s.done and not(s.accepted)) or s.callerOwns,
    not(s.reset) or s.count==0,
    not(collective and (s.ret0 or s.ret1)) or
      (s.seen0 and s.seen1 and s.ackEpoch==s.epoch and
       s.result0==s.decision and s.result1==s.decision and not(s.sfun))}
  action closeEntry=all {entryMode,s.phase==0,not(s.closed),s.count==0,
    s'={...s,closed:true}}
  action register=all {entryMode,s.phase==0,
    if((s.closed or not(s.valid)) and s.bug!=3)
      s'={...s,phase:6,done:true,callerOwns:if(s.bug==4) false else true}
    else s'={...s,phase:1,registered:not(Set(1,2).contains(s.bug)),
      count:if(Set(1,2).contains(s.bug)) 0 else 1}}
  action touch=all {entryMode,s.phase==1,s'={...s,phase:2,touched:true}}
  action publishOrPop=all {entryMode,s.phase==2,
    s'={...s,phase:3,accepted:true,callerOwns:false,rooted:s.bug!=6}}
  action execute=all {entryMode,s.phase==3,
    s'={...s,phase:4,active:true,registered:s.bug!=5}}
  action finishEntry=all {entryMode,s.phase==4,
    s'={...s,phase:6,active:false,registered:false,count:0,done:true}}

  action prepare=all {Set(1,5).contains(s.mode),s.phase==0,
    s'={...s,phase:1,locks:true}}
  action unlink=all {Set(1,5).contains(s.mode),s.phase==1,
    s'={...s,phase:2,unlinks:s.unlinks+1}}
  action requestGC=all {not(s.done),not(s.wantGC),s'={...s,wantGC:true}}
  action collect=all {not(s.done),s.wantGC,not(critical) or s.bug==7,
    s'={...s,wantGC:false,gcInside:s.gcInside or critical}}
  action escape=all {s.bug==8,s.phase==2,
    s'={...s,escaped:true,ret0:true}}
  action retryUnlink=all {s.bug==9,s.phase==2,
    s'={...s,unlinks:s.unlinks+1}}
  action commitOwner=all {Set(1,5).contains(s.mode),s.phase==2,
    s.mode!=5,s'={...s,phase:3,owner:2}}
  action unlock=all {s.mode==1,s.phase==3,s'={...s,phase:4,locks:false}}
  action wake=all {s.mode==1,s.phase==4,
    s'={...s,phase:5,woken:true}}
  action complete=all {s.mode==1,s.phase==5,
    s'={...s,phase:6,registered:false,count:0,done:true}}
  action faultRetain=all {s.mode==5,s.phase==2,
    s'={...s,phase:6,retained:true,done:true}}

  action decide=all {collective,s.phase==0,
    s'={...s,phase:1,decision:if(s.mode==3) 2 else 1,seen0:true}}
  action peerReceive=all {collective,s.phase==1,
    s'={...s,phase:2,seen1:true,
      result0:if(s.bug==11) 0 else s.decision,result1:s.decision}}
  action earlyLocal=all {s.bug==10,s.phase==1,s'={...s,ret0:true}}
  action finishCommon=all {collective,s.phase==2,
    s.ackEpoch==s.epoch or s.bug==13,
    s'={...s,phase:6,ret0:true,ret1:true,
      sfun:if(s.bug==12) true else false,done:true}}
  action retainStale=all {s.mode==8,s.phase==2,s.bug==0,
    s'={...s,phase:6,retained:true,done:true}}
  action reset=all {s.mode==6,s.phase==0,s.count==0 or s.bug==14,
    s'={...s,phase:6,reset:true,done:true}}
  action idle=s'=s
  action step=any {closeEntry,register,touch,publishOrPop,execute,finishEntry,
    prepare,unlink,requestGC,collect,escape,retryUnlink,commitOwner,unlock,wake,
    complete,faultRetain,decide,peerReceive,earlyLocal,finishCommon,retainStale,reset,idle}
}
