// Two-result scheduler wait, materialized before SYNC. Not a native/ABI proof.
module device_relock_sync {
 type State={bug:int,mode:int,phase:int,root:bool,borrow:bool,deviceAlive:bool,
   ready1:bool,ready2:bool,done1:bool,done2:bool,delivered1:bool,delivered2:bool,
   closed1:bool,closeAck1:bool,holder:bool,pending:bool,locks:bool,
   gc:int,version:int,mapped:int,cached:int,epoch:int,token:int,
   oldToken:int,reused:bool,ack:int,bad:bool,finished:bool}
 var s:State
 pure def initial(b:int,m:int):State={bug:b,mode:m,phase:0,root:true,borrow:true,
   deviceAlive:true,ready1:false,ready2:false,done1:false,done2:false,
   delivered1:false,delivered2:false,closed1:false,closeAck1:false,
   holder:true,pending:true,locks:false,gc:0,version:0,mapped:0,cached:0,
   epoch:1,token:1,oldToken:0,reused:false,ack:0,bad:false,finished:false}
 action initGood=s'=initial(0,0)
 action initClosed=s'=initial(0,1)
 action initCurrent=s'=initial(1,0)
 action initSyncHeld=s'=initial(2,0)
 action initLosePrefix=s'=initial(3,0)
 action initMissingMap=s'=initial(4,0)
 action initStalePointer=s'=initial(5,0)
 action initStaleEpoch=s'=initial(6,1)
 action initEarlyFree=s'=initial(7,0)
 action initRetryClear=s'=initial(8,0)
 action initOldCompletion=s'=initial(9,0)
 action initLockLeak=s'=initial(10,0)
 // Capture acquired all native borrows before wait, then dropped P. No C array
 // survives the return below: only the rooted record and readiness bits remain.
 action osReturn=all{s.phase==0,s'=s.with("phase",1).with("ready1",true).with("ready2",true)
   .with("closed1",s.mode==1)}
 action retainClose=all{s.phase==1,s.closed1,s'=s.with("closeAck1",true).with("phase",2)}
 action waitOpen=all{s.phase==1,not(s.closed1),s'=s.with("phase",2)}
 action failTry=all{s.phase==2,s.holder,
   s'=s.with("phase",3).with("locks",s.bug==2)
     .with("ready2",if(s.bug==8) false else s.ready2)}
 // Current blocking reacquire has no SYNC transition. A lock owner at the GC
 // barrier cannot release until this processor participates.
 action sync=all{s.phase==3,s.pending,s.bug!=1,
   s'=s.with("phase",2).with("holder",false).with("pending",false)
     .with("gc",s.gc+1).with("version",s.version+1)
     .with("mapped",if(s.bug==4) s.mapped else s.version+1)
     .with("cached",if(s.bug==5) s.cached else s.version+1)
     .with("bad",s.bad or s.locks)}
 // First result may commit, then a second collective/GC interrupts publication.
 action applyFirst=all{s.phase==2,not(s.holder),not(s.done1),
   s'=s.with("done1",true).with("delivered1",not(s.closed1) or s.bug==6)
     .with("bad",s.bad or (s.closed1 and s.bug==6) or s.cached!=s.version or s.mapped!=s.version)
     .with("holder",true).with("pending",true)
     .with("ready2",if(s.bug==3) false else s.ready2)}
 action applySecond=all{s.phase==2,not(s.holder),s.done1,not(s.done2),s.ready2,
   s'=s.with("done2",true).with("delivered2",true).with("phase",4)
     .with("bad",s.bad or s.cached!=s.version or s.mapped!=s.version)
     .with("locks",s.bug==10)}
 action earlyFree=all{s.phase<=3,s.bug==7,s'=s.with("deviceAlive",false).with("borrow",false)}
 action cleanup=all{s.phase==4,s.done1,s.done2,
   s'=s.with("phase",5).with("borrow",false).with("root",false)
     .with("ack",1).with("oldToken",s.token)}
 action reuse=all{s.phase==5,not(s.reused),
   s'=s.with("reused",true).with("epoch",2).with("token",2).with("phase",6)}
 action lateOld=all{s.phase==6,
   s'=s.with("phase",7).with("finished",true)
     .with("ack",if(s.bug==9) 2 else s.ack)
     .with("bad",s.bad or s.bug==9)}
 action idle=s'=s
 action step=any{osReturn,retainClose,waitOpen,failTry,sync,applyFirst,applySecond,
   earlyFree,cleanup,reuse,lateOld,idle}
 val safe=all{not(s.bad),not(s.locks),s.phase>=5 or (s.root and s.borrow and s.deviceAlive),
   s.phase<2 or s.done2 or s.ready2,
   not(s.delivered1) or not(s.closed1),
   not(s.done1 and s.closed1) or s.closeAck1,
   s.ack<=1,not(s.finished) or (s.done1 and s.done2 and s.delivered2 and s.gc==2)}
 temporal progress=(weakFair(osReturn,Set(s)) and weakFair(retainClose,Set(s)) and
   weakFair(waitOpen,Set(s)) and weakFair(failTry,Set(s)) and weakFair(sync,Set(s)) and
   weakFair(applyFirst,Set(s)) and weakFair(applySecond,Set(s)) and
   weakFair(cleanup,Set(s)) and weakFair(reuse,Set(s)) and weakFair(lateOld,Set(s)))
   .implies(eventually(s.finished))
}
