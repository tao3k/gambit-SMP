module still_owner_retirement {
  // One operation/three fields, two owner generations; abstract earlier receipt gap.
  // Native isolation and root-domain completeness are admission premises, not C facts.
  type State={mode:int,started:bool,prefix:int,physical:int,busy:bool,writeGen:int,
    owner:int,oldStopped:bool,writersClosed:bool,unknown:bool,effectFree:bool,inputStable:bool,
    rootDomain:bool,registryIndependent:bool,resourcesIndependent:bool,rawLeak:bool,stageDone:bool,
    published:bool,sourceRoot:bool,receiverRoot:bool,accepted:bool,accepts:int,
    gc:bool,meta:bool,clientAck:bool,closed:bool,readers:int,callbacks:int,
    floor:int,prefixSettled:bool,reexec:int,retired:bool,freed:bool,held:int}
  var s:State
  action init=s'={mode:1,started:false,prefix:0,physical:0,busy:false,writeGen:0,
    owner:0,oldStopped:false,writersClosed:false,unknown:false,effectFree:true,inputStable:true,
    rootDomain:true,registryIndependent:true,resourcesIndependent:true,rawLeak:false,stageDone:false,
    published:false,sourceRoot:false,receiverRoot:false,accepted:false,accepts:0,
    gc:false,meta:true,clientAck:false,closed:false,readers:0,callbacks:0,
    floor:0,prefixSettled:true,reexec:0,retired:false,freed:false,held:8}
  val gcReady=s.registryIndependent and s.resourcesIndependent and not(s.rawLeak) and
    (s.mode==1 and s.rootDomain or s.published and (s.sourceRoot or s.receiverRoot))
  val safe=s.prefix>=0 and s.prefix<=s.physical and s.physical<=3 and s.physical<=s.prefix+1 and
    (s.busy or s.prefix==s.physical) and (not(s.busy) or s.writeGen==s.owner) and
    s.reexec==0 and s.accepts<=1 and s.readers>=0 and s.readers<=2 and s.callbacks>=0 and s.callbacks<=1 and
    (not(s.started) or s.stageDone or s.rootDomain) and
    (not(s.gc) or gcReady) and
    (s.owner==0 or (s.oldStopped and s.writersClosed and s.mode==1 and s.effectFree and s.inputStable)) and
    (not(s.published) or (s.stageDone and s.prefix==3 and (s.sourceRoot or s.receiverRoot))) and
    (not(s.accepted) or (s.published and s.receiverRoot and s.accepts==1)) and
    (s.meta or (s.floor==1 and s.closed and s.clientAck and s.readers==0 and s.callbacks==0 and s.prefixSettled)) and
    (s.floor==0 or (s.prefixSettled and s.clientAck and s.closed)) and
    (not(s.freed) or (s.retired and s.stageDone and s.readers==0 and s.callbacks==0)) and
    (s.freed or s.held==8)
  action chooseClassic=all{not(s.started),not(s.gc),s'={...s,mode:0}}
  action chooseEffectful=all{not(s.started),s'={...s,effectFree:false}}
  action chooseGap=all{not(s.started),s'={...s,prefixSettled:false}}
  action start=all{not(s.started),s'={...s,started:true}}
  action reserve=all{s.started,s.prefix<3,not(s.busy),not(s.stageDone),
    s.owner==1 or not(s.oldStopped),s'={...s,busy:true,writeGen:s.owner}}
  action write=all{s.busy,s.physical==s.prefix,s.writeGen==s.owner,
    s.owner==1 or not(s.oldStopped),s'={...s,physical:s.physical+1}}
  action commit=all{s.busy,s.physical==s.prefix+1,s.writeGen==s.owner,
    s.owner==1 or not(s.oldStopped),s'={...s,prefix:s.physical,busy:false}}
  action failJoin=all{s.started,s'={...s,unknown:true}}
  action confirmStop=all{s.started,s.owner==0,not(s.stageDone),
    s'={...s,oldStopped:true}}
  action closeWriters=all{s.oldStopped,s.owner==0,s'={...s,writersClosed:true}}
  action takeover=all{s.oldStopped,s.writersClosed,s.mode==1,s.effectFree,s.inputStable,
    s.rootDomain,s.owner==0,not(s.stageDone),not(s.published),
    s'={...s,owner:1,physical:s.prefix,busy:false,unknown:false}}
  action finishStage=all{s.started,s.prefix==3,not(s.busy),
    s.owner==1 or not(s.oldStopped),s'={...s,stageDone:true}}
  action materialize=all{s.stageDone,not(s.gc),s.rootDomain,not(s.published),
    s'={...s,published:true,sourceRoot:true}}
  action accept=all{s.published,not(s.accepted),not(s.closed),
    s'={...s,accepted:true,receiverRoot:true,accepts:1}}
  action duplicateAccept=all{s.accepted,s'=s}
  action acknowledge=all{s.accepted,s.receiverRoot,s'={...s,clientAck:true,unknown:false}}
  action closeIngress=s'={...s,closed:true}
  action readerBegin=all{s.meta,not(s.closed),s.readers<2,s'={...s,readers:s.readers+1}}
  action readerEnd=all{s.readers>0,s'={...s,readers:s.readers-1}}
  action callbackBegin=all{s.meta,not(s.closed),s.callbacks==0,s'={...s,callbacks:1}}
  action deriveReader=all{s.meta,s.callbacks==1,s.readers<2,s'={...s,readers:s.readers+1}}
  action callbackEnd=all{s.callbacks==1,s'={...s,callbacks:0}}
  action retireReceipt=all{s.meta,s.clientAck,s.closed,s.readers==0,s.callbacks==0,
    s.stageDone,s.prefixSettled,s'={...s,meta:false,floor:1,retired:true,sourceRoot:false}}
  action lateRetry=all{s.closed,s.floor==1,s'=s}
  action freeStage=all{s.retired,s.stageDone,s.readers==0,s.callbacks==0,
    s'={...s,freed:true,held:0}}
  action enterGc=all{gcReady,s'={...s,gc:true}}
  action exitGc=all{s.gc,s'={...s,gc:false}}
  action stutter=s'=s
  action step=any{chooseClassic,chooseEffectful,chooseGap,start,reserve,write,commit,
    failJoin,confirmStop,closeWriters,takeover,finishStage,materialize,accept,
    duplicateAccept,acknowledge,closeIngress,readerBegin,readerEnd,callbackBegin,
    deriveReader,callbackEnd,retireReceipt,lateRetry,freeStage,enterGc,exitGc,stutter}
  action one=reserve.then(write).then(commit)
  action ready=start.then(one).then(one).then(one).then(finishStage).then(materialize).then(accept)
  run failedJoinDoesNotStopTest=init.then(start).then(reserve).then(write).then(failJoin).expect(safe and not(s.oldStopped))
  run joinDoesNotCloseBorrowersTest=init.then(start).then(reserve).then(write).then(confirmStop).expect(safe and not(s.writersClosed))
  run deadPendingPrivateReplayTest=init.then(start).then(reserve).then(write).then(confirmStop).then(closeWriters).then(takeover).then(one).expect(safe and s.owner==1 and s.prefix==1)
  run committedPrefixPreservedTest=init.then(start).then(one).then(reserve).then(write).then(confirmStop).then(closeWriters).then(takeover).expect(safe and s.prefix==1 and s.physical==1)
  run unknownNativeOwnerGcTest=init.then(start).then(reserve).then(write).then(failJoin).then(enterGc).expect(safe and s.gc and s.busy and not(s.oldStopped))
  run nativeWritesDuringGcTest=init.then(start).then(reserve).then(enterGc).then(write).then(commit).expect(safe and s.gc and s.prefix==1)
  run deadOwnerGcBeforeTakeoverTest=init.then(start).then(reserve).then(write).then(confirmStop).then(enterGc).expect(safe and s.gc and not(s.writersClosed))
  run classicStillBlocksTest=init.then(chooseClassic).then(start).then(reserve).then(write).then(confirmStop).expect(safe and not(gcReady))
  run effectfulCannotReplayTest=init.then(chooseEffectful).then(start).then(reserve).then(write).then(confirmStop).then(closeWriters).expect(safe and not(s.effectFree))
  run normalResultTest=init.then(ready).then(acknowledge).expect(safe and s.accepts==1)
  run acceptedUnknownTest=init.then(ready).then(failJoin).then(duplicateAccept).expect(safe and s.accepts==1 and s.receiverRoot)
  run lateRetryAfterRetirementTest=init.then(ready).then(acknowledge).then(closeIngress).then(retireReceipt).then(lateRetry).expect(safe and not(s.meta) and s.floor==1)
  run pinnedReaderRetainsTest=init.then(ready).then(readerBegin).then(acknowledge).then(closeIngress).expect(safe and s.meta and s.readers==1)
  run drainThenRetireTest=init.then(ready).then(readerBegin).then(acknowledge).then(closeIngress).then(readerEnd).then(retireReceipt).expect(safe and s.retired)
  run derivedChildPinTest=init.then(ready).then(callbackBegin).then(acknowledge).then(closeIngress).then(deriveReader).then(callbackEnd).expect(safe and s.meta and s.readers==1)
  run derivedDrainRetireTest=init.then(ready).then(callbackBegin).then(acknowledge).then(closeIngress).then(deriveReader).then(callbackEnd).then(readerEnd).then(retireReceipt).expect(safe and s.retired)
  run earlierGapRetainsTest=init.then(chooseGap).then(ready).then(acknowledge).then(closeIngress).expect(safe and s.meta and not(s.prefixSettled))
  run freeAfterReceiptTest=init.then(ready).then(acknowledge).then(closeIngress).then(retireReceipt).then(freeStage).expect(safe and s.freed and s.receiverRoot)
  run timeoutTakeoverControlTest=init.then(start).then(reserve).then(write).then(failJoin).then(s'={...s,owner:1,busy:false,physical:s.prefix}).expect(not(safe))
  run joinWithoutWriterClosureControlTest=init.then(start).then(confirmStop).then(s'={...s,owner:1}).expect(not(safe))
  run rawHeapGcControlTest=init.then(chooseClassic).then(start).then(reserve).then(write).then(s'={...s,gc:true}).expect(not(safe))
  run leakedHeapPointerGcControlTest=init.then(start).then(reserve).then(s'={...s,rawLeak:true,gc:true}).expect(not(safe))
  run deadRegistryLockControlTest=init.then(start).then(s'={...s,registryIndependent:false,gc:true}).expect(not(safe))
  run sharedAllocatorLockControlTest=init.then(start).then(s'={...s,resourcesIndependent:false,gc:true}).expect(not(safe))
  run inputLeaseLostControlTest=init.then(start).then(confirmStop).then(closeWriters).then(takeover).then(s'={...s,inputStable:false}).expect(not(safe))
  run staleWriterControlTest=init.then(start).then(confirmStop).then(closeWriters).then(takeover).then(s'={...s,busy:true,writeGen:0}).expect(not(safe))
  run unackedReceiptFreeControlTest=init.then(ready).then(closeIngress).then(s'={...s,meta:false,floor:1}).expect(not(safe))
  run activeReaderFreeControlTest=init.then(ready).then(readerBegin).then(acknowledge).then(closeIngress).then(s'={...s,meta:false,floor:1}).expect(not(safe))
  run activeCallbackFreeControlTest=init.then(ready).then(callbackBegin).then(acknowledge).then(closeIngress).then(s'={...s,meta:false,floor:1}).expect(not(safe))
  run gapFloorControlTest=init.then(chooseGap).then(ready).then(acknowledge).then(closeIngress).then(s'={...s,meta:false,floor:1}).expect(not(safe))
  run forgottenFenceControlTest=init.then(ready).then(acknowledge).then(closeIngress).then(retireReceipt).then(s'={...s,floor:0}).expect(not(safe))
  run duplicateReexecutionControlTest=init.then(ready).then(acknowledge).then(closeIngress).then(retireReceipt).then(s'={...s,reexec:1}).expect(not(safe))
  run unknownBufferFreeControlTest=init.then(start).then(reserve).then(write).then(failJoin).then(s'={...s,freed:true,held:0}).expect(not(safe))
}
