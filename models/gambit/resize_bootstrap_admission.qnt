// Two prospective children, one moving epoch; abstract external result/stop/partial-init cleanup receipts.
// Atomic complete-view/registry/snapshot steps are premises, not a C/source or liveness proof.
module resize_bootstrap_admission {
 val Children=Set(1,2)
 val Required=Set(0,1,2,3,4) // thunk slot, scalar-source slot, frame/RA, materialized context, control-root graph
 type S={view:Set[int],frozen:bool,pending:bool,registered:bool,closed:bool,snapshot:bool,
  moved:bool,epoch:int,loaded:int,rootEpoch:int,context:bool,routing:bool,aborting:bool,commitSealed:bool,
  prepared:Set[int],attempted:Set[int],success:Set[int],failed:Set[int],unknown:Set[int],
  bound:Set[int],stopped:Set[int],reclaimed:Set[int],members:Set[int],
  initFailed:Set[int],initReceipt:Set[int],initCleaned:Set[int],attempts1:int,attempts2:int,cleanups1:int,cleanups2:int}
 var s:S
 action init=s'={view:Required,frozen:false,pending:false,registered:false,closed:false,snapshot:false,
  moved:false,epoch:0,loaded:0,rootEpoch:0,context:true,routing:false,aborting:false,commitSealed:false,
  prepared:Set(),attempted:Set(),success:Set(),failed:Set(),unknown:Set(),bound:Set(),stopped:Set(),reclaimed:Set(),members:Set(),
  initFailed:Set(),initReceipt:Set(),initCleaned:Set(),attempts1:0,attempts2:0,cleanups1:0,cleanups2:0}
 action freezeCaller=all{s.view==Required,not(s.frozen),s'={...s,frozen:true}}
 action closeGC=all{not(s.closed),not(s.moved),s'={...s,closed:true,snapshot:s.registered}}
 action deferClosed=all{s.closed,s.frozen,s.view==Required,not(s.registered),s'={...s,pending:true}}
 action collect=all{s.closed,s.frozen,s.view==Required,not(s.moved),s'={...s,moved:true,epoch:1,rootEpoch:if(s.snapshot)1 else s.rootEpoch,context:false}}
 // Snapshot/view scan readers are externally drained at this atomic abstract reopen step.
 action reopen=all{s.closed,s.moved,s.frozen,s'={...s,closed:false,snapshot:false,context:true}}
 action reloadSource=all{not(s.closed),s.context,s.frozen,s.view==Required,s'={...s,loaded:s.epoch}}
 action registerOpen=all{not(s.closed),s.frozen,s.view==Required,s.context,s.loaded==s.epoch,not(s.registered),
  s'={...s,registered:true,pending:false,rootEpoch:s.epoch}}
 action prepareChild(i)=all{Children.contains(i),s.registered,not(s.closed),s.initFailed==Set(),not(s.routing),not(s.prepared.contains(i)),
  s'={...s,prepared:s.prepared.union(Set(i))}}
 action setupFailure(i)=all{Children.contains(i),s.registered,not(s.closed),not(s.routing),not(s.prepared.contains(i)),s.initFailed==Set(),
  s'={...s,initFailed:Set(i),aborting:true}}
 // This observation does not claim the existing cleanup wrappers implement the receipt.
 action observeInitCleanup(i)=all{s.initFailed.contains(i),s'={...s,initReceipt:s.initReceipt.union(Set(i))}}
 action cleanupPartial(i)=all{s.initFailed.contains(i),s.initReceipt.contains(i),not(s.initCleaned.contains(i)),not(s.closed),not(s.snapshot),
  s'={...s,initCleaned:s.initCleaned.union(Set(i))}}
 action publishRouting=all{s.prepared==Children,s.registered,not(s.closed),s.initFailed==Set(),not(s.aborting),s.rootEpoch==s.epoch,s'={...s,routing:true}}
 action beginCreate(i)=all{Children.contains(i),s.routing,s.registered,not(s.closed),not(s.aborting),s.failed==Set(),s.unknown==Set(),not(s.attempted.contains(i)),
  s'={...s,attempted:s.attempted.union(Set(i)),attempts1:s.attempts1+(if(i==1)1 else 0),attempts2:s.attempts2+(if(i==2)1 else 0)}}
 action childEntry(i)=all{s.attempted.contains(i),not(s.failed.contains(i)),not(s.stopped.contains(i)),not(s.reclaimed.contains(i)),s.registered,
  s'={...s,bound:s.bound.union(Set(i))}}
 action createSuccess(i)=all{s.attempted.contains(i),not(s.failed.contains(i)),not(s.success.contains(i)),
  s'={...s,success:s.success.union(Set(i)),unknown:s.unknown.exclude(Set(i))}}
 action createFailure(i)=all{s.attempted.contains(i),not(s.success.contains(i)),not(s.unknown.contains(i)),not(s.bound.contains(i)),not(s.failed.contains(i)),
  s'={...s,failed:s.failed.union(Set(i))}}
 action loseOutcome(i)=all{s.attempted.contains(i),not(s.success.contains(i)),not(s.failed.contains(i)),s'={...s,unknown:s.unknown.union(Set(i))}}
 // Exact external no-child observation, not absence of ACK or a timeout.
 action confirmNoChild(i)=all{s.unknown.contains(i),not(s.bound.contains(i)),s'={...s,unknown:s.unknown.exclude(Set(i)),failed:s.failed.union(Set(i))}}
 action commitMembers=all{s.registered,s.routing,not(s.closed),s.context,s.rootEpoch==s.epoch,s.success==Children,s.bound==Children,s.unknown==Set(),s.failed==Set(),not(s.aborting),
  s'={...s,members:Children,commitSealed:true}}
 action beginAbort=all{s.failed!=Set() or s.unknown!=Set() or s.initFailed!=Set(),s.members==Set(),s'={...s,aborting:true}}
 // Exact OS stop/drain evidence; run return or ignored join is not this observation.
 action observeStopped(i)=all{s.aborting,s.success.contains(i),not(s.members.contains(i)),s'={...s,stopped:s.stopped.union(Set(i))}}
 action reclaimChild(i)=all{s.aborting,s.prepared.contains(i),not(s.reclaimed.contains(i)),not(s.members.contains(i)),not(s.closed),not(s.snapshot),not(s.unknown.contains(i)),
  (not(s.attempted.contains(i)) or s.failed.contains(i) or s.stopped.contains(i)),
  s'={...s,reclaimed:s.reclaimed.union(Set(i)),cleanups1:s.cleanups1+(if(i==1)1 else 0),cleanups2:s.cleanups2+(if(i==2)1 else 0)}}
 action releaseDescriptor=all{s.registered,s.aborting,not(s.closed),not(s.snapshot),s.members==Set(),s.prepared.subseteq(s.reclaimed),s.attempted.subseteq(s.reclaimed),s.initFailed.subseteq(s.initCleaned),
  s'={...s,registered:false}}
 action idle=s'=s
 val safe=all{
  s.view==Required,
  not(s.pending) or (s.frozen and s.view==Required),
  not(s.registered) or s.rootEpoch==s.epoch,
  s.attempted.exclude(s.reclaimed)==Set() or s.registered,
  s.members.subseteq(s.prepared.intersect(s.success).intersect(s.bound)),
  s.members==Set() or s.commitSealed,
  s.members.intersect(s.reclaimed)==Set(),
  s.failed.intersect(s.bound)==Set(),s.failed.intersect(s.success)==Set(),
  s.unknown.subseteq(s.attempted.exclude(s.success.union(s.failed))),
  s.unknown.intersect(s.reclaimed)==Set(),
  s.reclaimed.subseteq(s.prepared),
  s.reclaimed.intersect(s.attempted).subseteq(s.failed.union(s.stopped)),
  s.initCleaned.subseteq(s.initReceipt),s.stopped.subseteq(s.success),
  s.attempts1<=1,s.attempts2<=1,s.cleanups1<=1,s.cleanups2<=1,
  not(s.routing) or s.prepared==Children,
  not(s.snapshot) or s.registered}
 action step=any{freezeCaller,closeGC,deferClosed,collect,reopen,reloadSource,registerOpen,publishRouting,commitMembers,beginAbort,releaseDescriptor,idle,
  (nondet i=Children.oneOf();any{prepareChild(i),setupFailure(i),observeInitCleanup(i),cleanupPartial(i),beginCreate(i),childEntry(i),createSuccess(i),createFailure(i),loseOutcome(i),confirmNoChild(i),observeStopped(i),reclaimChild(i)})}
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action frozen=init.then(freezeCaller)
 action closedInit=frozen.then(closeGC).then(deferClosed)
 action registered=frozen.then(registerOpen)
 action publishingInit=registered.then(prepareChild(1)).then(prepareChild(2)).then(publishRouting)
 action firstReady=publishingInit.then(beginCreate(1)).then(childEntry(1)).then(createSuccess(1))
 action partialFailure=firstReady.then(beginCreate(2)).then(createFailure(2)).then(beginAbort)
 action partialUnknown=firstReady.then(beginCreate(2)).then(loseOutcome(2)).then(beginAbort)
 action badRegisterClosed=s'={...s,registered:true,rootEpoch:0}
 action badNoRoot=s'={...s,registered:false}
 action badView=s'={...s,view:Set(0)}
 action badCommit=s'={...s,members:Children}
 action badSiblingReclaim=s'={...s,reclaimed:s.reclaimed.union(Set(1))}
 action badUnknownReclaim=s'={...s,reclaimed:s.reclaimed.union(Set(2))}
 action badInitCleanup=s'={...s,initCleaned:s.initFailed}
 action badRepeatCreate=s'={...s,attempts1:s.attempts1+1}
 action badRepeatCleanup=s'={...s,cleanups1:s.cleanups1+1}
 run mappedOriginRegistrationTest=registered.then(check)
 run closeWinnerRetainsCallerTest=closedInit.then(check)
 run deferMoveReopenReloadRegisterTest=closedInit.then(collect).then(reopen).then(reloadSource).then(registerOpen).then(check)
 run registerWinnerIncludedInGcTest=registered.then(closeGC).then(collect).then(reopen).then(reloadSource).then(check)
 run creationBeforeCloseRetainsRootTest=publishingInit.then(beginCreate(1)).then(closeGC).then(collect).then(reopen).then(check)
 run childBeforeCreateReturnTest=publishingInit.then(beginCreate(1)).then(childEntry(1)).then(check)
 run fullSuccessGenerationCommitTest=firstReady.then(beginCreate(2)).then(createSuccess(2)).then(childEntry(2)).then(commitMembers).then(check)
 run partialFailureKeepsSuccessfulSiblingTest=partialFailure.then(reclaimChild(2)).then(check)
 run partialFailureDrainAndCleanupTest=partialFailure.then(reclaimChild(2)).then(observeStopped(1)).then(reclaimChild(1)).then(releaseDescriptor).then(check)
 run unknownChildKeepsEscrowTest=partialUnknown.then(check)
 run unknownChildLateEntryTest=partialUnknown.then(childEntry(2)).then(check)
 run unknownSettlesSuccessThenDrainsTest=partialUnknown.then(childEntry(2)).then(createSuccess(2)).then(observeStopped(2)).then(reclaimChild(2)).then(observeStopped(1)).then(reclaimChild(1)).then(releaseDescriptor).then(check)
 run unknownConfirmedNoChildTest=partialUnknown.then(confirmNoChild(2)).then(reclaimChild(2)).then(observeStopped(1)).then(reclaimChild(1)).then(releaseDescriptor).then(check)
 run partialSetupIdentityCleanupTest=registered.then(prepareChild(1)).then(setupFailure(2)).then(observeInitCleanup(2)).then(cleanupPartial(2)).then(reclaimChild(1)).then(releaseDescriptor).then(check)
 run neverAttemptedPreparedChildCleanupTest=publishingInit.then(beginCreate(1)).then(createFailure(1)).then(beginAbort).then(reclaimChild(1)).then(reclaimChild(2)).then(releaseDescriptor).then(check)
 run gcDuringPartialRollbackTest=partialFailure.then(closeGC).then(collect).then(reopen).then(reclaimChild(2)).then(check)
 run readyChildrenCannotCommitDuringClosedGcCounterexampleTest=firstReady.then(beginCreate(2)).then(createSuccess(2)).then(childEntry(2)).then(closeGC).then(badCommit).then(reject)
 run lateRegistrationMissingSnapshotCounterexampleTest=closedInit.then(badRegisterClosed).then(collect).then(reject)
 run rawCValueDoesNotReplaceViewCounterexampleTest=closedInit.then(badView).then(reject)
 run rootRetiredWithLiveChildCounterexampleTest=firstReady.then(badNoRoot).then(reject)
 run uncreatedCollectorMemberCounterexampleTest=publishingInit.then(badCommit).then(reject)
 run partialFailureFullCommitCounterexampleTest=partialFailure.then(badCommit).then(reject)
 run successfulSiblingBulkRollbackCounterexampleTest=partialFailure.then(badSiblingReclaim).then(reject)
 run unknownResultReclaimCounterexampleTest=partialUnknown.then(badUnknownReclaim).then(reject)
 run partialInitReceiptMissingCounterexampleTest=registered.then(prepareChild(1)).then(setupFailure(2)).then(badInitCleanup).then(reject)
 run retrySameCreateGenerationCounterexampleTest=firstReady.then(badRepeatCreate).then(reject)
 run duplicatePstateCleanupCounterexampleTest=partialFailure.then(observeStopped(1)).then(reclaimChild(1)).then(badRepeatCleanup).then(reject)
 action negativeInit=publishingInit
 action negativeStep=badCommit
}
