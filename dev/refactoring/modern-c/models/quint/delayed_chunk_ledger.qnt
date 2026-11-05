module delayed_chunk_ledger {
 // phase 0 strong, 1 classification, 2 weak, 3 weak complete, 4 epoch retired.
 // chunk 0 unused, 1 delayed, 2 sealed, 3 queued, 4 scanning, 5 settled.
 type State={phase:int,chunk:int,debt:int,accepted:int,settled:int,children:int,kind:int,strongDebt:int,strongClosed:bool,da:bool,db:bool,rootsClosed:bool,sealed:bool,headPin:bool,receiptPin:bool,futureClosed:bool}
 pure val initial:State={phase:0,chunk:0,debt:0,accepted:0,settled:0,children:0,kind: -1,strongDebt:1,strongClosed:false,da:false,db:false,rootsClosed:false,sealed:false,headPin:true,receiptPin:false,futureClosed:false}
 var s:State
 action init=s'=initial
 val safe=all{
 s.phase>=0,s.phase<=4,s.chunk>=0,s.chunk<=5,s.strongDebt>=0,s.strongDebt<=1,
 s.debt>=0,s.children>=0,s.settled>=0,s.accepted>=s.settled,s.debt==s.accepted-s.settled,
 s.kind>= -1,s.kind<=4,
 (s.chunk>=1 and s.chunk<=4) implies s.debt==s.children+1,
 (s.chunk==0 or s.chunk==5) implies s.debt==s.children,
 s.chunk>=2 implies s.sealed,
 s.phase>=1 implies (s.strongClosed and s.strongDebt==0),
 (s.da or s.db) implies s.strongClosed,
 s.phase>=2 implies (s.da and s.db),
 s.debt>0 implies s.phase==2,
 s.rootsClosed implies s.phase>=2,
 s.phase>=3 implies (s.rootsClosed and s.debt==0),
 s.phase<=2 implies s.headPin,
 s.futureClosed implies s.phase>=3,
 s.receiptPin implies s.chunk>=1,
 (s.chunk==1 or s.chunk==2) implies s.receiptPin,
 s.phase==4 implies (not(s.headPin) and not(s.receiptPin) and s.futureClosed)}
 action drainStrong=all{s.phase==0,s'={...s,strongDebt:0}}
 action freezeStrong=all{s.phase==0,s.strongDebt==0,s'={...s,phase:1,strongClosed:true}}
 action classifyA=all{s.phase==1,s'={...s,da:true}}
 action classifyB=all{s.phase==1,s'={...s,db:true}}
 action enterWeak=all{s.phase==1,s.da,s.db,s'={...s,phase:2}}
 action acceptDelayed=all{s.phase==2,not(s.rootsClosed),s.chunk==0,s.debt==0,s'={...s,chunk:1,debt:s.debt+1,accepted:s.accepted+1,receiptPin:true,kind:4}}
 action sealDelayed=all{s.phase==2,s.chunk==1,s'={...s,chunk:2,sealed:true}}
 action publishAccepted=all{s.phase==2,s.chunk==2,s.sealed,s'={...s,chunk:3}}
 action observeReceipt=all{s.chunk>=3,s.receiptPin,s'={...s,receiptPin:false}}
 action claim=all{s.phase==2,s.chunk==3,s'={...s,chunk:4}}
 action deriveChild=all{s.phase==2,s.chunk==4,s'={...s,children:s.children+1,debt:s.debt+1,accepted:s.accepted+1}}
 action settleParent=all{s.phase==2,s.chunk==4,s'={...s,chunk:5,debt:s.debt-1,settled:s.settled+1}}
 action settleChild=all{s.phase==2,s.children>0,s'={...s,children:s.children-1,debt:s.debt-1,settled:s.settled+1}}
 action closeRoots=all{s.phase==2,s'={...s,rootsClosed:true}}
 action finishWeak=all{s.phase==2,s.rootsClosed,s.debt==0,s'={...s,phase:3}}
 action closeFutureUsers=all{s.phase==3,s'={...s,futureClosed:true}}
 action releaseHead=all{s.phase==3,s.futureClosed,s'={...s,headPin:false}}
 action retireEpoch=all{s.phase==3,s.futureClosed,not(s.headPin),not(s.receiptPin),s'={...s,phase:4}}
 action step=any{drainStrong,freezeStrong,classifyA,classifyB,enterWeak,acceptDelayed,sealDelayed,publishAccepted,observeReceipt,claim,deriveChild,settleParent,settleChild,closeRoots,finishWeak,closeFutureUsers,releaseHead,retireEpoch,all{s'=s}}
 action cut=drainStrong.then(freezeStrong).then(classifyA).then(classifyB).then(enterWeak)
 action scanChunk=acceptDelayed.then(sealDelayed).then(publishAccepted).then(claim)
 run completeTest=init.then(cut).then(scanChunk).then(closeRoots).then(deriveChild).then(settleParent).then(settleChild).then(finishWeak).then(observeReceipt).then(closeFutureUsers).then(releaseHead).then(retireEpoch).then(all{assert(safe and s.phase==4),s'=s})
 run publicationConservesTest=init.then(cut).then(acceptDelayed).then(sealDelayed).then(publishAccepted).then(all{assert(safe and s.debt==1 and s.accepted==1),s'=s})
 run lostAckPinTest=init.then(cut).then(scanChunk).then(closeRoots).then(settleParent).then(finishWeak).then(all{assert(safe and s.receiptPin and s.headPin and s.debt==0),s'=s})
 run delayedBlocksFinishTest=init.then(cut).then(acceptDelayed).then(closeRoots).then(all{assert(safe and s.debt==1 and s.phase==2),s'=s})
 run publicationDoubleCountControlTest=init.then(cut).then(acceptDelayed).then(sealDelayed).then(publishAccepted).then(all{s'={...s,debt:2,accepted:2}}).then(all{assert(not(safe)),s'=s})
 run earlyFinishControlTest=init.then(cut).then(acceptDelayed).then(closeRoots).then(all{s'={...s,phase:3}}).then(all{assert(not(safe)),s'=s})
 run lostPinControlTest=init.then(cut).then(scanChunk).then(settleParent).then(closeRoots).then(finishWeak).then(closeFutureUsers).then(releaseHead).then(all{s'={...s,phase:4}}).then(all{assert(not(safe)),s'=s})
 run missingCutControlTest=init.then(drainStrong).then(freezeStrong).then(classifyA).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
}
