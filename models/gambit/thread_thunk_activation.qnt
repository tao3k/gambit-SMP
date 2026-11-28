// One worker/activation and one moving epoch; atomic registry/result observations are premises.
// No C weak memory, arbitrary children, full GVM, runtime liveness or POSIX implementation proof.
module thread_thunk_activation {
 type S={phase:int,source:bool,descriptor:bool,activation:bool,child:bool,outcome:int,
  epoch:int,loaded:int,raw:bool,synced:bool,context:bool,marker:int,clears:int,drops:int,
  catcher:bool,claim:bool,unknown:bool,returned:bool,need:bool,descriptorFreed:bool,stopReceipt:bool}
 var s:S
 action init=s'={phase:0,source:true,descriptor:false,activation:false,child:false,outcome:0,
  epoch:0,loaded:0,raw:false,synced:false,context:false,marker:0,clears:0,drops:0,
  catcher:false,claim:false,unknown:false,returned:false,need:true,descriptorFreed:false,stopReceipt:false}
 action register=all{s.phase==0,s.source,s'={...s,phase:1,descriptor:true}}
 action beginCreate=all{s.phase==1,s.descriptor,s.outcome==0,s'={...s,phase:2,outcome:1}}
 // The child can enter before the creator observes any result.
 action childEntry=all{s.phase==2,s.descriptor,(s.outcome==1 or s.outcome==2 or s.outcome==4),not(s.child),s'={...s,phase:3,child:true}}
 action createSuccess=all{(s.outcome==1 or s.outcome==4),s'={...s,outcome:2}}
 action createFailure=all{s.phase==2,s.outcome==1,not(s.child),s'={...s,outcome:3}}
 action loseResult=all{s.outcome==1,s'={...s,outcome:4}}
 // Externally confirmed no-child receipt; never synthesized from timeout/absent ACK.
 action confirmNoChild=all{s.phase==2,s.outcome==4,not(s.child),s'={...s,outcome:3}}
 action abortKnownFailure=all{s.outcome==3,not(s.child),s.phase==2,s'={...s,phase:9,descriptor:false,descriptorFreed:true,source:false,need:false,catcher:true,claim:true}}
 action collect=all{s.phase>=1,s.phase<9,not(s.raw),s.epoch==0,(s.source or s.descriptor or s.activation),s'={...s,epoch:1,context:false}}
 action finishSync=all{s.phase==3,s.child,s'={...s,phase:4,synced:true,context:true}}
 action prepareContext=all{s.phase>=4,s.phase<=8,not(s.raw),s.synced,s'={...s,context:true}}
 action reloadThunk=all{s.phase>=4,s.phase<=6,s.synced,s.context,(s.descriptor or s.activation),s'={...s,loaded:s.epoch,raw:true}}
 action acceptActivation=all{s.phase==4,s.child,s.raw,s.loaded==s.epoch,s.context,s.descriptor,s'={...s,phase:5,activation:true}}
 action acknowledgeSource=all{s.activation,s.source,s.descriptor,s.outcome==2,not(s.unknown),s'={...s,source:false,descriptor:false}}
 // Safe marker allocator holds the mapped activation cell; raw proc parameter is not retained.
 action allocateMarker=all{s.phase==5,s.activation,s'={...s,phase:6,marker:1,raw:false}}
 action markerFailure=all{s.phase==5,s.activation,s'={...s,phase:7,raw:false,catcher:true}}
 action callReturn=all{s.phase==6,s.raw,s.loaded==s.epoch,s.context,s'={...s,phase:7,raw:false,catcher:true}}
 action callRethrow=callReturn
 action claimExit=all{s.phase==7,s.catcher,s.activation,not(s.claim),s'={...s,phase:8,claim:true}}
 action clearMarker=all{s.phase==8,s.claim,s.marker==1,not(s.unknown),s'={...s,marker:2,clears:s.clears+1}}
 action dropMarker=all{s.phase==8,s.marker==2,not(s.unknown),s'={...s,marker:3,drops:s.drops+1}}
 action loseDrop=all{s.phase==8,s.marker==2,s'={...s,unknown:true}}
 action settleDropped=all{s.unknown,s.marker==2,s'={...s,unknown:false,marker:3,drops:s.drops+1}}
 action retireActivation=all{s.phase==8,s.claim,s.catcher,not(s.unknown),(s.marker==0 or s.marker==3),s'={...s,phase:9,activation:false,need:false}}
 action deliver=all{s.phase==9,s.catcher,s.claim,not(s.activation),not(s.unknown),s'={...s,phase:10,returned:true}}
 // Abstract external OS-stop receipt; activation return is not this observation.
 action observeChildStop=all{s.phase>=9,s.outcome==2,s.child,s'={...s,stopReceipt:true}}
 action settleTerminalSource=all{s.phase>=9,s.outcome==2,not(s.activation),s.descriptor,s'={...s,descriptor:false,source:false}}
 action childStopped=all{s.phase>=9,s.outcome==2,s.child,s.stopReceipt,not(s.activation),s'={...s,child:false}}
 action freeDescriptorStorage=all{s.phase>=9,not(s.child),not(s.activation),not(s.descriptor),s.outcome==2,s'={...s,descriptorFreed:true}}
 action idle=s'=s
 val safe=all{
  not(s.need) or s.source or s.descriptor or s.activation,
  not(s.raw) or (s.loaded==s.epoch and s.context and s.synced),
  not(s.child) or not(s.descriptorFreed),
  s.outcome!=4 or s.descriptor,
  not(s.unknown) or s.activation,
  s.clears<=1,s.drops<=s.clears,
  s.phase<5 or s.phase>=9 or s.activation,
  not(s.returned) or (s.catcher and s.claim and not(s.activation) and not(s.unknown) and (s.marker==0 or s.marker==3))}
 action step=any{register,beginCreate,childEntry,createSuccess,createFailure,loseResult,confirmNoChild,abortKnownFailure,collect,finishSync,prepareContext,reloadThunk,acceptActivation,acknowledgeSource,allocateMarker,markerFailure,callReturn,callRethrow,claimExit,clearMarker,dropMarker,loseDrop,settleDropped,retireActivation,deliver,observeChildStop,settleTerminalSource,childStopped,freeDescriptorStorage,idle}
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action published=init.then(register).then(beginCreate)
 action childInit=published.then(childEntry)
 action activeInit=childInit.then(finishSync).then(reloadThunk).then(acceptActivation)
 action marked=activeInit.then(createSuccess).then(acknowledgeSource).then(allocateMarker)
 action caught=marked.then(reloadThunk).then(callRethrow).then(claimExit)
 action badRootDrop=s'={...s,source:false,descriptor:false,activation:false}
 action badRawRead=s'={...s,raw:true,loaded:0}
 action badFree=s'={...s,descriptor:false,descriptorFreed:true}
 action badReturn=s'={...s,returned:true,activation:false}
 action badDoubleDrop=s'={...s,drops:s.drops+1}
 action badUnknownRetire=s'={...s,activation:false,phase:9,need:false}
 run beforePublicationGcTest=init.then(register).then(collect).then(beginCreate).then(check)
 run childBeforeCreatorReturnTest=childInit.then(finishSync).then(reloadThunk).then(acceptActivation).then(check)
 run createReturnBeforeChildTest=published.then(createSuccess).then(childEntry).then(finishSync).then(reloadThunk).then(acceptActivation).then(acknowledgeSource).then(check)
 run syncGcReloadTest=childInit.then(collect).then(finishSync).then(reloadThunk).then(acceptActivation).then(check)
 run knownCreateFailureTest=published.then(createFailure).then(abortKnownFailure).then(deliver).then(check)
 run unknownCreateRetainsDescriptorTest=published.then(loseResult).then(check)
 run unknownChildStillStartsTest=published.then(loseResult).then(childEntry).then(finishSync).then(reloadThunk).then(acceptActivation).then(check)
 run externalNoChildReceiptTest=published.then(loseResult).then(confirmNoChild).then(abortKnownFailure).then(deliver).then(check)
 run markerAllocationGcReloadTest=marked.then(collect).then(prepareContext).then(reloadThunk).then(callReturn).then(claimExit).then(clearMarker).then(dropMarker).then(retireActivation).then(deliver).then(check)
 run markerFailureExitTest=activeInit.then(markerFailure).then(claimExit).then(retireActivation).then(deliver).then(check)
 run rethrowCleanupTest=caught.then(clearMarker).then(dropMarker).then(retireActivation).then(deliver).then(check)
 run unknownDropRetainsRootTest=caught.then(clearMarker).then(loseDrop).then(check)
 run settledDropNoReplayTest=caught.then(clearMarker).then(loseDrop).then(settleDropped).then(retireActivation).then(deliver).then(check)
 run childStopsBeforeMetadataFreeTest=caught.then(clearMarker).then(dropMarker).then(retireActivation).then(deliver).then(observeChildStop).then(childStopped).then(freeDescriptorStorage).then(check)
 run lateSuccessAfterMarkerFailureTest=activeInit.then(loseResult).then(markerFailure).then(claimExit).then(retireActivation).then(deliver).then(createSuccess).then(settleTerminalSource).then(observeChildStop).then(childStopped).then(freeDescriptorStorage).then(check)
 run rootBeforeCreateCounterexampleTest=published.then(badRootDrop).then(reject)
 run cachedThunkAfterSyncGcCounterexampleTest=childInit.then(collect).then(finishSync).then(badRawRead).then(reject)
 run unknownCreateFreeCounterexampleTest=published.then(loseResult).then(badFree).then(reject)
 run childOutlivesCreatorCounterexampleTest=childInit.then(badFree).then(reject)
 run markerAllocOldEpochCounterexampleTest=marked.then(collect).then(prepareContext).then(badRawRead).then(reject)
 run skipExitGuardCounterexampleTest=caught.then(badReturn).then(reject)
 run replayDecrementCounterexampleTest=caught.then(clearMarker).then(dropMarker).then(badDoubleDrop).then(reject)
 run unknownDropRetirementCounterexampleTest=caught.then(clearMarker).then(loseDrop).then(badUnknownRetire).then(reject)
 action negativeInit=childInit.then(collect).then(finishSync)
 action negativeStep=badRawRead
}
