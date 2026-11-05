// Companion to the existing phase-query scheduler; no second scheduler.
module native_artifact_partition {
  val M=Set(0,1)
  type HeaderKey={abi:int,inlinePolicy:int}
  type ObjectKey={moduleId:int,header:HeaderKey,tool:int,source:int,descriptor:int}
  type State={abi:int,inlinePolicy:int,tool:int,source:int->int,count:int->int,
    stored:int->ObjectKey,pending:int->ObjectKey,active:Set[int],complete:Set[int],selected:Set[int],closed:bool}
  def header(x:State):HeaderKey={abi:x.abi,inlinePolicy:x.inlinePolicy}
  def key(x:State,m:int):ObjectKey={moduleId:m,header:header(x),tool:x.tool,source:x.source.get(m),descriptor:x.count.get(m)}
  val zeroHeader={abi:0,inlinePolicy:0}
  def zeroKey(m:int):ObjectKey={moduleId:m,header:zeroHeader,tool:0,source:0,descriptor:0}
  val initial:State={abi:0,inlinePolicy:0,tool:0,source:M.mapBy(_=>0),count:M.mapBy(_=>0),
    stored:M.mapBy(m=>zeroKey(m)),pending:M.mapBy(m=>zeroKey(m)),active:Set(),complete:M,selected:Set(),closed:true}
  var s:State
  action init=s'=initial
  def reusable(m:int):bool=s.closed and s.complete.contains(m) and s.stored.get(m)==key(s,m)
  action selectNative(m)=all{reusable(m),s'={...s,selected:s.selected.union(Set(m))}}
  action start(m)=all{not(s.active.contains(m)),s'={...s,pending:s.pending.set(m,key(s,m)),active:s.active.union(Set(m))}}
  action publish(m)=all{s.active.contains(m),s.closed,s.pending.get(m)==key(s,m),
    s'={...s,stored:s.stored.set(m,s.pending.get(m)),complete:s.complete.union(Set(m)),active:s.active.exclude(Set(m))}}
  action failAttempt(m)=all{s.active.contains(m),s'={...s,active:s.active.exclude(Set(m))}}
  action editCount(m)=all{s.count.get(m)==0,s'={...s,count:s.count.set(m,1),selected:Set()}}
  action editSource(m)=all{s.source.get(m)==0,s'={...s,source:s.source.set(m,1),selected:Set()}}
  action editAbi=all{s.abi==0,s'={...s,abi:1,selected:Set()}}
  action editTool=all{s.tool==0,s'={...s,tool:1,selected:Set()}}
  action editInline=all{s.inlinePolicy==0,s'={...s,inlinePolicy:1,selected:Set()}}
  action opaque=s'={...s,closed:false,selected:Set()}
  val safe=s.selected.forall(m=>reusable(m))
  action step={nondet m=M.oneOf();any{selectNative(m),start(m),publish(m),failAttempt(m),editCount(m),editSource(m),editAbi,editTool,editInline,opaque,s'=s}}
  action forceSelect(m)=s'={...s,selected:s.selected.union(Set(m))}
  action stalePublish(m)=s'={...s,stored:s.stored.set(m,s.pending.get(m)),selected:s.selected.union(Set(m))}
  run countDoesNotChangeAbiTest=init.then(editCount(0)).then(selectNative(1)).expect(safe and header(s)==zeroHeader and not(reusable(0)) and reusable(1))
  run sourceIsLocalTest=init.then(editSource(0)).then(selectNative(1)).expect(safe and not(reusable(0)) and reusable(1))
  run abiInvalidatesBothTest=init.then(editAbi).expect(safe and not(reusable(0)) and not(reusable(1)))
  run toolPreservesHeaderTest=init.then(editTool).expect(safe and header(s)==zeroHeader and not(reusable(0)) and not(reusable(1)))
  run inlineIsAbiInputTest=init.then(editInline).expect(safe and header(s)!=zeroHeader and not(reusable(0)))
  run freshPublishTest=init.then(editCount(0)).then(start(0)).then(publish(0)).then(selectNative(0)).expect(safe and reusable(0))
  run failedAttemptKeepsOldArtifactTest=init.then(editCount(0)).then(start(0)).then(failAttempt(0)).expect(safe and s.stored.get(0)==zeroKey(0) and not(reusable(0)))
  run changedSnapshotRejectsTest=init.then(start(0)).then(editCount(0)).then(stalePublish(0)).expect(not(safe))
  run opaqueRejectsTest=init.then(opaque).then(forceSelect(0)).expect(not(safe))
  action wrongModule=s'={...s,stored:s.stored.set(1,s.stored.get(0)),selected:Set(1)}
  run wrongModuleRejectsTest=init.then(wrongModule).expect(not(safe))
  run ignoredCountRejectsTest=init.then(editCount(0)).then(forceSelect(0)).expect(not(safe))
}
