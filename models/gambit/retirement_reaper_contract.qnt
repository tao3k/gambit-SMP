module retirement_reaper_contract {
  // Two donors, two serial generations, fixed reaper identity1.
  // Original slots retain storage; carrier roots provide tracing only.
  // Actual GC maps/native atomics are refinement obligations, not this theorem.
  type State = {
    mode:int, bug:int, epoch:int, phase:int, oldCohort:bool,
    ready:Set[int], carrier:Set[int], p0roots:Set[int], pastRoots:Set[int],
    claimed:Set[int], exited:Set[int], joined:Set[int], completed:Set[int],
    accepted:Set[int], drained:Set[int], transferred:Set[int], reclaimed:Set[int],
    owner:int->int, calls:int->int, tag:int->int,
    prepGc:int, pendingSeen:bool, gc:int, reaperStarted:bool,
    retained:bool, nativeError:bool, hintLost:bool,
    stopAck:bool, reaperJoined:bool, vmFreed:bool, fakeErrno:bool
  }
  val donors=Set(1,2)
  var s:State
  pure def initial(mode:int,bug:int):State = {
    mode:mode, bug:bug, epoch:1, phase:0, oldCohort:true,
    ready:Set(),carrier:Set(),p0roots:Set(),pastRoots:Set(),claimed:Set(),exited:Set(),
    joined:Set(),completed:Set(),accepted:Set(),drained:Set(),
    transferred:Set(),reclaimed:Set(),owner:Map(1->0,2->0),
    calls:Map(1->0,2->0),tag:Map(1->0,2->0),prepGc:0,pendingSeen:false,
    gc:0,reaperStarted:false,retained:false,nativeError:false,hintLost:false,
    stopAck:false,reaperJoined:false,vmFreed:false,fakeErrno:false
  }
  action initNormal=s'=initial(0,0)
  action initRollback=s'=initial(1,0)
  action initStartupFail=s'=initial(2,0)
  action initHardFailure=s'=initial(3,0)
  action initNotificationFail=s'=initial(4,0)
  action initStuckWorker=s'=initial(5,0)
  action initEarlyCommit=s'=initial(0,1)
  action initDuplicateJoin=s'=initial(0,2)
  action initWrongOwner=s'=initial(0,3)
  action initStaleCompletion=s'=initial(0,4)
  action initEarlyReclaim=s'=initial(0,5)
  action initDropRoots=s'=initial(0,6)
  action initDestroyRetained=s'=initial(3,7)
  action initPendingAsErrno=s'=initial(0,8)
  action initDropMailbox=s'=initial(4,9)
  action initDropPriorRoots=s'=initial(0,10)
  action prepareOne=all {
    s.phase==0, s.ready==Set(),
    s'={...s,ready:Set(1),carrier:Set(1)}
  }
  action nestedPrepareGc=all {
    s.phase==0,s.ready==Set(1),s.prepGc==0,
    s'={...s,prepGc:1}
  }
  action prepareTwo=all {
    s.phase==0,s.ready==Set(1),s.prepGc==1,s.mode!=1,
    s'={...s,ready:donors,carrier:donors}
  }
  action rollback=all {
    s.phase==0,s.oldCohort,
    (s.mode==1 and s.ready==Set(1) and s.prepGc==1) or
      (s.mode==2 and s.ready==donors),
    s'={...s,phase:3,carrier:Set()}
  }
  action startReaper=all {
    s.phase==0,s.ready==donors,s.mode!=2,not(s.reaperStarted),
    s'={...s,reaperStarted:true}
  }
  action commit=all {
    s.phase==0,s.ready==donors,s.carrier==donors,s.reaperStarted,
    s'={...s,phase:1,oldCohort:false}
  }
  action claim= {
    nondet d=donors.oneOf()
    all {
      s.phase==1,not(s.claimed.contains(d)),
      d==1 or s.reclaimed.contains(1),
      s'={...s,claimed:s.claimed.union(Set(d)),
        owner:s.owner.set(d,1),calls:s.calls.set(d,1)}
    }
  }
  action observePending=all {
    s.phase==1,s.claimed.contains(1),not(s.joined.contains(1)),not(s.pendingSeen),
    s'={...s,pendingSeen:true}
  }
  action gcWhilePending=all {
    s.phase==1,s.pendingSeen,s.gc<2,not(s.exited.contains(1)),
    s'={...s,gc:s.gc+1}
  }
  action workerExit= {
    nondet d=donors.oneOf()
    all {
      s.phase==1,s.claimed.contains(d),not(s.exited.contains(d)),
      s.pendingSeen,s.gc==2,s.mode!=5,
      s.mode!=3 or d!=2,
      s'={...s,exited:s.exited.union(Set(d))}
    }
  }
  action joinZero= {
    nondet d=donors.oneOf()
    all {
      s.phase==1,s.exited.contains(d),s.claimed.contains(d),
      not(s.joined.contains(d)),
      s'={...s,joined:s.joined.union(Set(d)),completed:s.completed.union(Set(d)),
        tag:s.tag.set(d,s.epoch*10+d)}
    }
  }
  action failSecondJoin=all {
    s.phase==1,s.mode==3,s.claimed.contains(2),s.reclaimed.contains(1),
    s'={...s,phase:2,retained:true,nativeError:true}
  }
  action stuckDisposition=all {
    s.phase==1,s.mode==5,s.pendingSeen,s.gc==2,
    s'={...s,phase:2,retained:true}
  }
  action loseNotification=all {
    s.phase==1,s.mode==4,s.completed.contains(1),not(s.hintLost),
    s'={...s,hintLost:true}
  }
  action pollCompletion= {
    nondet d=donors.oneOf()
    all {
      s.phase==1,s.completed.contains(d),not(s.accepted.contains(d)),
      s.tag.get(d)==s.epoch*10+d,s.owner.get(d)==1,
      s.mode!=4 or s.hintLost,
      s'={...s,accepted:s.accepted.union(Set(d))}
    }
  }
  action borrowerGrace= {
    nondet d=donors.oneOf()
    all {s.phase==1,s.accepted.contains(d),not(s.drained.contains(d)),
      s'={...s,drained:s.drained.union(Set(d))}}
  }
  action transfer= {
    nondet d=donors.oneOf()
    all {s.phase==1,s.drained.contains(d),not(s.transferred.contains(d)),
      s'={...s,transferred:s.transferred.union(Set(d)),p0roots:s.p0roots.union(Set(d))}}
  }
  action reclaim= {
    nondet d=donors.oneOf()
    all {s.phase==1,s.transferred.contains(d),not(s.reclaimed.contains(d)),
      s'={...s,reclaimed:s.reclaimed.union(Set(d)),carrier:s.carrier.exclude(Set(d))}}
  }
  action nextEpoch=all {
    s.phase==1,s.epoch==1,s.reclaimed==donors,
    s'={...initial(s.mode,s.bug),epoch:2,reaperStarted:true,
      pastRoots:s.pastRoots.union(Set(11,12))}
  }
  action finishEpochs=all {
    s.phase==1,s.epoch==2,s.reclaimed==donors,
    s'={...s,phase:4}
  }
  action stopReaper=all {s.phase==4,s'={...s,phase:5,stopAck:true}}
  action joinReaper=all {s.phase==5,s.stopAck,s'={...s,phase:6,reaperJoined:true}}
  action freeVm=all {s.phase==6,s.reaperJoined,s'={...s,phase:7,vmFreed:true}}
  action earlyCommit=all {s.bug==1,s.phase==0,s.ready==Set(1),
    s'={...s,phase:1,oldCohort:false}}
  action duplicateJoin=all {s.bug==2,s.phase==1,s.joined.contains(1),
    s.calls.get(1)==1,s'={...s,calls:s.calls.set(1,2)}}
  action wrongOwner=all {s.bug==3,s.phase==1,s.claimed.contains(1),
    s.owner.get(1)==1,s'={...s,owner:s.owner.set(1,2)}}
  action staleCompletion=all {s.bug==4,s.phase==1,s.epoch==2,s.joined.contains(1),
    not(s.accepted.contains(1)),
    s'={...s,accepted:s.accepted.union(Set(1)),tag:s.tag.set(1,11)}}
  action earlyReclaim=all {s.bug==5,s.phase==1,s.accepted.contains(1),
    not(s.drained.contains(1)),s'={...s,reclaimed:s.reclaimed.union(Set(1))}}
  action dropRoots=all {s.bug==6,s.phase==1,s.pendingSeen,not(s.joined.contains(1)),
    s'={...s,carrier:s.carrier.exclude(Set(1))}}
  action destroyRetained=all {s.bug==7,s.phase==2,not(s.vmFreed),
    s'={...s,vmFreed:true}}
  action pendingAsErrno=all {s.bug==8,s.phase==1,s.pendingSeen,not(s.fakeErrno),
    s'={...s,fakeErrno:true}}
  action dropMailbox=all {s.bug==9,s.phase==1,s.joined.contains(1),
    s.completed.contains(1),s'={...s,completed:s.completed.exclude(Set(1))}}
  action dropPriorRoots=all {s.bug==10,s.epoch==2,s.pastRoots==Set(11,12),
    s'={...s,pastRoots:Set(12)}}
  val terminal=Set(2,3,7).contains(s.phase)
  action done=all {terminal,s'=s}
  action step=any {prepareOne,nestedPrepareGc,prepareTwo,rollback,startReaper,
    commit,claim,observePending,gcWhilePending,workerExit,joinZero,failSecondJoin,
    stuckDisposition,loseNotification,pollCompletion,borrowerGrace,transfer,reclaim,
    nextEpoch,finishEpochs,stopReaper,joinReaper,freeVm,earlyCommit,duplicateJoin,
    wrongOwner,staleCompletion,earlyReclaim,dropRoots,destroyRetained,
    pendingAsErrno,dropMailbox,dropPriorRoots,done}
  val safe=all {
    not(s.fakeErrno),
    s.epoch==1 or s.pastRoots==Set(11,12),
    donors.forall(d=> s.oldCohort or s.carrier.contains(d) or s.p0roots.contains(d)),
    s.claimed.forall(d=> s.owner.get(d)==1 and s.calls.get(d)==1),
    s.joined.forall(d=> s.exited.contains(d) and s.claimed.contains(d) and s.completed.contains(d)),
    s.accepted.forall(d=> s.joined.contains(d) and s.tag.get(d)==s.epoch*10+d),
    s.transferred.forall(d=> s.accepted.contains(d) and s.drained.contains(d)),
    s.reclaimed.forall(d=> s.transferred.contains(d) and s.drained.contains(d) and s.joined.contains(d)),
    not(s.vmFreed) or (s.reaperJoined and s.stopAck and s.reclaimed==donors),
    s.phase!=2 or (s.retained and not(s.vmFreed)),
    s.phase!=3 or (s.oldCohort and s.claimed==Set())
  }
  temporal completion=weakFair(step,Set(s)).implies(eventually(terminal))
}
