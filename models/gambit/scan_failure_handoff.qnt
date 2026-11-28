// Proposed diagnostic failure protocol, not native runtime acceptance.
// Failure recognition, revocation, cleanup/return, observation and retry are distinct.
module scan_failure_handoff {
  type State={mode:int,bug:int,phase:int,failed:bool,cap:bool,pending:int,
    opened:bool,mapping:bool,used:bool,claims:int,otherCap:bool,
    revoked:bool,exposed:bool,cleanup:bool,refused:bool,returned:bool,
    checked:bool,admitted:bool,retry:bool,retryRefused:bool,
    fatal:bool,escaped:bool,terminated:bool,repeated:bool,finished:bool}
  var s:State
  pure def initial(mode:int,bug:int):State={mode:mode,bug:bug,phase:0,
    failed:false,cap:mode<4,pending:if(mode<4) 1 else 0,
    opened:mode!=7,mapping:mode!=7,used:mode<4,claims:if(mode<4) 1 else 0,
    otherCap:mode!=7,revoked:false,exposed:false,cleanup:false,refused:false,
    returned:false,checked:false,admitted:false,retry:false,retryRefused:false,
    fatal:false,escaped:false,terminated:false,repeated:false,finished:false}
  action initInterrupt=s'=initial(0,0)
  action initOsMemory=s'=initial(1,0)
  action initSync=s'=initial(2,0)
  action initVmPublish=s'=initial(3,0)
  action initDirectGlobal=s'=initial(4,0)
  action initCleanupAccepted=s'=initial(5,0)
  action initCleanupRefused=s'=initial(6,0)
  action initBeforePrepare=s'=initial(7,0)
  action initLiveCleanupRefusal=s'=initial(8,0)
  action initRetryOnly=s'=initial(0,2)
  action initMissingOsRevoke=s'=initial(1,1)
  action initMissingSyncRevoke=s'=initial(2,1)
  action initVmLateRevoke=s'=initial(3,3)
  action initDirectGlobalOpen=s'=initial(4,4)
  action initRefusedCleanupOpen=s'=initial(6,5)
  action initLateArm=s'=initial(1,1)
  action initGlobalCloseLocal=s'=initial(0,6)
  action initCloseLiveRefusal=s'=initial(8,7)

  val local=s.mode<4
  val globalError=Set(4,5,6,7).contains(s.mode)
  val alive=not(s.finished) and not(s.terminated)
  action noticeFailure=all {alive,s.phase==0,s.mode!=8,
    s'={...s,phase:1,failed:true}}
  action localRevoke=all {alive,local,s.phase==1,
    s'={...s,phase:2,cap:if(Set(1,2,3).contains(s.bug)) s.cap else false,
      pending:if(Set(1,2,3).contains(s.bug)) s.pending else 0,
      revoked:not(Set(1,2,3).contains(s.bug)),
      opened:if(s.bug==6) false else s.opened}}
  action directLocalReturn=all {alive,s.mode==0,s.phase==2,
    s'={...s,phase:4,returned:true,exposed:true}}
  action localCleanup=all {alive,local,s.mode!=0,s.phase==2,
    s'={...s,phase:3,cleanup:true,exposed:true}}
  action afterLocalCleanup=all {alive,local,s.phase==3,
    s'={...s,phase:4,returned:true,
      cap:if(s.bug==3) false else s.cap,
      pending:if(s.bug==3) 0 else s.pending}}
  action observeLocalWindow=all {alive,local,s.phase==4,not(s.checked),
    s'={...s,checked:true,admitted:s.cap and s.opened and s.used}}
  action retryEntry=all {alive,local,s.phase==4,s.checked,
    s'={...s,phase:5,retry:true,cap:false,pending:0}}
  action usedSlotRefusal=all {alive,local,s.phase==5,s.used,
    s'={...s,phase:6,retryRefused:true,finished:true}}

  action preErrorClose=all {alive,globalError,s.phase==1,
    s'={...s,phase:2,opened:if(Set(4,5).contains(s.bug)) s.opened else false}}
  action directGlobalReturn=all {alive,Set(4,7).contains(s.mode),s.phase==2,
    s'={...s,phase:4,returned:true,exposed:true}}
  action callErrorCleanup=all {alive,Set(5,6).contains(s.mode),s.phase==2,
    s'={...s,phase:3,cleanup:true,exposed:true}}
  action acceptedErrorCleanup=all {alive,s.mode==5,s.phase==3,
    s'={...s,phase:4,opened:false,returned:true}}
  action refusedErrorCleanup=all {alive,s.mode==6,s.phase==3,
    s'={...s,phase:4,refused:true}}
  action observeGlobalWindow=all {alive,globalError,s.phase==4,not(s.checked),
    s'={...s,checked:true,admitted:s.opened}}
  action finishGlobal=all {alive,Set(4,5,7).contains(s.mode),s.phase==4,s.checked,
    s'={...s,finished:true}}
  action enterFatal=all {alive,s.mode==6,s.phase==4,s.checked,s.refused,
    s'={...s,phase:5,fatal:true}}
  action fatalOutcome=all {alive,s.mode==6,s.phase==5,
    nondet escape=Set(false,true).oneOf()
    s'={...s,phase:6,escaped:escape,terminated:not(escape)}}
  action subsequentSetup=all {alive,s.mode==6,s.phase==6,s.escaped,
    s'={...s,phase:7,repeated:true,opened:false,finished:true}}
  action liveCleanupRefusal=all {alive,s.mode==8,s.phase==0,
    s'={...s,phase:4,cleanup:true,refused:true,
      opened:if(s.bug==7) false else s.opened,finished:true}}
  action idle=s'=s
  action step=any {noticeFailure,localRevoke,directLocalReturn,localCleanup,
    afterLocalCleanup,observeLocalWindow,retryEntry,usedSlotRefusal,
    preErrorClose,directGlobalReturn,callErrorCleanup,acceptedErrorCleanup,
    refusedErrorCleanup,observeGlobalWindow,finishGlobal,enterFatal,fatalOutcome,
    subsequentSetup,liveCleanupRefusal,idle}
  val noLateAdmission=not(s.admitted)
  val closedOnRefusal=not(s.mode==6 and s.refused) or not(s.opened)
  val safe=all {
    not(local and s.failed and s.exposed) or (not(s.cap) and s.pending==0),
    not(globalError and s.failed and s.exposed) or not(s.opened),
    not(local) or (s.opened and s.otherCap and s.used and s.claims==1),
    s.mapping==(s.mode!=7),
    not(s.mode==8 and s.refused) or (s.opened and s.otherCap),
    noLateAdmission
  }
}
