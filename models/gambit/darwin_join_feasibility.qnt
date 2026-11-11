module darwin_join_feasibility {
  // Protocol abstraction of pinned Apple source, NOT deployed-machine proof.
  // kind0 normal;1 cycle;2 self;3 stale;4 detached;5 competing;
  // 6 interrupted native wait;7 canceled owner;8 proposed deferred retirement.
  // first/second are observed native returns; -1 means no return.
  type State = {
    kind:int, bug:int, stage:int, first:int, second:int,
    ownerAlive:bool, workerExited:bool, joined:bool, attempts:int,
    deferred:bool, roots:bool, transfers:int, busyAsErrno:bool, targetCanceled:bool
  }
  var s:State
  pure def initial(kind:int, bug:int):State = {
    kind:kind, bug:bug, stage:0, first:-1, second:-1,
    ownerAlive:true, workerExited:false, joined:false, attempts:0,
    deferred:false, roots:true, transfers:0, busyAsErrno:false, targetCanceled:false
  }
  action initPlatform = any {
    s'=initial(0,0), s'=initial(1,0), s'=initial(2,0), s'=initial(3,0),
    s'=initial(4,0), s'=initial(5,0), s'=initial(6,0), s'=initial(7,0)
  }
  // kind9 permits external target cancellation: wider API, NOT Gambit admission.
  action initCancelTarget = s'=initial(9,0)
  action initDeferred = s'=initial(8,0)
  action initInventError = s'=initial(0,1)
  action initBreakCycle = s'=initial(1,2)
  action initReturnEintr = s'=initial(6,3)
  action initBusyAsErrno = s'=initial(8,4)
  action initFreePendingRoots = s'=initial(8,5)
  action initJoinTwice = s'=initial(8,6)
  action beginWait = all {
    Set(0,6).contains(s.kind), s.stage==0,
    s'={...s, stage:1, attempts:1}
  }
  action waitInterrupted = all { s.kind==6, s.stage==1, s'=s }
  action exitWorker = all {
    Set(0,6,8).contains(s.kind), s.stage==1, not(s.workerExited),
    s'={...s, workerExited:true}
  }
  action completeWait = all {
    Set(0,6).contains(s.kind), s.stage==1, s.workerExited,
    s'={...s, stage:2, first:0, joined:true}
  }
  action reportError = all {
    Set(1,2,3,4,5,9).contains(s.kind), s.stage==0,
    s'={...s, stage:1, attempts:1,
      first:if (Set(1,2,9).contains(s.kind)) 11 else if (s.kind==3) 3 else 22}
  }
  action retryError = all {
    Set(1,2,3,4,5).contains(s.kind), s.stage==1,
    s'={...s, stage:2, attempts:2, second:s.first}
  }
  action cancelTarget = all {
    s.kind==9, s.stage==1, not(s.workerExited),
    s'={...s, workerExited:true, targetCanceled:true}
  }
  action joinCanceledTarget = all {
    s.kind==9, s.stage==1, s.workerExited, s.targetCanceled,
    s'={...s, stage:2, second:0, attempts:2, joined:true}
  }
  action canceledOwner = all {
    s.kind==7, s.stage==0,
    s'={...s, stage:2, ownerAlive:false, attempts:1}
  }
  action deferBeforeJoin = all {
    s.kind==8, s.stage==0,
    s'={...s, stage:1, deferred:true}
  }
  action joinExited = all {
    s.kind==8, s.stage==1, s.workerExited,
    s'={...s, stage:2, first:0, joined:true, attempts:1}
  }
  action transferAfterJoin = all {
    s.kind==8, s.stage==2, s.joined,
    s'={...s, stage:3, transfers:1, roots:false}
  }
  // These mutants introduce exactly the missing/unjustified transition.
  action inventError = all {
    s.bug==1, s.stage==0,
    s'={...s, stage:2, first:11, second:0, joined:true, attempts:2}
  }
  action breakCycle = all {
    s.bug==2, s.stage==1,
    s'={...s, stage:2, workerExited:true, second:0, joined:true, attempts:2}
  }
  action returnEintr = all {
    s.bug==3, s.stage==1,
    s'={...s, stage:2, first:4, second:0, joined:true, attempts:2}
  }
  action busyAsErrno = all {
    s.bug==4, s.stage==1,
    s'={...s, stage:2, busyAsErrno:true, first:11, second:0}
  }
  action freePendingRoots = all {
    s.bug==5, s.stage==1,
    s'={...s, roots:false}
  }
  action joinTwice = all {
    s.bug==6, s.kind==8, s.stage==2,
    s'={...s, attempts:2}
  }
  action hold = all { s.kind!=8, s.stage==2, s'=s }
  action done = all { s.kind==8, s.stage==3, s'=s }
  action step = any {
    beginWait,waitInterrupted,exitWorker,completeWait,reportError,retryError,
    cancelTarget,joinCanceledTarget,canceledOwner,deferBeforeJoin,joinExited,transferAfterJoin,inventError,
    breakCycle,returnEintr,busyAsErrno,freePendingRoots,joinTwice,hold,done
  }
  val notRecovered = not(s.first>0 and s.second==0)
  val noNativeRecovery = s.kind==9 or notRecovered
  val safe = noNativeRecovery and not(s.busyAsErrno) and
    (s.roots or s.joined) and (s.transfers==0 or s.joined) and
    (s.kind!=8 or s.attempts<=1) and
    (s.kind!=1 or not(s.ownerAlive and s.workerExited)) and
    (s.kind!=7 or s.first == -1) and
    (s.kind!=9 or s.second!=0 or (s.targetCanceled and s.workerExited and s.ownerAlive))
  val terminal = s.kind==8 and s.stage==3 and s.joined and
    s.workerExited and s.first==0 and s.second == -1 and
    s.deferred and s.transfers==1 and s.attempts==1
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
}
