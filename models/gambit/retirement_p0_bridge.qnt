module retirement_p0_bridge {
  // Single transition system: P0+A+B, two GC rounds per epoch, two epochs.
  // mode 0 abort/abort; 1 abort/success; 2 invalid suffix -> opaque containment.
  // Mutation policies are enumerated in the accompanying source contract.
  type State = { policy: int, mode: int, epoch: int, phase: int, cohort: int,
    a: int, b: int, aCalls: int, bCalls: int, yCalls: int,
    totalA: int, totalB: int, totalY: int,
    xFreed: bool, xQueued: bool, f15: bool,
    yAlive: bool, f17: int, f18: bool,
    round: int, gcPhase: int, lastGC: int, version: int,
    f23: int, f24: int, f25: int, staleGC: bool,
    sourceA: bool, sourceB: bool, f29: int, f30: int,
    f31: bool, f32: bool, f33: int, f34: int,
    f35: bool, frameA: bool, frameB: bool, f38: bool,
    f39: bool, f40: int,
    error: bool, f42: bool, f43: int, f44: bool,
    f45: bool, f46: bool, f47: bool, f48: bool,
    f49: bool, f50: bool,
    f51: bool, handoff: bool, ack0: int, ackA: int, ackB: int,
    f56: bool, common: bool, resumed: bool, f59: bool,
    left0: bool, leftA: bool, leftB: bool, f63: bool,
    f64: bool, f65: bool, f66: bool,
    tail0: int, tailA: int, tailB: int, f70: bool, f71: bool,
    f72: bool, f73: int, f74: int, f75: bool,
    f76: int, f77: bool, movable: bool, f79: int, f80: bool,
    f81: bool, f82: bool, f83: int,
    f84: bool, f85: bool, f86: bool, f87: bool, f88: bool,
    f89: bool, f90: bool, f91: int, f92: int,
    f93: bool, f94: bool, h: int, he: int, pc: int, rr: int, blocked: bool, bg: int, roots: bool, ctx: bool, mk: bool, gv: bool, bv: int, fault: int, bf: int, attempt: int, entry: int }
  var s: State
  pure def initial(policy: int, mode: int): State = {
    policy: policy, mode: mode, epoch: 0, phase: 0, cohort: 3,
    a: 0, b: 0, aCalls: 0, bCalls: 0, yCalls: 0,
    totalA: 0, totalB: 0, totalY: 0,
    xFreed: false, xQueued: false, f15: false,
    yAlive: false, f17: 0, f18: false,
    round: 0, gcPhase: 0, lastGC: 0, version: 0,
    f23: 0, f24: 0, f25: 0, staleGC: false,
    sourceA: true, sourceB: true, f29: 0, f30: 0,
    f31: false, f32: false, f33: -1, f34: -1,
    f35: true, frameA: true, frameB: true, f38: false,
    f39: false, f40: 0,
    error: false, f42: false, f43: -1, f44: false,
    f45: true, f46: false, f47: false, f48: false,
    f49: false, f50: false,
    f51: false, handoff: false, ack0: 0, ackA: 0, ackB: 0,
    f56: false, common: false, resumed: false, f59: false,
    left0: false, leftA: false, leftB: false, f63: false,
    f64: false, f65: false, f66: false,
    tail0: 0, tailA: 0, tailB: 0, f70: false, f71: false,
    f72: true, f73: 0, f74: -1, f75: false,
    f76: -1, f77: false, movable: true, f79: 0, f80: false,
    f81: false, f82: false, f83: 0,
    f84: false, f85: false, f86: true, f87: false, f88: false,
    f89: false, f90: false, f91: 0, f92: 0,
    f93: false, f94: true, h: 0, he: 0, pc: 0, rr: 0, blocked: false, bg: 0, roots: false, ctx: true, mk: false, gv: true, bv: 0, fault: 0, bf: 0, attempt: 0, entry: 0 }
  action initAbortTwice = s' = initial(0,0)
  action initAbortThenCommit = s' = initial(0,1)
  action initOpaqueSuffix = s' = initial(0,2)
  action initEarlyReturn = s' = initial(1,0)
  action initEarlySourceDrop = s' = initial(2,0)
  action initStaleGCRound = s' = initial(3,0)
  action initStaleGCEpoch = s' = initial(4,0)
  action initStaleAbortEpoch = s' = initial(5,0)
  action initEarlyErrorRelease = s' = initial(6,0)
  action initReplay = s' = initial(7,0)
  action initDeadSuffixResume = s' = initial(8,2)
  action initStrongifyWeak = s' = initial(9,0)
  action initWithdrawFrame = s' = initial(10,0)
  action initDropWillOwner = s' = initial(11,0)
  action initEarlyDecision = s' = initial(12,0)
  action initStaleCursor = s' = initial(13,0)
  action initPrematureReuse = s' = initial(14,0)
  action initUnscannedPayload = s' = initial(15,0)
  action initMissingHandoff = s' = initial(17,1)
  action initFreedNodeAccess = s' = initial(16,0)
  action initImmediateErrors = s' = { ...initial(0,0), movable: false }
  action initRegisteredCCaller = s' = { ...initial(0,0), f79: 1 }
  action initScanStillActive = s' = initial(18,0)
  action initSkippedGCTail = s' = initial(19,0)
  action initLateWorkProducer = s' = initial(20,1)
  action initMissingStillRC = s' = initial(21,1)
  action initLiveNativeOrigin = s' = { ...initial(22,1), f72: false }
  action initGCInReturnGap = s' = initial(23,0)
  action initStaleReturnCopy = s' = initial(24,0)
  action initUnregisteredCCaller = s' = { ...initial(25,0), f79: 2 }
  action initCatcherOnly = s' = { ...initial(26,0), f79: 3 }
  action initSkipPrivateChunk = s' = initial(27,1)
  action initRawStackInRC = s' = initial(28,1)
  action initLostThreadAnchor = s' = initial(29,1)
  action initDuplicateRunnable = s' = initial(30,1)
  action initUnsealedScheduling = s' = initial(31,1)
  action initFreedStackBeforeCopy = s' = initial(32,1)
  action initEarlyPublication = s' = initial(33,1)
  action initEarlyRestore = s' = initial(34,1)
  action initUnrootedPark = s' = initial(35,1)
  action initStaleHelper = s' = initial(36,1)
  action initHelperStopsGC = s' = initial(37,1)
  action initRepublish = s' = initial(38,1)
  action initEarlyAPIReturn = s' = initial(39,1)
  action initDirectCPrepared = s' = { ...initial(0,1), entry: 1, f79: 1 }
  action initMarkerFailureRetry = s' = { ...initial(0,1), bf: 1 }
  action initCaughtSchemeRetry = s' = { ...initial(0,1), bf: 2 }
  action initMissingBridgeRoots = s' = { ...initial(40,1), entry: 0, bf: 0 }
  action initPublicSFUNClosedGate = s' = { ...initial(41,1), entry: 0, bf: 0 }
  action initReopenedBridgeGate = s' = { ...initial(42,1), entry: 0, bf: 0 }
  action initRunClobber = s' = { ...initial(43,1), entry: 0, bf: 0 }
  action initWrongReturnMarker = s' = { ...initial(44,1), entry: 0, bf: 0 }
  action initNestedResizeInHelper = s' = { ...initial(45,1), entry: 0, bf: 0 }
  action initEarlyMarkerKill = s' = { ...initial(46,1), entry: 0, bf: 0 }
  action initStaleBridgeResult = s' = { ...initial(47,1), entry: 0, bf: 0 }
  action initEarlyBridgeReturn = s' = { ...initial(48,1), entry: 0, bf: 0 }
  action initThrowSkipsCleanup = s' = { ...initial(49,1), entry: 0, bf: 2 }
  action initDirectCWrongContext = s' = { ...initial(50,1), entry: 2, bf: 0 }
  action initRawUnwindResume = s' = initial(51,1)
  val shouldFail = s.epoch == 1 or s.mode != 1
  val gcKey = s.epoch * 10 + s.round
  val allArrived = s.f23 == gcKey and (s.cohort == 1 or (s.f24 == gcKey and s.f25 == gcKey))
  val allAcked = s.ack0 == s.epoch and s.ackA == s.epoch and s.ackB == s.epoch
  val tailsReturned = s.tail0 == gcKey and (s.cohort == 1 or (s.tailA == gcKey and s.tailB == gcKey))
  val workClosed = not(s.f64) and not(s.f65) and not(s.f66) and
    not(s.f89) and not(s.f90) and not(s.f88)
  val resultReleased = s.f44 and not(s.f39) and not(s.f42) and s.f77
  val allLeft = s.left0 and s.leftA and s.leftB
  action openEpoch = all { s.phase == 0, s.epoch < 2,
    s' = { ...initial(s.policy,s.mode), bf: s.bf, entry: s.entry, epoch: s.epoch + 1, phase: 1, bCalls: if(s.policy == 13 and s.epoch == 1) s.bCalls else 0, yAlive: true, f29: s.version, f30: s.version, f35: s.policy != 15, frameA: s.policy != 10, f39: true, f40: s.version, f45: s.policy != 11, blocked: false, cohort: s.cohort, totalA: s.totalA, totalB: s.totalB, totalY: s.totalY, version: s.version, f23: s.f23, f24: s.f24, f25: s.f25, staleGC: s.staleGC, ack0: s.ack0, ackA: s.ackA, ackB: s.ackB, f56: s.f56, f63: s.f63, tail0: s.tail0, tailA: s.tailA, tailB: s.tailB, f70: s.f70, f72: s.f72, movable: s.movable, f79: s.f79 } }
  // h: 0 C service, 1 Scheme capture, 2 C preparation,
  // 3 survivor Scheme activation, 4 activation complete,
  // 5 origin Scheme rollback, 6 rollback complete. he authenticates the helper epoch.
  action yieldCapture = all { s.phase == 1, s.h == 0,
    s' = { ...s, h: 1, he: s.epoch } }
  action reenterPreparation = all { s.h == 1, s.f84,
    s' = { ...s, h: 2 } }
  // bg: 0 none/retry, 1 rooted context, 2 marker, 3 Scheme call,
  // 4 matching C return, 5 finalized bridge, 6 caught entry/helper error.
  action rootBridge = all { s.common, s.bg == 0, s.h >= 2,
    s' = { ...s, bg: 1, roots: s.policy != 40, ctx: s.policy != 43 and s.entry != 2,
      gv: s.policy != 42, bv: s.version } }
  action makeBridgeMarker = all { s.bg == 1,
    s' = { ...s, bg: if(s.bf == 1 and s.attempt == 0) 6 else 2,
      mk: not(s.bf == 1 and s.attempt == 0) } }
  action yieldCompletion = all { s.common, s.bg == 2,
    s' = { ...s, bg: 3, h: if(s.error) 5 else 3,
      he: if(s.policy == 36) s.epoch - 1 else s.epoch,
      f85: s.policy != 35 and s.f85 } }
  action helperThrows = all { s.bg == 3, s.bf == 2, s.attempt == 0, s.round == 2,
    s' = { ...s, bg: 6 } }
  // Scheme caught-status still returns through the matching return-to-C frame.
  action matchCaughtReturn = all { s.bg == 6, s.mk, s.bf == 2,
    s' = { ...s, bg: 4 } }
  action cleanupBridgeError = all { (s.bg == 6 and not(s.mk)) or
    (s.bg == 4 and s.bf == 2 and not(helperDone)),
    s' = { ...s, bg: 0, mk: false, attempt: 1 } }
  action skipCaughtCleanup = all { s.bg == 6, s.policy == 49,
    s' = { ...s, bg: 5, fault: 3 } }
  action rawUnwindResume = all { s.bg == 3, s.policy == 51,
    s' = { ...s, bg: 6, ctx: false } }
  action returnBridge = all { s.bg == 3, helperDone, s.gcPhase == 0,
    s' = { ...s, bg: 4, fault: if(s.policy == 44) 2 else s.fault,
      bv: if(s.policy == 47) s.version - 1 else s.bv } }
  action closeBridge = all { s.bg == 4, helperDone,
    s' = { ...s, bg: 5, mk: false, roots: false } }
  action badPublicEntry = all { s.bg == 1, s.policy == 41,
    s' = { ...s, fault: 1 } }
  action badNestedResize = all { s.bg == 3, s.policy == 45,
    s' = { ...s, fault: 4 } }
  action badMarkerKill = all { s.bg == 3, s.policy == 46, s.mk,
    s' = { ...s, mk: false } }
  action requestHelperGC = all { s.common, s.bg == 3, (s.bf != 2 or s.attempt == 1), (s.h == 3 or s.h == 5), s.round == 2,
    s' = { ...s, round: 3, gcPhase: 1, f64: true, f66: true,
      blocked: s.policy == 37 } }
  action earlyPublication = all { s.policy == 33, s.phase == 1, s.f92 == 1,
    s' = { ...s, pc: 1, f92: 2 } }
  action republish = all { s.policy == 38, s.pc == 1,
    s' = { ...s, pc: 2 } }
  // Scheme safe-point operations, not raw copies of a C activation.
  action closeDonorScheduling = all { s.phase == 1, not(s.f81),
    s' = { ...s, f81: true, f82: s.policy != 31 } }
  action saveDonorThread = all { s.phase == 1, s.h == 1, s.f81, s.f83 == 0,
    s' = { ...s, f83: 1, f92: 1 } }
  action publishThreadAnchor = all { s.phase == 1, s.f83 == 1, not(s.f84),
    // Policy 29 marks the publication attempt complete without a reachable anchor.
    s' = { ...s, f84: true, f85: s.policy != 29, f86: s.policy != 28 } }
  action freeStackEarly = all { s.policy == 32, s.f83 == 1, s.f94,
    s' = { ...s, f94: false } }
  action startA = all { s.phase == 1, s.h == 2, s.a == 0,
    s' = { ...s, a: 1, aCalls: s.aCalls + 1, totalA: s.totalA + 1 } }
  action readyA = all { s.phase == 1, s.a == 1, s.gcPhase == 0,
    s' = { ...s, a: 2, f31: true, f33: s.version,
      sourceA: s.policy != 2 } }
  // Atomic one-node pop under existing mutex, then unlocked callback.
  // Y remains queue-owned and never invoked during a failed preparation.
  action popAndStartB = all { s.phase == 1, s.h == 2, s.b == 0,
    s' = { ...s, b: 1, bCalls: s.bCalls + 1, totalB: s.totalB + 1 } }
  action requestGC1 = all { s.phase == 1, s.b == 1, s.round == 0, s.f83 == 1, s.f84,
    s' = { ...s, round: 1, gcPhase: 1, f64: true, f66: true } }
  action outcomeB = all { s.phase == 1, s.b == 1, s.a == 2,
    s.lastGC == s.epoch * 10 + 1, s.gcPhase == 0,
    s' = { ...s, b: if(shouldFail) 3 else 2, xFreed: true,
      error: shouldFail, f42: shouldFail, f43: if(shouldFail) s.version else -1,
      yAlive: s.mode != 2, f18: s.mode == 2,
      f15: s.policy == 16 } }
  action requestGC2 = all { s.phase == 1, s.b >= 2, s.round == 1, s.gcPhase == 0,
    s' = { ...s, round: 2, gcPhase: 1, f64: true, f66: true } }
  action arriveP0 = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 1, not(s.blocked), not(s.left0), s.f23 != gcKey,
    s' = { ...s, f23: gcKey } }
  action arriveA = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 1, s.cohort == 3, not(s.leftA), s.f24 != gcKey,
    s' = { ...s, f24: gcKey } }
  action arriveB = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 1, s.cohort == 3, not(s.leftB), s.f25 != gcKey,
    s' = { ...s, f25: gcKey } }
  // Strong roots first. The GC key contains both epoch and within-epoch round.
  action markStrong = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 1,
    allArrived or
      (s.policy == 3 and s.round == 2 and s.f23 >= s.epoch * 10 + 1 and s.f24 >= s.epoch * 10 + 1 and s.f25 >= s.epoch * 10 + 1) or
      (s.policy == 4 and s.epoch == 2 and s.f23 > 0 and s.f24 > 0 and s.f25 > 0),
    s' = { ...s, gcPhase: 2, f65: true, f64: false, staleGC: s.staleGC or not(allArrived), version: s.version + 1, bv: if(s.roots) s.version + 1 else s.bv,
      f29: if(s.sourceA and s.frameA) s.version + 1 else s.f29,
      f30: if(s.sourceB and s.frameB) s.version + 1 else s.f30,
      f33: if(s.f31) s.version + 1 else s.f33,
      f34: if(s.f32) s.version + 1 else s.f34,
      f40: if(s.f39 and s.f35) s.version + 1 else s.f40,
      f43: if(s.f42 and s.f35) s.version + 1 else s.f43,
      f47: (s.f45 or s.f46), f48: s.policy == 9 } }
  // Special continuation scanning, reached through actual thread/cont object.
  // An immediate-looking raw stack address in generic RC data does not take this path.
  action materializeCapturedFrames = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 2,
    s.f83 == 1, not(s.f87),
    s' = { ...s, f87: true,
      f83: if(s.f85 and s.f86) 2 else 1,
      f88: true, f89: true } }
  action determineWill = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 2, s.f87,
    s' = { ...s, gcPhase: 3, f49: true,
      f50: s.f50 or ((s.f45 or s.f46) and not(s.f48)) } }
  // process_wills/marking may publish additional work. Empty FIFO != scan return.
  action publishWeakWork = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 3,
    s' = { ...s, gcPhase: 4, f64: true, f66: false } }
  action dequeueLastWork = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 4, s.f64,
    s' = { ...s, f64: false } }
  // scan_movable_objs also scans the donor's incomplete allocation chunk.
  action scanPrivateChunk = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 4,
    s.f89, not(s.f90),
    s' = { ...s, f90: true } }
  action returnPrivateScan = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 4, s.f90,
    s' = { ...s, f89: false, f90: false, f88: false } }
  action returnScanner = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 4,
    not(s.f64), s.f65,
    (not(s.f89) and not(s.f90) and not(s.f88)) or s.policy == 27,
    s' = { ...s, gcPhase: 5, f65: false } }
  action finishGC = all { (s.phase == 1 or s.phase == 3 or s.phase == 4),
    (s.gcPhase == 5 and (workClosed or s.policy == 27)) or
      (s.policy == 18 and s.gcPhase == 4 and not(s.f64)),
    s' = { ...s, gcPhase: 6, f48: s.f45 } }
  // Full GC epilogue includes fp/hp restoration, not just the weak-phase barrier.
  action tailP0 = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 6, s.tail0 != gcKey,
    s' = { ...s, tail0: gcKey } }
  action tailA = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 6, s.cohort == 3, s.tailA != gcKey,
    s' = { ...s, tailA: gcKey } }
  action tailB = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 6, s.cohort == 3, s.tailB != gcKey,
    s' = { ...s, tailB: gcKey } }
  action completeGCReturn = all { (s.phase == 1 or s.phase == 3 or s.phase == 4), s.gcPhase == 6,
    tailsReturned or s.policy == 19,
    s' = { ...s, gcPhase: 0, lastGC: gcKey, f91: if(s.f83 == 2 and workClosed) gcKey else s.f91, f70: s.f70 or not(tailsReturned) } }
  // Success must discharge Y before the no-future-callback cut.
  action cancelYOnSuccess = all { s.phase == 1, not(s.error), s.b == 2,
    s.lastGC == s.epoch * 10 + 2, s.gcPhase == 0, s.yAlive, s.yCalls == 0,
    s' = { ...s, yAlive: false, yCalls: 1, totalY: s.totalY + 1 } }
  action settlePreparation = all { s.phase == 1, s.a == 2, s.b >= 2,
    s.lastGC == s.epoch * 10 + 2, s.gcPhase == 0, workClosed, tailsReturned, not(s.f51),
    s.error or s.yCalls == 1,
    s' = { ...s, f51: true,
      f17: if(not(s.error)) 3 else if(s.yAlive or s.policy == 8) 1 else 2 } }
  // Abstract typed handoff: values/continuations already on supported surviving owners.
  // This is a C refinement premise, NOT raw native frame migration.
  action spliceStillRC = all { s.phase == 1, s.f51, not(s.error), not(s.f71),
    s' = { ...s, f71: true, f32: true, f34: s.version } }
  action handoffFrameValues = all { s.phase == 1, s.f51, not(s.error), not(s.f38),
    s.f72 or s.policy == 22,
    (s.f83 == 2 and s.f85 and s.f86 and s.f91 == gcKey) or s.policy == 28 or s.policy == 29,
    s' = { ...s, f38: true } }
  action publishRunnableOnReceiver = all { s.phase == 4, s.h == 3, s.he == s.epoch,
    s.lastGC == gcKey, s.round == 3, s.gcPhase == 0, workClosed,
    s.f38, s.f92 == 1, s.pc == 0,
    s' = { ...s, f92: 2, pc: 1, h: 4 } }
  action f93 = all { s.policy == 30, s.f92 == 2, not(s.f93),
    s' = { ...s, f93: true } }
  action handoffWillLists = all { s.phase == 1, s.f51, not(s.error), not(s.f46),
    s' = { ...s, f46: true } }
  action prepareHandoff = all { s.phase == 1, s.f51, not(s.error), not(s.handoff),
    (s.f71 or s.policy == 21), s.f38, s.f92 == 1, s.f46, workClosed,
    s' = { ...s, handoff: true, f32: true, f34: s.version } }
  action lateProducer = all { s.policy == 20, s.phase == 1, s.f51, not(s.f66),
    s' = { ...s, f66: true, f64: true } }
  action earlyReturn = all { s.policy == 1, s.phase == 1, s.error, not(s.leftB),
    s' = { ...s, leftB: true } }
  action releaseErrorEarly = all { s.policy == 6, s.f42, not(s.f44),
    s' = { ...s, f42: false } }
  action replayX = all { s.policy == 7, s.error, not(s.xQueued),
    s' = { ...s, xQueued: true, bCalls: s.bCalls + 1 } }
  action decide = all { s.phase == 1, s.a == 2, s.b >= 2, s.gcPhase == 0,
    (s.f51 and (s.error or s.handoff or s.policy == 17)) or s.policy == 12,
    s' = { ...s, phase: 2 } }
  action ackP0 = all { s.phase == 2, s.ack0 != s.epoch, s' = { ...s, ack0: s.epoch } }
  action ackA = all { s.phase == 2, s.ackA != s.epoch, s' = { ...s, ackA: s.epoch } }
  action ackB = all { s.phase == 2, s.ackB != s.epoch, s' = { ...s, ackB: s.epoch } }
  action commonCompletion = all { s.phase == 2,
    allAcked or (s.policy == 5 and s.epoch == 2 and s.ack0 > 0 and s.ackA > 0 and s.ackB > 0),
    s' = { ...s, phase: if(s.error) 3 else 4, common: true,
      f56: not(allAcked), cohort: if(s.error) 3 else 1,
      f59: s.error and s.f17 == 2,
      resumed: s.error and s.f17 == 1,
      f31: if(s.error) false else s.f31,
      sourceA: if(s.error) s.sourceA else false,
      sourceB: if(s.error) s.sourceB else false,
      f45: if(s.error) s.f45 else false, f94: if(s.error) s.f94 else false } }
  action restoreThreadOnAbort = all { s.error, s.f92 == 1,
    (s.common and s.h == 5 and s.he == s.epoch and s.round == 3 and s.lastGC == gcKey and s.gcPhase == 0) or s.policy == 34,
    s' = { ...s, f92: 3, f83: 0, f85: false, rr: 1, h: 6 } }
  val helperDone = if(s.error) s.h == 6 else s.h == 4
  action leaveP0 = all { s.common, not(s.left0), (helperDone and s.bg == 5) or s.policy == 39 or (s.policy == 48 and helperDone), s' = { ...s, left0: true } }
  action leaveA = all { s.common, not(s.leftA), helperDone, s.bg == 5, s' = { ...s, leftA: true } }
  action leaveB = all { s.common, not(s.leftB), helperDone, s.bg == 5, s' = { ...s, leftB: true } }
  // Last read from traced storage; no collective GC until caller installation.
  // The existing c-lambda normal-return bridge is such a cooperative no-GC path.
  action consumeResult = all { s.common, allLeft, s.f73 == 0,
    s' = { ...s, f73: 1,
      f74: if(s.policy == 24) s.version - 1 else if(s.error) s.f43 else s.version } }
  action releaseResult = all { s.f73 == 1, s.f39 or s.f42,
    s' = { ...s, f73: 2, f39: false, f42: false } }
  action gcInGap = all { s.policy == 23, s.f73 == 2, not(s.f80),
    s' = { ...s, f80: true } }
  action installCallerRoot = all { s.f73 == 2,
    s' = { ...s, f73: 3, f44: true,
      f75: s.f79 <= 1, f76: s.f74 } }
  // Relocation discriminator after caller installation, not a third full GC protocol.
  action checkCallerRelocation = all { s.f73 == 3, not(s.f77),
    s' = { ...s, f77: true,
      f76: if(s.f75) s.version + 1 else s.f76,
      f74: s.f74, version: s.version + 1,
      f29: if(s.sourceA) s.version + 1 else s.f29,
      f30: if(s.sourceB) s.version + 1 else s.f30,
      f33: if(s.f31) s.version + 1 else s.f33,
      f34: if(s.f32) s.version + 1 else s.f34 } }
  action serviceYAfterAbort = all { s.phase == 3, s.resumed, resultReleased,
    s.yAlive, s.yCalls == 0,
    s' = { ...s, yAlive: false, yCalls: 1, totalY: s.totalY + 1 } }
  action nextEpoch = all { s.common, s.epoch == 1, not(s.f59),
    (resultReleased and allLeft and s.yCalls == 1) or s.policy == 14,
    s' = { ...s, phase: 0,
      f63: not(resultReleased and allLeft and s.yCalls == 1) } }
  val terminal = s.common and resultReleased and allLeft and
    (s.f59 or (s.epoch == 2 and s.yCalls == 1))
  action done = all { terminal, s' = s }
  action step = any { openEpoch, rootBridge, makeBridgeMarker, helperThrows, matchCaughtReturn, cleanupBridgeError, skipCaughtCleanup, rawUnwindResume, returnBridge, closeBridge, badPublicEntry, badNestedResize, badMarkerKill, yieldCapture, reenterPreparation, yieldCompletion, requestHelperGC, earlyPublication, republish, closeDonorScheduling, saveDonorThread, publishThreadAnchor, freeStackEarly, startA, readyA, popAndStartB, requestGC1,
    outcomeB, requestGC2, arriveP0, arriveA, arriveB, markStrong, materializeCapturedFrames, determineWill,
    finishGC, publishWeakWork, dequeueLastWork, scanPrivateChunk, returnPrivateScan, returnScanner, tailP0, tailA, tailB, completeGCReturn,
    cancelYOnSuccess, settlePreparation, spliceStillRC, handoffFrameValues, publishRunnableOnReceiver, f93, handoffWillLists, prepareHandoff, lateProducer, earlyReturn,
    releaseErrorEarly, replayX, decide, ackP0, ackA, ackB, commonCompletion, restoreThreadOnAbort,
    leaveP0, leaveA, leaveB, consumeResult, releaseResult, gcInGap, installCallerRoot, checkCallerRelocation, serviceYAfterAbort, nextEpoch, done }
  val strongCoverage = ((s.sourceA and s.cohort == 3 and s.frameA and s.f29 == s.version) or
      (s.f31 and s.f33 == s.version)) and
    ((s.sourceB and s.cohort == 3 and s.frameB and s.f30 == s.version) or
      (s.f32 and s.f34 == s.version))
  val resultCoverage = (s.phase == 0 or s.f44 or s.f73 == 2 or
      (s.f39 and s.f35 and s.f40 == s.version)) and
    (not(s.error) or not(s.movable) or
      ((s.f42 and s.f35 and s.f43 == s.version) or
       (s.f73 >= 1 and s.f73 <= 2 and not(s.f80) and s.f74 == s.version) or
       (s.f75 and s.f76 == s.version)))
  val transferCoverage = s.cohort == 3 or (s.f71 and s.f46 and s.f38 and (s.f92 == 1 or s.f92 == 2))
  val workSafety = (s.gcPhase != 6 or workClosed) and (not(s.f51) or (s.f82 and (s.common or workClosed))) and not(s.f70)
  val framesCovered = s.cohort == 3 and s.frameA and s.frameB or s.f38
  val weakSemantics = ((s.f45 and s.cohort == 3) or s.f46) and (not(s.f49) or (s.f47 and s.f50))
  val serving = s.common or (s.cohort == 3 and not(s.left0) and not(s.leftA) and not(s.leftB))
  val closedDecision = s.phase != 2 or (s.f51 and s.lastGC == s.epoch * 10 + 2)
  val queueSafe = s.aCalls <= 1 and s.bCalls <= 1 and s.yCalls <= 1 and not(s.xQueued) and not(s.f15) and
    (not(s.resumed) or (not(s.f18) and s.f17 == 1))
  val savedFrameOwnership = (s.f83 != 1 or s.f94) and
    (not(s.f38) or (s.f83 == 2 and s.f85 and s.f86 and s.f91 == s.lastGC)) and
    not(s.f93)
  val protocol = s.pc <= 1 and (s.pc == 0 or (s.common and not(s.error))) and
    (s.rr == 0 or (s.common and s.error)) and
    (s.h < 3 or s.he == s.epoch) and not(s.blocked) and
    (s.f92 != 1 or s.f85 or not(s.f84)) and
    (not(s.left0) or helperDone) and
    (s.h != 3 or (s.cohort == 1 and s.f92 == 1 and s.f85)) and
    (s.h != 5 or (s.cohort == 3 and s.f92 == 1 and s.f85))
  val bridgeSafe = s.fault == 0 and s.gv and
    (s.bg == 0 or s.ctx) and
    (s.bg < 1 or s.bg > 4 or (s.roots and s.bv == s.version)) and
    (s.bg < 2 or s.bg > 4 or s.mk) and
    (not(s.left0) or s.bg == 5)
  val safe = bridgeSafe and protocol and savedFrameOwnership and strongCoverage and resultCoverage and transferCoverage and workSafety and
    (not(s.f38) or s.f72) and framesCovered and weakSemantics and serving and
    closedDecision and queueSafe and not(s.staleGC) and not(s.f56) and not(s.f63)
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
}
