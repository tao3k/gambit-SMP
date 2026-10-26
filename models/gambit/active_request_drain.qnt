// Concrete three-node chain and detached cleanup owner. Conditional ABI/GC model.
module active_request_drain {
 val ids=Set(1,2,3)
 type State={bug:int,mode:int,stage:int,head:int,tail:int,links:int->int,
   phases:int->int,runs:int->int,releases:int->int,outcomes:int->int,expected:int->int,removed:Set[int],
   detached:Set[int],privateRoot:bool,terminated:bool,failedA:bool,
   late:bool,capChecked:bool,migrated:bool,gc:int,cachedNext:int,done:bool}
 var s:State
 pure def initial(b:int,m:int):State={bug:b,mode:m,stage:0,head:1,tail:3,
   links:Map(0->0,1->2,2->3,3->0),phases:Map(1->1,2->1,3->1),
   runs:Map(1->0,2->0,3->0),releases:Map(1->0,2->0,3->0),
   outcomes:Map(1->0,2->0,3->0),expected:Map(1->3,2->3,3->3),removed:Set(),
   detached:Set(),privateRoot:false,terminated:false,failedA:false,
   late:false,capChecked:false,migrated:false,gc:0,cachedNext:2,done:false}
 action initGood=s'=initial(0,0)
 action initTerminated=s'=initial(0,1)
 action initCommittedThenTerminated=s'=initial(0,3)
 action initRetained=s'=initial(0,2)
 action initReplay=s'=initial(1,0)
 action initHeadOnly=s'=initial(2,0)
 action initWrongUnlink=s'=initial(3,0)
 action initStaleNext=s'=initial(4,0)
 action initWrongTail=s'=initial(5,0)
 action initTermDouble=s'=initial(6,1)
 action initDropRoot=s'=initial(7,1)
 action initDropRetained=s'=initial(8,2)
 action initPhaseOnlyCapability=s'=initial(9,0)
 action initEarlyUnlink=s'=initial(10,0)
 action initLatePayload=s'=initial(11,1)
 pure def members(x:State):Set[int]=Set(x.head,x.links.get(x.head),
   x.links.get(x.links.get(x.head))).exclude(Set(0))
 pure def unlink(x:State,r:int):State={
   val victim=if(x.bug==3 and r==2) x.head else r
   val after=if(x.bug==4 and r==1) x.cachedNext else x.links.get(victim)
   val pred=if(x.head==victim) 0 else if(x.links.get(1)==victim) 1
     else if(x.links.get(2)==victim) 2 else 3
   val h=if(pred==0) after else x.head
   val nexts=if(pred==0) x.links else x.links.set(pred,after)
   val t=if(x.tail==victim and not(x.bug==5 and r==3)) pred else x.tail
   x.with("head",h).with("tail",t).with("links",nexts.set(victim,0))
     .with("removed",x.removed.union(Set(r)))
 }
 action claimA=all{s.stage==0,
   s'=s.with("stage",1).with("phases",s.phases.set(1,2)).with("runs",s.runs.set(1,1))}
 action yieldMigrate=all{s.stage==1,
   s'=s.with("stage",2).with("gc",1).with("migrated",true)}
 // Captured continuation reentry is not queue dispatch. A phase-only wind guard
 // would allow it; the selected policy rejects it without rerunning the body.
 action checkCapability=all{s.stage==2,not(s.capChecked),
   s'=s.with("capChecked",true).with("runs",s.runs.set(1,
     if(s.bug==9) 2 else s.runs.get(1)))}
 action nestedClaim=all{s.stage==2,s.capChecked,s.bug!=2,
   s'=s.with("stage",3)
     .with("phases",s.phases.set(if(s.bug==1) 1 else 2,2))
     .with("runs",s.runs.set(if(s.bug==1) 1 else 2,
       s.runs.get(if(s.bug==1) 1 else 2)+1))}
 action completeB=all{s.stage==3,(s.mode==0 or s.mode==3),
   s'=s.with("stage",4).with("phases",s.phases.set(2,3))
     .with("releases",s.releases.set(2,1)).with("outcomes",s.outcomes.set(2,42))}
 action unlinkB=all{s.stage==4,(s.mode==0 or s.mode==3),
   s'=unlink(s,2).with("stage",5).with("gc",2)}
 action completeA=all{s.stage==5,
   s'=s.with("stage",6).with("phases",s.phases.set(1,3))
     .with("releases",s.releases.set(1,0)).with("outcomes",s.outcomes.set(1,41))}
 // Terminal A remains linked before its owner unlinks it. Dispatch must still
 // scan to C without resetting A to Active.
 action terminalScan=all{s.stage==6,s.mode!=3,
   s'=s.with("stage",7).with("phases",s.phases.set(3,2)).with("runs",s.runs.set(3,1))}
 action completeC=all{s.stage==7,
   s'=s.with("stage",8).with("phases",s.phases.set(3,3))
     .with("releases",s.releases.set(3,1)).with("outcomes",s.outcomes.set(3,43))}
 action unlinkC=all{s.stage==8,s'=unlink(s,3).with("stage",9)}
 action settleA=all{s.stage==9,s.releases.get(1)==0,s'=s.with("releases",s.releases.set(1,1))}
 action earlyUnlink=all{s.stage==6,s.bug==10,s'=unlink(s,1)}
 action unlinkA=all{s.stage==9,s.releases.get(1)==1,s'=unlink(s,1).with("stage",10).with("done",true)}
 action detachTermination=all{(s.stage==3 and (s.mode==1 or s.mode==2)) or (s.stage==6 and s.mode==3),
   s'=s.with("stage",11).with("terminated",true).with("detached",members(s))
     .with("privateRoot",s.bug!=7).with("head",0).with("tail",0)
     .with("expected",Map(1->(if(s.phases.get(1)==3) 3 else 4),
       2->(if(s.phases.get(2)==3) 3 else 4),3->(if(s.phases.get(3)==3) 3 else 4)))}
 action retainA=all{s.stage==11,s.mode==2,not(s.failedA),s.detached.contains(1),
   s'=s.with("failedA",true).with("phases",s.phases.set(1,5))
     .with("detached",if(s.bug==8) s.detached.exclude(Set(1)) else s.detached)}
 action cleanupOne=all{s.stage==11,
   nondet r=s.detached.filter(i=>not(s.mode==2 and i==1)).oneOf()
   s'=s.with("phases",s.phases.set(r,s.expected.get(r))).with("releases",s.releases.set(r,1))
     .with("outcomes",s.outcomes.set(r,if(s.expected.get(r)==3) s.outcomes.get(r) else -1))
     .with("detached",s.detached.exclude(Set(r))).with("removed",s.removed.union(Set(r)))}
 action lateCompletion=all{s.stage==11,(s.releases.get(1)==1 or s.phases.get(1)==5),not(s.late),
   s'=s.with("late",true).with("phases",if(s.bug==6) s.phases.set(1,3) else s.phases)
     .with("releases",if(s.bug==6) s.releases.set(1,2) else s.releases)
     .with("outcomes",if(s.bug==11) s.outcomes.set(1,41) else s.outcomes)}
 action finishTermination=all{s.stage==11,s.late,
   ((s.mode==1 or s.mode==3) and s.detached==Set()) or
   (s.mode==2 and s.failedA and s.detached==Set(1)),
   s'=s.with("stage",12).with("done",true)}
 action idle=s'=s
 action step=any{claimA,yieldMigrate,checkCapability,nestedClaim,completeB,unlinkB,
   completeA,terminalScan,completeC,unlinkC,settleA,earlyUnlink,unlinkA,detachTermination,retainA,
   cleanupOne,lateCompletion,finishTermination,idle}
 val shape=all{
   s.links.get(s.links.get(s.links.get(s.head)))==0,
   s.tail==(if(s.links.get(s.links.get(s.head))!=0) s.links.get(s.links.get(s.head))
     else if(s.links.get(s.head)!=0) s.links.get(s.head) else s.head),
   s.removed.intersect(members(s))==Set()}
 val safe=shape and ids.forall(i=>all{s.runs.get(i)<=1,s.releases.get(i)<=1,
   s.releases.get(i)==0 implies
      ((members(s).contains(i) or s.detached.contains(i)) and s.releases.get(i)==0),
   s.detached.contains(i) implies s.privateRoot,
   (s.terminated and s.releases.get(i)==1) implies
     (s.phases.get(i)==s.expected.get(i) and
       s.outcomes.get(i)==(if(s.expected.get(i)==3) 40+i else -1))})
 temporal progress=(weakFair(claimA,Set(s)) and weakFair(yieldMigrate,Set(s)) and
   weakFair(checkCapability,Set(s)) and weakFair(nestedClaim,Set(s)) and
   weakFair(completeB,Set(s)) and weakFair(unlinkB,Set(s)) and
   weakFair(completeA,Set(s)) and weakFair(terminalScan,Set(s)) and
   weakFair(completeC,Set(s)) and weakFair(unlinkC,Set(s)) and weakFair(settleA,Set(s)) and weakFair(unlinkA,Set(s)) and
   weakFair(detachTermination,Set(s)) and weakFair(retainA,Set(s)) and
   weakFair(cleanupOne,Set(s)) and weakFair(lateCompletion,Set(s)) and
   weakFair(finishTermination,Set(s))).implies(eventually(s.done))
}
