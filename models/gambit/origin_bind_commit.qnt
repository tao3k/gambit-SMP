// One fixed source port, one bind journal, one candidate slot, competing header and one GC.
// Hardware/OS stop receipts and the existing-source scanner are explicit external premises.
module origin_bind_commit {
 type S={port:bool,registered:bool,frozen:bool,admitted:bool,source:bool,needed:bool,sourceLoaded:int,
  intent:bool,header:int,casInFlight:bool,casKnown:bool,fieldA:bool,fieldB:bool,logA:bool,logB:bool,
  dataInFlight:bool,dataTarget:int,locator:bool,committed:bool,commitCount:int,effects:int,replySeen:bool,
  ownerExit:bool,closeRequested:bool,dataClosed:bool,controlClosed:bool,helper:bool,vmCustody:bool,
  root:bool,rootEpoch:int,epoch:int,gc:bool,moved:bool,sourceScan:bool,rootScan:bool,
  terminal:bool,resultAck:bool,sourceAck:bool,cellPin:bool,reclaimed:bool,unresolved:bool,helpViolation:int}
 var s:S
 action init=s'={port:false,registered:true,frozen:false,admitted:false,source:true,needed:true,sourceLoaded:0,
  intent:false,header:0,casInFlight:false,casKnown:false,fieldA:false,fieldB:false,logA:false,logB:false,
  dataInFlight:false,dataTarget:0,locator:false,committed:false,commitCount:0,effects:0,replySeen:false,
  ownerExit:false,closeRequested:false,dataClosed:false,controlClosed:false,helper:false,vmCustody:false,
  root:false,rootEpoch:0,epoch:0,gc:false,moved:false,sourceScan:false,rootScan:false,
  terminal:false,resultAck:false,sourceAck:false,cellPin:false,reclaimed:false,unresolved:false,helpViolation:0}
 action installEmptyPort=all{not(s.port),not(s.gc),not(s.admitted),s'={...s,port:true}}
 action freezeSource=all{s.port,s.registered,s.source,not(s.gc),not(s.admitted),s'={...s,frozen:true,sourceLoaded:s.epoch}}
 action admitOrigin=all{s.port,s.registered,s.frozen,s.source,not(s.admitted),s'={...s,admitted:true,vmCustody:true}}
 action prepareIntent=all{s.admitted,s.frozen,not(s.intent),not(s.controlClosed),not(s.terminal),s'={...s,intent:true}}
 action beginCas=all{s.intent,s.header==0,not(s.casInFlight),not(s.controlClosed),not(s.closeRequested),not(s.terminal),
   s'={...s,casInFlight:true,casKnown:false}}
 // Header0 free;1 owned by exact journal token;2 a competing journal's slot. No Scheme payload.
 action applyCas=all{s.casInFlight,not(s.controlClosed),s'={...s,header:if(s.header==0)1 else s.header,casInFlight:false,casKnown:false}}
 action noteCas=all{s.intent,not(s.casInFlight),s'={...s,casKnown:true}}
 action competitorClaim=all{s.header==0,s'={...s,header:2}}
 action beginData(target:int):bool=all{s.header==1,not(s.dataClosed),not(s.dataInFlight),not(s.committed),not(s.terminal),
   s'={...s,dataInFlight:true,dataTarget:target}}
 action storeData=all{s.dataInFlight,not(s.dataClosed),not(s.committed),not(s.terminal),
   s'={...s,fieldA:if(s.dataTarget==1)true else s.fieldA,fieldB:if(s.dataTarget==2)true else s.fieldB}}
 action finishData=all{s.dataInFlight,s'={...s,dataInFlight:false}}
 action logA=all{s.header==1,s.fieldA,not(s.controlClosed),not(s.committed),not(s.terminal),s'={...s,logA:true}}
 action logB=all{s.header==1,s.fieldB,not(s.controlClosed),not(s.committed),not(s.terminal),s'={...s,logB:true}}
 action publishLocator=all{s.header==1,s.fieldA,s.fieldB,not(s.controlClosed),not(s.terminal),s'={...s,locator:true}}
 // Observation of exit is not a proof that the CAS or field writer has stopped.
 action observeExit=all{s.admitted,s'={...s,ownerExit:true,unresolved:true}}
 action requestClose=all{s.admitted,s'={...s,closeRequested:true,vmCustody:true}}
 action confirmDataStopped=all{s.closeRequested,not(s.dataInFlight),s'={...s,dataClosed:true}}
 action confirmControlStopped=all{s.closeRequested,not(s.casInFlight),s'={...s,controlClosed:true}}
 action takeHelper=all{s.dataClosed,s.controlClosed,not(s.dataInFlight),not(s.casInFlight),s.vmCustody,not(s.reclaimed),s'={...s,helper:true}}
 action helperFieldA=all{s.helper,s.header==1,not(s.terminal),s'={...s,fieldA:true,logA:true}}
 action helperFieldB=all{s.helper,s.header==1,not(s.terminal),s'={...s,fieldB:true,logB:true}}
 action helperLocator=all{s.helper,s.header==1,s.fieldA,s.fieldB,not(s.terminal),s'={...s,locator:true}}
 action reloadSource=all{s.admitted,s.source,s.frozen,not(s.gc),s'={...s,sourceLoaded:s.epoch}}
 // Existing root-admission cut serializes against close and installs a current scannable cell.
 action acceptRoot=all{s.header==1,s.fieldA,s.fieldB,s.locator,s.admitted,s.source,s.frozen,not(s.gc),
   s.sourceLoaded==s.epoch,not(s.root),not(s.terminal),s'={...s,root:true,rootEpoch:s.epoch}}
 action commit=all{s.header==1,s.fieldA,s.fieldB,s.locator,s.root,s.rootEpoch==s.epoch,not(s.dataInFlight),not(s.casInFlight),
   not(s.committed),not(s.terminal),(s.helper or not(s.controlClosed)),s'={...s,committed:true,commitCount:s.commitCount+1}}
 action replayCommit=all{s.committed,s'=s}
 action loseReturn=all{s.admitted,s'={...s,replySeen:false,unresolved:true}}
 action query=all{s.admitted,s.vmCustody,not(s.reclaimed),s'={...s,replySeen:true}}
 action effect=all{s.committed,not(s.terminal),not(s.gc),s.root,s.effects==0,s'={...s,effects:1}}
 action abortUnclaimed=all{s.helper,s.intent,s.header!=1,not(s.casInFlight),s.effects==0,s'={...s,terminal:true,needed:false,unresolved:false}}
 action abortPrivateOwned=all{s.helper,s.header==1,not(s.root),not(s.committed),s.effects==0,s'={...s,terminal:true,needed:false,unresolved:false}}
 // External consumer/child drain is a premise; publication/root ownership is not stop evidence.
 action finishCommitted=all{s.helper,s.committed,not(s.gc),not(s.rootScan),s'={...s,terminal:true,needed:false,root:false,unresolved:false}}
 action ackSource=all{s.committed or s.terminal,s.root or not(s.needed),s'={...s,sourceAck:true}}
 action releaseSource=all{s.sourceAck,not(s.sourceScan),s'={...s,source:false}}
 action ackResult=all{s.terminal,s'={...s,resultAck:true}}
 action pinCell=all{s.admitted,not(s.reclaimed),s'={...s,cellPin:true}}
 action unpinCell=all{s.cellPin,s'={...s,cellPin:false}}
 action reclaim=all{s.terminal,s.resultAck,s.sourceAck,not(s.source),not(s.sourceScan),not(s.rootScan),not(s.cellPin),
   s.dataClosed,s.controlClosed,not(s.dataInFlight),not(s.casInFlight),s'={...s,reclaimed:true}}
 action closeGc=all{not(s.gc),not(s.moved),s.registered,s'={...s,gc:true,sourceScan:s.source,rootScan:s.root}}
 action collect=all{s.gc,not(s.moved),(not(s.source) or s.sourceScan),(not(s.root) or s.rootScan),
   s'={...s,epoch:1,moved:true,rootEpoch:if(s.rootScan)1 else s.rootEpoch}}
 action endGc=all{s.gc,s.moved,s'={...s,gc:false,sourceScan:false,rootScan:false}}
 action refuseUnregistered=all{not(s.registered),not(s.admitted),s'=s}
 action idle=s'=s
 val safe=all{not(s.admitted) or (s.port and s.registered and s.frozen and s.vmCustody),
   not(s.needed) or s.source or s.root,
   not(s.helper) or (s.dataClosed and s.controlClosed and not(s.dataInFlight) and not(s.casInFlight)),
   not(s.sourceScan) or s.source,not(s.rootScan) or s.root,
   not(s.root) or (s.header==1 and s.fieldA and s.fieldB and s.locator and s.rootEpoch==s.epoch),
   not(s.committed and not(s.terminal)) or (s.root and s.fieldA and s.fieldB and s.locator),
   s.effects==0 or s.committed,s.effects<=1,s.commitCount<=1,not(s.logA) or s.fieldA,not(s.logB) or s.fieldB,
   not(s.dataClosed) or not(s.dataInFlight),not(s.controlClosed) or not(s.casInFlight),
   not(s.terminal) or (s.dataClosed and s.controlClosed),
   not(s.reclaimed) or (s.terminal and s.resultAck and s.sourceAck and not(s.source) and not(s.cellPin) and not(s.rootScan)),
   s.helpViolation==0}
 action step=any{installEmptyPort,freezeSource,admitOrigin,prepareIntent,beginCas,applyCas,noteCas,competitorClaim,
   beginData(1),beginData(2),storeData,finishData,logA,logB,publishLocator,observeExit,requestClose,confirmDataStopped,confirmControlStopped,
   takeHelper,helperFieldA,helperFieldB,helperLocator,reloadSource,acceptRoot,commit,replayCommit,loseReturn,query,effect,abortUnclaimed,abortPrivateOwned,
   finishCommitted,ackSource,releaseSource,ackResult,pinCell,unpinCell,reclaim,closeGc,collect,endGc,refuseUnregistered,idle}
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action admitted=init.then(installEmptyPort).then(freezeSource).then(admitOrigin)
 action prepared=admitted.then(prepareIntent)
 action claimed=prepared.then(beginCas).then(applyCas)
 action initialized=claimed.then(beginData(1)).then(storeData).then(finishData).then(logA).then(beginData(2)).then(storeData).then(finishData).then(logB).then(publishLocator)
 action committed=initialized.then(acceptRoot).then(commit)
 action stop=requestClose.then(confirmDataStopped).then(confirmControlStopped).then(takeHelper)
 action repair=helperFieldA.then(helperFieldB).then(helperLocator)
 action gcRound=closeGc.then(collect).then(endGc)
 action unregisteredInit=init.then(all{s'={...s,registered:false}})
 action badAdmit=s'={...s,admitted:true}
 action badHelp=s'={...s,helper:true}
 action badControlClose=s'={...s,controlClosed:true}
 action badDataClose=s'={...s,dataClosed:true}
 action badEraseSource=s'={...s,source:false}
 action badCommit=s'={...s,committed:true,commitCount:s.commitCount+1}
 action badOverwriteRoot=s'={...s,rootEpoch:0}
 action badLoseLocator=s'={...s,locator:false}
 action badFree=s'={...s,reclaimed:true}
 action badTouchOther=s'={...s,helpViolation:s.helpViolation+1}
 action badEffect=s'={...s,effects:1}
 run fullNormalBindCommitTest=committed.then(effect).then(query).then(check)
 run admittedDuringCloseKeepsFrozenSourceTest=init.then(installEmptyPort).then(freezeSource).then(closeGc).then(admitOrigin).then(prepareIntent).then(collect).then(endGc).then(check)
 run firstHostWithoutRegisteredSourceRefusesTest=unregisteredInit.then(installEmptyPort).then(refuseUnregistered).then(check)
 run stopBeforeCasSealsNoEffectTest=prepared.then(stop).then(abortUnclaimed).then(ackSource).then(releaseSource).then(ackResult).then(reclaim).then(check)
 run lostCasReplyReconcilesOwnedHeaderTest=claimed.then(loseReturn).then(observeExit).then(stop).then(repair).then(acceptRoot).then(commit).then(check)
 run delayedCasAfterObservedExitStillOwnedTest=prepared.then(beginCas).then(observeExit).then(requestClose).then(applyCas).then(confirmControlStopped).then(confirmDataStopped).then(takeHelper).then(repair).then(acceptRoot).then(commit).then(check)
 run competitorWinsNeverInitializesOtherSlotTest=prepared.then(beginCas).then(competitorClaim).then(applyCas).then(stop).then(abortUnclaimed).then(check)
 run firstFieldStoreWithoutProgressCanRepairTest=claimed.then(beginData(1)).then(storeData).then(finishData).then(observeExit).then(stop).then(repair).then(acceptRoot).then(commit).then(check)
 run secondFieldStoreWithoutLogCanRepairTest=claimed.then(beginData(1)).then(storeData).then(finishData).then(logA).then(beginData(2)).then(storeData).then(finishData).then(observeExit).then(stop).then(repair).then(acceptRoot).then(commit).then(check)
 run locatorPublishedReplyLostReusesSameCellTest=initialized.then(loseReturn).then(query).then(acceptRoot).then(commit).then(replayCommit).then(check)
 run exitBeforeLocatorHelperPublishesItTest=claimed.then(stop).then(repair).then(acceptRoot).then(commit).then(check)
 run privateMetadataCanInitializeDuringGcCloseTest=claimed.then(closeGc).then(beginData(1)).then(storeData).then(finishData).then(collect).then(endGc).then(stop).then(repair).then(reloadSource).then(acceptRoot).then(commit).then(check)
 run staleSourceReloadBeforeRootAdmissionTest=initialized.then(gcRound).then(reloadSource).then(acceptRoot).then(commit).then(check)
 run acceptedRootMovesBeforeCommitTest=initialized.then(acceptRoot).then(gcRound).then(commit).then(check)
 run stoppedHelperNeverReplaysOldPayloadTest=initialized.then(acceptRoot).then(gcRound).then(stop).then(repair).then(commit).then(check)
 run committedReplyLostOnlyQueriesTest=committed.then(loseReturn).then(query).then(replayCommit).then(effect).then(check)
 run sourceAckDuringScanKeepsPhysicalViewTest=committed.then(closeGc).then(ackSource).then(collect).then(endGc).then(releaseSource).then(check)
 run unknownExitStillAllowsGcFromFrozenViewTest=claimed.then(observeExit).then(gcRound).then(check)
 run abortedBeforeAcceptanceCanReleaseAfterScanTest=claimed.then(closeGc).then(stop).then(abortPrivateOwned).then(ackSource).then(collect).then(endGc).then(releaseSource).then(ackResult).then(reclaim).then(check)
 run committedFinishRequiresSeparateResultAckTest=committed.then(stop).then(finishCommitted).then(ackSource).then(releaseSource).then(ackResult).then(reclaim).then(check)
 run cellQueryPinDrainsBeforeReuseTest=committed.then(pinCell).then(stop).then(finishCommitted).then(ackSource).then(releaseSource).then(ackResult).then(unpinCell).then(reclaim).then(check)
 run missingPortCannotAdmitCounterexampleTest=init.then(badAdmit).then(reject)
 run unregisteredSourceCannotAdmitCounterexampleTest=unregisteredInit.then(installEmptyPort).then(badAdmit).then(reject)
 run observedExitNotControlStopCounterexampleTest=prepared.then(beginCas).then(observeExit).then(badHelp).then(reject)
 run liveCasCannotBeDeclaredClosedCounterexampleTest=prepared.then(beginCas).then(badControlClose).then(reject)
 run liveDataStoreCannotBeDeclaredClosedCounterexampleTest=claimed.then(beginData(1)).then(badDataClose).then(reject)
 run incompleteFieldsCannotCommitCounterexampleTest=claimed.then(badCommit).then(reject)
 run locatorMissingCannotCommitCounterexampleTest=initialized.then(acceptRoot).then(badLoseLocator).then(badCommit).then(reject)
 run sideEffectBeforeCommitCounterexampleTest=initialized.then(badEffect).then(reject)
 run movedRootCannotReceiveCachedPayloadCounterexampleTest=initialized.then(acceptRoot).then(gcRound).then(badOverwriteRoot).then(reject)
 run descriptorCoverageCannotDropSourceScannerCounterexampleTest=committed.then(closeGc).then(ackSource).then(badEraseSource).then(reject)
 run sourceOnlyCannotBeDroppedCounterexampleTest=claimed.then(badEraseSource).then(reject)
 run resultUnknownCannotFreeCounterexampleTest=committed.then(stop).then(finishCommitted).then(ackSource).then(releaseSource).then(badFree).then(reject)
 run queryPinCannotBeFreedCounterexampleTest=committed.then(pinCell).then(stop).then(finishCommitted).then(ackSource).then(releaseSource).then(ackResult).then(badFree).then(reject)
 run competitorMetadataCannotBeRepairedCounterexampleTest=prepared.then(competitorClaim).then(stop).then(badTouchOther).then(reject)
 action badProgressBeforeStore=s'={...s,logA:true}
 run latePrivateStoreAfterExitObservationTest=claimed.then(beginData(1)).then(observeExit).then(requestClose).then(storeData).then(finishData).then(confirmDataStopped).then(confirmControlStopped).then(takeHelper).then(repair).then(acceptRoot).then(commit).then(check)
 run gcWhileUnknownPrivateStoreStillInFlightTest=claimed.then(beginData(1)).then(observeExit).then(gcRound).then(storeData).then(finishData).then(stop).then(repair).then(reloadSource).then(acceptRoot).then(commit).then(check)
 run failedClaimRecyclesJournalButNotCompetitorSlotTest=prepared.then(competitorClaim).then(stop).then(abortUnclaimed).then(ackSource).then(releaseSource).then(ackResult).then(reclaim).then(all{assert(s.header==2),s'=s}).then(check)
 run progressBeforeActualStoreCounterexampleTest=claimed.then(badProgressBeforeStore).then(reject)
 action negativeInit=
prepared.then(beginCas).then(observeExit)
 action negativeStep=badHelp
}
