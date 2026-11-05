module tfib_gc_handoff {
  // Source-bound finite abstraction, not a C implementation/refinement proof.
  // A pointer-bearing thread/frame refers to an F64 payload object. The latter
  // contains raw bits of 0.02, not a Scheme reference, even if its low bit is 1.
  // Two workers and two actual epochs; forwarding announcement precedes copy.
  type State = { policy: int, epoch: int, stage: int, initialized: bool,
    headerTyped: bool, roots: Set[int], rootVersion: int, frameVersion: int,
    executors: Set[int], arrived: Set[int], ackEpoch: int, tails: Set[int],
    copy: int, followed: bool, queued: bool, scanning: bool, finished: bool,
    cellKind: int, badLoad: bool, resultRead: bool, retained: bool,
    regionStart: int, regionEnd: int, writeBase: int, writeWords: int,
    regionGeneration: int, writerGeneration: int }
  var s: State
  pure val workers = Set(0, 1)
  pure def initial(p: int): State = { policy:p, epoch:1, stage:0,
    initialized:false, headerTyped:true, roots:Set(0), rootVersion:1,
    frameVersion:1, executors:Set(0), arrived:Set(), ackEpoch:1,
    tails:Set(), copy:0, followed:false, queued:false, scanning:false,
    finished:false, cellKind:0, badLoad:false, resultRead:false, retained:false,
    regionStart:0, regionEnd:if(p == 12) 37 else 38, writeBase:0, writeWords:38,
    regionGeneration:1, writerGeneration:if(p == 13) 0 else 1 }
  action init = all { s' = initial(0) }
  action initWrongMask = all { s' = initial(1) }
  action initPublishedUninitialized = all { s' = initial(2) }
  action initEarlyChunk = all { s' = initial(3) }
  action initLostRoot = all { s' = initial(4) }
  action initStaleFrame = all { s' = initial(5) }
  action initQueueEmptyIsDone = all { s' = initial(6) }
  action initStaleEpoch = all { s' = initial(7) }
  action initDuplicateExecutor = all { s' = initial(8) }
  action initLostResultRoot = all { s' = initial(9) }
  action initWrongHeader = all { s' = initial(10) }
  action initAllocationFailure = all { s' = initial(11) }
  action initUnreservedBurst = all { s' = initial(12) }
  action initStaleAllocation = all { s' = initial(13) }
  // stage 0 means reserved/registered storage, before caller initialization.
  // Safe acceptance of pending GC must wait for safe defaults, not semantic fill.
  action initialize = all { s.stage == 0, s.policy != 11,
    s' = {...s, stage:1, initialized: s.policy != 2} }
  action allocationFailure = all { s.stage == 0, s.policy == 11,
    s' = {...s, stage:11, retained:true} }
  action publish = all { s.stage == 1,
    s' = {...s, stage:2, headerTyped:s.policy != 10} }
  // Save frame before dropping current-thread ownership; a parked root persists.
  action park = all { s.stage == 2,
    s' = {...s, stage:3, roots:Set(1), executors:Set()} }
  action requestGC = all { s.stage == 3,
    s' = {...s, stage:4, roots:if(s.policy == 4) Set() else s.roots,
      ackEpoch:if(s.policy == 7 and s.epoch == 2) 1 else s.epoch} }
  action arrive = {
    nondet w = workers.exclude(s.arrived).oneOf()
    all { s.stage == 4, s' = {...s, arrived:s.arrived.union(Set(w))} }
  }
  action beginGC = all { s.stage == 4, s.arrived == workers,
    s' = {...s, stage:5} }
  // Current source CAS publishes the forwarding reference before body copying.
  // That alone is allowed. A consumer must wait for the real scan-work publish.
  action announceForward = all { s.stage == 5, s.copy == 0,
    s' = {...s, copy:1} }
  action followForward = all { s.stage == 5, s.copy >= 1, not(s.followed),
    s' = {...s, followed:true} }
  action copyBody = all { s.stage == 5, s.copy == 1,
    s' = {...s, copy:2} }
  action publishChunk = all { s.stage == 5,
    (s.copy == 2 or (s.policy == 3 and s.copy == 1)),
    s' = {...s, stage:6, queued:true} }
  action startScanner = all { s.stage == 6, s.queued, not(s.scanning),
    s' = {...s, queued:false, scanning:true} }
  // cellKind: 0 valid Scheme reference; 1 raw scalar; 2 stale frame/root;
  // 3 uninitialized destination. The fault models a header read, not PAC repair.
  action finishScanner = all { s.stage == 6, s.scanning,
    s' = {...s, scanning:false, finished:true,
      cellKind:if(not(s.initialized) or s.copy != 2) 3
        else if(s.policy == 1 or not(s.headerTyped)) 1
        else if(s.policy == 5 and s.epoch == 2) 2 else 0,
      badLoad: not(s.initialized) or s.copy != 2 or s.policy == 1
        or not(s.headerTyped) or (s.policy == 5 and s.epoch == 2),
      rootVersion:s.epoch+1,
      frameVersion:if(s.policy == 5 and s.epoch == 2) s.frameVersion else s.epoch+1} }
  action finishGC = all { s.stage == 6, not(s.queued),
    (s.finished and not(s.scanning)) or s.policy == 6,
    s' = {...s, stage:7} }
  action finishTail = {
    nondet w = workers.exclude(s.tails).oneOf()
    all { s.stage == 7, s' = {...s, tails:s.tails.union(Set(w))} }
  }
  action returnGC = all { s.stage == 7, s.tails == workers,
    s' = {...s, stage:8} }
  // Last consumers include scanners, saved frame restore, joiner and its result.
  action handoff = all { s.stage == 8,
    s' = {...s, stage:9, roots:if(s.policy == 9) Set() else Set(2),
      executors:if(s.policy == 8) workers else Set(1)} }
  action consumeResult = all { s.stage == 9,
    s' = {...s, stage:10, roots:Set(3), resultRead:true} }
  action nextEpoch = all { s.stage == 10, s.epoch == 1,
    s' = {...s, stage:3, epoch:2, roots:Set(1), executors:Set(), arrived:Set(),
      tails:Set(), copy:0, followed:false, queued:false, scanning:false,
      finished:false, resultRead:false} }
  action terminal = all { (s.stage == 10 and s.epoch == 2) or s.stage == 11,
    s' = s }
  action step = any { initialize, allocationFailure, publish, park, requestGC,
    arrive, beginGC, announceForward, followForward, copyBody, publishChunk,
    startScanner, finishScanner, finishGC, finishTail, returnGC, handoff,
    consumeResult, nextEpoch, terminal }
  val initializedBeforeExposure = s.stage < 2 or s.stage == 11 or s.initialized
  val typedExposure = s.stage < 2 or s.stage == 11 or s.headerTyped
  val continuousRoot = s.stage == 11 or s.roots.size() > 0
  val currentCohort = (s.stage < 5 or s.stage > 8) or
    (s.arrived == workers and s.ackEpoch == s.epoch)
  val scanReady = not(s.scanning) or s.copy == 2
  val scannerReturnedBeforeGC = s.stage < 7 or s.stage == 11 or
    (s.finished and not(s.queued) and not(s.scanning))
  val singleExecutionOwner = s.executors.size() <= 1
  val currentFrames = s.stage < 8 or s.stage == 11 or
    (s.rootVersion == s.epoch+1 and s.frameVersion == s.epoch+1)
  val typedHeaderRead = not(s.badLoad)
  // Header plus 37 initialized words in the retained generated thread constructor.
  // Same numeric address bounds do not prove the allocation belongs to this writer.
  val reservedWrite = s.stage == 0 or s.stage == 11 or
    (s.writeBase >= s.regionStart and s.writeBase+s.writeWords <= s.regionEnd
      and s.writerGeneration == s.regionGeneration)
  val safe = reservedWrite and initializedBeforeExposure and typedExposure and continuousRoot
    and currentCohort and scanReady and scannerReturnedBeforeGC
    and singleExecutionOwner and currentFrames and typedHeaderRead
  val normalDone = s.stage == 10 and s.epoch == 2 and s.resultRead
  val retainedFailure = s.stage == 11 and s.retained and not(s.resultRead)
  temporal completion = weakFair(step,Set(s)).implies(eventually(normalDone or retainedFailure))
}
