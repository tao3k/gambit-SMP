module constructor_debt_closure {
  // One invocation and one escrow ticket. Other whole-round gates are premises.
  // phase0 absent;1 prepared;2 native call pending;3 native result captured;
  // 4 conversion suspended in GC;5 wrapped/root-slot pending;6 delivered;
  // 7 rollback pending;8 terminal. kind0 accept,1 process,2 message.
  type State={phase:int,kind:int,ticket:bool,payload:bool,profile:bool,
    nativeOnly:bool,rooted:bool,traced:int,epoch:int,generation:int,
    viewGeneration:int,frozen:bool,writer:bool,gateClosed:bool,
    suspended:bool,callbackDepth:int,callbackProtected:bool,metadataKnown:bool,
    nativeUnknown:bool,ownerWaitsGc:bool,gcWaitsOwner:bool,gateHeld:bool,
    seal:bool,permit:bool,consumerRoot:bool,dispositionKnown:bool,
    readers:int,produces:int,wraps:int,deliveries:int,cleanupCalls:int,
    target:int,createdIdentity:int,parentPinned:bool,lateRoot:bool,noticeLost:bool}
  var s:State
  val supportedCut=(s.phase>=3 or (s.phase==2 and (s.nativeOnly or
    (s.suspended and s.callbackDepth==1 and s.callbackProtected))))
  val canSeal=s.ticket and s.profile and s.metadataKnown and s.rooted and
    s.frozen and not(s.writer) and s.gateClosed and s.traced==s.epoch and
    s.viewGeneration==s.generation and supportedCut and not(s.gcWaitsOwner) and
    not(s.gateHeld) and not(s.lateRoot)
  val safe=s.produces<=1 and s.wraps<=1 and s.deliveries<=1 and s.cleanupCalls<=1 and
    (s.phase==0 or s.phase==8 or s.ticket) and
    (not(s.seal) or canSeal) and not(s.ownerWaitsGc and s.gcWaitsOwner) and
    (s.cleanupCalls==0 or (s.target==s.createdIdentity and not(s.nativeUnknown))) and
    (s.deliveries==0 or (s.consumerRoot and s.wraps==1)) and
    (s.phase!=8 or (s.dispositionKnown and s.readers==0)) and
    (not(s.nativeUnknown) or s.ticket) and
    (not(s.seal) or not(s.writer))
  action init=s'={phase:0,kind:0,ticket:false,payload:false,profile:false,
    nativeOnly:false,rooted:false,traced:0,epoch:1,generation:1,viewGeneration:0,
    frozen:false,writer:false,gateClosed:false,suspended:false,callbackDepth:0,
    callbackProtected:false,metadataKnown:true,nativeUnknown:false,
    ownerWaitsGc:false,gcWaitsOwner:false,gateHeld:false,seal:false,permit:false,
    consumerRoot:false,dispositionKnown:false,readers:0,produces:0,wraps:0,
    deliveries:0,cleanupCalls:0,target:0,createdIdentity:17,parentPinned:true,lateRoot:false,noticeLost:false}
  action chooseProcess=all{s.phase==0,s'={...s,kind:1}}
  action chooseMessage=all{s.phase==0,s'={...s,kind:2}}
  action prepare=all{s.phase==0,s'={...s,phase:1,ticket:true,rooted:true,profile:true}}
  action certifyNativeOnly=all{s.phase==1,s'={...s,nativeOnly:true}}
  action invoke=all{s.phase==1,s.ticket,s.rooted,s'={...s,phase:2,produces:1,writer:true}}
  action capture=all{s.phase==2,not(s.frozen),s.callbackDepth==0,not(s.ownerWaitsGc),s'={...s,phase:3,payload:true,nativeUnknown:false,writer:true}}
  action nativeResultDuringGc=all{s.phase==2,s.nativeOnly,s.frozen,s'={...s,phase:3,payload:true,nativeUnknown:false}}
  action outcomeLost=all{s.phase==2,not(s.frozen),s'={...s,nativeUnknown:true}}
  action enterCallback=all{s.phase==2,not(s.gateClosed),not(s.nativeOnly),s.callbackDepth==0,
    s'={...s,callbackDepth:1,callbackProtected:true,suspended:true}}
  action requireGc=all{s.phase==2 or s.phase==3,s'={...s,ownerWaitsGc:true,gateClosed:true,permit:false}}
  action beginConversion=all{s.phase==3,s'={...s,phase:4,ownerWaitsGc:true,gateClosed:true,permit:false}}
  action freeze=all{s.ticket,s.profile,s.metadataKnown,s.rooted,supportedCut,
    s.gateClosed,not(s.gateHeld),s'={...s,frozen:true,writer:false,viewGeneration:s.generation}}
  action scan=all{s.frozen,not(s.writer),s'={...s,traced:s.epoch}}
  action publishSeal=all{canSeal,s'={...s,seal:true}}
  // Reentry consumes the old seal and transfers root custody to the active context.
  action reenter=all{s.seal,canSeal,s'={...s,seal:false,permit:true,ownerWaitsGc:false,
    gateClosed:false,frozen:false,writer:true,traced:0}}
  action returnCallback=all{s.permit,s.suspended,s.callbackDepth==1,
    s'={...s,suspended:false,callbackDepth:0,callbackProtected:false}}
  action reconcileKnown=all{s.permit,s.phase==2,s.nativeUnknown,not(s.suspended),
    s'={...s,phase:3,payload:true,nativeUnknown:false}}
  action completeWrapper=all{s.permit,s.phase==4,s.payload,not(s.nativeUnknown),s.wraps==0,
    s'={...s,phase:5,wraps:1}}
  action registerResult=all{s.phase==5,s.wraps==1,s'={...s,consumerRoot:true}}
  action loseResultNotice=all{s.phase==5,s.consumerRoot,s'={...s,noticeLost:true}}
  action observeResultSlot=all{s.phase==5,s.consumerRoot,s'={...s,noticeLost:false}}
  action deliver=all{s.phase==5,s.permit,s.consumerRoot,s.deliveries==0,
    s'={...s,phase:6,deliveries:1,writer:false}}
  action conversionFailure=all{s.permit,s.phase==4,s.payload,s.wraps==0,
    s'={...s,phase:7,writer:false}}
  action rollback=all{s.phase==7,s.payload,not(s.nativeUnknown),s.cleanupCalls==0,
    s'={...s,cleanupCalls:1,target:s.createdIdentity}}
  action knownDisposed=all{s.phase==7,s.cleanupCalls==1,
    s'={...s,dispositionKnown:true,payload:false}}
  action pinReceipt=all{s.phase==7,s.readers==0,s'={...s,readers:1}}
  action drainReceipt=all{s.readers==1,s'={...s,readers:0}}
  action retire=all{s.phase==7,s.dispositionKnown,s.readers==0,
    s'={...s,phase:8,ticket:false,writer:false}}
  action loseMetadata=all{not(s.seal),not(s.permit),s'={...s,metadataKnown:false}}
  action unsafeGateHeld=all{not(s.seal),s'={...s,gateHeld:true}}
  action retireGeneration=all{not(s.seal),not(s.permit),s'={...s,generation:s.generation+1}}
  action query=s'=s
  action step=any{prepare,certifyNativeOnly,invoke,capture,outcomeLost,enterCallback,
    requireGc,beginConversion,nativeResultDuringGc,freeze,scan,publishSeal,reenter,returnCallback,
    reconcileKnown,completeWrapper,registerResult,loseResultNotice,observeResultSlot,deliver,conversionFailure,
    rollback,knownDisposed,pinReceipt,drainReceipt,retire,loseMetadata,
    unsafeGateHeld,retireGeneration,query}
  action nativeReady=prepare.then(invoke).then(capture).then(beginConversion)
  action knownSeal=nativeReady.then(freeze).then(scan).then(publishSeal)
  action nativeUnknownReady=prepare.then(certifyNativeOnly).then(invoke).then(outcomeLost).then(requireGc)
  action callbackReady=prepare.then(invoke).then(enterCallback).then(requireGc)
  action unsafeWait=s'={...s,gcWaitsOwner:true}
  action unsafeSeal=s'={...s,seal:true}
  action unsafeDrop=s'={...s,ticket:false}
  action unsafeReplay=s'={...s,produces:s.produces+1}
  action unsafeCleanupParent=s'={...s,cleanupCalls:1,target:99}
  action unsafeLateRoot=s'={...s,writer:true,lateRoot:true}
  action unsafeDeliver=s'={...s,phase:6,deliveries:1}
  action unsafeDuplicate=s'={...s,wraps:s.wraps+1}
  action unsafeRetire=s'={...s,phase:8,ticket:false}
  action unsafeCleanupReplay=s'={...s,cleanupCalls:s.cleanupCalls+1}
  action unsafeUnknownCleanup=s'={...s,cleanupCalls:1,target:s.createdIdentity}
  run escrowBeforeNativeTest=init.then(prepare).expect(safe and s.ticket and s.rooted)
  run conversionCanResumeWhileBusinessPendingTest=init.then(knownSeal).expect(safe and s.phase==4 and s.wraps==0 and s.ownerWaitsGc)
  run gcDoesNotWaitForOwnerCompletionTest=init.then(knownSeal).then(reenter).expect(safe and s.permit and s.phase==4)
  run successfulResultRootThenDeliveryTest=init.then(knownSeal).then(reenter).then(completeWrapper).then(registerResult).then(deliver).expect(safe and s.deliveries==1 and s.ticket)
  run acceptFailureCleansClientTest=init.then(knownSeal).then(reenter).then(conversionFailure).then(rollback).expect(safe and s.target==17 and s.parentPinned)
  run processFailureRetainsExactDutyTest=init.then(chooseProcess).then(knownSeal).then(reenter).then(conversionFailure).expect(safe and s.ticket and s.kind==1)
  run messageFailureDoesNotReplayReadTest=init.then(chooseMessage).then(knownSeal).then(reenter).then(conversionFailure).then(rollback).expect(safe and s.produces==1)
  run isolatedUnknownCanSealTest=init.then(nativeUnknownReady).then(freeze).then(scan).then(publishSeal).expect(safe and s.nativeUnknown and s.ticket)
  run isolatedUnknownReentryAllowsQueryOnlyTest=init.then(nativeUnknownReady).then(freeze).then(scan).then(publishSeal).then(reenter).then(query).expect(safe and s.phase==2 and s.wraps==0)
  run knownReconciliationDoesNotReplayTest=init.then(nativeUnknownReady).then(freeze).then(scan).then(publishSeal).then(reenter).then(reconcileKnown).expect(safe and s.produces==1 and not(s.nativeUnknown))
  run nativeResultAfterFreezeKeepsRootViewTest=init.then(nativeUnknownReady).then(freeze).then(scan).then(publishSeal).then(nativeResultDuringGc).expect(safe and s.seal and s.payload)
  run managedUnknownCannotSealTest=init.then(prepare).then(invoke).then(outcomeLost).then(requireGc).expect(safe and not(supportedCut) and not(canSeal))
  run suspendedCallbackMayParticipateTest=init.then(callbackReady).then(freeze).then(scan).then(publishSeal).expect(safe and s.callbackDepth==1)
  run callbackReturnsAfterReentryTest=init.then(callbackReady).then(freeze).then(scan).then(publishSeal).then(reenter).then(returnCallback).then(capture).expect(safe and s.phase==3)
  run missingCurrentTraceBlocksSealTest=init.then(nativeReady).then(freeze).expect(safe and not(canSeal))
  run lostMetadataBlocksSealTest=init.then(nativeReady).then(loseMetadata).expect(safe and not(canSeal))
  run heldGateBlocksSealTest=init.then(nativeReady).then(unsafeGateHeld).expect(safe and not(canSeal))
  run staleGenerationBlocksSealTest=init.then(nativeReady).then(freeze).then(scan).then(retireGeneration).expect(safe and not(canSeal))
  run terminalReceiptRetainsBudgetTest=init.then(knownSeal).then(reenter).then(conversionFailure).then(rollback).then(knownDisposed).then(pinReceipt).expect(safe and s.ticket)
  run physicalDispositionAndDrainPermitRefundTest=init.then(knownSeal).then(reenter).then(conversionFailure).then(rollback).then(knownDisposed).then(pinReceipt).then(drainReceipt).then(retire).expect(safe and not(s.ticket))
  run completedWrapperLostNoticeQueriesSlotTest=init.then(knownSeal).then(reenter).then(completeWrapper).then(registerResult).then(loseResultNotice).then(observeResultSlot).then(deliver).expect(safe and s.wraps==1 and s.deliveries==1)
  run cleanupUnknownRetainsDutyTest=init.then(knownSeal).then(reenter).then(conversionFailure).then(rollback).then(query).expect(safe and not(s.dispositionKnown) and s.ticket)
  run cleanupReplayCounterexampleTest=init.then(knownSeal).then(reenter).then(conversionFailure).then(rollback).then(unsafeCleanupReplay).expect(not(safe))
  run waitingOwnerCounterexampleTest=init.then(nativeReady).then(unsafeWait).expect(not(safe))
  run rawPendingSealCounterexampleTest=init.then(prepare).then(invoke).then(requireGc).then(unsafeSeal).expect(not(safe))
  run unknownTicketDropCounterexampleTest=init.then(nativeUnknownReady).then(unsafeDrop).expect(not(safe))
  run producerReplayCounterexampleTest=init.then(nativeUnknownReady).then(unsafeReplay).expect(not(safe))
  run parentInsteadOfClientCounterexampleTest=init.then(knownSeal).then(reenter).then(conversionFailure).then(unsafeCleanupParent).expect(not(safe))
  run resultWithoutRootCounterexampleTest=init.then(knownSeal).then(reenter).then(completeWrapper).then(unsafeDeliver).expect(not(safe))
  run lateManagedPublicationCounterexampleTest=init.then(knownSeal).then(unsafeLateRoot).expect(not(safe))
  run duplicateWrapperCounterexampleTest=init.then(knownSeal).then(reenter).then(completeWrapper).then(unsafeDuplicate).expect(not(safe))
  run unknownNativeCleanupCounterexampleTest=init.then(nativeUnknownReady).then(unsafeUnknownCleanup).expect(not(safe))
  run retireBeforeDispositionCounterexampleTest=init.then(knownSeal).then(reenter).then(conversionFailure).then(unsafeRetire).expect(not(safe))
}
