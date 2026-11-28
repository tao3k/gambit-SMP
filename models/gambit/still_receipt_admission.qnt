module still_receipt_admission {
  // Logical critical sections refine to ONE gate. Raw effects are separate steps.
  type State={a:int,ar:bool,applied:bool,physical:bool,held:bool,charge:int,credits:int,
    f:int,fr:bool,freed:bool,retired:bool,closed:bool,mode:int,rev:int,
    view:bool,viewRev:int,owner:int,delivery:bool,rawPin:bool}
  var s:State
  action init=s'={a:0,ar:false,applied:false,physical:false,held:false,charge:2,credits:0,
    f:0,fr:false,freed:false,retired:false,closed:false,mode:0,rev:0,
    view:false,viewRev:0,owner:0,delivery:false,rawPin:false}
  val pending=not(s.applied) or (s.f>0 and not(s.freed))
  val canCommit=s.closed and s.mode==0 and not(pending) and s.view and s.viewRev==s.rev
  val safe=s.credits<=1 and s.credits>=0 and
    s.charge==(if(s.credits==0)2 else 0) and
    (not(s.physical) or s.charge==2) and
    (not(s.held) or (s.applied and s.a==2 and not(s.freed))) and
    (not(s.freed) or (s.f==2 and s.fr and s.retired)) and
    (not(s.rawPin) or (s.physical and not(s.retired))) and
    (s.owner==0 or canCommit)
  action enter=all{s.owner==0,s.mode==0,not(s.closed),s.a==0,s'={...s,a:1,rev:s.rev+1}}
  action rawAllocOk=all{s.a==1,s'={...s,a:2,physical:true}}
  action rawAllocFail=all{s.a==1,s'={...s,a:3}}
  action publishAlloc=all{s.a>=2,not(s.ar),s'={...s,ar:true}}
  action attach=all{s.owner==0,s.mode==0,s.ar,s.a==2,not(s.applied),
    s'={...s,applied:true,held:true,rev:s.rev+1}}
  action refund=all{s.owner==0,s.mode==0,s.ar,s.a==3,not(s.applied),
    s'={...s,applied:true,charge:0,credits:s.credits+1,rev:s.rev+1}}
  action replay=all{s.applied,s'=s}
  action deliver=all{s.applied,s'={...s,delivery:true}}
  action loseDelivery=all{s.applied,s'={...s,delivery:false}}
  action close=all{s.owner==0,s.mode==0,s'={...s,closed:true}}
  action cancelNotEntered=all{s.owner==0,s.mode==0,s.closed,s.a==0,not(s.applied),
    s'={...s,a:3,ar:true,applied:true,charge:0,credits:s.credits+1,rev:s.rev+1}}
  action capture=all{s.owner==0,s.mode==0,s.closed,not(pending),
    s'={...s,view:true,viewRev:s.rev}}
  action beginSweep=all{s.owner==0,s.mode==0,s.closed,not(pending),s'={...s,mode:2}}
  action retire=all{s.mode==2,s.held,not(s.rawPin),not(s.retired),
    s'={...s,retired:true,rev:s.rev+1}}
  action endSweep=all{s.mode==2,s'={...s,mode:0}}
  action enterFree=all{s.owner==0,s.mode==0,s.retired,s.f==0,not(s.rawPin),
    s'={...s,f:1,rev:s.rev+1}}
  action rawFreeOk=all{s.f==1,s'={...s,f:2,physical:false}}
  action rawFreeFail=all{s.f==1,s'={...s,f:3}}
  action publishFree=all{s.f>=2,not(s.fr),s'={...s,fr:true}}
  action settleFree=all{s.owner==0,s.mode==0,s.fr,s.f==2,not(s.freed),
    s'={...s,freed:true,held:false,charge:0,credits:s.credits+1,rev:s.rev+1}}
  // A failed/unknown release remains pending in this bounded quarantine model.
  action replayFree=all{s.freed,s'=s}
  action pin=all{s.held,not(s.closed),s'={...s,rawPin:true}}
  action unpin=all{s.rawPin,s'={...s,rawPin:false}}
  action commit=all{s.owner==0,canCommit,s'={...s,owner:1}}
  action stutter=s'=s
  action step=any{enter,rawAllocOk,rawAllocFail,publishAlloc,attach,refund,replay,deliver,
    loseDelivery,close,cancelNotEntered,capture,beginSweep,retire,endSweep,enterFree,rawFreeOk,rawFreeFail,
    publishFree,settleFree,replayFree,pin,unpin,commit,stutter}
  action acquired=enter.then(rawAllocOk).then(publishAlloc).then(attach)
  action retired=acquired.then(close).then(beginSweep).then(retire).then(endSweep)
  action released=retired.then(enterFree).then(rawFreeOk).then(publishFree).then(settleFree)
  action unsafeCredit=s'={...s,charge:s.charge-2,credits:s.credits+1}
  run closedUnenteredCancelTest=init.then(close).then(cancelNotEntered).then(capture).then(commit).expect(safe and s.owner==1 and s.credits==1)
  run rawSuccessUnknownTest=init.then(enter).then(rawAllocOk).then(close).expect(safe and s.physical and not(s.ar) and not(canCommit))
  run rawFailureUnknownTest=init.then(enter).then(rawAllocFail).then(close).expect(safe and s.charge==2 and not(canCommit))
  run publishIsNotSettlementTest=init.then(enter).then(rawAllocFail).then(publishAlloc).expect(safe and s.charge==2)
  run knownFailureRefundTest=init.then(enter).then(rawAllocFail).then(publishAlloc).then(refund).expect(safe and s.charge==0)
  run duplicateRefundReplayTest=init.then(enter).then(rawAllocFail).then(publishAlloc).then(refund).then(replay).expect(safe and s.credits==1)
  run lostDeliveryQueryTest=init.then(acquired).then(deliver).then(loseDelivery).then(replay).then(deliver).expect(safe and s.delivery and s.physical)
  run rawFreeUnknownTest=init.then(retired).then(enterFree).then(rawFreeOk).expect(safe and not(s.physical) and s.charge==2 and not(canCommit))
  run failedFreeNoRefundTest=init.then(retired).then(enterFree).then(rawFreeFail).then(publishFree).expect(safe and s.physical and s.charge==2 and not(canCommit))
  run duplicateFreeReplayTest=init.then(released).then(replayFree).expect(safe and s.credits==1)
  run sweepInvalidatesTest=init.then(acquired).then(close).then(capture).then(beginSweep).then(retire).then(endSweep).expect(safe and not(canCommit))
  run sweepGateExcludesCommitTest=init.then(acquired).then(close).then(capture).then(beginSweep).expect(safe and not(canCommit))
  run retiredSnapshotTest=init.then(retired).then(capture).then(commit).expect(safe and s.owner==1 and s.charge==2)
  run drainedReleaseCommitTest=init.then(released).then(capture).then(commit).expect(safe and s.owner==1 and s.charge==0)
  run rawBorrowBlocksRetireTest=init.then(acquired).then(pin).then(close).then(beginSweep).expect(safe and s.rawPin and not(s.retired))
  run borrowDrainTest=init.then(acquired).then(pin).then(close).then(unpin).then(beginSweep).then(retire).then(endSweep).expect(safe and s.retired)
  run unknownCreditCounterexampleTest=init.then(enter).then(rawAllocOk).then(unsafeCredit).expect(not(safe))
  run duplicateCreditCounterexampleTest=init.then(released).then(unsafeCredit).expect(not(safe))
  run splitCommitCounterexampleTest=init.then(acquired).then(close).then(capture).then(beginSweep).then(retire).then(endSweep).then(s'={...s,owner:1}).expect(not(safe))
}
