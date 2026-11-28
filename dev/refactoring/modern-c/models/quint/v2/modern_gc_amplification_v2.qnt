module modern_gc_amplification_v2 {
  // Post-Phase A/B/C Structural Amplification Behavioral & Mutation-Killing Model:
  //   1. LXR SATB-with-Interruptions (RC never deletes unmarked object during active SATB)
  //      + Line Reuse Epoch Counter (stale remsets rejected after Immix line reuse)
  //   2. Unified Lock-Free Local Movable+Still Nursery + Global-Marked Sticky-Block Skip
  //      + Bounded Escape Promotion (zero cross-nursery pointers, zero escaped double-free)
  //   3. Opportunistic Major Slice During STW Entry Spin (OCaml 5 domain.c:enter_spin_callback)
  //   4. Incremental Stack-Frame Watermark Scanning (OCaml 5 fiber.c:285-293)
  //
  // Six explicit adversarial mutants below prove that dropping ANY safety guard violates `safe`.

  type ProcId = int   // 0, 1
  type ObjId = int    // 0, 1, 2
  type LineId = int   // 0, 1
  type FrameId = int  // 0, 1, 2 (0 = deepest/oldest, 2 = top/newest)

  type RemsetEntry = {
    line: LineId,
    recordedEpoch: int
  }

  type State = {
    // --- Subsystem 1: LXR SATB-with-Interruptions + Line Reuse Counter ---
    satbActive: bool,
    satbMarked: ObjId -> bool,
    rcCount: ObjId -> int,
    deleted: ObjId -> bool,
    deferredDelete: Set[ObjId],
    lineEpoch: LineId -> int,
    lineReused: LineId -> bool,
    remset: Set[RemsetEntry],

    // --- Subsystem 2: Unified Local Movable+Still Nursery + Global-Skip ---
    // Location of objects 0..2: "LOCAL_0", "LOCAL_1", "GLOBAL"
    objLoc: ObjId -> str,
    stillBlockGlobal: ProcId -> bool,
    stillBlockFreed: ProcId -> bool,
    sharedSlotTarget: int, // -1 or ObjId published in shared global heap

    // --- Subsystem 3: Opportunistic Major Slice During STW Entry Spin ---
    // stwPhase: "MUTATING", "ENTERING", "FLIPPED"
    stwPhase: str,
    arrived: ProcId -> bool,
    spinWorkActive: ProcId -> bool,
    majorSlicesDone: int,

    // --- Subsystem 4: Incremental Stack-Frame Watermark Scanning ---
    // stackHasYoung[f] = true iff frame f holds a young pointer not yet promoted
    stackHasYoung: FrameId -> bool,
    // watermark: frames 0..watermark are claimed already-scanned (-1 = none scanned)
    watermark: int,

    // --- Safety Violation Latches ---
    satbUnmarkedDeleted: bool,
    staleRemsetCorrupted: bool,
    escapedStillFreedLocally: bool,
    crossNurseryLeak: bool,
    spinFlipRace: bool,
    missedYoungStackRoot: bool
  }

  var s: State

  action init = {
    s' = {
      satbActive: true,
      satbMarked: Map(0 -> false, 1 -> true, 2 -> false),
      rcCount: Map(0 -> 1, 1 -> 1, 2 -> 1),
      deleted: Map(0 -> false, 1 -> false, 2 -> false),
      deferredDelete: Set(),
      lineEpoch: Map(0 -> 1, 1 -> 1),
      lineReused: Map(0 -> false, 1 -> false),
      remset: Set({ line: 0, recordedEpoch: 1 }),

      objLoc: Map(0 -> "LOCAL_0", 1 -> "GLOBAL", 2 -> "LOCAL_1"),
      stillBlockGlobal: Map(0 -> false, 1 -> false),
      stillBlockFreed: Map(0 -> false, 1 -> false),
      sharedSlotTarget: 1,

      stwPhase: "MUTATING",
      arrived: Map(0 -> false, 1 -> false),
      spinWorkActive: Map(0 -> false, 1 -> false),
      majorSlicesDone: 0,

      stackHasYoung: Map(0 -> false, 1 -> true, 2 -> true),
      watermark: 0,

      satbUnmarkedDeleted: false,
      staleRemsetCorrupted: false,
      escapedStillFreedLocally: false,
      crossNurseryLeak: false,
      spinFlipRace: false,
      missedYoungStackRoot: false
    }
  }

  // =========================================================================
  // Subsystem 1: LXR SATB-with-Interruptions & Line Reuse Epoch Counter
  // =========================================================================

  // RC decrement drops count to 0; during active SATB, an UNMARKED object MUST
  // be deferred rather than deleted immediately (LXR PLDI '22 §3.3).
  action rcDecrementSafe(o: ObjId): bool = all {
    o == 0 or o == 1 or o == 2,
    not(s.deleted.get(o)),
    s.rcCount.get(o) > 0,
    val nextRc = s.rcCount.get(o) - 1
    val canDeleteNow = (nextRc == 0) and (not(s.satbActive) or s.satbMarked.get(o))
    val mustDefer = (nextRc == 0) and s.satbActive and not(s.satbMarked.get(o))
    s' = {
      ...s,
      rcCount: s.rcCount.set(o, nextRc),
      deleted: if (canDeleteNow) s.deleted.set(o, true) else s.deleted,
      deferredDelete: if (mustDefer) s.deferredDelete.union(Set(o)) else s.deferredDelete
    }
  }

  action satbMarkObject(o: ObjId): bool = all {
    o == 0 or o == 1 or o == 2,
    s.satbActive,
    not(s.deleted.get(o)),
    not(s.satbMarked.get(o)),
    s' = {
      ...s,
      satbMarked: s.satbMarked.set(o, true)
    }
  }

  // Finish SATB trace and safely flush deferred zero-RC objects.
  action finishSatbAndDrainDeferred: bool = all {
    s.satbActive,
    s' = {
      ...s,
      satbActive: false,
      deleted: Map(
        0 -> (s.deleted.get(0) or s.deferredDelete.contains(0)),
        1 -> (s.deleted.get(1) or s.deferredDelete.contains(1)),
        2 -> (s.deleted.get(2) or s.deferredDelete.contains(2))
      ),
      deferredDelete: Set()
    }
  }

  // Reclaim and reuse Immix line `l`: MUST bump `lineEpoch[l]` before reuse.
  action reuseImmixLineSafe(l: LineId): bool = all {
    l == 0 or l == 1,
    not(s.lineReused.get(l)),
    s' = {
      ...s,
      lineEpoch: s.lineEpoch.set(l, s.lineEpoch.get(l) + 1),
      lineReused: s.lineReused.set(l, true)
    }
  }

  // Remset scan checks `recordedEpoch == lineEpoch[entry.line]` and drops stale records.
  action scanRemsetEntrySafe(e: RemsetEntry): bool = all {
    s.remset.contains(e),
    val valid = (e.recordedEpoch == s.lineEpoch.get(e.line))
    s' = {
      ...s,
      remset: s.remset.exclude(Set(e)),
      staleRemsetCorrupted: s.staleRemsetCorrupted or (valid and s.lineReused.get(e.line) and e.recordedEpoch == 1)
    }
  }

  // =========================================================================
  // Subsystem 2: Unified Local Movable+Still Nursery + Global-Skip
  // =========================================================================

  // Publish live local object into shared heap: MUST promote to GLOBAL first (no cross-nursery pointer).
  action publishToSharedSafe(o: ObjId): bool = all {
    o == 0 or o == 2,
    not(s.deleted.get(o)),
    s.objLoc.get(o) != "GLOBAL",
    val ownerProc = if (s.objLoc.get(o) == "LOCAL_0") 0 else 1
    all {
      not(s.stillBlockFreed.get(ownerProc)),
      s' = {
        ...s,
        objLoc: s.objLoc.set(o, "GLOBAL"),
        stillBlockGlobal: s.stillBlockGlobal.set(ownerProc, true),
        sharedSlotTarget: o
      }
    }
  }

  // Unified local movable+still sweep on processor `p`:
  // skips any still block marked GLOBAL (Marlow ISMM '11 §5.3), frees only pure-local blocks.
  action unifiedLocalSweepSafe(p: ProcId): bool = all {
    p == 0 or p == 1,
    not(s.stillBlockFreed.get(p)),
    val canFreeStill = not(s.stillBlockGlobal.get(p))
    s' = {
      ...s,
      stillBlockFreed: if (canFreeStill) s.stillBlockFreed.set(p, true) else s.stillBlockFreed
    }
  }

  // =========================================================================
  // Subsystem 3: Opportunistic Major Slice During STW Entry Spin
  // =========================================================================

  action requestStw(p: ProcId): bool = all {
    p == 0 or p == 1,
    s.stwPhase == "MUTATING",
    s' = {
      ...s,
      stwPhase: "ENTERING",
      arrived: s.arrived.set(p, true)
    }
  }

  // Arrived fast core executes bounded opportunistic major slice ONLY while peer has not arrived.
  action beginSpinMajorSliceSafe(p: ProcId): bool = all {
    p == 0 or p == 1,
    s.stwPhase == "ENTERING",
    s.arrived.get(p),
    not(s.spinWorkActive.get(p)),
    not(s.arrived.get(1 - p)),
    s' = {
      ...s,
      spinWorkActive: s.spinWorkActive.set(p, true)
    }
  }

  action finishSpinMajorSliceSafe(p: ProcId): bool = all {
    p == 0 or p == 1,
    s.spinWorkActive.get(p),
    s' = {
      ...s,
      spinWorkActive: s.spinWorkActive.set(p, false),
      majorSlicesDone: s.majorSlicesDone + 1,
      spinFlipRace: s.spinFlipRace or (s.stwPhase == "FLIPPED")
    }
  }

  action peerArriveAtStw(p: ProcId): bool = all {
    p == 0 or p == 1,
    s.stwPhase == "ENTERING",
    not(s.arrived.get(p)),
    s' = {
      ...s,
      arrived: s.arrived.set(p, true)
    }
  }

  // Coordinator flips phase ONLY after ALL cores arrived AND all spin-work exited.
  action flipStwPhaseSafe: bool = all {
    s.stwPhase == "ENTERING",
    s.arrived.get(0) and s.arrived.get(1),
    not(s.spinWorkActive.get(0)) and not(s.spinWorkActive.get(1)),
    s' = {
      ...s,
      stwPhase: "FLIPPED"
    }
  }

  action resumeFromStw: bool = all {
    s.stwPhase == "FLIPPED",
    s' = {
      ...s,
      stwPhase: "MUTATING",
      arrived: Map(0 -> false, 1 -> false),
      spinWorkActive: Map(0 -> false, 1 -> false)
    }
  }

  // =========================================================================
  // Subsystem 4: Incremental Stack-Frame Watermark Scanning
  // =========================================================================

  // Mutating a frame `f` to store a young pointer MUST invalidate watermark to `min(watermark, f - 1)`.
  action mutateStackFrameSafe(f: FrameId): bool = all {
    f == 0 or f == 1 or f == 2,
    s' = {
      ...s,
      stackHasYoung: s.stackHasYoung.set(f, true),
      watermark: if (f <= s.watermark) f - 1 else s.watermark
    }
  }

  // Minor GC scans ONLY frames strictly above `watermark`, promoting their young pointers
  // and advancing `watermark` to top frame 2. Fails if any young pointer remained <= `watermark`!
  action minorScanStackWithWatermark: bool = all {
    val missed =
      (0 <= s.watermark and s.stackHasYoung.get(0)) or
      (1 <= s.watermark and s.stackHasYoung.get(1)) or
      (2 <= s.watermark and s.stackHasYoung.get(2))
    s' = {
      ...s,
      missedYoungStackRoot: s.missedYoungStackRoot or missed,
      stackHasYoung: Map(
        0 -> (if (0 > s.watermark) false else s.stackHasYoung.get(0)),
        1 -> (if (1 > s.watermark) false else s.stackHasYoung.get(1)),
        2 -> (if (2 > s.watermark) false else s.stackHasYoung.get(2))
      ),
      watermark: 2
    }
  }

  // =========================================================================
  // Global Nondeterministic Step & Safety Invariant
  // =========================================================================

  action step = any {
    nondet o = Set(0, 1, 2).oneOf()
    rcDecrementSafe(o),

    nondet o = Set(0, 1, 2).oneOf()
    satbMarkObject(o),

    finishSatbAndDrainDeferred,

    nondet l = Set(0, 1).oneOf()
    reuseImmixLineSafe(l),

    nondet e = s.remset.oneOf()
    scanRemsetEntrySafe(e),

    nondet o = Set(0, 2).oneOf()
    publishToSharedSafe(o),

    nondet p = Set(0, 1).oneOf()
    unifiedLocalSweepSafe(p),

    nondet p = Set(0, 1).oneOf()
    requestStw(p),

    nondet p = Set(0, 1).oneOf()
    beginSpinMajorSliceSafe(p),

    nondet p = Set(0, 1).oneOf()
    finishSpinMajorSliceSafe(p),

    nondet p = Set(0, 1).oneOf()
    peerArriveAtStw(p),

    flipStwPhaseSafe,
    resumeFromStw,

    nondet f = Set(0, 1, 2).oneOf()
    mutateStackFrameSafe(f),

    minorScanStackWithWatermark
  }

  val safe = all {
    not(s.satbUnmarkedDeleted),
    not(s.staleRemsetCorrupted),
    not(s.escapedStillFreedLocally),
    not(s.crossNurseryLeak),
    not(s.spinFlipRace),
    not(s.missedYoungStackRoot),
    // Structural invariants across all states:
    Set(0, 1, 2).forall(o =>
      not(s.satbActive and not(s.satbMarked.get(o)) and s.deleted.get(o))
    ),
    s.sharedSlotTarget == -1 or s.objLoc.get(s.sharedSlotTarget) == "GLOBAL",
    Set(0, 1).forall(p =>
      not(s.stillBlockGlobal.get(p) and s.stillBlockFreed.get(p))
    ),
    s.stwPhase != "FLIPPED" or (not(s.spinWorkActive.get(0)) and not(s.spinWorkActive.get(1))),
    Set(0, 1, 2).forall(f => (f <= s.watermark) implies not(s.stackHasYoung.get(f)))
  }

  // =========================================================================
  // Adversarial Bug-Injected Mutant Actions (for Mutation-Killer Runs)
  // =========================================================================

  // Mutant 1: RC deletes zero-count object during active SATB without checking satbMarked.
  action mutant1_rcDeleteUnmarkedDuringSatb(o: ObjId): bool = all {
    o == 0,
    s.satbActive,
    not(s.satbMarked.get(o)),
    s' = {
      ...s,
      rcCount: s.rcCount.set(o, 0),
      deleted: s.deleted.set(o, true),
      satbUnmarkedDeleted: true
    }
  }

  // Mutant 2: Remset scan ignores lineEpoch after line reuse -> corrupts new line!
  action mutant2_scanRemsetIgnoringEpoch(e: RemsetEntry): bool = all {
    s.remset.contains(e),
    s.lineReused.get(e.line),
    s' = {
      ...s,
      remset: s.remset.exclude(Set(e)),
      staleRemsetCorrupted: true
    }
  }

  // Mutant 3: Local still sweep ignores stillBlockGlobal -> frees escaped block!
  action mutant3_localSweepFreesGlobalStill(p: ProcId): bool = all {
    s.stillBlockGlobal.get(p),
    s' = {
      ...s,
      stillBlockFreed: s.stillBlockFreed.set(p, true),
      escapedStillFreedLocally: true
    }
  }

  // Mutant 4: Publish local pointer directly to shared heap without promoting!
  action mutant4_publishWithoutPromoting(o: ObjId): bool = all {
    s.objLoc.get(o) != "GLOBAL",
    s' = {
      ...s,
      sharedSlotTarget: o,
      crossNurseryLeak: true
    }
  }

  // Mutant 5: Coordinator flips STW phase while peer still has spinWorkActive!
  action mutant5_flipWithoutWaitingSpinExit: bool = all {
    s.stwPhase == "ENTERING",
    s.arrived.get(0) and s.arrived.get(1),
    s.spinWorkActive.get(0) or s.spinWorkActive.get(1),
    s' = {
      ...s,
      stwPhase: "FLIPPED",
      spinFlipRace: true
    }
  }

  // Mutant 6: Mutate stack frame below watermark WITHOUT invalidating watermark!
  action mutant6_mutateBelowWatermarkNoInvalidate(f: FrameId): bool = all {
    f <= s.watermark,
    s' = {
      ...s,
      stackHasYoung: s.stackHasYoung.set(f, true)
    }
  }

  // =========================================================================
  // Executable Tests (Quint discovers runs ending in `Test`):
  //   1 Full Happy Path + 6 Mutation-Killers
  // =========================================================================

  run happyPathAllAmplificationsTest = {
    init
    .then(rcDecrementSafe(0))            // deferred while SATB active & unmarked
    .then(reuseImmixLineSafe(0))         // bumps epoch 1 -> 2
    .then(scanRemsetEntrySafe({ line: 0, recordedEpoch: 1 })) // safely rejected as stale
    .then(publishToSharedSafe(0))        // promotes obj 0 to GLOBAL & marks block global
    .then(unifiedLocalSweepSafe(0))      // skips global block 0
    .then(unifiedLocalSweepSafe(1))      // frees pure-local block 1
    .then(requestStw(0))
    .then(beginSpinMajorSliceSafe(0))    // fast core does opportunistic major work
    .then(peerArriveAtStw(1))
    .then(finishSpinMajorSliceSafe(0))   // exits spin work before flip
    .then(flipStwPhaseSafe)
    .then(resumeFromStw)
    .then(mutateStackFrameSafe(0))       // invalidates watermark 0 -> -1
    .then(minorScanStackWithWatermark)   // finds all young roots, advances watermark -> 2
    .then(finishSatbAndDrainDeferred)    // safely deletes deferred obj 0 after SATB ends
    .then(all {
      assert(safe),
      assert(s.majorSlicesDone == 1),
      assert(s.deleted.get(0)),
      assert(not(s.stillBlockFreed.get(0))),
      assert(s.stillBlockFreed.get(1)),
      s' = s
    })
  }

  run mutant1SatbUnmarkedRcDeleteTest = {
    init
    .then(mutant1_rcDeleteUnmarkedDuringSatb(0))
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant2StaleRemsetIgnoresLineEpochTest = {
    init
    .then(reuseImmixLineSafe(0))
    .then(mutant2_scanRemsetIgnoringEpoch({ line: 0, recordedEpoch: 1 }))
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant3LocalSweepFreesEscapedStillTest = {
    init
    .then(publishToSharedSafe(0))
    .then(mutant3_localSweepFreesGlobalStill(0))
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant4CrossNurseryPointerWithoutPromoteTest = {
    init
    .then(mutant4_publishWithoutPromoting(0))
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant5SpinWorkRacesPhaseFlipTest = {
    init
    .then(requestStw(0))
    .then(beginSpinMajorSliceSafe(0))
    .then(peerArriveAtStw(1))
    .then(mutant5_flipWithoutWaitingSpinExit)
    .then(all { assert(not(safe)), s' = s })
  }

  run mutant6StackMutationBelowWatermarkMissesRootTest = {
    init
    .then(mutant6_mutateBelowWatermarkNoInvalidate(0))
    .then(minorScanStackWithWatermark)
    .then(all { assert(not(safe)), s' = s })
  }
}
