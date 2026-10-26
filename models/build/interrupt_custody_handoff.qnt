module interrupt_custody_handoff {
 pure val P=Set(0,1)
 pure val C=Set(0,1,2)
 // p: fresh / accepted / published / left / denied.
 // c: 0 idle, 1 reserved, 2 claimed, 3 unrooted load, 4 rooted, 5 unknown, 6 deferred pre-fetch.
 // Event sets are ghost coverage of coalesced work, not a counted signal queue.
 type State={open:bool,claimOpen:bool,live:bool,p:List[int],c:List[int],
  accepted:Set[int],claimed:Set[int],pending:Set[int],batch:List[Set[int]],done:Set[int],
  selected:List[int],ptr:List[int],loc:int,vector:int,
  writer:int,writerParent:int,arg:int,argPtr:int,parked:Set[int],frozen:bool,writes:int,wake:bool}
 pure val initial:State={open:true,claimOpen:true,live:true,p:[0,0],c:[0,0,0],
  accepted:Set(),claimed:Set(),pending:Set(),batch:[Set(),Set(),Set()],done:Set(),
  selected:[0,0,0],ptr:[0,0,0],loc:0,vector:1,
  writer:0,writerParent:-1,arg:0,argPtr:0,parked:Set(),frozen:false,writes:0,wake:false}
 var s:State
 action init=s'=initial
 def producers=P.filter(i=>s.p[i]==1 or s.p[i]==2)
 def consumers=C.filter(i=>s.c[i]>0)
 def inFlight=s.batch[0].union(s.batch[1]).union(s.batch[2])
 def publishing=P.filter(i=>s.p[i]==1)
 def noTemp=not(C.exists(i=>s.c[i]==3))
 def drained=not(s.open) and producers==Set() and not(s.claimOpen) and consumers==Set() and s.pending==Set() and s.writer==0
 val safe=all{
  s.accepted.subseteq(publishing.union(s.pending).union(inFlight).union(s.done)),
  s.pending.intersect(inFlight)==Set(),s.pending.intersect(s.claimed)==Set(),s.done.subseteq(s.claimed),s.pending.intersect(s.done)==Set(),
  s.batch[0].intersect(s.batch[1])==Set(),s.batch[0].intersect(s.batch[2])==Set(),s.batch[1].intersect(s.batch[2])==Set(),
  C.forall(i=>s.batch[i].size()>0 implies s.c[i]>=2),
  C.forall(i=>(s.c[i]==4 or s.c[i]==5) implies s.ptr[i]==s.selected[i]+s.loc),
  s.writer==1 implies s.argPtr==s.arg+s.loc,
  not(s.live) implies drained,
  (producers.size()>0 or consumers.size()>0 or s.pending.size()>0 or s.writer>0) implies s.live,
  s.frozen implies (s.parked==P and noTemp),
  s.writerParent>=0 implies (s.writer==1 and s.c[s.writerParent]>0),
  not(s.claimOpen) implies (not(s.open) and producers==Set())
 }
 action accept(i)=all{P.contains(i),s.p[i]==0,s.open,s.live,s'={...s,p:s.p.replaceAt(i,1),accepted:s.accepted.union(Set(i))}}
 action deny(i)=all{P.contains(i),s.p[i]==0,not(s.open),s'={...s,p:s.p.replaceAt(i,4)}}
 // Accepted producer remains authorized after Close. Slot storage is domain-owned.
 action publish(i)=all{s.p[i]==1,s.live,s'={...s,p:s.p.replaceAt(i,2),pending:s.pending.union(Set(i)),wake:true}}
 action leave(i)=all{s.p[i]==2,s'={...s,p:s.p.replaceAt(i,3)}}
 action close=all{s.open,s'={...s,open:false}}
 action reserve(i)=all{P.contains(i),s.c[i]==0,s.claimOpen,s.live,s'={...s,c:s.c.replaceAt(i,1)}}
 action claim(i)=all{s.c[i]==1,s.pending.size()>0,s'={...s,c:s.c.replaceAt(i,2),batch:s.batch.replaceAt(i,s.pending),claimed:s.claimed.union(s.pending),pending:Set()}}
 action emptyReturn(i)=all{s.c[i]==1,s.pending==Set(),s'={...s,c:s.c.replaceAt(i,0)}}
 action sealClaims=all{not(s.open),producers==Set(),s.claimOpen,s'={...s,claimOpen:false}}
 // One exclusive coordinator takeover after both admission domains drain.
 action coordinatorReserve=all{not(s.claimOpen),producers==Set(),consumers==Set(),s.pending.size()>0,s.live,s'={...s,c:s.c.replaceAt(2,1)}}
 action loadVector(i)=all{s.c[i]==2,not(s.frozen),s.parked==Set(),s'={...s,c:s.c.replaceAt(i,3),selected:s.selected.replaceAt(i,s.vector),ptr:s.ptr.replaceAt(i,s.vector+s.loc)}}
 // No checkpoint/GC between raw load and putting the value in the scanned slot.
 action rootCapture(i)=all{s.c[i]==3,s'={...s,c:s.c.replaceAt(i,4)}}
 action complete(i)=all{s.c[i]==4,s.parked==Set(),not(s.frozen),s.writerParent!=i,s'={...s,c:s.c.replaceAt(i,0),done:s.done.union(s.batch[i]),batch:s.batch.replaceAt(i,Set()),selected:s.selected.replaceAt(i,0),ptr:s.ptr.replaceAt(i,0)}}
 // Pre-fetch failure parks the original claim; never merge it back across a claim cut.
 action settleFailure(i)=all{s.c[i]==2,s'={...s,c:s.c.replaceAt(i,6)}}
 action resumeClaim(i)=all{s.c[i]==6,s'={...s,c:s.c.replaceAt(i,2)}}
 action unknownOutcome(i)=all{s.c[i]==4,s'={...s,c:s.c.replaceAt(i,5)}}
 action reconcileSuccess(i)=all{s.c[i]==5,s.writerParent!=i,s'={...s,c:s.c.replaceAt(i,0),done:s.done.union(s.batch[i]),batch:s.batch.replaceAt(i,Set()),selected:s.selected.replaceAt(i,0),ptr:s.ptr.replaceAt(i,0)}}
 action requestWrite=all{s.writer==0,s.live,s.open,s.writes<2,s'={...s,writer:1,arg:3-s.vector,argPtr:3-s.vector+s.loc}}
 action requestDerived(i)=all{s.writer==0,s.live,s.c[i]==4,s.writes<2,s'={...s,writer:1,writerParent:i,arg:3-s.vector,argPtr:3-s.vector+s.loc}}
 action park(i)=all{P.contains(i),noTemp,not(s.frozen),s'={...s,parked:s.parked.union(Set(i))}}
 action unpark=all{not(s.frozen),s'={...s,parked:Set()}}
 action rendezvous=all{s.writer==1,s.parked==P,noTemp,not(s.frozen),s'={...s,frozen:true}}
 action commitVector=all{s.writer==1,s.frozen,s.argPtr==s.arg+s.loc,s'={...s,vector:s.arg,writer:0,writerParent:-1,arg:0,argPtr:0,writes:s.writes+1,frozen:false}}
 // STW root rewrite, not concurrent GC. Scanned slots and queued setter argument move.
 action moveGc=all{s.live,s.parked==P,noTemp,not(s.frozen),
  s'={...s,loc:10-s.loc,
   ptr:[if(s.c[0]==4 or s.c[0]==5)s.selected[0]+10-s.loc else s.ptr[0],if(s.c[1]==4 or s.c[1]==5)s.selected[1]+10-s.loc else s.ptr[1],if(s.c[2]==4 or s.c[2]==5)s.selected[2]+10-s.loc else s.ptr[2]],
   argPtr:if(s.writer==1)s.arg+10-s.loc else s.argPtr}}
 action takeWake=all{s.wake,s'={...s,wake:false}}
 action retireVm=all{drained,s.live,s'={...s,live:false}}
 action step=any{accept(0),accept(1),deny(0),deny(1),publish(0),publish(1),leave(0),leave(1),close,reserve(0),reserve(1),claim(0),claim(1),claim(2),emptyReturn(0),emptyReturn(1),emptyReturn(2),sealClaims,coordinatorReserve,loadVector(0),loadVector(1),loadVector(2),rootCapture(0),rootCapture(1),rootCapture(2),complete(0),complete(1),complete(2),settleFailure(0),settleFailure(1),settleFailure(2),resumeClaim(0),resumeClaim(1),resumeClaim(2),unknownOutcome(0),unknownOutcome(1),unknownOutcome(2),reconcileSuccess(0),reconcileSuccess(1),reconcileSuccess(2),requestWrite,requestDerived(0),requestDerived(1),requestDerived(2),park(0),park(1),unpark,rendezvous,commitVector,moveGc,takeWake,retireVm,all{s'=s}}
 action fetch(i)=loadVector(i).then(rootCapture(i))
 action collect=park(0).then(park(1)).then(moveGc).then(unpark)
 run acceptedAfterCloseTest=init.then(accept(0)).then(close).then(publish(0)).then(leave(0)).then(sealClaims).then(coordinatorReserve).then(claim(2)).then(fetch(2)).then(complete(2)).then(retireVm).then(all{assert(safe and not(s.live) and s.done==Set(0)),s'=s})
 run closeRejectsNewTest=init.then(close).then(deny(0)).then(all{assert(safe and s.accepted==Set()),s'=s})
 run coalesceWithoutLeaseLeakTest=init.then(accept(0)).then(accept(1)).then(publish(0)).then(publish(1)).then(leave(0)).then(leave(1)).then(reserve(0)).then(claim(0)).then(fetch(0)).then(complete(0)).then(all{assert(safe and s.done==Set(0,1) and consumers==Set()),s'=s})
 run publishAfterClaimTest=init.then(accept(0)).then(accept(1)).then(publish(0)).then(reserve(0)).then(claim(0)).then(publish(1)).then(all{assert(safe and s.pending==Set(1) and s.batch[0]==Set(0)),s'=s})
 run reservedBeforeSealTest=init.then(reserve(0)).then(close).then(sealClaims).then(emptyReturn(0)).then(retireVm).then(all{assert(safe and not(s.live)),s'=s})
 run loadedRootPreventsParkTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(loadVector(0)).then(all{assert(safe and not(noTemp)),s'=s}).then(rootCapture(0)).then(collect).then(all{assert(safe and s.ptr[0]==11),s'=s})
 run replacementPreservesOldRootTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(fetch(0)).then(requestWrite).then(park(0)).then(park(1)).then(rendezvous).then(commitVector).then(moveGc).then(all{assert(safe and s.vector==2 and s.selected[0]==1 and s.ptr[0]==11),s'=s})
 run queuedWriterGcTest=init.then(requestWrite).then(collect).then(all{assert(safe and s.argPtr==12),s'=s})
 run prefetchFailureRetainsClaimTest=init.then(accept(0)).then(accept(1)).then(publish(0)).then(reserve(0)).then(claim(0)).then(settleFailure(0)).then(publish(1)).then(all{assert(safe and s.c[0]==6 and s.batch[0]==Set(0) and s.pending==Set(1)),s'=s}).then(resumeClaim(0)).then(fetch(0)).then(complete(0)).then(all{assert(safe),s'=s})
 run wakeNotCustodyTest=init.then(accept(0)).then(publish(0)).then(takeWake).then(all{assert(safe and s.pending==Set(0)),s'=s})
 run unknownKeepsRootsTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(fetch(0)).then(unknownOutcome(0)).then(collect).then(all{assert(safe and s.c[0]==5 and s.ptr[0]==11),s'=s}).then(reconcileSuccess(0)).then(all{assert(safe and s.done==Set(0)),s'=s})
 run derivedSetterAfterCloseTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(fetch(0)).then(close).then(requestDerived(0)).then(park(0)).then(park(1)).then(rendezvous).then(commitVector).then(unpark).then(complete(0)).then(all{assert(safe and s.writerParent== -1 and s.done==Set(0)),s'=s})
 run lostAcceptedOnCloseControlTest=init.then(accept(0)).then(close).then(all{s'={...s,p:[3,0]}}).then(all{assert(not(safe)),s'=s})
 run clearBeforeReserveControlTest=init.then(accept(0)).then(publish(0)).then(all{s'={...s,pending:Set()}}).then(all{assert(not(safe)),s'=s})
 run retireBeforeIngressDrainControlTest=init.then(accept(0)).then(close).then(all{s'={...s,live:false}}).then(all{assert(not(safe)),s'=s})
 run sealBeforePublishControlTest=init.then(accept(0)).then(close).then(all{s'={...s,claimOpen:false}}).then(all{assert(not(safe)),s'=s})
 run rawRootMissesGcControlTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(fetch(0)).then(all{s'={...s,loc:10}}).then(all{assert(not(safe)),s'=s})
 run writerArgumentMissesGcControlTest=init.then(requestWrite).then(all{s'={...s,loc:10}}).then(all{assert(not(safe)),s'=s})
 run requeueAcrossClaimControlTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(all{s'={...s,c:[0,0,0],batch:[Set(),Set(),Set()],pending:Set(0)}}).then(all{assert(not(safe)),s'=s})
 run parentFinishesBeforeSetterControlTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(fetch(0)).then(requestDerived(0)).then(all{s'={...s,c:[0,0,0],batch:[Set(),Set(),Set()],done:Set(0)}}).then(all{assert(not(safe)),s'=s})
 run duplicateClaimControlTest=init.then(accept(0)).then(publish(0)).then(reserve(0)).then(claim(0)).then(all{s'={...s,c:[2,2,0],batch:[Set(0),Set(0),Set()]}}).then(all{assert(not(safe)),s'=s})
}
