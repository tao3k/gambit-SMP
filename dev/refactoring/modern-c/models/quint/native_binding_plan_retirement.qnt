module native_binding_plan_retirement {
 // Conditional managed-session admission; source hooks and error prefixes remain external.
 type State={stage:int,epoch:int,planEpoch:int,mode:int,demand:int,headerDemand:int,prmCount:int,gloCount:int,entry:bool,layout:bool,exclusive:bool,noObservers:bool,sealed:bool,first:bool,second:bool,prm:bool,glo:bool,paused:bool,revoked:bool,custody:bool,closed:bool,receipt:bool}
 pure val initial:State={stage:0,epoch:1,planEpoch:0,mode:0,demand:0,headerDemand:0,prmCount:0,gloCount:0,entry:false,layout:false,exclusive:false,noObservers:false,sealed:false,first:false,second:false,prm:false,glo:false,paused:false,revoked:false,custody:false,closed:false,receipt:false}
 var s:State
 action init=s'=initial
 val safe=all{s.stage>=0,
s.stage<=6,
s.epoch>=1,
s.planEpoch>=0,
s.mode>=0,
s.mode<=2,
s.demand>=0,
s.demand<=2,
s.headerDemand>=0,
s.headerDemand<=2,
s.prmCount>=0,
s.prmCount<=1,
s.gloCount>=0,
s.gloCount<=1,
s.sealed implies (s.stage>=2 and s.entry and s.layout and s.custody and s.mode>=1),
s.stage>=2 implies s.sealed,
(s.sealed and not(s.revoked)) implies (s.planEpoch==s.epoch and s.exclusive),
s.first implies s.sealed,
s.second implies (s.prm and s.first),
s.prm implies (s.first and s.prmCount==1),
s.glo implies (s.second and s.gloCount==1),
s.prmCount==1 implies s.prm,
s.gloCount==1 implies s.glo,
s.closed implies s.glo,
(s.first and s.mode==1 and not(s.revoked)) implies s.noObservers,
(s.first and s.mode==2 and not(s.revoked)) implies s.demand==1,
s.receipt implies (s.stage==5 and s.closed and s.glo and not(s.revoked) and not(s.paused)),
s.stage==5 implies s.receipt,
s.prm implies s.stage>=3,
s.glo implies s.stage>=4,
(s.stage>=3 and s.stage<=5) implies s.prm,
(s.stage>=4 and s.stage<=5) implies s.glo}
 action discover=all{s.stage==0,s'={...s,entry:true}}
 action resolve=all{s.stage==0,s.entry,s'={...s,layout:true}}
 action closeWriters=all{s.stage==0,s'={...s,exclusive:true}}
 action admitElision=all{s.stage==0,s'={...s,mode:1,noObservers:true}}
 action requireMetadata=all{s.stage==0,s'={...s,mode:2,noObservers:false}}
 action writeHeader=all{s.stage==0,s.entry,s'={...s,stage:1,headerDemand:s.demand}}
 action sealPlan=all{s.stage==1,s.entry,s.layout,s.exclusive,s.mode>=1,s.mode<=2,s'={...s,stage:2,sealed:true,planEpoch:s.epoch,custody:true}}
 action firstElide=all{s.stage==2,s.mode==1,s.noObservers,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),not(s.first),s'={...s,first:true}}
 action firstPreserve=all{s.stage==2,s.mode==2,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),not(s.first),s'={...s,first:true,demand:1}}
 action emitPrm=all{s.stage==2,s.first,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),s'={...s,stage:3,prm:true,prmCount:s.prmCount+1}}
 action secondElide=all{s.stage==3,s.mode==1,s.noObservers,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),s'={...s,second:true}}
 action secondPreserve=all{s.stage==3,s.mode==2,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),s'={...s,second:true,demand:1}}
 action emitGlo=all{s.stage==3,s.second,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),s'={...s,stage:4,glo:true,gloCount:s.gloCount+1}}
 action closeOutput=all{s.stage==4,s.glo,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),s'={...s,closed:true}}
 action issue=all{s.stage==4,s.closed,s.exclusive,s.planEpoch==s.epoch,not(s.revoked),not(s.paused),s'={...s,stage:5,receipt:true}}
 action pause=all{s.stage>=2,s.stage<=4,not(s.paused),s'={...s,paused:true}}
 action resumeSame=all{s.stage>=2,s.stage<=4,s.paused,s.planEpoch==s.epoch,s.exclusive,not(s.revoked),s'={...s,paused:false}}
 action foreignReentry=all{s.stage>=2,s.stage<=4,s.paused,s'={...s,epoch:s.epoch+1,revoked:true}}
 action lateWriter=all{s.stage>=2,s.stage<=4,s'={...s,demand:2,exclusive:false,revoked:true}}
 action escapedObserver=all{s.stage>=2,s.stage<=4,s'={...s,noObservers:false,revoked:true}}
 action unknownExit=all{s.stage>=2,s.stage<=4,s'={...s,stage:6,paused:false,revoked:true}}
 action rejectResume=all{s.stage>=2,s.stage<=4,s.paused,s.revoked,s'={...s,stage:6,paused:false}}
 action step=any{discover,resolve,closeWriters,admitElision,requireMetadata,writeHeader,sealPlan,firstElide,firstPreserve,emitPrm,secondElide,secondPreserve,emitGlo,closeOutput,issue,pause,resumeSame,foreignReentry,lateWriter,escapedObserver,unknownExit,rejectResume,all{s'=s}}
 run elisionTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(firstElide).then(emitPrm).then(secondElide).then(emitGlo).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.demand==0 and s.headerDemand==0),s'=s})
 run metadataTest=init.then(discover).then(resolve).then(closeWriters).then(requireMetadata).then(writeHeader).then(sealPlan).then(firstPreserve).then(emitPrm).then(secondPreserve).then(emitGlo).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.demand==1 and s.headerDemand==0),s'=s})
 run resumeBeforeFirstTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(pause).then(resumeSame).then(firstElide).then(emitPrm).then(secondElide).then(emitGlo).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.prmCount==1),s'=s})
 run resumeAfterPrmTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(firstElide).then(emitPrm).then(pause).then(resumeSame).then(secondElide).then(emitGlo).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.prmCount==1 and s.gloCount==1),s'=s})
 run nestedRejectTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(pause).then(foreignReentry).then(rejectResume).then(all{assert(safe and s.custody and not(s.receipt) and s.stage==6),s'=s})
 run lateWriterRevokesTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(firstElide).then(emitPrm).then(lateWriter).then(unknownExit).then(all{assert(safe and s.custody and s.revoked),s'=s})
 run aliasRevokesTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(escapedObserver).then(unknownExit).then(all{assert(safe and s.custody and not(s.receipt)),s'=s})
 run unknownAfterPrmTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(firstElide).then(emitPrm).then(unknownExit).then(all{assert(safe and s.custody and s.prmCount==1 and not(s.receipt)),s'=s})
 run staleEpochControlTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(all{s'={...s,epoch:s.epoch+1}}).then(all{assert(not(safe)),s'=s})
 run duplicatePrmControlTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(firstElide).then(emitPrm).then(all{s'={...s,prmCount:2}}).then(all{assert(not(safe)),s'=s})
 run falseElisionControlTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(all{s'={...s,first:true,noObservers:false}}).then(all{assert(not(safe)),s'=s})
 run missingCloseControlTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(firstElide).then(emitPrm).then(secondElide).then(emitGlo).then(all{s'={...s,stage:5,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run lostCustodyControlTest=init.then(discover).then(resolve).then(closeWriters).then(admitElision).then(writeHeader).then(sealPlan).then(unknownExit).then(all{s'={...s,custody:false}}).then(all{assert(not(safe)),s'=s})
}
