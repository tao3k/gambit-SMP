module recursive_ffi_loan_composition {
  // Native nesting: CF1 -> SF2 -> CF3 -> SF4 -> CF5, one resource.
  // SF matching return, CF cleanup, and run-anchor release are distinct events.
  type S={mode:int,bug:int,stack:List[int],p1:int,p2:int,p3:int,p4:int,p5:int,
    entered:Set[int],popped:Set[int],loans:Set[int],using:Set[int],roots:Set[int],
    records:Set[int],pins:Set[int],markers:Set[int],vmRefs:int,anchor:bool,
    resourcePin:bool,metaBase:bool,metaFree:bool,closed:bool,vmFree:bool,
    op:int,calls:int,freed:bool,unwinding:bool,target:int,reached:bool,
    prefixFailed:bool,resultFailed:bool,retried:bool,fault:bool,gc:int,
    rootVersion:int,returnOwner:int,returnMoved:bool,returnRefused:bool,bad:bool}
  pure val CF=Set(1,3,5)
  pure val SF=Set(2,4)
  var s:S
  pure def pc(x:S,i:int):int=if(i==1) x.p1 else if(i==2) x.p2 else if(i==3) x.p3 else if(i==4) x.p4 else x.p5
  pure def setpc(x:S,i:int,n:int):S={...x,p1:if(i==1) n else x.p1,p2:if(i==2) n else x.p2,p3:if(i==3) n else x.p3,p4:if(i==4) n else x.p4,p5:if(i==5) n else x.p5}
  val top=if(s.stack.length()==0) 0 else s.stack[s.stack.length()-1]
  val live=Set(0,1,2,3,4).filter(i=>i<s.stack.length()).map(i=>s.stack[i])
  pure def initial(m:int,b:int):S={mode:m,bug:b,stack:[1],p1:1,p2:0,p3:0,p4:0,p5:0,
    entered:Set(1),popped:Set(),loans:Set(),using:Set(),roots:Set(1),records:Set(1),
    pins:Set(1),markers:Set(),vmRefs:3,anchor:true,resourcePin:true,metaBase:true,
    metaFree:false,closed:false,vmFree:false,op:0,calls:0,freed:false,
    unwinding:false,target:0,reached:false,prefixFailed:false,resultFailed:false,
    retried:false,fault:false,gc:0,rootVersion:0,returnOwner:0,returnMoved:false,returnRefused:false,bad:false}
  action initNested=s'=initial(0,0)
  action initPrefixFailure=s'=initial(1,0)
  action initInnerBoundary=s'=initial(2,0)
  action initOuterBoundary=s'=initial(3,0)
  action initTrampolineRetry=s'=initial(4,0)
  action initRetainedCleanup=s'=initial(5,0)
  action initResultFailure=s'=initial(6,0)
  action initReturnedPointer=s'=initial(7,0)
  action initReturnLoanDiesAtMarker=s'=initial(7,16)
  action initReturnOwnerFrameGone=s'=initial(7,17)
  action initMatchedDropsOuter=s'=initial(0,1)
  action initPrefixBypassesDrain=s'=initial(1,2)
  action initRetryDrainsOuter=s'=initial(4,3)
  action initJumpSkipsJournal=s'=initial(2,4)
  action initFreeMetadataAtLoanZero=s'=initial(0,5)
  action initReadAfterLastReference=s'=initial(0,6)
  action initKillAllMarkers=s'=initial(0,7)
  action initRestoreStaleRoots=s'=initial(0,8)
  action initWrongOwnerUnwind=s'=initial(2,9)
  action initDuplicateUnwind=s'=initial(2,10)
  action initDropPinBeforeTail=s'=initial(0,11)
  action initRetryUncertainCleanup=s'=initial(5,12)
  action initResultBypassesDrain=s'=initial(6,13)
  action initSkipCallbackParent=s'=initial(0,14)
  action initDropRunAnchor=s'=initial(0,15)
  action borrow=all {CF.contains(top),pc(s,top)==1,s.op==0,not(s.unwinding),
    s'=setpc({...s,loans:s.loans.union(Set(top))},top,2)}
  action refuse=all {CF.contains(top),pc(s,top)==1,s.op!=0,not(s.unwinding),s'=setpc(s,top,4)}
  action body=all {CF.contains(top),pc(s,top)==2,not(s.unwinding),s.mode!=1 or top!=5,
    s'=setpc({...s,using:s.using.union(Set(top))},top,3)}
  action push=all {top>0,top<5,pc(s,top)==3,not(s.unwinding),not(s.entered.contains(top+1)),
    val n=top+1
    s'=setpc({...s,stack:s.stack.append(n),entered:s.entered.union(Set(n)),
      roots:s.roots.union(Set(n)),pins:s.pins.union(Set(n)),vmRefs:s.vmRefs+1,
      markers:if(SF.contains(n)) s.markers.union(Set(n)) else s.markers,
      records:if(CF.contains(n)) s.records.union(Set(n)) else s.records},n,if(CF.contains(n)) 1 else 3)}
  action prefixError=all {s.mode==1,top==5,s.p5==2,not(s.unwinding),s'=setpc({...s,prefixFailed:true},5,4)}
  action result=all {CF.contains(top),pc(s,top)==3,not(s.unwinding),
    top==5 or s.popped.contains(top+1),not(Set(2,3,5).contains(s.mode)) or top!=5,
    s.mode!=4 or top!=5 or s.retried,
    s'=setpc({...s,resultFailed:s.resultFailed or (s.mode==6 and top==5)},top,4)}
  action drain=all {CF.contains(top),pc(s,top)==4,not(s.unwinding),
    s'=setpc({...s,loans:s.loans.exclude(if(top==3 and s.returnMoved) Set(top,6) else Set(top)),using:s.using.exclude(if(top==3 and s.returnMoved) Set(top,6) else Set(top))},top,5)}
  action matchedReturn=all {SF.contains(top),pc(s,top)==3,not(s.unwinding),s.popped.contains(top+1),s'=setpc(s,top,4)}
  action acquireReturnedPointer=all {s.mode==7,top==4,s.p4==4,s.op==0,s.returnOwner==0,not(s.returnRefused),
    s'={...s,returnOwner:4,loans:s.loans.union(Set(6)),using:s.using.union(Set(6)),records:s.records.union(Set(6))}}
  action returnRefusal=all {s.mode==7,top==4,s.p4==4,s.op!=0,s.returnOwner==0,not(s.returnRefused),s'={...s,returnRefused:true}}
  action attachReturnToParent=all {s.mode==7,top==4,s.p4==4,s.returnOwner==4,s.loans.contains(6),
    s'={...s,returnOwner:3,returnMoved:true}}
  action killMarker=all {SF.contains(top),pc(s,top)==4,not(s.unwinding),s.mode!=7 or top!=4 or s.returnMoved or s.returnRefused,s'=setpc({...s,markers:s.markers.exclude(Set(top))},top,5)}
  action trampolineRetry=all {s.mode==4,top==5,s.p5==3,not(s.retried),s'={...s,retried:true}}
  action beginUnwind=all {Set(2,3,5).contains(s.mode),top==5,s.p5==3,not(s.unwinding),not(s.reached),
    s'={...s,unwinding:true,target:if(s.mode==3) 0 else 2}}
  action crossFrame=all {s.unwinding,top>0,top!=s.target,pc(s,top)<5,s.mode!=5,
    s'=setpc({...s,loans:s.loans.exclude(Set(top)),using:s.using.exclude(Set(top)),markers:s.markers.exclude(Set(top))},top,5)}
  action retainFailure=all {s.mode==5,s.unwinding,top==5,s.p5==3,s'={...s,fault:true}}
  action reachedBoundary=all {s.unwinding,top==s.target,s'={...s,unwinding:false,reached:true}}
  action nativeTail=all {top>0,pc(s,top)==5,s'=setpc(s,top,6)}
  action popFrame=all {top>0,pc(s,top)==6,
    s'={...s,stack:s.stack.slice(0,s.stack.length()-1),popped:s.popped.union(Set(top)),
      roots:s.roots.exclude(Set(top)),records:s.records.exclude(if(top==3 and s.returnMoved) Set(top,6) else Set(top)),pins:s.pins.exclude(Set(top)),vmRefs:s.vmRefs-1}}
  action gc=all {s.gc<2,top>0,s'={...s,gc:s.gc+1,rootVersion:s.gc+1}}
  action close=all {not(s.closed),s'={...s,closed:true}}
  action drainRequest=all {s.closed,s.op==0,s'={...s,op:1}}
  action claim=all {s.op<2,s.loans.size()==0,s'={...s,op:2}}
  action release=all {s.op==2,s.calls==0,s'={...s,calls:1,freed:true,resourcePin:false,metaBase:false,vmRefs:s.vmRefs-1,op:3}}
  action freeMetadata=all {not(s.metaBase),s.records.size()==0,not(s.metaFree),s'={...s,metaFree:true}}
  action runTail=all {top==0,not(s.unwinding),s.anchor,s'={...s,anchor:false,vmRefs:s.vmRefs-1}}
  action freeVm=all {s.closed,s.vmRefs==0,not(s.vmFree),s'={...s,vmFree:true}}
  action protocolStep=any {borrow,refuse,body,push,prefixError,result,drain,matchedReturn,acquireReturnedPointer,returnRefusal,attachReturnToParent,killMarker,trampolineRetry,beginUnwind,crossFrame,retainFailure,reachedBoundary,nativeTail,popFrame,gc,close,drainRequest,claim,release,freeMetadata,runTail,freeVm}
  action mutant=any {
    all {s.bug==1,top==4,s.popped.contains(5),s'={...s,loans:s.loans.exclude(Set(1,3))}},
    all {s.bug==2,s.prefixFailed,s.p5==4,s'=setpc(s,5,5)},
    all {s.bug==3,s.retried,s'={...s,loans:s.loans.exclude(Set(1,3))}},
    all {s.bug==4,s.unwinding,top==5,s.p5==3,s'={...s,stack:[1,2,3,4],pins:s.pins.exclude(Set(5)),vmRefs:s.vmRefs-1}},
    all {s.bug==5,s.loans.size()==0,s.records.size()>0,s'={...s,metaFree:true}},
    all {s.bug==6,s.popped.contains(1),s'={...s,bad:true}},
    all {s.bug==7,top==4,s.popped.contains(5),s'={...s,markers:Set()}},
    all {s.bug==8,s.gc>0,top>0,s'={...s,rootVersion:0}},
    all {s.bug==9,s.unwinding,top==5,s'={...s,bad:true}},
    all {s.bug==10,s.unwinding,s.popped.contains(5),s'={...s,vmRefs:s.vmRefs-1}},
    all {s.bug==11,top>0,pc(s,top)==5,s'={...s,pins:s.pins.exclude(Set(top)),vmRefs:s.vmRefs-1}},
    all {s.bug==12,s.fault,s'={...s,fault:false,roots:Set()}},
    all {s.bug==13,s.resultFailed,s.p5==4,s'=setpc(s,5,5)},
    all {s.bug==14,top==3,s.p3==3,not(s.entered.contains(4)),s'={...s,stack:[1,2,3,5]}},
    all {s.bug==15,top>0,s.anchor,s'={...s,anchor:false,vmRefs:s.vmRefs-1}},
    all {s.bug==16,s.returnMoved,top==4,s'={...s,loans:s.loans.exclude(Set(6))}},
    all {s.bug==17,s.returnOwner==4,top==4,s'={...s,stack:[1,2,3],pins:s.pins.exclude(Set(4)),roots:s.roots.exclude(Set(4)),markers:s.markers.exclude(Set(4)),vmRefs:s.vmRefs-1}}
  }
  action step=any {all {not(s.fault),protocolStep},mutant}
  val safe=all {not(s.bad),s.calls<=1,s.stack==[1,2,3,4,5].slice(0,s.stack.length()),
    live.subseteq(s.roots),live.subseteq(s.pins),live.intersect(CF).subseteq(s.records),
    s.using.subseteq(s.loans),s.loans.exclude(Set(6)).subseteq(live.intersect(CF)),
    not(s.loans.contains(6)) or (live.contains(s.returnOwner) and s.records.contains(6) and (not(s.returnMoved) or s.returnOwner==3)),
    CF.forall(i=>pc(s,i)<5 or not(s.loans.contains(i))),
    live.intersect(SF).forall(i=>pc(s,i)>=5 or s.markers.contains(i)),
    s.vmRefs==s.pins.size()+(if(s.anchor) 1 else 0)+(if(s.resourcePin) 1 else 0),
    top==0 or s.anchor,s.op<2 or s.loans.size()==0,
    not(s.freed) or s.loans.size()==0,not(s.metaFree) or (not(s.metaBase) and s.records.size()==0),
    not(s.vmFree) or (s.closed and s.vmRefs==0),top==0 or s.rootVersion==s.gc}
}
