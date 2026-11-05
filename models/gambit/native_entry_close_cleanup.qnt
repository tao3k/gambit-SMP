// Product of three protocol projections; only parent raw-value epoch is explicit.
// Not a complete Tcl evaluator, C weak-memory model, or shared-VM execution simulation.
module native_entry_close_cleanup {
 type S={token:bool,open:bool,payload:bool,pins:int,queued:int,hookReturned:bool,drained:bool,read:bool,resultAccepted:bool,
  closed:bool,source:bool,child:bool,borrow:bool,raw:bool,mapped:bool,frozen:bool,epoch:int,reload:int,contextReady:bool,parentUnknown:bool,
  runPhase:int,runRoot:bool,marker:int,claim:bool,clearCount:int,dropCount:int,rootDrops:int,catcher:bool,runUnknown:bool,runReturned:bool,error:int}
 var s:S
 action init=s'={token:true,open:true,payload:true,pins:0,queued:1,hookReturned:false,drained:false,read:false,resultAccepted:false,
  closed:false,source:true,child:false,borrow:true,raw:true,mapped:true,frozen:false,epoch:0,reload:0,contextReady:true,parentUnknown:false,
  runPhase:0,runRoot:false,marker:0,claim:false,clearCount:0,dropCount:0,rootDrops:0,catcher:false,runUnknown:false,runReturned:false,error:0}
 action pin=all{s.token,s.open,s.queued==1,s.pins==0,s'={...s,pins:1,queued:0}}
 action readPayload=all{s.pins==1,s.payload,not(s.read),s'={...s,read:true}}
 action delete=all{s.token,s.open,s'={...s,open:false}}
 action deleteReturn=all{not(s.open),not(s.hookReturned),s'={...s,hookReturned:true}}
 action resultAccept=all{s.read,s.pins==1,s'={...s,resultAccepted:true}}
 action callbackReturn=all{s.pins==1,s.resultAccepted,s'={...s,pins:0}}
 action lateClosedEntry=all{s.token,not(s.open),s.queued==1,s'={...s,queued:0}}
 action releasePayload=all{not(s.open),s.hookReturned,s.pins==0,s.payload,s'={...s,payload:false}}
 // External dispatch/owner quiescence evidence is a premise, not inferred from pins==0.
 action observeDrain=all{not(s.open),s.hookReturned,s.pins==0,s.queued==0,s'={...s,drained:true}}
 action reclaimToken=all{s.drained,not(s.payload),s.pins==0,s.queued==0,s'={...s,token:false}}
 action close=all{not(s.closed),s'={...s,closed:true}}
 action park=all{s.closed,s.mapped,(s.source or s.child),not(s.parentUnknown),s'={...s,raw:false,borrow:false,frozen:true}}
 action collect=all{s.closed,s.frozen,s.mapped,not(s.raw),not(s.borrow),not(s.parentUnknown),s.epoch==0,
  s'={...s,epoch:1,contextReady:false}}
 action prepareContext=all{s.closed,s.frozen,s.epoch==1,s'={...s,contextReady:true}}
 action reloadParent=all{s.closed,s.frozen,s.contextReady,not(s.parentUnknown),s'={...s,reload:s.epoch}}
 action reopen=all{s.closed,s.source,s.frozen,s.contextReady,s.reload==s.epoch,not(s.parentUnknown),
  s'={...s,closed:false,frozen:false,borrow:true,raw:true}}
 action acceptChild=all{not(s.parentUnknown),not(s.closed),s.source,s.raw,s.reload==s.epoch,s'={...s,child:true,borrow:false,raw:false}}
 action ackChild=all{not(s.parentUnknown),s.child,s.source,not(s.borrow),not(s.raw),s'={...s,source:false}}
 action unknownParent=all{s.source,s'={...s,parentUnknown:true}}
 action enterRun=all{s.runPhase==0,s'={...s,runPhase:1,runRoot:true}}
 action makeMarker=all{s.runPhase==1,s.runRoot,s'={...s,runPhase:2,marker:1}}
 action failMarker=all{s.runPhase==1,s.runRoot,s'={...s,runPhase:3,error:1,catcher:true}}
 action normalCall=all{s.runPhase==2,s.runRoot,s'={...s,runPhase:3,error:0,catcher:true}}
 action rethrowCall=all{s.runPhase==2,s.runRoot,s'={...s,runPhase:3,error:1,catcher:true}}
 action claimCleanup=all{s.runPhase==3,s.runRoot,not(s.claim),s.catcher,s'={...s,runPhase:4,claim:true}}
 action clearMarker=all{s.runPhase==4,s.claim,s.marker==1,not(s.runUnknown),s'={...s,marker:2,clearCount:s.clearCount+1}}
 action dropMarker=all{s.runPhase==4,s.claim,s.marker==2,not(s.runUnknown),s'={...s,marker:3,dropCount:s.dropCount+1}}
 action loseDropResult=all{s.runPhase==4,s.marker==2,s'={...s,runUnknown:true}}
 // Only an external known-result/stop proof may settle the uncertain decrement.
 action confirmNotDropped=all{s.runUnknown,s.marker==2,s'={...s,runUnknown:false}}
 action confirmDropped=all{s.runUnknown,s.marker==2,s'={...s,runUnknown:false,marker:3,dropCount:s.dropCount+1}}
 action releaseRunRoots=all{s.runPhase==4,s.claim,not(s.runUnknown),(s.marker==0 or s.marker==3),
  s'={...s,runPhase:5,runRoot:false,rootDrops:s.rootDrops+1}}
 action returnRun=all{s.runPhase==5,s.catcher,s.claim,not(s.runRoot),not(s.runUnknown),s'={...s,runPhase:6,runReturned:true}}
 action idle=s'=s
 val tSafe=all{s.pins>=0,s.pins<=1, s.pins==0 or (s.token and s.payload),
  s.open or s.pins==0 or s.payload,
  s.payload or (not(s.open) and s.pins==0),
  s.token or (s.drained and not(s.open) and not(s.payload) and s.hookReturned and s.pins==0 and s.queued==0)}
 val pSafe=all{(s.source or s.child),not(s.borrow) or (s.source and not(s.frozen)),
  not(s.raw) or (s.reload==s.epoch and not(s.frozen)),
  not(s.frozen) or (s.mapped and not(s.raw) and not(s.borrow)),
  not(s.parentUnknown) or s.source}
 val rSafe=all{s.clearCount<=1,s.dropCount<=1,s.rootDrops<=1,s.dropCount<=s.clearCount,
  s.runPhase==0 or s.runRoot or s.runPhase>=5,
  s.marker!=2 or s.clearCount==1,s.marker!=3 or s.dropCount==1,
  s.runPhase<5 or (s.claim and s.catcher and not(s.runUnknown) and (s.marker==0 or s.marker==3)),
  not(s.runUnknown) or s.runRoot,
  not(s.runReturned) or (not(s.runRoot) and s.rootDrops==1 and s.catcher)}
 val safe=tSafe and pSafe and rSafe
 action step=any{pin,readPayload,delete,deleteReturn,resultAccept,callbackReturn,lateClosedEntry,releasePayload,observeDrain,reclaimToken,
  close,park,collect,prepareContext,reloadParent,reopen,acceptChild,ackChild,unknownParent,
  enterRun,makeMarker,failMarker,normalCall,rethrowCall,claimCleanup,clearMarker,dropMarker,loseDropResult,confirmNotDropped,confirmDropped,releaseRunRoots,returnRun,idle}
 action parentInit=init.then(close)
 action runInit=init.then(enterRun)
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action pinned=init.then(pin)
 action runCalling=init.then(enterRun).then(makeMarker)
 action runCaught=runCalling.then(rethrowCall)
 action runClearing=runCaught.then(claimCleanup).then(clearMarker)
 action badRelease=s'={...s,payload:false}
 action badTokenFree=s'={...s,token:false}
 action badGc=s'={...s,epoch:1}
 action badUnmap=s'={...s,mapped:false}
 action badSourceDrop=s'={...s,source:false,borrow:false,raw:false}
 action badRunReturn=s'={...s,runPhase:6,runReturned:true,runRoot:false}
 action badSecondDrop=s'={...s,dropCount:s.dropCount+1}
 action badRunRootDrop=s'={...s,runRoot:false,runPhase:5}
 run pinWinsDeleteKeepsPayloadTest=pinned.then(delete).then(deleteReturn).then(readPayload).then(check)
 run deleteWinsLateEntryTest=init.then(delete).then(deleteReturn).then(releasePayload).then(lateClosedEntry).then(observeDrain).then(reclaimToken).then(check)
 run nestedDeleteMustReturnWithoutOwnPinDrainTest=pinned.then(readPayload).then(delete).then(deleteReturn).then(all{assert(s.pins==1 and s.payload and safe),s'=s})
 run resultDeliveryBeforeLastPinReleaseTest=pinned.then(readPayload).then(delete).then(deleteReturn).then(resultAccept).then(callbackReturn).then(releasePayload).then(observeDrain).then(reclaimToken).then(check)
 run tombstoneOutlivesPayloadTest=init.then(delete).then(deleteReturn).then(releasePayload).then(all{assert(s.token and s.queued==1 and safe),s'=s})
 run parkGcContextReloadSameCallTest=init.then(close).then(park).then(collect).then(prepareContext).then(reloadParent).then(reopen).then(acceptChild).then(ackChild).then(check)
 run acceptedChildBeforeSourceAckTest=init.then(acceptChild).then(all{assert(s.child and s.source and safe),s'=s}).then(ackChild).then(check)
 run unknownBorrowRetainsSourceTest=init.then(unknownParent).then(close).then(idle).then(check)
 run runNormalExitCleanupTest=runCalling.then(normalCall).then(claimCleanup).then(clearMarker).then(dropMarker).then(releaseRunRoots).then(returnRun).then(check)
 run runRethrowUsesOuterCleanupTest=runCaught.then(claimCleanup).then(clearMarker).then(dropMarker).then(releaseRunRoots).then(returnRun).then(check)
 run markerFailureStillDropsRootTest=init.then(enterRun).then(failMarker).then(claimCleanup).then(releaseRunRoots).then(returnRun).then(check)
 run unknownMarkerDropRetainsRootTest=runClearing.then(loseDropResult).then(idle).then(check)
 run knownDroppedReceiptNoReplayTest=runClearing.then(loseDropResult).then(confirmDropped).then(releaseRunRoots).then(returnRun).then(check)
 run knownNotDroppedCanFinishTest=runClearing.then(loseDropResult).then(confirmNotDropped).then(dropMarker).then(releaseRunRoots).then(returnRun).then(check)
 run deleteCannotReleasePinnedPayloadCounterexampleTest=pinned.then(delete).then(badRelease).then(reject)
 run noPinsDoesNotProveDispatchDrainCounterexampleTest=init.then(delete).then(deleteReturn).then(releasePayload).then(badTokenFree).then(reject)
 run rawBorrowAcrossGcCounterexampleTest=init.then(close).then(badGc).then(reject)
 run missingParkMapCounterexampleTest=init.then(close).then(park).then(badUnmap).then(reject)
 run sourceDropBeforeChildAcceptCounterexampleTest=init.then(badSourceDrop).then(reject)
 run rethrowSkippingKillCounterexampleTest=runCaught.then(badRunReturn).then(reject)
 run markerFailureSkippingRootExitCounterexampleTest=init.then(enterRun).then(failMarker).then(badRunReturn).then(reject)
 run doubleMarkerDecrementCounterexampleTest=runClearing.then(dropMarker).then(badSecondDrop).then(reject)
 run unknownCleanupCannotDropRootCounterexampleTest=runClearing.then(loseDropResult).then(badRunRootDrop).then(reject)
 run unknownParentCannotAckAwaySourceCounterexampleTest=init.then(acceptChild).then(unknownParent).then(badSourceDrop).then(reject)
 action negativeInit=runCaught
 action negativeStep=badRunReturn
}
