module device_cleanup_wait {
 pure val Roster=Set(0,1)
 // cursor: 0 wrapper, 1 RD, 2 WR, 3 native release, 4 terminal.
 // wait: 0 none, 1 prepared, 2 armed, 3 blocked, 4 returned,
 // 5 participating, 6 GC, 7 GC returned, 8 loop closed, 9 restored.
 // mode: 0 normal, 1 known partial/retryable by qualified adapter, 2 unknown.
 // child: 0 absent, 1 reserved, 2 queued, 3 running, 4 terminal, 5 unknown enqueue.
 type State={cursor:int,detached:bool,hookCalls:int,nativeLive:bool,mode:int,residue:bool,
  wait:int,needOp:int,armedOp:int,context:bool,need:bool,ready:bool,token:bool,borrow:bool,
  request:int,served:int,round:int,epoch:int,loaded:int,roots:bool,gc:bool,
  joined:Set[int],returned:Set[int],noop:Set[int],service:Set[int],members:Set[int],
  generation:int,waitGeneration:int,parent:bool,child:int,childOwner:int,debt:int,
  ingress:bool,storage:int,scanner:int,ack:bool,rosterReceipt:bool,exited:bool,
  outcome:bool,facilities:bool,cleaned:bool}
 pure val initial:State={cursor:0,detached:false,hookCalls:0,nativeLive:true,mode:0,residue:false,
  wait:0,needOp:0,armedOp:0,context:false,need:false,ready:false,token:false,borrow:false,
  request:0,served:0,round:0,epoch:0,loaded:0,roots:true,gc:false,
  joined:Set(),returned:Set(),noop:Set(),service:Roster,members:Roster,
  generation:1,waitGeneration:1,parent:false,child:0,childOwner:0,debt:0,
  ingress:true,storage:1,scanner:1,ack:false,rosterReceipt:false,exited:false,
  outcome:false,facilities:true,cleaned:false}
 var s:State
 action init=s'=initial
 def childOwed=s.child>=1 and s.child!=4
 def runnable=s.cursor>=1 and s.cursor<=3 and s.wait==0 and s.mode==0 and not(s.need) and not(s.gc) and s.request==s.served and s.loaded==s.epoch and not(s.exited)
 def parentClosed=not(s.parent) and s.cursor==4 and not(s.nativeLive) and s.mode==0 and not(s.residue)
 def affinityClosed=parentClosed and (s.childOwner==0 or not(childOwed))
 def allClosed=parentClosed and not(childOwed) and not(s.ingress) and s.debt==0
 val safe=all{
  s.hookCalls<=1,
  s.debt==(if(s.parent)1 else 0)+(if(childOwed)1 else 0),
  s.storage==s.scanner,
  s.wait>0 implies (s.context and s.roots and s.waitGeneration==s.generation),
  s.borrow implies (s.wait==2 or s.wait==3),
  (s.wait>=2 and s.wait<=4) implies s.armedOp==s.needOp,
  s.gc implies (s.wait==6 and s.joined==Roster and s.service==Roster and s.members==Roster and not(s.borrow) and s.roots and s.child!=3),
  s.wait==3 implies (s.token or s.ready or s.request==s.served),
  s.exited implies (affinityClosed and s.storage==0 and s.ack and s.rosterReceipt and s.wait==0 and not(s.borrow) and s.request==s.served),
  (s.parent or childOwed or s.outcome or s.mode==2 or s.residue) implies (s.roots and s.facilities),
  s.cleaned implies (allClosed and not(s.outcome) and not(s.roots) and not(s.gc) and s.wait==0 and not(s.borrow) and s.rosterReceipt and s.ack)
 }
 action capture=all{s.cursor==0,s.ingress,s'={...s,cursor:1,detached:true,hookCalls:1,parent:true,debt:1}}
 action closeIngress=all{s.cursor>0,s'={...s,ingress:false}}
 action closeAgain=all{runnable,s.cursor<=2,s'={...s,need:true,needOp:s.cursor}}
 action closeAgainOpposite=all{runnable,s.cursor<=2,s'={...s,need:true,needOp:3-s.cursor}}
 action closeSuccess=all{runnable,s.cursor<=2,s'={...s,cursor:s.cursor+1}}
 action knownPartial=all{runnable,s.cursor<=2,s'={...s,mode:1}}
 // Requires operation-specific proof that repeating current close phase is legal.
 action qualifyRetry=all{s.mode==1,s.wait==0,not(s.gc),s'={...s,mode:0}}
 action unknownClose=all{runnable,s'={...s,mode:2}}
 // Environment-provided journal/outcome receipt; no guessing from stage flags.
 action resolveAlive=all{s.mode==2,s.wait==0,not(s.gc),s'={...s,mode:1}}
 action resolveConsumed=all{s.mode==2,s.wait==0,not(s.gc),s'={...s,mode:0,cursor:4,nativeLive:false,parent:false,debt:s.debt-1,residue:true,outcome:true}}
 action settleResidue=all{s.residue,s.wait==0,not(s.gc),s'={...s,residue:false}}
 action prepareWait=all{s.parent,s.wait==0,s.facilities,not(s.exited),s.need or s.request>s.served,
  s'={...s,wait:1,context:true,waitGeneration:s.generation}}
 action arm=all{s.wait==1,s'={...s,wait:2,borrow:true,armedOp:s.needOp}}
 // Durable level-notification is a premise. Native ignored write errors are NOT proved safe.
 action interrupt=all{not(s.exited),s.facilities,s.roots,s.parent,s.request<2,s'={...s,request:s.request+1,token:true}}
 action ioReady=all{s.wait>=1,s.wait<=4,s'={...s,ready:true}}
 action block=all{s.wait==2,s.request==s.served,not(s.ready),not(s.token),s'={...s,wait:3}}
 action receiveWake=all{(s.wait==2 or s.wait==3),(s.ready or s.token or s.request>s.served),s'={...s,wait:4,borrow:false,token:false}}
 action publishRoots=all{s.wait==4,s.request>s.served,s.roots,s.service==Roster,s'={...s,wait:5,round:s.request,joined:Set(),returned:Set(),noop:Set()}}
 action join(w)=all{s.wait==5,Roster.contains(w),s.service.contains(w),s'={...s,joined:s.joined.union(Set(w))}}
 action beginGc=all{s.wait==5,s.joined==Roster,not(s.borrow),s.child!=3,s'={...s,wait:6,gc:true,epoch:s.epoch+1}}
 action returnGc(w)=all{s.wait==6,Roster.contains(w),s'={...s,returned:s.returned.union(Set(w))}}
 action finishGc=all{s.wait==6,s.returned==Roster,s'={...s,wait:7,gc:false}}
 action arriveNoop(w)=all{s.wait==7,Roster.contains(w),s'={...s,noop:s.noop.union(Set(w))}}
 action repeatRound=all{s.wait==7,s.request>s.round,s'={...s,wait:5,round:s.request,joined:Set(),returned:Set(),noop:Set()}}
 action closeLoop=all{s.wait==7,s.noop==Roster,s.request==s.round,s'={...s,wait:8,served:s.round,token:false}}
 action restore=all{s.wait==8,s.request==s.served,s'={...s,wait:9,loaded:s.epoch}}
 // A new request after loop return must be serviced before native code resumes.
 action reenter=all{(s.wait==8 or s.wait==9),s.request>s.served,s'={...s,wait:5,round:s.request,joined:Set(),returned:Set(),noop:Set()}}
 action noInterruptReturn=all{s.wait==4,s.request==s.served,s'={...s,wait:9,loaded:s.epoch}}
 action resumeCursor=all{s.wait==9,s.ready,s.loaded==s.epoch,s.request==s.served,s.mode==0,
  s'={...s,wait:0,context:false,ready:false,need:false}}
 action rearm=all{s.wait==9,not(s.ready),s.need,s.request==s.served,s.mode==0,s'={...s,wait:1}}
 action retainUnknown=all{s.wait==9,s.mode==2,s.request==s.served,s'={...s,wait:0,context:false}}
 action reserveChild=all{runnable,s.child==0,s'={...s,child:1,debt:s.debt+1}}
 action publishChild=all{s.child==1,s'={...s,child:2}}
 action abortChild=all{s.child==1,s'={...s,child:0,debt:s.debt-1}}
 action childUnknown=all{s.child==1,s'={...s,child:5}}
 action queryChild=all{s.child==5,s'={...s,child:2}}
 action startChild=all{s.child==2,not(s.gc),(s.childOwner==0 or not(s.exited)),s'={...s,child:3}}
 action finishChild=all{s.child==3,s'={...s,child:4,debt:s.debt-1}}
 action releaseNative=all{runnable,s.cursor==3,s'={...s,cursor:4,nativeLive:false,parent:false,debt:s.debt-1,outcome:true}}
 action consumedError=all{runnable,s.cursor==3,s'={...s,cursor:4,nativeLive:false,parent:false,debt:s.debt-1,outcome:true,residue:true}}
 action moveStorage=all{not(s.ingress),s.storage==1,s.wait==0,not(s.gc),s.mode!=2,s'={...s,storage:0,scanner:0,ack:false}}
 action acknowledge=all{s.storage==0,s'={...s,ack:true}}
 // Prior topology/sender-tail/guard receipt, not a complete tree protocol proof here.
 action acceptRosterReceipt=all{affinityClosed,s.ack,s.request==s.served,s.wait==0,not(s.gc),s'={...s,rosterReceipt:true}}
 action exitProcessor=all{affinityClosed,s.ack,s.rosterReceipt,s.request==s.served,s.wait==0,not(s.gc),s'={...s,exited:true,members:Set(0),service:Set(0)}}
 action consumeOutcome=all{s.outcome,s'={...s,outcome:false}}
 action retireRoots=all{allClosed,s.ack,s.rosterReceipt,not(s.outcome),s.wait==0,not(s.gc),s.request==s.served,s'={...s,roots:false}}
 action cleanupVm=all{allClosed,s.ack,s.rosterReceipt,not(s.outcome),not(s.roots),s.wait==0,not(s.gc),s.request==s.served,s'={...s,facilities:false,cleaned:true}}
 action step=any{capture,closeIngress,closeAgain,closeAgainOpposite,closeSuccess,knownPartial,qualifyRetry,unknownClose,resolveAlive,resolveConsumed,settleResidue,prepareWait,arm,interrupt,ioReady,block,receiveWake,publishRoots,join(0),join(1),beginGc,returnGc(0),returnGc(1),finishGc,arriveNoop(0),arriveNoop(1),repeatRound,closeLoop,restore,reenter,noInterruptReturn,resumeCursor,rearm,retainUnknown,reserveChild,publishChild,abortChild,childUnknown,queryChild,startChild,finishChild,releaseNative,consumedError,moveStorage,acknowledge,acceptRosterReceipt,exitProcessor,consumeOutcome,retireRoots,cleanupVm,all{s'=s}}
 action completeRound=join(0).then(join(1)).then(beginGc).then(returnGc(0)).then(returnGc(1)).then(finishGc).then(arriveNoop(0)).then(arriveNoop(1)).then(closeLoop).then(restore)
 action gcRound=publishRoots.then(completeRound)
 run completeTest=init.then(capture).then(closeSuccess).then(closeSuccess).then(releaseNative).then(closeIngress).then(moveStorage).then(acknowledge).then(acceptRosterReceipt).then(exitProcessor).then(consumeOutcome).then(retireRoots).then(cleanupVm).then(all{assert(safe and s.cleaned),s'=s})
 run simultaneousReadyInterruptTest=init.then(capture).then(closeAgain).then(prepareWait).then(arm).then(block).then(ioReady).then(interrupt).then(receiveWake).then(gcRound).then(resumeCursor).then(all{assert(safe and s.cursor==1 and s.loaded==1 and s.hookCalls==1),s'=s})
 run interruptBeforeArmTest=init.then(capture).then(closeAgain).then(prepareWait).then(interrupt).then(arm).then(receiveWake).then(gcRound).then(rearm).then(all{assert(safe and s.need and s.wait==1),s'=s})
 run partialRetryTest=init.then(capture).then(knownPartial).then(qualifyRetry).then(closeSuccess).then(all{assert(safe and s.cursor==2 and s.hookCalls==1),s'=s})
 run unknownCustodyTest=init.then(capture).then(unknownClose).then(interrupt).then(prepareWait).then(arm).then(receiveWake).then(gcRound).then(retainUnknown).then(all{assert(safe and s.mode==2 and s.parent and s.debt==1),s'=s})
 run unknownConsumedTest=init.then(capture).then(unknownClose).then(resolveConsumed).then(all{assert(safe and s.residue and not(parentClosed)),s'=s})
 run childAfterExitTest=init.then(capture).then(reserveChild).then(publishChild).then(closeSuccess).then(closeSuccess).then(releaseNative).then(closeIngress).then(moveStorage).then(acknowledge).then(acceptRosterReceipt).then(exitProcessor).then(startChild).then(all{assert(safe and not(allClosed) and s.exited),s'=s}).then(finishChild).then(all{assert(safe and allClosed),s'=s})
 run childUnknownTest=init.then(capture).then(reserveChild).then(childUnknown).then(all{assert(safe and s.debt==2),s'=s}).then(queryChild).then(all{assert(safe and s.child==2),s'=s})
 run duplicateHookControlTest=init.then(capture).then(all{s'={...s,hookCalls:2}}).then(all{assert(not(safe)),s'=s})
 run missingContextControlTest=init.then(capture).then(closeAgain).then(prepareWait).then(all{s'={...s,context:false}}).then(all{assert(not(safe)),s'=s})
 run generationControlTest=init.then(capture).then(closeAgain).then(prepareWait).then(all{s'={...s,generation:2}}).then(all{assert(not(safe)),s'=s})
 run droppedWakeControlTest=init.then(capture).then(closeAgain).then(prepareWait).then(arm).then(block).then(interrupt).then(all{s'={...s,token:false}}).then(all{assert(not(safe)),s'=s})
 run borrowIntoGcControlTest=init.then(capture).then(all{s'={...s,gc:true,wait:6,borrow:true}}).then(all{assert(not(safe)),s'=s})
 run missingParticipantControlTest=init.then(capture).then(all{s'={...s,gc:true,wait:6,joined:Set(0)}}).then(all{assert(not(safe)),s'=s})
 run lostCreditControlTest=init.then(capture).then(reserveChild).then(all{s'={...s,debt:1}}).then(all{assert(not(safe)),s'=s})
 run scannerGapControlTest=init.then(capture).then(all{s'={...s,storage:0}}).then(all{assert(not(safe)),s'=s})
 run unknownExitControlTest=init.then(capture).then(unknownClose).then(all{s'={...s,exited:true}}).then(all{assert(not(safe)),s'=s})
 run childVmCleanupControlTest=init.then(capture).then(reserveChild).then(all{s'={...s,cleaned:true,facilities:false}}).then(all{assert(not(safe)),s'=s})
 run oppositeInterestTest=init.then(capture).then(closeAgainOpposite).then(prepareWait).then(arm).then(all{assert(safe and s.cursor==1 and s.armedOp==2),s'=s}).then(ioReady).then(receiveWake).then(noInterruptReturn).then(resumeCursor).then(all{assert(safe and s.cursor==1),s'=s})
 run lostInterestControlTest=init.then(capture).then(closeAgainOpposite).then(prepareWait).then(arm).then(all{s'={...s,armedOp:1}}).then(all{assert(not(safe)),s'=s})
 run newRequestAfterRestoreTest=init.then(capture).then(closeAgain).then(prepareWait).then(arm).then(interrupt).then(receiveWake).then(gcRound).then(interrupt).then(reenter).then(completeRound).then(rearm).then(all{assert(safe and s.epoch==2 and s.served==2),s'=s})
 run requestDuringGcTest=init.then(capture).then(closeAgain).then(prepareWait).then(arm).then(interrupt).then(receiveWake).then(publishRoots).then(join(0)).then(join(1)).then(beginGc).then(interrupt).then(returnGc(0)).then(returnGc(1)).then(finishGc).then(repeatRound).then(completeRound).then(rearm).then(all{assert(safe and s.epoch==2 and s.served==2),s'=s})
}
