module ingress_carrier_transfer {
 type State={sourceProtected:bool,sourceReleased:bool,gcCut:bool,targetRegistered:bool,targetVisible:bool,receipt:bool,unknown:bool,failed:bool,done:bool,epoch:int,sourceStamp:int,targetStamp:int,localStamp:int}
 pure val initial:State={sourceProtected:true,sourceReleased:false,gcCut:false,targetRegistered:false,targetVisible:false,receipt:false,unknown:false,failed:false,done:false,epoch:1,sourceStamp:1,targetStamp:0,localStamp:0}
 var s:State
 action init=s'=initial
 val safe=all{s.epoch>=1,s.epoch<=2,
 not(s.done) implies (s.sourceProtected or s.targetVisible),
 s.sourceProtected implies s.sourceStamp==s.epoch,
 s.targetVisible implies (s.targetRegistered and s.targetStamp==s.epoch),
 s.receipt implies s.targetVisible,
 (s.sourceReleased and not(s.done)) implies (s.targetVisible and s.receipt and not(s.unknown)),
 s.unknown implies s.sourceProtected}
 // Reference collector-serialized cut, not a lock held across allocation or callbacks.
 action beginCut=all{not(s.gcCut),not(s.done),not(s.failed),s'={...s,gcCut:true}}
 action readSource=all{s.gcCut,s.sourceProtected,s'={...s,localStamp:s.sourceStamp}}
 action registerTarget=all{s.gcCut,s.sourceProtected,not(s.targetVisible),s.localStamp==s.epoch,s'={...s,targetRegistered:true,targetStamp:s.localStamp}}
 action publishTarget=all{s.gcCut,s.targetRegistered,s.targetStamp==s.epoch,not(s.targetVisible),s'={...s,targetVisible:true,receipt:true}}
 action publishUnknown=all{s.gcCut,s.targetRegistered,s.targetStamp==s.epoch,not(s.targetVisible),s'={...s,targetVisible:true,unknown:true}}
 action queryReceipt=all{s.targetVisible,s.unknown,s'={...s,receipt:true,unknown:false}}
 action releaseSource=all{s.gcCut,s.sourceProtected,s.targetVisible,s.receipt,not(s.unknown),s.targetStamp==s.epoch,s'={...s,sourceProtected:false,sourceReleased:true}}
 action endCut=all{s'={...s,gcCut:false}}
 // Stamps denote validity after GC; they are not physical addresses or registration generations.
 action collect=all{not(s.gcCut),s.epoch<2,s'={...s,epoch:s.epoch+1,sourceStamp:if(s.sourceProtected) s.epoch+1 else s.sourceStamp,targetStamp:if(s.targetVisible) s.epoch+1 else s.targetStamp}}
 action abortPrivate=all{s.gcCut,not(s.targetVisible),s.sourceProtected,s'={...s,gcCut:false,targetRegistered:false,failed:true}}
 action finishTarget=all{not(s.gcCut),s.targetVisible,s.sourceReleased,s'={...s,targetVisible:false,targetRegistered:false,receipt:false,done:true}}
 action step=any{beginCut,readSource,registerTarget,publishTarget,publishUnknown,queryReceipt,releaseSource,endCut,collect,abortPrivate,finishTarget,all{s'=s}}
 action prepare=beginCut.then(readSource).then(registerTarget)
 run moveBeforeReadTest=init.then(collect).then(prepare).then(publishTarget).then(releaseSource).then(endCut).then(finishTarget).then(all{assert(safe and s.done),s'=s})
 run moveAfterPublicationTest=init.then(prepare).then(publishTarget).then(endCut).then(collect).then(beginCut).then(releaseSource).then(endCut).then(finishTarget).then(all{assert(safe),s'=s})
 run lostAckRetainsSourceTest=init.then(prepare).then(publishUnknown).then(endCut).then(collect).then(all{assert(safe and s.sourceProtected and s.unknown),s'=s}).then(queryReceipt).then(beginCut).then(releaseSource).then(endCut).then(finishTarget).then(all{assert(safe),s'=s})
 run privateFailureRetainsSourceTest=init.then(prepare).then(abortPrivate).then(collect).then(all{assert(safe and s.failed and s.sourceProtected and not(s.targetVisible)),s'=s})
 run sourceFirstControlTest=init.then(all{s'={...s,sourceProtected:false,sourceReleased:true}}).then(all{assert(not(safe)),s'=s})
 run staleLocalControlTest=init.then(prepare).then(endCut).then(collect).then(beginCut).then(all{s'={...s,targetVisible:true,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run invisibleTargetControlTest=init.then(all{s'={...s,targetVisible:true,targetStamp:1,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run lostAckReleaseControlTest=init.then(prepare).then(publishUnknown).then(all{s'={...s,sourceProtected:false,sourceReleased:true}}).then(all{assert(not(safe)),s'=s})
}
