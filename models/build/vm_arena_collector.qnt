module vm_arena_collector {
 import arena_collector_parameters.* from "./arena_collector_parameters"
 // Three symbolic blocks, two arenas, two worker slots, three statistic ledgers.
 // Phases: 0 open, 1 strong, 2 weak, 3 sweep, 4 census/reopen.
 type State={phase:int,epoch:int,processors:Set[int],transferred:bool,archived:int,
  physical:Set[int],quarantine:Set[int],freed:Set[int],charged:int,deferred:int,
  base:int->int,occupancy:int->int,folded:bool,history:int,latest:int,
  roots:Set[int],snapshot:Set[int],arenas:Set[int],workers:Set[int],sweeper:int->int,
  marked:Set[int],queue:Set[int],inflight:Set[int],scanner:int->int,scanned:Set[int],
  weakDecided:bool,swept:Set[int],task:int,attempts:int}
 pure def words(xs:Set[int]):int=xs.fold(0,(sum,i)=>sum+(if(i==0) 5 else if(i==1) 7 else 11))
 pure def arena(i:int):int=if(i==0) 0 else 1
 pure def objects(a:int,xs:Set[int]):Set[int]=xs.filter(i=>arena(i)==a)
 pure def due(s:State):int=s.archived+0.to(2).fold(0,(sum,i)=>sum+s.base.get(i)+(if(s.folded) 0 else s.occupancy.get(i)))
 pure def owner(s:State,a:int):int=if(a==0) 0 else if(s.transferred) 2 else 1
 pure def occupied(s:State,i:int):int=if(i==owner(s,0)) words(objects(0,s.physical)) else if(i==owner(s,1)) words(objects(1,s.physical)) else 0
 pure val initial:State={phase:0,epoch:0,processors:Set(0,1),transferred:false,archived:0,
  physical:Set(0,1,2),quarantine:Set(),freed:Set(),charged:16,deferred:7,
  base:Map(0->95,1->182,2->0),occupancy:Map(0->5,1->18,2->0),folded:false,history:300,latest:300,
  roots:Set(0),snapshot:Set(),arenas:Set(),workers:Set(),sweeper:Map(0->0,1->0),
  marked:Set(),queue:Set(),inflight:Set(),scanner:Map(0->0,1->0,2->0),scanned:Set(),weakDecided:false,swept:Set(),task:0,attempts:0}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,roots:Set(1)}
 // Storage handoff changes signed occupancy baselines, not cumulative allocation.
 action handoff=all {s.phase==0,not(s.transferred),s.processors.contains(1),
  s'={...s,transferred:true,charged:s.charged+s.deferred,deferred:0,
    base:s.base.set(1,s.base.get(1)+s.occupancy.get(1)).set(2,s.base.get(2)-s.occupancy.get(1)),
    occupancy:s.occupancy.set(2,s.occupancy.get(1)).set(1,0)}}
 action depart=all {s.phase==0,s.transferred,s.processors.contains(1),
  s'={...s,processors:s.processors.exclude(Set(1)),archived:s.archived+s.base.get(1)+s.occupancy.get(1),
    base:s.base.set(1,0),occupancy:s.occupancy.set(1,0)}}
 action beginGC=all {s.phase==0,
  s'={...s,phase:1,snapshot:s.physical,arenas:Set(0,1),workers:s.processors,
   charged:s.charged+s.deferred,deferred:0,base:0.to(2).mapBy(i=>s.base.get(i)+s.occupancy.get(i)),folded:true,
   marked:s.roots,queue:s.roots,inflight:Set(),scanned:Set(),weakDecided:false,swept:Set()}}
 action dequeue(i,w)=all {s.phase==1 or s.phase==2,s.workers.contains(w),s.queue.contains(i),
  s.inflight.forall(j=>s.scanner.get(j)!=w),
  s'={...s,queue:s.queue.exclude(Set(i)),inflight:s.inflight.union(Set(i)),scanner:s.scanner.set(i,w)}}
 // Root 0's body contains an edge to block 1 in the other arena.
 action finishScan(i)=all {s.inflight.contains(i),s.phase==1 or s.phase==2,
  val children=if(i==0 and s.physical.contains(1)) Set(1) else Set();
  val fresh=children.exclude(s.marked);
  s'={...s,inflight:s.inflight.exclude(Set(i)),scanned:s.scanned.union(Set(i)),marked:s.marked.union(fresh),queue:s.queue.union(fresh)}}
 action enterWeak=all {s.phase==1,s.queue==Set(),s.inflight==Set(),s'={...s,phase:2}}
 action processWeakKeep=all {s.phase==2,not(s.weakDecided),s.physical.contains(2),not(s.quarantine.contains(2)),
  val fresh=Set(2).exclude(s.marked);
  s'={...s,weakDecided:true,marked:s.marked.union(fresh),queue:s.queue.union(fresh)}}
 action processWeakClear=all {s.phase==2,not(s.weakDecided),s'={...s,weakDecided:true}}
 action enterSweep=all {s.phase==2,s.weakDecided,s.queue==Set(),s.inflight==Set(),s'={...s,phase:3}}
 // Dead foreign block 2 stays physically charged in quarantine until settlement.
 action sweep(a,w)=all {s.phase==3,s.arenas.contains(a),not(s.swept.contains(a)),s.sweeper.get(a)==w,s.workers.contains(w),
  val dead=objects(a,s.physical).exclude(s.marked).exclude(s.quarantine);
  val normal=dead.exclude(Set(2));
  val foreign=dead.intersect(Set(2));
  s'={...s,physical:s.physical.exclude(normal),freed:s.freed.union(normal),quarantine:s.quarantine.union(foreign),
   task:if(foreign==Set()) s.task else 1,swept:s.swept.union(Set(a))}}
 action enterCensus=all {s.phase==3,s.swept==s.arenas,s'={...s,phase:4}}
 action finishGC=all {s.phase==4,
  s'={...s,phase:0,epoch:s.epoch+1,charged:words(s.physical),deferred:0,latest:due(s),
   base:0.to(2).mapBy(i=>s.base.get(i)-occupied(s,i)),occupancy:0.to(2).mapBy(i=>occupied(s,i)),folded:false,
   snapshot:Set(),arenas:Set(),workers:Set()}}
 // Qualified release lane is an explicit premise; unknown result retains the shell.
 action startRelease=all {s.phase==0,s.task==1,s'={...s,task:2,attempts:s.attempts+1}}
 action unknownRelease=all {s.task==2,s'={...s,task:3}}
 action settleRelease=all {s.task==2 or s.task==3,s'={...s,task:4}}
 action freeReleased=all {s.phase==0,s.task==4,s.quarantine.contains(2),
  val ledger=owner(s,1);
  s'={...s,physical:s.physical.exclude(Set(2)),quarantine:s.quarantine.exclude(Set(2)),freed:s.freed.union(Set(2)),charged:s.charged-11,
   occupancy:s.occupancy.set(ledger,s.occupancy.get(ledger)-11),base:s.base.set(ledger,s.base.get(ledger)+11),task:5}}
 def safe=due(s)==s.history and s.latest==s.history and
  s.physical.intersect(s.freed)==Set() and s.physical.union(s.freed)==Set(0,1,2) and s.quarantine.subseteq(s.physical) and
  (s.phase==0 implies not(s.folded) and s.charged+s.deferred==words(s.physical) and 0.to(2).forall(i=>s.occupancy.get(i)==occupied(s,i))) and
  (s.phase!=0 implies s.folded and s.workers==s.processors and s.arenas==Set(0,1)) and
  ((s.phase==1 or s.phase==2) implies s.physical==s.snapshot and s.charged==words(s.physical) and s.deferred==0) and
  s.queue.intersect(s.inflight)==Set() and s.queue.intersect(s.scanned)==Set() and s.inflight.intersect(s.scanned)==Set() and
  s.marked==s.queue.union(s.inflight).union(s.scanned) and s.inflight.forall(i=>s.workers.contains(s.scanner.get(i))) and
  (s.scanned.contains(0) implies s.marked.contains(1)) and
  (s.phase>=3 implies s.weakDecided and s.queue==Set() and s.inflight==Set() and s.marked==s.scanned and s.marked.subseteq(s.physical)) and
  (not(s.processors.contains(1)) implies s.transferred and s.base.get(1)==0 and s.occupancy.get(1)==0) and
  (s.task>=1 and s.task<=4 implies s.quarantine.contains(2)) and s.attempts<=1
 action step={nondet i=0.to(2).oneOf(); nondet w=0.to(WorkspaceCount-1).oneOf(); nondet a=0.to(1).oneOf();
  any {handoff,depart,beginGC,dequeue(i,w),finishScan(i),enterWeak,processWeakKeep,processWeakClear,enterSweep,sweep(a,w),enterCensus,finishGC,
   startRelease,unknownRelease,settleRelease,freeReleased,s'=s}}
 action strongRoot0=dequeue(0,0).then(finishScan(0)).then(dequeue(1,0)).then(finishScan(1)).then(enterWeak)
 action strongRoot1=dequeue(1,0).then(finishScan(1)).then(enterWeak)
 action sweepBoth=sweep(0,0).then(sweep(1,0)).then(enterCensus).then(finishGC)
 action gcClear=beginGC.then(strongRoot0).then(processWeakClear).then(enterSweep).then(sweepBoth)
 action badDropStats=s'={...s,processors:s.processors.exclude(Set(1)),base:s.base.set(1,0),occupancy:s.occupancy.set(1,0)}
 action badDoubleHistory=s'={...s,archived:s.archived+18}
 action badCapacity=s'={...s,charged:5}
 action badEarlySweep=s'={...s,phase:3,weakDecided:true}
 action badOmitArena=s'={...s,arenas:Set(0)}
 action badWorkerExit=s'={...s,processors:s.processors.exclude(Set(1))}
 action badFreeUnknown=s'={...s,physical:s.physical.exclude(Set(2)),quarantine:Set(),freed:s.freed.union(Set(2)),charged:s.charged-11}
 action badFold=s'={...s,charged:s.charged+s.deferred,deferred:0,archived:s.archived+7}
 action badCopyCharge=s'={...s,base:s.base.set(2,s.base.get(2)+18)}
 action badRetry=s'={...s,attempts:s.attempts+1}
 action badOmitChild=s'={...s,inflight:s.inflight.exclude(Set(0)),scanned:s.scanned.union(Set(0))}
 action badResetMarks=s'={...s,marked:s.roots,queue:s.roots}
 run exitScanTest=init.then(handoff).then(depart).then(gcClear).expect(safe and s.scanned==Set(0,1) and s.physical==Set(0,1,2))
 run deferredOnceTest=init.then(handoff).then(gcClear).expect(safe and s.charged==23 and s.deferred==0)
 run sourceArenaTest=init.then(gcClear).expect(safe and not(s.transferred))
 run pendingScanTest=init.then(beginGC).then(dequeue(0,0)).expect(safe and s.queue==Set() and s.inflight==Set(0))
 run weakKeepTest=init.then(handoff).then(depart).then(beginGC).then(strongRoot0).then(processWeakKeep).then(dequeue(2,0)).then(finishScan(2)).then(enterSweep).then(sweepBoth).expect(safe and s.task==0 and s.scanned==Set(0,1,2))
 run sweepNormalTest=initOther.then(handoff).then(depart).then(beginGC).then(strongRoot1).then(processWeakClear).then(enterSweep).then(sweepBoth).expect(safe and s.freed==Set(0) and s.charged==18)
 run historyAfterReleaseTest=init.then(handoff).then(depart).then(gcClear).then(startRelease).then(settleRelease).then(freeReleased).expect(safe and s.charged==12 and due(s)==300)
 run unknownRetainedTest=init.then(handoff).then(depart).then(gcClear).then(startRelease).then(unknownRelease).then(gcClear).expect(safe and s.task==3 and s.charged==23 and s.attempts==1)
 run lateHandoffTest=init.then(gcClear).then(handoff).then(depart).expect(safe and s.archived==200)
 run repeatEpochTest=init.then(handoff).then(depart).then(gcClear).then(gcClear).expect(safe and s.epoch==2 and s.attempts==0)
 run statsArchiveTest=init.then(handoff).then(depart).expect(safe and s.archived==200 and s.base.get(2)== -18)
 run dropStatisticsControlTest=init.then(handoff).then(badDropStats).expect(not(safe))
 run transferAsAllocationControlTest=init.then(handoff).then(badDoubleHistory).expect(not(safe))
 run omittedCapacityControlTest=init.then(handoff).then(depart).then(gcClear).then(badCapacity).expect(not(safe))
 run dequeuedWorkControlTest=init.then(beginGC).then(dequeue(0,0)).then(badEarlySweep).expect(not(safe))
 run weakPendingControlTest=init.then(beginGC).then(strongRoot0).then(processWeakKeep).then(badEarlySweep).expect(not(safe))
 run omittedArenaControlTest=init.then(handoff).then(depart).then(beginGC).then(badOmitArena).expect(not(safe))
 run workerExitControlTest=init.then(beginGC).then(badWorkerExit).expect(not(safe))
 run unknownFreeControlTest=init.then(handoff).then(depart).then(gcClear).then(startRelease).then(unknownRelease).then(badFreeUnknown).expect(not(safe))
 run deferredAsHistoryControlTest=init.then(badFold).expect(not(safe))
 run copiedBaselineControlTest=init.then(handoff).then(badCopyCharge).expect(not(safe))
 run duplicateReleaseControlTest=init.then(gcClear).then(startRelease).then(unknownRelease).then(badRetry).expect(not(safe))
 run outgoingEdgeControlTest=init.then(beginGC).then(dequeue(0,0)).then(badOmitChild).expect(not(safe))
 run duplicateInitializationControlTest=init.then(beginGC).then(dequeue(0,0)).then(finishScan(0)).then(badResetMarks).expect(not(safe))
}
