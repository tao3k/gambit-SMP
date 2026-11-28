module foreign_cleanup_closure {
 // Three distinct release rights; parent 0 can derive child 1, then 1 derives 2.
 // 0 absent, 1 reserved, 2 queued, 3 running, 4 waiting, 5 settled, 6 unknown, 7 partial.
 type State={task:List[int],calls:List[int],credit:Set[int],debt:int,open:bool,
  gc:bool,roots:bool,readers:int,owner:int,scanner:int,prepared:bool,frozen:bool,
  ack:bool,lost:bool,rosterReceipt:bool,exited:bool,facilities:bool,cleaned:bool,
  wrapper:bool,captured:bool,cursor:int,waitContext:bool,residue:bool,
  booked:int,deferred:int,rcBytes:int,outcome:bool}
 pure val Rights=Set(0,1,2)
 pure val initial:State={task:[0,0,0],calls:[0,0,0],credit:Set(),debt:0,open:true,
  gc:false,roots:true,readers:0,owner:1,scanner:1,prepared:false,frozen:false,
  ack:false,lost:false,rosterReceipt:false,exited:false,facilities:true,cleaned:false,
  wrapper:true,captured:false,cursor:0,waitContext:false,residue:false,
  booked:1,deferred:3,rcBytes:8,outcome:false}
 var s:State
 action init=s'=initial
 def live=s.credit
 def noRunning=Rights.forall(i=>s.task[i]!=3 and s.task[i]!=6)
 def affinityClosed=not(s.residue) and Set(0,1).forall(i=>s.task[i]==0 or s.task[i]==5)
 def closed=not(s.open) and s.debt==0 and Rights.forall(i=>s.task[i]==0 or s.task[i]==5)
 val safe=all{
  s.debt==s.credit.size(),s.debt>=0,
  Rights.forall(i=>(s.task[i]>=1 and s.task[i]!=5) == s.credit.contains(i)),
  Rights.forall(i=>s.calls[i]<=1),
  s.owner==s.scanner,
  s.booked+s.deferred==4,s.rcBytes==8,
  not(s.wrapper) implies s.captured,
  s.exited implies (s.owner==0 and s.ack and not(s.lost) and affinityClosed and s.rosterReceipt),
  s.gc implies Rights.forall(i=>s.task[i]!=3),
  live.size()>0 implies (s.roots and s.facilities),
  s.task[0]==4 implies s.waitContext,
  s.cleaned implies (s.rosterReceipt and closed and not(s.residue) and not(s.outcome) and s.readers==0 and not(s.gc) and not(s.roots))
 }
 action captureRoot=all{s.wrapper,s.open,s.task[0]==0,s.facilities,s.roots,
  s'={...s,task:s.task.replaceAt(0,2),credit:Set(0),debt:1,captured:true,wrapper:false}}
 action closeIngress=all{s.captured,s'={...s,open:false,frozen:true}}
 action beginGc=all{not(s.gc),s.facilities,s.roots,noRunning,s'={...s,gc:true}}
 action endGc=all{s.gc,s'={...s,gc:false}}
 action start(i)=all{Rights.contains(i),s.task[i]==2,not(s.gc),s.facilities,
  i==2 or not(s.exited),s'={...s,task:s.task.replaceAt(i,3),calls:s.calls.replaceAt(i,s.calls[i]+1)}}
 action reserveChild(p,c)=all{p<2,c==p+1,s.task[p]==3,s.task[c]==0,
  s'={...s,task:s.task.replaceAt(c,1),credit:s.credit.union(Set(c)),debt:s.debt+1}}
 action publishChild(c)=all{s.task[c]==1,s'={...s,task:s.task.replaceAt(c,2)}}
 action abortReservation(c)=all{s.task[c]==1,s'={...s,task:s.task.replaceAt(c,0),credit:s.credit.exclude(Set(c)),debt:s.debt-1}}
 // A lost queue-publication acknowledgement retains credit, not a replay.
 // State 6 here has not executed native code (calls == 0); unknown native execution is outside this model.
 action unknownDelivery(c)=all{s.task[c]==1,s'={...s,task:s.task.replaceAt(c,6)}}
 action queryDelivery(c)=all{s.task[c]==6,s.calls[c]==0,s'={...s,task:s.task.replaceAt(c,2)}}
 action detachDevice=all{s.task[0]==3,s.cursor==0,s'={...s,cursor:1}}
 action finishRead=all{s.task[0]==3,s.cursor==1,s'={...s,cursor:2}}
 action finishWrite=all{s.task[0]==3,s.cursor==2,s'={...s,cursor:3}}
 action parkWait=all{s.task[0]==3,s.cursor>=1,s.cursor<=2,s'={...s,task:s.task.replaceAt(0,4),waitContext:true}}
 action resumeWait=all{s.task[0]==4,s.waitContext,not(s.gc),not(s.exited),s'={...s,task:s.task.replaceAt(0,3),waitContext:false}}
 action partialFailure=all{s.task[0]==3,s.cursor>=1,s.cursor<=2,s'={...s,task:s.task.replaceAt(0,7)}}
 action resumePartial=all{s.task[0]==7,not(s.gc),not(s.exited),s'={...s,task:s.task.replaceAt(0,3)}}
 action finish(i)=all{s.task[i]==3,i!=0 or s.cursor==3,
  s'={...s,task:s.task.replaceAt(i,5),credit:s.credit.exclude(Set(i)),debt:s.debt-1,outcome:true}}
 // Native self consumed, but error does NOT prove all underlying resources closed.
 action terminalError=all{s.task[0]==3,s.cursor==3,
  s'={...s,task:s.task.replaceAt(0,5),credit:s.credit.exclude(Set(0)),debt:s.debt-1,residue:true,outcome:true}}
 // Environment-provided terminal receipt, not inferred from an error or timeout.
 action settleResidue=all{s.residue,not(s.gc),s'={...s,residue:false}}
 action consumeOutcome=all{s.outcome,s'={...s,outcome:false}}
 action pin=all{s.roots,not(s.frozen),s'={...s,readers:s.readers+1}}
 action unpin=all{s.readers>0,s'={...s,readers:s.readers-1}}
 action prepare=all{s.frozen,s.owner==1,s'={...s,prepared:true}}
 action rejectTarget=all{s.owner==1,s.prepared,s'={...s,prepared:false}}
 // Abstract one publication gate. C scanner/census lock or epoch refinement is OPEN.
 action commitLost=all{s.prepared,s.frozen,s.readers==0,not(s.gc),noRunning,s.owner==1,
  s'={...s,owner:0,scanner:0,ack:false,lost:true}}
 action acknowledge=all{s.owner==0,s'={...s,ack:true,lost:false}}
 action foldQuota=all{s.facilities,not(s.gc),s'={...s,booked:s.booked+s.deferred,deferred:0}}
 // Receipt supplied by prior topology/guard proof, not inferred from callback return.
 action recordRosterReceipt=all{s.owner==0,s.ack,affinityClosed,noRunning,not(s.gc),s'= {...s,rosterReceipt:true}}
 action exitOwner=all{s.rosterReceipt,s.owner==0,s.ack,not(s.lost),affinityClosed,noRunning,not(s.gc),s'={...s,exited:true}}
 action retireRoots=all{closed,not(s.residue),not(s.outcome),s.readers==0,not(s.gc),s.owner==0,s.ack,s'={...s,roots:false}}
 action cleanupVm=all{s.rosterReceipt,closed,not(s.residue),not(s.outcome),s.readers==0,not(s.gc),not(s.roots),s.owner==0,s.ack,s'={...s,facilities:false,cleaned:true}}
 action step=any{captureRoot,closeIngress,beginGc,endGc,start(0),start(1),start(2),reserveChild(0,1),reserveChild(1,2),publishChild(1),publishChild(2),abortReservation(1),abortReservation(2),unknownDelivery(1),unknownDelivery(2),queryDelivery(1),queryDelivery(2),detachDevice,finishRead,finishWrite,parkWait,resumeWait,partialFailure,resumePartial,finish(0),finish(1),finish(2),terminalError,settleResidue,consumeOutcome,prepare,rejectTarget,commitLost,acknowledge,foldQuota,recordRosterReceipt,exitOwner,retireRoots,cleanupVm,all{s'=s}}
 run cleanupTest=init.then(captureRoot).then(closeIngress).then(start(0)).then(detachDevice).then(finishRead).then(finishWrite).then(finish(0)).then(consumeOutcome).then(prepare).then(commitLost).then(acknowledge).then(recordRosterReceipt).then(retireRoots).then(cleanupVm).then(all{assert(safe and s.cleaned),s'=s})
 run childSurvivesParentTest=init.then(captureRoot).then(start(0)).then(reserveChild(0,1)).then(publishChild(1)).then(detachDevice).then(finishRead).then(finishWrite).then(finish(0)).then(closeIngress).then(all{assert(safe and s.debt==1 and not(closed)),s'=s})
 run lostDeliveryTest=init.then(captureRoot).then(start(0)).then(reserveChild(0,1)).then(unknownDelivery(1)).then(all{assert(safe and s.debt==2),s'=s}).then(queryDelivery(1)).then(all{assert(safe and s.task[1]==2),s'=s})
 run waitAcrossGcTest=init.then(captureRoot).then(start(0)).then(detachDevice).then(parkWait).then(beginGc).then(endGc).then(resumeWait).then(all{assert(safe and s.calls[0]==1),s'=s})
 run targetScansBeforeReplyTest=init.then(captureRoot).then(closeIngress).then(prepare).then(commitLost).then(beginGc).then(all{assert(safe and s.scanner==0 and s.lost),s'=s})
 run terminalErrorTest=init.then(captureRoot).then(start(0)).then(detachDevice).then(finishRead).then(finishWrite).then(terminalError).then(closeIngress).then(all{assert(safe and closed and s.residue),s'=s})
 run partialCursorTest=init.then(captureRoot).then(start(0)).then(detachDevice).then(partialFailure).then(resumePartial).then(all{assert(safe and s.cursor==1 and s.calls[0]==1),s'=s})
 run reserveFailureTest=init.then(captureRoot).then(start(0)).then(reserveChild(0,1)).then(abortReservation(1)).then(all{assert(safe and s.debt==1),s'=s})
 run wrongCreditControlTest=init.then(captureRoot).then(all{s'={...s,debt:0}}).then(all{assert(not(safe)),s'=s})
 run duplicateCallControlTest=init.then(captureRoot).then(all{s'={...s,calls:[2,0,0]}}).then(all{assert(not(safe)),s'=s})
 run scannerGapControlTest=init.then(captureRoot).then(all{s'={...s,owner:0}}).then(all{assert(not(safe)),s'=s})
 run earlyVmControlTest=init.then(captureRoot).then(all{s'={...s,facilities:false,cleaned:true}}).then(all{assert(not(safe)),s'=s})
 run lostChildControlTest=init.then(captureRoot).then(start(0)).then(reserveChild(0,1)).then(all{s'={...s,credit:Set(0),debt:1}}).then(all{assert(not(safe)),s'=s})
 run waitingContextControlTest=init.then(captureRoot).then(start(0)).then(detachDevice).then(parkWait).then(all{s'={...s,waitContext:false}}).then(all{assert(not(safe)),s'=s})
 run affinityExitControlTest=init.then(captureRoot).then(closeIngress).then(prepare).then(commitLost).then(acknowledge).then(all{s'={...s,exited:true}}).then(all{assert(not(safe)),s'=s})
 run doubleCensusControlTest=init.then(all{s'={...s,booked:4}}).then(all{assert(not(safe)),s'=s})
 run lostReplyExitControlTest=init.then(captureRoot).then(closeIngress).then(prepare).then(commitLost).then(all{s'={...s,exited:true}}).then(all{assert(not(safe)),s'=s})
 run uncapturedFreeControlTest=init.then(all{s'={...s,wrapper:false}}).then(all{assert(not(safe)),s'=s})
 run errorTeardownControlTest=init.then(captureRoot).then(start(0)).then(detachDevice).then(finishRead).then(finishWrite).then(terminalError).then(closeIngress).then(all{s'={...s,cleaned:true}}).then(all{assert(not(safe)),s'=s})
 run independentChildAfterExitTest=init.then(captureRoot).then(start(0)).then(reserveChild(0,1)).then(publishChild(1)).then(detachDevice).then(finishRead).then(finishWrite).then(finish(0)).then(start(1)).then(reserveChild(1,2)).then(publishChild(2)).then(finish(1)).then(closeIngress).then(prepare).then(commitLost).then(acknowledge).then(recordRosterReceipt).then(exitOwner).then(start(2)).then(all{assert(safe and s.exited and not(closed)),s'=s})
 run reservedChildAfterParentTest=init.then(captureRoot).then(start(0)).then(reserveChild(0,1)).then(detachDevice).then(finishRead).then(finishWrite).then(finish(0)).then(closeIngress).then(all{assert(safe and s.task[1]==1 and not(closed)),s'=s})
 run refusedHandoffTest=init.then(captureRoot).then(closeIngress).then(prepare).then(rejectTarget).then(all{assert(safe and s.owner==1 and s.scanner==1 and s.roots),s'=s})
 run inlineGcControlTest=init.then(captureRoot).then(start(0)).then(all{s'={...s,gc:true}}).then(all{assert(not(safe)),s'=s})
 run unknownQueuedDuringGcTest=init.then(captureRoot).then(start(0)).then(reserveChild(0,1)).then(detachDevice).then(finishRead).then(finishWrite).then(finish(0)).then(closeIngress).then(beginGc).then(unknownDelivery(1)).then(all{assert(safe and s.gc and s.calls[1]==0 and s.debt==1),s'=s})
}
