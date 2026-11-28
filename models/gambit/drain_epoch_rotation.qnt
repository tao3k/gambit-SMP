module drain_epoch_rotation {
  // Three tagged transitions, two channels and two completion records.
  // Carrier reclamation is deliberately absent; rcHeld is intent, not a root proof.
  type S={mode:int,bug:int,g:int,e:int,phase:int,index:int,p0:int,p1:int,
    drainUsed:bool,a0:int,a1:int,w0:bool,w1:bool,prepared:bool,channelGen:int,
    published:int,seen0:bool,seen1:bool,r0:bool,r1:bool,expect0:int,expect1:int,
    record0:int,record1:int,rcHeld:bool,requested:bool,pendingGc:bool,servicedGc:bool,latched:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,g:0,e:1,phase:0,index:0,p0:0,p1:0,
    drainUsed:false,a0:0,a1:0,w0:false,w1:false,prepared:false,channelGen:0,
    published:0,seen0:true,seen1:true,r0:false,r1:false,expect0:0,expect1:0,
    record0:0,record1:0,rcHeld:true,requested:false,pendingGc:false,servicedGc:false,latched:false}
  action initSuccess=s'=initial(0,0)
  action initAbortRetry=s'=initial(1,0)
  action initHeldResult=s'=initial(2,0)
  action initLateEntry=s'=initial(0,1)
  action initStaleBits=s'=initial(0,2)
  action initResetWriter=s'=initial(0,3)
  action initReuseResult=s'=initial(0,4)
  action initResetPinned=s'=initial(0,5)
  action initOpenEarly=s'=initial(0,6)
  action initAbortDropRc=s'=initial(1,7)
  action initFreeAtSeen=s'=initial(0,8)
  action initParityAck=s'=initial(0,9)
  action initCloseAll=s'=initial(0,10)
  action initNoReopen=s'=initial(0,11)
  action start=all {s.phase==0,s.g<3,not(s.pendingGc),
    s.bug==4 or (if((s.g+1)%2==0) not(s.r0) else not(s.r1)),
    s'={...s,g:s.g+1,phase:1,p0:1,p1:0,drainUsed:false,
      a0:if(s.bug==2) s.a0 else 0,a1:if(s.bug==2) s.a1 else 0,
      prepared:false,seen0:false,seen1:false}}
  // Already counted ordinary call returns even while ordinary admission closes.
  action finish0=all {s.phase==1,s.p0==1,s.bug!=10,s'={...s,p0:0}}
  action admitDrain=all {s.phase==1,not(s.drainUsed),s.a1!=s.g,s.bug!=10,
    s'={...s,p1:1,drainUsed:true}}
  action finish1=all {s.phase==1,s.p1==1,s'={...s,p1:0}}
  // Publication pin outlives the release ACK store; zero scan must wait for it.
  action ack0=all {s.phase==1,s.p0==0,s.a0!=s.g,s'={...s,a0:s.g,w0:true}}
  action ack1=all {s.phase==1,s.p1==0,s.a1!=s.g,s'={...s,a1:s.g,w1:true}}
  action writer0End=all {s.w0,s'={...s,w0:false}}
  action writer1End=all {s.w1,s'={...s,w1:false}}
  action seal=all {s.phase==1,
    if(s.bug==2) s.a0>0 and s.a1>0 else
      if(s.bug==9) s.a0%2==s.g%2 and s.a1%2==s.g%2 else s.a0==s.g and s.a1==s.g,
    s'={...s,phase:2}}
  action zeroCheck=all {s.phase==2,s.p0==0,s.p1==0,
    s.bug==3 or (not(s.w0) and not(s.w1)),s'={...s,phase:3}}
  action prepareChannel=all {s.phase==3,s'={...s,phase:4,prepared:true,channelGen:s.g}}
  action publish=all {s.phase==4,s.prepared,s'={...s,phase:5,published:s.g,
    e:if(s.mode==1 and s.g==1) s.e else s.e+1,
    index:if(s.mode==1 and s.g==1) s.index else 1-s.index,
    record0:if(s.g%2==0) s.g else s.record0,record1:if(s.g%2==1) s.g else s.record1,
    r0:if(s.g%2==0) true else s.r0,r1:if(s.g%2==1) true else s.r1,
    expect0:if(s.g%2==0 and not(s.r0)) s.g else s.expect0,
    expect1:if(s.g%2==1 and not(s.r1)) s.g else s.expect1}}
  action observe0=all {s.phase==5,not(s.seen0),s'={...s,seen0:true}}
  action observe1=all {s.phase==5,not(s.seen1),s'={...s,seen1:true}}
  action reopen=all {s.phase==5,s.seen0,s.seen1,s.bug!=11,s'={...s,phase:0}}
  // Completion-reader tails may remain after GO was observed and OPEN resumed.
  action result0End=all {s.r0,(s.g%2!=0 or (s.seen0 and s.seen1)),s'={...s,r0:false}}
  action result1End=all {s.r1,s.mode!=2,(s.g%2!=1 or (s.seen0 and s.seen1)),s'={...s,r1:false}}
  action requestGc=all {not(s.requested),s'={...s,requested:true,pendingGc:true,latched:s.phase!=0}}
  action serviceGc=all {s.phase==0,s.pendingGc,s'={...s,pendingGc:false,servicedGc:true}}
  action mutant=any {
    all {s.bug==1,s.phase==3,s'={...s,p0:1}},
    all {s.bug==5,s.phase==1,s.p0==1,s'={...s,prepared:true}},
    all {s.bug==6,s.phase==3,s'={...s,phase:0}},
    all {s.bug==7,s.mode==1,s.g==1,s.phase==5,s'={...s,rcHeld:false}},
    all {s.bug==8,s.phase==5,s.seen0,s.seen1,s.g%2==1,s.r1,s'={...s,record1:0}},
    // Old ACK1 delayed across generation3 has equal parity but a different key.
    all {s.bug==9,s.g==3,s.phase==1,s'={...s,a0:1,a1:1}}
  }
  action idle=s'=s
  action step=any {start,finish0,admitDrain,finish1,ack0,ack1,writer0End,writer1End,
    seal,zeroCheck,prepareChannel,publish,observe0,observe1,reopen,result0End,result1End,
    requestGc,serviceGc,mutant,idle}
  val safe=all {s.rcHeld,
    s.phase<2 or (s.a0==s.g and s.a1==s.g),
    s.phase<3 or (s.p0==0 and s.p1==0 and not(s.w0) and not(s.w1)),
    not(s.prepared) or (s.p0==0 and s.p1==0 and not(s.w0) and not(s.w1)),
    s.phase!=0 or s.g==0 or (s.published==s.g and s.seen0 and s.seen1),
    not(s.r0) or s.record0==s.expect0,not(s.r1) or s.record1==s.expect1}
  val goal=if(s.mode==2) s.g==2 and s.phase==0 else s.g==3 and s.phase==0
  temporal fairness=all {weakFair(start,Set(s)),weakFair(finish0,Set(s)),weakFair(admitDrain,Set(s)),
    weakFair(finish1,Set(s)),weakFair(ack0,Set(s)),weakFair(ack1,Set(s)),weakFair(writer0End,Set(s)),
    weakFair(writer1End,Set(s)),weakFair(seal,Set(s)),weakFair(zeroCheck,Set(s)),
    weakFair(prepareChannel,Set(s)),weakFair(publish,Set(s)),weakFair(observe0,Set(s)),
    weakFair(observe1,Set(s)),weakFair(reopen,Set(s)),weakFair(result0End,Set(s)),
    weakFair(result1End,Set(s)),weakFair(requestGc,Set(s)),weakFair(serviceGc,Set(s))}
  temporal progress=fairness.implies(all {eventually(goal),always(s.requested.implies(eventually(s.servicedGc)))})
}
