module root_producer_census {
 import root_census_parameters.* from "./root_census_parameters"
 // A family is an abstraction of all its slots, not a proof that source maps are complete.
 pure val Families=0.to(FamilyCount-1)
 pure def assigned(i)=if(i<2) 0 else if(i%2==0) 0 else 1
 pure val Versions=Families.mapBy(i=>0)
 type State={active:Set[int],count:int,admission:bool,pending:Set[int],waitingGc:Set[int],frozen:bool,
  version:int->int,seen:int->int,manifest:bool,debts:Set[int],stage:int->int,
  queued:Set[int],rootDone:Set[int],done:bool,receipt:bool,markerRoot:bool,markerAllocated:bool}
 pure val initial:State={active:Set(0,1),count:2,admission:true,pending:Set(),waitingGc:Set(),frozen:false,
  version:Versions,seen:Families.mapBy(i=>-1),manifest:true,debts:Set(),stage:Map(0->0,1->0),
  queued:Set(),rootDone:Set(),done:false,receipt:false,markerRoot:false,markerAllocated:false}
 var s:State
 action init=s'=initial
 action initUnknown=s'={...initial,manifest:false}
 action admitWrite(i)=all{s.admission,not(s.frozen),Families.contains(i),not(s.pending.contains(i)),s'={...s,pending:s.pending.union(Set(i))}}
 // Accepted writer owns a root lease until it finishes or fails without changing the payload.
 action commitWrite(i)=all{s.pending.contains(i),not(s.waitingGc.contains(i)),not(s.frozen),s'={...s,pending:s.pending.exclude(Set(i)),version:s.version.set(i,s.version.get(i)+1)}}
 action abortWrite(i)=all{s.pending.contains(i),not(s.waitingGc.contains(i)),not(s.frozen),s'={...s,pending:s.pending.exclude(Set(i))}}
 action needsGC(i)=all{s.pending.contains(i),not(s.frozen),s'={...s,waitingGc:s.waitingGc.union(Set(i))}}
 action closeAdmission=all{s.admission,s'={...s,admission:false}}
 action freeze=all{not(s.admission),s.pending==Set(),not(s.frozen),s'={...s,frozen:true}}
 action scanFamily(i)=all{s.frozen,Families.contains(i),s.active.contains(assigned(i)),not(s.done),s'={...s,seen:s.seen.set(i,s.version.get(i))}}
 def freshFor(w)=Families.forall(i=>assigned(i)!=w or s.seen.get(i)==s.version.get(i))
 action closeProducer(w)=all{s.frozen,freshFor(w),s.active.contains(w),s'={...s,rootDone:s.rootDone.union(Set(w))}}
 pure def key(w,k)=7*w+k
 // 0 copy,1 alloc cursor,2 inline tail,3 publish,4 scanner frame,5 still,6 descendants.
 action startCopy(w)=all{s.frozen,s.active.contains(w),s.stage.get(w)==0,not(s.done),
  s'={...s,stage:s.stage.set(w,1),debts:s.debts.union(Set(key(w,0),key(w,2)))}}
 action finishPayload(w)=all{s.stage.get(w)==1,s.debts.contains(key(w,0)),
  s'={...s,debts:s.debts.exclude(Set(key(w,0))).union(Set(key(w,1))),stage:s.stage.set(w,2)}}
 action finishTail(w)=all{s.debts.contains(key(w,2)),s'={...s,debts:s.debts.exclude(Set(key(w,2)))}}
 action commitCursor(w)=all{s.stage.get(w)==2,not(s.debts.contains(key(w,0))),not(s.debts.contains(key(w,2))),
  s'={...s,debts:s.debts.exclude(Set(key(w,1))),stage:s.stage.set(w,3)}}
 action beginPublish(w)=all{s.stage.get(w)==3,not(s.debts.contains(key(w,3))),s'={...s,debts:s.debts.union(Set(key(w,3)))}}
 action commitPublish(w)=all{s.stage.get(w)==3,s.debts.contains(key(w,3)),
  s'={...s,debts:s.debts.exclude(Set(key(w,3))),queued:s.queued.union(Set(w)),stage:s.stage.set(w,5)}}
 action scanPrivate(w)=all{s.stage.get(w)==3,not(s.debts.contains(key(w,3))),
  s'={...s,stage:s.stage.set(w,4),debts:s.debts.union(Set(key(w,4)))}}
 action dequeue(src,dst)=all{s.queued.contains(src),s.active.contains(dst),s.stage.get(dst)==0 or src==dst,
  s'={...s,queued:s.queued.exclude(Set(src)),stage:s.stage.set(src,5).set(dst,4),debts:s.debts.union(Set(key(dst,4)))}}
 action discover(w)=all{s.stage.get(w)==4,s.debts.contains(key(w,4)),
  s'={...s,debts:s.debts.union(Set(key(w,5),key(w,6)))}}
 action drainDerived(w)=all{s.stage.get(w)==4,s'={...s,debts:s.debts.exclude(Set(key(w,5),key(w,6)))}}
 action finishScan(w)=all{s.stage.get(w)==4,not(s.debts.contains(key(w,5))),not(s.debts.contains(key(w,6))),
  s'={...s,debts:s.debts.exclude(Set(key(w,4))),stage:s.stage.set(w,5)}}
 def clear(w)=s.rootDone.contains(w) and not(s.queued.contains(w)) and 0.to(6).forall(k=>not(s.debts.contains(key(w,k)))) and Set(0,5).contains(s.stage.get(w))
 action idle(w)=all{s.active.contains(w),clear(w),not(s.done),s'={...s,active:s.active.exclude(Set(w)),count:s.count-1,done:s.count==1}}
 action issueReceipt=all{s.done,s.manifest,s.frozen,s.pending==Set(),Families.forall(i=>s.seen.get(i)==s.version.get(i)),s'={...s,receipt:true}}
 action protectArgument=s'={...s,markerRoot:true}
 action allocateMarker=all{s.markerRoot,s'={...s,markerAllocated:true}}
 def safe=s.waitingGc.subseteq(s.pending) and s.count==s.active.size() and s.rootDone.subseteq(Set(0,1)) and
  (s.frozen implies not(s.admission) and s.pending==Set()) and
  s.debts.forall(d=>s.active.contains(d/7)) and s.queued.subseteq(s.active) and
  0.to(1).forall(w=>(Set(1,2,3,4).contains(s.stage.get(w)) implies s.active.contains(w)) and
   (not(s.active.contains(w)) implies clear(w))) and
  (s.done implies s.count==0 and s.rootDone==Set(0,1) and s.debts==Set() and s.queued==Set()) and
  (s.receipt implies s.done and s.manifest and s.frozen and Families.forall(i=>s.seen.get(i)==s.version.get(i))) and
  (s.markerAllocated implies s.markerRoot)
 action step={nondet i=Families.oneOf();nondet w=0.to(1).oneOf();nondet t=0.to(1).oneOf();any{
  admitWrite(i),commitWrite(i),abortWrite(i),needsGC(i),closeAdmission,freeze,scanFamily(i),closeProducer(w),
  startCopy(w),finishPayload(w),finishTail(w),commitCursor(w),beginPublish(w),commitPublish(w),scanPrivate(w),dequeue(w,t),
  discover(w),drainDerived(w),finishScan(w),idle(w),issueReceipt,protectArgument,allocateMarker,s'=s}}
 action seal=closeAdmission.then(freeze)
 action scanAll=scanFamily(0).then(scanFamily(1)).then(scanFamily(2)).then(scanFamily(3)).then(scanFamily(4)).then(scanFamily(5)).then(scanFamily(6)).then(scanFamily(7)).then(scanFamily(8)).then(scanFamily(9)).then(scanFamily(10)).then(scanFamily(11))
 action closeRoots=scanAll.then(closeProducer(0)).then(closeProducer(1))
 action copied(w)=startCopy(w).then(finishPayload(w)).then(finishTail(w)).then(commitCursor(w))
 action finishAll=closeRoots.then(idle(0)).then(idle(1))
 action forceIdle(w)=s'={...s,active:s.active.exclude(Set(w)),count:s.count-1,done:s.count==1}
 action forceWrite(i)=s'={...s,version:s.version.set(i,s.version.get(i)+1)}
 action forceReceipt=s'={...s,receipt:true}
 action forceFreeze=s'={...s,frozen:true,admission:false}
 action forceMarker=s'={...s,markerAllocated:true}
 // Source-shaped omission witness, not an execution of a configured native caller.
 action omitRcOne=s'={...s,seen:s.seen.set(11,-1),rootDone:Set(0,1),active:Set(),count:0,done:true}
 run allRootsTest=init.then(seal).then(finishAll).then(issueReceipt).expect(safe and s.receipt)
 run acceptedWriterTest=init.then(admitWrite(11)).then(closeAdmission).then(commitWrite(11)).then(freeze).then(finishAll).then(issueReceipt).expect(safe and s.version.get(11)==1)
 run abortedWriterTest=init.then(admitWrite(11)).then(closeAdmission).then(abortWrite(11)).then(freeze).then(finishAll).then(issueReceipt).expect(safe and s.version.get(11)==0)
 run writerGcCycleTest=init.then(admitWrite(11)).then(needsGC(11)).then(closeAdmission).expect(safe and s.pending==Set(11) and s.waitingGc==Set(11) and not(s.frozen) and not(s.receipt))
 run nonzeroRcTest=init.then(seal).then(scanFamily(11)).expect(safe and s.seen.get(11)==0)
 run privateChunkTest=init.then(seal).then(closeRoots).then(copied(1)).then(scanPrivate(1)).then(discover(1)).then(drainDerived(1)).then(finishScan(1)).then(idle(0)).then(idle(1)).then(issueReceipt).expect(safe)
 run publishStealTest=init.then(seal).then(closeRoots).then(copied(0)).then(beginPublish(0)).then(commitPublish(0)).then(dequeue(0,1)).then(idle(0)).then(discover(1)).then(drainDerived(1)).then(finishScan(1)).then(idle(1)).then(issueReceipt).expect(safe)
 run protectedMarkerTest=init.then(protectArgument).then(allocateMarker).expect(safe)
 run unknownManifestTest=initUnknown.then(seal).then(finishAll).expect(safe and not(s.receipt))
 run omittedRcWitnessTest=init.then(seal).then(closeRoots).then(omitRcOne).expect(safe and s.done and not(s.receipt) and s.seen.get(11)!=s.version.get(11))
 run closeWithLeaseControlTest=init.then(admitWrite(11)).then(forceFreeze).expect(not(safe))
 run omitRcReceiptControlTest=init.then(seal).then(closeRoots).then(omitRcOne).then(forceReceipt).expect(not(safe))
 run staleWriteReceiptControlTest=init.then(seal).then(finishAll).then(issueReceipt).then(forceWrite(11)).expect(not(safe))
 run idleCopyControlTest=init.then(seal).then(closeRoots).then(startCopy(1)).then(forceIdle(1)).expect(not(safe))
 run idleTailControlTest=init.then(seal).then(closeRoots).then(startCopy(1)).then(finishPayload(1)).then(forceIdle(1)).expect(not(safe))
 run idleCursorControlTest=init.then(seal).then(closeRoots).then(startCopy(1)).then(finishPayload(1)).then(finishTail(1)).then(forceIdle(1)).expect(not(safe))
 run idlePublishControlTest=init.then(seal).then(closeRoots).then(copied(1)).then(beginPublish(1)).then(forceIdle(1)).expect(not(safe))
 run idlePrivateControlTest=init.then(seal).then(closeRoots).then(copied(1)).then(forceIdle(1)).expect(not(safe))
 run idleScannerControlTest=init.then(seal).then(closeRoots).then(copied(1)).then(scanPrivate(1)).then(discover(1)).then(forceIdle(1)).expect(not(safe))
 run markerBeforeRootControlTest=init.then(forceMarker).expect(not(safe))
 run unknownManifestReceiptControlTest=initUnknown.then(seal).then(finishAll).then(forceReceipt).expect(not(safe))
}
