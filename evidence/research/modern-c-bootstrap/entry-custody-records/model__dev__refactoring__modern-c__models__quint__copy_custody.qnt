// Research contract. Does not assert that existing C chunk/root scans refine it.
module copy_custody {
  pure val objects=Set(0,1,2)
  type S={frozen:bool,planned:bool,forwarded:Set[int],payload:Set[int],
    tailPending:Set[int],tailDone:Set[int],queued:Set[int],claimed:Set[int],
    scanned:Set[int],scanCount:int,duplicates:int,lastDuplicate:int,copied:int,capacity:int,
    abortPublished:bool,knownCreate:bool,entered:bool,emptyDomain:bool,
    joinUnknown:bool,isolated:bool,nativeStable:bool,gcs:int,
    privateChunks:Set[int],queuedChunks:Set[int],heldChunks:Set[int],
    drainedChunks:Set[int],closedChunks:Set[int],chunkTakes:Set[int],takeCount:int,
    frameOwner:int,frameRaw:bool,frameOpen:bool,linkReady:bool,ordinarySeen:Set[int],staleFrameRead:bool,
    reservationState:int,activeCharge:int,reservedCharge:int,refundedCharge:int,committedCharge:int,
    reservationInitialized:bool,unknownHeld:bool}
  var s:S
  pure val empty:S={frozen:false,planned:false,forwarded:Set(),payload:Set(),
    tailPending:Set(),tailDone:Set(),queued:Set(),claimed:Set(),scanned:Set(),
    scanCount:0,duplicates:0,lastDuplicate:-1,copied:0,capacity:3,abortPublished:false,knownCreate:true,
    entered:false,emptyDomain:true,joinUnknown:false,isolated:false,
    nativeStable:true,gcs:0,privateChunks:Set(1,2),queuedChunks:Set(),
    heldChunks:Set(0),drainedChunks:Set(),closedChunks:Set(),chunkTakes:Set(),takeCount:0,
    frameOwner:-1,frameRaw:false,frameOpen:false,linkReady:false,ordinarySeen:Set(),staleFrameRead:false,
    reservationState:0,activeCharge:0,reservedCharge:0,refundedCharge:0,committedCharge:0,
    reservationInitialized:false,unknownHeld:false}
  action init={s'=empty}
  action freeze=all{not(s.frozen),s'={...s,frozen:true}}
  action plan=all{s.frozen,s.capacity>=objects.size(),s'={...s,planned:true}}
  action forward=all{s.planned,s.forwarded!=objects,
    nondet o=objects.exclude(s.forwarded).oneOf();
    s'={...s,forwarded:s.forwarded.union(Set(o)),
      tailPending:s.tailPending.union(Set(o)),copied:s.copied+1}}
  action initializeCopy=all{s.payload!=s.forwarded,
    nondet o=s.forwarded.exclude(s.payload).oneOf();
    s'={...s,payload:s.payload.union(Set(o))}}
  action publish=all{s.queued!=s.payload,
    nondet o=s.payload.exclude(s.queued).oneOf();
    s'={...s,queued:s.queued.union(Set(o))}}
  action completeTail=all{s.tailPending.intersect(s.payload)!=Set(),
    nondet o=s.tailPending.intersect(s.payload).oneOf();
    s'={...s,tailPending:s.tailPending.exclude(Set(o)),
      tailDone:s.tailDone.union(Set(o))}}
  action claim=all{s.queued.exclude(s.claimed)!=Set(),
    nondet o=s.queued.exclude(s.claimed).oneOf();
    s'={...s,claimed:s.claimed.union(Set(o))}}
  action scan=all{s.claimed.exclude(s.scanned)!=Set(),
    nondet o=s.claimed.exclude(s.scanned).oneOf();
    // Tail is not executed by ordinary scan, even if it is pending.
    s'={...s,scanned:s.scanned.union(Set(o)),scanCount:s.scanCount+1}}
  action observeDuplicate=all{s.claimed!=Set(),
    nondet o=s.claimed.oneOf();
    s'={...s,duplicates:s.duplicates+1,lastDuplicate:o}}
  action abort=all{not(s.entered),s'={...s,abortPublished:true}}
  action unknownJoin={s'={...s,joinUnknown:true}}
  action unknownCreate=all{not(s.abortPublished),s'={...s,knownCreate:false}}
  action isolate=all{s.abortPublished,s.knownCreate,not(s.entered),
    s.emptyDomain,s.joinUnknown,s.nativeStable,s'={...s,isolated:true}}
  action collectHealthy=all{not(s.joinUnknown) or s.isolated,
    s'={...s,gcs:s.gcs+1}}
  // Chunk identity is the link word, not an allocation-tip range test.
  // This finite partition is not yet a proof of disjoint physical C intervals.
  action closePrivate=all{s.privateChunks!=Set(),
    nondet c=s.privateChunks.oneOf();
    s'={...s,privateChunks:s.privateChunks.exclude(Set(c)),
      queuedChunks:s.queuedChunks.union(Set(c)),closedChunks:s.closedChunks.union(Set(c))}}
  action closeHeld=all{s.heldChunks.exclude(s.closedChunks)!=Set(),
    nondet c=s.heldChunks.exclude(s.closedChunks).oneOf();
    s'={...s,closedChunks:s.closedChunks.union(Set(c))}}
  action takeChunk=all{s.queuedChunks!=Set(),
    nondet c=s.queuedChunks.oneOf();
    s'={...s,queuedChunks:s.queuedChunks.exclude(Set(c)),heldChunks:s.heldChunks.union(Set(c)),
      chunkTakes:s.chunkTakes.union(Set(c)),takeCount:s.takeCount+1}}
  action selectFrontier=all{s.privateChunks!=Set(),
    nondet c=s.privateChunks.oneOf();
    s'={...s,privateChunks:s.privateChunks.exclude(Set(c)),heldChunks:s.heldChunks.union(Set(c))}}
  action drainChunk=all{s.heldChunks.intersect(s.closedChunks)!=Set(),
    nondet c=s.heldChunks.intersect(s.closedChunks).oneOf();
    s'={...s,heldChunks:s.heldChunks.exclude(Set(c)),drainedChunks:s.drainedChunks.union(Set(c))}}
  // Raw READY can precede link completion, but cannot grant frame access.
  action acquireConstructor=all{s.frameOwner == -1,s'={...s,frameOwner:0}}
  action beginFrameChain=all{s.frameOwner==0,not(s.frameRaw),s'={...s,frameOpen:true}}
  action publishFrameRaw=all{s.frameOwner==0,s.frameOpen,s'={...s,frameRaw:true}}
  action repairFrameLink=all{s.frameOwner==0,s.frameOpen,s.frameRaw,
    s'={...s,frameOpen:false,linkReady:true}}
  action releaseFrameAccess=all{s.frameOwner != -1,not(s.frameOpen),s'={...s,frameOwner:-1}}
  action acquireScanner=all{s.frameOwner == -1,s.frameRaw,s'={...s,frameOwner:1}}
  action scanOrdinaryFrame=all{s.frameOwner==1,s.linkReady,not(s.frameOpen),
    s'={...s,ordinarySeen:Set(1,3,4)}}
  // Charge 3 words: 2 payload/header words plus one possible alignment word.
  // Physical interval bounds and source identity are separate C premises.
  action reservePrivateCopy=all{s.reservationState==0,
    s'={...s,reservationState:1,activeCharge:3,reservedCharge:s.reservedCharge+3,
      reservationInitialized:false}}
  action loseForwarding=all{s.reservationState==1,
    s'={...s,reservationState:0,activeCharge:0,refundedCharge:s.refundedCharge+s.activeCharge}}
  action winForwarding=all{s.reservationState==1,s'={...s,reservationState:2}}
  action initializeReserved=all{s.reservationState==2,s'={...s,reservationInitialized:true}}
  action commitReservation=all{s.reservationState==2,s.reservationInitialized,
    s'={...s,reservationState:0,activeCharge:0,committedCharge:s.committedCharge+s.activeCharge}}
  action unknownReservation=all{s.reservationState==1,
    s'={...s,reservationState:3,unknownHeld:true}}
  action step=any{freeze,plan,forward,initializeCopy,publish,completeTail,claim,scan,observeDuplicate,
    abort,unknownJoin,unknownCreate,isolate,collectHealthy,closePrivate,closeHeld,takeChunk,
    selectFrontier,drainChunk,acquireConstructor,beginFrameChain,publishFrameRaw,repairFrameLink,
    releaseFrameAccess,acquireScanner,scanOrdinaryFrame,reservePrivateCopy,loseForwarding,
    winForwarding,initializeReserved,commitReservation,unknownReservation,s'=s}
  val safe=all{
    s.copied==s.forwarded.size(),s.copied<=objects.size(),
    s.planned implies s.capacity>=objects.size(),
    s.payload.subseteq(s.forwarded),s.queued.subseteq(s.payload),
    s.claimed.subseteq(s.queued),s.scanned.subseteq(s.claimed),
    s.scanCount==s.scanned.size(),
    s.duplicates>0 implies s.lastDuplicate.in(s.claimed),
    s.tailPending.union(s.tailDone)==s.forwarded,
    s.tailPending.intersect(s.tailDone)==Set(),
    s.tailDone.subseteq(s.payload),
    s.isolated implies all{s.abortPublished,s.knownCreate,not(s.entered),
      s.emptyDomain,s.nativeStable},
    s.joinUnknown implies s.nativeStable,
    s.privateChunks.union(s.queuedChunks).union(s.heldChunks).union(s.drainedChunks)==objects,
    s.privateChunks.intersect(s.queuedChunks.union(s.heldChunks).union(s.drainedChunks))==Set(),
    s.queuedChunks.intersect(s.heldChunks.union(s.drainedChunks))==Set(),
    s.heldChunks.intersect(s.drainedChunks)==Set(),
    s.queuedChunks.union(s.drainedChunks).subseteq(s.closedChunks),
    s.chunkTakes.subseteq(s.heldChunks.union(s.drainedChunks)),
    s.takeCount==s.chunkTakes.size(),
    s.frameOwner.in(Set(-1,0,1)),
    s.frameOpen implies s.frameOwner==0,
    s.linkReady implies all{s.frameRaw,not(s.frameOpen)},
    s.ordinarySeen.subseteq(Set(1,3,4)),
    s.ordinarySeen!=Set() implies s.linkReady,
    not(s.staleFrameRead),
    s.reservedCharge==s.refundedCharge+s.committedCharge+s.activeCharge,
    s.reservationState==0 implies s.activeCharge==0,
    s.reservationState!=0 implies s.activeCharge==3,
    s.unknownHeld implies s.reservationState==3
  }
  val workDrained=all{s.payload==s.forwarded,s.scanned==s.forwarded,s.tailPending==Set(),
    s.queuedChunks==Set(),s.heldChunks.intersect(s.closedChunks)==Set(),
    s.reservationState==0,s.frameOwner == -1,not(s.frameOpen)}
  action tailDebtCheck=all{s.scanned==s.forwarded,s.tailPending!=Set(),not(workDrained),s'=s}
  action chunkDebtCheck=all{s.payload==s.forwarded,s.scanned==s.forwarded,
    s.tailPending==Set(),s.heldChunks.intersect(s.closedChunks)!=Set(),not(workDrained),s'=s}
  action check=all{safe,s'=s}
  run copyTest=init.then(freeze).then(plan).then(forward).then(initializeCopy)
    .then(publish).then(claim).then(scan).then(completeTail).then(check)
  run duplicateTaskTest=init.then(freeze).then(plan).then(forward).then(initializeCopy)
    .then(publish).then(claim).then(observeDuplicate).then(scan).then(observeDuplicate).then(completeTail).then(check)
  run tailDebtTest=init.then(freeze).then(plan).then(forward).then(initializeCopy)
    .then(publish).then(claim).then(scan).then(tailDebtCheck).then(completeTail).then(check)
  run isolatedGCTest=init.then(abort).then(unknownJoin).then(isolate)
    .then(collectHealthy).then(collectHealthy).then(check)
  run unknownCreateRetainedTest=init.then(unknownCreate).then(abort)
    .then(unknownJoin).then(check)
  run frontierTest=init.then(closeHeld).then(drainChunk).then(selectFrontier).then(check)
  run queuedTransportTest=init.then(closePrivate).then(takeChunk).then(drainChunk).then(check)
  run chunkDebtTest=init.then(freeze).then(plan).then(forward).then(initializeCopy)
    .then(publish).then(claim).then(scan).then(completeTail).then(closeHeld).then(chunkDebtCheck).then(check)
  run frameHandoffTest=init.then(acquireConstructor).then(beginFrameChain).then(publishFrameRaw)
    .then(repairFrameLink).then(releaseFrameAccess).then(acquireScanner).then(scanOrdinaryFrame)
    .then(releaseFrameAccess).then(check)
  run refundTest=init.then(reservePrivateCopy).then(loseForwarding).then(check)
  run reservationCommitTest=init.then(reservePrivateCopy).then(winForwarding)
    .then(initializeReserved).then(commitReservation).then(check)
  run unknownReservationTest=init.then(reservePrivateCopy).then(unknownReservation).then(check)
  action scanUnfinishedFrame={s'={...empty,frameOwner:0,frameRaw:true,frameOpen:true,staleFrameRead:true}}
  action ordinaryWritesLink={s'={...empty,ordinarySeen:Set(2)}}
  action refundUnknown={s'={...empty,reservedCharge:3,refundedCharge:3,unknownHeld:true}}
  action doubleRefund={s'={...empty,reservedCharge:3,refundedCharge:6}}
  action publishHeldAgain={s'={...empty,queuedChunks:Set(0)}}
  action duplicateChunkTake={s'={...empty,takeCount:2,chunkTakes:Set(0)}}
  action recopyTospace={s'={...empty,forwarded:Set(0),tailPending:Set(0),copied:2}}
  action duplicateScan={s'={...empty,scanCount:2,scanned:Set(0)}}
  action isolateUnknownCreate={s'={...empty,abortPublished:true,knownCreate:false,
    joinUnknown:true,isolated:true}}
  action reuseUnknownNative={s'={...empty,joinUnknown:true,nativeStable:false}}
}
