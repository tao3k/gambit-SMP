// Projection of the existing callback boundary, not a new delivery protocol.
// Native cleanup succeeds when valid here; BUSY, Retained, concurrent owners,
// C11 order and actual C frame maps remain in their separate obligations.
module delivery_callback_unwind_refinement {
  type State={bug:int,kind:int,phase:int,mode:int,payload:bool,
    calls:int,cap:int,settled:bool,debits:int,gc:bool,version:int,
    mapped:int,reentered:bool,rejected:bool,errorDelivered:bool}
  var s:State
  pure def initial(bug:int,kind:int):State={bug:bug,kind:kind,phase:0,
    mode:if(bug==1) 0 else 1,payload:false,calls:0,cap:1,
    settled:false,debits:0,gc:false,version:0,mapped:0,
    reentered:false,rejected:false,errorDelivered:false}
  action init=any{s'=initial(0,0),s'=initial(0,1),s'=initial(0,2),s'=initial(0,3)}
  action initPrematureNormal=s'=initial(1,2)
  action initMissingAfter=s'=initial(2,2)
  action initReplay=s'=initial(3,0)
  action initMissingMap=s'=initial(4,0)
  action initFalseSentinel=s'=initial(5,3)
  action enter=all{s.phase==0,s'=s.with("phase",1).with("calls",1).with("cap",2)}
  // kind: normal, ordinary error, nonlocal continuation escape. Errors and
  // escapes do not turn the default abandon mode into a normal result.
  action produce=all{s.phase==1,s'=s.with("phase",2)
    .with("payload",s.kind==0).with("mode",if(s.kind==0) 0 else s.mode)}
  action collect=all{(s.phase==1 or s.phase==2),not(s.gc),
    s'=s.with("gc",true).with("version",1).with("mapped",if(s.bug==4) 0 else 1)}
  // An invalid normal-without-outcome is REFUSED, never a fabricated result.
  // A missing after on escape bypasses the outer error catcher altogether.
  action after=all{s.phase==2,
    s'=s.with("phase",3)
      .with("settled",not(s.bug==2) and (s.mode==1 or s.payload))
      .with("debits",if(not(s.bug==2) and (s.mode==1 or s.payload)) 1 else 0)}
  // kind 3 is the legal exception object #f. A bare #f catcher return
  // collides with normal completion even though abandonment already settled.
  action leave=all{s.phase==3,s'=s.with("phase",4)
    .with("errorDelivered",(s.kind==1 or s.kind==3) and not(s.bug==5 and s.kind==3))}
  // The original phase/capability guard runs before the thunk on reentry.
  action reenter=all{s.phase==4,not(s.reentered),
    s'=s.with("reentered",true).with("rejected",s.bug!=3)
      .with("calls",if(s.bug==3) 2 else s.calls)}
  action idle=s'=s
  action step=any{enter,produce,collect,after,leave,reenter,idle}
  val noPrematureNormal=s.phase!=4 or s.settled
  val noMissingAfter=s.phase!=4 or s.settled
  val noReplay=s.calls<=1
  val gcCoverage=not(s.gc) or s.mapped==s.version
  val noSwallowedFalse=s.phase!=4 or s.kind!=3 or s.errorDelivered
  val safe=all{noSwallowedFalse,noPrematureNormal,noMissingAfter,noReplay,gcCoverage,
    s.debits<=1,s.settled implies s.debits==1,
    (s.phase>=2 and s.kind!=0 and s.bug==0) implies s.mode==1,
    (s.mode==0 and s.bug==0) implies s.payload}
  // This assumes the callback returns/raises/escapes, valid native cleanup
  // succeeds, and enabled steps are fairly scheduled. It does not establish
  // those facts, bounded latency, whole-runtime liveness or native admission.
  temporal progress=(weakFair(enter,Set(s)) and weakFair(produce,Set(s)) and
    weakFair(after,Set(s)) and weakFair(leave,Set(s))).implies(eventually(s.phase==4))
}
