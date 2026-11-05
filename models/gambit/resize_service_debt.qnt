module resize_service_debt {
  // Two non-wrapping resize epochs. GC/resize generation and service debt differ.
  type State={mode:int,bug:int,violation:int,phase:int,epoch:int,completed:int,
    members:Set[int],old:Set[int],ready:Set[int],failed:Set[int],resultAck:Set[int],
    memberGen:int,stableGen:int,stableMembers:Set[int],stable:bool,
    demand:int,issued:int,acked:int,covered:int,queued:bool,admitCut:int,
    lastAdmitCut:int,ackAtAdmit:int,gcDone:bool,startupGcDone:bool,
    sweepCut:int,sweepGen:int,sweepMembers:Set[int],visited:Set[int],sweepAck:Set[int],
    ackStamp:int,late:bool,rollbackAck:Set[int],roots:Set[int],destination:Set[int],
    pulse:bool,postFault:bool}
  var s:State
  val entries=Set(1,2)
  pure def initial(m:int,b:int):State={mode:m,bug:b,violation:0,phase:0,epoch:1,
    completed:0,members:Set(0,1),old:Set(0,1),ready:Set(0,1),failed:Set(),resultAck:Set(),
    memberGen:1,stableGen:1,stableMembers:Set(0,1),stable:true,demand:1,issued:1,
    acked:0,covered:0,queued:false,admitCut:0,lastAdmitCut:0,ackAtAdmit:0,
    gcDone:false,startupGcDone:false,sweepCut:0,sweepGen:0,sweepMembers:Set(),
    visited:Set(),sweepAck:Set(),ackStamp:0,late:false,rollbackAck:Set(),
    roots:entries,destination:Set(),pulse:false,postFault:false}
  action initGrowShrink=s'=initial(0,0)
  action initShrinkGrow=s'=initial(1,0)
  action initOverflowRollback=s'=initial(2,0)
  action initPostCountFailure=s'=initial(3,0)
  action initLateDemand=s'=initial(4,0)
  action initSetupRollback=s'=initial(6,0)
  action initClearOnCount=s'=initial(0,1)
  action initOldCohortSweep=s'=initial(0,2)
  action initEarlyGrowStable=s'=initial(0,3)
  action initRollbackClear=s'=initial(2,4)
  action initDropRetainedRoot=s'=initial(0,5)
  action initClearLateDemand=s'=initial(4,6)
  action initResizeBypass=s'=initial(0,7)
  action initStaleAck=s'=initial(0,8)
  action initErrorAsReady=s'=initial(3,9)
  action initResizeFlood=s'=initial(0,10)
  action initWaitAllDonors=s'=initial(0,11)
  action initStartupStuck=s'=initial(5,0)
  val shrink=(s.mode==1 and s.epoch==1) or (s.mode!=1 and s.epoch==2)
  val target=if(shrink) Set(0) else Set(0,1,2)
  action claim=all {s.phase==0,s.completed<2,not(s.queued),s.stable,
    s'={...s,queued:true,admitCut:s.demand}}
  action admit=all {s.phase==0,s.queued,s.acked>=s.admitCut,s.completed<2,
    s'={...s,phase:1,stable:false,old:s.members,ready:s.members,resultAck:Set(),
      gcDone:false,startupGcDone:false,rollbackAck:Set(),failed:Set(),
      lastAdmitCut:s.admitCut,ackAtAdmit:s.acked}}
  action resizeGc=all {s.phase==1,not(s.gcDone),
    s'={...s,gcDone:true,demand:s.demand+1,issued:s.issued+1}}
  action failPrecount=all {s.phase==1,s.gcDone,s.epoch==1,Set(2,6).contains(s.mode),
    s'={...s,phase:6}}
  action publishCount=all {s.phase==1,s.gcDone,not(s.epoch==1 and Set(2,6).contains(s.mode)),
    s'={...s,phase:2,members:target,memberGen:s.memberGen+1,
      ready:s.old.intersect(target),resultAck:Set()}}
  action startupGc=all {s.phase==2,not(s.startupGcDone),s.ready!=s.members,
    s'={...s,startupGcDone:true,demand:s.demand+1,issued:s.issued+1}}
  action makeReady={nondet p=s.members.oneOf();all {s.phase==2,not(s.ready.contains(p)),
    not(Set(3,5).contains(s.mode) and s.epoch==1),
    s'={...s,ready:s.ready.union(Set(p))}}}
  action postCountFailure=all {s.phase==2,s.mode==3,s.epoch==1,s.ready!=s.members,
    s'={...s,failed:Set(2),postFault:true,phase:5}}
  action resultAck={nondet p=s.members.oneOf();all {s.phase==2,s.ready==s.members,
    not(s.resultAck.contains(p)),s'={...s,resultAck:s.resultAck.union(Set(p))}}}
  action publishStable=all {s.phase==2,s.ready==s.members,s.failed==Set(),s.resultAck==s.members,
    s'={...s,phase:0,stable:true,stableGen:s.memberGen,stableMembers:s.members,
      queued:false,completed:s.completed+1,epoch:s.epoch+1}}
  action rollbackMember={nondet p=s.old.oneOf();all {s.phase==6,not(s.rollbackAck.contains(p)),
    s'={...s,rollbackAck:s.rollbackAck.union(Set(p))}}}
  action rollbackStable=all {s.phase==6,s.rollbackAck==s.old,
    s'={...s,phase:0,stable:true,stableGen:s.memberGen,stableMembers:s.old,
      members:s.old,ready:s.old,queued:false,completed:s.completed+1,epoch:s.epoch+1}}
  action beginSweep=all {s.phase==0,s.stable,s.demand>s.acked,
    s.bug!=10,
    s'={...s,phase:3,sweepCut:s.demand,sweepGen:s.stableGen,
      sweepMembers:s.stableMembers,visited:Set(),sweepAck:Set(),ackStamp:s.stableGen}}
  action visit={nondet p=entries.oneOf();all {s.phase==3,not(s.visited.contains(p)),
    s'={...s,visited:s.visited.union(Set(p)),
      roots:if(p==2) s.roots.exclude(Set(2)) else s.roots,
      destination:if(p==2) s.destination.union(Set(2)) else s.destination}}}
  action acknowledge={nondet p=s.sweepMembers.oneOf();all {s.phase==3,s.visited==entries,
    not(s.sweepAck.contains(p)),s'={...s,sweepAck:s.sweepAck.union(Set(p))}}}
  action lateDemand=all {s.phase==3,s.mode==4,s.epoch==1,not(s.late),
    s'={...s,late:true,demand:s.demand+1,issued:s.issued+1}}
  action finishSweep=all {s.phase==3,s.visited==entries,s.sweepAck==s.sweepMembers,
    s.bug!=11 or s.roots==Set(),
    s'={...s,phase:0,acked:s.sweepCut,covered:s.sweepCut}}
  // New resize attempts can arrive forever, without requiring epoch-number reuse.
  action resizePressure=all {s.phase==0 or s.bug==10,s'={...s,pulse:not(s.pulse)}}
  action bad=any {
    all {s.bug==1,s.phase==2,s.demand>s.acked,s'={...s,acked:s.demand,violation:1}},
    all {s.bug==2,s.phase==3,s.epoch==2,s.old!=s.members,
      s'={...s,sweepMembers:s.old,violation:2}},
    all {s.bug==3,s.phase==2,s.ready!=s.members,
      s'={...s,stable:true,stableGen:s.memberGen,stableMembers:s.members,violation:3}},
    all {s.bug==4,s.phase==6,s'={...s,acked:s.demand,violation:4}},
    all {s.bug==5,s.phase==0,s.acked>0,
      s'={...s,roots:s.roots.exclude(Set(1)),violation:5}},
    all {s.bug==6,s.phase==3,s.late,s.demand>s.sweepCut,
      s'={...s,demand:s.sweepCut,violation:6}},
    all {s.bug==7,s.phase==0,s.queued,s.acked<s.admitCut,
      s'={...s,lastAdmitCut:s.admitCut,ackAtAdmit:s.acked,violation:7}},
    all {s.bug==8,s.phase==3,s.memberGen>1,
      s'={...s,sweepAck:Set(0),ackStamp:1,violation:8}},
    all {s.bug==9,s.phase==5,s.postFault,
      s'={...s,stable:true,stableGen:s.memberGen,stableMembers:s.members,violation:9}}
  }
  action idle=s'=s
  action step=any {claim,admit,resizeGc,failPrecount,publishCount,startupGc,
    makeReady,postCountFailure,resultAck,publishStable,rollbackMember,rollbackStable,
    beginSweep,visit,acknowledge,lateDemand,finishSweep,resizePressure,bad,idle}
  val safe=all {
    s.demand==s.issued,s.acked<=s.covered,s.covered<=s.demand,
    s.lastAdmitCut<=s.ackAtAdmit,
    not(s.stable) or (s.stableGen==s.memberGen and s.stableMembers==s.members and
      s.ready==s.members and s.failed==Set()),
    s.phase!=3 or (s.sweepGen==s.memberGen and s.sweepMembers==s.members),
    s.sweepAck==Set() or s.ackStamp==s.sweepGen,
    s.roots.union(s.destination)==entries,s.roots.contains(1),
    s.phase!=5 or (s.postFault and s.demand>s.acked and not(s.stable))}
  val goal=if(s.mode==3) s.phase==5 and s.postFault and s.demand>s.acked and s.roots.contains(1)
    else s.completed==2 and s.acked==s.demand and s.destination.contains(2) and s.roots.contains(1)
  temporal fairness=all {weakFair(claim,Set(s)),weakFair(admit,Set(s)),
    weakFair(resizeGc,Set(s)),weakFair(failPrecount,Set(s)),weakFair(publishCount,Set(s)),
    weakFair(startupGc,Set(s)),weakFair(makeReady,Set(s)),weakFair(postCountFailure,Set(s)),
    weakFair(resultAck,Set(s)),weakFair(publishStable,Set(s)),weakFair(rollbackMember,Set(s)),
    weakFair(rollbackStable,Set(s)),weakFair(beginSweep,Set(s)),weakFair(visit,Set(s)),
    weakFair(acknowledge,Set(s)),weakFair(finishSweep,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
}
