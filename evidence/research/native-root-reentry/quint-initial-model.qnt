module native_root_reentry {
  // mode0 managed;1 preparing;2 frozen native;3 reentry request;4 granted/reload;5 managed callback.
  // Two canonical root cells abstract an exported register and an RC root; frame/denv coverage is a premise.
  type State={mode:int,epoch:int,ack:int,scan:bool,relocated:bool,worker:int,
    cells:int,locals:int,rev:int,viewRev:int,viewSeq:int,parentSeq:int,
    spills:bool,writers:int,borrow:int,valid:bool,unknown:bool,outcomeUnknown:bool,
    active:bool,depth:int,outerPinned:bool,callbackPending:bool,callbackRooted:bool,
    leaving:bool,resultReady:bool,binding:bool,escaped:bool,retired:bool}
  var s:State
  action init=s'={mode:0,epoch:0,ack:0,scan:false,relocated:false,worker:0,
    cells:0,locals:0,rev:0,viewRev:0,viewSeq:0,parentSeq:0,
    spills:false,writers:0,borrow:0,valid:false,unknown:false,outcomeUnknown:false,
    active:true,depth:1,outerPinned:false,callbackPending:false,callbackRooted:false,
    leaving:false,resultReady:false,binding:true,escaped:false,retired:false}
  val managed=s.mode==0 or s.mode==5
  val scanReady=s.mode==2 and s.valid and s.viewRev==s.rev and s.writers==0 and s.borrow==0 and not(s.unknown) and not(s.scan) and not(s.active)
  val grantReady=s.mode==3 and s.valid and not(s.scan) and s.ack==s.epoch and s.cells==s.epoch and not(s.unknown) and s.binding and (s.callbackPending or s.resultReady)
  val safe=not(s.escaped) and
    (not(s.scan) or ((s.mode==2 or s.mode==3) and not(s.active) and s.valid and s.writers==0 and s.borrow==0 and not(s.unknown))) and
    (not(managed) or (s.active and s.locals==s.cells and s.cells==s.epoch and not(s.scan))) and
    (s.mode!=4 or (s.active and not(s.scan) and s.ack==s.epoch and s.cells==s.epoch)) and
    (not(s.active) or not(s.scan)) and
    (not(s.retired) or (not(s.scan) and s.active and managed)) and
    (s.depth!=2 or (s.outerPinned and s.callbackRooted))
  action registerBorrow=all{managed,s.borrow==0,s'={...s,borrow:1}}
  action dropBorrow=all{s.borrow==1,s'={...s,borrow:0}}
  action registerWriter=all{managed,s.writers==0,s'={...s,writers:1}}
  action writerDone=all{s.writers==1,s'={...s,writers:0,rev:s.rev+1}}
  action mutateRc=all{managed,s'={...s,rev:s.rev+1}}
  action prepare=all{managed,s'={...s,mode:1,spills:false,valid:false,retired:false,active:true}}
  action prepareCallbackExit=all{s.mode==5,s.depth==2,s.resultReady,
    s'={...s,mode:1,spills:false,valid:false,retired:false,leaving:true,active:true}}
  action spill=all{s.mode==1,s'={...s,spills:true,cells:s.locals}}
  // Publication and active-ack membership transfer are ONE phase-gate step.
  action publishFrozen=all{s.mode==1,s.spills,s.writers==0,s.borrow==0,not(s.unknown),
    s'={...s,mode:2,valid:true,viewRev:s.rev,viewSeq:s.viewSeq+1,active:false,
      depth:if(s.leaving)1 else s.depth,callbackRooted:if(s.leaving)false else s.callbackRooted,
      outerPinned:if(s.leaving)false else s.outerPinned,leaving:false,callbackPending:false}}
  action claimScan=all{scanReady,s.epoch<2,
    s'={...s,epoch:s.epoch+1,scan:true,relocated:false,worker:2}}
  action relocate=all{s.scan,not(s.relocated),s'={...s,cells:s.epoch,relocated:true}}
  action finishScan=all{s.scan,s.relocated,s'={...s,scan:false,ack:s.epoch}}
  action nativeResult=all{s.mode==2 or s.mode==3,s'={...s,resultReady:true,outcomeUnknown:false}}
  action loseNativeOutcome=all{s.mode==2,s'={...s,outcomeUnknown:true,resultReady:false}}
  action markUnknownWriter=all{s.mode==2,not(s.scan),s'={...s,unknown:true}}
  action requestReturn=all{s.mode==2,s'={...s,mode:3,callbackPending:false}}
  action requestCallback=all{s.mode==2,s.depth==1,s'={...s,mode:3,callbackPending:true,parentSeq:s.viewSeq}}
  action grantMutator=all{grantReady,s'={...s,mode:4,active:true}}
  // Proc/result slots rooted after permission, BEFORE callback marker allocation.
  action protectCallback=all{s.mode==4,s.callbackPending,s'={...s,callbackRooted:true}}
  action reload=all{s.mode==4,not(s.callbackPending),s'={...s,mode:if(s.depth==1)0 else 5,locals:s.cells,retired:true,valid:false}}
  action enterCallback=all{s.mode==4,s.callbackPending,s.callbackRooted,
    s'={...s,mode:5,depth:2,outerPinned:true,locals:s.cells,retired:true,valid:false,callbackPending:false}}
  action retireMetadata=all{managed,s.retired,s'=s}
  action stutter=s'=s
  action step=any{registerBorrow,dropBorrow,registerWriter,writerDone,mutateRc,prepare,prepareCallbackExit,spill,
    publishFrozen,claimScan,relocate,finishScan,nativeResult,loseNativeOutcome,markUnknownWriter,requestReturn,
    requestCallback,grantMutator,protectCallback,reload,enterCallback,retireMetadata,stutter}
  action freeze=prepare.then(spill).then(publishFrozen)
  action scanOne=claimScan.then(relocate).then(finishScan)
  action callback=freeze.then(requestCallback).then(grantMutator).then(protectCallback).then(enterCallback)
  action resume= nativeResult.then(requestReturn).then(grantMutator).then(reload)
  action unsafeFrozen=s'={...s,mode:2,active:false,valid:true,viewRev:s.rev}
  action unsafeResume=s'={...s,mode:0,active:true,valid:false}
  action unsafeRcWrite=s'={...s,rev:s.rev+1,unknown:true}
  action unsafeDropImage=s'={...s,valid:false,retired:true}
  action unsafeCallback=s'={...s,mode:5,depth:2,active:true,outerPinned:true,callbackRooted:false}
  run publishTransfersAckDutyTest=init.then(freeze).expect(safe and not(s.active) and s.valid)
  run unspilledCannotPublishWitnessTest=init.then(prepare).expect(safe and not(s.spills))
  run writerDebtMustDrainTest=init.then(registerWriter).then(prepare).then(spill).expect(safe and s.writers==1)
  run writerDrainThenPublishTest=init.then(registerWriter).then(prepare).then(writerDone).then(spill).then(publishFrozen).expect(safe and s.valid)
  run rawBorrowMustDrainTest=init.then(registerBorrow).then(prepare).then(spill).expect(safe and s.borrow==1)
  run rawBorrowDrainTest=init.then(registerBorrow).then(prepare).then(spill).then(dropBorrow).then(publishFrozen).expect(safe and s.valid)
  run workerIndependentOfContextTest=init.then(freeze).then(scanOne).expect(safe and s.worker==2 and s.epoch==1)
  run collectorMayWriteFrozenCellsTest=init.then(freeze).then(scanOne).expect(safe and s.cells==1 and s.locals==0)
  run rawOutcomeUnknownStillScannableTest=init.then(freeze).then(loseNativeOutcome).then(scanOne).expect(safe and s.outcomeUnknown)
  run unknownWriterRefusesScanTest=init.then(freeze).then(markUnknownWriter).expect(safe and not(scanReady))
  run unknownWriterRefusesReturnTest=init.then(freeze).then(nativeResult).then(markUnknownWriter).then(requestReturn).expect(safe and not(grantReady))
  run returnWaitsForScanTest=init.then(freeze).then(claimScan).then(nativeResult).then(requestReturn).expect(safe and not(grantReady))
  run scanCompletesRequestedReturnTest=init.then(freeze).then(claimScan).then(nativeResult).then(requestReturn).then(relocate).then(finishScan).then(grantMutator).then(reload).expect(safe and s.locals==1)
  run repeatedCollectionsUpdateSameCellsTest=init.then(freeze).then(scanOne).then(scanOne).then(resume).expect(safe and s.locals==2)
  run reentryBlocksNewScanTest=init.then(freeze).then(nativeResult).then(requestReturn).expect(safe and not(scanReady))
  run permitProtectsReloadWindowTest=init.then(freeze).then(scanOne).then(nativeResult).then(requestReturn).then(grantMutator).expect(safe and s.mode==4 and s.active and not(scanReady))
  run reloadUsesRelocatedCellsTest=init.then(freeze).then(scanOne).then(resume).expect(safe and s.locals==s.cells)
  run metadataRetiresAfterReloadTest=init.then(freeze).then(scanOne).then(resume).then(retireMetadata).expect(safe and s.retired)
  run callbackAcquiresBeforeManagedReadTest=init.then(freeze).then(requestCallback).then(grantMutator).then(protectCallback).then(enterCallback).expect(safe and s.mode==5 and s.depth==2)
  run callbackAfterRelocationTest=init.then(freeze).then(scanOne).then(requestCallback).then(grantMutator).then(protectCallback).then(enterCallback).expect(safe and s.locals==1)
  run outerRootsRemainPinnedTest=init.then(callback).then(freeze).then(scanOne).expect(safe and s.depth==2 and s.outerPinned)
  run nestedNativeReturnsToCallbackTest=init.then(callback).then(freeze).then(scanOne).then(resume).expect(safe and s.mode==5 and s.depth==2)
  run callbackExitPublishesFreshParentTest=init.then(callback).then(mutateRc).then(nativeResult).then(prepareCallbackExit).then(spill).then(publishFrozen).expect(safe and s.depth==1 and s.viewSeq>s.parentSeq and s.viewRev==s.rev)
  run callbackParentMayScanAgainTest=init.then(callback).then(nativeResult).then(prepareCallbackExit).then(spill).then(publishFrozen).then(scanOne).then(resume).expect(safe and s.mode==0 and s.locals==1)
  run rcBeforeFreezeIncludedTest=init.then(mutateRc).then(freeze).then(scanOne).expect(safe and s.viewRev==s.rev)
  run publicationWithBorrowCounterexampleTest=init.then(registerBorrow).then(prepare).then(spill).then(unsafeFrozen).then(claimScan).expect(not(safe))
  run staleLocalsCounterexampleTest=init.then(freeze).then(scanOne).then(unsafeResume).expect(not(safe))
  run foreignWriteDuringScanCounterexampleTest=init.then(freeze).then(claimScan).then(unsafeRcWrite).expect(not(safe))
  run earlyImageDropCounterexampleTest=init.then(freeze).then(claimScan).then(unsafeDropImage).expect(not(safe))
  run callbackBeforeRootProtectionCounterexampleTest=init.then(freeze).then(requestCallback).then(grantMutator).then(unsafeCallback).expect(not(safe))
}
