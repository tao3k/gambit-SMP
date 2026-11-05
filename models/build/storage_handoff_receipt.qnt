module storage_handoff_receipt {
 import storage_handoff_parameters.* from "./storage_handoff_parameters"
 // Two symbolic still allocations: lengths 5 and 7; not measured object sizes.
 // One whole retired arena, two native RC holders, one foreign release duty.
 type State={phase:int,epoch:int,sealed:int,closed:bool,source:Set[int],target:Set[int],rcSource:Set[int],rcTarget:Set[int],roots:Set[int],
  charged:int,deferred:int,targetCharge:int,vmCharge:int,reserve:int,allocating:bool,raw:bool,writer:bool,
  committed:bool,unknown:bool,exited:bool,leases:Set[int],snapshot:Set[int],seen:Set[int],lastSnapshot:Set[int],lastSeen:Set[int],
  releaseState:int,releaseCalls:int,lane:bool,pinned:bool,freed:Set[int]}
 pure def words(xs:Set[int]):int=xs.fold(0,(a,i)=>a+(if(i==0) 5 else 7))
 pure val initial:State={phase:0,epoch:0,sealed:-1,closed:false,source:Set(0,1),target:Set(),rcSource:Set(0,1),rcTarget:Set(),roots:Set(0,1),
  charged:5,deferred:7,targetCharge:0,vmCharge:5,reserve:0,allocating:false,raw:false,writer:false,
  committed:false,unknown:false,exited:false,leases:Set(0),snapshot:Set(),seen:Set(),lastSnapshot:Set(),lastSeen:Set(),
  releaseState:0,releaseCalls:0,lane:true,pinned:false,freed:Set()}
 // releaseState: 0 armed, 1 accepted/in flight, 2 success, 3 error/unknown, 4 externally settled.
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,leases:Set(1)}
 action beginRaw=all {s.phase==0,not(s.closed),not(s.raw),not(s.exited),s'={...s,raw:true}}
 action endRaw=all {s.raw,s'={...s,raw:false}}
 action beginWriter=all {not(s.closed),not(s.writer),s.phase==0,s'={...s,writer:true}}
 action endWriter=all {s.writer,s.phase==0,s'={...s,writer:false,sealed:-1}}
 action closeAdmission=all {not(s.closed),s'={...s,closed:true}}
 action startAllocation=all {not(s.closed),not(s.allocating),s.phase==0,not(s.committed),s'={...s,allocating:true,reserve:3,vmCharge:s.vmCharge+3}}
 action failAllocation=all {s.allocating,s.phase==0,s'={...s,allocating:false,vmCharge:s.vmCharge-s.reserve,reserve:0,sealed:-1}}
 action seal=all {s.closed,s.phase==0,not(s.raw),not(s.writer),not(s.allocating),s.reserve==0,not(s.committed),s.roots==Set(0,1),s.lane,not(s.pinned),s'={...s,sealed:s.epoch}}
 action commitHandoff=all {s.phase==0,s.closed,s.sealed==s.epoch,not(s.raw),not(s.writer),not(s.allocating),s.reserve==0,
  not(s.committed),s.lane,not(s.pinned),s.roots==Set(0,1),
  s'={...s,source:Set(),target:s.source,rcSource:Set(),rcTarget:s.rcSource,
   charged:0,deferred:0,targetCharge:s.charged+s.deferred,vmCharge:s.vmCharge+s.deferred,committed:true,unknown:true}}
 action acknowledge=all {s.committed,s.unknown,s'={...s,unknown:false}}
 // Exact receipt lookup is idempotent; timeout does not repeat the transfer.
 action lookupReceipt=all {s.committed,s'=s}
 action depart=all {s.phase==0,s.committed,s.source==Set(),s.rcSource==Set(),not(s.raw),not(s.writer),not(s.allocating),
  s.lane,not(s.pinned),s'={...s,exited:true}}
 action beginGC=all {s.phase==0,not(s.raw),not(s.writer),not(s.allocating),s'={...s,phase:1,snapshot:s.source.union(s.target),seen:Set()}}
 action scan(i)=all {s.phase==1,s.snapshot.contains(i),not(s.seen.contains(i)),s'={...s,seen:s.seen.union(Set(i))}}
 action endGC=all {s.phase==1,s.seen==s.snapshot,
  s'={...s,phase:0,epoch:s.epoch+1,sealed:-1,charged:words(s.source),deferred:0,targetCharge:words(s.target),
    vmCharge:words(s.source)+words(s.target),lastSnapshot:s.snapshot,lastSeen:s.seen,snapshot:Set(),seen:Set()}}
 action releaseLease(i)=all {s.leases.contains(i),not(s.raw),s'={...s,leases:s.leases.exclude(Set(i))}}
 action startRelease=all {s.committed,s.phase==0,s.leases==Set(),not(s.unknown),s.releaseState==0,s.lane,
  s'={...s,releaseState:1,releaseCalls:s.releaseCalls+1}}
 action finishRelease=all {s.releaseState==1,s'={...s,releaseState:2}}
 action errorRelease=all {s.releaseState==1,s'={...s,releaseState:3}}
 action settleRelease=all {s.releaseState==3,s.lane,s'={...s,releaseState:4}}
 action reclaim=all {s.committed,s.phase==0,s.leases==Set(),not(s.unknown),not(s.raw),not(s.writer),s.releaseState==2 or s.releaseState==4,
  s'={...s,freed:s.freed.union(s.target),target:Set(),rcTarget:Set(),targetCharge:0,vmCharge:0,roots:Set()}}
 def safe=s.source.intersect(s.target)==Set() and s.freed.intersect(s.source.union(s.target))==Set() and s.source.union(s.target).union(s.freed)==Set(0,1) and
  s.charged+s.deferred==words(s.source) and s.targetCharge==words(s.target) and s.vmCharge+s.deferred==words(s.source)+words(s.target)+s.reserve and
  s.leases.subseteq(s.roots) and s.roots.subseteq(s.source.union(s.target)) and
  (s.exited implies s.committed and s.source==Set() and s.rcSource==Set()) and
  (s.committed implies s.rcSource==Set()) and
  (not(s.committed) implies s.rcSource==Set(0,1)) and
  (s.phase==1 implies s.snapshot==s.source.union(s.target) and not(s.raw) and not(s.writer) and not(s.allocating) and s.reserve==0) and s.lastSnapshot==s.lastSeen and
  (s.unknown implies s.committed and s.freed==Set()) and
  (s.freed!=Set() implies (s.releaseState==2 or s.releaseState==4) and s.leases==Set()) and
  s.releaseCalls<=1 and s.rcSource.intersect(s.rcTarget)==Set()
 action step={nondet i=0.to(WorkspaceCount-1).oneOf();any {beginRaw,endRaw,beginWriter,endWriter,closeAdmission,startAllocation,failAllocation,seal,commitHandoff,
  acknowledge,lookupReceipt,depart,beginGC,scan(i),endGC,releaseLease(i),startRelease,finishRelease,errorRelease,settleRelease,reclaim,s'=s}}
 action badExit=s'={...s,exited:true}
 action badCharge=s'={...s,vmCharge:s.vmCharge+7}
 action badCoverage=s'={...s,lastSnapshot:s.snapshot,lastSeen:s.seen,phase:0,snapshot:Set(),seen:Set()}
 action badDetach=s'={...s,source:Set()}
 action badFree=s'={...s,freed:Set(0,1),source:Set(),target:Set(),charged:0,deferred:0,targetCharge:0,vmCharge:0,roots:Set()}
 action badRC=s'={...s,rcSource:Set(0,1)}
 action badRetry=s'={...s,releaseCalls:s.releaseCalls+1}
 // Wrong cleanup follows a stale source head into storage already owned by target.
 action badLegacy=s'={...s,target:Set(),freed:s.freed.union(s.target),targetCharge:0,vmCharge:0}
 action badOmitTarget=s'={...s,vmCharge:words(s.source)}
 action badForgetReclaimed=s'={...s,freed:Set()}
 action badFrozenRaw=s'={...s,raw:true}
 run handoffExitTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(depart).expect(safe and s.unknown and s.leases==Set(0))
 run ackLookupTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(lookupReceipt).then(acknowledge).expect(safe and s.targetCharge==12)
 run beforeCommitFailureTest=init.then(closeAdmission).then(seal).expect(safe and s.source==Set(0,1) and not(s.committed))
 run rawDrainTest=init.then(beginRaw).then(closeAdmission).then(endRaw).then(seal).then(commitHandoff).expect(safe)
 run writerDrainTest=init.then(beginWriter).then(closeAdmission).then(endWriter).then(seal).then(commitHandoff).expect(safe)
 run allocationRefundTest=init.then(startAllocation).then(closeAdmission).then(failAllocation).then(seal).then(commitHandoff).expect(safe and s.vmCharge==12)
 run gcInvalidatesSealTest=init.then(closeAdmission).then(seal).then(beginGC).then(scan(0)).then(scan(1)).then(endGC).expect(safe and s.sealed== -1)
 run resealTest=init.then(closeAdmission).then(seal).then(beginGC).then(scan(0)).then(scan(1)).then(endGC).then(seal).then(commitHandoff).expect(safe and s.vmCharge==12)
 run gcAfterExitTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(depart).then(beginGC).then(scan(0)).then(scan(1)).then(endGC).expect(safe and s.targetCharge==12)
 run releaseSuccessTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(acknowledge).then(releaseLease(0)).then(startRelease).then(finishRelease).then(reclaim).expect(safe and s.freed==Set(0,1))
 run releaseErrorCustodyTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(acknowledge).then(releaseLease(0)).then(startRelease).then(errorRelease).expect(safe and s.target==Set(0,1))
 run externalSettlementTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(acknowledge).then(releaseLease(0)).then(startRelease).then(errorRelease).then(settleRelease).then(reclaim).expect(safe)
 run otherLeaseTest=initOther.then(closeAdmission).then(seal).then(commitHandoff).then(depart).expect(safe and s.leases==Set(1))
 run repeatedReclaimTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(acknowledge).then(releaseLease(0)).then(startRelease).then(finishRelease).then(reclaim).then(beginGC).then(endGC).then(reclaim).expect(safe and s.freed==Set(0,1))
 run exitWithoutHandoffControlTest=init.then(badExit).expect(not(safe))
 run doubleChargeControlTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(badCharge).expect(not(safe))
 run partialDetachControlTest=init.then(badDetach).expect(not(safe))
 run omittedScanControlTest=init.then(beginGC).then(scan(0)).then(badCoverage).expect(not(safe))
 run leaseFreeControlTest=init.then(badFree).expect(not(safe))
 run unknownFreeControlTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(releaseLease(0)).then(badFree).expect(not(safe))
 run rcLeftBehindControlTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(badRC).expect(not(safe))
 run duplicateReleaseControlTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(acknowledge).then(releaseLease(0)).then(startRelease).then(errorRelease).then(badRetry).expect(not(safe))
 run legacyCleanupControlTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(badLegacy).expect(not(safe))
 run targetAccountingOmittedControlTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(badOmitTarget).expect(not(safe))
 run forgottenReclaimControlTest=init.then(closeAdmission).then(seal).then(commitHandoff).then(acknowledge).then(releaseLease(0)).then(startRelease).then(finishRelease).then(reclaim).then(badForgetReclaimed).expect(not(safe))
 run frozenRawControlTest=init.then(beginGC).then(badFrozenRaw).expect(not(safe))
}
