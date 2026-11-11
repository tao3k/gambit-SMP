module pending_start_composition {
 type State={phase:int,round:int,sourceA:bool,sourceB:bool,pendingA:bool,pendingB:bool,contextA:bool,contextB:bool,ackA:bool,ackB:bool,launchA:bool,launchB:bool,startA:bool,readyA:bool,memberA:bool,failedB:bool,doneB:bool,unknownB:bool,scanLease:bool,viewSourceA:bool,viewSourceB:bool,viewPendingA:bool,viewPendingB:bool,viewContextA:bool,viewContextB:bool}
 pure val initial:State={phase:0,round:0,sourceA:true,sourceB:true,pendingA:false,pendingB:false,contextA:false,contextB:false,ackA:false,ackB:false,launchA:false,launchB:false,startA:false,readyA:false,memberA:false,failedB:false,doneB:false,unknownB:false,scanLease:false,viewSourceA:false,viewSourceB:false,viewPendingA:false,viewPendingB:false,viewContextA:false,viewContextB:false}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,s.phase<=2,s.round>=0,s.round<=2,
 s.sourceA or s.pendingA or s.contextA,
 s.doneB or s.sourceB or s.pendingB or s.contextB,
 not(s.pendingA and s.contextA),not(s.pendingB and s.contextB),
 s.launchA implies (s.pendingA or s.contextA),s.launchB implies (s.pendingB or s.contextB),
 s.contextA implies (s.launchA and s.readyA and s.memberA),
 s.unknownB implies s.sourceB,
 s.ackA implies (s.pendingA or s.contextA),s.ackB implies (s.pendingB or s.contextB),
 s.viewSourceA implies s.sourceA,s.viewSourceB implies s.sourceB,
 s.viewPendingA implies s.pendingA,s.viewPendingB implies s.pendingB,
 s.viewContextA implies s.contextA,s.viewContextB implies s.contextB,
 s.scanLease implies s.phase>0}
 action registerA=all{s.phase==0,s.sourceA,not(s.pendingA),not(s.contextA),s'={...s,pendingA:true,ackA:true}}
 action registerB=all{s.phase==0,s.sourceB,not(s.pendingB),not(s.contextB),not(s.doneB),s'={...s,pendingB:true,ackB:true}}
 action launchA=all{s.pendingA,s.ackA,s'={...s,launchA:true}}
 action launchBUnknown=all{s.pendingB,s.sourceB,not(s.failedB),s'={...s,launchB:true,unknownB:true,ackB:false}}
 action startA=all{s.launchA,s'={...s,startA:true}}
 // Qualified context/collective readiness receipt; not inferred from OS success.
 action readyA=all{s.phase==0,s.startA,s'={...s,readyA:true,memberA:true}}
 action releaseSourceA=all{s.phase==0,s.ackA,s.pendingA or s.contextA,s'={...s,sourceA:false}}
 action releaseSourceB=all{s.phase==0,s.ackB,not(s.unknownB),s.pendingB or s.contextB,s'={...s,sourceB:false}}
 action adoptA=all{s.phase==0,s.pendingA,not(s.contextA),s.launchA,s.startA,s.readyA,s.memberA,s.ackA,s'={...s,pendingA:false,contextA:true}}
 action rejectB=all{not(s.launchB),not(s.unknownB),s'={...s,failedB:true}}
 // Authenticated failure-result delivery; a failure flag alone is insufficient.
 action settleFailureB=all{s.failedB,not(s.launchB),not(s.unknownB),s'={...s,doneB:true}}
 action rollbackB=all{s.phase==0,s.failedB,s.doneB,not(s.launchB),not(s.unknownB),not(s.contextB),s'={...s,pendingB:false,ackB:false}}
 action resolveB=all{s.launchB,s.unknownB,s'={...s,unknownB:false,ackB:true}}
 action freeze=all{s.phase==0,s.round<2,s'={...s,phase:1,round:s.round+1,viewSourceA:s.sourceA,viewSourceB:s.sourceB,viewPendingA:s.pendingA,viewPendingB:s.pendingB,viewContextA:s.contextA,viewContextB:s.contextB}}
 action borrowScan=all{s.phase>0,s'={...s,scanLease:true}}
 action finishScan=all{s.phase==1,s'={...s,phase:2}}
 action returnScan=all{s'={...s,scanLease:false}}
 action restore=all{s.phase==2,not(s.scanLease),s'={...s,phase:0,viewSourceA:false,viewSourceB:false,viewPendingA:false,viewPendingB:false,viewContextA:false,viewContextB:false}}
 action step=any{registerA,registerB,launchA,launchBUnknown,startA,readyA,releaseSourceA,releaseSourceB,adoptA,rejectB,settleFailureB,rollbackB,resolveB,freeze,borrowScan,finishScan,returnScan,restore,all{s'=s}}
 action setup=registerA.then(registerB).then(launchA).then(startA)
 run partialBatchKeepsCreatedTest=init.then(setup).then(rejectB).then(settleFailureB).then(rollbackB).then(readyA).then(adoptA).then(releaseSourceA).then(freeze).then(finishScan).then(restore).then(all{assert(safe and s.contextA and not(s.pendingB)),s'=s})
 run frozenAdoptionWaitTest=init.then(setup).then(readyA).then(freeze).then(borrowScan).then(finishScan).then(all{assert(safe and s.pendingA and s.viewPendingA),s'=s}).then(returnScan).then(restore).then(adoptA).then(releaseSourceA).then(freeze).then(finishScan).then(restore).then(all{assert(safe and s.contextA),s'=s})
 run unknownSecondRetainsSourceTest=init.then(setup).then(launchBUnknown).then(freeze).then(finishScan).then(restore).then(all{assert(safe and s.sourceB and s.unknownB and s.pendingB),s'=s}).then(resolveB).then(releaseSourceB).then(all{assert(safe),s'=s})
 run rejectedWhileFrozenTest=init.then(setup).then(freeze).then(rejectB).then(settleFailureB).then(finishScan).then(restore).then(rollbackB).then(all{assert(safe and s.launchA and s.pendingA),s'=s})
 run frozenAdoptionControlTest=init.then(setup).then(readyA).then(freeze).then(all{s'={...s,pendingA:false,contextA:true}}).then(all{assert(not(safe)),s'=s})
 run batchClearCreatedControlTest=init.then(setup).then(rejectB).then(all{s'={...s,pendingA:false,sourceA:false}}).then(all{assert(not(safe)),s'=s})
 run unknownRollbackControlTest=init.then(setup).then(launchBUnknown).then(all{s'={...s,sourceB:false,pendingB:false}}).then(all{assert(not(safe)),s'=s})
 run unregisterFrozenSourceControlTest=init.then(setup).then(freeze).then(all{s'={...s,sourceA:false}}).then(all{assert(not(safe)),s'=s})
}
