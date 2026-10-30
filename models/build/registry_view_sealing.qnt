module registry_view_sealing {
 import registry_sealing_parameters.* from "./registry_sealing_parameters"
 // primitive ids: +=0, ##+=1, fx+=2, ##fx+=3, fl+=4, ##fl+=5.
 type Decl={mode:int,names:Set[int]}
 pure def arithmetic(ds:List[Decl], p:int):int={
  val found=ds.foldl(-1,(acc,d)=>if(acc>=0) acc else if(d.names==Set() or d.names.contains(p)) d.mode else -1)
  if(found<0) 0 else found
 }
 pure def provider(p:int,ds:List[Decl],safeMode:bool):int=
  if(p==0 and not(safeMode)) 1
  else if(p==0 or p==1) (if(arithmetic(ds,p)==1) (if(p==0) 2 else 3) else if(arithmetic(ds,p)==2) (if(p==0) 4 else 5) else p)
  else if(p==2 and not(safeMode)) 3 else if(p==4 and not(safeMode)) 5 else p
 pure def addr(w,p)=100+10*w+p
 type State={registry:int,sealedRegistry:int,admit:bool,retired:bool,sealed:bool,stable:bool,tainted:bool,
  aliases:bool,roots:bool,lease:bool,active:bool,done:bool,published:bool,arity:bool,
  ds:List[Decl],safeMode:bool,p:int,oldp:int,np:int,workspace:int,steps:int}
 pure val initial:State={registry:0,sealedRegistry:-1,admit:true,retired:false,sealed:false,stable:true,tainted:false,
  aliases:false,roots:false,lease:false,active:false,done:false,published:false,arity:true,
  ds:List({mode:1,names:Set()}),safeMode:false,p:0,oldp:0,np:addr(0,0),workspace:0,steps:0}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,workspace:WorkspaceCount-1,np:addr(WorkspaceCount-1,0)}
 action chooseNamed=all {not(s.sealed),s'={...s,ds:List({mode:1,names:Set(0)})}}
 action chooseBoth=all {not(s.sealed),s'={...s,ds:List({mode:1,names:Set(0,1)})}}
 action chooseOverride=all {not(s.sealed),s'={...s,ds:List({mode:0,names:Set(1)},{mode:1,names:Set()})}}
 action chooseSafe=all {not(s.sealed),s'={...s,safeMode:true}}
 action rejectArity=all {not(s.sealed),s'={...s,arity:false}}
 action borrowAlias=all {not(s.sealed),s'={...s,aliases:true}}
 action copyPayload=all {not(s.sealed),s'={...s,aliases:false}}
 action seal=all {s.admit,not(s.sealed),not(s.aliases),s.stable,s'={...s,sealed:true,sealedRegistry:s.registry,roots:true}}
 action beginAttempt=all {s.sealed,s.admit,not(s.retired),not(s.active),not(s.done),not(s.lease),s.stable,not(s.tainted),s.arity,s'={...s,active:true,lease:true}}
 action advance=all {s.active,s.lease,s.stable,not(s.tainted),s.steps<6,
  s'={...s,oldp:provider(s.oldp,s.ds,s.safeMode),p:provider(s.p,s.ds,s.safeMode),np:addr(s.workspace,provider(s.p,s.ds,s.safeMode)),steps:s.steps+1}}
 action completeAttempt=all {s.active,s.stable,not(s.tainted),provider(s.p,s.ds,s.safeMode)==s.p,s'={...s,active:false,done:true}}
 action publishResult=all {s.done,s.lease,s.stable,not(s.tainted),s'={...s,published:true}}
 action retire=all {not(s.retired),s'={...s,admit:false,retired:true,registry:s.registry+1}}
 action taint=all {not(s.tainted),not(s.published),s'={...s,tainted:true,admit:false,retired:true}}
 action abortAttempt=all {s.active,s'={...s,active:false}}
 action drain=all {s.lease,not(s.active),s'={...s,lease:false}}
 action releaseRoots=all {s.retired,not(s.lease),not(s.active),s'={...s,roots:false}}
 def safe=(s.sealed implies not(s.aliases) and s.stable) and
  (s.lease implies s.roots and s.sealed and s.sealedRegistry==0) and
  (s.active implies s.lease and s.p==s.oldp and s.np==addr(s.workspace,s.oldp)) and
  (s.retired implies not(s.admit)) and
  (s.published implies not(s.tainted) and s.done and provider(s.p,s.ds,s.safeMode)==s.p)
 action step=any {chooseNamed,chooseBoth,chooseOverride,chooseSafe,rejectArity,borrowAlias,copyPayload,seal,beginAttempt,advance,completeAttempt,publishResult,retire,taint,abortAttempt,drain,releaseRoots,s'=s}
 action forceSeal=s'={...s,sealed:true,roots:true,sealedRegistry:s.registry}
 action reopen=s'={...s,admit:true}
 action loseRoot=s'={...s,roots:false}
 action forcePublish=s'={...s,published:true,done:true}
 action wrongNameStep=s'={...s,p:3,np:addr(s.workspace,3)}
 action rawPayloadWrite=s'={...s,stable:false,ds:List({mode:2,names:Set()})}
 action stalePrimitive=s'={...s,np:s.p}
 action falseRegistry=s'={...s,sealedRegistry:s.registry}
 run universalChainTest=init.then(seal).then(beginAttempt).then(advance).then(advance).then(completeAttempt).then(publishResult).expect(safe and s.p==3)
 run namedStopsAtGenericTest=init.then(chooseNamed).then(seal).then(beginAttempt).then(advance).then(completeAttempt).expect(safe and s.p==1)
 run bothNamesChainTest=init.then(chooseBoth).then(seal).then(beginAttempt).then(advance).then(advance).then(completeAttempt).expect(safe and s.p==3)
 run orderedOverrideTest=init.then(chooseOverride).then(seal).then(beginAttempt).then(advance).then(completeAttempt).expect(safe and s.p==1)
 run safeNamedTest=init.then(chooseNamed).then(chooseSafe).then(seal).then(beginAttempt).then(advance).then(completeAttempt).expect(safe and s.p==2)
 run otherWorkspaceTest=initOther.then(seal).then(beginAttempt).then(advance).then(advance).then(completeAttempt).expect(safe and s.np==113)
 run borrowedCopyTest=init.then(borrowAlias).then(copyPayload).then(seal).expect(safe and not(s.aliases))
 run retirementDrainTest=init.then(seal).then(beginAttempt).then(retire).then(advance).then(advance).then(completeAttempt).then(publishResult).then(drain).then(releaseRoots).expect(safe and not(s.roots))
 run taintAbortTest=init.then(seal).then(beginAttempt).then(taint).then(abortAttempt).then(drain).then(releaseRoots).expect(safe and not(s.published))
 run arityRejectedTest=init.then(rejectArity).then(seal).expect(safe and not(s.arity) and not(s.active))
 run writableAliasControlTest=init.then(borrowAlias).then(forceSeal).expect(not(safe))
 run retiredAdmissionControlTest=init.then(seal).then(retire).then(reopen).expect(not(safe))
 run earlyRootsControlTest=init.then(seal).then(beginAttempt).then(loseRoot).expect(not(safe))
 run taintedPublicationControlTest=init.then(seal).then(beginAttempt).then(taint).then(forcePublish).expect(not(safe))
 run namedOverreachControlTest=init.then(chooseNamed).then(seal).then(beginAttempt).then(advance).then(wrongNameStep).expect(not(safe))
 run rawAliasMutationControlTest=init.then(seal).then(rawPayloadWrite).expect(not(safe))
 run foreignIdentityControlTest=init.then(seal).then(beginAttempt).then(advance).then(stalePrimitive).expect(not(safe))
 run registrySubstitutionControlTest=init.then(seal).then(beginAttempt).then(retire).then(falseRegistry).expect(not(safe))
}
