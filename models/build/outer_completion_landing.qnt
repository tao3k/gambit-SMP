module outer_completion_landing {
 pure val A=Set(0,1)
 // Phase: unused,boundary,call,landed,call-catcher-restored,marker-settled,
 // outer-catcher-restored,registers-reloaded,settled,released.
 type State={pc:List[int],owner:List[bool],marker:List[bool],abnormal:List[bool],
  stack:List[int],debt:List[bool],capture:List[bool],invoke:List[bool],
  rejected:List[bool],vm:bool,closed:bool,bad:bool}
 pure val initial:State={pc:[0,0],owner:[false,false],marker:[false,false],
 abnormal:[false,false],stack:[],debt:[false,false],capture:[false,false],
 invoke:[false,false],rejected:[false,false],vm:true,closed:false,bad:false}
 var s:State
 action init=s'=initial
 def active(i)=s.pc[i]>0 and s.pc[i]<9
 def top(n)=if(s.stack.length()>0) s.stack[s.stack.length()-1]==n else false
 val safe=all{not(s.bad),A.forall(i=>active(i) implies (s.owner[i] and s.vm)),
 A.forall(i=>s.pc[i]>=5 implies not(s.marker[i])),
 A.forall(i=>s.pc[i]>=8 implies not(s.debt[i])),
 A.forall(i=>s.pc[i]>=6 implies not(s.stack.indices().exists(j=>s.stack[j]==10*i))),
 A.forall(i=>s.pc[i]>=4 implies not(s.stack.indices().exists(j=>s.stack[j]==10*i+1))),
 A.forall(i=>(s.capture[i] or s.invoke[i]) implies s.vm),
 not(s.vm) implies (s.stack.length()==0 and not(A.exists(i=>s.owner[i] or s.capture[i] or s.invoke[i])))}
 action enterBoundary(i)=all{s.pc[i]==0,s.vm,not(s.closed),i==0 or s.pc[0]==2,
 s'={...s,pc:s.pc.replaceAt(i,1),owner:s.owner.replaceAt(i,true),marker:s.marker.replaceAt(i,true),stack:s.stack.append(10*i)}}
 action beginCall(i)=all{s.pc[i]==1,top(10*i),s'={...s,pc:s.pc.replaceAt(i,2),stack:s.stack.append(10*i+1)}}
 action land(i,error)=all{s.pc[i]==2,top(10*i+1),s'={...s,pc:s.pc.replaceAt(i,3),abnormal:s.abnormal.replaceAt(i,error)}}
 action restoreCall(i)=all{s.pc[i]==3,top(10*i+1),s'={...s,pc:s.pc.replaceAt(i,4),stack:s.stack.slice(0,s.stack.length()-1)}}
 // Abnormal edge below is a REQUIRED NEW stable marker guard, not current ___run/SFUN.
 action completeMarker(i)=all{s.pc[i]==4,top(10*i),s'={...s,pc:s.pc.replaceAt(i,5),marker:s.marker.replaceAt(i,false)}}
 action restoreOuter(i)=all{s.pc[i]==5,top(10*i),s'={...s,pc:s.pc.replaceAt(i,6),stack:s.stack.slice(0,s.stack.length()-1)}}
 // Combines CFUN R_ALL and remaining caller cleanup in this bounded abstraction.
 action reloadRoots(i)=all{s.pc[i]==6,s'={...s,pc:s.pc.replaceAt(i,7)}}
 action oweRoster(i)=all{s.pc[i]==1,s'={...s,debt:s.debt.replaceAt(i,true)}}
 // Proposed acknowledged custody transfer. Actual secondary ___run caller loops forever.
 action transferRoster(i)=all{s.pc[i]==7,s.debt[i],s'={...s,debt:s.debt.replaceAt(i,false)}}
 action settle(i)=all{s.pc[i]==7,not(s.debt[i]),i==1 or not(active(1)),s'={...s,pc:s.pc.replaceAt(i,8)}}
 action release(i)=all{s.pc[i]==8,s.owner[i],s'={...s,pc:s.pc.replaceAt(i,9),owner:s.owner.replaceAt(i,false)}}
 action captureK(i)=all{s.pc[i]==2,s'={...s,capture:s.capture.replaceAt(i,true)}}
 action invokeK(i)=all{s.pc[i]>=8,s.capture[i],not(s.invoke[i]),s.vm,s'={...s,invoke:s.invoke.replaceAt(i,true),rejected:s.rejected.replaceAt(i,false)}}
 // Repeated Scheme restoration is fresh invocation authority, never a popped C catcher.
 action denyDeadC(i)=all{s.invoke[i],not(s.marker[i]),s'={...s,rejected:s.rejected.replaceAt(i,true)}}
 action endInvoke(i)=all{s.invoke[i],s.rejected[i],s'={...s,invoke:s.invoke.replaceAt(i,false)}}
 action dropK(i)=all{s.capture[i],s'={...s,capture:s.capture.replaceAt(i,false)}}
 action close=all{s'={...s,closed:true}}
 action retireVm=all{s.closed,s.stack.length()==0,not(A.exists(i=>s.owner[i] or s.capture[i] or s.invoke[i])),s'={...s,vm:false}}
 action step=any{enterBoundary(0),enterBoundary(1),beginCall(0),beginCall(1),land(0,false),land(1,false),land(0,true),land(1,true),restoreCall(0),restoreCall(1),completeMarker(0),completeMarker(1),restoreOuter(0),restoreOuter(1),reloadRoots(0),reloadRoots(1),oweRoster(0),oweRoster(1),transferRoster(0),transferRoster(1),settle(0),settle(1),release(0),release(1),captureK(0),captureK(1),invokeK(0),invokeK(1),denyDeadC(0),denyDeadC(1),endInvoke(0),endInvoke(1),dropK(0),dropK(1),close,retireVm,all{s'=s}}
 action start(i)=enterBoundary(i).then(beginCall(i))
 action finish(i,e)=land(i,e).then(restoreCall(i)).then(completeMarker(i)).then(restoreOuter(i)).then(reloadRoots(i)).then(settle(i)).then(release(i))
 run normalTest=init.then(start(0)).then(finish(0,false)).then(close).then(retireVm).then(all{assert(safe),s'=s})
 run exceptionalTest=init.then(start(0)).then(finish(0,true)).then(all{assert(safe),s'=s})
 run nestedTest=init.then(start(0)).then(start(1)).then(finish(1,true)).then(all{assert(safe and top(1) and s.owner[0]),s'=s}).then(finish(0,false)).then(all{assert(safe),s'=s})
 run multishotTest=init.then(start(0)).then(captureK(0)).then(finish(0,false)).then(invokeK(0)).then(denyDeadC(0)).then(endInvoke(0)).then(invokeK(0)).then(denyDeadC(0)).then(all{assert(safe and s.pc[0]==9 and s.stack.length()==0),s'=s})
 run rosterCustodyTest=init.then(enterBoundary(0)).then(oweRoster(0)).then(beginCall(0)).then(land(0,true)).then(restoreCall(0)).then(completeMarker(0)).then(restoreOuter(0)).then(reloadRoots(0)).then(all{assert(safe and s.owner[0] and s.debt[0]),s'=s}).then(transferRoster(0)).then(settle(0)).then(release(0)).then(all{assert(safe),s'=s})
 run earlyReleaseControlTest=init.then(start(0)).then(all{s'={...s,owner:[false,false]}}).then(all{assert(not(safe)),s'=s})
 run wrongCatcherControlTest=init.then(start(0)).then(start(1)).then(all{s'={...s,pc:s.pc.replaceAt(0,6)}}).then(all{assert(not(safe)),s'=s})
 run markerSkippedControlTest=init.then(start(0)).then(land(0,true)).then(restoreCall(0)).then(all{s'={...s,pc:[5,0]}}).then(all{assert(not(safe)),s'=s})
 run rosterSkippedControlTest=init.then(enterBoundary(0)).then(oweRoster(0)).then(beginCall(0)).then(all{s'={...s,pc:[8,0],marker:[false,false],stack:[]}}).then(all{assert(not(safe)),s'=s})
 run resurrectCatcherControlTest=init.then(start(0)).then(captureK(0)).then(finish(0,false)).then(invokeK(0)).then(all{s'={...s,stack:[0]}}).then(all{assert(not(safe)),s'=s})
 run capturedVmFreedControlTest=init.then(start(0)).then(captureK(0)).then(finish(0,false)).then(all{s'={...s,vm:false}}).then(all{assert(not(safe)),s'=s})
}
