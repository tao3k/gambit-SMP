module unified_framespec_authority_v2 {
  // Adversarial Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Model for Slice 1:
  //   Unified FrameSpec / PointId Semantic Authority challenging 6 real engineering hazards:
  //     1. Unresolved OFD placeholder scanned before setup bind
  //     2. Double-lowering internal-return cfs vs physical F
  //     3. Wrong/union liveness map across callback (PointId=1) vs recursive return (PointId=2)
  //     4. Unbarriered ##frame-set! on mature captured frame (missing Card + SATB barriers)
  //     5. Dynamic .o1 module unload freeing FrameSpec table while captured continuations pin it!
  //     6. Unscrubbed raw unboxed IEEE-754 F64 spill slot exposed as tagged pointer on PointId transition!

  pure val POINT_IDS = Set(1, 2)
  pure val SLOTS = Set(1, 2, 3)

  pure def liveMask(pid: int): Set[int] =
    if (pid == 1) Set(1, 2) else Set(1, 3)

  type State = {
    moduleOfdBound: bool,
    modulePublished: bool,
    moduleMetadataAlive: bool,   // MUST stay true while cohortPinCount > 0!
    cohortPinCount: int,         // # captured continuations referencing this .o1 FrameSpec
    activePointId: int,
    storedCfs: int,
    physicalF: int,
    loweredOnce: bool,
    slot3HasRawF64: bool,        // unboxed IEEE-754 F64 spill in slot 3 during PointId=1
    capturedMature: bool,
    slotHasYoungPtr: int -> bool,
    slotHasOldSatbPtr: int -> bool,
    cardMarked: bool,
    satbLogged: bool,
    majorMarkActive: bool,
    shotsCompleted: int,
    // Fault flags
    unresolvedOfdScanned: bool,
    wrongPointMapUsed: bool,
    doubleLoweredCfs: bool,
    missedBarrierOnFrameSet: bool,
    danglingFrameSpecUnload: bool,
    rawF64ScannedAsPtr: bool
  }

  var s: State

  action init = {
    s' = {
      moduleOfdBound: false,
      modulePublished: false,
      moduleMetadataAlive: true,
      cohortPinCount: 0,
      activePointId: 1,
      storedCfs: 4,
      physicalF: 0,
      loweredOnce: false,
      slot3HasRawF64: true, // Slot 3 holds raw unboxed double while dead at PointId=1!
      capturedMature: false,
      slotHasYoungPtr: Map(1 -> false, 2 -> false, 3 -> false),
      slotHasOldSatbPtr: Map(1 -> true, 2 -> true, 3 -> false),
      cardMarked: false,
      satbLogged: false,
      majorMarkActive: true,
      shotsCompleted: 0,
      unresolvedOfdScanned: false,
      wrongPointMapUsed: false,
      doubleLoweredCfs: false,
      missedBarrierOnFrameSet: false,
      danglingFrameSpecUnload: false,
      rawF64ScannedAsPtr: false
    }
  }

  // Step 1: Resolve OFD & lower internal cfs -> physical F exactly once before publishing module
  action safeBindAndPublishModule = {
    val f = s.storedCfs + 4
    all {
      not(s.modulePublished),
      not(s.loweredOnce),
      s' = {
        ...s,
        moduleOfdBound: true,
        modulePublished: true,
        physicalF: f,
        loweredOnce: true
      }
    }
  }

  // Step 2: Capture continuation into mature heap -> pins .o1 FrameSpec cohort!
  action safeCaptureToMature = all {
    s.modulePublished,
    s.moduleOfdBound,
    s.moduleMetadataAlive,
    not(s.capturedMature),
    s' = { ...s, capturedMature: true, cohortPinCount: s.cohortPinCount + 1 }
  }

  // Step 3: Transition PointId 1 -> 2 MUST scrub raw unboxed F64 in slot 3 BEFORE liveMask(2) exposes it!
  action safeScrubAndAdvancePoint(nextPid: int): bool = all {
    s.modulePublished,
    POINT_IDS.contains(nextPid),
    nextPid != s.activePointId,
    s' = {
      ...s,
      activePointId: nextPid,
      slot3HasRawF64: if (nextPid == 2) false else s.slot3HasRawF64 // targ-scrub-dirty-unboxed!
    }
  }

  // Step 4: ##frame-set! on mature captured frame fires Card + SATB barriers
  action safeMatureFrameSet(slot: int): bool = all {
    s.capturedMature,
    s.moduleMetadataAlive,
    liveMask(s.activePointId).contains(slot),
    not(slot == 3 and s.slot3HasRawF64),
    s' = {
      ...s,
      slotHasYoungPtr: s.slotHasYoungPtr.set(slot, true),
      cardMarked: true,
      satbLogged: if (s.majorMarkActive and s.slotHasOldSatbPtr.get(slot)) true else s.satbLogged
    }
  }

  // Step 5: GC scans frame using exact PointId liveness map; verifies no raw F64 & barrier closure
  action safeGcScanFrame = {
    val anyYoung = liveMask(s.activePointId).exists(k => s.slotHasYoungPtr.get(k))
    val barrierOk = not(s.capturedMature) or not(anyYoung) or s.cardMarked
    val rawHit = liveMask(s.activePointId).contains(3) and s.slot3HasRawF64
    all {
      s.modulePublished,
      s.moduleOfdBound,
      s.moduleMetadataAlive,
      s' = {
        ...s,
        missedBarrierOnFrameSet: s.missedBarrierOnFrameSet or not(barrierOk),
        rawF64ScannedAsPtr: s.rawF64ScannedAsPtr or rawHit,
        slotHasYoungPtr: Map(1 -> false, 2 -> false, 3 -> false),
        cardMarked: false
      }
    }
  }

  // Step 6: Multi-shot continuation restore into private execution image
  action safeRestoreShot = all {
    s.modulePublished,
    s.moduleOfdBound,
    s.moduleMetadataAlive,
    s.capturedMature,
    s.shotsCompleted < 3,
    s' = { ...s, shotsCompleted: s.shotsCompleted + 1 }
  }

  // Step 7: Dynamic .o1 unload only frees FrameSpec metadata when cohortPinCount == 0!
  action safeUnloadDynamicModule = all {
    s.moduleMetadataAlive,
    s.cohortPinCount == 0,
    not(s.modulePublished),
    s' = { ...s, moduleMetadataAlive: false }
  }

  action step = any {
    safeBindAndPublishModule,
    safeCaptureToMature,
    nondet pid = POINT_IDS.oneOf()
    safeScrubAndAdvancePoint(pid),
    nondet slot = SLOTS.oneOf()
    safeMatureFrameSet(slot),
    safeGcScanFrame,
    safeRestoreShot,
    safeUnloadDynamicModule
  }

  // --- Safety Invariants ---
  val cohortPinIntact = (s.cohortPinCount == 0) or s.moduleMetadataAlive

  val safe =
    not(s.unresolvedOfdScanned) and
    not(s.wrongPointMapUsed) and
    not(s.doubleLoweredCfs) and
    not(s.missedBarrierOnFrameSet) and
    not(s.danglingFrameSpecUnload) and
    not(s.rawF64ScannedAsPtr) and
    cohortPinIntact and
    (not(s.modulePublished) or (s.moduleOfdBound and s.loweredOnce and s.physicalF == s.storedCfs + 4))

  // --- 6 Real-Bug Mutation Killers ---

  action buggyScanUnresolvedOfd = all {
    not(s.moduleOfdBound),
    s' = { ...s, unresolvedOfdScanned: true }
  }

  action buggyDoubleLowerInternalCfs = all {
    s.loweredOnce,
    s' = { ...s, physicalF: s.physicalF + 4, doubleLoweredCfs: true }
  }

  action buggyUseWrongPointMap = all {
    s.modulePublished,
    s.activePointId == 1,
    not(liveMask(1).contains(3)),
    s' = { ...s, wrongPointMapUsed: true }
  }

  action buggyUnbarrieredFrameSet = all {
    s.capturedMature,
    s' = { ...s, slotHasYoungPtr: s.slotHasYoungPtr.set(1, true), cardMarked: false, satbLogged: false }
  }

  // Mutant 5: Unload dynamic .o1 FrameSpec metadata while a captured continuation still pins it!
  action buggyUnloadPinnedCohort = all {
    s.cohortPinCount > 0,
    s' = { ...s, moduleMetadataAlive: false, danglingFrameSpecUnload: true }
  }

  // Mutant 6: Advance to PointId=2 without scrubbing raw unboxed F64 in slot 3!
  action buggyAdvanceWithoutRawF64Scrub = all {
    s.modulePublished,
    s.activePointId == 1,
    s.slot3HasRawF64,
    s' = { ...s, activePointId: 2 } // slot3HasRawF64 stays true -> GC scan explodes!
  }

  // --- Positive Test ---
  run unifiedFrameSpecMultiShotTest =
    init
      .then(safeBindAndPublishModule)
      .then(safeCaptureToMature)
      .then(safeMatureFrameSet(1))
      .then(safeGcScanFrame)
      .then(safeRestoreShot)
      .then(safeScrubAndAdvancePoint(2))
      .then(safeMatureFrameSet(3))
      .then(safeGcScanFrame)
      .then(safeRestoreShot)
      .expect(safe and s.shotsCompleted == 2 and s.satbLogged and s.cohortPinCount == 1)

  // --- 6 Mutant-Killing Negative Tests (all suffixed with Test for `quint test`) ---
  run mutant1UnresolvedOfdKilledTest =
    init.then(buggyScanUnresolvedOfd).expect(not(safe))

  run mutant2DoubleLowerKilledTest =
    init.then(safeBindAndPublishModule).then(buggyDoubleLowerInternalCfs).expect(not(safe))

  run mutant3WrongPointMapKilledTest =
    init.then(safeBindAndPublishModule).then(buggyUseWrongPointMap).expect(not(safe))

  run mutant4UnbarrieredFrameSetKilledTest =
    init
      .then(safeBindAndPublishModule)
      .then(safeCaptureToMature)
      .then(buggyUnbarrieredFrameSet)
      .then(safeGcScanFrame)
      .expect(not(safe))

  run mutant5DanglingCohortUnloadKilledTest =
    init
      .then(safeBindAndPublishModule)
      .then(safeCaptureToMature)
      .then(buggyUnloadPinnedCohort)
      .expect(not(safe))

  run mutant6UnscrubbedRawF64KilledTest =
    init
      .then(safeBindAndPublishModule)
      .then(buggyAdvanceWithoutRawF64Scrub)
      .then(safeGcScanFrame)
      .expect(not(safe))
}
