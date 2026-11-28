// One original activation, a propagation receiver, an OOL caller and one cleanup callback.
// Atomic ticket transitions assume correct generated C endpoints and complete effects.
module ffi_exit_catcher_closure {
  type S={mode:int,body:bool,conversion:bool,marker:bool,pending:bool,restored:bool,
    reloaded:bool,resultRoot:bool,route:int,forward:int,localClosed:bool,pins:Set[int],
    callback:int,future:bool,independent:bool,vm:bool,admission:bool,dataClosed:bool,cleaned:bool,
    frozen:bool,wrongRestore:bool,lost:bool}
  var s:S
  val empty=Set()
  // pins 0 original, 1 propagation receiver, 2 OOL caller, 10 cleanup callback.
  action init=s'={mode:0,body:false,conversion:true,marker:true,pending:false,
    restored:false,reloaded:true,resultRoot:false,route:0,forward:0,localClosed:false,
    pins:Set(0),callback:0,future:false,independent:false,vm:false,admission:true,dataClosed:false,
    cleaned:false,frozen:false,wrongRestore:false,lost:false}
  action cfunInit=init.then(all{s'={...s,mode:1,marker:false,reloaded:false,pins:Set(0,2)}})
  action inlineInit=init.then(all{s'={...s,mode:2,marker:false,reloaded:false}})
  action choose(r:int):bool=all{s.route==0,r>=1,r<=3,s'={...s,route:r}}
  action bodyResult=all{not(s.body),not(s.localClosed),s'={...s,body:true,resultRoot:true}}
  action issueTail=all{not(s.localClosed),s.pins.contains(0),not(s.pending),s'={...s,pending:true}}
  action applyTail=all{s.pending,s.pins.contains(0),s'={...s,pending:false}}
  action finishConversion=all{s.body,s.conversion,not(s.pending),s'={...s,conversion:false}}
  action clearMarker=all{s.mode==0,s.body,not(s.conversion),not(s.pending),s'={...s,marker:false}}
  action restoreCatcher=all{s.body,not(s.pending),not(s.restored),s.pins.contains(0),s'={...s,restored:true}}
  action reloadRegisters=all{s.mode==2,s.restored,not(s.reloaded),s.pins.contains(0),s'={...s,reloaded:true}}
  // Register successor before source close/drop, not after longjmp loses source stack.
  action reserveForward=all{s.route>=2,s.forward==0,not(s.localClosed),s.pins.contains(0),
    s'={...s,forward:1,pins:s.pins.union(Set(1))}}
  val ownEffectsDone=s.body and not(s.conversion) and not(s.marker) and not(s.pending) and s.restored and (s.mode==1 or s.reloaded) and s.resultRoot and s.route!=0
  action closeOriginal=all{ownEffectsDone,not(s.localClosed),s.route==1 or s.forward==1,
    s'={...s,localClosed:true}}
  action dropOriginalPin=all{s.localClosed,s.pins.contains(0),s'={...s,pins:s.pins.exclude(Set(0))}}
  // These later effects belong to the already counted receiver ticket, not closed writer 0.
  action issueForward=all{s.localClosed,s.forward==1,s.pins.contains(1),s'={...s,forward:2}}
  action arriveTarget=all{s.forward==2,s.pins.contains(1),s'={...s,forward:3}}
  action settleReceiver=all{s.forward==3,s.pins.contains(1),s'={...s,forward:4,pins:s.pins.exclude(Set(1))}}
  action callerPostlude=all{s.mode==1,s.localClosed,s.pins.contains(2),
    s'={...s,reloaded:true,pins:s.pins.exclude(Set(2))}}
  action acceptVm=s'={...s,vm:true}
  // Callback debt is reserved before invoking callback or discharging parent cleanup.
  action reserveCallback=all{s.admission,not(s.cleaned),s.callback==0,
    s'={...s,callback:1,pins:s.pins.union(Set(10))}}
  action transferCallback=all{s.callback==1,s.vm,not(s.independent),
    s'={...s,independent:true,pins:s.pins.exclude(Set(10))}}
  // Transfer future-epoch execution authorization, not task/resource debt.
  action deferCallback=all{s.callback==1,s.independent,s.vm,not(s.frozen),s'={...s,future:true}}
  action startCallback=all{s.callback==1,not(s.future),s'={...s,callback:2}}
  action finishCallback=all{s.callback==2,s'={...s,callback:3,pins:s.pins.exclude(Set(10))}}
  action closeAdmission=all{s.admission,s'={...s,admission:false}}
  val forwardDone=s.forward==0 or s.forward==4
  val callbackDone=s.callback==0 or s.callback==3 or s.future
  action certifyData=all{s.localClosed,forwardDone,callbackDone,s.pins==empty,not(s.admission),s.vm,
    s'={...s,dataClosed:true}}
  action cleanupSource=all{s.localClosed,s.pins==empty,s.vm,s.callback==0 or s.callback==3 or s.independent,
    s'={...s,cleaned:true}}
  action freeze=all{s.dataClosed,s'={...s,frozen:true}}
  action query=s'=s
  val admitted=all{
    not(s.localClosed) or ownEffectsDone,
    s.pins.contains(0) or s.localClosed,
    s.mode!=1 or s.reloaded or s.pins.contains(2),
    not(s.localClosed) or s.route==1 or s.forward>=1,
    (s.forward<1 or s.forward>3) or s.pins.contains(1),
    (s.callback==0 or s.callback==3 or s.independent) or s.pins.contains(10),
    not(s.cleaned) or (s.localClosed and s.vm and s.pins==empty),
    not(s.dataClosed) or (s.localClosed and forwardDone and callbackDone and s.pins==empty and not(s.admission) and s.vm),
    not(s.frozen) or s.dataClosed,
    not(s.future) or (s.callback==1 and s.independent and s.vm),
    not(s.wrongRestore),not(s.lost)}
  action step=any{choose(1),choose(2),choose(3),bodyResult,issueTail,applyTail,finishConversion,
    clearMarker,restoreCatcher,reloadRegisters,reserveForward,closeOriginal,dropOriginalPin,
    issueForward,arriveTarget,settleReceiver,callerPostlude,acceptVm,reserveCallback,
    transferCallback,deferCallback,startCallback,finishCallback,closeAdmission,certifyData,cleanupSource,freeze,query}
  action sfunReady=init.then(choose(1)).then(bodyResult).then(finishConversion).then(clearMarker).then(restoreCatcher).then(closeOriginal)
  action exceptionalReady=init.then(choose(2)).then(bodyResult).then(finishConversion).then(clearMarker).then(restoreCatcher).then(reserveForward).then(closeOriginal)
  action cfunReady=cfunInit.then(choose(1)).then(bodyResult).then(finishConversion).then(restoreCatcher).then(closeOriginal)
  action normalDetached=sfunReady.then(dropOriginalPin).then(acceptVm)
  action badClose=s'={...s,localClosed:true}
  action badDrop=s'={...s,pins:empty}
  action badSeal=s'={...s,dataClosed:true}
  action badCleanup=s'={...s,cleaned:true}
  action badForward=s'={...s,forward:2}
  action badCallback=s'={...s,callback:2}
  action badDefer=s'={...s,future:true}
  action badRestore=s'={...s,restored:true,wrongRestore:true}
  action badMarkerReopen=s'={...s,marker:true}
  action badLose=s'={...s,lost:true}
  run normalSfunTest=normalDetached.then(closeAdmission).then(certifyData).then(freeze).then(all{assert(admitted),s'=s})
  run resultIsNotCloseTest=init.then(bodyResult).then(all{assert(not(s.localClosed) and s.conversion and admitted),s'=s})
  run localCloseNotBorrowZeroTest=sfunReady.then(all{assert(s.pins==Set(0) and admitted),s'=s})
  run reservedForwardSurvivesOriginalDropTest=exceptionalReady.then(dropOriginalPin).then(all{assert(s.pins==Set(1) and not(s.dataClosed) and admitted),s'=s})
  run throwReceiveRestoreTest=exceptionalReady.then(dropOriginalPin).then(issueForward).then(arriveTarget).then(settleReceiver).then(acceptVm).then(closeAdmission).then(certifyData).then(all{assert(admitted),s'=s})
  run cfunCallerStillBorrowsTest=cfunReady.then(dropOriginalPin).then(all{assert(s.pins==Set(2) and admitted),s'=s})
  run cfunCallerReadThenDetachTest=cfunReady.then(dropOriginalPin).then(callerPostlude).then(acceptVm).then(cleanupSource).then(closeAdmission).then(certifyData).then(all{assert(admitted),s'=s})
  run pendingTailBeforeExitTest=init.then(bodyResult).then(issueTail).then(applyTail).then(finishConversion).then(clearMarker).then(restoreCatcher).then(choose(1)).then(closeOriginal).then(all{assert(admitted),s'=s})
  run nestedCfunPropagationTest=cfunInit.then(choose(3)).then(bodyResult).then(finishConversion).then(restoreCatcher).then(reserveForward).then(closeOriginal).then(dropOriginalPin).then(callerPostlude).then(issueForward).then(arriveTarget).then(settleReceiver).then(all{assert(s.pins==empty and admitted),s'=s})
  run callbackReserveBeforeCleanupTest=normalDetached.then(reserveCallback).then(all{assert(s.pins==Set(10) and not(s.cleaned) and admitted),s'=s})
  run callbackCanTransferOffSourceTest=normalDetached.then(reserveCallback).then(transferCallback).then(cleanupSource).then(startCallback).then(all{assert(not(s.dataClosed) and admitted),s'=s})
  run independentCallbackStillOwesDataTest=normalDetached.then(reserveCallback).then(transferCallback).then(closeAdmission).then(startCallback).then(finishCallback).then(certifyData).then(all{assert(admitted),s'=s})
  run sourceCallbackDrainsTest=normalDetached.then(reserveCallback).then(startCallback).then(finishCallback).then(cleanupSource).then(all{assert(admitted),s'=s})
  run lateRegisteredCallbackStillOwedTest=normalDetached.then(reserveCallback).then(closeAdmission).then(startCallback).then(finishCallback).then(certifyData).then(all{assert(admitted),s'=s})
  run queryDoesNotRepeatCleanupTest=normalDetached.then(query).then(query).then(all{assert(admitted),s'=s})
  run registerBeforeCatcherRestoreTest=init.then(choose(2)).then(reserveForward).then(bodyResult).then(finishConversion).then(clearMarker).then(restoreCatcher).then(closeOriginal).then(all{assert(admitted),s'=s})
  run resultOnlySealCounterexampleTest=init.then(bodyResult).then(badClose).then(all{assert(not(admitted)),s'=s})
  run beforeMarkerClearCounterexampleTest=init.then(choose(1)).then(bodyResult).then(finishConversion).then(restoreCatcher).then(badClose).then(all{assert(not(admitted)),s'=s})
  run beforeCatcherRestoreCounterexampleTest=init.then(choose(1)).then(bodyResult).then(finishConversion).then(clearMarker).then(badClose).then(all{assert(not(admitted)),s'=s})
  run cfunBeforeReloadCounterexampleTest=inlineInit.then(choose(1)).then(bodyResult).then(finishConversion).then(restoreCatcher).then(badClose).then(all{assert(not(admitted)),s'=s})
  run originalPinEarlyDropCounterexampleTest=init.then(badDrop).then(all{assert(not(admitted)),s'=s})
  run propagationDebtLostCounterexampleTest=exceptionalReady.then(dropOriginalPin).then(badDrop).then(all{assert(not(admitted)),s'=s})
  run cfunCallerBorrowIgnoredCounterexampleTest=cfunReady.then(dropOriginalPin).then(acceptVm).then(badCleanup).then(all{assert(not(admitted)),s'=s})
  run unregisteredPropagationCounterexampleTest=normalDetached.then(badForward).then(all{assert(not(admitted)),s'=s})
  run unregisteredCallbackCounterexampleTest=normalDetached.then(badCallback).then(all{assert(not(admitted)),s'=s})
  run callbackBorrowIgnoredCounterexampleTest=normalDetached.then(reserveCallback).then(badCleanup).then(all{assert(not(admitted)),s'=s})
  run transferredCallbackNotClosedCounterexampleTest=normalDetached.then(reserveCallback).then(transferCallback).then(closeAdmission).then(badSeal).then(all{assert(not(admitted)),s'=s})
  run wrongCatcherIdentityCounterexampleTest=init.then(badRestore).then(all{assert(not(admitted)),s'=s})
  run markerReopenedAfterCloseCounterexampleTest=sfunReady.then(badMarkerReopen).then(all{assert(not(admitted)),s'=s})
  run cleanupResponseLostCannotDropDutyCounterexampleTest=normalDetached.then(reserveCallback).then(badLose).then(all{assert(not(admitted)),s'=s})
  run routeWithoutReceiverCounterexampleTest=init.then(choose(2)).then(bodyResult).then(finishConversion).then(clearMarker).then(restoreCatcher).then(badClose).then(all{assert(not(admitted)),s'=s})
  run futureCallbackRetainsTaskAcrossFreezeTest=normalDetached.then(reserveCallback).then(transferCallback).then(deferCallback).then(closeAdmission).then(certifyData).then(freeze).then(all{assert(s.callback==1 and s.future and admitted),s'=s})
  run futureCallbackNotRunnableInCurrentEpochTest=normalDetached.then(reserveCallback).then(transferCallback).then(deferCallback).then(all{assert(s.future and s.callback==1 and admitted),s'=s})
  run activeCallbackCannotDeferCounterexampleTest=normalDetached.then(reserveCallback).then(transferCallback).then(startCallback).then(badDefer).then(all{assert(not(admitted)),s'=s})
  run oolClosePrecedesCallerReloadTest=cfunReady.then(all{assert(not(s.reloaded) and s.pins.contains(2) and admitted),s'=s})
  run inlineRestoreBeforeCloseTest=inlineInit.then(choose(1)).then(bodyResult).then(finishConversion).then(restoreCatcher).then(reloadRegisters).then(closeOriginal).then(all{assert(admitted),s'=s})
  run oolCallerPinDropCounterexampleTest=cfunReady.then(dropOriginalPin).then(badDrop).then(all{assert(not(admitted)),s'=s})
  action negativeInit=

exceptionalReady.then(dropOriginalPin).then(acceptVm).then(closeAdmission)
  action negativeStep=badSeal
}
