module interrupt_request_lifecycle {
  // Two bounded synchronous requests: nested child retains its suspended parent.
  // owner: 1 queue, 2 activation, 3 migration transfer, 4 destination run queue,
  // 5 reply, 6 caller consumed, 8 opaque retained. Not C memory refinement.
  type Request = { token:int, parent:int, phase:int, owner:int, runMask:int,
    mover:int, moveGC:bool, actionGC:bool, mutexRoot:bool, resultRoot:bool,
    waitAttempt:bool, blocked:bool, unlocked:bool, ready:bool, consumed:bool,
    stored:bool, status:int, valueEpoch:int, heapEpoch:int, wakeCount:int, preMoved:bool,
    routeEpoch:int, targetEpoch:int, staleDispatch:bool,
    session:int, vm:int, lookupToken:int, dispatchDone:bool, closed:bool,
    replayed:bool, coverage:bool, claimsBreakpoint:bool,
    executions:int, resultWrites:int, replies:int, targetEnded:bool }
  // Delivery is a bounded intrusive queue refinement, not an observed stuck token.
  // Tokens 1 and 2 share next slot 0; a detached local is a real consumer.
  type Delivery = { enabled:bool,stage:int,head:int,tail:int,next1:int,next2:int,
    local:int,tq:bool,receiver:bool,notified:bool,idle:bool,target:int,sampled:int,
    moved:bool,rechecked:bool,lost:bool,wrongTarget:bool,falseEmpty:bool }
  pure val deliveryInitial = { enabled:false,stage:0,head:1,tail:2,next1:2,next2:0,
    local:0,tq:false,receiver:false,notified:true,idle:false,target:0,sampled:0,
    moved:false,rechecked:false,lost:false,wrongTarget:false,falseEmpty:false }
  type State = { delivery:Delivery,policy:int, early:bool, nested:bool, migrate:bool, slow:bool,
    outcome:int, active:int, childCreated:bool, gcCount:int,
    outer:Request, inner:Request }
  var s:State
  pure def request(t:int,p:int):Request = { token:t,parent:p,phase:0,owner:1,
    runMask:1,mover:0,moveGC:false,actionGC:false,mutexRoot:true,resultRoot:true,
    waitAttempt:false,blocked:false,unlocked:false,ready:false,consumed:false,
    stored:false,status:0,valueEpoch:0,heapEpoch:0,wakeCount:0,preMoved:false,routeEpoch:0,targetEpoch:0,staleDispatch:false,session:1,vm:1,lookupToken:t,
    dispatchDone:false,closed:false,replayed:false,coverage:true,claimsBreakpoint:false,executions:0,resultWrites:0,replies:0,targetEnded:false }
  pure def initial(p:int,e:bool,n:bool,m:bool,l:bool,o:int):State = {
    delivery:deliveryInitial,policy:p,early:e,nested:n,migrate:m,slow:l,outcome:o,active:1,
    childCreated:false,gcCount:0,outer:request(1,0),inner:request(2,1) }
  action init = s' = initial(0,false,false,true,true,0)
  action initEarlyNested = s' = initial(0,true,true,true,true,0)
  action initCaught = s' = initial(0,true,true,true,true,1)
  action initTerminate = s' = initial(0,false,true,true,true,2)
  action initOpaque = s' = initial(0,false,true,true,true,3)
  action initRawEscape = s' = initial(0,false,true,true,true,4)
  action initFast = s' = initial(0,true,true,false,false,0)
  action initRequireWake = s' = initial(1,true,true,true,true,0)
  action initOverwriteParent = s' = initial(2,true,true,true,true,0)
  action initLoseParentRoot = s' = initial(3,true,true,true,true,0)
  action initDuplicateMigration = s' = initial(4,false,true,true,true,0)
  action initLoseResultRoot = s' = initial(5,false,true,true,true,0)
  action initEscapeSuccess = s' = initial(6,false,true,true,true,3)
  action initDropTerminated = s' = initial(7,false,true,true,true,2)
  action initStaleResult = s' = initial(8,false,true,true,true,0)
  action initStaleRoute = s' = initial(9,false,true,true,true,0)
  action initEarlyRelease = s' = initial(10,true,true,true,true,0)
  action initOpaqueRelease = s' = initial(11,false,true,true,true,3)
  action initReuseToken = s' = initial(12,true,true,true,true,0)
  action initNativeTLSParent = s' = initial(13,true,true,true,true,0)
  action initAddressLookup = s' = initial(14,true,true,true,true,0)
  action initGapVerdict = s' = initial(15,false,true,true,true,0)
  action initReplyReplay = s' = initial(16,false,true,true,true,0)
  action initEarlyChildRelease = s' = initial(17,true,true,true,true,0)
  action initDuplicateExecution = s' = initial(18,true,true,true,true,0)
  action initDuplicateReply = s' = initial(19,true,true,true,true,0)
  action initAbandonAsSuccess = s' = initial(20,false,true,true,true,2)
  action initOldOwnerExecution = s' = initial(21,true,true,true,true,0)
  action initOpaqueReplay = s' = initial(22,false,true,true,true,3)
  pure def deliveryState(p:int):State = {
    ...initial(p,false,false,false,false,0),
    outer:{...request(1,0),waitAttempt:true,blocked:true},
    delivery:{...deliveryInitial,enabled:true,stage:1} }
  action initDelivery = s' = deliveryState(0)
  action initDeliveryLostWake = s' = deliveryState(23)
  action initDeliveryDuplicateMiddle = s' = deliveryState(24)
  action initDeliverySharedLink = s' = deliveryState(25)
  action initDeliveryStaleReceiver = s' = deliveryState(26)
  action initDeliveryFalseEmpty = s' = deliveryState(27)
  action initDeliveryDropLocal = s' = deliveryState(28)
  val d = s.delivery
  val inProcessor1 = d.head == 1 or (d.head == 2 and d.next2 == 1)
  val inProcessor2 = d.head == 2 or (d.head == 1 and d.next1 == 2)
  val owners1 = (if(inProcessor1) 1 else 0) + (if(d.local == 1) 1 else 0)
    + (if(d.tq) 1 else 0) + (if(d.receiver) 1 else 0)
  action deliveryMove = all { d.enabled,not(d.moved),d.stage <= 2,
    s' = {...s,delivery:{...d,target:1,moved:true,rechecked:false}} }
  action deliveryClearWake = all { d.enabled,d.notified,
    s' = {...s,delivery:{...d,notified:false}} }
  action deliveryPop = all { d.enabled,d.stage == 1,d.head == 1,
    s' = {...s,delivery:{...d,stage:2,head:d.next1,next1:0,local:1,idle:false}} }
  action deliveryRecheck = all { d.enabled,d.stage == 2,
    s' = {...s,delivery:{...d,sampled:d.target,rechecked:true}} }
  action deliveryReceive = all { d.enabled,d.stage == 2,
    (d.rechecked and d.sampled == d.target) or s.policy == 26,
    s' = {...s,delivery:{...d,stage:4,local:0,receiver:true,
      wrongTarget:not(d.rechecked) or d.sampled != d.target}} }
  action deliveryReroute = all { d.enabled,d.stage == 2,d.sampled != d.target,
    s' = {...s,delivery:{...d,stage:3,local:0,tq:true,notified:true,idle:false}} }
  action deliveryThreadDrain = all { d.enabled,d.stage == 3,d.tq,
    s' = {...s,delivery:{...d,stage:4,tq:false,receiver:true,
      sampled:d.target,rechecked:true}} }
  action deliveryHandoff = all { d.enabled,d.stage == 4,d.receiver,
    s' = {...s,delivery:{...d,enabled:false,stage:5},
      outer:{...s.outer,phase:1,owner:2,routeEpoch:d.target,targetEpoch:d.target}} }
  // The current tail guard does reject an already-tail re-raise.
  action deliveryTailRetry = all { d.enabled,d.stage == 1,d.tail == 2,
    s' = {...s,delivery:{...d,notified:true}} }
  // Actual enqueue assignments for a non-tail node, which the tail guard cannot reject.
  action deliveryDuplicateMiddle = all { d.enabled,s.policy == 24,d.stage == 1,
    s' = {...s,delivery:{...d,next1:0,next2:1,tail:1,lost:true}} }
  // Linking a still-local/shared node into another queue before acknowledgement.
  action deliverySharedLink = all { d.enabled,s.policy == 25,d.stage == 1,
    s' = {...s,delivery:{...d,tq:true,next1:0,lost:true}} }
  action deliveryLostWake = all { d.enabled,s.policy == 23,d.stage == 1,
    not(d.notified),s' = {...s,delivery:{...d,idle:true}} }
  action deliveryFalseEmpty = all { d.enabled,s.policy == 27,d.stage == 2,
    s' = {...s,delivery:{...d,falseEmpty:true}} }
  action deliveryDropLocal = all { d.enabled,s.policy == 28,d.stage == 2,
    s' = {...s,delivery:{...d,local:0,lost:true}} }
  action deliveryStep = any { deliveryMove,deliveryClearWake,deliveryPop,
    deliveryRecheck,deliveryReceive,deliveryReroute,deliveryThreadDrain,
    deliveryHandoff,deliveryTailRetry,deliveryDuplicateMiddle,deliverySharedLink,
    deliveryLostWake,deliveryFalseEmpty,deliveryDropLocal }
  val deliverySafe = d.stage == 0 or all {
    owners1 == 1,inProcessor2,not(d.lost),not(d.wrongTarget),not(d.falseEmpty),
    not(d.idle and d.head != 0 and not(d.notified)) }
  val q = if(s.active == 1) s.outer else s.inner
  pure def updated(x:State,r:Request):State =
    if(x.active == 1) {...x,outer:r} else {...x,inner:r}
  val earlyCurrent = s.early and s.active == 1
  action wait = all { not(q.waitAttempt),
    if(earlyCurrent) q.phase == 5 else q.phase == 0,
    s' = updated(s,{...q,waitAttempt:true,blocked:not(q.unlocked),
      ready:if(q.unlocked) s.policy != 1 else q.ready}) }
  action dequeue = all { q.phase == 0,earlyCurrent or q.waitAttempt,
    s' = updated(s,{...q,phase:1,owner:2,coverage:s.policy != 15,claimsBreakpoint:s.policy == 15}) }
  action targetMovesBeforeDispatch = all { q.phase == 1,not(q.preMoved),
    s' = updated(s,{...q,preMoved:true,targetEpoch:1,runMask:2}) }
  action recheckReceiver = all { q.phase == 1,q.routeEpoch != q.targetEpoch,
    s' = updated(s,{...q,routeEpoch:q.targetEpoch}) }
  action dispatch = all { q.phase == 1,
    q.routeEpoch == q.targetEpoch or s.policy == 9,
    s' = updated(s,{...q,phase:2,executions:q.executions+1,staleDispatch:q.routeEpoch != q.targetEpoch}) }
  action beginMove = all { q.phase == 2,s.migrate,q.mover == 0,
    s' = updated(s,{...q,mover:1,owner:3,runMask:0}) }
  action moveCollect = all { q.mover == 1,not(q.moveGC),
    s' = updated({...s,gcCount:s.gcCount+1},{...q,moveGC:true,
      heapEpoch:q.heapEpoch+1,valueEpoch:q.valueEpoch+1,
      lookupToken:if(s.policy == 14) 0 else q.lookupToken}) }
  action publishMove = all { q.mover == 1,q.moveGC,
    s' = updated(s,{...q,mover:2,owner:4,
      runMask:if(s.policy == 4) 3 else 0}) }
  action restoreMove = all { q.mover == 2,
    s' = updated(s,{...q,mover:3,owner:2,runMask:2,
      parent:if(s.policy == 13 and s.active == 2) 0 else q.parent}) }
  val moveFinished = not(s.migrate) or q.mover == 3
  action nest = all { s.active == 1,s.nested,not(s.childCreated),
    q.phase == 2,moveFinished,
    s' = {...s,active:2,childCreated:true,
      outer:{...s.outer,mutexRoot:s.policy != 3},inner:request(2,1)} }
  val childFinished = s.active == 2 or not(s.nested) or
    (s.childCreated and s.inner.consumed)
  action actionCollect = all { q.phase == 2,moveFinished,childFinished,
    not(q.actionGC),s' = updated({...s,gcCount:s.gcCount+1},
      {...q,actionGC:true,heapEpoch:q.heapEpoch+1,valueEpoch:q.valueEpoch+1}) }
  action finishAction = all { q.phase == 2,q.actionGC,moveFinished,childFinished,
    s' = if(s.active == 1 and s.outcome >= 3)
      updated(s,{...q,phase:9,owner:8,consumed:s.policy == 6,closed:s.policy == 11})
    else updated(s,{...q,phase:3,stored:not(s.active == 1 and s.outcome == 2 and s.policy != 20),owner:5,
      resultWrites:if(s.active == 1 and s.outcome == 2 and s.policy != 20) 0 else q.resultWrites+1,
      targetEnded:s.active == 1 and s.outcome == 2,
      status:if(s.active == 1 and s.policy != 20) s.outcome else 0,
      mutexRoot:s.policy != 5}) }
  action replyCollect = all { q.phase == 3,s.slow,
    s' = updated({...s,gcCount:s.gcCount+1},{...q,phase:4,
      resultRoot:q.mutexRoot,heapEpoch:q.heapEpoch+1,
      valueEpoch:if(s.policy == 8) q.valueEpoch else q.heapEpoch+1}) }
  action fastReply = all { q.phase == 3,not(s.slow),
    s' = updated(s,{...q,phase:4}) }
  action unlock = all { q.phase == 4,
    s' = updated(s,{...q,phase:5,unlocked:true,blocked:false,replies:q.replies+1,
      owner:if(s.policy == 7 and q.status == 2) 0 else 5,
      ready:q.waitAttempt,wakeCount:if(q.blocked) 1 else 0,closed:s.policy == 10}) }
  action consume = all { q.phase == 5,q.waitAttempt,q.ready,
    s' = updated(s,{...q,phase:6,consumed:true,owner:6}) }
  action returnToParent = all { s.active == 2,s.inner.consumed,
    s' = {...s,active:1,outer:{...s.outer,
      token:if(s.policy == 2) 2 else s.outer.token}} }
  action dispatchAckOuter = all { s.outer.phase >= 5,s.outer.phase != 9,
    not(s.outer.dispatchDone),s' = {...s,outer:{...s.outer,dispatchDone:true}} }
  action dispatchAckInner = all { s.childCreated,s.inner.phase >= 5,
    s.inner.phase != 9,not(s.inner.dispatchDone),
    s' = {...s,inner:{...s.inner,dispatchDone:true}} }
  action closeInner = all { s.childCreated,s.inner.consumed,s.inner.dispatchDone,
    s.active == 1 or s.policy == 17,
    not(s.inner.closed),s' = {...s,inner:{...s.inner,closed:true}} }
  action closeOuter = all { s.outer.consumed,s.outer.dispatchDone,
    not(s.outer.closed),not(s.childCreated) or s.inner.closed,
    s' = {...s,outer:{...s.outer,closed:true}} }
  action reuseClosedChild = all { s.policy == 12,s.inner.closed,
    s.inner.token == 2,s' = {...s,inner:{...s.inner,token:1}} }
  action replyReplay = all { s.policy == 16,q.phase == 5,not(q.replayed),
    s' = updated(s,{...q,phase:1,owner:1,replayed:true}) }
  action abandonBeforeDispatch = all { s.active == 1,s.outcome == 2,
    q.phase == 1,s' = updated(s,{...q,phase:3,owner:5,status:2,
      stored:false,resultWrites:0,targetEnded:true}) }
  action duplicateExecution = all { s.policy == 18,q.phase == 2,q.executions == 1,
    s' = updated(s,{...q,executions:2}) }
  action duplicateReply = all { s.policy == 19,q.phase == 5,q.replies == 1,
    s' = updated(s,{...q,replies:2}) }
  action oldOwnerExecution = all { s.policy == 21,q.mover == 2,
    s' = updated(s,{...q,executions:q.executions+1,runMask:3}) }
  action opaqueReplay = all { s.policy == 22,q.phase == 9,
    s' = updated(s,{...q,phase:2,executions:q.executions+1}) }
  val lifecycleDone = s.active == 1 and (s.outer.phase == 6 or s.outer.phase == 9)
  val done = s.active == 1 and
    ((s.outer.phase == 6 and s.outer.closed) or s.outer.phase == 9)
  val oldDone = s.active == 1 and (s.outer.phase == 6 or s.outer.phase == 9)
  action step = if(d.enabled) deliveryStep else any { wait,dequeue,targetMovesBeforeDispatch,recheckReceiver,dispatch,beginMove,moveCollect,publishMove,
    restoreMove,nest,actionCollect,finishAction,replyCollect,fastReply,
    unlock,consume,returnToParent,dispatchAckOuter,dispatchAckInner,
    closeInner,closeOuter,reuseClosedChild,replyReplay,abandonBeforeDispatch,
    duplicateExecution,duplicateReply,oldOwnerExecution,opaqueReplay,all { done,s' = s } }
  pure def requestSafe(r:Request):bool = all {
    r.owner > 0,r.runMask != 3,r.executions <= 1,r.resultWrites <= 1,r.replies <= 1,
    r.resultWrites <= r.executions,
    not(r.targetEnded) or (r.status == 2 and r.resultWrites == 0),not(r.staleDispatch),not(r.replayed),
    r.session == 1,r.vm == 1,r.lookupToken == r.token,
    not(r.claimsBreakpoint) or r.coverage,
    not(r.closed) or (r.consumed and r.dispatchDone and r.phase == 6),
    not(r.consumed) or (r.phase == 6 and r.waitAttempt and r.ready and r.unlocked),
    not(r.unlocked and r.waitAttempt) or r.ready,
    not(r.stored and r.phase >= 4) or
      (r.mutexRoot and r.resultRoot and r.valueEpoch == r.heapEpoch) }
  val safe = all { deliverySafe,requestSafe(s.outer),
    not(s.childCreated) or requestSafe(s.inner),
    s.outer.token == 1,s.inner.token == 2,s.inner.parent == s.outer.token,
    not(s.active == 2 and s.gcCount > 0) or s.outer.mutexRoot,
    not(s.outer.closed and s.childCreated) or s.inner.closed,
    not(s.inner.closed) or s.active != 2 }
}
