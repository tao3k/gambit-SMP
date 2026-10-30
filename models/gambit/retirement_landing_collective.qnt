module retirement_landing_collective {
  // Three old members; two survivors. This is a protocol abstraction, not C execution.
  type State={mode:int,bug:int,violation:int,phase:int,landed:Set[int],saved:Set[int],
    restored:Set[int],ack:Set[int],released:Set[int],version:int,restoreVersion:int->int,
    oldMembers:Set[int],carrier:bool,gc:int,gcPending:bool,finalPending:bool,
    selected:int,transferred:bool,resultPublished:bool,resultAck:Set[int],error:int,
    callerError:int,quarantined:bool,restoreCount:int->int,contextValid:bool,lockHeld:bool,depth:int,earlyExit:bool,epoch:int}
  val old=Set(0,1,2)
  val survivors=Set(0,1)
  var s:State
  pure def initial(m:int,b:int):State={mode:m,bug:b,violation:0,phase:0,
    landed:Set(),saved:Set(),restored:Set(),ack:Set(),released:Set(),version:0,
    restoreVersion:Map(0->0,1->0,2->0),oldMembers:old,carrier:true,gc:0,
    gcPending:false,finalPending:false,selected:0,transferred:false,
    resultPublished:false,resultAck:Set(),error:0,callerError:0,quarantined:false,
    restoreCount:Map(0->0,1->0,2->0),contextValid:true,lockHeld:false,depth:0,earlyExit:false,epoch:1}
  action initSuccess=s'=initial(0,0)
  action initPrepareFailure=s'=initial(1,0)
  action initGcOverflow=s'=initial(2,0)
  action initRollbackFailure=s'=initial(3,0)
  action initFinalizeFailure=s'=initial(4,0)
  action initRawCJump=s'=initial(0,1)
  action initSaveUnderLock=s'=initial(0,2)
  action initGcAfterMemberReturn=s'=initial(0,3)
  action initStaleAbortRestore=s'=initial(1,4)
  action initDuplicateRestore=s'=initial(1,5)
  action initAckBeforeRestore=s'=initial(1,6)
  action initUserBeforeAbortAgreement=s'=initial(1,7)
  action initFreeOnRollbackFailure=s'=initial(3,8)
  action initLoseFinalizeToGc=s'=initial(0,9)
  action initRecursiveCollective=s'=initial(0,10)
  action initTransferBeforeElection=s'=initial(0,11)
  action initThrowBeforeResultAck=s'=initial(4,12)
  action initLoseCallerError=s'=initial(4,13)
  action initReuseDuringAbort=s'=initial(3,14)
  // Entry is from a supported Scheme continuation, outside T/P locks and C collectives.
  action land={nondet p=old.oneOf();all {s.phase==0,not(s.landed.contains(p)),
    s'={...s,landed:s.landed.union(Set(p)),saved:s.saved.union(Set(p))}}}
  action allLanded=all {s.phase==0,s.landed==old,s'={...s,phase:1}}
  // Two completed private GCs with all old members. Overflow may follow relocation.
  action nestedGc=all {s.phase==1,s.gc<2,s.oldMembers==old,
    s'={...s,gc:s.gc+1,version:s.version+1}}
  action decide=all {s.phase==1,s.gc==2,
    s'={...s,phase:if(Set(1,2,3).contains(s.mode)) 5 else 2,
      error:if(Set(1,2,3).contains(s.mode)) 1 else 0}}
  // Same collective exclusion commits membership and native scan-domain change.
  action commit=all {s.phase==2,s.saved==old,s.gc==2,
    s'={...s,phase:3,oldMembers:survivors,gcPending:true,finalPending:true}}
  // A competing GC wins first. Its result does not consume the pending finalize.
  action electGc=all {s.phase==3,s.gcPending,s.selected==0,
    s'={...s,selected:1}}
  action runGc=all {s.phase==3,s.selected==1,
    s'={...s,selected:0,gcPending:false,version:s.version+1}}
  action electFinalize=all {s.phase==3,not(s.gcPending),s.finalPending,s.selected==0,
    s'={...s,selected:2,depth:1}}
  // Selected finalize is nonallocating, has no callbacks and never calls on_all recursively.
  action finalize=all {s.phase==3,s.selected==2,
    s'={...s,phase:4,selected:0,depth:0,finalPending:false,
      transferred:s.mode!=4,error:if(s.mode==4) 2 else 0,resultPublished:true}}
  action consumeResult={nondet p=survivors.oneOf();all {s.phase==4,s.resultPublished,
    not(s.resultAck.contains(p)),s'={...s,resultAck:s.resultAck.union(Set(p))}}}
  action finish=all {s.phase==4,s.resultAck==survivors,
    s'={...s,phase:7,callerError:s.error,carrier:s.mode==4,quarantined:s.mode==4}}
  // Restore consumes each continuation exactly once, then an ACK trampoline parks it.
  action restore={nondet p=old.oneOf();all {s.phase==5,not(s.restored.contains(p)),
    not(s.mode==3 and p==2),s'={...s,restored:s.restored.union(Set(p)),
      restoreVersion:s.restoreVersion.set(p,s.version),restoreCount:s.restoreCount.set(p,1)}}}
  action acknowledge={nondet p=old.oneOf();all {s.phase==5,s.restored.contains(p),
    not(s.ack.contains(p)),s'={...s,ack:s.ack.union(Set(p))}}}
  action abortComplete=all {s.phase==5,s.ack==old,
    s'={...s,phase:7,carrier:false,released:old,callerError:s.error}}
  action rollbackFailed=all {s.phase==5,s.mode==3,s.ack==survivors,
    s'={...s,phase:7,quarantined:true,callerError:s.error}}
  action bad=any {
    all {s.bug==1,s.phase==0,s'={...s,contextValid:false,violation:1}},
    all {s.bug==2,s.phase==0,s'={...s,lockHeld:true,violation:2}},
    all {s.bug==3,s.phase==1,s.gc==1,s'={...s,oldMembers:survivors,violation:3}},
    all {s.bug==4,s.phase==5,s'={...s,restored:s.restored.union(Set(0)),restoreVersion:s.restoreVersion.set(0,0),restoreCount:s.restoreCount.set(0,1),violation:4}},
    all {s.bug==5,s.phase==5,s.restored.contains(0),s'={...s,restoreCount:s.restoreCount.set(0,2),violation:5}},
    all {s.bug==6,s.phase==5,not(s.restored.contains(2)),s'={...s,ack:s.ack.union(Set(2)),violation:6}},
    all {s.bug==7,s.phase==5,s.ack==Set(0),s'={...s,released:Set(0),violation:7}},
    all {s.bug==8,s.phase==7,s.quarantined,s'={...s,carrier:false,violation:8}},
    all {s.bug==9,s.phase==3,s.selected==1,s'={...s,finalPending:false,violation:9}},
    all {s.bug==10,s.phase==3,s.selected==2,s'={...s,depth:2,violation:10}},
    all {s.bug==11,s.phase==3,s.selected==0,s'={...s,transferred:true,violation:11}},
    all {s.bug==12,s.phase==4,s.resultAck!=survivors,s'={...s,earlyExit:true,violation:12}},
    all {s.bug==13,s.phase==7,s.error!=0,s'={...s,callerError:0,violation:13}},
    all {s.bug==14,s.phase==7,s.quarantined,s'={...s,epoch:2,violation:14}}
  }
  val terminal=s.phase==7
  action done=all {terminal,s'=s}
  action step=any {land,allLanded,nestedGc,decide,commit,electGc,runGc,electFinalize,
    finalize,consumeResult,finish,restore,acknowledge,abortComplete,rollbackFailed,bad,done}
  val safe=all {s.contextValid,not(s.lockHeld),s.depth<=1,
    not(s.earlyExit) or s.resultAck==survivors,
    not(s.quarantined) or s.epoch==1,
    s.phase!=3 or s.finalPending,
    not(s.transferred) or Set(4,7).contains(s.phase),
    s.restored.forall(p=>s.restoreVersion.get(p)==s.version and s.restoreCount.get(p)==1),
    s.ack.subseteq(s.restored),s.released==Set() or s.ack==old,
    s.phase!=1 or s.oldMembers==old,
    not(s.quarantined) or s.carrier,
    not(terminal) or s.callerError==s.error,
    s.phase!=4 or s.resultPublished}
  temporal completion=weakFair(step,Set(s)).implies(eventually(terminal))
}
