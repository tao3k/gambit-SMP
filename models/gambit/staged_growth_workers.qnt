module staged_growth_workers {
  // Native shell first; full inactive pstate exists only under GC exclusion.
  // Mode1/4/7 abort epoch1 fully, then retry epoch2 with new native keys.
  type State={mode:int,bug:int,violation:int,phase:int,epoch:int,created:Set[int],
    parked:Set[int],full:Set[int],reserved:Set[int],members:Set[int],gate:int,
    gateEpoch:int,keyEpoch:int->int,bound:Set[int],ran:Set[int],ready:Set[int],
    exited:Set[int],joined:Set[int],joinError:Set[int],joinCalls:int->int,
    cleaned:Set[int],pins:Set[int],carrier:bool,activeRoots:bool,gcExcluded:bool,
    gcActive:bool,gcVersion:int,staleRead:bool,readVersion:int,committed:bool,
    abortAck:Set[int],grace:bool,debt:int,covered:int,ack:int,stable:bool}
  val slots=Set(2,3)
  val old=Set(0,1)
  var s:State
  pure def initial(m:int,b:int):State={mode:m,bug:b,violation:0,phase:0,epoch:1,
    created:Set(),parked:Set(),full:Set(),reserved:Set(),members:old,gate:0,
    gateEpoch:1,keyEpoch:Map(2->1,3->1),bound:Set(),ran:Set(),ready:Set(),
    exited:Set(),joined:Set(),joinError:Set(),joinCalls:Map(2->0,3->0),cleaned:Set(),
    pins:Set(),carrier:false,activeRoots:false,gcExcluded:false,gcActive:false,
    gcVersion:0,staleRead:false,readVersion:0,committed:false,abortAck:Set(),
    grace:false,debt:0,covered:0,ack:0,stable:true}
  action initSuccess=s'=initial(0,0)
  action initPartialCreateRetry=s'=initial(1,0)
  action initGateTimeoutAbort=s'=initial(2,0)
  action initAbortJoinError=s'=initial(3,0)
  action initSetupFailureRetry=s'=initial(4,0)
  action initReservationRollbackFailure=s'=initial(5,0)
  action initPostCommitStartupFailure=s'=initial(6,0)
  action initGateInitFailureRetry=s'=initial(7,0)
  action initCommitBeforePark=s'=initial(0,1)
  action initShellBindsEarly=s'=initial(0,2)
  action initStaleGo=s'=initial(1,3)
  action initAbortAfterGo=s'=initial(0,4)
  action initFreeBeforeJoin=s'=initial(2,5)
  action initStaleNativeThunk=s'=initial(0,6)
  action initGcWithInactiveHeap=s'=initial(0,7)
  action initDropCarrierAfterAbort=s'=initial(2,8)
  action initReuseRetainedEpoch=s'=initial(3,9)
  action initCleanupWithoutReservationUndo=s'=initial(4,10)
  action initClearDebtOnAbort=s'=initial(2,11)
  action initMissingGateDeadline=s'=initial(8,0)
  action initAssumeJoinErrorRecovers=s'=initial(3,0)
  action begin=all {s.phase==0,s'={...s,phase:1,carrier:true,stable:true,debt:s.debt+1}}
  action createOne=all {s.phase==1,s.created==Set(),not(s.mode==7 and s.epoch==1),
    s'={...s,created:Set(2),pins:Set(2)}}
  action createTwo=all {s.phase==1,s.created==Set(2),not(Set(1,3).contains(s.mode) and s.epoch==1),
    s'={...s,created:slots,pins:slots}}
  action createFailure=all {s.phase==1,s.created==Set(2),Set(1,3).contains(s.mode),s.epoch==1,
    s'={...s,phase:4,gate:2,stable:true}}
  action gateInitFailure=all {s.phase==1,s.mode==7,s.epoch==1,s.created==Set(),
    s'={...s,phase:4,gate:2}}
  action park={nondet p=slots.oneOf();all {s.phase==1,s.created.contains(p),not(s.parked.contains(p)),
    not(Set(2,8).contains(s.mode) and p==3),
    s'={...s,parked:s.parked.union(Set(p))}}}
  action gateTimeout=all {s.phase==1,s.mode==2,s.created==slots,s.parked!=slots,
    s'={...s,phase:4,gate:2}}
  // Old cohort may collect repeatedly while native shells are unbound.
  action oldGc=all {(s.phase==1 or (s.phase==8 and not(s.committed))),not(s.gcExcluded),
    s.full==Set(),s'={...s,gcVersion:1-s.gcVersion}}
  action beginSetup=all {s.phase==1,s.created==slots,s.parked==slots,
    s'={...s,phase:2,gcExcluded:true,stable:false}}
  action setupOne=all {s.phase==2,s.full==Set(),s'={...s,full:Set(2),reserved:Set(2)}}
  action setupTwo=all {s.phase==2,s.full==Set(2),not(Set(4,5).contains(s.mode) and s.epoch==1),
    s'={...s,full:slots,reserved:slots}}
  action setupFailure=all {s.phase==2,s.full==Set(2),Set(4,5).contains(s.mode),s.epoch==1,
    s'={...s,phase:4,gate:2}}
  action commit=all {s.phase==2,s.created==slots,s.parked==slots,s.full==slots,
    s'={...s,phase:3,members:old.union(slots),committed:true,gate:1,gateEpoch:s.epoch,
      gcExcluded:false}}
  action bind={nondet p=slots.oneOf();all {s.phase==3,s.gate==1,s.gateEpoch==s.keyEpoch.get(p),
    not(s.bound.contains(p)),s'={...s,bound:s.bound.union(Set(p))}}}
  action runScheme={nondet p=slots.oneOf();all {s.phase==3,s.bound==slots,not(s.ran.contains(p)),
    s'={...s,ran:s.ran.union(Set(p)),readVersion:s.gcVersion,activeRoots:true}}}
  action ready={nondet p=slots.oneOf();all {s.phase==3,s.ran.contains(p),not(s.ready.contains(p)),
    not(s.mode==6 and p==3),s'={...s,ready:s.ready.union(Set(p))}}}
  action succeed=all {s.phase==3,s.ready==slots,
    s'={...s,phase:7,stable:true,covered:s.debt,ack:s.debt}}
  action postCommitFailure=all {s.phase==3,s.mode==6,s.ran==slots,s.ready!=slots,
    s'={...s,phase:8,stable:false}}
  // ABORT never binds or enters Scheme. EXIT hint is not native join0.
  action exitShell={nondet p=s.created.oneOf();all {s.phase==4,s.gate==2,not(s.exited.contains(p)),
    s'={...s,exited:s.exited.union(Set(p))}}}
  action joinShell={nondet p=s.created.oneOf();all {s.phase==4,s.exited.contains(p),
    not(s.joined.contains(p)),not(s.joinError.contains(p)),
    s'={...s,joinCalls:s.joinCalls.set(p,1),
      joined:if(s.mode==3) s.joined else s.joined.union(Set(p)),
      joinError:if(s.mode==3) s.joinError.union(Set(p)) else s.joinError}}}
  action nativeRetained=all {s.phase==4,s.joinError!=Set(),
    s'={...s,phase:8,stable:s.full==Set()}}
  action rollbackFailure=all {s.phase==4,s.mode==5,s.joined==s.created,
    s'={...s,phase:8,stable:false}}
  action undoAndClean=all {s.phase==4,s.joined==s.created,s.mode!=5,
    s'={...s,phase:5,full:Set(),reserved:Set(),cleaned:s.created,created:Set(),pins:Set(),
      gcExcluded:false,members:old,stable:false}}
  action abortAck={nondet p=old.oneOf();all {s.phase==5,not(s.abortAck.contains(p)),
    s'={...s,abortAck:s.abortAck.union(Set(p))}}}
  action drainReaders=all {s.phase==5,s.abortAck==old,not(s.grace),s'={...s,grace:true}}
  action abortStable=all {s.phase==5,s.abortAck==old,s.grace,
    s'={...s,phase:6,stable:true}}
  action serviceOld=all {Set(6,8).contains(s.phase),s.stable,s.full==Set(),s.ack<s.debt,
    s'={...s,covered:s.debt,ack:s.debt}}
  action retry=all {s.phase==6,s.ack==s.debt,s.epoch==1,Set(1,4,7).contains(s.mode),
    s'={...s,phase:0,epoch:2,created:Set(),parked:Set(),full:Set(),reserved:Set(),gate:0,
      gateEpoch:2,keyEpoch:Map(2->2,3->2),bound:Set(),ran:Set(),ready:Set(),exited:Set(),
      joined:Set(),joinError:Set(),joinCalls:Map(2->0,3->0),cleaned:Set(),pins:Set(),
      carrier:false,activeRoots:false,abortAck:Set(),grace:false}}
  action bad=any {
    all {s.bug==1,s.phase==1,s.created==slots,s.parked!=slots,
      s'={...s,committed:true,members:old.union(slots),violation:1}},
    all {s.bug==2,s.phase==1,s.created.contains(2),s'={...s,bound:Set(2),violation:2}},
    all {s.bug==3,s.phase==3,s.epoch==2,s'={...s,gateEpoch:1,violation:3}},
    all {s.bug==4,s.phase==3,s.committed,s'={...s,gate:2,violation:4}},
    all {s.bug==5,s.phase==4,s.created!=Set(),s.joined!=s.created,
      s'={...s,cleaned:s.created,violation:5}},
    all {s.bug==6,s.phase==1,s.gcVersion==1,
      s'={...s,staleRead:true,readVersion:0,violation:6}},
    all {s.bug==7,s.phase==2,s.full!=Set(),s'={...s,gcActive:true,violation:7}},
    all {s.bug==8,s.phase==4,s.created!=Set(),s'={...s,carrier:false,violation:8}},
    all {s.bug==9,s.phase==8,s.joinError!=Set(),s'={...s,epoch:2,violation:9}},
    all {s.bug==10,s.phase==4,s.full!=Set(),s.joined==s.created,
      s'={...s,phase:5,full:Set(),gcExcluded:false,violation:10}},
    all {s.bug==11,s.phase==4,s'={...s,ack:s.debt,violation:11}}
  }
  action idle=s'=s
  action step=any {begin,createOne,createTwo,createFailure,gateInitFailure,park,gateTimeout,
    oldGc,beginSetup,setupOne,setupTwo,setupFailure,commit,bind,runScheme,ready,succeed,
    postCommitFailure,exitShell,joinShell,nativeRetained,rollbackFailure,undoAndClean,
    abortAck,drainReaders,abortStable,serviceOld,retry,bad,idle}
  val safe=all {
    not(s.committed) or (s.full==slots and s.parked==slots and s.members==old.union(slots) and s.gate==1),
    s.bound==Set() or s.committed,
    s.created.forall(p=>s.keyEpoch.get(p)==s.epoch),
    s.gate!=1 or s.gateEpoch==s.epoch,
    s.cleaned.subseteq(s.joined),s.joined.forall(p=>s.joinCalls.get(p)==1),
    not(s.staleRead) or s.readVersion==s.gcVersion,
    not(s.gcActive) or (not(s.gcExcluded) and s.full.subseteq(s.members)),
    s.full.exclude(s.members)==Set() or s.gcExcluded,
    s.full==s.reserved,
    s.created==Set() or s.carrier or s.activeRoots,
    s.ack<=s.covered,s.covered<=s.debt,
    not(s.stable) or (not(s.gcExcluded) and (s.members==old or s.ready==slots))}
  val success=s.phase==7
  val goal=if(s.mode==3) s.phase==8 and s.carrier and s.joinError!=Set() and s.ack==s.debt
    else if(s.mode==5) s.phase==8 and s.gcExcluded and s.carrier and s.ack==0
    else if(s.mode==6) s.phase==8 and s.committed and s.carrier and s.ack==0
    else if(s.mode==2) s.phase==6 and s.ack==s.debt and s.created==Set() and s.members==old
    else success and (not(Set(1,4,7).contains(s.mode)) or s.epoch==2)
  temporal fairness=all {weakFair(begin,Set(s)),weakFair(createOne,Set(s)),weakFair(createTwo,Set(s)),
    weakFair(createFailure,Set(s)),weakFair(gateInitFailure,Set(s)),weakFair(park,Set(s)),
    weakFair(gateTimeout,Set(s)),weakFair(beginSetup,Set(s)),weakFair(setupOne,Set(s)),
    weakFair(setupTwo,Set(s)),weakFair(setupFailure,Set(s)),weakFair(commit,Set(s)),
    weakFair(bind,Set(s)),weakFair(runScheme,Set(s)),weakFair(ready,Set(s)),weakFair(succeed,Set(s)),
    weakFair(postCommitFailure,Set(s)),weakFair(exitShell,Set(s)),weakFair(joinShell,Set(s)),
    weakFair(nativeRetained,Set(s)),weakFair(rollbackFailure,Set(s)),weakFair(undoAndClean,Set(s)),
    weakFair(abortAck,Set(s)),weakFair(drainReaders,Set(s)),weakFair(abortStable,Set(s)),
    weakFair(serviceOld,Set(s)),weakFair(retry,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
  temporal unconditionalRecovery=fairness.implies(eventually(success))
}
