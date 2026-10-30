module dispatch_joint_admission {
// Research abstraction; native issuers and C23 refinement remain open.
type State={nativeOpen:int,storage:int,control:int,root:int,scope:int,others:int,selected:int,phase:int,pending:int,committed:int,known:int,refused:int,unknown:int,borrow:int,created:int,released:int,lease:int,rootAuth:int,nativeAuth:int,finished:int,delivered:int,dataReads:int,gcOpen:int,frozen:int,scanning:int,scanned:int,gcEpoch:int,viewRoot:int}
pure val initial:State={nativeOpen:1,storage:1,control:1,root:1,scope:0,others:0,selected:0,phase:0,pending:0,committed:0,known:0,refused:0,unknown:0,borrow:0,created:0,released:0,lease:0,rootAuth:0,nativeAuth:0,finished:0,delivered:0,dataReads:0,gcOpen:1,frozen:0,scanning:0,scanned:0,gcEpoch:1,viewRoot:0}
var s:State
action init=s'=initial
val safe=all{s.nativeOpen>=0,
s.nativeOpen<=1,
s.storage>=0,
s.storage<=1,
s.control>=0,
s.control<=1,
s.root>=0,
s.root<=1,
s.scope>=0,
s.scope<=1,
s.others>=0,
s.selected>=0,
s.selected<=1,
s.phase>=0,
s.phase<=4,
s.pending>=0,
s.pending<=1,
s.committed>=0,
s.committed<=1,
s.known>=0,
s.known<=1,
s.refused>=0,
s.refused<=1,
s.unknown>=0,
s.unknown<=1,
s.borrow>=0,
s.borrow<=1,
s.created>=0,
s.created<=1,
s.released>=0,
s.released<=1,
s.lease>=0,
s.lease<=1,
s.rootAuth>=0,
s.rootAuth<=1,
s.nativeAuth>=0,
s.nativeAuth<=1,
s.finished>=0,
s.finished<=1,
s.delivered>=0,
s.delivered<=1,
s.dataReads>=0,
s.dataReads<=1,
s.gcOpen>=0,
s.gcOpen<=1,
s.frozen>=0,
s.frozen<=1,
s.scanning>=0,
s.scanning<=1,
s.scanned>=0,
s.scanned<=1,
s.gcEpoch>=0,
s.viewRoot>=0,
s.viewRoot<=1,
s.gcEpoch>=1,
s.borrow+s.released==s.created,
(s.scope==1 or s.others>=1) implies (s.control==1 and s.storage==1 and s.root==1),
(s.nativeOpen==1) implies (s.root==1 and s.storage==1 and s.control==1),
(s.root==1) implies (s.storage==1 and s.control==1),
(s.storage==1) implies (s.control==1),
(s.nativeAuth==1) implies (s.scope==1),
(s.scope==1) implies (s.nativeAuth==1),
(s.pending==1) implies (s.scope==1 and s.known==0 and (s.phase==2 or s.phase==3) and s.root==1),
(s.unknown==1) implies (s.pending==1 and s.known==0),
(s.lease==1) implies (s.phase==2 and s.rootAuth==1 and s.pending==1 and s.frozen==0),
(s.phase==2) implies (s.lease==1 and s.committed==0 and s.borrow==0 and s.refused==0 and s.scope==1),
(s.phase==3) implies (s.committed==1 and s.borrow==1 and s.scope==1 and s.rootAuth==1 and s.lease==0 and s.refused==0),
(s.borrow==1) implies (s.root==1 and s.storage==1 and s.control==1 and s.committed==1 and s.scope==1 and s.rootAuth==1 and s.phase==3),
(s.rootAuth==1) implies (s.root==1 and s.scope==1 and (s.phase==2 or s.phase==3)),
(s.refused==1) implies (s.phase==4 and s.committed==0 and s.known==1 and s.pending==0 and s.borrow==0 and s.dataReads==0),
(s.phase==4) implies (s.known==1 and s.pending==0 and s.borrow==0 and s.rootAuth==0 and s.lease==0),
(s.dataReads==1) implies (s.known==1 and s.committed==1),
(s.released==1) implies (s.phase==4 and s.finished==1 and s.committed==1),
(s.delivered==1) implies (s.phase==4 and s.known==1 and s.pending==0 and s.borrow==0),
(s.frozen==1) implies (s.gcOpen==0 and s.lease==0 and s.root==s.viewRoot),
(s.scanning==1) implies (s.frozen==1 and s.scanned==0),
(s.scanned==1) implies (s.frozen==1 and s.scanning==0),
(s.storage==0) implies (s.root==0 and s.nativeOpen==0 and s.scope==0 and s.others==0 and s.borrow==0 and s.pending==0 and s.lease==0),
(s.control==0) implies (s.storage==0 and s.root==0 and s.nativeOpen==0 and s.scope==0 and s.others==0 and s.pending==0)}
action enterNative=all{s.nativeOpen==1 and s.control==1 and s.scope==0 and s.phase==0,s'={...s,scope:1,nativeAuth:1,phase:1}}
action enterOther=all{s.nativeOpen==1 and s.control==1,s'={...s,others:s.others+1}}
action leaveOther=all{s.others>=1,s'={...s,others:s.others-1}}
action selectHandle=all{s.scope==1 and s.phase==1 and s.nativeOpen==1 and s.storage==1 and s.selected==0,s'={...s,selected:1}}
action deleteCommand=all{s.nativeOpen==1,s'={...s,nativeOpen:0}}
action reserveRoot=all{s.phase==1 and s.scope==1 and s.selected==1 and s.nativeOpen==1 and s.gcOpen==1 and s.frozen==0 and s.root==1 and s.lease==0,s'={...s,phase:2,lease:1,pending:1,rootAuth:1}}
action rejectBeforeReserve=all{s.phase==1 and s.scope==1 and s.selected==1 and (s.nativeOpen==0 or s.gcOpen==0),s'={...s,phase:4,known:1,refused:1}}
action commitJoint=all{s.phase==2 and s.lease==1 and s.rootAuth==1 and s.nativeOpen==1 and s.root==1 and s.storage==1,s'={...s,phase:3,committed:1,borrow:1,created:1,lease:0}}
action rejectReservedDelete=all{s.phase==2 and s.lease==1 and s.nativeOpen==0,s'={...s,phase:4,known:1,refused:1,pending:0,lease:0,rootAuth:0,unknown:0}}
action abortPreparation=all{s.phase==2 and s.lease==1 and s.committed==0,s'={...s,phase:4,known:1,refused:1,pending:0,lease:0,rootAuth:0,unknown:0}}
action loseReply=all{s.pending==1 and s.known==0 and (s.phase==2 or s.phase==3),s'={...s,unknown:1}}
action resolveReservedAbort=all{s.phase==2 and s.unknown==1 and s.lease==1 and s.committed==0,s'={...s,phase:4,known:1,refused:1,pending:0,lease:0,rootAuth:0,unknown:0}}
action ackCommit=all{s.phase==3 and s.committed==1 and s.pending==1 and s.borrow==1,s'={...s,known:1,pending:0,unknown:0}}
action readSelected=all{s.phase==3 and s.known==1 and s.borrow==1 and s.rootAuth==1 and s.gcOpen==1 and s.frozen==0 and s.dataReads==0,s'={...s,dataReads:1}}
action finishUse=all{s.phase==3 and s.known==1 and s.borrow==1,s'={...s,finished:1}}
action retireBorrow=all{s.phase==3 and s.finished==1 and s.known==1 and s.borrow==1,s'={...s,borrow:0,released:1,rootAuth:0,phase:4}}
action deliverOutcome=all{s.phase==4 and s.known==1 and s.pending==0 and s.borrow==0 and s.lease==0,s'={...s,delivered:1}}
action leaveScope=all{s.phase==4 and s.delivered==1 and s.pending==0 and s.borrow==0 and s.lease==0 and s.scope==1,s'={...s,scope:0,nativeAuth:0}}
action leaveEmptyScope=all{s.phase==1 and s.selected==0 and s.pending==0 and s.scope==1,s'={...s,scope:0,nativeAuth:0,phase:0}}
action removeRoot=all{s.nativeOpen==0 and s.scope==0 and s.others==0 and s.borrow==0 and s.lease==0 and s.pending==0 and s.gcOpen==1 and s.frozen==0 and s.root==1,s'={...s,root:0}}
action freeStorage=all{s.nativeOpen==0 and s.root==0 and s.scope==0 and s.others==0 and s.borrow==0 and s.pending==0 and s.lease==0 and s.gcOpen==1 and s.frozen==0 and s.storage==1,s'={...s,storage:0}}
action freeControl=all{s.storage==0 and s.scope==0 and s.others==0 and s.pending==0 and s.nativeAuth==0 and s.gcOpen==1 and s.frozen==0 and s.control==1,s'={...s,control:0}}
action closeGc=all{s.gcOpen==1,s'={...s,gcOpen:0}}
action freezeRoots=all{s.gcOpen==0 and s.lease==0 and s.frozen==0,s'={...s,frozen:1,viewRoot:s.root}}
action beginScan=all{s.frozen==1 and s.scanning==0 and s.scanned==0,s'={...s,scanning:1}}
action endScan=all{s.scanning==1,s'={...s,scanning:0,scanned:1}}
action resumeGc=all{s.frozen==1 and s.scanning==0 and s.scanned==1,s'={...s,frozen:0,gcOpen:1,scanned:0,gcEpoch:s.gcEpoch+1}}
action step=any{enterNative,enterOther,leaveOther,selectHandle,deleteCommand,reserveRoot,rejectBeforeReserve,commitJoint,rejectReservedDelete,abortPreparation,loseReply,resolveReservedAbort,ackCommit,readSelected,finishUse,retireBorrow,deliverOutcome,leaveScope,leaveEmptyScope,removeRoot,freeStorage,freeControl,closeGc,freezeRoots,beginScan,endScan,resumeGc,all{s'=s}}
run ordinaryTest=init.then(enterNative).then(selectHandle).then(reserveRoot).then(commitJoint).then(ackCommit).then(readSelected).then(finishUse).then(retireBorrow).then(deliverOutcome).then(leaveScope).then(deleteCommand).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.control==0),s'=s})
run lateDeleteTest=init.then(enterNative).then(selectHandle).then(deleteCommand).then(rejectBeforeReserve).then(deliverOutcome).then(leaveScope).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.refused==1 and s.dataReads==0),s'=s})
run frozenRefusalTest=init.then(enterNative).then(selectHandle).then(closeGc).then(freezeRoots).then(rejectBeforeReserve).then(deliverOutcome).then(leaveScope).then(beginScan).then(endScan).then(resumeGc).then(deleteCommand).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.refused==1),s'=s})
run reservedDeleteTest=init.then(enterNative).then(selectHandle).then(reserveRoot).then(deleteCommand).then(rejectReservedDelete).then(deliverOutcome).then(leaveScope).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.created==0),s'=s})
run acceptedUnknownTest=init.then(enterNative).then(selectHandle).then(reserveRoot).then(commitJoint).then(loseReply).then(closeGc).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(ackCommit).then(readSelected).then(finishUse).then(retireBorrow).then(deliverOutcome).then(leaveScope).then(deleteCommand).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.released==1),s'=s})
run reservedUnknownTest=init.then(enterNative).then(selectHandle).then(reserveRoot).then(loseReply).then(closeGc).then(resolveReservedAbort).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(deliverOutcome).then(leaveScope).then(deleteCommand).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.refused==1 and s.created==0),s'=s})
run closeAfterReserveTest=init.then(enterNative).then(selectHandle).then(reserveRoot).then(closeGc).then(commitJoint).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(ackCommit).then(finishUse).then(retireBorrow).then(deliverOutcome).then(leaveScope).then(deleteCommand).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.released==1),s'=s})
run othersDelayFreeTest=init.then(enterOther).then(enterNative).then(selectHandle).then(deleteCommand).then(rejectBeforeReserve).then(deliverOutcome).then(leaveScope).then(leaveOther).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.others==0),s'=s})
run deleteAcceptedTest=init.then(enterNative).then(selectHandle).then(reserveRoot).then(commitJoint).then(deleteCommand).then(ackCommit).then(finishUse).then(retireBorrow).then(deliverOutcome).then(leaveScope).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.committed==1 and s.refused==0),s'=s})
run abortPreparationTest=init.then(enterNative).then(selectHandle).then(reserveRoot).then(abortPreparation).then(deliverOutcome).then(leaveScope).then(deleteCommand).then(removeRoot).then(freeStorage).then(freeControl).then(all{assert(safe and s.dataReads==0),s'=s})
}
