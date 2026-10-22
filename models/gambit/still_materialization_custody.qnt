module still_materialization_custody {
  // Three ordinary traced slots; one pending raw store; two relocation epochs.
  // Word-store integrity and authenticated write closure are premises, not C facts.
  type State={allocated:bool,shell:bool,enrolled:bool,domain:bool,source:bool,receiver:bool,
    retained:bool,leased:bool,pending:bool,stopped:bool,closed:bool,unknown:bool,
    prefix:int,physical:int,dirty:bool,young:bool,gc:bool,epoch:int,valueEpoch:int,
    complete:bool,delivered:bool,accepts:int,aborted:bool,recovered:bool}
  var s:State
  action init=s'={allocated:false,shell:false,enrolled:false,domain:true,source:true,receiver:false,
    retained:true,leased:false,pending:false,stopped:false,closed:false,unknown:false,
    prefix:0,physical:0,dirty:false,young:false,gc:false,epoch:0,valueEpoch:0,
    complete:false,delivered:false,accepts:0,aborted:false,recovered:false}
  val quiet=not(s.leased) and not(s.pending)
  val rooted=s.source or s.receiver
  val gcReady=s.domain and (not(s.enrolled) or (s.shell and rooted and s.retained)) and quiet
  val safe=s.prefix>=0 and s.prefix<=s.physical and s.physical<=3 and s.physical<=s.prefix+1 and
    (s.pending or s.prefix==s.physical) and
    (not(s.enrolled) or (s.allocated and s.shell and s.domain and rooted and s.retained)) and
    (not(s.pending) or (s.leased and s.enrolled and s.valueEpoch==s.epoch)) and
    (not(s.gc) or (gcReady and (not(s.young) or s.dirty))) and
    (not(s.complete) or (s.prefix==3 and quiet and not(s.aborted))) and
    (not(s.delivered) or (s.complete and s.receiver and s.accepts==1)) and
    (s.accepts<=1) and (not(s.recovered) or (s.stopped and s.closed))
  action allocate=all{not(s.allocated),not(s.gc),s'={...s,allocated:true}}
  action initializeShell=all{s.allocated,not(s.enrolled),not(s.gc),s'={...s,shell:true}}
  action enroll=all{s.shell,s.domain,s.source,s.retained,not(s.enrolled),not(s.gc),s'={...s,enrolled:true}}
  action acquire=all{s.enrolled,quiet,not(s.gc),not(s.stopped),not(s.complete),not(s.aborted),
    s'={...s,leased:true,valueEpoch:s.epoch}}
  action predirty=all{s.leased,not(s.gc),s'={...s,dirty:true}}
  action prepare=all{s.leased,s.dirty,s.prefix<3,not(s.pending),not(s.stopped),not(s.aborted),
    s'={...s,pending:true}}
  action store=all{s.pending,s.leased,s.physical==s.prefix,not(s.gc),not(s.stopped),s.valueEpoch==s.epoch,
    s'={...s,physical:s.prefix+1,young:true}}
  action commit=all{s.pending,s.physical==s.prefix+1,not(s.stopped),
    s'={...s,prefix:s.physical,pending:false}}
  action release=all{s.leased,not(s.pending),not(s.stopped),s'={...s,leased:false}}
  action loseResponse=s'={...s,unknown:true}
  action stop=all{s.allocated,not(s.gc),s'={...s,stopped:true}}
  action closeWriters=all{s.stopped,s'={...s,closed:true}}
  // Do not guess whether the ambiguous store ran: retain its actual valid slot.
  // Abort is semantic non-delivery, not physical deallocation or replay.
  action reconcileAbort=all{s.stopped,s.closed,not(s.complete),not(s.delivered),
    s'={...s,prefix:s.physical,pending:false,leased:false,aborted:true,recovered:true}}
  action enterGc=all{gcReady,not(s.gc),not(s.young) or s.dirty,s'={...s,gc:true}}
  // Abstract rewriting of all enumerated aliases; this is an explicit premise.
  action relocate=all{s.gc,s.epoch==0,s'={...s,epoch:1}}
  action finishGc=all{s.gc,s'={...s,gc:false}}
  action finish=all{s.enrolled,s.prefix==3,quiet,not(s.gc),not(s.aborted),s'={...s,complete:true}}
  action accept=all{s.complete,s.source,not(s.delivered),not(s.gc),
    s'={...s,receiver:true,delivered:true,accepts:1}}
  action dropSource=all{s.delivered,s.receiver,not(s.gc),s'={...s,source:false}}
  action retry=all{s.delivered,s'=s}
  // Whole-object dirty coverage remains until terminal initialization plus a
  // completed tracing/rearming protocol; that protocol is not abstracted away.
  action unsafeEnrollment=all{not(s.allocated),s'={...s,allocated:true,enrolled:true}}
  action stutter=s'=s
  action step=any{allocate,initializeShell,enroll,acquire,predirty,prepare,store,commit,release,
    loseResponse,stop,closeWriters,reconcileAbort,enterGc,relocate,finishGc,finish,accept,dropSource,retry,stutter}
  action shell=allocate.then(initializeShell).then(enroll)
  action one=acquire.then(predirty).then(prepare).then(store).then(commit).then(release)
  action ready=shell.then(one).then(one).then(one).then(finish)
  run shellBeforeEnrollmentTest=init.then(allocate).then(initializeShell).then(enroll).expect(safe)
  run unknownOutsideLeaseGcTest=init.then(shell).then(loseResponse).then(enterGc).expect(safe and s.gc)
  run unknownLeaseBlocksGcTest=init.then(shell).then(acquire).then(loseResponse).expect(safe and not(gcReady))
  run deadBeforeStoreAbortTest=init.then(shell).then(acquire).then(predirty).then(prepare).then(stop).then(closeWriters).then(reconcileAbort).then(enterGc).expect(safe and s.physical==0)
  run deadAfterStoreAbortTest=init.then(shell).then(acquire).then(predirty).then(prepare).then(store).then(stop).then(closeWriters).then(reconcileAbort).then(enterGc).expect(safe and s.physical==1 and s.aborted)
  run joinAloneRetainsLeaseTest=init.then(shell).then(acquire).then(stop).expect(safe and not(gcReady) and not(s.closed))
  run resultRootHandoffTest=init.then(ready).then(accept).then(dropSource).then(enterGc).expect(safe and s.receiver)
  run lostCompletionResponseTest=init.then(ready).then(accept).then(loseResponse).then(retry).expect(safe and s.accepts==1)
  run relocatedInputsReloadedTest=init.then(shell).then(one).then(enterGc).then(relocate).then(finishGc).then(one).expect(safe and s.prefix==2 and s.valueEpoch==1)
  run dirtyAcrossGcTest=init.then(shell).then(one).then(enterGc).then(relocate).then(finishGc).expect(safe and s.dirty)
  run deathAfterCompletionTest=init.then(ready).then(stop).then(closeWriters).then(accept).expect(safe and s.accepts==1)
  run unpublishedAllocationGcTest=init.then(allocate).then(loseResponse).then(enterGc).expect(safe and not(s.enrolled))
  run invalidShellControlTest=init.then(allocate).then(s'={...s,enrolled:true}).expect(not(safe))
  run rootDropControlTest=init.then(shell).then(s'={...s,source:false}).expect(not(safe))
  run pstateCleanupControlTest=init.then(shell).then(s'={...s,retained:false}).expect(not(safe))
  run unknownRawWriterGcControlTest=init.then(shell).then(acquire).then(predirty).then(prepare).then(loseResponse).then(s'={...s,gc:true}).expect(not(safe))
  run deathWithoutClosureControlTest=init.then(shell).then(acquire).then(stop).then(s'={...s,recovered:true,leased:false}).expect(not(safe))
  run postStoreBarrierGapControlTest=init.then(shell).then(one).then(s'={...s,dirty:false,gc:true}).expect(not(safe))
  run prematureResultControlTest=init.then(shell).then(s'={...s,complete:true}).expect(not(safe))
  run duplicateDeliveryControlTest=init.then(ready).then(accept).then(s'={...s,accepts:2}).expect(not(safe))
  run staleAliasGuardTest=init.then(shell).then(one).then(enterGc).then(relocate).then(finishGc).expect(safe and s.valueEpoch!=s.epoch)
  // Separate stale-pointer witness: the positive store guard rejects this epoch.
  run staleAliasControlTest=init.then(shell).then(one).then(enterGc).then(relocate).then(finishGc).then(acquire).then(predirty).then(prepare).then(s'={...s,valueEpoch:0}).expect(not(safe))
}
