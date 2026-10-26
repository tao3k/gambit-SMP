module alias_workspace_reconstruction {
 import alias_workspace_parameters.* from "./alias_workspace_parameters"
 pure val W=0.to(WorkspaceCount-1)
 pure def addr(w,n)=100+10*w+n
 type Observation={decl:List[int],identity:int,origin:int}
 pure val observation:Observation={decl:List(1,2),identity:0,origin:0}
 type State={shells:Set[int],wired:Set[int],bound:Set[int],validated:Set[int],published:Set[int],
   selfRef:int->int,altRef:int->int,targetRef:int->int,tagRef:int->int,graphRef:int->int,
   recipeKnown:bool,known:int->bool,failed:Set[int],live:Set[int],snapshotIntact:bool,
   frozen:Observation,now:Observation}
 pure val initial:State={shells:Set(),wired:Set(),bound:Set(),validated:Set(),published:Set(),
   selfRef:W.mapBy(_=>-1),altRef:W.mapBy(_=>-1),targetRef:W.mapBy(_=>-1),tagRef:W.mapBy(_=>-1),graphRef:W.mapBy(_=>-1),
   recipeKnown:true,known:W.mapBy(_=>true),failed:Set(),live:Set(),snapshotIntact:true,frozen:observation,now:observation}
 var s:State
 action init=s'=initial
 action initUnknownRecipe=s'={...initial,recipeKnown:false}
 action allocateShells(w)=all {not(s.shells.contains(w)),s'={...s,shells:s.shells.union(Set(w)),live:s.live.union(Set(w))}}
 action wireGraph(w)=all {s.live.contains(w),s.shells.contains(w),not(s.failed.contains(w)),
   s'={...s,wired:s.wired.union(Set(w)),graphRef:s.graphRef.set(w,addr(w,1)),tagRef:s.tagRef.set(w,7)}}
 action bindProviders(w)=all {s.live.contains(w),s.wired.contains(w),s.recipeKnown,not(s.failed.contains(w)),
   s'={...s,bound:s.bound.union(Set(w)),selfRef:s.selfRef.set(w,addr(w,1)),altRef:s.altRef.set(w,addr(w,2)),targetRef:s.targetRef.set(w,addr(w,0))}}
 def coherent(w)=s.selfRef.get(w)==addr(w,1) and s.altRef.get(w)==addr(w,2) and s.targetRef.get(w)==addr(w,0) and
   s.graphRef.get(w)==s.selfRef.get(w) and s.tagRef.get(w)==7
 def canValidate(w)=s.live.contains(w) and s.wired.contains(w) and s.bound.contains(w) and coherent(w) and
   s.recipeKnown and s.known.get(w) and not(s.failed.contains(w)) and s.snapshotIntact and s.frozen==s.now
 action validateWorkspace(w)=all {canValidate(w),s'={...s,validated:s.validated.union(Set(w))}}
 def canPublish(w)=s.validated.contains(w) and canValidate(w)
 action publishWorkspace(w)=all {canPublish(w),s'={...s,published:s.published.union(Set(w))}}
 action unknownOutcome(w)=all {s.live.contains(w),not(s.published.contains(w)),s'={...s,known:s.known.set(w,false),failed:s.failed.union(Set(w))}}
 action settleOutcome(w)=all {s.live.contains(w),s.failed.contains(w),not(s.known.get(w)),s'={...s,known:s.known.set(w,true)}}
 action releaseArena(w)=all {s.live.contains(w),s.failed.contains(w),s.known.get(w),s'={...s,live:s.live.exclude(Set(w))}}
 action changeOrigin=all {s.published.size()==0,s'={...s,now:{...s.now,origin:1}}}
 action changeIdentity=all {s.published.size()==0,s'={...s,now:{...s.now,identity:1}}}
 def safe=s.snapshotIntact and W.forall(w=>(s.published.contains(w) implies canPublish(w)) and
   (s.failed.contains(w) and not(s.known.get(w)) implies s.live.contains(w)))
 action step={nondet w=W.oneOf();any {allocateShells(w),wireGraph(w),bindProviders(w),validateWorkspace(w),publishWorkspace(w),unknownOutcome(w),settleOutcome(w),releaseArena(w),changeOrigin,changeIdentity,s'=s}}
 action shallowTarget(w)=s'={...s,targetRef:s.targetRef.set(w,0)}
 action shallowSelf(w)=s'={...s,selfRef:s.selfRef.set(w,1)}
 action copyTag(w)=s'={...s,tagRef:s.tagRef.set(w,addr(w,7))}
 action collapseIdentity(w)=s'={...s,altRef:s.altRef.set(w,addr(w,1))}
 action forcePublish(w)=s'={...s,published:s.published.union(Set(w))}
 action forceRelease(w)=s'={...s,live:s.live.exclude(Set(w))}
 run reconstructionTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(validateWorkspace(0)).then(publishWorkspace(0)).expect(safe and coherent(0))
 run twoPrivateTest=init.then(allocateShells(0)).then(allocateShells(1)).then(wireGraph(0)).then(wireGraph(1)).then(bindProviders(0)).then(bindProviders(1)).then(validateWorkspace(0)).then(validateWorkspace(1)).then(publishWorkspace(0)).then(publishWorkspace(1)).expect(safe and s.selfRef.get(0)!=s.selfRef.get(1))
 run sharingPreservedTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).expect(safe and s.graphRef.get(0)==s.selfRef.get(0))
 run unknownRecipeDeniedTest=initUnknownRecipe.then(allocateShells(0)).then(wireGraph(0)).expect(safe and not(canValidate(0)))
 run partialUnknownRetainsTest=init.then(allocateShells(0)).then(unknownOutcome(0)).expect(safe and s.live.contains(0))
 run failureDrainTest=init.then(allocateShells(0)).then(wireGraph(0)).then(unknownOutcome(0)).then(settleOutcome(0)).then(releaseArena(0)).expect(safe and not(s.live.contains(0)))
 run originRejectsTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(changeOrigin).expect(safe and not(canValidate(0)))
 run identityRejectsTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(changeIdentity).expect(safe and not(canValidate(0)))
 run canonicalTagTest=init.then(allocateShells(0)).then(allocateShells(1)).then(wireGraph(0)).then(wireGraph(1)).expect(safe and s.tagRef.get(0)==7 and s.tagRef.get(1)==7)
 run lateFailureBeforePublishTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(validateWorkspace(0)).then(unknownOutcome(0)).expect(safe and not(canPublish(0)))
 run shallowTargetControlTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(shallowTarget(0)).then(forcePublish(0)).expect(not(safe))
 run shallowSelfControlTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(shallowSelf(0)).then(forcePublish(0)).expect(not(safe))
 run copiedTagControlTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(copyTag(0)).then(forcePublish(0)).expect(not(safe))
 run collapsedIdentityControlTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(collapseIdentity(0)).then(forcePublish(0)).expect(not(safe))
 run ignoredOriginControlTest=init.then(allocateShells(0)).then(wireGraph(0)).then(bindProviders(0)).then(validateWorkspace(0)).then(changeOrigin).then(forcePublish(0)).expect(not(safe))
 run unknownReleaseControlTest=init.then(allocateShells(0)).then(unknownOutcome(0)).then(forceRelease(0)).expect(not(safe))
}
