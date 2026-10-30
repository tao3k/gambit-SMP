module primitive_header_binding {
 // demand: 0 empty; 1 exact singleton empty-string; 2 other nonempty list.
 // Single supplied primitive. Source alias closure and verifier correctness are external.
 type State={phase:int,demand:int,headerDemand:int,member:bool,prm:bool,glo:bool,spec:bool,coverage:bool,closed:bool,receipt:bool}
 pure val initial:State={phase:0,demand:0,headerDemand:0,member:false,prm:false,glo:false,spec:false,coverage:false,closed:false,receipt:false}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,
s.phase<=6,
s.demand>=0,
s.demand<=2,
s.headerDemand>=0,
s.headerDemand<=2,
s.phase>=1 implies s.member,
s.prm implies (s.phase>=2 and s.demand==1),
s.phase>=2 implies s.prm,
s.glo implies (s.phase>=3 and s.prm),
s.phase>=3 implies s.glo,
s.spec implies (s.phase>=4 and s.glo),
s.phase>=4 implies s.spec,
s.coverage implies s.spec,
s.closed implies s.spec,
s.receipt implies (s.phase==5 and s.coverage and s.closed),
s.phase==5 implies s.receipt}
 action seedSupply=all{s.phase==0,not(s.member),s'={...s,member:true}}
 action seedDemand=all{s.phase==0,s.member,s'={...s,demand:1}}
 action seedOtherDemand=all{s.phase==0,s.member,s'={...s,demand:2}}
 action writeHeader=all{s.phase==0,s.member,s'={...s,phase:1,headerDemand:s.demand}}
 action emitPrm=all{s.phase==1,s.member,s'={...s,phase:2,prm:true,demand:1}}
 action emitGlo=all{s.phase==2,s.prm,s'={...s,phase:3,glo:true,demand:1}}
 action sealSpec=all{s.phase==3,s.glo,s'={...s,phase:4,spec:true}}
 action checkCoverage=all{s.phase==4,s.spec,s'={...s,coverage:true}}
 action closePair=all{s.phase==4,s.spec,s'={...s,closed:true}}
 action issue=all{s.phase==4,s.coverage,s.closed,s'={...s,phase:5,receipt:true}}
 action unknownOutput=all{s.phase==4,s'={...s,phase:6}}
 action rejectLateUse=all{s.phase>=1,s'={...s,demand:s.demand}}
 action step=any{seedSupply,seedDemand,seedOtherDemand,writeHeader,emitPrm,emitGlo,sealSpec,checkCoverage,closePair,issue,unknownOutput,rejectLateUse,all{s'=s}}
 run suppliedOnlyTest=init.then(seedSupply).then(writeHeader).then(emitPrm).then(emitGlo).then(sealSpec).then(checkCoverage).then(closePair).then(issue).then(all{assert(safe and s.headerDemand==0 and s.demand==1 and s.receipt),s'=s})
 run canonicalTest=init.then(seedSupply).then(seedDemand).then(writeHeader).then(emitPrm).then(emitGlo).then(sealSpec).then(checkCoverage).then(closePair).then(issue).then(all{assert(safe and s.headerDemand==1 and s.receipt),s'=s})
 run noncanonicalTest=init.then(seedSupply).then(seedOtherDemand).then(writeHeader).then(emitPrm).then(emitGlo).then(sealSpec).then(checkCoverage).then(closePair).then(issue).then(all{assert(safe and s.headerDemand==2 and s.demand==1 and s.receipt),s'=s})
 run unknownTest=init.then(seedSupply).then(writeHeader).then(emitPrm).then(emitGlo).then(sealSpec).then(unknownOutput).then(all{assert(safe and not(s.receipt) and s.phase==6),s'=s})
 run lateRejectedTest=init.then(seedSupply).then(writeHeader).then(rejectLateUse).then(emitPrm).then(emitGlo).then(sealSpec).then(checkCoverage).then(closePair).then(issue).then(all{assert(safe and s.headerDemand==0 and s.receipt),s'=s})
 run reversedCloseTest=init.then(seedSupply).then(writeHeader).then(emitPrm).then(emitGlo).then(sealSpec).then(closePair).then(checkCoverage).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run missingBindingControlTest=init.then(seedSupply).then(writeHeader).then(all{s'={...s,phase:3,glo:true}}).then(all{assert(not(safe)),s'=s})
 run missingCoverageControlTest=init.then(seedSupply).then(writeHeader).then(emitPrm).then(emitGlo).then(sealSpec).then(closePair).then(all{s'={...s,phase:5,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run missingCloseControlTest=init.then(seedSupply).then(writeHeader).then(emitPrm).then(emitGlo).then(sealSpec).then(checkCoverage).then(all{s'={...s,phase:5,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run lostDemandControlTest=init.then(seedSupply).then(writeHeader).then(emitPrm).then(all{s'={...s,demand:0}}).then(all{assert(not(safe)),s'=s})
 run hoistChangesHeaderTest=init.then(seedSupply).then(seedDemand).then(writeHeader).then(all{assert(safe and s.headerDemand!=0),s'=s})
}
