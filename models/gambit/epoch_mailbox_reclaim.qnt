module epoch_mailbox_reclaim {
  // Two handoffs E0->E1->E2. Physical slot0 can be reused at E2, only after
  // native tail AND queued-reader pins leave E0. Two final-root-ACKed carriers.
  type S={mode:int,bug:int,e:int,gen0:int,oldLive:bool,closed0:bool,tail0:bool,
    tailBusy:bool,queue0:bool,m0:int,m1:int,late:bool,ready:bool,valueInit:bool,
    consumed:bool,uninitRead:bool,staleRejected:bool,staleAccepted:bool,rawRead:bool,
    rcA:bool,rcB:bool,borrowA:bool,readerB:bool,freeA:int,freeB:int,
    dstA:bool,dstB:bool,g:bool,ra:bool,rb:bool,da:bool,db:bool,newGc:bool,
    window:bool,cursor:int,left:int,skipA:bool,debtB:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,e:0,gen0:0,oldLive:true,
    closed0:false,tail0:true,tailBusy:true,queue0:true,m0:0,m1:1,late:false,
    ready:false,valueInit:false,consumed:false,uninitRead:false,
    staleRejected:false,staleAccepted:false,rawRead:false,rcA:true,rcB:true,
    borrowA:true,readerB:true,freeA:0,freeB:0,dstA:true,dstB:true,
    g:false,ra:false,rb:false,da:false,db:false,newGc:false,
    window:false,cursor:0,left:0,skipA:false,debtB:true}
  action initNormal=s'=initial(0,0)
  action initBusyA=s'=initial(1,0)
  action initOldTailHeld=s'=initial(2,0)
  action initAlias=s'=initial(0,1)
  action initReusePinned=s'=initial(0,2)
  action initEarlyDrop=s'=initial(0,3)
  action initFreeQueue=s'=initial(0,4)
  action initEarlyReady=s'=initial(0,5)
  action initModuloABA=s'=initial(0,6)
  action initRawFreed=s'=initial(0,7)
  action initGlobalGate=s'=initial(1,8)
  action initReleaseBusy=s'=initial(1,9)
  action initReleaseReader=s'=initial(0,10)
  action initDoubleFree=s'=initial(0,11)
  action initLoseRoot=s'=initial(0,12)
  action initLoseDebt=s'=initial(0,13)
  action initStuckCursor=s'=initial(1,14)
  action firstHandoff=all {s.e==0,s'={...s,e:1,closed0:true}}
  action lateSend=all {s.e==1,s.tail0,s.oldLive,not(s.late),
    s'={...s,late:true,m0:0,m1:if(s.bug==1) 0 else s.m1}}
  action finishNativeTail=all {s.e>=1,s.tailBusy,s.mode!=2,s'={...s,tailBusy:false}}
  action dropTail=all {s.tail0,not(s.tailBusy),s'={...s,tail0:false}}
  action dropQueuedPin=all {s.e>=1,s.queue0,s'={...s,queue0:false}}
  action destroyOld=all {s.closed0,s.oldLive,not(s.tail0),not(s.queue0),s'={...s,oldLive:false}}
  action reuseSlot=all {s.e==1,not(s.oldLive),not(s.tail0),not(s.queue0),
    s'={...s,e:2,gen0:2,m0:2,ready:false,valueInit:false,consumed:false}}
  // Registry lookup resolves the full historical token0 under stable ownership.
  action rejectHistorical=all {s.e==2,not(s.staleRejected),s'={...s,staleRejected:true}}
  action publishPayload=all {s.e>=1,not(s.ready),s'={...s,valueInit:true,ready:true}}
  action receivePayload=all {s.ready,not(s.consumed),s'={...s,consumed:true,uninitRead:not(s.valueInit)}}
  action dropA=all {s.mode==0,s.e>=1,s.skipA,s.borrowA,s'={...s,borrowA:false}}
  action dropBReader=all {s.e>=1,s.readerB,s'={...s,readerB:false}}
  action beginBatch=all {s.e>=1,not(s.window),not(s.bug==8 and s.borrowA),
    s'={...s,window:true,left:2}}
  action visitA=all {s.window,s.left>0,s.cursor==0,
    s'={...s,cursor:if(s.bug==14 and s.borrowA) 0 else 1,left:s.left-1,
      skipA:s.skipA or s.borrowA,rcA:if(s.borrowA) s.rcA else false,
      freeA:if(s.rcA and not(s.borrowA)) s.freeA+1 else s.freeA}}
  action visitB=all {s.window,s.left>0,s.cursor==1,
    s'={...s,cursor:0,left:s.left-1,rcB:if(s.readerB) s.rcB else false,
      debtB:if(s.readerB) s.debtB else false,
      freeB:if(s.rcB and not(s.readerB)) s.freeB+1 else s.freeB}}
  action endBatch=all {s.window,s.left==0,s'={...s,window:false}}
  action gc=all {not(s.window),s'={...s,g:not(s.g),newGc:s.newGc or s.e>=1,
    ra:if(s.rcA) not(s.g) else s.ra,rb:if(s.rcB) not(s.g) else s.rb,
    da:if(s.dstA) not(s.g) else s.da,db:if(s.dstB) not(s.g) else s.db}}
  action mutant=any {
    all {s.bug==2,s.e==1,s.tail0,s'={...s,e:2,gen0:2,m0:2}},
    all {s.bug==3,s.tailBusy,s'={...s,tail0:false}},
    all {s.bug==4,s.e==1,s.queue0,not(s.tail0),s'={...s,oldLive:false}},
    all {s.bug==5,s.e>=1,not(s.ready),s'={...s,ready:true,valueInit:false}},
    // Token0 and E2 have equal parity but unequal full generation.
    all {s.bug==6,s.e==2,s.gen0%2==0,s'={...s,staleAccepted:true}},
    all {s.bug==7,not(s.oldLive),s'={...s,rawRead:true}},
    all {s.bug==9,s.window,s.borrowA,s'={...s,rcA:false,freeA:s.freeA+1}},
    all {s.bug==10,s.window,s.readerB,s'={...s,rcB:false,freeB:s.freeB+1}},
    all {s.bug==11,s.freeB==1,s'={...s,freeB:2}},
    all {s.bug==12,not(s.rcB),s'={...s,dstB:false}},
    all {s.bug==13,s.rcB,s'={...s,debtB:false}}
  }
  action idle=s'=s
  action step=any {firstHandoff,lateSend,finishNativeTail,dropTail,dropQueuedPin,
    destroyOld,reuseSlot,rejectHistorical,publishPayload,receivePayload,dropA,
    dropBReader,beginBatch,visitA,visitB,endBatch,gc,mutant,idle}
  val safe=all {s.e!=1 or s.m1==1,s.e!=2 or (s.gen0==2 and s.m0==2),
    s.gen0!=2 or (not(s.tail0) and not(s.queue0)),
    not(s.tailBusy) or (s.tail0 and s.oldLive),
    s.oldLive or (not(s.tail0) and not(s.queue0)),
    not(s.uninitRead),not(s.staleAccepted),not(s.rawRead),
    s.rcA or not(s.borrowA),s.rcB or not(s.readerB),s.freeA<=1,s.freeB<=1,
    s.rcA or s.dstA,s.rcB or s.dstB,
    not(s.rcA) or s.ra==s.g,not(s.rcB) or s.rb==s.g,
    not(s.dstA) or s.da==s.g,not(s.dstB) or s.db==s.g,
    not(s.rcB) or s.debtB}
  val goal=not(s.rcB)
  temporal fairness=all {weakFair(firstHandoff,Set(s)),weakFair(finishNativeTail,Set(s)),
    weakFair(dropTail,Set(s)),weakFair(dropQueuedPin,Set(s)),weakFair(destroyOld,Set(s)),
    weakFair(reuseSlot,Set(s)),weakFair(rejectHistorical,Set(s)),weakFair(dropA,Set(s)),
    weakFair(dropBReader,Set(s)),weakFair(beginBatch,Set(s)),weakFair(visitA,Set(s)),
    weakFair(visitB,Set(s)),weakFair(endBatch,Set(s)),weakFair(gc,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
}
