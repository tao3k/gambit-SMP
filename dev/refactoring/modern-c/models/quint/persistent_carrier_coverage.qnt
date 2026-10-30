module persistent_carrier_coverage {
 // Two descriptors; per-round registry membership is independent of processor count.
 type State={d0:int,d1:int,mem0:int,mem1:int,initialized1:int,known1:int,sourcePin:int,use1:int,observe1:int,managed:int,rawUnknown:int,backing1:int,payload0:int,payload1:int,round:int,gc:int,snap0:int,snap1:int,read0:int,read1:int,done0:int,done1:int,updated0:int,updated1:int,processors:int,queries:int}
 pure val initial:State={d0:2,d1:0,mem0:1,mem1:0,initialized1:0,known1:0,sourcePin:0,use1:0,observe1:0,managed:0,rawUnknown:0,backing1:0,payload0:0,payload1:0,round:0,gc:0,snap0:0,snap1:0,read0:0,read1:0,done0:0,done1:0,updated0:-1,updated1:-1,processors:2,queries:0}
 var s:State
 action init=s'=initial
 val safe=all{s.d0>=0,
s.d0<=4,
s.d1>=0,
s.d1<=4,
s.mem0>=0,
s.mem0<=1,
s.mem1>=0,
s.mem1<=1,
s.initialized1>=0,
s.initialized1<=1,
s.known1>=0,
s.known1<=1,
s.sourcePin>=0,
s.sourcePin<=1,
s.use1>=0,
s.use1<=1,
s.observe1>=0,
s.observe1<=1,
s.managed>=0,
s.managed<=1,
s.rawUnknown>=0,
s.rawUnknown<=1,
s.backing1>=0,
s.backing1<=1,
s.gc>=0,
s.gc<=1,
s.snap0>=0,
s.snap0<=1,
s.snap1>=0,
s.snap1<=1,
s.read0>=0,
s.read0<=2,
s.read1>=0,
s.read1<=2,
s.done0>=0,
s.done0<=1,
s.done1>=0,
s.done1<=1,
s.payload0>=0,
s.payload1>=0,
s.round>=0,
s.queries>=0,
s.processors==1 or s.processors==2,
s.updated0>=-1,
s.updated1>=-1,
s.updated0<=s.round,
s.updated1<=s.round,
(s.d0==1 or s.d0==2 or s.d0==3) implies s.mem0==1,
s.d0==4 implies s.mem0==0,
(s.gc==1 and (s.d0==2 or s.d0==3)) implies s.snap0==1,
(s.gc==1 and s.snap0==1) implies ((s.d0==2 or s.d0==3) and s.mem0==1),
s.read0>0 implies (s.gc==1 and s.snap0==1 and s.done0==0),
(s.gc==1 and s.snap0==1 and s.done0==1) implies s.updated0==s.round,
(s.d1==1 or s.d1==2 or s.d1==3) implies s.mem1==1,
s.d1==4 implies s.mem1==0,
(s.gc==1 and (s.d1==2 or s.d1==3)) implies s.snap1==1,
(s.gc==1 and s.snap1==1) implies ((s.d1==2 or s.d1==3) and s.mem1==1),
s.read1>0 implies (s.gc==1 and s.snap1==1 and s.done1==0),
(s.gc==1 and s.snap1==1 and s.done1==1) implies s.updated1==s.round,
s.use1==1 implies ((s.d1==2 or s.d1==3) and s.mem1==1),
s.observe1==1 implies ((s.d1==2 or s.d1==3) and s.mem1==1),
s.sourcePin==1 implies (s.mem0==1 and (s.d0==2 or s.d0==3)),
s.d1==0 implies (s.mem1==0 and s.initialized1==0 and s.known1==0 and s.sourcePin==0),
(s.d1==2 or s.d1==3) implies s.initialized1==1,
s.d1==1 implies s.sourcePin==1,
s.known1==1 implies (s.d1==2 or s.d1==3 or s.d1==4),
s.payload1<=s.payload0,
s.gc==0 implies (s.read0==0 and s.read1==0 and s.snap0==0 and s.snap1==0),
s.rawUnknown==1 implies s.managed==0}
 action admitManagedWriters=all{(s.managed==0),(s.rawUnknown==0),(s.d0==2),s'={...s,managed:1}}
 action reserveCarrier=all{(s.d1==0),(s.d0==2),(s.managed==1),(s.rawUnknown==0),(s.gc==0),s'={...s,d1:1,mem1:1,sourcePin:1}}
 action initializeCarrier=all{(s.d1==1),(s.sourcePin==1),(s.gc==0),s'={...s,initialized1:1,payload1:s.payload0}}
 action publishCarrier=all{(s.d1==1),(s.initialized1==1),(s.gc==0),s'={...s,d1:2}}
 action queryPublication=all{(s.d1==2 or s.d1==3),s'={...s,known1:1,queries:s.queries+1}}
 action returnSourcePin=all{(s.sourcePin==1),(s.known1==1),(s.d1==2 or s.d1==3),(s.rawUnknown==0),(s.gc==0),s'={...s,sourcePin:0}}
 action borrowPayload=all{(s.d1==2),(s.known1==1),(s.managed==1),(s.rawUnknown==0),s'={...s,use1:1}}
 action returnPayload=all{(s.use1==1),s'={...s,use1:0}}
 action observeReceipt=all{(s.d1==2),(s.known1==1),(s.rawUnknown==0),s'={...s,observe1:1}}
 action releaseObserver=all{(s.observe1==1),s'={...s,observe1:0}}
 action revokeCarrier=all{(s.d1==2),s'={...s,d1:3}}
 action closeSource=all{(s.d0==2),s'={...s,d0:3}}
 action managedSetter=all{(s.d0==2),(s.managed==1),(s.rawUnknown==0),(s.sourcePin==0),(s.gc==0),s'={...s,payload0:s.payload0+1}}
 action recordRawInterference=all{(s.d0==2 or s.d0==3),s'={...s,rawUnknown:1,managed:0}}
 action storageHandoff=all{(s.d1==2 or s.d1==3),(s.known1==1),(s.gc==0),s'={...s,backing1:1}}
 action cleanupSource=all{(s.d0==3),(s.sourcePin==0),(s.known1==1),(s.d1==2 or s.d1==3),(s.backing1==1),(s.rawUnknown==0),(s.gc==0),s'={...s,d0:4,mem0:0}}
 action retireCarrier=all{(s.d1==3),(s.use1==0),(s.observe1==0),(s.sourcePin==0),(s.known1==1),(s.rawUnknown==0),(s.gc==0),s'={...s,d1:4,mem1:0}}
 action shrinkProcessors=all{(s.processors==2),(s.gc==0),s'={...s,processors:1}}
 action freezeBoth=all{(s.gc==0),(s.d1!=1 or s.initialized1==0),((s.d0==2 or s.d0==3)),((s.d1==2 or s.d1==3)),s'={...s,gc:1,round:s.round+1,snap0:1,snap1:1,done0:0,done1:0}}
 action freezeSource=all{(s.gc==0),(s.d1!=1 or s.initialized1==0),((s.d0==2 or s.d0==3)),((s.d1!=2 and s.d1!=3)),s'={...s,gc:1,round:s.round+1,snap0:1,snap1:0,done0:0,done1:1}}
 action freezeCarrier=all{(s.gc==0),(s.d1!=1 or s.initialized1==0),((s.d0!=2 and s.d0!=3)),((s.d1==2 or s.d1==3)),s'={...s,gc:1,round:s.round+1,snap0:0,snap1:1,done0:1,done1:0}}
 action freezeNeither=all{(s.gc==0),(s.d1!=1 or s.initialized1==0),((s.d0!=2 and s.d0!=3)),((s.d1!=2 and s.d1!=3)),s'={...s,gc:1,round:s.round+1,snap0:0,snap1:0,done0:1,done1:1}}
 action claim0=all{(s.gc==1),(s.snap0==1),(s.done0==0),(s.read0==0),s'={...s,read0:1}}
 action scanDone0=all{(s.gc==1),(s.read0==1),s'={...s,read0:0,done0:1,updated0:s.round}}
 action scanUnknown0=all{(s.gc==1),(s.read0==1),s'={...s,read0:2}}
 action resolveScan0=all{(s.gc==1),(s.read0==2),s'={...s,read0:0,done0:1,updated0:s.round}}
 action claim1=all{(s.gc==1),(s.snap1==1),(s.done1==0),(s.read1==0),s'={...s,read1:1}}
 action scanDone1=all{(s.gc==1),(s.read1==1),s'={...s,read1:0,done1:1,updated1:s.round}}
 action scanUnknown1=all{(s.gc==1),(s.read1==1),s'={...s,read1:2}}
 action resolveScan1=all{(s.gc==1),(s.read1==2),s'={...s,read1:0,done1:1,updated1:s.round}}
 action finishRound=all{(s.gc==1),(s.done0==1),(s.done1==1),(s.read0==0),(s.read1==0),s'={...s,gc:0,snap0:0,snap1:0}}
 action step=any{admitManagedWriters,reserveCarrier,initializeCarrier,publishCarrier,queryPublication,returnSourcePin,borrowPayload,returnPayload,observeReceipt,releaseObserver,revokeCarrier,closeSource,managedSetter,recordRawInterference,storageHandoff,cleanupSource,retireCarrier,shrinkProcessors,freezeBoth,freezeSource,freezeCarrier,freezeNeither,claim0,scanDone0,scanUnknown0,resolveScan0,claim1,scanDone1,scanUnknown1,resolveScan1,finishRound,all{s'=s}}
 run publicationUnknownTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(all{assert(s.known1==0 and s.sourcePin==1 and s.mem1==1 and safe),s'=s})
 run lateQueryTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(revokeCarrier).then(queryPublication).then(returnSourcePin).then(all{assert(s.d1==3 and s.sourcePin==0 and safe),s'=s})
 run repeatedRoundsTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(all{assert(s.updated0==s.round and s.updated1==s.round and s.round==2 and safe),s'=s})
 run independentProcessorTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(shrinkProcessors).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(all{assert(s.processors==1 and s.updated1==s.round and safe),s'=s})
 run oldPayloadTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(borrowPayload).then(managedSetter).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(all{assert(s.payload0==1 and s.payload1==0 and s.use1==1 and safe),s'=s})
 run cleanupOldPayloadTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(borrowPayload).then(managedSetter).then(closeSource).then(storageHandoff).then(cleanupSource).then(freezeCarrier).then(claim1).then(scanDone1).then(finishRound).then(all{assert(s.d0==4 and s.mem1==1 and s.use1==1 and s.updated1==s.round and safe),s'=s})
 run revokeDuringScanTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(freezeBoth).then(claim1).then(revokeCarrier).then(claim0).then(scanDone0).then(scanDone1).then(finishRound).then(all{assert(s.d1==3 and s.mem1==1 and s.updated1==s.round and safe),s'=s})
 run observerPinsDescriptorTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(observeReceipt).then(revokeCarrier).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(all{assert(s.observe1==1 and s.mem1==1 and safe),s'=s})
 run unknownScanTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanUnknown1).then(revokeCarrier).then(all{assert(s.read1==2 and s.gc==1 and s.mem1==1 and safe),s'=s})
 run resolveUnknownScanTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanUnknown1).then(revokeCarrier).then(resolveScan1).then(finishRound).then(all{assert(s.gc==0 and s.d1==3 and s.updated1==s.round and safe),s'=s})
 run rawQuarantineTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(borrowPayload).then(recordRawInterference).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(all{assert(s.managed==0 and s.rawUnknown==1 and s.mem1==1 and safe),s'=s})
 run retireAfterDrainTest=init.then(admitManagedWriters).then(reserveCarrier).then(initializeCarrier).then(publishCarrier).then(queryPublication).then(returnSourcePin).then(observeReceipt).then(borrowPayload).then(revokeCarrier).then(freezeBoth).then(claim0).then(scanDone0).then(claim1).then(scanDone1).then(finishRound).then(returnPayload).then(releaseObserver).then(retireCarrier).then(all{assert(s.d1==4 and s.mem1==0 and safe),s'=s})
}
