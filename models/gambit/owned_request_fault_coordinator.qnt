// Source refinement experiment: immutable request IDs, thread-owned links,
// fresh processor hints, sticky fault, rooted preparation and native grace.
// The host still must own a live VM borrow; an arbitrary stale C pointer is
// outside the admitted API. This model does not certify the other 12/12 gates.
module owned_request_fault_coordinator {
  type State = { bug:int, r:int -> int, executed:int -> int, replied:int -> int,
    hints:int, parked:bool, migrations:int, owner:int, fault:int, firstFault:int,
    phase:int, claims:int, p0:bool, vmRoot:bool, frameRoot:bool,
    gc:int, payloadEpoch:int, errorRoot:bool, suffix:int, jobs:int,
    writer:bool, selector:bool, marker:bool, nonreturnable:bool,
    terminal:bool, freed:bool, bad:bool }
  var s:State
  pure def initial(b:int):State = {bug:b,r:Map(0->0,1->0),executed:Map(0->0,1->0),
    replied:Map(0->0,1->0),hints:0,parked:false,migrations:0,owner:0,
    fault:0,firstFault:0,phase:0,claims:0,p0:true,vmRoot:true,frameRoot:false,
    gc:0,payloadEpoch:0,errorRoot:false,suffix:2,jobs:0,writer:false,
    selector:false,marker:true,nonreturnable:false,terminal:false,freed:false,bad:false}
  action init = s'=initial(0)
  action initSharedLink = s'=initial(1)
  action initStaleHintRemoval = s'=initial(2)
  action initDuplicateExecute = s'=initial(3)
  action initUnmappedGc = s'=initial(4)
  action initFaultReset = s'=initial(5)
  action initDuplicateCoordinator = s'=initial(6)
  action initMissingSuffix = s'=initial(7)
  action initFreeWithConsumer = s'=initial(8)
  action initPrematureMarker = s'=initial(9)
  action initWrongP = s'=initial(10)
  action initUnrootedError = s'=initial(11)
  action initRawExitSkipsPreparation = s'=initial(12)
  action publish = {
    nondet id=Set(0,1).oneOf()
    all {s.phase==0,s.r.get(id)==0,
      s'={...s,r:s.r.set(id,1),hints:s.hints+1,owner:if(s.bug==1) 2 else 1}}
  }
  action migrate = all {s.phase==0,s.migrations<2,
    s'={...s,migrations:s.migrations+1}}
  action park = all {s.phase==0,not(s.parked),s.hints>0,
    s'={...s,parked:true}}
  // Under T: reject stale hints BEFORE removing any BTQ/TOQ membership.
  action hint = all {s.phase==0,s.hints>0,
    s'={...s,hints:s.hints-1,parked:if(s.bug==2) true else false,
       r:if(s.bug==1) s.r.set(0,0).set(1,0) else s.r,
       bad:s.bug==2 and Set(0,1).forall(id=>s.r.get(id)>=3)}}
  action executeRequest = {
    nondet id=Set(0,1).oneOf()
    all {s.phase==0,not(s.parked),s.r.get(id)==1,
      s'={...s,r:s.r.set(id,2),executed:s.executed.set(id,
        s.executed.get(id)+(if(s.bug==3) 2 else 1)),frameRoot:s.bug!=4}}
  }
  action reply = {
    nondet id=Set(0,1).oneOf()
    nondet failed=Set(false,true).oneOf()
    all {s.phase==0,s.r.get(id)==2,
      s'={...s,r:s.r.set(id,if(failed) 4 else 3),
        replied:s.replied.set(id,s.replied.get(id)+1)}}
  }
  action gcRequest = all {s.phase==0,Set(0,1).exists(id=>s.r.get(id)==2),s.gc<2,
    s'={...s,gc:s.gc+1,payloadEpoch:if(s.frameRoot) s.gc+1 else s.payloadEpoch}}
  action failWake = all {s.phase==0,Set(0,1).exists(id=>s.executed.get(id)>0),
    s'={...s,fault:9,firstFault:9,phase:1,writer:true,selector:true}}
  action repeatFault = all {s.phase==1,s.fault==9,
    s'={...s,fault:if(s.bug==5) 0 else 9,phase:2}}
  action post = all {s.phase==2,
    s'={...s,phase:3,claims:if(s.bug==6) 2 else 1,p0:s.bug!=10}}
  action runCarrier = all {s.phase==3,
    s'={...s,phase:4,frameRoot:true}}
  action job = all {s.phase==4,s.suffix>0,
    s'={...s,suffix:if(s.bug==7) 0 else s.suffix-1,jobs:s.jobs+1,
      errorRoot:s.bug!=11}}
  action gcExit = all {s.phase==4,s.jobs>0,s.gc<3,
    s'={...s,gc:s.gc+1,payloadEpoch:s.gc+1}}
  action prepare = all {s.phase==4,s.suffix==0,
    s'={...s,phase:5,nonreturnable:true}}
  action rawExit = all {s.phase==4,s.bug==12,
    s'={...s,phase:5,nonreturnable:false}}
  action finishWriter = all {s.writer,s'={...s,writer:false}}
  action finishSelector = all {s.selector,s'={...s,selector:false}}
  action finalize = all {s.phase==5,
    s'={...s,phase:6,marker:false,terminal:true,r:Map(0->5,1->5)}}
  action prematureMarker = all {s.phase==4,s.bug==9,s'={...s,marker:false}}
  action free = all {s.phase==6,not(s.writer) and not(s.selector) or s.bug==8,
    s'={...s,phase:7,freed:true,vmRoot:false,frameRoot:false}}
  val safe=all {
    not(s.bad), s.owner<=1,
    Set(0,1).forall(id=>s.executed.get(id)<=1 and s.replied.get(id)<=1),
    Set(0,1).forall(id=>s.r.get(id)!=2) or s.frameRoot,
    s.gc==0 or s.payloadEpoch==s.gc,
    s.firstFault==0 or s.fault==s.firstFault,
    s.claims<=1, s.claims==0 or s.p0,
    s.phase<5 or s.jobs==2,
    s.jobs==0 or s.errorRoot or s.freed,
    s.marker or s.nonreturnable,
    not(s.freed) or (not(s.writer) and not(s.selector) and s.terminal and not(s.marker))}
  action step=any {publish,migrate,park,hint,executeRequest,reply,gcRequest,failWake,
    repeatFault,post,runCarrier,job,gcExit,prepare,rawExit,finishWriter,finishSelector,
    finalize,prematureMarker,free,all{s.phase==7,s'=s}}
  val done=s.freed
  temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
