module repair9_causal_projection {
  // Causal projection with the drain protocol ASSUMED complete.
  // Injected GC/alias states are hypotheses, not a native reproduction.
  type S={kind:int,phase:int,drainComplete:bool,rootFix:bool,rootVersion:int,
    rawVersion:int,word:int,cursor:int,layout:int,within:bool,metadata:bool,
    fault:bool,classified:bool,diagnosis:int,claimedWriter:bool,
    uniqueLink:bool,nativeReturn:bool,threadRoute:bool,
    head:int,tail:int,next1:int,next2:int,pending:int,active:int,
    starts:int,replies:int,masked:bool,parked:bool,otherEnabled:bool,
    dispatcherRoot:bool,terminal:bool,claimComplete:bool}
  var s:S
  pure def initial(k:int):S={kind:k,phase:0,drainComplete:true,
    rootFix:k!=1,rootVersion:1,rawVersion:1,word:0,cursor:0,layout:0,
    within:true,metadata:true,fault:false,classified:false,diagnosis:0,claimedWriter:false,
    uniqueLink:not(Set(11,12,13).contains(k)),nativeReturn:not(Set(14,15).contains(k)),
    threadRoute:k==15,head:0,tail:0,next1:0,next2:0,
    pending:if(Set(11,12,13,16).contains(k)) 2 else 1,active:0,
    starts:0,replies:0,masked:true,parked:false,otherEnabled:false,
    dispatcherRoot:true,terminal:false,claimComplete:false}
  action initNormalRoot=s'=initial(0)
  action initStaleRoot=s'=initial(1)
  action initRootFixed=s'=initial(2)
  action initFrameWithDrain=s'=initial(3)
  action initHeapWriteWithDrain=s'=initial(4)
  action initMistypedScalarWithDrain=s'=initial(5)
  action initExtentWithDrain=s'=initial(6)
  action initUnknownRaw=s'=initial(7)
  action initIntactScalar=s'=initial(8)
  action initFloatOverclaim=s'=initial(9)
  action initDelivery=s'=initial(10)
  action initSharedNext=s'=initial(11)
  action initTailGuard=s'=initial(12)
  action initWakeOnly=s'=initial(13)
  action initMaskedProcessor=s'=initial(14)
  action initThreadOnly=s'=initial(15)
  action initUniqueAndReturn=s'=initial(16)
  action initDispatcher=s'=initial(17)
  action initCallbackNoReply=s'=initial(18)
  action initEmptyMeansComplete=s'=initial(19)
  action collect=all {s.kind<10,s.phase==0,s'={...s,phase:1,rootVersion:2}}
  action refresh=all {s.kind<10,s.phase==1,
    s'={...s,phase:2,rawVersion:if(s.rootFix) s.rootVersion else s.rawVersion}}
  action selectCell=all {s.kind<10,s.phase==2,
    s'={...s,phase:3,
      word:if(Set(0,1,2).contains(s.kind)) (if(s.rawVersion==s.rootVersion) 0 else 3)
        else if(s.kind==8) 0 else 3,
      cursor:if(Set(3,6,9).contains(s.kind)) 2 else if(s.kind==7) 0
        else if(Set(4,5,8).contains(s.kind)) 3 else 1,
      layout:if(s.kind==8) 1 else 2,within:s.kind!=6,metadata:s.kind!=7}}
  action markHeader=all {s.kind<10,s.phase==3,
    s'={...s,phase:4,fault:s.word==3 or not(s.within)}}
  pure def classify(st:S):int=if(not(st.metadata)) 0 else if(not(st.within)) 4
    else if(st.cursor==1) 3 else if(st.cursor==2) 2
    else if(st.cursor==3 and st.layout==1) 1 else if(st.cursor==3) 6 else 0
  action diagnose=all {s.kind<10,s.phase==4,
    s'={...s,phase:5,classified:true,diagnosis:if(s.kind==9) 1 else classify(s)}}
  // Alias schedule starts with A->R. Re-enqueue A clears A.next, losing R.
  // Actual source requires an unproved duplicate-live-node precondition here.
  action publish=all {s.kind>=10,s.phase==0,
    s'={...s,phase:if(Set(17,19).contains(s.kind)) 15 else 10,
      head:if(Set(17,19).contains(s.kind)) 0 else 1,
      tail:if(Set(11,12,13,16).contains(s.kind)) 2
        else if(Set(17,19).contains(s.kind)) 0 else 1,
      next1:if(Set(11,12,13,16).contains(s.kind)) 2 else 0,
      active:if(Set(17,19).contains(s.kind)) 1 else 0}}
  action enqueueAgain=all {s.phase==10,
    s'={...s,phase:11,
      next1:if(not(s.uniqueLink)) 0 else s.next1,
      next2:if(not(s.uniqueLink)) 1 else s.next2,
      tail:if(not(s.uniqueLink)) 1 else s.tail}}
  action notify=all {s.phase==11,s'={...s,phase:12}}
  action park=all {s.phase==12,s'={...s,phase:13,parked:true}}
  action returnWait=all {s.phase==13,s.nativeReturn,
    s'={...s,phase:14,parked:false,masked:false,otherEnabled:true}}
  action dequeue=all {s.phase==14,s.head!=0,s.active==0,
    s'={...s,phase:15,active:s.head,
      head:if(s.head==1) s.next1 else s.next2,
      tail:if((if(s.head==1) s.next1 else s.next2)==0) 0 else s.tail,
      next1:if(s.head==1) 0 else s.next1,next2:if(s.head==2) 0 else s.next2}}
  action executeThunk=all {s.phase==15,s.active!=0,
    s'={...s,phase:16,starts:if(s.active==s.pending) s.starts+1 else s.starts}}
  action reply=all {s.phase==16,s.kind!=18,
    s'={...s,phase:if(s.active==s.pending) 18 else 14,
      replies:if(s.active==s.pending) 1 else s.replies,
      terminal:s.active==s.pending,active:0}}
  action callbackStop=all {s.phase==16,s.kind==18,s'={...s,phase:17}}
  action overclaimEmpty=all {s.kind==19,s.phase==15,not(s.claimComplete),
    s'={...s,claimComplete:true}}
  action idle=s'=s
  action step=any {collect,refresh,selectCell,markHeader,diagnose,
    publish,enqueueAgain,notify,park,returnWait,dequeue,executeThunk,reply,
    callbackStop,overclaimEmpty,idle}
  val noFault=not(s.fault)
  val honest=not(s.classified) or (s.diagnosis==classify(s) and not(s.claimedWriter))
  val reachable=s.head==s.pending or (s.head==1 and s.next1==s.pending)
    or (s.head==2 and s.next2==s.pending)
  val noLost=s.replies==1 or s.terminal or reachable
    or (s.active==s.pending and s.dispatcherRoot) or s.phase==0
  val honestReply=not(s.claimComplete) or s.replies==1 or s.terminal
  val notEmptyLost=not(s.phase==14 and s.head==0 and s.active==0 and s.replies==0)
  val notMaskedReachable=not(s.phase==13 and s.parked and reachable and not(s.otherEnabled))
  val goal=if(s.kind<10) s.phase==5 else s.terminal and s.replies==1
  temporal fairness=all {weakFair(collect,Set(s)),weakFair(refresh,Set(s)),
    weakFair(selectCell,Set(s)),weakFair(markHeader,Set(s)),weakFair(diagnose,Set(s)),
    weakFair(publish,Set(s)),weakFair(enqueueAgain,Set(s)),weakFair(notify,Set(s)),
    weakFair(park,Set(s)),weakFair(returnWait,Set(s)),weakFair(dequeue,Set(s)),
    weakFair(executeThunk,Set(s)),weakFair(reply,Set(s)),weakFair(callbackStop,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
}
