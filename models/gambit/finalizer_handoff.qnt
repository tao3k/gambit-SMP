module finalizer_handoff {
  // Registered per-donor lifetime pin persists across tail->finalizer handoff.
  // Native guard/misc/sync faults are conservative process-fatal, NOT recovery.
  // Common election, lock-free atomics, actual join0 and isolation are C premises.
  type State={mode:int,site:int,bug:int,stage:int->int,tail:int->bool,
    pin:int->bool,joined:int->bool,claims:int->int,key:int->int,
    readers:int->int,owner:int->int,window:bool,selected:int,acks:Set[int],
    result:bool,fault:bool,stopped:bool,sealed:bool,vmFreed:bool,
    refused:bool,localRetained:bool,cutProved:bool,earlyReturn:bool,
    hookCalled:bool,gc:int,lateUse:bool}
  var s:State
  val donors=Set(1,2)
  pure def initial(mode:int,site:int,bug:int):State={
    mode:mode,site:site,bug:bug,stage:Map(1->0,2->0),
    tail:Map(1->true,2->true),pin:Map(1->true,2->true),
    joined:Map(1->false,2->false),claims:Map(1->0,2->0),key:Map(1->1,2->2),
    readers:Map(1->if(mode==3) 1 else 0,2->0),owner:Map(1->0,2->0),
    window:false,selected:0,acks:Set(),result:false,fault:false,stopped:false,
    sealed:false,vmFreed:false,refused:false,localRetained:false,
    cutProved:true,earlyReturn:false,hookCalled:false,gc:0,lateUse:false}
  action initNormal=s'=initial(0,0,0)
  action initClaimRefused=s'=initial(5,0,0)
  action initHeldReader=s'=initial(3,0,0)
  action initDestroyRetained=s'=initial(2,0,0)
  action initPrivateUnlockRetained=s'=initial(4,0,0)
  action initGuardUnknown=s'=initial(1,1,0)
  action initMiscUnknown=s'=initial(1,2,0)
  action initSyncUnknown=s'=initial(1,3,0)
  action initPinGap=s'=initial(0,0,1)
  action initCounterOnlyClean=s'=initial(2,0,2)
  action initStaleClaim=s'=initial(0,0,3)
  action initTailBeforeJoin=s'=initial(0,0,4)
  action initDropReaderPin=s'=initial(3,0,5)
  action initResumeSharedFault=s'=initial(1,2,6)
  action initUnprovenIsolation=s'=initial(4,0,7)
  action initMemberEarlyReturn=s'=initial(0,0,8)
  action initFatalCallback=s'=initial(1,1,9)
  action initUseAfterRelease=s'=initial(0,0,10)
  action initDoubleClaim=s'=initial(0,0,11)
  action initIgnoreFinalReader=s'=initial(0,0,12)
  action initWaitBarrierFault=s'=initial(1,2,13)
  action initWaitHookFault=s'=initial(1,1,14)
  val normal=not(s.fault) and not(s.stopped) and not(s.vmFreed)
  action join(d:int):bool=all {normal,s.stage.get(d)==0,
    s'={...s,stage:s.stage.set(d,1),joined:s.joined.set(d,true)}}
  action claim(d:int):bool=all {normal,s.stage.get(d)==1,
    not(d==1 and (s.mode==5 or (s.mode==1 and s.site==1))),
    s'={...s,stage:s.stage.set(d,2),claims:s.claims.set(d,1)}}
  action leaveTail(d:int):bool=all {normal,s.stage.get(d)==2,
    s'={...s,stage:s.stage.set(d,3),tail:s.tail.set(d,false)}}
  action retainClaim=all {normal,s.mode==5,s.stage.get(1)==1,
    s'={...s,stage:s.stage.set(1,7),refused:true}}
  action retainReader=all {normal,s.mode==3,s.stage.get(1)==3,
    s'={...s,stage:s.stage.set(1,7),refused:true}}
  action guardFault=all {normal,s.mode==1,s.site==1,s.stage.get(1)==1,
    s'={...s,fault:true}}
  action beginWindow(d:int):bool=all {normal,not(s.window),
    s.stage.get(d)==3,s.readers.get(d)==0,
    s'={...s,window:true,selected:d,result:false,acks:Set()}}
  action mutate=all {normal,s.window,s.stage.get(s.selected)==3,
    s'={...s,stage:s.stage.set(s.selected,4),owner:s.owner.set(s.selected,1),
      result:not(s.mode==1 and s.site==2 and s.selected==1),
      fault:s.mode==1 and s.site==2 and s.selected==1}}
  action ack(p:int):bool=all {normal,s.window,s.result,not(s.acks.contains(p)),
    s'={...s,acks:s.acks.union(Set(p)),
      fault:s.mode==1 and s.site==3 and s.selected==1 and p==1}}
  action endWindow=all {normal,s.window,s.acks==donors,
    s'={...s,window:false,stage:s.stage.set(s.selected,5),selected:0}}
  action localFailure=all {normal,s.stage.get(1)==5,Set(2,4).contains(s.mode),
    s'={...s,stage:s.stage.set(1,7),localRetained:true}}
  action release(d:int):bool=all {normal,s.stage.get(d)==5,
    d!=1 or not(Set(2,4).contains(s.mode)),s.readers.get(d)==0,
    s'={...s,stage:s.stage.set(d,6),pin:s.pin.set(d,false)}}
  action seal=all {normal,not(s.sealed),s'={...s,sealed:true}}
  action cleanup=all {normal,s.sealed,donors.forall(d=>s.stage.get(d)==6),
    s'={...s,vmFreed:true}}
  action collect=all {normal,not(s.window),s.gc<2,s'={...s,gc:s.gc+1}}
  // Independent no-callback termination does not need any collective ack/lock.
  action processStop=all {s.fault,not(s.stopped),s.bug!=13,s.bug!=14,
    s'={...s,stopped:true}}
  action bad=any {
    all {normal,s.bug==1,s.stage.get(1)==2,s'={...s,pin:s.pin.set(1,false)}},
    all {normal,s.bug==2,donors.forall(d=>not(s.tail.get(d))),
      s'={...s,vmFreed:true}},
    all {normal,s.bug==3,s.stage.get(1)==2,s'={...s,key:s.key.set(1,0)}},
    all {normal,s.bug==4,s.stage.get(1)==0,s'={...s,tail:s.tail.set(1,false)}},
    all {normal,s.bug==5,s.readers.get(1)==1,s'={...s,pin:s.pin.set(1,false)}},
    all {s.bug==6,s.fault,not(s.stopped),s'={...s,earlyReturn:true}},
    all {normal,s.bug==7,s.localRetained,s'={...s,cutProved:false}},
    all {normal,s.bug==8,s.window,s'={...s,earlyReturn:true}},
    all {s.bug==9,s.fault,not(s.stopped),s'={...s,hookCalled:true}},
    all {normal,s.bug==10,s.stage.get(1)==6,s'={...s,lateUse:true}},
    all {normal,s.bug==11,s.stage.get(1)==2,s'={...s,claims:s.claims.set(1,2)}},
    all {normal,s.bug==12,s.stage.get(2)==5,
      s'={...s,stage:s.stage.set(2,6),pin:s.pin.set(2,false),readers:s.readers.set(2,1)}}
  }
  val partial=s.stage.get(1)==7 and s.stage.get(2)==6
  val goal=if(s.mode==1) s.stopped else if(s.mode==0) s.vmFreed else partial
  action idle=s'=s
  action step=any {join(1),join(2),claim(1),claim(2),leaveTail(1),leaveTail(2),
    retainClaim,retainReader,guardFault,beginWindow(1),beginWindow(2),mutate,
    ack(1),ack(2),endWindow,localFailure,release(1),release(2),seal,cleanup,
    collect,processStop,bad,idle}
  val safe=all {
    donors.forall(d=>s.stage.get(d)==6 or s.pin.get(d)),
    donors.forall(d=>s.tail.get(d) or s.joined.get(d)),
    donors.forall(d=>s.claims.get(d)<=1 and s.key.get(d)==d),
    donors.forall(d=>s.readers.get(d)==0 or s.pin.get(d)),
    donors.forall(d=>s.stage.get(d)!=6 or (s.joined.get(d) and s.owner.get(d)==1 and s.readers.get(d)==0)),
    not(s.vmFreed) or donors.forall(d=>s.stage.get(d)==6 and not(s.pin.get(d))),
    not(s.localRetained) or s.cutProved,
    not(s.earlyReturn),not(s.hookCalled),not(s.lateUse)
  }
  // Individual action fairness excludes scheduling starvation; it does not
  // force a broken barrier or host hook to return in the two temporal mutants.
  temporal fair=weakFair(join(1),Set(s)).and(weakFair(join(2),Set(s)))
    .and(weakFair(claim(1),Set(s))).and(weakFair(claim(2),Set(s)))
    .and(weakFair(leaveTail(1),Set(s))).and(weakFair(leaveTail(2),Set(s)))
    .and(weakFair(retainClaim,Set(s))).and(weakFair(retainReader,Set(s)))
    .and(weakFair(guardFault,Set(s)))
    .and(weakFair(beginWindow(1),Set(s))).and(weakFair(beginWindow(2),Set(s)))
    .and(weakFair(mutate,Set(s))).and(weakFair(ack(1),Set(s)))
    .and(weakFair(ack(2),Set(s))).and(weakFair(endWindow,Set(s)))
    .and(weakFair(localFailure,Set(s))).and(weakFair(release(1),Set(s)))
    .and(weakFair(release(2),Set(s))).and(weakFair(seal,Set(s)))
    .and(weakFair(cleanup,Set(s))).and(weakFair(processStop,Set(s)))
  temporal completion=fair.implies(eventually(goal))
}
