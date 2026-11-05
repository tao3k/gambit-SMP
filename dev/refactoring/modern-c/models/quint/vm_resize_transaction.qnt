// Bounded ledger protocol, not a C-memory-model or allocator proof.
module vm_resize_transaction {
  pure val old=Set(0)
  pure val added=Set(1,2)
  type State={phase:str,capacity:int,assigned:int,resume:int,grant:Set[int],
    initialized:Set[int],created:Set[int],joining:Set[int],joined:Set[int],
    members:Set[int],released:Set[int],contextRoots:Set[int],vmRoot:bool,
    inFlight:Set[int],unknown:bool,aborted:Set[int],dataClosed:Set[int],nativeDebt:Set[int],gcRounds:int}
  var s:State
  pure val empty:State={phase:"idle",capacity:4,assigned:2,resume:1,grant:Set(),
    initialized:Set(),created:Set(),joining:Set(),joined:Set(),members:old,
    released:Set(),contextRoots:Set(),vmRoot:false,inFlight:Set(),unknown:false,aborted:Set(),dataClosed:Set(),nativeDebt:Set(),gcRounds:0}
  action init={s'=empty}
  action request=all{s.phase=="idle",s.members==old,s.nativeDebt==Set(),
    s'={...s,phase:"request",vmRoot:true,initialized:Set(),created:Set(),
       joined:Set(),joining:Set(),contextRoots:Set(),released:Set(),inFlight:Set(),
       aborted:Set(),dataClosed:Set()}}
  action collect=all{s.phase=="request",s.vmRoot,
    s'={...s,assigned:2,capacity:4}}
  action reserve=all{s.phase=="request",s.vmRoot,s.assigned==2,
    s'={...s,phase:"initialize",capacity:7,assigned:6,grant:added}}
  action allocationFailure=all{s.phase=="request",
    s'={...s,phase:"idle",vmRoot:false}} // partial additions refunded; existing capacity kept
  action initialize=all{s.phase=="initialize",s.initialized!=added,
    nondet i=added.exclude(s.initialized).oneOf();
    s'={...s,initialized:s.initialized.union(Set(i)),
       contextRoots:s.contextRoots.union(Set(i))}}
  action beginCreate=all{s.phase=="initialize",s.initialized==added,
    s.inFlight==Set(),s.created!=added,
    nondet i=added.exclude(s.created).oneOf();
    s'={...s,inFlight:Set(i)}}
  action createSuccess=all{s.inFlight!=Set(),s.phase=="initialize",
    s'={...s,created:s.created.union(s.inFlight),inFlight:Set()}}
  action createFailure=all{s.inFlight!=Set(),s.phase=="initialize",
    s'={...s,phase:"abort",inFlight:Set(),joining:s.created}}
  action createUnknown=all{s.inFlight!=Set(),s.phase=="initialize",
    s'={...s,phase:"abort",unknown:true,aborted:added,
      nativeDebt:s.nativeDebt.union(s.inFlight),inFlight:Set(),joining:s.created}}
  action joinSuccess=all{s.phase=="abort",s.joined!=s.joining,
    nondet i=s.joining.exclude(s.joined).oneOf();
    s'={...s,joined:s.joined.union(Set(i))}}
  action joinUnknown=all{s.phase=="abort",s.joined!=s.joining,
    s'={...s,phase:"abort",unknown:true,aborted:added,
      nativeDebt:s.nativeDebt.union(s.joining.exclude(s.joined)),joined:s.joining}}
  // A parked descriptor has no PSTATE write authority. Abort is published
  // before its roots/section grants are refunded. Native identity still lives.
  action sealAbort=all{s.phase=="abort",s'={...s,aborted:added}}
  action rollback=all{s.phase=="abort",s.inFlight==Set(),s.aborted==added,
    s.joined==s.created,s'={...empty,unknown:s.unknown,nativeDebt:s.nativeDebt,
      aborted:s.aborted,gcRounds:s.gcRounds}}
  action healthyGc=all{s.phase=="idle",s.members==old,s.gcRounds<2,
    s.nativeDebt.subseteq(s.aborted.union(s.dataClosed)),s'={...s,gcRounds:s.gcRounds+1}}
  action nativeAbortExit=all{s.phase=="idle",s.nativeDebt!=Set(),
    nondet i=s.nativeDebt.oneOf();s'={...s,dataClosed:s.dataClosed.union(Set(i))}}

  action commitMembers=all{s.phase=="initialize",s.initialized==added,
    s.created==added,s.inFlight==Set(),not(s.unknown),
    s'={...s,phase:"committed",members:old.union(added)}}
  action releaseEntry=all{s.phase=="committed",
    s'={...s,phase:"finish",released:added}}
  action finish=all{s.phase=="finish",s.contextRoots==added,
    s'={...s,phase:"idle",vmRoot:false}}
  action shrinkReject=all{s.phase=="idle",s.members==old.union(added),s'=s}
  action shrinkCommit=all{s.phase=="idle",s.members==old.union(added),
    s'={...s,phase:"retire",members:old,joining:added,joined:Set()}}
  action retireJoin=all{s.phase=="retire",s.joined!=s.joining,
    nondet i=s.joining.exclude(s.joined).oneOf();
    s'={...s,joined:s.joined.union(Set(i))}}
  action retireUnknown=all{s.phase=="retire",s.joined!=s.joining,
    s'={...s,phase:"retained",unknown:true,nativeDebt:s.joining.exclude(s.joined)}}
  action transferAndFinish=all{s.phase=="retire",s.joined==added,
    s'={...empty,capacity:s.capacity,assigned:s.assigned}}
    // Still transfer is a source premise. Physical sections remain until GC.
  action step=any{request,collect,reserve,allocationFailure,initialize,beginCreate,
    createSuccess,createFailure,createUnknown,joinSuccess,joinUnknown,sealAbort,rollback,healthyGc,nativeAbortExit,
    commitMembers,releaseEntry,finish,shrinkReject,shrinkCommit,retireJoin,
    retireUnknown,transferAndFinish,s'=s}
  val safe=all{
    s.members.exclude(old).subseteq(s.created),
    s.members.exclude(old).subseteq(s.initialized),
    s.released.subseteq(s.created),
    s.phase.in(Set("request","initialize","abort")) implies s.vmRoot,
    s.phase.in(Set("committed","finish")) implies s.contextRoots==added,
    s.unknown implies all{s.nativeDebt!=Set(),
      s.phase.in(Set("retained","abort","idle"))},
    s.phase=="idle" implies s.nativeDebt.subseteq(s.aborted.union(s.dataClosed)),
    s.nativeDebt!=Set() implies not(s.released.intersect(s.aborted).size()>0),
    s.grant==added implies all{s.capacity>=s.assigned+s.resume,s.assigned==6},
    s.phase=="idle" and s.members==old implies all{s.grant==Set(),s.inFlight==Set()},
    s.phase=="initialize" implies s.released==Set()
  }
  action check=all{safe,s'=s}
  run publishTest=init.then(request).then(reserve).then(initialize).then(initialize)
    .then(beginCreate).then(createSuccess).then(beginCreate).then(createSuccess)
    .then(commitMembers).then(releaseEntry).then(finish).then(check)
  run rollbackTest=init.then(request).then(reserve).then(initialize).then(initialize)
    .then(beginCreate).then(createSuccess).then(beginCreate).then(createFailure)
    .then(joinSuccess).then(sealAbort).then(rollback).then(check)
  run unknownTest=init.then(request).then(reserve).then(initialize).then(initialize)
    .then(beginCreate).then(createUnknown).then(rollback).then(healthyGc).then(check)
  run retireTest=publishTest.then(shrinkCommit).then(retireJoin).then(retireJoin)
    .then(transferAndFinish).then(check)
  // A previous known abort is not authority for a reused RUN generation.
  // C clears a reusable descriptor and installs the new generation before
  // native creation; uncertain descriptors fail admission before that reset.
  run reusedGenerationTest=rollbackTest.then(request).then(reserve)
    .then(initialize).then(initialize).then(beginCreate).then(createSuccess)
    .then(beginCreate).then(createSuccess).then(commitMembers).then(releaseEntry)
    .then(finish).then(shrinkCommit).then(retireUnknown).then(check)
  action staleAbortReceipt=s'={...s,aborted:added}
  run staleGenerationNegativeTest=publishTest.then(staleAbortReceipt)
    .then(shrinkCommit).then(retireUnknown).then(all{assert(not(safe)),s'=s})
  action earlyPublish={s'={...empty,members:old.union(added)}}
  action refundUnknown={s'={...empty,unknown:true,phase:"retained"}}
  action releaseBeforeCreate={s'={...empty,phase:"initialize",released:added,vmRoot:true}}
  action dropRequestRoot={s'={...empty,phase:"request",vmRoot:false}}
  action noResumeBudget={s'={...empty,phase:"initialize",vmRoot:true,
    capacity:6,assigned:6,grant:added}}
}
