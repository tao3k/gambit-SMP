module release_producer_admission {
  // Two release rights sharing a function and pointer, not a pointer-identity dedup model.
  // 0 absent;1 reserved;2 native-created;3 wrapped;4 accepted;5 running;
  // 6 terminal-retained;7 retired;8 native outcome unknown.
  type State={phase:int->int,rooted:Set[int],traced:Set[int],calls:int->int,
    readers:Set[int],known:Set[int],profile:bool,delay:bool,origin:int,
    cut:bool,seal:bool,held:int,bytes:int,cap:int,byteCap:int}
  var s:State
  val ids=Set(0,1)
  val live=ids.filter(i=>s.phase.get(i)!=0 and s.phase.get(i)!=7)
  val instantiated=ids.filter(i=>s.phase.get(i)>=2 and s.phase.get(i)!=7)
  def canReserve(i)=not(s.cut) and s.profile and s.phase.get(i)==0 and
    s.held+1<=s.cap and s.bytes+4<=s.byteCap
  val canSeal=s.cut and ids.forall(i=>s.phase.get(i)!=1) and instantiated.subseteq(s.traced)
  val safe=s.held==live.size() and s.bytes==4*live.size() and
    s.held<=s.cap and s.bytes<=s.byteCap and
    instantiated.subseteq(s.rooted) and ids.forall(i=>s.calls.get(i)<=1) and
    ids.forall(i=>s.phase.get(i)!=7 or (s.known.contains(i) and not(s.readers.contains(i)))) and
    (not(s.seal) or canSeal) and
    ids.forall(i=>s.phase.get(i)<4 or s.phase.get(i)==7 or (s.profile and s.delay and s.origin==0))
  action init=s'={phase:Map(0->0,1->0),rooted:Set(),traced:Set(),calls:Map(0->0,1->0),
    readers:Set(),known:Set(),profile:false,delay:false,origin:0,cut:false,seal:false,
    held:0,bytes:0,cap:2,byteCap:8}
  action qualify=s'={...s,profile:true,delay:true}
  action explicitOrigin=all{s.held==0,s'={...s,origin:1}}
  action rollbackOrigin=all{s.held==0,s'={...s,origin:2}}
  action oneSlot=all{s.held==0,s'={...s,cap:1}}
  action lowBytes=all{s.held==0,s'={...s,byteCap:3}}
  action reserve(i)=all{canReserve(i),s'={...s,phase:s.phase.set(i,1),held:s.held+1,bytes:s.bytes+4}}
  action abortReservation(i)=all{s.phase.get(i)==1,s'={...s,phase:s.phase.set(i,7),known:s.known.union(Set(i)),held:s.held-1,bytes:s.bytes-4}}
  action registerRoots(i)=all{s.phase.get(i)==1,s'={...s,rooted:s.rooted.union(Set(i))}}
  action invokeProducer(i)=all{s.phase.get(i)==1,s.rooted.contains(i),s'={...s,phase:s.phase.set(i,2)}}
  action wrap(i)=all{s.phase.get(i)==2,s'={...s,phase:s.phase.set(i,3)}}
  action closeAdmission=s'={...s,cut:true}
  action trace(i)=all{instantiated.contains(i),s'={...s,traced:s.traced.union(Set(i))}}
  action accept(i)=all{s.phase.get(i)==3,s.cut,s.traced.contains(i),s.profile,s.delay,s.origin==0,s'={...s,phase:s.phase.set(i,4)}}
  action start(i)=all{s.phase.get(i)==4,s'={...s,phase:s.phase.set(i,5),calls:s.calls.set(i,s.calls.get(i)+1)}}
  action finish(i)=all{s.phase.get(i)==5,s'={...s,phase:s.phase.set(i,6),known:s.known.union(Set(i))}}
  action loseResult(i)=all{s.phase.get(i)==5,s'={...s,phase:s.phase.set(i,8)}}
  action pin(i)=all{s.phase.get(i)==6,not(s.readers.contains(i)),s'={...s,readers:s.readers.union(Set(i))}}
  action drain(i)=all{s.readers.contains(i),s'={...s,readers:s.readers.exclude(Set(i))}}
  action retire(i)=all{s.phase.get(i)==6,s.known.contains(i),not(s.readers.contains(i)),s'={...s,phase:s.phase.set(i,7),held:s.held-1,bytes:s.bytes-4}}
  // Synchronous rollback preserves its invocation boundary; no deferred task is made.
  action rollback(i)=all{s.phase.get(i)==2,s.calls.get(i)==0,s'={...s,phase:s.phase.set(i,7),known:s.known.union(Set(i)),calls:s.calls.set(i,1),held:s.held-1,bytes:s.bytes-4}}
  action publishSeal=all{canSeal,s'={...s,seal:true}}
  action query=s'=s
  action step={ nondet i=ids.oneOf(); any{qualify,closeAdmission,publishSeal,query,
    reserve(i),abortReservation(i),registerRoots(i),invokeProducer(i),wrap(i),trace(i),accept(i),start(i),finish(i),loseResult(i),pin(i),drain(i),retire(i),rollback(i)}}
  action born(i)=reserve(i).then(registerRoots(i)).then(invokeProducer(i)).then(wrap(i))
  action accepted=qualify.then(born(0)).then(closeAdmission).then(trace(0)).then(accept(0))
  action unsafeNative=s'={...s,phase:s.phase.set(0,2)}
  action unsafeDedup=s'={...s,held:s.held-1,bytes:s.bytes-4}
  action unsafeSeal=s'={...s,seal:true}
  action unsafeRefund=s'={...s,held:s.held-1,bytes:s.bytes-4}
  action unsafeReplay=s'={...s,calls:s.calls.set(0,s.calls.get(0)+1)}
  action unsafeRetire=s'={...s,phase:s.phase.set(0,7),held:s.held-1,bytes:s.bytes-4}
  action unsafeOrigin=s'={...s,phase:s.phase.set(0,4)}
  run reserveBeforeNativeTest=init.then(qualify).then(reserve(0)).expect(safe and s.held==1)
  run rootBeforeNativeTest=init.then(qualify).then(reserve(0)).then(registerRoots(0)).then(invokeProducer(0)).expect(safe)
  run sameFunctionTwoRightsTest=init.then(qualify).then(born(0)).then(born(1)).expect(safe and s.held==2 and s.bytes==8)
  run slotExhaustionTest=init.then(qualify).then(oneSlot).then(born(0)).expect(safe and not(canReserve(1)))
  run byteExhaustionTest=init.then(qualify).then(lowBytes).expect(safe and not(canReserve(0)))
  run frozenAdmissionTest=init.then(qualify).then(closeAdmission).expect(safe and not(canReserve(0)))
  run inflightStillChargedTest=init.then(qualify).then(reserve(0)).then(closeAdmission).expect(safe and s.held==1)
  run inflightCanUseExistingCreditTest=init.then(qualify).then(reserve(0)).then(closeAdmission).then(registerRoots(0)).then(invokeProducer(0)).expect(safe and not(canSeal))
  run traceBeforeSealTest=init.then(qualify).then(born(0)).then(closeAdmission).then(trace(0)).then(publishSeal).expect(safe and s.seal)
  run missingTraceRejectsSealTest=init.then(qualify).then(born(0)).then(closeAdmission).expect(safe and not(canSeal))
  run acceptNoSecondChargeTest=init.then(accepted).expect(safe and s.held==1)
  run unknownResultKeepsTicketTest=init.then(accepted).then(start(0)).then(loseResult(0)).then(query).expect(safe and s.held==1 and s.calls.get(0)==1)
  run terminalAckKeepsTicketTest=init.then(accepted).then(start(0)).then(finish(0)).then(pin(0)).expect(safe and s.held==1)
  run readerDrainBeforeRefundTest=init.then(accepted).then(start(0)).then(finish(0)).then(pin(0)).then(drain(0)).then(retire(0)).expect(safe and s.held==0)
  run synchronousRollbackTest=init.then(qualify).then(reserve(0)).then(registerRoots(0)).then(invokeProducer(0)).then(rollback(0)).expect(safe and s.held==0 and s.calls.get(0)==1)
  run explicitNotDeferredTest=init.then(qualify).then(explicitOrigin).then(born(0)).then(closeAdmission).then(trace(0)).expect(safe and s.origin==1)
  run rollbackNotDeferredTest=init.then(qualify).then(rollbackOrigin).then(reserve(0)).then(registerRoots(0)).then(invokeProducer(0)).then(rollback(0)).expect(safe)
  run unusedReservationAbortBeforeSealTest=init.then(qualify).then(reserve(0)).then(closeAdmission).then(abortReservation(0)).then(publishSeal).expect(safe and s.held==0)
  run inflightSealCounterexampleTest=init.then(qualify).then(reserve(0)).then(closeAdmission).then(unsafeSeal).expect(not(safe))
  run allocationBeforeReserveCounterexampleTest=init.then(unsafeNative).expect(not(safe))
  run functionDedupCounterexampleTest=init.then(qualify).then(born(0)).then(born(1)).then(unsafeDedup).expect(not(safe))
  run sealBeforeTraceCounterexampleTest=init.then(qualify).then(born(0)).then(closeAdmission).then(unsafeSeal).expect(not(safe))
  run unknownRefundCounterexampleTest=init.then(accepted).then(start(0)).then(loseResult(0)).then(unsafeRefund).expect(not(safe))
  run unknownReplayCounterexampleTest=init.then(accepted).then(start(0)).then(loseResult(0)).then(unsafeReplay).expect(not(safe))
  run readerRetireCounterexampleTest=init.then(accepted).then(start(0)).then(finish(0)).then(pin(0)).then(unsafeRetire).expect(not(safe))
  run explicitDeferredCounterexampleTest=init.then(qualify).then(explicitOrigin).then(born(0)).then(unsafeOrigin).expect(not(safe))
}
