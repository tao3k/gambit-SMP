// Source refinement obligation, not an implementation or C11 memory model.
module delivery_service_roots {
  type State={bug:int,device:bool,wakeFails:bool,phase:int,accepted:bool,queued:bool,
    runnable:bool,serviceOwner:bool,root:bool,pin:bool,droot:bool,domain:bool,
    locks:bool,active:bool,finite:bool,done:bool,bad:bool,version:int,
    mapped:int,cached:int,retried:bool,finishGc:bool,notified:bool,userTimeout:bool,
    wakeRead:bool,waitCalls:int,reparked:bool,deadlineRevision:int,signalSeen:bool}
  var s:State
  pure def initial(bug:int,device:bool,wakeFails:bool):State={bug:bug,device:device,wakeFails:wakeFails,
    phase:0,accepted:false,queued:false,runnable:false,serviceOwner:false,
    root:true,pin:true,droot:false,domain:true,locks:false,active:true,
    finite:bug!=1,done:false,bad:false,version:0,mapped:0,cached:0,
    retried:false,finishGc:false,notified:false,userTimeout:false,
    wakeRead:false,waitCalls:0,reparked:false,deadlineRevision:0,signalSeen:false}
  action initBare=s'=initial(0,false,true)
  action initDevice=s'=initial(0,true,true)
  action initWakeSuccess=s'=initial(0,true,false)
  action initNoBound=s'=initial(1,true,true)
  action initClearOnNotify=s'=initial(2,true,true)
  action initHiddenGc=s'=initial(3,true,true)
  action initMissingMap=s'=initial(4,true,true)
  action initStaleLocal=s'=initial(5,true,true)
  action initNoDestinationRoot=s'=initial(6,true,true)
  action initDispatchLocked=s'=initial(7,true,true)
  action initFalseTimeout=s'=initial(8,true,true)
  action initEarlyDomainRemove=s'=initial(9,true,true)
  action initEscapeLocked=s'=initial(10,true,true)
  // Source-bound refinements of the existing wait/service machine. These
  // faults preserve the request root and pin: the defect is the wait handoff,
  // not a second ownership or queue protocol. not(wakeFails) abstracts a real
  // internal wake byte/event, not an ordinary signal or an EOF.
  action initConsumedInternalWake=s'=initial(11,true,false)
  action initReparkRunnable=s'=initial(12,true,true)
  action initRefreshedDeadline=s'=initial(13,true,true)
  action accept=all{s.phase==0,s'=s.with("phase",1).with("accepted",true).with("queued",true)}
  // A failed try owns no locks. One GC moves all managed addresses before retry.
  action retryGc=all{s.phase==1,not(s.retried),
    s'=s.with("retried",true).with("version",1)
      .with("mapped",if(s.bug==4) 0 else 1)}
  action enter=all{s.phase==1,s.retried,
    s'=s.with("phase",2).with("locks",true)
      .with("cached",if(s.bug==5) 0 else s.mapped)}
  action hiddenGc=all{s.phase==2,s.bug==3,s'=s.with("bad",true)}
  action escape=all{s.phase==2,s.bug==10,s'=s.with("phase",3).with("active",false)}
  // D has become the durable service owner before producer notification starts.
  action commit=all{s.phase==2,
    s'=s.with("phase",3).with("locks",false).with("queued",false)
      .with("runnable",true).with("serviceOwner",true).with("droot",s.bug!=6)}
  // No interior pointer is carried through GC in the unlocked finish wrapper.
  action finishGc=all{s.phase==3,not(s.finishGc),
    s'=s.with("finishGc",true).with("version",2).with("mapped",2)
      .with("cached",2).with("bad",s.bad or not(s.droot))}
  action notify=all{s.phase==3,s.finishGc,
    s'=s.with("phase",4).with("waitCalls",1).with("notified",not(s.wakeFails))
      .with("serviceOwner",s.bug!=2).with("pin",s.bug!=2)}
  // device_select_impl reports an actual internal wake separately from EINTR.
  // A retry of os_condvar_select after that result is precisely the retained
  // pre-048b source conversion. It does not lose ownership, but violates the
  // prompt return obligation even when the finite cap eventually expires.
  action readInternalWake=all{s.phase==4,s.notified,not(s.wakeRead),
    s'=s.with("wakeRead",true)}
  action retryAfterInternalWake=all{s.phase==4,s.bug==11,s.wakeRead,s.waitCalls==1,
    s'=s.with("waitCalls",2)}
  // Ordinary signal EINTR may retry, but D_eff is computed once outside the
  // retry loop. The revision is an identity of D_eff, not a wall-clock model.
  action ordinarySignal=all{s.phase==4,not(s.notified),not(s.signalSeen),
    s'=s.with("signalSeen",true)
      .with("deadlineRevision",if(s.bug==13) 1 else s.deadlineRevision)}
  // The source queue observation is protected by P after the native arrays
  // have gone out of scope and service has returned. This mutant omits that
  // observation and goes around the same wait again over durable runnable work.
  action reparkQueued=all{s.phase==6,s.bug==12,s.runnable,
    s'=s.with("phase",4).with("waitCalls",s.waitCalls+1).with("reparked",true)}
  // Delayed by arbitrary stuttering, but not by the failed wake channel.
  // Finite-cap and scheduling fairness remain explicit assumptions. They are
  // not a proof of the original 1000/3600-second throughput requirements.
  action returnWait=all{s.phase==4,s.finite or not(s.wakeFails),
    not(s.notified) or s.wakeRead,
    s'=s.with("phase",5).with("locks",s.device).with("userTimeout",s.bug==8)}
  action unlock=all{s.phase==5,s'=s.with("phase",6).with("locks",false)}
  action service=all{s.phase==6 or (s.phase==5 and s.bug==7),
    s'=s.with("phase",7).with("done",true).with("serviceOwner",false)
      .with("runnable",false).with("pin",false).with("droot",false)
      .with("bad",s.bad or s.locks)}
  action removeDomain=all{s.accepted,not(s.done),s.bug==9,s'=s.with("domain",false)}
  action idle=s'=s
  action step=any{accept,retryGc,enter,hiddenGc,escape,commit,finishGc,notify,
    readInternalWake,retryAfterInternalWake,ordinarySignal,reparkQueued,
    returnWait,unlock,service,removeDomain,idle}
  val noRewaitAfterInternalWake=not(s.wakeRead and s.waitCalls>1)
  val noReparkKnownRunnable=not(s.reparked and s.runnable)
  val realDeadlinePreserved=s.deadlineRevision==0
  val bareSafe=safe
  val internalWakeSafe=safe
  val safe=all{noRewaitAfterInternalWake,noReparkKnownRunnable,realDeadlinePreserved,not(s.bad),not(s.userTimeout),s.active or not(s.locks),
    (s.accepted and not(s.done)) implies (s.root and s.pin and s.domain and
      (s.queued or (s.runnable and s.serviceOwner))),
    s.phase==2 implies (s.active and s.locks and s.cached==s.version),
    s.phase>=3 implies not(s.locks) or (s.device and s.phase==5),
    (s.phase==3 and s.finishGc) implies s.droot,
    s.done implies (not(s.pin) and not(s.runnable) and not(s.locks))}
  temporal progress=(weakFair(accept,Set(s)) and weakFair(retryGc,Set(s)) and
    weakFair(enter,Set(s)) and weakFair(commit,Set(s)) and
    weakFair(finishGc,Set(s)) and weakFair(notify,Set(s)) and
    weakFair(readInternalWake,Set(s)) and weakFair(returnWait,Set(s)) and weakFair(unlock,Set(s)) and
    weakFair(service,Set(s))).implies(eventually(s.done))
}
