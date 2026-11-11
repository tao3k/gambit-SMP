module private_reservation_admission {
  type State={mode:int,bug:int,violation:int,phase:int,epoch:int,slotGen:int,
    assigned:int,cursor:int,stacks:int,baseAssigned:int,baseCursor:int,baseStacks:int,
    allocGen:int,claimGen:int,activePages:Set[int],held:Set[int],views:Set[int],
    built:Set[int],excluded:bool,committed:bool,nativeOwned:bool,nativeKey:int,
    nativeFault:bool,carrier:bool,activeCount:int,ackCount:int,grace:bool,
    demand:int,covered:int,acked:int,gcSeen:bool,gcBeat:bool,
    req:int,wantedGen:int,lease:bool,leaseGen:int,grantPhase:int,prechecked:bool,
    queueOwned:bool,accepted:bool,done:bool,publishGrant:int,freed:bool,cancelRefused:bool}
  var s:State
  pure def pages(base:int):Set[int]=Set(base+1,base+2,base+3,base+4)
  pure def initial(m:int,b:int):State={mode:m,bug:b,violation:0,phase:0,epoch:1,slotGen:1,
    assigned:if(m==6) 5 else 4,cursor:if(m==6) 5 else 4,stacks:2,
    baseAssigned:if(m==6) 5 else 4,baseCursor:if(m==6) 5 else 4,baseStacks:2,
    allocGen:1,claimGen:0,activePages:if(m==6) Set(1,2,3,4,5) else Set(1,2,3,4),
    held:Set(),views:Set(),built:Set(),excluded:false,committed:false,nativeOwned:false,
    nativeKey:1,nativeFault:false,carrier:false,activeCount:2,ackCount:0,grace:false,
    demand:0,covered:0,acked:0,gcSeen:false,gcBeat:false,req:0,wantedGen:1,lease:false,
    leaseGen:0,grantPhase:0,prechecked:false,queueOwned:false,accepted:false,done:false,
    publishGrant:0,freed:false,cancelRefused:false}
  action initAbortRetry=s'=initial(0,0)
  action initPrefixAbort=s'=initial(1,0)
  action initNativeCleanupFault=s'=initial(2,0)
  action initPostCommitCancel=s'=initial(3,0)
  action initCapacityRefusal=s'=initial(4,0)
  action initHeldPublisher=s'=initial(5,0)
  action initExistingAllocationPrefix=s'=initial(6,0)
  action initEagerGlobalMutation=s'=initial(0,1)
  action initBlindRewindAfterCommit=s'=initial(6,2)
  action initGcDuringClaim=s'=initial(0,3)
  action initLeaseToStaged=s'=initial(0,4)
  action initCheckThenPin=s'=initial(6,5)
  action initStaleGenerationLease=s'=initial(0,6)
  action initDropAcceptedQueue=s'=initial(6,7)
  action initFreeWithPublisher=s'=initial(6,8)
  action initDropFaultCarrier=s'=initial(2,9)
  action initAbortClearsDebt=s'=initial(1,10)
  action initClaimLivePage=s'=initial(0,11)
  action initRawUnleasedPublish=s'=initial(0,12)
  action initReuseRetainedSlot=s'=initial(2,13)
  action initDropClaimBeforeViews=s'=initial(1,14)
  action initWaitNativeCleanupForGc=s'=initial(2,15)
  action initAssumePublisherReleases=s'=initial(5,0)
  action begin=all {s.phase==0,s'={...s,phase:1,nativeOwned:true,carrier:true,
    demand:s.demand+1,nativeKey:s.epoch}}
  action capacityRefuse=all {s.phase==1,s.mode==4,s'={...s,phase:5}}
  action claim=all {s.phase==1,s.mode!=4,
    s'={...s,phase:2,excluded:true,baseAssigned:s.assigned,baseCursor:s.cursor,
      baseStacks:s.stacks,claimGen:s.allocGen,held:pages(s.cursor),views:Set(),built:Set()}}
  action buildOne=all {s.phase==2,s.built==Set(),
    s'={...s,built:Set(2),views:Set(s.baseCursor+1,s.baseCursor+2)}}
  action buildTwo=all {s.phase==2,s.built==Set(2),
    not(Set(0,1,2).contains(s.mode) and s.epoch==1),
    s'={...s,built:Set(2,3),views:s.held}}
  // Discard clears only unpublished views/claim; global cursor/counters were never changed.
  action discard=all {s.phase==2,s.built==Set(2),Set(0,1,2).contains(s.mode),s.epoch==1,
    s'={...s,phase:5,views:Set(),held:Set(),built:Set(),excluded:false}}
  action commit=all {s.phase==2,s.built==Set(2,3),not(s.lease),not(s.queueOwned),
    s'={...s,phase:3,assigned:s.baseAssigned+4,cursor:s.baseCursor+4,stacks:s.baseStacks+2,
      activePages:s.activePages.union(s.held),held:Set(),excluded:false,committed:true,
      activeCount:4}}
  action nativeCleanup=all {s.phase==5,
    s'={...s,phase:if(s.mode==2) 6 else 9,nativeFault:s.mode==2,
      nativeOwned:s.mode==2}}
  action ackOld=all {s.phase==9,s.ackCount<2,s'={...s,ackCount:s.ackCount+1}}
  action grace=all {s.phase==9,s.ackCount==2,not(s.grace),s'={...s,grace:true}}
  action stableOld=all {s.phase==9,s.ackCount==2,s.grace,s'={...s,phase:10}}
  action collectOld=all {Set(6,10).contains(s.phase),s.held==Set(),s.views==Set(),not(s.excluded),
    not(s.bug==15 and s.nativeFault),
    s'={...s,gcSeen:true,gcBeat:not(s.gcBeat),allocGen:s.allocGen+1-(if(s.gcBeat) 2 else 0)}}
  action serviceOld=all {Set(6,10).contains(s.phase),s.held==Set(),s.views==Set(),
    s'={...s,covered:s.demand,acked:s.demand}}
  action retry=all {s.phase==10,s.mode==0,s.epoch==1,s.gcSeen,s.acked==s.demand,
    not(s.nativeOwned),s'={...s,phase:0,epoch:2,slotGen:2,nativeKey:2,req:0,
      wantedGen:1,prechecked:false,ackCount:0,grace:false,gcSeen:false}}
  action requestAcquire=all {s.req==0,
    s'={...s,req:if(s.phase==3 and s.wantedGen==s.slotGen) 1 else 4,
      lease:s.phase==3 and s.wantedGen==s.slotGen,
      leaseGen:if(s.phase==3 and s.wantedGen==s.slotGen) s.slotGen else 0,
      grantPhase:if(s.phase==3 and s.wantedGen==s.slotGen) 3 else 0}}
  action refreshRequest=all {s.phase==3,s.req==4,
    s'={...s,req:0,wantedGen:s.slotGen}}
  action precheck=all {s.phase==3,s.req==0,not(s.prechecked),s'={...s,prechecked:true}}
  action closeAdmission=all {s.phase==3,(s.lease or s.queueOwned or s.done or s.prechecked),
    // Correct protocol cannot let an unleased precheck strand the normal scenario.
    s.bug==5 or s.lease or s.queueOwned or s.done,
    s'={...s,phase:4}}
  action publishRequest=all {Set(3,4).contains(s.phase),s.req==1,s.lease,s.leaseGen==s.slotGen,
    s'={...s,req:2,accepted:true,queueOwned:true,publishGrant:s.grantPhase}}
  action consumeRequest=all {Set(3,4).contains(s.phase),s.queueOwned,
    s'={...s,queueOwned:false,done:true,req:3}}
  action releaseProducer=all {Set(2,3).contains(s.req),s.lease,s.mode!=5,
    s'={...s,lease:false}}
  action finishClose=all {s.phase==4,s.done,not(s.queueOwned),not(s.lease),
    s'={...s,phase:8,covered:s.demand,acked:s.demand}}
  action retainedPublisher=all {s.phase==4,s.mode==5,s.lease,
    s'={...s,phase:7,nativeFault:true}}
  action postCommitCancel=all {Set(3,4,8).contains(s.phase),s.mode==3,s.committed,not(s.cancelRefused),
    s'={...s,cancelRefused:true}}
  action bad=any {
    all {s.bug==1,s.phase==2,s.built==Set(2),
      s'={...s,assigned:s.assigned+2,cursor:s.cursor+2,violation:1}},
    all {s.bug==2,s.committed,s'={...s,assigned:s.baseAssigned,cursor:s.baseCursor,
      stacks:s.baseStacks,violation:2}},
    all {s.bug==3,s.held!=Set(),s'={...s,allocGen:s.allocGen+1,violation:3}},
    all {s.bug==4,s.phase==1,s'={...s,lease:true,leaseGen:s.slotGen,grantPhase:1,violation:4}},
    all {s.bug==5,s.phase==4,s.prechecked,not(s.lease),
      s'={...s,lease:true,leaseGen:s.slotGen,grantPhase:4,violation:5}},
    all {s.bug==6,s.phase==3,s.epoch==2,
      s'={...s,lease:true,leaseGen:1,grantPhase:3,violation:6}},
    all {s.bug==7,s.queueOwned,not(s.done),s'={...s,queueOwned:false,violation:7}},
    all {s.bug==8,s.lease,s'={...s,freed:true,violation:8}},
    all {s.bug==9,s.phase==6,s'={...s,carrier:false,violation:9}},
    all {s.bug==10,s.phase==5,s'={...s,acked:s.demand,violation:10}},
    all {s.bug==11,s.phase==2,s'={...s,held:s.held.union(Set(1)),violation:11}},
    all {s.bug==12,s.phase==1,s'={...s,accepted:true,queueOwned:true,publishGrant:1,violation:12}},
    all {s.bug==13,s.phase==6,s'={...s,epoch:2,slotGen:2,violation:13}},
    all {s.bug==14,s.phase==2,s.views!=Set(),s'={...s,held:Set(),excluded:false,violation:14}}
  }
  action idle=s'=s
  action step=any {begin,capacityRefuse,claim,buildOne,buildTwo,discard,commit,nativeCleanup,
    ackOld,grace,stableOld,collectOld,serviceOld,retry,requestAcquire,refreshRequest,
    precheck,closeAdmission,publishRequest,consumeRequest,releaseProducer,finishClose,
    retainedPublisher,postCommitCancel,bad,idle}
  val safe=all {
    s.held.intersect(s.activePages)==Set(),s.views.subseteq(s.held.union(s.activePages)),
    s.held==Set() or (s.excluded and s.claimGen==s.allocGen and s.assigned==s.baseAssigned and
      s.cursor==s.baseCursor and s.stacks==s.baseStacks),
    not(s.committed) or (s.assigned==s.baseAssigned+4 and s.cursor==s.baseCursor+4 and
      s.stacks==s.baseStacks+2 and s.activeCount==4),
    not(s.lease) or (s.grantPhase==3 and s.leaseGen==s.slotGen and not(s.freed)),
    not(s.accepted) or (s.publishGrant==3 and (s.queueOwned or s.done)),
    not(s.nativeOwned) or (s.carrier and s.nativeKey==s.epoch),
    s.acked<=s.covered,s.covered<=s.demand,
    not(Set(6,10).contains(s.phase)) or (s.held==Set() and s.views==Set() and not(s.excluded))}
  val quiescent=s.phase==8 and s.done and not(s.lease) and not(s.queueOwned)
  val goal=if(s.mode==2) s.phase==6 and s.nativeFault and s.gcSeen and s.acked==s.demand
    else if(s.mode==3) quiescent and s.cancelRefused
    else if(s.mode==5) s.phase==7 and s.committed and s.carrier
    else if(s.mode==1 or s.mode==4) s.phase==10 and s.gcSeen and s.acked==s.demand
    else quiescent and (s.mode!=0 or s.epoch==2)
  temporal fairness=all {weakFair(begin,Set(s)),weakFair(capacityRefuse,Set(s)),
    weakFair(claim,Set(s)),weakFair(buildOne,Set(s)),weakFair(buildTwo,Set(s)),
    weakFair(discard,Set(s)),weakFair(commit,Set(s)),weakFair(nativeCleanup,Set(s)),
    weakFair(ackOld,Set(s)),weakFair(grace,Set(s)),weakFair(stableOld,Set(s)),
    weakFair(collectOld,Set(s)),weakFair(serviceOld,Set(s)),weakFair(retry,Set(s)),
    weakFair(requestAcquire,Set(s)),weakFair(refreshRequest,Set(s)),
    weakFair(closeAdmission,Set(s)),weakFair(publishRequest,Set(s)),weakFair(consumeRequest,Set(s)),
    weakFair(releaseProducer,Set(s)),weakFair(finishClose,Set(s)),
    weakFair(retainedPublisher,Set(s)),weakFair(postCommitCancel,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
  temporal unconditionalQuiescence=fairness.implies(eventually(quiescent))
}
