module bundle_root_publication {
 import bundle_root_parameters.* from "./bundle_root_parameters"
 type State={phase:int,roots:Set[int],alive:Set[int],addresses:int->int,initialized:bool,ready:bool,
  active:int,receipt:int,pendingAck:bool,published:bool,releaseStamp:bool,reader:int,saved:int,
  rawAddress:int,badRead:bool,uninitializedScan:bool,workspace:int}
 pure val initial:State={phase:0,roots:Set(0),alive:Set(0),addresses:Map(0->100,1->200),initialized:false,ready:false,
  active:0,receipt:0,pendingAck:false,published:false,releaseStamp:false,reader:-1,saved:-1,
  rawAddress:-1,badRead:false,uninitializedScan:false,workspace:0}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,workspace:WorkspaceCount-1}
 // Slot is registered empty before candidate allocation. GC sees no uninitialized object there.
 action reserveRoot=all {s.phase==0,s'={...s,phase:1,roots:s.roots.union(Set(1))}}
 action allocateCandidate=all {s.phase==1,s'={...s,phase:2,alive:s.alive.union(Set(1))}}
 // No GC-capable step is admitted between raw allocation and field initialization.
 action initialize=all {s.phase==2,s'={...s,phase:3,initialized:true}}
 action finishCandidate=all {s.phase==3,s'={...s,phase:4,ready:true}}
 action publishBundle=all {s.phase==4,s.roots.contains(1),s.alive.contains(1),s.initialized,s.ready,
  s'={...s,phase:5,active:1,receipt:1,pendingAck:true,published:true,releaseStamp:true}}
 action collect=all {s.phase!=2,
  s'={...s,alive:s.alive.intersect(s.roots),addresses:Map(0->s.addresses.get(0)+10,1->s.addresses.get(1)+10)}}
 action borrow=all {s.reader<0,s.roots.contains(s.active),s.alive.contains(s.active),
  (s.active==0 or s.releaseStamp),s'={...s,reader:s.active}}
 action releaseReader=all {s.reader>=0,s'={...s,reader:-1}}
 action dereference=all {s.reader>=0,s'={...s,badRead:not(s.alive.contains(s.reader))}}
 action retireOld=all {s.active==1,s.reader!=0,s.saved!=0,s'={...s,roots:s.roots.exclude(Set(0))}}
 action loseAck=all {s.published,s'={...s,pendingAck:true}}
 action resolveAck=all {s.published,s.receipt==1,s'={...s,pendingAck:false}}
 action saveCandidate=all {s.phase>=3,s.initialized,s.alive.contains(1),s.roots.contains(1),s'={...s,saved:1}}
 action retireSaved=all {s.saved>=0,s'={...s,saved:-1}}
 action abortCandidate=all {s.phase>=1,s.phase<=4,s.phase!=2,s'={...s,phase:6,ready:false}}
 action releaseAborted=all {s.phase==6,s.saved!=1,s.reader!=1,s'={...s,roots:s.roots.exclude(Set(1))}}
 action resumeAfter=all {s.saved==1,s.published,s'={...s,receipt:1}}
 def safe=s.alive.contains(s.active) and s.roots.contains(s.active) and
  (s.reader>=0 implies s.roots.contains(s.reader) and s.alive.contains(s.reader)) and
  (s.saved>=0 implies s.roots.contains(s.saved) and s.alive.contains(s.saved)) and
  (s.phase>=3 and s.phase<=4 implies s.initialized and s.roots.contains(1) and s.alive.contains(1)) and
  (s.published implies s.initialized and s.ready and s.releaseStamp and s.receipt==1 and s.active==1) and
  (s.pendingAck implies s.roots.contains(1) and s.alive.contains(1)) and
  not(s.badRead) and not(s.uninitializedScan)
 action step=any {reserveRoot,allocateCandidate,initialize,finishCandidate,publishBundle,collect,borrow,releaseReader,
  dereference,retireOld,loseAck,resolveAck,saveCandidate,retireSaved,abortCandidate,releaseAborted,resumeAfter,failAllocation,s'=s}
 action failAllocation=all {s.phase==1,s'={...s,phase:6}}
 action noCandidateRoot=s'={...s,roots:s.roots.exclude(Set(1))}
 action rcWorkerScan=s'={...s,alive:s.alive.intersect(s.roots.exclude(Set(1)))}
 action gcUninitialized=s'={...s,uninitializedScan:true}
 action cacheRaw=s'={...s,rawAddress:s.addresses.get(s.reader)}
 action useRaw=s'={...s,badRead:s.rawAddress!=s.addresses.get(s.reader)}
 action forceRetireOld=s'={...s,roots:s.roots.exclude(Set(0))}
 action relaxedPublish=s'={...s,phase:5,active:1,published:true,pendingAck:true,receipt:1,releaseStamp:false}
 action rollbackCommitted=s'={...s,active:0,receipt:0}
 action unpinnedBorrow=s'={...s,reader:0}
 run allocationFailureTest=init.then(reserveRoot).then(failAllocation).then(releaseAborted).expect(safe and s.active==0)
 run partialFailureTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(abortCandidate).then(releaseAborted).then(collect).expect(safe and not(s.alive.contains(1)))
 run committedGcTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(collect).expect(safe and s.receipt==1)
 run lostAckGcTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(loseAck).then(collect).then(resolveAck).expect(safe and s.active==1)
 run oldReaderPinTest=init.then(borrow).then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(collect).then(dereference).expect(safe and s.reader==0)
 run oldDrainTest=init.then(borrow).then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(releaseReader).then(retireOld).then(collect).expect(safe and not(s.alive.contains(0)))
 run savedAbortTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(saveCandidate).then(abortCandidate).then(collect).expect(safe and s.alive.contains(1))
 run savedDrainTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(saveCandidate).then(abortCandidate).then(retireSaved).then(releaseAborted).then(collect).expect(safe and not(s.alive.contains(1)))
 run restoreAfterCommitTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(saveCandidate).then(finishCandidate).then(publishBundle).then(collect).then(resumeAfter).expect(safe and s.receipt==1)
 run currentHandleTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(borrow).then(collect).then(dereference).expect(safe and s.reader==1)
 run rootedInputTest=init.then(reserveRoot).then(collect).expect(safe and s.alive.contains(0))
 run otherContextTest=initOther.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(collect).expect(safe and s.workspace==1)
 run absentRootControlTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(noCandidateRoot).expect(not(safe))
 run lostAckRootControlTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(loseAck).then(noCandidateRoot).expect(not(safe))
 run rcWorkerControlTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(rcWorkerScan).expect(not(safe))
 run uninitializedScanControlTest=init.then(reserveRoot).then(allocateCandidate).then(gcUninitialized).expect(not(safe))
 run rawAddressControlTest=init.then(borrow).then(cacheRaw).then(collect).then(useRaw).expect(not(safe))
 run latePinControlTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(retireOld).then(collect).then(unpinnedBorrow).expect(not(safe))
 run earlyRetireControlTest=init.then(borrow).then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(forceRetireOld).expect(not(safe))
 run relaxedPublishControlTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(relaxedPublish).expect(not(safe))
 run savedRootControlTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(saveCandidate).then(abortCandidate).then(noCandidateRoot).expect(not(safe))
 run rollbackControlTest=init.then(reserveRoot).then(allocateCandidate).then(initialize).then(finishCandidate).then(publishBundle).then(rollbackCommitted).expect(not(safe))
}
