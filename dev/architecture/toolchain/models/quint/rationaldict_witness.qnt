// Retained C row163, conditional regs5/align4/reserve3. Not native proof.
module rationaldict_witness {
 val moduleResources=Set(0,1,2,3,4,5,6)
 val reads=Set(1,4)
 val writes=Set(4)
 val roots=Set(2,3,4,5,6)
 // Logical frame cells are disjoint from register-resource identities.
 val cells=0.to(23)
 def place(slot:int):int=7+slot
 val rootCells=roots.map(place)
 type State={source:int->int,target:int->int,history:List[int],saved:int->int,targetSaved:int->int,captured:bool}
 val initial= cells.mapBy(i=>i+100)
 var s:State
 action init=s'={source:initial,target:initial,history:[],saved:initial,targetSaved:initial,captured:false}
 def move(rs:int->int,mask:Set[int]):int->int=cells.mapBy(i=>if(mask.contains(i)) rs.get(i)+1000 else rs.get(i))
 action setR2=s'={...s,source:s.source.set(4,0),target:s.target.set(4,0)}
 action poll=s'={...s,source:move(s.source,rootCells),target:move(s.target,rootCells),history:s.history.append(163),saved:if(s.captured) move(s.saved,rootCells) else s.saved,targetSaved:if(s.captured) move(s.targetSaved,rootCells) else s.targetSaved}
 action capture=s'={...s,saved:s.source,targetSaved:s.target,captured:true}
 action resume=all{s.captured,s'={...s,source:s.saved,target:s.targetSaved,history:s.history.append(162)}}
 action missingRoot=s'={...s,source:move(s.source,rootCells),target:move(s.target,rootCells.exclude(Set(place(6))))}
 action wrongCoordinate=s'={...s,source:move(s.source,rootCells),target:move(s.target,roots)}
 val related=s.source==s.target and (s.captured implies s.saved==s.targetSaved)
 run actualResourceCoverageTest=init.expect(writes.subseteq(reads) and reads!=moduleResources and not(writes.contains(1)))
 run actualRootSlotsTest=init.expect(roots==1.to(9).filter(slot=>((63/(2^(slot-1)))%2==1) and slot!=1))
 run namespaceTest=init.expect(rootCells.intersect(moduleResources)==Set())
 run assignPollTest=init.then(setR2).then(poll).expect(related and s.source.get(place(6))==1113 and s.source.get(4)==0)
 run linkExcludedTest=init.then(poll).expect(related and s.source.get(place(1))==108)
 run missingRootCounterexampleTest=init.then(missingRoot).expect(not(related))
 run wrongCoordinateCounterexampleTest=init.then(wrongCoordinate).expect(not(related))
 run multiShotTest=init.then(setR2).then(capture).then(resume).then(poll).then(resume).expect(related and s.history==[162,163,162])
 action staleCapturedRoot=all{s.captured,s'={...s,source:move(s.source,rootCells),target:move(s.target,rootCells),saved:move(s.saved,rootCells)}}
 run capturedRootUpdateTest=init.then(capture).then(poll).then(resume).expect(related and s.source.get(place(6))==1113)
 run staleCapturedRootCounterexampleTest=init.then(capture).then(staleCapturedRoot).then(resume).expect(not(related))
 run mixedGenerationRejectTest=init.expect(1792170496!=1789984941)
 run timingRefusalTest=init.expect(moduleResources.size()==7 and roots.size()==5)
}
