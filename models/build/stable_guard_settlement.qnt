module stable_guard_settlement {
 pure val A=Set(0,1)
 // 0 unused,1 reserved+caller rooted,2 scan registered,3 published,
 // 4 marker acquired/callback live,5 landed,6 cleanup claimed,
 // 7 marker invalidated,8 drop/no-marker complete,9 done,10 retired.
 type State={p:List[int],session:List[bool],root:List[bool],registered:List[bool],
 published:List[bool],acquired:List[bool],invalid:List[bool],ref:List[int],drops:List[int],
 executor:List[int],pin:List[bool],done:List[bool],known:List[bool],read:List[bool],
 closing:List[bool],debt:List[bool],version:List[int],payload:List[int],
 capture:List[bool],invocation:List[bool],vm:bool,closed:bool}
 pure val initial:State={p:[0,0],session:[false,false],root:[false,false],registered:[false,false],
 published:[false,false],acquired:[false,false],invalid:[false,false],ref:[0,0],drops:[0,0],
 executor:[-1,-1],pin:[false,false],done:[false,false],known:[true,true],read:[false,false],
 closing:[false,false],debt:[false,false],version:[0,0],payload:[0,0],
 capture:[false,false],invocation:[false,false],vm:true,closed:false}
 var s:State
 action init=s'=initial
 def live(i)=s.p[i]>0 and s.p[i]<10
 def childClear(i)=i==1 or s.p[1]==0 or s.p[1]>=9
 val safe=all{A.forall(i=>live(i) implies (s.session[i] and s.root[i] and s.vm)),
 A.forall(i=>s.published[i] and live(i) implies s.registered[i]),
 A.forall(i=>s.drops[i]>=0 and s.drops[i]<=1 and s.ref[i]>=0),
 A.forall(i=>s.acquired[i] implies s.ref[i]+s.drops[i]==1),
 A.forall(i=>not(s.acquired[i]) implies s.drops[i]==0),
 A.forall(i=>s.acquired[i] and not(s.invalid[i]) implies s.payload[i]==s.version[i]),
 A.forall(i=>s.pin[i] implies (s.executor[i]>=0 and s.session[i] and s.root[i])),
 A.forall(i=>s.done[i] implies (not(s.debt[i]) and not(s.pin[i]) and (not(s.acquired[i]) or (s.invalid[i] and s.drops[i]==1)))),
 A.forall(i=>s.p[i]>=6 implies childClear(i)),
 A.forall(i=>s.p[i]==10 implies (s.done[i] and s.closing[i] and not(s.read[i]) and not(s.root[i]) and not(s.session[i]))),
 A.forall(i=>s.read[i] implies s.registered[i] and s.root[i] and s.session[i]),
 A.forall(i=>(s.capture[i] or s.invocation[i]) implies s.vm),
 not(s.vm) implies not(A.exists(i=>s.session[i] or s.capture[i] or s.invocation[i]))}
 // reserve abstracts an existing caller-root fence and a no-GC reserved slab slot.
 action reserve(i)=all{s.p[i]==0,s.vm,not(s.closed),i==0 or s.p[0]==4,
 s'={...s,p:s.p.replaceAt(i,1),session:s.session.replaceAt(i,true),root:s.root.replaceAt(i,true)}}
 action reserveFailure=all{s.p[0]==0,s'=s}
 action registerRoots(i)=all{s.p[i]==1,s.root[i],s'={...s,p:s.p.replaceAt(i,2),registered:s.registered.replaceAt(i,true)}}
 action publishGuard(i)=all{s.p[i]==2,s.registered[i],s'={...s,p:s.p.replaceAt(i,3),published:s.published.replaceAt(i,true)}}
 // The scanner/owner protocol serializes relocation against native marker writes.
 action relocate(i)=all{live(i),s.registered[i],not(s.pin[i]),s'={...s,version:s.version.replaceAt(i,1-s.version[i]),payload:if(s.acquired[i] and not(s.invalid[i])) s.payload.replaceAt(i,1-s.version[i]) else s.payload}}
 action allocateSuccess(i)=all{s.p[i]==3,s.published[i],s.root[i],s.registered[i],s'={...s,p:s.p.replaceAt(i,4),acquired:s.acquired.replaceAt(i,true),ref:s.ref.replaceAt(i,1),payload:s.payload.replaceAt(i,s.version[i]),debt:s.debt.replaceAt(i,true)}}
 action allocateFailure(i)=all{s.p[i]==3,s'={...s,p:s.p.replaceAt(i,5)}}
 action land(i)=all{s.p[i]==4,childClear(i),s'={...s,p:s.p.replaceAt(i,5)}}
 // a=0 normal tail; a=1 admitted exceptional outer custodian on same owner thread.
 action claimCleanup(i,a)=all{s.p[i]==5,s.published[i],childClear(i),s.executor[i]==-1,s'={...s,p:s.p.replaceAt(i,6),executor:s.executor.replaceAt(i,a),pin:s.pin.replaceAt(i,true)}}
 action invalidate(i)=all{s.p[i]==6,s.acquired[i],s.pin[i],s'={...s,p:s.p.replaceAt(i,7),invalid:s.invalid.replaceAt(i,true)}}
 // Only the same live executor can perform this non-idempotent step.
 action dropStill(i)=all{s.p[i]==7,s.pin[i],s.ref[i]==1,s.drops[i]==0,s'={...s,p:s.p.replaceAt(i,8),ref:s.ref.replaceAt(i,0),drops:s.drops.replaceAt(i,1)}}
 action noMarker(i)=all{s.p[i]==6,not(s.acquired[i]),s'={...s,p:s.p.replaceAt(i,8)}}
 action restoreCaller(i)=all{s.p[i]==8,s'={...s,debt:s.debt.replaceAt(i,false)}}
 action publishDone(i)=all{s.p[i]==8,not(s.debt[i]),childClear(i),s.pin[i],s'={...s,p:s.p.replaceAt(i,9),done:s.done.replaceAt(i,true),pin:s.pin.replaceAt(i,false)}}
 action loseReply(i)=all{s.p[i]>=6,s.p[i]<=9,s'={...s,known:s.known.replaceAt(i,false)}}
 action query(i)=all{s.p[i]==9,s.done[i],s'={...s,known:s.known.replaceAt(i,true)}}
 action borrow(i)=all{s.p[i]>=3,s.p[i]<=9,not(s.closing[i]),not(s.read[i]),s'={...s,read:s.read.replaceAt(i,true)}}
 action endBorrow(i)=all{s.read[i],s'={...s,read:s.read.replaceAt(i,false)}}
 action closeAdmission(i)=all{s.p[i]==9,s'={...s,closing:s.closing.replaceAt(i,true)}}
 action retireGuard(i)=all{s.p[i]==9,s.done[i],s.known[i],s.closing[i],not(s.read[i]),s'={...s,p:s.p.replaceAt(i,10),root:s.root.replaceAt(i,false),registered:s.registered.replaceAt(i,false),session:s.session.replaceAt(i,false)}}
 action captureK(i)=all{s.p[i]==4,s'={...s,capture:s.capture.replaceAt(i,true)}}
 action invokeK(i)=all{s.p[i]>=9,s.capture[i],not(s.invocation[i]),s.vm,s'={...s,invocation:s.invocation.replaceAt(i,true)}}
 // New invocation authority; old physical marker/counter/guard remain unchanged.
 action endInvocation(i)=all{s.invocation[i],s'={...s,invocation:s.invocation.replaceAt(i,false)}}
 action dropK(i)=all{s.capture[i],s'={...s,capture:s.capture.replaceAt(i,false)}}
 action close=all{s'={...s,closed:true}}
 action retireVm=all{s.closed,not(A.exists(i=>s.session[i] or s.capture[i] or s.invocation[i])),s'={...s,vm:false}}
 action step=any{reserve(0),reserve(1),registerRoots(0),registerRoots(1),publishGuard(0),publishGuard(1),relocate(0),relocate(1),allocateSuccess(0),allocateSuccess(1),allocateFailure(0),allocateFailure(1),land(0),land(1),claimCleanup(0,0),claimCleanup(0,1),claimCleanup(1,0),claimCleanup(1,1),invalidate(0),invalidate(1),dropStill(0),dropStill(1),noMarker(0),noMarker(1),restoreCaller(0),restoreCaller(1),publishDone(0),publishDone(1),loseReply(0),loseReply(1),query(0),query(1),borrow(0),borrow(1),endBorrow(0),endBorrow(1),closeAdmission(0),closeAdmission(1),retireGuard(0),retireGuard(1),captureK(0),captureK(1),invokeK(0),invokeK(1),endInvocation(0),endInvocation(1),dropK(0),dropK(1),close,retireVm,all{s'=s}}
 action prepared(i)=reserve(i).then(registerRoots(i)).then(publishGuard(i))
 action cleanup(i,a)=claimCleanup(i,a).then(invalidate(i)).then(dropStill(i)).then(restoreCaller(i)).then(publishDone(i))
 action retire(i)=closeAdmission(i).then(retireGuard(i))
 run successTest=init.then(prepared(0)).then(allocateSuccess(0)).then(land(0)).then(cleanup(0,0)).then(retire(0)).then(close).then(retireVm).then(all{assert(safe and s.drops[0]==1),s'=s})
 run allocationFailureTest=init.then(prepared(0)).then(allocateFailure(0)).then(claimCleanup(0,1)).then(noMarker(0)).then(publishDone(0)).then(retire(0)).then(all{assert(safe and s.drops[0]==0),s'=s})
 run reservationFailureTest=init.then(reserveFailure).then(all{assert(safe and not(s.acquired[0]) and not(s.session[0])),s'=s})
 run nestedTest=init.then(prepared(0)).then(allocateSuccess(0)).then(prepared(1)).then(allocateSuccess(1)).then(land(1)).then(cleanup(1,1)).then(retire(1)).then(all{assert(safe and s.session[0] and s.ref[0]==1),s'=s}).then(land(0)).then(cleanup(0,0)).then(all{assert(safe),s'=s})
 run unknownAfterDropTest=init.then(prepared(0)).then(allocateSuccess(0)).then(land(0)).then(claimCleanup(0,1)).then(invalidate(0)).then(dropStill(0)).then(loseReply(0)).then(restoreCaller(0)).then(publishDone(0)).then(query(0)).then(retire(0)).then(all{assert(safe and s.drops[0]==1),s'=s})
 run unknownBeforeDropTest=init.then(prepared(0)).then(allocateSuccess(0)).then(land(0)).then(claimCleanup(0,1)).then(loseReply(0)).then(invalidate(0)).then(dropStill(0)).then(all{assert(safe and s.pin[0] and s.session[0]),s'=s})
 run relocationTest=init.then(prepared(0)).then(relocate(0)).then(allocateSuccess(0)).then(all{assert(safe and s.payload[0]==1),s'=s})
 run readerDrainTest=init.then(prepared(0)).then(allocateSuccess(0)).then(borrow(0)).then(land(0)).then(cleanup(0,0)).then(closeAdmission(0)).then(all{assert(safe and s.root[0]),s'=s}).then(endBorrow(0)).then(retireGuard(0)).then(all{assert(safe),s'=s})
 run multishotTest=init.then(prepared(0)).then(allocateSuccess(0)).then(captureK(0)).then(land(0)).then(cleanup(0,1)).then(retire(0)).then(invokeK(0)).then(endInvocation(0)).then(invokeK(0)).then(all{assert(safe and s.drops[0]==1 and s.p[0]==10),s'=s})
 run missingRootControlTest=init.then(prepared(0)).then(all{s'={...s,root:[false,false]}}).then(all{assert(not(safe)),s'=s})
 run duplicateDropControlTest=init.then(prepared(0)).then(allocateSuccess(0)).then(land(0)).then(cleanup(0,0)).then(all{s'={...s,drops:[2,0],ref:[-1,0]}}).then(all{assert(not(safe)),s'=s})
 run uninitializedKillControlTest=init.then(prepared(0)).then(allocateFailure(0)).then(all{s'={...s,drops:[1,0]}}).then(all{assert(not(safe)),s'=s})
 run prematureDoneControlTest=init.then(prepared(0)).then(allocateSuccess(0)).then(all{s'={...s,done:[true,false]}}).then(all{assert(not(safe)),s'=s})
 run executorLostOwnerControlTest=init.then(prepared(0)).then(allocateSuccess(0)).then(land(0)).then(claimCleanup(0,1)).then(all{s'={...s,session:[false,false]}}).then(all{assert(not(safe)),s'=s})
 run parentBeforeChildControlTest=init.then(prepared(0)).then(allocateSuccess(0)).then(prepared(1)).then(allocateSuccess(1)).then(all{s'={...s,p:[6,4],pin:[true,false],executor:[1,-1]}}).then(all{assert(not(safe)),s'=s})
 run liveReaderFreedControlTest=init.then(prepared(0)).then(allocateSuccess(0)).then(borrow(0)).then(land(0)).then(cleanup(0,0)).then(all{s'={...s,root:[false,false]}}).then(all{assert(not(safe)),s'=s})
 run stalePayloadControlTest=init.then(prepared(0)).then(relocate(0)).then(allocateSuccess(0)).then(all{s'={...s,payload:[0,0]}}).then(all{assert(not(safe)),s'=s})
}
