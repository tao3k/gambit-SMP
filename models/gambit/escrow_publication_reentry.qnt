module escrow_publication_reentry {
  // Two invocation identities, one owner, two callback depths, one scan lease.
  // gate0 owner-active;1 closed;2 view published;3 scan claimed;4 scanned;5 seal.
  // slot0 empty;1 native captured;2 wrapping;3 rooted/ownership committed.
  type State={gate:int,epoch:int,generation:int,viewEpoch:int,viewGen:int,traceEpoch:int,
    active:Set[int],rooted:Set[int],protected:Set[int],tickets:Set[int],
    view:Set[int],scanPin:bool,readerPins:Set[int],top:int,
    marker:int->int,slot:int->int,body:int->int,rootValue:int->int,cache:int->int,
    owner:int->int,commits:int->int,delivered:Set[int],resultRoots:Set[int],
    initActive:Set[int],initParked:Set[int],shellSafe:Set[int],
    stopKnown:bool,metadataKnown:bool,resultLost:Set[int],disposed:Set[int],
    permit:bool,reloaded:bool,nativeOnly:Set[int],borrowers:Set[int],invocationGen:int->int,nativeAlive:Set[int]}
  var s:State
  val ids=Set(0,1)
  val canClose=s.initActive.size()==0 and s.metadataKnown and s.stopKnown
  val canSeal=s.gate==4 and not(s.scanPin) and s.viewEpoch==s.epoch and
    s.viewGen==s.generation and s.traceEpoch==s.epoch and s.view==s.active and s.view.subseteq(s.rooted)
  val safe=(s.gate<2 or (s.view==s.active and s.view.subseteq(s.rooted))) and
    (s.gate!=5 or canSealAfterPublish) and
    ids.forall(i=>s.commits.get(i)<=1) and
    s.active.subseteq(s.tickets) and s.initParked.subseteq(s.shellSafe) and s.initParked.forall(i=>s.owner.get(i)==0) and
    ids.forall(i=>s.slot.get(i)==0 or s.disposed.contains(i) or s.nativeAlive.contains(i)) and
    (s.gate==0 or s.initActive.size()==0) and
    s.delivered.subseteq(s.resultRoots) and
    s.delivered.forall(i=>s.slot.get(i)==3 and (s.owner.get(i)==1 or (s.owner.get(i)==2 and s.disposed.contains(i)))) and
    ids.forall(i=>s.slot.get(i)!=3 or (s.resultRoots.contains(i) and (s.owner.get(i)==1 or (s.owner.get(i)==2 and s.disposed.contains(i))))) and
    s.active.forall(i=>s.protected.contains(i)) and
    (not(s.reloaded) or s.active.forall(i=>s.cache.get(i)==s.rootValue.get(i))) and
    s.initActive.forall(i=>s.owner.get(i)==0 and s.slot.get(i)==2)
  val canSealAfterPublish=not(s.scanPin) and s.viewEpoch==s.epoch and
    s.viewGen==s.generation and s.traceEpoch==s.epoch and s.view==s.active and s.view.subseteq(s.rooted)
  action init=s'={gate:0,epoch:0,generation:1,viewEpoch:0,viewGen:0,traceEpoch:0,
    active:Set(0),rooted:Set(0),protected:Set(0),tickets:Set(0),view:Set(),
    scanPin:false,readerPins:Set(),top:0,marker:Map(0->2,1->0),slot:Map(0->0,1->0),
    body:Map(0->0,1->0),rootValue:Map(0->1,1->1),cache:Map(0->1,1->1),
    owner:Map(0->0,1->0),commits:Map(0->0,1->0),delivered:Set(),resultRoots:Set(),
    initActive:Set(),initParked:Set(),shellSafe:Set(),stopKnown:true,
    metadataKnown:true,resultLost:Set(),disposed:Set(),permit:true,reloaded:true,
    nativeOnly:Set(0,1),borrowers:Set(),invocationGen:Map(0->1,1->1),nativeAlive:Set()}
  action protectChild=all{s.gate==0,s.top==0,s'={...s,protected:s.protected.union(Set(1))}}
  action admitChild=all{s.gate==0,s.top==0,s.protected.contains(1),not(s.active.contains(1)),s.marker.get(1)==0,
    s'={...s,active:s.active.union(Set(1)),rooted:s.rooted.union(Set(1)),
      tickets:s.tickets.union(Set(1)),marker:s.marker.set(1,1),cache:s.cache.set(1,s.rootValue.get(1)),top:1}}
  action markerReady=all{s.gate==0,s.top==1,s.marker.get(1)==1,s'={...s,marker:s.marker.set(1,2)}}
  action close=all{s.gate==0,canClose,s'={...s,gate:1,epoch:s.epoch+1,permit:false,reloaded:false}}
  action publishView=all{s.gate==1,canClose,s.active.subseteq(s.rooted),
    s'={...s,gate:2,view:s.active,viewEpoch:s.epoch,viewGen:s.generation}}
  action claimScan=all{s.gate==2,s'={...s,gate:3,scanPin:true}}
  // Descriptor locations are fixed; only the collector updates values here.
  action finishScan=all{s.gate==3,s.scanPin,s'={...s,gate:4,traceEpoch:s.epoch,
    rootValue:s.rootValue.set(0,s.rootValue.get(0)+1).set(1,s.rootValue.get(1)+1)}}
  action drainScan=all{s.gate==4,s.scanPin,s'={...s,scanPin:false}}
  action seal=all{canSeal,s'={...s,gate:5}}
  action reenter=all{s.gate==5,canSealAfterPublish,s.metadataKnown,s.stopKnown,
    s'={...s,gate:0,permit:true,cache:s.rootValue,reloaded:true}}
  // Late native result stores change no root descriptor or managed value.
  def canArrive(i,g)=s.active.contains(i) and s.nativeOnly.contains(i) and s.slot.get(i)==0 and s.invocationGen.get(i)==g
  action nativeResult(i,g)=all{canArrive(i,g),
    s'={...s,slot:s.slot.set(i,1),nativeAlive:s.nativeAlive.union(Set(i))}}
  action beginShell(i)=all{s.gate==0,s.permit,s.reloaded,s.top==i,s.slot.get(i)==1,
    s'={...s,slot:s.slot.set(i,2),body:s.body.set(i,1),initActive:s.initActive.union(Set(i)),shellSafe:s.shellSafe.union(Set(i))}}
  action fillBody(i)=all{s.gate==0,s.initActive.contains(i),s.body.get(i)==1,
    s'={...s,body:s.body.set(i,2)}}
  action rootResult(i)=all{s.gate==0,s.initActive.contains(i),s.body.get(i)==2,
    s'={...s,body:s.body.set(i,3),resultRoots:s.resultRoots.union(Set(i))}}
  action commit(i)=all{s.gate==0,s.initActive.contains(i),s.body.get(i)==3,
    s.owner.get(i)==0,s.resultRoots.contains(i),s.commits.get(i)==0,
    s'={...s,owner:s.owner.set(i,1),slot:s.slot.set(i,3),commits:s.commits.set(i,1),initActive:s.initActive.exclude(Set(i))}}
  action parkInit(i)=all{s.gate==0,s.initActive.contains(i),s.shellSafe.contains(i),s.stopKnown,
    s'={...s,initActive:s.initActive.exclude(Set(i)),initParked:s.initParked.union(Set(i))}}
  action resumeInit(i)=all{s.gate==0,s.permit,s.reloaded,s.top==i,s.initParked.contains(i),
    s'={...s,initParked:s.initParked.exclude(Set(i)),initActive:s.initActive.union(Set(i))}}
  action loseNotice(i)=all{s.slot.get(i)==3,s'={...s,resultLost:s.resultLost.union(Set(i))}}
  action query(i)=all{s.active.contains(i),s'={...s,resultLost:s.resultLost.exclude(Set(i))}}
  action deliver(i)=all{s.gate==0,s.permit,s.reloaded,s.top==i,s.marker.get(i)==2,
    s.slot.get(i)==3,not(s.delivered.contains(i)),s'={...s,delivered:s.delivered.union(Set(i))}}
  action exitChild=all{s.gate==0,s.top==1,s.delivered.contains(1),
    s.initActive.size()==0,s.initParked.size()==0,
    s'={...s,marker:s.marker.set(1,3),top:0}}
  action pinResult(i)=all{s.active.contains(i),s'={...s,readerPins:s.readerPins.union(Set(i))}}
  action unpinResult(i)=all{s.readerPins.contains(i),s'={...s,readerPins:s.readerPins.exclude(Set(i))}}
  action borrowNative(i)=all{s.active.contains(i),s.nativeAlive.contains(i),not(s.disposed.contains(i)),s'={...s,borrowers:s.borrowers.union(Set(i))}}
  action dropBorrow(i)=all{s.borrowers.contains(i),s'={...s,borrowers:s.borrowers.exclude(Set(i))}}
  // Disposal itself is abstract and separately qualified; this model checks reclamation gates.
  def canDispose(i)=s.delivered.contains(i) and not(s.borrowers.contains(i)) and not(s.disposed.contains(i))
  action knownDisposal(i)=all{canDispose(i),s'={...s,disposed:s.disposed.union(Set(i)),nativeAlive:s.nativeAlive.exclude(Set(i))}}
  action retireChild=all{s.gate==0,s.top==0,s.marker.get(1)==3,s.disposed.contains(1),
    not(s.scanPin),not(s.readerPins.contains(1)),not(s.borrowers.contains(1)),
    s'={...s,active:s.active.exclude(Set(1)),rooted:s.rooted.exclude(Set(1)),tickets:s.tickets.exclude(Set(1)),owner:s.owner.set(1,2)}}
  action staleGeneration=all{s.gate==2 or s.gate==4,s'={...s,generation:s.generation+1}}
  action unknownStop=all{s.gate==0,s'={...s,stopKnown:false}}
  action stutter=s'=s
  action step={nondet i=ids.oneOf();any{protectChild,admitChild,markerReady,close,
    publishView,claimScan,finishScan,drainScan,seal,reenter,nativeResult(i,s.invocationGen.get(i)),beginShell(i),
    fillBody(i),rootResult(i),commit(i),parkInit(i),resumeInit(i),loseNotice(i),query(i),
    deliver(i),exitChild,pinResult(i),unpinResult(i),borrowNative(i),dropBorrow(i),
    knownDisposal(i),retireChild,staleGeneration,unknownStop,stutter}}
  action cycle=close.then(publishView).then(claimScan).then(finishScan).then(drainScan).then(seal).then(reenter)
  action build(i)=nativeResult(i,s.invocationGen.get(i)).then(beginShell(i)).then(fillBody(i)).then(rootResult(i)).then(commit(i))
  action child=protectChild.then(admitChild).then(markerReady)
  action unsafeChild=s'={...s,active:s.active.union(Set(1)),rooted:s.rooted.union(Set(1)),tickets:s.tickets.union(Set(1)),top:1}
  action unsafeLateChild=s'={...s,active:s.active.union(Set(1)),tickets:s.tickets.union(Set(1)),top:1}
  action unsafeCommit=s'={...s,slot:s.slot.set(0,3),owner:s.owner.set(0,1),commits:s.commits.set(0,1)}
  action unsafeDuplicate=s'={...s,commits:s.commits.set(0,2)}
  action unsafeThaw=s'={...s,gate:0,permit:true,reloaded:true}
  action unsafeSeal=s'={...s,gate:5}
  action unsafeResultRootDrop=s'={...s,resultRoots:s.resultRoots.exclude(Set(0))}
  action unsafeTicketDrop=s'={...s,tickets:s.tickets.exclude(Set(0))}
  action unsafeLegacyRelease=s'={...s,nativeAlive:s.nativeAlive.exclude(Set(0))}
  action unsafeCloseDuringInit=s'={...s,gate:1}
  run frozenDescriptorAllowsRelocationTest=init.then(close).then(publishView).then(claimScan).then(finishScan).expect(safe and s.rootValue.get(0)==2 and s.view==Set(0))
  run scannerPinBlocksSealTest=init.then(close).then(publishView).then(claimScan).then(finishScan).expect(safe and not(canSeal))
  run reentryReloadsRelocatedRootsTest=init.then(cycle).expect(safe and s.cache.get(0)==2 and s.permit)
  run nativeLateDuringScanTest=init.then(close).then(publishView).then(claimScan).then(nativeResult(0,1)).then(finishScan).then(drainScan).then(seal).expect(safe and s.slot.get(0)==1)
  run nativeLateAfterSealTest=init.then(close).then(publishView).then(claimScan).then(finishScan).then(drainScan).then(seal).then(nativeResult(0,1)).then(reenter).expect(safe and s.slot.get(0)==1)
  run nestedProtectBeforeMarkerAllocationTest=init.then(protectChild).then(admitChild).then(cycle).then(markerReady).expect(safe and s.top==1)
  run nestedTwoFrameViewTest=init.then(child).then(close).then(publishView).expect(safe and s.view==Set(0,1))
  run parentLateResultDoesNotOverwriteChildTest=init.then(child).then(nativeResult(0,1)).then(build(1)).expect(safe and s.slot.get(0)==1 and s.slot.get(1)==3)
  run rootedCommitThenDeliveryTest=init.then(build(0)).then(deliver(0)).expect(safe and s.owner.get(0)==1 and s.commits.get(0)==1)
  run lostCommitNoticeQueriesCanonicalSlotTest=init.then(build(0)).then(loseNotice(0)).then(query(0)).then(query(0)).then(deliver(0)).expect(safe and s.commits.get(0)==1)
  run partialShellParkAndGcTest=init.then(nativeResult(0,1)).then(beginShell(0)).then(parkInit(0)).then(cycle).expect(safe and s.body.get(0)==1 and s.owner.get(0)==0)
  run partialInitContinuesOnceTest=init.then(nativeResult(0,1)).then(beginShell(0)).then(parkInit(0)).then(cycle).then(resumeInit(0)).then(fillBody(0)).then(rootResult(0)).then(commit(0)).then(deliver(0)).expect(safe and s.commits.get(0)==1)
  run initializedUncommittedCanParkTest=init.then(nativeResult(0,1)).then(beginShell(0)).then(fillBody(0)).then(rootResult(0)).then(parkInit(0)).then(cycle).then(resumeInit(0)).then(commit(0)).expect(safe and s.slot.get(0)==3)
  run nestedChildThenParentReturnTest=init.then(child).then(build(1)).then(deliver(1)).then(exitChild).then(build(0)).then(deliver(0)).expect(safe and s.top==0 and s.delivered==Set(0,1))
  run childReadersRetainTicketTest=init.then(child).then(build(1)).then(deliver(1)).then(exitChild).then(knownDisposal(1)).then(pinResult(1)).expect(safe and s.tickets.contains(1))
  run childBorrowRetainsNativeBackingTest=init.then(child).then(build(1)).then(deliver(1)).then(exitChild).then(borrowNative(1)).expect(safe and s.tickets.contains(1) and not(canDispose(1)))
  run childDrainThenRetirementTest=init.then(child).then(build(1)).then(deliver(1)).then(exitChild).then(knownDisposal(1)).then(pinResult(1)).then(unpinResult(1)).then(retireChild).expect(safe and not(s.tickets.contains(1)))
  run staleViewCannotSealTest=init.then(close).then(publishView).then(claimScan).then(finishScan).then(drainScan).then(staleGeneration).expect(safe and not(canSeal))
  run resultReceiptReaderDoesNotPinGcViewTest=init.then(pinResult(0)).then(cycle).expect(safe and s.permit and s.readerPins.contains(0))
  run staleInvocationResultRejectedTest=init.expect(safe and not(canArrive(0,0)))
  run childAfterParentGcReloadsOwnRootsTest=init.then(cycle).then(child).expect(safe and s.cache.get(1)==s.rootValue.get(1))
  run nativeBorrowDrainsBeforeDisposalTest=init.then(child).then(build(1)).then(deliver(1)).then(exitChild).then(borrowNative(1)).then(dropBorrow(1)).then(knownDisposal(1)).then(retireChild).expect(safe and not(s.nativeAlive.contains(1)))
  run legacyFinalizerBeforeHandoffCounterexampleTest=init.then(nativeResult(0,1)).then(beginShell(0)).then(parkInit(0)).then(unsafeLegacyRelease).expect(not(safe))
  run unknownStopRetainsDutyTest=init.then(unknownStop).expect(safe and not(canClose) and s.tickets.contains(0))
  run unprotectedCallbackCounterexampleTest=init.then(unsafeChild).expect(not(safe))
  run lateCallbackAfterViewCounterexampleTest=init.then(close).then(publishView).then(unsafeLateChild).expect(not(safe))
  run commitWithoutRootCounterexampleTest=init.then(unsafeCommit).expect(not(safe))
  run duplicateCommitCounterexampleTest=init.then(build(0)).then(unsafeDuplicate).expect(not(safe))
  run reentryWithoutReloadCounterexampleTest=init.then(close).then(publishView).then(claimScan).then(finishScan).then(drainScan).then(seal).then(unsafeThaw).expect(not(safe))
  run sealBeforeScanCounterexampleTest=init.then(close).then(publishView).then(unsafeSeal).expect(not(safe))
  run deliveredRootRetiredEarlyCounterexampleTest=init.then(build(0)).then(deliver(0)).then(unsafeResultRootDrop).expect(not(safe))
  run ticketDropBeforeHandoffCounterexampleTest=init.then(unsafeTicketDrop).expect(not(safe))
  run initWriterCrossesGcCounterexampleTest=init.then(nativeResult(0,1)).then(beginShell(0)).then(unsafeCloseDuringInit).expect(not(safe))
}
