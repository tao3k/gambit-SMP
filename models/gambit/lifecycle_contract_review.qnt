module lifecycle_contract_review {
  // Review supplement: one donor key, four operations (two epochs in each of
  // two campaigns). Root/GC implementation and native syscall are assumptions.
  type State = { mode:int, bug:int, round:int, phase:int, key:int, owner:int,
    incarnation:int, producer:int, calls:int, exited:bool, nativeZero:bool,
    published:bool, acquired:bool, pendingSeen:bool, debt:bool, roots:bool,
    grace:bool, transfers:int, frees:int, errno:int, gc:int, retained:bool,
    acceptedKey:int, acceptedOwner:int, acceptedIncarnation:int, acceptedProducer:int }
  var s:State
  pure def initial(mode:int,bug:int,round:int):State = {
    mode:mode,bug:bug,round:round,phase:0,key:round,owner:1,incarnation:round,
    producer:1,calls:0,exited:false,nativeZero:false,published:false,
    acquired:false,pendingSeen:false,debt:true,roots:true,grace:false,
    transfers:0,frees:0,errno:0,gc:0,retained:false,
    acceptedKey:0,acceptedOwner:0,acceptedIncarnation:0,acceptedProducer:0 }
  action initSuccess=s'=initial(0,0,1)
  action initRetainedError=s'=initial(1,0,1)
  action initPendingErrno=s'=initial(0,1,1)
  action initWrongOwner=s'=initial(0,2,1)
  action initWrongIncarnation=s'=initial(0,3,1)
  action initStaleKey=s'=initial(0,4,1)
  action initProducerDrift=s'=initial(0,5,1)
  action initNoAcquire=s'=initial(0,6,1)
  action initNoGrace=s'=initial(0,7,1)
  action initLoseRoot=s'=initial(0,8,1)
  action initDuplicateJoin=s'=initial(0,9,1)
  action initFakeZero=s'=initial(0,10,1)
  action initClearDebt=s'=initial(0,11,1)
  action initClearError=s'=initial(1,12,1)
  action claim=all {s.phase==0,s'={...s,phase:1,calls:1}}
  action pending=all {s.phase==1,not(s.pendingSeen),
    s'={...s,pendingSeen:true}}
  action scan=all {s.phase==1,s.pendingSeen,s.gc<2,
    s'={...s,gc:s.gc+1}}
  action exitWorker=all {s.phase==1,s.pendingSeen,s.gc==2,s.mode==0,
    s'={...s,phase:2,exited:true}}
  action joinZero=all {s.phase==2,s.exited,
    s'={...s,phase:3,nativeZero:true}}
  action publish=all {s.phase==3,s.nativeZero,
    s'={...s,phase:4,published:true}}
  action consume=all {s.phase==4,s.published,
    s'={...s,phase:5,acquired:true,acceptedKey:s.key,
      acceptedOwner:s.owner,acceptedIncarnation:s.incarnation,acceptedProducer:s.producer}}
  action drain=all {s.phase==5,s'={...s,phase:6,grace:true}}
  action transfer=all {s.phase==6,s'={...s,phase:7,transfers:1}}
  action reclaim=all {s.phase==7,s'={...s,phase:8,frees:1,debt:false}}
  action nextOperation=all {s.phase==8,s.round<4,s'=initial(s.mode,s.bug,s.round+1)}
  // Error is an explicit adapter-result assumption, never evidence of OS errno.
  action error=all {s.phase==1,s.mode==1,s.pendingSeen,s.gc==2,
    s'={...s,phase:9,retained:true,errno:5}}
  action mutant=any {
    all {s.bug==1,s.phase==1,s.pendingSeen,s'={...s,errno:11}},
    all {s.bug==2,s.phase==5,s'={...s,acceptedOwner:2}},
    all {s.bug==3,s.phase==5,s'={...s,acceptedIncarnation:0}},
    all {s.bug==4,s.phase==5,s'={...s,acceptedKey:0}},
    all {s.bug==5,s.phase==5,s'={...s,acceptedProducer:2}},
    all {s.bug==6,s.phase==5,s'={...s,acquired:false}},
    all {s.bug==7,s.phase==5,s'={...s,transfers:1}},
    all {s.bug==8,s.phase==1,s.pendingSeen,s'={...s,roots:false}},
    all {s.bug==9,s.phase==3,s'={...s,calls:2}},
    all {s.bug==10,s.phase==1,s.pendingSeen,s'={...s,nativeZero:true}},
    all {s.bug==11,s.phase==1,s.pendingSeen,s'={...s,debt:false}},
    all {s.bug==12,s.phase==9,s'={...s,debt:false,roots:false,errno:0}}
  }
  val terminal=(s.phase==8 and s.round==4) or s.phase==9
  action done=all {terminal,s'=s}
  action step=any {claim,pending,scan,exitWorker,joinZero,publish,consume,
    drain,transfer,reclaim,nextOperation,error,mutant,done}
  val safe=all {
    s.calls<=1,
    not(s.nativeZero) or s.exited,
    s.errno==0 or s.retained,
    s.phase==8 or s.debt,
    s.roots,
    s.phase<5 or s.phase==9 or all {s.published,s.acquired,
      s.acceptedKey==s.key,s.acceptedOwner==s.owner,
      s.acceptedIncarnation==s.incarnation,s.acceptedProducer==s.producer},
    s.transfers==0 or (s.nativeZero and s.grace and s.acquired),
    s.frees==0 or (s.transfers==1 and s.grace and s.nativeZero),
    not(s.retained) or (s.errno==5 and s.debt and s.roots and s.frees==0)
  }
  temporal completion=weakFair(step,Set(s)).implies(eventually(terminal))
}
