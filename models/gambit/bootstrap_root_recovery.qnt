// One immutable logical request, up to three deliveries, one GC and one restored parent binding.
// Within one live VM only. Complete mapped source, atomic ledger/control and external consumer-drain are premises.
module bootstrap_root_recovery {
 type S={state:int,revision:int,allocations:int,rootsCreated:int,inflight:bool,deliveries:int,
  sourceLease:bool,sourcePin:bool,root:bool,rootEpoch:int,epoch:int,sourceLoaded:int,
  closed:bool,sourceReaders:bool,rootReaders:bool,moved:bool,queryPin:bool,
  observedState:int,observedRevision:int,observedKey:int,ackCount:int,ackKey:int,ackSeenRevision:int,ackCanonicalRevision:int,closing:bool,
  consumer:bool,vmEscrow:bool,parentAlive:bool,naturalFrameMap:bool,frozen:bool,
  rawBorrow:bool,nestedBorrow:bool,parentGen:int,loadedGen:int,parentLoaded:int,newParentPin:bool,
  frontier:bool,purged:bool,needValue:bool,resultAck:bool,rejections:int}
 var s:S
 // state 0 absent; 1 pending; 2 accepted; 3 terminal tombstone. Key is fixed logical identity 0.
 action init=s'={state:0,revision:0,allocations:0,rootsCreated:0,inflight:false,deliveries:0,
  sourceLease:true,sourcePin:true,root:false,rootEpoch:0,epoch:0,sourceLoaded:0,
  closed:false,sourceReaders:false,rootReaders:false,moved:false,queryPin:false,
  observedState:-1,observedRevision:-1,observedKey:0,ackCount:0,ackKey:-1,ackSeenRevision:-1,ackCanonicalRevision:-1,closing:false,
  consumer:false,vmEscrow:false,parentAlive:true,naturalFrameMap:true,frozen:true,
  rawBorrow:false,nestedBorrow:false,parentGen:0,loadedGen:0,parentLoaded:0,newParentPin:false,
  frontier:false,purged:false,needValue:true,resultAck:false,rejections:0}
 action submit=all{not(s.frontier),not(s.inflight),s.deliveries<3,s'={...s,inflight:true,deliveries:s.deliveries+1,observedState:-1}}
 action arrive=all{s.inflight,not(s.frontier),s'={...s,inflight:false,
  state:if(s.state==0)1 else s.state,revision:if(s.state==0)1 else s.revision,
  allocations:s.allocations+(if(s.state==0)1 else 0)}}
 action rejectLateDelivery=all{s.inflight,s.frontier,s'={...s,inflight:false,rejections:s.rejections+1}}
 action rejectExpiredRetry=all{s.frontier,s'={...s,rejections:s.rejections+1}}
 action rejectChangedIntent=all{s.state!=0,s'={...s,rejections:s.rejections+1}}
 action pinQuery=all{s.state!=0,not(s.queryPin),s'={...s,queryPin:true}}
 action readQuery=all{s.queryPin,s'={...s,observedState:s.state,observedRevision:s.revision,observedKey:0}}
 action unpinQuery=all{s.queryPin,s'={...s,queryPin:false}}
 // Absence never certifies that a delayed registration cannot later take effect.
 action queryAbsent=all{s.state==0,not(s.frontier),s'={...s,observedState:0,observedRevision:s.revision,observedKey:0}}
 action queryRetiredFence=all{s.state==0,s.frontier,s'={...s,observedState:3,observedRevision:s.revision,observedKey:0}}
 action replayAckFromFence=all{s.state==0,s.frontier,s.ackCount==1,s'=s}
 action queryWrongKey=all{s.queryPin,s'={...s,observedState:s.state,observedRevision:s.revision,observedKey:1}}
 action accept=all{s.state==1,not(s.closing),not(s.closed),s.frozen,not(s.rawBorrow),not(s.nestedBorrow),s.sourcePin,s.sourceLoaded==s.epoch,
  s'={...s,state:2,revision:s.revision+1,root:true,rootEpoch:s.epoch,rootsCreated:s.rootsCreated+1}}
 action loseReply=all{s.state!=0,s'={...s,observedState:-1}}
 // ACK revalidates canonical state under the control domain. Cached query does not contain a usable SCMOBJ.
 action ackAccepted=all{s.state==2,(not(s.closing) or s.vmEscrow),s.root,s.rootEpoch==s.epoch,s.observedState==2,s.observedKey==0,
  s.observedRevision==s.revision,s.sourceLease,not(s.rawBorrow),not(s.nestedBorrow),
  s'={...s,sourceLease:false,ackCount:s.ackCount+1,ackKey:s.observedKey,ackSeenRevision:s.observedRevision,ackCanonicalRevision:s.revision}}
 action ackTerminal=all{s.state==3,not(s.root),not(s.consumer),s.closing,s.observedState==3,s.observedKey==0,s.observedRevision==s.revision,
  s.sourceLease,not(s.rawBorrow),not(s.nestedBorrow),s'={...s,sourceLease:false,ackCount:s.ackCount+1,ackKey:s.observedKey,ackSeenRevision:s.observedRevision,ackCanonicalRevision:s.revision}}
 action replayAck=all{s.ackCount==1,s.observedKey==0,s.state!=0,s'=s}
 // Logical ACK may precede current source scan completion; physical source pin cannot.
 action releaseSourcePin=all{s.ackCount==1,not(s.sourceLease),s.sourcePin,not(s.sourceReaders),not(s.rawBorrow),not(s.nestedBorrow),s'={...s,sourcePin:false}}
 action closeGC=all{not(s.closed),not(s.moved),s'={...s,closed:true,sourceReaders:s.sourcePin,rootReaders:s.root}}
 action collect=all{s.closed,not(s.moved),s.frozen,not(s.rawBorrow),not(s.nestedBorrow),
  (not(s.sourcePin) or s.sourceReaders),(not(s.root) or s.rootReaders),
  s'={...s,moved:true,epoch:1,rootEpoch:if(s.rootReaders)1 else s.rootEpoch}}
 action finishGC=all{s.closed,s.moved,s'={...s,closed:false,sourceReaders:false,rootReaders:false}}
 action reloadSource=all{not(s.closed),s.sourcePin,s.frozen,not(s.rawBorrow),s'={...s,sourceLoaded:s.epoch}}
 action takeVmCustody=all{s.sourcePin or s.root,s.frozen,not(s.rawBorrow),not(s.nestedBorrow),s'={...s,vmEscrow:true}}
 action exitParent=all{s.parentAlive,s.vmEscrow,s.frozen,not(s.rawBorrow),not(s.nestedBorrow),s'={...s,parentAlive:false,naturalFrameMap:false,closing:true,revision:s.revision+(if(s.state==1 or s.state==2)1 else 0)}}
 // This is same-live-invocation binding restoration, not resurrection of an unwound C stack.
 action restoreParent=all{s.parentAlive,s.parentGen==0,not(s.closed),not(s.sourceReaders),s.frozen,not(s.rawBorrow),not(s.nestedBorrow),
  s'={...s,parentGen:1,newParentPin:true,loadedGen:-1}}
 action reloadParent=all{s.parentAlive,not(s.closed),s.naturalFrameMap,s.frozen,not(s.rawBorrow),not(s.nestedBorrow),
  s'={...s,loadedGen:s.parentGen,parentLoaded:s.epoch}}
 action borrowParent=all{s.parentAlive,s.naturalFrameMap,not(s.closed),s.loadedGen==s.parentGen,s.parentLoaded==s.epoch,
  s'={...s,rawBorrow:true,frozen:false}}
 action freezeParent=all{s.parentAlive,not(s.nestedBorrow),s'={...s,rawBorrow:false,frozen:true}}
 action startNestedBorrow=all{s.parentAlive,s.rawBorrow,s'={...s,nestedBorrow:true}}
 action finishNestedBorrow=all{s.nestedBorrow,s'={...s,nestedBorrow:false}}
 action releaseRestoredPin=all{not(s.parentAlive),not(s.sourceReaders),not(s.rawBorrow),not(s.nestedBorrow),s'={...s,newParentPin:false}}
 action attachConsumer=all{s.state==2,s.root,not(s.closing),not(s.closed),s'={...s,consumer:true}}
 // External full consumer/child stop-and-root-transfer observation. Not implied by run return or lost ACK.
 action observeConsumerDrain=all{s.closing,s.consumer,s'={...s,consumer:false}}
 action closeRequest=all{s.state==1 or s.state==2,not(s.closing),s'={...s,closing:true,revision:s.revision+1}}
 action cancelUnseen=all{s.state==0,not(s.frontier),s'={...s,state:3,closing:true,revision:1,allocations:s.allocations+1,needValue:false}}
 action cancelPending=all{s.state==1,s.closing,s'={...s,state:3,revision:s.revision+1,needValue:false}}
 action retireAccepted=all{s.state==2,s.closing,not(s.consumer),not(s.rootReaders),not(s.closed),s'={...s,state:3,root:false,revision:s.revision+1,needValue:false}}
 // Persistent within-VM admission frontier rejects old key even after tombstone deletion; not a max-seen shortcut.
 action ackTerminalResult=all{s.state==3,s.observedState==3,s.observedKey==0,s.observedRevision==s.revision,s'={...s,resultAck:true}}
 action sealKey=all{s.state==3,s.ackCount==1,not(s.sourcePin),not(s.consumer),s'={...s,frontier:true}}
 action purge=all{s.state==3,s.frontier,s.resultAck,not(s.sourcePin),not(s.sourceReaders),not(s.rootReaders),not(s.queryPin),not(s.inflight),
  s'={...s,state:0,purged:true}}
 action idle=s'=s
 val safe=all{s.allocations<=1,s.rootsCreated<=1,s.ackCount<=1,
  not(s.sourceLease) or s.sourcePin,
  s.parentAlive or (s.vmEscrow and s.closing),
  s.ackCount==0 or (s.ackKey==0 and s.ackSeenRevision==s.ackCanonicalRevision),
  not(s.needValue) or s.sourcePin or s.root,
  not(s.root) or (s.state==2 and s.rootEpoch==s.epoch),
  not(s.sourceReaders) or s.sourcePin,
  not(s.rootReaders) or s.root,
  not(s.consumer) or s.root,
  not(s.parentAlive) or s.naturalFrameMap,
  not(s.parentAlive and s.parentGen==1) or s.newParentPin,
  not(s.rawBorrow) or (s.parentAlive and s.loadedGen==s.parentGen and s.parentLoaded==s.epoch),
  not(s.purged) or (s.frontier and s.resultAck and s.state==0 and not(s.queryPin) and not(s.inflight)),
  s.ackCount==0 or (not(s.sourceLease) and (s.root or not(s.needValue))),
  not(s.sourcePin) or s.sourceLease or s.ackCount==1}
 action step=any{submit,arrive,rejectLateDelivery,rejectExpiredRetry,rejectChangedIntent,pinQuery,readQuery,unpinQuery,queryAbsent,queryRetiredFence,replayAckFromFence,queryWrongKey,accept,loseReply,
  ackAccepted,ackTerminal,replayAck,releaseSourcePin,closeGC,collect,finishGC,reloadSource,takeVmCustody,exitParent,restoreParent,reloadParent,borrowParent,freezeParent,
  startNestedBorrow,finishNestedBorrow,releaseRestoredPin,attachConsumer,observeConsumerDrain,closeRequest,cancelUnseen,cancelPending,retireAccepted,ackTerminalResult,sealKey,purge,idle}
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action pendingInit=init.then(submit).then(arrive)
 action acceptedInit=pendingInit.then(accept)
 action queried=acceptedInit.then(pinQuery).then(readQuery).then(unpinQuery)
 action acked=queried.then(ackAccepted)
 action terminal=pendingInit.then(closeRequest).then(cancelPending).then(pinQuery).then(readQuery).then(unpinQuery).then(ackTerminal).then(releaseSourcePin).then(ackTerminalResult)
 action badWrongAck=s'={...s,sourceLease:false,ackCount:1,ackKey:s.observedKey,ackSeenRevision:s.observedRevision,ackCanonicalRevision:s.revision}
 action badExitWithoutClose=s'={...s,parentAlive:false,naturalFrameMap:false}
 action badPurgeWithoutResult=s'={...s,state:0,purged:true}
 action badDuplicate=s'={...s,allocations:s.allocations+1,rootsCreated:s.rootsCreated+1}
 action badAbsenceRelease=s'={...s,sourceLease:false,sourcePin:false}
 action badScanRelease=s'={...s,sourcePin:false}
 action badEraseFrame=s'={...s,naturalFrameMap:false}
 action badOldAckNewPin=s'={...s,newParentPin:false}
 action badStaleBorrow=s'={...s,rawBorrow:true}
 action badDoubleAck=s'={...s,ackCount:s.ackCount+1}
 action badRootRetire=s'={...s,root:false,state:3}
 action badLatePublish=s'={...s,state:2,root:true,rootsCreated:s.rootsCreated+1}
 action badForgetFrontier=s'={...s,frontier:false}
 action badFreeQueryPin=s'={...s,state:0,purged:true}
 run acceptedReplyLostQuerySameIdentityTest=acceptedInit.then(loseReply).then(pinQuery).then(readQuery).then(unpinQuery).then(ackAccepted).then(releaseSourcePin).then(check)
 run pendingReplyLostDuplicateNoAllocationTest=pendingInit.then(loseReply).then(submit).then(arrive).then(accept).then(check)
 run acceptedDuplicateNoSecondRootTest=acceptedInit.then(submit).then(arrive).then(check)
 run mismatchedIntentRejectedTest=pendingInit.then(rejectChangedIntent).then(check)
 run absentWithInflightKeepsSourceTest=init.then(submit).then(queryAbsent).then(arrive).then(accept).then(check)
 run closedPendingKeepsSourceTest=pendingInit.then(closeGC).then(loseReply).then(submit).then(arrive).then(check)
 run closedPendingMoveReloadAcceptTest=pendingInit.then(closeGC).then(collect).then(finishGC).then(reloadSource).then(accept).then(check)
 run acceptedQueryBeforeMoveAckAfterMoveTest=queried.then(closeGC).then(collect).then(ackAccepted).then(finishGC).then(releaseSourcePin).then(check)
 run logicalAckKeepsScanningPinTest=queried.then(closeGC).then(ackAccepted).then(check)
 run lostAckReplayDropsOnceTest=acked.then(loseReply).then(pinQuery).then(readQuery).then(unpinQuery).then(replayAck).then(releaseSourcePin).then(check)
 run restoreThenOldSourceAckKeepsNewPinTest=queried.then(restoreParent).then(reloadParent).then(ackAccepted).then(releaseSourcePin).then(check)
 run ackThenRestoreReloadNewBindingTest=acked.then(releaseSourcePin).then(restoreParent).then(reloadParent).then(borrowParent).then(freezeParent).then(check)
 run pendingExceptionVmKeepsRootViewTest=pendingInit.then(takeVmCustody).then(exitParent).then(closeGC).then(collect).then(finishGC).then(reloadSource).then(cancelPending).then(pinQuery).then(readQuery).then(unpinQuery).then(ackTerminal).then(releaseSourcePin).then(check)
 run acceptedExceptionQueriesFromVmTest=acceptedInit.then(takeVmCustody).then(exitParent).then(pinQuery).then(readQuery).then(unpinQuery).then(ackAccepted).then(releaseSourcePin).then(check)
 run nestedBorrowFinishesBeforeAckTest=queried.then(reloadParent).then(borrowParent).then(startNestedBorrow).then(finishNestedBorrow).then(freezeParent).then(ackAccepted).then(check)
 run cancelWinsBeforeAcceptanceTest=pendingInit.then(closeRequest).then(cancelPending).then(submit).then(arrive).then(check)
 run staleQueryAfterCancelRetainsSourceTest=queried.then(closeRequest).then(retireAccepted).then(check)
 run acceptedCancelWaitsConsumerDrainTest=acceptedInit.then(attachConsumer).then(closeRequest).then(observeConsumerDrain).then(retireAccepted).then(pinQuery).then(readQuery).then(unpinQuery).then(ackTerminal).then(releaseSourcePin).then(check)
 run terminalAckAndTombstonePurgeTest=terminal.then(sealKey).then(purge).then(rejectExpiredRetry).then(check)
 run delayedDuplicateBeforePurgeSettledTest=terminal.then(submit).then(sealKey).then(rejectLateDelivery).then(purge).then(check)
 run queryPinDelaysPurgeTest=terminal.then(pinQuery).then(sealKey).then(readQuery).then(unpinQuery).then(purge).then(check)
 run cancelUnseenBlocksDelayedAdmissionTest=init.then(submit).then(queryAbsent).then(cancelUnseen).then(arrive).then(pinQuery).then(readQuery).then(unpinQuery).then(ackTerminal).then(releaseSourcePin).then(check)
 run exceptionBeforeArrivalVmCancelsTest=init.then(submit).then(takeVmCustody).then(exitParent).then(cancelUnseen).then(arrive).then(pinQuery).then(readQuery).then(unpinQuery).then(ackTerminal).then(releaseSourcePin).then(check)
 run wrongQueryKeyCannotAuthorizeAckCounterexampleTest=acceptedInit.then(pinQuery).then(queryWrongKey).then(unpinQuery).then(badWrongAck).then(reject)
 run staleQueryAfterCancelCannotAckCounterexampleTest=queried.then(closeRequest).then(badWrongAck).then(reject)
 run exceptionMustCloseFutureAdmissionCounterexampleTest=pendingInit.then(takeVmCustody).then(badExitWithoutClose).then(reject)
 run sourceAckAloneKeepsOutcomeTombstoneTest=pendingInit.then(closeRequest).then(cancelPending).then(pinQuery).then(readQuery).then(unpinQuery).then(ackTerminal).then(releaseSourcePin).then(sealKey).then(check)
 run queryRetiredFenceCannotRecreateRootTest=terminal.then(sealKey).then(purge).then(queryRetiredFence).then(replayAckFromFence).then(rejectExpiredRetry).then(check)
 run sourceAckCannotReplaceResultAckCounterexampleTest=pendingInit.then(closeRequest).then(cancelPending).then(pinQuery).then(readQuery).then(unpinQuery).then(ackTerminal).then(releaseSourcePin).then(sealKey).then(badPurgeWithoutResult).then(reject)
 run deadCActivationCannotBorrowAgainCounterexampleTest=pendingInit.then(takeVmCustody).then(exitParent).then(badStaleBorrow).then(reject)
 run repeatRegisterAllocatesTwiceCounterexampleTest=acceptedInit.then(badDuplicate).then(reject)
 run missingQueryDoesNotMeanNoEffectCounterexampleTest=init.then(submit).then(queryAbsent).then(badAbsenceRelease).then(reject)
 run ackCannotDropActiveScanPinCounterexampleTest=queried.then(closeGC).then(ackAccepted).then(badScanRelease).then(reject)
 run ackCannotEraseSchemeFrameMapCounterexampleTest=acked.then(badEraseFrame).then(reject)
 run oldAckCannotDropRestoredPinCounterexampleTest=queried.then(restoreParent).then(badOldAckNewPin).then(reject)
 run restoredFrameNeedsReloadCounterexampleTest=queried.then(restoreParent).then(badStaleBorrow).then(reject)
 run logicalAckCannotApplyTwiceCounterexampleTest=acked.then(badDoubleAck).then(reject)
 run activeConsumerPreventsRootRetireCounterexampleTest=acceptedInit.then(attachConsumer).then(badRootRetire).then(reject)
 run terminalKeyCannotPublishAgainCounterexampleTest=terminal.then(sealKey).then(purge).then(badLatePublish).then(reject)
 run forgottenFrontierAllowsStaleIdentityCounterexampleTest=terminal.then(sealKey).then(purge).then(badForgetFrontier).then(reject)
 run queryPinPreventsTombstoneFreeCounterexampleTest=terminal.then(pinQuery).then(sealKey).then(badFreeQueryPin).then(reject)
 action negativeInit=queried.then(restoreParent)
 action negativeStep=badOldAckNewPin
}
