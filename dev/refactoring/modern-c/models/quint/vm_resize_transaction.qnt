// Bounded ledger protocol, not a C-memory-model or allocator proof.
module vm_resize_transaction {
  pure val old=Set(0)
  pure val added=Set(1,2)
  type State={phase:str,capacity:int,assigned:int,resume:int,grant:Set[int],
    initialized:Set[int],created:Set[int],joining:Set[int],joined:Set[int],
    members:Set[int],released:Set[int],contextRoots:Set[int],vmRoot:bool,
    inFlight:Set[int],unknown:bool}
  var s:State
  pure val empty:State={phase:"idle",capacity:4,assigned:2,resume:1,grant:Set(),
    initialized:Set(),created:Set(),joining:Set(),joined:Set(),members:old,
    released:Set(),contextRoots:Set(),vmRoot:false,inFlight:Set(),unknown:false}
  action init={s'=empty}
  action request=all{s.phase=="idle",s.members==old,
    s'={...s,phase:"request",vmRoot:true,initialized:Set(),created:Set(),
       joined:Set(),joining:Set(),contextRoots:Set(),released:Set(),inFlight:Set()}}
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
    s'={...s,phase:"retained",unknown:true}}
  action joinSuccess=all{s.phase=="abort",s.joined!=s.joining,
    nondet i=s.joining.exclude(s.joined).oneOf();
    s'={...s,joined:s.joined.union(Set(i))}}
  action joinUnknown=all{s.phase=="abort",s.joined!=s.joining,
    s'={...s,phase:"retained",unknown:true}}
  action rollback=all{s.phase=="abort",not(s.unknown),s.inFlight==Set(),
    s.joined==s.created,s'={...empty}}
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
    s'={...s,phase:"retained",unknown:true}}
  action transferAndFinish=all{s.phase=="retire",s.joined==added,
    s'={...empty,capacity:s.capacity,assigned:s.assigned}}
    // Still transfer is a source premise. Physical sections remain until GC.
  action step=any{request,collect,reserve,allocationFailure,initialize,beginCreate,
    createSuccess,createFailure,createUnknown,joinSuccess,joinUnknown,rollback,
    commitMembers,releaseEntry,finish,shrinkReject,shrinkCommit,retireJoin,
    retireUnknown,transferAndFinish,s'=s}
  val safe=all{
    s.members.exclude(old).subseteq(s.created),
    s.members.exclude(old).subseteq(s.initialized),
    s.released.subseteq(s.created),
    s.phase.in(Set("request","initialize","abort")) implies s.vmRoot,
    s.phase.in(Set("committed","finish")) implies s.contextRoots==added,
    s.unknown implies all{s.phase=="retained",s.grant==added,s.assigned==6},
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
    .then(joinSuccess).then(rollback).then(check)
  run unknownTest=init.then(request).then(reserve).then(initialize).then(initialize)
    .then(beginCreate).then(createUnknown).then(check)
  run retireTest=publishTest.then(shrinkCommit).then(retireJoin).then(retireJoin)
    .then(transferAndFinish).then(check)
  action earlyPublish={s'={...empty,members:old.union(added)}}
  action refundUnknown={s'={...empty,unknown:true,phase:"retained"}}
  action releaseBeforeCreate={s'={...empty,phase:"initialize",released:added,vmRoot:true}}
  action dropRequestRoot={s'={...empty,phase:"request",vmRoot:false}}
  action noResumeBudget={s'={...empty,phase:"initialize",vmRoot:true,
    capacity:6,assigned:6,grant:added}}
}
