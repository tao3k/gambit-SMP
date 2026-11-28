module drain_go_admission {
  // Source-specific comparison: result ACKs and drained counters are distinct.
  // A CLOSED ordinary-entry gate is proposed; it is absent from current helper.
  type S={mode:int,bug:int,open:bool,ack0:bool,ack1:bool,
    tail0:bool,tail1:bool,p0:int,p1:int,checked0:bool,checked1:bool,
    enteredLate:bool,go:bool,rcHeld:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,open:true,ack0:false,ack1:false,
    tail0:true,tail1:true,p0:1,p1:1,checked0:false,checked1:false,
    enteredLate:false,go:false,rcHeld:true}
  action initClosedDrain=s'=initial(0,0)
  action initOpenRace=s'=initial(1,0)
  action initDropRc=s'=initial(0,1)
  action initTailWaitsGo=s'=initial(2,0)
  action close=all {s.mode!=1,s.open,s'={...s,open:false}}
  action tail0Done=all {s.tail0,not(s.enteredLate),(s.mode!=2 or s.go),s'={...s,tail0:false,p0:0}}
  action tail1Done=all {s.tail1,(s.mode!=2 or s.go),s'={...s,tail1:false,p1:0}}
  action ack0=all {not(s.tail0),not(s.ack0),s'={...s,ack0:true}}
  action ack1=all {not(s.tail1),not(s.ack1),s'={...s,ack1:true}}
  action readZero0=all {s.ack0,s.ack1,not(s.tail0),not(s.tail1),s.p0==0,
    not(s.checked0),(s.mode==1 or not(s.open)),s'={...s,checked0:true}}
  action readZero1=all {s.checked0,s.p1==0,not(s.checked1),s'={...s,checked1:true}}
  action lateEntry=all {s.open,s.checked0,not(s.enteredLate),not(s.go),
    s'={...s,p0:1,tail0:true,enteredLate:true}}
  action storeGo=all {s.checked0,s.checked1,not(s.go),s'={...s,go:true}}
  action mutant=all {s.bug==1,s.go,s'={...s,rcHeld:false}}
  action idle=s'=s
  action step=any {close,tail0Done,tail1Done,ack0,ack1,readZero0,readZero1,lateEntry,storeGo,mutant,idle}
  val safe=all {not(s.go) or (s.ack0 and s.ack1 and not(s.tail0) and not(s.tail1) and s.p0==0 and s.p1==0),s.rcHeld}
  val goal=s.go
  temporal fairness=all {weakFair(close,Set(s)),weakFair(tail0Done,Set(s)),weakFair(tail1Done,Set(s)),
    weakFair(ack0,Set(s)),weakFair(ack1,Set(s)),weakFair(readZero0,Set(s)),weakFair(readZero1,Set(s)),weakFair(storeGo,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
}
