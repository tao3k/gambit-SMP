module tier31p3_still_and_rest_fastpath_v2 {
  // Adversarial Quint V2 (Micro-step, Non-Atomic, Mutation-Killing) Model for Wave A (Tier 3.1p3):
  //   Challenges every engineering seam of Generational ___STILL & Lock-Free Rest Fast-Span:
  //     1. Non-pointer ___STILL (f64vector/u8vector/string) never dirties card/still scan
  //     2. External FFI refcount > 0 young still survives Minor GC and scans outgoing young edges
  //     3. Parallel GC workers W0/W1 racing to mark the SAME young still MUST use atomic CAS claim
  //        so still_objs_to_scan is pushed AT MOST ONCE (preventing linked-list cycles!)
  //     4. Dead young ___sFOREIGN with C release callback MUST defer to lifecycle cleanup outside STW
  //     5. Lock-free ___rest_fast_grant_fits fast_span MUST invalidate across GC epochs AND enforce
  //        strict stack/heap disjointness (heapFastHi <= stackFastFloor) on shared stack+heap sections.

  // Still object IDs:
  //   0 = non-pointer young f64vector (dead)
  //   1 = pointer-bearing young vector (reachable by BOTH W0 & W1 concurrently -> CAS claim race!)
  //   2 = non-pointer young u8vector held by FFI (refcount = 1, unreachable from Scheme roots)
  //   3 = pointer-bearing mature vector (mutated to point to young movable object)
  //   4 = dead young ___sFOREIGN object with C finalizer (MUST defer release outside STW!)
  pure val STILL_IDS = Set(0, 1, 2, 3, 4)

  type StillObj = {
    age: str,               // "young" | "mature" | "freed" | "deferred_release"
    hasPtrs: bool,
    dirty: bool,
    refcount: int,
    hasForeignRelease: bool,
    pointsToYoung: bool,
    rootReachable: bool,
    marked: bool,
    pushCount: int,         // # times pushed to still_objs_to_scan (MUST be <= 1!)
    markEpoch: int          // SATB-ready mark epoch field for Slice 2 compatibility
  }

  type State = {
    stills: int -> StillObj,
    stillDirtyAny: bool,
    gcPhase: str,           // "mutator" | "minor_mark"
    gcEpoch: int,
    deferredReleaseCount: int,
    stwForeignCallbackRan: bool,
    lostLiveStill: bool,
    lostYoungEdge: bool,
    nonPtrDirtied: bool,
    doublePushCycleBug: bool,
    // Part 2: Lock-free ___rest_fast_grant_fits fast_span
    fastSpanEpoch: int,
    fastSpanValid: bool,
    sharedStackHeapSection: bool,
    heapFastHi: int,
    stackFastFloor: int,
    restAttemptArmed: bool,
    restObsActive: bool,
    fastSpanTaken: bool,
    copyGateLockTaken: bool,
    staleFastSpanBug: bool,
    sharedSpanOverlapBug: bool
  }

  var s: State

  action init = {
    s' = {
      stills: Map(
        0 -> { age: "young",  hasPtrs: false, dirty: false, refcount: 0, hasForeignRelease: false, pointsToYoung: false, rootReachable: false, marked: false, pushCount: 0, markEpoch: 0 },
        1 -> { age: "young",  hasPtrs: true,  dirty: true,  refcount: 0, hasForeignRelease: false, pointsToYoung: true,  rootReachable: true,  marked: false, pushCount: 0, markEpoch: 0 },
        2 -> { age: "young",  hasPtrs: false, dirty: false, refcount: 1, hasForeignRelease: false, pointsToYoung: false, rootReachable: false, marked: false, pushCount: 0, markEpoch: 0 },
        3 -> { age: "mature", hasPtrs: true,  dirty: false, refcount: 0, hasForeignRelease: false, pointsToYoung: false, rootReachable: true,  marked: false, pushCount: 0, markEpoch: 0 },
        4 -> { age: "young",  hasPtrs: false, dirty: false, refcount: 0, hasForeignRelease: true,  pointsToYoung: false, rootReachable: false, marked: false, pushCount: 0, markEpoch: 0 }
      ),
      stillDirtyAny: true,
      gcPhase: "mutator",
      gcEpoch: 1,
      deferredReleaseCount: 0,
      stwForeignCallbackRan: false,
      lostLiveStill: false,
      lostYoungEdge: false,
      nonPtrDirtied: false,
      doublePushCycleBug: false,
      fastSpanEpoch: 1,
      fastSpanValid: true,
      sharedStackHeapSection: true,
      heapFastHi: 1000,
      stackFastFloor: 2000, // strictly disjoint: heapFastHi <= stackFastFloor!
      restAttemptArmed: false,
      restObsActive: false,
      fastSpanTaken: false,
      copyGateLockTaken: false,
      staleFastSpanBug: false,
      sharedSpanOverlapBug: false
    }
  }

  // Mutator writes a young movable pointer into mature pointer-bearing still 3 (with write barrier)
  action safeMutateMatureStillPtr = {
    val o3 = s.stills.get(3)
    all {
      s.gcPhase == "mutator",
      not(o3.pointsToYoung),
      s' = {
        ...s,
        stills: s.stills.set(3, { ...o3, pointsToYoung: true, dirty: true }),
        stillDirtyAny: true
      }
    }
  }

  // Enter Minor GC: invalidate fast_span immediately
  action safeEnterMinorMark = all {
    s.gcPhase == "mutator",
    s' = { ...s, gcPhase: "minor_mark", fastSpanValid: false }
  }

  // Atomic CAS claim by any parallel Minor GC worker: guarantees pushCount <= 1!
  action safeCasClaimYoungStill(id: int): bool = {
    val o = s.stills.get(id)
    all {
      s.gcPhase == "minor_mark",
      STILL_IDS.contains(id),
      o.age == "young",
      not(o.marked), // Atomic CAS(marked: false -> true) succeeds for at most ONE worker!
      o.rootReachable or o.refcount > 0,
      s' = {
        ...s,
        stills: s.stills.set(id, { ...o, marked: true, pushCount: o.pushCount + 1, markEpoch: s.gcEpoch })
      }
    }
  }

  // Sweep dead young stills (deferring ___sFOREIGN release callbacks outside STW!) & promote live ones
  action safeFinishMinorAndSweepYoungStill = {
    val o3 = s.stills.get(3)
    val scannedMatureEdge = not(o3.pointsToYoung) or (s.stillDirtyAny and o3.dirty)
    val nextEpoch = s.gcEpoch + 1
    val newlyDeferred = STILL_IDS.filter(id =>
      val o = s.stills.get(id)
      o.age == "young" and not(o.marked) and o.hasForeignRelease
    ).size()
    val nextStills = STILL_IDS.mapBy(id =>
      val o = s.stills.get(id)
      if (o.age == "young")
        if (o.marked)
          { ...o, age: "mature", marked: false, dirty: false, pointsToYoung: false, pushCount: 0 }
        else if (o.hasForeignRelease)
          { ...o, age: "deferred_release", marked: false, dirty: false, pointsToYoung: false, pushCount: 0 }
        else
          { ...o, age: "freed", marked: false, dirty: false, pointsToYoung: false, pushCount: 0 }
      else
        { ...o, dirty: false, pointsToYoung: false, pushCount: 0 }
    )
    all {
      s.gcPhase == "minor_mark",
      STILL_IDS.forall(id =>
        val o = s.stills.get(id)
        (o.age != "young") or not(o.rootReachable or o.refcount > 0) or o.marked
      ),
      s' = {
        ...s,
        stills: nextStills,
        stillDirtyAny: false,
        gcPhase: "mutator",
        gcEpoch: nextEpoch,
        deferredReleaseCount: s.deferredReleaseCount + newlyDeferred,
        lostYoungEdge: s.lostYoungEdge or not(scannedMatureEdge),
        fastSpanEpoch: nextEpoch,
        fastSpanValid: true
      }
    }
  }

  // Safe lock-free fast-span rest grant: zero copy_gate lock, requires valid epoch, disjoint stack/heap, idle attempt/obs
  action safeRestFastSpanAdmit = all {
    s.gcPhase == "mutator",
    s.fastSpanValid,
    s.fastSpanEpoch == s.gcEpoch,
    not(s.sharedStackHeapSection) or (s.heapFastHi <= s.stackFastFloor),
    not(s.restAttemptArmed),
    not(s.restObsActive),
    s' = { ...s, fastSpanTaken: true, copyGateLockTaken: false }
  }

  action toggleRestAttempt = all {
    s.gcPhase == "mutator",
    s' = { ...s, restAttemptArmed: not(s.restAttemptArmed) }
  }

  action toggleRestObs = all {
    s.gcPhase == "mutator",
    s' = { ...s, restObsActive: not(s.restObsActive) }
  }

  action safeRestSlowPath = all {
    s.gcPhase == "mutator",
    s.restAttemptArmed or s.restObsActive or not(s.fastSpanValid),
    s' = { ...s, fastSpanTaken: false, copyGateLockTaken: true }
  }

  action step = any {
    safeMutateMatureStillPtr,
    safeEnterMinorMark,
    nondet id = STILL_IDS.oneOf()
    safeCasClaimYoungStill(id),
    safeFinishMinorAndSweepYoungStill,
    safeRestFastSpanAdmit,
    toggleRestAttempt,
    toggleRestObs,
    safeRestSlowPath
  }

  // --- Safety Invariants ---
  val noNonPtrDirty = STILL_IDS.forall(id =>
    val o = s.stills.get(id)
    o.hasPtrs or not(o.dirty)
  )
  val noLiveOrPinnedFreed = STILL_IDS.forall(id =>
    val o = s.stills.get(id)
    (o.age != "freed" and o.age != "deferred_release") or (not(o.rootReachable) and o.refcount == 0)
  )
  val noDoublePush = STILL_IDS.forall(id => s.stills.get(id).pushCount <= 1)

  val safe =
    not(s.lostLiveStill) and
    not(s.lostYoungEdge) and
    not(s.nonPtrDirtied) and
    not(s.doublePushCycleBug) and
    not(s.stwForeignCallbackRan) and
    not(s.staleFastSpanBug) and
    not(s.sharedSpanOverlapBug) and
    noNonPtrDirty and
    noLiveOrPinnedFreed and
    noDoublePush

  // --- 7 Real-Bug Mutation Killers ---

  // Mutant 1: Mark non-pointer f64vector as STILL_DIRTY (824f5dc6 bottleneck)
  action buggyDirtyNonPointerStill = {
    val o0 = s.stills.get(0)
    all { s' = { ...s, stills: s.stills.set(0, { ...o0, dirty: true }), nonPtrDirtied: true } }
  }

  // Mutant 2: Sweep unmarked young still ignoring FFI refcount > 0
  action buggySweepIgnoringRefcount = {
    val o2 = s.stills.get(2)
    all {
      s.gcPhase == "minor_mark",
      o2.refcount > 0,
      s' = { ...s, stills: s.stills.set(2, { ...o2, age: "freed" }), lostLiveStill: true }
    }
  }

  // Mutant 3: Mutate mature pointer still without setting STILL_DIRTY
  action buggyUnbarrieredMatureStillWrite = {
    val o3 = s.stills.get(3)
    all {
      s.gcPhase == "mutator",
      s' = { ...s, stills: s.stills.set(3, { ...o3, pointsToYoung: true, dirty: false }), stillDirtyAny: false }
    }
  }

  // Mutant 4: Non-atomic parallel worker mark double-pushes young still 1 onto still_objs_to_scan!
  action buggyNonAtomicDoublePushStill = {
    val o1 = s.stills.get(1)
    all {
      s.gcPhase == "minor_mark",
      o1.marked,
      s' = { ...s, stills: s.stills.set(1, { ...o1, pushCount: o1.pushCount + 1 }), doublePushCycleBug: true }
    }
  }

  // Mutant 5: Invoke C foreign release callback inline during Minor GC STW instead of deferring!
  action buggyInlineStwForeignRelease = {
    val o4 = s.stills.get(4)
    all {
      s.gcPhase == "minor_mark",
      o4.hasForeignRelease,
      s' = { ...s, stills: s.stills.set(4, { ...o4, age: "freed" }), stwForeignCallbackRan: true }
    }
  }

  // Mutant 6: Admit rest fast_span without invalidating across GC epoch
  action buggyStaleRestFastSpan = all {
    s.gcPhase == "mutator",
    s.fastSpanEpoch != s.gcEpoch,
    s' = { ...s, fastSpanTaken: true, staleFastSpanBug: true }
  }

  // Mutant 7: Admit rest fast_span on shared stack+heap section when heapFastHi > stackFastFloor!
  action buggyOverlappingSharedFastSpan = all {
    s.gcPhase == "mutator",
    s.sharedStackHeapSection,
    s' = { ...s, heapFastHi: 2500, stackFastFloor: 2000, fastSpanTaken: true, sharedSpanOverlapBug: true }
  }

  // --- Positive Tests ---
  run youngStillSweepPromoteAndDeferForeignTest =
    init
      .then(safeMutateMatureStillPtr)
      .then(safeEnterMinorMark)
      .then(safeCasClaimYoungStill(1))
      .then(safeCasClaimYoungStill(2))
      .then(safeFinishMinorAndSweepYoungStill)
      .expect(
        safe and
        s.stills.get(0).age == "freed" and
        s.stills.get(1).age == "mature" and
        s.stills.get(2).age == "mature" and
        s.stills.get(3).age == "mature" and
        s.stills.get(4).age == "deferred_release" and
        s.deferredReleaseCount == 1
      )

  run restFastSpanZeroLockDisjointTest =
    init
      .then(safeRestFastSpanAdmit)
      .expect(safe and s.fastSpanTaken and not(s.copyGateLockTaken))

  // --- 7 Mutant-Killing Negative Tests (all suffixed with Test so `quint test` executes every mutant!) ---
  run mutant1NonPtrDirtyKilledTest =
    init.then(buggyDirtyNonPointerStill).expect(not(safe))

  run mutant2RefcountSweepKilledTest =
    init.then(safeEnterMinorMark).then(buggySweepIgnoringRefcount).expect(not(safe))

  run mutant3UnbarrieredStillWriteKilledTest =
    init
      .then(buggyUnbarrieredMatureStillWrite)
      .then(safeEnterMinorMark)
      .then(safeCasClaimYoungStill(1))
      .then(safeCasClaimYoungStill(2))
      .then(safeFinishMinorAndSweepYoungStill)
      .expect(not(safe))

  run mutant4DoublePushCycleKilledTest =
    init
      .then(safeEnterMinorMark)
      .then(safeCasClaimYoungStill(1))
      .then(buggyNonAtomicDoublePushStill)
      .expect(not(safe))

  run mutant5InlineStwForeignReleaseKilledTest =
    init.then(safeEnterMinorMark).then(buggyInlineStwForeignRelease).expect(not(safe))

  run mutant6StaleFastSpanKilledTest =
    init
      .then(safeEnterMinorMark)
      .then(safeCasClaimYoungStill(1))
      .then(safeCasClaimYoungStill(2))
      .then(safeFinishMinorAndSweepYoungStill)
      .then(s' = { ...s, fastSpanEpoch: 1 })
      .then(buggyStaleRestFastSpan)
      .expect(not(safe))

  run mutant7SharedSpanOverlapKilledTest =
    init.then(buggyOverlappingSharedFastSpan).expect(not(safe))
}
