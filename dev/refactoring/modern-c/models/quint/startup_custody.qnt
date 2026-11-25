// Fixed activation slot; finite safety, not an OS fairness/time-bound proof.
// Phase 8 retains a published startup whose readiness failed or is unknown.
module startup_custody {
  type S={phase:int,generation:int,ack:int,expected:int,member:bool,
    root:bool,marker:bool,nativeHeld:bool,joined:bool,unknown:bool,unknownGen:int,
    waiting:bool,lockHeld:bool,viewComplete:bool,pendingGC:bool,gcs:int,
    receipt:bool,yields:int,rejected:int}
  var s:S
  pure def acknowledgementAllowed(activeGeneration:int, launchGeneration:int,
                                   startupMarker:bool, pending:bool):bool =
    activeGeneration==launchGeneration and startupMarker and pending
  pure def ticketSettled(ticket:int, currentEpoch:int, ready:bool,
                         returned:bool, uncertain:bool):bool =
    ticket==currentEpoch and ready and not(returned or uncertain)
  pure val empty:S={phase:0,generation:0,ack:0,expected:0,member:false,
    root:false,marker:false,nativeHeld:false,joined:true,unknown:false,unknownGen:0,
    waiting:false,lockHeld:false,viewComplete:true,pendingGC:false,gcs:0,
    receipt:false,yields:0,rejected:0}
  action init={s'=empty}
  action reserveNext=all{s.phase.in(Set(0,7)),s.joined,not(s.nativeHeld),s.generation<3,
    s'={...s,phase:1,generation:s.generation+1,root:true,nativeHeld:true,
      joined:false,receipt:false,unknown:false}}
  action publish=all{s.phase==1,s'={...s,phase:2,member:true}}
  action enterNative=all{s.phase==2,s'={...s,phase:3}}
  action enterScheme=all{s.phase==3,s'={...s,phase:4,marker:true}}
  action ready=all{s.phase==4,s'={...s,phase:5,ack:s.generation}}
  action waitForReady=all{s.phase.in(Set(2,3,4,5)),s.member,not(s.waiting),not(s.receipt),
    s'={...s,waiting:true,expected:s.generation}}
  action ownerYield={s'={...s,yields:s.yields+1}}
  action requestGC=all{s.member,s'={...s,pendingGC:true}}
  action serviceGC=all{s.waiting,s.viewComplete,not(s.lockHeld),s.pendingGC,
    s'={...s,pendingGC:false,gcs:s.gcs+1}}
  action consumeReceipt=all{s.waiting,s.phase==5,s.ack==s.expected,
    s.generation==s.expected,s'={...s,waiting:false,receipt:true}}
  action startupRejected=all{s.phase.in(Set(3,4)),
    s'={...s,phase:8,waiting:false}}
  action startupUnknown=all{s.phase.in(Set(2,3,4)),
    s'={...s,phase:8,waiting:false,unknown:true,unknownGen:s.generation}}
  action stop=all{s.phase==5,s'={...s,phase:6,member:false,root:false,marker:false}}
  action joinKnown=all{s.phase==6,s'={...s,phase:7,joined:true,nativeHeld:false,
    unknown:false,receipt:false,waiting:false}}
  action joinUnknown=all{s.phase==6,s'={...s,unknown:true,unknownGen:s.generation}}
  action rejectLate=all{s.generation>1,s'={...s,rejected:s.rejected+1}}
  action abortKnown=all{s.phase==1,s'={...s,phase:7,joined:true,nativeHeld:false,root:false}}
  val safe=all{
    s.receipt implies all{s.phase.in(Set(5,6)),s.generation==s.ack,s.ack==s.expected},
    s.phase.in(Set(2,3,4)) implies s.root,
    s.phase==4 implies s.marker,
    s.phase==5 implies s.ack==s.generation,
    s.waiting implies all{s.viewComplete,not(s.lockHeld)},
    s.unknown implies all{s.nativeHeld,not(s.joined),s.generation==s.unknownGen},
    s.phase==7 implies all{s.joined,not(s.nativeHeld)},
    s.phase==8 implies all{s.member,s.nativeHeld,s.root,not(s.joined),
      not(s.waiting),not(s.receipt),s.ack!=s.generation},
    s.member implies s.phase.in(Set(2,3,4,5,8))
  }
  action check=all{safe,s'=s}
  action checkPending=all{safe,s.phase==2,s.yields>=3,not(s.receipt),s'=s}
  action step=any{reserveNext,publish,enterNative,enterScheme,ready,waitForReady,
    ownerYield,requestGC,serviceGC,consumeReceipt,startupRejected,startupUnknown,
    stop,joinKnown,joinUnknown,rejectLate,
    abortKnown,s'=s}
  run readinessTest=init.then(reserveNext).then(publish).then(waitForReady)
    .then(enterNative).then(enterScheme).then(ready).then(consumeReceipt).then(check)
  run gcDuringWaitTest=init.then(reserveNext).then(publish).then(waitForReady)
    .then(requestGC).then(serviceGC).then(enterNative).then(enterScheme)
    .then(ready).then(consumeReceipt).then(check)
  run yieldIsNotAckTest=init.then(reserveNext).then(publish).then(waitForReady)
    .then(ownerYield).then(ownerYield).then(ownerYield).then(checkPending)
  run reuseTest=init.then(reserveNext).then(publish).then(enterNative).then(enterScheme)
    .then(ready).then(stop).then(joinKnown).then(reserveNext).then(rejectLate).then(check)
  run unknownJoinTest=init.then(reserveNext).then(publish).then(enterNative).then(enterScheme)
    .then(ready).then(stop).then(joinUnknown).then(check)
  run rollbackTest=init.then(reserveNext).then(abortKnown).then(reserveNext).then(check)
  run rejectedReadinessTest=init.then(reserveNext).then(publish).then(waitForReady)
    .then(enterNative).then(enterScheme).then(startupRejected).then(check)
  run failedMarkerReadinessTest=init.then(reserveNext).then(publish).then(waitForReady)
    .then(enterNative).then(startupRejected).then(check)
  run unknownReadinessTest=init.then(reserveNext).then(publish).then(waitForReady)
    .then(startupUnknown).then(check)
  run failedStartupReceiptNegativeTest=rejectedReadinessTest
    .then(all{s'={...s,receipt:true,ack:s.generation}})
    .then(all{assert(not(safe)),s'=s})
  run staleActivationCannotAckTest=assert(not(acknowledgementAllowed(8,9,true,true)))
  run repeatActivationCannotAckTest=assert(not(acknowledgementAllowed(9,9,true,false)))
  run stableMemberInNewEpochTest=assert(
    acknowledgementAllowed(9,9,true,true) and ticketSettled(19,19,true,false,false))
  run shrinkInvalidatesTicketTest=assert(not(ticketSettled(19,20,true,false,false)))
  run returnedActivationInvalidatesReadyTest=assert(not(ticketSettled(19,19,true,true,false)))
  action badPublishMeansReady={s'={...empty,phase:2,member:true,root:true,
    receipt:true,generation:1,ack:0,expected:1}}
  action badReuseWithoutJoin={s'={...empty,phase:1,generation:2,nativeHeld:true,
    joined:false,unknown:true,unknownGen:1}}
  action badStaleReceipt={s'={...empty,phase:5,generation:2,ack:1,expected:1,
    receipt:true,member:true,root:true,marker:true}}
  action badGCWhileLocked={s'={...empty,waiting:true,lockHeld:true,gcs:1}}
  action badRootDrop={s'={...empty,phase:4,member:true,nativeHeld:true,joined:false}}
}
