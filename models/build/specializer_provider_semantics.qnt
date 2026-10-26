module specializer_provider_semantics {
 import specializer_provider_parameters.* from "./specializer_provider_parameters"
 pure def rho(w,x)=if(x<0) x else 100+10*w+x
 type State={kind:int,checked:bool,mode:int,w:int,fix:int,flo:int,unsafe:int,spec:int,
  bound:bool,p:int,f:int,l:int,u:int,b:int,name:int,origin:int,known:bool,live:bool,
  returned:bool,result:int,trace:List[int],captureComplete:bool}
 pure val initial:State={kind:0,checked:true,mode:0,w:0,fix:1,flo:2,unsafe:3,spec:4,
  bound:false,p:-9,f:-9,l:-9,u:-9,b:-9,name:1,origin:0,known:true,live:true,
  returned:false,result:-9,trace:List(),captureComplete:true}
 var s:State
 action init=s'=initial
 action initMissing=s'={...initial,kind:2,mode:1,fix:-1,captureComplete:false}
 action configure(k,c,m)=all {not(s.bound),s'={...s,kind:k,checked:c,mode:m}}
 action chooseWorkspace(w)=all {not(s.bound),s'={...s,w:w}}
 action configureNoUnsafe=all {not(s.bound),s'={...s,unsafe:0}}
 action configureAbsentFix=all {not(s.bound),s'={...s,fix:0}}
 action configureMissing=all {not(s.bound),s'={...s,fix:-1,captureComplete:false}}
 action instantiate=all {not(s.bound),s.known,s.live,s'={...s,bound:true,p:rho(s.w,0),f:rho(s.w,s.fix),l:rho(s.w,s.flo),u:rho(s.w,s.unsafe),b:rho(s.w,s.spec)}}
 def oldChoice=if(s.kind==0) s.spec else if(s.kind==1) (if(s.checked) 0 else s.spec) else
  (if(not(s.checked) and s.unsafe!=0) s.unsafe else if(s.mode==1) s.fix else if(s.mode==2) s.flo else 0)
 def actualMode=if(s.name==1) s.mode else 2
 def newChoice=if(s.kind==0) s.b else if(s.kind==1) (if(s.checked) s.p else s.b) else
  (if(not(s.checked) and s.u!=s.p) s.u else if(actualMode==1) s.f else if(actualMode==2) s.l else s.p)
 def expectedTrace=if(s.kind==0) List() else if(s.kind==1) List(2) else List(11,2)
 def newTrace=if(s.kind==0) List() else if(s.kind==1) List(2) else List(10+s.name,2)
 def coherent=s.p==rho(s.w,0) and s.f==rho(s.w,s.fix) and s.l==rho(s.w,s.flo) and s.u==rho(s.w,s.unsafe) and s.b==rho(s.w,s.spec)
 def canInvoke=s.bound and s.live and s.known and coherent and s.name==1 and s.origin==0
 action invoke=all {canInvoke,s'={...s,returned:true,result:newChoice,trace:newTrace}}
 action changeOrigin=all {not(s.returned),s'={...s,origin:1}}
 action unknownOutcome=all {s.live,not(s.returned),s'={...s,known:false}}
 action settleOutcome=all {not(s.known),s.live,s'={...s,known:true}}
 action releaseContext=all {s.known,s.live,not(s.returned),s'={...s,live:false}}
 def admitted=s.returned and s.captureComplete and canInvoke
 def safe=s.returned implies coherent and s.origin==0 and s.name==1 and s.known and s.result==rho(s.w,oldChoice) and s.trace==expectedTrace
 action step={
  nondet k=0.to(2).oneOf()
  nondet c=Set(true,false).oneOf()
  nondet m=0.to(2).oneOf()
  nondet w=0.to(WorkspaceCount-1).oneOf()
  any {configure(k,c,m),chooseWorkspace(w),configureNoUnsafe,configureAbsentFix,configureMissing,instantiate,invoke,changeOrigin,unknownOutcome,settleOutcome,releaseContext,s'=s}
 }
 action staleSelf=s'={...s,p:0}
 action foreignSpec=s'={...s,b:rho(1,s.spec)}
 action forceInvoke=s'={...s,returned:true,result:newChoice,trace:newTrace}
 action preferFix=s'={...s,result:s.f}
 action inventedUnsafe=s'={...s,u:rho(s.w,3)}
 action absentInsteadMissing=s'={...s,f:s.p}
 action skipRead=s'={...s,trace:List(2)}
 action globalName=s'={...s,name:2}
 run safeSelectedTest=init.then(configure(0,false,1)).then(instantiate).then(invoke).expect(safe and s.result==104)
 run unsafeCheckedTest=init.then(configure(1,true,0)).then(instantiate).then(invoke).expect(safe and s.result==100)
 run unsafeUncheckedTest=init.then(configure(1,false,0)).then(instantiate).then(invoke).expect(safe and s.result==104)
 run arithUnsafePriorityTest=init.then(configure(2,false,1)).then(instantiate).then(invoke).expect(safe and s.result==103)
 run arithFixTest=init.then(configure(2,true,1)).then(instantiate).then(invoke).expect(safe and s.result==101)
 run arithFloatTest=init.then(configure(2,true,2)).then(instantiate).then(invoke).expect(safe and s.result==102)
 run arithGenericTest=init.then(configure(2,true,0)).then(instantiate).then(invoke).expect(safe and s.result==100)
 run absentUnsafeTest=init.then(configure(2,false,1)).then(configureNoUnsafe).then(instantiate).then(invoke).expect(safe and s.result==101)
 run absentFixTest=init.then(configure(2,true,1)).then(configureAbsentFix).then(instantiate).then(invoke).expect(safe and s.result==100)
 run missingFixTest=init.then(configure(2,true,1)).then(configureMissing).then(instantiate).then(invoke).expect(safe and s.result == -1 and not(admitted))
 run privateWorkspaceTest=init.then(configure(2,false,1)).then(chooseWorkspace(1)).then(instantiate).then(invoke).expect(safe and s.result==113)
 run originDeniedTest=init.then(instantiate).then(changeOrigin).expect(safe and not(canInvoke))
 run staleSelfControlTest=init.then(configure(1,true,0)).then(instantiate).then(staleSelf).then(forceInvoke).expect(not(safe))
 run foreignSpecControlTest=init.then(instantiate).then(foreignSpec).then(forceInvoke).expect(not(safe))
 run priorityControlTest=init.then(configure(2,false,1)).then(instantiate).then(invoke).then(preferFix).expect(not(safe))
 run inventedUnsafeControlTest=init.then(configure(2,false,1)).then(configureNoUnsafe).then(instantiate).then(inventedUnsafe).then(forceInvoke).expect(not(safe))
 run missingFallbackControlTest=init.then(configure(2,true,1)).then(configureMissing).then(instantiate).then(absentInsteadMissing).then(forceInvoke).expect(not(safe))
 run skippedReadControlTest=init.then(configure(2,false,1)).then(instantiate).then(invoke).then(skipRead).expect(not(safe))
 run wrongNameControlTest=init.then(configure(2,true,1)).then(instantiate).then(globalName).then(forceInvoke).expect(not(safe))
 run originIgnoredControlTest=init.then(instantiate).then(changeOrigin).then(forceInvoke).expect(not(safe))
}
