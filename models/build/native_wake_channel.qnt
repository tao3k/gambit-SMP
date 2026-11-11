module native_wake_channel {
 pure val Producers=Set(0,1)
 pure val Roster=Set(0,1)
 // producer: 0 absent, 1 pinned, 2 published, 3 observed success/full,
 // 4 EINTR retry-owned, 5 unknown/hard failure rescue-owned, 6 pin retired, 7 rejected.
 // wait: 0 idle, 1 armed, 2 blocked, 3 returned/recheck, 4 collective, 5 loop return.
 // life: 0 OPEN, 1 CLOSING, 2 CLOSED, 3 close outcome unknown/quarantined.
 type State={life:int,generation:int,handles:List[int],state:List[int],pins:Set[int],
  accepted:Set[int],served:Set[int],token:bool,wait:int,waitPin:bool,roots:bool,
  fallback:bool,deadline:int,joined:Set[int],returned:Set[int],round:Set[int],roster:Set[int],
  signalQuiesced:bool,signalIngress:bool,signalActive:bool,rosterReceipt:bool,readOpen:bool,writeOpen:bool,
  exited:bool,facilities:bool,reused:bool,closeDebt:bool}
 pure val initial:State={life:0,generation:1,handles:[1,1],state:[0,0],pins:Set(),
  accepted:Set(),served:Set(),token:false,wait:0,waitPin:false,roots:true,
  fallback:true,deadline:2,joined:Set(),returned:Set(),round:Set(),roster:Roster,
  signalQuiesced:false,signalIngress:true,signalActive:false,rosterReceipt:false,readOpen:true,writeOpen:true,
  exited:false,facilities:true,reused:false,closeDebt:false}
 var s:State
 action init=s'=initial
 def pending=s.accepted.exclude(s.served)
 def outstanding=Producers.filter(i=>s.state[i]>=1 and s.state[i]<=5)
 def owed=Producers.filter(i=>Set(2,4,5).contains(s.state[i]))
 def quiet=pending.size()==0 and outstanding.size()==0 and s.wait==0 and not(s.waitPin) and not(s.signalActive)
 val safe=all{
  s.served.subseteq(s.accepted),
  s.pins==outstanding,
  s.pins.forall(i=>s.handles[i]==s.generation),
  (s.wait>0 or s.pins.size()>0 or s.signalActive) implies (s.readOpen and s.writeOpen and s.roots and s.facilities),
  s.wait>0 implies s.waitPin,
  (s.wait==2 and pending.size()>0) implies (s.token or owed.size()>0 or s.fallback),
  s.wait==4 implies (s.roster==Roster and s.joined==Roster and s.roots),
  (s.life==2 or s.life==3) implies (quiet and s.signalQuiesced and s.rosterReceipt),
  s.exited implies (s.life==2 and quiet and s.rosterReceipt),
  s.reused implies (s.life==2 and s.pins.size()==0 and not(s.waitPin)),
  s.closeDebt implies s.life==3,
  s.signalQuiesced implies (not(s.signalIngress) and not(s.signalActive))
 }
 action acquire(i)=all{Producers.contains(i),s.state[i]==0,s.life==0,s.handles[i]==s.generation,
  s'={...s,state:s.state.replaceAt(i,1),pins:s.pins.union(Set(i))}}
 action reject(i)=all{Producers.contains(i),s.state[i]==0,(s.life!=0 or s.handles[i]!=s.generation),s'={...s,state:s.state.replaceAt(i,7)}}
 action publish(i)=all{s.state[i]==1,s'={...s,state:s.state.replaceAt(i,2),accepted:s.accepted.union(Set(i))}}
 action cancelUnpublished(i)=all{s.state[i]==1,s'={...s,state:s.state.replaceAt(i,6),pins:s.pins.exclude(Set(i))}}
 // One byte; full pipe represented as one level token, never as request count.
 action writeSuccess(i)=all{s.state[i]==2,s.readOpen,s.writeOpen,s'={...s,state:s.state.replaceAt(i,3),token:true}}
 action writeFull(i)=all{s.state[i]==2,s.token,s.readOpen,s.writeOpen,s'={...s,state:s.state.replaceAt(i,3)}}
 action writeEintr(i)=all{s.state[i]==2,s'={...s,state:s.state.replaceAt(i,4)}}
 action retry(i)=all{s.state[i]==4,s.pins.contains(i),s'={...s,state:s.state.replaceAt(i,2)}}
 action writeHard(i)=all{s.state[i]==2,s'={...s,state:s.state.replaceAt(i,5)}}
 // A lost syscall observation may or may not have deposited a token.
 action writeUnknownToken(i)=all{s.state[i]==2,s'={...s,state:s.state.replaceAt(i,5),token:true}}
 action retireSender(i)=all{s.state[i]==3,s'={...s,state:s.state.replaceAt(i,6),pins:s.pins.exclude(Set(i))}}
 // Rescue can release pin only after owner has observed/served this request.
 action settleRescue(i)=all{s.state[i]==5,s.served.contains(i),s'={...s,state:s.state.replaceAt(i,6),pins:s.pins.exclude(Set(i))}}
 action settleRetry(i)=all{s.state[i]==4,s.served.contains(i),s'={...s,state:s.state.replaceAt(i,6),pins:s.pins.exclude(Set(i))}}
 action arm=all{s.life==0,s.wait==0,s.readOpen,s.writeOpen,s'={...s,wait:1,waitPin:true,deadline:2}}
 action block=all{s.wait==1,pending.size()==0,not(s.token),s.life==0,s'={...s,wait:2}}
 action recheck=all{s.wait==1,(pending.size()>0 or s.token or s.life!=0),s'={...s,wait:3}}
 action wakeToken=all{s.wait==2,s.token,s'={...s,wait:3}}
 // Conditional progress premise: a qualified finite native wait returns under OS/scheduler fairness.
 action tick=all{s.wait==2,s.fallback,s.deadline>0,s'={...s,deadline:s.deadline-1}}
 action fallbackReturn=all{s.wait==2,s.fallback,s.deadline==0,s'={...s,wait:3}}
 action drain=all{s.wait==3,s'={...s,token:false}}
 // Owner cannot sleep directly after drain: it must inspect durable pending set.
 action dispatch=all{s.wait==3,pending.size()>0,s'={...s,round:pending,joined:Set(),returned:Set()}}
 action join(w)=all{s.wait==3,s.round.size()>0,Roster.contains(w),s'={...s,joined:s.joined.union(Set(w))}}
 action enterCollective=all{s.wait==3,s.round.size()>0,s.joined==Roster,s'={...s,wait:4}}
 action returnMember(w)=all{s.wait==4,Roster.contains(w),s'={...s,returned:s.returned.union(Set(w))}}
 action returnLoop=all{s.wait==4,s.returned==Roster,s'={...s,wait:5,served:s.served.union(s.round),round:Set()}}
 action recheckAfterLoop=all{s.wait==5,s'={...s,wait:3,joined:Set(),returned:Set()}}
 action releaseWait=all{s.wait==3,pending.size()==0,s'={...s,wait:0,waitPin:false,token:false}}
 // Closing withdraws public admission, not already pinned producers or old roster service.
 action startClose=all{s.life==0,s'={...s,life:1}}
 // Lifetime-prepinned signal lane: producer-gate withdrawal is an external platform premise.
 action beginSignal=all{s.signalIngress,not(s.signalActive),not(s.accepted.contains(2)),s.readOpen,s.writeOpen,s'={...s,signalActive:true,accepted:s.accepted.union(Set(2))}}
 action signalNotify=all{s.signalActive,s'={...s,token:true}}
 action endSignal=all{s.signalActive,s'={...s,signalActive:false}}
 action stopSignalIngress=all{s.life==1,s'={...s,signalIngress:false}}
 action quiesceSignals=all{s.life==1,not(s.signalIngress),not(s.signalActive),s'={...s,signalQuiesced:true}}
 // Explicit inherited topology/guard receipt; not inferred from byte drain.
 action acceptRosterReceipt=all{s.life==1,quiet,s.signalQuiesced,s'={...s,rosterReceipt:true}}
 action closeEndpoints=all{s.life==1,quiet,s.signalQuiesced,s.rosterReceipt,s'={...s,life:2,readOpen:false,writeOpen:false,token:false}}
 action closeUnknown=all{s.life==1,quiet,s.signalQuiesced,s.rosterReceipt,s'={...s,life:3,closeDebt:true}}
 action resolveClose=all{s.life==3,s.closeDebt,s'={...s,life:2,closeDebt:false,readOpen:false,writeOpen:false}}
 action exitProcessor=all{s.life==2,quiet,s.rosterReceipt,s'={...s,exited:true,roster:Set(0)}}
 action reuseGeneration=all{s.life==2,quiet,s.signalQuiesced,s.rosterReceipt,not(s.reused),s'={...s,generation:s.generation+1,reused:true}}
 action cleanupVm=all{s.exited,s.life==2,quiet,s.signalQuiesced,not(s.closeDebt),s'={...s,roots:false,facilities:false}}
 action step=any{acquire(0),acquire(1),reject(0),reject(1),publish(0),publish(1),cancelUnpublished(0),cancelUnpublished(1),writeSuccess(0),writeSuccess(1),writeFull(0),writeFull(1),writeEintr(0),writeEintr(1),retry(0),retry(1),writeHard(0),writeHard(1),writeUnknownToken(0),writeUnknownToken(1),retireSender(0),retireSender(1),settleRescue(0),settleRescue(1),settleRetry(0),settleRetry(1),arm,block,recheck,wakeToken,tick,fallbackReturn,drain,dispatch,join(0),join(1),enterCollective,returnMember(0),returnMember(1),returnLoop,recheckAfterLoop,releaseWait,startClose,beginSignal,signalNotify,endSignal,stopSignalIngress,quiesceSignals,acceptRosterReceipt,closeEndpoints,closeUnknown,resolveClose,exitProcessor,reuseGeneration,cleanupVm,all{s'=s}}
 action round=dispatch.then(join(0)).then(join(1)).then(enterCollective).then(returnMember(0)).then(returnMember(1)).then(returnLoop).then(recheckAfterLoop)
 run fullPipeTest=init.then(acquire(0)).then(publish(0)).then(writeSuccess(0)).then(acquire(1)).then(publish(1)).then(writeFull(1)).then(arm).then(recheck).then(drain).then(round).then(retireSender(0)).then(retireSender(1)).then(releaseWait).then(all{assert(safe and s.served==Set(0,1)),s'=s})
 run eintrRetryTest=init.then(arm).then(block).then(acquire(0)).then(publish(0)).then(writeEintr(0)).then(retry(0)).then(writeSuccess(0)).then(wakeToken).then(round).then(retireSender(0)).then(releaseWait).then(all{assert(safe and s.accepted==Set(0)),s'=s})
 run hardFailureFallbackTest=init.then(arm).then(block).then(acquire(0)).then(publish(0)).then(writeHard(0)).then(tick).then(tick).then(fallbackReturn).then(round).then(settleRescue(0)).then(releaseWait).then(all{assert(safe and s.pins==Set()),s'=s})
 run fullThenDrainBeforeSenderRetireTest=init.then(acquire(0)).then(publish(0)).then(writeSuccess(0)).then(acquire(1)).then(publish(1)).then(writeFull(1)).then(arm).then(recheck).then(drain).then(retireSender(1)).then(round).then(all{assert(safe and s.served==Set(0,1)),s'=s})
 run requestAfterDrainTest=init.then(acquire(0)).then(publish(0)).then(writeSuccess(0)).then(arm).then(recheck).then(drain).then(acquire(1)).then(publish(1)).then(writeEintr(1)).then(round).then(all{assert(safe and s.served==Set(0,1)),s'=s})
 run requestDuringCollectiveTest=init.then(acquire(0)).then(publish(0)).then(writeSuccess(0)).then(arm).then(recheck).then(dispatch).then(join(0)).then(join(1)).then(enterCollective).then(acquire(1)).then(publish(1)).then(returnMember(0)).then(returnMember(1)).then(returnLoop).then(recheckAfterLoop).then(round).then(all{assert(safe and s.served==Set(0,1)),s'=s})
 run closeWithPinnedWriterTest=init.then(acquire(0)).then(startClose).then(publish(0)).then(writeSuccess(0)).then(all{assert(safe and s.life==1 and s.readOpen and s.pins==Set(0)),s'=s})
 run closeBlockedWaitTest=init.then(arm).then(block).then(startClose).then(tick).then(tick).then(fallbackReturn).then(releaseWait).then(stopSignalIngress).then(quiesceSignals).then(acceptRosterReceipt).then(closeEndpoints).then(exitProcessor).then(cleanupVm).then(all{assert(safe and not(s.facilities)),s'=s})
 run staleHandleTest=init.then(startClose).then(stopSignalIngress).then(quiesceSignals).then(acceptRosterReceipt).then(closeEndpoints).then(reuseGeneration).then(reject(0)).then(all{assert(safe and s.state[0]==7),s'=s})
 run closeUnknownTest=init.then(startClose).then(stopSignalIngress).then(quiesceSignals).then(acceptRosterReceipt).then(closeUnknown).then(all{assert(safe and s.closeDebt and not(s.exited)),s'=s})
 run unknownWriteTest=init.then(acquire(0)).then(publish(0)).then(writeUnknownToken(0)).then(arm).then(recheck).then(round).then(settleRescue(0)).then(releaseWait).then(all{assert(safe and s.pins==Set()),s'=s})
 run pinMissingControlTest=init.then(acquire(0)).then(all{s'={...s,pins:Set()}}).then(all{assert(not(safe)),s'=s})
 run closeWhileWritingControlTest=init.then(acquire(0)).then(all{s'={...s,readOpen:false}}).then(all{assert(not(safe)),s'=s})
 run pinGenerationControlTest=init.then(acquire(0)).then(all{s'={...s,generation:2}}).then(all{assert(not(safe)),s'=s})
 run lostCustodyControlTest=init.then(arm).then(block).then(acquire(0)).then(publish(0)).then(writeEintr(0)).then(all{s'={...s,state:[6,0],pins:Set(),fallback:false}}).then(all{assert(not(safe)),s'=s})
 run droppedFullTokenControlTest=init.then(arm).then(block).then(acquire(0)).then(publish(0)).then(writeSuccess(0)).then(retireSender(0)).then(all{s'={...s,token:false,fallback:false}}).then(all{assert(not(safe)),s'=s})
 run retireWithoutSignalFenceControlTest=init.then(all{s'={...s,life:2,readOpen:false,writeOpen:false}}).then(all{assert(not(safe)),s'=s})
 run lostOldMemberControlTest=init.then(acquire(0)).then(publish(0)).then(writeSuccess(0)).then(arm).then(recheck).then(dispatch).then(join(0)).then(join(1)).then(enterCollective).then(all{s'={...s,roster:Set(0)}}).then(all{assert(not(safe)),s'=s})
 run forgottenCloseUnknownControlTest=init.then(startClose).then(stopSignalIngress).then(quiesceSignals).then(acceptRosterReceipt).then(closeUnknown).then(all{s'={...s,exited:true}}).then(all{assert(not(safe)),s'=s})
 run signalFailureFallbackTest=init.then(arm).then(block).then(beginSignal).then(endSignal).then(tick).then(tick).then(fallbackReturn).then(round).then(releaseWait).then(all{assert(safe and s.served.contains(2)),s'=s})
 run closingSignalInFlightTest=init.then(startClose).then(beginSignal).then(stopSignalIngress).then(signalNotify).then(endSignal).then(all{assert(safe and not(s.signalQuiesced) and pending.contains(2)),s'=s})
 run activeSignalCloseControlTest=init.then(beginSignal).then(all{s'={...s,life:2,signalQuiesced:true}}).then(all{assert(not(safe)),s'=s})
 run signalFenceWithOpenIngressControlTest=init.then(all{s'={...s,signalQuiesced:true}}).then(all{assert(not(safe)),s'=s})
 run infiniteFailedSignalControlTest=init.then(arm).then(block).then(beginSignal).then(endSignal).then(all{s'={...s,fallback:false}}).then(all{assert(not(safe)),s'=s})
}
