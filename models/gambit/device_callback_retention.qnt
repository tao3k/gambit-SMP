// Source refinement: checked IO cleanup precedes VM/GC destruction; every
// public winding callback invocation has its own one-use recovery boundary.
// Nonterminating code and raw no-winding/private C jumps are not public exits.
module device_callback_retention {
  type S={bug:int,phase:int,group:bool,device:bool,refs:int,sticky:bool,
    foreignLive:bool,closedStage:bool,closeCalls:int,waits:int,releaseFailed:bool,
    vmRoot:bool,currentRoot:bool,errorRoot:bool,suffix:int,calls:int,
    active:bool,escaped:bool,terminal:bool,freed:bool,bad:bool}
  var s:S
  pure def initial(b:int):S={bug:b,phase:0,group:true,device:true,refs:1,
    sticky:false,foreignLive:true,closedStage:false,closeCalls:0,waits:0,releaseFailed:false,
    vmRoot:true,currentRoot:false,errorRoot:false,suffix:2,calls:0,
    active:false,escaped:false,terminal:false,freed:false,bad:false}
  action init=s'=initial(0)
  action initUnlinkBeforeClose=s'=initial(1)
  action initFreeGroupOnError=s'=initial(2)
  action initClosedStageForgetsError=s'=initial(3)
  action initCallbackEscapes=s'=initial(4)
  action initCallbackReentry=s'=initial(5)
  action initFreeRootsBeforeIo=s'=initial(6)
  action initFailedReleaseFrees=s'=initial(7)
  action initFreeBeforeForeignHandoff=s'=initial(8)
  action initTerminateCoordinator=s'=initial(9)
  action initSuspendCoordinator=s'=initial(10)
  action take=all{s.phase==0,s.suffix>0,
    s'={...s,phase:1,suffix:s.suffix-1,currentRoot:true,active:true,calls:s.calls+1}}
  action lifecycleAttempt={
    nondet op=Set(9,10).oneOf()
    all{s.phase==1,s'={...s,phase:if(s.bug==op) 9 else 2,
      active:false,errorRoot:true,bad:s.bug==op}}
  }
  action callbackGc=all{s.phase==1,not(s.vmRoot and s.currentRoot),s'={...s,bad:true}}
  action callbackReturn=all{s.phase==1,
    s'={...s,phase:2,active:false,errorRoot:true}}
  action callbackEscape=all{s.phase==1,
    s'={...s,phase:if(s.bug==4) 9 else 2,active:false,escaped:true,errorRoot:true,
      bad:s.bug==4}}
  action staleReentry=all{s.phase==1,s.escaped,
    s'={...s,phase:2,active:false,errorRoot:true,
      calls:s.calls+(if(s.bug==5) 1 else 0),bad:s.bug==5}}
  action releaseCurrent=all{s.phase==2,
    s'={...s,phase:0,currentRoot:false}}
  action prepare=all{s.phase==0,s.suffix==0,
    s'={...s,phase:3,vmRoot:s.bug!=6}}
  action disarmForeign=all{s.phase==3,s.foreignLive,s'={...s,foreignLive:false}}
  action eagain=all{s.phase==3,not(s.sticky),not(s.foreignLive) or s.bug==8,s.waits<2,
    s'={...s,waits:s.waits+1}}
  action closeFails=all{s.phase==3,not(s.sticky),not(s.foreignLive) or s.bug==8,
    s'={...s,phase:4,closedStage:true,sticky:true,closeCalls:s.closeCalls+1,
      device:s.bug!=1}}
  action closeSucceeds=all{s.phase==3,not(s.sticky),not(s.foreignLive) or s.bug==8,
    s'={...s,phase:5,closedStage:true,closeCalls:s.closeCalls+1}}
  action retry=all{s.phase==4,
    s'={...s,phase:6,group:s.bug!=2,sticky:s.bug!=3,
      closeCalls:s.closeCalls+(if(s.bug==3) 1 else 0)}}
  action releaseFails=all{s.phase==5,
    s'={...s,phase:6,sticky:true,releaseFailed:true,
      device:s.bug!=7,refs:if(s.bug==7) 0 else 1}}
  action releaseSucceeds=all{s.phase==5,
    s'={...s,phase:7,device:false,group:false,refs:0}}
  action retain=all{s.phase==6,s'={...s,phase:8,terminal:true}}
  action free=all{s.phase==7,
    s'={...s,phase:8,terminal:true,vmRoot:false,freed:true}}
  action idle=all{s.phase==8,s'=s}
  action step=any{take,lifecycleAttempt,callbackGc,callbackReturn,callbackEscape,staleReentry,
    releaseCurrent,prepare,disarmForeign,eagain,closeFails,closeSucceeds,retry,releaseFails,
    releaseSucceeds,retain,free,idle}
  val safe=all{not(s.bad),s.calls<=2,not(s.foreignLive) or s.device,
    s.phase!=1 or (s.currentRoot and s.vmRoot),
    not(s.sticky) or (s.device and s.group and s.refs==1 and s.vmRoot),
    s.phase<3 or s.vmRoot or s.freed,
    s.closeCalls<=1,s.freed.implies(not(s.device) and not(s.group)),
    s.terminal or s.vmRoot}
  temporal completion=weakFair(step,Set(s)).implies(eventually(s.terminal))
}
