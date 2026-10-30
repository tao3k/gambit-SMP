module managed_marker_layout {
  // A typed managed marker, owner processor 1, one closed GC view. No C execution.
  // Key words are abstract exact integers; Lean separately establishes bounded encoding.
  type State={phase:int,kind:int,key:int,originalKey:int,recordKey:int,recordLive:bool,
    inputsRooted:bool,initialized:bool,listVisible:bool,serviceRoot:bool,rawCount:int,
    view:int,setup:bool,queued:bool,markerMarked:bool,procMarked:bool,scanDone:bool,
    captured:bool,closed:bool,cleared:bool,freed:bool,allowedReturn:bool,
    clearedInView:bool,rawScanned:bool,forged:bool,transformed:bool,unknown:bool,owner:int}
  var s:State
  val safe=s.rawCount==0 and not(s.rawScanned) and not(s.forged) and not(s.transformed) and
    (not(s.listVisible) or s.initialized) and
    (s.kind!=1 or s.key==s.originalKey) and
    (not(s.serviceRoot) or s.listVisible) and
    (s.phase!=3 or s.serviceRoot or s.closed) and
    (not(s.scanDone) or (s.setup and s.markerMarked and (s.procMarked or s.cleared))) and
    (not(s.allowedReturn) or (s.kind==1 and s.recordLive and s.recordKey==s.key and not(s.closed) and s.owner==1)) and
    (not(s.freed) or (not(s.serviceRoot) and not(s.captured) and s.view==0 and not(s.markerMarked))) and
    not(s.clearedInView) and
    (not(s.unknown) or s.serviceRoot)
  action init=s'={phase:0,kind:0,key:0,originalKey:11,recordKey:11,recordLive:true,
    inputsRooted:true,initialized:false,listVisible:false,serviceRoot:false,rawCount:0,
    view:0,setup:false,queued:false,markerMarked:false,procMarked:false,scanDone:false,
    captured:false,closed:false,cleared:false,freed:false,allowedReturn:false,
    clearedInView:false,rawScanned:false,forged:false,transformed:false,unknown:false,owner:1}
  action reserve=all{s.phase==0,s.inputsRooted,s'={...s,phase:1}}
  action initialize=all{s.phase==1,s.inputsRooted,s'={...s,phase:2,kind:1,key:s.originalKey,initialized:true}}
  // One admission gate covers private body, still-list membership and root enumeration.
  // No unprotected intermediate state may be observed by GC or an escaping owner.
  action admit=all{s.phase==2,s.initialized,s.view==0,
    s'={...s,phase:3,listVisible:true,serviceRoot:true,inputsRooted:false}}
  action publishView=all{s.phase==3,(s.serviceRoot or s.captured),not(s.freed),s.view==0,
    s'={...s,view:1,setup:false,queued:false,markerMarked:false,procMarked:false,scanDone:false}}
  action setupAllLists=all{s.view==1,not(s.setup),s'={...s,setup:true}}
  action enumerateRoot=all{s.view==1,s.setup,(s.serviceRoot or s.captured),not(s.queued),
    s'={...s,queued:true,markerMarked:true}}
  action scanTypedBody=all{s.view==1,s.queued,not(s.scanDone),
    s'={...s,procMarked:not(s.cleared),scanDone:true}}
  action finishView=all{s.view==1,s.scanDone,s'={...s,view:0}}
  action capture=all{s.phase==3,not(s.freed),s'={...s,captured:true}}
  action close=all{s.phase==3,not(s.closed),not(s.allowedReturn),s'={...s,closed:true}}
  action physicalClear=all{s.closed,s.serviceRoot,s.view==0,not(s.unknown),
    s'={...s,cleared:true}}
  action retireRecord=all{s.closed,not(s.allowedReturn),s'={...s,recordLive:false}}
  action dropRoot=all{s.closed,s.cleared,s.view==0,not(s.unknown),s'={...s,serviceRoot:false}}
  action commitReturn=all{s.phase==3,s.kind==1,s.recordLive,s.key==s.recordKey,
    not(s.closed),s.owner==1,not(s.allowedReturn),s'={...s,allowedReturn:true}}
  action consumeReturn=all{s.allowedReturn,s'={...s,allowedReturn:false}}
  action queryClosed=all{s.kind==1,not(s.recordLive),s.closed,s'={...s,allowedReturn:false}}
  action unknownAdmission=all{s.phase==3,s.serviceRoot,s'={...s,unknown:true}}
  action settleUnknown=all{s.unknown,s.serviceRoot,s'={...s,unknown:false}}
  action sweep=all{s.closed,s.cleared,not(s.serviceRoot),not(s.captured),s.view==0,
    s'={...s,freed:true,markerMarked:false,scanDone:false}}
  action query=s'=s
  action step=any{reserve,initialize,admit,publishView,setupAllLists,enumerateRoot,
    scanTypedBody,finishView,capture,close,physicalClear,retireRecord,dropRoot,
    commitReturn,consumeReturn,queryClosed,unknownAdmission,settleUnknown,sweep,query}
  // Unsafe alternatives are deliberately excluded from the admitted transition set.
  action badPublish=all{s.phase==2,s'={...s,phase:3,listVisible:true,serviceRoot:false}}
  action badWholeBodyScan=s'={...s,rawScanned:true}
  action badForeignScan=all{s.view==1,s.setup,s'={...s,markerMarked:true,scanDone:true,procMarked:false}}
  action badResetAfterMark=all{s.scanDone,s'={...s,markerMarked:false}}
  action badFallback=all{not(s.recordLive),s'={...s,allowedReturn:true}}
  action badReuseKey=all{s.kind==1,s'={...s,key:12}}
  action badRawDebit=s'={...s,rawCount:(-1)}
  action badDeserialize=s'={...s,forged:true}
  action badClearActive=all{s.view==1,s'={...s,cleared:true,clearedInView:true}}
  action badUnknownDrop=all{s.unknown,s'={...s,serviceRoot:false}}
  action badFreeCaptured=all{s.captured,s'={...s,freed:true}}
  action prepared=init.then(reserve).then(initialize)
  action live=prepared.then(admit)
  action marked=live.then(publishView).then(setupAllLists).then(enumerateRoot).then(scanTypedBody)
  run privateBodyTest=prepared.then(all{assert(s.initialized and not(s.listVisible)),s'=s})
  run zeroCountAdmissionTest=live.then(all{assert(s.rawCount==0 and s.serviceRoot),s'=s})
  run setupBeforeEnumerationTest=live.then(publishView).then(setupAllLists).then(all{assert(s.setup and not(s.queued)),s'=s})
  run processorOneRootTest=marked.then(all{assert(s.owner==1 and s.procMarked and safe),s'=s})
  run immutableKeyTest=marked.then(finishView).then(close).then(retireRecord).then(all{assert(s.key==11),s'=s})
  run returnConsumeTest=live.then(commitReturn).then(consumeReturn).then(commitReturn).then(all{assert(safe),s'=s})
  run missingMetadataTest=live.then(close).then(retireRecord).then(queryClosed).then(all{assert(not(s.allowedReturn) and safe),s'=s})
  run capturedClosedMarkerTest=marked.then(finishView).then(capture).then(close).then(physicalClear).then(dropRoot).then(retireRecord).then(queryClosed).then(all{assert(s.captured and not(s.freed) and safe),s'=s})
  run capturedClosedRescanTest=marked.then(finishView).then(capture).then(close).then(physicalClear).then(dropRoot).then(publishView).then(setupAllLists).then(enumerateRoot).then(scanTypedBody).then(all{assert(safe and not(s.procMarked)),s'=s})
  run ordinarySweepTest=marked.then(finishView).then(close).then(physicalClear).then(dropRoot).then(sweep).then(all{assert(s.freed and safe),s'=s})
  run unknownRetainsRootTest=live.then(unknownAdmission).then(query).then(all{assert(s.serviceRoot and safe),s'=s})
  run settledUnknownTest=live.then(unknownAdmission).then(settleUnknown).then(close).then(physicalClear).then(all{assert(safe),s'=s})
  run repeatViewTest=marked.then(finishView).then(publishView).then(setupAllLists).then(enumerateRoot).then(scanTypedBody).then(all{assert(safe),s'=s})
  run sourceRootUntilAdmissionTest=prepared.then(all{assert(s.inputsRooted),s'=s})
  run closeDuringPublishedViewTest=marked.then(close).then(all{assert(s.serviceRoot and not(s.cleared) and safe),s'=s})
  run unknownAfterRecordRetireTest=live.then(close).then(retireRecord).then(unknownAdmission).then(all{assert(s.serviceRoot and safe),s'=s})
  run unrootedPublishCounterexampleTest=prepared.then(badPublish).then(all{assert(not(safe)),s'=s})
  run rawKeyScanCounterexampleTest=live.then(badWholeBodyScan).then(all{assert(not(safe)),s'=s})
  run opaqueForeignCounterexampleTest=live.then(publishView).then(setupAllLists).then(badForeignScan).then(all{assert(not(safe)),s'=s})
  run lateSetupCounterexampleTest=marked.then(badResetAfterMark).then(all{assert(not(safe)),s'=s})
  run managedMissFallbackCounterexampleTest=live.then(close).then(retireRecord).then(badFallback).then(all{assert(not(safe)),s'=s})
  run reusedKeyCounterexampleTest=live.then(badReuseKey).then(all{assert(not(safe)),s'=s})
  run rawDebitCounterexampleTest=live.then(badRawDebit).then(all{assert(not(safe)),s'=s})
  run forgedDeserializeCounterexampleTest=live.then(badDeserialize).then(all{assert(not(safe)),s'=s})
  run clearPublishedViewCounterexampleTest=marked.then(badClearActive).then(all{assert(not(safe)),s'=s})
  run unknownRootDropCounterexampleTest=live.then(unknownAdmission).then(badUnknownDrop).then(all{assert(not(safe)),s'=s})
  run capturedFreeCounterexampleTest=live.then(capture).then(badFreeCaptured).then(all{assert(not(safe)),s'=s})
  action negativeInit=live
  action negativeStep=badWholeBodyScan
}
