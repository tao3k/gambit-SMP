module callback_preparation {
  // Two nested jobs; moving-root versions and partial native teardown masks.
  // Callback entry consumes its token exactly once, including escape/error.
  type S={mode:int,bug:int,j1:int,j2:int,calls1:int,calls2:int,
    root1:bool,root2:bool,v1:int,v2:int,gc:int,carrier:bool,
    reader:int,ack:bool,owner:bool,phase:int,p0:int,vm:int,
    busy:bool,retried:bool,unknown:bool,locked:bool,staleExecuted:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,j1:1,j2:0,calls1:0,calls2:0,
    root1:true,root2:false,v1:0,v2:0,gc:0,carrier:true,reader:0,ack:false,
    owner:true,phase:0,p0:0,vm:0,busy:false,retried:false,
    unknown:false,locked:false,staleExecuted:false}
  action initNormal=s'=initial(0,0)
  action initNestedEscape=s'=initial(1,0)
  action initUnknownRetained=s'=initial(2,0)
  action initPartialRetry=s'=initial(3,0)
  action initRootAfterDetach=s'=initial(0,1)
  action initNestedOverwrite=s'=initial(0,2)
  action initReplayConsumed=s'=initial(2,3)
  action initEscapedContinuation=s'=initial(1,4)
  action initDropOnUnknown=s'=initial(2,5)
  action initGcStaleRoot=s'=initial(0,6)
  action initDropBeforeGrace=s'=initial(0,7)
  action initRepeatP0=s'=initial(3,8)
  action initCallbackInDestroy=s'=initial(0,9)
  action initCallbackUnderLock=s'=initial(0,10)
  action startParent=all {s.phase==0,s.j1==1,s.carrier,s.owner,
    s'={...s,j1:2,calls1:s.calls1+1}}
  action enqueueChild=all {s.j1==2,s.j2==0,
    s'={...s,j2:1,root2:true,v2:s.gc}}
  action startChild=all {s.j1==2,s.j2==1,
    s'={...s,j2:2,calls2:s.calls2+1}}
  action finishChild=all {s.j2==2,
    s'={...s,j2:if(s.mode==1) 5 else if(s.mode==2) 4 else 3,
      unknown:s.mode==2}}
  action finishParent=all {s.j1==2,s.j2>=3,
    s'={...s,j1:3}}
  action readBegin=all {s.reader==0,s.carrier,s.phase<2,
    s'={...s,reader:1}}
  action readEnd=all {s.reader==1,s'={...s,reader:2}}
  action gc=all {s.owner,s.phase<2,s.gc<2,
    s'={...s,gc:s.gc+1,v1:if(s.root1) s.gc+1 else s.v1,
      v2:if(s.root2) s.gc+1 else s.v2}}
  action prepare=all {s.phase==0,s.j1==3,s.j2==3,
    s'={...s,phase:1,ack:true}}
  action releaseCarrier=all {s.phase==1,s.carrier,s.ack,s.reader!=1,
    s'={...s,carrier:false,root1:false,root2:false}}
  action releaseOwner=all {s.phase==1,not(s.carrier),s.owner,
    s'={...s,owner:false}}
  action destroyBegin=all {s.phase==1,not(s.owner),
    s'={...s,phase:2}}
  action destroyP0=all {s.phase==2,s.p0==0,
    s'={...s,p0:1}}
  action busyVm=all {s.phase==2,s.p0==1,s.vm==0,s.mode==3,
    not(s.busy),not(s.retried),s'={...s,busy:true}}
  action retryVm=all {s.busy,s.phase==2,s.p0==1,
    s'={...s,busy:false,retried:true}}
  action destroyVm=all {s.phase==2,s.p0==1,s.vm==0,not(s.busy),
    s.mode!=3 or s.retried,s'={...s,vm:1,phase:3}}
  action mutant=any {
    all {s.bug==1,s.j1==1,s'={...s,root1:false}},
    all {s.bug==2,s.j1==2,s.j2==1,s'={...s,root1:false}},
    all {s.bug==3,s.j2==4,s'={...s,calls2:s.calls2+1}},
    all {s.bug==4,s.j2==5,s'={...s,staleExecuted:true}},
    all {s.bug==5,s.unknown,s'={...s,root2:false,owner:false}},
    all {s.bug==6,s.j1==2,s.gc<2,s'={...s,gc:s.gc+1}},
    all {s.bug==7,s.reader==1,s'={...s,carrier:false}},
    all {s.bug==8,s.phase==2,s.p0==1,s'={...s,p0:2}},
    all {s.bug==9,s.phase==2,s'={...s,j1:2,calls1:s.calls1+1}},
    all {s.bug==10,s.j1==2,s'={...s,locked:true}}
  }
  action step=any {startParent,enqueueChild,startChild,finishChild,finishParent,
    readBegin,readEnd,gc,prepare,releaseCarrier,releaseOwner,destroyBegin,
    destroyP0,busyVm,retryVm,destroyVm,mutant}
  val safe=all {s.calls1<=1,s.calls2<=1,not(s.staleExecuted),
    s.p0<=1,s.vm<=1,
    s.phase!=3 or s.p0==1,
    s.j1!=1 and s.j1!=2 or (s.root1 and s.carrier and s.owner),
    s.j2==0 or s.j2==3 or (s.root2 and s.carrier and s.owner),
    not(s.root1) or s.v1==s.gc,not(s.root2) or s.v2==s.gc,
    s.reader!=1 or s.carrier,
    (s.j1!=2 and s.j2!=2) or (s.phase==0 and not(s.locked)),
    not(s.unknown) or s.owner,
    s.phase<1 or (s.j1==3 and s.j2==3)}
}
