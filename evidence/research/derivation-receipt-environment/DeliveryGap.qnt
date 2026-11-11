module derivation_receipt_environment {
 type State={owner:int,active:bool,child:int,ledger:int,pubs:int,claims:int,receipt:int,uncertain:bool,closed:bool,freed:bool}
 pure val initial:State={owner:0,active:false,child:0,ledger:1,pubs:0,claims:0,receipt:0,uncertain:false,closed:false,freed:false}
 var s:State
 val parentDebt=if(s.owner==3) 0 else 1
 val childDebt=if(s.child>=1 and s.child<=3) 1 else 0
 val safe=all{s.owner>=0,s.owner<=3,s.child>=0,s.child<=5,s.ledger==parentDebt+childDebt,
 s.active==(s.owner==1),s.pubs>=0,s.pubs<=1,s.claims>=0,s.claims<=s.pubs,
 (s.child==0 or s.child==1) implies (s.receipt==0 and s.pubs==0 and s.claims==0),
 s.child==2 implies (s.receipt==1 and s.pubs==1 and s.claims==0),
 s.child==3 implies (s.receipt==1 and s.pubs==1 and s.claims==1),
 s.child==4 implies (s.receipt==2 and s.pubs==1 and s.claims==1),
 s.child==5 implies (s.receipt==3 and s.pubs==0 and s.claims==0),
 s.freed implies (s.closed and s.owner==3 and s.ledger==0 and not(s.uncertain))}
 action init=s'=initial
 action beginDerive=all{s.owner==0,s.child==0,not(s.freed),s'={...s,owner:1,active:true}}
 action endDerive=all{s.owner==1,s'={...s,owner:0,active:false}}
 action reserveChild=all{s.owner==1,s.active,s.child==0,s.ledger<2,s'={...s,child:1,ledger:s.ledger+1}}
 action publish=all{s.owner==1,s.child==1,s'={...s,child:2,receipt:1,pubs:s.pubs+1}}
 action beginFinish=all{s.owner==0,s'={...s,owner:2}}
 action finishParent=all{s.owner==2,s.ledger>0,s'={...s,owner:3,ledger:s.ledger-1}}
 action claim=all{s.child==2,s.receipt==1,s'={...s,child:3,claims:s.claims+1}}
 action finishChild=all{s.child==3,s.receipt==1,s.ledger>0,s'={...s,child:4,receipt:2,ledger:s.ledger-1}}
 action abortPrivate=all{s.child==1,s'={...s,child:5,receipt:3,ledger:s.ledger-1}}
 action loseAck=all{s.pubs==1,s.owner==1,s'={...s,uncertain:true}}
 action reconcile=all{s.uncertain,s.pubs==1,s.receipt>=1,s.receipt<=2,s'={...s,uncertain:false}}
 action replay=all{s.pubs==1,s.receipt>=1,s.receipt<=2,s'=s}
 action close=all{s'={...s,closed:true}}
 action retire=all{s.closed,s.owner==3,s.ledger==0,not(s.uncertain),s'={...s,freed:true}}
 action step=any{beginDerive,endDerive,reserveChild,publish,beginFinish,finishParent,claim,finishChild,abortPrivate,loseAck,reconcile,replay,close,retire,all{s'=s}}
 run deriveWinsTest=init.then(beginDerive).then(all{assert(safe and s.owner!=0 and s.ledger==1),s'=s}).then(reserveChild).then(publish).then(endDerive).then(beginFinish).then(finishParent).then(claim).then(finishChild).then(close).then(retire).then(all{assert(safe and s.freed),s'=s})
 run finishWinsTest=init.then(beginFinish).then(all{assert(safe and s.owner!=0 and s.owner!=1),s'=s}).then(finishParent).then(close).then(retire).then(all{assert(safe),s'=s})
 run ackLostAfterCompletionTest=init.then(beginDerive).then(reserveChild).then(publish).then(loseAck).then(claim).then(finishChild).then(endDerive).then(beginFinish).then(finishParent).then(close).then(all{assert(safe and s.ledger==0 and s.uncertain and not(s.freed)),s'=s}).then(replay).then(reconcile).then(retire).then(all{assert(safe and s.freed and s.pubs==1 and s.claims==1),s'=s})
 run replayWhileQueuedTest=init.then(beginDerive).then(reserveChild).then(publish).then(loseAck).then(replay).then(replay).then(all{assert(safe and s.pubs==1 and s.child==2),s'=s})
 run privateOutlivesParentTest=init.then(beginDerive).then(reserveChild).then(endDerive).then(beginFinish).then(finishParent).then(all{assert(safe and s.ledger==1),s'=s}).then(abortPrivate).then(close).then(retire).then(all{assert(safe),s'=s})
 run beforeReserveFailureTest=init.then(beginDerive).then(endDerive).then(beginFinish).then(finishParent).then(close).then(retire).then(all{assert(safe),s'=s})
 run inheritedAfterCloseTest=init.then(close).then(beginDerive).then(reserveChild).then(publish).then(endDerive).then(beginFinish).then(finishParent).then(claim).then(finishChild).then(retire).then(all{assert(safe),s'=s})
 run earlyReconcileTest=init.then(beginDerive).then(reserveChild).then(publish).then(loseAck).then(reconcile).then(all{assert(safe and s.ledger==2 and s.child==2 and not(s.uncertain)),s'=s})
 run derivationFinishRaceControlTest=init.then(beginDerive).then(all{s'={...s,owner:3,ledger:0}}).then(all{assert(not(safe)),s'=s})
 run duplicatePublicationControlTest=init.then(beginDerive).then(reserveChild).then(publish).then(all{s'={...s,pubs:2}}).then(all{assert(not(safe)),s'=s})
 run unreceiptedPublicationControlTest=init.then(beginDerive).then(reserveChild).then(all{s'={...s,child:2,pubs:1}}).then(all{assert(not(safe)),s'=s})
 run zeroGapControlTest=init.then(beginDerive).then(reserveChild).then(endDerive).then(beginFinish).then(finishParent).then(close).then(all{s'={...s,ledger:0,freed:true}}).then(all{assert(not(safe)),s'=s})
 run unknownRetirementControlTest=init.then(beginDerive).then(reserveChild).then(publish).then(loseAck).then(claim).then(finishChild).then(endDerive).then(beginFinish).then(finishParent).then(close).then(all{s'={...s,freed:true}}).then(all{assert(not(safe)),s'=s})
 run pendingGapControlTest=init.then(beginDerive).then(reserveChild).then(publish).then(endDerive).then(beginFinish).then(finishParent).then(claim).then(finishChild).then(close).then(all{assert(s.uncertain),s'=s})
}
