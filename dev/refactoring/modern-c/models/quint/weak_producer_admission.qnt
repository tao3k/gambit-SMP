module weak_producer_admission {
 // Six source-route classes; active includes accepted queued/private/child debt.
 type State={phase:int,strongDebt:int,active:int,kind:int,strongClosed:bool,da:bool,db:bool,rootsClosed:bool}
 pure val initial:State={phase:0,strongDebt:1,active:0,kind: -1,strongClosed:false,da:false,db:false,rootsClosed:false}
 var s:State
 action init=s'=initial
 val safe=all{
 s.phase>=0,s.phase<=4,s.strongDebt>=0,s.strongDebt<=1,s.active>=0,s.kind>= -1,s.kind<=5,
 s.phase>=1 implies (s.strongClosed and s.strongDebt==0),
 (s.da or s.db) implies s.strongClosed,
 s.phase>=2 implies (s.da and s.db),
 s.active>0 implies s.phase==2,
 s.phase>=3 implies (s.rootsClosed and s.active==0),
 s.rootsClosed implies s.phase>=2}
 action drainStrong=all{s.phase==0,s'={...s,strongDebt:0}}
 action freezeStrong=all{s.phase==0,s.strongDebt==0,s'={...s,phase:1,strongClosed:true}}
 action classifyA=all{s.phase==1,s'={...s,da:true}}
 action classifyB=all{s.phase==1,s'={...s,db:true}}
 action openWeak=all{s.phase==1,s.da,s.db,s'={...s,phase:2}}
 action listProducer=all{s.phase==2,not(s.rootsClosed),s'={...s,active:s.active+1,kind:0}}
 action repairProducer=all{s.phase==2,not(s.rootsClosed),s'={...s,active:s.active+1,kind:1}}
 action freshWillProducer=all{s.phase==2,not(s.rootsClosed),s'={...s,active:s.active+1,kind:2}}
 action graphProducer=all{s.phase==2,not(s.rootsClosed),s'={...s,active:s.active+1,kind:3}}
 action continuationProducer=all{s.phase==2,not(s.rootsClosed),s'={...s,active:s.active+1,kind:4}}
 action stillProducer=all{s.phase==2,not(s.rootsClosed),s'={...s,active:s.active+1,kind:5}}
 action deriveChild=all{s.phase==2,s.active>0,s'={...s,active:s.active+1}}
 action settleTask=all{s.phase==2,s.active>0,s'={...s,active:s.active-1}}
 action closeRoots=all{s.phase==2,s'={...s,rootsClosed:true}}
 action finishWeak=all{s.phase==2,s.rootsClosed,s.active==0,s'={...s,phase:3}}
 action cleanup=all{s.phase==3,s'={...s,phase:4}}
 action step=any{drainStrong,freezeStrong,classifyA,classifyB,openWeak,listProducer,repairProducer,freshWillProducer,graphProducer,continuationProducer,stillProducer,deriveChild,settleTask,closeRoots,finishWeak,cleanup,all{s'=s}}
 action cut=drainStrong.then(freezeStrong).then(classifyA).then(classifyB).then(openWeak)
 run allRoutesTest=init.then(cut).then(listProducer).then(repairProducer).then(freshWillProducer).then(graphProducer).then(continuationProducer).then(stillProducer).then(closeRoots).then(settleTask).then(settleTask).then(settleTask).then(settleTask).then(settleTask).then(settleTask).then(finishWeak).then(cleanup).then(all{assert(safe and s.phase==4),s'=s})
 run deriveAfterRootCloseTest=init.then(cut).then(continuationProducer).then(closeRoots).then(deriveChild).then(settleTask).then(settleTask).then(finishWeak).then(all{assert(safe),s'=s})
 run lostAckCustodyTest=init.then(cut).then(listProducer).then(all{s'=s}).then(closeRoots).then(all{assert(safe and s.active==1 and s.phase==2),s'=s})
 run missingStrongDrainControlTest=init.then(all{s'={...s,phase:1,strongClosed:true}}).then(all{assert(not(safe)),s'=s})
 run partialClassificationControlTest=init.then(drainStrong).then(freezeStrong).then(classifyA).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
 run earlyProducerControlTest=init.then(drainStrong).then(freezeStrong).then(all{s'={...s,active:1,kind:2}}).then(all{assert(not(safe)),s'=s})
 run lateChildControlTest=init.then(cut).then(closeRoots).then(finishWeak).then(all{s'={...s,active:1}}).then(all{assert(not(safe)),s'=s})
 run lostDebtControlTest=init.then(cut).then(graphProducer).then(closeRoots).then(all{s'={...s,phase:3}}).then(all{assert(not(safe)),s'=s})
}
