module integrated_growth {
  // Two staged slots, two overlapping request publishers, two transaction epochs.
  // phase: 0 idle,1 shells,2 private,3 built,4 count committed,5 GO/startup,
  // 6 OPEN,7 DRAINING,8 complete,9 ABORT,10 old stable,11 retained fault.
  type State={mode:int,bug:int,phase:int,epoch:int,created:Set[int],parked:Set[int],
    go:Set[int],bound:Set[int],ran:Set[int],ready:Set[int],aborted:Set[int],
    exited:Set[int],joined:Set[int],cleaned:Set[int],joinFault:bool,nativeFault:bool,
    held:bool,views:Set[int],usedNodes:Set[int],excluded:bool,committed:bool,assigned:int,cursor:int,
    stacks:int,base:int,members:Set[int],publicOpen:bool,grantReady:bool,
    req:int->int,leases:Set[int],queue:Set[int],wake:Set[int],accepted:Set[int],
    done:Set[int],grantGen:int->int,wanted:int->int,carrier:bool,freed:bool,controlFreed:bool,
    primaryDone:bool,hintDebt:bool,ackOld:bool,grace:bool,oldGc:bool,gcBeat:bool,
    staleRead:bool,demand:int,cut:int,ack:int,extraDebt:bool,cancelRefused:bool,
    boot:int,bootMode:int,bootEpoch:int,askedVm:int,askedSlot:int,identityBound:bool,
    bootVm:int,bootSlot:int,bootRes:Set[int],bootEver:Set[int],bootDestroyed:Set[int],
    bootReady:bool,bootRoots:bool,bootOpen:bool,bootPin:bool,bootBorrow:bool,
    bootGrantKey:int,bootOpenKey:int,bootErr:int,bootHadError:bool,bootRepeated:bool,
    bootDeniedClosed:bool,bootDeniedReady:bool,bootGranted:bool,
    invalidLookup:bool,doubleDestroy:bool,doubleInit:bool,bootReturnPending:bool,
    ticketMode:int,ticketStage:int,ticketEpoch:int,ticketNonce:int,recordLive:bool,
    guardReady:bool,guardHeld:bool,scopeId:int,contextReader:bool,
    entryDenied:bool,recursiveDenied:bool,nestedDenied:bool,staleDenied:bool,
    nestedDone:bool,scopeViolation:bool,stackRecord:bool,
    mapMode:int,bridge:int,mappedLanding:bool,registersSpilled:bool,
    nativeBridge:bool,rootVersion:int,cachedVersion:int,rootUsed:bool,gcInside:bool,
    slotPayload:int,slotRelease:bool,registryRelease:bool,registryAcquire:bool,
    lockBorrow:bool,lockAlive:bool,tailLive:bool,tailSeen:bool}
  var s:State
  val slots=Set(2,3)
  val old=Set(0,1)
  val ids=Set(1,2)
  pure def initial(m:int,b:int):State={mode:m,bug:b,phase:0,epoch:1,created:Set(),
    parked:Set(),go:Set(),bound:Set(),ran:Set(),ready:Set(),aborted:Set(),exited:Set(),
    joined:Set(),cleaned:Set(),joinFault:false,nativeFault:false,held:false,views:Set(),usedNodes:Set(),
    excluded:false,committed:false,assigned:5,cursor:5,stacks:2,base:5,members:old,
    publicOpen:false,grantReady:true,req:Map(1->0,2->0),leases:Set(),queue:Set(),
    wake:Set(),accepted:Set(),done:Set(),grantGen:Map(1->0,2->0),wanted:Map(1->1,2->1),
    carrier:false,freed:false,controlFreed:false,primaryDone:false,hintDebt:true,ackOld:false,grace:false,
    oldGc:false,gcBeat:false,staleRead:false,demand:0,cut:0,ack:0,extraDebt:false,cancelRefused:false,
    boot:0,bootMode:0,bootEpoch:1,askedVm:1,askedSlot:0,identityBound:false,
    bootVm:0,bootSlot:0,bootRes:Set(),bootEver:Set(),bootDestroyed:Set(),
    bootReady:false,bootRoots:false,bootOpen:false,bootPin:false,bootBorrow:false,
    bootGrantKey:0,bootOpenKey:0,bootErr:0,bootHadError:false,bootRepeated:false,
    bootDeniedClosed:false,bootDeniedReady:false,bootGranted:false,
    invalidLookup:false,doubleDestroy:false,doubleInit:false,bootReturnPending:false,
    ticketMode:0,ticketStage:0,ticketEpoch:0,ticketNonce:0,recordLive:false,
    guardReady:true,guardHeld:false,scopeId:0,contextReader:false,
    entryDenied:false,recursiveDenied:false,nestedDenied:false,staleDenied:false,
    nestedDone:false,scopeViolation:false,stackRecord:false,
    mapMode:0,bridge:0,mappedLanding:false,registersSpilled:false,
    nativeBridge:false,rootVersion:0,cachedVersion:0,rootUsed:false,gcInside:false,
    slotPayload:0,slotRelease:false,registryRelease:false,registryAcquire:false,
    lockBorrow:false,lockAlive:false,tailLive:false,tailSeen:false}
  action initSuccess=s'=initial(0,0)
  action initCreatePrefix=s'=initial(1,0)
  action initPartialViews=s'=initial(2,0)
  action initBlockedJoin=s'=initial(3,0)
  action initNativeCloseFault=s'=initial(4,0)
  action initHeldPublisher=s'=initial(5,0)
  action initAbortRetry=s'=initial(6,0)
  action initGateDeadline=s'=initial(7,0)
  action initStartupFailure=s'=initial(9,0)
  action initEarlyOpen=s'=initial(0,1)
  action initEarlyBind=s'=initial(0,2)
  action initEagerAllocator=s'=initial(2,3)
  action initGcDuringPrivate=s'=initial(0,4)
  action initFreeBeforeJoin=s'=initial(1,5)
  action initDropPrimaryOnHintDenial=s'=initial(0,6)
  action initCheckThenPin=s'=initial(0,7)
  action initRevokePriorLease=s'=initial(0,8)
  action initForgetQueueLease=s'=initial(0,9)
  action initForgetWakeLease=s'=initial(0,10)
  action initReuseRetained=s'=initial(3,11)
  action initStaleEpochGo=s'=initial(6,12)
  action initDebtReset=s'=initial(6,13)
  action initStaleThunk=s'=initial(0,14)
  action initPostGoRollback=s'=initial(0,15)
  action initAckFutureDebt=s'=initial(0,16)
  action initForeignHeapNode=s'=initial(0,18)
  action initReusedSectionPair=s'=initial(0,19)
  action initMissingGateDeadline=s'=initial(8,0)
  action initAssumeJoinRecovers=s'=initial(3,0)
  action initStopJoinLaneAfterResume=s'=initial(3,17)
  action begin=all {s.phase==0,s.boot==6,s.bootOpen,s.bootGranted,not(s.bootBorrow),
    not(Set(1,10).contains(s.bootMode)) or s.bootRepeated,
    not(Set(9,11).contains(s.bootMode)) or s.bootEpoch==2,s'={...s,phase:1,carrier:true,demand:s.demand+1}}
  action create(p:int):bool=all {s.phase==1,not(s.created.contains(p)),
    p==2 or s.created.contains(2),not(Set(1).contains(s.mode) and p==3),
    s'={...s,created:s.created.union(Set(p))}}
  action park(p:int):bool=all {s.phase==1,s.created.contains(p),not(s.parked.contains(p)),
    not(Set(7,8).contains(s.mode) and p==3),s'={...s,parked:s.parked.union(Set(p))}}
  action earlyGc=all {Set(1,10,11).contains(s.phase),not(s.held),s.views==Set(),
    s'={...s,gcBeat:not(s.gcBeat),oldGc:true}}
  action reserve=all {s.phase==1,s.parked==slots,
    s'={...s,phase:2,held:true,excluded:true,base:s.assigned}}
  action buildFirst=all {s.phase==2,s.views==Set(),s'={...s,views:Set(2),usedNodes:Set(6,7)}}
  action buildRest=all {s.phase==2,s.views==Set(2),
    not(Set(2,3,4,6).contains(s.mode) and s.epoch==1),s'={...s,phase:3,views:slots,usedNodes:Set(6,7,8,9)}}
  action abort=all {not(s.committed),any {
    s.phase==1 and s.mode==1 and s.parked==Set(2),
    s.phase==1 and s.mode==7 and s.created==slots and s.parked==Set(2),
    s.phase==2 and s.views==Set(2) and Set(2,3,4,6).contains(s.mode) and s.epoch==1},
    // Views cease to be accessible BEFORE old GC exclusion ends; shells cannot GO.
    s'={...s,phase:9,aborted:s.created,views:Set(),usedNodes:Set(),held:false,excluded:false}}
  action exitShell(p:int):bool=all {Set(9,10,11).contains(s.phase),
    s.bug!=17 or s.phase==9,s.aborted.contains(p),not(s.exited.contains(p)),
    s'={...s,exited:s.exited.union(Set(p))}}
  action joinShell(p:int):bool=all {Set(9,10,11).contains(s.phase),
    s.bug!=17 or s.phase==9,s.exited.contains(p),not(s.joined.contains(p)),
    not(s.mode==3 and p==2),s'={...s,joined:s.joined.union(Set(p))}}
  action joinError=all {s.phase==9,s.mode==3,s.exited.contains(2),not(s.joinFault),
    s'={...s,joinFault:true}}
  action cleanup(p:int):bool=all {Set(9,10,11).contains(s.phase),
    s.bug!=17 or s.phase==9,s.joined.contains(p),not(s.cleaned.contains(p)),
    s.mode!=4,s'={...s,cleaned:s.cleaned.union(Set(p))}}
  action cleanupError=all {s.phase==9,s.mode==4,s.joined==s.created,not(s.nativeFault),
    s'={...s,nativeFault:true}}
  action oldAgreement=all {s.phase==9,not(s.ackOld),s'={...s,ackOld:true}}
  action readerGrace=all {s.phase==9,s.ackOld,not(s.grace),s'={...s,grace:true}}
  action oldResume=all {s.phase==9,s.ackOld,s.grace,
    (s.cleaned==s.created or s.joinFault or s.nativeFault),
    s'={...s,phase:if(s.joinFault or s.nativeFault) 11 else 10}}
  action oldPrimary=all {Set(10,11).contains(s.phase),not(s.primaryDone),
    s'={...s,primaryDone:true,hintDebt:false}}
  action commit=all {s.phase==3,s.parked==slots,s.held,s.excluded,
    s'={...s,phase:4,committed:true,held:false,views:Set(),usedNodes:Set(),assigned:s.base+4,
      cursor:s.base+4,stacks:4,members:old.union(slots),excluded:false}}
  action publishGo(p:int):bool=all {Set(4,5).contains(s.phase),not(s.go.contains(p)),
    s'={...s,phase:5,go:s.go.union(Set(p))}}
  action bind(p:int):bool=all {s.phase==5,s.go.contains(p),not(s.bound.contains(p)),
    s'={...s,bound:s.bound.union(Set(p))}}
  action startupGc=all {s.phase==5,s.bound==slots,s'={...s,gcBeat:not(s.gcBeat)}}
  action runScheme(p:int):bool=all {s.phase==5,s.bound==slots,not(s.ran.contains(p)),not(s.mode==9 and p==3),
    // Model fresh typed-carrier resolve after startup collective. No cached raw SCMOBJ.
    s'={...s,ran:s.ran.union(Set(p))}}
  action startupError=all {s.phase==5,s.mode==9,s.ran.contains(2),
    s'={...s,phase:11,nativeFault:true}}
  action publishReady(p:int):bool=all {s.phase==5,s.ran.contains(p),not(s.ready.contains(p)),
    s'={...s,ready:s.ready.union(Set(p))}}
  action open=all {s.phase==5,s.ready==slots,s'={...s,phase:6,publicOpen:true}}
  action acquire(r:int):bool=all {s.phase>0,s.req.get(r)==0,
    val ok=s.publicOpen and s.wanted.get(r)==s.epoch
    s'={...s,req:s.req.set(r,if(ok) 1 else 4),
      leases:if(ok) s.leases.union(Set(r)) else s.leases,
      grantGen:s.grantGen.set(r,if(ok) s.epoch else 0),
      grantReady:s.grantReady and (not(ok) or s.ready==slots)}}
  action refresh(r:int):bool=all {s.phase==6,s.req.get(r)==4,
    s'={...s,req:s.req.set(r,0),wanted:s.wanted.set(r,s.epoch)}}
  action publish(r:int):bool=all {s.leases.contains(r),s.req.get(r)==1,
    Set(6,7).contains(s.phase),s.grantGen.get(r)==s.epoch,
    s'={...s,req:s.req.set(r,2),accepted:s.accepted.union(Set(r)),
      queue:s.queue.union(Set(r)),wake:s.wake.union(Set(r))}}
  action release(r:int):bool=all {s.leases.contains(r),s.req.get(r)>=2,
    not(s.mode==5 and r==2),s'={...s,leases:s.leases.exclude(Set(r))}}
  action drain(r:int):bool=all {s.queue.contains(r),
    s'={...s,queue:s.queue.exclude(Set(r)),done:s.done.union(Set(r)),req:s.req.set(r,3),
      primaryDone:s.primaryDone or r==1,hintDebt:if(r==1) false else s.hintDebt}}
  action wakeDone(r:int):bool=all {s.wake.contains(r),s'={...s,wake:s.wake.exclude(Set(r))}}
  action close=all {s.phase==6,ids.forall(r=>s.req.get(r)==1 or s.accepted.contains(r)),s'={...s,phase:7,publicOpen:false}}
  action retainedPublisher=all {s.phase==7,s.mode==5,s.done==ids,s.wake==Set(),
    s.leases==Set(2),s'={...s,phase:11,nativeFault:true}}
  action debtCut=all {Set(6,7,10,11).contains(s.phase),s.cut==s.ack,s.ack<s.demand,
    s'={...s,cut:s.demand}}
  action newDebt=all {s.cut>s.ack,not(s.extraDebt),
    s'={...s,demand:s.demand+1,extraDebt:true}}
  action serviceAck=all {s.cut>s.ack,s'={...s,ack:s.cut}}
  action finalize=all {s.phase==7,s.done==ids,s.leases==Set(),s.queue==Set(),s.wake==Set(),
    s.ack==s.demand,s'={...s,phase:8,carrier:false,freed:true}}
  action freeAborted=all {s.phase==10,s.cleaned==s.created,s.primaryDone,s.ack==s.demand,
    s.carrier,s'={...s,carrier:false,freed:true,controlFreed:true}}
  action retry=all {s.mode==6,s.epoch==1,s.phase==10,s.freed,s.oldGc,s.ack==s.demand,
    s'={...s,phase:0,epoch:2,created:Set(),parked:Set(),go:Set(),bound:Set(),ran:Set(),
      ready:Set(),aborted:Set(),exited:Set(),joined:Set(),cleaned:Set(),carrier:false,
      freed:false,controlFreed:false,ackOld:false,grace:false,extraDebt:false,oldGc:false,req:Map(1->0,2->0),
      primaryDone:false,hintDebt:true}}
  action cancel=all {s.committed,not(s.cancelRefused),s'={...s,cancelRefused:true}}
  action bad=any {
    all {s.bug==1,s.phase==4,s'={...s,publicOpen:true,grantReady:false}},
    all {s.bug==2,s.phase==1,s.parked.contains(2),s'={...s,bound:Set(2)}},
    all {s.bug==3,s.phase==2,s.views!=Set(),s'={...s,assigned:s.assigned+2}},
    all {s.bug==4,s.held,s'={...s,excluded:false}},
    all {s.bug==5,s.phase==9,s.joined!=s.created,s'={...s,controlFreed:true}},
    all {s.bug==6,s.req.get(1)==4,not(s.primaryDone),s'={...s,hintDebt:false}},
    all {s.bug==7,s.phase==7,s'={...s,leases:s.leases.union(Set(1)),grantGen:s.grantGen.set(1,0)}},
    all {s.bug==8,s.phase==7,s.req.get(2)==1,s'={...s,leases:s.leases.exclude(Set(2))}},
    all {s.bug==9,s.queue!=Set(),s.leases==Set(),s'={...s,freed:true,carrier:false}},
    all {s.bug==10,s.wake!=Set(),s.queue==Set(),s.leases==Set(),s'={...s,freed:true,carrier:false}},
    all {s.bug==11,s.phase==11,s.joinFault,s'={...s,epoch:2}},
    all {s.bug==12,s.epoch==2,s.phase==1,s'={...s,go:Set(2)}},
    all {s.bug==13,s.phase==9,s'={...s,ack:0,demand:0,cut:1}},
    all {s.bug==14,s.phase==5,s.bound==slots,s'={...s,staleRead:true}},
    all {s.bug==15,s.go!=Set(),s'={...s,assigned:s.base,members:old}},
    all {s.bug==16,s.cut>s.ack,s.demand>s.cut,s'={...s,ack:s.demand}},
    all {s.bug==18,s.phase==2,s.views==Set(2),s'={...s,usedNodes:Set(6,99)}},
    all {s.bug==19,s.phase==2,s.views==Set(2),s'={...s,views:slots}}
  }
  action idle=s'=s

  // Bootstrap:0 fresh,1 identity,2 slot mutex,3 native mutexes,4 CLOSED native,
  // 5 Scheme READY but CLOSED,6 OPEN,7 prefix cleanup,8 retained,9 clean,10 DRAINING.
  pure def bootInitial(m:int,b:int):State={...initial(0,b),bootMode:m,
    askedVm:if(m==2) 2 else 1,askedSlot:if(m==3) 128 else 0}
  action initBootstrapRepeatOpen=s'=bootInitial(1,0)
  action initBootstrapWrongVm=s'=bootInitial(2,0)
  action initBootstrapWrongSlot=s'=bootInitial(3,0)
  action initBootstrapSlotFail=s'=bootInitial(4,0)
  action initBootstrapProcFail=s'=bootInitial(5,0)
  action initBootstrapLateFail=s'=bootInitial(6,0)
  action initBootstrapCleanupFault=s'=bootInitial(7,0)
  action initBootstrapRepeatRetained=s'=bootInitial(8,0)
  action initBootstrapRetryClean=s'=bootInitial(9,0)
  action initBootstrapRepeatClosed=s'=bootInitial(10,0)
  action initBootstrapTeardownSetup=s'=bootInitial(11,0)
  action initBootstrapOpenFail=s'=bootInitial(12,0)
  action initBootstrapRootDropOnOpenFail=s'=bootInitial(12,30)
  action initBootstrapLookupBeforeBind=s'=bootInitial(0,20)
  action initBootstrapAliasP0=s'=bootInitial(2,21)
  action initBootstrapOpenBeforeReady=s'=bootInitial(0,22)
  action initBootstrapDestroyUninitialized=s'=bootInitial(5,23)
  action initBootstrapDoubleDestroy=s'=bootInitial(6,24)
  action initBootstrapResetLive=s'=bootInitial(1,25)
  action initBootstrapForgetRetained=s'=bootInitial(8,26)
  action initBootstrapEraseError=s'=bootInitial(5,27)
  action initBootstrapDoubleInit=s'=bootInitial(10,28)
  action initBootstrapGrowthBeforeOpen=s'=bootInitial(0,29)
  // Private ticket stages: reserve -> VM delegate -> P0 delegate -> original
  // C/Scheme scope -> P0 certificate consumed -> original return -> record retired.
  // guardReady is a process-lifetime POSIX static initializer, not a slot mutex.
  pure def ticketInitial(t:int,b:int):State={...initial(0,b),ticketMode:t}
  action initTicketConcurrent=s'=ticketInitial(1,0)
  action initTicketRecursive=s'=ticketInitial(2,0)
  action initTicketNested=s'=ticketInitial(3,0)
  action initTicketStaleNonce=s'=ticketInitial(4,0)
  action initTicketRetained=s'={...bootInitial(7,0),ticketMode:3}
  action initTicketOpenReturn=s'={...bootInitial(12,0),ticketMode:3}
  action initTicketRenewal=s'={...bootInitial(11,0),ticketMode:4}
  action initTicketGuardUninitialized=s'=ticketInitial(0,31)
  action initTicketGuardAcrossScheme=s'=ticketInitial(0,32)
  action initTicketConcurrentReset=s'=ticketInitial(1,33)
  action initTicketRecursiveReuse=s'=ticketInitial(2,34)
  action initTicketNestedAuthority=s'=ticketInitial(3,35)
  action initTicketStaleDelegate=s'=ticketInitial(4,36)
  action initTicketDropContext=s'={...bootInitial(12,37),ticketMode:3}
  action initTicketStackRecord=s'={...bootInitial(7,38),ticketMode:3}
  action initTicketEarlyRenewal=s'={...bootInitial(11,39),ticketMode:4}
  // A compiler-owned landing (not W_ALL alone), two moving GCs/reloads,
  // a non-GC native call, release/acquire publication, and C finalizer tail.
  action initMappedReady=s'={...initial(0,0),mapMode:1}
  action initMappedOpenFailure=s'={...bootInitial(12,0),mapMode:2}
  action initMappedTailFailure=s'={...bootInitial(12,0),mapMode:3}
  action initMappedRenewal=s'={...bootInitial(11,0),mapMode:1}
  action initDeclaredNotSpilled=s'=initial(0,40)
  action initSpillWithoutMap=s'={...initial(0,41),mapMode:1}
  action initGcInsideBridge=s'=initial(0,42)
  action initUseBeforeReload=s'={...initial(0,43),mapMode:1}
  action initPublishBeforeSlotRelease=s'=initial(0,44)
  action initObserveWithoutAcquire=s'=initial(0,45)
  action initDestroyBorrowedMutex=s'=initial(0,46)
  action initDropPinBeforeTail=s'={...bootInitial(12,47),mapMode:3}
  action initThrowWithNativeBorrow=s'={...bootInitial(12,48),mapMode:2}
  action initEraseObligationsOnReturn=s'={...bootInitial(12,50),mapMode:3}
  action initRenewBeforeTail=s'={...bootInitial(11,49),mapMode:1}
  action bridgeMap=all {s.boot==5,s.bridge==0,s.scopeId==1,
    s'={...s,bridge:1,mappedLanding:true,registersSpilled:true}}
  action bridgeGc=all {s.boot==5,s.bridge==1,Set(1,2).contains(s.mapMode),
    s.rootVersion<2,s.mappedLanding,s.registersSpilled,
    s'={...s,rootVersion:s.rootVersion+1}}
  action bridgeReload=all {s.boot==5,s.bridge==1,s.cachedVersion!=s.rootVersion,
    s'={...s,cachedVersion:s.rootVersion}}
  action bridgeEnter=all {s.boot==5,s.bridge==1,s.mappedLanding,s.registersSpilled,
    not(Set(1,2).contains(s.mapMode)) or s.rootVersion==2,
    s.cachedVersion==s.rootVersion,s.lockAlive,
    // The registry borrow is obtained under its guard before taking the slot.
    // No native lock is held during the modeled Scheme GC/reload.
    s'={...s,bridge:2,nativeBridge:true,lockBorrow:true,rootUsed:true}}
  action bridgeSlot=all {s.bridge==2,s.nativeBridge,s.lockBorrow,
    s'={...s,bridge:3,slotPayload:if(s.bootMode==12) 0 else s.bootEpoch}}
  action bridgeSlotUnlock=all {s.bridge==3,
    s'={...s,bridge:4,slotRelease:true}}
  action bridgeRegistryPublish=all {s.bridge==4,s.slotRelease,
    s'={...s,bridge:5,registryRelease:true}}
  action bridgeRegistryObserve=all {Set(5,7).contains(s.bridge),s.registryRelease,
    s.recordLive,not(s.registryAcquire),s.mapMode!=3 or s.bridge==7,
    s'={...s,registryAcquire:true}}
  action bridgeLeave=all {s.bridge==5,s.registryRelease,
    // Returned fixnum is scalar; this step is normal C return and R_ALL.
    s'={...s,bridge:7,nativeBridge:false,lockBorrow:false,cachedVersion:s.rootVersion}}
  action bridgeTailObserve=all {s.mapMode==3,s.tailLive,not(s.contextReader),
    s.boot==7,not(s.tailSeen),s'={...s,tailSeen:true}}
  action bridgeTailDone=all {s.tailLive,not(s.contextReader),Set(7,10).contains(s.boot),
    s.mapMode!=3 or s.tailSeen,
    s'={...s,tailLive:false}}
  action bridgeBad=any {
    all {s.bug==40,s.bridge==2,s'={...s,registersSpilled:false}},
    all {s.bug==41,s.bridge==1,s.rootVersion>0,s'={...s,mappedLanding:false}},
    all {s.bug==42,s.nativeBridge,s'={...s,gcInside:true}},
    all {s.bug==43,s.bridge==1,s.cachedVersion!=s.rootVersion,
      s'={...s,rootUsed:true}},
    all {s.bug==44,s.bridge==3,not(s.slotRelease),
      s'={...s,registryRelease:true}},
    all {s.bug==45,s.bridge==3,not(s.registryRelease),
      s'={...s,registryAcquire:true}},
    all {s.bug==46,s.lockBorrow,s'={...s,lockAlive:false}},
    all {s.bug==47,s.boot==7,not(s.contextReader),s.tailLive,
      s'={...s,bootPin:false}},
    all {s.bug==48,s.bridge==2,s.nativeBridge,s.lockBorrow,
      s'={...s,boot:12,bootReturnPending:true,bootOpen:false}},
    all {s.bug==49,s.boot==10,not(s.contextReader),s.tailLive,
      s'={...s,ticketNonce:2}},
    all {s.bug==50,s.boot==7,not(s.contextReader),s.tailLive,
      s'={...s,recordLive:false,tailLive:false,lockAlive:false,ticketStage:0}}
  }
  val bridgeSafe=all {not(s.gcInside),
    not(s.bootRoots) or s.recordLive,
    s.bootRes==Set() or s.recordLive,
    not(s.nativeBridge) or (s.mappedLanding and s.registersSpilled and s.lockBorrow and s.lockAlive),
    s.rootVersion==0 or s.mappedLanding,
    not(s.rootUsed) or s.cachedVersion==s.rootVersion,
    not(s.registryRelease) or (s.slotRelease and (s.bootMode==12 or s.slotPayload==s.bootEpoch)),
    not(s.registryAcquire) or s.registryRelease,
    not(s.lockBorrow) or s.lockAlive,
    not(s.tailLive) or (s.bootPin and s.recordLive),
    not(s.bootReturnPending) or (not(s.nativeBridge) and not(s.lockBorrow))}
  action ticketReserve=all {s.boot==0,s.ticketStage==0,s.guardReady,
    not(s.recordLive),not(s.contextReader),
    s'={...s,ticketStage:1,ticketEpoch:s.bootEpoch,ticketNonce:s.bootEpoch,
      recordLive:true}}
  action ticketContender=all {s.ticketMode==1,s.ticketStage==1,not(s.entryDenied),
    // A different invocation, even on the same OS thread, receives no ticket.
    s'={...s,entryDenied:true}}
  action ticketStaleRefuse=all {s.ticketMode==4,s.boot==4,s.ticketStage==1,
    not(s.staleDenied),s'={...s,staleDenied:true}}
  action ticketVm=all {s.boot==4,s.ticketStage==1,
    s.ticketMode!=4 or s.staleDenied,s.ticketNonce==s.bootEpoch,
    s'={...s,ticketStage:2}}
  action ticketRecursive=all {s.ticketMode==2,s.ticketStage==2,
    not(s.recursiveDenied),s'={...s,recursiveDenied:true}}
  action ticketP0=all {s.boot==4,s.ticketStage==2,
    s.ticketMode!=2 or s.recursiveDenied,
    s'={...s,ticketStage:3}}
  action ticketEnter=all {s.boot==4,s.ticketStage==3,not(s.guardHeld),
    s'={...s,ticketStage:4,scopeId:1,contextReader:true,tailLive:true}}
  action ticketNestedEnter=all {s.ticketMode==3,s.boot==4,s.ticketStage==4,
    s.scopeId==1,not(s.nestedDone),s'={...s,scopeId:2}}
  action ticketNestedReject=all {s.scopeId==2,not(s.nestedDenied),
    s'={...s,nestedDenied:true}}
  action ticketNestedReturn=all {s.scopeId==2,s.nestedDenied,
    s'={...s,scopeId:1,nestedDone:true}}
  action ticketScopeReturn=all {s.contextReader,s.scopeId==1,
    any {s.boot==7,s.boot==10},not(s.bootReturnPending),
    s'={...s,scopeId:0,contextReader:false,ticketStage:6}}
  action ticketBad=any {
    all {s.bug==31,s.ticketStage==0,s'={...s,guardReady:false}},
    all {s.bug==32,s.ticketStage==4,s'={...s,guardHeld:true}},
    all {s.bug==33,s.ticketStage==1,s'={...s,ticketNonce:2}},
    all {s.bug==34,s.ticketStage==2,s'={...s,doubleInit:true}},
    all {s.bug==35,s.scopeId==2,s'={...s,scopeViolation:true}},
    all {s.bug==36,s.ticketStage==1,s.boot==4,s'={...s,ticketEpoch:0}},
    all {s.bug==37,s.bootReturnPending,s'={...s,recordLive:false}},
    all {s.bug==38,s.boot==8,s'={...s,stackRecord:true}},
    all {s.bug==39,s.boot==10,s.contextReader,s'={...s,ticketNonce:2}}
  }
  val ticketSafe=all {s.guardReady,not(s.scopeViolation),not(s.stackRecord),
    not(s.guardHeld),
    not(s.recordLive) or (s.ticketEpoch==s.bootEpoch and s.ticketNonce==s.bootEpoch),
    not(s.contextReader) or (s.recordLive and s.bootPin and s.ticketStage>=4),
    s.scopeId==0 or s.contextReader,
    not(s.bootReady) or s.ticketStage>=4,
    s.boot!=9 or not(s.contextReader)}
  action bootBind=all {s.boot==0,s.ticketStage==1,s.ticketMode!=1 or s.entryDenied,s.askedVm==1,s.askedSlot==0,
    s'={...s,boot:1,identityBound:true,bootVm:1,bootSlot:0,bootPin:true}}
  action bootRejectIdentity=all {s.boot==0,s.ticketStage==1,not(s.askedVm==1 and s.askedSlot==0),
    s'={...s,boot:9,bootErr:1,bootHadError:true,recordLive:false,ticketStage:7}}
  action bootSlotInit=all {s.boot==1,
    s'={...s,boot:if(s.bootMode==4) 7 else 2,
      bootErr:if(s.bootMode==4) 3 else 0,bootHadError:s.bootMode==4,
      bootRes:if(s.bootMode==4) Set() else Set(1),
      bootEver:if(s.bootMode==4) Set() else Set(1),lockAlive:s.bootMode!=4}}
  action bootProcInit=all {s.boot==2,s.bootMode!=10 or s.bootRepeated,
    val fails=s.bootMode==5 or (s.bootMode==9 and s.bootEpoch==1)
    s'={...s,boot:if(fails) 7 else 3,bootErr:if(fails) 3 else 0,bootHadError:fails,
      bootRes:if(fails) s.bootRes else s.bootRes.union(Set(2)),
      bootEver:if(fails) s.bootEver else s.bootEver.union(Set(2))}}
  action bootQueues=all {s.boot==3,s'={...s,boot:4,
    bootRes:s.bootRes.union(Set(3)),bootEver:s.bootEver.union(Set(3))}}
  action bootProbeClosed=all {s.boot==4,not(s.bootDeniedClosed),
    s'={...s,bootDeniedClosed:true}}
  action bootScheme=all {s.boot==4,s.bootDeniedClosed,s.ticketStage==4,s.scopeId==1,
    s.ticketMode!=3 or s.nestedDone,
    val fails=Set(6,7,8).contains(s.bootMode)
    s'={...s,boot:if(fails) 7 else 5,bootErr:if(fails) 3 else 0,
      bootHadError:fails,bootReady:not(fails),bootRoots:not(fails)}}
  action bootProbeReady=all {s.boot==5,not(s.bootDeniedReady),
    s'={...s,bootDeniedReady:true}}
  action bootOpenReady=all {s.boot==5,s.bootReady,s.bootRoots,s.bootDeniedReady,s.scopeId==1,
    s.ticketStage==4,s.bridge==7,s.mapMode!=3 or s.registryAcquire,
    s'={...s,boot:if(s.bootMode==12) 12 else 6,bootOpen:s.bootMode!=12,
      bootOpenKey:if(s.bootMode==12) 0 else s.bootEpoch,
      bootReady:s.bootMode!=12,bootErr:if(s.bootMode==12) 3 else 0,
      bootHadError:s.bootMode==12,bootReturnPending:s.bootMode==12,ticketStage:5}}
  action bootGc=all {Set(5,12).contains(s.boot),s.bootRoots,s.bootPin,not(s.nativeBridge),
    s'={...s,gcBeat:not(s.gcBeat)}}
  action bootReturn=all {s.boot==12,s.bootReturnPending,s.bootRoots,s.bootPin,
    s'={...s,boot:7,bootReturnPending:false,scopeId:0,contextReader:false,ticketStage:6}}
  action bootGrant=all {s.boot==6,s.registryAcquire,not(s.bootGranted),
    s'={...s,bootGranted:true,bootGrantKey:s.bootEpoch,
      bootBorrow:Set(1,11).contains(s.bootMode) and s.bootEpoch==1}}
  action bootRepeat=all {not(s.bootRepeated),any {
    s.bootMode==1 and s.boot==6 and s.bootBorrow,
    s.bootMode==10 and s.boot==2,
    s.bootMode==8 and s.boot==8,
    s.bootMode==11 and s.boot==10 and s.bootBorrow},
    // Refusal is nonmutating: no identity/counter/mutex reinitialization.
    s'={...s,bootRepeated:true}}
  action bootReleaseBorrow=all {s.bootBorrow,s.bootRepeated,
    s'={...s,bootBorrow:false}}
  action bootClose=all {s.boot==6,s.bootMode==11,s.bootEpoch==1,s.bootGranted,
    s'={...s,boot:10,bootOpen:false}}
  action bootDrained=all {s.boot==10,s.bootRepeated,not(s.bootBorrow),not(s.contextReader),not(s.tailLive),
    s'={...s,boot:7,bootReady:false,bootRoots:false}}
  action bootCleanup(r:int):bool=all {s.boot==7,not(s.contextReader),not(s.tailLive),not(s.lockBorrow),s.bootRes.contains(r),
    not(s.bootRes.exists(x=>x>r)),not(Set(7,8).contains(s.bootMode) and r==2),
    s'={...s,bootRes:s.bootRes.exclude(Set(r)),
      bootDestroyed:s.bootDestroyed.union(Set(r)),lockAlive:s.lockAlive and r!=1}}
  action bootCleanupFault=all {s.boot==7,Set(7,8).contains(s.bootMode),
    s.bootRes==Set(1,2),s'={...s,boot:8}}
  action bootClean=all {s.boot==7,s.bootRes==Set(),not(s.bootBorrow),not(s.contextReader),not(s.tailLive),not(s.lockBorrow),
    s'={...s,boot:9,bootPin:false,bootRoots:false,recordLive:false,ticketStage:7}}
  action bootRetry=all {s.boot==9,Set(9,11).contains(s.bootMode),s.bootEpoch==1,
    s.bootRes==Set(),not(s.bootPin),not(s.bootBorrow),
    s'={...s,boot:0,bootEpoch:2,identityBound:false,bootVm:0,bootReady:false,
      bootRoots:false,bootOpen:false,bootErr:0,bootHadError:false,bootRepeated:false,
      bootEver:Set(),bootDestroyed:Set(),bootGranted:false,bootGrantKey:0,
      bootOpenKey:0,bootDeniedClosed:false,bootDeniedReady:false,
      ticketStage:0,ticketEpoch:0,ticketNonce:0,recordLive:false,scopeId:0,
      staleDenied:false,entryDenied:false,recursiveDenied:false,nestedDenied:false,nestedDone:false,
      bridge:0,mappedLanding:false,registersSpilled:false,nativeBridge:false,
      rootVersion:0,cachedVersion:0,rootUsed:false,gcInside:false,slotPayload:0,
      slotRelease:false,registryRelease:false,registryAcquire:false,lockBorrow:false,
      lockAlive:false,tailLive:false,tailSeen:false}}
  action bootBad=any {
    all {s.bug==20,s.boot==0,not(s.identityBound),s'={...s,invalidLookup:true}},
    all {s.bug==21,s.boot==0,s.askedVm!=1,
      s'={...s,boot:1,identityBound:true,bootVm:s.askedVm,bootPin:true}},
    all {s.bug==22,s.boot==4,s'={...s,bootOpen:true,bootOpenKey:s.bootEpoch}},
    all {s.bug==23,s.boot==7,s.bootRes==Set(1),
      s'={...s,bootDestroyed:s.bootDestroyed.union(Set(2))}},
    all {s.bug==24,s.boot==7,s.bootDestroyed!=Set(),s'={...s,doubleDestroy:true}},
    all {s.bug==25,s.boot==6,s.bootBorrow,s'={...s,bootEpoch:2}},
    all {s.bug==26,s.boot==8,s'={...s,bootPin:false,bootRes:Set()}},
    all {s.bug==27,s.boot==7,s.bootHadError,s'={...s,bootErr:0}},
    all {s.bug==28,s.boot==2,s'={...s,doubleInit:true}},
    all {s.bug==29,s.boot==4,s'={...s,phase:1,carrier:true}},
    all {s.bug==30,s.boot==12,s.bootReturnPending,s'={...s,bootRoots:false}}
  }
  val bootSafe=all {
    not(s.invalidLookup),not(s.doubleDestroy),not(s.doubleInit),
    not(s.bootRoots) or s.bootPin,
    not(s.bootReturnPending) or (s.boot==12 and s.bootRoots and s.bootPin and not(s.bootOpen)),
    not(s.identityBound) or (s.bootVm==1 and s.bootSlot==0),
    s.bootRes.subseteq(s.bootEver),s.bootDestroyed.subseteq(s.bootEver),
    s.bootDestroyed.intersect(s.bootRes)==Set(),
    s.bootRes==Set() or (s.identityBound and s.bootPin),
    not(s.bootOpen) or (s.boot==6 and s.bootReady and s.bootRoots and
      s.bootOpenKey==s.bootEpoch and s.bootRes==Set(1,2,3)),
    not(s.bootBorrow) or (s.bootGrantKey==s.bootEpoch and s.bootPin),
    s.boot!=8 or (s.bootPin and s.bootRes!=Set() and s.bootHadError),
    not(s.bootHadError) or s.bootErr!=0,
    s.phase==0 or (s.boot==6 and s.bootOpen and s.bootGranted)}
  action growthStep=any {begin,create(2),create(3),park(2),park(3),earlyGc,reserve,buildFirst,
    buildRest,abort,exitShell(2),exitShell(3),joinShell(2),joinShell(3),joinError,
    cleanup(2),cleanup(3),cleanupError,oldAgreement,readerGrace,oldResume,oldPrimary,
    commit,publishGo(2),publishGo(3),bind(2),bind(3),startupGc,runScheme(2),runScheme(3),
    publishReady(2),publishReady(3),startupError,open,acquire(1),acquire(2),refresh(1),refresh(2),
    publish(1),publish(2),release(1),release(2),drain(1),drain(2),wakeDone(1),wakeDone(2),
    close,retainedPublisher,debtCut,newDebt,serviceAck,finalize,freeAborted,retry,cancel,bad,idle}
  action step=any {bridgeMap,bridgeGc,bridgeReload,bridgeEnter,bridgeSlot,
    bridgeSlotUnlock,bridgeRegistryPublish,bridgeRegistryObserve,bridgeLeave,
    bridgeTailObserve,bridgeTailDone,bridgeBad,ticketReserve,ticketContender,ticketStaleRefuse,ticketVm,ticketRecursive,
    ticketP0,ticketEnter,ticketNestedEnter,ticketNestedReject,ticketNestedReturn,
    ticketScopeReturn,ticketBad,growthStep,bootBind,bootRejectIdentity,bootSlotInit,bootProcInit,
    bootQueues,bootProbeClosed,bootScheme,bootProbeReady,bootOpenReady,bootGc,bootReturn,bootGrant,
    bootRepeat,bootReleaseBorrow,bootClose,bootDrained,bootCleanup(3),bootCleanup(2),
    bootCleanup(1),bootCleanupFault,bootClean,bootRetry,bootBad}
  val safe=all {bootSafe,ticketSafe,bridgeSafe,
    s.usedNodes.subseteq(Set(6,7,8,9)),s.usedNodes.size()==2*s.views.size(),
    s.bound.subseteq(s.go),s.go.subseteq(s.members.exclude(old)),
    s.go.intersect(s.aborted)==Set(),s.go.subseteq(s.parked),
    not(s.publicOpen) or (s.ready==slots and s.committed),s.grantReady,
    not(s.held) or (s.excluded and s.assigned==s.base and s.cursor==s.base),
    not(s.committed) or (s.assigned==s.base+4 and s.members==old.union(slots)),
    not(s.freed) or (s.leases==Set() and s.queue==Set() and s.wake==Set() and
      (s.committed or s.joined==s.created)),
    not(s.controlFreed) or (s.joined==s.created and s.cleaned==s.created),
    s.accepted.subseteq(s.queue.union(s.done)),
    ids.forall(r=>s.req.get(r)!=1 or s.leases.contains(r)),
    s.leases.forall(r=>s.grantGen.get(r)==s.epoch),
    s.phase==0 or s.primaryDone or (s.carrier and s.hintDebt),
    not(s.joinFault) or s.epoch==1,
    s.ack<=s.cut,s.cut<=s.demand,not(s.staleRead)}
  val finished=s.phase==8
  val growthGoal=if(s.mode==9) s.phase==11 and s.carrier and s.committed and not(s.publicOpen) and s.ack==s.demand
    else if(s.mode==3 or s.mode==4 or s.mode==5)
      s.phase==11 and s.carrier and s.ack==s.demand and (s.mode!=3 or s.cleaned.contains(3)) and (s.mode==5 or (s.oldGc and s.primaryDone))
    else if(Set(1,2,7).contains(s.mode)) s.phase==10 and s.freed and s.oldGc
    else finished and (s.mode!=6 or s.epoch==2)
  val goal=if(Set(2,3,4,5,6,12).contains(s.bootMode))
      s.boot==9 and s.bootErr!=0 and s.bootRes==Set() and not(s.bootPin)
    else if(Set(7,8).contains(s.bootMode)) s.boot==8 and s.bootPin and
      s.bootRes==Set(1,2) and (s.bootMode!=8 or s.bootRepeated)
    else growthGoal and (not(Set(9,11).contains(s.bootMode)) or s.bootEpoch==2) and
      (not(Set(1,10).contains(s.bootMode)) or s.bootRepeated)
  temporal fairness=all {weakFair(bridgeMap,Set(s)),weakFair(bridgeGc,Set(s)),
    weakFair(bridgeReload,Set(s)),weakFair(bridgeEnter,Set(s)),weakFair(bridgeSlot,Set(s)),
    weakFair(bridgeSlotUnlock,Set(s)),weakFair(bridgeRegistryPublish,Set(s)),
    weakFair(bridgeRegistryObserve,Set(s)),weakFair(bridgeLeave,Set(s)),
    weakFair(bridgeTailObserve,Set(s)),weakFair(bridgeTailDone,Set(s)),
    weakFair(ticketReserve,Set(s)),
    weakFair(ticketContender,Set(s)),weakFair(ticketStaleRefuse,Set(s)),
    weakFair(ticketVm,Set(s)),weakFair(ticketRecursive,Set(s)),weakFair(ticketP0,Set(s)),
    weakFair(ticketEnter,Set(s)),weakFair(ticketNestedEnter,Set(s)),
    weakFair(ticketNestedReject,Set(s)),weakFair(ticketNestedReturn,Set(s)),
    weakFair(ticketScopeReturn,Set(s)),weakFair(bootBind,Set(s)),
    weakFair(bootRejectIdentity,Set(s)),
    weakFair(bootSlotInit,Set(s)),
    weakFair(bootProcInit,Set(s)),
    weakFair(bootQueues,Set(s)),
    weakFair(bootProbeClosed,Set(s)),
    weakFair(bootScheme,Set(s)),
    weakFair(bootProbeReady,Set(s)),
    weakFair(bootOpenReady,Set(s)),
    weakFair(bootReturn,Set(s)),
    weakFair(bootGrant,Set(s)),
    weakFair(bootRepeat,Set(s)),
    weakFair(bootReleaseBorrow,Set(s)),
    weakFair(bootClose,Set(s)),
    weakFair(bootDrained,Set(s)),
    weakFair(bootCleanup(3),Set(s)),
    weakFair(bootCleanup(2),Set(s)),
    weakFair(bootCleanup(1),Set(s)),
    weakFair(bootCleanupFault,Set(s)),
    weakFair(bootClean,Set(s)),
    weakFair(bootRetry,Set(s)),
    weakFair(begin,Set(s)),
    weakFair(create(2),Set(s)),
    weakFair(create(3),Set(s)),
    weakFair(park(2),Set(s)),
    weakFair(park(3),Set(s)),
    weakFair(earlyGc,Set(s)),
    weakFair(reserve,Set(s)),
    weakFair(buildFirst,Set(s)),
    weakFair(buildRest,Set(s)),
    weakFair(abort,Set(s)),
    weakFair(exitShell(2),Set(s)),
    weakFair(exitShell(3),Set(s)),
    weakFair(joinShell(2),Set(s)),
    weakFair(joinShell(3),Set(s)),
    weakFair(joinError,Set(s)),
    weakFair(cleanup(2),Set(s)),
    weakFair(cleanup(3),Set(s)),
    weakFair(cleanupError,Set(s)),
    weakFair(oldAgreement,Set(s)),
    weakFair(readerGrace,Set(s)),
    weakFair(oldResume,Set(s)),
    weakFair(oldPrimary,Set(s)),
    weakFair(commit,Set(s)),
    weakFair(publishGo(2),Set(s)),
    weakFair(publishGo(3),Set(s)),
    weakFair(bind(2),Set(s)),
    weakFair(bind(3),Set(s)),
    weakFair(runScheme(2),Set(s)),
    weakFair(runScheme(3),Set(s)),
    weakFair(publishReady(2),Set(s)),
    weakFair(publishReady(3),Set(s)),
    weakFair(startupError,Set(s)),
    weakFair(open,Set(s)),
    weakFair(acquire(1),Set(s)),
    weakFair(acquire(2),Set(s)),
    weakFair(refresh(1),Set(s)),
    weakFair(refresh(2),Set(s)),
    weakFair(publish(1),Set(s)),
    weakFair(publish(2),Set(s)),
    weakFair(release(1),Set(s)),
    weakFair(release(2),Set(s)),
    weakFair(drain(1),Set(s)),
    weakFair(drain(2),Set(s)),
    weakFair(wakeDone(1),Set(s)),
    weakFair(wakeDone(2),Set(s)),
    weakFair(close,Set(s)),
    weakFair(retainedPublisher,Set(s)),
    weakFair(debtCut,Set(s)),
    weakFair(serviceAck,Set(s)),
    weakFair(finalize,Set(s)),
    weakFair(freeAborted,Set(s)),
    weakFair(retry,Set(s)),
    weakFair(cancel,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
  temporal unconditional=fairness.implies(eventually(finished))
}
