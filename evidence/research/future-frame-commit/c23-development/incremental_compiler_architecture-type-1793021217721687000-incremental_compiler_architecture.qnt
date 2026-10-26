module incremental_compiler_architecture {
  import incremental_compiler_parameters.* from "./incremental_compiler_parameters"
  pure val N = 0.to(NodeCount-1)
  type State = { epoch: int, macroInput: int, abi: int, code: int, a: int, b: int, native: int, x: int,
    status: int->int, out: int->int, cached: int->int, traces: int->int,
    read: int->int, born: int->int, runs: int->int, leases: Set[int], needed: Set[int], groups: Set[int],
    discovered: bool, cachedExtra: bool, reusable: Set[int] }
  pure val initial: State = { epoch: 0, macroInput: 0, abi: 0, code: 0, a: 0, b: 0, native: 0, x: 0,
    status: N.mapBy(_=>0), out: N.mapBy(_=>0), cached: N.mapBy(_=>0), traces: N.mapBy(n=>if(n==7) -1 else 0),
    read: N.mapBy(_=>-1), born: N.mapBy(_=>-1), runs: N.mapBy(_=>0), leases: Set(), needed: Set(6), groups: Set(),
    discovered: false, cachedExtra: false, reusable: N }
  var s: State
  action init = s'=initial
  action initOpaque = s'={...initial,reusable:N.exclude(Set(2))}
  def deps(n) = Parents.get(n).union(if(n==2 and (s.discovered or s.cachedExtra)) Set(7) else Set())
  def depsReady(n) = deps(n).forall(d=>s.status.get(d)==3)
  def stamp(n) = if(n==0) s.macroInput else if(n==1) 100*s.macroInput+s.out.get(0) else if(n==2) 10000*s.a+1000*s.out.get(0)+100*s.out.get(1)+(if(s.discovered or s.cachedExtra) 10+s.out.get(7) else 0) else if(n==3) 10000*s.b+1000*s.out.get(0)+100*s.out.get(1) else if(n==4) 10000*s.native+s.out.get(2) else if(n==5) 10000*s.native+s.out.get(3) else if(n==6) 100000*s.out.get(4)+s.out.get(5) else s.x
  def compute(n) = if(n==0) s.abi else if(n==1) s.code else if(n==2) 1000*s.out.get(0)+100*s.out.get(1)+10*s.a+(if(s.a==2) s.out.get(7) else 0) else if(n==3) 1000*s.out.get(0)+100*s.out.get(1)+10*s.b else if(n==4) 10000*s.native+s.out.get(2) else if(n==5) 10000*s.native+s.out.get(3) else if(n==6) 100000*s.out.get(4)+s.out.get(5) else s.x
  def clean(n) = if(n==0) s.abi else if(n==1) s.code else if(n==2) 1000*s.abi+100*s.code+10*s.a+(if(s.a==2) s.x else 0) else if(n==3) 1000*s.abi+100*s.code+10*s.b else if(n==4) 10000*s.native+1000*s.abi+100*s.code+10*s.a+(if(s.a==2) s.x else 0) else if(n==5) 10000*s.native+1000*s.abi+100*s.code+10*s.b else if(n==6) 100000*(10000*s.native+1000*s.abi+100*s.code+10*s.a+(if(s.a==2) s.x else 0))+(10000*s.native+1000*s.abi+100*s.code+10*s.b) else s.x
  action request(n) = all { s.needed.contains(n), s'={...s,needed:s.needed.union(deps(n))} }
  def canReuse(n) = s.needed.contains(n) and s.status.get(n)==0 and not(s.leases.contains(n)) and
    s.reusable.contains(n) and depsReady(n) and s.traces.get(n)==stamp(n)
  action validate(n) = all { canReuse(n), s'={...s,status:s.status.set(n,3),out:s.out.set(n,s.cached.get(n)),groups:s.groups.union(Set(n))} }
  def canStart(n) = s.needed.contains(n) and s.status.get(n)==0 and not(s.leases.contains(n)) and depsReady(n) and
    s.leases.size()<Capacity and s.runs.get(n)==0 and not(canReuse(n))
  action start(n) = all { canStart(n), s'={...s,status:s.status.set(n,1),leases:s.leases.union(Set(n)),
    read:s.read.set(n,stamp(n)),born:s.born.set(n,s.epoch),runs:s.runs.set(n,1)} }
  action discoverX = all { s.status.get(2)==1, s.a==2, not(s.discovered),
    s'={...s,discovered:true,status:s.status.set(2,2),needed:s.needed.union(Set(7)),leases:s.leases.exclude(Set(2))} }
  action resume = all { s.status.get(2)==2, s.status.get(7)==3, s.born.get(2)==s.epoch, s.leases.size()<Capacity,
    s'={...s,status:s.status.set(2,1),leases:s.leases.union(Set(2)),read:s.read.set(2,stamp(2))} }
  def canCommit(n) = s.status.get(n)==1 and s.leases.contains(n) and s.born.get(n)==s.epoch and depsReady(n) and
    s.read.get(n)==stamp(n) and (n!=2 or s.a!=2 or s.discovered)
  action commit(n) = all { canCommit(n), s'={...s,status:s.status.set(n,3),out:s.out.set(n,compute(n)),cached:s.cached.set(n,compute(n)),
    traces:s.traces.set(n,stamp(n)),groups:s.groups.union(Set(n)),leases:s.leases.exclude(Set(n)),
    cachedExtra:if(n==2) s.discovered else s.cachedExtra} }
  action failQuery(n) = all { s.status.get(n)==1, s'={...s,status:s.status.set(n,4),leases:s.leases.exclude(Set(n))} }
  action settleOld(n) = all { s.leases.contains(n),s.born.get(n)!=s.epoch,s'={...s,leases:s.leases.exclude(Set(n))} }
  action editLeafA = all { s.epoch<2,s'={...s,epoch:s.epoch+1,a:1,status:N.mapBy(_=>0),runs:N.mapBy(_=>0),groups:Set(),needed:Set(6),discovered:false} }
  action editDynamicA = all { s.epoch<2,s'={...s,epoch:s.epoch+1,a:2,status:N.mapBy(_=>0),runs:N.mapBy(_=>0),groups:Set(),needed:Set(6),discovered:false} }
  action editMacro = all { s.epoch<2,s'={...s,epoch:s.epoch+1,macroInput:s.macroInput+1,code:1,status:N.mapBy(_=>0),runs:N.mapBy(_=>0),groups:Set(),needed:Set(6),discovered:false} }
  action editMacroSameResult = all { s.epoch<2,s'={...s,epoch:s.epoch+1,macroInput:s.macroInput+1,status:N.mapBy(_=>0),runs:N.mapBy(_=>0),groups:Set(),needed:Set(6),discovered:false} }
  action editNative = all { s.epoch<2,s'={...s,epoch:s.epoch+1,native:1,status:N.mapBy(_=>0),runs:N.mapBy(_=>0),groups:Set(),needed:Set(6),discovered:false} }
  action editX = all { s.epoch<2,s'={...s,epoch:s.epoch+1,x:1,status:N.mapBy(_=>0),runs:N.mapBy(_=>0),groups:Set(),needed:Set(6),discovered:false} }
  action editInterface = all { s.epoch<2,s'={...s,epoch:s.epoch+1,macroInput:s.macroInput+1,abi:1,status:N.mapBy(_=>0),runs:N.mapBy(_=>0),groups:Set(),needed:Set(6),discovered:false} }
  def safe = s.leases.size()<=Capacity and N.forall(n=>s.runs.get(n)<=1 and
    (s.status.get(n)==3 implies s.out.get(n)==clean(n) and s.groups.contains(n)))
  action step = {
    nondet n = N.oneOf()
    any {request(n),validate(n),start(n),commit(n),failQuery(n),settleOld(n),
      discoverX,resume,editLeafA,editDynamicA,editMacro,editMacroSameResult,editNative,editInterface,editX,s'=s}
  }
  action forceCached(n) = s'={...s,status:s.status.set(n,3),out:s.out.set(n,s.cached.get(n)),groups:s.groups.union(Set(n))}
  action duplicateProducer(n) = s'={...s,runs:s.runs.set(n,2)}
  action partialPublish(n) = s'={...s,status:s.status.set(n,3),out:s.out.set(n,clean(n))}
  action overBudget = s'={...s,leases:Set(0,1,2)}
  run noChangeTest = init.then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(validate(2)).then(validate(3)).then(validate(4)).then(validate(5)).then(validate(6)).expect(safe and N.forall(n=>s.runs.get(n)==0))
  run leafReuseOtherTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(commit(2)).then(validate(3)).then(start(4)).then(commit(4)).then(validate(5)).then(start(6)).then(commit(6)).expect(safe and s.runs.get(3)==0 and s.runs.get(5)==0)
  run sameMacroCutoffTest = init.then(editMacroSameResult).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(start(0)).then(commit(0)).then(start(1)).then(commit(1)).then(validate(2)).then(validate(3)).then(validate(4)).then(validate(5)).then(validate(6)).expect(safe and s.runs.get(2)==0)
  run macroChangesSupportTest = init.then(editMacro).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(start(0)).then(commit(0)).then(start(1)).then(commit(1)).expect(safe and not(canReuse(2)) and not(canReuse(3)))
  run parallelConsumersTest = init.then(editMacro).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(start(0)).then(commit(0)).then(start(1)).then(commit(1)).then(start(2)).then(start(3)).expect(safe and s.leases.size()==2)
  run phasePipelineTest = init.then(editMacro).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(start(0)).then(commit(0)).then(start(1)).then(commit(1)).then(start(2)).then(start(3)).then(commit(3)).then(start(5)).expect(safe and s.leases.contains(2) and s.leases.contains(5))
  run singleFlightTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(request(2)).expect(safe and not(canStart(2)))
  run dynamicSuspendsTest = init.then(editDynamicA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(discoverX).expect(safe and s.status.get(2)==2 and not(s.leases.contains(2)))
  run dynamicCompletesTest = init.then(editDynamicA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(discoverX).then(start(7)).then(commit(7)).then(resume).then(commit(2)).expect(safe and s.out.get(2)==20)
  run snapshotRejectsTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(editX).expect(safe and not(canCommit(2)))
  run oldLeaseSettlesTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(editX).then(settleOld(2)).expect(safe and not(s.leases.contains(2)))
  run failureNotCompleteTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(failQuery(2)).expect(safe and s.status.get(2)==4)
  run opaqueRunsTest = initOpaque.then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(commit(2)).expect(safe and s.runs.get(2)==1)
  run nativeLeavesExpansionTest = init.then(editNative).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(validate(2)).then(validate(3)).expect(safe and s.runs.get(2)==0 and not(canReuse(4)))
  run macroInterfaceOnlyControlTest = init.then(editMacro).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(start(0)).then(commit(0)).then(start(1)).then(commit(1)).then(forceCached(2)).expect(not(safe))
  run leafStaleControlTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(forceCached(2)).expect(not(safe))
  run duplicateControlTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(duplicateProducer(2)).expect(not(safe))
  run partialGroupControlTest = init.then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(partialPublish(2)).expect(not(safe))
  run budgetControlTest = init.then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(overBudget).expect(not(safe))
  run dynamicMissingReadControlTest = init.then(editDynamicA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(forceCached(2)).expect(not(safe))
  run changedHiddenReadControlTest = init.then(editDynamicA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(discoverX).then(start(7)).then(commit(7)).then(resume).then(commit(2)).then(editX).then(forceCached(2)).expect(not(safe))
  run staleEpochPublishControlTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(editX).then(forceCached(2)).expect(not(safe))
  run failedPublishedControlTest = init.then(editLeafA).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(start(2)).then(failQuery(2)).then(forceCached(2)).expect(not(safe))
  run nativeStaleControlTest = init.then(editNative).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(validate(0)).then(validate(1)).then(validate(2)).then(forceCached(4)).expect(not(safe))
  run interfaceChangeTest = init.then(editInterface).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(start(0)).then(commit(0)).then(start(1)).then(commit(1)).expect(safe and not(canReuse(2)) and not(canReuse(3)))
  run interfaceIgnoredControlTest = init.then(editInterface).then(request(6)).then(request(4)).then(request(5)).then(request(2)).then(request(3)).then(request(1)).then(start(0)).then(commit(0)).then(start(1)).then(commit(1)).then(forceCached(2)).expect(not(safe))
}
