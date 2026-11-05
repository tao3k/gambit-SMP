module gate_empty_root_materialization {
 pure val P=Set(0,1)
 pure val C=Set(0,1,2)
 // Each action names one proposed C atomic event or one no-checkpoint root step.
 // Gate open/count fields are compared and modified as ONE atomic word.
 // Release-frontier sets are ghost read-from/synchronization premises, not native data.
 type State={po:bool,pc:int,co:bool,cc:int,ps:List[int],cs:List[int],
  snapP:List[bool],seenPo:List[bool],seenPc:List[int],snapC:List[bool],seenCo:List[bool],seenCc:List[int],
  accepted:Set[int],pending:Set[int],batch:List[Set[int]],done:Set[int],
  pf:Set[int],cf:Set[int],pSeen:Set[int],cSeen:Set[int],pq:bool,cq:bool,
  local:List[int],slot:List[int],carrier:List[int],loc:int,final:bool}
 pure val initial:State={po:true,pc:0,co:true,cc:0,ps:[0,0],cs:[0,0,0],
  snapP:[false,false],seenPo:[false,false],seenPc:[0,0],snapC:[false,false],seenCo:[false,false],seenCc:[0,0],
  accepted:Set(),pending:Set(),batch:[Set(),Set(),Set()],done:Set(),
  pf:Set(),cf:Set(),pSeen:Set(),cSeen:Set(),pq:false,cq:false,
  local:[0,0,0],slot:[0,0,0],carrier:[1,1,1],loc:0,final:false}
 var s:State
 action init=s'=initial
 def pOwners=P.filter(i=>s.ps[i]>=1 and s.ps[i]<=3)
 def cOwners=P.filter(i=>s.cs[i]>=1 and s.cs[i]<=7)
 def active=C.filter(i=>s.cs[i]>=1 and s.cs[i]<=7)
 def flight=s.batch[0].union(s.batch[1]).union(s.batch[2])
 def emptyEligible=s.pq and s.cq and s.pending==Set() and active==Set()
 val safe=all{
  s.pc==pOwners.size(),s.cc==cOwners.size(),
  s.accepted.subseteq(P.filter(i=>s.ps[i]==1).union(s.pending).union(flight).union(s.done)),
  s.pending.intersect(flight)==Set(),
  s.pq implies (not(s.po) and s.pc==0 and s.accepted.subseteq(s.pSeen)),
  not(s.co) implies s.pq,
  s.cq implies (not(s.co) and s.cc==0 and P.filter(i=>s.cs[i]==8).subseteq(s.cSeen)),
  C.forall(i=>s.cs[i]>=4 and s.cs[i]<=6 implies s.slot[i]==1+s.loc),
  s.final implies (emptyEligible and s.accepted==s.done)
 }
 action snapshotP(i)=all{s.ps[i]==0,not(s.snapP[i]),s'={...s,snapP:s.snapP.replaceAt(i,true),seenPo:s.seenPo.replaceAt(i,s.po),seenPc:s.seenPc.replaceAt(i,s.pc)}}
 action casP(i)=all{s.ps[i]==0,s.snapP[i],s.seenPo[i],s.seenPc[i]<2,s.po==s.seenPo[i],s.pc==s.seenPc[i],
  s'={...s,pc:s.pc+1,ps:s.ps.replaceAt(i,1),accepted:s.accepted.union(Set(i))}}
 action rejectP(i)=all{s.ps[i]==0,s.snapP[i],not(s.seenPo[i]) or s.seenPc[i]>=2 or s.po!=s.seenPo[i] or s.pc!=s.seenPc[i],s'={...s,ps:s.ps.replaceAt(i,-1)}}
 action pendingOr(i)=all{s.ps[i]==1,s'={...s,ps:s.ps.replaceAt(i,2),pending:s.pending.union(Set(i))}}
 action wakeOr(i)=all{s.ps[i]==2,s'={...s,ps:s.ps.replaceAt(i,3)}}
 action decrementP(i)=all{s.ps[i]==3,s.pc>0,s'={...s,ps:s.ps.replaceAt(i,4),pc:s.pc-1,pf:s.pf.union(Set(i))}}
 action closeP=all{s.po,s'={...s,po:false}}
 // Qualifying acquire reads a CLOSED zero word, not any historical/open zero.
 action observePZero=all{not(s.po),s.pc==0,s'={...s,pq:true,pSeen:s.pf}}
 action snapshotC(i)=all{s.cs[i]==0,not(s.snapC[i]),s'={...s,snapC:s.snapC.replaceAt(i,true),seenCo:s.seenCo.replaceAt(i,s.co),seenCc:s.seenCc.replaceAt(i,s.cc)}}
 action reserveC(i)=all{s.cs[i]==0,s.snapC[i],s.seenCo[i],s.seenCc[i]<2,s.co==s.seenCo[i],s.cc==s.seenCc[i],s'={...s,cc:s.cc+1,cs:s.cs.replaceAt(i,1)}}
 action exchangePending(i)=all{s.cs[i]==1,s'={...s,cs:s.cs.replaceAt(i,if(s.pending==Set())7 else 2),batch:s.batch.replaceAt(i,s.pending),pending:Set()}}
 action closeC=all{s.pq,s.co,s'={...s,co:false}}
 action observeCZero=all{not(s.co),s.cc==0,s'={...s,cq:true,cSeen:s.cf}}
 action coordinatorReserve=all{s.pq,s.cq,active==Set(),s.pending.size()>0,s.cs[2]==0,s'={...s,cs:s.cs.replaceAt(2,1)}}
 action loadR1(i)=all{s.cs[i]==2,s'={...s,cs:s.cs.replaceAt(i,3),local:s.local.replaceAt(i,1+s.loc),carrier:s.carrier.replaceAt(i,1)}}
 action moveSelf(i)=all{s.cs[i]==3,s.carrier[i]==1,s'={...s,carrier:s.carrier.replaceAt(i,4)}}
 // Spill stands for the live carrier's W_Rn/registered slot before a safepoint.
 action spill(i)=all{s.cs[i]==3,Set(1,4).contains(s.carrier[i]),s'={...s,cs:s.cs.replaceAt(i,4),slot:s.slot.replaceAt(i,s.local[i])}}
 action collect=all{not(C.exists(i=>s.cs[i]==3)),
  s'={...s,loc:10-s.loc,slot:[if(s.cs[0]>=4 and s.cs[0]<=6)11-s.loc else s.slot[0],if(s.cs[1]>=4 and s.cs[1]<=6)11-s.loc else s.slot[1],if(s.cs[2]>=4 and s.cs[2]<=6)11-s.loc else s.slot[2]]}}
 action reload(i)=all{s.cs[i]==4 or s.cs[i]==5,s'={...s,cs:s.cs.replaceAt(i,5),local:s.local.replaceAt(i,s.slot[i])}}
 action complete(i)=all{s.cs[i]==5,s.local[i]==s.slot[i],s'={...s,cs:s.cs.replaceAt(i,6),done:s.done.union(s.batch[i]),batch:s.batch.replaceAt(i,Set())}}
 // Retirement of all restoration/capture roots is a SOURCE premise for this step.
 action retireRoot(i)=all{s.cs[i]==6,s'={...s,cs:s.cs.replaceAt(i,7),slot:s.slot.replaceAt(i,0),local:s.local.replaceAt(i,0)}}
 action decrementC(i)=all{P.contains(i),s.cs[i]==7,s.cc>0,s'={...s,cs:s.cs.replaceAt(i,8),cc:s.cc-1,cf:s.cf.union(Set(i))}}
 action releaseCoordinator=all{s.cs[2]==7,s'={...s,cs:s.cs.replaceAt(2,8)}}
 action issueEmpty=all{emptyEligible,s'={...s,final:true}}
 action step=any{snapshotP(0),snapshotP(1),casP(0),casP(1),rejectP(0),rejectP(1),pendingOr(0),pendingOr(1),wakeOr(0),wakeOr(1),decrementP(0),decrementP(1),closeP,observePZero,snapshotC(0),snapshotC(1),reserveC(0),reserveC(1),exchangePending(0),exchangePending(1),exchangePending(2),closeC,observeCZero,coordinatorReserve,loadR1(0),loadR1(1),loadR1(2),moveSelf(0),moveSelf(1),moveSelf(2),spill(0),spill(1),spill(2),collect,reload(0),reload(1),reload(2),complete(0),complete(1),complete(2),retireRoot(0),retireRoot(1),retireRoot(2),decrementC(0),decrementC(1),releaseCoordinator,issueEmpty,all{s'=s}}
 action enterP(i)=snapshotP(i).then(casP(i))
 action publishLeave(i)=pendingOr(i).then(wakeOr(i)).then(decrementP(i))
 action enterC(i)=snapshotC(i).then(reserveC(i))
 action runClaim(i)=exchangePending(i).then(loadR1(i)).then(moveSelf(i)).then(spill(i)).then(collect).then(reload(i)).then(complete(i)).then(retireRoot(i))
 run lastDecrementFrontierTest=init.then(enterP(0)).then(publishLeave(0)).then(enterP(1)).then(closeP).then(publishLeave(1)).then(observePZero).then(all{assert(safe and s.pSeen==Set(0,1)),s'=s})
 run snapshotBeforeCloseRejectedTest=init.then(snapshotP(0)).then(closeP).then(rejectP(0)).then(observePZero).then(all{assert(safe and s.accepted==Set()),s'=s})
 run reservedBeforeCloseTest=init.then(enterC(0)).then(closeP).then(observePZero).then(closeC).then(exchangePending(0)).then(decrementC(0)).then(observeCZero).then(issueEmpty).then(all{assert(safe and s.final),s'=s})
 run coordinatorDrainsResidualTest=init.then(enterP(0)).then(publishLeave(0)).then(closeP).then(observePZero).then(closeC).then(observeCZero).then(coordinatorReserve).then(runClaim(2)).then(releaseCoordinator).then(issueEmpty).then(all{assert(safe and s.done==Set(0)),s'=s})
 run claimBeforeProducerExitTest=init.then(enterP(0)).then(pendingOr(0)).then(enterC(0)).then(exchangePending(0)).then(wakeOr(0)).then(decrementP(0)).then(all{assert(safe and s.batch[0]==Set(0)),s'=s})
 run materializeReloadTest=init.then(enterP(0)).then(publishLeave(0)).then(enterC(0)).then(runClaim(0)).then(decrementC(0)).then(all{assert(safe and s.done==Set(0) and s.slot[0]==0),s'=s})
 run postClaimPublishRetainedTest=init.then(enterP(0)).then(publishLeave(0)).then(enterC(0)).then(exchangePending(0)).then(enterP(1)).then(publishLeave(1)).then(all{assert(safe and s.pending==Set(1) and s.batch[0]==Set(0)),s'=s})
 run countAbaSameIncarnationTest=init.then(snapshotP(0)).then(enterP(1)).then(publishLeave(1)).then(casP(0)).then(publishLeave(0)).then(closeP).then(observePZero).then(all{assert(safe and s.pSeen==Set(0,1)),s'=s})
 run twoClaimersExitFrontierTest=init.then(enterC(0)).then(enterC(1)).then(closeP).then(observePZero).then(closeC).then(exchangePending(0)).then(decrementC(0)).then(exchangePending(1)).then(decrementC(1)).then(observeCZero).then(issueEmpty).then(all{assert(safe and s.cSeen==Set(0,1)),s'=s})
 run openZeroReceiptControlTest=init.then(all{s'={...s,pq:true}}).then(all{assert(not(safe)),s'=s})
 run lastExitOnlyFrontierControlTest=init.then(enterP(0)).then(publishLeave(0)).then(enterP(1)).then(publishLeave(1)).then(closeP).then(all{s'={...s,pf:Set(1)}}).then(observePZero).then(all{assert(not(safe)),s'=s})
 run earlyProducerExitControlTest=init.then(enterP(0)).then(all{s'={...s,pc:0,ps:[4,0]}}).then(closeP).then(observePZero).then(all{assert(not(safe)),s'=s})
 run clearBeforeReservationControlTest=init.then(enterP(0)).then(publishLeave(0)).then(all{s'={...s,pending:Set()}}).then(all{assert(not(safe)),s'=s})
 run activeClaimFinalControlTest=init.then(enterC(0)).then(closeP).then(observePZero).then(closeC).then(all{s'={...s,final:true}}).then(all{assert(not(safe)),s'=s})
 run unspilledRootControlTest=init.then(enterP(0)).then(publishLeave(0)).then(enterC(0)).then(exchangePending(0)).then(loadR1(0)).then(all{s'={...s,cs:[4,0,0]}}).then(all{assert(not(safe)),s'=s})
 run staleR1UseControlTest=init.then(enterP(0)).then(publishLeave(0)).then(enterC(0)).then(exchangePending(0)).then(loadR1(0)).then(spill(0)).then(collect).then(all{assert(safe and s.local[0]!=s.slot[0]),s'=s})
 run pendingEmptyBeforeConsumerDrainControlTest=init.then(enterP(0)).then(publishLeave(0)).then(enterC(0)).then(exchangePending(0)).then(all{s'={...s,final:true}}).then(all{assert(not(safe)),s'=s})
}
