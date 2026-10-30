module tcl_source_borrow {
// Research abstraction; native issuers and C23 refinement remain open.
type State={generation:int,tokenGeneration:int,storage:int,closed:int,scope:int,borrower:int,borrowCreated:int,borrowReleased:int,selected:int,current:int,oldRoot:int,newRoot:int,dest:int,destVersion:int,pending:int,acknowledged:int,replyLost:int,writer:int,gcClosed:int,frozen:int,scanning:int,scanned:int,epoch:int,viewOld:int,viewNew:int,viewDest:int,prepared:int,refused:int,otherOld:int,otherNew:int}
pure val initial:State={generation:1,tokenGeneration:1,storage:1,closed:0,scope:0,borrower:0,borrowCreated:0,borrowReleased:0,selected:0,current:1,oldRoot:1,newRoot:0,dest:0,destVersion:0,pending:0,acknowledged:0,replyLost:0,writer:0,gcClosed:0,frozen:0,scanning:0,scanned:0,epoch:1,viewOld:0,viewNew:0,viewDest:0,prepared:0,refused:0,otherOld:0,otherNew:0}
var s:State
action init=s'=initial
val safe=all{s.generation>=0,
s.generation<=2,
s.tokenGeneration>=0,
s.tokenGeneration<=2,
s.storage>=0,
s.storage<=1,
s.closed>=0,
s.closed<=1,
s.scope>=0,
s.scope<=1,
s.borrower>=0,
s.borrower<=1,
s.borrowCreated>=0,
s.borrowCreated<=1,
s.borrowReleased>=0,
s.borrowReleased<=1,
s.selected>=0,
s.selected<=2,
s.current>=0,
s.current<=2,
s.oldRoot>=0,
s.oldRoot<=1,
s.newRoot>=0,
s.newRoot<=1,
s.dest>=0,
s.dest<=1,
s.destVersion>=0,
s.destVersion<=2,
s.pending>=0,
s.pending<=1,
s.acknowledged>=0,
s.acknowledged<=1,
s.replyLost>=0,
s.replyLost<=1,
s.writer>=0,
s.writer<=1,
s.gcClosed>=0,
s.gcClosed<=1,
s.frozen>=0,
s.frozen<=1,
s.scanning>=0,
s.scanning<=1,
s.scanned>=0,
s.scanned<=1,
s.epoch>=0,
s.viewOld>=0,
s.viewOld<=1,
s.viewNew>=0,
s.viewNew<=1,
s.viewDest>=0,
s.viewDest<=1,
s.prepared>=0,
s.prepared<=1,
s.refused>=0,
s.refused<=1,
s.otherOld>=0,
s.otherNew>=0,
s.generation>=1,
s.tokenGeneration>=1,
s.current>=1,
s.epoch>=1,
s.borrower+s.borrowReleased==s.borrowCreated,
(s.borrower==1) implies (s.storage==1 and s.scope==1 and s.selected>=1),
(s.borrower==1 and s.selected==1) implies (s.oldRoot==1),
(s.borrower==1 and s.selected==2) implies (s.newRoot==1),
(s.otherOld>=1) implies (s.storage==1 and s.oldRoot==1),
(s.otherNew>=1) implies (s.storage==1 and s.newRoot==1 and s.current==2),
(s.storage==1 and s.closed==0 and s.current==1) implies (s.oldRoot==1),
(s.storage==1 and s.closed==0 and s.current==2) implies (s.newRoot==1),
(s.prepared==1) implies (s.storage==1 and s.current==1 and s.newRoot==1),
(s.pending==1) implies (s.borrower==1 and s.dest==1 and s.destVersion==s.selected and s.acknowledged==0),
(s.acknowledged==1) implies (s.borrowReleased==1 and s.borrower==0),
(s.scope==1) implies (s.storage==1),
(s.storage==0) implies (s.closed==1 and s.scope==0 and s.borrower==0 and s.otherOld==0 and s.otherNew==0 and s.oldRoot==0 and s.newRoot==0 and s.prepared==0),
(s.writer==1) implies (s.frozen==0 and s.scanning==0),
(s.frozen==1) implies (s.gcClosed==1 and s.writer==0 and s.oldRoot==s.viewOld and s.newRoot==s.viewNew and s.dest==s.viewDest),
(s.scanning==1) implies (s.frozen==1 and s.scanned==0),
(s.scanned==1) implies (s.frozen==1 and s.scanning==0)}
action selectDispatch=all{s.storage==1 and s.closed==0 and s.scope==0 and s.tokenGeneration==s.generation,s'={...s,scope:1}}
action acquireBorrow=all{s.storage==1 and s.closed==0 and s.scope==1 and s.tokenGeneration==s.generation and s.borrowCreated==0 and s.refused==0 and s.writer==0 and s.gcClosed==0 and s.frozen==0,s'={...s,borrower:1,borrowCreated:1,selected:s.current}}
action refuseLateDispatch=all{s.storage==1 and s.scope==1 and s.closed==1 and s.borrower==0,s'={...s,refused:1}}
action refuseGcClosed=all{s.storage==1 and s.scope==1 and s.borrower==0 and s.gcClosed==1,s'={...s,refused:1}}
action otherBorrowOld=all{s.storage==1 and s.closed==0 and s.current==1 and s.gcClosed==0 and s.writer==0 and s.frozen==0,s'={...s,otherOld:s.otherOld+1}}
action otherBorrowNew=all{s.storage==1 and s.closed==0 and s.current==2 and s.gcClosed==0 and s.writer==0 and s.frozen==0,s'={...s,otherNew:s.otherNew+1}}
action releaseOtherOld=all{s.otherOld>=1,s'={...s,otherOld:s.otherOld-1}}
action releaseOtherNew=all{s.otherNew>=1,s'={...s,otherNew:s.otherNew-1}}
action acquireWriter=all{s.writer==0 and s.gcClosed==0 and s.frozen==0,s'={...s,writer:1}}
action prepareSetter=all{s.writer==1 and s.storage==1 and s.closed==0 and s.current==1 and s.prepared==0 and s.newRoot==0,s'={...s,prepared:1,newRoot:1}}
action commitSetter=all{s.writer==1 and s.storage==1 and s.closed==0 and s.current==1 and s.prepared==1,s'={...s,current:2,prepared:0}}
action abortSetter=all{s.writer==1 and s.current==1 and s.prepared==1,s'={...s,prepared:0,newRoot:0}}
action releaseWriter=all{s.writer==1,s'={...s,writer:0}}
action revoke=all{s.storage==1 and s.closed==0,s'={...s,closed:1}}
action publishDestination=all{s.storage==1 and s.borrower==1 and s.writer==1 and s.dest==0 and s.pending==0 and s.acknowledged==0,s'={...s,dest:1,destVersion:s.selected,pending:1}}
action loseReply=all{s.pending==1 and s.borrower==1,s'={...s,replyLost:1}}
action acknowledgeTransfer=all{s.pending==1 and s.dest==1 and s.borrower==1 and s.tokenGeneration==s.generation and s.destVersion==s.selected,s'={...s,pending:0,borrower:0,borrowReleased:1,acknowledged:1,replyLost:0}}
action dropOldVersion=all{s.storage==1 and s.current==2 and s.writer==1 and s.otherOld==0 and (s.borrower==0 or s.selected!=1),s'={...s,oldRoot:0}}
action dropRevokedRoots=all{s.storage==1 and s.closed==1 and s.writer==1 and s.borrower==0 and s.otherOld==0 and s.otherNew==0,s'={...s,oldRoot:0,newRoot:0,prepared:0}}
action leaveDispatch=all{s.scope==1 and s.borrower==0,s'={...s,scope:0}}
action freeSource=all{s.storage==1 and s.closed==1 and s.writer==1 and s.scope==0 and s.borrower==0 and s.otherOld==0 and s.otherNew==0 and s.oldRoot==0 and s.newRoot==0 and s.prepared==0,s'={...s,storage:0}}
action dropDestination=all{s.dest==1 and s.pending==0 and s.borrower==0 and s.acknowledged==1 and s.writer==1,s'={...s,dest:0,destVersion:0}}
action reuseStorage=all{s.storage==0 and s.generation==1 and s.dest==0 and s.writer==0 and s.gcClosed==0 and s.frozen==0,s'={...s,generation:2,storage:1,closed:0,current:1,oldRoot:1,newRoot:0,borrowCreated:0,borrowReleased:0,selected:0,acknowledged:0,refused:0,replyLost:0}}
action selectNewToken=all{s.storage==1 and s.generation==2 and s.scope==0 and s.borrowCreated==0,s'={...s,tokenGeneration:2}}
action closeGcGate=all{s.gcClosed==0,s'={...s,gcClosed:1}}
action freezeRoots=all{s.gcClosed==1 and s.writer==0 and s.frozen==0 and s.scanning==0 and s.scanned==0,s'={...s,frozen:1,viewOld:s.oldRoot,viewNew:s.newRoot,viewDest:s.dest}}
action beginScan=all{s.frozen==1 and s.scanning==0 and s.scanned==0,s'={...s,scanning:1}}
action endScan=all{s.scanning==1,s'={...s,scanning:0,scanned:1}}
action resumeRoots=all{s.frozen==1 and s.scanning==0 and s.scanned==1 and s.writer==0,s'={...s,frozen:0,gcClosed:0,scanned:0,epoch:s.epoch+1}}
action step=any{selectDispatch,acquireBorrow,refuseLateDispatch,refuseGcClosed,otherBorrowOld,otherBorrowNew,releaseOtherOld,releaseOtherNew,acquireWriter,prepareSetter,commitSetter,abortSetter,releaseWriter,revoke,publishDestination,loseReply,acknowledgeTransfer,dropOldVersion,dropRevokedRoots,leaveDispatch,freeSource,dropDestination,reuseStorage,selectNewToken,closeGcGate,freezeRoots,beginScan,endScan,resumeRoots,all{s'=s}}
run basicTransferTest=init.then(selectDispatch).then(acquireBorrow).then(acquireWriter).then(publishDestination).then(releaseWriter).then(acknowledgeTransfer).then(revoke).then(leaveDispatch).then(acquireWriter).then(dropRevokedRoots).then(freeSource).then(releaseWriter).then(all{assert(safe and s.storage==0 and s.dest==1),s'=s})
run setterKeepsOldTest=init.then(selectDispatch).then(acquireBorrow).then(acquireWriter).then(prepareSetter).then(commitSetter).then(releaseWriter).then(closeGcGate).then(freezeRoots).then(beginScan).then(endScan).then(resumeRoots).then(all{assert(safe and s.current==2 and s.selected==1 and s.oldRoot==1 and s.newRoot==1),s'=s})
run deleteDuringBorrowTest=init.then(selectDispatch).then(acquireBorrow).then(revoke).then(acquireWriter).then(publishDestination).then(releaseWriter).then(acknowledgeTransfer).then(leaveDispatch).then(acquireWriter).then(dropRevokedRoots).then(freeSource).then(releaseWriter).then(all{assert(safe and s.storage==0 and s.dest==1),s'=s})
run latePrologueTest=init.then(selectDispatch).then(revoke).then(refuseLateDispatch).then(leaveDispatch).then(acquireWriter).then(dropRevokedRoots).then(freeSource).then(releaseWriter).then(all{assert(safe and s.storage==0 and s.refused==1),s'=s})
run lostAckTest=init.then(selectDispatch).then(acquireBorrow).then(acquireWriter).then(publishDestination).then(releaseWriter).then(loseReply).then(closeGcGate).then(freezeRoots).then(beginScan).then(endScan).then(resumeRoots).then(acknowledgeTransfer).then(all{assert(safe and s.borrower==0 and s.dest==1 and s.borrowReleased==1),s'=s})
run revokePreparedTest=init.then(acquireWriter).then(prepareSetter).then(revoke).then(abortSetter).then(releaseWriter).then(all{assert(safe and s.current==1 and s.newRoot==0 and s.closed==1),s'=s})
run manyBorrowersTest=init.then(otherBorrowOld).then(otherBorrowOld).then(acquireWriter).then(prepareSetter).then(commitSetter).then(releaseWriter).then(closeGcGate).then(freezeRoots).then(beginScan).then(endScan).then(resumeRoots).then(releaseOtherOld).then(releaseOtherOld).then(acquireWriter).then(dropOldVersion).then(releaseWriter).then(all{assert(safe and s.oldRoot==0 and s.current==2),s'=s})
run closeWithWriterTest=init.then(acquireWriter).then(prepareSetter).then(closeGcGate).then(commitSetter).then(releaseWriter).then(freezeRoots).then(beginScan).then(endScan).then(resumeRoots).then(all{assert(safe and s.current==2 and s.newRoot==1),s'=s})
run staleTokenTest=init.then(revoke).then(acquireWriter).then(dropRevokedRoots).then(freeSource).then(releaseWriter).then(reuseStorage).then(all{assert(safe and s.generation==2 and s.tokenGeneration==1),s'=s})
run newTokenTest=init.then(revoke).then(acquireWriter).then(dropRevokedRoots).then(freeSource).then(releaseWriter).then(reuseStorage).then(selectNewToken).then(selectDispatch).then(acquireBorrow).then(all{assert(safe and s.borrower==1 and s.tokenGeneration==2),s'=s})
}
