module signal_gate_mailbox {
 pure val H=Set(0,1,2)
 pure val Roster=Set(0,1)
 pure val Capacity=1
 pure val GenerationMax=2
 // h: 0 before snapshot,1 coherent snapshot,2 pinned,3 published,last old access,4 left,5 mailbox.
 // code: 1 acquired,2 CAS mismatch,3 closed snapshot,4 saturated snapshot,5 stale generation.
 type State={enabled:bool,gen:int,count:int,sealed:bool,h:List[int],
  seenGen:List[int],seenCount:List[int],seenOpen:List[bool],code:List[int],pins:Set[int],pinGen:List[int],
  mailbox:Set[int],flight:Set[int],completed:Set[int],denied:Set[int],nativeOnly:bool,processCustodian:bool,
  decision:int,decisionKnown:bool,bindingReceipts:Set[int],work:Set[int],boundGen:List[int],served:Set[int],
  vmLive:Set[int],retired:Set[int],retireReceipts:Set[int],
  round:Set[int],roundVm:int,joined:Set[int],collective:bool,roster:Set[int]}
 pure val initial:State={enabled:true,gen:1,count:0,sealed:false,h:[0,0,0],
  seenGen:[0,0,0],seenCount:[0,0,0],seenOpen:[false,false,false],code:[0,0,0],pins:Set(),pinGen:[0,0,0],
  mailbox:Set(),flight:Set(),completed:Set(),denied:Set(),nativeOnly:true,processCustodian:true,
  decision:0,decisionKnown:true,bindingReceipts:Set(),work:Set(),boundGen:[0,0,0],served:Set(),
  vmLive:Set(1),retired:Set(),retireReceipts:Set(),
  round:Set(),roundVm:0,joined:Set(),collective:false,roster:Roster}
 var s:State
 action init=s'=initial
 def sameSnapshot(i)=s.seenGen[i]==s.gen and s.seenCount[i]==s.count and s.seenOpen[i]==s.enabled
 def pending(g)=s.work.exclude(s.served).filter(i=>s.boundGen[i]==g)
 def canRetire(g)=not(s.enabled and s.gen==g) and not(s.pins.exists(i=>s.pinGen[i]==g)) and pending(g)==Set() and s.decision!=g and not(s.collective and s.roundVm==g)
 val safe=all{
  s.count==s.pins.size(),s.count>=0,s.count<=Capacity,s.gen>=1,s.gen<=GenerationMax,
  s.pins==H.filter(i=>s.h[i]==2 or s.h[i]==3),
  s.pins.forall(i=>s.pinGen[i]==s.gen and s.vmLive.contains(s.pinGen[i])),
  s.enabled implies (s.vmLive.contains(s.gen) and not(s.sealed)),
  s.denied.subseteq(s.mailbox.union(s.flight).union(s.completed).union(s.work)),
  s.nativeOnly,s.processCustodian,
  s.decision>0 implies (s.flight.size()>0 and s.vmLive.contains(s.decision)),
  s.work.exclude(s.served).forall(i=>s.vmLive.contains(s.boundGen[i])),
  s.vmLive.intersect(s.retired)==Set(),
  s.retired.forall(g=>canRetire(g)),
  s.served.subseteq(s.work),
  s.work.intersect(s.denied).subseteq(s.bindingReceipts),
  s.collective implies (s.vmLive.contains(s.roundVm) and s.joined==Roster and s.roster==Roster)
 }
 action snapshot(i)=all{H.contains(i),s.h[i]==0,s'={...s,h:s.h.replaceAt(i,1),seenGen:s.seenGen.replaceAt(i,s.gen),seenCount:s.seenCount.replaceAt(i,s.count),seenOpen:s.seenOpen.replaceAt(i,s.enabled)}}
 action acquireCas(i)=all{s.h[i]==1,s.seenOpen[i],s.seenCount[i]<Capacity,sameSnapshot(i),
  s'={...s,h:s.h.replaceAt(i,2),code:s.code.replaceAt(i,1),count:s.count+1,pins:s.pins.union(Set(i)),pinGen:s.pinGen.replaceAt(i,s.gen)}}
 action mismatchCas(i)=all{s.h[i]==1,s.seenOpen[i],s.seenCount[i]<Capacity,not(sameSnapshot(i)),
  s'={...s,h:s.h.replaceAt(i,5),code:s.code.replaceAt(i,if(s.seenGen[i]!=s.gen)5 else 2),denied:s.denied.union(Set(i)),mailbox:s.mailbox.union(Set(i))}}
 action closedSnapshot(i)=all{s.h[i]==1,not(s.seenOpen[i]),s'={...s,h:s.h.replaceAt(i,5),code:s.code.replaceAt(i,3),denied:s.denied.union(Set(i)),mailbox:s.mailbox.union(Set(i))}}
 action overflowSnapshot(i)=all{s.h[i]==1,s.seenOpen[i],s.seenCount[i]==Capacity,s'={...s,h:s.h.replaceAt(i,5),code:s.code.replaceAt(i,4),denied:s.denied.union(Set(i)),mailbox:s.mailbox.union(Set(i))}}
 action publishBound(i)=all{s.h[i]==2,s'={...s,h:s.h.replaceAt(i,3),work:s.work.union(Set(i)),boundGen:s.boundGen.replaceAt(i,s.pinGen[i]),retireReceipts:s.retireReceipts.exclude(Set(s.pinGen[i]))}}
 action leave(i)=all{s.h[i]==3,s.count>0,s'={...s,h:s.h.replaceAt(i,4),pins:s.pins.exclude(Set(i)),count:s.count-1}}
 action revoke=all{s.enabled,s'={...s,enabled:false}}
 // One atomic exchange batch. Event identity sets are ghost coverage of one coalescible reason bit.
 action takeMailbox=all{s.flight==Set(),s.mailbox.size()>0,s.decision==0,s'={...s,flight:s.mailbox,mailbox:Set()}}
 action completeProcess=all{s.flight.size()>0,s.decision==0,s'={...s,completed:s.completed.union(s.flight),flight:Set()}}
 // Normal process custodian authorizes this whole equivalent-reason batch under a VM lifecycle lease.
 action authorizeBinding(g)=all{s.flight.size()>0,s.decision==0,s.vmLive.contains(g),s'={...s,decision:g,decisionKnown:true,retireReceipts:s.retireReceipts.exclude(Set(g))}}
 action loseDecisionReply=all{s.decision>0,s'={...s,decisionKnown:false}}
 action queryDecision=all{s.decision>0,s'={...s,decisionKnown:true}}
 action rejectBinding=all{s.decision>0,s.decisionKnown,s'={...s,decision:0}}
 action commitBinding=all{s.decision>0,s.decisionKnown,s.vmLive.contains(s.decision),
  s'={...s,work:s.work.union(s.flight),bindingReceipts:s.bindingReceipts.union(s.flight),boundGen:[if(s.flight.contains(0))s.decision else s.boundGen[0],if(s.flight.contains(1))s.decision else s.boundGen[1],if(s.flight.contains(2))s.decision else s.boundGen[2]],flight:Set(),decision:0}}
 action startRound(g)=all{pending(g).size()>0,s.vmLive.contains(g),not(s.collective),s'={...s,round:pending(g),roundVm:g,joined:Set()}}
 action join(w)=all{s.round.size()>0,Roster.contains(w),not(s.collective),s'={...s,joined:s.joined.union(Set(w))}}
 action enterCollective=all{s.round.size()>0,s.joined==Roster,s.vmLive.contains(s.roundVm),s'={...s,collective:true}}
 action returnRound=all{s.collective,s'={...s,collective:false,served:s.served.union(s.round),round:Set(),joined:Set(),roundVm:0}}
 action issueRetire(g)=all{s.vmLive.contains(g),canRetire(g),s'={...s,retireReceipts:s.retireReceipts.union(Set(g))}}
 action retireVm(g)=all{s.vmLive.contains(g),canRetire(g),s.retireReceipts.contains(g),s'={...s,vmLive:s.vmLive.exclude(Set(g)),retired:s.retired.union(Set(g))}}
 action reopenNext=all{not(s.enabled),s.count==0,s.retired.contains(s.gen),s.gen<GenerationMax,not(s.sealed),s'={...s,gen:s.gen+1,vmLive:s.vmLive.union(Set(s.gen+1)),enabled:true}}
 action sealExhausted=all{not(s.enabled),s.count==0,s.gen==GenerationMax,s'={...s,sealed:true}}
 action step=any{snapshot(0),snapshot(1),snapshot(2),acquireCas(0),acquireCas(1),acquireCas(2),mismatchCas(0),mismatchCas(1),mismatchCas(2),closedSnapshot(0),closedSnapshot(1),closedSnapshot(2),overflowSnapshot(0),overflowSnapshot(1),overflowSnapshot(2),publishBound(0),publishBound(1),publishBound(2),leave(0),leave(1),leave(2),revoke,takeMailbox,completeProcess,authorizeBinding(1),authorizeBinding(2),loseDecisionReply,queryDecision,rejectBinding,commitBinding,startRound(1),startRound(2),join(0),join(1),enterCollective,returnRound,issueRetire(1),issueRetire(2),retireVm(1),retireVm(2),reopenNext,sealExhausted,all{s'=s}}
 action service(g)=startRound(g).then(join(0)).then(join(1)).then(enterCollective).then(returnRound)
 run mismatchDoesNotBindTest=init.then(snapshot(0)).then(snapshot(1)).then(acquireCas(0)).then(mismatchCas(1)).then(all{assert(safe and s.code[1]==2 and s.boundGen[1]==0 and s.mailbox==Set(1)),s'=s})
 run overflowGoesMailboxTest=init.then(snapshot(0)).then(acquireCas(0)).then(snapshot(1)).then(overflowSnapshot(1)).then(all{assert(safe and s.count==1 and s.code[1]==4),s'=s})
 run closedSnapshotTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(all{assert(safe and s.code[0]==3),s'=s})
 run lateGenerationTest=init.then(snapshot(0)).then(revoke).then(issueRetire(1)).then(retireVm(1)).then(reopenNext).then(mismatchCas(0)).then(all{assert(safe and s.code[0]==5 and s.boundGen[0]==0 and s.gen==2),s'=s})
 run afterOldVmRetirementTest=init.then(revoke).then(issueRetire(1)).then(retireVm(1)).then(snapshot(0)).then(closedSnapshot(0)).then(takeMailbox).then(completeProcess).then(all{assert(safe and s.completed==Set(0)),s'=s})
 run publishDuringDrainTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(takeMailbox).then(snapshot(1)).then(closedSnapshot(1)).then(completeProcess).then(all{assert(safe and s.mailbox==Set(1) and s.completed==Set(0)),s'=s}).then(takeMailbox).then(completeProcess).then(all{assert(safe and s.completed==Set(0,1)),s'=s})
 run explicitBindingTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(takeMailbox).then(authorizeBinding(1)).then(commitBinding).then(service(1)).then(issueRetire(1)).then(retireVm(1)).then(all{assert(safe and s.served==Set(0)),s'=s})
 run unknownBindingLeaseTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(takeMailbox).then(authorizeBinding(1)).then(loseDecisionReply).then(all{assert(safe and not(canRetire(1)) and s.decision==1),s'=s}).then(queryDecision).then(rejectBinding).then(completeProcess).then(issueRetire(1)).then(retireVm(1)).then(all{assert(safe),s'=s})
 run gateDrainTest=init.then(snapshot(0)).then(acquireCas(0)).then(revoke).then(publishBound(0)).then(leave(0)).then(service(1)).then(issueRetire(1)).then(retireVm(1)).then(all{assert(safe and s.count==0),s'=s})
 run generationExhaustionTest=init.then(revoke).then(issueRetire(1)).then(retireVm(1)).then(reopenNext).then(revoke).then(issueRetire(2)).then(retireVm(2)).then(sealExhausted).then(all{assert(safe and s.gen==2 and s.sealed),s'=s})
 run overflowWrapControlTest=init.then(snapshot(0)).then(acquireCas(0)).then(all{s'={...s,count:0}}).then(all{assert(not(safe)),s'=s})
 run unpinnedFailureBindControlTest=init.then(snapshot(0)).then(revoke).then(issueRetire(1)).then(retireVm(1)).then(mismatchCas(0)).then(all{s'={...s,work:Set(0),boundGen:[1,0,0]}}).then(all{assert(not(safe)),s'=s})
 run lostMailboxControlTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(all{s'={...s,mailbox:Set()}}).then(all{assert(not(safe)),s'=s})
 run processCustodianFreeControlTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(all{s'={...s,processCustodian:false}}).then(all{assert(not(safe)),s'=s})
 run rawVmPointerMailboxControlTest=init.then(all{s'={...s,nativeOnly:false}}).then(all{assert(not(safe)),s'=s})
 run leaseRetirementControlTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(takeMailbox).then(authorizeBinding(1)).then(all{s'={...s,vmLive:Set(),retired:Set(1)}}).then(all{assert(not(safe)),s'=s})
 run prematureVmFreeControlTest=init.then(snapshot(0)).then(acquireCas(0)).then(all{s'={...s,vmLive:Set(),retired:Set(1)}}).then(all{assert(not(safe)),s'=s})
 run generationWrapControlTest=init.then(all{s'={...s,gen:0}}).then(all{assert(not(safe)),s'=s})
 run overflowSnapshotCanBeConservativeTest=init.then(snapshot(0)).then(acquireCas(0)).then(snapshot(1)).then(publishBound(0)).then(leave(0)).then(overflowSnapshot(1)).then(all{assert(safe and s.count==0 and s.code[1]==4 and s.boundGen[1]==0),s'=s})
 run loadThenClearLostControlTest=init.then(revoke).then(snapshot(0)).then(closedSnapshot(0)).then(takeMailbox).then(snapshot(1)).then(closedSnapshot(1)).then(all{s'={...s,mailbox:Set()}}).then(all{assert(not(safe)),s'=s})
 run automaticNextVmBindingControlTest=init.then(snapshot(0)).then(revoke).then(issueRetire(1)).then(retireVm(1)).then(reopenNext).then(mismatchCas(0)).then(all{s'={...s,mailbox:Set(),work:Set(0),boundGen:[2,0,0]}}).then(all{assert(not(safe)),s'=s})
}
