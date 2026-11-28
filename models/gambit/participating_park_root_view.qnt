// One existing native invocation, one root-cell view, one nested/effect/borrow debt, epochs 0/1.
// Source completeness, coherent C atomics, native frame survival and generated safe-point maps are premises.
module participating_park_root_view {
  // phase: running0, closing1, materialized2, offered3, accepted4, scanning5, scanned6, next7, resumed8, done9.
  type S={phase:int,epoch:int,gate:bool,safe:bool,initSafe:bool,effect:int,writer:int,borrow:int,nested:int,
    unknown:bool,materialized:bool,view:bool,accepted:bool,ack:bool,scanner:bool,scanDone:bool,
    roundDone:bool,ctx:bool,bound:bool,version:int,cache:int,permit:bool,stack:bool,roots:bool,
    resource:bool,vm:bool,starts:int,resumes:int,escaped:bool}
  var s:S
  action init=s'={phase:0,epoch:0,gate:true,safe:false,initSafe:true,effect:0,writer:0,borrow:0,nested:0,
    unknown:false,materialized:false,view:false,accepted:false,ack:false,scanner:false,scanDone:false,
    roundDone:false,ctx:false,bound:false,version:0,cache:0,permit:true,stack:true,roots:true,
    resource:true,vm:false,starts:1,resumes:0,escaped:false}
  action runningInit=init.then(all{s'={...s,effect:1,writer:1,borrow:1,nested:1,initSafe:false}})
  action close=all{s.phase==0,s'={...s,phase:1,gate:false}}
  action finishEffect=all{s.phase<=1,s.effect==1,s'={...s,effect:0}}
  action finishWriter=all{s.phase<=1,s.writer==1,s'={...s,writer:0}}
  action releaseBorrow=all{s.phase<=1,s.borrow==1,s'={...s,borrow:0}}
  action exitNested=all{s.phase<=1,s.nested==1,s'={...s,nested:0}}
  action completeInit=all{s.phase<=1,not(s.initSafe),s'={...s,initSafe:true}}
  action enterSafe=all{s.phase==1,s'={...s,safe:true}}
  action outcomeUnknown=all{s.phase<=1,s.effect==1,s'={...s,unknown:true}}
  action resolveOutcome=all{s.phase<=1,s.unknown,s.effect==0,s'={...s,unknown:false}}
  val drained=s.effect==0 and s.writer==0 and s.borrow==0 and s.nested==0 and not(s.unknown)
  // Materialize after last effect; no raw root writer or nested activation can mutate afterward.
  action materialize=all{s.phase==1,s.safe,s.initSafe,drained,s.stack,s.roots,s.resource,
    s'={...s,phase:2,materialized:true,permit:false}}
  // Source still pins backing until canonical VM acceptance; publication is not acceptance.
  action publishView=all{s.phase==2,s.materialized,not(s.permit),s'={...s,phase:3,view:true}}
  action acceptPark=all{s.phase==3,s.view,s.materialized,drained,not(s.permit),s.stack,s.roots,s.resource,
    s'={...s,phase:4,accepted:true,vm:true}}
  action loseResponse=all{s.accepted,s'={...s,ack:false}}
  action query=all{s.accepted,s'={...s,ack:true}}
  // Claim and resume share an exclusion domain; admitted phase forbids the other winner.
  action claimScan=all{s.phase==4,s.accepted,s.vm,not(s.permit),not(s.scanner),
    s'={...s,phase:5,scanner:true}}
  action relocate=all{s.phase==5,s.scanner,s.version==0,s'={...s,version:1}}
  action finishScan=all{s.phase==5,s.scanner,s.version==1,s'={...s,phase:6,scanner:false,scanDone:true}}
  action finishRound=all{s.phase==6,s.scanDone,not(s.scanner),s'={...s,roundDone:true}}
  action prepareContext=all{s.phase==6,s.roundDone,s'={...s,ctx:true}}
  action bindOwner=all{s.phase==6,s.ctx,s.stack,s'={...s,bound:true}}
  action reloadRoots=all{s.phase==6,s.bound,s.ctx,not(s.scanner),s'={...s,cache:s.version}}
  action publishNext=all{s.phase==6,s.roundDone,s.ctx,s.bound,s.scanDone,not(s.scanner),s.cache==s.version,
    s'={...s,phase:7,epoch:1}}
  // This is continuation of the original call, not another call to its entry function.
  action resumeSameCall=all{s.phase==7,s.epoch==1,s.stack,s.accepted,s.vm,s.roundDone,s.ctx,s.bound,
    not(s.scanner),s.scanDone,s.cache==s.version,s.resumes==0,
    s'={...s,phase:8,permit:true,resumes:1,accepted:false,view:false}}
  action completeCall=all{s.phase==8,s.permit,s'={...s,phase:9,permit:false}}
  action retire=all{s.phase==9,not(s.scanner),s'={...s,roots:false,resource:false,stack:false}}
  action idle=s'=s
  val admitted=all{
    s.starts==1,s.resumes<=1,not(s.escaped),
    s.phase==9 or (s.roots and s.resource and s.stack),
    not(s.materialized) or (s.safe and s.initSafe and drained),
    not(s.view) or (s.materialized and not(s.permit)),
    not(s.accepted) or (s.view and s.vm and not(s.permit) and s.stack and drained),
    not(s.scanner) or (s.phase==5 and s.accepted and not(s.permit)),
    not(s.permit) or s.phase<=1 or (s.phase==8 and s.epoch==1 and s.roundDone and s.ctx and s.bound and s.cache==s.version and not(s.scanner)),
    s.phase<7 or (s.epoch==1 and s.scanDone and s.roundDone and s.ctx and s.bound and s.cache==s.version and not(s.scanner)),
    s.phase<2 or not(s.gate)}
  action step=any{close,finishEffect,finishWriter,releaseBorrow,exitNested,completeInit,enterSafe,
    outcomeUnknown,resolveOutcome,materialize,publishView,acceptPark,loseResponse,query,claimScan,
    relocate,finishScan,finishRound,prepareContext,bindOwner,reloadRoots,publishNext,resumeSameCall,completeCall,retire,idle}
  action ready=init.then(close).then(enterSafe).then(materialize)
  action offered=ready.then(publishView)
  action parked=offered.then(acceptPark)
  action scanned=parked.then(claimScan).then(relocate).then(finishScan)
  action prepared=scanned.then(finishRound).then(prepareContext).then(bindOwner).then(reloadRoots)
  action nextEpoch=prepared.then(publishNext)
  action activeDebts=runningInit.then(close).then(enterSafe)
  action settleDebts=finishEffect.then(finishWriter).then(releaseBorrow).then(exitNested).then(completeInit)
  action badAccept=s'={...s,phase:4,accepted:true,vm:true}
  action badMaterialize=s'={...s,phase:2,materialized:true,permit:false}
  action badView=s'={...s,view:true}
  action badWriter=s'={...s,writer:1}
  action badResume=s'={...s,phase:8,epoch:1,permit:true,resumes:s.resumes+1,accepted:false,view:false}
  action badNext=s'={...s,phase:7,epoch:1}
  action badScan=s'={...s,phase:5,scanner:true}
  action badDrop=s'={...s,roots:false,resource:false}
  action badStack=s'={...s,stack:false}
  action badReplay=s'={...s,starts:s.starts+1}
  action badUnknown=s'={...s,unknown:true}
  run completeSameInvocationTest=nextEpoch.then(resumeSameCall).then(completeCall).then(retire).then(all{assert(admitted and s.starts==1 and s.resumes==1),s'=s})
  run sourceOwnsOfferTest=offered.then(all{assert(not(s.vm) and not(s.accepted) and s.roots and admitted),s'=s})
  run acceptedUnknownResponseKeepsDutyTest=parked.then(loseResponse).then(all{assert(s.vm and s.accepted and not(s.ack) and admitted),s'=s})
  run queryDoesNotInvokeTest=parked.then(loseResponse).then(query).then(query).then(all{assert(s.ack and s.starts==1 and admitted),s'=s})
  run collectorMayRewriteFrozenCellTest=parked.then(claimScan).then(relocate).then(all{assert(s.version==1 and s.cache==0 and not(s.permit) and admitted),s'=s})
  run nativeFrameStaysLiveWhileScanningTest=parked.then(claimScan).then(all{assert(s.stack and s.starts==1 and admitted),s'=s})
  run closeDoesNotDrainDebtsTest=activeDebts.then(all{assert(not(drained) and not(s.accepted) and admitted),s'=s})
  run drainBeforeMaterializeTest=activeDebts.then(settleDebts).then(materialize).then(publishView).then(acceptPark).then(all{assert(admitted),s'=s})
  run unresolvedEffectRetainedTest=runningInit.then(outcomeUnknown).then(close).then(enterSafe).then(settleDebts).then(all{assert(s.unknown and not(s.vm) and s.roots and admitted),s'=s})
  run knownEffectCanContinueTest=runningInit.then(outcomeUnknown).then(close).then(enterSafe).then(settleDebts).then(resolveOutcome).then(materialize).then(all{assert(admitted),s'=s})
  run scanReleasePrecedesRoundTest=scanned.then(all{assert(not(s.scanner) and s.scanDone and not(s.roundDone) and admitted),s'=s})
  run freshRootReloadTest=prepared.then(all{assert(s.version==1 and s.cache==1 and admitted),s'=s})
  run oldEpochNotReopenedTest=nextEpoch.then(resumeSameCall).then(all{assert(s.epoch==1 and not(s.gate) and admitted),s'=s})
  run noAckRequiredForCanonicalScanTest=parked.then(loseResponse).then(claimScan).then(relocate).then(finishScan).then(all{assert(not(s.ack) and s.scanDone and admitted),s'=s})
  run unsafePointCounterexampleTest=init.then(close).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run incompleteConstructionCounterexampleTest=init.then(all{s'={...s,initSafe:false}}).then(close).then(enterSafe).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run inFlightEffectCounterexampleTest=init.then(all{s'={...s,effect:1}}).then(close).then(enterSafe).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run rawWriterCounterexampleTest=init.then(all{s'={...s,writer:1}}).then(close).then(enterSafe).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run nativeBorrowCounterexampleTest=init.then(all{s'={...s,borrow:1}}).then(close).then(enterSafe).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run nestedCallbackCounterexampleTest=init.then(all{s'={...s,nested:1}}).then(close).then(enterSafe).then(badMaterialize).then(all{assert(not(admitted)),s'=s})
  run unknownEffectCounterexampleTest=ready.then(badUnknown).then(all{assert(not(admitted)),s'=s})
  run rootViewBeforeMaterializationCounterexampleTest=init.then(close).then(badView).then(all{assert(not(admitted)),s'=s})
  run sourceOfferIsNotReceiptCounterexampleTest=ready.then(badAccept).then(all{assert(not(admitted)),s'=s})
  run lateWriterCounterexampleTest=parked.then(badWriter).then(all{assert(not(admitted)),s'=s})
  run lostAckDoesNotRestorePermitCounterexampleTest=parked.then(loseResponse).then(badResume).then(all{assert(not(admitted)),s'=s})
  run scanAndResumeConflictCounterexampleTest=parked.then(claimScan).then(badResume).then(all{assert(not(admitted)),s'=s})
  run scannedNotWholeRoundCounterexampleTest=scanned.then(badNext).then(all{assert(not(admitted)),s'=s})
  run contextMissingCounterexampleTest=scanned.then(finishRound).then(badNext).then(all{assert(not(admitted)),s'=s})
  run bindingMissingCounterexampleTest=scanned.then(finishRound).then(prepareContext).then(badNext).then(all{assert(not(admitted)),s'=s})
  run staleCachedValueCounterexampleTest=scanned.then(finishRound).then(prepareContext).then(bindOwner).then(badNext).then(all{assert(not(admitted)),s'=s})
  run rootReleaseDuringParkCounterexampleTest=parked.then(badDrop).then(all{assert(not(admitted)),s'=s})
  run catcherFrameGoneCounterexampleTest=parked.then(badStack).then(all{assert(not(admitted)),s'=s})
  run replayInsteadOfResumeCounterexampleTest=nextEpoch.then(resumeSameCall).then(badReplay).then(all{assert(not(admitted)),s'=s})
  run secondResumeCounterexampleTest=nextEpoch.then(resumeSameCall).then(badResume).then(all{assert(not(admitted)),s'=s})
  run lateScannerAfterResumeCounterexampleTest=nextEpoch.then(resumeSameCall).then(badScan).then(all{assert(not(admitted)),s'=s})
  run publicationDoesNotPermitScanTest=offered.then(all{assert(not(s.accepted) and not(s.scanner) and admitted),s'=s})
  action negativeInit=offered
  action negativeStep=badScan
}
