module restore_entry_issuers {
 // Input source classification and outer witness provenance are external premises.
 type State={intent:int,source:int,sourceRoot:int,pin:int,carrier:int,version:int,copiedVersion:int,guard:int,issued:int,marker:int,handoff:int,escrow:int,outer:int,reuses:int,allocations:int,rejected:int}
 pure val initial:State={intent:0,source:0,sourceRoot:0,pin:0,carrier:0,version:0,copiedVersion:0,guard:0,issued:0,marker:0,handoff:0,escrow:0,outer:0,reuses:0,allocations:0,rejected:0}
 var s:State
 action init=s'=initial
 val safe=all{s.intent>=0,
s.intent<=5,
s.source>=0,
s.source<=3,
s.sourceRoot>=0,
s.sourceRoot<=1,
s.pin>=0,
s.pin<=1,
s.carrier>=0,
s.carrier<=1,
s.guard>=0,
s.guard<=5,
s.issued>=0,
s.issued<=1,
s.marker>=0,
s.marker<=1,
s.handoff>=0,
s.handoff<=1,
s.escrow>=0,
s.escrow<=1,
s.outer>=0,
s.outer<=1,
s.version>=0,
s.copiedVersion>=0,
s.reuses>=0,
s.allocations>=0,
s.rejected>=0,
s.guard>0 implies (s.issued==1 and s.carrier==1 and (s.intent==1 or s.intent==4)),
s.issued==1 implies s.guard>0,
s.carrier==1 implies ((s.source==1 or s.source==2) and s.copiedVersion==s.version and (s.intent==1 or s.intent==4)),
s.pin==1 implies (s.sourceRoot==1 and (s.source==1 or s.source==2) and (s.intent==1 or s.intent==4)),
s.source==0 implies (s.sourceRoot==0 and s.carrier==0 and s.pin==0),
s.source==3 implies (s.sourceRoot==0 and s.carrier==0 and s.pin==0),
s.marker==1 implies (s.intent==4 and s.guard>=2),
s.handoff==1 implies (s.guard>=2 and s.carrier==1),
s.escrow==1 implies (s.carrier==1 and s.guard!=5),
s.guard==5 implies (s.marker==0 and s.outer==1),
s.outer==1 implies s.guard>=3,
s.sourceRoot==1 implies (s.source==1 or s.source==2),
s.guard==0 implies s.handoff==0}
 action classifyFresh=all{(s.intent==0),(s.guard==0),s'={...s,intent:1}}
 action classifyNavigation=all{(s.intent==0),(s.guard==0),s'={...s,intent:2}}
 action classifyScheduler=all{(s.intent==0),(s.guard==0),s'={...s,intent:3}}
 action classifyForeign=all{(s.intent==0),(s.guard==0),s'={...s,intent:4}}
 action classifyConversion=all{(s.intent==0),(s.guard==0),s'={...s,intent:5}}
 action sourceFrame=all{(s.source==0),(s.guard==0),s'={...s,source:1,sourceRoot:1}}
 action sourceRc=all{(s.source==0),(s.guard==0),s'={...s,source:2,sourceRoot:1}}
 action sourceRaw=all{(s.source==0),(s.guard==0),s'={...s,source:3,sourceRoot:0}}
 action pinSource=all{(s.guard==0),(s.sourceRoot==1),(s.intent==1 or s.intent==4),s'={...s,pin:1}}
 action publishCarrier=all{(s.guard==0),(s.pin==1),(s.sourceRoot==1),s'={...s,carrier:1,copiedVersion:s.version}}
 action gcSourceOnly=all{(s.sourceRoot==1),(s.carrier==0),s'={...s,version:s.version+1}}
 action gcPublished=all{(s.carrier==1),s'={...s,version:s.version+1,copiedVersion:s.copiedVersion+1}}
 action reserveGuard=all{(s.guard==0),(s.carrier==1),s'={...s,guard:1,issued:1,allocations:s.allocations+1}}
 action guardAllocationFails=all{(s.guard==0),(s.carrier==1),s'={...s,escrow:1}}
 action publishGuard=all{(s.guard==1),s'={...s,guard:2,escrow:0}}
 action releaseSource=all{(s.guard>=2),(s.sourceRoot==1),s'={...s,sourceRoot:0,pin:0,handoff:1}}
 action allocateMarker=all{(s.guard==2),(s.intent==4),(s.marker==0),s'={...s,marker:1,allocations:s.allocations+1}}
 action enter=all{(s.guard==2),(s.intent==1 or s.marker==1),s'={...s,guard:3}}
 action exceptionToOwner=all{(s.guard>=1),(s.guard<=3),s'={...s,guard:4,escrow:1}}
 action observeOuter=all{(s.guard==3 or s.guard==4),s'={...s,outer:1}}
 action killMarker=all{(s.outer==1),(s.marker==1),s'={...s,marker:0}}
 action complete=all{(s.guard==3 or s.guard==4),(s.outer==1),(s.marker==0),s'={...s,guard:5,escrow:0}}
 action reuseExisting=all{(s.guard==0),(s.sourceRoot==1),(s.intent==2 or s.intent==3 or s.intent==5),s'={...s,reuses:s.reuses+1}}
 action rejectRaw=all{(s.source==3),(s.guard==0),s'={...s,rejected:s.rejected+1}}
 action recoverPreAdmission=all{(s.guard==0),(s.escrow==1),(s.sourceRoot==1),s'={...s,carrier:0,escrow:0,copiedVersion:0}}
 action step=any{classifyFresh,classifyNavigation,classifyScheduler,classifyForeign,classifyConversion,sourceFrame,sourceRc,sourceRaw,pinSource,publishCarrier,gcSourceOnly,gcPublished,reserveGuard,guardAllocationFails,publishGuard,releaseSource,allocateMarker,enter,exceptionToOwner,observeOuter,killMarker,complete,reuseExisting,rejectRaw,recoverPreAdmission,all{s'=s}}
 run freshBootstrapTest=init.then(classifyFresh).then(sourceFrame).then(pinSource).then(gcSourceOnly).then(publishCarrier).then(reserveGuard).then(gcPublished).then(publishGuard).then(releaseSource).then(enter).then(all{assert(s.guard==3 and s.issued==1 and s.carrier==1 and s.sourceRoot==0 and s.copiedVersion==s.version and safe),s'=s})
 run foreignBootstrapTest=init.then(classifyForeign).then(sourceRc).then(pinSource).then(publishCarrier).then(reserveGuard).then(publishGuard).then(releaseSource).then(gcPublished).then(allocateMarker).then(enter).then(observeOuter).then(killMarker).then(complete).then(all{assert(s.guard==5 and s.marker==0 and s.allocations==2 and safe),s'=s})
 run rawDeniedTest=init.then(classifyForeign).then(sourceRaw).then(rejectRaw).then(rejectRaw).then(all{assert(s.guard==0 and s.issued==0 and s.allocations==0 and safe),s'=s})
 run schedulerReuseTest=init.then(classifyScheduler).then(sourceFrame).then(reuseExisting).then(reuseExisting).then(reuseExisting).then(all{assert(s.reuses==3 and s.issued==0 and s.allocations==0 and safe),s'=s})
 run navigationReuseTest=init.then(classifyNavigation).then(sourceFrame).then(reuseExisting).then(reuseExisting).then(all{assert(s.reuses==2 and s.issued==0 and safe),s'=s})
 run conversionReuseTest=init.then(classifyConversion).then(sourceRc).then(reuseExisting).then(all{assert(s.reuses==1 and s.allocations==0 and safe),s'=s})
 run allocationFailureTest=init.then(classifyForeign).then(sourceRc).then(pinSource).then(publishCarrier).then(guardAllocationFails).then(gcPublished).then(all{assert(s.escrow==1 and s.carrier==1 and s.issued==0 and safe),s'=s})
 run preAdmissionRecoveryTest=init.then(classifyFresh).then(sourceFrame).then(pinSource).then(publishCarrier).then(guardAllocationFails).then(gcPublished).then(recoverPreAdmission).then(all{assert(s.sourceRoot==1 and s.carrier==0 and s.guard==0 and safe),s'=s})
 run unknownCustodyTest=init.then(classifyForeign).then(sourceRc).then(pinSource).then(publishCarrier).then(reserveGuard).then(publishGuard).then(releaseSource).then(allocateMarker).then(enter).then(exceptionToOwner).then(gcPublished).then(all{assert(s.guard==4 and s.escrow==1 and s.carrier==1 and s.marker==1 and safe),s'=s})
 run outerRecoveryTest=init.then(classifyForeign).then(sourceRc).then(pinSource).then(publishCarrier).then(reserveGuard).then(publishGuard).then(allocateMarker).then(enter).then(exceptionToOwner).then(observeOuter).then(killMarker).then(complete).then(all{assert(s.guard==5 and s.escrow==0 and safe),s'=s})
}
