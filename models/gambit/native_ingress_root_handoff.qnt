// One native activation and one nested callback; origins handle0,parent1,unowned-raw2.
// Linearizable registry and complete frozen root maps are assumptions; no C weak-memory or native ABI proof.
module native_ingress_root_handoff {
 type S={origin:int,phase:int,sourceHeld:bool,pin:bool,borrow:bool,raw:bool,
  registered:bool,acked:bool,marker:bool,converted:bool,active:bool,nested:int,
  closed:bool,epoch:int,payloadEpoch:int,deleted:bool,dispatchDrained:bool,
  unknown:bool,stopped:bool,done:bool,reclaimed:bool,registrations:int,deliveries:int}
 var s:S
 action init=s'={origin:0,phase:0,sourceHeld:true,pin:false,borrow:false,raw:false,
  registered:false,acked:false,marker:false,converted:false,active:false,nested:0,
  closed:false,epoch:0,payloadEpoch:-1,deleted:false,dispatchDrained:false,
  unknown:false,stopped:false,done:false,reclaimed:false,registrations:0,deliveries:0}
 action parentInit=init.then(all{s'={...s,origin:1}})
 action rawInit=init.then(all{s'={...s,origin:2,sourceHeld:false}})
 action pinHandle=all{s.origin==0,s.phase==0,not(s.deleted),s.sourceHeld,s'={...s,pin:true,phase:1}}
 action borrowParent=all{s.origin==1,s.phase==0,not(s.closed),s.sourceHeld,s'={...s,pin:true,borrow:true,phase:1}}
 action rejectRaw=all{s.origin==2,s.phase==0,s'={...s,phase:9,done:true}}
 action rejectDeleted=all{s.phase==0,s.deleted,s'={...s,phase:9,done:true}}
 action resolveHandle=all{s.origin==0,s.phase==1,s.pin,not(s.closed),s'={...s,phase:2,raw:true,payloadEpoch:s.epoch}}
 action resolveParent=all{s.origin==1,s.phase==1,s.pin,s.borrow,not(s.closed),s'={...s,phase:2,raw:true,payloadEpoch:s.epoch}}
 // Child roots take custody in the same gate step that removes the raw borrow.
 action publish=all{s.phase==2,s.pin,s.sourceHeld,s.raw,s.payloadEpoch==s.epoch,not(s.closed),
  s.registrations==0,s'={...s,phase:3,registered:true,raw:false,borrow:false,registrations:1}}
 action acknowledge=all{s.registered,not(s.acked),s'={...s,acked:true,pin:false,sourceHeld:false}}
 action query=s'=s
 action marker=all{s.phase==3,s.registered,not(s.closed),s'={...s,phase:4,marker:true}}
 action convert=all{s.phase==4,s.registered,not(s.closed),s'={...s,phase:5,converted:true}}
 action invoke=all{s.phase==5,s.registered,not(s.closed),not(s.unknown),s.payloadEpoch==s.epoch,
  s'={...s,phase:6,active:true}}
 action reload=all{s.registered,not(s.closed),not(s.active),s'={...s,payloadEpoch:s.epoch}}
 action nestedEnter=all{s.phase==6,s.active,s.nested==0,not(s.closed),not(s.unknown),s'={...s,nested:1}}
 action nestedReturn=all{s.nested==1,s.active,not(s.unknown),s'={...s,nested:0}}
 action returnKnown=all{s.phase==6,s.active,s.nested==0,not(s.unknown),s'={...s,phase:7,active:false}}
 action failKnown=all{s.registered,s.phase>=3,s.phase<=6,s.nested==0,not(s.unknown),s'={...s,phase:7,active:false}}
 // Result/error custody is acknowledged before child roots can be detached.
 action deliver=all{s.phase==7,s.registered,s.acked,not(s.active),s.nested==0,not(s.unknown),
  s'={...s,phase:8,registered:false,done:true,deliveries:s.deliveries+1}}
 action close=all{not(s.closed),not(s.done),s'={...s,closed:true}}
 action parkIngress=all{s.closed,s.pin,not(s.registered),s.phase>=1,s.phase<=2,not(s.unknown),
  s'={...s,phase:1,borrow:false,raw:false,payloadEpoch:-1}}
 action reborrow=all{s.origin==1,s.pin,s.phase==1,not(s.closed),s.sourceHeld,s'={...s,borrow:true}}
 action parkChild=all{s.registered,s.closed,not(s.unknown),s'={...s,active:false,raw:false}}
 action resumeChild=all{s.phase==6,s.registered,not(s.active),not(s.closed),s.payloadEpoch==s.epoch,not(s.unknown),s'={...s,active:true}}
 action gc=all{s.closed,s.epoch==0,not(s.raw),not(s.borrow),not(s.active),not(s.unknown),
  (s.sourceHeld or s.registered),s'={...s,epoch:1,payloadEpoch:-1}}
 action reopen=all{s.closed,s.epoch==1,not(s.unknown),s'={...s,closed:false}}
 action delete=all{not(s.deleted),s'={...s,deleted:true}}
 // These two actions stand for externally established stop/drain evidence, never a timeout.
 action observeDrain=all{s.deleted,s.done,not(s.active),not(s.registered),not(s.pin),s.nested==0,not(s.unknown),s'={...s,dispatchDrained:true}}
 action loseExit=all{s.registered,s'={...s,unknown:true}}
 action confirmStop=all{s.unknown,s'={...s,stopped:true,active:false,raw:false,borrow:false}}
 action settleFailure=all{s.unknown,s.stopped,s.nested==0,s.registered,s'={...s,unknown:false,phase:7}}
 action reclaim=all{s.deleted,s.dispatchDrained,s.done,not(s.pin),not(s.registered),not(s.raw),not(s.borrow),s.nested==0,not(s.unknown),
  s'={...s,reclaimed:true,sourceHeld:false}}
 action idle=s'=s
 val safe=all{
  s.registrations<=1,s.deliveries<=1,
  s.origin==2 or s.done or s.sourceHeld or s.registered,
  s.origin!=2 or (not(s.registered) and not(s.raw) and (s.phase==0 or s.phase==9)),
  not(s.raw) or (s.pin and s.sourceHeld and s.payloadEpoch==s.epoch),
  not(s.borrow) or (s.origin==1 and s.pin and s.sourceHeld),
  not(s.pin) or s.sourceHeld,
  not(s.acked) or (not(s.pin) and not(s.sourceHeld)),
  not(s.marker) or (s.registrations==1),
  not(s.active) or (s.registered and s.marker and s.converted and s.payloadEpoch==s.epoch),
  s.nested==0 or s.registered,
  not(s.unknown) or s.registered,
  not(s.reclaimed) or (s.deleted and s.dispatchDrained and s.done and not(s.pin) and not(s.registered) and not(s.raw) and not(s.borrow) and s.nested==0 and not(s.unknown)),
  not(s.done) or (not(s.registered) and not(s.active))}
 action step=any{pinHandle,borrowParent,rejectRaw,rejectDeleted,resolveHandle,resolveParent,publish,acknowledge,
  query,marker,convert,invoke,reload,nestedEnter,nestedReturn,returnKnown,failKnown,deliver,close,parkIngress,
  reborrow,parkChild,resumeChild,gc,reopen,delete,observeDrain,loseExit,confirmStop,settleFailure,reclaim,idle}
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action handleReady=init.then(pinHandle).then(resolveHandle)
 action parentReady=parentInit.then(borrowParent).then(resolveParent)
 action published=handleReady.then(publish)
 action running=published.then(acknowledge).then(marker).then(convert).then(invoke)
 action badDrop=s'={...s,sourceHeld:false,pin:false,borrow:false,raw:false}
 action badGc=s'={...s,epoch:s.epoch+1}
 action badRawPublish=s'={...s,registered:true,registrations:1,phase:3}
 action badMarker=s'={...s,marker:true,phase:4}
 action badReclaim=s'={...s,reclaimed:true}
 action badDouble=s'={...s,registrations:s.registrations+1}
 action badDetach=s'={...s,registered:false}
 run handlePinBeforeCloseTest=init.then(pinHandle).then(close).then(gc).then(reopen).then(resolveHandle).then(publish).then(check)
 run parentBorrowToChildTest=parentReady.then(publish).then(acknowledge).then(check)
 run closeBeforeParentEntryTest=parentInit.then(close).then(gc).then(reopen).then(borrowParent).then(resolveParent).then(publish).then(check)
 run parentParksWithoutWaitCycleTest=parentReady.then(close).then(parkIngress).then(gc).then(reopen).then(reborrow).then(resolveParent).then(publish).then(check)
 run lostPublicationAckKeepsBothTest=published.then(query).then(all{assert(s.sourceHeld and s.pin and s.registered and safe),s'=s})
 run deletingPinnedHandleKeepsCallTest=handleReady.then(delete).then(publish).then(acknowledge).then(marker).then(convert).then(invoke).then(returnKnown).then(deliver).then(observeDrain).then(reclaim).then(check)
 run rejectUnownedRawTest=rawInit.then(rejectRaw).then(check)
 run conversionFailureTransfersErrorTest=published.then(marker).then(acknowledge).then(failKnown).then(deliver).then(check)
 run nestedRootsSurviveGcTest=running.then(nestedEnter).then(close).then(parkChild).then(gc).then(reopen).then(reload).then(resumeChild).then(nestedReturn).then(returnKnown).then(deliver).then(check)
 run unknownExitKeepsRootsTest=running.then(loseExit).then(close).then(query).then(check)
 run knownStopThenErrorDeliveryTest=running.then(loseExit).then(confirmStop).then(settleFailure).then(deliver).then(check)
 run parentDropBeforePublishCounterexampleTest=parentReady.then(badDrop).then(reject)
 run rawCopyAcrossGcCounterexampleTest=handleReady.then(close).then(badGc).then(reject)
 run rawOriginCannotRegisterCounterexampleTest=rawInit.then(badRawPublish).then(reject)
 run markerBeforeChildRootCounterexampleTest=handleReady.then(badMarker).then(reject)
 run pinWithoutDispatchDrainCounterexampleTest=handleReady.then(delete).then(badReclaim).then(reject)
 run lostAckNoSecondRegistrationCounterexampleTest=published.then(query).then(badDouble).then(reject)
 run nestedDetachCounterexampleTest=running.then(nestedEnter).then(badDetach).then(reject)
 run unknownRootDetachCounterexampleTest=running.then(loseExit).then(badDetach).then(reject)
 action negativeInit=parentReady
 action negativeStep=badDrop
}
