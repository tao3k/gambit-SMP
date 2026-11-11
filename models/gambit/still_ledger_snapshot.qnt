module still_ledger_snapshot {
  // One existing two-word block and one two-word allocation intent.
  // Charge is a conservative custody bound while native outcomes are unknown.
  type State={baseHeld:bool,basePublished:bool,retired:bool,newHeld:bool,published:bool,shell:bool,
    attempted:bool,reserved:bool,allocBusy:bool,acquired:bool,known:bool,failed:bool,
    allocUnknown:bool,allocStopped:bool,refunds:int,charge:int,rev:int,
    closed:bool,scanning:bool,scanRev:int,sweeping:bool,metaPin:bool,rawPin:bool,
    freeBusy:bool,freeUnknown:bool,view:bool,viewRev:int,viewCharge:int,owner:int}
  var s:State
  action init=s'={baseHeld:true,basePublished:true,retired:false,newHeld:false,published:false,shell:false,
    attempted:false,reserved:false,allocBusy:false,acquired:false,known:false,failed:false,
    allocUnknown:false,allocStopped:false,refunds:0,charge:2,rev:0,
    closed:false,scanning:false,scanRev:0,sweeping:false,metaPin:false,rawPin:false,
    freeBusy:false,freeUnknown:false,view:false,viewRev:0,viewCharge:0,owner:0}
  val expected=(if(s.baseHeld)2 else 0)+(if(s.newHeld)2 else 0)+(if(s.reserved)2 else 0)
  val stable=not(s.allocBusy) and not(s.freeBusy) and not(s.sweeping)
  val commitReady=s.closed and stable and not(s.reserved) and s.view and
    s.viewRev==s.rev and s.viewCharge==s.charge
  val safe=s.charge==expected and s.charge>=0 and s.charge<=4 and s.refunds<=1 and
    (not(s.published) or (s.newHeld and s.shell)) and
    (not(s.basePublished) or s.baseHeld) and
    (not(s.acquired) or s.newHeld or s.reserved) and
    (not(s.allocBusy) or s.reserved) and
    (not(s.scanning) or (stable and s.closed and s.scanRev==s.rev)) and
    (not(s.freeBusy) or (s.retired and s.baseHeld and not(s.rawPin))) and
    (not(s.rawPin) or s.baseHeld) and
    (not(s.retired) or not(s.basePublished)) and
    (s.owner==0 or (s.closed and not(s.allocBusy) and not(s.reserved)))
  action reserve=all{not(s.attempted),not(s.closed),s.owner==0,not(s.scanning),not(s.sweeping),not(s.freeBusy),
    s'={...s,attempted:true,reserved:true,charge:s.charge+2,rev:s.rev+1}}
  action enterAllocator=all{s.reserved,not(s.allocBusy),not(s.scanning),not(s.sweeping),not(s.allocStopped),
    s'={...s,allocBusy:true}}
  action returnSuccess=all{s.allocBusy,not(s.acquired),not(s.failed),not(s.allocStopped),
    s'={...s,acquired:true,known:true,allocUnknown:false}}
  action returnFailure=all{s.allocBusy,not(s.acquired),not(s.failed),not(s.allocStopped),
    s'={...s,failed:true,known:true,allocUnknown:false}}
  action loseOutcome=all{s.allocBusy,s'={...s,known:false,allocUnknown:true}}
  // External stop/outcome witnesses are premises, not a malloc query facility.
  action proveAllocatorStopped=all{s.allocBusy,s'={...s,allocStopped:true}}
  action witnessSuccess=all{s.allocBusy,s.allocStopped,s.acquired,s'={...s,known:true}}
  action witnessFailure=all{s.allocBusy,s.allocStopped,not(s.acquired),s'={...s,known:true,failed:true}}
  action settleSuccess=all{s.allocBusy,s.known,s.acquired,not(s.failed),
    s'={...s,newHeld:true,reserved:false,allocBusy:false,allocUnknown:false,rev:s.rev+1}}
  action refundFailure=all{s.allocBusy,s.known,s.failed,not(s.acquired),s.refunds==0,
    s'={...s,reserved:false,allocBusy:false,allocUnknown:false,refunds:1,charge:s.charge-2,rev:s.rev+1}}
  action makeShell=all{s.newHeld,not(s.published),not(s.scanning),not(s.sweeping),s'={...s,shell:true}}
  action publish=all{s.newHeld,s.shell,not(s.published),stable,not(s.scanning),
    s'={...s,published:true,rev:s.rev+1}}
  action close=s'={...s,closed:true}
  action capture=all{s.closed,stable,not(s.scanning),s'={...s,view:true,viewRev:s.rev,viewCharge:s.charge}}
  action rebuild=all{s.closed,stable,not(s.scanning),s'={...s,charge:expected}}
  action beginScan=all{s.closed,stable,not(s.scanning),s'={...s,scanning:true,scanRev:s.rev}}
  action endScan=all{s.scanning,s'={...s,scanning:false}}
  action beginSweep=all{s.closed,stable,not(s.scanning),s'={...s,sweeping:true}}
  action retireBase=all{s.sweeping,s.basePublished,not(s.rawPin),
    s'={...s,basePublished:false,retired:true,rev:s.rev+1}}
  action endSweep=all{s.sweeping,s'={...s,sweeping:false}}
  action pinMeta=all{not(s.metaPin),s'={...s,metaPin:true}}
  action dropMeta=all{s.metaPin,s'={...s,metaPin:false}}
  action pinRaw=all{s.basePublished,not(s.retired),not(s.closed),s'={...s,rawPin:true}}
  action dropRaw=all{s.rawPin,s'={...s,rawPin:false}}
  action beginFree=all{s.retired,s.baseHeld,not(s.rawPin),stable,not(s.scanning),s'={...s,freeBusy:true}}
  action loseFree=all{s.freeBusy,s'={...s,freeUnknown:true}}
  action ackFree=all{s.freeBusy,not(s.freeUnknown),
    s'={...s,freeBusy:false,baseHeld:false,charge:s.charge-2,rev:s.rev+1}}
  action commit=all{commitReady,s.owner==0,s'={...s,owner:1}}
  action retryCommit=all{s.owner==1,s'=s}
  action unsafeRefund=s'={...s,charge:s.charge-2,refunds:s.refunds+1}
  action stutter=s'=s
  action step=any{reserve,enterAllocator,returnSuccess,returnFailure,loseOutcome,proveAllocatorStopped,
    witnessSuccess,witnessFailure,settleSuccess,refundFailure,makeShell,publish,close,capture,rebuild,
    beginScan,endScan,beginSweep,retireBase,endSweep,pinMeta,dropMeta,pinRaw,dropRaw,beginFree,
    loseFree,ackFree,commit,retryCommit,stutter}
  action privateBlock=reserve.then(enterAllocator).then(returnSuccess).then(settleSuccess)
  action ready=privateBlock.then(makeShell).then(publish)
  action retired=close.then(beginSweep).then(retireBase).then(endSweep)
  run reservedIsNotPhysicalTest=init.then(reserve).then(close).then(beginScan).expect(safe and s.charge==4 and not(s.acquired))
  run acquiredNotPublishedTest=init.then(reserve).then(enterAllocator).then(returnSuccess).expect(safe and s.acquired and not(s.newHeld) and not(s.published))
  run privateBlockChargeTest=init.then(privateBlock).then(close).then(capture).expect(safe and s.charge==4 and not(s.published))
  run successDoesNotDoubleChargeTest=init.then(ready).expect(safe and s.charge==4)
  run knownFailureRefundTest=init.then(reserve).then(enterAllocator).then(returnFailure).then(refundFailure).expect(safe and s.charge==2 and s.refunds==1)
  run unknownSuccessRetainedTest=init.then(reserve).then(enterAllocator).then(returnSuccess).then(loseOutcome).expect(safe and s.charge==4 and s.allocBusy)
  run stopAloneNotOutcomeTest=init.then(reserve).then(enterAllocator).then(loseOutcome).then(proveAllocatorStopped).expect(safe and not(s.known))
  run witnessedSuccessSettlementTest=init.then(reserve).then(enterAllocator).then(returnSuccess).then(loseOutcome).then(proveAllocatorStopped).then(witnessSuccess).then(settleSuccess).expect(safe and s.newHeld)
  run witnessedFailureSettlementTest=init.then(reserve).then(enterAllocator).then(loseOutcome).then(proveAllocatorStopped).then(witnessFailure).then(refundFailure).expect(safe and s.refunds==1)
  run scanBeforePrivatePublicationTest=init.then(privateBlock).then(close).then(beginScan).expect(safe and not(s.published))
  run ownerCommitDuringMarkTest=init.then(ready).then(close).then(capture).then(beginScan).then(commit).then(endScan).expect(safe and s.owner==1)
  run sweepInvalidatesPreparedViewTest=init.then(close).then(capture).then(beginSweep).then(retireBase).then(endSweep).expect(safe and not(commitReady))
  run recaptureAfterSweepTest=init.then(close).then(capture).then(beginSweep).then(retireBase).then(endSweep).then(capture).then(commit).expect(safe and s.owner==1)
  run retiredStillChargedTest=init.then(retired).expect(safe and s.charge==2 and s.baseHeld)
  run freeAckRemovesChargeTest=init.then(retired).then(beginFree).then(ackFree).expect(safe and s.charge==0)
  run unknownFreeRetainsDebtTest=init.then(retired).then(beginFree).then(loseFree).expect(safe and s.freeBusy and s.charge==2)
  run metaPinDoesNotRootPayloadTest=init.then(pinMeta).then(retired).then(beginFree).then(ackFree).expect(safe and s.metaPin and not(s.baseHeld))
  run rawPinBlocksRetireTest=init.then(pinRaw).then(close).then(beginSweep).expect(safe and s.rawPin and s.basePublished)
  run rawPinDrainTest=init.then(pinRaw).then(close).then(dropRaw).then(beginSweep).then(retireBase).then(endSweep).expect(safe and s.retired)
  run rebuildStableInventoryTest=init.then(privateBlock).then(close).then(rebuild).then(capture).then(commit).expect(safe and s.charge==4)
  run repeatedCommitDoesNotRechargeTest=init.then(ready).then(close).then(capture).then(commit).then(retryCommit).expect(safe and s.charge==4)
  run counterOnlyRebuildControlTest=init.then(privateBlock).then(s'={...s,charge:2}).expect(not(safe))
  run unknownRefundControlTest=init.then(reserve).then(enterAllocator).then(loseOutcome).then(unsafeRefund).expect(not(safe))
  run doubleRefundControlTest=init.then(reserve).then(enterAllocator).then(returnFailure).then(refundFailure).then(unsafeRefund).expect(not(safe))
  run acquireThenRefundControlTest=init.then(privateBlock).then(unsafeRefund).expect(not(safe))
  run publicationWithoutShellControlTest=init.then(privateBlock).then(s'={...s,published:true}).expect(not(safe))
  run rawReaderFreeControlTest=init.then(pinRaw).then(s'={...s,baseHeld:false,basePublished:false,charge:0}).expect(not(safe))
  run mutationDuringScanControlTest=init.then(close).then(beginScan).then(s'={...s,rev:s.rev+1}).expect(not(safe))
  run scanDuringFreeControlTest=init.then(retired).then(beginFree).then(s'={...s,scanning:true,scanRev:s.rev}).expect(not(safe))
  run pendingAllocatorCommitControlTest=init.then(reserve).then(enterAllocator).then(close).then(s'={...s,owner:1}).expect(not(safe))
}
