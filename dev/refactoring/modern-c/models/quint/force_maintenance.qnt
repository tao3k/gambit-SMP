module force_maintenance {
 type State={external:bool,maintenance:bool,cut:bool,roots:int,reserved:int,readers:int,unknown:bool,retired:bool}
 pure val initial:State={external:true,maintenance:true,cut:false,roots:1,reserved:0,readers:0,unknown:false,retired:false}
 var s:State
 action init=s'=initial
 val empty=s.roots==0 and s.reserved==0 and s.readers==0
 val safe=all{s.roots>=0,s.reserved>=0,s.readers>=0,
 s.cut implies (not(s.external) and s.roots==0),
 not(s.maintenance) implies s.cut,
 s.retired implies (not(s.external) and not(s.maintenance) and empty and not(s.unknown))}
 action closeExternal=all{s'={...s,external:false}}
 // Reservation is the linearized admission, before any descriptor dereference.
 action reserve=all{s.maintenance,not(s.retired),not(s.cut),s.roots>0,s.reserved<2,s'={...s,reserved:s.reserved+1}}
 action enter=all{s.reserved>0,s.readers<2,s'={...s,reserved:s.reserved-1,readers:s.readers+1}}
 // Derived work inherits a live parent grant, even after independent admission closes.
 action derive=all{s.readers>0,not(s.retired),not(s.unknown),s.reserved<2,s'={...s,reserved:s.reserved+1}}
 action abortReservation=all{s.reserved>0,s'={...s,reserved:s.reserved-1}}
 action lastRead=all{s.readers>0,s'={...s,readers:s.readers-1}}
 action loseOutcome=all{s.reserved+s.readers>0,s'={...s,unknown:true}}
 // Root cut includes all root producers, not merely currently visible frames.
 action rootCut=all{not(s.external),s'={...s,roots:0,cut:true}}
 action closeMaintenance=all{s.cut,s'={...s,maintenance:false}}
 action retire=all{not(s.external),not(s.maintenance),empty,not(s.unknown),s'={...s,retired:true}}
 action step=any{closeExternal,reserve,enter,derive,abortReservation,lastRead,loseOutcome,rootCut,closeMaintenance,retire,all{s'=s}}
 run scanAfterCloseTest=init.then(closeExternal).then(reserve).then(enter).then(lastRead).then(rootCut).then(closeMaintenance).then(retire).then(all{assert(safe and s.retired),s'=s})
 run admittedBeforeCutTest=init.then(reserve).then(closeExternal).then(rootCut).then(closeMaintenance).then(enter).then(all{assert(safe and s.readers==1 and not(s.retired)),s'=s}).then(lastRead).then(retire).then(all{assert(safe and s.retired),s'=s})
 run abortAfterCutTest=init.then(reserve).then(closeExternal).then(rootCut).then(closeMaintenance).then(abortReservation).then(retire).then(all{assert(safe and s.retired),s'=s})
 run unknownRetainedTest=init.then(reserve).then(loseOutcome).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{assert(safe and s.reserved==1 and s.unknown and not(s.retired)),s'=s})
 run twoReadersTest=init.then(reserve).then(reserve).then(enter).then(enter).then(closeExternal).then(rootCut).then(closeMaintenance).then(lastRead).then(all{assert(safe and s.readers==1),s'=s}).then(lastRead).then(retire).then(all{assert(safe),s'=s})
 run inheritedChildTest=init.then(reserve).then(enter).then(closeExternal).then(rootCut).then(closeMaintenance).then(derive).then(lastRead).then(enter).then(all{assert(safe and s.readers==1 and not(s.retired)),s'=s}).then(lastRead).then(retire).then(all{assert(safe and s.retired),s'=s})
 run prematureMaintenanceCloseControlTest=init.then(all{s'={...s,maintenance:false}}).then(all{assert(not(safe)),s'=s})
 run uncountedLateReaderControlTest=init.then(closeExternal).then(rootCut).then(closeMaintenance).then(retire).then(all{s'={...s,readers:1}}).then(all{assert(not(safe)),s'=s})
 run reservationIgnoredControlTest=init.then(reserve).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{s'={...s,retired:true}}).then(all{assert(not(safe)),s'=s})
 run unknownIgnoredControlTest=init.then(reserve).then(loseOutcome).then(abortReservation).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{s'={...s,retired:true}}).then(all{assert(not(safe)),s'=s})
}
