module strong_closure_receipt {
 import strong_closure_parameters.* from "./strong_closure_parameters"
 // One strong epoch: two worker credits, three canonical objects, cyclic derived work.
 // Work: 0 unseen, 1 root/child demand, 2 forwarding-visible copy, 3 initialized private,
 // 4 public FIFO, 5 dequeued scanner frame, 6 fully scanned.
 type State={epoch:int,members:Set[int],active:Set[int],count:int,rootsOpen:Set[int],seeded:Set[int],rootCoverage:bool,
  work:int->int,owner:int->int,copied:int->int,visible:int->int,
  cursorDebt:Set[int],publishDebt:Set[int],bodyDone:Set[int],advanceDebt:Set[int],
  done:bool,issued:Set[int],receiptEpoch:int,classified:Set[int],weakReady:bool,reclaimed:bool}
 pure val initial:State={epoch:11,members:Set(0,1),active:Set(0,1),count:2,rootsOpen:Set(0,1),seeded:Set(),rootCoverage:true,
  work:Map(0->0,1->0,2->0),owner:Map(0->0,1->1,2->0),copied:Map(0->0,1->0,2->0),visible:Map(0->0,1->0,2->0),
  cursorDebt:Set(),publishDebt:Set(),bodyDone:Set(),advanceDebt:Set(),done:false,issued:Set(),receiptEpoch:-1,classified:Set(),weakReady:false,reclaimed:false}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,rootCoverage:false}
 action seedRoot(w)=all {not(s.done),s.rootsOpen.contains(w),s.active.contains(w),not(s.seeded.contains(w)),
  s'={...s,seeded:s.seeded.union(Set(w)),work:if(s.work.get(w)==0) s.work.set(w,1) else s.work,
   owner:if(s.work.get(w)==0) s.owner.set(w,w) else s.owner}}
 action closeRoots(w)=all {s.rootsOpen.contains(w),s.seeded.contains(w),s'={...s,rootsOpen:s.rootsOpen.exclude(Set(w))}}
 action claim(o)=all {not(s.done),s.work.get(o)==1,s.active.contains(s.owner.get(o)),s'={...s,work:s.work.set(o,2)}}
 action copyWord(o)=all {s.work.get(o)==2,s.copied.get(o)<2,s.active.contains(s.owner.get(o)),s'={...s,copied:s.copied.set(o,s.copied.get(o)+1)}}
 action finishCopy(o)=all {s.work.get(o)==2,s.copied.get(o)==2,s.active.contains(s.owner.get(o)),
  s'={...s,work:s.work.set(o,3),cursorDebt:s.cursorDebt.union(Set(o))}}
 // Source obligation: inline tail work and local alloc cursor commit have settled here.
 action commitCursor(o)=all {s.work.get(o)==3,s.cursorDebt.contains(o),s.active.contains(s.owner.get(o)),s'={...s,cursorDebt:s.cursorDebt.exclude(Set(o))}}
 action beginPublish(o)=all {s.work.get(o)==3,not(s.cursorDebt.contains(o)),not(s.publishDebt.contains(o)),s.active.contains(s.owner.get(o)),
  s'={...s,publishDebt:s.publishDebt.union(Set(o))}}
 action commitPublish(o)=all {s.work.get(o)==3,s.publishDebt.contains(o),s.active.contains(s.owner.get(o)),
  s'={...s,work:s.work.set(o,4),visible:s.visible.set(o,s.copied.get(o)),publishDebt:s.publishDebt.exclude(Set(o))}}
 action scanPrivate(o)=all {s.work.get(o)==3,not(s.cursorDebt.contains(o)),not(s.publishDebt.contains(o)),s.active.contains(s.owner.get(o)),s'={...s,work:s.work.set(o,5)}}
 action dequeue(o,w)=all {not(s.done),s.work.get(o)==4,s.active.contains(w),s.visible.get(o)==2,
  s'={...s,work:s.work.set(o,5),owner:s.owner.set(o,w)}}
 action scanBody(o)=all {s.work.get(o)==5,s.active.contains(s.owner.get(o)),not(s.bodyDone.contains(o)),
  val child=if(o==2) 0 else 2;
  val fresh=s.work.get(child)==0;
  s'={...s,bodyDone:s.bodyDone.union(Set(o)),advanceDebt:s.advanceDebt.union(Set(o)),
   work:if(fresh) s.work.set(child,1) else s.work,owner:if(fresh) s.owner.set(child,s.owner.get(o)) else s.owner}}
 action finishScan(o)=all {s.work.get(o)==5,s.bodyDone.contains(o),s.advanceDebt.contains(o),s.active.contains(s.owner.get(o)),
  s'={...s,work:s.work.set(o,6),advanceDebt:s.advanceDebt.exclude(Set(o))}}
 def localClear(w)=not(s.rootsOpen.contains(w)) and 0.to(2).forall(o=>s.owner.get(o)!=w or not(Set(1,2,3,4,5).contains(s.work.get(o))))
 action idle(w)=all {not(s.done),s.active.contains(w),localClear(w),
  s'={...s,active:s.active.exclude(Set(w)),count:s.count-1,done:s.count==1}}
 // Waking after a zero observation is forbidden; a wake with count>0 reacquires credit first.
 action wake(w)=all {not(s.done),s.count>0,s.members.contains(w),not(s.active.contains(w)),s'={...s,active:s.active.union(Set(w)),count:s.count+1}}
 action issueReceipt(w)=all {s.done,s.count==0,s.rootCoverage,s.members.contains(w),not(s.issued.contains(w)),not(s.weakReady),
  s'={...s,issued:s.issued.union(Set(w)),receiptEpoch:s.epoch}}
 action classify(w)=all {s.issued.contains(w),s.receiptEpoch==s.epoch,not(s.weakReady),s'={...s,classified:s.classified.union(Set(w))}}
 action reuseBarrier=all {s.issued==s.members,s.classified==s.members,s'={...s,weakReady:true}}
 // Only an epoch-metadata retirement marker; not permission to free queues reused by weak GC.
 action retireMetadata=all {s.issued==s.members,s.weakReady,s'={...s,reclaimed:true}}
 def tracedClosed=s.rootsOpen==Set() and 0.to(2).forall(o=>s.work.get(o)==6) and s.cursorDebt==Set() and s.publishDebt==Set() and s.advanceDebt==Set()
 def safe=s.count==s.active.size() and s.active.subseteq(s.members) and s.rootsOpen.subseteq(s.active) and
  0.to(2).forall(o=>(Set(1,2,3,4,5).contains(s.work.get(o)) implies s.active.contains(s.owner.get(o))) and
   (Set(3,4,5,6).contains(s.work.get(o)) implies s.copied.get(o)==2) and (s.work.get(o)==4 implies s.visible.get(o)==2)) and
  s.cursorDebt.forall(o=>s.work.get(o)==3) and s.publishDebt.forall(o=>s.work.get(o)==3) and s.advanceDebt.forall(o=>s.work.get(o)==5) and
  (s.done implies s.count==0 and tracedClosed) and
  (s.issued!=Set() implies s.done and s.rootCoverage and s.receiptEpoch==s.epoch) and
  s.classified.subseteq(s.issued) and (s.weakReady implies s.classified==s.members and s.issued==s.members) and
  (s.reclaimed implies s.weakReady and s.issued==s.members)
 action step={nondet o=0.to(2).oneOf();nondet w=0.to(WorkspaceCount-1).oneOf();any {seedRoot(w),closeRoots(w),claim(o),copyWord(o),finishCopy(o),commitCursor(o),
  beginPublish(o),commitPublish(o),scanPrivate(o),dequeue(o,w),scanBody(o),finishScan(o),idle(w),wake(w),issueReceipt(w),classify(w),reuseBarrier,retireMetadata,s'=s}}
 action rootSetup=seedRoot(0).then(closeRoots(0)).then(seedRoot(1)).then(closeRoots(1))
 action copied(o)=claim(o).then(copyWord(o)).then(copyWord(o)).then(finishCopy(o)).then(commitCursor(o))
 action privateScan(o)=copied(o).then(scanPrivate(o)).then(scanBody(o)).then(finishScan(o))
 action closeAll=rootSetup.then(privateScan(0)).then(privateScan(1)).then(privateScan(2)).then(idle(0)).then(idle(1))
 action forceIdle(w)=s'={...s,active:s.active.exclude(Set(w)),count:s.count-1,done:s.count==1}
 action forceReceipt=s'={...s,issued:Set(0),receiptEpoch:s.epoch}
 action forceRetire=s'={...s,reclaimed:true}
 action staleReceipt=s'={...s,receiptEpoch:s.epoch-1}
 action lateRoot=s'={...s,work:s.work.set(2,1),rootsOpen:Set(0)}
 action forceWeak=s'={...s,weakReady:true}
 run allPrivateTest=init.then(closeAll).then(issueReceipt(0)).expect(safe and tracedClosed)
 run firstReturnBeforePeerTest=init.then(closeAll).then(issueReceipt(0)).then(classify(0)).expect(safe and s.issued==Set(0) and not(s.weakReady))
 run barrierReuseTest=init.then(closeAll).then(issueReceipt(0)).then(classify(0)).then(issueReceipt(1)).then(classify(1)).then(reuseBarrier).expect(safe and s.weakReady)
 run metadataRetirementTest=init.then(closeAll).then(issueReceipt(0)).then(issueReceipt(1)).then(classify(0)).then(classify(1)).then(reuseBarrier).then(retireMetadata).expect(safe)
 run countCoversCopyTest=init.then(rootSetup).then(claim(0)).then(copyWord(0)).expect(safe and s.count==2 and s.work.get(0)==2)
 run cursorUnpublishedTest=init.then(rootSetup).then(claim(0)).then(copyWord(0)).then(copyWord(0)).then(finishCopy(0)).expect(safe and s.cursorDebt==Set(0))
 run publicationPendingTest=init.then(rootSetup).then(copied(0)).then(beginPublish(0)).expect(safe and s.publishDebt==Set(0))
 run stealTransfersCustodyTest=init.then(rootSetup).then(copied(0)).then(beginPublish(0)).then(commitPublish(0)).then(dequeue(0,1)).then(scanBody(0)).then(finishScan(0)).expect(safe and s.owner.get(0)==1 and s.owner.get(2)==1)
 run rootProducerStillOpenTest=init.then(seedRoot(0)).expect(safe and s.rootsOpen==Set(0,1) and s.count==2)
 run missingRootCensusTest=initOther.then(closeAll).expect(safe and tracedClosed and not(s.rootCoverage))
 run helperIdleWithOtherQueueTest=init.then(rootSetup).then(privateScan(1)).then(privateScan(2)).then(copied(0)).then(beginPublish(0)).then(commitPublish(0)).then(idle(1)).expect(safe and s.count==1 and s.work.get(0)==4)
 run wakeCreditBeforeStealTest=init.then(rootSetup).then(privateScan(1)).then(privateScan(2)).then(copied(0)).then(beginPublish(0)).then(commitPublish(0)).then(idle(1)).then(wake(1)).then(dequeue(0,1)).then(scanBody(0)).then(finishScan(0)).then(idle(0)).then(idle(1)).then(issueReceipt(0)).expect(safe and tracedClosed)
 run idleWithCopyControlTest=init.then(rootSetup).then(claim(0)).then(forceIdle(0)).expect(not(safe))
 run idleWithCursorControlTest=init.then(rootSetup).then(claim(0)).then(copyWord(0)).then(copyWord(0)).then(finishCopy(0)).then(forceIdle(0)).expect(not(safe))
 run idleWithPublishControlTest=init.then(rootSetup).then(copied(0)).then(beginPublish(0)).then(forceIdle(0)).expect(not(safe))
 run idleWithDequeuedControlTest=init.then(rootSetup).then(copied(0)).then(beginPublish(0)).then(commitPublish(0)).then(dequeue(0,1)).then(forceIdle(1)).expect(not(safe))
 run idleWithRootProducerControlTest=init.then(forceIdle(0)).expect(not(safe))
 run localEmptyReceiptControlTest=init.then(rootSetup).then(forceReceipt).expect(not(safe))
 run missingCensusReceiptControlTest=initOther.then(closeAll).then(forceReceipt).expect(not(safe))
 run staleEpochControlTest=init.then(closeAll).then(issueReceipt(0)).then(staleReceipt).expect(not(safe))
 run retireBeforePeerReturnControlTest=init.then(closeAll).then(issueReceipt(0)).then(forceRetire).expect(not(safe))
 run reopenAfterZeroControlTest=init.then(closeAll).then(lateRoot).expect(not(safe))
 run weakBeforeAllClassifiedControlTest=init.then(closeAll).then(issueReceipt(0)).then(classify(0)).then(forceWeak).expect(not(safe))
 run idleWithAdvanceControlTest=init.then(rootSetup).then(copied(0)).then(scanPrivate(0)).then(scanBody(0)).then(forceIdle(0)).expect(not(safe))
}
