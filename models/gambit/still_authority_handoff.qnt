module still_authority_handoff {
  // One canonical still domain, two writers, one pending grant, one borrower,
  // one pinned reader, two owner generations, four abstract physical words.
  // Valid shell/root snapshot/store integrity are admission premises.
  type State={open:bool,grant:bool,writers:int,borrowers:int,closed:bool,
    stopped:bool,rawJoin:int,receiptGeneration:int,joinConsumed:bool,stopReceipt:bool,unknown:bool,integral:bool,
    roots:bool,parked:bool,prepared:bool,owner:int,commitKnown:bool,
    sourceAlias:bool,readers:int,backing:bool,booked:int,deferred:int,
    scan:bool,oldScan:bool,cleaned:bool,mutations:int}
  var s:State
  action init=s'={open:true,grant:false,writers:0,borrowers:0,closed:false,
    stopped:false,rawJoin:999,receiptGeneration:0,joinConsumed:false,stopReceipt:false,unknown:false,integral:true,
    roots:true,parked:false,prepared:false,owner:0,commitKnown:false,
    sourceAlias:true,readers:0,backing:true,booked:2,deferred:2,
    scan:false,oldScan:false,cleaned:false,mutations:0}
  val quiet=not(s.grant) and s.writers==0 and s.borrowers==0
  val gcReady=s.closed and quiet and s.parked and s.roots and s.backing
  val cleanupReady=s.owner==1 and s.commitKnown and not(s.sourceAlias) and
    s.closed and quiet and s.parked and s.roots and s.backing and s.readers==0
  val safe=s.writers>=0 and s.writers<=2 and s.borrowers>=0 and s.borrowers<=1 and
    s.readers>=0 and s.readers<=1 and s.booked>=0 and s.deferred>=0 and
    s.booked+s.deferred==4 and s.backing and
    (not(s.closed) or (not(s.open) and quiet and s.integral)) and
    (s.owner==0 or (s.closed and s.prepared and s.roots and s.parked)) and
    (not(s.scan) or (gcReady and (not(s.oldScan) or s.readers==1))) and
    (not(s.cleaned) or cleanupReady) and
    (not(s.stopReceipt) or (s.stopped and s.joinConsumed and s.rawJoin==0 and s.receiptGeneration==0))
  action reserve=all{s.open,not(s.grant),s.writers<2,not(s.stopped),
    s'={...s,grant:true}}
  action admit=all{s.open,s.grant,not(s.stopped),s.writers<2,
    s'={...s,grant:false,writers:s.writers+1}}
  action withdraw=all{s.grant,s'={...s,grant:false}}
  action closeIngress=s'={...s,open:false}
  action write=all{s.writers>0,not(s.stopped),not(s.closed),not(s.scan),s.mutations<3,
    s'={...s,mutations:s.mutations+1}}
  action finishWriter=all{s.writers>0,not(s.stopped),s'={...s,writers:s.writers-1}}
  action borrow=all{s.open,not(s.stopped),s.borrowers==0,s'={...s,borrowers:1}}
  action leaveBorrow=all{s.borrowers==1,s'={...s,borrowers:0}}
  action failJoin=all{not(s.joinConsumed),s'={...s,rawJoin:5,unknown:true}}
  action joinSuccess=all{not(s.joinConsumed),
    s'={...s,stopped:true,rawJoin:0,joinConsumed:true,stopReceipt:true}}
  action loseJoinSuccess=all{not(s.joinConsumed),
    s'={...s,stopped:true,rawJoin:0,joinConsumed:true,stopReceipt:false,unknown:true}}
  // Cooperative closure needs no native join: all operation access is drained.
  action closeCooperatively=all{not(s.open),quiet,s.integral,s'={...s,closed:true}}
  // Authenticated target stop does not discharge independent borrowers/grants.
  action reconcileStopped=all{not(s.open),s.stopReceipt,not(s.grant),s.borrowers==0,s.integral,
    s'={...s,writers:0,closed:true}}
  action park=all{s.closed,s.roots,s'={...s,parked:true}}
  action prepare=all{s.closed,s.parked,s.roots,s.owner==0,s'={...s,prepared:true}}
  action reject=all{s.owner==0,s.prepared,s'={...s,prepared:false}}
  // Ownership changes on the canonical descriptor, not an unlink/link pair.
  action commit=all{s.owner==0,s.prepared,s.closed,s.parked,s.roots,
    s'={...s,owner:1,commitKnown:true}}
  action commitLost=all{s.owner==0,s.prepared,s.closed,s.parked,s.roots,
    s'={...s,owner:1,commitKnown:false,unknown:true}}
  action queryOwner=all{s.owner==1,s'={...s,commitKnown:true}}
  action detach=all{s.owner==1,s.commitKnown,s'={...s,sourceAlias:false}}
  action pinReader=all{gcReady,s.readers==0,s.sourceAlias,not(s.cleaned),s'={...s,readers:1}}
  action dropReader=all{s.readers==1,not(s.scan),s'={...s,readers:0}}
  action beginScan=all{gcReady,s.readers==1,s'={...s,scan:true,oldScan:true}}
  action beginCanonicalScan=all{gcReady,s'={...s,scan:true,oldScan:false}}
  action endScan=all{s.scan,s'={...s,scan:false}}
  action foldAccounting=all{s.closed,s'={...s,booked:s.booked+s.deferred,deferred:0}}
  action cleanup=all{cleanupReady,s'={...s,cleaned:true}}
  action retryCommit=all{s.owner==1,s'=s}
  action stutter=s'=s
  action step=any{reserve,admit,withdraw,closeIngress,write,finishWriter,borrow,leaveBorrow,
    failJoin,joinSuccess,loseJoinSuccess,closeCooperatively,reconcileStopped,park,prepare,reject,
    commit,commitLost,queryOwner,detach,pinReader,dropReader,beginScan,beginCanonicalScan,endScan,foldAccounting,cleanup,retryCommit,stutter}
  action oneWriter=reserve.then(admit)
  action sealed=closeIngress.then(closeCooperatively).then(park)
  action handed=sealed.then(prepare).then(commit).then(detach)
  action unsafeDropBacking=s'={...s,backing:false}
  run precloseGrantRetainedTest=init.then(reserve).then(closeIngress).expect(safe and s.grant and not(quiet))
  run precloseGrantWithdrawTest=init.then(reserve).then(closeIngress).then(withdraw).then(closeCooperatively).expect(safe and s.closed)
  run existingWriterCanFinishTest=init.then(oneWriter).then(closeIngress).then(write).then(finishWriter).then(closeCooperatively).expect(safe)
  run borrowerBlocksStopTest=init.then(oneWriter).then(borrow).then(closeIngress).then(joinSuccess).expect(safe and not(quiet) and not(s.closed))
  run stoppedWriterReconciledTest=init.then(oneWriter).then(closeIngress).then(joinSuccess).then(reconcileStopped).then(park).expect(safe and gcReady)
  run borrowerDrainThenStopTest=init.then(oneWriter).then(borrow).then(closeIngress).then(joinSuccess).then(leaveBorrow).then(reconcileStopped).then(park).expect(safe and gcReady)
  run failedJoinBlocksTest=init.then(oneWriter).then(closeIngress).then(failJoin).expect(safe and not(gcReady))
  run lostSuccessfulJoinBlocksTest=init.then(oneWriter).then(closeIngress).then(loseJoinSuccess).expect(safe and s.stopped and not(s.stopReceipt) and not(gcReady))
  run lostJoinAfterWriteClosureTest=init.then(sealed).then(loseJoinSuccess).expect(safe and gcReady and not(s.stopReceipt))
  run normalTransferTest=init.then(handed).then(cleanup).expect(safe and s.backing and s.owner==1)
  run rejectedTransferRetainsTest=init.then(sealed).then(prepare).then(reject).expect(safe and s.owner==0 and s.sourceAlias)
  run unknownCommitRetainsTest=init.then(sealed).then(prepare).then(commitLost).expect(safe and s.sourceAlias and s.backing and not(cleanupReady))
  run queryUnknownCommitTest=init.then(sealed).then(prepare).then(commitLost).then(queryOwner).then(detach).then(cleanup).expect(safe)
  run repeatCommitIsQueryTest=init.then(handed).then(retryCommit).expect(safe and s.booked+s.deferred==4)
  run readerAcrossTransferTest=init.then(sealed).then(pinReader).then(prepare).then(commit).then(detach).expect(safe and not(cleanupReady))
  run readerDrainThenCleanupTest=init.then(sealed).then(pinReader).then(prepare).then(commit).then(detach).then(dropReader).then(cleanup).expect(safe)
  run scanAcrossOwnerChangeTest=init.then(sealed).then(pinReader).then(beginScan).then(prepare).then(commit).then(endScan).expect(safe and s.owner==1)
  run accountingFoldBeforeTransferTest=init.then(sealed).then(foldAccounting).then(prepare).then(commit).expect(safe and s.booked==4 and s.deferred==0)
  run accountingFoldAfterTransferTest=init.then(handed).then(foldAccounting).expect(safe and s.booked==4)
  run grantAfterCloseControlTest=init.then(closeIngress).then(s'={...s,grant:true,closed:true}).expect(not(safe))
  run closeWithWriterControlTest=init.then(oneWriter).then(closeIngress).then(s'={...s,closed:true}).expect(not(safe))
  run stopWithBorrowerControlTest=init.then(borrow).then(closeIngress).then(joinSuccess).then(s'={...s,closed:true}).expect(not(safe))
  run joinWithoutQuiescenceControlTest=init.then(oneWriter).then(closeIngress).then(joinSuccess).then(s'={...s,parked:true,scan:true,readers:1}).expect(not(safe))
  run unknownWriterScanControlTest=init.then(oneWriter).then(closeIngress).then(failJoin).then(s'={...s,scan:true,readers:1}).expect(not(safe))
  run earlySourceCleanupControlTest=init.then(sealed).then(s'={...s,cleaned:true,backing:false}).expect(not(safe))
  run readerCleanupControlTest=init.then(sealed).then(pinReader).then(prepare).then(commit).then(detach).then(s'={...s,cleaned:true}).expect(not(safe))
  run rootlessTransferControlTest=init.then(sealed).then(prepare).then(s'={...s,owner:1,roots:false}).expect(not(safe))
  run duplicateAccountingControlTest=init.then(handed).then(s'={...s,booked:4,deferred:2}).expect(not(safe))
  run omittedDeferredControlTest=init.then(handed).then(s'={...s,deferred:0}).expect(not(safe))
  run nextGcAfterPstateCleanupTest=init.then(handed).then(cleanup).then(beginCanonicalScan).then(foldAccounting).then(endScan).expect(safe and s.cleaned and s.owner==1)
  run nestedWritersDrainTest=init.then(oneWriter).then(oneWriter).then(closeIngress).then(finishWriter).then(finishWriter).then(closeCooperatively).expect(safe and s.closed)
  run staleStopReceiptControlTest=init.then(closeIngress).then(joinSuccess).then(s'={...s,receiptGeneration:1}).expect(not(safe))
  run rawJoinErrorReceiptControlTest=init.then(closeIngress).then(joinSuccess).then(s'={...s,rawJoin:5}).expect(not(safe))
  run callbackReopenControlTest=init.then(sealed).then(s'={...s,open:true}).expect(not(safe))
}
