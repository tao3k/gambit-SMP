module source_owner_registry {
 // Stable lookup, candidate roots and collector/storage receipts are trusted source obligations.
 type State={persistent:int,registry:int,owner:int,root:int,writer:int,writerRoot:int,payload:int,writeId:int,seenWrite:int,lastDone:int,round:int,gc:int,manifest:int,storage:int,pin0:int,pin1:int,used0:int,used1:int,view0:int,view1:int,target0:int,target1:int,targetView0:int,targetView1:int,guard0:int,guard1:int,ack0:int,ack1:int,queries:int,rejects:int}
 pure val initial:State={persistent:0,registry:1,owner:0,root:0,writer:0,writerRoot:0,payload:0,writeId:0,seenWrite:0,lastDone:0,round:0,gc:0,manifest:0,storage:0,pin0:0,pin1:0,used0:0,used1:0,view0:0,view1:0,target0:0,target1:0,targetView0:0,targetView1:0,guard0:0,guard1:0,ack0:-1,ack1:-1,queries:0,rejects:0}
 var s:State
 action init=s'=initial
 val safe=all{s.registry>=0,
s.registry<=1,
s.owner>=0,
s.owner<=4,
s.root>=0,
s.root<=1,
s.writer>=0,
s.writer<=2,
s.writerRoot>=0,
s.writerRoot<=1,
s.gc>=0,
s.gc<=1,
s.manifest>=0,
s.manifest<=1,
s.storage>=0,
s.storage<=1,
s.pin0>=0,
s.pin0<=1,
s.pin1>=0,
s.pin1<=1,
s.used0>=0,
s.used0<=1,
s.used1>=0,
s.used1<=1,
s.target0>=0,
s.target0<=1,
s.target1>=0,
s.target1<=1,
s.guard0>=0,
s.guard0<=4,
s.guard1>=0,
s.guard1<=4,
s.payload>=0,
s.writeId>=0,
s.seenWrite>=0,
s.lastDone>=0,
s.round>=0,
s.view0>=0,
s.view1>=0,
s.targetView0>=0,
s.targetView1>=0,
s.queries>=0,
s.rejects>=0,
s.ack0>=-1,
s.ack0<=s.round,
s.pin0==1 implies ((s.owner==2 or s.owner==3) and s.root==1 and s.writer==0 and s.used0==1 and s.view0==s.payload),
s.target0==1 implies (s.used0==1 and s.targetView0<=s.payload),
(s.guard0==1 or s.guard0==2 or s.guard0==3) implies s.target0==1,
(s.guard0==1 or s.guard0==3) implies s.pin0==1,
s.guard0>0 implies s.used0==1,
s.ack1>=-1,
s.ack1<=s.round,
s.pin1==1 implies ((s.owner==2 or s.owner==3) and s.root==1 and s.writer==0 and s.used1==1 and s.view1==s.payload),
s.target1==1 implies (s.used1==1 and s.targetView1<=s.payload),
(s.guard1==1 or s.guard1==2 or s.guard1==3) implies s.target1==1,
(s.guard1==1 or s.guard1==3) implies s.pin1==1,
s.guard1>0 implies s.used1==1,
(s.owner==2 or s.owner==3) implies s.root==1,
s.owner==0 implies (s.root==0 and s.writer==0),
s.owner==4 implies (s.root==0 and s.writer==0 and s.pin0==0 and s.pin1==0),
s.writer>0 implies ((s.owner==2 or s.owner==3) and s.pin0==0 and s.pin1==0 and s.writerRoot==1 and s.writeId>s.lastDone),
s.writer==0 implies s.writerRoot==0,
s.storage==1 implies ((s.owner==3 or s.owner==4) and s.writer==0 and s.pin0==0 and s.pin1==0),
s.manifest==1 implies (s.registry==0 and s.owner>=3),
s.lastDone<=s.writeId,
s.persistent>=0,
s.persistent<=1}
 action reserveOwner=all{(s.owner==0),(s.registry==1),s'={...s,owner:1}}
 action prepareRoot=all{(s.owner==1),(s.gc==0),s'={...s,root:1}}
 action publishOwner=all{(s.owner==1),(s.root==1),(s.registry==1),(s.gc==0),s'={...s,owner:2}}
 action abortPrivate=all{(s.owner==1),(s.gc==0),s'={...s,owner:4,root:0}}
 action closeRegistry=all{(s.registry==1),s'={...s,registry:0}}
 action closeOwner=all{(s.owner==2),s'={...s,owner:3}}
 action sealRoster=all{(s.registry==0),(s.owner==3 or s.owner==4),s'={...s,manifest:1}}
 action rejectLate=all{(s.owner==3 or s.owner==4),s'={...s,rejects:s.rejects+1}}
 action beginWrite=all{(s.owner==2),(s.writer==0),(s.pin0==0),(s.pin1==0),(s.gc==0),(s.storage==0),s'={...s,writer:1,writerRoot:1,writeId:s.writeId+1}}
 action unknownWrite=all{(s.writer==1),s'={...s,writer:2}}
 action presentCurrentWrite=all{(s.writeId>0),s'={...s,seenWrite:s.writeId}}
 action presentOldWrite=all{(s.writeId>0),s'={...s,seenWrite:s.writeId-1}}
 action commitWrite=all{(s.writer==1 or s.writer==2),(s.seenWrite==s.writeId),(s.gc==0),s'={...s,writer:0,writerRoot:0,payload:s.payload+1,lastDone:s.writeId}}
 action abortWrite=all{(s.writer==1 or s.writer==2),(s.seenWrite==s.writeId),(s.gc==0),s'={...s,writer:0,writerRoot:0,lastDone:s.writeId}}
 action queryWrite=all{(s.writeId>0),s'={...s,queries:s.queries+1}}
 action pin0=all{(s.owner==2),(s.writer==0),(s.used0==0),s'={...s,pin0:1,used0:1,view0:s.payload}}
 action enrollTarget0=all{(s.pin0==1),(s.target0==0),(s.gc==0),s'={...s,target0:1,targetView0:s.view0}}
 action ackRound0=all{(s.target0==1),(s.gc==0),s'={...s,ack0:s.round}}
 action reserveGuard0=all{(s.pin0==1),(s.target0==1),(s.guard0==0),(s.ack0==s.round or s.persistent==1),(s.gc==0),s'={...s,guard0:1}}
 action commitGuard0=all{(s.guard0==1),s'={...s,guard0:2}}
 action unknownGuard0=all{(s.guard0==1),s'={...s,guard0:3}}
 action resolveGuard0=all{(s.guard0==3),s'={...s,guard0:2}}
 action returnPin0=all{(s.pin0==1),(s.guard0==2),(s.target0==1),(s.ack0==s.round or s.persistent==1),(s.gc==0),s'={...s,pin0:0}}
 action finishGuard0=all{(s.guard0==2),(s.pin0==0),s'={...s,guard0:4}}
 action retireTarget0=all{(s.guard0==4),(s.gc==0),s'={...s,target0:0}}
 action pin1=all{(s.owner==2),(s.writer==0),(s.used1==0),(s.guard0==2),s'={...s,pin1:1,used1:1,view1:s.payload}}
 action enrollTarget1=all{(s.pin1==1),(s.target1==0),(s.gc==0),s'={...s,target1:1,targetView1:s.view1}}
 action ackRound1=all{(s.target1==1),(s.gc==0),s'={...s,ack1:s.round}}
 action reserveGuard1=all{(s.pin1==1),(s.target1==1),(s.guard1==0),(s.ack1==s.round or s.persistent==1),(s.gc==0),s'={...s,guard1:1}}
 action commitGuard1=all{(s.guard1==1),s'={...s,guard1:2}}
 action unknownGuard1=all{(s.guard1==1),s'={...s,guard1:3}}
 action resolveGuard1=all{(s.guard1==3),s'={...s,guard1:2}}
 action returnPin1=all{(s.pin1==1),(s.guard1==2),(s.target1==1),(s.ack1==s.round or s.persistent==1),(s.gc==0),s'={...s,pin1:0}}
 action finishGuard1=all{(s.guard1==2),(s.pin1==0),s'={...s,guard1:4}}
 action retireTarget1=all{(s.guard1==4),(s.gc==0),s'={...s,target1:0}}
 action qualifyPersistentCoverage=all{(s.owner==2),(s.target0==1),(s.gc==0),s'={...s,persistent:1}}
 action freezeGc=all{(s.gc==0),(s.root==1 or s.writerRoot==1 or s.target0==1 or s.target1==1),s'={...s,gc:1,round:s.round+1}}
 action finishGc=all{(s.gc==1),s'={...s,gc:0}}
 action storageReceipt=all{(s.owner==3),(s.writer==0),(s.pin0==0),(s.pin1==0),(s.gc==0),s'={...s,storage:1}}
 action bulkCleanup=all{(s.owner==3),(s.registry==0),(s.manifest==1),(s.storage==1),(s.writer==0),(s.pin0==0),(s.pin1==0),(s.gc==0),s'={...s,owner:4,root:0}}
 action step=any{reserveOwner,prepareRoot,publishOwner,abortPrivate,closeRegistry,closeOwner,sealRoster,rejectLate,beginWrite,unknownWrite,presentCurrentWrite,presentOldWrite,commitWrite,abortWrite,queryWrite,pin0,enrollTarget0,ackRound0,reserveGuard0,commitGuard0,unknownGuard0,resolveGuard0,returnPin0,finishGuard0,retireTarget0,pin1,enrollTarget1,ackRound1,reserveGuard1,commitGuard1,unknownGuard1,resolveGuard1,returnPin1,finishGuard1,retireTarget1,qualifyPersistentCoverage,freezeGc,finishGc,storageReceipt,bulkCleanup,all{s'=s}}
 run registrationTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(all{assert(s.owner==2 and s.root==1 and safe),s'=s})
 run closePrivateTest=init.then(reserveOwner).then(prepareRoot).then(closeRegistry).then(abortPrivate).then(all{assert(s.owner==4 and s.registry==0 and safe),s'=s})
 run writerCloseTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(beginWrite).then(closeOwner).then(unknownWrite).then(queryWrite).then(all{assert(s.owner==3 and s.writer==2 and s.writerRoot==1 and safe),s'=s})
 run writeDrainTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(beginWrite).then(closeOwner).then(unknownWrite).then(presentCurrentWrite).then(commitWrite).then(closeRegistry).then(sealRoster).then(storageReceipt).then(bulkCleanup).then(all{assert(s.owner==4 and s.payload==1 and safe),s'=s})
 run oldWriteReceiptTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(beginWrite).then(presentCurrentWrite).then(commitWrite).then(beginWrite).then(presentOldWrite).then(all{assert(s.writer==1 and s.seenWrite!=s.writeId and s.payload==1 and safe),s'=s})
 run oldRoundTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(commitGuard0).then(freezeGc).then(finishGc).then(all{assert(s.pin0==1 and s.ack0<s.round and safe),s'=s})
 run renewRoundTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(commitGuard0).then(freezeGc).then(finishGc).then(ackRound0).then(returnPin0).then(all{assert(s.pin0==0 and s.ack0==s.round and safe),s'=s})
 run nestedCloseTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(commitGuard0).then(pin1).then(enrollTarget1).then(ackRound1).then(reserveGuard1).then(commitGuard1).then(closeOwner).then(returnPin0).then(all{assert(s.pin1==1 and s.owner==3 and safe),s'=s})
 run unknownGuardTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(unknownGuard0).then(closeOwner).then(freezeGc).then(finishGc).then(all{assert(s.guard0==3 and s.pin0==1 and s.target0==1 and safe),s'=s})
 run newPayloadOldTargetTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(commitGuard0).then(returnPin0).then(beginWrite).then(presentCurrentWrite).then(commitWrite).then(all{assert(s.targetView0==0 and s.payload==1 and s.target0==1 and safe),s'=s})
 run cleanupWithTargetTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(commitGuard0).then(returnPin0).then(closeOwner).then(closeRegistry).then(sealRoster).then(storageReceipt).then(bulkCleanup).then(all{assert(s.owner==4 and s.target0==1 and s.guard0==2 and safe),s'=s})
 run fullDrainTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(commitGuard0).then(pin1).then(enrollTarget1).then(ackRound1).then(reserveGuard1).then(commitGuard1).then(closeOwner).then(returnPin1).then(finishGuard1).then(retireTarget1).then(returnPin0).then(finishGuard0).then(retireTarget0).then(closeRegistry).then(sealRoster).then(storageReceipt).then(bulkCleanup).then(all{assert(s.owner==4 and s.target0==0 and s.target1==0 and safe),s'=s})
 run persistentCoverageTest=init.then(reserveOwner).then(prepareRoot).then(publishOwner).then(pin0).then(enrollTarget0).then(ackRound0).then(reserveGuard0).then(commitGuard0).then(qualifyPersistentCoverage).then(freezeGc).then(finishGc).then(returnPin0).then(all{assert(s.pin0==0 and s.ack0<s.round and s.persistent==1 and safe),s'=s})
}
