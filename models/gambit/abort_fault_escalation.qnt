// Fault escalation dependency control, not an implementation of a new channel.
module abort_fault_escalation {
 type State={profile:int,pipeValid:bool,independentCarrier:bool,
 unlocked:bool,runReturned:bool,started:bool,byte:bool,awake:bool,
 arrived:bool,reported:bool,retained:bool}
 var s:State
 pure def initial(p:int):State={profile:p,pipeValid:p==0,
 independentCarrier:p==3,unlocked:false,runReturned:false,started:false,
 byte:false,awake:false,arrived:false,reported:false,retained:false}
 action initHealthy=s'=initial(0)
 action initBrokenWait=s'=initial(1)
 action initBrokenRetain=s'=initial(2)
 action initIndependentCarrier=s'=initial(3)
 action finishUnlocks=all{not(s.unlocked),s'={...s,unlocked:true}}
 action returnRun=all{s.unlocked,not(s.runReturned),s'={...s,runReturned:true}}
 action startP0ErrorCollective=all{s.runReturned,not(s.started),s.profile!=2,
 s'={...s,started:true,byte:s.pipeValid}}
 action wakePeer=all{s.started,not(s.awake),s.byte or s.independentCarrier,
 s'={...s,awake:true,byte:false}}
 action peerServicesSync=all{s.awake,not(s.arrived),s'={...s,arrived:true}}
 action propagateP0Error=all{s.arrived,not(s.reported),s'={...s,reported:true}}
 action retainFault=all{s.profile==2,s.runReturned,not(s.retained),
 s'={...s,retained:true}}
 val circularWait=s.started and not(s.awake) and not(s.pipeValid)
 and not(s.independentCarrier)
 val safe=not(circularWait)
 val done=s.reported
 action step=any{finishUnlocks,returnRun,startP0ErrorCollective,wakePeer,
 peerServicesSync,propagateP0Error,retainFault,
 all{done or s.retained or circularWait,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
