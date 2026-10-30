module object_scan_custody {
 // One object, two task occurrences/workers. The copier is worker 0.
 // phase: 0 UNPUBLISHED, 1 READY, 2 OWNED, 3 DONE.
 // task: 0 absent, 1 queued, 2 dequeued, 3 owning scan frame, 4 returned.
 type State={phase:int,owner:int,t0:int,t1:int,payload:bool,forwarded:bool,copier:bool,tail:bool,privateChunk:bool,child0:bool,child1:bool,active0:bool,active1:bool,closed:bool,terminated:bool}
 pure val initial:State={phase:0,owner:-1,t0:0,t1:0,payload:false,forwarded:false,copier:true,tail:false,privateChunk:false,child0:false,child1:false,active0:true,active1:true,closed:false,terminated:false}
 var s:State
 action init=s'=initial
 val safe=all{
  s.phase>=0,s.phase<=3,s.t0>=0,s.t0<=4,s.t1>=0,s.t1<=4,
  s.phase>=1 implies (s.payload and s.forwarded),
  s.payload implies s.forwarded,
  s.copier implies s.active0,
  s.tail implies s.copier,
  s.privateChunk implies (s.copier and s.payload),
  s.phase==2 implies ((s.owner==0 and s.t0==3 and s.active0) or (s.owner==1 and s.t1==3 and s.active1)),
  s.phase!=2 implies s.owner== -1,
  s.t0==3 implies (s.phase==2 and s.owner==0),
  s.t1==3 implies (s.phase==2 and s.owner==1),
  (s.t0>=1 and s.t0<=3) implies s.active0,
  (s.t1>=1 and s.t1<=3) implies s.active1,
  s.t0==4 implies s.phase>=2,
  s.t1==4 implies s.phase>=2,
  s.child0 implies s.active0,s.child1 implies s.active1,
  s.closed implies s.t0>=1,
  s.terminated implies all{s.closed,s.phase==3,not(s.active0),not(s.active1),not(s.copier),not(s.tail),not(s.privateChunk),not(s.child0),not(s.child1),s.t0==4,(s.t1==0 or s.t1==4)}}
 action forward=all{s.copier,not(s.forwarded),not(s.terminated),s'={...s,forwarded:true,tail:true}}
 action initializeCopy=all{s.copier,s.forwarded,not(s.payload),s'={...s,payload:true,privateChunk:true}}
 action publishReady=all{s.copier,s.payload,s.phase==0,s'={...s,phase:1}}
 action publishBatch=all{s.copier,s.privateChunk,s.phase>=1,s.t0==0,s'={...s,privateChunk:false,t0:1}}
 // Models a duplicate queue/frontier occurrence, not a second copied object.
 action duplicateTask=all{not(s.closed),s.t0>=1,s.t1==0,s.active1,s'={...s,t1:1}}
 action closeInputs=all{not(s.closed),s.t0>=1,s'={...s,closed:true}}
 action finishTail=all{s.copier,s.phase>=1,not(s.privateChunk),s'={...s,tail:false,copier:false}}
 // Worker 0 cannot execute a scan concurrently with its own synchronous copy/Tail.
 action claim0=all{s.active0,not(s.copier),s.t0==1,s'={...s,t0:2}}
 action claim1=all{s.active1,s.t1==1,s'={...s,t1:2}}
 action own0=all{s.active0,s.t0==2,s.phase==1,s'={...s,phase:2,owner:0,t0:3,child0:true}}
 action own1=all{s.active1,s.t1==2,s.phase==1,s'={...s,phase:2,owner:1,t1:3,child1:true}}
 // Duplicate return never clears another frame's authority or derived work.
 action skip0=all{s.t0==2,(s.phase==2 or s.phase==3),s.owner!=0,s'={...s,t0:4}}
 action skip1=all{s.t1==2,(s.phase==2 or s.phase==3),s.owner!=1,s'={...s,t1:4}}
 action done0=all{s.t0==3,s.owner==0,s.phase==2,s'={...s,phase:3,owner: -1,t0:4}}
 action done1=all{s.t1==3,s.owner==1,s.phase==2,s'={...s,phase:3,owner: -1,t1:4}}
 // DONE covers the object's scanned fields, not descendants or copier Tail.
 action drain0=all{s.active0,s.t0==4,s.child0,s'={...s,child0:false}}
 action drain1=all{s.active1,s.t1==4,s.child1,s'={...s,child1:false}}
 action idle0=all{s.closed,not(s.copier),s.t0==4,s.owner!=0,not(s.child0),s'={...s,active0:false}}
 action idle1=all{s.closed,(s.t1==0 or s.t1==4),s.owner!=1,not(s.child1),s'={...s,active1:false}}
 // No omniscient pending-work test: zero active count must imply closure via custody.
 action terminate=all{s.closed,not(s.active0),not(s.active1),s'={...s,terminated:true}}
 action step=any{forward,initializeCopy,publishReady,publishBatch,duplicateTask,closeInputs,finishTail,claim0,claim1,own0,own1,skip0,skip1,done0,done1,drain0,drain1,idle0,idle1,terminate,all{s'=s}}
 action batch=forward.then(initializeCopy).then(publishReady).then(publishBatch)
 action owner1=batch.then(duplicateTask).then(closeInputs).then(claim1).then(own1)
 action finish1=done1.then(drain1).then(idle1).then(finishTail).then(claim0).then(skip0).then(idle0).then(terminate)
 run completeTest=init.then(owner1).then(finish1).then(all{assert(safe and s.terminated),s'=s})
 run doneBeforeTailTest=init.then(owner1).then(done1).then(all{assert(safe and s.phase==3 and s.tail and s.child1),s'=s})
 run duplicateOwnedTest=init.then(owner1).then(finishTail).then(claim0).then(skip0).then(idle0).then(all{assert(safe and s.phase==2 and s.active1 and not(s.active0) and s.owner==1),s'=s})
 run duplicateDoneTest=init.then(owner1).then(done1).then(finishTail).then(claim0).then(skip0).then(all{assert(safe and s.child1 and s.phase==3),s'=s})
 run uniqueOwner0Test=init.then(batch).then(closeInputs).then(finishTail).then(claim0).then(own0).then(done0).then(drain0).then(idle0).then(idle1).then(terminate).then(all{assert(safe),s'=s})
 run partialCopyControlTest=init.then(forward).then(all{s'={...s,phase:1}}).then(all{assert(not(safe)),s'=s})
 run duplicateDropsOwnerControlTest=init.then(owner1).then(all{s'={...s,owner: -1}}).then(all{assert(not(safe)),s'=s})
 run ownerIdleControlTest=init.then(owner1).then(all{s'={...s,active1:false}}).then(all{assert(not(safe)),s'=s})
 run tailIdleControlTest=init.then(owner1).then(done1).then(all{s'={...s,active0:false}}).then(all{assert(not(safe)),s'=s})
 run descendantIdleControlTest=init.then(owner1).then(done1).then(all{s'={...s,active1:false}}).then(all{assert(not(safe)),s'=s})
 run queueIdleControlTest=init.then(batch).then(closeInputs).then(finishTail).then(all{s'={...s,active0:false}}).then(all{assert(not(safe)),s'=s})
 run doneIsTerminationControlTest=init.then(owner1).then(done1).then(all{s'={...s,terminated:true}}).then(all{assert(not(safe)),s'=s})
}
