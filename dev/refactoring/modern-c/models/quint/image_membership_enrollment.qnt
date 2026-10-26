module image_membership_enrollment {
 // Proposed controlled enrollment; raw aliases and actual source closure remain external obligations.
 type State={phase:int,epoch:int,vm1:int,incarnation:int,ticketEpoch:int,receiptEpoch0:int,receiptEpoch1:int,receiptInc1:int,users0:int,users1:int,observers:int,denied:int,helperKnown:bool,membersSealed:bool,mappingQualified:bool,ownedFacade:bool,rawEscape:bool,expected1:bool,closed0:bool,closed1:bool,receipt0:bool,receipt1:bool,externalDrained:bool}
 pure val initial:State={phase:0,epoch:1,vm1:0,incarnation:1,ticketEpoch:0,receiptEpoch0:0,receiptEpoch1:0,receiptInc1:0,users0:1,users1:0,observers:0,denied:0,helperKnown:false,membersSealed:false,mappingQualified:true,ownedFacade:false,rawEscape:false,expected1:false,closed0:false,closed1:false,receipt0:false,receipt1:false,externalDrained:true}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,
 s.phase<=2,
 s.epoch>=1,
 s.epoch<=2,
 s.vm1>=0,
 s.vm1<=4,
 s.incarnation>=1,
 s.incarnation<=2,
 s.ticketEpoch>=0,
 s.ticketEpoch<=s.epoch,
 s.receiptEpoch0>=0,
 s.receiptEpoch0<=s.epoch,
 s.receiptEpoch1>=0,
 s.receiptEpoch1<=s.epoch,
 s.receiptInc1>=0,
 s.receiptInc1<=s.incarnation,
 s.users0>=0,
 s.users0<=1,
 s.users1>=0,
 s.users1<=1,
 s.observers>=0,
 s.observers<=1,
 s.denied>=0,
 s.membersSealed implies (s.helperKnown and s.mappingQualified),
 s.receipt0 implies (s.phase>=1 and s.closed0 and s.users0==0 and s.receiptEpoch0==s.epoch),
 s.receipt1 implies (s.phase>=1 and s.closed1 and s.users1==0 and s.receiptEpoch1==s.epoch and s.receiptInc1==s.incarnation and (s.vm1==2 or s.vm1==3)),
 s.phase>=1 implies (s.expected1 == (s.vm1!=0)),
 s.phase==2 implies (s.membersSealed and s.ownedFacade and not(s.rawEscape) and s.receipt0 and (s.expected1 implies s.receipt1) and s.observers==0 and s.externalDrained and s.vm1!=1 and s.vm1!=4),
 s.vm1==0 implies s.users1==0,
 s.vm1==3 implies s.users1==0,
 s.vm1==1 implies s.users1==0}
 action enumerateHelper=all{s.phase==0,not(s.membersSealed),s'={...s,helperKnown:true}}
 action sealMembers=all{s.phase==0,s.helperKnown,s.mappingQualified,s'={...s,membersSealed:true}}
 action prepareOwned=all{s.phase==0,s.membersSealed,s'={...s,ownedFacade:true}}
 action exposeRaw=all{s.phase==0,s'={...s,rawEscape:true}}
 action reserveOwner=all{s.phase==0,s.vm1==0,s'={...s,vm1:1,ticketEpoch:s.epoch}}
 action commitOpen=all{s.phase==0,s.vm1==1,s'={...s,vm1:2,users1:1,closed1:false}}
 action closeGlobal=all{s.phase==0,s.membersSealed,s'={...s,phase:1,epoch:2,expected1:s.vm1!=0}}
 action commitClosing=all{s.phase==1,s.expected1,s.vm1==1,s'={...s,vm1:2,users1:1,closed1:true}}
 action abortReserved=all{s.vm1==1,s.phase<=1,s'={...s,vm1:3,closed1:true}}
 action unknownOwner=all{(s.vm1==1 or s.vm1==2),s.phase<=1,s'={...s,vm1:4,closed1:true,receipt1:false}}
 action close0=all{s.phase==1,s'={...s,closed0:true}}
 action close1=all{s.vm1==2,s.phase<=1,s'={...s,closed1:true}}
 action return0=all{s.users0==1,s'={...s,users0:0}}
 action return1=all{s.users1==1,s'={...s,users1:0}}
 action exitKnown=all{s.vm1==2,s.closed1,s.users1==0,s.phase<=1,s'={...s,vm1:3}}
 action reuseBeforeClose=all{s.phase==0,s.vm1==3,s.incarnation==1,s'={...s,vm1:0,incarnation:2,closed1:false,ticketEpoch:0}}
 action issue0=all{s.phase==1,s.closed0,s.users0==0,s'={...s,receipt0:true,receiptEpoch0:s.epoch}}
 action issue1=all{s.phase==1,s.expected1,s.closed1,s.users1==0,(s.vm1==2 or s.vm1==3),s'={...s,receipt1:true,receiptEpoch1:s.epoch,receiptInc1:s.incarnation}}
 action observe=all{s.phase==0,s.observers==0,s'={...s,observers:1}}
 action retireObserver=all{s.observers==1,s'={...s,observers:0}}
 action borrow0=all{s.phase==0,not(s.closed0),s.users0==0,s'={...s,users0:1}}
 action borrow1=all{s.phase==0,s.vm1==2,not(s.closed1),s.users1==0,s'={...s,users1:1}}
 action rejectLate=all{s.phase>=1,s'={...s,denied:s.denied+1}}
 action rejectStale=all{s.phase>=1,s'={...s,denied:s.denied+1}}
 action unknownExternal=all{s.phase<=1,s'={...s,externalDrained:false}}
 action permit=all{s.phase==1,s.membersSealed,s.ownedFacade,not(s.rawEscape),s.receipt0,(not(s.expected1) or s.receipt1),s.observers==0,s.externalDrained,s.vm1!=1,s.vm1!=4,s'={...s,phase:2}}
 action invalidateMembership=all{s.phase<=1,s'={...s,membersSealed:false,mappingQualified:false}}
 action step=any{enumerateHelper,sealMembers,prepareOwned,exposeRaw,reserveOwner,commitOpen,closeGlobal,commitClosing,abortReserved,unknownOwner,close0,close1,return0,return1,exitKnown,reuseBeforeClose,issue0,issue1,observe,retireObserver,borrow0,borrow1,rejectLate,rejectStale,unknownExternal,permit,invalidateMembership,all{s'=s}}
 run noSecondOwnerTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(closeGlobal).then(close0).then(return0).then(issue0).then(permit).then(all{assert(safe and not(s.expected1) and s.phase==2),s'=s})
 run reservedCommitAfterCloseTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(closeGlobal).then(close0).then(return0).then(issue0).then(commitClosing).then(return1).then(issue1).then(permit).then(all{assert(safe and s.expected1 and s.phase==2),s'=s})
 run knownAbortTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(closeGlobal).then(close0).then(return0).then(issue0).then(abortReserved).then(issue1).then(permit).then(all{assert(safe and s.vm1==3 and s.phase==2),s'=s})
 run unknownReservationTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(closeGlobal).then(close0).then(return0).then(issue0).then(unknownOwner).then(all{assert(safe and s.vm1==4 and s.expected1),s'=s})
 run exitAndTombstoneTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(commitOpen).then(closeGlobal).then(close0).then(return0).then(issue0).then(close1).then(return1).then(exitKnown).then(issue1).then(permit).then(all{assert(safe and s.phase==2 and s.vm1==3),s'=s})
 run newIncarnationTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(abortReserved).then(reuseBeforeClose).then(reserveOwner).then(commitOpen).then(closeGlobal).then(close0).then(return0).then(issue0).then(close1).then(return1).then(issue1).then(rejectStale).then(permit).then(all{assert(safe and s.receiptInc1==2 and s.phase==2),s'=s})
 run rawNotErasedTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(exposeRaw).then(closeGlobal).then(close0).then(return0).then(issue0).then(all{assert(safe and s.rawEscape and s.ownedFacade and s.phase==1),s'=s})
 run observerDrainTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(observe).then(closeGlobal).then(close0).then(return0).then(issue0).then(rejectLate).then(retireObserver).then(permit).then(all{assert(safe and s.phase==2 and s.denied==1),s'=s})
 run duplicateReceiptTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(abortReserved).then(closeGlobal).then(close0).then(return0).then(issue0).then(issue1).then(issue1).then(permit).then(all{assert(safe and s.phase==2),s'=s})
 run externalUnknownTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(closeGlobal).then(close0).then(return0).then(issue0).then(unknownExternal).then(all{assert(safe and not(s.externalDrained) and s.phase==1),s'=s})
 run omittedHelperControlTest=init.then(all{s'={...s,membersSealed:true}}).then(all{assert(not(safe)),s'=s})
 run lostReservationControlTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(closeGlobal).then(close0).then(return0).then(issue0).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
 run lateEnrollControlTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(closeGlobal).then(close0).then(return0).then(issue0).then(permit).then(all{s'={...s,vm1:1}}).then(all{assert(not(safe)),s'=s})
 run rawClearedByFacadeControlTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(exposeRaw).then(closeGlobal).then(close0).then(return0).then(issue0).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
 run staleVMReceiptControlTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(abortReserved).then(reuseBeforeClose).then(reserveOwner).then(abortReserved).then(closeGlobal).then(close0).then(return0).then(issue0).then(issue1).then(all{s'={...s,receiptInc1:1}}).then(all{assert(not(safe)),s'=s})
 run unknownExitControlTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(reserveOwner).then(closeGlobal).then(close0).then(return0).then(issue0).then(unknownOwner).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
 run observerDroppedControlTest=init.then(enumerateHelper).then(sealMembers).then(prepareOwned).then(observe).then(closeGlobal).then(close0).then(return0).then(issue0).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
}
