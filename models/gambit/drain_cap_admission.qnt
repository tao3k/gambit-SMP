module drain_cap_admission {
  // One scheduler-lock-held participant and one closing coordinator.
  // Atomic CAS and metadata reads are abstract actions, not a C11 memory model.
  type S={mode:int,bug:int,pc:int,ctl:int,n:int,gen:int,expected:int,snapshot:int,
    registered:bool,lookup:bool,comm:bool,writer:bool,extra:bool,
    waitRef:bool,waitCounted:bool,heldT:bool,threadRoot:bool,
    served:bool,rejected:bool,granted:bool,rotated:bool,
    ackState:int,payloadInit:bool,payloadGen:int,zeroSeen:bool,go:bool,
    seen:bool,newKeyInit:bool,rawRead:bool,mutexHeld:bool,hint:bool,pending:bool,polled:bool,capStep:int,spent:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,pc:0,
    ctl:if(Set(1,3,4,6,7,8,9,10).contains(m)) 1 else 0,n:0,gen:1,
    expected:if(m==2) 0 else 1,snapshot:0,registered:m!=3,
    lookup:false,comm:false,writer:false,extra:false,waitRef:false,waitCounted:false,
    heldT:true,threadRoot:true,served:false,rejected:false,granted:false,rotated:false,
    ackState:0,payloadInit:false,payloadGen:0,zeroSeen:false,go:false,seen:false,
    newKeyInit:false,rawRead:false,mutexHeld:m==6,hint:m!=8,pending:true,polled:false,capStep:if(m==9) 0 else 1,spent:m==10}
  action initBeforeClose=s'=initial(0,0)
  action initRegistered=s'=initial(1,0)
  action initStale=s'=initial(2,0)
  action initForged=s'=initial(3,0)
  action initOrdinaryClosed=s'=initial(4,0)
  action initModeAba=s'=initial(5,0)
  action initWrongStep=s'=initial(9,0)
  action initSpent=s'=initial(10,0)
  action initSkipStep=s'=initial(9,10)
  action initReuseSpent=s'=initial(10,11)
  action initCachedKey=s'=initial(5,1)
  action initSkipRegistration=s'=initial(3,2)
  action initUnpinnedRead=s'=initial(2,3)
  action initWeakAck=s'=initial(1,4)
  action initEarlyPut=s'=initial(1,5)
  action initResetCount=s'=initial(1,6)
  action initSealedEntry=s'=initial(1,7)
  action initReopenEarly=s'=initial(1,8)
  action initStaleAck=s'=initial(1,9)
  action initBlockingMutex=s'=initial(6,0)
  action initWaitCount=s'=initial(7,0)
  action initFlagOnly=s'=initial(8,0)
  action snapshotGate=all {s.pc==0,(s.mode!=8 or s.hint),s'={...s,pc:1,snapshot:s.ctl}}
  // OPEN/count0 can recur while a historical caller is descheduled.
  action otherRotation=all {s.mode==5,s.pc==1,s.n==0,not(s.rotated),
    s'={...s,gen:2,ctl:0,rotated:true}}
  action acquire=all {s.pc==1,not(s.mutexHeld),s.mode!=5 or s.rotated,
    s.ctl==0 or (s.ctl==1 and s.mode!=4),
    s'={...s,pc:2,n:s.n+1,lookup:true}}
  action rejectClosed=all {s.pc==1,s.mode==4,s.ctl==1,s'={...s,pc:11,rejected:true}}
  action validate=all {s.pc==2,
    (if(s.bug==1) s.expected==1 else s.expected==s.gen),
    s.registered or s.bug==2,(s.capStep==1 or s.bug==10),(not(s.spent) or s.bug==11),
    s'={...s,pc:3,lookup:false,comm:true,granted:true}}
  action rejectKey=all {s.pc==2,not(s.expected==s.gen and s.registered and s.capStep==1 and not(s.spent)),
    not(Set(1,2,10,11).contains(s.bug)),s'={...s,pc:11,lookup:false,n:s.n-1,rejected:true}}
  // Close preserves the count of a call already accepted in OPEN.
  action close=all {s.mode==0,s.ctl==0,s.pc>=2,s.pc<11,s'={...s,ctl:1}}
  action nativeService=all {s.pc==3,s.ctl==1,
    s'={...s,pc:4,comm:false,n:s.n-1,served:true}}
  action ackEnter=all {s.pc==4,s.ctl==1,s.registered,s.expected==s.gen,
    s'={...s,pc:5,n:s.n+1,writer:true,ackState:1}}
  action publishAck=all {s.pc==5,s'={...s,pc:6,ackState:2,payloadInit:true,
    payloadGen:s.gen,waitRef:true,waitCounted:s.mode==7,
    n:if(s.mode==7) s.n+1 else s.n}}
  action seal=all {s.ctl==1,s.ackState==2,s'={...s,ctl:2}}
  action writerEnd=all {s.pc==6,s.writer,s'={...s,pc:7,writer:false,n:s.n-1}}
  action zero=all {s.pc==7,s.ctl==2,s.n==0,s'={...s,pc:8,zeroSeen:true}}
  action publishGo=all {s.pc==8,s.ctl==2,s'={...s,pc:9,go:true}}
  action observeGo=all {s.pc==9,s.go,s'={...s,pc:10,seen:true}}
  action prepareNewKey=all {s.pc==10,not(s.newKeyInit),s'={...s,newKeyInit:true}}
  action reopen=all {s.pc==10,s.newKeyInit,s'={...s,pc:12,gen:2,ctl:0}}
  // A completion reader outlives reopening and is not a communication user.
  action dropWait=all {s.pc==12,s.waitRef,not(s.waitCounted),s'={...s,waitRef:false}}
  action unlockCoordinator=all {s.mutexHeld,s.served,s'={...s,mutexHeld:false}}
  action pollMiss=all {s.mode==8,s.pc==0,not(s.polled),s'={...s,polled:true}}
  action mutant=any {
    all {s.bug==3,s.pc==1,not(s.lookup),s'={...s,rawRead:true}},
    all {s.bug==4,s.pc==5,s'={...s,pc:6,ackState:2,payloadInit:false,waitRef:true}},
    all {s.bug==5,s.pc==3,s.comm,s'={...s,n:0}},
    all {s.bug==6,s.ctl==1,s.n>0,s'={...s,n:0}},
    all {s.bug==7,s.pc==8,s'={...s,n:1,extra:true}},
    all {s.bug==8,s.pc==10,not(s.newKeyInit),s'={...s,pc:12,ctl:0}},
    all {s.bug==9,s.pc==6,s'={...s,payloadGen:0}}
  }
  action idle=s'=s
  action step=any {snapshotGate,otherRotation,acquire,rejectClosed,validate,rejectKey,
    close,nativeService,ackEnter,publishAck,seal,writerEnd,zero,publishGo,observeGo,
    prepareNewKey,reopen,dropWait,unlockCoordinator,pollMiss,mutant,idle}
  pure def bit(b:bool):int=if(b) 1 else 0
  val safe=all {s.n==bit(s.lookup)+bit(s.comm)+bit(s.writer)+bit(s.extra)+bit(s.waitCounted),
    s.heldT,s.threadRoot,not(s.rawRead),
    not(s.granted) or (s.registered and s.capStep==1 and not(s.spent) and (s.pc==12 or s.expected==s.gen)),
    s.ackState!=2 or (s.payloadInit and s.payloadGen==s.expected),
    not(s.go) or (s.zeroSeen and s.n==0),
    s.pc!=12 or (s.newKeyInit and s.gen==2 and s.seen)}
  val goal=if(Set(2,3,4,5,9,10).contains(s.mode)) s.pc==11 and s.rejected and s.n==0
    else s.pc==12 and s.served and s.ctl==0
  temporal fairness=all {weakFair(snapshotGate,Set(s)),weakFair(otherRotation,Set(s)),
    weakFair(acquire,Set(s)),weakFair(rejectClosed,Set(s)),weakFair(validate,Set(s)),
    weakFair(rejectKey,Set(s)),weakFair(close,Set(s)),weakFair(nativeService,Set(s)),
    weakFair(ackEnter,Set(s)),weakFair(publishAck,Set(s)),weakFair(seal,Set(s)),
    weakFair(writerEnd,Set(s)),weakFair(zero,Set(s)),weakFair(publishGo,Set(s)),
    weakFair(observeGo,Set(s)),weakFair(prepareNewKey,Set(s)),weakFair(reopen,Set(s)),
    weakFair(dropWait,Set(s)),weakFair(unlockCoordinator,Set(s)),weakFair(pollMiss,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
}
