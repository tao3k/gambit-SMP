// Existing invocation, four logical arguments; zero/one required argument, bounded native duties.
// This is completion-before-collection, not arbitrary partial-frame stack scanning.
module rest_frame_park_cut {
  type S={phase:int,req:int,left:int,rest:List[int],pairs:int,vec:Set[int],packed:bool,
    frame:bool,mapped:bool,localLease:bool,capacity:bool,gate:bool,borrow:bool,writer:bool,unknown:bool,
    generation:int,spill:int,offer:bool,accepted:bool,ack:bool,vm:bool,scan:bool,scanDone:bool,
    rootVersion:int,reload:int,round:bool,ctx:bool,bound:bool,epoch:int,permit:bool,
    exitWanted:bool,mode:int,normalClaims:int,exitClaims:int,body:int,sentinel:bool,
    nativeLive:bool,starts:int,lost:bool}
  var s:S
  // phase0 repair,1 vector partial,2 packed,3 full-frame,4 spilled,5 offered,6 accepted/scan,7 scanned,8 next epoch,9 restored/exit.
  action init=s'={phase:0,req:0,left:3,rest:[3],pairs:1,vec:Set(),packed:false,
    frame:false,mapped:false,localLease:true,capacity:true,gate:true,borrow:false,writer:false,unknown:false,
    generation:0,spill:-1,offer:false,accepted:false,ack:false,vm:false,scan:false,scanDone:false,
    rootVersion:0,reload:0,round:false,ctx:false,bound:false,epoch:0,permit:true,
    exitWanted:false,mode:0,normalClaims:0,exitClaims:0,body:0,sentinel:false,
    nativeLive:true,starts:1,lost:false}
  action runningInit=init.then(all{s'={...s,req:1,left:2,borrow:true,writer:true}})
  val drained=not(s.borrow) and not(s.writer) and not(s.unknown)
  action close=all{s.gate,s'={...s,gate:false}}
  action consRemaining=all{s.phase==0,s.left>0,s.localLease,s.permit,
    s'={...s,left:s.left-1,rest:[s.req+s.left-1].concat(s.rest),pairs:s.pairs+1}}
  action beginVector=all{s.phase==0,s.left==0,s'={...s,phase:1}}
  action writeRestSlot=all{s.phase==1,not(s.vec.contains(s.req)),s'={...s,vec:s.vec.union(Set(s.req))}}
  action writeRequiredSlot=all{s.phase==1,s.req==1,s.vec.contains(1),not(s.vec.contains(0)),
    s'={...s,vec:s.vec.union(Set(0))}}
  action endVector=all{s.phase==1,s.vec.size()==s.req+1,s'={...s,phase:2,packed:true}}
  // Real Scheme GC helper call saves R0/proc/args and installs mapped return frame.
  action enterFrame=all{s.phase==2,s.packed,s'={...s,phase:3,frame:true,mapped:true}}
  // An old authorized writer may finish after close, before spill/offer; its last effect changes generation.
  action finishOldWriter=all{s.writer,s.phase<=3,s'={...s,writer:false,generation:s.generation+1}}
  action releaseBorrow=all{s.borrow,s.phase<=3,s'={...s,borrow:false}}
  action unknownWrite=all{s.writer,s.phase<=3,s'={...s,unknown:true}}
  action reconcileWrite=all{s.unknown,not(s.writer),s.phase<=3,s'={...s,unknown:false}}
  action requestExit=all{s.mode==0,s'={...s,exitWanted:true}}
  action materialize=all{s.phase==3,s.frame,s.mapped,s.localLease,not(s.gate),drained,
    s'={...s,phase:4,spill:s.generation,permit:false}}
  action publish=all{s.phase==4,s.spill==s.generation,s'={...s,phase:5,offer:true}}
  action accept=all{s.phase==5,s.offer,s.frame,s.mapped,drained,s.nativeLive,
    s'={...s,phase:6,accepted:true,vm:true}}
  action loseAck=all{s.accepted,s'={...s,ack:false}}
  action query=all{s.accepted,s'={...s,ack:true}}
  action claimScan=all{s.phase==6,s.accepted,not(s.scan),not(s.scanDone),s.mode==0,
    s'={...s,scan:true}}
  action relocate=all{s.scan,s.rootVersion==0,s'={...s,rootVersion:1}}
  action finishScan=all{s.scan,s.rootVersion==1,s'={...s,phase:7,scan:false,scanDone:true}}
  action finishRound=all{s.phase==7,s.scanDone,s'={...s,round:true}}
  action prepareContext=all{s.phase==7,s.round,s'={...s,ctx:true}}
  action bindOwner=all{s.phase==7,s.ctx,s.nativeLive,s'={...s,bound:true}}
  action reloadRoots=all{s.phase==7,s.ctx,s.bound,not(s.scan),s'={...s,reload:s.rootVersion}}
  action publishNext=all{s.phase==7,s.round,s.ctx,s.bound,s.reload==s.rootVersion,s'={...s,phase:8,epoch:1}}
  action normalClaim=all{s.phase==8,s.mode==0,not(s.exitWanted),s.nativeLive,s'={...s,mode:1,normalClaims:1,permit:true,accepted:false,offer:false}}
  action exitClaim=all{s.phase==8,s.mode==0,s.exitWanted,s.nativeLive,s'={...s,mode:2,exitClaims:1,permit:true,accepted:false,offer:false}}
  // Reload packed args, set nargs=-1 to bypass GET_REST; do not reconstruct rest pairs or reenter native wrapper.
  action restoreArguments=all{s.phase==8,s.mode==1,s.permit,s.reload==s.rootVersion,
    s'={...s,phase:9,body:1,sentinel:true}}
  action exitGuard=all{s.phase==8,s.mode==2,s.permit,s'={...s,phase:9}}
  action idle=s'=s
  val expected=if(s.req==0) [0,1,2,3] else [1,2,3]
  val prefix=if(s.req==0) [0,1,2,3].slice(0,s.left) else [1,2,3].slice(0,s.left)
  val admitted=all{
    s.req+s.left+s.rest.length()==4,s.pairs==s.rest.length(),prefix.concat(s.rest)==expected,
    s.localLease,s.capacity,s.nativeLive,s.starts==1,not(s.lost),s.body<=1,
    not(s.packed) or (s.left==0 and s.vec.size()==s.req+1),
    not(s.frame) or (s.packed and s.left==0),
    s.phase<4 or (s.frame and s.mapped and drained and not(s.gate) and s.spill==s.generation),
    not(s.offer) or (s.frame and not(s.permit)),
    not(s.accepted) or (s.vm and s.offer and not(s.permit) and s.mode==0),
    not(s.scan) or (s.accepted and s.mode==0 and not(s.permit)),
    s.epoch==0 or (s.scanDone and not(s.scan) and s.round and s.ctx and s.bound and s.reload==s.rootVersion),
    s.phase<4 or not(s.permit) or (s.epoch==1 and s.mode!=0),
    s.normalClaims+s.exitClaims<=1,
    s.mode!=1 or not(s.exitWanted),
    s.mode!=2 or s.exitWanted,
    s.body==0 or (s.mode==1 and s.sentinel and s.epoch==1),
    s.mode!=2 or s.body==0}
  action step=any{close,consRemaining,beginVector,writeRestSlot,writeRequiredSlot,endVector,enterFrame,
    finishOldWriter,releaseBorrow,unknownWrite,reconcileWrite,requestExit,materialize,publish,accept,loseAck,
    query,claimScan,relocate,finishScan,finishRound,prepareContext,bindOwner,reloadRoots,publishNext,
    normalClaim,exitClaim,restoreArguments,exitGuard,idle}
  action repaired=init.then(consRemaining).then(consRemaining).then(consRemaining)
  action framed=repaired.then(beginVector).then(writeRestSlot).then(endVector).then(enterFrame)
  action spilled=framed.then(close).then(materialize)
  action offered=spilled.then(publish)
  action parked=offered.then(accept)
  action scanned=parked.then(claimScan).then(relocate).then(finishScan)
  action ready=scanned.then(finishRound).then(prepareContext).then(bindOwner).then(reloadRoots).then(publishNext)
  action debtFrame=runningInit.then(close).then(consRemaining).then(consRemaining).then(beginVector).then(writeRestSlot).then(writeRequiredSlot).then(endVector).then(enterFrame)
  action badMaterialize=s'={...s,phase:4,spill:s.generation,permit:false}
  action badPack=s'={...s,packed:true,phase:2}
  action badAccept=s'={...s,phase:6,accepted:true,vm:true}
  action badGc=s'={...s,scan:true}
  action badLateWrite=s'={...s,generation:s.generation+1}
  action badLeaseDrop=s'={...s,localLease:false}
  action badReplay=s'={...s,starts:s.starts+1}
  action badNormal=s'={...s,mode:1,normalClaims:s.normalClaims+1,permit:true,accepted:false,offer:false}
  action badExit=s'={...s,mode:2,exitClaims:s.exitClaims+1,accepted:false,offer:false}
  action badRestore=s'={...s,phase:9,body:s.body+1,sentinel:false}
  action badFrame=s'={...s,mapped:false}
  action badNext=s'={...s,phase:8,epoch:1}
  action badRootCache=s'={...s,reload:0}
  action badRecons=s'={...s,pairs:s.pairs+1}
  action badOrder=s'={...s,rest:[3,2,1,0]}
  action badStack=s'={...s,nativeLive:false}
  run originalCallResumeTest=ready.then(normalClaim).then(restoreArguments).then(all{assert(admitted and s.starts==1 and s.pairs==4),s'=s})
  run restOrderPreservedTest=repaired.then(all{assert(s.rest==[0,1,2,3] and admitted),s'=s})
  run localLeaseDuringRepairTest=init.then(close).then(consRemaining).then(all{assert(s.localLease and not(s.frame) and admitted),s'=s})
  run vectorIncompleteStillSourceTest=repaired.then(beginVector).then(all{assert(not(s.packed) and not(s.vm) and admitted),s'=s})
  run frameBeforeParkTest=framed.then(all{assert(s.frame and not(s.accepted) and admitted),s'=s})
  run lateWriterBeforeSpillTest=debtFrame.then(finishOldWriter).then(releaseBorrow).then(materialize).then(all{assert(s.spill==1 and admitted),s'=s})
  run unknownWriteRetainsCustodyTest=runningInit.then(unknownWrite).then(finishOldWriter).then(all{assert(s.unknown and not(s.accepted) and s.localLease and admitted),s'=s})
  run reconciledWriteCanParkTest=runningInit.then(unknownWrite).then(finishOldWriter).then(reconcileWrite).then(releaseBorrow).then(all{assert(admitted),s'=s})
  run lostAckNoReplayTest=parked.then(loseAck).then(query).then(query).then(all{assert(s.starts==1 and s.accepted and admitted),s'=s})
  run collectorUpdatesPackedRootsTest=parked.then(claimScan).then(relocate).then(all{assert(s.rootVersion==1 and s.reload==0 and admitted),s'=s})
  run exitWhilePartialIsPendingTest=init.then(requestExit).then(consRemaining).then(all{assert(s.exitWanted and s.mode==0 and s.localLease and admitted),s'=s})
  run exitWhileScanningWaitsTest=parked.then(claimScan).then(requestExit).then(relocate).then(finishScan).then(finishRound).then(prepareContext).then(bindOwner).then(reloadRoots).then(publishNext).then(exitClaim).then(exitGuard).then(all{assert(s.body==0 and s.exitClaims==1 and admitted),s'=s})
  run exitBeforeAcceptUsesSameAttemptTest=offered.then(requestExit).then(accept).then(all{assert(s.exitWanted and s.mode==0 and admitted),s'=s})
  run fullFixedArgumentProfileTest=debtFrame.then(finishOldWriter).then(releaseBorrow).then(materialize).then(publish).then(accept).then(all{assert(s.req==1 and s.rest==[1,2,3] and admitted),s'=s})
  run partialFrameParkCounterexampleTest=init.then(close).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run partialFrameGcCounterexampleTest=init.then(badGc).then(all{assert(not(admitted)),s'=s})
  run incompleteVectorCounterexampleTest=repaired.then(beginVector).then(badPack).then(all{assert(not(admitted)),s'=s})
  run localLeaseDroppedCounterexampleTest=init.then(badLeaseDrop).then(all{assert(not(admitted)),s'=s})
  run borrowedNativeAliasCounterexampleTest=framed.then(all{s'={...s,borrow:true}}).then(close).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run preCloseWriterStillLiveCounterexampleTest=debtFrame.then(releaseBorrow).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run unknownWriterCannotParkCounterexampleTest=debtFrame.then(all{s'={...s,unknown:true,borrow:false,writer:false}}).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run missingFrameMapCounterexampleTest=framed.then(badFrame).then(close).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run publicationNotAcceptanceCounterexampleTest=offered.then(badGc).then(all{assert(not(admitted)),s'=s})
  run lateWriteAfterReceiptCounterexampleTest=parked.then(badLateWrite).then(all{assert(not(admitted)),s'=s})
  run nativeFrameDeathCounterexampleTest=parked.then(badStack).then(all{assert(not(admitted)),s'=s})
  run scanExitOverlapCounterexampleTest=parked.then(claimScan).then(badExit).then(all{assert(not(admitted)),s'=s})
  run scanNormalOverlapCounterexampleTest=parked.then(claimScan).then(badNormal).then(all{assert(not(admitted)),s'=s})
  run missingWholeRoundCounterexampleTest=scanned.then(badNext).then(all{assert(not(admitted)),s'=s})
  run contextMissingCounterexampleTest=scanned.then(finishRound).then(badNext).then(all{assert(not(admitted)),s'=s})
  run staleRootAfterNextCounterexampleTest=ready.then(badRootCache).then(all{assert(not(admitted)),s'=s})
  run nativeReplayCounterexampleTest=ready.then(normalClaim).then(badReplay).then(all{assert(not(admitted)),s'=s})
  run duplicateRestConsCounterexampleTest=ready.then(normalClaim).then(badRecons).then(all{assert(not(admitted)),s'=s})
  run badRestOrderingCounterexampleTest=repaired.then(badOrder).then(all{assert(not(admitted)),s'=s})
  run nargsSentinelMissingCounterexampleTest=ready.then(normalClaim).then(badRestore).then(all{assert(not(admitted)),s'=s})
  run normalExitBothClaimCounterexampleTest=ready.then(normalClaim).then(badExit).then(all{assert(not(admitted)),s'=s})
  run secondNormalClaimCounterexampleTest=ready.then(normalClaim).then(badNormal).then(all{assert(not(admitted)),s'=s})
  run entryStillOpenCounterexampleTest=framed.then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run missingPhysicalReservationCounterexampleTest=init.then(all{s'={...s,capacity:false}}).then(all{assert(not(admitted)),s'=s})
  run pendingExitMustWinCounterexampleTest=ready.then(requestExit).then(badNormal).then(all{assert(not(admitted)),s'=s})
  run inventedExitCounterexampleTest=ready.then(badExit).then(all{assert(not(admitted)),s'=s})
  action negativeInit=offered
  action negativeStep=badGc
}
