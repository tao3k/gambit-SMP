module retirement_progress {
  // Cyclic GC requests: no finite bound on the number of collections in a behavior.
  // phase status: 0 reserved, 1 native join, 2 join0, 3 native error,
  //               4 transferred, 5 retained preflight error.
  type State={mode:int,bug:int,violation:int,status:int->int,exited:Set[int],
    calls:int->int,roots:Set[int],destination:Set[int],scan:Set[int],pins:Set[int],
    grace:int->int,gcPending:bool,gcActive:bool,window:bool,gcBeat:bool,
    requestBeat:bool,cursor:int,admitted:bool,refused:bool,vmFreed:bool,
    observed:Set[int],lane:int->int}
  val donors=Set(1,2)
  var s:State
  pure def initial(m:int,b:int):State={mode:m,bug:b,violation:0,
    status:Map(1->0,2->0),exited:Set(),calls:Map(1->0,2->0),roots:donors,
    destination:Set(),scan:donors,pins:if(m==4) Set() else donors,
    grace:Map(1->if(m==3) 1 else 0,2->0),gcPending:true,gcActive:false,
    window:false,gcBeat:false,requestBeat:false,cursor:1,admitted:m!=4,
    refused:m==4,vmFreed:false,observed:Set(),lane:Map(1->1,2->2)}
  action initAllFinish=s'=initial(0,0)
  action initBlockedA=s'=initial(1,0)
  action initJoinErrorB=s'=initial(2,0)
  action initGraceA=s'=initial(3,0)
  action initCapacityRefusal=s'=initial(4,0)
  action initFinalizeErrorA=s'=initial(5,0)
  action initStrictGcPriority=s'=initial(1,1)
  action initSerialReaper=s'=initial(1,2)
  action initGlobalGraceGate=s'=initial(3,3)
  action initUnfairScheduler=s'=initial(1,0)
  action initSharedOwner=s'=initial(1,4)
  action initDropBlockedRoot=s'=initial(1,5)
  action initFreePinnedVm=s'=initial(1,6)
  action initIgnoreScanLease=s'=initial(3,7)
  action initPartialTransferLoss=s'=initial(5,8)
  action join(p:int):bool=all {s.admitted,s.status.get(p)==0,
    not(s.bug==2 and p==2 and s.status.get(1)!=4),
    s'={...s,status:s.status.set(p,1),calls:s.calls.set(p,s.calls.get(p)+1)}}
  action joinA=join(1)
  action joinB=join(2)
  action exitA=all {s.admitted,Set(0,3,5).contains(s.mode),s.status.get(1)==1,
    not(s.exited.contains(1)),s'={...s,exited:s.exited.union(Set(1))}}
  action exitB=all {s.admitted,s.mode!=2,s.status.get(2)==1,
    not(s.exited.contains(2)),s'={...s,exited:s.exited.union(Set(2))}}
  action returnA=all {s.status.get(1)==1,s.exited.contains(1),s'={...s,status:s.status.set(1,2)}}
  action returnB=all {s.status.get(2)==1,s.exited.contains(2),s'={...s,status:s.status.set(2,2)}}
  action errorB=all {s.mode==2,s.status.get(2)==1,s'={...s,status:s.status.set(2,3)}}
  // Environment may request GC infinitely often, including during a service window.
  action requestGc=all {s.admitted,s'={...s,gcPending:true,requestBeat:not(s.requestBeat)}}
  action startGc=all {s.admitted,s.gcPending,not(s.gcActive),not(s.window),
    s'={...s,gcActive:true,gcPending:false}}
  // No return to mutators before the guaranteed post-GC service window.
  action finishGc=all {s.gcActive,
    s'={...s,gcActive:false,window:s.bug!=1,gcPending:if(s.bug==1) true else s.gcPending,
      gcBeat:not(s.gcBeat)}}
  def eligible(p:int):bool=s.status.get(p)==2 and s.grace.get(p)==0 and
    (s.bug!=3 or s.grace.get(1)==0)
  val hasResult=donors.exists(p=>Set(2,3).contains(s.status.get(p)))
  action requestWindow=all {s.admitted,not(s.gcActive),not(s.gcPending),not(s.window),hasResult,
    s'={...s,window:true}}
  // One bounded native batch; scan cursor skips ineligible donors instead of waiting on them.
  action serviceWindow=all {s.window,not(s.gcActive),
    val other=3-s.cursor
    val p=if(eligible(s.cursor)) s.cursor else if(eligible(other)) other else 0
    val preflightBad=p==1 and s.mode==5
    s'={...s,window:false,cursor:other,
      observed:s.observed.union(donors.filter(d=>Set(2,3).contains(s.status.get(d)))),
      status:if(p==0) s.status else s.status.set(p,if(preflightBad) 5 else 4),
      roots:if(p==0 or preflightBad) s.roots else s.roots.exclude(Set(p)),
      scan:if(p==0 or preflightBad) s.scan else s.scan.exclude(Set(p)),
      destination:if(p==0 or preflightBad) s.destination else s.destination.union(Set(p))}}
  action bad=any {
    all {s.bug==4,s.admitted,s'={...s,lane:Map(1->1,2->1),violation:4}},
    all {s.bug==5,s.status.get(1)==1,s'={...s,roots:s.roots.exclude(Set(1)),violation:5}},
    all {s.bug==6,s.admitted,s'={...s,vmFreed:true,violation:6}},
    all {s.bug==7,s.status.get(1)==2,s.grace.get(1)>0,
      s'={...s,status:s.status.set(1,4),destination:s.destination.union(Set(1)),violation:7}},
    all {s.bug==8,s.status.get(1)==2,s.window,
      s'={...s,roots:s.roots.exclude(Set(1)),scan:s.scan.exclude(Set(1)),violation:8}}
  }
  action idle=s'=s
  action step=any {joinA,joinB,exitA,exitB,returnA,returnB,errorB,requestGc,
    startGc,finishGc,requestWindow,serviceWindow,bad,idle}
  val safe=all {
    not(s.admitted) or s.lane.get(1)!=s.lane.get(2),
    donors.forall(p=>s.calls.get(p)<=1),
    donors.forall(p=>s.roots.contains(p) or s.destination.contains(p)),
    donors.forall(p=>s.status.get(p)!=4 or (s.exited.contains(p) and s.calls.get(p)==1 and
      s.grace.get(p)==0 and s.destination.contains(p))),
    donors.forall(p=>s.scan.contains(p) or s.destination.contains(p)),
    donors.forall(p=>not(Set(1,3,5).contains(s.status.get(p))) or s.roots.contains(p)),
    not(s.vmFreed) or s.pins==Set(),
    not(s.refused) or (not(s.admitted) and s.calls==Map(1->0,2->0))}
  val goal=if(s.mode==4) s.refused else if(s.mode==2)
    s.status.get(2)==3 and s.observed.contains(2) and s.roots==donors
    else if(s.mode==0) s.status.get(1)==4 and s.status.get(2)==4
    else if(s.mode==5) s.status.get(1)==5 and s.status.get(2)==4 and s.roots.contains(1)
    else s.status.get(2)==4 and s.roots.contains(1)
  temporal assumptions=all {weakFair(joinA,Set(s)),weakFair(joinB,Set(s)),
    weakFair(exitA,Set(s)),weakFair(exitB,Set(s)),weakFair(returnA,Set(s)),
    weakFair(returnB,Set(s)),weakFair(errorB,Set(s)),weakFair(startGc,Set(s)),
    weakFair(finishGc,Set(s)),weakFair(requestWindow,Set(s)),weakFair(serviceWindow,Set(s))}
  temporal progress=assumptions.implies(eventually(goal))
  temporal noSchedulerAssumption=eventually(goal)
}
