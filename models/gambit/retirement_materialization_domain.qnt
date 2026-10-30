module retirement_materialization_domain {
  // Source refinement abstraction: two donors, preparation GC and two pending GCs.
  // Lists are identified separately from active participant count.
  type State={mode:int,bug:int,phase:int,epoch:int,active:Set[int],pending:Set[int],
    receiverLists:Set[int],saved:Set[int],materialized:Set[int],carrier:bool,
    executed:Set[int],cursor:int->int,contVersion:int->int,restored:int->int,
    abortAck:Set[int],lease:bool,snapshot:Set[int],domainVersion:int,snapshotVersion:int,
    gcCycles:int,livePtr:int,rcPtr:int,rcMutated:bool,stillSetup:bool,
    joined:bool,destination:bool,freed:bool}
  val donors=Set(1,2)
  val allOwners=Set(0,1,2)
  var s:State
  pure def initial(mode:int,bug:int):State={mode:mode,bug:bug,phase:0,epoch:1,
    active:allOwners,pending:Set(),receiverLists:Set(),saved:Set(),materialized:Set(),
    carrier:true,executed:Set(),cursor:Map(1->0,2->0),contVersion:Map(1->0,2->0),
    restored:Map(1->0,2->0),abortAck:Set(),lease:false,snapshot:Set(),domainVersion:0,
    snapshotVersion:0,gcCycles:0,livePtr:1,rcPtr:1,rcMutated:false,stillSetup:true,
    joined:false,destination:false,freed:false}
  action initNormal=s'=initial(0,0)
  action initDonor2Fails=s'=initial(1,0)
  action initHeapFailure=s'=initial(2,0)
  action initJoinDuringScan=s'=initial(3,0)
  action initCommitRaw=s'=initial(0,1)
  action initDropDomainGap=s'=initial(0,2)
  action initDuplicateOwner=s'=initial(0,3)
  action initRcNoWriteback=s'=initial(0,4)
  action initSkipStillReset=s'=initial(0,5)
  action initRestoreOldFrame=s'=initial(1,6)
  action initReplayPrefix=s'=initial(1,7)
  action initDropBeforeAbortAck=s'=initial(1,8)
  action initRemoveDuringScan=s'=initial(3,9)
  action initRemoveBeforeReceiver=s'=initial(0,10)
  action initFreeBeforeScanEnd=s'=initial(3,11)
  action initReuseBeforeAbortAck=s'=initial(1,12)
  action saveOne=all {
    s.phase==0,s.saved==Set(),
    s'={...s,saved:Set(1),executed:Set(1),cursor:s.cursor.set(1,1)}
  }
  action materializeOne=all {
    s.phase==0,s.saved==Set(1),
    s'={...s,phase:1,materialized:Set(1),contVersion:s.contVersion.set(1,1)}
  }
  action donor2Fails=all {
    s.phase==1,s.mode==1,s'={...s,phase:7}
  }
  action saveTwo=all {
    s.phase==1,s.mode!=1,s.saved==Set(1),
    s'={...s,saved:donors,executed:donors,cursor:s.cursor.set(2,1)}
  }
  // GC may have relocated roots even when the requested space is insufficient.
  action materializeTwo=all {
    s.phase==1,s.saved==donors,
    s'={...s,phase:if(s.mode==2) 7 else 2,materialized:donors,
      contVersion:Map(1->2,2->1)}
  }
  action commit=all {
    s.phase==2,s.materialized==donors,not(s.lease),
    s'={...s,phase:3,active:Set(0),pending:donors,domainVersion:1}
  }
  action beginGc=all {
    Set(3,4).contains(s.phase),not(s.lease),s.gcCycles<2,
    s.gcCycles==0 or s.rcMutated,
    s'={...s,lease:true,snapshot:s.active.union(s.pending).union(s.receiverLists),
      snapshotVersion:s.domainVersion}
  }
  action finishGc=all {
    s.lease,s.mode!=3 or s.phase==4 or s.gcCycles==0,
    s'={...s,lease:false,gcCycles:s.gcCycles+1,livePtr:s.livePtr+1,
      rcPtr:if(s.bug==4 and s.gcCycles==1) s.rcPtr else s.livePtr+1,
      stillSetup:not(s.bug==5 and s.gcCycles==1)}
  }
  action mutateRcBetweenGc=all {
    Set(3,4).contains(s.phase),s.gcCycles==1,not(s.lease),not(s.rcMutated),
    s'={...s,rcMutated:true,livePtr:101,rcPtr:101}
  }
  action joinDonors=all {
    s.phase==3,s.gcCycles>=1,s.mode!=3 or s.lease,
    s'={...s,phase:4,joined:true}
  }
  action beginFinalize=all {
    s.phase==4,s.joined,s.gcCycles==2,not(s.lease),
    s'={...s,phase:5}
  }
  action installReceiver=all {
    s.phase==5,not(s.destination),s'={...s,destination:true}
  }
  // No collector can snapshot between list ownership transfer and registry removal.
  action moveDomain=all {
    s.phase==5,s.destination,not(s.lease),
    s'={...s,phase:6,receiverLists:donors,pending:Set(),domainVersion:s.domainVersion+1}
  }
  action freeSlot=all {
    s.phase==6,s.joined,s.destination,not(s.lease),
    s'={...s,phase:9,freed:true,carrier:false}
  }
  action abortOne= {
    nondet d=donors.oneOf()
    all {
      s.phase==7,not(s.abortAck.contains(d)),
      s'={...s,abortAck:s.abortAck.union(Set(d)),restored:s.restored.set(d,s.contVersion.get(d))}
    }
  }
  action finishAbort=all {
    s.phase==7,s.abortAck==donors,not(s.lease),
    s'={...s,phase:8,carrier:false}
  }
  action commitRaw=all {
    s.bug==1,s.phase==1,s.saved==donors,
    s'={...s,phase:3,active:Set(0),pending:donors,domainVersion:1}
  }
  action dropDomainGap=all {
    s.bug==2,s.phase==2,
    s'={...s,phase:3,active:Set(0),pending:Set()}
  }
  action duplicateOwner=all {
    s.bug==3,s.phase==2,s'={...s,pending:donors}
  }
  action restoreOldFrame=all {
    s.bug==6,s.phase==7,not(s.abortAck.contains(1)),
    s'={...s,abortAck:s.abortAck.union(Set(1)),restored:s.restored.set(1,0)}
  }
  action replayPrefix=all {
    s.bug==7,s.phase==7,s'={...s,cursor:s.cursor.set(1,0)}
  }
  action dropBeforeAbortAck=all {
    s.bug==8,s.phase==7,s.abortAck!=donors,s'={...s,carrier:false}
  }
  action removeDuringScan=all {
    s.bug==9,s.phase==4,s.lease,
    s'={...s,pending:Set(),domainVersion:s.domainVersion+1}
  }
  action removeBeforeReceiver=all {
    s.bug==10,s.phase==4,not(s.lease),s.gcCycles==2,
    s'={...s,pending:Set(),domainVersion:s.domainVersion+1}
  }
  action freeBeforeScanEnd=all {
    s.bug==11,s.phase==4,s.lease,s'={...s,freed:true}
  }
  action reuseBeforeAbortAck=all {
    s.bug==12,s.phase==7,s.abortAck!=donors,s'={...s,epoch:2}
  }
  val terminal=Set(8,9).contains(s.phase)
  action done=all {terminal,s'=s}
  action step=any {saveOne,materializeOne,donor2Fails,saveTwo,materializeTwo,commit,
    beginGc,finishGc,mutateRcBetweenGc,joinDonors,beginFinalize,installReceiver,
    moveDomain,freeSlot,abortOne,finishAbort,commitRaw,dropDomainGap,duplicateOwner,
    restoreOldFrame,replayPrefix,dropBeforeAbortAck,removeDuringScan,
    removeBeforeReceiver,freeBeforeScanEnd,reuseBeforeAbortAck,done}
  val safe=all {
    s.active.intersect(s.pending)==Set(),
    s.active.union(s.pending).union(s.receiverLists)==allOwners,
    s.pending==Set() or s.materialized==donors,
    not(s.lease) or (s.snapshot==allOwners and s.snapshotVersion==s.domainVersion and not(s.freed)),
    s.rcPtr==s.livePtr,s.stillSetup,
    s.executed.forall(d=>s.cursor.get(d)==1),
    s.abortAck.forall(d=>s.restored.get(d)==s.contVersion.get(d)),
    s.phase!=7 or (s.epoch==1 and (s.carrier or s.abortAck==donors)),
    s.phase!=8 or (s.active==allOwners and s.pending==Set() and s.abortAck==donors),
    s.carrier or s.destination or s.phase==8,
    not(s.freed) or (s.joined and s.destination and s.pending==Set() and not(s.lease))
  }
  temporal completion=weakFair(step,Set(s)).implies(eventually(terminal))
}
