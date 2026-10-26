module ffi_scan_ready_handoff {
 import ffi_handoff_parameters.* from "./ffi_handoff_parameters"
 pure val Ops=0.to(OperationCount-1)
 // Two distinct operation identities on processor 1. Slot versions abstract relocation, not Scheme identity.
 type State={mode:int,epoch:int,heap:int,admission:bool,registry:bool,
  reserved:Set[int],reserveFailed:Set[int],accepted:Set[int],preparing:Set[int],roots:Set[int],sources:Set[int],parked:Set[int],
  nativePins:Set[int],readers:Set[int],retired:Set[int],markers:Set[int],known:Set[int],unknown:Set[int],
  requests:Set[int],scanned:Set[int],slot:int->int,local:int->int,outcome:int->int,commits:int->int,
  rcRegistered:bool,rcVersion:int,rcScan:int,rcAlive:bool,implicit:bool,completed:bool}
 pure val initial:State={mode:0,epoch:0,heap:0,admission:true,registry:true,
  reserved:Set(),reserveFailed:Set(),accepted:Set(),preparing:Set(),roots:Set(),sources:Ops,parked:Set(),
  nativePins:Set(),readers:Set(),retired:Set(),markers:Set(),known:Set(),unknown:Set(),requests:Set(),scanned:Set(),
  slot:Ops.mapBy(i=>0),local:Ops.mapBy(i=>0),outcome:Ops.mapBy(i=>0),commits:Ops.mapBy(i=>0),
  rcRegistered:false,rcVersion:0,rcScan:-1,rcAlive:true,implicit:false,completed:false}
 var s:State
 action init=s'=initial
 action initImplicit=s'={...initial,implicit:true,rcRegistered:true}
 action initLegacy=s'={...initial,registry:false}
 action reserve(i)=all{s.mode==0,s.admission,not(s.accepted.contains(i)),not(s.retired.contains(i)),
  s'={...s,reserved:s.reserved.union(Set(i))}}
 action reserveFailure(i)=all{s.mode==0,not(s.accepted.contains(i)),s.sources.contains(i),s'={...s,reserveFailed:s.reserveFailed.union(Set(i))}}
 action beginIntent(i)=all{s.mode==0,s.admission,s.reserved.contains(i),not(s.accepted.contains(i)),s.sources.contains(i),i!=1 or not(s.retired.contains(0)),
  not(s.implicit) or (s.rcAlive and s.rcRegistered),
  s'={...s,accepted:s.accepted.union(Set(i)),preparing:s.preparing.union(Set(i)),nativePins:if(s.implicit) s.nativePins.union(Set(i)) else s.nativePins}}
 // Accepted before cutoff; publication remains allowed while admission is closing. No allocating preparation.
 action abortPreparation(i)=all{s.mode<=1,s.preparing.contains(i),s.sources.contains(i),not(s.readers.contains(i)),
  i!=0 or not(s.accepted.contains(1)) or s.retired.contains(1),
  s'={...s,preparing:s.preparing.exclude(Set(i)),roots:s.roots.exclude(Set(i)),nativePins:s.nativePins.exclude(Set(i)),
   retired:s.retired.union(Set(i)),known:s.known.union(Set(i)),outcome:s.outcome.set(i,3)}}
 action publishRoot(i)=all{s.mode<=1,s.preparing.contains(i),s.sources.contains(i),s.rcAlive,
  s'={...s,roots:s.roots.union(Set(i)),slot:s.slot.set(i,s.heap)}}
 action handoff(i)=all{s.mode<=1,s.preparing.contains(i),s.roots.contains(i),s.slot.get(i)==s.heap,
  s'={...s,preparing:s.preparing.exclude(Set(i)),parked:s.parked.union(Set(i))}}
 action releaseSource(i)=all{s.roots.contains(i),s'={...s,sources:s.sources.exclude(Set(i))}}
 action requestGC(i)=all{s.parked.contains(i),s.roots.contains(i),not(s.preparing.contains(i)),s'={...s,requests:s.requests.union(Set(i))}}
 action closeAdmission=all{s.mode==0,s.admission,s.requests!=Set(),s'={...s,admission:false,mode:1}}
 def liveOps=s.accepted.filter(i=>s.outcome.get(i)==0)
 action freeze=all{s.mode==1,s.preparing==Set(),liveOps.subseteq(s.parked),s.accepted.exclude(s.retired).subseteq(s.roots),
  s'={...s,mode:2,epoch:s.epoch+1,scanned:Set()}}
 // Collector may scan processor-1 frame adapters and registered RC slots; root values update in place.
 action scanRoot(i)=all{s.mode==2,s.roots.contains(i),s.registry,
  s'={...s,slot:s.slot.set(i,s.epoch),scanned:s.scanned.union(Set(i))}}
 action scanRcDomain=all{s.mode==2,s.rcRegistered,s.rcAlive,s.registry,s'={...s,rcVersion:s.epoch,rcScan:s.epoch}}
 action finishGC=all{s.mode==2,s.registry,s.roots.subseteq(s.scanned),not(s.rcRegistered) or s.rcScan==s.epoch,
  s'={...s,mode:0,heap:s.epoch,admission:true,requests:Set(),completed:true}}
 action resume(i)=all{s.mode==0,s.parked.contains(i),s.roots.contains(i),s.slot.get(i)==s.heap,s.outcome.get(i)==0,
  s'={...s,parked:s.parked.exclude(Set(i)),local:s.local.set(i,s.slot.get(i))}}
 action parkAgain(i)=all{s.mode<=1,s.accepted.contains(i),s.roots.contains(i),not(s.preparing.contains(i)),s.outcome.get(i)==0,
  s'={...s,parked:s.parked.union(Set(i))}}
 def running(i)=s.mode==0 and s.accepted.contains(i) and not(s.preparing.contains(i)) and not(s.parked.contains(i)) and s.outcome.get(i)==0 and s.roots.contains(i) and s.local.get(i)==s.heap
 action allocateMarker(i)=all{running(i),not(s.markers.contains(i)),s'={...s,markers:s.markers.union(Set(i))}}
 action completeMarker(i)=all{running(i),s.markers.contains(i),s'={...s,outcome:s.outcome.set(i,2)}}
 action commitRc(i)=all{running(i),not(s.markers.contains(i)),s.rcAlive,s.commits.get(i)==0,
  s'={...s,rcRegistered:true,rcVersion:s.heap,commits:s.commits.set(i,1),outcome:s.outcome.set(i,1)}}
 // Failure/unwind retains frame custody; close-marker is modeled as an abstract nonallocating guard step.
 action failOp(i)=all{running(i),s'={...s,outcome:s.outcome.set(i,3),markers:s.markers.exclude(Set(i))}}
 action unwindOp(i)=all{running(i),s'={...s,outcome:s.outcome.set(i,4),markers:s.markers.exclude(Set(i))}}
 action markUnknown(i)=all{s.accepted.contains(i),not(s.preparing.contains(i)),not(s.retired.contains(i)),
  s'={...s,unknown:s.unknown.union(Set(i)),known:s.known.exclude(Set(i))}}
 action settleOutcome(i)=all{s.accepted.contains(i),s.outcome.get(i)!=0,not(s.retired.contains(i)),
  s'={...s,known:s.known.union(Set(i)),unknown:s.unknown.exclude(Set(i))}}
 action retryDelivery(i)=all{s.known.contains(i),s'=s}
 action beginReader(i)=all{s.mode==0,s.roots.contains(i),not(s.retired.contains(i)),s'={...s,readers:s.readers.union(Set(i))}}
 action endReader(i)=all{s.readers.contains(i),s'={...s,readers:s.readers.exclude(Set(i))}}
 action releasePin(i)=all{s.mode==0,s.nativePins.contains(i),s.outcome.get(i)!=0,s.known.contains(i),s'={...s,nativePins:s.nativePins.exclude(Set(i))}}
 def childClosed(i)=i!=0 or not(s.accepted.contains(1)) or s.retired.contains(1)
 action retireFrame(i)=all{s.mode==0,s.known.contains(i),not(s.unknown.contains(i)),s.outcome.get(i)!=0,
  not(s.readers.contains(i)),not(s.nativePins.contains(i)),childClosed(i),not(s.retired.contains(i)),
  s'={...s,roots:s.roots.exclude(Set(i)),retired:s.retired.union(Set(i))}}
 def safe=s.preparing.subseteq(s.accepted) and s.roots.subseteq(s.reserved) and s.parked.subseteq(s.roots) and
  s.nativePins.subseteq(s.accepted.exclude(s.retired)) and s.readers.subseteq(s.roots) and
  s.unknown.subseteq(s.accepted.exclude(s.retired)) and s.known.intersect(s.unknown)==Set() and
  s.accepted.exclude(s.retired).forall(i=>s.sources.contains(i) or s.roots.contains(i)) and
  s.retired.intersect(s.roots)==Set() and s.retired.forall(i=>s.known.contains(i) and s.outcome.get(i)!=0 and childClosed(i)) and
  (s.nativePins!=Set() implies s.rcAlive) and (s.rcRegistered implies s.rcAlive) and
  (s.mode==0 implies s.roots.forall(i=>s.slot.get(i)==s.heap) and (s.rcRegistered implies s.rcVersion==s.heap)) and
  (s.mode==2 implies s.preparing==Set() and liveOps.subseteq(s.parked)) and
  (s.completed implies s.registry) and Ops.forall(i=>s.commits.get(i)<=1) and
  Ops.forall(i=>(s.markers.contains(i) and s.mode==0 and not(s.parked.contains(i)) and s.outcome.get(i)==0) implies s.local.get(i)==s.heap)
 action step={nondet i=Ops.oneOf();any{reserve(i),reserveFailure(i),beginIntent(i),abortPreparation(i),publishRoot(i),handoff(i),releaseSource(i),requestGC(i),closeAdmission,freeze,
  scanRoot(i),scanRcDomain,finishGC,resume(i),parkAgain(i),allocateMarker(i),completeMarker(i),commitRc(i),failOp(i),unwindOp(i),markUnknown(i),settleOutcome(i),retryDelivery(i),beginReader(i),endReader(i),releasePin(i),retireFrame(i),s'=s}}
 action prepare(i)=reserve(i).then(beginIntent(i)).then(publishRoot(i)).then(handoff(i)).then(releaseSource(i))
 action collectOne(i)=requestGC(i).then(closeAdmission).then(freeze).then(scanRoot(i)).then(finishGC)
 action normal(i)=prepare(i).then(collectOne(i)).then(resume(i))
 action forceFreeze=s'={...s,mode:2,epoch:s.epoch+1}
 action forceDrop(i)=s'={...s,roots:s.roots.exclude(Set(i)),sources:s.sources.exclude(Set(i))}
 action forceRetire(i)=s'={...s,roots:s.roots.exclude(Set(i)),retired:s.retired.union(Set(i))}
 action forceDuplicate(i)=s'={...s,commits:s.commits.set(i,s.commits.get(i)+1)}
 action forceFreeRc=s'={...s,rcAlive:false}
 action forceFinish=s'={...s,mode:0,heap:s.epoch,admission:true,completed:true}
 action forceStaleMarker(i)=s'={...s,parked:s.parked.exclude(Set(i)),markers:s.markers.union(Set(i))}
 run reserveFailureTest=init.then(reserveFailure(0)).expect(safe and s.sources.contains(0) and s.accepted==Set())
 run preparationAbortTest=init.then(reserve(0)).then(beginIntent(0)).then(abortPreparation(0)).expect(safe and s.sources.contains(0) and s.preparing==Set() and s.retired.contains(0))
 run handoffBeforeCompletionTest=init.then(prepare(0)).then(requestGC(0)).then(closeAdmission).then(freeze).expect(safe and s.mode==2 and s.outcome.get(0)==0)
 run handoffAckLostTest=init.then(prepare(0)).then(markUnknown(0)).then(collectOne(0)).expect(safe and s.unknown.contains(0) and s.roots.contains(0) and s.outcome.get(0)==0)
 run acceptedAfterCutoffTest=init.then(prepare(0)).then(reserve(1)).then(beginIntent(1)).then(requestGC(0)).then(closeAdmission).then(publishRoot(1)).then(handoff(1)).then(freeze).expect(safe and s.mode==2)
 run explicitMarkerTest=init.then(normal(0)).then(allocateMarker(0)).then(completeMarker(0)).then(settleOutcome(0)).then(retireFrame(0)).expect(safe and s.markers.contains(0))
 run nonzeroRcCommitTest=init.then(normal(0)).then(commitRc(0)).then(settleOutcome(0)).then(retireFrame(0)).expect(safe and s.rcRegistered and s.commits.get(0)==1)
 run implicitRcTest=initImplicit.then(prepare(0)).then(requestGC(0)).then(closeAdmission).then(freeze).then(scanRoot(0)).then(scanRcDomain).then(finishGC).then(resume(0)).then(allocateMarker(0)).then(completeMarker(0)).then(settleOutcome(0)).then(releasePin(0)).then(retireFrame(0)).expect(safe and s.rcScan==1)
 run allocationFailureTest=init.then(normal(0)).then(failOp(0)).expect(safe and s.roots.contains(0) and s.outcome.get(0)==3)
 run unwindCustodyTest=init.then(normal(0)).then(allocateMarker(0)).then(unwindOp(0)).expect(safe and s.roots.contains(0) and not(s.markers.contains(0)))
 run lostCommitAckTest=init.then(normal(0)).then(commitRc(0)).then(markUnknown(0)).expect(safe and s.roots.contains(0) and not(s.known.contains(0)))
 run queryNoReplayTest=init.then(normal(0)).then(commitRc(0)).then(markUnknown(0)).then(settleOutcome(0)).then(retryDelivery(0)).expect(safe and s.commits.get(0)==1)
 run unknownNotQuiescenceTest=init.then(normal(0)).then(markUnknown(0)).expect(safe and not(s.parked.contains(0)) and s.outcome.get(0)==0)
 run nestedCollectionTest=init.then(prepare(0)).then(prepare(1)).then(requestGC(1)).then(closeAdmission).then(freeze).then(scanRoot(0)).then(scanRoot(1)).then(finishGC).then(resume(1)).then(failOp(1)).then(settleOutcome(1)).then(retireFrame(1)).then(resume(0)).then(failOp(0)).then(settleOutcome(0)).then(retireFrame(0)).expect(safe)
 run repeatedGcTest=init.then(normal(0)).then(parkAgain(0)).then(collectOne(0)).then(resume(0)).then(allocateMarker(0)).expect(safe and s.heap==2 and s.local.get(0)==2)
 run readerDrainTest=init.then(normal(0)).then(failOp(0)).then(settleOutcome(0)).then(beginReader(0)).then(endReader(0)).then(retireFrame(0)).expect(safe)
 run legacyProfileBlockedTest=initLegacy.then(prepare(0)).then(requestGC(0)).then(closeAdmission).then(freeze).expect(safe and not(s.completed))
 run freezeMutableControlTest=init.then(reserve(0)).then(beginIntent(0)).then(forceFreeze).expect(not(safe))
 run dropSourceTooSoonControlTest=init.then(reserve(0)).then(beginIntent(0)).then(forceDrop(0)).expect(not(safe))
 run dropParkedRootControlTest=init.then(prepare(0)).then(forceDrop(0)).expect(not(safe))
 run unknownRetireControlTest=init.then(normal(0)).then(commitRc(0)).then(markUnknown(0)).then(forceRetire(0)).expect(not(safe))
 run readerRetireControlTest=init.then(normal(0)).then(failOp(0)).then(settleOutcome(0)).then(beginReader(0)).then(forceRetire(0)).expect(not(safe))
 run implicitPinRetireControlTest=initImplicit.then(prepare(0)).then(resume(0)).then(failOp(0)).then(settleOutcome(0)).then(forceRetire(0)).expect(not(safe))
 run nativeFreeControlTest=initImplicit.then(prepare(0)).then(forceFreeRc).expect(not(safe))
 run duplicateCommitControlTest=init.then(normal(0)).then(commitRc(0)).then(forceDuplicate(0)).expect(not(safe))
 run staleReloadControlTest=init.then(prepare(0)).then(collectOne(0)).then(forceStaleMarker(0)).expect(not(safe))
 run nestedParentRetireControlTest=init.then(prepare(0)).then(prepare(1)).then(resume(0)).then(failOp(0)).then(settleOutcome(0)).then(forceRetire(0)).expect(not(safe))
 run noOutcomeRetireControlTest=init.then(normal(0)).then(markUnknown(0)).then(forceRetire(0)).expect(not(safe))
 run prematureGcReturnControlTest=init.then(prepare(0)).then(requestGC(0)).then(closeAdmission).then(freeze).then(forceFinish).expect(not(safe))
 run unknownRunningFreezeControlTest=init.then(normal(0)).then(markUnknown(0)).then(prepare(1)).then(requestGC(1)).then(closeAdmission).then(forceFreeze).expect(not(safe))
 run nonzeroRcSkipControlTest=initImplicit.then(prepare(0)).then(requestGC(0)).then(closeAdmission).then(freeze).then(scanRoot(0)).then(forceFinish).expect(not(safe))
 run legacyCompletionControlTest=initLegacy.then(prepare(0)).then(requestGC(0)).then(closeAdmission).then(freeze).then(forceFinish).expect(not(safe))
}
