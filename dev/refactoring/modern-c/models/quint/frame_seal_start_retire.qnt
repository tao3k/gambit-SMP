module frame_seal_start_retire {
 // Atomic abstract ledger; NOT a C11 weak-memory model or a native implementation.
 type State={generation:int,saved:int,ticket:int,phase:int,nativePins:int,frames:int,roots:int,maintenance:int,observers:int,denied:int,writer:bool,guard:bool,suspended:bool,sealed:bool,opaqueExport:bool,admit:bool,copyPin:bool,revocationWins:bool,unknown:bool,reclaimed:bool}
 pure val initial:State={generation:1,saved:0,ticket:0,phase:0,nativePins:0,frames:1,roots:1,maintenance:0,observers:0,denied:0,writer:true,guard:true,suspended:false,sealed:false,opaqueExport:false,admit:true,copyPin:false,revocationWins:false,unknown:false,reclaimed:false}
 var s:State
 action init=s'=initial
 val safe=all{s.generation>=1,
 s.saved>=0,
 s.saved<=s.generation,
 s.ticket>=0,
 s.ticket<=s.generation,
 s.phase>=0,
 s.phase<=4,
 s.nativePins>=0,
 s.nativePins<=1,
 s.frames>=0,
 s.frames<=1,
 s.roots>=0,
 s.roots<=1,
 s.maintenance>=0,
 s.maintenance<=1,
 s.observers>=0,
 s.observers<=1,
 s.denied>=0,
 s.sealed implies (not(s.writer) and not(s.guard) and not(s.suspended) and not(s.opaqueExport)),
 s.phase==1 implies (s.sealed and not(s.reclaimed)),
 s.phase==2 implies (s.sealed and s.copyPin and not(s.revocationWins) and not(s.reclaimed)),
 s.copyPin implies s.phase==2,
 s.revocationWins implies s.phase!=2,
 s.reclaimed implies (not(s.admit) and not(s.guard) and not(s.suspended) and not(s.writer) and s.phase!=1 and s.phase!=2 and not(s.copyPin) and s.nativePins==0 and s.frames==0 and s.roots==0 and s.maintenance==0 and s.observers==0 and not(s.unknown))}
 action capture=all{s.guard,not(s.sealed),s.phase==0,s'={...s,saved:s.generation,suspended:true,writer:false,guard:false,frames:1}}
 action resumeLive=all{s.suspended,s.saved==s.generation,not(s.sealed),s.phase==0,not(s.reclaimed),s'={...s,suspended:false,guard:true,writer:true}}
 action resumeDenied=all{(s.saved!=s.generation or not(s.suspended) or s.sealed),s'={...s,denied:s.denied+1}}
 action closeWriters=all{s.guard,not(s.suspended),s.nativePins==0,s'={...s,writer:false}}
 action opaqueEscape=all{s.writer,not(s.sealed),s'={...s,opaqueExport:true}}
 action seal=all{s.guard,not(s.writer),not(s.suspended),not(s.opaqueExport),s.nativePins==0,not(s.reclaimed),s'={...s,sealed:true,guard:false,generation:s.generation+1}}
 action abortCandidate=all{not(s.sealed),s.phase==0,s'={...s,writer:false,guard:false,suspended:false,generation:s.generation+1,phase:3,revocationWins:true}}
 action issue=all{s.sealed,s.phase==0,not(s.reclaimed),s.admit,s'={...s,phase:1}}
 action observe=all{s.phase==1,s.admit,s.observers==0,not(s.reclaimed),s'={...s,observers:1,ticket:s.generation}}
 action revoke=all{s.phase==1,s'={...s,phase:3,revocationWins:true}}
 action casStart=all{s.phase==1,s.observers==1,s.ticket==s.generation,not(s.reclaimed),not(s.revocationWins),s.sealed,s'={...s,phase:2,copyPin:true,observers:0}}
 action casFailed=all{s.phase==3,s.observers==1,s'={...s,observers:0,denied:s.denied+1}}
 action revokeTooLate=all{s.phase==2,s'={...s,denied:s.denied+1}}
 action finishCopy=all{s.phase==2,s'={...s,phase:4,copyPin:false}}
 action nativeBorrow=all{s.sealed,s.admit,not(s.reclaimed),s.nativePins==0,s'={...s,nativePins:1}}
 action nativeReturn=all{s.nativePins==1,not(s.unknown),s'={...s,nativePins:0}}
 action nativeUnknown=all{s.nativePins==1,s'={...s,unknown:true}}
 action closeAdmission=all{not(s.reclaimed),s'={...s,admit:false}}
 action dropFrame=all{s.frames==1,s'={...s,frames:0}}
 action dropRoot=all{s.roots==1,s'={...s,roots:0}}
 action beginMaintenance=all{s.admit,not(s.reclaimed),s.maintenance==0,s'={...s,maintenance:1}}
 action endMaintenance=all{s.maintenance==1,s'={...s,maintenance:0}}
 action reclaim=all{not(s.admit),not(s.guard),not(s.writer),not(s.suspended),s.phase!=1,s.phase!=2,not(s.copyPin),s.nativePins==0,s.frames==0,s.roots==0,s.maintenance==0,s.observers==0,not(s.unknown),s'={...s,reclaimed:true}}
 action denyLateBorrow=all{not(s.admit),s'={...s,denied:s.denied+1}}
 action step=any{capture,resumeLive,resumeDenied,closeWriters,opaqueEscape,seal,abortCandidate,issue,observe,revoke,casStart,casFailed,revokeTooLate,finishCopy,nativeBorrow,nativeReturn,nativeUnknown,closeAdmission,dropFrame,dropRoot,beginMaintenance,endMaintenance,reclaim,denyLateBorrow,all{s'=s}}
 run resumeBeforeSealTest=init.then(capture).then(resumeLive).then(closeWriters).then(seal).then(resumeDenied).then(resumeDenied).then(all{assert(safe and s.generation==2 and s.denied==2),s'=s})
 run revokeWinsTest=init.then(closeWriters).then(seal).then(issue).then(observe).then(revoke).then(casFailed).then(all{assert(safe and s.phase==3 and not(s.copyPin)),s'=s})
 run startWinsTest=init.then(closeWriters).then(seal).then(issue).then(observe).then(casStart).then(revokeTooLate).then(finishCopy).then(all{assert(safe and s.phase==4 and not(s.revocationWins)),s'=s})
 run observerDrainTest=init.then(closeWriters).then(seal).then(issue).then(observe).then(revoke).then(closeAdmission).then(dropFrame).then(dropRoot).then(casFailed).then(reclaim).then(all{assert(safe and s.reclaimed),s'=s})
 run nativeDrainTest=init.then(closeWriters).then(seal).then(nativeBorrow).then(closeAdmission).then(nativeReturn).then(dropFrame).then(dropRoot).then(reclaim).then(all{assert(safe and s.reclaimed),s'=s})
 run unknownRetainedTest=init.then(closeWriters).then(seal).then(nativeBorrow).then(nativeUnknown).then(closeAdmission).then(dropFrame).then(dropRoot).then(all{assert(safe and s.unknown and not(s.reclaimed)),s'=s})
 run maintenanceDrainTest=init.then(closeWriters).then(seal).then(issue).then(observe).then(casStart).then(beginMaintenance).then(closeAdmission).then(finishCopy).then(endMaintenance).then(dropFrame).then(dropRoot).then(reclaim).then(all{assert(safe and s.reclaimed),s'=s})
 run opaqueAbortTest=init.then(opaqueEscape).then(closeWriters).then(abortCandidate).then(closeAdmission).then(dropFrame).then(dropRoot).then(reclaim).then(all{assert(safe and s.reclaimed and not(s.sealed)),s'=s})
 run lateBorrowDeniedTest=init.then(closeWriters).then(seal).then(closeAdmission).then(dropFrame).then(dropRoot).then(reclaim).then(denyLateBorrow).then(all{assert(safe and s.reclaimed and s.denied==1),s'=s})
 run splitStartControlTest=init.then(closeWriters).then(seal).then(issue).then(observe).then(revoke).then(all{s'={...s,phase:2,copyPin:true}}).then(all{assert(not(safe)),s'=s})
 run staleResumeControlTest=init.then(capture).then(resumeLive).then(closeWriters).then(seal).then(all{s'={...s,guard:true,writer:true}}).then(all{assert(not(safe)),s'=s})
 run opaqueSealControlTest=init.then(opaqueEscape).then(closeWriters).then(all{s'={...s,sealed:true,guard:false}}).then(all{assert(not(safe)),s'=s})
 run frameRetireControlTest=init.then(closeWriters).then(seal).then(closeAdmission).then(dropRoot).then(all{s'={...s,reclaimed:true}}).then(all{assert(not(safe)),s'=s})
 run observerRetireControlTest=init.then(closeWriters).then(seal).then(issue).then(observe).then(revoke).then(closeAdmission).then(dropRoot).then(dropFrame).then(all{s'={...s,reclaimed:true}}).then(all{assert(not(safe)),s'=s})
 run unknownRetireControlTest=init.then(closeWriters).then(seal).then(nativeBorrow).then(nativeUnknown).then(closeAdmission).then(dropRoot).then(dropFrame).then(all{s'={...s,nativePins:0,reclaimed:true}}).then(all{assert(not(safe)),s'=s})
}
