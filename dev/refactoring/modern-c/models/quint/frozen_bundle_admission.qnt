module frozen_bundle_admission {
 type State={phase:int,round:int,epoch:int,source:bool,staged:bool,target:bool,future:bool,receipt:bool,unknown:bool,sourceView:bool,targetView:bool,scanBorrow:bool,done:bool,sourceStamp:int,targetStamp:int}
 pure val initial:State={phase:0,round:0,epoch:0,source:true,staged:false,target:false,future:false,receipt:false,unknown:false,sourceView:false,targetView:false,scanBorrow:false,done:false,sourceStamp:0,targetStamp:-1}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,s.phase<=2,s.round>=0,s.round<=2,
 not(s.done) implies (s.source or s.target),
 s.source implies s.sourceStamp==s.epoch,
 s.target implies (s.future and s.targetStamp==s.epoch),
 s.receipt implies (s.target and not(s.unknown)),
 (not(s.source) and not(s.done)) implies (s.target and s.future and s.receipt and not(s.unknown)),
 s.sourceView implies s.source,s.targetView implies s.target,
 s.scanBorrow implies (s.sourceView or s.targetView),s.unknown implies s.source}
 action stage=all{s.source,not(s.target),not(s.done),s'={...s,staged:true}}
 action activate=all{s.phase==0,s.source,s.staged,not(s.target),s'={...s,target:true,future:true,receipt:true,targetStamp:s.sourceStamp}}
 action activateUnknown=all{s.phase==0,s.source,s.staged,not(s.target),s'={...s,target:true,future:true,unknown:true,targetStamp:s.sourceStamp}}
 action queryReceipt=all{s.target,s.unknown,s'={...s,receipt:true,unknown:false}}
 action freeze=all{s.phase==0,s.round<2,not(s.done),s'={...s,phase:1,round:s.round+1,sourceView:s.source,targetView:s.target}}
 action borrowScan=all{s.phase>0,s.sourceView or s.targetView,s'={...s,scanBorrow:true}}
 action returnScan=all{s'={...s,scanBorrow:false}}
 action scan=all{s.phase==1,s'={...s,phase:2,epoch:s.round,sourceStamp:if(s.sourceView) s.round else s.sourceStamp,targetStamp:if(s.targetView) s.round else s.targetStamp}}
 action restore=all{s.phase==2,not(s.scanBorrow),s'={...s,phase:0,sourceView:false,targetView:false}}
 action releaseSource=all{s.phase==0,s.source,s.target,s.future,s.receipt,not(s.unknown),s.targetStamp==s.epoch,s'={...s,source:false}}
 action rejectStaged=all{s.source,not(s.target),s'={...s,staged:false}}
 action finish=all{s.phase==0,not(s.source),s.target,not(s.scanBorrow),s'={...s,target:false,future:false,receipt:false,done:true}}
 action step=any{stage,activate,activateUnknown,queryReceipt,freeze,borrowScan,returnScan,scan,restore,releaseSource,rejectStaged,finish,all{s'=s}}
 run activeBeforeFreezeTest=init.then(stage).then(activate).then(releaseSource).then(freeze).then(scan).then(restore).then(freeze).then(scan).then(restore).then(finish).then(all{assert(safe),s'=s})
 run lateBundleNextRoundTest=init.then(freeze).then(stage).then(scan).then(restore).then(activate).then(releaseSource).then(freeze).then(scan).then(restore).then(finish).then(all{assert(safe),s'=s})
 run lostAckKeepsSourceTest=init.then(stage).then(activateUnknown).then(freeze).then(scan).then(restore).then(all{assert(safe and s.source and s.unknown),s'=s}).then(queryReceipt).then(releaseSource).then(finish).then(all{assert(safe),s'=s})
 run scannerDrainTest=init.then(stage).then(activate).then(freeze).then(borrowScan).then(scan).then(all{assert(safe and s.scanBorrow and s.sourceView),s'=s}).then(returnScan).then(restore).then(releaseSource).then(finish).then(all{assert(safe),s'=s})
 run queuedReceiptControlTest=init.then(freeze).then(stage).then(all{s'={...s,source:false,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run frozenSourceReleaseControlTest=init.then(stage).then(activate).then(freeze).then(all{s'={...s,source:false}}).then(all{assert(not(safe)),s'=s})
 run lostFutureCoverageControlTest=init.then(stage).then(activate).then(releaseSource).then(all{s'={...s,future:false}}).then(all{assert(not(safe)),s'=s})
 run oldScanRetireControlTest=init.then(stage).then(activate).then(freeze).then(borrowScan).then(all{s'={...s,target:false}}).then(all{assert(not(safe)),s'=s})
 run missedTargetUpdateControlTest=init.then(stage).then(activate).then(freeze).then(all{s'={...s,phase:2,epoch:1,sourceStamp:1}}).then(all{assert(not(safe)),s'=s})
}
