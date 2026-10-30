module marker_joint_publication {
  // Two operation identities, two physical domains. Same-domain and split-owner profiles.
  // 0 absent,1 input root/reservation,2 raw private,3 permit,4 body,5 list,
  // 6 root entry,7 canonical commit/permit,8 exposed,9 aborted,10 native outcome debt.
  type State={stage:int->int,owners:int->int,inputRoots:Set[int],entries:Set[int],
    committed:Set[int],linked:Set[int],heads:int->int,next:int->int,permits:Set[int],
    initialized:Set[int],dead:Set[int],stopped:Set[int],lost:Set[int],nativeCalls:int->int,
    frees:int->int,credit:int->int,bodyRev:int->int,rootRev:int,phase:int,epoch:int,
    snapshot:Set[int],frozenInputs:Set[int],setup:Set[int],marked:Set[int],waiting:Set[int],unseen:Set[int],
    unknownNative:Set[int],rawCount:int,unsafeCall:bool}
  var s:State
  val ids=Set(0,1)
  val domains=Set(0,1)
  def chain(d)=if(s.heads.get(d)==(-1)) Set() else {
    val h=s.heads.get(d)
    if(s.next.get(h)==(-1)) Set(h) else Set(h,s.next.get(h))
  }
  def writer(i)=not(s.dead.contains(i)) or s.stopped.contains(i)
  val allSetup=s.setup==domains
  val safe=s.rawCount==0 and not(s.unsafeCall) and s.waiting.intersect(s.permits)==Set() and
    s.linked==chain(0).union(chain(1)) and s.linked.subseteq(s.initialized) and
    s.entries.subseteq(s.linked) and s.committed.subseteq(s.entries) and
    (s.permits!=Set() or (s.linked==s.entries and s.entries==s.committed)) and
    (s.phase<2 or (s.permits==Set() and s.snapshot==s.committed)) and
    (s.phase<2 or s.frozenInputs.subseteq(s.inputRoots)) and (s.marked==Set() or allSetup) and s.marked.subseteq(s.snapshot) and
    ids.forall(i=>s.nativeCalls.get(i)<=1 and s.frees.get(i)<=1 and
      ((s.stage.get(i)<3 or s.stage.get(i)>7) or s.permits.contains(i)) and
      (not(s.linked.contains(i)) or s.frees.get(i)==0) and
      (not(s.unknownNative.contains(i)) or (s.credit.get(i)==4 and s.inputRoots.contains(i))) and
      (not(s.permits.contains(i)) or s.inputRoots.contains(i)) and
      (not(s.initialized.contains(i)) or s.bodyRev.get(i)==s.rootRev) and
      (not(s.committed.contains(i)) or s.credit.get(i)==2) and
      (s.stage.get(i)!=8 or s.committed.contains(i))) and
    s.permits.forall(i=>s.permits.forall(j=>i==j or s.owners.get(i)!=s.owners.get(j)))
  action init=s'={stage:ids.mapBy(i=>0),owners:ids.mapBy(i=>1),inputRoots:Set(),entries:Set(),
    committed:Set(),linked:Set(),heads:domains.mapBy(d=>(-1)),next:ids.mapBy(i=>(-1)),
    permits:Set(),initialized:Set(),dead:Set(),stopped:Set(),lost:Set(),nativeCalls:ids.mapBy(i=>0),
    frees:ids.mapBy(i=>0),credit:ids.mapBy(i=>0),bodyRev:ids.mapBy(i=>0),rootRev:0,
    phase:0,epoch:0,snapshot:Set(),frozenInputs:Set(),setup:Set(),marked:Set(),waiting:Set(),unseen:Set(),
    unknownNative:Set(),rawCount:0,unsafeCall:false}
  action splitInit=init.then(s'={...s,owners:ids.mapBy(i=>i)})
  action begin(i)=all{s.phase==0,s.stage.get(i)==0,
    s'={...s,stage:s.stage.set(i,1),inputRoots:s.inputRoots.union(Set(i)),credit:s.credit.set(i,1)}}
  action nativeSuccess(i)=all{s.stage.get(i)==1,not(s.permits.contains(i)),
    s'={...s,stage:s.stage.set(i,2),nativeCalls:s.nativeCalls.set(i,1)}}
  action nativeFailure(i)=all{s.phase<2,s.stage.get(i)==1,s'={...s,stage:s.stage.set(i,9),
    nativeCalls:s.nativeCalls.set(i,1),credit:s.credit.set(i,3),inputRoots:s.inputRoots.exclude(Set(i))}}
  // A stopped native call with unknown result cannot expose any managed private field.
  action nativeUnknown(i)=all{s.stage.get(i)==1,s'={...s,stage:s.stage.set(i,10),
    nativeCalls:s.nativeCalls.set(i,1),credit:s.credit.set(i,4),unknownNative:s.unknownNative.union(Set(i))}}
  action grant(i)=all{s.phase==0,s.stage.get(i)==2,writer(i),
    s.permits.forall(j=>s.owners.get(j)!=s.owners.get(i)),
    s'={...s,stage:s.stage.set(i,3),permits:s.permits.union(Set(i))}}
  action fillBody(i)=all{s.stage.get(i)==3,writer(i),s'={...s,stage:s.stage.set(i,4),
    initialized:s.initialized.union(Set(i)),bodyRev:s.bodyRev.set(i,s.rootRev)}}
  action link(i)=all{s.stage.get(i)==4,writer(i),
    s'={...s,stage:s.stage.set(i,5),next:s.next.set(i,s.heads.get(s.owners.get(i))),
      heads:s.heads.set(s.owners.get(i),i),linked:s.linked.union(Set(i))}}
  action installRoot(i)=all{s.stage.get(i)==5,writer(i),
    s'={...s,stage:s.stage.set(i,6),entries:s.entries.union(Set(i))}}
  action commit(i)=all{s.stage.get(i)==6,writer(i),s'={...s,stage:s.stage.set(i,7),
    committed:s.committed.union(Set(i)),credit:s.credit.set(i,2)}}
  action releasePermit(i)=all{s.stage.get(i)==7,writer(i),s'={...s,stage:s.stage.set(i,8),
    permits:s.permits.exclude(Set(i)),inputRoots:s.inputRoots.exclude(Set(i))}}
  action rollbackPrivate(i)=all{s.phase<2,s.stage.get(i)==2,not(s.dead.contains(i)),
    s'={...s,stage:s.stage.set(i,9),frees:s.frees.set(i,1),credit:s.credit.set(i,3),inputRoots:s.inputRoots.exclude(Set(i))}}
  action rollbackUnknown(i)=all{s.stage.get(i)==2,not(s.dead.contains(i)),
    s'={...s,stage:s.stage.set(i,10),credit:s.credit.set(i,4),unknownNative:s.unknownNative.union(Set(i))}}
  action stopKnown(i)=all{s.permits.contains(i),s'={...s,dead:s.dead.union(Set(i)),stopped:s.stopped.union(Set(i))}}
  action stopUnknown(i)=all{s.permits.contains(i),s'={...s,dead:s.dead.union(Set(i))}}
  // External stop certificate is a premise, not derived from timeouts.
  action certifyStop(i)=all{s.dead.contains(i),s'={...s,stopped:s.stopped.union(Set(i))}}
  action loseReply(i)=all{s.committed.contains(i),s'={...s,lost:s.lost.union(Set(i))}}
  action query(i)=all{s.lost.contains(i),s'={...s,lost:s.lost.exclude(Set(i))}}
  action requestFreeze=all{s.phase==0,s.epoch<2,s'={...s,phase:1,marked:Set()}}
  action freeze=all{s.phase==1,s.permits==Set(),s'={...s,phase:2,snapshot:s.committed,frozenInputs:s.inputRoots,setup:Set()}}
  action setupDomain(d)=all{s.phase==2,not(s.setup.contains(d)),s'={...s,setup:s.setup.union(Set(d))}}
  action mark(i)=all{s.phase==2,allSetup,s.snapshot.contains(i),
    s'={...s,marked:s.marked.union(Set(i))}}
  action finishStrong=all{s.phase==2,allSetup,s.marked==s.snapshot,
    s'={...s,phase:3,rootRev:s.rootRev+1,bodyRev:ids.mapBy(i=>if(s.initialized.contains(i)) s.rootRev+1 else s.bodyRev.get(i))}}
  action resume=all{s.phase==3,s'={...s,phase:0,epoch:s.epoch+1}}
  action stutter=s'=s
  action step={nondet i=ids.oneOf();nondet d=domains.oneOf();any{
    begin(i),nativeSuccess(i),nativeFailure(i),nativeUnknown(i),grant(i),fillBody(i),link(i),
    installRoot(i),commit(i),releasePermit(i),rollbackPrivate(i),rollbackUnknown(i),
    stopKnown(i),stopUnknown(i),certifyStop(i),loseReply(i),query(i),mark(i),
    requestFreeze,freeze,setupDomain(d),finishStrong,resume,stutter}}
  action prepare(i)=begin(i).then(nativeSuccess(i))
  action publish(i)=grant(i).then(fillBody(i)).then(link(i)).then(installRoot(i)).then(commit(i)).then(releasePermit(i))
  action gc=requestFreeze.then(freeze).then(setupDomain(0)).then(setupDomain(1))
  action emptyGc=gc.then(finishStrong).then(resume)
  action badFreeze=all{s.phase==1,s'={...s,phase:2,snapshot:s.committed,frozenInputs:s.inputRoots,setup:Set()}}
  action badGrant(i)=all{s.phase==1,s.stage.get(i)==2,s'={...s,stage:s.stage.set(i,3),permits:s.permits.union(Set(i)),unseen:s.unseen.union(Set(i))}}
  action badWait(i)=all{s.permits.contains(i),s'={...s,waiting:s.waiting.union(Set(i))}}
  action badStaleBody(i)=all{s.stage.get(i)==3,s'={...s,stage:s.stage.set(i,4),initialized:s.initialized.union(Set(i)),bodyRev:s.bodyRev.set(i,0)}}
  action badReset=all{s.marked!=Set(),s'={...s,setup:Set(0)}}
  action badLosePermit(i)=all{s.stage.get(i)==5,s'={...s,permits:s.permits.exclude(Set(i))}}
  action badFreeLinked(i)=all{s.linked.contains(i),s'={...s,frees:s.frees.set(i,1)}}
  action badRefundUnknown(i)=all{s.unknownNative.contains(i),s'={...s,credit:s.credit.set(i,3)}}
  action badDropUnknownRoot(i)=all{s.unknownNative.contains(i),s'={...s,inputRoots:s.inputRoots.exclude(Set(i))}}
  action badReplayMalloc(i)=all{s.nativeCalls.get(i)==1,s'={...s,nativeCalls:s.nativeCalls.set(i,2)}}
  action badMarkEarly(i)=all{s.phase==2,s.snapshot.contains(i),s'={...s,marked:s.marked.union(Set(i))}}
  action badReleaseBeforeCommit(i)=all{s.stage.get(i)==6,s'={...s,stage:s.stage.set(i,8),permits:s.permits.exclude(Set(i))}}
  action badSameDomainGrant(i)=all{s.stage.get(i)==2,s'={...s,stage:s.stage.set(i,3),permits:s.permits.union(Set(i))}}
  action badDropFrozenInput(i)=all{s.phase==2,s.frozenInputs.contains(i),s'={...s,inputRoots:s.inputRoots.exclude(Set(i))}}
  action badNativeUnderPermit=s'={...s,unsafeCall:true}
  // unseen captures the rule that Closing forbids new publisher admission.
  val admitted=safe and s.unseen==Set()
  run processorOnePublishTest=init.then(prepare(0)).then(publish(0)).then(all{assert(s.owners.get(0)==1 and admitted),s'=s})
  run sameDomainSerializedTest=init.then(prepare(0)).then(prepare(1)).then(publish(0)).then(publish(1)).then(all{assert(chain(1)==ids and admitted),s'=s})
  run splitDomainsParallelTest=splitInit.then(prepare(0)).then(prepare(1)).then(grant(0)).then(grant(1)).then(fillBody(0)).then(fillBody(1)).then(link(1)).then(link(0)).then(installRoot(0)).then(installRoot(1)).then(commit(0)).then(commit(1)).then(releasePermit(1)).then(releasePermit(0)).then(all{assert(admitted),s'=s})
  run closingDrainsPublisherTest=init.then(prepare(0)).then(grant(0)).then(fillBody(0)).then(requestFreeze).then(link(0)).then(installRoot(0)).then(commit(0)).then(releasePermit(0)).then(freeze).then(all{assert(s.snapshot==Set(0) and admitted),s'=s})
  run rawPrivateSurvivesGcTest=init.then(prepare(0)).then(emptyGc).then(publish(0)).then(all{assert(s.bodyRev.get(0)==1 and admitted),s'=s})
  run knownMallocFailureTest=init.then(begin(0)).then(nativeFailure(0)).then(all{assert(s.credit.get(0)==3 and admitted),s'=s})
  run unknownMallocGcTest=init.then(begin(0)).then(nativeUnknown(0)).then(emptyGc).then(all{assert(s.inputRoots.contains(0) and admitted),s'=s})
  run knownPrivateRollbackTest=init.then(prepare(0)).then(rollbackPrivate(0)).then(all{assert(s.frees.get(0)==1 and admitted),s'=s})
  run unknownFreeGcTest=init.then(prepare(0)).then(rollbackUnknown(0)).then(emptyGc).then(all{assert(s.credit.get(0)==4 and admitted),s'=s})
  run helperRollForwardTest=init.then(prepare(0)).then(grant(0)).then(fillBody(0)).then(link(0)).then(stopKnown(0)).then(installRoot(0)).then(commit(0)).then(releasePermit(0)).then(all{assert(s.committed.contains(0) and admitted),s'=s})
  run unknownStopRetainsPermitTest=init.then(prepare(0)).then(grant(0)).then(stopUnknown(0)).then(requestFreeze).then(all{assert(s.phase==1 and s.permits==Set(0) and admitted),s'=s})
  run laterStopCertificateTest=init.then(prepare(0)).then(grant(0)).then(stopUnknown(0)).then(certifyStop(0)).then(fillBody(0)).then(link(0)).then(installRoot(0)).then(commit(0)).then(releasePermit(0)).then(all{assert(admitted),s'=s})
  run lostReplyQueryTest=init.then(prepare(0)).then(publish(0)).then(loseReply(0)).then(query(0)).then(all{assert(s.nativeCalls.get(0)==1 and admitted),s'=s})
  run processorOneTraceTest=init.then(prepare(0)).then(publish(0)).then(gc).then(mark(0)).then(finishStrong).then(resume).then(all{assert(s.bodyRev.get(0)==s.rootRev and admitted),s'=s})
  run freezeBeforeAdmissionTest=init.then(prepare(0)).then(emptyGc).then(publish(0)).then(all{assert(s.epoch==1 and admitted),s'=s})
  run secondRoundTraceTest=init.then(prepare(0)).then(publish(0)).then(gc).then(mark(0)).then(finishStrong).then(resume).then(gc).then(mark(0)).then(finishStrong).then(resume).then(all{assert(admitted),s'=s})
  run partialRootNotObservableTest=init.then(prepare(0)).then(grant(0)).then(fillBody(0)).then(link(0)).then(installRoot(0)).then(all{assert(s.permits==Set(0) and s.committed==Set() and admitted),s'=s})
  run partialFreezeCounterexampleTest=init.then(prepare(0)).then(grant(0)).then(fillBody(0)).then(link(0)).then(requestFreeze).then(badFreeze).then(all{assert(not(admitted)),s'=s})
  run closingAdmissionCounterexampleTest=init.then(prepare(0)).then(requestFreeze).then(badGrant(0)).then(all{assert(not(admitted)),s'=s})
  run gcWaitCycleCounterexampleTest=init.then(prepare(0)).then(grant(0)).then(badWait(0)).then(all{assert(not(admitted)),s'=s})
  run staleProcedureCounterexampleTest=init.then(prepare(0)).then(emptyGc).then(grant(0)).then(badStaleBody(0)).then(all{assert(not(admitted)),s'=s})
  run lateSetupCounterexampleTest=init.then(prepare(0)).then(publish(0)).then(gc).then(mark(0)).then(badReset).then(all{assert(not(admitted)),s'=s})
  run lostLinkedCustodyCounterexampleTest=init.then(prepare(0)).then(grant(0)).then(fillBody(0)).then(link(0)).then(badLosePermit(0)).then(all{assert(not(admitted)),s'=s})
  run freeLinkedCounterexampleTest=init.then(prepare(0)).then(publish(0)).then(badFreeLinked(0)).then(all{assert(not(admitted)),s'=s})
  run refundUnknownCounterexampleTest=init.then(begin(0)).then(nativeUnknown(0)).then(badRefundUnknown(0)).then(all{assert(not(admitted)),s'=s})
  run dropUnknownRootCounterexampleTest=init.then(begin(0)).then(nativeUnknown(0)).then(badDropUnknownRoot(0)).then(all{assert(not(admitted)),s'=s})
  run replayMallocCounterexampleTest=init.then(begin(0)).then(nativeUnknown(0)).then(badReplayMalloc(0)).then(all{assert(not(admitted)),s'=s})
  run earlyRootMarkCounterexampleTest=init.then(prepare(0)).then(publish(0)).then(requestFreeze).then(freeze).then(setupDomain(0)).then(badMarkEarly(0)).then(all{assert(not(admitted)),s'=s})
  run earlyExposeCounterexampleTest=init.then(prepare(0)).then(grant(0)).then(fillBody(0)).then(link(0)).then(installRoot(0)).then(badReleaseBeforeCommit(0)).then(all{assert(not(admitted)),s'=s})
  run domainLostUpdateCounterexampleTest=init.then(prepare(0)).then(prepare(1)).then(grant(0)).then(badSameDomainGrant(1)).then(all{assert(not(admitted)),s'=s})
  run nativeCallInPermitCounterexampleTest=init.then(prepare(0)).then(grant(0)).then(badNativeUnderPermit).then(all{assert(not(admitted)),s'=s})
  run frozenInputWithdrawalCounterexampleTest=init.then(prepare(0)).then(gc).then(badDropFrozenInput(0)).then(all{assert(not(admitted)),s'=s})
  action negativeInit=init.then(prepare(0)).then(grant(0)).then(fillBody(0)).then(link(0)).then(requestFreeze)
  action negativeStep=badFreeze
}
