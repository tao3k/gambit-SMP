// Exact-run registration, sampled aggregate admission and independent drain.
// Samples are not simultaneous OS snapshots or a hard memory bound.
module compile_resource_admission {
  val G=Set(0,1)
  val limit=6
  type State={gate:int,live:Set[int],registered:Set[int],born:int->int,
    actual:int->int,rss:int->int,seen:int,readable:bool,sampled:bool,
    abnormal:bool,signalled:Set[int],receipt:bool}
  val initial:State={gate:0,live:Set(0),registered:Set(0),born:G.mapBy(_=>0),
    actual:G.mapBy(_=>0),rss:G.mapBy(_=>2),seen:0,readable:true,sampled:false,
    abnormal:false,signalled:Set(),receipt:false}
  var s:State
  action init=s'=initial
  def total:int=s.live.fold(0,(n,g)=>n+s.rss.get(g))
  def canSpawn:bool=s.gate==0 and not(s.registered.contains(1))
  def killable(g:int):bool=s.gate==1 and s.live.contains(g) and
    s.registered.contains(g) and s.born.get(g)==s.actual.get(g)
  action spawn=all{canSpawn,s'={...s,live:s.live.union(Set(1)),registered:s.registered.union(Set(1))}}
  action grow(g,n)=s'={...s,rss:s.rss.set(g,n)}
  action unreadable=s'={...s,readable:false}
  action sample=s'={...s,seen:if(s.readable) total else s.seen,sampled:s.readable,
    gate:if(not(s.readable) or total>limit) 1 else s.gate,
    abnormal:s.abnormal or not(s.readable) or total>limit}
  action close=s'={...s,gate:1,abnormal:true}
  action signalGroup(g)=all{killable(g),s'={...s,signalled:s.signalled.union(Set(g))}}
  action drain(g)=all{s.signalled.contains(g),s'={...s,live:s.live.exclude(Set(g))}}
  action naturalExit(g)=s'={...s,live:s.live.exclude(Set(g))}
  action reuse(g)=s'={...s,actual:s.actual.set(g,s.actual.get(g)+1)}
  action seal=all{s.live==Set(),s'={...s,gate:2}}
  action publish=all{s.gate==2,not(s.abnormal),s.sampled,s.readable,
    s'={...s,receipt:true}}
  action badRootOnlyReceipt=s'={...s,live:s.live.exclude(Set(0)),receipt:true}
  def safe:bool=not(s.receipt) or (s.live==Set() and s.gate==2 and
    not(s.abnormal) and s.sampled and s.readable)
  run normalNestedDrainTest=init.then(spawn).then(sample).then(naturalExit(1))
    .then(naturalExit(0)).then(seal).then(publish).expect(safe and s.receipt)
  run aggregateExcessStopsTest=init.then(spawn).then(grow(0,4)).then(grow(1,4))
    .then(sample).then(signalGroup(0)).then(signalGroup(1)).then(drain(0)).then(drain(1))
    .then(seal).expect(safe and s.abnormal and not(s.receipt))
  run independentBudgetsAreInsufficientTest=init.then(spawn).then(grow(0,4)).then(grow(1,4))
    .expect(G.forall(g=>s.rss.get(g)<=limit) and total>limit)
  run samplingIsNotHardCapTest=init.then(sample).then(grow(0,8))
    .expect(safe and s.gate==0 and s.seen<=limit and total>limit)
  run unknownMeasurementRefusesTest=init.then(unreadable).then(sample)
    .expect(safe and s.gate==1 and not(s.sampled) and not(s.receipt))
  run signalIsNotDrainTest=init.then(spawn).then(close).then(signalGroup(0)).then(signalGroup(1))
    .expect(safe and s.live==G and not(s.receipt))
  run reusedBirthRetainsCustodyTest=init.then(spawn).then(close).then(reuse(1))
    .expect(safe and not(killable(1)) and s.live.contains(1) and not(s.receipt))
  run closedAdmissionRefusesChildTest=init.then(close).expect(safe and not(canSpawn))
  run rootOnlyCleanupIsCounterexampleTest=init.then(spawn).then(sample).then(badRootOnlyReceipt)
    .expect(not(safe) and s.live.contains(1))
}

// Two actual roles (runtime and phi support) abstract an arbitrary source bundle.
// SSI/static/optimizer members must be included in the concrete required set.
// One generation token models a full manifest, never timestamp equality alone.
module compile_stage_products {
  val J=Set(0,1)
  val capacity=6
  val parentReserve=1
  type State={generation:int,written:Set[int],sealed:bool,
    requestGeneration:int->int,credits:Set[int],running:Set[int],unknown:Set[int],
    done:Set[int],artifactGeneration:int->int,weight:int->int,known:Set[int],
    drained:Set[int],closed:bool}
  val initial:State={generation:0,written:Set(),sealed:false,
    requestGeneration:J.mapBy(_=>0),credits:Set(),running:Set(),unknown:Set(),
    done:Set(),artifactGeneration:J.mapBy(_=>0),weight:J.mapBy(j=>j+2),known:J,
    drained:Set(),closed:false}
  var p:State
  action init=p'=initial
  def charge:int=parentReserve+p.credits.fold(0,(n,j)=>n+p.weight.get(j))
  def nativeReady:bool=p.sealed and p.written==J
  def canReserve(j:int):bool=nativeReady and not(p.closed) and p.known.contains(j)
    and not(p.credits.contains(j)) and not(p.done.contains(j))
    and charge+p.weight.get(j)<=capacity
  def current(j:int):bool=p.done.contains(j) and p.artifactGeneration.get(j)==p.generation
  def safe:bool=charge<=capacity and p.running.subseteq(p.credits)
    and p.unknown.subseteq(p.credits)
    and p.done.forall(j=>p.drained.contains(j) and not(p.credits.contains(j)))
  action writePart(j)=p'={...p,written:p.written.union(Set(j))}
  action seal=all{p.written==J,p'={...p,sealed:true}}
  action reserve(j)=all{canReserve(j),p'={...p,credits:p.credits.union(Set(j)),
    requestGeneration:p.requestGeneration.set(j,p.generation)}}
  action start(j)=all{p.credits.contains(j),not(p.running.contains(j)),
    p'={...p,running:p.running.union(Set(j))}}
  action loseReply(j)=all{p.running.contains(j),p'={...p,unknown:p.unknown.union(Set(j))}}
  action observeSuccessAndDrain(j)=all{p.running.contains(j),
    p'={...p,running:p.running.exclude(Set(j)),unknown:p.unknown.exclude(Set(j)),
      credits:p.credits.exclude(Set(j)),drained:p.drained.union(Set(j)),
      done:p.done.union(Set(j)),artifactGeneration:p.artifactGeneration.set(j,p.requestGeneration.get(j))}}
  action close=p'={...p,closed:true}
  action nextGeneration=all{p.credits==Set(),p'={...p,generation:p.generation+1,
    written:Set(),sealed:false,done:Set(),drained:Set()}}
  action unknownProfile(j)=p'={...p,known:p.known.exclude(Set(j))}
  action heavyProfiles=p'={...p,weight:J.mapBy(_=>4)}
  action unsafeRefund(j)=p'={...p,credits:p.credits.exclude(Set(j))}
  action unsafeAdmit(j)=p'={...p,done:p.done.union(Set(j))}
  action unsafeIndependentReserve=p'={...p,credits:J}
  run partialBundleNotReadyTest=init.then(writePart(0)).expect(safe and not(nativeReady))
  run sealedBundleCanReserveTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(reserve(0)).then(reserve(1)).expect(safe and charge==capacity)
  run unknownReplyRetainsCreditTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(reserve(0)).then(start(0)).then(loseReply(0))
    .expect(safe and p.credits.contains(0) and not(current(0)))
  run unknownReplyCannotRefundTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(reserve(0)).then(start(0)).then(loseReply(0)).then(unsafeRefund(0)).expect(not(safe))
  run successAndDrainSettlesOnceTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(reserve(0)).then(start(0)).then(loseReply(0)).then(observeSuccessAndDrain(0))
    .expect(safe and current(0) and not(p.credits.contains(0)) and not(canReserve(0)))
  run sameTimestampIsNotGenerationTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(reserve(0)).then(start(0)).then(observeSuccessAndDrain(0)).then(nextGeneration)
    .expect(safe and not(current(0)) and not(nativeReady))
  run unknownProfileCannotLaunchTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(unknownProfile(0)).expect(safe and not(canReserve(0)))
  run heavySiblingWaitsForCreditTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(heavyProfiles).then(reserve(0)).then(start(0)).expect(safe and not(canReserve(1)))
  run independentBudgetsBreakEnvelopeTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(heavyProfiles).then(unsafeIndependentReserve).expect(not(safe))
  run closedGroupStillSettlesTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(reserve(0)).then(start(0)).then(close).then(observeSuccessAndDrain(0))
    .expect(safe and current(0) and not(canReserve(1)))
  run parentExitIsNotProductTest=init.then(writePart(0)).then(writePart(1)).then(seal)
    .then(reserve(0)).then(start(0)).then(unsafeAdmit(0)).expect(not(safe))
}

// SysML: GambitDarwinAcceleration::gcAllocationProgress. This module owns only
// the waiting -> acquire -> protected-read -> claim ordering. Lean owns section
// arithmetic; actual LDAR emission and runtime queue refinement remain separate.
