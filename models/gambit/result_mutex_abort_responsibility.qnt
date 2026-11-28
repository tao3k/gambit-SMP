// Two sequential publications; one bounded transient write interruption.
// No fd lifetime, full ARM, arbitrary signal stream or native recovery proof.
module result_mutex_abort_responsibility {
 type State={scenario:int,policy:int,epoch:int,ack:int,pending:bool,
 issuer:bool,pipe:bool,receiver:bool,parked:bool,outcome:int,
 returned:bool,reported:bool,retried:bool,fault:bool,admitted:bool,started:bool}
 var s:State
 pure def initial(sc:int,p:int):State={scenario:sc,policy:p,epoch:0,ack:0,
 pending:false,issuer:false,pipe:sc==1,receiver:false,parked:true,outcome:0,
 returned:false,reported:false,retried:false,fault:false,admitted:false,started:false}
 action initWrite=s'=initial(0,0)
 action initEagainDrainRace=s'=initial(1,0)
 action initEintrRetry=s'=initial(2,0)
 action initHardError=s'=initial(3,0)
 action initTwoEpochs=s'=initial(4,0)
 action initIgnoreEintr=s'=initial(2,1)
 action initDrainWithoutRecheck=s'=initial(1,2)
 action initStaleAck=s'=initial(4,3)
 action initHardErrorAdmitted=s'=initial(3,4)
 action publish=all{not(s.started),s'={...s,started:true,epoch:1,pending:true,issuer:true}}
 // Actual fixed one-byte write outcome; no allocation/lock/callback is hidden here.
 action attemptWrite=all{s.started,s.issuer,s.outcome==0,not(s.fault),
 s'=if(s.scenario==3) {...s,outcome:4,fault:true,admitted:s.policy==4}
 else if(s.scenario==2) {...s,outcome:3,
    issuer:s.policy!=1,returned:s.policy==1}
 else if(s.scenario==1 and s.pipe) {...s,outcome:2}
 else {...s,outcome:1,pipe:true}}
 action retryEintr=all{s.outcome==3,s.issuer,not(s.retried),
 s'={...s,retried:true,outcome:1,pipe:true}}
 // The byte may be drained before the writer has inspected its result.
 // Effective handoff is to an awake receiver that must recheck durable ready state.
 action drain=all{s.started,s.pipe,
 s'={...s,pipe:false,parked:false,receiver:s.policy!=2}}
 action acceptWriteOutcome=all{s.issuer,(s.outcome==1 or s.outcome==2),
 s'={...s,issuer:false,returned:true}}
 action serviceReady=all{s.pending,s.receiver,not(s.parked),
 s'={...s,pending:false,ack:s.epoch,receiver:false}}
 action finish=all{s.returned,not(s.pending),s.ack==s.epoch,not(s.reported),
 s'={...s,reported:true,admitted:true}}
 // Acknowledgment is tied to publication incarnation, not just ack!=0.
 action nextEpoch=all{s.scenario==4,s.epoch==1,s.reported,
 s'={...s,epoch:2,pending:true,issuer:s.policy!=3,pipe:false,receiver:false,
 parked:true,outcome:0,returned:s.policy==3,reported:false,admitted:false}}
 val done=s.reported and s.ack==s.epoch and
   (s.scenario!=4 or s.epoch==2)
 val retainedFault=s.fault and s.issuer and s.pending and not(s.admitted)
 val carrier=not(s.pending) or s.issuer or s.pipe or s.receiver
 val safe=all{carrier,not(s.fault and s.admitted),
   not(s.admitted) or (s.ack==s.epoch and not(s.pending)),
   not(s.pending) or s.ack<s.epoch}
 action step=any{publish,attemptWrite,retryEintr,drain,acceptWriteOutcome,
 serviceReady,finish,nextEpoch,all{done or retainedFault,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
