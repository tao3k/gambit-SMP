module darwin_force_binding {
 type State={external:bool,maintenance:bool,cut:bool,parent:bool,child:int,initialized:bool,unknown:bool,freed:bool}
 pure val initial:State={external:true,maintenance:true,cut:false,parent:true,child:0,initialized:false,unknown:false,freed:false}
 var s:State
 action init=s'=initial
 val empty=not(s.parent) and s.child==0
 val safe=all{s.child>=0,s.child<=3,not(s.maintenance) implies s.cut,
 s.child>=2 implies s.initialized,
 s.freed implies (not(s.external) and not(s.maintenance) and empty and not(s.unknown))}
 action closeExternal=all{s'={...s,external:false}}
 action rootCut=all{not(s.external),s'={...s,cut:true}}
 action closeMaintenance=all{s.cut,s'={...s,maintenance:false}}
 // child phase: 0 absent, 1 private reservation, 2 release-published, 3 acquired reader.
 action childReserve=all{s.parent,s.child==0,not(s.unknown),not(s.freed),s'={...s,child:1,initialized:false}}
 action initialize=all{s.child==1,s'={...s,initialized:true}}
 action publish=all{s.child==1,s.initialized,s'={...s,child:2}}
 action claim=all{s.child==2,s.initialized,s'={...s,child:3}}
 action parentLastUse=all{s.parent,s'={...s,parent:false}}
 action abortPrivate=all{s.child==1,not(s.unknown),s'={...s,child:0,initialized:false}}
 action childLastUse=all{s.child==3,not(s.unknown),s'={...s,child:0,initialized:false}}
 action lose=all{s.child>0,s'={...s,unknown:true}}
 action retire=all{not(s.external),not(s.maintenance),empty,not(s.unknown),s'={...s,freed:true}}
 action step=any{closeExternal,rootCut,closeMaintenance,childReserve,initialize,publish,claim,parentLastUse,abortPrivate,childLastUse,lose,retire,all{s'=s}}
 run afterCloseChildTest=init.then(closeExternal).then(rootCut).then(closeMaintenance).then(childReserve).then(initialize).then(publish).then(parentLastUse).then(claim).then(childLastUse).then(retire).then(all{assert(safe and s.freed),s'=s})
 run privateOutlivesParentTest=init.then(childReserve).then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{assert(safe and s.child==1 and not(s.freed)),s'=s})
 run abortKnownTest=init.then(childReserve).then(abortPrivate).then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(retire).then(all{assert(safe and s.freed),s'=s})
 run queuedAfterCloseTest=init.then(childReserve).then(initialize).then(publish).then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{assert(safe and s.child==2 and not(s.freed)),s'=s}).then(claim).then(childLastUse).then(retire).then(all{assert(safe and s.freed),s'=s})
 run unknownCustodyTest=init.then(childReserve).then(initialize).then(publish).then(lose).then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{assert(safe and s.unknown and s.child==2),s'=s})
 run noChildTest=init.then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(retire).then(all{assert(safe and s.freed),s'=s})
 run zeroGapControlTest=init.then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(retire).then(all{s'={...s,child:1}}).then(all{assert(not(safe)),s'=s})
 run uninitializedQueueControlTest=init.then(childReserve).then(all{s'={...s,child:2}}).then(all{assert(not(safe)),s'=s})
 run queuedRetirementControlTest=init.then(childReserve).then(initialize).then(publish).then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{s'={...s,freed:true}}).then(all{assert(not(safe)),s'=s})
 run unknownForgottenControlTest=init.then(childReserve).then(lose).then(parentLastUse).then(closeExternal).then(rootCut).then(closeMaintenance).then(all{s'={...s,child:0,freed:true}}).then(all{assert(not(safe)),s'=s})
}
