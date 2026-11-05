module structure_poll_still_envelope {
  // One bounded design history. Example a255,r254; frame strides8/7.
  // Unit100 denotes an abstract backing section (not native bytes); still21,
  // auxiliary2 and effect cap4 are deliberately abstract, not native estimates.
  type State={phase:int,sections:int,pool:bool,grant:bool,known:bool,
    epoch:int,proof:int,root:bool,forwarded:bool,pin:bool,quarantine:bool,
    frames:int,charge:int,allocated:bool,initialized:bool,nativeRef:bool,
    resultRoot:bool,collector:bool,unknown:bool,captured:bool,
    effects:int,qualified:bool,peak:int,floor:int}
  var s:State
  // Unknown service result may already own a block: charge its full held bound.
  // This is a custody upper envelope, not an observation of physical allocation.
  pure def occ(t:State):int=100*t.sections+(if(t.allocated or t.unknown)21 else 0)+2+t.effects
  pure def seen(t:State):State={...t,peak:if(t.peak>occ(t))t.peak else occ(t),
    floor:if(t.floor>occ(t))t.floor else occ(t)}
  action init=s'={phase:0,sections:2,pool:true,grant:false,known:false,
    epoch:1,proof:1,root:true,forwarded:false,pin:true,quarantine:false,
    frames:0,charge:0,allocated:false,initialized:false,nativeRef:false,
    resultRoot:false,collector:false,unknown:false,captured:false,
    effects:0,qualified:true,peak:202,floor:202}
  val safe=s.sections>=2 and s.sections<=3 and s.frames>=0 and s.frames<=254 and
    s.charge>=0 and s.peak>=occ(s) and s.peak>=s.floor and
    (not(s.grant) or (s.known and s.proof==s.epoch)) and
    (not(s.qualified) or s.effects<=4) and
    (not(s.collector) or not(s.allocated) or s.initialized) and
    (not(s.allocated) or s.root or s.resultRoot) and
    (not(s.unknown) or (not(s.grant) and s.pin)) and
    (not(s.quarantine) or (s.pin and not(s.grant)))
  action reusePool=all{s.phase==0,s.pool,s'={...s,phase:1,pool:false,grant:true,known:true}}
  action acquireFresh=all{s.phase==0,s'=seen({...s,phase:1,sections:3,grant:true,known:true})}
  action boundedInterrupt=all{s.phase==1,s.effects==0,s'=seen({...s,effects:4})}
  action unknownEffect=all{s.phase==1,s'=seen({...s,effects:5,qualified:false})}
  // Batching the254 recursive source steps needs a source refinement proof.
  action grow=all{s.phase==1,s.grant,s'={...s,phase:2,frames:254}}
  action pollGc=all{s.phase==2,s.root,s'={...s,epoch:s.epoch+1,grant:false,forwarded:true,collector:true}}
  action restore=all{s.phase==2,s.forwarded,s'={...s,collector:false,grant:true,known:true,proof:s.epoch}}
  action prepareStill=all{s.phase==2,s.grant,s'={...s,phase:3,charge:261}}
  action allocateStill=all{s.phase==3,not(s.allocated),s'=seen({...s,phase:4,allocated:true,nativeRef:true})}
  action dropNativeRef=all{s.phase==4,s'={...s,phase:5,nativeRef:false}}
  action initialize=all{s.phase==5,s'={...s,phase:6,initialized:true}}
  action returnResult=all{s.phase==6,s.initialized,s'={...s,phase:7,resultRoot:true}}
  action allocFailure=all{s.phase==3,not(s.allocated),s'={...s,phase:8,charge:0}}
  action unknownAllocation=all{s.phase==3,s'=seen({...s,phase:8,unknown:true,grant:false,pin:true})}
  action quarantine=all{s.forwarded,s'={...s,phase:9,quarantine:true,grant:false}}
  action capture=all{s.phase==7,s'={...s,captured:true}}
  action returnStackToPool=all{s.phase==7,s'={...s,pool:true}}
  // Pending-credit settlement into persistent accounting, not VM-space refund.
  action settlePendingCharge=all{s.phase==7,s'={...s,charge:0}}
  action stutter=s'=s
  action step=any{reusePool,acquireFresh,boundedInterrupt,unknownEffect,grow,
    pollGc,restore,prepareStill,allocateStill,dropNativeRef,initialize,returnResult,
    allocFailure,unknownAllocation,quarantine,capture,returnStackToPool,settlePendingCharge,stutter}
  action allocation=prepareStill.then(allocateStill).then(dropNativeRef).then(initialize).then(returnResult)
  action reuseRun=reusePool.then(grow).then(allocation)
  run reuseAndStillTest=init.then(reuseRun).expect(safe and s.peak==223)
  run freshAndStillTest=init.then(acquireFresh).then(grow).then(allocation).expect(safe and s.peak==323)
  run boundedEffectTest=init.then(reusePool).then(boundedInterrupt).then(grow).then(allocation).expect(safe and s.peak==227)
  run unknownEffectRefusesReceiptTest=init.then(reusePool).then(unknownEffect).expect(safe and not(s.qualified))
  run gcRebindTest=init.then(reusePool).then(grow).then(pollGc).then(restore).then(allocation).expect(safe and s.epoch==2)
  run stillFailureRefundTest=init.then(reusePool).then(grow).then(prepareStill).then(allocFailure).expect(safe and not(s.allocated) and s.charge==0)
  run unknownAllocationCustodyTest=init.then(reusePool).then(grow).then(prepareStill).then(unknownAllocation).expect(safe and s.pin and not(s.grant))
  run capturedStackPoolTest=init.then(reuseRun).then(capture).then(returnStackToPool).expect(safe and s.peak==223 and s.captured)
  run settlementNotFreeTest=init.then(reuseRun).then(settlePendingCharge).expect(safe and occ(s)==223)
  run afterForwardFailureTest=init.then(reusePool).then(grow).then(pollGc).then(quarantine).expect(safe and s.pin)
  run staleBindingControlTest=init.then(reusePool).then(grow).then(pollGc).then(s'={...s,grant:true}).expect(not(safe))
  run unboundedEffectClaimControlTest=init.then(reusePool).then(unknownEffect).then(s'={...s,qualified:true}).expect(not(safe))
  run uninitializedGcControlTest=init.then(reusePool).then(grow).then(prepareStill).then(allocateStill).then(s'={...s,collector:true}).expect(not(safe))
  run refcountZeroIsNotInitControlTest=init.then(reusePool).then(grow).then(prepareStill).then(allocateStill).then(dropNativeRef).then(s'={...s,collector:true}).expect(not(safe))
  run unknownReplayControlTest=init.then(reusePool).then(grow).then(prepareStill).then(unknownAllocation).then(s'={...s,grant:true}).expect(not(safe))
  run lostResultRootControlTest=init.then(reuseRun).then(s'={...s,root:false,resultRoot:false}).expect(not(safe))
  run lateRefundPeakControlTest=init.then(acquireFresh).then(grow).then(allocation).then(s'=seen({...s,sections:2})).then(s'={...s,peak:occ(s)}).expect(not(safe))
  run unknownUnpinControlTest=init.then(reusePool).then(grow).then(prepareStill).then(unknownAllocation).then(s'={...s,pin:false}).expect(not(safe))
}
