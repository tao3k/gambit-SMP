module rc_storage_lifecycle {
 // Allocation extents abstract bytes 0..9, header 8, bound 16; not a native layout.
 type State={phase:int,generation:int,operation:int,bytes:int,checked:int,owned:int,index:int,root:int,sourceHold:int,known:int,owner:int,contextClosing:int,contextGone:int,base:int,extra:int,extraSeen:int,borrow:int,scan:int,native:int,grace:int,effects:int,savedGeneration:int,keyGeneration:int,committed:int,oldResult:int,oldKnown:int,frees:int,rejections:int}
 pure val initial:State={phase:0,generation:1,operation:0,bytes:8,checked:0,owned:0,index:0,root:0,sourceHold:0,known:0,owner:0,contextClosing:0,contextGone:0,base:0,extra:0,extraSeen:0,borrow:0,scan:0,native:0,grace:0,effects:0,savedGeneration:0,keyGeneration:0,committed:0,oldResult:0,oldKnown:0,frees:0,rejections:0}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,
s.phase<=10,
s.generation>=1,
s.generation<=2,
s.operation>=0,
s.operation<=2,
s.bytes>=0,
s.bytes<=9,
s.index>=0,
s.index<=4,
s.owned>=0,
s.owned<=2,
s.owner>=0,
s.owner<=2,
s.savedGeneration>=0,
s.savedGeneration<=s.generation,
s.keyGeneration>=0,
s.keyGeneration<=s.generation,
s.oldResult>=0,
s.oldResult<=2,
s.frees>=0,
s.frees<=2,
s.rejections>=0,
s.checked>=0,
s.checked<=1,
s.root>=0,
s.root<=1,
s.sourceHold>=0,
s.sourceHold<=1,
s.known>=0,
s.known<=1,
s.contextClosing>=0,
s.contextClosing<=1,
s.contextGone>=0,
s.contextGone<=1,
s.base>=0,
s.base<=1,
s.extra>=0,
s.extra<=1,
s.extraSeen>=0,
s.extraSeen<=1,
s.borrow>=0,
s.borrow<=1,
s.scan>=0,
s.scan<=1,
s.native>=0,
s.native<=1,
s.grace>=0,
s.grace<=1,
s.effects>=0,
s.effects<=1,
s.committed>=0,
s.committed<=1,
s.oldKnown>=0,
s.oldKnown<=1,
s.phase>0 implies s.operation==s.generation,
s.checked==1 implies s.bytes<=8,
(s.phase>=2 and s.phase<=7) implies (s.owned==1 and s.keyGeneration==s.generation),
s.owned==1 implies (s.phase>=2 and s.phase<=7),
s.owned==2 implies s.phase==9,
s.phase==9 implies (s.owned==2 and s.owner==2),
(s.phase==0 or s.phase==1 or s.phase==8 or s.phase==10) implies s.owned==0,
(s.phase==1 or s.phase==2) implies s.sourceHold==1,
s.phase==3 implies (s.sourceHold==1 and s.index==1),
s.phase==4 implies (s.root==1 and s.index==2 and s.committed==1),
s.phase==5 implies (s.root==1 and s.index==3 and s.committed==1),
(s.phase>=6 and s.phase<=9) implies (s.root==0 and s.sourceHold==0 and s.index==4 and s.base==0 and s.extra==0 and s.known==1),
((s.phase==4 or s.phase==5) and s.known==0) implies s.sourceHold==1,
s.sourceHold==1 implies s.owner>=1,
s.root==1 implies (s.phase>=3 and s.phase<=5),
(s.borrow==1 or s.native==1) implies (s.phase==4 or s.phase==5),
s.scan==1 implies (s.root==1 and s.phase>=3 and s.phase<=5),
s.extra==1 implies ((s.phase==4 or s.phase==5) and s.extraSeen==0),
s.extraSeen==1 implies s.extra==0,
s.contextGone==1 implies (s.contextClosing==1 and ((s.owned==0 and s.sourceHold==0) or s.owner==2)),
s.phase==10 implies (s.root==0 and s.sourceHold==0 and s.base==0),
s.oldKnown==1 implies s.oldResult>0}
 action begin=all{(s.phase==0),(s.contextClosing==0),s'={...s,phase:1,operation:1,bytes:8,sourceHold:1,owner:1}}
 action beginZero=all{(s.phase==0),(s.contextClosing==0),s'={...s,phase:1,operation:1,bytes:0,sourceHold:1,owner:1}}
 action beginTooLarge=all{(s.phase==0),(s.contextClosing==0),s'={...s,phase:1,operation:1,bytes:9,sourceHold:1,owner:1}}
 action ticketFailure=all{(s.phase==0),s'={...s,phase:10,operation:1,known:1}}
 action checkSize=all{(s.phase==1),(s.bytes<=8),s'={...s,checked:1}}
 action rejectSize=all{(s.phase==1),(s.bytes>8),s'={...s,phase:10,sourceHold:0,known:1}}
 action allocNull=all{(s.phase==1),(s.checked==1),s'={...s,phase:10,sourceHold:0,known:1}}
 action allocSuccess=all{(s.phase==1),(s.checked==1),s'={...s,phase:2,owned:1,base:1,keyGeneration:s.generation}}
 action saveKey=all{(s.owned==1),(s.savedGeneration==0),s'={...s,savedGeneration:s.keyGeneration}}
 action reserveIndex=all{(s.phase==2),(s.contextClosing==0),s'={...s,phase:3,index:1}}
 action prepareRoot=all{(s.phase==3),s'={...s,root:1}}
 action publish=all{(s.phase==3),(s.root==1),s'={...s,phase:4,index:2,committed:1}}
 action queryCommit=all{((s.phase==4 or s.phase==5)),s'={...s,known:1}}
 action releaseSource=all{((s.phase==4 or s.phase==5)),(s.known==1),(s.root==1),s'={...s,sourceHold:0}}
 action retainExtra=all{(s.phase==4),(s.extra==0),(s.extraSeen==0),s'={...s,extra:1}}
 action releaseExtra=all{((s.phase==4 or s.phase==5)),(s.extra==1),(s.known==1),s'={...s,extra:0,extraSeen:1}}
 action releaseBase=all{((s.phase==4 or s.phase==5)),(s.base==1),(s.known==1),s'={...s,base:0,phase:5,index:3}}
 action borrow=all{(s.phase==4),(s.borrow==0),s'={...s,borrow:1}}
 action returnBorrow=all{(s.borrow==1),s'={...s,borrow:0}}
 action nativePin=all{(s.phase==4),(s.native==0),s'={...s,native:1}}
 action nativeReturn=all{(s.native==1),s'={...s,native:0}}
 action scan=all{(s.phase>=3),(s.phase<=5),(s.root==1),(s.scan==0),s'={...s,scan:1}}
 action finishScan=all{(s.scan==1),s'={...s,scan:0}}
 action closeEntry=all{(s.phase==4),s'={...s,phase:5,index:3}}
 action requestCleanup=all{(s.contextClosing==0),s'={...s,contextClosing:1}}
 action handoffVM=all{(s.contextClosing==1),(s.owner==1),s'={...s,owner:2}}
 action exitContext=all{(s.contextClosing==1),((s.owner==2 or (s.owned==0 and s.sourceHold==0))),s'={...s,contextGone:1}}
 action settleEffects=all{(s.phase>=2),(s.phase<=6),(s.native==0),s'={...s,effects:1}}
 action abortPrivate=all{((s.phase==2 or s.phase==3)),(s.scan==0),(s.effects==1),s'={...s,phase:6,index:4,root:0,sourceHold:0,base:0,known:1}}
 action unpublish=all{(s.phase==5),(s.known==1),(s.base==0),(s.extra==0),(s.borrow==0),(s.scan==0),(s.native==0),(s.effects==1),s'={...s,phase:6,index:4,root:0,sourceHold:0}}
 action scanGrace=all{(s.phase==6),s'={...s,grace:1}}
 action startFree=all{(s.phase==6),(s.grace==1),(s.effects==1),s'={...s,phase:7}}
 action finishFree=all{(s.phase==7),(s.frees<2),s'={...s,phase:8,owned:0,frees:s.frees+1}}
 action loseFreeOutcome=all{(s.phase==7),s'={...s,phase:9,owned:2,owner:2}}
 action reuseAddress=all{(s.phase==8),(s.generation<2),(s.contextClosing==0),s'={...s,phase:1,generation:s.generation+1,operation:s.operation+1,bytes:8,checked:0,index:0,root:0,sourceHold:1,known:0,owner:1,base:0,extra:0,extraSeen:0,grace:0,effects:0,keyGeneration:0,oldResult:s.committed+1,committed:0}}
 action queryOld=all{(s.oldResult>0),s'={...s,oldKnown:1}}
 action rejectOldRelease=all{(s.savedGeneration>0),(s.savedGeneration!=s.generation),s'={...s,rejections:s.rejections+1}}
 action step=any{begin,beginZero,beginTooLarge,ticketFailure,checkSize,rejectSize,allocNull,allocSuccess,saveKey,reserveIndex,prepareRoot,publish,queryCommit,releaseSource,retainExtra,releaseExtra,releaseBase,borrow,returnBorrow,nativePin,nativeReturn,scan,finishScan,closeEntry,requestCleanup,handoffVM,exitContext,settleEffects,abortPrivate,unpublish,scanGrace,startFree,finishFree,loseFreeOutcome,reuseAddress,queryOld,rejectOldRelease,all{s'=s}}
 run allocFailureTest=init.then(begin).then(checkSize).then(allocNull).then(all{assert(safe and (s.phase==10 and s.owned==0 and s.index==0)),s'=s})
 run overflowTest=init.then(beginTooLarge).then(rejectSize).then(all{assert(safe and (s.phase==10 and s.checked==0 and s.owned==0)),s'=s})
 run zeroPayloadTest=init.then(beginZero).then(checkSize).then(allocSuccess).then(reserveIndex).then(prepareRoot).then(publish).then(all{assert(safe and (s.phase==4 and s.bytes==0 and s.owned==1)),s'=s})
 run unknownCleanupTest=init.then(begin).then(checkSize).then(allocSuccess).then(reserveIndex).then(prepareRoot).then(publish).then(requestCleanup).then(handoffVM).then(exitContext).then(all{assert(safe and (s.contextGone==1 and s.owner==2 and s.phase==4 and s.known==0 and s.sourceHold==1)),s'=s})
 run privateAbortTest=init.then(begin).then(checkSize).then(allocSuccess).then(settleEffects).then(abortPrivate).then(scanGrace).then(startFree).then(finishFree).then(all{assert(safe and (s.phase==8 and s.owned==0 and s.index==4)),s'=s})
 run addressReuseTest=init.then(begin).then(checkSize).then(allocSuccess).then(saveKey).then(reserveIndex).then(prepareRoot).then(publish).then(queryCommit).then(releaseBase).then(settleEffects).then(unpublish).then(scanGrace).then(startFree).then(finishFree).then(reuseAddress).then(checkSize).then(allocSuccess).then(rejectOldRelease).then(queryOld).then(all{assert(safe and (s.generation==2 and s.owned==1 and s.savedGeneration==1 and s.oldKnown==1 and s.rejections==1)),s'=s})
 run freeUnknownTest=init.then(begin).then(checkSize).then(allocSuccess).then(settleEffects).then(abortPrivate).then(scanGrace).then(startFree).then(loseFreeOutcome).then(all{assert(safe and (s.phase==9 and s.owned==2 and s.owner==2)),s'=s})
}
