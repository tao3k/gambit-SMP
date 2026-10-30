// Proposed physical reservation, not an implemented C planner. Two sections
// per new context come from setup_mem_pstate's stack + heap allocations.
module context_startup_capacity {
  type Plan={active:int,target:int,assigned:int,capacity:int,resume:int,
    pending:int,granted:bool,unknown:bool}
  var s:Plan
  pure def required(assigned:int,active:int,target:int,resume:int):int=
    assigned+2*(if(target>active) target-active else 0)+resume
  pure val empty:Plan={active:1,target:1,assigned:2,capacity:2,resume:0,
    pending:0,granted:false,unknown:false}
  action init={s'=empty}
  action request={nondet target=1.to(12).oneOf();nondet density=0.to(4).oneOf();
    nondet resume=Set(0,1).oneOf();all{not(s.granted),
    s'={...s,target:target,assigned:2+density,resume:resume,
       capacity:required(2+density,1,target,resume),pending:target-1,unknown:false}}}
  action grant=all{not(s.granted),not(s.unknown),
    s.capacity>=s.assigned+2*s.pending+s.resume,s'={...s,granted:true}}
  action initializeContext=all{s.granted,s.pending>0,
    s'={...s,assigned:s.assigned+2,active:s.active+1,pending:s.pending-1}}
  action step=any{request,grant,initializeContext,s'=s}
  val safe=all{s.active+s.pending==s.target,s.granted implies all{not(s.unknown),
    s.capacity>=s.assigned+2*s.pending+s.resume},s.pending>=0}
  action check=all{safe,s'=s}
  action requestThree={s'={...empty,target:3,assigned:6,capacity:11,
    resume:1,pending:2}}
  action complete=all{safe,s.pending==0,s.active==3,s'=s}
  run reserveThenInitializeTest=init.then(requestThree).then(grant)
    .then(initializeContext).then(check).then(initializeContext).then(complete)
  action noClamp={s'={...empty,target:12,capacity:2,pending:11,granted:true}}
  // Even always applying max(2*target, live) can omit startup space on top
  // of already assigned dense live regions. These are countermodel values.
  action denseOldFloor={s'={...empty,target:12,assigned:10,capacity:24,pending:11,granted:true}}
  action closedCensusAsTarget={s'={...empty,target:12,capacity:2,pending:11,granted:true}}
  action unknownAsGrant={s'={...empty,granted:true,unknown:true}}
}
