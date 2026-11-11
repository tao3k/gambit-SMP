module storage_index_transactions {
 // Fixed two OperationIds; A=[0,8), B=[4,12) or adjacent [8,16).
 type State={opened:int,generation:int,revision:int,adjacent:int,payload:int,rejections:int,a:int,aSnapshot:int,aSnapshotGeneration:int,aGeneration:int,aLease:int,aBound:int,aRoot:int,aKnown:int,aReaders:int,aScan:int,b:int,bSnapshot:int,bSnapshotGeneration:int,bGeneration:int,bLease:int,bBound:int,bRoot:int,bKnown:int,bReaders:int,bScan:int}
 pure val initial:State={opened:1,generation:1,revision:0,adjacent:0,payload:0,rejections:0,a:0,aSnapshot:-1,aSnapshotGeneration:0,aGeneration:0,aLease:0,aBound:0,aRoot:0,aKnown:0,aReaders:0,aScan:0,b:0,bSnapshot:-1,bSnapshotGeneration:0,bGeneration:0,bLease:0,bBound:0,bRoot:0,bKnown:0,bReaders:0,bScan:0}
 var s:State
 action init=s'=initial
 val safe=all{s.opened>=0,
s.opened<=1,
s.a==4 implies s.aKnown==1,
s.b==4 implies s.bKnown==1,
s.generation>=1,
s.generation<=2,
s.revision>=0,
s.adjacent>=0,
s.adjacent<=1,
s.payload>=0,
s.rejections>=0,
s.a>=0,
s.a<=5,
s.aSnapshot>=-1,
s.aSnapshot<=s.revision,
s.aSnapshotGeneration>=0,
s.aSnapshotGeneration<=s.generation,
s.aGeneration>=0,
s.aGeneration<=s.generation,
s.aLease>=0,
s.aLease<=1,
s.aRoot>=0,
s.aRoot<=1,
s.aKnown>=0,
s.aKnown<=1,
s.aReaders>=0,
s.aReaders<=1,
s.aScan>=0,
s.aScan<=1,
(s.a>=1 and s.a<=4) implies (s.aLease==1 and s.aGeneration==s.generation and s.aBound==s.payload),
s.a==0 implies (s.aLease==0 and s.aRoot==0 and s.aReaders==0 and s.aScan==0),
s.a==5 implies (s.aLease==0 and s.aKnown==1 and s.aReaders==0 and s.aScan==0 and s.aRoot==0),
(s.a==2 or s.a==3) implies s.aRoot==1,
(s.aReaders==1 or s.aScan==1) implies (s.a==2 or s.a==3),
s.aKnown==1 implies s.a>=2,
s.b>=0,
s.b<=5,
s.bSnapshot>=-1,
s.bSnapshot<=s.revision,
s.bSnapshotGeneration>=0,
s.bSnapshotGeneration<=s.generation,
s.bGeneration>=0,
s.bGeneration<=s.generation,
s.bLease>=0,
s.bLease<=1,
s.bRoot>=0,
s.bRoot<=1,
s.bKnown>=0,
s.bKnown<=1,
s.bReaders>=0,
s.bReaders<=1,
s.bScan>=0,
s.bScan<=1,
(s.b>=1 and s.b<=4) implies (s.bLease==1 and s.bGeneration==s.generation and s.bBound==s.payload),
s.b==0 implies (s.bLease==0 and s.bRoot==0 and s.bReaders==0 and s.bScan==0),
s.b==5 implies (s.bLease==0 and s.bKnown==1 and s.bReaders==0 and s.bScan==0 and s.bRoot==0),
(s.b==2 or s.b==3) implies s.bRoot==1,
(s.bReaders==1 or s.bScan==1) implies (s.b==2 or s.b==3),
s.bKnown==1 implies s.b>=2,
(s.a>=1 and s.a<=4 and s.b>=1 and s.b<=4) implies s.adjacent==1}
 action chooseAdjacent=all{(s.revision==0),(s.a==0),(s.b==0),s'={...s,adjacent:1}}
 action observeA=all{(s.a==0),s'={...s,aSnapshot:s.revision,aSnapshotGeneration:s.generation}}
 action reserveA=all{(s.opened==1),(s.a==0),(s.aSnapshot==s.revision),(s.aSnapshotGeneration==s.generation),((s.b==0 or s.b==5 or s.adjacent==1)),s'={...s,a:1,aGeneration:s.generation,aLease:1,aBound:s.payload,revision:s.revision+1}}
 action prepareA=all{(s.a==1),s'={...s,aRoot:1}}
 action publishA=all{(s.a==1),(s.aRoot==1),s'={...s,a:2}}
 action queryA=all{(s.a>=2),(s.a<=5),s'={...s,aKnown:1}}
 action borrowA=all{(s.a==2),(s.aReaders==0),s'={...s,aReaders:1}}
 action returnA=all{(s.aReaders==1),s'={...s,aReaders:0}}
 action scanA=all{(s.a==2),(s.aScan==0),s'={...s,aScan:1}}
 action finishScanA=all{(s.aScan==1),s'={...s,aScan:0}}
 action revokeA=all{(s.a==2),s'={...s,a:3}}
 action drainA=all{(s.a==3),(s.aKnown==1),(s.aReaders==0),(s.aScan==0),s'={...s,a:4}}
 action abortA=all{(s.a==1),s'={...s,a:4,aKnown:1}}
 action settleA=all{(s.a==4),(s.aKnown==1),(s.aGeneration==s.generation),(s.aReaders==0),(s.aScan==0),s'={...s,a:5,aLease:0,aRoot:0,revision:s.revision+1}}
 action rejectOldA=all{(s.aGeneration>0),(s.aGeneration!=s.generation),s'={...s,rejections:s.rejections+1}}
 action observeB=all{(s.b==0),s'={...s,bSnapshot:s.revision,bSnapshotGeneration:s.generation}}
 action reserveB=all{(s.opened==1),(s.b==0),(s.bSnapshot==s.revision),(s.bSnapshotGeneration==s.generation),((s.a==0 or s.a==5 or s.adjacent==1)),s'={...s,b:1,bGeneration:s.generation,bLease:1,bBound:s.payload,revision:s.revision+1}}
 action prepareB=all{(s.b==1),s'={...s,bRoot:1}}
 action publishB=all{(s.b==1),(s.bRoot==1),s'={...s,b:2}}
 action queryB=all{(s.b>=2),(s.b<=5),s'={...s,bKnown:1}}
 action borrowB=all{(s.b==2),(s.bReaders==0),s'={...s,bReaders:1}}
 action returnB=all{(s.bReaders==1),s'={...s,bReaders:0}}
 action scanB=all{(s.b==2),(s.bScan==0),s'={...s,bScan:1}}
 action finishScanB=all{(s.bScan==1),s'={...s,bScan:0}}
 action revokeB=all{(s.b==2),s'={...s,b:3}}
 action drainB=all{(s.b==3),(s.bKnown==1),(s.bReaders==0),(s.bScan==0),s'={...s,b:4}}
 action abortB=all{(s.b==1),s'={...s,b:4,bKnown:1}}
 action settleB=all{(s.b==4),(s.bKnown==1),(s.bGeneration==s.generation),(s.bReaders==0),(s.bScan==0),s'={...s,b:5,bLease:0,bRoot:0,revision:s.revision+1}}
 action rejectOldB=all{(s.bGeneration>0),(s.bGeneration!=s.generation),s'={...s,rejections:s.rejections+1}}
 action sourceWrite=all{(s.opened==1),(s.aLease==0),(s.bLease==0),s'={...s,payload:s.payload+1}}
 action closeIndex=all{(s.opened==1),s'={...s,opened:0}}
 action reuse=all{(s.opened==0),(s.generation<2),((s.a==0 or s.a==5)),((s.b==0 or s.b==5)),(s.aLease==0),(s.bLease==0),s'={...s,generation:s.generation+1,revision:s.revision+1,opened:1}}
 action step=any{chooseAdjacent,observeA,reserveA,prepareA,publishA,queryA,borrowA,returnA,scanA,finishScanA,revokeA,drainA,abortA,settleA,rejectOldA,observeB,reserveB,prepareB,publishB,queryB,borrowB,returnB,scanB,finishScanB,revokeB,drainB,abortB,settleB,rejectOldB,sourceWrite,closeIndex,reuse,all{s'=s}}
 run pendingConflictTest=init.then(observeA).then(observeB).then(reserveA).then(observeB).then(all{assert(s.a==1 and s.b==0 and s.adjacent==0),s'=s})
 run adjacentParallelTest=init.then(chooseAdjacent).then(observeA).then(reserveA).then(observeB).then(reserveB).then(prepareA).then(prepareB).then(publishB).then(publishA).then(all{assert(safe),s'=s})
 run lostReplyTest=init.then(observeA).then(reserveA).then(prepareA).then(publishA).then(revokeA).then(all{assert(s.a==3 and s.aKnown==0 and s.aLease==1),s'=s}).then(queryA).then(drainA).then(settleA).then(closeIndex).then(reuse).then(rejectOldA).then(all{assert(safe),s'=s})
}
