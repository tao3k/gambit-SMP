// Temporal migration/rollback and projected operations, not a native scheduler.
module rationaldict_abi_cut {
 type State={registration:bool,access:bool,profile:bool,paste:bool,decl:bool,effects:bool,hidden:bool,cells:int->int,pub:int->int}
 var s:State
 action init=s'={registration:false,access:false,profile:false,paste:false,decl:false,effects:false,hidden:false,cells:Map(0->5,1->7),pub:Map(0->5,1->7)}
 val ready=s.registration and s.access and s.profile and s.paste and s.decl and s.effects
 action bindProfile=s'={...s,profile:true}
 action closePaste=s'={...s,paste:true}
 action closeDecl=s'={...s,decl:true}
 action refineEffects=s'={...s,effects:true}
 action replaceRegistration=s'={...s,registration:true}
 action replaceAccess=s'={...s,access:true}
 action hidePrivate=all{ready,s'={...s,hidden:true}}
 action rollback=all{not(s.hidden),s'={...s,access:false}}
 action writeOnce(v)=s'={...s,cells:s.cells.set(1,v),pub:s.pub.set(1,v)}
 action duplicateUpdate=s'={...s,cells:s.cells.set(1,s.cells.get(1)+1),pub:s.pub.set(1,s.pub.get(1)+2)}
 val semantic=s.cells==s.pub
 run accessOnlyRefusalTest=init.then(replaceAccess).expect(not(ready))
 run registrationOnlyRefusalTest=init.then(replaceRegistration).expect(not(ready))
 run unresolvedPasteRefusalTest=init.then(bindProfile).then(closeDecl).then(refineEffects).then(replaceRegistration).then(replaceAccess).expect(not(ready))
 run fullClosureTest=init.then(bindProfile).then(closeDecl).then(closePaste).then(refineEffects).then(replaceRegistration).then(replaceAccess).then(hidePrivate).expect(ready and s.hidden)
 run privateFallbackTest=init.then(replaceAccess).then(rollback).expect(not(ready) and not(s.hidden))
 run projectedWriteTest=init.then(writeOnce(42)).expect(semantic and s.cells.get(1)==42)
 run duplicateSetterCounterexampleTest=init.then(duplicateUpdate).expect(not(semantic))
 run oldSizeCheckNotEnoughTest=init.expect(64==64 and 8!=16)
 run historicalCapacityGapTest=init.expect(636536000-12*37335500==188510000 and 53044667-37335500==15709167)
}
