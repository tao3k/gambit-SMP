module decrement_restore_closure {
 pure val A=Set(0,1)
 // 0 unused,1 running,2 SELF,3 host exit,4 reentry,5 throw,6 catcher restored,
 // 7 normal call tail,8 marker invalidated,9 boundary settled,10 detached.
 // These are proposed guarded lifetime cuts, not an interpreter for Gambit.
 type State={phase:List[int],claim:List[bool],exec:List[bool],prepared:List[bool],
  published:List[bool],known:List[bool],marker:List[bool],error:List[bool],
  capture:List[bool],kinvoke:List[bool],kproc:List[int],rejected:List[int],
  vmLive:bool,processors:Set[int],badAccess:bool,closed:bool}
 pure val initial:State={phase:[0,0],claim:[false,false],exec:[false,false],prepared:[false,false],
  published:[false,false],known:[true,true],marker:[false,false],error:[false,false],
  capture:[false,false],kinvoke:[false,false],kproc:[0,0],rejected:[0,0],
  vmLive:true,processors:Set(0,1),badAccess:false,closed:false}
 var s:State
 action init=s'=initial
 def touching(i)=s.phase[i]>=1 and s.phase[i]<=8
 def owns(i)=s.claim[i] or s.exec[i]
 def nativeLive=A.exists(i=>s.claim[i] or s.exec[i])
 def futureVm=A.exists(i=>s.capture[i] or s.kinvoke[i])
 val safe=all{not(s.badAccess),
  A.forall(i=>touching(i) implies (owns(i) and s.vmLive and s.processors.contains(0))),
  A.forall(i=>s.phase[i]>=9 implies not(s.marker[i])),
  A.forall(i=>s.published[i] and touching(i) implies s.exec[i]),
  A.forall(i=>s.kinvoke[i] implies (s.vmLive and s.processors.contains(s.kproc[i]))),
  (nativeLive or futureVm) implies s.vmLive,
  not(s.vmLive) implies (s.closed and not(nativeLive) and not(futureVm))}
 action enter(i)=all{s.phase[i]==0,s.vmLive,s.processors.contains(0),not(s.closed),i==0 or touching(0),s'={...s,phase:s.phase.replaceAt(i,1),claim:s.claim.replaceAt(i,true),marker:s.marker.replaceAt(i,true)}}
 // Install a separate execution-session owner before publishing handoff receipt.
 action prepareOwner(i)=all{s.claim[i],touching(i),s'={...s,exec:s.exec.replaceAt(i,true),prepared:s.prepared.replaceAt(i,true)}}
 action publishOwner(i)=all{s.prepared[i],s.exec[i],s'={...s,published:s.published.replaceAt(i,true)}}
 action loseReply(i)=all{s.published[i],s'={...s,known:s.known.replaceAt(i,false)}}
 action queryOwner(i)=all{s.published[i],s'={...s,known:s.known.replaceAt(i,true)}}
 action decrementClaim(i)=all{s.claim[i],s.published[i],s.exec[i],s.known[i],s'={...s,claim:s.claim.replaceAt(i,false)}}
 action moveSelf(i)=all{s.phase[i]==1,s'={...s,phase:s.phase.replaceAt(i,2)}}
 action exitHost(i)=all{s.phase[i]==2,s'={...s,phase:s.phase.replaceAt(i,3)}}
 action reenterHost(i)=all{s.phase[i]==3,s'={...s,phase:s.phase.replaceAt(i,4)}}
 action returnThrow(i)=all{s.phase[i]==1 or s.phase[i]==2 or s.phase[i]==4,s'={...s,phase:s.phase.replaceAt(i,5),error:s.error.replaceAt(i,false)}}
 action exceptionThrow(i)=all{touching(i),s.phase[i]<5,s'={...s,phase:s.phase.replaceAt(i,5),error:s.error.replaceAt(i,true)}}
 action restoreCatcher(i)=all{s.phase[i]==5,s'={...s,phase:s.phase.replaceAt(i,6)}}
 action normalCallTail(i)=all{s.phase[i]==6,not(s.error[i]),s'={...s,phase:s.phase.replaceAt(i,7)}}
 action killMarker(i)=all{s.phase[i]==7,s'={...s,phase:s.phase.replaceAt(i,8),marker:s.marker.replaceAt(i,false)}}
 // Required new abnormal completion guard. Current source does not prove this edge.
 action unwindGuard(i)=all{s.phase[i]==6,s.error[i],s'={...s,phase:s.phase.replaceAt(i,8),marker:s.marker.replaceAt(i,false)}}
 action settleBoundary(i)=all{s.phase[i]==8,not(s.marker[i]),i==1 or not(touching(1)),s'={...s,phase:s.phase.replaceAt(i,9)}}
 action decrementLeaf(i)=all{s.phase[i]==9,s.claim[i],not(s.exec[i]),s'={...s,claim:s.claim.replaceAt(i,false)}}
 action detachOwner(i)=all{s.phase[i]==9,not(s.claim[i]),s'={...s,phase:s.phase.replaceAt(i,10),exec:s.exec.replaceAt(i,false)}}
 // Capture roots retain VM semantics, not the original processor pointer forever.
 action captureK(i)=all{s.phase[i]>=1,s.phase[i]<=4,s'={...s,capture:s.capture.replaceAt(i,true)}}
 action invokeK(i,p)=all{s.capture[i],s.phase[i]>=9,not(s.kinvoke[i]),s.vmLive,s.processors.contains(p),s'={...s,kinvoke:s.kinvoke.replaceAt(i,true),kproc:s.kproc.replaceAt(i,p),rejected:s.rejected.replaceAt(i,0)}}
 // Actual return-to-C checks wrong processor BEFORE invalid marker.
 action attemptCReturn(i)=all{s.kinvoke[i],s'={...s,rejected:s.rejected.replaceAt(i,if(s.kproc[i]!=0)1 else if(not(s.marker[i]))2 else 0)}}
 action leaveInvocation(i)=all{s.kinvoke[i],s.rejected[i]>0,s'={...s,kinvoke:s.kinvoke.replaceAt(i,false)}}
 action dropCapture(i)=all{s.capture[i],s'={...s,capture:s.capture.replaceAt(i,false)}}
 action close=all{s'={...s,closed:true}}
 action retireProcessor=all{s.closed,not(A.exists(i=>touching(i))),not(A.exists(i=>s.kinvoke[i] and s.kproc[i]==0)),not(nativeLive),s'={...s,processors:s.processors.exclude(Set(0))}}
 action retireVm=all{s.closed,not(nativeLive),not(futureVm),not(A.exists(i=>touching(i))),s'={...s,vmLive:false}}
 action step=any{enter(0),enter(1),prepareOwner(0),prepareOwner(1),publishOwner(0),publishOwner(1),loseReply(0),loseReply(1),queryOwner(0),queryOwner(1),decrementClaim(0),decrementClaim(1),moveSelf(0),moveSelf(1),exitHost(0),exitHost(1),reenterHost(0),reenterHost(1),returnThrow(0),returnThrow(1),exceptionThrow(0),exceptionThrow(1),restoreCatcher(0),restoreCatcher(1),normalCallTail(0),normalCallTail(1),killMarker(0),killMarker(1),unwindGuard(0),unwindGuard(1),settleBoundary(0),settleBoundary(1),decrementLeaf(0),decrementLeaf(1),detachOwner(0),detachOwner(1),captureK(0),captureK(1),invokeK(0,0),invokeK(0,1),invokeK(1,0),invokeK(1,1),attemptCReturn(0),attemptCReturn(1),leaveInvocation(0),leaveInvocation(1),dropCapture(0),dropCapture(1),close,retireProcessor,retireVm,all{s'=s}}
 action handoff(i)=prepareOwner(i).then(publishOwner(i)).then(decrementClaim(i))
 action finishNormal(i)=returnThrow(i).then(restoreCatcher(i)).then(normalCallTail(i)).then(killMarker(i)).then(settleBoundary(i))
 run ownerBeforeDecrementTest=init.then(enter(0)).then(handoff(0)).then(moveSelf(0)).then(exitHost(0)).then(reenterHost(0)).then(finishNormal(0)).then(detachOwner(0)).then(close).then(retireVm).then(all{assert(safe and not(s.vmLive)),s'=s})
 run leafAfterBoundaryTest=init.then(enter(0)).then(finishNormal(0)).then(decrementLeaf(0)).then(detachOwner(0)).then(all{assert(safe),s'=s})
 run unknownHandoffKeepsBothTest=init.then(enter(0)).then(prepareOwner(0)).then(publishOwner(0)).then(loseReply(0)).then(all{assert(safe and s.claim[0] and s.exec[0]),s'=s}).then(queryOwner(0)).then(decrementClaim(0)).then(all{assert(safe),s'=s})
 run exceptionRestorationTest=init.then(enter(0)).then(handoff(0)).then(exceptionThrow(0)).then(restoreCatcher(0)).then(unwindGuard(0)).then(settleBoundary(0)).then(detachOwner(0)).then(all{assert(safe),s'=s})
 run nestedUnwindKeepsOuterTest=init.then(enter(0)).then(handoff(0)).then(enter(1)).then(handoff(1)).then(exceptionThrow(1)).then(restoreCatcher(1)).then(unwindGuard(1)).then(settleBoundary(1)).then(detachOwner(1)).then(all{assert(safe and s.exec[0] and not(s.exec[1])),s'=s})
 run multishotMarkerRejectedTest=init.then(enter(0)).then(captureK(0)).then(finishNormal(0)).then(decrementLeaf(0)).then(detachOwner(0)).then(invokeK(0,0)).then(attemptCReturn(0)).then(leaveInvocation(0)).then(invokeK(0,0)).then(attemptCReturn(0)).then(all{assert(safe and s.rejected[0]==2),s'=s})
 run captureAllowsProcessorReplacementTest=init.then(enter(0)).then(captureK(0)).then(finishNormal(0)).then(decrementLeaf(0)).then(detachOwner(0)).then(close).then(retireProcessor).then(invokeK(0,1)).then(attemptCReturn(0)).then(all{assert(safe and s.rejected[0]==1 and not(s.processors.contains(0))),s'=s})
 run dropAliasDuringInvocationTest=init.then(enter(0)).then(captureK(0)).then(finishNormal(0)).then(decrementLeaf(0)).then(detachOwner(0)).then(invokeK(0,1)).then(dropCapture(0)).then(all{assert(safe and futureVm),s'=s})
 run earlyDecrementControlTest=init.then(enter(0)).then(all{s'={...s,claim:[false,false]}}).then(all{assert(not(safe)),s'=s})
 run hostExitNotBoundaryControlTest=init.then(enter(0)).then(moveSelf(0)).then(exitHost(0)).then(all{s'={...s,claim:[false,false]}}).then(all{assert(not(safe)),s'=s})
 run catcherRestoreAfterFreeControlTest=init.then(enter(0)).then(exceptionThrow(0)).then(all{s'={...s,vmLive:false}}).then(all{assert(not(safe)),s'=s})
 run skippedMarkerCleanupControlTest=init.then(enter(0)).then(exceptionThrow(0)).then(restoreCatcher(0)).then(all{s'={...s,phase:[9,0]}}).then(all{assert(not(safe)),s'=s})
 run captureFreedVmControlTest=init.then(enter(0)).then(captureK(0)).then(finishNormal(0)).then(decrementLeaf(0)).then(detachOwner(0)).then(all{s'={...s,vmLive:false}}).then(all{assert(not(safe)),s'=s})
 run invocationUsesRetiredProcessorControlTest=init.then(enter(0)).then(captureK(0)).then(finishNormal(0)).then(decrementLeaf(0)).then(detachOwner(0)).then(close).then(retireProcessor).then(all{s'={...s,kinvoke:[true,false],kproc:[0,0]}}).then(all{assert(not(safe)),s'=s})
}
