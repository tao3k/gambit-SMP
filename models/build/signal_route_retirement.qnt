module signal_route_retirement {
 pure val Handlers=Set(0,1,2)
 pure val Threads=Set(0,1)
 pure val Roster=Set(0,1)
 pure val Host=[0,1,0]
 // handler: 0 absent, 1 selected/pre-entry-CAS, 2 pinned, 3 last-access complete, 4 left, 5 denied.
 type State={gate:bool,generation:int,h:List[int],seen:List[int],pins:Set[int],
  sourceStopped:bool,masks:Set[int],maskFailures:Set[int],maskUnknown:Set[int],
  mailbox:Set[int],oldWork:Set[int],served:Set[int],faults:Set[int],
  roster:Set[int],joined:Set[int],round:Set[int],collective:bool,
  oldRouteLive:bool,endpointLive:bool,rosterReceipt:bool,retired:bool,reused:bool,
  dispatcherLive:bool,globalCustodian:bool,vmCleaned:bool}
 pure val initial:State={gate:true,generation:1,h:[0,0,0],seen:[0,0,0],pins:Set(),
  sourceStopped:false,masks:Set(),maskFailures:Set(),maskUnknown:Set(),
  mailbox:Set(),oldWork:Set(),served:Set(),faults:Set(),
  roster:Roster,joined:Set(),round:Set(),collective:false,
  oldRouteLive:true,endpointLive:true,rosterReceipt:false,retired:false,reused:false,
  dispatcherLive:true,globalCustodian:true,vmCleaned:false}
 var s:State
 action init=s'=initial
 def active=Handlers.filter(i=>s.h[i]==2 or s.h[i]==3)
 def pending=s.oldWork.exclude(s.served)
 def retiringReady=not(s.gate) and s.pins==Set() and pending==Set() and s.faults==Set() and not(s.collective)
 val safe=all{
  s.pins==active,
  s.gate implies (s.oldRouteLive and s.endpointLive),
  s.pins.forall(i=>s.seen[i]==s.generation),
  s.pins.size()>0 implies (s.oldRouteLive and s.endpointLive and s.dispatcherLive),
  s.served.subseteq(s.oldWork),
  s.faults.subseteq(s.oldWork),
  s.mailbox.size()>0 implies s.globalCustodian,
  pending.size()>0 implies (s.oldRouteLive and s.dispatcherLive),
  s.collective implies (s.joined==Roster and s.roster==Roster and s.dispatcherLive),
  s.retired implies (retiringReady and not(s.oldRouteLive) and not(s.endpointLive) and s.rosterReceipt),
  s.reused implies (s.retired and s.generation==2),
  s.vmCleaned implies (s.retired and s.rosterReceipt and pending==Set() and s.pins==Set())
 }
 // Kernel delivery selection is NOT counted as a pin. Stable trampoline remains alive.
 action selectHandler(i)=all{Handlers.contains(i),s.h[i]==0,not(s.masks.contains(Host[i])),s.globalCustodian,
  s'={...s,h:s.h.replaceAt(i,1),seen:s.seen.replaceAt(i,s.generation)}}
 // One tagged atomic gate: admission and reference increment linearize together.
 action pinEntry(i)=all{s.h[i]==1,s.gate,s.seen[i]==s.generation,s.oldRouteLive,
  s'={...s,h:s.h.replaceAt(i,2),pins:s.pins.union(Set(i))}}
 action denyLate(i)=all{s.h[i]==1,(not(s.gate) or s.seen[i]!=s.generation),s.globalCustodian,
  s'={...s,h:s.h.replaceAt(i,5),mailbox:s.mailbox.union(Set(i))}}
 action denyContention(i)=all{s.h[i]==1,s.gate,s.globalCustodian,s'={...s,h:s.h.replaceAt(i,5),mailbox:s.mailbox.union(Set(i))}}
 action publishReason(i)=all{s.h[i]==2,s'={...s,h:s.h.replaceAt(i,3),oldWork:s.oldWork.union(Set(i))}}
 action notificationFailed(i)=all{s.h[i]==3,s'={...s,faults:s.faults.union(Set(i))}}
 // Last old-route/endpoint access precedes pin release. Later code touches stable shell only.
 action leaveHandler(i)=all{s.h[i]==3,s'={...s,h:s.h.replaceAt(i,4),pins:s.pins.exclude(Set(i))}}
 action stopSource=all{s'={...s,sourceStopped:true}}
 action revoke=all{s.gate,s'={...s,gate:false}}
 // Cooperative current-thread call; cannot be mistaken for controlling another thread.
 action maskThread(t)=all{Threads.contains(t),not(Handlers.exists(i=>Host[i]==t and Set(1,2,3).contains(s.h[i]))),
  s'={...s,masks:s.masks.union(Set(t)),maskFailures:s.maskFailures.exclude(Set(t)),maskUnknown:s.maskUnknown.exclude(Set(t))}}
 action maskFailed(t)=all{Threads.contains(t),s'={...s,maskFailures:s.maskFailures.union(Set(t))}}
 action maskResultUnknown(t)=all{Threads.contains(t),s'={...s,maskUnknown:s.maskUnknown.union(Set(t))}}
 action restoreMask(t)=all{s.masks.contains(t),s'={...s,masks:s.masks.exclude(Set(t))}}
 // Unknown mask result is never inserted into the successful acknowledgement set.
 action acceptMailboxForOld(i)=all{s.mailbox.contains(i),s.oldRouteLive,not(s.retired),s.dispatcherLive,
  s'={...s,mailbox:s.mailbox.exclude(Set(i)),oldWork:s.oldWork.union(Set(i)),rosterReceipt:false}}
 action settleProcessMailbox(i)=all{s.mailbox.contains(i),s.globalCustodian,s'={...s,mailbox:s.mailbox.exclude(Set(i))}}
 action startRound=all{pending.size()>0,not(s.collective),s.dispatcherLive,s'={...s,round:pending,joined:Set()}}
 action join(w)=all{s.round.size()>0,Roster.contains(w),s.roster.contains(w),not(s.collective),s'={...s,joined:s.joined.union(Set(w))}}
 action enterCollective=all{s.round.size()>0,s.joined==Roster,s.roster==Roster,s'={...s,collective:true}}
 // Includes inherited selected-result/reset/NOOP completion as a premise.
 action returnRound=all{s.collective,s'={...s,collective:false,served:s.served.union(s.round),round:Set(),joined:Set()}}
 action settleNotification(i)=all{s.faults.contains(i),s.served.contains(i),s'={...s,faults:s.faults.exclude(Set(i))}}
 action acceptRosterReceipt=all{retiringReady,s.dispatcherLive,s'={...s,rosterReceipt:true}}
 action retireRoute=all{retiringReady,s.rosterReceipt,s'={...s,oldRouteLive:false,endpointLive:false,retired:true}}
 action reuseGeneration=all{s.retired,not(s.reused),s'={...s,generation:2,reused:true}}
 action cleanupVm=all{s.retired,retiringReady,s.rosterReceipt,s'={...s,vmCleaned:true,dispatcherLive:false,roster:Set(0)}}
 action step=any{selectHandler(0),selectHandler(1),selectHandler(2),pinEntry(0),pinEntry(1),pinEntry(2),denyLate(0),denyLate(1),denyLate(2),denyContention(0),denyContention(1),denyContention(2),publishReason(0),publishReason(1),publishReason(2),notificationFailed(0),notificationFailed(1),notificationFailed(2),leaveHandler(0),leaveHandler(1),leaveHandler(2),stopSource,revoke,maskThread(0),maskThread(1),maskFailed(0),maskFailed(1),maskResultUnknown(0),maskResultUnknown(1),restoreMask(0),restoreMask(1),acceptMailboxForOld(0),acceptMailboxForOld(1),acceptMailboxForOld(2),settleProcessMailbox(0),settleProcessMailbox(1),settleProcessMailbox(2),startRound,join(0),join(1),enterCollective,returnRound,settleNotification(0),settleNotification(1),settleNotification(2),acceptRosterReceipt,retireRoute,reuseGeneration,cleanupVm,all{s'=s}}
 action service=startRound.then(join(0)).then(join(1)).then(enterCollective).then(returnRound)
 run latePreCasTest=init.then(selectHandler(0)).then(revoke).then(acceptRosterReceipt).then(retireRoute).then(denyLate(0)).then(all{assert(safe and s.mailbox==Set(0) and s.pins==Set()),s'=s})
 run inFlightDrainTest=init.then(selectHandler(1)).then(pinEntry(1)).then(revoke).then(publishReason(1)).then(leaveHandler(1)).then(service).then(acceptRosterReceipt).then(retireRoute).then(all{assert(safe and s.retired),s'=s})
 run nestedHandlersTest=init.then(selectHandler(0)).then(pinEntry(0)).then(selectHandler(2)).then(pinEntry(2)).then(revoke).then(publishReason(2)).then(leaveHandler(2)).then(publishReason(0)).then(leaveHandler(0)).then(service).then(all{assert(safe and s.served==Set(0,2)),s'=s})
 run maskOneThreadTest=init.then(maskThread(0)).then(selectHandler(1)).then(pinEntry(1)).then(all{assert(safe and s.pins==Set(1)),s'=s})
 run stoppedSourceLateDeliveryTest=init.then(selectHandler(1)).then(stopSource).then(pinEntry(1)).then(all{assert(safe and s.sourceStopped and s.pins==Set(1)),s'=s})
 run maskFailureDoesNotBlockAtomicRetirementTest=init.then(maskFailed(1)).then(revoke).then(acceptRosterReceipt).then(retireRoute).then(selectHandler(1)).then(denyLate(1)).then(all{assert(safe and s.mailbox==Set(1)),s'=s})
 run unknownMaskNotAckTest=init.then(maskResultUnknown(1)).then(all{assert(safe and not(s.masks.contains(1)) and s.maskUnknown.contains(1)),s'=s})
 run unknownNotificationTest=init.then(selectHandler(1)).then(pinEntry(1)).then(publishReason(1)).then(notificationFailed(1)).then(leaveHandler(1)).then(revoke).then(service).then(settleNotification(1)).then(acceptRosterReceipt).then(retireRoute).then(all{assert(safe and s.retired),s'=s})
 run delayedGenerationCasTest=init.then(selectHandler(0)).then(revoke).then(acceptRosterReceipt).then(retireRoute).then(reuseGeneration).then(denyLate(0)).then(all{assert(safe and s.seen[0]==1 and s.generation==2),s'=s})
 run newDeliveryAfterVmCleanupTest=init.then(revoke).then(acceptRosterReceipt).then(retireRoute).then(cleanupVm).then(selectHandler(1)).then(denyLate(1)).then(all{assert(safe and s.globalCustodian and s.mailbox==Set(1)),s'=s})
 run mailboxCanRejoinOldWorkTest=init.then(revoke).then(selectHandler(0)).then(denyLate(0)).then(acceptMailboxForOld(0)).then(service).then(all{assert(safe and s.served==Set(0)),s'=s})
 run lateRequestDuringRoundTest=init.then(selectHandler(0)).then(pinEntry(0)).then(publishReason(0)).then(leaveHandler(0)).then(startRound).then(join(0)).then(join(1)).then(enterCollective).then(selectHandler(1)).then(pinEntry(1)).then(publishReason(1)).then(leaveHandler(1)).then(returnRound).then(service).then(all{assert(safe and s.served==Set(0,1)),s'=s})
 run counterOnlyRetirementControlTest=init.then(selectHandler(0)).then(all{s'={...s,retired:true,oldRouteLive:false,endpointLive:false,rosterReceipt:true}}).then(all{assert(not(safe)),s'=s})
 run countedHandlerFreeControlTest=init.then(selectHandler(1)).then(pinEntry(1)).then(revoke).then(all{s'={...s,oldRouteLive:false}}).then(all{assert(not(safe)),s'=s})
 run lostPinControlTest=init.then(selectHandler(0)).then(pinEntry(0)).then(all{s'={...s,pins:Set()}}).then(all{assert(not(safe)),s'=s})
 run generationReuseControlTest=init.then(selectHandler(0)).then(pinEntry(0)).then(all{s'={...s,generation:2}}).then(all{assert(not(safe)),s'=s})
 run droppedMailboxCustodianControlTest=init.then(revoke).then(selectHandler(1)).then(denyLate(1)).then(all{s'={...s,globalCustodian:false}}).then(all{assert(not(safe)),s'=s})
 run pendingWorkFreeControlTest=init.then(selectHandler(0)).then(pinEntry(0)).then(publishReason(0)).then(leaveHandler(0)).then(all{s'={...s,dispatcherLive:false}}).then(all{assert(not(safe)),s'=s})
 run lostOldRosterControlTest=init.then(selectHandler(0)).then(pinEntry(0)).then(publishReason(0)).then(leaveHandler(0)).then(startRound).then(join(0)).then(join(1)).then(enterCollective).then(all{s'={...s,roster:Set(0)}}).then(all{assert(not(safe)),s'=s})
 run ignoredFaultControlTest=init.then(selectHandler(0)).then(pinEntry(0)).then(publishReason(0)).then(notificationFailed(0)).then(leaveHandler(0)).then(revoke).then(service).then(all{s'={...s,retired:true,oldRouteLive:false,endpointLive:false,rosterReceipt:true}}).then(all{assert(not(safe)),s'=s})
 run contentionFallsBackTest=init.then(selectHandler(0)).then(denyContention(0)).then(acceptMailboxForOld(0)).then(service).then(all{assert(safe and s.served==Set(0)),s'=s})
 run lateCountAfterCloseControlTest=init.then(selectHandler(0)).then(revoke).then(acceptRosterReceipt).then(retireRoute).then(all{s'={...s,h:[2,0,0],pins:Set(0)}}).then(all{assert(not(safe)),s'=s})
}
