// Concrete adjacency/waiter/lock-order choice. Conditional store-region/GC contract.
module owned_release_algorithm {
  type State={mode:int,bug:int,phase:int,prev:int,next:int,pnext:int,nprev:int,
    mnext:int,mprev:int,head:int,seen:int,waiter:int,m:bool,t:bool,w:bool,p:bool,
    signalled:bool,badSignal:bool,woken:bool,pin:bool,leaves:int,done:bool,early:bool}
  var s:State
  pure def initial(mode:int,bug:int,k:int):State={mode:mode,bug:bug,phase:0,
    prev:if(k<2) 0 else 2,next:if(k==0 or k==2) 0 else 4,
    pnext:1,nprev:1,mnext:if(k==0 or k==2) 0 else 4,mprev:if(k<2) 0 else 2,
    head:if(mode==1) -1 else 3,seen:-1,waiter:-1,m:false,t:false,w:false,p:false,
    signalled:false,badSignal:false,woken:false,pin:true,leaves:0,done:false,early:false}
  action initGood=all{nondet k=Set(0,1,2,3).oneOf() s'=initial(0,0,k)}
  action initNoWait=s'=initial(1,0,0)
  action initRetry=s'=initial(2,0,3)
  action initUnused=s'=initial(3,0,0)
  action initNoNeighbors=s'=initial(0,1,3)
  action initWrongWaiter=s'=initial(0,2,0)
  action initSignalUnlocked=s'=initial(0,3,3)
  action initStaleRetry=s'=initial(2,4,3)
  action initDoubleUnpin=s'=initial(0,5,0)
  action initUnusedLeak=s'=initial(3,6,0)
  action initEarlyUnpin=s'=initial(0,7,0)
  action prepare=all{s.phase==0,s.mode!=3,s'=s.with("phase",1).with("m",true).with("t",true).with("seen",s.head)}
  action dropRetry=all{s.phase==1,s.mode==2,s'=s.with("phase",2).with("m",false).with("t",false).with("head",7)}
  action reacquire=all{s.phase==2,s'=s.with("phase",3).with("m",true).with("t",true).with("seen",if(s.bug==4) s.seen else s.head)}
  action ready=all{s.phase==1,s.mode!=2,s'=s.with("phase",3)}
  action acquireSet=all{s.phase==3,
    s'=s.with("phase",4).with("waiter",if(s.bug==2) s.next else s.seen)
      .with("w",s.seen>=0).with("p",s.seen>=0)
      .with("m",s.bug!=3).with("t",s.bug!=3)}
  action stores=all{s.phase==4,
    s'=s.with("phase",5).with("pnext",if(s.bug==1) s.pnext else s.next)
      .with("nprev",if(s.bug==1) s.nprev else s.prev).with("mnext",1).with("mprev",1).with("pin",s.bug!=7)}
  action signal=all{s.phase==5,
    s'=s.with("phase",6).with("signalled",s.head>=0).with("woken",s.head>=0)
      .with("badSignal",s.head>=0 and (s.waiter!=s.head or not(s.m and s.t and s.w and s.p)))
      .with("pin",s.bug!=7).with("early",s.bug==7)}
  action finish=all{s.phase==6,
    s'=s.with("phase",7).with("m",false).with("t",false).with("w",false).with("p",false)
      .with("pin",false).with("leaves",if(s.bug==5) 2 else 1).with("done",true)}
  action discard=all{s.phase==0,s.mode==3,
    s'=s.with("phase",7).with("done",true).with("pin",s.bug==6).with("leaves",if(s.bug==6) 0 else 1)}
  action stable=all{s.done,s'=s}
  action step=any{prepare,dropRetry,reacquire,ready,acquireSet,stores,signal,finish,discard,stable}
  val safe=not(s.badSignal) and not(s.early) and s.leaves<=1
    and (not(s.done) and s.mode!=3 implies s.pin)
    and (s.done implies (not(s.pin) and s.leaves==1))
    and (s.done and s.mode!=3 implies (s.pnext==s.next and s.nprev==s.prev and s.mnext==1 and s.mprev==1))
    and (s.signalled implies s.waiter==s.head)
}
