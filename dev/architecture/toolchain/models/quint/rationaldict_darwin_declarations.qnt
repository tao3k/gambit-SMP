// Classification/profile/type gates and shared image binding modes; finite histories.
module rationaldict_darwin_declarations {
 type State={operation:int,classified:bool,paste:bool,types:bool,profile:bool,inputs:bool,image:bool,access:bool,binding:int,allowed:Set[int],retired:bool,cold:bool,available:int,reused:int}
 var s:State
 action init=s'={operation:0,classified:false,paste:false,types:false,profile:false,inputs:false,image:false,access:false,binding:0,allowed:Set(0),retired:false,cold:true,available:10,reused:0}
 action classify=s'={...s,classified:true}
 action closePaste=s'={...s,paste:true}
 action closeTypes=s'={...s,types:true}
 action sealProfile=s'={...s,profile:true,inputs:true}
 action migrateImage=s'={...s,image:true}
 action migrateAccess=s'={...s,access:true}
 action selectDynamic=s'={...s,binding:1}
 action commonImage=s'={...s,allowed:Set(0,1)}
 val ready=s.classified and s.paste and s.types and s.profile and s.inputs and s.image and s.access and s.allowed.contains(s.binding)
 action retire=all{ready,s'={...s,retired:true}}
 action useIncremental=s'={...s,cold:false}
 action reuse=s'={...s,reused:if(s.cold) 0 else if(ready) s.available else 0}
 run candidate=init.then(classify).then(closePaste).then(closeTypes).then(migrateImage).then(migrateAccess)
 run classifiedNotQualifiedTest=init.then(classify).expect(not(ready))
 run unknownProfileRefusalTest=candidate.expect(not(ready))
 run earlyBindingTest=candidate.then(sealProfile).then(retire).expect(ready and s.retired)
 run lateBindingRefusalTest=candidate.then(sealProfile).then(selectDynamic).expect(not(ready))
 run objectLateBindingTest=candidate.then(sealProfile).then(commonImage).then(selectDynamic).then(retire).expect(s.operation==0 and s.binding==1 and ready)
 run commonImageBothModesTest=candidate.then(sealProfile).then(commonImage).then(selectDynamic).then(retire).expect(ready and s.retired)
 run coldReuseZeroTest=candidate.then(sealProfile).then(reuse).expect(ready and s.reused==0)
 run incrementalReuseTest=candidate.then(sealProfile).then(useIncremental).then(reuse).expect(ready and s.reused==10)
 run unqualifiedIncrementalRefusalTest=candidate.then(useIncremental).then(reuse).expect(not(ready) and s.reused==0)
}
