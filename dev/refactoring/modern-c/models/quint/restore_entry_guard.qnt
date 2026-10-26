module restore_entry_guard {
 // Two stable tickets and intent-qualified transitions; source receiver authority
 // and moving-GC coverage are external premises, not implemented gateways.
 type State={t0phase:int,t0witness:int,t0issued:int,t0settles:int,t0carrier:int,t0guard:bool,t0roots:bool,t0restored:bool,t0ack:bool,t1phase:int,t1witness:int,t1issued:int,t1settles:int,t1carrier:int,t1guard:bool,t1roots:bool,t1restored:bool,t1ack:bool,current:int,parent1:int,kind1:int,presented:int,nonce:int,hops:int,duplicates:int,rejected:int,markerCreated1:bool,markerLive1:bool}
 pure val initial:State={t0phase:0,t0witness:0,t0issued:0,t0settles:0,t0carrier:0,t0guard:false,t0roots:false,t0restored:false,t0ack:false,t1phase:0,t1witness:0,t1issued:0,t1settles:0,t1carrier:0,t1guard:false,t1roots:false,t1restored:false,t1ack:false,current:0,parent1:0,kind1:0,presented:1,nonce:101,hops:0,duplicates:0,rejected:0,markerCreated1:false,markerLive1:false}
 var s:State
 action init=s'=initial
 val safe=all{s.t0phase>=0,
s.t0phase<=7,
s.t0issued>=0,
s.t0issued<=1,
s.t0settles>=0,
s.t0settles<=1,
s.t0carrier>=0,
s.t0carrier<=2,
s.t0phase>0 implies (s.t0guard and s.t0issued==1),
s.t0phase==0 implies (s.t0issued==0 and not(s.t0guard) and s.t0settles==0),
s.t0phase==2 implies s.t0roots,
s.t0phase==3 implies s.t0roots,
s.t0phase==6 implies (s.t0settles==1 and s.t0witness==101 and s.t0restored),
s.t0phase!=6 implies s.t0settles==0,
s.t0witness!=0 implies ((s.t0phase==5 or s.t0phase==6) and s.t0witness==101 and s.t0restored),
s.t1phase>=0,
s.t1phase<=7,
s.t1issued>=0,
s.t1issued<=1,
s.t1settles>=0,
s.t1settles<=1,
s.t1carrier>=0,
s.t1carrier<=2,
s.t1phase>0 implies (s.t1guard and s.t1issued==1),
s.t1phase==0 implies (s.t1issued==0 and not(s.t1guard) and s.t1settles==0),
s.t1phase==2 implies s.t1roots,
s.t1phase==3 implies s.t1roots,
s.t1phase==6 implies (s.t1settles==1 and s.t1witness==102 and s.t1restored),
s.t1phase!=6 implies s.t1settles==0,
s.t1witness!=0 implies ((s.t1phase==5 or s.t1phase==6) and s.t1witness==102 and s.t1restored),
s.current>=0,
s.current<=2,
s.parent1==0 or s.parent1==1,
s.kind1>=0,
s.kind1<=2,
s.presented==1 or s.presented==2,
s.nonce==101 or s.nonce==102,
s.hops>=0,
s.duplicates>=0,
s.rejected>=0,
s.current==1 implies s.t0phase==2,
s.current==2 implies (s.t1phase==2 or s.t1phase==4 or s.t1phase==7),
s.t0phase==2 implies (s.current==1 or (s.parent1==1 and (s.t1phase==2 or s.t1phase==4 or s.t1phase==7))),
s.parent1==1 implies (s.t0phase==2 or s.t1phase==6),
s.t1phase>0 implies (s.kind1==1 or s.kind1==2),
s.kind1==2 implies s.parent1==1,
s.markerLive1 implies (s.markerCreated1 and s.kind1==2 and s.t1phase!=6),
(s.t1phase==5 or s.t1phase==6) implies not(s.markerLive1),
s.t1phase==2 implies (s.kind1==1 or s.markerCreated1),
s.parent1==1 implies s.t1phase>0,
s.kind1==1 implies s.parent1==0,
(s.t1phase==2 or s.t1phase==4 or s.t1phase==7) implies s.current==2,
(s.t0phase==4 or s.t0phase==7) implies s.t0roots,
(s.t1phase==4 or s.t1phase==7) implies s.t1roots}
 action reserveInitial0=all{s.t0phase==0,s.current==0,s'={...s,t0phase:1,t0guard:true,t0issued:1}}
 action publishRoot0=all{s.t0phase==1,s.t0guard,s'={...s,t0roots:true}}
 action enterInitial0=all{s.t0phase==1,s.t0roots,s.t0guard,s.current==0,s'={...s,t0phase:2,current:1,t0carrier:1}}
 action internalGraft0=all{s.t0phase==2,s.current==1,s'={...s,hops:s.hops+1}}
 action suspend0=all{s.t0phase==2,s.current==1,s.t1phase==0 or s.t1phase==6,s'={...s,t0phase:3,current:0}}
 action schedulerResume0=all{s.t0phase==3,s.t0roots,s.t0guard,s.current==0,s'={...s,t0phase:2,current:1,t0carrier:2}}
 action bodyReturn0=all{s.t0phase==2,s.current==1,s.t1phase==0 or s.t1phase==6,s'={...s,t0phase:4,current:0}}
 action restoreOuter0=all{s.t0phase==4,s'={...s,t0restored:true}}
 action observeExit0=all{s.t0phase==4,s.t0restored,s'={...s,t0phase:5,t0witness:101}}
 action settle0=all{s.t0phase==5,s.t0witness==101,s.t0guard,s.presented==1,s.nonce==101,s'={...s,t0phase:6,t0settles:1}}
 action reserveSemantic1=all{s.t0phase==6,s.t1phase==0,s.current==0,s'={...s,t1phase:1,t1guard:true,t1issued:1,parent1:0,kind1:1}}
 action reserveCrossRestore1=all{s.t0phase==2,s.current==1,s.t1phase==0,s'={...s,t0phase:7,current:0,t1phase:1,t1guard:true,t1issued:1,parent1:0,kind1:1}}
 action reserveForeignChild1=all{s.t0phase==2,s.current==1,s.t1phase==0,s'={...s,t1phase:1,t1guard:true,t1issued:1,parent1:1,kind1:2}}
 action publishRoot1=all{s.t1phase==1,s.t1guard,s'={...s,t1roots:true}}
 action allocateMarker1=all{s.t1phase==1,s.kind1==2,s.t1roots,not(s.markerCreated1),s'={...s,markerCreated1:true,markerLive1:true}}
 action enter1=all{s.t1phase==1,s.t1guard,s.t1roots,s.current==s.parent1,(s.kind1==1 or (s.kind1==2 and s.markerLive1)),s'={...s,t1phase:2,current:2,t1carrier:1}}
 action internalGraft1=all{s.t1phase==2,s.current==2,s'={...s,hops:s.hops+1}}
 action bodyReturn1=all{s.t1phase==2,s.current==2,s'={...s,t1phase:4}}
 action restoreOuter1=all{s.t1phase==4,s'={...s,t1restored:true}}
 action invalidateMarker1=all{s.t1phase==4,s.t1restored,s.markerLive1,s'={...s,markerLive1:false}}
 action observeExit1=all{s.t1phase==4,s.t1restored,not(s.markerLive1),s'={...s,t1phase:5,t1witness:102,current:s.parent1}}
 action settle1=all{s.t1phase==5,s.t1witness==102,s.t1guard,s.presented==2,s.nonce==102,s'={...s,t1phase:6,t1settles:1}}
 action abortMarkerAllocation1=all{s.t1phase==1,s.kind1==2,not(s.markerCreated1),s'={...s,t1phase:5,t1restored:true,t1witness:102}}
 action unknownForeignExit1=all{s.t1phase==2,s.current==2,s'={...s,t1phase:7}}
 action confirmOuterCatch1=all{s.t1phase==7,s.current==2,s'={...s,t1phase:4}}
 action presentOld=all{true,s'={...s,presented:1,nonce:101}}
 action presentNew=all{true,s'={...s,presented:2,nonce:102}}
 action presentOldAsNew=all{true,s'={...s,presented:2,nonce:101}}
 action rejectMismatchedGuard=all{s.presented==2,s.nonce!=102,s'={...s,rejected:s.rejected+1}}
 action repeatOldReceipt=all{s.t0phase==6,s.presented==1,s.nonce==101,s'={...s,duplicates:s.duplicates+1}}
 action rejectUnobservedOldExit=all{s.t0phase==7,s.presented==1,s.nonce==101,s'={...s,rejected:s.rejected+1}}
 action loseReply0=all{s.t0phase==6,s'={...s,t0ack:false}}
 action query0=all{s.t0phase==6,s.presented==1,s.nonce==101,s'={...s,t0ack:true}}
 action loseReply1=all{s.t1phase==6,s'={...s,t1ack:false}}
 action query1=all{s.t1phase==6,s.presented==2,s.nonce==102,s'={...s,t1ack:true}}
 action step=any{reserveInitial0,publishRoot0,enterInitial0,internalGraft0,suspend0,schedulerResume0,bodyReturn0,restoreOuter0,observeExit0,settle0,reserveSemantic1,reserveCrossRestore1,reserveForeignChild1,publishRoot1,allocateMarker1,enter1,internalGraft1,bodyReturn1,restoreOuter1,invalidateMarker1,observeExit1,settle1,abortMarkerAllocation1,unknownForeignExit1,confirmOuterCatch1,presentOld,presentNew,presentOldAsNew,rejectMismatchedGuard,repeatOldReceipt,rejectUnobservedOldExit,loseReply0,query0,loseReply1,query1,all{s'=s}}
 run schedulerKeepsIdTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(suspend0).then(schedulerResume0).then(internalGraft0).then(suspend0).then(schedulerResume0).then(all{assert(s.t0issued==1 and s.t1issued==0 and s.t0carrier==2 and safe),s'=s})
 run navigationKeepsIdTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(internalGraft0).then(internalGraft0).then(internalGraft0).then(all{assert(s.hops==3 and s.t0issued==1 and s.t1issued==0 and safe),s'=s})
 run semanticReplayFreshIdTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(bodyReturn0).then(restoreOuter0).then(observeExit0).then(settle0).then(reserveSemantic1).then(publishRoot1).then(enter1).then(internalGraft1).then(all{assert(s.t0phase==6 and s.t1phase==2 and s.t0issued==1 and s.t1issued==1 and safe),s'=s})
 run oldReceiptDuringNewTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(bodyReturn0).then(restoreOuter0).then(observeExit0).then(settle0).then(reserveSemantic1).then(publishRoot1).then(enter1).then(presentOld).then(repeatOldReceipt).then(all{assert(s.t1phase==2 and s.t1settles==0 and s.duplicates==1 and safe),s'=s})
 run oldGuardAsNewControlTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(bodyReturn0).then(restoreOuter0).then(observeExit0).then(settle0).then(reserveSemantic1).then(publishRoot1).then(enter1).then(presentOldAsNew).then(rejectMismatchedGuard).then(all{assert(s.t1settles==0 and s.t1phase==2 and s.rejected==1 and safe),s'=s})
 run foreignChildTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(reserveForeignChild1).then(publishRoot1).then(allocateMarker1).then(enter1).then(bodyReturn1).then(restoreOuter1).then(invalidateMarker1).then(observeExit1).then(presentNew).then(settle1).then(presentOld).then(bodyReturn0).then(restoreOuter0).then(observeExit0).then(settle0).then(all{assert(s.t0settles==1 and s.t1settles==1 and safe),s'=s})
 run bodyReturnNotCompleteControlTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(reserveForeignChild1).then(publishRoot1).then(allocateMarker1).then(enter1).then(bodyReturn1).then(all{assert(s.t1phase==4 and s.markerLive1 and s.t1witness==0 and s.t1settles==0 and safe),s'=s})
 run catcherRestoreNotCompleteControlTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(reserveForeignChild1).then(publishRoot1).then(allocateMarker1).then(enter1).then(bodyReturn1).then(restoreOuter1).then(all{assert(s.markerLive1 and s.t1witness==0 and s.t1settles==0 and safe),s'=s})
 run unknownExitRetainsTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(reserveForeignChild1).then(publishRoot1).then(allocateMarker1).then(enter1).then(unknownForeignExit1).then(all{assert(s.t1phase==7 and s.t1guard and s.t1roots and s.t1settles==0 and safe),s'=s})
 run outerCatchRecoveryTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(reserveForeignChild1).then(publishRoot1).then(allocateMarker1).then(enter1).then(unknownForeignExit1).then(confirmOuterCatch1).then(restoreOuter1).then(invalidateMarker1).then(observeExit1).then(presentNew).then(settle1).then(all{assert(s.t1phase==6 and s.t0phase==2 and s.current==1 and safe),s'=s})
 run markerAllocationFailureTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(reserveForeignChild1).then(publishRoot1).then(abortMarkerAllocation1).then(presentNew).then(settle1).then(all{assert(s.t1phase==6 and not(s.markerCreated1) and s.current==1 and safe),s'=s})
 run crossRestoreEscrowTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(reserveCrossRestore1).then(publishRoot1).then(enter1).then(presentOld).then(rejectUnobservedOldExit).then(all{assert(s.t0phase==7 and s.t0guard and s.t0roots and s.t1phase==2 and s.t0settles==0 and safe),s'=s})
 run ackLossDoesNotReenterTest=init.then(reserveInitial0).then(publishRoot0).then(enterInitial0).then(bodyReturn0).then(restoreOuter0).then(observeExit0).then(settle0).then(loseReply0).then(query0).then(query0).then(all{assert(s.t0issued==1 and s.t0settles==1 and s.t0ack and safe),s'=s})
}
