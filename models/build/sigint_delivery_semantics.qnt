module sigint_delivery_semantics {
 // Source-serial reference bit versus candidate target/claim-epoch pending key.
 // VM generations, vector revisions and dynamic handler identities are abstract names.
 type State={vm:int,live:Set[int],closed:bool,pending:bool,keys:Set[int],epoch:int,
  stage:int,target:int,vector:int,selected:int,currentThread:bool,thread:int,param:int,
  reference:List[int],candidate:List[int],deferred:bool,replays:int,unbound:int,wake:bool}
 pure val initial:State={vm:1,live:Set(1),closed:false,pending:false,keys:Set(),epoch:0,
  stage:0,target:0,vector:1,selected:0,currentThread:true,thread:0,param:1,
  reference:[],candidate:[],deferred:false,replays:0,unbound:0,wake:false}
 var s:State
 action init=s'=initial
 def key=s.vm*100+s.epoch
 val safe=all{s.pending==(s.keys.size()>0),s.keys.size()<=1,
  s.keys.forall(k=>k==key),s.reference==s.candidate,
  s.stage>0 implies s.live.contains(s.target),
  s.pending implies s.live.contains(s.vm),s.epoch<=8}
 // Mailbox only wakes: target-bound pending state remains authoritative.
 action publish=all{not(s.closed),s.live.contains(s.vm),s'={...s,pending:true,keys:s.keys.union(Set(key)),wake:true}}
 action takeWake=all{s.wake,s'={...s,wake:false}}
 // Claim/clear is the coalescing cut, not completion of the Scheme callback.
 action claim=all{s.pending,s.stage==0,s.epoch<8,
  s'={...s,pending:false,keys:s.keys.exclude(Set(key)),epoch:s.epoch+1,stage:1,target:s.vm}}
 action replaceVector=all{s'={...s,vector:3-s.vector}}
 action fetchVector=all{s.stage==1,s'={...s,selected:s.vector,stage:2}}
 action setThread=all{s.stage<3,s'={...s,currentThread:not(s.currentThread)}}
 action chooseThread=all{s.stage==2,s'={...s,thread:if(s.currentThread)1 else 2,stage:3}}
 action setParameter=all{s'={...s,param:if(s.param==0)1 else 0}}
 // The two observers use independent expressions but share admitted source cuts.
 // identity = target*100 + selectedVector*10 + thread*2 + handler.
 action execute=all{s.stage==3,
  s'={...s,reference:s.reference.append(s.target*100+s.selected*10+s.thread*2+s.param),
   candidate:s.candidate.concat([s.param+2*s.thread+10*s.selected+100*s.target]),
   deferred:s.deferred or s.param==0,stage:0,target:0}}
 // Separate source pending-user flag: replay is performed by the setter filter.
 action installHandler=all{s.deferred,s'={...s,deferred:false,replays:s.replays+1}}
 action close=all{not(s.closed),s'={...s,closed:true}}
 action retainUnbound=all{s.closed,s'={...s,unbound:s.unbound+1}}
 action retireVm=all{s.closed,not(s.pending),s.stage==0,s.live.contains(s.vm),s'={...s,live:s.live.exclude(Set(s.vm))}}
 action startNext=all{s.closed,s.live==Set(),s.vm==1,s'={...s,vm:2,live:Set(2),closed:false,vector:1,param:1}}
 action step=any{publish,takeWake,claim,replaceVector,fetchVector,setThread,chooseThread,setParameter,execute,installHandler,close,retainUnbound,retireVm,startNext,all{s'=s}}
 action deliver=claim.then(fetchVector).then(chooseThread).then(execute)
 run sameEpochMergeTest=init.then(publish).then(publish).then(deliver).then(all{assert(safe and s.reference.length()==1),s'=s})
 run afterClearNewDeliveryTest=init.then(publish).then(claim).then(publish).then(fetchVector).then(chooseThread).then(execute).then(deliver).then(all{assert(safe and s.reference.length()==2),s'=s})
 run vectorBeforeFetchTest=init.then(publish).then(claim).then(replaceVector).then(fetchVector).then(chooseThread).then(execute).then(all{assert(safe and s.reference==[123]),s'=s})
 run vectorAfterFetchTest=init.then(publish).then(claim).then(fetchVector).then(replaceVector).then(chooseThread).then(execute).then(all{assert(safe and s.reference==[113]),s'=s})
 run parameterAtExecutionTest=init.then(setThread).then(publish).then(claim).then(fetchVector).then(chooseThread).then(setParameter).then(execute).then(all{assert(safe and s.reference==[114] and s.deferred),s'=s}).then(installHandler).then(all{assert(s.replays==1 and not(s.deferred)),s'=s})
 run primordialFallbackTest=init.then(setThread).then(publish).then(deliver).then(all{assert(safe and s.reference==[115]),s'=s})
 run lateUnboundRetainedTest=init.then(close).then(retireVm).then(retainUnbound).then(startNext).then(all{assert(safe and s.unbound==1 and s.reference==[]),s'=s})
 run closedTargetDrainTest=init.then(publish).then(close).then(deliver).then(retireVm).then(startNext).then(all{assert(safe and s.reference==[113]),s'=s})
 run wakeNotDeliveryTest=init.then(publish).then(takeWake).then(all{assert(safe and s.pending and not(s.wake)),s'=s}).then(deliver).then(all{assert(safe),s'=s})
 run crossClaimMergeControlTest=init.then(publish).then(deliver).then(publish).then(deliver).then(all{s'={...s,candidate:[113]}}).then(all{assert(not(safe)),s'=s})
 run arrivalVectorControlTest=init.then(publish).then(claim).then(replaceVector).then(fetchVector).then(chooseThread).then(execute).then(all{s'={...s,candidate:[113]}}).then(all{assert(not(safe)),s'=s})
 run earlyParameterControlTest=init.then(setThread).then(publish).then(claim).then(fetchVector).then(chooseThread).then(setParameter).then(execute).then(all{s'={...s,candidate:[115]}}).then(all{assert(not(safe)),s'=s})
 run retargetControlTest=init.then(publish).then(claim).then(all{s'={...s,live:Set(2)}}).then(all{assert(not(safe)),s'=s})
 run lostPendingControlTest=init.then(publish).then(all{s'={...s,keys:Set()}}).then(all{assert(not(safe)),s'=s})
 run afterFetchRewriteControlTest=init.then(publish).then(claim).then(fetchVector).then(replaceVector).then(chooseThread).then(execute).then(all{s'={...s,candidate:[123]}}).then(all{assert(not(safe)),s'=s})
}
