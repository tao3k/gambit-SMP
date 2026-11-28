// Projection of an independent return contract, not a native scheduler model.
// All profiles start with an accepted queue obligation and a live owner scope.
module independent_wake_return {
 type State={carrier:int,bug:int,phase:int,fault:bool,writer:bool,
 armed:bool,signal:bool,parked:bool,returned:bool,pLock:bool,
 observed:bool,acked:bool,root:bool,queueOwned:bool,fdOpen:bool,
 reported:bool,timerReady:bool,internalExpired:bool,realDeadline:bool,
 instance:int,ackInstance:int,bad:bool,terminalAuthorized:bool,completed:bool}
 var s:State
 pure def initial(c:int,b:int):State={carrier:c,bug:b,phase:0,fault:false,
 writer:true,armed:c==1 and b!=1,signal:false,parked:false,returned:false,
 pLock:true,observed:false,acked:false,root:true,queueOwned:true,fdOpen:true,
 reported:false,timerReady:false,internalExpired:false,realDeadline:false,
 instance:2,ackInstance:2,bad:false,terminalAuthorized:b==10,completed:false}
 action initSlice=s'=initial(1,0)
 action initAtomicSignal=s'=initial(2,0)
 action initSpareChannel=s'=initial(3,0)
 action initAuthorizedDisposition=s'=initial(1,10)
 action initFaultOnlySlice=s'=initial(1,1)
 action initSignalBeforePlainSelect=s'=initial(2,2)
 action initEarlyDeviceTimeout=s'=initial(1,3)
 action initDispatchWithProcessorLock=s'=initial(1,4)
 action initStaleAcknowledgment=s'=initial(1,5)
 action initCloseBeforeWriter=s'=initial(1,6)
 action initClearFaultBeforeObservation=s'=initial(1,7)
 action initUnrootedFaultObserver=s'=initial(1,8)
 action initFakeCompletion=s'=initial(1,9)
 action initSpareAlsoBroken=s'=initial(3,11)
 action precheck=all{s.phase==0,not(s.fault),s'={...s,phase:1}}
 action publishFault=all{not(s.fault),s.phase<=3,
 s'={...s,fault:true,
 signal:if(s.carrier==2) (s.bug!=2 or s.parked) else s.signal}}
 action commitWait=all{s.phase==1,
 s'={...s,phase:2,parked:true}}
 action returnWithoutWaiting=all{s.phase==0,s.fault,
 s'={...s,phase:3,returned:true}}
 action quantumReturn=all{s.phase==2,s.armed,
 s'={...s,phase:3,parked:false,returned:true,internalExpired:true,timerReady:s.bug==3}}
 action signalReturn=all{s.phase==2,s.signal,
 s'={...s,phase:3,parked:false,returned:true}}
 action spareReturn=all{s.phase==2,s.carrier==3,s.fault,s.bug!=11,
 s'={...s,phase:3,parked:false,returned:true}}
 action writerEnds=all{s.fault,s.writer,s'={...s,writer:false}}
 // A healthy internal slice may return before the fault was published.
 // Keep the native obligation; this projection waits at that return boundary.
 action snapshot=all{s.phase==3,s.fault,
 s'={...s,phase:4,observed:true,root:s.bug!=8,
 ackInstance:if(s.bug==5) 1 else s.instance}}
 action callerUnlock=all{s.phase==4,s.pLock,s'={...s,pLock:false}}
 action report=all{s.phase==4,not(s.reported),not(s.pLock) or s.bug==4,
 s'={...s,phase:5,reported:true,acked:true,bad:s.pLock}}
 action close=all{s.phase==5,s.acked,
 s.ackInstance==s.instance or s.bug==5,
 not(s.writer) or s.bug==6,
 s'={...s,phase:6,fdOpen:false}}
 action dropFault=all{s.bug==7,s.fault,not(s.observed),
 s'={...s,fault:false,bad:true}}
 action dispose=all{s.phase==6,s.terminalAuthorized or s.bug==9,
 s'={...s,phase:7,queueOwned:false,completed:true,bad:s.bug==9}}
 val stranded=s.parked and s.fault and not(s.armed) and not(s.signal)
 and not(s.carrier==3 and s.bug!=11)
 val safe=all{not(stranded),not(s.bad),
 not(s.timerReady) or s.realDeadline,
 not(s.observed) or s.root,
 not(s.acked) or s.ackInstance==s.instance,
 s.fdOpen or (not(s.writer) and s.acked),
 s.queueOwned or (s.completed and s.terminalAuthorized)}
 val observedSafely=s.reported and not(s.pLock) and s.root
 val done=s.phase==6 or s.phase==7
 action step=any{precheck,publishFault,commitWait,returnWithoutWaiting,
 quantumReturn,signalReturn,spareReturn,writerEnds,snapshot,callerUnlock,
 report,close,dropFault,dispose,all{done,s'=s}}
 temporal observation=weakFair(step,Set(s)).implies(eventually(observedSafely))
}
