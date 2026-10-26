module declaration_specialization_context {
 import declaration_context_parameters.* from "./declaration_context_parameters"
 pure def addr(w,p)=100+10*w+p
 type State={views:int->int,current:int,saved:int,scope:bool,bindings:int,hasNewBinding:bool,
  pinned:bool,viewStable:bool,caller:int,operView:int,appView:int,selectedView:int,
  w:int,helper:int,arityOK:bool,active:bool,done:bool,oldP:int,newP:int,steps:int,origin:int}
 pure val initial:State={views:Map(0->0,1->1,2->2),current:0,saved:0,scope:false,bindings:0,hasNewBinding:false,
  pinned:false,viewStable:true,caller:0,operView:0,appView:1,selectedView:-1,
  w:0,helper:addr(0,3),arityOK:true,active:false,done:false,oldP:0,newP:addr(0,0),steps:0,origin:0}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,w:1,helper:addr(1,3),newP:addr(1,0)}
 action enterScope=all {not(s.scope),not(s.active),s'={...s,saved:s.current,current:1,scope:true}}
 action addBinding=all {s.scope,s'={...s,bindings:1,hasNewBinding:true}}
 action restoreDecl=all {s.scope,s'={...s,current:s.saved,scope:false}}
 action pinView=all {not(s.active),s'={...s,pinned:true}}
 action releaseView=all {not(s.active),s'={...s,pinned:false}}
 action configureCaller(c)=all {not(s.active),not(s.done),s'={...s,caller:c}}
 action configureUnsafe=all {not(s.active),not(s.done),s'={...s,appView:2}}
 action rejectArity=all {not(s.active),s'={...s,arityOK:false}}
 def requestedView=if(s.caller==0) s.appView else s.operView
 action beginCall=all {not(s.active),not(s.done),s.pinned,s.viewStable,s.origin==0,s.arityOK,
  s'={...s,active:true,selectedView:requestedView}}
 pure def providerNext(p,m)=if(m==0) p else if(m==1) (if(p==0) 1 else p) else (if(p==0) 2 else if(p==2) 3 else p)
 def mode=s.views.get(s.selectedView)
 action walkStep=all {s.active,s.pinned,s.viewStable,s.origin==0,s.steps<5,
  s'={...s,oldP:providerNext(s.oldP,mode),newP:addr(s.w,providerNext(s.oldP,mode)),steps:s.steps+1}}
 action finish=all {s.active,providerNext(s.oldP,mode)==s.oldP,s.newP==addr(s.w,s.oldP),s.helper==addr(s.w,3),s.selectedView==requestedView,
  s'={...s,active:false,done:true}}
 def safe=s.viewStable and (not(s.scope) and s.hasNewBinding implies s.bindings==1) and
  (s.active implies s.pinned and s.selectedView==requestedView and s.newP==addr(s.w,s.oldP)) and
  (s.done implies providerNext(s.oldP,s.views.get(requestedView))==s.oldP and s.newP==addr(s.w,s.oldP) and s.helper==addr(s.w,3) and s.origin==0)
 action step={nondet c=0.to(1).oneOf();any {enterScope,addBinding,restoreDecl,pinView,releaseView,configureCaller(c),configureUnsafe,rejectArity,beginCall,walkStep,finish,s'=s}}
 action mutatePayload=s'={...s,views:s.views.set(0,1),viewStable:false}
 action restoreWholeEnv=s'={...s,current:s.saved,scope:false,bindings:0}
 action wrongView=s'={...s,selectedView:s.operView}
 action staleHelper=s'={...s,helper:3}
 action staleProc=s'={...s,newP:s.oldP}
 action forceFinish=s'={...s,active:false,done:true}
 action dropPin=s'={...s,pinned:false}
 action changeOrigin=s'={...s,origin:1}
 run persistentParentTest=init.then(enterScope).expect(safe and s.views.get(0)==0 and s.current==1)
 run scopeBindingTest=init.then(enterScope).then(addBinding).then(restoreDecl).expect(safe and s.current==0 and s.bindings==1)
 run appEnvironmentTest=init.then(pinView).then(beginCall).then(walkStep).then(finish).expect(safe and s.oldP==1)
 run operandEnvironmentTest=init.then(configureCaller(1)).then(pinView).then(beginCall).then(finish).expect(safe and s.oldP==0)
 run unsafeChainTest=init.then(configureUnsafe).then(pinView).then(beginCall).then(walkStep).then(walkStep).then(finish).expect(safe and s.oldP==3 and s.steps==2)
 run otherWorkspaceTest=initOther.then(configureUnsafe).then(pinView).then(beginCall).then(walkStep).then(walkStep).then(finish).expect(safe and s.newP==113)
 run arityBeforeLoopTest=init.then(rejectArity).then(pinView).expect(safe and not(s.arityOK) and not(s.active))
 run pinnedChainTest=init.then(pinView).then(beginCall).then(walkStep).expect(safe and s.pinned)
 run payloadAliasControlTest=init.then(mutatePayload).expect(not(safe))
 run wholeEnvRestoreControlTest=init.then(enterScope).then(addBinding).then(restoreWholeEnv).expect(not(safe))
 run wrongCallerViewControlTest=init.then(pinView).then(beginCall).then(wrongView).expect(not(safe))
 run staleHelperControlTest=init.then(configureUnsafe).then(pinView).then(beginCall).then(walkStep).then(walkStep).then(staleHelper).then(forceFinish).expect(not(safe))
 run stalePrimitiveControlTest=init.then(pinView).then(beginCall).then(walkStep).then(staleProc).expect(not(safe))
 run prematureStopControlTest=init.then(configureUnsafe).then(pinView).then(beginCall).then(walkStep).then(forceFinish).expect(not(safe))
 run droppedPinControlTest=init.then(pinView).then(beginCall).then(dropPin).expect(not(safe))
 run changedOriginControlTest=init.then(pinView).then(beginCall).then(walkStep).then(finish).then(changeOrigin).expect(not(safe))
}
