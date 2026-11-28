module foreign_shell_unwind {
  // One abstract GC at a time; two nested invocations. Shell bytes and native
  // calls are not executed. Known-stop and safe-layout facts are premises.
  type State = {reserved:Set[int], procRoots:Set[int], procValue:int->int,
    cache:int->int, marker:int->int, top:int, shell:int->int, linked:Set[int],
    initOwner:int->int, stopped:Set[int], rootResult:Set[int], native:Set[int],
    control:int->int, commits:int->int, abort:Set[int], escaped:Set[int],
    observed:Set[int], delivered:Set[int], ticket:Set[int], scan:bool,
    disposed:Set[int], readers:Set[int], borrowers:Set[int], finalizerGuard:bool}
  // shell 0 absent,1 private backing,2 safe defaults,3 list admitted,4 complete.
  // control 0 escrow,1 wrapper,2 known disposed. initOwner 0 none,1 owner,2 service.
  var s:State
  val ids=Set(0,1)
  def canCommit(i)=not(s.scan) and s.top==i and s.shell.get(i)==4 and
    s.initOwner.get(i)==1 and s.control.get(i)==0 and s.rootResult.contains(i) and
    not(s.abort.contains(i)) and s.commits.get(i)==0
  def canEnter(i)=not(s.scan) and s.reserved.contains(i) and s.procRoots.contains(i)
  def canSettle(i)=s.top==i and s.abort.contains(i) and
    (s.initOwner.get(i)!=1 or s.stopped.contains(i)) and not(s.scan)
  def canDispose(i)=s.native.contains(i) and s.escaped.contains(i) and s.stopped.contains(i) and
    not(s.borrowers.contains(i)) and not(s.readers.contains(i)) and
    s.control.get(i)<2
  val safe=s.linked.forall(i=>s.shell.get(i)>=2 and s.ticket.contains(i)) and
    ids.forall(i=>s.commits.get(i)<=1) and
    ids.forall(i=>s.control.get(i)!=1 or (s.shell.get(i)==4 and s.rootResult.contains(i))) and
    s.native.forall(i=>s.ticket.contains(i) and s.control.get(i)<2) and
    s.escaped.forall(i=>s.marker.get(i)!=2 and s.initOwner.get(i)!=1) and
    s.delivered.forall(i=>s.commits.get(i)==1 and s.rootResult.contains(i)) and
    ids.forall(i=>s.marker.get(i)!=2 or (s.procRoots.contains(i) and s.reserved.contains(i))) and
    (not(s.scan) or ids.forall(i=>s.initOwner.get(i)!=1)) and
    s.disposed.intersect(s.native)==Set() and
    s.disposed.intersect(s.borrowers)==Set() and s.finalizerGuard
  action init=s'={reserved:Set(),procRoots:Set(),procValue:Map(0->1,1->1),cache:Map(0->0,1->0),
    marker:Map(0->0,1->0),top:0,shell:Map(0->0,1->0),linked:Set(),initOwner:Map(0->0,1->0),
    stopped:Set(),rootResult:Set(),native:Set(),control:Map(0->0,1->0),commits:Map(0->0,1->0),
    abort:Set(),escaped:Set(),observed:Set(),delivered:Set(),ticket:Set(),scan:false,
    disposed:Set(),readers:Set(),borrowers:Set(),finalizerGuard:true}
  action reserve(i)=all{not(s.scan),not(s.reserved.contains(i)),
    s'={...s,reserved:s.reserved.union(Set(i)),ticket:s.ticket.union(Set(i))}}
  action protect(i)=all{not(s.scan),s.reserved.contains(i),
    s'={...s,procRoots:s.procRoots.union(Set(i)),cache:s.cache.set(i,s.procValue.get(i))}}
  // Allocating the marker may collect and relocate the procedure before copy.
  action allocateMarker(i)=all{canEnter(i),s.marker.get(i)==0,ids.forall(k=>s.initOwner.get(k)!=1),
    i==0 or (i==1 and s.top==0 and s.marker.get(0)==2),
    s'={...s,top:i,marker:s.marker.set(i,1),
      procValue:s.procValue.set(0,s.procValue.get(0)+1).set(1,s.procValue.get(1)+1)}}
  action publishMarker(i)=all{not(s.scan),s.top==i,s.marker.get(i)==1,s.procRoots.contains(i),
    s'={...s,marker:s.marker.set(i,2),cache:s.cache.set(i,s.procValue.get(i))}}
  action captureNative(i)=all{not(s.scan),s.top==i,s.marker.get(i)==2,
    not(s.native.contains(i)),s.control.get(i)==0,not(s.abort.contains(i)),
    s'={...s,native:s.native.union(Set(i))}}
  action allocatePrivate(i)=all{not(s.scan),s.top==i,s.native.contains(i),s.shell.get(i)==0,
    not(s.abort.contains(i)),s'={...s,shell:s.shell.set(i,1),initOwner:s.initOwner.set(i,1)}}
  action defaults(i)=all{not(s.scan),s.initOwner.get(i)==1,s.shell.get(i)==1,
    not(s.abort.contains(i)),s'={...s,shell:s.shell.set(i,2)}}
  action admitShell(i)=all{not(s.scan),s.initOwner.get(i)==1,s.shell.get(i)==2,
    s.ticket.contains(i),s.finalizerGuard,not(s.abort.contains(i)),
    s'={...s,shell:s.shell.set(i,3),linked:s.linked.union(Set(i))}}
  action completeBody(i)=all{not(s.scan),s.initOwner.get(i)==1,s.shell.get(i)==3,
    not(s.abort.contains(i)),s'={...s,shell:s.shell.set(i,4)}}
  action root(i)=all{not(s.scan),s.initOwner.get(i)==1,s.shell.get(i)==4,
    not(s.abort.contains(i)),s'={...s,rootResult:s.rootResult.union(Set(i))}}
  // Exactly one authoritative state: readiness and release ownership project from it.
  action commit(i)=all{canCommit(i),s'={...s,control:s.control.set(i,1),
    commits:s.commits.set(i,1),initOwner:s.initOwner.set(i,0)}}
  action stop(i)=all{not(s.scan),s.top==i,s.initOwner.get(i)==1,
    s'={...s,stopped:s.stopped.union(Set(i)),initOwner:s.initOwner.set(i,2)}}
  action beginGc=all{not(s.scan),ids.forall(i=>s.initOwner.get(i)!=1),
    s.linked.forall(i=>s.shell.get(i)>=2),s'={...s,scan:true}}
  action endGc=all{s.scan,s'={...s,scan:false,
    procValue:s.procValue.set(0,s.procValue.get(0)+1).set(1,s.procValue.get(1)+1)}}
  // An exception request is not proof that all native or managed writers stopped.
  action exception(i)=all{not(s.scan),s.top==i,s.marker.get(i)>0,not(s.escaped.contains(i)),
    s'={...s,abort:s.abort.union(Set(i))}}
  action settleEscape(i)=all{canSettle(i),s'={...s,marker:s.marker.set(i,3),
    escaped:s.escaped.union(Set(i)),top:0}}
  action query(i)=all{s.commits.get(i)==1,s'={...s,observed:s.observed.union(Set(i))}}
  action deliver(i)=all{not(s.scan),s.top==i,s.marker.get(i)==2,s.control.get(i)==1,
    not(s.abort.contains(i)),s'={...s,delivered:s.delivered.union(Set(i))}}
  action pin(i)=all{s.native.contains(i),s'={...s,readers:s.readers.union(Set(i))}}
  action borrow(i)=all{s.native.contains(i),s'={...s,borrowers:s.borrowers.union(Set(i))}}
  action drain(i)=s'={...s,readers:s.readers.exclude(Set(i)),borrowers:s.borrowers.exclude(Set(i))}
  action knownStopAfterCommit(i)=all{s.control.get(i)==1,s'={...s,stopped:s.stopped.union(Set(i))}}
  action dispose(i)=all{canDispose(i),s'={...s,control:s.control.set(i,2),
    native:s.native.exclude(Set(i)),disposed:s.disposed.union(Set(i))}}
  action stutter=s'=s
  action step={nondet i=ids.oneOf();any{reserve(i),protect(i),allocateMarker(i),publishMarker(i),
    captureNative(i),allocatePrivate(i),defaults(i),admitShell(i),completeBody(i),root(i),
    commit(i),stop(i),beginGc,endGc,exception(i),settleEscape(i),query(i),deliver(i),
    pin(i),borrow(i),drain(i),knownStopAfterCommit(i),dispose(i),stutter}}
  action enter(i)=reserve(i).then(protect(i)).then(allocateMarker(i)).then(publishMarker(i))
  action prepare(i)=captureNative(i).then(allocatePrivate(i)).then(defaults(i)).then(admitShell(i)).then(completeBody(i)).then(root(i))
  action unsafePublish=s'={...s,linked:s.linked.union(Set(0))}
  action unsafeMarker=s'={...s,marker:s.marker.set(0,2)}
  action unsafeCommit=s'={...s,control:s.control.set(0,1),commits:s.commits.set(0,1)}
  action unsafeDuplicate=s'={...s,commits:s.commits.set(0,2)}
  action unsafeUnwind=s'={...s,escaped:s.escaped.union(Set(1)),top:0}
  action unsafeGc=s'={...s,scan:true}
  action unsafeTicketRefund=s'={...s,ticket:s.ticket.exclude(Set(0))}
  action unsafeDispose=s'={...s,disposed:s.disposed.union(Set(0)),native:s.native.exclude(Set(0)),control:s.control.set(0,2)}
  action unsafeLegacy=s'={...s,finalizerGuard:false}
  action badStep=any{step,unsafePublish}
  run markerAllocationFailureRetainsRootsTest=init.then(reserve(0)).then(protect(0)).then(allocateMarker(0)).then(exception(0)).then(settleEscape(0)).expect(safe and s.procRoots.contains(0) and s.ticket.contains(0))
  run wrapperAllocationFailureRetainsNativeTest=init.then(enter(0)).then(captureNative(0)).then(exception(0)).then(settleEscape(0)).expect(safe and s.native.contains(0) and s.shell.get(0)==0)
  run rootBeforeMarkerTest=init.then(enter(0)).expect(safe and s.cache.get(0)==s.procValue.get(0))
  run noRootRejectsMarkerTest=init.then(reserve(0)).expect(safe and not(canEnter(0)))
  run privateNotDiscoverableTest=init.then(enter(0)).then(captureNative(0)).then(allocatePrivate(0)).expect(safe and not(s.linked.contains(0)))
  run defaultsBeforeListTest=init.then(enter(0)).then(captureNative(0)).then(allocatePrivate(0)).then(defaults(0)).then(admitShell(0)).expect(safe and s.control.get(0)==0)
  run bodyAndRootBeforeCommitTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).expect(safe and s.control.get(0)==1)
  run queryDoesNotRepeatCommitTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).then(query(0)).then(query(0)).expect(safe and s.commits.get(0)==1)
  run privateStopAllowsCollectionTest=init.then(enter(0)).then(captureNative(0)).then(allocatePrivate(0)).then(stop(0)).then(beginGc).then(endGc).expect(safe and not(s.linked.contains(0)))
  run linkedStopAllowsCollectionTest=init.then(enter(0)).then(prepare(0)).then(stop(0)).then(beginGc).then(endGc).expect(safe and s.control.get(0)==0)
  run exceptionIsNotStopTest=init.then(enter(0)).then(prepare(0)).then(exception(0)).expect(safe and not(canSettle(0)) and s.ticket.contains(0))
  run stopThenEscapeRetainsEscrowTest=init.then(enter(0)).then(prepare(0)).then(exception(0)).then(stop(0)).then(settleEscape(0)).expect(safe and s.control.get(0)==0 and s.native.contains(0))
  run postCommitEscapeRetainsWrapperTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).then(exception(0)).then(settleEscape(0)).then(query(0)).expect(safe and s.control.get(0)==1)
  run childEscapeLeavesParentLiveTest=init.then(enter(0)).then(enter(1)).then(prepare(1)).then(exception(1)).then(stop(1)).then(settleEscape(1)).expect(safe and s.marker.get(0)==2 and s.marker.get(1)==3)
  run childCommitExceptionDoesNotWriteParentTest=init.then(enter(0)).then(enter(1)).then(prepare(1)).then(commit(1)).then(exception(1)).then(settleEscape(1)).expect(safe and s.commits.get(0)==0 and s.commits.get(1)==1)
  run nestedMarkerReloadTest=init.then(enter(0)).then(enter(1)).expect(safe and s.cache.get(1)==s.procValue.get(1) and s.procRoots==Set(0,1))
  run borrowPreventsDisposeTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).then(borrow(0)).then(exception(0)).then(settleEscape(0)).then(knownStopAfterCommit(0)).expect(safe and not(canDispose(0)))
  run readerPreventsDisposeTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).then(pin(0)).then(exception(0)).then(settleEscape(0)).then(knownStopAfterCommit(0)).expect(safe and not(canDispose(0)))
  run knownDisposalAfterDrainTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).then(borrow(0)).then(exception(0)).then(settleEscape(0)).then(knownStopAfterCommit(0)).then(drain(0)).then(dispose(0)).expect(safe and not(s.native.contains(0)))
  run invalidMarkerNotReusedTest=init.then(enter(0)).then(exception(0)).then(settleEscape(0)).expect(safe and s.marker.get(0)==3)
  run linkedBeforeDefaultsCounterexampleTest=init.then(enter(0)).then(captureNative(0)).then(allocatePrivate(0)).then(unsafePublish).expect(not(safe))
  run unprotectedMarkerCounterexampleTest=init.then(unsafeMarker).expect(not(safe))
  run unrootedCommitCounterexampleTest=init.then(unsafeCommit).expect(not(safe))
  run doubleCommitCounterexampleTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).then(unsafeDuplicate).expect(not(safe))
  run skippedChildGuardCounterexampleTest=init.then(enter(0)).then(enter(1)).then(prepare(1)).then(unsafeUnwind).expect(not(safe))
  run collectingActiveWriterCounterexampleTest=init.then(enter(0)).then(prepare(0)).then(unsafeGc).expect(not(safe))
  run refundBeforeDispositionCounterexampleTest=init.then(enter(0)).then(captureNative(0)).then(unsafeTicketRefund).expect(not(safe))
  run releaseWhileBorrowedCounterexampleTest=init.then(enter(0)).then(prepare(0)).then(commit(0)).then(borrow(0)).then(unsafeDispose).expect(not(safe))
  run rawFinalizerCoexistenceCounterexampleTest=init.then(unsafeLegacy).expect(not(safe))
}
