module retirement_exit_landing {
  // Single transition system: P0+A+B, two GC rounds per z2, two epochs.
  // mode 0 abort/abort; 1 abort/success; 2 invalid suffix -> opaque containment.
  // Mutation policies are enumerated in the accompanying source contract.
  // Packed bounded record; arithmetic is exact in Quint/TLC. No native encoding is proposed.
  pure def exitSetDigit(v: int,w: int,b: int,n: int): int = v + (n - ((v / w) % b)) * w
  pure def e0(v: int): int = ((v / 1) % 8)
  pure def e1(v: int): int = ((v / 8) % 16)
  pure def e2(v: int): int = ((v / 128) % 2)
  pure def e3(v: int): int = ((v / 256) % 4)
  pure def e4(v: int): int = ((v / 1024) % 4)
  pure def e5(v: int): bool = ((v / 4096) % 2) == 1
  pure def e6(v: int): bool = ((v / 8192) % 2) == 1
  pure def e7(v: int): bool = ((v / 16384) % 2) == 1
  pure def e8(v: int): int = ((v / 32768) % 64)
  pure def e9(v: int): int = ((v / 2097152) % 4)
  pure def e10(v: int): bool = ((v / 8388608) % 2) == 1
  pure def e11(v: int): bool = ((v / 16777216) % 2) == 1
  pure def e12(v: int): int = ((v / 33554432) % 8)
  pure def e13(v: int): int = ((v / 268435456) % 8)
  pure def e14(v: int): int = ((v / 2147483648) % 4)
  pure def e15(v: int): int = ((v / 8589934592) % 4)
  pure def e16(v: int): int = ((v / 34359738368) % 128)
  pure def exitPack(em: int): int = em + (if(em == 6) 268435584 else 0) + 28672 + (if(em == 7) 0 else 33554432)
  type State = { z0: int, mode: int, z2: int, z3: int, z4: int,
    a: int, b: int, z7: int, z8: int, z9: int,
    z10: int, z11: int, z12: int,
    z13: bool, z14: bool, f15: bool,
    z16: bool, f17: int, f18: bool,
    z19: int, z20: int, z21: int, z22: int,
    f23: int, f24: int, f25: int, z26: bool,
    z27: bool, z28: bool, f29: int, f30: int,
    f31: bool, f32: bool, f33: int, f34: int,
    f35: bool, z36: bool, z37: bool, f38: bool,
    f39: bool, f40: int,
    z41: bool, f42: bool, f43: int, f44: bool,
    f45: bool, f46: bool, f47: bool, f48: bool,
    f49: bool, f50: bool,
    f51: bool, z52: bool, ack0: int, ackA: int, ackB: int,
    f56: bool, z57: bool, z58: bool, f59: bool,
    z60: bool, z61: bool, z62: bool, f63: bool,
    f64: bool, f65: bool, f66: bool,
    z67: int, z68: int, z69: int, f70: bool, f71: bool,
    f72: bool, f73: int, f74: int, f75: bool,
    f76: int, f77: bool, z78: bool, f79: int, f80: bool,
    f81: bool, f82: bool, f83: int,
    f84: bool, f85: bool, f86: bool, f87: bool, f88: bool,
    f89: bool, f90: bool, f91: int, f92: int,
    f93: bool, f94: bool, h: int, he: int, pc: int, rr: int, z99: bool, bg: int, z101: bool, ctx: bool, mk: bool, gv: bool, bv: int, z106: int, bf: int, z108: int, z109: int, sd: int, boot: int, reg: int, slot: bool, z114: bool, pin: bool, cpu: int, z117: bool, z118: bool, q: bool, z120: bool, dead: bool, xs: int }
  var s: State
  pure def initial(z0: int, mode: int, em: int): State = {
    z0: z0, mode: mode, z2: 0, z3: 0, z4: 3,
    a: 0, b: 0, z7: 0, z8: 0, z9: 0,
    z10: 0, z11: 0, z12: 0,
    z13: false, z14: false, f15: false,
    z16: false, f17: 0, f18: false,
    z19: 0, z20: 0, z21: 0, z22: 0,
    f23: 0, f24: 0, f25: 0, z26: false,
    z27: true, z28: true, f29: 0, f30: 0,
    f31: false, f32: false, f33: -1, f34: -1,
    f35: true, z36: true, z37: true, f38: false,
    f39: false, f40: 0,
    z41: false, f42: false, f43: -1, f44: false,
    f45: true, f46: false, f47: false, f48: false,
    f49: false, f50: false,
    f51: false, z52: false, ack0: 0, ackA: 0, ackB: 0,
    f56: false, z57: false, z58: false, f59: false,
    z60: false, z61: false, z62: false, f63: false,
    f64: false, f65: false, f66: false,
    z67: 0, z68: 0, z69: 0, f70: false, f71: false,
    f72: true, f73: 0, f74: -1, f75: false,
    f76: -1, f77: false, z78: true, f79: 0, f80: false,
    f81: false, f82: false, f83: 0,
    f84: false, f85: false, f86: true, f87: false, f88: false,
    f89: false, f90: false, f91: 0, f92: 0,
    f93: false, f94: true, h: 0, he: 0, pc: 0, rr: 0, z99: false, bg: 0, z101: false, ctx: true, mk: false, gv: true, bv: 0, z106: 0, bf: 0, z108: 0, z109: 0, sd: 0, boot: 0, reg: 0, slot: false, z114: true, pin: false, cpu: 0, z117: true, z118: false, q: false, z120: true, dead: false, xs: exitPack(em) }
  action initAbortTwice = s' = initial(0,0,0)
  action initAbortThenCommit = s' = initial(0,1,0)
  action initOpaqueSuffix = s' = initial(0,2,0)
  action initEarlyReturn = s' = initial(1,0,0)
  action initEarlySourceDrop = s' = initial(2,0,0)
  action initStaleGCRound = s' = initial(3,0,0)
  action initStaleGCEpoch = s' = initial(4,0,0)
  action initStaleAbortEpoch = s' = initial(5,0,0)
  action initEarlyErrorRelease = s' = initial(6,0,0)
  action initReplay = s' = initial(7,0,0)
  action initDeadSuffixResume = s' = initial(8,2,0)
  action initStrongifyWeak = s' = initial(9,0,0)
  action initWithdrawFrame = s' = initial(10,0,0)
  action initDropWillOwner = s' = initial(11,0,0)
  action initEarlyDecision = s' = initial(12,0,0)
  action initStaleCursor = s' = initial(13,0,0)
  action initPrematureReuse = s' = initial(14,0,0)
  action initUnscannedPayload = s' = initial(15,0,0)
  action initMissingHandoff = s' = initial(17,1,0)
  action initFreedNodeAccess = s' = initial(16,0,0)
  action initImmediateErrors = s' = { ...initial(0,0,0), z78: false }
  action initRegisteredCCaller = s' = { ...initial(0,0,0), f79: 1 }
  action initScanStillActive = s' = initial(18,0,0)
  action initSkippedGCTail = s' = initial(19,0,0)
  action initLateWorkProducer = s' = initial(20,1,0)
  action initMissingStillRC = s' = initial(21,1,0)
  action initLiveNativeOrigin = s' = { ...initial(22,1,0), f72: false }
  action initGCInReturnGap = s' = initial(23,0,0)
  action initStaleReturnCopy = s' = initial(24,0,0)
  action initUnregisteredCCaller = s' = { ...initial(25,0,0), f79: 2 }
  action initCatcherOnly = s' = { ...initial(26,0,0), f79: 3 }
  action initSkipPrivateChunk = s' = initial(27,1,0)
  action initRawStackInRC = s' = initial(28,1,0)
  action initLostThreadAnchor = s' = initial(29,1,0)
  action initDuplicateRunnable = s' = initial(30,1,0)
  action initUnsealedScheduling = s' = initial(31,1,0)
  action initFreedStackBeforeCopy = s' = initial(32,1,0)
  action initEarlyPublication = s' = initial(33,1,0)
  action initEarlyRestore = s' = initial(34,1,0)
  action initUnrootedPark = s' = initial(35,1,0)
  action initStaleHelper = s' = initial(36,1,0)
  action initHelperStopsGC = s' = initial(37,1,0)
  action initRepublish = s' = initial(38,1,0)
  action initEarlyAPIReturn = s' = initial(39,1,0)
  action initDirectCPrepared = s' = { ...initial(0,1,0), z109: 1, f79: 1 }
  action initMarkerFailureRetry = s' = { ...initial(0,1,0), bf: 1 }
  action initCaughtSchemeRetry = s' = { ...initial(0,1,0), bf: 2 }
  action initMissingBridgeRoots = s' = { ...initial(40,1,0), z109: 0, bf: 0 }
  action initPublicSFUNClosedGate = s' = { ...initial(41,1,0), z109: 0, bf: 0 }
  action initReopenedBridgeGate = s' = { ...initial(42,1,0), z109: 0, bf: 0 }
  action initRunClobber = s' = { ...initial(43,1,0), z109: 0, bf: 0 }
  action initWrongReturnMarker = s' = { ...initial(44,1,0), z109: 0, bf: 0 }
  action initNestedResizeInHelper = s' = { ...initial(45,1,0), z109: 0, bf: 0 }
  action initEarlyMarkerKill = s' = { ...initial(46,1,0), z109: 0, bf: 0 }
  action initStaleBridgeResult = s' = { ...initial(47,1,0), z109: 0, bf: 0 }
  action initEarlyBridgeReturn = s' = { ...initial(48,1,0), z109: 0, bf: 0 }
  action initThrowSkipsCleanup = s' = { ...initial(49,1,0), z109: 0, bf: 2 }
  action initDirectCWrongContext = s' = { ...initial(50,1,0), z109: 2, bf: 0 }
  action initRawUnwindResume = s' = initial(51,1,0)
  action initShutdownPrepared = s' = { ...initial(0,1,0), sd: 1, z109: 1, f79: 1 }
  action initRawShutdownRetained = s' = { ...initial(0,1,0), sd: 2, z114: false }
  action initRawHelperRetained = s' = { ...initial(0,1,0), bf: 3 }
  action initSetupFlagOnly = s' = { ...initial(52,1,0) }
  action initUnregisteredHelper = s' = { ...initial(53,1,0) }
  action initStaleHelperRegistration = s' = { ...initial(54,1,0) }
  action initMissingPin = s' = { ...initial(55,1,0) }
  action initExplicitMigrationWhilePinned = s' = { ...initial(56,1,0) }
  action initRawShutdownEntry = s' = { ...initial(57,1,0), sd: 2, z114: false }
  action initRetainedTeardown = s' = { ...initial(58,1,0), sd: 2, z114: false }
  action initRetainedGC = s' = { ...initial(59,1,0), sd: 2, z114: false }
  action initLostRetainedRoots = s' = { ...initial(60,1,0), sd: 2, z114: false }
  action initClearHelperTooEarly = s' = { ...initial(61,1,0) }
  action initOSStopKillsSync = s' = { ...initial(62,1,0), sd: 1 }
  action initTeardownBeforeReturn = s' = { ...initial(63,1,0) }
  action initP0Exit = s' = initial(0,1,1)
  action initWorkerExit = s' = initial(0,1,6)
  action initJobFailure = s' = initial(0,1,2)
  action initWillFailure = s' = initial(0,1,3)
  action initRepeatedExit = s' = initial(0,1,4)
  action initAbruptExit = s' = initial(0,1,5)
  action initRunAllocationFailure = s' = initial(0,1,7)
  action initWorkerThrowsEarly = s' = initial(64,1,6)
  action initLostJobSuffix = s' = initial(65,1,1)
  action initReplayFailedJob = s' = initial(66,1,2)
  action initReplayConsumedWill = s' = initial(67,1,3)
  action initRecursiveCleanup = s' = initial(68,1,4)
  action initEarlyHostExit = s' = initial(69,1,1)
  action initMissingRunFinalizer = s' = initial(70,1,1)
  action initDoubleRunKill = s' = initial(71,1,1)
  action initKillUnallocatedRun = s' = initial(72,1,7)
  action initLostExitErrorRoot = s' = initial(73,1,3)
  action initKillReturnableRun = s' = initial(74,1,1)
  action initWorkerExitBeforeFinalizer = s' = initial(75,1,6)
  action initCleanupFailureSkipsLanding = s' = initial(76,1,2)
  action initReplacePrimaryExit = s' = initial(77,1,4)
  val shouldFail = s.z2 == 1 or s.mode != 1
  val gcKey = s.z2 * 10 + s.z19
  val allArrived = s.f23 == gcKey and (s.z4 == 1 or (s.f24 == gcKey and s.f25 == gcKey))
  val allAcked = s.ack0 == s.z2 and s.ackA == s.z2 and s.ackB == s.z2
  val tailsReturned = s.z67 == gcKey and (s.z4 == 1 or (s.z68 == gcKey and s.z69 == gcKey))
  val workClosed = not(s.f64) and not(s.f65) and not(s.f66) and
    not(s.f89) and not(s.f90) and not(s.f88)
  val resultReleased = s.f44 and not(s.f39) and not(s.f42) and s.f77
  val allLeft = s.z60 and s.z61 and s.z62
  // Registration and ready publication are separate from setup_state.
  action registerKernelHelper = all { s.z3 == 0, s.boot == 0,
    s' = { ...s, boot: 1 } }
  action publishVMHelper = all { s.z3 == 0, s.boot == 1,
    s' = { ...s, boot: 2, slot: s.z0 != 53, reg: if(s.z0 == 54) 0 else 1 } }
  action stopOSNotifications = all { s.sd > 0, s.z3 == 0, not(s.z118),
    s' = { ...s, z118: true, z117: s.z0 != 62 } }
  action retainUnsafeShutdown = all { s.sd == 2, not(s.z114), s.z3 == 0,
    s' = { ...s, q: true, z101: true, ctx: false, bg: 7, z120: true } }
  action rawHelperUnwind = all { s.bf == 3, s.bg == 3, s.z19 == 2, s.z20 == 0,
    s' = { ...s, q: true, ctx: false, bg: 7, z120: true } }
  action explicitHelperMigration = all { s.z0 == 56, s.bg == 3,
    s' = { ...s, cpu: 1 } }
  action clearHelperEarly = all { s.z0 == 61, s.bg == 3, s.slot,
    s' = { ...s, slot: false } }
  action teardownBeforeReturn = all { s.z0 == 63, s.bg == 3,
    s' = { ...s, dead: true } }
  action badRetainedTeardown = all { s.q, s.z0 == 58, s' = { ...s, dead: true } }
  action badRetainedGC = all { s.q, s.z0 == 59, s' = { ...s, z20: 1 } }
  action badRetainedRootDrop = all { s.q, s.z0 == 60, s' = { ...s, z120: false } }
  action exitRequest = all { e0(s.xs) > 0, e0(s.xs) != 7, e1(s.xs) == 0,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(exitSetDigit(s.xs,8,16,(1)),34359738368,128,(42)),32768,64,(s.z22)) } }
  // Worker matched host-return/finalization precedes its C-only exit intent offer.
  action workerRunBoundary = all { e2(s.xs) == 1, e1(s.xs) == 1, e13(s.xs) == 1,
    s' = { ...s, xs: exitSetDigit(s.xs,268435456,8,(4)) } }
  action claimExitP0 = all { e1(s.xs) == 1, e2(s.xs) == 0 or e13(s.xs) == 4,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(s.xs,8,16,(if(e0(s.xs) == 5) 6 else 2)),8589934592,4,(1)) } }
  action startExitJob = all { e1(s.xs) == 2,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(exitSetDigit(s.xs,8,16,(3)),256,4,(1)),2097152,4,(0)) } }
  action requestExitGC = all { s.z3 == 0, (e1(s.xs) == 3 or e1(s.xs) == 5), e9(s.xs) == 0,
    s' = { ...s, z19: if(e1(s.xs) == 3) 1 else 2, z20: 1, f64: true, f66: true, f87: true, xs: exitSetDigit(s.xs,2097152,4,(1)) } }
  action finishExitJob = all { e1(s.xs) == 3, e9(s.xs) == 2, s.z20 == 0,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(exitSetDigit(s.xs,8,16,(if(e0(s.xs) == 2 or e0(s.xs) == 4) 6 else 4)),8388608,2,if(e0(s.xs) == 4) 1 else 0),32768,64,(s.z22)) } }
  action startExitWill = all { e1(s.xs) == 4,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(exitSetDigit(s.xs,8,16,(5)),1024,4,(1)),2097152,4,(0)) } }
  action finishExitWill = all { e1(s.xs) == 5, e9(s.xs) == 2, s.z20 == 0,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(s.xs,8,16,(6)),32768,64,(s.z22)) } }
  action enterLanding = all { e1(s.xs) == 6, s.z20 == 0, workClosed,
    s' = { ...s, xs: exitSetDigit(s.xs,8,16,(7)) } }
  action permitExit = all { e1(s.xs) == 7, normalTerminal, not(s.z41), s.pc == 1,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(s.xs,8,16,(8)),16777216,2,if(true) 1 else 0) } }
  // Native host invocation is now nonreturnable; catcher has returned to its C boundary.
  action hostRunUnwinds = all { e1(s.xs) == 8, e12(s.xs) == 1,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(s.xs,8,16,(9)),33554432,8,(3)) } }
  action finalizeRunMarker = all { e1(s.xs) == 9, e12(s.xs) == 3,
    s' = { ...s, xs: exitSetDigit(exitSetDigit(exitSetDigit(s.xs,8,16,(10)),33554432,8,(4)),2147483648,4,(1)) } }
  action finalizeUnallocatedRun = all { e0(s.xs) == 7, e1(s.xs) == 0,
    s' = { ...s, q: true, z101: true, ctx: false, bg: 7, xs: exitSetDigit(exitSetDigit(exitSetDigit(s.xs,8,16,(10)),33554432,8,(4)),2147483648,4,(0)) } }
  action exitFaults = any {
    all { s.z0 == 77, e1(s.xs) == 3, s' = { ...s, xs: exitSetDigit(s.xs,34359738368,128,(99)) } },
    all { s.z0 == 64, e1(s.xs) == 1, s' = { ...s, xs: exitSetDigit(s.xs,16777216,2,if(true) 1 else 0) } },
    all { s.z0 == 65, e1(s.xs) == 3, s' = { ...s, xs: exitSetDigit(s.xs,4096,2,if(false) 1 else 0) } },
    all { s.z0 == 66, e1(s.xs) == 6, s' = { ...s, xs: exitSetDigit(s.xs,256,4,(2)) } },
    all { s.z0 == 67, e1(s.xs) == 6, s' = { ...s, xs: exitSetDigit(s.xs,1024,4,(2)) } },
    all { s.z0 == 68, e1(s.xs) == 3, s' = { ...s, xs: exitSetDigit(s.xs,8589934592,4,(2)) } },
    all { s.z0 == 69, e1(s.xs) == 6, s' = { ...s, xs: exitSetDigit(s.xs,16777216,2,if(true) 1 else 0) } },
    all { s.z0 == 70, e1(s.xs) == 9, s' = { ...s, xs: exitSetDigit(s.xs,8,16,(10)) } },
    all { s.z0 == 71, e12(s.xs) == 4, s' = { ...s, xs: exitSetDigit(s.xs,2147483648,4,(2)) } },
    all { s.z0 == 72, e12(s.xs) == 0, s' = { ...s, xs: exitSetDigit(s.xs,2147483648,4,(1)) } },
    all { s.z0 == 73, e1(s.xs) == 6, s' = { ...s, xs: exitSetDigit(s.xs,16384,2,if(false) 1 else 0) } },
    all { s.z0 == 74, e12(s.xs) == 1, s' = { ...s, xs: exitSetDigit(exitSetDigit(s.xs,33554432,8,(4)),2147483648,4,(1)) } },
    all { s.z0 == 75, e1(s.xs) == 1, s' = { ...s, xs: exitSetDigit(s.xs,268435456,8,(3)) } },
    all { s.z0 == 76, e1(s.xs) == 6, s' = { ...s, xs: exitSetDigit(s.xs,16777216,2,if(true) 1 else 0) } }
  }
  action openEpoch = all { s.z3 == 0, s.z2 < 2, e0(s.xs) == 0 or e1(s.xs) == 7,
    (s.boot == 2 and (s.z114 or s.z0 == 57)) or s.z0 == 52,
    s.sd == 0 or s.z118 or s.z0 == 57,
    s' = { ...initial(s.z0,s.mode,0), xs: s.xs, bf: s.bf, z109: s.z109, sd: s.sd, boot: s.boot, reg: s.reg, slot: s.slot, z114: s.z114, z117: s.z117, z118: s.z118, z2: s.z2 + 1, z3: 1, z8: if(s.z0 == 13 and s.z2 == 1) s.z8 else 0, z16: true, f29: s.z22, f30: s.z22, f35: s.z0 != 15, z36: s.z0 != 10, f39: true, f40: s.z22, f45: s.z0 != 11, z99: false, z4: s.z4, z10: s.z10, z11: s.z11, z12: s.z12, z22: s.z22, f23: s.f23, f24: s.f24, f25: s.f25, z26: s.z26, ack0: s.ack0, ackA: s.ackA, ackB: s.ackB, f56: s.f56, f63: s.f63, z67: s.z67, z68: s.z68, z69: s.z69, f70: s.f70, f72: s.f72, z78: s.z78, f79: s.f79 } }
  // h: 0 C service, 1 Scheme capture, 2 C preparation,
  // 3 survivor Scheme activation, 4 activation complete,
  // 5 origin Scheme rollback, 6 rollback complete. he authenticates the helper z2.
  action yieldCapture = all { s.z3 == 1, s.h == 0,
    s' = { ...s, h: 1, he: s.z2 } }
  action reenterPreparation = all { s.h == 1, s.f84,
    s' = { ...s, h: 2 } }
  // bg: 0 none/retry, 1 rooted context, 2 marker, 3 Scheme call,
  // 4 matching C return, 5 finalized bridge, 6 caught z109/helper z41.
  action rootBridge = all { s.z57, s.bg == 0, s.h >= 2,
    s' = { ...s, bg: 1, z101: s.z0 != 40, ctx: s.z0 != 43 and s.z109 != 2, pin: s.z0 != 55,
      gv: s.z0 != 42, bv: s.z22 } }
  action makeBridgeMarker = all { s.bg == 1,
    s' = { ...s, bg: if(s.bf == 1 and s.z108 == 0) 6 else 2,
      mk: not(s.bf == 1 and s.z108 == 0) } }
  action yieldCompletion = all { s.z57, s.bg == 2,
    s' = { ...s, bg: 3, h: if(s.z41) 5 else 3,
      he: if(s.z0 == 36) s.z2 - 1 else s.z2,
      f85: s.z0 != 35 and s.f85 } }
  action helperThrows = all { s.bg == 3, s.bf == 2, s.z108 == 0, s.z19 == 2,
    s' = { ...s, bg: 6 } }
  // Scheme caught-status still returns through the matching return-to-C frame.
  action matchCaughtReturn = all { s.bg == 6, s.mk, s.bf == 2,
    s' = { ...s, bg: 4 } }
  action cleanupBridgeError = all { (s.bg == 6 and not(s.mk)) or
    (s.bg == 4 and s.bf == 2 and not(helperDone)),
    s' = { ...s, bg: 0, mk: false, z108: 1 } }
  action skipCaughtCleanup = all { s.bg == 6, s.z0 == 49,
    s' = { ...s, bg: 5, z106: 3 } }
  action rawUnwindResume = all { s.bg == 3, s.z0 == 51,
    s' = { ...s, bg: 6, ctx: false } }
  action returnBridge = all { s.bg == 3, helperDone, s.z20 == 0,
    s' = { ...s, bg: 4, z106: if(s.z0 == 44) 2 else s.z106,
      bv: if(s.z0 == 47) s.z22 - 1 else s.bv } }
  action closeBridge = all { s.bg == 4, helperDone,
    s' = { ...s, bg: 5, mk: false, z101: false } }
  action badPublicEntry = all { s.bg == 1, s.z0 == 41,
    s' = { ...s, z106: 1 } }
  action badNestedResize = all { s.bg == 3, s.z0 == 45,
    s' = { ...s, z106: 4 } }
  action badMarkerKill = all { s.bg == 3, s.z0 == 46, s.mk,
    s' = { ...s, mk: false } }
  action requestHelperGC = all { s.z57, s.bg == 3, s.bf != 3, (s.bf != 2 or s.z108 == 1), (s.h == 3 or s.h == 5), s.z19 == 2,
    s' = { ...s, z19: 3, z20: 1, f64: true, f66: true,
      z99: s.z0 == 37 } }
  action earlyPublication = all { s.z0 == 33, s.z3 == 1, s.f92 == 1,
    s' = { ...s, pc: 1, f92: 2 } }
  action republish = all { s.z0 == 38, s.pc == 1,
    s' = { ...s, pc: 2 } }
  // Scheme safe-point operations, not raw copies of a C activation.
  action closeDonorScheduling = all { s.z3 == 1, not(s.f81),
    s' = { ...s, f81: true, f82: s.z0 != 31 } }
  action saveDonorThread = all { s.z3 == 1, s.h == 1, s.f81, s.f83 == 0,
    s' = { ...s, f83: 1, f92: 1 } }
  action publishThreadAnchor = all { s.z3 == 1, s.f83 == 1, not(s.f84),
    // Policy 29 marks the publication z108 complete without a reachable anchor.
    s' = { ...s, f84: true, f85: s.z0 != 29, f86: s.z0 != 28 } }
  action freeStackEarly = all { s.z0 == 32, s.f83 == 1, s.f94,
    s' = { ...s, f94: false } }
  action startA = all { s.z3 == 1, s.h == 2, s.a == 0,
    s' = { ...s, a: 1, z7: s.z7 + 1, z10: s.z10 + 1 } }
  action readyA = all { s.z3 == 1, s.a == 1, s.z20 == 0,
    s' = { ...s, a: 2, f31: true, f33: s.z22,
      z27: s.z0 != 2 } }
  // Atomic one-node pop under existing mutex, then unlocked callback.
  // Y remains queue-owned and never invoked during a failed preparation.
  action popAndStartB = all { s.z3 == 1, s.h == 2, s.b == 0,
    s' = { ...s, b: 1, z8: s.z8 + 1, z11: s.z11 + 1 } }
  action requestGC1 = all { s.z3 == 1, s.b == 1, s.z19 == 0, s.f83 == 1, s.f84,
    s' = { ...s, z19: 1, z20: 1, f64: true, f66: true } }
  action outcomeB = all { s.z3 == 1, s.b == 1, s.a == 2,
    s.z21 == s.z2 * 10 + 1, s.z20 == 0,
    s' = { ...s, b: if(shouldFail) 3 else 2, z13: true,
      z41: shouldFail, f42: shouldFail, f43: if(shouldFail) s.z22 else -1,
      z16: s.mode != 2, f18: s.mode == 2,
      f15: s.z0 == 16 } }
  action requestGC2 = all { s.z3 == 1, s.b >= 2, s.z19 == 1, s.z20 == 0,
    s' = { ...s, z19: 2, z20: 1, f64: true, f66: true } }
  action arriveP0 = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 1, not(s.z99), not(s.z60), s.f23 != gcKey,
    s' = { ...s, f23: gcKey } }
  action arriveA = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 1, s.z4 == 3, not(s.z61), s.f24 != gcKey,
    s' = { ...s, f24: gcKey } }
  action arriveB = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 1, s.z4 == 3, not(s.z62), s.f25 != gcKey,
    s' = { ...s, f25: gcKey } }
  // Strong z101 first. The GC key contains both z2 and within-z2 z19.
  action markStrong = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 1,
    allArrived or
      (s.z0 == 3 and s.z19 == 2 and s.f23 >= s.z2 * 10 + 1 and s.f24 >= s.z2 * 10 + 1 and s.f25 >= s.z2 * 10 + 1) or
      (s.z0 == 4 and s.z2 == 2 and s.f23 > 0 and s.f24 > 0 and s.f25 > 0),
    s' = { ...s, z20: 2, f65: true, f64: false, z26: s.z26 or not(allArrived), z22: s.z22 + 1, bv: if(s.z101) s.z22 + 1 else s.bv, f29: if(s.z27 and s.z36) s.z22 + 1 else s.f29, f30: if(s.z28 and s.z37) s.z22 + 1 else s.f30, f33: if(s.f31) s.z22 + 1 else s.f33, f34: if(s.f32) s.z22 + 1 else s.f34, f40: if(s.f39 and s.f35) s.z22 + 1 else s.f40, f43: if(s.f42 and s.f35) s.z22 + 1 else s.f43, f47: (s.f45 or s.f46), f48: s.z0 == 9, xs: exitSetDigit(s.xs,32768,64,(if(e7(s.xs)) s.z22 + 1 else e8(s.xs))) } }
  // Special continuation scanning, reached through actual thread/cont object.
  // An immediate-looking raw stack address in generic RC data does not take this path.
  action materializeCapturedFrames = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 2,
    s.f83 == 1, not(s.f87),
    s' = { ...s, f87: true,
      f83: if(s.f85 and s.f86) 2 else 1,
      f88: true, f89: true } }
  action determineWill = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 2, s.f87,
    s' = { ...s, z20: 3, f49: true,
      f50: s.f50 or ((s.f45 or s.f46) and not(s.f48)) } }
  // process_wills/marking may publish additional work. Empty FIFO != scan return.
  action publishWeakWork = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 3,
    s' = { ...s, z20: 4, f64: true, f66: false } }
  action dequeueLastWork = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 4, s.f64,
    s' = { ...s, f64: false } }
  // scan_movable_objs also scans the donor's incomplete allocation chunk.
  action scanPrivateChunk = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 4,
    s.f89, not(s.f90),
    s' = { ...s, f90: true } }
  action returnPrivateScan = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 4, s.f90,
    s' = { ...s, f89: false, f90: false, f88: false } }
  action returnScanner = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 4,
    not(s.f64), s.f65,
    (not(s.f89) and not(s.f90) and not(s.f88)) or s.z0 == 27,
    s' = { ...s, z20: 5, f65: false } }
  action finishGC = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)),
    (s.z20 == 5 and (workClosed or s.z0 == 27)) or
      (s.z0 == 18 and s.z20 == 4 and not(s.f64)),
    s' = { ...s, z20: 6, f48: s.f45 } }
  // Full GC epilogue includes fp/hp restoration, not just the weak-z3 barrier.
  action tailP0 = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 6, s.z67 != gcKey,
    s' = { ...s, z67: gcKey } }
  action z68 = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 6, s.z4 == 3, s.z68 != gcKey,
    s' = { ...s, z68: gcKey } }
  action z69 = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 6, s.z4 == 3, s.z69 != gcKey,
    s' = { ...s, z69: gcKey } }
  action completeGCReturn = all { (s.z3 == 1 or s.z3 == 3 or s.z3 == 4 or (s.z3 == 0 and e9(s.xs) == 1)), s.z20 == 6,
    tailsReturned or s.z0 == 19,
    s' = { ...s, z20: 0, z21: gcKey, f91: if(s.f83 == 2 and workClosed) gcKey else s.f91, f70: s.f70 or not(tailsReturned), xs: exitSetDigit(s.xs,2097152,4,(if(s.z3 == 0) 2 else e9(s.xs))) } }
  // Success must discharge Y before the no-future-callback cut.
  action cancelYOnSuccess = all { s.z3 == 1, not(s.z41), s.b == 2,
    s.z21 == s.z2 * 10 + 2, s.z20 == 0, s.z16, s.z9 == 0,
    s' = { ...s, z16: false, z9: 1, z12: s.z12 + 1 } }
  action settlePreparation = all { s.z3 == 1, s.a == 2, s.b >= 2,
    s.z21 == s.z2 * 10 + 2, s.z20 == 0, workClosed, tailsReturned, not(s.f51),
    s.z41 or s.z9 == 1,
    s' = { ...s, f51: true,
      f17: if(not(s.z41)) 3 else if(s.z16 or s.z0 == 8) 1 else 2 } }
  // Abstract typed z52: values/continuations already on supported surviving owners.
  // This is a C refinement premise, NOT raw native frame migration.
  action spliceStillRC = all { s.z3 == 1, s.f51, not(s.z41), not(s.f71),
    s' = { ...s, f71: true, f32: true, f34: s.z22 } }
  action handoffFrameValues = all { s.z3 == 1, s.f51, not(s.z41), not(s.f38),
    s.f72 or s.z0 == 22,
    (s.f83 == 2 and s.f85 and s.f86 and s.f91 == gcKey) or s.z0 == 28 or s.z0 == 29,
    s' = { ...s, f38: true } }
  action publishRunnableOnReceiver = all { s.z3 == 4, s.h == 3, s.he == s.z2,
    s.z21 == gcKey, s.z19 == 3, s.z20 == 0, workClosed,
    s.f38, s.f92 == 1, s.pc == 0,
    s' = { ...s, f92: 2, pc: 1, h: 4 } }
  action f93 = all { s.z0 == 30, s.f92 == 2, not(s.f93),
    s' = { ...s, f93: true } }
  action handoffWillLists = all { s.z3 == 1, s.f51, not(s.z41), not(s.f46),
    s' = { ...s, f46: true } }
  action prepareHandoff = all { s.z3 == 1, s.f51, not(s.z41), not(s.z52),
    (s.f71 or s.z0 == 21), s.f38, s.f92 == 1, s.f46, workClosed,
    s' = { ...s, z52: true, f32: true, f34: s.z22 } }
  action lateProducer = all { s.z0 == 20, s.z3 == 1, s.f51, not(s.f66),
    s' = { ...s, f66: true, f64: true } }
  action earlyReturn = all { s.z0 == 1, s.z3 == 1, s.z41, not(s.z62),
    s' = { ...s, z62: true } }
  action releaseErrorEarly = all { s.z0 == 6, s.f42, not(s.f44),
    s' = { ...s, f42: false } }
  action replayX = all { s.z0 == 7, s.z41, not(s.z14),
    s' = { ...s, z14: true, z8: s.z8 + 1 } }
  action decide = all { s.z3 == 1, s.a == 2, s.b >= 2, s.z20 == 0,
    (s.f51 and (s.z41 or s.z52 or s.z0 == 17)) or s.z0 == 12,
    s' = { ...s, z3: 2 } }
  action ackP0 = all { s.z3 == 2, s.ack0 != s.z2, s' = { ...s, ack0: s.z2 } }
  action ackA = all { s.z3 == 2, s.ackA != s.z2, s' = { ...s, ackA: s.z2 } }
  action ackB = all { s.z3 == 2, s.ackB != s.z2, s' = { ...s, ackB: s.z2 } }
  action commonCompletion = all { s.z3 == 2,
    allAcked or (s.z0 == 5 and s.z2 == 2 and s.ack0 > 0 and s.ackA > 0 and s.ackB > 0),
    s' = { ...s, z3: if(s.z41) 3 else 4, z57: true,
      f56: not(allAcked), z4: if(s.z41) 3 else 1,
      f59: s.z41 and s.f17 == 2,
      z58: s.z41 and s.f17 == 1,
      f31: if(s.z41) false else s.f31,
      z27: if(s.z41) s.z27 else false,
      z28: if(s.z41) s.z28 else false,
      f45: if(s.z41) s.f45 else false, f94: if(s.z41) s.f94 else false } }
  action restoreThreadOnAbort = all { s.z41, s.f92 == 1,
    (s.z57 and s.h == 5 and s.he == s.z2 and s.z19 == 3 and s.z21 == gcKey and s.z20 == 0) or s.z0 == 34,
    s' = { ...s, f92: 3, f83: 0, f85: false, rr: 1, h: 6 } }
  val helperDone = if(s.z41) s.h == 6 else s.h == 4
  action leaveP0 = all { s.z57, not(s.z60), (helperDone and s.bg == 5) or s.z0 == 39 or (s.z0 == 48 and helperDone), s' = { ...s, z60: true } }
  action leaveA = all { s.z57, not(s.z61), helperDone, s.bg == 5, s' = { ...s, z61: true } }
  action leaveB = all { s.z57, not(s.z62), helperDone, s.bg == 5, s' = { ...s, z62: true } }
  // Last read from traced storage; no collective GC until caller installation.
  // The existing c-lambda normal-return bridge is such a cooperative no-GC path.
  action consumeResult = all { s.z57, allLeft, s.f73 == 0,
    s' = { ...s, f73: 1,
      f74: if(s.z0 == 24) s.z22 - 1 else if(s.z41) s.f43 else s.z22 } }
  action releaseResult = all { s.f73 == 1, s.f39 or s.f42,
    s' = { ...s, f73: 2, f39: false, f42: false } }
  action gcInGap = all { s.z0 == 23, s.f73 == 2, not(s.f80),
    s' = { ...s, f80: true } }
  action installCallerRoot = all { s.f73 == 2,
    s' = { ...s, f73: 3, f44: true,
      f75: s.f79 <= 1, f76: s.f74 } }
  // Relocation discriminator after caller installation, not a third full GC protocol.
  action checkCallerRelocation = all { s.f73 == 3, not(s.f77),
    s' = { ...s, f77: true, f76: if(s.f75) s.z22 + 1 else s.f76, f74: s.f74, z22: s.z22 + 1, f29: if(s.z27) s.z22 + 1 else s.f29, f30: if(s.z28) s.z22 + 1 else s.f30, f33: if(s.f31) s.z22 + 1 else s.f33, f34: if(s.f32) s.z22 + 1 else s.f34, xs: exitSetDigit(s.xs,32768,64,(if(e7(s.xs)) s.z22 + 1 else e8(s.xs))) } }
  action serviceYAfterAbort = all { s.z3 == 3, s.z58, resultReleased,
    s.z16, s.z9 == 0,
    s' = { ...s, z16: false, z9: 1, z12: s.z12 + 1 } }
  action nextEpoch = all { s.z57, s.z2 == 1, not(s.f59),
    (resultReleased and allLeft and s.z9 == 1) or s.z0 == 14,
    s' = { ...s, z3: 0,
      f63: not(resultReleased and allLeft and s.z9 == 1) } }
  val normalTerminal = s.z57 and resultReleased and allLeft and
    (s.f59 or (s.z2 == 2 and s.z9 == 1))
  val terminal = (normalTerminal and e0(s.xs) == 0) or s.q or e1(s.xs) == 10
  action done = all { terminal, s' = s }
  action step = if(s.q) any { done, exitFaults, badRetainedTeardown, badRetainedGC, badRetainedRootDrop } else any { exitRequest, workerRunBoundary, claimExitP0, startExitJob, requestExitGC, finishExitJob, startExitWill, finishExitWill, enterLanding, permitExit, hostRunUnwinds, finalizeRunMarker, finalizeUnallocatedRun, exitFaults, registerKernelHelper, publishVMHelper, stopOSNotifications, retainUnsafeShutdown, rawHelperUnwind, explicitHelperMigration, clearHelperEarly, teardownBeforeReturn, openEpoch, rootBridge, makeBridgeMarker, helperThrows, matchCaughtReturn, cleanupBridgeError, skipCaughtCleanup, rawUnwindResume, returnBridge, closeBridge, badPublicEntry, badNestedResize, badMarkerKill, yieldCapture, reenterPreparation, yieldCompletion, requestHelperGC, earlyPublication, republish, closeDonorScheduling, saveDonorThread, publishThreadAnchor, freeStackEarly, startA, readyA, popAndStartB, requestGC1,
    outcomeB, requestGC2, arriveP0, arriveA, arriveB, markStrong, materializeCapturedFrames, determineWill,
    finishGC, publishWeakWork, dequeueLastWork, scanPrivateChunk, returnPrivateScan, returnScanner, tailP0, z68, z69, completeGCReturn,
    cancelYOnSuccess, settlePreparation, spliceStillRC, handoffFrameValues, publishRunnableOnReceiver, f93, handoffWillLists, prepareHandoff, lateProducer, earlyReturn,
    releaseErrorEarly, replayX, decide, ackP0, ackA, ackB, commonCompletion, restoreThreadOnAbort,
    leaveP0, leaveA, leaveB, consumeResult, releaseResult, gcInGap, installCallerRoot, checkCallerRelocation, serviceYAfterAbort, nextEpoch, done }
  val strongCoverage = ((s.z27 and s.z4 == 3 and s.z36 and s.f29 == s.z22) or
      (s.f31 and s.f33 == s.z22)) and
    ((s.z28 and s.z4 == 3 and s.z37 and s.f30 == s.z22) or
      (s.f32 and s.f34 == s.z22))
  val resultCoverage = (s.z3 == 0 or s.f44 or s.f73 == 2 or
      (s.f39 and s.f35 and s.f40 == s.z22)) and
    (not(s.z41) or not(s.z78) or
      ((s.f42 and s.f35 and s.f43 == s.z22) or
       (s.f73 >= 1 and s.f73 <= 2 and not(s.f80) and s.f74 == s.z22) or
       (s.f75 and s.f76 == s.z22)))
  val transferCoverage = s.z4 == 3 or (s.f71 and s.f46 and s.f38 and (s.f92 == 1 or s.f92 == 2))
  val workSafety = (s.z20 != 6 or workClosed) and (not(s.f51) or (s.f82 and (s.z57 or workClosed))) and not(s.f70)
  val framesCovered = s.z4 == 3 and s.z36 and s.z37 or s.f38
  val weakSemantics = ((s.f45 and s.z4 == 3) or s.f46) and (not(s.f49) or (s.f47 and s.f50))
  val serving = s.z57 or (s.z4 == 3 and not(s.z60) and not(s.z61) and not(s.z62))
  val closedDecision = s.z3 != 2 or (s.f51 and s.z21 == s.z2 * 10 + 2)
  val queueSafe = s.z7 <= 1 and s.z8 <= 1 and s.z9 <= 1 and not(s.z14) and not(s.f15) and
    (not(s.z58) or (not(s.f18) and s.f17 == 1))
  val savedFrameOwnership = (s.f83 != 1 or s.f94) and
    (not(s.f38) or (s.f83 == 2 and s.f85 and s.f86 and s.f91 == s.z21)) and
    not(s.f93)
  val protocol = s.pc <= 1 and (s.pc == 0 or (s.z57 and not(s.z41))) and
    (s.rr == 0 or (s.z57 and s.z41)) and
    (s.h < 3 or s.he == s.z2) and not(s.z99) and
    (s.f92 != 1 or s.f85 or not(s.f84)) and
    (not(s.z60) or helperDone) and
    (s.h != 3 or (s.z4 == 1 and s.f92 == 1 and s.f85)) and
    (s.h != 5 or (s.z4 == 3 and s.f92 == 1 and s.f85))
  val bridgeSafe = s.z106 == 0 and s.gv and
    (s.bg == 0 or s.ctx or (s.q and s.bg == 7)) and
    (s.bg < 1 or s.bg > 4 or (s.z101 and s.bv == s.z22)) and
    (s.bg < 2 or s.bg > 4 or s.mk) and
    (not(s.z60) or s.bg == 5)
  val shutdownSafe = not(s.dead) and s.z117 and
    (s.z2 == 0 or (s.boot == 2 and s.slot and s.reg == 1 and s.z114)) and
    (s.bg < 1 or s.bg > 4 or (s.pin and s.cpu == 0)) and
    (not(s.q) or (s.z120 and s.z101 and s.gv and s.z20 == 0 and not(s.z60)))
  val exitSafe = e0(s.xs) == 0 or (
    (e0(s.xs) == 7 or e1(s.xs) == 0 or e16(s.xs) == 42) and
    e3(s.xs) <= 1 and e4(s.xs) <= 1 and e15(s.xs) <= 1 and e5(s.xs) and e6(s.xs) and e7(s.xs) and e8(s.xs) == s.z22 and
    (not(e11(s.xs)) or (e1(s.xs) >= 8 and normalTerminal and not(s.z41))) and
    (e12(s.xs) != 4 or e1(s.xs) == 10) and
    (e1(s.xs) != 10 or (e12(s.xs) == 4 and e14(s.xs) == (if(e0(s.xs) == 7) 0 else 1))) and
    (e12(s.xs) != 0 or e14(s.xs) == 0) and e14(s.xs) <= 1 and
    e13(s.xs) != 3 and (e2(s.xs) == 0 or e1(s.xs) < 2 or e13(s.xs) == 4))
  val safe = exitSafe and shutdownSafe and bridgeSafe and protocol and savedFrameOwnership and strongCoverage and resultCoverage and transferCoverage and workSafety and
    (not(s.f38) or s.f72) and framesCovered and weakSemantics and serving and
    closedDecision and queueSafe and not(s.z26) and not(s.f56) and not(s.f63)
  temporal completion = weakFair(step,Set(s)).implies(eventually(terminal))
}
