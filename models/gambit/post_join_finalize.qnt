module post_join_finalize {
  // Joined donor, two independently transferable resource classes: still1, RC2.
  // Each splice+owner/log update is an indivisible non-failing C refinement unit.
  // Failures occur ONLY at explicit boundaries; arbitrary mid-write escape is
  // excluded, not repaired by the journal. No native syscall is modeled.
  type State={mode:int,bug:int,phase:int,closed:bool,readers:int,
    exclusive:bool,pin:bool,domain:bool,carrier:bool,destRoots:bool,
    moved:Set[int],intent:Set[int],owners:int->int,recvWords:int,donorWords:int,
    calls:int,transfers:int->int,lockReady:bool,destroyed:bool,
    freed:bool,retained:bool,failed:bool,uncertain:bool,gc:int,callback:bool}
  var s:State
  val resources=Set(1,2)
  pure def initial(mode:int,bug:int):State={
    mode:mode,bug:bug,phase:0,closed:false,readers:1,exclusive:false,
    pin:true,domain:true,carrier:true,destRoots:false,moved:Set(),intent:Set(),
    owners:Map(1->0,2->0),recvWords:0,donorWords:2,calls:1,
    transfers:Map(1->0,2->0),lockReady:true,destroyed:false,
    freed:false,retained:false,failed:false,uncertain:false,gc:0,callback:false}
  action initSuccess=s'=initial(0,0)
  action initPreflightRefusal=s'=initial(1,0)
  action initPartialRollForward=s'=initial(2,0)
  action initDestroyFailure=s'=initial(3,0)
  action initUnlockUncertain=s'=initial(4,0)
  action initHeldReader=s'=initial(5,0)
  action initEarlyDomainRemove=s'=initial(0,1)
  action initDoubleSplice=s'=initial(2,2)
  action initDoubleAccount=s'=initial(2,3)
  action initErasePartialLog=s'=initial(2,4)
  action initIgnoreDestroyFailure=s'=initial(3,5)
  action initDropFinalizerPin=s'=initial(0,6)
  action initTransferWithReader=s'=initial(0,7)
  action initCallbackInCleanup=s'=initial(0,8)
  action initRejoinAfterPartial=s'=initial(2,9)
  action initResumeAfterUnknownUnlock=s'=initial(4,10)
  action initDropCarrierBeforeDest=s'=initial(0,11)
  action initCommitWithoutIntent=s'=initial(0,12)
  action closeAdmission=all {s.phase==0,not(s.closed),s'={...s,closed:true}}
  action readerExit=all {s.phase==0,s.closed,s.readers==1,s.mode!=5,
    s'={...s,readers:0}}
  action enterWindow=all {s.phase==0,s.closed,s.readers==0,
    s'={...s,phase:1,exclusive:true}}
  action preflightRefuse=all {s.phase==1,s.mode==1,
    s'={...s,phase:8,retained:true,exclusive:false,failed:true}}
  action planStill=all {s.phase==1,s.mode!=1,not(s.intent.contains(1)),
    s'={...s,intent:s.intent.union(Set(1))}}
  action moveStill=all {s.phase==1,s.intent.contains(1),
    s'={...s,phase:2,moved:Set(1),owners:s.owners.set(1,1),recvWords:1,
      donorWords:1,transfers:s.transfers.set(1,1),destRoots:true}}
  action partialPause=all {s.phase==2,s.mode==2,not(s.failed),
    s'={...s,retained:true,failed:true,exclusive:false}}
  action resumePartial=all {s.phase==2,s.retained,s.mode==2,
    s'={...s,retained:false,exclusive:true}}
  action planRc=all {s.phase==2,s.exclusive,not(s.retained),
    s.mode!=2 or s.failed,not(s.intent.contains(2)),
    s'={...s,intent:s.intent.union(Set(2))}}
  action moveRc=all {s.phase==2,s.exclusive,s.intent.contains(2),
    s'={...s,phase:3,moved:resources,owners:s.owners.set(2,1),
      recvWords:2,donorWords:0,transfers:s.transfers.set(2,1)}}
  action removeDomain=all {s.phase==3,s.moved==resources,
    s'={...s,phase:4,domain:false,carrier:false}}
  action leaveWindow=all {s.phase==4,s.exclusive,s.mode!=4,
    s'={...s,exclusive:false}}
  action uncertainUnlock=all {s.phase==4,s.exclusive,s.mode==4,
    s'={...s,phase:8,uncertain:true,retained:true,failed:true}}
  action destroy=all {s.phase==4,not(s.exclusive),s.mode!=3,
    s'={...s,phase:5,lockReady:false,destroyed:true}}
  action destroyFail=all {s.phase==4,not(s.exclusive),s.mode==3,
    s'={...s,phase:8,retained:true,failed:true}}
  action reclaim=all {s.phase==5,s.destroyed,
    s'={...s,phase:6,freed:true,pin:false}}
  action retainReader=all {s.phase==0,s.mode==5,s.closed,s.readers==1,
    s'={...s,phase:8,retained:true}}
  action collect=all {not(s.exclusive),not(s.uncertain),s.gc<2,
    s'={...s,gc:s.gc+1}}
  action mutant=any {
    all {s.bug==1,s.phase==2,s'={...s,domain:false}},
    all {s.bug==2,s.phase==2,s.failed,s'={...s,transfers:s.transfers.set(1,2)}},
    all {s.bug==3,s.phase==2,s.failed,s'={...s,recvWords:2}},
    all {s.bug==4,s.phase==2,s.failed,s'={...s,moved:Set()}},
    all {s.bug==5,s.phase==8,s.failed,s.mode==3,s'={...s,freed:true,lockReady:false}},
    all {s.bug==6,s.phase==4,s'={...s,pin:false}},
    all {s.bug==7,s.phase==0,s.readers==1,s'={...s,moved:Set(1),owners:s.owners.set(1,1)}},
    all {s.bug==8,s.phase==4,s'={...s,callback:true}},
    all {s.bug==9,s.phase==2,s.failed,s'={...s,calls:2}},
    all {s.bug==10,s.uncertain,s'={...s,exclusive:false}},
    all {s.bug==11,s.phase==1,s'={...s,carrier:false}},
    all {s.bug==12,s.phase==1,s'={...s,moved:Set(1)}}
  }
  val terminal=Set(6,8).contains(s.phase)
  action done=all {terminal,s'=s}
  action step=any {closeAdmission,readerExit,enterWindow,preflightRefuse,
    planStill,moveStill,partialPause,resumePartial,planRc,moveRc,removeDomain,
    leaveWindow,uncertainUnlock,destroy,destroyFail,reclaim,retainReader,
    collect,mutant,done}
  val safe=all {
    s.calls==1,not(s.callback),
    s.moved.subseteq(s.intent),
    resources.forall(r=> (s.owners.get(r)==1)==s.moved.contains(r)),
    resources.forall(r=> s.transfers.get(r)<=1),
    s.recvWords==s.moved.size(),s.recvWords+s.donorWords==2,
    s.moved==Set() or s.readers==0,
    resources.forall(r=>s.owners.get(r)==1 or s.domain),
    s.carrier or s.destRoots,
    s.freed or s.pin,
    not(s.freed) or (s.destroyed and not(s.lockReady) and not(s.domain) and s.moved==resources),
    not(s.destroyed) or (not(s.exclusive) and s.readers==0),
    not(s.uncertain) or (s.exclusive and s.retained and not(s.freed))
  }
  temporal completion=weakFair(step,Set(s)).implies(eventually(terminal))
}
