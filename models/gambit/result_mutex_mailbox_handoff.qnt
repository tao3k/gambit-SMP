// Concrete candidate protocol for ONE synchronous result-mutex sender.
// No join/lifecycle, TYPEID or release composition. No arbitrary drop action.
module result_mutex_mailbox_handoff {
  type State = { policy:int,pub:int,lock:int,route:int,desired:int,running:int,
    ready:int,queued:bool,active:bool,waiting:bool,executions:int,replied:bool,
    consumed:bool,returned:bool,mode:int,stored:bool,frameRoot:bool,
    heapEpoch:int,localEpoch:int,collected:bool,abandoned:bool,errorConsumed:bool,
    escaped:bool,selectErrorSeen:bool,abortWriteFailed:bool,blockedOnce:bool,moved:bool,allowMove:bool,
    masked:bool,maskUsed:bool,park:int -> int,gen:int -> int,seen:int -> int,
    parkUsed:Set[int],wake:Set[int],flags:Set[int],claims:int,posts:int }
  var s:State
  pure def initial(p:int,idle:bool,migrate:bool):State = {
    policy:p,pub:0,lock:0,route:0,desired:0,running:if(idle) -1 else 0,
    ready:-1,queued:false,active:false,waiting:false,executions:0,
    replied:false,consumed:false,returned:false,mode:0,stored:false,frameRoot:false,
    heapEpoch:0,localEpoch:0,collected:false,abandoned:false,errorConsumed:false,
    escaped:false,selectErrorSeen:false,abortWriteFailed:false,blockedOnce:false,moved:false,
    allowMove:migrate,masked:false,maskUsed:false,
    park:Map(0 -> (if(idle) 2 else 0),1 -> 0),gen:Map(0 -> 0,1 -> 0),
    seen:Map(0 -> 0,1 -> 0),parkUsed:if(idle) Set(0) else Set(),
    wake:Set(),flags:Set(),claims:0,posts:0 }
  action initRunning = s' = initial(0,false,false)
  action initIdle = s' = initial(0,true,false)
  action initMigration = s' = initial(0,false,true)
  action initParkRace = s' = {...initial(0,true,false),
    park:Map(0 -> 1,1 -> 0)}
  action initStaleBlock = s' = initial(1,false,false)
  action initLoseClaimRoot = s' = initial(2,false,false)
  action initConsumeWakeWithoutDebtCheck = s' = initial(3,true,false)
  action initParkWithoutValidation = s' = {...initial(4,true,false),
    park:Map(0 -> 1,1 -> 0)}
  action initWrongMigrationDestination = s' = {...initial(5,true,false),
    desired:1,ready:1,moved:true}
  action initReplyBeforeExecution = s' = initial(6,false,false)
  action initCaughtCallback = s'={...initial(0,false,false),mode:1}
  action initTargetAbandon = s'={...initial(0,false,false),mode:2}
  action initOpaqueExit = s'={...initial(0,false,false),mode:3}
  action initSelectError = s'={...initial(0,true,false),mode:5}
  action initTargetAbandonAfterEntry = s'={...initial(0,false,false),mode:4}
  action initAbortWriteEINTR = s'=initial(7,true,false)
  action initUnmappedReplyLocal = s'=initial(8,false,false)
  action initFakeReplyAfterEscape = s'={...initial(9,false,false),mode:3}
  action initSelectErrorSkipsCleanup = s'={...initial(10,true,false),mode:5}
  // One target's runnable entry, publication generation and committed sleeper wake
  // are updated under the SAME destination processor lock.
  pure def postReady(x:State,p:int):State = {...x,ready:p,posts:x.posts+1,
    gen:x.gen.set(p,x.gen.get(p)+1),
    wake:if(x.park.get(p)==2 and x.policy!=7) x.wake.union(Set(p)) else x.wake,
    abortWriteFailed:x.policy==7 and x.park.get(p)==2}
  action acquirePublisher = all { s.pub==0,s.lock==0,
    s'={...s,pub:1,lock:1,route:if(s.running>=0) s.running else s.desired,
      ready:if(s.running<0) -1 else s.ready} }
  action publishMailbox = {
    val x={...s,pub:2,queued:true,waiting:true}
    all {s.pub==1,s.lock==1,s'=if(s.running<0) postReady(x,if(s.policy==5) 0 else s.desired) else x} }
  action releasePublisher = all { s.pub==2,s.lock==1,s'={...s,pub:3,lock:0} }
  // Notification has no request next link and never changes its ownership.
  action notifyOnly = all { s.pub==3,
    s'={...s,pub:4,flags:s.flags.union(Set(s.route))} }
  // Check pending debt in the SAME thread-locked commit that would suspend it.
  action commitTargetBlock = {
    val x={...s,running:-1,blockedOnce:true}
    all {s.lock==0,s.running>=0,not(s.blockedOnce),not(s.active),not(s.returned),
      s'=if(s.queued and s.policy!=1) postReady(x,s.desired) else {...x,ready:-1}} }
  action migrate = all { s.allowMove,not(s.moved),s.lock==0,s.running>=0,
    not(s.active),not(s.returned),
    s'=postReady({...s,desired:1,running:-1,moved:true},1) }
  action preparePark = any {prepareParkAt(0),prepareParkAt(1)}
  action prepareParkAt(p:int):bool = all {
    s.park.get(p)==0,
    not(s.parkUsed.contains(p)),s.ready!=p,s.running!=p,
    s'={...s,park:s.park.set(p,1),seen:s.seen.set(p,s.gen.get(p)),
      parkUsed:s.parkUsed.union(Set(p))} }
  action commitPark = any {commitParkAt(0),commitParkAt(1)}
  action commitParkAt(p:int):bool = all {
    s.park.get(p)==1,
    (s.ready!=p and s.running!=p and s.seen.get(p)==s.gen.get(p)) or s.policy==4,
    s'={...s,park:s.park.set(p,2)} }
  action cancelPark = any {cancelParkAt(0),cancelParkAt(1)}
  action cancelParkAt(p:int):bool = all {
    s.park.get(p)==1,
    s.ready==p or s.running==p or s.seen.get(p)!=s.gen.get(p),
    s'={...s,park:s.park.set(p,0)} }
  action observeWake = any {observeWakeAt(0),observeWakeAt(1)}
  action observeWakeAt(p:int):bool = all {
    s.park.get(p)==2,s.wake.contains(p),
    s'={...s,wake:s.wake.exclude(Set(p)),
      park:if(s.policy==3) s.park else s.park.set(p,0)} }
  action restoreTarget = all { s.lock==0,s.running<0,s.ready>=0,
    s.park.get(s.ready)==0,
    s'={...s,running:s.ready,ready:-1} }
  action enterMaskedInterval = all { not(s.maskUsed),not(s.active),
    not(s.returned),s'={...s,masked:true,maskUsed:true} }
  action leaveMaskedInterval = all { s.masked,s'={...s,masked:false} }
  // Common legal scheduler/interrupt/resume checkpoint, outside masked GC.
  // Pop AND rooted local ownership acquisition are one thread-locked transition.
  action claimAtCheckpoint = all { s.lock==0,s.running>=0,s.queued,
    not(s.masked),not(s.replied),s.park.get(s.running)==0,
    s'={...s,queued:false,active:s.policy!=2,frameRoot:s.policy!=2,
      localEpoch:s.heapEpoch,claims:s.claims+1} }
  action executeThunk = all {s.active,s.executions==0,s.mode!=2,
    s'={...s,executions:1,escaped:s.mode==3} }
  action storeResult = all {s.active,s.executions==1,not(s.stored),(s.mode<=1 or s.mode==5),
    s'={...s,stored:true} }
  // The object can remain alive through other roots while an unmapped local
  // retains a stale address. This is local-update coverage, not object death.
  action collectBetweenStoreAndUnlock = all {s.active,s.stored,not(s.replied),
    not(s.collected),s'={...s,collected:true,heapEpoch:s.heapEpoch+1,
      frameRoot:s.policy!=8,localEpoch:if(s.policy==8) s.localEpoch else s.heapEpoch+1} }
  action abandonTarget = all {s.mode==2 or s.mode==4,s.pub>=3,s.lock==0,
    not(s.replied),not(s.stored),s.mode==2 or s.executions==1,
    s'={...s,abandoned:true,replied:true,active:false,frameRoot:false,returned:true} }
  action fabricateEscapeReply = all {s.policy==9,s.escaped,not(s.replied),
    s'={...s,replied:true} }
  action returnSelectError = all {s.mode==5,not(s.selectErrorSeen),
    s.park.get(0)==2,s'={...s,selectErrorSeen:true,wake:s.wake.exclude(Set(0)),
      park:if(s.policy==10) s.park else s.park.set(0,0)} }
  action unlockReply = all { s.active,not(s.replied),
    (s.executions==1 and s.stored and not(s.escaped)) or s.policy==6,s'={...s,replied:true} }
  action consumeResult = all { s.waiting,s.replied,not(s.consumed),
    s'={...s,consumed:true,waiting:false,errorConsumed:s.abandoned} }
  action dispatcherReturn = all { s.active,s.replied,not(s.returned),
    s'={...s,active:false,frameRoot:false,returned:true} }
  val opaqueRetained=s.escaped and s.active and s.frameRoot and not(s.replied) and not(s.consumed)
  val done=s.pub==4 and s.consumed and s.returned
  action step=any { acquirePublisher,publishMailbox,releasePublisher,notifyOnly,
    commitTargetBlock,migrate,preparePark,commitPark,cancelPark,observeWake,
    restoreTarget,enterMaskedInterval,leaveMaskedInterval,claimAtCheckpoint,
    executeThunk,storeResult,collectBetweenStoreAndUnlock,abandonTarget,
    fabricateEscapeReply,returnSelectError,unlockReply,consumeResult,
    dispatcherReturn,all {done or opaqueRetained,s'=s} }
  // Reachability and effective service are distinct. Wake loss can leave a node
  // reachable but make completion impossible; noLost by itself is insufficient.
  val noLost=not(s.waiting and not(s.replied)) or s.queued or s.active
  val serviceable=s.replied or not(s.queued) or s.running>=0 or
    (s.ready>=0 and (s.park.get(s.ready)!=2 or s.wake.contains(s.ready)))
  val safe=all {noLost,serviceable,s.claims<=1,s.executions<=1,
    not(s.queued and s.active),
    not(s.replied) or s.abandoned or (s.executions==1 and s.stored),
    not(s.active) or (s.frameRoot and s.localEpoch==s.heapEpoch),
    not(s.escaped) or (s.active and s.frameRoot and not(s.replied) and not(s.consumed)),
    not(s.errorConsumed) or s.abandoned,
    not(s.abandoned and s.consumed) or s.errorConsumed,
    s.ready<0 or s.ready==s.desired,s.running<0 or s.running==s.desired,
    not(s.consumed) or s.replied,
    // Per bounded transition, not a native wall-clock cost certificate.
    s.posts<=3}
  temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
